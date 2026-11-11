#!/usr/bin/env bash
# Smoke test for the theme-pack seam: builds, installs into the default
# playground, drives the game in tmux and asserts on captured screens.
# No arguments.  Exit status is non-zero if any check fails.
set -u
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
PG=$ROOT/playground
OUT=$(mktemp -d)
T="tmux -L nhsmoke-$$"
FAILS=0
SCREEN=$OUT/screen.txt
: > "$OUT/all.txt"

cleanup() {
    $T kill-server 2>/dev/null
    rm -f "$PG/pack.lua" "$PG"/smoke*.lua
    if [ -f "$OUT/nhdat.orig" ]; then cp "$OUT/nhdat.orig" "$PG/nhdat"; fi
}
trap cleanup EXIT

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; FAILS=$((FAILS + 1)); }
has() { grep -qF -- "$1" "$SCREEN"; }
check() { if has "$2"; then pass "$1"; else fail "$1 (missing: $2)"; fi; }
checkno() { if has "$2"; then fail "$1 (found: $2)"; else pass "$1"; fi; }

snap() {
    $T capture-pane -p -t g > "$SCREEN" 2>/dev/null
    { echo "=== $1"; cat "$SCREEN"; } >> "${LOG:-$OUT/all.txt}"
}
send() { $T send-keys -t g "$@"; sleep 0.4; }
text() { $T send-keys -t g -l "$1"; sleep 0.3; send Enter; }
waitfor() { # waitfor needle: polls up to 15s, leaves the screen in $SCREEN
    local i
    for i in $(seq 1 30); do
        snap "wait $1"
        has "$1" && return 0
        sleep 0.5
    done
    return 1
}
settle() { # dismiss --More-- pages; $SCREEN then holds every page seen
    local i
    : > "$OUT/pages.txt"
    for i in $(seq 1 15); do
        snap "$1"; cat "$SCREEN" >> "$OUT/pages.txt"
        grep -qF -- "--More--" "$SCREEN" || break
        send Space
    done
    cp "$OUT/pages.txt" "$SCREEN"
}
# launch: MODE (default -D), OPTS (extra options) and RC (extra config lines)
launch() {
    $T kill-server 2>/dev/null; sleep 1 # a hangup save may be written
    printf 'OPTIONS=!tutorial,!autopickup,!tips%s\n%s\n' "${OPTS:-}" "${RC:-}" > "$OUT/nhrc"
    $T new-session -d -x 100 -y 30 -s g \
        "cd $PG && NETHACKOPTIONS=$OUT/nhrc ./nethack ${MODE:--D} -u smoke 2>>$OUT/err.txt; sleep 30"
}
# newgame <role name as the menu shows it>: leaves the first menu in menu.txt
newgame() {
    local key
    $T kill-server 2>/dev/null; sleep 1
    find "$PG/save" -type f -delete
    rm -f "$PG"/[0-9]*wizard.[0-9]* "$PG"/[0-9]*smoke.[0-9]* # crash leftovers
    launch
    waitfor "Shall I pick" && send n
    waitfor "Pick a role" || return 1
    cp "$SCREEN" "$OUT/menu.txt"
    key=$(grep -oE "[A-Za-z] - an? $1" "$SCREEN" | head -1 | cut -c1)
    [ -n "$key" ] || return 1
    send "$key"; waitfor "Pick a race"; send h
    waitfor "alignment"; send n
    waitfor "Is this ok"; send y
    waitfor "Dlvl:1" || settle start
    settle start
}
inv() { send i; snap inventory; send Escape; }
LEVERR="impossible|panic|Program in disorder|Please report|Lua error|Unknown (object|monster)"
create() { send C-g; waitfor "Create what kind"; text "$1"; settle "create $1"; }
wish() { send C-w; waitfor "For what do you wish"; text "$1"; settle "wish $1"; }
# loaddes <file>: wizard-load a level file; $SCREEN holds every page shown
loaddes() {
    send "#wizloaddes"; send Enter; waitfor "Load which des"; text "$1"
    settle "load $1"; send Escape
}
# kill_one <name>: create it and attack until a kill message shows
kill_one() {
    local try r c mr mc dir
    for try in 1 2 3 4 5; do
        create "$1"
        for hit in 1 2 3 4 5 6; do
            snap "locate"
            read -r mr mc cr cc < <(awk '
                { i = index($0, "@"); if (i && NR > 1 && NR < 22) { ar = NR; ac = i } }
                { s = $0; for (j = 1; j <= length(s); j++) if (substr(s, j, 1) == ":") { r[NR] = 1; c[NR] = j; n++; rr[n] = NR; cc[n] = j } }
                END { for (k = 1; k <= n; k++) { dr = rr[k] - ar; dc = cc[k] - ac;
                        if (dr >= -1 && dr <= 1 && dc >= -1 && dc <= 1 && (dr || dc)) { print dr, dc, rr[k], cc[k]; exit } }
                      print 9, 9, 0, 0 }' "$SCREEN")
            [ "$mr" = 9 ] && break
            case "$mr,$mc" in
                -1,-1) dir=y;; -1,0) dir=k;; -1,1) dir=u;; 0,-1) dir=h;;
                0,1) dir=l;; 1,-1) dir=b;; 1,0) dir=j;; 1,1) dir=n;;
            esac
            send F; send "$dir"; settle "attack"
            if has "You defeat" || has "You kill"; then
                KILLROW=$cr; KILLCOL=$cc; return 0
            fi
        done
    done
    return 1
}

