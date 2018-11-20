## source me, don't run me

export LFS_PARTITION=/dev/sdb

export LFS_VERSION="8.3-rc2"

################################################################################
# 2.5. Creating a File System on the Partition
#
_lfs_mkfs() {
    LFS_PARTITION=$1

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
