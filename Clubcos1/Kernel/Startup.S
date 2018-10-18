%include "../Bootsector/init.inc"

; VBE
VBE_INFO_SEGMENT equ 0x0200						; VBE�� ������ ����Ǵ� ���׸�Ʈ�� ��ġ
VBE_MODE equ 0x117								; VBE ȭ�� ���

; BootInfo
BOOT_INFO equ 0x7000							; BootInfo�� ��ġ
READ_CYLS equ 0									; �о���� �Ǹ��� ��
SCREEN_X equ 4									; ȭ���� X��ǥ ũ��
SCREEN_Y equ 8									; ȭ���� Y��ǥ ũ��
VIDEO_MEMORY equ 12								; ���� �޸��� ������
BOOT_INFO_SIZE equ 20							; BootInfo�� ũ��

; Memory
MINIMAL_MEMORY equ 0x4000000

MEMORY_MAP_ADD equ 0x1000

; Page Table
PAGE_PML4_ADDR equ 0x600000
PAGE_DIRPTR_ADDR equ 0x601000
PAGE_DIRECTORY_ADDR equ 0x602000

PAGE_DIRPTR_ENTRY_COUNT equ 4					; Page DirPtr Entry 4�� -> �� 4GB���� paging

; ����
FLOPPY_CPY_ADD equ 0x100000						; �÷��� ��ũ�� �����Ͱ� ����Ǵ� �ּ�
BOOT_INFO_CPY_ADD equ 0x268000					; BootInfo�� ����Ǵ� �ּ�
KERNEL_CPY_ADD equ 0x500000						; Ŀ���� ����Ǵ� �ּ�
KERNEL_STACK equ 0x500000						; Ŀ�� ������ �ּ�
KERNEL_SIZE equ (1024*540)						; Ŀ���� �ִ� ũ�� = 540KB

[org KERNEL_ADDR]
[bits 16]

Kernel_start:
	mov ax, cs									; cs�� ds�� ���� �Ѵ�
	mov ds, ax

	mov bx, 0
	mov fs, bx

	mov dword [fs:BOOT_INFO + READ_CYLS], READ_CYLINDERS
												; �� �Ǹ����� �о����� BootInfo�� ���
	; VBE
vbe:
	mov ax, VBE_INFO_SEGMENT
	mov es, ax
	mov di, 0									; es:di�� VBE������ ����
	mov ax, 0x4f00								; ax=0x4f00 -> VBE���� �� ���� ���� Ȯ��
	int 0x10									; BIOS ȣ��
	cmp ax, 0x004f								; VBE�� �ִٸ� ax�� ���� 0x004f�̴�
	jne vbe_error								; ax�� 0x004f�� �ƴ϶�� vbe_error�� ����

	mov ax, [es:di + 4]							; es:di + 4���� ���� ������ �ִ�.
	cmp ax, 0x0200								; ������ 0x0200����(2.0����) �̻����� Ȯ���Ѵ�
	jb vbe_error								; 0x0200 �̸��̶�� vbe_error�� ����

	jmp vbe_success								; vbe_success�� ����

vbe_error:
	mov si, vbe_error_msg						; ���� �޼����� �ּ�

real_error:
	mov al, [si]								; �޼����� �� ���� ����
	inc si										; si++
	cmp al, 0									; al�� 0�� ��
	je real_err_stop							; 0�̸� stop���� jmp
	mov ah, 0x0e								; ah=0x0e -> ȭ�鿡 �� ���� ���
	mov bx, 15									; �� �ڵ�
	int 0x10									; BIOS ȣ��(al�� ���� �ڵ�)
	jmp real_error								; ������ ��
real_err_stop:
	hlt											; CPU�� �Ͻ�����
	jmp real_err_stop							; ���ѷ���

vbe_error_msg db "Clubcos0 requires VBE 2.0, but this computer doesn't support VBE 2.0. System stop.", 0

