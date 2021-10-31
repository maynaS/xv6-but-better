
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
    80000068:	07c78793          	addi	a5,a5,124 # 800060e0 <timervec>
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
    80000130:	62a080e7          	jalr	1578(ra) # 80002756 <either_copyin>
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
    800001c8:	868080e7          	jalr	-1944(ra) # 80001a2c <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	030080e7          	jalr	48(ra) # 80002204 <sleep>
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
    80000214:	4f0080e7          	jalr	1264(ra) # 80002700 <either_copyout>
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
    800002f6:	4ba080e7          	jalr	1210(ra) # 800027ac <procdump>
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
    8000044a:	096080e7          	jalr	150(ra) # 800024dc <wakeup>
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
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	aa078793          	addi	a5,a5,-1376 # 80021f18 <devsw>
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
    80000570:	f8450513          	addi	a0,a0,-124 # 800084f0 <states.1773+0x230>
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
    800008a4:	c3c080e7          	jalr	-964(ra) # 800024dc <wakeup>
    
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
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	8d8080e7          	jalr	-1832(ra) # 80002204 <sleep>
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
    80000b82:	e92080e7          	jalr	-366(ra) # 80001a10 <mycpu>
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
    80000bb4:	e60080e7          	jalr	-416(ra) # 80001a10 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e54080e7          	jalr	-428(ra) # 80001a10 <mycpu>
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
    80000bd8:	e3c080e7          	jalr	-452(ra) # 80001a10 <mycpu>
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
    80000c18:	dfc080e7          	jalr	-516(ra) # 80001a10 <mycpu>
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
    80000c44:	dd0080e7          	jalr	-560(ra) # 80001a10 <mycpu>
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
    80000e9a:	b6a080e7          	jalr	-1174(ra) # 80001a00 <cpuid>
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
    80000eb6:	b4e080e7          	jalr	-1202(ra) # 80001a00 <cpuid>
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
    80000ed8:	a18080e7          	jalr	-1512(ra) # 800028ec <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	244080e7          	jalr	580(ra) # 80006120 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	0dc080e7          	jalr	220(ra) # 80001fc0 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	5f450513          	addi	a0,a0,1524 # 800084f0 <states.1773+0x230>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	5d450513          	addi	a0,a0,1492 # 800084f0 <states.1773+0x230>
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
    80000f48:	a0c080e7          	jalr	-1524(ra) # 80001950 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	978080e7          	jalr	-1672(ra) # 800028c4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	998080e7          	jalr	-1640(ra) # 800028ec <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	1ae080e7          	jalr	430(ra) # 8000610a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	1bc080e7          	jalr	444(ra) # 80006120 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	39c080e7          	jalr	924(ra) # 80003308 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	a2c080e7          	jalr	-1492(ra) # 800039a0 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	9d6080e7          	jalr	-1578(ra) # 80004952 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	2be080e7          	jalr	702(ra) # 80006242 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d9c080e7          	jalr	-612(ra) # 80001d28 <userinit>
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
    80001244:	67a080e7          	jalr	1658(ra) # 800018ba <proc_mapstacks>
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
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

void inc_runtime()
{
    8000183e:	7179                	addi	sp,sp,-48
    80001840:	f406                	sd	ra,40(sp)
    80001842:	f022                	sd	s0,32(sp)
    80001844:	ec26                	sd	s1,24(sp)
    80001846:	e84a                	sd	s2,16(sp)
    80001848:	e44e                	sd	s3,8(sp)
    8000184a:	e052                	sd	s4,0(sp)
    8000184c:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    8000184e:	00010497          	auipc	s1,0x10
    80001852:	e8248493          	addi	s1,s1,-382 # 800116d0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80001856:	4991                	li	s3,4
    {
      p->run_time++;
      p->newrun++;
    }
    if (p->state == SLEEPING)
    80001858:	4a09                	li	s4,2
  for (p = proc; p < &proc[NPROC]; p++)
    8000185a:	00016917          	auipc	s2,0x16
    8000185e:	47690913          	addi	s2,s2,1142 # 80017cd0 <tickslock>
    80001862:	a025                	j	8000188a <inc_runtime+0x4c>
      p->run_time++;
    80001864:	1744a783          	lw	a5,372(s1)
    80001868:	2785                	addiw	a5,a5,1
    8000186a:	16f4aa23          	sw	a5,372(s1)
      p->newrun++;
    8000186e:	1804a783          	lw	a5,384(s1)
    80001872:	2785                	addiw	a5,a5,1
    80001874:	18f4a023          	sw	a5,384(s1)
    {
      p->newsleep++;      
    }
    
    release(&p->lock);
    80001878:	8526                	mv	a0,s1
    8000187a:	fffff097          	auipc	ra,0xfffff
    8000187e:	41e080e7          	jalr	1054(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001882:	19848493          	addi	s1,s1,408
    80001886:	03248263          	beq	s1,s2,800018aa <inc_runtime+0x6c>
    acquire(&p->lock);
    8000188a:	8526                	mv	a0,s1
    8000188c:	fffff097          	auipc	ra,0xfffff
    80001890:	358080e7          	jalr	856(ra) # 80000be4 <acquire>
    if (p->state == RUNNING)
    80001894:	4c9c                	lw	a5,24(s1)
    80001896:	fd3787e3          	beq	a5,s3,80001864 <inc_runtime+0x26>
    if (p->state == SLEEPING)
    8000189a:	fd479fe3          	bne	a5,s4,80001878 <inc_runtime+0x3a>
      p->newsleep++;      
    8000189e:	1844a783          	lw	a5,388(s1)
    800018a2:	2785                	addiw	a5,a5,1
    800018a4:	18f4a223          	sw	a5,388(s1)
    800018a8:	bfc1                	j	80001878 <inc_runtime+0x3a>
  }
}
    800018aa:	70a2                	ld	ra,40(sp)
    800018ac:	7402                	ld	s0,32(sp)
    800018ae:	64e2                	ld	s1,24(sp)
    800018b0:	6942                	ld	s2,16(sp)
    800018b2:	69a2                	ld	s3,8(sp)
    800018b4:	6a02                	ld	s4,0(sp)
    800018b6:	6145                	addi	sp,sp,48
    800018b8:	8082                	ret

00000000800018ba <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
    800018ce:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800018d0:	00010497          	auipc	s1,0x10
    800018d4:	e0048493          	addi	s1,s1,-512 # 800116d0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800018d8:	8b26                	mv	s6,s1
    800018da:	00006a97          	auipc	s5,0x6
    800018de:	726a8a93          	addi	s5,s5,1830 # 80008000 <etext>
    800018e2:	04000937          	lui	s2,0x4000
    800018e6:	197d                	addi	s2,s2,-1
    800018e8:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800018ea:	00016a17          	auipc	s4,0x16
    800018ee:	3e6a0a13          	addi	s4,s4,998 # 80017cd0 <tickslock>
    char *pa = kalloc();
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	202080e7          	jalr	514(ra) # 80000af4 <kalloc>
    800018fa:	862a                	mv	a2,a0
    if (pa == 0)
    800018fc:	c131                	beqz	a0,80001940 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    800018fe:	416485b3          	sub	a1,s1,s6
    80001902:	858d                	srai	a1,a1,0x3
    80001904:	000ab783          	ld	a5,0(s5)
    80001908:	02f585b3          	mul	a1,a1,a5
    8000190c:	2585                	addiw	a1,a1,1
    8000190e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001912:	4719                	li	a4,6
    80001914:	6685                	lui	a3,0x1
    80001916:	40b905b3          	sub	a1,s2,a1
    8000191a:	854e                	mv	a0,s3
    8000191c:	00000097          	auipc	ra,0x0
    80001920:	834080e7          	jalr	-1996(ra) # 80001150 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001924:	19848493          	addi	s1,s1,408
    80001928:	fd4495e3          	bne	s1,s4,800018f2 <proc_mapstacks+0x38>
  }
}
    8000192c:	70e2                	ld	ra,56(sp)
    8000192e:	7442                	ld	s0,48(sp)
    80001930:	74a2                	ld	s1,40(sp)
    80001932:	7902                	ld	s2,32(sp)
    80001934:	69e2                	ld	s3,24(sp)
    80001936:	6a42                	ld	s4,16(sp)
    80001938:	6aa2                	ld	s5,8(sp)
    8000193a:	6b02                	ld	s6,0(sp)
    8000193c:	6121                	addi	sp,sp,64
    8000193e:	8082                	ret
      panic("kalloc");
    80001940:	00007517          	auipc	a0,0x7
    80001944:	89850513          	addi	a0,a0,-1896 # 800081d8 <digits+0x198>
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	bf6080e7          	jalr	-1034(ra) # 8000053e <panic>

0000000080001950 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    80001950:	7139                	addi	sp,sp,-64
    80001952:	fc06                	sd	ra,56(sp)
    80001954:	f822                	sd	s0,48(sp)
    80001956:	f426                	sd	s1,40(sp)
    80001958:	f04a                	sd	s2,32(sp)
    8000195a:	ec4e                	sd	s3,24(sp)
    8000195c:	e852                	sd	s4,16(sp)
    8000195e:	e456                	sd	s5,8(sp)
    80001960:	e05a                	sd	s6,0(sp)
    80001962:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001964:	00007597          	auipc	a1,0x7
    80001968:	87c58593          	addi	a1,a1,-1924 # 800081e0 <digits+0x1a0>
    8000196c:	00010517          	auipc	a0,0x10
    80001970:	93450513          	addi	a0,a0,-1740 # 800112a0 <pid_lock>
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	1e0080e7          	jalr	480(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000197c:	00007597          	auipc	a1,0x7
    80001980:	86c58593          	addi	a1,a1,-1940 # 800081e8 <digits+0x1a8>
    80001984:	00010517          	auipc	a0,0x10
    80001988:	93450513          	addi	a0,a0,-1740 # 800112b8 <wait_lock>
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	1c8080e7          	jalr	456(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001994:	00010497          	auipc	s1,0x10
    80001998:	d3c48493          	addi	s1,s1,-708 # 800116d0 <proc>
  {
    initlock(&p->lock, "proc");
    8000199c:	00007b17          	auipc	s6,0x7
    800019a0:	85cb0b13          	addi	s6,s6,-1956 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    800019a4:	8aa6                	mv	s5,s1
    800019a6:	00006a17          	auipc	s4,0x6
    800019aa:	65aa0a13          	addi	s4,s4,1626 # 80008000 <etext>
    800019ae:	04000937          	lui	s2,0x4000
    800019b2:	197d                	addi	s2,s2,-1
    800019b4:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800019b6:	00016997          	auipc	s3,0x16
    800019ba:	31a98993          	addi	s3,s3,794 # 80017cd0 <tickslock>
    initlock(&p->lock, "proc");
    800019be:	85da                	mv	a1,s6
    800019c0:	8526                	mv	a0,s1
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	192080e7          	jalr	402(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    800019ca:	415487b3          	sub	a5,s1,s5
    800019ce:	878d                	srai	a5,a5,0x3
    800019d0:	000a3703          	ld	a4,0(s4)
    800019d4:	02e787b3          	mul	a5,a5,a4
    800019d8:	2785                	addiw	a5,a5,1
    800019da:	00d7979b          	slliw	a5,a5,0xd
    800019de:	40f907b3          	sub	a5,s2,a5
    800019e2:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    800019e4:	19848493          	addi	s1,s1,408
    800019e8:	fd349be3          	bne	s1,s3,800019be <procinit+0x6e>
  }
}
    800019ec:	70e2                	ld	ra,56(sp)
    800019ee:	7442                	ld	s0,48(sp)
    800019f0:	74a2                	ld	s1,40(sp)
    800019f2:	7902                	ld	s2,32(sp)
    800019f4:	69e2                	ld	s3,24(sp)
    800019f6:	6a42                	ld	s4,16(sp)
    800019f8:	6aa2                	ld	s5,8(sp)
    800019fa:	6b02                	ld	s6,0(sp)
    800019fc:	6121                	addi	sp,sp,64
    800019fe:	8082                	ret

0000000080001a00 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a00:	1141                	addi	sp,sp,-16
    80001a02:	e422                	sd	s0,8(sp)
    80001a04:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a06:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a08:	2501                	sext.w	a0,a0
    80001a0a:	6422                	ld	s0,8(sp)
    80001a0c:	0141                	addi	sp,sp,16
    80001a0e:	8082                	ret

0000000080001a10 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001a10:	1141                	addi	sp,sp,-16
    80001a12:	e422                	sd	s0,8(sp)
    80001a14:	0800                	addi	s0,sp,16
    80001a16:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a18:	2781                	sext.w	a5,a5
    80001a1a:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a1c:	00010517          	auipc	a0,0x10
    80001a20:	8b450513          	addi	a0,a0,-1868 # 800112d0 <cpus>
    80001a24:	953e                	add	a0,a0,a5
    80001a26:	6422                	ld	s0,8(sp)
    80001a28:	0141                	addi	sp,sp,16
    80001a2a:	8082                	ret

0000000080001a2c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001a2c:	1101                	addi	sp,sp,-32
    80001a2e:	ec06                	sd	ra,24(sp)
    80001a30:	e822                	sd	s0,16(sp)
    80001a32:	e426                	sd	s1,8(sp)
    80001a34:	1000                	addi	s0,sp,32
  push_off();
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	162080e7          	jalr	354(ra) # 80000b98 <push_off>
    80001a3e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a40:	2781                	sext.w	a5,a5
    80001a42:	079e                	slli	a5,a5,0x7
    80001a44:	00010717          	auipc	a4,0x10
    80001a48:	85c70713          	addi	a4,a4,-1956 # 800112a0 <pid_lock>
    80001a4c:	97ba                	add	a5,a5,a4
    80001a4e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	1e8080e7          	jalr	488(ra) # 80000c38 <pop_off>
  return p;
}
    80001a58:	8526                	mv	a0,s1
    80001a5a:	60e2                	ld	ra,24(sp)
    80001a5c:	6442                	ld	s0,16(sp)
    80001a5e:	64a2                	ld	s1,8(sp)
    80001a60:	6105                	addi	sp,sp,32
    80001a62:	8082                	ret

0000000080001a64 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a64:	1141                	addi	sp,sp,-16
    80001a66:	e406                	sd	ra,8(sp)
    80001a68:	e022                	sd	s0,0(sp)
    80001a6a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a6c:	00000097          	auipc	ra,0x0
    80001a70:	fc0080e7          	jalr	-64(ra) # 80001a2c <myproc>
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	224080e7          	jalr	548(ra) # 80000c98 <release>

  if (first)
    80001a7c:	00007797          	auipc	a5,0x7
    80001a80:	f547a783          	lw	a5,-172(a5) # 800089d0 <first.1736>
    80001a84:	eb89                	bnez	a5,80001a96 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a86:	00001097          	auipc	ra,0x1
    80001a8a:	e7e080e7          	jalr	-386(ra) # 80002904 <usertrapret>
}
    80001a8e:	60a2                	ld	ra,8(sp)
    80001a90:	6402                	ld	s0,0(sp)
    80001a92:	0141                	addi	sp,sp,16
    80001a94:	8082                	ret
    first = 0;
    80001a96:	00007797          	auipc	a5,0x7
    80001a9a:	f207ad23          	sw	zero,-198(a5) # 800089d0 <first.1736>
    fsinit(ROOTDEV);
    80001a9e:	4505                	li	a0,1
    80001aa0:	00002097          	auipc	ra,0x2
    80001aa4:	e80080e7          	jalr	-384(ra) # 80003920 <fsinit>
    80001aa8:	bff9                	j	80001a86 <forkret+0x22>

0000000080001aaa <allocpid>:
{
    80001aaa:	1101                	addi	sp,sp,-32
    80001aac:	ec06                	sd	ra,24(sp)
    80001aae:	e822                	sd	s0,16(sp)
    80001ab0:	e426                	sd	s1,8(sp)
    80001ab2:	e04a                	sd	s2,0(sp)
    80001ab4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ab6:	0000f917          	auipc	s2,0xf
    80001aba:	7ea90913          	addi	s2,s2,2026 # 800112a0 <pid_lock>
    80001abe:	854a                	mv	a0,s2
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	124080e7          	jalr	292(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001ac8:	00007797          	auipc	a5,0x7
    80001acc:	f0c78793          	addi	a5,a5,-244 # 800089d4 <nextpid>
    80001ad0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ad2:	0014871b          	addiw	a4,s1,1
    80001ad6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad8:	854a                	mv	a0,s2
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	1be080e7          	jalr	446(ra) # 80000c98 <release>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret

0000000080001af0 <proc_pagetable>:
{
    80001af0:	1101                	addi	sp,sp,-32
    80001af2:	ec06                	sd	ra,24(sp)
    80001af4:	e822                	sd	s0,16(sp)
    80001af6:	e426                	sd	s1,8(sp)
    80001af8:	e04a                	sd	s2,0(sp)
    80001afa:	1000                	addi	s0,sp,32
    80001afc:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001afe:	00000097          	auipc	ra,0x0
    80001b02:	83c080e7          	jalr	-1988(ra) # 8000133a <uvmcreate>
    80001b06:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b08:	c121                	beqz	a0,80001b48 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b0a:	4729                	li	a4,10
    80001b0c:	00005697          	auipc	a3,0x5
    80001b10:	4f468693          	addi	a3,a3,1268 # 80007000 <_trampoline>
    80001b14:	6605                	lui	a2,0x1
    80001b16:	040005b7          	lui	a1,0x4000
    80001b1a:	15fd                	addi	a1,a1,-1
    80001b1c:	05b2                	slli	a1,a1,0xc
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	592080e7          	jalr	1426(ra) # 800010b0 <mappages>
    80001b26:	02054863          	bltz	a0,80001b56 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b2a:	4719                	li	a4,6
    80001b2c:	05893683          	ld	a3,88(s2)
    80001b30:	6605                	lui	a2,0x1
    80001b32:	020005b7          	lui	a1,0x2000
    80001b36:	15fd                	addi	a1,a1,-1
    80001b38:	05b6                	slli	a1,a1,0xd
    80001b3a:	8526                	mv	a0,s1
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	574080e7          	jalr	1396(ra) # 800010b0 <mappages>
    80001b44:	02054163          	bltz	a0,80001b66 <proc_pagetable+0x76>
}
    80001b48:	8526                	mv	a0,s1
    80001b4a:	60e2                	ld	ra,24(sp)
    80001b4c:	6442                	ld	s0,16(sp)
    80001b4e:	64a2                	ld	s1,8(sp)
    80001b50:	6902                	ld	s2,0(sp)
    80001b52:	6105                	addi	sp,sp,32
    80001b54:	8082                	ret
    uvmfree(pagetable, 0);
    80001b56:	4581                	li	a1,0
    80001b58:	8526                	mv	a0,s1
    80001b5a:	00000097          	auipc	ra,0x0
    80001b5e:	9dc080e7          	jalr	-1572(ra) # 80001536 <uvmfree>
    return 0;
    80001b62:	4481                	li	s1,0
    80001b64:	b7d5                	j	80001b48 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b66:	4681                	li	a3,0
    80001b68:	4605                	li	a2,1
    80001b6a:	040005b7          	lui	a1,0x4000
    80001b6e:	15fd                	addi	a1,a1,-1
    80001b70:	05b2                	slli	a1,a1,0xc
    80001b72:	8526                	mv	a0,s1
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	702080e7          	jalr	1794(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b7c:	4581                	li	a1,0
    80001b7e:	8526                	mv	a0,s1
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	9b6080e7          	jalr	-1610(ra) # 80001536 <uvmfree>
    return 0;
    80001b88:	4481                	li	s1,0
    80001b8a:	bf7d                	j	80001b48 <proc_pagetable+0x58>

0000000080001b8c <proc_freepagetable>:
{
    80001b8c:	1101                	addi	sp,sp,-32
    80001b8e:	ec06                	sd	ra,24(sp)
    80001b90:	e822                	sd	s0,16(sp)
    80001b92:	e426                	sd	s1,8(sp)
    80001b94:	e04a                	sd	s2,0(sp)
    80001b96:	1000                	addi	s0,sp,32
    80001b98:	84aa                	mv	s1,a0
    80001b9a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b9c:	4681                	li	a3,0
    80001b9e:	4605                	li	a2,1
    80001ba0:	040005b7          	lui	a1,0x4000
    80001ba4:	15fd                	addi	a1,a1,-1
    80001ba6:	05b2                	slli	a1,a1,0xc
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	6ce080e7          	jalr	1742(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bb0:	4681                	li	a3,0
    80001bb2:	4605                	li	a2,1
    80001bb4:	020005b7          	lui	a1,0x2000
    80001bb8:	15fd                	addi	a1,a1,-1
    80001bba:	05b6                	slli	a1,a1,0xd
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	6b8080e7          	jalr	1720(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc6:	85ca                	mv	a1,s2
    80001bc8:	8526                	mv	a0,s1
    80001bca:	00000097          	auipc	ra,0x0
    80001bce:	96c080e7          	jalr	-1684(ra) # 80001536 <uvmfree>
}
    80001bd2:	60e2                	ld	ra,24(sp)
    80001bd4:	6442                	ld	s0,16(sp)
    80001bd6:	64a2                	ld	s1,8(sp)
    80001bd8:	6902                	ld	s2,0(sp)
    80001bda:	6105                	addi	sp,sp,32
    80001bdc:	8082                	ret

0000000080001bde <freeproc>:
{
    80001bde:	1101                	addi	sp,sp,-32
    80001be0:	ec06                	sd	ra,24(sp)
    80001be2:	e822                	sd	s0,16(sp)
    80001be4:	e426                	sd	s1,8(sp)
    80001be6:	1000                	addi	s0,sp,32
    80001be8:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001bea:	6d28                	ld	a0,88(a0)
    80001bec:	c509                	beqz	a0,80001bf6 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	e0a080e7          	jalr	-502(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001bf6:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001bfa:	68a8                	ld	a0,80(s1)
    80001bfc:	c511                	beqz	a0,80001c08 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bfe:	64ac                	ld	a1,72(s1)
    80001c00:	00000097          	auipc	ra,0x0
    80001c04:	f8c080e7          	jalr	-116(ra) # 80001b8c <proc_freepagetable>
  p->pagetable = 0;
    80001c08:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c0c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c10:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c14:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c18:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c1c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c20:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c24:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c28:	0004ac23          	sw	zero,24(s1)
}
    80001c2c:	60e2                	ld	ra,24(sp)
    80001c2e:	6442                	ld	s0,16(sp)
    80001c30:	64a2                	ld	s1,8(sp)
    80001c32:	6105                	addi	sp,sp,32
    80001c34:	8082                	ret

0000000080001c36 <allocproc>:
{
    80001c36:	1101                	addi	sp,sp,-32
    80001c38:	ec06                	sd	ra,24(sp)
    80001c3a:	e822                	sd	s0,16(sp)
    80001c3c:	e426                	sd	s1,8(sp)
    80001c3e:	e04a                	sd	s2,0(sp)
    80001c40:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001c42:	00010497          	auipc	s1,0x10
    80001c46:	a8e48493          	addi	s1,s1,-1394 # 800116d0 <proc>
    80001c4a:	00016917          	auipc	s2,0x16
    80001c4e:	08690913          	addi	s2,s2,134 # 80017cd0 <tickslock>
    acquire(&p->lock);
    80001c52:	8526                	mv	a0,s1
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	f90080e7          	jalr	-112(ra) # 80000be4 <acquire>
    if (p->state == UNUSED)
    80001c5c:	4c9c                	lw	a5,24(s1)
    80001c5e:	cf81                	beqz	a5,80001c76 <allocproc+0x40>
      release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	036080e7          	jalr	54(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c6a:	19848493          	addi	s1,s1,408
    80001c6e:	ff2492e3          	bne	s1,s2,80001c52 <allocproc+0x1c>
  return 0;
    80001c72:	4481                	li	s1,0
    80001c74:	a89d                	j	80001cea <allocproc+0xb4>
  p->pid = allocpid();
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	e34080e7          	jalr	-460(ra) # 80001aaa <allocpid>
    80001c7e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c80:	4785                	li	a5,1
    80001c82:	cc9c                	sw	a5,24(s1)
  p->start_time = ticks;
    80001c84:	00007797          	auipc	a5,0x7
    80001c88:	3ac7a783          	lw	a5,940(a5) # 80009030 <ticks>
    80001c8c:	16f4a623          	sw	a5,364(s1)
  p->run_time = 0;
    80001c90:	1604aa23          	sw	zero,372(s1)
  p->end_time = 0;
    80001c94:	1604a823          	sw	zero,368(s1)
  p->static_priority = 60;
    80001c98:	03c00793          	li	a5,60
    80001c9c:	18f4a623          	sw	a5,396(s1)
  p->num_runs = 0;
    80001ca0:	1604ac23          	sw	zero,376(s1)
  p->timeslices = 0;
    80001ca4:	1804a823          	sw	zero,400(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	e4c080e7          	jalr	-436(ra) # 80000af4 <kalloc>
    80001cb0:	892a                	mv	s2,a0
    80001cb2:	eca8                	sd	a0,88(s1)
    80001cb4:	c131                	beqz	a0,80001cf8 <allocproc+0xc2>
  p->pagetable = proc_pagetable(p);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	e38080e7          	jalr	-456(ra) # 80001af0 <proc_pagetable>
    80001cc0:	892a                	mv	s2,a0
    80001cc2:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001cc4:	c531                	beqz	a0,80001d10 <allocproc+0xda>
  memset(&p->context, 0, sizeof(p->context));
    80001cc6:	07000613          	li	a2,112
    80001cca:	4581                	li	a1,0
    80001ccc:	06048513          	addi	a0,s1,96
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	010080e7          	jalr	16(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001cd8:	00000797          	auipc	a5,0x0
    80001cdc:	d8c78793          	addi	a5,a5,-628 # 80001a64 <forkret>
    80001ce0:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce2:	60bc                	ld	a5,64(s1)
    80001ce4:	6705                	lui	a4,0x1
    80001ce6:	97ba                	add	a5,a5,a4
    80001ce8:	f4bc                	sd	a5,104(s1)
}
    80001cea:	8526                	mv	a0,s1
    80001cec:	60e2                	ld	ra,24(sp)
    80001cee:	6442                	ld	s0,16(sp)
    80001cf0:	64a2                	ld	s1,8(sp)
    80001cf2:	6902                	ld	s2,0(sp)
    80001cf4:	6105                	addi	sp,sp,32
    80001cf6:	8082                	ret
    freeproc(p);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	00000097          	auipc	ra,0x0
    80001cfe:	ee4080e7          	jalr	-284(ra) # 80001bde <freeproc>
    release(&p->lock);
    80001d02:	8526                	mv	a0,s1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	f94080e7          	jalr	-108(ra) # 80000c98 <release>
    return 0;
    80001d0c:	84ca                	mv	s1,s2
    80001d0e:	bff1                	j	80001cea <allocproc+0xb4>
    freeproc(p);
    80001d10:	8526                	mv	a0,s1
    80001d12:	00000097          	auipc	ra,0x0
    80001d16:	ecc080e7          	jalr	-308(ra) # 80001bde <freeproc>
    release(&p->lock);
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	f7c080e7          	jalr	-132(ra) # 80000c98 <release>
    return 0;
    80001d24:	84ca                	mv	s1,s2
    80001d26:	b7d1                	j	80001cea <allocproc+0xb4>

0000000080001d28 <userinit>:
{
    80001d28:	1101                	addi	sp,sp,-32
    80001d2a:	ec06                	sd	ra,24(sp)
    80001d2c:	e822                	sd	s0,16(sp)
    80001d2e:	e426                	sd	s1,8(sp)
    80001d30:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d32:	00000097          	auipc	ra,0x0
    80001d36:	f04080e7          	jalr	-252(ra) # 80001c36 <allocproc>
    80001d3a:	84aa                	mv	s1,a0
  initproc = p;
    80001d3c:	00007797          	auipc	a5,0x7
    80001d40:	2ea7b623          	sd	a0,748(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d44:	03400613          	li	a2,52
    80001d48:	00007597          	auipc	a1,0x7
    80001d4c:	c9858593          	addi	a1,a1,-872 # 800089e0 <initcode>
    80001d50:	6928                	ld	a0,80(a0)
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	616080e7          	jalr	1558(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d5a:	6785                	lui	a5,0x1
    80001d5c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d5e:	6cb8                	ld	a4,88(s1)
    80001d60:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d64:	6cb8                	ld	a4,88(s1)
    80001d66:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d68:	4641                	li	a2,16
    80001d6a:	00006597          	auipc	a1,0x6
    80001d6e:	49658593          	addi	a1,a1,1174 # 80008200 <digits+0x1c0>
    80001d72:	15848513          	addi	a0,s1,344
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	0bc080e7          	jalr	188(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d7e:	00006517          	auipc	a0,0x6
    80001d82:	49250513          	addi	a0,a0,1170 # 80008210 <digits+0x1d0>
    80001d86:	00002097          	auipc	ra,0x2
    80001d8a:	5c8080e7          	jalr	1480(ra) # 8000434e <namei>
    80001d8e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d92:	478d                	li	a5,3
    80001d94:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d96:	8526                	mv	a0,s1
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	f00080e7          	jalr	-256(ra) # 80000c98 <release>
}
    80001da0:	60e2                	ld	ra,24(sp)
    80001da2:	6442                	ld	s0,16(sp)
    80001da4:	64a2                	ld	s1,8(sp)
    80001da6:	6105                	addi	sp,sp,32
    80001da8:	8082                	ret

0000000080001daa <growproc>:
{
    80001daa:	1101                	addi	sp,sp,-32
    80001dac:	ec06                	sd	ra,24(sp)
    80001dae:	e822                	sd	s0,16(sp)
    80001db0:	e426                	sd	s1,8(sp)
    80001db2:	e04a                	sd	s2,0(sp)
    80001db4:	1000                	addi	s0,sp,32
    80001db6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	c74080e7          	jalr	-908(ra) # 80001a2c <myproc>
    80001dc0:	892a                	mv	s2,a0
  sz = p->sz;
    80001dc2:	652c                	ld	a1,72(a0)
    80001dc4:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001dc8:	00904f63          	bgtz	s1,80001de6 <growproc+0x3c>
  else if (n < 0)
    80001dcc:	0204cc63          	bltz	s1,80001e04 <growproc+0x5a>
  p->sz = sz;
    80001dd0:	1602                	slli	a2,a2,0x20
    80001dd2:	9201                	srli	a2,a2,0x20
    80001dd4:	04c93423          	sd	a2,72(s2)
  return 0;
    80001dd8:	4501                	li	a0,0
}
    80001dda:	60e2                	ld	ra,24(sp)
    80001ddc:	6442                	ld	s0,16(sp)
    80001dde:	64a2                	ld	s1,8(sp)
    80001de0:	6902                	ld	s2,0(sp)
    80001de2:	6105                	addi	sp,sp,32
    80001de4:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001de6:	9e25                	addw	a2,a2,s1
    80001de8:	1602                	slli	a2,a2,0x20
    80001dea:	9201                	srli	a2,a2,0x20
    80001dec:	1582                	slli	a1,a1,0x20
    80001dee:	9181                	srli	a1,a1,0x20
    80001df0:	6928                	ld	a0,80(a0)
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	630080e7          	jalr	1584(ra) # 80001422 <uvmalloc>
    80001dfa:	0005061b          	sext.w	a2,a0
    80001dfe:	fa69                	bnez	a2,80001dd0 <growproc+0x26>
      return -1;
    80001e00:	557d                	li	a0,-1
    80001e02:	bfe1                	j	80001dda <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e04:	9e25                	addw	a2,a2,s1
    80001e06:	1602                	slli	a2,a2,0x20
    80001e08:	9201                	srli	a2,a2,0x20
    80001e0a:	1582                	slli	a1,a1,0x20
    80001e0c:	9181                	srli	a1,a1,0x20
    80001e0e:	6928                	ld	a0,80(a0)
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	5ca080e7          	jalr	1482(ra) # 800013da <uvmdealloc>
    80001e18:	0005061b          	sext.w	a2,a0
    80001e1c:	bf55                	j	80001dd0 <growproc+0x26>

0000000080001e1e <fork>:
{
    80001e1e:	7179                	addi	sp,sp,-48
    80001e20:	f406                	sd	ra,40(sp)
    80001e22:	f022                	sd	s0,32(sp)
    80001e24:	ec26                	sd	s1,24(sp)
    80001e26:	e84a                	sd	s2,16(sp)
    80001e28:	e44e                	sd	s3,8(sp)
    80001e2a:	e052                	sd	s4,0(sp)
    80001e2c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	bfe080e7          	jalr	-1026(ra) # 80001a2c <myproc>
    80001e36:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	dfe080e7          	jalr	-514(ra) # 80001c36 <allocproc>
    80001e40:	10050f63          	beqz	a0,80001f5e <fork+0x140>
    80001e44:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e46:	04893603          	ld	a2,72(s2)
    80001e4a:	692c                	ld	a1,80(a0)
    80001e4c:	05093503          	ld	a0,80(s2)
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	71e080e7          	jalr	1822(ra) # 8000156e <uvmcopy>
    80001e58:	04054a63          	bltz	a0,80001eac <fork+0x8e>
  np->sz = p->sz;
    80001e5c:	04893783          	ld	a5,72(s2)
    80001e60:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e64:	05893683          	ld	a3,88(s2)
    80001e68:	87b6                	mv	a5,a3
    80001e6a:	0589b703          	ld	a4,88(s3)
    80001e6e:	12068693          	addi	a3,a3,288
    80001e72:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e76:	6788                	ld	a0,8(a5)
    80001e78:	6b8c                	ld	a1,16(a5)
    80001e7a:	6f90                	ld	a2,24(a5)
    80001e7c:	01073023          	sd	a6,0(a4)
    80001e80:	e708                	sd	a0,8(a4)
    80001e82:	eb0c                	sd	a1,16(a4)
    80001e84:	ef10                	sd	a2,24(a4)
    80001e86:	02078793          	addi	a5,a5,32
    80001e8a:	02070713          	addi	a4,a4,32
    80001e8e:	fed792e3          	bne	a5,a3,80001e72 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e92:	0589b783          	ld	a5,88(s3)
    80001e96:	0607b823          	sd	zero,112(a5)
  np->tracy = p->tracy;
    80001e9a:	16892783          	lw	a5,360(s2)
    80001e9e:	16f9a423          	sw	a5,360(s3)
    80001ea2:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001ea6:	15000a13          	li	s4,336
    80001eaa:	a03d                	j	80001ed8 <fork+0xba>
    freeproc(np);
    80001eac:	854e                	mv	a0,s3
    80001eae:	00000097          	auipc	ra,0x0
    80001eb2:	d30080e7          	jalr	-720(ra) # 80001bde <freeproc>
    release(&np->lock);
    80001eb6:	854e                	mv	a0,s3
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	de0080e7          	jalr	-544(ra) # 80000c98 <release>
    return -1;
    80001ec0:	5a7d                	li	s4,-1
    80001ec2:	a069                	j	80001f4c <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ec4:	00003097          	auipc	ra,0x3
    80001ec8:	b20080e7          	jalr	-1248(ra) # 800049e4 <filedup>
    80001ecc:	009987b3          	add	a5,s3,s1
    80001ed0:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001ed2:	04a1                	addi	s1,s1,8
    80001ed4:	01448763          	beq	s1,s4,80001ee2 <fork+0xc4>
    if (p->ofile[i])
    80001ed8:	009907b3          	add	a5,s2,s1
    80001edc:	6388                	ld	a0,0(a5)
    80001ede:	f17d                	bnez	a0,80001ec4 <fork+0xa6>
    80001ee0:	bfcd                	j	80001ed2 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001ee2:	15093503          	ld	a0,336(s2)
    80001ee6:	00002097          	auipc	ra,0x2
    80001eea:	c74080e7          	jalr	-908(ra) # 80003b5a <idup>
    80001eee:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ef2:	4641                	li	a2,16
    80001ef4:	15890593          	addi	a1,s2,344
    80001ef8:	15898513          	addi	a0,s3,344
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	f36080e7          	jalr	-202(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f04:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f08:	854e                	mv	a0,s3
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	d8e080e7          	jalr	-626(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f12:	0000f497          	auipc	s1,0xf
    80001f16:	3a648493          	addi	s1,s1,934 # 800112b8 <wait_lock>
    80001f1a:	8526                	mv	a0,s1
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	cc8080e7          	jalr	-824(ra) # 80000be4 <acquire>
  np->parent = p;
    80001f24:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f28:	8526                	mv	a0,s1
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	d6e080e7          	jalr	-658(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f32:	854e                	mv	a0,s3
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	cb0080e7          	jalr	-848(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001f3c:	478d                	li	a5,3
    80001f3e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f42:	854e                	mv	a0,s3
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	d54080e7          	jalr	-684(ra) # 80000c98 <release>
}
    80001f4c:	8552                	mv	a0,s4
    80001f4e:	70a2                	ld	ra,40(sp)
    80001f50:	7402                	ld	s0,32(sp)
    80001f52:	64e2                	ld	s1,24(sp)
    80001f54:	6942                	ld	s2,16(sp)
    80001f56:	69a2                	ld	s3,8(sp)
    80001f58:	6a02                	ld	s4,0(sp)
    80001f5a:	6145                	addi	sp,sp,48
    80001f5c:	8082                	ret
    return -1;
    80001f5e:	5a7d                	li	s4,-1
    80001f60:	b7f5                	j	80001f4c <fork+0x12e>

0000000080001f62 <dyn_priority>:
{
    80001f62:	1141                	addi	sp,sp,-16
    80001f64:	e422                	sd	s0,8(sp)
    80001f66:	0800                	addi	s0,sp,16
  if (p->last_scheduled_time!=0 && p->num_runs!=0)
    80001f68:	17c52703          	lw	a4,380(a0)
  int niceness = 5;
    80001f6c:	4795                	li	a5,5
  if (p->last_scheduled_time!=0 && p->num_runs!=0)
    80001f6e:	cb0d                	beqz	a4,80001fa0 <dyn_priority+0x3e>
    80001f70:	17852703          	lw	a4,376(a0)
    80001f74:	c715                	beqz	a4,80001fa0 <dyn_priority+0x3e>
    int denom = p->newrun+p->newsleep;
    80001f76:	18452703          	lw	a4,388(a0)
    80001f7a:	18052683          	lw	a3,384(a0)
    80001f7e:	9eb9                	addw	a3,a3,a4
    80001f80:	0006861b          	sext.w	a2,a3
    if (denom!=0)
    80001f84:	ce11                	beqz	a2,80001fa0 <dyn_priority+0x3e>
      niceness = (int)((float)(numer/denom)*10);
    80001f86:	02d7473b          	divw	a4,a4,a3
    80001f8a:	d0077753          	fcvt.s.w	fa4,a4
    80001f8e:	00006797          	auipc	a5,0x6
    80001f92:	07a7a787          	flw	fa5,122(a5) # 80008008 <etext+0x8>
    80001f96:	10f777d3          	fmul.s	fa5,fa4,fa5
    80001f9a:	c00797d3          	fcvt.w.s	a5,fa5,rtz
    80001f9e:	2781                	sext.w	a5,a5
  return MAX(0,MIN(p->static_priority - niceness + 5, 100));
    80001fa0:	18c52503          	lw	a0,396(a0)
    80001fa4:	2515                	addiw	a0,a0,5
    80001fa6:	9d1d                	subw	a0,a0,a5
    80001fa8:	0005071b          	sext.w	a4,a0
    80001fac:	06400793          	li	a5,100
    80001fb0:	00e7f463          	bgeu	a5,a4,80001fb8 <dyn_priority+0x56>
    80001fb4:	06400513          	li	a0,100
}
    80001fb8:	2501                	sext.w	a0,a0
    80001fba:	6422                	ld	s0,8(sp)
    80001fbc:	0141                	addi	sp,sp,16
    80001fbe:	8082                	ret

0000000080001fc0 <scheduler>:
{
    80001fc0:	7139                	addi	sp,sp,-64
    80001fc2:	fc06                	sd	ra,56(sp)
    80001fc4:	f822                	sd	s0,48(sp)
    80001fc6:	f426                	sd	s1,40(sp)
    80001fc8:	f04a                	sd	s2,32(sp)
    80001fca:	ec4e                	sd	s3,24(sp)
    80001fcc:	e852                	sd	s4,16(sp)
    80001fce:	e456                	sd	s5,8(sp)
    80001fd0:	e05a                	sd	s6,0(sp)
    80001fd2:	0080                	addi	s0,sp,64
    80001fd4:	8792                	mv	a5,tp
  int id = r_tp();
    80001fd6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fd8:	00779a93          	slli	s5,a5,0x7
    80001fdc:	0000f717          	auipc	a4,0xf
    80001fe0:	2c470713          	addi	a4,a4,708 # 800112a0 <pid_lock>
    80001fe4:	9756                	add	a4,a4,s5
    80001fe6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fea:	0000f717          	auipc	a4,0xf
    80001fee:	2ee70713          	addi	a4,a4,750 # 800112d8 <cpus+0x8>
    80001ff2:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001ff4:	498d                	li	s3,3
        p->state = RUNNING;
    80001ff6:	4b11                	li	s6,4
        c->proc = p;
    80001ff8:	079e                	slli	a5,a5,0x7
    80001ffa:	0000fa17          	auipc	s4,0xf
    80001ffe:	2a6a0a13          	addi	s4,s4,678 # 800112a0 <pid_lock>
    80002002:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002004:	00016917          	auipc	s2,0x16
    80002008:	ccc90913          	addi	s2,s2,-820 # 80017cd0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000200c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002010:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002014:	10079073          	csrw	sstatus,a5
    80002018:	0000f497          	auipc	s1,0xf
    8000201c:	6b848493          	addi	s1,s1,1720 # 800116d0 <proc>
    80002020:	a03d                	j	8000204e <scheduler+0x8e>
        p->state = RUNNING;
    80002022:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002026:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000202a:	06048593          	addi	a1,s1,96
    8000202e:	8556                	mv	a0,s5
    80002030:	00001097          	auipc	ra,0x1
    80002034:	82a080e7          	jalr	-2006(ra) # 8000285a <swtch>
        c->proc = 0;
    80002038:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    8000203c:	8526                	mv	a0,s1
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	c5a080e7          	jalr	-934(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002046:	19848493          	addi	s1,s1,408
    8000204a:	fd2481e3          	beq	s1,s2,8000200c <scheduler+0x4c>
      acquire(&p->lock);
    8000204e:	8526                	mv	a0,s1
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	b94080e7          	jalr	-1132(ra) # 80000be4 <acquire>
      if (p->state == RUNNABLE)
    80002058:	4c9c                	lw	a5,24(s1)
    8000205a:	ff3791e3          	bne	a5,s3,8000203c <scheduler+0x7c>
    8000205e:	b7d1                	j	80002022 <scheduler+0x62>

0000000080002060 <sched>:
{
    80002060:	7179                	addi	sp,sp,-48
    80002062:	f406                	sd	ra,40(sp)
    80002064:	f022                	sd	s0,32(sp)
    80002066:	ec26                	sd	s1,24(sp)
    80002068:	e84a                	sd	s2,16(sp)
    8000206a:	e44e                	sd	s3,8(sp)
    8000206c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	9be080e7          	jalr	-1602(ra) # 80001a2c <myproc>
    80002076:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	af2080e7          	jalr	-1294(ra) # 80000b6a <holding>
    80002080:	c93d                	beqz	a0,800020f6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002082:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002084:	2781                	sext.w	a5,a5
    80002086:	079e                	slli	a5,a5,0x7
    80002088:	0000f717          	auipc	a4,0xf
    8000208c:	21870713          	addi	a4,a4,536 # 800112a0 <pid_lock>
    80002090:	97ba                	add	a5,a5,a4
    80002092:	0a87a703          	lw	a4,168(a5)
    80002096:	4785                	li	a5,1
    80002098:	06f71763          	bne	a4,a5,80002106 <sched+0xa6>
  if (p->state == RUNNING)
    8000209c:	4c98                	lw	a4,24(s1)
    8000209e:	4791                	li	a5,4
    800020a0:	06f70b63          	beq	a4,a5,80002116 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020a8:	8b89                	andi	a5,a5,2
  if (intr_get())
    800020aa:	efb5                	bnez	a5,80002126 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ac:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020ae:	0000f917          	auipc	s2,0xf
    800020b2:	1f290913          	addi	s2,s2,498 # 800112a0 <pid_lock>
    800020b6:	2781                	sext.w	a5,a5
    800020b8:	079e                	slli	a5,a5,0x7
    800020ba:	97ca                	add	a5,a5,s2
    800020bc:	0ac7a983          	lw	s3,172(a5)
    800020c0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020c2:	2781                	sext.w	a5,a5
    800020c4:	079e                	slli	a5,a5,0x7
    800020c6:	0000f597          	auipc	a1,0xf
    800020ca:	21258593          	addi	a1,a1,530 # 800112d8 <cpus+0x8>
    800020ce:	95be                	add	a1,a1,a5
    800020d0:	06048513          	addi	a0,s1,96
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	786080e7          	jalr	1926(ra) # 8000285a <swtch>
    800020dc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020de:	2781                	sext.w	a5,a5
    800020e0:	079e                	slli	a5,a5,0x7
    800020e2:	97ca                	add	a5,a5,s2
    800020e4:	0b37a623          	sw	s3,172(a5)
}
    800020e8:	70a2                	ld	ra,40(sp)
    800020ea:	7402                	ld	s0,32(sp)
    800020ec:	64e2                	ld	s1,24(sp)
    800020ee:	6942                	ld	s2,16(sp)
    800020f0:	69a2                	ld	s3,8(sp)
    800020f2:	6145                	addi	sp,sp,48
    800020f4:	8082                	ret
    panic("sched p->lock");
    800020f6:	00006517          	auipc	a0,0x6
    800020fa:	12250513          	addi	a0,a0,290 # 80008218 <digits+0x1d8>
    800020fe:	ffffe097          	auipc	ra,0xffffe
    80002102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    panic("sched locks");
    80002106:	00006517          	auipc	a0,0x6
    8000210a:	12250513          	addi	a0,a0,290 # 80008228 <digits+0x1e8>
    8000210e:	ffffe097          	auipc	ra,0xffffe
    80002112:	430080e7          	jalr	1072(ra) # 8000053e <panic>
    panic("sched running");
    80002116:	00006517          	auipc	a0,0x6
    8000211a:	12250513          	addi	a0,a0,290 # 80008238 <digits+0x1f8>
    8000211e:	ffffe097          	auipc	ra,0xffffe
    80002122:	420080e7          	jalr	1056(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002126:	00006517          	auipc	a0,0x6
    8000212a:	12250513          	addi	a0,a0,290 # 80008248 <digits+0x208>
    8000212e:	ffffe097          	auipc	ra,0xffffe
    80002132:	410080e7          	jalr	1040(ra) # 8000053e <panic>

0000000080002136 <yield>:
{
    80002136:	1101                	addi	sp,sp,-32
    80002138:	ec06                	sd	ra,24(sp)
    8000213a:	e822                	sd	s0,16(sp)
    8000213c:	e426                	sd	s1,8(sp)
    8000213e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002140:	00000097          	auipc	ra,0x0
    80002144:	8ec080e7          	jalr	-1812(ra) # 80001a2c <myproc>
    80002148:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	a9a080e7          	jalr	-1382(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002152:	478d                	li	a5,3
    80002154:	cc9c                	sw	a5,24(s1)
  sched();
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	f0a080e7          	jalr	-246(ra) # 80002060 <sched>
  release(&p->lock);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b38080e7          	jalr	-1224(ra) # 80000c98 <release>
}
    80002168:	60e2                	ld	ra,24(sp)
    8000216a:	6442                	ld	s0,16(sp)
    8000216c:	64a2                	ld	s1,8(sp)
    8000216e:	6105                	addi	sp,sp,32
    80002170:	8082                	ret

0000000080002172 <setpriority>:
{
    80002172:	7139                	addi	sp,sp,-64
    80002174:	fc06                	sd	ra,56(sp)
    80002176:	f822                	sd	s0,48(sp)
    80002178:	f426                	sd	s1,40(sp)
    8000217a:	f04a                	sd	s2,32(sp)
    8000217c:	ec4e                	sd	s3,24(sp)
    8000217e:	e852                	sd	s4,16(sp)
    80002180:	e456                	sd	s5,8(sp)
    80002182:	0080                	addi	s0,sp,64
  if (newpriority < 0 || newpriority > 100)
    80002184:	06400793          	li	a5,100
    80002188:	06a7e363          	bltu	a5,a0,800021ee <setpriority+0x7c>
    8000218c:	89ae                	mv	s3,a1
    8000218e:	8aaa                	mv	s5,a0
  for (p = proc; p < &proc[NPROC]; p++)
    80002190:	0000f497          	auipc	s1,0xf
    80002194:	54048493          	addi	s1,s1,1344 # 800116d0 <proc>
  int old_priority = 0,newpri = 0;
    80002198:	4901                	li	s2,0
  for (p = proc; p < &proc[NPROC]; p++)
    8000219a:	00016a17          	auipc	s4,0x16
    8000219e:	b36a0a13          	addi	s4,s4,-1226 # 80017cd0 <tickslock>
    800021a2:	a831                	j	800021be <setpriority+0x4c>
        yield();
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	f92080e7          	jalr	-110(ra) # 80002136 <yield>
    release(&p->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	aea080e7          	jalr	-1302(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800021b6:	19848493          	addi	s1,s1,408
    800021ba:	03448b63          	beq	s1,s4,800021f0 <setpriority+0x7e>
    acquire(&p->lock);
    800021be:	8526                	mv	a0,s1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	a24080e7          	jalr	-1500(ra) # 80000be4 <acquire>
    if (p->pid == pd)
    800021c8:	589c                	lw	a5,48(s1)
    800021ca:	ff3791e3          	bne	a5,s3,800021ac <setpriority+0x3a>
      old_priority = dyn_priority(p);
    800021ce:	8526                	mv	a0,s1
    800021d0:	00000097          	auipc	ra,0x0
    800021d4:	d92080e7          	jalr	-622(ra) # 80001f62 <dyn_priority>
    800021d8:	892a                	mv	s2,a0
      p->static_priority = newpriority;
    800021da:	1954a623          	sw	s5,396(s1)
      newpri = dyn_priority(p);
    800021de:	8526                	mv	a0,s1
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	d82080e7          	jalr	-638(ra) # 80001f62 <dyn_priority>
      if (newpri < old_priority)
    800021e8:	fd2552e3          	bge	a0,s2,800021ac <setpriority+0x3a>
    800021ec:	bf65                	j	800021a4 <setpriority+0x32>
    return -1;
    800021ee:	597d                	li	s2,-1
}
    800021f0:	854a                	mv	a0,s2
    800021f2:	70e2                	ld	ra,56(sp)
    800021f4:	7442                	ld	s0,48(sp)
    800021f6:	74a2                	ld	s1,40(sp)
    800021f8:	7902                	ld	s2,32(sp)
    800021fa:	69e2                	ld	s3,24(sp)
    800021fc:	6a42                	ld	s4,16(sp)
    800021fe:	6aa2                	ld	s5,8(sp)
    80002200:	6121                	addi	sp,sp,64
    80002202:	8082                	ret

0000000080002204 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002204:	7179                	addi	sp,sp,-48
    80002206:	f406                	sd	ra,40(sp)
    80002208:	f022                	sd	s0,32(sp)
    8000220a:	ec26                	sd	s1,24(sp)
    8000220c:	e84a                	sd	s2,16(sp)
    8000220e:	e44e                	sd	s3,8(sp)
    80002210:	1800                	addi	s0,sp,48
    80002212:	89aa                	mv	s3,a0
    80002214:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002216:	00000097          	auipc	ra,0x0
    8000221a:	816080e7          	jalr	-2026(ra) # 80001a2c <myproc>
    8000221e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	9c4080e7          	jalr	-1596(ra) # 80000be4 <acquire>
  release(lk);
    80002228:	854a                	mv	a0,s2
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	a6e080e7          	jalr	-1426(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002232:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002236:	4789                	li	a5,2
    80002238:	cc9c                	sw	a5,24(s1)

  sched();
    8000223a:	00000097          	auipc	ra,0x0
    8000223e:	e26080e7          	jalr	-474(ra) # 80002060 <sched>

  // Tidy up.
  p->chan = 0;
    80002242:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002246:	8526                	mv	a0,s1
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	a50080e7          	jalr	-1456(ra) # 80000c98 <release>
  acquire(lk);
    80002250:	854a                	mv	a0,s2
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	992080e7          	jalr	-1646(ra) # 80000be4 <acquire>
}
    8000225a:	70a2                	ld	ra,40(sp)
    8000225c:	7402                	ld	s0,32(sp)
    8000225e:	64e2                	ld	s1,24(sp)
    80002260:	6942                	ld	s2,16(sp)
    80002262:	69a2                	ld	s3,8(sp)
    80002264:	6145                	addi	sp,sp,48
    80002266:	8082                	ret

0000000080002268 <wait>:
{
    80002268:	715d                	addi	sp,sp,-80
    8000226a:	e486                	sd	ra,72(sp)
    8000226c:	e0a2                	sd	s0,64(sp)
    8000226e:	fc26                	sd	s1,56(sp)
    80002270:	f84a                	sd	s2,48(sp)
    80002272:	f44e                	sd	s3,40(sp)
    80002274:	f052                	sd	s4,32(sp)
    80002276:	ec56                	sd	s5,24(sp)
    80002278:	e85a                	sd	s6,16(sp)
    8000227a:	e45e                	sd	s7,8(sp)
    8000227c:	e062                	sd	s8,0(sp)
    8000227e:	0880                	addi	s0,sp,80
    80002280:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	7aa080e7          	jalr	1962(ra) # 80001a2c <myproc>
    8000228a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000228c:	0000f517          	auipc	a0,0xf
    80002290:	02c50513          	addi	a0,a0,44 # 800112b8 <wait_lock>
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	950080e7          	jalr	-1712(ra) # 80000be4 <acquire>
    havekids = 0;
    8000229c:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    8000229e:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    800022a0:	00016997          	auipc	s3,0x16
    800022a4:	a3098993          	addi	s3,s3,-1488 # 80017cd0 <tickslock>
        havekids = 1;
    800022a8:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800022aa:	0000fc17          	auipc	s8,0xf
    800022ae:	00ec0c13          	addi	s8,s8,14 # 800112b8 <wait_lock>
    havekids = 0;
    800022b2:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800022b4:	0000f497          	auipc	s1,0xf
    800022b8:	41c48493          	addi	s1,s1,1052 # 800116d0 <proc>
    800022bc:	a0bd                	j	8000232a <wait+0xc2>
          pid = np->pid;
    800022be:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022c2:	000b0e63          	beqz	s6,800022de <wait+0x76>
    800022c6:	4691                	li	a3,4
    800022c8:	02c48613          	addi	a2,s1,44
    800022cc:	85da                	mv	a1,s6
    800022ce:	05093503          	ld	a0,80(s2)
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	3a0080e7          	jalr	928(ra) # 80001672 <copyout>
    800022da:	02054563          	bltz	a0,80002304 <wait+0x9c>
          freeproc(np);
    800022de:	8526                	mv	a0,s1
    800022e0:	00000097          	auipc	ra,0x0
    800022e4:	8fe080e7          	jalr	-1794(ra) # 80001bde <freeproc>
          release(&np->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9ae080e7          	jalr	-1618(ra) # 80000c98 <release>
          release(&wait_lock);
    800022f2:	0000f517          	auipc	a0,0xf
    800022f6:	fc650513          	addi	a0,a0,-58 # 800112b8 <wait_lock>
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	99e080e7          	jalr	-1634(ra) # 80000c98 <release>
          return pid;
    80002302:	a09d                	j	80002368 <wait+0x100>
            release(&np->lock);
    80002304:	8526                	mv	a0,s1
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	992080e7          	jalr	-1646(ra) # 80000c98 <release>
            release(&wait_lock);
    8000230e:	0000f517          	auipc	a0,0xf
    80002312:	faa50513          	addi	a0,a0,-86 # 800112b8 <wait_lock>
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	982080e7          	jalr	-1662(ra) # 80000c98 <release>
            return -1;
    8000231e:	59fd                	li	s3,-1
    80002320:	a0a1                	j	80002368 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    80002322:	19848493          	addi	s1,s1,408
    80002326:	03348463          	beq	s1,s3,8000234e <wait+0xe6>
      if (np->parent == p)
    8000232a:	7c9c                	ld	a5,56(s1)
    8000232c:	ff279be3          	bne	a5,s2,80002322 <wait+0xba>
        acquire(&np->lock);
    80002330:	8526                	mv	a0,s1
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	8b2080e7          	jalr	-1870(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    8000233a:	4c9c                	lw	a5,24(s1)
    8000233c:	f94781e3          	beq	a5,s4,800022be <wait+0x56>
        release(&np->lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	956080e7          	jalr	-1706(ra) # 80000c98 <release>
        havekids = 1;
    8000234a:	8756                	mv	a4,s5
    8000234c:	bfd9                	j	80002322 <wait+0xba>
    if (!havekids || p->killed)
    8000234e:	c701                	beqz	a4,80002356 <wait+0xee>
    80002350:	02892783          	lw	a5,40(s2)
    80002354:	c79d                	beqz	a5,80002382 <wait+0x11a>
      release(&wait_lock);
    80002356:	0000f517          	auipc	a0,0xf
    8000235a:	f6250513          	addi	a0,a0,-158 # 800112b8 <wait_lock>
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	93a080e7          	jalr	-1734(ra) # 80000c98 <release>
      return -1;
    80002366:	59fd                	li	s3,-1
}
    80002368:	854e                	mv	a0,s3
    8000236a:	60a6                	ld	ra,72(sp)
    8000236c:	6406                	ld	s0,64(sp)
    8000236e:	74e2                	ld	s1,56(sp)
    80002370:	7942                	ld	s2,48(sp)
    80002372:	79a2                	ld	s3,40(sp)
    80002374:	7a02                	ld	s4,32(sp)
    80002376:	6ae2                	ld	s5,24(sp)
    80002378:	6b42                	ld	s6,16(sp)
    8000237a:	6ba2                	ld	s7,8(sp)
    8000237c:	6c02                	ld	s8,0(sp)
    8000237e:	6161                	addi	sp,sp,80
    80002380:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002382:	85e2                	mv	a1,s8
    80002384:	854a                	mv	a0,s2
    80002386:	00000097          	auipc	ra,0x0
    8000238a:	e7e080e7          	jalr	-386(ra) # 80002204 <sleep>
    havekids = 0;
    8000238e:	b715                	j	800022b2 <wait+0x4a>

0000000080002390 <waitx>:
{
    80002390:	711d                	addi	sp,sp,-96
    80002392:	ec86                	sd	ra,88(sp)
    80002394:	e8a2                	sd	s0,80(sp)
    80002396:	e4a6                	sd	s1,72(sp)
    80002398:	e0ca                	sd	s2,64(sp)
    8000239a:	fc4e                	sd	s3,56(sp)
    8000239c:	f852                	sd	s4,48(sp)
    8000239e:	f456                	sd	s5,40(sp)
    800023a0:	f05a                	sd	s6,32(sp)
    800023a2:	ec5e                	sd	s7,24(sp)
    800023a4:	e862                	sd	s8,16(sp)
    800023a6:	e466                	sd	s9,8(sp)
    800023a8:	e06a                	sd	s10,0(sp)
    800023aa:	1080                	addi	s0,sp,96
    800023ac:	8b2a                	mv	s6,a0
    800023ae:	8bae                	mv	s7,a1
    800023b0:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	67a080e7          	jalr	1658(ra) # 80001a2c <myproc>
    800023ba:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023bc:	0000f517          	auipc	a0,0xf
    800023c0:	efc50513          	addi	a0,a0,-260 # 800112b8 <wait_lock>
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	820080e7          	jalr	-2016(ra) # 80000be4 <acquire>
    havekids = 0;
    800023cc:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    800023ce:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    800023d0:	00016997          	auipc	s3,0x16
    800023d4:	90098993          	addi	s3,s3,-1792 # 80017cd0 <tickslock>
        havekids = 1;
    800023d8:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800023da:	0000fd17          	auipc	s10,0xf
    800023de:	eded0d13          	addi	s10,s10,-290 # 800112b8 <wait_lock>
    havekids = 0;
    800023e2:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800023e4:	0000f497          	auipc	s1,0xf
    800023e8:	2ec48493          	addi	s1,s1,748 # 800116d0 <proc>
    800023ec:	a059                	j	80002472 <waitx+0xe2>
          pid = np->pid;
    800023ee:	0304a983          	lw	s3,48(s1)
          *rtime = np->run_time;
    800023f2:	1744a703          	lw	a4,372(s1)
    800023f6:	00ec2023          	sw	a4,0(s8)
          *wtime = np->end_time - np->start_time - np->run_time;
    800023fa:	16c4a783          	lw	a5,364(s1)
    800023fe:	9f3d                	addw	a4,a4,a5
    80002400:	1704a783          	lw	a5,368(s1)
    80002404:	9f99                	subw	a5,a5,a4
    80002406:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd9000>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000240a:	000b0e63          	beqz	s6,80002426 <waitx+0x96>
    8000240e:	4691                	li	a3,4
    80002410:	02c48613          	addi	a2,s1,44
    80002414:	85da                	mv	a1,s6
    80002416:	05093503          	ld	a0,80(s2)
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	258080e7          	jalr	600(ra) # 80001672 <copyout>
    80002422:	02054563          	bltz	a0,8000244c <waitx+0xbc>
          freeproc(np);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	7b6080e7          	jalr	1974(ra) # 80001bde <freeproc>
          release(&np->lock);
    80002430:	8526                	mv	a0,s1
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	866080e7          	jalr	-1946(ra) # 80000c98 <release>
          release(&wait_lock);
    8000243a:	0000f517          	auipc	a0,0xf
    8000243e:	e7e50513          	addi	a0,a0,-386 # 800112b8 <wait_lock>
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	856080e7          	jalr	-1962(ra) # 80000c98 <release>
          return pid;
    8000244a:	a09d                	j	800024b0 <waitx+0x120>
            release(&np->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	84a080e7          	jalr	-1974(ra) # 80000c98 <release>
            release(&wait_lock);
    80002456:	0000f517          	auipc	a0,0xf
    8000245a:	e6250513          	addi	a0,a0,-414 # 800112b8 <wait_lock>
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	83a080e7          	jalr	-1990(ra) # 80000c98 <release>
            return -1;
    80002466:	59fd                	li	s3,-1
    80002468:	a0a1                	j	800024b0 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    8000246a:	19848493          	addi	s1,s1,408
    8000246e:	03348463          	beq	s1,s3,80002496 <waitx+0x106>
      if (np->parent == p)
    80002472:	7c9c                	ld	a5,56(s1)
    80002474:	ff279be3          	bne	a5,s2,8000246a <waitx+0xda>
        acquire(&np->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	76a080e7          	jalr	1898(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    80002482:	4c9c                	lw	a5,24(s1)
    80002484:	f74785e3          	beq	a5,s4,800023ee <waitx+0x5e>
        release(&np->lock);
    80002488:	8526                	mv	a0,s1
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	80e080e7          	jalr	-2034(ra) # 80000c98 <release>
        havekids = 1;
    80002492:	8756                	mv	a4,s5
    80002494:	bfd9                	j	8000246a <waitx+0xda>
    if (!havekids || p->killed)
    80002496:	c701                	beqz	a4,8000249e <waitx+0x10e>
    80002498:	02892783          	lw	a5,40(s2)
    8000249c:	cb8d                	beqz	a5,800024ce <waitx+0x13e>
      release(&wait_lock);
    8000249e:	0000f517          	auipc	a0,0xf
    800024a2:	e1a50513          	addi	a0,a0,-486 # 800112b8 <wait_lock>
    800024a6:	ffffe097          	auipc	ra,0xffffe
    800024aa:	7f2080e7          	jalr	2034(ra) # 80000c98 <release>
      return -1;
    800024ae:	59fd                	li	s3,-1
}
    800024b0:	854e                	mv	a0,s3
    800024b2:	60e6                	ld	ra,88(sp)
    800024b4:	6446                	ld	s0,80(sp)
    800024b6:	64a6                	ld	s1,72(sp)
    800024b8:	6906                	ld	s2,64(sp)
    800024ba:	79e2                	ld	s3,56(sp)
    800024bc:	7a42                	ld	s4,48(sp)
    800024be:	7aa2                	ld	s5,40(sp)
    800024c0:	7b02                	ld	s6,32(sp)
    800024c2:	6be2                	ld	s7,24(sp)
    800024c4:	6c42                	ld	s8,16(sp)
    800024c6:	6ca2                	ld	s9,8(sp)
    800024c8:	6d02                	ld	s10,0(sp)
    800024ca:	6125                	addi	sp,sp,96
    800024cc:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024ce:	85ea                	mv	a1,s10
    800024d0:	854a                	mv	a0,s2
    800024d2:	00000097          	auipc	ra,0x0
    800024d6:	d32080e7          	jalr	-718(ra) # 80002204 <sleep>
    havekids = 0;
    800024da:	b721                	j	800023e2 <waitx+0x52>

00000000800024dc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800024dc:	7139                	addi	sp,sp,-64
    800024de:	fc06                	sd	ra,56(sp)
    800024e0:	f822                	sd	s0,48(sp)
    800024e2:	f426                	sd	s1,40(sp)
    800024e4:	f04a                	sd	s2,32(sp)
    800024e6:	ec4e                	sd	s3,24(sp)
    800024e8:	e852                	sd	s4,16(sp)
    800024ea:	e456                	sd	s5,8(sp)
    800024ec:	0080                	addi	s0,sp,64
    800024ee:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800024f0:	0000f497          	auipc	s1,0xf
    800024f4:	1e048493          	addi	s1,s1,480 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800024f8:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800024fa:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800024fc:	00015917          	auipc	s2,0x15
    80002500:	7d490913          	addi	s2,s2,2004 # 80017cd0 <tickslock>
    80002504:	a821                	j	8000251c <wakeup+0x40>
        p->state = RUNNABLE;
    80002506:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000250a:	8526                	mv	a0,s1
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	78c080e7          	jalr	1932(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002514:	19848493          	addi	s1,s1,408
    80002518:	03248463          	beq	s1,s2,80002540 <wakeup+0x64>
    if (p != myproc())
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	510080e7          	jalr	1296(ra) # 80001a2c <myproc>
    80002524:	fea488e3          	beq	s1,a0,80002514 <wakeup+0x38>
      acquire(&p->lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	6ba080e7          	jalr	1722(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002532:	4c9c                	lw	a5,24(s1)
    80002534:	fd379be3          	bne	a5,s3,8000250a <wakeup+0x2e>
    80002538:	709c                	ld	a5,32(s1)
    8000253a:	fd4798e3          	bne	a5,s4,8000250a <wakeup+0x2e>
    8000253e:	b7e1                	j	80002506 <wakeup+0x2a>
    }
  }
}
    80002540:	70e2                	ld	ra,56(sp)
    80002542:	7442                	ld	s0,48(sp)
    80002544:	74a2                	ld	s1,40(sp)
    80002546:	7902                	ld	s2,32(sp)
    80002548:	69e2                	ld	s3,24(sp)
    8000254a:	6a42                	ld	s4,16(sp)
    8000254c:	6aa2                	ld	s5,8(sp)
    8000254e:	6121                	addi	sp,sp,64
    80002550:	8082                	ret

0000000080002552 <reparent>:
{
    80002552:	7179                	addi	sp,sp,-48
    80002554:	f406                	sd	ra,40(sp)
    80002556:	f022                	sd	s0,32(sp)
    80002558:	ec26                	sd	s1,24(sp)
    8000255a:	e84a                	sd	s2,16(sp)
    8000255c:	e44e                	sd	s3,8(sp)
    8000255e:	e052                	sd	s4,0(sp)
    80002560:	1800                	addi	s0,sp,48
    80002562:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002564:	0000f497          	auipc	s1,0xf
    80002568:	16c48493          	addi	s1,s1,364 # 800116d0 <proc>
      pp->parent = initproc;
    8000256c:	00007a17          	auipc	s4,0x7
    80002570:	abca0a13          	addi	s4,s4,-1348 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002574:	00015997          	auipc	s3,0x15
    80002578:	75c98993          	addi	s3,s3,1884 # 80017cd0 <tickslock>
    8000257c:	a029                	j	80002586 <reparent+0x34>
    8000257e:	19848493          	addi	s1,s1,408
    80002582:	01348d63          	beq	s1,s3,8000259c <reparent+0x4a>
    if (pp->parent == p)
    80002586:	7c9c                	ld	a5,56(s1)
    80002588:	ff279be3          	bne	a5,s2,8000257e <reparent+0x2c>
      pp->parent = initproc;
    8000258c:	000a3503          	ld	a0,0(s4)
    80002590:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002592:	00000097          	auipc	ra,0x0
    80002596:	f4a080e7          	jalr	-182(ra) # 800024dc <wakeup>
    8000259a:	b7d5                	j	8000257e <reparent+0x2c>
}
    8000259c:	70a2                	ld	ra,40(sp)
    8000259e:	7402                	ld	s0,32(sp)
    800025a0:	64e2                	ld	s1,24(sp)
    800025a2:	6942                	ld	s2,16(sp)
    800025a4:	69a2                	ld	s3,8(sp)
    800025a6:	6a02                	ld	s4,0(sp)
    800025a8:	6145                	addi	sp,sp,48
    800025aa:	8082                	ret

00000000800025ac <exit>:
{
    800025ac:	7179                	addi	sp,sp,-48
    800025ae:	f406                	sd	ra,40(sp)
    800025b0:	f022                	sd	s0,32(sp)
    800025b2:	ec26                	sd	s1,24(sp)
    800025b4:	e84a                	sd	s2,16(sp)
    800025b6:	e44e                	sd	s3,8(sp)
    800025b8:	e052                	sd	s4,0(sp)
    800025ba:	1800                	addi	s0,sp,48
    800025bc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800025be:	fffff097          	auipc	ra,0xfffff
    800025c2:	46e080e7          	jalr	1134(ra) # 80001a2c <myproc>
    800025c6:	89aa                	mv	s3,a0
  if (p == initproc)
    800025c8:	00007797          	auipc	a5,0x7
    800025cc:	a607b783          	ld	a5,-1440(a5) # 80009028 <initproc>
    800025d0:	0d050493          	addi	s1,a0,208
    800025d4:	15050913          	addi	s2,a0,336
    800025d8:	02a79363          	bne	a5,a0,800025fe <exit+0x52>
    panic("init exiting");
    800025dc:	00006517          	auipc	a0,0x6
    800025e0:	c8450513          	addi	a0,a0,-892 # 80008260 <digits+0x220>
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	f5a080e7          	jalr	-166(ra) # 8000053e <panic>
      fileclose(f);
    800025ec:	00002097          	auipc	ra,0x2
    800025f0:	44a080e7          	jalr	1098(ra) # 80004a36 <fileclose>
      p->ofile[fd] = 0;
    800025f4:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800025f8:	04a1                	addi	s1,s1,8
    800025fa:	01248563          	beq	s1,s2,80002604 <exit+0x58>
    if (p->ofile[fd])
    800025fe:	6088                	ld	a0,0(s1)
    80002600:	f575                	bnez	a0,800025ec <exit+0x40>
    80002602:	bfdd                	j	800025f8 <exit+0x4c>
  begin_op();
    80002604:	00002097          	auipc	ra,0x2
    80002608:	f66080e7          	jalr	-154(ra) # 8000456a <begin_op>
  iput(p->cwd);
    8000260c:	1509b503          	ld	a0,336(s3)
    80002610:	00001097          	auipc	ra,0x1
    80002614:	742080e7          	jalr	1858(ra) # 80003d52 <iput>
  end_op();
    80002618:	00002097          	auipc	ra,0x2
    8000261c:	fd2080e7          	jalr	-46(ra) # 800045ea <end_op>
  p->cwd = 0;
    80002620:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002624:	0000f497          	auipc	s1,0xf
    80002628:	c9448493          	addi	s1,s1,-876 # 800112b8 <wait_lock>
    8000262c:	8526                	mv	a0,s1
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	5b6080e7          	jalr	1462(ra) # 80000be4 <acquire>
  reparent(p);
    80002636:	854e                	mv	a0,s3
    80002638:	00000097          	auipc	ra,0x0
    8000263c:	f1a080e7          	jalr	-230(ra) # 80002552 <reparent>
  wakeup(p->parent);
    80002640:	0389b503          	ld	a0,56(s3)
    80002644:	00000097          	auipc	ra,0x0
    80002648:	e98080e7          	jalr	-360(ra) # 800024dc <wakeup>
  acquire(&p->lock);
    8000264c:	854e                	mv	a0,s3
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	596080e7          	jalr	1430(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002656:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000265a:	4795                	li	a5,5
    8000265c:	00f9ac23          	sw	a5,24(s3)
  p->end_time = ticks;
    80002660:	00007797          	auipc	a5,0x7
    80002664:	9d07a783          	lw	a5,-1584(a5) # 80009030 <ticks>
    80002668:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    8000266c:	8526                	mv	a0,s1
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	62a080e7          	jalr	1578(ra) # 80000c98 <release>
  sched();
    80002676:	00000097          	auipc	ra,0x0
    8000267a:	9ea080e7          	jalr	-1558(ra) # 80002060 <sched>
  panic("zombie exit");
    8000267e:	00006517          	auipc	a0,0x6
    80002682:	bf250513          	addi	a0,a0,-1038 # 80008270 <digits+0x230>
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	eb8080e7          	jalr	-328(ra) # 8000053e <panic>

000000008000268e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000268e:	7179                	addi	sp,sp,-48
    80002690:	f406                	sd	ra,40(sp)
    80002692:	f022                	sd	s0,32(sp)
    80002694:	ec26                	sd	s1,24(sp)
    80002696:	e84a                	sd	s2,16(sp)
    80002698:	e44e                	sd	s3,8(sp)
    8000269a:	1800                	addi	s0,sp,48
    8000269c:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000269e:	0000f497          	auipc	s1,0xf
    800026a2:	03248493          	addi	s1,s1,50 # 800116d0 <proc>
    800026a6:	00015997          	auipc	s3,0x15
    800026aa:	62a98993          	addi	s3,s3,1578 # 80017cd0 <tickslock>
  {
    acquire(&p->lock);
    800026ae:	8526                	mv	a0,s1
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	534080e7          	jalr	1332(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    800026b8:	589c                	lw	a5,48(s1)
    800026ba:	01278d63          	beq	a5,s2,800026d4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800026be:	8526                	mv	a0,s1
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	5d8080e7          	jalr	1496(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026c8:	19848493          	addi	s1,s1,408
    800026cc:	ff3491e3          	bne	s1,s3,800026ae <kill+0x20>
  }
  return -1;
    800026d0:	557d                	li	a0,-1
    800026d2:	a829                	j	800026ec <kill+0x5e>
      p->killed = 1;
    800026d4:	4785                	li	a5,1
    800026d6:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800026d8:	4c98                	lw	a4,24(s1)
    800026da:	4789                	li	a5,2
    800026dc:	00f70f63          	beq	a4,a5,800026fa <kill+0x6c>
      release(&p->lock);
    800026e0:	8526                	mv	a0,s1
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	5b6080e7          	jalr	1462(ra) # 80000c98 <release>
      return 0;
    800026ea:	4501                	li	a0,0
}
    800026ec:	70a2                	ld	ra,40(sp)
    800026ee:	7402                	ld	s0,32(sp)
    800026f0:	64e2                	ld	s1,24(sp)
    800026f2:	6942                	ld	s2,16(sp)
    800026f4:	69a2                	ld	s3,8(sp)
    800026f6:	6145                	addi	sp,sp,48
    800026f8:	8082                	ret
        p->state = RUNNABLE;
    800026fa:	478d                	li	a5,3
    800026fc:	cc9c                	sw	a5,24(s1)
    800026fe:	b7cd                	j	800026e0 <kill+0x52>

0000000080002700 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002700:	7179                	addi	sp,sp,-48
    80002702:	f406                	sd	ra,40(sp)
    80002704:	f022                	sd	s0,32(sp)
    80002706:	ec26                	sd	s1,24(sp)
    80002708:	e84a                	sd	s2,16(sp)
    8000270a:	e44e                	sd	s3,8(sp)
    8000270c:	e052                	sd	s4,0(sp)
    8000270e:	1800                	addi	s0,sp,48
    80002710:	84aa                	mv	s1,a0
    80002712:	892e                	mv	s2,a1
    80002714:	89b2                	mv	s3,a2
    80002716:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	314080e7          	jalr	788(ra) # 80001a2c <myproc>
  if (user_dst)
    80002720:	c08d                	beqz	s1,80002742 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002722:	86d2                	mv	a3,s4
    80002724:	864e                	mv	a2,s3
    80002726:	85ca                	mv	a1,s2
    80002728:	6928                	ld	a0,80(a0)
    8000272a:	fffff097          	auipc	ra,0xfffff
    8000272e:	f48080e7          	jalr	-184(ra) # 80001672 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002732:	70a2                	ld	ra,40(sp)
    80002734:	7402                	ld	s0,32(sp)
    80002736:	64e2                	ld	s1,24(sp)
    80002738:	6942                	ld	s2,16(sp)
    8000273a:	69a2                	ld	s3,8(sp)
    8000273c:	6a02                	ld	s4,0(sp)
    8000273e:	6145                	addi	sp,sp,48
    80002740:	8082                	ret
    memmove((char *)dst, src, len);
    80002742:	000a061b          	sext.w	a2,s4
    80002746:	85ce                	mv	a1,s3
    80002748:	854a                	mv	a0,s2
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	5f6080e7          	jalr	1526(ra) # 80000d40 <memmove>
    return 0;
    80002752:	8526                	mv	a0,s1
    80002754:	bff9                	j	80002732 <either_copyout+0x32>

0000000080002756 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002756:	7179                	addi	sp,sp,-48
    80002758:	f406                	sd	ra,40(sp)
    8000275a:	f022                	sd	s0,32(sp)
    8000275c:	ec26                	sd	s1,24(sp)
    8000275e:	e84a                	sd	s2,16(sp)
    80002760:	e44e                	sd	s3,8(sp)
    80002762:	e052                	sd	s4,0(sp)
    80002764:	1800                	addi	s0,sp,48
    80002766:	892a                	mv	s2,a0
    80002768:	84ae                	mv	s1,a1
    8000276a:	89b2                	mv	s3,a2
    8000276c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000276e:	fffff097          	auipc	ra,0xfffff
    80002772:	2be080e7          	jalr	702(ra) # 80001a2c <myproc>
  if (user_src)
    80002776:	c08d                	beqz	s1,80002798 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002778:	86d2                	mv	a3,s4
    8000277a:	864e                	mv	a2,s3
    8000277c:	85ca                	mv	a1,s2
    8000277e:	6928                	ld	a0,80(a0)
    80002780:	fffff097          	auipc	ra,0xfffff
    80002784:	f7e080e7          	jalr	-130(ra) # 800016fe <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002788:	70a2                	ld	ra,40(sp)
    8000278a:	7402                	ld	s0,32(sp)
    8000278c:	64e2                	ld	s1,24(sp)
    8000278e:	6942                	ld	s2,16(sp)
    80002790:	69a2                	ld	s3,8(sp)
    80002792:	6a02                	ld	s4,0(sp)
    80002794:	6145                	addi	sp,sp,48
    80002796:	8082                	ret
    memmove(dst, (char *)src, len);
    80002798:	000a061b          	sext.w	a2,s4
    8000279c:	85ce                	mv	a1,s3
    8000279e:	854a                	mv	a0,s2
    800027a0:	ffffe097          	auipc	ra,0xffffe
    800027a4:	5a0080e7          	jalr	1440(ra) # 80000d40 <memmove>
    return 0;
    800027a8:	8526                	mv	a0,s1
    800027aa:	bff9                	j	80002788 <either_copyin+0x32>

00000000800027ac <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800027ac:	715d                	addi	sp,sp,-80
    800027ae:	e486                	sd	ra,72(sp)
    800027b0:	e0a2                	sd	s0,64(sp)
    800027b2:	fc26                	sd	s1,56(sp)
    800027b4:	f84a                	sd	s2,48(sp)
    800027b6:	f44e                	sd	s3,40(sp)
    800027b8:	f052                	sd	s4,32(sp)
    800027ba:	ec56                	sd	s5,24(sp)
    800027bc:	e85a                	sd	s6,16(sp)
    800027be:	e45e                	sd	s7,8(sp)
    800027c0:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800027c2:	00006517          	auipc	a0,0x6
    800027c6:	d2e50513          	addi	a0,a0,-722 # 800084f0 <states.1773+0x230>
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	dbe080e7          	jalr	-578(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800027d2:	0000f497          	auipc	s1,0xf
    800027d6:	05648493          	addi	s1,s1,86 # 80011828 <proc+0x158>
    800027da:	00015917          	auipc	s2,0x15
    800027de:	64e90913          	addi	s2,s2,1614 # 80017e28 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027e2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800027e4:	00006997          	auipc	s3,0x6
    800027e8:	a9c98993          	addi	s3,s3,-1380 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800027ec:	00006a97          	auipc	s5,0x6
    800027f0:	a9ca8a93          	addi	s5,s5,-1380 # 80008288 <digits+0x248>
    printf("\n");
    800027f4:	00006a17          	auipc	s4,0x6
    800027f8:	cfca0a13          	addi	s4,s4,-772 # 800084f0 <states.1773+0x230>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027fc:	00006b97          	auipc	s7,0x6
    80002800:	ac4b8b93          	addi	s7,s7,-1340 # 800082c0 <states.1773>
    80002804:	a00d                	j	80002826 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002806:	ed86a583          	lw	a1,-296(a3)
    8000280a:	8556                	mv	a0,s5
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	d7c080e7          	jalr	-644(ra) # 80000588 <printf>
    printf("\n");
    80002814:	8552                	mv	a0,s4
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	d72080e7          	jalr	-654(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000281e:	19848493          	addi	s1,s1,408
    80002822:	03248163          	beq	s1,s2,80002844 <procdump+0x98>
    if (p->state == UNUSED)
    80002826:	86a6                	mv	a3,s1
    80002828:	ec04a783          	lw	a5,-320(s1)
    8000282c:	dbed                	beqz	a5,8000281e <procdump+0x72>
      state = "???";
    8000282e:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002830:	fcfb6be3          	bltu	s6,a5,80002806 <procdump+0x5a>
    80002834:	1782                	slli	a5,a5,0x20
    80002836:	9381                	srli	a5,a5,0x20
    80002838:	078e                	slli	a5,a5,0x3
    8000283a:	97de                	add	a5,a5,s7
    8000283c:	6390                	ld	a2,0(a5)
    8000283e:	f661                	bnez	a2,80002806 <procdump+0x5a>
      state = "???";
    80002840:	864e                	mv	a2,s3
    80002842:	b7d1                	j	80002806 <procdump+0x5a>
  }
}
    80002844:	60a6                	ld	ra,72(sp)
    80002846:	6406                	ld	s0,64(sp)
    80002848:	74e2                	ld	s1,56(sp)
    8000284a:	7942                	ld	s2,48(sp)
    8000284c:	79a2                	ld	s3,40(sp)
    8000284e:	7a02                	ld	s4,32(sp)
    80002850:	6ae2                	ld	s5,24(sp)
    80002852:	6b42                	ld	s6,16(sp)
    80002854:	6ba2                	ld	s7,8(sp)
    80002856:	6161                	addi	sp,sp,80
    80002858:	8082                	ret

000000008000285a <swtch>:
    8000285a:	00153023          	sd	ra,0(a0)
    8000285e:	00253423          	sd	sp,8(a0)
    80002862:	e900                	sd	s0,16(a0)
    80002864:	ed04                	sd	s1,24(a0)
    80002866:	03253023          	sd	s2,32(a0)
    8000286a:	03353423          	sd	s3,40(a0)
    8000286e:	03453823          	sd	s4,48(a0)
    80002872:	03553c23          	sd	s5,56(a0)
    80002876:	05653023          	sd	s6,64(a0)
    8000287a:	05753423          	sd	s7,72(a0)
    8000287e:	05853823          	sd	s8,80(a0)
    80002882:	05953c23          	sd	s9,88(a0)
    80002886:	07a53023          	sd	s10,96(a0)
    8000288a:	07b53423          	sd	s11,104(a0)
    8000288e:	0005b083          	ld	ra,0(a1)
    80002892:	0085b103          	ld	sp,8(a1)
    80002896:	6980                	ld	s0,16(a1)
    80002898:	6d84                	ld	s1,24(a1)
    8000289a:	0205b903          	ld	s2,32(a1)
    8000289e:	0285b983          	ld	s3,40(a1)
    800028a2:	0305ba03          	ld	s4,48(a1)
    800028a6:	0385ba83          	ld	s5,56(a1)
    800028aa:	0405bb03          	ld	s6,64(a1)
    800028ae:	0485bb83          	ld	s7,72(a1)
    800028b2:	0505bc03          	ld	s8,80(a1)
    800028b6:	0585bc83          	ld	s9,88(a1)
    800028ba:	0605bd03          	ld	s10,96(a1)
    800028be:	0685bd83          	ld	s11,104(a1)
    800028c2:	8082                	ret

00000000800028c4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028c4:	1141                	addi	sp,sp,-16
    800028c6:	e406                	sd	ra,8(sp)
    800028c8:	e022                	sd	s0,0(sp)
    800028ca:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028cc:	00006597          	auipc	a1,0x6
    800028d0:	a2458593          	addi	a1,a1,-1500 # 800082f0 <states.1773+0x30>
    800028d4:	00015517          	auipc	a0,0x15
    800028d8:	3fc50513          	addi	a0,a0,1020 # 80017cd0 <tickslock>
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	278080e7          	jalr	632(ra) # 80000b54 <initlock>
}
    800028e4:	60a2                	ld	ra,8(sp)
    800028e6:	6402                	ld	s0,0(sp)
    800028e8:	0141                	addi	sp,sp,16
    800028ea:	8082                	ret

00000000800028ec <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028ec:	1141                	addi	sp,sp,-16
    800028ee:	e422                	sd	s0,8(sp)
    800028f0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028f2:	00003797          	auipc	a5,0x3
    800028f6:	75e78793          	addi	a5,a5,1886 # 80006050 <kernelvec>
    800028fa:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028fe:	6422                	ld	s0,8(sp)
    80002900:	0141                	addi	sp,sp,16
    80002902:	8082                	ret

0000000080002904 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002904:	1141                	addi	sp,sp,-16
    80002906:	e406                	sd	ra,8(sp)
    80002908:	e022                	sd	s0,0(sp)
    8000290a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000290c:	fffff097          	auipc	ra,0xfffff
    80002910:	120080e7          	jalr	288(ra) # 80001a2c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002914:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002918:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000291a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000291e:	00004617          	auipc	a2,0x4
    80002922:	6e260613          	addi	a2,a2,1762 # 80007000 <_trampoline>
    80002926:	00004697          	auipc	a3,0x4
    8000292a:	6da68693          	addi	a3,a3,1754 # 80007000 <_trampoline>
    8000292e:	8e91                	sub	a3,a3,a2
    80002930:	040007b7          	lui	a5,0x4000
    80002934:	17fd                	addi	a5,a5,-1
    80002936:	07b2                	slli	a5,a5,0xc
    80002938:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000293a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000293e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002940:	180026f3          	csrr	a3,satp
    80002944:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002946:	6d38                	ld	a4,88(a0)
    80002948:	6134                	ld	a3,64(a0)
    8000294a:	6585                	lui	a1,0x1
    8000294c:	96ae                	add	a3,a3,a1
    8000294e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002950:	6d38                	ld	a4,88(a0)
    80002952:	00000697          	auipc	a3,0x0
    80002956:	14668693          	addi	a3,a3,326 # 80002a98 <usertrap>
    8000295a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000295c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000295e:	8692                	mv	a3,tp
    80002960:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002962:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002966:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000296a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000296e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002972:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002974:	6f18                	ld	a4,24(a4)
    80002976:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000297a:	692c                	ld	a1,80(a0)
    8000297c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000297e:	00004717          	auipc	a4,0x4
    80002982:	71270713          	addi	a4,a4,1810 # 80007090 <userret>
    80002986:	8f11                	sub	a4,a4,a2
    80002988:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000298a:	577d                	li	a4,-1
    8000298c:	177e                	slli	a4,a4,0x3f
    8000298e:	8dd9                	or	a1,a1,a4
    80002990:	02000537          	lui	a0,0x2000
    80002994:	157d                	addi	a0,a0,-1
    80002996:	0536                	slli	a0,a0,0xd
    80002998:	9782                	jalr	a5
}
    8000299a:	60a2                	ld	ra,8(sp)
    8000299c:	6402                	ld	s0,0(sp)
    8000299e:	0141                	addi	sp,sp,16
    800029a0:	8082                	ret

00000000800029a2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029a2:	1101                	addi	sp,sp,-32
    800029a4:	ec06                	sd	ra,24(sp)
    800029a6:	e822                	sd	s0,16(sp)
    800029a8:	e426                	sd	s1,8(sp)
    800029aa:	e04a                	sd	s2,0(sp)
    800029ac:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029ae:	00015917          	auipc	s2,0x15
    800029b2:	32290913          	addi	s2,s2,802 # 80017cd0 <tickslock>
    800029b6:	854a                	mv	a0,s2
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	22c080e7          	jalr	556(ra) # 80000be4 <acquire>
  ticks++;
    800029c0:	00006497          	auipc	s1,0x6
    800029c4:	67048493          	addi	s1,s1,1648 # 80009030 <ticks>
    800029c8:	409c                	lw	a5,0(s1)
    800029ca:	2785                	addiw	a5,a5,1
    800029cc:	c09c                	sw	a5,0(s1)
  inc_runtime();
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	e70080e7          	jalr	-400(ra) # 8000183e <inc_runtime>
  wakeup(&ticks);
    800029d6:	8526                	mv	a0,s1
    800029d8:	00000097          	auipc	ra,0x0
    800029dc:	b04080e7          	jalr	-1276(ra) # 800024dc <wakeup>
  release(&tickslock);
    800029e0:	854a                	mv	a0,s2
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	2b6080e7          	jalr	694(ra) # 80000c98 <release>
}
    800029ea:	60e2                	ld	ra,24(sp)
    800029ec:	6442                	ld	s0,16(sp)
    800029ee:	64a2                	ld	s1,8(sp)
    800029f0:	6902                	ld	s2,0(sp)
    800029f2:	6105                	addi	sp,sp,32
    800029f4:	8082                	ret

00000000800029f6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029f6:	1101                	addi	sp,sp,-32
    800029f8:	ec06                	sd	ra,24(sp)
    800029fa:	e822                	sd	s0,16(sp)
    800029fc:	e426                	sd	s1,8(sp)
    800029fe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a00:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a04:	00074d63          	bltz	a4,80002a1e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a08:	57fd                	li	a5,-1
    80002a0a:	17fe                	slli	a5,a5,0x3f
    80002a0c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a0e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a10:	06f70363          	beq	a4,a5,80002a76 <devintr+0x80>
  }
}
    80002a14:	60e2                	ld	ra,24(sp)
    80002a16:	6442                	ld	s0,16(sp)
    80002a18:	64a2                	ld	s1,8(sp)
    80002a1a:	6105                	addi	sp,sp,32
    80002a1c:	8082                	ret
     (scause & 0xff) == 9){
    80002a1e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a22:	46a5                	li	a3,9
    80002a24:	fed792e3          	bne	a5,a3,80002a08 <devintr+0x12>
    int irq = plic_claim();
    80002a28:	00003097          	auipc	ra,0x3
    80002a2c:	730080e7          	jalr	1840(ra) # 80006158 <plic_claim>
    80002a30:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a32:	47a9                	li	a5,10
    80002a34:	02f50763          	beq	a0,a5,80002a62 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a38:	4785                	li	a5,1
    80002a3a:	02f50963          	beq	a0,a5,80002a6c <devintr+0x76>
    return 1;
    80002a3e:	4505                	li	a0,1
    } else if(irq){
    80002a40:	d8f1                	beqz	s1,80002a14 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a42:	85a6                	mv	a1,s1
    80002a44:	00006517          	auipc	a0,0x6
    80002a48:	8b450513          	addi	a0,a0,-1868 # 800082f8 <states.1773+0x38>
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	b3c080e7          	jalr	-1220(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a54:	8526                	mv	a0,s1
    80002a56:	00003097          	auipc	ra,0x3
    80002a5a:	726080e7          	jalr	1830(ra) # 8000617c <plic_complete>
    return 1;
    80002a5e:	4505                	li	a0,1
    80002a60:	bf55                	j	80002a14 <devintr+0x1e>
      uartintr();
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	f46080e7          	jalr	-186(ra) # 800009a8 <uartintr>
    80002a6a:	b7ed                	j	80002a54 <devintr+0x5e>
      virtio_disk_intr();
    80002a6c:	00004097          	auipc	ra,0x4
    80002a70:	bf0080e7          	jalr	-1040(ra) # 8000665c <virtio_disk_intr>
    80002a74:	b7c5                	j	80002a54 <devintr+0x5e>
    if(cpuid() == 0){
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	f8a080e7          	jalr	-118(ra) # 80001a00 <cpuid>
    80002a7e:	c901                	beqz	a0,80002a8e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a80:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a84:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a86:	14479073          	csrw	sip,a5
    return 2;
    80002a8a:	4509                	li	a0,2
    80002a8c:	b761                	j	80002a14 <devintr+0x1e>
      clockintr();
    80002a8e:	00000097          	auipc	ra,0x0
    80002a92:	f14080e7          	jalr	-236(ra) # 800029a2 <clockintr>
    80002a96:	b7ed                	j	80002a80 <devintr+0x8a>

0000000080002a98 <usertrap>:
{
    80002a98:	1101                	addi	sp,sp,-32
    80002a9a:	ec06                	sd	ra,24(sp)
    80002a9c:	e822                	sd	s0,16(sp)
    80002a9e:	e426                	sd	s1,8(sp)
    80002aa0:	e04a                	sd	s2,0(sp)
    80002aa2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002aa8:	1007f793          	andi	a5,a5,256
    80002aac:	e3ad                	bnez	a5,80002b0e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aae:	00003797          	auipc	a5,0x3
    80002ab2:	5a278793          	addi	a5,a5,1442 # 80006050 <kernelvec>
    80002ab6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	f72080e7          	jalr	-142(ra) # 80001a2c <myproc>
    80002ac2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ac4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ac6:	14102773          	csrr	a4,sepc
    80002aca:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002acc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ad0:	47a1                	li	a5,8
    80002ad2:	04f71c63          	bne	a4,a5,80002b2a <usertrap+0x92>
    if(p->killed)
    80002ad6:	551c                	lw	a5,40(a0)
    80002ad8:	e3b9                	bnez	a5,80002b1e <usertrap+0x86>
    p->trapframe->epc += 4;
    80002ada:	6cb8                	ld	a4,88(s1)
    80002adc:	6f1c                	ld	a5,24(a4)
    80002ade:	0791                	addi	a5,a5,4
    80002ae0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ae6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aea:	10079073          	csrw	sstatus,a5
    syscall();
    80002aee:	00000097          	auipc	ra,0x0
    80002af2:	2e0080e7          	jalr	736(ra) # 80002dce <syscall>
  if(p->killed)
    80002af6:	549c                	lw	a5,40(s1)
    80002af8:	ebc1                	bnez	a5,80002b88 <usertrap+0xf0>
  usertrapret();
    80002afa:	00000097          	auipc	ra,0x0
    80002afe:	e0a080e7          	jalr	-502(ra) # 80002904 <usertrapret>
}
    80002b02:	60e2                	ld	ra,24(sp)
    80002b04:	6442                	ld	s0,16(sp)
    80002b06:	64a2                	ld	s1,8(sp)
    80002b08:	6902                	ld	s2,0(sp)
    80002b0a:	6105                	addi	sp,sp,32
    80002b0c:	8082                	ret
    panic("usertrap: not from user mode");
    80002b0e:	00006517          	auipc	a0,0x6
    80002b12:	80a50513          	addi	a0,a0,-2038 # 80008318 <states.1773+0x58>
    80002b16:	ffffe097          	auipc	ra,0xffffe
    80002b1a:	a28080e7          	jalr	-1496(ra) # 8000053e <panic>
      exit(-1);
    80002b1e:	557d                	li	a0,-1
    80002b20:	00000097          	auipc	ra,0x0
    80002b24:	a8c080e7          	jalr	-1396(ra) # 800025ac <exit>
    80002b28:	bf4d                	j	80002ada <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b2a:	00000097          	auipc	ra,0x0
    80002b2e:	ecc080e7          	jalr	-308(ra) # 800029f6 <devintr>
    80002b32:	892a                	mv	s2,a0
    80002b34:	c501                	beqz	a0,80002b3c <usertrap+0xa4>
  if(p->killed)
    80002b36:	549c                	lw	a5,40(s1)
    80002b38:	c3a1                	beqz	a5,80002b78 <usertrap+0xe0>
    80002b3a:	a815                	j	80002b6e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b3c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b40:	5890                	lw	a2,48(s1)
    80002b42:	00005517          	auipc	a0,0x5
    80002b46:	7f650513          	addi	a0,a0,2038 # 80008338 <states.1773+0x78>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	a3e080e7          	jalr	-1474(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b52:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b56:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b5a:	00006517          	auipc	a0,0x6
    80002b5e:	80e50513          	addi	a0,a0,-2034 # 80008368 <states.1773+0xa8>
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	a26080e7          	jalr	-1498(ra) # 80000588 <printf>
    p->killed = 1;
    80002b6a:	4785                	li	a5,1
    80002b6c:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b6e:	557d                	li	a0,-1
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	a3c080e7          	jalr	-1476(ra) # 800025ac <exit>
    if(which_dev == 2)
    80002b78:	4789                	li	a5,2
    80002b7a:	f8f910e3          	bne	s2,a5,80002afa <usertrap+0x62>
    yield();
    80002b7e:	fffff097          	auipc	ra,0xfffff
    80002b82:	5b8080e7          	jalr	1464(ra) # 80002136 <yield>
    80002b86:	bf95                	j	80002afa <usertrap+0x62>
  int which_dev = 0;
    80002b88:	4901                	li	s2,0
    80002b8a:	b7d5                	j	80002b6e <usertrap+0xd6>

0000000080002b8c <kerneltrap>:
{
    80002b8c:	7179                	addi	sp,sp,-48
    80002b8e:	f406                	sd	ra,40(sp)
    80002b90:	f022                	sd	s0,32(sp)
    80002b92:	ec26                	sd	s1,24(sp)
    80002b94:	e84a                	sd	s2,16(sp)
    80002b96:	e44e                	sd	s3,8(sp)
    80002b98:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b9a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b9e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ba2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ba6:	1004f793          	andi	a5,s1,256
    80002baa:	cb85                	beqz	a5,80002bda <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bb0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bb2:	ef85                	bnez	a5,80002bea <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bb4:	00000097          	auipc	ra,0x0
    80002bb8:	e42080e7          	jalr	-446(ra) # 800029f6 <devintr>
    80002bbc:	cd1d                	beqz	a0,80002bfa <kerneltrap+0x6e>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bbe:	4789                	li	a5,2
    80002bc0:	06f50a63          	beq	a0,a5,80002c34 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bc4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bc8:	10049073          	csrw	sstatus,s1
}
    80002bcc:	70a2                	ld	ra,40(sp)
    80002bce:	7402                	ld	s0,32(sp)
    80002bd0:	64e2                	ld	s1,24(sp)
    80002bd2:	6942                	ld	s2,16(sp)
    80002bd4:	69a2                	ld	s3,8(sp)
    80002bd6:	6145                	addi	sp,sp,48
    80002bd8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bda:	00005517          	auipc	a0,0x5
    80002bde:	7ae50513          	addi	a0,a0,1966 # 80008388 <states.1773+0xc8>
    80002be2:	ffffe097          	auipc	ra,0xffffe
    80002be6:	95c080e7          	jalr	-1700(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002bea:	00005517          	auipc	a0,0x5
    80002bee:	7c650513          	addi	a0,a0,1990 # 800083b0 <states.1773+0xf0>
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	94c080e7          	jalr	-1716(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002bfa:	85ce                	mv	a1,s3
    80002bfc:	00005517          	auipc	a0,0x5
    80002c00:	7d450513          	addi	a0,a0,2004 # 800083d0 <states.1773+0x110>
    80002c04:	ffffe097          	auipc	ra,0xffffe
    80002c08:	984080e7          	jalr	-1660(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c0c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c10:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c14:	00005517          	auipc	a0,0x5
    80002c18:	7cc50513          	addi	a0,a0,1996 # 800083e0 <states.1773+0x120>
    80002c1c:	ffffe097          	auipc	ra,0xffffe
    80002c20:	96c080e7          	jalr	-1684(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c24:	00005517          	auipc	a0,0x5
    80002c28:	7d450513          	addi	a0,a0,2004 # 800083f8 <states.1773+0x138>
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	912080e7          	jalr	-1774(ra) # 8000053e <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	df8080e7          	jalr	-520(ra) # 80001a2c <myproc>
    80002c3c:	d541                	beqz	a0,80002bc4 <kerneltrap+0x38>
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	dee080e7          	jalr	-530(ra) # 80001a2c <myproc>
    80002c46:	4d18                	lw	a4,24(a0)
    80002c48:	4791                	li	a5,4
    80002c4a:	f6f71de3          	bne	a4,a5,80002bc4 <kerneltrap+0x38>
    yield();
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	4e8080e7          	jalr	1256(ra) # 80002136 <yield>
    80002c56:	b7bd                	j	80002bc4 <kerneltrap+0x38>

0000000080002c58 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c58:	1101                	addi	sp,sp,-32
    80002c5a:	ec06                	sd	ra,24(sp)
    80002c5c:	e822                	sd	s0,16(sp)
    80002c5e:	e426                	sd	s1,8(sp)
    80002c60:	1000                	addi	s0,sp,32
    80002c62:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	dc8080e7          	jalr	-568(ra) # 80001a2c <myproc>
  switch (n) {
    80002c6c:	4795                	li	a5,5
    80002c6e:	0497e163          	bltu	a5,s1,80002cb0 <argraw+0x58>
    80002c72:	048a                	slli	s1,s1,0x2
    80002c74:	00006717          	auipc	a4,0x6
    80002c78:	96470713          	addi	a4,a4,-1692 # 800085d8 <states.1773+0x318>
    80002c7c:	94ba                	add	s1,s1,a4
    80002c7e:	409c                	lw	a5,0(s1)
    80002c80:	97ba                	add	a5,a5,a4
    80002c82:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c84:	6d3c                	ld	a5,88(a0)
    80002c86:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c88:	60e2                	ld	ra,24(sp)
    80002c8a:	6442                	ld	s0,16(sp)
    80002c8c:	64a2                	ld	s1,8(sp)
    80002c8e:	6105                	addi	sp,sp,32
    80002c90:	8082                	ret
    return p->trapframe->a1;
    80002c92:	6d3c                	ld	a5,88(a0)
    80002c94:	7fa8                	ld	a0,120(a5)
    80002c96:	bfcd                	j	80002c88 <argraw+0x30>
    return p->trapframe->a2;
    80002c98:	6d3c                	ld	a5,88(a0)
    80002c9a:	63c8                	ld	a0,128(a5)
    80002c9c:	b7f5                	j	80002c88 <argraw+0x30>
    return p->trapframe->a3;
    80002c9e:	6d3c                	ld	a5,88(a0)
    80002ca0:	67c8                	ld	a0,136(a5)
    80002ca2:	b7dd                	j	80002c88 <argraw+0x30>
    return p->trapframe->a4;
    80002ca4:	6d3c                	ld	a5,88(a0)
    80002ca6:	6bc8                	ld	a0,144(a5)
    80002ca8:	b7c5                	j	80002c88 <argraw+0x30>
    return p->trapframe->a5;
    80002caa:	6d3c                	ld	a5,88(a0)
    80002cac:	6fc8                	ld	a0,152(a5)
    80002cae:	bfe9                	j	80002c88 <argraw+0x30>
  panic("argraw");
    80002cb0:	00005517          	auipc	a0,0x5
    80002cb4:	75850513          	addi	a0,a0,1880 # 80008408 <states.1773+0x148>
    80002cb8:	ffffe097          	auipc	ra,0xffffe
    80002cbc:	886080e7          	jalr	-1914(ra) # 8000053e <panic>

0000000080002cc0 <fetchaddr>:
{
    80002cc0:	1101                	addi	sp,sp,-32
    80002cc2:	ec06                	sd	ra,24(sp)
    80002cc4:	e822                	sd	s0,16(sp)
    80002cc6:	e426                	sd	s1,8(sp)
    80002cc8:	e04a                	sd	s2,0(sp)
    80002cca:	1000                	addi	s0,sp,32
    80002ccc:	84aa                	mv	s1,a0
    80002cce:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	d5c080e7          	jalr	-676(ra) # 80001a2c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002cd8:	653c                	ld	a5,72(a0)
    80002cda:	02f4f863          	bgeu	s1,a5,80002d0a <fetchaddr+0x4a>
    80002cde:	00848713          	addi	a4,s1,8
    80002ce2:	02e7e663          	bltu	a5,a4,80002d0e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ce6:	46a1                	li	a3,8
    80002ce8:	8626                	mv	a2,s1
    80002cea:	85ca                	mv	a1,s2
    80002cec:	6928                	ld	a0,80(a0)
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	a10080e7          	jalr	-1520(ra) # 800016fe <copyin>
    80002cf6:	00a03533          	snez	a0,a0
    80002cfa:	40a00533          	neg	a0,a0
}
    80002cfe:	60e2                	ld	ra,24(sp)
    80002d00:	6442                	ld	s0,16(sp)
    80002d02:	64a2                	ld	s1,8(sp)
    80002d04:	6902                	ld	s2,0(sp)
    80002d06:	6105                	addi	sp,sp,32
    80002d08:	8082                	ret
    return -1;
    80002d0a:	557d                	li	a0,-1
    80002d0c:	bfcd                	j	80002cfe <fetchaddr+0x3e>
    80002d0e:	557d                	li	a0,-1
    80002d10:	b7fd                	j	80002cfe <fetchaddr+0x3e>

0000000080002d12 <fetchstr>:
{
    80002d12:	7179                	addi	sp,sp,-48
    80002d14:	f406                	sd	ra,40(sp)
    80002d16:	f022                	sd	s0,32(sp)
    80002d18:	ec26                	sd	s1,24(sp)
    80002d1a:	e84a                	sd	s2,16(sp)
    80002d1c:	e44e                	sd	s3,8(sp)
    80002d1e:	1800                	addi	s0,sp,48
    80002d20:	892a                	mv	s2,a0
    80002d22:	84ae                	mv	s1,a1
    80002d24:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d26:	fffff097          	auipc	ra,0xfffff
    80002d2a:	d06080e7          	jalr	-762(ra) # 80001a2c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d2e:	86ce                	mv	a3,s3
    80002d30:	864a                	mv	a2,s2
    80002d32:	85a6                	mv	a1,s1
    80002d34:	6928                	ld	a0,80(a0)
    80002d36:	fffff097          	auipc	ra,0xfffff
    80002d3a:	a54080e7          	jalr	-1452(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002d3e:	00054763          	bltz	a0,80002d4c <fetchstr+0x3a>
  return strlen(buf);
    80002d42:	8526                	mv	a0,s1
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	120080e7          	jalr	288(ra) # 80000e64 <strlen>
}
    80002d4c:	70a2                	ld	ra,40(sp)
    80002d4e:	7402                	ld	s0,32(sp)
    80002d50:	64e2                	ld	s1,24(sp)
    80002d52:	6942                	ld	s2,16(sp)
    80002d54:	69a2                	ld	s3,8(sp)
    80002d56:	6145                	addi	sp,sp,48
    80002d58:	8082                	ret

0000000080002d5a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d5a:	1101                	addi	sp,sp,-32
    80002d5c:	ec06                	sd	ra,24(sp)
    80002d5e:	e822                	sd	s0,16(sp)
    80002d60:	e426                	sd	s1,8(sp)
    80002d62:	1000                	addi	s0,sp,32
    80002d64:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d66:	00000097          	auipc	ra,0x0
    80002d6a:	ef2080e7          	jalr	-270(ra) # 80002c58 <argraw>
    80002d6e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d70:	4501                	li	a0,0
    80002d72:	60e2                	ld	ra,24(sp)
    80002d74:	6442                	ld	s0,16(sp)
    80002d76:	64a2                	ld	s1,8(sp)
    80002d78:	6105                	addi	sp,sp,32
    80002d7a:	8082                	ret

0000000080002d7c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d7c:	1101                	addi	sp,sp,-32
    80002d7e:	ec06                	sd	ra,24(sp)
    80002d80:	e822                	sd	s0,16(sp)
    80002d82:	e426                	sd	s1,8(sp)
    80002d84:	1000                	addi	s0,sp,32
    80002d86:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d88:	00000097          	auipc	ra,0x0
    80002d8c:	ed0080e7          	jalr	-304(ra) # 80002c58 <argraw>
    80002d90:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d92:	4501                	li	a0,0
    80002d94:	60e2                	ld	ra,24(sp)
    80002d96:	6442                	ld	s0,16(sp)
    80002d98:	64a2                	ld	s1,8(sp)
    80002d9a:	6105                	addi	sp,sp,32
    80002d9c:	8082                	ret

0000000080002d9e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d9e:	1101                	addi	sp,sp,-32
    80002da0:	ec06                	sd	ra,24(sp)
    80002da2:	e822                	sd	s0,16(sp)
    80002da4:	e426                	sd	s1,8(sp)
    80002da6:	e04a                	sd	s2,0(sp)
    80002da8:	1000                	addi	s0,sp,32
    80002daa:	84ae                	mv	s1,a1
    80002dac:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	eaa080e7          	jalr	-342(ra) # 80002c58 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002db6:	864a                	mv	a2,s2
    80002db8:	85a6                	mv	a1,s1
    80002dba:	00000097          	auipc	ra,0x0
    80002dbe:	f58080e7          	jalr	-168(ra) # 80002d12 <fetchstr>
}
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	64a2                	ld	s1,8(sp)
    80002dc8:	6902                	ld	s2,0(sp)
    80002dca:	6105                	addi	sp,sp,32
    80002dcc:	8082                	ret

0000000080002dce <syscall>:
[SYS_setpriority]   1,
};

void
syscall(void)
{
    80002dce:	7139                	addi	sp,sp,-64
    80002dd0:	fc06                	sd	ra,56(sp)
    80002dd2:	f822                	sd	s0,48(sp)
    80002dd4:	f426                	sd	s1,40(sp)
    80002dd6:	f04a                	sd	s2,32(sp)
    80002dd8:	ec4e                	sd	s3,24(sp)
    80002dda:	e852                	sd	s4,16(sp)
    80002ddc:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	c4e080e7          	jalr	-946(ra) # 80001a2c <myproc>
    80002de6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002de8:	05853903          	ld	s2,88(a0)
    80002dec:	0a893783          	ld	a5,168(s2)
    80002df0:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002df4:	37fd                	addiw	a5,a5,-1
    80002df6:	475d                	li	a4,23
    80002df8:	1af76763          	bltu	a4,a5,80002fa6 <syscall+0x1d8>
    80002dfc:	00399713          	slli	a4,s3,0x3
    80002e00:	00005797          	auipc	a5,0x5
    80002e04:	7f078793          	addi	a5,a5,2032 # 800085f0 <syscalls>
    80002e08:	97ba                	add	a5,a5,a4
    80002e0a:	639c                	ld	a5,0(a5)
    80002e0c:	18078d63          	beqz	a5,80002fa6 <syscall+0x1d8>
    int x = p->trapframe->a0;
    80002e10:	07093a03          	ld	s4,112(s2)
    p->trapframe->a0 = syscalls[num]();
    80002e14:	9782                	jalr	a5
    80002e16:	06a93823          	sd	a0,112(s2)
    if (((1<<num) & p->tracy)!=0)
    80002e1a:	1684a783          	lw	a5,360(s1)
    80002e1e:	4137d7bb          	sraw	a5,a5,s3
    80002e22:	8b85                	andi	a5,a5,1
    80002e24:	1a078063          	beqz	a5,80002fc4 <syscall+0x1f6>
    int x = p->trapframe->a0;
    80002e28:	000a069b          	sext.w	a3,s4
    {
      if (nargs[num]==0)
    80002e2c:	00299713          	slli	a4,s3,0x2
    80002e30:	00006797          	auipc	a5,0x6
    80002e34:	be878793          	addi	a5,a5,-1048 # 80008a18 <nargs>
    80002e38:	97ba                	add	a5,a5,a4
    80002e3a:	439c                	lw	a5,0(a5)
    80002e3c:	cfa9                	beqz	a5,80002e96 <syscall+0xc8>
      {
        printf("%d: syscall %s (%d) -> %d\n",p->pid,names[num],x,p->trapframe->a0);
      }
      else if (nargs[num]==1)
    80002e3e:	4705                	li	a4,1
    80002e40:	06e78f63          	beq	a5,a4,80002ebe <syscall+0xf0>
      {
        printf("%d: syscall %s (%d) -> %d\n",p->pid,names[num],x,p->trapframe->a0);
      }
      else if (nargs[num]==2)
    80002e44:	4709                	li	a4,2
    80002e46:	0ae78063          	beq	a5,a4,80002ee6 <syscall+0x118>
      {
        printf("%d: syscall %s (%d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a0);
      }
      else if (nargs[num]==3)
    80002e4a:	470d                	li	a4,3
    80002e4c:	0ce78263          	beq	a5,a4,80002f10 <syscall+0x142>
      {
        printf("%d: syscall %s (%d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a0);
      }
      else if (nargs[num]==4)
    80002e50:	4711                	li	a4,4
    80002e52:	0ee78663          	beq	a5,a4,80002f3e <syscall+0x170>
      {
              printf("%d: syscall %s (%d %d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a3,p->trapframe->a0);
      }
      else if (nargs[num]==5)
    80002e56:	4715                	li	a4,5
    80002e58:	10e78c63          	beq	a5,a4,80002f70 <syscall+0x1a2>
      {
              printf("%d: syscall %s (%d %d %d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a3,p->trapframe->a4,p->trapframe->a0);
      }
      else
      {
              printf("%d: syscall %s (%d %d %d %d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a3,p->trapframe->a4,p->trapframe->a5,p->trapframe->a0);
    80002e5c:	6cb0                	ld	a2,88(s1)
    80002e5e:	09063883          	ld	a7,144(a2)
    80002e62:	08863803          	ld	a6,136(a2)
    80002e66:	625c                	ld	a5,128(a2)
    80002e68:	7e38                	ld	a4,120(a2)
    80002e6a:	098e                	slli	s3,s3,0x3
    80002e6c:	00006597          	auipc	a1,0x6
    80002e70:	bac58593          	addi	a1,a1,-1108 # 80008a18 <nargs>
    80002e74:	99ae                	add	s3,s3,a1
    80002e76:	588c                	lw	a1,48(s1)
    80002e78:	7a28                	ld	a0,112(a2)
    80002e7a:	e42a                	sd	a0,8(sp)
    80002e7c:	6e50                	ld	a2,152(a2)
    80002e7e:	e032                	sd	a2,0(sp)
    80002e80:	0689b603          	ld	a2,104(s3)
    80002e84:	00005517          	auipc	a0,0x5
    80002e88:	64450513          	addi	a0,a0,1604 # 800084c8 <states.1773+0x208>
    80002e8c:	ffffd097          	auipc	ra,0xffffd
    80002e90:	6fc080e7          	jalr	1788(ra) # 80000588 <printf>
    80002e94:	aa05                	j	80002fc4 <syscall+0x1f6>
        printf("%d: syscall %s (%d) -> %d\n",p->pid,names[num],x,p->trapframe->a0);
    80002e96:	6cb8                	ld	a4,88(s1)
    80002e98:	098e                	slli	s3,s3,0x3
    80002e9a:	00006797          	auipc	a5,0x6
    80002e9e:	b7e78793          	addi	a5,a5,-1154 # 80008a18 <nargs>
    80002ea2:	99be                	add	s3,s3,a5
    80002ea4:	7b38                	ld	a4,112(a4)
    80002ea6:	0689b603          	ld	a2,104(s3)
    80002eaa:	588c                	lw	a1,48(s1)
    80002eac:	00005517          	auipc	a0,0x5
    80002eb0:	56450513          	addi	a0,a0,1380 # 80008410 <states.1773+0x150>
    80002eb4:	ffffd097          	auipc	ra,0xffffd
    80002eb8:	6d4080e7          	jalr	1748(ra) # 80000588 <printf>
    80002ebc:	a221                	j	80002fc4 <syscall+0x1f6>
        printf("%d: syscall %s (%d) -> %d\n",p->pid,names[num],x,p->trapframe->a0);
    80002ebe:	6cb8                	ld	a4,88(s1)
    80002ec0:	098e                	slli	s3,s3,0x3
    80002ec2:	00006797          	auipc	a5,0x6
    80002ec6:	b5678793          	addi	a5,a5,-1194 # 80008a18 <nargs>
    80002eca:	99be                	add	s3,s3,a5
    80002ecc:	7b38                	ld	a4,112(a4)
    80002ece:	0689b603          	ld	a2,104(s3)
    80002ed2:	588c                	lw	a1,48(s1)
    80002ed4:	00005517          	auipc	a0,0x5
    80002ed8:	53c50513          	addi	a0,a0,1340 # 80008410 <states.1773+0x150>
    80002edc:	ffffd097          	auipc	ra,0xffffd
    80002ee0:	6ac080e7          	jalr	1708(ra) # 80000588 <printf>
    80002ee4:	a0c5                	j	80002fc4 <syscall+0x1f6>
        printf("%d: syscall %s (%d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a0);
    80002ee6:	6cb8                	ld	a4,88(s1)
    80002ee8:	098e                	slli	s3,s3,0x3
    80002eea:	00006797          	auipc	a5,0x6
    80002eee:	b2e78793          	addi	a5,a5,-1234 # 80008a18 <nargs>
    80002ef2:	99be                	add	s3,s3,a5
    80002ef4:	7b3c                	ld	a5,112(a4)
    80002ef6:	7f38                	ld	a4,120(a4)
    80002ef8:	0689b603          	ld	a2,104(s3)
    80002efc:	588c                	lw	a1,48(s1)
    80002efe:	00005517          	auipc	a0,0x5
    80002f02:	53250513          	addi	a0,a0,1330 # 80008430 <states.1773+0x170>
    80002f06:	ffffd097          	auipc	ra,0xffffd
    80002f0a:	682080e7          	jalr	1666(ra) # 80000588 <printf>
    80002f0e:	a85d                	j	80002fc4 <syscall+0x1f6>
        printf("%d: syscall %s (%d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a0);
    80002f10:	6cb8                	ld	a4,88(s1)
    80002f12:	098e                	slli	s3,s3,0x3
    80002f14:	00006797          	auipc	a5,0x6
    80002f18:	b0478793          	addi	a5,a5,-1276 # 80008a18 <nargs>
    80002f1c:	99be                	add	s3,s3,a5
    80002f1e:	07073803          	ld	a6,112(a4)
    80002f22:	635c                	ld	a5,128(a4)
    80002f24:	7f38                	ld	a4,120(a4)
    80002f26:	0689b603          	ld	a2,104(s3)
    80002f2a:	588c                	lw	a1,48(s1)
    80002f2c:	00005517          	auipc	a0,0x5
    80002f30:	52450513          	addi	a0,a0,1316 # 80008450 <states.1773+0x190>
    80002f34:	ffffd097          	auipc	ra,0xffffd
    80002f38:	654080e7          	jalr	1620(ra) # 80000588 <printf>
    80002f3c:	a061                	j	80002fc4 <syscall+0x1f6>
              printf("%d: syscall %s (%d %d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a3,p->trapframe->a0);
    80002f3e:	6cb8                	ld	a4,88(s1)
    80002f40:	098e                	slli	s3,s3,0x3
    80002f42:	00006797          	auipc	a5,0x6
    80002f46:	ad678793          	addi	a5,a5,-1322 # 80008a18 <nargs>
    80002f4a:	99be                	add	s3,s3,a5
    80002f4c:	07073883          	ld	a7,112(a4)
    80002f50:	08873803          	ld	a6,136(a4)
    80002f54:	635c                	ld	a5,128(a4)
    80002f56:	7f38                	ld	a4,120(a4)
    80002f58:	0689b603          	ld	a2,104(s3)
    80002f5c:	588c                	lw	a1,48(s1)
    80002f5e:	00005517          	auipc	a0,0x5
    80002f62:	51a50513          	addi	a0,a0,1306 # 80008478 <states.1773+0x1b8>
    80002f66:	ffffd097          	auipc	ra,0xffffd
    80002f6a:	622080e7          	jalr	1570(ra) # 80000588 <printf>
    80002f6e:	a899                	j	80002fc4 <syscall+0x1f6>
              printf("%d: syscall %s (%d %d %d %d %d) -> %d\n",p->pid,names[num],x,p->trapframe->a1,p->trapframe->a2,p->trapframe->a3,p->trapframe->a4,p->trapframe->a0);
    80002f70:	6cb0                	ld	a2,88(s1)
    80002f72:	09063883          	ld	a7,144(a2)
    80002f76:	08863803          	ld	a6,136(a2)
    80002f7a:	625c                	ld	a5,128(a2)
    80002f7c:	7e38                	ld	a4,120(a2)
    80002f7e:	098e                	slli	s3,s3,0x3
    80002f80:	00006597          	auipc	a1,0x6
    80002f84:	a9858593          	addi	a1,a1,-1384 # 80008a18 <nargs>
    80002f88:	99ae                	add	s3,s3,a1
    80002f8a:	588c                	lw	a1,48(s1)
    80002f8c:	7a30                	ld	a2,112(a2)
    80002f8e:	e032                	sd	a2,0(sp)
    80002f90:	0689b603          	ld	a2,104(s3)
    80002f94:	00005517          	auipc	a0,0x5
    80002f98:	50c50513          	addi	a0,a0,1292 # 800084a0 <states.1773+0x1e0>
    80002f9c:	ffffd097          	auipc	ra,0xffffd
    80002fa0:	5ec080e7          	jalr	1516(ra) # 80000588 <printf>
    80002fa4:	a005                	j	80002fc4 <syscall+0x1f6>
      }
    }
    
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002fa6:	86ce                	mv	a3,s3
    80002fa8:	15848613          	addi	a2,s1,344
    80002fac:	588c                	lw	a1,48(s1)
    80002fae:	00005517          	auipc	a0,0x5
    80002fb2:	54a50513          	addi	a0,a0,1354 # 800084f8 <states.1773+0x238>
    80002fb6:	ffffd097          	auipc	ra,0xffffd
    80002fba:	5d2080e7          	jalr	1490(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fbe:	6cbc                	ld	a5,88(s1)
    80002fc0:	577d                	li	a4,-1
    80002fc2:	fbb8                	sd	a4,112(a5)
  }
}
    80002fc4:	70e2                	ld	ra,56(sp)
    80002fc6:	7442                	ld	s0,48(sp)
    80002fc8:	74a2                	ld	s1,40(sp)
    80002fca:	7902                	ld	s2,32(sp)
    80002fcc:	69e2                	ld	s3,24(sp)
    80002fce:	6a42                	ld	s4,16(sp)
    80002fd0:	6121                	addi	sp,sp,64
    80002fd2:	8082                	ret

0000000080002fd4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002fd4:	1101                	addi	sp,sp,-32
    80002fd6:	ec06                	sd	ra,24(sp)
    80002fd8:	e822                	sd	s0,16(sp)
    80002fda:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002fdc:	fec40593          	addi	a1,s0,-20
    80002fe0:	4501                	li	a0,0
    80002fe2:	00000097          	auipc	ra,0x0
    80002fe6:	d78080e7          	jalr	-648(ra) # 80002d5a <argint>
    return -1;
    80002fea:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fec:	00054963          	bltz	a0,80002ffe <sys_exit+0x2a>
  exit(n);
    80002ff0:	fec42503          	lw	a0,-20(s0)
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	5b8080e7          	jalr	1464(ra) # 800025ac <exit>
  return 0;  // not reached
    80002ffc:	4781                	li	a5,0
}
    80002ffe:	853e                	mv	a0,a5
    80003000:	60e2                	ld	ra,24(sp)
    80003002:	6442                	ld	s0,16(sp)
    80003004:	6105                	addi	sp,sp,32
    80003006:	8082                	ret

0000000080003008 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003008:	1141                	addi	sp,sp,-16
    8000300a:	e406                	sd	ra,8(sp)
    8000300c:	e022                	sd	s0,0(sp)
    8000300e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003010:	fffff097          	auipc	ra,0xfffff
    80003014:	a1c080e7          	jalr	-1508(ra) # 80001a2c <myproc>
}
    80003018:	5908                	lw	a0,48(a0)
    8000301a:	60a2                	ld	ra,8(sp)
    8000301c:	6402                	ld	s0,0(sp)
    8000301e:	0141                	addi	sp,sp,16
    80003020:	8082                	ret

0000000080003022 <sys_fork>:

uint64
sys_fork(void)
{
    80003022:	1141                	addi	sp,sp,-16
    80003024:	e406                	sd	ra,8(sp)
    80003026:	e022                	sd	s0,0(sp)
    80003028:	0800                	addi	s0,sp,16
  return fork();
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	df4080e7          	jalr	-524(ra) # 80001e1e <fork>
}
    80003032:	60a2                	ld	ra,8(sp)
    80003034:	6402                	ld	s0,0(sp)
    80003036:	0141                	addi	sp,sp,16
    80003038:	8082                	ret

000000008000303a <sys_wait>:

uint64
sys_wait(void)
{
    8000303a:	1101                	addi	sp,sp,-32
    8000303c:	ec06                	sd	ra,24(sp)
    8000303e:	e822                	sd	s0,16(sp)
    80003040:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003042:	fe840593          	addi	a1,s0,-24
    80003046:	4501                	li	a0,0
    80003048:	00000097          	auipc	ra,0x0
    8000304c:	d34080e7          	jalr	-716(ra) # 80002d7c <argaddr>
    80003050:	87aa                	mv	a5,a0
    return -1;
    80003052:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003054:	0007c863          	bltz	a5,80003064 <sys_wait+0x2a>
  return wait(p);
    80003058:	fe843503          	ld	a0,-24(s0)
    8000305c:	fffff097          	auipc	ra,0xfffff
    80003060:	20c080e7          	jalr	524(ra) # 80002268 <wait>
}
    80003064:	60e2                	ld	ra,24(sp)
    80003066:	6442                	ld	s0,16(sp)
    80003068:	6105                	addi	sp,sp,32
    8000306a:	8082                	ret

000000008000306c <sys_waitx>:

uint64
sys_waitx(void)
{
    8000306c:	7139                	addi	sp,sp,-64
    8000306e:	fc06                	sd	ra,56(sp)
    80003070:	f822                	sd	s0,48(sp)
    80003072:	f426                	sd	s1,40(sp)
    80003074:	f04a                	sd	s2,32(sp)
    80003076:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    80003078:	fd840593          	addi	a1,s0,-40
    8000307c:	4501                	li	a0,0
    8000307e:	00000097          	auipc	ra,0x0
    80003082:	cfe080e7          	jalr	-770(ra) # 80002d7c <argaddr>
    return -1;
    80003086:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    80003088:	08054063          	bltz	a0,80003108 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    8000308c:	fd040593          	addi	a1,s0,-48
    80003090:	4505                	li	a0,1
    80003092:	00000097          	auipc	ra,0x0
    80003096:	cea080e7          	jalr	-790(ra) # 80002d7c <argaddr>
    return -1;
    8000309a:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    8000309c:	06054663          	bltz	a0,80003108 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    800030a0:	fc840593          	addi	a1,s0,-56
    800030a4:	4509                	li	a0,2
    800030a6:	00000097          	auipc	ra,0x0
    800030aa:	cd6080e7          	jalr	-810(ra) # 80002d7c <argaddr>
    return -1;
    800030ae:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    800030b0:	04054c63          	bltz	a0,80003108 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    800030b4:	fc040613          	addi	a2,s0,-64
    800030b8:	fc440593          	addi	a1,s0,-60
    800030bc:	fd843503          	ld	a0,-40(s0)
    800030c0:	fffff097          	auipc	ra,0xfffff
    800030c4:	2d0080e7          	jalr	720(ra) # 80002390 <waitx>
    800030c8:	892a                	mv	s2,a0
  struct proc* p = myproc();
    800030ca:	fffff097          	auipc	ra,0xfffff
    800030ce:	962080e7          	jalr	-1694(ra) # 80001a2c <myproc>
    800030d2:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800030d4:	4691                	li	a3,4
    800030d6:	fc440613          	addi	a2,s0,-60
    800030da:	fd043583          	ld	a1,-48(s0)
    800030de:	6928                	ld	a0,80(a0)
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	592080e7          	jalr	1426(ra) # 80001672 <copyout>
    return -1;
    800030e8:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800030ea:	00054f63          	bltz	a0,80003108 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    800030ee:	4691                	li	a3,4
    800030f0:	fc040613          	addi	a2,s0,-64
    800030f4:	fc843583          	ld	a1,-56(s0)
    800030f8:	68a8                	ld	a0,80(s1)
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	578080e7          	jalr	1400(ra) # 80001672 <copyout>
    80003102:	00054a63          	bltz	a0,80003116 <sys_waitx+0xaa>
    return -1;
  return ret;
    80003106:	87ca                	mv	a5,s2
}
    80003108:	853e                	mv	a0,a5
    8000310a:	70e2                	ld	ra,56(sp)
    8000310c:	7442                	ld	s0,48(sp)
    8000310e:	74a2                	ld	s1,40(sp)
    80003110:	7902                	ld	s2,32(sp)
    80003112:	6121                	addi	sp,sp,64
    80003114:	8082                	ret
    return -1;
    80003116:	57fd                	li	a5,-1
    80003118:	bfc5                	j	80003108 <sys_waitx+0x9c>

000000008000311a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000311a:	7179                	addi	sp,sp,-48
    8000311c:	f406                	sd	ra,40(sp)
    8000311e:	f022                	sd	s0,32(sp)
    80003120:	ec26                	sd	s1,24(sp)
    80003122:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003124:	fdc40593          	addi	a1,s0,-36
    80003128:	4501                	li	a0,0
    8000312a:	00000097          	auipc	ra,0x0
    8000312e:	c30080e7          	jalr	-976(ra) # 80002d5a <argint>
    80003132:	87aa                	mv	a5,a0
    return -1;
    80003134:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003136:	0207c063          	bltz	a5,80003156 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000313a:	fffff097          	auipc	ra,0xfffff
    8000313e:	8f2080e7          	jalr	-1806(ra) # 80001a2c <myproc>
    80003142:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003144:	fdc42503          	lw	a0,-36(s0)
    80003148:	fffff097          	auipc	ra,0xfffff
    8000314c:	c62080e7          	jalr	-926(ra) # 80001daa <growproc>
    80003150:	00054863          	bltz	a0,80003160 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003154:	8526                	mv	a0,s1
}
    80003156:	70a2                	ld	ra,40(sp)
    80003158:	7402                	ld	s0,32(sp)
    8000315a:	64e2                	ld	s1,24(sp)
    8000315c:	6145                	addi	sp,sp,48
    8000315e:	8082                	ret
    return -1;
    80003160:	557d                	li	a0,-1
    80003162:	bfd5                	j	80003156 <sys_sbrk+0x3c>

0000000080003164 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003164:	7139                	addi	sp,sp,-64
    80003166:	fc06                	sd	ra,56(sp)
    80003168:	f822                	sd	s0,48(sp)
    8000316a:	f426                	sd	s1,40(sp)
    8000316c:	f04a                	sd	s2,32(sp)
    8000316e:	ec4e                	sd	s3,24(sp)
    80003170:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003172:	fcc40593          	addi	a1,s0,-52
    80003176:	4501                	li	a0,0
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	be2080e7          	jalr	-1054(ra) # 80002d5a <argint>
    return -1;
    80003180:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003182:	06054563          	bltz	a0,800031ec <sys_sleep+0x88>
  acquire(&tickslock);
    80003186:	00015517          	auipc	a0,0x15
    8000318a:	b4a50513          	addi	a0,a0,-1206 # 80017cd0 <tickslock>
    8000318e:	ffffe097          	auipc	ra,0xffffe
    80003192:	a56080e7          	jalr	-1450(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003196:	00006917          	auipc	s2,0x6
    8000319a:	e9a92903          	lw	s2,-358(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000319e:	fcc42783          	lw	a5,-52(s0)
    800031a2:	cf85                	beqz	a5,800031da <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800031a4:	00015997          	auipc	s3,0x15
    800031a8:	b2c98993          	addi	s3,s3,-1236 # 80017cd0 <tickslock>
    800031ac:	00006497          	auipc	s1,0x6
    800031b0:	e8448493          	addi	s1,s1,-380 # 80009030 <ticks>
    if(myproc()->killed){
    800031b4:	fffff097          	auipc	ra,0xfffff
    800031b8:	878080e7          	jalr	-1928(ra) # 80001a2c <myproc>
    800031bc:	551c                	lw	a5,40(a0)
    800031be:	ef9d                	bnez	a5,800031fc <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800031c0:	85ce                	mv	a1,s3
    800031c2:	8526                	mv	a0,s1
    800031c4:	fffff097          	auipc	ra,0xfffff
    800031c8:	040080e7          	jalr	64(ra) # 80002204 <sleep>
  while(ticks - ticks0 < n){
    800031cc:	409c                	lw	a5,0(s1)
    800031ce:	412787bb          	subw	a5,a5,s2
    800031d2:	fcc42703          	lw	a4,-52(s0)
    800031d6:	fce7efe3          	bltu	a5,a4,800031b4 <sys_sleep+0x50>
  }
  release(&tickslock);
    800031da:	00015517          	auipc	a0,0x15
    800031de:	af650513          	addi	a0,a0,-1290 # 80017cd0 <tickslock>
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	ab6080e7          	jalr	-1354(ra) # 80000c98 <release>
  return 0;
    800031ea:	4781                	li	a5,0
}
    800031ec:	853e                	mv	a0,a5
    800031ee:	70e2                	ld	ra,56(sp)
    800031f0:	7442                	ld	s0,48(sp)
    800031f2:	74a2                	ld	s1,40(sp)
    800031f4:	7902                	ld	s2,32(sp)
    800031f6:	69e2                	ld	s3,24(sp)
    800031f8:	6121                	addi	sp,sp,64
    800031fa:	8082                	ret
      release(&tickslock);
    800031fc:	00015517          	auipc	a0,0x15
    80003200:	ad450513          	addi	a0,a0,-1324 # 80017cd0 <tickslock>
    80003204:	ffffe097          	auipc	ra,0xffffe
    80003208:	a94080e7          	jalr	-1388(ra) # 80000c98 <release>
      return -1;
    8000320c:	57fd                	li	a5,-1
    8000320e:	bff9                	j	800031ec <sys_sleep+0x88>

0000000080003210 <sys_kill>:

uint64
sys_kill(void)
{
    80003210:	1101                	addi	sp,sp,-32
    80003212:	ec06                	sd	ra,24(sp)
    80003214:	e822                	sd	s0,16(sp)
    80003216:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003218:	fec40593          	addi	a1,s0,-20
    8000321c:	4501                	li	a0,0
    8000321e:	00000097          	auipc	ra,0x0
    80003222:	b3c080e7          	jalr	-1220(ra) # 80002d5a <argint>
    80003226:	87aa                	mv	a5,a0
    return -1;
    80003228:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000322a:	0007c863          	bltz	a5,8000323a <sys_kill+0x2a>
  return kill(pid);
    8000322e:	fec42503          	lw	a0,-20(s0)
    80003232:	fffff097          	auipc	ra,0xfffff
    80003236:	45c080e7          	jalr	1116(ra) # 8000268e <kill>
}
    8000323a:	60e2                	ld	ra,24(sp)
    8000323c:	6442                	ld	s0,16(sp)
    8000323e:	6105                	addi	sp,sp,32
    80003240:	8082                	ret

0000000080003242 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003242:	1101                	addi	sp,sp,-32
    80003244:	ec06                	sd	ra,24(sp)
    80003246:	e822                	sd	s0,16(sp)
    80003248:	e426                	sd	s1,8(sp)
    8000324a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000324c:	00015517          	auipc	a0,0x15
    80003250:	a8450513          	addi	a0,a0,-1404 # 80017cd0 <tickslock>
    80003254:	ffffe097          	auipc	ra,0xffffe
    80003258:	990080e7          	jalr	-1648(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000325c:	00006497          	auipc	s1,0x6
    80003260:	dd44a483          	lw	s1,-556(s1) # 80009030 <ticks>
  release(&tickslock);
    80003264:	00015517          	auipc	a0,0x15
    80003268:	a6c50513          	addi	a0,a0,-1428 # 80017cd0 <tickslock>
    8000326c:	ffffe097          	auipc	ra,0xffffe
    80003270:	a2c080e7          	jalr	-1492(ra) # 80000c98 <release>
  return xticks;
}
    80003274:	02049513          	slli	a0,s1,0x20
    80003278:	9101                	srli	a0,a0,0x20
    8000327a:	60e2                	ld	ra,24(sp)
    8000327c:	6442                	ld	s0,16(sp)
    8000327e:	64a2                	ld	s1,8(sp)
    80003280:	6105                	addi	sp,sp,32
    80003282:	8082                	ret

0000000080003284 <sys_trace>:

uint64
sys_trace(void)
{
    80003284:	1101                	addi	sp,sp,-32
    80003286:	ec06                	sd	ra,24(sp)
    80003288:	e822                	sd	s0,16(sp)
    8000328a:	1000                	addi	s0,sp,32
  int arg;
  if (argint(0,&arg)<0)
    8000328c:	fec40593          	addi	a1,s0,-20
    80003290:	4501                	li	a0,0
    80003292:	00000097          	auipc	ra,0x0
    80003296:	ac8080e7          	jalr	-1336(ra) # 80002d5a <argint>
  {
    return -1;
    8000329a:	57fd                	li	a5,-1
  if (argint(0,&arg)<0)
    8000329c:	00054b63          	bltz	a0,800032b2 <sys_trace+0x2e>
  }
  myproc()->tracy = arg;
    800032a0:	ffffe097          	auipc	ra,0xffffe
    800032a4:	78c080e7          	jalr	1932(ra) # 80001a2c <myproc>
    800032a8:	fec42783          	lw	a5,-20(s0)
    800032ac:	16f52423          	sw	a5,360(a0)
  return 0;
    800032b0:	4781                	li	a5,0
}
    800032b2:	853e                	mv	a0,a5
    800032b4:	60e2                	ld	ra,24(sp)
    800032b6:	6442                	ld	s0,16(sp)
    800032b8:	6105                	addi	sp,sp,32
    800032ba:	8082                	ret

00000000800032bc <sys_setpriority>:

uint64
sys_setpriority(void)
{
    800032bc:	1101                	addi	sp,sp,-32
    800032be:	ec06                	sd	ra,24(sp)
    800032c0:	e822                	sd	s0,16(sp)
    800032c2:	1000                	addi	s0,sp,32
  int newpriority,newpid;
  if (argint(0,&newpriority)<0)
    800032c4:	fec40593          	addi	a1,s0,-20
    800032c8:	4501                	li	a0,0
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	a90080e7          	jalr	-1392(ra) # 80002d5a <argint>
  {
    return -1;
    800032d2:	57fd                	li	a5,-1
  if (argint(0,&newpriority)<0)
    800032d4:	02054563          	bltz	a0,800032fe <sys_setpriority+0x42>
  }
  if (argint(1,&newpid)<0)
    800032d8:	fe840593          	addi	a1,s0,-24
    800032dc:	4505                	li	a0,1
    800032de:	00000097          	auipc	ra,0x0
    800032e2:	a7c080e7          	jalr	-1412(ra) # 80002d5a <argint>
  {
    return -1;
    800032e6:	57fd                	li	a5,-1
  if (argint(1,&newpid)<0)
    800032e8:	00054b63          	bltz	a0,800032fe <sys_setpriority+0x42>
  }
  return setpriority(newpriority,newpid);
    800032ec:	fe842583          	lw	a1,-24(s0)
    800032f0:	fec42503          	lw	a0,-20(s0)
    800032f4:	fffff097          	auipc	ra,0xfffff
    800032f8:	e7e080e7          	jalr	-386(ra) # 80002172 <setpriority>
    800032fc:	87aa                	mv	a5,a0
}
    800032fe:	853e                	mv	a0,a5
    80003300:	60e2                	ld	ra,24(sp)
    80003302:	6442                	ld	s0,16(sp)
    80003304:	6105                	addi	sp,sp,32
    80003306:	8082                	ret

0000000080003308 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003308:	7179                	addi	sp,sp,-48
    8000330a:	f406                	sd	ra,40(sp)
    8000330c:	f022                	sd	s0,32(sp)
    8000330e:	ec26                	sd	s1,24(sp)
    80003310:	e84a                	sd	s2,16(sp)
    80003312:	e44e                	sd	s3,8(sp)
    80003314:	e052                	sd	s4,0(sp)
    80003316:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003318:	00005597          	auipc	a1,0x5
    8000331c:	3a058593          	addi	a1,a1,928 # 800086b8 <syscalls+0xc8>
    80003320:	00015517          	auipc	a0,0x15
    80003324:	9c850513          	addi	a0,a0,-1592 # 80017ce8 <bcache>
    80003328:	ffffe097          	auipc	ra,0xffffe
    8000332c:	82c080e7          	jalr	-2004(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003330:	0001d797          	auipc	a5,0x1d
    80003334:	9b878793          	addi	a5,a5,-1608 # 8001fce8 <bcache+0x8000>
    80003338:	0001d717          	auipc	a4,0x1d
    8000333c:	c1870713          	addi	a4,a4,-1000 # 8001ff50 <bcache+0x8268>
    80003340:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003344:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003348:	00015497          	auipc	s1,0x15
    8000334c:	9b848493          	addi	s1,s1,-1608 # 80017d00 <bcache+0x18>
    b->next = bcache.head.next;
    80003350:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003352:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003354:	00005a17          	auipc	s4,0x5
    80003358:	36ca0a13          	addi	s4,s4,876 # 800086c0 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000335c:	2b893783          	ld	a5,696(s2)
    80003360:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003362:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003366:	85d2                	mv	a1,s4
    80003368:	01048513          	addi	a0,s1,16
    8000336c:	00001097          	auipc	ra,0x1
    80003370:	4bc080e7          	jalr	1212(ra) # 80004828 <initsleeplock>
    bcache.head.next->prev = b;
    80003374:	2b893783          	ld	a5,696(s2)
    80003378:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000337a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000337e:	45848493          	addi	s1,s1,1112
    80003382:	fd349de3          	bne	s1,s3,8000335c <binit+0x54>
  }
}
    80003386:	70a2                	ld	ra,40(sp)
    80003388:	7402                	ld	s0,32(sp)
    8000338a:	64e2                	ld	s1,24(sp)
    8000338c:	6942                	ld	s2,16(sp)
    8000338e:	69a2                	ld	s3,8(sp)
    80003390:	6a02                	ld	s4,0(sp)
    80003392:	6145                	addi	sp,sp,48
    80003394:	8082                	ret

0000000080003396 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003396:	7179                	addi	sp,sp,-48
    80003398:	f406                	sd	ra,40(sp)
    8000339a:	f022                	sd	s0,32(sp)
    8000339c:	ec26                	sd	s1,24(sp)
    8000339e:	e84a                	sd	s2,16(sp)
    800033a0:	e44e                	sd	s3,8(sp)
    800033a2:	1800                	addi	s0,sp,48
    800033a4:	89aa                	mv	s3,a0
    800033a6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800033a8:	00015517          	auipc	a0,0x15
    800033ac:	94050513          	addi	a0,a0,-1728 # 80017ce8 <bcache>
    800033b0:	ffffe097          	auipc	ra,0xffffe
    800033b4:	834080e7          	jalr	-1996(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033b8:	0001d497          	auipc	s1,0x1d
    800033bc:	be84b483          	ld	s1,-1048(s1) # 8001ffa0 <bcache+0x82b8>
    800033c0:	0001d797          	auipc	a5,0x1d
    800033c4:	b9078793          	addi	a5,a5,-1136 # 8001ff50 <bcache+0x8268>
    800033c8:	02f48f63          	beq	s1,a5,80003406 <bread+0x70>
    800033cc:	873e                	mv	a4,a5
    800033ce:	a021                	j	800033d6 <bread+0x40>
    800033d0:	68a4                	ld	s1,80(s1)
    800033d2:	02e48a63          	beq	s1,a4,80003406 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033d6:	449c                	lw	a5,8(s1)
    800033d8:	ff379ce3          	bne	a5,s3,800033d0 <bread+0x3a>
    800033dc:	44dc                	lw	a5,12(s1)
    800033de:	ff2799e3          	bne	a5,s2,800033d0 <bread+0x3a>
      b->refcnt++;
    800033e2:	40bc                	lw	a5,64(s1)
    800033e4:	2785                	addiw	a5,a5,1
    800033e6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033e8:	00015517          	auipc	a0,0x15
    800033ec:	90050513          	addi	a0,a0,-1792 # 80017ce8 <bcache>
    800033f0:	ffffe097          	auipc	ra,0xffffe
    800033f4:	8a8080e7          	jalr	-1880(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033f8:	01048513          	addi	a0,s1,16
    800033fc:	00001097          	auipc	ra,0x1
    80003400:	466080e7          	jalr	1126(ra) # 80004862 <acquiresleep>
      return b;
    80003404:	a8b9                	j	80003462 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003406:	0001d497          	auipc	s1,0x1d
    8000340a:	b924b483          	ld	s1,-1134(s1) # 8001ff98 <bcache+0x82b0>
    8000340e:	0001d797          	auipc	a5,0x1d
    80003412:	b4278793          	addi	a5,a5,-1214 # 8001ff50 <bcache+0x8268>
    80003416:	00f48863          	beq	s1,a5,80003426 <bread+0x90>
    8000341a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000341c:	40bc                	lw	a5,64(s1)
    8000341e:	cf81                	beqz	a5,80003436 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003420:	64a4                	ld	s1,72(s1)
    80003422:	fee49de3          	bne	s1,a4,8000341c <bread+0x86>
  panic("bget: no buffers");
    80003426:	00005517          	auipc	a0,0x5
    8000342a:	2a250513          	addi	a0,a0,674 # 800086c8 <syscalls+0xd8>
    8000342e:	ffffd097          	auipc	ra,0xffffd
    80003432:	110080e7          	jalr	272(ra) # 8000053e <panic>
      b->dev = dev;
    80003436:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000343a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000343e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003442:	4785                	li	a5,1
    80003444:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003446:	00015517          	auipc	a0,0x15
    8000344a:	8a250513          	addi	a0,a0,-1886 # 80017ce8 <bcache>
    8000344e:	ffffe097          	auipc	ra,0xffffe
    80003452:	84a080e7          	jalr	-1974(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003456:	01048513          	addi	a0,s1,16
    8000345a:	00001097          	auipc	ra,0x1
    8000345e:	408080e7          	jalr	1032(ra) # 80004862 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003462:	409c                	lw	a5,0(s1)
    80003464:	cb89                	beqz	a5,80003476 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003466:	8526                	mv	a0,s1
    80003468:	70a2                	ld	ra,40(sp)
    8000346a:	7402                	ld	s0,32(sp)
    8000346c:	64e2                	ld	s1,24(sp)
    8000346e:	6942                	ld	s2,16(sp)
    80003470:	69a2                	ld	s3,8(sp)
    80003472:	6145                	addi	sp,sp,48
    80003474:	8082                	ret
    virtio_disk_rw(b, 0);
    80003476:	4581                	li	a1,0
    80003478:	8526                	mv	a0,s1
    8000347a:	00003097          	auipc	ra,0x3
    8000347e:	f0c080e7          	jalr	-244(ra) # 80006386 <virtio_disk_rw>
    b->valid = 1;
    80003482:	4785                	li	a5,1
    80003484:	c09c                	sw	a5,0(s1)
  return b;
    80003486:	b7c5                	j	80003466 <bread+0xd0>

0000000080003488 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003488:	1101                	addi	sp,sp,-32
    8000348a:	ec06                	sd	ra,24(sp)
    8000348c:	e822                	sd	s0,16(sp)
    8000348e:	e426                	sd	s1,8(sp)
    80003490:	1000                	addi	s0,sp,32
    80003492:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003494:	0541                	addi	a0,a0,16
    80003496:	00001097          	auipc	ra,0x1
    8000349a:	466080e7          	jalr	1126(ra) # 800048fc <holdingsleep>
    8000349e:	cd01                	beqz	a0,800034b6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034a0:	4585                	li	a1,1
    800034a2:	8526                	mv	a0,s1
    800034a4:	00003097          	auipc	ra,0x3
    800034a8:	ee2080e7          	jalr	-286(ra) # 80006386 <virtio_disk_rw>
}
    800034ac:	60e2                	ld	ra,24(sp)
    800034ae:	6442                	ld	s0,16(sp)
    800034b0:	64a2                	ld	s1,8(sp)
    800034b2:	6105                	addi	sp,sp,32
    800034b4:	8082                	ret
    panic("bwrite");
    800034b6:	00005517          	auipc	a0,0x5
    800034ba:	22a50513          	addi	a0,a0,554 # 800086e0 <syscalls+0xf0>
    800034be:	ffffd097          	auipc	ra,0xffffd
    800034c2:	080080e7          	jalr	128(ra) # 8000053e <panic>

00000000800034c6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034c6:	1101                	addi	sp,sp,-32
    800034c8:	ec06                	sd	ra,24(sp)
    800034ca:	e822                	sd	s0,16(sp)
    800034cc:	e426                	sd	s1,8(sp)
    800034ce:	e04a                	sd	s2,0(sp)
    800034d0:	1000                	addi	s0,sp,32
    800034d2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034d4:	01050913          	addi	s2,a0,16
    800034d8:	854a                	mv	a0,s2
    800034da:	00001097          	auipc	ra,0x1
    800034de:	422080e7          	jalr	1058(ra) # 800048fc <holdingsleep>
    800034e2:	c92d                	beqz	a0,80003554 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034e4:	854a                	mv	a0,s2
    800034e6:	00001097          	auipc	ra,0x1
    800034ea:	3d2080e7          	jalr	978(ra) # 800048b8 <releasesleep>

  acquire(&bcache.lock);
    800034ee:	00014517          	auipc	a0,0x14
    800034f2:	7fa50513          	addi	a0,a0,2042 # 80017ce8 <bcache>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	6ee080e7          	jalr	1774(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034fe:	40bc                	lw	a5,64(s1)
    80003500:	37fd                	addiw	a5,a5,-1
    80003502:	0007871b          	sext.w	a4,a5
    80003506:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003508:	eb05                	bnez	a4,80003538 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000350a:	68bc                	ld	a5,80(s1)
    8000350c:	64b8                	ld	a4,72(s1)
    8000350e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003510:	64bc                	ld	a5,72(s1)
    80003512:	68b8                	ld	a4,80(s1)
    80003514:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003516:	0001c797          	auipc	a5,0x1c
    8000351a:	7d278793          	addi	a5,a5,2002 # 8001fce8 <bcache+0x8000>
    8000351e:	2b87b703          	ld	a4,696(a5)
    80003522:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003524:	0001d717          	auipc	a4,0x1d
    80003528:	a2c70713          	addi	a4,a4,-1492 # 8001ff50 <bcache+0x8268>
    8000352c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000352e:	2b87b703          	ld	a4,696(a5)
    80003532:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003534:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003538:	00014517          	auipc	a0,0x14
    8000353c:	7b050513          	addi	a0,a0,1968 # 80017ce8 <bcache>
    80003540:	ffffd097          	auipc	ra,0xffffd
    80003544:	758080e7          	jalr	1880(ra) # 80000c98 <release>
}
    80003548:	60e2                	ld	ra,24(sp)
    8000354a:	6442                	ld	s0,16(sp)
    8000354c:	64a2                	ld	s1,8(sp)
    8000354e:	6902                	ld	s2,0(sp)
    80003550:	6105                	addi	sp,sp,32
    80003552:	8082                	ret
    panic("brelse");
    80003554:	00005517          	auipc	a0,0x5
    80003558:	19450513          	addi	a0,a0,404 # 800086e8 <syscalls+0xf8>
    8000355c:	ffffd097          	auipc	ra,0xffffd
    80003560:	fe2080e7          	jalr	-30(ra) # 8000053e <panic>

0000000080003564 <bpin>:

void
bpin(struct buf *b) {
    80003564:	1101                	addi	sp,sp,-32
    80003566:	ec06                	sd	ra,24(sp)
    80003568:	e822                	sd	s0,16(sp)
    8000356a:	e426                	sd	s1,8(sp)
    8000356c:	1000                	addi	s0,sp,32
    8000356e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003570:	00014517          	auipc	a0,0x14
    80003574:	77850513          	addi	a0,a0,1912 # 80017ce8 <bcache>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	66c080e7          	jalr	1644(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003580:	40bc                	lw	a5,64(s1)
    80003582:	2785                	addiw	a5,a5,1
    80003584:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003586:	00014517          	auipc	a0,0x14
    8000358a:	76250513          	addi	a0,a0,1890 # 80017ce8 <bcache>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	70a080e7          	jalr	1802(ra) # 80000c98 <release>
}
    80003596:	60e2                	ld	ra,24(sp)
    80003598:	6442                	ld	s0,16(sp)
    8000359a:	64a2                	ld	s1,8(sp)
    8000359c:	6105                	addi	sp,sp,32
    8000359e:	8082                	ret

00000000800035a0 <bunpin>:

void
bunpin(struct buf *b) {
    800035a0:	1101                	addi	sp,sp,-32
    800035a2:	ec06                	sd	ra,24(sp)
    800035a4:	e822                	sd	s0,16(sp)
    800035a6:	e426                	sd	s1,8(sp)
    800035a8:	1000                	addi	s0,sp,32
    800035aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035ac:	00014517          	auipc	a0,0x14
    800035b0:	73c50513          	addi	a0,a0,1852 # 80017ce8 <bcache>
    800035b4:	ffffd097          	auipc	ra,0xffffd
    800035b8:	630080e7          	jalr	1584(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035bc:	40bc                	lw	a5,64(s1)
    800035be:	37fd                	addiw	a5,a5,-1
    800035c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035c2:	00014517          	auipc	a0,0x14
    800035c6:	72650513          	addi	a0,a0,1830 # 80017ce8 <bcache>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	6ce080e7          	jalr	1742(ra) # 80000c98 <release>
}
    800035d2:	60e2                	ld	ra,24(sp)
    800035d4:	6442                	ld	s0,16(sp)
    800035d6:	64a2                	ld	s1,8(sp)
    800035d8:	6105                	addi	sp,sp,32
    800035da:	8082                	ret

00000000800035dc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035dc:	1101                	addi	sp,sp,-32
    800035de:	ec06                	sd	ra,24(sp)
    800035e0:	e822                	sd	s0,16(sp)
    800035e2:	e426                	sd	s1,8(sp)
    800035e4:	e04a                	sd	s2,0(sp)
    800035e6:	1000                	addi	s0,sp,32
    800035e8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035ea:	00d5d59b          	srliw	a1,a1,0xd
    800035ee:	0001d797          	auipc	a5,0x1d
    800035f2:	dd67a783          	lw	a5,-554(a5) # 800203c4 <sb+0x1c>
    800035f6:	9dbd                	addw	a1,a1,a5
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	d9e080e7          	jalr	-610(ra) # 80003396 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003600:	0074f713          	andi	a4,s1,7
    80003604:	4785                	li	a5,1
    80003606:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000360a:	14ce                	slli	s1,s1,0x33
    8000360c:	90d9                	srli	s1,s1,0x36
    8000360e:	00950733          	add	a4,a0,s1
    80003612:	05874703          	lbu	a4,88(a4)
    80003616:	00e7f6b3          	and	a3,a5,a4
    8000361a:	c69d                	beqz	a3,80003648 <bfree+0x6c>
    8000361c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000361e:	94aa                	add	s1,s1,a0
    80003620:	fff7c793          	not	a5,a5
    80003624:	8ff9                	and	a5,a5,a4
    80003626:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000362a:	00001097          	auipc	ra,0x1
    8000362e:	118080e7          	jalr	280(ra) # 80004742 <log_write>
  brelse(bp);
    80003632:	854a                	mv	a0,s2
    80003634:	00000097          	auipc	ra,0x0
    80003638:	e92080e7          	jalr	-366(ra) # 800034c6 <brelse>
}
    8000363c:	60e2                	ld	ra,24(sp)
    8000363e:	6442                	ld	s0,16(sp)
    80003640:	64a2                	ld	s1,8(sp)
    80003642:	6902                	ld	s2,0(sp)
    80003644:	6105                	addi	sp,sp,32
    80003646:	8082                	ret
    panic("freeing free block");
    80003648:	00005517          	auipc	a0,0x5
    8000364c:	0a850513          	addi	a0,a0,168 # 800086f0 <syscalls+0x100>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	eee080e7          	jalr	-274(ra) # 8000053e <panic>

0000000080003658 <balloc>:
{
    80003658:	711d                	addi	sp,sp,-96
    8000365a:	ec86                	sd	ra,88(sp)
    8000365c:	e8a2                	sd	s0,80(sp)
    8000365e:	e4a6                	sd	s1,72(sp)
    80003660:	e0ca                	sd	s2,64(sp)
    80003662:	fc4e                	sd	s3,56(sp)
    80003664:	f852                	sd	s4,48(sp)
    80003666:	f456                	sd	s5,40(sp)
    80003668:	f05a                	sd	s6,32(sp)
    8000366a:	ec5e                	sd	s7,24(sp)
    8000366c:	e862                	sd	s8,16(sp)
    8000366e:	e466                	sd	s9,8(sp)
    80003670:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003672:	0001d797          	auipc	a5,0x1d
    80003676:	d3a7a783          	lw	a5,-710(a5) # 800203ac <sb+0x4>
    8000367a:	cbd1                	beqz	a5,8000370e <balloc+0xb6>
    8000367c:	8baa                	mv	s7,a0
    8000367e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003680:	0001db17          	auipc	s6,0x1d
    80003684:	d28b0b13          	addi	s6,s6,-728 # 800203a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003688:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000368a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000368c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000368e:	6c89                	lui	s9,0x2
    80003690:	a831                	j	800036ac <balloc+0x54>
    brelse(bp);
    80003692:	854a                	mv	a0,s2
    80003694:	00000097          	auipc	ra,0x0
    80003698:	e32080e7          	jalr	-462(ra) # 800034c6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000369c:	015c87bb          	addw	a5,s9,s5
    800036a0:	00078a9b          	sext.w	s5,a5
    800036a4:	004b2703          	lw	a4,4(s6)
    800036a8:	06eaf363          	bgeu	s5,a4,8000370e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800036ac:	41fad79b          	sraiw	a5,s5,0x1f
    800036b0:	0137d79b          	srliw	a5,a5,0x13
    800036b4:	015787bb          	addw	a5,a5,s5
    800036b8:	40d7d79b          	sraiw	a5,a5,0xd
    800036bc:	01cb2583          	lw	a1,28(s6)
    800036c0:	9dbd                	addw	a1,a1,a5
    800036c2:	855e                	mv	a0,s7
    800036c4:	00000097          	auipc	ra,0x0
    800036c8:	cd2080e7          	jalr	-814(ra) # 80003396 <bread>
    800036cc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ce:	004b2503          	lw	a0,4(s6)
    800036d2:	000a849b          	sext.w	s1,s5
    800036d6:	8662                	mv	a2,s8
    800036d8:	faa4fde3          	bgeu	s1,a0,80003692 <balloc+0x3a>
      m = 1 << (bi % 8);
    800036dc:	41f6579b          	sraiw	a5,a2,0x1f
    800036e0:	01d7d69b          	srliw	a3,a5,0x1d
    800036e4:	00c6873b          	addw	a4,a3,a2
    800036e8:	00777793          	andi	a5,a4,7
    800036ec:	9f95                	subw	a5,a5,a3
    800036ee:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036f2:	4037571b          	sraiw	a4,a4,0x3
    800036f6:	00e906b3          	add	a3,s2,a4
    800036fa:	0586c683          	lbu	a3,88(a3)
    800036fe:	00d7f5b3          	and	a1,a5,a3
    80003702:	cd91                	beqz	a1,8000371e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003704:	2605                	addiw	a2,a2,1
    80003706:	2485                	addiw	s1,s1,1
    80003708:	fd4618e3          	bne	a2,s4,800036d8 <balloc+0x80>
    8000370c:	b759                	j	80003692 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000370e:	00005517          	auipc	a0,0x5
    80003712:	ffa50513          	addi	a0,a0,-6 # 80008708 <syscalls+0x118>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	e28080e7          	jalr	-472(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000371e:	974a                	add	a4,a4,s2
    80003720:	8fd5                	or	a5,a5,a3
    80003722:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003726:	854a                	mv	a0,s2
    80003728:	00001097          	auipc	ra,0x1
    8000372c:	01a080e7          	jalr	26(ra) # 80004742 <log_write>
        brelse(bp);
    80003730:	854a                	mv	a0,s2
    80003732:	00000097          	auipc	ra,0x0
    80003736:	d94080e7          	jalr	-620(ra) # 800034c6 <brelse>
  bp = bread(dev, bno);
    8000373a:	85a6                	mv	a1,s1
    8000373c:	855e                	mv	a0,s7
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	c58080e7          	jalr	-936(ra) # 80003396 <bread>
    80003746:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003748:	40000613          	li	a2,1024
    8000374c:	4581                	li	a1,0
    8000374e:	05850513          	addi	a0,a0,88
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	58e080e7          	jalr	1422(ra) # 80000ce0 <memset>
  log_write(bp);
    8000375a:	854a                	mv	a0,s2
    8000375c:	00001097          	auipc	ra,0x1
    80003760:	fe6080e7          	jalr	-26(ra) # 80004742 <log_write>
  brelse(bp);
    80003764:	854a                	mv	a0,s2
    80003766:	00000097          	auipc	ra,0x0
    8000376a:	d60080e7          	jalr	-672(ra) # 800034c6 <brelse>
}
    8000376e:	8526                	mv	a0,s1
    80003770:	60e6                	ld	ra,88(sp)
    80003772:	6446                	ld	s0,80(sp)
    80003774:	64a6                	ld	s1,72(sp)
    80003776:	6906                	ld	s2,64(sp)
    80003778:	79e2                	ld	s3,56(sp)
    8000377a:	7a42                	ld	s4,48(sp)
    8000377c:	7aa2                	ld	s5,40(sp)
    8000377e:	7b02                	ld	s6,32(sp)
    80003780:	6be2                	ld	s7,24(sp)
    80003782:	6c42                	ld	s8,16(sp)
    80003784:	6ca2                	ld	s9,8(sp)
    80003786:	6125                	addi	sp,sp,96
    80003788:	8082                	ret

000000008000378a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000378a:	7179                	addi	sp,sp,-48
    8000378c:	f406                	sd	ra,40(sp)
    8000378e:	f022                	sd	s0,32(sp)
    80003790:	ec26                	sd	s1,24(sp)
    80003792:	e84a                	sd	s2,16(sp)
    80003794:	e44e                	sd	s3,8(sp)
    80003796:	e052                	sd	s4,0(sp)
    80003798:	1800                	addi	s0,sp,48
    8000379a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000379c:	47ad                	li	a5,11
    8000379e:	04b7fe63          	bgeu	a5,a1,800037fa <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800037a2:	ff45849b          	addiw	s1,a1,-12
    800037a6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037aa:	0ff00793          	li	a5,255
    800037ae:	0ae7e363          	bltu	a5,a4,80003854 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800037b2:	08052583          	lw	a1,128(a0)
    800037b6:	c5ad                	beqz	a1,80003820 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800037b8:	00092503          	lw	a0,0(s2)
    800037bc:	00000097          	auipc	ra,0x0
    800037c0:	bda080e7          	jalr	-1062(ra) # 80003396 <bread>
    800037c4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037c6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037ca:	02049593          	slli	a1,s1,0x20
    800037ce:	9181                	srli	a1,a1,0x20
    800037d0:	058a                	slli	a1,a1,0x2
    800037d2:	00b784b3          	add	s1,a5,a1
    800037d6:	0004a983          	lw	s3,0(s1)
    800037da:	04098d63          	beqz	s3,80003834 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037de:	8552                	mv	a0,s4
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	ce6080e7          	jalr	-794(ra) # 800034c6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037e8:	854e                	mv	a0,s3
    800037ea:	70a2                	ld	ra,40(sp)
    800037ec:	7402                	ld	s0,32(sp)
    800037ee:	64e2                	ld	s1,24(sp)
    800037f0:	6942                	ld	s2,16(sp)
    800037f2:	69a2                	ld	s3,8(sp)
    800037f4:	6a02                	ld	s4,0(sp)
    800037f6:	6145                	addi	sp,sp,48
    800037f8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037fa:	02059493          	slli	s1,a1,0x20
    800037fe:	9081                	srli	s1,s1,0x20
    80003800:	048a                	slli	s1,s1,0x2
    80003802:	94aa                	add	s1,s1,a0
    80003804:	0504a983          	lw	s3,80(s1)
    80003808:	fe0990e3          	bnez	s3,800037e8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000380c:	4108                	lw	a0,0(a0)
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	e4a080e7          	jalr	-438(ra) # 80003658 <balloc>
    80003816:	0005099b          	sext.w	s3,a0
    8000381a:	0534a823          	sw	s3,80(s1)
    8000381e:	b7e9                	j	800037e8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003820:	4108                	lw	a0,0(a0)
    80003822:	00000097          	auipc	ra,0x0
    80003826:	e36080e7          	jalr	-458(ra) # 80003658 <balloc>
    8000382a:	0005059b          	sext.w	a1,a0
    8000382e:	08b92023          	sw	a1,128(s2)
    80003832:	b759                	j	800037b8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003834:	00092503          	lw	a0,0(s2)
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	e20080e7          	jalr	-480(ra) # 80003658 <balloc>
    80003840:	0005099b          	sext.w	s3,a0
    80003844:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003848:	8552                	mv	a0,s4
    8000384a:	00001097          	auipc	ra,0x1
    8000384e:	ef8080e7          	jalr	-264(ra) # 80004742 <log_write>
    80003852:	b771                	j	800037de <bmap+0x54>
  panic("bmap: out of range");
    80003854:	00005517          	auipc	a0,0x5
    80003858:	ecc50513          	addi	a0,a0,-308 # 80008720 <syscalls+0x130>
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	ce2080e7          	jalr	-798(ra) # 8000053e <panic>

0000000080003864 <iget>:
{
    80003864:	7179                	addi	sp,sp,-48
    80003866:	f406                	sd	ra,40(sp)
    80003868:	f022                	sd	s0,32(sp)
    8000386a:	ec26                	sd	s1,24(sp)
    8000386c:	e84a                	sd	s2,16(sp)
    8000386e:	e44e                	sd	s3,8(sp)
    80003870:	e052                	sd	s4,0(sp)
    80003872:	1800                	addi	s0,sp,48
    80003874:	89aa                	mv	s3,a0
    80003876:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003878:	0001d517          	auipc	a0,0x1d
    8000387c:	b5050513          	addi	a0,a0,-1200 # 800203c8 <itable>
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	364080e7          	jalr	868(ra) # 80000be4 <acquire>
  empty = 0;
    80003888:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000388a:	0001d497          	auipc	s1,0x1d
    8000388e:	b5648493          	addi	s1,s1,-1194 # 800203e0 <itable+0x18>
    80003892:	0001e697          	auipc	a3,0x1e
    80003896:	5de68693          	addi	a3,a3,1502 # 80021e70 <log>
    8000389a:	a039                	j	800038a8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000389c:	02090b63          	beqz	s2,800038d2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038a0:	08848493          	addi	s1,s1,136
    800038a4:	02d48a63          	beq	s1,a3,800038d8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038a8:	449c                	lw	a5,8(s1)
    800038aa:	fef059e3          	blez	a5,8000389c <iget+0x38>
    800038ae:	4098                	lw	a4,0(s1)
    800038b0:	ff3716e3          	bne	a4,s3,8000389c <iget+0x38>
    800038b4:	40d8                	lw	a4,4(s1)
    800038b6:	ff4713e3          	bne	a4,s4,8000389c <iget+0x38>
      ip->ref++;
    800038ba:	2785                	addiw	a5,a5,1
    800038bc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038be:	0001d517          	auipc	a0,0x1d
    800038c2:	b0a50513          	addi	a0,a0,-1270 # 800203c8 <itable>
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	3d2080e7          	jalr	978(ra) # 80000c98 <release>
      return ip;
    800038ce:	8926                	mv	s2,s1
    800038d0:	a03d                	j	800038fe <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038d2:	f7f9                	bnez	a5,800038a0 <iget+0x3c>
    800038d4:	8926                	mv	s2,s1
    800038d6:	b7e9                	j	800038a0 <iget+0x3c>
  if(empty == 0)
    800038d8:	02090c63          	beqz	s2,80003910 <iget+0xac>
  ip->dev = dev;
    800038dc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038e0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038e4:	4785                	li	a5,1
    800038e6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038ea:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038ee:	0001d517          	auipc	a0,0x1d
    800038f2:	ada50513          	addi	a0,a0,-1318 # 800203c8 <itable>
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	3a2080e7          	jalr	930(ra) # 80000c98 <release>
}
    800038fe:	854a                	mv	a0,s2
    80003900:	70a2                	ld	ra,40(sp)
    80003902:	7402                	ld	s0,32(sp)
    80003904:	64e2                	ld	s1,24(sp)
    80003906:	6942                	ld	s2,16(sp)
    80003908:	69a2                	ld	s3,8(sp)
    8000390a:	6a02                	ld	s4,0(sp)
    8000390c:	6145                	addi	sp,sp,48
    8000390e:	8082                	ret
    panic("iget: no inodes");
    80003910:	00005517          	auipc	a0,0x5
    80003914:	e2850513          	addi	a0,a0,-472 # 80008738 <syscalls+0x148>
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	c26080e7          	jalr	-986(ra) # 8000053e <panic>

0000000080003920 <fsinit>:
fsinit(int dev) {
    80003920:	7179                	addi	sp,sp,-48
    80003922:	f406                	sd	ra,40(sp)
    80003924:	f022                	sd	s0,32(sp)
    80003926:	ec26                	sd	s1,24(sp)
    80003928:	e84a                	sd	s2,16(sp)
    8000392a:	e44e                	sd	s3,8(sp)
    8000392c:	1800                	addi	s0,sp,48
    8000392e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003930:	4585                	li	a1,1
    80003932:	00000097          	auipc	ra,0x0
    80003936:	a64080e7          	jalr	-1436(ra) # 80003396 <bread>
    8000393a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000393c:	0001d997          	auipc	s3,0x1d
    80003940:	a6c98993          	addi	s3,s3,-1428 # 800203a8 <sb>
    80003944:	02000613          	li	a2,32
    80003948:	05850593          	addi	a1,a0,88
    8000394c:	854e                	mv	a0,s3
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	3f2080e7          	jalr	1010(ra) # 80000d40 <memmove>
  brelse(bp);
    80003956:	8526                	mv	a0,s1
    80003958:	00000097          	auipc	ra,0x0
    8000395c:	b6e080e7          	jalr	-1170(ra) # 800034c6 <brelse>
  if(sb.magic != FSMAGIC)
    80003960:	0009a703          	lw	a4,0(s3)
    80003964:	102037b7          	lui	a5,0x10203
    80003968:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000396c:	02f71263          	bne	a4,a5,80003990 <fsinit+0x70>
  initlog(dev, &sb);
    80003970:	0001d597          	auipc	a1,0x1d
    80003974:	a3858593          	addi	a1,a1,-1480 # 800203a8 <sb>
    80003978:	854a                	mv	a0,s2
    8000397a:	00001097          	auipc	ra,0x1
    8000397e:	b4c080e7          	jalr	-1204(ra) # 800044c6 <initlog>
}
    80003982:	70a2                	ld	ra,40(sp)
    80003984:	7402                	ld	s0,32(sp)
    80003986:	64e2                	ld	s1,24(sp)
    80003988:	6942                	ld	s2,16(sp)
    8000398a:	69a2                	ld	s3,8(sp)
    8000398c:	6145                	addi	sp,sp,48
    8000398e:	8082                	ret
    panic("invalid file system");
    80003990:	00005517          	auipc	a0,0x5
    80003994:	db850513          	addi	a0,a0,-584 # 80008748 <syscalls+0x158>
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	ba6080e7          	jalr	-1114(ra) # 8000053e <panic>

00000000800039a0 <iinit>:
{
    800039a0:	7179                	addi	sp,sp,-48
    800039a2:	f406                	sd	ra,40(sp)
    800039a4:	f022                	sd	s0,32(sp)
    800039a6:	ec26                	sd	s1,24(sp)
    800039a8:	e84a                	sd	s2,16(sp)
    800039aa:	e44e                	sd	s3,8(sp)
    800039ac:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039ae:	00005597          	auipc	a1,0x5
    800039b2:	db258593          	addi	a1,a1,-590 # 80008760 <syscalls+0x170>
    800039b6:	0001d517          	auipc	a0,0x1d
    800039ba:	a1250513          	addi	a0,a0,-1518 # 800203c8 <itable>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	196080e7          	jalr	406(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039c6:	0001d497          	auipc	s1,0x1d
    800039ca:	a2a48493          	addi	s1,s1,-1494 # 800203f0 <itable+0x28>
    800039ce:	0001e997          	auipc	s3,0x1e
    800039d2:	4b298993          	addi	s3,s3,1202 # 80021e80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039d6:	00005917          	auipc	s2,0x5
    800039da:	d9290913          	addi	s2,s2,-622 # 80008768 <syscalls+0x178>
    800039de:	85ca                	mv	a1,s2
    800039e0:	8526                	mv	a0,s1
    800039e2:	00001097          	auipc	ra,0x1
    800039e6:	e46080e7          	jalr	-442(ra) # 80004828 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039ea:	08848493          	addi	s1,s1,136
    800039ee:	ff3498e3          	bne	s1,s3,800039de <iinit+0x3e>
}
    800039f2:	70a2                	ld	ra,40(sp)
    800039f4:	7402                	ld	s0,32(sp)
    800039f6:	64e2                	ld	s1,24(sp)
    800039f8:	6942                	ld	s2,16(sp)
    800039fa:	69a2                	ld	s3,8(sp)
    800039fc:	6145                	addi	sp,sp,48
    800039fe:	8082                	ret

0000000080003a00 <ialloc>:
{
    80003a00:	715d                	addi	sp,sp,-80
    80003a02:	e486                	sd	ra,72(sp)
    80003a04:	e0a2                	sd	s0,64(sp)
    80003a06:	fc26                	sd	s1,56(sp)
    80003a08:	f84a                	sd	s2,48(sp)
    80003a0a:	f44e                	sd	s3,40(sp)
    80003a0c:	f052                	sd	s4,32(sp)
    80003a0e:	ec56                	sd	s5,24(sp)
    80003a10:	e85a                	sd	s6,16(sp)
    80003a12:	e45e                	sd	s7,8(sp)
    80003a14:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a16:	0001d717          	auipc	a4,0x1d
    80003a1a:	99e72703          	lw	a4,-1634(a4) # 800203b4 <sb+0xc>
    80003a1e:	4785                	li	a5,1
    80003a20:	04e7fa63          	bgeu	a5,a4,80003a74 <ialloc+0x74>
    80003a24:	8aaa                	mv	s5,a0
    80003a26:	8bae                	mv	s7,a1
    80003a28:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a2a:	0001da17          	auipc	s4,0x1d
    80003a2e:	97ea0a13          	addi	s4,s4,-1666 # 800203a8 <sb>
    80003a32:	00048b1b          	sext.w	s6,s1
    80003a36:	0044d593          	srli	a1,s1,0x4
    80003a3a:	018a2783          	lw	a5,24(s4)
    80003a3e:	9dbd                	addw	a1,a1,a5
    80003a40:	8556                	mv	a0,s5
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	954080e7          	jalr	-1708(ra) # 80003396 <bread>
    80003a4a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a4c:	05850993          	addi	s3,a0,88
    80003a50:	00f4f793          	andi	a5,s1,15
    80003a54:	079a                	slli	a5,a5,0x6
    80003a56:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a58:	00099783          	lh	a5,0(s3)
    80003a5c:	c785                	beqz	a5,80003a84 <ialloc+0x84>
    brelse(bp);
    80003a5e:	00000097          	auipc	ra,0x0
    80003a62:	a68080e7          	jalr	-1432(ra) # 800034c6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a66:	0485                	addi	s1,s1,1
    80003a68:	00ca2703          	lw	a4,12(s4)
    80003a6c:	0004879b          	sext.w	a5,s1
    80003a70:	fce7e1e3          	bltu	a5,a4,80003a32 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a74:	00005517          	auipc	a0,0x5
    80003a78:	cfc50513          	addi	a0,a0,-772 # 80008770 <syscalls+0x180>
    80003a7c:	ffffd097          	auipc	ra,0xffffd
    80003a80:	ac2080e7          	jalr	-1342(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a84:	04000613          	li	a2,64
    80003a88:	4581                	li	a1,0
    80003a8a:	854e                	mv	a0,s3
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	254080e7          	jalr	596(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a94:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a98:	854a                	mv	a0,s2
    80003a9a:	00001097          	auipc	ra,0x1
    80003a9e:	ca8080e7          	jalr	-856(ra) # 80004742 <log_write>
      brelse(bp);
    80003aa2:	854a                	mv	a0,s2
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	a22080e7          	jalr	-1502(ra) # 800034c6 <brelse>
      return iget(dev, inum);
    80003aac:	85da                	mv	a1,s6
    80003aae:	8556                	mv	a0,s5
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	db4080e7          	jalr	-588(ra) # 80003864 <iget>
}
    80003ab8:	60a6                	ld	ra,72(sp)
    80003aba:	6406                	ld	s0,64(sp)
    80003abc:	74e2                	ld	s1,56(sp)
    80003abe:	7942                	ld	s2,48(sp)
    80003ac0:	79a2                	ld	s3,40(sp)
    80003ac2:	7a02                	ld	s4,32(sp)
    80003ac4:	6ae2                	ld	s5,24(sp)
    80003ac6:	6b42                	ld	s6,16(sp)
    80003ac8:	6ba2                	ld	s7,8(sp)
    80003aca:	6161                	addi	sp,sp,80
    80003acc:	8082                	ret

0000000080003ace <iupdate>:
{
    80003ace:	1101                	addi	sp,sp,-32
    80003ad0:	ec06                	sd	ra,24(sp)
    80003ad2:	e822                	sd	s0,16(sp)
    80003ad4:	e426                	sd	s1,8(sp)
    80003ad6:	e04a                	sd	s2,0(sp)
    80003ad8:	1000                	addi	s0,sp,32
    80003ada:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003adc:	415c                	lw	a5,4(a0)
    80003ade:	0047d79b          	srliw	a5,a5,0x4
    80003ae2:	0001d597          	auipc	a1,0x1d
    80003ae6:	8de5a583          	lw	a1,-1826(a1) # 800203c0 <sb+0x18>
    80003aea:	9dbd                	addw	a1,a1,a5
    80003aec:	4108                	lw	a0,0(a0)
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	8a8080e7          	jalr	-1880(ra) # 80003396 <bread>
    80003af6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003af8:	05850793          	addi	a5,a0,88
    80003afc:	40c8                	lw	a0,4(s1)
    80003afe:	893d                	andi	a0,a0,15
    80003b00:	051a                	slli	a0,a0,0x6
    80003b02:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b04:	04449703          	lh	a4,68(s1)
    80003b08:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b0c:	04649703          	lh	a4,70(s1)
    80003b10:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b14:	04849703          	lh	a4,72(s1)
    80003b18:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b1c:	04a49703          	lh	a4,74(s1)
    80003b20:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b24:	44f8                	lw	a4,76(s1)
    80003b26:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b28:	03400613          	li	a2,52
    80003b2c:	05048593          	addi	a1,s1,80
    80003b30:	0531                	addi	a0,a0,12
    80003b32:	ffffd097          	auipc	ra,0xffffd
    80003b36:	20e080e7          	jalr	526(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b3a:	854a                	mv	a0,s2
    80003b3c:	00001097          	auipc	ra,0x1
    80003b40:	c06080e7          	jalr	-1018(ra) # 80004742 <log_write>
  brelse(bp);
    80003b44:	854a                	mv	a0,s2
    80003b46:	00000097          	auipc	ra,0x0
    80003b4a:	980080e7          	jalr	-1664(ra) # 800034c6 <brelse>
}
    80003b4e:	60e2                	ld	ra,24(sp)
    80003b50:	6442                	ld	s0,16(sp)
    80003b52:	64a2                	ld	s1,8(sp)
    80003b54:	6902                	ld	s2,0(sp)
    80003b56:	6105                	addi	sp,sp,32
    80003b58:	8082                	ret

0000000080003b5a <idup>:
{
    80003b5a:	1101                	addi	sp,sp,-32
    80003b5c:	ec06                	sd	ra,24(sp)
    80003b5e:	e822                	sd	s0,16(sp)
    80003b60:	e426                	sd	s1,8(sp)
    80003b62:	1000                	addi	s0,sp,32
    80003b64:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b66:	0001d517          	auipc	a0,0x1d
    80003b6a:	86250513          	addi	a0,a0,-1950 # 800203c8 <itable>
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	076080e7          	jalr	118(ra) # 80000be4 <acquire>
  ip->ref++;
    80003b76:	449c                	lw	a5,8(s1)
    80003b78:	2785                	addiw	a5,a5,1
    80003b7a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b7c:	0001d517          	auipc	a0,0x1d
    80003b80:	84c50513          	addi	a0,a0,-1972 # 800203c8 <itable>
    80003b84:	ffffd097          	auipc	ra,0xffffd
    80003b88:	114080e7          	jalr	276(ra) # 80000c98 <release>
}
    80003b8c:	8526                	mv	a0,s1
    80003b8e:	60e2                	ld	ra,24(sp)
    80003b90:	6442                	ld	s0,16(sp)
    80003b92:	64a2                	ld	s1,8(sp)
    80003b94:	6105                	addi	sp,sp,32
    80003b96:	8082                	ret

0000000080003b98 <ilock>:
{
    80003b98:	1101                	addi	sp,sp,-32
    80003b9a:	ec06                	sd	ra,24(sp)
    80003b9c:	e822                	sd	s0,16(sp)
    80003b9e:	e426                	sd	s1,8(sp)
    80003ba0:	e04a                	sd	s2,0(sp)
    80003ba2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ba4:	c115                	beqz	a0,80003bc8 <ilock+0x30>
    80003ba6:	84aa                	mv	s1,a0
    80003ba8:	451c                	lw	a5,8(a0)
    80003baa:	00f05f63          	blez	a5,80003bc8 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003bae:	0541                	addi	a0,a0,16
    80003bb0:	00001097          	auipc	ra,0x1
    80003bb4:	cb2080e7          	jalr	-846(ra) # 80004862 <acquiresleep>
  if(ip->valid == 0){
    80003bb8:	40bc                	lw	a5,64(s1)
    80003bba:	cf99                	beqz	a5,80003bd8 <ilock+0x40>
}
    80003bbc:	60e2                	ld	ra,24(sp)
    80003bbe:	6442                	ld	s0,16(sp)
    80003bc0:	64a2                	ld	s1,8(sp)
    80003bc2:	6902                	ld	s2,0(sp)
    80003bc4:	6105                	addi	sp,sp,32
    80003bc6:	8082                	ret
    panic("ilock");
    80003bc8:	00005517          	auipc	a0,0x5
    80003bcc:	bc050513          	addi	a0,a0,-1088 # 80008788 <syscalls+0x198>
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	96e080e7          	jalr	-1682(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bd8:	40dc                	lw	a5,4(s1)
    80003bda:	0047d79b          	srliw	a5,a5,0x4
    80003bde:	0001c597          	auipc	a1,0x1c
    80003be2:	7e25a583          	lw	a1,2018(a1) # 800203c0 <sb+0x18>
    80003be6:	9dbd                	addw	a1,a1,a5
    80003be8:	4088                	lw	a0,0(s1)
    80003bea:	fffff097          	auipc	ra,0xfffff
    80003bee:	7ac080e7          	jalr	1964(ra) # 80003396 <bread>
    80003bf2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bf4:	05850593          	addi	a1,a0,88
    80003bf8:	40dc                	lw	a5,4(s1)
    80003bfa:	8bbd                	andi	a5,a5,15
    80003bfc:	079a                	slli	a5,a5,0x6
    80003bfe:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c00:	00059783          	lh	a5,0(a1)
    80003c04:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c08:	00259783          	lh	a5,2(a1)
    80003c0c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c10:	00459783          	lh	a5,4(a1)
    80003c14:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c18:	00659783          	lh	a5,6(a1)
    80003c1c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c20:	459c                	lw	a5,8(a1)
    80003c22:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c24:	03400613          	li	a2,52
    80003c28:	05b1                	addi	a1,a1,12
    80003c2a:	05048513          	addi	a0,s1,80
    80003c2e:	ffffd097          	auipc	ra,0xffffd
    80003c32:	112080e7          	jalr	274(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c36:	854a                	mv	a0,s2
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	88e080e7          	jalr	-1906(ra) # 800034c6 <brelse>
    ip->valid = 1;
    80003c40:	4785                	li	a5,1
    80003c42:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c44:	04449783          	lh	a5,68(s1)
    80003c48:	fbb5                	bnez	a5,80003bbc <ilock+0x24>
      panic("ilock: no type");
    80003c4a:	00005517          	auipc	a0,0x5
    80003c4e:	b4650513          	addi	a0,a0,-1210 # 80008790 <syscalls+0x1a0>
    80003c52:	ffffd097          	auipc	ra,0xffffd
    80003c56:	8ec080e7          	jalr	-1812(ra) # 8000053e <panic>

0000000080003c5a <iunlock>:
{
    80003c5a:	1101                	addi	sp,sp,-32
    80003c5c:	ec06                	sd	ra,24(sp)
    80003c5e:	e822                	sd	s0,16(sp)
    80003c60:	e426                	sd	s1,8(sp)
    80003c62:	e04a                	sd	s2,0(sp)
    80003c64:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c66:	c905                	beqz	a0,80003c96 <iunlock+0x3c>
    80003c68:	84aa                	mv	s1,a0
    80003c6a:	01050913          	addi	s2,a0,16
    80003c6e:	854a                	mv	a0,s2
    80003c70:	00001097          	auipc	ra,0x1
    80003c74:	c8c080e7          	jalr	-884(ra) # 800048fc <holdingsleep>
    80003c78:	cd19                	beqz	a0,80003c96 <iunlock+0x3c>
    80003c7a:	449c                	lw	a5,8(s1)
    80003c7c:	00f05d63          	blez	a5,80003c96 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c80:	854a                	mv	a0,s2
    80003c82:	00001097          	auipc	ra,0x1
    80003c86:	c36080e7          	jalr	-970(ra) # 800048b8 <releasesleep>
}
    80003c8a:	60e2                	ld	ra,24(sp)
    80003c8c:	6442                	ld	s0,16(sp)
    80003c8e:	64a2                	ld	s1,8(sp)
    80003c90:	6902                	ld	s2,0(sp)
    80003c92:	6105                	addi	sp,sp,32
    80003c94:	8082                	ret
    panic("iunlock");
    80003c96:	00005517          	auipc	a0,0x5
    80003c9a:	b0a50513          	addi	a0,a0,-1270 # 800087a0 <syscalls+0x1b0>
    80003c9e:	ffffd097          	auipc	ra,0xffffd
    80003ca2:	8a0080e7          	jalr	-1888(ra) # 8000053e <panic>

0000000080003ca6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ca6:	7179                	addi	sp,sp,-48
    80003ca8:	f406                	sd	ra,40(sp)
    80003caa:	f022                	sd	s0,32(sp)
    80003cac:	ec26                	sd	s1,24(sp)
    80003cae:	e84a                	sd	s2,16(sp)
    80003cb0:	e44e                	sd	s3,8(sp)
    80003cb2:	e052                	sd	s4,0(sp)
    80003cb4:	1800                	addi	s0,sp,48
    80003cb6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cb8:	05050493          	addi	s1,a0,80
    80003cbc:	08050913          	addi	s2,a0,128
    80003cc0:	a021                	j	80003cc8 <itrunc+0x22>
    80003cc2:	0491                	addi	s1,s1,4
    80003cc4:	01248d63          	beq	s1,s2,80003cde <itrunc+0x38>
    if(ip->addrs[i]){
    80003cc8:	408c                	lw	a1,0(s1)
    80003cca:	dde5                	beqz	a1,80003cc2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ccc:	0009a503          	lw	a0,0(s3)
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	90c080e7          	jalr	-1780(ra) # 800035dc <bfree>
      ip->addrs[i] = 0;
    80003cd8:	0004a023          	sw	zero,0(s1)
    80003cdc:	b7dd                	j	80003cc2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cde:	0809a583          	lw	a1,128(s3)
    80003ce2:	e185                	bnez	a1,80003d02 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ce4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ce8:	854e                	mv	a0,s3
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	de4080e7          	jalr	-540(ra) # 80003ace <iupdate>
}
    80003cf2:	70a2                	ld	ra,40(sp)
    80003cf4:	7402                	ld	s0,32(sp)
    80003cf6:	64e2                	ld	s1,24(sp)
    80003cf8:	6942                	ld	s2,16(sp)
    80003cfa:	69a2                	ld	s3,8(sp)
    80003cfc:	6a02                	ld	s4,0(sp)
    80003cfe:	6145                	addi	sp,sp,48
    80003d00:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d02:	0009a503          	lw	a0,0(s3)
    80003d06:	fffff097          	auipc	ra,0xfffff
    80003d0a:	690080e7          	jalr	1680(ra) # 80003396 <bread>
    80003d0e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d10:	05850493          	addi	s1,a0,88
    80003d14:	45850913          	addi	s2,a0,1112
    80003d18:	a811                	j	80003d2c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d1a:	0009a503          	lw	a0,0(s3)
    80003d1e:	00000097          	auipc	ra,0x0
    80003d22:	8be080e7          	jalr	-1858(ra) # 800035dc <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d26:	0491                	addi	s1,s1,4
    80003d28:	01248563          	beq	s1,s2,80003d32 <itrunc+0x8c>
      if(a[j])
    80003d2c:	408c                	lw	a1,0(s1)
    80003d2e:	dde5                	beqz	a1,80003d26 <itrunc+0x80>
    80003d30:	b7ed                	j	80003d1a <itrunc+0x74>
    brelse(bp);
    80003d32:	8552                	mv	a0,s4
    80003d34:	fffff097          	auipc	ra,0xfffff
    80003d38:	792080e7          	jalr	1938(ra) # 800034c6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d3c:	0809a583          	lw	a1,128(s3)
    80003d40:	0009a503          	lw	a0,0(s3)
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	898080e7          	jalr	-1896(ra) # 800035dc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d4c:	0809a023          	sw	zero,128(s3)
    80003d50:	bf51                	j	80003ce4 <itrunc+0x3e>

0000000080003d52 <iput>:
{
    80003d52:	1101                	addi	sp,sp,-32
    80003d54:	ec06                	sd	ra,24(sp)
    80003d56:	e822                	sd	s0,16(sp)
    80003d58:	e426                	sd	s1,8(sp)
    80003d5a:	e04a                	sd	s2,0(sp)
    80003d5c:	1000                	addi	s0,sp,32
    80003d5e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d60:	0001c517          	auipc	a0,0x1c
    80003d64:	66850513          	addi	a0,a0,1640 # 800203c8 <itable>
    80003d68:	ffffd097          	auipc	ra,0xffffd
    80003d6c:	e7c080e7          	jalr	-388(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d70:	4498                	lw	a4,8(s1)
    80003d72:	4785                	li	a5,1
    80003d74:	02f70363          	beq	a4,a5,80003d9a <iput+0x48>
  ip->ref--;
    80003d78:	449c                	lw	a5,8(s1)
    80003d7a:	37fd                	addiw	a5,a5,-1
    80003d7c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d7e:	0001c517          	auipc	a0,0x1c
    80003d82:	64a50513          	addi	a0,a0,1610 # 800203c8 <itable>
    80003d86:	ffffd097          	auipc	ra,0xffffd
    80003d8a:	f12080e7          	jalr	-238(ra) # 80000c98 <release>
}
    80003d8e:	60e2                	ld	ra,24(sp)
    80003d90:	6442                	ld	s0,16(sp)
    80003d92:	64a2                	ld	s1,8(sp)
    80003d94:	6902                	ld	s2,0(sp)
    80003d96:	6105                	addi	sp,sp,32
    80003d98:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d9a:	40bc                	lw	a5,64(s1)
    80003d9c:	dff1                	beqz	a5,80003d78 <iput+0x26>
    80003d9e:	04a49783          	lh	a5,74(s1)
    80003da2:	fbf9                	bnez	a5,80003d78 <iput+0x26>
    acquiresleep(&ip->lock);
    80003da4:	01048913          	addi	s2,s1,16
    80003da8:	854a                	mv	a0,s2
    80003daa:	00001097          	auipc	ra,0x1
    80003dae:	ab8080e7          	jalr	-1352(ra) # 80004862 <acquiresleep>
    release(&itable.lock);
    80003db2:	0001c517          	auipc	a0,0x1c
    80003db6:	61650513          	addi	a0,a0,1558 # 800203c8 <itable>
    80003dba:	ffffd097          	auipc	ra,0xffffd
    80003dbe:	ede080e7          	jalr	-290(ra) # 80000c98 <release>
    itrunc(ip);
    80003dc2:	8526                	mv	a0,s1
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	ee2080e7          	jalr	-286(ra) # 80003ca6 <itrunc>
    ip->type = 0;
    80003dcc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003dd0:	8526                	mv	a0,s1
    80003dd2:	00000097          	auipc	ra,0x0
    80003dd6:	cfc080e7          	jalr	-772(ra) # 80003ace <iupdate>
    ip->valid = 0;
    80003dda:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dde:	854a                	mv	a0,s2
    80003de0:	00001097          	auipc	ra,0x1
    80003de4:	ad8080e7          	jalr	-1320(ra) # 800048b8 <releasesleep>
    acquire(&itable.lock);
    80003de8:	0001c517          	auipc	a0,0x1c
    80003dec:	5e050513          	addi	a0,a0,1504 # 800203c8 <itable>
    80003df0:	ffffd097          	auipc	ra,0xffffd
    80003df4:	df4080e7          	jalr	-524(ra) # 80000be4 <acquire>
    80003df8:	b741                	j	80003d78 <iput+0x26>

0000000080003dfa <iunlockput>:
{
    80003dfa:	1101                	addi	sp,sp,-32
    80003dfc:	ec06                	sd	ra,24(sp)
    80003dfe:	e822                	sd	s0,16(sp)
    80003e00:	e426                	sd	s1,8(sp)
    80003e02:	1000                	addi	s0,sp,32
    80003e04:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	e54080e7          	jalr	-428(ra) # 80003c5a <iunlock>
  iput(ip);
    80003e0e:	8526                	mv	a0,s1
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	f42080e7          	jalr	-190(ra) # 80003d52 <iput>
}
    80003e18:	60e2                	ld	ra,24(sp)
    80003e1a:	6442                	ld	s0,16(sp)
    80003e1c:	64a2                	ld	s1,8(sp)
    80003e1e:	6105                	addi	sp,sp,32
    80003e20:	8082                	ret

0000000080003e22 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e22:	1141                	addi	sp,sp,-16
    80003e24:	e422                	sd	s0,8(sp)
    80003e26:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e28:	411c                	lw	a5,0(a0)
    80003e2a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e2c:	415c                	lw	a5,4(a0)
    80003e2e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e30:	04451783          	lh	a5,68(a0)
    80003e34:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e38:	04a51783          	lh	a5,74(a0)
    80003e3c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e40:	04c56783          	lwu	a5,76(a0)
    80003e44:	e99c                	sd	a5,16(a1)
}
    80003e46:	6422                	ld	s0,8(sp)
    80003e48:	0141                	addi	sp,sp,16
    80003e4a:	8082                	ret

0000000080003e4c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e4c:	457c                	lw	a5,76(a0)
    80003e4e:	0ed7e963          	bltu	a5,a3,80003f40 <readi+0xf4>
{
    80003e52:	7159                	addi	sp,sp,-112
    80003e54:	f486                	sd	ra,104(sp)
    80003e56:	f0a2                	sd	s0,96(sp)
    80003e58:	eca6                	sd	s1,88(sp)
    80003e5a:	e8ca                	sd	s2,80(sp)
    80003e5c:	e4ce                	sd	s3,72(sp)
    80003e5e:	e0d2                	sd	s4,64(sp)
    80003e60:	fc56                	sd	s5,56(sp)
    80003e62:	f85a                	sd	s6,48(sp)
    80003e64:	f45e                	sd	s7,40(sp)
    80003e66:	f062                	sd	s8,32(sp)
    80003e68:	ec66                	sd	s9,24(sp)
    80003e6a:	e86a                	sd	s10,16(sp)
    80003e6c:	e46e                	sd	s11,8(sp)
    80003e6e:	1880                	addi	s0,sp,112
    80003e70:	8baa                	mv	s7,a0
    80003e72:	8c2e                	mv	s8,a1
    80003e74:	8ab2                	mv	s5,a2
    80003e76:	84b6                	mv	s1,a3
    80003e78:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e7a:	9f35                	addw	a4,a4,a3
    return 0;
    80003e7c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e7e:	0ad76063          	bltu	a4,a3,80003f1e <readi+0xd2>
  if(off + n > ip->size)
    80003e82:	00e7f463          	bgeu	a5,a4,80003e8a <readi+0x3e>
    n = ip->size - off;
    80003e86:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e8a:	0a0b0963          	beqz	s6,80003f3c <readi+0xf0>
    80003e8e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e90:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e94:	5cfd                	li	s9,-1
    80003e96:	a82d                	j	80003ed0 <readi+0x84>
    80003e98:	020a1d93          	slli	s11,s4,0x20
    80003e9c:	020ddd93          	srli	s11,s11,0x20
    80003ea0:	05890613          	addi	a2,s2,88
    80003ea4:	86ee                	mv	a3,s11
    80003ea6:	963a                	add	a2,a2,a4
    80003ea8:	85d6                	mv	a1,s5
    80003eaa:	8562                	mv	a0,s8
    80003eac:	fffff097          	auipc	ra,0xfffff
    80003eb0:	854080e7          	jalr	-1964(ra) # 80002700 <either_copyout>
    80003eb4:	05950d63          	beq	a0,s9,80003f0e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003eb8:	854a                	mv	a0,s2
    80003eba:	fffff097          	auipc	ra,0xfffff
    80003ebe:	60c080e7          	jalr	1548(ra) # 800034c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ec2:	013a09bb          	addw	s3,s4,s3
    80003ec6:	009a04bb          	addw	s1,s4,s1
    80003eca:	9aee                	add	s5,s5,s11
    80003ecc:	0569f763          	bgeu	s3,s6,80003f1a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ed0:	000ba903          	lw	s2,0(s7)
    80003ed4:	00a4d59b          	srliw	a1,s1,0xa
    80003ed8:	855e                	mv	a0,s7
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	8b0080e7          	jalr	-1872(ra) # 8000378a <bmap>
    80003ee2:	0005059b          	sext.w	a1,a0
    80003ee6:	854a                	mv	a0,s2
    80003ee8:	fffff097          	auipc	ra,0xfffff
    80003eec:	4ae080e7          	jalr	1198(ra) # 80003396 <bread>
    80003ef0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ef2:	3ff4f713          	andi	a4,s1,1023
    80003ef6:	40ed07bb          	subw	a5,s10,a4
    80003efa:	413b06bb          	subw	a3,s6,s3
    80003efe:	8a3e                	mv	s4,a5
    80003f00:	2781                	sext.w	a5,a5
    80003f02:	0006861b          	sext.w	a2,a3
    80003f06:	f8f679e3          	bgeu	a2,a5,80003e98 <readi+0x4c>
    80003f0a:	8a36                	mv	s4,a3
    80003f0c:	b771                	j	80003e98 <readi+0x4c>
      brelse(bp);
    80003f0e:	854a                	mv	a0,s2
    80003f10:	fffff097          	auipc	ra,0xfffff
    80003f14:	5b6080e7          	jalr	1462(ra) # 800034c6 <brelse>
      tot = -1;
    80003f18:	59fd                	li	s3,-1
  }
  return tot;
    80003f1a:	0009851b          	sext.w	a0,s3
}
    80003f1e:	70a6                	ld	ra,104(sp)
    80003f20:	7406                	ld	s0,96(sp)
    80003f22:	64e6                	ld	s1,88(sp)
    80003f24:	6946                	ld	s2,80(sp)
    80003f26:	69a6                	ld	s3,72(sp)
    80003f28:	6a06                	ld	s4,64(sp)
    80003f2a:	7ae2                	ld	s5,56(sp)
    80003f2c:	7b42                	ld	s6,48(sp)
    80003f2e:	7ba2                	ld	s7,40(sp)
    80003f30:	7c02                	ld	s8,32(sp)
    80003f32:	6ce2                	ld	s9,24(sp)
    80003f34:	6d42                	ld	s10,16(sp)
    80003f36:	6da2                	ld	s11,8(sp)
    80003f38:	6165                	addi	sp,sp,112
    80003f3a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f3c:	89da                	mv	s3,s6
    80003f3e:	bff1                	j	80003f1a <readi+0xce>
    return 0;
    80003f40:	4501                	li	a0,0
}
    80003f42:	8082                	ret

0000000080003f44 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f44:	457c                	lw	a5,76(a0)
    80003f46:	10d7e863          	bltu	a5,a3,80004056 <writei+0x112>
{
    80003f4a:	7159                	addi	sp,sp,-112
    80003f4c:	f486                	sd	ra,104(sp)
    80003f4e:	f0a2                	sd	s0,96(sp)
    80003f50:	eca6                	sd	s1,88(sp)
    80003f52:	e8ca                	sd	s2,80(sp)
    80003f54:	e4ce                	sd	s3,72(sp)
    80003f56:	e0d2                	sd	s4,64(sp)
    80003f58:	fc56                	sd	s5,56(sp)
    80003f5a:	f85a                	sd	s6,48(sp)
    80003f5c:	f45e                	sd	s7,40(sp)
    80003f5e:	f062                	sd	s8,32(sp)
    80003f60:	ec66                	sd	s9,24(sp)
    80003f62:	e86a                	sd	s10,16(sp)
    80003f64:	e46e                	sd	s11,8(sp)
    80003f66:	1880                	addi	s0,sp,112
    80003f68:	8b2a                	mv	s6,a0
    80003f6a:	8c2e                	mv	s8,a1
    80003f6c:	8ab2                	mv	s5,a2
    80003f6e:	8936                	mv	s2,a3
    80003f70:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f72:	00e687bb          	addw	a5,a3,a4
    80003f76:	0ed7e263          	bltu	a5,a3,8000405a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f7a:	00043737          	lui	a4,0x43
    80003f7e:	0ef76063          	bltu	a4,a5,8000405e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f82:	0c0b8863          	beqz	s7,80004052 <writei+0x10e>
    80003f86:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f88:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f8c:	5cfd                	li	s9,-1
    80003f8e:	a091                	j	80003fd2 <writei+0x8e>
    80003f90:	02099d93          	slli	s11,s3,0x20
    80003f94:	020ddd93          	srli	s11,s11,0x20
    80003f98:	05848513          	addi	a0,s1,88
    80003f9c:	86ee                	mv	a3,s11
    80003f9e:	8656                	mv	a2,s5
    80003fa0:	85e2                	mv	a1,s8
    80003fa2:	953a                	add	a0,a0,a4
    80003fa4:	ffffe097          	auipc	ra,0xffffe
    80003fa8:	7b2080e7          	jalr	1970(ra) # 80002756 <either_copyin>
    80003fac:	07950263          	beq	a0,s9,80004010 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fb0:	8526                	mv	a0,s1
    80003fb2:	00000097          	auipc	ra,0x0
    80003fb6:	790080e7          	jalr	1936(ra) # 80004742 <log_write>
    brelse(bp);
    80003fba:	8526                	mv	a0,s1
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	50a080e7          	jalr	1290(ra) # 800034c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fc4:	01498a3b          	addw	s4,s3,s4
    80003fc8:	0129893b          	addw	s2,s3,s2
    80003fcc:	9aee                	add	s5,s5,s11
    80003fce:	057a7663          	bgeu	s4,s7,8000401a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fd2:	000b2483          	lw	s1,0(s6)
    80003fd6:	00a9559b          	srliw	a1,s2,0xa
    80003fda:	855a                	mv	a0,s6
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	7ae080e7          	jalr	1966(ra) # 8000378a <bmap>
    80003fe4:	0005059b          	sext.w	a1,a0
    80003fe8:	8526                	mv	a0,s1
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	3ac080e7          	jalr	940(ra) # 80003396 <bread>
    80003ff2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ff4:	3ff97713          	andi	a4,s2,1023
    80003ff8:	40ed07bb          	subw	a5,s10,a4
    80003ffc:	414b86bb          	subw	a3,s7,s4
    80004000:	89be                	mv	s3,a5
    80004002:	2781                	sext.w	a5,a5
    80004004:	0006861b          	sext.w	a2,a3
    80004008:	f8f674e3          	bgeu	a2,a5,80003f90 <writei+0x4c>
    8000400c:	89b6                	mv	s3,a3
    8000400e:	b749                	j	80003f90 <writei+0x4c>
      brelse(bp);
    80004010:	8526                	mv	a0,s1
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	4b4080e7          	jalr	1204(ra) # 800034c6 <brelse>
  }

  if(off > ip->size)
    8000401a:	04cb2783          	lw	a5,76(s6)
    8000401e:	0127f463          	bgeu	a5,s2,80004026 <writei+0xe2>
    ip->size = off;
    80004022:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004026:	855a                	mv	a0,s6
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	aa6080e7          	jalr	-1370(ra) # 80003ace <iupdate>

  return tot;
    80004030:	000a051b          	sext.w	a0,s4
}
    80004034:	70a6                	ld	ra,104(sp)
    80004036:	7406                	ld	s0,96(sp)
    80004038:	64e6                	ld	s1,88(sp)
    8000403a:	6946                	ld	s2,80(sp)
    8000403c:	69a6                	ld	s3,72(sp)
    8000403e:	6a06                	ld	s4,64(sp)
    80004040:	7ae2                	ld	s5,56(sp)
    80004042:	7b42                	ld	s6,48(sp)
    80004044:	7ba2                	ld	s7,40(sp)
    80004046:	7c02                	ld	s8,32(sp)
    80004048:	6ce2                	ld	s9,24(sp)
    8000404a:	6d42                	ld	s10,16(sp)
    8000404c:	6da2                	ld	s11,8(sp)
    8000404e:	6165                	addi	sp,sp,112
    80004050:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004052:	8a5e                	mv	s4,s7
    80004054:	bfc9                	j	80004026 <writei+0xe2>
    return -1;
    80004056:	557d                	li	a0,-1
}
    80004058:	8082                	ret
    return -1;
    8000405a:	557d                	li	a0,-1
    8000405c:	bfe1                	j	80004034 <writei+0xf0>
    return -1;
    8000405e:	557d                	li	a0,-1
    80004060:	bfd1                	j	80004034 <writei+0xf0>

0000000080004062 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004062:	1141                	addi	sp,sp,-16
    80004064:	e406                	sd	ra,8(sp)
    80004066:	e022                	sd	s0,0(sp)
    80004068:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000406a:	4639                	li	a2,14
    8000406c:	ffffd097          	auipc	ra,0xffffd
    80004070:	d4c080e7          	jalr	-692(ra) # 80000db8 <strncmp>
}
    80004074:	60a2                	ld	ra,8(sp)
    80004076:	6402                	ld	s0,0(sp)
    80004078:	0141                	addi	sp,sp,16
    8000407a:	8082                	ret

000000008000407c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000407c:	7139                	addi	sp,sp,-64
    8000407e:	fc06                	sd	ra,56(sp)
    80004080:	f822                	sd	s0,48(sp)
    80004082:	f426                	sd	s1,40(sp)
    80004084:	f04a                	sd	s2,32(sp)
    80004086:	ec4e                	sd	s3,24(sp)
    80004088:	e852                	sd	s4,16(sp)
    8000408a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000408c:	04451703          	lh	a4,68(a0)
    80004090:	4785                	li	a5,1
    80004092:	00f71a63          	bne	a4,a5,800040a6 <dirlookup+0x2a>
    80004096:	892a                	mv	s2,a0
    80004098:	89ae                	mv	s3,a1
    8000409a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000409c:	457c                	lw	a5,76(a0)
    8000409e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040a0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a2:	e79d                	bnez	a5,800040d0 <dirlookup+0x54>
    800040a4:	a8a5                	j	8000411c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040a6:	00004517          	auipc	a0,0x4
    800040aa:	70250513          	addi	a0,a0,1794 # 800087a8 <syscalls+0x1b8>
    800040ae:	ffffc097          	auipc	ra,0xffffc
    800040b2:	490080e7          	jalr	1168(ra) # 8000053e <panic>
      panic("dirlookup read");
    800040b6:	00004517          	auipc	a0,0x4
    800040ba:	70a50513          	addi	a0,a0,1802 # 800087c0 <syscalls+0x1d0>
    800040be:	ffffc097          	auipc	ra,0xffffc
    800040c2:	480080e7          	jalr	1152(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c6:	24c1                	addiw	s1,s1,16
    800040c8:	04c92783          	lw	a5,76(s2)
    800040cc:	04f4f763          	bgeu	s1,a5,8000411a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d0:	4741                	li	a4,16
    800040d2:	86a6                	mv	a3,s1
    800040d4:	fc040613          	addi	a2,s0,-64
    800040d8:	4581                	li	a1,0
    800040da:	854a                	mv	a0,s2
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	d70080e7          	jalr	-656(ra) # 80003e4c <readi>
    800040e4:	47c1                	li	a5,16
    800040e6:	fcf518e3          	bne	a0,a5,800040b6 <dirlookup+0x3a>
    if(de.inum == 0)
    800040ea:	fc045783          	lhu	a5,-64(s0)
    800040ee:	dfe1                	beqz	a5,800040c6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040f0:	fc240593          	addi	a1,s0,-62
    800040f4:	854e                	mv	a0,s3
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	f6c080e7          	jalr	-148(ra) # 80004062 <namecmp>
    800040fe:	f561                	bnez	a0,800040c6 <dirlookup+0x4a>
      if(poff)
    80004100:	000a0463          	beqz	s4,80004108 <dirlookup+0x8c>
        *poff = off;
    80004104:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004108:	fc045583          	lhu	a1,-64(s0)
    8000410c:	00092503          	lw	a0,0(s2)
    80004110:	fffff097          	auipc	ra,0xfffff
    80004114:	754080e7          	jalr	1876(ra) # 80003864 <iget>
    80004118:	a011                	j	8000411c <dirlookup+0xa0>
  return 0;
    8000411a:	4501                	li	a0,0
}
    8000411c:	70e2                	ld	ra,56(sp)
    8000411e:	7442                	ld	s0,48(sp)
    80004120:	74a2                	ld	s1,40(sp)
    80004122:	7902                	ld	s2,32(sp)
    80004124:	69e2                	ld	s3,24(sp)
    80004126:	6a42                	ld	s4,16(sp)
    80004128:	6121                	addi	sp,sp,64
    8000412a:	8082                	ret

000000008000412c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000412c:	711d                	addi	sp,sp,-96
    8000412e:	ec86                	sd	ra,88(sp)
    80004130:	e8a2                	sd	s0,80(sp)
    80004132:	e4a6                	sd	s1,72(sp)
    80004134:	e0ca                	sd	s2,64(sp)
    80004136:	fc4e                	sd	s3,56(sp)
    80004138:	f852                	sd	s4,48(sp)
    8000413a:	f456                	sd	s5,40(sp)
    8000413c:	f05a                	sd	s6,32(sp)
    8000413e:	ec5e                	sd	s7,24(sp)
    80004140:	e862                	sd	s8,16(sp)
    80004142:	e466                	sd	s9,8(sp)
    80004144:	1080                	addi	s0,sp,96
    80004146:	84aa                	mv	s1,a0
    80004148:	8b2e                	mv	s6,a1
    8000414a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000414c:	00054703          	lbu	a4,0(a0)
    80004150:	02f00793          	li	a5,47
    80004154:	02f70363          	beq	a4,a5,8000417a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004158:	ffffe097          	auipc	ra,0xffffe
    8000415c:	8d4080e7          	jalr	-1836(ra) # 80001a2c <myproc>
    80004160:	15053503          	ld	a0,336(a0)
    80004164:	00000097          	auipc	ra,0x0
    80004168:	9f6080e7          	jalr	-1546(ra) # 80003b5a <idup>
    8000416c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000416e:	02f00913          	li	s2,47
  len = path - s;
    80004172:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004174:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004176:	4c05                	li	s8,1
    80004178:	a865                	j	80004230 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000417a:	4585                	li	a1,1
    8000417c:	4505                	li	a0,1
    8000417e:	fffff097          	auipc	ra,0xfffff
    80004182:	6e6080e7          	jalr	1766(ra) # 80003864 <iget>
    80004186:	89aa                	mv	s3,a0
    80004188:	b7dd                	j	8000416e <namex+0x42>
      iunlockput(ip);
    8000418a:	854e                	mv	a0,s3
    8000418c:	00000097          	auipc	ra,0x0
    80004190:	c6e080e7          	jalr	-914(ra) # 80003dfa <iunlockput>
      return 0;
    80004194:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004196:	854e                	mv	a0,s3
    80004198:	60e6                	ld	ra,88(sp)
    8000419a:	6446                	ld	s0,80(sp)
    8000419c:	64a6                	ld	s1,72(sp)
    8000419e:	6906                	ld	s2,64(sp)
    800041a0:	79e2                	ld	s3,56(sp)
    800041a2:	7a42                	ld	s4,48(sp)
    800041a4:	7aa2                	ld	s5,40(sp)
    800041a6:	7b02                	ld	s6,32(sp)
    800041a8:	6be2                	ld	s7,24(sp)
    800041aa:	6c42                	ld	s8,16(sp)
    800041ac:	6ca2                	ld	s9,8(sp)
    800041ae:	6125                	addi	sp,sp,96
    800041b0:	8082                	ret
      iunlock(ip);
    800041b2:	854e                	mv	a0,s3
    800041b4:	00000097          	auipc	ra,0x0
    800041b8:	aa6080e7          	jalr	-1370(ra) # 80003c5a <iunlock>
      return ip;
    800041bc:	bfe9                	j	80004196 <namex+0x6a>
      iunlockput(ip);
    800041be:	854e                	mv	a0,s3
    800041c0:	00000097          	auipc	ra,0x0
    800041c4:	c3a080e7          	jalr	-966(ra) # 80003dfa <iunlockput>
      return 0;
    800041c8:	89d2                	mv	s3,s4
    800041ca:	b7f1                	j	80004196 <namex+0x6a>
  len = path - s;
    800041cc:	40b48633          	sub	a2,s1,a1
    800041d0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041d4:	094cd463          	bge	s9,s4,8000425c <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041d8:	4639                	li	a2,14
    800041da:	8556                	mv	a0,s5
    800041dc:	ffffd097          	auipc	ra,0xffffd
    800041e0:	b64080e7          	jalr	-1180(ra) # 80000d40 <memmove>
  while(*path == '/')
    800041e4:	0004c783          	lbu	a5,0(s1)
    800041e8:	01279763          	bne	a5,s2,800041f6 <namex+0xca>
    path++;
    800041ec:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041ee:	0004c783          	lbu	a5,0(s1)
    800041f2:	ff278de3          	beq	a5,s2,800041ec <namex+0xc0>
    ilock(ip);
    800041f6:	854e                	mv	a0,s3
    800041f8:	00000097          	auipc	ra,0x0
    800041fc:	9a0080e7          	jalr	-1632(ra) # 80003b98 <ilock>
    if(ip->type != T_DIR){
    80004200:	04499783          	lh	a5,68(s3)
    80004204:	f98793e3          	bne	a5,s8,8000418a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004208:	000b0563          	beqz	s6,80004212 <namex+0xe6>
    8000420c:	0004c783          	lbu	a5,0(s1)
    80004210:	d3cd                	beqz	a5,800041b2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004212:	865e                	mv	a2,s7
    80004214:	85d6                	mv	a1,s5
    80004216:	854e                	mv	a0,s3
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	e64080e7          	jalr	-412(ra) # 8000407c <dirlookup>
    80004220:	8a2a                	mv	s4,a0
    80004222:	dd51                	beqz	a0,800041be <namex+0x92>
    iunlockput(ip);
    80004224:	854e                	mv	a0,s3
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	bd4080e7          	jalr	-1068(ra) # 80003dfa <iunlockput>
    ip = next;
    8000422e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004230:	0004c783          	lbu	a5,0(s1)
    80004234:	05279763          	bne	a5,s2,80004282 <namex+0x156>
    path++;
    80004238:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000423a:	0004c783          	lbu	a5,0(s1)
    8000423e:	ff278de3          	beq	a5,s2,80004238 <namex+0x10c>
  if(*path == 0)
    80004242:	c79d                	beqz	a5,80004270 <namex+0x144>
    path++;
    80004244:	85a6                	mv	a1,s1
  len = path - s;
    80004246:	8a5e                	mv	s4,s7
    80004248:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000424a:	01278963          	beq	a5,s2,8000425c <namex+0x130>
    8000424e:	dfbd                	beqz	a5,800041cc <namex+0xa0>
    path++;
    80004250:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004252:	0004c783          	lbu	a5,0(s1)
    80004256:	ff279ce3          	bne	a5,s2,8000424e <namex+0x122>
    8000425a:	bf8d                	j	800041cc <namex+0xa0>
    memmove(name, s, len);
    8000425c:	2601                	sext.w	a2,a2
    8000425e:	8556                	mv	a0,s5
    80004260:	ffffd097          	auipc	ra,0xffffd
    80004264:	ae0080e7          	jalr	-1312(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004268:	9a56                	add	s4,s4,s5
    8000426a:	000a0023          	sb	zero,0(s4)
    8000426e:	bf9d                	j	800041e4 <namex+0xb8>
  if(nameiparent){
    80004270:	f20b03e3          	beqz	s6,80004196 <namex+0x6a>
    iput(ip);
    80004274:	854e                	mv	a0,s3
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	adc080e7          	jalr	-1316(ra) # 80003d52 <iput>
    return 0;
    8000427e:	4981                	li	s3,0
    80004280:	bf19                	j	80004196 <namex+0x6a>
  if(*path == 0)
    80004282:	d7fd                	beqz	a5,80004270 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004284:	0004c783          	lbu	a5,0(s1)
    80004288:	85a6                	mv	a1,s1
    8000428a:	b7d1                	j	8000424e <namex+0x122>

000000008000428c <dirlink>:
{
    8000428c:	7139                	addi	sp,sp,-64
    8000428e:	fc06                	sd	ra,56(sp)
    80004290:	f822                	sd	s0,48(sp)
    80004292:	f426                	sd	s1,40(sp)
    80004294:	f04a                	sd	s2,32(sp)
    80004296:	ec4e                	sd	s3,24(sp)
    80004298:	e852                	sd	s4,16(sp)
    8000429a:	0080                	addi	s0,sp,64
    8000429c:	892a                	mv	s2,a0
    8000429e:	8a2e                	mv	s4,a1
    800042a0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042a2:	4601                	li	a2,0
    800042a4:	00000097          	auipc	ra,0x0
    800042a8:	dd8080e7          	jalr	-552(ra) # 8000407c <dirlookup>
    800042ac:	e93d                	bnez	a0,80004322 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ae:	04c92483          	lw	s1,76(s2)
    800042b2:	c49d                	beqz	s1,800042e0 <dirlink+0x54>
    800042b4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042b6:	4741                	li	a4,16
    800042b8:	86a6                	mv	a3,s1
    800042ba:	fc040613          	addi	a2,s0,-64
    800042be:	4581                	li	a1,0
    800042c0:	854a                	mv	a0,s2
    800042c2:	00000097          	auipc	ra,0x0
    800042c6:	b8a080e7          	jalr	-1142(ra) # 80003e4c <readi>
    800042ca:	47c1                	li	a5,16
    800042cc:	06f51163          	bne	a0,a5,8000432e <dirlink+0xa2>
    if(de.inum == 0)
    800042d0:	fc045783          	lhu	a5,-64(s0)
    800042d4:	c791                	beqz	a5,800042e0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042d6:	24c1                	addiw	s1,s1,16
    800042d8:	04c92783          	lw	a5,76(s2)
    800042dc:	fcf4ede3          	bltu	s1,a5,800042b6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042e0:	4639                	li	a2,14
    800042e2:	85d2                	mv	a1,s4
    800042e4:	fc240513          	addi	a0,s0,-62
    800042e8:	ffffd097          	auipc	ra,0xffffd
    800042ec:	b0c080e7          	jalr	-1268(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800042f0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042f4:	4741                	li	a4,16
    800042f6:	86a6                	mv	a3,s1
    800042f8:	fc040613          	addi	a2,s0,-64
    800042fc:	4581                	li	a1,0
    800042fe:	854a                	mv	a0,s2
    80004300:	00000097          	auipc	ra,0x0
    80004304:	c44080e7          	jalr	-956(ra) # 80003f44 <writei>
    80004308:	872a                	mv	a4,a0
    8000430a:	47c1                	li	a5,16
  return 0;
    8000430c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000430e:	02f71863          	bne	a4,a5,8000433e <dirlink+0xb2>
}
    80004312:	70e2                	ld	ra,56(sp)
    80004314:	7442                	ld	s0,48(sp)
    80004316:	74a2                	ld	s1,40(sp)
    80004318:	7902                	ld	s2,32(sp)
    8000431a:	69e2                	ld	s3,24(sp)
    8000431c:	6a42                	ld	s4,16(sp)
    8000431e:	6121                	addi	sp,sp,64
    80004320:	8082                	ret
    iput(ip);
    80004322:	00000097          	auipc	ra,0x0
    80004326:	a30080e7          	jalr	-1488(ra) # 80003d52 <iput>
    return -1;
    8000432a:	557d                	li	a0,-1
    8000432c:	b7dd                	j	80004312 <dirlink+0x86>
      panic("dirlink read");
    8000432e:	00004517          	auipc	a0,0x4
    80004332:	4a250513          	addi	a0,a0,1186 # 800087d0 <syscalls+0x1e0>
    80004336:	ffffc097          	auipc	ra,0xffffc
    8000433a:	208080e7          	jalr	520(ra) # 8000053e <panic>
    panic("dirlink");
    8000433e:	00004517          	auipc	a0,0x4
    80004342:	59a50513          	addi	a0,a0,1434 # 800088d8 <syscalls+0x2e8>
    80004346:	ffffc097          	auipc	ra,0xffffc
    8000434a:	1f8080e7          	jalr	504(ra) # 8000053e <panic>

000000008000434e <namei>:

struct inode*
namei(char *path)
{
    8000434e:	1101                	addi	sp,sp,-32
    80004350:	ec06                	sd	ra,24(sp)
    80004352:	e822                	sd	s0,16(sp)
    80004354:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004356:	fe040613          	addi	a2,s0,-32
    8000435a:	4581                	li	a1,0
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	dd0080e7          	jalr	-560(ra) # 8000412c <namex>
}
    80004364:	60e2                	ld	ra,24(sp)
    80004366:	6442                	ld	s0,16(sp)
    80004368:	6105                	addi	sp,sp,32
    8000436a:	8082                	ret

000000008000436c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000436c:	1141                	addi	sp,sp,-16
    8000436e:	e406                	sd	ra,8(sp)
    80004370:	e022                	sd	s0,0(sp)
    80004372:	0800                	addi	s0,sp,16
    80004374:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004376:	4585                	li	a1,1
    80004378:	00000097          	auipc	ra,0x0
    8000437c:	db4080e7          	jalr	-588(ra) # 8000412c <namex>
}
    80004380:	60a2                	ld	ra,8(sp)
    80004382:	6402                	ld	s0,0(sp)
    80004384:	0141                	addi	sp,sp,16
    80004386:	8082                	ret

0000000080004388 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004388:	1101                	addi	sp,sp,-32
    8000438a:	ec06                	sd	ra,24(sp)
    8000438c:	e822                	sd	s0,16(sp)
    8000438e:	e426                	sd	s1,8(sp)
    80004390:	e04a                	sd	s2,0(sp)
    80004392:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004394:	0001e917          	auipc	s2,0x1e
    80004398:	adc90913          	addi	s2,s2,-1316 # 80021e70 <log>
    8000439c:	01892583          	lw	a1,24(s2)
    800043a0:	02892503          	lw	a0,40(s2)
    800043a4:	fffff097          	auipc	ra,0xfffff
    800043a8:	ff2080e7          	jalr	-14(ra) # 80003396 <bread>
    800043ac:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043ae:	02c92683          	lw	a3,44(s2)
    800043b2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043b4:	02d05763          	blez	a3,800043e2 <write_head+0x5a>
    800043b8:	0001e797          	auipc	a5,0x1e
    800043bc:	ae878793          	addi	a5,a5,-1304 # 80021ea0 <log+0x30>
    800043c0:	05c50713          	addi	a4,a0,92
    800043c4:	36fd                	addiw	a3,a3,-1
    800043c6:	1682                	slli	a3,a3,0x20
    800043c8:	9281                	srli	a3,a3,0x20
    800043ca:	068a                	slli	a3,a3,0x2
    800043cc:	0001e617          	auipc	a2,0x1e
    800043d0:	ad860613          	addi	a2,a2,-1320 # 80021ea4 <log+0x34>
    800043d4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043d6:	4390                	lw	a2,0(a5)
    800043d8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043da:	0791                	addi	a5,a5,4
    800043dc:	0711                	addi	a4,a4,4
    800043de:	fed79ce3          	bne	a5,a3,800043d6 <write_head+0x4e>
  }
  bwrite(buf);
    800043e2:	8526                	mv	a0,s1
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	0a4080e7          	jalr	164(ra) # 80003488 <bwrite>
  brelse(buf);
    800043ec:	8526                	mv	a0,s1
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	0d8080e7          	jalr	216(ra) # 800034c6 <brelse>
}
    800043f6:	60e2                	ld	ra,24(sp)
    800043f8:	6442                	ld	s0,16(sp)
    800043fa:	64a2                	ld	s1,8(sp)
    800043fc:	6902                	ld	s2,0(sp)
    800043fe:	6105                	addi	sp,sp,32
    80004400:	8082                	ret

0000000080004402 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004402:	0001e797          	auipc	a5,0x1e
    80004406:	a9a7a783          	lw	a5,-1382(a5) # 80021e9c <log+0x2c>
    8000440a:	0af05d63          	blez	a5,800044c4 <install_trans+0xc2>
{
    8000440e:	7139                	addi	sp,sp,-64
    80004410:	fc06                	sd	ra,56(sp)
    80004412:	f822                	sd	s0,48(sp)
    80004414:	f426                	sd	s1,40(sp)
    80004416:	f04a                	sd	s2,32(sp)
    80004418:	ec4e                	sd	s3,24(sp)
    8000441a:	e852                	sd	s4,16(sp)
    8000441c:	e456                	sd	s5,8(sp)
    8000441e:	e05a                	sd	s6,0(sp)
    80004420:	0080                	addi	s0,sp,64
    80004422:	8b2a                	mv	s6,a0
    80004424:	0001ea97          	auipc	s5,0x1e
    80004428:	a7ca8a93          	addi	s5,s5,-1412 # 80021ea0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000442c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000442e:	0001e997          	auipc	s3,0x1e
    80004432:	a4298993          	addi	s3,s3,-1470 # 80021e70 <log>
    80004436:	a035                	j	80004462 <install_trans+0x60>
      bunpin(dbuf);
    80004438:	8526                	mv	a0,s1
    8000443a:	fffff097          	auipc	ra,0xfffff
    8000443e:	166080e7          	jalr	358(ra) # 800035a0 <bunpin>
    brelse(lbuf);
    80004442:	854a                	mv	a0,s2
    80004444:	fffff097          	auipc	ra,0xfffff
    80004448:	082080e7          	jalr	130(ra) # 800034c6 <brelse>
    brelse(dbuf);
    8000444c:	8526                	mv	a0,s1
    8000444e:	fffff097          	auipc	ra,0xfffff
    80004452:	078080e7          	jalr	120(ra) # 800034c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004456:	2a05                	addiw	s4,s4,1
    80004458:	0a91                	addi	s5,s5,4
    8000445a:	02c9a783          	lw	a5,44(s3)
    8000445e:	04fa5963          	bge	s4,a5,800044b0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004462:	0189a583          	lw	a1,24(s3)
    80004466:	014585bb          	addw	a1,a1,s4
    8000446a:	2585                	addiw	a1,a1,1
    8000446c:	0289a503          	lw	a0,40(s3)
    80004470:	fffff097          	auipc	ra,0xfffff
    80004474:	f26080e7          	jalr	-218(ra) # 80003396 <bread>
    80004478:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000447a:	000aa583          	lw	a1,0(s5)
    8000447e:	0289a503          	lw	a0,40(s3)
    80004482:	fffff097          	auipc	ra,0xfffff
    80004486:	f14080e7          	jalr	-236(ra) # 80003396 <bread>
    8000448a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000448c:	40000613          	li	a2,1024
    80004490:	05890593          	addi	a1,s2,88
    80004494:	05850513          	addi	a0,a0,88
    80004498:	ffffd097          	auipc	ra,0xffffd
    8000449c:	8a8080e7          	jalr	-1880(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800044a0:	8526                	mv	a0,s1
    800044a2:	fffff097          	auipc	ra,0xfffff
    800044a6:	fe6080e7          	jalr	-26(ra) # 80003488 <bwrite>
    if(recovering == 0)
    800044aa:	f80b1ce3          	bnez	s6,80004442 <install_trans+0x40>
    800044ae:	b769                	j	80004438 <install_trans+0x36>
}
    800044b0:	70e2                	ld	ra,56(sp)
    800044b2:	7442                	ld	s0,48(sp)
    800044b4:	74a2                	ld	s1,40(sp)
    800044b6:	7902                	ld	s2,32(sp)
    800044b8:	69e2                	ld	s3,24(sp)
    800044ba:	6a42                	ld	s4,16(sp)
    800044bc:	6aa2                	ld	s5,8(sp)
    800044be:	6b02                	ld	s6,0(sp)
    800044c0:	6121                	addi	sp,sp,64
    800044c2:	8082                	ret
    800044c4:	8082                	ret

00000000800044c6 <initlog>:
{
    800044c6:	7179                	addi	sp,sp,-48
    800044c8:	f406                	sd	ra,40(sp)
    800044ca:	f022                	sd	s0,32(sp)
    800044cc:	ec26                	sd	s1,24(sp)
    800044ce:	e84a                	sd	s2,16(sp)
    800044d0:	e44e                	sd	s3,8(sp)
    800044d2:	1800                	addi	s0,sp,48
    800044d4:	892a                	mv	s2,a0
    800044d6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044d8:	0001e497          	auipc	s1,0x1e
    800044dc:	99848493          	addi	s1,s1,-1640 # 80021e70 <log>
    800044e0:	00004597          	auipc	a1,0x4
    800044e4:	30058593          	addi	a1,a1,768 # 800087e0 <syscalls+0x1f0>
    800044e8:	8526                	mv	a0,s1
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	66a080e7          	jalr	1642(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800044f2:	0149a583          	lw	a1,20(s3)
    800044f6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044f8:	0109a783          	lw	a5,16(s3)
    800044fc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044fe:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004502:	854a                	mv	a0,s2
    80004504:	fffff097          	auipc	ra,0xfffff
    80004508:	e92080e7          	jalr	-366(ra) # 80003396 <bread>
  log.lh.n = lh->n;
    8000450c:	4d3c                	lw	a5,88(a0)
    8000450e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004510:	02f05563          	blez	a5,8000453a <initlog+0x74>
    80004514:	05c50713          	addi	a4,a0,92
    80004518:	0001e697          	auipc	a3,0x1e
    8000451c:	98868693          	addi	a3,a3,-1656 # 80021ea0 <log+0x30>
    80004520:	37fd                	addiw	a5,a5,-1
    80004522:	1782                	slli	a5,a5,0x20
    80004524:	9381                	srli	a5,a5,0x20
    80004526:	078a                	slli	a5,a5,0x2
    80004528:	06050613          	addi	a2,a0,96
    8000452c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000452e:	4310                	lw	a2,0(a4)
    80004530:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004532:	0711                	addi	a4,a4,4
    80004534:	0691                	addi	a3,a3,4
    80004536:	fef71ce3          	bne	a4,a5,8000452e <initlog+0x68>
  brelse(buf);
    8000453a:	fffff097          	auipc	ra,0xfffff
    8000453e:	f8c080e7          	jalr	-116(ra) # 800034c6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004542:	4505                	li	a0,1
    80004544:	00000097          	auipc	ra,0x0
    80004548:	ebe080e7          	jalr	-322(ra) # 80004402 <install_trans>
  log.lh.n = 0;
    8000454c:	0001e797          	auipc	a5,0x1e
    80004550:	9407a823          	sw	zero,-1712(a5) # 80021e9c <log+0x2c>
  write_head(); // clear the log
    80004554:	00000097          	auipc	ra,0x0
    80004558:	e34080e7          	jalr	-460(ra) # 80004388 <write_head>
}
    8000455c:	70a2                	ld	ra,40(sp)
    8000455e:	7402                	ld	s0,32(sp)
    80004560:	64e2                	ld	s1,24(sp)
    80004562:	6942                	ld	s2,16(sp)
    80004564:	69a2                	ld	s3,8(sp)
    80004566:	6145                	addi	sp,sp,48
    80004568:	8082                	ret

000000008000456a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000456a:	1101                	addi	sp,sp,-32
    8000456c:	ec06                	sd	ra,24(sp)
    8000456e:	e822                	sd	s0,16(sp)
    80004570:	e426                	sd	s1,8(sp)
    80004572:	e04a                	sd	s2,0(sp)
    80004574:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004576:	0001e517          	auipc	a0,0x1e
    8000457a:	8fa50513          	addi	a0,a0,-1798 # 80021e70 <log>
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	666080e7          	jalr	1638(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004586:	0001e497          	auipc	s1,0x1e
    8000458a:	8ea48493          	addi	s1,s1,-1814 # 80021e70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000458e:	4979                	li	s2,30
    80004590:	a039                	j	8000459e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004592:	85a6                	mv	a1,s1
    80004594:	8526                	mv	a0,s1
    80004596:	ffffe097          	auipc	ra,0xffffe
    8000459a:	c6e080e7          	jalr	-914(ra) # 80002204 <sleep>
    if(log.committing){
    8000459e:	50dc                	lw	a5,36(s1)
    800045a0:	fbed                	bnez	a5,80004592 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045a2:	509c                	lw	a5,32(s1)
    800045a4:	0017871b          	addiw	a4,a5,1
    800045a8:	0007069b          	sext.w	a3,a4
    800045ac:	0027179b          	slliw	a5,a4,0x2
    800045b0:	9fb9                	addw	a5,a5,a4
    800045b2:	0017979b          	slliw	a5,a5,0x1
    800045b6:	54d8                	lw	a4,44(s1)
    800045b8:	9fb9                	addw	a5,a5,a4
    800045ba:	00f95963          	bge	s2,a5,800045cc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045be:	85a6                	mv	a1,s1
    800045c0:	8526                	mv	a0,s1
    800045c2:	ffffe097          	auipc	ra,0xffffe
    800045c6:	c42080e7          	jalr	-958(ra) # 80002204 <sleep>
    800045ca:	bfd1                	j	8000459e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045cc:	0001e517          	auipc	a0,0x1e
    800045d0:	8a450513          	addi	a0,a0,-1884 # 80021e70 <log>
    800045d4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6c2080e7          	jalr	1730(ra) # 80000c98 <release>
      break;
    }
  }
}
    800045de:	60e2                	ld	ra,24(sp)
    800045e0:	6442                	ld	s0,16(sp)
    800045e2:	64a2                	ld	s1,8(sp)
    800045e4:	6902                	ld	s2,0(sp)
    800045e6:	6105                	addi	sp,sp,32
    800045e8:	8082                	ret

00000000800045ea <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045ea:	7139                	addi	sp,sp,-64
    800045ec:	fc06                	sd	ra,56(sp)
    800045ee:	f822                	sd	s0,48(sp)
    800045f0:	f426                	sd	s1,40(sp)
    800045f2:	f04a                	sd	s2,32(sp)
    800045f4:	ec4e                	sd	s3,24(sp)
    800045f6:	e852                	sd	s4,16(sp)
    800045f8:	e456                	sd	s5,8(sp)
    800045fa:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045fc:	0001e497          	auipc	s1,0x1e
    80004600:	87448493          	addi	s1,s1,-1932 # 80021e70 <log>
    80004604:	8526                	mv	a0,s1
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	5de080e7          	jalr	1502(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000460e:	509c                	lw	a5,32(s1)
    80004610:	37fd                	addiw	a5,a5,-1
    80004612:	0007891b          	sext.w	s2,a5
    80004616:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004618:	50dc                	lw	a5,36(s1)
    8000461a:	efb9                	bnez	a5,80004678 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000461c:	06091663          	bnez	s2,80004688 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004620:	0001e497          	auipc	s1,0x1e
    80004624:	85048493          	addi	s1,s1,-1968 # 80021e70 <log>
    80004628:	4785                	li	a5,1
    8000462a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000462c:	8526                	mv	a0,s1
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	66a080e7          	jalr	1642(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004636:	54dc                	lw	a5,44(s1)
    80004638:	06f04763          	bgtz	a5,800046a6 <end_op+0xbc>
    acquire(&log.lock);
    8000463c:	0001e497          	auipc	s1,0x1e
    80004640:	83448493          	addi	s1,s1,-1996 # 80021e70 <log>
    80004644:	8526                	mv	a0,s1
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	59e080e7          	jalr	1438(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000464e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004652:	8526                	mv	a0,s1
    80004654:	ffffe097          	auipc	ra,0xffffe
    80004658:	e88080e7          	jalr	-376(ra) # 800024dc <wakeup>
    release(&log.lock);
    8000465c:	8526                	mv	a0,s1
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	63a080e7          	jalr	1594(ra) # 80000c98 <release>
}
    80004666:	70e2                	ld	ra,56(sp)
    80004668:	7442                	ld	s0,48(sp)
    8000466a:	74a2                	ld	s1,40(sp)
    8000466c:	7902                	ld	s2,32(sp)
    8000466e:	69e2                	ld	s3,24(sp)
    80004670:	6a42                	ld	s4,16(sp)
    80004672:	6aa2                	ld	s5,8(sp)
    80004674:	6121                	addi	sp,sp,64
    80004676:	8082                	ret
    panic("log.committing");
    80004678:	00004517          	auipc	a0,0x4
    8000467c:	17050513          	addi	a0,a0,368 # 800087e8 <syscalls+0x1f8>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	ebe080e7          	jalr	-322(ra) # 8000053e <panic>
    wakeup(&log);
    80004688:	0001d497          	auipc	s1,0x1d
    8000468c:	7e848493          	addi	s1,s1,2024 # 80021e70 <log>
    80004690:	8526                	mv	a0,s1
    80004692:	ffffe097          	auipc	ra,0xffffe
    80004696:	e4a080e7          	jalr	-438(ra) # 800024dc <wakeup>
  release(&log.lock);
    8000469a:	8526                	mv	a0,s1
    8000469c:	ffffc097          	auipc	ra,0xffffc
    800046a0:	5fc080e7          	jalr	1532(ra) # 80000c98 <release>
  if(do_commit){
    800046a4:	b7c9                	j	80004666 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046a6:	0001da97          	auipc	s5,0x1d
    800046aa:	7faa8a93          	addi	s5,s5,2042 # 80021ea0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046ae:	0001da17          	auipc	s4,0x1d
    800046b2:	7c2a0a13          	addi	s4,s4,1986 # 80021e70 <log>
    800046b6:	018a2583          	lw	a1,24(s4)
    800046ba:	012585bb          	addw	a1,a1,s2
    800046be:	2585                	addiw	a1,a1,1
    800046c0:	028a2503          	lw	a0,40(s4)
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	cd2080e7          	jalr	-814(ra) # 80003396 <bread>
    800046cc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046ce:	000aa583          	lw	a1,0(s5)
    800046d2:	028a2503          	lw	a0,40(s4)
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	cc0080e7          	jalr	-832(ra) # 80003396 <bread>
    800046de:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046e0:	40000613          	li	a2,1024
    800046e4:	05850593          	addi	a1,a0,88
    800046e8:	05848513          	addi	a0,s1,88
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	654080e7          	jalr	1620(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800046f4:	8526                	mv	a0,s1
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	d92080e7          	jalr	-622(ra) # 80003488 <bwrite>
    brelse(from);
    800046fe:	854e                	mv	a0,s3
    80004700:	fffff097          	auipc	ra,0xfffff
    80004704:	dc6080e7          	jalr	-570(ra) # 800034c6 <brelse>
    brelse(to);
    80004708:	8526                	mv	a0,s1
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	dbc080e7          	jalr	-580(ra) # 800034c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004712:	2905                	addiw	s2,s2,1
    80004714:	0a91                	addi	s5,s5,4
    80004716:	02ca2783          	lw	a5,44(s4)
    8000471a:	f8f94ee3          	blt	s2,a5,800046b6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000471e:	00000097          	auipc	ra,0x0
    80004722:	c6a080e7          	jalr	-918(ra) # 80004388 <write_head>
    install_trans(0); // Now install writes to home locations
    80004726:	4501                	li	a0,0
    80004728:	00000097          	auipc	ra,0x0
    8000472c:	cda080e7          	jalr	-806(ra) # 80004402 <install_trans>
    log.lh.n = 0;
    80004730:	0001d797          	auipc	a5,0x1d
    80004734:	7607a623          	sw	zero,1900(a5) # 80021e9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004738:	00000097          	auipc	ra,0x0
    8000473c:	c50080e7          	jalr	-944(ra) # 80004388 <write_head>
    80004740:	bdf5                	j	8000463c <end_op+0x52>

0000000080004742 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004742:	1101                	addi	sp,sp,-32
    80004744:	ec06                	sd	ra,24(sp)
    80004746:	e822                	sd	s0,16(sp)
    80004748:	e426                	sd	s1,8(sp)
    8000474a:	e04a                	sd	s2,0(sp)
    8000474c:	1000                	addi	s0,sp,32
    8000474e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004750:	0001d917          	auipc	s2,0x1d
    80004754:	72090913          	addi	s2,s2,1824 # 80021e70 <log>
    80004758:	854a                	mv	a0,s2
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	48a080e7          	jalr	1162(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004762:	02c92603          	lw	a2,44(s2)
    80004766:	47f5                	li	a5,29
    80004768:	06c7c563          	blt	a5,a2,800047d2 <log_write+0x90>
    8000476c:	0001d797          	auipc	a5,0x1d
    80004770:	7207a783          	lw	a5,1824(a5) # 80021e8c <log+0x1c>
    80004774:	37fd                	addiw	a5,a5,-1
    80004776:	04f65e63          	bge	a2,a5,800047d2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000477a:	0001d797          	auipc	a5,0x1d
    8000477e:	7167a783          	lw	a5,1814(a5) # 80021e90 <log+0x20>
    80004782:	06f05063          	blez	a5,800047e2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004786:	4781                	li	a5,0
    80004788:	06c05563          	blez	a2,800047f2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000478c:	44cc                	lw	a1,12(s1)
    8000478e:	0001d717          	auipc	a4,0x1d
    80004792:	71270713          	addi	a4,a4,1810 # 80021ea0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004796:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004798:	4314                	lw	a3,0(a4)
    8000479a:	04b68c63          	beq	a3,a1,800047f2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000479e:	2785                	addiw	a5,a5,1
    800047a0:	0711                	addi	a4,a4,4
    800047a2:	fef61be3          	bne	a2,a5,80004798 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047a6:	0621                	addi	a2,a2,8
    800047a8:	060a                	slli	a2,a2,0x2
    800047aa:	0001d797          	auipc	a5,0x1d
    800047ae:	6c678793          	addi	a5,a5,1734 # 80021e70 <log>
    800047b2:	963e                	add	a2,a2,a5
    800047b4:	44dc                	lw	a5,12(s1)
    800047b6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047b8:	8526                	mv	a0,s1
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	daa080e7          	jalr	-598(ra) # 80003564 <bpin>
    log.lh.n++;
    800047c2:	0001d717          	auipc	a4,0x1d
    800047c6:	6ae70713          	addi	a4,a4,1710 # 80021e70 <log>
    800047ca:	575c                	lw	a5,44(a4)
    800047cc:	2785                	addiw	a5,a5,1
    800047ce:	d75c                	sw	a5,44(a4)
    800047d0:	a835                	j	8000480c <log_write+0xca>
    panic("too big a transaction");
    800047d2:	00004517          	auipc	a0,0x4
    800047d6:	02650513          	addi	a0,a0,38 # 800087f8 <syscalls+0x208>
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	d64080e7          	jalr	-668(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800047e2:	00004517          	auipc	a0,0x4
    800047e6:	02e50513          	addi	a0,a0,46 # 80008810 <syscalls+0x220>
    800047ea:	ffffc097          	auipc	ra,0xffffc
    800047ee:	d54080e7          	jalr	-684(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047f2:	00878713          	addi	a4,a5,8
    800047f6:	00271693          	slli	a3,a4,0x2
    800047fa:	0001d717          	auipc	a4,0x1d
    800047fe:	67670713          	addi	a4,a4,1654 # 80021e70 <log>
    80004802:	9736                	add	a4,a4,a3
    80004804:	44d4                	lw	a3,12(s1)
    80004806:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004808:	faf608e3          	beq	a2,a5,800047b8 <log_write+0x76>
  }
  release(&log.lock);
    8000480c:	0001d517          	auipc	a0,0x1d
    80004810:	66450513          	addi	a0,a0,1636 # 80021e70 <log>
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	484080e7          	jalr	1156(ra) # 80000c98 <release>
}
    8000481c:	60e2                	ld	ra,24(sp)
    8000481e:	6442                	ld	s0,16(sp)
    80004820:	64a2                	ld	s1,8(sp)
    80004822:	6902                	ld	s2,0(sp)
    80004824:	6105                	addi	sp,sp,32
    80004826:	8082                	ret

0000000080004828 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004828:	1101                	addi	sp,sp,-32
    8000482a:	ec06                	sd	ra,24(sp)
    8000482c:	e822                	sd	s0,16(sp)
    8000482e:	e426                	sd	s1,8(sp)
    80004830:	e04a                	sd	s2,0(sp)
    80004832:	1000                	addi	s0,sp,32
    80004834:	84aa                	mv	s1,a0
    80004836:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004838:	00004597          	auipc	a1,0x4
    8000483c:	ff858593          	addi	a1,a1,-8 # 80008830 <syscalls+0x240>
    80004840:	0521                	addi	a0,a0,8
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	312080e7          	jalr	786(ra) # 80000b54 <initlock>
  lk->name = name;
    8000484a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000484e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004852:	0204a423          	sw	zero,40(s1)
}
    80004856:	60e2                	ld	ra,24(sp)
    80004858:	6442                	ld	s0,16(sp)
    8000485a:	64a2                	ld	s1,8(sp)
    8000485c:	6902                	ld	s2,0(sp)
    8000485e:	6105                	addi	sp,sp,32
    80004860:	8082                	ret

0000000080004862 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004862:	1101                	addi	sp,sp,-32
    80004864:	ec06                	sd	ra,24(sp)
    80004866:	e822                	sd	s0,16(sp)
    80004868:	e426                	sd	s1,8(sp)
    8000486a:	e04a                	sd	s2,0(sp)
    8000486c:	1000                	addi	s0,sp,32
    8000486e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004870:	00850913          	addi	s2,a0,8
    80004874:	854a                	mv	a0,s2
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	36e080e7          	jalr	878(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000487e:	409c                	lw	a5,0(s1)
    80004880:	cb89                	beqz	a5,80004892 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004882:	85ca                	mv	a1,s2
    80004884:	8526                	mv	a0,s1
    80004886:	ffffe097          	auipc	ra,0xffffe
    8000488a:	97e080e7          	jalr	-1666(ra) # 80002204 <sleep>
  while (lk->locked) {
    8000488e:	409c                	lw	a5,0(s1)
    80004890:	fbed                	bnez	a5,80004882 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004892:	4785                	li	a5,1
    80004894:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004896:	ffffd097          	auipc	ra,0xffffd
    8000489a:	196080e7          	jalr	406(ra) # 80001a2c <myproc>
    8000489e:	591c                	lw	a5,48(a0)
    800048a0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048a2:	854a                	mv	a0,s2
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	3f4080e7          	jalr	1012(ra) # 80000c98 <release>
}
    800048ac:	60e2                	ld	ra,24(sp)
    800048ae:	6442                	ld	s0,16(sp)
    800048b0:	64a2                	ld	s1,8(sp)
    800048b2:	6902                	ld	s2,0(sp)
    800048b4:	6105                	addi	sp,sp,32
    800048b6:	8082                	ret

00000000800048b8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048b8:	1101                	addi	sp,sp,-32
    800048ba:	ec06                	sd	ra,24(sp)
    800048bc:	e822                	sd	s0,16(sp)
    800048be:	e426                	sd	s1,8(sp)
    800048c0:	e04a                	sd	s2,0(sp)
    800048c2:	1000                	addi	s0,sp,32
    800048c4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048c6:	00850913          	addi	s2,a0,8
    800048ca:	854a                	mv	a0,s2
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	318080e7          	jalr	792(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800048d4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048d8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048dc:	8526                	mv	a0,s1
    800048de:	ffffe097          	auipc	ra,0xffffe
    800048e2:	bfe080e7          	jalr	-1026(ra) # 800024dc <wakeup>
  release(&lk->lk);
    800048e6:	854a                	mv	a0,s2
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	3b0080e7          	jalr	944(ra) # 80000c98 <release>
}
    800048f0:	60e2                	ld	ra,24(sp)
    800048f2:	6442                	ld	s0,16(sp)
    800048f4:	64a2                	ld	s1,8(sp)
    800048f6:	6902                	ld	s2,0(sp)
    800048f8:	6105                	addi	sp,sp,32
    800048fa:	8082                	ret

00000000800048fc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048fc:	7179                	addi	sp,sp,-48
    800048fe:	f406                	sd	ra,40(sp)
    80004900:	f022                	sd	s0,32(sp)
    80004902:	ec26                	sd	s1,24(sp)
    80004904:	e84a                	sd	s2,16(sp)
    80004906:	e44e                	sd	s3,8(sp)
    80004908:	1800                	addi	s0,sp,48
    8000490a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000490c:	00850913          	addi	s2,a0,8
    80004910:	854a                	mv	a0,s2
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	2d2080e7          	jalr	722(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000491a:	409c                	lw	a5,0(s1)
    8000491c:	ef99                	bnez	a5,8000493a <holdingsleep+0x3e>
    8000491e:	4481                	li	s1,0
  release(&lk->lk);
    80004920:	854a                	mv	a0,s2
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	376080e7          	jalr	886(ra) # 80000c98 <release>
  return r;
}
    8000492a:	8526                	mv	a0,s1
    8000492c:	70a2                	ld	ra,40(sp)
    8000492e:	7402                	ld	s0,32(sp)
    80004930:	64e2                	ld	s1,24(sp)
    80004932:	6942                	ld	s2,16(sp)
    80004934:	69a2                	ld	s3,8(sp)
    80004936:	6145                	addi	sp,sp,48
    80004938:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000493a:	0284a983          	lw	s3,40(s1)
    8000493e:	ffffd097          	auipc	ra,0xffffd
    80004942:	0ee080e7          	jalr	238(ra) # 80001a2c <myproc>
    80004946:	5904                	lw	s1,48(a0)
    80004948:	413484b3          	sub	s1,s1,s3
    8000494c:	0014b493          	seqz	s1,s1
    80004950:	bfc1                	j	80004920 <holdingsleep+0x24>

0000000080004952 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004952:	1141                	addi	sp,sp,-16
    80004954:	e406                	sd	ra,8(sp)
    80004956:	e022                	sd	s0,0(sp)
    80004958:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000495a:	00004597          	auipc	a1,0x4
    8000495e:	ee658593          	addi	a1,a1,-282 # 80008840 <syscalls+0x250>
    80004962:	0001d517          	auipc	a0,0x1d
    80004966:	65650513          	addi	a0,a0,1622 # 80021fb8 <ftable>
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	1ea080e7          	jalr	490(ra) # 80000b54 <initlock>
}
    80004972:	60a2                	ld	ra,8(sp)
    80004974:	6402                	ld	s0,0(sp)
    80004976:	0141                	addi	sp,sp,16
    80004978:	8082                	ret

000000008000497a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000497a:	1101                	addi	sp,sp,-32
    8000497c:	ec06                	sd	ra,24(sp)
    8000497e:	e822                	sd	s0,16(sp)
    80004980:	e426                	sd	s1,8(sp)
    80004982:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004984:	0001d517          	auipc	a0,0x1d
    80004988:	63450513          	addi	a0,a0,1588 # 80021fb8 <ftable>
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	258080e7          	jalr	600(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004994:	0001d497          	auipc	s1,0x1d
    80004998:	63c48493          	addi	s1,s1,1596 # 80021fd0 <ftable+0x18>
    8000499c:	0001e717          	auipc	a4,0x1e
    800049a0:	5d470713          	addi	a4,a4,1492 # 80022f70 <ftable+0xfb8>
    if(f->ref == 0){
    800049a4:	40dc                	lw	a5,4(s1)
    800049a6:	cf99                	beqz	a5,800049c4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049a8:	02848493          	addi	s1,s1,40
    800049ac:	fee49ce3          	bne	s1,a4,800049a4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049b0:	0001d517          	auipc	a0,0x1d
    800049b4:	60850513          	addi	a0,a0,1544 # 80021fb8 <ftable>
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	2e0080e7          	jalr	736(ra) # 80000c98 <release>
  return 0;
    800049c0:	4481                	li	s1,0
    800049c2:	a819                	j	800049d8 <filealloc+0x5e>
      f->ref = 1;
    800049c4:	4785                	li	a5,1
    800049c6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049c8:	0001d517          	auipc	a0,0x1d
    800049cc:	5f050513          	addi	a0,a0,1520 # 80021fb8 <ftable>
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	2c8080e7          	jalr	712(ra) # 80000c98 <release>
}
    800049d8:	8526                	mv	a0,s1
    800049da:	60e2                	ld	ra,24(sp)
    800049dc:	6442                	ld	s0,16(sp)
    800049de:	64a2                	ld	s1,8(sp)
    800049e0:	6105                	addi	sp,sp,32
    800049e2:	8082                	ret

00000000800049e4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049e4:	1101                	addi	sp,sp,-32
    800049e6:	ec06                	sd	ra,24(sp)
    800049e8:	e822                	sd	s0,16(sp)
    800049ea:	e426                	sd	s1,8(sp)
    800049ec:	1000                	addi	s0,sp,32
    800049ee:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049f0:	0001d517          	auipc	a0,0x1d
    800049f4:	5c850513          	addi	a0,a0,1480 # 80021fb8 <ftable>
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	1ec080e7          	jalr	492(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a00:	40dc                	lw	a5,4(s1)
    80004a02:	02f05263          	blez	a5,80004a26 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a06:	2785                	addiw	a5,a5,1
    80004a08:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a0a:	0001d517          	auipc	a0,0x1d
    80004a0e:	5ae50513          	addi	a0,a0,1454 # 80021fb8 <ftable>
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	286080e7          	jalr	646(ra) # 80000c98 <release>
  return f;
}
    80004a1a:	8526                	mv	a0,s1
    80004a1c:	60e2                	ld	ra,24(sp)
    80004a1e:	6442                	ld	s0,16(sp)
    80004a20:	64a2                	ld	s1,8(sp)
    80004a22:	6105                	addi	sp,sp,32
    80004a24:	8082                	ret
    panic("filedup");
    80004a26:	00004517          	auipc	a0,0x4
    80004a2a:	e2250513          	addi	a0,a0,-478 # 80008848 <syscalls+0x258>
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	b10080e7          	jalr	-1264(ra) # 8000053e <panic>

0000000080004a36 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a36:	7139                	addi	sp,sp,-64
    80004a38:	fc06                	sd	ra,56(sp)
    80004a3a:	f822                	sd	s0,48(sp)
    80004a3c:	f426                	sd	s1,40(sp)
    80004a3e:	f04a                	sd	s2,32(sp)
    80004a40:	ec4e                	sd	s3,24(sp)
    80004a42:	e852                	sd	s4,16(sp)
    80004a44:	e456                	sd	s5,8(sp)
    80004a46:	0080                	addi	s0,sp,64
    80004a48:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a4a:	0001d517          	auipc	a0,0x1d
    80004a4e:	56e50513          	addi	a0,a0,1390 # 80021fb8 <ftable>
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	192080e7          	jalr	402(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a5a:	40dc                	lw	a5,4(s1)
    80004a5c:	06f05163          	blez	a5,80004abe <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a60:	37fd                	addiw	a5,a5,-1
    80004a62:	0007871b          	sext.w	a4,a5
    80004a66:	c0dc                	sw	a5,4(s1)
    80004a68:	06e04363          	bgtz	a4,80004ace <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a6c:	0004a903          	lw	s2,0(s1)
    80004a70:	0094ca83          	lbu	s5,9(s1)
    80004a74:	0104ba03          	ld	s4,16(s1)
    80004a78:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a7c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a80:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a84:	0001d517          	auipc	a0,0x1d
    80004a88:	53450513          	addi	a0,a0,1332 # 80021fb8 <ftable>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	20c080e7          	jalr	524(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a94:	4785                	li	a5,1
    80004a96:	04f90d63          	beq	s2,a5,80004af0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a9a:	3979                	addiw	s2,s2,-2
    80004a9c:	4785                	li	a5,1
    80004a9e:	0527e063          	bltu	a5,s2,80004ade <fileclose+0xa8>
    begin_op();
    80004aa2:	00000097          	auipc	ra,0x0
    80004aa6:	ac8080e7          	jalr	-1336(ra) # 8000456a <begin_op>
    iput(ff.ip);
    80004aaa:	854e                	mv	a0,s3
    80004aac:	fffff097          	auipc	ra,0xfffff
    80004ab0:	2a6080e7          	jalr	678(ra) # 80003d52 <iput>
    end_op();
    80004ab4:	00000097          	auipc	ra,0x0
    80004ab8:	b36080e7          	jalr	-1226(ra) # 800045ea <end_op>
    80004abc:	a00d                	j	80004ade <fileclose+0xa8>
    panic("fileclose");
    80004abe:	00004517          	auipc	a0,0x4
    80004ac2:	d9250513          	addi	a0,a0,-622 # 80008850 <syscalls+0x260>
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	a78080e7          	jalr	-1416(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004ace:	0001d517          	auipc	a0,0x1d
    80004ad2:	4ea50513          	addi	a0,a0,1258 # 80021fb8 <ftable>
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	1c2080e7          	jalr	450(ra) # 80000c98 <release>
  }
}
    80004ade:	70e2                	ld	ra,56(sp)
    80004ae0:	7442                	ld	s0,48(sp)
    80004ae2:	74a2                	ld	s1,40(sp)
    80004ae4:	7902                	ld	s2,32(sp)
    80004ae6:	69e2                	ld	s3,24(sp)
    80004ae8:	6a42                	ld	s4,16(sp)
    80004aea:	6aa2                	ld	s5,8(sp)
    80004aec:	6121                	addi	sp,sp,64
    80004aee:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004af0:	85d6                	mv	a1,s5
    80004af2:	8552                	mv	a0,s4
    80004af4:	00000097          	auipc	ra,0x0
    80004af8:	34c080e7          	jalr	844(ra) # 80004e40 <pipeclose>
    80004afc:	b7cd                	j	80004ade <fileclose+0xa8>

0000000080004afe <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004afe:	715d                	addi	sp,sp,-80
    80004b00:	e486                	sd	ra,72(sp)
    80004b02:	e0a2                	sd	s0,64(sp)
    80004b04:	fc26                	sd	s1,56(sp)
    80004b06:	f84a                	sd	s2,48(sp)
    80004b08:	f44e                	sd	s3,40(sp)
    80004b0a:	0880                	addi	s0,sp,80
    80004b0c:	84aa                	mv	s1,a0
    80004b0e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b10:	ffffd097          	auipc	ra,0xffffd
    80004b14:	f1c080e7          	jalr	-228(ra) # 80001a2c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b18:	409c                	lw	a5,0(s1)
    80004b1a:	37f9                	addiw	a5,a5,-2
    80004b1c:	4705                	li	a4,1
    80004b1e:	04f76763          	bltu	a4,a5,80004b6c <filestat+0x6e>
    80004b22:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b24:	6c88                	ld	a0,24(s1)
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	072080e7          	jalr	114(ra) # 80003b98 <ilock>
    stati(f->ip, &st);
    80004b2e:	fb840593          	addi	a1,s0,-72
    80004b32:	6c88                	ld	a0,24(s1)
    80004b34:	fffff097          	auipc	ra,0xfffff
    80004b38:	2ee080e7          	jalr	750(ra) # 80003e22 <stati>
    iunlock(f->ip);
    80004b3c:	6c88                	ld	a0,24(s1)
    80004b3e:	fffff097          	auipc	ra,0xfffff
    80004b42:	11c080e7          	jalr	284(ra) # 80003c5a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b46:	46e1                	li	a3,24
    80004b48:	fb840613          	addi	a2,s0,-72
    80004b4c:	85ce                	mv	a1,s3
    80004b4e:	05093503          	ld	a0,80(s2)
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	b20080e7          	jalr	-1248(ra) # 80001672 <copyout>
    80004b5a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b5e:	60a6                	ld	ra,72(sp)
    80004b60:	6406                	ld	s0,64(sp)
    80004b62:	74e2                	ld	s1,56(sp)
    80004b64:	7942                	ld	s2,48(sp)
    80004b66:	79a2                	ld	s3,40(sp)
    80004b68:	6161                	addi	sp,sp,80
    80004b6a:	8082                	ret
  return -1;
    80004b6c:	557d                	li	a0,-1
    80004b6e:	bfc5                	j	80004b5e <filestat+0x60>

0000000080004b70 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b70:	7179                	addi	sp,sp,-48
    80004b72:	f406                	sd	ra,40(sp)
    80004b74:	f022                	sd	s0,32(sp)
    80004b76:	ec26                	sd	s1,24(sp)
    80004b78:	e84a                	sd	s2,16(sp)
    80004b7a:	e44e                	sd	s3,8(sp)
    80004b7c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b7e:	00854783          	lbu	a5,8(a0)
    80004b82:	c3d5                	beqz	a5,80004c26 <fileread+0xb6>
    80004b84:	84aa                	mv	s1,a0
    80004b86:	89ae                	mv	s3,a1
    80004b88:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b8a:	411c                	lw	a5,0(a0)
    80004b8c:	4705                	li	a4,1
    80004b8e:	04e78963          	beq	a5,a4,80004be0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b92:	470d                	li	a4,3
    80004b94:	04e78d63          	beq	a5,a4,80004bee <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b98:	4709                	li	a4,2
    80004b9a:	06e79e63          	bne	a5,a4,80004c16 <fileread+0xa6>
    ilock(f->ip);
    80004b9e:	6d08                	ld	a0,24(a0)
    80004ba0:	fffff097          	auipc	ra,0xfffff
    80004ba4:	ff8080e7          	jalr	-8(ra) # 80003b98 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ba8:	874a                	mv	a4,s2
    80004baa:	5094                	lw	a3,32(s1)
    80004bac:	864e                	mv	a2,s3
    80004bae:	4585                	li	a1,1
    80004bb0:	6c88                	ld	a0,24(s1)
    80004bb2:	fffff097          	auipc	ra,0xfffff
    80004bb6:	29a080e7          	jalr	666(ra) # 80003e4c <readi>
    80004bba:	892a                	mv	s2,a0
    80004bbc:	00a05563          	blez	a0,80004bc6 <fileread+0x56>
      f->off += r;
    80004bc0:	509c                	lw	a5,32(s1)
    80004bc2:	9fa9                	addw	a5,a5,a0
    80004bc4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bc6:	6c88                	ld	a0,24(s1)
    80004bc8:	fffff097          	auipc	ra,0xfffff
    80004bcc:	092080e7          	jalr	146(ra) # 80003c5a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bd0:	854a                	mv	a0,s2
    80004bd2:	70a2                	ld	ra,40(sp)
    80004bd4:	7402                	ld	s0,32(sp)
    80004bd6:	64e2                	ld	s1,24(sp)
    80004bd8:	6942                	ld	s2,16(sp)
    80004bda:	69a2                	ld	s3,8(sp)
    80004bdc:	6145                	addi	sp,sp,48
    80004bde:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004be0:	6908                	ld	a0,16(a0)
    80004be2:	00000097          	auipc	ra,0x0
    80004be6:	3c8080e7          	jalr	968(ra) # 80004faa <piperead>
    80004bea:	892a                	mv	s2,a0
    80004bec:	b7d5                	j	80004bd0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bee:	02451783          	lh	a5,36(a0)
    80004bf2:	03079693          	slli	a3,a5,0x30
    80004bf6:	92c1                	srli	a3,a3,0x30
    80004bf8:	4725                	li	a4,9
    80004bfa:	02d76863          	bltu	a4,a3,80004c2a <fileread+0xba>
    80004bfe:	0792                	slli	a5,a5,0x4
    80004c00:	0001d717          	auipc	a4,0x1d
    80004c04:	31870713          	addi	a4,a4,792 # 80021f18 <devsw>
    80004c08:	97ba                	add	a5,a5,a4
    80004c0a:	639c                	ld	a5,0(a5)
    80004c0c:	c38d                	beqz	a5,80004c2e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c0e:	4505                	li	a0,1
    80004c10:	9782                	jalr	a5
    80004c12:	892a                	mv	s2,a0
    80004c14:	bf75                	j	80004bd0 <fileread+0x60>
    panic("fileread");
    80004c16:	00004517          	auipc	a0,0x4
    80004c1a:	c4a50513          	addi	a0,a0,-950 # 80008860 <syscalls+0x270>
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	920080e7          	jalr	-1760(ra) # 8000053e <panic>
    return -1;
    80004c26:	597d                	li	s2,-1
    80004c28:	b765                	j	80004bd0 <fileread+0x60>
      return -1;
    80004c2a:	597d                	li	s2,-1
    80004c2c:	b755                	j	80004bd0 <fileread+0x60>
    80004c2e:	597d                	li	s2,-1
    80004c30:	b745                	j	80004bd0 <fileread+0x60>

0000000080004c32 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c32:	715d                	addi	sp,sp,-80
    80004c34:	e486                	sd	ra,72(sp)
    80004c36:	e0a2                	sd	s0,64(sp)
    80004c38:	fc26                	sd	s1,56(sp)
    80004c3a:	f84a                	sd	s2,48(sp)
    80004c3c:	f44e                	sd	s3,40(sp)
    80004c3e:	f052                	sd	s4,32(sp)
    80004c40:	ec56                	sd	s5,24(sp)
    80004c42:	e85a                	sd	s6,16(sp)
    80004c44:	e45e                	sd	s7,8(sp)
    80004c46:	e062                	sd	s8,0(sp)
    80004c48:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c4a:	00954783          	lbu	a5,9(a0)
    80004c4e:	10078663          	beqz	a5,80004d5a <filewrite+0x128>
    80004c52:	892a                	mv	s2,a0
    80004c54:	8aae                	mv	s5,a1
    80004c56:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c58:	411c                	lw	a5,0(a0)
    80004c5a:	4705                	li	a4,1
    80004c5c:	02e78263          	beq	a5,a4,80004c80 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c60:	470d                	li	a4,3
    80004c62:	02e78663          	beq	a5,a4,80004c8e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c66:	4709                	li	a4,2
    80004c68:	0ee79163          	bne	a5,a4,80004d4a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c6c:	0ac05d63          	blez	a2,80004d26 <filewrite+0xf4>
    int i = 0;
    80004c70:	4981                	li	s3,0
    80004c72:	6b05                	lui	s6,0x1
    80004c74:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c78:	6b85                	lui	s7,0x1
    80004c7a:	c00b8b9b          	addiw	s7,s7,-1024
    80004c7e:	a861                	j	80004d16 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c80:	6908                	ld	a0,16(a0)
    80004c82:	00000097          	auipc	ra,0x0
    80004c86:	22e080e7          	jalr	558(ra) # 80004eb0 <pipewrite>
    80004c8a:	8a2a                	mv	s4,a0
    80004c8c:	a045                	j	80004d2c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c8e:	02451783          	lh	a5,36(a0)
    80004c92:	03079693          	slli	a3,a5,0x30
    80004c96:	92c1                	srli	a3,a3,0x30
    80004c98:	4725                	li	a4,9
    80004c9a:	0cd76263          	bltu	a4,a3,80004d5e <filewrite+0x12c>
    80004c9e:	0792                	slli	a5,a5,0x4
    80004ca0:	0001d717          	auipc	a4,0x1d
    80004ca4:	27870713          	addi	a4,a4,632 # 80021f18 <devsw>
    80004ca8:	97ba                	add	a5,a5,a4
    80004caa:	679c                	ld	a5,8(a5)
    80004cac:	cbdd                	beqz	a5,80004d62 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004cae:	4505                	li	a0,1
    80004cb0:	9782                	jalr	a5
    80004cb2:	8a2a                	mv	s4,a0
    80004cb4:	a8a5                	j	80004d2c <filewrite+0xfa>
    80004cb6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004cba:	00000097          	auipc	ra,0x0
    80004cbe:	8b0080e7          	jalr	-1872(ra) # 8000456a <begin_op>
      ilock(f->ip);
    80004cc2:	01893503          	ld	a0,24(s2)
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	ed2080e7          	jalr	-302(ra) # 80003b98 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cce:	8762                	mv	a4,s8
    80004cd0:	02092683          	lw	a3,32(s2)
    80004cd4:	01598633          	add	a2,s3,s5
    80004cd8:	4585                	li	a1,1
    80004cda:	01893503          	ld	a0,24(s2)
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	266080e7          	jalr	614(ra) # 80003f44 <writei>
    80004ce6:	84aa                	mv	s1,a0
    80004ce8:	00a05763          	blez	a0,80004cf6 <filewrite+0xc4>
        f->off += r;
    80004cec:	02092783          	lw	a5,32(s2)
    80004cf0:	9fa9                	addw	a5,a5,a0
    80004cf2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cf6:	01893503          	ld	a0,24(s2)
    80004cfa:	fffff097          	auipc	ra,0xfffff
    80004cfe:	f60080e7          	jalr	-160(ra) # 80003c5a <iunlock>
      end_op();
    80004d02:	00000097          	auipc	ra,0x0
    80004d06:	8e8080e7          	jalr	-1816(ra) # 800045ea <end_op>

      if(r != n1){
    80004d0a:	009c1f63          	bne	s8,s1,80004d28 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d0e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d12:	0149db63          	bge	s3,s4,80004d28 <filewrite+0xf6>
      int n1 = n - i;
    80004d16:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d1a:	84be                	mv	s1,a5
    80004d1c:	2781                	sext.w	a5,a5
    80004d1e:	f8fb5ce3          	bge	s6,a5,80004cb6 <filewrite+0x84>
    80004d22:	84de                	mv	s1,s7
    80004d24:	bf49                	j	80004cb6 <filewrite+0x84>
    int i = 0;
    80004d26:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d28:	013a1f63          	bne	s4,s3,80004d46 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d2c:	8552                	mv	a0,s4
    80004d2e:	60a6                	ld	ra,72(sp)
    80004d30:	6406                	ld	s0,64(sp)
    80004d32:	74e2                	ld	s1,56(sp)
    80004d34:	7942                	ld	s2,48(sp)
    80004d36:	79a2                	ld	s3,40(sp)
    80004d38:	7a02                	ld	s4,32(sp)
    80004d3a:	6ae2                	ld	s5,24(sp)
    80004d3c:	6b42                	ld	s6,16(sp)
    80004d3e:	6ba2                	ld	s7,8(sp)
    80004d40:	6c02                	ld	s8,0(sp)
    80004d42:	6161                	addi	sp,sp,80
    80004d44:	8082                	ret
    ret = (i == n ? n : -1);
    80004d46:	5a7d                	li	s4,-1
    80004d48:	b7d5                	j	80004d2c <filewrite+0xfa>
    panic("filewrite");
    80004d4a:	00004517          	auipc	a0,0x4
    80004d4e:	b2650513          	addi	a0,a0,-1242 # 80008870 <syscalls+0x280>
    80004d52:	ffffb097          	auipc	ra,0xffffb
    80004d56:	7ec080e7          	jalr	2028(ra) # 8000053e <panic>
    return -1;
    80004d5a:	5a7d                	li	s4,-1
    80004d5c:	bfc1                	j	80004d2c <filewrite+0xfa>
      return -1;
    80004d5e:	5a7d                	li	s4,-1
    80004d60:	b7f1                	j	80004d2c <filewrite+0xfa>
    80004d62:	5a7d                	li	s4,-1
    80004d64:	b7e1                	j	80004d2c <filewrite+0xfa>

0000000080004d66 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d66:	7179                	addi	sp,sp,-48
    80004d68:	f406                	sd	ra,40(sp)
    80004d6a:	f022                	sd	s0,32(sp)
    80004d6c:	ec26                	sd	s1,24(sp)
    80004d6e:	e84a                	sd	s2,16(sp)
    80004d70:	e44e                	sd	s3,8(sp)
    80004d72:	e052                	sd	s4,0(sp)
    80004d74:	1800                	addi	s0,sp,48
    80004d76:	84aa                	mv	s1,a0
    80004d78:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d7a:	0005b023          	sd	zero,0(a1)
    80004d7e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d82:	00000097          	auipc	ra,0x0
    80004d86:	bf8080e7          	jalr	-1032(ra) # 8000497a <filealloc>
    80004d8a:	e088                	sd	a0,0(s1)
    80004d8c:	c551                	beqz	a0,80004e18 <pipealloc+0xb2>
    80004d8e:	00000097          	auipc	ra,0x0
    80004d92:	bec080e7          	jalr	-1044(ra) # 8000497a <filealloc>
    80004d96:	00aa3023          	sd	a0,0(s4)
    80004d9a:	c92d                	beqz	a0,80004e0c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	d58080e7          	jalr	-680(ra) # 80000af4 <kalloc>
    80004da4:	892a                	mv	s2,a0
    80004da6:	c125                	beqz	a0,80004e06 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004da8:	4985                	li	s3,1
    80004daa:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004dae:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004db2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004db6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004dba:	00003597          	auipc	a1,0x3
    80004dbe:	77658593          	addi	a1,a1,1910 # 80008530 <states.1773+0x270>
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	d92080e7          	jalr	-622(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004dca:	609c                	ld	a5,0(s1)
    80004dcc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dd0:	609c                	ld	a5,0(s1)
    80004dd2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dd6:	609c                	ld	a5,0(s1)
    80004dd8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ddc:	609c                	ld	a5,0(s1)
    80004dde:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004de2:	000a3783          	ld	a5,0(s4)
    80004de6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dea:	000a3783          	ld	a5,0(s4)
    80004dee:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004df2:	000a3783          	ld	a5,0(s4)
    80004df6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004dfa:	000a3783          	ld	a5,0(s4)
    80004dfe:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e02:	4501                	li	a0,0
    80004e04:	a025                	j	80004e2c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e06:	6088                	ld	a0,0(s1)
    80004e08:	e501                	bnez	a0,80004e10 <pipealloc+0xaa>
    80004e0a:	a039                	j	80004e18 <pipealloc+0xb2>
    80004e0c:	6088                	ld	a0,0(s1)
    80004e0e:	c51d                	beqz	a0,80004e3c <pipealloc+0xd6>
    fileclose(*f0);
    80004e10:	00000097          	auipc	ra,0x0
    80004e14:	c26080e7          	jalr	-986(ra) # 80004a36 <fileclose>
  if(*f1)
    80004e18:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e1c:	557d                	li	a0,-1
  if(*f1)
    80004e1e:	c799                	beqz	a5,80004e2c <pipealloc+0xc6>
    fileclose(*f1);
    80004e20:	853e                	mv	a0,a5
    80004e22:	00000097          	auipc	ra,0x0
    80004e26:	c14080e7          	jalr	-1004(ra) # 80004a36 <fileclose>
  return -1;
    80004e2a:	557d                	li	a0,-1
}
    80004e2c:	70a2                	ld	ra,40(sp)
    80004e2e:	7402                	ld	s0,32(sp)
    80004e30:	64e2                	ld	s1,24(sp)
    80004e32:	6942                	ld	s2,16(sp)
    80004e34:	69a2                	ld	s3,8(sp)
    80004e36:	6a02                	ld	s4,0(sp)
    80004e38:	6145                	addi	sp,sp,48
    80004e3a:	8082                	ret
  return -1;
    80004e3c:	557d                	li	a0,-1
    80004e3e:	b7fd                	j	80004e2c <pipealloc+0xc6>

0000000080004e40 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e40:	1101                	addi	sp,sp,-32
    80004e42:	ec06                	sd	ra,24(sp)
    80004e44:	e822                	sd	s0,16(sp)
    80004e46:	e426                	sd	s1,8(sp)
    80004e48:	e04a                	sd	s2,0(sp)
    80004e4a:	1000                	addi	s0,sp,32
    80004e4c:	84aa                	mv	s1,a0
    80004e4e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	d94080e7          	jalr	-620(ra) # 80000be4 <acquire>
  if(writable){
    80004e58:	02090d63          	beqz	s2,80004e92 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e5c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e60:	21848513          	addi	a0,s1,536
    80004e64:	ffffd097          	auipc	ra,0xffffd
    80004e68:	678080e7          	jalr	1656(ra) # 800024dc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e6c:	2204b783          	ld	a5,544(s1)
    80004e70:	eb95                	bnez	a5,80004ea4 <pipeclose+0x64>
    release(&pi->lock);
    80004e72:	8526                	mv	a0,s1
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	e24080e7          	jalr	-476(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004e7c:	8526                	mv	a0,s1
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	b7a080e7          	jalr	-1158(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e86:	60e2                	ld	ra,24(sp)
    80004e88:	6442                	ld	s0,16(sp)
    80004e8a:	64a2                	ld	s1,8(sp)
    80004e8c:	6902                	ld	s2,0(sp)
    80004e8e:	6105                	addi	sp,sp,32
    80004e90:	8082                	ret
    pi->readopen = 0;
    80004e92:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e96:	21c48513          	addi	a0,s1,540
    80004e9a:	ffffd097          	auipc	ra,0xffffd
    80004e9e:	642080e7          	jalr	1602(ra) # 800024dc <wakeup>
    80004ea2:	b7e9                	j	80004e6c <pipeclose+0x2c>
    release(&pi->lock);
    80004ea4:	8526                	mv	a0,s1
    80004ea6:	ffffc097          	auipc	ra,0xffffc
    80004eaa:	df2080e7          	jalr	-526(ra) # 80000c98 <release>
}
    80004eae:	bfe1                	j	80004e86 <pipeclose+0x46>

0000000080004eb0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004eb0:	7159                	addi	sp,sp,-112
    80004eb2:	f486                	sd	ra,104(sp)
    80004eb4:	f0a2                	sd	s0,96(sp)
    80004eb6:	eca6                	sd	s1,88(sp)
    80004eb8:	e8ca                	sd	s2,80(sp)
    80004eba:	e4ce                	sd	s3,72(sp)
    80004ebc:	e0d2                	sd	s4,64(sp)
    80004ebe:	fc56                	sd	s5,56(sp)
    80004ec0:	f85a                	sd	s6,48(sp)
    80004ec2:	f45e                	sd	s7,40(sp)
    80004ec4:	f062                	sd	s8,32(sp)
    80004ec6:	ec66                	sd	s9,24(sp)
    80004ec8:	1880                	addi	s0,sp,112
    80004eca:	84aa                	mv	s1,a0
    80004ecc:	8aae                	mv	s5,a1
    80004ece:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ed0:	ffffd097          	auipc	ra,0xffffd
    80004ed4:	b5c080e7          	jalr	-1188(ra) # 80001a2c <myproc>
    80004ed8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004eda:	8526                	mv	a0,s1
    80004edc:	ffffc097          	auipc	ra,0xffffc
    80004ee0:	d08080e7          	jalr	-760(ra) # 80000be4 <acquire>
  while(i < n){
    80004ee4:	0d405163          	blez	s4,80004fa6 <pipewrite+0xf6>
    80004ee8:	8ba6                	mv	s7,s1
  int i = 0;
    80004eea:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004eec:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004eee:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ef2:	21c48c13          	addi	s8,s1,540
    80004ef6:	a08d                	j	80004f58 <pipewrite+0xa8>
      release(&pi->lock);
    80004ef8:	8526                	mv	a0,s1
    80004efa:	ffffc097          	auipc	ra,0xffffc
    80004efe:	d9e080e7          	jalr	-610(ra) # 80000c98 <release>
      return -1;
    80004f02:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f04:	854a                	mv	a0,s2
    80004f06:	70a6                	ld	ra,104(sp)
    80004f08:	7406                	ld	s0,96(sp)
    80004f0a:	64e6                	ld	s1,88(sp)
    80004f0c:	6946                	ld	s2,80(sp)
    80004f0e:	69a6                	ld	s3,72(sp)
    80004f10:	6a06                	ld	s4,64(sp)
    80004f12:	7ae2                	ld	s5,56(sp)
    80004f14:	7b42                	ld	s6,48(sp)
    80004f16:	7ba2                	ld	s7,40(sp)
    80004f18:	7c02                	ld	s8,32(sp)
    80004f1a:	6ce2                	ld	s9,24(sp)
    80004f1c:	6165                	addi	sp,sp,112
    80004f1e:	8082                	ret
      wakeup(&pi->nread);
    80004f20:	8566                	mv	a0,s9
    80004f22:	ffffd097          	auipc	ra,0xffffd
    80004f26:	5ba080e7          	jalr	1466(ra) # 800024dc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f2a:	85de                	mv	a1,s7
    80004f2c:	8562                	mv	a0,s8
    80004f2e:	ffffd097          	auipc	ra,0xffffd
    80004f32:	2d6080e7          	jalr	726(ra) # 80002204 <sleep>
    80004f36:	a839                	j	80004f54 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f38:	21c4a783          	lw	a5,540(s1)
    80004f3c:	0017871b          	addiw	a4,a5,1
    80004f40:	20e4ae23          	sw	a4,540(s1)
    80004f44:	1ff7f793          	andi	a5,a5,511
    80004f48:	97a6                	add	a5,a5,s1
    80004f4a:	f9f44703          	lbu	a4,-97(s0)
    80004f4e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f52:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f54:	03495d63          	bge	s2,s4,80004f8e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f58:	2204a783          	lw	a5,544(s1)
    80004f5c:	dfd1                	beqz	a5,80004ef8 <pipewrite+0x48>
    80004f5e:	0289a783          	lw	a5,40(s3)
    80004f62:	fbd9                	bnez	a5,80004ef8 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f64:	2184a783          	lw	a5,536(s1)
    80004f68:	21c4a703          	lw	a4,540(s1)
    80004f6c:	2007879b          	addiw	a5,a5,512
    80004f70:	faf708e3          	beq	a4,a5,80004f20 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f74:	4685                	li	a3,1
    80004f76:	01590633          	add	a2,s2,s5
    80004f7a:	f9f40593          	addi	a1,s0,-97
    80004f7e:	0509b503          	ld	a0,80(s3)
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	77c080e7          	jalr	1916(ra) # 800016fe <copyin>
    80004f8a:	fb6517e3          	bne	a0,s6,80004f38 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f8e:	21848513          	addi	a0,s1,536
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	54a080e7          	jalr	1354(ra) # 800024dc <wakeup>
  release(&pi->lock);
    80004f9a:	8526                	mv	a0,s1
    80004f9c:	ffffc097          	auipc	ra,0xffffc
    80004fa0:	cfc080e7          	jalr	-772(ra) # 80000c98 <release>
  return i;
    80004fa4:	b785                	j	80004f04 <pipewrite+0x54>
  int i = 0;
    80004fa6:	4901                	li	s2,0
    80004fa8:	b7dd                	j	80004f8e <pipewrite+0xde>

0000000080004faa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004faa:	715d                	addi	sp,sp,-80
    80004fac:	e486                	sd	ra,72(sp)
    80004fae:	e0a2                	sd	s0,64(sp)
    80004fb0:	fc26                	sd	s1,56(sp)
    80004fb2:	f84a                	sd	s2,48(sp)
    80004fb4:	f44e                	sd	s3,40(sp)
    80004fb6:	f052                	sd	s4,32(sp)
    80004fb8:	ec56                	sd	s5,24(sp)
    80004fba:	e85a                	sd	s6,16(sp)
    80004fbc:	0880                	addi	s0,sp,80
    80004fbe:	84aa                	mv	s1,a0
    80004fc0:	892e                	mv	s2,a1
    80004fc2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fc4:	ffffd097          	auipc	ra,0xffffd
    80004fc8:	a68080e7          	jalr	-1432(ra) # 80001a2c <myproc>
    80004fcc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fce:	8b26                	mv	s6,s1
    80004fd0:	8526                	mv	a0,s1
    80004fd2:	ffffc097          	auipc	ra,0xffffc
    80004fd6:	c12080e7          	jalr	-1006(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fda:	2184a703          	lw	a4,536(s1)
    80004fde:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fe2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fe6:	02f71463          	bne	a4,a5,8000500e <piperead+0x64>
    80004fea:	2244a783          	lw	a5,548(s1)
    80004fee:	c385                	beqz	a5,8000500e <piperead+0x64>
    if(pr->killed){
    80004ff0:	028a2783          	lw	a5,40(s4)
    80004ff4:	ebc1                	bnez	a5,80005084 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ff6:	85da                	mv	a1,s6
    80004ff8:	854e                	mv	a0,s3
    80004ffa:	ffffd097          	auipc	ra,0xffffd
    80004ffe:	20a080e7          	jalr	522(ra) # 80002204 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005002:	2184a703          	lw	a4,536(s1)
    80005006:	21c4a783          	lw	a5,540(s1)
    8000500a:	fef700e3          	beq	a4,a5,80004fea <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000500e:	09505263          	blez	s5,80005092 <piperead+0xe8>
    80005012:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005014:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005016:	2184a783          	lw	a5,536(s1)
    8000501a:	21c4a703          	lw	a4,540(s1)
    8000501e:	02f70d63          	beq	a4,a5,80005058 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005022:	0017871b          	addiw	a4,a5,1
    80005026:	20e4ac23          	sw	a4,536(s1)
    8000502a:	1ff7f793          	andi	a5,a5,511
    8000502e:	97a6                	add	a5,a5,s1
    80005030:	0187c783          	lbu	a5,24(a5)
    80005034:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005038:	4685                	li	a3,1
    8000503a:	fbf40613          	addi	a2,s0,-65
    8000503e:	85ca                	mv	a1,s2
    80005040:	050a3503          	ld	a0,80(s4)
    80005044:	ffffc097          	auipc	ra,0xffffc
    80005048:	62e080e7          	jalr	1582(ra) # 80001672 <copyout>
    8000504c:	01650663          	beq	a0,s6,80005058 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005050:	2985                	addiw	s3,s3,1
    80005052:	0905                	addi	s2,s2,1
    80005054:	fd3a91e3          	bne	s5,s3,80005016 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005058:	21c48513          	addi	a0,s1,540
    8000505c:	ffffd097          	auipc	ra,0xffffd
    80005060:	480080e7          	jalr	1152(ra) # 800024dc <wakeup>
  release(&pi->lock);
    80005064:	8526                	mv	a0,s1
    80005066:	ffffc097          	auipc	ra,0xffffc
    8000506a:	c32080e7          	jalr	-974(ra) # 80000c98 <release>
  return i;
}
    8000506e:	854e                	mv	a0,s3
    80005070:	60a6                	ld	ra,72(sp)
    80005072:	6406                	ld	s0,64(sp)
    80005074:	74e2                	ld	s1,56(sp)
    80005076:	7942                	ld	s2,48(sp)
    80005078:	79a2                	ld	s3,40(sp)
    8000507a:	7a02                	ld	s4,32(sp)
    8000507c:	6ae2                	ld	s5,24(sp)
    8000507e:	6b42                	ld	s6,16(sp)
    80005080:	6161                	addi	sp,sp,80
    80005082:	8082                	ret
      release(&pi->lock);
    80005084:	8526                	mv	a0,s1
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	c12080e7          	jalr	-1006(ra) # 80000c98 <release>
      return -1;
    8000508e:	59fd                	li	s3,-1
    80005090:	bff9                	j	8000506e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005092:	4981                	li	s3,0
    80005094:	b7d1                	j	80005058 <piperead+0xae>

0000000080005096 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005096:	df010113          	addi	sp,sp,-528
    8000509a:	20113423          	sd	ra,520(sp)
    8000509e:	20813023          	sd	s0,512(sp)
    800050a2:	ffa6                	sd	s1,504(sp)
    800050a4:	fbca                	sd	s2,496(sp)
    800050a6:	f7ce                	sd	s3,488(sp)
    800050a8:	f3d2                	sd	s4,480(sp)
    800050aa:	efd6                	sd	s5,472(sp)
    800050ac:	ebda                	sd	s6,464(sp)
    800050ae:	e7de                	sd	s7,456(sp)
    800050b0:	e3e2                	sd	s8,448(sp)
    800050b2:	ff66                	sd	s9,440(sp)
    800050b4:	fb6a                	sd	s10,432(sp)
    800050b6:	f76e                	sd	s11,424(sp)
    800050b8:	0c00                	addi	s0,sp,528
    800050ba:	84aa                	mv	s1,a0
    800050bc:	dea43c23          	sd	a0,-520(s0)
    800050c0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050c4:	ffffd097          	auipc	ra,0xffffd
    800050c8:	968080e7          	jalr	-1688(ra) # 80001a2c <myproc>
    800050cc:	892a                	mv	s2,a0

  begin_op();
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	49c080e7          	jalr	1180(ra) # 8000456a <begin_op>

  if((ip = namei(path)) == 0){
    800050d6:	8526                	mv	a0,s1
    800050d8:	fffff097          	auipc	ra,0xfffff
    800050dc:	276080e7          	jalr	630(ra) # 8000434e <namei>
    800050e0:	c92d                	beqz	a0,80005152 <exec+0xbc>
    800050e2:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050e4:	fffff097          	auipc	ra,0xfffff
    800050e8:	ab4080e7          	jalr	-1356(ra) # 80003b98 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050ec:	04000713          	li	a4,64
    800050f0:	4681                	li	a3,0
    800050f2:	e5040613          	addi	a2,s0,-432
    800050f6:	4581                	li	a1,0
    800050f8:	8526                	mv	a0,s1
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	d52080e7          	jalr	-686(ra) # 80003e4c <readi>
    80005102:	04000793          	li	a5,64
    80005106:	00f51a63          	bne	a0,a5,8000511a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000510a:	e5042703          	lw	a4,-432(s0)
    8000510e:	464c47b7          	lui	a5,0x464c4
    80005112:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005116:	04f70463          	beq	a4,a5,8000515e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000511a:	8526                	mv	a0,s1
    8000511c:	fffff097          	auipc	ra,0xfffff
    80005120:	cde080e7          	jalr	-802(ra) # 80003dfa <iunlockput>
    end_op();
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	4c6080e7          	jalr	1222(ra) # 800045ea <end_op>
  }
  return -1;
    8000512c:	557d                	li	a0,-1
}
    8000512e:	20813083          	ld	ra,520(sp)
    80005132:	20013403          	ld	s0,512(sp)
    80005136:	74fe                	ld	s1,504(sp)
    80005138:	795e                	ld	s2,496(sp)
    8000513a:	79be                	ld	s3,488(sp)
    8000513c:	7a1e                	ld	s4,480(sp)
    8000513e:	6afe                	ld	s5,472(sp)
    80005140:	6b5e                	ld	s6,464(sp)
    80005142:	6bbe                	ld	s7,456(sp)
    80005144:	6c1e                	ld	s8,448(sp)
    80005146:	7cfa                	ld	s9,440(sp)
    80005148:	7d5a                	ld	s10,432(sp)
    8000514a:	7dba                	ld	s11,424(sp)
    8000514c:	21010113          	addi	sp,sp,528
    80005150:	8082                	ret
    end_op();
    80005152:	fffff097          	auipc	ra,0xfffff
    80005156:	498080e7          	jalr	1176(ra) # 800045ea <end_op>
    return -1;
    8000515a:	557d                	li	a0,-1
    8000515c:	bfc9                	j	8000512e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000515e:	854a                	mv	a0,s2
    80005160:	ffffd097          	auipc	ra,0xffffd
    80005164:	990080e7          	jalr	-1648(ra) # 80001af0 <proc_pagetable>
    80005168:	8baa                	mv	s7,a0
    8000516a:	d945                	beqz	a0,8000511a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000516c:	e7042983          	lw	s3,-400(s0)
    80005170:	e8845783          	lhu	a5,-376(s0)
    80005174:	c7ad                	beqz	a5,800051de <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005176:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005178:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000517a:	6c85                	lui	s9,0x1
    8000517c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005180:	def43823          	sd	a5,-528(s0)
    80005184:	a42d                	j	800053ae <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005186:	00003517          	auipc	a0,0x3
    8000518a:	6fa50513          	addi	a0,a0,1786 # 80008880 <syscalls+0x290>
    8000518e:	ffffb097          	auipc	ra,0xffffb
    80005192:	3b0080e7          	jalr	944(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005196:	8756                	mv	a4,s5
    80005198:	012d86bb          	addw	a3,s11,s2
    8000519c:	4581                	li	a1,0
    8000519e:	8526                	mv	a0,s1
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	cac080e7          	jalr	-852(ra) # 80003e4c <readi>
    800051a8:	2501                	sext.w	a0,a0
    800051aa:	1aaa9963          	bne	s5,a0,8000535c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800051ae:	6785                	lui	a5,0x1
    800051b0:	0127893b          	addw	s2,a5,s2
    800051b4:	77fd                	lui	a5,0xfffff
    800051b6:	01478a3b          	addw	s4,a5,s4
    800051ba:	1f897163          	bgeu	s2,s8,8000539c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800051be:	02091593          	slli	a1,s2,0x20
    800051c2:	9181                	srli	a1,a1,0x20
    800051c4:	95ea                	add	a1,a1,s10
    800051c6:	855e                	mv	a0,s7
    800051c8:	ffffc097          	auipc	ra,0xffffc
    800051cc:	ea6080e7          	jalr	-346(ra) # 8000106e <walkaddr>
    800051d0:	862a                	mv	a2,a0
    if(pa == 0)
    800051d2:	d955                	beqz	a0,80005186 <exec+0xf0>
      n = PGSIZE;
    800051d4:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800051d6:	fd9a70e3          	bgeu	s4,s9,80005196 <exec+0x100>
      n = sz - i;
    800051da:	8ad2                	mv	s5,s4
    800051dc:	bf6d                	j	80005196 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051de:	4901                	li	s2,0
  iunlockput(ip);
    800051e0:	8526                	mv	a0,s1
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	c18080e7          	jalr	-1000(ra) # 80003dfa <iunlockput>
  end_op();
    800051ea:	fffff097          	auipc	ra,0xfffff
    800051ee:	400080e7          	jalr	1024(ra) # 800045ea <end_op>
  p = myproc();
    800051f2:	ffffd097          	auipc	ra,0xffffd
    800051f6:	83a080e7          	jalr	-1990(ra) # 80001a2c <myproc>
    800051fa:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800051fc:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005200:	6785                	lui	a5,0x1
    80005202:	17fd                	addi	a5,a5,-1
    80005204:	993e                	add	s2,s2,a5
    80005206:	757d                	lui	a0,0xfffff
    80005208:	00a977b3          	and	a5,s2,a0
    8000520c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005210:	6609                	lui	a2,0x2
    80005212:	963e                	add	a2,a2,a5
    80005214:	85be                	mv	a1,a5
    80005216:	855e                	mv	a0,s7
    80005218:	ffffc097          	auipc	ra,0xffffc
    8000521c:	20a080e7          	jalr	522(ra) # 80001422 <uvmalloc>
    80005220:	8b2a                	mv	s6,a0
  ip = 0;
    80005222:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005224:	12050c63          	beqz	a0,8000535c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005228:	75f9                	lui	a1,0xffffe
    8000522a:	95aa                	add	a1,a1,a0
    8000522c:	855e                	mv	a0,s7
    8000522e:	ffffc097          	auipc	ra,0xffffc
    80005232:	412080e7          	jalr	1042(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005236:	7c7d                	lui	s8,0xfffff
    80005238:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000523a:	e0043783          	ld	a5,-512(s0)
    8000523e:	6388                	ld	a0,0(a5)
    80005240:	c535                	beqz	a0,800052ac <exec+0x216>
    80005242:	e9040993          	addi	s3,s0,-368
    80005246:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000524a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000524c:	ffffc097          	auipc	ra,0xffffc
    80005250:	c18080e7          	jalr	-1000(ra) # 80000e64 <strlen>
    80005254:	2505                	addiw	a0,a0,1
    80005256:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000525a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000525e:	13896363          	bltu	s2,s8,80005384 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005262:	e0043d83          	ld	s11,-512(s0)
    80005266:	000dba03          	ld	s4,0(s11)
    8000526a:	8552                	mv	a0,s4
    8000526c:	ffffc097          	auipc	ra,0xffffc
    80005270:	bf8080e7          	jalr	-1032(ra) # 80000e64 <strlen>
    80005274:	0015069b          	addiw	a3,a0,1
    80005278:	8652                	mv	a2,s4
    8000527a:	85ca                	mv	a1,s2
    8000527c:	855e                	mv	a0,s7
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	3f4080e7          	jalr	1012(ra) # 80001672 <copyout>
    80005286:	10054363          	bltz	a0,8000538c <exec+0x2f6>
    ustack[argc] = sp;
    8000528a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000528e:	0485                	addi	s1,s1,1
    80005290:	008d8793          	addi	a5,s11,8
    80005294:	e0f43023          	sd	a5,-512(s0)
    80005298:	008db503          	ld	a0,8(s11)
    8000529c:	c911                	beqz	a0,800052b0 <exec+0x21a>
    if(argc >= MAXARG)
    8000529e:	09a1                	addi	s3,s3,8
    800052a0:	fb3c96e3          	bne	s9,s3,8000524c <exec+0x1b6>
  sz = sz1;
    800052a4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052a8:	4481                	li	s1,0
    800052aa:	a84d                	j	8000535c <exec+0x2c6>
  sp = sz;
    800052ac:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800052ae:	4481                	li	s1,0
  ustack[argc] = 0;
    800052b0:	00349793          	slli	a5,s1,0x3
    800052b4:	f9040713          	addi	a4,s0,-112
    800052b8:	97ba                	add	a5,a5,a4
    800052ba:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800052be:	00148693          	addi	a3,s1,1
    800052c2:	068e                	slli	a3,a3,0x3
    800052c4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052c8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052cc:	01897663          	bgeu	s2,s8,800052d8 <exec+0x242>
  sz = sz1;
    800052d0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052d4:	4481                	li	s1,0
    800052d6:	a059                	j	8000535c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052d8:	e9040613          	addi	a2,s0,-368
    800052dc:	85ca                	mv	a1,s2
    800052de:	855e                	mv	a0,s7
    800052e0:	ffffc097          	auipc	ra,0xffffc
    800052e4:	392080e7          	jalr	914(ra) # 80001672 <copyout>
    800052e8:	0a054663          	bltz	a0,80005394 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800052ec:	058ab783          	ld	a5,88(s5)
    800052f0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052f4:	df843783          	ld	a5,-520(s0)
    800052f8:	0007c703          	lbu	a4,0(a5)
    800052fc:	cf11                	beqz	a4,80005318 <exec+0x282>
    800052fe:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005300:	02f00693          	li	a3,47
    80005304:	a039                	j	80005312 <exec+0x27c>
      last = s+1;
    80005306:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000530a:	0785                	addi	a5,a5,1
    8000530c:	fff7c703          	lbu	a4,-1(a5)
    80005310:	c701                	beqz	a4,80005318 <exec+0x282>
    if(*s == '/')
    80005312:	fed71ce3          	bne	a4,a3,8000530a <exec+0x274>
    80005316:	bfc5                	j	80005306 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005318:	4641                	li	a2,16
    8000531a:	df843583          	ld	a1,-520(s0)
    8000531e:	158a8513          	addi	a0,s5,344
    80005322:	ffffc097          	auipc	ra,0xffffc
    80005326:	b10080e7          	jalr	-1264(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000532a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000532e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005332:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005336:	058ab783          	ld	a5,88(s5)
    8000533a:	e6843703          	ld	a4,-408(s0)
    8000533e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005340:	058ab783          	ld	a5,88(s5)
    80005344:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005348:	85ea                	mv	a1,s10
    8000534a:	ffffd097          	auipc	ra,0xffffd
    8000534e:	842080e7          	jalr	-1982(ra) # 80001b8c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005352:	0004851b          	sext.w	a0,s1
    80005356:	bbe1                	j	8000512e <exec+0x98>
    80005358:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000535c:	e0843583          	ld	a1,-504(s0)
    80005360:	855e                	mv	a0,s7
    80005362:	ffffd097          	auipc	ra,0xffffd
    80005366:	82a080e7          	jalr	-2006(ra) # 80001b8c <proc_freepagetable>
  if(ip){
    8000536a:	da0498e3          	bnez	s1,8000511a <exec+0x84>
  return -1;
    8000536e:	557d                	li	a0,-1
    80005370:	bb7d                	j	8000512e <exec+0x98>
    80005372:	e1243423          	sd	s2,-504(s0)
    80005376:	b7dd                	j	8000535c <exec+0x2c6>
    80005378:	e1243423          	sd	s2,-504(s0)
    8000537c:	b7c5                	j	8000535c <exec+0x2c6>
    8000537e:	e1243423          	sd	s2,-504(s0)
    80005382:	bfe9                	j	8000535c <exec+0x2c6>
  sz = sz1;
    80005384:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005388:	4481                	li	s1,0
    8000538a:	bfc9                	j	8000535c <exec+0x2c6>
  sz = sz1;
    8000538c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005390:	4481                	li	s1,0
    80005392:	b7e9                	j	8000535c <exec+0x2c6>
  sz = sz1;
    80005394:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005398:	4481                	li	s1,0
    8000539a:	b7c9                	j	8000535c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000539c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053a0:	2b05                	addiw	s6,s6,1
    800053a2:	0389899b          	addiw	s3,s3,56
    800053a6:	e8845783          	lhu	a5,-376(s0)
    800053aa:	e2fb5be3          	bge	s6,a5,800051e0 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053ae:	2981                	sext.w	s3,s3
    800053b0:	03800713          	li	a4,56
    800053b4:	86ce                	mv	a3,s3
    800053b6:	e1840613          	addi	a2,s0,-488
    800053ba:	4581                	li	a1,0
    800053bc:	8526                	mv	a0,s1
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	a8e080e7          	jalr	-1394(ra) # 80003e4c <readi>
    800053c6:	03800793          	li	a5,56
    800053ca:	f8f517e3          	bne	a0,a5,80005358 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800053ce:	e1842783          	lw	a5,-488(s0)
    800053d2:	4705                	li	a4,1
    800053d4:	fce796e3          	bne	a5,a4,800053a0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800053d8:	e4043603          	ld	a2,-448(s0)
    800053dc:	e3843783          	ld	a5,-456(s0)
    800053e0:	f8f669e3          	bltu	a2,a5,80005372 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053e4:	e2843783          	ld	a5,-472(s0)
    800053e8:	963e                	add	a2,a2,a5
    800053ea:	f8f667e3          	bltu	a2,a5,80005378 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053ee:	85ca                	mv	a1,s2
    800053f0:	855e                	mv	a0,s7
    800053f2:	ffffc097          	auipc	ra,0xffffc
    800053f6:	030080e7          	jalr	48(ra) # 80001422 <uvmalloc>
    800053fa:	e0a43423          	sd	a0,-504(s0)
    800053fe:	d141                	beqz	a0,8000537e <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005400:	e2843d03          	ld	s10,-472(s0)
    80005404:	df043783          	ld	a5,-528(s0)
    80005408:	00fd77b3          	and	a5,s10,a5
    8000540c:	fba1                	bnez	a5,8000535c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000540e:	e2042d83          	lw	s11,-480(s0)
    80005412:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005416:	f80c03e3          	beqz	s8,8000539c <exec+0x306>
    8000541a:	8a62                	mv	s4,s8
    8000541c:	4901                	li	s2,0
    8000541e:	b345                	j	800051be <exec+0x128>

0000000080005420 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005420:	7179                	addi	sp,sp,-48
    80005422:	f406                	sd	ra,40(sp)
    80005424:	f022                	sd	s0,32(sp)
    80005426:	ec26                	sd	s1,24(sp)
    80005428:	e84a                	sd	s2,16(sp)
    8000542a:	1800                	addi	s0,sp,48
    8000542c:	892e                	mv	s2,a1
    8000542e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005430:	fdc40593          	addi	a1,s0,-36
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	926080e7          	jalr	-1754(ra) # 80002d5a <argint>
    8000543c:	04054063          	bltz	a0,8000547c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005440:	fdc42703          	lw	a4,-36(s0)
    80005444:	47bd                	li	a5,15
    80005446:	02e7ed63          	bltu	a5,a4,80005480 <argfd+0x60>
    8000544a:	ffffc097          	auipc	ra,0xffffc
    8000544e:	5e2080e7          	jalr	1506(ra) # 80001a2c <myproc>
    80005452:	fdc42703          	lw	a4,-36(s0)
    80005456:	01a70793          	addi	a5,a4,26
    8000545a:	078e                	slli	a5,a5,0x3
    8000545c:	953e                	add	a0,a0,a5
    8000545e:	611c                	ld	a5,0(a0)
    80005460:	c395                	beqz	a5,80005484 <argfd+0x64>
    return -1;
  if(pfd)
    80005462:	00090463          	beqz	s2,8000546a <argfd+0x4a>
    *pfd = fd;
    80005466:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000546a:	4501                	li	a0,0
  if(pf)
    8000546c:	c091                	beqz	s1,80005470 <argfd+0x50>
    *pf = f;
    8000546e:	e09c                	sd	a5,0(s1)
}
    80005470:	70a2                	ld	ra,40(sp)
    80005472:	7402                	ld	s0,32(sp)
    80005474:	64e2                	ld	s1,24(sp)
    80005476:	6942                	ld	s2,16(sp)
    80005478:	6145                	addi	sp,sp,48
    8000547a:	8082                	ret
    return -1;
    8000547c:	557d                	li	a0,-1
    8000547e:	bfcd                	j	80005470 <argfd+0x50>
    return -1;
    80005480:	557d                	li	a0,-1
    80005482:	b7fd                	j	80005470 <argfd+0x50>
    80005484:	557d                	li	a0,-1
    80005486:	b7ed                	j	80005470 <argfd+0x50>

0000000080005488 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005488:	1101                	addi	sp,sp,-32
    8000548a:	ec06                	sd	ra,24(sp)
    8000548c:	e822                	sd	s0,16(sp)
    8000548e:	e426                	sd	s1,8(sp)
    80005490:	1000                	addi	s0,sp,32
    80005492:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005494:	ffffc097          	auipc	ra,0xffffc
    80005498:	598080e7          	jalr	1432(ra) # 80001a2c <myproc>
    8000549c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000549e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800054a2:	4501                	li	a0,0
    800054a4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054a6:	6398                	ld	a4,0(a5)
    800054a8:	cb19                	beqz	a4,800054be <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054aa:	2505                	addiw	a0,a0,1
    800054ac:	07a1                	addi	a5,a5,8
    800054ae:	fed51ce3          	bne	a0,a3,800054a6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054b2:	557d                	li	a0,-1
}
    800054b4:	60e2                	ld	ra,24(sp)
    800054b6:	6442                	ld	s0,16(sp)
    800054b8:	64a2                	ld	s1,8(sp)
    800054ba:	6105                	addi	sp,sp,32
    800054bc:	8082                	ret
      p->ofile[fd] = f;
    800054be:	01a50793          	addi	a5,a0,26
    800054c2:	078e                	slli	a5,a5,0x3
    800054c4:	963e                	add	a2,a2,a5
    800054c6:	e204                	sd	s1,0(a2)
      return fd;
    800054c8:	b7f5                	j	800054b4 <fdalloc+0x2c>

00000000800054ca <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054ca:	715d                	addi	sp,sp,-80
    800054cc:	e486                	sd	ra,72(sp)
    800054ce:	e0a2                	sd	s0,64(sp)
    800054d0:	fc26                	sd	s1,56(sp)
    800054d2:	f84a                	sd	s2,48(sp)
    800054d4:	f44e                	sd	s3,40(sp)
    800054d6:	f052                	sd	s4,32(sp)
    800054d8:	ec56                	sd	s5,24(sp)
    800054da:	0880                	addi	s0,sp,80
    800054dc:	89ae                	mv	s3,a1
    800054de:	8ab2                	mv	s5,a2
    800054e0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054e2:	fb040593          	addi	a1,s0,-80
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	e86080e7          	jalr	-378(ra) # 8000436c <nameiparent>
    800054ee:	892a                	mv	s2,a0
    800054f0:	12050f63          	beqz	a0,8000562e <create+0x164>
    return 0;

  ilock(dp);
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	6a4080e7          	jalr	1700(ra) # 80003b98 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054fc:	4601                	li	a2,0
    800054fe:	fb040593          	addi	a1,s0,-80
    80005502:	854a                	mv	a0,s2
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	b78080e7          	jalr	-1160(ra) # 8000407c <dirlookup>
    8000550c:	84aa                	mv	s1,a0
    8000550e:	c921                	beqz	a0,8000555e <create+0x94>
    iunlockput(dp);
    80005510:	854a                	mv	a0,s2
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	8e8080e7          	jalr	-1816(ra) # 80003dfa <iunlockput>
    ilock(ip);
    8000551a:	8526                	mv	a0,s1
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	67c080e7          	jalr	1660(ra) # 80003b98 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005524:	2981                	sext.w	s3,s3
    80005526:	4789                	li	a5,2
    80005528:	02f99463          	bne	s3,a5,80005550 <create+0x86>
    8000552c:	0444d783          	lhu	a5,68(s1)
    80005530:	37f9                	addiw	a5,a5,-2
    80005532:	17c2                	slli	a5,a5,0x30
    80005534:	93c1                	srli	a5,a5,0x30
    80005536:	4705                	li	a4,1
    80005538:	00f76c63          	bltu	a4,a5,80005550 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000553c:	8526                	mv	a0,s1
    8000553e:	60a6                	ld	ra,72(sp)
    80005540:	6406                	ld	s0,64(sp)
    80005542:	74e2                	ld	s1,56(sp)
    80005544:	7942                	ld	s2,48(sp)
    80005546:	79a2                	ld	s3,40(sp)
    80005548:	7a02                	ld	s4,32(sp)
    8000554a:	6ae2                	ld	s5,24(sp)
    8000554c:	6161                	addi	sp,sp,80
    8000554e:	8082                	ret
    iunlockput(ip);
    80005550:	8526                	mv	a0,s1
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	8a8080e7          	jalr	-1880(ra) # 80003dfa <iunlockput>
    return 0;
    8000555a:	4481                	li	s1,0
    8000555c:	b7c5                	j	8000553c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000555e:	85ce                	mv	a1,s3
    80005560:	00092503          	lw	a0,0(s2)
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	49c080e7          	jalr	1180(ra) # 80003a00 <ialloc>
    8000556c:	84aa                	mv	s1,a0
    8000556e:	c529                	beqz	a0,800055b8 <create+0xee>
  ilock(ip);
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	628080e7          	jalr	1576(ra) # 80003b98 <ilock>
  ip->major = major;
    80005578:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000557c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005580:	4785                	li	a5,1
    80005582:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005586:	8526                	mv	a0,s1
    80005588:	ffffe097          	auipc	ra,0xffffe
    8000558c:	546080e7          	jalr	1350(ra) # 80003ace <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005590:	2981                	sext.w	s3,s3
    80005592:	4785                	li	a5,1
    80005594:	02f98a63          	beq	s3,a5,800055c8 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005598:	40d0                	lw	a2,4(s1)
    8000559a:	fb040593          	addi	a1,s0,-80
    8000559e:	854a                	mv	a0,s2
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	cec080e7          	jalr	-788(ra) # 8000428c <dirlink>
    800055a8:	06054b63          	bltz	a0,8000561e <create+0x154>
  iunlockput(dp);
    800055ac:	854a                	mv	a0,s2
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	84c080e7          	jalr	-1972(ra) # 80003dfa <iunlockput>
  return ip;
    800055b6:	b759                	j	8000553c <create+0x72>
    panic("create: ialloc");
    800055b8:	00003517          	auipc	a0,0x3
    800055bc:	2e850513          	addi	a0,a0,744 # 800088a0 <syscalls+0x2b0>
    800055c0:	ffffb097          	auipc	ra,0xffffb
    800055c4:	f7e080e7          	jalr	-130(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800055c8:	04a95783          	lhu	a5,74(s2)
    800055cc:	2785                	addiw	a5,a5,1
    800055ce:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055d2:	854a                	mv	a0,s2
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	4fa080e7          	jalr	1274(ra) # 80003ace <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055dc:	40d0                	lw	a2,4(s1)
    800055de:	00003597          	auipc	a1,0x3
    800055e2:	2d258593          	addi	a1,a1,722 # 800088b0 <syscalls+0x2c0>
    800055e6:	8526                	mv	a0,s1
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	ca4080e7          	jalr	-860(ra) # 8000428c <dirlink>
    800055f0:	00054f63          	bltz	a0,8000560e <create+0x144>
    800055f4:	00492603          	lw	a2,4(s2)
    800055f8:	00003597          	auipc	a1,0x3
    800055fc:	2c058593          	addi	a1,a1,704 # 800088b8 <syscalls+0x2c8>
    80005600:	8526                	mv	a0,s1
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	c8a080e7          	jalr	-886(ra) # 8000428c <dirlink>
    8000560a:	f80557e3          	bgez	a0,80005598 <create+0xce>
      panic("create dots");
    8000560e:	00003517          	auipc	a0,0x3
    80005612:	2b250513          	addi	a0,a0,690 # 800088c0 <syscalls+0x2d0>
    80005616:	ffffb097          	auipc	ra,0xffffb
    8000561a:	f28080e7          	jalr	-216(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000561e:	00003517          	auipc	a0,0x3
    80005622:	2b250513          	addi	a0,a0,690 # 800088d0 <syscalls+0x2e0>
    80005626:	ffffb097          	auipc	ra,0xffffb
    8000562a:	f18080e7          	jalr	-232(ra) # 8000053e <panic>
    return 0;
    8000562e:	84aa                	mv	s1,a0
    80005630:	b731                	j	8000553c <create+0x72>

0000000080005632 <sys_dup>:
{
    80005632:	7179                	addi	sp,sp,-48
    80005634:	f406                	sd	ra,40(sp)
    80005636:	f022                	sd	s0,32(sp)
    80005638:	ec26                	sd	s1,24(sp)
    8000563a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000563c:	fd840613          	addi	a2,s0,-40
    80005640:	4581                	li	a1,0
    80005642:	4501                	li	a0,0
    80005644:	00000097          	auipc	ra,0x0
    80005648:	ddc080e7          	jalr	-548(ra) # 80005420 <argfd>
    return -1;
    8000564c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000564e:	02054363          	bltz	a0,80005674 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005652:	fd843503          	ld	a0,-40(s0)
    80005656:	00000097          	auipc	ra,0x0
    8000565a:	e32080e7          	jalr	-462(ra) # 80005488 <fdalloc>
    8000565e:	84aa                	mv	s1,a0
    return -1;
    80005660:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005662:	00054963          	bltz	a0,80005674 <sys_dup+0x42>
  filedup(f);
    80005666:	fd843503          	ld	a0,-40(s0)
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	37a080e7          	jalr	890(ra) # 800049e4 <filedup>
  return fd;
    80005672:	87a6                	mv	a5,s1
}
    80005674:	853e                	mv	a0,a5
    80005676:	70a2                	ld	ra,40(sp)
    80005678:	7402                	ld	s0,32(sp)
    8000567a:	64e2                	ld	s1,24(sp)
    8000567c:	6145                	addi	sp,sp,48
    8000567e:	8082                	ret

0000000080005680 <sys_read>:
{
    80005680:	7179                	addi	sp,sp,-48
    80005682:	f406                	sd	ra,40(sp)
    80005684:	f022                	sd	s0,32(sp)
    80005686:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005688:	fe840613          	addi	a2,s0,-24
    8000568c:	4581                	li	a1,0
    8000568e:	4501                	li	a0,0
    80005690:	00000097          	auipc	ra,0x0
    80005694:	d90080e7          	jalr	-624(ra) # 80005420 <argfd>
    return -1;
    80005698:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000569a:	04054163          	bltz	a0,800056dc <sys_read+0x5c>
    8000569e:	fe440593          	addi	a1,s0,-28
    800056a2:	4509                	li	a0,2
    800056a4:	ffffd097          	auipc	ra,0xffffd
    800056a8:	6b6080e7          	jalr	1718(ra) # 80002d5a <argint>
    return -1;
    800056ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ae:	02054763          	bltz	a0,800056dc <sys_read+0x5c>
    800056b2:	fd840593          	addi	a1,s0,-40
    800056b6:	4505                	li	a0,1
    800056b8:	ffffd097          	auipc	ra,0xffffd
    800056bc:	6c4080e7          	jalr	1732(ra) # 80002d7c <argaddr>
    return -1;
    800056c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056c2:	00054d63          	bltz	a0,800056dc <sys_read+0x5c>
  return fileread(f, p, n);
    800056c6:	fe442603          	lw	a2,-28(s0)
    800056ca:	fd843583          	ld	a1,-40(s0)
    800056ce:	fe843503          	ld	a0,-24(s0)
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	49e080e7          	jalr	1182(ra) # 80004b70 <fileread>
    800056da:	87aa                	mv	a5,a0
}
    800056dc:	853e                	mv	a0,a5
    800056de:	70a2                	ld	ra,40(sp)
    800056e0:	7402                	ld	s0,32(sp)
    800056e2:	6145                	addi	sp,sp,48
    800056e4:	8082                	ret

00000000800056e6 <sys_write>:
{
    800056e6:	7179                	addi	sp,sp,-48
    800056e8:	f406                	sd	ra,40(sp)
    800056ea:	f022                	sd	s0,32(sp)
    800056ec:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ee:	fe840613          	addi	a2,s0,-24
    800056f2:	4581                	li	a1,0
    800056f4:	4501                	li	a0,0
    800056f6:	00000097          	auipc	ra,0x0
    800056fa:	d2a080e7          	jalr	-726(ra) # 80005420 <argfd>
    return -1;
    800056fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005700:	04054163          	bltz	a0,80005742 <sys_write+0x5c>
    80005704:	fe440593          	addi	a1,s0,-28
    80005708:	4509                	li	a0,2
    8000570a:	ffffd097          	auipc	ra,0xffffd
    8000570e:	650080e7          	jalr	1616(ra) # 80002d5a <argint>
    return -1;
    80005712:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005714:	02054763          	bltz	a0,80005742 <sys_write+0x5c>
    80005718:	fd840593          	addi	a1,s0,-40
    8000571c:	4505                	li	a0,1
    8000571e:	ffffd097          	auipc	ra,0xffffd
    80005722:	65e080e7          	jalr	1630(ra) # 80002d7c <argaddr>
    return -1;
    80005726:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005728:	00054d63          	bltz	a0,80005742 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000572c:	fe442603          	lw	a2,-28(s0)
    80005730:	fd843583          	ld	a1,-40(s0)
    80005734:	fe843503          	ld	a0,-24(s0)
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	4fa080e7          	jalr	1274(ra) # 80004c32 <filewrite>
    80005740:	87aa                	mv	a5,a0
}
    80005742:	853e                	mv	a0,a5
    80005744:	70a2                	ld	ra,40(sp)
    80005746:	7402                	ld	s0,32(sp)
    80005748:	6145                	addi	sp,sp,48
    8000574a:	8082                	ret

000000008000574c <sys_close>:
{
    8000574c:	1101                	addi	sp,sp,-32
    8000574e:	ec06                	sd	ra,24(sp)
    80005750:	e822                	sd	s0,16(sp)
    80005752:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005754:	fe040613          	addi	a2,s0,-32
    80005758:	fec40593          	addi	a1,s0,-20
    8000575c:	4501                	li	a0,0
    8000575e:	00000097          	auipc	ra,0x0
    80005762:	cc2080e7          	jalr	-830(ra) # 80005420 <argfd>
    return -1;
    80005766:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005768:	02054463          	bltz	a0,80005790 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000576c:	ffffc097          	auipc	ra,0xffffc
    80005770:	2c0080e7          	jalr	704(ra) # 80001a2c <myproc>
    80005774:	fec42783          	lw	a5,-20(s0)
    80005778:	07e9                	addi	a5,a5,26
    8000577a:	078e                	slli	a5,a5,0x3
    8000577c:	97aa                	add	a5,a5,a0
    8000577e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005782:	fe043503          	ld	a0,-32(s0)
    80005786:	fffff097          	auipc	ra,0xfffff
    8000578a:	2b0080e7          	jalr	688(ra) # 80004a36 <fileclose>
  return 0;
    8000578e:	4781                	li	a5,0
}
    80005790:	853e                	mv	a0,a5
    80005792:	60e2                	ld	ra,24(sp)
    80005794:	6442                	ld	s0,16(sp)
    80005796:	6105                	addi	sp,sp,32
    80005798:	8082                	ret

000000008000579a <sys_fstat>:
{
    8000579a:	1101                	addi	sp,sp,-32
    8000579c:	ec06                	sd	ra,24(sp)
    8000579e:	e822                	sd	s0,16(sp)
    800057a0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057a2:	fe840613          	addi	a2,s0,-24
    800057a6:	4581                	li	a1,0
    800057a8:	4501                	li	a0,0
    800057aa:	00000097          	auipc	ra,0x0
    800057ae:	c76080e7          	jalr	-906(ra) # 80005420 <argfd>
    return -1;
    800057b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057b4:	02054563          	bltz	a0,800057de <sys_fstat+0x44>
    800057b8:	fe040593          	addi	a1,s0,-32
    800057bc:	4505                	li	a0,1
    800057be:	ffffd097          	auipc	ra,0xffffd
    800057c2:	5be080e7          	jalr	1470(ra) # 80002d7c <argaddr>
    return -1;
    800057c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057c8:	00054b63          	bltz	a0,800057de <sys_fstat+0x44>
  return filestat(f, st);
    800057cc:	fe043583          	ld	a1,-32(s0)
    800057d0:	fe843503          	ld	a0,-24(s0)
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	32a080e7          	jalr	810(ra) # 80004afe <filestat>
    800057dc:	87aa                	mv	a5,a0
}
    800057de:	853e                	mv	a0,a5
    800057e0:	60e2                	ld	ra,24(sp)
    800057e2:	6442                	ld	s0,16(sp)
    800057e4:	6105                	addi	sp,sp,32
    800057e6:	8082                	ret

00000000800057e8 <sys_link>:
{
    800057e8:	7169                	addi	sp,sp,-304
    800057ea:	f606                	sd	ra,296(sp)
    800057ec:	f222                	sd	s0,288(sp)
    800057ee:	ee26                	sd	s1,280(sp)
    800057f0:	ea4a                	sd	s2,272(sp)
    800057f2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057f4:	08000613          	li	a2,128
    800057f8:	ed040593          	addi	a1,s0,-304
    800057fc:	4501                	li	a0,0
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	5a0080e7          	jalr	1440(ra) # 80002d9e <argstr>
    return -1;
    80005806:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005808:	10054e63          	bltz	a0,80005924 <sys_link+0x13c>
    8000580c:	08000613          	li	a2,128
    80005810:	f5040593          	addi	a1,s0,-176
    80005814:	4505                	li	a0,1
    80005816:	ffffd097          	auipc	ra,0xffffd
    8000581a:	588080e7          	jalr	1416(ra) # 80002d9e <argstr>
    return -1;
    8000581e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005820:	10054263          	bltz	a0,80005924 <sys_link+0x13c>
  begin_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	d46080e7          	jalr	-698(ra) # 8000456a <begin_op>
  if((ip = namei(old)) == 0){
    8000582c:	ed040513          	addi	a0,s0,-304
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	b1e080e7          	jalr	-1250(ra) # 8000434e <namei>
    80005838:	84aa                	mv	s1,a0
    8000583a:	c551                	beqz	a0,800058c6 <sys_link+0xde>
  ilock(ip);
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	35c080e7          	jalr	860(ra) # 80003b98 <ilock>
  if(ip->type == T_DIR){
    80005844:	04449703          	lh	a4,68(s1)
    80005848:	4785                	li	a5,1
    8000584a:	08f70463          	beq	a4,a5,800058d2 <sys_link+0xea>
  ip->nlink++;
    8000584e:	04a4d783          	lhu	a5,74(s1)
    80005852:	2785                	addiw	a5,a5,1
    80005854:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005858:	8526                	mv	a0,s1
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	274080e7          	jalr	628(ra) # 80003ace <iupdate>
  iunlock(ip);
    80005862:	8526                	mv	a0,s1
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	3f6080e7          	jalr	1014(ra) # 80003c5a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000586c:	fd040593          	addi	a1,s0,-48
    80005870:	f5040513          	addi	a0,s0,-176
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	af8080e7          	jalr	-1288(ra) # 8000436c <nameiparent>
    8000587c:	892a                	mv	s2,a0
    8000587e:	c935                	beqz	a0,800058f2 <sys_link+0x10a>
  ilock(dp);
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	318080e7          	jalr	792(ra) # 80003b98 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005888:	00092703          	lw	a4,0(s2)
    8000588c:	409c                	lw	a5,0(s1)
    8000588e:	04f71d63          	bne	a4,a5,800058e8 <sys_link+0x100>
    80005892:	40d0                	lw	a2,4(s1)
    80005894:	fd040593          	addi	a1,s0,-48
    80005898:	854a                	mv	a0,s2
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	9f2080e7          	jalr	-1550(ra) # 8000428c <dirlink>
    800058a2:	04054363          	bltz	a0,800058e8 <sys_link+0x100>
  iunlockput(dp);
    800058a6:	854a                	mv	a0,s2
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	552080e7          	jalr	1362(ra) # 80003dfa <iunlockput>
  iput(ip);
    800058b0:	8526                	mv	a0,s1
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	4a0080e7          	jalr	1184(ra) # 80003d52 <iput>
  end_op();
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	d30080e7          	jalr	-720(ra) # 800045ea <end_op>
  return 0;
    800058c2:	4781                	li	a5,0
    800058c4:	a085                	j	80005924 <sys_link+0x13c>
    end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	d24080e7          	jalr	-732(ra) # 800045ea <end_op>
    return -1;
    800058ce:	57fd                	li	a5,-1
    800058d0:	a891                	j	80005924 <sys_link+0x13c>
    iunlockput(ip);
    800058d2:	8526                	mv	a0,s1
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	526080e7          	jalr	1318(ra) # 80003dfa <iunlockput>
    end_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	d0e080e7          	jalr	-754(ra) # 800045ea <end_op>
    return -1;
    800058e4:	57fd                	li	a5,-1
    800058e6:	a83d                	j	80005924 <sys_link+0x13c>
    iunlockput(dp);
    800058e8:	854a                	mv	a0,s2
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	510080e7          	jalr	1296(ra) # 80003dfa <iunlockput>
  ilock(ip);
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	2a4080e7          	jalr	676(ra) # 80003b98 <ilock>
  ip->nlink--;
    800058fc:	04a4d783          	lhu	a5,74(s1)
    80005900:	37fd                	addiw	a5,a5,-1
    80005902:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005906:	8526                	mv	a0,s1
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	1c6080e7          	jalr	454(ra) # 80003ace <iupdate>
  iunlockput(ip);
    80005910:	8526                	mv	a0,s1
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	4e8080e7          	jalr	1256(ra) # 80003dfa <iunlockput>
  end_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	cd0080e7          	jalr	-816(ra) # 800045ea <end_op>
  return -1;
    80005922:	57fd                	li	a5,-1
}
    80005924:	853e                	mv	a0,a5
    80005926:	70b2                	ld	ra,296(sp)
    80005928:	7412                	ld	s0,288(sp)
    8000592a:	64f2                	ld	s1,280(sp)
    8000592c:	6952                	ld	s2,272(sp)
    8000592e:	6155                	addi	sp,sp,304
    80005930:	8082                	ret

0000000080005932 <sys_unlink>:
{
    80005932:	7151                	addi	sp,sp,-240
    80005934:	f586                	sd	ra,232(sp)
    80005936:	f1a2                	sd	s0,224(sp)
    80005938:	eda6                	sd	s1,216(sp)
    8000593a:	e9ca                	sd	s2,208(sp)
    8000593c:	e5ce                	sd	s3,200(sp)
    8000593e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005940:	08000613          	li	a2,128
    80005944:	f3040593          	addi	a1,s0,-208
    80005948:	4501                	li	a0,0
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	454080e7          	jalr	1108(ra) # 80002d9e <argstr>
    80005952:	18054163          	bltz	a0,80005ad4 <sys_unlink+0x1a2>
  begin_op();
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	c14080e7          	jalr	-1004(ra) # 8000456a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000595e:	fb040593          	addi	a1,s0,-80
    80005962:	f3040513          	addi	a0,s0,-208
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	a06080e7          	jalr	-1530(ra) # 8000436c <nameiparent>
    8000596e:	84aa                	mv	s1,a0
    80005970:	c979                	beqz	a0,80005a46 <sys_unlink+0x114>
  ilock(dp);
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	226080e7          	jalr	550(ra) # 80003b98 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000597a:	00003597          	auipc	a1,0x3
    8000597e:	f3658593          	addi	a1,a1,-202 # 800088b0 <syscalls+0x2c0>
    80005982:	fb040513          	addi	a0,s0,-80
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	6dc080e7          	jalr	1756(ra) # 80004062 <namecmp>
    8000598e:	14050a63          	beqz	a0,80005ae2 <sys_unlink+0x1b0>
    80005992:	00003597          	auipc	a1,0x3
    80005996:	f2658593          	addi	a1,a1,-218 # 800088b8 <syscalls+0x2c8>
    8000599a:	fb040513          	addi	a0,s0,-80
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	6c4080e7          	jalr	1732(ra) # 80004062 <namecmp>
    800059a6:	12050e63          	beqz	a0,80005ae2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059aa:	f2c40613          	addi	a2,s0,-212
    800059ae:	fb040593          	addi	a1,s0,-80
    800059b2:	8526                	mv	a0,s1
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	6c8080e7          	jalr	1736(ra) # 8000407c <dirlookup>
    800059bc:	892a                	mv	s2,a0
    800059be:	12050263          	beqz	a0,80005ae2 <sys_unlink+0x1b0>
  ilock(ip);
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	1d6080e7          	jalr	470(ra) # 80003b98 <ilock>
  if(ip->nlink < 1)
    800059ca:	04a91783          	lh	a5,74(s2)
    800059ce:	08f05263          	blez	a5,80005a52 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059d2:	04491703          	lh	a4,68(s2)
    800059d6:	4785                	li	a5,1
    800059d8:	08f70563          	beq	a4,a5,80005a62 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059dc:	4641                	li	a2,16
    800059de:	4581                	li	a1,0
    800059e0:	fc040513          	addi	a0,s0,-64
    800059e4:	ffffb097          	auipc	ra,0xffffb
    800059e8:	2fc080e7          	jalr	764(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059ec:	4741                	li	a4,16
    800059ee:	f2c42683          	lw	a3,-212(s0)
    800059f2:	fc040613          	addi	a2,s0,-64
    800059f6:	4581                	li	a1,0
    800059f8:	8526                	mv	a0,s1
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	54a080e7          	jalr	1354(ra) # 80003f44 <writei>
    80005a02:	47c1                	li	a5,16
    80005a04:	0af51563          	bne	a0,a5,80005aae <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a08:	04491703          	lh	a4,68(s2)
    80005a0c:	4785                	li	a5,1
    80005a0e:	0af70863          	beq	a4,a5,80005abe <sys_unlink+0x18c>
  iunlockput(dp);
    80005a12:	8526                	mv	a0,s1
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	3e6080e7          	jalr	998(ra) # 80003dfa <iunlockput>
  ip->nlink--;
    80005a1c:	04a95783          	lhu	a5,74(s2)
    80005a20:	37fd                	addiw	a5,a5,-1
    80005a22:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a26:	854a                	mv	a0,s2
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	0a6080e7          	jalr	166(ra) # 80003ace <iupdate>
  iunlockput(ip);
    80005a30:	854a                	mv	a0,s2
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	3c8080e7          	jalr	968(ra) # 80003dfa <iunlockput>
  end_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	bb0080e7          	jalr	-1104(ra) # 800045ea <end_op>
  return 0;
    80005a42:	4501                	li	a0,0
    80005a44:	a84d                	j	80005af6 <sys_unlink+0x1c4>
    end_op();
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	ba4080e7          	jalr	-1116(ra) # 800045ea <end_op>
    return -1;
    80005a4e:	557d                	li	a0,-1
    80005a50:	a05d                	j	80005af6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a52:	00003517          	auipc	a0,0x3
    80005a56:	e8e50513          	addi	a0,a0,-370 # 800088e0 <syscalls+0x2f0>
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	ae4080e7          	jalr	-1308(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a62:	04c92703          	lw	a4,76(s2)
    80005a66:	02000793          	li	a5,32
    80005a6a:	f6e7f9e3          	bgeu	a5,a4,800059dc <sys_unlink+0xaa>
    80005a6e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a72:	4741                	li	a4,16
    80005a74:	86ce                	mv	a3,s3
    80005a76:	f1840613          	addi	a2,s0,-232
    80005a7a:	4581                	li	a1,0
    80005a7c:	854a                	mv	a0,s2
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	3ce080e7          	jalr	974(ra) # 80003e4c <readi>
    80005a86:	47c1                	li	a5,16
    80005a88:	00f51b63          	bne	a0,a5,80005a9e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a8c:	f1845783          	lhu	a5,-232(s0)
    80005a90:	e7a1                	bnez	a5,80005ad8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a92:	29c1                	addiw	s3,s3,16
    80005a94:	04c92783          	lw	a5,76(s2)
    80005a98:	fcf9ede3          	bltu	s3,a5,80005a72 <sys_unlink+0x140>
    80005a9c:	b781                	j	800059dc <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a9e:	00003517          	auipc	a0,0x3
    80005aa2:	e5a50513          	addi	a0,a0,-422 # 800088f8 <syscalls+0x308>
    80005aa6:	ffffb097          	auipc	ra,0xffffb
    80005aaa:	a98080e7          	jalr	-1384(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005aae:	00003517          	auipc	a0,0x3
    80005ab2:	e6250513          	addi	a0,a0,-414 # 80008910 <syscalls+0x320>
    80005ab6:	ffffb097          	auipc	ra,0xffffb
    80005aba:	a88080e7          	jalr	-1400(ra) # 8000053e <panic>
    dp->nlink--;
    80005abe:	04a4d783          	lhu	a5,74(s1)
    80005ac2:	37fd                	addiw	a5,a5,-1
    80005ac4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ac8:	8526                	mv	a0,s1
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	004080e7          	jalr	4(ra) # 80003ace <iupdate>
    80005ad2:	b781                	j	80005a12 <sys_unlink+0xe0>
    return -1;
    80005ad4:	557d                	li	a0,-1
    80005ad6:	a005                	j	80005af6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ad8:	854a                	mv	a0,s2
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	320080e7          	jalr	800(ra) # 80003dfa <iunlockput>
  iunlockput(dp);
    80005ae2:	8526                	mv	a0,s1
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	316080e7          	jalr	790(ra) # 80003dfa <iunlockput>
  end_op();
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	afe080e7          	jalr	-1282(ra) # 800045ea <end_op>
  return -1;
    80005af4:	557d                	li	a0,-1
}
    80005af6:	70ae                	ld	ra,232(sp)
    80005af8:	740e                	ld	s0,224(sp)
    80005afa:	64ee                	ld	s1,216(sp)
    80005afc:	694e                	ld	s2,208(sp)
    80005afe:	69ae                	ld	s3,200(sp)
    80005b00:	616d                	addi	sp,sp,240
    80005b02:	8082                	ret

0000000080005b04 <sys_open>:

uint64
sys_open(void)
{
    80005b04:	7131                	addi	sp,sp,-192
    80005b06:	fd06                	sd	ra,184(sp)
    80005b08:	f922                	sd	s0,176(sp)
    80005b0a:	f526                	sd	s1,168(sp)
    80005b0c:	f14a                	sd	s2,160(sp)
    80005b0e:	ed4e                	sd	s3,152(sp)
    80005b10:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b12:	08000613          	li	a2,128
    80005b16:	f5040593          	addi	a1,s0,-176
    80005b1a:	4501                	li	a0,0
    80005b1c:	ffffd097          	auipc	ra,0xffffd
    80005b20:	282080e7          	jalr	642(ra) # 80002d9e <argstr>
    return -1;
    80005b24:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b26:	0c054163          	bltz	a0,80005be8 <sys_open+0xe4>
    80005b2a:	f4c40593          	addi	a1,s0,-180
    80005b2e:	4505                	li	a0,1
    80005b30:	ffffd097          	auipc	ra,0xffffd
    80005b34:	22a080e7          	jalr	554(ra) # 80002d5a <argint>
    80005b38:	0a054863          	bltz	a0,80005be8 <sys_open+0xe4>

  begin_op();
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	a2e080e7          	jalr	-1490(ra) # 8000456a <begin_op>

  if(omode & O_CREATE){
    80005b44:	f4c42783          	lw	a5,-180(s0)
    80005b48:	2007f793          	andi	a5,a5,512
    80005b4c:	cbdd                	beqz	a5,80005c02 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b4e:	4681                	li	a3,0
    80005b50:	4601                	li	a2,0
    80005b52:	4589                	li	a1,2
    80005b54:	f5040513          	addi	a0,s0,-176
    80005b58:	00000097          	auipc	ra,0x0
    80005b5c:	972080e7          	jalr	-1678(ra) # 800054ca <create>
    80005b60:	892a                	mv	s2,a0
    if(ip == 0){
    80005b62:	c959                	beqz	a0,80005bf8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b64:	04491703          	lh	a4,68(s2)
    80005b68:	478d                	li	a5,3
    80005b6a:	00f71763          	bne	a4,a5,80005b78 <sys_open+0x74>
    80005b6e:	04695703          	lhu	a4,70(s2)
    80005b72:	47a5                	li	a5,9
    80005b74:	0ce7ec63          	bltu	a5,a4,80005c4c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	e02080e7          	jalr	-510(ra) # 8000497a <filealloc>
    80005b80:	89aa                	mv	s3,a0
    80005b82:	10050263          	beqz	a0,80005c86 <sys_open+0x182>
    80005b86:	00000097          	auipc	ra,0x0
    80005b8a:	902080e7          	jalr	-1790(ra) # 80005488 <fdalloc>
    80005b8e:	84aa                	mv	s1,a0
    80005b90:	0e054663          	bltz	a0,80005c7c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b94:	04491703          	lh	a4,68(s2)
    80005b98:	478d                	li	a5,3
    80005b9a:	0cf70463          	beq	a4,a5,80005c62 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b9e:	4789                	li	a5,2
    80005ba0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ba4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ba8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005bac:	f4c42783          	lw	a5,-180(s0)
    80005bb0:	0017c713          	xori	a4,a5,1
    80005bb4:	8b05                	andi	a4,a4,1
    80005bb6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bba:	0037f713          	andi	a4,a5,3
    80005bbe:	00e03733          	snez	a4,a4
    80005bc2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bc6:	4007f793          	andi	a5,a5,1024
    80005bca:	c791                	beqz	a5,80005bd6 <sys_open+0xd2>
    80005bcc:	04491703          	lh	a4,68(s2)
    80005bd0:	4789                	li	a5,2
    80005bd2:	08f70f63          	beq	a4,a5,80005c70 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bd6:	854a                	mv	a0,s2
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	082080e7          	jalr	130(ra) # 80003c5a <iunlock>
  end_op();
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	a0a080e7          	jalr	-1526(ra) # 800045ea <end_op>

  return fd;
}
    80005be8:	8526                	mv	a0,s1
    80005bea:	70ea                	ld	ra,184(sp)
    80005bec:	744a                	ld	s0,176(sp)
    80005bee:	74aa                	ld	s1,168(sp)
    80005bf0:	790a                	ld	s2,160(sp)
    80005bf2:	69ea                	ld	s3,152(sp)
    80005bf4:	6129                	addi	sp,sp,192
    80005bf6:	8082                	ret
      end_op();
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	9f2080e7          	jalr	-1550(ra) # 800045ea <end_op>
      return -1;
    80005c00:	b7e5                	j	80005be8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c02:	f5040513          	addi	a0,s0,-176
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	748080e7          	jalr	1864(ra) # 8000434e <namei>
    80005c0e:	892a                	mv	s2,a0
    80005c10:	c905                	beqz	a0,80005c40 <sys_open+0x13c>
    ilock(ip);
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	f86080e7          	jalr	-122(ra) # 80003b98 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c1a:	04491703          	lh	a4,68(s2)
    80005c1e:	4785                	li	a5,1
    80005c20:	f4f712e3          	bne	a4,a5,80005b64 <sys_open+0x60>
    80005c24:	f4c42783          	lw	a5,-180(s0)
    80005c28:	dba1                	beqz	a5,80005b78 <sys_open+0x74>
      iunlockput(ip);
    80005c2a:	854a                	mv	a0,s2
    80005c2c:	ffffe097          	auipc	ra,0xffffe
    80005c30:	1ce080e7          	jalr	462(ra) # 80003dfa <iunlockput>
      end_op();
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	9b6080e7          	jalr	-1610(ra) # 800045ea <end_op>
      return -1;
    80005c3c:	54fd                	li	s1,-1
    80005c3e:	b76d                	j	80005be8 <sys_open+0xe4>
      end_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	9aa080e7          	jalr	-1622(ra) # 800045ea <end_op>
      return -1;
    80005c48:	54fd                	li	s1,-1
    80005c4a:	bf79                	j	80005be8 <sys_open+0xe4>
    iunlockput(ip);
    80005c4c:	854a                	mv	a0,s2
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	1ac080e7          	jalr	428(ra) # 80003dfa <iunlockput>
    end_op();
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	994080e7          	jalr	-1644(ra) # 800045ea <end_op>
    return -1;
    80005c5e:	54fd                	li	s1,-1
    80005c60:	b761                	j	80005be8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c62:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c66:	04691783          	lh	a5,70(s2)
    80005c6a:	02f99223          	sh	a5,36(s3)
    80005c6e:	bf2d                	j	80005ba8 <sys_open+0xa4>
    itrunc(ip);
    80005c70:	854a                	mv	a0,s2
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	034080e7          	jalr	52(ra) # 80003ca6 <itrunc>
    80005c7a:	bfb1                	j	80005bd6 <sys_open+0xd2>
      fileclose(f);
    80005c7c:	854e                	mv	a0,s3
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	db8080e7          	jalr	-584(ra) # 80004a36 <fileclose>
    iunlockput(ip);
    80005c86:	854a                	mv	a0,s2
    80005c88:	ffffe097          	auipc	ra,0xffffe
    80005c8c:	172080e7          	jalr	370(ra) # 80003dfa <iunlockput>
    end_op();
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	95a080e7          	jalr	-1702(ra) # 800045ea <end_op>
    return -1;
    80005c98:	54fd                	li	s1,-1
    80005c9a:	b7b9                	j	80005be8 <sys_open+0xe4>

0000000080005c9c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c9c:	7175                	addi	sp,sp,-144
    80005c9e:	e506                	sd	ra,136(sp)
    80005ca0:	e122                	sd	s0,128(sp)
    80005ca2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ca4:	fffff097          	auipc	ra,0xfffff
    80005ca8:	8c6080e7          	jalr	-1850(ra) # 8000456a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cac:	08000613          	li	a2,128
    80005cb0:	f7040593          	addi	a1,s0,-144
    80005cb4:	4501                	li	a0,0
    80005cb6:	ffffd097          	auipc	ra,0xffffd
    80005cba:	0e8080e7          	jalr	232(ra) # 80002d9e <argstr>
    80005cbe:	02054963          	bltz	a0,80005cf0 <sys_mkdir+0x54>
    80005cc2:	4681                	li	a3,0
    80005cc4:	4601                	li	a2,0
    80005cc6:	4585                	li	a1,1
    80005cc8:	f7040513          	addi	a0,s0,-144
    80005ccc:	fffff097          	auipc	ra,0xfffff
    80005cd0:	7fe080e7          	jalr	2046(ra) # 800054ca <create>
    80005cd4:	cd11                	beqz	a0,80005cf0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	124080e7          	jalr	292(ra) # 80003dfa <iunlockput>
  end_op();
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	90c080e7          	jalr	-1780(ra) # 800045ea <end_op>
  return 0;
    80005ce6:	4501                	li	a0,0
}
    80005ce8:	60aa                	ld	ra,136(sp)
    80005cea:	640a                	ld	s0,128(sp)
    80005cec:	6149                	addi	sp,sp,144
    80005cee:	8082                	ret
    end_op();
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	8fa080e7          	jalr	-1798(ra) # 800045ea <end_op>
    return -1;
    80005cf8:	557d                	li	a0,-1
    80005cfa:	b7fd                	j	80005ce8 <sys_mkdir+0x4c>

0000000080005cfc <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cfc:	7135                	addi	sp,sp,-160
    80005cfe:	ed06                	sd	ra,152(sp)
    80005d00:	e922                	sd	s0,144(sp)
    80005d02:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	866080e7          	jalr	-1946(ra) # 8000456a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d0c:	08000613          	li	a2,128
    80005d10:	f7040593          	addi	a1,s0,-144
    80005d14:	4501                	li	a0,0
    80005d16:	ffffd097          	auipc	ra,0xffffd
    80005d1a:	088080e7          	jalr	136(ra) # 80002d9e <argstr>
    80005d1e:	04054a63          	bltz	a0,80005d72 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d22:	f6c40593          	addi	a1,s0,-148
    80005d26:	4505                	li	a0,1
    80005d28:	ffffd097          	auipc	ra,0xffffd
    80005d2c:	032080e7          	jalr	50(ra) # 80002d5a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d30:	04054163          	bltz	a0,80005d72 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d34:	f6840593          	addi	a1,s0,-152
    80005d38:	4509                	li	a0,2
    80005d3a:	ffffd097          	auipc	ra,0xffffd
    80005d3e:	020080e7          	jalr	32(ra) # 80002d5a <argint>
     argint(1, &major) < 0 ||
    80005d42:	02054863          	bltz	a0,80005d72 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d46:	f6841683          	lh	a3,-152(s0)
    80005d4a:	f6c41603          	lh	a2,-148(s0)
    80005d4e:	458d                	li	a1,3
    80005d50:	f7040513          	addi	a0,s0,-144
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	776080e7          	jalr	1910(ra) # 800054ca <create>
     argint(2, &minor) < 0 ||
    80005d5c:	c919                	beqz	a0,80005d72 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d5e:	ffffe097          	auipc	ra,0xffffe
    80005d62:	09c080e7          	jalr	156(ra) # 80003dfa <iunlockput>
  end_op();
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	884080e7          	jalr	-1916(ra) # 800045ea <end_op>
  return 0;
    80005d6e:	4501                	li	a0,0
    80005d70:	a031                	j	80005d7c <sys_mknod+0x80>
    end_op();
    80005d72:	fffff097          	auipc	ra,0xfffff
    80005d76:	878080e7          	jalr	-1928(ra) # 800045ea <end_op>
    return -1;
    80005d7a:	557d                	li	a0,-1
}
    80005d7c:	60ea                	ld	ra,152(sp)
    80005d7e:	644a                	ld	s0,144(sp)
    80005d80:	610d                	addi	sp,sp,160
    80005d82:	8082                	ret

0000000080005d84 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d84:	7135                	addi	sp,sp,-160
    80005d86:	ed06                	sd	ra,152(sp)
    80005d88:	e922                	sd	s0,144(sp)
    80005d8a:	e526                	sd	s1,136(sp)
    80005d8c:	e14a                	sd	s2,128(sp)
    80005d8e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d90:	ffffc097          	auipc	ra,0xffffc
    80005d94:	c9c080e7          	jalr	-868(ra) # 80001a2c <myproc>
    80005d98:	892a                	mv	s2,a0
  
  begin_op();
    80005d9a:	ffffe097          	auipc	ra,0xffffe
    80005d9e:	7d0080e7          	jalr	2000(ra) # 8000456a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005da2:	08000613          	li	a2,128
    80005da6:	f6040593          	addi	a1,s0,-160
    80005daa:	4501                	li	a0,0
    80005dac:	ffffd097          	auipc	ra,0xffffd
    80005db0:	ff2080e7          	jalr	-14(ra) # 80002d9e <argstr>
    80005db4:	04054b63          	bltz	a0,80005e0a <sys_chdir+0x86>
    80005db8:	f6040513          	addi	a0,s0,-160
    80005dbc:	ffffe097          	auipc	ra,0xffffe
    80005dc0:	592080e7          	jalr	1426(ra) # 8000434e <namei>
    80005dc4:	84aa                	mv	s1,a0
    80005dc6:	c131                	beqz	a0,80005e0a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	dd0080e7          	jalr	-560(ra) # 80003b98 <ilock>
  if(ip->type != T_DIR){
    80005dd0:	04449703          	lh	a4,68(s1)
    80005dd4:	4785                	li	a5,1
    80005dd6:	04f71063          	bne	a4,a5,80005e16 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dda:	8526                	mv	a0,s1
    80005ddc:	ffffe097          	auipc	ra,0xffffe
    80005de0:	e7e080e7          	jalr	-386(ra) # 80003c5a <iunlock>
  iput(p->cwd);
    80005de4:	15093503          	ld	a0,336(s2)
    80005de8:	ffffe097          	auipc	ra,0xffffe
    80005dec:	f6a080e7          	jalr	-150(ra) # 80003d52 <iput>
  end_op();
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	7fa080e7          	jalr	2042(ra) # 800045ea <end_op>
  p->cwd = ip;
    80005df8:	14993823          	sd	s1,336(s2)
  return 0;
    80005dfc:	4501                	li	a0,0
}
    80005dfe:	60ea                	ld	ra,152(sp)
    80005e00:	644a                	ld	s0,144(sp)
    80005e02:	64aa                	ld	s1,136(sp)
    80005e04:	690a                	ld	s2,128(sp)
    80005e06:	610d                	addi	sp,sp,160
    80005e08:	8082                	ret
    end_op();
    80005e0a:	ffffe097          	auipc	ra,0xffffe
    80005e0e:	7e0080e7          	jalr	2016(ra) # 800045ea <end_op>
    return -1;
    80005e12:	557d                	li	a0,-1
    80005e14:	b7ed                	j	80005dfe <sys_chdir+0x7a>
    iunlockput(ip);
    80005e16:	8526                	mv	a0,s1
    80005e18:	ffffe097          	auipc	ra,0xffffe
    80005e1c:	fe2080e7          	jalr	-30(ra) # 80003dfa <iunlockput>
    end_op();
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	7ca080e7          	jalr	1994(ra) # 800045ea <end_op>
    return -1;
    80005e28:	557d                	li	a0,-1
    80005e2a:	bfd1                	j	80005dfe <sys_chdir+0x7a>

0000000080005e2c <sys_exec>:

uint64
sys_exec(void)
{
    80005e2c:	7145                	addi	sp,sp,-464
    80005e2e:	e786                	sd	ra,456(sp)
    80005e30:	e3a2                	sd	s0,448(sp)
    80005e32:	ff26                	sd	s1,440(sp)
    80005e34:	fb4a                	sd	s2,432(sp)
    80005e36:	f74e                	sd	s3,424(sp)
    80005e38:	f352                	sd	s4,416(sp)
    80005e3a:	ef56                	sd	s5,408(sp)
    80005e3c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e3e:	08000613          	li	a2,128
    80005e42:	f4040593          	addi	a1,s0,-192
    80005e46:	4501                	li	a0,0
    80005e48:	ffffd097          	auipc	ra,0xffffd
    80005e4c:	f56080e7          	jalr	-170(ra) # 80002d9e <argstr>
    return -1;
    80005e50:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e52:	0c054a63          	bltz	a0,80005f26 <sys_exec+0xfa>
    80005e56:	e3840593          	addi	a1,s0,-456
    80005e5a:	4505                	li	a0,1
    80005e5c:	ffffd097          	auipc	ra,0xffffd
    80005e60:	f20080e7          	jalr	-224(ra) # 80002d7c <argaddr>
    80005e64:	0c054163          	bltz	a0,80005f26 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e68:	10000613          	li	a2,256
    80005e6c:	4581                	li	a1,0
    80005e6e:	e4040513          	addi	a0,s0,-448
    80005e72:	ffffb097          	auipc	ra,0xffffb
    80005e76:	e6e080e7          	jalr	-402(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e7a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e7e:	89a6                	mv	s3,s1
    80005e80:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e82:	02000a13          	li	s4,32
    80005e86:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e8a:	00391513          	slli	a0,s2,0x3
    80005e8e:	e3040593          	addi	a1,s0,-464
    80005e92:	e3843783          	ld	a5,-456(s0)
    80005e96:	953e                	add	a0,a0,a5
    80005e98:	ffffd097          	auipc	ra,0xffffd
    80005e9c:	e28080e7          	jalr	-472(ra) # 80002cc0 <fetchaddr>
    80005ea0:	02054a63          	bltz	a0,80005ed4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ea4:	e3043783          	ld	a5,-464(s0)
    80005ea8:	c3b9                	beqz	a5,80005eee <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005eaa:	ffffb097          	auipc	ra,0xffffb
    80005eae:	c4a080e7          	jalr	-950(ra) # 80000af4 <kalloc>
    80005eb2:	85aa                	mv	a1,a0
    80005eb4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005eb8:	cd11                	beqz	a0,80005ed4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005eba:	6605                	lui	a2,0x1
    80005ebc:	e3043503          	ld	a0,-464(s0)
    80005ec0:	ffffd097          	auipc	ra,0xffffd
    80005ec4:	e52080e7          	jalr	-430(ra) # 80002d12 <fetchstr>
    80005ec8:	00054663          	bltz	a0,80005ed4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ecc:	0905                	addi	s2,s2,1
    80005ece:	09a1                	addi	s3,s3,8
    80005ed0:	fb491be3          	bne	s2,s4,80005e86 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ed4:	10048913          	addi	s2,s1,256
    80005ed8:	6088                	ld	a0,0(s1)
    80005eda:	c529                	beqz	a0,80005f24 <sys_exec+0xf8>
    kfree(argv[i]);
    80005edc:	ffffb097          	auipc	ra,0xffffb
    80005ee0:	b1c080e7          	jalr	-1252(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ee4:	04a1                	addi	s1,s1,8
    80005ee6:	ff2499e3          	bne	s1,s2,80005ed8 <sys_exec+0xac>
  return -1;
    80005eea:	597d                	li	s2,-1
    80005eec:	a82d                	j	80005f26 <sys_exec+0xfa>
      argv[i] = 0;
    80005eee:	0a8e                	slli	s5,s5,0x3
    80005ef0:	fc040793          	addi	a5,s0,-64
    80005ef4:	9abe                	add	s5,s5,a5
    80005ef6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005efa:	e4040593          	addi	a1,s0,-448
    80005efe:	f4040513          	addi	a0,s0,-192
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	194080e7          	jalr	404(ra) # 80005096 <exec>
    80005f0a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f0c:	10048993          	addi	s3,s1,256
    80005f10:	6088                	ld	a0,0(s1)
    80005f12:	c911                	beqz	a0,80005f26 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f14:	ffffb097          	auipc	ra,0xffffb
    80005f18:	ae4080e7          	jalr	-1308(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f1c:	04a1                	addi	s1,s1,8
    80005f1e:	ff3499e3          	bne	s1,s3,80005f10 <sys_exec+0xe4>
    80005f22:	a011                	j	80005f26 <sys_exec+0xfa>
  return -1;
    80005f24:	597d                	li	s2,-1
}
    80005f26:	854a                	mv	a0,s2
    80005f28:	60be                	ld	ra,456(sp)
    80005f2a:	641e                	ld	s0,448(sp)
    80005f2c:	74fa                	ld	s1,440(sp)
    80005f2e:	795a                	ld	s2,432(sp)
    80005f30:	79ba                	ld	s3,424(sp)
    80005f32:	7a1a                	ld	s4,416(sp)
    80005f34:	6afa                	ld	s5,408(sp)
    80005f36:	6179                	addi	sp,sp,464
    80005f38:	8082                	ret

0000000080005f3a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f3a:	7139                	addi	sp,sp,-64
    80005f3c:	fc06                	sd	ra,56(sp)
    80005f3e:	f822                	sd	s0,48(sp)
    80005f40:	f426                	sd	s1,40(sp)
    80005f42:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f44:	ffffc097          	auipc	ra,0xffffc
    80005f48:	ae8080e7          	jalr	-1304(ra) # 80001a2c <myproc>
    80005f4c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f4e:	fd840593          	addi	a1,s0,-40
    80005f52:	4501                	li	a0,0
    80005f54:	ffffd097          	auipc	ra,0xffffd
    80005f58:	e28080e7          	jalr	-472(ra) # 80002d7c <argaddr>
    return -1;
    80005f5c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f5e:	0e054063          	bltz	a0,8000603e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f62:	fc840593          	addi	a1,s0,-56
    80005f66:	fd040513          	addi	a0,s0,-48
    80005f6a:	fffff097          	auipc	ra,0xfffff
    80005f6e:	dfc080e7          	jalr	-516(ra) # 80004d66 <pipealloc>
    return -1;
    80005f72:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f74:	0c054563          	bltz	a0,8000603e <sys_pipe+0x104>
  fd0 = -1;
    80005f78:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f7c:	fd043503          	ld	a0,-48(s0)
    80005f80:	fffff097          	auipc	ra,0xfffff
    80005f84:	508080e7          	jalr	1288(ra) # 80005488 <fdalloc>
    80005f88:	fca42223          	sw	a0,-60(s0)
    80005f8c:	08054c63          	bltz	a0,80006024 <sys_pipe+0xea>
    80005f90:	fc843503          	ld	a0,-56(s0)
    80005f94:	fffff097          	auipc	ra,0xfffff
    80005f98:	4f4080e7          	jalr	1268(ra) # 80005488 <fdalloc>
    80005f9c:	fca42023          	sw	a0,-64(s0)
    80005fa0:	06054863          	bltz	a0,80006010 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fa4:	4691                	li	a3,4
    80005fa6:	fc440613          	addi	a2,s0,-60
    80005faa:	fd843583          	ld	a1,-40(s0)
    80005fae:	68a8                	ld	a0,80(s1)
    80005fb0:	ffffb097          	auipc	ra,0xffffb
    80005fb4:	6c2080e7          	jalr	1730(ra) # 80001672 <copyout>
    80005fb8:	02054063          	bltz	a0,80005fd8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fbc:	4691                	li	a3,4
    80005fbe:	fc040613          	addi	a2,s0,-64
    80005fc2:	fd843583          	ld	a1,-40(s0)
    80005fc6:	0591                	addi	a1,a1,4
    80005fc8:	68a8                	ld	a0,80(s1)
    80005fca:	ffffb097          	auipc	ra,0xffffb
    80005fce:	6a8080e7          	jalr	1704(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fd2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fd4:	06055563          	bgez	a0,8000603e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fd8:	fc442783          	lw	a5,-60(s0)
    80005fdc:	07e9                	addi	a5,a5,26
    80005fde:	078e                	slli	a5,a5,0x3
    80005fe0:	97a6                	add	a5,a5,s1
    80005fe2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fe6:	fc042503          	lw	a0,-64(s0)
    80005fea:	0569                	addi	a0,a0,26
    80005fec:	050e                	slli	a0,a0,0x3
    80005fee:	9526                	add	a0,a0,s1
    80005ff0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ff4:	fd043503          	ld	a0,-48(s0)
    80005ff8:	fffff097          	auipc	ra,0xfffff
    80005ffc:	a3e080e7          	jalr	-1474(ra) # 80004a36 <fileclose>
    fileclose(wf);
    80006000:	fc843503          	ld	a0,-56(s0)
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	a32080e7          	jalr	-1486(ra) # 80004a36 <fileclose>
    return -1;
    8000600c:	57fd                	li	a5,-1
    8000600e:	a805                	j	8000603e <sys_pipe+0x104>
    if(fd0 >= 0)
    80006010:	fc442783          	lw	a5,-60(s0)
    80006014:	0007c863          	bltz	a5,80006024 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006018:	01a78513          	addi	a0,a5,26
    8000601c:	050e                	slli	a0,a0,0x3
    8000601e:	9526                	add	a0,a0,s1
    80006020:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006024:	fd043503          	ld	a0,-48(s0)
    80006028:	fffff097          	auipc	ra,0xfffff
    8000602c:	a0e080e7          	jalr	-1522(ra) # 80004a36 <fileclose>
    fileclose(wf);
    80006030:	fc843503          	ld	a0,-56(s0)
    80006034:	fffff097          	auipc	ra,0xfffff
    80006038:	a02080e7          	jalr	-1534(ra) # 80004a36 <fileclose>
    return -1;
    8000603c:	57fd                	li	a5,-1
}
    8000603e:	853e                	mv	a0,a5
    80006040:	70e2                	ld	ra,56(sp)
    80006042:	7442                	ld	s0,48(sp)
    80006044:	74a2                	ld	s1,40(sp)
    80006046:	6121                	addi	sp,sp,64
    80006048:	8082                	ret
    8000604a:	0000                	unimp
    8000604c:	0000                	unimp
	...

0000000080006050 <kernelvec>:
    80006050:	7111                	addi	sp,sp,-256
    80006052:	e006                	sd	ra,0(sp)
    80006054:	e40a                	sd	sp,8(sp)
    80006056:	e80e                	sd	gp,16(sp)
    80006058:	ec12                	sd	tp,24(sp)
    8000605a:	f016                	sd	t0,32(sp)
    8000605c:	f41a                	sd	t1,40(sp)
    8000605e:	f81e                	sd	t2,48(sp)
    80006060:	fc22                	sd	s0,56(sp)
    80006062:	e0a6                	sd	s1,64(sp)
    80006064:	e4aa                	sd	a0,72(sp)
    80006066:	e8ae                	sd	a1,80(sp)
    80006068:	ecb2                	sd	a2,88(sp)
    8000606a:	f0b6                	sd	a3,96(sp)
    8000606c:	f4ba                	sd	a4,104(sp)
    8000606e:	f8be                	sd	a5,112(sp)
    80006070:	fcc2                	sd	a6,120(sp)
    80006072:	e146                	sd	a7,128(sp)
    80006074:	e54a                	sd	s2,136(sp)
    80006076:	e94e                	sd	s3,144(sp)
    80006078:	ed52                	sd	s4,152(sp)
    8000607a:	f156                	sd	s5,160(sp)
    8000607c:	f55a                	sd	s6,168(sp)
    8000607e:	f95e                	sd	s7,176(sp)
    80006080:	fd62                	sd	s8,184(sp)
    80006082:	e1e6                	sd	s9,192(sp)
    80006084:	e5ea                	sd	s10,200(sp)
    80006086:	e9ee                	sd	s11,208(sp)
    80006088:	edf2                	sd	t3,216(sp)
    8000608a:	f1f6                	sd	t4,224(sp)
    8000608c:	f5fa                	sd	t5,232(sp)
    8000608e:	f9fe                	sd	t6,240(sp)
    80006090:	afdfc0ef          	jal	ra,80002b8c <kerneltrap>
    80006094:	6082                	ld	ra,0(sp)
    80006096:	6122                	ld	sp,8(sp)
    80006098:	61c2                	ld	gp,16(sp)
    8000609a:	7282                	ld	t0,32(sp)
    8000609c:	7322                	ld	t1,40(sp)
    8000609e:	73c2                	ld	t2,48(sp)
    800060a0:	7462                	ld	s0,56(sp)
    800060a2:	6486                	ld	s1,64(sp)
    800060a4:	6526                	ld	a0,72(sp)
    800060a6:	65c6                	ld	a1,80(sp)
    800060a8:	6666                	ld	a2,88(sp)
    800060aa:	7686                	ld	a3,96(sp)
    800060ac:	7726                	ld	a4,104(sp)
    800060ae:	77c6                	ld	a5,112(sp)
    800060b0:	7866                	ld	a6,120(sp)
    800060b2:	688a                	ld	a7,128(sp)
    800060b4:	692a                	ld	s2,136(sp)
    800060b6:	69ca                	ld	s3,144(sp)
    800060b8:	6a6a                	ld	s4,152(sp)
    800060ba:	7a8a                	ld	s5,160(sp)
    800060bc:	7b2a                	ld	s6,168(sp)
    800060be:	7bca                	ld	s7,176(sp)
    800060c0:	7c6a                	ld	s8,184(sp)
    800060c2:	6c8e                	ld	s9,192(sp)
    800060c4:	6d2e                	ld	s10,200(sp)
    800060c6:	6dce                	ld	s11,208(sp)
    800060c8:	6e6e                	ld	t3,216(sp)
    800060ca:	7e8e                	ld	t4,224(sp)
    800060cc:	7f2e                	ld	t5,232(sp)
    800060ce:	7fce                	ld	t6,240(sp)
    800060d0:	6111                	addi	sp,sp,256
    800060d2:	10200073          	sret
    800060d6:	00000013          	nop
    800060da:	00000013          	nop
    800060de:	0001                	nop

00000000800060e0 <timervec>:
    800060e0:	34051573          	csrrw	a0,mscratch,a0
    800060e4:	e10c                	sd	a1,0(a0)
    800060e6:	e510                	sd	a2,8(a0)
    800060e8:	e914                	sd	a3,16(a0)
    800060ea:	6d0c                	ld	a1,24(a0)
    800060ec:	7110                	ld	a2,32(a0)
    800060ee:	6194                	ld	a3,0(a1)
    800060f0:	96b2                	add	a3,a3,a2
    800060f2:	e194                	sd	a3,0(a1)
    800060f4:	4589                	li	a1,2
    800060f6:	14459073          	csrw	sip,a1
    800060fa:	6914                	ld	a3,16(a0)
    800060fc:	6510                	ld	a2,8(a0)
    800060fe:	610c                	ld	a1,0(a0)
    80006100:	34051573          	csrrw	a0,mscratch,a0
    80006104:	30200073          	mret
	...

000000008000610a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000610a:	1141                	addi	sp,sp,-16
    8000610c:	e422                	sd	s0,8(sp)
    8000610e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006110:	0c0007b7          	lui	a5,0xc000
    80006114:	4705                	li	a4,1
    80006116:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006118:	c3d8                	sw	a4,4(a5)
}
    8000611a:	6422                	ld	s0,8(sp)
    8000611c:	0141                	addi	sp,sp,16
    8000611e:	8082                	ret

0000000080006120 <plicinithart>:

void
plicinithart(void)
{
    80006120:	1141                	addi	sp,sp,-16
    80006122:	e406                	sd	ra,8(sp)
    80006124:	e022                	sd	s0,0(sp)
    80006126:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006128:	ffffc097          	auipc	ra,0xffffc
    8000612c:	8d8080e7          	jalr	-1832(ra) # 80001a00 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006130:	0085171b          	slliw	a4,a0,0x8
    80006134:	0c0027b7          	lui	a5,0xc002
    80006138:	97ba                	add	a5,a5,a4
    8000613a:	40200713          	li	a4,1026
    8000613e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006142:	00d5151b          	slliw	a0,a0,0xd
    80006146:	0c2017b7          	lui	a5,0xc201
    8000614a:	953e                	add	a0,a0,a5
    8000614c:	00052023          	sw	zero,0(a0)
}
    80006150:	60a2                	ld	ra,8(sp)
    80006152:	6402                	ld	s0,0(sp)
    80006154:	0141                	addi	sp,sp,16
    80006156:	8082                	ret

0000000080006158 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006158:	1141                	addi	sp,sp,-16
    8000615a:	e406                	sd	ra,8(sp)
    8000615c:	e022                	sd	s0,0(sp)
    8000615e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006160:	ffffc097          	auipc	ra,0xffffc
    80006164:	8a0080e7          	jalr	-1888(ra) # 80001a00 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006168:	00d5179b          	slliw	a5,a0,0xd
    8000616c:	0c201537          	lui	a0,0xc201
    80006170:	953e                	add	a0,a0,a5
  return irq;
}
    80006172:	4148                	lw	a0,4(a0)
    80006174:	60a2                	ld	ra,8(sp)
    80006176:	6402                	ld	s0,0(sp)
    80006178:	0141                	addi	sp,sp,16
    8000617a:	8082                	ret

000000008000617c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000617c:	1101                	addi	sp,sp,-32
    8000617e:	ec06                	sd	ra,24(sp)
    80006180:	e822                	sd	s0,16(sp)
    80006182:	e426                	sd	s1,8(sp)
    80006184:	1000                	addi	s0,sp,32
    80006186:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006188:	ffffc097          	auipc	ra,0xffffc
    8000618c:	878080e7          	jalr	-1928(ra) # 80001a00 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006190:	00d5151b          	slliw	a0,a0,0xd
    80006194:	0c2017b7          	lui	a5,0xc201
    80006198:	97aa                	add	a5,a5,a0
    8000619a:	c3c4                	sw	s1,4(a5)
}
    8000619c:	60e2                	ld	ra,24(sp)
    8000619e:	6442                	ld	s0,16(sp)
    800061a0:	64a2                	ld	s1,8(sp)
    800061a2:	6105                	addi	sp,sp,32
    800061a4:	8082                	ret

00000000800061a6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061a6:	1141                	addi	sp,sp,-16
    800061a8:	e406                	sd	ra,8(sp)
    800061aa:	e022                	sd	s0,0(sp)
    800061ac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061ae:	479d                	li	a5,7
    800061b0:	06a7c963          	blt	a5,a0,80006222 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800061b4:	0001d797          	auipc	a5,0x1d
    800061b8:	e4c78793          	addi	a5,a5,-436 # 80023000 <disk>
    800061bc:	00a78733          	add	a4,a5,a0
    800061c0:	6789                	lui	a5,0x2
    800061c2:	97ba                	add	a5,a5,a4
    800061c4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800061c8:	e7ad                	bnez	a5,80006232 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061ca:	00451793          	slli	a5,a0,0x4
    800061ce:	0001f717          	auipc	a4,0x1f
    800061d2:	e3270713          	addi	a4,a4,-462 # 80025000 <disk+0x2000>
    800061d6:	6314                	ld	a3,0(a4)
    800061d8:	96be                	add	a3,a3,a5
    800061da:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061de:	6314                	ld	a3,0(a4)
    800061e0:	96be                	add	a3,a3,a5
    800061e2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061e6:	6314                	ld	a3,0(a4)
    800061e8:	96be                	add	a3,a3,a5
    800061ea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061ee:	6318                	ld	a4,0(a4)
    800061f0:	97ba                	add	a5,a5,a4
    800061f2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061f6:	0001d797          	auipc	a5,0x1d
    800061fa:	e0a78793          	addi	a5,a5,-502 # 80023000 <disk>
    800061fe:	97aa                	add	a5,a5,a0
    80006200:	6509                	lui	a0,0x2
    80006202:	953e                	add	a0,a0,a5
    80006204:	4785                	li	a5,1
    80006206:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000620a:	0001f517          	auipc	a0,0x1f
    8000620e:	e0e50513          	addi	a0,a0,-498 # 80025018 <disk+0x2018>
    80006212:	ffffc097          	auipc	ra,0xffffc
    80006216:	2ca080e7          	jalr	714(ra) # 800024dc <wakeup>
}
    8000621a:	60a2                	ld	ra,8(sp)
    8000621c:	6402                	ld	s0,0(sp)
    8000621e:	0141                	addi	sp,sp,16
    80006220:	8082                	ret
    panic("free_desc 1");
    80006222:	00002517          	auipc	a0,0x2
    80006226:	6fe50513          	addi	a0,a0,1790 # 80008920 <syscalls+0x330>
    8000622a:	ffffa097          	auipc	ra,0xffffa
    8000622e:	314080e7          	jalr	788(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006232:	00002517          	auipc	a0,0x2
    80006236:	6fe50513          	addi	a0,a0,1790 # 80008930 <syscalls+0x340>
    8000623a:	ffffa097          	auipc	ra,0xffffa
    8000623e:	304080e7          	jalr	772(ra) # 8000053e <panic>

0000000080006242 <virtio_disk_init>:
{
    80006242:	1101                	addi	sp,sp,-32
    80006244:	ec06                	sd	ra,24(sp)
    80006246:	e822                	sd	s0,16(sp)
    80006248:	e426                	sd	s1,8(sp)
    8000624a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000624c:	00002597          	auipc	a1,0x2
    80006250:	6f458593          	addi	a1,a1,1780 # 80008940 <syscalls+0x350>
    80006254:	0001f517          	auipc	a0,0x1f
    80006258:	ed450513          	addi	a0,a0,-300 # 80025128 <disk+0x2128>
    8000625c:	ffffb097          	auipc	ra,0xffffb
    80006260:	8f8080e7          	jalr	-1800(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006264:	100017b7          	lui	a5,0x10001
    80006268:	4398                	lw	a4,0(a5)
    8000626a:	2701                	sext.w	a4,a4
    8000626c:	747277b7          	lui	a5,0x74727
    80006270:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006274:	0ef71163          	bne	a4,a5,80006356 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006278:	100017b7          	lui	a5,0x10001
    8000627c:	43dc                	lw	a5,4(a5)
    8000627e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006280:	4705                	li	a4,1
    80006282:	0ce79a63          	bne	a5,a4,80006356 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006286:	100017b7          	lui	a5,0x10001
    8000628a:	479c                	lw	a5,8(a5)
    8000628c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000628e:	4709                	li	a4,2
    80006290:	0ce79363          	bne	a5,a4,80006356 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006294:	100017b7          	lui	a5,0x10001
    80006298:	47d8                	lw	a4,12(a5)
    8000629a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000629c:	554d47b7          	lui	a5,0x554d4
    800062a0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062a4:	0af71963          	bne	a4,a5,80006356 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a8:	100017b7          	lui	a5,0x10001
    800062ac:	4705                	li	a4,1
    800062ae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062b0:	470d                	li	a4,3
    800062b2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062b4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800062b6:	c7ffe737          	lui	a4,0xc7ffe
    800062ba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800062be:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062c0:	2701                	sext.w	a4,a4
    800062c2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062c4:	472d                	li	a4,11
    800062c6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062c8:	473d                	li	a4,15
    800062ca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800062cc:	6705                	lui	a4,0x1
    800062ce:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062d0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062d4:	5bdc                	lw	a5,52(a5)
    800062d6:	2781                	sext.w	a5,a5
  if(max == 0)
    800062d8:	c7d9                	beqz	a5,80006366 <virtio_disk_init+0x124>
  if(max < NUM)
    800062da:	471d                	li	a4,7
    800062dc:	08f77d63          	bgeu	a4,a5,80006376 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062e0:	100014b7          	lui	s1,0x10001
    800062e4:	47a1                	li	a5,8
    800062e6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062e8:	6609                	lui	a2,0x2
    800062ea:	4581                	li	a1,0
    800062ec:	0001d517          	auipc	a0,0x1d
    800062f0:	d1450513          	addi	a0,a0,-748 # 80023000 <disk>
    800062f4:	ffffb097          	auipc	ra,0xffffb
    800062f8:	9ec080e7          	jalr	-1556(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062fc:	0001d717          	auipc	a4,0x1d
    80006300:	d0470713          	addi	a4,a4,-764 # 80023000 <disk>
    80006304:	00c75793          	srli	a5,a4,0xc
    80006308:	2781                	sext.w	a5,a5
    8000630a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000630c:	0001f797          	auipc	a5,0x1f
    80006310:	cf478793          	addi	a5,a5,-780 # 80025000 <disk+0x2000>
    80006314:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006316:	0001d717          	auipc	a4,0x1d
    8000631a:	d6a70713          	addi	a4,a4,-662 # 80023080 <disk+0x80>
    8000631e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006320:	0001e717          	auipc	a4,0x1e
    80006324:	ce070713          	addi	a4,a4,-800 # 80024000 <disk+0x1000>
    80006328:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000632a:	4705                	li	a4,1
    8000632c:	00e78c23          	sb	a4,24(a5)
    80006330:	00e78ca3          	sb	a4,25(a5)
    80006334:	00e78d23          	sb	a4,26(a5)
    80006338:	00e78da3          	sb	a4,27(a5)
    8000633c:	00e78e23          	sb	a4,28(a5)
    80006340:	00e78ea3          	sb	a4,29(a5)
    80006344:	00e78f23          	sb	a4,30(a5)
    80006348:	00e78fa3          	sb	a4,31(a5)
}
    8000634c:	60e2                	ld	ra,24(sp)
    8000634e:	6442                	ld	s0,16(sp)
    80006350:	64a2                	ld	s1,8(sp)
    80006352:	6105                	addi	sp,sp,32
    80006354:	8082                	ret
    panic("could not find virtio disk");
    80006356:	00002517          	auipc	a0,0x2
    8000635a:	5fa50513          	addi	a0,a0,1530 # 80008950 <syscalls+0x360>
    8000635e:	ffffa097          	auipc	ra,0xffffa
    80006362:	1e0080e7          	jalr	480(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006366:	00002517          	auipc	a0,0x2
    8000636a:	60a50513          	addi	a0,a0,1546 # 80008970 <syscalls+0x380>
    8000636e:	ffffa097          	auipc	ra,0xffffa
    80006372:	1d0080e7          	jalr	464(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006376:	00002517          	auipc	a0,0x2
    8000637a:	61a50513          	addi	a0,a0,1562 # 80008990 <syscalls+0x3a0>
    8000637e:	ffffa097          	auipc	ra,0xffffa
    80006382:	1c0080e7          	jalr	448(ra) # 8000053e <panic>

0000000080006386 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006386:	7159                	addi	sp,sp,-112
    80006388:	f486                	sd	ra,104(sp)
    8000638a:	f0a2                	sd	s0,96(sp)
    8000638c:	eca6                	sd	s1,88(sp)
    8000638e:	e8ca                	sd	s2,80(sp)
    80006390:	e4ce                	sd	s3,72(sp)
    80006392:	e0d2                	sd	s4,64(sp)
    80006394:	fc56                	sd	s5,56(sp)
    80006396:	f85a                	sd	s6,48(sp)
    80006398:	f45e                	sd	s7,40(sp)
    8000639a:	f062                	sd	s8,32(sp)
    8000639c:	ec66                	sd	s9,24(sp)
    8000639e:	e86a                	sd	s10,16(sp)
    800063a0:	1880                	addi	s0,sp,112
    800063a2:	892a                	mv	s2,a0
    800063a4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063a6:	00c52c83          	lw	s9,12(a0)
    800063aa:	001c9c9b          	slliw	s9,s9,0x1
    800063ae:	1c82                	slli	s9,s9,0x20
    800063b0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800063b4:	0001f517          	auipc	a0,0x1f
    800063b8:	d7450513          	addi	a0,a0,-652 # 80025128 <disk+0x2128>
    800063bc:	ffffb097          	auipc	ra,0xffffb
    800063c0:	828080e7          	jalr	-2008(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800063c4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063c6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800063c8:	0001db97          	auipc	s7,0x1d
    800063cc:	c38b8b93          	addi	s7,s7,-968 # 80023000 <disk>
    800063d0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800063d2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800063d4:	8a4e                	mv	s4,s3
    800063d6:	a051                	j	8000645a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800063d8:	00fb86b3          	add	a3,s7,a5
    800063dc:	96da                	add	a3,a3,s6
    800063de:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800063e2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800063e4:	0207c563          	bltz	a5,8000640e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063e8:	2485                	addiw	s1,s1,1
    800063ea:	0711                	addi	a4,a4,4
    800063ec:	25548063          	beq	s1,s5,8000662c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800063f0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800063f2:	0001f697          	auipc	a3,0x1f
    800063f6:	c2668693          	addi	a3,a3,-986 # 80025018 <disk+0x2018>
    800063fa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800063fc:	0006c583          	lbu	a1,0(a3)
    80006400:	fde1                	bnez	a1,800063d8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006402:	2785                	addiw	a5,a5,1
    80006404:	0685                	addi	a3,a3,1
    80006406:	ff879be3          	bne	a5,s8,800063fc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000640a:	57fd                	li	a5,-1
    8000640c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000640e:	02905a63          	blez	s1,80006442 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006412:	f9042503          	lw	a0,-112(s0)
    80006416:	00000097          	auipc	ra,0x0
    8000641a:	d90080e7          	jalr	-624(ra) # 800061a6 <free_desc>
      for(int j = 0; j < i; j++)
    8000641e:	4785                	li	a5,1
    80006420:	0297d163          	bge	a5,s1,80006442 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006424:	f9442503          	lw	a0,-108(s0)
    80006428:	00000097          	auipc	ra,0x0
    8000642c:	d7e080e7          	jalr	-642(ra) # 800061a6 <free_desc>
      for(int j = 0; j < i; j++)
    80006430:	4789                	li	a5,2
    80006432:	0097d863          	bge	a5,s1,80006442 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006436:	f9842503          	lw	a0,-104(s0)
    8000643a:	00000097          	auipc	ra,0x0
    8000643e:	d6c080e7          	jalr	-660(ra) # 800061a6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006442:	0001f597          	auipc	a1,0x1f
    80006446:	ce658593          	addi	a1,a1,-794 # 80025128 <disk+0x2128>
    8000644a:	0001f517          	auipc	a0,0x1f
    8000644e:	bce50513          	addi	a0,a0,-1074 # 80025018 <disk+0x2018>
    80006452:	ffffc097          	auipc	ra,0xffffc
    80006456:	db2080e7          	jalr	-590(ra) # 80002204 <sleep>
  for(int i = 0; i < 3; i++){
    8000645a:	f9040713          	addi	a4,s0,-112
    8000645e:	84ce                	mv	s1,s3
    80006460:	bf41                	j	800063f0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006462:	20058713          	addi	a4,a1,512
    80006466:	00471693          	slli	a3,a4,0x4
    8000646a:	0001d717          	auipc	a4,0x1d
    8000646e:	b9670713          	addi	a4,a4,-1130 # 80023000 <disk>
    80006472:	9736                	add	a4,a4,a3
    80006474:	4685                	li	a3,1
    80006476:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000647a:	20058713          	addi	a4,a1,512
    8000647e:	00471693          	slli	a3,a4,0x4
    80006482:	0001d717          	auipc	a4,0x1d
    80006486:	b7e70713          	addi	a4,a4,-1154 # 80023000 <disk>
    8000648a:	9736                	add	a4,a4,a3
    8000648c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006490:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006494:	7679                	lui	a2,0xffffe
    80006496:	963e                	add	a2,a2,a5
    80006498:	0001f697          	auipc	a3,0x1f
    8000649c:	b6868693          	addi	a3,a3,-1176 # 80025000 <disk+0x2000>
    800064a0:	6298                	ld	a4,0(a3)
    800064a2:	9732                	add	a4,a4,a2
    800064a4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064a6:	6298                	ld	a4,0(a3)
    800064a8:	9732                	add	a4,a4,a2
    800064aa:	4541                	li	a0,16
    800064ac:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064ae:	6298                	ld	a4,0(a3)
    800064b0:	9732                	add	a4,a4,a2
    800064b2:	4505                	li	a0,1
    800064b4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800064b8:	f9442703          	lw	a4,-108(s0)
    800064bc:	6288                	ld	a0,0(a3)
    800064be:	962a                	add	a2,a2,a0
    800064c0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064c4:	0712                	slli	a4,a4,0x4
    800064c6:	6290                	ld	a2,0(a3)
    800064c8:	963a                	add	a2,a2,a4
    800064ca:	05890513          	addi	a0,s2,88
    800064ce:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800064d0:	6294                	ld	a3,0(a3)
    800064d2:	96ba                	add	a3,a3,a4
    800064d4:	40000613          	li	a2,1024
    800064d8:	c690                	sw	a2,8(a3)
  if(write)
    800064da:	140d0063          	beqz	s10,8000661a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800064de:	0001f697          	auipc	a3,0x1f
    800064e2:	b226b683          	ld	a3,-1246(a3) # 80025000 <disk+0x2000>
    800064e6:	96ba                	add	a3,a3,a4
    800064e8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064ec:	0001d817          	auipc	a6,0x1d
    800064f0:	b1480813          	addi	a6,a6,-1260 # 80023000 <disk>
    800064f4:	0001f517          	auipc	a0,0x1f
    800064f8:	b0c50513          	addi	a0,a0,-1268 # 80025000 <disk+0x2000>
    800064fc:	6114                	ld	a3,0(a0)
    800064fe:	96ba                	add	a3,a3,a4
    80006500:	00c6d603          	lhu	a2,12(a3)
    80006504:	00166613          	ori	a2,a2,1
    80006508:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000650c:	f9842683          	lw	a3,-104(s0)
    80006510:	6110                	ld	a2,0(a0)
    80006512:	9732                	add	a4,a4,a2
    80006514:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006518:	20058613          	addi	a2,a1,512
    8000651c:	0612                	slli	a2,a2,0x4
    8000651e:	9642                	add	a2,a2,a6
    80006520:	577d                	li	a4,-1
    80006522:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006526:	00469713          	slli	a4,a3,0x4
    8000652a:	6114                	ld	a3,0(a0)
    8000652c:	96ba                	add	a3,a3,a4
    8000652e:	03078793          	addi	a5,a5,48
    80006532:	97c2                	add	a5,a5,a6
    80006534:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006536:	611c                	ld	a5,0(a0)
    80006538:	97ba                	add	a5,a5,a4
    8000653a:	4685                	li	a3,1
    8000653c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000653e:	611c                	ld	a5,0(a0)
    80006540:	97ba                	add	a5,a5,a4
    80006542:	4809                	li	a6,2
    80006544:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006548:	611c                	ld	a5,0(a0)
    8000654a:	973e                	add	a4,a4,a5
    8000654c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006550:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006554:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006558:	6518                	ld	a4,8(a0)
    8000655a:	00275783          	lhu	a5,2(a4)
    8000655e:	8b9d                	andi	a5,a5,7
    80006560:	0786                	slli	a5,a5,0x1
    80006562:	97ba                	add	a5,a5,a4
    80006564:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006568:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000656c:	6518                	ld	a4,8(a0)
    8000656e:	00275783          	lhu	a5,2(a4)
    80006572:	2785                	addiw	a5,a5,1
    80006574:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006578:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000657c:	100017b7          	lui	a5,0x10001
    80006580:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006584:	00492703          	lw	a4,4(s2)
    80006588:	4785                	li	a5,1
    8000658a:	02f71163          	bne	a4,a5,800065ac <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000658e:	0001f997          	auipc	s3,0x1f
    80006592:	b9a98993          	addi	s3,s3,-1126 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006596:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006598:	85ce                	mv	a1,s3
    8000659a:	854a                	mv	a0,s2
    8000659c:	ffffc097          	auipc	ra,0xffffc
    800065a0:	c68080e7          	jalr	-920(ra) # 80002204 <sleep>
  while(b->disk == 1) {
    800065a4:	00492783          	lw	a5,4(s2)
    800065a8:	fe9788e3          	beq	a5,s1,80006598 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800065ac:	f9042903          	lw	s2,-112(s0)
    800065b0:	20090793          	addi	a5,s2,512
    800065b4:	00479713          	slli	a4,a5,0x4
    800065b8:	0001d797          	auipc	a5,0x1d
    800065bc:	a4878793          	addi	a5,a5,-1464 # 80023000 <disk>
    800065c0:	97ba                	add	a5,a5,a4
    800065c2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800065c6:	0001f997          	auipc	s3,0x1f
    800065ca:	a3a98993          	addi	s3,s3,-1478 # 80025000 <disk+0x2000>
    800065ce:	00491713          	slli	a4,s2,0x4
    800065d2:	0009b783          	ld	a5,0(s3)
    800065d6:	97ba                	add	a5,a5,a4
    800065d8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065dc:	854a                	mv	a0,s2
    800065de:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065e2:	00000097          	auipc	ra,0x0
    800065e6:	bc4080e7          	jalr	-1084(ra) # 800061a6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065ea:	8885                	andi	s1,s1,1
    800065ec:	f0ed                	bnez	s1,800065ce <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065ee:	0001f517          	auipc	a0,0x1f
    800065f2:	b3a50513          	addi	a0,a0,-1222 # 80025128 <disk+0x2128>
    800065f6:	ffffa097          	auipc	ra,0xffffa
    800065fa:	6a2080e7          	jalr	1698(ra) # 80000c98 <release>
}
    800065fe:	70a6                	ld	ra,104(sp)
    80006600:	7406                	ld	s0,96(sp)
    80006602:	64e6                	ld	s1,88(sp)
    80006604:	6946                	ld	s2,80(sp)
    80006606:	69a6                	ld	s3,72(sp)
    80006608:	6a06                	ld	s4,64(sp)
    8000660a:	7ae2                	ld	s5,56(sp)
    8000660c:	7b42                	ld	s6,48(sp)
    8000660e:	7ba2                	ld	s7,40(sp)
    80006610:	7c02                	ld	s8,32(sp)
    80006612:	6ce2                	ld	s9,24(sp)
    80006614:	6d42                	ld	s10,16(sp)
    80006616:	6165                	addi	sp,sp,112
    80006618:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000661a:	0001f697          	auipc	a3,0x1f
    8000661e:	9e66b683          	ld	a3,-1562(a3) # 80025000 <disk+0x2000>
    80006622:	96ba                	add	a3,a3,a4
    80006624:	4609                	li	a2,2
    80006626:	00c69623          	sh	a2,12(a3)
    8000662a:	b5c9                	j	800064ec <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000662c:	f9042583          	lw	a1,-112(s0)
    80006630:	20058793          	addi	a5,a1,512
    80006634:	0792                	slli	a5,a5,0x4
    80006636:	0001d517          	auipc	a0,0x1d
    8000663a:	a7250513          	addi	a0,a0,-1422 # 800230a8 <disk+0xa8>
    8000663e:	953e                	add	a0,a0,a5
  if(write)
    80006640:	e20d11e3          	bnez	s10,80006462 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006644:	20058713          	addi	a4,a1,512
    80006648:	00471693          	slli	a3,a4,0x4
    8000664c:	0001d717          	auipc	a4,0x1d
    80006650:	9b470713          	addi	a4,a4,-1612 # 80023000 <disk>
    80006654:	9736                	add	a4,a4,a3
    80006656:	0a072423          	sw	zero,168(a4)
    8000665a:	b505                	j	8000647a <virtio_disk_rw+0xf4>

000000008000665c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000665c:	1101                	addi	sp,sp,-32
    8000665e:	ec06                	sd	ra,24(sp)
    80006660:	e822                	sd	s0,16(sp)
    80006662:	e426                	sd	s1,8(sp)
    80006664:	e04a                	sd	s2,0(sp)
    80006666:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006668:	0001f517          	auipc	a0,0x1f
    8000666c:	ac050513          	addi	a0,a0,-1344 # 80025128 <disk+0x2128>
    80006670:	ffffa097          	auipc	ra,0xffffa
    80006674:	574080e7          	jalr	1396(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006678:	10001737          	lui	a4,0x10001
    8000667c:	533c                	lw	a5,96(a4)
    8000667e:	8b8d                	andi	a5,a5,3
    80006680:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006682:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006686:	0001f797          	auipc	a5,0x1f
    8000668a:	97a78793          	addi	a5,a5,-1670 # 80025000 <disk+0x2000>
    8000668e:	6b94                	ld	a3,16(a5)
    80006690:	0207d703          	lhu	a4,32(a5)
    80006694:	0026d783          	lhu	a5,2(a3)
    80006698:	06f70163          	beq	a4,a5,800066fa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000669c:	0001d917          	auipc	s2,0x1d
    800066a0:	96490913          	addi	s2,s2,-1692 # 80023000 <disk>
    800066a4:	0001f497          	auipc	s1,0x1f
    800066a8:	95c48493          	addi	s1,s1,-1700 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800066ac:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066b0:	6898                	ld	a4,16(s1)
    800066b2:	0204d783          	lhu	a5,32(s1)
    800066b6:	8b9d                	andi	a5,a5,7
    800066b8:	078e                	slli	a5,a5,0x3
    800066ba:	97ba                	add	a5,a5,a4
    800066bc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066be:	20078713          	addi	a4,a5,512
    800066c2:	0712                	slli	a4,a4,0x4
    800066c4:	974a                	add	a4,a4,s2
    800066c6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800066ca:	e731                	bnez	a4,80006716 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066cc:	20078793          	addi	a5,a5,512
    800066d0:	0792                	slli	a5,a5,0x4
    800066d2:	97ca                	add	a5,a5,s2
    800066d4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800066d6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066da:	ffffc097          	auipc	ra,0xffffc
    800066de:	e02080e7          	jalr	-510(ra) # 800024dc <wakeup>

    disk.used_idx += 1;
    800066e2:	0204d783          	lhu	a5,32(s1)
    800066e6:	2785                	addiw	a5,a5,1
    800066e8:	17c2                	slli	a5,a5,0x30
    800066ea:	93c1                	srli	a5,a5,0x30
    800066ec:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066f0:	6898                	ld	a4,16(s1)
    800066f2:	00275703          	lhu	a4,2(a4)
    800066f6:	faf71be3          	bne	a4,a5,800066ac <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800066fa:	0001f517          	auipc	a0,0x1f
    800066fe:	a2e50513          	addi	a0,a0,-1490 # 80025128 <disk+0x2128>
    80006702:	ffffa097          	auipc	ra,0xffffa
    80006706:	596080e7          	jalr	1430(ra) # 80000c98 <release>
}
    8000670a:	60e2                	ld	ra,24(sp)
    8000670c:	6442                	ld	s0,16(sp)
    8000670e:	64a2                	ld	s1,8(sp)
    80006710:	6902                	ld	s2,0(sp)
    80006712:	6105                	addi	sp,sp,32
    80006714:	8082                	ret
      panic("virtio_disk_intr status");
    80006716:	00002517          	auipc	a0,0x2
    8000671a:	29a50513          	addi	a0,a0,666 # 800089b0 <syscalls+0x3c0>
    8000671e:	ffffa097          	auipc	ra,0xffffa
    80006722:	e20080e7          	jalr	-480(ra) # 8000053e <panic>
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
