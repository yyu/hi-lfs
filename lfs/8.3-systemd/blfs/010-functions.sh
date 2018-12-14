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
