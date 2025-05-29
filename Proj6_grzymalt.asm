TITLE Intern Fixer     (Proj6_grzymalt.asm)

; Author: Tyler Grzymalski
; Last Modified: 12/05/2024
; OSU email address: grzymalt@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:      6           Due Date: 12/08/2024
; Description: This program prompts a user for a file name, reads the file if it is valid, converts the ASC-II string to integers and puts them in a new SDWORD array.
;              It then prints that array in reverse order.

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays a null-terminated string to the console and adds a newline.
;
; Preconditions: EDX must contain the address of the string to be displayed.
;
; Receives:
;   message = address of the null-terminated string to display
;
; Returns: None
; ---------------------------------------------------------------------------------
mDisplayString MACRO message
    PUSH    EDX
    MOV     EDX, message
    CALL    Writestring
    CALL    Crlf
    POP     EDX
ENDM

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Prompts the user for input, reads a string, and stores it in a buffer.
;
; Preconditions: None
;
; Receives:
;   inputMessage = address of the null-terminated string prompt
;   outputBuffer = address of the buffer to store user input
;   bufferSize   = maximum size of the input buffer
;   bytesRead    = variable to store the number of bytes read
;
; Returns: None
; ---------------------------------------------------------------------------------
mGetString MACRO inputMessage, outputBuffer, bufferSize, bytesRead
    PUSH    ECX
    PUSH    EDX
    MOV     EDX, inputMessage
    CALL    Writestring
    MOV     EDX, outputBuffer   ; Load the address of the output buffer
    MOV     ECX, bufferSize     ; Set the maximum length of the input
    CALL    ReadString          ; Read the user's input
    CALL    Crlf
    POP     EDX
    POP     ECX
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayChar
;
; Displays a single character to the console.
;
; Preconditions: None
;
; Receives:
;   comma = character to display (passed in AL)
;
; Returns: None
; ---------------------------------------------------------------------------------
mDisplayChar MACRO comma
    PUSH    EAX
    MOV     AL, comma
    CALL    WriteChar
    POP     EAX
ENDM

; Constants and memory allocations
DELIMITER       = ","
NEGATIVE        = "-"
TEMPS_PER_DAY   = 24
BUFFER_SIZE     = 13*TEMPS_PER_DAY

.data
startMsg    BYTE    "Welcome to the Intern Mistake Fixer by Tyler Grzymalski", 0
explainMsg  BYTE    "This program reads an ASC-II formatted document, converts the characters to integers, and then reverses the order of the list automatically!", 0
promptMsg   BYTE    "Please type in the name of the file that you wish to correct: ", 0
errorMsg    BYTE    "That file cannot be found. Try again?", 0
confirmMsg  BYTE    "Okay, it looks like the original list is:", 0
arrayMsg    BYTE    "Here is that fixed list:", 0
exitMsg     BYTE    "Thanks for using the program!", 0
fileName    BYTE    20 DUP(0)
fileHandle  DWORD   ?
fileBuffer  BYTE    BUFFER_SIZE DUP(?)
tempArray   SDWORD  100 DUP(?)
bytesRead   DWORD   ?

.code
main PROC
    ; Display welcome and point of the program
    mDisplayString  OFFSET startMsg
    mDisplayString  OFFSET explainMsg
    CALL            CRLF

_openFile:
    ; Read and store user input. Input must be less than 50 characters
    mGetString      OFFSET promptMsg, OFFSET fileName, 50, bytesRead

    ; Open the file
    MOV             EDX, OFFSET fileName
    CALL            OpenInputFile
    CMP             EAX, -1
    JE              _fileError

    ; Read file content
    MOV             fileHandle, EAX
    MOV             ECX, BUFFER_SIZE
    MOV             EDX, OFFSET fileBuffer
    CALL            ReadFromFile
    MOV             bytesRead, EAX   ; Store bytes read
    CALL            CloseFile
    JMP             _done

_fileError:
    ; Validation check for file name
    mDisplayString  OFFSET errorMsg
    CALL            Crlf
    JMP             _openFile

_done:
    ; Fix values and fill tempArray
    PUSH            bytesRead
    PUSH            OFFSET fileBuffer
    PUSH            OFFSET tempArray
    CALL            ParseTempsFromString

    ; Write the reverse list
    PUSH            OFFSET tempArray
    CALL            WriteTempsReverse

    ; Closing Message
    mDisplayString  OFFSET exitMsg

    Invoke ExitProcess,0
main ENDP

