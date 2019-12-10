#!/bin/sh

echo -e "
                   _     _  _____ 
  _   _  __ _  ___| |__ | ||___  |
 | | | |/ _\` |/ __| '_ \| __| / / 
 | |_| | (_| | (__| | | | |_ / /  
  \__, |\__,_|\___|_| |_|\__/_/   
  |___/
"
echo -e "Running setup.sh\n"

# All environment variable checking in one step is not straightforward.
# $ACCT_NUM - simple - string whose format is constant
# $LOG_LEVEL - simple - integer from 1-11 
# $REGION - challenging - string whose value must be an existing Mullvad VPN endpoint
#     Note: Since $REGION must exist on Mullvad's side, this check has to be done after
#     pulling the OpenVPN configuration zip bundle from Mullvad using $ACCT_NUM.

echo "Checking account number format"
# Make sure ACCT_NUM is in the format of 0123+4567+8901+2345
if ! $(echo $ACCT_NUM | grep -Eq '\d{4}\+\d{4}\+\d{4}\+\d{4}'); then
    >&2 echo "[ERROR] Account number \"$ACCT_NUM\" is not formatted correctly."
    exit 1
fi
echo -e "[INFO] Account number is formatted correctly\n"

echo "Pulling zip bundle from Mullvad"
response=$(curl -si --compressed 'https://mullvad.net/en/account/login/')

csrftoken=$(echo $response | grep -o 'csrftoken=\w*' \
        | cut -d '=' -f 2)
csrfmiddlewaretoken=$(echo $response | grep -o 'name=\"csrfmiddlewaretoken\" value=\"\w*\"' \
        | cut -d ' ' -f 2 \
        | cut -d '=' -f 2 \
        | sed 's/"//g')
sessionid=$(curl -si --compressed \
        -H "Cookie: csrftoken=$csrftoken" \
        -d "csrfmiddlewaretoken=${csrfmiddlewaretoken}&next=%2Fen%2Faccount%2Flogin%2F&account_number=${ACCT_NUM}" \
        'https://mullvad.net/en/account/login/' | grep -o 'sessionid=\w*' | cut -d '=' -f 2)

curl -s --compressed -o /data/configs.zip \
    -H "Cookie: csrftoken=$csrftoken; sessionid=$sessionid" \
    -d "csrfmiddlewaretoken=${csrfmiddlewaretoken}&platform=linux&region=all&port=0" \
    'https://mullvad.net/en/download/config/?platform=linux'

mkdir -p /data/mullvad
unzip -jq /data/configs.zip -d /data/mullvad 
rm /data/configs.zip
echo -e "[INFO] Zip bundle pulled and extracted\n"


echo "Making sure desired region exists"
for file in /data/mullvad/*.conf; do
    echo ${file%.*} | cut -d '_' -f 2 >> /data/region_codes
done

if ! grep -q $REGION /data/region_codes; then
    echo "[ERROR] Region code \"$REGION\" is invalid. Please choose one from the following list:
    $(cat /data/region_codes)"
    exit 1
fi
echo -e "[INFO] Desired region exists\n"

echo "Making required changes to the config file"
sed -i \
    -e '/up /c up \/etc\/openvpn\/up.sh' \
    -e '/down /c down \/etc\/openvpn\/down.sh' \
    -e 's/proto udp/proto udp4/' \
    -e 's/proto tcp/proto tcp4/' \
    /data/mullvad/mullvad_${REGION}.conf

echo 'pull-filter ignore "route-ipv6"' >> /data/mullvad/mullvad_${REGION}.conf
echo 'pull-filter ignore "ifconfig-ipv6"' >> /data/mullvad/mullvad_${REGION}.conf

cp \
    /data/mullvad/mullvad_ca.crt \
    /data/mullvad/mullvad_userpass.txt \
    /data/mullvad/mullvad_${REGION}.conf \
    /etc/openvpn

echo -e "[INFO] Required changes made and files are moved into place\n"

################################################################################

echo "Creating iptables ruleset and configuring routes"

# https://mullvad.net/en/help/linux-openvpn-installation/
# Enabling a kill switch section (slightly modified)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

for subnet in ${SUBNETS//,/ }; do
    ip route add $subnet via $(ip r | grep 'default via' | cut -d " " -f 3) dev eth0
    iptables -A INPUT -s $subnet -j ACCEPT
    iptables -A OUTPUT -d $subnet -j ACCEPT
done

iptables -A OUTPUT ! -d 193.138.218.74 -p tcp --dport 53 -j DROP

iptables -A INPUT -i tun+ -j ACCEPT
iptables -A OUTPUT -o tun+ -j ACCEPT

# for list of ports see the following link:
# https://mullvad.net/en/help/tag/connectivity/#39
domain=$(grep -o "${REGION}.mullvad.net" /etc/openvpn/mullvad_${REGION}.conf)
for ip in $(nslookup $domain localhost | tail -n +4 | grep -Eo '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort | uniq); do
    iptables -A OUTPUT -o eth+ -d $ip -p tcp -m multiport --dports 80,443,1401 -j ACCEPT
    iptables -A OUTPUT -o eth+ -d $ip -p udp -m multiport --dports 53,1194:1197,1300:1303,1400 -j ACCEPT
done

echo -e "[INFO] iptables rules created and routes configured\n"

################################################################################

sleep 5

echo "[INFO] Running openvpn with desired config"
cd /etc/openvpn

if ! $(echo $LOG_LEVEL | grep -Eq '^([1-9]|1[0-1])$'); then
    printf "[WARN] Invalid log level $LOG_LEVEL. Setting to default."
    LOG_LEVEL=3
fi

openvpn --verb $LOG_LEVEL --config mullvad_${REGION}.conf
