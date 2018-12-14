## source me, don't run me

#####################
# virtualbox config #
#####################
#---------------------------------------------------------------------------------------------------
# General  System  Display  Storage  Audio  Network  Ports  Shared Folders  User Interface
# ^^^^^^^
#    Name: LFS2018Thanksgiving
#    Type: Linux
# Version: Other Linux (64-bit)
#
#---------------------------------------------------------------------------------------------------
# General  System  Display  Storage  Audio  Network  Ports  Shared Folders  User Interface
#          ^^^^^^
# Base Memory: 4096 MB
#         Boot Order: [v] Floppy
#                     [v] Optical
#                     [v] Hard Disk
#                     [ ] Network
#            Chipset: PIIX3
#    Pointing Device: USB Tablet
#  Extended Features: [v] Enable I/O APIC
#                     [ ] Enable EFI (special OSes only)
#                     [v] Hardware Clock in UTC
#
#---------------------------------------------------------------------------------------------------
# General  System  Display  Storage  Audio  Network  Ports  Shared Folders  User Interface
#                           ^^^^^^^
# Storage Devices -----  | Attributes -------------------------
# +-------------------+  |        Name: SATA
# | Controller: SATA  |  |        Type: AHCI
# | +-- lfs.vdi       |  |  Port Count: 1
# |                   |  |              [ ] Use Host I/O Cache
# +-------------------+  |
#
#---------------------------------------------------------------------------------------------------
# General  System  Display  Storage  Audio  Network  Ports  Shared Folders  User Interface
#                                           ^^^^^^^
# [v] Enable Network Adapter
#             Attached to: NAT
#                Advanced
#            Adapter Type: Intel PRO/1000 MT Desktop (82540EM)
#        Promiscuous Mode: Deny
#             MAC Address: 080027398583
#                          [v] Cable Connected
#---------------------------------------------------------------------------------------------------

#export LFS_LOG=/home/ubuntu/lfs.log

################################################################################


################################################################################

_blfs_sleep() {
    sleep 3
}

________________________________________________________________________________() {
    echo -e "\033[1;3;32m"'________________________________________________________________________________' | tee -a $LFS_LOG
    echo -e "$1" | tee -a $LFS_LOG
    echo -e '................................................................................'"\033[0m" | tee -a $LFS_LOG
    _blfs_sleep
}

________________________________________there_should_have________________________________________() {
    echo -e "\033[0;3;36m$1" | tee -a $LFS_LOG
    echo -e "\033[0;1;36m$2" | tee -a $LFS_LOG
    echo -e "\033[0;3;35m$3" | tee -a $LFS_LOG
    echo -e "\033[0;1;35m$4" | tee -a $LFS_LOG
    echo -e "\033[0m" | tee -a $LFS_LOG
    _blfs_sleep
}

________________________________________TEXT________________________________________() {
    color=34
    echo -e "\033[7;${color}m$1\033[0m\033[${color}m__________________________________________________\033[0m" | tee -a $LFS_LOG
    echo -e "\033[0;${color}m$2" | tee -a $LFS_LOG
    echo -e "\033[0m" | tee -a $LFS_LOG
}

________________________________________HIGHLIGHT________________________________________() {
    color=$1
    echo -e "\033[7;${color}m$2\033[0m\033[${color}m__________________________________________________\033[0m" | tee -a $LFS_LOG
    echo -e "\033[0;${color}m$3" | tee -a $LFS_LOG
    shift 3
    echo -e "\033[0;1;${color}m$@" | tee -a $LFS_LOG
    echo -e "\033[0m" | tee -a $LFS_LOG
    _blfs_sleep
}

________________________________________NOTE________________________________________() {
    ________________________________________HIGHLIGHT________________________________________ 33 Note "$1" "$2"
}

________________________________________IMPORTANT________________________________________() {
    ________________________________________HIGHLIGHT________________________________________ 31 Important "$1" "$2"
}

################################################################################

_____________() {
    echo -e "\033[1;46m"$@"\033[0m"
}

pause_and_run() {
    echo -e "\033[1;42m"$@"\033[0m"
    read
    $@
}

################################################################################

_blfs_refresh_the_functions() {
    functionsfile=010-functions.sh

    cd /sources/downloads
    rm -v $functionsfile
    wget 192.168.10.144:8000/$functionsfile  # because python3 -m http.server
    . $functionsfile
    cd -
}

_blfs_console_fonts() {
    tar xf terminus-font-4.46.tar.gz
    cd terminus-font-4.46
    make psf
    install -v -m644 ter-v14n.psf /usr/share/consolefonts
    echo -e "done \033[32minstall -v -m644 ter-v14n.psf /usr/share/consolefonts\033[0m"
    echo -e "now you can do \033[36msetfont /usr/share/consolefonts/ter-v14n.psf\033[0m"
}

