; ===========================================================================
; Created by Flamewing, based on S1SMPS2ASM version 1.1 by Marc Gordon (AKA Cinossu)
; ===========================================================================
; Permission to use, copy, modify, and/or distribute this software for any
; purpose with or without fee is hereby granted.
;
; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
; WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
; MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
; ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
; ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
; OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
; ===========================================================================

; PSG conversion to S3/S&K/S3D drivers require a tone shift of 12 semi-tones.
psgdelta	EQU 12
; ---------------------------------------------------------------------------
; Standard Octave Pitch Equates
	enumconf	0Ch
	enum		smpsPitch10lo=88h,smpsPitch09lo,smpsPitch08lo,smpsPitch07lo,smpsPitch06lo
	nextenum	smpsPitch05lo,smpsPitch04lo,smpsPitch03lo,smpsPitch02lo,smpsPitch01lo
	enum		smpsPitch00=00h,smpsPitch01hi,smpsPitch02hi,smpsPitch03hi,smpsPitch04hi
	nextenum	smpsPitch05hi,smpsPitch06hi,smpsPitch07hi,smpsPitch08hi,smpsPitch09hi
	nextenum	smpsPitch10hi
	enumconf	1
; ---------------------------------------------------------------------------
; Note Equates
	enum		nRst=80h
	nextenum	nC0,nCs0,nDb0=nCs0,nD0,nDs0,nEb0=nDs0,nE0,nFb0=nE0,nEs0,nF0=nEs0
	nextenum	nFs0,nGb0=nFs0,nG0,nGs0,nAb0=nGs0,nA0,nAs0,nBb0=nAs0,nB0,nCb1=nB0,nBs0
	nextenum	nC1=nBs0,nCs1,nDb1=nCs1,nD1,nDs1,nEb1=nDs1,nE1,nFb1=nE1,nEs1,nF1=nEs1
	nextenum	nFs1,nGb1=nFs1,nG1,nGs1,nAb1=nGs1,nA1,nAs1,nBb1=nAs1,nB1,nCb2=nB1,nBs1
	nextenum	nC2=nBs1,nCs2,nDb2=nCs2,nD2,nDs2,nEb2=nDs2,nE2,nFb2=nE2,nEs2,nF2=nEs2
	nextenum	nFs2,nGb2=nFs2,nG2,nGs2,nAb2=nGs2,nA2,nAs2,nBb2=nAs2,nB2,nCb3=nB2,nBs2
	nextenum	nC3=nBs2,nCs3,nDb3=nCs3,nD3,nDs3,nEb3=nDs3,nE3,nFb3=nE3,nEs3,nF3=nEs3
	nextenum	nFs3,nGb3=nFs3,nG3,nGs3,nAb3=nGs3,nA3,nAs3,nBb3=nAs3,nB3,nCb4=nB3,nBs3
	nextenum	nC4=nBs3,nCs4,nDb4=nCs4,nD4,nDs4,nEb4=nDs4,nE4,nFb4=nE4,nEs4,nF4=nEs4
	nextenum	nFs4,nGb4=nFs4,nG4,nGs4,nAb4=nGs4,nA4,nAs4,nBb4=nAs4,nB4,nCb5=nB4,nBs4
	nextenum	nC5=nBs4,nCs5,nDb5=nCs5,nD5,nDs5,nEb5=nDs5,nE5,nFb5=nE5,nEs5,nF5=nEs5
	nextenum	nFs5,nGb5=nFs5,nG5,nGs5,nAb5=nGs5,nA5,nAs5,nBb5=nAs5,nB5,nCb6=nB5,nBs5
	nextenum	nC6=nBs5,nCs6,nDb6=nCs6,nD6,nDs6,nEb6=nDs6,nE6,nFb6=nE6,nEs6,nF6=nEs6
	nextenum	nFs6,nGb6=nFs6,nG6,nGs6,nAb6=nGs6,nA6,nAs6,nBb6=nAs6,nB6,nCb7=nB6,nBs6
	nextenum	nC7=nBs6,nCs7,nDb7=nCs7,nD7,nDs7,nEb7=nDs7,nE7,nFb7=nE7,nEs7,nF7=nEs7
	nextenum	nFs7,nGb7=nFs7,nG7,nGs7,nAb7=nGs7,nA7,nAs7,nBb7=nAs7
