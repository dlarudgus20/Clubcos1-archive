READ_CYLINDERS equ 3									; ���� �Ǹ��� ��
FLOPPY_SEGMENT equ 0x07e0								; �б� ������ �޸��� ���׸�Ʈ

KERNEL_ADDR equ (FLOPPY_SEGMENT * 0x10 + 0x4200 - 0x200); Ŀ���� ��ġ = 0xc000
													; = FLOPPY_SEGMENT * 0x10 + 0x4200 - 0x200
; !!����!!
; [ 0x00080000 ~ 0x00100000 ) => ��� �Ҵ� �޸�
; [ 0x00007e00 ~ 0x00080000 ) ������ �ε� ����
; 480.5 KiB -> �ִ� 26 �Ǹ��� �ε� ���� (468 KiB)