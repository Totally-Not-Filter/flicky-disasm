; ---------------------------------------------------------------------------
; Flicky Sound Driver Disassembly
; Originally done by ValleyBell
; Fixed up for usage by Filter
;
; Note:	Sega Channel BIOS (J) uses the exactly same driver revision.
;	Differences (a few pointers and	FM drums) are noted.
; ---------------------------------------------------------------------------

	phase $1C00
	padding off
byte_1C00:	ds.b 1
byte_1C01:	ds.b 1
word_1C02:	ds.w 1
word_1C04:	ds.w 1
byte_1C06:	ds.b 1
byte_1C07:	ds.b 1
unk_1C08:	ds.b 1
byte_1C09:	ds.b 1
unk_1C0A:	ds.b 1
unk_1C0B:	ds.b 1
unk_1C0C:	ds.b 1
byte_1C0D:	ds.b 1
byte_1C0E:	ds.b 1
byte_1C0F:	ds.b 1
unk_1C10:	ds.b 1			; Pause flag
byte_1C11:	ds.b 1
byte_1C12:	ds.b 1
byte_1C13:	ds.b 1
byte_1C14:	ds.b 1
byte_1C15:	ds.b 1
byte_1C16:	ds.b 1
byte_1C17:	ds.b 1
byte_1C18:	ds.b 1
byte_1C19:	ds.b 1
byte_1C1A:	ds.b 8
byte_1C22:	ds.b 8
byte_1C2A:	ds.b 8
byte_1C32:	ds.b 1
word_1C33:	ds.w 1
word_1C35:	ds.w 1
word_1C37:	ds.w 1
word_1C39:	ds.w 1
byte_1C3B:	ds.b 1
		ds.b 1
		ds.b 1
		ds.b 1
		ds.b 1
byte_1C40:	ds.b 1
		ds.b 1
byte_1C42:	ds.b 9
byte_1C4B:	ds.b $25
byte_1C70:	ds.b $0F0
byte_1D60:	ds.b 5
byte_1D65:	ds.b 1
byte_1D66:	ds.b 2
byte_1D68:	ds.b $28
byte_1D90:	ds.b $30
byte_1DC0:	ds.b $30
byte_1DF0:	ds.b $30
byte_1E20:	ds.b $60
byte_1E80:	ds.b $17D
unk_1FFD:	ds.b 1
		ds.b 1
byte_1FFF:	ds.b 1
	dephase
	!org	Z80SoundDriver

	save
	phase 0
	cpu z80

DrumHeader	macro ptr,trans,vol,mod,inst ;	(sizeof=0x6)
		dw ptr			; offset
		db trans
		db vol
		db mod
		db inst
		endm

; ===========================================================================

Initalize:
		di
		di
		im	1
		jr	InitDriver
; ---------------------------------------------------------------------------
		align 8

; =============== S U B	R O U T	I N E =======================================


WaitForYM:
		ld	a, (4000h)
		bit	7, a
		jr	nz, WaitForYM
		ret
; End of function WaitForYM


; =============== S U B	R O U T	I N E =======================================


WriteFMMain:
		bit	7, (ix+1)
		ret	nz
		jp	WriteFMIorII
; End of function WriteFMMain


; =============== S U B	R O U T	I N E =======================================


WriteFMI:
		ld	(4000h), a
		rst	WaitForYM
		ld	a, c
		jp	YMRegister1
; End of function WriteFMI


; =============== S U B	R O U T	I N E =======================================


GetListOfs:
		ld	hl, (word_1C02)	; get Pointer List Offset from 1C02/03
		jp	GetPtrListOfs
; End of function GetListOfs

; ---------------------------------------------------------------------------
		align 8

; =============== S U B	R O U T	I N E =======================================


ReadPtrTable:
		ld	c, a
		ld	b, 0
		add	hl, bc
		add	hl, bc
		nop
		nop
		nop
; End of function ReadPtrTable


; =============== S U B	R O U T	I N E =======================================


ReadPtrFromHL:
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a
		ret
; End of function ReadPtrFromHL

; ---------------------------------------------------------------------------
		org	38h

VInt:					; where	is the DI??
		push	af
		push	bc		; save some registers
		push	de
		push	hl
		ld	hl, byte_1FFF	; HL = Skip Update counter
		ld	a, (hl)
		or	a		; Counter == 0?
		jr	z, loc_46	; yes -	update sound
		dec	(hl)		; no - decrement
		jr	loc_4D		; and don't do anything else
; ---------------------------------------------------------------------------

loc_46:
		ld	a, (byte_1C07)	; 1C07 - Timing	Mode
		or	a
		call	z, UpdateAll	; update only when 1C07	== 00

loc_4D:
		pop	hl		; restore the registers
		pop	de
		pop	bc
		pop	af
		ei
		ret
; ---------------------------------------------------------------------------

InitDriver:
		ld	sp, unk_1FFD
		ld	a, 3
		ld	(byte_1FFF), a	; make it skip 3 updates

loc_5B:
		ei			; enable VInt
		ld	a, (byte_1FFF)
		or	a		; wait for 3 VInts
		jp	nz, loc_5B
		call	StopAllSound
		call	SetupBank
		call	RefreshTimerA
		call	RefreshTimerB

loc_6F:
		ei
		call	DoSoundQueue
		ld	a, (byte_1C07)	; 1C07 - Timing	Mode
		or	a
		jr	z, loc_6F	; Timing Mode 00, update on VInt
		di
		jp	p, TimerB_Update ; Timing Mode 40 - Update on YM2612 Timer A

TimerAB_Update:				; Timing Mode 80
		call	DoSoundQueue
		ld	a, (4000h)	; Music	Update on YM2612 Timer A
		and	3		; SFX Update on	YM2612 Timer B
		jr	z, loc_6F	; none of the YM2612 Timers expired - jump back
		bit	1, a
		jr	z, loc_9B	; Timer	B not yet expired - try	Timer A
		call	RefreshTimerB	; Timer	B expired - update SFX
		ld	hl, loc_9B	; make it jump to the Timer A update check when
		push	hl		; returning from UpdateSFXTracks
		call	DoPause
		call	PlaySoundID
		jp	UpdateSFXTracks
; ---------------------------------------------------------------------------

loc_9B:
		ld	a, (4000h)
		bit	0, a
		jr	z, loc_6F
		call	RefreshTimerA	; Timer	A expires - update Music
		call	UpdateAll
		jr	loc_6F
; ---------------------------------------------------------------------------

TimerB_Update:
		ld	a, (4000h)

loc_AD:
		bit	1, a
		jr	z, loc_6F
		call	RefreshTimerB	; update everything when Timer B expires
		call	UpdateAll
		jr	loc_6F

; =============== S U B	R O U T	I N E =======================================


RefreshTimerA:
		ld	hl, (word_1C04)
		ld	a, l
		and	3
		ld	c, a
		ld	a, 25h
		rst	WriteFMI	; write	Timer A	LSB
		srl	h
		rr	l
		srl	h
		rr	l
		ld	c, l
		ld	a, 24h
		rst	WriteFMI	; write	Timer A	MSB
		ld	a, 1Fh
		jr	ResetYMTimer
; End of function RefreshTimerA


; =============== S U B	R O U T	I N E =======================================


RefreshTimerB:
		ld	a, (byte_1C06)
		ld	c, a
		ld	a, 26h
		rst	WriteFMI	; write	Timer B
		ld	a, 2Fh

ResetYMTimer:
		ld	hl, byte_1C12
		or	(hl)
		ld	c, a
		ld	a, 27h
		rst	WriteFMI	; Reset	Timer
		ret
; End of function RefreshTimerB


; =============== S U B	R O U T	I N E =======================================


UpdateAll:
		call	DoPause
		call	DoTempo
		call	DoFading
		call	PlaySoundID
		ld	a, (byte_1C07)	; 1C07 - Timing	Mode
		or	a
		call	p, UpdateSFXTracks ; 1C07 < 80 - update	SFX (SFX use Music Timing)
		xor	a
		ld	(byte_1C19), a	; 00 - Music Mode
		ld	ix, byte_1C40	; 1C40 - Music Track Drum
		bit	7, (ix+0)
		call	nz, DrumUpdateTrack
		ld	b, 9		; 9 Music Tracks (10 minus Drum	Track)
		ld	ix, byte_1C70	; 1C70 - Music Track FM1
		jr	TrkUpdateLoop
; End of function UpdateAll


; =============== S U B	R O U T	I N E =======================================


UpdateSFXTracks:
		ld	a, 1
		ld	(byte_1C19), a	; 01 - SFX Mode
		ld	ix, byte_1E80	; 1E80 - SFX Tracks
		ld	b, 6		; 6 SFX	tracks
		call	TrkUpdateLoop
		ld	a, 80h
		ld	(byte_1C19), a	; 80 - Special SFX Mode
		ld	b, 2		; 2 special SFX	tracks
		ld	ix, byte_1E20	; 1E20 - Special SFX Tracks
; End of function UpdateSFXTracks


; =============== S U B	R O U T	I N E =======================================


TrkUpdateLoop:
		push	bc
		bit	7, (ix+0)	; 'in use' flag set?
		call	nz, UpdateTrack
		ld	de, 30h		; next track
		add	ix, de
		pop	bc
		djnz	TrkUpdateLoop
		ret
; End of function TrkUpdateLoop


; =============== S U B	R O U T	I N E =======================================


UpdateTrack:
		bit	7, (ix+1)
		jp	nz, UpdatePSGTrk
		call	TrackTimeout
		jr	nz, loc_15C
		call	TrkUpdate_Proc
		bit	4, (ix+0)
		ret	nz
		call	PrepareModulat
		call	DoPitchSlide
		call	DoModulation
		call	SendFMFreq
		jp	DoNoteOn
; ---------------------------------------------------------------------------

