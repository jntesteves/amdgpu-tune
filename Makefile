# SPDX-License-Identifier: Unlicense
timer_unit := amdgpu-tune@apply.timer
unit_files := amdgpu-tune@.service $(timer_unit)
ifdef PREFIX
install_prefix := $(PREFIX)
else
install_prefix := /etc/systemd/system
endif

.PHONY: install
install:
	install -DZ -m 644 -t $(install_prefix) $(unit_files)
	systemctl daemon-reload

.PHONY: uninstall
uninstall:
	-systemctl disable --now $(timer_unit)
	-rm -f $(addprefix $(install_prefix)/,$(unit_files))
