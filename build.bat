64tass -a -O -o firefighterJenny.prg --dump-labels -l firefighterJenny.tass -L ffj.list firefighterJenny.asm
@IF ERRORLEVEL 1 GOTO end
cscript D:\pathstuff\dumpToViceLocal.vbs firefighterJenny.tass firefighterJenny.vice
exomizer sfx sys -n -q firefighterJenny.prg sprites.prg -o ffj.prg
@echo off
FOR /F "usebackq" %%A in ('ffj.prg') DO set size=%%~zA
if %size% LSS 4096 GOTO end
echo on
echo File Too Large  
:end