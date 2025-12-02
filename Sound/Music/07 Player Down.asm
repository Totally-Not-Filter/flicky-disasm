Player_Down_Header:
	; Voices
	dw	Player_Down_Voices
	; Channels (FM, PSG)
	db	06, 02
	; Tempo
	db	02, 00

	; DAC Channel
	dw	Player_Down_DAC
	db	00, 00h
	; FM1 Channel
	dw	Player_Down_FM1
	db	01, 00h
	; FM2 Channel
	dw	Player_Down_FM2
	db	-01, 08h
	; FM3 Channel
	dw	Player_Down_FM3
	db	-11, 10h
	; FM4 Channel
	dw	Player_Down_FM4
	db	-11, 10h
	; FM5 Channel
	dw	Player_Down_FM5
	db	-11, 20h
	; PSG1 Channel
	dw	Player_Down_PSG1
	db	-11, 08h
	db	01, 01
	; PSG2 Channel
	dw	Player_Down_PSG2
	db	-11, 08h
	db	00, 02

; 1A75
; FM3 Data
Player_Down_FM3:
	db	nRst, 05h
	smpsModSet  03h, 01h, 04h, 09h
	smpsFMvoice 00h
	smpsJump    Player_Down_Jump01

; 1A81
; FM1 Data
Player_Down_FM1:
	db	0EAh, 27h
	db	03h
	db	0E6h

	smpsFMvoice 00h

; 1A87
Player_Down_Jump01:
	db	0E4h, 02h, 03h, 02h, 03h, 03h
	db	nCs5, 0Ch, nEb5, nCs5, nEb5, nAb4, nRst, nAb4, nRst, nB4, 06h
	db	nBb4, nA4, nAb4, nG4, nFs4, nF4, nE4, nEb4, nD4, nCs4, nC4, nB3
	db	nBb3, nA3, nAb3
	smpsStop

; 1AA8
; FM4 Data
Player_Down_FM4:
	db	nRst, 03h
	smpsModSet  03h, 01h, 04h, 09h
	smpsFMvoice 00h
	smpsJump    Player_Down_Jump02

; 1AB4
; FM2 Data
Player_Down_FM2:
	smpsFMvoice 00h

; 1AB6
Player_Down_Jump02:
	db	0E4h, 02h, 03h, 02h, 02h, 03h
	db	nCs5, 0Ch, nEb5, nCs5, nEb5, nAb4, nRst, nAb4, nRst, nB4, 06h, nBb4, nA4
	db	nAb4, nG4, nFs4, nF4, nE4, nEb4, nD4, nCs4, nC4, nB3, nBb3, nA3, nAb3
	smpsStop

; 1AD7
; FM5 Data
Player_Down_FM5:
	smpsFMvoice 00h
	smpsFMvoice 00h
	smpsFMvoice 00h
	smpsStop

; 1ADE
; PSG1 Data
Player_Down_PSG1:
; PSG2 Data
Player_Down_PSG2:
	smpsStop

; 1ADF
; DAC Data
Player_Down_DAC:
	smpsStop

Player_Down_Voices:
;	Voice $00
	db	0F1h
	db	04h, 04h, 12h, 14h,	0Fh, 0Fh, 3Ch, 3Ah,	00h, 10h, 10h, 14h
	db	00h, 00h, 00h, 10h,	7Fh, 7Fh, 7Fh, 0Ch,	96h, 93h, 99h, 80h

;	Voice $01 (Unused?)
	db	10h
	db	04h, 02h, 08h, 04h,	1Fh, 1Fh, 1Fh, 1Fh,	10h, 0Fh, 09h, 08h
	db	07h, 00h, 00h, 00h,	3Fh, 0Fh, 0Fh, 4Fh,	20h, 20h, 20h, 80h

;	Voice $02 (Duplicate of Above, Unused?)
	db	10h
	db	04h, 02h, 08h, 04h,	1Fh, 1Fh, 1Fh, 1Fh,	10h, 0Fh, 09h, 08h
	db	07h, 00h, 00h, 00h,	3Fh, 0Fh, 0Fh, 4Fh,	20h, 20h, 20h, 80h