; SMPS2ASM uses nMaxPSG for songs from S1/S2 drivers.
; nMaxPSG1 and nMaxPSG2 are used only for songs from S3/S&K/S3D drivers.
; The use of psgdelta is intended to undo the effects of PSGPitchConvert
; and ensure that the ending note is indeed the maximum PSG frequency.
nMaxPSG				EQU nA5
nMaxPSG1			EQU nA5+psgdelta
nMaxPSG2			EQU nA5+psgdelta
; ---------------------------------------------------------------------------
; PSG volume envelope equates
	enum		fTone_01=01h,fTone_02,fTone_03,fTone_04,fTone_05,fTone_06
	nextenum	fTone_07,fTone_08,fTone_09
; ---------------------------------------------------------------------------
; DAC Equates
	enum		dKick=81h,dSnare,dTimpani
	enum		dHiTimpani=88h,dMidTimpani,dLowTimpani,dVLowTimpani
; ---------------------------------------------------------------------------
; Channel IDs for SFX
cPSG1				EQU 80h
cPSG2				EQU 0A0h
cPSG3				EQU 0C0h
cNoise				EQU 0E0h	; Not for use in S3/S&K/S3D
cFM3				EQU 02h
cFM4				EQU 04h
cFM5				EQU 05h
cFM6				EQU 06h	; Only in S3/S&K/S3D, overrides DAC
; ---------------------------------------------------------------------------
; Conversion macros and functions

conv0To256  function n,((n==0)<<8)|n
s2TempotoS1 function n,(((768-n)>>1)/(256-n))&0FFh
s2TempotoS3 function n,(100h-((n==0)|n))&0FFh
s1TempotoS2 function n,((((conv0To256(n)-1)<<8)+(conv0To256(n)>>1))/conv0To256(n))&0FFh
s1TempotoS3 function n,s2TempotoS3(s1TempotoS2(n))
s3TempotoS1 function n,s2TempotoS1(s2TempotoS3(n))
s3TempotoS2 function n,s2TempotoS3(n)

convertMainTempoMod macro mod
		db	mod
	endm

; PSG conversion to S3/S&K/S3D drivers require a tone shift of 12 semi-tones.
PSGPitchConvert macro pitch
		db	pitch
	endm

CheckedChannelPointer macro loc
		dw	loc
	endm
; ---------------------------------------------------------------------------
; Header Macros
smpsHeaderStartSong macro ver, sourcesmps2asmver

SourceDriver set ver

	if ("sourcesmps2asmver"<>"")
		set SourceSMPS2ASM,sourcesmps2asmver
	else
		set SourceSMPS2ASM,0
	endif

songStart set *

	if MOMPASS=1
		if SMPS2ASMVer < SourceSMPS2ASM
			message "Song at 0x\{songStart} was made for a newer version of SMPS2ASM (this is version \{SMPS2ASMVer}, but song wants at least version \{SourceSMPS2ASM})."
		endif
	endif

	endm

smpsHeaderVoiceNull macro
	if songStart<>*
		fatal "Missing smpsHeaderStartSong"
	endif
	dw	0000h
	endm

; Header - Set up Voice Location
; Common to music and SFX
smpsHeaderVoice macro loc
	if songStart<>*
		fatal "Missing smpsHeaderStartSong"
	endif
		dw	loc
	endm

; Header - Set up Voice Location as S3's Universal Voice Bank
; Common to music and SFX
smpsHeaderVoiceUVB macro
	if songStart<>*
		fatal "Missing smpsHeaderStartSong"
	endif
		fatal "Universal Voice Bank does not exist in Sonic 1 or Sonic 2 drivers"
	endm

; Header macros for music (not for SFX)
; Header - Set up Channel Usage
smpsHeaderChan macro fm,psg
	db	fm,psg
	endm

; Header - Set up Tempo
smpsHeaderTempo macro div,mod
	db	div
	convertMainTempoMod mod
	endm

