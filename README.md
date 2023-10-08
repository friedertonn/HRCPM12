# HRCPM12
Assemblercode von HRCPM12 für den AC1-2010

HRCPM12 ist ein CP/M V2.2 kompatibles Betriebssystem und wurde von Ralph Hänsel für den AC1 entwickelt.
Es besteht aus drei Teilen: CCP, BDOS und BIOS.
Das BIOS ist an die Hardware des AC1-2010 angepasst.
Der CCP beginnt auf Adresse 0D000h, der Einsprung ins BIOS ist Adresse 0E600h.

Für den CCP und das BDOS wurden CP/A-Assemblerquellen von Volker Pohlers verwendet:
https://hc-ddr.hucki.net/wiki/doku.php/cpm/cpa

Zum Assemblieren des Quellcodes erfolgt mit SUBMIT.COM: **SUBMIT CPM**

Nachfolgend ein Bildschirmcopy von HRCPM12 im JKCEMU V0.9.7:
![Bildschirmcopy von HRCPM12](https://github.com/friedertonn/HRCPM12/blob/main/Fotos/HRCPM12.png?raw=true)
