; ***********************************************************
; *                                                         *
; *  HRCPM12-BIOS fuer den AC1      Version vom 11.04.2024  *
; *                                                         *
; *                                                  V.143  *
; *                                                         *
; ***********************************************************
;
; Korrekturen/Fehlerbehebungen:
; - alle nicht genutzten Programmteile (HRDOS12) entfernt
; - (Turbo-)LOAD entfernt
; - BWS (Farb-)Init geaendert
; - ^G BEEP + PUNCH:=V24out + LIST:=V24out hinzugefuegt
; - keine Pruefsumme, kein Vergleichslesen der RAM-Disk (entfernt)
; - fehlerhafte Maskierung USER in WBOOT entfernt
; - Kursorblinken im Texteditor
; - Consolenkommandos Kursor-ON / Kursor-OFF
; - RAM-Disk mit 64 REC/TRK, Systemspur auf 8K reduziert
; - GIDE-Laufwerke (C:, D:, E:) auf 8MByte verkleinert
; - Formatierung RAM-Disk: letzter Sektor wurde nicht formatiert
; - ISR angepasst, damit HRCPM12 mit JKCEMU V0.9.8.3 funktioniert
; - Fehlermeldung "Bdos Err On P: Select" in WBOOT behoben
;
; Neu hinzugekommen:
; - EXIT loescht CCPPUFLEN (V.132)
; - WBOOT loescht CCPPUFLEN, weil in Systemspur "aktiver Befehl" (V.133)
; - Eintragen von NMI auf 066h in BOOT1 entfernt (CPM Page-Zero) (V.133)
; - Tastaturpuffer von FFD0h -> FF00h, "d"-Befehl ueberschrieben (V.134)
; - nicht benutzte RAM-Zellen am Ende auskommentiert (V.135)
; - automatische Erkennung der RAM-Disk 256k/512k/1024k/2048k (V.140)
; - Änderungen an READ_CCP (V.142)
;
;
        .CREF
        .Z80
;
        .PHASE 0E600H
;
;
OUTHL   EQU  07F1H
RSA     EQU  01A5H        ;CPU-Register nach RSA - nicht Monitor 11 !
REGIST  EQU  05CEH        ;Registeranzeige - nicht Monitor 11 !
MV24A   EQU  0DF9H        ;MO-UP V24-Out
;
;
CUPOS   EQU  1800H
BREAK   EQU  1818H        ;NMI Sprungziel
CBWSB   EQU  181FH        ;Merkzelle fuer das Farbbyte im AC1-Monitor 
;                         ;0=kein Color-BWS, sonst der eingestellte Farbwert
ARG1    EQU  185BH
ARG2    EQU  185DH
;
;
WARMBT  EQU  0000H        ;WBOOT der Grundseite
BDOSF   EQU  0005H        ;BDOS-Aufruf + TPA-MAX
RST38   EQU  0038H        ;CP/M-Break
NMI     EQU  0066H
;
;
IOBYTE  EQU  0003H
LWBYTE  EQU  0004H        ;LW (Bit0-3) + USER Nr.(Bit4-7)
;
ZEIPUF  EQU  0FF00H       ;1 + 32 Byte Puffer fuer Tastatur
;                          --> war urspruenlich auf 0FFD0H
;                          --> ueberschreibt den "d"-Befehl
;
BDOS    EQU  0D806H       ;BDOS-EinsprungAdresse
WBOOTB  EQU  0E603H       ;BIOS-Eisprung WBOOT
;
;
HPRDSK  EQU  0C000H       ;Hilfsprogramm: Format RAM-Disk
CCP     EQU  0D000H       ;Start CCP
COMLEN  EQU  CCP+07       ;CCP-Kommandopuffer-Laenge
;
PE0     EQU  0E0H         ;Grundadresse der RAM-Disk
PF0     EQU  0F0H         ;BWS-CPLD-(Steuer)Port
;
CFDC    EQU  40H          ;Hauptstatusregister FDC
DFDC    EQU  41H          ;Datenport FDC
FLWAIT  EQU  43H          ;IO-Adr. /WAIT Monoflop
LATCH   EQU  45H          ;IO-Adr. Latch 74LS175
;
CUZEI   EQU  0FH          ;KursorSymbol
;
;******************************   Sprungverteiler   ******************************
;
        JP   BOOT
        JP   WBOOT
        JP   CONST
        JP   CONIN
        JP   CONOUT
        JP   LIST
        JP   PUNCH
        JP   CONIN        ;eigentlich JP READER
        JP   HOME
        JP   SELDSK
        JP   SETTRK
        JP   SETSEC
        JP   SETDMA
        JP   READ
        JP   WRITE
        JP   LISTST
        JP   SECTRN
;
        DEFM 'C85AC'      ;fuer PC/BC Progr.
        JP   EXIT         ;User-Kommando EXIT
        JP   LOAD         ;User-Kommando LOAD
        JP   0000H
;
NDISK:  DEFB 7            ;Anzahl der LW = 7
;
DPHX:   DEFW DPHY         ;Zeiger auf den 1. Block?
DPHY:   DEFW DPH0         ;DPH von LW A:
        DEFW DPH1         ;DPH von LW B:
        DEFW DPH2         ;DPH von LW C:
        DEFW DPH3         ;DPH von LW D:
        DEFW DPH4         ;DPH von LW E:
        DEFW DPH5         ;DPH von LW F:
        DEFW DPH6         ;DPH von LW G:
;
DPH0:   DEFW 0            ;RAM-Disk A:
        DEFW 0
        DEFW 0
        DEFW 0
        DEFW DIRBF
        DEFW DPB0
        DEFW 0            ;weil nichtwechselbares Medium
        DEFW ALL00
;
DPH1:   DEFW 0            ;Floppy B:
        DEFW 0
        DEFW 0
        DEFW 0
        DEFW DIRBF
        DEFW DPB1
        DEFW CHK01
        DEFW ALL01
;
DPH2:   DEFW 0            ;GIDE C:
        DEFW 0
        DEFW 0
        DEFW 0
        DEFW DIRBF
        DEFW DPB2
        DEFW 0            ;weil nichtwechselbares Medium
        DEFW ALL02
;
DPH3:   DEFW 0            ;GIDE D:
        DEFW 0
        DEFW 0
        DEFW 0
        DEFW DIRBF
        DEFW DPB3
        DEFW 0            ;weil nichtwechselbares Medium
        DEFW ALL03
;
DPH4:   DEFW 0            ;GIDE E:
        DEFW 0
        DEFW 0
        DEFW 0
        DEFW DIRBF
        DEFW DPB4
        DEFW 0            ;weil nichtwechselbares Medium
        DEFW ALL04
;
DPH5:   DEFW 0            ;Floppy F:
        DEFW 0
        DEFW 0
        DEFW 0
        DEFW DIRBF
        DEFW DPB5
        DEFW CHK05
        DEFW ALL05
;
DPH6:   DEFW 0            ;Floppy G:
        DEFW 0
        DEFW 0
        DEFW 0
        DEFW DIRBF
        DEFW DPB6
        DEFW CHK06
        DEFW ALL06
;
; https://hc-ddr.hucki.net/wiki/doku.php/cpm/write_a_bios/teil_1
;
;RAM-Disk 256 KByte  LW A:
;
        DEFW RWRDSK       ;Routine zum Lesen/Schreiben der RAM-Disk
;
DPB0:   DEFW 64           ;64 Sectoren/Track (Rec/Trk) = 8 Kbyte/Track
        DEFB 3            ;Blockgroesse = 1 Kbyte
        DEFB 7
        DEFB 0            ;8-Bit Blockadressen im FCB/DIR, da weniger als 255 Bloecke
        DEFW 247          ;248 * 1 Kbyte-Bloecke  -> 256k-8k(System)=248k(CP/M) ( - 2k(DIR) -> 246k (NETTO f. Daten))
        DEFW 63           ;64 DIR - Eintaege
        DEFW 0C0H         ;2 DIR-Bloecke
        DEFW 0            ;weil nichtwechselbares Medium
        DEFW 1            ;8 Kbyte System / Track-Offset
;
;Floppy 780 KByte  LW B:
;
        DEFW RWFLO        ;Routine zum Lesen/Schreiben der Floppy-Disk
;
DPB1:   DEFW 80           ;80 Sectoren/Track
        DEFB 4            ;Blockgroesse = 2 Kbyte
        DEFB 15
        DEFB 0
        DEFW 389          ;390 * 2 Kbyte - Bloecke
        DEFW 127          ;128 DIR - Eintraege
        DEFW 0C0H         ;2 DIR-Bloecke
        DEFW 32
        DEFW 2            ;20 Kbyte System
;
        DEFB 3,7,5,25H
        DEFB 50H,0,43H,0FFH
        DEFB 0E1H,33H,0FFH
;
;GIDE 8 MByte  LW C:
;
        DEFW RWGIDE       ;Routine zum Lesen/Schreiben des GIDE-LW
;
DPB2:   DEFW 2048         ;2048 Records/Track = 256k/Trk
        DEFB 5
        DEFB 31           ;4k Bloecke
        DEFB 1            ;16-Bit Blockadressen im FCB/DIR
        DEFW 1983         ;1984 * 4k-Bloecke = 7936k
        DEFW 2047         ;2048 DIR-Eintraege
        DEFW 0FFFFH       ;16 DIR-Bloecke = 64 k
        DEFW 0            ;weil nichtwechselbares Medium
        DEFW 1            ;1 Trk = 256k System
;
        DEFB 2,3,0A0H     ;?,?, add constant bits fuer Kopf-Register ?
        DEFW 000AH        ;10 = 1. Zylinder-Nr. phys. LW, wo BDOS-LW beginnt
        DEFW 0040H        ;64 Zyl. f. 16 MB LW-Groesse
        DEFW 03D8H        ;984 Zylinder HDD
        DEFB 10H          ;16 Koepfe HDD
        DEFB 20H          ;32 Sektoren/Spur HDD
;
;GIDE 8 MByte  LW D:
;
        DEFW RWGIDE       ;Routine zum Lesen/Schreiben des GIDE-LW
;
DPB3:   DEFW 2048         ;2048 Records/Track = 256k/Trk
        DEFB 6
        DEFB 63           ;8k Bloecke
        DEFB 3            ;16Bit Blockadressen im FCB/DIR
        DEFW 1023         ;1024 * 8k-Bloecke = 8192k = 8M
        DEFW 4095         ;4096 DIR-Eintraege
        DEFW 0FFFFH       ;16 DIR-Bloecke
        DEFW 0            ;weil nichtwechselbares Medium
        DEFW 0            ;kein System-Track
