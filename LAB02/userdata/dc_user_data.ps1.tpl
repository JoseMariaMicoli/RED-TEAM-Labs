<powershell>
$ErrorActionPreference = "Stop"

$hostname = "${hostname}"
$domain = "${ad_domain_name}"
$dsrm = "${ad_safe_mode_password}"
$dcIp = "${dc_ip}"
$adminPasswordPlain = "${windows_admin_password}"
$itUser = "${win10_01_user}"
$itUserPasswordPlain = "${win10_01_user_password}"
$netbios = $domain.Split(".")[0].ToUpper()
$flagApt29Lab02_2 = "${flag_apt29_lab02_2}"

function Set-AdministratorPassword([string]$plain) {
  $secure = ConvertTo-SecureString $plain -AsPlainText -Force
  Set-LocalUser -Name "Administrator" -Password $secure
}

function Set-DnsToSelf([string]$ip) {
  $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
  foreach ($adapter in $adapters) {
    try {
      Set-DnsClientServerAddress -InterfaceIndex $adapter.IfIndex -ServerAddresses $ip
    } catch {
      Write-Host "Unable to set DNS on adapter $($adapter.Name): $($_.Exception.Message)"
    }
  }
}

function Write-PostAdScript {
  $dir = "C:\\ProgramData\\Nyxera\\LAB02"
  New-Item -ItemType Directory -Path $dir -Force | Out-Null

  $script = @"
`$ErrorActionPreference = 'Stop'
`$domain = '$domain'
`$netbios = '$netbios'
`$itUser = '$itUser'
`$itUserPasswordPlain = '$itUserPasswordPlain'
`$groupName = 'FINANCE-WS-ADMINS'

Import-Module ActiveDirectory

for (`$i = 1; `$i -le 120; `$i++) {
  try {
    Get-ADDomain | Out-Null
    break
  } catch {
    Start-Sleep -Seconds 10
  }
}

if (-not (Get-ADDomain -ErrorAction SilentlyContinue)) {
  Write-Host 'AD not ready; exiting'
  exit 1
}

if (-not (Get-ADUser -Filter "SamAccountName -eq '`$itUser'" -ErrorAction SilentlyContinue)) {
  `$secure = ConvertTo-SecureString `$itUserPasswordPlain -AsPlainText -Force
  New-ADUser -Name 'IT Support' -SamAccountName `$itUser -UserPrincipalName "`$itUser@`$domain" -AccountPassword `$secure -Enabled `$true -PasswordNeverExpires `$true
}

if (-not (Get-ADGroup -Filter "Name -eq '`$groupName'" -ErrorAction SilentlyContinue)) {
  New-ADGroup -Name `$groupName -GroupScope Global -GroupCategory Security
}

Add-ADGroupMember -Identity `$groupName -Members `$itUser -ErrorAction SilentlyContinue

Write-Host 'Post-AD bootstrap complete'
"@

  $path = Join-Path $dir "post-ad.ps1"
  Set-Content -Path $path -Value $script -Encoding UTF8 -Force

  $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$path`""
  $trigger = New-ScheduledTaskTrigger -AtStartup
  Register-ScheduledTask -TaskName "Nyxera-LAB02-PostAD" -Action $action -Trigger $trigger -RunLevel Highest -User "SYSTEM" -Force | Out-Null
}

Write-Host "Configuring LAB02 DC/DNS: $hostname ($dcIp) for domain $domain"
Set-AdministratorPassword $adminPasswordPlain
Set-DnsToSelf $dcIp

if ($env:COMPUTERNAME -ne $hostname) {
  Rename-Computer -NewName $hostname -Force -Restart
}

Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools

# Seed lab-only artifacts and flags (rotating per deployment).
$caseDir = "C:\\ProgramData\\Nyxera\\LAB02\\Case"
$flagDir = "C:\\ProgramData\\Nyxera\\LAB02\\Flags"
New-Item -ItemType Directory -Path $caseDir -Force | Out-Null
New-Item -ItemType Directory -Path $flagDir -Force | Out-Null

@"
LAB02 Domain Controller (Lab-Only)

This environment is designed for APT-aligned training playbooks.
Do not reuse artifacts, credentials, or tooling outside an authorized lab.
"@ | Set-Content -Path (Join-Path $caseDir "README.txt") -Encoding UTF8 -Force

$flagApt29Lab02_2 | Set-Content -Path (Join-Path $flagDir "APT29-LAB02-2.flag") -Encoding UTF8 -Force

@"
LumenWorks (Dummy) - Directory Services Notes

- Domain: $domain
- NetBIOS: $netbios
- Lab objective: keep a clean evidence trail (timeline + artifacts) and validate rotating flags operator-side.
"@ | Set-Content -Path (Join-Path $caseDir "directory-services-notes.txt") -Encoding UTF8 -Force

if ($dsrm -ne "") {
  Write-PostAdScript
  Import-Module ADDSDeployment
  $pass = ConvertTo-SecureString $dsrm -AsPlainText -Force
  Install-ADDSForest -DomainName $domain -DomainNetbiosName $netbios -SafeModeAdministratorPassword $pass -Force
} else {
  Write-Host "ad_safe_mode_password empty; skipping DC promotion and user provisioning"
}
</powershell>
