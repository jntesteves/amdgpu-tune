# SPDX-License-Identifier: Unlicense
PREFIX := /etc/systemd/system
timer_unit := amdgpu-tune@apply.timer
unit_files := amdgpu-tune@.service $(timer_unit)
ifndef NO_SELINUX
selinux_flag := -Z
endif

.PHONY: install
install:
	install -D $(selinux_flag) -m 644 -t $(PREFIX) $(unit_files)
	systemctl daemon-reload

.PHONY: uninstall
uninstall:
	-systemctl disable --now $(timer_unit)
	-rm -f $(addprefix $(PREFIX)/,$(unit_files))
