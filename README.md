# amdgpu-tune

A simple systemd service unit to tune the performance of AMD GPU, and optionally apply automatically on boot.

## Prerequisites

This software only supports recent AMD GPUs using the `amdgpu` kernel driver. It is tested on RDNA2/RX 6000 series — tested on the Asus ROG Strix G15 (2021) laptop, RX 6800M.

You must append the boot parameter `amdgpu.ppfeaturemask=0xffffffff` to the kernel command in the bootloader. How to do that varies per Linux distribution. Check your OS' documentation.

## Installation and usage

Edit the environment variables in the [amdgpu-tune.service](amdgpu-tune.service) file to tune the settings. Then you can install the service to the `/etc/systemd/system` folder:

```shell
# Install using make
sudo make install

# If you don't have make, you can use this command instead
sudo install -DZ -m 644 -t /etc/systemd/system amdgpu-tune.service && sudo systemctl daemon-reload
```

Starting the service applies the configuration. Stopping the service resets the configuration back to defaults.

To start/stop the service:
```shell
sudo systemctl start amdgpu-tune.service

sudo systemctl stop amdgpu-tune.service
```

You can keep tuning the configuration by just editing the file at `/etc/systemd/system/amdgpu-tune.service`. After making changes, you have to reload and restart the service to apply the new settings:
```shell
sudo systemctl daemon-reload && sudo systemctl restart amdgpu-tune.service
```

After you have tuned the settings to your liking — and found a **stable** configuration! — you can optionally enable the service to have your settings always applied automatically on boot:
```shell
sudo systemctl enable amdgpu-tune.service
```

## Uninstall

```shell
sudo make uninstall

# If you don't have make, you can use this command instead
sudo systemctl disable --now amdgpu-tune.service && sudo rm -f /etc/systemd/system/amdgpu-tune.service
```

## License
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

See [UNLICENSE](UNLICENSE) file or http://unlicense.org/ for details.
