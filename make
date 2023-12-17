#!/usr/bin/env sh
# SPDX-License-Identifier: Unlicense
# shellcheck disable=SC2046,SC2086
. ./dot-slash-make.sh

param PREFIX=/etc/systemd/system
timer_unit=amdgpu-tune@apply.timer
unit_files="amdgpu-tune@.service ${timer_unit}"
selinux_flag=-Z
case $(install -Z 2>&1) in *'unrecognized option'*) selinux_flag='' ;; esac
script_files=$(wildcard ./*.sh ./make)

for __target in ${__dsm__targets}; do
	case "${__target}" in
	install)
		run install -D ${selinux_flag} -m 644 -t "$PREFIX" $unit_files
		run systemctl daemon-reload
		;;
	uninstall)
		run_ systemctl disable --now "$timer_unit"
		run_ rm -f $(printf "${PREFIX}/%s " $unit_files)
		;;
	lint)
		run shellcheck ${script_files}
		run shfmt -p -d ${script_files}
		;;
	format)
		run shfmt -p -w ${script_files}
		;;
	# dot-slash-make: This * case must be last and should not be changed
	*) abort "No rule to make target '${__target}'" ;;
	esac
done
