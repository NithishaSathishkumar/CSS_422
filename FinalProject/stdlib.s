		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; r0 = s
		; r1 = n
		; r2 = 0
		STMFD	sp!, {r1-r12,lr}
		MOV		r3, r0				; r3 = dest
		MOV		r2, #0				; r2 = 0;	
_bzero_loop							; while( ) {
		SUBS	r1, r1, #1			; 	n--;
		BMI		_bzero_return		;   if ( n < 0 ) break;	
		STRB	r2, [r0], #0x1		;	[s++] = 0;
		B		_bzero_loop			; }
_bzero_return
		MOV		r0, r3				; return dest;
		LDMFD	sp!, {r1-r12,lr}
		MOV		pc, lr	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the buffer to copy to
;	src		- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
		; r0 = dest
		; r1 = src
		; r2 = size
		; r3 = a copy of original dest
		; r4 = src[i]
		STMFD	sp!, {r1-r12,lr}
		MOV		r3, r0				; r3 = dest
_strncpy_loop						; while( ) {
		SUBS	r2, r2, #1			; 	size--;
		BMI		_strncpy_return		; 	if ( size < 0 ) break; 		
		LDRB	r4, [r1], #0x1		; 	r4 = [src++];
		STRB	r4, [r0], #0x1		;	[dest++] = r4;
		CMP		r4, #0				;   
		BEQ		_strncpy_return		;	if ( r4 = '\0' ) break;
		B		_strncpy_loop		; }
_strncpy_return
		MOV		r0, r3				; return dest;
		LDMFD	sp!, {r1-r12,lr}
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   	void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		PUSH 	{R4-R12, lr}
		MOV		R4, R0
		MOV 	R7, #3				; set the system call # to R7

		MOV		R0, R4
		SVC     #0x0

		POP		{R4-R12, pc}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   	none
		EXPORT	_free
_free
		PUSH	{R4-R12, lr}

		MOV		R4, R0
		MOV 	R7, #4	
		MOV		R0, R4
		SVC     #0x0
		
		POP		{R4-R12, pc}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
		PUSH	{R4-R12, lr}

		MOV		R4, R0
		MOV 	R7, #1 	; set the system call # to R7

		MOV		R0, R4
		SVC     #0x0

		POP		{R4-R12, pc}
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT	_signal
_signal
		PUSH	{R4-R12, lr}

		MOV 	R4, R0
		MOV		R5, R1
		MOV 	R7, #2	; set the system call # to R7

		MOV		R0, R4
		MOV		R1, R5
		SVC     #0x0

		POP		{R4-R12, pc}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; int _strcmp(const char*, const char*);

;The strcmp function is used to compare two strings. It takes two strings as input and 
;compares them lexicographically (character by character) according to their ASCII values. 
;The function returns an integer that indicates the relationship between the two strings:
;It returns 0 if the strings are equal.
;It returns a negative integer if the first string is less than the second string.
;It returns a positive integer if the first string is greater than the second string.

		EXPORT  _strcmp
_strcmp
        ; r0 = str1
        ; r1 = str2
        STMFD   sp!, {r2-r12,lr}
_strcmp_loop
        LDRB    r2, [r0], #1    ; r2 = *str1++
        LDRB    r3, [r1], #1    ; r3 = *str2++
        CMP     r2, r3
        BNE     _strcmp_diff    ; if *str1 != *str2, break
        CMP     r2, #0
        BEQ     _strcmp_done    ; if *str1 == '\0', break
        B       _strcmp_loop
_strcmp_diff
        SUB     r0, r2, r3      ; return *str1 - *str2
        B       _strcmp_exit
_strcmp_done
        MOV     r0, #0          ; strings are equal
_strcmp_exit
        LDMFD   sp!, {r2-r12,lr}
        MOV     pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; int _strlen(const char*);
; this function calculates the length of a null-terminated string by iterating over its 
; characters until it encounters the null terminator, counting each character encountered.
        EXPORT  _strlen

_strlen
        ; r0 = str
        STMFD   sp!, {r1-r12,lr}
        MOV     r1, r0          ; r1 = str
        MOV     r2, #0          ; r2 = len
_strlen_loop
        LDRB    r3, [r1], #1    ; r3 = *str++
        CMP     r3, #0
        BEQ     _strlen_done    ; if *str == '\0', break
        ADD     r2, r2, #1      ; len++
        B       _strlen_loop
_strlen_done
        MOV     r0, r2          ; return len
        LDMFD   sp!, {r1-r12,lr}
        MOV     pc, lr
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
	EXPORT  _atoi

_atoi
    ; r0 = str
    STMFD   sp!, {r1-r12,lr}    ; Save registers

    MOV     r1, #0              ; Initialize result to 0
    MOV     r2, #10             ; Base 10 for decimal conversion

_atoi_loop
    LDRB    r3, [r0], #1        ; Load the next character from the string
    CMP     r3, #0              ; Check for end of string
    BEQ     _atoi_done          ; If end of string, exit loop

    CMP     r3, #'0'            ; Compare with '0'
    BLT     _atoi_invalid       ; If less than '0', invalid character
    CMP     r3, #'9'            ; Compare with '9'
    BGT     _atoi_invalid       ; If greater than '9', invalid character

    SUB     r3, r3, #'0'        ; Convert character to integer value
    MUL     r1, r1, r2          ; Multiply result by base
    ADD     r1, r1, r3          ; Add current digit to result
    B       _atoi_loop          ; Continue looping

_atoi_invalid
    MOV     r1, #0              ; Set result to 0 for invalid input

_atoi_done
    MOV     r0, r1              ; Return result in r0
    LDMFD   sp!, {r1-r12,pc}    ; Restore registers and return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------

		EXPORT _strcpy

; Copy the C string pointed by source into the array pointed by destination
; r0 = destination
; r1 = source
_strcpy
    PUSH {r4, lr}       ; Preserve the caller-saved registers r4 and lr

_strcpy_loop
    LDRB r2, [r1], #1  ; Load a byte from source into r2 and increment source pointer
    STRB r2, [r0], #1  ; Store the byte into destination and increment destination pointer
    CMP r2, #0         ; Check if the byte is the null terminator
    BNE _strcpy_loop   ; If not, continue copying
    POP {r4, pc}       ; Restore the caller-saved registers and return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			