#parameters
Param(
    [Parameter(Mandatory=$True)]
    [string[]]$navUser,

    [Parameter(Mandatory=$True)]
    [string[]]$navUserPassword,

    [Parameter(Mandatory=$True)]
    [string]$navVersion,

    [Parameter(Mandatory=$True)]
    [string]$country,

    [Parameter(Mandatory=$True)]
    [string]$TFS,

    [Parameter(Mandatory=$False)]
    [string]$customerName
)

#set execution policy
Set-ExecutionPolicy -ExecutionPolicy unrestricted -Force

#variables configuration
$sqlServerName = $env:computername +'\NAVDEMO'
$databaseName = 'Release_CTR_MAIN_' + $navVersion + '-' + $country

#calculate internal NAV version
switch ($navVersion) { 
    2016 { $navInternVersion = '90' } 
    2015 { $navInternVersion = '80' } 
    default { $navInternVersion = '90' }
}

#set customername
if($TFS -eq 'No') {
    $customerName = 'com|metal Metallhandel GmbH'
}

#import modules
[Environment]::NewLine
Write-Output '##### Importing Modules #####'
$navAdminToolPath = 'C:\Program Files\Microsoft Dynamics NAV\' + $navInternVersion + '\Service\NavAdminTool.ps1' 
Import-module $navAdminToolPath | Out-Null

#create nav users if specified
if(![string]::IsNullOrEmpty($navUser)) {
    if($navUser.Length -eq $navUserPassword.Length) {

        [Environment]::NewLine
        Write-Output '##### Creating the following NAV users: #####'
        for ($a=0; $a -lt $navUser.length; $a++) {
            $outputString = '##### ' + $a.ToString() + '. User = ' + $navUser[$a] + ' #####'
	        Write-Output $outputString
        }

        for ($a=0; $a -lt $navUser.length; $a++) {
            $secureString = convertto-securestring $navUserPassword[$a] -asplaintext -Force
            $fullname = $navUser[$a]
            New-NAVServerUser -ServerInstance NAV -UserName $navUser[$a].ToUpper() -FullName $fullname -Password $secureString -Verbose
            New-NAVServerUserPermissionSet -ServerInstance NAV -UserName $navUser[$a].ToUpper() -CompanyName $customerName -PermissionSetId SUPER -Verbose

            #open database connection
            [Environment]::NewLine
            Write-Output '##### Adding user to users setup table #####'
            $conn = New-Object System.Data.SqlClient.SqlConnection("Server=localhost\NAVDEMO;Database=$databaseName;Integrated Security=SSPI")
            $conn.Open()
            $cmd = $conn.CreateCommand()        
            $sqlCommand = "INSERT INTO [" + $databaseName + "].[dbo].[" + $customerName + "$" + "User Setup](
            [User ID]
            ,[Allow Posting From]
            ,[Allow Posting To]
            ,[Register Time]
            ,[Salespers__Purch_ Code]
            ,[Approver ID]
            ,[Sales Amount Approval Limit]
            ,[Purchase Amount Approval Limit]
            ,[Unlimited Sales Approval]
            ,[Unlimited Purchase Approval]
            ,[Substitute]
            ,[E-Mail]
            ,[Request Amount Approval Limit]
            ,[Unlimited Request Approval]
            ,[Approval Administrator]
            ,[Time Sheet Admin_]
            ,[Allow FA Posting From]
            ,[Allow FA Posting To]
            ,[Sales Resp_ Ctr_ Filter]
            ,[Purchase Resp_ Ctr_ Filter]
            ,[Service Resp_ Ctr_ Filter]
            ,[Max_ Auto_ Phys_ Invt_ Qty_]
            ,[Max_ Auto_ Phys_ Invt_ UOM]
            ,[Max_ Auto_ Phys_ Invt_ Value]
            ,[Dispatcher]
            ,[Default Weighbridge Code])
            VALUES (UPPER('" + $navUser[$a] + "'), '1753-01-01 00:00:00.000', '1753-01-01 00:00:00.000', '0', '0', '0', '0', '0', '0', '0', '0', 'user@user.net', '0', '0', '0', '0', '1753-01-01 00:00:00.000', '1753-01-01 00:00:00.000', '0', '0', '0', '0.00000000000000000000', 'MT', '0.00000000000000000000', '0', 'WEIGHBR. 1')"

            $cmd.CommandText = $sqlCommand
            $cmd.ExecuteNonQuery() 
            $conn.Close()    
        }
    }
    else {
        [Environment]::NewLine
        Write-Output 'Warning: Different number of users and passwords'
        Write-Output 'Warning: Users will be initialized with standard password "Username123"'

        [Environment]::NewLine
        Write-Output '##### Creating the following NAV users: #####'
        for ($a=0; $a -lt $navUser.length; $a++) {
            $outputString = '##### ' + $a.ToString() + '. User = ' + $navUser[$a] + ' #####'
	        Write-Output $outputString
        }

        for ($a=0; $a -lt $navUser.length; $a++) {
            $unsecureString = $navUser[$a] + '123'
            $secureString = convertto-securestring $unsecureString -asplaintext -Force
            $fullname = $navUser[$a]
            New-NAVServerUser -ServerInstance NAV -UserName $navUser[$a].ToUpper() -FullName $fullname -Password $secureString -Verbose
            New-NAVServerUserPermissionSet -ServerInstance NAV -UserName $navUser[$a].ToUpper() -CompanyName $customerName -PermissionSetId SUPER -Verbose

            #open database connection
            [Environment]::NewLine
            Write-Output '##### Adding user to users setup table #####'
            $conn = New-Object System.Data.SqlClient.SqlConnection("Server=localhost\NAVDEMO;Database=$databaseName;Integrated Security=SSPI")
            $conn.Open()
            $cmd = $conn.CreateCommand()        
            $sqlCommand = "INSERT INTO [" + $databaseName + "].[dbo].[" + $customerName + "$" + "User Setup](
            [User ID]
            ,[Allow Posting From]
            ,[Allow Posting To]
            ,[Register Time]
            ,[Salespers__Purch_ Code]
            ,[Approver ID]
            ,[Sales Amount Approval Limit]
            ,[Purchase Amount Approval Limit]
            ,[Unlimited Sales Approval]
            ,[Unlimited Purchase Approval]
            ,[Substitute]
            ,[E-Mail]
            ,[Request Amount Approval Limit]
            ,[Unlimited Request Approval]
            ,[Approval Administrator]
            ,[Time Sheet Admin_]
            ,[Allow FA Posting From]
            ,[Allow FA Posting To]
            ,[Sales Resp_ Ctr_ Filter]
            ,[Purchase Resp_ Ctr_ Filter]
            ,[Service Resp_ Ctr_ Filter]
            ,[Max_ Auto_ Phys_ Invt_ Qty_]
            ,[Max_ Auto_ Phys_ Invt_ UOM]
            ,[Max_ Auto_ Phys_ Invt_ Value]
            ,[Dispatcher]
            ,[Default Weighbridge Code])
            VALUES (UPPER'" + $navUser[$a] + "'), '1753-01-01 00:00:00.000', '1753-01-01 00:00:00.000', '0', '0', '0', '0', '0', '0', '0', '0', 'user@user.net', '0', '0', '0', '0', '1753-01-01 00:00:00.000', '1753-01-01 00:00:00.000', '0', '0', '0', '0.00000000000000000000', 'MT', '0.00000000000000000000', '0', 'WEIGHBR. 1')"

            $cmd.CommandText = $sqlCommand
            $cmd.ExecuteNonQuery() 
            $conn.Close()     
        }     
    }   
}
