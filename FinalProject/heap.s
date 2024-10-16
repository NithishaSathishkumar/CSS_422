		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; Memory Control Block Initialization
		EXPORT	_heap_init
_heap_init
		LDR		R0, =MCB_TOP
		LDR 	R1, =MAX_SIZE
		STR		R1, [R0]
		LDR 	R3, =MCB_TOP+0x4		; 0x20006804
		LDR		R4, =0x20006C00
		MOV		R2, #0x0
			
_initialize_mcb
		CMP 	R3, R4
		BGE		_heap_done
		
		STR		R2, [R3]			
		ADD		R3, R3, #1			
		STR		R2, [R3]
		ADD		R3, R3, #1			
		B 	_initialize_mcb
	
_heap_done
		MOV	pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ---------------DONE------------------DONE------------------DONE-------------------
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
        PUSH        {lr}
        CMP         R0, #32
        BGE         set_size
        MOV         R0, #32

set_size
        LDR         R1, =MCB_TOP        ; Load MCB_TOP into R1
        LDR         R2, =MCB_BOT        ; Load MCB_BOT into R2
        LDR         R3, =MCB_ENT_SZ     ; Load MCB_ENT_SZ into R3
        BL          allocate_memory

        POP         {lr}
        MOV         R0, R12             ; Move the result to R0
        MOV         pc, lr              ; Return

allocate_memory
        PUSH        {lr}

        SUB         R4, R2, R1          ; Calculate the size of the entire memory block
        ADD         R4, R4, R3          ; Add the entry size
        ASR         R5, R4, #1          ; Calculate half of the memory block
        ADD         R6, R1, R5          ; Find the midpoint
        LSL         R7, R4, #4          ; Calculate the actual entire size
        LSL         R8, R5, #4          ; Calculate the actual half size
        MOV         R12, #0x0           ; Initialize the heap address to zero

        CMP         R0, R8
        BGT         no_allocation

        PUSH        {r0-r8}             ; Save registers
        SUB         R2, R6, R3
        BL          allocate_memory
        POP         {r0-r8}             ; Restore registers

        CMP         R12, #0x0
        BEQ         allocate_right

        LDR         R9, [R6]            ; Check the midpoint memory
        AND         R9, R9, #0x01
        CMP         R9, #0
        BEQ         return_heap_address
        B           allocation_done

allocate_right
        PUSH        {r0-r8}             ; Save registers
        MOV         R1, R6
        BL          allocate_memory
        POP         {r0-r8}             ; Restore registers
        B           allocation_done

return_heap_address
        STR         R8, [R6]
        B           allocation_done

no_allocation
        LDR         R9, [R1]            ; Check the left memory
        AND         R9, R9, #0x01
        CMP         R9, #0
        BNE         return_invalid

        LDR         R9, [R1]            ; Check the left memory
        CMP         R9, R7
        BLT         return_invalid

        ORR         R9, R7, #0x01       ; Mark the memory as allocated
        STR         R9, [R1]

        LDR         R9, =MCB_TOP        ; Load MCB_TOP into R9
        LDR         R10, =HEAP_TOP      ; Load HEAP_TOP into R10
        SUB         R1, R1, R9          ; Calculate the offset from MCB_TOP
        LSL         R1, R1, #4          ; Multiply by 16
        ADD         R10, R10, R1        ; Calculate the heap address
        MOV         R12, R10            ; Store the heap address
        B           allocation_done

return_invalid
        MOV         R12, #0             ; Set the result to zero
        B           allocation_done

allocation_done
        POP         {lr}
        BX          lr                  ; Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; Kernel Memory De-allocation
; void free(void *ptr)
        EXPORT  _kfree
_kfree
        PUSH    {lr}

        MOV     R1, R0              ; Move pointer address into R1
        LDR     R2, =HEAP_TOP       ; Load HEAP_TOP into R2
        LDR     R3, =HEAP_BOT       ; Load HEAP_BOT into R3

        ; Check if the address is valid
        CMP     R1, R2              ; Compare address with HEAP_TOP
        BLT     invalid_address     ; If less, jump to invalid_address
        CMP     R1, R3              ; Compare address with HEAP_BOT
        BGT     invalid_address     ; If greater, jump to invalid_address

        ; Compute the MCB address
        LDR     R4, =MCB_TOP        ; Load MCB_TOP into R4
        SUB     R5, R1, R2          ; Subtract HEAP_TOP from the pointer
        ASR     R5, R5, #4          ; Divide by 16 (logical shift right by 4 bits)
        ADD     R5, R4, R5          ; Add result to MCB_TOP

        ; Call _rfree function
        MOV     R0, R5
        PUSH    {R1-R12}
        BL      _rfree
        POP     {R1-R12}
        CMP     R0, #0              ; Check if _rfree returns 0
        BEQ     invalid_address

        POP     {LR}
        MOV     pc, lr

invalid_address
        MOV     R0, #0              ; Set return value to NULL
        POP     {LR}
        MOV     pc, lr

_rfree
        PUSH    {lr}

        ; R0 = MCB address
        LDR     R1, [R0]            ; Load MCB contents
        LDR     R2, =MCB_TOP        ; Load MCB_TOP into R2
        SUB     R3, R0, R2          ; Calculate MCB offset

        ASR     R1, R1, #4
        MOV     R4, R1              ; MCB chunk
        LSL     R1, R1, #4
        MOV     R5, R1              ; Actual size

        STR     R1, [R0]

        SDIV    R6, R3, R4
        AND     R6, R6, #1
        CMP     R6, #0              ; Check if even or odd
        BNE     odd_case

        ; Even Case
        ADD     R6, R0, R4          ; Calculate buddy address
        LDR     R7, =MCB_BOT
        CMP     R6, R7              ; Check if buddy address is within range
        BGE     return_zero

        LDR     R7, [R6]            ; Load buddy contents
        AND     R8, R7, #1
        CMP     R8, #0              ; Check if buddy is free
        BNE     free_done

        ASR     R7, R7, #5
        LSL     R7, R7, #5
        CMP     R7, R5              ; Check if buddy size matches
        BNE     free_done

        STR     R8, [R6]            ; Clear buddy
        LSL     R5, #1              ; Double size
        STR     R5, [R0]            ; Update size

        BL      _rfree              ; Recurse
        B       free_done

odd_case
        ; Odd Case
        SUB     R6, R0, R4          ; Calculate buddy address
        CMP     R2, R6
        BGT     return_zero

        LDR     R7, [R6]            ; Load buddy contents
        AND     R8, R7, #1
        CMP     R8, #0              ; Check if buddy is free
        BNE     free_done

        ASR     R7, R7, #5
        LSL     R7, R7, #5
        CMP     R7, R5              ; Check if buddy size matches
        BNE     free_done

        STR     R8, [R0]
        LSL     R5, #1              ; Double size
        STR     R5, [R6]

        MOV     R0, R6
        BL      _rfree              ; Recurse
        B       free_done

return_zero
        MOV     R0, #0

free_done
        POP     {lr}
        BX      lr                  ; Return from _rfree

		END