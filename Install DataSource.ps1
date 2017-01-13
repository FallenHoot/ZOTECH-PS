############################################################################
## Purpose: Create Agresso DataSource and Setup Agresso                   ##
## Author: Zach Olinske                                                   ## 
## Date: 27/12/2016                                                       ##
## Company: UNIT4 Cloud                                                   ##
## Version: 1.0                                                           ##
############################################################################
param([switch]$Elevated)

function Test-Admin {
  $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) 
    {
        # tried to elevate, did not work, aborting
    } 
    else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
}

exit
}

'running with full privileges'
set-executionpolicy remotesigned


##Use the Agresso PowerTools features to load and use Agresso.Management.PowerShell
Add-pssnapin Agresso.Management.PowerShell -erroraction silentlycontinue
Import-Module -Name "AgressoPowerTools" -erroraction silentlycontinue
Import-AgressoModule -erroraction silentlycontinue

#----------------------------------------------------------
#Functions
#----------------------------------------------------------


#GOGO is a function that starts the other functions.
Function GOGO{
FileStructure
CreateDataSource
AppConfig
AddUBWUpdates
AddTitleUpdates
CreateCCC
Cleanup
}

#Creates File Structure and starts a log
Function FileStructure
{
$Test=Test-Path "c:\SEcloud\$global:env$global:CustomerNumber\"
		if ($Test -eq $TRUE){
        $Title="File Structure Was already Created"
        Write-Host "================ $Title ================"
		Exit
		}
		Else{
        $Title="File Structure Was Created"
        Write-Host "================ $Title ================"
		New-Item -ItemType directory -Path C:\SEcloud\$global:env$global:CustomerNumber\

		}
}

#Creates the UBW DataSource
Function CreateDataSource
{
cd 'Agr:\Datasources'
# Check if already exists, exit if yes
$Test2=Test-Path "$global:DSname"
			if ($Test2 -eq $TRUE){
			Write-Host "DataSource has been aborted, because DataSource was already created"   
			exit
			}
Else{ 

# Create Datasource
$ds = New-Item -Name $global:DSname -Type MSSQL 
$ds.ServerName = $global:DBServerName
$ds.DatabaseName = $global:DBname
$ds.UserName = $global:DBUsername
$ds.Password = "$global:DBPassword"
$ds.Save() |out-null

write-host "Datasource $global:DSname created.  Check $outfile"
}
}