;
        DEFB 2,3,0A0H     ;?,?, add constant bits fuer Kopf-Register ?
        DEFW 0096H        ;150 = 1. Zylinder-Nr. phys. LW, wo BDOS-LW beginnt
        DEFW 0040H        ;64 Zyl. f. 16 MB LW-Groesse
        DEFW 03D8H        ;984 Zylinder HDD
        DEFB 10H          ;16 Koepfe HDD
        DEFB 20H          ;32 Sektoren/Spur HDD
;
;GIDE 8 MByte  LW E:
;
        DEFW RWGIDE       ;Routine zum Lesen/Schreiben des GIDE-LW
;
DPB4:   DEFW 2048         ;2048 Records/Track = 256k/Trk
        DEFB 6
        DEFB 63           ;8k Bloecke
        DEFB 3            ;16Bit Blockadressen im FCB/DIR
        DEFW 1023         ;1024 * 8k-Bloecke = 8192k = 8M
        DEFW 4095         ;4096 DIR-Eintraege
        DEFW 0FFFFH       ;16 DIR-Bloecke
        DEFW 0            ;weil nichtwechselbares Medium
        DEFW 0            ;kein System-Track
;
        DEFB 2,3,0A0H     ;?,?, add constant bits fuer Kopf-Register ?
        DEFW 012CH        ;300 = 1. Zylinder-Nr. phys. LW, wo BDOS-LW beginnt
        DEFW 0040H        ;64 Zyl. f. 16 MB LW-Groesse
        DEFW 03D8H        ;984 Zylinder HDD
        DEFB 10H          ;16 Koepfe HDD
        DEFB 20H          ;32 Sektoren/Spur HDD
;
;Floppy 640 KByte  LW F:
;
        DEFW RWFLO        ;Routine zum Lesen/Schreiben der Floppy-Disk
;
DPB5:   DEFW 64           ;64 Sectoren/Track
        DEFB 4            ;Blockgroesse = 2 Kbyte
        DEFB 15
        DEFB 0
        DEFW 319          ;320 * 2 Kbyte - Bloecke
        DEFW 127          ;128 DIR - Eintraege
        DEFW 0C0H         ;2 DIR-Bloecke
        DEFW 32
        DEFW 0            ;kein System-Track
;
        DEFB 1,1,10H,14H
        DEFB 50H,0,43H,0FFH
        DEFB 0E1H,33H,0FFH
;
;Floppy 800 KByte  LW G:
;
        DEFW RWFLO        ;Routine zum Lesen/Schreiben der Floppy-Disk
;
DPB6:   DEFW 80           ;80 Sectoren/Track
        DEFB 4            ;Blockgroesse = 2 Kbyte
        DEFB 15
        DEFB 0
        DEFW 399          ;400 * 2 Kbyte - Bloecke
        DEFW 127          ;128 DIR - Eintraege
        DEFW 0C0H         ;2 DIR-Bloecke
        DEFW 32
        DEFW 0            ;kein System-Track
;
        DEFB 3,7,5,25H
        DEFB 50H,1,43H,0FFH
        DEFB 0E1H,33H,0FFH
;
;RAM-Disk 512 KByte  LW A:
DP512:  DEFW 64           ;64 Sectoren/Track (Rec/Trk) = 8 Kbyte/Track
        DEFB 4            ;Blockgroesse = 2 Kbyte
        DEFB 15
        DEFB 1            ;8-Bit Blockadressen im FCB/DIR, da weniger als 255 Bloecke
        DEFW 251          ;252 * 2 Kbyte-Bloecke  -> 512k-8k(System)=504k(CP/M) ( - 2k(DIR) -> 502k (NETTO f. Daten))
        DEFW 63           ;64 DIR - Eintaege
        DEFW 080H         ;1 DIR-Block
        DEFW 0            ;weil nichtwechselbares Medium
        DEFW 1            ;8 Kbyte System / Track-Offset
;
;RAM-Disk 1024 KByte  LW A:
DP1024: DEFW 64           ;64 Sectoren/Track (Rec/Trk) = 8 Kbyte/Track
        DEFB 4            ;Blockgroesse = 2 Kbyte
        DEFB 15
        DEFB 0            ;16-Bit Blockadressen im FCB/DIR, da mehr als 255 Bloecke
        DEFW 507          ;508 * 2 Kbyte-Bloecke  -> 1024k-8k(System)=1016k(CP/M) ( - 4k(DIR) -> 1012k (NETTO f. Daten))
        DEFW 127          ;128 DIR - Eintraege -> bei 64 DIR-Eintraegen bekommt man die RAM-Disk nicht voll
        DEFW 0C0H         ;2 DIR-Bloecke
        DEFW 0            ;weil nichtwechselbares Medium
        DEFW 1            ;8 Kbyte System / Track-Offset
;
;RAM-Disk 2048 KByte  LW A:
DP2048: DEFW 64           ;64 Sectoren/Track (Rec/Trk) = 8 Kbyte/Track
        DEFB 4            ;Blockgroesse = 2 Kbyte
        DEFB 15
        DEFB 0            ;16-Bit Blockadressen im FCB/DIR, da mehr als 255 Bloecke
        DEFW 1019         ;1020 * 2 Kbyte-Bloecke  -> 2048k-8k(System)=2040k(CP/M) ( - 8k(DIR) -> 2032k (NETTO f. Daten))
        DEFW 255          ;256 DIR - Eintraege
        DEFW 0F0H         ;4 DIR-Bloecke
        DEFW 0            ;weil nichtwechselbares Medium
        DEFW 1            ;8 Kbyte System / Track-Offset
;
TXT01:  DEFB 0CH
        DEFM "HRCPM AC1 V1.2 CPA "
        DEFM "11.01.89 FA-MODE "
        DEFM "vom 11.04.2024 V.143"
        DEFB 0DH,0AH,0DH,0AH
        DEFM "GIDE(80H) C0:8MB,"
        DEFM "   D0: 8MB   E0: 8MB"
        DEFB 0DH,0AH
        DEFM "FDC (45H) B0:5*1024"   ;B0 --> Floppy-Drive 0,
        DEFM " F0:16*256 G1:5*1024"  ;F0 --> Floppy-Drive 0, G1 --> Floppy-Drive 1
        DEFB 0DH,0AH,0DH,0AH
        DEFM "RFL Praeci.Port E0H"
        DEFM " A: "
        DEFB 0
TXT01A: DEFM "256k"
        DEFB 0
TXT01B: DEFM "512k"
        DEFB 0
TXT01C: DEFM "1024k"
        DEFB 0
TXT01D: DEFM "2048k"
        DEFB 0
TXT02:  DEFM " --> Format A:(J)?"
        DEFB 0
;
;******************************   BOOT   ******************************
;
BOOT:   DI
        LD   SP,CPMSTK
        XOR  A
        OUT  (P1E),A      ;zwingend AC1-Mode !!
        LD   (LATPU),A    ;FDC-Latch zuruecksetzen
        CALL BWSINI
        IN   A,(P05)
        RES  3,A          ;ACC-Zeichensatz ein (PIO1B, Bit3)
        OUT  (P05),A
        LD   HL,(BREAK)   ;Sprungtabelle NMI Monitor
        LD   (OLDNMI),HL  ;sichern
        LD   HL,WBOOTB    ;CP/M-Warmstart-Einsprungadresse
        LD   (BREAK),HL
        CALL CPMMOD
        XOR  A
        LD   (DF51A),A
        LD   (IOBYTE),A
        LD   (LWBYTE),A
        LD   (ZEIPUF),A   ;Init. Tastaturpuffer
        CALL BOOT1        ;CP/M "Grundseite" INIT
;
        LD   A,03H        ;CTC init. + Interrupt abgeschaltet
        OUT  (P00),A
        OUT  (P01),A
        OUT  (P02),A
        OUT  (P03),A
        LD   A,0FFH       ;HWT vom Interruptvektor 0FF80h ff.
        LD   I,A
        IM   2            ;Interrupt freigeben
        LD   HL,INTEND    ;Adresse Einsprungpunkt fuer nicht verwendete Interrupts
        LD   (DFF80),HL   ;Prog. Einsprung IV fuer CTC-Kanal 0
        LD   (DFF82),HL   ;Prog. Einsprung IV fuer CTC-Kanal 1
        LD   (DFF84),HL   ;Prog. Einsprung IV fuer CTC-Kanal 2
        LD   HL,ISRCTC    ;Einsprungpunkt CTC-Interrupt - Steuerung Nachlauf Floppy-LW
        LD   (DFF86),HL   ;Prog. Einsprung IV fuer CTC-Kanal 3
        LD   A,80H
        OUT  (P00),A      ;CTC-Interruptadresse NWT (= 80h) eintragen
        LD   A,0FFH
        LD   (CTCCNT),A   ;Init. CTC-Counter = 255 --> Zusatzzaehler fuer CTC-Interrupt
        LD   A,0A7H
        OUT  (P03),A      ;Programmierung der CTC K3 als Zeitgeber mit Interrupt, Vorteiler 256
        XOR  A
        OUT  (P03),A      ;Programmierung der CTC K3 - Hauptteiler = 256
                          ;d.h. bei 2 MHz CPU-Takt wird alle 33ms ein CTC-Interrupt ausgeloest
;
        LD   HL,ISRTAS    ;1. Einsprungpunkt PIO-Interrupt --> Taste in Tastaturpuffer schreiben
        LD   (DFF88),HL   ;auf 0FF88h eintragen
        LD   BC,0506H     ;5 Bytes auf Controlkanal PIO1 A
        LD   HL,PIOTAB
        OTIR              ;PIO1_A Init. fuer 1. Einsprungpunkt
;
        LD   HL,TXT01     ;Begruessungstext
        CALL OUTTXT
;
        CALL RDTEST       ;Kapazitaet der RAM-Disk bestimmen
        LD   HL,RDSIZE    ;RD-Size: 0=256K 1=512K 2=1024K 3=2048K
        LD   A,(HL)
        LD   HL,DP2048    ;DPB 2048K RAM-Disk
        CP   3
        JR   Z,BOOT2
        LD   HL,DP1024    ;DPB 1024K RAM-Disk
        CP   2
        JR   Z,BOOT2
        LD   HL,DP512     ;DPB 512K RAM-Disk
        CP   1
        JR   Z,BOOT2
        JR   BOOT3        ;256K RAM-Disk, nichts kopieren
