#========================================================================
#requires -version 4.0
#requires –runasadministrator
#Version 2.0.0.0 20160422 Zachery Olinske
############################################################################
## Purpose: Active Directory Tool                                 ##
## Author: Zachery Olinske                                                ##
## Date: 22/04/2016                                                       ##
## Company: UNIT4 Cloud                                                   ##
## Version: 2.0                                                           ##
############################################################################
#========================================================================
Import-Module ActiveDirectory

#----------------------------------------------------------
#DYNAMIC VARIABLES
#----------------------------------------------------------
$date = Get-Date
$i = 1
#$addn = (Get-ADDomain).DistinguishedName
#$dnsroot = (Get-ADDomain).DNSRoot
$DNdom = Get-ChildItem -Path Ad:\ | where {$_.Name -eq "Configuration"}            
$addn = ($DNdom.DistinguishedName -split "," ,2)[1] 
$wmiDomain = Get-WmiObject Win32_NTDomain -Filter "DnsForestName = '$( (Get-WmiObject Win32_ComputerSystem).Domain)'"
$dnsroot = $wmiDomain.DomainName  + ".local"
$envname=$args[0]
$CompanyOU=$args[1]
$Usersaccountpath=$args[2]
$Usersaccountpath = "OU=$Usersaccountpath,OU=$CompanyOU,$addn"  # Location of the User OU
$Groupaccountpath = "OU=$CompanyOU,$addn"

#----------------------------------------------------------
#GROUP VARIABLES
#----------------------------------------------------------
#
# Auto Populate Live Group
#
$LG = New-Object System.Collections.ArrayList
$LiveGroupArray = Get-ADGroup -SearchBase $Groupaccountpath -filter {GroupCategory -eq "Security"} -Propertie Name| Where { $_.Name -notmatch "SQL*" -and $_.Name -notmatch "SFTP*" -and $_.Name -match "live*"} #| 
#Select Name | Out-GridView -Title "List of AD Groups" -passthru
foreach($LiveGroup in $LiveGroupArray)
{
$LiveGroup=$LiveGroup.Name
$LG.Add("`n<LiveGroup>$LiveGroup</LiveGroup>")
}
#
# Auto Populate Test Group
#
$TG = New-Object System.Collections.ArrayList
$TestGroupArray = Get-ADGroup -SearchBase $Groupaccountpath -filter {GroupCategory -eq "Security"} -Propertie Name| Where { $_.Name -notmatch "SQL*" -and $_.Name -notmatch "SFTP*" -and $_.Name -match "Test*"} #| 
#Select Name | Out-GridView -Title "List of AD Groups" -passthru
$TestGroupsArray = foreach($TestGroup in $TestGroupArray)
{
$TestGroup=$TestGroup.Name
$TG.Add("`n<TestGroup>$TestGroup</TestGroup>")
}
#
# Auto Populate Dev Group
#
$DG = New-Object System.Collections.ArrayList
$DevGroupArray = Get-ADGroup -SearchBase $Groupaccountpath -filter {GroupCategory -eq "Security"} -Propertie Name| Where { $_.Name -notmatch "SQL*" -and $_.Name -notmatch "SFTP*" -and $_.Name -match "Dev*"} #| 
#Select Name | Out-GridView -Title "List of AD Groups" -passthru
$DevGroupsArray = foreach($DevGroup in $DevGroupArray)
{
$DevGroup=$DevGroup.Name
$DG.Add("`n<DevGroup>$DevGroup</DevGroup>")
}
#
# Auto Populate All Groups and find only SQLREAD
#
$SQLREADG = New-Object System.Collections.ArrayList
$AllGroupArray = Get-ADGroup -SearchBase $Groupaccountpath -filter {GroupCategory -eq "Security"} -Propertie Name| Where { $_.Name -match "SQL*" -and $_.Name -notmatch "ReadWrite*" -and $_.Name -notmatch "Admins*" -and $_.Name -notmatch "Service*"} #| 
#Select Name | Out-GridView -Title "List of AD Groups" -passthru
$AllGroupsArray = foreach($AllGroup in $AllGroupArray)
{
$AllGroup=$AllGroup.Name
$SQLREADG.Add("`n$AllGroup")
}
#
# Auto Populate All Groups and find only Citrix
#
$CITRIXG = New-Object System.Collections.ArrayList
$AllGroupArray = Get-ADGroup -SearchBase $Groupaccountpath -filter {GroupCategory -eq "Security"} -Propertie Name| Where { $_.Name -match "Citrix*"} #| 
#Select Name | Out-GridView -Title "List of AD Groups" -passthru
$AllGroupsArray = foreach($AllGroup in $AllGroupArray)
{
$AllGroup=$AllGroup.Name
$CITRIXG.Add("`n<DevGroup>$AllGroup</DevGroup>")
}
#----------------------------------------------
#region Application Functions
#----------------------------------------------

function OnApplicationLoad {
$CreateXML = @"
<?xml version="1.0" standalone="no"?>
<OPTIONS Product="$CompanyOU - AD User Tool">
 <Settings>
  <sAMAccountName Generate="True">
   <Style Format="FirstName.LastName" Enabled="False" />
   <Style Format="FirstInitialLastName" Enabled="True" />
   <Style Format="LastNameFirstInitial" Enabled="False" />
  </sAMAccountName>
  <UPN Generate="True">
   <Style Format="FirstName.LastName" Enabled="False" />
   <Style Format="FirstInitialLastName" Enabled="True" />
   <Style Format="LastNameFirstInitial" Enabled="False" />
  </UPN>
  <DisplayName Generate="True">
   <Style Format="FirstName LastName" Enabled="True" />
   <Style Format="LastName, FirstName" Enabled="False" />
  </DisplayName>
  <AccountStatus Enabled="True" />
  <Password ChangeAtLogon="True" />
 </Settings>
 <Default>
  <Domain>$dnsroot</Domain>
  <Path>$Usersaccountpath</Path>
  <FirstName></FirstName>
  <LastName></LastName>
  <Description>Full-Time Employee</Description>
  <Password></Password>
 </Default>
 <Domains>
  <Domain Name="$dnsroot">
   <Path>$Usersaccountpath</Path>
  </Domain>
 </Domains>
 <Descriptions>
 <Description>Full-Time Employee</Description>
  <Description>Part-Time Employee</Description>
  <Description>Consultant</Description>
  <Description>Intern</Description>
  <Description>Service Account</Description>
  <Description>Temp</Description>
  <Description>Freelancer</Description>
 </Descriptions>
 <Departments>
  <Department>Finance</Department>
  <Department>IT</Department>
  <Department>Marketing</Department>
  <Department>Sales</Department>
  <Department>Executive</Department>
  <Department>Human Resources</Department>
  <Department>Security</Department>
 </Departments>
 <Groups>
  <Group Name="Normal User">
  </Group>
  <Group Name="SQL Groups">
  </Group>
 </Groups>
 <TestGroups>
  $TG
 </TestGroups>
  <DevGroups>
  $DG
  </DevGroups>
 <LiveGroups>
  $LG
 </LiveGroups>

</OPTIONS>
"@
	
	Import-Module ActiveDirectory
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	$XMLOptions = $envname + ".Options.xml"
	$Script:ParentFolder = Split-Path (Get-Variable MyInvocation -scope 1 -ValueOnly).MyCommand.Definition
	$XMLFile = Join-Path $ParentFolder $XMLOptions
	
	$XMLMsg = "Configuration file $XMLOptions not detected in folder $ParentFolder.  Would you like to create one now?"
	if(!(Test-Path $XMLFile)){
 	   if([System.Windows.Forms.MessageBox]::Show($XMLMsg,"Warning",[System.Windows.Forms.MessageBoxButtons]::YesNo) -eq "Yes")
            {
    	    $CreateXML | Out-File $XMLFile
            $TemplateMsg = "Opening XML configuration file for editing ($XMLFile).  Please relaunch the script when the configuration is complete."
            [System.Windows.Forms.MessageBox]::Show($TemplateMsg,"Information",[System.Windows.Forms.MessageBoxButtons]::Ok) | Out-Null
			notepad $XMLFile
            Exit
	 	    }
        else{Exit}
	}
	else{[XML]$Script:XML = Get-Content $XMLFile}
#   if($XML.Options.Version -ne ([xml]$CreateXML).Options.Version)
#        {
#        $VersionMsg = "You are using an older version of the Options file.  Please generate a new Options file and transfer your settings.`r`nIn Use: $($XML.Options.Version) `r`nLatest: $(([xml]$CreateXML).Options.Version)"
#        [System.Windows.Forms.MessageBox]::Show($VersionMsg,"Warning",[System.Windows.Forms.MessageBoxButtons]::Ok)
#        }
#    else{}
	return $true#return true for success or false for failure
}

function OnApplicationExit {
	Remove-Module ActiveDirectory	
	$script:ExitCode = 0 #Set the exit code for the Packager
}

Function Set-sAMAccountName {
    Param([Switch]$Csv=$false)
    if(!$Csv)
        {
        $GivenName = $txtFirstName.text
        $SurName = $txtLastName.text
        }
    else{}
    Switch($XML.Options.Settings.sAMAccountName.Style | Where{$_.Enabled -eq $True} | Select -ExpandProperty Format)
        {
        "FirstName.LastName"    {"{0}.{1}" -f $GivenName,$Surname}
        "FirstInitialLastName"  {"{0}{1}" -f ($GivenName)[0],$SurName}
        "LastNameFirstInitial"  {"{0}{1}" -f $SurName,($GivenName)[0]}
        Default                 {"{0}.{1}" -f $GivenName,$Surname}
        }
    }
	
Function Set-UPN {
    Param([Switch]$Csv=$false)
    if(!$Csv)
        {
        $GivenName = $txtFirstName.text
        $SurName = $txtLastName.text
        $Domain = $cboDomain.Text
        }
    else{}
    Switch($XML.Options.Settings.UPN.Style | Where{$_.Enabled -eq $True} | Select -ExpandProperty Format)
        {
        "FirstName.LastName"    {"{0}.{1}@{2}" -f $GivenName,$Surname,$Domain}
        "FirstInitialLastName"  {"{0}{1}@{2}" -f ($GivenName)[0],$SurName,$Domain}
        "LastNameFirstInitial"  {"{0}{1}@{2}" -f $SurName,($GivenName)[0],$Domain}
        Default                 {"{0}.{1}@{2}" -f $GivenName,$Surname,$Domain}
        }
    }
	
Function Set-DisplayName {

    Param([Switch]$Csv=$false)
    if(!$Csv)
        {
        $GivenName = $txtFirstName.text
        $SurName = $txtLastName.text
        }
    else{}
    Switch($XML.Options.Settings.DisplayName.Style | Where{$_.Enabled -eq $True} | Select -ExpandProperty Format)
        {
        "FirstName LastName"    {"{0} {1}" -f $GivenName,$Surname}
        "LastName, FirstName"   {"{0}, {1}" -f $SurName, $GivenName}
        Default                 {"{0} {1}" -f $GivenName,$Surname}
        }
    }
	
