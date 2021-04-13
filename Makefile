# If local QEmu build does not exist, use system wide installed QEmu
QEMU ?= ./qemu-build/bin/qemu-system-riscv64
ifeq ($(wildcard $(QEMU)),)
	QEMU = qemu-system-riscv64
endif
QEMU32 ?= ./qemu-build/bin/qemu-system-riscv32
ifeq ($(wildcard $(QEMU32)),)
	QEMU32 = qemu-system-riscv32
endif

DEBUG_FLAGS := ""
ifeq ($(DBG),1)
	# DEBUG_FLAGS are gdb-related flags to QEMU:
	# -S only loads an image, but stops the CPU, giving a chance to attach gdb
	# -s is a shorthand to listen for gdb on localhost:1234
	DEBUG_FLAGS = -s -S
	QEMU += $(DEBUG_FLAGS)
	QEMU32 += $(DEBUG_FLAGS)
endif

RISCV64_GCC ?= riscv64-linux-gnu-gcc
ifeq (, $(shell which $(RISCV64_GCC)))
	RISCV64_GCC = riscv64-unknown-elf-gcc
endif
# Spike, the RISC-V ISA Simulator (https://github.com/riscv/riscv-isa-sim)
SPIKE ?= ./riscv-isa-sim/build/build/bin/spike
ifeq ($(wildcard $(SPIKE)),)
	SPIKE = spike
endif
# Proxy Kernel, a lightweight app execution environment that can host RISC-V ELF binaries (https://github.com/riscv/riscv-pk)
RISCV_PK ?= riscv-pk/build/build/riscv64-linux-gnu/bin/pk
ifeq ($(wildcard $(RISCV_PK)),)
	RISCV_PK = pk
endif

OUT := out
BINS := $(OUT)/test_sifive_u \
	$(OUT)/user_sifive_u \
	$(OUT)/test_sifive_e \
	$(OUT)/user_sifive_e \
	$(OUT)/test_sifive_e32 \
	$(OUT)/user_sifive_e32 \
	$(OUT)/test_virt \
	$(OUT)/user_virt

# This target makes all the binaries depend on existence (but not timestamp) of
# $(OUT), which lets us avoid repetitive 'mkdir -p out'
$(BINS): | $(OUT)

all: $(BINS)
baremetal: all

# Shortcuts
run32: run-baremetal32
runm: run-baremetal
runb: run-baremetal
runs: run-spike
runl: run-linux

TEST_DEPS = src/baremetal-fib.s src/baremetal-print.s src/baremetal-poweroff.s
USER_DEPS = src/boot.s src/baremetal-print.s \
			src/baremetal-poweroff.s src/userland.c src/kernel.c src/syscalls.c
TEST_SIFIVE_U_DEPS = $(TEST_DEPS)
USER_SIFIVE_U_DEPS = $(USER_DEPS)
TEST_SIFIVE_E_DEPS = $(TEST_DEPS)
USER_SIFIVE_E_DEPS = $(USER_DEPS)
TEST_SIFIVE_E32_DEPS = $(TEST_DEPS)
USER_SIFIVE_E32_DEPS = $(USER_DEPS)
TEST_VIRT_DEPS = $(TEST_DEPS)
USER_VIRT_DEPS = $(USER_DEPS)


# $ riscv64-linux-gnu-objdump -s -j .rodata out/test_virt


.PHONY: test
test: $(OUT)/test-output.txt
	@diff -u testdata/want-output.txt $<
	@echo "OK"

$(OUT)/test-output.txt: $(OUT)/test_virt
	@$(QEMU) -nographic -machine virt -bios none -kernel $< > $@

.PHONY: run-baremetal
run-baremetal: $(OUT)/user_sifive_u
	$(QEMU) -nographic -machine sifive_u -bios none -kernel $<

.PHONY: run-baremetal32
run-baremetal32: $(OUT)/user_sifive_e32
	$(QEMU32) -nographic -machine sifive_e -bios none -kernel $<

GCC_FLAGS=-static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles \
          -Tsrc/baremetal.ld -Iinclude

$(OUT)/test_sifive_u: ${TEST_SIFIVE_U_DEPS}
	$(RISCV64_GCC) -march=rv64g -mabi=lp64 $(GCC_FLAGS) \
		${TEST_SIFIVE_U_DEPS} -o $@

$(OUT)/user_sifive_u: ${USER_SIFIVE_U_DEPS}
	$(RISCV64_GCC) -march=rv64g -mabi=lp64 $(GCC_FLAGS) \
		${USER_SIFIVE_U_DEPS} -o $@

