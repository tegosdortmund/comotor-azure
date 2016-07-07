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

New-Item -ItemType Directory -Path C:\comotorfiles -Force
New-Item -ItemType Directory -Path C:\comotorfiles\scripts -Force

$tfsURL = 'https://tfs.tegos.eu/tfs/Tools/PowerShell/_api/_versioncontrol/itemContent?path=%24%2FPowerShell%2FAzureDeployment%2F'

$secTFSPassword = ConvertTo-SecureString $tfsUserPassword -AsPlainText -Force
$credTFS = New-Object System.Management.Automation.PSCredential($tfsUserName, $secTFSPassword)

$source = $tfsURL + 'Start-Installation.ps1'
$destination = 'C:\comotorfiles\scripts\Start-Installation.ps1'
Invoke-WebRequest $source -OutFile $destination -Credential $credTFS -Verbose
        
. 'C:\comotorfiles\scripts\Start-Installation.ps1' `
        -azureStorageKey $azureStorageKey `
        -customerName $customerName `
        -vmAdminUsername $vmAdminUsername `
        -vmAdminPassword $vmAdminPassword `
        -navVersion $navVersion `
        -country $country `
        -SSMS $SSMS `
        -TFS $TFS `
        -docma $docma `
        -tfsUserName $tfsUserName `
        -tfsUserPassword $tfsUserPassword `
        -clickOnce $clickOnce `
        -navUser $navUser `
        -navUserPassword $navUserPassword `
        -publicMachineName $publicMachineName 