_blfs_install_make-ca() {
    # http://www.linuxfromscratch.org/blfs/view/stable-systemd/postlfs/make-ca.html
    # http://www.cacert.org/certs/root.crt
    # http://www.cacert.org/certs/class3.crt
    install -vdm755 /etc/ssl/local
    openssl x509 -in root.crt -text -fingerprint -setalias "CAcert Class 1 root" \
            -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
            > /etc/ssl/local/CAcert_Class_1_root.pem
    openssl x509 -in class3.crt -text -fingerprint -setalias "CAcert Class 3 root" \
            -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
            > /etc/ssl/local/CAcert_Class_3_root.pem
    make install
    /usr/sbin/make-ca -g
}

_blfs_install_wget() {
    echo -e "\033[35mhas \033[0;31mmake-ca \033[0;35mbeen installed? (y/n) "
    read ans
    if [ x"$ans" == xy ]; then
        ./configure --prefix=/usr --sysconfdir=/etc --with-ssl=openssl
        make
        make install
    fi
}

_blfs_install_pciutils() {
    cd /sources/downloads/blfs
    wget https://www.kernel.org/pub/software/utils/pciutils/pciutils-3.6.2.tar.xz
    tar xf pciutils-3.6.2.tar.xz
    cd pciutils-3.6.2

    make PREFIX=/usr                \
         SHAREDIR=/usr/share/hwdata \
         SHARED=yes

    make PREFIX=/usr                \
         SHAREDIR=/usr/share/hwdata \
         SHARED=yes                 \
         install install-lib

    chmod -v 755 /usr/lib/libpci.so

    cat > /lib/systemd/system/update-pciids.service << "EOF"
[Unit]
Description=Update pci.ids file
Documentation=man:update-pciids(8)
DefaultDependencies=no
After=local-fs.target
Before=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/update-pciids
EOF

    cat > /lib/systemd/system/update-pciids.timer << "EOF"
[Unit]
Description=Update pci.ids file weekly

[Timer]
OnCalendar=Sun 02:30:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

    systemctl enable update-pciids.timer
}

_blfs_test() {
    _____________ "a bc"
    pause_and_run echo ab c
}

_blfs_install_vimcat() {
    wget -O vimcat https://www.vim.org/scripts/download_script.php?src_id=23422
    install -v -m755 vimcat /usr/local/bin
}

_blfs_set_bashrc() {
    cat > ~/.bashrc << "EOF"
# don't put duplicate lines or lines starting with space in the history. See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

export PS_YELLOWUL_ON_GREY='\[\033[0m\033[48;5;250m\033[4;38;5;227m\]'
export PS_MAGENTA_ON_GRAY='\[\033[0;47;35m\]'
export PS_BLUE_ON_GRAY='\[\033[0;47;34m\]'
export PS_NOCOLOR='\[\033[00m\]'
export PS_RED_ON_GRAY='\[\033[0;47;31m\]'
export PS_GREENUL_ON_GRAY='\[\033[0;4;47;32m\]'
export PS_USER=$PS_YELLOWUL_ON_GREY'\u'$PS_NOCOLOR
export PS_SEP=$PS_MAGENTA_ON_GRAY':'$PS_NOCOLOR
export PS_CWD=$PS_BLUE_ON_GRAY'\w'$PS_NOCOLOR
export PS1="$PS_USER$PS_SEP$PS_CWD$PS_GREENUL_ON_GRAY$PS_RED_ON_GRAY\$$PS_NOCOLOR "

export PATH=/usr/local/bin:$PATH

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ll='ls -alF'
alias lh='ls -alhF'
alias l='ls -CF'
EOF

    . ~/.bashrc
}

_blfs_set_user_defaults() {
    # copied from Ubuntu 18.04

    cat > /etc/skel/.profile << "EOF"
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
EOF

    cat > /etc/skel/.bash_logout << "EOF"
# ~/.bash_logout: executed by bash(1) when login shell exits.
# when leaving the console clear the screen to increase privacy
if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi
EOF

    cat > /etc/skel/.bashrc << "EOF"
# don't put duplicate lines or lines starting with space in the history. See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ll='ls -alF'
alias lh='ls -alhF'
alias la='ls -A'
alias l='ls -CF'
EOF

}

_blfs_add_user_yyu() {
    useradd -m yyu
}

