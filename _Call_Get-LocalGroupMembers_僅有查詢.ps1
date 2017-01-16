###	$LoginID = "KGIBANK\CSMBMGR"
###	$LoginID = "CSMBMGR"
###	$LoginID = "CSMBADMIN"
###	$LoginID = "DCAD\CSMBAdmin"
$LoginID = "CDIBANK\CDIB3272"

$CredMonitoradm = Get-Credential -Credential $LoginID
$host.ui.RawUI.WindowTitle = “USE-ID__$LoginID ”
#####################################################################################################################
#####################################################################################################################
$SubNet = "172.18.1"
for ($N = 1 ; $N -lt 255 ; $N++)
	{$IP=$SubNet+"."+$N
	$computername = "$IP"
	if (test-connection $IP -Quiet -Count 1) {
				.\Get-LocalGroupMembers.ps1 -ComputerName $computername -OutputDir C:\Users\cdib3272\Desktop\Get-LocalGroupMembers
				}
	else {write-host "This IP is offline：$IP" -ForegroundColor Red
		"This IP is offline：$IP" | Out-File .\$SubNet.xx_ConnectError.Log -Append}
	}