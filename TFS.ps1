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
  [string]$tfsUserPassword
)

#write received parameters to log file
[Environment]::NewLine
Write-Output 'Received Parameters:'
$outputString = 'Current user doing operations = ' + [Environment]::UserName
Write-Output $outputString
$outputString = 'navVersion = ' + $navVersion 
Write-Output $outputString
$outputString = 'country = ' + $country
Write-Output $outputString
$outputString = 'customerName = ' + $customerName
Write-Output $outputString
$outputString = 'tfsUserName = ' + $tfsUserName
Write-Output $outputString
$outputString = 'tfsUserPassword = ' + $tfsUserPassword
Write-Output $outputString

#set execution policy
Set-ExecutionPolicy -ExecutionPolicy unrestricted -Force

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
$navAdminToolPath = 'C:\Program Files\Microsoft Dynamics NAV\' + $navInternVersion + '\Service\NavAdminTool.ps1'
Import-module $navAdminToolPath | Out-Null

#mount TFS image
Write-Output 'Using local image file to install TFS Team Explorer'
Write-Output 'Mounting TFS image file'
$tfsMountResult = Mount-DiskImage -ImagePath C:\comotorfiles\downloads\VS_TFS_2013_Team_Explorer.iso -StorageType ISO 
$tfsDriveLetter = (Get-DiskImage -ImagePath C:\comotorfiles\downloads\VS_TFS_2013_Team_Explorer.iso | Get-Volume).DriveLetter
$tfsSetupURL = $tfsDriveLetter + ':\vs_teamExplorer.exe'
Write-Output 'Mounting successful'

#start setup routine TFS
Write-Output 'Starting TFS installation'
$tfsInstallParameters = “/QUIET"
Start-Process -FilePath $tfsSetupURL -ArgumentList $tfsInstallParameters -Wait -Passthru
Write-Output 'TFS installation successful'
[Environment]::NewLine

#install TFS Power Tools
Write-Output 'Using local file to install TFS Power Tools'
Write-Output 'Starting TFS installation'
$msiParameters = '/i C:\comotorfiles\downloads\VS_TFS_2013_Power_Tools.msi /q AddLocal="ALL"'
Start-Process -FilePath msiexec -ArgumentList $msiParameters -Wait -Passthru 
Write-Output 'Mounting successful'
[Environment]::NewLine


#add TFS snapin
Add-PSSnapin Microsoft.TeamFoundation.PowerShell

#load assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.VersionControl.Client")

#provide connection information
$tfsCollectionURL = 'https://tfs.tegos.eu/tfs/comotor'
$localFolder = 'C:\comotorfiles\tfsworkspace\RapidStart'
$tfsFolder = '$/comotor/MAIN/RapidStart'
$tfsDomain = 'CBCDTM'
if( $tfsUserName.Contains('CBCDTM') ) {
  $tfsUserNameArray = $tfsUserName.Split('\')
  $tfsUserName = $tfsUserNameArray[1]
}
$credentials = New-Object System.Net.NetworkCredential($tfsUserName, $tfsUserPassword, $tfsDomain)

#declare sever objects
$tfsProjectCollection = New-Object Microsoft.TeamFoundation.Client.TfsTeamProjectCollection($tfsCollectionUrl, $credentials)
$tfsProjectCollection.Authenticate()
$tfsVersionControlType = [Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer]
$tfsVersionControlServer = $tfsProjectCollection.GetService($tfsVersionControlType)

#create workspace if not existing
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
$workspace.Get() 

#create new company
$userName = [Environment]::UserName
New-NAVCompany -ServerInstance 'NAV' -CompanyName $customerName -Force

New-NAVServerUser -WindowsAccount $userName -ServerInstance NAV -Verbose 
New-NAVServerUserPermissionSet -ServerInstance NAV -UserName $userName.ToUpper() -CompanyName $customerName -PermissionSetId SUPER -Verbose

#auto create company
Invoke-NAVCodeunit -ServerInstance 'NAV' -CompanyName $customerName -Codeunit 5222051 -MethodName "LoadPackageCollFile" -Argument 'C:\comotorfiles\tfsworkspace\RapidStart\W1 Stainless Steel Demo.xml' -Language $language 

