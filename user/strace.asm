
user/_strace:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
   0:	de010113          	addi	sp,sp,-544
   4:	20113c23          	sd	ra,536(sp)
   8:	20813823          	sd	s0,528(sp)
   c:	20913423          	sd	s1,520(sp)
  10:	21213023          	sd	s2,512(sp)
  14:	1400                	addi	s0,sp,544
  int i;
  char *newargv[64];

  if(argc < 3){
  16:	4789                	li	a5,2
  18:	02a7c063          	blt	a5,a0,38 <main+0x38>
    fprintf(2,"Invalid number of Arguments");
  1c:	00001597          	auipc	a1,0x1
  20:	83458593          	addi	a1,a1,-1996 # 850 <malloc+0xe4>
  24:	4509                	li	a0,2
  26:	00000097          	auipc	ra,0x0
  2a:	65a080e7          	jalr	1626(ra) # 680 <fprintf>
    exit(1);
  2e:	4505                	li	a0,1
  30:	00000097          	auipc	ra,0x0
  34:	2f6080e7          	jalr	758(ra) # 326 <exit>
  38:	84aa                	mv	s1,a0
  3a:	892e                	mv	s2,a1
  }

  if (trace(atoi(argv[1])) < 0) {
  3c:	6588                	ld	a0,8(a1)
  3e:	00000097          	auipc	ra,0x0
  42:	1e8080e7          	jalr	488(ra) # 226 <atoi>
  46:	00000097          	auipc	ra,0x0
  4a:	380080e7          	jalr	896(ra) # 3c6 <trace>
  4e:	04054363          	bltz	a0,94 <main+0x94>
  52:	01090793          	addi	a5,s2,16
  56:	de040713          	addi	a4,s0,-544
  5a:	ffd4869b          	addiw	a3,s1,-3
  5e:	1682                	slli	a3,a3,0x20
  60:	9281                	srli	a3,a3,0x20
  62:	068e                	slli	a3,a3,0x3
  64:	96be                	add	a3,a3,a5
  66:	10090593          	addi	a1,s2,256
    fprintf(2, "Incorrect Mask value");
    exit(1);
  }
  for(i = 2; i < argc && i < MAXARG; i++){
    newargv[i-2] = argv[i];
  6a:	6390                	ld	a2,0(a5)
  6c:	e310                	sd	a2,0(a4)
  for(i = 2; i < argc && i < MAXARG; i++){
  6e:	00d78663          	beq	a5,a3,7a <main+0x7a>
  72:	07a1                	addi	a5,a5,8
  74:	0721                	addi	a4,a4,8
  76:	feb79ae3          	bne	a5,a1,6a <main+0x6a>
  }
  exec(newargv[0], newargv);  
  7a:	de040593          	addi	a1,s0,-544
  7e:	de043503          	ld	a0,-544(s0)
  82:	00000097          	auipc	ra,0x0
  86:	2dc080e7          	jalr	732(ra) # 35e <exec>
  exit(0);
  8a:	4501                	li	a0,0
  8c:	00000097          	auipc	ra,0x0
  90:	29a080e7          	jalr	666(ra) # 326 <exit>
    fprintf(2, "Incorrect Mask value");
  94:	00000597          	auipc	a1,0x0
  98:	7dc58593          	addi	a1,a1,2012 # 870 <malloc+0x104>
  9c:	4509                	li	a0,2
  9e:	00000097          	auipc	ra,0x0
  a2:	5e2080e7          	jalr	1506(ra) # 680 <fprintf>
    exit(1);
  a6:	4505                	li	a0,1
  a8:	00000097          	auipc	ra,0x0
  ac:	27e080e7          	jalr	638(ra) # 326 <exit>

00000000000000b0 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  b0:	1141                	addi	sp,sp,-16
  b2:	e422                	sd	s0,8(sp)
  b4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  b6:	87aa                	mv	a5,a0
  b8:	0585                	addi	a1,a1,1
  ba:	0785                	addi	a5,a5,1
  bc:	fff5c703          	lbu	a4,-1(a1)
  c0:	fee78fa3          	sb	a4,-1(a5)
  c4:	fb75                	bnez	a4,b8 <strcpy+0x8>
    ;
  return os;
}
  c6:	6422                	ld	s0,8(sp)
  c8:	0141                	addi	sp,sp,16
  ca:	8082                	ret

00000000000000cc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  cc:	1141                	addi	sp,sp,-16
  ce:	e422                	sd	s0,8(sp)
  d0:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  d2:	00054783          	lbu	a5,0(a0)
  d6:	cb91                	beqz	a5,ea <strcmp+0x1e>
  d8:	0005c703          	lbu	a4,0(a1)
  dc:	00f71763          	bne	a4,a5,ea <strcmp+0x1e>
    p++, q++;
  e0:	0505                	addi	a0,a0,1
  e2:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  e4:	00054783          	lbu	a5,0(a0)
  e8:	fbe5                	bnez	a5,d8 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  ea:	0005c503          	lbu	a0,0(a1)
}
  ee:	40a7853b          	subw	a0,a5,a0
  f2:	6422                	ld	s0,8(sp)
  f4:	0141                	addi	sp,sp,16
  f6:	8082                	ret

00000000000000f8 <strlen>:

