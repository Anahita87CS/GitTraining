Import-Module Sharegate
if(!(Get-Module SharePointPnPPowerShellOnline))  {
    Install-Module  SharePointPnPPowerShellOnline -Force -AllowClobber
}
# Install Azure AD if it is not already installed
if (!(Get-Module AzureAD)) {
       Install-Module  AzureAD -Force -AllowClobber
    }

#Get list of file inventory on server and write it in a .txt file
Get-ChildItem -path C:\Users\aatash-biz-yeganeh\OneDrive_Migration_Folder -recurse | Select-Object FullName,DirectoryName | Export-Csv C:\Users\aatash-biz-yeganeh\oneDriveTest-ShareGate\Inventory.csv -NoTypeInformation

$url="https://swordcanada-admin.sharepoint.com"

$dstUsername = "anahita.atash-biz-yeganeh@swordcanada.onmicrosoft.com"
$dstPassword = ConvertTo-SecureString "Annakjkj@75" -AsPlainText -Force
[System.Management.Automation.PSCredential]$destinationMigrationCredentials = New-Object System.Management.Automation.PSCredential($dstUsername, $dstPassword)
$dsttenant = Connect-Site -Url $url -Username $dstUsername -Password $dstPassword
Connect-PnPOnline -url $url -Credentials $destinationMigrationCredentials

Connect-AzureAD -Credential $destinationMigrationCredentials


# Get the list of all licensed users in O365 Azure AD and create an array that holds the user's UPN
$Users = Get-AzureADUser -All $True | Where-Object {$_.UserType -eq 'Member' -and $_.AssignedLicenses -ne $null}
$UsersArray = @()

foreach ($user in $Users) 
{
    $SPProfile  = Get-PnPUserProfileProperty -Account $user.UserPrincipalName -ErrorAction SilentlyContinue
        if ($null -ne $SPProfile)
        {
          if ($SPProfile.UserProfileProperties.AboutMe -eq "")
            {
               $UsersArray += $user
            }
        }
}

# to test if I got the correct UPN and display name of users
$UsersArray | Select-Object DisplayName, UserPrincipalName | Export-Csv -Path "C:\Users\aatash-biz-yeganeh\oneDriveTest-ShareGate\liscenced_Users.csv" -NoTypeInformation

$Users | Select-Object DisplayName, UserPrincipalName | Export-Csv -Path "C:\Users\aatash-biz-yeganeh\oneDriveTest-ShareGate\Users.csv" -NoTypeInformation

# Create OneDrive for licensed users in O365 tenant who does not have a OneDrive setup for them(using array of UPN we created for licensed users)
foreach($i in $Users){
    $NameofOneDrive = Get-PnPUserProfileProperty -Account $i.UserPrincipalName  
    $u =  Get-OneDriveUrl -Tenant $dsttenant -Email $i.UserPrincipalName
    if($null -eq $u){
      Write-Host ("creating OneDrive for "+ $NameofOneDrive.DisplayName +" who does not have a OneDrive ") -ForegroundColor Yellow
      
      New-PnPPersonalSite -Email $i.UserPrincipalName 
      
    }
 }
 
# Arbitrary wait to avoid synchronization issues
Start-Sleep -Seconds 15

Write-Host "List of all OneDrives: "
foreach($email in $Users){ 
           
    Get-OneDriveUrl -Tenant $dsttenant -Email $email.UserPrincipalName -ProvisionIfRequired 
    
}

Start-Sleep -Seconds 30
Write-Host "Migration started" -ForegroundColor Yellow
#Get files on server (here, My PC for test) and put the path/URL of each folder in an array - The name of folder should match the name of OneDrive in O365
[array]$files=Get-ChildItem -path "C:\Users\aatash-biz-yeganeh\OneDrive_Migration_Folder"  

Set-Variable dstSite, dstList
foreach($serverFileName in $files ){
   # Write-Host ("Path of files on my pc: " + $serverFileName.fullName) -ForegroundColor Gray 
   # Write-Host ("Name of the user folder on my pc: " + $serverFileName) -ForegroundColor Red
    
    foreach($OneDriveuser in $Users){
        Clear-Variable dstSite
        Clear-Variable dstList
        #Get-OneDriveUrl -Tenant $dsttenant -Email $OneDriveuser.UserPrincipalName -ProvisionIfRequired -DoNotWaitForProvisioning
        $displayNameofOneDrive = Get-PnPUserProfileProperty -Account $OneDriveuser.UserPrincipalName
       
       if($displayNameofOneDrive.DisplayName -eq $serverFileName ){
            Write-Host ("URL.DisplayName: " + $displayNameofOneDrive.DisplayName + " =  serverFileName: " +$serverFileName) -ForegroundColor Green
           
           $mydrive =  Get-OneDriveUrl -Tenant $dsttenant -Email $OneDriveuser.UserPrincipalName -ProvisionIfRequired -DoNotWaitForProvisioning 

           
  
           Write-Host "my drive that I want to connect now :  $mydrive "

            $dstSite = Connect-Site -Url $displayNameofOneDrive.PersonalUrl  -Username $dstUsername -Password $dstPassword
           
            #$dstSite = Connect-Site -Url  $mydrive  -Username $dstUsername -Password $dstPassword
            
      
            Write-Host ("Destination site that we successfully connected to :    "+$dstSite) -ForegroundColor Red -BackgroundColor Yellow
        
            Add-SiteCollectionAdministrator -Site $dstSite

            $dstList = Get-List -Name Documents -Site $dstSite
            Import-Document -SourceFolder $serverFileName.fullName -DestinationList $dstList 
            Remove-SiteCollectionAdministrator -Site $dstSite
        }
       
       
        
    }

}