
<#
---------------------------------------------------------------------------------------------
    Copyright © 2020  SWORD TECHNOLOGIES.  All rights reserved.
---------------------------------------------------------------------------------------------
    PowerShell Source Code

    NAME: Migration.ps1
    AUTHORS:    
        - Anahita ATASH-BIZ-YEGANEH  - SWORD TECHNOLOGIES (anahita.atash-biz-yeganeh@sword-group.com)
    DATE  : 27/11/2020

    DESCRIPTION:
        *  Migrate files from server/source to OneDrive for business
---------------------------------------------------------------------------------------------
#>

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

Import-Module Sharegate
if(!(Get-Module SharePointPnPPowerShellOnline))  {
    Install-Module  SharePointPnPPowerShellOnline -Force -AllowClobber
}

             
$dsttenant = Connect-Site -Url $TenantUrl -Username $dstUsername -Password $dstPassword
Connect-PnPOnline -url $TenantUrl -Credentials $destinationMigrationCredentials
Connect-SPOService -Credential $destinationMigrationCredentials -Url $TenantUrl
Connect-MsolService -Credential $destinationMigrationCredentials

# Get the list of all licensed users in O365 Azure AD and create an array that holds the user's UPN
$Users = Get-MsolUser -All | Where-Object { $_.islicensed -eq $true }
Write-Output "Users who have the license"

# Create OneDrive for licensed users in O365 tenant who does not have a OneDrive setup for them(using array of UPN we created for licensed users)

    $Users |ForEach-Object{
        $NameofOneDrive = Get-PnPUserProfileProperty -Account $_.UserPrincipalName  
        $userOneDrive =  Get-OneDriveUrl -Tenant $dsttenant -Email $_.UserPrincipalName
        if($null -eq $userOneDrive){
          Write-Output ("creating OneDrive for "+ $NameofOneDrive.DisplayName +" who does not have a OneDrive ") -ForegroundColor Yellow
          
          $newOneDrive = New-PnPPersonalSite -Email $_.UserPrincipalName 
          Start-Sleep -Seconds 30
          Get-OneDriveUrl -Tenant $dsttenant -Email $newOneDrive.UserPrincipalName -ProvisionIfRequired 
          Start-Sleep -Seconds 30
 
        }      
     }
   


# Arbitrary wait to avoid synchronization issues
Start-Sleep -Seconds 30


Write-Host "Migration started" -ForegroundColor Yellow
#Get files on server (here, My PC for test) and put the path/URL of each folder in an array - The name of folder should match the name of OneDrive in O365
[array]$files=Get-ChildItem -path $ServerPath   


foreach($serverFileName in $files ){

     foreach($OneDriveuser in $Users){

        
        if($OneDriveuser.DisplayName -eq $serverFileName ){
             Write-Host ("URL.DisplayName: " + $OneDriveuser.DisplayName + " =  serverFileName: " +$serverFileName) -ForegroundColor Green
            
           $OneDrive =  Get-OneDriveUrl -Tenant $dsttenant -Email $OneDriveuser.UserPrincipalName -ProvisionIfRequired 
           # Write-Host "my drive that I want to connect now :  $mydrive "
           Set-SPOUser -Site $OneDrive -LoginName $dstUsername -IsSiteCollectionAdmin $true
           Connect-PnPOnline -Url $OneDrive -Credentials $destinationMigrationCredentials
            $DestinationFolder = Add-PnPFolder -Name "Migrated Data"  -Folder "Documents"
 
             $dstSite = Connect-Site -Url $OneDrive  -Username $dstUsername -Password $dstPassword

             Write-Host ("Destination site that we successfully connected to :    "+$dstSite) -ForegroundColor Red -BackgroundColor Yellow
 
             if($dstSite){
         
             Add-SiteCollectionAdministrator -Site $dstSite
 
             $dstList = Get-List -Name Documents -Site $dstSite
             Import-Document -SourceFolder $serverFileName.fullName -DestinationList $dstList -DestinationFolder "Migrated Data"
             Remove-SiteCollectionAdministrator -Site $dstSite
         }
     }
                
     }
 
 }






# Also, give site collection admin before connect-site  OR connect-PnPOnline to onedrive -> create folder inside onedrive -> connect-site and the rest 
