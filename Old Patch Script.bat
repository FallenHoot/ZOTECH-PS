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
REM  Params
Set app=x86
Set app64=x64
Set dataSource=M6
Set agressoLogin=sysno
Set CCC=BusinessWorld
REM  Extra CCC for Test or Other
Set CCC2=
Set CCC3=
Set CCC4=
REM  Turn of Services
Set Service32=Business World 6.0.0 Server - M6
Set Service64=Business World 6.0.0 Server (x64) - M6

REM if you do not want to disable/enable LOADSYSDATA. Remove the REM
REM Set OFF_LOADSYSDATA=REM
:--------------------------------------
cd %~dp0..\..\
set BASEDIR=%CD%

set STARTTIME=%TIME%

ECHO ******************* START FixUnblock *******************
"%BASEDIR%\%app%\updates\extra\streams.exe" -s -d "%BASEDIR%\%app%\Updates\*.*"
ECHO ******************* START FixUnblock *******************

ECHO ******************* Agresso Services *******************
SET SERVICE=
SET /P SERVICE=Do you want to turn off the %Service32% and %Service64%? (s)top or (i)gnore:  %=%
if '%SERVICE%' NEQ 'i' (
sc stop "%Service32%"
sc stop "%Service64%"
    goto :AGRESSO
) else ( goto :AGRESSO )

:AGRESSO
SET INPUT=
SET /P INPUT=Enter the patch date here YYYYMM? :  %=%

SET /P answer=Is the client on a Milestone? y or n :  %=%
if '%answer%' NEQ 'y' (
    goto :553
) else ( goto :M )

:553
ECHO ***** 553 is Running *****
ECHO ***** 553 is Running *****
ECHO ******************* START Install Patch *******************
if not exist "%BASEDIR%\%app%\updates\Unzip" mkdir "%BASEDIR%\%app%\Updates\unzip"
"%BASEDIR%\%app%\updates\extra\7zip32\7za.exe" x -o"%BASEDIR%\%app%\Updates\unzip" "%BASEDIR%\%app%\Updates\%INPUT%\*.zip"
attrib -R /S "%BASEDIR%\%app%\Updates\%INPUT%\*.*"
XCOPY /E /R /Y "%BASEDIR%\%app%\updates\unzip\bin\*.*" "%BASEDIR%\%app%\bin"
XCOPY /E /R /Y "%BASEDIR%\%app%\updates\unzip\Customised Reports\*.*" "%BASEDIR%\%app%\Customised Reports"
XCOPY /E /R /Y "%BASEDIR%\%app%\updates\unzip\NO\*.*" "%BASEDIR%\%app%\NO"
XCOPY /E /R /Y "%BASEDIR%\%app%\updates\unzip\Stylesheets\*.*" "%BASEDIR%\%app%\Stylesheets"
XCOPY /E /R /Y "%BASEDIR%\%app%\updates\unzip\bin\*.*" "%BASEDIR%\%app%\Central Configuration Server\Central Configured Clients\%CCC%\Bin"
del "%BASEDIR%\%app%\updates\unzip\*.txt*" /Q
ECHO *************************************************************************
ECHO *********************** Manual Transfer to CCC **************************
ECHO *************************************************************************
ECHO ** Central Configuration Server\Central Configured Clients\Agresso\Bin **
ECHO *************************************************************************
ECHO *************************************************************************
ECHO *************************************************************************
ECHO *************************************************************************
ECHO ************************** Manual Run Scripts ***************************
ECHO *******************This is the time to edit the scripts******************
ECHO ********************** \unzip\NO\ScriptsNO\Scripts **********************
ECHO               Move files to the CCC before pressing any key
pause
ECHO *************************************************************
ECHO ******************* Remove Unzip folder *********************
ECHO *************************************************************
rmdir /S /Q "%BASEDIR%\%app%\updates\unzip"
ECHO ******************* End Of Install Patch *******************
set ENDTIME=%TIME%
GOTO :end

