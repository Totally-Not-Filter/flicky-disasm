@echo off
call tools/md5.bat flicky.bin md5
if "%md5%" equ "805cc0b3724f041126a57a4d956fd251" (
      echo MD5 identical!
) else (
      echo MD5 does not match.
)
pause