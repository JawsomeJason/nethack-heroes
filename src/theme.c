/* theme.c - heroes fork, 2026-11-11: theme packs (Lua) over a stock engine.
 * Packs call the nh.* functions documented in heroes/docs/seam.md.  Every
 * key is an ORIGINAL NetHack name, so packs stack.  Nothing here is saved:
 * names are re-applied in each process and presets are re-derived from the
 * role on every turn. */
#include "hack.h"
#include "dlb.h"
#include "theme.h"

#define MAXKIT 16
#define MAXLST 12
#define NOSPE (-127)

static const char *mn0[NUMMONS][NUM_MGENDERS], *on0[NUM_OBJECTS],
    *od0[NUM_OBJECTS], *rolekey[NUM_ROLES], *racekey[NUM_RACES];
static const char *killverb[2] = { "kill", "killed" };
static boolean objren;

static struct hero {
    struct { short otyp, n, spe; } kit[MAXKIT];
    short nkit, props[MAXLST], nprops, spells[MAXLST], nspells;
} hero[NUM_ROLES];

/* scalar fields a pack may set: 's' string, 'i' int, 'n' RoleName */
static const struct tfield { const char *key; size_t off; char ty; }
#define RF(k, t) { #k, offsetof(struct Role, k), t }
    rolefields[] = { RF(name, 'n'), RF(lgod, 's'), RF(ngod, 's'),
                     RF(cgod, 's'), RF(spelbase, 'i'), RF(spelheal, 'i'),
                     RF(spelshld, 'i'), RF(spelarmr, 'i'), RF(spelstat, 'i'),
                     RF(spelspec, 'i'), RF(spelsbon, 'i'), { 0, 0, 0 } },
#define RC(k, t) { #k, offsetof(struct Race, k), t }
    racefields[] = { RC(noun, 's'), RC(adj, 's'), RC(coll, 's'),
                     RC(individual, 'n'), { 0, 0, 0 } };

/* the engine names these "HP regeneration", "telepathic", "very fast" */
static const char *const propalias[][2] = {
    { "regeneration", "HP regeneration" }, { "telepathy", "telepathic" },
    { "speed", "very fast" }, { 0, 0 }
};

static int
findkey(const char *const *keys, int n, const char *s)
{
    while (--n >= 0 && strcmp(keys[n], s))
        continue;
    return n;
}

/* object by ORIGINAL name; a "potion of " style prefix or cls narrows it */
static int
origobj(const char **sp, int cls)
{
    static const char *const pfx[] = { "ring of ", "potion of ", "scroll of ",
                                       "spellbook of ", "wand of " };
    static const char pcls[] = { RING_CLASS, POTION_CLASS, SCROLL_CLASS,
                                 SPBOOK_CLASS, WAND_CLASS };
    int i;

    for (i = 0; i < SIZE(pfx); i++)
        if (!strncmpi(*sp, pfx[i], strlen(pfx[i]))) {
            *sp += strlen(pfx[i]), cls = pcls[i];
            break;
        }
    for (i = 1; i < NUM_OBJECTS; i++)
        if (on0[i] && !strcmpi(*sp, on0[i])
            && (!cls || objects[i].oc_class == cls))
            return i;
    return STRANGE_OBJECT;
}

static int
objarg(lua_State *L, int idx, int cls)
{
    const char *s = luaL_checkstring(L, idx);
    int otyp = origobj(&s, cls);

    return otyp ? otyp : luaL_error(L, "unknown object '%s'", s);
}

static int
classarg(lua_State *L, int idx)
{
    const char *s = luaL_optstring(L, idx, "");
    int c = *s ? def_char_to_objclass(*s) : 0;

    return c != MAXOCLASSES ? c : luaL_error(L, "bad object class '%s'", s);
}

/* role or race index from the original name in arg 1; arg 2 is a table */
static int
slotarg(lua_State *L, boolean race)
{
    const char *s = luaL_checkstring(L, 1);
    int i = race ? findkey(racekey, NUM_RACES, s)
                 : findkey(rolekey, NUM_ROLES, s);

    luaL_checktype(L, 2, LUA_TTABLE);
    return i >= 0 ? i : luaL_error(L, "unknown role or race '%s'", s);
}

