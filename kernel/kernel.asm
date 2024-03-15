
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8e013103          	ld	sp,-1824(sp) # 800088e0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8f070713          	addi	a4,a4,-1808 # 80008940 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	d0e78793          	addi	a5,a5,-754 # 80005d70 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca4f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	388080e7          	jalr	904(ra) # 800024b2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8f650513          	addi	a0,a0,-1802 # 80010a80 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8e648493          	addi	s1,s1,-1818 # 80010a80 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	97690913          	addi	s2,s2,-1674 # 80010b18 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	134080e7          	jalr	308(ra) # 800022fc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	24a080e7          	jalr	586(ra) # 8000245c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	85a50513          	addi	a0,a0,-1958 # 80010a80 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	84450513          	addi	a0,a0,-1980 # 80010a80 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8af72323          	sw	a5,-1882(a4) # 80010b18 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7b450513          	addi	a0,a0,1972 # 80010a80 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	216080e7          	jalr	534(ra) # 80002508 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	78650513          	addi	a0,a0,1926 # 80010a80 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	76270713          	addi	a4,a4,1890 # 80010a80 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	73878793          	addi	a5,a5,1848 # 80010a80 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7a27a783          	lw	a5,1954(a5) # 80010b18 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6f670713          	addi	a4,a4,1782 # 80010a80 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6e648493          	addi	s1,s1,1766 # 80010a80 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6aa70713          	addi	a4,a4,1706 # 80010a80 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	72f72a23          	sw	a5,1844(a4) # 80010b20 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	66e78793          	addi	a5,a5,1646 # 80010a80 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ec7a323          	sw	a2,1766(a5) # 80010b1c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6da50513          	addi	a0,a0,1754 # 80010b18 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c72080e7          	jalr	-910(ra) # 800020b8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	62050513          	addi	a0,a0,1568 # 80010a80 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	7a078793          	addi	a5,a5,1952 # 80020c18 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5e07aa23          	sw	zero,1524(a5) # 80010b40 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	38f72023          	sw	a5,896(a4) # 80008900 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	584dad83          	lw	s11,1412(s11) # 80010b40 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	52e50513          	addi	a0,a0,1326 # 80010b28 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3d050513          	addi	a0,a0,976 # 80010b28 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	3b448493          	addi	s1,s1,948 # 80010b28 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	37450513          	addi	a0,a0,884 # 80010b48 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1007a783          	lw	a5,256(a5) # 80008900 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0d07b783          	ld	a5,208(a5) # 80008908 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0d073703          	ld	a4,208(a4) # 80008910 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2e6a0a13          	addi	s4,s4,742 # 80010b48 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	09e48493          	addi	s1,s1,158 # 80008908 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	09e98993          	addi	s3,s3,158 # 80008910 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	824080e7          	jalr	-2012(ra) # 800020b8 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	27850513          	addi	a0,a0,632 # 80010b48 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0207a783          	lw	a5,32(a5) # 80008900 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	02673703          	ld	a4,38(a4) # 80008910 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0167b783          	ld	a5,22(a5) # 80008908 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	24a98993          	addi	s3,s3,586 # 80010b48 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	00248493          	addi	s1,s1,2 # 80008908 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	00290913          	addi	s2,s2,2 # 80008910 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	736080e7          	jalr	1846(ra) # 80002054 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	21448493          	addi	s1,s1,532 # 80010b48 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fce7b423          	sd	a4,-56(a5) # 80008910 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	18e48493          	addi	s1,s1,398 # 80010b48 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	3b478793          	addi	a5,a5,948 # 80021db0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	16490913          	addi	s2,s2,356 # 80010b80 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0c650513          	addi	a0,a0,198 # 80010b80 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	2e250513          	addi	a0,a0,738 # 80021db0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	09048493          	addi	s1,s1,144 # 80010b80 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	07850513          	addi	a0,a0,120 # 80010b80 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	04c50513          	addi	a0,a0,76 # 80010b80 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd251>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a9070713          	addi	a4,a4,-1392 # 80008918 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	954080e7          	jalr	-1708(ra) # 80002812 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	eea080e7          	jalr	-278(ra) # 80005db0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fd4080e7          	jalr	-44(ra) # 80001ea2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	8b4080e7          	jalr	-1868(ra) # 800027ea <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	8d4080e7          	jalr	-1836(ra) # 80002812 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	e54080e7          	jalr	-428(ra) # 80005d9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	e62080e7          	jalr	-414(ra) # 80005db0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	ff8080e7          	jalr	-8(ra) # 80002f4e <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	698080e7          	jalr	1688(ra) # 800035f6 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	63e080e7          	jalr	1598(ra) # 800045a4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	f4a080e7          	jalr	-182(ra) # 80005eb8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	98f72a23          	sw	a5,-1644(a4) # 80008918 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9887b783          	ld	a5,-1656(a5) # 80008920 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd247>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6ca7b623          	sd	a0,1740(a5) # 80008920 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd250>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	78448493          	addi	s1,s1,1924 # 80010fd0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	16aa0a13          	addi	s4,s4,362 # 800169d0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	16848493          	addi	s1,s1,360
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	2b850513          	addi	a0,a0,696 # 80010ba0 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	2b850513          	addi	a0,a0,696 # 80010bb8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6c048493          	addi	s1,s1,1728 # 80010fd0 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	09e98993          	addi	s3,s3,158 # 800169d0 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	16848493          	addi	s1,s1,360
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	23450513          	addi	a0,a0,564 # 80010bd0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1dc70713          	addi	a4,a4,476 # 80010ba0 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e947a783          	lw	a5,-364(a5) # 80008890 <first.2>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	e24080e7          	jalr	-476(ra) # 8000282a <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e607ad23          	sw	zero,-390(a5) # 80008890 <first.2>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	b56080e7          	jalr	-1194(ra) # 80003576 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	16a90913          	addi	s2,s2,362 # 80010ba0 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e4c78793          	addi	a5,a5,-436 # 80008894 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	40e48493          	addi	s1,s1,1038 # 80010fd0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	e0690913          	addi	s2,s2,-506 # 800169d0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	16848493          	addi	s1,s1,360
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	c8a7b823          	sd	a0,-880(a5) # 80008928 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	bfc58593          	addi	a1,a1,-1028 # 800088a0 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	2be080e7          	jalr	702(ra) # 80003fa0 <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  } else if(n < 0){
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	050ab503          	ld	a0,80(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7d2080e7          	jalr	2002(ra) # 80001568 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	058ab683          	ld	a3,88(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	058a3703          	ld	a4,88(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	058a3783          	ld	a5,88(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de0:	0d0a8493          	addi	s1,s5,208
    80001de4:	0d0a0913          	addi	s2,s4,208
    80001de8:	150a8993          	addi	s3,s5,336
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if(p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00003097          	auipc	ra,0x3
    80001e16:	824080e7          	jalr	-2012(ra) # 80004636 <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	992080e7          	jalr	-1646(ra) # 800037b6 <idup>
    80001e2c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	158a8593          	addi	a1,s5,344
    80001e36:	158a0513          	addi	a0,s4,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	d6848493          	addi	s1,s1,-664 # 80010bb8 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	ce270713          	addi	a4,a4,-798 # 80010ba0 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	d0c70713          	addi	a4,a4,-756 # 80010bd8 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	cc4a0a13          	addi	s4,s4,-828 # 80010ba0 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	aea90913          	addi	s2,s2,-1302 # 800169d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	0d648493          	addi	s1,s1,214 # 80010fd0 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0e:	16848493          	addi	s1,s1,360
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00001097          	auipc	ra,0x1
    80001f38:	84c080e7          	jalr	-1972(ra) # 80002780 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80001f58:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c02080e7          	jalr	-1022(ra) # 80000b5c <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	c3670713          	addi	a4,a4,-970 # 80010ba0 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	c1090913          	addi	s2,s2,-1008 # 80010ba0 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	c3058593          	addi	a1,a1,-976 # 80010bd8 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	7ca080e7          	jalr	1994(ra) # 80002780 <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	993e                	add	s2,s2,a5
    80001fc6:	0b392623          	sw	s3,172(s2)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	24050513          	addi	a0,a0,576 # 80008218 <digits+0x1d8>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	560080e7          	jalr	1376(ra) # 80000540 <panic>
    panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	24050513          	addi	a0,a0,576 # 80008228 <digits+0x1e8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>
    panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	24050513          	addi	a0,a0,576 # 80008238 <digits+0x1f8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	540080e7          	jalr	1344(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	24050513          	addi	a0,a0,576 # 80008248 <digits+0x208>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	530080e7          	jalr	1328(ra) # 80000540 <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	f0448493          	addi	s1,s1,-252 # 80010fd0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020d4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	8f890913          	addi	s2,s2,-1800 # 800169d0 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ec:	16848493          	addi	s1,s1,360
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if(p != myproc()){
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <reparent>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	e052                	sd	s4,0(sp)
    8000213c:	1800                	addi	s0,sp,48
    8000213e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002140:	0000f497          	auipc	s1,0xf
    80002144:	e9048493          	addi	s1,s1,-368 # 80010fd0 <proc>
      pp->parent = initproc;
    80002148:	00006a17          	auipc	s4,0x6
    8000214c:	7e0a0a13          	addi	s4,s4,2016 # 80008928 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002150:	00015997          	auipc	s3,0x15
    80002154:	88098993          	addi	s3,s3,-1920 # 800169d0 <tickslock>
    80002158:	a029                	j	80002162 <reparent+0x34>
    8000215a:	16848493          	addi	s1,s1,360
    8000215e:	01348d63          	beq	s1,s3,80002178 <reparent+0x4a>
    if(pp->parent == p){
    80002162:	7c9c                	ld	a5,56(s1)
    80002164:	ff279be3          	bne	a5,s2,8000215a <reparent+0x2c>
      pp->parent = initproc;
    80002168:	000a3503          	ld	a0,0(s4)
    8000216c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	f4a080e7          	jalr	-182(ra) # 800020b8 <wakeup>
    80002176:	b7d5                	j	8000215a <reparent+0x2c>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	812080e7          	jalr	-2030(ra) # 800019ac <myproc>
    800021a2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021a4:	00006797          	auipc	a5,0x6
    800021a8:	7847b783          	ld	a5,1924(a5) # 80008928 <initproc>
    800021ac:	0d050493          	addi	s1,a0,208
    800021b0:	15050913          	addi	s2,a0,336
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	0a850513          	addi	a0,a0,168 # 80008260 <digits+0x220>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	380080e7          	jalr	896(ra) # 80000540 <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	4c0080e7          	jalr	1216(ra) # 80004688 <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if(p->ofile[fd]){
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	fe0080e7          	jalr	-32(ra) # 800041c0 <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	7c2080e7          	jalr	1986(ra) # 800039ae <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	04a080e7          	jalr	74(ra) # 8000423e <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	9b848493          	addi	s1,s1,-1608 # 80010bb8 <wait_lock>
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9cc080e7          	jalr	-1588(ra) # 80000bd6 <acquire>
  reparent(p);
    80002212:	854e                	mv	a0,s3
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f1a080e7          	jalr	-230(ra) # 8000212e <reparent>
  wakeup(p->parent);
    8000221c:	0389b503          	ld	a0,56(s3)
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e98080e7          	jalr	-360(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    80002228:	854e                	mv	a0,s3
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002232:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002236:	4795                	li	a5,5
    80002238:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
  sched();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	cfc080e7          	jalr	-772(ra) # 80001f42 <sched>
  panic("zombie exit");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	02250513          	addi	a0,a0,34 # 80008270 <digits+0x230>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2ea080e7          	jalr	746(ra) # 80000540 <panic>

000000008000225e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	d6248493          	addi	s1,s1,-670 # 80010fd0 <proc>
    80002276:	00014997          	auipc	s3,0x14
    8000227a:	75a98993          	addi	s3,s3,1882 # 800169d0 <tickslock>
    acquire(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002288:	589c                	lw	a5,48(s1)
    8000228a:	01278d63          	beq	a5,s2,800022a4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002298:	16848493          	addi	s1,s1,360
    8000229c:	ff3491e3          	bne	s1,s3,8000227e <kill+0x20>
  }
  return -1;
    800022a0:	557d                	li	a0,-1
    800022a2:	a829                	j	800022bc <kill+0x5e>
      p->killed = 1;
    800022a4:	4785                	li	a5,1
    800022a6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a8:	4c98                	lw	a4,24(s1)
    800022aa:	4789                	li	a5,2
    800022ac:	00f70f63          	beq	a4,a5,800022ca <kill+0x6c>
      release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
      return 0;
    800022ba:	4501                	li	a0,0
}
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6145                	addi	sp,sp,48
    800022c8:	8082                	ret
        p->state = RUNNABLE;
    800022ca:	478d                	li	a5,3
    800022cc:	cc9c                	sw	a5,24(s1)
    800022ce:	b7cd                	j	800022b0 <kill+0x52>

00000000800022d0 <setkilled>:

void
setkilled(struct proc *p)
{
    800022d0:	1101                	addi	sp,sp,-32
    800022d2:	ec06                	sd	ra,24(sp)
    800022d4:	e822                	sd	s0,16(sp)
    800022d6:	e426                	sd	s1,8(sp)
    800022d8:	1000                	addi	s0,sp,32
    800022da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022e4:	4785                	li	a5,1
    800022e6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9a0080e7          	jalr	-1632(ra) # 80000c8a <release>
}
    800022f2:	60e2                	ld	ra,24(sp)
    800022f4:	6442                	ld	s0,16(sp)
    800022f6:	64a2                	ld	s1,8(sp)
    800022f8:	6105                	addi	sp,sp,32
    800022fa:	8082                	ret

00000000800022fc <killed>:

int
killed(struct proc *p)
{
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	e04a                	sd	s2,0(sp)
    80002306:	1000                	addi	s0,sp,32
    80002308:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002312:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	972080e7          	jalr	-1678(ra) # 80000c8a <release>
  return k;
}
    80002320:	854a                	mv	a0,s2
    80002322:	60e2                	ld	ra,24(sp)
    80002324:	6442                	ld	s0,16(sp)
    80002326:	64a2                	ld	s1,8(sp)
    80002328:	6902                	ld	s2,0(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	664080e7          	jalr	1636(ra) # 800019ac <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	86650513          	addi	a0,a0,-1946 # 80010bb8 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002362:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002364:	4a15                	li	s4,5
        havekids = 1;
    80002366:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002368:	00014997          	auipc	s3,0x14
    8000236c:	66898993          	addi	s3,s3,1640 # 800169d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002370:	0000fc17          	auipc	s8,0xf
    80002374:	848c0c13          	addi	s8,s8,-1976 # 80010bb8 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237a:	0000f497          	auipc	s1,0xf
    8000237e:	c5648493          	addi	s1,s1,-938 # 80010fd0 <proc>
    80002382:	a0bd                	j	800023f0 <wait+0xc2>
          pid = pp->pid;
    80002384:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002388:	000b0e63          	beqz	s6,800023a4 <wait+0x76>
    8000238c:	4691                	li	a3,4
    8000238e:	02c48613          	addi	a2,s1,44
    80002392:	85da                	mv	a1,s6
    80002394:	05093503          	ld	a0,80(s2)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	2d4080e7          	jalr	724(ra) # 8000166c <copyout>
    800023a0:	02054563          	bltz	a0,800023ca <wait+0x9c>
          freeproc(pp);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	7b8080e7          	jalr	1976(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>
          release(&wait_lock);
    800023b8:	0000f517          	auipc	a0,0xf
    800023bc:	80050513          	addi	a0,a0,-2048 # 80010bb8 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
          return pid;
    800023c8:	a0b5                	j	80002434 <wait+0x106>
            release(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
            release(&wait_lock);
    800023d4:	0000e517          	auipc	a0,0xe
    800023d8:	7e450513          	addi	a0,a0,2020 # 80010bb8 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a0b9                	j	80002434 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e8:	16848493          	addi	s1,s1,360
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xe6>
      if(pp->parent == p){
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xba>
        acquire(&pp->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94781e3          	beq	a5,s4,80002384 <wait+0x56>
        release(&pp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xba>
    if(!havekids || killed(p)){
    80002414:	c719                	beqz	a4,80002422 <wait+0xf4>
    80002416:	854a                	mv	a0,s2
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	ee4080e7          	jalr	-284(ra) # 800022fc <killed>
    80002420:	c51d                	beqz	a0,8000244e <wait+0x120>
      release(&wait_lock);
    80002422:	0000e517          	auipc	a0,0xe
    80002426:	79650513          	addi	a0,a0,1942 # 80010bb8 <wait_lock>
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
      return -1;
    80002432:	59fd                	li	s3,-1
}
    80002434:	854e                	mv	a0,s3
    80002436:	60a6                	ld	ra,72(sp)
    80002438:	6406                	ld	s0,64(sp)
    8000243a:	74e2                	ld	s1,56(sp)
    8000243c:	7942                	ld	s2,48(sp)
    8000243e:	79a2                	ld	s3,40(sp)
    80002440:	7a02                	ld	s4,32(sp)
    80002442:	6ae2                	ld	s5,24(sp)
    80002444:	6b42                	ld	s6,16(sp)
    80002446:	6ba2                	ld	s7,8(sp)
    80002448:	6c02                	ld	s8,0(sp)
    8000244a:	6161                	addi	sp,sp,80
    8000244c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000244e:	85e2                	mv	a1,s8
    80002450:	854a                	mv	a0,s2
    80002452:	00000097          	auipc	ra,0x0
    80002456:	c02080e7          	jalr	-1022(ra) # 80002054 <sleep>
    havekids = 0;
    8000245a:	bf39                	j	80002378 <wait+0x4a>

000000008000245c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	e052                	sd	s4,0(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	84aa                	mv	s1,a0
    8000246e:	892e                	mv	s2,a1
    80002470:	89b2                	mv	s3,a2
    80002472:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	538080e7          	jalr	1336(ra) # 800019ac <myproc>
  if(user_dst){
    8000247c:	c08d                	beqz	s1,8000249e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247e:	86d2                	mv	a3,s4
    80002480:	864e                	mv	a2,s3
    80002482:	85ca                	mv	a1,s2
    80002484:	6928                	ld	a0,80(a0)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	1e6080e7          	jalr	486(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6a02                	ld	s4,0(sp)
    8000249a:	6145                	addi	sp,sp,48
    8000249c:	8082                	ret
    memmove((char *)dst, src, len);
    8000249e:	000a061b          	sext.w	a2,s4
    800024a2:	85ce                	mv	a1,s3
    800024a4:	854a                	mv	a0,s2
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	888080e7          	jalr	-1912(ra) # 80000d2e <memmove>
    return 0;
    800024ae:	8526                	mv	a0,s1
    800024b0:	bff9                	j	8000248e <either_copyout+0x32>

00000000800024b2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	892a                	mv	s2,a0
    800024c4:	84ae                	mv	s1,a1
    800024c6:	89b2                	mv	s3,a2
    800024c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	4e2080e7          	jalr	1250(ra) # 800019ac <myproc>
  if(user_src){
    800024d2:	c08d                	beqz	s1,800024f4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d4:	86d2                	mv	a3,s4
    800024d6:	864e                	mv	a2,s3
    800024d8:	85ca                	mv	a1,s2
    800024da:	6928                	ld	a0,80(a0)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	21c080e7          	jalr	540(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f4:	000a061b          	sext.w	a2,s4
    800024f8:	85ce                	mv	a1,s3
    800024fa:	854a                	mv	a0,s2
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	832080e7          	jalr	-1998(ra) # 80000d2e <memmove>
    return 0;
    80002504:	8526                	mv	a0,s1
    80002506:	bff9                	j	800024e4 <either_copyin+0x32>

0000000080002508 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002508:	715d                	addi	sp,sp,-80
    8000250a:	e486                	sd	ra,72(sp)
    8000250c:	e0a2                	sd	s0,64(sp)
    8000250e:	fc26                	sd	s1,56(sp)
    80002510:	f84a                	sd	s2,48(sp)
    80002512:	f44e                	sd	s3,40(sp)
    80002514:	f052                	sd	s4,32(sp)
    80002516:	ec56                	sd	s5,24(sp)
    80002518:	e85a                	sd	s6,16(sp)
    8000251a:	e45e                	sd	s7,8(sp)
    8000251c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	baa50513          	addi	a0,a0,-1110 # 800080c8 <digits+0x88>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	064080e7          	jalr	100(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	bfa48493          	addi	s1,s1,-1030 # 80011128 <proc+0x158>
    80002536:	00014917          	auipc	s2,0x14
    8000253a:	5f290913          	addi	s2,s2,1522 # 80016b28 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002540:	00006997          	auipc	s3,0x6
    80002544:	d4098993          	addi	s3,s3,-704 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002548:	00006a97          	auipc	s5,0x6
    8000254c:	d40a8a93          	addi	s5,s5,-704 # 80008288 <digits+0x248>
    printf("\n");
    80002550:	00006a17          	auipc	s4,0x6
    80002554:	b78a0a13          	addi	s4,s4,-1160 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	00006b97          	auipc	s7,0x6
    8000255c:	d80b8b93          	addi	s7,s7,-640 # 800082d8 <states.1>
    80002560:	a00d                	j	80002582 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	ed86a583          	lw	a1,-296(a3)
    80002566:	8556                	mv	a0,s5
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	022080e7          	jalr	34(ra) # 8000058a <printf>
    printf("\n");
    80002570:	8552                	mv	a0,s4
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	018080e7          	jalr	24(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257a:	16848493          	addi	s1,s1,360
    8000257e:	03248263          	beq	s1,s2,800025a2 <procdump+0x9a>
    if(p->state == UNUSED)
    80002582:	86a6                	mv	a3,s1
    80002584:	ec04a783          	lw	a5,-320(s1)
    80002588:	dbed                	beqz	a5,8000257a <procdump+0x72>
      state = "???";
    8000258a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	fcfb6be3          	bltu	s6,a5,80002562 <procdump+0x5a>
    80002590:	02079713          	slli	a4,a5,0x20
    80002594:	01d75793          	srli	a5,a4,0x1d
    80002598:	97de                	add	a5,a5,s7
    8000259a:	6390                	ld	a2,0(a5)
    8000259c:	f279                	bnez	a2,80002562 <procdump+0x5a>
      state = "???";
    8000259e:	864e                	mv	a2,s3
    800025a0:	b7c9                	j	80002562 <procdump+0x5a>
  }
}
    800025a2:	60a6                	ld	ra,72(sp)
    800025a4:	6406                	ld	s0,64(sp)
    800025a6:	74e2                	ld	s1,56(sp)
    800025a8:	7942                	ld	s2,48(sp)
    800025aa:	79a2                	ld	s3,40(sp)
    800025ac:	7a02                	ld	s4,32(sp)
    800025ae:	6ae2                	ld	s5,24(sp)
    800025b0:	6b42                	ld	s6,16(sp)
    800025b2:	6ba2                	ld	s7,8(sp)
    800025b4:	6161                	addi	sp,sp,80
    800025b6:	8082                	ret

00000000800025b8 <ps_listinfo>:

// function ps_listinfo for task 2
int ps_listinfo (struct procinfo *plist, int lim) {
    800025b8:	7119                	addi	sp,sp,-128
    800025ba:	fc86                	sd	ra,120(sp)
    800025bc:	f8a2                	sd	s0,112(sp)
    800025be:	f4a6                	sd	s1,104(sp)
    800025c0:	f0ca                	sd	s2,96(sp)
    800025c2:	ecce                	sd	s3,88(sp)
    800025c4:	e8d2                	sd	s4,80(sp)
    800025c6:	e4d6                	sd	s5,72(sp)
    800025c8:	e0da                	sd	s6,64(sp)
    800025ca:	fc5e                	sd	s7,56(sp)
    800025cc:	f862                	sd	s8,48(sp)
    800025ce:	f466                	sd	s9,40(sp)
    800025d0:	f06a                	sd	s10,32(sp)
    800025d2:	0100                	addi	s0,sp,128
    800025d4:	8a2a                	mv	s4,a0
    800025d6:	8aae                	mv	s5,a1
  int nproc = 0;  // number of alive processes
  struct proc *p;
  // counting nproc
  for (p = proc; p < &proc[NPROC]; p++) {
    800025d8:	0000f497          	auipc	s1,0xf
    800025dc:	9f848493          	addi	s1,s1,-1544 # 80010fd0 <proc>
  int nproc = 0;  // number of alive processes
    800025e0:	4901                	li	s2,0
  for (p = proc; p < &proc[NPROC]; p++) {
    800025e2:	00014997          	auipc	s3,0x14
    800025e6:	3ee98993          	addi	s3,s3,1006 # 800169d0 <tickslock>
    800025ea:	a811                	j	800025fe <ps_listinfo+0x46>
    acquire(&p->lock);
    if (p->state != UNUSED)
      nproc++;
    release(&p->lock);
    800025ec:	8526                	mv	a0,s1
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	69c080e7          	jalr	1692(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    800025f6:	16848493          	addi	s1,s1,360
    800025fa:	01348b63          	beq	s1,s3,80002610 <ps_listinfo+0x58>
    acquire(&p->lock);
    800025fe:	8526                	mv	a0,s1
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    if (p->state != UNUSED)
    80002608:	4c9c                	lw	a5,24(s1)
    8000260a:	d3ed                	beqz	a5,800025ec <ps_listinfo+0x34>
      nproc++;
    8000260c:	2905                	addiw	s2,s2,1
    8000260e:	bff9                	j	800025ec <ps_listinfo+0x34>
  }
  
  if (plist == NULL)
    80002610:	100a0b63          	beqz	s4,80002726 <ps_listinfo+0x16e>
    return nproc;
  if (nproc > lim)
    80002614:	112ac663          	blt	s5,s2,80002720 <ps_listinfo+0x168>
    [RUNNING]   "run",
    [ZOMBIE]    "zombie"
  };

  int i = 0;
  struct proc *mp = myproc();
    80002618:	fffff097          	auipc	ra,0xfffff
    8000261c:	394080e7          	jalr	916(ra) # 800019ac <myproc>
    80002620:	8aaa                	mv	s5,a0
  int i = 0;
    80002622:	4901                	li	s2,0
  struct procinfo pi;

  for (p = proc; p < &proc[NPROC]; p++) {
    80002624:	0000f497          	auipc	s1,0xf
    80002628:	9ac48493          	addi	s1,s1,-1620 # 80010fd0 <proc>
      release(&p->lock);
      continue;
    }

    safestrcpy(pi.name, p->name, sizeof(p->name));
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000262c:	4b95                	li	s7,5
    else
      safestrcpy(pi.state, "???", 3);
    if (p->parent == 0) {
      pi.parent_pid = -1;
    } else {
      acquire(&wait_lock);
    8000262e:	0000eb17          	auipc	s6,0xe
    80002632:	58ab0b13          	addi	s6,s6,1418 # 80010bb8 <wait_lock>
      pi.parent_pid = -1;
    80002636:	5d7d                	li	s10,-1
      safestrcpy(pi.state, "???", 3);
    80002638:	00006c97          	auipc	s9,0x6
    8000263c:	c48c8c93          	addi	s9,s9,-952 # 80008280 <digits+0x240>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002640:	00006c17          	auipc	s8,0x6
    80002644:	c98c0c13          	addi	s8,s8,-872 # 800082d8 <states.1>
  for (p = proc; p < &proc[NPROC]; p++) {
    80002648:	00014997          	auipc	s3,0x14
    8000264c:	38898993          	addi	s3,s3,904 # 800169d0 <tickslock>
    80002650:	a059                	j	800026d6 <ps_listinfo+0x11e>
      release(&p->lock);
    80002652:	8526                	mv	a0,s1
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	636080e7          	jalr	1590(ra) # 80000c8a <release>
      continue;
    8000265c:	a88d                	j	800026ce <ps_listinfo+0x116>
      safestrcpy(pi.state, "???", 3);
    8000265e:	460d                	li	a2,3
    80002660:	85e6                	mv	a1,s9
    80002662:	f9040513          	addi	a0,s0,-112
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	7b6080e7          	jalr	1974(ra) # 80000e1c <safestrcpy>
    if (p->parent == 0) {
    8000266e:	7c9c                	ld	a5,56(s1)
    80002670:	c7cd                	beqz	a5,8000271a <ps_listinfo+0x162>
      acquire(&wait_lock);
    80002672:	855a                	mv	a0,s6
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	562080e7          	jalr	1378(ra) # 80000bd6 <acquire>
      acquire(&p->parent->lock);
    8000267c:	7c88                	ld	a0,56(s1)
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	558080e7          	jalr	1368(ra) # 80000bd6 <acquire>
      pi.parent_pid = p->parent->pid;
    80002686:	7c88                	ld	a0,56(s1)
    80002688:	591c                	lw	a5,48(a0)
    8000268a:	f8f42c23          	sw	a5,-104(s0)
      release(&p->parent->lock);
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	5fc080e7          	jalr	1532(ra) # 80000c8a <release>
      release(&wait_lock);
    80002696:	855a                	mv	a0,s6
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	5f2080e7          	jalr	1522(ra) # 80000c8a <release>
    }
    release(&p->lock);
    800026a0:	8526                	mv	a0,s1
    800026a2:	ffffe097          	auipc	ra,0xffffe
    800026a6:	5e8080e7          	jalr	1512(ra) # 80000c8a <release>

    if (copyout(mp->pagetable, (uint64) (plist + i), (void*) &pi, sizeof(struct procinfo)) < 0) {
    800026aa:	00391593          	slli	a1,s2,0x3
    800026ae:	412585b3          	sub	a1,a1,s2
    800026b2:	058a                	slli	a1,a1,0x2
    800026b4:	46f1                	li	a3,28
    800026b6:	f8040613          	addi	a2,s0,-128
    800026ba:	95d2                	add	a1,a1,s4
    800026bc:	050ab503          	ld	a0,80(s5)
    800026c0:	fffff097          	auipc	ra,0xfffff
    800026c4:	fac080e7          	jalr	-84(ra) # 8000166c <copyout>
    800026c8:	04054e63          	bltz	a0,80002724 <ps_listinfo+0x16c>
      return -2;
    }

    i++;
    800026cc:	2905                	addiw	s2,s2,1
  for (p = proc; p < &proc[NPROC]; p++) {
    800026ce:	16848493          	addi	s1,s1,360
    800026d2:	05348a63          	beq	s1,s3,80002726 <ps_listinfo+0x16e>
    acquire(&p->lock);
    800026d6:	8526                	mv	a0,s1
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	4fe080e7          	jalr	1278(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    800026e0:	4c9c                	lw	a5,24(s1)
    800026e2:	dba5                	beqz	a5,80002652 <ps_listinfo+0x9a>
    safestrcpy(pi.name, p->name, sizeof(p->name));
    800026e4:	4641                	li	a2,16
    800026e6:	15848593          	addi	a1,s1,344
    800026ea:	f8040513          	addi	a0,s0,-128
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	72e080e7          	jalr	1838(ra) # 80000e1c <safestrcpy>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f6:	4c9c                	lw	a5,24(s1)
    800026f8:	f6fbe3e3          	bltu	s7,a5,8000265e <ps_listinfo+0xa6>
    800026fc:	02079713          	slli	a4,a5,0x20
    80002700:	01d75793          	srli	a5,a4,0x1d
    80002704:	97e2                	add	a5,a5,s8
    80002706:	7b8c                	ld	a1,48(a5)
    80002708:	d9b9                	beqz	a1,8000265e <ps_listinfo+0xa6>
      safestrcpy(pi.state, states[p->state], sizeof(states[p->state]));
    8000270a:	4621                	li	a2,8
    8000270c:	f9040513          	addi	a0,s0,-112
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	70c080e7          	jalr	1804(ra) # 80000e1c <safestrcpy>
    80002718:	bf99                	j	8000266e <ps_listinfo+0xb6>
      pi.parent_pid = -1;
    8000271a:	f9a42c23          	sw	s10,-104(s0)
    8000271e:	b749                	j	800026a0 <ps_listinfo+0xe8>
    return -1;
    80002720:	597d                	li	s2,-1
    80002722:	a011                	j	80002726 <ps_listinfo+0x16e>
      return -2;
    80002724:	5979                	li	s2,-2
  }
  return i;
}
    80002726:	854a                	mv	a0,s2
    80002728:	70e6                	ld	ra,120(sp)
    8000272a:	7446                	ld	s0,112(sp)
    8000272c:	74a6                	ld	s1,104(sp)
    8000272e:	7906                	ld	s2,96(sp)
    80002730:	69e6                	ld	s3,88(sp)
    80002732:	6a46                	ld	s4,80(sp)
    80002734:	6aa6                	ld	s5,72(sp)
    80002736:	6b06                	ld	s6,64(sp)
    80002738:	7be2                	ld	s7,56(sp)
    8000273a:	7c42                	ld	s8,48(sp)
    8000273c:	7ca2                	ld	s9,40(sp)
    8000273e:	7d02                	ld	s10,32(sp)
    80002740:	6109                	addi	sp,sp,128
    80002742:	8082                	ret

0000000080002744 <sys_ps_listinfo>:

// syscall wrap for ps_listinfo
uint64 sys_ps_listinfo(void)
{
    80002744:	1101                	addi	sp,sp,-32
    80002746:	ec06                	sd	ra,24(sp)
    80002748:	e822                	sd	s0,16(sp)
    8000274a:	1000                	addi	s0,sp,32
  struct procinfo *plist;
  int lim;
  argaddr(0, (uint64*) &plist);
    8000274c:	fe840593          	addi	a1,s0,-24
    80002750:	4501                	li	a0,0
    80002752:	00000097          	auipc	ra,0x0
    80002756:	558080e7          	jalr	1368(ra) # 80002caa <argaddr>
  argint(1, &lim);
    8000275a:	fe440593          	addi	a1,s0,-28
    8000275e:	4505                	li	a0,1
    80002760:	00000097          	auipc	ra,0x0
    80002764:	52a080e7          	jalr	1322(ra) # 80002c8a <argint>
  return ps_listinfo(plist, lim);
    80002768:	fe442583          	lw	a1,-28(s0)
    8000276c:	fe843503          	ld	a0,-24(s0)
    80002770:	00000097          	auipc	ra,0x0
    80002774:	e48080e7          	jalr	-440(ra) # 800025b8 <ps_listinfo>
}
    80002778:	60e2                	ld	ra,24(sp)
    8000277a:	6442                	ld	s0,16(sp)
    8000277c:	6105                	addi	sp,sp,32
    8000277e:	8082                	ret

0000000080002780 <swtch>:
    80002780:	00153023          	sd	ra,0(a0)
    80002784:	00253423          	sd	sp,8(a0)
    80002788:	e900                	sd	s0,16(a0)
    8000278a:	ed04                	sd	s1,24(a0)
    8000278c:	03253023          	sd	s2,32(a0)
    80002790:	03353423          	sd	s3,40(a0)
    80002794:	03453823          	sd	s4,48(a0)
    80002798:	03553c23          	sd	s5,56(a0)
    8000279c:	05653023          	sd	s6,64(a0)
    800027a0:	05753423          	sd	s7,72(a0)
    800027a4:	05853823          	sd	s8,80(a0)
    800027a8:	05953c23          	sd	s9,88(a0)
    800027ac:	07a53023          	sd	s10,96(a0)
    800027b0:	07b53423          	sd	s11,104(a0)
    800027b4:	0005b083          	ld	ra,0(a1)
    800027b8:	0085b103          	ld	sp,8(a1)
    800027bc:	6980                	ld	s0,16(a1)
    800027be:	6d84                	ld	s1,24(a1)
    800027c0:	0205b903          	ld	s2,32(a1)
    800027c4:	0285b983          	ld	s3,40(a1)
    800027c8:	0305ba03          	ld	s4,48(a1)
    800027cc:	0385ba83          	ld	s5,56(a1)
    800027d0:	0405bb03          	ld	s6,64(a1)
    800027d4:	0485bb83          	ld	s7,72(a1)
    800027d8:	0505bc03          	ld	s8,80(a1)
    800027dc:	0585bc83          	ld	s9,88(a1)
    800027e0:	0605bd03          	ld	s10,96(a1)
    800027e4:	0685bd83          	ld	s11,104(a1)
    800027e8:	8082                	ret

00000000800027ea <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027ea:	1141                	addi	sp,sp,-16
    800027ec:	e406                	sd	ra,8(sp)
    800027ee:	e022                	sd	s0,0(sp)
    800027f0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027f2:	00006597          	auipc	a1,0x6
    800027f6:	b4658593          	addi	a1,a1,-1210 # 80008338 <states.0+0x30>
    800027fa:	00014517          	auipc	a0,0x14
    800027fe:	1d650513          	addi	a0,a0,470 # 800169d0 <tickslock>
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	344080e7          	jalr	836(ra) # 80000b46 <initlock>
}
    8000280a:	60a2                	ld	ra,8(sp)
    8000280c:	6402                	ld	s0,0(sp)
    8000280e:	0141                	addi	sp,sp,16
    80002810:	8082                	ret

0000000080002812 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002812:	1141                	addi	sp,sp,-16
    80002814:	e422                	sd	s0,8(sp)
    80002816:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002818:	00003797          	auipc	a5,0x3
    8000281c:	4c878793          	addi	a5,a5,1224 # 80005ce0 <kernelvec>
    80002820:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002824:	6422                	ld	s0,8(sp)
    80002826:	0141                	addi	sp,sp,16
    80002828:	8082                	ret

000000008000282a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000282a:	1141                	addi	sp,sp,-16
    8000282c:	e406                	sd	ra,8(sp)
    8000282e:	e022                	sd	s0,0(sp)
    80002830:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002832:	fffff097          	auipc	ra,0xfffff
    80002836:	17a080e7          	jalr	378(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000283e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002840:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002844:	00004697          	auipc	a3,0x4
    80002848:	7bc68693          	addi	a3,a3,1980 # 80007000 <_trampoline>
    8000284c:	00004717          	auipc	a4,0x4
    80002850:	7b470713          	addi	a4,a4,1972 # 80007000 <_trampoline>
    80002854:	8f15                	sub	a4,a4,a3
    80002856:	040007b7          	lui	a5,0x4000
    8000285a:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000285c:	07b2                	slli	a5,a5,0xc
    8000285e:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002860:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002864:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002866:	18002673          	csrr	a2,satp
    8000286a:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000286c:	6d30                	ld	a2,88(a0)
    8000286e:	6138                	ld	a4,64(a0)
    80002870:	6585                	lui	a1,0x1
    80002872:	972e                	add	a4,a4,a1
    80002874:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002876:	6d38                	ld	a4,88(a0)
    80002878:	00000617          	auipc	a2,0x0
    8000287c:	13060613          	addi	a2,a2,304 # 800029a8 <usertrap>
    80002880:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002882:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002884:	8612                	mv	a2,tp
    80002886:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002888:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000288c:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002890:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002894:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002898:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000289a:	6f18                	ld	a4,24(a4)
    8000289c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028a0:	6928                	ld	a0,80(a0)
    800028a2:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028a4:	00004717          	auipc	a4,0x4
    800028a8:	7f870713          	addi	a4,a4,2040 # 8000709c <userret>
    800028ac:	8f15                	sub	a4,a4,a3
    800028ae:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028b0:	577d                	li	a4,-1
    800028b2:	177e                	slli	a4,a4,0x3f
    800028b4:	8d59                	or	a0,a0,a4
    800028b6:	9782                	jalr	a5
}
    800028b8:	60a2                	ld	ra,8(sp)
    800028ba:	6402                	ld	s0,0(sp)
    800028bc:	0141                	addi	sp,sp,16
    800028be:	8082                	ret

00000000800028c0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028c0:	1101                	addi	sp,sp,-32
    800028c2:	ec06                	sd	ra,24(sp)
    800028c4:	e822                	sd	s0,16(sp)
    800028c6:	e426                	sd	s1,8(sp)
    800028c8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028ca:	00014497          	auipc	s1,0x14
    800028ce:	10648493          	addi	s1,s1,262 # 800169d0 <tickslock>
    800028d2:	8526                	mv	a0,s1
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	302080e7          	jalr	770(ra) # 80000bd6 <acquire>
  ticks++;
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	05450513          	addi	a0,a0,84 # 80008930 <ticks>
    800028e4:	411c                	lw	a5,0(a0)
    800028e6:	2785                	addiw	a5,a5,1
    800028e8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028ea:	fffff097          	auipc	ra,0xfffff
    800028ee:	7ce080e7          	jalr	1998(ra) # 800020b8 <wakeup>
  release(&tickslock);
    800028f2:	8526                	mv	a0,s1
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	396080e7          	jalr	918(ra) # 80000c8a <release>
}
    800028fc:	60e2                	ld	ra,24(sp)
    800028fe:	6442                	ld	s0,16(sp)
    80002900:	64a2                	ld	s1,8(sp)
    80002902:	6105                	addi	sp,sp,32
    80002904:	8082                	ret

0000000080002906 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002906:	1101                	addi	sp,sp,-32
    80002908:	ec06                	sd	ra,24(sp)
    8000290a:	e822                	sd	s0,16(sp)
    8000290c:	e426                	sd	s1,8(sp)
    8000290e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002910:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002914:	00074d63          	bltz	a4,8000292e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002918:	57fd                	li	a5,-1
    8000291a:	17fe                	slli	a5,a5,0x3f
    8000291c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000291e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002920:	06f70363          	beq	a4,a5,80002986 <devintr+0x80>
  }
}
    80002924:	60e2                	ld	ra,24(sp)
    80002926:	6442                	ld	s0,16(sp)
    80002928:	64a2                	ld	s1,8(sp)
    8000292a:	6105                	addi	sp,sp,32
    8000292c:	8082                	ret
     (scause & 0xff) == 9){
    8000292e:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002932:	46a5                	li	a3,9
    80002934:	fed792e3          	bne	a5,a3,80002918 <devintr+0x12>
    int irq = plic_claim();
    80002938:	00003097          	auipc	ra,0x3
    8000293c:	4b0080e7          	jalr	1200(ra) # 80005de8 <plic_claim>
    80002940:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002942:	47a9                	li	a5,10
    80002944:	02f50763          	beq	a0,a5,80002972 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002948:	4785                	li	a5,1
    8000294a:	02f50963          	beq	a0,a5,8000297c <devintr+0x76>
    return 1;
    8000294e:	4505                	li	a0,1
    } else if(irq){
    80002950:	d8f1                	beqz	s1,80002924 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002952:	85a6                	mv	a1,s1
    80002954:	00006517          	auipc	a0,0x6
    80002958:	9ec50513          	addi	a0,a0,-1556 # 80008340 <states.0+0x38>
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	c2e080e7          	jalr	-978(ra) # 8000058a <printf>
      plic_complete(irq);
    80002964:	8526                	mv	a0,s1
    80002966:	00003097          	auipc	ra,0x3
    8000296a:	4a6080e7          	jalr	1190(ra) # 80005e0c <plic_complete>
    return 1;
    8000296e:	4505                	li	a0,1
    80002970:	bf55                	j	80002924 <devintr+0x1e>
      uartintr();
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	026080e7          	jalr	38(ra) # 80000998 <uartintr>
    8000297a:	b7ed                	j	80002964 <devintr+0x5e>
      virtio_disk_intr();
    8000297c:	00004097          	auipc	ra,0x4
    80002980:	958080e7          	jalr	-1704(ra) # 800062d4 <virtio_disk_intr>
    80002984:	b7c5                	j	80002964 <devintr+0x5e>
    if(cpuid() == 0){
    80002986:	fffff097          	auipc	ra,0xfffff
    8000298a:	ffa080e7          	jalr	-6(ra) # 80001980 <cpuid>
    8000298e:	c901                	beqz	a0,8000299e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002990:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002994:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002996:	14479073          	csrw	sip,a5
    return 2;
    8000299a:	4509                	li	a0,2
    8000299c:	b761                	j	80002924 <devintr+0x1e>
      clockintr();
    8000299e:	00000097          	auipc	ra,0x0
    800029a2:	f22080e7          	jalr	-222(ra) # 800028c0 <clockintr>
    800029a6:	b7ed                	j	80002990 <devintr+0x8a>

00000000800029a8 <usertrap>:
{
    800029a8:	1101                	addi	sp,sp,-32
    800029aa:	ec06                	sd	ra,24(sp)
    800029ac:	e822                	sd	s0,16(sp)
    800029ae:	e426                	sd	s1,8(sp)
    800029b0:	e04a                	sd	s2,0(sp)
    800029b2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029b8:	1007f793          	andi	a5,a5,256
    800029bc:	e3b1                	bnez	a5,80002a00 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029be:	00003797          	auipc	a5,0x3
    800029c2:	32278793          	addi	a5,a5,802 # 80005ce0 <kernelvec>
    800029c6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029ca:	fffff097          	auipc	ra,0xfffff
    800029ce:	fe2080e7          	jalr	-30(ra) # 800019ac <myproc>
    800029d2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029d4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029d6:	14102773          	csrr	a4,sepc
    800029da:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029dc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029e0:	47a1                	li	a5,8
    800029e2:	02f70763          	beq	a4,a5,80002a10 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800029e6:	00000097          	auipc	ra,0x0
    800029ea:	f20080e7          	jalr	-224(ra) # 80002906 <devintr>
    800029ee:	892a                	mv	s2,a0
    800029f0:	c151                	beqz	a0,80002a74 <usertrap+0xcc>
  if(killed(p))
    800029f2:	8526                	mv	a0,s1
    800029f4:	00000097          	auipc	ra,0x0
    800029f8:	908080e7          	jalr	-1784(ra) # 800022fc <killed>
    800029fc:	c929                	beqz	a0,80002a4e <usertrap+0xa6>
    800029fe:	a099                	j	80002a44 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a00:	00006517          	auipc	a0,0x6
    80002a04:	96050513          	addi	a0,a0,-1696 # 80008360 <states.0+0x58>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	b38080e7          	jalr	-1224(ra) # 80000540 <panic>
    if(killed(p))
    80002a10:	00000097          	auipc	ra,0x0
    80002a14:	8ec080e7          	jalr	-1812(ra) # 800022fc <killed>
    80002a18:	e921                	bnez	a0,80002a68 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002a1a:	6cb8                	ld	a4,88(s1)
    80002a1c:	6f1c                	ld	a5,24(a4)
    80002a1e:	0791                	addi	a5,a5,4
    80002a20:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a22:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a26:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a2a:	10079073          	csrw	sstatus,a5
    syscall();
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	2d4080e7          	jalr	724(ra) # 80002d02 <syscall>
  if(killed(p))
    80002a36:	8526                	mv	a0,s1
    80002a38:	00000097          	auipc	ra,0x0
    80002a3c:	8c4080e7          	jalr	-1852(ra) # 800022fc <killed>
    80002a40:	c911                	beqz	a0,80002a54 <usertrap+0xac>
    80002a42:	4901                	li	s2,0
    exit(-1);
    80002a44:	557d                	li	a0,-1
    80002a46:	fffff097          	auipc	ra,0xfffff
    80002a4a:	742080e7          	jalr	1858(ra) # 80002188 <exit>
  if(which_dev == 2)
    80002a4e:	4789                	li	a5,2
    80002a50:	04f90f63          	beq	s2,a5,80002aae <usertrap+0x106>
  usertrapret();
    80002a54:	00000097          	auipc	ra,0x0
    80002a58:	dd6080e7          	jalr	-554(ra) # 8000282a <usertrapret>
}
    80002a5c:	60e2                	ld	ra,24(sp)
    80002a5e:	6442                	ld	s0,16(sp)
    80002a60:	64a2                	ld	s1,8(sp)
    80002a62:	6902                	ld	s2,0(sp)
    80002a64:	6105                	addi	sp,sp,32
    80002a66:	8082                	ret
      exit(-1);
    80002a68:	557d                	li	a0,-1
    80002a6a:	fffff097          	auipc	ra,0xfffff
    80002a6e:	71e080e7          	jalr	1822(ra) # 80002188 <exit>
    80002a72:	b765                	j	80002a1a <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a74:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a78:	5890                	lw	a2,48(s1)
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	90650513          	addi	a0,a0,-1786 # 80008380 <states.0+0x78>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	b08080e7          	jalr	-1272(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a8a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a8e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a92:	00006517          	auipc	a0,0x6
    80002a96:	91e50513          	addi	a0,a0,-1762 # 800083b0 <states.0+0xa8>
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	af0080e7          	jalr	-1296(ra) # 8000058a <printf>
    setkilled(p);
    80002aa2:	8526                	mv	a0,s1
    80002aa4:	00000097          	auipc	ra,0x0
    80002aa8:	82c080e7          	jalr	-2004(ra) # 800022d0 <setkilled>
    80002aac:	b769                	j	80002a36 <usertrap+0x8e>
    yield();
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	56a080e7          	jalr	1386(ra) # 80002018 <yield>
    80002ab6:	bf79                	j	80002a54 <usertrap+0xac>

0000000080002ab8 <kerneltrap>:
{
    80002ab8:	7179                	addi	sp,sp,-48
    80002aba:	f406                	sd	ra,40(sp)
    80002abc:	f022                	sd	s0,32(sp)
    80002abe:	ec26                	sd	s1,24(sp)
    80002ac0:	e84a                	sd	s2,16(sp)
    80002ac2:	e44e                	sd	s3,8(sp)
    80002ac4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ac6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aca:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ace:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ad2:	1004f793          	andi	a5,s1,256
    80002ad6:	cb85                	beqz	a5,80002b06 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002adc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ade:	ef85                	bnez	a5,80002b16 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ae0:	00000097          	auipc	ra,0x0
    80002ae4:	e26080e7          	jalr	-474(ra) # 80002906 <devintr>
    80002ae8:	cd1d                	beqz	a0,80002b26 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aea:	4789                	li	a5,2
    80002aec:	06f50a63          	beq	a0,a5,80002b60 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002af0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002af4:	10049073          	csrw	sstatus,s1
}
    80002af8:	70a2                	ld	ra,40(sp)
    80002afa:	7402                	ld	s0,32(sp)
    80002afc:	64e2                	ld	s1,24(sp)
    80002afe:	6942                	ld	s2,16(sp)
    80002b00:	69a2                	ld	s3,8(sp)
    80002b02:	6145                	addi	sp,sp,48
    80002b04:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b06:	00006517          	auipc	a0,0x6
    80002b0a:	8ca50513          	addi	a0,a0,-1846 # 800083d0 <states.0+0xc8>
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	a32080e7          	jalr	-1486(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b16:	00006517          	auipc	a0,0x6
    80002b1a:	8e250513          	addi	a0,a0,-1822 # 800083f8 <states.0+0xf0>
    80002b1e:	ffffe097          	auipc	ra,0xffffe
    80002b22:	a22080e7          	jalr	-1502(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002b26:	85ce                	mv	a1,s3
    80002b28:	00006517          	auipc	a0,0x6
    80002b2c:	8f050513          	addi	a0,a0,-1808 # 80008418 <states.0+0x110>
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	a5a080e7          	jalr	-1446(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b38:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b3c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b40:	00006517          	auipc	a0,0x6
    80002b44:	8e850513          	addi	a0,a0,-1816 # 80008428 <states.0+0x120>
    80002b48:	ffffe097          	auipc	ra,0xffffe
    80002b4c:	a42080e7          	jalr	-1470(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002b50:	00006517          	auipc	a0,0x6
    80002b54:	8f050513          	addi	a0,a0,-1808 # 80008440 <states.0+0x138>
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	9e8080e7          	jalr	-1560(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b60:	fffff097          	auipc	ra,0xfffff
    80002b64:	e4c080e7          	jalr	-436(ra) # 800019ac <myproc>
    80002b68:	d541                	beqz	a0,80002af0 <kerneltrap+0x38>
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	e42080e7          	jalr	-446(ra) # 800019ac <myproc>
    80002b72:	4d18                	lw	a4,24(a0)
    80002b74:	4791                	li	a5,4
    80002b76:	f6f71de3          	bne	a4,a5,80002af0 <kerneltrap+0x38>
    yield();
    80002b7a:	fffff097          	auipc	ra,0xfffff
    80002b7e:	49e080e7          	jalr	1182(ra) # 80002018 <yield>
    80002b82:	b7bd                	j	80002af0 <kerneltrap+0x38>

0000000080002b84 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b84:	1101                	addi	sp,sp,-32
    80002b86:	ec06                	sd	ra,24(sp)
    80002b88:	e822                	sd	s0,16(sp)
    80002b8a:	e426                	sd	s1,8(sp)
    80002b8c:	1000                	addi	s0,sp,32
    80002b8e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	e1c080e7          	jalr	-484(ra) # 800019ac <myproc>
  switch (n) {
    80002b98:	4795                	li	a5,5
    80002b9a:	0497e163          	bltu	a5,s1,80002bdc <argraw+0x58>
    80002b9e:	048a                	slli	s1,s1,0x2
    80002ba0:	00006717          	auipc	a4,0x6
    80002ba4:	8d870713          	addi	a4,a4,-1832 # 80008478 <states.0+0x170>
    80002ba8:	94ba                	add	s1,s1,a4
    80002baa:	409c                	lw	a5,0(s1)
    80002bac:	97ba                	add	a5,a5,a4
    80002bae:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bb0:	6d3c                	ld	a5,88(a0)
    80002bb2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bb4:	60e2                	ld	ra,24(sp)
    80002bb6:	6442                	ld	s0,16(sp)
    80002bb8:	64a2                	ld	s1,8(sp)
    80002bba:	6105                	addi	sp,sp,32
    80002bbc:	8082                	ret
    return p->trapframe->a1;
    80002bbe:	6d3c                	ld	a5,88(a0)
    80002bc0:	7fa8                	ld	a0,120(a5)
    80002bc2:	bfcd                	j	80002bb4 <argraw+0x30>
    return p->trapframe->a2;
    80002bc4:	6d3c                	ld	a5,88(a0)
    80002bc6:	63c8                	ld	a0,128(a5)
    80002bc8:	b7f5                	j	80002bb4 <argraw+0x30>
    return p->trapframe->a3;
    80002bca:	6d3c                	ld	a5,88(a0)
    80002bcc:	67c8                	ld	a0,136(a5)
    80002bce:	b7dd                	j	80002bb4 <argraw+0x30>
    return p->trapframe->a4;
    80002bd0:	6d3c                	ld	a5,88(a0)
    80002bd2:	6bc8                	ld	a0,144(a5)
    80002bd4:	b7c5                	j	80002bb4 <argraw+0x30>
    return p->trapframe->a5;
    80002bd6:	6d3c                	ld	a5,88(a0)
    80002bd8:	6fc8                	ld	a0,152(a5)
    80002bda:	bfe9                	j	80002bb4 <argraw+0x30>
  panic("argraw");
    80002bdc:	00006517          	auipc	a0,0x6
    80002be0:	87450513          	addi	a0,a0,-1932 # 80008450 <states.0+0x148>
    80002be4:	ffffe097          	auipc	ra,0xffffe
    80002be8:	95c080e7          	jalr	-1700(ra) # 80000540 <panic>

0000000080002bec <fetchaddr>:
{
    80002bec:	1101                	addi	sp,sp,-32
    80002bee:	ec06                	sd	ra,24(sp)
    80002bf0:	e822                	sd	s0,16(sp)
    80002bf2:	e426                	sd	s1,8(sp)
    80002bf4:	e04a                	sd	s2,0(sp)
    80002bf6:	1000                	addi	s0,sp,32
    80002bf8:	84aa                	mv	s1,a0
    80002bfa:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	db0080e7          	jalr	-592(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c04:	653c                	ld	a5,72(a0)
    80002c06:	02f4f863          	bgeu	s1,a5,80002c36 <fetchaddr+0x4a>
    80002c0a:	00848713          	addi	a4,s1,8
    80002c0e:	02e7e663          	bltu	a5,a4,80002c3a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c12:	46a1                	li	a3,8
    80002c14:	8626                	mv	a2,s1
    80002c16:	85ca                	mv	a1,s2
    80002c18:	6928                	ld	a0,80(a0)
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	ade080e7          	jalr	-1314(ra) # 800016f8 <copyin>
    80002c22:	00a03533          	snez	a0,a0
    80002c26:	40a00533          	neg	a0,a0
}
    80002c2a:	60e2                	ld	ra,24(sp)
    80002c2c:	6442                	ld	s0,16(sp)
    80002c2e:	64a2                	ld	s1,8(sp)
    80002c30:	6902                	ld	s2,0(sp)
    80002c32:	6105                	addi	sp,sp,32
    80002c34:	8082                	ret
    return -1;
    80002c36:	557d                	li	a0,-1
    80002c38:	bfcd                	j	80002c2a <fetchaddr+0x3e>
    80002c3a:	557d                	li	a0,-1
    80002c3c:	b7fd                	j	80002c2a <fetchaddr+0x3e>

0000000080002c3e <fetchstr>:
{
    80002c3e:	7179                	addi	sp,sp,-48
    80002c40:	f406                	sd	ra,40(sp)
    80002c42:	f022                	sd	s0,32(sp)
    80002c44:	ec26                	sd	s1,24(sp)
    80002c46:	e84a                	sd	s2,16(sp)
    80002c48:	e44e                	sd	s3,8(sp)
    80002c4a:	1800                	addi	s0,sp,48
    80002c4c:	892a                	mv	s2,a0
    80002c4e:	84ae                	mv	s1,a1
    80002c50:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	d5a080e7          	jalr	-678(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c5a:	86ce                	mv	a3,s3
    80002c5c:	864a                	mv	a2,s2
    80002c5e:	85a6                	mv	a1,s1
    80002c60:	6928                	ld	a0,80(a0)
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	b24080e7          	jalr	-1244(ra) # 80001786 <copyinstr>
    80002c6a:	00054e63          	bltz	a0,80002c86 <fetchstr+0x48>
  return strlen(buf);
    80002c6e:	8526                	mv	a0,s1
    80002c70:	ffffe097          	auipc	ra,0xffffe
    80002c74:	1de080e7          	jalr	478(ra) # 80000e4e <strlen>
}
    80002c78:	70a2                	ld	ra,40(sp)
    80002c7a:	7402                	ld	s0,32(sp)
    80002c7c:	64e2                	ld	s1,24(sp)
    80002c7e:	6942                	ld	s2,16(sp)
    80002c80:	69a2                	ld	s3,8(sp)
    80002c82:	6145                	addi	sp,sp,48
    80002c84:	8082                	ret
    return -1;
    80002c86:	557d                	li	a0,-1
    80002c88:	bfc5                	j	80002c78 <fetchstr+0x3a>

0000000080002c8a <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c8a:	1101                	addi	sp,sp,-32
    80002c8c:	ec06                	sd	ra,24(sp)
    80002c8e:	e822                	sd	s0,16(sp)
    80002c90:	e426                	sd	s1,8(sp)
    80002c92:	1000                	addi	s0,sp,32
    80002c94:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c96:	00000097          	auipc	ra,0x0
    80002c9a:	eee080e7          	jalr	-274(ra) # 80002b84 <argraw>
    80002c9e:	c088                	sw	a0,0(s1)
}
    80002ca0:	60e2                	ld	ra,24(sp)
    80002ca2:	6442                	ld	s0,16(sp)
    80002ca4:	64a2                	ld	s1,8(sp)
    80002ca6:	6105                	addi	sp,sp,32
    80002ca8:	8082                	ret

0000000080002caa <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002caa:	1101                	addi	sp,sp,-32
    80002cac:	ec06                	sd	ra,24(sp)
    80002cae:	e822                	sd	s0,16(sp)
    80002cb0:	e426                	sd	s1,8(sp)
    80002cb2:	1000                	addi	s0,sp,32
    80002cb4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cb6:	00000097          	auipc	ra,0x0
    80002cba:	ece080e7          	jalr	-306(ra) # 80002b84 <argraw>
    80002cbe:	e088                	sd	a0,0(s1)
}
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	64a2                	ld	s1,8(sp)
    80002cc6:	6105                	addi	sp,sp,32
    80002cc8:	8082                	ret

0000000080002cca <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cca:	7179                	addi	sp,sp,-48
    80002ccc:	f406                	sd	ra,40(sp)
    80002cce:	f022                	sd	s0,32(sp)
    80002cd0:	ec26                	sd	s1,24(sp)
    80002cd2:	e84a                	sd	s2,16(sp)
    80002cd4:	1800                	addi	s0,sp,48
    80002cd6:	84ae                	mv	s1,a1
    80002cd8:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002cda:	fd840593          	addi	a1,s0,-40
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	fcc080e7          	jalr	-52(ra) # 80002caa <argaddr>
  return fetchstr(addr, buf, max);
    80002ce6:	864a                	mv	a2,s2
    80002ce8:	85a6                	mv	a1,s1
    80002cea:	fd843503          	ld	a0,-40(s0)
    80002cee:	00000097          	auipc	ra,0x0
    80002cf2:	f50080e7          	jalr	-176(ra) # 80002c3e <fetchstr>
}
    80002cf6:	70a2                	ld	ra,40(sp)
    80002cf8:	7402                	ld	s0,32(sp)
    80002cfa:	64e2                	ld	s1,24(sp)
    80002cfc:	6942                	ld	s2,16(sp)
    80002cfe:	6145                	addi	sp,sp,48
    80002d00:	8082                	ret

0000000080002d02 <syscall>:
[SYS_ps_listinfo]   sys_ps_listinfo,
};

void
syscall(void)
{
    80002d02:	1101                	addi	sp,sp,-32
    80002d04:	ec06                	sd	ra,24(sp)
    80002d06:	e822                	sd	s0,16(sp)
    80002d08:	e426                	sd	s1,8(sp)
    80002d0a:	e04a                	sd	s2,0(sp)
    80002d0c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	c9e080e7          	jalr	-866(ra) # 800019ac <myproc>
    80002d16:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d18:	05853903          	ld	s2,88(a0)
    80002d1c:	0a893783          	ld	a5,168(s2)
    80002d20:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d24:	37fd                	addiw	a5,a5,-1
    80002d26:	4755                	li	a4,21
    80002d28:	00f76f63          	bltu	a4,a5,80002d46 <syscall+0x44>
    80002d2c:	00369713          	slli	a4,a3,0x3
    80002d30:	00005797          	auipc	a5,0x5
    80002d34:	76078793          	addi	a5,a5,1888 # 80008490 <syscalls>
    80002d38:	97ba                	add	a5,a5,a4
    80002d3a:	639c                	ld	a5,0(a5)
    80002d3c:	c789                	beqz	a5,80002d46 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d3e:	9782                	jalr	a5
    80002d40:	06a93823          	sd	a0,112(s2)
    80002d44:	a839                	j	80002d62 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d46:	15848613          	addi	a2,s1,344
    80002d4a:	588c                	lw	a1,48(s1)
    80002d4c:	00005517          	auipc	a0,0x5
    80002d50:	70c50513          	addi	a0,a0,1804 # 80008458 <states.0+0x150>
    80002d54:	ffffe097          	auipc	ra,0xffffe
    80002d58:	836080e7          	jalr	-1994(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d5c:	6cbc                	ld	a5,88(s1)
    80002d5e:	577d                	li	a4,-1
    80002d60:	fbb8                	sd	a4,112(a5)
  }
}
    80002d62:	60e2                	ld	ra,24(sp)
    80002d64:	6442                	ld	s0,16(sp)
    80002d66:	64a2                	ld	s1,8(sp)
    80002d68:	6902                	ld	s2,0(sp)
    80002d6a:	6105                	addi	sp,sp,32
    80002d6c:	8082                	ret

0000000080002d6e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d6e:	1101                	addi	sp,sp,-32
    80002d70:	ec06                	sd	ra,24(sp)
    80002d72:	e822                	sd	s0,16(sp)
    80002d74:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d76:	fec40593          	addi	a1,s0,-20
    80002d7a:	4501                	li	a0,0
    80002d7c:	00000097          	auipc	ra,0x0
    80002d80:	f0e080e7          	jalr	-242(ra) # 80002c8a <argint>
  exit(n);
    80002d84:	fec42503          	lw	a0,-20(s0)
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	400080e7          	jalr	1024(ra) # 80002188 <exit>
  return 0;  // not reached
}
    80002d90:	4501                	li	a0,0
    80002d92:	60e2                	ld	ra,24(sp)
    80002d94:	6442                	ld	s0,16(sp)
    80002d96:	6105                	addi	sp,sp,32
    80002d98:	8082                	ret

0000000080002d9a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d9a:	1141                	addi	sp,sp,-16
    80002d9c:	e406                	sd	ra,8(sp)
    80002d9e:	e022                	sd	s0,0(sp)
    80002da0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	c0a080e7          	jalr	-1014(ra) # 800019ac <myproc>
}
    80002daa:	5908                	lw	a0,48(a0)
    80002dac:	60a2                	ld	ra,8(sp)
    80002dae:	6402                	ld	s0,0(sp)
    80002db0:	0141                	addi	sp,sp,16
    80002db2:	8082                	ret

0000000080002db4 <sys_fork>:

uint64
sys_fork(void)
{
    80002db4:	1141                	addi	sp,sp,-16
    80002db6:	e406                	sd	ra,8(sp)
    80002db8:	e022                	sd	s0,0(sp)
    80002dba:	0800                	addi	s0,sp,16
  return fork();
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	fa6080e7          	jalr	-90(ra) # 80001d62 <fork>
}
    80002dc4:	60a2                	ld	ra,8(sp)
    80002dc6:	6402                	ld	s0,0(sp)
    80002dc8:	0141                	addi	sp,sp,16
    80002dca:	8082                	ret

0000000080002dcc <sys_wait>:

uint64
sys_wait(void)
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002dd4:	fe840593          	addi	a1,s0,-24
    80002dd8:	4501                	li	a0,0
    80002dda:	00000097          	auipc	ra,0x0
    80002dde:	ed0080e7          	jalr	-304(ra) # 80002caa <argaddr>
  return wait(p);
    80002de2:	fe843503          	ld	a0,-24(s0)
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	548080e7          	jalr	1352(ra) # 8000232e <wait>
}
    80002dee:	60e2                	ld	ra,24(sp)
    80002df0:	6442                	ld	s0,16(sp)
    80002df2:	6105                	addi	sp,sp,32
    80002df4:	8082                	ret

0000000080002df6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002df6:	7179                	addi	sp,sp,-48
    80002df8:	f406                	sd	ra,40(sp)
    80002dfa:	f022                	sd	s0,32(sp)
    80002dfc:	ec26                	sd	s1,24(sp)
    80002dfe:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e00:	fdc40593          	addi	a1,s0,-36
    80002e04:	4501                	li	a0,0
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	e84080e7          	jalr	-380(ra) # 80002c8a <argint>
  addr = myproc()->sz;
    80002e0e:	fffff097          	auipc	ra,0xfffff
    80002e12:	b9e080e7          	jalr	-1122(ra) # 800019ac <myproc>
    80002e16:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e18:	fdc42503          	lw	a0,-36(s0)
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	eea080e7          	jalr	-278(ra) # 80001d06 <growproc>
    80002e24:	00054863          	bltz	a0,80002e34 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e28:	8526                	mv	a0,s1
    80002e2a:	70a2                	ld	ra,40(sp)
    80002e2c:	7402                	ld	s0,32(sp)
    80002e2e:	64e2                	ld	s1,24(sp)
    80002e30:	6145                	addi	sp,sp,48
    80002e32:	8082                	ret
    return -1;
    80002e34:	54fd                	li	s1,-1
    80002e36:	bfcd                	j	80002e28 <sys_sbrk+0x32>

0000000080002e38 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e38:	7139                	addi	sp,sp,-64
    80002e3a:	fc06                	sd	ra,56(sp)
    80002e3c:	f822                	sd	s0,48(sp)
    80002e3e:	f426                	sd	s1,40(sp)
    80002e40:	f04a                	sd	s2,32(sp)
    80002e42:	ec4e                	sd	s3,24(sp)
    80002e44:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e46:	fcc40593          	addi	a1,s0,-52
    80002e4a:	4501                	li	a0,0
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	e3e080e7          	jalr	-450(ra) # 80002c8a <argint>
  acquire(&tickslock);
    80002e54:	00014517          	auipc	a0,0x14
    80002e58:	b7c50513          	addi	a0,a0,-1156 # 800169d0 <tickslock>
    80002e5c:	ffffe097          	auipc	ra,0xffffe
    80002e60:	d7a080e7          	jalr	-646(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002e64:	00006917          	auipc	s2,0x6
    80002e68:	acc92903          	lw	s2,-1332(s2) # 80008930 <ticks>
  while(ticks - ticks0 < n){
    80002e6c:	fcc42783          	lw	a5,-52(s0)
    80002e70:	cf9d                	beqz	a5,80002eae <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e72:	00014997          	auipc	s3,0x14
    80002e76:	b5e98993          	addi	s3,s3,-1186 # 800169d0 <tickslock>
    80002e7a:	00006497          	auipc	s1,0x6
    80002e7e:	ab648493          	addi	s1,s1,-1354 # 80008930 <ticks>
    if(killed(myproc())){
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	b2a080e7          	jalr	-1238(ra) # 800019ac <myproc>
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	472080e7          	jalr	1138(ra) # 800022fc <killed>
    80002e92:	ed15                	bnez	a0,80002ece <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e94:	85ce                	mv	a1,s3
    80002e96:	8526                	mv	a0,s1
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	1bc080e7          	jalr	444(ra) # 80002054 <sleep>
  while(ticks - ticks0 < n){
    80002ea0:	409c                	lw	a5,0(s1)
    80002ea2:	412787bb          	subw	a5,a5,s2
    80002ea6:	fcc42703          	lw	a4,-52(s0)
    80002eaa:	fce7ece3          	bltu	a5,a4,80002e82 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002eae:	00014517          	auipc	a0,0x14
    80002eb2:	b2250513          	addi	a0,a0,-1246 # 800169d0 <tickslock>
    80002eb6:	ffffe097          	auipc	ra,0xffffe
    80002eba:	dd4080e7          	jalr	-556(ra) # 80000c8a <release>
  return 0;
    80002ebe:	4501                	li	a0,0
}
    80002ec0:	70e2                	ld	ra,56(sp)
    80002ec2:	7442                	ld	s0,48(sp)
    80002ec4:	74a2                	ld	s1,40(sp)
    80002ec6:	7902                	ld	s2,32(sp)
    80002ec8:	69e2                	ld	s3,24(sp)
    80002eca:	6121                	addi	sp,sp,64
    80002ecc:	8082                	ret
      release(&tickslock);
    80002ece:	00014517          	auipc	a0,0x14
    80002ed2:	b0250513          	addi	a0,a0,-1278 # 800169d0 <tickslock>
    80002ed6:	ffffe097          	auipc	ra,0xffffe
    80002eda:	db4080e7          	jalr	-588(ra) # 80000c8a <release>
      return -1;
    80002ede:	557d                	li	a0,-1
    80002ee0:	b7c5                	j	80002ec0 <sys_sleep+0x88>

0000000080002ee2 <sys_kill>:

uint64
sys_kill(void)
{
    80002ee2:	1101                	addi	sp,sp,-32
    80002ee4:	ec06                	sd	ra,24(sp)
    80002ee6:	e822                	sd	s0,16(sp)
    80002ee8:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002eea:	fec40593          	addi	a1,s0,-20
    80002eee:	4501                	li	a0,0
    80002ef0:	00000097          	auipc	ra,0x0
    80002ef4:	d9a080e7          	jalr	-614(ra) # 80002c8a <argint>
  return kill(pid);
    80002ef8:	fec42503          	lw	a0,-20(s0)
    80002efc:	fffff097          	auipc	ra,0xfffff
    80002f00:	362080e7          	jalr	866(ra) # 8000225e <kill>
}
    80002f04:	60e2                	ld	ra,24(sp)
    80002f06:	6442                	ld	s0,16(sp)
    80002f08:	6105                	addi	sp,sp,32
    80002f0a:	8082                	ret

0000000080002f0c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f0c:	1101                	addi	sp,sp,-32
    80002f0e:	ec06                	sd	ra,24(sp)
    80002f10:	e822                	sd	s0,16(sp)
    80002f12:	e426                	sd	s1,8(sp)
    80002f14:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f16:	00014517          	auipc	a0,0x14
    80002f1a:	aba50513          	addi	a0,a0,-1350 # 800169d0 <tickslock>
    80002f1e:	ffffe097          	auipc	ra,0xffffe
    80002f22:	cb8080e7          	jalr	-840(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002f26:	00006497          	auipc	s1,0x6
    80002f2a:	a0a4a483          	lw	s1,-1526(s1) # 80008930 <ticks>
  release(&tickslock);
    80002f2e:	00014517          	auipc	a0,0x14
    80002f32:	aa250513          	addi	a0,a0,-1374 # 800169d0 <tickslock>
    80002f36:	ffffe097          	auipc	ra,0xffffe
    80002f3a:	d54080e7          	jalr	-684(ra) # 80000c8a <release>
  return xticks;
}
    80002f3e:	02049513          	slli	a0,s1,0x20
    80002f42:	9101                	srli	a0,a0,0x20
    80002f44:	60e2                	ld	ra,24(sp)
    80002f46:	6442                	ld	s0,16(sp)
    80002f48:	64a2                	ld	s1,8(sp)
    80002f4a:	6105                	addi	sp,sp,32
    80002f4c:	8082                	ret

0000000080002f4e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f4e:	7179                	addi	sp,sp,-48
    80002f50:	f406                	sd	ra,40(sp)
    80002f52:	f022                	sd	s0,32(sp)
    80002f54:	ec26                	sd	s1,24(sp)
    80002f56:	e84a                	sd	s2,16(sp)
    80002f58:	e44e                	sd	s3,8(sp)
    80002f5a:	e052                	sd	s4,0(sp)
    80002f5c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f5e:	00005597          	auipc	a1,0x5
    80002f62:	5ea58593          	addi	a1,a1,1514 # 80008548 <syscalls+0xb8>
    80002f66:	00014517          	auipc	a0,0x14
    80002f6a:	a8250513          	addi	a0,a0,-1406 # 800169e8 <bcache>
    80002f6e:	ffffe097          	auipc	ra,0xffffe
    80002f72:	bd8080e7          	jalr	-1064(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f76:	0001c797          	auipc	a5,0x1c
    80002f7a:	a7278793          	addi	a5,a5,-1422 # 8001e9e8 <bcache+0x8000>
    80002f7e:	0001c717          	auipc	a4,0x1c
    80002f82:	cd270713          	addi	a4,a4,-814 # 8001ec50 <bcache+0x8268>
    80002f86:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f8a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f8e:	00014497          	auipc	s1,0x14
    80002f92:	a7248493          	addi	s1,s1,-1422 # 80016a00 <bcache+0x18>
    b->next = bcache.head.next;
    80002f96:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f98:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f9a:	00005a17          	auipc	s4,0x5
    80002f9e:	5b6a0a13          	addi	s4,s4,1462 # 80008550 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002fa2:	2b893783          	ld	a5,696(s2)
    80002fa6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fa8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fac:	85d2                	mv	a1,s4
    80002fae:	01048513          	addi	a0,s1,16
    80002fb2:	00001097          	auipc	ra,0x1
    80002fb6:	4c8080e7          	jalr	1224(ra) # 8000447a <initsleeplock>
    bcache.head.next->prev = b;
    80002fba:	2b893783          	ld	a5,696(s2)
    80002fbe:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fc0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fc4:	45848493          	addi	s1,s1,1112
    80002fc8:	fd349de3          	bne	s1,s3,80002fa2 <binit+0x54>
  }
}
    80002fcc:	70a2                	ld	ra,40(sp)
    80002fce:	7402                	ld	s0,32(sp)
    80002fd0:	64e2                	ld	s1,24(sp)
    80002fd2:	6942                	ld	s2,16(sp)
    80002fd4:	69a2                	ld	s3,8(sp)
    80002fd6:	6a02                	ld	s4,0(sp)
    80002fd8:	6145                	addi	sp,sp,48
    80002fda:	8082                	ret

0000000080002fdc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fdc:	7179                	addi	sp,sp,-48
    80002fde:	f406                	sd	ra,40(sp)
    80002fe0:	f022                	sd	s0,32(sp)
    80002fe2:	ec26                	sd	s1,24(sp)
    80002fe4:	e84a                	sd	s2,16(sp)
    80002fe6:	e44e                	sd	s3,8(sp)
    80002fe8:	1800                	addi	s0,sp,48
    80002fea:	892a                	mv	s2,a0
    80002fec:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002fee:	00014517          	auipc	a0,0x14
    80002ff2:	9fa50513          	addi	a0,a0,-1542 # 800169e8 <bcache>
    80002ff6:	ffffe097          	auipc	ra,0xffffe
    80002ffa:	be0080e7          	jalr	-1056(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ffe:	0001c497          	auipc	s1,0x1c
    80003002:	ca24b483          	ld	s1,-862(s1) # 8001eca0 <bcache+0x82b8>
    80003006:	0001c797          	auipc	a5,0x1c
    8000300a:	c4a78793          	addi	a5,a5,-950 # 8001ec50 <bcache+0x8268>
    8000300e:	02f48f63          	beq	s1,a5,8000304c <bread+0x70>
    80003012:	873e                	mv	a4,a5
    80003014:	a021                	j	8000301c <bread+0x40>
    80003016:	68a4                	ld	s1,80(s1)
    80003018:	02e48a63          	beq	s1,a4,8000304c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000301c:	449c                	lw	a5,8(s1)
    8000301e:	ff279ce3          	bne	a5,s2,80003016 <bread+0x3a>
    80003022:	44dc                	lw	a5,12(s1)
    80003024:	ff3799e3          	bne	a5,s3,80003016 <bread+0x3a>
      b->refcnt++;
    80003028:	40bc                	lw	a5,64(s1)
    8000302a:	2785                	addiw	a5,a5,1
    8000302c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000302e:	00014517          	auipc	a0,0x14
    80003032:	9ba50513          	addi	a0,a0,-1606 # 800169e8 <bcache>
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	c54080e7          	jalr	-940(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000303e:	01048513          	addi	a0,s1,16
    80003042:	00001097          	auipc	ra,0x1
    80003046:	472080e7          	jalr	1138(ra) # 800044b4 <acquiresleep>
      return b;
    8000304a:	a8b9                	j	800030a8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000304c:	0001c497          	auipc	s1,0x1c
    80003050:	c4c4b483          	ld	s1,-948(s1) # 8001ec98 <bcache+0x82b0>
    80003054:	0001c797          	auipc	a5,0x1c
    80003058:	bfc78793          	addi	a5,a5,-1028 # 8001ec50 <bcache+0x8268>
    8000305c:	00f48863          	beq	s1,a5,8000306c <bread+0x90>
    80003060:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003062:	40bc                	lw	a5,64(s1)
    80003064:	cf81                	beqz	a5,8000307c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003066:	64a4                	ld	s1,72(s1)
    80003068:	fee49de3          	bne	s1,a4,80003062 <bread+0x86>
  panic("bget: no buffers");
    8000306c:	00005517          	auipc	a0,0x5
    80003070:	4ec50513          	addi	a0,a0,1260 # 80008558 <syscalls+0xc8>
    80003074:	ffffd097          	auipc	ra,0xffffd
    80003078:	4cc080e7          	jalr	1228(ra) # 80000540 <panic>
      b->dev = dev;
    8000307c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003080:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003084:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003088:	4785                	li	a5,1
    8000308a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000308c:	00014517          	auipc	a0,0x14
    80003090:	95c50513          	addi	a0,a0,-1700 # 800169e8 <bcache>
    80003094:	ffffe097          	auipc	ra,0xffffe
    80003098:	bf6080e7          	jalr	-1034(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000309c:	01048513          	addi	a0,s1,16
    800030a0:	00001097          	auipc	ra,0x1
    800030a4:	414080e7          	jalr	1044(ra) # 800044b4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030a8:	409c                	lw	a5,0(s1)
    800030aa:	cb89                	beqz	a5,800030bc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030ac:	8526                	mv	a0,s1
    800030ae:	70a2                	ld	ra,40(sp)
    800030b0:	7402                	ld	s0,32(sp)
    800030b2:	64e2                	ld	s1,24(sp)
    800030b4:	6942                	ld	s2,16(sp)
    800030b6:	69a2                	ld	s3,8(sp)
    800030b8:	6145                	addi	sp,sp,48
    800030ba:	8082                	ret
    virtio_disk_rw(b, 0);
    800030bc:	4581                	li	a1,0
    800030be:	8526                	mv	a0,s1
    800030c0:	00003097          	auipc	ra,0x3
    800030c4:	fe2080e7          	jalr	-30(ra) # 800060a2 <virtio_disk_rw>
    b->valid = 1;
    800030c8:	4785                	li	a5,1
    800030ca:	c09c                	sw	a5,0(s1)
  return b;
    800030cc:	b7c5                	j	800030ac <bread+0xd0>

00000000800030ce <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030ce:	1101                	addi	sp,sp,-32
    800030d0:	ec06                	sd	ra,24(sp)
    800030d2:	e822                	sd	s0,16(sp)
    800030d4:	e426                	sd	s1,8(sp)
    800030d6:	1000                	addi	s0,sp,32
    800030d8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030da:	0541                	addi	a0,a0,16
    800030dc:	00001097          	auipc	ra,0x1
    800030e0:	472080e7          	jalr	1138(ra) # 8000454e <holdingsleep>
    800030e4:	cd01                	beqz	a0,800030fc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030e6:	4585                	li	a1,1
    800030e8:	8526                	mv	a0,s1
    800030ea:	00003097          	auipc	ra,0x3
    800030ee:	fb8080e7          	jalr	-72(ra) # 800060a2 <virtio_disk_rw>
}
    800030f2:	60e2                	ld	ra,24(sp)
    800030f4:	6442                	ld	s0,16(sp)
    800030f6:	64a2                	ld	s1,8(sp)
    800030f8:	6105                	addi	sp,sp,32
    800030fa:	8082                	ret
    panic("bwrite");
    800030fc:	00005517          	auipc	a0,0x5
    80003100:	47450513          	addi	a0,a0,1140 # 80008570 <syscalls+0xe0>
    80003104:	ffffd097          	auipc	ra,0xffffd
    80003108:	43c080e7          	jalr	1084(ra) # 80000540 <panic>

000000008000310c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000310c:	1101                	addi	sp,sp,-32
    8000310e:	ec06                	sd	ra,24(sp)
    80003110:	e822                	sd	s0,16(sp)
    80003112:	e426                	sd	s1,8(sp)
    80003114:	e04a                	sd	s2,0(sp)
    80003116:	1000                	addi	s0,sp,32
    80003118:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000311a:	01050913          	addi	s2,a0,16
    8000311e:	854a                	mv	a0,s2
    80003120:	00001097          	auipc	ra,0x1
    80003124:	42e080e7          	jalr	1070(ra) # 8000454e <holdingsleep>
    80003128:	c92d                	beqz	a0,8000319a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000312a:	854a                	mv	a0,s2
    8000312c:	00001097          	auipc	ra,0x1
    80003130:	3de080e7          	jalr	990(ra) # 8000450a <releasesleep>

  acquire(&bcache.lock);
    80003134:	00014517          	auipc	a0,0x14
    80003138:	8b450513          	addi	a0,a0,-1868 # 800169e8 <bcache>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	a9a080e7          	jalr	-1382(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003144:	40bc                	lw	a5,64(s1)
    80003146:	37fd                	addiw	a5,a5,-1
    80003148:	0007871b          	sext.w	a4,a5
    8000314c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000314e:	eb05                	bnez	a4,8000317e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003150:	68bc                	ld	a5,80(s1)
    80003152:	64b8                	ld	a4,72(s1)
    80003154:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003156:	64bc                	ld	a5,72(s1)
    80003158:	68b8                	ld	a4,80(s1)
    8000315a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000315c:	0001c797          	auipc	a5,0x1c
    80003160:	88c78793          	addi	a5,a5,-1908 # 8001e9e8 <bcache+0x8000>
    80003164:	2b87b703          	ld	a4,696(a5)
    80003168:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000316a:	0001c717          	auipc	a4,0x1c
    8000316e:	ae670713          	addi	a4,a4,-1306 # 8001ec50 <bcache+0x8268>
    80003172:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003174:	2b87b703          	ld	a4,696(a5)
    80003178:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000317a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000317e:	00014517          	auipc	a0,0x14
    80003182:	86a50513          	addi	a0,a0,-1942 # 800169e8 <bcache>
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	b04080e7          	jalr	-1276(ra) # 80000c8a <release>
}
    8000318e:	60e2                	ld	ra,24(sp)
    80003190:	6442                	ld	s0,16(sp)
    80003192:	64a2                	ld	s1,8(sp)
    80003194:	6902                	ld	s2,0(sp)
    80003196:	6105                	addi	sp,sp,32
    80003198:	8082                	ret
    panic("brelse");
    8000319a:	00005517          	auipc	a0,0x5
    8000319e:	3de50513          	addi	a0,a0,990 # 80008578 <syscalls+0xe8>
    800031a2:	ffffd097          	auipc	ra,0xffffd
    800031a6:	39e080e7          	jalr	926(ra) # 80000540 <panic>

00000000800031aa <bpin>:

void
bpin(struct buf *b) {
    800031aa:	1101                	addi	sp,sp,-32
    800031ac:	ec06                	sd	ra,24(sp)
    800031ae:	e822                	sd	s0,16(sp)
    800031b0:	e426                	sd	s1,8(sp)
    800031b2:	1000                	addi	s0,sp,32
    800031b4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031b6:	00014517          	auipc	a0,0x14
    800031ba:	83250513          	addi	a0,a0,-1998 # 800169e8 <bcache>
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	a18080e7          	jalr	-1512(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800031c6:	40bc                	lw	a5,64(s1)
    800031c8:	2785                	addiw	a5,a5,1
    800031ca:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031cc:	00014517          	auipc	a0,0x14
    800031d0:	81c50513          	addi	a0,a0,-2020 # 800169e8 <bcache>
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	ab6080e7          	jalr	-1354(ra) # 80000c8a <release>
}
    800031dc:	60e2                	ld	ra,24(sp)
    800031de:	6442                	ld	s0,16(sp)
    800031e0:	64a2                	ld	s1,8(sp)
    800031e2:	6105                	addi	sp,sp,32
    800031e4:	8082                	ret

00000000800031e6 <bunpin>:

void
bunpin(struct buf *b) {
    800031e6:	1101                	addi	sp,sp,-32
    800031e8:	ec06                	sd	ra,24(sp)
    800031ea:	e822                	sd	s0,16(sp)
    800031ec:	e426                	sd	s1,8(sp)
    800031ee:	1000                	addi	s0,sp,32
    800031f0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031f2:	00013517          	auipc	a0,0x13
    800031f6:	7f650513          	addi	a0,a0,2038 # 800169e8 <bcache>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	9dc080e7          	jalr	-1572(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003202:	40bc                	lw	a5,64(s1)
    80003204:	37fd                	addiw	a5,a5,-1
    80003206:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003208:	00013517          	auipc	a0,0x13
    8000320c:	7e050513          	addi	a0,a0,2016 # 800169e8 <bcache>
    80003210:	ffffe097          	auipc	ra,0xffffe
    80003214:	a7a080e7          	jalr	-1414(ra) # 80000c8a <release>
}
    80003218:	60e2                	ld	ra,24(sp)
    8000321a:	6442                	ld	s0,16(sp)
    8000321c:	64a2                	ld	s1,8(sp)
    8000321e:	6105                	addi	sp,sp,32
    80003220:	8082                	ret

0000000080003222 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003222:	1101                	addi	sp,sp,-32
    80003224:	ec06                	sd	ra,24(sp)
    80003226:	e822                	sd	s0,16(sp)
    80003228:	e426                	sd	s1,8(sp)
    8000322a:	e04a                	sd	s2,0(sp)
    8000322c:	1000                	addi	s0,sp,32
    8000322e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003230:	00d5d59b          	srliw	a1,a1,0xd
    80003234:	0001c797          	auipc	a5,0x1c
    80003238:	e907a783          	lw	a5,-368(a5) # 8001f0c4 <sb+0x1c>
    8000323c:	9dbd                	addw	a1,a1,a5
    8000323e:	00000097          	auipc	ra,0x0
    80003242:	d9e080e7          	jalr	-610(ra) # 80002fdc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003246:	0074f713          	andi	a4,s1,7
    8000324a:	4785                	li	a5,1
    8000324c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003250:	14ce                	slli	s1,s1,0x33
    80003252:	90d9                	srli	s1,s1,0x36
    80003254:	00950733          	add	a4,a0,s1
    80003258:	05874703          	lbu	a4,88(a4)
    8000325c:	00e7f6b3          	and	a3,a5,a4
    80003260:	c69d                	beqz	a3,8000328e <bfree+0x6c>
    80003262:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003264:	94aa                	add	s1,s1,a0
    80003266:	fff7c793          	not	a5,a5
    8000326a:	8f7d                	and	a4,a4,a5
    8000326c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003270:	00001097          	auipc	ra,0x1
    80003274:	126080e7          	jalr	294(ra) # 80004396 <log_write>
  brelse(bp);
    80003278:	854a                	mv	a0,s2
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	e92080e7          	jalr	-366(ra) # 8000310c <brelse>
}
    80003282:	60e2                	ld	ra,24(sp)
    80003284:	6442                	ld	s0,16(sp)
    80003286:	64a2                	ld	s1,8(sp)
    80003288:	6902                	ld	s2,0(sp)
    8000328a:	6105                	addi	sp,sp,32
    8000328c:	8082                	ret
    panic("freeing free block");
    8000328e:	00005517          	auipc	a0,0x5
    80003292:	2f250513          	addi	a0,a0,754 # 80008580 <syscalls+0xf0>
    80003296:	ffffd097          	auipc	ra,0xffffd
    8000329a:	2aa080e7          	jalr	682(ra) # 80000540 <panic>

000000008000329e <balloc>:
{
    8000329e:	711d                	addi	sp,sp,-96
    800032a0:	ec86                	sd	ra,88(sp)
    800032a2:	e8a2                	sd	s0,80(sp)
    800032a4:	e4a6                	sd	s1,72(sp)
    800032a6:	e0ca                	sd	s2,64(sp)
    800032a8:	fc4e                	sd	s3,56(sp)
    800032aa:	f852                	sd	s4,48(sp)
    800032ac:	f456                	sd	s5,40(sp)
    800032ae:	f05a                	sd	s6,32(sp)
    800032b0:	ec5e                	sd	s7,24(sp)
    800032b2:	e862                	sd	s8,16(sp)
    800032b4:	e466                	sd	s9,8(sp)
    800032b6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032b8:	0001c797          	auipc	a5,0x1c
    800032bc:	df47a783          	lw	a5,-524(a5) # 8001f0ac <sb+0x4>
    800032c0:	cff5                	beqz	a5,800033bc <balloc+0x11e>
    800032c2:	8baa                	mv	s7,a0
    800032c4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032c6:	0001cb17          	auipc	s6,0x1c
    800032ca:	de2b0b13          	addi	s6,s6,-542 # 8001f0a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ce:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032d0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032d4:	6c89                	lui	s9,0x2
    800032d6:	a061                	j	8000335e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032d8:	97ca                	add	a5,a5,s2
    800032da:	8e55                	or	a2,a2,a3
    800032dc:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800032e0:	854a                	mv	a0,s2
    800032e2:	00001097          	auipc	ra,0x1
    800032e6:	0b4080e7          	jalr	180(ra) # 80004396 <log_write>
        brelse(bp);
    800032ea:	854a                	mv	a0,s2
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	e20080e7          	jalr	-480(ra) # 8000310c <brelse>
  bp = bread(dev, bno);
    800032f4:	85a6                	mv	a1,s1
    800032f6:	855e                	mv	a0,s7
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	ce4080e7          	jalr	-796(ra) # 80002fdc <bread>
    80003300:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003302:	40000613          	li	a2,1024
    80003306:	4581                	li	a1,0
    80003308:	05850513          	addi	a0,a0,88
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	9c6080e7          	jalr	-1594(ra) # 80000cd2 <memset>
  log_write(bp);
    80003314:	854a                	mv	a0,s2
    80003316:	00001097          	auipc	ra,0x1
    8000331a:	080080e7          	jalr	128(ra) # 80004396 <log_write>
  brelse(bp);
    8000331e:	854a                	mv	a0,s2
    80003320:	00000097          	auipc	ra,0x0
    80003324:	dec080e7          	jalr	-532(ra) # 8000310c <brelse>
}
    80003328:	8526                	mv	a0,s1
    8000332a:	60e6                	ld	ra,88(sp)
    8000332c:	6446                	ld	s0,80(sp)
    8000332e:	64a6                	ld	s1,72(sp)
    80003330:	6906                	ld	s2,64(sp)
    80003332:	79e2                	ld	s3,56(sp)
    80003334:	7a42                	ld	s4,48(sp)
    80003336:	7aa2                	ld	s5,40(sp)
    80003338:	7b02                	ld	s6,32(sp)
    8000333a:	6be2                	ld	s7,24(sp)
    8000333c:	6c42                	ld	s8,16(sp)
    8000333e:	6ca2                	ld	s9,8(sp)
    80003340:	6125                	addi	sp,sp,96
    80003342:	8082                	ret
    brelse(bp);
    80003344:	854a                	mv	a0,s2
    80003346:	00000097          	auipc	ra,0x0
    8000334a:	dc6080e7          	jalr	-570(ra) # 8000310c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000334e:	015c87bb          	addw	a5,s9,s5
    80003352:	00078a9b          	sext.w	s5,a5
    80003356:	004b2703          	lw	a4,4(s6)
    8000335a:	06eaf163          	bgeu	s5,a4,800033bc <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000335e:	41fad79b          	sraiw	a5,s5,0x1f
    80003362:	0137d79b          	srliw	a5,a5,0x13
    80003366:	015787bb          	addw	a5,a5,s5
    8000336a:	40d7d79b          	sraiw	a5,a5,0xd
    8000336e:	01cb2583          	lw	a1,28(s6)
    80003372:	9dbd                	addw	a1,a1,a5
    80003374:	855e                	mv	a0,s7
    80003376:	00000097          	auipc	ra,0x0
    8000337a:	c66080e7          	jalr	-922(ra) # 80002fdc <bread>
    8000337e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003380:	004b2503          	lw	a0,4(s6)
    80003384:	000a849b          	sext.w	s1,s5
    80003388:	8762                	mv	a4,s8
    8000338a:	faa4fde3          	bgeu	s1,a0,80003344 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000338e:	00777693          	andi	a3,a4,7
    80003392:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003396:	41f7579b          	sraiw	a5,a4,0x1f
    8000339a:	01d7d79b          	srliw	a5,a5,0x1d
    8000339e:	9fb9                	addw	a5,a5,a4
    800033a0:	4037d79b          	sraiw	a5,a5,0x3
    800033a4:	00f90633          	add	a2,s2,a5
    800033a8:	05864603          	lbu	a2,88(a2)
    800033ac:	00c6f5b3          	and	a1,a3,a2
    800033b0:	d585                	beqz	a1,800032d8 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b2:	2705                	addiw	a4,a4,1
    800033b4:	2485                	addiw	s1,s1,1
    800033b6:	fd471ae3          	bne	a4,s4,8000338a <balloc+0xec>
    800033ba:	b769                	j	80003344 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800033bc:	00005517          	auipc	a0,0x5
    800033c0:	1dc50513          	addi	a0,a0,476 # 80008598 <syscalls+0x108>
    800033c4:	ffffd097          	auipc	ra,0xffffd
    800033c8:	1c6080e7          	jalr	454(ra) # 8000058a <printf>
  return 0;
    800033cc:	4481                	li	s1,0
    800033ce:	bfa9                	j	80003328 <balloc+0x8a>

00000000800033d0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800033d0:	7179                	addi	sp,sp,-48
    800033d2:	f406                	sd	ra,40(sp)
    800033d4:	f022                	sd	s0,32(sp)
    800033d6:	ec26                	sd	s1,24(sp)
    800033d8:	e84a                	sd	s2,16(sp)
    800033da:	e44e                	sd	s3,8(sp)
    800033dc:	e052                	sd	s4,0(sp)
    800033de:	1800                	addi	s0,sp,48
    800033e0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033e2:	47ad                	li	a5,11
    800033e4:	02b7e863          	bltu	a5,a1,80003414 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800033e8:	02059793          	slli	a5,a1,0x20
    800033ec:	01e7d593          	srli	a1,a5,0x1e
    800033f0:	00b504b3          	add	s1,a0,a1
    800033f4:	0504a903          	lw	s2,80(s1)
    800033f8:	06091e63          	bnez	s2,80003474 <bmap+0xa4>
      addr = balloc(ip->dev);
    800033fc:	4108                	lw	a0,0(a0)
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	ea0080e7          	jalr	-352(ra) # 8000329e <balloc>
    80003406:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000340a:	06090563          	beqz	s2,80003474 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000340e:	0524a823          	sw	s2,80(s1)
    80003412:	a08d                	j	80003474 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003414:	ff45849b          	addiw	s1,a1,-12
    80003418:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000341c:	0ff00793          	li	a5,255
    80003420:	08e7e563          	bltu	a5,a4,800034aa <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003424:	08052903          	lw	s2,128(a0)
    80003428:	00091d63          	bnez	s2,80003442 <bmap+0x72>
      addr = balloc(ip->dev);
    8000342c:	4108                	lw	a0,0(a0)
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	e70080e7          	jalr	-400(ra) # 8000329e <balloc>
    80003436:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000343a:	02090d63          	beqz	s2,80003474 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000343e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003442:	85ca                	mv	a1,s2
    80003444:	0009a503          	lw	a0,0(s3)
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	b94080e7          	jalr	-1132(ra) # 80002fdc <bread>
    80003450:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003452:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003456:	02049713          	slli	a4,s1,0x20
    8000345a:	01e75593          	srli	a1,a4,0x1e
    8000345e:	00b784b3          	add	s1,a5,a1
    80003462:	0004a903          	lw	s2,0(s1)
    80003466:	02090063          	beqz	s2,80003486 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000346a:	8552                	mv	a0,s4
    8000346c:	00000097          	auipc	ra,0x0
    80003470:	ca0080e7          	jalr	-864(ra) # 8000310c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003474:	854a                	mv	a0,s2
    80003476:	70a2                	ld	ra,40(sp)
    80003478:	7402                	ld	s0,32(sp)
    8000347a:	64e2                	ld	s1,24(sp)
    8000347c:	6942                	ld	s2,16(sp)
    8000347e:	69a2                	ld	s3,8(sp)
    80003480:	6a02                	ld	s4,0(sp)
    80003482:	6145                	addi	sp,sp,48
    80003484:	8082                	ret
      addr = balloc(ip->dev);
    80003486:	0009a503          	lw	a0,0(s3)
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	e14080e7          	jalr	-492(ra) # 8000329e <balloc>
    80003492:	0005091b          	sext.w	s2,a0
      if(addr){
    80003496:	fc090ae3          	beqz	s2,8000346a <bmap+0x9a>
        a[bn] = addr;
    8000349a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000349e:	8552                	mv	a0,s4
    800034a0:	00001097          	auipc	ra,0x1
    800034a4:	ef6080e7          	jalr	-266(ra) # 80004396 <log_write>
    800034a8:	b7c9                	j	8000346a <bmap+0x9a>
  panic("bmap: out of range");
    800034aa:	00005517          	auipc	a0,0x5
    800034ae:	10650513          	addi	a0,a0,262 # 800085b0 <syscalls+0x120>
    800034b2:	ffffd097          	auipc	ra,0xffffd
    800034b6:	08e080e7          	jalr	142(ra) # 80000540 <panic>

00000000800034ba <iget>:
{
    800034ba:	7179                	addi	sp,sp,-48
    800034bc:	f406                	sd	ra,40(sp)
    800034be:	f022                	sd	s0,32(sp)
    800034c0:	ec26                	sd	s1,24(sp)
    800034c2:	e84a                	sd	s2,16(sp)
    800034c4:	e44e                	sd	s3,8(sp)
    800034c6:	e052                	sd	s4,0(sp)
    800034c8:	1800                	addi	s0,sp,48
    800034ca:	89aa                	mv	s3,a0
    800034cc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034ce:	0001c517          	auipc	a0,0x1c
    800034d2:	bfa50513          	addi	a0,a0,-1030 # 8001f0c8 <itable>
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	700080e7          	jalr	1792(ra) # 80000bd6 <acquire>
  empty = 0;
    800034de:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034e0:	0001c497          	auipc	s1,0x1c
    800034e4:	c0048493          	addi	s1,s1,-1024 # 8001f0e0 <itable+0x18>
    800034e8:	0001d697          	auipc	a3,0x1d
    800034ec:	68868693          	addi	a3,a3,1672 # 80020b70 <log>
    800034f0:	a039                	j	800034fe <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034f2:	02090b63          	beqz	s2,80003528 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034f6:	08848493          	addi	s1,s1,136
    800034fa:	02d48a63          	beq	s1,a3,8000352e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034fe:	449c                	lw	a5,8(s1)
    80003500:	fef059e3          	blez	a5,800034f2 <iget+0x38>
    80003504:	4098                	lw	a4,0(s1)
    80003506:	ff3716e3          	bne	a4,s3,800034f2 <iget+0x38>
    8000350a:	40d8                	lw	a4,4(s1)
    8000350c:	ff4713e3          	bne	a4,s4,800034f2 <iget+0x38>
      ip->ref++;
    80003510:	2785                	addiw	a5,a5,1
    80003512:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003514:	0001c517          	auipc	a0,0x1c
    80003518:	bb450513          	addi	a0,a0,-1100 # 8001f0c8 <itable>
    8000351c:	ffffd097          	auipc	ra,0xffffd
    80003520:	76e080e7          	jalr	1902(ra) # 80000c8a <release>
      return ip;
    80003524:	8926                	mv	s2,s1
    80003526:	a03d                	j	80003554 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003528:	f7f9                	bnez	a5,800034f6 <iget+0x3c>
    8000352a:	8926                	mv	s2,s1
    8000352c:	b7e9                	j	800034f6 <iget+0x3c>
  if(empty == 0)
    8000352e:	02090c63          	beqz	s2,80003566 <iget+0xac>
  ip->dev = dev;
    80003532:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003536:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000353a:	4785                	li	a5,1
    8000353c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003540:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003544:	0001c517          	auipc	a0,0x1c
    80003548:	b8450513          	addi	a0,a0,-1148 # 8001f0c8 <itable>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	73e080e7          	jalr	1854(ra) # 80000c8a <release>
}
    80003554:	854a                	mv	a0,s2
    80003556:	70a2                	ld	ra,40(sp)
    80003558:	7402                	ld	s0,32(sp)
    8000355a:	64e2                	ld	s1,24(sp)
    8000355c:	6942                	ld	s2,16(sp)
    8000355e:	69a2                	ld	s3,8(sp)
    80003560:	6a02                	ld	s4,0(sp)
    80003562:	6145                	addi	sp,sp,48
    80003564:	8082                	ret
    panic("iget: no inodes");
    80003566:	00005517          	auipc	a0,0x5
    8000356a:	06250513          	addi	a0,a0,98 # 800085c8 <syscalls+0x138>
    8000356e:	ffffd097          	auipc	ra,0xffffd
    80003572:	fd2080e7          	jalr	-46(ra) # 80000540 <panic>

0000000080003576 <fsinit>:
fsinit(int dev) {
    80003576:	7179                	addi	sp,sp,-48
    80003578:	f406                	sd	ra,40(sp)
    8000357a:	f022                	sd	s0,32(sp)
    8000357c:	ec26                	sd	s1,24(sp)
    8000357e:	e84a                	sd	s2,16(sp)
    80003580:	e44e                	sd	s3,8(sp)
    80003582:	1800                	addi	s0,sp,48
    80003584:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003586:	4585                	li	a1,1
    80003588:	00000097          	auipc	ra,0x0
    8000358c:	a54080e7          	jalr	-1452(ra) # 80002fdc <bread>
    80003590:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003592:	0001c997          	auipc	s3,0x1c
    80003596:	b1698993          	addi	s3,s3,-1258 # 8001f0a8 <sb>
    8000359a:	02000613          	li	a2,32
    8000359e:	05850593          	addi	a1,a0,88
    800035a2:	854e                	mv	a0,s3
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	78a080e7          	jalr	1930(ra) # 80000d2e <memmove>
  brelse(bp);
    800035ac:	8526                	mv	a0,s1
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	b5e080e7          	jalr	-1186(ra) # 8000310c <brelse>
  if(sb.magic != FSMAGIC)
    800035b6:	0009a703          	lw	a4,0(s3)
    800035ba:	102037b7          	lui	a5,0x10203
    800035be:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035c2:	02f71263          	bne	a4,a5,800035e6 <fsinit+0x70>
  initlog(dev, &sb);
    800035c6:	0001c597          	auipc	a1,0x1c
    800035ca:	ae258593          	addi	a1,a1,-1310 # 8001f0a8 <sb>
    800035ce:	854a                	mv	a0,s2
    800035d0:	00001097          	auipc	ra,0x1
    800035d4:	b4a080e7          	jalr	-1206(ra) # 8000411a <initlog>
}
    800035d8:	70a2                	ld	ra,40(sp)
    800035da:	7402                	ld	s0,32(sp)
    800035dc:	64e2                	ld	s1,24(sp)
    800035de:	6942                	ld	s2,16(sp)
    800035e0:	69a2                	ld	s3,8(sp)
    800035e2:	6145                	addi	sp,sp,48
    800035e4:	8082                	ret
    panic("invalid file system");
    800035e6:	00005517          	auipc	a0,0x5
    800035ea:	ff250513          	addi	a0,a0,-14 # 800085d8 <syscalls+0x148>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	f52080e7          	jalr	-174(ra) # 80000540 <panic>

00000000800035f6 <iinit>:
{
    800035f6:	7179                	addi	sp,sp,-48
    800035f8:	f406                	sd	ra,40(sp)
    800035fa:	f022                	sd	s0,32(sp)
    800035fc:	ec26                	sd	s1,24(sp)
    800035fe:	e84a                	sd	s2,16(sp)
    80003600:	e44e                	sd	s3,8(sp)
    80003602:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003604:	00005597          	auipc	a1,0x5
    80003608:	fec58593          	addi	a1,a1,-20 # 800085f0 <syscalls+0x160>
    8000360c:	0001c517          	auipc	a0,0x1c
    80003610:	abc50513          	addi	a0,a0,-1348 # 8001f0c8 <itable>
    80003614:	ffffd097          	auipc	ra,0xffffd
    80003618:	532080e7          	jalr	1330(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000361c:	0001c497          	auipc	s1,0x1c
    80003620:	ad448493          	addi	s1,s1,-1324 # 8001f0f0 <itable+0x28>
    80003624:	0001d997          	auipc	s3,0x1d
    80003628:	55c98993          	addi	s3,s3,1372 # 80020b80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000362c:	00005917          	auipc	s2,0x5
    80003630:	fcc90913          	addi	s2,s2,-52 # 800085f8 <syscalls+0x168>
    80003634:	85ca                	mv	a1,s2
    80003636:	8526                	mv	a0,s1
    80003638:	00001097          	auipc	ra,0x1
    8000363c:	e42080e7          	jalr	-446(ra) # 8000447a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003640:	08848493          	addi	s1,s1,136
    80003644:	ff3498e3          	bne	s1,s3,80003634 <iinit+0x3e>
}
    80003648:	70a2                	ld	ra,40(sp)
    8000364a:	7402                	ld	s0,32(sp)
    8000364c:	64e2                	ld	s1,24(sp)
    8000364e:	6942                	ld	s2,16(sp)
    80003650:	69a2                	ld	s3,8(sp)
    80003652:	6145                	addi	sp,sp,48
    80003654:	8082                	ret

0000000080003656 <ialloc>:
{
    80003656:	715d                	addi	sp,sp,-80
    80003658:	e486                	sd	ra,72(sp)
    8000365a:	e0a2                	sd	s0,64(sp)
    8000365c:	fc26                	sd	s1,56(sp)
    8000365e:	f84a                	sd	s2,48(sp)
    80003660:	f44e                	sd	s3,40(sp)
    80003662:	f052                	sd	s4,32(sp)
    80003664:	ec56                	sd	s5,24(sp)
    80003666:	e85a                	sd	s6,16(sp)
    80003668:	e45e                	sd	s7,8(sp)
    8000366a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000366c:	0001c717          	auipc	a4,0x1c
    80003670:	a4872703          	lw	a4,-1464(a4) # 8001f0b4 <sb+0xc>
    80003674:	4785                	li	a5,1
    80003676:	04e7fa63          	bgeu	a5,a4,800036ca <ialloc+0x74>
    8000367a:	8aaa                	mv	s5,a0
    8000367c:	8bae                	mv	s7,a1
    8000367e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003680:	0001ca17          	auipc	s4,0x1c
    80003684:	a28a0a13          	addi	s4,s4,-1496 # 8001f0a8 <sb>
    80003688:	00048b1b          	sext.w	s6,s1
    8000368c:	0044d593          	srli	a1,s1,0x4
    80003690:	018a2783          	lw	a5,24(s4)
    80003694:	9dbd                	addw	a1,a1,a5
    80003696:	8556                	mv	a0,s5
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	944080e7          	jalr	-1724(ra) # 80002fdc <bread>
    800036a0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036a2:	05850993          	addi	s3,a0,88
    800036a6:	00f4f793          	andi	a5,s1,15
    800036aa:	079a                	slli	a5,a5,0x6
    800036ac:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036ae:	00099783          	lh	a5,0(s3)
    800036b2:	c3a1                	beqz	a5,800036f2 <ialloc+0x9c>
    brelse(bp);
    800036b4:	00000097          	auipc	ra,0x0
    800036b8:	a58080e7          	jalr	-1448(ra) # 8000310c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036bc:	0485                	addi	s1,s1,1
    800036be:	00ca2703          	lw	a4,12(s4)
    800036c2:	0004879b          	sext.w	a5,s1
    800036c6:	fce7e1e3          	bltu	a5,a4,80003688 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800036ca:	00005517          	auipc	a0,0x5
    800036ce:	f3650513          	addi	a0,a0,-202 # 80008600 <syscalls+0x170>
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	eb8080e7          	jalr	-328(ra) # 8000058a <printf>
  return 0;
    800036da:	4501                	li	a0,0
}
    800036dc:	60a6                	ld	ra,72(sp)
    800036de:	6406                	ld	s0,64(sp)
    800036e0:	74e2                	ld	s1,56(sp)
    800036e2:	7942                	ld	s2,48(sp)
    800036e4:	79a2                	ld	s3,40(sp)
    800036e6:	7a02                	ld	s4,32(sp)
    800036e8:	6ae2                	ld	s5,24(sp)
    800036ea:	6b42                	ld	s6,16(sp)
    800036ec:	6ba2                	ld	s7,8(sp)
    800036ee:	6161                	addi	sp,sp,80
    800036f0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036f2:	04000613          	li	a2,64
    800036f6:	4581                	li	a1,0
    800036f8:	854e                	mv	a0,s3
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	5d8080e7          	jalr	1496(ra) # 80000cd2 <memset>
      dip->type = type;
    80003702:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003706:	854a                	mv	a0,s2
    80003708:	00001097          	auipc	ra,0x1
    8000370c:	c8e080e7          	jalr	-882(ra) # 80004396 <log_write>
      brelse(bp);
    80003710:	854a                	mv	a0,s2
    80003712:	00000097          	auipc	ra,0x0
    80003716:	9fa080e7          	jalr	-1542(ra) # 8000310c <brelse>
      return iget(dev, inum);
    8000371a:	85da                	mv	a1,s6
    8000371c:	8556                	mv	a0,s5
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	d9c080e7          	jalr	-612(ra) # 800034ba <iget>
    80003726:	bf5d                	j	800036dc <ialloc+0x86>

0000000080003728 <iupdate>:
{
    80003728:	1101                	addi	sp,sp,-32
    8000372a:	ec06                	sd	ra,24(sp)
    8000372c:	e822                	sd	s0,16(sp)
    8000372e:	e426                	sd	s1,8(sp)
    80003730:	e04a                	sd	s2,0(sp)
    80003732:	1000                	addi	s0,sp,32
    80003734:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003736:	415c                	lw	a5,4(a0)
    80003738:	0047d79b          	srliw	a5,a5,0x4
    8000373c:	0001c597          	auipc	a1,0x1c
    80003740:	9845a583          	lw	a1,-1660(a1) # 8001f0c0 <sb+0x18>
    80003744:	9dbd                	addw	a1,a1,a5
    80003746:	4108                	lw	a0,0(a0)
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	894080e7          	jalr	-1900(ra) # 80002fdc <bread>
    80003750:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003752:	05850793          	addi	a5,a0,88
    80003756:	40d8                	lw	a4,4(s1)
    80003758:	8b3d                	andi	a4,a4,15
    8000375a:	071a                	slli	a4,a4,0x6
    8000375c:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000375e:	04449703          	lh	a4,68(s1)
    80003762:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003766:	04649703          	lh	a4,70(s1)
    8000376a:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000376e:	04849703          	lh	a4,72(s1)
    80003772:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003776:	04a49703          	lh	a4,74(s1)
    8000377a:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000377e:	44f8                	lw	a4,76(s1)
    80003780:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003782:	03400613          	li	a2,52
    80003786:	05048593          	addi	a1,s1,80
    8000378a:	00c78513          	addi	a0,a5,12
    8000378e:	ffffd097          	auipc	ra,0xffffd
    80003792:	5a0080e7          	jalr	1440(ra) # 80000d2e <memmove>
  log_write(bp);
    80003796:	854a                	mv	a0,s2
    80003798:	00001097          	auipc	ra,0x1
    8000379c:	bfe080e7          	jalr	-1026(ra) # 80004396 <log_write>
  brelse(bp);
    800037a0:	854a                	mv	a0,s2
    800037a2:	00000097          	auipc	ra,0x0
    800037a6:	96a080e7          	jalr	-1686(ra) # 8000310c <brelse>
}
    800037aa:	60e2                	ld	ra,24(sp)
    800037ac:	6442                	ld	s0,16(sp)
    800037ae:	64a2                	ld	s1,8(sp)
    800037b0:	6902                	ld	s2,0(sp)
    800037b2:	6105                	addi	sp,sp,32
    800037b4:	8082                	ret

00000000800037b6 <idup>:
{
    800037b6:	1101                	addi	sp,sp,-32
    800037b8:	ec06                	sd	ra,24(sp)
    800037ba:	e822                	sd	s0,16(sp)
    800037bc:	e426                	sd	s1,8(sp)
    800037be:	1000                	addi	s0,sp,32
    800037c0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037c2:	0001c517          	auipc	a0,0x1c
    800037c6:	90650513          	addi	a0,a0,-1786 # 8001f0c8 <itable>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	40c080e7          	jalr	1036(ra) # 80000bd6 <acquire>
  ip->ref++;
    800037d2:	449c                	lw	a5,8(s1)
    800037d4:	2785                	addiw	a5,a5,1
    800037d6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037d8:	0001c517          	auipc	a0,0x1c
    800037dc:	8f050513          	addi	a0,a0,-1808 # 8001f0c8 <itable>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	4aa080e7          	jalr	1194(ra) # 80000c8a <release>
}
    800037e8:	8526                	mv	a0,s1
    800037ea:	60e2                	ld	ra,24(sp)
    800037ec:	6442                	ld	s0,16(sp)
    800037ee:	64a2                	ld	s1,8(sp)
    800037f0:	6105                	addi	sp,sp,32
    800037f2:	8082                	ret

00000000800037f4 <ilock>:
{
    800037f4:	1101                	addi	sp,sp,-32
    800037f6:	ec06                	sd	ra,24(sp)
    800037f8:	e822                	sd	s0,16(sp)
    800037fa:	e426                	sd	s1,8(sp)
    800037fc:	e04a                	sd	s2,0(sp)
    800037fe:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003800:	c115                	beqz	a0,80003824 <ilock+0x30>
    80003802:	84aa                	mv	s1,a0
    80003804:	451c                	lw	a5,8(a0)
    80003806:	00f05f63          	blez	a5,80003824 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000380a:	0541                	addi	a0,a0,16
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	ca8080e7          	jalr	-856(ra) # 800044b4 <acquiresleep>
  if(ip->valid == 0){
    80003814:	40bc                	lw	a5,64(s1)
    80003816:	cf99                	beqz	a5,80003834 <ilock+0x40>
}
    80003818:	60e2                	ld	ra,24(sp)
    8000381a:	6442                	ld	s0,16(sp)
    8000381c:	64a2                	ld	s1,8(sp)
    8000381e:	6902                	ld	s2,0(sp)
    80003820:	6105                	addi	sp,sp,32
    80003822:	8082                	ret
    panic("ilock");
    80003824:	00005517          	auipc	a0,0x5
    80003828:	df450513          	addi	a0,a0,-524 # 80008618 <syscalls+0x188>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	d14080e7          	jalr	-748(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003834:	40dc                	lw	a5,4(s1)
    80003836:	0047d79b          	srliw	a5,a5,0x4
    8000383a:	0001c597          	auipc	a1,0x1c
    8000383e:	8865a583          	lw	a1,-1914(a1) # 8001f0c0 <sb+0x18>
    80003842:	9dbd                	addw	a1,a1,a5
    80003844:	4088                	lw	a0,0(s1)
    80003846:	fffff097          	auipc	ra,0xfffff
    8000384a:	796080e7          	jalr	1942(ra) # 80002fdc <bread>
    8000384e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003850:	05850593          	addi	a1,a0,88
    80003854:	40dc                	lw	a5,4(s1)
    80003856:	8bbd                	andi	a5,a5,15
    80003858:	079a                	slli	a5,a5,0x6
    8000385a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000385c:	00059783          	lh	a5,0(a1)
    80003860:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003864:	00259783          	lh	a5,2(a1)
    80003868:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000386c:	00459783          	lh	a5,4(a1)
    80003870:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003874:	00659783          	lh	a5,6(a1)
    80003878:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000387c:	459c                	lw	a5,8(a1)
    8000387e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003880:	03400613          	li	a2,52
    80003884:	05b1                	addi	a1,a1,12
    80003886:	05048513          	addi	a0,s1,80
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	4a4080e7          	jalr	1188(ra) # 80000d2e <memmove>
    brelse(bp);
    80003892:	854a                	mv	a0,s2
    80003894:	00000097          	auipc	ra,0x0
    80003898:	878080e7          	jalr	-1928(ra) # 8000310c <brelse>
    ip->valid = 1;
    8000389c:	4785                	li	a5,1
    8000389e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038a0:	04449783          	lh	a5,68(s1)
    800038a4:	fbb5                	bnez	a5,80003818 <ilock+0x24>
      panic("ilock: no type");
    800038a6:	00005517          	auipc	a0,0x5
    800038aa:	d7a50513          	addi	a0,a0,-646 # 80008620 <syscalls+0x190>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	c92080e7          	jalr	-878(ra) # 80000540 <panic>

00000000800038b6 <iunlock>:
{
    800038b6:	1101                	addi	sp,sp,-32
    800038b8:	ec06                	sd	ra,24(sp)
    800038ba:	e822                	sd	s0,16(sp)
    800038bc:	e426                	sd	s1,8(sp)
    800038be:	e04a                	sd	s2,0(sp)
    800038c0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038c2:	c905                	beqz	a0,800038f2 <iunlock+0x3c>
    800038c4:	84aa                	mv	s1,a0
    800038c6:	01050913          	addi	s2,a0,16
    800038ca:	854a                	mv	a0,s2
    800038cc:	00001097          	auipc	ra,0x1
    800038d0:	c82080e7          	jalr	-894(ra) # 8000454e <holdingsleep>
    800038d4:	cd19                	beqz	a0,800038f2 <iunlock+0x3c>
    800038d6:	449c                	lw	a5,8(s1)
    800038d8:	00f05d63          	blez	a5,800038f2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038dc:	854a                	mv	a0,s2
    800038de:	00001097          	auipc	ra,0x1
    800038e2:	c2c080e7          	jalr	-980(ra) # 8000450a <releasesleep>
}
    800038e6:	60e2                	ld	ra,24(sp)
    800038e8:	6442                	ld	s0,16(sp)
    800038ea:	64a2                	ld	s1,8(sp)
    800038ec:	6902                	ld	s2,0(sp)
    800038ee:	6105                	addi	sp,sp,32
    800038f0:	8082                	ret
    panic("iunlock");
    800038f2:	00005517          	auipc	a0,0x5
    800038f6:	d3e50513          	addi	a0,a0,-706 # 80008630 <syscalls+0x1a0>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	c46080e7          	jalr	-954(ra) # 80000540 <panic>

0000000080003902 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003902:	7179                	addi	sp,sp,-48
    80003904:	f406                	sd	ra,40(sp)
    80003906:	f022                	sd	s0,32(sp)
    80003908:	ec26                	sd	s1,24(sp)
    8000390a:	e84a                	sd	s2,16(sp)
    8000390c:	e44e                	sd	s3,8(sp)
    8000390e:	e052                	sd	s4,0(sp)
    80003910:	1800                	addi	s0,sp,48
    80003912:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003914:	05050493          	addi	s1,a0,80
    80003918:	08050913          	addi	s2,a0,128
    8000391c:	a021                	j	80003924 <itrunc+0x22>
    8000391e:	0491                	addi	s1,s1,4
    80003920:	01248d63          	beq	s1,s2,8000393a <itrunc+0x38>
    if(ip->addrs[i]){
    80003924:	408c                	lw	a1,0(s1)
    80003926:	dde5                	beqz	a1,8000391e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003928:	0009a503          	lw	a0,0(s3)
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	8f6080e7          	jalr	-1802(ra) # 80003222 <bfree>
      ip->addrs[i] = 0;
    80003934:	0004a023          	sw	zero,0(s1)
    80003938:	b7dd                	j	8000391e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000393a:	0809a583          	lw	a1,128(s3)
    8000393e:	e185                	bnez	a1,8000395e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003940:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003944:	854e                	mv	a0,s3
    80003946:	00000097          	auipc	ra,0x0
    8000394a:	de2080e7          	jalr	-542(ra) # 80003728 <iupdate>
}
    8000394e:	70a2                	ld	ra,40(sp)
    80003950:	7402                	ld	s0,32(sp)
    80003952:	64e2                	ld	s1,24(sp)
    80003954:	6942                	ld	s2,16(sp)
    80003956:	69a2                	ld	s3,8(sp)
    80003958:	6a02                	ld	s4,0(sp)
    8000395a:	6145                	addi	sp,sp,48
    8000395c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000395e:	0009a503          	lw	a0,0(s3)
    80003962:	fffff097          	auipc	ra,0xfffff
    80003966:	67a080e7          	jalr	1658(ra) # 80002fdc <bread>
    8000396a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000396c:	05850493          	addi	s1,a0,88
    80003970:	45850913          	addi	s2,a0,1112
    80003974:	a021                	j	8000397c <itrunc+0x7a>
    80003976:	0491                	addi	s1,s1,4
    80003978:	01248b63          	beq	s1,s2,8000398e <itrunc+0x8c>
      if(a[j])
    8000397c:	408c                	lw	a1,0(s1)
    8000397e:	dde5                	beqz	a1,80003976 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003980:	0009a503          	lw	a0,0(s3)
    80003984:	00000097          	auipc	ra,0x0
    80003988:	89e080e7          	jalr	-1890(ra) # 80003222 <bfree>
    8000398c:	b7ed                	j	80003976 <itrunc+0x74>
    brelse(bp);
    8000398e:	8552                	mv	a0,s4
    80003990:	fffff097          	auipc	ra,0xfffff
    80003994:	77c080e7          	jalr	1916(ra) # 8000310c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003998:	0809a583          	lw	a1,128(s3)
    8000399c:	0009a503          	lw	a0,0(s3)
    800039a0:	00000097          	auipc	ra,0x0
    800039a4:	882080e7          	jalr	-1918(ra) # 80003222 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039a8:	0809a023          	sw	zero,128(s3)
    800039ac:	bf51                	j	80003940 <itrunc+0x3e>

00000000800039ae <iput>:
{
    800039ae:	1101                	addi	sp,sp,-32
    800039b0:	ec06                	sd	ra,24(sp)
    800039b2:	e822                	sd	s0,16(sp)
    800039b4:	e426                	sd	s1,8(sp)
    800039b6:	e04a                	sd	s2,0(sp)
    800039b8:	1000                	addi	s0,sp,32
    800039ba:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039bc:	0001b517          	auipc	a0,0x1b
    800039c0:	70c50513          	addi	a0,a0,1804 # 8001f0c8 <itable>
    800039c4:	ffffd097          	auipc	ra,0xffffd
    800039c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039cc:	4498                	lw	a4,8(s1)
    800039ce:	4785                	li	a5,1
    800039d0:	02f70363          	beq	a4,a5,800039f6 <iput+0x48>
  ip->ref--;
    800039d4:	449c                	lw	a5,8(s1)
    800039d6:	37fd                	addiw	a5,a5,-1
    800039d8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039da:	0001b517          	auipc	a0,0x1b
    800039de:	6ee50513          	addi	a0,a0,1774 # 8001f0c8 <itable>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	2a8080e7          	jalr	680(ra) # 80000c8a <release>
}
    800039ea:	60e2                	ld	ra,24(sp)
    800039ec:	6442                	ld	s0,16(sp)
    800039ee:	64a2                	ld	s1,8(sp)
    800039f0:	6902                	ld	s2,0(sp)
    800039f2:	6105                	addi	sp,sp,32
    800039f4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039f6:	40bc                	lw	a5,64(s1)
    800039f8:	dff1                	beqz	a5,800039d4 <iput+0x26>
    800039fa:	04a49783          	lh	a5,74(s1)
    800039fe:	fbf9                	bnez	a5,800039d4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a00:	01048913          	addi	s2,s1,16
    80003a04:	854a                	mv	a0,s2
    80003a06:	00001097          	auipc	ra,0x1
    80003a0a:	aae080e7          	jalr	-1362(ra) # 800044b4 <acquiresleep>
    release(&itable.lock);
    80003a0e:	0001b517          	auipc	a0,0x1b
    80003a12:	6ba50513          	addi	a0,a0,1722 # 8001f0c8 <itable>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	274080e7          	jalr	628(ra) # 80000c8a <release>
    itrunc(ip);
    80003a1e:	8526                	mv	a0,s1
    80003a20:	00000097          	auipc	ra,0x0
    80003a24:	ee2080e7          	jalr	-286(ra) # 80003902 <itrunc>
    ip->type = 0;
    80003a28:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a2c:	8526                	mv	a0,s1
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	cfa080e7          	jalr	-774(ra) # 80003728 <iupdate>
    ip->valid = 0;
    80003a36:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a3a:	854a                	mv	a0,s2
    80003a3c:	00001097          	auipc	ra,0x1
    80003a40:	ace080e7          	jalr	-1330(ra) # 8000450a <releasesleep>
    acquire(&itable.lock);
    80003a44:	0001b517          	auipc	a0,0x1b
    80003a48:	68450513          	addi	a0,a0,1668 # 8001f0c8 <itable>
    80003a4c:	ffffd097          	auipc	ra,0xffffd
    80003a50:	18a080e7          	jalr	394(ra) # 80000bd6 <acquire>
    80003a54:	b741                	j	800039d4 <iput+0x26>

0000000080003a56 <iunlockput>:
{
    80003a56:	1101                	addi	sp,sp,-32
    80003a58:	ec06                	sd	ra,24(sp)
    80003a5a:	e822                	sd	s0,16(sp)
    80003a5c:	e426                	sd	s1,8(sp)
    80003a5e:	1000                	addi	s0,sp,32
    80003a60:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	e54080e7          	jalr	-428(ra) # 800038b6 <iunlock>
  iput(ip);
    80003a6a:	8526                	mv	a0,s1
    80003a6c:	00000097          	auipc	ra,0x0
    80003a70:	f42080e7          	jalr	-190(ra) # 800039ae <iput>
}
    80003a74:	60e2                	ld	ra,24(sp)
    80003a76:	6442                	ld	s0,16(sp)
    80003a78:	64a2                	ld	s1,8(sp)
    80003a7a:	6105                	addi	sp,sp,32
    80003a7c:	8082                	ret

0000000080003a7e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a7e:	1141                	addi	sp,sp,-16
    80003a80:	e422                	sd	s0,8(sp)
    80003a82:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a84:	411c                	lw	a5,0(a0)
    80003a86:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a88:	415c                	lw	a5,4(a0)
    80003a8a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a8c:	04451783          	lh	a5,68(a0)
    80003a90:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a94:	04a51783          	lh	a5,74(a0)
    80003a98:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a9c:	04c56783          	lwu	a5,76(a0)
    80003aa0:	e99c                	sd	a5,16(a1)
}
    80003aa2:	6422                	ld	s0,8(sp)
    80003aa4:	0141                	addi	sp,sp,16
    80003aa6:	8082                	ret

0000000080003aa8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aa8:	457c                	lw	a5,76(a0)
    80003aaa:	0ed7e963          	bltu	a5,a3,80003b9c <readi+0xf4>
{
    80003aae:	7159                	addi	sp,sp,-112
    80003ab0:	f486                	sd	ra,104(sp)
    80003ab2:	f0a2                	sd	s0,96(sp)
    80003ab4:	eca6                	sd	s1,88(sp)
    80003ab6:	e8ca                	sd	s2,80(sp)
    80003ab8:	e4ce                	sd	s3,72(sp)
    80003aba:	e0d2                	sd	s4,64(sp)
    80003abc:	fc56                	sd	s5,56(sp)
    80003abe:	f85a                	sd	s6,48(sp)
    80003ac0:	f45e                	sd	s7,40(sp)
    80003ac2:	f062                	sd	s8,32(sp)
    80003ac4:	ec66                	sd	s9,24(sp)
    80003ac6:	e86a                	sd	s10,16(sp)
    80003ac8:	e46e                	sd	s11,8(sp)
    80003aca:	1880                	addi	s0,sp,112
    80003acc:	8b2a                	mv	s6,a0
    80003ace:	8bae                	mv	s7,a1
    80003ad0:	8a32                	mv	s4,a2
    80003ad2:	84b6                	mv	s1,a3
    80003ad4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ad6:	9f35                	addw	a4,a4,a3
    return 0;
    80003ad8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ada:	0ad76063          	bltu	a4,a3,80003b7a <readi+0xd2>
  if(off + n > ip->size)
    80003ade:	00e7f463          	bgeu	a5,a4,80003ae6 <readi+0x3e>
    n = ip->size - off;
    80003ae2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ae6:	0a0a8963          	beqz	s5,80003b98 <readi+0xf0>
    80003aea:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aec:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003af0:	5c7d                	li	s8,-1
    80003af2:	a82d                	j	80003b2c <readi+0x84>
    80003af4:	020d1d93          	slli	s11,s10,0x20
    80003af8:	020ddd93          	srli	s11,s11,0x20
    80003afc:	05890613          	addi	a2,s2,88
    80003b00:	86ee                	mv	a3,s11
    80003b02:	963a                	add	a2,a2,a4
    80003b04:	85d2                	mv	a1,s4
    80003b06:	855e                	mv	a0,s7
    80003b08:	fffff097          	auipc	ra,0xfffff
    80003b0c:	954080e7          	jalr	-1708(ra) # 8000245c <either_copyout>
    80003b10:	05850d63          	beq	a0,s8,80003b6a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b14:	854a                	mv	a0,s2
    80003b16:	fffff097          	auipc	ra,0xfffff
    80003b1a:	5f6080e7          	jalr	1526(ra) # 8000310c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b1e:	013d09bb          	addw	s3,s10,s3
    80003b22:	009d04bb          	addw	s1,s10,s1
    80003b26:	9a6e                	add	s4,s4,s11
    80003b28:	0559f763          	bgeu	s3,s5,80003b76 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b2c:	00a4d59b          	srliw	a1,s1,0xa
    80003b30:	855a                	mv	a0,s6
    80003b32:	00000097          	auipc	ra,0x0
    80003b36:	89e080e7          	jalr	-1890(ra) # 800033d0 <bmap>
    80003b3a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b3e:	cd85                	beqz	a1,80003b76 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b40:	000b2503          	lw	a0,0(s6)
    80003b44:	fffff097          	auipc	ra,0xfffff
    80003b48:	498080e7          	jalr	1176(ra) # 80002fdc <bread>
    80003b4c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b4e:	3ff4f713          	andi	a4,s1,1023
    80003b52:	40ec87bb          	subw	a5,s9,a4
    80003b56:	413a86bb          	subw	a3,s5,s3
    80003b5a:	8d3e                	mv	s10,a5
    80003b5c:	2781                	sext.w	a5,a5
    80003b5e:	0006861b          	sext.w	a2,a3
    80003b62:	f8f679e3          	bgeu	a2,a5,80003af4 <readi+0x4c>
    80003b66:	8d36                	mv	s10,a3
    80003b68:	b771                	j	80003af4 <readi+0x4c>
      brelse(bp);
    80003b6a:	854a                	mv	a0,s2
    80003b6c:	fffff097          	auipc	ra,0xfffff
    80003b70:	5a0080e7          	jalr	1440(ra) # 8000310c <brelse>
      tot = -1;
    80003b74:	59fd                	li	s3,-1
  }
  return tot;
    80003b76:	0009851b          	sext.w	a0,s3
}
    80003b7a:	70a6                	ld	ra,104(sp)
    80003b7c:	7406                	ld	s0,96(sp)
    80003b7e:	64e6                	ld	s1,88(sp)
    80003b80:	6946                	ld	s2,80(sp)
    80003b82:	69a6                	ld	s3,72(sp)
    80003b84:	6a06                	ld	s4,64(sp)
    80003b86:	7ae2                	ld	s5,56(sp)
    80003b88:	7b42                	ld	s6,48(sp)
    80003b8a:	7ba2                	ld	s7,40(sp)
    80003b8c:	7c02                	ld	s8,32(sp)
    80003b8e:	6ce2                	ld	s9,24(sp)
    80003b90:	6d42                	ld	s10,16(sp)
    80003b92:	6da2                	ld	s11,8(sp)
    80003b94:	6165                	addi	sp,sp,112
    80003b96:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b98:	89d6                	mv	s3,s5
    80003b9a:	bff1                	j	80003b76 <readi+0xce>
    return 0;
    80003b9c:	4501                	li	a0,0
}
    80003b9e:	8082                	ret

0000000080003ba0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ba0:	457c                	lw	a5,76(a0)
    80003ba2:	10d7e863          	bltu	a5,a3,80003cb2 <writei+0x112>
{
    80003ba6:	7159                	addi	sp,sp,-112
    80003ba8:	f486                	sd	ra,104(sp)
    80003baa:	f0a2                	sd	s0,96(sp)
    80003bac:	eca6                	sd	s1,88(sp)
    80003bae:	e8ca                	sd	s2,80(sp)
    80003bb0:	e4ce                	sd	s3,72(sp)
    80003bb2:	e0d2                	sd	s4,64(sp)
    80003bb4:	fc56                	sd	s5,56(sp)
    80003bb6:	f85a                	sd	s6,48(sp)
    80003bb8:	f45e                	sd	s7,40(sp)
    80003bba:	f062                	sd	s8,32(sp)
    80003bbc:	ec66                	sd	s9,24(sp)
    80003bbe:	e86a                	sd	s10,16(sp)
    80003bc0:	e46e                	sd	s11,8(sp)
    80003bc2:	1880                	addi	s0,sp,112
    80003bc4:	8aaa                	mv	s5,a0
    80003bc6:	8bae                	mv	s7,a1
    80003bc8:	8a32                	mv	s4,a2
    80003bca:	8936                	mv	s2,a3
    80003bcc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bce:	00e687bb          	addw	a5,a3,a4
    80003bd2:	0ed7e263          	bltu	a5,a3,80003cb6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bd6:	00043737          	lui	a4,0x43
    80003bda:	0ef76063          	bltu	a4,a5,80003cba <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bde:	0c0b0863          	beqz	s6,80003cae <writei+0x10e>
    80003be2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003be4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003be8:	5c7d                	li	s8,-1
    80003bea:	a091                	j	80003c2e <writei+0x8e>
    80003bec:	020d1d93          	slli	s11,s10,0x20
    80003bf0:	020ddd93          	srli	s11,s11,0x20
    80003bf4:	05848513          	addi	a0,s1,88
    80003bf8:	86ee                	mv	a3,s11
    80003bfa:	8652                	mv	a2,s4
    80003bfc:	85de                	mv	a1,s7
    80003bfe:	953a                	add	a0,a0,a4
    80003c00:	fffff097          	auipc	ra,0xfffff
    80003c04:	8b2080e7          	jalr	-1870(ra) # 800024b2 <either_copyin>
    80003c08:	07850263          	beq	a0,s8,80003c6c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c0c:	8526                	mv	a0,s1
    80003c0e:	00000097          	auipc	ra,0x0
    80003c12:	788080e7          	jalr	1928(ra) # 80004396 <log_write>
    brelse(bp);
    80003c16:	8526                	mv	a0,s1
    80003c18:	fffff097          	auipc	ra,0xfffff
    80003c1c:	4f4080e7          	jalr	1268(ra) # 8000310c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c20:	013d09bb          	addw	s3,s10,s3
    80003c24:	012d093b          	addw	s2,s10,s2
    80003c28:	9a6e                	add	s4,s4,s11
    80003c2a:	0569f663          	bgeu	s3,s6,80003c76 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c2e:	00a9559b          	srliw	a1,s2,0xa
    80003c32:	8556                	mv	a0,s5
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	79c080e7          	jalr	1948(ra) # 800033d0 <bmap>
    80003c3c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c40:	c99d                	beqz	a1,80003c76 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c42:	000aa503          	lw	a0,0(s5)
    80003c46:	fffff097          	auipc	ra,0xfffff
    80003c4a:	396080e7          	jalr	918(ra) # 80002fdc <bread>
    80003c4e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c50:	3ff97713          	andi	a4,s2,1023
    80003c54:	40ec87bb          	subw	a5,s9,a4
    80003c58:	413b06bb          	subw	a3,s6,s3
    80003c5c:	8d3e                	mv	s10,a5
    80003c5e:	2781                	sext.w	a5,a5
    80003c60:	0006861b          	sext.w	a2,a3
    80003c64:	f8f674e3          	bgeu	a2,a5,80003bec <writei+0x4c>
    80003c68:	8d36                	mv	s10,a3
    80003c6a:	b749                	j	80003bec <writei+0x4c>
      brelse(bp);
    80003c6c:	8526                	mv	a0,s1
    80003c6e:	fffff097          	auipc	ra,0xfffff
    80003c72:	49e080e7          	jalr	1182(ra) # 8000310c <brelse>
  }

  if(off > ip->size)
    80003c76:	04caa783          	lw	a5,76(s5)
    80003c7a:	0127f463          	bgeu	a5,s2,80003c82 <writei+0xe2>
    ip->size = off;
    80003c7e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c82:	8556                	mv	a0,s5
    80003c84:	00000097          	auipc	ra,0x0
    80003c88:	aa4080e7          	jalr	-1372(ra) # 80003728 <iupdate>

  return tot;
    80003c8c:	0009851b          	sext.w	a0,s3
}
    80003c90:	70a6                	ld	ra,104(sp)
    80003c92:	7406                	ld	s0,96(sp)
    80003c94:	64e6                	ld	s1,88(sp)
    80003c96:	6946                	ld	s2,80(sp)
    80003c98:	69a6                	ld	s3,72(sp)
    80003c9a:	6a06                	ld	s4,64(sp)
    80003c9c:	7ae2                	ld	s5,56(sp)
    80003c9e:	7b42                	ld	s6,48(sp)
    80003ca0:	7ba2                	ld	s7,40(sp)
    80003ca2:	7c02                	ld	s8,32(sp)
    80003ca4:	6ce2                	ld	s9,24(sp)
    80003ca6:	6d42                	ld	s10,16(sp)
    80003ca8:	6da2                	ld	s11,8(sp)
    80003caa:	6165                	addi	sp,sp,112
    80003cac:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cae:	89da                	mv	s3,s6
    80003cb0:	bfc9                	j	80003c82 <writei+0xe2>
    return -1;
    80003cb2:	557d                	li	a0,-1
}
    80003cb4:	8082                	ret
    return -1;
    80003cb6:	557d                	li	a0,-1
    80003cb8:	bfe1                	j	80003c90 <writei+0xf0>
    return -1;
    80003cba:	557d                	li	a0,-1
    80003cbc:	bfd1                	j	80003c90 <writei+0xf0>

0000000080003cbe <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cbe:	1141                	addi	sp,sp,-16
    80003cc0:	e406                	sd	ra,8(sp)
    80003cc2:	e022                	sd	s0,0(sp)
    80003cc4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cc6:	4639                	li	a2,14
    80003cc8:	ffffd097          	auipc	ra,0xffffd
    80003ccc:	0da080e7          	jalr	218(ra) # 80000da2 <strncmp>
}
    80003cd0:	60a2                	ld	ra,8(sp)
    80003cd2:	6402                	ld	s0,0(sp)
    80003cd4:	0141                	addi	sp,sp,16
    80003cd6:	8082                	ret

0000000080003cd8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cd8:	7139                	addi	sp,sp,-64
    80003cda:	fc06                	sd	ra,56(sp)
    80003cdc:	f822                	sd	s0,48(sp)
    80003cde:	f426                	sd	s1,40(sp)
    80003ce0:	f04a                	sd	s2,32(sp)
    80003ce2:	ec4e                	sd	s3,24(sp)
    80003ce4:	e852                	sd	s4,16(sp)
    80003ce6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ce8:	04451703          	lh	a4,68(a0)
    80003cec:	4785                	li	a5,1
    80003cee:	00f71a63          	bne	a4,a5,80003d02 <dirlookup+0x2a>
    80003cf2:	892a                	mv	s2,a0
    80003cf4:	89ae                	mv	s3,a1
    80003cf6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cf8:	457c                	lw	a5,76(a0)
    80003cfa:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cfc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cfe:	e79d                	bnez	a5,80003d2c <dirlookup+0x54>
    80003d00:	a8a5                	j	80003d78 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d02:	00005517          	auipc	a0,0x5
    80003d06:	93650513          	addi	a0,a0,-1738 # 80008638 <syscalls+0x1a8>
    80003d0a:	ffffd097          	auipc	ra,0xffffd
    80003d0e:	836080e7          	jalr	-1994(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003d12:	00005517          	auipc	a0,0x5
    80003d16:	93e50513          	addi	a0,a0,-1730 # 80008650 <syscalls+0x1c0>
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	826080e7          	jalr	-2010(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d22:	24c1                	addiw	s1,s1,16
    80003d24:	04c92783          	lw	a5,76(s2)
    80003d28:	04f4f763          	bgeu	s1,a5,80003d76 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d2c:	4741                	li	a4,16
    80003d2e:	86a6                	mv	a3,s1
    80003d30:	fc040613          	addi	a2,s0,-64
    80003d34:	4581                	li	a1,0
    80003d36:	854a                	mv	a0,s2
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	d70080e7          	jalr	-656(ra) # 80003aa8 <readi>
    80003d40:	47c1                	li	a5,16
    80003d42:	fcf518e3          	bne	a0,a5,80003d12 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d46:	fc045783          	lhu	a5,-64(s0)
    80003d4a:	dfe1                	beqz	a5,80003d22 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d4c:	fc240593          	addi	a1,s0,-62
    80003d50:	854e                	mv	a0,s3
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	f6c080e7          	jalr	-148(ra) # 80003cbe <namecmp>
    80003d5a:	f561                	bnez	a0,80003d22 <dirlookup+0x4a>
      if(poff)
    80003d5c:	000a0463          	beqz	s4,80003d64 <dirlookup+0x8c>
        *poff = off;
    80003d60:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d64:	fc045583          	lhu	a1,-64(s0)
    80003d68:	00092503          	lw	a0,0(s2)
    80003d6c:	fffff097          	auipc	ra,0xfffff
    80003d70:	74e080e7          	jalr	1870(ra) # 800034ba <iget>
    80003d74:	a011                	j	80003d78 <dirlookup+0xa0>
  return 0;
    80003d76:	4501                	li	a0,0
}
    80003d78:	70e2                	ld	ra,56(sp)
    80003d7a:	7442                	ld	s0,48(sp)
    80003d7c:	74a2                	ld	s1,40(sp)
    80003d7e:	7902                	ld	s2,32(sp)
    80003d80:	69e2                	ld	s3,24(sp)
    80003d82:	6a42                	ld	s4,16(sp)
    80003d84:	6121                	addi	sp,sp,64
    80003d86:	8082                	ret

0000000080003d88 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d88:	711d                	addi	sp,sp,-96
    80003d8a:	ec86                	sd	ra,88(sp)
    80003d8c:	e8a2                	sd	s0,80(sp)
    80003d8e:	e4a6                	sd	s1,72(sp)
    80003d90:	e0ca                	sd	s2,64(sp)
    80003d92:	fc4e                	sd	s3,56(sp)
    80003d94:	f852                	sd	s4,48(sp)
    80003d96:	f456                	sd	s5,40(sp)
    80003d98:	f05a                	sd	s6,32(sp)
    80003d9a:	ec5e                	sd	s7,24(sp)
    80003d9c:	e862                	sd	s8,16(sp)
    80003d9e:	e466                	sd	s9,8(sp)
    80003da0:	e06a                	sd	s10,0(sp)
    80003da2:	1080                	addi	s0,sp,96
    80003da4:	84aa                	mv	s1,a0
    80003da6:	8b2e                	mv	s6,a1
    80003da8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003daa:	00054703          	lbu	a4,0(a0)
    80003dae:	02f00793          	li	a5,47
    80003db2:	02f70363          	beq	a4,a5,80003dd8 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003db6:	ffffe097          	auipc	ra,0xffffe
    80003dba:	bf6080e7          	jalr	-1034(ra) # 800019ac <myproc>
    80003dbe:	15053503          	ld	a0,336(a0)
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	9f4080e7          	jalr	-1548(ra) # 800037b6 <idup>
    80003dca:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003dcc:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003dd0:	4cb5                	li	s9,13
  len = path - s;
    80003dd2:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dd4:	4c05                	li	s8,1
    80003dd6:	a87d                	j	80003e94 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003dd8:	4585                	li	a1,1
    80003dda:	4505                	li	a0,1
    80003ddc:	fffff097          	auipc	ra,0xfffff
    80003de0:	6de080e7          	jalr	1758(ra) # 800034ba <iget>
    80003de4:	8a2a                	mv	s4,a0
    80003de6:	b7dd                	j	80003dcc <namex+0x44>
      iunlockput(ip);
    80003de8:	8552                	mv	a0,s4
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	c6c080e7          	jalr	-916(ra) # 80003a56 <iunlockput>
      return 0;
    80003df2:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003df4:	8552                	mv	a0,s4
    80003df6:	60e6                	ld	ra,88(sp)
    80003df8:	6446                	ld	s0,80(sp)
    80003dfa:	64a6                	ld	s1,72(sp)
    80003dfc:	6906                	ld	s2,64(sp)
    80003dfe:	79e2                	ld	s3,56(sp)
    80003e00:	7a42                	ld	s4,48(sp)
    80003e02:	7aa2                	ld	s5,40(sp)
    80003e04:	7b02                	ld	s6,32(sp)
    80003e06:	6be2                	ld	s7,24(sp)
    80003e08:	6c42                	ld	s8,16(sp)
    80003e0a:	6ca2                	ld	s9,8(sp)
    80003e0c:	6d02                	ld	s10,0(sp)
    80003e0e:	6125                	addi	sp,sp,96
    80003e10:	8082                	ret
      iunlock(ip);
    80003e12:	8552                	mv	a0,s4
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	aa2080e7          	jalr	-1374(ra) # 800038b6 <iunlock>
      return ip;
    80003e1c:	bfe1                	j	80003df4 <namex+0x6c>
      iunlockput(ip);
    80003e1e:	8552                	mv	a0,s4
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	c36080e7          	jalr	-970(ra) # 80003a56 <iunlockput>
      return 0;
    80003e28:	8a4e                	mv	s4,s3
    80003e2a:	b7e9                	j	80003df4 <namex+0x6c>
  len = path - s;
    80003e2c:	40998633          	sub	a2,s3,s1
    80003e30:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003e34:	09acd863          	bge	s9,s10,80003ec4 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003e38:	4639                	li	a2,14
    80003e3a:	85a6                	mv	a1,s1
    80003e3c:	8556                	mv	a0,s5
    80003e3e:	ffffd097          	auipc	ra,0xffffd
    80003e42:	ef0080e7          	jalr	-272(ra) # 80000d2e <memmove>
    80003e46:	84ce                	mv	s1,s3
  while(*path == '/')
    80003e48:	0004c783          	lbu	a5,0(s1)
    80003e4c:	01279763          	bne	a5,s2,80003e5a <namex+0xd2>
    path++;
    80003e50:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e52:	0004c783          	lbu	a5,0(s1)
    80003e56:	ff278de3          	beq	a5,s2,80003e50 <namex+0xc8>
    ilock(ip);
    80003e5a:	8552                	mv	a0,s4
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	998080e7          	jalr	-1640(ra) # 800037f4 <ilock>
    if(ip->type != T_DIR){
    80003e64:	044a1783          	lh	a5,68(s4)
    80003e68:	f98790e3          	bne	a5,s8,80003de8 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003e6c:	000b0563          	beqz	s6,80003e76 <namex+0xee>
    80003e70:	0004c783          	lbu	a5,0(s1)
    80003e74:	dfd9                	beqz	a5,80003e12 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e76:	865e                	mv	a2,s7
    80003e78:	85d6                	mv	a1,s5
    80003e7a:	8552                	mv	a0,s4
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	e5c080e7          	jalr	-420(ra) # 80003cd8 <dirlookup>
    80003e84:	89aa                	mv	s3,a0
    80003e86:	dd41                	beqz	a0,80003e1e <namex+0x96>
    iunlockput(ip);
    80003e88:	8552                	mv	a0,s4
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	bcc080e7          	jalr	-1076(ra) # 80003a56 <iunlockput>
    ip = next;
    80003e92:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e94:	0004c783          	lbu	a5,0(s1)
    80003e98:	01279763          	bne	a5,s2,80003ea6 <namex+0x11e>
    path++;
    80003e9c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e9e:	0004c783          	lbu	a5,0(s1)
    80003ea2:	ff278de3          	beq	a5,s2,80003e9c <namex+0x114>
  if(*path == 0)
    80003ea6:	cb9d                	beqz	a5,80003edc <namex+0x154>
  while(*path != '/' && *path != 0)
    80003ea8:	0004c783          	lbu	a5,0(s1)
    80003eac:	89a6                	mv	s3,s1
  len = path - s;
    80003eae:	8d5e                	mv	s10,s7
    80003eb0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003eb2:	01278963          	beq	a5,s2,80003ec4 <namex+0x13c>
    80003eb6:	dbbd                	beqz	a5,80003e2c <namex+0xa4>
    path++;
    80003eb8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003eba:	0009c783          	lbu	a5,0(s3)
    80003ebe:	ff279ce3          	bne	a5,s2,80003eb6 <namex+0x12e>
    80003ec2:	b7ad                	j	80003e2c <namex+0xa4>
    memmove(name, s, len);
    80003ec4:	2601                	sext.w	a2,a2
    80003ec6:	85a6                	mv	a1,s1
    80003ec8:	8556                	mv	a0,s5
    80003eca:	ffffd097          	auipc	ra,0xffffd
    80003ece:	e64080e7          	jalr	-412(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003ed2:	9d56                	add	s10,s10,s5
    80003ed4:	000d0023          	sb	zero,0(s10)
    80003ed8:	84ce                	mv	s1,s3
    80003eda:	b7bd                	j	80003e48 <namex+0xc0>
  if(nameiparent){
    80003edc:	f00b0ce3          	beqz	s6,80003df4 <namex+0x6c>
    iput(ip);
    80003ee0:	8552                	mv	a0,s4
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	acc080e7          	jalr	-1332(ra) # 800039ae <iput>
    return 0;
    80003eea:	4a01                	li	s4,0
    80003eec:	b721                	j	80003df4 <namex+0x6c>

0000000080003eee <dirlink>:
{
    80003eee:	7139                	addi	sp,sp,-64
    80003ef0:	fc06                	sd	ra,56(sp)
    80003ef2:	f822                	sd	s0,48(sp)
    80003ef4:	f426                	sd	s1,40(sp)
    80003ef6:	f04a                	sd	s2,32(sp)
    80003ef8:	ec4e                	sd	s3,24(sp)
    80003efa:	e852                	sd	s4,16(sp)
    80003efc:	0080                	addi	s0,sp,64
    80003efe:	892a                	mv	s2,a0
    80003f00:	8a2e                	mv	s4,a1
    80003f02:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f04:	4601                	li	a2,0
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	dd2080e7          	jalr	-558(ra) # 80003cd8 <dirlookup>
    80003f0e:	e93d                	bnez	a0,80003f84 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f10:	04c92483          	lw	s1,76(s2)
    80003f14:	c49d                	beqz	s1,80003f42 <dirlink+0x54>
    80003f16:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f18:	4741                	li	a4,16
    80003f1a:	86a6                	mv	a3,s1
    80003f1c:	fc040613          	addi	a2,s0,-64
    80003f20:	4581                	li	a1,0
    80003f22:	854a                	mv	a0,s2
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	b84080e7          	jalr	-1148(ra) # 80003aa8 <readi>
    80003f2c:	47c1                	li	a5,16
    80003f2e:	06f51163          	bne	a0,a5,80003f90 <dirlink+0xa2>
    if(de.inum == 0)
    80003f32:	fc045783          	lhu	a5,-64(s0)
    80003f36:	c791                	beqz	a5,80003f42 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f38:	24c1                	addiw	s1,s1,16
    80003f3a:	04c92783          	lw	a5,76(s2)
    80003f3e:	fcf4ede3          	bltu	s1,a5,80003f18 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f42:	4639                	li	a2,14
    80003f44:	85d2                	mv	a1,s4
    80003f46:	fc240513          	addi	a0,s0,-62
    80003f4a:	ffffd097          	auipc	ra,0xffffd
    80003f4e:	e94080e7          	jalr	-364(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003f52:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f56:	4741                	li	a4,16
    80003f58:	86a6                	mv	a3,s1
    80003f5a:	fc040613          	addi	a2,s0,-64
    80003f5e:	4581                	li	a1,0
    80003f60:	854a                	mv	a0,s2
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	c3e080e7          	jalr	-962(ra) # 80003ba0 <writei>
    80003f6a:	1541                	addi	a0,a0,-16
    80003f6c:	00a03533          	snez	a0,a0
    80003f70:	40a00533          	neg	a0,a0
}
    80003f74:	70e2                	ld	ra,56(sp)
    80003f76:	7442                	ld	s0,48(sp)
    80003f78:	74a2                	ld	s1,40(sp)
    80003f7a:	7902                	ld	s2,32(sp)
    80003f7c:	69e2                	ld	s3,24(sp)
    80003f7e:	6a42                	ld	s4,16(sp)
    80003f80:	6121                	addi	sp,sp,64
    80003f82:	8082                	ret
    iput(ip);
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	a2a080e7          	jalr	-1494(ra) # 800039ae <iput>
    return -1;
    80003f8c:	557d                	li	a0,-1
    80003f8e:	b7dd                	j	80003f74 <dirlink+0x86>
      panic("dirlink read");
    80003f90:	00004517          	auipc	a0,0x4
    80003f94:	6d050513          	addi	a0,a0,1744 # 80008660 <syscalls+0x1d0>
    80003f98:	ffffc097          	auipc	ra,0xffffc
    80003f9c:	5a8080e7          	jalr	1448(ra) # 80000540 <panic>

0000000080003fa0 <namei>:

struct inode*
namei(char *path)
{
    80003fa0:	1101                	addi	sp,sp,-32
    80003fa2:	ec06                	sd	ra,24(sp)
    80003fa4:	e822                	sd	s0,16(sp)
    80003fa6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fa8:	fe040613          	addi	a2,s0,-32
    80003fac:	4581                	li	a1,0
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	dda080e7          	jalr	-550(ra) # 80003d88 <namex>
}
    80003fb6:	60e2                	ld	ra,24(sp)
    80003fb8:	6442                	ld	s0,16(sp)
    80003fba:	6105                	addi	sp,sp,32
    80003fbc:	8082                	ret

0000000080003fbe <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fbe:	1141                	addi	sp,sp,-16
    80003fc0:	e406                	sd	ra,8(sp)
    80003fc2:	e022                	sd	s0,0(sp)
    80003fc4:	0800                	addi	s0,sp,16
    80003fc6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fc8:	4585                	li	a1,1
    80003fca:	00000097          	auipc	ra,0x0
    80003fce:	dbe080e7          	jalr	-578(ra) # 80003d88 <namex>
}
    80003fd2:	60a2                	ld	ra,8(sp)
    80003fd4:	6402                	ld	s0,0(sp)
    80003fd6:	0141                	addi	sp,sp,16
    80003fd8:	8082                	ret

0000000080003fda <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fda:	1101                	addi	sp,sp,-32
    80003fdc:	ec06                	sd	ra,24(sp)
    80003fde:	e822                	sd	s0,16(sp)
    80003fe0:	e426                	sd	s1,8(sp)
    80003fe2:	e04a                	sd	s2,0(sp)
    80003fe4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fe6:	0001d917          	auipc	s2,0x1d
    80003fea:	b8a90913          	addi	s2,s2,-1142 # 80020b70 <log>
    80003fee:	01892583          	lw	a1,24(s2)
    80003ff2:	02892503          	lw	a0,40(s2)
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	fe6080e7          	jalr	-26(ra) # 80002fdc <bread>
    80003ffe:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004000:	02c92683          	lw	a3,44(s2)
    80004004:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004006:	02d05863          	blez	a3,80004036 <write_head+0x5c>
    8000400a:	0001d797          	auipc	a5,0x1d
    8000400e:	b9678793          	addi	a5,a5,-1130 # 80020ba0 <log+0x30>
    80004012:	05c50713          	addi	a4,a0,92
    80004016:	36fd                	addiw	a3,a3,-1
    80004018:	02069613          	slli	a2,a3,0x20
    8000401c:	01e65693          	srli	a3,a2,0x1e
    80004020:	0001d617          	auipc	a2,0x1d
    80004024:	b8460613          	addi	a2,a2,-1148 # 80020ba4 <log+0x34>
    80004028:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000402a:	4390                	lw	a2,0(a5)
    8000402c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000402e:	0791                	addi	a5,a5,4
    80004030:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004032:	fed79ce3          	bne	a5,a3,8000402a <write_head+0x50>
  }
  bwrite(buf);
    80004036:	8526                	mv	a0,s1
    80004038:	fffff097          	auipc	ra,0xfffff
    8000403c:	096080e7          	jalr	150(ra) # 800030ce <bwrite>
  brelse(buf);
    80004040:	8526                	mv	a0,s1
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	0ca080e7          	jalr	202(ra) # 8000310c <brelse>
}
    8000404a:	60e2                	ld	ra,24(sp)
    8000404c:	6442                	ld	s0,16(sp)
    8000404e:	64a2                	ld	s1,8(sp)
    80004050:	6902                	ld	s2,0(sp)
    80004052:	6105                	addi	sp,sp,32
    80004054:	8082                	ret

0000000080004056 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004056:	0001d797          	auipc	a5,0x1d
    8000405a:	b467a783          	lw	a5,-1210(a5) # 80020b9c <log+0x2c>
    8000405e:	0af05d63          	blez	a5,80004118 <install_trans+0xc2>
{
    80004062:	7139                	addi	sp,sp,-64
    80004064:	fc06                	sd	ra,56(sp)
    80004066:	f822                	sd	s0,48(sp)
    80004068:	f426                	sd	s1,40(sp)
    8000406a:	f04a                	sd	s2,32(sp)
    8000406c:	ec4e                	sd	s3,24(sp)
    8000406e:	e852                	sd	s4,16(sp)
    80004070:	e456                	sd	s5,8(sp)
    80004072:	e05a                	sd	s6,0(sp)
    80004074:	0080                	addi	s0,sp,64
    80004076:	8b2a                	mv	s6,a0
    80004078:	0001da97          	auipc	s5,0x1d
    8000407c:	b28a8a93          	addi	s5,s5,-1240 # 80020ba0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004080:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004082:	0001d997          	auipc	s3,0x1d
    80004086:	aee98993          	addi	s3,s3,-1298 # 80020b70 <log>
    8000408a:	a00d                	j	800040ac <install_trans+0x56>
    brelse(lbuf);
    8000408c:	854a                	mv	a0,s2
    8000408e:	fffff097          	auipc	ra,0xfffff
    80004092:	07e080e7          	jalr	126(ra) # 8000310c <brelse>
    brelse(dbuf);
    80004096:	8526                	mv	a0,s1
    80004098:	fffff097          	auipc	ra,0xfffff
    8000409c:	074080e7          	jalr	116(ra) # 8000310c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040a0:	2a05                	addiw	s4,s4,1
    800040a2:	0a91                	addi	s5,s5,4
    800040a4:	02c9a783          	lw	a5,44(s3)
    800040a8:	04fa5e63          	bge	s4,a5,80004104 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ac:	0189a583          	lw	a1,24(s3)
    800040b0:	014585bb          	addw	a1,a1,s4
    800040b4:	2585                	addiw	a1,a1,1
    800040b6:	0289a503          	lw	a0,40(s3)
    800040ba:	fffff097          	auipc	ra,0xfffff
    800040be:	f22080e7          	jalr	-222(ra) # 80002fdc <bread>
    800040c2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040c4:	000aa583          	lw	a1,0(s5)
    800040c8:	0289a503          	lw	a0,40(s3)
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	f10080e7          	jalr	-240(ra) # 80002fdc <bread>
    800040d4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040d6:	40000613          	li	a2,1024
    800040da:	05890593          	addi	a1,s2,88
    800040de:	05850513          	addi	a0,a0,88
    800040e2:	ffffd097          	auipc	ra,0xffffd
    800040e6:	c4c080e7          	jalr	-948(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800040ea:	8526                	mv	a0,s1
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	fe2080e7          	jalr	-30(ra) # 800030ce <bwrite>
    if(recovering == 0)
    800040f4:	f80b1ce3          	bnez	s6,8000408c <install_trans+0x36>
      bunpin(dbuf);
    800040f8:	8526                	mv	a0,s1
    800040fa:	fffff097          	auipc	ra,0xfffff
    800040fe:	0ec080e7          	jalr	236(ra) # 800031e6 <bunpin>
    80004102:	b769                	j	8000408c <install_trans+0x36>
}
    80004104:	70e2                	ld	ra,56(sp)
    80004106:	7442                	ld	s0,48(sp)
    80004108:	74a2                	ld	s1,40(sp)
    8000410a:	7902                	ld	s2,32(sp)
    8000410c:	69e2                	ld	s3,24(sp)
    8000410e:	6a42                	ld	s4,16(sp)
    80004110:	6aa2                	ld	s5,8(sp)
    80004112:	6b02                	ld	s6,0(sp)
    80004114:	6121                	addi	sp,sp,64
    80004116:	8082                	ret
    80004118:	8082                	ret

000000008000411a <initlog>:
{
    8000411a:	7179                	addi	sp,sp,-48
    8000411c:	f406                	sd	ra,40(sp)
    8000411e:	f022                	sd	s0,32(sp)
    80004120:	ec26                	sd	s1,24(sp)
    80004122:	e84a                	sd	s2,16(sp)
    80004124:	e44e                	sd	s3,8(sp)
    80004126:	1800                	addi	s0,sp,48
    80004128:	892a                	mv	s2,a0
    8000412a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000412c:	0001d497          	auipc	s1,0x1d
    80004130:	a4448493          	addi	s1,s1,-1468 # 80020b70 <log>
    80004134:	00004597          	auipc	a1,0x4
    80004138:	53c58593          	addi	a1,a1,1340 # 80008670 <syscalls+0x1e0>
    8000413c:	8526                	mv	a0,s1
    8000413e:	ffffd097          	auipc	ra,0xffffd
    80004142:	a08080e7          	jalr	-1528(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004146:	0149a583          	lw	a1,20(s3)
    8000414a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000414c:	0109a783          	lw	a5,16(s3)
    80004150:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004152:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004156:	854a                	mv	a0,s2
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	e84080e7          	jalr	-380(ra) # 80002fdc <bread>
  log.lh.n = lh->n;
    80004160:	4d34                	lw	a3,88(a0)
    80004162:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004164:	02d05663          	blez	a3,80004190 <initlog+0x76>
    80004168:	05c50793          	addi	a5,a0,92
    8000416c:	0001d717          	auipc	a4,0x1d
    80004170:	a3470713          	addi	a4,a4,-1484 # 80020ba0 <log+0x30>
    80004174:	36fd                	addiw	a3,a3,-1
    80004176:	02069613          	slli	a2,a3,0x20
    8000417a:	01e65693          	srli	a3,a2,0x1e
    8000417e:	06050613          	addi	a2,a0,96
    80004182:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004184:	4390                	lw	a2,0(a5)
    80004186:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004188:	0791                	addi	a5,a5,4
    8000418a:	0711                	addi	a4,a4,4
    8000418c:	fed79ce3          	bne	a5,a3,80004184 <initlog+0x6a>
  brelse(buf);
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	f7c080e7          	jalr	-132(ra) # 8000310c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004198:	4505                	li	a0,1
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	ebc080e7          	jalr	-324(ra) # 80004056 <install_trans>
  log.lh.n = 0;
    800041a2:	0001d797          	auipc	a5,0x1d
    800041a6:	9e07ad23          	sw	zero,-1542(a5) # 80020b9c <log+0x2c>
  write_head(); // clear the log
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	e30080e7          	jalr	-464(ra) # 80003fda <write_head>
}
    800041b2:	70a2                	ld	ra,40(sp)
    800041b4:	7402                	ld	s0,32(sp)
    800041b6:	64e2                	ld	s1,24(sp)
    800041b8:	6942                	ld	s2,16(sp)
    800041ba:	69a2                	ld	s3,8(sp)
    800041bc:	6145                	addi	sp,sp,48
    800041be:	8082                	ret

00000000800041c0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041c0:	1101                	addi	sp,sp,-32
    800041c2:	ec06                	sd	ra,24(sp)
    800041c4:	e822                	sd	s0,16(sp)
    800041c6:	e426                	sd	s1,8(sp)
    800041c8:	e04a                	sd	s2,0(sp)
    800041ca:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041cc:	0001d517          	auipc	a0,0x1d
    800041d0:	9a450513          	addi	a0,a0,-1628 # 80020b70 <log>
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	a02080e7          	jalr	-1534(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800041dc:	0001d497          	auipc	s1,0x1d
    800041e0:	99448493          	addi	s1,s1,-1644 # 80020b70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041e4:	4979                	li	s2,30
    800041e6:	a039                	j	800041f4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041e8:	85a6                	mv	a1,s1
    800041ea:	8526                	mv	a0,s1
    800041ec:	ffffe097          	auipc	ra,0xffffe
    800041f0:	e68080e7          	jalr	-408(ra) # 80002054 <sleep>
    if(log.committing){
    800041f4:	50dc                	lw	a5,36(s1)
    800041f6:	fbed                	bnez	a5,800041e8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041f8:	5098                	lw	a4,32(s1)
    800041fa:	2705                	addiw	a4,a4,1
    800041fc:	0007069b          	sext.w	a3,a4
    80004200:	0027179b          	slliw	a5,a4,0x2
    80004204:	9fb9                	addw	a5,a5,a4
    80004206:	0017979b          	slliw	a5,a5,0x1
    8000420a:	54d8                	lw	a4,44(s1)
    8000420c:	9fb9                	addw	a5,a5,a4
    8000420e:	00f95963          	bge	s2,a5,80004220 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004212:	85a6                	mv	a1,s1
    80004214:	8526                	mv	a0,s1
    80004216:	ffffe097          	auipc	ra,0xffffe
    8000421a:	e3e080e7          	jalr	-450(ra) # 80002054 <sleep>
    8000421e:	bfd9                	j	800041f4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004220:	0001d517          	auipc	a0,0x1d
    80004224:	95050513          	addi	a0,a0,-1712 # 80020b70 <log>
    80004228:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000422a:	ffffd097          	auipc	ra,0xffffd
    8000422e:	a60080e7          	jalr	-1440(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004232:	60e2                	ld	ra,24(sp)
    80004234:	6442                	ld	s0,16(sp)
    80004236:	64a2                	ld	s1,8(sp)
    80004238:	6902                	ld	s2,0(sp)
    8000423a:	6105                	addi	sp,sp,32
    8000423c:	8082                	ret

000000008000423e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000423e:	7139                	addi	sp,sp,-64
    80004240:	fc06                	sd	ra,56(sp)
    80004242:	f822                	sd	s0,48(sp)
    80004244:	f426                	sd	s1,40(sp)
    80004246:	f04a                	sd	s2,32(sp)
    80004248:	ec4e                	sd	s3,24(sp)
    8000424a:	e852                	sd	s4,16(sp)
    8000424c:	e456                	sd	s5,8(sp)
    8000424e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004250:	0001d497          	auipc	s1,0x1d
    80004254:	92048493          	addi	s1,s1,-1760 # 80020b70 <log>
    80004258:	8526                	mv	a0,s1
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	97c080e7          	jalr	-1668(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004262:	509c                	lw	a5,32(s1)
    80004264:	37fd                	addiw	a5,a5,-1
    80004266:	0007891b          	sext.w	s2,a5
    8000426a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000426c:	50dc                	lw	a5,36(s1)
    8000426e:	e7b9                	bnez	a5,800042bc <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004270:	04091e63          	bnez	s2,800042cc <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004274:	0001d497          	auipc	s1,0x1d
    80004278:	8fc48493          	addi	s1,s1,-1796 # 80020b70 <log>
    8000427c:	4785                	li	a5,1
    8000427e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004280:	8526                	mv	a0,s1
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	a08080e7          	jalr	-1528(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000428a:	54dc                	lw	a5,44(s1)
    8000428c:	06f04763          	bgtz	a5,800042fa <end_op+0xbc>
    acquire(&log.lock);
    80004290:	0001d497          	auipc	s1,0x1d
    80004294:	8e048493          	addi	s1,s1,-1824 # 80020b70 <log>
    80004298:	8526                	mv	a0,s1
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	93c080e7          	jalr	-1732(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800042a2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042a6:	8526                	mv	a0,s1
    800042a8:	ffffe097          	auipc	ra,0xffffe
    800042ac:	e10080e7          	jalr	-496(ra) # 800020b8 <wakeup>
    release(&log.lock);
    800042b0:	8526                	mv	a0,s1
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
}
    800042ba:	a03d                	j	800042e8 <end_op+0xaa>
    panic("log.committing");
    800042bc:	00004517          	auipc	a0,0x4
    800042c0:	3bc50513          	addi	a0,a0,956 # 80008678 <syscalls+0x1e8>
    800042c4:	ffffc097          	auipc	ra,0xffffc
    800042c8:	27c080e7          	jalr	636(ra) # 80000540 <panic>
    wakeup(&log);
    800042cc:	0001d497          	auipc	s1,0x1d
    800042d0:	8a448493          	addi	s1,s1,-1884 # 80020b70 <log>
    800042d4:	8526                	mv	a0,s1
    800042d6:	ffffe097          	auipc	ra,0xffffe
    800042da:	de2080e7          	jalr	-542(ra) # 800020b8 <wakeup>
  release(&log.lock);
    800042de:	8526                	mv	a0,s1
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	9aa080e7          	jalr	-1622(ra) # 80000c8a <release>
}
    800042e8:	70e2                	ld	ra,56(sp)
    800042ea:	7442                	ld	s0,48(sp)
    800042ec:	74a2                	ld	s1,40(sp)
    800042ee:	7902                	ld	s2,32(sp)
    800042f0:	69e2                	ld	s3,24(sp)
    800042f2:	6a42                	ld	s4,16(sp)
    800042f4:	6aa2                	ld	s5,8(sp)
    800042f6:	6121                	addi	sp,sp,64
    800042f8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042fa:	0001da97          	auipc	s5,0x1d
    800042fe:	8a6a8a93          	addi	s5,s5,-1882 # 80020ba0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004302:	0001da17          	auipc	s4,0x1d
    80004306:	86ea0a13          	addi	s4,s4,-1938 # 80020b70 <log>
    8000430a:	018a2583          	lw	a1,24(s4)
    8000430e:	012585bb          	addw	a1,a1,s2
    80004312:	2585                	addiw	a1,a1,1
    80004314:	028a2503          	lw	a0,40(s4)
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	cc4080e7          	jalr	-828(ra) # 80002fdc <bread>
    80004320:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004322:	000aa583          	lw	a1,0(s5)
    80004326:	028a2503          	lw	a0,40(s4)
    8000432a:	fffff097          	auipc	ra,0xfffff
    8000432e:	cb2080e7          	jalr	-846(ra) # 80002fdc <bread>
    80004332:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004334:	40000613          	li	a2,1024
    80004338:	05850593          	addi	a1,a0,88
    8000433c:	05848513          	addi	a0,s1,88
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	9ee080e7          	jalr	-1554(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004348:	8526                	mv	a0,s1
    8000434a:	fffff097          	auipc	ra,0xfffff
    8000434e:	d84080e7          	jalr	-636(ra) # 800030ce <bwrite>
    brelse(from);
    80004352:	854e                	mv	a0,s3
    80004354:	fffff097          	auipc	ra,0xfffff
    80004358:	db8080e7          	jalr	-584(ra) # 8000310c <brelse>
    brelse(to);
    8000435c:	8526                	mv	a0,s1
    8000435e:	fffff097          	auipc	ra,0xfffff
    80004362:	dae080e7          	jalr	-594(ra) # 8000310c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004366:	2905                	addiw	s2,s2,1
    80004368:	0a91                	addi	s5,s5,4
    8000436a:	02ca2783          	lw	a5,44(s4)
    8000436e:	f8f94ee3          	blt	s2,a5,8000430a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004372:	00000097          	auipc	ra,0x0
    80004376:	c68080e7          	jalr	-920(ra) # 80003fda <write_head>
    install_trans(0); // Now install writes to home locations
    8000437a:	4501                	li	a0,0
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	cda080e7          	jalr	-806(ra) # 80004056 <install_trans>
    log.lh.n = 0;
    80004384:	0001d797          	auipc	a5,0x1d
    80004388:	8007ac23          	sw	zero,-2024(a5) # 80020b9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000438c:	00000097          	auipc	ra,0x0
    80004390:	c4e080e7          	jalr	-946(ra) # 80003fda <write_head>
    80004394:	bdf5                	j	80004290 <end_op+0x52>

0000000080004396 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004396:	1101                	addi	sp,sp,-32
    80004398:	ec06                	sd	ra,24(sp)
    8000439a:	e822                	sd	s0,16(sp)
    8000439c:	e426                	sd	s1,8(sp)
    8000439e:	e04a                	sd	s2,0(sp)
    800043a0:	1000                	addi	s0,sp,32
    800043a2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043a4:	0001c917          	auipc	s2,0x1c
    800043a8:	7cc90913          	addi	s2,s2,1996 # 80020b70 <log>
    800043ac:	854a                	mv	a0,s2
    800043ae:	ffffd097          	auipc	ra,0xffffd
    800043b2:	828080e7          	jalr	-2008(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043b6:	02c92603          	lw	a2,44(s2)
    800043ba:	47f5                	li	a5,29
    800043bc:	06c7c563          	blt	a5,a2,80004426 <log_write+0x90>
    800043c0:	0001c797          	auipc	a5,0x1c
    800043c4:	7cc7a783          	lw	a5,1996(a5) # 80020b8c <log+0x1c>
    800043c8:	37fd                	addiw	a5,a5,-1
    800043ca:	04f65e63          	bge	a2,a5,80004426 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043ce:	0001c797          	auipc	a5,0x1c
    800043d2:	7c27a783          	lw	a5,1986(a5) # 80020b90 <log+0x20>
    800043d6:	06f05063          	blez	a5,80004436 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043da:	4781                	li	a5,0
    800043dc:	06c05563          	blez	a2,80004446 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043e0:	44cc                	lw	a1,12(s1)
    800043e2:	0001c717          	auipc	a4,0x1c
    800043e6:	7be70713          	addi	a4,a4,1982 # 80020ba0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043ea:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043ec:	4314                	lw	a3,0(a4)
    800043ee:	04b68c63          	beq	a3,a1,80004446 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043f2:	2785                	addiw	a5,a5,1
    800043f4:	0711                	addi	a4,a4,4
    800043f6:	fef61be3          	bne	a2,a5,800043ec <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043fa:	0621                	addi	a2,a2,8
    800043fc:	060a                	slli	a2,a2,0x2
    800043fe:	0001c797          	auipc	a5,0x1c
    80004402:	77278793          	addi	a5,a5,1906 # 80020b70 <log>
    80004406:	97b2                	add	a5,a5,a2
    80004408:	44d8                	lw	a4,12(s1)
    8000440a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000440c:	8526                	mv	a0,s1
    8000440e:	fffff097          	auipc	ra,0xfffff
    80004412:	d9c080e7          	jalr	-612(ra) # 800031aa <bpin>
    log.lh.n++;
    80004416:	0001c717          	auipc	a4,0x1c
    8000441a:	75a70713          	addi	a4,a4,1882 # 80020b70 <log>
    8000441e:	575c                	lw	a5,44(a4)
    80004420:	2785                	addiw	a5,a5,1
    80004422:	d75c                	sw	a5,44(a4)
    80004424:	a82d                	j	8000445e <log_write+0xc8>
    panic("too big a transaction");
    80004426:	00004517          	auipc	a0,0x4
    8000442a:	26250513          	addi	a0,a0,610 # 80008688 <syscalls+0x1f8>
    8000442e:	ffffc097          	auipc	ra,0xffffc
    80004432:	112080e7          	jalr	274(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004436:	00004517          	auipc	a0,0x4
    8000443a:	26a50513          	addi	a0,a0,618 # 800086a0 <syscalls+0x210>
    8000443e:	ffffc097          	auipc	ra,0xffffc
    80004442:	102080e7          	jalr	258(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004446:	00878693          	addi	a3,a5,8
    8000444a:	068a                	slli	a3,a3,0x2
    8000444c:	0001c717          	auipc	a4,0x1c
    80004450:	72470713          	addi	a4,a4,1828 # 80020b70 <log>
    80004454:	9736                	add	a4,a4,a3
    80004456:	44d4                	lw	a3,12(s1)
    80004458:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000445a:	faf609e3          	beq	a2,a5,8000440c <log_write+0x76>
  }
  release(&log.lock);
    8000445e:	0001c517          	auipc	a0,0x1c
    80004462:	71250513          	addi	a0,a0,1810 # 80020b70 <log>
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	824080e7          	jalr	-2012(ra) # 80000c8a <release>
}
    8000446e:	60e2                	ld	ra,24(sp)
    80004470:	6442                	ld	s0,16(sp)
    80004472:	64a2                	ld	s1,8(sp)
    80004474:	6902                	ld	s2,0(sp)
    80004476:	6105                	addi	sp,sp,32
    80004478:	8082                	ret

000000008000447a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000447a:	1101                	addi	sp,sp,-32
    8000447c:	ec06                	sd	ra,24(sp)
    8000447e:	e822                	sd	s0,16(sp)
    80004480:	e426                	sd	s1,8(sp)
    80004482:	e04a                	sd	s2,0(sp)
    80004484:	1000                	addi	s0,sp,32
    80004486:	84aa                	mv	s1,a0
    80004488:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000448a:	00004597          	auipc	a1,0x4
    8000448e:	23658593          	addi	a1,a1,566 # 800086c0 <syscalls+0x230>
    80004492:	0521                	addi	a0,a0,8
    80004494:	ffffc097          	auipc	ra,0xffffc
    80004498:	6b2080e7          	jalr	1714(ra) # 80000b46 <initlock>
  lk->name = name;
    8000449c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044a0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044a4:	0204a423          	sw	zero,40(s1)
}
    800044a8:	60e2                	ld	ra,24(sp)
    800044aa:	6442                	ld	s0,16(sp)
    800044ac:	64a2                	ld	s1,8(sp)
    800044ae:	6902                	ld	s2,0(sp)
    800044b0:	6105                	addi	sp,sp,32
    800044b2:	8082                	ret

00000000800044b4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044b4:	1101                	addi	sp,sp,-32
    800044b6:	ec06                	sd	ra,24(sp)
    800044b8:	e822                	sd	s0,16(sp)
    800044ba:	e426                	sd	s1,8(sp)
    800044bc:	e04a                	sd	s2,0(sp)
    800044be:	1000                	addi	s0,sp,32
    800044c0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044c2:	00850913          	addi	s2,a0,8
    800044c6:	854a                	mv	a0,s2
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	70e080e7          	jalr	1806(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800044d0:	409c                	lw	a5,0(s1)
    800044d2:	cb89                	beqz	a5,800044e4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044d4:	85ca                	mv	a1,s2
    800044d6:	8526                	mv	a0,s1
    800044d8:	ffffe097          	auipc	ra,0xffffe
    800044dc:	b7c080e7          	jalr	-1156(ra) # 80002054 <sleep>
  while (lk->locked) {
    800044e0:	409c                	lw	a5,0(s1)
    800044e2:	fbed                	bnez	a5,800044d4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044e4:	4785                	li	a5,1
    800044e6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044e8:	ffffd097          	auipc	ra,0xffffd
    800044ec:	4c4080e7          	jalr	1220(ra) # 800019ac <myproc>
    800044f0:	591c                	lw	a5,48(a0)
    800044f2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044f4:	854a                	mv	a0,s2
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	794080e7          	jalr	1940(ra) # 80000c8a <release>
}
    800044fe:	60e2                	ld	ra,24(sp)
    80004500:	6442                	ld	s0,16(sp)
    80004502:	64a2                	ld	s1,8(sp)
    80004504:	6902                	ld	s2,0(sp)
    80004506:	6105                	addi	sp,sp,32
    80004508:	8082                	ret

000000008000450a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000450a:	1101                	addi	sp,sp,-32
    8000450c:	ec06                	sd	ra,24(sp)
    8000450e:	e822                	sd	s0,16(sp)
    80004510:	e426                	sd	s1,8(sp)
    80004512:	e04a                	sd	s2,0(sp)
    80004514:	1000                	addi	s0,sp,32
    80004516:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004518:	00850913          	addi	s2,a0,8
    8000451c:	854a                	mv	a0,s2
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	6b8080e7          	jalr	1720(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004526:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000452a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000452e:	8526                	mv	a0,s1
    80004530:	ffffe097          	auipc	ra,0xffffe
    80004534:	b88080e7          	jalr	-1144(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    80004538:	854a                	mv	a0,s2
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	750080e7          	jalr	1872(ra) # 80000c8a <release>
}
    80004542:	60e2                	ld	ra,24(sp)
    80004544:	6442                	ld	s0,16(sp)
    80004546:	64a2                	ld	s1,8(sp)
    80004548:	6902                	ld	s2,0(sp)
    8000454a:	6105                	addi	sp,sp,32
    8000454c:	8082                	ret

000000008000454e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000454e:	7179                	addi	sp,sp,-48
    80004550:	f406                	sd	ra,40(sp)
    80004552:	f022                	sd	s0,32(sp)
    80004554:	ec26                	sd	s1,24(sp)
    80004556:	e84a                	sd	s2,16(sp)
    80004558:	e44e                	sd	s3,8(sp)
    8000455a:	1800                	addi	s0,sp,48
    8000455c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000455e:	00850913          	addi	s2,a0,8
    80004562:	854a                	mv	a0,s2
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	672080e7          	jalr	1650(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000456c:	409c                	lw	a5,0(s1)
    8000456e:	ef99                	bnez	a5,8000458c <holdingsleep+0x3e>
    80004570:	4481                	li	s1,0
  release(&lk->lk);
    80004572:	854a                	mv	a0,s2
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	716080e7          	jalr	1814(ra) # 80000c8a <release>
  return r;
}
    8000457c:	8526                	mv	a0,s1
    8000457e:	70a2                	ld	ra,40(sp)
    80004580:	7402                	ld	s0,32(sp)
    80004582:	64e2                	ld	s1,24(sp)
    80004584:	6942                	ld	s2,16(sp)
    80004586:	69a2                	ld	s3,8(sp)
    80004588:	6145                	addi	sp,sp,48
    8000458a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000458c:	0284a983          	lw	s3,40(s1)
    80004590:	ffffd097          	auipc	ra,0xffffd
    80004594:	41c080e7          	jalr	1052(ra) # 800019ac <myproc>
    80004598:	5904                	lw	s1,48(a0)
    8000459a:	413484b3          	sub	s1,s1,s3
    8000459e:	0014b493          	seqz	s1,s1
    800045a2:	bfc1                	j	80004572 <holdingsleep+0x24>

00000000800045a4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045a4:	1141                	addi	sp,sp,-16
    800045a6:	e406                	sd	ra,8(sp)
    800045a8:	e022                	sd	s0,0(sp)
    800045aa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045ac:	00004597          	auipc	a1,0x4
    800045b0:	12458593          	addi	a1,a1,292 # 800086d0 <syscalls+0x240>
    800045b4:	0001c517          	auipc	a0,0x1c
    800045b8:	70450513          	addi	a0,a0,1796 # 80020cb8 <ftable>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	58a080e7          	jalr	1418(ra) # 80000b46 <initlock>
}
    800045c4:	60a2                	ld	ra,8(sp)
    800045c6:	6402                	ld	s0,0(sp)
    800045c8:	0141                	addi	sp,sp,16
    800045ca:	8082                	ret

00000000800045cc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045cc:	1101                	addi	sp,sp,-32
    800045ce:	ec06                	sd	ra,24(sp)
    800045d0:	e822                	sd	s0,16(sp)
    800045d2:	e426                	sd	s1,8(sp)
    800045d4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045d6:	0001c517          	auipc	a0,0x1c
    800045da:	6e250513          	addi	a0,a0,1762 # 80020cb8 <ftable>
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	5f8080e7          	jalr	1528(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045e6:	0001c497          	auipc	s1,0x1c
    800045ea:	6ea48493          	addi	s1,s1,1770 # 80020cd0 <ftable+0x18>
    800045ee:	0001d717          	auipc	a4,0x1d
    800045f2:	68270713          	addi	a4,a4,1666 # 80021c70 <disk>
    if(f->ref == 0){
    800045f6:	40dc                	lw	a5,4(s1)
    800045f8:	cf99                	beqz	a5,80004616 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045fa:	02848493          	addi	s1,s1,40
    800045fe:	fee49ce3          	bne	s1,a4,800045f6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004602:	0001c517          	auipc	a0,0x1c
    80004606:	6b650513          	addi	a0,a0,1718 # 80020cb8 <ftable>
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	680080e7          	jalr	1664(ra) # 80000c8a <release>
  return 0;
    80004612:	4481                	li	s1,0
    80004614:	a819                	j	8000462a <filealloc+0x5e>
      f->ref = 1;
    80004616:	4785                	li	a5,1
    80004618:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000461a:	0001c517          	auipc	a0,0x1c
    8000461e:	69e50513          	addi	a0,a0,1694 # 80020cb8 <ftable>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	668080e7          	jalr	1640(ra) # 80000c8a <release>
}
    8000462a:	8526                	mv	a0,s1
    8000462c:	60e2                	ld	ra,24(sp)
    8000462e:	6442                	ld	s0,16(sp)
    80004630:	64a2                	ld	s1,8(sp)
    80004632:	6105                	addi	sp,sp,32
    80004634:	8082                	ret

0000000080004636 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004636:	1101                	addi	sp,sp,-32
    80004638:	ec06                	sd	ra,24(sp)
    8000463a:	e822                	sd	s0,16(sp)
    8000463c:	e426                	sd	s1,8(sp)
    8000463e:	1000                	addi	s0,sp,32
    80004640:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004642:	0001c517          	auipc	a0,0x1c
    80004646:	67650513          	addi	a0,a0,1654 # 80020cb8 <ftable>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	58c080e7          	jalr	1420(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004652:	40dc                	lw	a5,4(s1)
    80004654:	02f05263          	blez	a5,80004678 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004658:	2785                	addiw	a5,a5,1
    8000465a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000465c:	0001c517          	auipc	a0,0x1c
    80004660:	65c50513          	addi	a0,a0,1628 # 80020cb8 <ftable>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	626080e7          	jalr	1574(ra) # 80000c8a <release>
  return f;
}
    8000466c:	8526                	mv	a0,s1
    8000466e:	60e2                	ld	ra,24(sp)
    80004670:	6442                	ld	s0,16(sp)
    80004672:	64a2                	ld	s1,8(sp)
    80004674:	6105                	addi	sp,sp,32
    80004676:	8082                	ret
    panic("filedup");
    80004678:	00004517          	auipc	a0,0x4
    8000467c:	06050513          	addi	a0,a0,96 # 800086d8 <syscalls+0x248>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	ec0080e7          	jalr	-320(ra) # 80000540 <panic>

0000000080004688 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004688:	7139                	addi	sp,sp,-64
    8000468a:	fc06                	sd	ra,56(sp)
    8000468c:	f822                	sd	s0,48(sp)
    8000468e:	f426                	sd	s1,40(sp)
    80004690:	f04a                	sd	s2,32(sp)
    80004692:	ec4e                	sd	s3,24(sp)
    80004694:	e852                	sd	s4,16(sp)
    80004696:	e456                	sd	s5,8(sp)
    80004698:	0080                	addi	s0,sp,64
    8000469a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000469c:	0001c517          	auipc	a0,0x1c
    800046a0:	61c50513          	addi	a0,a0,1564 # 80020cb8 <ftable>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	532080e7          	jalr	1330(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800046ac:	40dc                	lw	a5,4(s1)
    800046ae:	06f05163          	blez	a5,80004710 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046b2:	37fd                	addiw	a5,a5,-1
    800046b4:	0007871b          	sext.w	a4,a5
    800046b8:	c0dc                	sw	a5,4(s1)
    800046ba:	06e04363          	bgtz	a4,80004720 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046be:	0004a903          	lw	s2,0(s1)
    800046c2:	0094ca83          	lbu	s5,9(s1)
    800046c6:	0104ba03          	ld	s4,16(s1)
    800046ca:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046ce:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046d2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046d6:	0001c517          	auipc	a0,0x1c
    800046da:	5e250513          	addi	a0,a0,1506 # 80020cb8 <ftable>
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	5ac080e7          	jalr	1452(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800046e6:	4785                	li	a5,1
    800046e8:	04f90d63          	beq	s2,a5,80004742 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046ec:	3979                	addiw	s2,s2,-2
    800046ee:	4785                	li	a5,1
    800046f0:	0527e063          	bltu	a5,s2,80004730 <fileclose+0xa8>
    begin_op();
    800046f4:	00000097          	auipc	ra,0x0
    800046f8:	acc080e7          	jalr	-1332(ra) # 800041c0 <begin_op>
    iput(ff.ip);
    800046fc:	854e                	mv	a0,s3
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	2b0080e7          	jalr	688(ra) # 800039ae <iput>
    end_op();
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	b38080e7          	jalr	-1224(ra) # 8000423e <end_op>
    8000470e:	a00d                	j	80004730 <fileclose+0xa8>
    panic("fileclose");
    80004710:	00004517          	auipc	a0,0x4
    80004714:	fd050513          	addi	a0,a0,-48 # 800086e0 <syscalls+0x250>
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	e28080e7          	jalr	-472(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004720:	0001c517          	auipc	a0,0x1c
    80004724:	59850513          	addi	a0,a0,1432 # 80020cb8 <ftable>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	562080e7          	jalr	1378(ra) # 80000c8a <release>
  }
}
    80004730:	70e2                	ld	ra,56(sp)
    80004732:	7442                	ld	s0,48(sp)
    80004734:	74a2                	ld	s1,40(sp)
    80004736:	7902                	ld	s2,32(sp)
    80004738:	69e2                	ld	s3,24(sp)
    8000473a:	6a42                	ld	s4,16(sp)
    8000473c:	6aa2                	ld	s5,8(sp)
    8000473e:	6121                	addi	sp,sp,64
    80004740:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004742:	85d6                	mv	a1,s5
    80004744:	8552                	mv	a0,s4
    80004746:	00000097          	auipc	ra,0x0
    8000474a:	34c080e7          	jalr	844(ra) # 80004a92 <pipeclose>
    8000474e:	b7cd                	j	80004730 <fileclose+0xa8>

0000000080004750 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004750:	715d                	addi	sp,sp,-80
    80004752:	e486                	sd	ra,72(sp)
    80004754:	e0a2                	sd	s0,64(sp)
    80004756:	fc26                	sd	s1,56(sp)
    80004758:	f84a                	sd	s2,48(sp)
    8000475a:	f44e                	sd	s3,40(sp)
    8000475c:	0880                	addi	s0,sp,80
    8000475e:	84aa                	mv	s1,a0
    80004760:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004762:	ffffd097          	auipc	ra,0xffffd
    80004766:	24a080e7          	jalr	586(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000476a:	409c                	lw	a5,0(s1)
    8000476c:	37f9                	addiw	a5,a5,-2
    8000476e:	4705                	li	a4,1
    80004770:	04f76763          	bltu	a4,a5,800047be <filestat+0x6e>
    80004774:	892a                	mv	s2,a0
    ilock(f->ip);
    80004776:	6c88                	ld	a0,24(s1)
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	07c080e7          	jalr	124(ra) # 800037f4 <ilock>
    stati(f->ip, &st);
    80004780:	fb840593          	addi	a1,s0,-72
    80004784:	6c88                	ld	a0,24(s1)
    80004786:	fffff097          	auipc	ra,0xfffff
    8000478a:	2f8080e7          	jalr	760(ra) # 80003a7e <stati>
    iunlock(f->ip);
    8000478e:	6c88                	ld	a0,24(s1)
    80004790:	fffff097          	auipc	ra,0xfffff
    80004794:	126080e7          	jalr	294(ra) # 800038b6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004798:	46e1                	li	a3,24
    8000479a:	fb840613          	addi	a2,s0,-72
    8000479e:	85ce                	mv	a1,s3
    800047a0:	05093503          	ld	a0,80(s2)
    800047a4:	ffffd097          	auipc	ra,0xffffd
    800047a8:	ec8080e7          	jalr	-312(ra) # 8000166c <copyout>
    800047ac:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047b0:	60a6                	ld	ra,72(sp)
    800047b2:	6406                	ld	s0,64(sp)
    800047b4:	74e2                	ld	s1,56(sp)
    800047b6:	7942                	ld	s2,48(sp)
    800047b8:	79a2                	ld	s3,40(sp)
    800047ba:	6161                	addi	sp,sp,80
    800047bc:	8082                	ret
  return -1;
    800047be:	557d                	li	a0,-1
    800047c0:	bfc5                	j	800047b0 <filestat+0x60>

00000000800047c2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047c2:	7179                	addi	sp,sp,-48
    800047c4:	f406                	sd	ra,40(sp)
    800047c6:	f022                	sd	s0,32(sp)
    800047c8:	ec26                	sd	s1,24(sp)
    800047ca:	e84a                	sd	s2,16(sp)
    800047cc:	e44e                	sd	s3,8(sp)
    800047ce:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047d0:	00854783          	lbu	a5,8(a0)
    800047d4:	c3d5                	beqz	a5,80004878 <fileread+0xb6>
    800047d6:	84aa                	mv	s1,a0
    800047d8:	89ae                	mv	s3,a1
    800047da:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047dc:	411c                	lw	a5,0(a0)
    800047de:	4705                	li	a4,1
    800047e0:	04e78963          	beq	a5,a4,80004832 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047e4:	470d                	li	a4,3
    800047e6:	04e78d63          	beq	a5,a4,80004840 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ea:	4709                	li	a4,2
    800047ec:	06e79e63          	bne	a5,a4,80004868 <fileread+0xa6>
    ilock(f->ip);
    800047f0:	6d08                	ld	a0,24(a0)
    800047f2:	fffff097          	auipc	ra,0xfffff
    800047f6:	002080e7          	jalr	2(ra) # 800037f4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047fa:	874a                	mv	a4,s2
    800047fc:	5094                	lw	a3,32(s1)
    800047fe:	864e                	mv	a2,s3
    80004800:	4585                	li	a1,1
    80004802:	6c88                	ld	a0,24(s1)
    80004804:	fffff097          	auipc	ra,0xfffff
    80004808:	2a4080e7          	jalr	676(ra) # 80003aa8 <readi>
    8000480c:	892a                	mv	s2,a0
    8000480e:	00a05563          	blez	a0,80004818 <fileread+0x56>
      f->off += r;
    80004812:	509c                	lw	a5,32(s1)
    80004814:	9fa9                	addw	a5,a5,a0
    80004816:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004818:	6c88                	ld	a0,24(s1)
    8000481a:	fffff097          	auipc	ra,0xfffff
    8000481e:	09c080e7          	jalr	156(ra) # 800038b6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004822:	854a                	mv	a0,s2
    80004824:	70a2                	ld	ra,40(sp)
    80004826:	7402                	ld	s0,32(sp)
    80004828:	64e2                	ld	s1,24(sp)
    8000482a:	6942                	ld	s2,16(sp)
    8000482c:	69a2                	ld	s3,8(sp)
    8000482e:	6145                	addi	sp,sp,48
    80004830:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004832:	6908                	ld	a0,16(a0)
    80004834:	00000097          	auipc	ra,0x0
    80004838:	3c6080e7          	jalr	966(ra) # 80004bfa <piperead>
    8000483c:	892a                	mv	s2,a0
    8000483e:	b7d5                	j	80004822 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004840:	02451783          	lh	a5,36(a0)
    80004844:	03079693          	slli	a3,a5,0x30
    80004848:	92c1                	srli	a3,a3,0x30
    8000484a:	4725                	li	a4,9
    8000484c:	02d76863          	bltu	a4,a3,8000487c <fileread+0xba>
    80004850:	0792                	slli	a5,a5,0x4
    80004852:	0001c717          	auipc	a4,0x1c
    80004856:	3c670713          	addi	a4,a4,966 # 80020c18 <devsw>
    8000485a:	97ba                	add	a5,a5,a4
    8000485c:	639c                	ld	a5,0(a5)
    8000485e:	c38d                	beqz	a5,80004880 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004860:	4505                	li	a0,1
    80004862:	9782                	jalr	a5
    80004864:	892a                	mv	s2,a0
    80004866:	bf75                	j	80004822 <fileread+0x60>
    panic("fileread");
    80004868:	00004517          	auipc	a0,0x4
    8000486c:	e8850513          	addi	a0,a0,-376 # 800086f0 <syscalls+0x260>
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	cd0080e7          	jalr	-816(ra) # 80000540 <panic>
    return -1;
    80004878:	597d                	li	s2,-1
    8000487a:	b765                	j	80004822 <fileread+0x60>
      return -1;
    8000487c:	597d                	li	s2,-1
    8000487e:	b755                	j	80004822 <fileread+0x60>
    80004880:	597d                	li	s2,-1
    80004882:	b745                	j	80004822 <fileread+0x60>

0000000080004884 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004884:	715d                	addi	sp,sp,-80
    80004886:	e486                	sd	ra,72(sp)
    80004888:	e0a2                	sd	s0,64(sp)
    8000488a:	fc26                	sd	s1,56(sp)
    8000488c:	f84a                	sd	s2,48(sp)
    8000488e:	f44e                	sd	s3,40(sp)
    80004890:	f052                	sd	s4,32(sp)
    80004892:	ec56                	sd	s5,24(sp)
    80004894:	e85a                	sd	s6,16(sp)
    80004896:	e45e                	sd	s7,8(sp)
    80004898:	e062                	sd	s8,0(sp)
    8000489a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000489c:	00954783          	lbu	a5,9(a0)
    800048a0:	10078663          	beqz	a5,800049ac <filewrite+0x128>
    800048a4:	892a                	mv	s2,a0
    800048a6:	8b2e                	mv	s6,a1
    800048a8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048aa:	411c                	lw	a5,0(a0)
    800048ac:	4705                	li	a4,1
    800048ae:	02e78263          	beq	a5,a4,800048d2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048b2:	470d                	li	a4,3
    800048b4:	02e78663          	beq	a5,a4,800048e0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048b8:	4709                	li	a4,2
    800048ba:	0ee79163          	bne	a5,a4,8000499c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048be:	0ac05d63          	blez	a2,80004978 <filewrite+0xf4>
    int i = 0;
    800048c2:	4981                	li	s3,0
    800048c4:	6b85                	lui	s7,0x1
    800048c6:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800048ca:	6c05                	lui	s8,0x1
    800048cc:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800048d0:	a861                	j	80004968 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048d2:	6908                	ld	a0,16(a0)
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	22e080e7          	jalr	558(ra) # 80004b02 <pipewrite>
    800048dc:	8a2a                	mv	s4,a0
    800048de:	a045                	j	8000497e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048e0:	02451783          	lh	a5,36(a0)
    800048e4:	03079693          	slli	a3,a5,0x30
    800048e8:	92c1                	srli	a3,a3,0x30
    800048ea:	4725                	li	a4,9
    800048ec:	0cd76263          	bltu	a4,a3,800049b0 <filewrite+0x12c>
    800048f0:	0792                	slli	a5,a5,0x4
    800048f2:	0001c717          	auipc	a4,0x1c
    800048f6:	32670713          	addi	a4,a4,806 # 80020c18 <devsw>
    800048fa:	97ba                	add	a5,a5,a4
    800048fc:	679c                	ld	a5,8(a5)
    800048fe:	cbdd                	beqz	a5,800049b4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004900:	4505                	li	a0,1
    80004902:	9782                	jalr	a5
    80004904:	8a2a                	mv	s4,a0
    80004906:	a8a5                	j	8000497e <filewrite+0xfa>
    80004908:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000490c:	00000097          	auipc	ra,0x0
    80004910:	8b4080e7          	jalr	-1868(ra) # 800041c0 <begin_op>
      ilock(f->ip);
    80004914:	01893503          	ld	a0,24(s2)
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	edc080e7          	jalr	-292(ra) # 800037f4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004920:	8756                	mv	a4,s5
    80004922:	02092683          	lw	a3,32(s2)
    80004926:	01698633          	add	a2,s3,s6
    8000492a:	4585                	li	a1,1
    8000492c:	01893503          	ld	a0,24(s2)
    80004930:	fffff097          	auipc	ra,0xfffff
    80004934:	270080e7          	jalr	624(ra) # 80003ba0 <writei>
    80004938:	84aa                	mv	s1,a0
    8000493a:	00a05763          	blez	a0,80004948 <filewrite+0xc4>
        f->off += r;
    8000493e:	02092783          	lw	a5,32(s2)
    80004942:	9fa9                	addw	a5,a5,a0
    80004944:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004948:	01893503          	ld	a0,24(s2)
    8000494c:	fffff097          	auipc	ra,0xfffff
    80004950:	f6a080e7          	jalr	-150(ra) # 800038b6 <iunlock>
      end_op();
    80004954:	00000097          	auipc	ra,0x0
    80004958:	8ea080e7          	jalr	-1814(ra) # 8000423e <end_op>

      if(r != n1){
    8000495c:	009a9f63          	bne	s5,s1,8000497a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004960:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004964:	0149db63          	bge	s3,s4,8000497a <filewrite+0xf6>
      int n1 = n - i;
    80004968:	413a04bb          	subw	s1,s4,s3
    8000496c:	0004879b          	sext.w	a5,s1
    80004970:	f8fbdce3          	bge	s7,a5,80004908 <filewrite+0x84>
    80004974:	84e2                	mv	s1,s8
    80004976:	bf49                	j	80004908 <filewrite+0x84>
    int i = 0;
    80004978:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000497a:	013a1f63          	bne	s4,s3,80004998 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000497e:	8552                	mv	a0,s4
    80004980:	60a6                	ld	ra,72(sp)
    80004982:	6406                	ld	s0,64(sp)
    80004984:	74e2                	ld	s1,56(sp)
    80004986:	7942                	ld	s2,48(sp)
    80004988:	79a2                	ld	s3,40(sp)
    8000498a:	7a02                	ld	s4,32(sp)
    8000498c:	6ae2                	ld	s5,24(sp)
    8000498e:	6b42                	ld	s6,16(sp)
    80004990:	6ba2                	ld	s7,8(sp)
    80004992:	6c02                	ld	s8,0(sp)
    80004994:	6161                	addi	sp,sp,80
    80004996:	8082                	ret
    ret = (i == n ? n : -1);
    80004998:	5a7d                	li	s4,-1
    8000499a:	b7d5                	j	8000497e <filewrite+0xfa>
    panic("filewrite");
    8000499c:	00004517          	auipc	a0,0x4
    800049a0:	d6450513          	addi	a0,a0,-668 # 80008700 <syscalls+0x270>
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	b9c080e7          	jalr	-1124(ra) # 80000540 <panic>
    return -1;
    800049ac:	5a7d                	li	s4,-1
    800049ae:	bfc1                	j	8000497e <filewrite+0xfa>
      return -1;
    800049b0:	5a7d                	li	s4,-1
    800049b2:	b7f1                	j	8000497e <filewrite+0xfa>
    800049b4:	5a7d                	li	s4,-1
    800049b6:	b7e1                	j	8000497e <filewrite+0xfa>

00000000800049b8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049b8:	7179                	addi	sp,sp,-48
    800049ba:	f406                	sd	ra,40(sp)
    800049bc:	f022                	sd	s0,32(sp)
    800049be:	ec26                	sd	s1,24(sp)
    800049c0:	e84a                	sd	s2,16(sp)
    800049c2:	e44e                	sd	s3,8(sp)
    800049c4:	e052                	sd	s4,0(sp)
    800049c6:	1800                	addi	s0,sp,48
    800049c8:	84aa                	mv	s1,a0
    800049ca:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049cc:	0005b023          	sd	zero,0(a1)
    800049d0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049d4:	00000097          	auipc	ra,0x0
    800049d8:	bf8080e7          	jalr	-1032(ra) # 800045cc <filealloc>
    800049dc:	e088                	sd	a0,0(s1)
    800049de:	c551                	beqz	a0,80004a6a <pipealloc+0xb2>
    800049e0:	00000097          	auipc	ra,0x0
    800049e4:	bec080e7          	jalr	-1044(ra) # 800045cc <filealloc>
    800049e8:	00aa3023          	sd	a0,0(s4)
    800049ec:	c92d                	beqz	a0,80004a5e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	0f8080e7          	jalr	248(ra) # 80000ae6 <kalloc>
    800049f6:	892a                	mv	s2,a0
    800049f8:	c125                	beqz	a0,80004a58 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049fa:	4985                	li	s3,1
    800049fc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a00:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a04:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a08:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a0c:	00004597          	auipc	a1,0x4
    80004a10:	d0458593          	addi	a1,a1,-764 # 80008710 <syscalls+0x280>
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	132080e7          	jalr	306(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004a1c:	609c                	ld	a5,0(s1)
    80004a1e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a22:	609c                	ld	a5,0(s1)
    80004a24:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a28:	609c                	ld	a5,0(s1)
    80004a2a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a2e:	609c                	ld	a5,0(s1)
    80004a30:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a34:	000a3783          	ld	a5,0(s4)
    80004a38:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a3c:	000a3783          	ld	a5,0(s4)
    80004a40:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a44:	000a3783          	ld	a5,0(s4)
    80004a48:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a4c:	000a3783          	ld	a5,0(s4)
    80004a50:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a54:	4501                	li	a0,0
    80004a56:	a025                	j	80004a7e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a58:	6088                	ld	a0,0(s1)
    80004a5a:	e501                	bnez	a0,80004a62 <pipealloc+0xaa>
    80004a5c:	a039                	j	80004a6a <pipealloc+0xb2>
    80004a5e:	6088                	ld	a0,0(s1)
    80004a60:	c51d                	beqz	a0,80004a8e <pipealloc+0xd6>
    fileclose(*f0);
    80004a62:	00000097          	auipc	ra,0x0
    80004a66:	c26080e7          	jalr	-986(ra) # 80004688 <fileclose>
  if(*f1)
    80004a6a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a6e:	557d                	li	a0,-1
  if(*f1)
    80004a70:	c799                	beqz	a5,80004a7e <pipealloc+0xc6>
    fileclose(*f1);
    80004a72:	853e                	mv	a0,a5
    80004a74:	00000097          	auipc	ra,0x0
    80004a78:	c14080e7          	jalr	-1004(ra) # 80004688 <fileclose>
  return -1;
    80004a7c:	557d                	li	a0,-1
}
    80004a7e:	70a2                	ld	ra,40(sp)
    80004a80:	7402                	ld	s0,32(sp)
    80004a82:	64e2                	ld	s1,24(sp)
    80004a84:	6942                	ld	s2,16(sp)
    80004a86:	69a2                	ld	s3,8(sp)
    80004a88:	6a02                	ld	s4,0(sp)
    80004a8a:	6145                	addi	sp,sp,48
    80004a8c:	8082                	ret
  return -1;
    80004a8e:	557d                	li	a0,-1
    80004a90:	b7fd                	j	80004a7e <pipealloc+0xc6>

0000000080004a92 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a92:	1101                	addi	sp,sp,-32
    80004a94:	ec06                	sd	ra,24(sp)
    80004a96:	e822                	sd	s0,16(sp)
    80004a98:	e426                	sd	s1,8(sp)
    80004a9a:	e04a                	sd	s2,0(sp)
    80004a9c:	1000                	addi	s0,sp,32
    80004a9e:	84aa                	mv	s1,a0
    80004aa0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	134080e7          	jalr	308(ra) # 80000bd6 <acquire>
  if(writable){
    80004aaa:	02090d63          	beqz	s2,80004ae4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004aae:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ab2:	21848513          	addi	a0,s1,536
    80004ab6:	ffffd097          	auipc	ra,0xffffd
    80004aba:	602080e7          	jalr	1538(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004abe:	2204b783          	ld	a5,544(s1)
    80004ac2:	eb95                	bnez	a5,80004af6 <pipeclose+0x64>
    release(&pi->lock);
    80004ac4:	8526                	mv	a0,s1
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	1c4080e7          	jalr	452(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004ace:	8526                	mv	a0,s1
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	f18080e7          	jalr	-232(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004ad8:	60e2                	ld	ra,24(sp)
    80004ada:	6442                	ld	s0,16(sp)
    80004adc:	64a2                	ld	s1,8(sp)
    80004ade:	6902                	ld	s2,0(sp)
    80004ae0:	6105                	addi	sp,sp,32
    80004ae2:	8082                	ret
    pi->readopen = 0;
    80004ae4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ae8:	21c48513          	addi	a0,s1,540
    80004aec:	ffffd097          	auipc	ra,0xffffd
    80004af0:	5cc080e7          	jalr	1484(ra) # 800020b8 <wakeup>
    80004af4:	b7e9                	j	80004abe <pipeclose+0x2c>
    release(&pi->lock);
    80004af6:	8526                	mv	a0,s1
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	192080e7          	jalr	402(ra) # 80000c8a <release>
}
    80004b00:	bfe1                	j	80004ad8 <pipeclose+0x46>

0000000080004b02 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b02:	711d                	addi	sp,sp,-96
    80004b04:	ec86                	sd	ra,88(sp)
    80004b06:	e8a2                	sd	s0,80(sp)
    80004b08:	e4a6                	sd	s1,72(sp)
    80004b0a:	e0ca                	sd	s2,64(sp)
    80004b0c:	fc4e                	sd	s3,56(sp)
    80004b0e:	f852                	sd	s4,48(sp)
    80004b10:	f456                	sd	s5,40(sp)
    80004b12:	f05a                	sd	s6,32(sp)
    80004b14:	ec5e                	sd	s7,24(sp)
    80004b16:	e862                	sd	s8,16(sp)
    80004b18:	1080                	addi	s0,sp,96
    80004b1a:	84aa                	mv	s1,a0
    80004b1c:	8aae                	mv	s5,a1
    80004b1e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b20:	ffffd097          	auipc	ra,0xffffd
    80004b24:	e8c080e7          	jalr	-372(ra) # 800019ac <myproc>
    80004b28:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	0aa080e7          	jalr	170(ra) # 80000bd6 <acquire>
  while(i < n){
    80004b34:	0b405663          	blez	s4,80004be0 <pipewrite+0xde>
  int i = 0;
    80004b38:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b3a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b3c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b40:	21c48b93          	addi	s7,s1,540
    80004b44:	a089                	j	80004b86 <pipewrite+0x84>
      release(&pi->lock);
    80004b46:	8526                	mv	a0,s1
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	142080e7          	jalr	322(ra) # 80000c8a <release>
      return -1;
    80004b50:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b52:	854a                	mv	a0,s2
    80004b54:	60e6                	ld	ra,88(sp)
    80004b56:	6446                	ld	s0,80(sp)
    80004b58:	64a6                	ld	s1,72(sp)
    80004b5a:	6906                	ld	s2,64(sp)
    80004b5c:	79e2                	ld	s3,56(sp)
    80004b5e:	7a42                	ld	s4,48(sp)
    80004b60:	7aa2                	ld	s5,40(sp)
    80004b62:	7b02                	ld	s6,32(sp)
    80004b64:	6be2                	ld	s7,24(sp)
    80004b66:	6c42                	ld	s8,16(sp)
    80004b68:	6125                	addi	sp,sp,96
    80004b6a:	8082                	ret
      wakeup(&pi->nread);
    80004b6c:	8562                	mv	a0,s8
    80004b6e:	ffffd097          	auipc	ra,0xffffd
    80004b72:	54a080e7          	jalr	1354(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b76:	85a6                	mv	a1,s1
    80004b78:	855e                	mv	a0,s7
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	4da080e7          	jalr	1242(ra) # 80002054 <sleep>
  while(i < n){
    80004b82:	07495063          	bge	s2,s4,80004be2 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b86:	2204a783          	lw	a5,544(s1)
    80004b8a:	dfd5                	beqz	a5,80004b46 <pipewrite+0x44>
    80004b8c:	854e                	mv	a0,s3
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	76e080e7          	jalr	1902(ra) # 800022fc <killed>
    80004b96:	f945                	bnez	a0,80004b46 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b98:	2184a783          	lw	a5,536(s1)
    80004b9c:	21c4a703          	lw	a4,540(s1)
    80004ba0:	2007879b          	addiw	a5,a5,512
    80004ba4:	fcf704e3          	beq	a4,a5,80004b6c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba8:	4685                	li	a3,1
    80004baa:	01590633          	add	a2,s2,s5
    80004bae:	faf40593          	addi	a1,s0,-81
    80004bb2:	0509b503          	ld	a0,80(s3)
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	b42080e7          	jalr	-1214(ra) # 800016f8 <copyin>
    80004bbe:	03650263          	beq	a0,s6,80004be2 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bc2:	21c4a783          	lw	a5,540(s1)
    80004bc6:	0017871b          	addiw	a4,a5,1
    80004bca:	20e4ae23          	sw	a4,540(s1)
    80004bce:	1ff7f793          	andi	a5,a5,511
    80004bd2:	97a6                	add	a5,a5,s1
    80004bd4:	faf44703          	lbu	a4,-81(s0)
    80004bd8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bdc:	2905                	addiw	s2,s2,1
    80004bde:	b755                	j	80004b82 <pipewrite+0x80>
  int i = 0;
    80004be0:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004be2:	21848513          	addi	a0,s1,536
    80004be6:	ffffd097          	auipc	ra,0xffffd
    80004bea:	4d2080e7          	jalr	1234(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004bee:	8526                	mv	a0,s1
    80004bf0:	ffffc097          	auipc	ra,0xffffc
    80004bf4:	09a080e7          	jalr	154(ra) # 80000c8a <release>
  return i;
    80004bf8:	bfa9                	j	80004b52 <pipewrite+0x50>

0000000080004bfa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bfa:	715d                	addi	sp,sp,-80
    80004bfc:	e486                	sd	ra,72(sp)
    80004bfe:	e0a2                	sd	s0,64(sp)
    80004c00:	fc26                	sd	s1,56(sp)
    80004c02:	f84a                	sd	s2,48(sp)
    80004c04:	f44e                	sd	s3,40(sp)
    80004c06:	f052                	sd	s4,32(sp)
    80004c08:	ec56                	sd	s5,24(sp)
    80004c0a:	e85a                	sd	s6,16(sp)
    80004c0c:	0880                	addi	s0,sp,80
    80004c0e:	84aa                	mv	s1,a0
    80004c10:	892e                	mv	s2,a1
    80004c12:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c14:	ffffd097          	auipc	ra,0xffffd
    80004c18:	d98080e7          	jalr	-616(ra) # 800019ac <myproc>
    80004c1c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c1e:	8526                	mv	a0,s1
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	fb6080e7          	jalr	-74(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c28:	2184a703          	lw	a4,536(s1)
    80004c2c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c30:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c34:	02f71763          	bne	a4,a5,80004c62 <piperead+0x68>
    80004c38:	2244a783          	lw	a5,548(s1)
    80004c3c:	c39d                	beqz	a5,80004c62 <piperead+0x68>
    if(killed(pr)){
    80004c3e:	8552                	mv	a0,s4
    80004c40:	ffffd097          	auipc	ra,0xffffd
    80004c44:	6bc080e7          	jalr	1724(ra) # 800022fc <killed>
    80004c48:	e949                	bnez	a0,80004cda <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c4a:	85a6                	mv	a1,s1
    80004c4c:	854e                	mv	a0,s3
    80004c4e:	ffffd097          	auipc	ra,0xffffd
    80004c52:	406080e7          	jalr	1030(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c56:	2184a703          	lw	a4,536(s1)
    80004c5a:	21c4a783          	lw	a5,540(s1)
    80004c5e:	fcf70de3          	beq	a4,a5,80004c38 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c62:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c64:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c66:	05505463          	blez	s5,80004cae <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004c6a:	2184a783          	lw	a5,536(s1)
    80004c6e:	21c4a703          	lw	a4,540(s1)
    80004c72:	02f70e63          	beq	a4,a5,80004cae <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c76:	0017871b          	addiw	a4,a5,1
    80004c7a:	20e4ac23          	sw	a4,536(s1)
    80004c7e:	1ff7f793          	andi	a5,a5,511
    80004c82:	97a6                	add	a5,a5,s1
    80004c84:	0187c783          	lbu	a5,24(a5)
    80004c88:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c8c:	4685                	li	a3,1
    80004c8e:	fbf40613          	addi	a2,s0,-65
    80004c92:	85ca                	mv	a1,s2
    80004c94:	050a3503          	ld	a0,80(s4)
    80004c98:	ffffd097          	auipc	ra,0xffffd
    80004c9c:	9d4080e7          	jalr	-1580(ra) # 8000166c <copyout>
    80004ca0:	01650763          	beq	a0,s6,80004cae <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca4:	2985                	addiw	s3,s3,1
    80004ca6:	0905                	addi	s2,s2,1
    80004ca8:	fd3a91e3          	bne	s5,s3,80004c6a <piperead+0x70>
    80004cac:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cae:	21c48513          	addi	a0,s1,540
    80004cb2:	ffffd097          	auipc	ra,0xffffd
    80004cb6:	406080e7          	jalr	1030(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004cba:	8526                	mv	a0,s1
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	fce080e7          	jalr	-50(ra) # 80000c8a <release>
  return i;
}
    80004cc4:	854e                	mv	a0,s3
    80004cc6:	60a6                	ld	ra,72(sp)
    80004cc8:	6406                	ld	s0,64(sp)
    80004cca:	74e2                	ld	s1,56(sp)
    80004ccc:	7942                	ld	s2,48(sp)
    80004cce:	79a2                	ld	s3,40(sp)
    80004cd0:	7a02                	ld	s4,32(sp)
    80004cd2:	6ae2                	ld	s5,24(sp)
    80004cd4:	6b42                	ld	s6,16(sp)
    80004cd6:	6161                	addi	sp,sp,80
    80004cd8:	8082                	ret
      release(&pi->lock);
    80004cda:	8526                	mv	a0,s1
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	fae080e7          	jalr	-82(ra) # 80000c8a <release>
      return -1;
    80004ce4:	59fd                	li	s3,-1
    80004ce6:	bff9                	j	80004cc4 <piperead+0xca>

0000000080004ce8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ce8:	1141                	addi	sp,sp,-16
    80004cea:	e422                	sd	s0,8(sp)
    80004cec:	0800                	addi	s0,sp,16
    80004cee:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cf0:	8905                	andi	a0,a0,1
    80004cf2:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004cf4:	8b89                	andi	a5,a5,2
    80004cf6:	c399                	beqz	a5,80004cfc <flags2perm+0x14>
      perm |= PTE_W;
    80004cf8:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cfc:	6422                	ld	s0,8(sp)
    80004cfe:	0141                	addi	sp,sp,16
    80004d00:	8082                	ret

0000000080004d02 <exec>:

int
exec(char *path, char **argv)
{
    80004d02:	de010113          	addi	sp,sp,-544
    80004d06:	20113c23          	sd	ra,536(sp)
    80004d0a:	20813823          	sd	s0,528(sp)
    80004d0e:	20913423          	sd	s1,520(sp)
    80004d12:	21213023          	sd	s2,512(sp)
    80004d16:	ffce                	sd	s3,504(sp)
    80004d18:	fbd2                	sd	s4,496(sp)
    80004d1a:	f7d6                	sd	s5,488(sp)
    80004d1c:	f3da                	sd	s6,480(sp)
    80004d1e:	efde                	sd	s7,472(sp)
    80004d20:	ebe2                	sd	s8,464(sp)
    80004d22:	e7e6                	sd	s9,456(sp)
    80004d24:	e3ea                	sd	s10,448(sp)
    80004d26:	ff6e                	sd	s11,440(sp)
    80004d28:	1400                	addi	s0,sp,544
    80004d2a:	892a                	mv	s2,a0
    80004d2c:	dea43423          	sd	a0,-536(s0)
    80004d30:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	c78080e7          	jalr	-904(ra) # 800019ac <myproc>
    80004d3c:	84aa                	mv	s1,a0

  begin_op();
    80004d3e:	fffff097          	auipc	ra,0xfffff
    80004d42:	482080e7          	jalr	1154(ra) # 800041c0 <begin_op>

  if((ip = namei(path)) == 0){
    80004d46:	854a                	mv	a0,s2
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	258080e7          	jalr	600(ra) # 80003fa0 <namei>
    80004d50:	c93d                	beqz	a0,80004dc6 <exec+0xc4>
    80004d52:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	aa0080e7          	jalr	-1376(ra) # 800037f4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d5c:	04000713          	li	a4,64
    80004d60:	4681                	li	a3,0
    80004d62:	e5040613          	addi	a2,s0,-432
    80004d66:	4581                	li	a1,0
    80004d68:	8556                	mv	a0,s5
    80004d6a:	fffff097          	auipc	ra,0xfffff
    80004d6e:	d3e080e7          	jalr	-706(ra) # 80003aa8 <readi>
    80004d72:	04000793          	li	a5,64
    80004d76:	00f51a63          	bne	a0,a5,80004d8a <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d7a:	e5042703          	lw	a4,-432(s0)
    80004d7e:	464c47b7          	lui	a5,0x464c4
    80004d82:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d86:	04f70663          	beq	a4,a5,80004dd2 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d8a:	8556                	mv	a0,s5
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	cca080e7          	jalr	-822(ra) # 80003a56 <iunlockput>
    end_op();
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	4aa080e7          	jalr	1194(ra) # 8000423e <end_op>
  }
  return -1;
    80004d9c:	557d                	li	a0,-1
}
    80004d9e:	21813083          	ld	ra,536(sp)
    80004da2:	21013403          	ld	s0,528(sp)
    80004da6:	20813483          	ld	s1,520(sp)
    80004daa:	20013903          	ld	s2,512(sp)
    80004dae:	79fe                	ld	s3,504(sp)
    80004db0:	7a5e                	ld	s4,496(sp)
    80004db2:	7abe                	ld	s5,488(sp)
    80004db4:	7b1e                	ld	s6,480(sp)
    80004db6:	6bfe                	ld	s7,472(sp)
    80004db8:	6c5e                	ld	s8,464(sp)
    80004dba:	6cbe                	ld	s9,456(sp)
    80004dbc:	6d1e                	ld	s10,448(sp)
    80004dbe:	7dfa                	ld	s11,440(sp)
    80004dc0:	22010113          	addi	sp,sp,544
    80004dc4:	8082                	ret
    end_op();
    80004dc6:	fffff097          	auipc	ra,0xfffff
    80004dca:	478080e7          	jalr	1144(ra) # 8000423e <end_op>
    return -1;
    80004dce:	557d                	li	a0,-1
    80004dd0:	b7f9                	j	80004d9e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dd2:	8526                	mv	a0,s1
    80004dd4:	ffffd097          	auipc	ra,0xffffd
    80004dd8:	c9c080e7          	jalr	-868(ra) # 80001a70 <proc_pagetable>
    80004ddc:	8b2a                	mv	s6,a0
    80004dde:	d555                	beqz	a0,80004d8a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004de0:	e7042783          	lw	a5,-400(s0)
    80004de4:	e8845703          	lhu	a4,-376(s0)
    80004de8:	c735                	beqz	a4,80004e54 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dea:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dec:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004df0:	6a05                	lui	s4,0x1
    80004df2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004df6:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004dfa:	6d85                	lui	s11,0x1
    80004dfc:	7d7d                	lui	s10,0xfffff
    80004dfe:	ac3d                	j	8000503c <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e00:	00004517          	auipc	a0,0x4
    80004e04:	91850513          	addi	a0,a0,-1768 # 80008718 <syscalls+0x288>
    80004e08:	ffffb097          	auipc	ra,0xffffb
    80004e0c:	738080e7          	jalr	1848(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e10:	874a                	mv	a4,s2
    80004e12:	009c86bb          	addw	a3,s9,s1
    80004e16:	4581                	li	a1,0
    80004e18:	8556                	mv	a0,s5
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	c8e080e7          	jalr	-882(ra) # 80003aa8 <readi>
    80004e22:	2501                	sext.w	a0,a0
    80004e24:	1aa91963          	bne	s2,a0,80004fd6 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004e28:	009d84bb          	addw	s1,s11,s1
    80004e2c:	013d09bb          	addw	s3,s10,s3
    80004e30:	1f74f663          	bgeu	s1,s7,8000501c <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004e34:	02049593          	slli	a1,s1,0x20
    80004e38:	9181                	srli	a1,a1,0x20
    80004e3a:	95e2                	add	a1,a1,s8
    80004e3c:	855a                	mv	a0,s6
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	21e080e7          	jalr	542(ra) # 8000105c <walkaddr>
    80004e46:	862a                	mv	a2,a0
    if(pa == 0)
    80004e48:	dd45                	beqz	a0,80004e00 <exec+0xfe>
      n = PGSIZE;
    80004e4a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e4c:	fd49f2e3          	bgeu	s3,s4,80004e10 <exec+0x10e>
      n = sz - i;
    80004e50:	894e                	mv	s2,s3
    80004e52:	bf7d                	j	80004e10 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e54:	4901                	li	s2,0
  iunlockput(ip);
    80004e56:	8556                	mv	a0,s5
    80004e58:	fffff097          	auipc	ra,0xfffff
    80004e5c:	bfe080e7          	jalr	-1026(ra) # 80003a56 <iunlockput>
  end_op();
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	3de080e7          	jalr	990(ra) # 8000423e <end_op>
  p = myproc();
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	b44080e7          	jalr	-1212(ra) # 800019ac <myproc>
    80004e70:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e72:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e76:	6785                	lui	a5,0x1
    80004e78:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004e7a:	97ca                	add	a5,a5,s2
    80004e7c:	777d                	lui	a4,0xfffff
    80004e7e:	8ff9                	and	a5,a5,a4
    80004e80:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e84:	4691                	li	a3,4
    80004e86:	6609                	lui	a2,0x2
    80004e88:	963e                	add	a2,a2,a5
    80004e8a:	85be                	mv	a1,a5
    80004e8c:	855a                	mv	a0,s6
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	582080e7          	jalr	1410(ra) # 80001410 <uvmalloc>
    80004e96:	8c2a                	mv	s8,a0
  ip = 0;
    80004e98:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e9a:	12050e63          	beqz	a0,80004fd6 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e9e:	75f9                	lui	a1,0xffffe
    80004ea0:	95aa                	add	a1,a1,a0
    80004ea2:	855a                	mv	a0,s6
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	796080e7          	jalr	1942(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004eac:	7afd                	lui	s5,0xfffff
    80004eae:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eb0:	df043783          	ld	a5,-528(s0)
    80004eb4:	6388                	ld	a0,0(a5)
    80004eb6:	c925                	beqz	a0,80004f26 <exec+0x224>
    80004eb8:	e9040993          	addi	s3,s0,-368
    80004ebc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004ec0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ec2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ec4:	ffffc097          	auipc	ra,0xffffc
    80004ec8:	f8a080e7          	jalr	-118(ra) # 80000e4e <strlen>
    80004ecc:	0015079b          	addiw	a5,a0,1
    80004ed0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ed4:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004ed8:	13596663          	bltu	s2,s5,80005004 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004edc:	df043d83          	ld	s11,-528(s0)
    80004ee0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ee4:	8552                	mv	a0,s4
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	f68080e7          	jalr	-152(ra) # 80000e4e <strlen>
    80004eee:	0015069b          	addiw	a3,a0,1
    80004ef2:	8652                	mv	a2,s4
    80004ef4:	85ca                	mv	a1,s2
    80004ef6:	855a                	mv	a0,s6
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	774080e7          	jalr	1908(ra) # 8000166c <copyout>
    80004f00:	10054663          	bltz	a0,8000500c <exec+0x30a>
    ustack[argc] = sp;
    80004f04:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f08:	0485                	addi	s1,s1,1
    80004f0a:	008d8793          	addi	a5,s11,8
    80004f0e:	def43823          	sd	a5,-528(s0)
    80004f12:	008db503          	ld	a0,8(s11)
    80004f16:	c911                	beqz	a0,80004f2a <exec+0x228>
    if(argc >= MAXARG)
    80004f18:	09a1                	addi	s3,s3,8
    80004f1a:	fb3c95e3          	bne	s9,s3,80004ec4 <exec+0x1c2>
  sz = sz1;
    80004f1e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f22:	4a81                	li	s5,0
    80004f24:	a84d                	j	80004fd6 <exec+0x2d4>
  sp = sz;
    80004f26:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f28:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f2a:	00349793          	slli	a5,s1,0x3
    80004f2e:	f9078793          	addi	a5,a5,-112
    80004f32:	97a2                	add	a5,a5,s0
    80004f34:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004f38:	00148693          	addi	a3,s1,1
    80004f3c:	068e                	slli	a3,a3,0x3
    80004f3e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f42:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f46:	01597663          	bgeu	s2,s5,80004f52 <exec+0x250>
  sz = sz1;
    80004f4a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f4e:	4a81                	li	s5,0
    80004f50:	a059                	j	80004fd6 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f52:	e9040613          	addi	a2,s0,-368
    80004f56:	85ca                	mv	a1,s2
    80004f58:	855a                	mv	a0,s6
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	712080e7          	jalr	1810(ra) # 8000166c <copyout>
    80004f62:	0a054963          	bltz	a0,80005014 <exec+0x312>
  p->trapframe->a1 = sp;
    80004f66:	058bb783          	ld	a5,88(s7)
    80004f6a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f6e:	de843783          	ld	a5,-536(s0)
    80004f72:	0007c703          	lbu	a4,0(a5)
    80004f76:	cf11                	beqz	a4,80004f92 <exec+0x290>
    80004f78:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f7a:	02f00693          	li	a3,47
    80004f7e:	a039                	j	80004f8c <exec+0x28a>
      last = s+1;
    80004f80:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f84:	0785                	addi	a5,a5,1
    80004f86:	fff7c703          	lbu	a4,-1(a5)
    80004f8a:	c701                	beqz	a4,80004f92 <exec+0x290>
    if(*s == '/')
    80004f8c:	fed71ce3          	bne	a4,a3,80004f84 <exec+0x282>
    80004f90:	bfc5                	j	80004f80 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f92:	4641                	li	a2,16
    80004f94:	de843583          	ld	a1,-536(s0)
    80004f98:	158b8513          	addi	a0,s7,344
    80004f9c:	ffffc097          	auipc	ra,0xffffc
    80004fa0:	e80080e7          	jalr	-384(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004fa4:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004fa8:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004fac:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fb0:	058bb783          	ld	a5,88(s7)
    80004fb4:	e6843703          	ld	a4,-408(s0)
    80004fb8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fba:	058bb783          	ld	a5,88(s7)
    80004fbe:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fc2:	85ea                	mv	a1,s10
    80004fc4:	ffffd097          	auipc	ra,0xffffd
    80004fc8:	b48080e7          	jalr	-1208(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fcc:	0004851b          	sext.w	a0,s1
    80004fd0:	b3f9                	j	80004d9e <exec+0x9c>
    80004fd2:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004fd6:	df843583          	ld	a1,-520(s0)
    80004fda:	855a                	mv	a0,s6
    80004fdc:	ffffd097          	auipc	ra,0xffffd
    80004fe0:	b30080e7          	jalr	-1232(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004fe4:	da0a93e3          	bnez	s5,80004d8a <exec+0x88>
  return -1;
    80004fe8:	557d                	li	a0,-1
    80004fea:	bb55                	j	80004d9e <exec+0x9c>
    80004fec:	df243c23          	sd	s2,-520(s0)
    80004ff0:	b7dd                	j	80004fd6 <exec+0x2d4>
    80004ff2:	df243c23          	sd	s2,-520(s0)
    80004ff6:	b7c5                	j	80004fd6 <exec+0x2d4>
    80004ff8:	df243c23          	sd	s2,-520(s0)
    80004ffc:	bfe9                	j	80004fd6 <exec+0x2d4>
    80004ffe:	df243c23          	sd	s2,-520(s0)
    80005002:	bfd1                	j	80004fd6 <exec+0x2d4>
  sz = sz1;
    80005004:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005008:	4a81                	li	s5,0
    8000500a:	b7f1                	j	80004fd6 <exec+0x2d4>
  sz = sz1;
    8000500c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005010:	4a81                	li	s5,0
    80005012:	b7d1                	j	80004fd6 <exec+0x2d4>
  sz = sz1;
    80005014:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005018:	4a81                	li	s5,0
    8000501a:	bf75                	j	80004fd6 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000501c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005020:	e0843783          	ld	a5,-504(s0)
    80005024:	0017869b          	addiw	a3,a5,1
    80005028:	e0d43423          	sd	a3,-504(s0)
    8000502c:	e0043783          	ld	a5,-512(s0)
    80005030:	0387879b          	addiw	a5,a5,56
    80005034:	e8845703          	lhu	a4,-376(s0)
    80005038:	e0e6dfe3          	bge	a3,a4,80004e56 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000503c:	2781                	sext.w	a5,a5
    8000503e:	e0f43023          	sd	a5,-512(s0)
    80005042:	03800713          	li	a4,56
    80005046:	86be                	mv	a3,a5
    80005048:	e1840613          	addi	a2,s0,-488
    8000504c:	4581                	li	a1,0
    8000504e:	8556                	mv	a0,s5
    80005050:	fffff097          	auipc	ra,0xfffff
    80005054:	a58080e7          	jalr	-1448(ra) # 80003aa8 <readi>
    80005058:	03800793          	li	a5,56
    8000505c:	f6f51be3          	bne	a0,a5,80004fd2 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005060:	e1842783          	lw	a5,-488(s0)
    80005064:	4705                	li	a4,1
    80005066:	fae79de3          	bne	a5,a4,80005020 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000506a:	e4043483          	ld	s1,-448(s0)
    8000506e:	e3843783          	ld	a5,-456(s0)
    80005072:	f6f4ede3          	bltu	s1,a5,80004fec <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005076:	e2843783          	ld	a5,-472(s0)
    8000507a:	94be                	add	s1,s1,a5
    8000507c:	f6f4ebe3          	bltu	s1,a5,80004ff2 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005080:	de043703          	ld	a4,-544(s0)
    80005084:	8ff9                	and	a5,a5,a4
    80005086:	fbad                	bnez	a5,80004ff8 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005088:	e1c42503          	lw	a0,-484(s0)
    8000508c:	00000097          	auipc	ra,0x0
    80005090:	c5c080e7          	jalr	-932(ra) # 80004ce8 <flags2perm>
    80005094:	86aa                	mv	a3,a0
    80005096:	8626                	mv	a2,s1
    80005098:	85ca                	mv	a1,s2
    8000509a:	855a                	mv	a0,s6
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	374080e7          	jalr	884(ra) # 80001410 <uvmalloc>
    800050a4:	dea43c23          	sd	a0,-520(s0)
    800050a8:	d939                	beqz	a0,80004ffe <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050aa:	e2843c03          	ld	s8,-472(s0)
    800050ae:	e2042c83          	lw	s9,-480(s0)
    800050b2:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050b6:	f60b83e3          	beqz	s7,8000501c <exec+0x31a>
    800050ba:	89de                	mv	s3,s7
    800050bc:	4481                	li	s1,0
    800050be:	bb9d                	j	80004e34 <exec+0x132>

00000000800050c0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050c0:	7179                	addi	sp,sp,-48
    800050c2:	f406                	sd	ra,40(sp)
    800050c4:	f022                	sd	s0,32(sp)
    800050c6:	ec26                	sd	s1,24(sp)
    800050c8:	e84a                	sd	s2,16(sp)
    800050ca:	1800                	addi	s0,sp,48
    800050cc:	892e                	mv	s2,a1
    800050ce:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800050d0:	fdc40593          	addi	a1,s0,-36
    800050d4:	ffffe097          	auipc	ra,0xffffe
    800050d8:	bb6080e7          	jalr	-1098(ra) # 80002c8a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050dc:	fdc42703          	lw	a4,-36(s0)
    800050e0:	47bd                	li	a5,15
    800050e2:	02e7eb63          	bltu	a5,a4,80005118 <argfd+0x58>
    800050e6:	ffffd097          	auipc	ra,0xffffd
    800050ea:	8c6080e7          	jalr	-1850(ra) # 800019ac <myproc>
    800050ee:	fdc42703          	lw	a4,-36(s0)
    800050f2:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd26a>
    800050f6:	078e                	slli	a5,a5,0x3
    800050f8:	953e                	add	a0,a0,a5
    800050fa:	611c                	ld	a5,0(a0)
    800050fc:	c385                	beqz	a5,8000511c <argfd+0x5c>
    return -1;
  if(pfd)
    800050fe:	00090463          	beqz	s2,80005106 <argfd+0x46>
    *pfd = fd;
    80005102:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005106:	4501                	li	a0,0
  if(pf)
    80005108:	c091                	beqz	s1,8000510c <argfd+0x4c>
    *pf = f;
    8000510a:	e09c                	sd	a5,0(s1)
}
    8000510c:	70a2                	ld	ra,40(sp)
    8000510e:	7402                	ld	s0,32(sp)
    80005110:	64e2                	ld	s1,24(sp)
    80005112:	6942                	ld	s2,16(sp)
    80005114:	6145                	addi	sp,sp,48
    80005116:	8082                	ret
    return -1;
    80005118:	557d                	li	a0,-1
    8000511a:	bfcd                	j	8000510c <argfd+0x4c>
    8000511c:	557d                	li	a0,-1
    8000511e:	b7fd                	j	8000510c <argfd+0x4c>

0000000080005120 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005120:	1101                	addi	sp,sp,-32
    80005122:	ec06                	sd	ra,24(sp)
    80005124:	e822                	sd	s0,16(sp)
    80005126:	e426                	sd	s1,8(sp)
    80005128:	1000                	addi	s0,sp,32
    8000512a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000512c:	ffffd097          	auipc	ra,0xffffd
    80005130:	880080e7          	jalr	-1920(ra) # 800019ac <myproc>
    80005134:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005136:	0d050793          	addi	a5,a0,208
    8000513a:	4501                	li	a0,0
    8000513c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000513e:	6398                	ld	a4,0(a5)
    80005140:	cb19                	beqz	a4,80005156 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005142:	2505                	addiw	a0,a0,1
    80005144:	07a1                	addi	a5,a5,8
    80005146:	fed51ce3          	bne	a0,a3,8000513e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000514a:	557d                	li	a0,-1
}
    8000514c:	60e2                	ld	ra,24(sp)
    8000514e:	6442                	ld	s0,16(sp)
    80005150:	64a2                	ld	s1,8(sp)
    80005152:	6105                	addi	sp,sp,32
    80005154:	8082                	ret
      p->ofile[fd] = f;
    80005156:	01a50793          	addi	a5,a0,26
    8000515a:	078e                	slli	a5,a5,0x3
    8000515c:	963e                	add	a2,a2,a5
    8000515e:	e204                	sd	s1,0(a2)
      return fd;
    80005160:	b7f5                	j	8000514c <fdalloc+0x2c>

0000000080005162 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005162:	715d                	addi	sp,sp,-80
    80005164:	e486                	sd	ra,72(sp)
    80005166:	e0a2                	sd	s0,64(sp)
    80005168:	fc26                	sd	s1,56(sp)
    8000516a:	f84a                	sd	s2,48(sp)
    8000516c:	f44e                	sd	s3,40(sp)
    8000516e:	f052                	sd	s4,32(sp)
    80005170:	ec56                	sd	s5,24(sp)
    80005172:	e85a                	sd	s6,16(sp)
    80005174:	0880                	addi	s0,sp,80
    80005176:	8b2e                	mv	s6,a1
    80005178:	89b2                	mv	s3,a2
    8000517a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000517c:	fb040593          	addi	a1,s0,-80
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	e3e080e7          	jalr	-450(ra) # 80003fbe <nameiparent>
    80005188:	84aa                	mv	s1,a0
    8000518a:	14050f63          	beqz	a0,800052e8 <create+0x186>
    return 0;

  ilock(dp);
    8000518e:	ffffe097          	auipc	ra,0xffffe
    80005192:	666080e7          	jalr	1638(ra) # 800037f4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005196:	4601                	li	a2,0
    80005198:	fb040593          	addi	a1,s0,-80
    8000519c:	8526                	mv	a0,s1
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	b3a080e7          	jalr	-1222(ra) # 80003cd8 <dirlookup>
    800051a6:	8aaa                	mv	s5,a0
    800051a8:	c931                	beqz	a0,800051fc <create+0x9a>
    iunlockput(dp);
    800051aa:	8526                	mv	a0,s1
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	8aa080e7          	jalr	-1878(ra) # 80003a56 <iunlockput>
    ilock(ip);
    800051b4:	8556                	mv	a0,s5
    800051b6:	ffffe097          	auipc	ra,0xffffe
    800051ba:	63e080e7          	jalr	1598(ra) # 800037f4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051be:	000b059b          	sext.w	a1,s6
    800051c2:	4789                	li	a5,2
    800051c4:	02f59563          	bne	a1,a5,800051ee <create+0x8c>
    800051c8:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd294>
    800051cc:	37f9                	addiw	a5,a5,-2
    800051ce:	17c2                	slli	a5,a5,0x30
    800051d0:	93c1                	srli	a5,a5,0x30
    800051d2:	4705                	li	a4,1
    800051d4:	00f76d63          	bltu	a4,a5,800051ee <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800051d8:	8556                	mv	a0,s5
    800051da:	60a6                	ld	ra,72(sp)
    800051dc:	6406                	ld	s0,64(sp)
    800051de:	74e2                	ld	s1,56(sp)
    800051e0:	7942                	ld	s2,48(sp)
    800051e2:	79a2                	ld	s3,40(sp)
    800051e4:	7a02                	ld	s4,32(sp)
    800051e6:	6ae2                	ld	s5,24(sp)
    800051e8:	6b42                	ld	s6,16(sp)
    800051ea:	6161                	addi	sp,sp,80
    800051ec:	8082                	ret
    iunlockput(ip);
    800051ee:	8556                	mv	a0,s5
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	866080e7          	jalr	-1946(ra) # 80003a56 <iunlockput>
    return 0;
    800051f8:	4a81                	li	s5,0
    800051fa:	bff9                	j	800051d8 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051fc:	85da                	mv	a1,s6
    800051fe:	4088                	lw	a0,0(s1)
    80005200:	ffffe097          	auipc	ra,0xffffe
    80005204:	456080e7          	jalr	1110(ra) # 80003656 <ialloc>
    80005208:	8a2a                	mv	s4,a0
    8000520a:	c539                	beqz	a0,80005258 <create+0xf6>
  ilock(ip);
    8000520c:	ffffe097          	auipc	ra,0xffffe
    80005210:	5e8080e7          	jalr	1512(ra) # 800037f4 <ilock>
  ip->major = major;
    80005214:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005218:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000521c:	4905                	li	s2,1
    8000521e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005222:	8552                	mv	a0,s4
    80005224:	ffffe097          	auipc	ra,0xffffe
    80005228:	504080e7          	jalr	1284(ra) # 80003728 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000522c:	000b059b          	sext.w	a1,s6
    80005230:	03258b63          	beq	a1,s2,80005266 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005234:	004a2603          	lw	a2,4(s4)
    80005238:	fb040593          	addi	a1,s0,-80
    8000523c:	8526                	mv	a0,s1
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	cb0080e7          	jalr	-848(ra) # 80003eee <dirlink>
    80005246:	06054f63          	bltz	a0,800052c4 <create+0x162>
  iunlockput(dp);
    8000524a:	8526                	mv	a0,s1
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	80a080e7          	jalr	-2038(ra) # 80003a56 <iunlockput>
  return ip;
    80005254:	8ad2                	mv	s5,s4
    80005256:	b749                	j	800051d8 <create+0x76>
    iunlockput(dp);
    80005258:	8526                	mv	a0,s1
    8000525a:	ffffe097          	auipc	ra,0xffffe
    8000525e:	7fc080e7          	jalr	2044(ra) # 80003a56 <iunlockput>
    return 0;
    80005262:	8ad2                	mv	s5,s4
    80005264:	bf95                	j	800051d8 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005266:	004a2603          	lw	a2,4(s4)
    8000526a:	00003597          	auipc	a1,0x3
    8000526e:	4ce58593          	addi	a1,a1,1230 # 80008738 <syscalls+0x2a8>
    80005272:	8552                	mv	a0,s4
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	c7a080e7          	jalr	-902(ra) # 80003eee <dirlink>
    8000527c:	04054463          	bltz	a0,800052c4 <create+0x162>
    80005280:	40d0                	lw	a2,4(s1)
    80005282:	00003597          	auipc	a1,0x3
    80005286:	4be58593          	addi	a1,a1,1214 # 80008740 <syscalls+0x2b0>
    8000528a:	8552                	mv	a0,s4
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	c62080e7          	jalr	-926(ra) # 80003eee <dirlink>
    80005294:	02054863          	bltz	a0,800052c4 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005298:	004a2603          	lw	a2,4(s4)
    8000529c:	fb040593          	addi	a1,s0,-80
    800052a0:	8526                	mv	a0,s1
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	c4c080e7          	jalr	-948(ra) # 80003eee <dirlink>
    800052aa:	00054d63          	bltz	a0,800052c4 <create+0x162>
    dp->nlink++;  // for ".."
    800052ae:	04a4d783          	lhu	a5,74(s1)
    800052b2:	2785                	addiw	a5,a5,1
    800052b4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800052b8:	8526                	mv	a0,s1
    800052ba:	ffffe097          	auipc	ra,0xffffe
    800052be:	46e080e7          	jalr	1134(ra) # 80003728 <iupdate>
    800052c2:	b761                	j	8000524a <create+0xe8>
  ip->nlink = 0;
    800052c4:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800052c8:	8552                	mv	a0,s4
    800052ca:	ffffe097          	auipc	ra,0xffffe
    800052ce:	45e080e7          	jalr	1118(ra) # 80003728 <iupdate>
  iunlockput(ip);
    800052d2:	8552                	mv	a0,s4
    800052d4:	ffffe097          	auipc	ra,0xffffe
    800052d8:	782080e7          	jalr	1922(ra) # 80003a56 <iunlockput>
  iunlockput(dp);
    800052dc:	8526                	mv	a0,s1
    800052de:	ffffe097          	auipc	ra,0xffffe
    800052e2:	778080e7          	jalr	1912(ra) # 80003a56 <iunlockput>
  return 0;
    800052e6:	bdcd                	j	800051d8 <create+0x76>
    return 0;
    800052e8:	8aaa                	mv	s5,a0
    800052ea:	b5fd                	j	800051d8 <create+0x76>

00000000800052ec <sys_dup>:
{
    800052ec:	7179                	addi	sp,sp,-48
    800052ee:	f406                	sd	ra,40(sp)
    800052f0:	f022                	sd	s0,32(sp)
    800052f2:	ec26                	sd	s1,24(sp)
    800052f4:	e84a                	sd	s2,16(sp)
    800052f6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052f8:	fd840613          	addi	a2,s0,-40
    800052fc:	4581                	li	a1,0
    800052fe:	4501                	li	a0,0
    80005300:	00000097          	auipc	ra,0x0
    80005304:	dc0080e7          	jalr	-576(ra) # 800050c0 <argfd>
    return -1;
    80005308:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000530a:	02054363          	bltz	a0,80005330 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000530e:	fd843903          	ld	s2,-40(s0)
    80005312:	854a                	mv	a0,s2
    80005314:	00000097          	auipc	ra,0x0
    80005318:	e0c080e7          	jalr	-500(ra) # 80005120 <fdalloc>
    8000531c:	84aa                	mv	s1,a0
    return -1;
    8000531e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005320:	00054863          	bltz	a0,80005330 <sys_dup+0x44>
  filedup(f);
    80005324:	854a                	mv	a0,s2
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	310080e7          	jalr	784(ra) # 80004636 <filedup>
  return fd;
    8000532e:	87a6                	mv	a5,s1
}
    80005330:	853e                	mv	a0,a5
    80005332:	70a2                	ld	ra,40(sp)
    80005334:	7402                	ld	s0,32(sp)
    80005336:	64e2                	ld	s1,24(sp)
    80005338:	6942                	ld	s2,16(sp)
    8000533a:	6145                	addi	sp,sp,48
    8000533c:	8082                	ret

000000008000533e <sys_read>:
{
    8000533e:	7179                	addi	sp,sp,-48
    80005340:	f406                	sd	ra,40(sp)
    80005342:	f022                	sd	s0,32(sp)
    80005344:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005346:	fd840593          	addi	a1,s0,-40
    8000534a:	4505                	li	a0,1
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	95e080e7          	jalr	-1698(ra) # 80002caa <argaddr>
  argint(2, &n);
    80005354:	fe440593          	addi	a1,s0,-28
    80005358:	4509                	li	a0,2
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	930080e7          	jalr	-1744(ra) # 80002c8a <argint>
  if(argfd(0, 0, &f) < 0)
    80005362:	fe840613          	addi	a2,s0,-24
    80005366:	4581                	li	a1,0
    80005368:	4501                	li	a0,0
    8000536a:	00000097          	auipc	ra,0x0
    8000536e:	d56080e7          	jalr	-682(ra) # 800050c0 <argfd>
    80005372:	87aa                	mv	a5,a0
    return -1;
    80005374:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005376:	0007cc63          	bltz	a5,8000538e <sys_read+0x50>
  return fileread(f, p, n);
    8000537a:	fe442603          	lw	a2,-28(s0)
    8000537e:	fd843583          	ld	a1,-40(s0)
    80005382:	fe843503          	ld	a0,-24(s0)
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	43c080e7          	jalr	1084(ra) # 800047c2 <fileread>
}
    8000538e:	70a2                	ld	ra,40(sp)
    80005390:	7402                	ld	s0,32(sp)
    80005392:	6145                	addi	sp,sp,48
    80005394:	8082                	ret

0000000080005396 <sys_write>:
{
    80005396:	7179                	addi	sp,sp,-48
    80005398:	f406                	sd	ra,40(sp)
    8000539a:	f022                	sd	s0,32(sp)
    8000539c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000539e:	fd840593          	addi	a1,s0,-40
    800053a2:	4505                	li	a0,1
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	906080e7          	jalr	-1786(ra) # 80002caa <argaddr>
  argint(2, &n);
    800053ac:	fe440593          	addi	a1,s0,-28
    800053b0:	4509                	li	a0,2
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	8d8080e7          	jalr	-1832(ra) # 80002c8a <argint>
  if(argfd(0, 0, &f) < 0)
    800053ba:	fe840613          	addi	a2,s0,-24
    800053be:	4581                	li	a1,0
    800053c0:	4501                	li	a0,0
    800053c2:	00000097          	auipc	ra,0x0
    800053c6:	cfe080e7          	jalr	-770(ra) # 800050c0 <argfd>
    800053ca:	87aa                	mv	a5,a0
    return -1;
    800053cc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053ce:	0007cc63          	bltz	a5,800053e6 <sys_write+0x50>
  return filewrite(f, p, n);
    800053d2:	fe442603          	lw	a2,-28(s0)
    800053d6:	fd843583          	ld	a1,-40(s0)
    800053da:	fe843503          	ld	a0,-24(s0)
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	4a6080e7          	jalr	1190(ra) # 80004884 <filewrite>
}
    800053e6:	70a2                	ld	ra,40(sp)
    800053e8:	7402                	ld	s0,32(sp)
    800053ea:	6145                	addi	sp,sp,48
    800053ec:	8082                	ret

00000000800053ee <sys_close>:
{
    800053ee:	1101                	addi	sp,sp,-32
    800053f0:	ec06                	sd	ra,24(sp)
    800053f2:	e822                	sd	s0,16(sp)
    800053f4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053f6:	fe040613          	addi	a2,s0,-32
    800053fa:	fec40593          	addi	a1,s0,-20
    800053fe:	4501                	li	a0,0
    80005400:	00000097          	auipc	ra,0x0
    80005404:	cc0080e7          	jalr	-832(ra) # 800050c0 <argfd>
    return -1;
    80005408:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000540a:	02054463          	bltz	a0,80005432 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000540e:	ffffc097          	auipc	ra,0xffffc
    80005412:	59e080e7          	jalr	1438(ra) # 800019ac <myproc>
    80005416:	fec42783          	lw	a5,-20(s0)
    8000541a:	07e9                	addi	a5,a5,26
    8000541c:	078e                	slli	a5,a5,0x3
    8000541e:	953e                	add	a0,a0,a5
    80005420:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005424:	fe043503          	ld	a0,-32(s0)
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	260080e7          	jalr	608(ra) # 80004688 <fileclose>
  return 0;
    80005430:	4781                	li	a5,0
}
    80005432:	853e                	mv	a0,a5
    80005434:	60e2                	ld	ra,24(sp)
    80005436:	6442                	ld	s0,16(sp)
    80005438:	6105                	addi	sp,sp,32
    8000543a:	8082                	ret

000000008000543c <sys_fstat>:
{
    8000543c:	1101                	addi	sp,sp,-32
    8000543e:	ec06                	sd	ra,24(sp)
    80005440:	e822                	sd	s0,16(sp)
    80005442:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005444:	fe040593          	addi	a1,s0,-32
    80005448:	4505                	li	a0,1
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	860080e7          	jalr	-1952(ra) # 80002caa <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005452:	fe840613          	addi	a2,s0,-24
    80005456:	4581                	li	a1,0
    80005458:	4501                	li	a0,0
    8000545a:	00000097          	auipc	ra,0x0
    8000545e:	c66080e7          	jalr	-922(ra) # 800050c0 <argfd>
    80005462:	87aa                	mv	a5,a0
    return -1;
    80005464:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005466:	0007ca63          	bltz	a5,8000547a <sys_fstat+0x3e>
  return filestat(f, st);
    8000546a:	fe043583          	ld	a1,-32(s0)
    8000546e:	fe843503          	ld	a0,-24(s0)
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	2de080e7          	jalr	734(ra) # 80004750 <filestat>
}
    8000547a:	60e2                	ld	ra,24(sp)
    8000547c:	6442                	ld	s0,16(sp)
    8000547e:	6105                	addi	sp,sp,32
    80005480:	8082                	ret

0000000080005482 <sys_link>:
{
    80005482:	7169                	addi	sp,sp,-304
    80005484:	f606                	sd	ra,296(sp)
    80005486:	f222                	sd	s0,288(sp)
    80005488:	ee26                	sd	s1,280(sp)
    8000548a:	ea4a                	sd	s2,272(sp)
    8000548c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000548e:	08000613          	li	a2,128
    80005492:	ed040593          	addi	a1,s0,-304
    80005496:	4501                	li	a0,0
    80005498:	ffffe097          	auipc	ra,0xffffe
    8000549c:	832080e7          	jalr	-1998(ra) # 80002cca <argstr>
    return -1;
    800054a0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054a2:	10054e63          	bltz	a0,800055be <sys_link+0x13c>
    800054a6:	08000613          	li	a2,128
    800054aa:	f5040593          	addi	a1,s0,-176
    800054ae:	4505                	li	a0,1
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	81a080e7          	jalr	-2022(ra) # 80002cca <argstr>
    return -1;
    800054b8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ba:	10054263          	bltz	a0,800055be <sys_link+0x13c>
  begin_op();
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	d02080e7          	jalr	-766(ra) # 800041c0 <begin_op>
  if((ip = namei(old)) == 0){
    800054c6:	ed040513          	addi	a0,s0,-304
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	ad6080e7          	jalr	-1322(ra) # 80003fa0 <namei>
    800054d2:	84aa                	mv	s1,a0
    800054d4:	c551                	beqz	a0,80005560 <sys_link+0xde>
  ilock(ip);
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	31e080e7          	jalr	798(ra) # 800037f4 <ilock>
  if(ip->type == T_DIR){
    800054de:	04449703          	lh	a4,68(s1)
    800054e2:	4785                	li	a5,1
    800054e4:	08f70463          	beq	a4,a5,8000556c <sys_link+0xea>
  ip->nlink++;
    800054e8:	04a4d783          	lhu	a5,74(s1)
    800054ec:	2785                	addiw	a5,a5,1
    800054ee:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054f2:	8526                	mv	a0,s1
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	234080e7          	jalr	564(ra) # 80003728 <iupdate>
  iunlock(ip);
    800054fc:	8526                	mv	a0,s1
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	3b8080e7          	jalr	952(ra) # 800038b6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005506:	fd040593          	addi	a1,s0,-48
    8000550a:	f5040513          	addi	a0,s0,-176
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	ab0080e7          	jalr	-1360(ra) # 80003fbe <nameiparent>
    80005516:	892a                	mv	s2,a0
    80005518:	c935                	beqz	a0,8000558c <sys_link+0x10a>
  ilock(dp);
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	2da080e7          	jalr	730(ra) # 800037f4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005522:	00092703          	lw	a4,0(s2)
    80005526:	409c                	lw	a5,0(s1)
    80005528:	04f71d63          	bne	a4,a5,80005582 <sys_link+0x100>
    8000552c:	40d0                	lw	a2,4(s1)
    8000552e:	fd040593          	addi	a1,s0,-48
    80005532:	854a                	mv	a0,s2
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	9ba080e7          	jalr	-1606(ra) # 80003eee <dirlink>
    8000553c:	04054363          	bltz	a0,80005582 <sys_link+0x100>
  iunlockput(dp);
    80005540:	854a                	mv	a0,s2
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	514080e7          	jalr	1300(ra) # 80003a56 <iunlockput>
  iput(ip);
    8000554a:	8526                	mv	a0,s1
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	462080e7          	jalr	1122(ra) # 800039ae <iput>
  end_op();
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	cea080e7          	jalr	-790(ra) # 8000423e <end_op>
  return 0;
    8000555c:	4781                	li	a5,0
    8000555e:	a085                	j	800055be <sys_link+0x13c>
    end_op();
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	cde080e7          	jalr	-802(ra) # 8000423e <end_op>
    return -1;
    80005568:	57fd                	li	a5,-1
    8000556a:	a891                	j	800055be <sys_link+0x13c>
    iunlockput(ip);
    8000556c:	8526                	mv	a0,s1
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	4e8080e7          	jalr	1256(ra) # 80003a56 <iunlockput>
    end_op();
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	cc8080e7          	jalr	-824(ra) # 8000423e <end_op>
    return -1;
    8000557e:	57fd                	li	a5,-1
    80005580:	a83d                	j	800055be <sys_link+0x13c>
    iunlockput(dp);
    80005582:	854a                	mv	a0,s2
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	4d2080e7          	jalr	1234(ra) # 80003a56 <iunlockput>
  ilock(ip);
    8000558c:	8526                	mv	a0,s1
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	266080e7          	jalr	614(ra) # 800037f4 <ilock>
  ip->nlink--;
    80005596:	04a4d783          	lhu	a5,74(s1)
    8000559a:	37fd                	addiw	a5,a5,-1
    8000559c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055a0:	8526                	mv	a0,s1
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	186080e7          	jalr	390(ra) # 80003728 <iupdate>
  iunlockput(ip);
    800055aa:	8526                	mv	a0,s1
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	4aa080e7          	jalr	1194(ra) # 80003a56 <iunlockput>
  end_op();
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	c8a080e7          	jalr	-886(ra) # 8000423e <end_op>
  return -1;
    800055bc:	57fd                	li	a5,-1
}
    800055be:	853e                	mv	a0,a5
    800055c0:	70b2                	ld	ra,296(sp)
    800055c2:	7412                	ld	s0,288(sp)
    800055c4:	64f2                	ld	s1,280(sp)
    800055c6:	6952                	ld	s2,272(sp)
    800055c8:	6155                	addi	sp,sp,304
    800055ca:	8082                	ret

00000000800055cc <sys_unlink>:
{
    800055cc:	7151                	addi	sp,sp,-240
    800055ce:	f586                	sd	ra,232(sp)
    800055d0:	f1a2                	sd	s0,224(sp)
    800055d2:	eda6                	sd	s1,216(sp)
    800055d4:	e9ca                	sd	s2,208(sp)
    800055d6:	e5ce                	sd	s3,200(sp)
    800055d8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055da:	08000613          	li	a2,128
    800055de:	f3040593          	addi	a1,s0,-208
    800055e2:	4501                	li	a0,0
    800055e4:	ffffd097          	auipc	ra,0xffffd
    800055e8:	6e6080e7          	jalr	1766(ra) # 80002cca <argstr>
    800055ec:	18054163          	bltz	a0,8000576e <sys_unlink+0x1a2>
  begin_op();
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	bd0080e7          	jalr	-1072(ra) # 800041c0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055f8:	fb040593          	addi	a1,s0,-80
    800055fc:	f3040513          	addi	a0,s0,-208
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	9be080e7          	jalr	-1602(ra) # 80003fbe <nameiparent>
    80005608:	84aa                	mv	s1,a0
    8000560a:	c979                	beqz	a0,800056e0 <sys_unlink+0x114>
  ilock(dp);
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	1e8080e7          	jalr	488(ra) # 800037f4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005614:	00003597          	auipc	a1,0x3
    80005618:	12458593          	addi	a1,a1,292 # 80008738 <syscalls+0x2a8>
    8000561c:	fb040513          	addi	a0,s0,-80
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	69e080e7          	jalr	1694(ra) # 80003cbe <namecmp>
    80005628:	14050a63          	beqz	a0,8000577c <sys_unlink+0x1b0>
    8000562c:	00003597          	auipc	a1,0x3
    80005630:	11458593          	addi	a1,a1,276 # 80008740 <syscalls+0x2b0>
    80005634:	fb040513          	addi	a0,s0,-80
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	686080e7          	jalr	1670(ra) # 80003cbe <namecmp>
    80005640:	12050e63          	beqz	a0,8000577c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005644:	f2c40613          	addi	a2,s0,-212
    80005648:	fb040593          	addi	a1,s0,-80
    8000564c:	8526                	mv	a0,s1
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	68a080e7          	jalr	1674(ra) # 80003cd8 <dirlookup>
    80005656:	892a                	mv	s2,a0
    80005658:	12050263          	beqz	a0,8000577c <sys_unlink+0x1b0>
  ilock(ip);
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	198080e7          	jalr	408(ra) # 800037f4 <ilock>
  if(ip->nlink < 1)
    80005664:	04a91783          	lh	a5,74(s2)
    80005668:	08f05263          	blez	a5,800056ec <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000566c:	04491703          	lh	a4,68(s2)
    80005670:	4785                	li	a5,1
    80005672:	08f70563          	beq	a4,a5,800056fc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005676:	4641                	li	a2,16
    80005678:	4581                	li	a1,0
    8000567a:	fc040513          	addi	a0,s0,-64
    8000567e:	ffffb097          	auipc	ra,0xffffb
    80005682:	654080e7          	jalr	1620(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005686:	4741                	li	a4,16
    80005688:	f2c42683          	lw	a3,-212(s0)
    8000568c:	fc040613          	addi	a2,s0,-64
    80005690:	4581                	li	a1,0
    80005692:	8526                	mv	a0,s1
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	50c080e7          	jalr	1292(ra) # 80003ba0 <writei>
    8000569c:	47c1                	li	a5,16
    8000569e:	0af51563          	bne	a0,a5,80005748 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056a2:	04491703          	lh	a4,68(s2)
    800056a6:	4785                	li	a5,1
    800056a8:	0af70863          	beq	a4,a5,80005758 <sys_unlink+0x18c>
  iunlockput(dp);
    800056ac:	8526                	mv	a0,s1
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	3a8080e7          	jalr	936(ra) # 80003a56 <iunlockput>
  ip->nlink--;
    800056b6:	04a95783          	lhu	a5,74(s2)
    800056ba:	37fd                	addiw	a5,a5,-1
    800056bc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056c0:	854a                	mv	a0,s2
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	066080e7          	jalr	102(ra) # 80003728 <iupdate>
  iunlockput(ip);
    800056ca:	854a                	mv	a0,s2
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	38a080e7          	jalr	906(ra) # 80003a56 <iunlockput>
  end_op();
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	b6a080e7          	jalr	-1174(ra) # 8000423e <end_op>
  return 0;
    800056dc:	4501                	li	a0,0
    800056de:	a84d                	j	80005790 <sys_unlink+0x1c4>
    end_op();
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	b5e080e7          	jalr	-1186(ra) # 8000423e <end_op>
    return -1;
    800056e8:	557d                	li	a0,-1
    800056ea:	a05d                	j	80005790 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056ec:	00003517          	auipc	a0,0x3
    800056f0:	05c50513          	addi	a0,a0,92 # 80008748 <syscalls+0x2b8>
    800056f4:	ffffb097          	auipc	ra,0xffffb
    800056f8:	e4c080e7          	jalr	-436(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056fc:	04c92703          	lw	a4,76(s2)
    80005700:	02000793          	li	a5,32
    80005704:	f6e7f9e3          	bgeu	a5,a4,80005676 <sys_unlink+0xaa>
    80005708:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000570c:	4741                	li	a4,16
    8000570e:	86ce                	mv	a3,s3
    80005710:	f1840613          	addi	a2,s0,-232
    80005714:	4581                	li	a1,0
    80005716:	854a                	mv	a0,s2
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	390080e7          	jalr	912(ra) # 80003aa8 <readi>
    80005720:	47c1                	li	a5,16
    80005722:	00f51b63          	bne	a0,a5,80005738 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005726:	f1845783          	lhu	a5,-232(s0)
    8000572a:	e7a1                	bnez	a5,80005772 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000572c:	29c1                	addiw	s3,s3,16
    8000572e:	04c92783          	lw	a5,76(s2)
    80005732:	fcf9ede3          	bltu	s3,a5,8000570c <sys_unlink+0x140>
    80005736:	b781                	j	80005676 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005738:	00003517          	auipc	a0,0x3
    8000573c:	02850513          	addi	a0,a0,40 # 80008760 <syscalls+0x2d0>
    80005740:	ffffb097          	auipc	ra,0xffffb
    80005744:	e00080e7          	jalr	-512(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005748:	00003517          	auipc	a0,0x3
    8000574c:	03050513          	addi	a0,a0,48 # 80008778 <syscalls+0x2e8>
    80005750:	ffffb097          	auipc	ra,0xffffb
    80005754:	df0080e7          	jalr	-528(ra) # 80000540 <panic>
    dp->nlink--;
    80005758:	04a4d783          	lhu	a5,74(s1)
    8000575c:	37fd                	addiw	a5,a5,-1
    8000575e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005762:	8526                	mv	a0,s1
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	fc4080e7          	jalr	-60(ra) # 80003728 <iupdate>
    8000576c:	b781                	j	800056ac <sys_unlink+0xe0>
    return -1;
    8000576e:	557d                	li	a0,-1
    80005770:	a005                	j	80005790 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005772:	854a                	mv	a0,s2
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	2e2080e7          	jalr	738(ra) # 80003a56 <iunlockput>
  iunlockput(dp);
    8000577c:	8526                	mv	a0,s1
    8000577e:	ffffe097          	auipc	ra,0xffffe
    80005782:	2d8080e7          	jalr	728(ra) # 80003a56 <iunlockput>
  end_op();
    80005786:	fffff097          	auipc	ra,0xfffff
    8000578a:	ab8080e7          	jalr	-1352(ra) # 8000423e <end_op>
  return -1;
    8000578e:	557d                	li	a0,-1
}
    80005790:	70ae                	ld	ra,232(sp)
    80005792:	740e                	ld	s0,224(sp)
    80005794:	64ee                	ld	s1,216(sp)
    80005796:	694e                	ld	s2,208(sp)
    80005798:	69ae                	ld	s3,200(sp)
    8000579a:	616d                	addi	sp,sp,240
    8000579c:	8082                	ret

000000008000579e <sys_open>:

uint64
sys_open(void)
{
    8000579e:	7131                	addi	sp,sp,-192
    800057a0:	fd06                	sd	ra,184(sp)
    800057a2:	f922                	sd	s0,176(sp)
    800057a4:	f526                	sd	s1,168(sp)
    800057a6:	f14a                	sd	s2,160(sp)
    800057a8:	ed4e                	sd	s3,152(sp)
    800057aa:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800057ac:	f4c40593          	addi	a1,s0,-180
    800057b0:	4505                	li	a0,1
    800057b2:	ffffd097          	auipc	ra,0xffffd
    800057b6:	4d8080e7          	jalr	1240(ra) # 80002c8a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057ba:	08000613          	li	a2,128
    800057be:	f5040593          	addi	a1,s0,-176
    800057c2:	4501                	li	a0,0
    800057c4:	ffffd097          	auipc	ra,0xffffd
    800057c8:	506080e7          	jalr	1286(ra) # 80002cca <argstr>
    800057cc:	87aa                	mv	a5,a0
    return -1;
    800057ce:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057d0:	0a07c963          	bltz	a5,80005882 <sys_open+0xe4>

  begin_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	9ec080e7          	jalr	-1556(ra) # 800041c0 <begin_op>

  if(omode & O_CREATE){
    800057dc:	f4c42783          	lw	a5,-180(s0)
    800057e0:	2007f793          	andi	a5,a5,512
    800057e4:	cfc5                	beqz	a5,8000589c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057e6:	4681                	li	a3,0
    800057e8:	4601                	li	a2,0
    800057ea:	4589                	li	a1,2
    800057ec:	f5040513          	addi	a0,s0,-176
    800057f0:	00000097          	auipc	ra,0x0
    800057f4:	972080e7          	jalr	-1678(ra) # 80005162 <create>
    800057f8:	84aa                	mv	s1,a0
    if(ip == 0){
    800057fa:	c959                	beqz	a0,80005890 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057fc:	04449703          	lh	a4,68(s1)
    80005800:	478d                	li	a5,3
    80005802:	00f71763          	bne	a4,a5,80005810 <sys_open+0x72>
    80005806:	0464d703          	lhu	a4,70(s1)
    8000580a:	47a5                	li	a5,9
    8000580c:	0ce7ed63          	bltu	a5,a4,800058e6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	dbc080e7          	jalr	-580(ra) # 800045cc <filealloc>
    80005818:	89aa                	mv	s3,a0
    8000581a:	10050363          	beqz	a0,80005920 <sys_open+0x182>
    8000581e:	00000097          	auipc	ra,0x0
    80005822:	902080e7          	jalr	-1790(ra) # 80005120 <fdalloc>
    80005826:	892a                	mv	s2,a0
    80005828:	0e054763          	bltz	a0,80005916 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000582c:	04449703          	lh	a4,68(s1)
    80005830:	478d                	li	a5,3
    80005832:	0cf70563          	beq	a4,a5,800058fc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005836:	4789                	li	a5,2
    80005838:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000583c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005840:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005844:	f4c42783          	lw	a5,-180(s0)
    80005848:	0017c713          	xori	a4,a5,1
    8000584c:	8b05                	andi	a4,a4,1
    8000584e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005852:	0037f713          	andi	a4,a5,3
    80005856:	00e03733          	snez	a4,a4
    8000585a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000585e:	4007f793          	andi	a5,a5,1024
    80005862:	c791                	beqz	a5,8000586e <sys_open+0xd0>
    80005864:	04449703          	lh	a4,68(s1)
    80005868:	4789                	li	a5,2
    8000586a:	0af70063          	beq	a4,a5,8000590a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	046080e7          	jalr	70(ra) # 800038b6 <iunlock>
  end_op();
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	9c6080e7          	jalr	-1594(ra) # 8000423e <end_op>

  return fd;
    80005880:	854a                	mv	a0,s2
}
    80005882:	70ea                	ld	ra,184(sp)
    80005884:	744a                	ld	s0,176(sp)
    80005886:	74aa                	ld	s1,168(sp)
    80005888:	790a                	ld	s2,160(sp)
    8000588a:	69ea                	ld	s3,152(sp)
    8000588c:	6129                	addi	sp,sp,192
    8000588e:	8082                	ret
      end_op();
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	9ae080e7          	jalr	-1618(ra) # 8000423e <end_op>
      return -1;
    80005898:	557d                	li	a0,-1
    8000589a:	b7e5                	j	80005882 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000589c:	f5040513          	addi	a0,s0,-176
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	700080e7          	jalr	1792(ra) # 80003fa0 <namei>
    800058a8:	84aa                	mv	s1,a0
    800058aa:	c905                	beqz	a0,800058da <sys_open+0x13c>
    ilock(ip);
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	f48080e7          	jalr	-184(ra) # 800037f4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058b4:	04449703          	lh	a4,68(s1)
    800058b8:	4785                	li	a5,1
    800058ba:	f4f711e3          	bne	a4,a5,800057fc <sys_open+0x5e>
    800058be:	f4c42783          	lw	a5,-180(s0)
    800058c2:	d7b9                	beqz	a5,80005810 <sys_open+0x72>
      iunlockput(ip);
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	190080e7          	jalr	400(ra) # 80003a56 <iunlockput>
      end_op();
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	970080e7          	jalr	-1680(ra) # 8000423e <end_op>
      return -1;
    800058d6:	557d                	li	a0,-1
    800058d8:	b76d                	j	80005882 <sys_open+0xe4>
      end_op();
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	964080e7          	jalr	-1692(ra) # 8000423e <end_op>
      return -1;
    800058e2:	557d                	li	a0,-1
    800058e4:	bf79                	j	80005882 <sys_open+0xe4>
    iunlockput(ip);
    800058e6:	8526                	mv	a0,s1
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	16e080e7          	jalr	366(ra) # 80003a56 <iunlockput>
    end_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	94e080e7          	jalr	-1714(ra) # 8000423e <end_op>
    return -1;
    800058f8:	557d                	li	a0,-1
    800058fa:	b761                	j	80005882 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058fc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005900:	04649783          	lh	a5,70(s1)
    80005904:	02f99223          	sh	a5,36(s3)
    80005908:	bf25                	j	80005840 <sys_open+0xa2>
    itrunc(ip);
    8000590a:	8526                	mv	a0,s1
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	ff6080e7          	jalr	-10(ra) # 80003902 <itrunc>
    80005914:	bfa9                	j	8000586e <sys_open+0xd0>
      fileclose(f);
    80005916:	854e                	mv	a0,s3
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	d70080e7          	jalr	-656(ra) # 80004688 <fileclose>
    iunlockput(ip);
    80005920:	8526                	mv	a0,s1
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	134080e7          	jalr	308(ra) # 80003a56 <iunlockput>
    end_op();
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	914080e7          	jalr	-1772(ra) # 8000423e <end_op>
    return -1;
    80005932:	557d                	li	a0,-1
    80005934:	b7b9                	j	80005882 <sys_open+0xe4>

0000000080005936 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005936:	7175                	addi	sp,sp,-144
    80005938:	e506                	sd	ra,136(sp)
    8000593a:	e122                	sd	s0,128(sp)
    8000593c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	882080e7          	jalr	-1918(ra) # 800041c0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005946:	08000613          	li	a2,128
    8000594a:	f7040593          	addi	a1,s0,-144
    8000594e:	4501                	li	a0,0
    80005950:	ffffd097          	auipc	ra,0xffffd
    80005954:	37a080e7          	jalr	890(ra) # 80002cca <argstr>
    80005958:	02054963          	bltz	a0,8000598a <sys_mkdir+0x54>
    8000595c:	4681                	li	a3,0
    8000595e:	4601                	li	a2,0
    80005960:	4585                	li	a1,1
    80005962:	f7040513          	addi	a0,s0,-144
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	7fc080e7          	jalr	2044(ra) # 80005162 <create>
    8000596e:	cd11                	beqz	a0,8000598a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	0e6080e7          	jalr	230(ra) # 80003a56 <iunlockput>
  end_op();
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	8c6080e7          	jalr	-1850(ra) # 8000423e <end_op>
  return 0;
    80005980:	4501                	li	a0,0
}
    80005982:	60aa                	ld	ra,136(sp)
    80005984:	640a                	ld	s0,128(sp)
    80005986:	6149                	addi	sp,sp,144
    80005988:	8082                	ret
    end_op();
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	8b4080e7          	jalr	-1868(ra) # 8000423e <end_op>
    return -1;
    80005992:	557d                	li	a0,-1
    80005994:	b7fd                	j	80005982 <sys_mkdir+0x4c>

0000000080005996 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005996:	7135                	addi	sp,sp,-160
    80005998:	ed06                	sd	ra,152(sp)
    8000599a:	e922                	sd	s0,144(sp)
    8000599c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	822080e7          	jalr	-2014(ra) # 800041c0 <begin_op>
  argint(1, &major);
    800059a6:	f6c40593          	addi	a1,s0,-148
    800059aa:	4505                	li	a0,1
    800059ac:	ffffd097          	auipc	ra,0xffffd
    800059b0:	2de080e7          	jalr	734(ra) # 80002c8a <argint>
  argint(2, &minor);
    800059b4:	f6840593          	addi	a1,s0,-152
    800059b8:	4509                	li	a0,2
    800059ba:	ffffd097          	auipc	ra,0xffffd
    800059be:	2d0080e7          	jalr	720(ra) # 80002c8a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059c2:	08000613          	li	a2,128
    800059c6:	f7040593          	addi	a1,s0,-144
    800059ca:	4501                	li	a0,0
    800059cc:	ffffd097          	auipc	ra,0xffffd
    800059d0:	2fe080e7          	jalr	766(ra) # 80002cca <argstr>
    800059d4:	02054b63          	bltz	a0,80005a0a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059d8:	f6841683          	lh	a3,-152(s0)
    800059dc:	f6c41603          	lh	a2,-148(s0)
    800059e0:	458d                	li	a1,3
    800059e2:	f7040513          	addi	a0,s0,-144
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	77c080e7          	jalr	1916(ra) # 80005162 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059ee:	cd11                	beqz	a0,80005a0a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	066080e7          	jalr	102(ra) # 80003a56 <iunlockput>
  end_op();
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	846080e7          	jalr	-1978(ra) # 8000423e <end_op>
  return 0;
    80005a00:	4501                	li	a0,0
}
    80005a02:	60ea                	ld	ra,152(sp)
    80005a04:	644a                	ld	s0,144(sp)
    80005a06:	610d                	addi	sp,sp,160
    80005a08:	8082                	ret
    end_op();
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	834080e7          	jalr	-1996(ra) # 8000423e <end_op>
    return -1;
    80005a12:	557d                	li	a0,-1
    80005a14:	b7fd                	j	80005a02 <sys_mknod+0x6c>

0000000080005a16 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a16:	7135                	addi	sp,sp,-160
    80005a18:	ed06                	sd	ra,152(sp)
    80005a1a:	e922                	sd	s0,144(sp)
    80005a1c:	e526                	sd	s1,136(sp)
    80005a1e:	e14a                	sd	s2,128(sp)
    80005a20:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a22:	ffffc097          	auipc	ra,0xffffc
    80005a26:	f8a080e7          	jalr	-118(ra) # 800019ac <myproc>
    80005a2a:	892a                	mv	s2,a0
  
  begin_op();
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	794080e7          	jalr	1940(ra) # 800041c0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a34:	08000613          	li	a2,128
    80005a38:	f6040593          	addi	a1,s0,-160
    80005a3c:	4501                	li	a0,0
    80005a3e:	ffffd097          	auipc	ra,0xffffd
    80005a42:	28c080e7          	jalr	652(ra) # 80002cca <argstr>
    80005a46:	04054b63          	bltz	a0,80005a9c <sys_chdir+0x86>
    80005a4a:	f6040513          	addi	a0,s0,-160
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	552080e7          	jalr	1362(ra) # 80003fa0 <namei>
    80005a56:	84aa                	mv	s1,a0
    80005a58:	c131                	beqz	a0,80005a9c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	d9a080e7          	jalr	-614(ra) # 800037f4 <ilock>
  if(ip->type != T_DIR){
    80005a62:	04449703          	lh	a4,68(s1)
    80005a66:	4785                	li	a5,1
    80005a68:	04f71063          	bne	a4,a5,80005aa8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a6c:	8526                	mv	a0,s1
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	e48080e7          	jalr	-440(ra) # 800038b6 <iunlock>
  iput(p->cwd);
    80005a76:	15093503          	ld	a0,336(s2)
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	f34080e7          	jalr	-204(ra) # 800039ae <iput>
  end_op();
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	7bc080e7          	jalr	1980(ra) # 8000423e <end_op>
  p->cwd = ip;
    80005a8a:	14993823          	sd	s1,336(s2)
  return 0;
    80005a8e:	4501                	li	a0,0
}
    80005a90:	60ea                	ld	ra,152(sp)
    80005a92:	644a                	ld	s0,144(sp)
    80005a94:	64aa                	ld	s1,136(sp)
    80005a96:	690a                	ld	s2,128(sp)
    80005a98:	610d                	addi	sp,sp,160
    80005a9a:	8082                	ret
    end_op();
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	7a2080e7          	jalr	1954(ra) # 8000423e <end_op>
    return -1;
    80005aa4:	557d                	li	a0,-1
    80005aa6:	b7ed                	j	80005a90 <sys_chdir+0x7a>
    iunlockput(ip);
    80005aa8:	8526                	mv	a0,s1
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	fac080e7          	jalr	-84(ra) # 80003a56 <iunlockput>
    end_op();
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	78c080e7          	jalr	1932(ra) # 8000423e <end_op>
    return -1;
    80005aba:	557d                	li	a0,-1
    80005abc:	bfd1                	j	80005a90 <sys_chdir+0x7a>

0000000080005abe <sys_exec>:

uint64
sys_exec(void)
{
    80005abe:	7145                	addi	sp,sp,-464
    80005ac0:	e786                	sd	ra,456(sp)
    80005ac2:	e3a2                	sd	s0,448(sp)
    80005ac4:	ff26                	sd	s1,440(sp)
    80005ac6:	fb4a                	sd	s2,432(sp)
    80005ac8:	f74e                	sd	s3,424(sp)
    80005aca:	f352                	sd	s4,416(sp)
    80005acc:	ef56                	sd	s5,408(sp)
    80005ace:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ad0:	e3840593          	addi	a1,s0,-456
    80005ad4:	4505                	li	a0,1
    80005ad6:	ffffd097          	auipc	ra,0xffffd
    80005ada:	1d4080e7          	jalr	468(ra) # 80002caa <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ade:	08000613          	li	a2,128
    80005ae2:	f4040593          	addi	a1,s0,-192
    80005ae6:	4501                	li	a0,0
    80005ae8:	ffffd097          	auipc	ra,0xffffd
    80005aec:	1e2080e7          	jalr	482(ra) # 80002cca <argstr>
    80005af0:	87aa                	mv	a5,a0
    return -1;
    80005af2:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005af4:	0c07c363          	bltz	a5,80005bba <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005af8:	10000613          	li	a2,256
    80005afc:	4581                	li	a1,0
    80005afe:	e4040513          	addi	a0,s0,-448
    80005b02:	ffffb097          	auipc	ra,0xffffb
    80005b06:	1d0080e7          	jalr	464(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b0a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b0e:	89a6                	mv	s3,s1
    80005b10:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b12:	02000a13          	li	s4,32
    80005b16:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b1a:	00391513          	slli	a0,s2,0x3
    80005b1e:	e3040593          	addi	a1,s0,-464
    80005b22:	e3843783          	ld	a5,-456(s0)
    80005b26:	953e                	add	a0,a0,a5
    80005b28:	ffffd097          	auipc	ra,0xffffd
    80005b2c:	0c4080e7          	jalr	196(ra) # 80002bec <fetchaddr>
    80005b30:	02054a63          	bltz	a0,80005b64 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b34:	e3043783          	ld	a5,-464(s0)
    80005b38:	c3b9                	beqz	a5,80005b7e <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b3a:	ffffb097          	auipc	ra,0xffffb
    80005b3e:	fac080e7          	jalr	-84(ra) # 80000ae6 <kalloc>
    80005b42:	85aa                	mv	a1,a0
    80005b44:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b48:	cd11                	beqz	a0,80005b64 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b4a:	6605                	lui	a2,0x1
    80005b4c:	e3043503          	ld	a0,-464(s0)
    80005b50:	ffffd097          	auipc	ra,0xffffd
    80005b54:	0ee080e7          	jalr	238(ra) # 80002c3e <fetchstr>
    80005b58:	00054663          	bltz	a0,80005b64 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b5c:	0905                	addi	s2,s2,1
    80005b5e:	09a1                	addi	s3,s3,8
    80005b60:	fb491be3          	bne	s2,s4,80005b16 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b64:	f4040913          	addi	s2,s0,-192
    80005b68:	6088                	ld	a0,0(s1)
    80005b6a:	c539                	beqz	a0,80005bb8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b6c:	ffffb097          	auipc	ra,0xffffb
    80005b70:	e7c080e7          	jalr	-388(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b74:	04a1                	addi	s1,s1,8
    80005b76:	ff2499e3          	bne	s1,s2,80005b68 <sys_exec+0xaa>
  return -1;
    80005b7a:	557d                	li	a0,-1
    80005b7c:	a83d                	j	80005bba <sys_exec+0xfc>
      argv[i] = 0;
    80005b7e:	0a8e                	slli	s5,s5,0x3
    80005b80:	fc0a8793          	addi	a5,s5,-64
    80005b84:	00878ab3          	add	s5,a5,s0
    80005b88:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b8c:	e4040593          	addi	a1,s0,-448
    80005b90:	f4040513          	addi	a0,s0,-192
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	16e080e7          	jalr	366(ra) # 80004d02 <exec>
    80005b9c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b9e:	f4040993          	addi	s3,s0,-192
    80005ba2:	6088                	ld	a0,0(s1)
    80005ba4:	c901                	beqz	a0,80005bb4 <sys_exec+0xf6>
    kfree(argv[i]);
    80005ba6:	ffffb097          	auipc	ra,0xffffb
    80005baa:	e42080e7          	jalr	-446(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bae:	04a1                	addi	s1,s1,8
    80005bb0:	ff3499e3          	bne	s1,s3,80005ba2 <sys_exec+0xe4>
  return ret;
    80005bb4:	854a                	mv	a0,s2
    80005bb6:	a011                	j	80005bba <sys_exec+0xfc>
  return -1;
    80005bb8:	557d                	li	a0,-1
}
    80005bba:	60be                	ld	ra,456(sp)
    80005bbc:	641e                	ld	s0,448(sp)
    80005bbe:	74fa                	ld	s1,440(sp)
    80005bc0:	795a                	ld	s2,432(sp)
    80005bc2:	79ba                	ld	s3,424(sp)
    80005bc4:	7a1a                	ld	s4,416(sp)
    80005bc6:	6afa                	ld	s5,408(sp)
    80005bc8:	6179                	addi	sp,sp,464
    80005bca:	8082                	ret

0000000080005bcc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bcc:	7139                	addi	sp,sp,-64
    80005bce:	fc06                	sd	ra,56(sp)
    80005bd0:	f822                	sd	s0,48(sp)
    80005bd2:	f426                	sd	s1,40(sp)
    80005bd4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bd6:	ffffc097          	auipc	ra,0xffffc
    80005bda:	dd6080e7          	jalr	-554(ra) # 800019ac <myproc>
    80005bde:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005be0:	fd840593          	addi	a1,s0,-40
    80005be4:	4501                	li	a0,0
    80005be6:	ffffd097          	auipc	ra,0xffffd
    80005bea:	0c4080e7          	jalr	196(ra) # 80002caa <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005bee:	fc840593          	addi	a1,s0,-56
    80005bf2:	fd040513          	addi	a0,s0,-48
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	dc2080e7          	jalr	-574(ra) # 800049b8 <pipealloc>
    return -1;
    80005bfe:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c00:	0c054463          	bltz	a0,80005cc8 <sys_pipe+0xfc>
  fd0 = -1;
    80005c04:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c08:	fd043503          	ld	a0,-48(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	514080e7          	jalr	1300(ra) # 80005120 <fdalloc>
    80005c14:	fca42223          	sw	a0,-60(s0)
    80005c18:	08054b63          	bltz	a0,80005cae <sys_pipe+0xe2>
    80005c1c:	fc843503          	ld	a0,-56(s0)
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	500080e7          	jalr	1280(ra) # 80005120 <fdalloc>
    80005c28:	fca42023          	sw	a0,-64(s0)
    80005c2c:	06054863          	bltz	a0,80005c9c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c30:	4691                	li	a3,4
    80005c32:	fc440613          	addi	a2,s0,-60
    80005c36:	fd843583          	ld	a1,-40(s0)
    80005c3a:	68a8                	ld	a0,80(s1)
    80005c3c:	ffffc097          	auipc	ra,0xffffc
    80005c40:	a30080e7          	jalr	-1488(ra) # 8000166c <copyout>
    80005c44:	02054063          	bltz	a0,80005c64 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c48:	4691                	li	a3,4
    80005c4a:	fc040613          	addi	a2,s0,-64
    80005c4e:	fd843583          	ld	a1,-40(s0)
    80005c52:	0591                	addi	a1,a1,4
    80005c54:	68a8                	ld	a0,80(s1)
    80005c56:	ffffc097          	auipc	ra,0xffffc
    80005c5a:	a16080e7          	jalr	-1514(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c5e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c60:	06055463          	bgez	a0,80005cc8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c64:	fc442783          	lw	a5,-60(s0)
    80005c68:	07e9                	addi	a5,a5,26
    80005c6a:	078e                	slli	a5,a5,0x3
    80005c6c:	97a6                	add	a5,a5,s1
    80005c6e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c72:	fc042783          	lw	a5,-64(s0)
    80005c76:	07e9                	addi	a5,a5,26
    80005c78:	078e                	slli	a5,a5,0x3
    80005c7a:	94be                	add	s1,s1,a5
    80005c7c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c80:	fd043503          	ld	a0,-48(s0)
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	a04080e7          	jalr	-1532(ra) # 80004688 <fileclose>
    fileclose(wf);
    80005c8c:	fc843503          	ld	a0,-56(s0)
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	9f8080e7          	jalr	-1544(ra) # 80004688 <fileclose>
    return -1;
    80005c98:	57fd                	li	a5,-1
    80005c9a:	a03d                	j	80005cc8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c9c:	fc442783          	lw	a5,-60(s0)
    80005ca0:	0007c763          	bltz	a5,80005cae <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ca4:	07e9                	addi	a5,a5,26
    80005ca6:	078e                	slli	a5,a5,0x3
    80005ca8:	97a6                	add	a5,a5,s1
    80005caa:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005cae:	fd043503          	ld	a0,-48(s0)
    80005cb2:	fffff097          	auipc	ra,0xfffff
    80005cb6:	9d6080e7          	jalr	-1578(ra) # 80004688 <fileclose>
    fileclose(wf);
    80005cba:	fc843503          	ld	a0,-56(s0)
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	9ca080e7          	jalr	-1590(ra) # 80004688 <fileclose>
    return -1;
    80005cc6:	57fd                	li	a5,-1
}
    80005cc8:	853e                	mv	a0,a5
    80005cca:	70e2                	ld	ra,56(sp)
    80005ccc:	7442                	ld	s0,48(sp)
    80005cce:	74a2                	ld	s1,40(sp)
    80005cd0:	6121                	addi	sp,sp,64
    80005cd2:	8082                	ret
	...

0000000080005ce0 <kernelvec>:
    80005ce0:	7111                	addi	sp,sp,-256
    80005ce2:	e006                	sd	ra,0(sp)
    80005ce4:	e40a                	sd	sp,8(sp)
    80005ce6:	e80e                	sd	gp,16(sp)
    80005ce8:	ec12                	sd	tp,24(sp)
    80005cea:	f016                	sd	t0,32(sp)
    80005cec:	f41a                	sd	t1,40(sp)
    80005cee:	f81e                	sd	t2,48(sp)
    80005cf0:	fc22                	sd	s0,56(sp)
    80005cf2:	e0a6                	sd	s1,64(sp)
    80005cf4:	e4aa                	sd	a0,72(sp)
    80005cf6:	e8ae                	sd	a1,80(sp)
    80005cf8:	ecb2                	sd	a2,88(sp)
    80005cfa:	f0b6                	sd	a3,96(sp)
    80005cfc:	f4ba                	sd	a4,104(sp)
    80005cfe:	f8be                	sd	a5,112(sp)
    80005d00:	fcc2                	sd	a6,120(sp)
    80005d02:	e146                	sd	a7,128(sp)
    80005d04:	e54a                	sd	s2,136(sp)
    80005d06:	e94e                	sd	s3,144(sp)
    80005d08:	ed52                	sd	s4,152(sp)
    80005d0a:	f156                	sd	s5,160(sp)
    80005d0c:	f55a                	sd	s6,168(sp)
    80005d0e:	f95e                	sd	s7,176(sp)
    80005d10:	fd62                	sd	s8,184(sp)
    80005d12:	e1e6                	sd	s9,192(sp)
    80005d14:	e5ea                	sd	s10,200(sp)
    80005d16:	e9ee                	sd	s11,208(sp)
    80005d18:	edf2                	sd	t3,216(sp)
    80005d1a:	f1f6                	sd	t4,224(sp)
    80005d1c:	f5fa                	sd	t5,232(sp)
    80005d1e:	f9fe                	sd	t6,240(sp)
    80005d20:	d99fc0ef          	jal	ra,80002ab8 <kerneltrap>
    80005d24:	6082                	ld	ra,0(sp)
    80005d26:	6122                	ld	sp,8(sp)
    80005d28:	61c2                	ld	gp,16(sp)
    80005d2a:	7282                	ld	t0,32(sp)
    80005d2c:	7322                	ld	t1,40(sp)
    80005d2e:	73c2                	ld	t2,48(sp)
    80005d30:	7462                	ld	s0,56(sp)
    80005d32:	6486                	ld	s1,64(sp)
    80005d34:	6526                	ld	a0,72(sp)
    80005d36:	65c6                	ld	a1,80(sp)
    80005d38:	6666                	ld	a2,88(sp)
    80005d3a:	7686                	ld	a3,96(sp)
    80005d3c:	7726                	ld	a4,104(sp)
    80005d3e:	77c6                	ld	a5,112(sp)
    80005d40:	7866                	ld	a6,120(sp)
    80005d42:	688a                	ld	a7,128(sp)
    80005d44:	692a                	ld	s2,136(sp)
    80005d46:	69ca                	ld	s3,144(sp)
    80005d48:	6a6a                	ld	s4,152(sp)
    80005d4a:	7a8a                	ld	s5,160(sp)
    80005d4c:	7b2a                	ld	s6,168(sp)
    80005d4e:	7bca                	ld	s7,176(sp)
    80005d50:	7c6a                	ld	s8,184(sp)
    80005d52:	6c8e                	ld	s9,192(sp)
    80005d54:	6d2e                	ld	s10,200(sp)
    80005d56:	6dce                	ld	s11,208(sp)
    80005d58:	6e6e                	ld	t3,216(sp)
    80005d5a:	7e8e                	ld	t4,224(sp)
    80005d5c:	7f2e                	ld	t5,232(sp)
    80005d5e:	7fce                	ld	t6,240(sp)
    80005d60:	6111                	addi	sp,sp,256
    80005d62:	10200073          	sret
    80005d66:	00000013          	nop
    80005d6a:	00000013          	nop
    80005d6e:	0001                	nop

0000000080005d70 <timervec>:
    80005d70:	34051573          	csrrw	a0,mscratch,a0
    80005d74:	e10c                	sd	a1,0(a0)
    80005d76:	e510                	sd	a2,8(a0)
    80005d78:	e914                	sd	a3,16(a0)
    80005d7a:	6d0c                	ld	a1,24(a0)
    80005d7c:	7110                	ld	a2,32(a0)
    80005d7e:	6194                	ld	a3,0(a1)
    80005d80:	96b2                	add	a3,a3,a2
    80005d82:	e194                	sd	a3,0(a1)
    80005d84:	4589                	li	a1,2
    80005d86:	14459073          	csrw	sip,a1
    80005d8a:	6914                	ld	a3,16(a0)
    80005d8c:	6510                	ld	a2,8(a0)
    80005d8e:	610c                	ld	a1,0(a0)
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	30200073          	mret
	...

0000000080005d9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d9a:	1141                	addi	sp,sp,-16
    80005d9c:	e422                	sd	s0,8(sp)
    80005d9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005da0:	0c0007b7          	lui	a5,0xc000
    80005da4:	4705                	li	a4,1
    80005da6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005da8:	c3d8                	sw	a4,4(a5)
}
    80005daa:	6422                	ld	s0,8(sp)
    80005dac:	0141                	addi	sp,sp,16
    80005dae:	8082                	ret

0000000080005db0 <plicinithart>:

void
plicinithart(void)
{
    80005db0:	1141                	addi	sp,sp,-16
    80005db2:	e406                	sd	ra,8(sp)
    80005db4:	e022                	sd	s0,0(sp)
    80005db6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	bc8080e7          	jalr	-1080(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005dc0:	0085171b          	slliw	a4,a0,0x8
    80005dc4:	0c0027b7          	lui	a5,0xc002
    80005dc8:	97ba                	add	a5,a5,a4
    80005dca:	40200713          	li	a4,1026
    80005dce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005dd2:	00d5151b          	slliw	a0,a0,0xd
    80005dd6:	0c2017b7          	lui	a5,0xc201
    80005dda:	97aa                	add	a5,a5,a0
    80005ddc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005de0:	60a2                	ld	ra,8(sp)
    80005de2:	6402                	ld	s0,0(sp)
    80005de4:	0141                	addi	sp,sp,16
    80005de6:	8082                	ret

0000000080005de8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005de8:	1141                	addi	sp,sp,-16
    80005dea:	e406                	sd	ra,8(sp)
    80005dec:	e022                	sd	s0,0(sp)
    80005dee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005df0:	ffffc097          	auipc	ra,0xffffc
    80005df4:	b90080e7          	jalr	-1136(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005df8:	00d5151b          	slliw	a0,a0,0xd
    80005dfc:	0c2017b7          	lui	a5,0xc201
    80005e00:	97aa                	add	a5,a5,a0
  return irq;
}
    80005e02:	43c8                	lw	a0,4(a5)
    80005e04:	60a2                	ld	ra,8(sp)
    80005e06:	6402                	ld	s0,0(sp)
    80005e08:	0141                	addi	sp,sp,16
    80005e0a:	8082                	ret

0000000080005e0c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e0c:	1101                	addi	sp,sp,-32
    80005e0e:	ec06                	sd	ra,24(sp)
    80005e10:	e822                	sd	s0,16(sp)
    80005e12:	e426                	sd	s1,8(sp)
    80005e14:	1000                	addi	s0,sp,32
    80005e16:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e18:	ffffc097          	auipc	ra,0xffffc
    80005e1c:	b68080e7          	jalr	-1176(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e20:	00d5151b          	slliw	a0,a0,0xd
    80005e24:	0c2017b7          	lui	a5,0xc201
    80005e28:	97aa                	add	a5,a5,a0
    80005e2a:	c3c4                	sw	s1,4(a5)
}
    80005e2c:	60e2                	ld	ra,24(sp)
    80005e2e:	6442                	ld	s0,16(sp)
    80005e30:	64a2                	ld	s1,8(sp)
    80005e32:	6105                	addi	sp,sp,32
    80005e34:	8082                	ret

0000000080005e36 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e36:	1141                	addi	sp,sp,-16
    80005e38:	e406                	sd	ra,8(sp)
    80005e3a:	e022                	sd	s0,0(sp)
    80005e3c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e3e:	479d                	li	a5,7
    80005e40:	04a7cc63          	blt	a5,a0,80005e98 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e44:	0001c797          	auipc	a5,0x1c
    80005e48:	e2c78793          	addi	a5,a5,-468 # 80021c70 <disk>
    80005e4c:	97aa                	add	a5,a5,a0
    80005e4e:	0187c783          	lbu	a5,24(a5)
    80005e52:	ebb9                	bnez	a5,80005ea8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e54:	00451693          	slli	a3,a0,0x4
    80005e58:	0001c797          	auipc	a5,0x1c
    80005e5c:	e1878793          	addi	a5,a5,-488 # 80021c70 <disk>
    80005e60:	6398                	ld	a4,0(a5)
    80005e62:	9736                	add	a4,a4,a3
    80005e64:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005e68:	6398                	ld	a4,0(a5)
    80005e6a:	9736                	add	a4,a4,a3
    80005e6c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e70:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e74:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e78:	97aa                	add	a5,a5,a0
    80005e7a:	4705                	li	a4,1
    80005e7c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005e80:	0001c517          	auipc	a0,0x1c
    80005e84:	e0850513          	addi	a0,a0,-504 # 80021c88 <disk+0x18>
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	230080e7          	jalr	560(ra) # 800020b8 <wakeup>
}
    80005e90:	60a2                	ld	ra,8(sp)
    80005e92:	6402                	ld	s0,0(sp)
    80005e94:	0141                	addi	sp,sp,16
    80005e96:	8082                	ret
    panic("free_desc 1");
    80005e98:	00003517          	auipc	a0,0x3
    80005e9c:	8f050513          	addi	a0,a0,-1808 # 80008788 <syscalls+0x2f8>
    80005ea0:	ffffa097          	auipc	ra,0xffffa
    80005ea4:	6a0080e7          	jalr	1696(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005ea8:	00003517          	auipc	a0,0x3
    80005eac:	8f050513          	addi	a0,a0,-1808 # 80008798 <syscalls+0x308>
    80005eb0:	ffffa097          	auipc	ra,0xffffa
    80005eb4:	690080e7          	jalr	1680(ra) # 80000540 <panic>

0000000080005eb8 <virtio_disk_init>:
{
    80005eb8:	1101                	addi	sp,sp,-32
    80005eba:	ec06                	sd	ra,24(sp)
    80005ebc:	e822                	sd	s0,16(sp)
    80005ebe:	e426                	sd	s1,8(sp)
    80005ec0:	e04a                	sd	s2,0(sp)
    80005ec2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ec4:	00003597          	auipc	a1,0x3
    80005ec8:	8e458593          	addi	a1,a1,-1820 # 800087a8 <syscalls+0x318>
    80005ecc:	0001c517          	auipc	a0,0x1c
    80005ed0:	ecc50513          	addi	a0,a0,-308 # 80021d98 <disk+0x128>
    80005ed4:	ffffb097          	auipc	ra,0xffffb
    80005ed8:	c72080e7          	jalr	-910(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005edc:	100017b7          	lui	a5,0x10001
    80005ee0:	4398                	lw	a4,0(a5)
    80005ee2:	2701                	sext.w	a4,a4
    80005ee4:	747277b7          	lui	a5,0x74727
    80005ee8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eec:	14f71b63          	bne	a4,a5,80006042 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ef0:	100017b7          	lui	a5,0x10001
    80005ef4:	43dc                	lw	a5,4(a5)
    80005ef6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ef8:	4709                	li	a4,2
    80005efa:	14e79463          	bne	a5,a4,80006042 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005efe:	100017b7          	lui	a5,0x10001
    80005f02:	479c                	lw	a5,8(a5)
    80005f04:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f06:	12e79e63          	bne	a5,a4,80006042 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f0a:	100017b7          	lui	a5,0x10001
    80005f0e:	47d8                	lw	a4,12(a5)
    80005f10:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f12:	554d47b7          	lui	a5,0x554d4
    80005f16:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f1a:	12f71463          	bne	a4,a5,80006042 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f1e:	100017b7          	lui	a5,0x10001
    80005f22:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f26:	4705                	li	a4,1
    80005f28:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f2a:	470d                	li	a4,3
    80005f2c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f2e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f30:	c7ffe6b7          	lui	a3,0xc7ffe
    80005f34:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9af>
    80005f38:	8f75                	and	a4,a4,a3
    80005f3a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f3c:	472d                	li	a4,11
    80005f3e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f40:	5bbc                	lw	a5,112(a5)
    80005f42:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f46:	8ba1                	andi	a5,a5,8
    80005f48:	10078563          	beqz	a5,80006052 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f4c:	100017b7          	lui	a5,0x10001
    80005f50:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f54:	43fc                	lw	a5,68(a5)
    80005f56:	2781                	sext.w	a5,a5
    80005f58:	10079563          	bnez	a5,80006062 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f5c:	100017b7          	lui	a5,0x10001
    80005f60:	5bdc                	lw	a5,52(a5)
    80005f62:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f64:	10078763          	beqz	a5,80006072 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005f68:	471d                	li	a4,7
    80005f6a:	10f77c63          	bgeu	a4,a5,80006082 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005f6e:	ffffb097          	auipc	ra,0xffffb
    80005f72:	b78080e7          	jalr	-1160(ra) # 80000ae6 <kalloc>
    80005f76:	0001c497          	auipc	s1,0x1c
    80005f7a:	cfa48493          	addi	s1,s1,-774 # 80021c70 <disk>
    80005f7e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f80:	ffffb097          	auipc	ra,0xffffb
    80005f84:	b66080e7          	jalr	-1178(ra) # 80000ae6 <kalloc>
    80005f88:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f8a:	ffffb097          	auipc	ra,0xffffb
    80005f8e:	b5c080e7          	jalr	-1188(ra) # 80000ae6 <kalloc>
    80005f92:	87aa                	mv	a5,a0
    80005f94:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f96:	6088                	ld	a0,0(s1)
    80005f98:	cd6d                	beqz	a0,80006092 <virtio_disk_init+0x1da>
    80005f9a:	0001c717          	auipc	a4,0x1c
    80005f9e:	cde73703          	ld	a4,-802(a4) # 80021c78 <disk+0x8>
    80005fa2:	cb65                	beqz	a4,80006092 <virtio_disk_init+0x1da>
    80005fa4:	c7fd                	beqz	a5,80006092 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005fa6:	6605                	lui	a2,0x1
    80005fa8:	4581                	li	a1,0
    80005faa:	ffffb097          	auipc	ra,0xffffb
    80005fae:	d28080e7          	jalr	-728(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005fb2:	0001c497          	auipc	s1,0x1c
    80005fb6:	cbe48493          	addi	s1,s1,-834 # 80021c70 <disk>
    80005fba:	6605                	lui	a2,0x1
    80005fbc:	4581                	li	a1,0
    80005fbe:	6488                	ld	a0,8(s1)
    80005fc0:	ffffb097          	auipc	ra,0xffffb
    80005fc4:	d12080e7          	jalr	-750(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005fc8:	6605                	lui	a2,0x1
    80005fca:	4581                	li	a1,0
    80005fcc:	6888                	ld	a0,16(s1)
    80005fce:	ffffb097          	auipc	ra,0xffffb
    80005fd2:	d04080e7          	jalr	-764(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fd6:	100017b7          	lui	a5,0x10001
    80005fda:	4721                	li	a4,8
    80005fdc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005fde:	4098                	lw	a4,0(s1)
    80005fe0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005fe4:	40d8                	lw	a4,4(s1)
    80005fe6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005fea:	6498                	ld	a4,8(s1)
    80005fec:	0007069b          	sext.w	a3,a4
    80005ff0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005ff4:	9701                	srai	a4,a4,0x20
    80005ff6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005ffa:	6898                	ld	a4,16(s1)
    80005ffc:	0007069b          	sext.w	a3,a4
    80006000:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006004:	9701                	srai	a4,a4,0x20
    80006006:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000600a:	4705                	li	a4,1
    8000600c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000600e:	00e48c23          	sb	a4,24(s1)
    80006012:	00e48ca3          	sb	a4,25(s1)
    80006016:	00e48d23          	sb	a4,26(s1)
    8000601a:	00e48da3          	sb	a4,27(s1)
    8000601e:	00e48e23          	sb	a4,28(s1)
    80006022:	00e48ea3          	sb	a4,29(s1)
    80006026:	00e48f23          	sb	a4,30(s1)
    8000602a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000602e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006032:	0727a823          	sw	s2,112(a5)
}
    80006036:	60e2                	ld	ra,24(sp)
    80006038:	6442                	ld	s0,16(sp)
    8000603a:	64a2                	ld	s1,8(sp)
    8000603c:	6902                	ld	s2,0(sp)
    8000603e:	6105                	addi	sp,sp,32
    80006040:	8082                	ret
    panic("could not find virtio disk");
    80006042:	00002517          	auipc	a0,0x2
    80006046:	77650513          	addi	a0,a0,1910 # 800087b8 <syscalls+0x328>
    8000604a:	ffffa097          	auipc	ra,0xffffa
    8000604e:	4f6080e7          	jalr	1270(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006052:	00002517          	auipc	a0,0x2
    80006056:	78650513          	addi	a0,a0,1926 # 800087d8 <syscalls+0x348>
    8000605a:	ffffa097          	auipc	ra,0xffffa
    8000605e:	4e6080e7          	jalr	1254(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006062:	00002517          	auipc	a0,0x2
    80006066:	79650513          	addi	a0,a0,1942 # 800087f8 <syscalls+0x368>
    8000606a:	ffffa097          	auipc	ra,0xffffa
    8000606e:	4d6080e7          	jalr	1238(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006072:	00002517          	auipc	a0,0x2
    80006076:	7a650513          	addi	a0,a0,1958 # 80008818 <syscalls+0x388>
    8000607a:	ffffa097          	auipc	ra,0xffffa
    8000607e:	4c6080e7          	jalr	1222(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006082:	00002517          	auipc	a0,0x2
    80006086:	7b650513          	addi	a0,a0,1974 # 80008838 <syscalls+0x3a8>
    8000608a:	ffffa097          	auipc	ra,0xffffa
    8000608e:	4b6080e7          	jalr	1206(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006092:	00002517          	auipc	a0,0x2
    80006096:	7c650513          	addi	a0,a0,1990 # 80008858 <syscalls+0x3c8>
    8000609a:	ffffa097          	auipc	ra,0xffffa
    8000609e:	4a6080e7          	jalr	1190(ra) # 80000540 <panic>

00000000800060a2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060a2:	7119                	addi	sp,sp,-128
    800060a4:	fc86                	sd	ra,120(sp)
    800060a6:	f8a2                	sd	s0,112(sp)
    800060a8:	f4a6                	sd	s1,104(sp)
    800060aa:	f0ca                	sd	s2,96(sp)
    800060ac:	ecce                	sd	s3,88(sp)
    800060ae:	e8d2                	sd	s4,80(sp)
    800060b0:	e4d6                	sd	s5,72(sp)
    800060b2:	e0da                	sd	s6,64(sp)
    800060b4:	fc5e                	sd	s7,56(sp)
    800060b6:	f862                	sd	s8,48(sp)
    800060b8:	f466                	sd	s9,40(sp)
    800060ba:	f06a                	sd	s10,32(sp)
    800060bc:	ec6e                	sd	s11,24(sp)
    800060be:	0100                	addi	s0,sp,128
    800060c0:	8aaa                	mv	s5,a0
    800060c2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060c4:	00c52d03          	lw	s10,12(a0)
    800060c8:	001d1d1b          	slliw	s10,s10,0x1
    800060cc:	1d02                	slli	s10,s10,0x20
    800060ce:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800060d2:	0001c517          	auipc	a0,0x1c
    800060d6:	cc650513          	addi	a0,a0,-826 # 80021d98 <disk+0x128>
    800060da:	ffffb097          	auipc	ra,0xffffb
    800060de:	afc080e7          	jalr	-1284(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800060e2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060e4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800060e6:	0001cb97          	auipc	s7,0x1c
    800060ea:	b8ab8b93          	addi	s7,s7,-1142 # 80021c70 <disk>
  for(int i = 0; i < 3; i++){
    800060ee:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060f0:	0001cc97          	auipc	s9,0x1c
    800060f4:	ca8c8c93          	addi	s9,s9,-856 # 80021d98 <disk+0x128>
    800060f8:	a08d                	j	8000615a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800060fa:	00fb8733          	add	a4,s7,a5
    800060fe:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006102:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006104:	0207c563          	bltz	a5,8000612e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006108:	2905                	addiw	s2,s2,1
    8000610a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000610c:	05690c63          	beq	s2,s6,80006164 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006110:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006112:	0001c717          	auipc	a4,0x1c
    80006116:	b5e70713          	addi	a4,a4,-1186 # 80021c70 <disk>
    8000611a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000611c:	01874683          	lbu	a3,24(a4)
    80006120:	fee9                	bnez	a3,800060fa <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006122:	2785                	addiw	a5,a5,1
    80006124:	0705                	addi	a4,a4,1
    80006126:	fe979be3          	bne	a5,s1,8000611c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000612a:	57fd                	li	a5,-1
    8000612c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000612e:	01205d63          	blez	s2,80006148 <virtio_disk_rw+0xa6>
    80006132:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006134:	000a2503          	lw	a0,0(s4)
    80006138:	00000097          	auipc	ra,0x0
    8000613c:	cfe080e7          	jalr	-770(ra) # 80005e36 <free_desc>
      for(int j = 0; j < i; j++)
    80006140:	2d85                	addiw	s11,s11,1
    80006142:	0a11                	addi	s4,s4,4
    80006144:	ff2d98e3          	bne	s11,s2,80006134 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006148:	85e6                	mv	a1,s9
    8000614a:	0001c517          	auipc	a0,0x1c
    8000614e:	b3e50513          	addi	a0,a0,-1218 # 80021c88 <disk+0x18>
    80006152:	ffffc097          	auipc	ra,0xffffc
    80006156:	f02080e7          	jalr	-254(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    8000615a:	f8040a13          	addi	s4,s0,-128
{
    8000615e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006160:	894e                	mv	s2,s3
    80006162:	b77d                	j	80006110 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006164:	f8042503          	lw	a0,-128(s0)
    80006168:	00a50713          	addi	a4,a0,10
    8000616c:	0712                	slli	a4,a4,0x4

  if(write)
    8000616e:	0001c797          	auipc	a5,0x1c
    80006172:	b0278793          	addi	a5,a5,-1278 # 80021c70 <disk>
    80006176:	00e786b3          	add	a3,a5,a4
    8000617a:	01803633          	snez	a2,s8
    8000617e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006180:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006184:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006188:	f6070613          	addi	a2,a4,-160
    8000618c:	6394                	ld	a3,0(a5)
    8000618e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006190:	00870593          	addi	a1,a4,8
    80006194:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006196:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006198:	0007b803          	ld	a6,0(a5)
    8000619c:	9642                	add	a2,a2,a6
    8000619e:	46c1                	li	a3,16
    800061a0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061a2:	4585                	li	a1,1
    800061a4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800061a8:	f8442683          	lw	a3,-124(s0)
    800061ac:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061b0:	0692                	slli	a3,a3,0x4
    800061b2:	9836                	add	a6,a6,a3
    800061b4:	058a8613          	addi	a2,s5,88
    800061b8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800061bc:	0007b803          	ld	a6,0(a5)
    800061c0:	96c2                	add	a3,a3,a6
    800061c2:	40000613          	li	a2,1024
    800061c6:	c690                	sw	a2,8(a3)
  if(write)
    800061c8:	001c3613          	seqz	a2,s8
    800061cc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061d0:	00166613          	ori	a2,a2,1
    800061d4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061d8:	f8842603          	lw	a2,-120(s0)
    800061dc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061e0:	00250693          	addi	a3,a0,2
    800061e4:	0692                	slli	a3,a3,0x4
    800061e6:	96be                	add	a3,a3,a5
    800061e8:	58fd                	li	a7,-1
    800061ea:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061ee:	0612                	slli	a2,a2,0x4
    800061f0:	9832                	add	a6,a6,a2
    800061f2:	f9070713          	addi	a4,a4,-112
    800061f6:	973e                	add	a4,a4,a5
    800061f8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800061fc:	6398                	ld	a4,0(a5)
    800061fe:	9732                	add	a4,a4,a2
    80006200:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006202:	4609                	li	a2,2
    80006204:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006208:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000620c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006210:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006214:	6794                	ld	a3,8(a5)
    80006216:	0026d703          	lhu	a4,2(a3)
    8000621a:	8b1d                	andi	a4,a4,7
    8000621c:	0706                	slli	a4,a4,0x1
    8000621e:	96ba                	add	a3,a3,a4
    80006220:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006224:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006228:	6798                	ld	a4,8(a5)
    8000622a:	00275783          	lhu	a5,2(a4)
    8000622e:	2785                	addiw	a5,a5,1
    80006230:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006234:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006238:	100017b7          	lui	a5,0x10001
    8000623c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006240:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006244:	0001c917          	auipc	s2,0x1c
    80006248:	b5490913          	addi	s2,s2,-1196 # 80021d98 <disk+0x128>
  while(b->disk == 1) {
    8000624c:	4485                	li	s1,1
    8000624e:	00b79c63          	bne	a5,a1,80006266 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006252:	85ca                	mv	a1,s2
    80006254:	8556                	mv	a0,s5
    80006256:	ffffc097          	auipc	ra,0xffffc
    8000625a:	dfe080e7          	jalr	-514(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    8000625e:	004aa783          	lw	a5,4(s5)
    80006262:	fe9788e3          	beq	a5,s1,80006252 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006266:	f8042903          	lw	s2,-128(s0)
    8000626a:	00290713          	addi	a4,s2,2
    8000626e:	0712                	slli	a4,a4,0x4
    80006270:	0001c797          	auipc	a5,0x1c
    80006274:	a0078793          	addi	a5,a5,-1536 # 80021c70 <disk>
    80006278:	97ba                	add	a5,a5,a4
    8000627a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000627e:	0001c997          	auipc	s3,0x1c
    80006282:	9f298993          	addi	s3,s3,-1550 # 80021c70 <disk>
    80006286:	00491713          	slli	a4,s2,0x4
    8000628a:	0009b783          	ld	a5,0(s3)
    8000628e:	97ba                	add	a5,a5,a4
    80006290:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006294:	854a                	mv	a0,s2
    80006296:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000629a:	00000097          	auipc	ra,0x0
    8000629e:	b9c080e7          	jalr	-1124(ra) # 80005e36 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062a2:	8885                	andi	s1,s1,1
    800062a4:	f0ed                	bnez	s1,80006286 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062a6:	0001c517          	auipc	a0,0x1c
    800062aa:	af250513          	addi	a0,a0,-1294 # 80021d98 <disk+0x128>
    800062ae:	ffffb097          	auipc	ra,0xffffb
    800062b2:	9dc080e7          	jalr	-1572(ra) # 80000c8a <release>
}
    800062b6:	70e6                	ld	ra,120(sp)
    800062b8:	7446                	ld	s0,112(sp)
    800062ba:	74a6                	ld	s1,104(sp)
    800062bc:	7906                	ld	s2,96(sp)
    800062be:	69e6                	ld	s3,88(sp)
    800062c0:	6a46                	ld	s4,80(sp)
    800062c2:	6aa6                	ld	s5,72(sp)
    800062c4:	6b06                	ld	s6,64(sp)
    800062c6:	7be2                	ld	s7,56(sp)
    800062c8:	7c42                	ld	s8,48(sp)
    800062ca:	7ca2                	ld	s9,40(sp)
    800062cc:	7d02                	ld	s10,32(sp)
    800062ce:	6de2                	ld	s11,24(sp)
    800062d0:	6109                	addi	sp,sp,128
    800062d2:	8082                	ret

00000000800062d4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062d4:	1101                	addi	sp,sp,-32
    800062d6:	ec06                	sd	ra,24(sp)
    800062d8:	e822                	sd	s0,16(sp)
    800062da:	e426                	sd	s1,8(sp)
    800062dc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062de:	0001c497          	auipc	s1,0x1c
    800062e2:	99248493          	addi	s1,s1,-1646 # 80021c70 <disk>
    800062e6:	0001c517          	auipc	a0,0x1c
    800062ea:	ab250513          	addi	a0,a0,-1358 # 80021d98 <disk+0x128>
    800062ee:	ffffb097          	auipc	ra,0xffffb
    800062f2:	8e8080e7          	jalr	-1816(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062f6:	10001737          	lui	a4,0x10001
    800062fa:	533c                	lw	a5,96(a4)
    800062fc:	8b8d                	andi	a5,a5,3
    800062fe:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006300:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006304:	689c                	ld	a5,16(s1)
    80006306:	0204d703          	lhu	a4,32(s1)
    8000630a:	0027d783          	lhu	a5,2(a5)
    8000630e:	04f70863          	beq	a4,a5,8000635e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006312:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006316:	6898                	ld	a4,16(s1)
    80006318:	0204d783          	lhu	a5,32(s1)
    8000631c:	8b9d                	andi	a5,a5,7
    8000631e:	078e                	slli	a5,a5,0x3
    80006320:	97ba                	add	a5,a5,a4
    80006322:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006324:	00278713          	addi	a4,a5,2
    80006328:	0712                	slli	a4,a4,0x4
    8000632a:	9726                	add	a4,a4,s1
    8000632c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006330:	e721                	bnez	a4,80006378 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006332:	0789                	addi	a5,a5,2
    80006334:	0792                	slli	a5,a5,0x4
    80006336:	97a6                	add	a5,a5,s1
    80006338:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000633a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000633e:	ffffc097          	auipc	ra,0xffffc
    80006342:	d7a080e7          	jalr	-646(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    80006346:	0204d783          	lhu	a5,32(s1)
    8000634a:	2785                	addiw	a5,a5,1
    8000634c:	17c2                	slli	a5,a5,0x30
    8000634e:	93c1                	srli	a5,a5,0x30
    80006350:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006354:	6898                	ld	a4,16(s1)
    80006356:	00275703          	lhu	a4,2(a4)
    8000635a:	faf71ce3          	bne	a4,a5,80006312 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000635e:	0001c517          	auipc	a0,0x1c
    80006362:	a3a50513          	addi	a0,a0,-1478 # 80021d98 <disk+0x128>
    80006366:	ffffb097          	auipc	ra,0xffffb
    8000636a:	924080e7          	jalr	-1756(ra) # 80000c8a <release>
}
    8000636e:	60e2                	ld	ra,24(sp)
    80006370:	6442                	ld	s0,16(sp)
    80006372:	64a2                	ld	s1,8(sp)
    80006374:	6105                	addi	sp,sp,32
    80006376:	8082                	ret
      panic("virtio_disk_intr status");
    80006378:	00002517          	auipc	a0,0x2
    8000637c:	4f850513          	addi	a0,a0,1272 # 80008870 <syscalls+0x3e0>
    80006380:	ffffa097          	auipc	ra,0xffffa
    80006384:	1c0080e7          	jalr	448(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