;        
BOOT2:  LD   DE,DPB0
        LD   BC,15
        LDIR
BOOT3:  LD   HL,TXT01D    ;2048k
        CP   3
        JR   Z,BOOT4
        LD   HL,TXT01C    ;1024k
        CP   2
        JR   Z,BOOT4
        LD   HL,TXT01B    ;512k
        CP   1
        JR   Z,BOOT4
        LD   HL,TXT01A    ;256k
BOOT4:  CALL OUTTXT
        LD   HL,TXT02     ;Formatieren? (J)
        CALL OUTTXT
        EI
        CALL CONIN
        RES  5,A          ;Upcase
        CP   4AH          ;J --> RAM-Disk formatieren
        JP   Z,RDFORM
;       LD   HL,6000H     ;FC64.COM von 6000h nach 100h kopieren
;       LD   DE,0100H
;       LD   BC,5880H     ;5880h Bytes
;       LDIR
        JR   WBOOT1       ;READCCP ueberspringen
;
;******************************   WBOOT   ******************************
;
WBOOT:  LD   SP,CPMSTK
        CALL CPMMOD
        LD   A,(DF51B)
        OR   A
        CALL NZ,LF0CE
        LD   B,2CH        ;44 Bloecke CCP+BDOS
        LD   HL,READ
        LD   (WRCCP2),HL
        CALL WRCCP        ;hier READ_CCP!
        XOR  A
        LD   (COMLEN),A   ;auf Laenge=0 setzen
        LD   A,(NDISK)    ;Anzahl der LW
        LD   C,A
        LD   A,(LWBYTE)
        AND  0FH          ;LW testen
        CP   C
        JR   C,WBOOT1     ;akt. LW < NDISK
        LD   A,(LWBYTE)
        AND  0F0H         ;LW ruecksetzen
        LD   (LWBYTE),A
;
WBOOT1: CALL BOOT1        ;CP/M "Grundseite" INIT
        LD   A,01H        ;Kursor einschalten
        LD   (CUFLAG),A
        LD   A,(COLO2)
        LD   (COLOR),A    ;Arbeitszelle Farbbyte
        AND  77H          ;Intensivdarstellung maskieren
        LD   (COLO1),A    ;Arbeitszelle "Normaldarstellung"
        LD   A,(LWBYTE)
        LD   C,A
        JP   CCP          ;hier beginnt die Party
;
CPMERR: PUSH AF           ;CP/M-Fehler - zurueck z. Monitor
        PUSH HL
        CALL EXIT1
        RST  18H
        DEFB 0DH
        DEFM "CP/M-Fehler:"
        DEFB 20H+80H
        POP  HL
        POP  AF
        CALL RSA          ;CPU-Register nach RSA - nicht Monitor 11 !
        POP  HL
        DEC  HL
        CALL OUTHL
        RST  18H
        DEFB 0DH+80H
        CALL REGIST       ;Monitor - Registeranzeige - nicht Monitor 11 !
        RST  38H          ;zurueck zum Monitor
;
BOOT1:  LD   A,0C3H       ;CP/M "Grundseite" INIT
        LD   (WARMBT),A
        LD   (BDOSF),A
        LD   (RST38),A
        LD   HL,WBOOTB
        LD   (WARMBT+1),HL
        LD   HL,BDOS
        LD   (BDOSF+1),HL
        LD   HL,CPMERR
        LD   (RST38+1),HL
        LD   HL,0080H
        LD   (DMA),HL
        RET
;
;******************************   Ende BOOT / WBOOT   ******************************
;
CPMMOD: PUSH AF           ;CP/M EIN
        LD   A,01H
        JR   MOD1
;
AC1MOD: PUSH AF           ;CP/M AUS (AC1-Mode)
        XOR  A
MOD1:   OUT  (P1E),A
        POP  AF
        RET
;
;--------------------------------------------------------------------------
;
;EXIT - Routine
;
EXIT:   LD   HL,0000H     ;Ruecksprungadresse fuer RET
        PUSH HL
EXIT1:  XOR  A            ;Einsprung aus CPMERR
        LD   (COMLEN),A   ;auf Laenge=0 setzen
        OUT  (P1E),A      ;AC1-Mode
        LD   HL,(OLDNMI)
        LD   (BREAK),HL   ;alten NMI wiederherstellen
        LD   A,03H
        OUT  (P00),A      ;CTC: Interrupts ausschalten
        OUT  (P01),A
        OUT  (P02),A
        OUT  (P03),A
        OUT  (P06),A      ;PIO1 A: Interrupt auschalten
        LD   A,0CFH
        OUT  (P06),A      ;PIO1 A: "Mode 3" + "Set Mode"
        LD   A,0FFH
        OUT  (P06),A      ;PIO1 A: PA0 bis PA7 sind Eingaenge
        RET               ;zurueck zum Monitor
;
;
;Interrupt-Einsprung fuer die Tastatur
;
ISRTAS: DI
        PUSH AF
        PUSH BC
        PUSH HL
        IN   A,(P04)      ;PIO_A abfragen
        BIT  7,A          ;Taste gedrueckt?
        JR   Z,ISREND     ;nein, ISR beenden
        LD   C,A
;
        LD   B,1EH        ;Tastaturentprellung
PRELL1: IN   A,(P04)
        CP   C
        JR   NZ,ISREND
        DJNZ PRELL1       ;30 Durchlaeufe
;
        CP   80H
        JR   Z,ISREND     ;das war eine NULL-Eingabe
;
        LD   C,A
        LD   HL,ZEIPUF
        LD   A,(HL)       ;Fuellstand Zeichenpuffer
        INC  A
        CP   1FH          ;Puffer voll?
        JR   Z,ISREND
        LD   (HL),A       ;Anzahl der Zeichen rueckschreiben
        PUSH BC
        LD   B,0
        LD   C,A
        ADD  HL,BC        ;HL = Position im Zeichenpuffer
        POP  BC
        RES  7,C          ;7. Bit loeschen und
        LD   (HL),C       ;Taste in Zeichenpuffer eintragen
;
;       LD   BC,8034H     ;Initialisierung Tastenpiep --> 2 MHz
        LD   BC,8068H     ;Initialisierung Tastenpiep --> 4 MHz
BEEP1:  LD   A,C
BEEP2:  DEC  A
        JR   NZ,BEEP2
        IN   A,(P05)      ;PIO_B-Daten
        XOR  01H          ;Tastenpiep
        OUT  (P05),A
        DJNZ BEEP1
        AND  0FEH
        OUT  (P05),A
;
        LD   BC,0200H     ;Tastaturentprellung
PRELL2: DEC  BC
        LD   A,B
        OR   C
        JR   NZ,PRELL2
;
        LD   A,0B7H       ;weitere Interrupts loeschen
        OUT  (P06),A
        LD   A,7FH
        OUT  (P06),A
;
ISREND: POP  HL
        POP  BC
        POP  AF
        EI
        RETI
;
PIOTAB: DEFB 88H,0CFH,0FFH,0B7H,7FH  ;PIO 1A: Init.-Tabelle
;  88H --> NWT Interruptvektor --> 0FF88H
; 0CFH --> "Mode 3" + "Set Mode" (kein Handshaking, next Byte = I/O-Zuordnung)
; 0FFH --> PA0 bis PA7 sind Eingaenge
; 0B7H --> Setting Interrupt Control Word --> mit nachfolgender Maskierung
;  7FH --> Bit7=L --> nur PA7 erzeugt Interrupts
;
OUTTXT: PUSH BC
        PUSH AF
TEXT1:  LD   C,(HL)
        LD   A,C
        OR   A
        JR   Z,TEXT2
        CALL CONOUT
        INC  HL
        JR   TEXT1
TEXT2:  POP  AF
        POP  BC
        RET
;
;******************************   CONST   ******************************
;
CONST:  LD   A,(ZEIPUF)
        OR   A
        RET  Z
        LD   A,0FFH
        RET
;
;******************************   CONIN   ******************************
;
CONIN:  DI
        LD   (SPCIN),SP
        LD   SP,CINSP
        PUSH BC
        PUSH DE
        PUSH HL
        LD   BC,017FH     ;Kursor-Blinker ruecksetzen
CONIN1: XOR  A
        DI
        LD   HL,(ZEIPUF)  ;L = Anz. der Zeichen, H = 1. Zeichen
        OR   L
        JR   NZ,CONIN3    ;Zeichen im Tastaturpuffer vorhanden
        EI
        DJNZ CONIN1       ;256*LOOP: warte auf ein Zeichen
        LD   A,(CUFLAG)
        OR   A
        JR   Z,CONIN1     ;kein "Kursor-Blinken"
        DI
        CALL AC1MOD       ;AC1 Mode
        LD   HL,(CUPOS)
        INC  C
        BIT  7,C          ;hier wird die Cursor-Blinkfrequenz festgelegt
        LD   A,(CHAR)     ;bisheriges Zeichen auf der Kursorposition
        JR   Z,CONIN2
        LD   A,CUZEI      ;Kursor = 0FH
CONIN2: LD   (HL),A       ;"Kursor-Blinken" - Bildschirm-Ausgabe
        CALL CPMMOD       ;CP/M Mode
        JR   CONIN1
;
CONIN3: DEC  A            ;DEC Anzahl_der_Zeichen_im_Tastaturpuffer
        LD   (ZEIPUF),A
        LD   A,H          ;1. Zeichen aus dem Tastaturpuffer --> A
        LD   HL,ZEIPUF+2
        LD   DE,ZEIPUF+1
        LD   BC,001FH
        LDIR              ;alle Zeichen im Puffer ruecken 1 Pos. n. links
        POP  HL
        POP  DE
        POP  BC
        LD   SP,(SPCIN)
        EI
        RET
;
;******************************   LIST   ******************************
;
LIST:   DI
        CALL AC1MOD
        PUSH AF      
        LD   A,C
        CP   0AH  
        JR   Z,LIST1  
        CALL MV24A        ;Monitor V24 Ausgabe Akku
        CP   0DH     
        JR   NZ,LIST1 
        LD   A,0AH   
        CALL MV24A        ;Monitor V24 Ausgabe Akku
LIST1:  POP  AF      
        CALL CPMMOD
        EI
        RET
;
;******************************   PUNCH   ******************************
;
PUNCH:  DI                ;Ausgabe C nach V24
        LD   A,C
        CALL AC1MOD
        CALL MV24A        ;Monitor V24 Ausgabe Akku
        CALL CPMMOD
        EI
        RET
