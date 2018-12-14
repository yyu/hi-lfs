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

