<powershell>
$ErrorActionPreference = "Stop"

$hostname = "${hostname}"
$domain = "${ad_domain_name}"
$dcIp = "${dc_ip}"
$adminPasswordPlain = "${windows_admin_password}"
$adminOverPeer = "${admin_over_peer}"
$peerAdminUser = "${peer_admin_user}"
$netbios = $domain.Split(".")[0].ToUpper()

function Set-AdministratorPassword([string]$plain) {
  $secure = ConvertTo-SecureString $plain -AsPlainText -Force
  Set-LocalUser -Name "Administrator" -Password $secure
}

function Set-Dns([string]$ip) {
  $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
  foreach ($adapter in $adapters) {
    try {
      Set-DnsClientServerAddress -InterfaceIndex $adapter.IfIndex -ServerAddresses $ip
    } catch {
      Write-Host "Unable to set DNS on adapter $($adapter.Name): $($_.Exception.Message)"
    }
  }
}

function Ensure-JoinTask {
  $dir = "C:\\ProgramData\\Nyxera\\LAB02"
  New-Item -ItemType Directory -Path $dir -Force | Out-Null

  $script = @"
`$ErrorActionPreference = 'Continue'
`$hostname = '$hostname'
`$domain = '$domain'
`$dcIp = '$dcIp'
`$adminPasswordPlain = '$adminPasswordPlain'
`$adminOverPeer = '$adminOverPeer'
`$peerAdminUser = '$peerAdminUser'
`$netbios = '$netbios'
`$marker = 'C:\\ProgramData\\Nyxera\\LAB02\\joined.marker'

function Set-Dns([string]`$ip) {
  `$adapters = Get-NetAdapter | Where-Object { `$_.Status -eq 'Up' }
  foreach (`$adapter in `$adapters) {
    try { Set-DnsClientServerAddress -InterfaceIndex `$adapter.IfIndex -ServerAddresses `$ip } catch {}
  }
}

Set-Dns `$dcIp

if (`$env:COMPUTERNAME -ne `$hostname) {
  Rename-Computer -NewName `$hostname -Force -Restart
  exit 0
}

`$cs = Get-CimInstance -ClassName Win32_ComputerSystem
if (-not `$cs.PartOfDomain) {
  `$secure = ConvertTo-SecureString `$adminPasswordPlain -AsPlainText -Force
  `$cred = New-Object System.Management.Automation.PSCredential("Administrator@`$domain", `$secure)

  for (`$i = 1; `$i -le 120; `$i++) {
    try {
      Add-Computer -DomainName `$domain -Credential `$cred -Force -ErrorAction Stop
      Restart-Computer -Force
      exit 0
    } catch {
      Start-Sleep -Seconds 15
    }
  }
  exit 1
}

if (-not (Test-Path `$marker)) {
  if (`$adminOverPeer -eq 'true') {
    for (`$i = 1; `$i -le 120; `$i++) {
      cmd /c "net localgroup Administrators /add `"`$netbios\\`$peerAdminUser`""
      if (`$LASTEXITCODE -eq 0) { break }
      Start-Sleep -Seconds 10
    }
  }
  New-Item -ItemType File -Path `$marker -Force | Out-Null
}

schtasks /Change /TN "Nyxera-LAB02-JoinDomain" /Disable | Out-Null
exit 0
"@

  $path = Join-Path $dir "join-domain.ps1"
  Set-Content -Path $path -Value $script -Encoding UTF8 -Force

  $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$path`""
  $trigger = New-ScheduledTaskTrigger -AtStartup
  Register-ScheduledTask -TaskName "Nyxera-LAB02-JoinDomain" -Action $action -Trigger $trigger -RunLevel Highest -User "SYSTEM" -Force | Out-Null
}

Write-Host "Configuring LAB02 Windows workstation: $hostname"
Set-AdministratorPassword $adminPasswordPlain
Set-Dns $dcIp
Ensure-JoinTask
</powershell>
