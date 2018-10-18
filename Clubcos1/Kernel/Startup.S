%include "../Bootsector/init.inc"

; VBE
VBE_INFO_SEGMENT equ 0x0200						; VBE의 정보가 저장되는 세그먼트의 위치
VBE_MODE equ 0x117								; VBE 화면 모드

; BootInfo
BOOT_INFO equ 0x7000							; BootInfo의 위치
READ_CYLS equ 0									; 읽어들인 실린더 수
SCREEN_X equ 4									; 화면의 X좌표 크기
SCREEN_Y equ 8									; 화면의 Y좌표 크기
VIDEO_MEMORY equ 12								; 비디오 메모리의 포인터
BOOT_INFO_SIZE equ 20							; BootInfo의 크기

; Memory
MINIMAL_MEMORY equ 0x4000000

MEMORY_MAP_ADD equ 0x1000

; Page Table
PAGE_PML4_ADDR equ 0x600000
PAGE_DIRPTR_ADDR equ 0x601000
PAGE_DIRECTORY_ADDR equ 0x602000

PAGE_DIRPTR_ENTRY_COUNT equ 4					; Page DirPtr Entry 4개 -> 총 4GB까지 paging

; 복사
FLOPPY_CPY_ADD equ 0x100000						; 플로피 디스크의 데이터가 복사되는 주소
BOOT_INFO_CPY_ADD equ 0x268000					; BootInfo가 복사되는 주소
KERNEL_CPY_ADD equ 0x500000						; 커널이 복사되는 주소
KERNEL_STACK equ 0x500000						; 커널 스택의 주소
KERNEL_SIZE equ (1024*540)						; 커널의 최대 크기 = 540KB

[org KERNEL_ADDR]
[bits 16]

Kernel_start:
	mov ax, cs									; cs와 ds를 같게 한다
	mov ds, ax

	mov bx, 0
	mov fs, bx

	mov dword [fs:BOOT_INFO + READ_CYLS], READ_CYLINDERS
												; 몇 실린더를 읽었는지 BootInfo에 기록
	; VBE
vbe:
	mov ax, VBE_INFO_SEGMENT
	mov es, ax
	mov di, 0									; es:di에 VBE정보가 들어간다
	mov ax, 0x4f00								; ax=0x4f00 -> VBE정보 및 존재 유무 확인
	int 0x10									; BIOS 호출
	cmp ax, 0x004f								; VBE가 있다면 ax의 값은 0x004f이다
	jne vbe_error								; ax가 0x004f가 아니라면 vbe_error로 간다

	mov ax, [es:di + 4]							; es:di + 4에는 버전 정보가 있다.
	cmp ax, 0x0200								; 버전이 0x0200인지(2.0인지) 이상인지 확인한다
	jb vbe_error								; 0x0200 미만이라면 vbe_error로 간다

	jmp vbe_success								; vbe_success로 간다

vbe_error:
	mov si, vbe_error_msg						; 에러 메세지의 주소

real_error:
	mov al, [si]								; 메세지의 한 글자 읽음
	inc si										; si++
	cmp al, 0									; al과 0을 비교
	je real_err_stop							; 0이면 stop으로 jmp
	mov ah, 0x0e								; ah=0x0e -> 화면에 한 글자 출력
	mov bx, 15									; 색 코드
	int 0x10									; BIOS 호출(al엔 글자 코드)
	jmp real_error								; 루프를 돔
real_err_stop:
	hlt											; CPU를 일시정지
	jmp real_err_stop							; 무한루프

vbe_error_msg db "Clubcos0 requires VBE 2.0, but this computer doesn't support VBE 2.0. System stop.", 0