loc_15C:
		call	ExecPanAnim
		bit	4, (ix+0)
		ret	nz
		call	DoFMVolEnv
		ld	a, (ix+1Eh)
		or	a
		jr	z, loc_173
		dec	(ix+1Eh)
		jp	z, SendNoteOff

loc_173:
		call	DoPitchSlide
		bit	6, (ix+0)
		ret	nz
		call	DoModulation
; End of function UpdateTrack


; =============== S U B	R O U T	I N E =======================================


SendFMFreq:
		bit	2, (ix+0)
		ret	nz
		bit	0, (ix+0)
		jp	nz, loc_193

loc_18A:
		ld	a, 0A4h
		ld	c, h
		rst	WriteFMMain
		ld	a, 0A0h
		ld	c, l
		rst	WriteFMMain
		ret
; ---------------------------------------------------------------------------

loc_193:
		ld	a, (ix+1)
		cp	2
		jr	nz, loc_18A
		call	GetFM3FreqPtr
		exx
		ld	hl, SpcFM3Regs
		ld	b, 4

loc_1A3:
		ld	a, (hl)
		push	af
		inc	hl
		exx
		ex	de, hl
		ld	c, (hl)
		inc	hl
		ld	b, (hl)
		inc	hl
		ex	de, hl
		ld	l, (ix+0Dh)
		ld	h, (ix+0Eh)
		add	hl, bc
		pop	af
		push	af
		ld	c, h
		rst	WriteFMI
		pop	af
		sub	4
		ld	c, l
		rst	WriteFMI
		exx
		djnz	loc_1A3
		exx
		ret
; End of function SendFMFreq

; ---------------------------------------------------------------------------
SpcFM3Regs:	db 0ADh, 0AEh, 0ACh, 0A6h

; =============== S U B	R O U T	I N E =======================================


GetFM3FreqPtr:
		ld	de, byte_1C2A
		ld	a, (byte_1C19)
		or	a
		ret	z		; Music	Mode (00) - 1C2A
		ld	de, byte_1C1A
		ret	p		; Special SFX Mode (80)	- 1C1A
		ld	de, byte_1C22
		ret			; SFX Mode (01)	- 1C22
; End of function GetFM3FreqPtr


; =============== S U B	R O U T	I N E =======================================


TrkUpdate_Proc:
		ld	e, (ix+3)
		ld	d, (ix+4)
		res	1, (ix+0)
		res	4, (ix+0)

loc_1E4:
		ld	a, (de)
		inc	de
		cp	0E0h
		jp	nc, cfHandler
		ex	af, af'
		call	DoNoteOff
		call	DoPanAnimation
		ex	af, af'
		bit	3, (ix+0)
		jp	nz, DoRawFreqMode
		or	a
		jp	p, SetDuration	; 00-7F	- Delay
		sub	81h
		jp	p, GetNote	; 81-DF	- Note
		call	SetRest		; 80 - Rest
		jr	loc_236
; ---------------------------------------------------------------------------

GetNote:
		add	a, (ix+5)
		ld	hl, PSGFreqs
		push	af
		rst	ReadPtrTable
		pop	af
		bit	7, (ix+1)
		jr	nz, loc_230
		push	de
		ld	d, 8
		ld	e, 0Ch
		ex	af, af'
		xor	a

loc_21E:
		ex	af, af'
		sub	e
		jr	c, loc_227
		ex	af, af'
		add	a, d
		jr	loc_21E
; ---------------------------------------------------------------------------
		; dead code in multiple z80 Type 1a and Type 1b sound drivers.
		ex	af, af'

loc_227:
		add	a, e
		ld	hl, FMFreqs
		rst	ReadPtrTable
		ex	af, af'
		or	h
		ld	h, a
		pop	de

loc_230:
		ld	(ix+0Dh), l
		ld	(ix+0Eh), h

loc_236:
		bit	5, (ix+0)
		jr	nz, loc_249
		ld	a, (de)
		or	a
		jp	p, loc_275
		ld	a, (ix+0Ch)
		ld	(ix+0Bh), a
		jr	loc_27C
; ---------------------------------------------------------------------------

loc_249:
		ld	a, (de)
		inc	de
		ld	(ix+10h), a
		jr	loc_274
; ---------------------------------------------------------------------------

DoRawFreqMode:
		ld	h, a
		ld	a, (de)
		inc	de
		ld	l, a
		or	h
		jr	z, loc_263
		ld	a, (ix+5)
		ld	b, 0
		or	a
		jp	p, loc_261
		dec	b

loc_261:
		ld	c, a
		add	hl, bc

loc_263:
		ld	(ix+0Dh), l
		ld	(ix+0Eh), h
		bit	5, (ix+0)
		jr	z, loc_274
		ld	a, (de)
		inc	de
		ld	(ix+10h), a

loc_274:
		ld	a, (de)

loc_275:
		inc	de

SetDuration:
		call	TickMultiplier
		ld	(ix+0Ch), a

loc_27C:
		ld	(ix+3),	e
		ld	(ix+4),	d
		ld	a, (ix+0Ch)
		ld	(ix+0Bh), a
		bit	1, (ix+0)
		ret	nz
		xor	a
		ld	(ix+25h), a
		ld	(ix+22h), a
		ld	a, (ix+1Fh)
		ld	(ix+1Eh), a
		ld	(ix+17h), a
		ret
; End of function TrkUpdate_Proc


; =============== S U B	R O U T	I N E =======================================


TickMultiplier:
		ld	b, (ix+2)
		dec	b
		ret	z
		ld	c, a

loc_2A4:
		add	a, c
		djnz	loc_2A4
		ret
; End of function TickMultiplier


; =============== S U B	R O U T	I N E =======================================


DoPanAnimation:
		ld	a, (ix+11h)
		dec	a
		ret	m
		jr	nz, loc_2EA
		bit	1, (ix+0)
		ret	nz

loc_2B4:
		dec	(ix+16h)
		ret	nz
		exx
		ld	a, (ix+15h)
		ld	(ix+16h), a
		ld	a, (ix+12h)
		ld	hl, PanAniPtrList
		rst	ReadPtrTable
		ld	e, (ix+13h)
		inc	(ix+13h)
		ld	a, (ix+14h)
		dec	a
		cp	e
		jr	nz, loc_2E1
		dec	(ix+13h)
		ld	a, (ix+11h)
		cp	2
		jr	z, loc_2E1
		ld	(ix+13h), 0

loc_2E1:
		ld	d, 0
		add	hl, de
		ex	de, hl
		call	cfE0_Pan
		exx
		ret
; ---------------------------------------------------------------------------

loc_2EA:
		xor	a
		ld	(ix+13h), a
; End of function DoPanAnimation


; =============== S U B	R O U T	I N E =======================================


ExecPanAnim:
		ld	a, (ix+11h)
		sub	2
		ret	m
		jr	loc_2B4
; End of function ExecPanAnim

; ---------------------------------------------------------------------------
PanAniPtrList:	dw byte_2FE, byte_2FF, byte_300, byte_301
byte_2FE:	db 0C0h
byte_2FF:	db  80h
byte_300:	db 0C0h
byte_301:	db  40h, 80h,0C0h

; =============== S U B	R O U T	I N E =======================================


TrackTimeout:
		ld	a, (ix+0Bh)
		dec	a
		ld	(ix+0Bh), a
		ret
; End of function TrackTimeout


; =============== S U B	R O U T	I N E =======================================


DoFMVolEnv:
		ld	a, (ix+18h)
		or	a
		ret	z
		dec	a
		ld	c, 0Ah
		rst	GetListOfs	; get List 5 (PSG/Volume envelopes)
		rst	ReadPtrTable
		call	DoPSGVolEnv
		ld	h, (ix+1Dh)
		ld	l, (ix+1Ch)
		ld	de, Volume_Ops
		ld	b, 4
		ld	c, (ix+19h)

loc_327:
		push	af
		sra	c
		push	bc
		jr	nc, loc_333
		add	a, (hl)
		and	7Fh
		ld	c, a
		ld	a, (de)
		rst	WriteFMMain

loc_333:
		pop	bc
		inc	de
		inc	hl
		pop	af
		djnz	loc_327
		ret
; End of function DoFMVolEnv


; =============== S U B	R O U T	I N E =======================================


PrepareModulat:
		bit	7, (ix+7)
		ret	z
		bit	1, (ix+0)
		ret	nz
		ld	e, (ix+20h)
		ld	d, (ix+21h)
		push	ix
		pop	hl
		ld	b, 0
		ld	c, 24h
		add	hl, bc
		ex	de, hl
		ldi
		ldi
		ldi
		ld	a, (hl)
		srl	a
		ld	(de), a
		xor	a
		ld	(ix+22h), a
		ld	(ix+23h), a
		ret
; End of function PrepareModulat


; =============== S U B	R O U T	I N E =======================================


DoModulation:
		ld	a, (ix+7)
		or	a
		ret	z		; ModType 00 ->	return (modulation off)
		cp	80h
		jr	nz, DoModEnv	; ModType != 80	-> jump
		dec	(ix+24h)	; ModType 80 ->	manual modulation parameters
		ret	nz
		inc	(ix+24h)
		push	hl
		ld	l, (ix+22h)
		ld	h, (ix+23h)
		dec	(ix+25h)
		jr	nz, loc_3A1
		ld	e, (ix+20h)
		ld	d, (ix+21h)
		push	de
		pop	iy
		ld	a, (iy+1)
		ld	(ix+25h), a
		ld	a, (ix+26h)
		ld	c, a
		and	80h
		rlca
		neg
		ld	b, a
		add	hl, bc
		ld	(ix+22h), l
		ld	(ix+23h), h

loc_3A1:
		pop	bc
		add	hl, bc
		dec	(ix+27h)
		ret	nz
		ld	a, (iy+3)
		ld	(ix+27h), a
		ld	a, (ix+26h)
		neg
		ld	(ix+26h), a
		ret
; ---------------------------------------------------------------------------

