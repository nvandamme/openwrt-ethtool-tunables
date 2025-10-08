# ethtool_tunables init service (OpenWrt)

Apply `ethtool`/`ip` tunables at boot (coldplug) **after static device renames** and **before netifd**, and on **net hotplug** events.

## Init script

The init script [`/etc/init.d/ethtool_tunables`](https://github.com/nvandamme/openwrt-ethtool-tunables/blob/main/etc/init.d/ethtool_tunables) supports the standard `start`, `stop`, `reload`, and `enable`/`disable` actions.

Additional actions:

- `status` shows the current applied settings for all configured devices.
- `status_json` shows the current applied settings in JSON format (for scripting).
- `check` validates the config without applying it (returns non-zero on error).
- `debug` show the config and the current state of each device.

- `START=12` so it runs after optional `static-device-names` (`START=11`) and before `network` (netifd, `START=20`).

## Hotplug

The hotplug `net` helper is located at [`/etc/hotplug.d/net/00-01-ethtool_tunables`](https://github.com/nvandamme/openwrt-ethtool-tunables/blob/main/etc/hotplug.d/net/00-01-ethtool_tunables).

### Enabling

Add the `globals.hotplug` flag to [`/etc/config/ethtool_tunables`](https://github.com/nvandamme/openwrt-ethtool-tunables/blob/main/etc/config/ethtool_tunables):

```uci
config globals 'globals'
    option hotplug '1'   # 1=enable, 0=disable
```

or use `uci set ethtool_tunables.globals.hotplug=1 && uci commit ethtool_tunables`.

- Priority **`00-01`** ensures that it'll run before `netifd`.
- The script checks for the `globals.hotplug` flag on each invocation, so you can toggle it at runtime.

### Behavior

With hotplug enabled, on each interface `add` event, the helper will call:

```sh
DEVICENAME="$DEVICENAME" HOTPLUG=1 /etc/init.d/ethtool_tunables reload
```

This targets only the matching device _anonymous_ section (by `option ifname`, or by section name when the section is **named**).

## Example config

> [!TIP]
> A more complete example is in [`/etc/config/ethtool_tunables`](https://github.com/nvandamme/openwrt-ethtool-tunables/blob/main/etc/config/ethtool_tunables) in this repo.

```uci
config device 'eth1'
    list offload 'sg on'
    list ring 'rx 4096'
    option txqueuelen '10000'
```

### Available options

- Section names (e.g. `device 'eth1'`) can be the device name (e.g. `eth0`, `wlan0`), or an arbitrary name (e.g. `device 'lan'`) with `option ifname 'eth0'` to target the device.
- If `option ifname` is omitted, the section name is used as the device name.
- The special section `config globals 'globals'` can hold global settings like `option hotplug '1'` (see above).
- Supported keys are: `offload`, `channels`, `ring`, `coalesce`, `pause`, `priv`, `mtu`, and `txqueuelen`.
- `offload`, `channels`, `ring`, `coalesce`, and `pause` keys are passed to `ethtool -K`, `-L`, `-G`, `-C`, and `-A` respectively; refer to [`ethtool`](https://man7.org/linux/man-pages/man8/ethtool.8.html) documentation for valid values.
- `priv` keys are canonicalized to the driver’s exact labels if available (e.g. `RxChecksum` -> `rx-checksum`) and passed to `ethtool --set-priv-flags`; refer to `ethtool --show-priv-flags <dev>` for valid values as they vary by driver.
- `mtu` and `txqueuelen` are applied via `ip link` unless already declared _natively_ in `/etc/config/network` device sections (and handled by netifd), in which case they are skipped to avoid conflicts; refer to [`ip`](https://man7.org/linux/man-pages/man8/ip.8.html) documentation for valid values.

> [!IMPORTANT]
>
> - Keys under `offload | channels | ring | coalesce | pause | priv` must use `_` in UCI; the script translates to `-` for `ethtool` and can be space-separated lists or repeated list items (e.g. `list offload 'sg on'` or `list offload 'sg on' 'tso on'`).
> - `channels | ring | priv | mtu` will flap the interface down and up to apply the settings.

> [!CAUTION]
>
> - The script does **not** validate the values; refer to `ethtool` and `ip` documentation for valid options; it will skip invalid values and log a warning on ethtool | ip errors.
> - It does **not** check if the device exists at config time; it will skip non-existing devices at runtime.
> - It does **not** persist settings across reboots; it applies them at boot and on hotplug events only.
> - It does **not** revert settings on `stop`; it only applies settings on `start` and `reload`.
> - The script only applies to _physical_ devices or _sub-interfaces_ (e.g. `eth0`, `eth0.1`, `wlan0`); it ignores virtual devices (e.g. `br-lan`, `wwan`, `tun0`, `pppoe-wan`).

## Files & layout

```tree
etc
├── config/
│   └── ethtool_tunables            # example config
├── hotplug.d/
│   └── net/
│       └── 00-01-ethtool_tunables  # hotplug helper
└── init.d/
    └── ethtool_tunables            # init service script
usr
└── share/doc/
    └── ethtool-tunables/
        └── README.md
README.md
Makefile
```

## Requirements

- OpenWrt 24.0+
- `ethtool`
- `ip` (iproute2, included in OpenWrt base image, 24+)
- `awk`, `sed`, `grep` (BusyBox versions, included in OpenWrt base image)

## Packaging (OpenWrt `.ipk`)

1. Place your init script, hotplug helper, and default config under the directory structure as shown above.
2. Inside an OpenWrt SDK or full tree:

   ```sh
   ./scripts/feeds update -a && ./scripts/feeds install ethtool_tunables
   make package/ethtool-tunables/compile
   ```

3. The resulting `.ipk` will include your files plus this README under `/usr/share/doc/ethtool-tunables/`.

## Packaging (apk)

TBD

## Manual installation

1. Copy the init script to `/etc/init.d/ethtool_tunables` and make it executable:

   ```sh
   cp ./etc/init.d/ethtool_tunables /etc/init.d/ethtool_tunables
   chmod +x /etc/init.d/ethtool_tunables
   ```

2. Copy the hotplug helper to `/etc/hotplug.d/net/00-01-ethtool_tunables` and make it executable:

   ```sh
   cp ./etc/hotplug.d/net/00-01-ethtool_tunables /etc/hotplug.d/net/00-01-ethtool_tunables
   chmod +x /etc/hotplug.d/net/00-01-ethtool_tunables
   ```

3. Copy the example config to `/etc/config/ethtool_tunables` and edit as needed:

   ```sh
   cp ./etc/config/ethtool_tunables /etc/config/ethtool_tunables
   vi /etc/config/ethtool_tunables
   ```

## Future work

- A `procd`-native flavor (with `procd_add_reload_trigger`/`procd_set_param respawn` etc.) can live on a separate branch without changing the UCI namespace or hotplug ordering.
- A patch for `netifd` to natively support `ethtool`/`ip` tunables in `/etc/config/network` device sections would be ideal.