;
;******************************   CONOUT   ******************************
;
;       Ausgabe eines Zeichens,   IN: Zeichen in C
;
CONOUT: DI
        LD   (SPCOUT),SP  ;Stack bei MON-Aufruf retten
        LD   SP,COUTSP
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        CALL AC1MOD
        PUSH HL
        LD   HL,(CUPOS)   ;Cursorposition
        LD   A,(CHAR)
        LD   (HL),A       ;altes Zeichen auf Position
        LD   A,(STZ00)    ;Durchlauf bei Steuerzeichen?
        AND  A
        JP   NZ,KONV10    ;NZ= Steuerzeichen 2. oder 3. Durchlauf
        LD   A,C          ;Byte
        CP   20H          ;kleinstes Zeichen
        JR   C,KONVTB
        CP   7FH          ;groesstes Zeichen
        JR   NC,KONVTB
        LD   HL,(CUPOS)
        JP   CCHAR        ;Ausgabe einzelnes Zeichen
;
KONVT9: LD   HL,(CUPOS)
        LD   A,(HL)
        LD   (CHAR),A
        LD   A,(CUFLAG)
        OR   A
        JR   Z,COEN1      ;Kursor nicht darstellen
        LD   (HL),CUZEI
COEN1:  CALL CPMMOD
        POP  HL
        POP  DE
        POP  BC
        POP  AF
        LD   SP,(SPCOUT)
        EI
        RET
;
;Verzweigung bei Steuerzeichen
;INPUT:  A=Zeichen
;
KONVTB: CP   1BH          ;ESC ?
        JR   NZ,KONVT1
        LD   A,02H        ;wenn ja
        LD   (STZ00),A    ;Zeiger auf 2
        JR   KONVT9       ;nichts ausgeben
;
KONVT1: LD   HL,(CUPOS)
        CP   01H          ;^A Cursor home                      
        JR   Z,CHOME                                             
        CP   07H          ;^G akustisches Signal                                                 
        JP   Z,MBEEP                                              
        CP   08H          ;^H Cursor links                     
        JP   Z,CLEFT                                             
        CP   0AH          ;^J Zeilenvorschub                   
        JP   Z,CLF                                               
        CP   0CH          ;^L CLS                              
        JR   Z,BCLS                                              
        CP   0DH          ;^M Wagenruecklauf                   
        JP   Z,CCRET                                             
        CP   14H          ;^T BS ab Cursor loeschen            
        JP   Z,CBLOE                                             
        CP   15H          ;^U Cursor nach rechts               
        JP   Z,CRIGH                                             
        CP   16H          ;^V Zeile ab Cursor loeschen         
        JP   Z,CZLOE                                             
        CP   18H          ;^X Zeile ab Cursor loeschen + CR    
        JP   Z,CZLCR                                             
        CP   1AH          ;^Z Cursor hoch                      
        JP   Z,CHOCH                                             
        CP   82H          ;Kursor ein
        JP   Z,CUON
        CP   83H          ;Kursor aus
        JP   Z,CUOFF
;
        LD   B,A          ;Zeichen merken                      
        LD   A,(COLOR)                                         
        AND  A            ;Test auf Color-BWS                  
        JP   Z,KONVT9     ;Z = monochrom  
        LD   A,B                                                 
;
        CP   84H          ;normale Darstellung
        JP   Z,BNORM
        CP   85H          ;invers
        JP   Z,BINVN
        CP   86H          ;intensiv - HihgLight
        JP   Z,BINTE
        CP   87H          ;intensiv + invers
        JP   Z,BIVIN
        JP   KONVT9
;
CHOME:  LD   HL,17FFH
        LD   (CUPOS),HL
        JP   KONVT9
;
BCLS:   LD   A,20H        ;0Ch  Bildschirm loeschen
        CALL BCL1         ;Loeschroutine
        LD   (CUPOS),HL   ;Cursorposition
        LD   A,(COLOR)    ;Farbbyte
        AND  77H          ;Farb-BWS vorhanden?
        JP   Z,KONVT9     ;Z = nein, dann Ende
        CALL BWSCOL       ;Farbspeicher ein
        LD   A,(COLOR)
        CALL BCL1
        CALL BWSZEI       ;Farbspeicher aus
        JP   KONVT9
;
CLEFT:  INC  HL           ;08h  Cursor links
        JP   CHOLI
;
CLF:    LD   DE,0040H     ;0Ah  Zeilenvorschub
        AND  A
        SBC  HL,DE
        JP   SCROL
;
BCL1:   LD   HL,1000H     ;Anfang BWS
        LD   (HL),A
        LD   D,H
        LD   E,L
        INC  E
        PUSH BC
        LD   BC,07FFH     ;Laenge BWS
        LDIR
        POP  BC
        RET
;
CCRET:  LD   A,L          ;0Dh  Wagenruecklauf
        OR   3FH
        LD   L,A
        JP   SCROL
;
CBLOE:  PUSH HL
        LD   A,CUZEI      ;14h  BS ab Cursor loeschen
CBLO1:  LD   (HL),20H
        DEC  HL
        CP   H
        JR   NZ,CBLO1
        POP  HL
        LD   A,(COLOR)
        LD   B,A
        AND  77H
        JP   Z,KONVT9
        CALL BWSCOL       ;Farbspeicher ein
        LD   A,CUZEI
CBLO2:  LD   (HL),B
        DEC  HL
        CP   H
        JR   NZ,CBLO2
        CALL BWSZEI       ;Farbspeicher aus
        JP   KONVT9
;
CRIGH:  DEC  HL           ;15h  Cursor nach rechts
        JP   SCROL
;
CZLOE:  PUSH HL           ;16h  Zeile ab Cursor loeschen
        LD   A,L
        AND  3FH
        LD   B,A
        INC  B
CZLO1:  LD   (HL),20H
        DEC  HL
        DJNZ CZLO1
        POP  HL
        LD   A,(COLOR)
        LD   C,A
        AND  77H
        JP   Z,KONVT9
        CALL BWSCOL       ;Farbspeicher ein
        LD   A,L
        AND  3FH
        LD   B,A
        INC  B
CZLO2:  LD   (HL),C
        DEC  HL
        DJNZ CZLO2
        CALL BWSZEI       ;Farbspeicher aus
        JP   KONVT9
;
CZLCR:  PUSH HL           ;18h  Zeile ab Cursor loeschen + CR
        LD   A,L
        OR   3FH
        LD   L,A
        LD   (CUPOS),HL
        PUSH HL
        LD   B,40H        ;Zeilenlaenge
CZLC1:  LD   (HL),20H
        DEC  HL
        DJNZ CZLC1
        POP  HL
        LD   A,(COLOR)
        LD   C,A
        AND  77H
        JP   Z,KONVT9
        CALL BWSCOL       ;Farbspeicher ein
        LD   B,40H
CZLC2:  LD   (HL),C
        DEC  HL
        DJNZ CZLC2
        CALL BWSZEI       ;Farbspeicher aus
        JP   KONVT9
;
CHOCH:  LD   DE,0040H     ;1Ah     Cursor hoch
        ADD  HL,DE
;
CHOLI:  LD   A,18H        ;Begrenzung Cursor hoch und links
        CP   H
        JP   Z,KONVT9
        LD   (CUPOS),HL
        JP   KONVT9
;
CCHAR:  LD   (HL),A
        LD   A,(COLOR)
        LD   C,A
        AND  77H
        JR   Z,CCHA1
        CALL BWSCOL       ;Farbspeicher ein
        LD   (HL),C
        CALL BWSZEI       ;Farbspeicher aus
CCHA1:  DEC  HL
;
SCROL:  LD   (CUPOS),HL
        EX   DE,HL        ;Test ob Scrollen noetig
        LD   HL,0FFFH
        AND  A
        SBC  HL,DE        ;DE = akt. Cursorpos.
        EX   DE,HL
        JP   C,KONVT9     ;CY = nicht scrollen
        LD   A,20H        ;Leerzeichen
        CALL SCR11        ;Scrollen
        LD   A,(COLOR)
        AND  77H
        JP   Z,KONVT9     ;Z = kein Farbspeicher
        CALL BWSCOL       ;Farbspeicher ein
        LD   A,(COLOR)    ;Farbbyte
        CALL SCR11
        CALL BWSZEI       ;Farbspeicher aus
        JP   KONVT9
;
SCR11:  LD   HL,17BFH     ;Umladeroutine Scrollen
        LD   DE,17FFH
        LD   BC,07C0H
        LDDR
        EX   DE,HL
        LD   (CUPOS),HL
        INC  HL
        LD   B,40H        ;eine Zeilenlaenge
SCR12:  DEC  L
        LD   (HL),A       ;Leerzeile schreiben
        DJNZ SCR12
        RET
;
;
;UP 'MBEEP' (Monitor-Beep)
;
MBEEP:  PUSH BC 
        LD   B,02H        ;2 Wiederholungen
MBEEP1: PUSH BC 
;       LD   BC,0040H     ;--> fuer 2 MHz
        LD   BC,0080H     ;--> fuer 4 MHz
        CALL UPTON        ;UP 'Ton', Reg, B = Tonlaenge, C = Tonhoehe
;       LD   BC,0F032H    ;--> fuer 2 MHz
        LD   BC,0F064H    ;--> fuer 4 MHz
        CALL UPTON        ;UP 'Ton', Reg, B = Tonlaenge, C = Tonhoehe
        POP  BC 
        DJNZ MBEEP1 
        POP  BC 
        JP   COEN1 
;
;
;UP 'Ton', Reg, B = Tonlaenge, C = Tonhoehe
;
UPTON:  PUSH AF 
UPTON1: IN   A,(P05) 
        RRA 
        CCF 
        RLA 
        OUT  (P05),A 
        LD   A,C 
UPTON2: DEC  A 
        JR   NZ,UPTON2 
        DJNZ UPTON1 
        POP  AF 
        RET 
;
;
BNORM:  LD   A,(COLO1)    ;84h  normale Darstellung
        AND  77H
        LD   (COLOR),A
        LD   (COLO1),A
        JP   KONVT9
;
BINVN:  LD   A,(COLO1)    ;85h  invers EIN
        AND  77H
        RRCA
        RRCA
        RRCA
        RRCA
        LD   (COLOR),A
        JP   KONVT9
;
BINTE:  LD   A,(COLO1)    ;86h  intensiv EIN
        AND  77H
        OR   08H
        LD   (COLOR),A
        JP   KONVT9