DoModEnv:
		dec	a
		ex	de, hl
		ld	c, 8
		ld	b, 80h
		call	GetListOfsAB	; get List 4 (Modulation Pointers)
		jr	loc_3C4
; ---------------------------------------------------------------------------

loc_3C1:
		ld	(ix+25h), a

loc_3C4:
		push	hl
		ld	c, (ix+25h)
		call	GetEnvData	; BC = HL (base) + BC (index), A = (BC)
		pop	hl
		bit	7, a
		jp	z, ModEnv_Positive
		cp	82h
		jr	z, ModEnv_Jump2Idx ; 82	xx - jump to byte xx
		cp	80h
		jr	z, ModEnv_Reset	; 80 - loop back to beginning
		cp	84h
		jr	z, ModEnv_ChgMult ; 84 - change	Modulation Multipler
		ld	h, 0FFh		; make HL negative (FFxx)
		jr	nc, ModEnv_Next
		set	6, (ix+0)
		pop	hl
		ret
; ---------------------------------------------------------------------------

ModEnv_Jump2Idx:
		inc	bc
		ld	a, (bc)
		jr	loc_3C1
; ---------------------------------------------------------------------------

ModEnv_Reset:
		xor	a
		jr	loc_3C1
; ---------------------------------------------------------------------------

ModEnv_ChgMult:
		inc	bc
		ld	a, (bc)
		add	a, (ix+22h)
		ld	(ix+22h), a
		inc	(ix+25h)
		inc	(ix+25h)
		jr	loc_3C4
; ---------------------------------------------------------------------------

ModEnv_Positive:
		ld	h, 0		; make HL positive (00xx)

ModEnv_Next:
		ld	l, a
		ld	b, (ix+22h)
		inc	b
		ex	de, hl

loc_406:
		add	hl, de
		djnz	loc_406
		inc	(ix+25h)
		ret
; End of function DoModulation

; ---------------------------------------------------------------------------

DoNoteOn:
		ld	a, (ix+0Dh)
		or	(ix+0Eh)
		ret	z
		ld	a, (ix+0)
		and	6
		ret	nz
		ld	a, (ix+1)
		or	0F0h
		ld	c, a
		ld	a, 28h
		rst	WriteFMI
		ret

; =============== S U B	R O U T	I N E =======================================


DoNoteOff:
		ld	a, (ix+0)
		and	6
		ret	nz

SendNoteOff:
		ld	c, (ix+1)
		bit	7, c
		ret	nz

FMNoteOff:
		ld	a, 28h
		rst	WriteFMI
		ret
; End of function DoNoteOff


; =============== S U B	R O U T	I N E =======================================


DoPitchSlide:
		ld	b, 0
		ld	a, (ix+10h)
		or	a
		jp	p, loc_43E
		dec	b

loc_43E:
		ld	h, (ix+0Eh)
		ld	l, (ix+0Dh)
		ld	c, a
		add	hl, bc
		bit	7, (ix+1)
		jr	nz, loc_46E
		ex	de, hl
		ld	a, 7
		and	d
		ld	b, a
		ld	c, e
		or	a
		ld	hl, 283h
		sbc	hl, bc
		jr	c, loc_460
		ld	hl, -57Bh
		add	hl, de
		jr	loc_46E
; ---------------------------------------------------------------------------

loc_460:
		or	a
		ld	hl, 508h
		sbc	hl, bc
		jr	nc, loc_46D
		ld	hl, 57Ch
		add	hl, de
		ex	de, hl

loc_46D:
		ex	de, hl

loc_46E:
		bit	5, (ix+0)
		ret	z
		ld	(ix+0Eh), h
		ld	(ix+0Dh), l
		ret
; End of function DoPitchSlide


; =============== S U B	R O U T	I N E =======================================


GetPtrListOfs:
		ld	b, 0
		add	hl, bc
		ex	af, af'
		rst	ReadPtrFromHL
		ex	af, af'
		ret
; End of function GetPtrListOfs


; =============== S U B	R O U T	I N E =======================================

; BC = HL (base) + BC (index), A = (BC)

GetEnvData:
		ld	b, 0
		add	hl, bc
		ld	c, l
		ld	b, h
		ld	a, (bc)
		ret
; End of function GetEnvData


; =============== S U B	R O U T	I N E =======================================


GetFMInsPtr:
		ld	hl, (word_1C37)
		ld	a, (byte_1C19)
		or	a
		jr	z, JumpToInsData ; Mode	00 (Music Mode)	- jump
		ld	l, (ix+2Ah)	; load SFX track Instrument Pointer (Trk+2A/2B)
		ld	h, (ix+2Bh)
; End of function GetFMInsPtr


; =============== S U B	R O U T	I N E =======================================


JumpToInsData:
		xor	a
		or	b
		jr	z, .finished
		ld	de, 25

.loop:
		add	hl, de
		djnz	.loop

.finished:
		ret
; End of function JumpToInsData

; ---------------------------------------------------------------------------

WriteFMIorII:
		bit	2, (ix+1)	; is FM	4-6?
		jr	nz, WriteFMIIPart
		bit	2, (ix+0)
		ret	nz
		add	a, (ix+1)	; add Channel Bits to register value
		rst	WriteFMI
		ret
; ---------------------------------------------------------------------------

YMRegister1:
		ld	(4001h), a
		ret
; ---------------------------------------------------------------------------

WriteFMIIPart:
		bit	2, (ix+0)
		ret	nz
		add	a, (ix+1)
		sub	4

; =============== S U B	R O U T	I N E =======================================


WriteFMII:
		ld	(4002h), a
		rst	WaitForYM
		ld	a, c
		ld	(4003h), a
		ret
; End of function WriteFMII

; ---------------------------------------------------------------------------
FMInsOperators:	db 0B0h
		db  30h, 38h, 34h, 3Ch
		db  50h, 58h, 54h, 5Ch
		db  60h, 68h, 64h, 6Ch
		db  70h, 78h, 74h, 7Ch
		db  80h, 88h, 84h, 8Ch
Volume_Ops:	db  40h, 48h, 44h, 4Ch
SSGEG_Ops:	db  90h, 98h, 94h, 9Ch

; =============== S U B	R O U T	I N E =======================================


SendFMIns:
		ld	de, FMInsOperators
		ld	c, (ix+0Ah)
		ld	a, 0B4h
		rst	WriteFMMain
		call	WriteInsReg
		ld	(ix+1Bh), a
		ld	b, 14h

loc_4F7:
		call	WriteInsReg
		djnz	loc_4F7
		ld	(ix+1Ch), l
		ld	(ix+1Dh), h
		jp	RefreshVolume
; End of function SendFMIns


; =============== S U B	R O U T	I N E =======================================


WriteInsReg:
		ld	a, (de)
		inc	de
		ld	c, (hl)
		inc	hl
		rst	WriteFMMain
		ret
; End of function WriteInsReg


; =============== S U B	R O U T	I N E =======================================


PlaySoundID:
		ld	a, (byte_1C09)

PlaySnd_JumpIn:
		bit	7, a
		jp	z, StopAllSound	; 00-7F	- Stop All
		cp	90h
		jp	c, PlayMusic	; 80-8F	- Music
		cp	0D0h		; Note:	93h in Sega Channel BIOS (J)
		jp	c, PlaySFX	; 90-CF	- SFX
		cp	0E0h
		jp	c, PlaySpcSFX	; D0-DF	- Special SFX
		cp	0F9h
		jp	nc, StopAllSound ; F9-FF - Stop	All

PlaySnd_Command:			; E0-F8	- Special Commands
		sub	0E0h
		ld	hl, CmdPtrTable
		rst	ReadPtrTable
		jp	(hl)
; ---------------------------------------------------------------------------
CmdPtrTable:	dw FadeOutMusic
		dw StopAllSound
		dw SilencePSG
		dw StopSpcSFX
; ---------------------------------------------------------------------------

StopSpcSFX:
		ld	ix, byte_1E20	; 1F40 - Special SFX tracks
		ld	b, 2
		ld	a, 80h
		ld	(byte_1C19), a	; 80 - Special SFX Mode

loc_541:
		push	bc
		bit	7, (ix+0)	; Track	in use?
		call	nz, loc_552	; yes -	stop it
		ld	de, 30h
		add	ix, de		; next track
		pop	bc		; restore BC (C	has the	remaining number of tracks)
		djnz	loc_541
		ret
; ---------------------------------------------------------------------------

loc_552:
		push	hl		; push 4 bytes onto the	stack to make StopTrack
		push	hl		; return to the	correct	routine.
		jp	cfF2_StopTrk
; ---------------------------------------------------------------------------

PlayMusic:
		sub	81h		; Sound	ID -> Music Index
		ret	m		; was 80 (dummy	command) - return
		push	af
		call	StopAllSound
		pop	af
		ld	c, 4
		ld	b, 8
		call	GetListOfsAB	; get List 2 (Music Pointers)
		push	hl
		push	hl
		rst	ReadPtrFromHL
		ld	(word_1C37), hl	; save Instrument Pointer
		pop	hl
		pop	iy
		ld	a, (iy+5)	; read Tempo
		ld	(byte_1C13), a	; Tempo	work counter
		ld	(byte_1C14), a	; Tempo	Reset value
		ld	de, 6
		add	hl, de
		ld	(word_1C33), hl
		ld	hl, FMInitBytes
		ld	(word_1C35), hl
		ld	de, byte_1C40	; 1C40 - Music Track RAM
		ld	b, (iy+2)	; load FM tracks
		ld	a, (iy+4)	; load Tick Multiplier

loc_58E:
		push	bc
		ld	hl, (word_1C35)
		ldi
		ldi
		ld	(de), a
		inc	de
		ld	(word_1C35), hl
		ld	hl, (word_1C33)
		ldi
		ldi
		ldi
		ldi
		ld	(word_1C33), hl
		call	FinishFMTrkInit
		pop	bc
		djnz	loc_58E
		ld	a, (iy+3)	; load PSG tracks
		or	a
		jp	z, ClearSoundID	; no PSG tracks	- skip
		ld	b, a
		ld	hl, PSGInitBytes
		ld	(word_1C35), hl
		ld	de, byte_1D90	; 1D90 - Music Track PSG1
		ld	a, (iy+4)	; load Tick Multiplier

