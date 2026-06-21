export GPG_TTY=$(tty)

if [ "$(tty)" = "/dev/tty1" ]; then
    exec startx > /tmp/startx.log 2>&1
fi
