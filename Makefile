CROSS_COMPILE ?= arm-none-eabi-

CC = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
SIZE = $(CROSS_COMPILE)size
GDB = $(CROSS_COMPILE)gdb
OPENOCD = openocd

CFLAGS := -mthumb -mcpu=cortex-m4
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Os -std=gnu99 -Wall
LDFLAGS := -nostartfiles -Wl,--gc-sections
LDSCRIPT = stm32f429.lds

obj-y += foo.o

all: test.elf test.bin

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

test.elf: $(obj-y) Makefile $(LDSCRIPT)
	$(CC) $(CFLAGS) -T $(LDSCRIPT) -Wl,-Map,test.map $(LDFLAGS) -o test.elf $(obj-y)

test.bin: test.elf Makefile
	$(OBJCOPY) -Obinary test.elf test.bin
	$(OBJDUMP) -S test.elf > test.lst
	$(SIZE) test.elf

clean:
	@rm -f *.o *.elf *.bin *.lst

flash: test.bin
	$(OPENOCD) -f board/stm32f429discovery.cfg \
	  -c "init" \
	  -c "reset init" \
	  -c "flash probe 0" \
	  -c "flash info 0" \
	  -c "flash write_image erase test.bin 0x08000000" \
	  -c "reset run" \
	  -c "shutdown"

debug: test.elf test.bin
	$(GDB) test.elf -ex "target remote :3333" -ex "monitor reset halt"
