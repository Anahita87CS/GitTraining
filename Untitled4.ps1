$AdminUrl = "https://swordcanada-admin.sharepoint.com"
Connect-SPOService -Url $AdminUrl
$NewODFBUsers = "Cody@swordcanada.onmicrosoft.com"
Request-SPOPersonalSite -UserEmails $NewODFBusers


$OneDriveSiteURL = "https://swordcanada-my.sharepoint.com/personal/leeg_swordcanada_onmicrosoft_com/"
$FolderName = "Archives"
  
Try {
    #Connect to PnP Online
    Connect-PnPOnline -Url $OneDriveSiteURL -Credentials (Get-Credential)

    Connect-PnPOnline -Url   -c
      
    #ensure folder in SharePoint online using powershell
    Resolve-PnPFolder -SiteRelativePath "Documents/$FolderName"
}
catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
}


#Read more: https://www.sharepointdiary.com/2019/09/onedrive-for-business-powershell-to-create-folder.html#ixzz6dUf6c23M