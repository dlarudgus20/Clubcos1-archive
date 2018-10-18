##################################
# Kernel makefile
##################################

# 변수
LIB_CLC1SHARE_PATH = ../libClc1Share
LIB_CLC1SHARE = Clc1Share

C_SOURCES = $(wildcard *.c)
C_OBJECTS = $(patsubst %.c, tmp/%.o, $(C_SOURCES))

ASM_SOURCES = $(wildcard *.asm)
ASM_OBJECTS = $(patsubst %.asm, tmp/%.o, $(ASM_SOURCES))

ASM_MAIN_OBJECT = tmp/AsmFunc.o
ASM_OTHER_OBJECTS = $(subst $(ASM_MAIN_OBJECT), , $(ASM_OBJECTS))

GCC_OPT = -I $(LIB_CLC1SHARE_PATH)

include ../makes/opt.mk
MAKE_DEP_LIST = makefile ../makes/opt.mk

# 기본 규칙
all: tmp/Dependency.dep
	##################################
	# Kernel makefile
	##################################

	make -r bin/Clubcos0.sys

# 생성 규칙
bin/Clubcos0.sys: tmp/Startup.bin tmp/C_Kernel.bin $(MAKE_DEP_LIST)
	cat tmp/Startup.bin tmp/C_Kernel.bin > bin/Clubcos0.sys

tmp/Startup.bin: Startup.S ../Bootsector/init.inc $(MAKE_DEP_LIST)
	nasm -f bin -o tmp/Startup.bin -l tmp/Startup.lst Startup.S

tmp/C_Kernel.bin: $(ASM_OBJECTS) $(C_OBJECTS) $(MAKE_DEP_LIST)
	x86_64-pc-linux-ld -melf_x86_64 -T elf_x86_64.x -nostdlib -Ttext 0x500000 -e ClcEntry \
		 -o tmp/C_Kernel.exe\
		-Map tmp/C_Kernel.map \
		$(ASM_MAIN_OBJECT) $(ASM_OTHER_OBJECTS) $(C_OBJECTS) \
		-L $(LIB_CLC1SHARE_PATH)/bin -l $(LIB_CLC1SHARE)
	x86_64-pc-linux-objcopy -R .note -R .comment -R .absolut \
		-S -O binary \
		tmp/C_Kernel.exe tmp/C_Kernel.bin
	x86_64-pc-linux-nm --line-numbers tmp/C_Kernel.exe | sort > tmp/C_Kernel_nm.txt
	ndisasm -b 64 tmp/C_Kernel.bin > tmp/C_Kernel_disasm.txt

tmp/Dependency.dep: $(C_SOURCES) $(MAKE_DEP_LIST)
	x86_64-pc-linux-gcc $(GCC_OPT) -MM $(C_SOURCES) > tmp/Dependency.dep

# 일반 규칙
tmp/%.o: %.c $(MAKE_DEP_LIST)
	x86_64-pc-linux-gcc $(GCC_OPT) -o $@ -c $<
	x86_64-pc-linux-objdump -M intel -D $@ > tmp/$*_dump.txt

tmp/%.o: %.asm $(MAKE_DEP_LIST)
	nasm -f elf64 $(NASM_OPT) -o $@ -l tmp/$*.lst $<

# 커맨드
clean:
	-rm tmp/*
	-rm bin/*

ifeq (tmp/Dependency.dep, $(wildcard tmp/Dependency.dep))
include tmp/Dependency.dep
endif
