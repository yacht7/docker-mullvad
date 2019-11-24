# Containerized Mullvad Client

## Usage
### docker run
```
docker run -d --name=mullvad --cap-add=NET_ADMIN --device=/dev/net/tun -e REGION=ca-qc -e ACCT_NUM=1234+5678+9123+4567 yacht7/mullvad
```

## Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `ACCT_NUM` | | 16-digit account number with `+` as separators (`1234+5678+9123+4567`) |
| `LOG_LEVEL` | `3` | Sets OpenVPN verbosity (`1`-`11`) |
| `REGION` | `us-ga` | One of the Mullvad regions |