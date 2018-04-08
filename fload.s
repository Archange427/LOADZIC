;// ============================================================================
;// FLOAD 
;// v0.1
;// April 2018
;// A.C
;// ----------------------------------------------------------------------------
;// Adapted from DOS 3.3 Load routines from APPLE
;// "Armove" routines from FastLoad
;// 
;// target: Oric / Pravetz 8D emulation mode (ORICUTRON only)
;// ============================================================================
;
; ON DISK: physical interleaving
; TRACK  : $00
; SECTORS: $07,$0E,$06
;
;// ============================================================================
;// *= $F000 ; ORG = $F000

; ROM 8D+DISKII I/O addresses

#define P0OFF      $310         ; EQUI A2 = Phase0 OFF          / DRVSM0 / $C080+SLOT*$10
#define P0ON       $311         ; EQUI A2 = Phase0 ON           / DRVSM1 / $C081+SLOT*$10
#define P1OFF      $312         ; EQUI A2 = Phase1 OFF          / DRVSM2 / $C082+SLOT*$10
#define P1ON       $313         ; EQUI A2 = Phase1 ON           / DRVSM3 / $C083+SLOT*$10
#define P2OFF      $314         ; EQUI A2 = Phase2 OFF          / DRVSM4 / $C084+SLOT*$10
#define P2ON       $315         ; EQUI A2 = Phase2 ON           / DRVSM5 / $C085+SLOT*$10
#define P3OFF      $316         ; EQUI A2 = Phase3 OFF          / DRVSM6 / $C086+SLOT*$10
#define P3ON       $317         ; EQUI A2 = Phase3 ON           / DRVSM7 / $C087+SLOT*$10

#define MOTOFF     $318         ; EQUI A2 = Motor  OFF          / DRVOFF / $C088+SLOT*$10
#define MOTON      $319         ; EQUI A2 = Motor  ON           / DRVON  / $C089+SLOT*$10
#define DRSEL1     $31A         ; EQUI A2 = Select DR1          / DRVSL1 / $C08A+SLOT*$10
#define DRSEL2     $31B         ; EQUI A2 = Select DR2          / DRVSL2 / $C08B+SLOT*$10

#define SHIFTREG   $31C         ; EQUI A2 = STROBE DATA LATCH   / DRVRD  / $C08C+SLOT*$10 (Q6L)
#define DATAREG    $31D         ; EQUI A2 = LOAD DATA LATCH     / DRVWR  / $C08D+SLOT*$10 (Q6H)
#define READMODE   $31E         ; EQUI A2 = SET READ MODE       / DRVRDM / $C08E+SLOT*$10 (Q7L)
#define WRITEMODE  $31F         ; EQUI A2 = SET WRITE MODE      / DRVWRM / $C08F+SLOT*$10 (Q7H)
                                                    
; from Beneath Apple DOS (Don Worth/Pieter Lechner)
; Q7L with Q6L = Read
; Q7L with Q6H = Sens Write Protect
; Q7H with Q6L = Write
; Q7H with Q6H = Load Write Latch


#define TRANS_TABLE $F100

#define BUFF_P	    $400
#define BUFF_S	    $500

; -------------------------------------

;//
;// Zero page definition
;//

    .zero

	*= $A0

; PAGE ZERO
                          
;-PARAMETRES D'ENTREE
PISDEP  .dsb 1      ; $A0       ; PISTE DE DEPART
SECDEP  .dsb 1      ; $A1       ; SECTEUR DE DEPART
BUFFER  .dsb 2      ; $A2 ;+$A3 ; ADRESSE OU L'ON CHARGE
TOTSEC  .dsb 1      ; $A4       ; TOTAL DES SECTEURS A CHARGER 
CURTRK1 .dsb 1      ; $A5       ; piste de départ DRIVE 1 - A INITIALISER A ZERO pour le premier appel !


