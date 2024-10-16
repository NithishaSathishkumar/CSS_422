		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MEMCPY		EQU		0x3		; address 20007B0C
SYS_MALLOC		EQU		0x4		; address 20007B10
SYS_FREE		EQU		0x5		; address 20007B14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; System Call Table Initialization
		EXPORT	_syscall_table_init
_syscall_table_init
		PUSH	{R4, lr}
		LDR		R0, =SYSTEMCALLTBL		; originally 0x20007500
		
		LDR		R4, =0x20007B00
		
		LDR		R1, =0x0				; address 20007B00
		STR		R1, [R0, #SYS_EXIT*4]
		
		LDR		R1, [R4, #0x04]
		STR		R1, [R0, #SYS_ALARM*4]
		
		LDR		R1, [R4, #0x08]
		STR		R1, [R0, #SYS_SIGNAL*4]
		
		LDR		R1, [R4, #0x0C]
		STR		R1, [R0, #SYS_MEMCPY*4]
		
		LDR		R1, [R4, #0x10]
		STR		R1, [R0, #SYS_MALLOC*4]
		
		LDR		R1, [R4, #0x14]
		STR		R1, [R0, #SYS_FREE*4]
	
		POP			{R4, pc}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
; ---------------DONE------------------DONE------------------DONE-------------------
        EXPORT	_syscall_table_jump
		IMPORT _kfree
		IMPORT _kalloc
		IMPORT _signal_handler
		IMPORT _timer_start
			
_syscall_table_jump
		LDR		R8, =jump_table
		CMP 	R7, #4
		BHI		default_case
		LSL		R7, R7, #2
		LDR		PC, [R8, R7]
		
default_case
		MOV		PC, LR
		
jump_table
		DCD		0
		DCD		_timer_start 	; go to _timer_start
		DCD 	_signal_handler	; go to _signal_handler
		DCD 	_kalloc			; go to _kalloc
		DCD 	_kfree			; go to _kfree
		
		END