uint
strlen(const char *s)
{
  f8:	1141                	addi	sp,sp,-16
  fa:	e422                	sd	s0,8(sp)
  fc:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  fe:	00054783          	lbu	a5,0(a0)
 102:	cf91                	beqz	a5,11e <strlen+0x26>
 104:	0505                	addi	a0,a0,1
 106:	87aa                	mv	a5,a0
 108:	4685                	li	a3,1
 10a:	9e89                	subw	a3,a3,a0
 10c:	00f6853b          	addw	a0,a3,a5
 110:	0785                	addi	a5,a5,1
 112:	fff7c703          	lbu	a4,-1(a5)
 116:	fb7d                	bnez	a4,10c <strlen+0x14>
    ;
  return n;
}
 118:	6422                	ld	s0,8(sp)
 11a:	0141                	addi	sp,sp,16
 11c:	8082                	ret
  for(n = 0; s[n]; n++)
 11e:	4501                	li	a0,0
 120:	bfe5                	j	118 <strlen+0x20>

0000000000000122 <memset>:

void*
memset(void *dst, int c, uint n)
{
 122:	1141                	addi	sp,sp,-16
 124:	e422                	sd	s0,8(sp)
 126:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 128:	ce09                	beqz	a2,142 <memset+0x20>
 12a:	87aa                	mv	a5,a0
 12c:	fff6071b          	addiw	a4,a2,-1
 130:	1702                	slli	a4,a4,0x20
 132:	9301                	srli	a4,a4,0x20
 134:	0705                	addi	a4,a4,1
 136:	972a                	add	a4,a4,a0
    cdst[i] = c;
 138:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 13c:	0785                	addi	a5,a5,1
 13e:	fee79de3          	bne	a5,a4,138 <memset+0x16>
  }
  return dst;
}
 142:	6422                	ld	s0,8(sp)
 144:	0141                	addi	sp,sp,16
 146:	8082                	ret

0000000000000148 <strchr>:

char*
strchr(const char *s, char c)
{
 148:	1141                	addi	sp,sp,-16
 14a:	e422                	sd	s0,8(sp)
 14c:	0800                	addi	s0,sp,16
  for(; *s; s++)
 14e:	00054783          	lbu	a5,0(a0)
 152:	cb99                	beqz	a5,168 <strchr+0x20>
    if(*s == c)
 154:	00f58763          	beq	a1,a5,162 <strchr+0x1a>
  for(; *s; s++)
 158:	0505                	addi	a0,a0,1
 15a:	00054783          	lbu	a5,0(a0)
 15e:	fbfd                	bnez	a5,154 <strchr+0xc>
      return (char*)s;
  return 0;
 160:	4501                	li	a0,0
}
 162:	6422                	ld	s0,8(sp)
 164:	0141                	addi	sp,sp,16
 166:	8082                	ret
  return 0;
 168:	4501                	li	a0,0
 16a:	bfe5                	j	162 <strchr+0x1a>

000000000000016c <gets>:

