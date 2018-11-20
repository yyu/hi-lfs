## source me, don't run me

export LFS_PARTITION=/dev/sdb

export LFS_VERSION="stable-systemd"

################################################################################

_lfs_refresh_functions() {
    (su -c 'rm -rf /tmp/hi-lfs && cp -r /media/sf_hi-lfs/ /tmp/hi-lfs && chown -R lfs /tmp/hi-lfs' root) && . /tmp/hi-lfs/8.3-systemd/000-functions.sh
}

################################################################################
# 2.5. Creating a File System on the Partition
#
_lfs_mkfs() {
    # LFS assumes that the root file system (/) is of type ext4.
    # To create an ext4 file system on the LFS partition, run the following:
    mkfs -v -t ext4 $LFS_PARTITION
}

################################################################################
# 2.6. Setting The $LFS Variable
#
# You should ensure that this variable is always defined throughout the LFS build process.
# It should be set to the name of the directory where you will be building your LFS system
#
# ~/.bash_profile vs ~/.bashrc
# - If the shell specified in the /etc/passwd file is bash, ~/.bash_profile file is incorporated as a part of the login process
# - If logging in through a graphical display manager, ~/.bash_profile is not normally used when a virtual terminal is started.
#   In this case, add the export command to the .bashrc file for the user and root.
#   In addition, some distributions have instructions to not run the .bashrc instructions in a non-interactive bash invocation.
#   Be sure to add the export command before the test for non-interactive use.
export LFS=/mnt/lfs

################################################################################
# 2.7. Mounting the New Partition
_lfs_mount_fs() {
    #Create the mount point and mount the LFS file system by running:
    mkdir -pv $LFS
    mount -v -t ext4 $LFS_PARTITION $LFS
}

################################################################################
# Chapter 3. Packages and Patches

export LFS_SOURCES_DIR=$LFS/sources
export LFS_EXTRA_PATCHES_DIR=$LFS_SOURCES_DIR/extra-patches

_lfs_get_packages_and_patches() {
    mkdir -pv $LFS_SOURCES_DIR

    # Make this directory writable and sticky.
    # “Sticky” means that even if multiple users have write permission on a directory,
    # only the owner of a file can delete the file within a sticky directory.
    chmod -v a+wt $LFS_SOURCES_DIR

    if [ ! -f $LFS_SOURCES_DIR/wget-list ]; then
        for f in wget-list md5sums; do
            wget http://www.linuxfromscratch.org/lfs/downloads/$LFS_VERSION/$f -O $LFS_SOURCES_DIR/$f
        done

        wget --input-file=$LFS_SOURCES_DIR/wget-list --continue --directory-prefix=$LFS_SOURCES_DIR

        pushd $LFS_SOURCES_DIR
        md5sum -c md5sums
        popd
    fi

    # In addition to the above required patches, there exist a number of optional patches created by the LFS community.
    # These optional patches solve minor problems or enable functionality that is not enabled by default.
    # Feel free to peruse the patches database located at http://www.linuxfromscratch.org/patches/downloads/
    # and acquire any additional patches to suit your system needs.

    mkdir -pv $LFS_EXTRA_PATCHES_DIR  # comment me to download extra patches

    if [ ! -d $LFS_EXTRA_PATCHES_DIR ]; then
        mkdir -v $LFS_EXTRA_PATCHES_DIR
        pushd $LFS_EXTRA_PATCHES_DIR
        wget --recursive --no-parent --continue http://www.linuxfromscratch.org/patches/downloads/
        popd
    fi
}

################################################################################
# 4.2. Creating the $LFS/tools Directory

export LFS_TOOLS_DIR=$LFS/tools

_lfs_setup_tools_directory() {
    mkdir -v $LFS_TOOLS_DIR

    # create a /tools symlink on the host system
    ln -sv $LFS_TOOLS_DIR /
    # The created symlink enables the toolchain to be compiled so that it always refers to /tools,
    # meaning that the compiler, assembler, and linker will work both
    # * in Chapter 5 (when we are still using some tools from the host)
    # * and in the next (when we are “chrooted” to the LFS partition)
}

################################################################################
# 4.3. Adding the LFS User

export LFS_USER=lfs
export LFS_GROUP=lfs

# create a new user called lfs as a member of a new group (also named lfs) and use this user during the installation process

_lfs_setup_user_and_group() {
    groupadd $LFS_GROUP

    # -s /bin/bash
    #     This makes bash the default shell for user lfs.
    #
    # -g lfs
    #     This option adds user lfs to group lfs.
    #
    # -m
    #     This creates a home directory for lfs.
    #
    # -k /dev/null
    #     This parameter prevents possible copying of files from a skeleton directory (default is /etc/skel) by changing the input location to the special null device.
    useradd -s /bin/bash -g $LFS_GROUP -m -k /dev/null $LFS_USER

    if [ $? -eq 0 ]; then
        passwd $LFS_USER
    fi

    chown -v $LFS_USER $LFS_TOOLS_DIR
    chown -v $LFS_USER $LFS_SOURCES_DIR

    # login as user lfs
    # The “-” instructs su to start a login shell as opposed to a non-login shell.
    # The difference between these two types of shells can be found in detail in bash(1) and info bash.
    su - $LFS_USER
}