; USED temporairement par FLOADZ
TEMPA	.dsb 1
SECTOR  .dsb 1
TEMPB	.dsb 1
TEMPC	.dsb 1
DEST	.dsb 2            
COUNTG	.dsb 1
COUNT1	.dsb 1
COUNT2	.dsb 1
COUNT3	.dsb 1


    .text
  
; $F000               
FLOAD
; entrée : PISDEP/SECDEP/TOTSEC/BUFFER
	
			; init lecture
            LDA MOTON       ; motor on
         	LDA DRSEL1      ; select drive 1 
         	LDA READMODE    ; MODE... 
         	LDA SHIFTREG    ; ...LECTURE (Q7L + Q6L)

	        LDA P0OFF
        	LDA P1OFF
         	LDA P2OFF
         	LDA P3OFF     ; INIT PHASES POUR BRAS
                          ;
         	LDA #1
         	JSR TEMPO
                          ;
         	LDY #3
INILEC2  	LDA #0
         	JSR TEMPO
         	DEY
         	BNE INILEC2
			; ----

			; début routine de lecture (entrée : PISDEP/SECDEP/TOTSEC/BUFFER)
         	LDA SECDEP	
            STA FIRSTSEC+1		; init premier secteur
            LDA TOTSEC			; initialisation compteur du nombre de secteurs à lire
        	STA COUNTG			; compteur principal (décrémenter à chaque lecture)
			
            LDA BUFFER			; init buffer dest (low)
			STA DEST			
       
			LDX PISDEP			; piste à atteindre
			JSR ARMOVE			; déplacement tête sur la premiere piste à lire
			
BP_READ_ALL LDA #00
			STA COUNT2			; init à 0 du nb de secteurs à lire pour cette piste (incrémenté plus plus bas)
			LDA COUNTG			; compteur général (secteurs restant à lire)
			STA COUNT1			; compteur temporaire
  						
         	; on marque les sectors à lire pour la piste courante
			LDA #01				; marker (non lu)
FIRSTSEC	LDX #00				; premier secteur de la piste courante à lire (modif lors de l'init)
BMARK
			STA TMARKSECT,X		; on remplit la table avec les secteurs à lire
			INC COUNT2			; on incrémente le nombre de secteur à lire pour CETTE piste
			DEC COUNT1			
			BEQ s1				; cas : dernier secteur de la dernière piste à lire ?	
			INX
			CPX #$10			; 16 ? piste pleine
			BNE BMARK
			; ----------
			LDA COUNT2
			STA COUNT3			; on sauve le nb de secteurs à lire pour cette piste
			; ----------
s1	        ; LECTURE SECTEUR(s) DE LA PISTE COURANTE
loop_read  	
LOCATE_SECTOR
  	
			
         	; check entete     
			SEI					; on bloque les INT
br1 	 	LDA	SHIFTREG
         	BPL br1
br1b        CMP	#$D5
         	BNE	br1
br2 	  	LDA SHIFTREG
         	BPL br2
         	CMP #$AA
         	BNE	br1b
br3 	  	LDA	SHIFTREG
         	BPL	br3
         	CMP #$96
         	BNE	br1b
            
            ; lecture info du sector
br4         LDA SHIFTREG		; Volume4
         	BPL br4
         	STA TEMPA			; POUR LE TIMING => 3 cycles mini (peut-être 4c nécessaire pour tous les drives ?!)
br4b		LDA SHIFTREG		; Volume/4
         	BPL br4b
         	STA TEMPA			; POUR LE TIMING
br5         LDA SHIFTREG		; Track4
         	BPL br5
         	STA TEMPA			; POUR LE TIMING
br5b		LDA SHIFTREG		; Track/4
         	BPL br5b
         	STA TEMPA			; POUR LE TIMING
br6 	  	LDA SHIFTREG		; Sector4
         	BPL br6
         	STA TEMPA		
