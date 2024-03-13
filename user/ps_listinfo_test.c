#include "kernel/types.h"
#include "user/user.h"
#include "kernel/procinfo.h"

void test_correct() {
  const int lim = 64;
  struct procinfo *plist = malloc(sizeof(struct procinfo) * lim);
  int code = ps_listinfo(plist, lim);
  printf("Test 1. Expected: %d; Answer: %d\n", 3, code);
  // Содержимое plist можно увидеть при использовании утилиты ps,
  // поэтому в тестах его не проверяю
}

void test_small_buf_size() {
  const int lim = 2;
  struct procinfo *plist = malloc(sizeof(struct procinfo) * 64);
  int code = ps_listinfo(plist, lim);
  printf("Test 2. Expected: %d; Answer: %d\n", -1, code);
}

void test_incorrect_buf_size() {
  const int lim = -5;
  struct procinfo *plist = malloc(sizeof(struct procinfo) * 64);
  int code = ps_listinfo(plist, lim);
  printf("Test 3. Expected: %d; Answer: %d\n", -1, code);
}

void test_incorrect_address() {
  const int lim = 64;
  struct procinfo *plist = (struct procinfo*)1232342342342323;
  int code = ps_listinfo(plist, lim);
  printf("Test 4. Expected: %d; Answer: %d\n", -2, code);
}

int main(int argc, char *argv[])
{
  test_correct();
  test_small_buf_size();
  test_incorrect_buf_size();
  test_incorrect_address();
  exit(0);
}