loc_5C3:
		push	bc		; same as FM init loop ...
		ld	hl, (word_1C35)
		ldi
		ldi
		ld	(de), a
		inc	de
		ld	(word_1C35), hl
		ld	hl, (word_1C33)
		ld	bc, 6
		ldir
		ld	(word_1C33), hl
		call	FinishTrkInit
		pop	bc
		djnz	loc_5C3

ClearSoundID:
		ld	a, 80h
		ld	(byte_1C09), a
		ret
; End of function PlaySoundID


; =============== S U B	R O U T	I N E =======================================


GetListOfsAB:
		cp	b
		jr	c, loc_5F3	; A < B	- use list collection from (1C02)
		sub	b		; A >= B - use list collection from 8000

GetListOfsROM:
		ld	hl, 8000h	; Note:	1200h in Sega Channel BIOS (J)
		call	GetPtrListOfs
		jr	loc_5F4
; ---------------------------------------------------------------------------

loc_5F3:
		rst	GetListOfs

loc_5F4:
		rst	ReadPtrTable
		ret
; End of function GetListOfsAB

; ---------------------------------------------------------------------------
FMInitBytes:	db  80h,   2
		db  80h,   0
		db  80h,   1
		db  80h,   4
		db  80h,   5
		db  80h,   6
		db  80h,   2
PSGInitBytes:	db  80h, 80h
		db  80h,0A0h
		db  80h,0C0h
; ---------------------------------------------------------------------------

PlaySpcSFX:
		sub	0D0h		; Sound	ID -> SFX Index
		push	af
		ld	c, 2
		rst	GetListOfs	; get List 1 (Special SFX)
		rst	ReadPtrTable
		ld	a, 80h		; 80 - Special SFX Init-Mode
		jr	loc_622
; ---------------------------------------------------------------------------

PlaySFX:
		sub	90h		; Sound	ID -> SFX Index
		push	af
		ld	c, 6
		ld	hl, unk_1C08
		ld	b, (hl)
		call	GetListOfsAB	; get List 3 (Normal SFX)
		xor	a		; 00 - normal SFX Init-Mode

loc_622:
		ld	(byte_1C19), a
		pop	af
		push	hl
		rst	ReadPtrFromHL
		ld	(word_1C39), hl
		xor	a
		ld	(byte_1C15), a
		pop	hl
		push	hl
		pop	iy
		ld	a, (iy+2)
		ld	(byte_1C3B), a
		ld	de, 4
		add	hl, de
		ld	b, (iy+3)

loc_640:
		push	bc
		push	hl
		inc	hl
		ld	c, (hl)
		call	GetSFXChnPtrs
		set	2, (hl)
		push	ix
		ld	a, (byte_1C19)
		or	a
		jr	z, loc_654
		pop	hl
		push	iy

loc_654:
		pop	de
		pop	hl
		ldi
		ld	a, (de)
		cp	2
		call	z, ResetSpcFM3Mode
		ldi
		ld	a, (byte_1C3B)
		ld	(de), a
		inc	de
		ldi
		ldi
		ldi
		ldi
		call	FinishFMTrkInit
		bit	7, (ix+0)
		jr	z, loc_682
		ld	a, (ix+1)
		cp	(iy+1)
		jr	nz, loc_682
		set	2, (iy+0)

loc_682:
		push	hl
		ld	hl, (word_1C39)
		ld	a, (byte_1C19)
		or	a
		jr	z, loc_690
		push	iy
		pop	ix

loc_690:
		ld	(ix+2Ah), l
		ld	(ix+2Bh), h
		call	DoNoteOff
		call	DisableSSGEG
		pop	hl
		pop	bc
		djnz	loc_640
		jp	ClearSoundID
; END OF FUNCTION CHUNK	FOR PlaySoundID

; =============== S U B	R O U T	I N E =======================================


GetSFXChnPtrs:
		bit	7, c
		jr	nz, loc_6AC
		ld	a, c
		sub	2
		jr	loc_6C2
; ---------------------------------------------------------------------------

loc_6AC:
		ld	a, 1Fh
		call	SilencePSGChn
		ld	a, 0FFh
		ld	(7F11h), a
		ld	a, c
		srl	a
		srl	a
		srl	a
		srl	a
		srl	a
		inc	a

loc_6C2:
		ld	(byte_1C32), a
		push	af
		ld	hl, SFXChnPtrs
		rst	ReadPtrTable
		push	hl
		pop	ix		; IX - SFX Track
		pop	af
		push	af
		ld	hl, SpcSFXChnPtrs
		rst	ReadPtrTable
		push	hl
		pop	iy		; IY - Special SFX Track
		pop	af
		ld	hl, BGMChnPtrs
		rst	ReadPtrTable	; HL - Music Track
		ret
; End of function GetSFXChnPtrs


; =============== S U B	R O U T	I N E =======================================


FinishFMTrkInit:
		ex	af, af'
		xor	a
		ld	(de), a
		inc	de
		ld	(de), a
		inc	de
		ex	af, af'
; End of function FinishFMTrkInit


; =============== S U B	R O U T	I N E =======================================


FinishTrkInit:
		ex	de, hl
		ld	(hl), 30h	; set GoSub Stack Pointer (30 =	track size)
		inc	hl
		ld	(hl), 0C0h	; set Pan to L/R
		inc	hl
		ld	(hl), 1		; set Note Timeout to 1	(next frame)
		ld	b, 24h

loc_6EE:
		inc	hl
		ld	(hl), 0		; fill rest of the track with 00s
		djnz	loc_6EE
		inc	hl
		ex	de, hl
		ret
; End of function FinishTrkInit

; ---------------------------------------------------------------------------
SpcSFXChnPtrs:	dw 1E20h, 1E20h, 1E20h,	1E20h, 1E50h, 1E20h, 1E20h, 1E50h
SFXChnPtrs:	dw 1E80h, 1EB0h, 1EB0h,	1EB0h, 1EE0h, 1F10h, 1F40h, 1F70h
BGMChnPtrs:	dw 1D60h, 1D00h, 1D00h,	1D00h, 1D30h, 1D90h, 1DC0h, 1DF0h

; =============== S U B	R O U T	I N E =======================================


SetupBank:
		ld	a, (byte_1C01)
		rlca
		ld	(6000h), a
		ld	b, 8
		ld	a, (byte_1C00)

loc_732:
		ld	(6000h), a
		rrca
		djnz	loc_732
		ret
; End of function SetupBank


; =============== S U B	R O U T	I N E =======================================


DoPause:
		ld	hl, unk_1C10	; 1C10 = Pause Mode
		ld	a, (hl)
		or	a
		ret	z		; 00 = not paused
		jp	m, UnpauseMusic	; 80-FF	- request Unpause
		pop	de
		dec	a		; 01 - request Pause?
		ret	nz		; no, it's 02 - return
		ld	(hl), 2		; it's 01, so set it to 02 (Pause active)
		jp	SilenceAll
; ---------------------------------------------------------------------------

UnpauseMusic:
		xor	a
		ld	(hl), a
		ld	a, (byte_1C0D)
		or	a
		jp	nz, StopAllSound
		ld	ix, byte_1C70	; IX = Track of	FM 1
		ld	b, 6

loc_759:
		ld	a, (byte_1C11)
		or	a
		jr	nz, loc_765
		bit	7, (ix+0)
		jr	z, loc_76B

loc_765:
		ld	c, (ix+0Ah)
		ld	a, 0B4h
		rst	WriteFMMain

loc_76B:
		ld	de, 30h
		add	ix, de
		djnz	loc_759
		ld	ix, byte_1E20	; IX = Special SFX Track 1
		ld	b, 8		; 8 SFX	tracks (special	+ normal)

loc_778:
		bit	7, (ix+0)
		jr	z, loc_78A
		bit	7, (ix+1)
		jr	nz, loc_78A
		ld	c, (ix+0Ah)
		ld	a, 0B4h
		rst	WriteFMMain

loc_78A:
		ld	de, 30h
		add	ix, de
		djnz	loc_778
		ret
; End of function DoPause

; ---------------------------------------------------------------------------

FadeOutMusic:
		ld	a, 28h		; Number of fading steps
		ld	(byte_1C0D), a
		ld	a, 6		; Frames per Step
		ld	(byte_1C0F), a
		ld	(byte_1C0E), a

; =============== S U B	R O U T	I N E =======================================


StopDrumPSG:
		xor	a
		ld	(byte_1C40), a	; stop Drum Track
		ld	(byte_1D60), a	; stop FM6 Track
		ld	(byte_1DF0), a	; stop PSG3 Track
		ld	(byte_1D90), a	; stop PSG1 Track
		ld	(byte_1DC0), a	; stop PSG2 Track
		call	SilencePSG
		jp	ClearSoundID
; End of function StopDrumPSG


; =============== S U B	R O U T	I N E =======================================


DoFading:
		ld	hl, byte_1C0D
		ld	a, (hl)		; load remaining Fading	Steps
		or	a
		ret	z		; reached 0 - return
		call	m, StopDrumPSG	; 80+ -	mute Drum and PSG channels
		res	7, (hl)
		ld	a, (byte_1C0F)	; 1C0F - Timeout Counter
		dec	a
		jr	z, ApplyFading	; reached 0 - apply fading
		ld	(byte_1C0F), a	; else just write back
		ret
; ---------------------------------------------------------------------------

ApplyFading:
		ld	a, (byte_1C0E)
		ld	(byte_1C0F), a	; 1C0F (Counter) = 1C0E	(Initial)
		ld	a, (byte_1C0D)
		dec	a
		ld	(byte_1C0D), a
		jr	z, StopAllSound
		ld	ix, byte_1C40	; 1C40 - Music Track RAM
		ld	b, 6

