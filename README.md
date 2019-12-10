# Mullvad Client for Docker
[![Docker Pulls](https://img.shields.io/docker/pulls/yacht7/mullvad?style=flat-square)](https://hub.docker.com/r/yacht7/mullvad)
[![Mullvad VPN](https://mullvad.net/media/press/MullvadVPN_logo_Round_RGB_Color_positive.png)](https://mullvad.net)

## Start
### docker run
```
docker run -d \
  --name=mullvad \
  --cap-add=NET_ADMIN \
  --device=/dev/net/tun \
  -e ACCT_NUM=0123+4567+8901+2345 \
  yacht7/mullvad
```

### docker-compose
```
version: '2'

services:
    mullvad:
        image: yacht7/mullvad
        container_name: mullvad
        cap_add:
            - NET_ADMIN
        devices:
            - /dev/net/tun
        environment:
            - ACCT_NUM=0123+4567+8901+2345
        restart: unless-stopped
```

### Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `ACCT_NUM` | | 16-digit account number with `+` as separators (`1234+5678+9123+4567`) |
| `LOG_LEVEL` | `3` | Sets OpenVPN verbosity (`1`-`11`) |
| `REGION` | `us-ga` | One of the Mullvad regions (see list of [region codes](region_codes) as of 2019/11/24) |
| `SUBNETS` | `192.168.0.0/24` | A comma-separated (no whitespaces) list of LAN subnets (e.g. `192.168.0.0/24,192.168.1.0/24`) |

#### Region
The expected value for this variable is the region code that is used in the filenames of the OpenVPN configuration files. For example, if you download the zip bundle of config files from [here](https://mullvad.net/en/download/config/?platform=linux) and take a look at the filename, you'll see something like `mullvad_xx.conf` or `mullvad_xx-xxx.conf`. The value you're looking for is the `xx` or `xx-xxx` string.

## Running
### Verifying functionality
Once you have container running `yacht7/mullvad`, run the following command to spin up a temporary container using `mullvad` for networking. The `wget -qO - ifconfig.me` bit will return the public IP of the container (and anything else using `mullvad` for networking). You should see a Mullvad IP address.
```
docker run --rm -it --network=container:mullvad alpine wget -qO - ifconfig.me
```

### Port forwarding
Port forwarding is handled outside of this image. You'll want to add ports in the [Mullvad account page](https://mullvad.net/en/account/ports/). Just click to add ports, and they will automatically be forwarded to your container when it connects.
