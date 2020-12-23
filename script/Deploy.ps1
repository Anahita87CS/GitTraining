
[CmdletBinding()]
param(
        
    [Parameter(Mandatory= $false)]
    [string] $dstUsername, # add it as site collectio admin to all onedrives
    [Parameter(Mandatory= $false)]
    [string] $TenantUrl,
    [Parameter(Mandatory= $false)]
    [PSCredential] $destinationMigrationCredentials,
    [Parameter(Mandatory= $false)]
    [string] $ServerPath # source/location of files at source on server
) 

$ServerPath = "C:\Users\aatash-biz-yeganeh\OneDrive_Migration_Folder"
$TenantUrl="https://swordcanada-admin.sharepoint.com"
$dstUsername = "anahita.atash-biz-yeganeh@swordcanada.onmicrosoft.com"
$dstPassword = ConvertTo-SecureString "khodayar@1987" -AsPlainText -Force
#$ServerPath = "C:\Users\aatash-biz-yeganeh\OneDrive_Migration_Folder"
[System.Management.Automation.PSCredential]$destinationMigrationCredentials = New-Object System.Management.Automation.PSCredential($dstUsername, $dstPassword)

#Get list of file inventory on server and write it in a .txt file -Credentials $destinationMigrationCredentials `
Get-ChildItem -path $ServerPath -recurse | Select-Object FullName,DirectoryName | Export-Csv C:\Users\aatash-biz-yeganeh\oneDriveTest-ShareGate\Inventory.csv -NoTypeInformation
  
   # Include "Deploy" file 
   . ".\Deploy"
   