; Header - Set up DAC Channel
smpsHeaderDAC macro loc,pitch,vol
	CheckedChannelPointer loc
	if ("pitch"<>"")
		db	pitch
		if ("vol"<>"")
			db	vol
		else
			db	00h
		endif
	else
		db	00h
	endif
	endm

; Header - Set up FM Channel
smpsHeaderFM macro loc,pitch,vol
	CheckedChannelPointer loc
	db	pitch,vol
	endm

; Header - Set up PSG Channel
smpsHeaderPSG macro loc,pitch,vol,mod,voice
	CheckedChannelPointer loc
	PSGPitchConvert pitch
	db	vol
	; Frequency envelope
	db	0
	; Volume envelope
	db	voice
	endm

; Header macros for SFX (not for music)
; Header - Set up Tempo
smpsHeaderTempoSFX macro div
	db	div
	endm

; Header - Set up Channel Usage
smpsHeaderChanSFX macro chan
	db	chan
	endm

; Header - Set up FM Channel
smpsHeaderSFXChannel macro chanid,loc,pitch,vol
	if (SonicDriverVer>=3)&&(chanid==cNoise)
		fatal "Using channel ID of cNoise ($E0) in Sonic 3 driver is dangerous. Fix the song so that it turns into a noise channel instead."
	elseif (SonicDriverVer<3)&&(chanid==cFM6)
		fatal "Using channel ID of FM6 ($06) in Sonic 1 or Sonic 2 drivers is unsupported. Change it to another channel."
	endif
	db	80h,chanid
	CheckedChannelPointer loc
	if (chanid&80h)<>0
		PSGPitchConvert pitch
	else
		db	pitch
	endif
	db	vol
	endm
; ---------------------------------------------------------------------------
; Co-ord Flag Macros and Equates
; E0xx - Panning, AMS, FMS
smpsPan macro direction,amsfms
panNone set 00h
panRight set 40h
panLeft set 80h
panCentre set 0C0h
panCenter set 0C0h ; silly Americans :U
	db 0E0h,direction+amsfms
	endm

; E1xx - Set channel detune to val
smpsDetune macro val
	db	0E1h,val
	endm

; E2xx - Useless
smpsNop macro val
	if SonicDriverVer<3
		db	0E2h,val
	endif
	endm

; Return (used after smpsCall)
smpsReturn macro val
	if SonicDriverVer>=3
		db	0F9h
	else
		db	0E3h
	endif
	endm

; Fade in previous song (ie. 1-Up)
smpsFade macro val
	if SonicDriverVer>=3
		db	0E2h
		if ("val"<>"")
			db	val
		else
			db	0FFh
		endif
		if SourceDriver<3
			smpsStop
		endif
	elseif (SourceDriver>=3) && ("val"<>"") && ("val"<>"0FFh")
		; This is one of those weird S3+ "fades" that we don't need
	else
		db	0E4h
	endif
	endm

; E5xx - Set channel tempo divider to xx
smpsChanTempoDiv macro val
	if SonicDriverVer>=5
		; New flag unique to Flamewing's modified S&K driver
		db	0FFh,08h,val
	elseif SonicDriverVer==3
		fatal "Coord. Flag to set tempo divider of a single channel does not exist in S3 driver. Use Flamewing's modified S&K sound driver instead."
	else
		db	0E5h,val
	endif
	endm

; E6xx - Alter Volume by xx
smpsAlterVol macro val
	db	0E6h,val
	endm

; E7 - Prevent attack of next note
smpsNoAttack	EQU 0E7h

; E8xx - Set note fill to xx
smpsNoteFill macro val
	if (SonicDriverVer>=5)&&(SourceDriver<3)
		; Unique to Flamewing's modified driver
		db	0FFh,0Ah,val
	else
		if (SonicDriverVer>=3)&&(SourceDriver<3)
			message "Note fill will not work as intended unless you divide the fill value by the tempo divider or complain to Flamewing to add an appropriate coordination flag for it."
		elseif (SonicDriverVer<3)&&(SourceDriver>=3)
			message "Note fill will not work as intended unless you multiply the fill value by the tempo divider or complain to Flamewing to add an appropriate coordination flag for it."
		endif
		db	0E8h,val
	endif
	endm

