;// ============================================================================
;// MAIN: LOADING HIRES while MUSIC is Playing (INT)
;// v0.1
;// April 2018
;// A.C
;// ----------------------------------------------------------------------------
;// Adapted from my previous work on Apple II 
;// 
;// 
;// target: Oric / Pravetz 8D emulation mode (ORICUTRON only)
;// ============================================================================
;
; ON DISK: physical interleaving
; TRACK  : $00
; SECTORS: $0D,$05,$0C,$04,$0B
;
; MUSIC DATA: physical interleaving
; T$01/S$00 - T$03/S$0C

; PICTURES: physical interleaving
; marvel.hir			T$04/S$00-T$05/S$0F
; SpiderMan.hir			T$06/S$00-T$07/S$0F	
; Iron-man.hir			T$08/S$00-T$09/S$0F
; deadpool.hir			T$0A/S$00-T$0B/S$0F
; carol.hir				T$0C/S$00-T$0D/S$0F
; doctor.hir			T$0E/S$00-T$0F/S$0F
; hulk.hir				T$10/S$00-T$11/S$0F	
; torche.hir			T$12/S$00-T$13/S$0F
; thing.hir				T$14/S$00-T$15/S$0F
; silver.hir			T$16/S$00-T$17/S$0F
; black.hir				T$18/S$00-T$19/S$0F
; daredevil.hir			T$1A/S$00-T$1B/S$0F
; thor.hir				T$1C/S$00-T$1D/S$0F
; wolf.hir				T$1E/S$00-T$1F/S$0F
; captainminion.hir		T$20/S$00-T$21/S$0F
;
;// ============================================================================
;// *= $F000 ; ORG = $F000


; struct VIA	=	    // a standard 6522 chip
;
;   byte	PORTB;	    // Port B
;	byte	PORTA;	    // Port A
;	byte	DDRA;	    // Port B Control (Data Direction Register B)
;	byte	DDRB;	    // Port A Control (Data Direction Register A)
;			            // Write (R/W = L)      | Read (R/W = H)
;	byte	T1C_L;	    // T1 Low-Order Latches | T1 Low-Order Counter
;	byte	T1C_H;	    // T1 High-Order Counter| T1 High-Order Counter
;	byte	T1L_L;	    // T1 Low-Order Latches
;	byte	T1L_H;	    // T1 High-Order Latches
;	byte	T2C_L;	    // T2 Low-Order Latches | T2 Low-Order Counter
;	byte	T2C_H;	    // T2 High-Order Counter
;	byte	SR;	        // Shift Register
;	byte	ACR;	    // Auxiliary Control Register
;	byte	PCR;	    // Peripheral Control Register
;	byte	IFR;	    // Interrupt Flag Register
;	byte	IER;	    // Interrupt Enable Register
;	byte	PORTA_NH;	// Same as Register 1 except no handshake.
;
;#define        via_portb               $0300
;#define        via_porta_h             $0301
;#define        via_ddrb                $0302 ddra ?
;#define        via_ddra                $0303 ddrb ?
;#define        via_t1cl                $0304 
;#define        via_t1ch                $0305 
;#define        via_t1ll                $0306 
;#define        via_t1lh                $0307 
;#define        via_t2ll                $0308 
;#define        via_t2ch                $0309 
;#define        via_sr                  $030A 
;#define        via_acr                 $030B 
;#define        via_pcr                 $030C 
;#define        via_ifr                 $030D 
;#define        via_ier                 $030E 
;#define        via_porta_nh            $030F 

#define VIA_PCR $30C
#define VIA_ORA $30F


#define FLOAD   $F000

; PZ
#define PISDEP  $A0       ; PISTE DE DEPART
#define SECDEP  $A1       ; SECTEUR DE DEPART
#define BUFFER  $A2       ; +$A3 ; ADRESSE OU L'ON CHARGE
#define TOTSEC  $A4       ; TOTAL DES SECTEURS A CHARGER
#define CURTRK1 $A5       ; Current TRACK  
; -------------------------------------

	.zero

	*= $40

