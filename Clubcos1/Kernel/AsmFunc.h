#pragma once

typedef struct tagGdt Gdt;
void LoadGdt(uint16_t size, Gdt *addr);

typedef struct tagIdt Idt;
void LoadIdt(uint16_t size, Idt *addr);

uintptr_t GetCr0();
void SetCr0(uintptr_t cr0);