br6b	  	LDA SHIFTREG		; Sector/4
         	BPL br6b
         	; SEC				; inutile car le dernier CMP (égal) a mis C à 1 !
         	ROL TEMPA
         	AND TEMPA
         	TAY					; numéro secteur physique			
         	LDA TSECT,Y			; -> numéro secteur soft !
         	STA	SECTOR			; sauve numéro (software) du secteur 
         	TAY
         	LDA	TMARKSECT,Y		; on checke si le secteur est "bien" à lire
         	BEQ br1 			; si non, on passe à un autre
         	
			; routine de lecture d'un SECTEUR (342 nibbles)
READ_SECTOR   	
					
            ; lecture entête DATA (D5AAAD)
rl1 	 	LDA SHIFTREG
         	BPL rl1
rl1b        CMP #$D5
         	BNE rl1
rl2 	  	LDA SHIFTREG
         	BPL rl2
          	CMP #$AA
         	BNE rl1b
rl3 	  	LDA SHIFTREG
         	BPL rl3
         	EOR #$AD			; EOR plutôt que CMP pour mise à 0 de A
         	BNE rl1b
               
            ; lecture/decodage DATA
			LDY #$56           
         	; LDA #$00
         	
loop_r1     DEY
			STY TEMPA
rl4         LDY SHIFTREG
			BPL rl4
			EOR TRANS_TABLE,Y
			LDY TEMPA
         	STA BUFF_S,Y
         	BNE loop_r1
         	
loop_r2   	STY TEMPA
rl5 		LDY SHIFTREG
			BPL rl5
         	EOR TRANS_TABLE,Y
         	LDY TEMPA
         	STA BUFF_P,Y
         	INY
         	BNE loop_r2
         	; fin routine lecture / On shunte la verif du checksum et de l'épilogue
         	CLI					; INT ON !
         	
			; ---------------------------------------------
			TYA					; => A = 0 
		  	LDY	SECTOR			; on marque le secteur
         	STA	TMARKSECT,Y		; OK
			; ---------------------------------------------
			; calcul de DEST+1 (destination hi)
			TYA					; sector lu
			SEC
			SBC FIRSTSEC+1		; on calcul le "combien-tième" sector on vient de lire (0 inclus)			
			CLC
			ADC BUFFER+1		; on ajoute le résultat au BUFFER (hi) de base pour obtenir l'adresse de l'endroit où on doit denibblelized le sector lu
			STA DEST+1 
			; ---------------------------------------------
			; POST DENIBBLE ROUTINE (DOS 3.3)
			LDY #$00
lp1	    	LDX #$56
lp2 		DEX
			BMI lp1
			LDA BUFF_P,Y
			LSR BUFF_S,X
			ROL
			LSR BUFF_S,X
			ROL
			STA (DEST),Y
			INY
			BNE lp2 
			; ---------------------------------------------

			DEC COUNTG			; on décrémente le nombre total de secteurs à lire
         	BEQ	fin 			; il en reste ? non ? On sort
         	DEC COUNT2			; on décrémente le nombre de secteurs à lire pour CETTE piste
         	BEQ suite
         	JMP loop_read		; il en reste ? Oui, on boucle (on cherche le secteur suivant). 
suite			
			; si non on passe à la piste suivante 
         	LDA #00				; oui, on réinit:
			STA FIRSTSEC+1		; on met à 0 pour le début de la piste suivante (on commencera secteur 0)
         	
			; on modifie le buffer de base pour la prochaine lecture de piste
			LDA COUNT3
			CLC
			ADC BUFFER+1
			STA BUFFER+1
			; ------------------------
