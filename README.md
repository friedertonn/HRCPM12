# HRCPM12
Assemblercode von HRCPM12 für den AC1-2010

HRCPM12 ist ein CP/M V2.2 kompatibles Betriebssystem und wurde von Ralph Hänsel für den AC1 entwickelt.
Es besteht aus drei Teilen: CCP, BDOS und BIOS.
Das BIOS ist an die Hardware des AC1-2010 angepasst.
Der CCP beginnt auf Adresse 0D000h, die Startadresse ist 0E600h.

Für den CCP und das BDOS wurden CP/A-Assemblerquellen von Volker Pohlers verwendet:
https://hc-ddr.hucki.net/wiki/doku.php/cpm/cpa

Im BIOS wurden eine Reihe von Änderungen (Fehlerbehebung und neue Features) vorgenommen:
- Maskierung des USER-Bytes in WBOOT entfernt
- GIDE-Laufwerke (C:, D:, E:) auf 8 MByte begrenzt
- Konsolenkommandos: Kursor-ON / Kursor-OFF
- Kursorblinken im Texteditor
- Automatische Erkennung der RAM-Disk-Größe: 256 / 512 / 1024 / 2048 KByte
- Fehlermeldung *Bdos Err On P: Select* behoben

Das Assemblieren des Quellcodes erfolgt mit SUBMIT.COM:
```
SUBMIT CPM
```

Kompilierte Binarys sind unter https://github.com/friedertonn/HRCPM12/releases zu finden.

Nachfolgend ein Bildschirmcopy von HRCPM12 im JKCEMU:

![Bildschirmcopy von HRCPM12](https://github.com/friedertonn/HRCPM12/blob/main/Fotos/HRCPM12.png?raw=true)