char*
gets(char *buf, int max)
{
 16c:	711d                	addi	sp,sp,-96
 16e:	ec86                	sd	ra,88(sp)
 170:	e8a2                	sd	s0,80(sp)
 172:	e4a6                	sd	s1,72(sp)
 174:	e0ca                	sd	s2,64(sp)
 176:	fc4e                	sd	s3,56(sp)
 178:	f852                	sd	s4,48(sp)
 17a:	f456                	sd	s5,40(sp)
 17c:	f05a                	sd	s6,32(sp)
 17e:	ec5e                	sd	s7,24(sp)
 180:	1080                	addi	s0,sp,96
 182:	8baa                	mv	s7,a0
 184:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 186:	892a                	mv	s2,a0
 188:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 18a:	4aa9                	li	s5,10
 18c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 18e:	89a6                	mv	s3,s1
 190:	2485                	addiw	s1,s1,1
 192:	0344d863          	bge	s1,s4,1c2 <gets+0x56>
    cc = read(0, &c, 1);
 196:	4605                	li	a2,1
 198:	faf40593          	addi	a1,s0,-81
 19c:	4501                	li	a0,0
 19e:	00000097          	auipc	ra,0x0
 1a2:	1a0080e7          	jalr	416(ra) # 33e <read>
    if(cc < 1)
 1a6:	00a05e63          	blez	a0,1c2 <gets+0x56>
    buf[i++] = c;
 1aa:	faf44783          	lbu	a5,-81(s0)
 1ae:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1b2:	01578763          	beq	a5,s5,1c0 <gets+0x54>
 1b6:	0905                	addi	s2,s2,1
 1b8:	fd679be3          	bne	a5,s6,18e <gets+0x22>
  for(i=0; i+1 < max; ){
 1bc:	89a6                	mv	s3,s1
 1be:	a011                	j	1c2 <gets+0x56>
 1c0:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1c2:	99de                	add	s3,s3,s7
 1c4:	00098023          	sb	zero,0(s3)
  return buf;
}
 1c8:	855e                	mv	a0,s7
 1ca:	60e6                	ld	ra,88(sp)
 1cc:	6446                	ld	s0,80(sp)
 1ce:	64a6                	ld	s1,72(sp)
 1d0:	6906                	ld	s2,64(sp)
 1d2:	79e2                	ld	s3,56(sp)
 1d4:	7a42                	ld	s4,48(sp)
 1d6:	7aa2                	ld	s5,40(sp)
 1d8:	7b02                	ld	s6,32(sp)
 1da:	6be2                	ld	s7,24(sp)
 1dc:	6125                	addi	sp,sp,96
 1de:	8082                	ret

00000000000001e0 <stat>:

int
stat(const char *n, struct stat *st)
{
 1e0:	1101                	addi	sp,sp,-32
 1e2:	ec06                	sd	ra,24(sp)
 1e4:	e822                	sd	s0,16(sp)
 1e6:	e426                	sd	s1,8(sp)
 1e8:	e04a                	sd	s2,0(sp)
 1ea:	1000                	addi	s0,sp,32
 1ec:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1ee:	4581                	li	a1,0
 1f0:	00000097          	auipc	ra,0x0
 1f4:	176080e7          	jalr	374(ra) # 366 <open>
  if(fd < 0)
 1f8:	02054563          	bltz	a0,222 <stat+0x42>
 1fc:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1fe:	85ca                	mv	a1,s2
 200:	00000097          	auipc	ra,0x0
 204:	17e080e7          	jalr	382(ra) # 37e <fstat>
 208:	892a                	mv	s2,a0
  close(fd);
 20a:	8526                	mv	a0,s1
 20c:	00000097          	auipc	ra,0x0
 210:	142080e7          	jalr	322(ra) # 34e <close>
  return r;
}
 214:	854a                	mv	a0,s2
 216:	60e2                	ld	ra,24(sp)
 218:	6442                	ld	s0,16(sp)
 21a:	64a2                	ld	s1,8(sp)
 21c:	6902                	ld	s2,0(sp)
 21e:	6105                	addi	sp,sp,32
 220:	8082                	ret
    return -1;
 222:	597d                	li	s2,-1
 224:	bfc5                	j	214 <stat+0x34>

0000000000000226 <atoi>:

int
atoi(const char *s)
{
 226:	1141                	addi	sp,sp,-16
 228:	e422                	sd	s0,8(sp)
 22a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 22c:	00054603          	lbu	a2,0(a0)
 230:	fd06079b          	addiw	a5,a2,-48
 234:	0ff7f793          	andi	a5,a5,255
 238:	4725                	li	a4,9
 23a:	02f76963          	bltu	a4,a5,26c <atoi+0x46>
 23e:	86aa                	mv	a3,a0
  n = 0;
 240:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 242:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 244:	0685                	addi	a3,a3,1
 246:	0025179b          	slliw	a5,a0,0x2
 24a:	9fa9                	addw	a5,a5,a0
 24c:	0017979b          	slliw	a5,a5,0x1
 250:	9fb1                	addw	a5,a5,a2
 252:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 256:	0006c603          	lbu	a2,0(a3)
 25a:	fd06071b          	addiw	a4,a2,-48
 25e:	0ff77713          	andi	a4,a4,255
 262:	fee5f1e3          	bgeu	a1,a4,244 <atoi+0x1e>
  return n;
}
 266:	6422                	ld	s0,8(sp)
 268:	0141                	addi	sp,sp,16
 26a:	8082                	ret
  n = 0;
 26c:	4501                	li	a0,0
 26e:	bfe5                	j	266 <atoi+0x40>

0000000000000270 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 270:	1141                	addi	sp,sp,-16
 272:	e422                	sd	s0,8(sp)
 274:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 276:	02b57663          	bgeu	a0,a1,2a2 <memmove+0x32>
    while(n-- > 0)
 27a:	02c05163          	blez	a2,29c <memmove+0x2c>
 27e:	fff6079b          	addiw	a5,a2,-1
 282:	1782                	slli	a5,a5,0x20
 284:	9381                	srli	a5,a5,0x20
 286:	0785                	addi	a5,a5,1
 288:	97aa                	add	a5,a5,a0
  dst = vdst;
 28a:	872a                	mv	a4,a0
      *dst++ = *src++;
 28c:	0585                	addi	a1,a1,1
 28e:	0705                	addi	a4,a4,1
 290:	fff5c683          	lbu	a3,-1(a1)
 294:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 298:	fee79ae3          	bne	a5,a4,28c <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 29c:	6422                	ld	s0,8(sp)
 29e:	0141                	addi	sp,sp,16
 2a0:	8082                	ret
    dst += n;
 2a2:	00c50733          	add	a4,a0,a2
    src += n;
 2a6:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2a8:	fec05ae3          	blez	a2,29c <memmove+0x2c>
 2ac:	fff6079b          	addiw	a5,a2,-1
 2b0:	1782                	slli	a5,a5,0x20
 2b2:	9381                	srli	a5,a5,0x20
 2b4:	fff7c793          	not	a5,a5
 2b8:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2ba:	15fd                	addi	a1,a1,-1
 2bc:	177d                	addi	a4,a4,-1
 2be:	0005c683          	lbu	a3,0(a1)
 2c2:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2c6:	fee79ae3          	bne	a5,a4,2ba <memmove+0x4a>
 2ca:	bfc9                	j	29c <memmove+0x2c>

00000000000002cc <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2cc:	1141                	addi	sp,sp,-16
 2ce:	e422                	sd	s0,8(sp)
 2d0:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2d2:	ca05                	beqz	a2,302 <memcmp+0x36>
 2d4:	fff6069b          	addiw	a3,a2,-1
 2d8:	1682                	slli	a3,a3,0x20
 2da:	9281                	srli	a3,a3,0x20
 2dc:	0685                	addi	a3,a3,1
 2de:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2e0:	00054783          	lbu	a5,0(a0)
 2e4:	0005c703          	lbu	a4,0(a1)
 2e8:	00e79863          	bne	a5,a4,2f8 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2ec:	0505                	addi	a0,a0,1
    p2++;
 2ee:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2f0:	fed518e3          	bne	a0,a3,2e0 <memcmp+0x14>
  }
  return 0;
 2f4:	4501                	li	a0,0
 2f6:	a019                	j	2fc <memcmp+0x30>
      return *p1 - *p2;
 2f8:	40e7853b          	subw	a0,a5,a4
}
 2fc:	6422                	ld	s0,8(sp)
 2fe:	0141                	addi	sp,sp,16
 300:	8082                	ret
  return 0;
 302:	4501                	li	a0,0
 304:	bfe5                	j	2fc <memcmp+0x30>

