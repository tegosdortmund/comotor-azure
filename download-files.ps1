#parameters
Param(
    [Parameter(Mandatory=$False)]
    [string]$navVersion = '2016',

    [Parameter(Mandatory=$False)]
    [string]$country = 'W1',

    [Parameter(Mandatory=$False)]
    [string]$SSMS = 'No',

    [Parameter(Mandatory=$False)]
    [string]$TFS = 'No',

    [Parameter(Mandatory=$True)]
    [string]$azureStorageKey
)

#set execution policy
Set-ExecutionPolicy -ExecutionPolicy unrestricted -Force

#import modules
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1' | Out-Null

#create database filename
$databaseAzurePath = 'Release_CTR_MAIN_' + $navVersion + '-' + $country + '.bak'

#create storage context
$ctx = New-AzureStorageContext -StorageAccountName notdelete -StorageAccountKey $azureStorageKey -Verbose

#download files
[Environment]::NewLine
Write-Output '##### Start downloading setup files #####'
Get-AzureStorageBlobContent -blob PS_SQL_2012_Extensions.msi -Container comotor -Destination C:\comotorfiles\downloads -Context $ctx -Force -Verbose
Get-AzureStorageBlobContent -blob $databaseAzurePath -Container comotor -Destination C:\comotorfiles\downloads -Context $ctx -Force -Verbose
if ($SSMS -eq "Yes") {
    Get-AzureStorageBlobContent -blob SSMS_2014_Express.iso -Container comotor -Destination C:\comotorfiles\downloads -Context $ctx -Force -Verbose 
}

#download custom landing page
[Environment]::NewLine
Write-Output '##### Start downloading custom landing page files #####'
[Environment]::NewLine
Get-AzureStorageBlobContent -blob LP_AppStore.png -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Verbose
Get-AzureStorageBlobContent -blob LP_GooglePlay.png -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
Get-AzureStorageBlobContent -blob LP_WindowsStore.png -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
Get-AzureStorageBlobContent -blob LP_tegos_logo.jpg -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
Get-AzureStorageBlobContent -blob LP_comotor_logo.jpg -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
Get-AzureStorageBlobContent -blob LP_background.jpg -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
Get-AzureStorageBlobContent -blob Default.aspx -Container comotor -Destination C:\comotorfiles\landingpage -Context $ctx -Force -Verbose
[Environment]::NewLine
Write-Output '##### Finished downloading #####'