;
BIVIN:  LD   A,(COLOR)    ;87h  intensiv + invers
        AND  77H
        OR   08H
        RRCA
        RRCA
        RRCA
        RRCA
        LD   (COLOR),A
        JP   KONVT9
;
CUON:   LD   A,01H        ;82h Cursor EIN
        LD   (CUFLAG),A
        JP   KONVT9
;
CUOFF:  XOR  A            ;83h Cursor AUS
        LD   (CUFLAG),A
        JP   KONVT9
;
; Behandlung ESC-Sequenzen
;
; Input: ESC + 2 Steuerzeichen
; wenn 1. Zeichen > 80h dann Cursorposition
; sonst Auswertung Farbe / Grafikzeichen
; (stz00) = Zaehler fuer Zeichenanzahl
;
KONV10: LD   A,(STZ00)
        CP   02H          ;2 = 1. Steuerzeichen (Zeile)
        JR   NZ,KONV20    ;sonst 3. Durchlauf (Spalte)
        LD   A,C
        LD   (STZ01),A    ;erstes Zeichen merken
        LD   A,01H        ;Zeiger fuer 3. Durchlauf
        LD   (STZ00),A
        JP   KONVT9       ;nichts ausgeben
;
; Verzweigung Cursorposition / weitere Funktionen
;
KONV20: LD   A,C
        LD   (STZ02),A    ;zweites Zeichen merken
        XOR  A
        LD   (STZ00),A    ;Durchlaufzaehler ruecksetzen
        LD   HL,STZ01
        LD   A,(HL)
        BIT  7,A          ;welche Funktion? NZ = Cursor
        JR   Z,KONV22     ;Z = weitere Funktionen

; Berechnung direkte Cursorposition
; OUT:    HL = BWS-Adresse
;
        PUSH AF
        LD   A,C
        AND  3FH          ;max. Spaltenzahl
        LD   L,A
        POP  AF
        AND  1FH          ;max. Zeilenzahl
        LD   D,00H
        LD   H,D
        LD   E,A
        LD   B,06H
KONV21: SLA  E
        RL   D
        DJNZ KONV21
        ADD  HL,DE
        EX   DE,HL
        LD   HL,17FFH     ;Ende BWS-RAM
        AND  A
        SBC  HL,DE
;
; Cursor direkt positionieren
; IN:    HL = Adresse Cursor
;
        PUSH HL
        LD   HL,(CUPOS)	  ;alte Position
        LD   A,(CHAR)	  ;Zeichen holen
        LD   (HL),A	      ;auf BS schreiben
        POP  HL
        LD   (CUPOS),HL   ;neue Position setzen
        LD   A,(HL)       ;neues Zeichen holen
        LD   (CHAR),A     ;und merken
        JP   KONVT9
;
; Auswertung weiterer ESC-Funktionen
; IN:      A = 1. Steuerzeichen
;
; Ausgabe Grafikzeichen aus AC1-ZG ( > 80h )
;
KONV22: CP   5FH          ;Grafikzeichen?
        JR   NZ,KONV24    ;NZ = nein
        INC  HL
        LD   A,(HL)       ;2. Zeichen holen
        LD   HL,(CUPOS)
        JP   CCHAR        ;Zeichen ausgeben
;
; Einstellen der Farbe (nur Color-BWS)
;
KONV24: CP   5DH          ;Farbe?
        JP   NZ,KONVT9    ;NZ = nein
        LD   A,(COLOR)    ;Color-BWS?
        AND  A
        JP   Z,KONVT9     ;Z = nein
        INC  HL
        LD   A,(HL)       ;2. Zeichen holen
        AND  77H          ;intensiv maskieren
        LD   B,A
        RRCA
        RRCA
        RRCA
        RRCA
        CP   B            ;Zeichen- und HG-Farbe gleich?
        JP   Z,KONVT9     ;Z = Ja, dann ignorieren
        LD   A,B
        LD   (COLOR),A    ;Farbe setzen
        AND  77H          ;intensiv maskieren
        LD   (COLO1),A    ;Backup
        JP   KONVT9
;
BWSCOL: IN   A,(PF0)      ;bwsport
        SET  2,A          ;Farbspeicher ein
        JR   BWSZ1
;
BWSZEI: IN   A,(PF0)      ;bwsport
        RES  2,A          ;Farbspeicher aus
BWSZ1:  AND  07H
        OUT  (PF0),A
        RET
;
BWSINI: XOR  A            ;Farbbyte auf Monochrom setzen
        LD   (COLOR),A    ;Arbeitszelle Farbbyte im BIOS
        LD   (COLO2),A    ;Merkzelle fuer WBOOT im BIOS
        LD   C,0F0H       ;I/O-Adresse COLOR-BWS
        IN   B,(C)        ;Konfigbyte COLOR-BWS lesen
        INC  B            ;fuer COLOR-BWS muss B<255 sein
        RET  Z            ;kein COLOR-BWS vorhanden --> Ende
        ;hier wird die Routine verlassen, wenn kein CPLD vorh. ist
        DEC  B            ;Konfigbyte COLOR-BWS: Farb-RAM aus
        LD   D,B
        SET  2,D          ;Konfigbyte COLOR-BWS: Farb-RAM ein
        LD   HL,1000H
        LD   E,(HL)       ;Zeichen aus 1000h
        OUT  (C),D        ;Farb-RAM einschalten
        LD   A,(CBWSB)    ;Farbbyte aus dem AC1-Monitor
        LD   (HL),A       ;Farbe auf 1000h setzen
        CP   (HL)         ;ist Farb-RAM gesteckt?
        OUT  (C),B        ;Farb-RAM ausschalten
        LD   (HL),E       ;Zeichen auf 1000h zurueckschreiben
        RET  NZ           ;Farbe hat nicht geklappt --> Ende
        ;hier wird die Routine verlassen, wenn kein Farb-RAM steckt
        OUT  (C),D        ;Farb-RAM einschalten
        PUSH BC
        LD   DE,1001H
        LD   BC,07FFH
        LDIR              ;Farb-RAM initialisieren
        LD   A,(HL)       ;Farbe aus 17FFh ruecklesen
        POP  BC
        OUT  (C),B        ;Farb-RAM ausschalten
        LD   (COLOR),A    ;Arbeitszelle Farbbyte im BIOS
        LD   (COLO2),A    ;Merkzelle fuer WBOOT im BIOS
        RET
;
;******************************   LISTST   ******************************
;
LISTST: XOR  A
        DEC  A
        RET
;
;******************************   SELDSK   ******************************
;
SELDSK: LD   HL,NDISK     ;max. Anzahl der LW
        LD   A,C          ;C = akt. LW
        CP   (HL)
        LD   HL,0000H     ;HL=0 --> kein LW
        RET  NC           ;akt. LW >= NDISK!!!
        LD   HL,(DPHX)    ;AnfangsADR DPH(y)-Tabelle
        LD   B,00H        ;BC = akt. LW
        ADD  HL,BC
        ADD  HL,BC        ;HL = DPHY + (2 * LW)
        LD   E,(HL)
        INC  HL
        LD   D,(HL)       ;DE = (DPHY + (2 * LW))
        EX   DE,HL        ;HL = DPH-ADR vom akt. LW
        LD   A,H
        OR   L
        RET  Z            ;HL=0 --> kein DPB
        LD   A,C
        LD   (DRIVE),A    ;aktives LW --> A
        LD   (DPH),HL     ;zugeordneter DPH --> HL
        RET
;
;******************************   HOME   ******************************
;
HOME:   LD   BC,0000H
SETTRK: LD   (TRACK),BC
        RET
;
;******************************   SETSEC   ******************************
;
SETSEC: LD   (SECTOR),BC
        RET
;
;******************************   SETDMA   ******************************
;
SETDMA: LD   (DMA),BC
        RET
;
;******************************   SECTRN   ******************************
;
SECTRN: LD   H,B
        LD   L,C
        LD   A,D
        OR   E
        RET  Z
        EX   DE,HL
        LD   B,00H
        ADD  HL,BC
        LD   L,(HL)
        LD   H,D
        RET
;
;******************************   READ + WRITE   ******************************
;
READ:   LD   C,02H
        LD   A,04H
        DEFB 21H          ;LD HL,063EH mit nxt. Befehl!!!
WRITE:  LD   A,06H        ;DUMMY fuer READ
        LD   (RWBYTE),A   ;RWBYTE: 04 = Lesen; 06 = Schreiben
        LD   A,C
        LD   (DF51E),A
        LD   HL,RWEND
        PUSH HL
        LD   HL,(DPH)
        LD   DE,000AH
        ADD  HL,DE
        LD   A,(HL)       ;NWT vom DPB
        INC  HL
        LD   H,(HL)       ;HWT vom DPB
        LD   L,A
        DEC  HL
        LD   A,(HL)       ;HWT der R/W-Funktion
        DEC  HL
        LD   L,(HL)       ;NWT der R/W-Funktion
        LD   H,A
        PUSH HL           ;Adresse der R/W-Funktion
        LD   HL,RWBYTE    ;HL -> R/W-Byte
        RET               ;JP R/W-Funktion
;
RWEND:  OR   A
        RET  Z
        LD   A,01H        ;Fehler
        RET
;
;******************************   RAM-Disk   ******************************
;
RWRDSK: LD   C,(HL)       ;RWBYTE: 04 = Lesen; 06 = Schreiben 
        INC  HL           ;DRIVE wird uebersprungen
        INC  HL
        LD   A,(HL)       ;TRACK NWT
        LD   (RAFTRK),A
        INC  HL
        LD   A,(HL)       ;TRACK HWT
        AND  A
        JR   NZ,RDERR     ;muss 0 sein
        INC  HL
        LD   A,(HL)       ;SEKTOR NWT
        LD   (RAFSEC),A
        BIT  7,A
        JR   NZ,RDERR     ;Bit 7 muss 0 sein
        BIT  6,A
        JR   NZ,RDERR     ;Bit 6 muss 0 sein
        INC  HL
        LD   A,(HL)       ;SEKTOR HWT
        AND  A
        JR   NZ,RDERR     ;muss 0 sein
        INC  HL
        INC  HL           ;DMA wird uebersprungen
        LD   A,C
        LD   BC,0080H
        CP   06H
        JR   Z,RDSKWR     ;C = 06 --> RDSK Schreiben
        CALL ADRRAF
        INIR
        NOP
        XOR  A            ;in Ordnung
        RET