0000000000000306 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 306:	1141                	addi	sp,sp,-16
 308:	e406                	sd	ra,8(sp)
 30a:	e022                	sd	s0,0(sp)
 30c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 30e:	00000097          	auipc	ra,0x0
 312:	f62080e7          	jalr	-158(ra) # 270 <memmove>
}
 316:	60a2                	ld	ra,8(sp)
 318:	6402                	ld	s0,0(sp)
 31a:	0141                	addi	sp,sp,16
 31c:	8082                	ret

000000000000031e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 31e:	4885                	li	a7,1
 ecall
 320:	00000073          	ecall
 ret
 324:	8082                	ret

0000000000000326 <exit>:
.global exit
exit:
 li a7, SYS_exit
 326:	4889                	li	a7,2
 ecall
 328:	00000073          	ecall
 ret
 32c:	8082                	ret

000000000000032e <wait>:
.global wait
wait:
 li a7, SYS_wait
 32e:	488d                	li	a7,3
 ecall
 330:	00000073          	ecall
 ret
 334:	8082                	ret

0000000000000336 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 336:	4891                	li	a7,4
 ecall
 338:	00000073          	ecall
 ret
 33c:	8082                	ret

000000000000033e <read>:
.global read
read:
 li a7, SYS_read
 33e:	4895                	li	a7,5
 ecall
 340:	00000073          	ecall
 ret
 344:	8082                	ret

0000000000000346 <write>:
.global write
write:
 li a7, SYS_write
 346:	48c1                	li	a7,16
 ecall
 348:	00000073          	ecall
 ret
 34c:	8082                	ret

000000000000034e <close>:
.global close
close:
 li a7, SYS_close
 34e:	48d5                	li	a7,21
 ecall
 350:	00000073          	ecall
 ret
 354:	8082                	ret

0000000000000356 <kill>:
.global kill
kill:
 li a7, SYS_kill
 356:	4899                	li	a7,6
 ecall
 358:	00000073          	ecall
 ret
 35c:	8082                	ret

000000000000035e <exec>:
.global exec
exec:
 li a7, SYS_exec
 35e:	489d                	li	a7,7
 ecall
 360:	00000073          	ecall
 ret
 364:	8082                	ret

0000000000000366 <open>:
.global open
open:
 li a7, SYS_open
 366:	48bd                	li	a7,15
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 36e:	48c5                	li	a7,17
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 376:	48c9                	li	a7,18
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 37e:	48a1                	li	a7,8
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <link>:
.global link
link:
 li a7, SYS_link
 386:	48cd                	li	a7,19
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 38e:	48d1                	li	a7,20
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 396:	48a5                	li	a7,9
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <dup>:
.global dup
dup:
 li a7, SYS_dup
 39e:	48a9                	li	a7,10
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3a6:	48ad                	li	a7,11
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3ae:	48b1                	li	a7,12
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3b6:	48b5                	li	a7,13
 ecall
 3b8:	00000073          	ecall
 ret
 3bc:	8082                	ret

00000000000003be <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3be:	48b9                	li	a7,14
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <trace>:
.global trace
trace:
 li a7, SYS_trace
 3c6:	48d9                	li	a7,22
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 3ce:	48dd                	li	a7,23
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3d6:	1101                	addi	sp,sp,-32
 3d8:	ec06                	sd	ra,24(sp)
 3da:	e822                	sd	s0,16(sp)
 3dc:	1000                	addi	s0,sp,32
 3de:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3e2:	4605                	li	a2,1
 3e4:	fef40593          	addi	a1,s0,-17
 3e8:	00000097          	auipc	ra,0x0
 3ec:	f5e080e7          	jalr	-162(ra) # 346 <write>
}
 3f0:	60e2                	ld	ra,24(sp)
 3f2:	6442                	ld	s0,16(sp)
 3f4:	6105                	addi	sp,sp,32
 3f6:	8082                	ret