$(OUT)/test_sifive_e: ${TEST_SIFIVE_E_DEPS}
	$(RISCV64_GCC) -march=rv64g -mabi=lp64 $(GCC_FLAGS) \
		-Wl,--defsym,ROM_START=0x20400000 -Wa,--defsym,UART=0x10013000 \
		${TEST_SIFIVE_E_DEPS} -o $@

$(OUT)/user_sifive_e: ${USER_SIFIVE_E_DEPS}
	$(RISCV64_GCC) -march=rv64g -mabi=lp64 $(GCC_FLAGS) \
		-Wl,--defsym,ROM_START=0x20400000 -Wa,--defsym,UART=0x10013000 \
		${USER_SIFIVE_E_DEPS} -o $@

$(OUT)/test_sifive_e32: ${TEST_SIFIVE_E32_DEPS}
	$(RISCV64_GCC) -march=rv32g -mabi=ilp32 $(GCC_FLAGS) \
		-Wl,--defsym,ROM_START=0x20400000 -Wa,--defsym,UART=0x10013000 \
		-Wa,--defsym,XLEN=32 \
		${TEST_SIFIVE_E32_DEPS} -o $@

$(OUT)/user_sifive_e32: ${USER_SIFIVE_E32_DEPS}
	$(RISCV64_GCC) -march=rv32g -mabi=ilp32 $(GCC_FLAGS) \
		-Wl,--defsym,ROM_START=0x20400000 -Wa,--defsym,UART=0x10013000 \
		-Wa,--defsym,XLEN=32 \
		${USER_SIFIVE_E32_DEPS} -o $@

$(OUT)/test_virt: ${TEST_VIRT_DEPS}
	$(RISCV64_GCC) -march=rv64g -mabi=lp64 $(GCC_FLAGS) \
		-Wa,--defsym,UART=0x10000000 -Wa,--defsym,QEMU_EXIT=0x100000 \
		${TEST_VIRT_DEPS} -o $@

$(OUT)/user_virt: ${USER_VIRT_DEPS}
	$(RISCV64_GCC) -march=rv64g -mabi=lp64 $(GCC_FLAGS) \
		-Wa,--defsym,UART=0x10000000 -Wa,--defsym,QEMU_EXIT=0x100000 \
		${USER_VIRT_DEPS} -o $@

$(OUT):
	mkdir -p $(OUT)

run-spike: elf
	$(SPIKE) $(RISCV_PK) generic-elf/hello bbl loader

run-linux: initrd
	$(QEMU) -nographic -machine virt \
     -kernel linux/arch/riscv/boot/Image -append "root=/dev/vda ro console=ttyS0" \
     -drive file=busybox/busybox,format=raw,id=hd0 \
     -device virtio-blk-device,drive=hd0 \
     -initrd initramfs-busybox-riscv64.cpio.gz

clean:
	rm -Rf $(OUT)
	rm -Rf initramfs

prereqs:
	# OSX brew install gawk gnu-sed gmp mpfr libmpc isl zlib expat
	# OSX brew install riscv-tools qemu
	sudo apt --yes install \
		autoconf \
		automake \
		autotools-dev \
		bc \
		bison \
		build-essential \
		curl \
		device-tree-compiler \
		flex \
		gawk \
		gcc-riscv64-linux-gnu \
		git \
		libexpat-dev \
		libglib2.0-dev \
		libpixman-1-dev \
		libgmp-dev \
		libmpc-dev \
		libmpfr-dev \
		libtool \
		patchutils \
		pkg-config \
		texinfo gperf \
		zlib1g-dev

clone:
	git clone https://github.com/qemu/qemu
	git clone https://github.com/torvalds/linux
	git clone https://git.busybox.net/busybox
	git clone https://github.com/riscv/riscv-isa-sim
	git clone https://github.com/riscv/riscv-pk

.PHONY: qemu
qemu:
	./scripts/build-qemu.sh

.PHONY: busybox
busybox:
	./scripts/build-busybox.sh

.PHONY: linux
linux:
	./scripts/build-linux.sh

.PHONY: initrd
initrd:
	./scripts/build-initrd.sh

$(OUT)/generic-elf/hello:
	@mkdir -p $(OUT)/generic-elf
	$(RISCV64_GCC) -static -o $@ src/generic-elf/hello.c src/generic-elf/hiasm.S
