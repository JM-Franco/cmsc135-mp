.model small
.stack 100h
.data
	snake_head_x db 49
	snake_head_y db 14
	direction db 77h
	direction_2 db 48h
	foo db ?
.code
	clrscrn proc near
		mov ah, 06h
		mov bh, 00h
		xor cx, cx
		mov dx, 1c62h
		int 10h
		ret
	clrscrn endp
	
	setdirection proc near
		mov ah, 00h
		int 16h

		cmp al, 'w'
		je resetdirection
		cmp al, 'a'
		je resetdirection
		cmp al, 's'
		je resetdirection
		cmp al, 'd'
		je resetdirection

		jmp setdirectionend

		resetdirection:
		mov direction, al  ; ASCII character
		mov direction_2, ah ; BIOS scan code
		setdirectionend:
		ret
	setdirection endp

	movehead proc near
		mov al, ' '
		mov ah, 09h
		mov bh, 00h
		mov bl, 00h
		mov cx, 01h
		int 10h

		cmp direction, 'w'
		je moveup
		cmp direction, 'a'
		je moveleft
		cmp direction, 's'
		je movedown
		cmp direction, 'd'
		je moveright

		moveup:
		dec snake_head_y	
		jmp moveheadend

		moveleft:
		dec snake_head_x
		jmp moveheadend

		movedown:
		inc snake_head_y
		jmp moveheadend

		moveright:
		inc snake_head_x
		jmp moveheadend

		moveheadend:
		mov dh, snake_head_y
		mov dl, snake_head_x

		mov ah, 02h
		mov bh, 00h
		int 10h
		
		mov al, 254d
		mov ah, 09h
		mov bh, 00h
		mov bl, 02h
		mov cl, 01h
		int 10h

		ret
	movehead endp

	main proc near
		mov ax, @data
		mov ds, ax

		call clrscrn

		mov dh, snake_head_y
		mov dl, snake_head_x
		mov ah, 02h
		mov bh, 00h
		int 10h

		mov al, 245d
		mov ah, 09h
		mov bh, 00h
		mov bl, 02h
		mov cl, 01h
		int 10h

		mov ch, 32
		mov ah, 01h
		int 10h

		game_loop:
		xor ax, ax
		mov ah, 01h
		int 16h
		jz skipsetdirection
		call setdirection

		skipsetdirection:
		call movehead

		; 1 second delay
		mov cx, 0fh
		mov dx, 4240h
		mov ah, 86h
		int 15h

		jmp game_loop	
		
		mov ax, 4c00h
		int 21h
		main endp
	end main
