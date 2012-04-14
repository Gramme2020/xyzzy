@echo off
setlocal
call "%VS100COMNTOOLS%\vsvars32.bat"

if "%1"=="" (set CONFIGURATION=Release) else (set CONFIGURATION=%1)
if "%2"=="" (set TARGET=Build) else (set TARGET=%2)
if "%3"=="" (set VERBOSITY=normal) else (set VERBOSITY=%3)

echo Build xyzzy...
msbuild xyzzy.sln /nologo /p:Configuration=%CONFIGURATION% /target:%TARGET% /verbosity:%VERBOSITY% || exit /b 1

echo Byte compile...

rem startup.lc �����u���݂���t�@�C�����쐬���邱�Ƃ͏o���܂���v�ƌ�����
rem ���܂ɃG���[�ɂȂ�̂ō폜
del /S /Q lisp\startup.lc 2> nul

del /S /Q xyzzy.wxp 2> nul
set XYZZYHOME=%~dp0
xyzzy.exe -load misc/makelc.l -e "(makelc t)" -f kill-xyzzy
del /S /Q xyzzy.wxp 2> nul