################################################################################
# 4.4. Setting Up the Environment

_lfs_setup_env() {

    # While logged in as user lfs, issue the following command to create a new .bash_profile
    # which replaces the running shell with a new one with a completely empty environment, except for the HOME, TERM, and PS1 variables
    # This ensures that no unwanted and potentially hazardous environment variables from the host system leak into the build environment.
    # The technique used here achieves the goal of ensuring a clean environment.
    cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

    # The new instance of the shell is a non-login shell, which does not read the /etc/profile or .bash_profile files, but rather reads the .bashrc file instead.
    cat > ~/.bashrc << "EOF"
set +h      # turns off bash's hash function
umask 022   # ensures that newly created files and directories are only writable by their owner, but are readable and executable by anyone
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
alias ll='ls -lah --color=auto'
export LFS LC_ALL LFS_TGT PATH
EOF
    # The set +h command turns off bash's hash function.
    # Hashing is ordinarily a useful feature—bash uses a hash table to remember the full path
    # of executable files to avoid searching the PATH time and again to find the same executable.
    # However, the new tools should be used as soon as they are installed.
    # By switching off the hash function, the shell will always search the PATH when a program is to be run.
    # As such, the shell will find the newly compiled tools in $LFS/tools as soon as they are available
    # without remembering a previous version of the same program in a different location.
    #
    # Setting the user file-creation mask (umask) to 022 ensures that newly created files and directories are only writable by their owner,
    # but are readable and executable by anyone (assuming default modes are used by the open(2) system call,
    # new files will end up with permission mode 644 and directories with mode 755).
    #
    # The LC_ALL variable controls the localization of certain programs, making their messages follow the conventions of a specified country.
    # Setting LC_ALL to “POSIX” or “C” (the two are equivalent) ensures that everything will work as expected in the chroot environment.
    #
    # The LFS_TGT variable sets a non-default, but compatible machine description for use when building our cross compiler and linker
    # and when cross compiling our temporary toolchain. More information is contained in Section 5.2, “Toolchain Technical Notes”.
    #
    # putting /tools/bin ahead of the standard PATH ... combined with turning off hashing,
    # limits the risk that old programs are used from the host when the same programs are available in the chapter 5 environment.

    source ~/.bash_profile
}

################################################################################
# Chapter 5. Constructing a Temporary System
# 5.2. Toolchain Technical Notes

_lfs_get_target_triplets() {
    set -e

    # Before continuing, be aware of the name of the working platform, often referred to as the target triplet.
    # A simple way to determine the name of the target triplet is to run the config.guess script that comes with the source for many packages.
    package=binutils
    package_with_version=${package}-2.31.1
    package_file=$package_with_version.tar.xz
    url=http://ftp.gnu.org/gnu/$package/$package_file
    target_triplets_work_folder=~/___/target-triplets

    mkdir -pv $target_triplets_work_folder
    pushd $target_triplets_work_folder

    wget $url
    # Unpack the Binutils sources and run the script: ./config.guess and note the output.
    tar xJf $package_file
    cd $package_with_version
    # For example, for a 32-bit Intel processor the output will be i686-pc-linux-gnu. On a 64-bit system it will be x86_64-pc-linux-gnu.
    ./config.guess

    popd
    set +e
}

_lfs_get_name_of_dynamic_linker_() {
    # Also be aware of the name of the platform's dynamic linker, often referred to as the dynamic loader
    # (not to be confused with the standard linker ld that is part of Binutils).
    # The dynamic linker provided by Glibc finds and loads the shared libraries needed by a program, prepares the program to run, and then runs it.
    # The name of the dynamic linker for a 32-bit Intel machine will be ld-linux.so.2 (ld-linux-x86-64.so.2 for 64-bit systems).
    random_binary=$1
    # A sure-fire way to determine the name of the dynamic linker is to inspect a random binary from the host system by running:
    readelf -l $random_binary | grep interpreter
    # The authoritative reference covering all platforms is in the shlib-versions file in the root of the Glibc source tree.
}

_lfs_get_name_of_dynamic_linker() {
    random_binary=/bin/cp
    _lfs_get_name_of_dynamic_linker_ $random_binary
}

################################################################################

_lfs_start_until_user_and_group() {
    _lfs_mkfs
    _lfs_mount_fs
    _lfs_get_packages_and_patches
    _lfs_setup_tools_directory
    _lfs_setup_user_and_group
}

_lfs_continue() {
    _lfs_setup_env
    _lfs_get_name_of_dynamic_linker
}

################################################################################
