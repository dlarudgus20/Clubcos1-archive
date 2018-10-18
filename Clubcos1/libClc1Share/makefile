##################################
# libClc1Share makefile
##################################

# 변수
C_SOURCES = $(wildcard *.c)
C_OBJECTS = $(patsubst %.c, tmp/%.o, $(C_SOURCES))

ASM_SOURCES = $(wildcard *.asm)
ASM_OBJECTS = $(patsubst %.asm, tmp/%.o, $(ASM_SOURCES))

include ../makes/opt.mk
MAKE_DEP_LIST = makefile ../makes/opt.mk

# 기본 규칙
all: tmp/Dependency.dep
	##################################
	# libClc1Share makefile
	##################################

	make -r bin/libClc1Share.a

# 생성 규칙
bin/libClc1Share.a: $(ASM_OBJECTS) $(C_OBJECTS) $(MAKE_DEP_LIST)
	x86_64-pc-linux-ar rcs bin/libClc1Share.a $(ASM_OBJECTS) $(C_OBJECTS)

tmp/Dependency.dep: $(C_SOURCES) $(MAKE_DEP_LIST)
	x86_64-pc-linux-gcc -MM $(C_SOURCES) > tmp/Dependency.dep

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
