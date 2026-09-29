ARCH = armv7-a
MCPU = cortex-a8

CC = arm-none-eabi-gcc
AS = arm-none-eabi-as
LD = arm-none-eabi-ld
OC = arm-none-eabi-objcopy

LINKER_SCRIPT = ./samos.ld

ASM_SRCS = $(wildcard boot/*.S)
ASM_OBJS = $(patsubst boot/%.S, build/%.o, $(ASM_SRCS))

samos = build/samos.axf
samos_bin = build/samos.bin

.PHONY: all clean run debug gdb

all: $(samos)

clean:
	@rm -fr build

run: $(samos)
	qemu-system-arm -M realview-pb-a8 -kernel $(samos)

debug: $(samos)
	qemu-system-arm -M realview-pb-a8 -kernel $(samos) -S -gdb tcp::1234,ipv4

gdb:
	gdb-multiarch

$(samos): $(ASM_OBJS) $(LINKER_SCRIPT)
	$(LD) -n -T $(LINKER_SCRIPT) -o $(samos) $(ASM_OBJS)
	$(OC) -O binary $(samos) $(samos_bin)

build/%.o: boot/%.S
	mkdir -p $(shell dirname $@)
	$(AS) -march=$(ARCH) -mcpu=$(MCPU) -g -o $@ $<
