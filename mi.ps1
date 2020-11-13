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

Connect-MsolService -Credential $destinationMigrationCredentials
Connect-SPOService -Credential $destinationMigrationCredentials -Url $url


# Get the list of all licensed users in O365 Azure AD and create an array that holds the user's UPN
#$Users = Get-AzureADUser -All $True | Where-Object {$_.UserType -eq 'Member' -and $_.AssignedLicenses -ne $null}
$Users = Get-MsolUser -All | Where-Object { $_.islicensed -eq $true }
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

#################
# Retry-Command #
#################
function Retry-Command {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Position=1, Mandatory=$false)]
        [int]$Maximum = 15,

        [Parameter(Position=2, Mandatory=$false)]
        [int]$Delay = 20
    )

    Begin {
        $cnt = 0
    }

    Process {
        do {
            $cnt++
            try {
                $ScriptBlock.Invoke()
                return
            } catch {
                Write-Host "An error occured, retrying in 20 seconds ..." -ForegroundColor Yellow -ErrorAction Continue
                Write-Host $_.exception.Message -ForegroundColor Yellow 
                Start-Sleep -Seconds $Delay
            }
        } while ($cnt -lt $Maximum)

        # Info
        write-host "Execution failed" -ForegroundColor Red
    }
}

# Create OneDrive for licensed users in O365 tenant who does not have a OneDrive setup for them(using array of UPN we created for licensed users)
Retry-Command -ScriptBlock {
foreach($i in $Users){
    $NameofOneDrive = Get-PnPUserProfileProperty -Account $i.UserPrincipalName  
    $u =  Get-OneDriveUrl -Tenant $dsttenant -Email $i.UserPrincipalName
    if($null -eq $u){
      Write-Host ("creating OneDrive for "+ $NameofOneDrive.DisplayName +" who does not have a OneDrive ") -ForegroundColor Yellow
      
      $p = New-PnPPersonalSite -Email $i.UserPrincipalName 
      Start-Sleep -Seconds 240
      Get-OneDriveUrl -Tenant $dsttenant -Email $p.UserPrincipalName -ProvisionIfRequired 
    }
 }
}
# Arbitrary wait to avoid synchronization issues
Start-Sleep -Seconds 180

Write-Host "List of all OneDrives: "

foreach($email in $Users){ 
           
   $OneDriveSite =  Get-OneDriveUrl -Tenant $dsttenant -Email $email.UserPrincipalName -ProvisionIfRequired 

   Start-Sleep -Seconds 10

   Set-SPOUser -Site $OneDriveSite -LoginName $dstUsername -IsSiteCollectionAdmin $true

}




Write-Host "Migration started" -ForegroundColor Yellow
#Get files on server (here, My PC for test) and put the path/URL of each folder in an array - The name of folder should match the name of OneDrive in O365
[array]$files=Get-ChildItem -path "C:\Users\aatash-biz-yeganeh\OneDrive_Migration_Folder"  


foreach($serverFileName in $files ){
   # Write-Host ("Path of files on my pc: " + $serverFileName.fullName) -ForegroundColor Gray 
   # Write-Host ("Name of the user folder on my pc: " + $serverFileName) -ForegroundColor Red
    
    foreach($OneDriveuser in $Users){
        
        #Get-OneDriveUrl -Tenant $dsttenant -Email $OneDriveuser.UserPrincipalName -ProvisionIfRequired -DoNotWaitForProvisioning
        $displayNameofOneDrive = Get-PnPUserProfileProperty -Account $OneDriveuser.UserPrincipalName
       
       if($displayNameofOneDrive.DisplayName -eq $serverFileName ){
            Write-Host ("URL.DisplayName: " + $displayNameofOneDrive.DisplayName + " =  serverFileName: " +$serverFileName) -ForegroundColor Green
           
           #$mydrive =  Get-OneDriveUrl -Tenant $dsttenant -Email $OneDriveuser.UserPrincipalName -ProvisionIfRequired 
          # Write-Host "my drive that I want to connect now :  $mydrive "

            $dstSite = Connect-Site -Url $displayNameofOneDrive.PersonalUrl  -Username $dstUsername -Password $dstPassword
           
            #$dstSite = Connect-Site -Url  $mydrive  -Username $dstUsername -Password $dstPassword
            
      
            Write-Host ("Destination site that we successfully connected to :    "+$dstSite) -ForegroundColor Red -BackgroundColor Yellow

            if($dstSite){
        
            Add-SiteCollectionAdministrator -Site $dstSite

            $dstList = Get-List -Name Documents -Site $dstSite
            Import-Document -SourceFolder $serverFileName.fullName -DestinationList $dstList 
            Remove-SiteCollectionAdministrator -Site $dstSite
        }
    }
               
    }

}


#Read this , it may help me to solve the migrtaion issue (connect site)
#https://support-desktop.sharegate.com/hc/en-us/articles/115000602087?utm_source=Sharegate&utm_medium=App&utm_content=Migration&utm_campaign=App-Support

# Also, give site collection admin before connect-site  OR connect-PnPOnline to onedrive -> create folder inside onedrive -> connect-site and the rest 