ARMOVE_ONE_TRACK_UP 	; on déplace la tête de lecture d'une PISTE (en AVANT)
		  	; phase1
			LDA   CURTRK1
         	STA   TEMPB
         	INC   CURTRK1
		  	JSR   ARMOVE5
         	JSR   ARMOVE6			; tempo
         	LDA   TEMPB
         	AND   #3
         	ASL  
         	ORA   #00	         	; pour respecter le timing 
         	TAY
	        LDA   P0OFF,Y
         	JSR   ARMOVE6			; tempo
			; phase2
         	LDA   CURTRK1
         	STA   TEMPB
         	INC   CURTRK1
		  	JSR   ARMOVE5
         	JSR   ARMOVE6			; tempo
         	LDA   TEMPB
         	AND   #3
         	ASL  
         	ORA   #00	         	; pour respecter le timing 
         	TAY
	        LDA   P0OFF,Y
         	JSR   ARMOVE6			; tempo
         	; ------------------------
         	JMP BP_READ_ALL		 	; on boucle
                          
fin	    	
			LDA MOTOFF  			; drive off
         	RTS						; sortie
; ============================================================================

			.dsb $96-(*&255)
TABLE96			
; off $96 de TRANS_TABLE (imperatif!)		
			.byt $00,$01,$FF,$FF,$02,$03,$FF,$04,$05,$06,$FF,$FF,$FF,$FF,$FF,$FF
			.byt $07,$08,$FF,$FF,$FF,$09,$0A,$0B,$0C,$0D,$FF,$FF,$0E,$0F,$10,$11
			.byt $12,$13,$FF,$14,$15,$16,$17,$18,$19,$1A,$FF,$FF,$FF,$FF,$FF,$FF
			.byt $FF,$FF,$FF,$FF,$FF,$1B,$FF,$1C,$1D,$1E,$FF,$FF,$FF,$1F,$FF,$FF
			.byt $20,$21,$FF,$22,$23,$24,$25,$26,$27,$28,$FF,$FF,$FF,$FF,$FF,$29
			.byt $2A,$2B,$FF,$2C,$2D,$2E,$2F,$30,$31,$32,$FF,$FF,$33,$34,$35,$36
			.byt $37,$38,$FF,$39,$3A,$3B,$3C,$3D,$3E,$3F

; ============================================================================
; routine déplacement tête de lecture - positionnement sur la piste                          
; In 	: X : PISTE , (CURTRK1 = 0)
; Out	: CURTRK1
ARMOVE 
 
    		TXA				; piste à atteindre -> A
         	ASL   
         	STA   TEMPA
ARMOVE1  	LDA   CURTRK1
         	STA   TEMPB
         	SEC
         	SBC   TEMPA
         	BEQ   ARMOVE2	; si même piste, on sort !
         	BCS   ARMOVE3
         	INC   CURTRK1
         	BCC   ARMOVE4
ARMOVE3  	DEC   CURTRK1
ARMOVE4  	JSR   ARMOVE5
         	JSR   ARMOVE6
         	LDA   TEMPB
         	AND   #3
         	ASL  
         	ORA   #00           ; pour respecter le timing         
         	TAY
	        LDA   P0OFF,Y
         	JSR   ARMOVE6
         	BEQ   ARMOVE1
ARMOVE5  	LDA   CURTRK1
         	AND   #3
         	ASL  
         	ORA   #00           ; pour respecter le timing
         	TAY
	        LDA   P0ON,Y
			RTS
ARMOVE2  	;CLI
			RTS					; sortie ROUTINE ARMOVE
ARMOVE6  	LDA   #$28
TEMPO     	SEC
ARMOVE7  	STA	  TEMPC
ARMOVE8  	SBC   #1
         	BNE   ARMOVE8
         	LDA   TEMPC
         	SBC   #1
         	BNE   ARMOVE7
         	RTS
; =============================================================================
; Tables Décodage + Tables divers

TMARKSECT   .byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00                       
; TSECT    	.byt $00,$07,$0E,$06,$0D,$05,$0C,$04,$0B,$03,$0A,$02,$09,$01,$08,$0F    ; dos inter
TSECT    	.byt $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F   ; physical inter

ENDFLOAD