vbe_success:
	mov ax, VBE_INFO_SEGMENT
	mov es, ax
	mov di, 0									; es:di에 화면 모드 정보가 들어간다
	mov ax, 0x4f01								; ax=0x4f01 -> 화면 모드 지원 여부 및 정보 확인
	mov cx, VBE_MODE								; cx -> 화면 모드
	int 0x10									; BIOS 호출
	cmp ax, 0x004f								; 성공하면 ax의 값은 0x004f이다
	jne vbe_error								; 아니라면 vbe_error로 간다

	mov eax, 0
	mov ax, [es:di + 0x12]						; 화면 모드+0x12 -> 화면 X방향 크기(2byte = word)
	mov [fs:BOOT_INFO + SCREEN_X], eax			; BootInfo에 기록
	mov ax, [es:di + 0x14]						; 화면 모드+0x14 -> 화면 Y방향 크기(2byte = word)
	mov [fs:BOOT_INFO + SCREEN_Y], eax			; BootInfo에 기록
	mov eax, [es:di + 0x28]						; 화면 모드 정보+0x28 -> 비디오 메모리의 위치(pointer = 4byte = dword)
	mov [fs:BOOT_INFO + VIDEO_MEMORY], eax		; BootInfo에 기록 (8byte pointer)
	mov dword [fs:BOOT_INFO + VIDEO_MEMORY + 4], 0

	mov ax, 0x4f02								; 그래픽 모드로 전환
	mov bx, (0100000b << 9) | VBE_MODE			; 화면 갱신 횟수=기본값, 선형 프레임 버퍼 모델, 화면 지움
	int 0x10									; BIOS 호출
	cmp ax, 0x004f								; 성공하면 ax의 값은 0x004f이다
	jne vbe_error								; 아니라면 vbe_error로 간다

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
	mov al, 0xff								; PIC 인터럽트 금지
	out 0x21, al								; 마스터 PIC
	nop											; 계속 하면 안 될 때도 있으므로 잠시 쉰다.
	out 0xa1, al								; 슬레이브 PIC

	cli											; CPU 인터럽트 금지

	call waitkbdout								; 키보드 컨트룰러가 준비될 때까지 기다림
	mov al, 0xd1								; 키보드 컨트룰러 내부의 포트 번호 지정 (0xdl = 기타 포트)
	out 0x64, al								; out!

	call waitkbdout								; 키보드 컨트룰러가 준비될 때까지 기다림
	mov al, 0xdf								; A20 게이트 활성화 명령어
	out 0x60, al								; out!

	call waitkbdout

	; Protected Mode로 전환
	lgdt [gdtr]									; GDT 로드

	mov eax, cr0								; cr0레지스터의 값을 변경한다.
	or eax, 0x00000001							; Protected Mode
	and eax, 0x7fffffff							; 페이징을 사용하지 않음
	mov cr0, eax								; mov!

	jmp dword SysCodeSelector:PM_Start			; 32비트 커널로 점프한다

[bits 32]
PM_Start:
	mov ax, SysDataSelector						; 세그먼트 초기화
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov esp, 0x7c00								; 임시 스택 초기화

	; IA-32 모드 지원 여부 확인
	mov eax, 0x80000001
	cpuid
	test edx, 0x20000000
	jnz IA32_sucs

	jmp ErrorInProtected
IA32_sucs:

	; 메모리 체크
	mov eax, cr0
	push eax
	or eax, 0x60000000
	mov cr0, eax								; 캐시 비활성화

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

	; 데이터 복사
	mov esi, 0x7c00								; 플로피 디스크의 위치 (부트섹터+읽은 데이터)
	mov edi, FLOPPY_CPY_ADD						; 복사할 곳
	mov ecx, READ_CYLINDERS * 512 * 18 * 2		; 복사할 양 계산
	call memcpy									; copy!

	mov esi, FLOPPY_CPY_ADD + 0x4200 + C_Kernel - KERNEL_ADDR	; C언어 커널 복사
	mov edi, KERNEL_CPY_ADD						; 복사할 곳
	mov ecx, KERNEL_SIZE						; 복사할 양
	call memcpy									; copy!

	mov esi, BOOT_INFO
	mov edi, BOOT_INFO_CPY_ADD
	mov ecx, BOOT_INFO_SIZE
	call memcpy

	; Page Table 생성
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
	cmp ebx, 512 * PAGE_DIRPTR_ENTRY_COUNT * 8	; 루프 PAGE_DIRPTR_ENTRY_COUNT회 수행
	jb PageDirLoop

	; IA-32 Mode로 전환
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
	mov ax, SysIA32DataSelector					; 세그먼트 초기화
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov esp, KERNEL_STACK						; 스택을 KERNEL_STACK으로 설정
	mov ebp, KERNEL_STACK

	jmp KERNEL_CPY_ADD							; 커널로 점프