:M
ECHO ***** M3, M4, M5, M6 is Running *****
ECHO ***** M3, M4, M5, M6 is Running *****
REM  --> Powershell file needs an active AMC User to enable and disable LOADSYSDATA only works on M3, M4, and M5
ECHO ******************* Disable LOADSYSDATA *******************
%OFF_LOADSYSDATA% Powershell.exe -executionpolicy remotesigned -NoProfile -File  "%BASEDIR%\%app%\updates\extra\disableLOADSYSDATA.ps1" "%BASEDIR%" "%app%" "%dataSource%" "%agressoLogin%"
ECHO ******************* Disabled LOADSYSDATA *******************
ECHO ******************* START Install Patch *******************
if not exist "%BASEDIR%\%app%\updates\Unzip" mkdir "%BASEDIR%\%app%\Updates\unzip"
"%BASEDIR%\%app%\updates\extra\7zip\7za.exe" x -o"%BASEDIR%\%app%\Updates\unzip" "%BASEDIR%\%app%\Updates\%INPUT%\*.zip"
attrib -R /S "%BASEDIR%\%app%\Updates\%INPUT%\*.*"
XCOPY /E /R /Y "%BASEDIR%\%app%\updates\unzip\bin\*.*" "%BASEDIR%\%app%\bin"
XCOPY /E /R /Y "%BASEDIR%\%app%\updates\unzip\Customised Reports\*.*" "%BASEDIR%\%app%\Customised Reports"
XCOPY /E /R /Y "%BASEDIR%\%app%\updates\unzip\NO\*.*" "%BASEDIR%\%app%\NO"
XCOPY /E /R /Y "%BASEDIR%\%app%\updates\unzip\Stylesheets\*.*" "%BASEDIR%\%app%\Stylesheets"
XCOPY /E /R /Y "%BASEDIR%\%app%\updates\unzip\bin\*.*" "%BASEDIR%\%app%\Central Configuration Server\Central Configured Clients\%CCC%\Bin"
if not exist "%BASEDIR%\%app%\updates\Unzip\bin86" mkdir "%BASEDIR%\%app%\Updates\unzip\bin86"
XCOPY /E /R /Y "%BASEDIR%\%app%\updates\unzip\bin" "%BASEDIR%\%app%\updates\unzip\bin86"
rmdir /S /Q "%BASEDIR%\%app%\updates\unzip\bin"
del "%BASEDIR%\%app%\updates\unzip\*.txt*" /Q
ECHO *************************************************************************
ECHO *********************** Manual Transfer to CCC **************************
ECHO *************************************************************************
ECHO ** Central Configuration Server\Central Configured Clients\Agresso\Bin **
ECHO *************************************************************************
ECHO *************************************************************************
ECHO *************************************************************************
ECHO *************************************************************************
ECHO ************************** Manual Run Scripts ***************************
ECHO *******************This is the time to edit the scripts******************
ECHO ********************** \unzip\NO\ScriptsNO\Scripts **********************
ECHO            Move files to the CCC before pressing any key
pause
ECHO ******************* Run ASQL Scripts *******************
REM Powershell.exe -executionpolicy remotesigned -File  "%BASEDIR%\%app%\updates\extra\runASQLScript.ps1" "%BASEDIR%" "%app%" "%dataSource%" "%agressoLogin%"
ECHO ******************* Ran ASQL Scripts*******************
ECHO *********************************************************
ECHO ******************* Transfer to x64 *********************
ECHO *********************************************************
rmdir /S /Q "%BASEDIR%\%app%\updates\unzip\bin86"
MOVE "%BASEDIR%\%app%\updates\unzip\bin64" "%BASEDIR%\%app%\updates\unzip\bin"
XCOPY /E /R /Y "%BASEDIR%\%app%\updates\unzip\*.*" "%BASEDIR%\%app64%"
ECHO *************************************************************
ECHO ******************* Remove Unzip folder *********************
ECHO *************************************************************
rmdir /S /Q "%BASEDIR%\%app%\updates\unzip"
ECHO ******************* Enable LOADSYSDATA *******************
%OFF_LOADSYSDATA% Powershell.exe -executionpolicy remotesigned -File  "%BASEDIR%\%app%\updates\extra\enableLOADSYSDATA.ps1" "%BASEDIR%" "%app%" "%dataSource%" "%agressoLogin%"
ECHO ******************* Enabled LOADSYSDATA *******************
ECHO ******************* End Of Install Patch *******************
del "%BASEDIR%\%app%\updates\extra\hidden.txt" /Q
set ENDTIME=%TIME%
GOTO :end

:end
if '%SERVICE%' NEQ 'i' (
sc start "%Service32%"
sc start "%Service64%"
echo STARTTIME: %STARTTIME%
echo ENDTIME: %ENDTIME%
pause
) else (
echo STARTTIME: %STARTTIME%
echo ENDTIME: %ENDTIME%
pause
)