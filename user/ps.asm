
user/_ps:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"
#include "kernel/procinfo.h"

int main(int argc, char *argv[])
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	e052                	sd	s4,0(sp)
   e:	1800                	addi	s0,sp,48
  int lim = 2, code;
  10:	4489                	li	s1,2
  struct procinfo *plist;
  
  while (1) {
    plist = malloc(sizeof(struct procinfo) * lim);
    code = ps_listinfo(plist, lim);
    if (code != -1 && code <= lim)
  12:	59fd                	li	s3,-1
  14:	a801                	j	24 <main+0x24>
      break;
    free(plist);
  16:	854a                	mv	a0,s2
  18:	00000097          	auipc	ra,0x0
  1c:	6b6080e7          	jalr	1718(ra) # 6ce <free>
    lim *= 2;
  20:	0014949b          	slliw	s1,s1,0x1
    plist = malloc(sizeof(struct procinfo) * lim);
  24:	0034951b          	slliw	a0,s1,0x3
  28:	9d05                	subw	a0,a0,s1
  2a:	0025151b          	slliw	a0,a0,0x2
  2e:	00000097          	auipc	ra,0x0
  32:	722080e7          	jalr	1826(ra) # 750 <malloc>
  36:	892a                	mv	s2,a0
    code = ps_listinfo(plist, lim);
  38:	85a6                	mv	a1,s1
  3a:	00000097          	auipc	ra,0x0
  3e:	37c080e7          	jalr	892(ra) # 3b6 <ps_listinfo>
    if (code != -1 && code <= lim)
  42:	fd350ae3          	beq	a0,s3,16 <main+0x16>
  46:	fca4c8e3          	blt	s1,a0,16 <main+0x16>
  }
  
  struct procinfo *p;
  for (p = plist; p < plist + code; p++)
  4a:	00351993          	slli	s3,a0,0x3
  4e:	40a989b3          	sub	s3,s3,a0
  52:	098a                	slli	s3,s3,0x2
  54:	99ca                	add	s3,s3,s2
    plist = malloc(sizeof(struct procinfo) * lim);
  56:	84ca                	mv	s1,s2
    printf("name: %s\tstate: %s\tparent pid: %d\n", p->name, p->state, p->parent_pid);
  58:	00000a17          	auipc	s4,0x0
  5c:	7e8a0a13          	addi	s4,s4,2024 # 840 <malloc+0xf0>
  for (p = plist; p < plist + code; p++)
  60:	01397e63          	bgeu	s2,s3,7c <main+0x7c>
    printf("name: %s\tstate: %s\tparent pid: %d\n", p->name, p->state, p->parent_pid);
  64:	4c94                	lw	a3,24(s1)
  66:	01048613          	addi	a2,s1,16
  6a:	85a6                	mv	a1,s1
  6c:	8552                	mv	a0,s4
  6e:	00000097          	auipc	ra,0x0
  72:	62a080e7          	jalr	1578(ra) # 698 <printf>
  for (p = plist; p < plist + code; p++)
  76:	04f1                	addi	s1,s1,28
  78:	ff34e6e3          	bltu	s1,s3,64 <main+0x64>
  free(plist);
  7c:	854a                	mv	a0,s2
  7e:	00000097          	auipc	ra,0x0
  82:	650080e7          	jalr	1616(ra) # 6ce <free>
  exit(0);
  86:	4501                	li	a0,0
  88:	00000097          	auipc	ra,0x0
  8c:	28e080e7          	jalr	654(ra) # 316 <exit>

0000000000000090 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  90:	1141                	addi	sp,sp,-16
  92:	e406                	sd	ra,8(sp)
  94:	e022                	sd	s0,0(sp)
  96:	0800                	addi	s0,sp,16
  extern int main();
  main();
  98:	00000097          	auipc	ra,0x0
  9c:	f68080e7          	jalr	-152(ra) # 0 <main>
  exit(0);
  a0:	4501                	li	a0,0
  a2:	00000097          	auipc	ra,0x0
  a6:	274080e7          	jalr	628(ra) # 316 <exit>

00000000000000aa <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  aa:	1141                	addi	sp,sp,-16
  ac:	e422                	sd	s0,8(sp)
  ae:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  b0:	87aa                	mv	a5,a0
  b2:	0585                	addi	a1,a1,1
  b4:	0785                	addi	a5,a5,1
  b6:	fff5c703          	lbu	a4,-1(a1)
  ba:	fee78fa3          	sb	a4,-1(a5)
  be:	fb75                	bnez	a4,b2 <strcpy+0x8>
    ;
  return os;
}
  c0:	6422                	ld	s0,8(sp)
  c2:	0141                	addi	sp,sp,16
  c4:	8082                	ret

00000000000000c6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  c6:	1141                	addi	sp,sp,-16
  c8:	e422                	sd	s0,8(sp)
  ca:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  cc:	00054783          	lbu	a5,0(a0)
  d0:	cb91                	beqz	a5,e4 <strcmp+0x1e>
  d2:	0005c703          	lbu	a4,0(a1)
  d6:	00f71763          	bne	a4,a5,e4 <strcmp+0x1e>
    p++, q++;
  da:	0505                	addi	a0,a0,1
  dc:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  de:	00054783          	lbu	a5,0(a0)
  e2:	fbe5                	bnez	a5,d2 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  e4:	0005c503          	lbu	a0,0(a1)
}
  e8:	40a7853b          	subw	a0,a5,a0
  ec:	6422                	ld	s0,8(sp)
  ee:	0141                	addi	sp,sp,16
  f0:	8082                	ret

