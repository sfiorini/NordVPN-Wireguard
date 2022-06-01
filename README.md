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
```
But any options supplied to the script will be supplied directly to nordvpn connect, and will allow you to select the type of server, etc.

Requesting a specific country:

```bash
$ ./NordVpnToWireguard.sh Canada
```

Requesting a specific country and city

```bash
$ ./NordVpnToWireguard.sh Hungary Budapest
```

Requesting a specific server type

```bash
$ ./NordVpnToWireguard.sh Onion_Over_VPN
```

Getting help:

```bash
$ nordvpn connect --help
nordvpn connect
Usage: nordvpn connect [command options] [country]/[server]/[country_code]/[city]/[group] or [country] [city]

Use this command to connect to NordVPN. Adding no arguments to the command will connect you to the recommended server.
Provide a [country] argument to connect to a specific country. For example: 'nordvpn connect Australia'
Provide a [server] argument to connecto to a specific server. For example: 'nordvpn connect jp35'
Provide a [country_code] argument to connect to a specific country. For example: 'nordvpn connect us'
Provide a [city] argument to connect to a specific city. For example: 'nordvpn connect Hungary Budapest'
Provide a [group] argument to connect to a specific servers group. For example: 'nordvpn connect Onion_Over_VPN'
```

## Use the generated [Wireguard](https://www.wireguard.com) configuration files

Import the file/s with the  [Wireguard](https://www.wireguard.com) client in any platform and activate the `VPN`.
Or run `sudo wg-quick up ./wg0.conf`