# ---- build ---------------------------------------------------------------
cd "$ROOT" || exit 1
if (cd sys/unix && sh setup.sh hints/linux.501) >"$OUT/build.log" 2>&1 \
   && make -j8 all >>"$OUT/build.log" 2>&1 \
   && make install >>"$OUT/build.log" 2>&1; then
    pass "build and install"
else
    fail "build and install (see $OUT/build.log)"; exit 1
fi
sed -i 's/^WIZARDS=.*/WIZARDS=*/' "$PG/sysconf"
rm -f "$PG/pack.lua"
echo 'des.object("no such thing")' > "$PG/smokebad.lua"
echo 'nh.pline("ruby check: class " .. obj.new("ruby"):totable().oclass)' > "$PG/smokeruby.lua"

# ---- public pack only ----------------------------------------------------
: > "$OUT/err.txt"
if newgame "Thunder warrior"; then
    cp "$OUT/menu.txt" "$SCREEN"
    check "role menu shows Thunder warrior" "Thunder warrior"
    checkno "role menu hides Valkyrie" "Valkyrie"
    inv
    check "kit: war hammer wielded" "war hammer (weapon in"
    check "kit: small shield worn" "small shield (being worn)"
    check "kit: renamed dagger present" "stun baton"
    check "kit: potions use the renamed object" "med-spray"
    checkno "kit: stock long sword replaced" "long sword"
    send +; snap spells; send Escape
    check "permanent spell in spell menu" "force bolt"
    $T send-keys -t g -H 3b; sleep 0.4; settle look; send m; send .; settle sidekick
    check "sidekick is the non-eating pet" "tame recon drone"
    send C-x; snap attributes1
    check "role renamed in attributes" "Thunder warrior"
    send ">"; snap attributes2; send Escape
    check "regeneration intrinsic granted" "You regenerate"
    # ^T from the entrance (10,7) to beside the launch bay portal (72,13)
    send C-t; waitfor "Where do you want"
    for k in L L L L L L L l l l l l l j j j j j j; do send $k; done
    send .; settle teleport
    check "new game starts on the headquarters entrance" "MISSION GATE"
    send C-e; settle detect; send "^"; send l; settle trap
    check "the headquarters portal is on the map" "That is a magic portal"
    create "street thug"
    check "wizard create by themed name" "street thug appears"
    create "gnome lord"
    check "wizard create by original name" "street thug appears"
    wish "plasma blade"
    check "wish by themed name" "plasma blade"
    wish "long sword"
    check "wish by original name" "plasma blade"
    wish "newt corpse"
    checkno "no-corpse flag blocks the corpse wish" "gutter rat corpse"
    if kill_one newt; then
        check "kill prints defeat" "You defeat the gutter rat"
    else
        fail "kill prints defeat (could not kill)"
    fi
    LOG=$OUT/control.txt loaddes smokebad.lua # kept out of all.txt
    if grep -qiE "$LEVERR" "$OUT/control.txt"; then pass "control: a bad name in a level is reported"
    else fail "control: a bad name in a level is reported"; fi
    for lv in "minefill.lua names gnome lord" "tower3.lua names long sword"; do
        loaddes "${lv%% *}"
        if grep -qiE "$LEVERR" "$SCREEN"; then fail "stock level $lv: loads"
        else pass "stock level $lv: loads"; fi
    done
    send S; waitfor "save" ; send y; sleep 3
    launch
    sleep 2; settle restored
    if has "keep the save file"; then send n; settle restored2; fi
    inv
    check "restore keeps war hammer wielded" "war hammer (weapon in"
    check "restore keeps renamed items" "stun baton"
    send +; snap spells; send Escape
    check "restore keeps the spell" "force bolt"
    send C-x; snap attributes1
    check "restore shows themed role" "Thunder warrior"
    send ">"; snap attributes2; send Escape
    check "restore keeps regeneration" "You regenerate"
