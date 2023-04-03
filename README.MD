# [Wireguard](https://www.wireguard.com) configuration file generator for a [NordVPN](https://nordvpn.com)

A `bash` scripts that generates [Wireguard](https://www.wireguard.com) configuration file for a [NordVPN](https://nordvpn.com) connection.

## INSTALL

This guide assumes the use of [Ubuntu](https://ubuntu.com). A similar install procedure will work on other distros.

### Clone this project

First let's clone this project so that you'll have the script on your target [Ubuntu](https://ubuntu.com) system.

### Install required packages

```bash
sudo apt install wireguard curl jq net-tools
```

### Install [NordVPN](https://nordvpn.com) client

Execute the following command and follow the on screen instructions:

```bash
sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
```

## Login to your [NordVPN](https://nordvpn.com) account

The procedure differs if you have `MFA` enabled on your account:

1. `MFA` is ENABLED on your account

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

2. `MFA` is NOT ENABLED on your account

   Use `legacy` username and password to login.

   > Note: This will NOT work if you have `Multi Factor Authentication` enabled. (See above for the `MFA` method)

   ```bash
   nordvpn login --legacy​
   ```

## Change protocol to NordLynx

After a successful login, please set [NordVPN](https://nordvpn.com) to use `NordLynx` protocol.

```bash
sudo nordvpn set technology nordlynx
```

## Generate [Wireguard](https://www.wireguard.com) configuration files

The script is quite simple and can be run without parameters to generate a config file for the recommended server:

```bash
$ ./NordVpnToWireguard.sh
Getting configuration for recommended server...
Wireguard configuration file NordVPN-us1234.conf created successfully!
```

Requesting a specific country:

```bash
$ ./NordVpnToWireguard.sh --country Canada
Getting configuration for recommended server in Canada
Wireguard configuration file NordVPN-ca1234.conf created successfully!
```

Requesting a specific city

```bash
$ ./NordVpnToWireguard.sh --city Berlin
Getting configuration for recommended server in Berlin
Wireguard configuration file NordVPN-de1234.conf created successfully!
```

Requesting a specific country and city

```bash
$ ./NordVpnToWireguard.sh --country Japan --city Tokyo
Getting configuration for recommended server in Japan, city: Tokyo
Wireguard configuration file NordVPN-jp1234.conf created successfully!
```

Getting help:

```bash
$ ./NordVpnToWireguard.sh --help
Usage: NordVpnToWireguard [OPTIONS]
OPTION includes:
   -v | --version  - prints out version information.
   -c | --country  - Country to connect to (ex. Canada). If option is not provided, NordVPN will get a wireguard configuration for the recommended country, unless a valid city name is provided.
   -s | --city - City to connect to (ex. Toronto). When country option is provided, NordVPN will look for the the city within the country and return the fastest server. If no country is provided, NordVPN will look up the fastest server for a city matching the name.
   -h | --help     - displays this message.
```

## Use the generated [Wireguard](https://www.wireguard.com) configuration files

Import the file/s with the  [Wireguard](https://www.wireguard.com) client in any platform and activate the `VPN`.