00000000000000f2 <strlen>:

uint
strlen(const char *s)
{
  f2:	1141                	addi	sp,sp,-16
  f4:	e422                	sd	s0,8(sp)
  f6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  f8:	00054783          	lbu	a5,0(a0)
  fc:	cf91                	beqz	a5,118 <strlen+0x26>
  fe:	0505                	addi	a0,a0,1
 100:	87aa                	mv	a5,a0
 102:	4685                	li	a3,1
 104:	9e89                	subw	a3,a3,a0
 106:	00f6853b          	addw	a0,a3,a5
 10a:	0785                	addi	a5,a5,1
 10c:	fff7c703          	lbu	a4,-1(a5)
 110:	fb7d                	bnez	a4,106 <strlen+0x14>
    ;
  return n;
}
 112:	6422                	ld	s0,8(sp)
 114:	0141                	addi	sp,sp,16
 116:	8082                	ret
  for(n = 0; s[n]; n++)
 118:	4501                	li	a0,0
 11a:	bfe5                	j	112 <strlen+0x20>

000000000000011c <memset>:

void*
memset(void *dst, int c, uint n)
{
 11c:	1141                	addi	sp,sp,-16
 11e:	e422                	sd	s0,8(sp)
 120:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 122:	ca19                	beqz	a2,138 <memset+0x1c>
 124:	87aa                	mv	a5,a0
 126:	1602                	slli	a2,a2,0x20
 128:	9201                	srli	a2,a2,0x20
 12a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 12e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 132:	0785                	addi	a5,a5,1
 134:	fee79de3          	bne	a5,a4,12e <memset+0x12>
  }
  return dst;
}
 138:	6422                	ld	s0,8(sp)
 13a:	0141                	addi	sp,sp,16
 13c:	8082                	ret

000000000000013e <strchr>:

char*
strchr(const char *s, char c)
{
 13e:	1141                	addi	sp,sp,-16
 140:	e422                	sd	s0,8(sp)
 142:	0800                	addi	s0,sp,16
  for(; *s; s++)
 144:	00054783          	lbu	a5,0(a0)
 148:	cb99                	beqz	a5,15e <strchr+0x20>
    if(*s == c)
 14a:	00f58763          	beq	a1,a5,158 <strchr+0x1a>
  for(; *s; s++)
 14e:	0505                	addi	a0,a0,1
 150:	00054783          	lbu	a5,0(a0)
 154:	fbfd                	bnez	a5,14a <strchr+0xc>
      return (char*)s;
  return 0;
 156:	4501                	li	a0,0
}
 158:	6422                	ld	s0,8(sp)
 15a:	0141                	addi	sp,sp,16
 15c:	8082                	ret
  return 0;
 15e:	4501                	li	a0,0
 160:	bfe5                	j	158 <strchr+0x1a>

0000000000000162 <gets>:

char*
gets(char *buf, int max)
{
 162:	711d                	addi	sp,sp,-96
 164:	ec86                	sd	ra,88(sp)
 166:	e8a2                	sd	s0,80(sp)
 168:	e4a6                	sd	s1,72(sp)
 16a:	e0ca                	sd	s2,64(sp)
 16c:	fc4e                	sd	s3,56(sp)
 16e:	f852                	sd	s4,48(sp)
 170:	f456                	sd	s5,40(sp)
 172:	f05a                	sd	s6,32(sp)
 174:	ec5e                	sd	s7,24(sp)
 176:	1080                	addi	s0,sp,96
 178:	8baa                	mv	s7,a0
 17a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 17c:	892a                	mv	s2,a0
 17e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 180:	4aa9                	li	s5,10
 182:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 184:	89a6                	mv	s3,s1
 186:	2485                	addiw	s1,s1,1
 188:	0344d863          	bge	s1,s4,1b8 <gets+0x56>
    cc = read(0, &c, 1);
 18c:	4605                	li	a2,1
 18e:	faf40593          	addi	a1,s0,-81
 192:	4501                	li	a0,0
 194:	00000097          	auipc	ra,0x0
 198:	19a080e7          	jalr	410(ra) # 32e <read>
    if(cc < 1)
 19c:	00a05e63          	blez	a0,1b8 <gets+0x56>
    buf[i++] = c;
 1a0:	faf44783          	lbu	a5,-81(s0)
 1a4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1a8:	01578763          	beq	a5,s5,1b6 <gets+0x54>
 1ac:	0905                	addi	s2,s2,1
 1ae:	fd679be3          	bne	a5,s6,184 <gets+0x22>
  for(i=0; i+1 < max; ){
 1b2:	89a6                	mv	s3,s1
 1b4:	a011                	j	1b8 <gets+0x56>
 1b6:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1b8:	99de                	add	s3,s3,s7
 1ba:	00098023          	sb	zero,0(s3)
  return buf;
}
 1be:	855e                	mv	a0,s7
 1c0:	60e6                	ld	ra,88(sp)
 1c2:	6446                	ld	s0,80(sp)
 1c4:	64a6                	ld	s1,72(sp)
 1c6:	6906                	ld	s2,64(sp)
 1c8:	79e2                	ld	s3,56(sp)
 1ca:	7a42                	ld	s4,48(sp)
 1cc:	7aa2                	ld	s5,40(sp)
 1ce:	7b02                	ld	s6,32(sp)
 1d0:	6be2                	ld	s7,24(sp)
 1d2:	6125                	addi	sp,sp,96
 1d4:	8082                	ret

00000000000001d6 <stat>:

int
stat(const char *n, struct stat *st)
{
 1d6:	1101                	addi	sp,sp,-32
 1d8:	ec06                	sd	ra,24(sp)
 1da:	e822                	sd	s0,16(sp)
 1dc:	e426                	sd	s1,8(sp)
 1de:	e04a                	sd	s2,0(sp)
 1e0:	1000                	addi	s0,sp,32
 1e2:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1e4:	4581                	li	a1,0
 1e6:	00000097          	auipc	ra,0x0
 1ea:	170080e7          	jalr	368(ra) # 356 <open>
  if(fd < 0)
 1ee:	02054563          	bltz	a0,218 <stat+0x42>
 1f2:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1f4:	85ca                	mv	a1,s2
 1f6:	00000097          	auipc	ra,0x0
 1fa:	178080e7          	jalr	376(ra) # 36e <fstat>
 1fe:	892a                	mv	s2,a0
  close(fd);
 200:	8526                	mv	a0,s1
 202:	00000097          	auipc	ra,0x0
 206:	13c080e7          	jalr	316(ra) # 33e <close>
  return r;
}
 20a:	854a                	mv	a0,s2
 20c:	60e2                	ld	ra,24(sp)
 20e:	6442                	ld	s0,16(sp)
 210:	64a2                	ld	s1,8(sp)
 212:	6902                	ld	s2,0(sp)
 214:	6105                	addi	sp,sp,32
 216:	8082                	ret
    return -1;
 218:	597d                	li	s2,-1
 21a:	bfc5                	j	20a <stat+0x34>

000000000000021c <atoi>:

int
atoi(const char *s)
{
 21c:	1141                	addi	sp,sp,-16
 21e:	e422                	sd	s0,8(sp)
 220:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 222:	00054683          	lbu	a3,0(a0)
 226:	fd06879b          	addiw	a5,a3,-48
 22a:	0ff7f793          	zext.b	a5,a5
 22e:	4625                	li	a2,9
 230:	02f66863          	bltu	a2,a5,260 <atoi+0x44>
 234:	872a                	mv	a4,a0
  n = 0;
 236:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 238:	0705                	addi	a4,a4,1
 23a:	0025179b          	slliw	a5,a0,0x2
 23e:	9fa9                	addw	a5,a5,a0
 240:	0017979b          	slliw	a5,a5,0x1
 244:	9fb5                	addw	a5,a5,a3
 246:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 24a:	00074683          	lbu	a3,0(a4)
 24e:	fd06879b          	addiw	a5,a3,-48
 252:	0ff7f793          	zext.b	a5,a5
 256:	fef671e3          	bgeu	a2,a5,238 <atoi+0x1c>
  return n;
}
 25a:	6422                	ld	s0,8(sp)
 25c:	0141                	addi	sp,sp,16
 25e:	8082                	ret
  n = 0;
 260:	4501                	li	a0,0
 262:	bfe5                	j	25a <atoi+0x3e>

0000000000000264 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 264:	1141                	addi	sp,sp,-16
 266:	e422                	sd	s0,8(sp)
 268:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 26a:	02b57463          	bgeu	a0,a1,292 <memmove+0x2e>
    while(n-- > 0)
 26e:	00c05f63          	blez	a2,28c <memmove+0x28>
 272:	1602                	slli	a2,a2,0x20
 274:	9201                	srli	a2,a2,0x20
 276:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 27a:	872a                	mv	a4,a0
      *dst++ = *src++;
 27c:	0585                	addi	a1,a1,1
 27e:	0705                	addi	a4,a4,1
 280:	fff5c683          	lbu	a3,-1(a1)
 284:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 288:	fee79ae3          	bne	a5,a4,27c <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 28c:	6422                	ld	s0,8(sp)
 28e:	0141                	addi	sp,sp,16
 290:	8082                	ret
    dst += n;
 292:	00c50733          	add	a4,a0,a2
    src += n;
 296:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 298:	fec05ae3          	blez	a2,28c <memmove+0x28>
 29c:	fff6079b          	addiw	a5,a2,-1
 2a0:	1782                	slli	a5,a5,0x20
 2a2:	9381                	srli	a5,a5,0x20
 2a4:	fff7c793          	not	a5,a5
 2a8:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2aa:	15fd                	addi	a1,a1,-1
 2ac:	177d                	addi	a4,a4,-1
 2ae:	0005c683          	lbu	a3,0(a1)
 2b2:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2b6:	fee79ae3          	bne	a5,a4,2aa <memmove+0x46>
 2ba:	bfc9                	j	28c <memmove+0x28>

00000000000002bc <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2bc:	1141                	addi	sp,sp,-16
 2be:	e422                	sd	s0,8(sp)
 2c0:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2c2:	ca05                	beqz	a2,2f2 <memcmp+0x36>
 2c4:	fff6069b          	addiw	a3,a2,-1
 2c8:	1682                	slli	a3,a3,0x20
 2ca:	9281                	srli	a3,a3,0x20
 2cc:	0685                	addi	a3,a3,1
 2ce:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2d0:	00054783          	lbu	a5,0(a0)
 2d4:	0005c703          	lbu	a4,0(a1)
 2d8:	00e79863          	bne	a5,a4,2e8 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2dc:	0505                	addi	a0,a0,1
    p2++;
 2de:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2e0:	fed518e3          	bne	a0,a3,2d0 <memcmp+0x14>
  }
  return 0;
 2e4:	4501                	li	a0,0
 2e6:	a019                	j	2ec <memcmp+0x30>
      return *p1 - *p2;
 2e8:	40e7853b          	subw	a0,a5,a4
}
 2ec:	6422                	ld	s0,8(sp)
 2ee:	0141                	addi	sp,sp,16
 2f0:	8082                	ret
  return 0;
 2f2:	4501                	li	a0,0
 2f4:	bfe5                	j	2ec <memcmp+0x30>

