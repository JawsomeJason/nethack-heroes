/* theme.h - heroes fork: theme pack seam; see heroes/docs/seam.md */
#ifndef THEME_H
#define THEME_H

extern void theme_init(void);               /* once per process, idempotent */
extern void theme_lua_hook(lua_State *);    /* adds nh.* seam functions */
extern void theme_event(int);               /* NHCORE_* call, from nhlua.c */
extern int theme_mon_orig(const char *, int *, int *);
extern const char *theme_orig(int, boolean); /* original obj name/appearance */
extern const char *theme_killverb(boolean); /* TRUE: "killed" form */

#endif /* THEME_H */
