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
  
  struct procinfo *p;
  for (p = plist; p < plist + code; p++)
    printf("name: %s\tstate: %s\tparent pid: %d\n", p->name, p->state, p->parent_pid);
  free(plist);
  exit(0);
}
