#parameters
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
    [string]$docma = 'No',

    [Parameter(Mandatory=$True)]
    [string]$tfsUserName ,

    [Parameter(Mandatory=$True)]
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

#create folder structure
New-Item -ItemType Directory -Path C:\comotorfiles -Force
New-Item -ItemType Directory -Path C:\comotorfiles\scripts -Force
New-Item -ItemType Directory -Path C:\comotorfiles\logs -Force
New-Item -ItemType Directory -Path C:\comotorfiles\downloads -Force
New-Item -ItemType Directory -Path C:\comotorfiles\landingpage -Force
New-Item -ItemType Directory -Path C:\comotorfiles\tfsworkspace\RapidStart -Force

#start logging
Start-Transcript -Path c:\comotorfiles\logs\0_start.log

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
[Environment]::NewLine
$outputString = '##### Defining variables #####'
$country = $country.Substring(0,2)
$machineName = [Environment]::MachineName.ToLowerInvariant()
$failure = $false
#define TFS URL and files
[Environment]::NewLine   
$outputString = '##### Defining TFS URL and Files #####'
$tfsURL = 'https://tfs.tegos.eu/tfs/Tools/PowerShell/_api/_versioncontrol/itemContent?path=%24%2FPowerShell%2FAzureDeployment%2F'
$filesToDownloadArray = ('install-prequesites.ps1', 'download-files.ps1', 'initialize-comotor.ps1', 'TFS.ps1', 'configure-nav-users.ps1', 'initialize-vm.ps1')

#generate powershell commmand strings
$psParameterString =    ' -azureStorageKey ' + $azureStorageKey + `
                        ' -customerName \"' + $customerName + '\"' + `
                        ' -vmAdminUsername ' + $vmAdminUsername + ` 
                        ' -vmAdminPassword ' + $vmAdminPassword + `
                        ' -navVersion ' + $navVersion + ` 
                        ' -country ' + $country + `
                        ' -SSMS ' + $SSMS +  `
                        ' -TFS ' + $TFS + `
                        ' -docma ' + $docma + `
                        ' -tfsUserName ' + $tfsUserName + `
                        ' -tfsUserPassword \"' + $tfsUserPassword + '\"' + `
                        ' -clickOnce ' + $clickOnce + `
                        ' -navUser ' + $navUser + `
                        ' -navUserPassword ' + $navUserPassword + `
                        ' -publicMachineName ' + $publicMachineName 

try {
    #create TFS credentials
    [Environment]::NewLine
    $outputString = '##### Creating TFS credentials #####'
    $secTFSPassword = ConvertTo-SecureString $tfsUserPassword -AsPlainText -Force
    $credTFS = New-Object System.Management.Automation.PSCredential($tfsUserName, $secTFSPassword)
    
    Write-Output '##### Start downloading RapidStart-Packages from TFS #####'
    foreach ($file in $filesToDownloadArray) {
        $source = $tfsURL + $file
        $destination = 'C:\comotorfiles\scripts\' + $file
        Invoke-WebRequest $source -OutFile $destination -Credential $credTFS -Verbose
    }

    #invoke scripts as separate processes    
    for ($a=0; $a -lt $filesToDownloadArray.length; $a++) {
        [Environment]::NewLine
        $outputString = '##### Invoking ' + $filesToDownloadArray[$a] + ' #####'
        Write-Output $outputString

        if( ($filesToDownloadArray[$a] -ne 'TFS.ps1') -or ($TFS -eq 'Yes') ) {
            $b = $a + 1
            $invokeCommand = 'C:\comotorfiles\scripts\' + $filesToDownloadArray[$a] + $psParameterString
            $standardOutputFile = 'C:\comotorfiles\logs\' + $b + '_' + $filesToDownloadArray[$a] + '.log'
            $standardErrorFile = 'C:\comotorfiles\logs\' + $b + '_' + $filesToDownloadArray[$a] + '-error.txt'
            
            Start-Process powershell.exe $invokeCommand -Wait -PassThru -RedirectStandardOutput $standardOutputFile -RedirectStandardError $standardErrorFile 
        }        
    }
    
    $source = $tfsURL + 'Install-comotorAutomation.ps'
    $destination = 'C:\comotorfiles\scripts\Install-comotorAutomation.ps'
    Invoke-WebRequest $source -OutFile $destination -Credential $credTFS -Verbose
    $invokeCommand = "C:\comotorfiles\scripts\Install-comotorAutomation.ps1 -AzureStorageKey $azureStorageKey"
    $standardOutputFile = 'C:\comotorfiles\logs\Install-comotorAutomation.log'
    $standardErrorFile = 'C:\comotorfiles\logs\Install-comotorAutomation-error.txt'
    Start-Process powershell.exe $invokeCommand -Wait -PassThru -RedirectStandardOutput $standardOutputFile -RedirectStandardError $standardErrorFile
    
} catch {
    Set-Content -Path "C:\comotorfiles\logs\0_error.txt" -Value $_.Exception.Message
    Write-Verbose $_.Exception.Message
    $failure = $true
}

#redirect error if failure
if ($failure) {
    throw "Error deploying the comotor packages"
}

#stop logging
Stop-Transcript