;
RDSKWR: LD   HL,0080H     ;RAM-Disk schreiben 
        LD   DE,(DMA)
        CALL ADRRAF
        OTIR
        XOR  A            ;in Ordnung
        RET
;
RDERR:  LD   A,0FFH       ;Fehler
        RET
;
TXTRDI: DEFM " =>INIT.."
        DEFB 0
;
TXTRDO: DEFM "OK"
        DEFB 0
;
TXTRDE: DEFM "RFL ERROR!"
        DEFB 0DH,0AH
        DEFB 0
;
; Test der RAM-Disk - Größe (256 / 512 / 1024 / 2048 KByte)
;
RDTEST: XOR  A            ;Kapazitaet der RAM-Disk testen
        OUT  (PE0+6),A    ;H-Adresse ruecksetzen
        LD   C,PE0        ;Test erfolgt in der 1. RAM-Bank
;
; Inhalte der 4 RAM-Testzellen sichern
;
        LD   HL,RDMERK    ;Merkzellen im RAM
        LD   B,4          ;4 Durchlaeufe
        LD   D,4          ;Startwert Extended-Adresse
RDTST1: XOR  A
        OUT  (PE0+7),A    ;L-Adresse ruecksetzen
        LD   A,D
        OUT  (PE0+5),A    ;Extended-Adresse auswaehlen
        IN   A,(C)
        LD   (HL),A       ;Daten aus der RAM-Disk sichern
        INC  HL           ;Merkzelle++
        SRL  D            ;0 --> D7 --> D0 --> CY
        DJNZ RDTST1
;
; 4 Testwerte in die RAM-Disk schreiben
;
        LD   B,4          ;4 Durchlaeufe
        LD   D,4          ;Startwert Extended-Adresse
RDTST2: XOR  A
        OUT  (PE0+7),A    ;L-Adresse ruecksetzen
        LD   A,D
        OUT  (PE0+5),A    ;Extended-Adresse auswaehlen
        OUT  (C),A        ;Testwert in die RAM-Disk schreiben
        SRL  D            ;0 --> D7 --> D0 --> CY
        DJNZ RDTST2
;
;Tabelle der Test-Werte (mit *...* sind die zu testenden Werte):
;
;           RAM-Disk-Size =   256K   512K  1024K  2048K
;Extended-Adresse=00000100B    0      0      0     *4*
;Extended-Adresse=00000010B    0      0     *2*     2
;Extended-Adresse=00000001B    0     *1*     1      1
;Extended-Adresse=00000000B   *0*     0      0      0
;
; Groesse der RAM-Disk bestimmen
;
        LD   B,4          ;4 Durchlaeufe
        LD   D,4          ;Startwert Extended-Adresse
RDTST3: XOR  A
        OUT  (PE0+7),A    ;L-Adresse ruecksetzen
        LD   A,D
        OUT  (PE0+5),A    ;Extended-Adresse auswaehlen
        IN   A,(C)
        CP   D
        JR   Z,RDTST4     ;2048(B=4),1024(B=3),512(B=2),256(B=1)
        SRL  D            ;0 --> D7 --> D0 --> CY
        DJNZ RDTST3
        JP   RDERRO       ;Fehler: hier stimmt was nicht!
;
RDTST4: LD   HL,RDSIZE
        DEC  B
        LD   (HL),B       ;RD-Size: 0=256K 1=512K 2=1024K 3=2048K
;
; gesicherte Daten in die RAM-Disk zurueckschreiben
; 
        LD   HL,RDMERK+3  ;Merkzellen RAM (letzter Eintrag)
        INC  B            ;1 bis 4 Durchlaeufe, je nach RDSIZE
        LD   D,1          ;Startwert Ext.-Adr. (1 Bit n. rechts)
RDTST5: XOR  A
        OUT  (PE0+7),A    ;L-Adresse ruecksetzen
        LD   A,D
        SRL  A            ;0 --> A7 --> A0 --> CY
        OUT  (PE0+5),A    ;Extended-Adresse auswaehlen
        LD   A,(HL)
        OUT  (C),A        ;urspruengliche Daten zurueckschreiben
        DEC  HL
        SLA  D            ;CY <-- D7 <-- D0 <-- 0
        DJNZ RDTST5       ;WICHTIG: nicht mehr als notwendig
        RET               ;in die RAM-Disk zurueckschreiben!
;
RDMERK: DEFS 4,0          ;4 Merkzellen fuer den RAM-Disk Test
RDSIZE: DEFB 0            ;RD-Size: 0=256K 1=512K 2=1024K 3=2048K
;
RDFORM: LD   HL,TXTRDI    ;Formatierungstext...
        CALL OUTTXT
        LD   HL,0C002H    ;Hilfsprogramm von 0C000H bis 0C800H
        LD   D,H
        LD   E,L
        DEC  HL
        LD   (HL),PE0     ;0C001H = Grundadresse der RAM-Disk
        DEC  HL
        LD   (HL),0D3H    ;0C000H = 0D3H --> OUT n
        LD   BC,0200H
        LDIR              ;0D3H,0E0H von 0C000H bis 0C1FFH
        INC  HL
        LD   (HL),PE0+1
        DEC  HL
        LD   BC,0200H
        LDIR              ;0D3H,0E1H von 0C200H bis 0C3FFH
        INC  HL
        LD   (HL),PE0+2
        DEC  HL
        LD   BC,0200H
        LDIR              ;0D3H,0E2H von 0C400H bis 0C5FFH
        INC  HL
        LD   (HL),PE0+3
        DEC  HL
        LD   BC,0200H
        LDIR              ;0D3H,0E3H von 0C600H bis 0C7FFH
        LD   (HL),0C9H    ;RET auf 0C800H
;
        LD   HL,RDSIZE    ;RD-Size: 0=256K 1=512K 2=1024K 3=2048K
        LD   A,(HL)
        CP   0
        JR   Z,RDFOR1     ;RD 256K
        CP   1
        JR   Z,RDFOR1     ;RD 512K
        DEC  A
        SLA  A            ;A *= 2
        SLA  A            ;A *= 2
        DEC  A
RDFOR1: LD   D,A
        INC  D            ;D ==> 1=256K 2=512K 4=1024K 8=2048K
        XOR  A
        OUT  (PE0+7),A    ;L-Adresse setzen
        OUT  (PE0+5),A    ;Extended-Adresse
        LD   E,0          ;Merker fuer Extended-Adresse
        LD   B,0          ;256 Durchlaeufe
        LD   C,PE0+6
RDFOR2: OUT  (C),B        ;H-Adresse setzen
        LD   A,0E5H       ;RD wird mit 0E5H formatiert
        CALL HPRDSK       ;Hilfsprog. Format RAM-Disk auf C000H
        DJNZ RDFOR2       ;fuer alle H-Adressen (256 Durchl.)
        INC  E
        LD   A,E
        OUT  (PE0+5),A    ;Extended-Adresse
        DEC  D
        JR   NZ,RDFOR2        
;
        LD   HL,CCP
        LD   (DMA),HL
        LD   B,2CH        ;44 Bloecke CCP+BDOS
        CALL WRCCP
        JP   NZ,CPMERR
        LD   HL,TXTRDO    ;"OK"
        CALL OUTTXT
        JP   WBOOT1
;
WRCCP:  PUSH BC           ;CCP+BDOS in Systemtrack schreiben
        LD   C,0          ;LW A:
        CALL SELDSK
        POP  BC
        LD   HL,0000H
        LD   (TRACK),HL   ;Track 0
        EX   DE,HL
        LD   HL,CCP
WRCCP1: LD   (SECTOR),DE  ;Sektor 0 ff.
        LD   (DMA),HL
        PUSH BC
        DEFB 0CDH         ;CALL WRITE -> CD ED CA
WRCCP2: DEFW WRITE        ;kannn durch READ (EDC5) ersetzt werden
        POP  BC
        JR   NZ,RDERRO
        LD   HL,(DMA)
        LD   DE,0080H
        ADD  HL,DE
        LD   DE,(SECTOR)
        INC  DE
        DJNZ WRCCP1
        XOR  A
        RET
;
RDERRO: LD   HL,TXTRDE
        CALL OUTTXT
        XOR  A
        DEC  A
        RET
;
;Adressarithmetik RAF: L=RADR 0-7 , H=RADR 8-15 , A=RADR 16-19
;
ADRRAF: XOR  A            ;CY = 0
        LD   L,A 
        LD   A,(RAFSEC)   ;8 bit
        LD   H,A          ;H=Sektor (max. 64 = Bit 0-5)
        RR   H
        RR   L            ;H0 -> L7 ...... H5 -> H4
        LD   A,(RAFTRK)   ;8 bit , A=Track (max. 128 bei 1M = Bit 0-6)
        RR   A            ;A0 -> CY
        JR   NC,ADRAF1
        SET  5,H          ;H5 = A0 (RADR13)
ADRAF1: RR   A            ;A1 -> CY
        JR   NC,ADRAF2
        SET  6,H          ;H6 = A1 (RADR14)
ADRAF2: RR   A            ;A2 -> CY
        JR   NC,ADRAF3
        SET  7,H          ;H7 = A2 (RADR15)
ADRAF3: PUSH AF
        AND  03H
        OR   PE0          ;Grundadresse der RAM-Disk
        LD   C,A
        LD   A,L
        OUT  (PE0+7),A    ;L-Adresse
        LD   A,H
        OUT  (PE0+6),A    ;H-Adresse
        POP  AF
        RR   A            ;Rotiere A rechts durch Carry
        RR   A
        AND  07H          ;max. 2048K RAM-Disk
        OUT  (PE0+5),A    ;Extended-Adresse
        LD   B,80H
        LD   HL,(DMA)
        RET
;
;******************************  LOAD  ******************************
;
LOAD:   RET
;
LEFFA:  LD   HL,(DPH)     ;zugeordneter DPH --> HL
        LD   (DPH3M),HL   ;Merkzelle DPH
LF000:  LD   L,0FH
LF002:  PUSH DE
        LD   DE,000AH
        LD   H,D
        PUSH HL
        LD   HL,(DPH3M)   ;Merkzelle DPH
        ADD  HL,DE
        LD   E,(HL)
        INC  HL
        LD   D,(HL)
        POP  HL
        ADD  HL,DE
        POP  DE
        LD   A,(HL)
        OR   A
        RET
;
;
;       READ/WRITE Routinen GIDE + Floppy-Disk
;       --------------------------------------
;
RWGIDE: INC  HL
        SET  7,(HL)
        DEC  HL
