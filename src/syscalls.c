// Entry points for all the syscalls here

#include "syscalls.h"

// for fun let's pretend syscall table is kinda like 32bit Linux on x86,
// /usr/include/asm/unistd_32.h: __NR_restart_syscall 0, __NR_exit 1, _NR_fork 2, __NR_read 3, __NR_write 4
void *syscall_vector[] = {
/* 0 */     sys_restart,
/* 1 */     sys_exit,
/* 2 */     sys_fork,
/* 3 */     sys_read,
/* 4 */     sys_write,
};

void sys_restart() {
    poweroff();
}

void sys_exit() {
    // TODO: implement
}

void sys_fork() {
    // TODO: implement
}

void sys_read() {
    // TODO: implement
}

void sys_write() {
    prints();
}
