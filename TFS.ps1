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

#mount TFS image
[Environment]::NewLine
Write-Output '##### Using local image file to install TFS Team Explorer #####'
$tfsMountResult = Mount-DiskImage -ImagePath C:\comotorfiles\downloads\VS_TFS_2013_Team_Explorer.iso -StorageType ISO 
$tfsDriveLetter = (Get-DiskImage -ImagePath C:\comotorfiles\downloads\VS_TFS_2013_Team_Explorer.iso | Get-Volume).DriveLetter
$tfsSetupURL = $tfsDriveLetter + ':\vs_teamExplorer.exe'
$tfsInstallParameters = “/QUIET"
Start-Process -FilePath $tfsSetupURL -ArgumentList $tfsInstallParameters -Wait -Passthru
[Environment]::NewLine
Write-Output '##### TFS installation successful #####'

#install TFS Power Tools
[Environment]::NewLine
Write-Output '##### Using local file to install TFS Power Tools #####'
$msiParameters = '/i C:\comotorfiles\downloads\VS_TFS_2013_Power_Tools.msi /q AddLocal="ALL"'
Start-Process -FilePath msiexec -ArgumentList $msiParameters -Wait -Passthru 

#add TFS snapin
Add-PSSnapin Microsoft.TeamFoundation.PowerShell

#load assemblies
[Environment]::NewLine
Write-Output '##### Load assemblies #####'
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.VersionControl.Client")

#provide connection information
$tfsCollectionURL = 'https://tfs.tegos.eu/tfs/comotor'
$localFolder = 'C:\comotorfiles\tfsworkspace\RapidStart'
$tfsFolder = '$/comotor/MAIN/RapidStart'
$tfsDomain = 'CBCDTM'
if( $tfsUserName.ToUpper().Contains('\') ) {
    $tfsUserNameArray = $tfsUserName.Split('\')
    $tfsUserName = $tfsUserNameArray[1]
} elseif ( $tfsUserName.ToUpper().Contains('/') ) {
    $tfsUserNameArray = $tfsUserName.Split('/')
    $tfsUserName = $tfsUserNameArray[1]
}
$tfsCredentials = New-Object System.Net.NetworkCredential($tfsUserName, $tfsUserPassword, $tfsDomain)

#declare sever objects
[Environment]::NewLine
Write-Output '##### Connectiong to TFS #####'
$tfsProjectCollection = New-Object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection($tfsCollectionUrl, $tfsCredentials)
$tfsProjectCollection.Authenticate()
$tfsVersionControlType = [Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer]
$tfsVersionControlServer = $tfsProjectCollection.GetService($tfsVersionControlType)
[Environment]::NewLine
Write-Output '##### TFS connections established #####'

#create workspace if not existing
[Environment]::NewLine
Write-Output '##### Creating/mapping TFS workspace #####'
$workspaceName = "tfsworkspace" -f [System.Guid]::NewGuid().ToString()
if($tfsVersionControlServer.GetWorkspace($workspaceName, $tfsUserName) -ne $null) {
    $outputString = 'Deleting existing workspace "' + $tfsVersionControlServer.GetWorkspace($workspaceName, $tfsUserName).Name + '"'
    Write-Output $outputString  
    $tfsVersionControlServer.DeleteWorkspace($workspaceName, $tfsUserName)
}
$workspace = $tfsVersionControlServer.CreateWorkspace($workspaceName, $tfsVersionControlServer.AuthenticatedUser)
$workingfolder = New-Object Microsoft.TeamFoundation.VersionControl.Client.WorkingFolder($tfsFolder, $localFolder)
$workspace.CreateMapping($workingFolder)

#get objects
[Environment]::NewLine
Write-Output '##### Get objects from TFS #####'
$workspace.Get() 

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


