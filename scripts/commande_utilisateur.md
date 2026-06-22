Import-Module ActiveDirectory

$csvPath = "C:\utilisateurs.csv"

$targetOU = "OU=Utilisateurs,OU=@cyna.local,DC=cyna,DC=local"

$users = Import-Csv -Path $csvPath -Delimiter ","

foreach ($user in $users) {
    

    $securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force
    
    $userParams = @{
        Name                  = "$($user.FirstName) $($user.LastName)"
        GivenName             = $user.FirstName
        Surname               = $user.LastName
        SamAccountName        = $user.SamAccountName
        UserPrincipalName     = "$($user.SamAccountName)@cyna.local"
        Path                  = $targetOU      
        AccountPassword       = $securePassword
        Enabled               = $false         
        ChangePasswordAtLogon = $true      
    }
    
    try {
        New-ADUser @userParams
        Write-Host "Utilisateur créé dans Utilisateurs : $($user.SamAccountName) (Désactivé + Changement MDP requis)" -ForegroundColor Green
    } catch {
        Write-Host "Erreur sur l'utilisateur $($user.SamAccountName) : $_" -ForegroundColor Red
    }
}
