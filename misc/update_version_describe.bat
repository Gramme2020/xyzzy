@echo off
setlocal
cd %~dp0\..

set GIT_DESCRIBE=git describe --tags --dirty
set VERSION_DESCRIBE_H=src\version-describe.gen.h
set VERSION_DESCRIBE_TMP=src\version-describe.%RANDOM%.tmp

rem git describe �̏���
rem   (tag)-(tag �ȍ~�̃R�~�b�g��)-g(hash)
rem
rem git describe �� --long ���w�肵�Ȃ��ƃR�~�b�g�񐔂� 0 �̏ꍇ��
rem �^�O�����\������Ȃ�

for /F "usebackq" %%i in (`%GIT_DESCRIBE% --long`) do (
  set DESCRIBE_LONG=%%i
)
for /F "usebackq" %%i in (`%GIT_DESCRIBE%`) do (
  set DESCRIBE=%%i
)

if not "%DESCRIBE%"=="%DESCRIBE_LONG%" (
  rem �����[�X�o�[�W����
  echo. > %VERSION_DESCRIBE_TMP%
) else (
  rem �J���o�[�W����
  echo #define PROGRAM_VERSION_DESCRIBE_STRING "%DESCRIBE%" > %VERSION_DESCRIBE_TMP%
)

if not exist %VERSION_DESCRIBE_H% goto update
fc %VERSION_DESCRIBE_H% %VERSION_DESCRIBE_TMP% > nul
if errorlevel 1 goto update
goto not_update

:update
echo %DESCRIBE%
copy /Y %VERSION_DESCRIBE_TMP% %VERSION_DESCRIBE_H% > nul
goto cleanup

:not_update
goto cleanup

:cleanup
DEL /Q /S %VERSION_DESCRIBE_TMP% > nul
exit /b 0
