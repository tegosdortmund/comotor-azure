#set execution policy
Set-ExecutionPolicy -ExecutionPolicy unrestricted -Force

#install prerequisites for azure powershell
[Environment]::NewLine
Write-Output '##### Start installing .NET and PowerShellv2 #####'
Install-WindowsFeature –name NET-Framework-Core 
Install-WindowsFeature –name NET-Framework-45-Core
Add-WindowsFeature Powershell-V2

#install azure powershell modules
[Environment]::NewLine
Write-Output '##### Start downloading Azure Powershell setup file #####'
Invoke-WebRequest https://tegosstorage.blob.core.windows.net/public/azure-powershell.0.9.9.msi -OutFile c:\comotorfiles\downloads\azure-powershell.0.9.9.msi -Verbose
[Environment]::NewLine
Write-Output '#####Using local file to install Azure PowerShell #####'
Start-Process C:\comotorfiles\downloads\azure-powershell.0.9.9.msi /quiet -Wait -PassThru

#use WebPI to install SQL Server 2013 CLR Types and Shared Management Objects
[Environment]::NewLine
Write-Output '##### Using WebPI to install SQL Server 2013 CLR Types and Shared Management Objects #####'
$tempPICmd = $env:programfiles + “\Microsoft\Web Platform Installer\WebpiCmd.exe”
$tempPIParameters = “/Install /AcceptEula /Products:SQLCLRTypes,SMO"
Start-Process -FilePath $tempPICmd -ArgumentList $tempPIParameters -Wait -Passthru