loc_7DF:
		inc	(ix+6)
		jp	p, loc_7EA
		dec	(ix+6)
		jr	loc_7F9
; ---------------------------------------------------------------------------

loc_7EA:
		bit	7, (ix+0)
		jr	z, loc_7F9
		bit	2, (ix+0)
		jr	nz, loc_7F9
		call	RefreshVolume

loc_7F9:
		ld	de, 30h
		add	ix, de
		djnz	loc_7DF
		ret
; End of function DoFading


; =============== S U B	R O U T	I N E =======================================


StopAllSound:
		ld	hl, byte_1C09
		ld	de, unk_1C0A
		ld	bc, 396h
		ld	(hl), 0
		ldir			; clear	complete sound RAM (music + SFX)
		ld	ix, FMInitBytes
		ld	b, 6		; 6 FM channels

loc_814:
		push	bc
		call	SilenceFMChn
		call	DisableSSGEG
		inc	ix
		inc	ix
		pop	bc
		djnz	loc_814
		ld	b, 7		; dead instruction?
		xor	a
		ld	(byte_1C0D), a	; clear	Fading Step Counter
		call	SilencePSG
; End of function StopAllSound


; =============== S U B	R O U T	I N E =======================================


ResetSpcFM3Mode:
		ld	a, 0Fh
		ld	(byte_1C12), a
		ld	c, a
		ld	a, 27h
		rst	WriteFMI
		jp	ClearSoundID
; End of function ResetSpcFM3Mode


; =============== S U B	R O U T	I N E =======================================


DisableSSGEG:
		ld	a, 90h
		ld	c, 0
		jp	SendAllFMOps
; End of function DisableSSGEG

; ---------------------------------------------------------------------------

SilenceAll:
		call	SilencePSG
		push	bc
		push	af
		ld	b, 3
		ld	a, 0B4h
		ld	c, 0

loc_849:
		push	af
		rst	WriteFMI
		pop	af
		inc	a
		djnz	loc_849
		ld	b, 3
		ld	a, 0B4h

loc_853:
		push	af
		call	WriteFMII
		pop	af
		inc	a
		djnz	loc_853
		ld	c, 0
		ld	b, 7
		ld	a, 28h

loc_861:
		push	af
		rst	WriteFMI
		inc	c
		pop	af
		djnz	loc_861
		pop	af
		pop	bc

; =============== S U B	R O U T	I N E =======================================


SilencePSG:
		push	hl
		push	bc
		ld	hl, PSGMuteVals
		ld	b, 4

loc_870:
		ld	a, (hl)
		ld	(7F11h), a
		inc	hl
		djnz	loc_870
		pop	bc
		pop	hl
		jp	ClearSoundID
; End of function SilencePSG

; ---------------------------------------------------------------------------
PSGMuteVals:	db 9Fh,	0BFh, 0DFh, 0FFh

; =============== S U B	R O U T	I N E =======================================


DoTempo:
		ld	hl, byte_1C13	; 1C13 = Tempo Timeout
		ld	a, (hl)
		or	a
		ret	z		; Tempo	00 = never delayed
		dec	(hl)		; subtract 1
		ret	nz		; reached 00 - continue	and delay all tracks
		ld	a, (byte_1C14)	; load initial Tempo (1C14)
		ld	(hl), a
		ld	hl, byte_1C4B	; 1C40 (DAC Track) + 0B	(Note Timeout)
		ld	de, 30h
		ld	b, 0Ah		; 10 Music Tracks

loc_894:
		inc	(hl)		; delay	by 1 frame
		add	hl, de		; next track
		djnz	loc_894
		ret
; End of function DoTempo


; =============== S U B	R O U T	I N E =======================================


DoSoundQueue:
		ld	a, r
		ld	(byte_1C17), a
		ld	de, unk_1C0A
		call	DoOneSndQueue
		ld	de, unk_1C0B
		call	DoOneSndQueue
		ld	de, unk_1C0C
; End of function DoSoundQueue


; =============== S U B	R O U T	I N E =======================================


DoOneSndQueue:
		ld	a, (de)
		bit	7, a
		ret	z
		sub	81h
		ld	hl, (word_1C02)
		ld	c, 0
		rst	GetListOfs	; get List 0 (Sound Priorities)
		ld	c, a
		ld	b, 0
		add	hl, bc
		bit	7, (hl)
		jr	z, loc_8CF
		ld	a, (de)
		ld	(byte_1C09), a
		xor	a
		ld	hl, unk_1C0A
		ld	(hl), a
		inc	hl
		ld	(hl), a
		inc	hl
		ld	(hl), a
		ret
; ---------------------------------------------------------------------------

loc_8CF:
		ld	a, (byte_1C18)
		cp	(hl)
		jr	z, loc_8D7
		jr	nc, loc_8DF

loc_8D7:
		ld	a, (de)
		ld	(byte_1C09), a
		ld	a, (hl)
		ld	(byte_1C18), a

loc_8DF:
		xor	a
		ld	(de), a
		ret
; End of function DoOneSndQueue


; =============== S U B	R O U T	I N E =======================================


SilenceFMChn:
		call	SetMaxRelRate
		ld	a, 40h
		ld	c, 7Fh
		call	SendAllFMOps
		ld	c, (ix+1)
		jp	FMNoteOff
; End of function SilenceFMChn


; =============== S U B	R O U T	I N E =======================================


SetMaxRelRate:
		ld	a, 80h
		ld	c, 0FFh
; End of function SetMaxRelRate


; =============== S U B	R O U T	I N E =======================================


SendAllFMOps:
		ld	b, 4

loc_8F8:
		push	af
		rst	WriteFMMain
		pop	af
		add	a, 4
		djnz	loc_8F8
		ret
; End of function SendAllFMOps

; ---------------------------------------------------------------------------
PSGFreqs:	dw  356h, 326h,	2F9h, 2CEh, 2A5h, 280h,	25Ch, 23Ah, 21Ah, 1FBh,	1DFh, 1C4h
		dw  1ABh, 193h,	17Dh, 167h, 153h, 140h,	12Eh, 11Dh, 10Dh, 0FEh,	0EFh, 0E2h
		dw  0D6h, 0C9h,	0BEh, 0B4h, 0A9h, 0A0h,	 97h,  8Fh,  87h,  7Fh,	 78h,  71h
		dw   6Bh,  65h,	 5Fh,  5Ah,  55h,  50h,	 4Bh,  47h,  43h,  40h,	 3Ch,  39h
		dw   36h,  33h,	 30h,  2Dh,  2Bh,  28h,	 26h,  24h,  22h,  20h,	 1Fh,  1Dh
		dw   1Bh,  1Ah,	 18h,  17h,  16h,  15h,	 13h,  12h,  11h
FMFreqs:	dw  284h, 2ABh,	2D3h, 2FEh, 32Dh, 35Ch,	38Fh, 3C5h, 3FFh, 43Ch,	47Ch, 4C0h

; =============== S U B	R O U T	I N E =======================================


DrumUpdateTrack:
		call	TrackTimeout
		call	z, DrumUpdate_Proc
		ret
; End of function DrumUpdateTrack


; =============== S U B	R O U T	I N E =======================================


DrumUpdate_Proc:
		ld	e, (ix+3)
		ld	d, (ix+4)

loc_9AF:
		ld	a, (de)
		inc	de
		cp	0E0h
		jp	nc, cfHandler_Drum
		or	a
		jp	m, loc_9BE
		dec	de
		ld	a, (ix+0Dh)

loc_9BE:
		ld	(ix+0Dh), a
		cp	80h
		jp	z, loc_A40
		push	de
		ld	hl, byte_1D60	; BGM Channel FM6 (actually FM3	here)
		bit	2, (hl)
		jr	nz, zloc_A12
		and	0Fh
		jr	z, zloc_A12
		ex	af, af'
		call	DoNoteOff
		ex	af, af'
		ld	de, FMDrumInit
		ex	de, hl
		ldi
		ldi
		ldi
		dec	a
		ld	hl, FMDrumTrkList
		rst	ReadPtrTable
		ld	bc, 6
		ldir
		call	FinishTrkInit
		ld	hl, byte_1D65
		ld	a, (ix+5)
		add	a, (hl)
		ld	(hl), a
		ld	a, (byte_1D68)
		ld	hl, FMDrumInsPtrs
		rst	ReadPtrTable
		ld	a, (byte_1D66)
		ld	e, (ix+6)
		push	de
		add	a, e
		ld	(ix+6),	a
		call	SendFMIns
		pop	de
		ld	(ix+6),	e
		call	ResetSpcFM3Mode

zloc_A12:
		ld	hl, byte_1DF0
		bit	2, (hl)
		jr	nz, loc_A3F
		ld	a, (ix+0Dh)
		and	70h
		jr	z, loc_A3F
		ld	de, PSGDrumInit
		ex	de, hl
		ldi
		ldi
		ldi
		srl	a
		srl	a
		srl	a
		srl	a
		dec	a
		ld	hl, PSGDrumTrkList
		rst	ReadPtrTable
		ld	bc, 6
		ldir
		call	FinishTrkInit

loc_A3F:
		pop	de

loc_A40:
		ld	a, (de)
		inc	de
		or	a
		jp	p, SetDuration
		dec	de
		ld	a, (ix+0Ch)
		ld	(ix+0Bh), a
		jp	loc_27C
; ---------------------------------------------------------------------------
FMDrumInit:	db  80h,   2,	1
PSGDrumInit:	db  80h,0C0h,	1
; ---------------------------------------------------------------------------

cfHandler_Drum:
		ld	hl, cfReturn_Drum
		jp	loc_B9B
; ---------------------------------------------------------------------------

cfReturn_Drum:
		inc	de
		jp	loc_9AF
; ---------------------------------------------------------------------------
PSGDrumTrkList:	dw PSGDrum90
		dw PSGDrumA0
