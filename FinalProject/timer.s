		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL		EQU		0xE000E010		; SysTick Control and Status Register
STRELOAD	EQU		0xE000E014		; SysTick Reload Value Register
STCURRENT	EQU		0xE000E018		; SysTick Current Value Register
	
STCTRL_STOP	EQU		0x00000004		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO	EQU		0x00000007		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX	EQU		0x00FFFFFF		; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR	EQU		0x00000000		; Clear STCURRENT and STCTRL.COUNT	
SIGALRM		EQU		14				; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( )
USR_HANDLER EQU		0x20007B84		; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init
		PUSH	{R4, lr}

		LDR		R4, =STCTRL
		LDR		R0, =STCTRL_STOP	
		STR		R0, [R4]	
		
		;; Load the maximum value to SYST_RVR
		LDR		R4, =STRELOAD			; load address of systick reload into r1
		LDR		R0, =STRELOAD_MX		; load countdown to r0 to equal 1 second
		STR		R0, [R4]				

		LDR		R4, =STCURRENT	
		MOV		R0, #0		; Ensure register is clear for use and no remaining time leftovers
		STR		R0, [R4]
		
		POP		{R4, pc}
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; Timer start
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start
		PUSH	{R4-R6, lr}
		;; R0 = new seconds value returned by the _signal_handler
		LDR 	R1, =SECOND_LEFT	; Retrieve the seconds parameter from memory address 0x20007B80 (SECONDS_LEFT)
		LDR		R2, [R1]		; Create a copy of the value (seconds left) inside 0x20007B80 into R2
		STR 	R0, [R1]		; Replace seconds left (R0) with new seconds parameter from alarm( ) to memory address 0x20007B80 (R1)
		
		;; Enable SysTick:
		;; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1 ---> STCTRL_GO
		LDR		R3, =STCTRL		; R3 holds memory address of SysTick Control and Status Register
		LDR		R4, =STCTRL_GO		; R4 holds [Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1 ---> STCTRL_GO]
		STR		R4, [R3]		; Update address of SysTick Control and Status Register ---> Systick Enabled
		
		;; Clear SYST_CVR:
		LDR		R5, =STCURRENT
		MOV 	R6, #0
		STR		R6, [R5]		; Set 0x00000000 in SYST_CVR
		
		MOV 	R0, R2			; Return seconds left into main through R0
		
		POP		{R4-R6, pc}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; Timer update
; void timer_update( )
		EXPORT		_timer_update
_timer_update
		PUSH	{R4-R6, lr}
		LDR		R1, =SECOND_LEFT	; R1 holds memory address to how many seconds left
		LDR		R2, [R1] 		; R2 holds how many seconds left
		SUB 	R2, R2, #1		; Decrement seconds left by 1
		STR 	R2, [R1]
		
		CMP		R2, #0
		BEQ		stop_Timer

_timer_update_done
		POP		{R4-R6, pc}
		
stop_Timer
		;; Stop the timer first
		LDR		R3, =STCTRL
		LDR		R4, =STCTRL_STOP
		STR		R4, [R3]
		
		;; Invoke *func at 0x2000.7B84
		LDR 	R5, =USR_HANDLER
		LDR		R6, [R5]
		
		PUSH	{r0-r12}
		BLX 	R6
		POP		{r0-r12}

		B		_timer_update_done

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; Timer update
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
		PUSH 	{R2}
		CMP		R0, #SIGALRM
		BNE		handler_return	
		
handle_SIGALRM
		LDR		R2, =USR_HANDLER	
		LDR		R3, [R2]		
		STR		R1, [R2]	
		;ADD		R1, R1, #0x60
		MOV 	R0, R3 			

handler_return
		POP		{R2}
		MOV		pc, lr			

		END		