; Archivo: main.s
; Dispositivo: PIC16F887
; Autor: Cristian Catú
; Compilador: pic-as (v.30), MPLABX V5.40
;
; Programa: Contador con 3 desiplays de 7 segmentos
; Hardware: contador 7 segmentos
;
; Creado: 21 de feb, 2022
; Última modificación: 21 de feb, 2022

PROCESSOR 16F887
;----------------- bits de configuración --------------------
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  // config statements should precede project file includes.
#include <xc.inc>

; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr		    ; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1
    display:            DS 3
    banderas:           DS 1
    centenas:           DS 1
    decenas:            DS 1
    unidades:           DS 1
    valor:              DS 1
    valor1:             DS 1
  
PSECT resVect, class=CODE, abs, delta=2
; ----------------vector reset-----------------
ORG 00h ;posición 0000h para el reset
resetVec:
    PAGESEL main
    goto main

PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posición 0004h para interrupciones
;-------------- VECTOR INTERRUPCIONES ------------------
PUSH:
    MOVWF   W_TEMP	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Guardamos STATUS
    
ISR:
    BTFSC T0IF        ; verificamos la bandera de interrupción del timer 0
    CALL INT_TMR0
    BTFSC RBIF        ; verificamos la bandera de interrupción del puerto B
    CALL INT_IOCB
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal  

; ------------------------ tabla -------------------------------
PSECT code, delta=2, abs
ORG 200h ;posición para el código
tabla:
    CLRF    PCLATH		; Limpiamos registro PCLATH
    BSF	    PCLATH, 1		; Posicionamos el PC en dirección 02xxh
    ADDWF   PCL			; Apuntamos el PC a caracter en ASCII de CONT
    RETLW   00111111B			; ASCII char 0
    RETLW   00000110B			; ASCII char 1
    RETLW   01011011B			; ASCII char 2
    RETLW   01001111B			; ASCII char 3
    RETLW   01100110B           	; ASCII char 4
    RETLW   01101101B			; ASCII char 5
    RETLW   01111101B			; ASCII char 6
    RETLW   00000111B			; ASCII char 7
    RETLW   01111111B			; ASCII char 8
    RETLW   01101111B	                ; ASCII char 9
    RETLW   01110111B			; ASCII char 10
    RETLW   01111100B			; ASCII char 11
    RETLW   00111001B			; ASCII char 12
    RETLW   01011110B			; ASCII char 13
    RETLW   01111001B			; ASCII char 14
    RETLW   01110001B			; ASCII char 15    
; ----------- configuración ----------------------
main:
    CALL CONFIG_IO
    CALL CONFIG_RELOJ
    CALL CONFIG_TMR0
    CALL CONFIG_INT_ENABLE
LOOP:
    CALL SET_DISPLAY
    GOTO LOOP

CONFIG_IO:                    ; se configuran las entradas y salidas respectivas
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH
    
    BANKSEL TRISA
    BSF TRISB, 0
    BSF TRISB, 1
    CLRF TRISC
    CLRF TRISA
    BCF TRISD, 0
    BCF TRISD, 1
    BCF TRISD, 2
    
    BANKSEL OPTION_REG
    BCF OPTION_REG, 7
    BANKSEL WPUB
    BSF WPUB0
    BSF WPUB1
    
    BANKSEL PORTA
    CLRF PORTA
    CLRF PORTC
    BCF PORTD, 0
    BCF PORTD, 1
    BCF PORTD, 2
    CLRF unidades
    CLRF decenas
    CLRF centenas
    CLRF valor1
    CLRF valor
    RETURN

CONFIG_RELOJ:
    BANKSEL OSCCON		; cambiamos a banco 1
    BSF	    OSCCON, 0		; SCS -> 1, Usamos reloj interno
    BSF	    OSCCON, 6
    BSF	    OSCCON, 5
    BCF	    OSCCON, 4		; IRCF<2:0> -> 110 4MHz
    RETURN

CONFIG_TMR0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como temporizador
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BSF	    PS0		    ; PS<2:0> -> 111 prescaler 1 : 256
    
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   217
    MOVWF   TMR0	    ; 50ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    return 