PSGDrum90:
		DrumHeader byte_A6A, 0, 4, 0, 1
byte_A6A:	db 0F3h,0E7h,0C2h, 08h,0F2h
PSGDrumA0:
		DrumHeader byte_A75, 0, 6, 0, 2
byte_A75:	db 0F3h,0E7h,0C5h, 08h,0F2h
FMDrumTrkList:
		dw FMDrum81, FMDrum82, FMDrum83, FMDrum84, FMDrum85, FMDrum86
		dw FMDrum87, FMDrum88, FMDrum89, FMDrum8A
FMDrumInsPtrs:
		dw FMDrumIns00,	FMDrumIns01, FMDrumIns02, FMDrumIns03
		dw FMDrumIns04,	FMDrumIns05
FMDrum81:
		DrumHeader byte_AA0, 0, 0Eh, 81h, 0
byte_AA0:	db 0B9h, 10h,0F2h
FMDrumIns00:
		db  3Eh, 60h, 30h, 30h,	30h, 19h, 1Fh, 1Fh, 1Fh, 15h, 11h
		db  11h, 0Ch, 10h, 0Ah,	06h, 09h, 4Fh, 5Fh,0AFh, 8Fh, 00h
		db  82h, 83h, 80h
FMDrum82:
		DrumHeader byte_AC2, 0, 0Ch, 81h, 0
byte_AC2:	db 0E0h, 80h,0B6h, 0Ah,0F2h
FMDrum83:
		DrumHeader byte_ACD, 0, 0Ch, 81h, 0
byte_ACD:	db 0B3h, 0Ah,0F2h
FMDrum84:
		DrumHeader byte_AD6, 0, 0Ch, 81h, 0
byte_AD6:	db 0E0h, 40h,0B0h, 0Ah,0F2h
; Sega Channel BIOS (J):
;byte_AD6:	db 0E0h, 40h,0ADh, 0Ah,0F2h
FMDrum87:
		DrumHeader byte_AE1, 0, 0Ch, 81h, 0
byte_AE1:	db 0B2h, 0Ah,0F2h
FMDrum85:
		DrumHeader byte_AEA, 0, 3, 81h, 1
byte_AEA:	db  89h, 08h,0F2h
FMDrumIns01:
		db  72h, 33h, 30h, 32h,	31h, 1Eh, 1Bh, 1Ch, 15h, 16h, 12h
		db  17h, 10h, 10h, 18h,	1Eh, 14h, 4Fh, 5Fh, 4Fh, 4Fh, 08h
		db  00h, 10h, 80h
; Sega Channel BIOS (J):
;byte_AEA:	db  89h, 05h,0F2h
;FMDrumIns01:
;		db  72h, 31h, 33h, 30h,	31h, 1Eh, 1Bh, 1Ch, 15h, 16h, 12h
;		db  17h, 10h, 10h, 18h,	1Eh, 14h, 4Fh, 5Fh, 4Fh, 4Fh, 08h
;		db  00h, 10h, 80h
FMDrum86:
		DrumHeader byte_B0C, 0, 6, 81h, 2
byte_B0C:	db 0B0h, 16h,0F2h
FMDrumIns02:
		db  72h, 9Eh, 5Bh, 42h,	22h, 96h, 96h, 9Eh, 96h, 16h, 18h
		db  16h, 18h, 10h, 17h,	11h, 18h, 4Fh, 5Fh, 4Fh, 4Fh, 00h
		db  00h, 10h, 80h
FMDrum88:
		DrumHeader byte_B2E, 0, 0Eh, 0, 3
; Sega Channel BIOS (J):
;		DrumHeader byte_B2E, 0, 8, 0, 3
byte_B2E:	db 0B4h, 10h,0F2h
FMDrumIns03:
		db  3Ch, 0Fh, 00h, 00h,	00h, 1Fh, 1Ah, 18h, 1Ch, 17h, 11h
		db  1Ah, 0Eh, 00h, 0Fh,	14h, 10h, 1Fh,0ECh,0FFh,0FFh, 07h
		db  80h, 16h, 80h
FMDrum89:
		DrumHeader byte_B50, 0F7h, 0Ah, 0, 4
byte_B50:	db 0FEh, 03h, 00h, 00h,	00h, 95h, 20h,0F2h

FMDrumIns04:
		db  3Ch, 0Ah, 50h, 70h,	00h, 1Fh, 17h, 19h, 1Dh, 1Dh, 15h
		db  1Ah, 17h, 06h, 18h,	07h, 19h, 0Fh, 5Fh, 6Fh, 1Fh, 0Ch
		db  95h, 00h, 8Eh
FMDrum8A:
		DrumHeader byte_B77, 0, 7, 0, 7
byte_B77:	db 0FEh, 00h, 03h, 00h,	03h,0D1h, 08h,0F2h

FMDrumIns05:
		db  3Dh, 00h, 0Fh, 0Fh,	0Fh, 1Fh, 9Fh, 9Fh, 9Fh, 1Fh, 1Fh
		db  1Fh, 1Fh, 00h, 0Eh,	10h, 0Fh, 0Fh, 4Fh, 4Fh, 4Fh, 00h
		db  90h, 90h, 85h
; ---------------------------------------------------------------------------

cfHandler:
		ld	hl, cfReturn

loc_B9B:
		push	hl
		sub	0E0h
		ld	hl, cfPtrTable
		rst	ReadPtrTable
		ld	a, (de)
		jp	(hl)
; End of function DrumUpdate_Proc

; ---------------------------------------------------------------------------

cfReturn:
		inc	de
		jp	loc_1E4
; ---------------------------------------------------------------------------

cfMetaCoordFlag:
		ld	hl, cfMetaPtrTable
		rst	ReadPtrTable
		inc	de
		ld	a, (de)
		jp	(hl)
; ---------------------------------------------------------------------------
cfPtrTable:	dw cfE0_Pan
		dw cfE1_Detune
		dw cfE2_SetComm
		dw cfE3_SilenceTrk
		dw cfE4_PanAnim
		dw cfE5_ChgPFMVol
		dw cfE6_ChgFMVol
		dw cfE7_Hold
		dw cfE8_NoteStop
		dw cfE9_SetLFO
		dw cfEA_SetUpdRate
		dw cfEB_ChgUpdRate
		dw cfEC_ChgPSGVol
		dw cfED_FMChnWrite
		dw cfEE_FM1Write
		dw cfEF_SetIns
		dw cfF0_ModSetup
		dw cfF1_ModTypePFM
		dw cfF2_StopTrk
		dw cfF3_PSGNoise
		dw cfF4_ModType
		dw cfF5_SetPSGIns
		dw cfF6_GoTo
		dw cfF7_Loop
		dw cfF8_GoSub
		dw cfF9_Return
		dw cfFA_TickMult
		dw cfFB_ChgTransp
		dw cfFC_PitchSlide
		dw cfFD_RawFrqMode
		dw cfFE_SpcFM3Mode
		dw cfMetaCoordFlag
cfMetaPtrTable:	dw cf00_TimingMode
		dw cf01_SetTempo
		dw cf02_PlaySnd
		dw cf03_MusPause
		dw cf04_CopyMem
		dw cf05_TickMulAll
		dw cf06_SSGEG
		dw cf07_FMVolEnv
; ---------------------------------------------------------------------------

cf06_SSGEG:
		ld	(ix+18h), 80h
		ld	(ix+19h), e
		ld	(ix+1Ah), d

; =============== S U B	R O U T	I N E =======================================


SendSSGEG:
		ld	hl, SSGEG_Ops
		ld	b, 4

loc_C0E:
		ld	a, (de)
		inc	de
		ld	c, a
		ld	a, (hl)
		inc	hl
		rst	WriteFMMain
		djnz	loc_C0E
		dec	de
		ret
; End of function SendSSGEG

; ---------------------------------------------------------------------------

cf05_TickMulAll:
		exx
		ld	b, 0Ah
		ld	de, 30h
		ld	hl, byte_1C42

loc_C21:
		ld	(hl), a
		add	hl, de
		djnz	loc_C21
		exx
		ret
; ---------------------------------------------------------------------------

cf00_TimingMode:
		ld	(byte_1C07), a	; set 1C07, the	Timing Mode
		ret
; ---------------------------------------------------------------------------

cfEA_SetUpdRate:
		ld	hl, word_1C04	; 1C04/1C05 = YM2612 Timer A value (Music Tempo)
		ex	de, hl		; (sound driver	update rate)
		ldi
		ldi
		ldi			; 1C06 = YM2612	Timer B	value (SFX Tempo)
		ex	de, hl
		dec	de
		ret
; ---------------------------------------------------------------------------

cfEB_ChgUpdRate:
		ex	de, hl
		ld	c, (hl)
		inc	hl
		ld	b, (hl)
		inc	hl
		ex	de, hl
		ld	hl, (word_1C04)
		add	hl, bc		; add 2-byte value to 1C04/1C05	Timer A
		ld	(word_1C04), hl
		ld	a, (de)
		ld	hl, byte_1C06
		add	a, (hl)		; add 1-byte value to 1C06 Timer B
		ld	(hl), a
		ret
; ---------------------------------------------------------------------------

cf02_PlaySnd:
		push	ix
		call	PlaySnd_JumpIn	; play Sound ID	from parameter A
		pop	ix
		ret
; ---------------------------------------------------------------------------

cf03_MusPause:
		ld	(byte_1C11), a	; 1C11 - Music is paused
		or	a
		jr	z, loc_C77	; 00 - unpause,	so jump
		push	ix		; 01-FF	- pause	music
		push	de
		ld	ix, byte_1C40	; 1C40 - Music Tracks
		ld	b, 0Ah		; 10 music tracks
		ld	de, 30h

loc_C66:
		res	7, (ix+0)	; disable channel
		call	SendNoteOff	; turn FM note off
		add	ix, de
		djnz	loc_C66
		pop	de
		pop	ix
		jp	SilencePSG
