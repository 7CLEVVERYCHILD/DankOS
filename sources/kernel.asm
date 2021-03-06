; *****************************************************************
;     The DankOS kernel. It contains core drivers and routines.
; *****************************************************************

org 0x0000							; Bootloader loads us here (9000:0000)
bits 16								; 16-bit Real mode

; **** Check CS using a far call to verify that we're loaded in the proper spot by the bootloader ****
; ** if not, use a 'terminate execution' interrupt to return to the caller

call 0x9000:check_cs				; Far call to the check routine

check_cs:

pop ax								; Pop call offset into AX
pop bx								; Pop call segment into BX
cmp bx, 0x9000						; Check if CS was 0x9000
jne start_fail						; If it wasn't, cleanely abort execution

cli									; Disable interrupts and set segments to 0x9000
mov ax, 0x9000
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
mov sp, 0xFFF0						; Move stack to 0xFFF0
sti									; Enable interrupts back

mov byte [CurrentDrive], dl			; Set up the current drive variable

; **** Bootup routines ****

%include 'includes/kernel/syscalls.inc'		; Activate all system interrupts

; Prepare the screen

mov ax, 0x1003
mov bl, 0x00
xor bh, bh
int 0x10				; Disable blinking with BIOS

mov dh, 24
mov dl, 80
mov bh, 0x00
mov ah, 0x02
int 0x10				; Disable BIOS cursor

mov ah, 0x02
mov al, 0x70
int 0x51				; Set palette and reset screen
int 0x4A

mov si, LoadingMsg		; Display loading shell message
int 0x42

reload:

mov dl, byte [CurrentDrive]		; Get current drive
mov si, InitName				; Use the default 'init.bin'
int 0x54						; Launch process #1

; Since process #1 is never supposed to quit, add an exception handler here

mov si, ProcessWarning1			; Print warning message (part 1)
int 0x42

xor dl, dl
int 0x46						; Print exit code

mov si, ProcessWarning2			; Print second part of message
int 0x42

int 0x58						; Pause

jmp reload						; Reload shell


start_fail:

mov ax, 128						; Allocate 128 bytes of memory for stack
int 0x59

cli								; Prepare stack
mov ss, cx
mov sp, 128
sti

mov si, KernelRunningMsg		; Print error and terminate execution
int 0x42
int 0x40


data:

LoadingMsg		db	"Loading 'init.bin'...", 0x00
InitName		db	'init.bin', 0x00
ProcessWarning1	db	0x0A, "Kernel: The root process has been terminated,"
				db	0x0A, "        process exit code: ", 0x00
ProcessWarning2	db	0x0A, "        The kernel will now reload 'init.bin'."
				db	0x0A, "Press a key to continue...", 0x00
KernelRunningMsg	db	"The kernel is already loaded.", 0x0A, 0x00


includes:

%include 'includes/kernel/kernel.inc'
%include 'includes/kernel/video.inc'
%include 'includes/kernel/io.inc'
%include 'includes/kernel/fat12.inc'
%include 'includes/kernel/disk.inc'


global_variables:

%include 'includes/kernel/variables.inc'
