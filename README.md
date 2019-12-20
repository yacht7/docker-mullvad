# Mullvad Client for Docker
[![Mullvad VPN](https://mullvad.net/media/press/MullvadVPN_logo_Round_RGB_Color_positive.png)](https://mullvad.net)

## Creating
### `docker run`
```
docker run -d \
  --name=mullvad \
  --cap-add=NET_ADMIN \
  --device=/dev/net/tun \
  -e ACCT_NUM=0123+4567+8901+2345 \
  yacht7/mullvad
```

### `docker-compose`
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
| `FORWARDED_PORTS` | | Port(s) forwarded by [Mullvad](https://mullvad.net/en/account/ports/) (e.g. `12345` or `9876,54321`) |
| `LOG_LEVEL` | `3` | OpenVPN verbosity (`1`-`11`) |
| `REGION` | `us-ga` | One of the Mullvad regions (see list of [region codes](region_codes) as of 2019/11/24) |
| `SUBNETS` | `192.168.0.0/24` | A comma-separated (no whitespaces) list of LAN subnets (e.g. `192.168.0.0/24,192.168.1.0/24`) |

#### `REGION`
The expected value for this variable is the region code that is used in the filenames of the OpenVPN configuration files. For example, if you download the zip bundle of config files from [here](https://mullvad.net/en/download/config/?platform=linux) and take a look at the filename, you'll see something like `mullvad_xx.conf` or `mullvad_xx-xxx.conf`. The value you're looking for is the `xx` or `xx-xxx` string.

#### `SUBNETS`
The subnets specified will have routes created and whitelists added in the firewall for them which allows for connectivity to and from hosts on the subnets. 

## Running
### Verifying functionality
Once you have container running `yacht7/mullvad`, run the following command to spin up a temporary container using `mullvad` for networking. The `wget -qO - ifconfig.me` bit will return the public IP of the container (and anything else using `mullvad` for networking). You should see a Mullvad IP address.
```
docker run --rm -it --network=container:mullvad alpine wget -qO - ifconfig.me
```

### Port forwarding
Just click the button to add port(s) on the [Mullvad account page](https://mullvad.net/en/account/ports/), list them in the environment variable, and they will automatically be forwarded to your container when it connects.

### Using with other containers
Once you have your Mullvad container up and running, you can tell other containers to use `mullvad`'s network stack which gives any container the ability to utilize the VPN tunnel. There are a few ways to accomplish this depending how how your container is created.

If your container is being created with
1. the same Compose YAML file as `mullvad`, add `network_mode: service:mullvad` to the container's service definition.
2. a different Compose YAML file as `mullvad`, add `network_mode: container:mullvad` to the container's service definition.
3. `docker run`, add `--network=container:mullvad` as an option to `docker run`.

Once running and provided your container has `wget` or `curl`, you can run `docker exec <container_name> wget -qO - ifconfig.me` or `docker exec <container_name> curl -s ifconfig.me` to get the public IP of the container and make sure everything is working as expected. This IP should match the one of `mullvad`.
