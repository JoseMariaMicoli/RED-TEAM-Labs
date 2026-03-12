<powershell>
$ErrorActionPreference = "Stop"

$hostname = "${hostname}"
$domain = "${ad_domain_name}"
$dcIp = "${dc_ip}"
$adminPasswordPlain = "${windows_admin_password}"
$adminOverPeer = "${admin_over_peer}"
$peerAdminUser = "${peer_admin_user}"
$netbios = $domain.Split(".")[0].ToUpper()
$flagApt28Lab02_1 = "${flag_apt28_lab02_1}"
$flagApt29Lab02_1 = "${flag_apt29_lab02_1}"
$flagLazarusLab02_1 = "${flag_lazarus_lab02_1}"

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

# Seed lab-only artifacts and flags (rotating per deployment).
$caseDir = "C:\\ProgramData\\Nyxera\\LAB02\\Case"
$flagDir = "C:\\ProgramData\\Nyxera\\LAB02\\Flags"
New-Item -ItemType Directory -Path $caseDir -Force | Out-Null
New-Item -ItemType Directory -Path $flagDir -Force | Out-Null

@"
LAB02 Workstation (Lab-Only)

This host contains dummy-but-realistic artifacts for APT-aligned exercises.
"@ | Set-Content -Path (Join-Path $caseDir "README.txt") -Encoding UTF8 -Force

@"
Host: $hostname
Domain: $domain
Role: workstation

Notes (Dummy):
- Keep artifacts and flags lab-only.
- Validate flags operator-side using the per-deployment seed from Terraform.
"@ | Set-Content -Path (Join-Path $caseDir "host-profile.txt") -Encoding UTF8 -Force

if ($flagApt28Lab02_1 -ne "") {
  $flagApt28Lab02_1 | Set-Content -Path (Join-Path $flagDir "APT28-LAB02-1.flag") -Encoding UTF8 -Force
}
if ($flagApt29Lab02_1 -ne "") {
  $flagApt29Lab02_1 | Set-Content -Path (Join-Path $flagDir "APT29-LAB02-1.flag") -Encoding UTF8 -Force

  @"
IT Support Notes (Dummy)

- Workstation build checklist
- Domain troubleshooting hints
- Internal naming: LumenWorks
"@ | Set-Content -Path (Join-Path $caseDir "it-support-notes.txt") -Encoding UTF8 -Force
}
if ($flagLazarusLab02_1 -ne "") {
  $flagLazarusLab02_1 | Set-Content -Path (Join-Path $flagDir "LAZARUS-LAB02-1.flag") -Encoding UTF8 -Force

  @"
Finance Ops (Dummy)

Quarterly close checklist:
- Validate approvals
- Prepare transfer templates
- Archive reports
"@ | Set-Content -Path (Join-Path $caseDir "finance-ops-notes.txt") -Encoding UTF8 -Force
}
</powershell>
