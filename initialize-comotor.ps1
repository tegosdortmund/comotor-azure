#parameters
Param(
  [Parameter(Mandatory=$True)]
  [string]$navVersion,

  [Parameter(Mandatory=$True)]
  [string]$country,

  [Parameter(Mandatory=$False)]
  [string]$SSMS = 'No',

  [Parameter(Mandatory=$True)]
  [string]$vmAdminUsername,

  [Parameter(Mandatory=$True)]
  [string]$vmAdminPassword
)

#start logging
Set-ExecutionPolicy -ExecutionPolicy unrestricted -Force

#write received parameters to log file
Write-Output 'Received Parameters: '
$outputString = 'navVersion = ' + $navVersion 
Write-Output $outputString
$outputString = 'country = ' + $country
Write-Output $outputString
$outputString = 'SSMS = ' + $SSMS
Write-Output $outputString
$outputString = 'vmAdminUserName = ' + $vmAdminUsername
Write-Output $outputString
$outputString = 'vmAdminPassword = ' + $vmAdminPassword
Write-Output $outputString

#variables configuration
$sqlServerName = $env:computername +'\NAVDEMO'
$sqlUserName = $env:computername +'\' + $vmAdminUsername
$country = $country.Substring(0,2)
$bakFilePath = 'C:\comotorfiles\downloads\Release_CTR_MAIN_' + $navVersion + '-' + $country+'.bak'
$databaseName = 'Release_CTR_MAIN_' + $navVersion + '-' + $country
$machineName = [Environment]::MachineName.ToLowerInvariant()

#calculate internal NAV version
switch ($navVersion) { 
  2016 { $navInternVersion = '90' } 
  2015 { $navInternVersion = '80' } 
  default { $navInternVersion = '90' }
}

#install SQL Server 2012 PowerShell Extensions
[Environment]::NewLine
Write-Output 'Using local file to install SQL Server PowerShell Extensions'
Start-Process C:\comotorfiles\downloads\PS_SQL_2012_Extensions.msi /quiet -Wait -PassThru

#import modules
Import-Module SQLPS -DisableNameChecking | Out-Null
$navAdminToolPath = 'C:\Program Files\Microsoft Dynamics NAV\' + $navInternVersion + '\Service\NavAdminTool.ps1'
Import-module $navAdminToolPath | Out-Null

#install SSMS if selected
if ($SSMS -eq "Yes") {
  [Environment]::NewLine
  Write-Output 'Installing SQL Server Management Studio from iso file'
  #mount SSMS iso image
  $sqlMountResult = Mount-DiskImage -ImagePath C:\comotorfiles\downloads\SSMS_2014_Express.iso -StorageType ISO 
  $sqlDriveLetter = (Get-DiskImage -ImagePath C:\comotorfiles\downloads\SSMS_2014_Express.iso | Get-Volume).DriveLetter
  $sqlSetupURL = $sqlDriveLetter+":\setup.exe"
  #start setup routine SSMS
  & $sqlSetupURL -verb=sync /QUIET="True" `
              /ACTION=Install `
              /FEATURES=SSMS `
              /IACCEPTSQLSERVERLICENSETERMS `
              /MEDIALAYOUT=Core
}

# restore database 
[Environment]::NewLine
Write-Output 'Restoring database from local .bak file'
$smoServer = New-Object Microsoft.SqlServer.Management.Smo.Server($sqlServerName) 
$dataFile = $smoServer.Settings.DefaultFile + $dbname + '_Data.mdf'
$logFile = $smoServer.Settings.DefaultLog + $dbname + '_Log.ldf'

$smoRestore = New-Object Microsoft.SqlServer.Management.Smo.Restore
$smoRestore.Devices.AddDevice($bakFilePath, [Microsoft.SqlServer.Management.Smo.DeviceType]::File) 
$smoHeaderList = $smoRestore.ReadFileList($smoServer)
$rfl = @()
foreach ($headerEntry in $smoHeaderList) {
    $rsfile = new-object('Microsoft.SqlServer.Management.Smo.RelocateFile')
    $rsfile.LogicalFileName = $headerEntry.LogicalName
    if ($headerEntry.Type -eq 'D') {
        $rsfile.PhysicalFileName = $dataFile
    }
    else {
        $rsfile.PhysicalFileName = $logFile
    }
    $rfl += $rsfile
}

Restore-SqlDatabase -Verbose `
                    -ServerInstance $sqlServerName `
                    -Database $databaseName `
                    -BackupFile $bakFilePath `
                    -RelocateFile $rfl `
                    -ReplaceDatabase 

# configure NAV service 
Set-NAVServerInstance -ServerInstance NAV -Stop -Verbose
while ((Get-NAVServerInstance -ServerInstance NAV).State -ne "Stopped") { Start-Sleep -Seconds 5 }
Set-NAVServerConfiguration NAV -KeyName DatabaseName -KeyValue $databaseName -Verbose

# create login for network service 
[Environment]::NewLine
Write-Output 'Creating database login for VM admin user and Network Service'
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null 
$sqlServer = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $sqlServerName -Verbose
$database = $sqlServer.Databases[$databaseName]
$dbUser = New-Object ('Microsoft.SqlServer.Management.Smo.User') $database, 'NT AUTHORITY\NETWORK SERVICE' -Verbose
$dbUser.Login = 'NT AUTHORITY\NETWORK SERVICE' 
$dbUser.Create() 
$dbrole = $database.Roles['db_owner']
$dbrole.AddMember('NT AUTHORITY\NETWORK SERVICE') 
$dbrole.Alter() 

#wait until NAV service is running
Set-NAVServerInstance -ServerInstance NAV -Start -Verbose
while ((Get-NAVServerInstance -ServerInstance NAV).State -ne "Running") { Start-Sleep -Seconds 5 }

#create NAV login for VM admin
$secureString = convertto-securestring $vmAdminPassword -asplaintext -Force
New-NAVServerUser -WindowsAccount $sqlUserName -ServerInstance NAV -Verbose 
New-NAVServerUserPermissionSet -WindowsAccount $sqlUserName -ServerInstance NAV -PermissionSetId SUPER -Verbose 

#restart NAV service 
Set-NAVServerInstance -ServerInstance NAV -Restart -Verbose
while ((Get-NAVServerInstance -ServerInstance NAV).State -ne "Running") { Start-Sleep -Seconds 5 }