RWFLO:  XOR  A
        LD   (DF51C),A
        CALL LF024
        LD   A,(DF51C)
        RET
;
LF024:  LD   C,(HL)
        CALL LEFFA
        JP   Z,LF0E1
        LD   A,C
        CP   06H
        LD   A,01H
        JR   NZ,LF033
        XOR  A
LF033:  LD   (DF51D),A
        CALL LF000
        LD   B,A
        LD   HL,(SECTOR)
LF03D:  SRL  H
        RR   L
        DJNZ LF03D
        LD   (DF518),HL
        LD   HL,DF51A
        LD   A,(HL)
        LD   (HL),01H
        OR   A
        JR   Z,LF075
        LD   A,(DRIVE)
        LD   HL,DRV2
        CP   (HL)
        JR   NZ,LF06E
        LD   HL,(TRK2)
        LD   DE,(TRACK)
        SBC  HL,DE
        JR   NZ,LF06E
        LD   HL,(SEC2)
        LD   DE,(DF518)
        SBC  HL,DE
        JR   Z,LF08D
LF06E:  LD   A,(DF51B)
        OR   A
        CALL NZ,LF0CE
LF075:  LD   HL,DRIVE
        LD   DE,DRV2
        LD   BC,9         ;9 Bytes kopieren
        LDIR
        LD   HL,(DF518)
        LD   (SEC2),HL
        CALL LF0D1
        XOR  A
        LD   (DF51B),A
LF08D:  CALL LF000
        INC  HL
        LD   A,(SECTOR)
        AND  (HL)
        RRA
        LD   H,A
        LD   A,00H
        RRA
        LD   L,A
        LD   DE,DISKP
        ADD  HL,DE
        LD   DE,(DMA)
        LD   A,(DF51D)
        OR   A
        JR   NZ,LF0AE
        INC  A
        LD   (DF51B),A
        EX   DE,HL
LF0AE:  LD   BC,0080H
        LDIR
        LD   A,(DF51C)
        OR   A
        JR   NZ,LF0C9
        LD   A,(DF51E)
        DEC  A
        RET  NZ
        LD   (DF51B),A
        CALL LF0CE
        LD   A,(DF51C)
        OR   A
        RET  Z
LF0C9:  XOR  A
        LD   (DF51A),A
        RET
;
LF0CE:  LD   A,06H
        DEFB 21H          ;LD HL,043EH -> 21 3E 04
LF0D1:  LD   A,04H  
        LD   (MERKRW),A
        LD   HL,DISKP
        LD   (DMA2),HL
        LD   HL,DRV2
        JR   LF0EA
;
LF0E1:  LD   A,(RWBYTE)
        LD   (MERKRW),A
        LD   HL,DRIVE
LF0EA:  LD   DE,DRV3
        LD   BC,9         ;9 Bytes kopieren
        LDIR
        LD   A,(DRV3)
        RLA
        JP   C,GIDERW     ;GIDE
        LD   A,(TRK3+1)
        LD   HL,SEC3+1
        OR   (HL)
        JP   NZ,LF1C1
        CALL LF000
        LD   (DF4E8),A
        OR   A
        LD   A,0FFH
        JR   Z,LF110
        LD   A,80H
LF110:  LD   (DF4EB),A
        INC  HL
        INC  HL
        LD   A,(HL)
        LD   (DF4E9),A
        LD   A,(SEC3)
        CP   (HL)
        JR   C,LF123
        SUB  (HL)
        LD   BC,0104H
LF123:  INC  A
        LD   (DF4E7),A
        INC  HL
        LD   A,(HL)
        LD   (DF4EA),A
        INC  HL
        LD   A,(TRK3)
        CP   (HL)
        JR   C,LF137
        SUB  (HL)
        LD   BC,0104H
LF137:  LD   (DF4E5),A
        INC  HL
        LD   A,(HL)
        OR   C
        LD   (DF4E4),A
        LD   A,B
        LD   (DF4E6),A
        INC  HL
        LD   A,(MERKRW)
        LD   D,05H
        CP   06H
        JR   Z,LF150
        LD   D,06H
LF150:  LD   A,(HL)
        AND  40H
        OR   D
        LD   (DF4E2),A
        LD   DE,DF4EC
        LD   BC,0004H
        LDIR
        LD   C,02H
LF161:  LD   B,02H
LF163:  PUSH BC
        CALL LF175
        POP  BC
        OR   A
        RET  Z
        DJNZ LF163
        DEC  C
        RET  Z
        PUSH BC
        CALL LF1D5
        POP  BC
        JR   LF161
;
LF175:  LD   A,03H
        LD   B,02H
        LD   HL,CTAB      ;FDC Befehlsbyte
        OUT  (DFDC),A     ;Datenport FDC
        CALL LF230
        CALL LF1E7
        JR   NZ,LF1C1
        LD   HL,0040H
        LD   A,(DF4E8)
        INC  A
LF18D:  ADD  HL,HL
        DEC  A
        JR   NZ,LF18D
        DEC  HL
        INC  H
        INC  L
        PUSH HL
        LD   HL,(DMA3)
        PUSH HL
        LD   A,(DF4E2)
        LD   C,A
        LD   B,09H
        RRCA
        LD   A,51H
        ADC  A,A
        LD   (MODE0),A    ;A2 --> INI
        LD   (MODE1),A    ;A3 --> OUTI
        DI
        CALL LF227
        POP  HL
        POP  DE
        LD   B,E
        LD   C,DFDC       ;Datenport FDC
        CALL RW           ;FDC RW-Routine
        EI
        CALL LF1C8
        LD   HL,DF4F0
        LD   A,(HL)
        AND  0C0H
        JR   Z,LF1C3
LF1C1:  LD   A,0FFH
LF1C3:  LD   (DF51C),A
        OR   A
        RET
;
LF1C8:  LD   B,07H
        LD   HL,DF4F0
LF1CD:  CALL RBYTE
        LD   (HL),A
        INC  HL
        DJNZ LF1CD
        RET
;
LF1D5:  LD   BC,0207H     ;Spur 0 einstellen
        CALL LF227
        CALL SENSE
        RET  Z
        LD   BC,0207H
        CALL LF227
        JR   SENSE
;
LF1E7:  LD   A,(DF4E5)
        LD   (DF4F7),A
        OR   A
        JR   Z,LF1D5
        LD   BC,030FH
        LD   HL,DF4EC
        BIT  4,(HL)
        JR   Z,LF1FE
        ADD  A,A
        LD   (DF4E5),A
LF1FE:  CALL LF227
        LD   A,(DF4F7)
        LD   (DF4E5),A
SENSE:  LD   BC,0108H
        CALL LF227
        CALL RBYTE
        LD   B,A
        LD   (DF4F0),A
        CP   80H
        CALL NZ,RBYTE     ;PCN holen
        BIT  5,B          ;SEEK Ende?
        JR   Z,SENSE
        LD   A,B
        AND  0F0H
        CP   0C0H
        JR   Z,SENSE
        XOR  20H
        RET
;
LF227:  PUSH BC
        CALL LF285
        POP  BC
LF22C:  LD   HL,DF4E3
        LD   (HL),C
LF230:  LD   C,41H
        PUSH DE
LF233:  LD   DE,1FFFH
LF236:  LD   A,E
        OR   D
        JR   Z,LF247      ;Abbruch nach 8192 Versuchen
        IN   A,(CFDC)     ;Lese Hauptstatusregister
        AND  0C0H
        CP   80H          ;FDC bereit zum Schreiben?
        DEC  DE
        JR   NZ,LF236     ;noch nicht bereit
        OUTI              ;1 Byte --> FDC
        JR   NZ,LF233     ;Wdhlg., bis B=0
LF247:  LD   B,00H
        POP  DE
        RET
;
RBYTE:  PUSH HL           ;1 Byte lesen
        LD   HL,1FFFH
RBYTE1: LD   A,L
        OR   H
        LD   A,0C0H
        JR   Z,RBYTE2     ;Abbruch nach 8192 Versuchen
        IN   A,(CFDC)     ;Lese Hauptstatusregister
        AND  0C0H
        CP   0C0H         ;FDC bereit zum Lesen?
        DEC  HL
        JR   NZ,RBYTE1    ;noch nicht bereit
        IN   A,(DFDC)     ;1 Byte vom FDC lesen --> A
RBYTE2: POP  HL
        RET
;
;
;       FDC READ/WRITE Routine
;       ----------------------
;
RW:     LD   A,(LATPU)
        SET  1,A
        OUT  (LATCH),A    ;WAIT-Freigabe
RW01:   IN   A,(CFDC)     ;Lese Hauptstatusregister
        RLCA
        JR   NC,RW01      ;FDC noch nicht bereit
        DEFB 0EDH         ;ED A2 = INI
MODE0:  DEFB 0A2H         ;ED A3 = OUTI
        NOP
RW02:   OUT  (FLWAIT),A   ;WAIT bis Interrupt FDC
        NOP
        DEFB 0EDH         ;ED A2 = INI
MODE1:  DEFB 0A2H         ;ED A3 = OUTI
        JP   NZ,RW02
        DEC  D
        JP   NZ,RW02
        LD   A,(LATPU)
        SET  4,A          ;Terminal Count
        OUT  (LATCH),A    ;TC + WAIT-Sperrung
        RET
;
LF285:  LD   HL,DF4F8
        LD   A,(DF4E4)
        AND  03H
        CP   (HL)
        LD   (HL),A
        INC  HL
        LD   C,(HL)
        LD   (HL),48H
        PUSH AF
        PUSH HL
        LD   HL,LATPU
        LD   A,(DF4E4)
        AND  03H
        JR   Z,LF2A7
        CP   02H
        JR   Z,LF2A7
        SET  3,(HL)       ;Floppy-LW 1: Motor an
        JR   LF2A9
;
LF2A7:  SET  0,(HL)       ;Floppy-LW 0: Motor an
LF2A9:  LD   A,(HL)
        OUT  (LATCH),A
        POP  HL
        POP  AF
        JR   NZ,LF2B4
        LD   A,C
        AND  A
        JR   NZ,LF2BD
LF2B4:  LD   A,48H
        SRL  A
        SRL  A
        CP   (HL)
        JR   C,LF2B4
LF2BD:  LD   A,(HL)
        AND  A
        JR   NZ,LF2C9
        PUSH HL
        LD   HL,DISCTX
        CALL OUTTXT
        POP  HL
LF2C9:  PUSH BC
        PUSH HL
        LD   BC,0204H
        CALL LF22C
        CALL RBYTE
        POP  HL
        POP  BC
        BIT  5,A
        JR   Z,LF2BD
        LD   (HL),90H
        RET