/* value at top: "name", or { m = "male form", f = "female form" } */
static void
rolename(lua_State *L, struct RoleName *rn)
{
    if (!lua_istable(L, -1)) {
        rn->m = dupstr(luaL_checkstring(L, -1)), rn->f = 0;
        return;
    }
    if (lua_getfield(L, -1, "m") == LUA_TSTRING)
        rn->m = dupstr(lua_tostring(L, -1));
    rn->f = lua_getfield(L, -2, "f") == LUA_TSTRING
                ? dupstr(lua_tostring(L, -1)) : 0;
    lua_pop(L, 2);
}

static void
setfields(lua_State *L, char *base, const struct tfield *f)
{
    for (; f->key; f++, lua_pop(L, 1))
        if (lua_getfield(L, 2, f->key) == LUA_TNIL)
            continue;
        else if (f->ty == 'i')
            *(int *) (base + f->off) = (int) luaL_checkinteger(L, -1);
        else if (f->ty == 's')
            *(const char **) (base + f->off) = dupstr(luaL_checkstring(L, -1));
        else
            rolename(L, (struct RoleName *) (base + f->off));
}

/* int field k of the table at top, or dflt */
static int
optint(lua_State *L, const char *k, int dflt)
{
    int v = lua_getfield(L, -1, k) == LUA_TNIL ? dflt
                                               : (int) lua_tointeger(L, -1);

    lua_pop(L, 1);
    return v;
}

/* nh.rename_monster / rename_object / rename_appearance (orig, new [, cls]) */
static int
t_rename(lua_State *L, int kind)
{
    const char *orig = luaL_checkstring(L, 1), *nu = luaL_checkstring(L, 2);
    int i, g, n = 0, cls = classarg(L, 3);

    nu = dupstr(nu);
    for (i = 0; i < (kind ? NUM_OBJECTS : NUMMONS); i++)
        if (!kind) {
            for (g = 0; g < NUM_MGENDERS; g++)
                if (mn0[i][g] && !strcmp(mn0[i][g], orig))
                    mons[i].pmnames[g] = nu, n++;
        } else if ((!cls || objects[i].oc_class == cls)
                   && (kind == 1 ? on0[i] : od0[i])
                   && !strcmp(kind == 1 ? on0[i] : od0[i], orig)) {
            *(kind == 1 ? &obj_descr[i].oc_name : &obj_descr[i].oc_descr) = nu;
            n++, objren = TRUE;
        }
    lua_pushinteger(L, n); /* entries renamed; 0 means a typo */
    return 1;
}
static int t_rename_mon(lua_State *L) { return t_rename(L, 0); }
static int t_rename_obj(lua_State *L) { return t_rename(L, 1); }
static int t_rename_look(lua_State *L) { return t_rename(L, 2); }

/* nh.theme_object(orig [, cls]): current name for an original name or
   appearance, or nil; the des.object/obj.new wrappers use it */
static int
t_theme_obj(lua_State *L)
{
    const char *s = luaL_checkstring(L, 1), *p = s;
    int i = origobj(&p, classarg(L, 2));

    if (i) { /* an original name never falls through to appearances */
        if (on0[i] == obj_descr[i].oc_name)
            return 0;
        lua_pushfstring(L, "%s%s", lua_pushlstring(L, s, p - s),
                        obj_descr[i].oc_name);
        return 1;
    }
    for (i = 1; i < NUM_OBJECTS; i++)
        if (od0[i] && od0[i] != obj_descr[i].oc_descr && !strcmpi(s, od0[i])) {
            lua_pushstring(L, obj_descr[i].oc_descr);
            return 1;
        }
    return 0;
}

/* field k of arg 2, a list of original race nouns or alignment adjectives
   ("lawful"), as a mask; -1 if absent */
static long
masklist(lua_State *L, const char *k, boolean isalign)
{
    const char *s;
    long m = 0;
    int i, j;

    if (lua_getfield(L, 2, k) == LUA_TTABLE)
        for (i = 1; lua_rawgeti(L, 3, i) != LUA_TNIL; i++, lua_pop(L, 1)) {
            s = luaL_checkstring(L, -1);
            if (isalign)
                for (j = ROLE_ALIGNS - 1; j >= 0 && strcmp(aligns[j].adj, s);)
                    j--;
            else
                j = findkey(racekey, NUM_RACES, s);
            if (j < 0)
                return luaL_error(L, "unknown %s '%s'", k, s);
            m |= isalign ? aligns[j].allow : races[j].selfmask;
        }
    else
        m = -1;
    lua_settop(L, 2);
    return m;
}

