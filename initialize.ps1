#parameters
Param(
  [Parameter(Mandatory=$True)]
  [string]$azureStorageKey,

  [Parameter(Mandatory=$False)]
  [string]$customerName,

  [Parameter(Mandatory=$True)]
  [string]$vmAdminUsername,

  [Parameter(Mandatory=$True)]
  [string]$vmAdminPassword,

  [Parameter(Mandatory=$True)]
  [string]$navVersion,

  [Parameter(Mandatory=$True)]
  [string]$country,

  [Parameter(Mandatory=$False)]
  [string]$SSMS = 'No',

  [Parameter(Mandatory=$False)]
  [string]$TFS = 'No',

  [Parameter(Mandatory=$False)]
  [string]$clickOnce = 'No',

  [Parameter(Mandatory=$False)]
  [string]$navUser = $null,

  [Parameter(Mandatory=$False)]
  [string]$navUserPassword = $null,

  [Parameter(Mandatory=$True)]
  [string]$publicMachineName
)


#create log folder
New-Item -ItemType Directory -Path C:\comotorfiles -Force
New-Item -ItemType Directory -Path C:\comotorfiles\scripts -Force
New-Item -ItemType Directory -Path C:\comotorfiles\logs -Force
New-Item -ItemType Directory -Path C:\comotorfiles\downloads -Force
New-Item -ItemType Directory -Path C:\comotorfiles\landingpage -Force

#start logging
Start-Transcript -Path c:\comotorfiles\logs\initialize.log

#set execution policy
Set-ExecutionPolicy -ExecutionPolicy unrestricted -Force

#write received parameters to log file
[Environment]::NewLine
Write-Output 'Received Parameters:'
$outputString = 'azureStorageKey = ' + $azureStorageKey
Write-Output $outputString
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
$outputString = 'publicMachineName = ' + $publicMachineName
Write-Output $outputString
$outputString = 'navUser = ' + $navUser
Write-Output $outputString
$outputString = 'navUserPassword = ' + $navUserPassword
Write-Output $outputString
$outputString = 'clickOnce = ' + $clickOnce
Write-Output $outputString
$outputString = 'TFS = ' + $TFS
Write-Output $outputString

#define variables
$country = $country.Substring(0,2)
$machineName = [Environment]::MachineName.ToLowerInvariant()


#invoke scripts as separate processes
$failure = $false
try {
  
  #install prequesites
  $psSession1 = New-PSSession localhost
  Invoke-Command -Session $psSession1 -ScriptBlock { 
    #install prerequisites for azure powershell
    [Environment]::NewLine
    Write-Output 'Start installing .NET and PowerShellv2'
    Install-WindowsFeature –name NET-Framework-Core 
    Install-WindowsFeature –name NET-Framework-45-Core
    Add-WindowsFeature Powershell-V2

    #install azure powershell modules
    [Environment]::NewLine
    Write-Output 'Start downloading azure setup file'
    Invoke-WebRequest https://tegosstorage.blob.core.windows.net/public/azure-powershell.0.9.9.msi -OutFile c:\comotorfiles\downloads\azure-powershell.0.9.9.msi -Verbose
    [Environment]::NewLine
    [Environment]::NewLine
    Write-Output 'Using local file to install Azure PowerShell'
    Start-Process C:\comotorfiles\downloads\azure-powershell.0.9.9.msi /quiet -Wait

    #use WebPI to install SQL Server 2013 CLR Types and Shared Management Objects
    [Environment]::NewLine
    Write-Output “Using WebPI to install SQL Server 2013 CLR Types and Shared Management Objects"
    $tempPICmd = $env:programfiles + “\Microsoft\Web Platform Installer\WebpiCmd.exe”
    $tempPIParameters = “/Install /AcceptEula /Products:SQLCLRTypes,SMO"
    Start-Process -FilePath $tempPICmd -ArgumentList $tempPIParameters -Wait -Passthru
  } | Wait-Job


  #download files
  $psSession2 = New-PSSession localhost
  Invoke-Command -Session $psSession2 -ScriptBlock { 
    #create database filename
    $databaseAzurePath = 'Release_CTR_MAIN_' + $navVersion + '-' + $country + '.bak'
    
    #import modules
    Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1' | Out-Null
    
    #create storage context
    $ctx = New-AzureStorageContext -StorageAccountName notdelete -StorageAccountKey $azureStorageKey -Verbose
    
    #download install files
    [Environment]::NewLine
    Write-Output 'Start downloading installation files'
    Get-AzureStorageBlobContent -blob PS_SQL_2012_Extensions.msi -Container comotor -Destination C:\comotorfiles\downloads -Context $ctx -Force -Verbose
    Get-AzureStorageBlobContent -blob $databaseAzurePath -Container comotor -Destination C:\comotorfiles\downloads -Context $ctx -Force -Verbose
    if ($TFS -eq "Yes") {
      Get-AzureStorageBlobContent -blob VS_TFS_2013_Team_Explorer.iso -Container comotor -Destination C:\comotorfiles\downloads -Context $ctx -Force -Verbose
      Get-AzureStorageBlobContent -blob VS_TFS_2013_Power_Tools.msi -Container comotor -Destination C:\comotorfiles\downloads -Context $ctx -Force -Verbose
    }
    if ($SSMS -eq "Yes") {
      Get-AzureStorageBlobContent -blob SSMS_2014_Express.iso -Container comotor -Destination C:\comotorfiles\downloads -Context $ctx -Force -Verbose 
    }
    
    #download custom landing page
    [Environment]::NewLine
    Write-Output 'Start downloading custom landing page files'
    [Environment]::NewLine
    Get-AzureStorageBlobContent -blob LP_AppStore.png -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Verbose
    Get-AzureStorageBlobContent -blob LP_GooglePlay.png -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
    Get-AzureStorageBlobContent -blob LP_WindowsStore.png -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
    Get-AzureStorageBlobContent -blob LP_tegos_logo.jpg -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
    Get-AzureStorageBlobContent -blob LP_comotor_logo.jpg -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
    Get-AzureStorageBlobContent -blob Default.aspx -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
    Write-Output 'Finished downloading'
    [Environment]::NewLine
  } | Wait-Job
  
  # initialize comotor
  $psSession3 = New-PSSession localhost
  Invoke-Command -Session $psSession3 -ScriptBlock {
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
  } | Wait-Job
  

} catch {
    Set-Content -Path "C:\comotorfiles\logs\error.txt" -Value $_.Exception.Message
    Write-Verbose $_.Exception.Message
    $failure = $true
}


if ($failure) {
    throw "Error deploying the comotor packages"
}

#stop logging
Stop-Transcript