;
DISCTX: DEFM ' DISC?'
        DEFB 8,8,8,8,8,8
        NOP
;
;
; Interrupteinsprung von CTC Kanal 3
;
ISRCTC: DI                ;DI hat gefehlt, wurde ergaenzt
        PUSH AF
        LD   A,(CTCCNT)   ;CTC-Zusatzzaehler lesen
        AND  A
        JR   Z,ISRCTE     ;bei "0", die Fkt. beenden
        ;Beim Start von HRCPM wird CNTCNT per Interrupt von 255 auf 0 heruntergezaehlt.
        ;--> verzoegerte Steuerung von LATPU und LATCH
        DEC  A
        LD   (CTCCNT),A
        JR   NZ,ISRCTE
        PUSH HL           ;Bei 2 MHz CPU-Takt wird nach 8 Sekunden diese Stelle erreicht
        LD   HL,LATPU
        RES  0,(HL)       ;Floppy-LW 0: Motor aus
        RES  3,(HL)       ;Floppy-LW 1: Motor aus
        LD   A,(HL)
        OUT  (LATCH),A    ;Latch auf dem Floppy-Controller ruecksetzen
        POP  HL
ISRCTE: POP  AF
INTEND: EI                ;ist zusaetzlich Einsprungpunkt fuer nicht genutzte Interrupts
        RETI
;
;-------------  R/W GIDE HW  -----------------------------------------------------------

GIDERW: IN   A,(P8F)      ;Command / Status
        RLA               ;Bit 0 = CY
        JR   C,GIDERW     ;wait for hard disk ready (non-busy)
        LD   L,19H
        CALL LF002
        LD   C,A
        LD   HL,(SEC3)
        INC  HL
        XOR  A
        LD   B,A
LF318:  INC  A
        SBC  HL,BC
        JR   Z,LF31F
        JR   NC,LF318
LF31F:  ADD  HL,BC
        DEC  A
        LD   D,A
        LD   E,L
        LD   L,11H
        CALL LF002
        OR   D
        OUT  (P8E),A      ;Drive and Head
        LD   A,E
        OUT  (P8B),A      ;Sector Number
        INC  HL
        LD   E,(HL)
        INC  HL
        LD   D,(HL)
        LD   HL,(TRK3)
        ADD  HL,DE
        LD   A,L
        OUT  (P8C),A      ;Cylinder Low
        LD   A,H
        OUT  (P8D),A      ;Cylinder High
        LD   A,01H
        OUT  (P8A),A      ;Sector Count
        LD   A,(MERKRW)
        CP   06H
        JR   Z,LF35D      ;6 = schreiben
;
;  GIDE lesen 1 Sektor = 512 Bytes nach Puffer
;
        LD   A,20H        ;Read Sector
        OUT  (P8F),A      ;Command / Status
LF34B:  IN   A,(P8F)      ;Command / Status
        BIT  3,A
        JR   Z,LF34B      ;wait resp. DRQ active.
        LD   HL,(DMA3)
        LD   BC,0088H     ;B = 0 (counter), C = I/O address (Data Register)
        INIR
        INIR              ;512 bytes gesamt lesen
        JR   LF376
;
;  GIDE schreiben 1 Sektor = 512 Bytes von Puffer
;
LF35D:  LD   A,30H        ;Write Sector
        OUT  (P8F),A      ;Command / Status
LF361:  IN   A,(P8F)      ;Command / Status
        RLA               ;Bit 0 = CY
        JR   C,LF361      ;wait for hard disk ready (non-busy)
LF366:  IN   A,(P8F)      ;Command / Status
        BIT  3,A
        JR   Z,LF366      ;wait resp. DRQ active.
        LD   HL,(DMA3)
        LD   BC,0088H     ;B = 0 (counter), C = I/O address (Data Register)
        OTIR             
        OTIR              ;512 bytes gesamt schreiben 
;        
LF376:  IN   A,(P8F)      ;Command / Status
        RLA               ;Bit 0 = CY
        JR   C,LF376      ;wait for hard disk ready (non-busy)
        IN   A,(P8F)      ;Command / Status
        AND  89H          ;10001001b - busy, DRQ, or error?
        RET  Z            ;no: all is fine, mit A=0
        LD   A,0FFH
        LD   (DF51C),A
        RET               ;on errors, return with A=FFh
;
;-----------------  ENDE GIDE HW  ------------------------------------------
;
        DEFM "CONIN-ZBIOS-STACK==26BYTES"
        DEFM "CONIN-ZBIOS-STACK==26BYTES"
CINSP:  DEFM "CONOUT-STACK_CONOUT-STACK_CONOUT-STACK"
COUTSP: DEFM "ZBIOS(C)ML-SOFT 2003 & AC1-BIOS(C)HR 2011"
CPMSTK: NOP
;
;******************************  Ende CP/M-Stack  ******************************
;
COLOR:  DEFB 0            ;Merkzelle aktuelle BWS-Farbe (0=Monochrom)
COLO1:  DEFB 0            ;aktuelle Farbe ohne invers und intensiv
COLO2:  DEFB 0            ;Farbe fuer Monitor und CP/M Warmstart
;
RAFTRK: DEFB 0            ;RAFTRK EQU 0F4C2H
RAFSEC: DEFB 0
;
CUFLAG: DEFB 1            ;CUON/CUOFF  KursorFlag
STZ00:  DEFB 0            ;Merkzelle Anz. BS-Steuerzeichen
STZ01:  DEFB 0            ;Merkzelle fuer 1. ESC-Steuerzeichen
STZ02:  DEFB 0            ;Merkzelle fuer 2. ESC-Steuerzeichen
;
CHAR:   DEFB 0            ;Merkzelle Zeichen <> Cursor
;
SPCIN:  DEFW 0            ;Merkzelle Stackpointer waehrend CONIN
SPCOUT: DEFW 0            ;Merkzelle Stackpointer waehrend CONOUT
OLDNMI: DEFW 0            ;2 Bytes fuer alten NMI
;
DF4E2:  NOP
DF4E3:  NOP               ;Merkzelle
DF4E4:  NOP
DF4E5:  NOP
DF4E6:  NOP
DF4E7:  NOP
DF4E8:  NOP
DF4E9:  NOP
DF4EA:  NOP
DF4EB:  NOP
;
DF4EC:  NOP               ;4 Merkzellen  
        NOP
CTAB:   NOP               ;FDC Befehlsbyte
        NOP               ;4 Merkzellen Ende
;
DF4F0:  NOP
DF4F7:  NOP
DF4F8:  NOP
CTCCNT: DEFB 0            ;CTC-Counter - Zusatzzaehler fuer CTC-Interrupt
LATPU:  DEFB 0            ;Latch fuer den Floppy-Controler
;
;hier beginnt eine Bytefolge fuer Read/Write Operationen
;
RWBYTE: DEFB 4            ;4 = READ, 6 = WRITE
DRIVE:  DEFB 0            ;LW-Nr.
TRACK:  DEFW 0            ;akt. Track
SECTOR: DEFW 0            ;akt. Sektor
DMA:    DEFW 0            ;DMA-Adresse
DPH:    DEFW 0            ;akt. DPH
;
DRV2:   DEFB 0            ;9 Bytes Kopie ab DRIVE:
TRK2:   DEFW 0
SEC2:   DEFW 0
DMA2:   DEFW 0            ;DMA-Adresse
        DEFW 0
;
DRV3:   DEFB 0            ;9 Bytes Kopie ab DRIVE:
TRK3:   DEFW 0
SEC3:   DEFW 0
DMA3:   DEFW 0            ;DMA-Adresse
DPH3M:  DEFW 0            ;Merkzelle akt. DPH
;
MERKRW: DEFB 4            ;Merkzelle: 4 = READ, 6 = WRITE
DF518:  DEFW 0
DF51A:  DEFB 0
DF51B:  DEFB 0
DF51C:  DEFB 0
DF51D:  DEFB 0
DF51E:  DEFB 0
;
DISKP:  DEFS 1024,0       ;HW-Sektor Puffer aller LW (1k max. fuer FDD)
DIRBF:  DEFS 128,0        ;1 REC Puffer fuer Direktory
ALL00:  DEFS 128,0        ;2048k(max.) / 2k / 8 = 128
ALL01:  DEFS 50,0         ;0F99FH
ALL02:  DEFS 504,0        ;0F9D1H
ALL03:  DEFS 256,0        ;0FBC9H
ALL04:  DEFS 256,0        ;0FCC9H
ALL05:  DEFS 50,0         ;0FDC9H
ALL06:  DEFS 50,0         ;0FDFBH
CHK01:  DEFS 32,0         ;0FE2DH
CHK05:  DEFS 32,0         ;0FE4DH
CHK06:  DEFS 32,0         ;0FE6DH
;
        DEFM "BIOS-Ende"  ;nur fuer Frieder zur Info
;
;
DFF80   EQU  0FF80H       ;Interrupt-Einsprungpunkt CTC Kanal 0
DFF82   EQU  0FF82H       ;Interrupt-Einsprungpunkt CTC Kanal 1
DFF84   EQU  0FF84H       ;Interrupt-Einsprungpunkt CTC Kanal 2
DFF86   EQU  0FF86H       ;Interrupt-Einsprungpunkt CTC Kanal 3
DFF88   EQU  0FF88H       ;Interrupt-Einsprungpunkt Nr.1 PIO1A
DFF8A   EQU  0FF8AH       ;Interrupt-Einsprungpunkt Nr.2 PIO1A
;
;******************************   PortAdressen   ******************************
;
P00     EQU  00H          ;CTC Kanal 0
P01     EQU  01H          ;CTC Kanal 1
P02     EQU  02H          ;CTC Kanal 2
P03     EQU  03H          ;CTC Kanal 3
;
P04     EQU  04H          ;PIO_A-Daten
P05     EQU  05H          ;PIO_B-Daten
P06     EQU  06H          ;PIO_A-Control
;
P1E     EQU  1EH          ;CP/M - Umschalter
;
P8A     EQU  8AH          ;GIDE Sector Count
P8B     EQU  8BH          ;GIDE Sector Number
P8C     EQU  8CH          ;GIDE Cylinder Low
P8D     EQU  8DH          ;GIDE Cylinder High
P8E     EQU  8EH          ;GIDE Drive and Head
P8F     EQU  8FH          ;GIDE Command/Status
;
        .DEPHASE
        END
;
