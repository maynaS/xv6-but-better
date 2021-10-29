
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	f2c78793          	addi	a5,a5,-212 # 80005f90 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	520080e7          	jalr	1312(ra) # 8000264c <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	84a080e7          	jalr	-1974(ra) # 80001a0e <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f26080e7          	jalr	-218(ra) # 800020fa <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	3e6080e7          	jalr	998(ra) # 800025f6 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

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
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

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
    800002f6:	3b0080e7          	jalr	944(ra) # 800026a2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f8c080e7          	jalr	-116(ra) # 800023d2 <wakeup>
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
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	2a078793          	addi	a5,a5,672 # 80021718 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
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
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
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
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	f8c50513          	addi	a0,a0,-116 # 800084f8 <states.1738+0x230>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	b32080e7          	jalr	-1230(ra) # 800023d2 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	7ce080e7          	jalr	1998(ra) # 800020fa <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e74080e7          	jalr	-396(ra) # 800019f2 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	e42080e7          	jalr	-446(ra) # 800019f2 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e36080e7          	jalr	-458(ra) # 800019f2 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	e1e080e7          	jalr	-482(ra) # 800019f2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	dde080e7          	jalr	-546(ra) # 800019f2 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	db2080e7          	jalr	-590(ra) # 800019f2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b4c080e7          	jalr	-1204(ra) # 800019e2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	b30080e7          	jalr	-1232(ra) # 800019e2 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	90e080e7          	jalr	-1778(ra) # 800027e2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	0f4080e7          	jalr	244(ra) # 80005fd0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	050080e7          	jalr	80(ra) # 80001f34 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	5fc50513          	addi	a0,a0,1532 # 800084f8 <states.1738+0x230>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	5dc50513          	addi	a0,a0,1500 # 800084f8 <states.1738+0x230>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	9ee080e7          	jalr	-1554(ra) # 80001932 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	86e080e7          	jalr	-1938(ra) # 800027ba <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	88e080e7          	jalr	-1906(ra) # 800027e2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	05e080e7          	jalr	94(ra) # 80005fba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	06c080e7          	jalr	108(ra) # 80005fd0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	246080e7          	jalr	582(ra) # 800031b2 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	8d6080e7          	jalr	-1834(ra) # 8000384a <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	880080e7          	jalr	-1920(ra) # 800047fc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	16e080e7          	jalr	366(ra) # 800060f2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d6e080e7          	jalr	-658(ra) # 80001cfa <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	65c080e7          	jalr	1628(ra) # 8000189c <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <inc_runtime>:
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

void inc_runtime() {
    8000183e:	7179                	addi	sp,sp,-48
    80001840:	f406                	sd	ra,40(sp)
    80001842:	f022                	sd	s0,32(sp)
    80001844:	ec26                	sd	s1,24(sp)
    80001846:	e84a                	sd	s2,16(sp)
    80001848:	e44e                	sd	s3,8(sp)
    8000184a:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	00010497          	auipc	s1,0x10
    80001850:	e8448493          	addi	s1,s1,-380 # 800116d0 <proc>
  {
    acquire(&p->lock);
    if (p->state==RUNNING)
    80001854:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80001856:	00016917          	auipc	s2,0x16
    8000185a:	c7a90913          	addi	s2,s2,-902 # 800174d0 <tickslock>
    8000185e:	a811                	j	80001872 <inc_runtime+0x34>
    {
      p->run_time++;
    }
    
    release(&p->lock);
    80001860:	8526                	mv	a0,s1
    80001862:	fffff097          	auipc	ra,0xfffff
    80001866:	436080e7          	jalr	1078(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000186a:	17848493          	addi	s1,s1,376
    8000186e:	03248063          	beq	s1,s2,8000188e <inc_runtime+0x50>
    acquire(&p->lock);
    80001872:	8526                	mv	a0,s1
    80001874:	fffff097          	auipc	ra,0xfffff
    80001878:	370080e7          	jalr	880(ra) # 80000be4 <acquire>
    if (p->state==RUNNING)
    8000187c:	4c9c                	lw	a5,24(s1)
    8000187e:	ff3791e3          	bne	a5,s3,80001860 <inc_runtime+0x22>
      p->run_time++;
    80001882:	1744a783          	lw	a5,372(s1)
    80001886:	2785                	addiw	a5,a5,1
    80001888:	16f4aa23          	sw	a5,372(s1)
    8000188c:	bfd1                	j	80001860 <inc_runtime+0x22>
  }
}
    8000188e:	70a2                	ld	ra,40(sp)
    80001890:	7402                	ld	s0,32(sp)
    80001892:	64e2                	ld	s1,24(sp)
    80001894:	6942                	ld	s2,16(sp)
    80001896:	69a2                	ld	s3,8(sp)
    80001898:	6145                	addi	sp,sp,48
    8000189a:	8082                	ret

000000008000189c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000189c:	7139                	addi	sp,sp,-64
    8000189e:	fc06                	sd	ra,56(sp)
    800018a0:	f822                	sd	s0,48(sp)
    800018a2:	f426                	sd	s1,40(sp)
    800018a4:	f04a                	sd	s2,32(sp)
    800018a6:	ec4e                	sd	s3,24(sp)
    800018a8:	e852                	sd	s4,16(sp)
    800018aa:	e456                	sd	s5,8(sp)
    800018ac:	e05a                	sd	s6,0(sp)
    800018ae:	0080                	addi	s0,sp,64
    800018b0:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b2:	00010497          	auipc	s1,0x10
    800018b6:	e1e48493          	addi	s1,s1,-482 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018ba:	8b26                	mv	s6,s1
    800018bc:	00006a97          	auipc	s5,0x6
    800018c0:	744a8a93          	addi	s5,s5,1860 # 80008000 <etext>
    800018c4:	04000937          	lui	s2,0x4000
    800018c8:	197d                	addi	s2,s2,-1
    800018ca:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018cc:	00016a17          	auipc	s4,0x16
    800018d0:	c04a0a13          	addi	s4,s4,-1020 # 800174d0 <tickslock>
    char *pa = kalloc();
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	220080e7          	jalr	544(ra) # 80000af4 <kalloc>
    800018dc:	862a                	mv	a2,a0
    if(pa == 0)
    800018de:	c131                	beqz	a0,80001922 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018e0:	416485b3          	sub	a1,s1,s6
    800018e4:	858d                	srai	a1,a1,0x3
    800018e6:	000ab783          	ld	a5,0(s5)
    800018ea:	02f585b3          	mul	a1,a1,a5
    800018ee:	2585                	addiw	a1,a1,1
    800018f0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018f4:	4719                	li	a4,6
    800018f6:	6685                	lui	a3,0x1
    800018f8:	40b905b3          	sub	a1,s2,a1
    800018fc:	854e                	mv	a0,s3
    800018fe:	00000097          	auipc	ra,0x0
    80001902:	852080e7          	jalr	-1966(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001906:	17848493          	addi	s1,s1,376
    8000190a:	fd4495e3          	bne	s1,s4,800018d4 <proc_mapstacks+0x38>
  }
}
    8000190e:	70e2                	ld	ra,56(sp)
    80001910:	7442                	ld	s0,48(sp)
    80001912:	74a2                	ld	s1,40(sp)
    80001914:	7902                	ld	s2,32(sp)
    80001916:	69e2                	ld	s3,24(sp)
    80001918:	6a42                	ld	s4,16(sp)
    8000191a:	6aa2                	ld	s5,8(sp)
    8000191c:	6b02                	ld	s6,0(sp)
    8000191e:	6121                	addi	sp,sp,64
    80001920:	8082                	ret
      panic("kalloc");
    80001922:	00007517          	auipc	a0,0x7
    80001926:	8b650513          	addi	a0,a0,-1866 # 800081d8 <digits+0x198>
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	c14080e7          	jalr	-1004(ra) # 8000053e <panic>

0000000080001932 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001932:	7139                	addi	sp,sp,-64
    80001934:	fc06                	sd	ra,56(sp)
    80001936:	f822                	sd	s0,48(sp)
    80001938:	f426                	sd	s1,40(sp)
    8000193a:	f04a                	sd	s2,32(sp)
    8000193c:	ec4e                	sd	s3,24(sp)
    8000193e:	e852                	sd	s4,16(sp)
    80001940:	e456                	sd	s5,8(sp)
    80001942:	e05a                	sd	s6,0(sp)
    80001944:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001946:	00007597          	auipc	a1,0x7
    8000194a:	89a58593          	addi	a1,a1,-1894 # 800081e0 <digits+0x1a0>
    8000194e:	00010517          	auipc	a0,0x10
    80001952:	95250513          	addi	a0,a0,-1710 # 800112a0 <pid_lock>
    80001956:	fffff097          	auipc	ra,0xfffff
    8000195a:	1fe080e7          	jalr	510(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000195e:	00007597          	auipc	a1,0x7
    80001962:	88a58593          	addi	a1,a1,-1910 # 800081e8 <digits+0x1a8>
    80001966:	00010517          	auipc	a0,0x10
    8000196a:	95250513          	addi	a0,a0,-1710 # 800112b8 <wait_lock>
    8000196e:	fffff097          	auipc	ra,0xfffff
    80001972:	1e6080e7          	jalr	486(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001976:	00010497          	auipc	s1,0x10
    8000197a:	d5a48493          	addi	s1,s1,-678 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    8000197e:	00007b17          	auipc	s6,0x7
    80001982:	87ab0b13          	addi	s6,s6,-1926 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001986:	8aa6                	mv	s5,s1
    80001988:	00006a17          	auipc	s4,0x6
    8000198c:	678a0a13          	addi	s4,s4,1656 # 80008000 <etext>
    80001990:	04000937          	lui	s2,0x4000
    80001994:	197d                	addi	s2,s2,-1
    80001996:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001998:	00016997          	auipc	s3,0x16
    8000199c:	b3898993          	addi	s3,s3,-1224 # 800174d0 <tickslock>
      initlock(&p->lock, "proc");
    800019a0:	85da                	mv	a1,s6
    800019a2:	8526                	mv	a0,s1
    800019a4:	fffff097          	auipc	ra,0xfffff
    800019a8:	1b0080e7          	jalr	432(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019ac:	415487b3          	sub	a5,s1,s5
    800019b0:	878d                	srai	a5,a5,0x3
    800019b2:	000a3703          	ld	a4,0(s4)
    800019b6:	02e787b3          	mul	a5,a5,a4
    800019ba:	2785                	addiw	a5,a5,1
    800019bc:	00d7979b          	slliw	a5,a5,0xd
    800019c0:	40f907b3          	sub	a5,s2,a5
    800019c4:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c6:	17848493          	addi	s1,s1,376
    800019ca:	fd349be3          	bne	s1,s3,800019a0 <procinit+0x6e>
  }
}
    800019ce:	70e2                	ld	ra,56(sp)
    800019d0:	7442                	ld	s0,48(sp)
    800019d2:	74a2                	ld	s1,40(sp)
    800019d4:	7902                	ld	s2,32(sp)
    800019d6:	69e2                	ld	s3,24(sp)
    800019d8:	6a42                	ld	s4,16(sp)
    800019da:	6aa2                	ld	s5,8(sp)
    800019dc:	6b02                	ld	s6,0(sp)
    800019de:	6121                	addi	sp,sp,64
    800019e0:	8082                	ret

00000000800019e2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019e2:	1141                	addi	sp,sp,-16
    800019e4:	e422                	sd	s0,8(sp)
    800019e6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019e8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019ea:	2501                	sext.w	a0,a0
    800019ec:	6422                	ld	s0,8(sp)
    800019ee:	0141                	addi	sp,sp,16
    800019f0:	8082                	ret

00000000800019f2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019f2:	1141                	addi	sp,sp,-16
    800019f4:	e422                	sd	s0,8(sp)
    800019f6:	0800                	addi	s0,sp,16
    800019f8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019fa:	2781                	sext.w	a5,a5
    800019fc:	079e                	slli	a5,a5,0x7
  return c;
}
    800019fe:	00010517          	auipc	a0,0x10
    80001a02:	8d250513          	addi	a0,a0,-1838 # 800112d0 <cpus>
    80001a06:	953e                	add	a0,a0,a5
    80001a08:	6422                	ld	s0,8(sp)
    80001a0a:	0141                	addi	sp,sp,16
    80001a0c:	8082                	ret

0000000080001a0e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a0e:	1101                	addi	sp,sp,-32
    80001a10:	ec06                	sd	ra,24(sp)
    80001a12:	e822                	sd	s0,16(sp)
    80001a14:	e426                	sd	s1,8(sp)
    80001a16:	1000                	addi	s0,sp,32
  push_off();
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	180080e7          	jalr	384(ra) # 80000b98 <push_off>
    80001a20:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a22:	2781                	sext.w	a5,a5
    80001a24:	079e                	slli	a5,a5,0x7
    80001a26:	00010717          	auipc	a4,0x10
    80001a2a:	87a70713          	addi	a4,a4,-1926 # 800112a0 <pid_lock>
    80001a2e:	97ba                	add	a5,a5,a4
    80001a30:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	206080e7          	jalr	518(ra) # 80000c38 <pop_off>
  return p;
}
    80001a3a:	8526                	mv	a0,s1
    80001a3c:	60e2                	ld	ra,24(sp)
    80001a3e:	6442                	ld	s0,16(sp)
    80001a40:	64a2                	ld	s1,8(sp)
    80001a42:	6105                	addi	sp,sp,32
    80001a44:	8082                	ret

0000000080001a46 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a46:	1141                	addi	sp,sp,-16
    80001a48:	e406                	sd	ra,8(sp)
    80001a4a:	e022                	sd	s0,0(sp)
    80001a4c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a4e:	00000097          	auipc	ra,0x0
    80001a52:	fc0080e7          	jalr	-64(ra) # 80001a0e <myproc>
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	242080e7          	jalr	578(ra) # 80000c98 <release>

  if (first) {
    80001a5e:	00007797          	auipc	a5,0x7
    80001a62:	f627a783          	lw	a5,-158(a5) # 800089c0 <first.1701>
    80001a66:	eb89                	bnez	a5,80001a78 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a68:	00001097          	auipc	ra,0x1
    80001a6c:	d92080e7          	jalr	-622(ra) # 800027fa <usertrapret>
}
    80001a70:	60a2                	ld	ra,8(sp)
    80001a72:	6402                	ld	s0,0(sp)
    80001a74:	0141                	addi	sp,sp,16
    80001a76:	8082                	ret
    first = 0;
    80001a78:	00007797          	auipc	a5,0x7
    80001a7c:	f407a423          	sw	zero,-184(a5) # 800089c0 <first.1701>
    fsinit(ROOTDEV);
    80001a80:	4505                	li	a0,1
    80001a82:	00002097          	auipc	ra,0x2
    80001a86:	d48080e7          	jalr	-696(ra) # 800037ca <fsinit>
    80001a8a:	bff9                	j	80001a68 <forkret+0x22>

0000000080001a8c <allocpid>:
allocpid() {
    80001a8c:	1101                	addi	sp,sp,-32
    80001a8e:	ec06                	sd	ra,24(sp)
    80001a90:	e822                	sd	s0,16(sp)
    80001a92:	e426                	sd	s1,8(sp)
    80001a94:	e04a                	sd	s2,0(sp)
    80001a96:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a98:	00010917          	auipc	s2,0x10
    80001a9c:	80890913          	addi	s2,s2,-2040 # 800112a0 <pid_lock>
    80001aa0:	854a                	mv	a0,s2
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	142080e7          	jalr	322(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001aaa:	00007797          	auipc	a5,0x7
    80001aae:	f1a78793          	addi	a5,a5,-230 # 800089c4 <nextpid>
    80001ab2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ab4:	0014871b          	addiw	a4,s1,1
    80001ab8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aba:	854a                	mv	a0,s2
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	1dc080e7          	jalr	476(ra) # 80000c98 <release>
}
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	60e2                	ld	ra,24(sp)
    80001ac8:	6442                	ld	s0,16(sp)
    80001aca:	64a2                	ld	s1,8(sp)
    80001acc:	6902                	ld	s2,0(sp)
    80001ace:	6105                	addi	sp,sp,32
    80001ad0:	8082                	ret

0000000080001ad2 <proc_pagetable>:
{
    80001ad2:	1101                	addi	sp,sp,-32
    80001ad4:	ec06                	sd	ra,24(sp)
    80001ad6:	e822                	sd	s0,16(sp)
    80001ad8:	e426                	sd	s1,8(sp)
    80001ada:	e04a                	sd	s2,0(sp)
    80001adc:	1000                	addi	s0,sp,32
    80001ade:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ae0:	00000097          	auipc	ra,0x0
    80001ae4:	85a080e7          	jalr	-1958(ra) # 8000133a <uvmcreate>
    80001ae8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aea:	c121                	beqz	a0,80001b2a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aec:	4729                	li	a4,10
    80001aee:	00005697          	auipc	a3,0x5
    80001af2:	51268693          	addi	a3,a3,1298 # 80007000 <_trampoline>
    80001af6:	6605                	lui	a2,0x1
    80001af8:	040005b7          	lui	a1,0x4000
    80001afc:	15fd                	addi	a1,a1,-1
    80001afe:	05b2                	slli	a1,a1,0xc
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	5b0080e7          	jalr	1456(ra) # 800010b0 <mappages>
    80001b08:	02054863          	bltz	a0,80001b38 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b0c:	4719                	li	a4,6
    80001b0e:	05893683          	ld	a3,88(s2)
    80001b12:	6605                	lui	a2,0x1
    80001b14:	020005b7          	lui	a1,0x2000
    80001b18:	15fd                	addi	a1,a1,-1
    80001b1a:	05b6                	slli	a1,a1,0xd
    80001b1c:	8526                	mv	a0,s1
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	592080e7          	jalr	1426(ra) # 800010b0 <mappages>
    80001b26:	02054163          	bltz	a0,80001b48 <proc_pagetable+0x76>
}
    80001b2a:	8526                	mv	a0,s1
    80001b2c:	60e2                	ld	ra,24(sp)
    80001b2e:	6442                	ld	s0,16(sp)
    80001b30:	64a2                	ld	s1,8(sp)
    80001b32:	6902                	ld	s2,0(sp)
    80001b34:	6105                	addi	sp,sp,32
    80001b36:	8082                	ret
    uvmfree(pagetable, 0);
    80001b38:	4581                	li	a1,0
    80001b3a:	8526                	mv	a0,s1
    80001b3c:	00000097          	auipc	ra,0x0
    80001b40:	9fa080e7          	jalr	-1542(ra) # 80001536 <uvmfree>
    return 0;
    80001b44:	4481                	li	s1,0
    80001b46:	b7d5                	j	80001b2a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b48:	4681                	li	a3,0
    80001b4a:	4605                	li	a2,1
    80001b4c:	040005b7          	lui	a1,0x4000
    80001b50:	15fd                	addi	a1,a1,-1
    80001b52:	05b2                	slli	a1,a1,0xc
    80001b54:	8526                	mv	a0,s1
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	720080e7          	jalr	1824(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b5e:	4581                	li	a1,0
    80001b60:	8526                	mv	a0,s1
    80001b62:	00000097          	auipc	ra,0x0
    80001b66:	9d4080e7          	jalr	-1580(ra) # 80001536 <uvmfree>
    return 0;
    80001b6a:	4481                	li	s1,0
    80001b6c:	bf7d                	j	80001b2a <proc_pagetable+0x58>

0000000080001b6e <proc_freepagetable>:
{
    80001b6e:	1101                	addi	sp,sp,-32
    80001b70:	ec06                	sd	ra,24(sp)
    80001b72:	e822                	sd	s0,16(sp)
    80001b74:	e426                	sd	s1,8(sp)
    80001b76:	e04a                	sd	s2,0(sp)
    80001b78:	1000                	addi	s0,sp,32
    80001b7a:	84aa                	mv	s1,a0
    80001b7c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b7e:	4681                	li	a3,0
    80001b80:	4605                	li	a2,1
    80001b82:	040005b7          	lui	a1,0x4000
    80001b86:	15fd                	addi	a1,a1,-1
    80001b88:	05b2                	slli	a1,a1,0xc
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	6ec080e7          	jalr	1772(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b92:	4681                	li	a3,0
    80001b94:	4605                	li	a2,1
    80001b96:	020005b7          	lui	a1,0x2000
    80001b9a:	15fd                	addi	a1,a1,-1
    80001b9c:	05b6                	slli	a1,a1,0xd
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	6d6080e7          	jalr	1750(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ba8:	85ca                	mv	a1,s2
    80001baa:	8526                	mv	a0,s1
    80001bac:	00000097          	auipc	ra,0x0
    80001bb0:	98a080e7          	jalr	-1654(ra) # 80001536 <uvmfree>
}
    80001bb4:	60e2                	ld	ra,24(sp)
    80001bb6:	6442                	ld	s0,16(sp)
    80001bb8:	64a2                	ld	s1,8(sp)
    80001bba:	6902                	ld	s2,0(sp)
    80001bbc:	6105                	addi	sp,sp,32
    80001bbe:	8082                	ret

0000000080001bc0 <freeproc>:
{
    80001bc0:	1101                	addi	sp,sp,-32
    80001bc2:	ec06                	sd	ra,24(sp)
    80001bc4:	e822                	sd	s0,16(sp)
    80001bc6:	e426                	sd	s1,8(sp)
    80001bc8:	1000                	addi	s0,sp,32
    80001bca:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bcc:	6d28                	ld	a0,88(a0)
    80001bce:	c509                	beqz	a0,80001bd8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	e28080e7          	jalr	-472(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001bd8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bdc:	68a8                	ld	a0,80(s1)
    80001bde:	c511                	beqz	a0,80001bea <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001be0:	64ac                	ld	a1,72(s1)
    80001be2:	00000097          	auipc	ra,0x0
    80001be6:	f8c080e7          	jalr	-116(ra) # 80001b6e <proc_freepagetable>
  p->pagetable = 0;
    80001bea:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bee:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bf2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bf6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bfa:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bfe:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c02:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c06:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c0a:	0004ac23          	sw	zero,24(s1)
}
    80001c0e:	60e2                	ld	ra,24(sp)
    80001c10:	6442                	ld	s0,16(sp)
    80001c12:	64a2                	ld	s1,8(sp)
    80001c14:	6105                	addi	sp,sp,32
    80001c16:	8082                	ret

0000000080001c18 <allocproc>:
{
    80001c18:	1101                	addi	sp,sp,-32
    80001c1a:	ec06                	sd	ra,24(sp)
    80001c1c:	e822                	sd	s0,16(sp)
    80001c1e:	e426                	sd	s1,8(sp)
    80001c20:	e04a                	sd	s2,0(sp)
    80001c22:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c24:	00010497          	auipc	s1,0x10
    80001c28:	aac48493          	addi	s1,s1,-1364 # 800116d0 <proc>
    80001c2c:	00016917          	auipc	s2,0x16
    80001c30:	8a490913          	addi	s2,s2,-1884 # 800174d0 <tickslock>
    acquire(&p->lock);
    80001c34:	8526                	mv	a0,s1
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	fae080e7          	jalr	-82(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c3e:	4c9c                	lw	a5,24(s1)
    80001c40:	cf81                	beqz	a5,80001c58 <allocproc+0x40>
      release(&p->lock);
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	054080e7          	jalr	84(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c4c:	17848493          	addi	s1,s1,376
    80001c50:	ff2492e3          	bne	s1,s2,80001c34 <allocproc+0x1c>
  return 0;
    80001c54:	4481                	li	s1,0
    80001c56:	a09d                	j	80001cbc <allocproc+0xa4>
  p->pid = allocpid();
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	e34080e7          	jalr	-460(ra) # 80001a8c <allocpid>
    80001c60:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c62:	4785                	li	a5,1
    80001c64:	cc9c                	sw	a5,24(s1)
  p->start_time = ticks;
    80001c66:	00007797          	auipc	a5,0x7
    80001c6a:	3ca7a783          	lw	a5,970(a5) # 80009030 <ticks>
    80001c6e:	16f4a623          	sw	a5,364(s1)
  p->run_time = 0;
    80001c72:	1604aa23          	sw	zero,372(s1)
  p->end_time = 0;
    80001c76:	1604a823          	sw	zero,368(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	e7a080e7          	jalr	-390(ra) # 80000af4 <kalloc>
    80001c82:	892a                	mv	s2,a0
    80001c84:	eca8                	sd	a0,88(s1)
    80001c86:	c131                	beqz	a0,80001cca <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c88:	8526                	mv	a0,s1
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	e48080e7          	jalr	-440(ra) # 80001ad2 <proc_pagetable>
    80001c92:	892a                	mv	s2,a0
    80001c94:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c96:	c531                	beqz	a0,80001ce2 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001c98:	07000613          	li	a2,112
    80001c9c:	4581                	li	a1,0
    80001c9e:	06048513          	addi	a0,s1,96
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	03e080e7          	jalr	62(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001caa:	00000797          	auipc	a5,0x0
    80001cae:	d9c78793          	addi	a5,a5,-612 # 80001a46 <forkret>
    80001cb2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cb4:	60bc                	ld	a5,64(s1)
    80001cb6:	6705                	lui	a4,0x1
    80001cb8:	97ba                	add	a5,a5,a4
    80001cba:	f4bc                	sd	a5,104(s1)
}
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	60e2                	ld	ra,24(sp)
    80001cc0:	6442                	ld	s0,16(sp)
    80001cc2:	64a2                	ld	s1,8(sp)
    80001cc4:	6902                	ld	s2,0(sp)
    80001cc6:	6105                	addi	sp,sp,32
    80001cc8:	8082                	ret
    freeproc(p);
    80001cca:	8526                	mv	a0,s1
    80001ccc:	00000097          	auipc	ra,0x0
    80001cd0:	ef4080e7          	jalr	-268(ra) # 80001bc0 <freeproc>
    release(&p->lock);
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	fc2080e7          	jalr	-62(ra) # 80000c98 <release>
    return 0;
    80001cde:	84ca                	mv	s1,s2
    80001ce0:	bff1                	j	80001cbc <allocproc+0xa4>
    freeproc(p);
    80001ce2:	8526                	mv	a0,s1
    80001ce4:	00000097          	auipc	ra,0x0
    80001ce8:	edc080e7          	jalr	-292(ra) # 80001bc0 <freeproc>
    release(&p->lock);
    80001cec:	8526                	mv	a0,s1
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	faa080e7          	jalr	-86(ra) # 80000c98 <release>
    return 0;
    80001cf6:	84ca                	mv	s1,s2
    80001cf8:	b7d1                	j	80001cbc <allocproc+0xa4>

0000000080001cfa <userinit>:
{
    80001cfa:	1101                	addi	sp,sp,-32
    80001cfc:	ec06                	sd	ra,24(sp)
    80001cfe:	e822                	sd	s0,16(sp)
    80001d00:	e426                	sd	s1,8(sp)
    80001d02:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d04:	00000097          	auipc	ra,0x0
    80001d08:	f14080e7          	jalr	-236(ra) # 80001c18 <allocproc>
    80001d0c:	84aa                	mv	s1,a0
  initproc = p;
    80001d0e:	00007797          	auipc	a5,0x7
    80001d12:	30a7bd23          	sd	a0,794(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d16:	03400613          	li	a2,52
    80001d1a:	00007597          	auipc	a1,0x7
    80001d1e:	cb658593          	addi	a1,a1,-842 # 800089d0 <initcode>
    80001d22:	6928                	ld	a0,80(a0)
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	644080e7          	jalr	1604(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d2c:	6785                	lui	a5,0x1
    80001d2e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d30:	6cb8                	ld	a4,88(s1)
    80001d32:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d36:	6cb8                	ld	a4,88(s1)
    80001d38:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d3a:	4641                	li	a2,16
    80001d3c:	00006597          	auipc	a1,0x6
    80001d40:	4c458593          	addi	a1,a1,1220 # 80008200 <digits+0x1c0>
    80001d44:	15848513          	addi	a0,s1,344
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	0ea080e7          	jalr	234(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d50:	00006517          	auipc	a0,0x6
    80001d54:	4c050513          	addi	a0,a0,1216 # 80008210 <digits+0x1d0>
    80001d58:	00002097          	auipc	ra,0x2
    80001d5c:	4a0080e7          	jalr	1184(ra) # 800041f8 <namei>
    80001d60:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d64:	478d                	li	a5,3
    80001d66:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d68:	8526                	mv	a0,s1
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	f2e080e7          	jalr	-210(ra) # 80000c98 <release>
}
    80001d72:	60e2                	ld	ra,24(sp)
    80001d74:	6442                	ld	s0,16(sp)
    80001d76:	64a2                	ld	s1,8(sp)
    80001d78:	6105                	addi	sp,sp,32
    80001d7a:	8082                	ret

0000000080001d7c <growproc>:
{
    80001d7c:	1101                	addi	sp,sp,-32
    80001d7e:	ec06                	sd	ra,24(sp)
    80001d80:	e822                	sd	s0,16(sp)
    80001d82:	e426                	sd	s1,8(sp)
    80001d84:	e04a                	sd	s2,0(sp)
    80001d86:	1000                	addi	s0,sp,32
    80001d88:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	c84080e7          	jalr	-892(ra) # 80001a0e <myproc>
    80001d92:	892a                	mv	s2,a0
  sz = p->sz;
    80001d94:	652c                	ld	a1,72(a0)
    80001d96:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d9a:	00904f63          	bgtz	s1,80001db8 <growproc+0x3c>
  } else if(n < 0){
    80001d9e:	0204cc63          	bltz	s1,80001dd6 <growproc+0x5a>
  p->sz = sz;
    80001da2:	1602                	slli	a2,a2,0x20
    80001da4:	9201                	srli	a2,a2,0x20
    80001da6:	04c93423          	sd	a2,72(s2)
  return 0;
    80001daa:	4501                	li	a0,0
}
    80001dac:	60e2                	ld	ra,24(sp)
    80001dae:	6442                	ld	s0,16(sp)
    80001db0:	64a2                	ld	s1,8(sp)
    80001db2:	6902                	ld	s2,0(sp)
    80001db4:	6105                	addi	sp,sp,32
    80001db6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001db8:	9e25                	addw	a2,a2,s1
    80001dba:	1602                	slli	a2,a2,0x20
    80001dbc:	9201                	srli	a2,a2,0x20
    80001dbe:	1582                	slli	a1,a1,0x20
    80001dc0:	9181                	srli	a1,a1,0x20
    80001dc2:	6928                	ld	a0,80(a0)
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	65e080e7          	jalr	1630(ra) # 80001422 <uvmalloc>
    80001dcc:	0005061b          	sext.w	a2,a0
    80001dd0:	fa69                	bnez	a2,80001da2 <growproc+0x26>
      return -1;
    80001dd2:	557d                	li	a0,-1
    80001dd4:	bfe1                	j	80001dac <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dd6:	9e25                	addw	a2,a2,s1
    80001dd8:	1602                	slli	a2,a2,0x20
    80001dda:	9201                	srli	a2,a2,0x20
    80001ddc:	1582                	slli	a1,a1,0x20
    80001dde:	9181                	srli	a1,a1,0x20
    80001de0:	6928                	ld	a0,80(a0)
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	5f8080e7          	jalr	1528(ra) # 800013da <uvmdealloc>
    80001dea:	0005061b          	sext.w	a2,a0
    80001dee:	bf55                	j	80001da2 <growproc+0x26>

0000000080001df0 <fork>:
{
    80001df0:	7179                	addi	sp,sp,-48
    80001df2:	f406                	sd	ra,40(sp)
    80001df4:	f022                	sd	s0,32(sp)
    80001df6:	ec26                	sd	s1,24(sp)
    80001df8:	e84a                	sd	s2,16(sp)
    80001dfa:	e44e                	sd	s3,8(sp)
    80001dfc:	e052                	sd	s4,0(sp)
    80001dfe:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e00:	00000097          	auipc	ra,0x0
    80001e04:	c0e080e7          	jalr	-1010(ra) # 80001a0e <myproc>
    80001e08:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	e0e080e7          	jalr	-498(ra) # 80001c18 <allocproc>
    80001e12:	10050f63          	beqz	a0,80001f30 <fork+0x140>
    80001e16:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e18:	04893603          	ld	a2,72(s2)
    80001e1c:	692c                	ld	a1,80(a0)
    80001e1e:	05093503          	ld	a0,80(s2)
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	74c080e7          	jalr	1868(ra) # 8000156e <uvmcopy>
    80001e2a:	04054a63          	bltz	a0,80001e7e <fork+0x8e>
  np->sz = p->sz;
    80001e2e:	04893783          	ld	a5,72(s2)
    80001e32:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e36:	05893683          	ld	a3,88(s2)
    80001e3a:	87b6                	mv	a5,a3
    80001e3c:	0589b703          	ld	a4,88(s3)
    80001e40:	12068693          	addi	a3,a3,288
    80001e44:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e48:	6788                	ld	a0,8(a5)
    80001e4a:	6b8c                	ld	a1,16(a5)
    80001e4c:	6f90                	ld	a2,24(a5)
    80001e4e:	01073023          	sd	a6,0(a4)
    80001e52:	e708                	sd	a0,8(a4)
    80001e54:	eb0c                	sd	a1,16(a4)
    80001e56:	ef10                	sd	a2,24(a4)
    80001e58:	02078793          	addi	a5,a5,32
    80001e5c:	02070713          	addi	a4,a4,32
    80001e60:	fed792e3          	bne	a5,a3,80001e44 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e64:	0589b783          	ld	a5,88(s3)
    80001e68:	0607b823          	sd	zero,112(a5)
  np->tracy = p->tracy;
    80001e6c:	16892783          	lw	a5,360(s2)
    80001e70:	16f9a423          	sw	a5,360(s3)
    80001e74:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e78:	15000a13          	li	s4,336
    80001e7c:	a03d                	j	80001eaa <fork+0xba>
    freeproc(np);
    80001e7e:	854e                	mv	a0,s3
    80001e80:	00000097          	auipc	ra,0x0
    80001e84:	d40080e7          	jalr	-704(ra) # 80001bc0 <freeproc>
    release(&np->lock);
    80001e88:	854e                	mv	a0,s3
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e0e080e7          	jalr	-498(ra) # 80000c98 <release>
    return -1;
    80001e92:	5a7d                	li	s4,-1
    80001e94:	a069                	j	80001f1e <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e96:	00003097          	auipc	ra,0x3
    80001e9a:	9f8080e7          	jalr	-1544(ra) # 8000488e <filedup>
    80001e9e:	009987b3          	add	a5,s3,s1
    80001ea2:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ea4:	04a1                	addi	s1,s1,8
    80001ea6:	01448763          	beq	s1,s4,80001eb4 <fork+0xc4>
    if(p->ofile[i])
    80001eaa:	009907b3          	add	a5,s2,s1
    80001eae:	6388                	ld	a0,0(a5)
    80001eb0:	f17d                	bnez	a0,80001e96 <fork+0xa6>
    80001eb2:	bfcd                	j	80001ea4 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001eb4:	15093503          	ld	a0,336(s2)
    80001eb8:	00002097          	auipc	ra,0x2
    80001ebc:	b4c080e7          	jalr	-1204(ra) # 80003a04 <idup>
    80001ec0:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ec4:	4641                	li	a2,16
    80001ec6:	15890593          	addi	a1,s2,344
    80001eca:	15898513          	addi	a0,s3,344
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	f64080e7          	jalr	-156(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001ed6:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001eda:	854e                	mv	a0,s3
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	dbc080e7          	jalr	-580(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ee4:	0000f497          	auipc	s1,0xf
    80001ee8:	3d448493          	addi	s1,s1,980 # 800112b8 <wait_lock>
    80001eec:	8526                	mv	a0,s1
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	cf6080e7          	jalr	-778(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ef6:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001efa:	8526                	mv	a0,s1
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	d9c080e7          	jalr	-612(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f04:	854e                	mv	a0,s3
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	cde080e7          	jalr	-802(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001f0e:	478d                	li	a5,3
    80001f10:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f14:	854e                	mv	a0,s3
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	d82080e7          	jalr	-638(ra) # 80000c98 <release>
}
    80001f1e:	8552                	mv	a0,s4
    80001f20:	70a2                	ld	ra,40(sp)
    80001f22:	7402                	ld	s0,32(sp)
    80001f24:	64e2                	ld	s1,24(sp)
    80001f26:	6942                	ld	s2,16(sp)
    80001f28:	69a2                	ld	s3,8(sp)
    80001f2a:	6a02                	ld	s4,0(sp)
    80001f2c:	6145                	addi	sp,sp,48
    80001f2e:	8082                	ret
    return -1;
    80001f30:	5a7d                	li	s4,-1
    80001f32:	b7f5                	j	80001f1e <fork+0x12e>

0000000080001f34 <scheduler>:
{
    80001f34:	715d                	addi	sp,sp,-80
    80001f36:	e486                	sd	ra,72(sp)
    80001f38:	e0a2                	sd	s0,64(sp)
    80001f3a:	fc26                	sd	s1,56(sp)
    80001f3c:	f84a                	sd	s2,48(sp)
    80001f3e:	f44e                	sd	s3,40(sp)
    80001f40:	f052                	sd	s4,32(sp)
    80001f42:	ec56                	sd	s5,24(sp)
    80001f44:	e85a                	sd	s6,16(sp)
    80001f46:	e45e                	sd	s7,8(sp)
    80001f48:	0880                	addi	s0,sp,80
    80001f4a:	8792                	mv	a5,tp
  int id = r_tp();
    80001f4c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f4e:	00779a93          	slli	s5,a5,0x7
    80001f52:	0000f717          	auipc	a4,0xf
    80001f56:	34e70713          	addi	a4,a4,846 # 800112a0 <pid_lock>
    80001f5a:	9756                	add	a4,a4,s5
    80001f5c:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f60:	0000f717          	auipc	a4,0xf
    80001f64:	37870713          	addi	a4,a4,888 # 800112d8 <cpus+0x8>
    80001f68:	9aba                	add	s5,s5,a4
      printf("RR\n");
    80001f6a:	00006b97          	auipc	s7,0x6
    80001f6e:	2aeb8b93          	addi	s7,s7,686 # 80008218 <digits+0x1d8>
          p->state = RUNNING;
    80001f72:	4b11                	li	s6,4
          c->proc = p;
    80001f74:	079e                	slli	a5,a5,0x7
    80001f76:	0000fa17          	auipc	s4,0xf
    80001f7a:	32aa0a13          	addi	s4,s4,810 # 800112a0 <pid_lock>
    80001f7e:	9a3e                	add	s4,s4,a5
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f80:	00015997          	auipc	s3,0x15
    80001f84:	55098993          	addi	s3,s3,1360 # 800174d0 <tickslock>
      printf("RR\n");
    80001f88:	855e                	mv	a0,s7
    80001f8a:	ffffe097          	auipc	ra,0xffffe
    80001f8e:	5fe080e7          	jalr	1534(ra) # 80000588 <printf>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f96:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9a:	10079073          	csrw	sstatus,a5
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f9e:	0000f497          	auipc	s1,0xf
    80001fa2:	73248493          	addi	s1,s1,1842 # 800116d0 <proc>
        if(p->state == RUNNABLE) {
    80001fa6:	490d                	li	s2,3
    80001fa8:	a03d                	j	80001fd6 <scheduler+0xa2>
          p->state = RUNNING;
    80001faa:	0164ac23          	sw	s6,24(s1)
          c->proc = p;
    80001fae:	029a3823          	sd	s1,48(s4)
          swtch(&c->context, &p->context);
    80001fb2:	06048593          	addi	a1,s1,96
    80001fb6:	8556                	mv	a0,s5
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	798080e7          	jalr	1944(ra) # 80002750 <swtch>
          c->proc = 0;
    80001fc0:	020a3823          	sd	zero,48(s4)
        release(&p->lock);
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	cd2080e7          	jalr	-814(ra) # 80000c98 <release>
      for(p = proc; p < &proc[NPROC]; p++) {
    80001fce:	17848493          	addi	s1,s1,376
    80001fd2:	fb348be3          	beq	s1,s3,80001f88 <scheduler+0x54>
        acquire(&p->lock);
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	c0c080e7          	jalr	-1012(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001fe0:	4c9c                	lw	a5,24(s1)
    80001fe2:	ff2791e3          	bne	a5,s2,80001fc4 <scheduler+0x90>
    80001fe6:	b7d1                	j	80001faa <scheduler+0x76>

0000000080001fe8 <sched>:
{
    80001fe8:	7179                	addi	sp,sp,-48
    80001fea:	f406                	sd	ra,40(sp)
    80001fec:	f022                	sd	s0,32(sp)
    80001fee:	ec26                	sd	s1,24(sp)
    80001ff0:	e84a                	sd	s2,16(sp)
    80001ff2:	e44e                	sd	s3,8(sp)
    80001ff4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	a18080e7          	jalr	-1512(ra) # 80001a0e <myproc>
    80001ffe:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	b6a080e7          	jalr	-1174(ra) # 80000b6a <holding>
    80002008:	c93d                	beqz	a0,8000207e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000200a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	0000f717          	auipc	a4,0xf
    80002014:	29070713          	addi	a4,a4,656 # 800112a0 <pid_lock>
    80002018:	97ba                	add	a5,a5,a4
    8000201a:	0a87a703          	lw	a4,168(a5)
    8000201e:	4785                	li	a5,1
    80002020:	06f71763          	bne	a4,a5,8000208e <sched+0xa6>
  if(p->state == RUNNING)
    80002024:	4c98                	lw	a4,24(s1)
    80002026:	4791                	li	a5,4
    80002028:	06f70b63          	beq	a4,a5,8000209e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002030:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002032:	efb5                	bnez	a5,800020ae <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002034:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002036:	0000f917          	auipc	s2,0xf
    8000203a:	26a90913          	addi	s2,s2,618 # 800112a0 <pid_lock>
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	97ca                	add	a5,a5,s2
    80002044:	0ac7a983          	lw	s3,172(a5)
    80002048:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000204a:	2781                	sext.w	a5,a5
    8000204c:	079e                	slli	a5,a5,0x7
    8000204e:	0000f597          	auipc	a1,0xf
    80002052:	28a58593          	addi	a1,a1,650 # 800112d8 <cpus+0x8>
    80002056:	95be                	add	a1,a1,a5
    80002058:	06048513          	addi	a0,s1,96
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	6f4080e7          	jalr	1780(ra) # 80002750 <swtch>
    80002064:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	97ca                	add	a5,a5,s2
    8000206c:	0b37a623          	sw	s3,172(a5)
}
    80002070:	70a2                	ld	ra,40(sp)
    80002072:	7402                	ld	s0,32(sp)
    80002074:	64e2                	ld	s1,24(sp)
    80002076:	6942                	ld	s2,16(sp)
    80002078:	69a2                	ld	s3,8(sp)
    8000207a:	6145                	addi	sp,sp,48
    8000207c:	8082                	ret
    panic("sched p->lock");
    8000207e:	00006517          	auipc	a0,0x6
    80002082:	1a250513          	addi	a0,a0,418 # 80008220 <digits+0x1e0>
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	4b8080e7          	jalr	1208(ra) # 8000053e <panic>
    panic("sched locks");
    8000208e:	00006517          	auipc	a0,0x6
    80002092:	1a250513          	addi	a0,a0,418 # 80008230 <digits+0x1f0>
    80002096:	ffffe097          	auipc	ra,0xffffe
    8000209a:	4a8080e7          	jalr	1192(ra) # 8000053e <panic>
    panic("sched running");
    8000209e:	00006517          	auipc	a0,0x6
    800020a2:	1a250513          	addi	a0,a0,418 # 80008240 <digits+0x200>
    800020a6:	ffffe097          	auipc	ra,0xffffe
    800020aa:	498080e7          	jalr	1176(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020ae:	00006517          	auipc	a0,0x6
    800020b2:	1a250513          	addi	a0,a0,418 # 80008250 <digits+0x210>
    800020b6:	ffffe097          	auipc	ra,0xffffe
    800020ba:	488080e7          	jalr	1160(ra) # 8000053e <panic>

00000000800020be <yield>:
{
    800020be:	1101                	addi	sp,sp,-32
    800020c0:	ec06                	sd	ra,24(sp)
    800020c2:	e822                	sd	s0,16(sp)
    800020c4:	e426                	sd	s1,8(sp)
    800020c6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	946080e7          	jalr	-1722(ra) # 80001a0e <myproc>
    800020d0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b12080e7          	jalr	-1262(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020da:	478d                	li	a5,3
    800020dc:	cc9c                	sw	a5,24(s1)
  sched();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	f0a080e7          	jalr	-246(ra) # 80001fe8 <sched>
  release(&p->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	bb0080e7          	jalr	-1104(ra) # 80000c98 <release>
}
    800020f0:	60e2                	ld	ra,24(sp)
    800020f2:	6442                	ld	s0,16(sp)
    800020f4:	64a2                	ld	s1,8(sp)
    800020f6:	6105                	addi	sp,sp,32
    800020f8:	8082                	ret

00000000800020fa <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020fa:	7179                	addi	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	1800                	addi	s0,sp,48
    80002108:	89aa                	mv	s3,a0
    8000210a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	902080e7          	jalr	-1790(ra) # 80001a0e <myproc>
    80002114:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	ace080e7          	jalr	-1330(ra) # 80000be4 <acquire>
  release(lk);
    8000211e:	854a                	mv	a0,s2
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	b78080e7          	jalr	-1160(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002128:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000212c:	4789                	li	a5,2
    8000212e:	cc9c                	sw	a5,24(s1)

  sched();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	eb8080e7          	jalr	-328(ra) # 80001fe8 <sched>

  // Tidy up.
  p->chan = 0;
    80002138:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	b5a080e7          	jalr	-1190(ra) # 80000c98 <release>
  acquire(lk);
    80002146:	854a                	mv	a0,s2
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	a9c080e7          	jalr	-1380(ra) # 80000be4 <acquire>
}
    80002150:	70a2                	ld	ra,40(sp)
    80002152:	7402                	ld	s0,32(sp)
    80002154:	64e2                	ld	s1,24(sp)
    80002156:	6942                	ld	s2,16(sp)
    80002158:	69a2                	ld	s3,8(sp)
    8000215a:	6145                	addi	sp,sp,48
    8000215c:	8082                	ret

000000008000215e <wait>:
{
    8000215e:	715d                	addi	sp,sp,-80
    80002160:	e486                	sd	ra,72(sp)
    80002162:	e0a2                	sd	s0,64(sp)
    80002164:	fc26                	sd	s1,56(sp)
    80002166:	f84a                	sd	s2,48(sp)
    80002168:	f44e                	sd	s3,40(sp)
    8000216a:	f052                	sd	s4,32(sp)
    8000216c:	ec56                	sd	s5,24(sp)
    8000216e:	e85a                	sd	s6,16(sp)
    80002170:	e45e                	sd	s7,8(sp)
    80002172:	e062                	sd	s8,0(sp)
    80002174:	0880                	addi	s0,sp,80
    80002176:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002178:	00000097          	auipc	ra,0x0
    8000217c:	896080e7          	jalr	-1898(ra) # 80001a0e <myproc>
    80002180:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002182:	0000f517          	auipc	a0,0xf
    80002186:	13650513          	addi	a0,a0,310 # 800112b8 <wait_lock>
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	a5a080e7          	jalr	-1446(ra) # 80000be4 <acquire>
    havekids = 0;
    80002192:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002194:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002196:	00015997          	auipc	s3,0x15
    8000219a:	33a98993          	addi	s3,s3,826 # 800174d0 <tickslock>
        havekids = 1;
    8000219e:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021a0:	0000fc17          	auipc	s8,0xf
    800021a4:	118c0c13          	addi	s8,s8,280 # 800112b8 <wait_lock>
    havekids = 0;
    800021a8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800021aa:	0000f497          	auipc	s1,0xf
    800021ae:	52648493          	addi	s1,s1,1318 # 800116d0 <proc>
    800021b2:	a0bd                	j	80002220 <wait+0xc2>
          pid = np->pid;
    800021b4:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021b8:	000b0e63          	beqz	s6,800021d4 <wait+0x76>
    800021bc:	4691                	li	a3,4
    800021be:	02c48613          	addi	a2,s1,44
    800021c2:	85da                	mv	a1,s6
    800021c4:	05093503          	ld	a0,80(s2)
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	4aa080e7          	jalr	1194(ra) # 80001672 <copyout>
    800021d0:	02054563          	bltz	a0,800021fa <wait+0x9c>
          freeproc(np);
    800021d4:	8526                	mv	a0,s1
    800021d6:	00000097          	auipc	ra,0x0
    800021da:	9ea080e7          	jalr	-1558(ra) # 80001bc0 <freeproc>
          release(&np->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	ab8080e7          	jalr	-1352(ra) # 80000c98 <release>
          release(&wait_lock);
    800021e8:	0000f517          	auipc	a0,0xf
    800021ec:	0d050513          	addi	a0,a0,208 # 800112b8 <wait_lock>
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	aa8080e7          	jalr	-1368(ra) # 80000c98 <release>
          return pid;
    800021f8:	a09d                	j	8000225e <wait+0x100>
            release(&np->lock);
    800021fa:	8526                	mv	a0,s1
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	a9c080e7          	jalr	-1380(ra) # 80000c98 <release>
            release(&wait_lock);
    80002204:	0000f517          	auipc	a0,0xf
    80002208:	0b450513          	addi	a0,a0,180 # 800112b8 <wait_lock>
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	a8c080e7          	jalr	-1396(ra) # 80000c98 <release>
            return -1;
    80002214:	59fd                	li	s3,-1
    80002216:	a0a1                	j	8000225e <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002218:	17848493          	addi	s1,s1,376
    8000221c:	03348463          	beq	s1,s3,80002244 <wait+0xe6>
      if(np->parent == p){
    80002220:	7c9c                	ld	a5,56(s1)
    80002222:	ff279be3          	bne	a5,s2,80002218 <wait+0xba>
        acquire(&np->lock);
    80002226:	8526                	mv	a0,s1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	9bc080e7          	jalr	-1604(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002230:	4c9c                	lw	a5,24(s1)
    80002232:	f94781e3          	beq	a5,s4,800021b4 <wait+0x56>
        release(&np->lock);
    80002236:	8526                	mv	a0,s1
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	a60080e7          	jalr	-1440(ra) # 80000c98 <release>
        havekids = 1;
    80002240:	8756                	mv	a4,s5
    80002242:	bfd9                	j	80002218 <wait+0xba>
    if(!havekids || p->killed){
    80002244:	c701                	beqz	a4,8000224c <wait+0xee>
    80002246:	02892783          	lw	a5,40(s2)
    8000224a:	c79d                	beqz	a5,80002278 <wait+0x11a>
      release(&wait_lock);
    8000224c:	0000f517          	auipc	a0,0xf
    80002250:	06c50513          	addi	a0,a0,108 # 800112b8 <wait_lock>
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	a44080e7          	jalr	-1468(ra) # 80000c98 <release>
      return -1;
    8000225c:	59fd                	li	s3,-1
}
    8000225e:	854e                	mv	a0,s3
    80002260:	60a6                	ld	ra,72(sp)
    80002262:	6406                	ld	s0,64(sp)
    80002264:	74e2                	ld	s1,56(sp)
    80002266:	7942                	ld	s2,48(sp)
    80002268:	79a2                	ld	s3,40(sp)
    8000226a:	7a02                	ld	s4,32(sp)
    8000226c:	6ae2                	ld	s5,24(sp)
    8000226e:	6b42                	ld	s6,16(sp)
    80002270:	6ba2                	ld	s7,8(sp)
    80002272:	6c02                	ld	s8,0(sp)
    80002274:	6161                	addi	sp,sp,80
    80002276:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002278:	85e2                	mv	a1,s8
    8000227a:	854a                	mv	a0,s2
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	e7e080e7          	jalr	-386(ra) # 800020fa <sleep>
    havekids = 0;
    80002284:	b715                	j	800021a8 <wait+0x4a>

0000000080002286 <waitx>:
{
    80002286:	711d                	addi	sp,sp,-96
    80002288:	ec86                	sd	ra,88(sp)
    8000228a:	e8a2                	sd	s0,80(sp)
    8000228c:	e4a6                	sd	s1,72(sp)
    8000228e:	e0ca                	sd	s2,64(sp)
    80002290:	fc4e                	sd	s3,56(sp)
    80002292:	f852                	sd	s4,48(sp)
    80002294:	f456                	sd	s5,40(sp)
    80002296:	f05a                	sd	s6,32(sp)
    80002298:	ec5e                	sd	s7,24(sp)
    8000229a:	e862                	sd	s8,16(sp)
    8000229c:	e466                	sd	s9,8(sp)
    8000229e:	e06a                	sd	s10,0(sp)
    800022a0:	1080                	addi	s0,sp,96
    800022a2:	8b2a                	mv	s6,a0
    800022a4:	8c2e                	mv	s8,a1
    800022a6:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	766080e7          	jalr	1894(ra) # 80001a0e <myproc>
    800022b0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022b2:	0000f517          	auipc	a0,0xf
    800022b6:	00650513          	addi	a0,a0,6 # 800112b8 <wait_lock>
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	92a080e7          	jalr	-1750(ra) # 80000be4 <acquire>
    havekids = 0;
    800022c2:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    800022c4:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022c6:	00015997          	auipc	s3,0x15
    800022ca:	20a98993          	addi	s3,s3,522 # 800174d0 <tickslock>
        havekids = 1;
    800022ce:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022d0:	0000fd17          	auipc	s10,0xf
    800022d4:	fe8d0d13          	addi	s10,s10,-24 # 800112b8 <wait_lock>
    havekids = 0;
    800022d8:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    800022da:	0000f497          	auipc	s1,0xf
    800022de:	3f648493          	addi	s1,s1,1014 # 800116d0 <proc>
    800022e2:	a059                	j	80002368 <waitx+0xe2>
          pid = np->pid;
    800022e4:	0304a983          	lw	s3,48(s1)
          *rtime = np->run_time;
    800022e8:	1744a703          	lw	a4,372(s1)
    800022ec:	00ec2023          	sw	a4,0(s8)
          *wtime = np->end_time-np->start_time-np->run_time;
    800022f0:	16c4a783          	lw	a5,364(s1)
    800022f4:	9f3d                	addw	a4,a4,a5
    800022f6:	1704a783          	lw	a5,368(s1)
    800022fa:	9f99                	subw	a5,a5,a4
    800022fc:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002300:	000b0e63          	beqz	s6,8000231c <waitx+0x96>
    80002304:	4691                	li	a3,4
    80002306:	02c48613          	addi	a2,s1,44
    8000230a:	85da                	mv	a1,s6
    8000230c:	05093503          	ld	a0,80(s2)
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	362080e7          	jalr	866(ra) # 80001672 <copyout>
    80002318:	02054563          	bltz	a0,80002342 <waitx+0xbc>
          freeproc(np);
    8000231c:	8526                	mv	a0,s1
    8000231e:	00000097          	auipc	ra,0x0
    80002322:	8a2080e7          	jalr	-1886(ra) # 80001bc0 <freeproc>
          release(&np->lock);
    80002326:	8526                	mv	a0,s1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	970080e7          	jalr	-1680(ra) # 80000c98 <release>
          release(&wait_lock);
    80002330:	0000f517          	auipc	a0,0xf
    80002334:	f8850513          	addi	a0,a0,-120 # 800112b8 <wait_lock>
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	960080e7          	jalr	-1696(ra) # 80000c98 <release>
          return pid;
    80002340:	a09d                	j	800023a6 <waitx+0x120>
            release(&np->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	954080e7          	jalr	-1708(ra) # 80000c98 <release>
            release(&wait_lock);
    8000234c:	0000f517          	auipc	a0,0xf
    80002350:	f6c50513          	addi	a0,a0,-148 # 800112b8 <wait_lock>
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	944080e7          	jalr	-1724(ra) # 80000c98 <release>
            return -1;
    8000235c:	59fd                	li	s3,-1
    8000235e:	a0a1                	j	800023a6 <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    80002360:	17848493          	addi	s1,s1,376
    80002364:	03348463          	beq	s1,s3,8000238c <waitx+0x106>
      if(np->parent == p){
    80002368:	7c9c                	ld	a5,56(s1)
    8000236a:	ff279be3          	bne	a5,s2,80002360 <waitx+0xda>
        acquire(&np->lock);
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	874080e7          	jalr	-1932(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002378:	4c9c                	lw	a5,24(s1)
    8000237a:	f74785e3          	beq	a5,s4,800022e4 <waitx+0x5e>
        release(&np->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	918080e7          	jalr	-1768(ra) # 80000c98 <release>
        havekids = 1;
    80002388:	8756                	mv	a4,s5
    8000238a:	bfd9                	j	80002360 <waitx+0xda>
    if(!havekids || p->killed){
    8000238c:	c701                	beqz	a4,80002394 <waitx+0x10e>
    8000238e:	02892783          	lw	a5,40(s2)
    80002392:	cb8d                	beqz	a5,800023c4 <waitx+0x13e>
      release(&wait_lock);
    80002394:	0000f517          	auipc	a0,0xf
    80002398:	f2450513          	addi	a0,a0,-220 # 800112b8 <wait_lock>
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	8fc080e7          	jalr	-1796(ra) # 80000c98 <release>
      return -1;
    800023a4:	59fd                	li	s3,-1
}
    800023a6:	854e                	mv	a0,s3
    800023a8:	60e6                	ld	ra,88(sp)
    800023aa:	6446                	ld	s0,80(sp)
    800023ac:	64a6                	ld	s1,72(sp)
    800023ae:	6906                	ld	s2,64(sp)
    800023b0:	79e2                	ld	s3,56(sp)
    800023b2:	7a42                	ld	s4,48(sp)
    800023b4:	7aa2                	ld	s5,40(sp)
    800023b6:	7b02                	ld	s6,32(sp)
    800023b8:	6be2                	ld	s7,24(sp)
    800023ba:	6c42                	ld	s8,16(sp)
    800023bc:	6ca2                	ld	s9,8(sp)
    800023be:	6d02                	ld	s10,0(sp)
    800023c0:	6125                	addi	sp,sp,96
    800023c2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023c4:	85ea                	mv	a1,s10
    800023c6:	854a                	mv	a0,s2
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	d32080e7          	jalr	-718(ra) # 800020fa <sleep>
    havekids = 0;
    800023d0:	b721                	j	800022d8 <waitx+0x52>

00000000800023d2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023d2:	7139                	addi	sp,sp,-64
    800023d4:	fc06                	sd	ra,56(sp)
    800023d6:	f822                	sd	s0,48(sp)
    800023d8:	f426                	sd	s1,40(sp)
    800023da:	f04a                	sd	s2,32(sp)
    800023dc:	ec4e                	sd	s3,24(sp)
    800023de:	e852                	sd	s4,16(sp)
    800023e0:	e456                	sd	s5,8(sp)
    800023e2:	0080                	addi	s0,sp,64
    800023e4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023e6:	0000f497          	auipc	s1,0xf
    800023ea:	2ea48493          	addi	s1,s1,746 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023ee:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023f0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f2:	00015917          	auipc	s2,0x15
    800023f6:	0de90913          	addi	s2,s2,222 # 800174d0 <tickslock>
    800023fa:	a821                	j	80002412 <wakeup+0x40>
        p->state = RUNNABLE;
    800023fc:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	896080e7          	jalr	-1898(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000240a:	17848493          	addi	s1,s1,376
    8000240e:	03248463          	beq	s1,s2,80002436 <wakeup+0x64>
    if(p != myproc()){
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	5fc080e7          	jalr	1532(ra) # 80001a0e <myproc>
    8000241a:	fea488e3          	beq	s1,a0,8000240a <wakeup+0x38>
      acquire(&p->lock);
    8000241e:	8526                	mv	a0,s1
    80002420:	ffffe097          	auipc	ra,0xffffe
    80002424:	7c4080e7          	jalr	1988(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002428:	4c9c                	lw	a5,24(s1)
    8000242a:	fd379be3          	bne	a5,s3,80002400 <wakeup+0x2e>
    8000242e:	709c                	ld	a5,32(s1)
    80002430:	fd4798e3          	bne	a5,s4,80002400 <wakeup+0x2e>
    80002434:	b7e1                	j	800023fc <wakeup+0x2a>
    }
  }
}
    80002436:	70e2                	ld	ra,56(sp)
    80002438:	7442                	ld	s0,48(sp)
    8000243a:	74a2                	ld	s1,40(sp)
    8000243c:	7902                	ld	s2,32(sp)
    8000243e:	69e2                	ld	s3,24(sp)
    80002440:	6a42                	ld	s4,16(sp)
    80002442:	6aa2                	ld	s5,8(sp)
    80002444:	6121                	addi	sp,sp,64
    80002446:	8082                	ret

0000000080002448 <reparent>:
{
    80002448:	7179                	addi	sp,sp,-48
    8000244a:	f406                	sd	ra,40(sp)
    8000244c:	f022                	sd	s0,32(sp)
    8000244e:	ec26                	sd	s1,24(sp)
    80002450:	e84a                	sd	s2,16(sp)
    80002452:	e44e                	sd	s3,8(sp)
    80002454:	e052                	sd	s4,0(sp)
    80002456:	1800                	addi	s0,sp,48
    80002458:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000245a:	0000f497          	auipc	s1,0xf
    8000245e:	27648493          	addi	s1,s1,630 # 800116d0 <proc>
      pp->parent = initproc;
    80002462:	00007a17          	auipc	s4,0x7
    80002466:	bc6a0a13          	addi	s4,s4,-1082 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000246a:	00015997          	auipc	s3,0x15
    8000246e:	06698993          	addi	s3,s3,102 # 800174d0 <tickslock>
    80002472:	a029                	j	8000247c <reparent+0x34>
    80002474:	17848493          	addi	s1,s1,376
    80002478:	01348d63          	beq	s1,s3,80002492 <reparent+0x4a>
    if(pp->parent == p){
    8000247c:	7c9c                	ld	a5,56(s1)
    8000247e:	ff279be3          	bne	a5,s2,80002474 <reparent+0x2c>
      pp->parent = initproc;
    80002482:	000a3503          	ld	a0,0(s4)
    80002486:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	f4a080e7          	jalr	-182(ra) # 800023d2 <wakeup>
    80002490:	b7d5                	j	80002474 <reparent+0x2c>
}
    80002492:	70a2                	ld	ra,40(sp)
    80002494:	7402                	ld	s0,32(sp)
    80002496:	64e2                	ld	s1,24(sp)
    80002498:	6942                	ld	s2,16(sp)
    8000249a:	69a2                	ld	s3,8(sp)
    8000249c:	6a02                	ld	s4,0(sp)
    8000249e:	6145                	addi	sp,sp,48
    800024a0:	8082                	ret

00000000800024a2 <exit>:
{
    800024a2:	7179                	addi	sp,sp,-48
    800024a4:	f406                	sd	ra,40(sp)
    800024a6:	f022                	sd	s0,32(sp)
    800024a8:	ec26                	sd	s1,24(sp)
    800024aa:	e84a                	sd	s2,16(sp)
    800024ac:	e44e                	sd	s3,8(sp)
    800024ae:	e052                	sd	s4,0(sp)
    800024b0:	1800                	addi	s0,sp,48
    800024b2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	55a080e7          	jalr	1370(ra) # 80001a0e <myproc>
    800024bc:	89aa                	mv	s3,a0
  if(p == initproc)
    800024be:	00007797          	auipc	a5,0x7
    800024c2:	b6a7b783          	ld	a5,-1174(a5) # 80009028 <initproc>
    800024c6:	0d050493          	addi	s1,a0,208
    800024ca:	15050913          	addi	s2,a0,336
    800024ce:	02a79363          	bne	a5,a0,800024f4 <exit+0x52>
    panic("init exiting");
    800024d2:	00006517          	auipc	a0,0x6
    800024d6:	d9650513          	addi	a0,a0,-618 # 80008268 <digits+0x228>
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	064080e7          	jalr	100(ra) # 8000053e <panic>
      fileclose(f);
    800024e2:	00002097          	auipc	ra,0x2
    800024e6:	3fe080e7          	jalr	1022(ra) # 800048e0 <fileclose>
      p->ofile[fd] = 0;
    800024ea:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024ee:	04a1                	addi	s1,s1,8
    800024f0:	01248563          	beq	s1,s2,800024fa <exit+0x58>
    if(p->ofile[fd]){
    800024f4:	6088                	ld	a0,0(s1)
    800024f6:	f575                	bnez	a0,800024e2 <exit+0x40>
    800024f8:	bfdd                	j	800024ee <exit+0x4c>
  begin_op();
    800024fa:	00002097          	auipc	ra,0x2
    800024fe:	f1a080e7          	jalr	-230(ra) # 80004414 <begin_op>
  iput(p->cwd);
    80002502:	1509b503          	ld	a0,336(s3)
    80002506:	00001097          	auipc	ra,0x1
    8000250a:	6f6080e7          	jalr	1782(ra) # 80003bfc <iput>
  end_op();
    8000250e:	00002097          	auipc	ra,0x2
    80002512:	f86080e7          	jalr	-122(ra) # 80004494 <end_op>
  p->cwd = 0;
    80002516:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000251a:	0000f497          	auipc	s1,0xf
    8000251e:	d9e48493          	addi	s1,s1,-610 # 800112b8 <wait_lock>
    80002522:	8526                	mv	a0,s1
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	6c0080e7          	jalr	1728(ra) # 80000be4 <acquire>
  reparent(p);
    8000252c:	854e                	mv	a0,s3
    8000252e:	00000097          	auipc	ra,0x0
    80002532:	f1a080e7          	jalr	-230(ra) # 80002448 <reparent>
  wakeup(p->parent);
    80002536:	0389b503          	ld	a0,56(s3)
    8000253a:	00000097          	auipc	ra,0x0
    8000253e:	e98080e7          	jalr	-360(ra) # 800023d2 <wakeup>
  acquire(&p->lock);
    80002542:	854e                	mv	a0,s3
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	6a0080e7          	jalr	1696(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000254c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002550:	4795                	li	a5,5
    80002552:	00f9ac23          	sw	a5,24(s3)
  p->end_time = ticks;
    80002556:	00007797          	auipc	a5,0x7
    8000255a:	ada7a783          	lw	a5,-1318(a5) # 80009030 <ticks>
    8000255e:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002562:	8526                	mv	a0,s1
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	734080e7          	jalr	1844(ra) # 80000c98 <release>
  sched();
    8000256c:	00000097          	auipc	ra,0x0
    80002570:	a7c080e7          	jalr	-1412(ra) # 80001fe8 <sched>
  panic("zombie exit");
    80002574:	00006517          	auipc	a0,0x6
    80002578:	d0450513          	addi	a0,a0,-764 # 80008278 <digits+0x238>
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	fc2080e7          	jalr	-62(ra) # 8000053e <panic>

0000000080002584 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002584:	7179                	addi	sp,sp,-48
    80002586:	f406                	sd	ra,40(sp)
    80002588:	f022                	sd	s0,32(sp)
    8000258a:	ec26                	sd	s1,24(sp)
    8000258c:	e84a                	sd	s2,16(sp)
    8000258e:	e44e                	sd	s3,8(sp)
    80002590:	1800                	addi	s0,sp,48
    80002592:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002594:	0000f497          	auipc	s1,0xf
    80002598:	13c48493          	addi	s1,s1,316 # 800116d0 <proc>
    8000259c:	00015997          	auipc	s3,0x15
    800025a0:	f3498993          	addi	s3,s3,-204 # 800174d0 <tickslock>
    acquire(&p->lock);
    800025a4:	8526                	mv	a0,s1
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	63e080e7          	jalr	1598(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025ae:	589c                	lw	a5,48(s1)
    800025b0:	01278d63          	beq	a5,s2,800025ca <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025b4:	8526                	mv	a0,s1
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	6e2080e7          	jalr	1762(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025be:	17848493          	addi	s1,s1,376
    800025c2:	ff3491e3          	bne	s1,s3,800025a4 <kill+0x20>
  }
  return -1;
    800025c6:	557d                	li	a0,-1
    800025c8:	a829                	j	800025e2 <kill+0x5e>
      p->killed = 1;
    800025ca:	4785                	li	a5,1
    800025cc:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025ce:	4c98                	lw	a4,24(s1)
    800025d0:	4789                	li	a5,2
    800025d2:	00f70f63          	beq	a4,a5,800025f0 <kill+0x6c>
      release(&p->lock);
    800025d6:	8526                	mv	a0,s1
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	6c0080e7          	jalr	1728(ra) # 80000c98 <release>
      return 0;
    800025e0:	4501                	li	a0,0
}
    800025e2:	70a2                	ld	ra,40(sp)
    800025e4:	7402                	ld	s0,32(sp)
    800025e6:	64e2                	ld	s1,24(sp)
    800025e8:	6942                	ld	s2,16(sp)
    800025ea:	69a2                	ld	s3,8(sp)
    800025ec:	6145                	addi	sp,sp,48
    800025ee:	8082                	ret
        p->state = RUNNABLE;
    800025f0:	478d                	li	a5,3
    800025f2:	cc9c                	sw	a5,24(s1)
    800025f4:	b7cd                	j	800025d6 <kill+0x52>

00000000800025f6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025f6:	7179                	addi	sp,sp,-48
    800025f8:	f406                	sd	ra,40(sp)
    800025fa:	f022                	sd	s0,32(sp)
    800025fc:	ec26                	sd	s1,24(sp)
    800025fe:	e84a                	sd	s2,16(sp)
    80002600:	e44e                	sd	s3,8(sp)
    80002602:	e052                	sd	s4,0(sp)
    80002604:	1800                	addi	s0,sp,48
    80002606:	84aa                	mv	s1,a0
    80002608:	892e                	mv	s2,a1
    8000260a:	89b2                	mv	s3,a2
    8000260c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000260e:	fffff097          	auipc	ra,0xfffff
    80002612:	400080e7          	jalr	1024(ra) # 80001a0e <myproc>
  if(user_dst){
    80002616:	c08d                	beqz	s1,80002638 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002618:	86d2                	mv	a3,s4
    8000261a:	864e                	mv	a2,s3
    8000261c:	85ca                	mv	a1,s2
    8000261e:	6928                	ld	a0,80(a0)
    80002620:	fffff097          	auipc	ra,0xfffff
    80002624:	052080e7          	jalr	82(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002628:	70a2                	ld	ra,40(sp)
    8000262a:	7402                	ld	s0,32(sp)
    8000262c:	64e2                	ld	s1,24(sp)
    8000262e:	6942                	ld	s2,16(sp)
    80002630:	69a2                	ld	s3,8(sp)
    80002632:	6a02                	ld	s4,0(sp)
    80002634:	6145                	addi	sp,sp,48
    80002636:	8082                	ret
    memmove((char *)dst, src, len);
    80002638:	000a061b          	sext.w	a2,s4
    8000263c:	85ce                	mv	a1,s3
    8000263e:	854a                	mv	a0,s2
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	700080e7          	jalr	1792(ra) # 80000d40 <memmove>
    return 0;
    80002648:	8526                	mv	a0,s1
    8000264a:	bff9                	j	80002628 <either_copyout+0x32>

000000008000264c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000264c:	7179                	addi	sp,sp,-48
    8000264e:	f406                	sd	ra,40(sp)
    80002650:	f022                	sd	s0,32(sp)
    80002652:	ec26                	sd	s1,24(sp)
    80002654:	e84a                	sd	s2,16(sp)
    80002656:	e44e                	sd	s3,8(sp)
    80002658:	e052                	sd	s4,0(sp)
    8000265a:	1800                	addi	s0,sp,48
    8000265c:	892a                	mv	s2,a0
    8000265e:	84ae                	mv	s1,a1
    80002660:	89b2                	mv	s3,a2
    80002662:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002664:	fffff097          	auipc	ra,0xfffff
    80002668:	3aa080e7          	jalr	938(ra) # 80001a0e <myproc>
  if(user_src){
    8000266c:	c08d                	beqz	s1,8000268e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000266e:	86d2                	mv	a3,s4
    80002670:	864e                	mv	a2,s3
    80002672:	85ca                	mv	a1,s2
    80002674:	6928                	ld	a0,80(a0)
    80002676:	fffff097          	auipc	ra,0xfffff
    8000267a:	088080e7          	jalr	136(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000267e:	70a2                	ld	ra,40(sp)
    80002680:	7402                	ld	s0,32(sp)
    80002682:	64e2                	ld	s1,24(sp)
    80002684:	6942                	ld	s2,16(sp)
    80002686:	69a2                	ld	s3,8(sp)
    80002688:	6a02                	ld	s4,0(sp)
    8000268a:	6145                	addi	sp,sp,48
    8000268c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000268e:	000a061b          	sext.w	a2,s4
    80002692:	85ce                	mv	a1,s3
    80002694:	854a                	mv	a0,s2
    80002696:	ffffe097          	auipc	ra,0xffffe
    8000269a:	6aa080e7          	jalr	1706(ra) # 80000d40 <memmove>
    return 0;
    8000269e:	8526                	mv	a0,s1
    800026a0:	bff9                	j	8000267e <either_copyin+0x32>

00000000800026a2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026a2:	715d                	addi	sp,sp,-80
    800026a4:	e486                	sd	ra,72(sp)
    800026a6:	e0a2                	sd	s0,64(sp)
    800026a8:	fc26                	sd	s1,56(sp)
    800026aa:	f84a                	sd	s2,48(sp)
    800026ac:	f44e                	sd	s3,40(sp)
    800026ae:	f052                	sd	s4,32(sp)
    800026b0:	ec56                	sd	s5,24(sp)
    800026b2:	e85a                	sd	s6,16(sp)
    800026b4:	e45e                	sd	s7,8(sp)
    800026b6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026b8:	00006517          	auipc	a0,0x6
    800026bc:	e4050513          	addi	a0,a0,-448 # 800084f8 <states.1738+0x230>
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	ec8080e7          	jalr	-312(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026c8:	0000f497          	auipc	s1,0xf
    800026cc:	16048493          	addi	s1,s1,352 # 80011828 <proc+0x158>
    800026d0:	00015917          	auipc	s2,0x15
    800026d4:	f5890913          	addi	s2,s2,-168 # 80017628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026d8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026da:	00006997          	auipc	s3,0x6
    800026de:	bae98993          	addi	s3,s3,-1106 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800026e2:	00006a97          	auipc	s5,0x6
    800026e6:	baea8a93          	addi	s5,s5,-1106 # 80008290 <digits+0x250>
    printf("\n");
    800026ea:	00006a17          	auipc	s4,0x6
    800026ee:	e0ea0a13          	addi	s4,s4,-498 # 800084f8 <states.1738+0x230>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f2:	00006b97          	auipc	s7,0x6
    800026f6:	bd6b8b93          	addi	s7,s7,-1066 # 800082c8 <states.1738>
    800026fa:	a00d                	j	8000271c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026fc:	ed86a583          	lw	a1,-296(a3)
    80002700:	8556                	mv	a0,s5
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	e86080e7          	jalr	-378(ra) # 80000588 <printf>
    printf("\n");
    8000270a:	8552                	mv	a0,s4
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	e7c080e7          	jalr	-388(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002714:	17848493          	addi	s1,s1,376
    80002718:	03248163          	beq	s1,s2,8000273a <procdump+0x98>
    if(p->state == UNUSED)
    8000271c:	86a6                	mv	a3,s1
    8000271e:	ec04a783          	lw	a5,-320(s1)
    80002722:	dbed                	beqz	a5,80002714 <procdump+0x72>
      state = "???";
    80002724:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002726:	fcfb6be3          	bltu	s6,a5,800026fc <procdump+0x5a>
    8000272a:	1782                	slli	a5,a5,0x20
    8000272c:	9381                	srli	a5,a5,0x20
    8000272e:	078e                	slli	a5,a5,0x3
    80002730:	97de                	add	a5,a5,s7
    80002732:	6390                	ld	a2,0(a5)
    80002734:	f661                	bnez	a2,800026fc <procdump+0x5a>
      state = "???";
    80002736:	864e                	mv	a2,s3
    80002738:	b7d1                	j	800026fc <procdump+0x5a>
  }
}
    8000273a:	60a6                	ld	ra,72(sp)
    8000273c:	6406                	ld	s0,64(sp)
    8000273e:	74e2                	ld	s1,56(sp)
    80002740:	7942                	ld	s2,48(sp)
    80002742:	79a2                	ld	s3,40(sp)
    80002744:	7a02                	ld	s4,32(sp)
    80002746:	6ae2                	ld	s5,24(sp)
    80002748:	6b42                	ld	s6,16(sp)
    8000274a:	6ba2                	ld	s7,8(sp)
    8000274c:	6161                	addi	sp,sp,80
    8000274e:	8082                	ret

0000000080002750 <swtch>:
    80002750:	00153023          	sd	ra,0(a0)
    80002754:	00253423          	sd	sp,8(a0)
    80002758:	e900                	sd	s0,16(a0)
    8000275a:	ed04                	sd	s1,24(a0)
    8000275c:	03253023          	sd	s2,32(a0)
    80002760:	03353423          	sd	s3,40(a0)
    80002764:	03453823          	sd	s4,48(a0)
    80002768:	03553c23          	sd	s5,56(a0)
    8000276c:	05653023          	sd	s6,64(a0)
    80002770:	05753423          	sd	s7,72(a0)
    80002774:	05853823          	sd	s8,80(a0)
    80002778:	05953c23          	sd	s9,88(a0)
    8000277c:	07a53023          	sd	s10,96(a0)
    80002780:	07b53423          	sd	s11,104(a0)
    80002784:	0005b083          	ld	ra,0(a1)
    80002788:	0085b103          	ld	sp,8(a1)
    8000278c:	6980                	ld	s0,16(a1)
    8000278e:	6d84                	ld	s1,24(a1)
    80002790:	0205b903          	ld	s2,32(a1)
    80002794:	0285b983          	ld	s3,40(a1)
    80002798:	0305ba03          	ld	s4,48(a1)
    8000279c:	0385ba83          	ld	s5,56(a1)
    800027a0:	0405bb03          	ld	s6,64(a1)
    800027a4:	0485bb83          	ld	s7,72(a1)
    800027a8:	0505bc03          	ld	s8,80(a1)
    800027ac:	0585bc83          	ld	s9,88(a1)
    800027b0:	0605bd03          	ld	s10,96(a1)
    800027b4:	0685bd83          	ld	s11,104(a1)
    800027b8:	8082                	ret

00000000800027ba <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027ba:	1141                	addi	sp,sp,-16
    800027bc:	e406                	sd	ra,8(sp)
    800027be:	e022                	sd	s0,0(sp)
    800027c0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027c2:	00006597          	auipc	a1,0x6
    800027c6:	b3658593          	addi	a1,a1,-1226 # 800082f8 <states.1738+0x30>
    800027ca:	00015517          	auipc	a0,0x15
    800027ce:	d0650513          	addi	a0,a0,-762 # 800174d0 <tickslock>
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	382080e7          	jalr	898(ra) # 80000b54 <initlock>
}
    800027da:	60a2                	ld	ra,8(sp)
    800027dc:	6402                	ld	s0,0(sp)
    800027de:	0141                	addi	sp,sp,16
    800027e0:	8082                	ret

00000000800027e2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027e2:	1141                	addi	sp,sp,-16
    800027e4:	e422                	sd	s0,8(sp)
    800027e6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027e8:	00003797          	auipc	a5,0x3
    800027ec:	71878793          	addi	a5,a5,1816 # 80005f00 <kernelvec>
    800027f0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027f4:	6422                	ld	s0,8(sp)
    800027f6:	0141                	addi	sp,sp,16
    800027f8:	8082                	ret

00000000800027fa <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027fa:	1141                	addi	sp,sp,-16
    800027fc:	e406                	sd	ra,8(sp)
    800027fe:	e022                	sd	s0,0(sp)
    80002800:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002802:	fffff097          	auipc	ra,0xfffff
    80002806:	20c080e7          	jalr	524(ra) # 80001a0e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000280a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000280e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002810:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002814:	00004617          	auipc	a2,0x4
    80002818:	7ec60613          	addi	a2,a2,2028 # 80007000 <_trampoline>
    8000281c:	00004697          	auipc	a3,0x4
    80002820:	7e468693          	addi	a3,a3,2020 # 80007000 <_trampoline>
    80002824:	8e91                	sub	a3,a3,a2
    80002826:	040007b7          	lui	a5,0x4000
    8000282a:	17fd                	addi	a5,a5,-1
    8000282c:	07b2                	slli	a5,a5,0xc
    8000282e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002830:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002834:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002836:	180026f3          	csrr	a3,satp
    8000283a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000283c:	6d38                	ld	a4,88(a0)
    8000283e:	6134                	ld	a3,64(a0)
    80002840:	6585                	lui	a1,0x1
    80002842:	96ae                	add	a3,a3,a1
    80002844:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002846:	6d38                	ld	a4,88(a0)
    80002848:	00000697          	auipc	a3,0x0
    8000284c:	14668693          	addi	a3,a3,326 # 8000298e <usertrap>
    80002850:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002852:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002854:	8692                	mv	a3,tp
    80002856:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002858:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000285c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002860:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002864:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002868:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000286a:	6f18                	ld	a4,24(a4)
    8000286c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002870:	692c                	ld	a1,80(a0)
    80002872:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002874:	00005717          	auipc	a4,0x5
    80002878:	81c70713          	addi	a4,a4,-2020 # 80007090 <userret>
    8000287c:	8f11                	sub	a4,a4,a2
    8000287e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002880:	577d                	li	a4,-1
    80002882:	177e                	slli	a4,a4,0x3f
    80002884:	8dd9                	or	a1,a1,a4
    80002886:	02000537          	lui	a0,0x2000
    8000288a:	157d                	addi	a0,a0,-1
    8000288c:	0536                	slli	a0,a0,0xd
    8000288e:	9782                	jalr	a5
}
    80002890:	60a2                	ld	ra,8(sp)
    80002892:	6402                	ld	s0,0(sp)
    80002894:	0141                	addi	sp,sp,16
    80002896:	8082                	ret

0000000080002898 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002898:	1101                	addi	sp,sp,-32
    8000289a:	ec06                	sd	ra,24(sp)
    8000289c:	e822                	sd	s0,16(sp)
    8000289e:	e426                	sd	s1,8(sp)
    800028a0:	e04a                	sd	s2,0(sp)
    800028a2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028a4:	00015917          	auipc	s2,0x15
    800028a8:	c2c90913          	addi	s2,s2,-980 # 800174d0 <tickslock>
    800028ac:	854a                	mv	a0,s2
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	336080e7          	jalr	822(ra) # 80000be4 <acquire>
  ticks++;
    800028b6:	00006497          	auipc	s1,0x6
    800028ba:	77a48493          	addi	s1,s1,1914 # 80009030 <ticks>
    800028be:	409c                	lw	a5,0(s1)
    800028c0:	2785                	addiw	a5,a5,1
    800028c2:	c09c                	sw	a5,0(s1)
  inc_runtime();
    800028c4:	fffff097          	auipc	ra,0xfffff
    800028c8:	f7a080e7          	jalr	-134(ra) # 8000183e <inc_runtime>
  wakeup(&ticks);
    800028cc:	8526                	mv	a0,s1
    800028ce:	00000097          	auipc	ra,0x0
    800028d2:	b04080e7          	jalr	-1276(ra) # 800023d2 <wakeup>
  release(&tickslock);
    800028d6:	854a                	mv	a0,s2
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	3c0080e7          	jalr	960(ra) # 80000c98 <release>
}
    800028e0:	60e2                	ld	ra,24(sp)
    800028e2:	6442                	ld	s0,16(sp)
    800028e4:	64a2                	ld	s1,8(sp)
    800028e6:	6902                	ld	s2,0(sp)
    800028e8:	6105                	addi	sp,sp,32
    800028ea:	8082                	ret

00000000800028ec <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028ec:	1101                	addi	sp,sp,-32
    800028ee:	ec06                	sd	ra,24(sp)
    800028f0:	e822                	sd	s0,16(sp)
    800028f2:	e426                	sd	s1,8(sp)
    800028f4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028fa:	00074d63          	bltz	a4,80002914 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028fe:	57fd                	li	a5,-1
    80002900:	17fe                	slli	a5,a5,0x3f
    80002902:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002904:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002906:	06f70363          	beq	a4,a5,8000296c <devintr+0x80>
  }
}
    8000290a:	60e2                	ld	ra,24(sp)
    8000290c:	6442                	ld	s0,16(sp)
    8000290e:	64a2                	ld	s1,8(sp)
    80002910:	6105                	addi	sp,sp,32
    80002912:	8082                	ret
     (scause & 0xff) == 9){
    80002914:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002918:	46a5                	li	a3,9
    8000291a:	fed792e3          	bne	a5,a3,800028fe <devintr+0x12>
    int irq = plic_claim();
    8000291e:	00003097          	auipc	ra,0x3
    80002922:	6ea080e7          	jalr	1770(ra) # 80006008 <plic_claim>
    80002926:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002928:	47a9                	li	a5,10
    8000292a:	02f50763          	beq	a0,a5,80002958 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000292e:	4785                	li	a5,1
    80002930:	02f50963          	beq	a0,a5,80002962 <devintr+0x76>
    return 1;
    80002934:	4505                	li	a0,1
    } else if(irq){
    80002936:	d8f1                	beqz	s1,8000290a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002938:	85a6                	mv	a1,s1
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	9c650513          	addi	a0,a0,-1594 # 80008300 <states.1738+0x38>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	c46080e7          	jalr	-954(ra) # 80000588 <printf>
      plic_complete(irq);
    8000294a:	8526                	mv	a0,s1
    8000294c:	00003097          	auipc	ra,0x3
    80002950:	6e0080e7          	jalr	1760(ra) # 8000602c <plic_complete>
    return 1;
    80002954:	4505                	li	a0,1
    80002956:	bf55                	j	8000290a <devintr+0x1e>
      uartintr();
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	050080e7          	jalr	80(ra) # 800009a8 <uartintr>
    80002960:	b7ed                	j	8000294a <devintr+0x5e>
      virtio_disk_intr();
    80002962:	00004097          	auipc	ra,0x4
    80002966:	baa080e7          	jalr	-1110(ra) # 8000650c <virtio_disk_intr>
    8000296a:	b7c5                	j	8000294a <devintr+0x5e>
    if(cpuid() == 0){
    8000296c:	fffff097          	auipc	ra,0xfffff
    80002970:	076080e7          	jalr	118(ra) # 800019e2 <cpuid>
    80002974:	c901                	beqz	a0,80002984 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002976:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000297a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000297c:	14479073          	csrw	sip,a5
    return 2;
    80002980:	4509                	li	a0,2
    80002982:	b761                	j	8000290a <devintr+0x1e>
      clockintr();
    80002984:	00000097          	auipc	ra,0x0
    80002988:	f14080e7          	jalr	-236(ra) # 80002898 <clockintr>
    8000298c:	b7ed                	j	80002976 <devintr+0x8a>

000000008000298e <usertrap>:
{
    8000298e:	1101                	addi	sp,sp,-32
    80002990:	ec06                	sd	ra,24(sp)
    80002992:	e822                	sd	s0,16(sp)
    80002994:	e426                	sd	s1,8(sp)
    80002996:	e04a                	sd	s2,0(sp)
    80002998:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000299a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000299e:	1007f793          	andi	a5,a5,256
    800029a2:	e3ad                	bnez	a5,80002a04 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a4:	00003797          	auipc	a5,0x3
    800029a8:	55c78793          	addi	a5,a5,1372 # 80005f00 <kernelvec>
    800029ac:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029b0:	fffff097          	auipc	ra,0xfffff
    800029b4:	05e080e7          	jalr	94(ra) # 80001a0e <myproc>
    800029b8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029ba:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029bc:	14102773          	csrr	a4,sepc
    800029c0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029c6:	47a1                	li	a5,8
    800029c8:	04f71c63          	bne	a4,a5,80002a20 <usertrap+0x92>
    if(p->killed)
    800029cc:	551c                	lw	a5,40(a0)
    800029ce:	e3b9                	bnez	a5,80002a14 <usertrap+0x86>
    p->trapframe->epc += 4;
    800029d0:	6cb8                	ld	a4,88(s1)
    800029d2:	6f1c                	ld	a5,24(a4)
    800029d4:	0791                	addi	a5,a5,4
    800029d6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029dc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e0:	10079073          	csrw	sstatus,a5
    syscall();
    800029e4:	00000097          	auipc	ra,0x0
    800029e8:	2e0080e7          	jalr	736(ra) # 80002cc4 <syscall>
  if(p->killed)
    800029ec:	549c                	lw	a5,40(s1)
    800029ee:	ebc1                	bnez	a5,80002a7e <usertrap+0xf0>
  usertrapret();
    800029f0:	00000097          	auipc	ra,0x0
    800029f4:	e0a080e7          	jalr	-502(ra) # 800027fa <usertrapret>
}
    800029f8:	60e2                	ld	ra,24(sp)
    800029fa:	6442                	ld	s0,16(sp)
    800029fc:	64a2                	ld	s1,8(sp)
    800029fe:	6902                	ld	s2,0(sp)
    80002a00:	6105                	addi	sp,sp,32
    80002a02:	8082                	ret
    panic("usertrap: not from user mode");
    80002a04:	00006517          	auipc	a0,0x6
    80002a08:	91c50513          	addi	a0,a0,-1764 # 80008320 <states.1738+0x58>
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	b32080e7          	jalr	-1230(ra) # 8000053e <panic>
      exit(-1);
    80002a14:	557d                	li	a0,-1
    80002a16:	00000097          	auipc	ra,0x0
    80002a1a:	a8c080e7          	jalr	-1396(ra) # 800024a2 <exit>
    80002a1e:	bf4d                	j	800029d0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a20:	00000097          	auipc	ra,0x0
    80002a24:	ecc080e7          	jalr	-308(ra) # 800028ec <devintr>
    80002a28:	892a                	mv	s2,a0
    80002a2a:	c501                	beqz	a0,80002a32 <usertrap+0xa4>
  if(p->killed)
    80002a2c:	549c                	lw	a5,40(s1)
    80002a2e:	c3a1                	beqz	a5,80002a6e <usertrap+0xe0>
    80002a30:	a815                	j	80002a64 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a32:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a36:	5890                	lw	a2,48(s1)
    80002a38:	00006517          	auipc	a0,0x6
    80002a3c:	90850513          	addi	a0,a0,-1784 # 80008340 <states.1738+0x78>
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	b48080e7          	jalr	-1208(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a48:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a4c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a50:	00006517          	auipc	a0,0x6
    80002a54:	92050513          	addi	a0,a0,-1760 # 80008370 <states.1738+0xa8>
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	b30080e7          	jalr	-1232(ra) # 80000588 <printf>
    p->killed = 1;
    80002a60:	4785                	li	a5,1
    80002a62:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a64:	557d                	li	a0,-1
    80002a66:	00000097          	auipc	ra,0x0
    80002a6a:	a3c080e7          	jalr	-1476(ra) # 800024a2 <exit>
    if(which_dev == 2)
    80002a6e:	4789                	li	a5,2
    80002a70:	f8f910e3          	bne	s2,a5,800029f0 <usertrap+0x62>
    yield();
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	64a080e7          	jalr	1610(ra) # 800020be <yield>
    80002a7c:	bf95                	j	800029f0 <usertrap+0x62>
  int which_dev = 0;
    80002a7e:	4901                	li	s2,0
    80002a80:	b7d5                	j	80002a64 <usertrap+0xd6>

0000000080002a82 <kerneltrap>:
{
    80002a82:	7179                	addi	sp,sp,-48
    80002a84:	f406                	sd	ra,40(sp)
    80002a86:	f022                	sd	s0,32(sp)
    80002a88:	ec26                	sd	s1,24(sp)
    80002a8a:	e84a                	sd	s2,16(sp)
    80002a8c:	e44e                	sd	s3,8(sp)
    80002a8e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a90:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a94:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a98:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a9c:	1004f793          	andi	a5,s1,256
    80002aa0:	cb85                	beqz	a5,80002ad0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002aa6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002aa8:	ef85                	bnez	a5,80002ae0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	e42080e7          	jalr	-446(ra) # 800028ec <devintr>
    80002ab2:	cd1d                	beqz	a0,80002af0 <kerneltrap+0x6e>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ab4:	4789                	li	a5,2
    80002ab6:	06f50a63          	beq	a0,a5,80002b2a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002aba:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002abe:	10049073          	csrw	sstatus,s1
}
    80002ac2:	70a2                	ld	ra,40(sp)
    80002ac4:	7402                	ld	s0,32(sp)
    80002ac6:	64e2                	ld	s1,24(sp)
    80002ac8:	6942                	ld	s2,16(sp)
    80002aca:	69a2                	ld	s3,8(sp)
    80002acc:	6145                	addi	sp,sp,48
    80002ace:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ad0:	00006517          	auipc	a0,0x6
    80002ad4:	8c050513          	addi	a0,a0,-1856 # 80008390 <states.1738+0xc8>
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	a66080e7          	jalr	-1434(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ae0:	00006517          	auipc	a0,0x6
    80002ae4:	8d850513          	addi	a0,a0,-1832 # 800083b8 <states.1738+0xf0>
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	a56080e7          	jalr	-1450(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002af0:	85ce                	mv	a1,s3
    80002af2:	00006517          	auipc	a0,0x6
    80002af6:	8e650513          	addi	a0,a0,-1818 # 800083d8 <states.1738+0x110>
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	a8e080e7          	jalr	-1394(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b02:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b06:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	8de50513          	addi	a0,a0,-1826 # 800083e8 <states.1738+0x120>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a76080e7          	jalr	-1418(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b1a:	00006517          	auipc	a0,0x6
    80002b1e:	8e650513          	addi	a0,a0,-1818 # 80008400 <states.1738+0x138>
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	a1c080e7          	jalr	-1508(ra) # 8000053e <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	ee4080e7          	jalr	-284(ra) # 80001a0e <myproc>
    80002b32:	d541                	beqz	a0,80002aba <kerneltrap+0x38>
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	eda080e7          	jalr	-294(ra) # 80001a0e <myproc>
    80002b3c:	4d18                	lw	a4,24(a0)
    80002b3e:	4791                	li	a5,4
    80002b40:	f6f71de3          	bne	a4,a5,80002aba <kerneltrap+0x38>
    yield();
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	57a080e7          	jalr	1402(ra) # 800020be <yield>
    80002b4c:	b7bd                	j	80002aba <kerneltrap+0x38>

0000000080002b4e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b4e:	1101                	addi	sp,sp,-32
    80002b50:	ec06                	sd	ra,24(sp)
    80002b52:	e822                	sd	s0,16(sp)
    80002b54:	e426                	sd	s1,8(sp)
    80002b56:	1000                	addi	s0,sp,32
    80002b58:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b5a:	fffff097          	auipc	ra,0xfffff
    80002b5e:	eb4080e7          	jalr	-332(ra) # 80001a0e <myproc>
  switch (n) {
    80002b62:	4795                	li	a5,5
    80002b64:	0497e163          	bltu	a5,s1,80002ba6 <argraw+0x58>
    80002b68:	048a                	slli	s1,s1,0x2
    80002b6a:	00006717          	auipc	a4,0x6
    80002b6e:	a6670713          	addi	a4,a4,-1434 # 800085d0 <states.1738+0x308>
    80002b72:	94ba                	add	s1,s1,a4
    80002b74:	409c                	lw	a5,0(s1)
    80002b76:	97ba                	add	a5,a5,a4
    80002b78:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b7a:	6d3c                	ld	a5,88(a0)
    80002b7c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b7e:	60e2                	ld	ra,24(sp)
    80002b80:	6442                	ld	s0,16(sp)
    80002b82:	64a2                	ld	s1,8(sp)
    80002b84:	6105                	addi	sp,sp,32
    80002b86:	8082                	ret
    return p->trapframe->a1;
    80002b88:	6d3c                	ld	a5,88(a0)
    80002b8a:	7fa8                	ld	a0,120(a5)
    80002b8c:	bfcd                	j	80002b7e <argraw+0x30>
    return p->trapframe->a2;
    80002b8e:	6d3c                	ld	a5,88(a0)
    80002b90:	63c8                	ld	a0,128(a5)
    80002b92:	b7f5                	j	80002b7e <argraw+0x30>
    return p->trapframe->a3;
    80002b94:	6d3c                	ld	a5,88(a0)
    80002b96:	67c8                	ld	a0,136(a5)
    80002b98:	b7dd                	j	80002b7e <argraw+0x30>
    return p->trapframe->a4;
    80002b9a:	6d3c                	ld	a5,88(a0)
    80002b9c:	6bc8                	ld	a0,144(a5)
    80002b9e:	b7c5                	j	80002b7e <argraw+0x30>
    return p->trapframe->a5;
    80002ba0:	6d3c                	ld	a5,88(a0)
    80002ba2:	6fc8                	ld	a0,152(a5)
    80002ba4:	bfe9                	j	80002b7e <argraw+0x30>
  panic("argraw");
    80002ba6:	00006517          	auipc	a0,0x6
    80002baa:	86a50513          	addi	a0,a0,-1942 # 80008410 <states.1738+0x148>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	990080e7          	jalr	-1648(ra) # 8000053e <panic>

0000000080002bb6 <fetchaddr>:
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	e426                	sd	s1,8(sp)
    80002bbe:	e04a                	sd	s2,0(sp)
    80002bc0:	1000                	addi	s0,sp,32
    80002bc2:	84aa                	mv	s1,a0
    80002bc4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	e48080e7          	jalr	-440(ra) # 80001a0e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bce:	653c                	ld	a5,72(a0)
    80002bd0:	02f4f863          	bgeu	s1,a5,80002c00 <fetchaddr+0x4a>
    80002bd4:	00848713          	addi	a4,s1,8
    80002bd8:	02e7e663          	bltu	a5,a4,80002c04 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bdc:	46a1                	li	a3,8
    80002bde:	8626                	mv	a2,s1
    80002be0:	85ca                	mv	a1,s2
    80002be2:	6928                	ld	a0,80(a0)
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	b1a080e7          	jalr	-1254(ra) # 800016fe <copyin>
    80002bec:	00a03533          	snez	a0,a0
    80002bf0:	40a00533          	neg	a0,a0
}
    80002bf4:	60e2                	ld	ra,24(sp)
    80002bf6:	6442                	ld	s0,16(sp)
    80002bf8:	64a2                	ld	s1,8(sp)
    80002bfa:	6902                	ld	s2,0(sp)
    80002bfc:	6105                	addi	sp,sp,32
    80002bfe:	8082                	ret
    return -1;
    80002c00:	557d                	li	a0,-1
    80002c02:	bfcd                	j	80002bf4 <fetchaddr+0x3e>
    80002c04:	557d                	li	a0,-1
    80002c06:	b7fd                	j	80002bf4 <fetchaddr+0x3e>

0000000080002c08 <fetchstr>:
{
    80002c08:	7179                	addi	sp,sp,-48
    80002c0a:	f406                	sd	ra,40(sp)
    80002c0c:	f022                	sd	s0,32(sp)
    80002c0e:	ec26                	sd	s1,24(sp)
    80002c10:	e84a                	sd	s2,16(sp)
    80002c12:	e44e                	sd	s3,8(sp)
    80002c14:	1800                	addi	s0,sp,48
    80002c16:	892a                	mv	s2,a0
    80002c18:	84ae                	mv	s1,a1
    80002c1a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c1c:	fffff097          	auipc	ra,0xfffff
    80002c20:	df2080e7          	jalr	-526(ra) # 80001a0e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c24:	86ce                	mv	a3,s3
    80002c26:	864a                	mv	a2,s2
    80002c28:	85a6                	mv	a1,s1
    80002c2a:	6928                	ld	a0,80(a0)
    80002c2c:	fffff097          	auipc	ra,0xfffff
    80002c30:	b5e080e7          	jalr	-1186(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002c34:	00054763          	bltz	a0,80002c42 <fetchstr+0x3a>
  return strlen(buf);
    80002c38:	8526                	mv	a0,s1
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	22a080e7          	jalr	554(ra) # 80000e64 <strlen>
}
    80002c42:	70a2                	ld	ra,40(sp)
    80002c44:	7402                	ld	s0,32(sp)
    80002c46:	64e2                	ld	s1,24(sp)
    80002c48:	6942                	ld	s2,16(sp)
    80002c4a:	69a2                	ld	s3,8(sp)
    80002c4c:	6145                	addi	sp,sp,48
    80002c4e:	8082                	ret

0000000080002c50 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c50:	1101                	addi	sp,sp,-32
    80002c52:	ec06                	sd	ra,24(sp)
    80002c54:	e822                	sd	s0,16(sp)
    80002c56:	e426                	sd	s1,8(sp)
    80002c58:	1000                	addi	s0,sp,32
    80002c5a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c5c:	00000097          	auipc	ra,0x0
    80002c60:	ef2080e7          	jalr	-270(ra) # 80002b4e <argraw>
    80002c64:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c66:	4501                	li	a0,0
    80002c68:	60e2                	ld	ra,24(sp)
    80002c6a:	6442                	ld	s0,16(sp)
    80002c6c:	64a2                	ld	s1,8(sp)
    80002c6e:	6105                	addi	sp,sp,32
    80002c70:	8082                	ret

0000000080002c72 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c72:	1101                	addi	sp,sp,-32
    80002c74:	ec06                	sd	ra,24(sp)
    80002c76:	e822                	sd	s0,16(sp)
    80002c78:	e426                	sd	s1,8(sp)
    80002c7a:	1000                	addi	s0,sp,32
    80002c7c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	ed0080e7          	jalr	-304(ra) # 80002b4e <argraw>
    80002c86:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c88:	4501                	li	a0,0
    80002c8a:	60e2                	ld	ra,24(sp)
    80002c8c:	6442                	ld	s0,16(sp)
    80002c8e:	64a2                	ld	s1,8(sp)
    80002c90:	6105                	addi	sp,sp,32
    80002c92:	8082                	ret

0000000080002c94 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	e426                	sd	s1,8(sp)
    80002c9c:	e04a                	sd	s2,0(sp)
    80002c9e:	1000                	addi	s0,sp,32
    80002ca0:	84ae                	mv	s1,a1
    80002ca2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ca4:	00000097          	auipc	ra,0x0
    80002ca8:	eaa080e7          	jalr	-342(ra) # 80002b4e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cac:	864a                	mv	a2,s2
    80002cae:	85a6                	mv	a1,s1
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	f58080e7          	jalr	-168(ra) # 80002c08 <fetchstr>
}
    80002cb8:	60e2                	ld	ra,24(sp)
    80002cba:	6442                	ld	s0,16(sp)
    80002cbc:	64a2                	ld	s1,8(sp)
    80002cbe:	6902                	ld	s2,0(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret

0000000080002cc4 <syscall>:
[SYS_waitx]   3,
};

void
syscall(void)
{
    80002cc4:	7139                	addi	sp,sp,-64
    80002cc6:	fc06                	sd	ra,56(sp)
    80002cc8:	f822                	sd	s0,48(sp)
    80002cca:	f426                	sd	s1,40(sp)
    80002ccc:	f04a                	sd	s2,32(sp)
    80002cce:	ec4e                	sd	s3,24(sp)
    80002cd0:	e852                	sd	s4,16(sp)
    80002cd2:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	d3a080e7          	jalr	-710(ra) # 80001a0e <myproc>
    80002cdc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cde:	05853903          	ld	s2,88(a0)
    80002ce2:	0a893783          	ld	a5,168(s2)
    80002ce6:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cea:	37fd                	addiw	a5,a5,-1
    80002cec:	4759                	li	a4,22
    80002cee:	1af76763          	bltu	a4,a5,80002e9c <syscall+0x1d8>
    80002cf2:	00399713          	slli	a4,s3,0x3
    80002cf6:	00006797          	auipc	a5,0x6
    80002cfa:	8f278793          	addi	a5,a5,-1806 # 800085e8 <syscalls>
    80002cfe:	97ba                	add	a5,a5,a4
    80002d00:	639c                	ld	a5,0(a5)
    80002d02:	18078d63          	beqz	a5,80002e9c <syscall+0x1d8>
    int x = p->trapframe->a0;
    80002d06:	07093a03          	ld	s4,112(s2)
    p->trapframe->a0 = syscalls[num]();
    80002d0a:	9782                	jalr	a5
    80002d0c:	06a93823          	sd	a0,112(s2)
    if (((1<<num) & p->tracy)!=0)
    80002d10:	1684a783          	lw	a5,360(s1)
    80002d14:	4137d7bb          	sraw	a5,a5,s3
    80002d18:	8b85                	andi	a5,a5,1
    80002d1a:	1a078063          	beqz	a5,80002eba <syscall+0x1f6>
    int x = p->trapframe->a0;
    80002d1e:	000a069b          	sext.w	a3,s4
    {
      if (nargs[num]==0)
    80002d22:	00299713          	slli	a4,s3,0x2
    80002d26:	00006797          	auipc	a5,0x6
    80002d2a:	ce278793          	addi	a5,a5,-798 # 80008a08 <nargs>
    80002d2e:	97ba                	add	a5,a5,a4
    80002d30:	439c                	lw	a5,0(a5)
    80002d32:	cfa9                	beqz	a5,80002d8c <syscall+0xc8>
      {
        printf("%d: syscall %s (%d) -> %d\n",p->pid,names[num],x,p->trapframe->a0);
      }
      else if (nargs[num]==1)
    80002d34:	4705                	li	a4,1
    80002d36:	06e78f63          	beq	a5,a4,80002db4 <syscall+0xf0>
      {
        printf("%d: syscall %s (%d) -> %d\n",p->pid,names[num],x,p->trapframe->a0);
      }
      else if (nargs[num]==2)
    80002d3a:	4709                	li	a4,2
    80002d3c:	0ae78063          	beq	a5,a4,80002ddc <syscall+0x118>
      {
        printf("%d: syscall %s (%d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a0);
      }
      else if (nargs[num]==3)
    80002d40:	470d                	li	a4,3
    80002d42:	0ce78263          	beq	a5,a4,80002e06 <syscall+0x142>
      {
        printf("%d: syscall %s (%d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a0);
      }
      else if (nargs[num]==4)
    80002d46:	4711                	li	a4,4
    80002d48:	0ee78663          	beq	a5,a4,80002e34 <syscall+0x170>
      {
              printf("%d: syscall %s (%d %d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a3,p->trapframe->a0);
      }
      else if (nargs[num]==5)
    80002d4c:	4715                	li	a4,5
    80002d4e:	10e78c63          	beq	a5,a4,80002e66 <syscall+0x1a2>
      {
              printf("%d: syscall %s (%d %d %d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a3,p->trapframe->a4,p->trapframe->a0);
      }
      else
      {
              printf("%d: syscall %s (%d %d %d %d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a3,p->trapframe->a4,p->trapframe->a5,p->trapframe->a0);
    80002d52:	6cb0                	ld	a2,88(s1)
    80002d54:	09063883          	ld	a7,144(a2)
    80002d58:	08863803          	ld	a6,136(a2)
    80002d5c:	625c                	ld	a5,128(a2)
    80002d5e:	7e38                	ld	a4,120(a2)
    80002d60:	098e                	slli	s3,s3,0x3
    80002d62:	00006597          	auipc	a1,0x6
    80002d66:	ca658593          	addi	a1,a1,-858 # 80008a08 <nargs>
    80002d6a:	99ae                	add	s3,s3,a1
    80002d6c:	588c                	lw	a1,48(s1)
    80002d6e:	7a28                	ld	a0,112(a2)
    80002d70:	e42a                	sd	a0,8(sp)
    80002d72:	6e50                	ld	a2,152(a2)
    80002d74:	e032                	sd	a2,0(sp)
    80002d76:	0609b603          	ld	a2,96(s3)
    80002d7a:	00005517          	auipc	a0,0x5
    80002d7e:	75650513          	addi	a0,a0,1878 # 800084d0 <states.1738+0x208>
    80002d82:	ffffe097          	auipc	ra,0xffffe
    80002d86:	806080e7          	jalr	-2042(ra) # 80000588 <printf>
    80002d8a:	aa05                	j	80002eba <syscall+0x1f6>
        printf("%d: syscall %s (%d) -> %d\n",p->pid,names[num],x,p->trapframe->a0);
    80002d8c:	6cb8                	ld	a4,88(s1)
    80002d8e:	098e                	slli	s3,s3,0x3
    80002d90:	00006797          	auipc	a5,0x6
    80002d94:	c7878793          	addi	a5,a5,-904 # 80008a08 <nargs>
    80002d98:	99be                	add	s3,s3,a5
    80002d9a:	7b38                	ld	a4,112(a4)
    80002d9c:	0609b603          	ld	a2,96(s3)
    80002da0:	588c                	lw	a1,48(s1)
    80002da2:	00005517          	auipc	a0,0x5
    80002da6:	67650513          	addi	a0,a0,1654 # 80008418 <states.1738+0x150>
    80002daa:	ffffd097          	auipc	ra,0xffffd
    80002dae:	7de080e7          	jalr	2014(ra) # 80000588 <printf>
    80002db2:	a221                	j	80002eba <syscall+0x1f6>
        printf("%d: syscall %s (%d) -> %d\n",p->pid,names[num],x,p->trapframe->a0);
    80002db4:	6cb8                	ld	a4,88(s1)
    80002db6:	098e                	slli	s3,s3,0x3
    80002db8:	00006797          	auipc	a5,0x6
    80002dbc:	c5078793          	addi	a5,a5,-944 # 80008a08 <nargs>
    80002dc0:	99be                	add	s3,s3,a5
    80002dc2:	7b38                	ld	a4,112(a4)
    80002dc4:	0609b603          	ld	a2,96(s3)
    80002dc8:	588c                	lw	a1,48(s1)
    80002dca:	00005517          	auipc	a0,0x5
    80002dce:	64e50513          	addi	a0,a0,1614 # 80008418 <states.1738+0x150>
    80002dd2:	ffffd097          	auipc	ra,0xffffd
    80002dd6:	7b6080e7          	jalr	1974(ra) # 80000588 <printf>
    80002dda:	a0c5                	j	80002eba <syscall+0x1f6>
        printf("%d: syscall %s (%d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a0);
    80002ddc:	6cb8                	ld	a4,88(s1)
    80002dde:	098e                	slli	s3,s3,0x3
    80002de0:	00006797          	auipc	a5,0x6
    80002de4:	c2878793          	addi	a5,a5,-984 # 80008a08 <nargs>
    80002de8:	99be                	add	s3,s3,a5
    80002dea:	7b3c                	ld	a5,112(a4)
    80002dec:	7f38                	ld	a4,120(a4)
    80002dee:	0609b603          	ld	a2,96(s3)
    80002df2:	588c                	lw	a1,48(s1)
    80002df4:	00005517          	auipc	a0,0x5
    80002df8:	64450513          	addi	a0,a0,1604 # 80008438 <states.1738+0x170>
    80002dfc:	ffffd097          	auipc	ra,0xffffd
    80002e00:	78c080e7          	jalr	1932(ra) # 80000588 <printf>
    80002e04:	a85d                	j	80002eba <syscall+0x1f6>
        printf("%d: syscall %s (%d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a0);
    80002e06:	6cb8                	ld	a4,88(s1)
    80002e08:	098e                	slli	s3,s3,0x3
    80002e0a:	00006797          	auipc	a5,0x6
    80002e0e:	bfe78793          	addi	a5,a5,-1026 # 80008a08 <nargs>
    80002e12:	99be                	add	s3,s3,a5
    80002e14:	07073803          	ld	a6,112(a4)
    80002e18:	635c                	ld	a5,128(a4)
    80002e1a:	7f38                	ld	a4,120(a4)
    80002e1c:	0609b603          	ld	a2,96(s3)
    80002e20:	588c                	lw	a1,48(s1)
    80002e22:	00005517          	auipc	a0,0x5
    80002e26:	63650513          	addi	a0,a0,1590 # 80008458 <states.1738+0x190>
    80002e2a:	ffffd097          	auipc	ra,0xffffd
    80002e2e:	75e080e7          	jalr	1886(ra) # 80000588 <printf>
    80002e32:	a061                	j	80002eba <syscall+0x1f6>
              printf("%d: syscall %s (%d %d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a3,p->trapframe->a0);
    80002e34:	6cb8                	ld	a4,88(s1)
    80002e36:	098e                	slli	s3,s3,0x3
    80002e38:	00006797          	auipc	a5,0x6
    80002e3c:	bd078793          	addi	a5,a5,-1072 # 80008a08 <nargs>
    80002e40:	99be                	add	s3,s3,a5
    80002e42:	07073883          	ld	a7,112(a4)
    80002e46:	08873803          	ld	a6,136(a4)
    80002e4a:	635c                	ld	a5,128(a4)
    80002e4c:	7f38                	ld	a4,120(a4)
    80002e4e:	0609b603          	ld	a2,96(s3)
    80002e52:	588c                	lw	a1,48(s1)
    80002e54:	00005517          	auipc	a0,0x5
    80002e58:	62c50513          	addi	a0,a0,1580 # 80008480 <states.1738+0x1b8>
    80002e5c:	ffffd097          	auipc	ra,0xffffd
    80002e60:	72c080e7          	jalr	1836(ra) # 80000588 <printf>
    80002e64:	a899                	j	80002eba <syscall+0x1f6>
              printf("%d: syscall %s (%d %d %d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a3,p->trapframe->a4,p->trapframe->a0);
    80002e66:	6cb0                	ld	a2,88(s1)
    80002e68:	09063883          	ld	a7,144(a2)
    80002e6c:	08863803          	ld	a6,136(a2)
    80002e70:	625c                	ld	a5,128(a2)
    80002e72:	7e38                	ld	a4,120(a2)
    80002e74:	098e                	slli	s3,s3,0x3
    80002e76:	00006597          	auipc	a1,0x6
    80002e7a:	b9258593          	addi	a1,a1,-1134 # 80008a08 <nargs>
    80002e7e:	99ae                	add	s3,s3,a1
    80002e80:	588c                	lw	a1,48(s1)
    80002e82:	7a30                	ld	a2,112(a2)
    80002e84:	e032                	sd	a2,0(sp)
    80002e86:	0609b603          	ld	a2,96(s3)
    80002e8a:	00005517          	auipc	a0,0x5
    80002e8e:	61e50513          	addi	a0,a0,1566 # 800084a8 <states.1738+0x1e0>
    80002e92:	ffffd097          	auipc	ra,0xffffd
    80002e96:	6f6080e7          	jalr	1782(ra) # 80000588 <printf>
    80002e9a:	a005                	j	80002eba <syscall+0x1f6>
      }
    }
    
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e9c:	86ce                	mv	a3,s3
    80002e9e:	15848613          	addi	a2,s1,344
    80002ea2:	588c                	lw	a1,48(s1)
    80002ea4:	00005517          	auipc	a0,0x5
    80002ea8:	65c50513          	addi	a0,a0,1628 # 80008500 <states.1738+0x238>
    80002eac:	ffffd097          	auipc	ra,0xffffd
    80002eb0:	6dc080e7          	jalr	1756(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002eb4:	6cbc                	ld	a5,88(s1)
    80002eb6:	577d                	li	a4,-1
    80002eb8:	fbb8                	sd	a4,112(a5)
  }
}
    80002eba:	70e2                	ld	ra,56(sp)
    80002ebc:	7442                	ld	s0,48(sp)
    80002ebe:	74a2                	ld	s1,40(sp)
    80002ec0:	7902                	ld	s2,32(sp)
    80002ec2:	69e2                	ld	s3,24(sp)
    80002ec4:	6a42                	ld	s4,16(sp)
    80002ec6:	6121                	addi	sp,sp,64
    80002ec8:	8082                	ret

0000000080002eca <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eca:	1101                	addi	sp,sp,-32
    80002ecc:	ec06                	sd	ra,24(sp)
    80002ece:	e822                	sd	s0,16(sp)
    80002ed0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ed2:	fec40593          	addi	a1,s0,-20
    80002ed6:	4501                	li	a0,0
    80002ed8:	00000097          	auipc	ra,0x0
    80002edc:	d78080e7          	jalr	-648(ra) # 80002c50 <argint>
    return -1;
    80002ee0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ee2:	00054963          	bltz	a0,80002ef4 <sys_exit+0x2a>
  exit(n);
    80002ee6:	fec42503          	lw	a0,-20(s0)
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	5b8080e7          	jalr	1464(ra) # 800024a2 <exit>
  return 0;  // not reached
    80002ef2:	4781                	li	a5,0
}
    80002ef4:	853e                	mv	a0,a5
    80002ef6:	60e2                	ld	ra,24(sp)
    80002ef8:	6442                	ld	s0,16(sp)
    80002efa:	6105                	addi	sp,sp,32
    80002efc:	8082                	ret

0000000080002efe <sys_getpid>:

uint64
sys_getpid(void)
{
    80002efe:	1141                	addi	sp,sp,-16
    80002f00:	e406                	sd	ra,8(sp)
    80002f02:	e022                	sd	s0,0(sp)
    80002f04:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	b08080e7          	jalr	-1272(ra) # 80001a0e <myproc>
}
    80002f0e:	5908                	lw	a0,48(a0)
    80002f10:	60a2                	ld	ra,8(sp)
    80002f12:	6402                	ld	s0,0(sp)
    80002f14:	0141                	addi	sp,sp,16
    80002f16:	8082                	ret

0000000080002f18 <sys_fork>:

uint64
sys_fork(void)
{
    80002f18:	1141                	addi	sp,sp,-16
    80002f1a:	e406                	sd	ra,8(sp)
    80002f1c:	e022                	sd	s0,0(sp)
    80002f1e:	0800                	addi	s0,sp,16
  return fork();
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	ed0080e7          	jalr	-304(ra) # 80001df0 <fork>
}
    80002f28:	60a2                	ld	ra,8(sp)
    80002f2a:	6402                	ld	s0,0(sp)
    80002f2c:	0141                	addi	sp,sp,16
    80002f2e:	8082                	ret

0000000080002f30 <sys_wait>:

uint64
sys_wait(void)
{
    80002f30:	1101                	addi	sp,sp,-32
    80002f32:	ec06                	sd	ra,24(sp)
    80002f34:	e822                	sd	s0,16(sp)
    80002f36:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f38:	fe840593          	addi	a1,s0,-24
    80002f3c:	4501                	li	a0,0
    80002f3e:	00000097          	auipc	ra,0x0
    80002f42:	d34080e7          	jalr	-716(ra) # 80002c72 <argaddr>
    80002f46:	87aa                	mv	a5,a0
    return -1;
    80002f48:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f4a:	0007c863          	bltz	a5,80002f5a <sys_wait+0x2a>
  return wait(p);
    80002f4e:	fe843503          	ld	a0,-24(s0)
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	20c080e7          	jalr	524(ra) # 8000215e <wait>
}
    80002f5a:	60e2                	ld	ra,24(sp)
    80002f5c:	6442                	ld	s0,16(sp)
    80002f5e:	6105                	addi	sp,sp,32
    80002f60:	8082                	ret

0000000080002f62 <sys_waitx>:

uint64
sys_waitx(void)
{
    80002f62:	7139                	addi	sp,sp,-64
    80002f64:	fc06                	sd	ra,56(sp)
    80002f66:	f822                	sd	s0,48(sp)
    80002f68:	f426                	sd	s1,40(sp)
    80002f6a:	f04a                	sd	s2,32(sp)
    80002f6c:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    80002f6e:	fd840593          	addi	a1,s0,-40
    80002f72:	4501                	li	a0,0
    80002f74:	00000097          	auipc	ra,0x0
    80002f78:	cfe080e7          	jalr	-770(ra) # 80002c72 <argaddr>
    return -1;
    80002f7c:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    80002f7e:	08054063          	bltz	a0,80002ffe <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002f82:	fd040593          	addi	a1,s0,-48
    80002f86:	4505                	li	a0,1
    80002f88:	00000097          	auipc	ra,0x0
    80002f8c:	cea080e7          	jalr	-790(ra) # 80002c72 <argaddr>
    return -1;
    80002f90:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002f92:	06054663          	bltz	a0,80002ffe <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80002f96:	fc840593          	addi	a1,s0,-56
    80002f9a:	4509                	li	a0,2
    80002f9c:	00000097          	auipc	ra,0x0
    80002fa0:	cd6080e7          	jalr	-810(ra) # 80002c72 <argaddr>
    return -1;
    80002fa4:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    80002fa6:	04054c63          	bltz	a0,80002ffe <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80002faa:	fc040613          	addi	a2,s0,-64
    80002fae:	fc440593          	addi	a1,s0,-60
    80002fb2:	fd843503          	ld	a0,-40(s0)
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	2d0080e7          	jalr	720(ra) # 80002286 <waitx>
    80002fbe:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80002fc0:	fffff097          	auipc	ra,0xfffff
    80002fc4:	a4e080e7          	jalr	-1458(ra) # 80001a0e <myproc>
    80002fc8:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002fca:	4691                	li	a3,4
    80002fcc:	fc440613          	addi	a2,s0,-60
    80002fd0:	fd043583          	ld	a1,-48(s0)
    80002fd4:	6928                	ld	a0,80(a0)
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	69c080e7          	jalr	1692(ra) # 80001672 <copyout>
    return -1;
    80002fde:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002fe0:	00054f63          	bltz	a0,80002ffe <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80002fe4:	4691                	li	a3,4
    80002fe6:	fc040613          	addi	a2,s0,-64
    80002fea:	fc843583          	ld	a1,-56(s0)
    80002fee:	68a8                	ld	a0,80(s1)
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	682080e7          	jalr	1666(ra) # 80001672 <copyout>
    80002ff8:	00054a63          	bltz	a0,8000300c <sys_waitx+0xaa>
    return -1;
  return ret;
    80002ffc:	87ca                	mv	a5,s2
}
    80002ffe:	853e                	mv	a0,a5
    80003000:	70e2                	ld	ra,56(sp)
    80003002:	7442                	ld	s0,48(sp)
    80003004:	74a2                	ld	s1,40(sp)
    80003006:	7902                	ld	s2,32(sp)
    80003008:	6121                	addi	sp,sp,64
    8000300a:	8082                	ret
    return -1;
    8000300c:	57fd                	li	a5,-1
    8000300e:	bfc5                	j	80002ffe <sys_waitx+0x9c>

0000000080003010 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003010:	7179                	addi	sp,sp,-48
    80003012:	f406                	sd	ra,40(sp)
    80003014:	f022                	sd	s0,32(sp)
    80003016:	ec26                	sd	s1,24(sp)
    80003018:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000301a:	fdc40593          	addi	a1,s0,-36
    8000301e:	4501                	li	a0,0
    80003020:	00000097          	auipc	ra,0x0
    80003024:	c30080e7          	jalr	-976(ra) # 80002c50 <argint>
    80003028:	87aa                	mv	a5,a0
    return -1;
    8000302a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000302c:	0207c063          	bltz	a5,8000304c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	9de080e7          	jalr	-1570(ra) # 80001a0e <myproc>
    80003038:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000303a:	fdc42503          	lw	a0,-36(s0)
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	d3e080e7          	jalr	-706(ra) # 80001d7c <growproc>
    80003046:	00054863          	bltz	a0,80003056 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000304a:	8526                	mv	a0,s1
}
    8000304c:	70a2                	ld	ra,40(sp)
    8000304e:	7402                	ld	s0,32(sp)
    80003050:	64e2                	ld	s1,24(sp)
    80003052:	6145                	addi	sp,sp,48
    80003054:	8082                	ret
    return -1;
    80003056:	557d                	li	a0,-1
    80003058:	bfd5                	j	8000304c <sys_sbrk+0x3c>

000000008000305a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000305a:	7139                	addi	sp,sp,-64
    8000305c:	fc06                	sd	ra,56(sp)
    8000305e:	f822                	sd	s0,48(sp)
    80003060:	f426                	sd	s1,40(sp)
    80003062:	f04a                	sd	s2,32(sp)
    80003064:	ec4e                	sd	s3,24(sp)
    80003066:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003068:	fcc40593          	addi	a1,s0,-52
    8000306c:	4501                	li	a0,0
    8000306e:	00000097          	auipc	ra,0x0
    80003072:	be2080e7          	jalr	-1054(ra) # 80002c50 <argint>
    return -1;
    80003076:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003078:	06054563          	bltz	a0,800030e2 <sys_sleep+0x88>
  acquire(&tickslock);
    8000307c:	00014517          	auipc	a0,0x14
    80003080:	45450513          	addi	a0,a0,1108 # 800174d0 <tickslock>
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	b60080e7          	jalr	-1184(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000308c:	00006917          	auipc	s2,0x6
    80003090:	fa492903          	lw	s2,-92(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003094:	fcc42783          	lw	a5,-52(s0)
    80003098:	cf85                	beqz	a5,800030d0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000309a:	00014997          	auipc	s3,0x14
    8000309e:	43698993          	addi	s3,s3,1078 # 800174d0 <tickslock>
    800030a2:	00006497          	auipc	s1,0x6
    800030a6:	f8e48493          	addi	s1,s1,-114 # 80009030 <ticks>
    if(myproc()->killed){
    800030aa:	fffff097          	auipc	ra,0xfffff
    800030ae:	964080e7          	jalr	-1692(ra) # 80001a0e <myproc>
    800030b2:	551c                	lw	a5,40(a0)
    800030b4:	ef9d                	bnez	a5,800030f2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800030b6:	85ce                	mv	a1,s3
    800030b8:	8526                	mv	a0,s1
    800030ba:	fffff097          	auipc	ra,0xfffff
    800030be:	040080e7          	jalr	64(ra) # 800020fa <sleep>
  while(ticks - ticks0 < n){
    800030c2:	409c                	lw	a5,0(s1)
    800030c4:	412787bb          	subw	a5,a5,s2
    800030c8:	fcc42703          	lw	a4,-52(s0)
    800030cc:	fce7efe3          	bltu	a5,a4,800030aa <sys_sleep+0x50>
  }
  release(&tickslock);
    800030d0:	00014517          	auipc	a0,0x14
    800030d4:	40050513          	addi	a0,a0,1024 # 800174d0 <tickslock>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	bc0080e7          	jalr	-1088(ra) # 80000c98 <release>
  return 0;
    800030e0:	4781                	li	a5,0
}
    800030e2:	853e                	mv	a0,a5
    800030e4:	70e2                	ld	ra,56(sp)
    800030e6:	7442                	ld	s0,48(sp)
    800030e8:	74a2                	ld	s1,40(sp)
    800030ea:	7902                	ld	s2,32(sp)
    800030ec:	69e2                	ld	s3,24(sp)
    800030ee:	6121                	addi	sp,sp,64
    800030f0:	8082                	ret
      release(&tickslock);
    800030f2:	00014517          	auipc	a0,0x14
    800030f6:	3de50513          	addi	a0,a0,990 # 800174d0 <tickslock>
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	b9e080e7          	jalr	-1122(ra) # 80000c98 <release>
      return -1;
    80003102:	57fd                	li	a5,-1
    80003104:	bff9                	j	800030e2 <sys_sleep+0x88>

0000000080003106 <sys_kill>:

uint64
sys_kill(void)
{
    80003106:	1101                	addi	sp,sp,-32
    80003108:	ec06                	sd	ra,24(sp)
    8000310a:	e822                	sd	s0,16(sp)
    8000310c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000310e:	fec40593          	addi	a1,s0,-20
    80003112:	4501                	li	a0,0
    80003114:	00000097          	auipc	ra,0x0
    80003118:	b3c080e7          	jalr	-1220(ra) # 80002c50 <argint>
    8000311c:	87aa                	mv	a5,a0
    return -1;
    8000311e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003120:	0007c863          	bltz	a5,80003130 <sys_kill+0x2a>
  return kill(pid);
    80003124:	fec42503          	lw	a0,-20(s0)
    80003128:	fffff097          	auipc	ra,0xfffff
    8000312c:	45c080e7          	jalr	1116(ra) # 80002584 <kill>
}
    80003130:	60e2                	ld	ra,24(sp)
    80003132:	6442                	ld	s0,16(sp)
    80003134:	6105                	addi	sp,sp,32
    80003136:	8082                	ret

0000000080003138 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003138:	1101                	addi	sp,sp,-32
    8000313a:	ec06                	sd	ra,24(sp)
    8000313c:	e822                	sd	s0,16(sp)
    8000313e:	e426                	sd	s1,8(sp)
    80003140:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003142:	00014517          	auipc	a0,0x14
    80003146:	38e50513          	addi	a0,a0,910 # 800174d0 <tickslock>
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	a9a080e7          	jalr	-1382(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003152:	00006497          	auipc	s1,0x6
    80003156:	ede4a483          	lw	s1,-290(s1) # 80009030 <ticks>
  release(&tickslock);
    8000315a:	00014517          	auipc	a0,0x14
    8000315e:	37650513          	addi	a0,a0,886 # 800174d0 <tickslock>
    80003162:	ffffe097          	auipc	ra,0xffffe
    80003166:	b36080e7          	jalr	-1226(ra) # 80000c98 <release>
  return xticks;
}
    8000316a:	02049513          	slli	a0,s1,0x20
    8000316e:	9101                	srli	a0,a0,0x20
    80003170:	60e2                	ld	ra,24(sp)
    80003172:	6442                	ld	s0,16(sp)
    80003174:	64a2                	ld	s1,8(sp)
    80003176:	6105                	addi	sp,sp,32
    80003178:	8082                	ret

000000008000317a <sys_trace>:

uint64
sys_trace(void)
{
    8000317a:	1101                	addi	sp,sp,-32
    8000317c:	ec06                	sd	ra,24(sp)
    8000317e:	e822                	sd	s0,16(sp)
    80003180:	1000                	addi	s0,sp,32
  int arg;
  if (argint(0,&arg)<0)
    80003182:	fec40593          	addi	a1,s0,-20
    80003186:	4501                	li	a0,0
    80003188:	00000097          	auipc	ra,0x0
    8000318c:	ac8080e7          	jalr	-1336(ra) # 80002c50 <argint>
  {
    return -1;
    80003190:	57fd                	li	a5,-1
  if (argint(0,&arg)<0)
    80003192:	00054b63          	bltz	a0,800031a8 <sys_trace+0x2e>
  }
  myproc()->tracy = arg;
    80003196:	fffff097          	auipc	ra,0xfffff
    8000319a:	878080e7          	jalr	-1928(ra) # 80001a0e <myproc>
    8000319e:	fec42783          	lw	a5,-20(s0)
    800031a2:	16f52423          	sw	a5,360(a0)
  return 0;
    800031a6:	4781                	li	a5,0
}
    800031a8:	853e                	mv	a0,a5
    800031aa:	60e2                	ld	ra,24(sp)
    800031ac:	6442                	ld	s0,16(sp)
    800031ae:	6105                	addi	sp,sp,32
    800031b0:	8082                	ret

00000000800031b2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031b2:	7179                	addi	sp,sp,-48
    800031b4:	f406                	sd	ra,40(sp)
    800031b6:	f022                	sd	s0,32(sp)
    800031b8:	ec26                	sd	s1,24(sp)
    800031ba:	e84a                	sd	s2,16(sp)
    800031bc:	e44e                	sd	s3,8(sp)
    800031be:	e052                	sd	s4,0(sp)
    800031c0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031c2:	00005597          	auipc	a1,0x5
    800031c6:	4e658593          	addi	a1,a1,1254 # 800086a8 <syscalls+0xc0>
    800031ca:	00014517          	auipc	a0,0x14
    800031ce:	31e50513          	addi	a0,a0,798 # 800174e8 <bcache>
    800031d2:	ffffe097          	auipc	ra,0xffffe
    800031d6:	982080e7          	jalr	-1662(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031da:	0001c797          	auipc	a5,0x1c
    800031de:	30e78793          	addi	a5,a5,782 # 8001f4e8 <bcache+0x8000>
    800031e2:	0001c717          	auipc	a4,0x1c
    800031e6:	56e70713          	addi	a4,a4,1390 # 8001f750 <bcache+0x8268>
    800031ea:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031ee:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031f2:	00014497          	auipc	s1,0x14
    800031f6:	30e48493          	addi	s1,s1,782 # 80017500 <bcache+0x18>
    b->next = bcache.head.next;
    800031fa:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031fc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031fe:	00005a17          	auipc	s4,0x5
    80003202:	4b2a0a13          	addi	s4,s4,1202 # 800086b0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003206:	2b893783          	ld	a5,696(s2)
    8000320a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000320c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003210:	85d2                	mv	a1,s4
    80003212:	01048513          	addi	a0,s1,16
    80003216:	00001097          	auipc	ra,0x1
    8000321a:	4bc080e7          	jalr	1212(ra) # 800046d2 <initsleeplock>
    bcache.head.next->prev = b;
    8000321e:	2b893783          	ld	a5,696(s2)
    80003222:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003224:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003228:	45848493          	addi	s1,s1,1112
    8000322c:	fd349de3          	bne	s1,s3,80003206 <binit+0x54>
  }
}
    80003230:	70a2                	ld	ra,40(sp)
    80003232:	7402                	ld	s0,32(sp)
    80003234:	64e2                	ld	s1,24(sp)
    80003236:	6942                	ld	s2,16(sp)
    80003238:	69a2                	ld	s3,8(sp)
    8000323a:	6a02                	ld	s4,0(sp)
    8000323c:	6145                	addi	sp,sp,48
    8000323e:	8082                	ret

0000000080003240 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003240:	7179                	addi	sp,sp,-48
    80003242:	f406                	sd	ra,40(sp)
    80003244:	f022                	sd	s0,32(sp)
    80003246:	ec26                	sd	s1,24(sp)
    80003248:	e84a                	sd	s2,16(sp)
    8000324a:	e44e                	sd	s3,8(sp)
    8000324c:	1800                	addi	s0,sp,48
    8000324e:	89aa                	mv	s3,a0
    80003250:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003252:	00014517          	auipc	a0,0x14
    80003256:	29650513          	addi	a0,a0,662 # 800174e8 <bcache>
    8000325a:	ffffe097          	auipc	ra,0xffffe
    8000325e:	98a080e7          	jalr	-1654(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003262:	0001c497          	auipc	s1,0x1c
    80003266:	53e4b483          	ld	s1,1342(s1) # 8001f7a0 <bcache+0x82b8>
    8000326a:	0001c797          	auipc	a5,0x1c
    8000326e:	4e678793          	addi	a5,a5,1254 # 8001f750 <bcache+0x8268>
    80003272:	02f48f63          	beq	s1,a5,800032b0 <bread+0x70>
    80003276:	873e                	mv	a4,a5
    80003278:	a021                	j	80003280 <bread+0x40>
    8000327a:	68a4                	ld	s1,80(s1)
    8000327c:	02e48a63          	beq	s1,a4,800032b0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003280:	449c                	lw	a5,8(s1)
    80003282:	ff379ce3          	bne	a5,s3,8000327a <bread+0x3a>
    80003286:	44dc                	lw	a5,12(s1)
    80003288:	ff2799e3          	bne	a5,s2,8000327a <bread+0x3a>
      b->refcnt++;
    8000328c:	40bc                	lw	a5,64(s1)
    8000328e:	2785                	addiw	a5,a5,1
    80003290:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003292:	00014517          	auipc	a0,0x14
    80003296:	25650513          	addi	a0,a0,598 # 800174e8 <bcache>
    8000329a:	ffffe097          	auipc	ra,0xffffe
    8000329e:	9fe080e7          	jalr	-1538(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800032a2:	01048513          	addi	a0,s1,16
    800032a6:	00001097          	auipc	ra,0x1
    800032aa:	466080e7          	jalr	1126(ra) # 8000470c <acquiresleep>
      return b;
    800032ae:	a8b9                	j	8000330c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032b0:	0001c497          	auipc	s1,0x1c
    800032b4:	4e84b483          	ld	s1,1256(s1) # 8001f798 <bcache+0x82b0>
    800032b8:	0001c797          	auipc	a5,0x1c
    800032bc:	49878793          	addi	a5,a5,1176 # 8001f750 <bcache+0x8268>
    800032c0:	00f48863          	beq	s1,a5,800032d0 <bread+0x90>
    800032c4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032c6:	40bc                	lw	a5,64(s1)
    800032c8:	cf81                	beqz	a5,800032e0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032ca:	64a4                	ld	s1,72(s1)
    800032cc:	fee49de3          	bne	s1,a4,800032c6 <bread+0x86>
  panic("bget: no buffers");
    800032d0:	00005517          	auipc	a0,0x5
    800032d4:	3e850513          	addi	a0,a0,1000 # 800086b8 <syscalls+0xd0>
    800032d8:	ffffd097          	auipc	ra,0xffffd
    800032dc:	266080e7          	jalr	614(ra) # 8000053e <panic>
      b->dev = dev;
    800032e0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800032e4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800032e8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032ec:	4785                	li	a5,1
    800032ee:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032f0:	00014517          	auipc	a0,0x14
    800032f4:	1f850513          	addi	a0,a0,504 # 800174e8 <bcache>
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	9a0080e7          	jalr	-1632(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003300:	01048513          	addi	a0,s1,16
    80003304:	00001097          	auipc	ra,0x1
    80003308:	408080e7          	jalr	1032(ra) # 8000470c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000330c:	409c                	lw	a5,0(s1)
    8000330e:	cb89                	beqz	a5,80003320 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003310:	8526                	mv	a0,s1
    80003312:	70a2                	ld	ra,40(sp)
    80003314:	7402                	ld	s0,32(sp)
    80003316:	64e2                	ld	s1,24(sp)
    80003318:	6942                	ld	s2,16(sp)
    8000331a:	69a2                	ld	s3,8(sp)
    8000331c:	6145                	addi	sp,sp,48
    8000331e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003320:	4581                	li	a1,0
    80003322:	8526                	mv	a0,s1
    80003324:	00003097          	auipc	ra,0x3
    80003328:	f12080e7          	jalr	-238(ra) # 80006236 <virtio_disk_rw>
    b->valid = 1;
    8000332c:	4785                	li	a5,1
    8000332e:	c09c                	sw	a5,0(s1)
  return b;
    80003330:	b7c5                	j	80003310 <bread+0xd0>

0000000080003332 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003332:	1101                	addi	sp,sp,-32
    80003334:	ec06                	sd	ra,24(sp)
    80003336:	e822                	sd	s0,16(sp)
    80003338:	e426                	sd	s1,8(sp)
    8000333a:	1000                	addi	s0,sp,32
    8000333c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000333e:	0541                	addi	a0,a0,16
    80003340:	00001097          	auipc	ra,0x1
    80003344:	466080e7          	jalr	1126(ra) # 800047a6 <holdingsleep>
    80003348:	cd01                	beqz	a0,80003360 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000334a:	4585                	li	a1,1
    8000334c:	8526                	mv	a0,s1
    8000334e:	00003097          	auipc	ra,0x3
    80003352:	ee8080e7          	jalr	-280(ra) # 80006236 <virtio_disk_rw>
}
    80003356:	60e2                	ld	ra,24(sp)
    80003358:	6442                	ld	s0,16(sp)
    8000335a:	64a2                	ld	s1,8(sp)
    8000335c:	6105                	addi	sp,sp,32
    8000335e:	8082                	ret
    panic("bwrite");
    80003360:	00005517          	auipc	a0,0x5
    80003364:	37050513          	addi	a0,a0,880 # 800086d0 <syscalls+0xe8>
    80003368:	ffffd097          	auipc	ra,0xffffd
    8000336c:	1d6080e7          	jalr	470(ra) # 8000053e <panic>

0000000080003370 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003370:	1101                	addi	sp,sp,-32
    80003372:	ec06                	sd	ra,24(sp)
    80003374:	e822                	sd	s0,16(sp)
    80003376:	e426                	sd	s1,8(sp)
    80003378:	e04a                	sd	s2,0(sp)
    8000337a:	1000                	addi	s0,sp,32
    8000337c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000337e:	01050913          	addi	s2,a0,16
    80003382:	854a                	mv	a0,s2
    80003384:	00001097          	auipc	ra,0x1
    80003388:	422080e7          	jalr	1058(ra) # 800047a6 <holdingsleep>
    8000338c:	c92d                	beqz	a0,800033fe <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000338e:	854a                	mv	a0,s2
    80003390:	00001097          	auipc	ra,0x1
    80003394:	3d2080e7          	jalr	978(ra) # 80004762 <releasesleep>

  acquire(&bcache.lock);
    80003398:	00014517          	auipc	a0,0x14
    8000339c:	15050513          	addi	a0,a0,336 # 800174e8 <bcache>
    800033a0:	ffffe097          	auipc	ra,0xffffe
    800033a4:	844080e7          	jalr	-1980(ra) # 80000be4 <acquire>
  b->refcnt--;
    800033a8:	40bc                	lw	a5,64(s1)
    800033aa:	37fd                	addiw	a5,a5,-1
    800033ac:	0007871b          	sext.w	a4,a5
    800033b0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033b2:	eb05                	bnez	a4,800033e2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033b4:	68bc                	ld	a5,80(s1)
    800033b6:	64b8                	ld	a4,72(s1)
    800033b8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800033ba:	64bc                	ld	a5,72(s1)
    800033bc:	68b8                	ld	a4,80(s1)
    800033be:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033c0:	0001c797          	auipc	a5,0x1c
    800033c4:	12878793          	addi	a5,a5,296 # 8001f4e8 <bcache+0x8000>
    800033c8:	2b87b703          	ld	a4,696(a5)
    800033cc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033ce:	0001c717          	auipc	a4,0x1c
    800033d2:	38270713          	addi	a4,a4,898 # 8001f750 <bcache+0x8268>
    800033d6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033d8:	2b87b703          	ld	a4,696(a5)
    800033dc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033de:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033e2:	00014517          	auipc	a0,0x14
    800033e6:	10650513          	addi	a0,a0,262 # 800174e8 <bcache>
    800033ea:	ffffe097          	auipc	ra,0xffffe
    800033ee:	8ae080e7          	jalr	-1874(ra) # 80000c98 <release>
}
    800033f2:	60e2                	ld	ra,24(sp)
    800033f4:	6442                	ld	s0,16(sp)
    800033f6:	64a2                	ld	s1,8(sp)
    800033f8:	6902                	ld	s2,0(sp)
    800033fa:	6105                	addi	sp,sp,32
    800033fc:	8082                	ret
    panic("brelse");
    800033fe:	00005517          	auipc	a0,0x5
    80003402:	2da50513          	addi	a0,a0,730 # 800086d8 <syscalls+0xf0>
    80003406:	ffffd097          	auipc	ra,0xffffd
    8000340a:	138080e7          	jalr	312(ra) # 8000053e <panic>

000000008000340e <bpin>:

void
bpin(struct buf *b) {
    8000340e:	1101                	addi	sp,sp,-32
    80003410:	ec06                	sd	ra,24(sp)
    80003412:	e822                	sd	s0,16(sp)
    80003414:	e426                	sd	s1,8(sp)
    80003416:	1000                	addi	s0,sp,32
    80003418:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000341a:	00014517          	auipc	a0,0x14
    8000341e:	0ce50513          	addi	a0,a0,206 # 800174e8 <bcache>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	7c2080e7          	jalr	1986(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000342a:	40bc                	lw	a5,64(s1)
    8000342c:	2785                	addiw	a5,a5,1
    8000342e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003430:	00014517          	auipc	a0,0x14
    80003434:	0b850513          	addi	a0,a0,184 # 800174e8 <bcache>
    80003438:	ffffe097          	auipc	ra,0xffffe
    8000343c:	860080e7          	jalr	-1952(ra) # 80000c98 <release>
}
    80003440:	60e2                	ld	ra,24(sp)
    80003442:	6442                	ld	s0,16(sp)
    80003444:	64a2                	ld	s1,8(sp)
    80003446:	6105                	addi	sp,sp,32
    80003448:	8082                	ret

000000008000344a <bunpin>:

void
bunpin(struct buf *b) {
    8000344a:	1101                	addi	sp,sp,-32
    8000344c:	ec06                	sd	ra,24(sp)
    8000344e:	e822                	sd	s0,16(sp)
    80003450:	e426                	sd	s1,8(sp)
    80003452:	1000                	addi	s0,sp,32
    80003454:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003456:	00014517          	auipc	a0,0x14
    8000345a:	09250513          	addi	a0,a0,146 # 800174e8 <bcache>
    8000345e:	ffffd097          	auipc	ra,0xffffd
    80003462:	786080e7          	jalr	1926(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003466:	40bc                	lw	a5,64(s1)
    80003468:	37fd                	addiw	a5,a5,-1
    8000346a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000346c:	00014517          	auipc	a0,0x14
    80003470:	07c50513          	addi	a0,a0,124 # 800174e8 <bcache>
    80003474:	ffffe097          	auipc	ra,0xffffe
    80003478:	824080e7          	jalr	-2012(ra) # 80000c98 <release>
}
    8000347c:	60e2                	ld	ra,24(sp)
    8000347e:	6442                	ld	s0,16(sp)
    80003480:	64a2                	ld	s1,8(sp)
    80003482:	6105                	addi	sp,sp,32
    80003484:	8082                	ret

0000000080003486 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003486:	1101                	addi	sp,sp,-32
    80003488:	ec06                	sd	ra,24(sp)
    8000348a:	e822                	sd	s0,16(sp)
    8000348c:	e426                	sd	s1,8(sp)
    8000348e:	e04a                	sd	s2,0(sp)
    80003490:	1000                	addi	s0,sp,32
    80003492:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003494:	00d5d59b          	srliw	a1,a1,0xd
    80003498:	0001c797          	auipc	a5,0x1c
    8000349c:	72c7a783          	lw	a5,1836(a5) # 8001fbc4 <sb+0x1c>
    800034a0:	9dbd                	addw	a1,a1,a5
    800034a2:	00000097          	auipc	ra,0x0
    800034a6:	d9e080e7          	jalr	-610(ra) # 80003240 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034aa:	0074f713          	andi	a4,s1,7
    800034ae:	4785                	li	a5,1
    800034b0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034b4:	14ce                	slli	s1,s1,0x33
    800034b6:	90d9                	srli	s1,s1,0x36
    800034b8:	00950733          	add	a4,a0,s1
    800034bc:	05874703          	lbu	a4,88(a4)
    800034c0:	00e7f6b3          	and	a3,a5,a4
    800034c4:	c69d                	beqz	a3,800034f2 <bfree+0x6c>
    800034c6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034c8:	94aa                	add	s1,s1,a0
    800034ca:	fff7c793          	not	a5,a5
    800034ce:	8ff9                	and	a5,a5,a4
    800034d0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800034d4:	00001097          	auipc	ra,0x1
    800034d8:	118080e7          	jalr	280(ra) # 800045ec <log_write>
  brelse(bp);
    800034dc:	854a                	mv	a0,s2
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	e92080e7          	jalr	-366(ra) # 80003370 <brelse>
}
    800034e6:	60e2                	ld	ra,24(sp)
    800034e8:	6442                	ld	s0,16(sp)
    800034ea:	64a2                	ld	s1,8(sp)
    800034ec:	6902                	ld	s2,0(sp)
    800034ee:	6105                	addi	sp,sp,32
    800034f0:	8082                	ret
    panic("freeing free block");
    800034f2:	00005517          	auipc	a0,0x5
    800034f6:	1ee50513          	addi	a0,a0,494 # 800086e0 <syscalls+0xf8>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	044080e7          	jalr	68(ra) # 8000053e <panic>

0000000080003502 <balloc>:
{
    80003502:	711d                	addi	sp,sp,-96
    80003504:	ec86                	sd	ra,88(sp)
    80003506:	e8a2                	sd	s0,80(sp)
    80003508:	e4a6                	sd	s1,72(sp)
    8000350a:	e0ca                	sd	s2,64(sp)
    8000350c:	fc4e                	sd	s3,56(sp)
    8000350e:	f852                	sd	s4,48(sp)
    80003510:	f456                	sd	s5,40(sp)
    80003512:	f05a                	sd	s6,32(sp)
    80003514:	ec5e                	sd	s7,24(sp)
    80003516:	e862                	sd	s8,16(sp)
    80003518:	e466                	sd	s9,8(sp)
    8000351a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000351c:	0001c797          	auipc	a5,0x1c
    80003520:	6907a783          	lw	a5,1680(a5) # 8001fbac <sb+0x4>
    80003524:	cbd1                	beqz	a5,800035b8 <balloc+0xb6>
    80003526:	8baa                	mv	s7,a0
    80003528:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000352a:	0001cb17          	auipc	s6,0x1c
    8000352e:	67eb0b13          	addi	s6,s6,1662 # 8001fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003532:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003534:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003536:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003538:	6c89                	lui	s9,0x2
    8000353a:	a831                	j	80003556 <balloc+0x54>
    brelse(bp);
    8000353c:	854a                	mv	a0,s2
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	e32080e7          	jalr	-462(ra) # 80003370 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003546:	015c87bb          	addw	a5,s9,s5
    8000354a:	00078a9b          	sext.w	s5,a5
    8000354e:	004b2703          	lw	a4,4(s6)
    80003552:	06eaf363          	bgeu	s5,a4,800035b8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003556:	41fad79b          	sraiw	a5,s5,0x1f
    8000355a:	0137d79b          	srliw	a5,a5,0x13
    8000355e:	015787bb          	addw	a5,a5,s5
    80003562:	40d7d79b          	sraiw	a5,a5,0xd
    80003566:	01cb2583          	lw	a1,28(s6)
    8000356a:	9dbd                	addw	a1,a1,a5
    8000356c:	855e                	mv	a0,s7
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	cd2080e7          	jalr	-814(ra) # 80003240 <bread>
    80003576:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003578:	004b2503          	lw	a0,4(s6)
    8000357c:	000a849b          	sext.w	s1,s5
    80003580:	8662                	mv	a2,s8
    80003582:	faa4fde3          	bgeu	s1,a0,8000353c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003586:	41f6579b          	sraiw	a5,a2,0x1f
    8000358a:	01d7d69b          	srliw	a3,a5,0x1d
    8000358e:	00c6873b          	addw	a4,a3,a2
    80003592:	00777793          	andi	a5,a4,7
    80003596:	9f95                	subw	a5,a5,a3
    80003598:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000359c:	4037571b          	sraiw	a4,a4,0x3
    800035a0:	00e906b3          	add	a3,s2,a4
    800035a4:	0586c683          	lbu	a3,88(a3)
    800035a8:	00d7f5b3          	and	a1,a5,a3
    800035ac:	cd91                	beqz	a1,800035c8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035ae:	2605                	addiw	a2,a2,1
    800035b0:	2485                	addiw	s1,s1,1
    800035b2:	fd4618e3          	bne	a2,s4,80003582 <balloc+0x80>
    800035b6:	b759                	j	8000353c <balloc+0x3a>
  panic("balloc: out of blocks");
    800035b8:	00005517          	auipc	a0,0x5
    800035bc:	14050513          	addi	a0,a0,320 # 800086f8 <syscalls+0x110>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	f7e080e7          	jalr	-130(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035c8:	974a                	add	a4,a4,s2
    800035ca:	8fd5                	or	a5,a5,a3
    800035cc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800035d0:	854a                	mv	a0,s2
    800035d2:	00001097          	auipc	ra,0x1
    800035d6:	01a080e7          	jalr	26(ra) # 800045ec <log_write>
        brelse(bp);
    800035da:	854a                	mv	a0,s2
    800035dc:	00000097          	auipc	ra,0x0
    800035e0:	d94080e7          	jalr	-620(ra) # 80003370 <brelse>
  bp = bread(dev, bno);
    800035e4:	85a6                	mv	a1,s1
    800035e6:	855e                	mv	a0,s7
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	c58080e7          	jalr	-936(ra) # 80003240 <bread>
    800035f0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035f2:	40000613          	li	a2,1024
    800035f6:	4581                	li	a1,0
    800035f8:	05850513          	addi	a0,a0,88
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	6e4080e7          	jalr	1764(ra) # 80000ce0 <memset>
  log_write(bp);
    80003604:	854a                	mv	a0,s2
    80003606:	00001097          	auipc	ra,0x1
    8000360a:	fe6080e7          	jalr	-26(ra) # 800045ec <log_write>
  brelse(bp);
    8000360e:	854a                	mv	a0,s2
    80003610:	00000097          	auipc	ra,0x0
    80003614:	d60080e7          	jalr	-672(ra) # 80003370 <brelse>
}
    80003618:	8526                	mv	a0,s1
    8000361a:	60e6                	ld	ra,88(sp)
    8000361c:	6446                	ld	s0,80(sp)
    8000361e:	64a6                	ld	s1,72(sp)
    80003620:	6906                	ld	s2,64(sp)
    80003622:	79e2                	ld	s3,56(sp)
    80003624:	7a42                	ld	s4,48(sp)
    80003626:	7aa2                	ld	s5,40(sp)
    80003628:	7b02                	ld	s6,32(sp)
    8000362a:	6be2                	ld	s7,24(sp)
    8000362c:	6c42                	ld	s8,16(sp)
    8000362e:	6ca2                	ld	s9,8(sp)
    80003630:	6125                	addi	sp,sp,96
    80003632:	8082                	ret

0000000080003634 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003634:	7179                	addi	sp,sp,-48
    80003636:	f406                	sd	ra,40(sp)
    80003638:	f022                	sd	s0,32(sp)
    8000363a:	ec26                	sd	s1,24(sp)
    8000363c:	e84a                	sd	s2,16(sp)
    8000363e:	e44e                	sd	s3,8(sp)
    80003640:	e052                	sd	s4,0(sp)
    80003642:	1800                	addi	s0,sp,48
    80003644:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003646:	47ad                	li	a5,11
    80003648:	04b7fe63          	bgeu	a5,a1,800036a4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000364c:	ff45849b          	addiw	s1,a1,-12
    80003650:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003654:	0ff00793          	li	a5,255
    80003658:	0ae7e363          	bltu	a5,a4,800036fe <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000365c:	08052583          	lw	a1,128(a0)
    80003660:	c5ad                	beqz	a1,800036ca <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003662:	00092503          	lw	a0,0(s2)
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	bda080e7          	jalr	-1062(ra) # 80003240 <bread>
    8000366e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003670:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003674:	02049593          	slli	a1,s1,0x20
    80003678:	9181                	srli	a1,a1,0x20
    8000367a:	058a                	slli	a1,a1,0x2
    8000367c:	00b784b3          	add	s1,a5,a1
    80003680:	0004a983          	lw	s3,0(s1)
    80003684:	04098d63          	beqz	s3,800036de <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003688:	8552                	mv	a0,s4
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	ce6080e7          	jalr	-794(ra) # 80003370 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003692:	854e                	mv	a0,s3
    80003694:	70a2                	ld	ra,40(sp)
    80003696:	7402                	ld	s0,32(sp)
    80003698:	64e2                	ld	s1,24(sp)
    8000369a:	6942                	ld	s2,16(sp)
    8000369c:	69a2                	ld	s3,8(sp)
    8000369e:	6a02                	ld	s4,0(sp)
    800036a0:	6145                	addi	sp,sp,48
    800036a2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800036a4:	02059493          	slli	s1,a1,0x20
    800036a8:	9081                	srli	s1,s1,0x20
    800036aa:	048a                	slli	s1,s1,0x2
    800036ac:	94aa                	add	s1,s1,a0
    800036ae:	0504a983          	lw	s3,80(s1)
    800036b2:	fe0990e3          	bnez	s3,80003692 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800036b6:	4108                	lw	a0,0(a0)
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	e4a080e7          	jalr	-438(ra) # 80003502 <balloc>
    800036c0:	0005099b          	sext.w	s3,a0
    800036c4:	0534a823          	sw	s3,80(s1)
    800036c8:	b7e9                	j	80003692 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800036ca:	4108                	lw	a0,0(a0)
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	e36080e7          	jalr	-458(ra) # 80003502 <balloc>
    800036d4:	0005059b          	sext.w	a1,a0
    800036d8:	08b92023          	sw	a1,128(s2)
    800036dc:	b759                	j	80003662 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800036de:	00092503          	lw	a0,0(s2)
    800036e2:	00000097          	auipc	ra,0x0
    800036e6:	e20080e7          	jalr	-480(ra) # 80003502 <balloc>
    800036ea:	0005099b          	sext.w	s3,a0
    800036ee:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800036f2:	8552                	mv	a0,s4
    800036f4:	00001097          	auipc	ra,0x1
    800036f8:	ef8080e7          	jalr	-264(ra) # 800045ec <log_write>
    800036fc:	b771                	j	80003688 <bmap+0x54>
  panic("bmap: out of range");
    800036fe:	00005517          	auipc	a0,0x5
    80003702:	01250513          	addi	a0,a0,18 # 80008710 <syscalls+0x128>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	e38080e7          	jalr	-456(ra) # 8000053e <panic>

000000008000370e <iget>:
{
    8000370e:	7179                	addi	sp,sp,-48
    80003710:	f406                	sd	ra,40(sp)
    80003712:	f022                	sd	s0,32(sp)
    80003714:	ec26                	sd	s1,24(sp)
    80003716:	e84a                	sd	s2,16(sp)
    80003718:	e44e                	sd	s3,8(sp)
    8000371a:	e052                	sd	s4,0(sp)
    8000371c:	1800                	addi	s0,sp,48
    8000371e:	89aa                	mv	s3,a0
    80003720:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003722:	0001c517          	auipc	a0,0x1c
    80003726:	4a650513          	addi	a0,a0,1190 # 8001fbc8 <itable>
    8000372a:	ffffd097          	auipc	ra,0xffffd
    8000372e:	4ba080e7          	jalr	1210(ra) # 80000be4 <acquire>
  empty = 0;
    80003732:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003734:	0001c497          	auipc	s1,0x1c
    80003738:	4ac48493          	addi	s1,s1,1196 # 8001fbe0 <itable+0x18>
    8000373c:	0001e697          	auipc	a3,0x1e
    80003740:	f3468693          	addi	a3,a3,-204 # 80021670 <log>
    80003744:	a039                	j	80003752 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003746:	02090b63          	beqz	s2,8000377c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000374a:	08848493          	addi	s1,s1,136
    8000374e:	02d48a63          	beq	s1,a3,80003782 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003752:	449c                	lw	a5,8(s1)
    80003754:	fef059e3          	blez	a5,80003746 <iget+0x38>
    80003758:	4098                	lw	a4,0(s1)
    8000375a:	ff3716e3          	bne	a4,s3,80003746 <iget+0x38>
    8000375e:	40d8                	lw	a4,4(s1)
    80003760:	ff4713e3          	bne	a4,s4,80003746 <iget+0x38>
      ip->ref++;
    80003764:	2785                	addiw	a5,a5,1
    80003766:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003768:	0001c517          	auipc	a0,0x1c
    8000376c:	46050513          	addi	a0,a0,1120 # 8001fbc8 <itable>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	528080e7          	jalr	1320(ra) # 80000c98 <release>
      return ip;
    80003778:	8926                	mv	s2,s1
    8000377a:	a03d                	j	800037a8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000377c:	f7f9                	bnez	a5,8000374a <iget+0x3c>
    8000377e:	8926                	mv	s2,s1
    80003780:	b7e9                	j	8000374a <iget+0x3c>
  if(empty == 0)
    80003782:	02090c63          	beqz	s2,800037ba <iget+0xac>
  ip->dev = dev;
    80003786:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000378a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000378e:	4785                	li	a5,1
    80003790:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003794:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003798:	0001c517          	auipc	a0,0x1c
    8000379c:	43050513          	addi	a0,a0,1072 # 8001fbc8 <itable>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	4f8080e7          	jalr	1272(ra) # 80000c98 <release>
}
    800037a8:	854a                	mv	a0,s2
    800037aa:	70a2                	ld	ra,40(sp)
    800037ac:	7402                	ld	s0,32(sp)
    800037ae:	64e2                	ld	s1,24(sp)
    800037b0:	6942                	ld	s2,16(sp)
    800037b2:	69a2                	ld	s3,8(sp)
    800037b4:	6a02                	ld	s4,0(sp)
    800037b6:	6145                	addi	sp,sp,48
    800037b8:	8082                	ret
    panic("iget: no inodes");
    800037ba:	00005517          	auipc	a0,0x5
    800037be:	f6e50513          	addi	a0,a0,-146 # 80008728 <syscalls+0x140>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	d7c080e7          	jalr	-644(ra) # 8000053e <panic>

00000000800037ca <fsinit>:
fsinit(int dev) {
    800037ca:	7179                	addi	sp,sp,-48
    800037cc:	f406                	sd	ra,40(sp)
    800037ce:	f022                	sd	s0,32(sp)
    800037d0:	ec26                	sd	s1,24(sp)
    800037d2:	e84a                	sd	s2,16(sp)
    800037d4:	e44e                	sd	s3,8(sp)
    800037d6:	1800                	addi	s0,sp,48
    800037d8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037da:	4585                	li	a1,1
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	a64080e7          	jalr	-1436(ra) # 80003240 <bread>
    800037e4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037e6:	0001c997          	auipc	s3,0x1c
    800037ea:	3c298993          	addi	s3,s3,962 # 8001fba8 <sb>
    800037ee:	02000613          	li	a2,32
    800037f2:	05850593          	addi	a1,a0,88
    800037f6:	854e                	mv	a0,s3
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	548080e7          	jalr	1352(ra) # 80000d40 <memmove>
  brelse(bp);
    80003800:	8526                	mv	a0,s1
    80003802:	00000097          	auipc	ra,0x0
    80003806:	b6e080e7          	jalr	-1170(ra) # 80003370 <brelse>
  if(sb.magic != FSMAGIC)
    8000380a:	0009a703          	lw	a4,0(s3)
    8000380e:	102037b7          	lui	a5,0x10203
    80003812:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003816:	02f71263          	bne	a4,a5,8000383a <fsinit+0x70>
  initlog(dev, &sb);
    8000381a:	0001c597          	auipc	a1,0x1c
    8000381e:	38e58593          	addi	a1,a1,910 # 8001fba8 <sb>
    80003822:	854a                	mv	a0,s2
    80003824:	00001097          	auipc	ra,0x1
    80003828:	b4c080e7          	jalr	-1204(ra) # 80004370 <initlog>
}
    8000382c:	70a2                	ld	ra,40(sp)
    8000382e:	7402                	ld	s0,32(sp)
    80003830:	64e2                	ld	s1,24(sp)
    80003832:	6942                	ld	s2,16(sp)
    80003834:	69a2                	ld	s3,8(sp)
    80003836:	6145                	addi	sp,sp,48
    80003838:	8082                	ret
    panic("invalid file system");
    8000383a:	00005517          	auipc	a0,0x5
    8000383e:	efe50513          	addi	a0,a0,-258 # 80008738 <syscalls+0x150>
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	cfc080e7          	jalr	-772(ra) # 8000053e <panic>

000000008000384a <iinit>:
{
    8000384a:	7179                	addi	sp,sp,-48
    8000384c:	f406                	sd	ra,40(sp)
    8000384e:	f022                	sd	s0,32(sp)
    80003850:	ec26                	sd	s1,24(sp)
    80003852:	e84a                	sd	s2,16(sp)
    80003854:	e44e                	sd	s3,8(sp)
    80003856:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003858:	00005597          	auipc	a1,0x5
    8000385c:	ef858593          	addi	a1,a1,-264 # 80008750 <syscalls+0x168>
    80003860:	0001c517          	auipc	a0,0x1c
    80003864:	36850513          	addi	a0,a0,872 # 8001fbc8 <itable>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	2ec080e7          	jalr	748(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003870:	0001c497          	auipc	s1,0x1c
    80003874:	38048493          	addi	s1,s1,896 # 8001fbf0 <itable+0x28>
    80003878:	0001e997          	auipc	s3,0x1e
    8000387c:	e0898993          	addi	s3,s3,-504 # 80021680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003880:	00005917          	auipc	s2,0x5
    80003884:	ed890913          	addi	s2,s2,-296 # 80008758 <syscalls+0x170>
    80003888:	85ca                	mv	a1,s2
    8000388a:	8526                	mv	a0,s1
    8000388c:	00001097          	auipc	ra,0x1
    80003890:	e46080e7          	jalr	-442(ra) # 800046d2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003894:	08848493          	addi	s1,s1,136
    80003898:	ff3498e3          	bne	s1,s3,80003888 <iinit+0x3e>
}
    8000389c:	70a2                	ld	ra,40(sp)
    8000389e:	7402                	ld	s0,32(sp)
    800038a0:	64e2                	ld	s1,24(sp)
    800038a2:	6942                	ld	s2,16(sp)
    800038a4:	69a2                	ld	s3,8(sp)
    800038a6:	6145                	addi	sp,sp,48
    800038a8:	8082                	ret

00000000800038aa <ialloc>:
{
    800038aa:	715d                	addi	sp,sp,-80
    800038ac:	e486                	sd	ra,72(sp)
    800038ae:	e0a2                	sd	s0,64(sp)
    800038b0:	fc26                	sd	s1,56(sp)
    800038b2:	f84a                	sd	s2,48(sp)
    800038b4:	f44e                	sd	s3,40(sp)
    800038b6:	f052                	sd	s4,32(sp)
    800038b8:	ec56                	sd	s5,24(sp)
    800038ba:	e85a                	sd	s6,16(sp)
    800038bc:	e45e                	sd	s7,8(sp)
    800038be:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800038c0:	0001c717          	auipc	a4,0x1c
    800038c4:	2f472703          	lw	a4,756(a4) # 8001fbb4 <sb+0xc>
    800038c8:	4785                	li	a5,1
    800038ca:	04e7fa63          	bgeu	a5,a4,8000391e <ialloc+0x74>
    800038ce:	8aaa                	mv	s5,a0
    800038d0:	8bae                	mv	s7,a1
    800038d2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038d4:	0001ca17          	auipc	s4,0x1c
    800038d8:	2d4a0a13          	addi	s4,s4,724 # 8001fba8 <sb>
    800038dc:	00048b1b          	sext.w	s6,s1
    800038e0:	0044d593          	srli	a1,s1,0x4
    800038e4:	018a2783          	lw	a5,24(s4)
    800038e8:	9dbd                	addw	a1,a1,a5
    800038ea:	8556                	mv	a0,s5
    800038ec:	00000097          	auipc	ra,0x0
    800038f0:	954080e7          	jalr	-1708(ra) # 80003240 <bread>
    800038f4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038f6:	05850993          	addi	s3,a0,88
    800038fa:	00f4f793          	andi	a5,s1,15
    800038fe:	079a                	slli	a5,a5,0x6
    80003900:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003902:	00099783          	lh	a5,0(s3)
    80003906:	c785                	beqz	a5,8000392e <ialloc+0x84>
    brelse(bp);
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	a68080e7          	jalr	-1432(ra) # 80003370 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003910:	0485                	addi	s1,s1,1
    80003912:	00ca2703          	lw	a4,12(s4)
    80003916:	0004879b          	sext.w	a5,s1
    8000391a:	fce7e1e3          	bltu	a5,a4,800038dc <ialloc+0x32>
  panic("ialloc: no inodes");
    8000391e:	00005517          	auipc	a0,0x5
    80003922:	e4250513          	addi	a0,a0,-446 # 80008760 <syscalls+0x178>
    80003926:	ffffd097          	auipc	ra,0xffffd
    8000392a:	c18080e7          	jalr	-1000(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000392e:	04000613          	li	a2,64
    80003932:	4581                	li	a1,0
    80003934:	854e                	mv	a0,s3
    80003936:	ffffd097          	auipc	ra,0xffffd
    8000393a:	3aa080e7          	jalr	938(ra) # 80000ce0 <memset>
      dip->type = type;
    8000393e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003942:	854a                	mv	a0,s2
    80003944:	00001097          	auipc	ra,0x1
    80003948:	ca8080e7          	jalr	-856(ra) # 800045ec <log_write>
      brelse(bp);
    8000394c:	854a                	mv	a0,s2
    8000394e:	00000097          	auipc	ra,0x0
    80003952:	a22080e7          	jalr	-1502(ra) # 80003370 <brelse>
      return iget(dev, inum);
    80003956:	85da                	mv	a1,s6
    80003958:	8556                	mv	a0,s5
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	db4080e7          	jalr	-588(ra) # 8000370e <iget>
}
    80003962:	60a6                	ld	ra,72(sp)
    80003964:	6406                	ld	s0,64(sp)
    80003966:	74e2                	ld	s1,56(sp)
    80003968:	7942                	ld	s2,48(sp)
    8000396a:	79a2                	ld	s3,40(sp)
    8000396c:	7a02                	ld	s4,32(sp)
    8000396e:	6ae2                	ld	s5,24(sp)
    80003970:	6b42                	ld	s6,16(sp)
    80003972:	6ba2                	ld	s7,8(sp)
    80003974:	6161                	addi	sp,sp,80
    80003976:	8082                	ret

0000000080003978 <iupdate>:
{
    80003978:	1101                	addi	sp,sp,-32
    8000397a:	ec06                	sd	ra,24(sp)
    8000397c:	e822                	sd	s0,16(sp)
    8000397e:	e426                	sd	s1,8(sp)
    80003980:	e04a                	sd	s2,0(sp)
    80003982:	1000                	addi	s0,sp,32
    80003984:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003986:	415c                	lw	a5,4(a0)
    80003988:	0047d79b          	srliw	a5,a5,0x4
    8000398c:	0001c597          	auipc	a1,0x1c
    80003990:	2345a583          	lw	a1,564(a1) # 8001fbc0 <sb+0x18>
    80003994:	9dbd                	addw	a1,a1,a5
    80003996:	4108                	lw	a0,0(a0)
    80003998:	00000097          	auipc	ra,0x0
    8000399c:	8a8080e7          	jalr	-1880(ra) # 80003240 <bread>
    800039a0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039a2:	05850793          	addi	a5,a0,88
    800039a6:	40c8                	lw	a0,4(s1)
    800039a8:	893d                	andi	a0,a0,15
    800039aa:	051a                	slli	a0,a0,0x6
    800039ac:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800039ae:	04449703          	lh	a4,68(s1)
    800039b2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800039b6:	04649703          	lh	a4,70(s1)
    800039ba:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800039be:	04849703          	lh	a4,72(s1)
    800039c2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800039c6:	04a49703          	lh	a4,74(s1)
    800039ca:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800039ce:	44f8                	lw	a4,76(s1)
    800039d0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039d2:	03400613          	li	a2,52
    800039d6:	05048593          	addi	a1,s1,80
    800039da:	0531                	addi	a0,a0,12
    800039dc:	ffffd097          	auipc	ra,0xffffd
    800039e0:	364080e7          	jalr	868(ra) # 80000d40 <memmove>
  log_write(bp);
    800039e4:	854a                	mv	a0,s2
    800039e6:	00001097          	auipc	ra,0x1
    800039ea:	c06080e7          	jalr	-1018(ra) # 800045ec <log_write>
  brelse(bp);
    800039ee:	854a                	mv	a0,s2
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	980080e7          	jalr	-1664(ra) # 80003370 <brelse>
}
    800039f8:	60e2                	ld	ra,24(sp)
    800039fa:	6442                	ld	s0,16(sp)
    800039fc:	64a2                	ld	s1,8(sp)
    800039fe:	6902                	ld	s2,0(sp)
    80003a00:	6105                	addi	sp,sp,32
    80003a02:	8082                	ret

0000000080003a04 <idup>:
{
    80003a04:	1101                	addi	sp,sp,-32
    80003a06:	ec06                	sd	ra,24(sp)
    80003a08:	e822                	sd	s0,16(sp)
    80003a0a:	e426                	sd	s1,8(sp)
    80003a0c:	1000                	addi	s0,sp,32
    80003a0e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a10:	0001c517          	auipc	a0,0x1c
    80003a14:	1b850513          	addi	a0,a0,440 # 8001fbc8 <itable>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	1cc080e7          	jalr	460(ra) # 80000be4 <acquire>
  ip->ref++;
    80003a20:	449c                	lw	a5,8(s1)
    80003a22:	2785                	addiw	a5,a5,1
    80003a24:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a26:	0001c517          	auipc	a0,0x1c
    80003a2a:	1a250513          	addi	a0,a0,418 # 8001fbc8 <itable>
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	26a080e7          	jalr	618(ra) # 80000c98 <release>
}
    80003a36:	8526                	mv	a0,s1
    80003a38:	60e2                	ld	ra,24(sp)
    80003a3a:	6442                	ld	s0,16(sp)
    80003a3c:	64a2                	ld	s1,8(sp)
    80003a3e:	6105                	addi	sp,sp,32
    80003a40:	8082                	ret

0000000080003a42 <ilock>:
{
    80003a42:	1101                	addi	sp,sp,-32
    80003a44:	ec06                	sd	ra,24(sp)
    80003a46:	e822                	sd	s0,16(sp)
    80003a48:	e426                	sd	s1,8(sp)
    80003a4a:	e04a                	sd	s2,0(sp)
    80003a4c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a4e:	c115                	beqz	a0,80003a72 <ilock+0x30>
    80003a50:	84aa                	mv	s1,a0
    80003a52:	451c                	lw	a5,8(a0)
    80003a54:	00f05f63          	blez	a5,80003a72 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a58:	0541                	addi	a0,a0,16
    80003a5a:	00001097          	auipc	ra,0x1
    80003a5e:	cb2080e7          	jalr	-846(ra) # 8000470c <acquiresleep>
  if(ip->valid == 0){
    80003a62:	40bc                	lw	a5,64(s1)
    80003a64:	cf99                	beqz	a5,80003a82 <ilock+0x40>
}
    80003a66:	60e2                	ld	ra,24(sp)
    80003a68:	6442                	ld	s0,16(sp)
    80003a6a:	64a2                	ld	s1,8(sp)
    80003a6c:	6902                	ld	s2,0(sp)
    80003a6e:	6105                	addi	sp,sp,32
    80003a70:	8082                	ret
    panic("ilock");
    80003a72:	00005517          	auipc	a0,0x5
    80003a76:	d0650513          	addi	a0,a0,-762 # 80008778 <syscalls+0x190>
    80003a7a:	ffffd097          	auipc	ra,0xffffd
    80003a7e:	ac4080e7          	jalr	-1340(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a82:	40dc                	lw	a5,4(s1)
    80003a84:	0047d79b          	srliw	a5,a5,0x4
    80003a88:	0001c597          	auipc	a1,0x1c
    80003a8c:	1385a583          	lw	a1,312(a1) # 8001fbc0 <sb+0x18>
    80003a90:	9dbd                	addw	a1,a1,a5
    80003a92:	4088                	lw	a0,0(s1)
    80003a94:	fffff097          	auipc	ra,0xfffff
    80003a98:	7ac080e7          	jalr	1964(ra) # 80003240 <bread>
    80003a9c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a9e:	05850593          	addi	a1,a0,88
    80003aa2:	40dc                	lw	a5,4(s1)
    80003aa4:	8bbd                	andi	a5,a5,15
    80003aa6:	079a                	slli	a5,a5,0x6
    80003aa8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003aaa:	00059783          	lh	a5,0(a1)
    80003aae:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ab2:	00259783          	lh	a5,2(a1)
    80003ab6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003aba:	00459783          	lh	a5,4(a1)
    80003abe:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ac2:	00659783          	lh	a5,6(a1)
    80003ac6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003aca:	459c                	lw	a5,8(a1)
    80003acc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ace:	03400613          	li	a2,52
    80003ad2:	05b1                	addi	a1,a1,12
    80003ad4:	05048513          	addi	a0,s1,80
    80003ad8:	ffffd097          	auipc	ra,0xffffd
    80003adc:	268080e7          	jalr	616(ra) # 80000d40 <memmove>
    brelse(bp);
    80003ae0:	854a                	mv	a0,s2
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	88e080e7          	jalr	-1906(ra) # 80003370 <brelse>
    ip->valid = 1;
    80003aea:	4785                	li	a5,1
    80003aec:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003aee:	04449783          	lh	a5,68(s1)
    80003af2:	fbb5                	bnez	a5,80003a66 <ilock+0x24>
      panic("ilock: no type");
    80003af4:	00005517          	auipc	a0,0x5
    80003af8:	c8c50513          	addi	a0,a0,-884 # 80008780 <syscalls+0x198>
    80003afc:	ffffd097          	auipc	ra,0xffffd
    80003b00:	a42080e7          	jalr	-1470(ra) # 8000053e <panic>

0000000080003b04 <iunlock>:
{
    80003b04:	1101                	addi	sp,sp,-32
    80003b06:	ec06                	sd	ra,24(sp)
    80003b08:	e822                	sd	s0,16(sp)
    80003b0a:	e426                	sd	s1,8(sp)
    80003b0c:	e04a                	sd	s2,0(sp)
    80003b0e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b10:	c905                	beqz	a0,80003b40 <iunlock+0x3c>
    80003b12:	84aa                	mv	s1,a0
    80003b14:	01050913          	addi	s2,a0,16
    80003b18:	854a                	mv	a0,s2
    80003b1a:	00001097          	auipc	ra,0x1
    80003b1e:	c8c080e7          	jalr	-884(ra) # 800047a6 <holdingsleep>
    80003b22:	cd19                	beqz	a0,80003b40 <iunlock+0x3c>
    80003b24:	449c                	lw	a5,8(s1)
    80003b26:	00f05d63          	blez	a5,80003b40 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	00001097          	auipc	ra,0x1
    80003b30:	c36080e7          	jalr	-970(ra) # 80004762 <releasesleep>
}
    80003b34:	60e2                	ld	ra,24(sp)
    80003b36:	6442                	ld	s0,16(sp)
    80003b38:	64a2                	ld	s1,8(sp)
    80003b3a:	6902                	ld	s2,0(sp)
    80003b3c:	6105                	addi	sp,sp,32
    80003b3e:	8082                	ret
    panic("iunlock");
    80003b40:	00005517          	auipc	a0,0x5
    80003b44:	c5050513          	addi	a0,a0,-944 # 80008790 <syscalls+0x1a8>
    80003b48:	ffffd097          	auipc	ra,0xffffd
    80003b4c:	9f6080e7          	jalr	-1546(ra) # 8000053e <panic>

0000000080003b50 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b50:	7179                	addi	sp,sp,-48
    80003b52:	f406                	sd	ra,40(sp)
    80003b54:	f022                	sd	s0,32(sp)
    80003b56:	ec26                	sd	s1,24(sp)
    80003b58:	e84a                	sd	s2,16(sp)
    80003b5a:	e44e                	sd	s3,8(sp)
    80003b5c:	e052                	sd	s4,0(sp)
    80003b5e:	1800                	addi	s0,sp,48
    80003b60:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b62:	05050493          	addi	s1,a0,80
    80003b66:	08050913          	addi	s2,a0,128
    80003b6a:	a021                	j	80003b72 <itrunc+0x22>
    80003b6c:	0491                	addi	s1,s1,4
    80003b6e:	01248d63          	beq	s1,s2,80003b88 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b72:	408c                	lw	a1,0(s1)
    80003b74:	dde5                	beqz	a1,80003b6c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b76:	0009a503          	lw	a0,0(s3)
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	90c080e7          	jalr	-1780(ra) # 80003486 <bfree>
      ip->addrs[i] = 0;
    80003b82:	0004a023          	sw	zero,0(s1)
    80003b86:	b7dd                	j	80003b6c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b88:	0809a583          	lw	a1,128(s3)
    80003b8c:	e185                	bnez	a1,80003bac <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b8e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b92:	854e                	mv	a0,s3
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	de4080e7          	jalr	-540(ra) # 80003978 <iupdate>
}
    80003b9c:	70a2                	ld	ra,40(sp)
    80003b9e:	7402                	ld	s0,32(sp)
    80003ba0:	64e2                	ld	s1,24(sp)
    80003ba2:	6942                	ld	s2,16(sp)
    80003ba4:	69a2                	ld	s3,8(sp)
    80003ba6:	6a02                	ld	s4,0(sp)
    80003ba8:	6145                	addi	sp,sp,48
    80003baa:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bac:	0009a503          	lw	a0,0(s3)
    80003bb0:	fffff097          	auipc	ra,0xfffff
    80003bb4:	690080e7          	jalr	1680(ra) # 80003240 <bread>
    80003bb8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bba:	05850493          	addi	s1,a0,88
    80003bbe:	45850913          	addi	s2,a0,1112
    80003bc2:	a811                	j	80003bd6 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003bc4:	0009a503          	lw	a0,0(s3)
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	8be080e7          	jalr	-1858(ra) # 80003486 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003bd0:	0491                	addi	s1,s1,4
    80003bd2:	01248563          	beq	s1,s2,80003bdc <itrunc+0x8c>
      if(a[j])
    80003bd6:	408c                	lw	a1,0(s1)
    80003bd8:	dde5                	beqz	a1,80003bd0 <itrunc+0x80>
    80003bda:	b7ed                	j	80003bc4 <itrunc+0x74>
    brelse(bp);
    80003bdc:	8552                	mv	a0,s4
    80003bde:	fffff097          	auipc	ra,0xfffff
    80003be2:	792080e7          	jalr	1938(ra) # 80003370 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003be6:	0809a583          	lw	a1,128(s3)
    80003bea:	0009a503          	lw	a0,0(s3)
    80003bee:	00000097          	auipc	ra,0x0
    80003bf2:	898080e7          	jalr	-1896(ra) # 80003486 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003bf6:	0809a023          	sw	zero,128(s3)
    80003bfa:	bf51                	j	80003b8e <itrunc+0x3e>

0000000080003bfc <iput>:
{
    80003bfc:	1101                	addi	sp,sp,-32
    80003bfe:	ec06                	sd	ra,24(sp)
    80003c00:	e822                	sd	s0,16(sp)
    80003c02:	e426                	sd	s1,8(sp)
    80003c04:	e04a                	sd	s2,0(sp)
    80003c06:	1000                	addi	s0,sp,32
    80003c08:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c0a:	0001c517          	auipc	a0,0x1c
    80003c0e:	fbe50513          	addi	a0,a0,-66 # 8001fbc8 <itable>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	fd2080e7          	jalr	-46(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c1a:	4498                	lw	a4,8(s1)
    80003c1c:	4785                	li	a5,1
    80003c1e:	02f70363          	beq	a4,a5,80003c44 <iput+0x48>
  ip->ref--;
    80003c22:	449c                	lw	a5,8(s1)
    80003c24:	37fd                	addiw	a5,a5,-1
    80003c26:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c28:	0001c517          	auipc	a0,0x1c
    80003c2c:	fa050513          	addi	a0,a0,-96 # 8001fbc8 <itable>
    80003c30:	ffffd097          	auipc	ra,0xffffd
    80003c34:	068080e7          	jalr	104(ra) # 80000c98 <release>
}
    80003c38:	60e2                	ld	ra,24(sp)
    80003c3a:	6442                	ld	s0,16(sp)
    80003c3c:	64a2                	ld	s1,8(sp)
    80003c3e:	6902                	ld	s2,0(sp)
    80003c40:	6105                	addi	sp,sp,32
    80003c42:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c44:	40bc                	lw	a5,64(s1)
    80003c46:	dff1                	beqz	a5,80003c22 <iput+0x26>
    80003c48:	04a49783          	lh	a5,74(s1)
    80003c4c:	fbf9                	bnez	a5,80003c22 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c4e:	01048913          	addi	s2,s1,16
    80003c52:	854a                	mv	a0,s2
    80003c54:	00001097          	auipc	ra,0x1
    80003c58:	ab8080e7          	jalr	-1352(ra) # 8000470c <acquiresleep>
    release(&itable.lock);
    80003c5c:	0001c517          	auipc	a0,0x1c
    80003c60:	f6c50513          	addi	a0,a0,-148 # 8001fbc8 <itable>
    80003c64:	ffffd097          	auipc	ra,0xffffd
    80003c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
    itrunc(ip);
    80003c6c:	8526                	mv	a0,s1
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	ee2080e7          	jalr	-286(ra) # 80003b50 <itrunc>
    ip->type = 0;
    80003c76:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c7a:	8526                	mv	a0,s1
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	cfc080e7          	jalr	-772(ra) # 80003978 <iupdate>
    ip->valid = 0;
    80003c84:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c88:	854a                	mv	a0,s2
    80003c8a:	00001097          	auipc	ra,0x1
    80003c8e:	ad8080e7          	jalr	-1320(ra) # 80004762 <releasesleep>
    acquire(&itable.lock);
    80003c92:	0001c517          	auipc	a0,0x1c
    80003c96:	f3650513          	addi	a0,a0,-202 # 8001fbc8 <itable>
    80003c9a:	ffffd097          	auipc	ra,0xffffd
    80003c9e:	f4a080e7          	jalr	-182(ra) # 80000be4 <acquire>
    80003ca2:	b741                	j	80003c22 <iput+0x26>

0000000080003ca4 <iunlockput>:
{
    80003ca4:	1101                	addi	sp,sp,-32
    80003ca6:	ec06                	sd	ra,24(sp)
    80003ca8:	e822                	sd	s0,16(sp)
    80003caa:	e426                	sd	s1,8(sp)
    80003cac:	1000                	addi	s0,sp,32
    80003cae:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	e54080e7          	jalr	-428(ra) # 80003b04 <iunlock>
  iput(ip);
    80003cb8:	8526                	mv	a0,s1
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	f42080e7          	jalr	-190(ra) # 80003bfc <iput>
}
    80003cc2:	60e2                	ld	ra,24(sp)
    80003cc4:	6442                	ld	s0,16(sp)
    80003cc6:	64a2                	ld	s1,8(sp)
    80003cc8:	6105                	addi	sp,sp,32
    80003cca:	8082                	ret

0000000080003ccc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ccc:	1141                	addi	sp,sp,-16
    80003cce:	e422                	sd	s0,8(sp)
    80003cd0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003cd2:	411c                	lw	a5,0(a0)
    80003cd4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003cd6:	415c                	lw	a5,4(a0)
    80003cd8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003cda:	04451783          	lh	a5,68(a0)
    80003cde:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ce2:	04a51783          	lh	a5,74(a0)
    80003ce6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cea:	04c56783          	lwu	a5,76(a0)
    80003cee:	e99c                	sd	a5,16(a1)
}
    80003cf0:	6422                	ld	s0,8(sp)
    80003cf2:	0141                	addi	sp,sp,16
    80003cf4:	8082                	ret

0000000080003cf6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cf6:	457c                	lw	a5,76(a0)
    80003cf8:	0ed7e963          	bltu	a5,a3,80003dea <readi+0xf4>
{
    80003cfc:	7159                	addi	sp,sp,-112
    80003cfe:	f486                	sd	ra,104(sp)
    80003d00:	f0a2                	sd	s0,96(sp)
    80003d02:	eca6                	sd	s1,88(sp)
    80003d04:	e8ca                	sd	s2,80(sp)
    80003d06:	e4ce                	sd	s3,72(sp)
    80003d08:	e0d2                	sd	s4,64(sp)
    80003d0a:	fc56                	sd	s5,56(sp)
    80003d0c:	f85a                	sd	s6,48(sp)
    80003d0e:	f45e                	sd	s7,40(sp)
    80003d10:	f062                	sd	s8,32(sp)
    80003d12:	ec66                	sd	s9,24(sp)
    80003d14:	e86a                	sd	s10,16(sp)
    80003d16:	e46e                	sd	s11,8(sp)
    80003d18:	1880                	addi	s0,sp,112
    80003d1a:	8baa                	mv	s7,a0
    80003d1c:	8c2e                	mv	s8,a1
    80003d1e:	8ab2                	mv	s5,a2
    80003d20:	84b6                	mv	s1,a3
    80003d22:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d24:	9f35                	addw	a4,a4,a3
    return 0;
    80003d26:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d28:	0ad76063          	bltu	a4,a3,80003dc8 <readi+0xd2>
  if(off + n > ip->size)
    80003d2c:	00e7f463          	bgeu	a5,a4,80003d34 <readi+0x3e>
    n = ip->size - off;
    80003d30:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d34:	0a0b0963          	beqz	s6,80003de6 <readi+0xf0>
    80003d38:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d3a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d3e:	5cfd                	li	s9,-1
    80003d40:	a82d                	j	80003d7a <readi+0x84>
    80003d42:	020a1d93          	slli	s11,s4,0x20
    80003d46:	020ddd93          	srli	s11,s11,0x20
    80003d4a:	05890613          	addi	a2,s2,88
    80003d4e:	86ee                	mv	a3,s11
    80003d50:	963a                	add	a2,a2,a4
    80003d52:	85d6                	mv	a1,s5
    80003d54:	8562                	mv	a0,s8
    80003d56:	fffff097          	auipc	ra,0xfffff
    80003d5a:	8a0080e7          	jalr	-1888(ra) # 800025f6 <either_copyout>
    80003d5e:	05950d63          	beq	a0,s9,80003db8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d62:	854a                	mv	a0,s2
    80003d64:	fffff097          	auipc	ra,0xfffff
    80003d68:	60c080e7          	jalr	1548(ra) # 80003370 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d6c:	013a09bb          	addw	s3,s4,s3
    80003d70:	009a04bb          	addw	s1,s4,s1
    80003d74:	9aee                	add	s5,s5,s11
    80003d76:	0569f763          	bgeu	s3,s6,80003dc4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d7a:	000ba903          	lw	s2,0(s7)
    80003d7e:	00a4d59b          	srliw	a1,s1,0xa
    80003d82:	855e                	mv	a0,s7
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	8b0080e7          	jalr	-1872(ra) # 80003634 <bmap>
    80003d8c:	0005059b          	sext.w	a1,a0
    80003d90:	854a                	mv	a0,s2
    80003d92:	fffff097          	auipc	ra,0xfffff
    80003d96:	4ae080e7          	jalr	1198(ra) # 80003240 <bread>
    80003d9a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d9c:	3ff4f713          	andi	a4,s1,1023
    80003da0:	40ed07bb          	subw	a5,s10,a4
    80003da4:	413b06bb          	subw	a3,s6,s3
    80003da8:	8a3e                	mv	s4,a5
    80003daa:	2781                	sext.w	a5,a5
    80003dac:	0006861b          	sext.w	a2,a3
    80003db0:	f8f679e3          	bgeu	a2,a5,80003d42 <readi+0x4c>
    80003db4:	8a36                	mv	s4,a3
    80003db6:	b771                	j	80003d42 <readi+0x4c>
      brelse(bp);
    80003db8:	854a                	mv	a0,s2
    80003dba:	fffff097          	auipc	ra,0xfffff
    80003dbe:	5b6080e7          	jalr	1462(ra) # 80003370 <brelse>
      tot = -1;
    80003dc2:	59fd                	li	s3,-1
  }
  return tot;
    80003dc4:	0009851b          	sext.w	a0,s3
}
    80003dc8:	70a6                	ld	ra,104(sp)
    80003dca:	7406                	ld	s0,96(sp)
    80003dcc:	64e6                	ld	s1,88(sp)
    80003dce:	6946                	ld	s2,80(sp)
    80003dd0:	69a6                	ld	s3,72(sp)
    80003dd2:	6a06                	ld	s4,64(sp)
    80003dd4:	7ae2                	ld	s5,56(sp)
    80003dd6:	7b42                	ld	s6,48(sp)
    80003dd8:	7ba2                	ld	s7,40(sp)
    80003dda:	7c02                	ld	s8,32(sp)
    80003ddc:	6ce2                	ld	s9,24(sp)
    80003dde:	6d42                	ld	s10,16(sp)
    80003de0:	6da2                	ld	s11,8(sp)
    80003de2:	6165                	addi	sp,sp,112
    80003de4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003de6:	89da                	mv	s3,s6
    80003de8:	bff1                	j	80003dc4 <readi+0xce>
    return 0;
    80003dea:	4501                	li	a0,0
}
    80003dec:	8082                	ret

0000000080003dee <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dee:	457c                	lw	a5,76(a0)
    80003df0:	10d7e863          	bltu	a5,a3,80003f00 <writei+0x112>
{
    80003df4:	7159                	addi	sp,sp,-112
    80003df6:	f486                	sd	ra,104(sp)
    80003df8:	f0a2                	sd	s0,96(sp)
    80003dfa:	eca6                	sd	s1,88(sp)
    80003dfc:	e8ca                	sd	s2,80(sp)
    80003dfe:	e4ce                	sd	s3,72(sp)
    80003e00:	e0d2                	sd	s4,64(sp)
    80003e02:	fc56                	sd	s5,56(sp)
    80003e04:	f85a                	sd	s6,48(sp)
    80003e06:	f45e                	sd	s7,40(sp)
    80003e08:	f062                	sd	s8,32(sp)
    80003e0a:	ec66                	sd	s9,24(sp)
    80003e0c:	e86a                	sd	s10,16(sp)
    80003e0e:	e46e                	sd	s11,8(sp)
    80003e10:	1880                	addi	s0,sp,112
    80003e12:	8b2a                	mv	s6,a0
    80003e14:	8c2e                	mv	s8,a1
    80003e16:	8ab2                	mv	s5,a2
    80003e18:	8936                	mv	s2,a3
    80003e1a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003e1c:	00e687bb          	addw	a5,a3,a4
    80003e20:	0ed7e263          	bltu	a5,a3,80003f04 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e24:	00043737          	lui	a4,0x43
    80003e28:	0ef76063          	bltu	a4,a5,80003f08 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e2c:	0c0b8863          	beqz	s7,80003efc <writei+0x10e>
    80003e30:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e32:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e36:	5cfd                	li	s9,-1
    80003e38:	a091                	j	80003e7c <writei+0x8e>
    80003e3a:	02099d93          	slli	s11,s3,0x20
    80003e3e:	020ddd93          	srli	s11,s11,0x20
    80003e42:	05848513          	addi	a0,s1,88
    80003e46:	86ee                	mv	a3,s11
    80003e48:	8656                	mv	a2,s5
    80003e4a:	85e2                	mv	a1,s8
    80003e4c:	953a                	add	a0,a0,a4
    80003e4e:	ffffe097          	auipc	ra,0xffffe
    80003e52:	7fe080e7          	jalr	2046(ra) # 8000264c <either_copyin>
    80003e56:	07950263          	beq	a0,s9,80003eba <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e5a:	8526                	mv	a0,s1
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	790080e7          	jalr	1936(ra) # 800045ec <log_write>
    brelse(bp);
    80003e64:	8526                	mv	a0,s1
    80003e66:	fffff097          	auipc	ra,0xfffff
    80003e6a:	50a080e7          	jalr	1290(ra) # 80003370 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e6e:	01498a3b          	addw	s4,s3,s4
    80003e72:	0129893b          	addw	s2,s3,s2
    80003e76:	9aee                	add	s5,s5,s11
    80003e78:	057a7663          	bgeu	s4,s7,80003ec4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e7c:	000b2483          	lw	s1,0(s6)
    80003e80:	00a9559b          	srliw	a1,s2,0xa
    80003e84:	855a                	mv	a0,s6
    80003e86:	fffff097          	auipc	ra,0xfffff
    80003e8a:	7ae080e7          	jalr	1966(ra) # 80003634 <bmap>
    80003e8e:	0005059b          	sext.w	a1,a0
    80003e92:	8526                	mv	a0,s1
    80003e94:	fffff097          	auipc	ra,0xfffff
    80003e98:	3ac080e7          	jalr	940(ra) # 80003240 <bread>
    80003e9c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e9e:	3ff97713          	andi	a4,s2,1023
    80003ea2:	40ed07bb          	subw	a5,s10,a4
    80003ea6:	414b86bb          	subw	a3,s7,s4
    80003eaa:	89be                	mv	s3,a5
    80003eac:	2781                	sext.w	a5,a5
    80003eae:	0006861b          	sext.w	a2,a3
    80003eb2:	f8f674e3          	bgeu	a2,a5,80003e3a <writei+0x4c>
    80003eb6:	89b6                	mv	s3,a3
    80003eb8:	b749                	j	80003e3a <writei+0x4c>
      brelse(bp);
    80003eba:	8526                	mv	a0,s1
    80003ebc:	fffff097          	auipc	ra,0xfffff
    80003ec0:	4b4080e7          	jalr	1204(ra) # 80003370 <brelse>
  }

  if(off > ip->size)
    80003ec4:	04cb2783          	lw	a5,76(s6)
    80003ec8:	0127f463          	bgeu	a5,s2,80003ed0 <writei+0xe2>
    ip->size = off;
    80003ecc:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ed0:	855a                	mv	a0,s6
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	aa6080e7          	jalr	-1370(ra) # 80003978 <iupdate>

  return tot;
    80003eda:	000a051b          	sext.w	a0,s4
}
    80003ede:	70a6                	ld	ra,104(sp)
    80003ee0:	7406                	ld	s0,96(sp)
    80003ee2:	64e6                	ld	s1,88(sp)
    80003ee4:	6946                	ld	s2,80(sp)
    80003ee6:	69a6                	ld	s3,72(sp)
    80003ee8:	6a06                	ld	s4,64(sp)
    80003eea:	7ae2                	ld	s5,56(sp)
    80003eec:	7b42                	ld	s6,48(sp)
    80003eee:	7ba2                	ld	s7,40(sp)
    80003ef0:	7c02                	ld	s8,32(sp)
    80003ef2:	6ce2                	ld	s9,24(sp)
    80003ef4:	6d42                	ld	s10,16(sp)
    80003ef6:	6da2                	ld	s11,8(sp)
    80003ef8:	6165                	addi	sp,sp,112
    80003efa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003efc:	8a5e                	mv	s4,s7
    80003efe:	bfc9                	j	80003ed0 <writei+0xe2>
    return -1;
    80003f00:	557d                	li	a0,-1
}
    80003f02:	8082                	ret
    return -1;
    80003f04:	557d                	li	a0,-1
    80003f06:	bfe1                	j	80003ede <writei+0xf0>
    return -1;
    80003f08:	557d                	li	a0,-1
    80003f0a:	bfd1                	j	80003ede <writei+0xf0>

0000000080003f0c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f0c:	1141                	addi	sp,sp,-16
    80003f0e:	e406                	sd	ra,8(sp)
    80003f10:	e022                	sd	s0,0(sp)
    80003f12:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f14:	4639                	li	a2,14
    80003f16:	ffffd097          	auipc	ra,0xffffd
    80003f1a:	ea2080e7          	jalr	-350(ra) # 80000db8 <strncmp>
}
    80003f1e:	60a2                	ld	ra,8(sp)
    80003f20:	6402                	ld	s0,0(sp)
    80003f22:	0141                	addi	sp,sp,16
    80003f24:	8082                	ret

0000000080003f26 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f26:	7139                	addi	sp,sp,-64
    80003f28:	fc06                	sd	ra,56(sp)
    80003f2a:	f822                	sd	s0,48(sp)
    80003f2c:	f426                	sd	s1,40(sp)
    80003f2e:	f04a                	sd	s2,32(sp)
    80003f30:	ec4e                	sd	s3,24(sp)
    80003f32:	e852                	sd	s4,16(sp)
    80003f34:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f36:	04451703          	lh	a4,68(a0)
    80003f3a:	4785                	li	a5,1
    80003f3c:	00f71a63          	bne	a4,a5,80003f50 <dirlookup+0x2a>
    80003f40:	892a                	mv	s2,a0
    80003f42:	89ae                	mv	s3,a1
    80003f44:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f46:	457c                	lw	a5,76(a0)
    80003f48:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f4a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f4c:	e79d                	bnez	a5,80003f7a <dirlookup+0x54>
    80003f4e:	a8a5                	j	80003fc6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f50:	00005517          	auipc	a0,0x5
    80003f54:	84850513          	addi	a0,a0,-1976 # 80008798 <syscalls+0x1b0>
    80003f58:	ffffc097          	auipc	ra,0xffffc
    80003f5c:	5e6080e7          	jalr	1510(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003f60:	00005517          	auipc	a0,0x5
    80003f64:	85050513          	addi	a0,a0,-1968 # 800087b0 <syscalls+0x1c8>
    80003f68:	ffffc097          	auipc	ra,0xffffc
    80003f6c:	5d6080e7          	jalr	1494(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f70:	24c1                	addiw	s1,s1,16
    80003f72:	04c92783          	lw	a5,76(s2)
    80003f76:	04f4f763          	bgeu	s1,a5,80003fc4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f7a:	4741                	li	a4,16
    80003f7c:	86a6                	mv	a3,s1
    80003f7e:	fc040613          	addi	a2,s0,-64
    80003f82:	4581                	li	a1,0
    80003f84:	854a                	mv	a0,s2
    80003f86:	00000097          	auipc	ra,0x0
    80003f8a:	d70080e7          	jalr	-656(ra) # 80003cf6 <readi>
    80003f8e:	47c1                	li	a5,16
    80003f90:	fcf518e3          	bne	a0,a5,80003f60 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f94:	fc045783          	lhu	a5,-64(s0)
    80003f98:	dfe1                	beqz	a5,80003f70 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f9a:	fc240593          	addi	a1,s0,-62
    80003f9e:	854e                	mv	a0,s3
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	f6c080e7          	jalr	-148(ra) # 80003f0c <namecmp>
    80003fa8:	f561                	bnez	a0,80003f70 <dirlookup+0x4a>
      if(poff)
    80003faa:	000a0463          	beqz	s4,80003fb2 <dirlookup+0x8c>
        *poff = off;
    80003fae:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fb2:	fc045583          	lhu	a1,-64(s0)
    80003fb6:	00092503          	lw	a0,0(s2)
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	754080e7          	jalr	1876(ra) # 8000370e <iget>
    80003fc2:	a011                	j	80003fc6 <dirlookup+0xa0>
  return 0;
    80003fc4:	4501                	li	a0,0
}
    80003fc6:	70e2                	ld	ra,56(sp)
    80003fc8:	7442                	ld	s0,48(sp)
    80003fca:	74a2                	ld	s1,40(sp)
    80003fcc:	7902                	ld	s2,32(sp)
    80003fce:	69e2                	ld	s3,24(sp)
    80003fd0:	6a42                	ld	s4,16(sp)
    80003fd2:	6121                	addi	sp,sp,64
    80003fd4:	8082                	ret

0000000080003fd6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fd6:	711d                	addi	sp,sp,-96
    80003fd8:	ec86                	sd	ra,88(sp)
    80003fda:	e8a2                	sd	s0,80(sp)
    80003fdc:	e4a6                	sd	s1,72(sp)
    80003fde:	e0ca                	sd	s2,64(sp)
    80003fe0:	fc4e                	sd	s3,56(sp)
    80003fe2:	f852                	sd	s4,48(sp)
    80003fe4:	f456                	sd	s5,40(sp)
    80003fe6:	f05a                	sd	s6,32(sp)
    80003fe8:	ec5e                	sd	s7,24(sp)
    80003fea:	e862                	sd	s8,16(sp)
    80003fec:	e466                	sd	s9,8(sp)
    80003fee:	1080                	addi	s0,sp,96
    80003ff0:	84aa                	mv	s1,a0
    80003ff2:	8b2e                	mv	s6,a1
    80003ff4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ff6:	00054703          	lbu	a4,0(a0)
    80003ffa:	02f00793          	li	a5,47
    80003ffe:	02f70363          	beq	a4,a5,80004024 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004002:	ffffe097          	auipc	ra,0xffffe
    80004006:	a0c080e7          	jalr	-1524(ra) # 80001a0e <myproc>
    8000400a:	15053503          	ld	a0,336(a0)
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	9f6080e7          	jalr	-1546(ra) # 80003a04 <idup>
    80004016:	89aa                	mv	s3,a0
  while(*path == '/')
    80004018:	02f00913          	li	s2,47
  len = path - s;
    8000401c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000401e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004020:	4c05                	li	s8,1
    80004022:	a865                	j	800040da <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004024:	4585                	li	a1,1
    80004026:	4505                	li	a0,1
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	6e6080e7          	jalr	1766(ra) # 8000370e <iget>
    80004030:	89aa                	mv	s3,a0
    80004032:	b7dd                	j	80004018 <namex+0x42>
      iunlockput(ip);
    80004034:	854e                	mv	a0,s3
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	c6e080e7          	jalr	-914(ra) # 80003ca4 <iunlockput>
      return 0;
    8000403e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004040:	854e                	mv	a0,s3
    80004042:	60e6                	ld	ra,88(sp)
    80004044:	6446                	ld	s0,80(sp)
    80004046:	64a6                	ld	s1,72(sp)
    80004048:	6906                	ld	s2,64(sp)
    8000404a:	79e2                	ld	s3,56(sp)
    8000404c:	7a42                	ld	s4,48(sp)
    8000404e:	7aa2                	ld	s5,40(sp)
    80004050:	7b02                	ld	s6,32(sp)
    80004052:	6be2                	ld	s7,24(sp)
    80004054:	6c42                	ld	s8,16(sp)
    80004056:	6ca2                	ld	s9,8(sp)
    80004058:	6125                	addi	sp,sp,96
    8000405a:	8082                	ret
      iunlock(ip);
    8000405c:	854e                	mv	a0,s3
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	aa6080e7          	jalr	-1370(ra) # 80003b04 <iunlock>
      return ip;
    80004066:	bfe9                	j	80004040 <namex+0x6a>
      iunlockput(ip);
    80004068:	854e                	mv	a0,s3
    8000406a:	00000097          	auipc	ra,0x0
    8000406e:	c3a080e7          	jalr	-966(ra) # 80003ca4 <iunlockput>
      return 0;
    80004072:	89d2                	mv	s3,s4
    80004074:	b7f1                	j	80004040 <namex+0x6a>
  len = path - s;
    80004076:	40b48633          	sub	a2,s1,a1
    8000407a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000407e:	094cd463          	bge	s9,s4,80004106 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004082:	4639                	li	a2,14
    80004084:	8556                	mv	a0,s5
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	cba080e7          	jalr	-838(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000408e:	0004c783          	lbu	a5,0(s1)
    80004092:	01279763          	bne	a5,s2,800040a0 <namex+0xca>
    path++;
    80004096:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004098:	0004c783          	lbu	a5,0(s1)
    8000409c:	ff278de3          	beq	a5,s2,80004096 <namex+0xc0>
    ilock(ip);
    800040a0:	854e                	mv	a0,s3
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	9a0080e7          	jalr	-1632(ra) # 80003a42 <ilock>
    if(ip->type != T_DIR){
    800040aa:	04499783          	lh	a5,68(s3)
    800040ae:	f98793e3          	bne	a5,s8,80004034 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800040b2:	000b0563          	beqz	s6,800040bc <namex+0xe6>
    800040b6:	0004c783          	lbu	a5,0(s1)
    800040ba:	d3cd                	beqz	a5,8000405c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040bc:	865e                	mv	a2,s7
    800040be:	85d6                	mv	a1,s5
    800040c0:	854e                	mv	a0,s3
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	e64080e7          	jalr	-412(ra) # 80003f26 <dirlookup>
    800040ca:	8a2a                	mv	s4,a0
    800040cc:	dd51                	beqz	a0,80004068 <namex+0x92>
    iunlockput(ip);
    800040ce:	854e                	mv	a0,s3
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	bd4080e7          	jalr	-1068(ra) # 80003ca4 <iunlockput>
    ip = next;
    800040d8:	89d2                	mv	s3,s4
  while(*path == '/')
    800040da:	0004c783          	lbu	a5,0(s1)
    800040de:	05279763          	bne	a5,s2,8000412c <namex+0x156>
    path++;
    800040e2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040e4:	0004c783          	lbu	a5,0(s1)
    800040e8:	ff278de3          	beq	a5,s2,800040e2 <namex+0x10c>
  if(*path == 0)
    800040ec:	c79d                	beqz	a5,8000411a <namex+0x144>
    path++;
    800040ee:	85a6                	mv	a1,s1
  len = path - s;
    800040f0:	8a5e                	mv	s4,s7
    800040f2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800040f4:	01278963          	beq	a5,s2,80004106 <namex+0x130>
    800040f8:	dfbd                	beqz	a5,80004076 <namex+0xa0>
    path++;
    800040fa:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800040fc:	0004c783          	lbu	a5,0(s1)
    80004100:	ff279ce3          	bne	a5,s2,800040f8 <namex+0x122>
    80004104:	bf8d                	j	80004076 <namex+0xa0>
    memmove(name, s, len);
    80004106:	2601                	sext.w	a2,a2
    80004108:	8556                	mv	a0,s5
    8000410a:	ffffd097          	auipc	ra,0xffffd
    8000410e:	c36080e7          	jalr	-970(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004112:	9a56                	add	s4,s4,s5
    80004114:	000a0023          	sb	zero,0(s4)
    80004118:	bf9d                	j	8000408e <namex+0xb8>
  if(nameiparent){
    8000411a:	f20b03e3          	beqz	s6,80004040 <namex+0x6a>
    iput(ip);
    8000411e:	854e                	mv	a0,s3
    80004120:	00000097          	auipc	ra,0x0
    80004124:	adc080e7          	jalr	-1316(ra) # 80003bfc <iput>
    return 0;
    80004128:	4981                	li	s3,0
    8000412a:	bf19                	j	80004040 <namex+0x6a>
  if(*path == 0)
    8000412c:	d7fd                	beqz	a5,8000411a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000412e:	0004c783          	lbu	a5,0(s1)
    80004132:	85a6                	mv	a1,s1
    80004134:	b7d1                	j	800040f8 <namex+0x122>

0000000080004136 <dirlink>:
{
    80004136:	7139                	addi	sp,sp,-64
    80004138:	fc06                	sd	ra,56(sp)
    8000413a:	f822                	sd	s0,48(sp)
    8000413c:	f426                	sd	s1,40(sp)
    8000413e:	f04a                	sd	s2,32(sp)
    80004140:	ec4e                	sd	s3,24(sp)
    80004142:	e852                	sd	s4,16(sp)
    80004144:	0080                	addi	s0,sp,64
    80004146:	892a                	mv	s2,a0
    80004148:	8a2e                	mv	s4,a1
    8000414a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000414c:	4601                	li	a2,0
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	dd8080e7          	jalr	-552(ra) # 80003f26 <dirlookup>
    80004156:	e93d                	bnez	a0,800041cc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004158:	04c92483          	lw	s1,76(s2)
    8000415c:	c49d                	beqz	s1,8000418a <dirlink+0x54>
    8000415e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004160:	4741                	li	a4,16
    80004162:	86a6                	mv	a3,s1
    80004164:	fc040613          	addi	a2,s0,-64
    80004168:	4581                	li	a1,0
    8000416a:	854a                	mv	a0,s2
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	b8a080e7          	jalr	-1142(ra) # 80003cf6 <readi>
    80004174:	47c1                	li	a5,16
    80004176:	06f51163          	bne	a0,a5,800041d8 <dirlink+0xa2>
    if(de.inum == 0)
    8000417a:	fc045783          	lhu	a5,-64(s0)
    8000417e:	c791                	beqz	a5,8000418a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004180:	24c1                	addiw	s1,s1,16
    80004182:	04c92783          	lw	a5,76(s2)
    80004186:	fcf4ede3          	bltu	s1,a5,80004160 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000418a:	4639                	li	a2,14
    8000418c:	85d2                	mv	a1,s4
    8000418e:	fc240513          	addi	a0,s0,-62
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	c62080e7          	jalr	-926(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000419a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000419e:	4741                	li	a4,16
    800041a0:	86a6                	mv	a3,s1
    800041a2:	fc040613          	addi	a2,s0,-64
    800041a6:	4581                	li	a1,0
    800041a8:	854a                	mv	a0,s2
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	c44080e7          	jalr	-956(ra) # 80003dee <writei>
    800041b2:	872a                	mv	a4,a0
    800041b4:	47c1                	li	a5,16
  return 0;
    800041b6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041b8:	02f71863          	bne	a4,a5,800041e8 <dirlink+0xb2>
}
    800041bc:	70e2                	ld	ra,56(sp)
    800041be:	7442                	ld	s0,48(sp)
    800041c0:	74a2                	ld	s1,40(sp)
    800041c2:	7902                	ld	s2,32(sp)
    800041c4:	69e2                	ld	s3,24(sp)
    800041c6:	6a42                	ld	s4,16(sp)
    800041c8:	6121                	addi	sp,sp,64
    800041ca:	8082                	ret
    iput(ip);
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	a30080e7          	jalr	-1488(ra) # 80003bfc <iput>
    return -1;
    800041d4:	557d                	li	a0,-1
    800041d6:	b7dd                	j	800041bc <dirlink+0x86>
      panic("dirlink read");
    800041d8:	00004517          	auipc	a0,0x4
    800041dc:	5e850513          	addi	a0,a0,1512 # 800087c0 <syscalls+0x1d8>
    800041e0:	ffffc097          	auipc	ra,0xffffc
    800041e4:	35e080e7          	jalr	862(ra) # 8000053e <panic>
    panic("dirlink");
    800041e8:	00004517          	auipc	a0,0x4
    800041ec:	6e050513          	addi	a0,a0,1760 # 800088c8 <syscalls+0x2e0>
    800041f0:	ffffc097          	auipc	ra,0xffffc
    800041f4:	34e080e7          	jalr	846(ra) # 8000053e <panic>

00000000800041f8 <namei>:

struct inode*
namei(char *path)
{
    800041f8:	1101                	addi	sp,sp,-32
    800041fa:	ec06                	sd	ra,24(sp)
    800041fc:	e822                	sd	s0,16(sp)
    800041fe:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004200:	fe040613          	addi	a2,s0,-32
    80004204:	4581                	li	a1,0
    80004206:	00000097          	auipc	ra,0x0
    8000420a:	dd0080e7          	jalr	-560(ra) # 80003fd6 <namex>
}
    8000420e:	60e2                	ld	ra,24(sp)
    80004210:	6442                	ld	s0,16(sp)
    80004212:	6105                	addi	sp,sp,32
    80004214:	8082                	ret

0000000080004216 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004216:	1141                	addi	sp,sp,-16
    80004218:	e406                	sd	ra,8(sp)
    8000421a:	e022                	sd	s0,0(sp)
    8000421c:	0800                	addi	s0,sp,16
    8000421e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004220:	4585                	li	a1,1
    80004222:	00000097          	auipc	ra,0x0
    80004226:	db4080e7          	jalr	-588(ra) # 80003fd6 <namex>
}
    8000422a:	60a2                	ld	ra,8(sp)
    8000422c:	6402                	ld	s0,0(sp)
    8000422e:	0141                	addi	sp,sp,16
    80004230:	8082                	ret

0000000080004232 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004232:	1101                	addi	sp,sp,-32
    80004234:	ec06                	sd	ra,24(sp)
    80004236:	e822                	sd	s0,16(sp)
    80004238:	e426                	sd	s1,8(sp)
    8000423a:	e04a                	sd	s2,0(sp)
    8000423c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000423e:	0001d917          	auipc	s2,0x1d
    80004242:	43290913          	addi	s2,s2,1074 # 80021670 <log>
    80004246:	01892583          	lw	a1,24(s2)
    8000424a:	02892503          	lw	a0,40(s2)
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	ff2080e7          	jalr	-14(ra) # 80003240 <bread>
    80004256:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004258:	02c92683          	lw	a3,44(s2)
    8000425c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000425e:	02d05763          	blez	a3,8000428c <write_head+0x5a>
    80004262:	0001d797          	auipc	a5,0x1d
    80004266:	43e78793          	addi	a5,a5,1086 # 800216a0 <log+0x30>
    8000426a:	05c50713          	addi	a4,a0,92
    8000426e:	36fd                	addiw	a3,a3,-1
    80004270:	1682                	slli	a3,a3,0x20
    80004272:	9281                	srli	a3,a3,0x20
    80004274:	068a                	slli	a3,a3,0x2
    80004276:	0001d617          	auipc	a2,0x1d
    8000427a:	42e60613          	addi	a2,a2,1070 # 800216a4 <log+0x34>
    8000427e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004280:	4390                	lw	a2,0(a5)
    80004282:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004284:	0791                	addi	a5,a5,4
    80004286:	0711                	addi	a4,a4,4
    80004288:	fed79ce3          	bne	a5,a3,80004280 <write_head+0x4e>
  }
  bwrite(buf);
    8000428c:	8526                	mv	a0,s1
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	0a4080e7          	jalr	164(ra) # 80003332 <bwrite>
  brelse(buf);
    80004296:	8526                	mv	a0,s1
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	0d8080e7          	jalr	216(ra) # 80003370 <brelse>
}
    800042a0:	60e2                	ld	ra,24(sp)
    800042a2:	6442                	ld	s0,16(sp)
    800042a4:	64a2                	ld	s1,8(sp)
    800042a6:	6902                	ld	s2,0(sp)
    800042a8:	6105                	addi	sp,sp,32
    800042aa:	8082                	ret

00000000800042ac <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ac:	0001d797          	auipc	a5,0x1d
    800042b0:	3f07a783          	lw	a5,1008(a5) # 8002169c <log+0x2c>
    800042b4:	0af05d63          	blez	a5,8000436e <install_trans+0xc2>
{
    800042b8:	7139                	addi	sp,sp,-64
    800042ba:	fc06                	sd	ra,56(sp)
    800042bc:	f822                	sd	s0,48(sp)
    800042be:	f426                	sd	s1,40(sp)
    800042c0:	f04a                	sd	s2,32(sp)
    800042c2:	ec4e                	sd	s3,24(sp)
    800042c4:	e852                	sd	s4,16(sp)
    800042c6:	e456                	sd	s5,8(sp)
    800042c8:	e05a                	sd	s6,0(sp)
    800042ca:	0080                	addi	s0,sp,64
    800042cc:	8b2a                	mv	s6,a0
    800042ce:	0001da97          	auipc	s5,0x1d
    800042d2:	3d2a8a93          	addi	s5,s5,978 # 800216a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042d6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042d8:	0001d997          	auipc	s3,0x1d
    800042dc:	39898993          	addi	s3,s3,920 # 80021670 <log>
    800042e0:	a035                	j	8000430c <install_trans+0x60>
      bunpin(dbuf);
    800042e2:	8526                	mv	a0,s1
    800042e4:	fffff097          	auipc	ra,0xfffff
    800042e8:	166080e7          	jalr	358(ra) # 8000344a <bunpin>
    brelse(lbuf);
    800042ec:	854a                	mv	a0,s2
    800042ee:	fffff097          	auipc	ra,0xfffff
    800042f2:	082080e7          	jalr	130(ra) # 80003370 <brelse>
    brelse(dbuf);
    800042f6:	8526                	mv	a0,s1
    800042f8:	fffff097          	auipc	ra,0xfffff
    800042fc:	078080e7          	jalr	120(ra) # 80003370 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004300:	2a05                	addiw	s4,s4,1
    80004302:	0a91                	addi	s5,s5,4
    80004304:	02c9a783          	lw	a5,44(s3)
    80004308:	04fa5963          	bge	s4,a5,8000435a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000430c:	0189a583          	lw	a1,24(s3)
    80004310:	014585bb          	addw	a1,a1,s4
    80004314:	2585                	addiw	a1,a1,1
    80004316:	0289a503          	lw	a0,40(s3)
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	f26080e7          	jalr	-218(ra) # 80003240 <bread>
    80004322:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004324:	000aa583          	lw	a1,0(s5)
    80004328:	0289a503          	lw	a0,40(s3)
    8000432c:	fffff097          	auipc	ra,0xfffff
    80004330:	f14080e7          	jalr	-236(ra) # 80003240 <bread>
    80004334:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004336:	40000613          	li	a2,1024
    8000433a:	05890593          	addi	a1,s2,88
    8000433e:	05850513          	addi	a0,a0,88
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	9fe080e7          	jalr	-1538(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000434a:	8526                	mv	a0,s1
    8000434c:	fffff097          	auipc	ra,0xfffff
    80004350:	fe6080e7          	jalr	-26(ra) # 80003332 <bwrite>
    if(recovering == 0)
    80004354:	f80b1ce3          	bnez	s6,800042ec <install_trans+0x40>
    80004358:	b769                	j	800042e2 <install_trans+0x36>
}
    8000435a:	70e2                	ld	ra,56(sp)
    8000435c:	7442                	ld	s0,48(sp)
    8000435e:	74a2                	ld	s1,40(sp)
    80004360:	7902                	ld	s2,32(sp)
    80004362:	69e2                	ld	s3,24(sp)
    80004364:	6a42                	ld	s4,16(sp)
    80004366:	6aa2                	ld	s5,8(sp)
    80004368:	6b02                	ld	s6,0(sp)
    8000436a:	6121                	addi	sp,sp,64
    8000436c:	8082                	ret
    8000436e:	8082                	ret

0000000080004370 <initlog>:
{
    80004370:	7179                	addi	sp,sp,-48
    80004372:	f406                	sd	ra,40(sp)
    80004374:	f022                	sd	s0,32(sp)
    80004376:	ec26                	sd	s1,24(sp)
    80004378:	e84a                	sd	s2,16(sp)
    8000437a:	e44e                	sd	s3,8(sp)
    8000437c:	1800                	addi	s0,sp,48
    8000437e:	892a                	mv	s2,a0
    80004380:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004382:	0001d497          	auipc	s1,0x1d
    80004386:	2ee48493          	addi	s1,s1,750 # 80021670 <log>
    8000438a:	00004597          	auipc	a1,0x4
    8000438e:	44658593          	addi	a1,a1,1094 # 800087d0 <syscalls+0x1e8>
    80004392:	8526                	mv	a0,s1
    80004394:	ffffc097          	auipc	ra,0xffffc
    80004398:	7c0080e7          	jalr	1984(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000439c:	0149a583          	lw	a1,20(s3)
    800043a0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800043a2:	0109a783          	lw	a5,16(s3)
    800043a6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800043a8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800043ac:	854a                	mv	a0,s2
    800043ae:	fffff097          	auipc	ra,0xfffff
    800043b2:	e92080e7          	jalr	-366(ra) # 80003240 <bread>
  log.lh.n = lh->n;
    800043b6:	4d3c                	lw	a5,88(a0)
    800043b8:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043ba:	02f05563          	blez	a5,800043e4 <initlog+0x74>
    800043be:	05c50713          	addi	a4,a0,92
    800043c2:	0001d697          	auipc	a3,0x1d
    800043c6:	2de68693          	addi	a3,a3,734 # 800216a0 <log+0x30>
    800043ca:	37fd                	addiw	a5,a5,-1
    800043cc:	1782                	slli	a5,a5,0x20
    800043ce:	9381                	srli	a5,a5,0x20
    800043d0:	078a                	slli	a5,a5,0x2
    800043d2:	06050613          	addi	a2,a0,96
    800043d6:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800043d8:	4310                	lw	a2,0(a4)
    800043da:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800043dc:	0711                	addi	a4,a4,4
    800043de:	0691                	addi	a3,a3,4
    800043e0:	fef71ce3          	bne	a4,a5,800043d8 <initlog+0x68>
  brelse(buf);
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	f8c080e7          	jalr	-116(ra) # 80003370 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043ec:	4505                	li	a0,1
    800043ee:	00000097          	auipc	ra,0x0
    800043f2:	ebe080e7          	jalr	-322(ra) # 800042ac <install_trans>
  log.lh.n = 0;
    800043f6:	0001d797          	auipc	a5,0x1d
    800043fa:	2a07a323          	sw	zero,678(a5) # 8002169c <log+0x2c>
  write_head(); // clear the log
    800043fe:	00000097          	auipc	ra,0x0
    80004402:	e34080e7          	jalr	-460(ra) # 80004232 <write_head>
}
    80004406:	70a2                	ld	ra,40(sp)
    80004408:	7402                	ld	s0,32(sp)
    8000440a:	64e2                	ld	s1,24(sp)
    8000440c:	6942                	ld	s2,16(sp)
    8000440e:	69a2                	ld	s3,8(sp)
    80004410:	6145                	addi	sp,sp,48
    80004412:	8082                	ret

0000000080004414 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004414:	1101                	addi	sp,sp,-32
    80004416:	ec06                	sd	ra,24(sp)
    80004418:	e822                	sd	s0,16(sp)
    8000441a:	e426                	sd	s1,8(sp)
    8000441c:	e04a                	sd	s2,0(sp)
    8000441e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004420:	0001d517          	auipc	a0,0x1d
    80004424:	25050513          	addi	a0,a0,592 # 80021670 <log>
    80004428:	ffffc097          	auipc	ra,0xffffc
    8000442c:	7bc080e7          	jalr	1980(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004430:	0001d497          	auipc	s1,0x1d
    80004434:	24048493          	addi	s1,s1,576 # 80021670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004438:	4979                	li	s2,30
    8000443a:	a039                	j	80004448 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000443c:	85a6                	mv	a1,s1
    8000443e:	8526                	mv	a0,s1
    80004440:	ffffe097          	auipc	ra,0xffffe
    80004444:	cba080e7          	jalr	-838(ra) # 800020fa <sleep>
    if(log.committing){
    80004448:	50dc                	lw	a5,36(s1)
    8000444a:	fbed                	bnez	a5,8000443c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000444c:	509c                	lw	a5,32(s1)
    8000444e:	0017871b          	addiw	a4,a5,1
    80004452:	0007069b          	sext.w	a3,a4
    80004456:	0027179b          	slliw	a5,a4,0x2
    8000445a:	9fb9                	addw	a5,a5,a4
    8000445c:	0017979b          	slliw	a5,a5,0x1
    80004460:	54d8                	lw	a4,44(s1)
    80004462:	9fb9                	addw	a5,a5,a4
    80004464:	00f95963          	bge	s2,a5,80004476 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004468:	85a6                	mv	a1,s1
    8000446a:	8526                	mv	a0,s1
    8000446c:	ffffe097          	auipc	ra,0xffffe
    80004470:	c8e080e7          	jalr	-882(ra) # 800020fa <sleep>
    80004474:	bfd1                	j	80004448 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004476:	0001d517          	auipc	a0,0x1d
    8000447a:	1fa50513          	addi	a0,a0,506 # 80021670 <log>
    8000447e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004480:	ffffd097          	auipc	ra,0xffffd
    80004484:	818080e7          	jalr	-2024(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004488:	60e2                	ld	ra,24(sp)
    8000448a:	6442                	ld	s0,16(sp)
    8000448c:	64a2                	ld	s1,8(sp)
    8000448e:	6902                	ld	s2,0(sp)
    80004490:	6105                	addi	sp,sp,32
    80004492:	8082                	ret

0000000080004494 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004494:	7139                	addi	sp,sp,-64
    80004496:	fc06                	sd	ra,56(sp)
    80004498:	f822                	sd	s0,48(sp)
    8000449a:	f426                	sd	s1,40(sp)
    8000449c:	f04a                	sd	s2,32(sp)
    8000449e:	ec4e                	sd	s3,24(sp)
    800044a0:	e852                	sd	s4,16(sp)
    800044a2:	e456                	sd	s5,8(sp)
    800044a4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800044a6:	0001d497          	auipc	s1,0x1d
    800044aa:	1ca48493          	addi	s1,s1,458 # 80021670 <log>
    800044ae:	8526                	mv	a0,s1
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	734080e7          	jalr	1844(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800044b8:	509c                	lw	a5,32(s1)
    800044ba:	37fd                	addiw	a5,a5,-1
    800044bc:	0007891b          	sext.w	s2,a5
    800044c0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044c2:	50dc                	lw	a5,36(s1)
    800044c4:	efb9                	bnez	a5,80004522 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044c6:	06091663          	bnez	s2,80004532 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800044ca:	0001d497          	auipc	s1,0x1d
    800044ce:	1a648493          	addi	s1,s1,422 # 80021670 <log>
    800044d2:	4785                	li	a5,1
    800044d4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044d6:	8526                	mv	a0,s1
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	7c0080e7          	jalr	1984(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044e0:	54dc                	lw	a5,44(s1)
    800044e2:	06f04763          	bgtz	a5,80004550 <end_op+0xbc>
    acquire(&log.lock);
    800044e6:	0001d497          	auipc	s1,0x1d
    800044ea:	18a48493          	addi	s1,s1,394 # 80021670 <log>
    800044ee:	8526                	mv	a0,s1
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	6f4080e7          	jalr	1780(ra) # 80000be4 <acquire>
    log.committing = 0;
    800044f8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044fc:	8526                	mv	a0,s1
    800044fe:	ffffe097          	auipc	ra,0xffffe
    80004502:	ed4080e7          	jalr	-300(ra) # 800023d2 <wakeup>
    release(&log.lock);
    80004506:	8526                	mv	a0,s1
    80004508:	ffffc097          	auipc	ra,0xffffc
    8000450c:	790080e7          	jalr	1936(ra) # 80000c98 <release>
}
    80004510:	70e2                	ld	ra,56(sp)
    80004512:	7442                	ld	s0,48(sp)
    80004514:	74a2                	ld	s1,40(sp)
    80004516:	7902                	ld	s2,32(sp)
    80004518:	69e2                	ld	s3,24(sp)
    8000451a:	6a42                	ld	s4,16(sp)
    8000451c:	6aa2                	ld	s5,8(sp)
    8000451e:	6121                	addi	sp,sp,64
    80004520:	8082                	ret
    panic("log.committing");
    80004522:	00004517          	auipc	a0,0x4
    80004526:	2b650513          	addi	a0,a0,694 # 800087d8 <syscalls+0x1f0>
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	014080e7          	jalr	20(ra) # 8000053e <panic>
    wakeup(&log);
    80004532:	0001d497          	auipc	s1,0x1d
    80004536:	13e48493          	addi	s1,s1,318 # 80021670 <log>
    8000453a:	8526                	mv	a0,s1
    8000453c:	ffffe097          	auipc	ra,0xffffe
    80004540:	e96080e7          	jalr	-362(ra) # 800023d2 <wakeup>
  release(&log.lock);
    80004544:	8526                	mv	a0,s1
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	752080e7          	jalr	1874(ra) # 80000c98 <release>
  if(do_commit){
    8000454e:	b7c9                	j	80004510 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004550:	0001da97          	auipc	s5,0x1d
    80004554:	150a8a93          	addi	s5,s5,336 # 800216a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004558:	0001da17          	auipc	s4,0x1d
    8000455c:	118a0a13          	addi	s4,s4,280 # 80021670 <log>
    80004560:	018a2583          	lw	a1,24(s4)
    80004564:	012585bb          	addw	a1,a1,s2
    80004568:	2585                	addiw	a1,a1,1
    8000456a:	028a2503          	lw	a0,40(s4)
    8000456e:	fffff097          	auipc	ra,0xfffff
    80004572:	cd2080e7          	jalr	-814(ra) # 80003240 <bread>
    80004576:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004578:	000aa583          	lw	a1,0(s5)
    8000457c:	028a2503          	lw	a0,40(s4)
    80004580:	fffff097          	auipc	ra,0xfffff
    80004584:	cc0080e7          	jalr	-832(ra) # 80003240 <bread>
    80004588:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000458a:	40000613          	li	a2,1024
    8000458e:	05850593          	addi	a1,a0,88
    80004592:	05848513          	addi	a0,s1,88
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	7aa080e7          	jalr	1962(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000459e:	8526                	mv	a0,s1
    800045a0:	fffff097          	auipc	ra,0xfffff
    800045a4:	d92080e7          	jalr	-622(ra) # 80003332 <bwrite>
    brelse(from);
    800045a8:	854e                	mv	a0,s3
    800045aa:	fffff097          	auipc	ra,0xfffff
    800045ae:	dc6080e7          	jalr	-570(ra) # 80003370 <brelse>
    brelse(to);
    800045b2:	8526                	mv	a0,s1
    800045b4:	fffff097          	auipc	ra,0xfffff
    800045b8:	dbc080e7          	jalr	-580(ra) # 80003370 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045bc:	2905                	addiw	s2,s2,1
    800045be:	0a91                	addi	s5,s5,4
    800045c0:	02ca2783          	lw	a5,44(s4)
    800045c4:	f8f94ee3          	blt	s2,a5,80004560 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045c8:	00000097          	auipc	ra,0x0
    800045cc:	c6a080e7          	jalr	-918(ra) # 80004232 <write_head>
    install_trans(0); // Now install writes to home locations
    800045d0:	4501                	li	a0,0
    800045d2:	00000097          	auipc	ra,0x0
    800045d6:	cda080e7          	jalr	-806(ra) # 800042ac <install_trans>
    log.lh.n = 0;
    800045da:	0001d797          	auipc	a5,0x1d
    800045de:	0c07a123          	sw	zero,194(a5) # 8002169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045e2:	00000097          	auipc	ra,0x0
    800045e6:	c50080e7          	jalr	-944(ra) # 80004232 <write_head>
    800045ea:	bdf5                	j	800044e6 <end_op+0x52>

00000000800045ec <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045ec:	1101                	addi	sp,sp,-32
    800045ee:	ec06                	sd	ra,24(sp)
    800045f0:	e822                	sd	s0,16(sp)
    800045f2:	e426                	sd	s1,8(sp)
    800045f4:	e04a                	sd	s2,0(sp)
    800045f6:	1000                	addi	s0,sp,32
    800045f8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045fa:	0001d917          	auipc	s2,0x1d
    800045fe:	07690913          	addi	s2,s2,118 # 80021670 <log>
    80004602:	854a                	mv	a0,s2
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	5e0080e7          	jalr	1504(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000460c:	02c92603          	lw	a2,44(s2)
    80004610:	47f5                	li	a5,29
    80004612:	06c7c563          	blt	a5,a2,8000467c <log_write+0x90>
    80004616:	0001d797          	auipc	a5,0x1d
    8000461a:	0767a783          	lw	a5,118(a5) # 8002168c <log+0x1c>
    8000461e:	37fd                	addiw	a5,a5,-1
    80004620:	04f65e63          	bge	a2,a5,8000467c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004624:	0001d797          	auipc	a5,0x1d
    80004628:	06c7a783          	lw	a5,108(a5) # 80021690 <log+0x20>
    8000462c:	06f05063          	blez	a5,8000468c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004630:	4781                	li	a5,0
    80004632:	06c05563          	blez	a2,8000469c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004636:	44cc                	lw	a1,12(s1)
    80004638:	0001d717          	auipc	a4,0x1d
    8000463c:	06870713          	addi	a4,a4,104 # 800216a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004640:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004642:	4314                	lw	a3,0(a4)
    80004644:	04b68c63          	beq	a3,a1,8000469c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004648:	2785                	addiw	a5,a5,1
    8000464a:	0711                	addi	a4,a4,4
    8000464c:	fef61be3          	bne	a2,a5,80004642 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004650:	0621                	addi	a2,a2,8
    80004652:	060a                	slli	a2,a2,0x2
    80004654:	0001d797          	auipc	a5,0x1d
    80004658:	01c78793          	addi	a5,a5,28 # 80021670 <log>
    8000465c:	963e                	add	a2,a2,a5
    8000465e:	44dc                	lw	a5,12(s1)
    80004660:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004662:	8526                	mv	a0,s1
    80004664:	fffff097          	auipc	ra,0xfffff
    80004668:	daa080e7          	jalr	-598(ra) # 8000340e <bpin>
    log.lh.n++;
    8000466c:	0001d717          	auipc	a4,0x1d
    80004670:	00470713          	addi	a4,a4,4 # 80021670 <log>
    80004674:	575c                	lw	a5,44(a4)
    80004676:	2785                	addiw	a5,a5,1
    80004678:	d75c                	sw	a5,44(a4)
    8000467a:	a835                	j	800046b6 <log_write+0xca>
    panic("too big a transaction");
    8000467c:	00004517          	auipc	a0,0x4
    80004680:	16c50513          	addi	a0,a0,364 # 800087e8 <syscalls+0x200>
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	eba080e7          	jalr	-326(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000468c:	00004517          	auipc	a0,0x4
    80004690:	17450513          	addi	a0,a0,372 # 80008800 <syscalls+0x218>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	eaa080e7          	jalr	-342(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000469c:	00878713          	addi	a4,a5,8
    800046a0:	00271693          	slli	a3,a4,0x2
    800046a4:	0001d717          	auipc	a4,0x1d
    800046a8:	fcc70713          	addi	a4,a4,-52 # 80021670 <log>
    800046ac:	9736                	add	a4,a4,a3
    800046ae:	44d4                	lw	a3,12(s1)
    800046b0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046b2:	faf608e3          	beq	a2,a5,80004662 <log_write+0x76>
  }
  release(&log.lock);
    800046b6:	0001d517          	auipc	a0,0x1d
    800046ba:	fba50513          	addi	a0,a0,-70 # 80021670 <log>
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	5da080e7          	jalr	1498(ra) # 80000c98 <release>
}
    800046c6:	60e2                	ld	ra,24(sp)
    800046c8:	6442                	ld	s0,16(sp)
    800046ca:	64a2                	ld	s1,8(sp)
    800046cc:	6902                	ld	s2,0(sp)
    800046ce:	6105                	addi	sp,sp,32
    800046d0:	8082                	ret

00000000800046d2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046d2:	1101                	addi	sp,sp,-32
    800046d4:	ec06                	sd	ra,24(sp)
    800046d6:	e822                	sd	s0,16(sp)
    800046d8:	e426                	sd	s1,8(sp)
    800046da:	e04a                	sd	s2,0(sp)
    800046dc:	1000                	addi	s0,sp,32
    800046de:	84aa                	mv	s1,a0
    800046e0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046e2:	00004597          	auipc	a1,0x4
    800046e6:	13e58593          	addi	a1,a1,318 # 80008820 <syscalls+0x238>
    800046ea:	0521                	addi	a0,a0,8
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	468080e7          	jalr	1128(ra) # 80000b54 <initlock>
  lk->name = name;
    800046f4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046fc:	0204a423          	sw	zero,40(s1)
}
    80004700:	60e2                	ld	ra,24(sp)
    80004702:	6442                	ld	s0,16(sp)
    80004704:	64a2                	ld	s1,8(sp)
    80004706:	6902                	ld	s2,0(sp)
    80004708:	6105                	addi	sp,sp,32
    8000470a:	8082                	ret

000000008000470c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000470c:	1101                	addi	sp,sp,-32
    8000470e:	ec06                	sd	ra,24(sp)
    80004710:	e822                	sd	s0,16(sp)
    80004712:	e426                	sd	s1,8(sp)
    80004714:	e04a                	sd	s2,0(sp)
    80004716:	1000                	addi	s0,sp,32
    80004718:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000471a:	00850913          	addi	s2,a0,8
    8000471e:	854a                	mv	a0,s2
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	4c4080e7          	jalr	1220(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004728:	409c                	lw	a5,0(s1)
    8000472a:	cb89                	beqz	a5,8000473c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000472c:	85ca                	mv	a1,s2
    8000472e:	8526                	mv	a0,s1
    80004730:	ffffe097          	auipc	ra,0xffffe
    80004734:	9ca080e7          	jalr	-1590(ra) # 800020fa <sleep>
  while (lk->locked) {
    80004738:	409c                	lw	a5,0(s1)
    8000473a:	fbed                	bnez	a5,8000472c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000473c:	4785                	li	a5,1
    8000473e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004740:	ffffd097          	auipc	ra,0xffffd
    80004744:	2ce080e7          	jalr	718(ra) # 80001a0e <myproc>
    80004748:	591c                	lw	a5,48(a0)
    8000474a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000474c:	854a                	mv	a0,s2
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	54a080e7          	jalr	1354(ra) # 80000c98 <release>
}
    80004756:	60e2                	ld	ra,24(sp)
    80004758:	6442                	ld	s0,16(sp)
    8000475a:	64a2                	ld	s1,8(sp)
    8000475c:	6902                	ld	s2,0(sp)
    8000475e:	6105                	addi	sp,sp,32
    80004760:	8082                	ret

0000000080004762 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004762:	1101                	addi	sp,sp,-32
    80004764:	ec06                	sd	ra,24(sp)
    80004766:	e822                	sd	s0,16(sp)
    80004768:	e426                	sd	s1,8(sp)
    8000476a:	e04a                	sd	s2,0(sp)
    8000476c:	1000                	addi	s0,sp,32
    8000476e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004770:	00850913          	addi	s2,a0,8
    80004774:	854a                	mv	a0,s2
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	46e080e7          	jalr	1134(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000477e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004782:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004786:	8526                	mv	a0,s1
    80004788:	ffffe097          	auipc	ra,0xffffe
    8000478c:	c4a080e7          	jalr	-950(ra) # 800023d2 <wakeup>
  release(&lk->lk);
    80004790:	854a                	mv	a0,s2
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	506080e7          	jalr	1286(ra) # 80000c98 <release>
}
    8000479a:	60e2                	ld	ra,24(sp)
    8000479c:	6442                	ld	s0,16(sp)
    8000479e:	64a2                	ld	s1,8(sp)
    800047a0:	6902                	ld	s2,0(sp)
    800047a2:	6105                	addi	sp,sp,32
    800047a4:	8082                	ret

00000000800047a6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800047a6:	7179                	addi	sp,sp,-48
    800047a8:	f406                	sd	ra,40(sp)
    800047aa:	f022                	sd	s0,32(sp)
    800047ac:	ec26                	sd	s1,24(sp)
    800047ae:	e84a                	sd	s2,16(sp)
    800047b0:	e44e                	sd	s3,8(sp)
    800047b2:	1800                	addi	s0,sp,48
    800047b4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047b6:	00850913          	addi	s2,a0,8
    800047ba:	854a                	mv	a0,s2
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	428080e7          	jalr	1064(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047c4:	409c                	lw	a5,0(s1)
    800047c6:	ef99                	bnez	a5,800047e4 <holdingsleep+0x3e>
    800047c8:	4481                	li	s1,0
  release(&lk->lk);
    800047ca:	854a                	mv	a0,s2
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	4cc080e7          	jalr	1228(ra) # 80000c98 <release>
  return r;
}
    800047d4:	8526                	mv	a0,s1
    800047d6:	70a2                	ld	ra,40(sp)
    800047d8:	7402                	ld	s0,32(sp)
    800047da:	64e2                	ld	s1,24(sp)
    800047dc:	6942                	ld	s2,16(sp)
    800047de:	69a2                	ld	s3,8(sp)
    800047e0:	6145                	addi	sp,sp,48
    800047e2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047e4:	0284a983          	lw	s3,40(s1)
    800047e8:	ffffd097          	auipc	ra,0xffffd
    800047ec:	226080e7          	jalr	550(ra) # 80001a0e <myproc>
    800047f0:	5904                	lw	s1,48(a0)
    800047f2:	413484b3          	sub	s1,s1,s3
    800047f6:	0014b493          	seqz	s1,s1
    800047fa:	bfc1                	j	800047ca <holdingsleep+0x24>

00000000800047fc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047fc:	1141                	addi	sp,sp,-16
    800047fe:	e406                	sd	ra,8(sp)
    80004800:	e022                	sd	s0,0(sp)
    80004802:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004804:	00004597          	auipc	a1,0x4
    80004808:	02c58593          	addi	a1,a1,44 # 80008830 <syscalls+0x248>
    8000480c:	0001d517          	auipc	a0,0x1d
    80004810:	fac50513          	addi	a0,a0,-84 # 800217b8 <ftable>
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	340080e7          	jalr	832(ra) # 80000b54 <initlock>
}
    8000481c:	60a2                	ld	ra,8(sp)
    8000481e:	6402                	ld	s0,0(sp)
    80004820:	0141                	addi	sp,sp,16
    80004822:	8082                	ret

0000000080004824 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004824:	1101                	addi	sp,sp,-32
    80004826:	ec06                	sd	ra,24(sp)
    80004828:	e822                	sd	s0,16(sp)
    8000482a:	e426                	sd	s1,8(sp)
    8000482c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000482e:	0001d517          	auipc	a0,0x1d
    80004832:	f8a50513          	addi	a0,a0,-118 # 800217b8 <ftable>
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	3ae080e7          	jalr	942(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000483e:	0001d497          	auipc	s1,0x1d
    80004842:	f9248493          	addi	s1,s1,-110 # 800217d0 <ftable+0x18>
    80004846:	0001e717          	auipc	a4,0x1e
    8000484a:	f2a70713          	addi	a4,a4,-214 # 80022770 <ftable+0xfb8>
    if(f->ref == 0){
    8000484e:	40dc                	lw	a5,4(s1)
    80004850:	cf99                	beqz	a5,8000486e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004852:	02848493          	addi	s1,s1,40
    80004856:	fee49ce3          	bne	s1,a4,8000484e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000485a:	0001d517          	auipc	a0,0x1d
    8000485e:	f5e50513          	addi	a0,a0,-162 # 800217b8 <ftable>
    80004862:	ffffc097          	auipc	ra,0xffffc
    80004866:	436080e7          	jalr	1078(ra) # 80000c98 <release>
  return 0;
    8000486a:	4481                	li	s1,0
    8000486c:	a819                	j	80004882 <filealloc+0x5e>
      f->ref = 1;
    8000486e:	4785                	li	a5,1
    80004870:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004872:	0001d517          	auipc	a0,0x1d
    80004876:	f4650513          	addi	a0,a0,-186 # 800217b8 <ftable>
    8000487a:	ffffc097          	auipc	ra,0xffffc
    8000487e:	41e080e7          	jalr	1054(ra) # 80000c98 <release>
}
    80004882:	8526                	mv	a0,s1
    80004884:	60e2                	ld	ra,24(sp)
    80004886:	6442                	ld	s0,16(sp)
    80004888:	64a2                	ld	s1,8(sp)
    8000488a:	6105                	addi	sp,sp,32
    8000488c:	8082                	ret

000000008000488e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000488e:	1101                	addi	sp,sp,-32
    80004890:	ec06                	sd	ra,24(sp)
    80004892:	e822                	sd	s0,16(sp)
    80004894:	e426                	sd	s1,8(sp)
    80004896:	1000                	addi	s0,sp,32
    80004898:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000489a:	0001d517          	auipc	a0,0x1d
    8000489e:	f1e50513          	addi	a0,a0,-226 # 800217b8 <ftable>
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	342080e7          	jalr	834(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800048aa:	40dc                	lw	a5,4(s1)
    800048ac:	02f05263          	blez	a5,800048d0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048b0:	2785                	addiw	a5,a5,1
    800048b2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048b4:	0001d517          	auipc	a0,0x1d
    800048b8:	f0450513          	addi	a0,a0,-252 # 800217b8 <ftable>
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	3dc080e7          	jalr	988(ra) # 80000c98 <release>
  return f;
}
    800048c4:	8526                	mv	a0,s1
    800048c6:	60e2                	ld	ra,24(sp)
    800048c8:	6442                	ld	s0,16(sp)
    800048ca:	64a2                	ld	s1,8(sp)
    800048cc:	6105                	addi	sp,sp,32
    800048ce:	8082                	ret
    panic("filedup");
    800048d0:	00004517          	auipc	a0,0x4
    800048d4:	f6850513          	addi	a0,a0,-152 # 80008838 <syscalls+0x250>
    800048d8:	ffffc097          	auipc	ra,0xffffc
    800048dc:	c66080e7          	jalr	-922(ra) # 8000053e <panic>

00000000800048e0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048e0:	7139                	addi	sp,sp,-64
    800048e2:	fc06                	sd	ra,56(sp)
    800048e4:	f822                	sd	s0,48(sp)
    800048e6:	f426                	sd	s1,40(sp)
    800048e8:	f04a                	sd	s2,32(sp)
    800048ea:	ec4e                	sd	s3,24(sp)
    800048ec:	e852                	sd	s4,16(sp)
    800048ee:	e456                	sd	s5,8(sp)
    800048f0:	0080                	addi	s0,sp,64
    800048f2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048f4:	0001d517          	auipc	a0,0x1d
    800048f8:	ec450513          	addi	a0,a0,-316 # 800217b8 <ftable>
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	2e8080e7          	jalr	744(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004904:	40dc                	lw	a5,4(s1)
    80004906:	06f05163          	blez	a5,80004968 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000490a:	37fd                	addiw	a5,a5,-1
    8000490c:	0007871b          	sext.w	a4,a5
    80004910:	c0dc                	sw	a5,4(s1)
    80004912:	06e04363          	bgtz	a4,80004978 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004916:	0004a903          	lw	s2,0(s1)
    8000491a:	0094ca83          	lbu	s5,9(s1)
    8000491e:	0104ba03          	ld	s4,16(s1)
    80004922:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004926:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000492a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000492e:	0001d517          	auipc	a0,0x1d
    80004932:	e8a50513          	addi	a0,a0,-374 # 800217b8 <ftable>
    80004936:	ffffc097          	auipc	ra,0xffffc
    8000493a:	362080e7          	jalr	866(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000493e:	4785                	li	a5,1
    80004940:	04f90d63          	beq	s2,a5,8000499a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004944:	3979                	addiw	s2,s2,-2
    80004946:	4785                	li	a5,1
    80004948:	0527e063          	bltu	a5,s2,80004988 <fileclose+0xa8>
    begin_op();
    8000494c:	00000097          	auipc	ra,0x0
    80004950:	ac8080e7          	jalr	-1336(ra) # 80004414 <begin_op>
    iput(ff.ip);
    80004954:	854e                	mv	a0,s3
    80004956:	fffff097          	auipc	ra,0xfffff
    8000495a:	2a6080e7          	jalr	678(ra) # 80003bfc <iput>
    end_op();
    8000495e:	00000097          	auipc	ra,0x0
    80004962:	b36080e7          	jalr	-1226(ra) # 80004494 <end_op>
    80004966:	a00d                	j	80004988 <fileclose+0xa8>
    panic("fileclose");
    80004968:	00004517          	auipc	a0,0x4
    8000496c:	ed850513          	addi	a0,a0,-296 # 80008840 <syscalls+0x258>
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	bce080e7          	jalr	-1074(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004978:	0001d517          	auipc	a0,0x1d
    8000497c:	e4050513          	addi	a0,a0,-448 # 800217b8 <ftable>
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	318080e7          	jalr	792(ra) # 80000c98 <release>
  }
}
    80004988:	70e2                	ld	ra,56(sp)
    8000498a:	7442                	ld	s0,48(sp)
    8000498c:	74a2                	ld	s1,40(sp)
    8000498e:	7902                	ld	s2,32(sp)
    80004990:	69e2                	ld	s3,24(sp)
    80004992:	6a42                	ld	s4,16(sp)
    80004994:	6aa2                	ld	s5,8(sp)
    80004996:	6121                	addi	sp,sp,64
    80004998:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000499a:	85d6                	mv	a1,s5
    8000499c:	8552                	mv	a0,s4
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	34c080e7          	jalr	844(ra) # 80004cea <pipeclose>
    800049a6:	b7cd                	j	80004988 <fileclose+0xa8>

00000000800049a8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800049a8:	715d                	addi	sp,sp,-80
    800049aa:	e486                	sd	ra,72(sp)
    800049ac:	e0a2                	sd	s0,64(sp)
    800049ae:	fc26                	sd	s1,56(sp)
    800049b0:	f84a                	sd	s2,48(sp)
    800049b2:	f44e                	sd	s3,40(sp)
    800049b4:	0880                	addi	s0,sp,80
    800049b6:	84aa                	mv	s1,a0
    800049b8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049ba:	ffffd097          	auipc	ra,0xffffd
    800049be:	054080e7          	jalr	84(ra) # 80001a0e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049c2:	409c                	lw	a5,0(s1)
    800049c4:	37f9                	addiw	a5,a5,-2
    800049c6:	4705                	li	a4,1
    800049c8:	04f76763          	bltu	a4,a5,80004a16 <filestat+0x6e>
    800049cc:	892a                	mv	s2,a0
    ilock(f->ip);
    800049ce:	6c88                	ld	a0,24(s1)
    800049d0:	fffff097          	auipc	ra,0xfffff
    800049d4:	072080e7          	jalr	114(ra) # 80003a42 <ilock>
    stati(f->ip, &st);
    800049d8:	fb840593          	addi	a1,s0,-72
    800049dc:	6c88                	ld	a0,24(s1)
    800049de:	fffff097          	auipc	ra,0xfffff
    800049e2:	2ee080e7          	jalr	750(ra) # 80003ccc <stati>
    iunlock(f->ip);
    800049e6:	6c88                	ld	a0,24(s1)
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	11c080e7          	jalr	284(ra) # 80003b04 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049f0:	46e1                	li	a3,24
    800049f2:	fb840613          	addi	a2,s0,-72
    800049f6:	85ce                	mv	a1,s3
    800049f8:	05093503          	ld	a0,80(s2)
    800049fc:	ffffd097          	auipc	ra,0xffffd
    80004a00:	c76080e7          	jalr	-906(ra) # 80001672 <copyout>
    80004a04:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a08:	60a6                	ld	ra,72(sp)
    80004a0a:	6406                	ld	s0,64(sp)
    80004a0c:	74e2                	ld	s1,56(sp)
    80004a0e:	7942                	ld	s2,48(sp)
    80004a10:	79a2                	ld	s3,40(sp)
    80004a12:	6161                	addi	sp,sp,80
    80004a14:	8082                	ret
  return -1;
    80004a16:	557d                	li	a0,-1
    80004a18:	bfc5                	j	80004a08 <filestat+0x60>

0000000080004a1a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a1a:	7179                	addi	sp,sp,-48
    80004a1c:	f406                	sd	ra,40(sp)
    80004a1e:	f022                	sd	s0,32(sp)
    80004a20:	ec26                	sd	s1,24(sp)
    80004a22:	e84a                	sd	s2,16(sp)
    80004a24:	e44e                	sd	s3,8(sp)
    80004a26:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a28:	00854783          	lbu	a5,8(a0)
    80004a2c:	c3d5                	beqz	a5,80004ad0 <fileread+0xb6>
    80004a2e:	84aa                	mv	s1,a0
    80004a30:	89ae                	mv	s3,a1
    80004a32:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a34:	411c                	lw	a5,0(a0)
    80004a36:	4705                	li	a4,1
    80004a38:	04e78963          	beq	a5,a4,80004a8a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a3c:	470d                	li	a4,3
    80004a3e:	04e78d63          	beq	a5,a4,80004a98 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a42:	4709                	li	a4,2
    80004a44:	06e79e63          	bne	a5,a4,80004ac0 <fileread+0xa6>
    ilock(f->ip);
    80004a48:	6d08                	ld	a0,24(a0)
    80004a4a:	fffff097          	auipc	ra,0xfffff
    80004a4e:	ff8080e7          	jalr	-8(ra) # 80003a42 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a52:	874a                	mv	a4,s2
    80004a54:	5094                	lw	a3,32(s1)
    80004a56:	864e                	mv	a2,s3
    80004a58:	4585                	li	a1,1
    80004a5a:	6c88                	ld	a0,24(s1)
    80004a5c:	fffff097          	auipc	ra,0xfffff
    80004a60:	29a080e7          	jalr	666(ra) # 80003cf6 <readi>
    80004a64:	892a                	mv	s2,a0
    80004a66:	00a05563          	blez	a0,80004a70 <fileread+0x56>
      f->off += r;
    80004a6a:	509c                	lw	a5,32(s1)
    80004a6c:	9fa9                	addw	a5,a5,a0
    80004a6e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a70:	6c88                	ld	a0,24(s1)
    80004a72:	fffff097          	auipc	ra,0xfffff
    80004a76:	092080e7          	jalr	146(ra) # 80003b04 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a7a:	854a                	mv	a0,s2
    80004a7c:	70a2                	ld	ra,40(sp)
    80004a7e:	7402                	ld	s0,32(sp)
    80004a80:	64e2                	ld	s1,24(sp)
    80004a82:	6942                	ld	s2,16(sp)
    80004a84:	69a2                	ld	s3,8(sp)
    80004a86:	6145                	addi	sp,sp,48
    80004a88:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a8a:	6908                	ld	a0,16(a0)
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	3c8080e7          	jalr	968(ra) # 80004e54 <piperead>
    80004a94:	892a                	mv	s2,a0
    80004a96:	b7d5                	j	80004a7a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a98:	02451783          	lh	a5,36(a0)
    80004a9c:	03079693          	slli	a3,a5,0x30
    80004aa0:	92c1                	srli	a3,a3,0x30
    80004aa2:	4725                	li	a4,9
    80004aa4:	02d76863          	bltu	a4,a3,80004ad4 <fileread+0xba>
    80004aa8:	0792                	slli	a5,a5,0x4
    80004aaa:	0001d717          	auipc	a4,0x1d
    80004aae:	c6e70713          	addi	a4,a4,-914 # 80021718 <devsw>
    80004ab2:	97ba                	add	a5,a5,a4
    80004ab4:	639c                	ld	a5,0(a5)
    80004ab6:	c38d                	beqz	a5,80004ad8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ab8:	4505                	li	a0,1
    80004aba:	9782                	jalr	a5
    80004abc:	892a                	mv	s2,a0
    80004abe:	bf75                	j	80004a7a <fileread+0x60>
    panic("fileread");
    80004ac0:	00004517          	auipc	a0,0x4
    80004ac4:	d9050513          	addi	a0,a0,-624 # 80008850 <syscalls+0x268>
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	a76080e7          	jalr	-1418(ra) # 8000053e <panic>
    return -1;
    80004ad0:	597d                	li	s2,-1
    80004ad2:	b765                	j	80004a7a <fileread+0x60>
      return -1;
    80004ad4:	597d                	li	s2,-1
    80004ad6:	b755                	j	80004a7a <fileread+0x60>
    80004ad8:	597d                	li	s2,-1
    80004ada:	b745                	j	80004a7a <fileread+0x60>

0000000080004adc <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004adc:	715d                	addi	sp,sp,-80
    80004ade:	e486                	sd	ra,72(sp)
    80004ae0:	e0a2                	sd	s0,64(sp)
    80004ae2:	fc26                	sd	s1,56(sp)
    80004ae4:	f84a                	sd	s2,48(sp)
    80004ae6:	f44e                	sd	s3,40(sp)
    80004ae8:	f052                	sd	s4,32(sp)
    80004aea:	ec56                	sd	s5,24(sp)
    80004aec:	e85a                	sd	s6,16(sp)
    80004aee:	e45e                	sd	s7,8(sp)
    80004af0:	e062                	sd	s8,0(sp)
    80004af2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004af4:	00954783          	lbu	a5,9(a0)
    80004af8:	10078663          	beqz	a5,80004c04 <filewrite+0x128>
    80004afc:	892a                	mv	s2,a0
    80004afe:	8aae                	mv	s5,a1
    80004b00:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b02:	411c                	lw	a5,0(a0)
    80004b04:	4705                	li	a4,1
    80004b06:	02e78263          	beq	a5,a4,80004b2a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b0a:	470d                	li	a4,3
    80004b0c:	02e78663          	beq	a5,a4,80004b38 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b10:	4709                	li	a4,2
    80004b12:	0ee79163          	bne	a5,a4,80004bf4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b16:	0ac05d63          	blez	a2,80004bd0 <filewrite+0xf4>
    int i = 0;
    80004b1a:	4981                	li	s3,0
    80004b1c:	6b05                	lui	s6,0x1
    80004b1e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b22:	6b85                	lui	s7,0x1
    80004b24:	c00b8b9b          	addiw	s7,s7,-1024
    80004b28:	a861                	j	80004bc0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b2a:	6908                	ld	a0,16(a0)
    80004b2c:	00000097          	auipc	ra,0x0
    80004b30:	22e080e7          	jalr	558(ra) # 80004d5a <pipewrite>
    80004b34:	8a2a                	mv	s4,a0
    80004b36:	a045                	j	80004bd6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b38:	02451783          	lh	a5,36(a0)
    80004b3c:	03079693          	slli	a3,a5,0x30
    80004b40:	92c1                	srli	a3,a3,0x30
    80004b42:	4725                	li	a4,9
    80004b44:	0cd76263          	bltu	a4,a3,80004c08 <filewrite+0x12c>
    80004b48:	0792                	slli	a5,a5,0x4
    80004b4a:	0001d717          	auipc	a4,0x1d
    80004b4e:	bce70713          	addi	a4,a4,-1074 # 80021718 <devsw>
    80004b52:	97ba                	add	a5,a5,a4
    80004b54:	679c                	ld	a5,8(a5)
    80004b56:	cbdd                	beqz	a5,80004c0c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b58:	4505                	li	a0,1
    80004b5a:	9782                	jalr	a5
    80004b5c:	8a2a                	mv	s4,a0
    80004b5e:	a8a5                	j	80004bd6 <filewrite+0xfa>
    80004b60:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b64:	00000097          	auipc	ra,0x0
    80004b68:	8b0080e7          	jalr	-1872(ra) # 80004414 <begin_op>
      ilock(f->ip);
    80004b6c:	01893503          	ld	a0,24(s2)
    80004b70:	fffff097          	auipc	ra,0xfffff
    80004b74:	ed2080e7          	jalr	-302(ra) # 80003a42 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b78:	8762                	mv	a4,s8
    80004b7a:	02092683          	lw	a3,32(s2)
    80004b7e:	01598633          	add	a2,s3,s5
    80004b82:	4585                	li	a1,1
    80004b84:	01893503          	ld	a0,24(s2)
    80004b88:	fffff097          	auipc	ra,0xfffff
    80004b8c:	266080e7          	jalr	614(ra) # 80003dee <writei>
    80004b90:	84aa                	mv	s1,a0
    80004b92:	00a05763          	blez	a0,80004ba0 <filewrite+0xc4>
        f->off += r;
    80004b96:	02092783          	lw	a5,32(s2)
    80004b9a:	9fa9                	addw	a5,a5,a0
    80004b9c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ba0:	01893503          	ld	a0,24(s2)
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	f60080e7          	jalr	-160(ra) # 80003b04 <iunlock>
      end_op();
    80004bac:	00000097          	auipc	ra,0x0
    80004bb0:	8e8080e7          	jalr	-1816(ra) # 80004494 <end_op>

      if(r != n1){
    80004bb4:	009c1f63          	bne	s8,s1,80004bd2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004bb8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004bbc:	0149db63          	bge	s3,s4,80004bd2 <filewrite+0xf6>
      int n1 = n - i;
    80004bc0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004bc4:	84be                	mv	s1,a5
    80004bc6:	2781                	sext.w	a5,a5
    80004bc8:	f8fb5ce3          	bge	s6,a5,80004b60 <filewrite+0x84>
    80004bcc:	84de                	mv	s1,s7
    80004bce:	bf49                	j	80004b60 <filewrite+0x84>
    int i = 0;
    80004bd0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004bd2:	013a1f63          	bne	s4,s3,80004bf0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bd6:	8552                	mv	a0,s4
    80004bd8:	60a6                	ld	ra,72(sp)
    80004bda:	6406                	ld	s0,64(sp)
    80004bdc:	74e2                	ld	s1,56(sp)
    80004bde:	7942                	ld	s2,48(sp)
    80004be0:	79a2                	ld	s3,40(sp)
    80004be2:	7a02                	ld	s4,32(sp)
    80004be4:	6ae2                	ld	s5,24(sp)
    80004be6:	6b42                	ld	s6,16(sp)
    80004be8:	6ba2                	ld	s7,8(sp)
    80004bea:	6c02                	ld	s8,0(sp)
    80004bec:	6161                	addi	sp,sp,80
    80004bee:	8082                	ret
    ret = (i == n ? n : -1);
    80004bf0:	5a7d                	li	s4,-1
    80004bf2:	b7d5                	j	80004bd6 <filewrite+0xfa>
    panic("filewrite");
    80004bf4:	00004517          	auipc	a0,0x4
    80004bf8:	c6c50513          	addi	a0,a0,-916 # 80008860 <syscalls+0x278>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	942080e7          	jalr	-1726(ra) # 8000053e <panic>
    return -1;
    80004c04:	5a7d                	li	s4,-1
    80004c06:	bfc1                	j	80004bd6 <filewrite+0xfa>
      return -1;
    80004c08:	5a7d                	li	s4,-1
    80004c0a:	b7f1                	j	80004bd6 <filewrite+0xfa>
    80004c0c:	5a7d                	li	s4,-1
    80004c0e:	b7e1                	j	80004bd6 <filewrite+0xfa>

0000000080004c10 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c10:	7179                	addi	sp,sp,-48
    80004c12:	f406                	sd	ra,40(sp)
    80004c14:	f022                	sd	s0,32(sp)
    80004c16:	ec26                	sd	s1,24(sp)
    80004c18:	e84a                	sd	s2,16(sp)
    80004c1a:	e44e                	sd	s3,8(sp)
    80004c1c:	e052                	sd	s4,0(sp)
    80004c1e:	1800                	addi	s0,sp,48
    80004c20:	84aa                	mv	s1,a0
    80004c22:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c24:	0005b023          	sd	zero,0(a1)
    80004c28:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c2c:	00000097          	auipc	ra,0x0
    80004c30:	bf8080e7          	jalr	-1032(ra) # 80004824 <filealloc>
    80004c34:	e088                	sd	a0,0(s1)
    80004c36:	c551                	beqz	a0,80004cc2 <pipealloc+0xb2>
    80004c38:	00000097          	auipc	ra,0x0
    80004c3c:	bec080e7          	jalr	-1044(ra) # 80004824 <filealloc>
    80004c40:	00aa3023          	sd	a0,0(s4)
    80004c44:	c92d                	beqz	a0,80004cb6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	eae080e7          	jalr	-338(ra) # 80000af4 <kalloc>
    80004c4e:	892a                	mv	s2,a0
    80004c50:	c125                	beqz	a0,80004cb0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c52:	4985                	li	s3,1
    80004c54:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c58:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c5c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c60:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c64:	00004597          	auipc	a1,0x4
    80004c68:	8d458593          	addi	a1,a1,-1836 # 80008538 <states.1738+0x270>
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	ee8080e7          	jalr	-280(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004c74:	609c                	ld	a5,0(s1)
    80004c76:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c7a:	609c                	ld	a5,0(s1)
    80004c7c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c80:	609c                	ld	a5,0(s1)
    80004c82:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c86:	609c                	ld	a5,0(s1)
    80004c88:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c8c:	000a3783          	ld	a5,0(s4)
    80004c90:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c94:	000a3783          	ld	a5,0(s4)
    80004c98:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c9c:	000a3783          	ld	a5,0(s4)
    80004ca0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ca4:	000a3783          	ld	a5,0(s4)
    80004ca8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004cac:	4501                	li	a0,0
    80004cae:	a025                	j	80004cd6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004cb0:	6088                	ld	a0,0(s1)
    80004cb2:	e501                	bnez	a0,80004cba <pipealloc+0xaa>
    80004cb4:	a039                	j	80004cc2 <pipealloc+0xb2>
    80004cb6:	6088                	ld	a0,0(s1)
    80004cb8:	c51d                	beqz	a0,80004ce6 <pipealloc+0xd6>
    fileclose(*f0);
    80004cba:	00000097          	auipc	ra,0x0
    80004cbe:	c26080e7          	jalr	-986(ra) # 800048e0 <fileclose>
  if(*f1)
    80004cc2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004cc6:	557d                	li	a0,-1
  if(*f1)
    80004cc8:	c799                	beqz	a5,80004cd6 <pipealloc+0xc6>
    fileclose(*f1);
    80004cca:	853e                	mv	a0,a5
    80004ccc:	00000097          	auipc	ra,0x0
    80004cd0:	c14080e7          	jalr	-1004(ra) # 800048e0 <fileclose>
  return -1;
    80004cd4:	557d                	li	a0,-1
}
    80004cd6:	70a2                	ld	ra,40(sp)
    80004cd8:	7402                	ld	s0,32(sp)
    80004cda:	64e2                	ld	s1,24(sp)
    80004cdc:	6942                	ld	s2,16(sp)
    80004cde:	69a2                	ld	s3,8(sp)
    80004ce0:	6a02                	ld	s4,0(sp)
    80004ce2:	6145                	addi	sp,sp,48
    80004ce4:	8082                	ret
  return -1;
    80004ce6:	557d                	li	a0,-1
    80004ce8:	b7fd                	j	80004cd6 <pipealloc+0xc6>

0000000080004cea <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004cea:	1101                	addi	sp,sp,-32
    80004cec:	ec06                	sd	ra,24(sp)
    80004cee:	e822                	sd	s0,16(sp)
    80004cf0:	e426                	sd	s1,8(sp)
    80004cf2:	e04a                	sd	s2,0(sp)
    80004cf4:	1000                	addi	s0,sp,32
    80004cf6:	84aa                	mv	s1,a0
    80004cf8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	eea080e7          	jalr	-278(ra) # 80000be4 <acquire>
  if(writable){
    80004d02:	02090d63          	beqz	s2,80004d3c <pipeclose+0x52>
    pi->writeopen = 0;
    80004d06:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d0a:	21848513          	addi	a0,s1,536
    80004d0e:	ffffd097          	auipc	ra,0xffffd
    80004d12:	6c4080e7          	jalr	1732(ra) # 800023d2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d16:	2204b783          	ld	a5,544(s1)
    80004d1a:	eb95                	bnez	a5,80004d4e <pipeclose+0x64>
    release(&pi->lock);
    80004d1c:	8526                	mv	a0,s1
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	f7a080e7          	jalr	-134(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004d26:	8526                	mv	a0,s1
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	cd0080e7          	jalr	-816(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004d30:	60e2                	ld	ra,24(sp)
    80004d32:	6442                	ld	s0,16(sp)
    80004d34:	64a2                	ld	s1,8(sp)
    80004d36:	6902                	ld	s2,0(sp)
    80004d38:	6105                	addi	sp,sp,32
    80004d3a:	8082                	ret
    pi->readopen = 0;
    80004d3c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d40:	21c48513          	addi	a0,s1,540
    80004d44:	ffffd097          	auipc	ra,0xffffd
    80004d48:	68e080e7          	jalr	1678(ra) # 800023d2 <wakeup>
    80004d4c:	b7e9                	j	80004d16 <pipeclose+0x2c>
    release(&pi->lock);
    80004d4e:	8526                	mv	a0,s1
    80004d50:	ffffc097          	auipc	ra,0xffffc
    80004d54:	f48080e7          	jalr	-184(ra) # 80000c98 <release>
}
    80004d58:	bfe1                	j	80004d30 <pipeclose+0x46>

0000000080004d5a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d5a:	7159                	addi	sp,sp,-112
    80004d5c:	f486                	sd	ra,104(sp)
    80004d5e:	f0a2                	sd	s0,96(sp)
    80004d60:	eca6                	sd	s1,88(sp)
    80004d62:	e8ca                	sd	s2,80(sp)
    80004d64:	e4ce                	sd	s3,72(sp)
    80004d66:	e0d2                	sd	s4,64(sp)
    80004d68:	fc56                	sd	s5,56(sp)
    80004d6a:	f85a                	sd	s6,48(sp)
    80004d6c:	f45e                	sd	s7,40(sp)
    80004d6e:	f062                	sd	s8,32(sp)
    80004d70:	ec66                	sd	s9,24(sp)
    80004d72:	1880                	addi	s0,sp,112
    80004d74:	84aa                	mv	s1,a0
    80004d76:	8aae                	mv	s5,a1
    80004d78:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d7a:	ffffd097          	auipc	ra,0xffffd
    80004d7e:	c94080e7          	jalr	-876(ra) # 80001a0e <myproc>
    80004d82:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d84:	8526                	mv	a0,s1
    80004d86:	ffffc097          	auipc	ra,0xffffc
    80004d8a:	e5e080e7          	jalr	-418(ra) # 80000be4 <acquire>
  while(i < n){
    80004d8e:	0d405163          	blez	s4,80004e50 <pipewrite+0xf6>
    80004d92:	8ba6                	mv	s7,s1
  int i = 0;
    80004d94:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d96:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d98:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d9c:	21c48c13          	addi	s8,s1,540
    80004da0:	a08d                	j	80004e02 <pipewrite+0xa8>
      release(&pi->lock);
    80004da2:	8526                	mv	a0,s1
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	ef4080e7          	jalr	-268(ra) # 80000c98 <release>
      return -1;
    80004dac:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004dae:	854a                	mv	a0,s2
    80004db0:	70a6                	ld	ra,104(sp)
    80004db2:	7406                	ld	s0,96(sp)
    80004db4:	64e6                	ld	s1,88(sp)
    80004db6:	6946                	ld	s2,80(sp)
    80004db8:	69a6                	ld	s3,72(sp)
    80004dba:	6a06                	ld	s4,64(sp)
    80004dbc:	7ae2                	ld	s5,56(sp)
    80004dbe:	7b42                	ld	s6,48(sp)
    80004dc0:	7ba2                	ld	s7,40(sp)
    80004dc2:	7c02                	ld	s8,32(sp)
    80004dc4:	6ce2                	ld	s9,24(sp)
    80004dc6:	6165                	addi	sp,sp,112
    80004dc8:	8082                	ret
      wakeup(&pi->nread);
    80004dca:	8566                	mv	a0,s9
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	606080e7          	jalr	1542(ra) # 800023d2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004dd4:	85de                	mv	a1,s7
    80004dd6:	8562                	mv	a0,s8
    80004dd8:	ffffd097          	auipc	ra,0xffffd
    80004ddc:	322080e7          	jalr	802(ra) # 800020fa <sleep>
    80004de0:	a839                	j	80004dfe <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004de2:	21c4a783          	lw	a5,540(s1)
    80004de6:	0017871b          	addiw	a4,a5,1
    80004dea:	20e4ae23          	sw	a4,540(s1)
    80004dee:	1ff7f793          	andi	a5,a5,511
    80004df2:	97a6                	add	a5,a5,s1
    80004df4:	f9f44703          	lbu	a4,-97(s0)
    80004df8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004dfc:	2905                	addiw	s2,s2,1
  while(i < n){
    80004dfe:	03495d63          	bge	s2,s4,80004e38 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004e02:	2204a783          	lw	a5,544(s1)
    80004e06:	dfd1                	beqz	a5,80004da2 <pipewrite+0x48>
    80004e08:	0289a783          	lw	a5,40(s3)
    80004e0c:	fbd9                	bnez	a5,80004da2 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e0e:	2184a783          	lw	a5,536(s1)
    80004e12:	21c4a703          	lw	a4,540(s1)
    80004e16:	2007879b          	addiw	a5,a5,512
    80004e1a:	faf708e3          	beq	a4,a5,80004dca <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e1e:	4685                	li	a3,1
    80004e20:	01590633          	add	a2,s2,s5
    80004e24:	f9f40593          	addi	a1,s0,-97
    80004e28:	0509b503          	ld	a0,80(s3)
    80004e2c:	ffffd097          	auipc	ra,0xffffd
    80004e30:	8d2080e7          	jalr	-1838(ra) # 800016fe <copyin>
    80004e34:	fb6517e3          	bne	a0,s6,80004de2 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004e38:	21848513          	addi	a0,s1,536
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	596080e7          	jalr	1430(ra) # 800023d2 <wakeup>
  release(&pi->lock);
    80004e44:	8526                	mv	a0,s1
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	e52080e7          	jalr	-430(ra) # 80000c98 <release>
  return i;
    80004e4e:	b785                	j	80004dae <pipewrite+0x54>
  int i = 0;
    80004e50:	4901                	li	s2,0
    80004e52:	b7dd                	j	80004e38 <pipewrite+0xde>

0000000080004e54 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e54:	715d                	addi	sp,sp,-80
    80004e56:	e486                	sd	ra,72(sp)
    80004e58:	e0a2                	sd	s0,64(sp)
    80004e5a:	fc26                	sd	s1,56(sp)
    80004e5c:	f84a                	sd	s2,48(sp)
    80004e5e:	f44e                	sd	s3,40(sp)
    80004e60:	f052                	sd	s4,32(sp)
    80004e62:	ec56                	sd	s5,24(sp)
    80004e64:	e85a                	sd	s6,16(sp)
    80004e66:	0880                	addi	s0,sp,80
    80004e68:	84aa                	mv	s1,a0
    80004e6a:	892e                	mv	s2,a1
    80004e6c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e6e:	ffffd097          	auipc	ra,0xffffd
    80004e72:	ba0080e7          	jalr	-1120(ra) # 80001a0e <myproc>
    80004e76:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e78:	8b26                	mv	s6,s1
    80004e7a:	8526                	mv	a0,s1
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	d68080e7          	jalr	-664(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e84:	2184a703          	lw	a4,536(s1)
    80004e88:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e8c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e90:	02f71463          	bne	a4,a5,80004eb8 <piperead+0x64>
    80004e94:	2244a783          	lw	a5,548(s1)
    80004e98:	c385                	beqz	a5,80004eb8 <piperead+0x64>
    if(pr->killed){
    80004e9a:	028a2783          	lw	a5,40(s4)
    80004e9e:	ebc1                	bnez	a5,80004f2e <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ea0:	85da                	mv	a1,s6
    80004ea2:	854e                	mv	a0,s3
    80004ea4:	ffffd097          	auipc	ra,0xffffd
    80004ea8:	256080e7          	jalr	598(ra) # 800020fa <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004eac:	2184a703          	lw	a4,536(s1)
    80004eb0:	21c4a783          	lw	a5,540(s1)
    80004eb4:	fef700e3          	beq	a4,a5,80004e94 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eb8:	09505263          	blez	s5,80004f3c <piperead+0xe8>
    80004ebc:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ebe:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ec0:	2184a783          	lw	a5,536(s1)
    80004ec4:	21c4a703          	lw	a4,540(s1)
    80004ec8:	02f70d63          	beq	a4,a5,80004f02 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ecc:	0017871b          	addiw	a4,a5,1
    80004ed0:	20e4ac23          	sw	a4,536(s1)
    80004ed4:	1ff7f793          	andi	a5,a5,511
    80004ed8:	97a6                	add	a5,a5,s1
    80004eda:	0187c783          	lbu	a5,24(a5)
    80004ede:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ee2:	4685                	li	a3,1
    80004ee4:	fbf40613          	addi	a2,s0,-65
    80004ee8:	85ca                	mv	a1,s2
    80004eea:	050a3503          	ld	a0,80(s4)
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	784080e7          	jalr	1924(ra) # 80001672 <copyout>
    80004ef6:	01650663          	beq	a0,s6,80004f02 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004efa:	2985                	addiw	s3,s3,1
    80004efc:	0905                	addi	s2,s2,1
    80004efe:	fd3a91e3          	bne	s5,s3,80004ec0 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f02:	21c48513          	addi	a0,s1,540
    80004f06:	ffffd097          	auipc	ra,0xffffd
    80004f0a:	4cc080e7          	jalr	1228(ra) # 800023d2 <wakeup>
  release(&pi->lock);
    80004f0e:	8526                	mv	a0,s1
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	d88080e7          	jalr	-632(ra) # 80000c98 <release>
  return i;
}
    80004f18:	854e                	mv	a0,s3
    80004f1a:	60a6                	ld	ra,72(sp)
    80004f1c:	6406                	ld	s0,64(sp)
    80004f1e:	74e2                	ld	s1,56(sp)
    80004f20:	7942                	ld	s2,48(sp)
    80004f22:	79a2                	ld	s3,40(sp)
    80004f24:	7a02                	ld	s4,32(sp)
    80004f26:	6ae2                	ld	s5,24(sp)
    80004f28:	6b42                	ld	s6,16(sp)
    80004f2a:	6161                	addi	sp,sp,80
    80004f2c:	8082                	ret
      release(&pi->lock);
    80004f2e:	8526                	mv	a0,s1
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	d68080e7          	jalr	-664(ra) # 80000c98 <release>
      return -1;
    80004f38:	59fd                	li	s3,-1
    80004f3a:	bff9                	j	80004f18 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f3c:	4981                	li	s3,0
    80004f3e:	b7d1                	j	80004f02 <piperead+0xae>

0000000080004f40 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004f40:	df010113          	addi	sp,sp,-528
    80004f44:	20113423          	sd	ra,520(sp)
    80004f48:	20813023          	sd	s0,512(sp)
    80004f4c:	ffa6                	sd	s1,504(sp)
    80004f4e:	fbca                	sd	s2,496(sp)
    80004f50:	f7ce                	sd	s3,488(sp)
    80004f52:	f3d2                	sd	s4,480(sp)
    80004f54:	efd6                	sd	s5,472(sp)
    80004f56:	ebda                	sd	s6,464(sp)
    80004f58:	e7de                	sd	s7,456(sp)
    80004f5a:	e3e2                	sd	s8,448(sp)
    80004f5c:	ff66                	sd	s9,440(sp)
    80004f5e:	fb6a                	sd	s10,432(sp)
    80004f60:	f76e                	sd	s11,424(sp)
    80004f62:	0c00                	addi	s0,sp,528
    80004f64:	84aa                	mv	s1,a0
    80004f66:	dea43c23          	sd	a0,-520(s0)
    80004f6a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f6e:	ffffd097          	auipc	ra,0xffffd
    80004f72:	aa0080e7          	jalr	-1376(ra) # 80001a0e <myproc>
    80004f76:	892a                	mv	s2,a0

  begin_op();
    80004f78:	fffff097          	auipc	ra,0xfffff
    80004f7c:	49c080e7          	jalr	1180(ra) # 80004414 <begin_op>

  if((ip = namei(path)) == 0){
    80004f80:	8526                	mv	a0,s1
    80004f82:	fffff097          	auipc	ra,0xfffff
    80004f86:	276080e7          	jalr	630(ra) # 800041f8 <namei>
    80004f8a:	c92d                	beqz	a0,80004ffc <exec+0xbc>
    80004f8c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f8e:	fffff097          	auipc	ra,0xfffff
    80004f92:	ab4080e7          	jalr	-1356(ra) # 80003a42 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f96:	04000713          	li	a4,64
    80004f9a:	4681                	li	a3,0
    80004f9c:	e5040613          	addi	a2,s0,-432
    80004fa0:	4581                	li	a1,0
    80004fa2:	8526                	mv	a0,s1
    80004fa4:	fffff097          	auipc	ra,0xfffff
    80004fa8:	d52080e7          	jalr	-686(ra) # 80003cf6 <readi>
    80004fac:	04000793          	li	a5,64
    80004fb0:	00f51a63          	bne	a0,a5,80004fc4 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004fb4:	e5042703          	lw	a4,-432(s0)
    80004fb8:	464c47b7          	lui	a5,0x464c4
    80004fbc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fc0:	04f70463          	beq	a4,a5,80005008 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	fffff097          	auipc	ra,0xfffff
    80004fca:	cde080e7          	jalr	-802(ra) # 80003ca4 <iunlockput>
    end_op();
    80004fce:	fffff097          	auipc	ra,0xfffff
    80004fd2:	4c6080e7          	jalr	1222(ra) # 80004494 <end_op>
  }
  return -1;
    80004fd6:	557d                	li	a0,-1
}
    80004fd8:	20813083          	ld	ra,520(sp)
    80004fdc:	20013403          	ld	s0,512(sp)
    80004fe0:	74fe                	ld	s1,504(sp)
    80004fe2:	795e                	ld	s2,496(sp)
    80004fe4:	79be                	ld	s3,488(sp)
    80004fe6:	7a1e                	ld	s4,480(sp)
    80004fe8:	6afe                	ld	s5,472(sp)
    80004fea:	6b5e                	ld	s6,464(sp)
    80004fec:	6bbe                	ld	s7,456(sp)
    80004fee:	6c1e                	ld	s8,448(sp)
    80004ff0:	7cfa                	ld	s9,440(sp)
    80004ff2:	7d5a                	ld	s10,432(sp)
    80004ff4:	7dba                	ld	s11,424(sp)
    80004ff6:	21010113          	addi	sp,sp,528
    80004ffa:	8082                	ret
    end_op();
    80004ffc:	fffff097          	auipc	ra,0xfffff
    80005000:	498080e7          	jalr	1176(ra) # 80004494 <end_op>
    return -1;
    80005004:	557d                	li	a0,-1
    80005006:	bfc9                	j	80004fd8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005008:	854a                	mv	a0,s2
    8000500a:	ffffd097          	auipc	ra,0xffffd
    8000500e:	ac8080e7          	jalr	-1336(ra) # 80001ad2 <proc_pagetable>
    80005012:	8baa                	mv	s7,a0
    80005014:	d945                	beqz	a0,80004fc4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005016:	e7042983          	lw	s3,-400(s0)
    8000501a:	e8845783          	lhu	a5,-376(s0)
    8000501e:	c7ad                	beqz	a5,80005088 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005020:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005022:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005024:	6c85                	lui	s9,0x1
    80005026:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000502a:	def43823          	sd	a5,-528(s0)
    8000502e:	a42d                	j	80005258 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005030:	00004517          	auipc	a0,0x4
    80005034:	84050513          	addi	a0,a0,-1984 # 80008870 <syscalls+0x288>
    80005038:	ffffb097          	auipc	ra,0xffffb
    8000503c:	506080e7          	jalr	1286(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005040:	8756                	mv	a4,s5
    80005042:	012d86bb          	addw	a3,s11,s2
    80005046:	4581                	li	a1,0
    80005048:	8526                	mv	a0,s1
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	cac080e7          	jalr	-852(ra) # 80003cf6 <readi>
    80005052:	2501                	sext.w	a0,a0
    80005054:	1aaa9963          	bne	s5,a0,80005206 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005058:	6785                	lui	a5,0x1
    8000505a:	0127893b          	addw	s2,a5,s2
    8000505e:	77fd                	lui	a5,0xfffff
    80005060:	01478a3b          	addw	s4,a5,s4
    80005064:	1f897163          	bgeu	s2,s8,80005246 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005068:	02091593          	slli	a1,s2,0x20
    8000506c:	9181                	srli	a1,a1,0x20
    8000506e:	95ea                	add	a1,a1,s10
    80005070:	855e                	mv	a0,s7
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	ffc080e7          	jalr	-4(ra) # 8000106e <walkaddr>
    8000507a:	862a                	mv	a2,a0
    if(pa == 0)
    8000507c:	d955                	beqz	a0,80005030 <exec+0xf0>
      n = PGSIZE;
    8000507e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005080:	fd9a70e3          	bgeu	s4,s9,80005040 <exec+0x100>
      n = sz - i;
    80005084:	8ad2                	mv	s5,s4
    80005086:	bf6d                	j	80005040 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005088:	4901                	li	s2,0
  iunlockput(ip);
    8000508a:	8526                	mv	a0,s1
    8000508c:	fffff097          	auipc	ra,0xfffff
    80005090:	c18080e7          	jalr	-1000(ra) # 80003ca4 <iunlockput>
  end_op();
    80005094:	fffff097          	auipc	ra,0xfffff
    80005098:	400080e7          	jalr	1024(ra) # 80004494 <end_op>
  p = myproc();
    8000509c:	ffffd097          	auipc	ra,0xffffd
    800050a0:	972080e7          	jalr	-1678(ra) # 80001a0e <myproc>
    800050a4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800050a6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800050aa:	6785                	lui	a5,0x1
    800050ac:	17fd                	addi	a5,a5,-1
    800050ae:	993e                	add	s2,s2,a5
    800050b0:	757d                	lui	a0,0xfffff
    800050b2:	00a977b3          	and	a5,s2,a0
    800050b6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800050ba:	6609                	lui	a2,0x2
    800050bc:	963e                	add	a2,a2,a5
    800050be:	85be                	mv	a1,a5
    800050c0:	855e                	mv	a0,s7
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	360080e7          	jalr	864(ra) # 80001422 <uvmalloc>
    800050ca:	8b2a                	mv	s6,a0
  ip = 0;
    800050cc:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800050ce:	12050c63          	beqz	a0,80005206 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050d2:	75f9                	lui	a1,0xffffe
    800050d4:	95aa                	add	a1,a1,a0
    800050d6:	855e                	mv	a0,s7
    800050d8:	ffffc097          	auipc	ra,0xffffc
    800050dc:	568080e7          	jalr	1384(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800050e0:	7c7d                	lui	s8,0xfffff
    800050e2:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800050e4:	e0043783          	ld	a5,-512(s0)
    800050e8:	6388                	ld	a0,0(a5)
    800050ea:	c535                	beqz	a0,80005156 <exec+0x216>
    800050ec:	e9040993          	addi	s3,s0,-368
    800050f0:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800050f4:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800050f6:	ffffc097          	auipc	ra,0xffffc
    800050fa:	d6e080e7          	jalr	-658(ra) # 80000e64 <strlen>
    800050fe:	2505                	addiw	a0,a0,1
    80005100:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005104:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005108:	13896363          	bltu	s2,s8,8000522e <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000510c:	e0043d83          	ld	s11,-512(s0)
    80005110:	000dba03          	ld	s4,0(s11)
    80005114:	8552                	mv	a0,s4
    80005116:	ffffc097          	auipc	ra,0xffffc
    8000511a:	d4e080e7          	jalr	-690(ra) # 80000e64 <strlen>
    8000511e:	0015069b          	addiw	a3,a0,1
    80005122:	8652                	mv	a2,s4
    80005124:	85ca                	mv	a1,s2
    80005126:	855e                	mv	a0,s7
    80005128:	ffffc097          	auipc	ra,0xffffc
    8000512c:	54a080e7          	jalr	1354(ra) # 80001672 <copyout>
    80005130:	10054363          	bltz	a0,80005236 <exec+0x2f6>
    ustack[argc] = sp;
    80005134:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005138:	0485                	addi	s1,s1,1
    8000513a:	008d8793          	addi	a5,s11,8
    8000513e:	e0f43023          	sd	a5,-512(s0)
    80005142:	008db503          	ld	a0,8(s11)
    80005146:	c911                	beqz	a0,8000515a <exec+0x21a>
    if(argc >= MAXARG)
    80005148:	09a1                	addi	s3,s3,8
    8000514a:	fb3c96e3          	bne	s9,s3,800050f6 <exec+0x1b6>
  sz = sz1;
    8000514e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005152:	4481                	li	s1,0
    80005154:	a84d                	j	80005206 <exec+0x2c6>
  sp = sz;
    80005156:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005158:	4481                	li	s1,0
  ustack[argc] = 0;
    8000515a:	00349793          	slli	a5,s1,0x3
    8000515e:	f9040713          	addi	a4,s0,-112
    80005162:	97ba                	add	a5,a5,a4
    80005164:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005168:	00148693          	addi	a3,s1,1
    8000516c:	068e                	slli	a3,a3,0x3
    8000516e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005172:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005176:	01897663          	bgeu	s2,s8,80005182 <exec+0x242>
  sz = sz1;
    8000517a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000517e:	4481                	li	s1,0
    80005180:	a059                	j	80005206 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005182:	e9040613          	addi	a2,s0,-368
    80005186:	85ca                	mv	a1,s2
    80005188:	855e                	mv	a0,s7
    8000518a:	ffffc097          	auipc	ra,0xffffc
    8000518e:	4e8080e7          	jalr	1256(ra) # 80001672 <copyout>
    80005192:	0a054663          	bltz	a0,8000523e <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005196:	058ab783          	ld	a5,88(s5)
    8000519a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000519e:	df843783          	ld	a5,-520(s0)
    800051a2:	0007c703          	lbu	a4,0(a5)
    800051a6:	cf11                	beqz	a4,800051c2 <exec+0x282>
    800051a8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800051aa:	02f00693          	li	a3,47
    800051ae:	a039                	j	800051bc <exec+0x27c>
      last = s+1;
    800051b0:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800051b4:	0785                	addi	a5,a5,1
    800051b6:	fff7c703          	lbu	a4,-1(a5)
    800051ba:	c701                	beqz	a4,800051c2 <exec+0x282>
    if(*s == '/')
    800051bc:	fed71ce3          	bne	a4,a3,800051b4 <exec+0x274>
    800051c0:	bfc5                	j	800051b0 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800051c2:	4641                	li	a2,16
    800051c4:	df843583          	ld	a1,-520(s0)
    800051c8:	158a8513          	addi	a0,s5,344
    800051cc:	ffffc097          	auipc	ra,0xffffc
    800051d0:	c66080e7          	jalr	-922(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800051d4:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800051d8:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800051dc:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051e0:	058ab783          	ld	a5,88(s5)
    800051e4:	e6843703          	ld	a4,-408(s0)
    800051e8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051ea:	058ab783          	ld	a5,88(s5)
    800051ee:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051f2:	85ea                	mv	a1,s10
    800051f4:	ffffd097          	auipc	ra,0xffffd
    800051f8:	97a080e7          	jalr	-1670(ra) # 80001b6e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051fc:	0004851b          	sext.w	a0,s1
    80005200:	bbe1                	j	80004fd8 <exec+0x98>
    80005202:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005206:	e0843583          	ld	a1,-504(s0)
    8000520a:	855e                	mv	a0,s7
    8000520c:	ffffd097          	auipc	ra,0xffffd
    80005210:	962080e7          	jalr	-1694(ra) # 80001b6e <proc_freepagetable>
  if(ip){
    80005214:	da0498e3          	bnez	s1,80004fc4 <exec+0x84>
  return -1;
    80005218:	557d                	li	a0,-1
    8000521a:	bb7d                	j	80004fd8 <exec+0x98>
    8000521c:	e1243423          	sd	s2,-504(s0)
    80005220:	b7dd                	j	80005206 <exec+0x2c6>
    80005222:	e1243423          	sd	s2,-504(s0)
    80005226:	b7c5                	j	80005206 <exec+0x2c6>
    80005228:	e1243423          	sd	s2,-504(s0)
    8000522c:	bfe9                	j	80005206 <exec+0x2c6>
  sz = sz1;
    8000522e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005232:	4481                	li	s1,0
    80005234:	bfc9                	j	80005206 <exec+0x2c6>
  sz = sz1;
    80005236:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000523a:	4481                	li	s1,0
    8000523c:	b7e9                	j	80005206 <exec+0x2c6>
  sz = sz1;
    8000523e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005242:	4481                	li	s1,0
    80005244:	b7c9                	j	80005206 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005246:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000524a:	2b05                	addiw	s6,s6,1
    8000524c:	0389899b          	addiw	s3,s3,56
    80005250:	e8845783          	lhu	a5,-376(s0)
    80005254:	e2fb5be3          	bge	s6,a5,8000508a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005258:	2981                	sext.w	s3,s3
    8000525a:	03800713          	li	a4,56
    8000525e:	86ce                	mv	a3,s3
    80005260:	e1840613          	addi	a2,s0,-488
    80005264:	4581                	li	a1,0
    80005266:	8526                	mv	a0,s1
    80005268:	fffff097          	auipc	ra,0xfffff
    8000526c:	a8e080e7          	jalr	-1394(ra) # 80003cf6 <readi>
    80005270:	03800793          	li	a5,56
    80005274:	f8f517e3          	bne	a0,a5,80005202 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005278:	e1842783          	lw	a5,-488(s0)
    8000527c:	4705                	li	a4,1
    8000527e:	fce796e3          	bne	a5,a4,8000524a <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005282:	e4043603          	ld	a2,-448(s0)
    80005286:	e3843783          	ld	a5,-456(s0)
    8000528a:	f8f669e3          	bltu	a2,a5,8000521c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000528e:	e2843783          	ld	a5,-472(s0)
    80005292:	963e                	add	a2,a2,a5
    80005294:	f8f667e3          	bltu	a2,a5,80005222 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005298:	85ca                	mv	a1,s2
    8000529a:	855e                	mv	a0,s7
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	186080e7          	jalr	390(ra) # 80001422 <uvmalloc>
    800052a4:	e0a43423          	sd	a0,-504(s0)
    800052a8:	d141                	beqz	a0,80005228 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800052aa:	e2843d03          	ld	s10,-472(s0)
    800052ae:	df043783          	ld	a5,-528(s0)
    800052b2:	00fd77b3          	and	a5,s10,a5
    800052b6:	fba1                	bnez	a5,80005206 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052b8:	e2042d83          	lw	s11,-480(s0)
    800052bc:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052c0:	f80c03e3          	beqz	s8,80005246 <exec+0x306>
    800052c4:	8a62                	mv	s4,s8
    800052c6:	4901                	li	s2,0
    800052c8:	b345                	j	80005068 <exec+0x128>

00000000800052ca <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052ca:	7179                	addi	sp,sp,-48
    800052cc:	f406                	sd	ra,40(sp)
    800052ce:	f022                	sd	s0,32(sp)
    800052d0:	ec26                	sd	s1,24(sp)
    800052d2:	e84a                	sd	s2,16(sp)
    800052d4:	1800                	addi	s0,sp,48
    800052d6:	892e                	mv	s2,a1
    800052d8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800052da:	fdc40593          	addi	a1,s0,-36
    800052de:	ffffe097          	auipc	ra,0xffffe
    800052e2:	972080e7          	jalr	-1678(ra) # 80002c50 <argint>
    800052e6:	04054063          	bltz	a0,80005326 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052ea:	fdc42703          	lw	a4,-36(s0)
    800052ee:	47bd                	li	a5,15
    800052f0:	02e7ed63          	bltu	a5,a4,8000532a <argfd+0x60>
    800052f4:	ffffc097          	auipc	ra,0xffffc
    800052f8:	71a080e7          	jalr	1818(ra) # 80001a0e <myproc>
    800052fc:	fdc42703          	lw	a4,-36(s0)
    80005300:	01a70793          	addi	a5,a4,26
    80005304:	078e                	slli	a5,a5,0x3
    80005306:	953e                	add	a0,a0,a5
    80005308:	611c                	ld	a5,0(a0)
    8000530a:	c395                	beqz	a5,8000532e <argfd+0x64>
    return -1;
  if(pfd)
    8000530c:	00090463          	beqz	s2,80005314 <argfd+0x4a>
    *pfd = fd;
    80005310:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005314:	4501                	li	a0,0
  if(pf)
    80005316:	c091                	beqz	s1,8000531a <argfd+0x50>
    *pf = f;
    80005318:	e09c                	sd	a5,0(s1)
}
    8000531a:	70a2                	ld	ra,40(sp)
    8000531c:	7402                	ld	s0,32(sp)
    8000531e:	64e2                	ld	s1,24(sp)
    80005320:	6942                	ld	s2,16(sp)
    80005322:	6145                	addi	sp,sp,48
    80005324:	8082                	ret
    return -1;
    80005326:	557d                	li	a0,-1
    80005328:	bfcd                	j	8000531a <argfd+0x50>
    return -1;
    8000532a:	557d                	li	a0,-1
    8000532c:	b7fd                	j	8000531a <argfd+0x50>
    8000532e:	557d                	li	a0,-1
    80005330:	b7ed                	j	8000531a <argfd+0x50>

0000000080005332 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005332:	1101                	addi	sp,sp,-32
    80005334:	ec06                	sd	ra,24(sp)
    80005336:	e822                	sd	s0,16(sp)
    80005338:	e426                	sd	s1,8(sp)
    8000533a:	1000                	addi	s0,sp,32
    8000533c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000533e:	ffffc097          	auipc	ra,0xffffc
    80005342:	6d0080e7          	jalr	1744(ra) # 80001a0e <myproc>
    80005346:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005348:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000534c:	4501                	li	a0,0
    8000534e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005350:	6398                	ld	a4,0(a5)
    80005352:	cb19                	beqz	a4,80005368 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005354:	2505                	addiw	a0,a0,1
    80005356:	07a1                	addi	a5,a5,8
    80005358:	fed51ce3          	bne	a0,a3,80005350 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000535c:	557d                	li	a0,-1
}
    8000535e:	60e2                	ld	ra,24(sp)
    80005360:	6442                	ld	s0,16(sp)
    80005362:	64a2                	ld	s1,8(sp)
    80005364:	6105                	addi	sp,sp,32
    80005366:	8082                	ret
      p->ofile[fd] = f;
    80005368:	01a50793          	addi	a5,a0,26
    8000536c:	078e                	slli	a5,a5,0x3
    8000536e:	963e                	add	a2,a2,a5
    80005370:	e204                	sd	s1,0(a2)
      return fd;
    80005372:	b7f5                	j	8000535e <fdalloc+0x2c>

0000000080005374 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005374:	715d                	addi	sp,sp,-80
    80005376:	e486                	sd	ra,72(sp)
    80005378:	e0a2                	sd	s0,64(sp)
    8000537a:	fc26                	sd	s1,56(sp)
    8000537c:	f84a                	sd	s2,48(sp)
    8000537e:	f44e                	sd	s3,40(sp)
    80005380:	f052                	sd	s4,32(sp)
    80005382:	ec56                	sd	s5,24(sp)
    80005384:	0880                	addi	s0,sp,80
    80005386:	89ae                	mv	s3,a1
    80005388:	8ab2                	mv	s5,a2
    8000538a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000538c:	fb040593          	addi	a1,s0,-80
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	e86080e7          	jalr	-378(ra) # 80004216 <nameiparent>
    80005398:	892a                	mv	s2,a0
    8000539a:	12050f63          	beqz	a0,800054d8 <create+0x164>
    return 0;

  ilock(dp);
    8000539e:	ffffe097          	auipc	ra,0xffffe
    800053a2:	6a4080e7          	jalr	1700(ra) # 80003a42 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053a6:	4601                	li	a2,0
    800053a8:	fb040593          	addi	a1,s0,-80
    800053ac:	854a                	mv	a0,s2
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	b78080e7          	jalr	-1160(ra) # 80003f26 <dirlookup>
    800053b6:	84aa                	mv	s1,a0
    800053b8:	c921                	beqz	a0,80005408 <create+0x94>
    iunlockput(dp);
    800053ba:	854a                	mv	a0,s2
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	8e8080e7          	jalr	-1816(ra) # 80003ca4 <iunlockput>
    ilock(ip);
    800053c4:	8526                	mv	a0,s1
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	67c080e7          	jalr	1660(ra) # 80003a42 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053ce:	2981                	sext.w	s3,s3
    800053d0:	4789                	li	a5,2
    800053d2:	02f99463          	bne	s3,a5,800053fa <create+0x86>
    800053d6:	0444d783          	lhu	a5,68(s1)
    800053da:	37f9                	addiw	a5,a5,-2
    800053dc:	17c2                	slli	a5,a5,0x30
    800053de:	93c1                	srli	a5,a5,0x30
    800053e0:	4705                	li	a4,1
    800053e2:	00f76c63          	bltu	a4,a5,800053fa <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800053e6:	8526                	mv	a0,s1
    800053e8:	60a6                	ld	ra,72(sp)
    800053ea:	6406                	ld	s0,64(sp)
    800053ec:	74e2                	ld	s1,56(sp)
    800053ee:	7942                	ld	s2,48(sp)
    800053f0:	79a2                	ld	s3,40(sp)
    800053f2:	7a02                	ld	s4,32(sp)
    800053f4:	6ae2                	ld	s5,24(sp)
    800053f6:	6161                	addi	sp,sp,80
    800053f8:	8082                	ret
    iunlockput(ip);
    800053fa:	8526                	mv	a0,s1
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	8a8080e7          	jalr	-1880(ra) # 80003ca4 <iunlockput>
    return 0;
    80005404:	4481                	li	s1,0
    80005406:	b7c5                	j	800053e6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005408:	85ce                	mv	a1,s3
    8000540a:	00092503          	lw	a0,0(s2)
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	49c080e7          	jalr	1180(ra) # 800038aa <ialloc>
    80005416:	84aa                	mv	s1,a0
    80005418:	c529                	beqz	a0,80005462 <create+0xee>
  ilock(ip);
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	628080e7          	jalr	1576(ra) # 80003a42 <ilock>
  ip->major = major;
    80005422:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005426:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000542a:	4785                	li	a5,1
    8000542c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005430:	8526                	mv	a0,s1
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	546080e7          	jalr	1350(ra) # 80003978 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000543a:	2981                	sext.w	s3,s3
    8000543c:	4785                	li	a5,1
    8000543e:	02f98a63          	beq	s3,a5,80005472 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005442:	40d0                	lw	a2,4(s1)
    80005444:	fb040593          	addi	a1,s0,-80
    80005448:	854a                	mv	a0,s2
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	cec080e7          	jalr	-788(ra) # 80004136 <dirlink>
    80005452:	06054b63          	bltz	a0,800054c8 <create+0x154>
  iunlockput(dp);
    80005456:	854a                	mv	a0,s2
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	84c080e7          	jalr	-1972(ra) # 80003ca4 <iunlockput>
  return ip;
    80005460:	b759                	j	800053e6 <create+0x72>
    panic("create: ialloc");
    80005462:	00003517          	auipc	a0,0x3
    80005466:	42e50513          	addi	a0,a0,1070 # 80008890 <syscalls+0x2a8>
    8000546a:	ffffb097          	auipc	ra,0xffffb
    8000546e:	0d4080e7          	jalr	212(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005472:	04a95783          	lhu	a5,74(s2)
    80005476:	2785                	addiw	a5,a5,1
    80005478:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000547c:	854a                	mv	a0,s2
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	4fa080e7          	jalr	1274(ra) # 80003978 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005486:	40d0                	lw	a2,4(s1)
    80005488:	00003597          	auipc	a1,0x3
    8000548c:	41858593          	addi	a1,a1,1048 # 800088a0 <syscalls+0x2b8>
    80005490:	8526                	mv	a0,s1
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	ca4080e7          	jalr	-860(ra) # 80004136 <dirlink>
    8000549a:	00054f63          	bltz	a0,800054b8 <create+0x144>
    8000549e:	00492603          	lw	a2,4(s2)
    800054a2:	00003597          	auipc	a1,0x3
    800054a6:	40658593          	addi	a1,a1,1030 # 800088a8 <syscalls+0x2c0>
    800054aa:	8526                	mv	a0,s1
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	c8a080e7          	jalr	-886(ra) # 80004136 <dirlink>
    800054b4:	f80557e3          	bgez	a0,80005442 <create+0xce>
      panic("create dots");
    800054b8:	00003517          	auipc	a0,0x3
    800054bc:	3f850513          	addi	a0,a0,1016 # 800088b0 <syscalls+0x2c8>
    800054c0:	ffffb097          	auipc	ra,0xffffb
    800054c4:	07e080e7          	jalr	126(ra) # 8000053e <panic>
    panic("create: dirlink");
    800054c8:	00003517          	auipc	a0,0x3
    800054cc:	3f850513          	addi	a0,a0,1016 # 800088c0 <syscalls+0x2d8>
    800054d0:	ffffb097          	auipc	ra,0xffffb
    800054d4:	06e080e7          	jalr	110(ra) # 8000053e <panic>
    return 0;
    800054d8:	84aa                	mv	s1,a0
    800054da:	b731                	j	800053e6 <create+0x72>

00000000800054dc <sys_dup>:
{
    800054dc:	7179                	addi	sp,sp,-48
    800054de:	f406                	sd	ra,40(sp)
    800054e0:	f022                	sd	s0,32(sp)
    800054e2:	ec26                	sd	s1,24(sp)
    800054e4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054e6:	fd840613          	addi	a2,s0,-40
    800054ea:	4581                	li	a1,0
    800054ec:	4501                	li	a0,0
    800054ee:	00000097          	auipc	ra,0x0
    800054f2:	ddc080e7          	jalr	-548(ra) # 800052ca <argfd>
    return -1;
    800054f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054f8:	02054363          	bltz	a0,8000551e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054fc:	fd843503          	ld	a0,-40(s0)
    80005500:	00000097          	auipc	ra,0x0
    80005504:	e32080e7          	jalr	-462(ra) # 80005332 <fdalloc>
    80005508:	84aa                	mv	s1,a0
    return -1;
    8000550a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000550c:	00054963          	bltz	a0,8000551e <sys_dup+0x42>
  filedup(f);
    80005510:	fd843503          	ld	a0,-40(s0)
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	37a080e7          	jalr	890(ra) # 8000488e <filedup>
  return fd;
    8000551c:	87a6                	mv	a5,s1
}
    8000551e:	853e                	mv	a0,a5
    80005520:	70a2                	ld	ra,40(sp)
    80005522:	7402                	ld	s0,32(sp)
    80005524:	64e2                	ld	s1,24(sp)
    80005526:	6145                	addi	sp,sp,48
    80005528:	8082                	ret

000000008000552a <sys_read>:
{
    8000552a:	7179                	addi	sp,sp,-48
    8000552c:	f406                	sd	ra,40(sp)
    8000552e:	f022                	sd	s0,32(sp)
    80005530:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005532:	fe840613          	addi	a2,s0,-24
    80005536:	4581                	li	a1,0
    80005538:	4501                	li	a0,0
    8000553a:	00000097          	auipc	ra,0x0
    8000553e:	d90080e7          	jalr	-624(ra) # 800052ca <argfd>
    return -1;
    80005542:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005544:	04054163          	bltz	a0,80005586 <sys_read+0x5c>
    80005548:	fe440593          	addi	a1,s0,-28
    8000554c:	4509                	li	a0,2
    8000554e:	ffffd097          	auipc	ra,0xffffd
    80005552:	702080e7          	jalr	1794(ra) # 80002c50 <argint>
    return -1;
    80005556:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005558:	02054763          	bltz	a0,80005586 <sys_read+0x5c>
    8000555c:	fd840593          	addi	a1,s0,-40
    80005560:	4505                	li	a0,1
    80005562:	ffffd097          	auipc	ra,0xffffd
    80005566:	710080e7          	jalr	1808(ra) # 80002c72 <argaddr>
    return -1;
    8000556a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000556c:	00054d63          	bltz	a0,80005586 <sys_read+0x5c>
  return fileread(f, p, n);
    80005570:	fe442603          	lw	a2,-28(s0)
    80005574:	fd843583          	ld	a1,-40(s0)
    80005578:	fe843503          	ld	a0,-24(s0)
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	49e080e7          	jalr	1182(ra) # 80004a1a <fileread>
    80005584:	87aa                	mv	a5,a0
}
    80005586:	853e                	mv	a0,a5
    80005588:	70a2                	ld	ra,40(sp)
    8000558a:	7402                	ld	s0,32(sp)
    8000558c:	6145                	addi	sp,sp,48
    8000558e:	8082                	ret

0000000080005590 <sys_write>:
{
    80005590:	7179                	addi	sp,sp,-48
    80005592:	f406                	sd	ra,40(sp)
    80005594:	f022                	sd	s0,32(sp)
    80005596:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005598:	fe840613          	addi	a2,s0,-24
    8000559c:	4581                	li	a1,0
    8000559e:	4501                	li	a0,0
    800055a0:	00000097          	auipc	ra,0x0
    800055a4:	d2a080e7          	jalr	-726(ra) # 800052ca <argfd>
    return -1;
    800055a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055aa:	04054163          	bltz	a0,800055ec <sys_write+0x5c>
    800055ae:	fe440593          	addi	a1,s0,-28
    800055b2:	4509                	li	a0,2
    800055b4:	ffffd097          	auipc	ra,0xffffd
    800055b8:	69c080e7          	jalr	1692(ra) # 80002c50 <argint>
    return -1;
    800055bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055be:	02054763          	bltz	a0,800055ec <sys_write+0x5c>
    800055c2:	fd840593          	addi	a1,s0,-40
    800055c6:	4505                	li	a0,1
    800055c8:	ffffd097          	auipc	ra,0xffffd
    800055cc:	6aa080e7          	jalr	1706(ra) # 80002c72 <argaddr>
    return -1;
    800055d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055d2:	00054d63          	bltz	a0,800055ec <sys_write+0x5c>
  return filewrite(f, p, n);
    800055d6:	fe442603          	lw	a2,-28(s0)
    800055da:	fd843583          	ld	a1,-40(s0)
    800055de:	fe843503          	ld	a0,-24(s0)
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	4fa080e7          	jalr	1274(ra) # 80004adc <filewrite>
    800055ea:	87aa                	mv	a5,a0
}
    800055ec:	853e                	mv	a0,a5
    800055ee:	70a2                	ld	ra,40(sp)
    800055f0:	7402                	ld	s0,32(sp)
    800055f2:	6145                	addi	sp,sp,48
    800055f4:	8082                	ret

00000000800055f6 <sys_close>:
{
    800055f6:	1101                	addi	sp,sp,-32
    800055f8:	ec06                	sd	ra,24(sp)
    800055fa:	e822                	sd	s0,16(sp)
    800055fc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055fe:	fe040613          	addi	a2,s0,-32
    80005602:	fec40593          	addi	a1,s0,-20
    80005606:	4501                	li	a0,0
    80005608:	00000097          	auipc	ra,0x0
    8000560c:	cc2080e7          	jalr	-830(ra) # 800052ca <argfd>
    return -1;
    80005610:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005612:	02054463          	bltz	a0,8000563a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005616:	ffffc097          	auipc	ra,0xffffc
    8000561a:	3f8080e7          	jalr	1016(ra) # 80001a0e <myproc>
    8000561e:	fec42783          	lw	a5,-20(s0)
    80005622:	07e9                	addi	a5,a5,26
    80005624:	078e                	slli	a5,a5,0x3
    80005626:	97aa                	add	a5,a5,a0
    80005628:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000562c:	fe043503          	ld	a0,-32(s0)
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	2b0080e7          	jalr	688(ra) # 800048e0 <fileclose>
  return 0;
    80005638:	4781                	li	a5,0
}
    8000563a:	853e                	mv	a0,a5
    8000563c:	60e2                	ld	ra,24(sp)
    8000563e:	6442                	ld	s0,16(sp)
    80005640:	6105                	addi	sp,sp,32
    80005642:	8082                	ret

0000000080005644 <sys_fstat>:
{
    80005644:	1101                	addi	sp,sp,-32
    80005646:	ec06                	sd	ra,24(sp)
    80005648:	e822                	sd	s0,16(sp)
    8000564a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000564c:	fe840613          	addi	a2,s0,-24
    80005650:	4581                	li	a1,0
    80005652:	4501                	li	a0,0
    80005654:	00000097          	auipc	ra,0x0
    80005658:	c76080e7          	jalr	-906(ra) # 800052ca <argfd>
    return -1;
    8000565c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000565e:	02054563          	bltz	a0,80005688 <sys_fstat+0x44>
    80005662:	fe040593          	addi	a1,s0,-32
    80005666:	4505                	li	a0,1
    80005668:	ffffd097          	auipc	ra,0xffffd
    8000566c:	60a080e7          	jalr	1546(ra) # 80002c72 <argaddr>
    return -1;
    80005670:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005672:	00054b63          	bltz	a0,80005688 <sys_fstat+0x44>
  return filestat(f, st);
    80005676:	fe043583          	ld	a1,-32(s0)
    8000567a:	fe843503          	ld	a0,-24(s0)
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	32a080e7          	jalr	810(ra) # 800049a8 <filestat>
    80005686:	87aa                	mv	a5,a0
}
    80005688:	853e                	mv	a0,a5
    8000568a:	60e2                	ld	ra,24(sp)
    8000568c:	6442                	ld	s0,16(sp)
    8000568e:	6105                	addi	sp,sp,32
    80005690:	8082                	ret

0000000080005692 <sys_link>:
{
    80005692:	7169                	addi	sp,sp,-304
    80005694:	f606                	sd	ra,296(sp)
    80005696:	f222                	sd	s0,288(sp)
    80005698:	ee26                	sd	s1,280(sp)
    8000569a:	ea4a                	sd	s2,272(sp)
    8000569c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000569e:	08000613          	li	a2,128
    800056a2:	ed040593          	addi	a1,s0,-304
    800056a6:	4501                	li	a0,0
    800056a8:	ffffd097          	auipc	ra,0xffffd
    800056ac:	5ec080e7          	jalr	1516(ra) # 80002c94 <argstr>
    return -1;
    800056b0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056b2:	10054e63          	bltz	a0,800057ce <sys_link+0x13c>
    800056b6:	08000613          	li	a2,128
    800056ba:	f5040593          	addi	a1,s0,-176
    800056be:	4505                	li	a0,1
    800056c0:	ffffd097          	auipc	ra,0xffffd
    800056c4:	5d4080e7          	jalr	1492(ra) # 80002c94 <argstr>
    return -1;
    800056c8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056ca:	10054263          	bltz	a0,800057ce <sys_link+0x13c>
  begin_op();
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	d46080e7          	jalr	-698(ra) # 80004414 <begin_op>
  if((ip = namei(old)) == 0){
    800056d6:	ed040513          	addi	a0,s0,-304
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	b1e080e7          	jalr	-1250(ra) # 800041f8 <namei>
    800056e2:	84aa                	mv	s1,a0
    800056e4:	c551                	beqz	a0,80005770 <sys_link+0xde>
  ilock(ip);
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	35c080e7          	jalr	860(ra) # 80003a42 <ilock>
  if(ip->type == T_DIR){
    800056ee:	04449703          	lh	a4,68(s1)
    800056f2:	4785                	li	a5,1
    800056f4:	08f70463          	beq	a4,a5,8000577c <sys_link+0xea>
  ip->nlink++;
    800056f8:	04a4d783          	lhu	a5,74(s1)
    800056fc:	2785                	addiw	a5,a5,1
    800056fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	274080e7          	jalr	628(ra) # 80003978 <iupdate>
  iunlock(ip);
    8000570c:	8526                	mv	a0,s1
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	3f6080e7          	jalr	1014(ra) # 80003b04 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005716:	fd040593          	addi	a1,s0,-48
    8000571a:	f5040513          	addi	a0,s0,-176
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	af8080e7          	jalr	-1288(ra) # 80004216 <nameiparent>
    80005726:	892a                	mv	s2,a0
    80005728:	c935                	beqz	a0,8000579c <sys_link+0x10a>
  ilock(dp);
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	318080e7          	jalr	792(ra) # 80003a42 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005732:	00092703          	lw	a4,0(s2)
    80005736:	409c                	lw	a5,0(s1)
    80005738:	04f71d63          	bne	a4,a5,80005792 <sys_link+0x100>
    8000573c:	40d0                	lw	a2,4(s1)
    8000573e:	fd040593          	addi	a1,s0,-48
    80005742:	854a                	mv	a0,s2
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	9f2080e7          	jalr	-1550(ra) # 80004136 <dirlink>
    8000574c:	04054363          	bltz	a0,80005792 <sys_link+0x100>
  iunlockput(dp);
    80005750:	854a                	mv	a0,s2
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	552080e7          	jalr	1362(ra) # 80003ca4 <iunlockput>
  iput(ip);
    8000575a:	8526                	mv	a0,s1
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	4a0080e7          	jalr	1184(ra) # 80003bfc <iput>
  end_op();
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	d30080e7          	jalr	-720(ra) # 80004494 <end_op>
  return 0;
    8000576c:	4781                	li	a5,0
    8000576e:	a085                	j	800057ce <sys_link+0x13c>
    end_op();
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	d24080e7          	jalr	-732(ra) # 80004494 <end_op>
    return -1;
    80005778:	57fd                	li	a5,-1
    8000577a:	a891                	j	800057ce <sys_link+0x13c>
    iunlockput(ip);
    8000577c:	8526                	mv	a0,s1
    8000577e:	ffffe097          	auipc	ra,0xffffe
    80005782:	526080e7          	jalr	1318(ra) # 80003ca4 <iunlockput>
    end_op();
    80005786:	fffff097          	auipc	ra,0xfffff
    8000578a:	d0e080e7          	jalr	-754(ra) # 80004494 <end_op>
    return -1;
    8000578e:	57fd                	li	a5,-1
    80005790:	a83d                	j	800057ce <sys_link+0x13c>
    iunlockput(dp);
    80005792:	854a                	mv	a0,s2
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	510080e7          	jalr	1296(ra) # 80003ca4 <iunlockput>
  ilock(ip);
    8000579c:	8526                	mv	a0,s1
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	2a4080e7          	jalr	676(ra) # 80003a42 <ilock>
  ip->nlink--;
    800057a6:	04a4d783          	lhu	a5,74(s1)
    800057aa:	37fd                	addiw	a5,a5,-1
    800057ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	1c6080e7          	jalr	454(ra) # 80003978 <iupdate>
  iunlockput(ip);
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	4e8080e7          	jalr	1256(ra) # 80003ca4 <iunlockput>
  end_op();
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	cd0080e7          	jalr	-816(ra) # 80004494 <end_op>
  return -1;
    800057cc:	57fd                	li	a5,-1
}
    800057ce:	853e                	mv	a0,a5
    800057d0:	70b2                	ld	ra,296(sp)
    800057d2:	7412                	ld	s0,288(sp)
    800057d4:	64f2                	ld	s1,280(sp)
    800057d6:	6952                	ld	s2,272(sp)
    800057d8:	6155                	addi	sp,sp,304
    800057da:	8082                	ret

00000000800057dc <sys_unlink>:
{
    800057dc:	7151                	addi	sp,sp,-240
    800057de:	f586                	sd	ra,232(sp)
    800057e0:	f1a2                	sd	s0,224(sp)
    800057e2:	eda6                	sd	s1,216(sp)
    800057e4:	e9ca                	sd	s2,208(sp)
    800057e6:	e5ce                	sd	s3,200(sp)
    800057e8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057ea:	08000613          	li	a2,128
    800057ee:	f3040593          	addi	a1,s0,-208
    800057f2:	4501                	li	a0,0
    800057f4:	ffffd097          	auipc	ra,0xffffd
    800057f8:	4a0080e7          	jalr	1184(ra) # 80002c94 <argstr>
    800057fc:	18054163          	bltz	a0,8000597e <sys_unlink+0x1a2>
  begin_op();
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	c14080e7          	jalr	-1004(ra) # 80004414 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005808:	fb040593          	addi	a1,s0,-80
    8000580c:	f3040513          	addi	a0,s0,-208
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	a06080e7          	jalr	-1530(ra) # 80004216 <nameiparent>
    80005818:	84aa                	mv	s1,a0
    8000581a:	c979                	beqz	a0,800058f0 <sys_unlink+0x114>
  ilock(dp);
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	226080e7          	jalr	550(ra) # 80003a42 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005824:	00003597          	auipc	a1,0x3
    80005828:	07c58593          	addi	a1,a1,124 # 800088a0 <syscalls+0x2b8>
    8000582c:	fb040513          	addi	a0,s0,-80
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	6dc080e7          	jalr	1756(ra) # 80003f0c <namecmp>
    80005838:	14050a63          	beqz	a0,8000598c <sys_unlink+0x1b0>
    8000583c:	00003597          	auipc	a1,0x3
    80005840:	06c58593          	addi	a1,a1,108 # 800088a8 <syscalls+0x2c0>
    80005844:	fb040513          	addi	a0,s0,-80
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	6c4080e7          	jalr	1732(ra) # 80003f0c <namecmp>
    80005850:	12050e63          	beqz	a0,8000598c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005854:	f2c40613          	addi	a2,s0,-212
    80005858:	fb040593          	addi	a1,s0,-80
    8000585c:	8526                	mv	a0,s1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	6c8080e7          	jalr	1736(ra) # 80003f26 <dirlookup>
    80005866:	892a                	mv	s2,a0
    80005868:	12050263          	beqz	a0,8000598c <sys_unlink+0x1b0>
  ilock(ip);
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	1d6080e7          	jalr	470(ra) # 80003a42 <ilock>
  if(ip->nlink < 1)
    80005874:	04a91783          	lh	a5,74(s2)
    80005878:	08f05263          	blez	a5,800058fc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000587c:	04491703          	lh	a4,68(s2)
    80005880:	4785                	li	a5,1
    80005882:	08f70563          	beq	a4,a5,8000590c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005886:	4641                	li	a2,16
    80005888:	4581                	li	a1,0
    8000588a:	fc040513          	addi	a0,s0,-64
    8000588e:	ffffb097          	auipc	ra,0xffffb
    80005892:	452080e7          	jalr	1106(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005896:	4741                	li	a4,16
    80005898:	f2c42683          	lw	a3,-212(s0)
    8000589c:	fc040613          	addi	a2,s0,-64
    800058a0:	4581                	li	a1,0
    800058a2:	8526                	mv	a0,s1
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	54a080e7          	jalr	1354(ra) # 80003dee <writei>
    800058ac:	47c1                	li	a5,16
    800058ae:	0af51563          	bne	a0,a5,80005958 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058b2:	04491703          	lh	a4,68(s2)
    800058b6:	4785                	li	a5,1
    800058b8:	0af70863          	beq	a4,a5,80005968 <sys_unlink+0x18c>
  iunlockput(dp);
    800058bc:	8526                	mv	a0,s1
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	3e6080e7          	jalr	998(ra) # 80003ca4 <iunlockput>
  ip->nlink--;
    800058c6:	04a95783          	lhu	a5,74(s2)
    800058ca:	37fd                	addiw	a5,a5,-1
    800058cc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058d0:	854a                	mv	a0,s2
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	0a6080e7          	jalr	166(ra) # 80003978 <iupdate>
  iunlockput(ip);
    800058da:	854a                	mv	a0,s2
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	3c8080e7          	jalr	968(ra) # 80003ca4 <iunlockput>
  end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	bb0080e7          	jalr	-1104(ra) # 80004494 <end_op>
  return 0;
    800058ec:	4501                	li	a0,0
    800058ee:	a84d                	j	800059a0 <sys_unlink+0x1c4>
    end_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	ba4080e7          	jalr	-1116(ra) # 80004494 <end_op>
    return -1;
    800058f8:	557d                	li	a0,-1
    800058fa:	a05d                	j	800059a0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058fc:	00003517          	auipc	a0,0x3
    80005900:	fd450513          	addi	a0,a0,-44 # 800088d0 <syscalls+0x2e8>
    80005904:	ffffb097          	auipc	ra,0xffffb
    80005908:	c3a080e7          	jalr	-966(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000590c:	04c92703          	lw	a4,76(s2)
    80005910:	02000793          	li	a5,32
    80005914:	f6e7f9e3          	bgeu	a5,a4,80005886 <sys_unlink+0xaa>
    80005918:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000591c:	4741                	li	a4,16
    8000591e:	86ce                	mv	a3,s3
    80005920:	f1840613          	addi	a2,s0,-232
    80005924:	4581                	li	a1,0
    80005926:	854a                	mv	a0,s2
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	3ce080e7          	jalr	974(ra) # 80003cf6 <readi>
    80005930:	47c1                	li	a5,16
    80005932:	00f51b63          	bne	a0,a5,80005948 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005936:	f1845783          	lhu	a5,-232(s0)
    8000593a:	e7a1                	bnez	a5,80005982 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000593c:	29c1                	addiw	s3,s3,16
    8000593e:	04c92783          	lw	a5,76(s2)
    80005942:	fcf9ede3          	bltu	s3,a5,8000591c <sys_unlink+0x140>
    80005946:	b781                	j	80005886 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005948:	00003517          	auipc	a0,0x3
    8000594c:	fa050513          	addi	a0,a0,-96 # 800088e8 <syscalls+0x300>
    80005950:	ffffb097          	auipc	ra,0xffffb
    80005954:	bee080e7          	jalr	-1042(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005958:	00003517          	auipc	a0,0x3
    8000595c:	fa850513          	addi	a0,a0,-88 # 80008900 <syscalls+0x318>
    80005960:	ffffb097          	auipc	ra,0xffffb
    80005964:	bde080e7          	jalr	-1058(ra) # 8000053e <panic>
    dp->nlink--;
    80005968:	04a4d783          	lhu	a5,74(s1)
    8000596c:	37fd                	addiw	a5,a5,-1
    8000596e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005972:	8526                	mv	a0,s1
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	004080e7          	jalr	4(ra) # 80003978 <iupdate>
    8000597c:	b781                	j	800058bc <sys_unlink+0xe0>
    return -1;
    8000597e:	557d                	li	a0,-1
    80005980:	a005                	j	800059a0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005982:	854a                	mv	a0,s2
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	320080e7          	jalr	800(ra) # 80003ca4 <iunlockput>
  iunlockput(dp);
    8000598c:	8526                	mv	a0,s1
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	316080e7          	jalr	790(ra) # 80003ca4 <iunlockput>
  end_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	afe080e7          	jalr	-1282(ra) # 80004494 <end_op>
  return -1;
    8000599e:	557d                	li	a0,-1
}
    800059a0:	70ae                	ld	ra,232(sp)
    800059a2:	740e                	ld	s0,224(sp)
    800059a4:	64ee                	ld	s1,216(sp)
    800059a6:	694e                	ld	s2,208(sp)
    800059a8:	69ae                	ld	s3,200(sp)
    800059aa:	616d                	addi	sp,sp,240
    800059ac:	8082                	ret

00000000800059ae <sys_open>:

uint64
sys_open(void)
{
    800059ae:	7131                	addi	sp,sp,-192
    800059b0:	fd06                	sd	ra,184(sp)
    800059b2:	f922                	sd	s0,176(sp)
    800059b4:	f526                	sd	s1,168(sp)
    800059b6:	f14a                	sd	s2,160(sp)
    800059b8:	ed4e                	sd	s3,152(sp)
    800059ba:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059bc:	08000613          	li	a2,128
    800059c0:	f5040593          	addi	a1,s0,-176
    800059c4:	4501                	li	a0,0
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	2ce080e7          	jalr	718(ra) # 80002c94 <argstr>
    return -1;
    800059ce:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059d0:	0c054163          	bltz	a0,80005a92 <sys_open+0xe4>
    800059d4:	f4c40593          	addi	a1,s0,-180
    800059d8:	4505                	li	a0,1
    800059da:	ffffd097          	auipc	ra,0xffffd
    800059de:	276080e7          	jalr	630(ra) # 80002c50 <argint>
    800059e2:	0a054863          	bltz	a0,80005a92 <sys_open+0xe4>

  begin_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	a2e080e7          	jalr	-1490(ra) # 80004414 <begin_op>

  if(omode & O_CREATE){
    800059ee:	f4c42783          	lw	a5,-180(s0)
    800059f2:	2007f793          	andi	a5,a5,512
    800059f6:	cbdd                	beqz	a5,80005aac <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059f8:	4681                	li	a3,0
    800059fa:	4601                	li	a2,0
    800059fc:	4589                	li	a1,2
    800059fe:	f5040513          	addi	a0,s0,-176
    80005a02:	00000097          	auipc	ra,0x0
    80005a06:	972080e7          	jalr	-1678(ra) # 80005374 <create>
    80005a0a:	892a                	mv	s2,a0
    if(ip == 0){
    80005a0c:	c959                	beqz	a0,80005aa2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a0e:	04491703          	lh	a4,68(s2)
    80005a12:	478d                	li	a5,3
    80005a14:	00f71763          	bne	a4,a5,80005a22 <sys_open+0x74>
    80005a18:	04695703          	lhu	a4,70(s2)
    80005a1c:	47a5                	li	a5,9
    80005a1e:	0ce7ec63          	bltu	a5,a4,80005af6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	e02080e7          	jalr	-510(ra) # 80004824 <filealloc>
    80005a2a:	89aa                	mv	s3,a0
    80005a2c:	10050263          	beqz	a0,80005b30 <sys_open+0x182>
    80005a30:	00000097          	auipc	ra,0x0
    80005a34:	902080e7          	jalr	-1790(ra) # 80005332 <fdalloc>
    80005a38:	84aa                	mv	s1,a0
    80005a3a:	0e054663          	bltz	a0,80005b26 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a3e:	04491703          	lh	a4,68(s2)
    80005a42:	478d                	li	a5,3
    80005a44:	0cf70463          	beq	a4,a5,80005b0c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a48:	4789                	li	a5,2
    80005a4a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a4e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a52:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a56:	f4c42783          	lw	a5,-180(s0)
    80005a5a:	0017c713          	xori	a4,a5,1
    80005a5e:	8b05                	andi	a4,a4,1
    80005a60:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a64:	0037f713          	andi	a4,a5,3
    80005a68:	00e03733          	snez	a4,a4
    80005a6c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a70:	4007f793          	andi	a5,a5,1024
    80005a74:	c791                	beqz	a5,80005a80 <sys_open+0xd2>
    80005a76:	04491703          	lh	a4,68(s2)
    80005a7a:	4789                	li	a5,2
    80005a7c:	08f70f63          	beq	a4,a5,80005b1a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a80:	854a                	mv	a0,s2
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	082080e7          	jalr	130(ra) # 80003b04 <iunlock>
  end_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	a0a080e7          	jalr	-1526(ra) # 80004494 <end_op>

  return fd;
}
    80005a92:	8526                	mv	a0,s1
    80005a94:	70ea                	ld	ra,184(sp)
    80005a96:	744a                	ld	s0,176(sp)
    80005a98:	74aa                	ld	s1,168(sp)
    80005a9a:	790a                	ld	s2,160(sp)
    80005a9c:	69ea                	ld	s3,152(sp)
    80005a9e:	6129                	addi	sp,sp,192
    80005aa0:	8082                	ret
      end_op();
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	9f2080e7          	jalr	-1550(ra) # 80004494 <end_op>
      return -1;
    80005aaa:	b7e5                	j	80005a92 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005aac:	f5040513          	addi	a0,s0,-176
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	748080e7          	jalr	1864(ra) # 800041f8 <namei>
    80005ab8:	892a                	mv	s2,a0
    80005aba:	c905                	beqz	a0,80005aea <sys_open+0x13c>
    ilock(ip);
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	f86080e7          	jalr	-122(ra) # 80003a42 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ac4:	04491703          	lh	a4,68(s2)
    80005ac8:	4785                	li	a5,1
    80005aca:	f4f712e3          	bne	a4,a5,80005a0e <sys_open+0x60>
    80005ace:	f4c42783          	lw	a5,-180(s0)
    80005ad2:	dba1                	beqz	a5,80005a22 <sys_open+0x74>
      iunlockput(ip);
    80005ad4:	854a                	mv	a0,s2
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	1ce080e7          	jalr	462(ra) # 80003ca4 <iunlockput>
      end_op();
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	9b6080e7          	jalr	-1610(ra) # 80004494 <end_op>
      return -1;
    80005ae6:	54fd                	li	s1,-1
    80005ae8:	b76d                	j	80005a92 <sys_open+0xe4>
      end_op();
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	9aa080e7          	jalr	-1622(ra) # 80004494 <end_op>
      return -1;
    80005af2:	54fd                	li	s1,-1
    80005af4:	bf79                	j	80005a92 <sys_open+0xe4>
    iunlockput(ip);
    80005af6:	854a                	mv	a0,s2
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	1ac080e7          	jalr	428(ra) # 80003ca4 <iunlockput>
    end_op();
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	994080e7          	jalr	-1644(ra) # 80004494 <end_op>
    return -1;
    80005b08:	54fd                	li	s1,-1
    80005b0a:	b761                	j	80005a92 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b0c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b10:	04691783          	lh	a5,70(s2)
    80005b14:	02f99223          	sh	a5,36(s3)
    80005b18:	bf2d                	j	80005a52 <sys_open+0xa4>
    itrunc(ip);
    80005b1a:	854a                	mv	a0,s2
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	034080e7          	jalr	52(ra) # 80003b50 <itrunc>
    80005b24:	bfb1                	j	80005a80 <sys_open+0xd2>
      fileclose(f);
    80005b26:	854e                	mv	a0,s3
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	db8080e7          	jalr	-584(ra) # 800048e0 <fileclose>
    iunlockput(ip);
    80005b30:	854a                	mv	a0,s2
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	172080e7          	jalr	370(ra) # 80003ca4 <iunlockput>
    end_op();
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	95a080e7          	jalr	-1702(ra) # 80004494 <end_op>
    return -1;
    80005b42:	54fd                	li	s1,-1
    80005b44:	b7b9                	j	80005a92 <sys_open+0xe4>

0000000080005b46 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b46:	7175                	addi	sp,sp,-144
    80005b48:	e506                	sd	ra,136(sp)
    80005b4a:	e122                	sd	s0,128(sp)
    80005b4c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	8c6080e7          	jalr	-1850(ra) # 80004414 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b56:	08000613          	li	a2,128
    80005b5a:	f7040593          	addi	a1,s0,-144
    80005b5e:	4501                	li	a0,0
    80005b60:	ffffd097          	auipc	ra,0xffffd
    80005b64:	134080e7          	jalr	308(ra) # 80002c94 <argstr>
    80005b68:	02054963          	bltz	a0,80005b9a <sys_mkdir+0x54>
    80005b6c:	4681                	li	a3,0
    80005b6e:	4601                	li	a2,0
    80005b70:	4585                	li	a1,1
    80005b72:	f7040513          	addi	a0,s0,-144
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	7fe080e7          	jalr	2046(ra) # 80005374 <create>
    80005b7e:	cd11                	beqz	a0,80005b9a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	124080e7          	jalr	292(ra) # 80003ca4 <iunlockput>
  end_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	90c080e7          	jalr	-1780(ra) # 80004494 <end_op>
  return 0;
    80005b90:	4501                	li	a0,0
}
    80005b92:	60aa                	ld	ra,136(sp)
    80005b94:	640a                	ld	s0,128(sp)
    80005b96:	6149                	addi	sp,sp,144
    80005b98:	8082                	ret
    end_op();
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	8fa080e7          	jalr	-1798(ra) # 80004494 <end_op>
    return -1;
    80005ba2:	557d                	li	a0,-1
    80005ba4:	b7fd                	j	80005b92 <sys_mkdir+0x4c>

0000000080005ba6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ba6:	7135                	addi	sp,sp,-160
    80005ba8:	ed06                	sd	ra,152(sp)
    80005baa:	e922                	sd	s0,144(sp)
    80005bac:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	866080e7          	jalr	-1946(ra) # 80004414 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bb6:	08000613          	li	a2,128
    80005bba:	f7040593          	addi	a1,s0,-144
    80005bbe:	4501                	li	a0,0
    80005bc0:	ffffd097          	auipc	ra,0xffffd
    80005bc4:	0d4080e7          	jalr	212(ra) # 80002c94 <argstr>
    80005bc8:	04054a63          	bltz	a0,80005c1c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005bcc:	f6c40593          	addi	a1,s0,-148
    80005bd0:	4505                	li	a0,1
    80005bd2:	ffffd097          	auipc	ra,0xffffd
    80005bd6:	07e080e7          	jalr	126(ra) # 80002c50 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bda:	04054163          	bltz	a0,80005c1c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005bde:	f6840593          	addi	a1,s0,-152
    80005be2:	4509                	li	a0,2
    80005be4:	ffffd097          	auipc	ra,0xffffd
    80005be8:	06c080e7          	jalr	108(ra) # 80002c50 <argint>
     argint(1, &major) < 0 ||
    80005bec:	02054863          	bltz	a0,80005c1c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bf0:	f6841683          	lh	a3,-152(s0)
    80005bf4:	f6c41603          	lh	a2,-148(s0)
    80005bf8:	458d                	li	a1,3
    80005bfa:	f7040513          	addi	a0,s0,-144
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	776080e7          	jalr	1910(ra) # 80005374 <create>
     argint(2, &minor) < 0 ||
    80005c06:	c919                	beqz	a0,80005c1c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	09c080e7          	jalr	156(ra) # 80003ca4 <iunlockput>
  end_op();
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	884080e7          	jalr	-1916(ra) # 80004494 <end_op>
  return 0;
    80005c18:	4501                	li	a0,0
    80005c1a:	a031                	j	80005c26 <sys_mknod+0x80>
    end_op();
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	878080e7          	jalr	-1928(ra) # 80004494 <end_op>
    return -1;
    80005c24:	557d                	li	a0,-1
}
    80005c26:	60ea                	ld	ra,152(sp)
    80005c28:	644a                	ld	s0,144(sp)
    80005c2a:	610d                	addi	sp,sp,160
    80005c2c:	8082                	ret

0000000080005c2e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c2e:	7135                	addi	sp,sp,-160
    80005c30:	ed06                	sd	ra,152(sp)
    80005c32:	e922                	sd	s0,144(sp)
    80005c34:	e526                	sd	s1,136(sp)
    80005c36:	e14a                	sd	s2,128(sp)
    80005c38:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c3a:	ffffc097          	auipc	ra,0xffffc
    80005c3e:	dd4080e7          	jalr	-556(ra) # 80001a0e <myproc>
    80005c42:	892a                	mv	s2,a0
  
  begin_op();
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	7d0080e7          	jalr	2000(ra) # 80004414 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c4c:	08000613          	li	a2,128
    80005c50:	f6040593          	addi	a1,s0,-160
    80005c54:	4501                	li	a0,0
    80005c56:	ffffd097          	auipc	ra,0xffffd
    80005c5a:	03e080e7          	jalr	62(ra) # 80002c94 <argstr>
    80005c5e:	04054b63          	bltz	a0,80005cb4 <sys_chdir+0x86>
    80005c62:	f6040513          	addi	a0,s0,-160
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	592080e7          	jalr	1426(ra) # 800041f8 <namei>
    80005c6e:	84aa                	mv	s1,a0
    80005c70:	c131                	beqz	a0,80005cb4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	dd0080e7          	jalr	-560(ra) # 80003a42 <ilock>
  if(ip->type != T_DIR){
    80005c7a:	04449703          	lh	a4,68(s1)
    80005c7e:	4785                	li	a5,1
    80005c80:	04f71063          	bne	a4,a5,80005cc0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c84:	8526                	mv	a0,s1
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	e7e080e7          	jalr	-386(ra) # 80003b04 <iunlock>
  iput(p->cwd);
    80005c8e:	15093503          	ld	a0,336(s2)
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	f6a080e7          	jalr	-150(ra) # 80003bfc <iput>
  end_op();
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	7fa080e7          	jalr	2042(ra) # 80004494 <end_op>
  p->cwd = ip;
    80005ca2:	14993823          	sd	s1,336(s2)
  return 0;
    80005ca6:	4501                	li	a0,0
}
    80005ca8:	60ea                	ld	ra,152(sp)
    80005caa:	644a                	ld	s0,144(sp)
    80005cac:	64aa                	ld	s1,136(sp)
    80005cae:	690a                	ld	s2,128(sp)
    80005cb0:	610d                	addi	sp,sp,160
    80005cb2:	8082                	ret
    end_op();
    80005cb4:	ffffe097          	auipc	ra,0xffffe
    80005cb8:	7e0080e7          	jalr	2016(ra) # 80004494 <end_op>
    return -1;
    80005cbc:	557d                	li	a0,-1
    80005cbe:	b7ed                	j	80005ca8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005cc0:	8526                	mv	a0,s1
    80005cc2:	ffffe097          	auipc	ra,0xffffe
    80005cc6:	fe2080e7          	jalr	-30(ra) # 80003ca4 <iunlockput>
    end_op();
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	7ca080e7          	jalr	1994(ra) # 80004494 <end_op>
    return -1;
    80005cd2:	557d                	li	a0,-1
    80005cd4:	bfd1                	j	80005ca8 <sys_chdir+0x7a>

0000000080005cd6 <sys_exec>:

uint64
sys_exec(void)
{
    80005cd6:	7145                	addi	sp,sp,-464
    80005cd8:	e786                	sd	ra,456(sp)
    80005cda:	e3a2                	sd	s0,448(sp)
    80005cdc:	ff26                	sd	s1,440(sp)
    80005cde:	fb4a                	sd	s2,432(sp)
    80005ce0:	f74e                	sd	s3,424(sp)
    80005ce2:	f352                	sd	s4,416(sp)
    80005ce4:	ef56                	sd	s5,408(sp)
    80005ce6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ce8:	08000613          	li	a2,128
    80005cec:	f4040593          	addi	a1,s0,-192
    80005cf0:	4501                	li	a0,0
    80005cf2:	ffffd097          	auipc	ra,0xffffd
    80005cf6:	fa2080e7          	jalr	-94(ra) # 80002c94 <argstr>
    return -1;
    80005cfa:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cfc:	0c054a63          	bltz	a0,80005dd0 <sys_exec+0xfa>
    80005d00:	e3840593          	addi	a1,s0,-456
    80005d04:	4505                	li	a0,1
    80005d06:	ffffd097          	auipc	ra,0xffffd
    80005d0a:	f6c080e7          	jalr	-148(ra) # 80002c72 <argaddr>
    80005d0e:	0c054163          	bltz	a0,80005dd0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d12:	10000613          	li	a2,256
    80005d16:	4581                	li	a1,0
    80005d18:	e4040513          	addi	a0,s0,-448
    80005d1c:	ffffb097          	auipc	ra,0xffffb
    80005d20:	fc4080e7          	jalr	-60(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d24:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d28:	89a6                	mv	s3,s1
    80005d2a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d2c:	02000a13          	li	s4,32
    80005d30:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d34:	00391513          	slli	a0,s2,0x3
    80005d38:	e3040593          	addi	a1,s0,-464
    80005d3c:	e3843783          	ld	a5,-456(s0)
    80005d40:	953e                	add	a0,a0,a5
    80005d42:	ffffd097          	auipc	ra,0xffffd
    80005d46:	e74080e7          	jalr	-396(ra) # 80002bb6 <fetchaddr>
    80005d4a:	02054a63          	bltz	a0,80005d7e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005d4e:	e3043783          	ld	a5,-464(s0)
    80005d52:	c3b9                	beqz	a5,80005d98 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d54:	ffffb097          	auipc	ra,0xffffb
    80005d58:	da0080e7          	jalr	-608(ra) # 80000af4 <kalloc>
    80005d5c:	85aa                	mv	a1,a0
    80005d5e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d62:	cd11                	beqz	a0,80005d7e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d64:	6605                	lui	a2,0x1
    80005d66:	e3043503          	ld	a0,-464(s0)
    80005d6a:	ffffd097          	auipc	ra,0xffffd
    80005d6e:	e9e080e7          	jalr	-354(ra) # 80002c08 <fetchstr>
    80005d72:	00054663          	bltz	a0,80005d7e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d76:	0905                	addi	s2,s2,1
    80005d78:	09a1                	addi	s3,s3,8
    80005d7a:	fb491be3          	bne	s2,s4,80005d30 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d7e:	10048913          	addi	s2,s1,256
    80005d82:	6088                	ld	a0,0(s1)
    80005d84:	c529                	beqz	a0,80005dce <sys_exec+0xf8>
    kfree(argv[i]);
    80005d86:	ffffb097          	auipc	ra,0xffffb
    80005d8a:	c72080e7          	jalr	-910(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d8e:	04a1                	addi	s1,s1,8
    80005d90:	ff2499e3          	bne	s1,s2,80005d82 <sys_exec+0xac>
  return -1;
    80005d94:	597d                	li	s2,-1
    80005d96:	a82d                	j	80005dd0 <sys_exec+0xfa>
      argv[i] = 0;
    80005d98:	0a8e                	slli	s5,s5,0x3
    80005d9a:	fc040793          	addi	a5,s0,-64
    80005d9e:	9abe                	add	s5,s5,a5
    80005da0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005da4:	e4040593          	addi	a1,s0,-448
    80005da8:	f4040513          	addi	a0,s0,-192
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	194080e7          	jalr	404(ra) # 80004f40 <exec>
    80005db4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005db6:	10048993          	addi	s3,s1,256
    80005dba:	6088                	ld	a0,0(s1)
    80005dbc:	c911                	beqz	a0,80005dd0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005dbe:	ffffb097          	auipc	ra,0xffffb
    80005dc2:	c3a080e7          	jalr	-966(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dc6:	04a1                	addi	s1,s1,8
    80005dc8:	ff3499e3          	bne	s1,s3,80005dba <sys_exec+0xe4>
    80005dcc:	a011                	j	80005dd0 <sys_exec+0xfa>
  return -1;
    80005dce:	597d                	li	s2,-1
}
    80005dd0:	854a                	mv	a0,s2
    80005dd2:	60be                	ld	ra,456(sp)
    80005dd4:	641e                	ld	s0,448(sp)
    80005dd6:	74fa                	ld	s1,440(sp)
    80005dd8:	795a                	ld	s2,432(sp)
    80005dda:	79ba                	ld	s3,424(sp)
    80005ddc:	7a1a                	ld	s4,416(sp)
    80005dde:	6afa                	ld	s5,408(sp)
    80005de0:	6179                	addi	sp,sp,464
    80005de2:	8082                	ret

0000000080005de4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005de4:	7139                	addi	sp,sp,-64
    80005de6:	fc06                	sd	ra,56(sp)
    80005de8:	f822                	sd	s0,48(sp)
    80005dea:	f426                	sd	s1,40(sp)
    80005dec:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dee:	ffffc097          	auipc	ra,0xffffc
    80005df2:	c20080e7          	jalr	-992(ra) # 80001a0e <myproc>
    80005df6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005df8:	fd840593          	addi	a1,s0,-40
    80005dfc:	4501                	li	a0,0
    80005dfe:	ffffd097          	auipc	ra,0xffffd
    80005e02:	e74080e7          	jalr	-396(ra) # 80002c72 <argaddr>
    return -1;
    80005e06:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e08:	0e054063          	bltz	a0,80005ee8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005e0c:	fc840593          	addi	a1,s0,-56
    80005e10:	fd040513          	addi	a0,s0,-48
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	dfc080e7          	jalr	-516(ra) # 80004c10 <pipealloc>
    return -1;
    80005e1c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e1e:	0c054563          	bltz	a0,80005ee8 <sys_pipe+0x104>
  fd0 = -1;
    80005e22:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e26:	fd043503          	ld	a0,-48(s0)
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	508080e7          	jalr	1288(ra) # 80005332 <fdalloc>
    80005e32:	fca42223          	sw	a0,-60(s0)
    80005e36:	08054c63          	bltz	a0,80005ece <sys_pipe+0xea>
    80005e3a:	fc843503          	ld	a0,-56(s0)
    80005e3e:	fffff097          	auipc	ra,0xfffff
    80005e42:	4f4080e7          	jalr	1268(ra) # 80005332 <fdalloc>
    80005e46:	fca42023          	sw	a0,-64(s0)
    80005e4a:	06054863          	bltz	a0,80005eba <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e4e:	4691                	li	a3,4
    80005e50:	fc440613          	addi	a2,s0,-60
    80005e54:	fd843583          	ld	a1,-40(s0)
    80005e58:	68a8                	ld	a0,80(s1)
    80005e5a:	ffffc097          	auipc	ra,0xffffc
    80005e5e:	818080e7          	jalr	-2024(ra) # 80001672 <copyout>
    80005e62:	02054063          	bltz	a0,80005e82 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e66:	4691                	li	a3,4
    80005e68:	fc040613          	addi	a2,s0,-64
    80005e6c:	fd843583          	ld	a1,-40(s0)
    80005e70:	0591                	addi	a1,a1,4
    80005e72:	68a8                	ld	a0,80(s1)
    80005e74:	ffffb097          	auipc	ra,0xffffb
    80005e78:	7fe080e7          	jalr	2046(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e7c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e7e:	06055563          	bgez	a0,80005ee8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e82:	fc442783          	lw	a5,-60(s0)
    80005e86:	07e9                	addi	a5,a5,26
    80005e88:	078e                	slli	a5,a5,0x3
    80005e8a:	97a6                	add	a5,a5,s1
    80005e8c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e90:	fc042503          	lw	a0,-64(s0)
    80005e94:	0569                	addi	a0,a0,26
    80005e96:	050e                	slli	a0,a0,0x3
    80005e98:	9526                	add	a0,a0,s1
    80005e9a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e9e:	fd043503          	ld	a0,-48(s0)
    80005ea2:	fffff097          	auipc	ra,0xfffff
    80005ea6:	a3e080e7          	jalr	-1474(ra) # 800048e0 <fileclose>
    fileclose(wf);
    80005eaa:	fc843503          	ld	a0,-56(s0)
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	a32080e7          	jalr	-1486(ra) # 800048e0 <fileclose>
    return -1;
    80005eb6:	57fd                	li	a5,-1
    80005eb8:	a805                	j	80005ee8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005eba:	fc442783          	lw	a5,-60(s0)
    80005ebe:	0007c863          	bltz	a5,80005ece <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ec2:	01a78513          	addi	a0,a5,26
    80005ec6:	050e                	slli	a0,a0,0x3
    80005ec8:	9526                	add	a0,a0,s1
    80005eca:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ece:	fd043503          	ld	a0,-48(s0)
    80005ed2:	fffff097          	auipc	ra,0xfffff
    80005ed6:	a0e080e7          	jalr	-1522(ra) # 800048e0 <fileclose>
    fileclose(wf);
    80005eda:	fc843503          	ld	a0,-56(s0)
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	a02080e7          	jalr	-1534(ra) # 800048e0 <fileclose>
    return -1;
    80005ee6:	57fd                	li	a5,-1
}
    80005ee8:	853e                	mv	a0,a5
    80005eea:	70e2                	ld	ra,56(sp)
    80005eec:	7442                	ld	s0,48(sp)
    80005eee:	74a2                	ld	s1,40(sp)
    80005ef0:	6121                	addi	sp,sp,64
    80005ef2:	8082                	ret
	...

0000000080005f00 <kernelvec>:
    80005f00:	7111                	addi	sp,sp,-256
    80005f02:	e006                	sd	ra,0(sp)
    80005f04:	e40a                	sd	sp,8(sp)
    80005f06:	e80e                	sd	gp,16(sp)
    80005f08:	ec12                	sd	tp,24(sp)
    80005f0a:	f016                	sd	t0,32(sp)
    80005f0c:	f41a                	sd	t1,40(sp)
    80005f0e:	f81e                	sd	t2,48(sp)
    80005f10:	fc22                	sd	s0,56(sp)
    80005f12:	e0a6                	sd	s1,64(sp)
    80005f14:	e4aa                	sd	a0,72(sp)
    80005f16:	e8ae                	sd	a1,80(sp)
    80005f18:	ecb2                	sd	a2,88(sp)
    80005f1a:	f0b6                	sd	a3,96(sp)
    80005f1c:	f4ba                	sd	a4,104(sp)
    80005f1e:	f8be                	sd	a5,112(sp)
    80005f20:	fcc2                	sd	a6,120(sp)
    80005f22:	e146                	sd	a7,128(sp)
    80005f24:	e54a                	sd	s2,136(sp)
    80005f26:	e94e                	sd	s3,144(sp)
    80005f28:	ed52                	sd	s4,152(sp)
    80005f2a:	f156                	sd	s5,160(sp)
    80005f2c:	f55a                	sd	s6,168(sp)
    80005f2e:	f95e                	sd	s7,176(sp)
    80005f30:	fd62                	sd	s8,184(sp)
    80005f32:	e1e6                	sd	s9,192(sp)
    80005f34:	e5ea                	sd	s10,200(sp)
    80005f36:	e9ee                	sd	s11,208(sp)
    80005f38:	edf2                	sd	t3,216(sp)
    80005f3a:	f1f6                	sd	t4,224(sp)
    80005f3c:	f5fa                	sd	t5,232(sp)
    80005f3e:	f9fe                	sd	t6,240(sp)
    80005f40:	b43fc0ef          	jal	ra,80002a82 <kerneltrap>
    80005f44:	6082                	ld	ra,0(sp)
    80005f46:	6122                	ld	sp,8(sp)
    80005f48:	61c2                	ld	gp,16(sp)
    80005f4a:	7282                	ld	t0,32(sp)
    80005f4c:	7322                	ld	t1,40(sp)
    80005f4e:	73c2                	ld	t2,48(sp)
    80005f50:	7462                	ld	s0,56(sp)
    80005f52:	6486                	ld	s1,64(sp)
    80005f54:	6526                	ld	a0,72(sp)
    80005f56:	65c6                	ld	a1,80(sp)
    80005f58:	6666                	ld	a2,88(sp)
    80005f5a:	7686                	ld	a3,96(sp)
    80005f5c:	7726                	ld	a4,104(sp)
    80005f5e:	77c6                	ld	a5,112(sp)
    80005f60:	7866                	ld	a6,120(sp)
    80005f62:	688a                	ld	a7,128(sp)
    80005f64:	692a                	ld	s2,136(sp)
    80005f66:	69ca                	ld	s3,144(sp)
    80005f68:	6a6a                	ld	s4,152(sp)
    80005f6a:	7a8a                	ld	s5,160(sp)
    80005f6c:	7b2a                	ld	s6,168(sp)
    80005f6e:	7bca                	ld	s7,176(sp)
    80005f70:	7c6a                	ld	s8,184(sp)
    80005f72:	6c8e                	ld	s9,192(sp)
    80005f74:	6d2e                	ld	s10,200(sp)
    80005f76:	6dce                	ld	s11,208(sp)
    80005f78:	6e6e                	ld	t3,216(sp)
    80005f7a:	7e8e                	ld	t4,224(sp)
    80005f7c:	7f2e                	ld	t5,232(sp)
    80005f7e:	7fce                	ld	t6,240(sp)
    80005f80:	6111                	addi	sp,sp,256
    80005f82:	10200073          	sret
    80005f86:	00000013          	nop
    80005f8a:	00000013          	nop
    80005f8e:	0001                	nop

0000000080005f90 <timervec>:
    80005f90:	34051573          	csrrw	a0,mscratch,a0
    80005f94:	e10c                	sd	a1,0(a0)
    80005f96:	e510                	sd	a2,8(a0)
    80005f98:	e914                	sd	a3,16(a0)
    80005f9a:	6d0c                	ld	a1,24(a0)
    80005f9c:	7110                	ld	a2,32(a0)
    80005f9e:	6194                	ld	a3,0(a1)
    80005fa0:	96b2                	add	a3,a3,a2
    80005fa2:	e194                	sd	a3,0(a1)
    80005fa4:	4589                	li	a1,2
    80005fa6:	14459073          	csrw	sip,a1
    80005faa:	6914                	ld	a3,16(a0)
    80005fac:	6510                	ld	a2,8(a0)
    80005fae:	610c                	ld	a1,0(a0)
    80005fb0:	34051573          	csrrw	a0,mscratch,a0
    80005fb4:	30200073          	mret
	...

0000000080005fba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fba:	1141                	addi	sp,sp,-16
    80005fbc:	e422                	sd	s0,8(sp)
    80005fbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fc0:	0c0007b7          	lui	a5,0xc000
    80005fc4:	4705                	li	a4,1
    80005fc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fc8:	c3d8                	sw	a4,4(a5)
}
    80005fca:	6422                	ld	s0,8(sp)
    80005fcc:	0141                	addi	sp,sp,16
    80005fce:	8082                	ret

0000000080005fd0 <plicinithart>:

void
plicinithart(void)
{
    80005fd0:	1141                	addi	sp,sp,-16
    80005fd2:	e406                	sd	ra,8(sp)
    80005fd4:	e022                	sd	s0,0(sp)
    80005fd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	a0a080e7          	jalr	-1526(ra) # 800019e2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fe0:	0085171b          	slliw	a4,a0,0x8
    80005fe4:	0c0027b7          	lui	a5,0xc002
    80005fe8:	97ba                	add	a5,a5,a4
    80005fea:	40200713          	li	a4,1026
    80005fee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ff2:	00d5151b          	slliw	a0,a0,0xd
    80005ff6:	0c2017b7          	lui	a5,0xc201
    80005ffa:	953e                	add	a0,a0,a5
    80005ffc:	00052023          	sw	zero,0(a0)
}
    80006000:	60a2                	ld	ra,8(sp)
    80006002:	6402                	ld	s0,0(sp)
    80006004:	0141                	addi	sp,sp,16
    80006006:	8082                	ret

0000000080006008 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006008:	1141                	addi	sp,sp,-16
    8000600a:	e406                	sd	ra,8(sp)
    8000600c:	e022                	sd	s0,0(sp)
    8000600e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006010:	ffffc097          	auipc	ra,0xffffc
    80006014:	9d2080e7          	jalr	-1582(ra) # 800019e2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006018:	00d5179b          	slliw	a5,a0,0xd
    8000601c:	0c201537          	lui	a0,0xc201
    80006020:	953e                	add	a0,a0,a5
  return irq;
}
    80006022:	4148                	lw	a0,4(a0)
    80006024:	60a2                	ld	ra,8(sp)
    80006026:	6402                	ld	s0,0(sp)
    80006028:	0141                	addi	sp,sp,16
    8000602a:	8082                	ret

000000008000602c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000602c:	1101                	addi	sp,sp,-32
    8000602e:	ec06                	sd	ra,24(sp)
    80006030:	e822                	sd	s0,16(sp)
    80006032:	e426                	sd	s1,8(sp)
    80006034:	1000                	addi	s0,sp,32
    80006036:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	9aa080e7          	jalr	-1622(ra) # 800019e2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006040:	00d5151b          	slliw	a0,a0,0xd
    80006044:	0c2017b7          	lui	a5,0xc201
    80006048:	97aa                	add	a5,a5,a0
    8000604a:	c3c4                	sw	s1,4(a5)
}
    8000604c:	60e2                	ld	ra,24(sp)
    8000604e:	6442                	ld	s0,16(sp)
    80006050:	64a2                	ld	s1,8(sp)
    80006052:	6105                	addi	sp,sp,32
    80006054:	8082                	ret

0000000080006056 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006056:	1141                	addi	sp,sp,-16
    80006058:	e406                	sd	ra,8(sp)
    8000605a:	e022                	sd	s0,0(sp)
    8000605c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000605e:	479d                	li	a5,7
    80006060:	06a7c963          	blt	a5,a0,800060d2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006064:	0001d797          	auipc	a5,0x1d
    80006068:	f9c78793          	addi	a5,a5,-100 # 80023000 <disk>
    8000606c:	00a78733          	add	a4,a5,a0
    80006070:	6789                	lui	a5,0x2
    80006072:	97ba                	add	a5,a5,a4
    80006074:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006078:	e7ad                	bnez	a5,800060e2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000607a:	00451793          	slli	a5,a0,0x4
    8000607e:	0001f717          	auipc	a4,0x1f
    80006082:	f8270713          	addi	a4,a4,-126 # 80025000 <disk+0x2000>
    80006086:	6314                	ld	a3,0(a4)
    80006088:	96be                	add	a3,a3,a5
    8000608a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000608e:	6314                	ld	a3,0(a4)
    80006090:	96be                	add	a3,a3,a5
    80006092:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006096:	6314                	ld	a3,0(a4)
    80006098:	96be                	add	a3,a3,a5
    8000609a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000609e:	6318                	ld	a4,0(a4)
    800060a0:	97ba                	add	a5,a5,a4
    800060a2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800060a6:	0001d797          	auipc	a5,0x1d
    800060aa:	f5a78793          	addi	a5,a5,-166 # 80023000 <disk>
    800060ae:	97aa                	add	a5,a5,a0
    800060b0:	6509                	lui	a0,0x2
    800060b2:	953e                	add	a0,a0,a5
    800060b4:	4785                	li	a5,1
    800060b6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800060ba:	0001f517          	auipc	a0,0x1f
    800060be:	f5e50513          	addi	a0,a0,-162 # 80025018 <disk+0x2018>
    800060c2:	ffffc097          	auipc	ra,0xffffc
    800060c6:	310080e7          	jalr	784(ra) # 800023d2 <wakeup>
}
    800060ca:	60a2                	ld	ra,8(sp)
    800060cc:	6402                	ld	s0,0(sp)
    800060ce:	0141                	addi	sp,sp,16
    800060d0:	8082                	ret
    panic("free_desc 1");
    800060d2:	00003517          	auipc	a0,0x3
    800060d6:	83e50513          	addi	a0,a0,-1986 # 80008910 <syscalls+0x328>
    800060da:	ffffa097          	auipc	ra,0xffffa
    800060de:	464080e7          	jalr	1124(ra) # 8000053e <panic>
    panic("free_desc 2");
    800060e2:	00003517          	auipc	a0,0x3
    800060e6:	83e50513          	addi	a0,a0,-1986 # 80008920 <syscalls+0x338>
    800060ea:	ffffa097          	auipc	ra,0xffffa
    800060ee:	454080e7          	jalr	1108(ra) # 8000053e <panic>

00000000800060f2 <virtio_disk_init>:
{
    800060f2:	1101                	addi	sp,sp,-32
    800060f4:	ec06                	sd	ra,24(sp)
    800060f6:	e822                	sd	s0,16(sp)
    800060f8:	e426                	sd	s1,8(sp)
    800060fa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060fc:	00003597          	auipc	a1,0x3
    80006100:	83458593          	addi	a1,a1,-1996 # 80008930 <syscalls+0x348>
    80006104:	0001f517          	auipc	a0,0x1f
    80006108:	02450513          	addi	a0,a0,36 # 80025128 <disk+0x2128>
    8000610c:	ffffb097          	auipc	ra,0xffffb
    80006110:	a48080e7          	jalr	-1464(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006114:	100017b7          	lui	a5,0x10001
    80006118:	4398                	lw	a4,0(a5)
    8000611a:	2701                	sext.w	a4,a4
    8000611c:	747277b7          	lui	a5,0x74727
    80006120:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006124:	0ef71163          	bne	a4,a5,80006206 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006128:	100017b7          	lui	a5,0x10001
    8000612c:	43dc                	lw	a5,4(a5)
    8000612e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006130:	4705                	li	a4,1
    80006132:	0ce79a63          	bne	a5,a4,80006206 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006136:	100017b7          	lui	a5,0x10001
    8000613a:	479c                	lw	a5,8(a5)
    8000613c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000613e:	4709                	li	a4,2
    80006140:	0ce79363          	bne	a5,a4,80006206 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006144:	100017b7          	lui	a5,0x10001
    80006148:	47d8                	lw	a4,12(a5)
    8000614a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000614c:	554d47b7          	lui	a5,0x554d4
    80006150:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006154:	0af71963          	bne	a4,a5,80006206 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006158:	100017b7          	lui	a5,0x10001
    8000615c:	4705                	li	a4,1
    8000615e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006160:	470d                	li	a4,3
    80006162:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006164:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006166:	c7ffe737          	lui	a4,0xc7ffe
    8000616a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000616e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006170:	2701                	sext.w	a4,a4
    80006172:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006174:	472d                	li	a4,11
    80006176:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006178:	473d                	li	a4,15
    8000617a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000617c:	6705                	lui	a4,0x1
    8000617e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006180:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006184:	5bdc                	lw	a5,52(a5)
    80006186:	2781                	sext.w	a5,a5
  if(max == 0)
    80006188:	c7d9                	beqz	a5,80006216 <virtio_disk_init+0x124>
  if(max < NUM)
    8000618a:	471d                	li	a4,7
    8000618c:	08f77d63          	bgeu	a4,a5,80006226 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006190:	100014b7          	lui	s1,0x10001
    80006194:	47a1                	li	a5,8
    80006196:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006198:	6609                	lui	a2,0x2
    8000619a:	4581                	li	a1,0
    8000619c:	0001d517          	auipc	a0,0x1d
    800061a0:	e6450513          	addi	a0,a0,-412 # 80023000 <disk>
    800061a4:	ffffb097          	auipc	ra,0xffffb
    800061a8:	b3c080e7          	jalr	-1220(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800061ac:	0001d717          	auipc	a4,0x1d
    800061b0:	e5470713          	addi	a4,a4,-428 # 80023000 <disk>
    800061b4:	00c75793          	srli	a5,a4,0xc
    800061b8:	2781                	sext.w	a5,a5
    800061ba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800061bc:	0001f797          	auipc	a5,0x1f
    800061c0:	e4478793          	addi	a5,a5,-444 # 80025000 <disk+0x2000>
    800061c4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800061c6:	0001d717          	auipc	a4,0x1d
    800061ca:	eba70713          	addi	a4,a4,-326 # 80023080 <disk+0x80>
    800061ce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800061d0:	0001e717          	auipc	a4,0x1e
    800061d4:	e3070713          	addi	a4,a4,-464 # 80024000 <disk+0x1000>
    800061d8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800061da:	4705                	li	a4,1
    800061dc:	00e78c23          	sb	a4,24(a5)
    800061e0:	00e78ca3          	sb	a4,25(a5)
    800061e4:	00e78d23          	sb	a4,26(a5)
    800061e8:	00e78da3          	sb	a4,27(a5)
    800061ec:	00e78e23          	sb	a4,28(a5)
    800061f0:	00e78ea3          	sb	a4,29(a5)
    800061f4:	00e78f23          	sb	a4,30(a5)
    800061f8:	00e78fa3          	sb	a4,31(a5)
}
    800061fc:	60e2                	ld	ra,24(sp)
    800061fe:	6442                	ld	s0,16(sp)
    80006200:	64a2                	ld	s1,8(sp)
    80006202:	6105                	addi	sp,sp,32
    80006204:	8082                	ret
    panic("could not find virtio disk");
    80006206:	00002517          	auipc	a0,0x2
    8000620a:	73a50513          	addi	a0,a0,1850 # 80008940 <syscalls+0x358>
    8000620e:	ffffa097          	auipc	ra,0xffffa
    80006212:	330080e7          	jalr	816(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006216:	00002517          	auipc	a0,0x2
    8000621a:	74a50513          	addi	a0,a0,1866 # 80008960 <syscalls+0x378>
    8000621e:	ffffa097          	auipc	ra,0xffffa
    80006222:	320080e7          	jalr	800(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006226:	00002517          	auipc	a0,0x2
    8000622a:	75a50513          	addi	a0,a0,1882 # 80008980 <syscalls+0x398>
    8000622e:	ffffa097          	auipc	ra,0xffffa
    80006232:	310080e7          	jalr	784(ra) # 8000053e <panic>

0000000080006236 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006236:	7159                	addi	sp,sp,-112
    80006238:	f486                	sd	ra,104(sp)
    8000623a:	f0a2                	sd	s0,96(sp)
    8000623c:	eca6                	sd	s1,88(sp)
    8000623e:	e8ca                	sd	s2,80(sp)
    80006240:	e4ce                	sd	s3,72(sp)
    80006242:	e0d2                	sd	s4,64(sp)
    80006244:	fc56                	sd	s5,56(sp)
    80006246:	f85a                	sd	s6,48(sp)
    80006248:	f45e                	sd	s7,40(sp)
    8000624a:	f062                	sd	s8,32(sp)
    8000624c:	ec66                	sd	s9,24(sp)
    8000624e:	e86a                	sd	s10,16(sp)
    80006250:	1880                	addi	s0,sp,112
    80006252:	892a                	mv	s2,a0
    80006254:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006256:	00c52c83          	lw	s9,12(a0)
    8000625a:	001c9c9b          	slliw	s9,s9,0x1
    8000625e:	1c82                	slli	s9,s9,0x20
    80006260:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006264:	0001f517          	auipc	a0,0x1f
    80006268:	ec450513          	addi	a0,a0,-316 # 80025128 <disk+0x2128>
    8000626c:	ffffb097          	auipc	ra,0xffffb
    80006270:	978080e7          	jalr	-1672(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006274:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006276:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006278:	0001db97          	auipc	s7,0x1d
    8000627c:	d88b8b93          	addi	s7,s7,-632 # 80023000 <disk>
    80006280:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006282:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006284:	8a4e                	mv	s4,s3
    80006286:	a051                	j	8000630a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006288:	00fb86b3          	add	a3,s7,a5
    8000628c:	96da                	add	a3,a3,s6
    8000628e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006292:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006294:	0207c563          	bltz	a5,800062be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006298:	2485                	addiw	s1,s1,1
    8000629a:	0711                	addi	a4,a4,4
    8000629c:	25548063          	beq	s1,s5,800064dc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800062a0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800062a2:	0001f697          	auipc	a3,0x1f
    800062a6:	d7668693          	addi	a3,a3,-650 # 80025018 <disk+0x2018>
    800062aa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800062ac:	0006c583          	lbu	a1,0(a3)
    800062b0:	fde1                	bnez	a1,80006288 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800062b2:	2785                	addiw	a5,a5,1
    800062b4:	0685                	addi	a3,a3,1
    800062b6:	ff879be3          	bne	a5,s8,800062ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800062ba:	57fd                	li	a5,-1
    800062bc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800062be:	02905a63          	blez	s1,800062f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062c2:	f9042503          	lw	a0,-112(s0)
    800062c6:	00000097          	auipc	ra,0x0
    800062ca:	d90080e7          	jalr	-624(ra) # 80006056 <free_desc>
      for(int j = 0; j < i; j++)
    800062ce:	4785                	li	a5,1
    800062d0:	0297d163          	bge	a5,s1,800062f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062d4:	f9442503          	lw	a0,-108(s0)
    800062d8:	00000097          	auipc	ra,0x0
    800062dc:	d7e080e7          	jalr	-642(ra) # 80006056 <free_desc>
      for(int j = 0; j < i; j++)
    800062e0:	4789                	li	a5,2
    800062e2:	0097d863          	bge	a5,s1,800062f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062e6:	f9842503          	lw	a0,-104(s0)
    800062ea:	00000097          	auipc	ra,0x0
    800062ee:	d6c080e7          	jalr	-660(ra) # 80006056 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062f2:	0001f597          	auipc	a1,0x1f
    800062f6:	e3658593          	addi	a1,a1,-458 # 80025128 <disk+0x2128>
    800062fa:	0001f517          	auipc	a0,0x1f
    800062fe:	d1e50513          	addi	a0,a0,-738 # 80025018 <disk+0x2018>
    80006302:	ffffc097          	auipc	ra,0xffffc
    80006306:	df8080e7          	jalr	-520(ra) # 800020fa <sleep>
  for(int i = 0; i < 3; i++){
    8000630a:	f9040713          	addi	a4,s0,-112
    8000630e:	84ce                	mv	s1,s3
    80006310:	bf41                	j	800062a0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006312:	20058713          	addi	a4,a1,512
    80006316:	00471693          	slli	a3,a4,0x4
    8000631a:	0001d717          	auipc	a4,0x1d
    8000631e:	ce670713          	addi	a4,a4,-794 # 80023000 <disk>
    80006322:	9736                	add	a4,a4,a3
    80006324:	4685                	li	a3,1
    80006326:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000632a:	20058713          	addi	a4,a1,512
    8000632e:	00471693          	slli	a3,a4,0x4
    80006332:	0001d717          	auipc	a4,0x1d
    80006336:	cce70713          	addi	a4,a4,-818 # 80023000 <disk>
    8000633a:	9736                	add	a4,a4,a3
    8000633c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006340:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006344:	7679                	lui	a2,0xffffe
    80006346:	963e                	add	a2,a2,a5
    80006348:	0001f697          	auipc	a3,0x1f
    8000634c:	cb868693          	addi	a3,a3,-840 # 80025000 <disk+0x2000>
    80006350:	6298                	ld	a4,0(a3)
    80006352:	9732                	add	a4,a4,a2
    80006354:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006356:	6298                	ld	a4,0(a3)
    80006358:	9732                	add	a4,a4,a2
    8000635a:	4541                	li	a0,16
    8000635c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000635e:	6298                	ld	a4,0(a3)
    80006360:	9732                	add	a4,a4,a2
    80006362:	4505                	li	a0,1
    80006364:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006368:	f9442703          	lw	a4,-108(s0)
    8000636c:	6288                	ld	a0,0(a3)
    8000636e:	962a                	add	a2,a2,a0
    80006370:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006374:	0712                	slli	a4,a4,0x4
    80006376:	6290                	ld	a2,0(a3)
    80006378:	963a                	add	a2,a2,a4
    8000637a:	05890513          	addi	a0,s2,88
    8000637e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006380:	6294                	ld	a3,0(a3)
    80006382:	96ba                	add	a3,a3,a4
    80006384:	40000613          	li	a2,1024
    80006388:	c690                	sw	a2,8(a3)
  if(write)
    8000638a:	140d0063          	beqz	s10,800064ca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000638e:	0001f697          	auipc	a3,0x1f
    80006392:	c726b683          	ld	a3,-910(a3) # 80025000 <disk+0x2000>
    80006396:	96ba                	add	a3,a3,a4
    80006398:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000639c:	0001d817          	auipc	a6,0x1d
    800063a0:	c6480813          	addi	a6,a6,-924 # 80023000 <disk>
    800063a4:	0001f517          	auipc	a0,0x1f
    800063a8:	c5c50513          	addi	a0,a0,-932 # 80025000 <disk+0x2000>
    800063ac:	6114                	ld	a3,0(a0)
    800063ae:	96ba                	add	a3,a3,a4
    800063b0:	00c6d603          	lhu	a2,12(a3)
    800063b4:	00166613          	ori	a2,a2,1
    800063b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063bc:	f9842683          	lw	a3,-104(s0)
    800063c0:	6110                	ld	a2,0(a0)
    800063c2:	9732                	add	a4,a4,a2
    800063c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063c8:	20058613          	addi	a2,a1,512
    800063cc:	0612                	slli	a2,a2,0x4
    800063ce:	9642                	add	a2,a2,a6
    800063d0:	577d                	li	a4,-1
    800063d2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063d6:	00469713          	slli	a4,a3,0x4
    800063da:	6114                	ld	a3,0(a0)
    800063dc:	96ba                	add	a3,a3,a4
    800063de:	03078793          	addi	a5,a5,48
    800063e2:	97c2                	add	a5,a5,a6
    800063e4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800063e6:	611c                	ld	a5,0(a0)
    800063e8:	97ba                	add	a5,a5,a4
    800063ea:	4685                	li	a3,1
    800063ec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063ee:	611c                	ld	a5,0(a0)
    800063f0:	97ba                	add	a5,a5,a4
    800063f2:	4809                	li	a6,2
    800063f4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800063f8:	611c                	ld	a5,0(a0)
    800063fa:	973e                	add	a4,a4,a5
    800063fc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006400:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006404:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006408:	6518                	ld	a4,8(a0)
    8000640a:	00275783          	lhu	a5,2(a4)
    8000640e:	8b9d                	andi	a5,a5,7
    80006410:	0786                	slli	a5,a5,0x1
    80006412:	97ba                	add	a5,a5,a4
    80006414:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006418:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000641c:	6518                	ld	a4,8(a0)
    8000641e:	00275783          	lhu	a5,2(a4)
    80006422:	2785                	addiw	a5,a5,1
    80006424:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006428:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000642c:	100017b7          	lui	a5,0x10001
    80006430:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006434:	00492703          	lw	a4,4(s2)
    80006438:	4785                	li	a5,1
    8000643a:	02f71163          	bne	a4,a5,8000645c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000643e:	0001f997          	auipc	s3,0x1f
    80006442:	cea98993          	addi	s3,s3,-790 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006446:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006448:	85ce                	mv	a1,s3
    8000644a:	854a                	mv	a0,s2
    8000644c:	ffffc097          	auipc	ra,0xffffc
    80006450:	cae080e7          	jalr	-850(ra) # 800020fa <sleep>
  while(b->disk == 1) {
    80006454:	00492783          	lw	a5,4(s2)
    80006458:	fe9788e3          	beq	a5,s1,80006448 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000645c:	f9042903          	lw	s2,-112(s0)
    80006460:	20090793          	addi	a5,s2,512
    80006464:	00479713          	slli	a4,a5,0x4
    80006468:	0001d797          	auipc	a5,0x1d
    8000646c:	b9878793          	addi	a5,a5,-1128 # 80023000 <disk>
    80006470:	97ba                	add	a5,a5,a4
    80006472:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006476:	0001f997          	auipc	s3,0x1f
    8000647a:	b8a98993          	addi	s3,s3,-1142 # 80025000 <disk+0x2000>
    8000647e:	00491713          	slli	a4,s2,0x4
    80006482:	0009b783          	ld	a5,0(s3)
    80006486:	97ba                	add	a5,a5,a4
    80006488:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000648c:	854a                	mv	a0,s2
    8000648e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006492:	00000097          	auipc	ra,0x0
    80006496:	bc4080e7          	jalr	-1084(ra) # 80006056 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000649a:	8885                	andi	s1,s1,1
    8000649c:	f0ed                	bnez	s1,8000647e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000649e:	0001f517          	auipc	a0,0x1f
    800064a2:	c8a50513          	addi	a0,a0,-886 # 80025128 <disk+0x2128>
    800064a6:	ffffa097          	auipc	ra,0xffffa
    800064aa:	7f2080e7          	jalr	2034(ra) # 80000c98 <release>
}
    800064ae:	70a6                	ld	ra,104(sp)
    800064b0:	7406                	ld	s0,96(sp)
    800064b2:	64e6                	ld	s1,88(sp)
    800064b4:	6946                	ld	s2,80(sp)
    800064b6:	69a6                	ld	s3,72(sp)
    800064b8:	6a06                	ld	s4,64(sp)
    800064ba:	7ae2                	ld	s5,56(sp)
    800064bc:	7b42                	ld	s6,48(sp)
    800064be:	7ba2                	ld	s7,40(sp)
    800064c0:	7c02                	ld	s8,32(sp)
    800064c2:	6ce2                	ld	s9,24(sp)
    800064c4:	6d42                	ld	s10,16(sp)
    800064c6:	6165                	addi	sp,sp,112
    800064c8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800064ca:	0001f697          	auipc	a3,0x1f
    800064ce:	b366b683          	ld	a3,-1226(a3) # 80025000 <disk+0x2000>
    800064d2:	96ba                	add	a3,a3,a4
    800064d4:	4609                	li	a2,2
    800064d6:	00c69623          	sh	a2,12(a3)
    800064da:	b5c9                	j	8000639c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064dc:	f9042583          	lw	a1,-112(s0)
    800064e0:	20058793          	addi	a5,a1,512
    800064e4:	0792                	slli	a5,a5,0x4
    800064e6:	0001d517          	auipc	a0,0x1d
    800064ea:	bc250513          	addi	a0,a0,-1086 # 800230a8 <disk+0xa8>
    800064ee:	953e                	add	a0,a0,a5
  if(write)
    800064f0:	e20d11e3          	bnez	s10,80006312 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800064f4:	20058713          	addi	a4,a1,512
    800064f8:	00471693          	slli	a3,a4,0x4
    800064fc:	0001d717          	auipc	a4,0x1d
    80006500:	b0470713          	addi	a4,a4,-1276 # 80023000 <disk>
    80006504:	9736                	add	a4,a4,a3
    80006506:	0a072423          	sw	zero,168(a4)
    8000650a:	b505                	j	8000632a <virtio_disk_rw+0xf4>

000000008000650c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000650c:	1101                	addi	sp,sp,-32
    8000650e:	ec06                	sd	ra,24(sp)
    80006510:	e822                	sd	s0,16(sp)
    80006512:	e426                	sd	s1,8(sp)
    80006514:	e04a                	sd	s2,0(sp)
    80006516:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006518:	0001f517          	auipc	a0,0x1f
    8000651c:	c1050513          	addi	a0,a0,-1008 # 80025128 <disk+0x2128>
    80006520:	ffffa097          	auipc	ra,0xffffa
    80006524:	6c4080e7          	jalr	1732(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006528:	10001737          	lui	a4,0x10001
    8000652c:	533c                	lw	a5,96(a4)
    8000652e:	8b8d                	andi	a5,a5,3
    80006530:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006532:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006536:	0001f797          	auipc	a5,0x1f
    8000653a:	aca78793          	addi	a5,a5,-1334 # 80025000 <disk+0x2000>
    8000653e:	6b94                	ld	a3,16(a5)
    80006540:	0207d703          	lhu	a4,32(a5)
    80006544:	0026d783          	lhu	a5,2(a3)
    80006548:	06f70163          	beq	a4,a5,800065aa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000654c:	0001d917          	auipc	s2,0x1d
    80006550:	ab490913          	addi	s2,s2,-1356 # 80023000 <disk>
    80006554:	0001f497          	auipc	s1,0x1f
    80006558:	aac48493          	addi	s1,s1,-1364 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000655c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006560:	6898                	ld	a4,16(s1)
    80006562:	0204d783          	lhu	a5,32(s1)
    80006566:	8b9d                	andi	a5,a5,7
    80006568:	078e                	slli	a5,a5,0x3
    8000656a:	97ba                	add	a5,a5,a4
    8000656c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000656e:	20078713          	addi	a4,a5,512
    80006572:	0712                	slli	a4,a4,0x4
    80006574:	974a                	add	a4,a4,s2
    80006576:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000657a:	e731                	bnez	a4,800065c6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000657c:	20078793          	addi	a5,a5,512
    80006580:	0792                	slli	a5,a5,0x4
    80006582:	97ca                	add	a5,a5,s2
    80006584:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006586:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000658a:	ffffc097          	auipc	ra,0xffffc
    8000658e:	e48080e7          	jalr	-440(ra) # 800023d2 <wakeup>

    disk.used_idx += 1;
    80006592:	0204d783          	lhu	a5,32(s1)
    80006596:	2785                	addiw	a5,a5,1
    80006598:	17c2                	slli	a5,a5,0x30
    8000659a:	93c1                	srli	a5,a5,0x30
    8000659c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800065a0:	6898                	ld	a4,16(s1)
    800065a2:	00275703          	lhu	a4,2(a4)
    800065a6:	faf71be3          	bne	a4,a5,8000655c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800065aa:	0001f517          	auipc	a0,0x1f
    800065ae:	b7e50513          	addi	a0,a0,-1154 # 80025128 <disk+0x2128>
    800065b2:	ffffa097          	auipc	ra,0xffffa
    800065b6:	6e6080e7          	jalr	1766(ra) # 80000c98 <release>
}
    800065ba:	60e2                	ld	ra,24(sp)
    800065bc:	6442                	ld	s0,16(sp)
    800065be:	64a2                	ld	s1,8(sp)
    800065c0:	6902                	ld	s2,0(sp)
    800065c2:	6105                	addi	sp,sp,32
    800065c4:	8082                	ret
      panic("virtio_disk_intr status");
    800065c6:	00002517          	auipc	a0,0x2
    800065ca:	3da50513          	addi	a0,a0,986 # 800089a0 <syscalls+0x3b8>
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	f70080e7          	jalr	-144(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