00000000000002f6 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2f6:	1141                	addi	sp,sp,-16
 2f8:	e406                	sd	ra,8(sp)
 2fa:	e022                	sd	s0,0(sp)
 2fc:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2fe:	00000097          	auipc	ra,0x0
 302:	f66080e7          	jalr	-154(ra) # 264 <memmove>
}
 306:	60a2                	ld	ra,8(sp)
 308:	6402                	ld	s0,0(sp)
 30a:	0141                	addi	sp,sp,16
 30c:	8082                	ret

000000000000030e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 30e:	4885                	li	a7,1
 ecall
 310:	00000073          	ecall
 ret
 314:	8082                	ret

0000000000000316 <exit>:
.global exit
exit:
 li a7, SYS_exit
 316:	4889                	li	a7,2
 ecall
 318:	00000073          	ecall
 ret
 31c:	8082                	ret

000000000000031e <wait>:
.global wait
wait:
 li a7, SYS_wait
 31e:	488d                	li	a7,3
 ecall
 320:	00000073          	ecall
 ret
 324:	8082                	ret

0000000000000326 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 326:	4891                	li	a7,4
 ecall
 328:	00000073          	ecall
 ret
 32c:	8082                	ret

000000000000032e <read>:
.global read
read:
 li a7, SYS_read
 32e:	4895                	li	a7,5
 ecall
 330:	00000073          	ecall
 ret
 334:	8082                	ret

0000000000000336 <write>:
.global write
write:
 li a7, SYS_write
 336:	48c1                	li	a7,16
 ecall
 338:	00000073          	ecall
 ret
 33c:	8082                	ret

000000000000033e <close>:
.global close
close:
 li a7, SYS_close
 33e:	48d5                	li	a7,21
 ecall
 340:	00000073          	ecall
 ret
 344:	8082                	ret

0000000000000346 <kill>:
.global kill
kill:
 li a7, SYS_kill
 346:	4899                	li	a7,6
 ecall
 348:	00000073          	ecall
 ret
 34c:	8082                	ret

000000000000034e <exec>:
.global exec
exec:
 li a7, SYS_exec
 34e:	489d                	li	a7,7
 ecall
 350:	00000073          	ecall
 ret
 354:	8082                	ret

0000000000000356 <open>:
.global open
open:
 li a7, SYS_open
 356:	48bd                	li	a7,15
 ecall
 358:	00000073          	ecall
 ret
 35c:	8082                	ret

000000000000035e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 35e:	48c5                	li	a7,17
 ecall
 360:	00000073          	ecall
 ret
 364:	8082                	ret

0000000000000366 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 366:	48c9                	li	a7,18
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 36e:	48a1                	li	a7,8
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <link>:
.global link
link:
 li a7, SYS_link
 376:	48cd                	li	a7,19
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 37e:	48d1                	li	a7,20
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 386:	48a5                	li	a7,9
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <dup>:
.global dup
dup:
 li a7, SYS_dup
 38e:	48a9                	li	a7,10
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 396:	48ad                	li	a7,11
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 39e:	48b1                	li	a7,12
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3a6:	48b5                	li	a7,13
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3ae:	48b9                	li	a7,14
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <ps_listinfo>:
.global ps_listinfo
ps_listinfo:
 li a7, SYS_ps_listinfo
 3b6:	48d9                	li	a7,22
 ecall
 3b8:	00000073          	ecall
 ret
 3bc:	8082                	ret

00000000000003be <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3be:	1101                	addi	sp,sp,-32
 3c0:	ec06                	sd	ra,24(sp)
 3c2:	e822                	sd	s0,16(sp)
 3c4:	1000                	addi	s0,sp,32
 3c6:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3ca:	4605                	li	a2,1
 3cc:	fef40593          	addi	a1,s0,-17
 3d0:	00000097          	auipc	ra,0x0
 3d4:	f66080e7          	jalr	-154(ra) # 336 <write>
}
 3d8:	60e2                	ld	ra,24(sp)
 3da:	6442                	ld	s0,16(sp)
 3dc:	6105                	addi	sp,sp,32
 3de:	8082                	ret

