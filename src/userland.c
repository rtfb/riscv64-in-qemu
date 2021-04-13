#include "sys.h"
#include "userland.h"

#define PRINT_FREQ (10*1000*1000)

uint64_t get_clock_cycles();
int m_read_hart_id();

int _userland u_main() {
    sys_puts("Hello from U-mode!\n");

    sys_puts("Read user CSR: ");
    uint64_t clock_cycles = get_clock_cycles();
    sys_puts("OK\n");

    sys_puts("Read from memory: ");
    int word = *a_string_in_user_mem_ptr;
    sys_puts("OK\n");

    sys_puts("Read from unaligned memory: ");
    char *cptr = (char*)a_string_in_user_mem_ptr;
    cptr++;
    char c = *cptr;
    sys_puts("OK\n");

    sys_puts("Read/write stack: ");
    push_pop_stack();
    sys_puts("OK\n");

    sys_puts("Illegal write to read-only memory: ");
    // XXX: this ought to fail, but succeeds in QEMU for some reason:
    *a_string_in_user_mem_ptr = 7;
    sys_puts("OK\n");

    sys_puts("Illegal read from protected CSR: ");
    // causes Illegal instruction (mcause=2) in User mode:
    int hart_id = m_read_hart_id();

    sys_puts("Illegal read from protected memory: ");
    // causes Load access fault (mcause=5) in User mode:
    word = *msg_m_hello_ptr;

    int64_t counter = 0;
    int flipper = 0;
    while (1) {
        counter++;
        if (counter % PRINT_FREQ == 0) {
            flipper++;
            if ((flipper & 1) == 0) {
                sys_puts("-");
            } else {
                sys_puts("|");
            }
        }
    }

    sys_puts("C Done.\n");
    return 0;
}

int _userland u_main2() {
    sys_puts("Hello from U-mode 2!\n");

    sys_puts("Read user CSR: ");
    uint64_t clock_cycles = get_clock_cycles();
    sys_puts("OK\n");

    sys_puts("Read from memory: ");
    int word = *a_string_in_user_mem_ptr;
    sys_puts("OK\n");

    sys_puts("Read from unaligned memory: ");
    char *cptr = (char*)a_string_in_user_mem_ptr;
    cptr++;
    char c = *cptr;
    sys_puts("OK\n");

    sys_puts("Read/write stack: ");
    push_pop_stack();
    sys_puts("OK\n");

    sys_puts("Illegal write to read-only memory: ");
    // XXX: this ought to fail, but succeeds in QEMU for some reason:
    *a_string_in_user_mem_ptr = 7;
    sys_puts("OK\n");

    sys_puts("Illegal read from protected CSR: ");
    // causes Illegal instruction (mcause=2) in User mode:
    int hart_id = m_read_hart_id();

    sys_puts("Illegal read from protected memory: ");
    // causes Load access fault (mcause=5) in User mode:
    word = *msg_m_hello_ptr;

    int64_t counter = 0;
    int flipper = 0;
    while (1) {
        counter++;
        if (counter % PRINT_FREQ == 0) {
            flipper++;
            if ((flipper & 1) == 0) {
                sys_puts(".");
            } else {
                sys_puts("o");
            }
        }
    }

    sys_puts("C Done.\n");
    return 0;
}

uint64_t _userland get_clock_cycles() {
    register uint64_t a0 asm ("a0");
#if XLEN == 64
    asm volatile (
        "csrr a0, cycle"
        : "=r"(a0)  // output in a0
    );
#elif XLEN == 32
    // TODO
#else
    #error Unknown xlen
#endif
    return a0;
}

int _userland m_read_hart_id() {
    register int a0 asm ("a0");
    asm volatile (
        "csrr a0, mhartid"
        : "=r"(a0)  // output in a0
    );
    return a0;
}

void _userland push_pop_stack() {
    asm(
#if XLEN == 64
        "addi sp, sp, -16;"
        "ld   t0, 0(sp);"
        "ld   t1, 8(sp);"
        "sd   t0, 0(sp);"
        "sd   t1, 8(sp);"
        "addi sp, sp, 16;"
#elif XLEN == 32
        "addi sp, sp, -8;"
        "lw   t0, 0(sp);"
        "lw   t1, 4(sp);"
        "sw   t0, 0(sp);"
        "sw   t1, 4(sp);"
        "addi sp, sp, 8;"
#else
    #error Unknown xlen
#endif
    : // no output
    : // no input
    : "t0", "t1"  // t0 and t1 get clobbered
    );
}
