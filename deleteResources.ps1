


$secpasswd = ConvertTo-SecureString '123' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Hans', $secpasswd)
Login-AzureRmAccount -Verbose -Credential $cred



$completed = $False

do {
  $resources = Get-AzureRmResource -ResourceGroupName comotor |  where { (!$_.Name.Contains('notdelete')) -and (!$_.Name.Contains('tegosDTM-SStrassmann')) -and (!$_.Name.Contains('tt')) }

  foreach ($resource in $resources) {
    echo $resource.Name
    Remove-AzureRmResource -ResourceId $resource.ResourceId -Verbose -Force
  }
} 
while (!($resources -eq $null))