else
    fail "public pack: could not start a game"
fi

# ---- downstream pack.lua overrides theme.lua -----------------------------
cat > "$PG/pack.lua" <<'LUA'
nh.rename_monster("newt", "sewer thing")
nh.rename_object("dagger", "shock rod")
LUA
if newgame "Thunder warrior"; then
    inv
    check "pack.lua renames an object over theme.lua" "shock rod"
    checkno "theme.lua name is overridden" "stun baton"
    create newt
    check "pack.lua renames a monster over theme.lua" "sewer thing appears"
else
    fail "pack.lua: could not start a game"
fi
rm -f "$PG/pack.lua"

# ---- hero preset edge cases ---------------------------------------------
cat > "$PG/pack.lua" <<'LUA'
nh.rename_appearance("ruby", "red gel", "!")
nh.hero("Valkyrie", {
  kit = { "war hammer", "bow", "spellbook of force bolt", "small shield" },
  spells = { "force bolt" },
})
LUA
if newgame "Thunder warrior"; then
    inv
    check "preset: kit weapon outside the role's skills is carried" "bow"
    if grep -qF "curr > max" "$OUT/all.txt"; then fail "preset: no skill_init error for an off-role weapon"
    else pass "preset: no skill_init error for an off-role weapon"; fi
    if grep -qF "already known" "$OUT/all.txt"; then fail "preset: spell in kit book and spells list is learned once"
    else pass "preset: spell in kit book and spells list is learned once"; fi
    # the first #wizloaddes on the headquarters reports "Couldn't place lregion"
    LOG=$OUT/ruby.txt loaddes smokeruby.lua
    check "original object name beats a renamed appearance" "ruby check: class *"
else
    fail "preset edge cases: could not start a game"
fi
rm -f "$PG/pack.lua"

if OPTS=,pauper newgame "Thunder warrior"; then
    inv
    check "pauper: no preset kit" "Not carrying anything"
else
    fail "pauper: could not start a game"
fi
echo "magic marker" > "$OUT/wizkit.txt"
if OPTS=,nudist RC="WIZKIT=$OUT/wizkit.txt" newgame "Thunder warrior"; then
    inv
    check "nudist: preset weapon given" "war hammer"
    checkno "nudist: no preset armour" "small shield"
    check "wizard kit survives the preset" "magic marker"
else
    fail "nudist: could not start a game"
fi
if MODE=-X newgame "Thunder warrior"; then
    inv
    check "explore mode wand survives the preset" "wand of wishing"
    check "explore mode gets the preset kit" "war hammer"
else
    fail "explore: could not start a game"
fi

if newgame "Thunder warrior"; then
    pp=$($T list-panes -t g -F '#{pane_pid}')
    kill -KILL "$(pgrep -P "$pp" -x nethack)"; sleep 1
    launch; waitfor "Recover"; send r; settle recovered
    if has "keep the save file"; then send n; settle recovered2; fi
    inv
    check "crash recovery keeps the preset kit" "war hammer (weapon in"
    send +; snap spells; send Escape
    check "crash recovery keeps the preset spell" "force bolt"
else
    fail "crash recovery: could not start a game"
fi

# ---- no theme.lua, no pack.lua: stock game -------------------------------
cp "$PG/nhdat" "$OUT/nhdat.orig"
mkdir "$OUT/dat"
( cd "$OUT/dat" && "$ROOT/util/dlb" xf "$PG/nhdat" && rm -f theme.lua \
  && "$ROOT/util/dlb" cf "$OUT/nhdat.stock" $(ls) ) >>"$OUT/build.log" 2>&1
cp "$OUT/nhdat.stock" "$PG/nhdat"
if newgame Valkyrie; then
    cp "$OUT/menu.txt" "$SCREEN"
    check "stock: role menu shows Valkyrie" "Valkyrie"
    checkno "stock: role menu hides Thunder warrior" "Thunder warrior"
    inv
    check "stock: stock kit (spear, unrenamed dagger)" "+0 dagger"
    if kill_one newt; then
        check "stock: kill prints kill" "You kill the newt"
    else
        fail "stock: kill prints kill (could not kill)"
    fi
else
    fail "stock: could not start a game"
fi
cp "$OUT/nhdat.orig" "$PG/nhdat"; rm -f "$OUT/nhdat.orig"

# ---- global -------------------------------------------------------------
if grep -qiE "$LEVERR" "$OUT/all.txt" "$OUT/err.txt"; then
    fail "no impossible/panic/Lua error in any capture (see $OUT/all.txt)"
else
    pass "no impossible/panic/Lua error in any capture"
fi
echo "captures: $OUT/all.txt"
[ "$FAILS" = 0 ]
