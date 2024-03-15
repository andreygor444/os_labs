#include "kernel/types.h"
#include "user/user.h"
#include "kernel/procinfo.h"

int main(int argc, char *argv[])
{
  int lim = 2, code;
  struct procinfo *plist;
  
  while (1) {
    plist = malloc(sizeof(struct procinfo) * lim);
    code = ps_listinfo(plist, lim);
    if (code != -1 && code <= lim)
      break;
    free(plist);
    lim *= 2;
  }
  if (code < 0)
    exit(code);

  const int NSTATES = 6;
  static char *states[] = {
    "unused", "used", "sleep", "runble", "run", "zombie"
  };

  struct procinfo *p;
  char state[6];
  for (p = plist; p < plist + code; p++) {
    if(p->state >= 0 && p->state < NSTATES && states[p->state])
      strcpy(state, states[p->state]);
    else
      strcpy(state, "???");
    printf("name: %s\tstate: %s\tparent pid: %d\n", p->name, state, p->parent_pid);
  }
  free(plist);
  exit(0);
}
