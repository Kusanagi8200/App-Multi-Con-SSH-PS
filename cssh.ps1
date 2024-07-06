# Chemin vers le fichier de données
$dataFile = "C:\Users\rachel\Documents\data.json"

# Déclarer les hashtables
$global:Servers = @{}
$global:ServerKeys = @()

# Charger les données depuis data.json s'il existe
if (Test-Path $dataFile) {
    try {
        $jsonData = Get-Content -Path $dataFile -Raw | ConvertFrom-Json
        $global:Servers = @{}
        foreach ($key in $jsonData.Servers.PSObject.Properties.Name) {
            $global:Servers[$key] = $jsonData.Servers.$key
        }
        $global:ServerKeys = $jsonData.ServerKeys
    } catch {
        Write-Host "Erreur lors du chargement des données depuis $dataFile" -ForegroundColor Red
    }
}

function Save-Data {
    try {
        $jsonData = @{
            Servers = $global:Servers
            ServerKeys = $global:ServerKeys
        } | ConvertTo-Json -Depth 3

        $jsonData | Out-File -FilePath $dataFile
    } catch {
        Write-Host "Erreur lors de la sauvegarde des données dans $dataFile" -ForegroundColor Red
    }
}

function Add-New-Connection {
    $newName = Read-Host -Prompt "Nom de la nouvelle connexion"
    $newAddress = Read-Host -Prompt "Adresse de la nouvelle connexion (user@ip)"

    if ($newName -and $newAddress) {
        # Mettre à jour les tableaux avec la nouvelle connexion
        $global:ServerKeys += $newName
        $global:Servers[$newName] = $newAddress

        Save-Data

        Write-Host "Nouvelle connexion ajoutée avec succès !" -ForegroundColor Blue -BackgroundColor Green
    } else {
        Write-Host "Le nom et l'adresse sont requis !" -ForegroundColor Red -BackgroundColor Green
    }
}

function Delete-Connection {
    Write-Host "Liste des connexions existantes:" -ForegroundColor White -BackgroundColor Green
    for ($idx = 0; $idx -lt $global:ServerKeys.Length; $idx++) {
        $key = $global:ServerKeys[$idx]
        Write-Host "$idx) $key : $($global:Servers[$key])" -ForegroundColor White -BackgroundColor Green
    }
    $delChoice = Read-Host -Prompt "Entrez le numéro de la connexion que vous souhaitez supprimer"

    if ($delChoice -match '^\d+$' -and $delChoice -lt $global:ServerKeys.Length) {
        $key = $global:ServerKeys[$delChoice]
        $global:Servers.Remove($key)
        $global:ServerKeys = $global:ServerKeys | Where-Object { $_ -ne $key }
        Save-Data
        Write-Host "Connexion supprimée avec succès !" -ForegroundColor Red -BackgroundColor Green
    } else {
        Write-Host "CHOIX INVALID" -ForegroundColor Red -BackgroundColor Green
    }
}

function Show-Menu {
    Write-Host "__________CONNEXIONS SSH___________" -ForegroundColor White -BackgroundColor Green
    Write-Host ""
    for ($idx = 0; $idx -lt $global:ServerKeys.Length; $idx++) {
        $key = $global:ServerKeys[$idx]
        Write-Host "$idx) $key : $($global:Servers[$key])" -ForegroundColor White -BackgroundColor Green
        Write-Host ""
    }
    Write-Host "/) SORTIR_____________________________" -ForegroundColor Black -BackgroundColor Green
    Write-Host ""
    Write-Host "+) NOUVELLE CONNEXION_____________" -ForegroundColor Black -BackgroundColor Green
    Write-Host ""
    Write-Host "-) SUPPRIMER CONNEXION______________" -ForegroundColor Black -BackgroundColor Green
    Write-Host ""
}

while ($true) {
    Show-Menu
    Write-Host "SÉLECTION : " -NoNewline -ForegroundColor Black -BackgroundColor Green
    $choice = Read-Host

    if ($choice -eq "/") {
        exit
    } elseif ($choice -eq "+") {
        Add-New-Connection
    } elseif ($choice -eq "-") {
        Delete-Connection
    } elseif ($choice -match '^\d+$' -and $choice -lt $global:ServerKeys.Length) {
        $key = $global:ServerKeys[$choice]
        if ($global:Servers[$key]) {
            Write-Host "CONNEXION À $key..." -ForegroundColor Black -BackgroundColor Green
            ssh $global:Servers[$key]
        }
    } else {
        Write-Host "CHOIX INVALIDE" -ForegroundColor Black -BackgroundColor Green
    }
}
