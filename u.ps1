Import-Module Sharegate
#Get list of file inventory on server and write it in a .txt file
Get-ChildItem -path C:\Users\aatash-biz-yeganeh\OneDrive_Migration_Folder -recurse | Select-Object FullName,DirectoryName | Export-Csv C:\Users\aatash-biz-yeganeh\oneDriveTest-ShareGate\Inventory.csv -NoTypeInformation

# Install Azure AD if it is not already installed
if (!(Get-Module AzureAD)) {
       Install-Module  AzureAD -Force -AllowClobber
    }

$dstUsername = "AnaAtash@migrationlearning.onmicrosoft.com"
$dstPassword = ConvertTo-SecureString "Annakjkj@75" -AsPlainText -Force
[System.Management.Automation.PSCredential]$destinationMigrationCredentials = New-Object System.Management.Automation.PSCredential($dstUsername, $dstPassword)
$dsttenant = Connect-Site -Url "https://MigrationLearning-admin.sharepoint.com" -Username $dstUsername -Password $dstPassword
Connect-PnPOnline -url "https://MigrationLearning-admin.sharepoint.com" -Credentials $destinationMigrationCredentials
Connect-AzureAD -Credential $destinationMigrationCredentials

$Users = Get-AzureADUser -All $True | Where {$_.UserType -eq 'Member' -and $_.AssignedLicenses -ne $null}
$UsersArray = @()

foreach ($user in $Users) 
{
    $SPProfile  = Get-PnPUserProfileProperty -Account $user.UserPrincipalName -ErrorAction SilentlyContinue
        if ($SPProfile -ne $null)
        {
          if ($SPProfile.UserProfileProperties.AboutMe -eq "")
            {
               $UsersArray += $user
            }
        }
}

# to test if I got the correct UPN and display name of users
$UsersArray | Select-Object DisplayName, UserPrincipalName | Export-Csv -Path "C:\Users\aatash-biz-yeganeh\oneDriveTest-ShareGate\OneDrive_Users.csv" -NoTypeInformation


# Get OneDrive URLs of users in O365 tenant
foreach ($row in $Users) {
    $dstresult = Get-OneDriveUrl -Tenant $dsttenant -Email $row.UserPrincipalName -ProvisionIfRequired -DoNotWaitForProvisioning
    $displayNameofOneDrive = Get-PnPUserProfileProperty -Account $row.UserPrincipalName
    if( $dstresult){
        Write-Host ("OneDrive URL:  "+$dstresult) -ForegroundColor Black -BackgroundColor White
        Write-Host ("OneDrive User Name:  "+$displayNameofOneDrive.DisplayName) -ForegroundColor Black -BackgroundColor White
    }
}

#Get files on server (here, My PC for test) and put the path/URL in an array
[array]$files=Get-ChildItem -path "C:\Users\aatash-biz-yeganeh\OneDrive_Migration_Folder"  
foreach($serverFileName in $files ){
    Write-Host ("Path of files on my pc: " + $serverFileName.fullName) -ForegroundColor Gray 
    Write-Host ("Name of the user folder on my pc: " + $serverFileName) -ForegroundColor Red
    foreach($OneDriveuser in $Users){
        $dstresult = Get-OneDriveUrl -Tenant $dsttenant -Email $OneDriveuser.UserPrincipalName -ProvisionIfRequired -DoNotWaitForProvisioning
        $displayNameofOneDrive = Get-PnPUserProfileProperty -Account $OneDriveuser.UserPrincipalName
      
       if($displayNameofOneDrive.DisplayName -eq $serverFileName ){
            Write-Host ("URL.DisplayName: " + $displayNameofOneDrive.DisplayName + " =  serverFileName: " +$serverFileName) -ForegroundColor Green
            
            $dstSite = Connect-Site -Url $displayNameofOneDrive.PersonalUrl  -Username $dstUsername -Password $dstPassword
            Write-Host ("Destination site :    "+$dstSite)
            Add-SiteCollectionAdministrator -Site $dstSite
            $dstList = Get-List -Name Documents -Site $dstSite
            Import-Document -SourceFolder $serverFileName.fullName -DestinationList $dstList -DestinationFolder "Migrated Data"
            Remove-SiteCollectionAdministrator -Site $dstSite
        }
       
       
        
    }

}
<#
# work on this part 
[array]$files=Get-ChildItem -path "C:\Users\aatash-biz-yeganeh\OneDrive_Migration_Folder"  

    foreach($serverFileName in $files ){
        Write-Host ("Path of files on my pc: " + $serverFileName.fullName) -ForegroundColor Gray 
        Write-Host ("Name of the user folder on my pc: " + $serverFileName) -ForegroundColor Red
        foreach($OneDriveuser in $table){
            $dstresult = Get-OneDriveUrl -Tenant $dsttenant -Email $row -ProvisionIfRequired -DoNotWaitForProvisioning
           
          
           if($URL.DisplayName -eq $serverFileName ){
                Write-Host ("URL.DisplayName: " + $URL.DisplayName + " __ serverFileName: " +$serverFileName) -ForegroundColor Green
                $dstSite = Connect-Site -Url $URL.PersonalUrl  -Username $dstUsername -Password $dstPassword
                Write-Host ("Destination site :    "+$dstSite)
                Add-SiteCollectionAdministrator -Site $dstSite
                $dstList = Get-List -Name Documents -Site $dstSite
                Import-Document -SourceFolder $serverFileName.fullName -DestinationList $dstList -DestinationFolder "Migrated Data"
                Remove-SiteCollectionAdministrator -Site $dstSite
            }
            else{
                continue
            }
           
            
        }

    }










