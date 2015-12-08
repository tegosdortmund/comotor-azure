﻿#parameters
Param(
    [Parameter(Mandatory=$True)]
    [string]$azureStorageKey,
        
    [Parameter(Mandatory=$True)]
    [string]$customerName,

    [Parameter(Mandatory=$True)]
    [string]$vmAdminUsername,
    
    [Parameter(Mandatory=$True)]
    [string]$vmAdminPassword,
    
    [Parameter(Mandatory=$False)]
    [string]$navVersion = '2016',
    
    [Parameter(Mandatory=$False)]
    [string]$country = 'W1-International',
    
    [Parameter(Mandatory=$False)]
    [string]$SSMS = 'No',

    [Parameter(Mandatory=$False)]
    [string]$TFS = 'No',

    [Parameter(Mandatory=$False)]
    [string]$tfsUserName ,

    [Parameter(Mandatory=$False)]
    [string]$tfsUserPassword,

    [Parameter(Mandatory=$False)]
    [string]$clickOnce = 'No',

    [Parameter(Mandatory=$False)]
    [string]$navUser = $null,

    [Parameter(Mandatory=$False)]
    [string]$navUserPassword = $null,

    [Parameter(Mandatory=$True)]
    [string]$publicMachineName
)

#define variables
$githubURL = 'https://raw.githubusercontent.com/tegosdortmund/comotor-azure/master/'
$filesToDownloadArray = ('install-prequesites.ps1', 'download-files.ps1', 'initialize-comotor.ps1', 'configure-nav-users.ps1', 'TFS.ps1')

#create log folder
New-Item -ItemType Directory -Path C:\comotorfiles -Force
New-Item -ItemType Directory -Path C:\comotorfiles\scripts -Force
New-Item -ItemType Directory -Path C:\comotorfiles\logs -Force
New-Item -ItemType Directory -Path C:\comotorfiles\downloads -Force
New-Item -ItemType Directory -Path C:\comotorfiles\landingpage -Force

#start logging
Start-Transcript -Path c:\comotorfiles\logs\1_start.log

#set execution policy
Set-ExecutionPolicy -ExecutionPolicy unrestricted -Force

#write received parameters to log file
[Environment]::NewLine
Write-Output '##### Received Parameters: #####'
$outputString = 'navVersion = ' + $navVersion 
Write-Output $outputString
$outputString = 'country = ' + $country
Write-Output $outputString
$outputString = 'SSMS = ' + $SSMS
Write-Output $outputString
$outputString = 'vmAdminUserName = ' + $vmAdminUsername
Write-Output $outputString
$outputString = 'publicMachineName = ' + $publicMachineName
Write-Output $outputString
$outputString = 'navUser = ' + $navUser
Write-Output $outputString
$outputString = 'clickOnce = ' + $clickOnce
Write-Output $outputString
$outputString = 'TFS = ' + $TFS
Write-Output $outputString
$outputString = 'tfsUserName = ' + $tfsUserName
Write-Output $outputString

#define variables
$country = $country.Substring(0,2)
$machineName = [Environment]::MachineName.ToLowerInvariant()

#download script files
[Environment]::NewLine
Write-Output '##### Start downloading script files from github #####'
foreach ($file in $filesToDownloadArray) {
    $source = $githubURL + $file
    $destination = 'c:\comotorfiles\scripts\' + $file
    Invoke-WebRequest $source -OutFile $destination -Verbose
}

<#
#create TFS credentials
[Environment]::NewLine
$outputString = '##### Creating TFS credentials #####'
$secTFSPassword = ConvertTo-SecureString $tfsUserPassword -AsPlainText -Force
$credTFS = New-Object System.Management.Automation.PSCredential($tfsUserName, $secTFSPassword)

#define TFS URL and files
[Environment]::NewLine
$outputString = '##### Defining TFS URL and Files #####'
$tfsURL = 'https://tfs.tegos.eu/tfs/comotor/comotor/_api/_versioncontrol/itemContent?path=%24%2Fcomotor%2FMAIN%2FRapidStart%2F'
$filesToDownloadArray = ('PackageW1-BASE.xml', 'PackageW1-COMOTOR.xml', 'PackageW1-FINANCE.xml', 'PackageW1-STAINLESS S. - EX.xml', 'PackageW1-STAINLESS S. DEMO.xml', 'PackageW1-STAINLESS STEEL.xml', 'W1 Finance Demo.xml', 'W1 Stainless Steel Demo - Extended Market Prices.xml', 'W1 Stainless Steel Demo.xml')

Write-Output '##### Start downloading RapidStart-Packages from TFS #####'
foreach ($file in $filesToDownloadArray) {
    $source = $tfsURL + $file
    $destination = 'C:\comotorfiles\scripts\' + $file
    Invoke-WebRequest $source -OutFile $destination -Credential $credTFS -Verbose
}
#>


