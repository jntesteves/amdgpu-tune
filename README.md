# amdgpu-tune

A simple systemd service unit to tune the performance of AMD GPU, and optionally apply automatically on boot.

## Prerequisites

This software only supports recent AMD GPUs using the `amdgpu` kernel driver. It is tested on RDNA2/RX 6000 series — tested on the Asus ROG Strix G15 (2021) laptop, RX 6800M.

You must append the boot parameter `amdgpu.ppfeaturemask=0xffffffff` to the kernel command in the bootloader. How to do that varies per Linux distribution. Check your OS' documentation.

## Installation and usage

Edit the environment variables in the [amdgpu-tune@.service](amdgpu-tune@.service) file to tune the settings. Then you can install the service to the `/etc/systemd/system` folder:

```shell
sudo ./make install
```

Starting the service `amdgpu-tune@apply.service` applies the configuration. Starting the service `amdgpu-tune@reset.service` resets the configuration back to defaults.

```shell
# Apply configuration
sudo systemctl start amdgpu-tune@apply.service

# Reset configuration
sudo systemctl start amdgpu-tune@reset.service
```

You can keep tuning the configuration by just editing the file at `/etc/systemd/system/amdgpu-tune@.service`. After making changes, you have to reload and restart the service to apply the new settings:
```shell
sudo systemctl daemon-reload && sudo systemctl restart amdgpu-tune@apply.service
```

After you have tuned the settings to your liking — and found a **stable** configuration! — you can optionally enable the systemd timer unit to have your settings always applied automatically on boot:
```shell
sudo systemctl enable amdgpu-tune@apply.timer
```

## Uninstall

```shell
sudo ./make uninstall

# Or, without a clone of this repository, you can use these commands instead
sudo systemctl disable --now amdgpu-tune@apply.timer
sudo rm -f /etc/systemd/system/amdgpu-tune@{.service,apply.timer}
```

## License
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

See [UNLICENSE](UNLICENSE) file or http://unlicense.org/ for details.
