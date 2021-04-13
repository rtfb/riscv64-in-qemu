#ifndef _SYSCALLS_H_
#define _SYSCALLS_H_

void sys_restart();
void sys_exit();
void sys_fork();
void sys_read();
void sys_write();

// These are implemented in assembler as of now:
extern void prints();
extern void poweroff();

#endif // ifndef _SYSCALLS_H_
