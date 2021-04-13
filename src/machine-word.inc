.ifdef RISCV32
.set XLEN,      32
.endif
.ifdef RISCV64
.set XLEN,      64
.endif

.ifdef XLEN
.equ REGBITS,   XLEN
.equ REGBYTES,  XLEN/8
.equ LOG2_SIZEOF_PTR, 2
.equ SIZEOF_PTR, (1 << LOG2_SIZEOF_PTR)
.else
.equ XLEN,      64
.equ REGBITS,   64
.equ REGBYTES,  8
.equ LOG2_SIZEOF_PTR, 3
.equ SIZEOF_PTR, (1 << LOG2_SIZEOF_PTR)
.endif
.if XLEN == 32
    .set RISCV32, 1
    .macro lx a, offset, addr
        lw \a, (\offset*REGBYTES)\addr
    .endm
    .macro sx a, offset, addr
        sw \a, (\offset*REGBYTES)\addr
    .endm
    .macro pointer a
        .word \a
    .endm
    .macro machineword a
        .word \a
    .endm
.else
    .set RISCV64, 1
    .macro lx a, offset, addr
        ld \a, (\offset*REGBYTES)\addr
    .endm
    .macro sx a, offset, addr
        sd \a, (\offset*REGBYTES)\addr
    .endm
    .macro pointer a
        .dword \a
    .endm
    .macro machineword a
        .dword \a
    .endm
.endif

.macro addxi a, b, number_of_regs
    addi \a, \b, \number_of_regs * REGBYTES
.endm

.macro stackalloc_x number_of_regs
    addxi sp, sp, -(\number_of_regs)
.endm

.macro stackfree_x number_of_regs
    addxi sp, sp,  (\number_of_regs)
.endm
