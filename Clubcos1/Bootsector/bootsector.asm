%include "init.inc"

[org 0x7c00]
[bits 16]
	jmp start

; fat12 ���� �ý����� ���
db 0						; fat12�� ����� �� �������� �����ϱ� ������, 1byte�� ����
db "CLUBCOS0"				; ��Ʈ������ �̸��� 8���ڷ� ����
dw 512						; 1������ ũ��(����Ʈ ����)
db 1						; Ŭ�������� ũ��(���� ����, fat12���� 1����
dw 1						; ����� ������ ��
db 2						; ��ũ�� FAT�� ��(fat12���� 2)
dw 224						; ��Ʈ ���͸� ��Ʈ���� ��(������ 224��Ʈ��)
dw 2880						; ��ũ�� �� ���� ��
db 0xf0						; �̵�� Ÿ��(0xf0���� �ؾ� ��)
dw 9						; FAT �ϳ��� ���� ��(fat12���� 9)
dw 18						; 1Ʈ���� ���� ��(�÷��� ��ũ���� 18)
dw 2						; ����� ��
dd 0						; ��Ƽ���� ���� �����Ƿ� 0
dd 2880						; ���� ���� �ٽ� ��
db 0, 0, 0x29				; �� �𸣰ڽ��ϴ٤�.��
dd 0xffffffff				; å���� '�Ƹ� ���� �ø��� ��ȣ'��׿�
db "CLUBCOS0   "			; ��ũ�� �̸�(11����Ʈ)
db "FAT12   "				; ���� �ý����� �̸�(8����Ʈ)
times 18 db 0				; 18����Ʈ ���

start:
	mov ax, cs
	mov ds, ax				; ds�� cs�� ���� �Ѵ�

	mov ax, 0				; ������ �����Ѵ�
	mov ss, ax				; ������ ���׸�Ʈ : 0
	mov sp, 0x7c00			; ������ ������ : 0x7c00

	mov si, boot_msg		; ���� �޼��� ��¹�
bootmsg_putloop:
	mov al, [si]			; �޼����� �� ���� ����
	inc si					; si++
	cmp al, 0				; al�� 0�� ��
	je bootmsg_end			; 0�̸� bootmsg_end���� jmp
	mov ah, 0x0e			; ah=0x0e -> ȭ�鿡 �� ���� ���
	mov bx, 15				; �� �ڵ�
	int 0x10				; BIOS ȣ��(al�� ���� �ڵ�)
	jmp bootmsg_putloop		; ������ ��

boot_msg:
	db 0x0a, 0x0a			; ���� ASCII �ڵ�
	db "This is Clubcos0 boot loader, booting...."
	db 0x0a, 0x0d
	db 0					; NULL
bootmsg_end:

	mov ax, FLOPPY_SEGMENT
	mov es, ax				; es:bx -> �б� ������ �޸��� �ּ�(bx�� 0)
	mov ch, 0				; �Ǹ��� 0
	mov dh, 0				; ��� 0
	mov cl, 2				; ���� 2
readloop:
	mov si, 0				; �б� ���� Ƚ���� ���� ��������
retry:
	mov ah, 0x02			; ah=2 -> �б�
	mov al, 1				; 1���;� ����
	mov bx, 0
	mov dl, 0				; ù��° �÷��� ��ũ
	int 0x13				; BIOS ȣ��
	jnc next				; �����̸� next��
	inc si					; �б� ���� Ƚ�� ����
	cmp si, 5				; si�� 5�� ��
	jae error				; 5 �̻��̸� ���� ó��
	mov ah, 0				; ah=0 -> ����̺� ����
	mov dh, 0				; ù��° �÷��� ��ũ
	int 0x13				; BIOS ȣ��
	jmp retry				; �ٽ� �õ�
next:
	mov ax, es				; es:bx�� 0x200�� ����
	add ax, 0x20			; es�� ���׸�Ʈ�̱� ������ 0x20�� ����
	mov es, ax				; es�� ���׸�Ʈ�̱� ������ ax�� �����ؼ� ���
	inc cl					; ���� ��ȣ�� 1����
	cmp cl, 18				; cl�� 18�� ��
	jbe readloop			; 18 ���϶�� readloop�� jmp
	mov cl, 1				; 18 �ʰ���� ���� ��ȣ�� 1��
	inc dh					; �׸��� ��� ��ȣ�� 1����
	cmp dh, 2				; dh�� 2�� ��
	jb readloop				; 2 �̸��̶�� readloop�� jmp
	mov dh, 0				; 2 �̻��̶�� dh�� 0����
	inc ch					; �Ǹ��� ��ȣ�� ����
	cmp ch, READ_CYLINDERS	; ch�� READ_CYLINDERS�� ��
	jb readloop				; ch < READ_CYLINDERS(�� ���о�����)
							; readloop�� ��

	jmp KERNEL_ADDR			; OS�� ����!

error:						; ���� ó�� ����
	mov si, msg				; ���� �޼����� �ּ�
putloop:
	mov al, [si]			; �޼����� �� ���� ����
	inc si					; si++
	cmp al, 0				; al�� 0�� ��
	je stop					; 0�̸� stop���� jmp
	mov ah, 0x0e			; ah=0x0e -> ȭ�鿡 �� ���� ���
	mov bx, 15				; �� �ڵ�
	int 0x10				; BIOS ȣ��(al�� ���� �ڵ�)
	jmp putloop				; ������ ��
stop:
	hlt						; CPU�� �Ͻ�����
	jmp stop				; ���ѷ���

msg:
	db 0x0a, 0x0a			; ���� ASCII �ڵ�
	db "Clubcos0 load error, system halt"
	db 0x0a
	db 0					; NULL

times 510-($-$$) db 0
dw 0xAA55