[array]$files=Get-ChildItem -path "C:\Users\aatash-biz-yeganeh\OneDrive_Migration_Folder"  
$names = @("sara@MigrationLearning.onmicrosoft.com")
    foreach($serverFileName in $files ){
        Write-Host ($serverFileName.fullName) -ForegroundColor Blue
        Write-Host ($serverFileName) -ForegroundColor Red
        foreach($OneDriveuser in $names){
            $URL = Get-PnPUserProfileProperty -Account $OneDriveuser  
           
          
           if($URL.DisplayName -eq $serverFileName ){
                Write-Host ("URL.DisplayName: " + $URL.DisplayName + " __ serverFileName: " +$serverFileName) -ForegroundColor Green
                $dstSite = Connect-Site -Url $URL.PersonalUrl  -Username $dstUsername -Password $dstPassword
                Write-Host ("Destination site :    "+$dstSite)
                Add-SiteCollectionAdministrator -Site $dstSite
                $dstList = Get-List -Name Documents -Site $dstSite
                Import-Document -SourceFolder $serverFileName.fullName -DestinationList $dstList -DestinationFolder "Migrated Data"
                Remove-SiteCollectionAdministrator -Site $dstSite
            }
            else{
                continue
            }
           
            
        }

    }



   
foreach($user in $names){
    $URL = Get-PnPUserProfileProperty -Account $user 
    $dstSite = Connect-Site -Url $URL.PersonalUrl  -Username $dstUsername -Password $dstPassword
    Add-SiteCollectionAdministrator -Site $dstSite
    $dstList = Get-List -Name Documents -Site $dstSite
    foreach($i in $files ){
   if($URL.DisplayName -eq $i ){
        Write-Host ("i.DisplayName: "+$i.DisplayName+"i: "+$i) -ForegroundColor Green
        Import-Document -SourceFolder $i.PersonalUrl -DestinationList $dstList -DestinationFolder "Migrated Data"
    }
   
    Remove-SiteCollectionAdministrator -Site $dstSite
}
}


$dstSite = Connect-Site -Url "https://migrationlearning-my.sharepoint.com/personal/anaatash_migrationlearning_onmicrosoft_com/" -Username $dstUsername -Password $dstPassword
    Add-SiteCollectionAdministrator -Site $dstSite
    $dstList = Get-List -Name Documents -Site $dstSite
    #Import-Document -SourceFolder $URL.PersonalUrl -DestinationList $dstList
    Import-Document -SourceFolder "C:\Users\aatash-biz-yeganeh\OneDrive_Migration_Folder" -DestinationList $dstList -DestinationFolder "Migrated Data"
    Remove-SiteCollectionAdministrator -Site $dstSite
#>