; ---------------------------------------------------------------------------

loc_C77:
		push	ix
		push	de
		ld	ix, byte_1C40	; 1C40 - Music Tracks
		ld	b, 0Ah		; 10 music tracks
		ld	de, 30h

loc_C83:
		set	7, (ix+0)	; re-enable channel
		add	ix, de
		djnz	loc_C83
		pop	de
		pop	ix
		ret
; ---------------------------------------------------------------------------

cf04_CopyMem:				; DATA XREF: RAM:cfMetaPtrTableo
		ex	de, hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		inc	hl
		ld	c, (hl)
		ld	b, 0
		inc	hl
		ex	de, hl
		ldir
		dec	de
		ret
; ---------------------------------------------------------------------------

cfE1_Detune:				; DATA XREF: RAM:cfPtrTableo
		ld	(ix+10h), a
		ret
; ---------------------------------------------------------------------------

cf07_FMVolEnv:				; DATA XREF: RAM:cfMetaPtrTableo
		ld	(ix+18h), a
		inc	de
		ld	a, (de)
		ld	(ix+19h), a
		ret
; ---------------------------------------------------------------------------

cf01_SetTempo:				; DATA XREF: RAM:cfMetaPtrTableo
		ld	hl, byte_1C14	; 1C14 - Tempo Value (frame-based timing)
		add	a, (hl)
		ld	(hl), a		; set 1C14 (Initial Tempo)
		dec	hl
		ld	(hl), a		; set 1C13 (Tempo Timeout)
		ret
; ---------------------------------------------------------------------------

cfE2_SetComm:				; DATA XREF: RAM:cfPtrTableo
		ld	(byte_1C16), a
		ret
; ---------------------------------------------------------------------------

cfEC_ChgPSGVol:				; DATA XREF: RAM:cfPtrTableo
		bit	7, (ix+1)
		ret	z
		res	4, (ix+0)
		dec	(ix+17h)
		add	a, (ix+6)
		ld	(ix+6),	a
		ret
; ---------------------------------------------------------------------------

cfED_FMChnWrite:			; DATA XREF: RAM:cfPtrTableo
		call	ReadFMCommand
		rst	WriteFMMain
		ret
; ---------------------------------------------------------------------------

cfEE_FM1Write:				; DATA XREF: RAM:cfPtrTableo
		call	ReadFMCommand
		rst	WriteFMI
		ret

; =============== S U B	R O U T	I N E =======================================


ReadFMCommand:				; CODE XREF: RAM:cfED_FMChnWritep
					; RAM:cfEE_FM1Writep
		ex	de, hl
		ld	a, (hl)
		inc	hl
		ld	c, (hl)
		ex	de, hl
		ret
; End of function ReadFMCommand

; ---------------------------------------------------------------------------

cfF0_ModSetup:				; DATA XREF: RAM:cfPtrTableo
		ld	(ix+20h), e
		ld	(ix+21h), d
		ld	(ix+7),	80h
		inc	de
		inc	de
		inc	de
		ret
; ---------------------------------------------------------------------------

cfE3_SilenceTrk:			; DATA XREF: RAM:cfPtrTableo
		call	SilenceFMChn
		jp	cfF2_StopTrk
; ---------------------------------------------------------------------------

cfE8_NoteStop:				; DATA XREF: RAM:cfPtrTableo
		call	TickMultiplier
		ld	(ix+1Eh), a
		ld	(ix+1Fh), a
		ret
; ---------------------------------------------------------------------------

cfE4_PanAnim:				; DATA XREF: RAM:cfPtrTableo
		push	ix
		pop	hl
		ld	bc, 11h
		add	hl, bc
		ex	de, hl
		ld	bc, 5
		ldir
		ld	a, 1
		ld	(de), a
		ex	de, hl
		dec	de
		ret
; ---------------------------------------------------------------------------

cfE7_Hold:				; DATA XREF: RAM:cfPtrTableo
		set	1, (ix+0)
		dec	de
		ret
; ---------------------------------------------------------------------------

cfFE_SpcFM3Mode:			; DATA XREF: RAM:cfPtrTableo
		ld	a, (ix+1)
		cp	2
		jr	nz, SpcFM3_skip
		set	0, (ix+0)
		exx
		call	GetFM3FreqPtr
		ld	b, 4

loc_D21:				; CODE XREF: RAM:0D33j
		push	bc
		exx
		ld	a, (de)
		inc	de
		exx
		ld	hl, FM3_FreqVals
		add	a, a
		ld	c, a
		ld	b, 0
		add	hl, bc
		ldi
		ldi
		pop	bc
		djnz	loc_D21
		exx
		dec	de
		ld	a, 4Fh		; enable Special FM3 Mode

; =============== S U B	R O U T	I N E =======================================


SendFM3SpcMode:				; CODE XREF: PlaySoundID:loc_E9Dp
		ld	(byte_1C12), a
		ld	c, a
		ld	a, 27h
		rst	WriteFMI
		ret
; End of function SendFM3SpcMode

; ---------------------------------------------------------------------------

SpcFM3_skip:				; CODE XREF: RAM:0D15j
		inc	de
		inc	de
		inc	de
		ret
; ---------------------------------------------------------------------------
FM3_FreqVals:	dw 0, 132h, 18Ah, 1E4h	; DATA XREF: RAM:0D26o
					; Note:	The 3rd	frequency is different from other SMPS drivers.
					;	(18Ah instead of 18Eh)
; ---------------------------------------------------------------------------

cfEF_SetIns:				; DATA XREF: RAM:cfPtrTableo
		bit	7, (ix+1)
		jr	nz, loc_D84
		call	SetMaxRelRate
		ld	a, (de)
		ld	(ix+8),	a
		or	a
		jp	p, loc_D7A
		inc	de
		ld	a, (de)
		ld	(ix+0Fh), a

; =============== S U B	R O U T	I N E =======================================


SetInsFromSong:				; CODE XREF: PlaySoundID+99Cp
		push	de
		ld	a, (ix+0Fh)
		sub	81h
		ld	c, 4
		call	GetListOfsROM	; get List 2 (Music Pointers)
		rst	ReadPtrFromHL
		ld	a, (ix+8)
		and	7Fh
		ld	b, a
		call	JumpToInsData
		jr	loc_D7F
; ---------------------------------------------------------------------------

loc_D7A:				; CODE XREF: RAM:0D5Bj
		push	de
		ld	b, a
		call	GetFMInsPtr

loc_D7F:				; CODE XREF: SetInsFromSong+15j
		call	SendFMIns
		pop	de
		ret
; End of function SetInsFromSong

; ---------------------------------------------------------------------------

loc_D84:				; CODE XREF: RAM:0D51j
		ld	a, (de)
		or	a
		ret	p
		inc	de
		ret

; =============== S U B	R O U T	I N E =======================================


cfE0_Pan:				; CODE XREF: DoPanAnimation+3Dp
					; DATA XREF: RAM:cfPtrTableo
		ld	c, 3Fh

loc_D8B:				; CODE XREF: RAM:0DA1j
		ld	a, (ix+0Ah)
		and	c
		ex	de, hl
		or	(hl)
		ld	(ix+0Ah), a
		ld	c, a
		ld	a, 0B4h
		rst	WriteFMMain
		ex	de, hl
		ret
; End of function cfE0_Pan

; ---------------------------------------------------------------------------

cfE9_SetLFO:				; DATA XREF: RAM:cfPtrTableo
		ld	c, a
		ld	a, 22h
		rst	WriteFMI
		inc	de
		ld	c, 0C0h
		jr	loc_D8B

; =============== S U B	R O U T	I N E =======================================


RefreshVolume:				; CODE XREF: SendFMIns+1Cj
					; DoFading+41p	...
		exx
		ld	de, Volume_Ops
		ld	l, (ix+1Ch)
		ld	h, (ix+1Dh)
		ld	b, 4

loc_DAF:				; CODE XREF: RefreshVolume+1Bj
		ld	a, (hl)
		or	a
		jp	p, loc_DB7
		add	a, (ix+6)

loc_DB7:				; CODE XREF: RefreshVolume+Ej
		and	7Fh
		ld	c, a
		ld	a, (de)
		rst	WriteFMMain
		inc	de
		inc	hl
		djnz	loc_DAF
		exx
		ret
; End of function RefreshVolume

; ---------------------------------------------------------------------------

cfE5_ChgPFMVol:				; DATA XREF: RAM:cfPtrTableo
		inc	de
		add	a, (ix+6)
		ld	(ix+6),	a
		ld	a, (de)

cfE6_ChgFMVol:				; DATA XREF: RAM:cfPtrTableo
		bit	7, (ix+1)
		ret	nz
		add	a, (ix+6)
		ld	(ix+6),	a
		jr	RefreshVolume
; ---------------------------------------------------------------------------

cfFB_ChgTransp:				; DATA XREF: RAM:cfPtrTableo
		add	a, (ix+5)
		ld	(ix+5),	a
		ret
; ---------------------------------------------------------------------------

cfFA_TickMult:				; DATA XREF: RAM:cfPtrTableo
		ld	(ix+2),	a
		ret
; ---------------------------------------------------------------------------

cfF3_PSGNoise:				; DATA XREF: RAM:cfPtrTableo
		bit	2, (ix+1)
		ret	nz
		ld	a, 0DFh
		ld	(7F11h), a
		ld	a, (de)
		ld	(ix+1Ah), a
		set	0, (ix+0)
		or	a
		jr	nz, loc_DFD
		res	0, (ix+0)
		ld	a, 0FFh

loc_DFD:				; CODE XREF: RAM:0DF5j
		ld	(7F11h), a
		ret
; ---------------------------------------------------------------------------

cfF5_SetPSGIns:				; DATA XREF: RAM:cfPtrTableo
		bit	7, (ix+1)
		ret	z
		ld	(ix+8),	a
		ret
; ---------------------------------------------------------------------------

