ARMGNU ?= aarch64-linux-gnu

AOPS = -g --warn --fatal-warnings
ASM_SRCS = $(wildcard *.s)
ASM_OBJS = $(ASM_SRCS:%.s=%.o)

GDB_REGISTERS = 'x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16 x17 x18 x19 x20 x21 x22 x23 x24 x25 x26 x27 x28 x29 x30 sp pc cpsr'
GDB_FLAGS = -x "~/dashboard.gdbinit" -ex "set architecture aarch64" -ex "target remote localhost:1234" --ex "dashboard registers -style list $(GDB_REGISTERS)"
GDB_SYMBOL_FILE_FLAGS = -ex "set confirm off" -ex "add-symbol-file app.o 0x900c8" -ex "set confirm on"

.PHONY: clean

all: kernel8.img

%.o: %.s
	$(ARMGNU)-as $(AOPS) $< -o $@

clean:
	rm -f *.o memory_map.txt kernel8.list kernel8.img kernel8.elf

kernel8.img: memmap $(ASM_OBJS)
	$(ARMGNU)-ld $(ASM_OBJS) -T memmap -o kernel8.elf -M > memory_map.txt
	$(ARMGNU)-objdump -D kernel8.elf > kernel8.list
	$(ARMGNU)-objcopy kernel8.elf -O binary kernel8.img

runQEMU: clean kernel8.img
	qemu-system-aarch64 -s -M raspi3b -kernel kernel8.img -serial stdio -qtest unix:/tmp/qtest.sock,server,nowait

debugQEMU: clean kernel8.img
	qemu-system-aarch64 -s -S -M raspi3b -kernel kernel8.img -serial stdio -qtest unix:/tmp/qtest.sock,server,nowait

runGPIOM: bin/gpiom
	./bin/gpiom

runSGPIOM: bin/sgpiom
	cd "./bin" ; ./sgpiom ; cd ".."

runGDB:
	gdb-multiarch $(GDB_FLAGS) $(GDB_SYMBOL_FILE_FLAGS)

runGDBnf:
	gdb-multiarch $(GDB_FLAGS)