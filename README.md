# ethtool-tunables (OpenWrt)

Apply `ethtool`/`ip` tunables at boot (coldplug) **after static device renames** and **before netifd**, and on **net hotplug** events.
The runtime config namespace is **`ethtool_tunables`** (underscore), aligning with OpenWrt UCI naming conventions.

## Boot / hotplug ordering

**Init script** (rc.common):
- `START=12` so it runs after optional `static-device-names` (`START=11`) and before `network` (netifd, `START=20`).

**Hotplug** (`/etc/hotplug.d/net/00-01-ethtool_tunables`):
- Priority **`00-01`** ensures:
  1. `00-00-static-name-devices` (if installed/enabled) finishes renaming the interface to its **final name**.
  2. **`00-01-ethtool_tunables`** applies driver/IP tunables _to that final name_ via `init` reload.
  3. `00-netifd` runs after, seeing the tuned interface.

Hotplug events we care about are `SUBSYSTEM=net` and `ACTION=add`. OpenWrt exposes the up-to-date **`DEVICENAME`** for physical devices; that is what the init `reload` consumes.

## Enabling hotplug in UCI

Add the `globals.hotplug` flag to `/etc/config/ethtool_tunables`:

```uci
config globals 'globals'
    option hotplug '1'   # 1=enable, 0=disable
```

With hotplug enabled, the helper will call:
```sh
DEVICENAME="$DEVICENAME" HOTPLUG=1 /etc/init.d/ethtool_tunables reload
```
This targets only the matching device section (by `option ifname`, or by section name when the section is **named**).

## Example config

> You said you'll add your own example; leaving this section intentionally brief.

```uci
config device 'eth1'
    list offload 'sg on'
    list ring 'rx 4096'
    option txqueuelen '10000'
```

- Keys under `offload/channels/ring/coalesce/pause/priv` may use `_` in UCI; the script translates to `-` for `ethtool`.
- `priv` keys are canonicalized to the driver’s exact labels.
- `mtu` and `txqueuelen` are applied via `ip link` unless already declared _natively_ in `/etc/config/network` device sections.

## Files & layout

This repo intentionally ships only a **skeleton**. You will drop the scripts and default config yourself.

```
files/
└── etc
    ├── config/
    │   └── ethtool_tunables            # (you add this)
    ├── hotplug.d/
    │   └── net/
    │       └── 00-01-ethtool_tunables  # (you add this)
    └── init.d/
        └── ethtool_tunables            # (you add this)
README.md
Makefile
```

## Packaging (OpenWrt `.ipk`)

1. Place your init script, hotplug helper, and default config under `files/` as shown above.
2. Inside an OpenWrt SDK or full tree:
   ```sh
   ./scripts/feeds update -a && ./scripts/feeds install -a   # if needed
   make package/ethtool-tunables/compile V=sc
   ```
3. The resulting `.ipk` will include your files plus this README under `/usr/share/doc/ethtool-tunables/`.

## Notes

- BusyBox `awk`/`sed`/`grep` are supported; the scripts avoid GNU-only features.
- The package name uses a **hyphen** (`ethtool-tunables`) while the UCI namespace and file names use an **underscore** (`ethtool_tunables`).

## Future work (procd branch)

A `procd`-native flavor (with `procd_add_reload_trigger`/`procd_set_param respawn` etc.) can live on a separate branch without changing the UCI namespace or hotplug ordering.
