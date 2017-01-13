write-host "Install bulk MSI"
## Location of the MSI files
## PARAM ##
$path="C:\Program Files (x86)\Agresso 5.7.2\updates\ExpPacks\"


## DO NOT EDIT ##
cd $path
$files = Get-ChildItem -Path $path\ -Recurse -File -Filter '*.msi' 
foreach ($msifile in $files)
    {
        write-host "Finished MSI "$msifile
        $arguments= "/qn /norestart"
        Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
    }
    write-host "Finished applying all MSI's"