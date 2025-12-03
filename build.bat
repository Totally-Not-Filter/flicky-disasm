@echo off
if exist flicky.bin move /y flicky.bin flicky.prev.bin >NUL
tools\asw -xx -q -A -L -E -i . flicky.asm
tools\p2bin -p=FF flicky.p flicky.bin
del flicky.p
tools\fixheader flicky.bin
pause