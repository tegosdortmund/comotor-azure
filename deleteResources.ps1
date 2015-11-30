

New-AzureRmResourceGroupDeployment -Name comotor42 -ResourceGroupName comotor -TemplateUri 'https://raw.githubusercontent.com/tegosdortmund/comotor-azure/master/azuredeploy.json' -TemplateParameterFile 'C:\Users\sstrassmann\Desktop\Seminararbeit\other resources\azuredeploy.param.dev.json'


$secpasswd = ConvertTo-SecureString '' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('', $secpasswd)
Login-AzureRmAccount -Verbose -Credential $cred




do {
  $resources = Get-AzureRmResource -ResourceGroupName 'comotor' |  where { (!$_.Name.Contains('notdelete')) -and (!$_.Name.Contains('tegosDTM-SStrassmann')) -and (!$_.Name.Contains('grau')) }

  foreach ($resource in $resources) {
    echo $resource.Name
    Remove-AzureRmResource -ResourceId $resource.ResourceId -Verbose -Force
  }
} 
while (!($resources -eq $null))






