Import-Module ActiveDirectory
$Usersaccountpath ="OU=Users,OU=St James Place,OU=Accounts,DC=UKDC4SJP,DC=local"
$duuser = Get-ADUser -filter "enabled -eq 'TRUE'" -SearchBase $Usersaccountpath -Properties * |
	Select Name,SamAccountname,lastlogondate | 
	Out-GridView -title "Select a user account or cancel" -PassThru