Function Set-DisplayNameCopy {
    Param([Switch]$Csv=$false)
    if(!$Csv)
        {
        $GivenName
        $SurName
        }
    else{}
    Switch($XML.Options.Settings.DisplayName.Style | Where{$_.Enabled -eq $True} | Select -ExpandProperty Format)
        {
        "FirstName LastName"    {"{0} {1}" -f $GivenName,$Surname}
        "LastName, FirstName"   {"{0}, {1}" -f $SurName, $GivenName}
        Default                 {"{0} {1}" -f $GivenName,$Surname}
        }
    }
	
Function Set-UPNCopy {
    Param([Switch]$Csv=$false)
    if(!$Csv)
        {
        $GivenName
        $SurName
        $Domain = $cboDomain.Text
        }
    else{}
    Switch($XML.Options.Settings.UPN.Style | Where{$_.Enabled -eq $True} | Select -ExpandProperty Format)
        {
        "FirstName.LastName"    {"{0}.{1}@{2}" -f $GivenName,$Surname,$Domain}
        "FirstInitialLastName"  {"{0}{1}@{2}" -f ($GivenName)[0],$SurName,$Domain}
        "LastNameFirstInitial"  {"{0}{1}@{2}" -f $SurName,($GivenName)[0],$Domain}
        Default                 {"{0}.{1}@{2}" -f $GivenName,$Surname,$Domain}
        }
    }
	
Function Set-sAMAccountNameCopy {	
    Param([Switch]$Csv=$false)
    if(!$Csv)
        {
        $GivenName
        $SurName
        }
    else{}
    Switch($XML.Options.Settings.sAMAccountName.Style | Where{$_.Enabled -eq $True} | Select -ExpandProperty Format)
        {
        "FirstName.LastName"    {"{0}.{1}" -f $GivenName,$Surname}
        "FirstInitialLastName"  {"{0}{1}" -f ($GivenName)[0],$SurName}
        "LastNameFirstInitial"  {"{0}{1}" -f $SurName,($GivenName)[0]}
        Default                 {"{0}.{1}" -f $GivenName,$Surname}
        }
    }
#endregion Application Functions

function Get-vmfSeed{ #20160204
# Generate a seed for future randomization
    $RandomBytes = New-Object -TypeName "System.Byte[]" 4
    $Random = New-Object -TypeName "System.Security.Cryptography.RNGCryptoServiceProvider"
    $Random.GetBytes($RandomBytes)
    [BitConverter]::ToInt32($RandomBytes, 0)
}

function NEW-GeneratePassword { #20160204
    [CmdletBinding(ConfirmImpact='Low')] 
    [OutputType([String[]])] 
    param( 
        [int] $NumCaps = 0,
        [int] $NumDigit = 0,
        [int] $NumLower = 0,
        [int] $NumSpecial = 0    
    )

    # not using default parameters because we only want defaults of nothing is specified at all.
    if ( ($NumCaps -eq 0) -and ($NumDigit -eq 0) -and ($NumLower -eq 0) -and ($NumSpecial -eq 0) )
    {
        $NumCaps = 2
        $NumDigit = 2
        $NumLower = 5
        $NumSpecial = 2    
    }

    #iIl| and oO0 all look the same to users and generate support incidents
    #aA cause users to accidentally hit caps-lock
    #only using certain symbols that usually don't mess up users. :)
    #adjust these lists to suit your requirements
    $CharsCaps = "BCDEFGHJKLMNPQRSTUVWXYZ".ToCharArray()
    $CharsLower = "bcdefghjkmnpqrstuvwxyz".ToCharArray()
    $CharsDigit = "23456789".ToCharArray()
    $CharsSpecial = '#$&'.ToCharArray()

    $passchars = ""

    #generate the proper characters from each category
    while ($NumCaps-- -gt 0){$passchars += ($CharsCaps|Get-Random -SetSeed (Get-vmfSeed) )}
    while ($NumDigit-- -gt 0){$passchars += ($CharsDigit|Get-Random -SetSeed (Get-vmfSeed) )}
    while ($NumLower-- -gt 0){$passchars += ($CharsLower|Get-Random -SetSeed (Get-vmfSeed) )}
    while ($NumSpecial-- -gt 0){$passchars += ($CharsSpecial|Get-Random -SetSeed (Get-vmfSeed) )}


    #shuffle the generated characters int a random password
    $passchars = $passchars.ToCharArray() 
    $result = ""
    $result += ($passchars | Get-Random -SetSeed (Get-vmfSeed) -count ($passchars.Count)) -join ''

   $result
}

