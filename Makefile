# SPDX-License-Identifier: Unlicense
service_unit := amdgpu-tune.service
ifdef PREFIX
install_prefix := $(PREFIX)
else
install_prefix := /etc/systemd/system
endif

.PHONY: install
install:
	install -DZ -m 644 -t $(install_prefix) $(service_unit)
	systemctl daemon-reload

.PHONY: uninstall
uninstall:
	systemctl disable --now $(service_unit)
	rm -f $(install_prefix)/$(service_unit)