#generate powershell commmand strings
$psCommandInstallPrequesites = 'c:\comotorfiles\scripts\install-prequesites.ps1'
$psCommandDownloadFiles = 'c:\comotorfiles\scripts\download-files.ps1' + ' -navVersion ' + $navVersion + ' -country ' + $country + ' -SSMS ' + $SSMS + ' -TFS ' + $TFS + ' -azureStorageKey ' + $azureStorageKey
$psCommandInitializeComotor = 'c:\comotorfiles\scripts\initialize-comotor.ps1 ' + ' -navVersion ' + $navVersion + ' -country ' + $country + ' -SSMS ' + $SSMS + ' -vmAdminUsername ' + $vmAdminUsername + ' -vmAdminPassword ' + $vmAdminPassword
$psCommandTFS = 'c:\comotorfiles\scripts\TFS.ps1' + ' -navVersion ' + $navVersion + ' -customerName \"' + $customerName + '\" -country ' + $country + ' -tfsUserName ' + $tfsUserName + ' -tfsUserPassword ' + $tfsUserPassword + ' -vmAdminUsername ' + $vmAdminUsername + ' -vmAdminPassword ' + $vmAdminPassword
$psCommandConfigureUser = 'c:\comotorfiles\scripts\configure-nav-users.ps1 ' + ' -navUser ' + $navUser + ' -navUserPassword ' + $navUserPassword + ' -navVersion ' + $navVersion + ' -country ' + $country + ' -customerName \"' + $customerName + '\" -TFS ' + $TFS 

#invoke scripts as separate processes
$failure = $false
try {
    Start-Process powershell.exe $psCommandInstallPrequesites -Wait -PassThru -RedirectStandardOutput 'C:\comotorfiles\logs\2_install-prequesites.log' -RedirectStandardError 'C:\comotorfiles\logs\2_install-prequesites-error.txt' 
    Start-Process powershell.exe $psCommandDownloadFiles -Wait -RedirectStandardOutput 'C:\comotorfiles\logs\3_downloadfiles.log' -RedirectStandardError 'C:\comotorfiles\logs\3_downloadfiles-error.txt'
    Start-Process powershell.exe $psCommandInitializeComotor -Wait -RedirectStandardOutput 'C:\comotorfiles\logs\4_initialize-comotor.log' -RedirectStandardError 'C:\comotorfiles\logs\4_initialize-comotor-error.txt'
    
    #create company from TFS Rapid Start files
    if($TFS -eq 'Yes') {
      Start-Process powershell.exe $psCommandTFS -Wait -RedirectStandardOutput 'C:\comotorfiles\logs\5_TFS.log' -RedirectStandardError 'C:\comotorfiles\logs\5_TFS-error.txt'
    }
    Start-Process powershell.exe $psCommandConfigureUser -Wait -RedirectStandardOutput 'C:\comotorfiles\logs\6_configure-nav-users.log' -RedirectStandardError 'C:\comotorfiles\logs\6_configure-nav-users-error.txt'
    
    #initialize vm
    ('$HardcodeLanguage = "'+$country.Substring(0,2)+'"')           | Add-Content "c:\DEMO\Initialize\HardcodeInput.ps1"
    ('$HardcodeNavAdminUser = "'+$vmAdminUsername+'"')              | Add-Content "c:\DEMO\Initialize\HardcodeInput.ps1"
    ('$HardcodeNavAdminPassword = "'+$vmAdminPassword+'"')          | Add-Content "c:\DEMO\Initialize\HardcodeInput.ps1"
    ('$HardcodeRestoreAndUseBakFile = "Default"')                   | Add-Content "c:\DEMO\Initialize\HardcodeInput.ps1"
    ('$HardcodeCloudServiceName = "'+$publicMachineName+'"')        | Add-Content "c:\DEMO\Initialize\HardcodeInput.ps1"
    ('$HardcodePublicMachineName = "'+$publicMachineName+'"')       | Add-Content "c:\DEMO\Initialize\HardcodeInput.ps1"
    ('$HardcodecertificatePfxFile = "default"')                     | Add-Content "c:\DEMO\Initialize\HardcodeInput.ps1"
    Start-Process powershell.exe 'C:\DEMO\Initialize\install.ps1' -RedirectStandardOutput 'C:\comotorfiles\logs\7_initialize-vm.log' -RedirectStandardError 'C:\comotorfiles\logs\7_initialize-vm-error.txt' -Wait
    Set-Content -Path "c:\inetpub\wwwroot\http\$MachineName.rdp" -Value ('full address:s:' + $publicMachineName + ':3389')
   
    #change landing page
    $titleReplaceString = '<title>' + $customerName+ '</title>'
    $headingReplaceString = 'Welcome to ' + $customerName
    $aspxContent = (Get-Content -Path 'C:\comotorfiles\landingpage\Default.aspx' -ReadCount 0) -join "`n"
    $aspxContent -replace '<title>comotor Demonstration Environment</title>', $titleReplaceString -replace 'Welcome to the comotor Demonstration Environment', $headingReplaceString | Set-Content -Path 'C:\comotorfiles\landingpage\Default.aspx'
        
    #copy custom landing page files
    [Environment]::NewLine
    Write-Output '##### Copying landing page files to IIS http directory #####'
    Copy-Item 'C:\comotorfiles\landingpage\*' 'C:\inetpub\wwwroot\http' -Force -Verbose
 
    #enable click once 
    if ($clickOnce -eq "Yes") {
        [Environment]::NewLine
        Write-Output 'initializing clickOnce'
        Start-Process powershell.exe 'c:\DEMO\Clickonce\install.ps1' -RedirectStandardOutput 'C:\comotorfiles\logs\8_clickonce-install.log' -RedirectStandardError 'C:\comotorfiles\logs\8_clickonce-install-error.txt' -Wait
    }

} catch {
    Set-Content -Path "C:\comotorfiles\logs\0_error.txt" -Value $_.Exception.Message
    Write-Verbose $_.Exception.Message
    $failure = $true
}


if ($failure) {
    throw "Error deploying the comotor packages"
}

#stop logging
Stop-Transcript