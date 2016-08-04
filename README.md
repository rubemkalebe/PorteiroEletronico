Para montar (assemblar):
avra <arquivo.asm>

Para gravar:
sudo avrdude -C/home/rafael/Dropbox/arduino-1.0/hardware/tools/avrdude.conf -q -q -patmega328p -carduino -P/dev/ttyACM0 -b115200 -D -Uflash:w:blink.hex:i
