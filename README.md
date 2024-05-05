# NordVPN to Wireguard Configuration Generator

This tool is a bash script for generating a Wireguard configuration file for a NordVPN connection.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
  - [Cloning the Project](#cloning-the-project)
  - [Requirements and Dependencies](#requirements-and-dependencies)
- [NordVPN Account Login](#nordvpn-account-login)
- [Protocol Change to NordLynx](#protocol-change-to-nordlynx)
- [Generating the Wireguard Configuration Files](#generating-the-wireguard-configuration-files)
- [Importing the Wireguard Configuration Files](#importing-the-wireguard-configuration-files)

> Note: This guide assumes the use of Ubuntu for Linux and Windows 11 for Windows. A similar install procedure will work on other distributions/versions.

## Overview

This guide provides instructions on how to generate a Wireguard configuration file for a NordVPN connection.

## Installation

### Cloning the Project

Clone this project to have the script on your target Ubuntu system.

### Requirements and Dependencies

#### Linux

* curl
* jq
* net-tools
* wireguard
* nordvpn

You may install the required packages by running the following command:

```bash
sudo apt install wireguard curl jq net-tools
```

And then, the NordVPN client, with the command below following the onscreen instructions:

```bash
sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
```

#### Windows

* Powershell 7.x
* WireGuard
* NordVPN Client

You may install the latest version by downloading the package from [PowerShell/powershell](https://github.com/PowerShell/powershell/releases) releases, or if you prefer `winget`:

```pwsh
winget install --id Microsoft.Powershell --source winget
```
You can get more information about the above command from Microsoft's documentation [here](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows).

For Wireguard, simply go to the [official page](https://www.wireguard.com/install/) and download and install the package for Windows.
If you prefer to install it by a different method, simply ensure that `wg.exe` is in your `PATH`. The usual installation path is `C:\Program Files\WireGuard\wg.exe`.

For the NordVPN client, simply follow the [official download page instructions](https://nordvpn.com/download/windows/).

## NordVPN Account Login

**If you're on Windows, please ensure `nordvpn` is in your `PATH` before proceeding, or adjust accordingly.**

The login procedure will differ based on whether you have MFA enabled:

1. MFA is **ENABLED**:

   ```bash
   nordvpn login
   ```

  This will return a URL link.
  Open the link on any browser, on any machine and perform the login.
  Cancel out of the `Open with` popup, and copy the link that is assigned to the `Continue` link, under the message saying `You've successfully logged in`.

  Back to the terminal

  ```bash
  nordvpn login --callback "<The link you copied>"
  ```

  And it will log you in.

2. MFA is **NOT ENABLED**:

   Use `legacy` username and password to login.

   > Note: This will NOT work if you have `Multi Factor Authentication` enabled. (See above for the `MFA` method)

  ```bash
  nordvpn login --legacy​
  ```

If you have Multi Factor Authentication enabled, this will not work. Refer to the MFA method mentioned above.

## Protocol Change to NordLynx

Set NordVPN to use the NordLynx protocol after successful login by using the following command:

#### Linux
```bash
sudo nordvpn set technology nordlynx
```

#### Windows (Elevated)
```pwsh
nordvpn set technology nordlynx
```

## Generating the [Wireguard](https://www.wireguard.com) Configuration Files

For Linux, it is quite simple and can be run without parameters to generate a config file for the recommended server:

#### Linux
```bash
$ ./NordVpnToWireguard.sh
Getting configuration for recommended server...
Wireguard configuration file NordVPN-us1234.conf created successfully!
```

Generating the configuration on Windows requires the NordVPN Desktop app to be executed. The default behavior would be the same as "Quick Connect".
The Windows NordVPN desktop application does not offer a rich interface that lets you connect directly from CLI to a server like it does on Linux.

It allows you to request for specific parameters, but connection itself has to be established through the GUI.

#### Windows
```pwsh
PS > .\NordVpnToWireguard.ps1
Relaunching script with administrator rights... - -NoExit -File ".\NordVpnToWireguard.ps1"
Getting configuration for recommended server...
Checking for NordLynx interface... Attempt 1 of 12
Checking for NordLynx interface... Attempt 2 of 12
Checking for NordLynx interface... Attempt 3 of 12
Checking internet conectivity...
Attempt failed: Unable to confirm internet connectivity. Retrying in 5 seconds...
Attempt failed: Unable to confirm internet connectivity. Retrying in 5 seconds...
Attempt failed: Unable to confirm internet connectivity. Retrying in 5 seconds...
Attempt failed: Unable to confirm internet connectivity. Retrying in 5 seconds...
Attempt failed: Unable to confirm internet connectivity. Retrying in 5 seconds...
Internet connectivity confirmed.
Wireguard configuration file NordVPN-us9388.conf.nordvpn.com created successfully!
```
Note: If you notice that after the NordVPN desktop app loads, it doesn't automatically connect, you may manually attempt to establish the connection through the GUI.
Sometimes the application will stand by and not connect as expected on Windows. It is bit wonky.


You may also explore some alternative options with parameters. Here are some examples:

#### Linux
- For a specific country: `./NordVpnToWireguard.sh --country Canada`
- For a specific city: `./NordVpnToWireguard.sh --city Berlin`
- For a specific country and city: `./NordVpnToWireguard.sh --country Japan --city Tokyo`
- For help: `./NordVpnToWireguard.sh --help`

#### Windows
- For a specific country: `.\NordVpnToWireguard.ps1 -Country "United_States"`
- For a specific country and server: `.\NordVpnToWireguard.ps1 -Country "United_States" -Id "9388"`
- For help: `.\NordVpnToWireguard.ps1 -Help`

## Importing the [Wireguard](https://www.wireguard.com) Configuration Files

With the [Wireguard](https://www.wireguard.com) client on any platform, import and activate the VPN with the generated files.
