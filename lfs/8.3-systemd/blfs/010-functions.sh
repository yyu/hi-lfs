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

_lfs_sleep() {
    sleep 3
}

________________________________________________________________________________() {
    echo -e "\033[1;3;32m"'________________________________________________________________________________' | tee -a $LFS_LOG
    echo -e "$1" | tee -a $LFS_LOG
    echo -e '................................................................................'"\033[0m" | tee -a $LFS_LOG
    _lfs_sleep
}

________________________________________there_should_have________________________________________() {
    echo -e "\033[0;3;36m$1" | tee -a $LFS_LOG
    echo -e "\033[0;1;36m$2" | tee -a $LFS_LOG
    echo -e "\033[0;3;35m$3" | tee -a $LFS_LOG
    echo -e "\033[0;1;35m$4" | tee -a $LFS_LOG
    echo -e "\033[0m" | tee -a $LFS_LOG
    _lfs_sleep
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
    _lfs_sleep
}

________________________________________NOTE________________________________________() {
    ________________________________________HIGHLIGHT________________________________________ 33 Note "$1" "$2"
}

________________________________________IMPORTANT________________________________________() {
    ________________________________________HIGHLIGHT________________________________________ 31 Important "$1" "$2"
}

