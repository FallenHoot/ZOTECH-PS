Import-Module ActiveDirectory
$Usersaccountpath ="OU=disabled,OU=Users,OU=Acision,DC=UKDC4ACI,DC=local"
$duuser = Get-ADUser -filter "enabled -eq 'FALSE'" -SearchBase $Usersaccountpath -Properties * |
	Select Name,SamAccountname,Description | 
	Out-GridView -title "Select a user account or cancel" -PassThru