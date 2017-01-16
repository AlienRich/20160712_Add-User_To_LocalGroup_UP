$LoginID = "YourDomain\YourID"	##設定使用權限

###使用前先設定密碼、網段
###---->>>	$CreateLocalUser.SetPassword("SetPassword")		###	由此變更密碼
###---->>>	$SubNet = "192.168.1"	###	由此變更網段
###---->>>	$DomainName = "Domain"			###	由此變更
###---->>>	$DomainUser = "DomainGroup"		###	由此變更

$CredMonitoradm = Get-Credential -Credential $LoginID
$host.ui.RawUI.WindowTitle = “USE-ID === $LoginID”
#####################################################################################################################
#####################################################################################################################
$SubNet = "192.168.1"	###	由此變更網段
for ($N = 1 ; $N -lt 255 ; $N++)
	{$IP=$SubNet+"."+$N
	$computername = "$IP"
	if (test-connection $IP -Quiet -Count 1) {
			#### Create new local Admin user for script purposes
			$GroupName = 'Administrators'
			$user = 'RMAdmin'
			$Computer = [ADSI]"WinNT://$ComputerName,Computer"
			$CreateLocalUser = $Computer.Create("User", "$user")
			$CreateLocalUser.SetPassword("SetPassword")		###	由此變更密碼
			$CreateLocalUser.SetInfo()
			$CreateLocalUser.FullName = "Local-Admin by SP-Group"
			$CreateLocalUser.SetInfo()
			$CreateLocalUser.UserFlags = 64 + 65536		# ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
			$CreateLocalUser.SetInfo()
			
			#### Add local-User to Local-group (administrators)
			([ADSI]"WinNT://$ComputerName/Administrators,group").psbase.Invoke("Add",([ADSI]"WinNT://$ComputerName/$user,User").path)
			
			#### Add Domain-User to Local-group (administrators)
			$DomainName = "Domain"			###	由此變更
			$DomainUser = "DomainGroup"		###	由此變更
			([ADSI]"WinNT://$ComputerName/Administrators,group").psbase.Invoke("Add",([ADSI]"WinNT://$DomainName/$DomainUser,User").path)
			
			#### PSEXEC 加入RMADMIN、Domain\DomainGroup 到 Administrators 群組
			psexec \\$computername cmd /c "net localgroup $GroupName $user /add"
			psexec \\$computername cmd /c "net localgroup $GroupName Domain\DomainGroup /add"

			#### 確認 Administrators 群組成員 (RMADMIN、Domain\DomainGroup)
			$ADSI = [ADSI]("WinNT://$ComputerName")
			$GroupCHK = $ADSI.Children.Find($GroupName,'group')
			$GroupCHKList = $GroupCHK.psbase.invoke('members') | ForEach { $_.GetType().InvokeMember("Name","GetProperty",$Null,$_,$Null)}
			$AdminListToFile= foreach ($AdminList in $GroupCHKList) {$computername + ";" + $Adminlist}
			$AdminListToFile | Out-file -Encoding utf8 -Append .\$SubNet.xx_List-Local-Admin-Group.csv

			#### 匯出全部 Local-groups 成員清單(不含Domain-User加入local-group)
				$adsi = [ADSI]"WinNT://$computername"
				$SRVUGList = $adsi.Children | where {$_.SchemaClassName -eq 'user'} | 
				Foreach-Object {
					$groups = $_.Groups() | Foreach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
					##  $_ | Select-Object @{n='UserName';e={$_.Name}},@{n='Groups';e={$groups -join ';'}}
					$_ | Select-Object @{n='Local-ID';e={$_.Name}},@{n='Local-Groups';e={$groups -join ';'}}
					}
				$SRVUGList | add-member -Name "IP" -Value $computername -MemberType NoteProperty
				$SRVUGList | Export-Csv -NoTypeInformation -Append -Encoding UTF8 -Path .\$SubNet.xx_List-Local-User-Group.csv
				
			#### 使用Get-LocalGroupMembers.ps1 匯出 Local-Administrators-Group
				.\Get-LocalGroupMembers.ps1 -ComputerName $computername -OutputDir .\
				
				}
	else {write-host "This IP is offline：$IP" -ForegroundColor Red
		"This IP is offline：$IP" | Out-File .\$SubNet.xx_ConnectError.Log -Append}
	}
#####################################################################################################################
#####################################################################################################################
