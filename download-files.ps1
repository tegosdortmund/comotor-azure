#parameters
Param(
  [Parameter(Mandatory=$True)]
  [string]$navVersion,

  [Parameter(Mandatory=$True)]
  [string]$country,

  [Parameter(Mandatory=$False)]
  [string]$SSMS = 'No',

  [Parameter(Mandatory=$False)]
  [string]$TFS = 'No',

    [Parameter(Mandatory=$True)]
  [string]$azureStorageKey
)

#set execution policy
Set-ExecutionPolicy -ExecutionPolicy unrestricted -Force

#write received parameters to log file
[Environment]::NewLine
Write-Output 'Received Parameters: '
$outputString = 'navVersion = ' + $navVersion 
Write-Output $outputString
$outputString = 'country = ' + $country
Write-Output $outputString
$outputString = 'SSMS = ' + $SSMS
[Environment]::NewLine

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
Get-AzureStorageBlobContent -blob LP_background.jpg -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
Get-AzureStorageBlobContent -blob Default.aspx -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
Write-Output 'Finished downloading'
[Environment]::NewLine