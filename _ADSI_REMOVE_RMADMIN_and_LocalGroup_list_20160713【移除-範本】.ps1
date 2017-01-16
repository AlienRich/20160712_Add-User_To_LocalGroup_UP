$LoginID = "Domain\UserName"



$CredMonitoradm = Get-Credential -Credential $LoginID
$host.ui.RawUI.WindowTitle = “USE-ID === $LoginID”
#####################################################################################################################
#####################################################################################################################
$SubNet = "192.168.1"
for ($N = 1 ; $N -lt 255 ; $N++)
	{$IP=$SubNet+"."+$N
	$computername = "$IP"
	if (test-connection $IP -Quiet -Count 1) {
			#### Create new local Admin user for script purposes
			$GroupName = 'Administrators'
			$user = 'RMAdmin'
			$Computer = [ADSI]"WinNT://$ComputerName,Computer"
			$RemoveLocalUser = $Computer.delete("User", "$user")
			
			#### remove local-User form Local-group (administrators)
			([ADSI]"WinNT://$ComputerName/Administrators,group").psbase.Invoke("Remove",([ADSI]"WinNT://$ComputerName/$user,User").path)
			
			#### Add Domain-User to Local-group (administrators)
			$DomainName = "kgibank"
			$DomainUser = "gallsrvma"
			([ADSI]"WinNT://$ComputerName/Administrators,group").psbase.Invoke("Remove",([ADSI]"WinNT://$DomainName/$DomainUser,User").path)
			
			#### PSEXEC 自Administrators 群組移除RMADMIN、kgibank\gallsrvma
			psexec \\$computername cmd /c "net user $user /del"
			### psexec \\$computername cmd /c "net localgroup $GroupName $user /del"
			psexec \\$computername cmd /c "net localgroup $GroupName kgibank\gallsrvma /del"

			#### 確認 Administrators 群組成員 (RMADMIN、kgibank\gallsrvma)
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
				.\__Get-LocalGroupMembers.ps1 -ComputerName $computername -OutputDir .\
				
				}
	else {write-host "This IP is offline：$IP" -ForegroundColor Red
		"This IP is offline：$IP" | Out-File .\$SubNet.xx_ConnectError.Log -Append}
	}
