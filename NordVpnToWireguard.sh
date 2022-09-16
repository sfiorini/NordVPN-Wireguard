#!/bin/bash

COUNTRY=""
CITY=""
GROUP=""
VERSION="0.1.1"

while [ "$1" != "" ];
do
   case $1 in
    -v | --version )
        echo "Wireguard Config Files for NordVPN v$VERSION"
	exit
        ;;
    -c | --country )
        shift
        if [ -n "$1" ]
           then
             COUNTRY="$1"
        fi
        ;;
    -s | --city )
        shift
        if [ -n "$1" ]
           then
             CITY="$1"
        fi
        ;;
    -g | --group )
        shift
        if [ -n "$1" ]
           then
             GROUP="$1"
        fi
        ;;
    -o | --output )
        shift
        if [ -n "$1" ]
           then
             OUTPUT_FILE="$1"
        fi
        ;;
    -h | --help )
         echo "Usage: NordVpnToWireguard [OPTIONS]"
         echo "OPTION includes:"
         echo "   -v | --version  - prints out version information."
	 echo "   -c | --country  - Country to connect to (ex. Canada). If option is not provided, NordVPN will get a wireguard configuration for the recommended country, unless a valid city name is provided."
	 echo "   -s | --city - City to connect to (ex. Toronto). When country option is provided, NordVPN will look for the the city within the country and return the fastest server. If no country is provided, NordVPN will look up the fastest server for a city matching the name."
         echo "   -g | --group  - Group to connect to (ex. P2P)"
         echo "   -o | --output  - Config file to output to (ex. wg0.conf). If option is not provided, will output config name based on server chosen."
         echo "   -h | --help     - displays this message."
         exit
      ;;
    * )
         echo "Invalid option: $1"
         echo "Usage: NordVpnToWireguard [-v] [-c country] [-s server]"
         echo "   -v | --version   - prints out version information."
         echo "   -c | --country   - country name"
         echo "   -s | --city      - city name"
         echo "   -g | --group     - group name"
         echo "   -h | --help      - displays this message."
        exit
      ;;
  esac
  shift
done

if [[ -z "$COUNTRY" ]] && [[ -z "$CITY" ]]
then
	if [[ -z "$GROUP" ]]
	then
		echo "Getting configuration for recommended server..."
	else
                echo "Getting configuration for recommended server with group $GROUP ..."
	fi
else
	if [[ -z "$CITY" ]] && [[ ! -z "$COUNTRY" ]]
	then
                if [[ -z "$GROUP" ]]
                then
        		echo "Getting configuration for recommended server in $COUNTRY"
                else
                        echo "Getting configuration for recommended server in $COUNTRY with group $GROUP"
                fi
	fi

	if [[ ! -z "$CITY" ]] && [[ -z "$COUNTRY" ]]
	then
                if [[ -z "$GROUP" ]]
                then
	      		echo "Getting configuration for recommended server in $CITY"
		else
                        echo "Getting configuration for recommended server in $CITY with group $GROUP"
		fi
	fi

	if [[ ! -z "$CITY" ]] && [[ ! -z "$COUNTRY" ]]
        then
                if [[ -z "$GROUP" ]]
                then
                	echo "Getting configuration for recommended server in $COUNTRY, city: $CITY"
		else
                	echo "Getting configuration for recommended server in $COUNTRY, city: $CITY with group $GROUP"
		fi
        fi
fi

TMP_DIR=`mktemp -d -u -t "$(basename "$0").XXXXXXXXXX"`
mkdir -p "$TMP_DIR"
trap 'rm -Rf "$TMP_DIR"' EXIT

# Connect to NordVPN
if [[ -z "$GROUP" ]]
then
	nordvpn c $COUNTRY $CITY > /dev/null 2>&1
else
	if [[ -z "$COUNTRY" ]] && [[ -z "$CITY" ]]
	then
		nordvpn c $GROUP
	else
	        nordvpn c --group $GROUP $COUNTRY $CITY > /dev/null 2>&1
	fi
fi

if [ $? -ne 0 ]
then
	echo "Unable to connect to NordVPN."
	exit 1
fi

# Preparing the Interface section
echo "[Interface]" > "$TMP_DIR/Nordvpn.conf"
privateKey=`sudo wg show nordlynx private-key`
echo "PrivateKey = $privateKey" >> "$TMP_DIR/Nordvpn.conf"
echo "ListenPort = 51820" >> "$TMP_DIR/Nordvpn.conf"
localAddress=`ifconfig nordlynx | grep inet |  awk -v OFS='\n' '{ print $2 }'`
echo "Address = $localAddress/32" >> "$TMP_DIR/Nordvpn.conf"
echo "DNS = 103.86.96.100, 103.86.99.100" >> "$TMP_DIR/Nordvpn.conf"
echo "" >> "$TMP_DIR/Nordvpn.conf"

# Gathering info for the Peer section
curl -s "https://api.nordvpn.com/v1/servers/recommendations?&filters\[servers_technologies\]\[identifier\]=wireguard_udp&limit=1"|jq -r '.[]|.hostname, .station, (.locations|.[]|.country|.city.name), (.locations|.[]|.country|.name), (.technologies|.[].metadata|.[].value), .load' >> "$TMP_DIR/Peer.txt"

# Disconnect from NordVPN
nordvpn d > /dev/null 2>&1

# Preparing the Peer section
endpoint=`grep -m 1 -o '.*' "$TMP_DIR/Peer.txt" | tail -n 1`
publicKey=`grep -m 5 -o '.*' "$TMP_DIR/Peer.txt" | tail -n 1`

rm -f "$TMP_DIR/Peer.txt"

echo "[Peer]" >> "$TMP_DIR/Nordvpn.conf"
echo "PublicKey = $publicKey" >> "$TMP_DIR/Nordvpn.conf"
echo "AllowedIPs = 0.0.0.0/0" >> "$TMP_DIR/Nordvpn.conf"
echo "Endpoint = $endpoint:51820" >> "$TMP_DIR/Nordvpn.conf"
echo "PersistentKeepalive = 25" >> "$TMP_DIR/Nordvpn.conf"

# Renaming config file to show the endpoint country id and server number
if [[ -z "$OUTPUT_FILE" ]]
then
	outputFileName=`echo "$endpoint" |  grep -o '^[^.]*'`
	outputFileName=`echo "NordVPN-$outputFileName.conf"`
else
	outputFileName="$OUTPUT_FILE"
fi

mv "$TMP_DIR/Nordvpn.conf" "$outputFileName"

echo "Wireguard configuration file $outputFileName created successfully!"
exit 0