;-----------;
; Functions ;
;-----------;
memcpy:			; 메모리 복사 함수. ds:esi=복사할 데이터 주소, es:edi=복사될 주소, ecx=크기(byte)
	pushad										; 모든 범용 레지스터 및 일부 인덱스 레지스터 push

	cld											; 방향 플래그(DF) = 0 -> 문자열 명령어 실행시 edi, esi 증가
	rep movsb									; 복사
												; rep = ecx가 0일 때까지 명령어를 반복(한번 반복할 때마다 ecx감소)
												; movsb = mov의 바이트 문자열 명령어, mov byte [es:edi], [ds:esi]
												; 바이트 문자열 명령어이므로 실행후 edi, esi 1증가

	popad										; 모든 범용 레지스터 및 일부 인덱스 레지스터 pop
	ret											; return;

memset:			; 메모리 설정 함수. es:edi=설정할 데이터 주소, al=설정할 값, ecx=크기(byte)
	pushad										; 모든 범용 레지스터 및 일부 인덱스 레지스터 push

	cld											; 방향 플래그(DF) = 0 -> 문자열 명령어 실행시 edi 증가
	rep stosb									; 설정
												; rep = ecx가 0일 때까지 명령어를 반복(한번 반복할 때마다 ecx감소)
												; stosb = mov byte [es:edi], al
												; 바이트 문자열 명령어이므로 실행후 edi 1증가

	popad										; 모든 범용 레지스터 및 일부 인덱스 레지스터 pop
	ret											; return;

waitkbdout:		; 키보드 컨트룰러 대기 함수
	push eax									; 사용하는 레지스터(eax) push

wait_loop:
	in al, 0x64									; 키보드 컨트룰러 상태 in
	and al, 0x2									; 만일 준비가 안 돼있으면 2번째 bit가 0이 됨(따라서 ZF=1)
	in al, 0x60									; 키보드 컨트룰러의 버퍼를 비움
	jnz wait_loop								; ZF=0(키보드 컨트룰러가 준비가 안 돼면 루프를 돔

	pop eax										; 사용하는 레지스터(eax) pop
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
	dw gdt_end - gdt - 1						; GDT의 크기
	dd gdt										; GDT의 시작 주소

gdt:											; GDT의 시작

NullSelector equ (0 * 8)						; 예약된 NULL 디스크럽터
	dw 0										; 전부 0
	dw 0
	db 0
	db 0
	db 0
	db 0

SysIA32CodeSelector equ (1 * 8)				; IA-32모드 코드 세그먼트 디스크립터
	dw 0xffff									; Limit 0~15 bit = 0xffff
	dw 0										; Base 0~15 bit = 0
	db 0										; Base 16~23 bit = 0
	db 10011010b								; P=1, DPL=0, Code, non-conforming, readable
	db 10101111b								; G=1, D=0, L=1, Limit 16~19 bit = 0xf (Limit = 0xfffff)
	db 0

SysIA32DataSelector equ (2 * 8)				; IA-32모드 데이터 세그먼트 디스크립터
	dw 0xffff									; Limit 0~15 bit = 0xffff
	dw 0										; Base 0~15 bit = 0
	db 0										; Base 16~23 bit = 0
	db 10010010b								; P=1, DPL=0, Code, non-conforming, readable
	db 10101111b								; G=1, D=0, L=1, Limit 16~19 bit = 0xf (Limit = 0xfffff)
	db 0

SysCodeSelector equ (3 * 8)					; 코드 세그먼트 디스크럽터
	dw 0xffff									; Limit 0~15 bit = 0xffff
	dw 0										; Base 0~15 bit = 0
	db 0										; Base 16~23 bit = 0
	db 10011010b								; P=1, DPL=0, Code, non-conforming, readable
	db 11001111b								; G=1, D=1, Limit 16~19 bit = 0xf (Limit = 0xfffff)
	db 0										; Base 24~32 bit = 0 (Base = 0)

SysDataSelector equ (4 * 8)					; 데이터 세그먼트 디스크럽터
	dw 0xffff									; Limit 0~15bit = 0xffff
	dw 0										; Base 0~15 bit = 0
	db 0										; Base 16~23 bit = 0
	db 10010010b								; P=1, DPL=0, Data, expand-up, writable
	db 11001111b								; G=1, D=1, Limit 16~19 bit = 0xf (Limit = 0xfffff)
	db 0										; Base 24~32 bit = 0 (Base = 0)

gdt_end:										; GDT의 끝 + 1

C_Kernel:										; C언어로 만든 커널의 시작
