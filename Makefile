ARCH = armv7-a
MCPU = cortex-a8

TARGET = rvpb#rvpb 폴더 타겟

CC = arm-none-eabi-gcc
AS = arm-none-eabi-as
LD = arm-none-eabi-gcc
OC = arm-none-eabi-objcopy

LINKER_SCRIPT = ./samos.ld
MAP_FILE = build/samos.map

ASM_SRCS = $(wildcard boot/*.S)
ASM_OBJS = $(patsubst boot/%.S, build/%.o, $(ASM_SRCS))

VPATH = boot \
	hal/$(TARGET) \
	lib

C_SRCS = $(notdir $(wildcard boot/*.c)) #소스파일 모으기
C_SRCS += $(notdir $(wildcard hal/$(TARGET)/*.c)) #하드웨어에 맞는 소스파일
C_SRCS += $(notdir $(wildcard lib/*.c))
C_OBJS = $(patsubst %.c, build/%.o, $(C_SRCS))

INC_DIRS = -I include	\
	   -I hal	\
	   -I hal/$(TARGET)	\
	   -I lib

CFLAGS = -c -g -std=c11 -mthumb-interwork

LDFLAGS = -nostartfiles -nostdlib -nodefaultlibs -static -lgcc

samos = build/samos.axf
samos_bin = build/samos.bin

.PHONY: all clean run debug gdb

all: $(samos)

clean:
	@rm -fr build

run: $(samos)
	qemu-system-arm -M realview-pb-a8 -kernel $(samos) -nographic

debug: $(samos)
	qemu-system-arm -M realview-pb-a8 -kernel $(samos) -S -gdb tcp::1234,ipv4 -display none

gdb:
	gdb-multiarch $(samos) -ex "target remote 127.0.0.1:1234"

$(samos): $(ASM_OBJS) $(C_OBJS) $(LINKER_SCRIPT)
	$(LD) -n -T $(LINKER_SCRIPT) -o $(samos) $(ASM_OBJS) $(C_OBJS) -Wl,-Map=$(MAP_FILE) $(LDFLAGS)
	$(OC) -O binary $(samos) $(samos_bin)

build/%.o: %.S
	mkdir -p $(shell dirname $@)
	$(CC) -march=$(ARCH) -mcpu=$(MCPU) -marm $(INC_DIRS) $(CFLAGS) -o $@ $< 

build/%.o: %.c
	mkdir -p $(shell dirname $@)
	$(CC) -march=$(ARCH) -mcpu=$(MCPU) -marm $(INC_DIRS) $(CFLAGS) -o $@ $<