00000000000003e0 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3e0:	7139                	addi	sp,sp,-64
 3e2:	fc06                	sd	ra,56(sp)
 3e4:	f822                	sd	s0,48(sp)
 3e6:	f426                	sd	s1,40(sp)
 3e8:	f04a                	sd	s2,32(sp)
 3ea:	ec4e                	sd	s3,24(sp)
 3ec:	0080                	addi	s0,sp,64
 3ee:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3f0:	c299                	beqz	a3,3f6 <printint+0x16>
 3f2:	0805c963          	bltz	a1,484 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3f6:	2581                	sext.w	a1,a1
  neg = 0;
 3f8:	4881                	li	a7,0
 3fa:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3fe:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 400:	2601                	sext.w	a2,a2
 402:	00000517          	auipc	a0,0x0
 406:	4c650513          	addi	a0,a0,1222 # 8c8 <digits>
 40a:	883a                	mv	a6,a4
 40c:	2705                	addiw	a4,a4,1
 40e:	02c5f7bb          	remuw	a5,a1,a2
 412:	1782                	slli	a5,a5,0x20
 414:	9381                	srli	a5,a5,0x20
 416:	97aa                	add	a5,a5,a0
 418:	0007c783          	lbu	a5,0(a5)
 41c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 420:	0005879b          	sext.w	a5,a1
 424:	02c5d5bb          	divuw	a1,a1,a2
 428:	0685                	addi	a3,a3,1
 42a:	fec7f0e3          	bgeu	a5,a2,40a <printint+0x2a>
  if(neg)
 42e:	00088c63          	beqz	a7,446 <printint+0x66>
    buf[i++] = '-';
 432:	fd070793          	addi	a5,a4,-48
 436:	00878733          	add	a4,a5,s0
 43a:	02d00793          	li	a5,45
 43e:	fef70823          	sb	a5,-16(a4)
 442:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 446:	02e05863          	blez	a4,476 <printint+0x96>
 44a:	fc040793          	addi	a5,s0,-64
 44e:	00e78933          	add	s2,a5,a4
 452:	fff78993          	addi	s3,a5,-1
 456:	99ba                	add	s3,s3,a4
 458:	377d                	addiw	a4,a4,-1
 45a:	1702                	slli	a4,a4,0x20
 45c:	9301                	srli	a4,a4,0x20
 45e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 462:	fff94583          	lbu	a1,-1(s2)
 466:	8526                	mv	a0,s1
 468:	00000097          	auipc	ra,0x0
 46c:	f56080e7          	jalr	-170(ra) # 3be <putc>
  while(--i >= 0)
 470:	197d                	addi	s2,s2,-1
 472:	ff3918e3          	bne	s2,s3,462 <printint+0x82>
}
 476:	70e2                	ld	ra,56(sp)
 478:	7442                	ld	s0,48(sp)
 47a:	74a2                	ld	s1,40(sp)
 47c:	7902                	ld	s2,32(sp)
 47e:	69e2                	ld	s3,24(sp)
 480:	6121                	addi	sp,sp,64
 482:	8082                	ret
    x = -xx;
 484:	40b005bb          	negw	a1,a1
    neg = 1;
 488:	4885                	li	a7,1
    x = -xx;
 48a:	bf85                	j	3fa <printint+0x1a>

