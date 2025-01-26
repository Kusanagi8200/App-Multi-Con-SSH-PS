# Modifier l'encodage du terminal pour UTF-8
# chcp 65001
$OutputEncoding = New-Object -typename System.Text.UTF8Encoding

# Chemin vers le fichier de données
$dataFile = "data.json"

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
        Write-Host "ERREUR LORS DU CHARGEMENT DES DONNEES" -ForegroundColor Red
    }
}

function Save-Data {
    try {
        $jsonData = @{
            ServerKeys = $global:ServerKeys
            Servers = $global:Servers
        } | ConvertTo-Json -Depth 3

        # Sauvegarde dans le fichier JSON
        $jsonData | Out-File -FilePath $dataFile -Encoding utf8

        # Message de confirmation de sauvegarde
        #Write-Host "DONNEES SAUVEGARDEES" $dataFile -ForegroundColor White
    }
    catch {
        Write-Host "ERREUR LORS DE LA SAUVEGARDE DES DONNEES" -ForegroundColor Red
    }
}

function Add-New-Connection {
    $newName = Read-Host -Prompt "NOM DE LA NOUVELLE CONNEXION"
    $newAddress = Read-Host -Prompt "ADRESSE DE LA NOUVELLE CONNEXION (user@ip)"

    if ($newName -and $newAddress) {
        # Mettre à jour les tableaux avec la nouvelle connexion
        $global:ServerKeys += $newName
        $global:Servers[$newName] = $newAddress

        # Sauvegarde des données après l'ajout
        Save-Data

        Write-Host "NOUVELLE CONNEXION AJOUTEE AVEC SUCCES" -ForegroundColor Black -BackgroundColor Green
    } else {
        Write-Host "LE NOM ET L'IP SONT REQUIS" -ForegroundColor Red -BackgroundColor Green
    }
}

function Remove-Connection {
    Write-Host "LISTE DES CONNEXIONS DISPONIBLES :" -ForegroundColor White -BackgroundColor Green
    for ($idx = 0; $idx -lt $global:ServerKeys.Length; $idx++) {
        $key = $global:ServerKeys[$idx]
        Write-Host "$idx) $key : $($global:Servers[$key])" -ForegroundColor White -BackgroundColor Green
    }

    # Demander à l'utilisateur de sélectionner une connexion à supprimer
    $delChoice = Read-Host -Prompt "NUMERO DE LA CONNEXION A SUPPRIMER"

    if ($delChoice -match '^\d+$' -and $delChoice -lt $global:ServerKeys.Length) {
        $key = $global:ServerKeys[$delChoice]

        # Supprimer la connexion dans la liste des serveurs
        $global:Servers.Remove($key)
        
        # Supprimer la clé dans la liste ServerKeys
        $global:ServerKeys = $global:ServerKeys | Where-Object { $_ -ne $key }

        # Sauvegarder les données après modification
        Save-Data

        Write-Host "CONNEXION SUPPRIMEE AVEC SUCCES" -ForegroundColor Red -BackgroundColor Green
    } else {
        Write-Host "CHOIX INVALIDE. VEUILLEZ ESSAYER À NOUVEAU" -ForegroundColor Red -BackgroundColor Green
    }
}

function Show-Menu {
    Write-Host "__________CONNEXIONS SSH___________" -ForegroundColor Black -BackgroundColor Green
    Write-Host ""

    # Vérifier si des connexions sont disponibles
    if ($global:ServerKeys.Count -eq 0) {
        Write-Host "AUCUNE CONNEXION DISPONIBLE" -ForegroundColor Yellow
    } else {
        # Afficher les connexions existantes
        for ($idx = 0; $idx -lt $global:ServerKeys.Length; $idx++) {
            $key = $global:ServerKeys[$idx]
            Write-Host "$idx) $key : $($global:Servers[$key])" -ForegroundColor White -BackgroundColor Green
        }
    }

    Write-Host ""  # Ligne vide
    Write-Host "/  SORTIR_____________________________" -ForegroundColor Black -BackgroundColor Green
    Write-Host ""  # Ligne vide
    Write-Host "+  NOUVELLE CONNEXION_____________" -ForegroundColor Black -BackgroundColor Green
    Write-Host ""  # Ligne vide
    Write-Host "-  SUPPRIMER CONNEXION______________" -ForegroundColor Black -BackgroundColor Green
    Write-Host ""  # Ligne vide
}

while ($true) {
    Show-Menu
    Write-Host "SELECTION : " -NoNewline -ForegroundColor Black -BackgroundColor Green
    $choice = Read-Host

    if ($choice -eq "/") {
        exit
    } elseif ($choice -eq "+") {
        Add-New-Connection
    } elseif ($choice -eq "-") {
        Remove-Connection
    } elseif ($choice -match '^\d+$' -and $choice -lt $global:ServerKeys.Length) {
        $key = $global:ServerKeys[$choice]
        if ($global:Servers[$key]) {
            Write-Host "CONNEXION AU SERVEUR $key..." -ForegroundColor Black -BackgroundColor Green
            ssh $global:Servers[$key]
        }
    } else {
        Write-Host "CHOIX INVALIDE" -ForegroundColor Red -BackgroundColor Green
        Start-Sleep -Seconds 2 # Ajoute un délai pour que l'utilisateur puisse voir l'erreur avant de recommencer
    }
}
