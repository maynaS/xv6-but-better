# **xv6-but-better**

---

#### Sanyam Shah 2020101012

## Introduction

This is a modification of the xv6 operating system in which the following features have been implemented:

- `strace` system call
- First-come-first-serve CPU scheduler (`FCFS`)
- Priority-based CPU scheduler (`PBS`)
- Multi-level-feedback-queue CPU scheduler (`MLFQ`)

Details about the scope and implementation of these features are available in `REPORT.pdf` (or `REPORT.md`).

#####  How to Run:

1. Clean the binary files compiled previously

```sh
make clean
```

2. Compile and generate the binary files (Build the OS)

```sh
make qemu
```

3. Add the flag "SCHEDULER" to choose between `RR`, `FCFS`, `PBS`, and `MLFQ` (default scheduler := `RR`)

```sh
make qemu SCHEDULER=FCFS
```

##### How to exit the xv6 OS:

```sh
Ctrl-A + x
```

#### New System-Calls:

##### 1. `strace Syscall`

##### 2. `waitx Syscall`

##### 3. `setpriority Syscall`

##### 5. `schedulertest Syscall`

#### New CPU Schedulers:

##### 1. `First-Come-First-Serve (FCFS) Syscall`

##### 2. `Priority Based Scheduling (PBS) Syscall`

##### 3. `Multilevel Feedback Queue (MLFQ) Syscall`

Comparision

As we can see from the total time taken by all the schedulers :-
RR is the fastest one in terms of total time and also gives fair run time to the process that forks all other processes in the bench mark.
MLFQ and PBS are not far behind as they also complete in almost the same time or a little bit lower.
FCFS is the slowest one as it increases the overall turnaround time due to convoy effect.

from most time to least: -
FCFS > PBS >= MLFQ >= RR

**************
# Original README:

xv6 is a re-implementation of Dennis Ritchie's and Ken Thompson's Unix Version 6 (v6).  xv6 loosely follows the structure and style of v6, but is implemented for a modern RISC-V multiprocessor using ANSI C.

ACKNOWLEDGMENTS

xv6 is inspired by John Lions's Commentary on UNIX 6th Edition (Peer to Peer Communications; ISBN: 1-57398-013-7; 1st edition (June 14, 2000)). See also https://pdos.csail.mit.edu/6.828/, which provides pointers to on-line resources for v6.

The following people have made contributions: Russ Cox (context switching, locking), Cliff Frey (MP), Xiao Yu (MP), Nickolai Zeldovich, and Austin Clements. We are also grateful for the bug reports and patches contributed by Takahiro Aoyagi, Silas Boyd-Wickizer, Anton Burtsev, Ian Chen, Dan Cross, Cody Cutler, Mike CAT, Tej Chajed, Asami Doi, eyalz800, Nelson Elhage, Saar Ettinger, Alice Ferrazzi, Nathaniel Filardo, flespark,Peter Froehlich, Yakir Goaron,Shivam Handa, Matt Harvey, Bryan Henry, jaichenhengjie, Jim Huang, Matúš Jókay, Alexander Kapshuk, Anders Kaseorg, kehao95, Wolfgang Keller, Jungwoo Kim, Jonathan Kimmitt,Eddie Kohler, Vadim Kolontsov , Austin Liew, l0stman, Pavan Maddamsetti, Imbar Marinescu, Yandong Mao, , Matan Shabtay, Hitoshi Mitake, Carmi Merimovich, Mark Morrissey, mtasm, Joel Nider, OptimisticSide, Greg Price, Jude Rich, Ayan Shafqat, Eldar Sehayek, Yongming Shen, Fumiya Shigemitsu, Cam Tenny, tyfkda, Warren Toomey, Stephen Tu, Rafael Ubal, Amane Uehara, Pablo Ventura, Xi Wang, Keiichi Watanabe, Nicolas Wolovick, wxdao, Grant Wu, Jindong Zhang, Icenowy Zheng, ZhUyU1997, and Zou Chang Wei.

The code in the files that constitute xv6 is Copyright 2006-2020 Frans Kaashoek, Robert Morris, and Russ Cox.

ERROR REPORTS

Please send errors and suggestions to Frans Kaashoek and Robert Morris (kaashoek,rtm@mit.edu). The main purpose of xv6 is as a teaching operating system for MIT's 6.S081, so we are more interested in simplifications and clarifications than new features.

BUILDING AND RUNNING XV6

You will need a RISC-V "newlib" tool chain from https://github.com/riscv/riscv-gnu-toolchain, and qemu compiled for

riscv64-softmmu. Once they are installed, and in your shell search path, you can run "make qemu".
