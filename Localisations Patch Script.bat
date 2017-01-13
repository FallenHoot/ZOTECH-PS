@echo off
:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------
REM --------> PARAMS <--------
REM ***************************
REM --------> File Structure <--------
REM ***************************
Set APPx86=x86
Set APPx64=x64
Set CCC=BusinessWorld
REM --------> Agresso Structure <--------
REM ***************************
Set dataSource=M6
Set agressoLogin=sysno
REM --------> Services <--------
REM ***************************
Set Service32=Business World 6.0.0 Server - M6
Set Service64=Business World 6.0.0 Server (x64) - M6

:--------------------------------------
cd %~dp0..\..\
set BASEDIR=%CD%

ECHO ******************* START FixUnblock *******************
"%BASEDIR%\%APPx86%\updates\extra\streams.exe" -s -d "%BASEDIR%\%APPx86%\Updates\*.*"
ECHO ******************* STOP FixUnblock *******************

ECHO ******************* STOP Agresso Services *******************
SET SERVICE=
SET /P SERVICE=Do you want to turn off the %Service32% and %Service64%? (s)top or (i)gnore:  %=%
if '%SERVICE%' NEQ 'i' (
sc stop "%Service32%"
sc stop "%Service64%"
    goto :AGRESSO
) else ( goto :AGRESSO )

:AGRESSO
SET patchfile=
SET /P patchfile=Enter the patch date here YYYYMM? :  %=%
set STARTTIME=%TIME%
Powershell.exe -executionpolicy Unrestricted -NoProfile -File "D:\app\Agresso\x86\Updates\extra\Localisation.ps1" "%APPx86%" "%APPx64%" "%dataSource%" "%agressoLogin%" "%CCC%" "%patchfile%"
set ENDTIME=%TIME%
pause
echo.
echo.
echo STARTTIME: %STARTTIME%
echo ENDTIME: %ENDTIME%
echo.
echo.
pause
echo.
ECHO ******************* STOP Agresso Services *******************
if '%SERVICE%' NEQ 'i' (
sc start "%Service32%"
sc start "%Service64%"