cfF1_ModTypePFM:			; DATA XREF: RAM:cfPtrTableo
		inc	de
		bit	7, (ix+1)
		jr	nz, cfF4_ModType
		ld	a, (de)

cfF4_ModType:				; CODE XREF: RAM:0E0Fj
					; DATA XREF: RAM:cfPtrTableo
		ld	(ix+7),	a
		ret
; ---------------------------------------------------------------------------

cfF6_GoTo:				; CODE XREF: RAM:0F19j
					; DATA XREF: RAM:cfPtrTableo
		ex	de, hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		dec	de
		ret
; ---------------------------------------------------------------------------

cfFC_PitchSlide:			; DATA XREF: RAM:cfPtrTableo
		cp	1
		jr	nz, loc_E25
		set	5, (ix+0)
		ret
; ---------------------------------------------------------------------------

loc_E25:				; CODE XREF: RAM:0E1Ej
		res	1, (ix+0)
		res	5, (ix+0)
		xor	a
		ld	(ix+10h), a
		ret
; ---------------------------------------------------------------------------

cfFD_RawFrqMode:			; DATA XREF: RAM:cfPtrTableo
		cp	1
		jr	nz, loc_E3B
		set	3, (ix+0)
		ret
; ---------------------------------------------------------------------------

loc_E3B:				; CODE XREF: RAM:0E34j
		res	3, (ix+0)
		ret
; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR PlaySoundID

cfF2_StopTrk:				; CODE XREF: PlaySoundID+49j RAM:0CEAj
					; DATA XREF: ...
		res	7, (ix+0)
		ld	a, 1Fh
		ld	(byte_1C15), a
		call	DoNoteOff
		ld	c, (ix+1)
		push	ix
		call	GetSFXChnPtrs
		ld	a, (byte_1C19)
		or	a
		jr	z, loc_EC3
		xor	a
		ld	(byte_1C18), a
		bit	7, (iy+0)
		jr	z, loc_E76
		ld	a, (ix+1)
		cp	(iy+1)
		jr	nz, loc_E76
		push	iy
		ld	l, (iy+2Ah)
		ld	h, (iy+2Bh)
		jr	loc_E7A
; ---------------------------------------------------------------------------

loc_E76:				; CODE XREF: PlaySoundID+957j
					; PlaySoundID+95Fj
		push	hl
		ld	hl, (word_1C37)

loc_E7A:				; CODE XREF: PlaySoundID+969j
		pop	ix
		res	2, (ix+0)
		bit	7, (ix+1)
		jr	nz, loc_EC8
		bit	7, (ix+0)
		jr	z, loc_EC3
		ld	a, 2
		cp	(ix+1)
		jr	nz, loc_EA0
		ld	a, 4Fh
		bit	0, (ix+0)
		jr	nz, loc_E9D
		and	0Fh

loc_E9D:				; CODE XREF: PlaySoundID+98Ej
		call	SendFM3SpcMode

loc_EA0:				; CODE XREF: PlaySoundID+986j
		ld	a, (ix+8)
		or	a
		jp	p, loc_EAC
		call	SetInsFromSong
		jr	zloc_EC0
; ---------------------------------------------------------------------------

loc_EAC:				; CODE XREF: PlaySoundID+999j
		ld	b, a
		call	JumpToInsData
		call	SendFMIns
		ld	a, (ix+18h)
		or	a
		jp	p, loc_EC3
		ld	e, (ix+19h)
		ld	d, (ix+1Ah)

zloc_EC0:				; CODE XREF: PlaySoundID+99Fj
		call	SendSSGEG

loc_EC3:				; CODE XREF: PlaySoundID+94Dj
					; PlaySoundID+97Fj ...
		pop	ix
		pop	hl
		pop	hl
		ret
; ---------------------------------------------------------------------------

loc_EC8:				; CODE XREF: PlaySoundID+979j
		bit	0, (ix+0)
		jr	z, loc_EC3
		ld	a, (ix+1Ah)
		or	a
		jp	p, loc_ED8
		ld	(7F11h), a

loc_ED8:				; CODE XREF: PlaySoundID+9C7j
		jr	loc_EC3
; END OF FUNCTION CHUNK	FOR PlaySoundID
; ---------------------------------------------------------------------------

cfF8_GoSub:				; DATA XREF: RAM:cfPtrTableo
		ld	c, a
		inc	de
		ld	a, (de)
		ld	b, a
		push	bc
		push	ix
		pop	hl
		dec	(ix+9)
		ld	c, (ix+9)
		dec	(ix+9)
		ld	b, 0
		add	hl, bc
		ld	(hl), d
		dec	hl
		ld	(hl), e
		pop	de
		dec	de
		ret
; ---------------------------------------------------------------------------

cfF9_Return:				; DATA XREF: RAM:cfPtrTableo
		push	ix
		pop	hl
		ld	c, (ix+9)
		ld	b, 0
		add	hl, bc
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		inc	(ix+9)
		inc	(ix+9)
		ret
; ---------------------------------------------------------------------------

cfF7_Loop:				; DATA XREF: RAM:cfPtrTableo
		inc	de
		add	a, 28h
		ld	c, a
		ld	b, 0
		push	ix
		pop	hl
		add	hl, bc
		ld	a, (hl)
		or	a
		jr	nz, loc_F17
		ld	a, (de)
		ld	(hl), a

loc_F17:				; CODE XREF: RAM:0F13j
		inc	de
		dec	(hl)
		jp	nz, cfF6_GoTo
		inc	de
		ret
; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR UpdateTrack

UpdatePSGTrk:				; CODE XREF: UpdateTrack+4j
		call	TrackTimeout
		jr	nz, loc_F30
		call	TrkUpdate_Proc
		bit	4, (ix+0)
		ret	nz
		call	PrepareModulat
		jr	loc_F3C
; ---------------------------------------------------------------------------

loc_F30:				; CODE XREF: UpdateTrack+DE8j
		ld	a, (ix+1Eh)
		or	a
		jr	z, loc_F3C
		dec	(ix+1Eh)
		jp	z, SetRest

loc_F3C:				; CODE XREF: UpdateTrack+DF5j
					; UpdateTrack+DFBj
		call	DoPitchSlide
		call	DoModulation
		bit	2, (ix+0)
		ret	nz
		ld	c, (ix+1)
		ld	a, l
		and	0Fh
		or	c
		ld	(7F11h), a
		ld	a, l
		and	0F0h
		or	h
		rrca
		rrca
		rrca
		rrca
		ld	(7F11h), a
		ld	a, (ix+8)
		or	a
		ld	c, 0
		jr	z, zloc_F70
		dec	a
		ld	c, 0Ah
		ld	b, 80h
		call	GetListOfsAB	; get List 5 (PSG envelopes)
		call	DoPSGVolEnv
		ld	c, a

zloc_F70:				; CODE XREF: UpdateTrack+E29j
		bit	4, (ix+0)
		ret	nz
		ld	a, (ix+6)
		add	a, c
		bit	4, a
		jr	z, loc_F7F
		ld	a, 0Fh

loc_F7F:				; CODE XREF: UpdateTrack+E42j
		or	(ix+1)
		add	a, 10h
		bit	0, (ix+0)
		jr	nz, loc_F8E
		ld	(7F11h), a
		ret
; ---------------------------------------------------------------------------

loc_F8E:				; CODE XREF: UpdateTrack+E4Fj
		add	a, 20h
		ld	(7F11h), a
		ret
; END OF FUNCTION CHUNK	FOR UpdateTrack
; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR DoPSGVolEnv

loc_F94:				; CODE XREF: DoPSGVolEnv+1Aj
					; DoPSGVolEnv+25j
		ld	(ix+17h), a
; END OF FUNCTION CHUNK	FOR DoPSGVolEnv

; =============== S U B	R O U T	I N E =======================================


DoPSGVolEnv:				; CODE XREF: DoFMVolEnv+Ap
					; UpdateTrack+E33p

; FUNCTION CHUNK AT 0F94 SIZE 00000003 BYTES

		push	hl
		ld	c, (ix+17h)
		call	GetEnvData	; BC = HL (base) + BC (index), A = (BC)
		pop	hl
		bit	7, a
		jr	z, VolEnv_Next
		cp	83h
		jr	z, VolEnv_Off	; 83 - stop the	tone
		cp	81h
		jr	z, VolEnv_Hold	; 81 - hold the	envelope at current level
		cp	80h
		jr	z, VolEnv_Reset	; 80 - loop back to beginning
		inc	bc
		ld	a, (bc)
		jr	loc_F94
; ---------------------------------------------------------------------------

VolEnv_Off:				; CODE XREF: DoPSGVolEnv+Ej
		set	4, (ix+0)
		pop	hl
		jp	SetRest
; ---------------------------------------------------------------------------

VolEnv_Reset:				; CODE XREF: DoPSGVolEnv+16j
		xor	a
		jr	loc_F94
; ---------------------------------------------------------------------------

VolEnv_Hold:				; CODE XREF: DoPSGVolEnv+12j
		pop	hl
		set	4, (ix+0)
		ret
; ---------------------------------------------------------------------------

VolEnv_Next:				; CODE XREF: DoPSGVolEnv+Aj
		inc	(ix+17h)
		ret
; End of function DoPSGVolEnv


; =============== S U B	R O U T	I N E =======================================


SetRest:				; CODE XREF: TrkUpdate_Proc+2Dp
					; UpdateTrack+E00j ...
		set	4, (ix+0)
		bit	2, (ix+0)
		ret	nz
; End of function SetRest


; =============== S U B	R O U T	I N E =======================================


SilencePSGChn:				; CODE XREF: GetSFXChnPtrs+Bp
		ld	a, 1Fh
		add	a, (ix+1)
		or	a
		ret	p
		ld	(7F11h), a
		bit	0, (ix+0)
		ret	z
		ld	a, 0FFh
		ld	(7F11h), a
		ret
; End of function SilencePSGChn

		restore
		dephase