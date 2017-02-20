Function Menu{
#----------------------------------------------------------
#DYNAMIC VARIABLES
#----------------------------------------------------------
cls
$Title="SFTP & FTP Menu"
Write-Host "================ $Title ================"  -Fore Magenta

Write-Host "`n Choose SFTP Location:" -Fore Cyan
[int]$global:Menu = 0
while ( $global:Menu -lt 1 -or $global:Menu -gt 4 ){
Write-host "1. Option 1" -Fore Cyan
Write-host "2. Option 2" -Fore Cyan
Write-host "3. Option 3" -Fore Cyan
Write-host "4. Option 4" -Fore Cyan
[Int]$global:Menu = read-host "Choose an option 1 to 4" }
Switch( $global:Menu ){
  1{$global:FTPdirectory= "Test1/"}
  2{$global:FTPdirectory= "Test2/"}
  3{$global:FTPdirectory= "Test3/"}
  4{$global:FTPdirectory= "Test4/"}
}
$Global:source = "ftp://USERNAME:PASSWORD@EXTERNALIP/$global:FTPdirectory"
$Global:target = "C:\SFTP\$global:FTPdirectory"
}

Function Get-FTP{
Function FTPdirectory{
    $request = [Net.WebRequest]::Create($Global:source)
    $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory
    $response = $request.GetResponse()
    $reader = New-Object IO.StreamReader $response.GetResponseStream() 
	$reader.ReadToEnd()
	$reader.Close()
	$response.Close()
}

if(!(Test-Path -Path $Global:target )){
    New-Item -ItemType directory -Path $Global:target
}

$WebClient = New-Object System.Net.WebClient
$files=FTPdirectory | Out-String
$files = $files.replace("`r",",")
$files = $files.replace("`n","")
$files = $files.trimend(",")
$array = $files -split ","

Foreach ($file in ($array | where {$_ -like "*"})){
	$source=$Global:source+$file 
    $target=$Global:target+$file
	$WebClient.DownloadFile($source, $target)
    Write-Host "Downloaded: $file"
}
}
Menu
Get-FTP