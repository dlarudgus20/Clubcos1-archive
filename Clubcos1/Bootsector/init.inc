READ_CYLINDERS equ 3									; 읽을 실린더 수
FLOPPY_SEGMENT equ 0x07e0								; 읽기 시작할 메모리의 세그먼트

KERNEL_ADDR equ (FLOPPY_SEGMENT * 0x10 + 0x4200 - 0x200); 커널의 위치 = 0xc000
													; = FLOPPY_SEGMENT * 0x10 + 0x4200 - 0x200
; !!주의!!
; [ 0x00080000 ~ 0x00100000 ) => 사용 불능 메모리
; [ 0x00007e00 ~ 0x00080000 ) 까지만 로드 가능
; 480.5 KiB -> 최대 26 실린더 로드 가능 (468 KiB)