00000000000003f8 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3f8:	7139                	addi	sp,sp,-64
 3fa:	fc06                	sd	ra,56(sp)
 3fc:	f822                	sd	s0,48(sp)
 3fe:	f426                	sd	s1,40(sp)
 400:	f04a                	sd	s2,32(sp)
 402:	ec4e                	sd	s3,24(sp)
 404:	0080                	addi	s0,sp,64
 406:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 408:	c299                	beqz	a3,40e <printint+0x16>
 40a:	0805c863          	bltz	a1,49a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 40e:	2581                	sext.w	a1,a1
  neg = 0;
 410:	4881                	li	a7,0
 412:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 416:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 418:	2601                	sext.w	a2,a2
 41a:	00000517          	auipc	a0,0x0
 41e:	47650513          	addi	a0,a0,1142 # 890 <digits>
 422:	883a                	mv	a6,a4
 424:	2705                	addiw	a4,a4,1
 426:	02c5f7bb          	remuw	a5,a1,a2
 42a:	1782                	slli	a5,a5,0x20
 42c:	9381                	srli	a5,a5,0x20
 42e:	97aa                	add	a5,a5,a0
 430:	0007c783          	lbu	a5,0(a5)
 434:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 438:	0005879b          	sext.w	a5,a1
 43c:	02c5d5bb          	divuw	a1,a1,a2
 440:	0685                	addi	a3,a3,1
 442:	fec7f0e3          	bgeu	a5,a2,422 <printint+0x2a>
  if(neg)
 446:	00088b63          	beqz	a7,45c <printint+0x64>
    buf[i++] = '-';
 44a:	fd040793          	addi	a5,s0,-48
 44e:	973e                	add	a4,a4,a5
 450:	02d00793          	li	a5,45
 454:	fef70823          	sb	a5,-16(a4)
 458:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 45c:	02e05863          	blez	a4,48c <printint+0x94>
 460:	fc040793          	addi	a5,s0,-64
 464:	00e78933          	add	s2,a5,a4
 468:	fff78993          	addi	s3,a5,-1
 46c:	99ba                	add	s3,s3,a4
 46e:	377d                	addiw	a4,a4,-1
 470:	1702                	slli	a4,a4,0x20
 472:	9301                	srli	a4,a4,0x20
 474:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 478:	fff94583          	lbu	a1,-1(s2)
 47c:	8526                	mv	a0,s1
 47e:	00000097          	auipc	ra,0x0
 482:	f58080e7          	jalr	-168(ra) # 3d6 <putc>
  while(--i >= 0)
 486:	197d                	addi	s2,s2,-1
 488:	ff3918e3          	bne	s2,s3,478 <printint+0x80>
}
 48c:	70e2                	ld	ra,56(sp)
 48e:	7442                	ld	s0,48(sp)
 490:	74a2                	ld	s1,40(sp)
 492:	7902                	ld	s2,32(sp)
 494:	69e2                	ld	s3,24(sp)
 496:	6121                	addi	sp,sp,64
 498:	8082                	ret
    x = -xx;
 49a:	40b005bb          	negw	a1,a1
    neg = 1;
 49e:	4885                	li	a7,1
    x = -xx;
 4a0:	bf8d                	j	412 <printint+0x1a>

