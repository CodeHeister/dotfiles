#!/bin/bash
set -uo pipefail

configs=(
	".xinitrc"
	".Xresources"
	".Xresources.d"
	".config"
	".zshrc"
	".profile"
)

paks_pacman=(
	"i3-gaps"
	"cmus"
	"maim"
	"flameshot"
	"neovim"
	"rofi"
	"feh"
	"xss-lock"
	"rxvt-unicode"
	"thunar"
	"ranger"
	"ueberzug"
	"zathura"
	"dunst"
	"papirus-icon-theme"
	"yarn"
	"picom"
	"cava"
	"polybar"
	"ttf-iosevka-nerd"
	"ttf-hack-nerd"
	"ttf-fira-code"
	"zsh"
	"starship"
	"zoxide"
)

paks_aur=(
	"breeze-default-cursor-theme"
	"qogir-gtk-theme"
	"candy-icons-git"
	"ttf-iosevka"
)

extra_pacman=(
	"cava"
	"cmus"
	"htop"
	"btop"
	"cmatrix"
	"obsidian"
)

extra_aur=(
	"tt"
	"cbonsai"
	"pipes.sh"
)

log_ok()  { printf "\033[36m%s\033[39m\n" "$1"; }
log_warn(){ printf "\033[33m%s\033[39m\n" "$1"; }
log_err() { printf "\033[31m%s\033[39m\n" "$1" >&2; }

run_root() {
	if [ "$EUID" -ne 0 ]; then
		sudo "$@"
	else
		log_warn "Already root, running without sudo"
		"$@"
	fi
}

find_aur_helper() {
	if command -v yay &> /dev/null; then
		echo "yay"
	elif command -v paru &> /dev/null; then
		echo "paru"
	fi
}

function install_pacman() {
	run_root pacman -Sy --needed --noconfirm "${paks_pacman[@]}"
}

function install_aur() {
	if [ "$EUID" -eq 0 ]; then
		log_err "AUR: refusing to build/install AUR packages as root"
		return 1
	fi

	local helper
	helper=$(find_aur_helper)

	if [ -z "$helper" ]; then
		log_warn "AUR helper: neither yay nor paru found"
		printf "Install paru now? [y/N] "
		read -r answer
		case "$answer" in
			[yY]|[yY][eE][sS])
				install_paru_binary || { log_err "paru: installation failed"; return 1; }
				helper="paru"
				;;
			*)
				log_err "AUR helper: skipping AUR package installation"
				return 1
				;;
		esac
	else
		log_ok "AUR helper: using $helper"
	fi

	"$helper" -Sy --needed --noconfirm "${paks_aur[@]}"
}

function install_paru_binary() {
	log_ok "paru: installing prerequisites"
	run_root pacman -S --needed --noconfirm base-devel || return 1

	local tmpdir
	tmpdir=$(mktemp -d) || return 1

	(
		set -e
		cd "$tmpdir"
		git clone https://aur.archlinux.org/paru.git
		cd paru
		makepkg -si --noconfirm
	)
	local status=$?

	rm -rf "$tmpdir"
	return $status
}

function install_zsh() {
	if ! command -v zsh &> /dev/null; then
		log_err "zsh: not installed (run './install.sh pacman' first)"
		return 1
	fi

	local zsh_path
	zsh_path=$(command -v zsh)

	if [ "$SHELL" != "$zsh_path" ]; then
		log_ok "zsh: setting as default shell for $USER"
		if run_root chsh -s "$zsh_path" "$USER"; then
			log_ok "zsh: default shell set (effective next login)"
		else
			log_err "zsh: failed to set default shell"
		fi
	else
		log_ok "zsh: already the default shell"
	fi

	if [ -d "$HOME/.oh-my-zsh" ]; then
		log_ok "oh-my-zsh: already installed"
		return 0
	fi

	log_ok "oh-my-zsh: installing"
	RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
		"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
		|| { log_err "oh-my-zsh: installation failed"; return 1; }
}

function install_extra() {
	log_ok "extra: installing pacman packages"
	run_root pacman -Sy --needed --noconfirm "${extra_pacman[@]}"

	if [ "$EUID" -eq 0 ]; then
		log_err "extra: refusing to build/install AUR packages as root, skipping AUR extras"
		return 1
	fi

	local helper
	helper=$(find_aur_helper)

	if [ -z "$helper" ]; then
		log_err "extra: no AUR helper found (run './install.sh aur' first to install one), skipping AUR extras"
		return 1
	fi

	log_ok "extra: installing AUR packages via $helper"
	"$helper" -Sy --needed --noconfirm "${extra_aur[@]}"
}

function move_configs() {
	for i in "${configs[@]}"; do
		if [ ! -e "./${i}" ]; then
			log_err "${i}: invalid path"
			continue
		fi

		if [ -d "./${i}" ]; then
			mkdir -p "$HOME/${i}"
			find "./${i}" -maxdepth 1 -mindepth 1 | while read -r line; do
				name="${line##*/}"
				dest="$HOME/${i}/${name}"

				if [ -e "$dest" ]; then
					if mv "$dest" "${dest}.save"; then
						log_ok "$HOME/${i}: initial config $name saved as ${name}.save"
					else
						log_err "$HOME/${i}: initial config not saved"
					fi
				fi

				if cp -r "./${i}/${name}" "$HOME/${i}"; then
					log_ok "$HOME/${i}: added $name"
				else
					log_err "$HOME/${i}: failed to add $name"
				fi
			done
		else
			dest="$HOME/${i}"

			if [ -e "$dest" ]; then
				if mv "$dest" "${dest}.save"; then
					log_ok "$HOME: initial config $i saved as ${i}.save"
				else
					log_err "$HOME: initial config not saved"
				fi
			fi

			if cp -r "./${i}" "$HOME"; then
				log_ok "$HOME: added $i"
			else
				log_err "$HOME: failed to add $i"
			fi
		fi
	done
}

function show_help() {
	cat <<'EOF'
Usage: ./install.sh [SUB-COMMAND]
  help		show this message
  aur		install aur packages (uses yay or paru, offers to install paru if neither found)
  pacman	install pacman packages
  zsh		set zsh as default shell and install oh-my-zsh
  set		move configs to home
  extra		install optional extras (cmus, cava, htop, btop, cmatrix, obsidian, tt, cbonsai, pipes.sh)
            not part of the default pipeline, run explicitly
On no sub-commands script will use default settings.
EOF
}

if [ $# -lt 1 ]; then
	install_pacman
	install_aur
	move_configs
	install_zsh
	exit 0
fi

while (( "$#" )); do
	arg=$1
	case $arg in
		pacman)
			install_pacman ;;
		aur)
			install_aur ;;
		set)
			move_configs ;;
		zsh)
			install_zsh ;;
		extra)
			install_extra ;;
		help)
			show_help ;;
		*)
			log_err "$arg: No such sub-command" ;;
	esac
	shift
done
