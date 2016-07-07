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