; Add xx to channel pitch
smpsChangeTransposition macro val
	db	0E9h,val
	endm

; Set music tempo modifier to xx
smpsSetTempoMod macro mod
	db	0EAh
	convertMainTempoMod mod
	endm

; Set music tempo divider to xx
smpsSetTempoDiv macro val
	if SonicDriverVer>=3
		db	0FFh,04h,val
	else
		db	0EBh,val
	endif
	endm

; ECxx - Set Volume to xx
smpsSetVol macro val
	if SonicDriverVer>=3
		db	0E4h,val
	else
		fatal "Coord. Flag to set volume (instead of volume attenuation) does not exist in S1 or S2 drivers. Complain to Flamewing to add it."
	endif
	endm

; Works on all drivers
smpsPSGAlterVol macro vol
	db	0ECh,vol
	endm

smpsPSGAlterVolS2 macro vol
	; Sonic 2's driver allows the FM command to be used on PSG channels, but others do not.
	if SonicDriverVer==2
		smpsAlterVol vol
	else
		smpsPSGAlterVol vol
	endif
	endm

; Clears pushing sound flag in S1
smpsClearPush macro
	if SonicDriverVer==1
		db	0EDh
	else
		fatal "Coord. Flag to clear S1 push block flag does not exist in S2 or S3 drivers. Complain to Flamewing to add it."
	endif
	endm

; Stops special SFX (S1 only) and restarts overridden music track
smpsStopSpecial macro
	if SonicDriverVer==1
		db	0EEh
	else
		message "Coord. Flag to stop special SFX does not exist in S2 or S3 drivers. Complain to Flamewing to add it. With adequate caution, smpsStop can do this job."
		smpsStop
	endif
	endm

; EFxx[yy] - Set Voice of FM channel to xx; xx < 0 means yy present
smpsFMvoice macro voice,songID
	db	0EFh,voice
	endm

; F0wwxxyyzz - Modulation - ww: wait time - xx: modulation speed - yy: change per step - zz: number of steps
smpsModSet macro wait,speed,change,step
	db	0F0h
	db	wait,speed,change,step
	;db	speed,change,step
	endm

; Turn on Modulation
smpsModOn macro type
	if SonicDriverVer>=3
		if "type"<>""
			db	0F4h,type
		else
			db	0F4h,80h
		endif
	else
		db	0F1h
	endif
	endm

; F2 - End of channel
smpsStop macro
	db	0F2h
	endm

; F3xx - PSG waveform to xx
smpsPSGform macro form
	db	0F3h,form
	endm

; Turn off Modulation
smpsModOff macro
	if SonicDriverVer>=3
		db	0FAh
	else
		db	0F4h
	endif
	endm

; F5xx - PSG voice to xx
smpsPSGvoice macro voice
	db	0F5h,voice
	endm

; F6xxxx - Jump to xxxx
smpsJump macro loc
	db	0F6h
	dw	loc
	endm

; F7xxyyzzzz - Loop back to zzzz yy times, xx being the loop index for loop recursion fixing
smpsLoop macro index,loops,loc
	db	0F7h
	db	index,loops
	dw	loc
	endm

; F8xxxx - Call pattern at xxxx, saving return point
smpsCall macro loc
	db	0F8h
	dw	loc
	endm
; ---------------------------------------------------------------------------
; Alter Volume
smpsFMAlterVol macro val1,val2
	if (SonicDriverVer>=3)&&("val2"<>"")
		db	0E5h,val1,val2
	else
		db	0E6h,val1
	endif
	endm
; ---------------------------------------------------------------------------
; S1/S2 only coordination flag
; Sets D1L to maximum volume (minimum attenuation) and RR to maximum for operators 3 and 4 of FM1
smpsMaxRelRate macro
	if SonicDriverVer>=3
		; Emulate it in S3/S&K/S3D driver
		smpsFMICommand 88h,0Fh
		smpsFMICommand 8Ch,0Fh
	else
		db	0F9h
	endif
	endm
; ---------------------------------------------------------------------------
; Backwards compatibility
smpsAlterNote macro
	smpsDetune	ALLARGS
	endm