/* nh.race(orig_noun, { noun, adj, coll, individual, aligns, friends, foes }) */
static int
t_race(lua_State *L)
{
    struct Race *ra = &races[slotarg(L, TRUE)];
    long m;

    setfields(L, (char *) ra, racefields);
    if ((m = masklist(L, "aligns", TRUE)) >= 0)
        ra->allow = (short) ((ra->allow & ~ROLE_ALIGNMASK) | m);
    if ((m = masklist(L, "friends", FALSE)) >= 0)
        ra->lovemask = (short) m;
    if ((m = masklist(L, "foes", FALSE)) >= 0)
        ra->hatemask = (short) m;
    return 0;
}

/* nh.role(orig, { name, ranks, lgod, ngod, cgod, races, sidekick, spel* }) */
static int
t_role(lua_State *L)
{
    struct Role *ro = &roles[slotarg(L, FALSE)];
    long m;
    int i;

    setfields(L, (char *) ro, rolefields);
    if (lua_getfield(L, 2, "ranks") == LUA_TTABLE)
        for (i = 0; i < SIZE(ro->rank); i++, lua_pop(L, 1))
            if (lua_rawgeti(L, 3, i + 1) != LUA_TNIL)
                rolename(L, &ro->rank[i]);
    lua_settop(L, 2);
    if ((m = masklist(L, "races", FALSE)) >= 0) /* {} hides the role */
        ro->allow = (short) ((ro->allow & ~ROLE_RACEMASK) | m);
    if (lua_getfield(L, 2, "sidekick") != LUA_TNIL
        && (ro->petnum = name_to_mon(luaL_checkstring(L, 3), (int *) 0))
               == NON_PM)
        return luaL_error(L, "unknown monster '%s'", lua_tostring(L, 3));
    return 0;
}

/* nh.hero(orig_role, { kit = {...}, intrinsics = {...}, spells = {...} }) */
static int
t_hero(lua_State *L)
{
    struct hero *h = &hero[slotarg(L, FALSE)];
    const char *s, *nm;
    int k, p;

    if (lua_getfield(L, 2, "kit") == LUA_TTABLE)
        for (h->nkit = 0; h->nkit < MAXKIT
             && lua_rawgeti(L, 3, h->nkit + 1) != LUA_TNIL;
             h->nkit++, lua_settop(L, 3)) {
            if (lua_istable(L, 4)) /* { "name", spe = 2, n = 3 } */
                lua_rawgeti(L, 4, 1);
            h->kit[h->nkit].otyp = objarg(L, -1, 0);
            lua_settop(L, 4);
            h->kit[h->nkit].spe = lua_istable(L, 4) ? optint(L, "spe", NOSPE)
                                                    : NOSPE;
            h->kit[h->nkit].n = lua_istable(L, 4) ? optint(L, "n", 1) : 1;
        }
    lua_settop(L, 2);
    if (lua_getfield(L, 2, "intrinsics") == LUA_TTABLE)
        for (h->nprops = 0; h->nprops < MAXLST
             && lua_rawgeti(L, 3, h->nprops + 1) != LUA_TNIL;
             h->nprops++, lua_pop(L, 1)) {
            s = luaL_checkstring(L, -1);
            for (k = 0; propalias[k][0] && strcmp(s, propalias[k][0]); k++)
                continue;
            if (propalias[k][0])
                s = propalias[k][1];
            for (k = 0; (nm = property_by_index(k, &p)) != 0
                        && strcmpi(nm, s); k++)
                continue;
            if (!nm)
                return luaL_error(L, "unknown intrinsic '%s'", s);
            h->props[h->nprops] = (short) p;
        }
    lua_settop(L, 2);
    if (lua_getfield(L, 2, "spells") == LUA_TTABLE)
        for (h->nspells = 0; h->nspells < MAXLST
             && lua_rawgeti(L, 3, h->nspells + 1) != LUA_TNIL;
             h->nspells++, lua_pop(L, 1))
            h->spells[h->nspells] = (short) objarg(L, -1, SPBOOK_CLASS);
    return 0;
}

/* nh.monster_flags(orig, { nocorpse = true }) */
static int
t_monflags(lua_State *L)
{
    const char *key = luaL_checkstring(L, 1);
    int i, g, n = 0;

    luaL_checktype(L, 2, LUA_TTABLE);
    lua_getfield(L, 2, "nocorpse");
    for (i = 0; i < NUMMONS; i++)
        for (g = 0; g < NUM_MGENDERS; g++)
            if (mn0[i][g] && !strcmp(mn0[i][g], key) && !lua_isnil(L, 3)) {
                mons[i].geno = lua_toboolean(L, 3) ? mons[i].geno | G_NOCORPSE
                                                   : mons[i].geno & ~G_NOCORPSE;
                n++;
            }
    lua_pushinteger(L, n);
    return 1;
}