#----------------------------------------------
# Generated Form Function
#----------------------------------------------
function Call-ANUC_pff {

	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load("System.DirectoryServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	[void][reflection.assembly]::Load("System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Xml, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Design, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	#endregion Import Assemblies

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$formMain = New-Object System.Windows.Forms.Form
	$val1 = New-Object System.Windows.Forms.Label
	$val2 = New-Object System.Windows.Forms.Label
	$val3 = New-Object System.Windows.Forms.Label
	$btnClear = New-Object System.Windows.Forms.Button #20160407
	$txtUPN = New-Object System.Windows.Forms.TextBox
	$txtsAM = New-Object System.Windows.Forms.TextBox
	$txtDN = New-Object System.Windows.Forms.TextBox
	$labelUserPrincipalName = New-Object System.Windows.Forms.Label
	$labelSamAccountName = New-Object System.Windows.Forms.Label
	$labelDisplayName = New-Object System.Windows.Forms.Label
	$SB = New-Object System.Windows.Forms.StatusBar
	$cboDescription = New-Object System.Windows.Forms.ComboBox
	$txtPassword = New-Object System.Windows.Forms.TextBox
	$labelPassword = New-Object System.Windows.Forms.Label
	$cboDomain = New-Object System.Windows.Forms.ComboBox
	$labelCurrentDomain = New-Object System.Windows.Forms.Label
	$grpBoxStatus = New-Object System.Windows.Forms.GroupBox
	$richtextboxStatus = New-Object System.Windows.Forms.RichTextBox #20160407
	$pictureboxGroup = New-Object System.Windows.Forms.PictureBox  #20160407
	$pictureboxPassword = New-Object System.Windows.Forms.PictureBox #20160407
	$pictureboxDescription = New-Object System.Windows.Forms.PictureBox #20160407
	$pictureboxLastName = New-Object System.Windows.Forms.PictureBox #20160407
	$pictureboxFirstName = New-Object System.Windows.Forms.PictureBox #20160407
	$pictureboxDN = New-Object System.Windows.Forms.PictureBox #20160407
	$pictureboxAM = New-Object System.Windows.Forms.PictureBox #20160407
	#$Logo = New-Object System.Windows.Forms.PictureBox #20160501
	$txtLastName = New-Object System.Windows.Forms.TextBox
	$cboPath = New-Object System.Windows.Forms.ComboBox
	$labelOU = New-Object System.Windows.Forms.Label
	$txtFirstName = New-Object System.Windows.Forms.TextBox
	$btnSubmit = New-Object System.Windows.Forms.Button
	$btnModify = New-Object System.Windows.Forms.Button
	$btnLookup = New-Object System.Windows.Forms.Button
	$labelDescription = New-Object System.Windows.Forms.Label
	$labelLastName = New-Object System.Windows.Forms.Label
	$labelFirstName = New-Object System.Windows.Forms.Label
	$menustrip1 = New-Object System.Windows.Forms.MenuStrip
	$fileToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
	$SingleUserToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem #20160407
	$groupmanagementToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem  #20160407
	$grpBoxSurname = New-Object System.Windows.Forms.GroupBox #20160407
	$GroupManagement = New-Object System.Windows.Forms.ToolStripMenuItem #20160407
	$GroupList = New-Object System.Windows.Forms.ToolStripMenuItem #20160415
	$CountOUMembers = New-Object System.Windows.Forms.ToolStripMenuItem #20160415
	$LastLogonMembers = New-Object System.Windows.Forms.ToolStripMenuItem #20160425
	$CopyUser = New-Object System.Windows.Forms.ToolStripMenuItem #20160412
	$ResetPassword = New-Object System.Windows.Forms.ToolStripMenuItem #20160407
	$UnlockUser = New-Object System.Windows.Forms.ToolStripMenuItem #20160407
	$DisableUser = New-Object System.Windows.Forms.ToolStripMenuItem #20160407
	$EnableUser = New-Object System.Windows.Forms.ToolStripMenuItem #20160407
	$CopyUser = New-Object System.Windows.Forms.ToolStripMenuItem #20160412
	$Refresh = New-Object System.Windows.Forms.ToolStripMenuItem #20160420
	$MenuExit = New-Object System.Windows.Forms.ToolStripMenuItem
	$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
	$cboGroup = New-Object System.Windows.Forms.ComboBox #20160204
	$lblGroup = New-Object System.Windows.Forms.Label #20160204
	$lblGroups = New-Object System.Windows.Forms.Label #20160204
	$clbGroups = New-Object System.Windows.Forms.CheckedListBox #20160204
	$lblLists = New-Object System.Windows.Forms.Label #20160204
	$clbLists = New-Object System.Windows.Forms.CheckedListBox #20160204
	$lblCombo = New-Object System.Windows.Forms.Label #20160204
	$clbCombo = New-Object System.Windows.Forms.CheckedListBox #20160204
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$formMain_Load={
		
		$formMain.Text = $formMain.Text + " " + $XML.Options.Version
		Write-Verbose "Adding domains to combo box"
		$XML.Options.Domains.Domain | %{$cboDomain.Items.Add($_.Name)}
		
		Write-Verbose "Adding OUs to combo box"
	    $XML.Options.Domains.Domain | ?{$_.Name -match $cboDomain.Text} | Select -ExpandProperty Path | %{$cboPath.Items.Add($_)}
		
		Write-Verbose "Adding descriptions to combo box"
		$XML.Options.Descriptions.Description | %{$cboDescription.Items.Add($_)}
		
		Write-Verbose "Adding groups to combo box"
		$XML.Options.Groups.Group | %{$cboGroup.Items.Add($_.Name)} #20160204

		Write-Verbose "Adding groups to checked list box"
		$XML.Options.TestGroups.TestGroup | %{$clbGroups.Items.Add($_)} #20160204
		
		Write-Verbose "Adding lists to checked list box"
		$XML.Options.LiveGroups.LiveGroup | %{$clbLists.Items.Add($_)} #20160204
		
		Write-Verbose "Adding combo to checked list box"
		$XML.Options.DevGroups.DevGroup | %{$clbCombo.Items.Add($_)} #20160204
		
		Write-Verbose "Setting default fields"
		$cboDomain.SelectedItem = $XML.Options.Default.Domain
		$cboDomain.enabled = $False
	    $cboPath.SelectedItem = $XML.Options.Default.Path
		$cboPath.enabled = $False
		$txtFirstName.Text = $XML.Options.Default.FirstName
		$txtLastName.Text = $XML.Options.Default.LastName
		$cboDescription.SelectedItem = $XML.Options.Default.Description
		$cboGroup.SelectedItem = $XML.Options.Default.Group #20160204
		$txtPassword.Text = NEW-GeneratePassword -NumCaps 3 -NumDigit 2 -NumLower 3 -NumSpecial 1
		$hidden = $txtPassword.Text
		$txtsAM.enabled = $False
		$txtUPN.enabled = $False
		$btnModify.Visible = $False
		$btnSubmit.Visible = $True

	}
	
	$btnSubmit_Click={
		$richtextboxStatus.Text = ""
		$Domain=$cboDomain.Text
		$Path=$cboPath.Text
		$GivenName = $txtFirstName.Text
		$Surname = $txtLastName.Text
		$Description = $cboDescription.Text
		$UserGroups = $clbGroups.CheckedItems #20160204
		$UserLists = $clbLists.CheckedItems #20160204
		$UserCombo = $clbCombo.CheckedItems #20160204

		if($XML.Options.Settings.Password.ChangeAtLogon -eq "True"){$ChangePasswordAtLogon = $True}
        else{$ChangePasswordAtLogon = $false}
		
        if($XML.Options.Settings.AccountStatus.Enabled -eq "True"){$Enabled = $True}
        else{$Enabled = $false}
	
		$Name="$GivenName $Surname"
		
        if($XML.Options.Settings.sAMAccountName.Generate -eq $True){$sAMAccountName = Set-sAMAccountName}
		else{$sAMAccountName = $txtsAM.Text}

        if($XML.Options.Settings.uPN.Generate -eq $True){$userPrincipalName = Set-UPN}
        else{$userPrincipalName = $txtuPN.Text}
		
        if($XML.Options.Settings.DisplayName.Generate -eq $True){$DisplayName = Set-DisplayName}
        else{$DisplayName = $txtDN.Text}

		$AccountPassword = $txtPassword.text | ConvertTo-SecureString -AsPlainText -Force
	
		$User = @{
		    Name = $Name
		    GivenName = $GivenName
		    Surname = $Surname
		    Path = $Path
		    samAccountName = $samAccountName
		    userPrincipalName = $userPrincipalName
		    DisplayName = $DisplayName
		    AccountPassword = $AccountPassword
		    ChangePasswordAtLogon = $ChangePasswordAtLogon
		    Enabled = $Enabled
		    Description = $Description
		    }	
		#Checking if the new user exist

		$global:NewUserds = $txtsAM.Text
		$global:NewUserds = $global:NewUserds
		$global:NewUser = $global:NewUserds

		if ( $global:NewUserds -eq "$addn" ) {$val3.Text = "Empty"}
			
		elseif (dsquery user -samid $global:NewUserds)
		{$val3.Text = "User Exist" 
		$richtextboxStatus.Text += "`nUser Exist" 
		$richtextboxStatus.Text += "`nError from Active Directory: $_ `n"}
		elseif ($global:NewUserds = "null") 
		{$val3.Text = "OK" 
		$richtextboxStatus.Text += "`nUser Doesn't Exist - OK" }

		#Checking if Fisrt Name isn't empty

		if ( $txtFirstName.Text -eq "" ) {$val1.Text = "Empty"}
		elseif ($txtFirstName.Text -ne "") 
		{$val1.Text = "OK" 
		$richtextboxStatus.Text += "`nFirst Name - OK" }

		#Checking if Last Name isn't empty

		if ( $txtLastName.Text -eq "" ) {$val2.Text = "Empty"}
		elseif ($txtLastName.Text -ne "") 
		{$val2.Text = "OK"
		$richtextboxStatus.Text += "`nLast Name - OK"}
		
		#Checking if All Validation is OK
	If ($val1.Text -eq "OK" -and $val2.Text -eq "OK" -and $val3.Text -eq "OK")
		{
		$richtextboxStatus.Text += "`nValidation is - OK `n"
		$txtFirstName.enabled = $False
		$txtLastName.enabled = $False 	
	Try {	
	
	 
			$richtextboxStatus.Text += "Creating new user: $sAMAccountName. `n"
			$SB.Text = "Creating new user $sAMAccountName "
			$ADError = $Null
			New-ADUser @User -ErrorVariable ADError
			if ($ADerror){$SB.Text = "[$sAMAccountName] $ADError"}
			else{$SB.Text = "$sAMAccountName created successfully. "}
			
			#Add user to Test Groups
			$richtextboxStatus.Text += "Added user to Test Group(s). `n"
			$SB.Text = "Added user to Test Groups"
			$UserGroups | Add-ADGroupMember –Member $sAMAccountName #20160204

			#Add user to Dev Groups
			$richtextboxStatus.Text += "Added user to Dev Group(s). `n"
			$SB.Text = "Add user to Dev Groups"
			$UserLists | Add-ADGroupMember -Member $sAMAccountName #20160204
			
			#Add user to Live Groups
			$richtextboxStatus.Text += "Added user to Live Group(s). `n"
			$SB.Text = "Add user to Live Groups"
			$UserCombo | Add-ADGroupMember –Member $sAMAccountName #20160204
			
			$richtextboxStatus.Text += "User $sAMAccountName has been created. `n"
			$richtextboxStatus.Text += "Make sure to give $sAMAccountName the passwod: $hidden `n"
			$btnModify.Visible = $False
			}
	
	Catch {
				$richtextboxStatus.Text += "`nERROR: The user was NOT added to the Active Directory!!!! `n"
				$richtextboxStatus.Text += "`nError from Active Directory: $_ `n"
			}
	}
	}
	
	
	$btnLookup_Click={
		$richtextboxStatus.Text = ""
		$Domain=$cboDomain.Text
		$Path=$cboPath.Text
		$GivenName = $txtFirstName.Text
		$Surname = $txtLastName.Text
		$Description = $cboDescription.Text
		$UserGroups = $clbGroups.CheckedItems #20160204
		$UserLists = $clbLists.CheckedItems #20160204
		$UserCombo = $clbCombo.CheckedItems #20160204

		if($XML.Options.Settings.Password.ChangeAtLogon -eq "True"){$ChangePasswordAtLogon = $True}
        else{$ChangePasswordAtLogon = $false}
		
        if($XML.Options.Settings.AccountStatus.Enabled -eq "True"){$Enabled = $True}
        else{$Enabled = $false}
	
		$Name="$GivenName $Surname"
		
        if($XML.Options.Settings.sAMAccountName.Generate -eq $True){$sAMAccountName = Set-sAMAccountName}
		else{$sAMAccountName = $txtsAM.Text}

        if($XML.Options.Settings.uPN.Generate -eq $True){$userPrincipalName = Set-UPN}
        else{$userPrincipalName = $txtuPN.Text}
		
        if($XML.Options.Settings.DisplayName.Generate -eq $True){$DisplayName = Set-DisplayName}
        else{$DisplayName = $txtDN.Text}
		
		$btnSubmit.Visible = $False
		$AccountPassword = $txtPassword.text | ConvertTo-SecureString -AsPlainText -Force
		$btnModify.Visible = $True
		Try {
		$LUuser = get-aduser -f {GivenName -eq $GivenName}
		
		$GM = @{
			Identity = $LUuser.Name
		    GivenName = $LUuser.GivenName
		    Surname = $LUuser.Surname
		    Path = $LUuser.Path
		    samAccountName = $LUuser.samAccountName
		    userPrincipalName = $LUuser.userPrincipalName
		    DisplayName = $LUuser.DisplayName
		    AccountPassword = $LUuser.AccountPassword
		    ChangePasswordAtLogon = $LUuser.ChangePasswordAtLogon
		    Enabled = $LUuser.Enabled
		    Description = $LUuser.Description
				
			}
			$Name = $LUuser.Name
			$txtFirstName.Text = $LUuser.GivenName
			$txtLastName.Text = $LUuser.Surname
			$cboDescription = $LUuser.Description
			$txtsAM = $LUuser.samAccountName
			$txtDN.Text = $LUuser.userPrincipalName
			
	}
	Catch {
				$richtextboxStatus.Text += "`nERROR: The user $GivenName was NOT found in Active Directory!!!! `n"
				$richtextboxStatus.Text += "`nError from Active Directory: $_ `n"
			}

			
	}
	
	$btnModify_Click={
		$richtextboxStatus.Text = ""
		$Domain=$cboDomain.Text
		$Path=$cboPath.Text
		$GivenName = $txtFirstName.Text
		$Surname = $txtLastName.Text
		$Description = $cboDescription.Text
		$UserGroups = $clbGroups.CheckedItems #20160204
		$UserLists = $clbLists.CheckedItems #20160204
		$UserCombo = $clbCombo.CheckedItems #20160204

		if($XML.Options.Settings.Password.ChangeAtLogon -eq "True"){$ChangePasswordAtLogon = $True}
        else{$ChangePasswordAtLogon = $false}
		
        if($XML.Options.Settings.AccountStatus.Enabled -eq "True"){$Enabled = $True}
        else{$Enabled = $false}
	
		$Name="$GivenName $Surname"
		
        if($XML.Options.Settings.sAMAccountName.Generate -eq $True){$sAMAccountName = Set-sAMAccountName}
		else{$sAMAccountName = $txtsAM.Text}

        if($XML.Options.Settings.uPN.Generate -eq $True){$userPrincipalName = Set-UPN}
        else{$userPrincipalName = $txtuPN.Text}
		
        if($XML.Options.Settings.DisplayName.Generate -eq $True){$DisplayName = Set-DisplayName}
        else{$DisplayName = $txtDN.Text}
	
		$User = @{
		    Name = $Name
		    GivenName = $GivenName
		    Surname = $Surname
		    Path = $Path
		    samAccountName = $samAccountName
		    userPrincipalName = $userPrincipalName
		    DisplayName = $DisplayName
		    ChangePasswordAtLogon = $ChangePasswordAtLogon
		    Enabled = $Enabled
		    Description = $Description
		    }
	Try {	
		$richtextboxStatus.Text += "Modify user: $sAMAccountName. `n"
		$SB.Text = "Modify user $User.sAMAccountName "
        $ADError = $Null
		$LUuser | Set-ADUser @User -ErrorVariable ADError
        if ($ADerror){$SB.Text = "[$sAMAccountName] $ADError"}
        else{$SB.Text = "$sAMAccountName modified successfully. "}
		
		#Add user to Test Groups
		$richtextboxStatus.Text += "Added user to Test Group(s). `n"
		$SB.Text = "Added user to Test Groups"
		$UserGroups | Add-ADGroupMember –Member $sAMAccountName #20160204

		#Add user to Dev Groups
		$richtextboxStatus.Text += "Added user to Dev Group(s). `n"
		$SB.Text = "Add user to Dev Groups"
		$UserLists | Add-ADGroupMember -Member $sAMAccountName #20160204
		
		#Add user to Live Groups
		$richtextboxStatus.Text += "Added user to Live Group(s). `n"
		$SB.Text = "Add user to Live Groups"
		$UserCombo | Add-ADGroupMember –Member $sAMAccountName #20160204
		
		
		
		$btnSubmit.Visible = $True
		$richtextboxStatus.Text += "User $User.sAMAccountName has been modified. `n"
		}
	Catch {
				$richtextboxStatus.Text += "`nERROR: The user was NOT modified to the Active Directory!!!! `n"
				$richtextboxStatus.Text += "`nError from Active Directory: $_ `n"
			}
	
	}
	
	$btnClear_Click={
		
		# Clear the TextBoxes from text
		$txtFirstName.Text = $null
		$txtLastName.Text = $null
		$cboDescription.Text = $null
		$txtPassword.Text = NEW-GeneratePassword -NumCaps 3 -NumDigit 2 -NumLower 3 -NumSpecial 1
		$txtDN.Text = $null
		$txtsAM.Text = $null
		$txtuPN.Text = $null
		$btnModify.Visible = $False
		$btnSubmit.Visible = $True
		# Clear the RichTextBox Status
		$richtextboxStatus.Text = $null
	}
	
	$cboDomain_SelectedIndexChanged={
		$cboPath.Items.Clear()
		Write-Verbose "Adding OUs to combo box"
	    $XML.Options.Domains.Domain | ?{$_.Name -match $cboDomain.Text} | Select -ExpandProperty Path | %{$cboPath.Items.Add($_)}	
		Write-Verbose "Creating required account fields"
		
        if ($XML.Options.Settings.DisplayName.Generate) {$txtDN.Text = Set-DisplayName}
        if ($XML.Options.Settings.sAMAccountName.Generate) {$txtsAM.Text = Set-sAMAccountName}
        if ($XML.Options.Settings.UPN.Generate) {$txtUPN.Text = Set-UPN}	
	}

	$cboGroup_SelectedIndexChanged={ #20160204
		Write-Verbose "Updating groups fields with list information"
	    $Group = @($XML.Options.Groups.Group | ? {$_.Name -match $cboGroup.Text}) #20141120
		$arrayGroups = @($Group | % { $_.List } | ? { $_.Type -match "TestGroup" } | % { $_.'#text' } ) #20141120
		#$arrayGroups = @($GroupLists | % { $_.'#text' } ) #20141120
		for ($i = 0; $i -lt $clbGroups.Items.Count; $i++) { if($arrayGroups -Contains $clbGroups.Items[$i]){ $clbGroups.SetItemChecked( $i, $true ) } else { $clbGroups.SetItemChecked( $i, $false ) } } #20141114
		$arrayLists = @($Group | % { $_.List } | ? { $_.Type -match "LiveGroup" } | % { $_.'#text' } ) #20141120
		for ($i = 0; $i -lt $clbLists.Items.Count; $i++) { if($arrayLists -Contains $clbLists.Items[$i]) { $clbLists.SetItemChecked( $i, $true ) } else { $clbLists.SetItemChecked( $i, $false ) } } #20141114
		$arrayCombo = @($Group | % { $_.List } | ? { $_.Type -match "DevGroup" } | % { $_.'#text' } ) #20141120
		for ($i = 0; $i -lt $clbCombo.Items.Count; $i++) { if($arrayCombo -Contains $clbCombo.Items[$i]) { $clbCombo.SetItemChecked( $i, $true ) } else { $clbCombo.SetItemChecked( $i, $false ) } } #20141120
	}
	
	$txtName_TextChanged={
		Write-Verbose "Creating required account fields"
        
        if ($XML.Options.Settings.DisplayName.Generate -eq $True) {$txtDN.Text = Set-DisplayName}
        if ($XML.Options.Settings.sAMAccountName.Generate -eq $True) {$txtsAM.Text = (Set-sAMAccountName)}
        if ($XML.Options.Settings.UPN.Generate -eq $True) {$txtUPN.Text = Set-UPN}
	}
	
	$ResetPassword_Click={ #20160204
 
#get all enabled user accounts in the OU
	$rpuser = Get-ADUser -filter "enabled -eq 'true'" -SearchBase $Usersaccountpath -Properties * |
	Select Name,SamAccountname,Surname | 
	Out-GridView -title "Select a user account or cancel" -PassThru
if ($rpuser) {
 
    #prompt for the new password
    $prompt = "Enter the user's $SAMAccountname. Password has been generated for you.`n"
    $Title = "Reset Password"
    $Default = NEW-GeneratePassword -NumCaps 3 -NumDigit 2 -NumLower 3 -NumSpecial 1
 
    Add-Type -AssemblyName "microsoft.visualbasic" -ErrorAction Stop
    $prompt = "Enter the user's new password. `n `n Minimal of 8 characters `n  Uppercase characters (A through Z) `n  Lowercase characters (a through z)  `n  One or more digits (0 through 9) `n  Non-Alphabetic characters (Example !, $, #, &) `n `n "
    $Plaintext =[microsoft.visualbasic.interaction]::InputBox($Prompt,$Title,$Default)
 
    #only continue is there is text for the password
    if ($plaintext -match "^\w") {  
    #convert to secure string
    $NewPassword = ConvertTo-SecureString -String $Plaintext -AsPlainText -Force
	
	$userinstance = Get-ADUser -Identity $rpuser.SamAccountname
    #define a hash table of parameter values to splat to 
    #Set-ADAccountPassword
    $paramHash = @{
    Identity = $rpuser.SamAccountname
    NewPassword = $NewPassword 
    Reset = $True
    Passthru = $True
    ErrorAction = "Stop"
    }
		
    Try {
     $output = Set-ADAccountPassword @paramHash |
     Set-ADUser -ChangePasswordAtLogon $True -PassThru |
     Get-ADuser -Properties PasswordLastSet,PasswordExpired,WhenChanged | 
     Out-String
 
	$richtextboxStatus.Text += "`nPassword has been changed for user: `n"
	$richtextboxStatus.Text += "Username: $userinstance `n"
	$richtextboxStatus.Text += "Password: $Default `n" 
    }
    Catch {
				$richtextboxStatus.Text += "`nERROR: The user was NOT added to the Active Directory!!!! "
				$richtextboxStatus.Text += "`nError from Active Directory: $_"
			}
    } #if plain text password
}
}
	
	$DisableUser_Click={ #20160204

	#get all enabled user accounts in the OU
	$duuser = Get-ADUser -filter "enabled -eq 'true'" -SearchBase $Usersaccountpath -Properties * |
	Select Name,SamAccountname,Surname | 
	Out-GridView -title "Select a user account or cancel" -PassThru
 
if ($duuser) {

	 $paramHash = @{
    Identity = $duuser.SamAccountname
    Passthru = $True
    ErrorAction = "Stop"
    }
	
		$userinstance = Get-ADUser -Identity $duuser.SamAccountname
    #prompt for the new password
    $prompt = "Enter the user's SAMAccountname"
    $Title = "Disable User"
    $Default = $null
 
	$richtextboxStatus.Text += "$output"
    Try {
    $output = Set-ADUser @paramHash |
	Set-ADUser -Enabled $false  -PassThru | 
    Out-String
	
	$richtextboxStatus.Text += "`nUser has been disabled `n"
	$richtextboxStatus.Text += "Username: $userinstance `n"
    }
    Catch {
				$richtextboxStatus.Text += "`nERROR: The user was NOT added to the Active Directory!!!! `n"
				$richtextboxStatus.Text += "`nError from Active Directory: $_ `n"
			}
}
	}
	
	$EnableUser_Click={ #20160204
 
	#get all enabled user accounts in the OU
	$euuser = Get-ADUser -filter "enabled -eq 'False'" -SearchBase $Usersaccountpath -Properties * |
	Select Name,SamAccountname,Surname | 
	Out-GridView -title "Select a user account or cancel" -PassThru
  if ($euuser) {
 
    #prompt for the new password
    $prompt = "Enter the user's SAMAccountname"
    $Title = "Reset Password"
    $Default = NEW-GeneratePassword -NumCaps 3 -NumDigit 2 -NumLower 3 -NumSpecial 1
 
    Add-Type -AssemblyName "microsoft.visualbasic" -ErrorAction Stop
    $prompt = "Enter the user's new password. `n `n Minimal of 8 characters `n  Uppercase characters (A through Z) `n  Lowercase characters (a through z)  `n  One or more digits (0 through 9) `n  Non-Alphabetic characters (Example !, $, #, &) `n `n "
    $Plaintext =[microsoft.visualbasic.interaction]::InputBox($Prompt,$Title,$Default)
 
    #define a hash table of parameter values to splat to 
    #Set-ADAccountPassword
    $paramHash = @{
    Identity = $euuser.SamAccountname
    Passthru = $True
    ErrorAction = "Stop"
    }
	$userinstance = Get-ADUser -Identity $euuser.SamAccountname
    Try {
    $output = Set-ADUser @paramHash |
	Set-ADUser -Enabled $true  -PassThru | 
    Out-String
 

 	$richtextboxStatus.Text += "`nUser has been enabled `n"
	$richtextboxStatus.Text += "$userinstance `n"
	$richtextboxStatus.Text += "$Default `n"
	
 
    }
    Catch {
				$richtextboxStatus.Text += "`nERROR: The user was NOT added to the Active Directory!!!!"
				$richtextboxStatus.Text += "`nError from Active Directory: $_"
			}
	else ($euuser = "")
	{
	$richtextboxStatus.Text += "No users to be enabled `n"
	}
}
	}
 
	$GroupManagement_Click={ #20160204
	
	$GroupMan = Get-ADGroup -SearchBase $Groupaccountpath -filter {GroupCategory -eq "Security"} | 
	Select Name | Out-GridView -Title "List of AD Groups" -passthru
	
	}
	
	$CopyUser_Click={ #20160204
		#Generated Form Function
function GenerateForm {
########################################################################
# Code Generated By: SAPIEN Technologies PrimalForms (Community Edition) v1.0.10.0
# Generated On: 2014-02-13 11:34
# Generated By: Jean-Sebastien Elie
Import-Module ActiveDirectory
########################################################################

#region Import the Assemblies
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
#endregion

#region Generated Form Objects
$form1 = New-Object System.Windows.Forms.Form
#$pictureBox1 = New-Object System.Windows.Forms.PictureBox
$infodisplay = New-Object System.Windows.Forms.Label
$tuser = New-Object System.Windows.Forms.ComboBox
$clear = New-Object System.Windows.Forms.Button
$val4 = New-Object System.Windows.Forms.Label
$val3 = New-Object System.Windows.Forms.Label
$bcopy = New-Object System.Windows.Forms.Button
$val2 = New-Object System.Windows.Forms.Label
$val1 = New-Object System.Windows.Forms.Label
$bvalidate = New-Object System.Windows.Forms.Button
$label4 = New-Object System.Windows.Forms.Label
$label3 = New-Object System.Windows.Forms.Label
$label2 = New-Object System.Windows.Forms.Label
$label1 = New-Object System.Windows.Forms.Label
$tlname = New-Object System.Windows.Forms.TextBox
$tfname = New-Object System.Windows.Forms.TextBox
$tnewuser = New-Object System.Windows.Forms.TextBox
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#endregion Generated Form Objects

#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------
#Provide Custom Code for events specified in PrimalForms.

$form1.FormBorderStyle = "FixedToolWindow"

#ComboBox Ad user generation
$arrac = get-aduser -SearchBase $Usersaccountpath -Filter * | sort-object


foreach($muser in $arrac)
                {
                    $tuser.items.add($muser.Name)
                                        }


#Unit4 Logo

$picturebox1.imagelocation = "\unit4icons\unit4logo.png"
$picturebox1.sizemode = "StretchImage" 

# Global Var
[string]$global:name = $null
[string]$global:nameok = $null
[string]$global:Newuser = $null
[string]$global:fname = $null
[string]$global:lname = $null
[string]$global:nameds = $null
[string]$global:NewUserds = $null
[string]$global:db = $null
[Int]$global:count = $null
[string]$global:DN = $null
[string]$global:OldUser = $null
[string]$global:Parent = $null
[string]$global:OU = $null
[string]$global:OUDN = $null
[string]$global:domain = $null
[Int]$global:countr = $null
[Int]$global:index = $null
[string]$global:iuser = $null
[Int]$global:index2 = $null 



$bcopy_OnClick= 
{
$clear.visible = $False
$bcopy.visible = $False
$bvalidate.visible = $False


# Gets all of the users info to be copied to the new account

$name = Get-AdUser -Identity $global:nameok -Properties *
$DN = $name.distinguishedName
$OldUser = [ADSI]"LDAP://$DN"
$Parent = $OldUser.Parent
$OU = [ADSI]$Parent
$OUDN = $OU.distinguishedName
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() 
$NewName = "$fname $lname"
$flname = "$global:fname.$global:lname"


# Creates the user from the copied properties #Step 1

New-ADUser -SamAccountName $global:NewUser -Name $NewName -GivenName $fname -Surname $lname -Instance $DN -Path "$OUDN" -AccountPassword (ConvertTo-SecureString -AsPlainText "abc123**" -Force) –userPrincipalName $global:NewUser@$domain -Department $name.Department -Enabled $true

# Requires Change Password at Logon
 
Set-ADUser -Identity $global:NewUser -ChangePasswordAtLogon $true

# gets groups from the Copied user and populates the new user in them #Step 2

$groups = (GET-ADUSER –Identity $name –Properties MemberOf).MemberOf
$global:count = $groups.count
$global:countr = $groups.count
$infodisplay.text = "Group a copier: $global:count"

# Group copy 

$groups = (GET-ADUSER –Identity $name –Properties MemberOf).MemberOf
foreach ($group in $groups) { 

Add-ADGroupMember -Identity $group -Members $global:NewUser

}

# After some testing it seems that sometimes AD don't have time to process everything and while trying to access the user for exchange it gave errors.
$infodisplay.Text = $infodisplay.Text + "`r`nProcessing time... "
$sec = 10
While($sec -ne 0) {Start-Sleep -s 1
$sec--}

$infodisplay.text = "$global:name has been copied"
}

$bvalidate_OnClick= 
{
# Gets all of the users info to be copied to the new account

#array index selection
$global:index = $tuser.SelectedIndex
$indexuser = $arrac[$index]
$iuser = get-aduser  $indexuser.SamAccountName  | select -ExpandProperty SamAccountName
$global:nameds = $iuser
$global:nameok = $iuser

#Checking the user to copy if it exist

if ($tuser.SelectedIndex -eq -1) {$val1.Text = "Not OK"
$global:nameok = ""}

else {$val1.Text = "OK"}



#Checking if the new user exist

$global:NewUserds = $tnewuser.Text
$global:NewUserds = $global:NewUserds.trim( )
$global:NewUser = $global:NewUserds

if ( $global:NewUserds -eq "" ) {$val2.Text = "Empty"}
	
elseif (dsquery user -samid $global:NewUserds){$val2.Text = "User Exist"}

elseif ($global:NewUserds = "null") {$val2.Text = "OK"}

#Checking if Fisrt Name isn't empty

if ( $tfname.Text -eq "" ) {$val3.Text = "Empty"}
elseif ($tfname.Text -ne "") {$val3.Text = "OK"}
$global:fname = $tfname.Text
$global:fname = $global:fname.trim( )

#Checking if Last Name isn't empty

if ( $tlname.Text -eq "" ) {$val4.Text = "Empty"}
elseif ($tlname.Text -ne "") {$val4.Text = "OK"}
$global:lname = $tlname.Text
$global:lname = $global:lname.trim( )

#Checking if All Validation is OK

if ( $val1.Text -eq "OK" -and $val2.Text -eq "OK" -and $val3.Text -eq "OK" -and $val4.Text -eq "OK")
{ 
$tuser.enabled = $False
$tnewuser.enabled = $False
$tfname.enabled = $False
$tlname.enabled = $False 
$clear.visible = $True
$bcopy.visible = $True 
}


}

$handler_label1_Click= 
{
#TODO: Place custom script here

}

$clear_OnClick= 
{
$tuser.enabled = $True
$tnewuser.enabled = $True
$tfname.enabled = $True
$tlname.enabled = $True

$val1.Text = ""
$val2.Text = ""
$val3.Text = ""
$val4.Text = ""
$tuser.SelectedIndex = -1
$tnewuser.Text = ""
$tfname.Text = ""
$tlname.Text = ""
$infodisplay.Text = ""
$clear.visible = $False
$bcopy.visible = $False 

$bvalidate.visible = $True
}
$handler_form1_Load= 
{
}
$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$form1.WindowState = $InitialFormWindowState
}

#----------------------------------------------
#region Generated Form Code
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 394
$System_Drawing_Size.Width = 534
$form1.ClientSize = $System_Drawing_Size
$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$form1.Name = "form1"
$form1.Text = "$CompanyOU - Copy User"
$form1.add_Load($handler_form1_Load)

$pictureBox1.DataBindings.DefaultDataSourceUpdateMode = 0

$pictureBox1.InitialImage = [System.Drawing.Image]::FromFile('\unit4icons\unit4logo.png')
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 336
$System_Drawing_Point.Y = 261
$pictureBox1.Location = $System_Drawing_Point
$pictureBox1.Name = "pictureBox1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 109
$System_Drawing_Size.Width = 185
$pictureBox1.Size = $System_Drawing_Size
$pictureBox1.TabIndex = 21
$pictureBox1.TabStop = $False

#$form1.Controls.Add($pictureBox1)

$infodisplay.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 255
$infodisplay.Location = $System_Drawing_Point
$infodisplay.Name = "infodisplay"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 116
$System_Drawing_Size.Width = 311
$infodisplay.Size = $System_Drawing_Size
$infodisplay.TabIndex = 19

$form1.Controls.Add($infodisplay)

$tuser.AutoCompleteMode = 3
$tuser.AutoCompleteSource = 256
$tuser.DataBindings.DefaultDataSourceUpdateMode = 0
$tuser.FormattingEnabled = $True
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 128
$System_Drawing_Point.Y = 38
$tuser.Location = $System_Drawing_Point
$tuser.Name = "tuser"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 21
$System_Drawing_Size.Width = 145
$tuser.Size = $System_Drawing_Size
$tuser.TabIndex = 1

$form1.Controls.Add($tuser)

$clear.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 413
$System_Drawing_Point.Y = 178
$clear.Location = $System_Drawing_Point
$clear.Name = "clear"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 24
$System_Drawing_Size.Width = 110
$clear.Size = $System_Drawing_Size
$clear.TabIndex = 16
$clear.Text = "Clear"
$clear.UseVisualStyleBackColor = $True
$clear.Visible = $False
$clear.add_Click($clear_OnClick)

$form1.Controls.Add($clear)

$val4.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 290
$System_Drawing_Point.Y = 119
$val4.Location = $System_Drawing_Point
$val4.Name = "val4"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 18
$System_Drawing_Size.Width = 108
$val4.Size = $System_Drawing_Size
$val4.TabIndex = 15

$form1.Controls.Add($val4)

$val3.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 290
$System_Drawing_Point.Y = 93
$val3.Location = $System_Drawing_Point
$val3.Name = "val3"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 18
$System_Drawing_Size.Width = 108
$val3.Size = $System_Drawing_Size
$val3.TabIndex = 14

$form1.Controls.Add($val3)

$bcopy.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 412
$System_Drawing_Point.Y = 149
$bcopy.Location = $System_Drawing_Point
$bcopy.Name = "bcopy"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 24
$System_Drawing_Size.Width = 110
$bcopy.Size = $System_Drawing_Size
$bcopy.TabIndex = 12
$bcopy.Text = "Start Copy"
$bcopy.UseVisualStyleBackColor = $True
$bcopy.Visible = $False
$bcopy.add_Click($bcopy_OnClick)

$form1.Controls.Add($bcopy)

$val2.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 290
$System_Drawing_Point.Y = 67
$val2.Location = $System_Drawing_Point
$val2.Name = "val2"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 18
$System_Drawing_Size.Width = 108
$val2.Size = $System_Drawing_Size
$val2.TabIndex = 11

$form1.Controls.Add($val2)

$val1.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 290
$System_Drawing_Point.Y = 41
$val1.Location = $System_Drawing_Point
$val1.Name = "val1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 18
$System_Drawing_Size.Width = 108
$val1.Size = $System_Drawing_Size
$val1.TabIndex = 10

$form1.Controls.Add($val1)

$bvalidate.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 412
$System_Drawing_Point.Y = 119
$bvalidate.Location = $System_Drawing_Point
$bvalidate.Name = "bvalidate"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 24
$System_Drawing_Size.Width = 110
$bvalidate.Size = $System_Drawing_Size
$bvalidate.TabIndex = 9
$bvalidate.Text = "Validate"
$bvalidate.UseVisualStyleBackColor = $True
$bvalidate.add_Click($bvalidate_OnClick)

$form1.Controls.Add($bvalidate)

$label4.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 38
$System_Drawing_Point.Y = 119
$label4.Location = $System_Drawing_Point
$label4.Name = "label4"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 19
$System_Drawing_Size.Width = 84
$label4.Size = $System_Drawing_Size
$label4.TabIndex = 8
$label4.Text = "Lastname"

$form1.Controls.Add($label4)

$label3.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 38
$System_Drawing_Point.Y = 95
$label3.Location = $System_Drawing_Point
$label3.Name = "label3"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 19
$System_Drawing_Size.Width = 84
$label3.Size = $System_Drawing_Size
$label3.TabIndex = 7
$label3.Text = "First Name"

$form1.Controls.Add($label3)

$label2.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 38
$System_Drawing_Point.Y = 69
$label2.Location = $System_Drawing_Point
$label2.Name = "label2"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 19
$System_Drawing_Size.Width = 84
$label2.Size = $System_Drawing_Size
$label2.TabIndex = 6
$label2.Text = "New Username"

$form1.Controls.Add($label2)

$label1.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 38
$System_Drawing_Point.Y = 43
$label1.Location = $System_Drawing_Point
$label1.Name = "label1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 19
$System_Drawing_Size.Width = 84
$label1.Size = $System_Drawing_Size
$label1.TabIndex = 5
$label1.Text = "User to Copy"
$label1.add_Click($handler_label1_Click)

$form1.Controls.Add($label1)

$tlname.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 128
$System_Drawing_Point.Y = 119
$tlname.Location = $System_Drawing_Point
$tlname.Name = "tlname"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 145
$tlname.Size = $System_Drawing_Size
$tlname.TabIndex = 4

$form1.Controls.Add($tlname)

$tfname.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 128
$System_Drawing_Point.Y = 93
$tfname.Location = $System_Drawing_Point
$tfname.Name = "tfname"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 145
$tfname.Size = $System_Drawing_Size
$tfname.TabIndex = 3

$form1.Controls.Add($tfname)

$tnewuser.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 128
$System_Drawing_Point.Y = 67
$tnewuser.Location = $System_Drawing_Point
$tnewuser.Name = "tnewuser"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 145
$tnewuser.Size = $System_Drawing_Size
$tnewuser.TabIndex = 2

$form1.Controls.Add($tnewuser)

#endregion Generated Form Code

#Save the initial state of the form
$InitialFormWindowState = $form1.WindowState
#Init the OnLoad event to correct the initial state of the form
$form1.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$form1.ShowDialog()| Out-Null

} #End Function

#Call the Function
GenerateForm
	}
	
	$GroupUserList_Click={ 
	
	
	$GroupMan = Get-ADGroup -SearchBase $Groupaccountpath -filter {GroupCategory -eq "Security"} | 
	Select Name | Out-GridView -Title "List of AD Groups" -passthru

	$GM = @{
				Identity = $GroupMan.Name
			}

	Get-ADGroupMember @GM | 
	Get-ADUser -Property * | 
	Select name, samaccountname |
	Out-GridView -title "List of users in $GroupMan.Name" -OutputMode Single
	}
	
	$CountOUMembers_Click={ 
 
	$TotalActiveAccounts = (Get-ADUser -filter "enabled -eq 'True'" -SearchBase $Usersaccountpath).count
					[Windows.Forms.MessageBox]::Show("There are $TotalActiveAccounts active Users.")  
 
	} 
            
	$LastLogonMembers_Click={ 
	
    $lluser = Get-ADUser -filter "enabled -eq 'true'" -SearchBase $Usersaccountpath -Properties * |
	Select Name,SamAccountname,Surname,@{n='LastLogon';e={[DateTime]::FromFileTime($_.LastLogon).ToString("yyyy-MM-dd")}} | 
	Out-GridView -title "Select a user account or cancel" -PassThru
	[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString
	} 
            	
	$Refresh_Click={
		# Clear the TextBoxes from text
		$txtFirstName.Text = $null
		$txtLastName.Text = $null
		$cboDescription.Text = $null
		$txtPassword.Text = NEW-GeneratePassword -NumCaps 3 -NumDigit 2 -NumLower 3 -NumSpecial 1
		$txtDN.Text = $null
		$txtsAM.Text = $null
		$txtuPN.Text = $null
		$btnModify.Visible = $False
		$btnSubmit.Visible = $True
		# Clear the RichTextBox Status
		$richtextboxStatus.Text = $null
	}
			
	$MenuExit_Click={
		$formMain.Close()
	}

	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formMain.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$cboGroup.remove_SelectedIndexChanged($cboGroup_SelectedIndexChanged) #20160204
			$cboDomain.remove_SelectedIndexChanged($cboDomain_SelectedIndexChanged)
			$txtLastName.remove_TextChanged($txtName_TextChanged)
			$txtFirstName.remove_TextChanged($txtName_TextChanged)
			$btnSubmit.remove_Click($btnSubmit_Click)
			$btnModify.remove_Click($btnModify_Click)
			$btnLookup.remove_Click($btnLookup_Click)
			$pictureboxGroup.add_MouseLeave($pictureboxGroup_MouseLeave)
			$pictureboxGroup.add_MouseHover($pictureboxGroup_MouseHover)
			$pictureboxPassword.add_MouseLeave($pictureboxPassword_MouseLeave)
			$pictureboxPassword.add_MouseHover($pictureboxPassword_MouseHover)
			$pictureboxDescription.add_MouseLeave($pictureboxDescription_MouseLeave)
			$pictureboxDescription.add_MouseHover($pictureboxDescription_MouseHover)
			$pictureboxLastName.add_MouseLeave($pictureboxLastName_MouseLeave)
			$pictureboxLastName.add_MouseHover($pictureboxLastName_MouseHover)
			$pictureboxFirstName.add_MouseLeave($pictureboxFirstName_MouseLeave)
			$pictureboxFirstName.add_MouseHover($pictureboxFirstName_MouseHover)
			$pictureboxDN.add_MouseLeave($pictureboxDN_MouseLeave)
			$pictureboxDN.add_MouseHover($pictureboxDN_MouseHover)
			$pictureboxAM.add_MouseLeave($pictureboxAM_MouseLeave)
			$pictureboxAM.add_MouseHover($pictureboxAM_MouseHover)
			$txtFirstName.remove_Leave($txtFirstName_Leave)
			$txtLastName.remove_Leave($txtLastName_Leave)
			$ResetPassword.remove_Click($ResetPassword_Click)
			$UnlockUser.remove_Click($UnlockUser_Click)
			$DisableUser.remove_Click($DisableUser_Click)
			$EnableUser.remove_Click($EnableUser_Click)
			$Refresh.remove_Click($Refresh_Click)
			$MenuExit.remove_Click($MenuExit_Click)
			$formMain.remove_Load($Form_StateCorrection_Load)
			$formMain.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	#
	# formMain
	#
	$formMain.Controls.Add($val1)
	$formMain.Controls.Add($val2)
	$formMain.Controls.Add($val3)
	$formMain.Controls.Add($grpBoxStatus)
	$formMain.Controls.Add($Logo) #20160501
	$formMain.Controls.Add($cboGroup) #20160204
	$formMain.Controls.Add($lblGroup) #20160204
	$formMain.Controls.Add($lblGroups) #20160204
	$formMain.Controls.Add($clbGroups) #20160204
	$formMain.Controls.Add($lblLists) #20160204
	$formMain.Controls.Add($clbLists) #20160204
	$formMain.Controls.Add($lblCombo) #20160204
	$formMain.Controls.Add($clbCombo) #20160204
	$formMain.Controls.Add($txtUPN)
	$formMain.Controls.Add($txtsAM)
	$formMain.Controls.Add($txtDN)
	$formMain.Controls.Add($labelUserPrincipalName)
	$formMain.Controls.Add($labelSamAccountName)
	$formMain.Controls.Add($labelDisplayName)
	$formMain.Controls.Add($SB)
	$formMain.Controls.Add($cboDescription)
	$formMain.Controls.Add($txtPassword)
	$formMain.Controls.Add($labelPassword)
	$formMain.Controls.Add($cboDomain)
	$formMain.Controls.Add($labelCurrentDomain)
	$formMain.Controls.Add($txtLastName)
	$formMain.Controls.Add($cboPath)
	$formMain.Controls.Add($labelOU)
	$formMain.Controls.Add($txtFirstName)
	$formMain.Controls.Add($btnSubmit)
	$formMain.Controls.Add($btnModify)
	$formMain.Controls.Add($btnLookup)
	$formMain.Controls.Add($btnClear)
	$formMain.Controls.Add($labelDescription)
	$formMain.Controls.Add($labelLastName)
	$formMain.Controls.Add($labelFirstName)
	$formMain.Controls.Add($menustrip1)
	$formMain.AcceptButton = $btnSubmit	
	$formMain.AcceptButton = $btnModify
	$formMain.AcceptButton = $btnLookup
	$formMain.ClientSize = '600, 700' #subtract 16,35 pts for borders
	$System_Windows_Forms_MenuStrip_1 = New-Object System.Windows.Forms.MenuStrip
	$System_Windows_Forms_MenuStrip_1.Location = '0, 0'
	$System_Windows_Forms_MenuStrip_1.Name = ""
	$System_Windows_Forms_MenuStrip_1.Size = '271, 24'
	$System_Windows_Forms_MenuStrip_1.TabIndex = 1
	$System_Windows_Forms_MenuStrip_1.Visible = $False
	$formMain.MainMenuStrip = $System_Windows_Forms_MenuStrip_1
	$formMain.Name = "formMain"
	$formMain.ShowIcon = $False
	$formMain.StartPosition = 'CenterScreen'
	$formMain.FormBorderStyle = "FixedToolWindow"
	$formMain.Text = $XML.Options.Product #20160204
	$formMain.add_Load($formMain_Load)
	#
	# val1
	#
	$val1.DataBindings.DefaultDataSourceUpdateMode = 0
	$val1.Location = '300, 110'
	$val1.Name = "val1"
	$val1.Size = '50, 50'
	$val1.TabIndex = 15
	#
	# val2
	#
	$val2.DataBindings.DefaultDataSourceUpdateMode = 0
	$val2.Location = '300, 140'
	$val2.Name = "val2"
	$val2.Size = '50, 50'
	$val2.TabIndex = 15
	#
	# val3
	#
	$val3.DataBindings.DefaultDataSourceUpdateMode = 0
	$val3.Location = '300, 240'
	$val3.Name = "val3"
	$val3.Size = '50, 50'
	$val3.TabIndex = 15
	#
	# Unit4 Logo
	#
	#$Logo.imagelocation = "\unit4icons\unit4logo.png"
	#$Logo.sizemode = "StretchImage"
	#$Logo.Location = '505, 40'
	#$Logo.InitialImage = [System.Drawing.Image]::FromFile('\unit4icons\unit4logo.png')
	#$Logo.Name = "Unit4Logo"
	#
	# grpBoxStatus
	#
	$grpBoxStatus.Controls.Add($richtextboxStatus)
	$grpBoxStatus.Location = '10, 360'
	$grpBoxStatus.Name = "grpBoxStatus"
	$grpBoxStatus.Size = '300, 260'
	$grpBoxStatus.TabIndex = 89
	$grpBoxStatus.TabStop = $False
	$grpBoxStatus.Text = "Status"
	#
	# richtextboxStatus
	#
	$richtextboxStatus.Location = '7, 20'
	$richtextboxStatus.Name = "richtextboxStatus"
	$richtextboxStatus.Size = '280, 260'
	$richtextboxStatus.TabIndex = 1
	$richtextboxStatus.Text = ""
	#
	# txtUPN
	#
	$txtUPN.Location = '118, 260'
	$txtUPN.Name = "txtUPN"
	$txtUPN.Size = '173, 20'
	$txtUPN.TabIndex = 7
	#
	# txtsAM
	#
	$txtsAM.Location = '118, 230'
	$txtsAM.Name = "txtsAM"
	$txtsAM.Size = '173, 20'
	$txtsAM.TabIndex = 6
	#
	# txtDN
	#
	$txtDN.Location = '118, 200'
	$txtDN.Name = "txtDN"
	$txtDN.Size = '173, 20'
	$txtDN.TabIndex = 5
	#
	# labelUserPrincipalName
	#
	$labelUserPrincipalName.Location = '10, 260'
	$labelUserPrincipalName.Name = "labelUserPrincipalName"
	$labelUserPrincipalName.Size = '100, 23'
	$labelUserPrincipalName.TabIndex = 48
	$labelUserPrincipalName.Text = "userPrincipalName"
	$labelUserPrincipalName.TextAlign = 'MiddleLeft'
	#
	# labelSamAccountName
	#
	$labelSamAccountName.Location = '10, 230'
	$labelSamAccountName.Name = "labelSamAccountName"
	$labelSamAccountName.Size = '100, 23'
	$labelSamAccountName.TabIndex = 47
	$labelSamAccountName.Text = "samAccountName"
	$labelSamAccountName.TextAlign = 'MiddleLeft'
	#
	# labelDisplayName
	#
	$labelDisplayName.Location = '10, 200'
	$labelDisplayName.Name = "labelDisplayName"
	$labelDisplayName.Size = '100, 23'
	$labelDisplayName.TabIndex = 46
	$labelDisplayName.Text = "Display Name"
	$labelDisplayName.TextAlign = 'MiddleLeft'
	#
	# SB
	#
	$SB.Location = '0, 575'
	$SB.Name = "SB"
	$SB.Size = '304, 22'
	$SB.TabIndex = 45
	$SB.Text = "Ready"
	#
	# labelPassword
	#
	$labelPassword.Location = '10, 290'
	$labelPassword.Name = "labelPassword"
	$labelPassword.Size = '100, 23'
	$labelPassword.TabIndex = 41
	$labelPassword.Text = "Password"
	$labelPassword.TextAlign = 'MiddleLeft'
	#
	# labelCurrentDomain
	#
	$labelCurrentDomain.Location = '10, 35'
	$labelCurrentDomain.Name = "labelCurrentDomain"
	$labelCurrentDomain.Size = '100, 23'
	$labelCurrentDomain.TabIndex = 39
	$labelCurrentDomain.Text = "Current Domain"
	$labelCurrentDomain.TextAlign = 'MiddleLeft'
	#
	# labelOU
	#
	$labelOU.Location = '10, 65'
	$labelOU.Name = "labelOU"
	$labelOU.Size = '36, 23'
	$labelOU.TabIndex = 26
	$labelOU.Text = "OU"
	$labelOU.TextAlign = 'MiddleLeft'
	#
	# lblGroup									#20141120
	#
	$lblGroup.Location = '350, 40'
	$lblGroup.Name = "lblGroup"
	$lblGroup.Size = '100, 23'
	$lblGroup.TabIndex = 9
	$lblGroup.Text = "Groups Template"
	$lblGroup.TextAlign = 'MiddleLeft'
	#
	# cboGroup									#20141120
	#
	$cboGroup.FormattingEnabled = $True
	$cboGroup.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$cboGroup.Location = '450, 40'
	$cboGroup.Name = "cboGroup"
	$cboGroup.Size = '100, 25'
	$cboGroup.TabIndex = 12
	$cboGroup.add_SelectedIndexChanged($cboGroup_SelectedIndexChanged)
	#
	# pictureboxGroup
	#
	$pictureboxGroup.Location = '245, 16'
	$pictureboxGroup.Name = "pictureboxGroup"
	$pictureboxGroup.Size = '24, 24'
	$pictureboxGroup.TabIndex = 85
	$pictureboxGroup.TabStop = $False
	$pictureboxGroup.add_MouseLeave($pictureboxGroup_MouseLeave)
	$pictureboxGroup.add_MouseHover($pictureboxGroup_MouseHover)
	#
	# lblLists									#20160204
	#
	$lblLists.Location = '350, 65'
	$lblLists.Name = "lblLists"
	$lblLists.Size = '100, 23'
	$lblLists.Width = 210
	$lblLists.Text = "Live Groups"
	$lblLists.TextAlign = 'MiddleLeft'
	#
	# clbLists									#20160204
	#
	$clbLists.Location = '350, 90'
	$clbLists.Name = "clbLists"
	$clbLists.Size = '250, 170'
	$clbLists.CheckOnClick = $true;
	$clbLists.TabIndex = 17

	#
	# lblGroups									#20160204
	#
	$lblGroups.Location = '350, 265'
	$lblGroups.Name = "lblGroups"
	$lblGroups.Size = '100, 23'
	$lblGroups.Width = 210
	$lblGroups.Text = "Test Groups"
	$lblGroups.TextAlign = 'MiddleLeft'
	#
	# clbGroups									#20160204
	#
	$clbGroups.Location = '350, 290'
	$clbGroups.Name = "clbGroups"
	$clbGroups.Size = '250, 170'
	$clbGroups.CheckOnClick = $true;
	$clbGroups.TabIndex = 18

	#
	# lblCombo									#20160204
	#
	$lblCombo.Location = '350, 460'
	$lblCombo.Name = "lblCombo"
	$lblCombo.Size = '100, 23'
	$lblCombo.Width = 210
	$lblCombo.Text = "Dev Groups"
	$lblCombo.TextAlign = 'MiddleLeft'
	#
	# clbCombo									#20160204
	#
	$clbCombo.Location = '350, 485'
	$clbCombo.Name = "clbCombo"
	$clbCombo.Size = '250, 170'
	$clbCombo.CheckOnClick = $true;
	$clbCombo.TabIndex = 18
	#
	# btnSubmit
	#
	$btnSubmit.Location = '150, 320'
	$btnSubmit.Name = "btnSubmit"
	$btnSubmit.Size = '75, 25'
	$btnSubmit.TabIndex = 10
	$btnSubmit.Text = "Submit"
	$btnSubmit.UseVisualStyleBackColor = $True
	$btnSubmit.add_Click($btnSubmit_Click)
	#
	# btnLookup
	#
	$btnLookup.Location = '40, 320'
	$btnLookup.Name = "btnLookup"
	$btnLookup.Size = '80, 25'
	$btnLookup.TabIndex = 10
	$btnLookup.Text = "Lookup User"
	$btnLookup.UseVisualStyleBackColor = $True
	$btnLookup.add_Click($btnLookup_Click)
	#
	# btnModify
	#
	$btnModify.Location = '150, 320'
	$btnModify.Name = "btnModify"
	$btnModify.Size = '75, 25'
	$btnModify.TabIndex = 10
	$btnModify.Text = "Modify User"
	$btnModify.UseVisualStyleBackColor = $True
	$btnModify.add_Click($btnModify_Click)
	#
	# btnClear
	#
	$btnClear.Location = '10, 637'
	$btnClear.Name = "btnClear"
	$btnClear.Size = '75, 20'
	$btnClear.TabIndex = 90
	$btnClear.Text = "Clear Status"
	$btnClear.UseVisualStyleBackColor = $True
	$btnClear.add_Click($btnClear_Click)
	#
	# txtPassword
	#
	$txtPassword.Location = '118, 290'
	$txtPassword.Name = "txtPassword"
	$txtPassword.Size = '173, 20'
	$txtPassword.TabIndex = 8
	$txtPassword.UseSystemPasswordChar = $false
	$txtPassword.ReadOnly = $true
	#
	# pictureboxPassword
	#
	$pictureboxPassword.Location = '245, 16'
	$pictureboxPassword.Name = "pictureboxPassword"
	$pictureboxPassword.Size = '24, 24'
	$pictureboxPassword.TabIndex = 91
	$pictureboxPassword.TabStop = $False
	$pictureboxPassword.add_MouseLeave($pictureboxPassword_MouseLeave)
	$pictureboxPassword.add_MouseHover($pictureboxPassword_MouseHover)
	#
	# labelDescription
	#
	$labelDescription.Location = '10, 170'
	$labelDescription.Name = "labelDescription"
	$labelDescription.Size = '100, 23'
	$labelDescription.TabIndex = 92
	$labelDescription.Text = "Description"
	$labelDescription.TextAlign = 'MiddleLeft'
	#
	# labelLastName
	#
	$labelLastName.Location = '10, 140'
	$labelLastName.Name = "labelLastName"
	$labelLastName.Size = '100, 23'
	$labelLastName.TabIndex = 93
	$labelLastName.Text = "Last Name"
	$labelLastName.TextAlign = 'MiddleLeft'
	
	#
	# labelFirstName
	#
	$labelFirstName.Location = '10, 110'
	$labelFirstName.Name = "labelFirstName"
	$labelFirstName.Size = '100, 23'
	$labelFirstName.TabIndex = 94
	$labelFirstName.Text = "First Name"
	$labelFirstName.TextAlign = 'MiddleLeft'
	#
	# cboDescription
	#
	$cboDescription.FormattingEnabled = $True
	$cboDescription.Location = '118, 170'
	$cboDescription.Name = "cboDescription"
	$cboDescription.Size = '173, 21'
	$cboDescription.TabIndex = 4
	#
	# pictureboxDescription
	#
	$pictureboxDescription.Location = '245, 16'
	$pictureboxDescription.Name = "pictureboxDescription"
	$pictureboxDescription.Size = '24, 24'
	$pictureboxDescription.TabIndex = 95
	$pictureboxDescription.TabStop = $False
	$pictureboxDescription.add_MouseLeave($pictureboxDescription_MouseLeave)
	$pictureboxDescription.add_MouseHover($pictureboxDescription_MouseHover)
	#
	# txtLastName
	#
	$txtLastName.Location = '118, 140'
	$txtLastName.Name = "txtLastName"
	$txtLastName.Size = '173, 20'
	$txtLastName.TabIndex = 3
	$txtLastName.Controls.Add($pictureboxLastName)
	$txtLastName.add_Leave($txtLastName_Leave)
	#
	#region Binary Data
	#
	$pictureboxLastName.BackgroundImage = [System.Convert]::FromBase64String('
iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABGdBTUEAALGPC/xhBQAAA8lJREFU
SEutVmtIVVkU/q5YlIH2w0rTpim7ak+J6Qk9GIqcqaz+RZQhNGFZRI3ZA0nK6V3TmGVmRVkpUoT0
o/fDJkLLyuw56dgbetmDrD8peVffOvvcuF2PNMYs+DjHu9f+1lrfWmdv0QJzEW1t6Pv/Ym4iE66A
MnT8sQ7RgzyIITp1q7N+0zUgWh1bapFEEaIGNyJxk+CvG4L8p4KCF4LCl4K9zwSbbwuSsgQ9hjTS
94C95z9ZPII7vcHUbEFWlWD7Q8G2+4Lsaga6K/jzH8FGkm/i0/vb9BxBSNhb7v3FUDRvCQjr2YC0
k4JckubcE2z5l9mSSIMpmRJvYIC1rGr1dcHKa4L1twSLTgnCejWQY4KhamoxCIn8gLTTJH9gk9cI
thL6rgF9oWsb7wj+YIAVV/isEKQySHtyKFcTcwWcQ+JOH3Jm7oPAnBqZc75Wks6wD0ruXdPqtIpl
lwQZ5YJpO8Ti8rMR6PGzcVZyr7Y++O30c/HamOInTdaReVWwtFSQXiZwkwsYbqiN7UQSI3vJtXRt
pA8mHn4sHo9HPjV6ZOB+SuS3bvUlnQHSzgsmb9YAOwy1WmCbGqxj07RkbwMdMGRfjcTtZgIOaxa0
ioV/CxacEXJW2+xohQ7uBktXnRTVszmsqpReeXclLItT47SuSNUAJYLQqHpyB2qAIHT7yeiv2etE
+MG95ZZsr6iVR+8+WjLFF7BSBz8LKtE8TmJEX5UpyAToPsA0ag3L1GnwQ+iaCsm/Vmu3WCR+Lyt1
8LOgEs3luIb3+RIgEBE9660vlBJYk+CAuOxKm54B9nAIHHwsLDgrSDnxlURA66BqrL/JCvhlLmKJ
DojdcMWmZ4Bd9HXwsaDZJx/RJlcZcmN5mJ1vJkE1/J1N8kPs2nKbngHymIiDj5X97OOCCetUnlxD
bWwY+o8zZ4vqqE3yQ+yqMpueAXI5LQ4+ljTJRwVRIz3kHGqoveYKKEFKIWdZzxQ2Sp19ELe61KYX
GbuNPn7rFpR8Eo93V8Apm/Uri0Zo1/dYwlIzLgvms1zdQHRZWiLFlS9sepGSqtcSncEk7HXMOmae
04sEwZ3fkSvKUDa18YjsU49UHtfpF00l3Nxm1lH5gaesL9qlkHAmm+kNksjqO7g/kuObd0I8L483
mMLbavEF03T9MucwqDYwmdlqxvpu/U3yXzMF7UJfce8oQ/Ft0+vvILoOaETCCo4eM1XJtJE6hqr3
jEOC0UsEnft9om8BEa4bW2p6caxk0y6ifUQdwnt7eGt5EEKdXa5Sri0nmtW7pfYd/7YAnwEFkWDv
PycN5gAAAABJRU5ErkJggg==')
	#endregion
	#
	# pictureboxLastName
	#
	$pictureboxLastName.Location = '400, 50'
	$pictureboxLastName.Name = "pictureboxLastName"
	$pictureboxLastName.Size = '24, 24'
	$pictureboxLastName.TabIndex = 99
	$pictureboxLastName.TabStop = $False
	$txtLastName.add_TextChanged($txtName_TextChanged)
	$pictureboxLastName.add_MouseLeave($pictureboxLastName_MouseLeave)
	$pictureboxLastName.add_MouseHover($pictureboxLastName_MouseHover)
	#
	# txtFirstName
	#
	$txtFirstName.Location = '118, 110'
	$txtFirstName.Name = "txtFirstName"
	$txtFirstName.Size = '173, 20'
	$txtFirstName.TabIndex = 2
	$txtFirstName.add_Leave($txtFirstName_Leave)
	#
	#region Binary Data
	#
	$pictureboxFirstName.BackgroundImage = [System.Convert]::FromBase64String('
iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABGdBTUEAALGPC/xhBQAAA8lJREFU
SEutVmtIVVkU/q5YlIH2w0rTpim7ak+J6Qk9GIqcqaz+RZQhNGFZRI3ZA0nK6V3TmGVmRVkpUoT0
o/fDJkLLyuw56dgbetmDrD8peVffOvvcuF2PNMYs+DjHu9f+1lrfWmdv0QJzEW1t6Pv/Ym4iE66A
MnT8sQ7RgzyIITp1q7N+0zUgWh1bapFEEaIGNyJxk+CvG4L8p4KCF4LCl4K9zwSbbwuSsgQ9hjTS
94C95z9ZPII7vcHUbEFWlWD7Q8G2+4Lsaga6K/jzH8FGkm/i0/vb9BxBSNhb7v3FUDRvCQjr2YC0
k4JckubcE2z5l9mSSIMpmRJvYIC1rGr1dcHKa4L1twSLTgnCejWQY4KhamoxCIn8gLTTJH9gk9cI
thL6rgF9oWsb7wj+YIAVV/isEKQySHtyKFcTcwWcQ+JOH3Jm7oPAnBqZc75Wks6wD0ruXdPqtIpl
lwQZ5YJpO8Ti8rMR6PGzcVZyr7Y++O30c/HamOInTdaReVWwtFSQXiZwkwsYbqiN7UQSI3vJtXRt
pA8mHn4sHo9HPjV6ZOB+SuS3bvUlnQHSzgsmb9YAOwy1WmCbGqxj07RkbwMdMGRfjcTtZgIOaxa0
ioV/CxacEXJW2+xohQ7uBktXnRTVszmsqpReeXclLItT47SuSNUAJYLQqHpyB2qAIHT7yeiv2etE
+MG95ZZsr6iVR+8+WjLFF7BSBz8LKtE8TmJEX5UpyAToPsA0ag3L1GnwQ+iaCsm/Vmu3WCR+Lyt1
8LOgEs3luIb3+RIgEBE9660vlBJYk+CAuOxKm54B9nAIHHwsLDgrSDnxlURA66BqrL/JCvhlLmKJ
DojdcMWmZ4Bd9HXwsaDZJx/RJlcZcmN5mJ1vJkE1/J1N8kPs2nKbngHymIiDj5X97OOCCetUnlxD
bWwY+o8zZ4vqqE3yQ+yqMpueAXI5LQ4+ljTJRwVRIz3kHGqoveYKKEFKIWdZzxQ2Sp19ELe61KYX
GbuNPn7rFpR8Eo93V8Apm/Uri0Zo1/dYwlIzLgvms1zdQHRZWiLFlS9sepGSqtcSncEk7HXMOmae
04sEwZ3fkSvKUDa18YjsU49UHtfpF00l3Nxm1lH5gaesL9qlkHAmm+kNksjqO7g/kuObd0I8L483
mMLbavEF03T9MucwqDYwmdlqxvpu/U3yXzMF7UJfce8oQ/Ft0+vvILoOaETCCo4eM1XJtJE6hqr3
jEOC0UsEnft9om8BEa4bW2p6caxk0y6ifUQdwnt7eGt5EEKdXa5Sri0nmtW7pfYd/7YAnwEFkWDv
PycN5gAAAABJRU5ErkJggg==')
	#endregion
	#
	# pictureboxFirstName
	#
	$pictureboxFirstName.Location = '400, 300'
	$pictureboxFirstName.Name = "pictureboxFirstName"
	$pictureboxFirstName.Size = '24, 24'
	$pictureboxFirstName.TabIndex = 98
	$pictureboxFirstName.TabStop = $False
	$pictureboxFirstName.add_TextChanged($txtName_TextChanged)
	$pictureboxFirstName.add_MouseLeave($pictureboxFirstName_MouseLeave)
	$pictureboxFirstName.add_MouseHover($pictureboxFirstName_MouseHover)
	#
	# cboPath
	#
	$cboPath.FormattingEnabled = $false
	$cboPath.Location = '45, 65'
	$cboPath.Name = "cboPath"
	$cboPath.Size = '247, 21'
	$cboPath.TabIndex = 97

	#
	# cboDomain
	#
	$cboDomain.FormattingEnabled = $false
	$cboDomain.Location = '118, 35'
	$cboDomain.Name = "cboDomain"
	$cboDomain.Size = '173, 21'
	$cboDomain.TabIndex = 1
	$cboDomain.add_SelectedIndexChanged($cboDomain_SelectedIndexChanged)
	#----------------------------------------------
	#----------------------------------------------
	#
	# menustrip1
	#
	[void]$menustrip1.Items.Add($fileToolStripMenuItem)
	[void]$menustrip1.Items.Add($SingleUserToolStripMenuItem)
	[void]$menustrip1.Items.Add($groupmanagementToolStripMenuItem)
	$menustrip1.Location = '0, 0'
	$menustrip1.Name = "menustrip1"
	$menustrip1.Size = '304, 24'
	$menustrip1.TabIndex = 52
	$menustrip1.Text = "menustrip1"
	#
	# fileToolStripMenuItem
	#
	[void]$fileToolStripMenuItem.DropDownItems.Add($Refresh)
	[void]$fileToolStripMenuItem.DropDownItems.Add($MenuExit)
	$fileToolStripMenuItem.Name = "fileToolStripMenuItem"
	$fileToolStripMenuItem.Size = '37, 20'
	$fileToolStripMenuItem.Text = "File"
	#
	# SingleUserToolStripMenuItem
	#
	[void]$SingleUserToolStripMenuItem.DropDownItems.Add($ResetPassword)
	[void]$SingleUserToolStripMenuItem.DropDownItems.Add($DisableUser)
	[void]$SingleUserToolStripMenuItem.DropDownItems.Add($EnableUser)
	[void]$SingleUserToolStripMenuItem.DropDownItems.Add($CopyUser)
	$SingleUserToolStripMenuItem.Name = "SingleUserToolStripMenuItem"
	$SingleUserToolStripMenuItem.Size = '37, 20'
	$SingleUserToolStripMenuItem.Text = "Single User Tool"	
	#
	# groupmanagementToolStripMenuItem
	#
	[void]$groupmanagementToolStripMenuItem.DropDownItems.Add($GroupManagement)
	[void]$groupmanagementToolStripMenuItem.DropDownItems.Add($GroupList)
	[void]$groupmanagementToolStripMenuItem.DropDownItems.Add($CountOUMembers)
	[void]$groupmanagementToolStripMenuItem.DropDownItems.Add($LastLogonMembers)
	$groupmanagementToolStripMenuItem.Name = "groupmanagementToolStripMenuItem"
	$groupmanagementToolStripMenuItem.Size = '37, 20'
	$groupmanagementToolStripMenuItem.Text = "Group Management Tool"
	
	#----------------------------------------------
	#----------------------------------------------
	#----------Menu Items--------------------------
	#----------------------------------------------
	#
	# ResetPassword
	#
	$ResetPassword.Name = "ResetPassword"
	$ResetPassword.Size = '185, 22'
	$ResetPassword.Text = "Reset Password and Unlock Account"
	$ResetPassword.add_Click($ResetPassword_Click)
	#
	# DisableUser
	#
	$DisableUser.Name = "DisableUser"
	$DisableUser.Size = '185, 22'
	$DisableUser.Text = "Disable User"
	$DisableUser.add_Click($DisableUser_Click)
	#
	# EnableUser
	#
	$EnableUser.Name = "EnableUser"
	$EnableUser.Size = '185, 22'
	$EnableUser.Text = "Enable User"
	$EnableUser.add_Click($EnableUser_Click)
	#
	# GroupManagement
	#
	$GroupManagement.Name = "GroupManagement"
	$GroupManagement.Size = '185, 22'
	$GroupManagement.Text = "Group Management"
	$GroupManagement.add_Click($GroupManagement_Click)
	#
	# GroupList
	#
	$GroupList.Name = "GroupList"
	$GroupList.Size = '185, 22'
	$GroupList.Text = "Find Users for a Group"
	$GroupList.add_Click($GroupUserList_Click)
	#
	# CountOUMembers
	#
	$CountOUMembers.Name = "CountOUMembers"
	$CountOUMembers.Size = '185, 22'
	$CountOUMembers.Text = "Count Members"
	$CountOUMembers.add_Click($CountOUMembers_Click)
	#
	# LastLogonMembers
	#
	$LastLogonMembers.Name = "LastLogonMembers"
	$LastLogonMembers.Size = '185, 22'
	$LastLogonMembers.Text = "Last Logon Members"
	$LastLogonMembers.add_Click($LastLogonMembers_Click)
	#
	# CopyUser
	#
	$CopyUser.Name = "CopyUser"
	$CopyUser.Size = '185, 22'
	$CopyUser.Text = "Copy User"
	$CopyUser.add_Click($CopyUser_Click)
	#
	# Refresh
	#
	$Refresh.Name = "Refresh"
	$Refresh.Size = '185, 22'
	$Refresh.Text = "Main\Refresh"
	$Refresh.add_Click($Refresh_Click)
	#
	# MenuExit
	#
	$MenuExit.Name = "MenuExit"
	$MenuExit.Size = '185, 22'
	$MenuExit.Text = "Exit"
	$MenuExit.add_Click($MenuExit_Click)
	#endregion Generated Form Code
	
	#----------------------------------------------
	#----------------------------------------------
	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formMain.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formMain.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formMain.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formMain.ShowDialog()
} 
 #End Function

#Call OnApplicationLoad to initialize
if((OnApplicationLoad) -eq $true)
{
	#Call the form
	Call-ANUC_pff | Out-Null
	#Perform cleanup
	OnApplicationExit
}
