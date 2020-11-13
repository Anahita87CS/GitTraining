Import-Module Sharegate
if(!(Get-Module SharePointPnPPowerShellOnline))  {
    Install-Module  SharePointPnPPowerShellOnline -Force -AllowClobber
}
# Install Azure AD if it is not already installed
if (!(Get-Module AzureAD)) {
       Install-Module  AzureAD -Force -AllowClobber
    }



$url="https://swordcanada-admin.sharepoint.com"

$dstUsername = "anahita.atash-biz-yeganeh@swordcanada.onmicrosoft.com"
$dstPassword = ConvertTo-SecureString "Annakjkj@75" -AsPlainText -Force
[System.Management.Automation.PSCredential]$destinationMigrationCredentials = New-Object System.Management.Automation.PSCredential($dstUsername, $dstPassword)
$dsttenant = Connect-Site -Url $url -Username $dstUsername -Password $dstPassword
Connect-PnPOnline -url $url -Credentials $destinationMigrationCredentials

Connect-AzureAD -Credential $destinationMigrationCredentials


# Get the list of all licensed users in O365 Azure AD and create an array that holds the user's UPN
$Users = Get-AzureADUser -All $True | Where-Object {$_.UserType -eq 'Member' -and $_.AssignedLicenses -ne $null}



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
      Start-Sleep -Seconds 10

     
    }
 }
 
# Arbitrary wait to avoid synchronization issues
#Start-Sleep -Seconds 10
$FolderName = "Data"
foreach($email in $Users){ 
           
   $OneDriveSiteURL = Get-OneDriveUrl -Tenant $dsttenant -Email $email.UserPrincipalName -ProvisionIfRequired -DoNotWaitForProvisioning 

    Try {
    #Connect to PnP Online
    Connect-PnPOnline -Url $OneDriveSiteURL -Credentials $destinationMigrationCredentials
      
    #ensure folder in SharePoint online using powershell
    #Resolve-PnPFolder -SiteRelativePath "Documents/$FolderName"
}
catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor yellow
}
   
}






Write-Host "List of all OneDrives: "

foreach($email in $Users){ 
           
    $d = Get-OneDriveUrl -Tenant $dsttenant -Email $email.UserPrincipalName -ProvisionIfRequired -DoNotWaitForProvisioning 
   try{

    Connect-Site -Url  $d  -Username $dstUsername -Password $dstPassword
   }
   catch{
    Write-Host "An error occured, retrying in 20 seconds ..." -ForegroundColor Yellow -ErrorAction Continue
                Write-Host $_.exception.Message -ForegroundColor Yellow 
                Start-Sleep -Seconds 10
   }
}

