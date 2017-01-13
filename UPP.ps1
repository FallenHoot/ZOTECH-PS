Import-Module WebAdministration
#----------------------------------------------------------
#Static VARIABLES
#----------------------------------------------------------
$iisAppName = "PSTEST2"

#----------------------------------------------------------
#DYNAMIC VARIABLES
#----------------------------------------------------------
$iisAppPoolDotNetVersion = "v4.0"
$directoryPath = "D:\"


Function gogo{
Create_AppPool
CreateFileStructure
Create_AppSite
}

Function Create_AppPool{
#navigate to the app pools root
cd IIS:\AppPools\

#Error handling to see if pool exists
$Test=Test-Path $iisAppName
			if ($Test -eq $TRUE){
			Write-Host "Operation has been aborted, because AppPool was already created"   
			}
				Else{ 
					#Create the App Pool
					$appPool = New-Item $iisAppName
					$appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion

					#Fix the Advanced Settings
						foreach ($item in $iisAppName)
							{
							 $ApplicationPoolName = $item.Name
							 $pool = Get-Item $iisAppName
							 $pool.autoStart = 'true'
							 $pool.startmode = 'alwaysrunning'
							 $pool.processModel.idleTimeout = '0'
							 $pool | Set-Item
							}
			Write-Host "AppPool has been Created"
					}
}

Function CreateFileStructure{
#Create File Structure
$Test2=Test-Path $directoryPath$iisAppName
	if ($Test2 -eq $TRUE){
			Write-Host "Operation has been aborted, because directory already exists"   
						}
							Else{ 
							New-Item $directoryPath$iisAppName -type Directory
                            Write-Host "File Structure has been Created"
								}
}

Function Create_AppSite{

#Navigate to the to the Default Web Site
cd "IIS:\Sites\Default Web Site\"

#Error handling to see if App exists
$Test3=Test-Path $iisAppName
if ($Test3 -eq $TRUE){
						Write-Host "Operation has been aborted, because AppSite was already created"   
						}
							Else{ 

								#Create the Web Application
                                New-Item $iisAppName -physicalPath $directoryPath$iisAppName -type Application
                                Set-ItemProperty "$iisAppName" applicationPool  $iisAppName
                                Write-Host "AppSite has been Created"
							}
}
gogo