000000000000048c <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 48c:	7119                	addi	sp,sp,-128
 48e:	fc86                	sd	ra,120(sp)
 490:	f8a2                	sd	s0,112(sp)
 492:	f4a6                	sd	s1,104(sp)
 494:	f0ca                	sd	s2,96(sp)
 496:	ecce                	sd	s3,88(sp)
 498:	e8d2                	sd	s4,80(sp)
 49a:	e4d6                	sd	s5,72(sp)
 49c:	e0da                	sd	s6,64(sp)
 49e:	fc5e                	sd	s7,56(sp)
 4a0:	f862                	sd	s8,48(sp)
 4a2:	f466                	sd	s9,40(sp)
 4a4:	f06a                	sd	s10,32(sp)
 4a6:	ec6e                	sd	s11,24(sp)
 4a8:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4aa:	0005c903          	lbu	s2,0(a1)
 4ae:	18090f63          	beqz	s2,64c <vprintf+0x1c0>
 4b2:	8aaa                	mv	s5,a0
 4b4:	8b32                	mv	s6,a2
 4b6:	00158493          	addi	s1,a1,1
  state = 0;
 4ba:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4bc:	02500a13          	li	s4,37
 4c0:	4c55                	li	s8,21
 4c2:	00000c97          	auipc	s9,0x0
 4c6:	3aec8c93          	addi	s9,s9,942 # 870 <malloc+0x120>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4ca:	02800d93          	li	s11,40
  putc(fd, 'x');
 4ce:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4d0:	00000b97          	auipc	s7,0x0
 4d4:	3f8b8b93          	addi	s7,s7,1016 # 8c8 <digits>
 4d8:	a839                	j	4f6 <vprintf+0x6a>
        putc(fd, c);
 4da:	85ca                	mv	a1,s2
 4dc:	8556                	mv	a0,s5
 4de:	00000097          	auipc	ra,0x0
 4e2:	ee0080e7          	jalr	-288(ra) # 3be <putc>
 4e6:	a019                	j	4ec <vprintf+0x60>
    } else if(state == '%'){
 4e8:	01498d63          	beq	s3,s4,502 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4ec:	0485                	addi	s1,s1,1
 4ee:	fff4c903          	lbu	s2,-1(s1)
 4f2:	14090d63          	beqz	s2,64c <vprintf+0x1c0>
    if(state == 0){
 4f6:	fe0999e3          	bnez	s3,4e8 <vprintf+0x5c>
      if(c == '%'){
 4fa:	ff4910e3          	bne	s2,s4,4da <vprintf+0x4e>
        state = '%';
 4fe:	89d2                	mv	s3,s4
 500:	b7f5                	j	4ec <vprintf+0x60>
      if(c == 'd'){
 502:	11490c63          	beq	s2,s4,61a <vprintf+0x18e>
 506:	f9d9079b          	addiw	a5,s2,-99
 50a:	0ff7f793          	zext.b	a5,a5
 50e:	10fc6e63          	bltu	s8,a5,62a <vprintf+0x19e>
 512:	f9d9079b          	addiw	a5,s2,-99
 516:	0ff7f713          	zext.b	a4,a5
 51a:	10ec6863          	bltu	s8,a4,62a <vprintf+0x19e>
 51e:	00271793          	slli	a5,a4,0x2
 522:	97e6                	add	a5,a5,s9
 524:	439c                	lw	a5,0(a5)
 526:	97e6                	add	a5,a5,s9
 528:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 52a:	008b0913          	addi	s2,s6,8
 52e:	4685                	li	a3,1
 530:	4629                	li	a2,10
 532:	000b2583          	lw	a1,0(s6)
 536:	8556                	mv	a0,s5
 538:	00000097          	auipc	ra,0x0
 53c:	ea8080e7          	jalr	-344(ra) # 3e0 <printint>
 540:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 542:	4981                	li	s3,0
 544:	b765                	j	4ec <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 546:	008b0913          	addi	s2,s6,8
 54a:	4681                	li	a3,0
 54c:	4629                	li	a2,10
 54e:	000b2583          	lw	a1,0(s6)
 552:	8556                	mv	a0,s5
 554:	00000097          	auipc	ra,0x0
 558:	e8c080e7          	jalr	-372(ra) # 3e0 <printint>
 55c:	8b4a                	mv	s6,s2
      state = 0;
 55e:	4981                	li	s3,0
 560:	b771                	j	4ec <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 562:	008b0913          	addi	s2,s6,8
 566:	4681                	li	a3,0
 568:	866a                	mv	a2,s10
 56a:	000b2583          	lw	a1,0(s6)
 56e:	8556                	mv	a0,s5
 570:	00000097          	auipc	ra,0x0
 574:	e70080e7          	jalr	-400(ra) # 3e0 <printint>
 578:	8b4a                	mv	s6,s2
      state = 0;
 57a:	4981                	li	s3,0
 57c:	bf85                	j	4ec <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 57e:	008b0793          	addi	a5,s6,8
 582:	f8f43423          	sd	a5,-120(s0)
 586:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 58a:	03000593          	li	a1,48
 58e:	8556                	mv	a0,s5
 590:	00000097          	auipc	ra,0x0
 594:	e2e080e7          	jalr	-466(ra) # 3be <putc>
  putc(fd, 'x');
 598:	07800593          	li	a1,120
 59c:	8556                	mv	a0,s5
 59e:	00000097          	auipc	ra,0x0
 5a2:	e20080e7          	jalr	-480(ra) # 3be <putc>
 5a6:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5a8:	03c9d793          	srli	a5,s3,0x3c
 5ac:	97de                	add	a5,a5,s7
 5ae:	0007c583          	lbu	a1,0(a5)
 5b2:	8556                	mv	a0,s5
 5b4:	00000097          	auipc	ra,0x0
 5b8:	e0a080e7          	jalr	-502(ra) # 3be <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5bc:	0992                	slli	s3,s3,0x4
 5be:	397d                	addiw	s2,s2,-1
 5c0:	fe0914e3          	bnez	s2,5a8 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5c4:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5c8:	4981                	li	s3,0
 5ca:	b70d                	j	4ec <vprintf+0x60>
        s = va_arg(ap, char*);
 5cc:	008b0913          	addi	s2,s6,8
 5d0:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5d4:	02098163          	beqz	s3,5f6 <vprintf+0x16a>
        while(*s != 0){
 5d8:	0009c583          	lbu	a1,0(s3)
 5dc:	c5ad                	beqz	a1,646 <vprintf+0x1ba>
          putc(fd, *s);
 5de:	8556                	mv	a0,s5
 5e0:	00000097          	auipc	ra,0x0
 5e4:	dde080e7          	jalr	-546(ra) # 3be <putc>
          s++;
 5e8:	0985                	addi	s3,s3,1
        while(*s != 0){
 5ea:	0009c583          	lbu	a1,0(s3)
 5ee:	f9e5                	bnez	a1,5de <vprintf+0x152>
        s = va_arg(ap, char*);
 5f0:	8b4a                	mv	s6,s2
      state = 0;
 5f2:	4981                	li	s3,0
 5f4:	bde5                	j	4ec <vprintf+0x60>
          s = "(null)";
 5f6:	00000997          	auipc	s3,0x0
 5fa:	27298993          	addi	s3,s3,626 # 868 <malloc+0x118>
        while(*s != 0){
 5fe:	85ee                	mv	a1,s11
 600:	bff9                	j	5de <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 602:	008b0913          	addi	s2,s6,8
 606:	000b4583          	lbu	a1,0(s6)
 60a:	8556                	mv	a0,s5
 60c:	00000097          	auipc	ra,0x0
 610:	db2080e7          	jalr	-590(ra) # 3be <putc>
 614:	8b4a                	mv	s6,s2
      state = 0;
 616:	4981                	li	s3,0
 618:	bdd1                	j	4ec <vprintf+0x60>
        putc(fd, c);
 61a:	85d2                	mv	a1,s4
 61c:	8556                	mv	a0,s5
 61e:	00000097          	auipc	ra,0x0
 622:	da0080e7          	jalr	-608(ra) # 3be <putc>
      state = 0;
 626:	4981                	li	s3,0
 628:	b5d1                	j	4ec <vprintf+0x60>
        putc(fd, '%');
 62a:	85d2                	mv	a1,s4
 62c:	8556                	mv	a0,s5
 62e:	00000097          	auipc	ra,0x0
 632:	d90080e7          	jalr	-624(ra) # 3be <putc>
        putc(fd, c);
 636:	85ca                	mv	a1,s2
 638:	8556                	mv	a0,s5
 63a:	00000097          	auipc	ra,0x0
 63e:	d84080e7          	jalr	-636(ra) # 3be <putc>
      state = 0;
 642:	4981                	li	s3,0
 644:	b565                	j	4ec <vprintf+0x60>
        s = va_arg(ap, char*);
 646:	8b4a                	mv	s6,s2
      state = 0;
 648:	4981                	li	s3,0
 64a:	b54d                	j	4ec <vprintf+0x60>
    }
  }
}
 64c:	70e6                	ld	ra,120(sp)
 64e:	7446                	ld	s0,112(sp)
 650:	74a6                	ld	s1,104(sp)
 652:	7906                	ld	s2,96(sp)
 654:	69e6                	ld	s3,88(sp)
 656:	6a46                	ld	s4,80(sp)
 658:	6aa6                	ld	s5,72(sp)
 65a:	6b06                	ld	s6,64(sp)
 65c:	7be2                	ld	s7,56(sp)
 65e:	7c42                	ld	s8,48(sp)
 660:	7ca2                	ld	s9,40(sp)
 662:	7d02                	ld	s10,32(sp)
 664:	6de2                	ld	s11,24(sp)
 666:	6109                	addi	sp,sp,128
 668:	8082                	ret

000000000000066a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 66a:	715d                	addi	sp,sp,-80
 66c:	ec06                	sd	ra,24(sp)
 66e:	e822                	sd	s0,16(sp)
 670:	1000                	addi	s0,sp,32
 672:	e010                	sd	a2,0(s0)
 674:	e414                	sd	a3,8(s0)
 676:	e818                	sd	a4,16(s0)
 678:	ec1c                	sd	a5,24(s0)
 67a:	03043023          	sd	a6,32(s0)
 67e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 682:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 686:	8622                	mv	a2,s0
 688:	00000097          	auipc	ra,0x0
 68c:	e04080e7          	jalr	-508(ra) # 48c <vprintf>
}
 690:	60e2                	ld	ra,24(sp)
 692:	6442                	ld	s0,16(sp)
 694:	6161                	addi	sp,sp,80
 696:	8082                	ret

0000000000000698 <printf>:

void
printf(const char *fmt, ...)
{
 698:	711d                	addi	sp,sp,-96
 69a:	ec06                	sd	ra,24(sp)
 69c:	e822                	sd	s0,16(sp)
 69e:	1000                	addi	s0,sp,32
 6a0:	e40c                	sd	a1,8(s0)
 6a2:	e810                	sd	a2,16(s0)
 6a4:	ec14                	sd	a3,24(s0)
 6a6:	f018                	sd	a4,32(s0)
 6a8:	f41c                	sd	a5,40(s0)
 6aa:	03043823          	sd	a6,48(s0)
 6ae:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6b2:	00840613          	addi	a2,s0,8
 6b6:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ba:	85aa                	mv	a1,a0
 6bc:	4505                	li	a0,1
 6be:	00000097          	auipc	ra,0x0
 6c2:	dce080e7          	jalr	-562(ra) # 48c <vprintf>
}
 6c6:	60e2                	ld	ra,24(sp)
 6c8:	6442                	ld	s0,16(sp)
 6ca:	6125                	addi	sp,sp,96
 6cc:	8082                	ret

00000000000006ce <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6ce:	1141                	addi	sp,sp,-16
 6d0:	e422                	sd	s0,8(sp)
 6d2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6d4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6d8:	00001797          	auipc	a5,0x1
 6dc:	9287b783          	ld	a5,-1752(a5) # 1000 <freep>
 6e0:	a02d                	j	70a <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6e2:	4618                	lw	a4,8(a2)
 6e4:	9f2d                	addw	a4,a4,a1
 6e6:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6ea:	6398                	ld	a4,0(a5)
 6ec:	6310                	ld	a2,0(a4)
 6ee:	a83d                	j	72c <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6f0:	ff852703          	lw	a4,-8(a0)
 6f4:	9f31                	addw	a4,a4,a2
 6f6:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6f8:	ff053683          	ld	a3,-16(a0)
 6fc:	a091                	j	740 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6fe:	6398                	ld	a4,0(a5)
 700:	00e7e463          	bltu	a5,a4,708 <free+0x3a>
 704:	00e6ea63          	bltu	a3,a4,718 <free+0x4a>
{
 708:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 70a:	fed7fae3          	bgeu	a5,a3,6fe <free+0x30>
 70e:	6398                	ld	a4,0(a5)
 710:	00e6e463          	bltu	a3,a4,718 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 714:	fee7eae3          	bltu	a5,a4,708 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 718:	ff852583          	lw	a1,-8(a0)
 71c:	6390                	ld	a2,0(a5)
 71e:	02059813          	slli	a6,a1,0x20
 722:	01c85713          	srli	a4,a6,0x1c
 726:	9736                	add	a4,a4,a3
 728:	fae60de3          	beq	a2,a4,6e2 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 72c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 730:	4790                	lw	a2,8(a5)
 732:	02061593          	slli	a1,a2,0x20
 736:	01c5d713          	srli	a4,a1,0x1c
 73a:	973e                	add	a4,a4,a5
 73c:	fae68ae3          	beq	a3,a4,6f0 <free+0x22>
    p->s.ptr = bp->s.ptr;
 740:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 742:	00001717          	auipc	a4,0x1
 746:	8af73f23          	sd	a5,-1858(a4) # 1000 <freep>
}
 74a:	6422                	ld	s0,8(sp)
 74c:	0141                	addi	sp,sp,16
 74e:	8082                	ret

0000000000000750 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 750:	7139                	addi	sp,sp,-64
 752:	fc06                	sd	ra,56(sp)
 754:	f822                	sd	s0,48(sp)
 756:	f426                	sd	s1,40(sp)
 758:	f04a                	sd	s2,32(sp)
 75a:	ec4e                	sd	s3,24(sp)
 75c:	e852                	sd	s4,16(sp)
 75e:	e456                	sd	s5,8(sp)
 760:	e05a                	sd	s6,0(sp)
 762:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 764:	02051493          	slli	s1,a0,0x20
 768:	9081                	srli	s1,s1,0x20
 76a:	04bd                	addi	s1,s1,15
 76c:	8091                	srli	s1,s1,0x4
 76e:	0014899b          	addiw	s3,s1,1
 772:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 774:	00001517          	auipc	a0,0x1
 778:	88c53503          	ld	a0,-1908(a0) # 1000 <freep>
 77c:	c515                	beqz	a0,7a8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 77e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 780:	4798                	lw	a4,8(a5)
 782:	02977f63          	bgeu	a4,s1,7c0 <malloc+0x70>
 786:	8a4e                	mv	s4,s3
 788:	0009871b          	sext.w	a4,s3
 78c:	6685                	lui	a3,0x1
 78e:	00d77363          	bgeu	a4,a3,794 <malloc+0x44>
 792:	6a05                	lui	s4,0x1
 794:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 798:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 79c:	00001917          	auipc	s2,0x1
 7a0:	86490913          	addi	s2,s2,-1948 # 1000 <freep>
  if(p == (char*)-1)
 7a4:	5afd                	li	s5,-1
 7a6:	a895                	j	81a <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7a8:	00001797          	auipc	a5,0x1
 7ac:	86878793          	addi	a5,a5,-1944 # 1010 <base>
 7b0:	00001717          	auipc	a4,0x1
 7b4:	84f73823          	sd	a5,-1968(a4) # 1000 <freep>
 7b8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7ba:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7be:	b7e1                	j	786 <malloc+0x36>
      if(p->s.size == nunits)
 7c0:	02e48c63          	beq	s1,a4,7f8 <malloc+0xa8>
        p->s.size -= nunits;
 7c4:	4137073b          	subw	a4,a4,s3
 7c8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7ca:	02071693          	slli	a3,a4,0x20
 7ce:	01c6d713          	srli	a4,a3,0x1c
 7d2:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7d4:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7d8:	00001717          	auipc	a4,0x1
 7dc:	82a73423          	sd	a0,-2008(a4) # 1000 <freep>
      return (void*)(p + 1);
 7e0:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7e4:	70e2                	ld	ra,56(sp)
 7e6:	7442                	ld	s0,48(sp)
 7e8:	74a2                	ld	s1,40(sp)
 7ea:	7902                	ld	s2,32(sp)
 7ec:	69e2                	ld	s3,24(sp)
 7ee:	6a42                	ld	s4,16(sp)
 7f0:	6aa2                	ld	s5,8(sp)
 7f2:	6b02                	ld	s6,0(sp)
 7f4:	6121                	addi	sp,sp,64
 7f6:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7f8:	6398                	ld	a4,0(a5)
 7fa:	e118                	sd	a4,0(a0)
 7fc:	bff1                	j	7d8 <malloc+0x88>
  hp->s.size = nu;
 7fe:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 802:	0541                	addi	a0,a0,16
 804:	00000097          	auipc	ra,0x0
 808:	eca080e7          	jalr	-310(ra) # 6ce <free>
  return freep;
 80c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 810:	d971                	beqz	a0,7e4 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 812:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 814:	4798                	lw	a4,8(a5)
 816:	fa9775e3          	bgeu	a4,s1,7c0 <malloc+0x70>
    if(p == freep)
 81a:	00093703          	ld	a4,0(s2)
 81e:	853e                	mv	a0,a5
 820:	fef719e3          	bne	a4,a5,812 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 824:	8552                	mv	a0,s4
 826:	00000097          	auipc	ra,0x0
 82a:	b78080e7          	jalr	-1160(ra) # 39e <sbrk>
  if(p == (char*)-1)
 82e:	fd5518e3          	bne	a0,s5,7fe <malloc+0xae>
        return 0;
 832:	4501                	li	a0,0
 834:	bf45                	j	7e4 <malloc+0x94>
