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

export LFS_LOG=/var/log/lfs.log
export BLFS_LOG=/var/log/blfs.log

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

_log_() {
    $@ 2>&1 | tee -a $BLFS_LOG
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

    # skipped:
    # doxygen

    # skipped:
    # make check

    pause_and_run make install

    # skipped:
    # install -v -m755 -d /usr/share/doc/popt-1.16 &&
    # install -v -m644 doxygen/html/* /usr/share/doc/popt-1.16

    pause_and_run popd
}

_blfs_install_libuv_() {
    url=https://dist.libuv.org/dist/v1.22.0/libuv-v1.22.0.tar.gz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run sh autogen.sh
    pause_and_run ./configure --prefix=/usr --disable-static
    pause_and_run make
    pause_and_run make check
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_cmake_() {
    url=https://cmake.org/files/v3.12/cmake-3.12.1.tar.gz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake
    pause_and_run ./bootstrap --prefix=/usr        \
                              --system-libs        \
                              --mandir=/share/man  \
                              --no-system-jsoncpp  \
                              --no-system-librhash \
                              --docdir=/share/doc/cmake-3.12.1
    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_libarchive_() {
    url=http://www.libarchive.org/downloads/libarchive-3.3.2.tar.gz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr --disable-static
    pause_and_run make
    pause_and_run make check
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_valgrind_() {
    url=https://sourceware.org/ftp/valgrind/valgrind-3.13.0.tar.bz2

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run sed -i '1904s/4/5/' coregrind/m_syswrap/syswrap-linux.c

    pause_and_run sed -i 's|/doc/valgrind||' docs/Makefile.in

    pause_and_run ./configure --prefix=/usr \
                              --datadir=/usr/share/doc/valgrind-3.13.0
    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_which_() {
    url=https://ftp.gnu.org/gnu/which/which-2.21.tar.gz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr
    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_python27_() {
    url=https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tar.xz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr       \
                              --enable-shared     \
                              --with-system-expat \
                              --with-system-ffi   \
                              --with-ensurepip=yes \
                              --enable-unicode=ucs4
    pause_and_run make
    pause_and_run make install
    pause_and_run chmod -v 755 /usr/lib/libpython2.7.so.1.0

    # skipped:
    # pause_and_run install -v -dm755 /usr/share/doc/python-2.7.15
    # pause_and_run tar --strip-components=1                     \
    #                   --no-same-owner                          \
    #                   --directory /usr/share/doc/python-2.7.15 \
    #                   -xvf ../python-2.7.15-docs-html.tar.bz2
    #
    # pause_and_run find /usr/share/doc/python-2.7.15 -type d -exec chmod 0755 {} \;
    # pause_and_run find /usr/share/doc/python-2.7.15 -type f -exec chmod 0644 {} \;

    # pause_and_run echo 'export PYTHONDOCS=/usr/share/doc/python-2.7.15' >> ~/.bashrc

    pause_and_run popd
}

_blfs_install_llvm_() {
    pause_and_run wget http://llvm.org/releases/6.0.1/cfe-6.0.1.src.tar.xz
    pause_and_run wget http://llvm.org/releases/6.0.1/compiler-rt-6.0.1.src.tar.xz

    url=http://llvm.org/releases/6.0.1/llvm-6.0.1.src.tar.xz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run tar -xf ../cfe-6.0.1.src.tar.xz -C tools
    pause_and_run tar -xf ../compiler-rt-6.0.1.src.tar.xz -C projects

    pause_and_run mv tools/cfe-6.0.1.src tools/clang
    pause_and_run mv projects/compiler-rt-6.0.1.src projects/compiler-rt

    pause_and_run mkdir -v build
    pause_and_run cd       build

    _____________ 'CC=gcc CXX=g++'
    CC=gcc
    CXX=g++
    pause_and_run cmake -DCMAKE_INSTALL_PREFIX=/usr           \
                        -DLLVM_ENABLE_FFI=ON                  \
                        -DCMAKE_BUILD_TYPE=Release            \
                        -DLLVM_BUILD_LLVM_DYLIB=ON            \
                        -DLLVM_LINK_LLVM_DYLIB=ON             \
                        -DLLVM_TARGETS_TO_BUILD="host;AMDGPU" \
                        -DLLVM_BUILD_TESTS=ON                 \
                        -Wno-dev -G Ninja ..
    pause_and_run ninja
    # pause_and_run ninja check-all # this didn't finish properly
    pause_and_run ninja install

    # skipped:
    # rm -rf ./*
    # cmake -DLLVM_ENABLE_SPHINX=ON         \
    #       -DSPHINX_WARNINGS_AS_ERRORS=OFF \
    #       -Wno-dev ..                     &&
    # make docs-llvm-html  docs-llvm-man
    # make docs-clang-html docs-clang-man
    #
    # install -v -m644 docs/man/* /usr/share/man/man1             &&
    # install -v -d -m755 /usr/share/doc/llvm-6.0.1/llvm-html     &&
    # cp -Rv docs/html/* /usr/share/doc/llvm-6.0.1/llvm-html
    # 
    # install -v -m644 tools/clang/docs/man/* /usr/share/man/man1 &&
    # install -v -d -m755 /usr/share/doc/llvm-6.0.1/clang-html    &&
    # cp -Rv tools/clang/docs/html/* /usr/share/doc/llvm-6.0.1/clang-html

    pause_and_run popd
}

_blfs_install_python37_() {
    url=https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tar.xz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    _____________ 'CXX="/usr/bin/g++"'
    CXX="/usr/bin/g++"

    pause_and_run ./configure --prefix=/usr       \
                              --enable-shared     \
                              --with-system-expat \
                              --with-system-ffi   \
                              --with-ensurepip=yes
    pause_and_run make
    pause_and_run make install
    pause_and_run chmod -v 755 /usr/lib/libpython3.7m.so
    pause_and_run chmod -v 755 /usr/lib/libpython3.so

    ln -svfn python-3.7.0 /usr/share/doc/python-3
    echo 'export PYTHONDOCS=/usr/share/doc/python-3/html' >> ~/.bashrc

    pause_and_run popd
}

_blfs_install_libxml_() {
    url=http://xmlsoft.org/sources/libxml2-2.9.8.tar.gz

    pause_and_run pushd /sources/downloads/blfs

    pause_and_run wget http://www.linuxfromscratch.org/patches/blfs/8.3/libxml2-2.9.8-python3_hack-1.patch

    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run patch -Np1 -i ../libxml2-2.9.8-python3_hack-1.patch
    pause_and_run sed -i '/_PyVerify_fd/,+1d' python/types.c
    pause_and_run ./configure --prefix=/usr    \
                              --disable-static \
                              --with-history   \
                              --with-python=/usr/bin/python3
    pause_and_run make

    # skipped testing
    #pause_and_run tar xf ../xmlts20130923.tar.gz

    pause_and_run make install

    pause_and_run popd
}

_blfs_install_doxygen_() {
    url=http://ftp.osuosl.org/pub/blfs/8.3/d/doxygen-1.8.14.src.tar.gz
    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url
    pause_and_run cd doxygen-1.8.14

    pause_and_run mkdir -v build
    pause_and_run cd       build

    _____________ 'cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -Wno-dev ..'
    cmake -G "Unix Makefiles"         \
          -DCMAKE_BUILD_TYPE=Release  \
          -DCMAKE_INSTALL_PREFIX=/usr \
          -Wno-dev ..

    pause_and_run make

    # skipped:
    # pause_and_run cmake -DDOC_INSTALL_DIR=share/doc/doxygen-1.8.14 -Dbuild_doc=ON ..
    # pause_and_run make docs

    pause_and_run make install
    pause_and_run install -vm644 ../doc/*.1 /usr/share/man/man1

    pause_and_run popd
}

_blfs_install_berkeleydb_() {
    url=http://anduin.linuxfromscratch.org/BLFS/bdb/db-5.3.28.tar.gz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run sed -i 's/\(__atomic_compare_exchange\)/\1_db/' src/dbinc/atomic.h
    pause_and_run cd build_unix
    pause_and_run ../dist/configure --prefix=/usr      \
                                    --enable-compat185 \
                                    --enable-dbm       \
                                    --disable-static   \
                                    --enable-cxx
    pause_and_run make
    pause_and_run make docdir=/usr/share/doc/db-5.3.28 install
    pause_and_run chown -v -R root:root                        \
                        /usr/bin/db_*                          \
                        /usr/include/db{,_185,_cxx}.h          \
                        /usr/lib/libdb*.{so,la}                \
                        /usr/share/doc/db-5.3.28

    pause_and_run popd
}

_blfs_install_cyrus_sasl_() {
    url=https://www.cyrusimap.org/releases/cyrus-sasl-2.1.26.tar.gz

    pause_and_run pushd /sources/downloads/blfs

    pause_and_run wget http://www.linuxfromscratch.org/patches/blfs/8.3/cyrus-sasl-2.1.26-fixes-3.patch
    pause_and_run wget http://www.linuxfromscratch.org/patches/blfs/8.3/cyrus-sasl-2.1.26-openssl-1.1.0-1.patch

    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run patch -Np1 -i ../cyrus-sasl-2.1.26-fixes-3.patch
    pause_and_run patch -Np1 -i ../cyrus-sasl-2.1.26-openssl-1.1.0-1.patch
    pause_and_run autoreconf -fi

    pause_and_run ./configure --prefix=/usr        \
                              --sysconfdir=/etc    \
                              --enable-auth-sasldb \
                              --with-dbpath=/var/lib/sasl/sasldb2 \
                              --with-saslauthd=/var/run/saslauthd
    pause_and_run make -j1

    pause_and_run make install
    pause_and_run install -v -dm755 /usr/share/doc/cyrus-sasl-2.1.26
    pause_and_run install -v -m644  doc/{*.{html,txt,fig},ONEWS,TODO} \
                          saslauthd/LDAP_SASLAUTHD /usr/share/doc/cyrus-sasl-2.1.26
    pause_and_run install -v -dm700 /var/lib/sasl

    pause_and_run popd
}

_blfs_kernel_build_config_for_lvm2_() {
    pause_and_run pushd /sources/downloads/blfs
    pause_and_run cd linux-4.18.5
    pause_and_run make mrproper
    pause_and_run cp -v /boot/config-4.18.5 .config
    echo -e '\033[1;33m
Device Drivers --->
  [*] Multiple devices driver support (RAID and LVM) ---> [CONFIG_MD]
    <*/M>   Device mapper support        [CONFIG_BLK_DEV_DM]
    <*/M/ >   Crypt target support       [CONFIG_DM_CRYPT]
    <*/M/ >   Snapshot target            [CONFIG_DM_SNAPSHOT]
    <*/M/ >   Thin provisioning target   [CONFIG_DM_THIN_PROVISIONING]
    <*/M/ >   Mirror target              [CONFIG_DM_MIRROR]
Kernel hacking --->
  [*] Magic SysRq key                    [CONFIG_MAGIC_SYSRQ]
    \033[0m'
    _____________ 'now do\033[0m \033[0;1;35mmake menuconfig'
}

_blfs_kernel_build_config_check_() {
    pause_and_run grep --color -E '(CONFIG_MD|CONFIG_BLK_DEV_DM|CONFIG_DM_CRYPT|CONFIG_DM_SNAPSHOT|CONFIG_DM_THIN_PROVISIONING|CONFIG_DM_MIRROR|CONFIG_MAGIC_SYSRQ)\>' .config
    pause_and_run diff --color /boot/config-4.18.5 .config
}

_blfs_kernel_build_() {
    pause_and_run make
    pause_and_run make modules_install
}

_blfs_kernel_post_build_() {
    pause_and_run cp -iv arch/x86/boot/bzImage /boot/vmlinuz-4.18.5-lfs-8.3-systemd
    pause_and_run cp -iv System.map /boot/System.map-4.18.5
    pause_and_run cp -iv .config /boot/config-4.18.5
    pause_and_run install -d /usr/share/doc/linux-4.18.5
    pause_and_run cp -r Documentation/* /usr/share/doc/linux-4.18.5
}

# _blfs_configure_linux_module_load_order() {
#     install -v -m755 -d /etc/modprobe.d
#     cat > /etc/modprobe.d/usb.conf << "EOF"
# # Begin /etc/modprobe.d/usb.conf
# 
# install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
# install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true
# 
# # End /etc/modprobe.d/usb.conf
# EOF
# }

_blfs_install_lvm2_() {
    url=https://sourceware.org/ftp/lvm2/releases/LVM2.2.02.177.tgz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run wget $url
    pause_and_run tar xf LVM2.2.02.177.tgz
    pause_and_run cd LVM2.2.02.177

    _____________ 'SAVEPATH=$PATH'
                   SAVEPATH=$PATH
    _____________ 'PATH=$PATH:/sbin:/usr/sbin'
                   PATH=$PATH:/sbin:/usr/sbin
    pause_and_run ./configure --prefix=/usr       \
                              --exec-prefix=      \
                              --with-confdir=/etc \
                              --enable-applib     \
                              --enable-cmdlib     \
                              --enable-pkgconfig  \
                              --enable-udev_sync
    pause_and_run make
    _____________ 'PATH=$SAVEPATH'
                   PATH=$SAVEPATH
    _____________ 'unset SAVEPATH'
                   unset SAVEPATH

    pause_and_run make -C tools install_dmsetup_dynamic
    pause_and_run make -C udev  install
    pause_and_run make -C libdm install

    # skipped
    # pause_and_run make -C test help
    # pause_and_run make check_local

    pause_and_run make install

    pause_and_run popd
}

_blfs_install_libgpg_error_() {
    url=https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.32.tar.bz2

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr
    pause_and_run make
    pause_and_run make install
    pause_and_run install -v -m644 -D README /usr/share/doc/libgpg-error-1.32/README

    pause_and_run popd
}

_blfs_install_libgcrypt_() {
    url=https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.8.3.tar.bz2

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr
    pause_and_run make

    # skipped
    # make -C doc pdf ps html
    # makeinfo --html --no-split -o doc/gcrypt_nochunks.html doc/gcrypt.texi
    # makeinfo --plaintext       -o doc/gcrypt.txt           doc/gcrypt.texi

    # skipped
    # make check

    pause_and_run make install
    pause_and_run install -v -dm755   /usr/share/doc/libgcrypt-1.8.3
    pause_and_run install -v -m644    README doc/{README.apichanges,fips*,libgcrypt*} \
                                      /usr/share/doc/libgcrypt-1.8.3

    # skipped
    # install -v -dm755   /usr/share/doc/libgcrypt-1.8.3/html
    # install -v -m644 doc/gcrypt.html/* \
    #                     /usr/share/doc/libgcrypt-1.8.3/html
    # install -v -m644 doc/gcrypt_nochunks.html \
    #                     /usr/share/doc/libgcrypt-1.8.3
    # install -v -m644 doc/gcrypt.{pdf,ps,dvi,txt,texi} \
    #                     /usr/share/doc/libgcrypt-1.8.3

    pause_and_run popd
}

_blfs_install_cryptsetup_() {
    url=https://www.kernel.org/pub/linux/utils/cryptsetup/v2.0/cryptsetup-2.0.4.tar.xz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr \
                              --with-crypto_backend=openssl
    pause_and_run make

    # skipped
    # pause_and_run make check

    pause_and_run make install

    pause_and_run popd
}

_blfs_kernel_build_config_() {
    pause_and_run pushd /sources/downloads/blfs
    pause_and_run cd linux-4.18.5
    pause_and_run make mrproper
    pause_and_run cp -v /boot/config-4.18.5 .config
    _____________ 'now do\033[0m \033[0;1;35mmake menuconfig'
}

_blfs_kernel_build_config_for_cryptsetup_() {
    echo -e '\033[1;33m
Device Drivers  --->          
  [*] Multiple devices driver support (RAID and LVM) ---> [CONFIG_MD]
       <*/M> Device mapper support           [CONFIG_BLK_DEV_DM]
       <*/M> Crypt target support            [CONFIG_DM_CRYPT]

Cryptographic API  --->                       
  <*/M> XTS support                          [CONFIG_CRYPTO_XTS]
  <*/M> SHA224 and SHA256 digest algorithm   [CONFIG_CRYPTO_SHA256]
  <*/M> AES cipher algorithms                [CONFIG_CRYPTO_AES]
  <*/M> AES cipher algorithms (x86_64)       [CONFIG_CRYPTO_AES_X86_64] 
  <*/M> User-space interface for symmetric key cipher algorithms
                                      [CONFIG_CRYPTO_USER_API_SKCIPHER]
  For tests:
  <*/M> Twofish cipher algorithm      [CONFIG_CRYPTO_TWOFISH]
\033[0m'

    _blfs_kernel_build_config_
}

_blfs_kernel_build_config_check_for_cryptsetup_() {
    pause_and_run diff --color /boot/config-4.18.5 .config
    pause_and_run grep --color -E '(CONFIG_MD|CONFIG_BLK_DEV_DM|CONFIG_DM_CRYPT|CONFIG_CRYPTO_XTS|CONFIG_CRYPTO_SHA256|CONFIG_CRYPTO_AES|CONFIG_CRYPTO_AES_X86_64|CONFIG_CRYPTO_USER_API_SKCIPHER|CONFIG_CRYPTO_TWOFISH)\>' .config
}

_blfs_install_libassuan_() {
    url=https://www.gnupg.org/ftp/gcrypt/libassuan/libassuan-2.5.1.tar.bz2

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr
    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_libksba_() {
    url=https://www.gnupg.org/ftp/gcrypt/libksba/libksba-1.3.5.tar.bz2

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr
    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_npth_() {
    url=https://www.gnupg.org/ftp/gcrypt/npth/npth-1.6.tar.bz2

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr
    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_pinentry_() {
    url=https://www.gnupg.org/ftp/gcrypt/pinentry/pinentry-1.1.0.tar.bz2

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr --enable-pinentry-tty
    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_gnupg_() {
    url=https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-2.2.9.tar.bz2

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    _____________ 'sed -e '/noinst_SCRIPTS = gpg-zip/c sbin_SCRIPTS += gpg-zip' -i tools/Makefile.in'
    sed -e '/noinst_SCRIPTS = gpg-zip/c sbin_SCRIPTS += gpg-zip' -i tools/Makefile.in

    pause_and_run ./configure --prefix=/usr            \
                              --enable-symcryptrun     \
                              --docdir=/usr/share/doc/gnupg-2.2.9
    pause_and_run make

    pause_and_run makeinfo --html --no-split -o doc/gnupg_nochunks.html doc/gnupg.texi
    pause_and_run makeinfo --plaintext       -o doc/gnupg.txt           doc/gnupg.texi
    #make -C doc pdf ps html
    pause_and_run make install

    pause_and_run install -v -m755 -d /usr/share/doc/gnupg-2.2.9/html
    pause_and_run install -v -m644    doc/gnupg_nochunks.html \
                        /usr/share/doc/gnupg-2.2.9/html/gnupg.html
    pause_and_run install -v -m644    doc/*.texi doc/gnupg.txt \
                        /usr/share/doc/gnupg-2.2.9
    # install -v -m644 doc/gnupg.html/* \
    #                  /usr/share/doc/gnupg-2.2.9/html
    # install -v -m644 doc/gnupg.{pdf,dvi,ps} \
    #                  /usr/share/doc/gnupg-2.2.9

    pause_and_run popd
}

_blfs_install_nettle_() {
    url=https://ftp.gnu.org/gnu/nettle/nettle-3.4.tar.gz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr --disable-static
    pause_and_run make

    pause_and_run make install
    pause_and_run chmod   -v   755 /usr/lib/lib{hogweed,nettle}.so
    pause_and_run install -v -m755 -d /usr/share/doc/nettle-3.4
    pause_and_run install -v -m644 nettle.html /usr/share/doc/nettle-3.4

    pause_and_run popd
}

_blfs_install_libunistring_() {
    url=https://ftp.gnu.org/gnu/libunistring/libunistring-0.9.10.tar.xz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr    \
                              --disable-static \
                              --docdir=/usr/share/doc/libunistring-0.9.10
    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_six_() {
    url=https://pypi.io/packages/source/s/six/six-1.11.0.tar.gz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run python2 setup.py build
    pause_and_run python2 setup.py install --optimize=1
    pause_and_run python3 setup.py build
    pause_and_run python3 setup.py install --optimize=1

    pause_and_run popd
}

_blfs_install_libtasn1_() {
    url=https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.13.tar.gz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr --disable-static
    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_p11_kit_() {
    url=https://github.com/p11-glue/p11-kit/releases/download/0.23.13/p11-kit-0.23.13.tar.gz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr     \
                              --sysconfdir=/etc \
                              --with-trust-paths=/etc/pki/anchors
    pause_and_run make
    pause_and_run make install

    _____________ 'if [ -e /usr/lib/libnssckbi.so ]; then
      readlink /usr/lib/libnssckbi.so ||
      rm -v /usr/lib/libnssckbi.so    &&
      ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
    fi'
    if [ -e /usr/lib/libnssckbi.so ]; then
      readlink /usr/lib/libnssckbi.so ||
      rm -v /usr/lib/libnssckbi.so    &&
      ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
    fi

    pause_and_run popd
}

_blfs_install_gnutls_() {
    url=https://www.gnupg.org/ftp/gcrypt/gnutls/v3.5/gnutls-3.5.19.tar.xz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr \
                              --with-default-trust-store-pkcs11="pkcs11:"
    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_gpgme_() {
    url=https://www.gnupg.org/ftp/gcrypt/gpgme/gpgme-1.11.1.tar.bz2

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr --disable-gpg-test
    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_haveged_() {
    url=https://downloads.sourceforge.net/haveged/haveged-1.9.2.tar.gz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr
    pause_and_run make
    pause_and_run make install
    pause_and_run mkdir -pv    /usr/share/doc/haveged-1.9.2
    pause_and_run cp -v README /usr/share/doc/haveged-1.9.2

    pause_and_run popd
}

_blfs_install_systemd_units_() {
    url=http://ftp.osuosl.org/pub/blfs/8.3/b/blfs-systemd-units-20180105.tar.bz2

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pwd

    _____________ 'make install-<systemd-unit>'

    # pause_and_run make install-haveged
    pause_and_run make install-iptables

    pause_and_run popd
}

_blfs_install_iptables_() {
    url=http://www.netfilter.org/projects/iptables/files/iptables-1.8.0.tar.bz2

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run sed -i -e '/libebt_/s/^/#/' \
                         -e '/libarpt_/s/^/#/' extensions/GNUmakefile.in
    pause_and_run ./configure --prefix=/usr      \
                              --sbindir=/sbin    \
                              --disable-nftables \
                              --enable-libipq    \
                              --with-xtlibdir=/lib/xtables
    pause_and_run make
    pause_and_run make install
    pause_and_run ln -sfv ../../sbin/xtables-legacy-multi /usr/bin/iptables-xml

    for file in ip4tc ip6tc ipq iptc xtables
    do
      pause_and_run mv -v /usr/lib/lib${file}.so.* /lib
      pause_and_run ln -sfv ../../lib/$(readlink /usr/lib/lib${file}.so) /usr/lib/lib${file}.so
    done

    pause_and_run cd ../blfs-systemd-units-20180105
    pause_and_run make install-iptables

    pause_and_run popd
}

_blfs_setup_network_firewall() {
    _____________ ''
    _____________ 'skipped'
    _____________ ''
    _____________ 'http://www.linuxfromscratch.org/blfs/view/stable-systemd/postlfs/firewall.html'
    _____________ ''
}

_blfs_install_linux_pam_() {
    url=http://linux-pam.org/library/Linux-PAM-1.3.0.tar.bz2

    pause_and_run pushd /sources/downloads/blfs

    pause_and_run wget http://linux-pam.org/documentation/Linux-PAM-1.2.0-docs.tar.bz2

    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run tar -xf ../Linux-PAM-1.2.0-docs.tar.bz2 --strip-components=1

    pause_and_run ./configure --prefix=/usr                    \
                              --sysconfdir=/etc                \
                              --libdir=/usr/lib                \
                              --disable-regenerate-docu        \
                              --enable-securedir=/lib/security \
                              --docdir=/usr/share/doc/Linux-PAM-1.3.0
    pause_and_run make

    install -v -m755 -d /etc/pam.d

    cat > /etc/pam.d/other << "EOF"
auth     required       pam_deny.so
account  required       pam_deny.so
password required       pam_deny.so
session  required       pam_deny.so
EOF

    pause_and_run make check

    ________________________________________IMPORTANT________________________________________ "
    Ensure there are no errors produced by the tests
    before continuing the installation.

    \033[1m$BLFS_LOG
    "

    _____________ 'run _blfs_install_linux_pam_continued once done'
}

_blfs_install_linux_pam_continued_() {
    pause_and_run pushd /sources/downloads/blfs/Linux-PAM-1.3.0

#    #pause_and_run rm -fv /etc/pam.d/*
#    pause_and_run mv -v /etc/pam.d/* /tmp/
#
#    pause_and_run make install
#    pause_and_run chmod -v 4755 /sbin/unix_chkpwd
#
#    for file in pam pam_misc pamc
#    do
#      pause_and_run mv -v /usr/lib/lib${file}.so.* /lib
#      pause_and_run ln -sfv ../../lib/$(readlink /usr/lib/lib${file}.so) /usr/lib/lib${file}.so
#    done

    pause_and_run install -vdm755 /etc/pam.d
    _____________ '/etc/pam.d/system-account'
    cat > /etc/pam.d/system-account << "EOF"
# Begin /etc/pam.d/system-account

account   required    pam_unix.so

# End /etc/pam.d/system-account
EOF

    _____________ '/etc/pam.d/system-auth'
    cat > /etc/pam.d/system-auth << "EOF"
# Begin /etc/pam.d/system-auth

auth      required    pam_unix.so

# End /etc/pam.d/system-auth
EOF

    _____________ '/etc/pam.d/system-session'
    cat > /etc/pam.d/system-session << "EOF"
# Begin /etc/pam.d/system-session

session   required    pam_unix.so

# End /etc/pam.d/system-session
EOF

    _____________ '/etc/pam.d/system-password'
    cat > /etc/pam.d/system-password << "EOF"
# Begin /etc/pam.d/system-password

# check new passwords for strength (man pam_cracklib)
password  required    pam_cracklib.so   type=Linux retry=3 difok=5 \
                                        difignore=23 minlen=9 dcredit=1 \
                                        ucredit=1 lcredit=1 ocredit=1 \
                                        dictpath=/lib/cracklib/pw_dict
# use sha512 hash for encryption, use shadow, and use the
# authentication token (chosen password) set by pam_cracklib
# above (or any previous modules)
password  required    pam_unix.so       sha512 shadow use_authtok

# End /etc/pam.d/system-password
EOF

    _____________ '/etc/pam.d/other'
    cat > /etc/pam.d/other << "EOF"
# Begin /etc/pam.d/other

auth        required        pam_warn.so
auth        required        pam_deny.so
account     required        pam_warn.so
account     required        pam_deny.so
password    required        pam_warn.so
password    required        pam_deny.so
session     required        pam_warn.so
session     required        pam_deny.so

# End /etc/pam.d/other
EOF

    pause_and_run popd

    ________________________________________NOTE________________________________________ '
    The PAM man page (man pam) provides a good starting point for descriptions
    of fields and allowable entries. The Linux-PAM System Administrators Guide
    http://www.linux-pam.org/Linux-PAM-html/Linux-PAM_SAG.html
    is recommended for additional information.

    see http://www.linuxfromscratch.org/blfs/view/stable-systemd/postlfs/linux-pam.html
    '
}

_blfs_install_shadow_() {
    url=https://github.com/shadow-maint/shadow/releases/download/4.6/shadow-4.6.tar.xz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    _____________ "sed -i 's/groups\$(EXEEXT) //' src/Makefile.in"
                   sed -i 's/groups$(EXEEXT) //' src/Makefile.in

    _____________ "find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;"
                   find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
    _____________ "find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;"
                   find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
    _____________ "find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;"
                   find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

    _____________ "sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \ "
    _____________ "       -e 's@/var/spool/mail@/var/mail@' etc/login.defs"
                   sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
                          -e 's@/var/spool/mail@/var/mail@' etc/login.defs

    _____________ "sed -i 's/1000/999/' etc/useradd"
                   sed -i 's/1000/999/' etc/useradd

    pause_and_run ./configure --sysconfdir=/etc --with-group-name-max-length=32
    pause_and_run make

    pause_and_run make install
    pause_and_run mv -v /usr/bin/passwd /bin

    pause_and_run sed -i 's/yes/no/' /etc/default/useradd

    pause_and_run install -v -m644 /etc/login.defs /etc/login.defs.orig

    for FUNCTION in FAIL_DELAY               \
                    FAILLOG_ENAB             \
                    LASTLOG_ENAB             \
                    MAIL_CHECK_ENAB          \
                    OBSCURE_CHECKS_ENAB      \
                    PORTTIME_CHECKS_ENAB     \
                    QUOTAS_ENAB              \
                    CONSOLE MOTD_FILE        \
                    FTMP_FILE NOLOGINS_FILE  \
                    ENV_HZ PASS_MIN_LEN      \
                    SU_WHEEL_ONLY            \
                    CRACKLIB_DICTPATH        \
                    PASS_CHANGE_TRIES        \
                    PASS_ALWAYS_WARN         \
                    CHFN_AUTH ENCRYPT_METHOD \
                    ENVIRON_FILE
    do
        _____________ 'sed -i "s/^'${FUNCTION}'/# &/" /etc/login.defs'
        sed -i "s/^${FUNCTION}/# &/" /etc/login.defs
    done

    cat > /etc/pam.d/login << "EOF"
# Begin /etc/pam.d/login

# Set failure delay before next prompt to 3 seconds
auth      optional    pam_faildelay.so  delay=3000000

# Check to make sure that the user is allowed to login
auth      requisite   pam_nologin.so

# Check to make sure that root is allowed to login
# Disabled by default. You will need to create /etc/securetty
# file for this module to function. See man 5 securetty.
#auth      required    pam_securetty.so

# Additional group memberships - disabled by default
#auth      optional    pam_group.so

# include the default auth settings
auth      include     system-auth

# check access for the user
account   required    pam_access.so

# include the default account settings
account   include     system-account

# Set default environment variables for the user
session   required    pam_env.so

# Set resource limits for the user
session   required    pam_limits.so

# Display date of last login - Disabled by default
#session   optional    pam_lastlog.so

# Display the message of the day - Disabled by default
#session   optional    pam_motd.so

# Check user's mail - Disabled by default
#session   optional    pam_mail.so      standard quiet

# include the default session and password settings
session   include     system-session
password  include     system-password

# End /etc/pam.d/login
EOF

    cat > /etc/pam.d/passwd << "EOF"
# Begin /etc/pam.d/passwd

password  include     system-password

# End /etc/pam.d/passwd
EOF

    cat > /etc/pam.d/su << "EOF"
# Begin /etc/pam.d/su

# always allow root
auth      sufficient  pam_rootok.so
auth      include     system-auth

# include the default account settings
account   include     system-account

# Set default environment variables for the service user
session   required    pam_env.so

# include system session defaults
session   include     system-session

# End /etc/pam.d/su
EOF

    cat > /etc/pam.d/chage << "EOF"
# Begin /etc/pam.d/chage

# always allow root
auth      sufficient  pam_rootok.so

# include system defaults for auth account and session
auth      include     system-auth
account   include     system-account
session   include     system-session

# Always permit for authentication updates
password  required    pam_permit.so

# End /etc/pam.d/chage
EOF

    for PROGRAM in chfn chgpasswd chpasswd chsh groupadd groupdel \
                   groupmems groupmod newusers useradd userdel usermod
    do
        pause_and_run install -v -m644 /etc/pam.d/chage /etc/pam.d/${PROGRAM}
        pause_and_run sed -i "s/chage/$PROGRAM/" /etc/pam.d/${PROGRAM}
    done


    rm -f /run/nologin

    ________________________________________IMPORTANT________________________________________ '
    At this point, you should do a simple test to see if Shadow is working as expected. Open another terminal and log in as a user, then su to root. If you do not see any errors, then all is well and you should proceed with the rest of the configuration. If you did receive errors, stop now and double check the above configuration files manually. You can also run the test suite from the Linux-PAM package to assist you in determining the problem. If you cannot find and fix the error, you should recompile Shadow adding the --without-libpam switch to the configure command in the above instructions (also move the /etc/login.defs.orig backup file to /etc/login.defs). If you fail to do this and the errors remain, you will be unable to log into your system.'

    _____________ '[ -f /etc/login.access ] && mv -v /etc/login.access{,.NOUSE}'
    [ -f /etc/login.access ] && mv -v /etc/login.access{,.NOUSE}

    _____________ '[ -f /etc/limits ] && mv -v /etc/limits{,.NOUSE}'
    [ -f /etc/limits ] && mv -v /etc/limits{,.NOUSE}

    pause_and_run popd
}

_blfs_install_sudo_() {
    #url=http://www.sudo.ws/dist/sudo-1.8.23.tar.gz

    #pause_and_run pushd /sources/downloads/blfs
    #pause_and_run _blfs_download_extract_and_enter $url

    ________________________________________________________________________________ '
    ./configure --prefix=/usr              \
                --libexecdir=/usr/lib      \
                --with-secure-path         \
                --with-all-insults         \
                --with-env-editor          \
                --docdir=/usr/share/doc/sudo-1.8.23 \
                --with-passprompt="[sudo] password for %p: "
    '
    ./configure --prefix=/usr              \
                --libexecdir=/usr/lib      \
                --with-secure-path         \
                --with-all-insults         \
                --with-env-editor          \
                --docdir=/usr/share/doc/sudo-1.8.23 \
                --with-passprompt="[sudo] password for %p: "
    pause_and_run make
    
    pause_and_run make install
    pause_and_run ln -sfv libsudo_util.so.0.0.0 /usr/lib/sudo/libsudo_util.so.0

    cat > /etc/pam.d/sudo << "EOF"
# Begin /etc/pam.d/sudo

# include the default auth settings
auth      include     system-auth

# include the default account settings
account   include     system-account

# Set default environment variables for the service user
session   required    pam_env.so

# include system session defaults
session   include     system-session

# End /etc/pam.d/sudo
EOF

    pause_and_run chmod 644 /etc/pam.d/sudo

    pause_and_run popd

    echo -e "\033[35mnow use \033[31mvisudo\033[0;35m to modify \033[31m/etc/sudoers\033[0m"

    ________________________________________NOTE________________________________________ '
# User alias specification
User_Alias  ADMIN = yyu

# Allow people in group ADMIN to run all commands without a password
ADMIN       ALL = NOPASSWD: ALL
'
}

_blfs_install_pcre_() {
    url=https://ftp.pcre.org/pub/pcre/pcre-8.42.tar.bz2

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run ./configure --prefix=/usr                     \
                              --docdir=/usr/share/doc/pcre-8.42 \
                              --enable-unicode-properties       \
                              --enable-pcre16                   \
                              --enable-pcre32                   \
                              --enable-pcregrep-libz            \
                              --enable-pcregrep-libbz2          \
                              --enable-pcretest-libreadline     \
                              --disable-static
    pause_and_run make
    pause_and_run make install
    pause_and_run mv -v /usr/lib/libpcre.so.* /lib
    pause_and_run ln -sfv ../../lib/$(readlink /usr/lib/libpcre.so) /usr/lib/libpcre.so

    pause_and_run popd
}

_blfs_install_glib_() {
    url=http://ftp.gnome.org/pub/gnome/sources/glib/2.56/glib-2.56.1.tar.xz

    pause_and_run pushd /sources/downloads/blfs

    pause_and_run wget http://www.linuxfromscratch.org/patches/blfs/8.3/glib-2.56.1-skip_warnings-1.patch

    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run patch -Np1 -i ../glib-2.56.1-skip_warnings-1.patch
    pause_and_run ./configure --prefix=/usr      \
                              --with-pcre=system \
                              --with-python=/usr/bin/python3
    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_nspr_() {
    url=https://archive.mozilla.org/pub/nspr/releases/v4.19/src/nspr-4.19.tar.gz

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    ________________________________________________________________________________ '
    cd nspr                                                     &&
    sed -ri s#^(RELEASE_BINS =).*#\1# pr/src/misc/Makefile.in &&
    sed -i s#$(LIBRARY) ##            config/rules.mk

    ./configure --prefix=/usr \
                --with-mozilla \
                --with-pthreads \
                $([ $(uname -m) = x86_64 ] && echo --enable-64bit) &&
    '
    cd nspr                                                     &&
    sed -ri 's#^(RELEASE_BINS =).*#\1#' pr/src/misc/Makefile.in &&
    sed -i 's#$(LIBRARY) ##'            config/rules.mk

    ./configure --prefix=/usr \
                --with-mozilla \
                --with-pthreads \
                $([ $(uname -m) = x86_64 ] && echo --enable-64bit) &&

    pause_and_run make
    pause_and_run make install

    pause_and_run popd
}

_blfs_install_openssh_() {
    url=http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.7p1.tar.gz

    pause_and_run pushd /sources/downloads/blfs

    pause_and_run wget http://www.linuxfromscratch.org/patches/blfs/8.3/openssh-7.7p1-openssl-1.1.0-1.patch

    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run install  -v -m700 -d /var/lib/sshd
    pause_and_run chown    -v root:sys /var/lib/sshd

    pause_and_run groupadd -g 50 sshd
    ________________________________________________________________________________ "
    useradd  -c 'sshd PrivSep' \
             -d /var/lib/sshd  \
             -g sshd           \
             -s /bin/false     \
             -u 50 sshd
    "
    useradd  -c 'sshd PrivSep' \
             -d /var/lib/sshd  \
             -g sshd           \
             -s /bin/false     \
             -u 50 sshd

    pause_and_run patch -Np1 -i ../openssh-7.7p1-openssl-1.1.0-1.patch

    pause_and_run ./configure --prefix=/usr                     \
                              --sysconfdir=/etc/ssh             \
                              --with-md5-passwords              \
                              --with-privsep-path=/var/lib/sshd
    pause_and_run make

    pause_and_run make install
    pause_and_run install -v -m755    contrib/ssh-copy-id /usr/bin

    pause_and_run install -v -m644    contrib/ssh-copy-id.1 \
                                      /usr/share/man/man1
    pause_and_run install -v -m755 -d /usr/share/doc/openssh-7.7p1
    pause_and_run install -v -m644    INSTALL LICENCE OVERVIEW README* \
                                      /usr/share/doc/openssh-7.7p1

    ________________________________________________________________________________ '
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    pause_and_run ssh-keygen
    ssh-copy-id -i ~/.ssh/id_rsa.pub REMOTE_USERNAME@REMOTE_HOSTNAME
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
    sed 's@d/login@d/sshd@g' /etc/pam.d/login > /etc/pam.d/sshd
    pause_and_run chmod 644 /etc/pam.d/sshd
    echo "UsePAM yes" >> /etc/ssh/sshd_config
    '

    pause_and_run cd ../blfs-systemd-units-20180105
    pause_and_run make install-sshd

    pause_and_run popd
}

_blfs_install___() {
    url=

    pause_and_run pushd /sources/downloads/blfs
    pause_and_run _blfs_download_extract_and_enter $url

    pause_and_run 
    pause_and_run 
    pause_and_run ./configure --prefix=/usr
    pause_and_run make
    pause_and_run make install
    pause_and_run 
    pause_and_run 

    pause_and_run popd
}

_blfs_one_off_install_() {
    echo
    ________________________________________________________________________________ '
    cd nspr                                                     &&
    sed -ri s#^(RELEASE_BINS =).*#\1# pr/src/misc/Makefile.in &&
    sed -i s#$(LIBRARY) ##            config/rules.mk

    ./configure --prefix=/usr \
                --with-mozilla \
                --with-pthreads \
                $([ $(uname -m) = x86_64 ] && echo --enable-64bit) &&
    '
}

_blfs_install_libuv() {
    _log_ _blfs_install_libuv_
}

_blfs_install_cmake() {
    _log_ _blfs_install_cmake_
}

_blfs_install_libarchive() {
    _log_ _blfs_install_libarchive_
}

_blfs_install_valgrind() {
    _log_ _blfs_install_valgrind_
}

_blfs_install_which() {
    _log_ _blfs_install_which_
}

_blfs_install_python27() {
    _log_ _blfs_install_python27_
}

_blfs_install_llvm() {
    _log_ _blfs_install_llvm_
}

_blfs_install_python37() {
    _log_ _blfs_install_python37_
}

_blfs_one_off_install() {
    _log_ _blfs_one_off_install_
}

_blfs_install_libxml() {
    _log_ _blfs_install_libxml_
}

_blfs_install_doxygen() {
    _log_ _blfs_install_doxygen_
}

_blfs_install_berkeleydb() {
    _log_ _blfs_install_berkeleydb_
}

_blfs_install_cyrus_sasl() {
    _log_ _blfs_install_cyrus_sasl_
}

_blfs_kernel_build_config_for_lvm2() {
    _log_ _blfs_kernel_build_config_for_lvm2_
}

_blfs_kernel_build_config_check() {
    _log_ _blfs_kernel_build_config_check_
}

_blfs_kernel_build() {
    _log_ _blfs_kernel_build_
}

_blfs_kernel_post_build() {
    _log_ _blfs_kernel_post_build_
}

_blfs_install_lvm2() {
    _log_ _blfs_install_lvm2_
}

_blfs_install_libgpg_error() {
    _log_ _blfs_install_libgpg_error_
}

_blfs_install_libgcrypt() {
    _log_ _blfs_install_libgcrypt_
}

_blfs_install_cryptsetup() {
    _log_ _blfs_install_cryptsetup_
}

_blfs_kernel_build_config_for_cryptsetup() {
    _log_ _blfs_kernel_build_config_for_cryptsetup_
}

_blfs_kernel_build_config_check_for_cryptsetup() {
    _log_ _blfs_kernel_build_config_check_for_cryptsetup_
}

_blfs_install_libassuan() {
    _log_ _blfs_install_libassuan_
}

_blfs_install_libksba() {
    _log_ _blfs_install_libksba_
}

_blfs_install_npth() {
    _log_ _blfs_install_npth_
}

_blfs_install_pinentry() {
    _log_ _blfs_install_pinentry_
}

_blfs_install_gnupg() {
    _log_ _blfs_install_gnupg_
}

_blfs_install_nettle() {
    _log_ _blfs_install_nettle_
}

_blfs_install_libunistring() {
    _log_ _blfs_install_libunistring_
}

_blfs_install_six() {
    _log_ _blfs_install_six_
}

_blfs_install_libtasn1() {
    _log_ _blfs_install_libtasn1_
}

_blfs_install_p11_kit() {
    _log_ _blfs_install_p11_kit_
}

_blfs_install_gnutls() {
    _log_ _blfs_install_gnutls_
}

_blfs_install_gpgme() {
    _log_ _blfs_install_gpgme_
}

_blfs_install_haveged() {
    _log_ _blfs_install_haveged_
}

_blfs_install_systemd_units() {
    _log_ _blfs_install_systemd_units_
}

_blfs_install_iptables() {
    _log_ _blfs_install_iptables_
}

_blfs_install_linux_pam() {
    _log_ _blfs_install_linux_pam_
}

_blfs_install_linux_pam_continued() {
    _log_ _blfs_install_linux_pam_continued_
}

_blfs_install_shadow() {
    _log_ _blfs_install_shadow_
}

_blfs_install_sudo() {
    _log_ _blfs_install_sudo_
}

_blfs_install_pcre() {
    _log_ _blfs_install_pcre_
}

_blfs_install_glib() {
    _log_ _blfs_install_glib_
}

_blfs_install_nspr() {
    _log_ _blfs_install_nspr_
}

_blfs_install_openssh() {
    _log_ _blfs_install_openssh_
}