_blfs_setup_bash() {
    cat > /etc/profile << "EOF"
# Begin /etc/profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# modifications by Dagmar d'Surreal <rivyqntzne@pbzpnfg.arg>

# System wide environment variables and startup programs.

# System wide aliases and functions should go in /etc/bashrc.  Personal
# environment variables and startup programs should go into
# ~/.bash_profile.  Personal aliases and functions should go into
# ~/.bashrc.

# Functions to help us manage paths.  Second argument is the name of the
# path variable to be modified (default: PATH)
pathremove () {
        local IFS=':'
        local NEWPATH
        local DIR
        local PATHVARIABLE=${2:-PATH}
        for DIR in ${!PATHVARIABLE} ; do
                if [ "$DIR" != "$1" ] ; then
                  NEWPATH=${NEWPATH:+$NEWPATH:}$DIR
                fi
        done
        export $PATHVARIABLE="$NEWPATH"
}

pathprepend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="$1${!PATHVARIABLE:+:${!PATHVARIABLE}}"
}

pathappend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="${!PATHVARIABLE:+${!PATHVARIABLE}:}$1"
}

export -f pathremove pathprepend pathappend

# Set the initial path
export PATH=/bin:/usr/bin

if [ $EUID -eq 0 ] ; then
        pathappend /sbin:/usr/sbin
        unset HISTFILE
fi

# Setup some environment variables.
export HISTSIZE=1000
export HISTIGNORE="&:[bf]g:exit"

# Set some defaults for graphical systems
export XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/share/}
export XDG_CONFIG_DIRS=${XDG_CONFIG_DIRS:-/etc/xdg/}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$USER}

# Setup a red prompt for root and a green one for users.
NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
else
  PS1="$GREEN\u [ $NORMAL\w$GREEN ]\$ $NORMAL"
fi