vREG0	    .dsb 1	
dREG0	    .dsb 2	
nREG0       .dsb 1		
vREG1       .dsb 1		
dREG1	    .dsb 2	
nREG1	    .dsb 1	
vREG2	    .dsb 1	
dREG2	    .dsb 2	
nREG2	    .dsb 1	
vREG3	    .dsb 1	
dREG3       .dsb 2		
nREG3       .dsb 1		
vREG4	    .dsb 1	
dREG4	    .dsb 2	
nREG4	    .dsb 1	
vREG5	    .dsb 1	
dREG5	    .dsb 2	
nREG5	    .dsb 1	
vREG6	    .dsb 1	
dREG6	    .dsb 2	
nREG6	    .dsb 1	
vREG7	    .dsb 1	
dREG7	    .dsb 2	
nREG7	    .dsb 1	
vREG9	    .dsb 1	
dREG9	    .dsb 2	
nREG9	    .dsb 1	
vREGA	    .dsb 1	
dREGA	    .dsb 2	
nREGA	    .dsb 1	
vREGB	    .dsb 1	
dREGB	    .dsb 2	
nREGB	    .dsb 1	
vREGD	    .dsb 1	
dREGD	    .dsb 2	
nREGD	    .dsb 1	
; -----
indexIMG    .dsb 1	
CounterL	.dsb 1
CounterH	.dsb 1

; ------------------------------
	.text
; 
SET_FIXED_REGISTER
.(
		; AY REGISTRES $08 et $0C sont fixes !

		LDX #$01

bp		
		; REGISTRE X

		LDA TableFixedRegisters,X	; numéro registre fixe
		STA VIA_ORA		            ; (data)
		LDA #$FF			        ; Set fct "Set PSG Reg #"
		STA VIA_PCR 		        ; (fct)
		LDA #$DD			        ; Set fct "Inactive"
		STA VIA_PCR    		        ; (fct)

		LDA TableValueRegisters,X	; value
		STA VIA_ORA 		        ; (data)
		LDA #$FD			        ; Set fct "Write DATA"
		STA VIA_PCR 		        ; (fct)
		LDA #$DD			        ; Set fct "Inactive"
		STA VIA_PCR 		        ; (fct)
		
		DEX
		BPL bp
.)        
; =================================        
        ; hide Hires
        LDY #00
        LDX #32
        LDA #$00                 
bc      STA $A000,Y
        INY
        BNE bc
        INC bc+2
        DEX
        BNE bc
        ; ----------

        ; mode HIRES
        LDA #$1E         
        STA $BFDF

        ; clear Hires
        LDY #00
        LDX #31
        LDA #$40                 
bc2     STA $A000,Y
        INY
        BNE bc2
        INC bc2+2
        DEX
        BNE bc2
        ; ----------
; =====================================
; very bad trick to deactivate INT while loading of the MUSIC DATA
        LDA #<NOTHING
		STA $FFFE		
		LDA #>NOTHING
		STA $FFFF
; =====================================                
        ; chargement ZIC
	                
        LDA #$01        
		STA PISDEP			; piste 
 		LDA #$00
 		STA CURTRK1         ; current track is ZERO (first load)
        STA SECDEP			; secteur
		STA BUFFER
 		LDA #$10			; -> $1000
		STA BUFFER+1
		LDA #$2D
		STA TOTSEC
        		
		JSR FLOAD			; chargement !

        SEI
        JSR InitREGValues
        

