# SPDX-License-Identifier: Unlicense
# v0.1.0-pre
# shellcheck shell=sh
#
# This file is part of dot-slash-make https://codeberg.org/jntesteves/dot-slash-make
# Do NOT make changes to this file, your commands go in the ./make file
#
log_error() { printf 'ERROR %s\n' "$@" >&2; }
log_warn() { printf 'WARN %s\n' "$@" >&2; }
log_info() { printf '%s\n' "$@"; }
log_debug() { :; } && [ "$MAKE_DEBUG" ] && log_debug() { printf 'DEBUG %s\n' "$@"; }
log_trace() { :; } && case "$MAKE_DEBUG" in *trace*) log_trace() { printf 'TRACE %s\n' "$@"; } ;; esac
abort() {
	log_error "$@"
	exit 1
}

# Get real path to shell interpreter of current process
real_proc_cmdline() (
	if [ -r /proc/$$/cmdline ]; then
		proc_cmdline="$(cut -d '' -f1 /proc/$$/cmdline 2>/dev/null)" || return 1
	else
		proc_cmdline="$(ps -p $$ -o comm= 2>/dev/null)" || return 1
	fi
	# On Alpine Linux the cut command above gives weird result, remove everything from the first blank space to the end
	proc_cmdline="${proc_cmdline%%[[:space:][:cntrl:]]*}"
	# Remove leading "-" added by macOS
	proc_cmdline="${proc_cmdline#-}"
	proc_cmdline="$(command -v "$proc_cmdline" 2>/dev/null)" || return 1
	proc_cmdline="$(realpath "$proc_cmdline" 2>/dev/null)" || return 1
	printf '%s\n' "$proc_cmdline"
)

# Detect if running on a problematic shell, and try to re-exec the script on a better shell
upgrade_to_better_shell() {
	current_shell="$(basename "$(real_proc_cmdline)" 2>/dev/null)"
	case "$current_shell" in
	# If running on dash, re-exec the script on bash if possible (for debian/ubuntu and derivatives)
	# If mksh, re-exec on anything available (mksh performs Field Splitting inconsistently between Parameter Expansion and Command Substitution)
	# If zsh, re-exec on anything available (zsh's sh compatibility mode is woefully incompatible, Field Splitting is unusable)
	dash | mksh | zsh)
		if [ "$current_shell" != bash ] && command -v bash >/dev/null; then
			log_debug "$current_shell detected, upgrading to bash"
			exec bash --posix "$0" "$@"
		elif [ "$current_shell" != busybox ] && command -v busybox >/dev/null; then
			log_debug "$current_shell detected, upgrading to busybox"
			exec busybox "$0" "$@"
		elif [ "$current_shell" != dash ] && command -v dash >/dev/null; then
			log_debug "$current_shell detected, upgrading to dash"
			exec dash "$0" "$@"
		fi
		;;
	esac
}

# Substitute every instance of character in text with replacement string
# This function uses only shell builtins and has no external dependencies (f.e. on sed)
# This is slower than using sed on a big input, but faster on many invocations with small inputs
substitute_character_builtin() (
	set -f # Disable globbing (aka pathname expansion)
	IFS="$1"
	replacement="$2"
	trailing_match=
	case "$3" in *"$1") [ "$ZSH_VERSION" ] || trailing_match="$replacement" ;; esac
	# shellcheck disable=2086
	set -- $3 # Create arguments list splitting at each occurrence of IFS
	i=0
	for field in "$@"; do
		i=$((i + 1))
		if [ "$i" -eq "$#" ]; then
			printf '%s%s' "$field" "$trailing_match"
		else
			printf '%s%s' "$field" "$replacement"
		fi
	done
)

