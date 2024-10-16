; Nithisha Sathishkumar midpoint report

		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
; size and if there is nothing to do
; implement your complete logic, including stack operations
		EXPORT	_bzero
_bzero
		; save registers
		PUSH	{r4, LR}
		
		; Load parameters
		MOV		r3, r0 ; r3 = s {dest}
		MOV		r4, r1 ; r4 = n
		
		; zero initialize memory
		MOV		r2, #0 ; r2 = 0
		
_bz_loop
		CMP		r4, #0 ; check if n is 0
		BEQ		_bz_end ; if n == 0, return
		STRB	r2, [r3], #1 ; store byte at [dest] and increment dest
		SUBS	r4, r4, #1 ; decrement n
		B		_bz_loop ; continue loop

_bz_end
		; restore registers and return 
		POP		{r4, pc}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   	dest 	- pointer to the buffer to copy to
;	src	- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest

				EXPORT	_strncpy
_strncpy
		; implement your complete logic, including stack operations
		PUSH	{r4, LR} ; Save registers
		
		MOV		r3, r0 ; r3 = dest
		MOV		r4, r1 ; r4 = src
		MOV		r2, r2 ; r2 = size
_st_loop
		CMP		r2, #0 ; compare size with 0
		BEQ		_st_return ; if size == 0, break
		
		LDRB	r4, [r1], #1 ; r4 = [src++] load src[i] into r4 and increment src
		STRB	r4, [r0], #1 ; store src[i] at dest[i] and increment dest [dest++] = r4
		
		SUBS	r2, r2, #1 ; decrement size size--
		
		; check if src[i] == '\0'
		CMP		r4, #0 ; if r4 == '\0'
		BEQ		_st_return ; if src[i] == '\0' break
		
		B 		_st_loop ; Repeat loop
_st_return 
		POP		{r4, pc} ; restore registers and return 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   	void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		; save registers
		; set the system call # to R7
	    SVC     #0x0
		; resume registers
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   	none
		EXPORT	_free
_free
		; save registers
		; set the system call # to R7
        SVC     #0x0
		; resume registers
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
		; save registers
		; set the system call # to R7
        SVC     #0x0
		; resume registers	
		MOV		pc, lr		
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT	_signal
_signal
		; save registers
		; set the system call # to R7
        SVC     #0x0
		; resume registers
		MOV		pc, lr	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			