smpsAlterPitch macro
	smpsChangeTransposition	ALLARGS
	endm

smpsFMFlutter macro
	smpsFMVolEnv	ALLARGS
	endm

smpsWeirdD1LRR macro
	smpsMaxRelRate ALLARGS
	endm

smpsSetvoice macro
	smpsFMvoice ALLARGS
	endm
; ---------------------------------------------------------------------------
; Macros for FM instruments
; Voices - Feedback
smpsVcFeedback macro val
vcFeedback set val
	endm

; Voices - Algorithm
smpsVcAlgorithm macro val
vcAlgorithm set val
	endm

smpsVcUnusedBits macro val,d1r1,d1r2,d1r3,d1r4
vcUnusedBits set val
	if ("d1r1"<>"")&&("d1r2"<>"")&&("d1r3"<>"")&&("d1r4"<>"")
		set vcD1R1Unk,d1r1<<5
		set vcD1R2Unk,d1r2<<5
		set vcD1R3Unk,d1r3<<5
		set vcD1R4Unk,d1r4<<5
	else
		set vcD1R1Unk,0
		set vcD1R2Unk,0
		set vcD1R3Unk,0
		set vcD1R4Unk,0
	endif
	endm

; Voices - Detune
smpsVcDetune macro op1,op2,op3,op4
	set vcDT1,op1
	set vcDT2,op2
	set vcDT3,op3
	set vcDT4,op4
	endm

; Voices - Coarse-Frequency
smpsVcCoarseFreq macro op1,op2,op3,op4
	set vcCF1,op1
	set vcCF2,op2
	set vcCF3,op3
	set vcCF4,op4
	endm

; Voices - Rate Scale
smpsVcRateScale macro op1,op2,op3,op4
	set vcRS1,op1
	set vcRS2,op2
	set vcRS3,op3
	set vcRS4,op4
	endm

; Voices - Attack Rate
smpsVcAttackRate macro op1,op2,op3,op4
	set vcAR1,op1
	set vcAR2,op2
	set vcAR3,op3
	set vcAR4,op4
	endm

; Voices - Amplitude Modulation
; The original SMPS2ASM erroneously assumed the 6th and 7th bits
; were the Amplitude Modulation.
; According to several docs, however, it's actually the high bit.
smpsVcAmpMod macro op1,op2,op3,op4
	if SourceSMPS2ASM==0
		set vcAM1,op1<<5
		set vcAM2,op2<<5
		set vcAM3,op3<<5
		set vcAM4,op4<<5
	else
		set vcAM1,op1<<7
		set vcAM2,op2<<7
		set vcAM3,op3<<7
		set vcAM4,op4<<7
	endif
	endm

; Voices - First Decay Rate
smpsVcDecayRate1 macro op1,op2,op3,op4
	set vcD1R1,op1
	set vcD1R2,op2
	set vcD1R3,op3
	set vcD1R4,op4
	endm

; Voices - Second Decay Rate
smpsVcDecayRate2 macro op1,op2,op3,op4
	set vcD2R1,op1
	set vcD2R2,op2
	set vcD2R3,op3
	set vcD2R4,op4
	endm

; Voices - Decay Level
smpsVcDecayLevel macro op1,op2,op3,op4
	set vcDL1,op1
	set vcDL2,op2
	set vcDL3,op3
	set vcDL4,op4
	endm

; Voices - Release Rate
smpsVcReleaseRate macro op1,op2,op3,op4
	set vcRR1,op1
	set vcRR2,op2
	set vcRR3,op3
	set vcRR4,op4
	endm

; Voices - Total Level
; The original SMPS2ASM decides TL high bits automatically,
; but later versions leave it up to the user.
; Alternatively, if we're converting an SMPS 68k song to SMPS Z80,
; then we *want* the TL bits to match the algorithm, because SMPS 68k
; prefers the algorithm over the TL bits, ignoring the latter, while
; SMPS Z80 does the opposite.
; Unfortunately, there's nothing we can do if we're trying to convert
; an SMPS Z80 song to SMPS 68k. It will ignore the bits no matter
; what we do, so we just print a warning.
smpsVcTotalLevel macro op1,op2,op3,op4
	set vcTL1,op1
	set vcTL2,op2
	set vcTL3,op3
	set vcTL4,op4
	db	(vcUnusedBits<<6)+(vcFeedback<<3)+vcAlgorithm
