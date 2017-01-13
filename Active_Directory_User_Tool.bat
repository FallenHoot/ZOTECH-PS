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
REM # Enviroment name: (Example: NO-AGR)
Set envname=NO-ESP
REM # Location of the OU before the User OU
Set CompanyOU=Espen AS
REM # Location of the User OU
Set Usersaccountpath=Users
REM # Location of the Folder you are in now
Set CompanyFolder=Espen_AS


cd %~dp0
set BASEDIR=%CD%
powershell.exe -windowstyle hidden -executionpolicy remotesigned -NoProfile -File "%BASEDIR%\%CompanyFolder%\Active_Directory_user_Tool.ps1" "%envname%" "%CompanyOU%" "%Usersaccountpath%"