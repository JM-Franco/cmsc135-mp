.model small
.stack 100h
.data
	snake_head_x db 49
	snake_head_y db 14
	snake_current_x db 49
	snake_current_y db 14
	snake_array_x db 50 dup(?) ;array that stores all the x values of the snake
	snake_array_y db 50 dup(?) ;array that stores all the y values of the snake
	snake_length dw 3
	direction db 77h
	direction_2 db 48h
	foo db ?
	top_board db 1
	bottom_board db 24
	left_board db 0
	right_board db 79
	rows dw 24 
 	columns dw 80
	counter dw ? ;variable that would be used for loops since data in the cx register keeps changing
	food_x db ?
	food_y db ?
	regenerate db 0 ; to keep track if we need to print new food
	score_msg db "Score:"
	score dw 0
	score_digit db ?
	lose_msg db "GAME OVER!"
	win_msg db "YOU WIN!"
.code
	clrscrn proc near
		mov ah, 06h
		mov bh, 00h
		xor cx, cx
		mov dx, 1c62h
		int 10h
		ret
	clrscrn endp

	setcursor proc near
		mov ah, 02h
		mov bh, 00h
		int 10h
		ret
	setcursor endp

	;Print single green pixel for the snake
	printsnake proc near
		call setcursor
		mov al,219
		mov ah,09h
		mov bh,00h
		mov bl,02h
		mov cl,01h
		int 10h
		ret
	printsnake endp
	
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
		cmp al, 'W'
		je resetdirection
		cmp al, 'A'
		je resetdirection
		cmp al, 'S'
		je resetdirection
		cmp al, 'D'
		je resetdirection
		cmp ah, 48h
		je resetdirection
		cmp ah, 4Bh
		je resetdirection
		cmp ah, 50h
		je resetdirection
		cmp ah, 4Dh
		je resetdirection

		jmp setdirectionend

		resetdirection:
		mov direction, al  ; ASCII character
		mov direction_2, ah ; BIOS scan code
		setdirectionend:
		ret
	setdirection endp

	movehead proc near
		;set the cursor to the tail of the snake
		mov si, snake_length
		sub si, 1 ;subtract 1 since arrays start at index 0
		mov dh, snake_array_y[si] ;snake tail is stored last
		mov dl, snake_array_x[si]
		call setcursor 
		
		;unprint tail of snake
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
		cmp direction, 'W'
		je moveup
		cmp direction, 'A'
		je moveleft
		cmp direction, 'S'
		je movedown
		cmp direction, 'D'
		je moveright
		cmp direction_2, 48h
		je moveup
		cmp direction_2, 4Bh
		je moveleft
		cmp direction_2, 50h
		je movedown
		cmp direction_2, 4Dh
		je moveright	
		

		moveup:
		mov dh, snake_head_y
		mov snake_current_y, dh
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
		call printsnake

		cmp dh, top_board ;checks if snake hits the top board
		je lose
		cmp dh, bottom_board ;checks if snake hits the bottom board
		je lose	
		cmp dl, left_board ;checks if snake hits the left board
		je lose
		cmp dl, right_board ;checks if snake hits the right oard
		je lose			

		;checks whether the snake eats the food
		cmp dh, food_y
		jne updatesnake
		cmp dl, food_x
		jne updatesnake	
		
		;adds one pixel to snake length
		mov dh, snake_array_y[si]
		mov dl, snake_array_x[si]	
		call printsnake	

		add snake_length, 1
		mov si, snake_length
		mov regenerate, 1 ;signals that we should regenerate food
		
		;update both arrays with the new snake pixel positions
		updatesnake:
		mov counter, si
		mov cx, counter
		;shift the values to the right to have space for the new head
		mov ah, snake_array_y[si - 1] 
		mov snake_array_y[si], ah
		mov ah, snake_array_x[si - 1]
		mov snake_array_x[si], ah
		dec si
		loop updatesnake		
		
		;inputs new snake head in the array
		mov dh, snake_head_y
		mov dl, snake_head_x
		mov snake_array_y[si], dh
		mov snake_array_x[si], dl			
		
		mov si, snake_length
		sub si, 1
		;checks if generated food location is within the snake		
		checksnake:
			mov counter, si ;we check each element of the snake array
			mov cx, counter 

			cmp dl, snake_array_x[si]
			jne next ;if x is not equal check next element

			cmp dh, snake_array_y[si]
			je lose; if head touches body then you lose
			
			next:
				dec si	
			loop checksnake

		jmp continue
		lose:
		call gameover

		continue:
		ret
	movehead endp	
	
	;Print single cyan pixel for the board
	printboard proc near
		call setcursor
		mov al,219
		mov ah,09h
		mov bh,00h
		mov bl,03h
		mov cl,01h
		int 10h
		ret
	printboard endp

	;prints the whole board
	completeboard proc near
		mov dh, top_board
		mov dl, left_board
		mov cx, columns ;we print one pixel for each column
		mov counter, cx	
		;prints top board	
		printtop:
			call printboard
			inc dl
			dec counter
			mov cx, counter
			loop printtop
		mov cx, rows ;we print one pixel for each row
		mov counter, cx

		;prints right board
		printright:
			call printboard
			inc dh
			dec counter
			mov cx, counter
			loop printright
		mov cx, columns
		mov counter, cx

		;prints bottom board
		printbottom:
			call printboard
			dec dl
			dec counter
			mov cx, counter
			loop printbottom
		mov cx, rows
		mov counter, cx

		;prints left board
		printleft:
			call printboard
			dec dh
			dec counter
			mov cx, counter
			loop printleft
		ret
	completeboard endp

	;generates food 
	placefood proc near
	getposition:
		;get random x value
		mov ax, 0 
		int 1Ah	;read system timer
		mov ax, dx
		mov dx, 0
		mov cx, columns ; the no. of columns is the max value possible
		sub cx, 1 ; subtract 1 so it won't be on the board
		div cx 
		mov food_x, dl ;get remainder which could be 0-78
		
		;get random y value
		mov ah, 0
		int 1Ah
		mov ax, dx
		mov dx, 0
		mov cx, rows ; the no. of rows is the max value possible
		div cx
		mov food_y, dl ;get remainder which could be 0-23 
		
		;check if it is within the board 
		cmp food_x, 0
		je getposition
		cmp food_y, 1
		jle getposition

		mov si, snake_length
		sub si, 1
		;checks if generated food location is within the snake		
		checksnake:
			mov counter, si ;we check each element of the snake array
			mov cx, counter 

			mov al, food_x
			cmp al, snake_array_x[si]
			jne next ;if x is not equal check next element

			mov al, food_y
			cmp al, snake_array_y[si]
			je getposition ;if the generated food location is within the snake, generate a new one
			
			next:
				dec si	

			loop checksnake

		;print food
		mov dh, food_y
		mov dl, food_x
 		call setcursor

		mov al,219
		mov ah,09h
		mov bh,00h
		mov bl,06h
		mov cl,01h
		int 10h
		ret
	placefood endp

	;print a single character, use by moving chosen character to al before calling printchar
	printchar proc near 
		mov ah, 9h
		mov bh, 0
		mov bl, 0Fh ;white font
		mov cx, 1
		int 10h
		ret
	printchar endp

	printscore proc near				
		mov ax, score
		mov bl, 10
		div bl ;divide score by 10 to get its digits
		mov score_digit, al ;store temporarily in score_digit since we need al
		mov al, ah ;move to al to print ones digit
		add al, "0" ;add "0" to convert to its ASCII value

		mov dh, 0
		mov dl, 8
		call setcursor
		call printchar

		mov al, score_digit ;move to al to print tens digit
		add al, "0"
		mov dh, 0
		mov dl, 7
		call setcursor	
		call printchar
	 
		ret
	printscore endp

	;print game over message 
	gameover proc near
		call clrscrn

		mov dh, 12
		mov dl, 35
		call setcursor 

		mov si, 0
		mov counter, 10
		printgameover:
			mov al, lose_msg[si]
			call printchar
			inc si
			inc dl
			call setcursor
			mov cx, counter
			dec counter
			loop printgameover

		mov ax, 4c00h 
		int 21h
		ret
	gameover endp

	;print win message 
	win proc near
		call clrscrn

		mov dh, 12
		mov dl, 35
		call setcursor 

		mov si, 0
		mov counter, 8
		printwin:
			mov al, win_msg[si]
			call printchar
			inc si
			inc dl
			call setcursor
			mov cx, counter
			dec counter
			loop printwin

		mov ax, 4c00h 
		int 21h
		ret
	win endp

	main proc near
		mov ax, @data
		mov ds, ax

		call clrscrn
		call completeboard		
		call placefood

		mov dh, 0
		mov dl, 0
		call setcursor
		mov si, 0
		mov counter, 6
		printscoremsg:
			mov al, score_msg[si]
			call printchar
			inc si
			inc dl
			call setcursor
			mov cx, counter
			dec counter
			loop printscoremsg

		call printscore

		mov si, 0
		mov dx, snake_length
		mov counter, dx 
		;print initial snake with length = 3
		printinitial:
			mov dh, snake_current_y
			mov dl, snake_current_x
			mov snake_array_y[si], dh
			mov snake_array_x[si], dl
			call printsnake
			
			mov cx, counter
			inc snake_current_y ;next snake pixel would be printed below
			inc si
			dec counter
			loop printinitial

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
		
		;check if food is already eaten, if so generate a new one and add score
		cmp regenerate, 1
		jne game_loop
		call placefood
		mov regenerate, 0
		add score, 1
		call printscore

		cmp score, 10
		jne game_loop
		call win

		jmp game_loop	
		
		mov ax, 4c00h
		int 21h
		main endp
	end main