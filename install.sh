configs=(
	".xinitrc"
	".Xresources"
	".Xresources.d"
	".config"
	".zshrc"
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
)

paks_yay=(
	"betterlockscreen"
	"breeze-default-cursor-theme"
	"qogir-gtk-theme"
	"candy-icons-git"
	"picom-ibhagwan-git"
	"cava"
	"eww-git"
	"lemonbar-xft-git"
	"ttf-hack-nerd"
	"ttf-iosevka"
)

function install_pacman() {
	local paks_install=""

	for i in "${paks_pacman[@]}"; do 
		paks_install="$paks_install$i "
	done
	echo -n $paks_install
	
	if [ "$EUID" -ne 0 ]; then
		sudo pacman -Sy $paks_install
	else
		printf "\033[31mpacman\033[39m: Already \033[36mroot\033[39m (--noconfirm)\n"
		pacman -Sy $paks_install --noconfirm
	fi
}

function install_aur() {
	local paks_install=""

	for i in "${paks_yay[@]}"; do 
		paks_install="$paks_install$i "
	done

	if [ "$EUID" -ne 0 ]; then
		if [ ! command -v yay &> /dev/null ]; then
			printf "\033[31myay\033[39m: no yay"
		else
			yay -Sy $paks_install
		fi
	else
		printf "\033[31myay\033[39m: Already \033[36mroot\033[39m (not allowed)\n"
	fi
}

function move_configs() {
	for i in ${configs[@]}; do
		if [ -e "./${i}" ]; then
			if [ -d "./${i}" ]; then
				mkdir -p "$HOME/${i}"
				find "./${i}" -maxdepth 1 -mindepth 1 | {
					while read line; do 
						save="$HOME/${i}/${line##*/}"
						if [ -e "${save}" ]; then
							mv "${save}" "${save}.save"
							if [ $? -ne 0 ]; then
								printf "\033[31m%s\033[39m: initial config not saved\n" \
									"$HOME/${i}" >&2
							else 
								printf "\033[36m%s\033[39m: initial config source \033[36m%s\033[39m saved as \033[36m%s.save\033[39m\n" \
									"$HOME/${i}" "${line##*/}" "${line##*/}"
							fi
						fi
						cp -r "./${i}/${line##*/}" "$HOME/${i}"
						if [ $? -ne 0 ]; then
							printf "\033[31m$HOME/${i}\033[39m: failed to add \033[36m${line##*/}\033[39m\n" >&2
						else 
							printf "\033[36m$HOME/${i}\033[39m: added \033[36m${line##*/}\033[39m\n"
						fi
					done
				}
			else
				save="$HOME/${i}"
				if [ -e "${save}" ]; then
					mv "${save}" "${save}.save"
					if [ $? -ne 0 ]; then
						printf "\033[31m%s\033[39m: initial config not saved\n" \
							"$HOME" >&2
					else
						printf "\033[36m%s\033[39m: initial config source \033[36m%s\033[39m saved as \033[36m%s.save\033[39m\n" \
							"$HOME" "${i}" "${i}"
					fi
				fi
				cp -r "./${i}" "$HOME"
				if [ $? -ne 0 ]; then
					printf "\033[31m$HOME\033[39m: failed to add \033[36m${i}\033[39m\n"
				else 
					printf "\033[36m$HOME\033[39m: added \033[36m${i}\033[39m\n"
				fi
			fi
		else
			printf "$i: \033[31minvalid path\033[39m\n"
		fi
	done
}

function make_nvim() {
	if [ ! -e "$HOME/.local/share/nvim/site/autoload/plug.vim" ]; then
		sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	fi
	nvim -c 'PlugUpdate' -c 'PlugInstall' -c 'qa!'
}

function show_help() {
	printf "Usage: ./install.sh [SUB-COMMAND]\n\n  help\t\tshow this message\n  yay\t\tinstall aur packages\n  pacman\tinstall pacman packages\n  nvim\t\tinstall nvim plugins\n  set\t\tmove configs to home\n\nOn no sub-commands script will use default settings.\n\n"
}

if [ $# -lt 1 ]; then
	install_pacman
	install_aur
	move_configs
	make_nvim
fi

while (( "$#" )); do
	arg=$1
	case $arg in
		pacman)
			install_pacman ;;
		yay)
			install_aur ;;
		set)
			move_configs ;;
		nvim)
			make_nvim ;;
		help)
			show_help ;;
		*)
			printf "\033[31m%s\033[39m: No such sub-command\n" "$arg" >&2
	esac
	shift
done