for script in /etc/profile.d/*.sh ; do
        if [ -r $script ] ; then
                . $script
        fi
done

unset script RED GREEN NORMAL

# End /etc/profile
EOF

    install --directory --mode=0755 --owner=root --group=root /etc/profile.d

    cat > /etc/profile.d/bash_completion.sh << "EOF"
# Begin /etc/profile.d/bash_completion.sh
# Import bash completion scripts

for script in /etc/bash_completion.d/*.sh ; do
        if [ -r $script ] ; then
                . $script
        fi
done
# End /etc/profile.d/bash_completion.sh
EOF

    install --directory --mode=0755 --owner=root --group=root /etc/bash_completion.d
    
    cat > /etc/profile.d/dircolors.sh << "EOF"
# Setup for /bin/ls and /bin/grep to support color, the alias is in /etc/bashrc.
if [ -f "/etc/dircolors" ] ; then
        eval $(dircolors -b /etc/dircolors)
fi

if [ -f "$HOME/.dircolors" ] ; then
        eval $(dircolors -b $HOME/.dircolors)
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
EOF

    cat > /etc/profile.d/extrapaths.sh << "EOF"
if [ -d /usr/local/lib/pkgconfig ] ; then
        pathappend /usr/local/lib/pkgconfig PKG_CONFIG_PATH
fi
if [ -d /usr/local/bin ]; then
        pathprepend /usr/local/bin
fi
if [ -d /usr/local/sbin -a $EUID -eq 0 ]; then
        pathprepend /usr/local/sbin
fi

# Set some defaults before other applications add to these paths.
pathappend /usr/share/man  MANPATH
pathappend /usr/share/info INFOPATH
EOF

    cat > /etc/profile.d/readline.sh << "EOF"
# Setup the INPUTRC environment variable.
if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ] ; then
        INPUTRC=/etc/inputrc
fi
export INPUTRC
EOF

    cat > /etc/profile.d/umask.sh << "EOF"
# By default, the umask should be set.
if [ "$(id -gn)" = "$(id -un)" -a $EUID -gt 99 ] ; then
  umask 002
else
  umask 022
fi
EOF

    cat > /etc/profile.d/i18n.sh << "EOF"
# Set up i18n variables
#export LANG=<ll>_<CC>.<charmap><@modifiers>
EOF

    cat > /etc/bashrc << "EOF"
# Begin /etc/bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# System wide aliases and functions.

# System wide environment variables and startup programs should go into
# /etc/profile.  Personal environment variables and startup programs
# should go into ~/.bash_profile.  Personal aliases and functions should
# go into ~/.bashrc

# Provides colored /bin/ls and /bin/grep commands.  Used in conjunction
# with code in /etc/profile.

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Provides prompt for non-login shells, specifically shells started
# in the X environment. [Review the LFS archive thread titled
# PS1 Environment Variable for a great case study behind this script
# addendum.]

NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
else
  PS1="$GREEN\u [ $NORMAL\w$GREEN ]\$ $NORMAL"
fi

unset RED GREEN NORMAL

# End /etc/bashrc
EOF

    cat > ~/.bash_profile << "EOF"
# Begin ~/.bash_profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# Personal environment variables and startup programs.

# Personal aliases and functions should go in ~/.bashrc.  System wide
# environment variables and startup programs are in /etc/profile.
# System wide aliases and functions are in /etc/bashrc.

if [ -f "$HOME/.bashrc" ] ; then
  source $HOME/.bashrc
fi

if [ -d "$HOME/bin" ] ; then
  pathprepend $HOME/bin
fi

# Having . in the PATH is dangerous
#if [ $EUID -gt 99 ]; then
#  pathappend .
#fi

# End ~/.bash_profile
EOF

    dircolors -p > /etc/dircolors
}

_blfs_etc_issue() {
    # b   Insert the baudrate of the current line.
    # d   Insert the current date.
    # s   Insert the system name, the name of the operating system.
    # l   Insert the name of the current tty line.
    # m   Insert the architecture identifier of the machine, e.g., i686.
    # n   Insert the nodename of the machine, also known as the hostname.
    # o   Insert the domainname of the machine.
    # r   Insert the release number of the kernel, e.g., 2.6.11.12.
    # t   Insert the current time.
    # u   Insert the number of current users logged in.
    # U   Insert the string "1 user" or "<n> users" where <n> is the
    #     number of current users logged in.
    # v   Insert the version of the OS, e.g., the build-date etc.
    cat > /etc/issue << "EOF"
\s \r \v (\m)

[\d \t] \l

EOF
}

_blfs_install_lsb_release() {
    # http://www.linuxfromscratch.org/blfs/view/stable-systemd/postlfs/lsb-release.html

    # sed -i "s|n/a|unavailable|" lsb_release
    # 
    # ./help2man -N --include ./lsb_release.examples \
    #               --alt_version_key=program_version ./lsb_release > lsb_release.1
    # 
    # install -v -m 644 lsb_release.1 /usr/share/man/man1
    # install -v -m 755 lsb_release   /usr/bin
    echo
}

_blfs_install_cracklib() {
    pause_and_run cd /sources/downloads/blfs

    pause_and_run wget https://github.com/cracklib/cracklib/releases/download/cracklib-2.9.6/cracklib-2.9.6.tar.gz
    pause_and_run wget https://github.com/cracklib/cracklib/releases/download/cracklib-2.9.6/cracklib-words-2.9.6.gz

    pause_and_run tar xf cracklib-2.9.6.tar.gz
    pause_and_run cd cracklib-2.9.6

    pause_and_run sed -i '/skipping/d' util/packer.c

    pause_and_run ./configure --prefix=/usr    \
                              --disable-static \
                              --with-default-dict=/lib/cracklib/pw_dict
    pause_and_run make

    pause_and_run make install
    pause_and_run mv -v /usr/lib/libcrack.so.* /lib
    pause_and_run ln -sfv ../../lib/$(readlink /usr/lib/libcrack.so) /usr/lib/libcrack.so

    pause_and_run install -v -m644 -D    ../cracklib-words-2.9.6.gz \
                                           /usr/share/dict/cracklib-words.gz

    pause_and_run gunzip -v                /usr/share/dict/cracklib-words.gz
    pause_and_run ln -v -sf cracklib-words /usr/share/dict/words

    _____________ "echo $(hostname) >>      /usr/share/dict/cracklib-extra-words"
    echo $(hostname) >>      /usr/share/dict/cracklib-extra-words

    pause_and_run install -v -m755 -d      /lib/cracklib

    pause_and_run create-cracklib-dict     /usr/share/dict/cracklib-words \
                                           /usr/share/dict/cracklib-extra-words

    pause_and_run make test
}

_blfs_install_cryptsetup() {
    # skipped
    # http://www.linuxfromscratch.org/blfs/view/stable-systemd/postlfs/cryptsetup.html
    echo
}

_blfs_install_json_c() {
    pause_and_run pushd /sources/downloads/blfs
    pause_and_run wget https://s3.amazonaws.com/json-c_releases/releases/json-c-0.13.1.tar.gz
    pause_and_run tar xf json-c-0.13.1.tar.gz
    pause_and_run cd json-c-0.13.1
    pause_and_run ./configure --prefix=/usr --disable-static
    pause_and_run make
    pause_and_run make install
    popd
}

_blfs_extract_filename() {
    echo $1 | sed -e 's/.*\///g'
}

_blfs_folder_name() {
    echo $tarball | sed -e 's/\.tar\.[gxb]z2\?//g'
}

_blfs_download_extract_and_enter() {
    download_url=$1
    tarball=$(_blfs_extract_filename $download_url)
    folder=$(_blfs_folder_name $tarball)

    pause_and_run wget $download_url
    pause_and_run tar xf $tarball
    pause_and_run cd $folder
}

_blfs_install_popt() {
    download_url=ftp://anduin.linuxfromscratch.org/BLFS/popt/popt-1.16.tar.gz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $download_url
    pause_and_run ./configure --prefix=/usr --disable-static
    pause_and_run make
    pause_and_run make install
    pause_and_run popd
}