00000000000004a2 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4a2:	7119                	addi	sp,sp,-128
 4a4:	fc86                	sd	ra,120(sp)
 4a6:	f8a2                	sd	s0,112(sp)
 4a8:	f4a6                	sd	s1,104(sp)
 4aa:	f0ca                	sd	s2,96(sp)
 4ac:	ecce                	sd	s3,88(sp)
 4ae:	e8d2                	sd	s4,80(sp)
 4b0:	e4d6                	sd	s5,72(sp)
 4b2:	e0da                	sd	s6,64(sp)
 4b4:	fc5e                	sd	s7,56(sp)
 4b6:	f862                	sd	s8,48(sp)
 4b8:	f466                	sd	s9,40(sp)
 4ba:	f06a                	sd	s10,32(sp)
 4bc:	ec6e                	sd	s11,24(sp)
 4be:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4c0:	0005c903          	lbu	s2,0(a1)
 4c4:	18090f63          	beqz	s2,662 <vprintf+0x1c0>
 4c8:	8aaa                	mv	s5,a0
 4ca:	8b32                	mv	s6,a2
 4cc:	00158493          	addi	s1,a1,1
  state = 0;
 4d0:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4d2:	02500a13          	li	s4,37
      if(c == 'd'){
 4d6:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4da:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4de:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4e2:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4e6:	00000b97          	auipc	s7,0x0
 4ea:	3aab8b93          	addi	s7,s7,938 # 890 <digits>
 4ee:	a839                	j	50c <vprintf+0x6a>
        putc(fd, c);
 4f0:	85ca                	mv	a1,s2
 4f2:	8556                	mv	a0,s5
 4f4:	00000097          	auipc	ra,0x0
 4f8:	ee2080e7          	jalr	-286(ra) # 3d6 <putc>
 4fc:	a019                	j	502 <vprintf+0x60>
    } else if(state == '%'){
 4fe:	01498f63          	beq	s3,s4,51c <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 502:	0485                	addi	s1,s1,1
 504:	fff4c903          	lbu	s2,-1(s1)
 508:	14090d63          	beqz	s2,662 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 50c:	0009079b          	sext.w	a5,s2
    if(state == 0){
 510:	fe0997e3          	bnez	s3,4fe <vprintf+0x5c>
      if(c == '%'){
 514:	fd479ee3          	bne	a5,s4,4f0 <vprintf+0x4e>
        state = '%';
 518:	89be                	mv	s3,a5
 51a:	b7e5                	j	502 <vprintf+0x60>
      if(c == 'd'){
 51c:	05878063          	beq	a5,s8,55c <vprintf+0xba>
      } else if(c == 'l') {
 520:	05978c63          	beq	a5,s9,578 <vprintf+0xd6>
      } else if(c == 'x') {
 524:	07a78863          	beq	a5,s10,594 <vprintf+0xf2>
      } else if(c == 'p') {
 528:	09b78463          	beq	a5,s11,5b0 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 52c:	07300713          	li	a4,115
 530:	0ce78663          	beq	a5,a4,5fc <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 534:	06300713          	li	a4,99
 538:	0ee78e63          	beq	a5,a4,634 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 53c:	11478863          	beq	a5,s4,64c <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 540:	85d2                	mv	a1,s4
 542:	8556                	mv	a0,s5
 544:	00000097          	auipc	ra,0x0
 548:	e92080e7          	jalr	-366(ra) # 3d6 <putc>
        putc(fd, c);
 54c:	85ca                	mv	a1,s2
 54e:	8556                	mv	a0,s5
 550:	00000097          	auipc	ra,0x0
 554:	e86080e7          	jalr	-378(ra) # 3d6 <putc>
      }
      state = 0;
 558:	4981                	li	s3,0
 55a:	b765                	j	502 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 55c:	008b0913          	addi	s2,s6,8
 560:	4685                	li	a3,1
 562:	4629                	li	a2,10
 564:	000b2583          	lw	a1,0(s6)
 568:	8556                	mv	a0,s5
 56a:	00000097          	auipc	ra,0x0
 56e:	e8e080e7          	jalr	-370(ra) # 3f8 <printint>
 572:	8b4a                	mv	s6,s2
      state = 0;
 574:	4981                	li	s3,0
 576:	b771                	j	502 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 578:	008b0913          	addi	s2,s6,8
 57c:	4681                	li	a3,0
 57e:	4629                	li	a2,10
 580:	000b2583          	lw	a1,0(s6)
 584:	8556                	mv	a0,s5
 586:	00000097          	auipc	ra,0x0
 58a:	e72080e7          	jalr	-398(ra) # 3f8 <printint>
 58e:	8b4a                	mv	s6,s2
      state = 0;
 590:	4981                	li	s3,0
 592:	bf85                	j	502 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 594:	008b0913          	addi	s2,s6,8
 598:	4681                	li	a3,0
 59a:	4641                	li	a2,16
 59c:	000b2583          	lw	a1,0(s6)
 5a0:	8556                	mv	a0,s5
 5a2:	00000097          	auipc	ra,0x0
 5a6:	e56080e7          	jalr	-426(ra) # 3f8 <printint>
 5aa:	8b4a                	mv	s6,s2
      state = 0;
 5ac:	4981                	li	s3,0
 5ae:	bf91                	j	502 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5b0:	008b0793          	addi	a5,s6,8
 5b4:	f8f43423          	sd	a5,-120(s0)
 5b8:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5bc:	03000593          	li	a1,48
 5c0:	8556                	mv	a0,s5
 5c2:	00000097          	auipc	ra,0x0
 5c6:	e14080e7          	jalr	-492(ra) # 3d6 <putc>
  putc(fd, 'x');
 5ca:	85ea                	mv	a1,s10
 5cc:	8556                	mv	a0,s5
 5ce:	00000097          	auipc	ra,0x0
 5d2:	e08080e7          	jalr	-504(ra) # 3d6 <putc>
 5d6:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5d8:	03c9d793          	srli	a5,s3,0x3c
 5dc:	97de                	add	a5,a5,s7
 5de:	0007c583          	lbu	a1,0(a5)
 5e2:	8556                	mv	a0,s5
 5e4:	00000097          	auipc	ra,0x0
 5e8:	df2080e7          	jalr	-526(ra) # 3d6 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5ec:	0992                	slli	s3,s3,0x4
 5ee:	397d                	addiw	s2,s2,-1
 5f0:	fe0914e3          	bnez	s2,5d8 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5f4:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5f8:	4981                	li	s3,0
 5fa:	b721                	j	502 <vprintf+0x60>
        s = va_arg(ap, char*);
 5fc:	008b0993          	addi	s3,s6,8
 600:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 604:	02090163          	beqz	s2,626 <vprintf+0x184>
        while(*s != 0){
 608:	00094583          	lbu	a1,0(s2)
 60c:	c9a1                	beqz	a1,65c <vprintf+0x1ba>
          putc(fd, *s);
 60e:	8556                	mv	a0,s5
 610:	00000097          	auipc	ra,0x0
 614:	dc6080e7          	jalr	-570(ra) # 3d6 <putc>
          s++;
 618:	0905                	addi	s2,s2,1
        while(*s != 0){
 61a:	00094583          	lbu	a1,0(s2)
 61e:	f9e5                	bnez	a1,60e <vprintf+0x16c>
        s = va_arg(ap, char*);
 620:	8b4e                	mv	s6,s3
      state = 0;
 622:	4981                	li	s3,0
 624:	bdf9                	j	502 <vprintf+0x60>
          s = "(null)";
 626:	00000917          	auipc	s2,0x0
 62a:	26290913          	addi	s2,s2,610 # 888 <malloc+0x11c>
        while(*s != 0){
 62e:	02800593          	li	a1,40
 632:	bff1                	j	60e <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 634:	008b0913          	addi	s2,s6,8
 638:	000b4583          	lbu	a1,0(s6)
 63c:	8556                	mv	a0,s5
 63e:	00000097          	auipc	ra,0x0
 642:	d98080e7          	jalr	-616(ra) # 3d6 <putc>
 646:	8b4a                	mv	s6,s2
      state = 0;
 648:	4981                	li	s3,0
 64a:	bd65                	j	502 <vprintf+0x60>
        putc(fd, c);
 64c:	85d2                	mv	a1,s4
 64e:	8556                	mv	a0,s5
 650:	00000097          	auipc	ra,0x0
 654:	d86080e7          	jalr	-634(ra) # 3d6 <putc>
      state = 0;
 658:	4981                	li	s3,0
 65a:	b565                	j	502 <vprintf+0x60>
        s = va_arg(ap, char*);
 65c:	8b4e                	mv	s6,s3
      state = 0;
 65e:	4981                	li	s3,0
 660:	b54d                	j	502 <vprintf+0x60>
    }
  }
}
 662:	70e6                	ld	ra,120(sp)
 664:	7446                	ld	s0,112(sp)
 666:	74a6                	ld	s1,104(sp)
 668:	7906                	ld	s2,96(sp)
 66a:	69e6                	ld	s3,88(sp)
 66c:	6a46                	ld	s4,80(sp)
 66e:	6aa6                	ld	s5,72(sp)
 670:	6b06                	ld	s6,64(sp)
 672:	7be2                	ld	s7,56(sp)
 674:	7c42                	ld	s8,48(sp)
 676:	7ca2                	ld	s9,40(sp)
 678:	7d02                	ld	s10,32(sp)
 67a:	6de2                	ld	s11,24(sp)
 67c:	6109                	addi	sp,sp,128
 67e:	8082                	ret

0000000000000680 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 680:	715d                	addi	sp,sp,-80
 682:	ec06                	sd	ra,24(sp)
 684:	e822                	sd	s0,16(sp)
 686:	1000                	addi	s0,sp,32
 688:	e010                	sd	a2,0(s0)
 68a:	e414                	sd	a3,8(s0)
 68c:	e818                	sd	a4,16(s0)
 68e:	ec1c                	sd	a5,24(s0)
 690:	03043023          	sd	a6,32(s0)
 694:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 698:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 69c:	8622                	mv	a2,s0
 69e:	00000097          	auipc	ra,0x0
 6a2:	e04080e7          	jalr	-508(ra) # 4a2 <vprintf>
}
 6a6:	60e2                	ld	ra,24(sp)
 6a8:	6442                	ld	s0,16(sp)
 6aa:	6161                	addi	sp,sp,80
 6ac:	8082                	ret

00000000000006ae <printf>:

void
printf(const char *fmt, ...)
{
 6ae:	711d                	addi	sp,sp,-96
 6b0:	ec06                	sd	ra,24(sp)
 6b2:	e822                	sd	s0,16(sp)
 6b4:	1000                	addi	s0,sp,32
 6b6:	e40c                	sd	a1,8(s0)
 6b8:	e810                	sd	a2,16(s0)
 6ba:	ec14                	sd	a3,24(s0)
 6bc:	f018                	sd	a4,32(s0)
 6be:	f41c                	sd	a5,40(s0)
 6c0:	03043823          	sd	a6,48(s0)
 6c4:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6c8:	00840613          	addi	a2,s0,8
 6cc:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6d0:	85aa                	mv	a1,a0
 6d2:	4505                	li	a0,1
 6d4:	00000097          	auipc	ra,0x0
 6d8:	dce080e7          	jalr	-562(ra) # 4a2 <vprintf>
}
 6dc:	60e2                	ld	ra,24(sp)
 6de:	6442                	ld	s0,16(sp)
 6e0:	6125                	addi	sp,sp,96
 6e2:	8082                	ret

00000000000006e4 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6e4:	1141                	addi	sp,sp,-16
 6e6:	e422                	sd	s0,8(sp)
 6e8:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6ea:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6ee:	00000797          	auipc	a5,0x0
 6f2:	1ba7b783          	ld	a5,442(a5) # 8a8 <freep>
 6f6:	a805                	j	726 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6f8:	4618                	lw	a4,8(a2)
 6fa:	9db9                	addw	a1,a1,a4
 6fc:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 700:	6398                	ld	a4,0(a5)
 702:	6318                	ld	a4,0(a4)
 704:	fee53823          	sd	a4,-16(a0)
 708:	a091                	j	74c <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 70a:	ff852703          	lw	a4,-8(a0)
 70e:	9e39                	addw	a2,a2,a4
 710:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 712:	ff053703          	ld	a4,-16(a0)
 716:	e398                	sd	a4,0(a5)
 718:	a099                	j	75e <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 71a:	6398                	ld	a4,0(a5)
 71c:	00e7e463          	bltu	a5,a4,724 <free+0x40>
 720:	00e6ea63          	bltu	a3,a4,734 <free+0x50>
{
 724:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 726:	fed7fae3          	bgeu	a5,a3,71a <free+0x36>
 72a:	6398                	ld	a4,0(a5)
 72c:	00e6e463          	bltu	a3,a4,734 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 730:	fee7eae3          	bltu	a5,a4,724 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 734:	ff852583          	lw	a1,-8(a0)
 738:	6390                	ld	a2,0(a5)
 73a:	02059713          	slli	a4,a1,0x20
 73e:	9301                	srli	a4,a4,0x20
 740:	0712                	slli	a4,a4,0x4
 742:	9736                	add	a4,a4,a3
 744:	fae60ae3          	beq	a2,a4,6f8 <free+0x14>
    bp->s.ptr = p->s.ptr;
 748:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 74c:	4790                	lw	a2,8(a5)
 74e:	02061713          	slli	a4,a2,0x20
 752:	9301                	srli	a4,a4,0x20
 754:	0712                	slli	a4,a4,0x4
 756:	973e                	add	a4,a4,a5
 758:	fae689e3          	beq	a3,a4,70a <free+0x26>
  } else
    p->s.ptr = bp;
 75c:	e394                	sd	a3,0(a5)
  freep = p;
 75e:	00000717          	auipc	a4,0x0
 762:	14f73523          	sd	a5,330(a4) # 8a8 <freep>
}
 766:	6422                	ld	s0,8(sp)
 768:	0141                	addi	sp,sp,16
 76a:	8082                	ret

000000000000076c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 76c:	7139                	addi	sp,sp,-64
 76e:	fc06                	sd	ra,56(sp)
 770:	f822                	sd	s0,48(sp)
 772:	f426                	sd	s1,40(sp)
 774:	f04a                	sd	s2,32(sp)
 776:	ec4e                	sd	s3,24(sp)
 778:	e852                	sd	s4,16(sp)
 77a:	e456                	sd	s5,8(sp)
 77c:	e05a                	sd	s6,0(sp)
 77e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 780:	02051493          	slli	s1,a0,0x20
 784:	9081                	srli	s1,s1,0x20
 786:	04bd                	addi	s1,s1,15
 788:	8091                	srli	s1,s1,0x4
 78a:	0014899b          	addiw	s3,s1,1
 78e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 790:	00000517          	auipc	a0,0x0
 794:	11853503          	ld	a0,280(a0) # 8a8 <freep>
 798:	c515                	beqz	a0,7c4 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 79a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 79c:	4798                	lw	a4,8(a5)
 79e:	02977f63          	bgeu	a4,s1,7dc <malloc+0x70>
 7a2:	8a4e                	mv	s4,s3
 7a4:	0009871b          	sext.w	a4,s3
 7a8:	6685                	lui	a3,0x1
 7aa:	00d77363          	bgeu	a4,a3,7b0 <malloc+0x44>
 7ae:	6a05                	lui	s4,0x1
 7b0:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7b4:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7b8:	00000917          	auipc	s2,0x0
 7bc:	0f090913          	addi	s2,s2,240 # 8a8 <freep>
  if(p == (char*)-1)
 7c0:	5afd                	li	s5,-1
 7c2:	a88d                	j	834 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7c4:	00000797          	auipc	a5,0x0
 7c8:	0ec78793          	addi	a5,a5,236 # 8b0 <base>
 7cc:	00000717          	auipc	a4,0x0
 7d0:	0cf73e23          	sd	a5,220(a4) # 8a8 <freep>
 7d4:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7d6:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7da:	b7e1                	j	7a2 <malloc+0x36>
      if(p->s.size == nunits)
 7dc:	02e48b63          	beq	s1,a4,812 <malloc+0xa6>
        p->s.size -= nunits;
 7e0:	4137073b          	subw	a4,a4,s3
 7e4:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7e6:	1702                	slli	a4,a4,0x20
 7e8:	9301                	srli	a4,a4,0x20
 7ea:	0712                	slli	a4,a4,0x4
 7ec:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7ee:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7f2:	00000717          	auipc	a4,0x0
 7f6:	0aa73b23          	sd	a0,182(a4) # 8a8 <freep>
      return (void*)(p + 1);
 7fa:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7fe:	70e2                	ld	ra,56(sp)
 800:	7442                	ld	s0,48(sp)
 802:	74a2                	ld	s1,40(sp)
 804:	7902                	ld	s2,32(sp)
 806:	69e2                	ld	s3,24(sp)
 808:	6a42                	ld	s4,16(sp)
 80a:	6aa2                	ld	s5,8(sp)
 80c:	6b02                	ld	s6,0(sp)
 80e:	6121                	addi	sp,sp,64
 810:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 812:	6398                	ld	a4,0(a5)
 814:	e118                	sd	a4,0(a0)
 816:	bff1                	j	7f2 <malloc+0x86>
  hp->s.size = nu;
 818:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 81c:	0541                	addi	a0,a0,16
 81e:	00000097          	auipc	ra,0x0
 822:	ec6080e7          	jalr	-314(ra) # 6e4 <free>
  return freep;
 826:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 82a:	d971                	beqz	a0,7fe <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 82c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 82e:	4798                	lw	a4,8(a5)
 830:	fa9776e3          	bgeu	a4,s1,7dc <malloc+0x70>
    if(p == freep)
 834:	00093703          	ld	a4,0(s2)
 838:	853e                	mv	a0,a5
 83a:	fef719e3          	bne	a4,a5,82c <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 83e:	8552                	mv	a0,s4
 840:	00000097          	auipc	ra,0x0
 844:	b6e080e7          	jalr	-1170(ra) # 3ae <sbrk>
  if(p == (char*)-1)
 848:	fd5518e3          	bne	a0,s5,818 <malloc+0xac>
        return 0;
 84c:	4501                	li	a0,0
 84e:	bf45                	j	7fe <malloc+0x92>
