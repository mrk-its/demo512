[bits 16]
[org 0x7c00]

delay   equ 20000

	jmp word 0x0000:start

start:
	push cs
        pop es

	mov ax, 0xb800
	mov fs, ax

	xor ax, ax
        xor bx, bx
clsscr:
	mov [fs:bx], ax
	add bx, 2
	cmp bx, 4000
	jnz clsscr

	xor bx, bx
fillscr:
        mov ah, 4
	mov [fs:bx], ax
        mov ah, 2
	mov [fs:bx+160*4+16], ax
        mov ah, 1
	mov [fs:bx+160*8+32], ax
	add bx,2
	add al, 4
        jnc fillscr1
	add bx, 32
        add al, 1
fillscr1:
	cmp bx, 160 * 4
	jc fillscr

	mov si, regs
reg_init:
        mov ax, [es:si]
        mov dl, [es:si+2]
        mov dh, 3
	out dx, ax
        add si, 3
        cmp si, regs_end
        jc reg_init

	mov ax, 0xa000
	mov gs, ax

	mov si, sin_data
        mov cx, 65
        mov di, 0x2000
        mov bx, di
        add bx, 128 * 2

prepare_sin_table:
        mov al, [es:si]
        xor ah, ah
        mov [gs:di], ax
        mov [gs:bx], ax
        
        xor ax, 0xffff
        add ax, 1
        mov [gs:di+128*2], ax
        mov [gs:bx+128*2], ax

	inc si
        add di, 2
        sub bx, 2
        dec cx
        jnz prepare_sin_table

        mov cx, 0
loop:
	push cx
        mov dx, cx
        and cx, 1023
        xor cx, 0xffff
	add cx, 512
	mov di, 0x8000
        xor ax, ax
cls1:
        mov word [gs:di], ax
        add di, 2
        cmp di, 0x8000 + 0x2000
        jc cls1

	mov bx, cx
        shl bx, 1
        add bx, cx
        and bx, 0xff
        shl bx, 1
        mov ax, [gs:bx + 0x2000]
        sar ax, 1
	push ax

	mov bx, cx
        sal bx, 1
        add bx, 20
        and bx, 0xff
        shl bx, 1
        mov ax, [gs:bx + 0x2000]
        sar ax, 2

        mov di, 0x8000 + 32 + 128*9
        test dx, 2048 + 1024
        jz skip_eff1
        add di, ax
skip_eff1:
	mov si, msg
        and dx, 1024+2048
        cmp dx, 1024
        jnz skip_msg
        mov si, msg2
skip_msg:

	pop ax
        test dx, 2048
        jz skip_eff2
        add cx, ax
skip_eff2:

print:
        push cx
        and cx, 7
        mov ah, 0x80
        shr ah, cl
        pop cx
        shr cx, 3
        shl cx, 7
        add di, cx
print0:
        ; si - pointer to text
        ; di - pointer to screen
        ; cx - horizontal bit offset

	mov bl, [es:si]
        test bl, bl
        jz printq

        push di
        xor bh, bh
        shl bx, 5

        mov cl, 0
        mov ch, 16

print2:
	push di
        push ax

print3:
        push cx
        shr cl, 2
        mov al, [gs:bx]
        shl al, cl
        and al, 0x80
	jz print4
	or [gs:di], ah
	;or [gs:di+1], ah
	or [gs:di+2], ah
	;or [gs:di+3], ah
print4:
        shr ah, 1
	jnz print5
        add di, 128
        mov ah, 0x80
print5:
	pop cx
        inc cl
        and cl, 31
        jnz print3
	pop ax
	pop di
        add di, 4

        inc bx ; next character line
        dec ch
        jnz print2
        inc si
        pop di
print6:
        add di, 512
        cmp di, 0x8000 + 128 * 64
        jc print0
printq:

        mov si, 0x1ffe
show1:
	mov ax, word [gs:si + 0x8000]
        mov word [gs:si + 0xc000], ax
        sub si, 2
        jnc show1

	mov ah, 0x86
        xor cx, cx
        mov dx, delay
	int 15h

	pop cx
        inc cx
        jmp loop

msg db "OSDev rocks!", 0
msg2 db "a bit boring?" ; We can ommit zero byte here, because sin table starts with zero. Hurray, 1 byte saved!

sin_data db 0,3,6,9,12,16,19,22,25,28,31,34,37,40,43,46,49,51,54,57,60,63,65,68,71,73,76,78,81,83,85,88,90,92,94,96,98,100,102,104,106,107,109,111,112,113,115,116,117,118,120,121,122,122,123,124,125,125,126,126,126,127,127,127,127

regs: 
	dw 0x0f03,
        db 0xc4    ; Memory Map Select reg: char set A = char set B = 0xc000-0xdfff
	dw 0x1f09
        db 0xd4    ; character height: 32px
	dw 0x0101, 
        db 0xc4    ; character width: 8px
	dw 0x0402
        db 0xc4    ; Mask reg; enable write to map 2
	dw 0x0704
        db 0xc4    ; Memory Mode reg ; alpha, ext mem, non-interleaved
	dw 0x0005
        db 0xce    ; Graphics Mode reg; non-interleaved access
	dw 0x0406
        db 0xce    ; Graphics Misc reg; map char gen RAM to a000:0
	dw 0x0204
        db 0xce    ; Graphics ReadMapSelect reg; enable read chargen RAM
regs_end:


times 510 - ($ - $$) db 0
db 0x55
db 0xAA