;   0     1     2     3     4     5     6     7
;%1000,%1000,%1000,%1000,%1010,%1110,%1110,%1111
	if SourceSMPS2ASM==0
		set vcTLMask4,((vcAlgorithm==7)<<7)
		set vcTLMask3,((vcAlgorithm>=4)<<7)
		set vcTLMask2,((vcAlgorithm>=5)<<7)
		set vcTLMask1,80h
	else
		set vcTLMask4,0
		set vcTLMask3,0
		set vcTLMask2,0
		set vcTLMask1,0
	endif

	if (SonicDriverVer>=3)&&(SourceDriver<3)
		set vcTLMask4,((vcAlgorithm==7)<<7)
		set vcTLMask3,((vcAlgorithm>=4)<<7)
		set vcTLMask2,((vcAlgorithm>=5)<<7)
		set vcTLMask1,80h
		set vcTL1,vcTL1&7Fh
		set vcTL2,vcTL2&7Fh
		set vcTL3,vcTL3&7Fh
		set vcTL4,vcTL4&7Fh
	elseif (SonicDriverVer<3)&&(SourceDriver>=3)&&((((vcTL1|vcTLMask1)&80h)<>80h)||(((vcTL2|vcTLMask2)&80h)<>((vcAlgorithm>=5)<<7))||(((vcTL3|vcTLMask3)&80h)<>((vcAlgorithm>=4)<<7))||(((vcTL4|vcTLMask4)&80h)<>((vcAlgorithm==7)<<7)))
		if MOMPASS=1
			message "Voice at 0x\{*} has TL bits that do not match its algorithm setting. This voice will not work in S1/S2 drivers."
		endif
	endif

	if SonicDriverVer==2
		db	(vcDT4<<4)+vcCF4       ,(vcDT2<<4)+vcCF2       ,(vcDT3<<4)+vcCF3       ,(vcDT1<<4)+vcCF1
		db	(vcRS4<<6)+vcAR4       ,(vcRS2<<6)+vcAR2       ,(vcRS3<<6)+vcAR3       ,(vcRS1<<6)+vcAR1
		db	vcAM4|vcD1R4|vcD1R4Unk ,vcAM2|vcD1R2|vcD1R2Unk ,vcAM3|vcD1R3|vcD1R3Unk ,vcAM1|vcD1R1|vcD1R1Unk
		db	vcD2R4                 ,vcD2R2                 ,vcD2R3                 ,vcD2R1
		db	(vcDL4<<4)+vcRR4       ,(vcDL2<<4)+vcRR2       ,(vcDL3<<4)+vcRR3       ,(vcDL1<<4)+vcRR1
		db	vcTL4|vcTLMask4        ,vcTL2|vcTLMask2        ,vcTL3|vcTLMask3        ,vcTL1|vcTLMask1
	else
		db	(vcDT4<<4)+vcCF4       ,(vcDT3<<4)+vcCF3       ,(vcDT2<<4)+vcCF2       ,(vcDT1<<4)+vcCF1
		db	(vcRS4<<6)+vcAR4       ,(vcRS3<<6)+vcAR3       ,(vcRS2<<6)+vcAR2       ,(vcRS1<<6)+vcAR1
		db	vcAM4|vcD1R4|vcD1R4Unk ,vcAM3|vcD1R3|vcD1R3Unk ,vcAM2|vcD1R2|vcD1R2Unk ,vcAM1|vcD1R1|vcD1R1Unk
		db	vcD2R4                 ,vcD2R3                 ,vcD2R2                 ,vcD2R1
		db	(vcDL4<<4)+vcRR4       ,(vcDL3<<4)+vcRR3       ,(vcDL2<<4)+vcRR2       ,(vcDL1<<4)+vcRR1
		db	vcTL4|vcTLMask4        ,vcTL3|vcTLMask3        ,vcTL2|vcTLMask2        ,vcTL1|vcTLMask1
	endif
	endm

