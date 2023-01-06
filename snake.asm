.model small
.stack 100h
.data
	; Initial length of snake is 3 with body positions at (25, 25), (25, 24), (25, 23)
	snake_x db 40, 40, 40, 252 dup(81)		; X position of snake body, start of array is the tail
	snake_y db 11, 12, 13, 252 dup(81)		; Y position of snake body, start of array is the tail
	snake_length db 3						; Length of snake
	game_action db 0						; Tells what the game should do. 0 = nothing, 1 = game over, 2 = feed snake (add snake length)
	score_d db 5 dup("$")
	score_h dw 0
	game_over db "GAME OVER", "$"

	; Movement directions: up = w (77h), left = a (61h), down = s (73h), right = d (64h)
	direction db 77h						; ASCII character for lowercase w
	direction_2 db 48h						; BIOS scan code for up arrow (keypad)
	foo db ?
.code 
	clear_screen proc near
		mov ax, 0600h
		mov bh, 7
		xor cx, cx
                                    
		; New screen size with 79(4Fh)x24(18h) lines
		mov dx, 184Fh
		int 10h
		
		ret
	clear_screen endp

	draw_borders proc near
		
		; Write top border
		mov dx, 0000h
		call set_cursor_position
		
		top_border_loop:
		mov al, 0DBh
		mov bl, 03h
		call write_character
		
		inc dl
		call set_cursor_position
		
		cmp dl, 50h
		jne top_border_loop
		
		; Write left border
		mov dx, 0100h
		call set_cursor_position

		left_border_loop:
		mov ah, 0DBh
		mov bl, 03h
		call write_character
		
		inc dh
		call set_cursor_position
		
		cmp dh, 18h
		jne left_border_loop
		
		; Write right border
		mov dx, 014Fh
		call set_cursor_position
		
		right_border_loop:
		mov al, 0DBh
		mov bl, 03h
		call write_character
		
		inc dh
		call set_cursor_position
		
		cmp dh, 18h
		jne right_border_loop 
		
		
		; Write bottom border
		mov dx, 1700h
		call set_cursor_position
		
		bottom_border_loop:
		mov al, 0DBh
		mov bl, 03h
		call write_character
		
		inc dl
		call set_cursor_position
		
		cmp dl, 50h
		jne bottom_border_loop

		ret
	draw_borders endp

	print_score proc near

		; Print "S"
		mov ah, 02h
		mov dl, 53h
		int 21h

		; Print "C"
		mov ah, 02h
		mov dl, 43h
		int 21h

		; Print "O"
		mov ah, 02h
		mov dl, 4Fh
		int 21h

		; Print "R"
		mov ah, 02h
		mov dl, 52h
		int 21h

		; Print "E"
		mov ah, 02h
		mov dl, 45h
		int 21h

		; Print ":"
		mov ah, 02h
		mov dl, 3Ah
		int 21h

		; Print " "
		mov ah, 02h
		mov dl, 20h
		int 21h

		; Begin printing score

		; Convert hex score to ASCII
		mov ax, score_h
		lea si, [score_d]

		xor cx, cx
		mov bx, 000ah
		ascii_convert:
		xor dx, dx
		div bx
		add dx, 0030h
		push dx
		inc cl
		cmp ax, 0000h
		jne ascii_convert
		to_result_loop:
		pop [si]
		inc si
		loop to_result_loop
		
		lea dx, score_d
		mov ah, 09h
		int 21h

		ret
	print_score endp

	print_game_over proc near
		mov dx, 1824h
		call set_cursor_position

		lea dx, game_over
		mov ah, 09h
		int 21h
		ret
	print_game_over endp

	set_cursor_position proc near		; input: DH = row (snake_y), DL = column (snake_x)
		mov bh, 00h						; Page Number
		mov ah, 02h
		int 10h
		ret
	set_cursor_position endp

	read_character proc near			; return: AH = attribute, AL = character
		mov bh, 00h						; Page Number
		mov ah, 08h
		int 10h
		ret
	read_character endp

	write_character proc near			; input: AL = Character to display
		mov bh, 00h						; Page Number
		xor cx, cx
		mov cl, 01h						; Number of times to write character
		mov ah, 09h
		int 10h
		ret
	write_character endp

	unprint_snake proc near
		; Use CX register as counter for the unprint_snake_loop
		xor cx, cx

		unprint_snake_loop:
		lea si, [snake_x]
		add si, cx
		mov dl, [si]
		lea si, [snake_y]
		add si, cx
		mov dh, [si]

		; Set cursor position to x value in dh and y value in dl
		call set_cursor_position

		; Prepare registers for int 10h / ah = 9
		mov al, ' '
		mov bl, 02h
		push cx							; Temporarily store print_snake_loop counter in stack because it will be overwritten when printing snake body

		; Write character and attribute at cursor position
		call write_character
		pop cx							; Restore print_snake_loop counter value from  the stack

		inc cl
		cmp cl, snake_length
		jne unprint_snake_loop

		ret
	unprint_snake endp

	print_snake proc near
		; Use CX register as counter for the print_snake_loop
		xor cx, cx

		print_snake_loop:
		; Load snake body x and y position to dh and dl registers to prepare for int 10h / ah = 2
		lea si, [snake_x]
		add si, cx
		mov dl, [si]
		lea si, [snake_y]
		add si, cx
		mov dh, [si]

		; Set cursor position to x value in dh and y value in dl
		call set_cursor_position

		; Prepare registers for int 10h / ah = 9
		;mov al, 219						; 245d is the ASCII character for a box
		mov al, 0B2h

		mov bl, 02h
		push cx							; Temporarily store print_snake_loop counter in stack because it will be overwritten when printing snake body

		; Write character and attribute at cursor position
		call write_character
		pop cx							; Restore print_snake_loop counter value from  the stack

		inc cl
		cmp cl, snake_length
		jne print_snake_loop

		ret
	print_snake endp
	
	check_collisions proc near
	    lea si, [snake_x]
		mov dl, [si]
		lea si, [snake_y]
		mov dh, [si]
		
		mov al, direction
		mov ah, direction_2
		
		cmp al, 'w'
		je next_up
		cmp al, 'W'
		je next_up
		cmp al, 'a'
		je next_left
		cmp al, 'A'
		je next_left
		cmp al, 's'
		je next_down
		cmp al, 'S'
		je next_down
		cmp al, 'd'
		je next_right
		cmp al, 'D'
		je next_right

		cmp ah, 48h
		je next_up
		cmp ah, 4Bh
		je next_left
		cmp ah, 50h
		je next_down
		cmp ah, 4Dh
		je next_right
		
	    next_up:
		sub dh, 01h
		jmp check_front_of_snake_head

		next_left:
		sub dl, 01h
		jmp check_front_of_snake_head

		next_down:
		add dh, 01h
		jmp check_front_of_snake_head

		next_right:
		add dl, 01h

		check_front_of_snake_head:
		
	    ; Check if the object in front of the snake head is the character DBh (block)
		call set_cursor_position
		call read_character

		; If the front of the snake head is food
		cmp al, 0FEh
		jne if_front_is_snake
		mov game_action, 02h
		jmp end_check_collision

		; If front of the snake is snake
		if_front_is_snake:
		cmp al, 0B2h
		; If no collision, continue else set game_action to 1 and end game
		jne if_front_is_wall
        mov game_action, 01h

		; If front of the snake head is a wall
		if_front_is_wall:
		cmp al, 0DBh
		; If no collision, continue else set game_action to 1 and end game
		jne end_check_collision
        mov game_action, 01h
        
		end_check_collision:
	    ret
	check_collisions endp    

	; THIS SHOULD ALWAYS COME AFTER CHECK_COLLISION
	feed_snake proc near
		; Make space for new snake part at the head of the snake
		xor cx, cx
		lea si, [snake_x]
		mov al, [si]

		make_space_x:
		mov bl, [si + 1]
		mov [si + 1], al
		mov al, bl
		
		inc si
		cmp al, 81d
		jne make_space_x

		xor cx, cx
		lea si, [snake_y]
		mov al, [si]
		
		make_space_y:
		mov bl, [si + 1]
		mov [si + 1], al
		mov al, bl
		
		inc si
		cmp al, 81d
		jne make_space_y

		lea si, snake_x
		mov [si], dl
		lea si, snake_y
		mov [si], dh
		
		call unprint_snake
		call print_snake
		add snake_length, 01h

		; Reset game action to 00h
		mov game_action, 00h	

		; Increment score
		add score_h, 0001h
		mov dx, 1800h
		call set_cursor_position
		call print_score

		; Dispense new food
		call dispense_food

		ret
	feed_snake endp

	change_direction proc near
		mov ah, 00h
		int 16h

		cmp al, 'w'
		je new_direction_up
		cmp al, 'W'
		je new_direction_up
		cmp al, 'a'
		je new_direction_left
		cmp al, 'A'
		je new_direction_left
		cmp al, 's'
		je new_direction_down
		cmp al, 'S'
		je new_direction_down
		cmp al, 'd'
		je new_direction_right
		cmp al, 'D'
		je new_direction_right

		cmp ah, 48h
		je new_direction_up
		cmp ah, 4Bh
		je new_direction_left
		cmp ah, 50h
		je new_direction_down
		cmp ah, 4Dh
		je new_direction_right

		; Prevent snake head from going the opposite direction (into it's own body)
		new_direction_up:
		cmp direction, 's'
		je end_change_direction
		cmp direction, 'S'
		je end_change_direction
		cmp direction_2, 50h
		je end_change_direction
		jmp set_new_direction
		new_direction_left:
		cmp direction, 'd'
		je end_change_direction
		cmp direction, 'D'
		je end_change_direction
		cmp direction_2, 4Dh
		je end_change_direction
		jmp set_new_direction
		new_direction_down:
		cmp direction, 'w'
		je end_change_direction
		cmp direction, 'W'
		je end_change_direction
		cmp direction_2, 48h
		je end_change_direction
		jmp set_new_direction
		new_direction_right:
		cmp direction, 'a'
		je end_change_direction
		cmp direction, 'A'
		je end_change_direction
		cmp direction_2, 4Bh
		je end_change_direction

		set_new_direction:
		mov direction, al  ; ASCII character
		mov direction_2, ah ; BIOS scan code

		end_change_direction:
		ret
	change_direction endp

	move_to_direction proc near
		; "Move" by adjusting coordinates of new head in dh and dl and "cutting off" the tail
		cmp direction, 'w'
		je move_up
		cmp direction, 'W'
		je move_up
		cmp direction, 'a'
		je move_left
		cmp direction, 'A'
		je move_left
		cmp direction, 's'
		je move_down
		cmp direction, 'S'
		je move_down
		cmp direction, 'd'
		je move_right
		cmp direction, 'D'
		je move_right

		cmp direction_2, 48h
		je move_up
		cmp direction_2, 4Bh
		je move_left
		cmp direction_2, 50h
		je move_down
		cmp direction_2, 4Dh
		je move_right

		move_up:
		sub dh, 01h
		jmp end_move_to_direction

		move_left:
		sub dl, 01h
		jmp end_move_to_direction

		move_down:
		add dh, 01h
		jmp end_move_to_direction

		move_right:
		add dl, 01h

		end_move_to_direction:
		ret
	move_to_direction endp

	move_snake proc near
		lea si, [snake_x]
		mov dl, [si]
		mov al, dl

		adjust_snake_x_positions:
		mov bl, [si + 1]
		mov [si + 1], al
		mov al, bl
		
		inc si
		mov bh, [si + 1]
		cmp bh, 81d
		jne adjust_snake_x_positions

		lea si, [snake_y]
		mov dh, [si]
		mov al, dh
		
		adjust_snake_y_positions:
		mov bl, [si + 1]
		mov [si + 1], al
		mov al, bl
		
		inc si
		mov bh, [si + 1]
		cmp bh, 81d
		jne adjust_snake_y_positions


		call move_to_direction
                    
		lea si, [snake_x]
		mov [si], dl
		lea si, [snake_y]
		mov [si], dh

		end_move_snake:
		ret
	move_snake endp

	dispense_food proc near
		dispense_food_start:
		; Generate random number
		mov ah, 00h
		int 1Ah

		; Getting random x coordinate to put food into
		; Get modulo of resulting number (divide by 77d/4Dh which is the length of the screen excluding borders)
		mov ax, dx
		xor dx, dx
		mov cx, 4Dh 
		div cx

		; Add 01h to the random number generated so that the range is between 01 and 76 (corrdinates excludes the borders)
		add dl, 01h

		; Store temporarily in foo variable
		mov foo, dl

		; Getting random y coordinate to put food into
		; Get modulo of resulting number (divide by 21d/15h which is the width of the screen excluding borders)
		mov ax, dx
		xor dx, dx
		mov cx, 15h
		div cx

		; Add 01h to the random number generated so that the range is between 01 and 76 (corrdinates excludes the borders)
		add dl, 01h
		
		mov dh, dl
		mov dl, foo
		
		call set_cursor_position
		call read_character

		; Check if space is occupied by snake repeat generation if true
		cmp al, 0DBh
		je dispense_food_start

		; Dispense food at chosen location
		mov al, 0FEh
		mov bl, 0Ch
		call write_character

		ret
	dispense_food endp

	delay proc near
		mov cx, 03h
		mov dx, 0D090h
		mov ah, 86h
		int 15h
		ret
	delay endp

	main proc near
		mov ax, @data
		mov ds, ax

		; Hide blinking cursor
		mov ch, 32
		mov ah, 1
		int 10h

		call clear_screen
		call draw_borders

		; Print score
		mov dx, 1800h
		call set_cursor_position
		call print_score
		
		; Temporary
		; mov dx, 0728h
		; mov cx, 0005h
		; loop_de_loop:
		; mov al, 0FEh
		; mov bl, 02h
		; sub dh, 01h
		; push cx
		; call set_cursor_position
	    ; call write_character
		; pop cx
		; loop loop_de_loop
	    
		call print_snake
		call dispense_food
		call delay
		
		game_loop:
		
	    ; Check for keystrokes
		mov ah, 01h
		int 16h
		jz no_change_direction              ; If no new keystrokes
		call change_direction	
		no_change_direction:
		
		; Check game action based on collision
		call check_collisions
        cmp game_action, 01h
        je end_game
		cmp game_action, 02h
		jne no_feed_snake
		call feed_snake
		jmp game_loop_end
        no_feed_snake:

		; Printing of the snake
		call unprint_snake
		call move_snake
		call print_snake
		
		game_loop_end:
		call delay
		jmp game_loop
		
		end_game:
		call print_snake
		call print_game_over

		mov ax, 4c00h
		int 21h
		main endp
	end main