; ---------------------------------------------------------------------------------
; Name: ParseTempsFromString
;
; Parses a string of ASCII-encoded, comma-separated integers from a file buffer,
; converts them to signed integers, and stores them in an array.
; The procedure handles negative numbers and ensures the output array is
; formatted correctly. Additionally, it prints the original list of integers.
;
; Preconditions:
;   - The string in `fileBuffer` must be null-terminated.
;   - `tempArray` must have sufficient space to store the integers.
;   - `bytesRead` should accurately reflect the length of the string.
;
; Postconditions:
;   - Updates the `tempArray` with parsed integers in their original order.
;   - Outputs the original integer list to the console.
;
; Receives:
;   - fileBuffer = [EBP + 12]   Address of the ASCII string containing the integers. 
;   - tempArray  = [EBP + 8]    Address of the array to store parsed integers.        
;   - bytesRead  = [EBP + 16]   Length of the input string in bytes.                  
;
; Returns:
;   - Updates `tempArray` with parsed integers in their original order.
; ---------------------------------------------------------------------------------
ParseTempsFromString PROC
    PUSH            EBP
    MOV             EBP, ESP
    PUSH            ESI
    PUSH            EDI
    PUSH            EDX
    PUSH            EAX
    PUSH            EBX
    PUSH            ECX

    MOV             ESI, [EBP + 12]
    MOV             EDI, [EBP + 8] 
    MOV             ECX, [EBP + 16]
    MOV             EAX, 0
    MOV             EBX, 0
 
 _checkChar:
    CMP             ECX, 0
    JE              _checkNeg     
    DEC             ECX
    LODSB
    CMP             AL, DELIMITER
    JE              _checkNeg           ; Move unit to get processed into tempArray
    CMP             AL, NEGATIVE
    JE              _negInt
    SUB             AL, '0'
    CMP             AL, 9
    JA              _checkChar

    IMUL            EBX, 10             ; Shift values left to make room for bigger number
    ADD             EBX, EAX
    
    JMP             _checkChar

_negInt:
    MOV             EDX, 1
    JMP             _checkChar

_checkNeg:
    CMP             EDX, 1             ; Check if the number is negative
    JNE             _addToArray
    NEG             EBX

_addToArray:        
    MOV             [EDI], EBX
    ADD             EDI, 4
    MOV             EBX, 0
    MOV             EDX, 0
    CMP             ECX, 0
    JE              _prepPrint
    JMP             _checkChar

_prepPrint:
    ; Print array msg and load array
    mDisplayString  OFFSET confirmMsg
    MOV             ECX, 0
    MOV             ESI, [EBP + 8]

_printOldArray:                                       
    MOV             EAX, [ESI + 4*ECX]
    
    ; Move to next number and print current number
    INC             ECX
    CALL            WriteInt
    mDisplayChar    DELIMITER

    ; Make a check to see if all the integers are printed as defined by TEMPS_PER_DAY
    CMP             ECX, TEMPS_PER_DAY
    JL              _printOldArray
    CALL            Crlf
    CALL            Crlf
 
 _done:
    POP             ECX
    POP             EAX
    POP             EBX
    POP             EDX
    POP             EDI
    POP             ESI
    POP             EBP
    RET             12
ParseTempsFromString ENDP

; ---------------------------------------------------------------------------------
; Name: WriteTempsReverse
;
; Prints the integers in an array in reverse order. The procedure formats the 
; output as comma-separated values and ends with a newline.
;
; Preconditions:
;   - The array pointed to by `tempArray` must contain valid integers.
;   - The array must have at least `TEMPS_PER_DAY` elements.
;
; Postconditions:
;   - Outputs the reversed list of integers to the console.
;
; Receives:
;   - tempArray = [EBP + 8]      Address of the array containing the integers to print.
;
; Returns:
;   - Outputs the reversed list of integers to the console.
; ---------------------------------------------------------------------------------
WriteTempsReverse PROC
    PUSH            EBP
    MOV             EBP, ESP
    PUSH            ESI
    PUSH            EDI
    PUSH            EAX
    PUSH            ECX

    MOV             EAX, 0
    MOV             EDI, [EBP + 8]    ; EDI points to tempArray

_prepPrint:
    ; Print array msg and load array
    mDisplayString OFFSET arrayMsg
    MOV             ECX, TEMPS_PER_DAY
    SUB             ECX, 1
    MOV             ESI, [EBP + 8]

_printTempArray:                                       
    MOV             EAX, [ESI + 4*ECX]
    
    ; Move to next number and print current number
    DEC             ECX
    CALL            WriteInt
    mDisplayChar    DELIMITER

    ; Make a check to see if all the integers are printed
    CMP             ECX, 0
    JGE              _printTempArray
    CALL            Crlf
    CALL            Crlf

    POP             ECX
    POP             EAX
    POP             EDI
    POP             ESI
    POP             EBP
    RET             4
WriteTempsReverse ENDP

END main