/* nh.kill_verb("defeat", "defeated") */
static int
t_killverb(lua_State *L)
{
    killverb[0] = dupstr(luaL_checkstring(L, 1));
    killverb[1] = dupstr(luaL_checkstring(L, 2));
    return 0;
}

static const struct luaL_Reg theme_fns[] = {
    { "rename_monster", t_rename_mon }, { "rename_object", t_rename_obj },
    { "rename_appearance", t_rename_look }, { "theme_object", t_theme_obj },
    { "role", t_role }, { "race", t_race }, { "hero", t_hero },
    { "monster_flags", t_monflags }, { "kill_verb", t_killverb }, { 0, 0 }
};

/* stock levels name objects by original name; find_objtype() only knows
   current names, so translate on the way in */
static const char wrapsrc[] =
    "local function fix(a)\n"
    " if type(a) == 'string' then return nh.theme_object(a) or a end\n"
    " if type(a) == 'table' and type(a.id) == 'string' then\n"
    "  a.id = nh.theme_object(a.id, a.class) or a.id end\n"
    " return a end\n"
    "for _, w in ipairs({ { des, 'object' }, { obj, 'new' } }) do\n"
    " local t, k = w[1], w[2]; local f = t[k]\n"
    " t[k] = function(a, ...)\n"
    "  if a == nil then return f() end\n"
    "  return f(fix(a), ...) end end\n";

/* from nhl_init(), for every Lua state */
void
theme_lua_hook(lua_State *L)
{
    lua_getglobal(L, "nh");
    luaL_setfuncs(L, theme_fns, 0);
    lua_pop(L, 1);
    if (objren && luaL_dostring(L, wrapsrc))
        impossible("theme wrapper: %s", lua_tostring(L, -1));
}

/* once per process, before the role menu: snapshot the original names, then
   load theme.lua (public pack) and pack.lua (downstream pack); both optional */
void
theme_init(void)
{
    static boolean done;
    static const char *const packs[] = { "theme.lua", "pack.lua" };
    nhl_sandbox_info sbi = { NHL_SB_SAFE, 1 * 1024 * 1024, 0, 1 * 1024 * 1024 };
    lua_State *L;
    dlb *f;
    int i, g;

    if (done)
        return;
    done = TRUE;
    for (i = 0; i < NUMMONS; i++)
        for (g = 0; g < NUM_MGENDERS; g++)
            mn0[i][g] = mons[i].pmnames[g];
    for (i = 0; i < NUM_OBJECTS; i++)
        on0[i] = obj_descr[i].oc_name, od0[i] = obj_descr[i].oc_descr;
    for (i = 0; i < NUM_ROLES; i++)
        rolekey[i] = roles[i].name.m;
    for (i = 0; i < NUM_RACES; i++)
        racekey[i] = races[i].noun;
    if (!(L = nhl_init(&sbi)))
        return;
    for (i = 0; i < SIZE(packs); i++)
        if ((f = dlb_fopen(packs[i], RDBMODE)) != 0) {
            (void) dlb_fclose(f);
            if (!nhl_loadlua(L, packs[i]))
                break;
        }
    nhl_done(L);
}

/* name_to_monplus() fallback: str starts with the original name of a renamed
   monster, longer than the stock match *lenp (longest match wins, so
   "gnome lord" is not read as "gnome"); same suffixes as the stock loop */
int
theme_mon_orig(const char *str, int *lenp, int *gendp)
{
    int i, g, found = NON_PM;
    size_t l;
    const char *p;

    for (i = LOW_PM; i < NUMMONS; i++)
        for (g = 0; g < NUM_MGENDERS; g++) {
            if (!mn0[i][g] || mn0[i][g] == mons[i].pmnames[g]
                || (l = strlen(mn0[i][g])) <= (size_t) *lenp
                || strncmpi(str, mn0[i][g], (int) l))
                continue;
            p = str + l;
            p += (!strncmpi(p, "es", 2) || !strncmpi(p, "'s", 2)) ? 2
                 : (*p == 's' || *p == '\'');
            if (!*p || *p == ' ')
                *lenp = (int) l, found = i, *gendp = g;
        }
    return found;
}