vbe_success:
	mov ax, VBE_INFO_SEGMENT
	mov es, ax
	mov di, 0									; es:di�� ȭ�� ��� ������ ����
	mov ax, 0x4f01								; ax=0x4f01 -> ȭ�� ��� ���� ���� �� ���� Ȯ��
	mov cx, VBE_MODE								; cx -> ȭ�� ���
	int 0x10									; BIOS ȣ��
	cmp ax, 0x004f								; �����ϸ� ax�� ���� 0x004f�̴�
	jne vbe_error								; �ƴ϶�� vbe_error�� ����

	mov eax, 0
	mov ax, [es:di + 0x12]						; ȭ�� ���+0x12 -> ȭ�� X���� ũ��(2byte = word)
	mov [fs:BOOT_INFO + SCREEN_X], eax			; BootInfo�� ���
	mov ax, [es:di + 0x14]						; ȭ�� ���+0x14 -> ȭ�� Y���� ũ��(2byte = word)
	mov [fs:BOOT_INFO + SCREEN_Y], eax			; BootInfo�� ���
	mov eax, [es:di + 0x28]						; ȭ�� ��� ����+0x28 -> ���� �޸��� ��ġ(pointer = 4byte = dword)
	mov [fs:BOOT_INFO + VIDEO_MEMORY], eax		; BootInfo�� ��� (8byte pointer)
	mov dword [fs:BOOT_INFO + VIDEO_MEMORY + 4], 0

	mov ax, 0x4f02								; �׷��� ���� ��ȯ
	mov bx, (0100000b << 9) | VBE_MODE			; ȭ�� ���� Ƚ��=�⺻��, ���� ������ ���� ��, ȭ�� ����
	int 0x10									; BIOS ȣ��
	cmp ax, 0x004f								; �����ϸ� ax�� ���� 0x004f�̴�
	jne vbe_error								; �ƴ϶�� vbe_error�� ����

	; Memory Map (Source from http://wiki.osdev.org/Detecting_Memory_(x86)#Getting_an_E820_Memory_Map )
	xor bx, bx
	mov es, bx
	mov di, MEMORY_MAP_ADD	; es:di -> Memory Map
	xor ebx, ebx			; ebx must be 0 to start
	xor ebp, ebp			; keep an entry count in bp
	mov edx, 0x0534D4150	; Place "SMAP" into edx
	mov eax, 0xe820
	mov [es:di + 20], dword 1	; force a valid ACPI 3.X entry
	mov ecx, 24				; ask for 24 bytes
	int 0x15
	jc short failed		; carry set on first call means "unsupported function"
	mov edx, 0x0534D4150	; Some BIOSes apparently trash this register?
	cmp eax, edx			; on success, eax must have been reset to "SMAP"
	jne short failed
	test ebx, ebx			; ebx = 0 implies list is only 1 entry long (worthless)
	je short failed
	jmp short jmpin
e820lp:
	mov eax, 0xe820			; eax, ecx get trashed on every int 0x15 call
	mov [es:di + 20], dword 1	; force a valid ACPI 3.X entry
	mov ecx, 24				; ask for 24 bytes again
	int 0x15
	jc short e820f			; carry set means "end of list already reached"
	mov edx, 0x0534D4150	; repair potentially trashed register
jmpin:
	jcxz skipent			; skip any 0 length entries
	cmp cl, 20				; got a 24 byte ACPI 3.X response?
	jbe short notext
	test byte [es:di + 20], 1	; if so: is the "ignore this data" bit clear?
	je short skipent
notext:
	mov ecx, [es:di + 8]	; get lower dword of memory region length
	or ecx, [es:di + 12]	; "or" it with upper dword to test for zero
	jz skipent				; if length qword is 0, skip entry
	inc bp					; got a good entry: ++count, move to next storage spot
	add di, 24
skipent:
	test ebx, ebx			; if ebx resets to 0, list is complete
	jne short e820lp
e820f:
	mov dword [MEMORY_MAP_ADD - 4], ebp
	jmp e820end
failed:
	mov dword [MEMORY_MAP_ADD - 4], 0
e820end:
	clc						; flag clear

	; A20 Gate
	mov al, 0xff								; PIC ���ͷ�Ʈ ����
	out 0x21, al								; ������ PIC
	nop											; ��� �ϸ� �� �� ���� �����Ƿ� ��� ����.
	out 0xa1, al								; �����̺� PIC

	cli											; CPU ���ͷ�Ʈ ����

	call waitkbdout								; Ű���� ��Ʈ�귯�� �غ�� ������ ��ٸ�
	mov al, 0xd1								; Ű���� ��Ʈ�귯 ������ ��Ʈ ��ȣ ���� (0xdl = ��Ÿ ��Ʈ)
	out 0x64, al								; out!

	call waitkbdout								; Ű���� ��Ʈ�귯�� �غ�� ������ ��ٸ�
	mov al, 0xdf								; A20 ����Ʈ Ȱ��ȭ ���ɾ�
	out 0x60, al								; out!

	call waitkbdout

	; Protected Mode�� ��ȯ
	lgdt [gdtr]									; GDT �ε�

	mov eax, cr0								; cr0���������� ���� �����Ѵ�.
	or eax, 0x00000001							; Protected Mode
	and eax, 0x7fffffff							; ����¡�� ������� ����
	mov cr0, eax								; mov!

	jmp dword SysCodeSelector:PM_Start			; 32��Ʈ Ŀ�η� �����Ѵ�

[bits 32]
PM_Start:
	mov ax, SysDataSelector						; ���׸�Ʈ �ʱ�ȭ
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov esp, 0x7c00								; �ӽ� ���� �ʱ�ȭ

	; IA-32 ��� ���� ���� Ȯ��
	mov eax, 0x80000001
	cpuid
	test edx, 0x20000000
	jnz IA32_sucs

	jmp ErrorInProtected
IA32_sucs:

	; �޸� üũ
	mov eax, cr0
	push eax
	or eax, 0x60000000
	mov cr0, eax								; ĳ�� ��Ȱ��ȭ

	mov ebx, 0x100000
mem_loop:
	call mem_sub
	jc mem_error
	add ebx, 0x100000
	cmp ebx, MINIMAL_MEMORY
	jb mem_loop

	mov ebx, MINIMAL_MEMORY - 4
	call mem_sub
	jc mem_error

	jmp mem_sucs

mem_sub:
	mov dword [ebx], 0x1234abcd
	xor dword [ebx], 0xffffffff
	cmp dword [ebx], ~0x1234abcd
	jne mem_sub_fail
	xor dword [ebx], 0xffffffff
	cmp dword [ebx], 0x1234abcd
	jne mem_sub_fail
	clc
	ret
mem_sub_fail:
	stc
	ret

mem_error:
	jmp ErrorInProtected

mem_sucs:

	; ������ ����
	mov esi, 0x7c00								; �÷��� ��ũ�� ��ġ (��Ʈ����+���� ������)
	mov edi, FLOPPY_CPY_ADD						; ������ ��
	mov ecx, READ_CYLINDERS * 512 * 18 * 2		; ������ �� ���
	call memcpy									; copy!

	mov esi, FLOPPY_CPY_ADD + 0x4200 + C_Kernel - KERNEL_ADDR	; C��� Ŀ�� ����
	mov edi, KERNEL_CPY_ADD						; ������ ��
	mov ecx, KERNEL_SIZE						; ������ ��
	call memcpy									; copy!

	mov esi, BOOT_INFO
	mov edi, BOOT_INFO_CPY_ADD
	mov ecx, BOOT_INFO_SIZE
	call memcpy

	; Page Table ����
	mov edi, PAGE_PML4_ADDR					; PML4
	mov ecx, 0x1000
	mov al, 0
	call memset
												; A=0, PCD=0, PWT=0, U/S=0, R/W=1, P=1
	mov dword [PAGE_PML4_ADDR], PAGE_DIRPTR_ADDR | 000011b
	mov dword [PAGE_PML4_ADDR+4], 0				; EXB=0, rsrv

	mov edi, PAGE_DIRPTR_ADDR				; Directory Pointer
	mov ecx, 0x1000
	mov al, 0
	call memset

	mov eax, 0
	mov ebx, 0
PageDirPtrLoop:
	mov dword [PAGE_DIRPTR_ADDR + ebx], PAGE_DIRECTORY_ADDR
	add dword [PAGE_DIRPTR_ADDR + ebx], eax
	or dword [PAGE_DIRPTR_ADDR + ebx], 000011b	; A=0, PCD=0, PWT=0, U/S=0, R/W=1, P=1
	mov dword [PAGE_DIRPTR_ADDR + ebx +4], 0	; EXB=0, rsrv
	add eax, 0x1000
	add ebx, 8
	cmp ebx, 8 * PAGE_DIRPTR_ENTRY_COUNT
	jb PageDirPtrLoop


	mov edi, PAGE_DIRECTORY_ADDR			; Directory
	mov ecx, 0x1000
	mov al, 0
	call memset

	mov eax, 0								; Directory Loop...
	mov ebx, 0
	mov edx, 0
PageDirLoop:
	mov dword [PAGE_DIRECTORY_ADDR + ebx], eax		; PAT=0, G=0, PS=1, D=0,
	or dword [PAGE_DIRECTORY_ADDR + ebx], 10000011b	; A=0, PCD=0, PWT=0, U/S=0, R/W=1, P=1
	mov dword [PAGE_DIRECTORY_ADDR + ebx +4], edx	; EXB=0, rsrv

	add ebx, 8
	add eax, 0x200000							; ebx += 2MB;
	adc edx, 0
	cmp ebx, 512 * PAGE_DIRPTR_ENTRY_COUNT * 8	; ���� PAGE_DIRPTR_ENTRY_COUNTȸ ����
	jb PageDirLoop

	; IA-32 Mode�� ��ȯ
	mov eax, cr4
	or eax, 0x00000020							; PAE=1
	mov cr4, eax

	mov eax, PAGE_PML4_ADDR						; PCD=0, PWT=0
	mov cr3, eax

	mov ecx, 0xC0000080
	rdmsr
	or eax, 0x0100								; LMA=1
	wrmsr

	mov eax, cr0
	or eax, 0x80000000							; PG=1
	and eax, ~0x60000000						; CD=0, NW=0
	mov cr0, eax

	jmp SysIA32CodeSelector:IA32_Start

IA32_Start:
	mov ax, SysIA32DataSelector					; ���׸�Ʈ �ʱ�ȭ
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov esp, KERNEL_STACK						; ������ KERNEL_STACK���� ����
	mov ebp, KERNEL_STACK

	jmp KERNEL_CPY_ADD							; Ŀ�η� ����

;-----------;
; Functions ;
;-----------;
memcpy:			; �޸� ���� �Լ�. ds:esi=������ ������ �ּ�, es:edi=����� �ּ�, ecx=ũ��(byte)
	pushad										; ��� ���� �������� �� �Ϻ� �ε��� �������� push

	cld											; ���� �÷���(DF) = 0 -> ���ڿ� ���ɾ� ����� edi, esi ����
	rep movsb									; ����
												; rep = ecx�� 0�� ������ ���ɾ �ݺ�(�ѹ� �ݺ��� ������ ecx����)
												; movsb = mov�� ����Ʈ ���ڿ� ���ɾ�, mov byte [es:edi], [ds:esi]
												; ����Ʈ ���ڿ� ���ɾ��̹Ƿ� ������ edi, esi 1����

	popad										; ��� ���� �������� �� �Ϻ� �ε��� �������� pop
	ret											; return;

memset:			; �޸� ���� �Լ�. es:edi=������ ������ �ּ�, al=������ ��, ecx=ũ��(byte)
	pushad										; ��� ���� �������� �� �Ϻ� �ε��� �������� push

	cld											; ���� �÷���(DF) = 0 -> ���ڿ� ���ɾ� ����� edi ����
	rep stosb									; ����
												; rep = ecx�� 0�� ������ ���ɾ �ݺ�(�ѹ� �ݺ��� ������ ecx����)
												; stosb = mov byte [es:edi], al
												; ����Ʈ ���ڿ� ���ɾ��̹Ƿ� ������ edi 1����

	popad										; ��� ���� �������� �� �Ϻ� �ε��� �������� pop
	ret											; return;

waitkbdout:		; Ű���� ��Ʈ�귯 ��� �Լ�
	push eax									; ����ϴ� ��������(eax) push

wait_loop:
	in al, 0x64									; Ű���� ��Ʈ�귯 ���� in
	and al, 0x2									; ���� �غ� �� �������� 2��° bit�� 0�� ��(���� ZF=1)
	in al, 0x60									; Ű���� ��Ʈ�귯�� ���۸� ���
	jnz wait_loop								; ZF=0(Ű���� ��Ʈ�귯�� �غ� �� �Ÿ� ������ ��

	pop eax										; ����ϴ� ��������(eax) pop
	ret

ErrorInProtected:
	mov esi, X_err_bit
	mov ecx, 5
	mov eax, 5

	mov edi, [BOOT_INFO + VIDEO_MEMORY]
	mov edx, [BOOT_INFO + SCREEN_X]
	shl edx, 1

	shl ecx, 1
ErrorInProtected_putloop:
	call memcpy
	add esi, ecx
	add edi, edx
	dec eax
	jnz ErrorInProtected_putloop
ErrorInProtected_stop:
	hlt
	jmp ErrorInProtected_stop

X_err_bit:
	dw 0x7fff, 0x0000, 0x0000, 0x0000, 0x7fff
	dw 0x0000, 0x7fff, 0x0000, 0x7fff, 0x0000
	dw 0x0000, 0x0000, 0x7fff, 0x0000, 0x0000
	dw 0x0000, 0x7fff, 0x0000, 0x7fff, 0x0000
	dw 0x7fff, 0x0000, 0x0000, 0x0000, 0x7fff


;-----------;
; GDT Table ;
;-----------;
gdtr:
	dw gdt_end - gdt - 1						; GDT�� ũ��
	dd gdt										; GDT�� ���� �ּ�

gdt:											; GDT�� ����

NullSelector equ (0 * 8)						; ����� NULL ��ũ����
	dw 0										; ���� 0
	dw 0
	db 0
	db 0
	db 0
	db 0

SysIA32CodeSelector equ (1 * 8)				; IA-32��� �ڵ� ���׸�Ʈ ��ũ����
	dw 0xffff									; Limit 0~15 bit = 0xffff
	dw 0										; Base 0~15 bit = 0
	db 0										; Base 16~23 bit = 0
	db 10011010b								; P=1, DPL=0, Code, non-conforming, readable
	db 10101111b								; G=1, D=0, L=1, Limit 16~19 bit = 0xf (Limit = 0xfffff)
	db 0

SysIA32DataSelector equ (2 * 8)				; IA-32��� ������ ���׸�Ʈ ��ũ����
	dw 0xffff									; Limit 0~15 bit = 0xffff
	dw 0										; Base 0~15 bit = 0
	db 0										; Base 16~23 bit = 0
	db 10010010b								; P=1, DPL=0, Code, non-conforming, readable
	db 10101111b								; G=1, D=0, L=1, Limit 16~19 bit = 0xf (Limit = 0xfffff)
	db 0

SysCodeSelector equ (3 * 8)					; �ڵ� ���׸�Ʈ ��ũ����
	dw 0xffff									; Limit 0~15 bit = 0xffff
	dw 0										; Base 0~15 bit = 0
	db 0										; Base 16~23 bit = 0
	db 10011010b								; P=1, DPL=0, Code, non-conforming, readable
	db 11001111b								; G=1, D=1, Limit 16~19 bit = 0xf (Limit = 0xfffff)
	db 0										; Base 24~32 bit = 0 (Base = 0)

SysDataSelector equ (4 * 8)					; ������ ���׸�Ʈ ��ũ����
	dw 0xffff									; Limit 0~15bit = 0xffff
	dw 0										; Base 0~15 bit = 0
	db 0										; Base 16~23 bit = 0
	db 10010010b								; P=1, DPL=0, Data, expand-up, writable
	db 11001111b								; G=1, D=1, Limit 16~19 bit = 0xf (Limit = 0xfffff)
	db 0										; Base 24~32 bit = 0 (Base = 0)

gdt_end:										; GDT�� �� + 1

C_Kernel:										; C���� ���� Ŀ���� ����