# Mullvad Client for Docker
[![Mullvad VPN](https://mullvad.net/media/press/MullvadVPN_logo_Round_RGB_Color_positive.png)](https://mullvad.net)

[![Docker Pulls](https://img.shields.io/docker/pulls/yacht7/mullvad?style=flat-square)](https://hub.docker.com/r/yacht7/mullvad)

## Usage
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

## Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `ACCT_NUM` | | 16-digit account number with `+` as separators (`1234+5678+9123+4567`) |
| `LOG_LEVEL` | `3` | Sets OpenVPN verbosity (`1`-`11`) |
| `REGION` | `us-ga` | One of the Mullvad regions (see list of [region codes](region_codes) as of 2019/11/24) |

### Region
The expected value for this variable is the region code that is used in the filenames of the OpenVPN configuration files. For example, if you download the zip bundle of config files from [here](https://mullvad.net/en/download/config/?platform=linux) and take a look at the filename, you'll see something like `mullvad_xx.conf` or `mullvad_xx-xxx.conf`. The value you're looking for is the `xx` or `xx-xxx` string.