/* original object name (or appearance) when a pack renamed it, else NULL */
const char *
theme_orig(int otyp, boolean appearance)
{
    int i = appearance ? objects[otyp].oc_descr_idx : otyp;

    if (appearance)
        return od0[i] != obj_descr[i].oc_descr ? od0[i] : (const char *) 0;
    return on0[i] != obj_descr[i].oc_name ? on0[i] : (const char *) 0;
}

const char *
theme_killverb(boolean passive)
{
    return killverb[passive];
}

/* replace the stock kit; identify, wear and wield through the stock path.
   welcome() runs this after the explore-mode wand, the wizard kit and the
   INSURANCE checkpoint already exist */
static void
hero_kit(const struct hero *h)
{
    struct obj *o, *nxt, *held[MAXKIT];
    int k, sk, nheld = 0;

    for (o = gi.invent; o; o = nxt) {
        nxt = o->nobj;
        if (!(discover && o->otyp == WAN_WISHING))
            useupall(o);
    }
    gl.lastinvnr = 51; /* letters restart at 'a' */
    (void) memset(svs.spl_book, 0, sizeof svs.spl_book);
    for (k = 0; k < h->nkit && !u.uroleplay.pauper; k++) {
        if (u.uroleplay.nudist
            && objects[h->kit[k].otyp].oc_class == ARMOR_CLASS)
            continue;
        o = mksobj(h->kit[k].otyp, TRUE, FALSE);
        if (h->kit[k].spe != NOSPE)
            o->spe = h->kit[k].spe;
        else if (o->oclass == WEAPON_CLASS || o->oclass == ARMOR_CLASS)
            o->spe = 0;
        o->quan = h->kit[k].n;
        o->cursed = o->blessed = 0;
        o->known = o->dknown = o->bknown = o->rknown = 1;
        o->owt = weight(o);
        /* skill_init() calls a weapon outside the role's skills a bug */
        sk = weapon_type(o);
        if (sk != P_NONE && !is_ammo(o) && P_RESTRICTED(sk))
            held[nheld++] = o;
        else
            (void) addinv(o);
    }
    u_init_skills_discoveries();
    for (k = 0; k < nheld; k++) {
        sk = weapon_type(held[k]);
        unrestrict_weapon_skill(sk);
        P_SKILL(sk) = P_BASIC;
        P_ADVANCE(sk) = practice_needed_to_advance(P_BASIC - 1);
        o = addinv(held[k]);
        if (is_missile(o)) {
            if (!uquiver)
                setuqwep(o);
        } else if (!uwep && !(uarms && bimanual(o))) {
            /* shortcut: an on-role weapon later in the kit is wielded first */
            setuwep(o);
        }
    }
    if (wizard) { /* the wipe above dropped the wizard kit */
        read_wizkit();
        obj_delivery(FALSE);
    }
}

/* learn the preset spells the stock or preset kit did not teach */
static void
hero_spells(const struct hero *h)
{
    struct obj fake;
    int k;

    for (k = 0; k < h->nspells; k++)
        if (known_spell(h->spells[k]) == spe_Unknown) {
            fake = cg.zeroobj;
            fake.otyp = h->spells[k];
            initialspell(&fake);
        }
}

/* re-grant intrinsics and refresh spells; spell.c's KEEN is 20000 */
static void
hero_tick(const struct hero *h)
{
    int i, k;

    for (k = 0; k < h->nprops; k++)
        u.uprops[h->props[k]].intrinsic |= FROMOUTSIDE;
    for (i = 0; i < MAXSPELL && spellid(i) != NO_SPELL; i++)
        for (k = 0; k < h->nspells; k++)
            if (spellid(i) == h->spells[k])
                spellknow(i) = 20000;
}

/* every l_nhcore_call(), Lua core or not */
void
theme_event(int call)
{
    const struct hero *h;

    if (flags.initrole < 0 || flags.initrole >= NUM_ROLES)
        return;
    h = &hero[flags.initrole];
    if (call == NHCORE_START_NEW_GAME && (h->nkit || h->nspells)) {
        if (h->nkit)
            hero_kit(h);
        hero_spells(h);
#ifdef INSURANCE
        save_currentstate(); /* the checkpoint before welcome() is stock */
#endif
    }
    if (call == NHCORE_START_NEW_GAME || call == NHCORE_RESTORE_OLD_GAME
        || call == NHCORE_MOVELOOP_TURN)
        hero_tick(h);
}