# Escape text for use in a shell script single-quoted string (shell builtin version)
escape_single_quotes_builtin() { substitute_character_builtin \' "'\\''" "$1"; }

# Wrap all arguments in single-quotes and concatenate them
__dsm__quote_eval_cmd() (
	escaped_text=
	for arg in "$@"; do
		escaped_text="${escaped_text} '$(escape_single_quotes_builtin "$arg")'"
	done
	printf '%s\n' "$escaped_text"
)

# Evaluate command in a sub-shell, abort on error
run() {
	log_info "$(printf '%s ' "$@")"
	__dsm__eval_cmd="$(__dsm__quote_eval_cmd "$@")"
	log_trace "dot-slash-make: [run] __dsm__eval_cmd=$__dsm__eval_cmd"
	(eval "$__dsm__eval_cmd") || abort "${__dsm__cmd}: [target: ${__target}] Error ${?}"
}

# Evaluate command in a sub-shell, ignore returned status code
run_() {
	log_info "$(printf '%s ' "$@")"
	__dsm__eval_cmd="$(__dsm__quote_eval_cmd "$@")"
	log_trace "dot-slash-make: [run_] __dsm__eval_cmd=$__dsm__eval_cmd"
	(eval "$__dsm__eval_cmd") || log_info "${__dsm__cmd}: [target: ${__target}] Error ${?} (ignored)"
}

# Validate if text is appropriate for a shell variable name
validate_var_name() {
	case "$1" in
	*[!_a-zA-Z0-9]*) return 1 ;;
	[!_a-zA-Z]*) return 1 ;;
	esac
}

# Check if the given name was provided as an argument in the CLI
__dsm__is_in_cli_parameters_list() (
	var_name="$1"
	log_trace "dot-slash-make: [__dsm__is_in_cli_parameters_list] var_name='${var_name}' __dsm__cli_parameters_list='${__dsm__cli_parameters_list}'"
	for arg in $__dsm__cli_parameters_list; do
		log_trace "dot-slash-make: [__dsm__is_in_cli_parameters_list] loop arg='${arg}'"
		[ "$var_name" = "$arg" ] && return 0
	done
	return 1
)

# Use indirection to dynamically set a variable from argument NAME=VALUE
__dsm__set_variable_cli_override() {
	__dsm__fn_arguments="$2"
	__dsm__var_name="${__dsm__fn_arguments%%=*}"
	__dsm__var_value="${__dsm__fn_arguments#*=}"
	if validate_var_name "$__dsm__var_name"; then
		if [ "$1" ] && __dsm__is_in_cli_parameters_list "$__dsm__var_name"; then
			log_debug "dot-slash-make:${1:+" [$1]"} '$__dsm__var_name' overridden by command line argument"
			return
		fi
		eval "$__dsm__var_name='$(escape_single_quotes_builtin "$__dsm__var_value")'"
		[ "$1" ] || __dsm__cli_parameters_list="${__dsm__cli_parameters_list}${__dsm__var_name} "
		eval "log_debug \"dot-slash-make: [__dsm__set_variable_cli_override] ${__dsm__var_name}=\$${__dsm__var_name}\""
	else
		abort "${__dsm__cmd}:${1:+" [$1]"} Invalid parameter name '$__dsm__var_name'"
	fi
}

# Set variable from argument NAME=VALUE, only if it was not overridden by an argument on the CLI
param() { __dsm__set_variable_cli_override param "$@"; }

# Use format_string to format each subsequent argument, return a list separated by IFS
fmt() (
	format_string="$1"
	shift
	# shellcheck disable=SC2059
	[ "$#" != 0 ] && printf "${format_string}${IFS%"${IFS#?}"}" "$@"
)

# Perform tilde- and pathname-expansion (globbing) on arguments
# Similar behavior as the wildcard function in GNU Make
wildcard() (
	set +f                 # Enable globbing
	ft="${IFS%"${IFS#?}"}" # Use first character of IFS as field terminator
	for pattern in "$@"; do
		case "$pattern" in
		'~') pattern="$HOME" ;;
		'~'/*) pattern="${HOME}${pattern#'~'}" ;;
		esac
		# shellcheck disable=SC2086
		for file in $(printf "%s${ft}" $pattern); do
			[ -e "$file" ] && printf "%s${ft}" "$file"
		done
	done
)

set -f # Disable globbing (aka pathname expansion)
case "$MAKE_DEBUG" in *shell*) ;; *) upgrade_to_better_shell "$@" ;; esac
__dsm__cmd="$0"
__dsm__cli_parameters_list=
__dsm__targets=
__target=
for __dsm__arg in "$@"; do
	case "$__dsm__arg" in
	[_a-zA-Z]*=*) __dsm__set_variable_cli_override '' "$__dsm__arg" ;;
	-*) abort "${__dsm__cmd}: invalid option '${__dsm__arg}'" ;;
	*) __dsm__targets="${__dsm__targets}${__dsm__arg} " ;;
	esac
done
[ "$__dsm__targets" ] || __dsm__targets=-
log_debug "dot-slash-make: targets list: '${__dsm__targets}'"