CONFIG_INT_ENABLE:         ; se habilitan los bits respectivos para las interrupciones
    BANKSEL INTCON
    BSF GIE
    BSF RBIE
    BSF T0IE
    BCF RBIF
    BCF T0IF
    BANKSEL IOCB
    BSF IOCB0
    BSF IOCB1
    RETURN

INT_IOCB: 
    BANKSEL PORTA
    BTFSS PORTB, 0       ; se verifica si se presiona el primer puerto
    CALL INC_PORTA
    BTFSS PORTB, 1       ; se verifica si se presiona el segundo puerto
    CALL DEC_PORTA
    MOVF valor1, W       ; se pone el valor1 a la variable valor
    MOVWF valor
    CLRF centenas        ; siempre se limpian las variables de centenas, decenas y unidades
    CLRF decenas
    CLRF unidades
    CALL OBT_CENTENAS    ; se obtienen las decenas
    MOVLW 100
    ADDWF valor, F
    CALL OBT_DECENAS     ; se obtienen las decenas
    MOVLW 10
    ADDWF valor, F
    CALL OBT_UNIDADES    ; se obtienen las unidades
    BCF RBIF
    RETURN

INC_PORTA:              ;subrutina para incrementar el puerto A y el valor1
    INCF PORTA, F
    INCF valor1, F
    RETURN
DEC_PORTA:           ;subrutina para decrementar el puerto A y el valor1
    DECF PORTA
    DECF valor1, F
    RETURN

SET_DISPLAY:              ; se va llamando a la tabla para mostrar los bits respectivos del display de 7 segmentos
    BANKSEL PCLATH
    MOVF decenas, W
    CALL tabla
    MOVWF display
    
    MOVF centenas, W
    CALL tabla
    MOVWF display+1
    
    MOVF unidades, W
    CALL tabla
    MOVWF display+2
    RETURN

OBT_DECENAS:  
    MOVLW 10
    SUBWF valor, W       ;se va restando el valor de 10 hasta que el valor sea negativo
    MOVWF valor
    BANKSEL STATUS
    BTFSS STATUS, 0
    RETURN               ; la unica manera de salir es cuando la resta es negativa, es decir C = 0
    INCF decenas, F      ; cada vez que restamos 10 se incrementa el valor de decenas
    GOTO OBT_DECENAS

OBT_CENTENAS:                 
    MOVLW   100
    SUBWF   valor, W      ; se va restando el valor de 100 hasta que el valor sea negativo
    MOVWF valor
    BANKSEL STATUS
    BTFSS   STATUS, 0
    RETURN                ; la unica manera de salir es cuando la resta es negativa, es decir C = 0
    INCF centenas, F      ; cada vez que restamos cien se incrementa el valor de centenas
    GOTO OBT_CENTENAS
    
OBT_UNIDADES:
    MOVF valor, W        ; el valor restante son las unidades, así que solo se le atribuye el valor a la variable unidades
    MOVWF unidades
    RETURN
    
INT_TMR0:
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   217
    MOVWF   TMR0	    ; 50ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    
    BANKSEL PORTD
    CLRF PORTD
    BTFSC banderas, 1       ; se evalua si el bit 1 es cero o uno
    GOTO DISPLAY_2
    GOTO EVALUAR
    
EVALUAR:                    ; si el bit es 0 ahora se evalua el bit 0
    BTFSC banderas, 0
    GOTO DISPLAY_1
    GOTO DISPLAY_0
    
DISPLAY_0:                  ; si es la combinación 00 se enciende el display 0
    MOVF display, W 
    MOVWF PORTC
    BSF PORTD, 1
    BSF banderas, 0
    BCF banderas, 1
    RETURN
DISPLAY_1:                 ; si es la combinación 01 se enciende el display 1
    MOVF display+1, W
    MOVWF PORTC
    BSF PORTD, 0
    BCF banderas, 0
    BSF banderas, 1
    RETURN
DISPLAY_2:                 ; si es la combinación 10 se enciende el display 2
    MOVF display+2, W
    MOVWF PORTC
    BSF PORTD, 2
    BCF banderas, 0
    BCF banderas, 1
    RETURN
END