#Configures the UBW Application
Function AppConfig
{ 
start-transcript -path "c:\SEcloud\" + $global:env + $global:CustomerNumber + "_Datasource_configuration.txt"
		$outfile = "c:\SEcloud\"+ $global:env + $global:CustomerNumber + "\" + $global:env + $global:CustomerNumber +"_APPconfiguration.txt"
$Versions=Test-Path "HKLM:\SOFTWARE\Wow6432node\UNIT4\Business World 6.0.0"
			if ($Versions -eq $TRUE){
			$regpath = "HKLM:\SOFTWARE\Wow6432node\UNIT4\Business World 6.0.0"
            $global:AgrFilesRoot = Get-ItemProperty -Path $regpath -Name InstallPath
			}
				Else{
                    $regpath = "HKLM:\SOFTWARE\Wow6432node\UNIT4\Agresso 5.7.2" 
                    $global:AgrFilesRoot = Get-ItemProperty -Path $regpath -Name InstallPath
}

$global:AgrFilesRoot = $global:AgrFilesRoot.InstallPath


######################  APPLICATION SERVER ########################
cd 'Agr:\Datasources'

# Mount Datasource as new PS Drive

New-AgrDsDrive -Name $global:DSname -LoginType DB -UserName $global:DBUsername -Password $global:DBPassword

# Create ODBC Connections

write-host "Creating ODBC connections"

if (test-path ("HKLM:\SOFTWARE\ODBC\ODBC.INI\AgrDbUtilOdbc_" + $global:DSname)) {
        	del HKLM:\SOFTWARE\ODBC\ODBC.INI\AgrDbUtilOdbc_$global:DSname -recurse
    	}
if (test-path ("HKLM:\SOFTWARE\Wow6432Node\ODBC\ODBC.INI\AgrDbUtilOdbc_" + $global:DSname)) {
        	del HKLM:\SOFTWARE\Wow6432Node\ODBC\ODBC.INI\AgrDbUtilOdbc_$global:DSname -recurse
    	}

Add-AgrOdbc -Name $("AgrDbUtilOdbc_" + $global:DSname) -ServerName $global:DBServerName -Database $global:DBname -Duplicate -DriverName "SQL Server" 


# Initialise Business Server
write-host "Initialising Business Server"

cd $($global:DSname + ":\Features")

$bs = get-item ".\BusinessServer"
if ($bs.isinitialized) { $bs.uninitialize() }
$bs.Initialize($($global:AgrFilesRoot + "Bin"), $global:DataFilesRoot)
$bs.ConnectInfo = $("AgrDbUtilOdbc_" + $global:DSname)
$bs.Save() |out-null


# Set File / DB Cleanup to on, keep 999 of each report
$bs = get-item ".\BusinessServer"
$bs.CleanUpRoutines.CleanUpMode = "Orders"
$bs.CleanUpRoutines.CleanUpKeep = 500
$bs.CleanUpRoutines.ProcessInfoKeep = 48;
$bs.CleanUpRoutines.DeleteFiles = $true;
$bs.CleanUpRoutines.Save() |out-null


# Move Customised Reports, Report Writer, Command Files, Stylesheets folders, update global:env variables
robocopy ('"' + $global:AgrFilesRoot + "Command Files" + '"') ('"' + $global:DataFilesRoot + "\Command Files" + '"') /e
robocopy ('"' + $global:AgrFilesRoot + "Customised Reports" + '"') ('"' + $global:DataFilesRoot + "\Customised Reports" + '"') /e
robocopy ('"' + $global:AgrFilesRoot + "Report Writer" + '"') ('"' + $global:DataFilesRoot + "\Report Writer" + '"') /e
robocopy ('"' + $global:AgrFilesRoot + "Stylesheets" + '"') ('"' + $global:DataFilesRoot + "\Stylesheets" + '"') /e

cd ($global:DSname + ":\Features\BusinessServer\global:envVars")
Set-Item "AGRESSO_COM" -Value $($global:DataFilesRoot + "\Command Files\") -Type Directory
Set-Item "AGRESSO_CUSTOM" -Value $($global:DataFilesRoot + "\Customised Reports\") -Type Directory
Set-Item "AGRESSO_REPORT" -Value $($global:DataFilesRoot + "\Report Writer\") -Type Directory
Set-Item "AGRESSO_STYLESHEET" -Value $($global:DataFilesRoot + "\Stylesheets\") -Type Directory
Set-Item "AGRESSO_PRINT" -Value $($global:DataFilesRoot + "\Report Results\") -Type Directory
Set-Item "AGRESSO_EXPORT" -Value $($global:DataFilesRoot + "\Data Export\") -Type Directory
Set-Item "AGRESSO_IMPORT" -Value $($global:DataFilesRoot + "\Data Import\") -Type Directory
Set-Item "AGRESSO_OCR" -Value $($global:DataFilesRoot + "\OCR Export\") -Type Directory
Set-Item "AGRESSO_LOG" -Value $($global:DataFilesRoot + "\Server Logging\") -Type Directory
Set-Item "AGR_TEMPDB" -Value $($global:env + $global:CustomerNumber + "_T") -Type String -Description "Database for creation of Temporary Tables"
cd ($global:DSname + ":\Features\BusinessServer")
$logger = get-item .\Logger
$logger.Recreate()


# Create Default Report Queue
cd ($global:DSname + ":\Features\BusinessServer\ServerControllers\ReportQueues")
Remove-Item * -Force -Recurse
new-Item -Name DEFAULT -slots 1 |out-null


# Create Timed Processes - TPS, DWS etc.
cd ($global:DSname + ":\Features\BusinessServer\ServerControllers\TimedProcesses")
Remove-Item * -Force -Recurse
new-Item -Name TPS |out-null
new-Item -Name DWS |out-null
new-Item -Name ALGIPS |out-null
new-Item -Name ALGSPS |out-null
new-Item -Name Scheduler |out-null
new-Item -Name AINAPS |out-null
new-Item -Name ACRALS |out-null
new-Item -Name AMS |out-null
new-Item -Name RESRATE |out-null
new-Item -Name IMS |out-null
New-Item -Name LOADSYSDATA
New-Item -Name FILEMOVER -Excutable "$global:AgrFilesRoot\BIN\No.EN86.FileMoverService.exe" -Parameters 'FILEMOVER $global:DSname' -DefaultLogging 1 -HandlesLogging 1 -HandlesBacklog 1
# new-Item -Name COPS |out-null

# Create Service Process - Workflow
cd ($global:DSname + ":\Features\BusinessServer\ServerControllers\ServiceProcesses")
Remove-Item * -Force -Recurse
new-Item -Name Workflow |out-null


# Install Mail Services
Install-AgressoMail -DataSource $global:DSname -FromName $global:DSname -FromAddress $($global:DSname + ".donotreply@u4a.se") -Provider Custom -HostName "ctxadm" -Port 25 -Force
}

#Adds UBW Update to the Database 
Function AddUBWUpdates()
{
    Write-Host "Start applying updates in DB"
    GetUBWDataSource
    #Get the updates-dll name
    $updatePath=(Get-ChildItem "$BASE_DIR\x64\Database Script\AGR*UPDATE.update.dll").FullName
    #Add the update in AMC
    Add-AgrUpdate -FilePath $updatePath -ErrorAction SilentlyContinue | Out-Null
    cd ('DatabaseTools\UpdateManager')
    #Run each step in the update
    Foreach($p in dir)
    {
        invoke-Item $p.GUID  | Out-Null
    }
    cd \
    #Do an extra "Recreate views and triggers" after the update
    $d = Get-Item .\DatabaseTools
    Write-Host "Start recreate views"
    $d.RecreateViewsAndTriggers()  | Out-Null
    Write-Host "Finished recreating views"
    Write-Host "Finished applying updates in DB"
}

#Adds UBW Titles to the Database
function AddTitleUpdates()
{
    Write-Host "Start applying title updates in DB"
    GetUBWDataSource
    #Get folder with latest titles
    $folders = Get-ChildItem "$RealRoot\30 - Latest Titles\AGR*TITLES*TBL" | ?{ $_.PSIsContainer }
    $folder = $folders | Sort Name -Descending | Select -First 1
    $titlesPath="$folder"
    #Run a copy-in on all files in the folder
    Import-AgrData $titlesPath | Out-Null
    Write-Host "Finished applying title updates in DB"
}

#Configures the CCC and sends to shared client folder
Function CreateCCC
{
# Create Central Configured Client

write-host "Creating Central Config"

New-AgrCentralConfig -Name $global:DSname -ShareDescription "Agresso Desktop" -ShareName ("$global:DSname") -DataSourceName $global:DSname 
cd ($global:DSname + ":\Features\CentralConfig")
	$ccc = Get-Item $global:DSname
    $ccc.DisplayName = $global:DSname
    $ccc.Save()
	
# Create EventServer Service

#New-AgrServiceHost -Type "EventServer" -StartMode "Disabled"


# Create DocArchiveFileStorage Service

#write-host "Creating Doc Archive Folder and Service"

#$docfilespath = ($global:DataFilesRoot + "\DocArchive")

#New-AgrServiceHost -Type "DocArchiveFileStorage" 
#cd ($global:datasource + ":\Features\HostedServices\DocArchiveFileStorage - " + $global:datasource + "\AppSettings")
#$docroot= get-item ".\DocumentArchiveRoot"
#$docroot.Value = $docfilespath
#$docroot.save()
#$docweekno = get-item ".\UseWeekNumber"
#$docweekno.Value = $true
#$docweekno.Save()
}

#Cleanups the PowerShell variables and install folders
Function Cleanup
{
write-host "Start Patch Watcher"
Start-AgressoUpdateWatcher -FolderPath ($global:AgrFilesRoot + "Database Script") *

Remove-AgrDsDrive -Name $global:DSname
set-content $outfile "------------------------------"
add-content $outfile "Datasource Name: $global:DSname"
add-content $outfile "DB Server: $global:DBServerName"
add-content $outfile "DB Name: $global:DBname"
add-content $outfile "DB Username: $global:DBUsername"
add-content $outfile "DB Password: ***********"
add-content $outfile "Datafiles folder: $global:DataFilesRoot"
add-content $outfile "Email address: $global:DSname .noreplyctxadm"
add-content $outfile "Central Config Share: $global:DSname _ccc$"
add-content $outfile "------------------------------"

exit
exit
exit
stop-transcript
}

#Menu functions that as for a list of variables
Function Menu{
#----------------------------------------------------------
#DYNAMIC VARIABLES
#----------------------------------------------------------
## Variables - Fixed
$localmachine = get-content global:env:computername
$domain = get-content global:env:userdomain 

cls
$Title="Customer Info Menu"
Write-Host "================ $Title ================"  -Fore Magenta
Write-Host "Please provide global:environment ((P)roduction, (T)est, (D)ev)" -Fore Cyan
$global:env = Read-Host ":"
Write-Host "Please provide customer number" -Fore Cyan
$global:CustomerNumber = Read-Host ":"
Write-Host "Data Files Location:" -Fore Cyan
[int]$global:DFR = 0
while ( $global:DFR -lt 1 -or $global:DFR -gt 4 ){
Write-host "1. \\esv_agresso.se\UBWDataFiles-prod\$global:CustomerNumber\M5" -Fore Cyan
Write-host "2. \\esv_agresso.se\UBWDataFiles-prod\$global:CustomerNumber\M6" -Fore Cyan
Write-host "3. \\esv_agresso.se\UBWDataFiles-test\$global:CustomerNumber\M5" -Fore Cyan
Write-host "4. \\esv_agresso.se\UBWDataFiles-test\$global:CustomerNumber\M6" -Fore Cyan
[Int]$global:DFR = read-host "Choose an option 1 to 4" }
Switch( $global:DFR ){
  1{$global:DataFilesRoot="\\esv_agresso.se\UBWDataFiles-prod\$global:CustomerNumber\M5"}
  2{$global:DataFilesRoot="\\esv_agresso.se\UBWDataFiles-prod\$global:CustomerNumber\M6"}
  3{$global:DataFilesRoot="\\esv_agresso.se\UBWDataFiles-test\$global:CustomerNumber\M5"}
  4{$global:DataFilesRoot="\\esv_agresso.se\UBWDataFiles-test\$global:CustomerNumber\M6"}
}

 [int]$global:DBSN = 0
while ( $global:DBSN -lt 1 -or $global:DBSN -gt 4 ){
Write-host "1. PD-DBV-DB20\DB20" -Fore Cyan
Write-host "2. PD-DBV-DB21\DB21" -Fore Cyan
Write-host "3. TD-DBV-DB20\DB20" -Fore Cyan
Write-host "4. TD-DBV-DB21\DB21" -Fore Cyan
[Int]$global:DBSN = read-host "Choose an option 1 to 4" }
Switch( $global:DBSN ){
  1{$global:DBServerName= "PD-DBV-DB20\DB20"}
  2{$global:DBServerName= "PD-DBV-DB21\DB21"}
  3{$global:DBServerName= "TD-DBV-DB20\DB20"}
  4{$global:DBServerName= "TD-DBV-DB21\DB21"}
}  
Write-Host "Please provide password for $global:env$global:CustomerNumber" -Fore Cyan
$global:DBPassword = Read-Host ":"

# Trim spaces
$global:DBServerName.Trim |out-null
$global:DBPassword.Trim |out-null
$global:AgrFilesRoot.Trim |out-null
$global:DataFilesRoot.Trim |out-null

$global:DSname = ($global:env + $global:CustomerNumber)
$global:DBname = ($global:env + $global:CustomerNumber)
$global:DBUsername = ($global:env + $global:CustomerNumber)
cls
$Title="Verify Customer Info"
Write-Host "================ $Title ================" -Fore Magenta
Write-Host "Customer Number:        $global:env$global:CustomerNumber" -Fore Cyan
Write-Host "Data File Location:     $global:DataFilesRoot" -Fore Cyan
Write-Host "DB Server & Instance:   $global:DBServerName" -Fore Cyan
Write-Host "DB Password:            $global:DBPassword" -Fore Cyan
$confirmation = Read-Host "Are you sure you want to proceed? [y/n]"
If($confirmation.ToUpper().StartsWith("Y") )
{
    GOGO
}

Else{exit}
}
Menu
