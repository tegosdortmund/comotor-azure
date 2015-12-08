#parameters
Param(
    [Parameter(Mandatory=$True)]
    [string]$navVersion,

    [Parameter(Mandatory=$False)]
    [string]$country = 'W1',
  
    [Parameter(Mandatory=$False)]
    [string]$customerName = 'commetal',

    [Parameter(Mandatory=$True)]
    [string]$tfsUserName,

    [Parameter(Mandatory=$True)]
    [string]$tfsUserPassword,

    [Parameter(Mandatory=$True)]
    [string]$vmAdminUsername,

    [Parameter(Mandatory=$True)]
    [string]$vmAdminPassword
)

#set execution policy
Set-ExecutionPolicy -ExecutionPolicy unrestricted -Force

#enable PowerShell remoting
[Environment]::NewLine
Write-Output '##### Enable PowerShell Remoting #####'
Enable-PSRemoting -Force

#calculate internal NAV version
switch ($navVersion) { 
    2016 { $navInternVersion = '90' } 
    2015 { $navInternVersion = '80' } 
    default { $navInternVersion = '90' }
}

#calculate language
switch ($country) { 
    W1 { $language = 'en-US' } 
    DE { $language = 'de-DE' } 
    NL { $language = 'nl-BE' } 
    default { $language = 'en-US' }
}

#import modules
[Environment]::NewLine
Write-Output '##### Importing Modules #####'
$navAdminToolPath = 'C:\Program Files\Microsoft Dynamics NAV\' + $navInternVersion + '\Service\NavAdminTool.ps1'
Import-module $navAdminToolPath | Out-Null

#create TFS credentials
[Environment]::NewLine
$outputString = '##### Creating TFS credentials #####'
$secTFSPassword = ConvertTo-SecureString $tfsUserPassword -AsPlainText -Force
Start-Sleep -Seconds 2
$credTFS = New-Object System.Management.Automation.PSCredential($tfsUserName, $secTFSPassword)
Write-Output $credTFS

#define TFS URL and files
[Environment]::NewLine
$outputString = '##### Defining TFS URL and Files #####'
$tfsURL = 'https://tfs.tegos.eu/tfs/comotor/comotor/_api/_versioncontrol/itemContent?path=%24%2Fcomotor%2FMAIN%2FRapidStart%2F'
$filesToDownloadArray = ('PackageW1-BASE.xml', 'PackageW1-COMOTOR.xml', 'PackageW1-FINANCE.xml', 'PackageW1-STAINLESS S. - EX.xml', 'PackageW1-STAINLESS S. DEMO.xml', 'PackageW1-STAINLESS STEEL.xml', 'W1 Finance Demo.xml', 'W1 Stainless Steel Demo - Extended Market Prices.xml', 'W1 Stainless Steel Demo.xml')

Write-Output '##### Start downloading RapidStart-Packages from TFS #####'
foreach ($file in $filesToDownloadArray) {
    $source = $tfsURL + $file
    $destination = 'C:\comotorfiles\tfsworkspace\RapidStart\' + $file
    Invoke-WebRequest $source -OutFile $destination -Credential $credTFS -Verbose
}

#create new company
[Environment]::NewLine
$outputString = '##### Creating new company ' + $customerName + ' #####'
Write-Output $outputString
New-NAVCompany -ServerInstance 'NAV' -CompanyName $customerName -Force

#create vm admin user
[Environment]::NewLine
$outputString = '##### Creating admin credentials #####'
$compVmAdminUsername = $env:COMPUTERNAME + '\' + $vmAdminUsername
$secVmAdminPassword = ConvertTo-SecureString $vmAdminPassword -AsPlainText -Force
$credVmAdmin = New-Object System.Management.Automation.PSCredential($compVmAdminUsername, $secVmAdminPassword)

#auto create company
[Environment]::NewLine
$outputString = '##### Invoke Codeunit AutoCreateCompany as VM admin #####'
Invoke-Command -ComputerName 'localhost' -Credential $credVmAdmin -ScriptBlock {    
    Param($navInternVersion, $language, $customerName)
    $navAdminToolPath = 'C:\Program Files\Microsoft Dynamics NAV\' + $navInternVersion + '\Service\NavAdminTool.ps1'
    Import-module $navAdminToolPath | Out-Null
    Invoke-NAVCodeunit -ServerInstance NAV -CompanyName $customerName -Codeunit 5222051 -MethodName "LoadPackageCollFile" -Argument 'C:\comotorfiles\tfsworkspace\RapidStart\W1 Stainless Steel Demo.xml' -Language $language
} -Args $navInternVersion,$language,$customerName


