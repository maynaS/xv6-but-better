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

### Specification 1: Syscall Tracing

+ Here, we add a system call, trace, and an accompanying user program `strace`.

```shell
strace mask command [args]
```

+ `strace` runs the specified command until it exits.
+ It intercepts and records the system calls which are called by a process during its execution.
+ It takes one argument, an integer **mask**, whose bits specify which system calls to trace.
+ For example, to trace the `ith` system call, a program calls strace `1<<i`, where `i` is the syscall number.
+ A line is printed when each system call is about to return if the system call's number is set in the mask.
+ The line contains:
  1. The process id 
  2. The name of the system call
  3. The decimal value of the arguments(xv6 passes arguments via registers).
  4. The return value of the syscall.

+ Added $U/_strace  in UPROGS in Makefile
+ Added a sys_trace() function in kernel/sysproc.c that implements the new system call by remembering its argument in a new variable in the proc structure in proc.h
+ Modified fork() (in kernel/proc.c) to copy the trace mask from the parent to the child process
+ Added an array to store/remember the number of arguments for each syscall
+ Modified the syscall() function in kernel/syscall.c to print the trace output. 
+ Created a user program in user/strace.c,  to generate the user-space stubs for the system call
+ Added a prototype for the system call to user/user.h, a stub to user/usys.pl, and a syscall number to kernel/syscall.h 

### Specification 2: Scheduling

+ The default scheduler of xv6 is round-robin-based. Here I implemented 3 other scheduling policies for CPU scheduler. The kernel shall only use one scheduling policy which will be declared at compile time.
+ Modified the Makefile to support `SCHEDULER` - a macro for the compilation of the specified scheduling algorithm. 
+ Following is the list of flags used:
  + First Come First Serve = FCFS
  + Priority Based = PBS
  + Multilevel Feedback Queue = MLFQ
+ Used preprocessor directives to declare the alternate scheduling policy in scheduler() in kernel/proc.h

#### a) FCFS

+ Implemented a policy that selects the process with the lowest creation time.
+ The process will run until it no longer needs CPU time.
+ Edited the struct proc (used for storing per-process information) in kernel/proc.h to store extra information about the process.
+ Modified the allocproc() function to set up values when the process starts.
+ Disabled the preemption of the process after the clock interrupts in kernel/trap.c

#### b) PBS

+ Implemented a non-preemptive priority-based scheduler that selects the process with the highest priority for execution. 

+ In case two or more processes have the same priority, I used the number of times the process has been scheduled to break the tie. If the tie remains, the start-time of the process is used to break the tie(processes with lower start times is scheduled further).

+ 2 types of priorities used:

  + The **Static Priority** of a process (SP) can be in the range [0,100],  the smaller value will represent higher priority  Set the default priority of a process as 60. Lower the value, higher the priority.
  + **Dynamic Priority** (DP) is calculated from static priority and niceness.
  + The **niceness** is an integer in the range [0, 10] that measures what percentage of the time the process was sleeping.
  + To calculate the niceness:
    + I recorded the number of ticks the process was sleeping and running from the last time it was scheduled by the kernel using the sleep(), wakeup() and inc_runtime() function.
    + New processes start with niceness equal to 5. After scheduling the process, the niceness is computed as (𝑇𝑖𝑐𝑘𝑠 𝑠𝑝𝑒𝑛𝑡 𝑖𝑛 (𝑠𝑙𝑒𝑒𝑝𝑖𝑛𝑔) 𝑠𝑡𝑎𝑡𝑒/𝑇𝑖𝑐𝑘 𝑠𝑝𝑒𝑛𝑡 𝑖𝑛 (𝑟𝑢𝑛𝑛𝑖𝑛𝑔 + 𝑠𝑙𝑒𝑒𝑝𝑖𝑛𝑔) 𝑠𝑡𝑎𝑡𝑒)\*10.

  + Dynamic Priority is calculated as `DP = max(0,min(SP-niceness+5,100))`.

  + To change the Static Priority I added a new system call  set_priority() as well. This resets niceness to 5 as well.

    ```c
    int set_priority(int new_priority, int pid)
    ```

  + The system call returns the old Static Priority of the process. In case the priority of the process increases(the value is lower than before), then rescheduling is done.
  + CL argument is : `setpriority <priority> <pid>`

#### c) MLFQ

+ 

### Specification 3: procdump

+ It is the extension of procdump function already present in kernel/proc.c for PBS and MLFQ schedulers.
+ It prints a list of processes to the console when a user types Ctrl-p on the console.
+ `priority` (for PBS): Current dynamic-priority of the process.It will range from [0,100].
+ `state`: The current state of the process
+ `rtime`: Total ticks for which the process ran on the CPU till now
+ `wtime`: Total waiting time for the process.
+ `nrun`: Number of times the process was picked by the scheduler

**Q) If a process voluntarily relinquishes control of the CPU(eg. For doing I/O), it leaves the queuing network, and when the process becomes ready again after the I/O, it is inserted at the tail of the same queue, from which it is relinquished earlier. Explain how could this be exploited by a process.**

<u>Ans:</u> After predefined timer interrupt for each queue occurs, the process is demoted to a lower priority queue. This allows the other processes to come forward as well. But if a process voluntarily relinquishes control of the CPU, it leaves the queuing network, and when the process becomes ready again after the I/O, it is inserted at the tail of the same queue, from which it is relinquished earlier. A process can therefore exploit this bug by just relinquishing the CPU control before timer interrupt defined for that queue occurs. This saves it from being demoted and therefore remains in that queue and keeps that respective queue crowded, which subsequently can cause starvation and ageing.

Following is the tabulation for comparison of different schedulers using the given benchmark program `schedulertest.c` and with the help of `waitx` system call: 

### Comparision

| Scheduler | Avg wtime (on my processor) | Avg rtime (on my processor) |
| --------- | --------------------------- | --------------------------- |
| RR        | 24                          | 122                         |
| FCFS      | 21                          | 118                         |
| PBS       | 12                          | 127                         |
| MLFQ      | -                           | -                           |



**************
