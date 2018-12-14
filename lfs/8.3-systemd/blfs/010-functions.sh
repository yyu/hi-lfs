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
function parse_git_branch {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/\* \(.*\)/(\1)/'
}
# colors in terminals

export NOCOLOR='\033[00m'

export BLACK='\033[0;1m'

export RED='\033[0;31m'
export REDUL='\033[0;4;31m'

export GREEN='\033[0;32m'
export GREENUL='\033[0;4;32m'
export LIGHTGREEN='\033[0;1;32m'

export YELLOW='\033[0;33m'
export YELLOWUL='\033[0;4;33m'
export LIGHTYELLOW='\033[0;1;33m'

export BLUE='\033[0;34m'
export BLUEUL='\033[0;4;34m'
export LIGHTBLUE='\033[0;1;34m'

export MAGENTA='\033[0;35m'
export MAGENTAUL='\033[0;4;35m'
export LIGHTMAGENTA='\033[0;1;35m'

export CYAN='\033[0;36m'
export CYANUL='\033[0;4;36m'
export LIGHTCYAN='\033[0;1;36m'

export GRAY='\033[0;37m'
export GRAYUL='\033[0;4;37m'

export WHITE='\033[0;1;37m'

# colors on gray

export BLACK_ON_GRAY='\033[0;47;1m'

export RED_ON_GRAY='\033[0;47;31m'
export REDUL_ON_GRAY='\033[0;4;47;31m'

export GREEN_ON_GRAY='\033[0;47;32m'
export GREENUL_ON_GRAY='\033[0;4;47;32m'

export YELLOW_ON_GRAY='\033[0;47;33m'
export YELLOWUL_ON_GRAY='\033[0;4;47;33m'

export BLUE_ON_GRAY='\033[0;47;34m'
export BLUEUL_ON_GRAY='\033[0;4;47;34m'

export MAGENTA_ON_GRAY='\033[0;47;35m'
export MAGENTAUL_ON_GRAY='\033[0;4;47;35m'

export CYAN_ON_GRAY='\033[0;47;36m'
export CYANUL_ON_GRAY='\033[0;4;47;36m'

export WHITE_ON_GRAY='\033[0;47;1;37m'

# colors below are used in PS1 for color prompt

export PS_NOCOLOR='\[\033[00m\]'

export PS_BLACK='\[\033[0;1m\]'

export PS_RED='\[\033[0;31m\]'
export PS_REDUL='\[\033[0;4;31m\]'

export PS_GREEN='\[\033[0;32m\]'
export PS_GREENUL='\[\033[0;4;32m\]'

export PS_YELLOW='\[\033[0;33m\]'
export PS_YELLOWUL='\[\033[0;4;33m\]'

export PS_BLUE='\[\033[0;34m\]'
export PS_BLUEUL='\[\033[0;4;34m\]'

export PS_MAGENTA='\[\033[0;35m\]'
export PS_MAGENTAUL='\[\033[0;4;35m\]'

export PS_CYAN='\[\033[0;36m\]'
export PS_CYANUL='\[\033[0;4;36m\]'

export PS_GRAY='\[\033[0;37m\]'
export PS_GRAYUL='\[\033[0;4;37m\]'

export PS_WHITE='\[\033[0;1;37m\]'

# colors on gray

export PS_BLACK_ON_GRAY='\[\033[0;47;1m\]'

export PS_RED_ON_GRAY='\[\033[0;47;31m\]'
export PS_REDUL_ON_GRAY='\[\033[0;4;47;31m\]'

export PS_GREEN_ON_GRAY='\[\033[0;47;32m\]'
export PS_GREENUL_ON_GRAY='\[\033[0;4;47;32m\]'

export PS_YELLOW_ON_GRAY='\[\033[0;47;38;5;227m\]'
export PS_YELLOWUL_ON_GRAY='\[\033[0;47;38;5;227m\]'
export PS_YELLOW_ON_GREY='\[\033[0m\033[48;5;250m\033[38;5;227m\]'
export PS_YELLOWUL_ON_GREY='\[\033[0m\033[48;5;250m\033[4;38;5;227m\]'

export PS_BLUE_ON_GRAY='\[\033[0;47;34m\]'
export PS_BLUEUL_ON_GRAY='\[\033[0;4;47;34m\]'

export PS_MAGENTA_ON_GRAY='\[\033[0;47;35m\]'
export PS_MAGENTAUL_ON_GRAY='\[\033[0;4;47;35m\]'

export PS_CYAN_ON_GRAY='\[\033[0;47;36m\]'
export PS_CYANUL_ON_GRAY='\[\033[0;4;47;36m\]'

export PS_WHITE_ON_GRAY='\[\033[0;47;1;37m\]'

export PS_TIME=$PS_REDUL_ON_GRAY'[\t]'$PS_NOCOLOR
#export PS_USER=$PS_YELLOWUL_ON_GREY'\u'$PS_GREENUL_ON_GREY'@'$PS_NOCOLOR
export PS_USER=$PS_YELLOWUL_ON_GREY'\u'$PS_NOCOLOR
export PS_HOST=$PS_YELLOWUL_ON_GREY'\h'$PS_NOCOLOR
export PS_CWD=$PS_BLUE_ON_GRAY'\w'$PS_NOCOLOR
export PS_SEP=$PS_MAGENTA_ON_GRAY':'$PS_NOCOLOR
export PS1="$PS_USER$PS_SEP$PS_CWD$PS_GREENUL_ON_GRAY\$(parse_git_branch)$PS_RED_ON_GRAY\$$PS_NOCOLOR "
export PATH=/usr/local/bin:$PATH
EOF

    . ~/.bashrc
}
