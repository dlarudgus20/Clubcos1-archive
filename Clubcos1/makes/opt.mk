##################################
# opt.mk
##################################

# Global
GCC_OPT := -m64 -ffreestanding -std=gnu99 \
			 -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-3dnow \
			 $(GCC_OPT)
NASM_OPT := $(NASM_OPT)

# Release
GCC_OPT := -O3 $(GCC_OPT)
NASM_OPT := $(NASM_OPT)
# Debug
#GCC_OPT := -ggdb $(GCC_OPT)
#NASM_OPT := -g $(NASM_OPT)