Init_INT		            ; init interrupt (50Hz = 1/50s)
    
        ; UTILE pour ORIC?!
        ; préparation interruption - TIMER 1 6522 
		LDA #%01000000		; continuous interrupt / PB7 disabled
		STA $30B    		; Auxiliary Control Register

		LDA #%11000000		;
		STA $30D    		; interrupt flag register	(Time Out of Timer 1/Int)
		STA $30E    		; interrupt Enable register (Timer 1 + Set)
        ; ------
        
        ; TIMER : 50 Hz = 20 ms = 20 000 microsecond = 20 000 tick environ (1 Mhz d'holorge) = $4E20
		; calcul fin : 50 Hz = 20 ms
		; 1.0205 Mhz = 1020500 cycles par seconde soit 1020.5 cycles par ms  <-- à verifier pour l'ORIC!
		; pour 20ms, il faut donc 1020.5*20 = 20410 cycles soit : $4FBA

        LDA #$BA		    ; TIC-LOW
	    STA $304            ; $306/$304 ?
	    LDA #$4F		    ; TIC-HIGH
	    STA $305            ; $307/$305 ?

		; set interrupt routine
        LDA #<PLAYER_YM
		STA $FFFE		
		LDA #>PLAYER_YM
		STA $FFFF
        
        CLI                 ; music !
       

b1      ; boucle principale
        LDX #00
b2      STX indexIMG

        ; chargement ROUTINES
	
        LDA TTrack,X
		STA PISDEP			; piste 
        LDA #$00
		STA SECDEP			; secteur
		STA BUFFER
 		LDA #$A0			; -> $A000
		STA BUFFER+1
		LDA #$20
		STA TOTSEC
        		
		JSR FLOAD			; chargement !
       
        LDX indexIMG
        INX
        CPX #TSector-TTrack
        BNE b2
        JMP b1

; =============================================================================
PLAYER_YM					; INT
.(
		; save
		PHP					; on sauve les flags
		PHA					; on sauve A
		TXA					; on sauve 
		PHA					; X
		TYA					; on sauve
		PHA					; Y

        LDY #$00
r0		
		; REGISTRE 0
		TYA     			; registre 0
		STA VIA_ORA		    ; (data)
		LDA #$FF			; Set fct "Set PSG Reg #"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR    		; (fct)

		LDA vREG0			;
		STA VIA_ORA 		; (data)
		LDA #$FD			; Set fct "Write DATA"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR 		; (fct)
		DEC nREG0
		BNE r1
		LDA (dREG0),Y
		STA nREG0
		INY
		LDA (dREG0),Y
		STA vREG0
		CLC
		LDA dREG0
		ADC #02
		STA dREG0
		LDA dREG0+1
		ADC #00
		STA dREG0+1
		DEY
r1		
		; REGISTRE 1
		LDA #$01			; registre 1
		STA VIA_ORA		    ; (data)
		LDA #$FF			; Set fct "Set PSG Reg #"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR    		; (fct)

		LDA vREG1		;
		STA VIA_ORA 		; (data)
		LDA #$FD			; Set fct "Write DATA"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR 		; (fct)
		DEC nREG1
		BNE r2
		LDA (dREG1),Y
		STA nREG1
		INY
		LDA (dREG1),Y
		STA vREG1
		CLC
		LDA dREG1
		ADC #02
		STA dREG1
		LDA dREG1+1
		ADC #00
		STA dREG1+1
		DEY

r2		
		; REGISTRE 2
		LDA #$02			; registre 2
		STA VIA_ORA		    ; (data)
		LDA #$FF			; Set fct "Set PSG Reg #"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR    		; (fct)

		LDA vREG2			;
		STA VIA_ORA 		; (data)
		LDA #$FD			; Set fct "Write DATA"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR 		; (fct)
		DEC nREG2
		BNE r3
		LDA (dREG2),Y
		STA nREG2
		INY
		LDA (dREG2),Y
		STA vREG2
		CLC
		LDA dREG2
		ADC #02
		STA dREG2
		LDA dREG2+1
		ADC #00
		STA dREG2+1
		DEY

r3
		; REGISTRE 3
		LDA #$03			; registre 3
		STA VIA_ORA		    ; (data)
		LDA #$FF			; Set fct "Set PSG Reg #"
		STA VIA_PCR     	; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR    		; (fct)

		LDA vREG3
		STA VIA_ORA 		; (data)
		LDA #$FD			; Set fct "Write DATA"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR 		; (fct)
		DEC nREG3
		BNE r4
		LDA (dREG3),Y
		STA nREG3
		INY
		LDA (dREG3),Y
		STA vREG3
		CLC
		LDA dREG3
		ADC #02
		STA dREG3
		LDA dREG3+1
		ADC #00
		STA dREG3+1
		DEY

r4
		; REGISTRE 4
		LDA #$04			; registre 4
		STA VIA_ORA		    ; (data)
		LDA #$FF			; Set fct "Set PSG Reg #"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR    		; (fct)

		LDA vREG4
		STA VIA_ORA 		; (data)
		LDA #$FD			; Set fct "Write DATA"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR 		; (fct)
		DEC nREG4
		BNE r5
		LDA (dREG4),Y
		STA nREG4
		INY
		LDA (dREG4),Y
		STA vREG4
		CLC
		LDA dREG4
		ADC #02
		STA dREG4
		LDA dREG4+1
		ADC #00
		STA dREG4+1
		DEY

r5
		; REGISTRE 5
		LDA #$05			; registre 5
		STA VIA_ORA		    ; (data)
		LDA #$FF			; Set fct "Set PSG Reg #"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR    		; (fct)

		LDA vREG5
		STA VIA_ORA 		; (data)
		LDA #$FD			; Set fct "Write DATA"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR 		; (fct)
		DEC nREG5
		BNE r6
		LDA (dREG5),Y
		STA nREG5
		INY
		LDA (dREG5),Y
		STA vREG5
		CLC
		LDA dREG5
		ADC #02
		STA dREG5
		LDA dREG5+1
		ADC #00
		STA dREG5+1
		DEY

r6
		; REGISTRE 6
		LDA #$06			; registre 6
		STA VIA_ORA		    ; (data)
		LDA #$FF			; Set fct "Set PSG Reg #"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR    		; (fct)

		LDA vREG6
		STA VIA_ORA 		; (data)
		LDA #$FD			; Set fct "Write DATA"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR 		; (fct)
		DEC nREG6
		BNE r7
		LDA (dREG6),Y
		STA nREG6
		INY
		LDA (dREG6),Y
		STA vREG6
		CLC
		LDA dREG6
		ADC #02
		STA dREG6
		LDA dREG6+1
		ADC #00
		STA dREG6+1
		DEY

r7
		; REGISTRE 7
		LDA #$07			; registre 7
		STA VIA_ORA		    ; (data)
		LDA #$FF			; Set fct "Set PSG Reg #"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR    		; (fct)

		LDA vREG7
		STA VIA_ORA 		; (data)
		LDA #$FD			; Set fct "Write DATA"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR 		; (fct)
		DEC nREG7
		BNE r9
		LDA (dREG7),Y
		STA nREG7
		INY
		LDA (dREG7),Y
		STA vREG7
		CLC
		LDA dREG7
		ADC #02
		STA dREG7
		LDA dREG7+1
		ADC #00
		STA dREG7+1
		DEY

r9
		; REGISTRE 9
		LDA #$09			; registre 9
		STA VIA_ORA		    ; (data)
		LDA #$FF			; Set fct "Set PSG Reg #"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR    		; (fct)

		LDA vREG9 
		STA VIA_ORA 		; (data)
		LDA #$FD			; Set fct "Write DATA"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR 		; (fct)
		DEC nREG9
		BNE ra
		LDA (dREG9),Y
		STA nREG9
		INY
		LDA (dREG9),Y
		STA vREG9
		CLC
		LDA dREG9
		ADC #02
		STA dREG9
		LDA dREG9+1
		ADC #00
		STA dREG9+1
		DEY

ra
		; REGISTRE 10
		LDA #$0A			; registre 10
		STA VIA_ORA		    ; (data)
		LDA #$FF			; Set fct "Set PSG Reg #"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR    		; (fct)

		LDA vREGA			; 
		STA VIA_ORA 		; (data)
		LDA #$FD			; Set fct "Write DATA"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR 		; (fct)
		DEC nREGA
		BNE rb
		LDA (dREGA),Y
		STA nREGA
		INY
		LDA (dREGA),Y
		STA vREGA
		CLC
		LDA dREGA
		ADC #02
		STA dREGA
		LDA dREGA+1
		ADC #00
		STA dREGA+1
		DEY

rb
		; REGISTRE 11
		LDA #$0B			; registre 11
		STA VIA_ORA		    ; (data)
		LDA #$FF			; Set fct "Set PSG Reg #"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR    		; (fct)

		LDA vREGB			; 
		STA VIA_ORA 		; (data)
		LDA #$FD			; Set fct "Write DATA"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR 		; (fct)
		DEC nREGB
		BNE rd
		LDA (dREGB),Y
		STA nREGB
		INY
		LDA (dREGB),Y
		STA vREGB
		CLC
		LDA dREGB
		ADC #02
		STA dREGB
		LDA dREGB+1
		ADC #00
		STA dREGB+1
		DEY

rd
		; REGISTRE 13		; pas oublier de shunter si = $FF
		LDA vREGD
		CMP #$FF
		BEQ rdb
		TAX
		LDA #$0D			; registre 13
		STA VIA_ORA		    ; (data)
		LDA #$FF			; Set fct "Set PSG Reg #"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR    		; (fct)

		TXA			   		; 
		STA VIA_ORA 		; (data)
		LDA #$FD			; Set fct "Write DATA"
		STA VIA_PCR 		; (fct)
		LDA #$DD			; Set fct "Inactive"
		STA VIA_PCR 		; (fct)
rdb
		DEC nREGD
		BNE decVBL
		LDA (dREGD),Y
		STA nREGD
		INY
		LDA (dREGD),Y
		STA vREGD
		CLC
		LDA dREGD
		ADC #02
		STA dREGD
		LDA dREGD+1
		ADC #00
		STA dREGD+1
		
decVBL
		DEC CounterL
		BNE finInterrupt
		DEC CounterH
		BNE finInterrupt

		JSR InitREGValues
		
finInterrupt
    	BIT $304            ; Clears interrupt (T1CL) pour pouvoir être de nouveau réutilisé! 

		PLA
		TAY					; on récup Y
		PLA
		TAX					; on récup X
		PLA					; on récup A
		PLP					; et les flags

		RTI					; sortie
.)
; =============================================================================
InitREGValues

		; init Music DATA value for first use (or before looping)
		LDA #$C0
		STA CounterL
		LDA #$09
		STA CounterH
		
		LDA #$02			; dREG0+2
		STA dREG0
		LDA #$10
		STA dREG0+1
		LDA #$0E
		STA nREG0
		LDA #$C1
		STA vREG0
		
		LDA #$BA			; dREG1+2
		STA dREG1
		LDA #$11
		STA dREG1+1
		LDA #$FF
		STA nREG1
		LDA #$00
		STA vREG1
		
		LDA #$0A			; dREG2+2
		STA dREG2
		LDA #$12
		STA dREG2+1
		LDA #$07
		STA nREG2
		LDA #$A2
		STA vREG2
		
		LDA #$C2			; dREG3+2
		STA dREG3
		LDA #$1C
		STA dREG3+1
		LDA #$0E
		STA nREG3
		LDA #$00
		STA vREG3
		
		LDA #$74			; dREG4+2
		STA dREG4
		LDA #$1D
		STA dREG4+1
		LDA #$01
		STA nREG4
		LDA #$77
		STA vREG4
		
		LDA #$BE			; dREG5+2
		STA dREG5
		LDA #$23
		STA dREG5+1
		LDA #$02
		STA nREG5
		LDA #$01
		STA vREG5
		
		LDA #$38			; dREG6+2
		STA dREG6
		LDA #$27
		STA dREG6+1
		LDA #$0E
		STA nREG6
		LDA #$0F
		STA vREG6
		
		LDA #$7E			; dREG7+2
		STA dREG7
		LDA #$29
		STA dREG7+1
		LDA #$01
		STA nREG7
		LDA #$18
		STA vREG7
		
		LDA #$66			; dREG9+2
		STA dREG9
		LDA #$2D
		STA dREG9+1
		LDA #$02
		STA nREG9
		LDA #$0F
		STA vREG9
		
		LDA #$2E			; dREGA+2
		STA dREGA
		LDA #$30
		STA dREGA+1
		LDA #$02
		STA nREGA
		LDA #$0F
		STA vREGA
		
		LDA #$10			; dREGB+2
		STA dREGB
		LDA #$37
		STA dREGB+1
		LDA #$0E
		STA nREGB
		LDA #$17
		STA vREGB
		
		LDA #$C8			; dREGD+2
		STA dREGD
		LDA #$38
		STA dREGD+1
		LDA #$01
		STA nREGD
		LDA #$0E
		STA vREGD

		RTS
; -------------------------------------
NOTHING		; ugly!
        BIT $304            ; reinit INT
        RTI
; -------------------------------------

TableFixedRegisters .byt $08,$0C
TableValueRegisters	.byt $10,$00

TTrack      .byt $04,$06,$08,$0A,$0C,$0E,$10,$12,$14,$16,$18,$1A,$1C,$1E,$20
TSector