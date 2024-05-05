param(
    [string]$Country,
    [string]$Id,
    [switch]$Version,
    [switch]$Help
)

function Show-Version {
    Write-Host "Wireguard Config Files for NordVPN v0.1.0"
    exit
}

function Show-Help {
    Write-Host "Usage: NordVpnToWireguard [OPTIONS]"
    Write-Host "OPTION includes:"
    Write-Host "   -Version           - prints out version information."
    Write-Host "   -Country <country> - Country to connect to (ex. Canada). If option is not provided, NordVPN will get a wireguard configuration for the recommended country, unless a valid city name is provided."
    Write-Host "   -Id <id>           - ID to connect to (ex. 1234)."
    Write-Host "   -Help              - displays this message."
    exit
}

# Process arguments
if ($Version.IsPresent) {
    Show-Version
}

if ($Help.IsPresent) {
    Show-Help
}

# Debug output
if ($Country) {
    $Country = $Country -replace '_', ' '
    # Write-Host "DEBUG: Found country $Country"
}
if ($Id) {
    # Write-Host "DEBUG: Found ID $Id"
    if (-not $Country) {
        Write-Host "While specifying -Id, you also need to specify -Country. Exiting..."
        exit 1
    }
}

# Check if the script is running as an administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Prepare the arguments to pass to the elevated instance
    $params = ""
    if ($Country) {
        $params += " -Country `"$Country`""
    }
    if ($Id) {
        $params += " -Id `"$Id`""
    }
    if ($Version) {
        $params += " -Version"
    }
    if ($Help) {
        $params += " -Help"
    }

    # Relaunch the script with administrator rights using pwsh
    $scriptPath = $MyInvocation.MyCommand.Definition
    Write-Host "Relaunching script with administrator rights... - -NoExit -File `"$scriptPath`" $params"
    Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit -File `"$scriptPath`" $params"
    exit
}

function Check-InternetConnectivity {
    $url = "https://www.wtfismyip.com/json"

    while ($true) {
        try {
            $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 5
            if ($response.YourFuckingIPAddress) {
                Write-Host "Internet connectivity confirmed."
                break
            }
        } catch {
            Write-Host "Attempt failed: Unable to confirm internet connectivity. Retrying in 5 seconds..."
        }
        Start-Sleep -Seconds 5
    }
}

if (-not $Country -and -not $Id) {
    Write-Host "Getting configuration for recommended server..."
    nordvpn -c > $null 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Unable to connect to NordVPN."
        exit 1
    }
}
elseif ($Country -and -not $Id) {
    Write-Host "Getting configuration for recommended server in $Country"
    nordvpn -c -g $Country > $null 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Unable to connect to NordVPN."
        exit 1
    }
}
elseif ($Id -and $Country) {
    Write-Host "Getting configuration for recommended server in $Country with ID $Id"
    nordvpn -c -n "$Country #$Id" > $null 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Unable to connect to NordVPN."
        exit 1
    }
}
elseif (-not $Country -and $Id) {
    Write-Host "Please provide the Country group for the provided ID."
}

# Pooling for nordlynx interface
$interfaceExists = $false
$retryCount = 0
$retryLimit = 12 # 60 seconds at 5-second intervals

while (-not $interfaceExists -and $retryCount -lt $retryLimit) {
    Write-Host "Checking for NordLynx interface... Attempt $($retryCount + 1) of $retryLimit"
    Start-Sleep -Seconds 5
    $interfaceExists = (Get-NetAdapter -Name 'NordLynx' -ErrorAction SilentlyContinue) -ne $null
    $retryCount++
}

if (-not $interfaceExists) {
    Write-Host "NordLynx interface not found. Ensure that NordVPN is connected."
    exit 1
}

# Preparing the Interface section
"[Interface]" | Out-File -FilePath Nordvpn.conf
$privateKey = (wg show NordLynx private-key)
"PrivateKey = $privateKey" | Add-Content -Path Nordvpn.conf
"ListenPort = 51820" | Add-Content -Path Nordvpn.conf
$localAddress = (Get-NetIPAddress -InterfaceAlias NordLynx -AddressFamily IPv4).IPAddress
"Address = $localAddress/32" | Add-Content -Path Nordvpn.conf
"DNS = 103.86.96.100, 103.86.99.100" | Add-Content -Path Nordvpn.conf
"" | Add-Content -Path Nordvpn.conf

Write-Host "Checking internet conectivity..."
Check-InternetConnectivity
Start-Sleep 5

$response = Invoke-RestMethod -Uri "https://api.nordvpn.com/v1/servers/recommendations?&filters[servers_technologies][identifier]=wireguard_udp&limit=1"
if ($response) {
    $hostname = $response.hostname
    $station = $response.station
    $wireguardTechnology = $response.technologies | Where-Object { $_.identifier -eq "wireguard_udp" }
    
    if ($wireguardTechnology) {
        # Assuming the first metadata entry contains the public key
        $publicKey = $wireguardTechnology.metadata | Where-Object { $_.name -eq 'public_key' } | Select-Object -ExpandProperty value

        if ($publicKey) {
            @($hostname, $station, $publicKey) | Out-File -FilePath Peer.txt
        } else {
            Write-Host "No publicKey found for Wireguard server."
            exit 1
        }
    } else {
        Write-Host "No Wireguard servers available."
        exit 1
    }
} else {
    Write-Host "Failed to retrieve server recommendations."
    exit 1
}

# Disconnect from NordVPN
nordvpn d > $null 2>&1

# Preparing the Peer section
if (Test-Path -Path Peer.txt -PathType Leaf) {
    $endpoint = (Get-Content -Path Peer.txt -TotalCount 1).Trim()
    $publicKey = (Get-Content -Path Peer.txt | Select-Object -Skip 2 -First 1).Trim()

    if (-not $endpoint -or -not $publicKey) {
        Write-Host "Failed to parse Peer information."
        exit 1
    }
} else {
    Write-Host "Peer information file not found."
    exit 1
}

Remove-Item Peer.txt

"[Peer]" | Add-Content -Path Nordvpn.conf
"PublicKey = $publicKey" | Add-Content -Path Nordvpn.conf
"AllowedIPs = 0.0.0.0/0" | Add-Content -Path Nordvpn.conf
"Endpoint = $($endpoint):51820" | Add-Content -Path Nordvpn.conf
"PersistentKeepalive = 25" | Add-Content -Path Nordvpn.conf

# Renaming config file to show the endpoint country id and server number
if ($endpoint) {
    $outputFileName = $endpoint -replace '^[^.]*', 'NordVPN-$&.conf'
    if (Test-Path -Path $outputFileName) {
        Remove-Item -Path $outputFileName
    }
    Rename-Item -Path Nordvpn.conf -NewName "$outputFileName.conf"
} else {
    Write-Host "Failed to set output file name."
    exit 1
}

Write-Host "Wireguard configuration file $outputFileName created successfully!"
exit 0
