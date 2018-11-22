## source me, don't run me

export LFS_PARTITION=/dev/sdb

export LFS_VERSION="stable-systemd"

################################################################################

_lfs_sleep() {
    sleep 3
}

________________________________________________________________________________() {
    echo -e "\033[1;3;32m"'________________________________________________________________________________'
    echo -e $1
    echo -e '................................................................................'"\033[0m"
    _lfs_sleep
}

________________________________________there_should_have________________________________________() {
    echo -e "\033[0;3;36m"$1
    echo -e "\033[0;1;36m"$2
    echo -e "\033[0;3;35m"$3
    echo -e "\033[0;1;35m"$4
    echo -e "\033[0m"
    _lfs_sleep
}

________________________________________NOTE________________________________________() {
    color=33
    echo -e "\033[7;${color}mNote\033[0m\033[${color}m__________________________________________________\033[0m"
    echo -e "\033[0;${color}m"$1
    echo -e "\033[0;1;${color}m"$2
    echo -e "\033[0m"
    _lfs_sleep
}

________________________________________IMPORTANT________________________________________() {
    color=31
    echo -e "\033[7;${color}mImportant\033[0m\033[${color}m__________________________________________________\033[0m"
    echo -e "\033[0;${color}m"$1
    echo -e "\033[0;1;${color}m"$2
    echo -e "\033[0m"
    _lfs_sleep
}

_lfs_refresh_functions() {
    (su -c 'rm -rf /tmp/hi-lfs && cp -r /media/sf_hi-lfs/ /tmp/hi-lfs && chown -R lfs /tmp/hi-lfs' root) && . /tmp/hi-lfs/8.3-systemd/000-functions.sh
}

################################################################################
# 2.2. Host System Requirements

# To see whether your host system has all the appropriate versions, and the ability to compile programs
_lfs_version_check() {
    # Simple script to list version numbers of critical development tools

    export LC_ALL=C
    bash --version | head -n1 | cut -d" " -f2-4
    MYSH=$(readlink -f /bin/sh)
    echo "/bin/sh -> $MYSH"
    echo $MYSH | grep -q bash || echo "ERROR: /bin/sh does not point to bash"
    unset MYSH

    echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
    bison --version | head -n1

    if [ -h /usr/bin/yacc ]; then
      echo "/usr/bin/yacc -> `readlink -f /usr/bin/yacc`";
    elif [ -x /usr/bin/yacc ]; then
      echo yacc is `/usr/bin/yacc --version | head -n1`
    else
      echo "yacc not found"
    fi

    bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f1,6-
    echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2
    diff --version | head -n1
    find --version | head -n1
    gawk --version | head -n1

    if [ -h /usr/bin/awk ]; then
      echo "/usr/bin/awk -> `readlink -f /usr/bin/awk`";
    elif [ -x /usr/bin/awk ]; then
      echo awk is `/usr/bin/awk --version | head -n1`
    else
      echo "awk not found"
    fi

    gcc --version | head -n1
    g++ --version | head -n1
    ldd --version | head -n1 | cut -d" " -f2-  # glibc version
    grep --version | head -n1
    gzip --version | head -n1
    cat /proc/version
    m4 --version | head -n1
    make --version | head -n1
    patch --version | head -n1
    echo Perl `perl -V:version`
    sed --version | head -n1
    tar --version | head -n1
    makeinfo --version | head -n1
    xz --version | head -n1

    echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
    if [ -x dummy ]
      then echo "g++ compilation OK";
      else echo "g++ compilation failed"; fi
    rm -f dummy.c dummy
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

_lfs_get_ld_search_order() {
    # linker's library search order can be obtained from ld by passing it the --verbose flag.
    for d in `ld --verbose | grep SEARCH`; do
        echo -e "\033[36m"$d"\033[0m"
    done
}

_lfs_show_linked_files_for_dummy_program() {
    # show all the files successfully opened during the linking.
    echo 'int main(){}' > dummy.c && gcc dummy.c -Wl,--verbose 2>&1 | grep succeeded
}

_lfs_show_linker_used_by_gcc() {
    # find out which standard linker gcc will use
    gcc -print-prog-name=ld
}

_lfs_gcc_dummy_program_verbose() {
    # show detailed information about the preprocessor, compilation, and assembly stages, including gcc's included search paths and their order.
    echo 'int main(){}' > dummy.c && gcc -v dummy.c
}

################################################################################
# 5.3. General Compilation Instructions

_lfs_general_compilation_instruction_1() {
    echo -e "\
        | \033[7;31mImportant\033[0m\033[31m__________________________________________________\033[0m
        | \033[31mThe build instructions assume that the Host System Requirements,
        | including symbolic links, have been set properly\033[0m:
        | * \033[1;31mbash\033[0;31m is the shell in use\033[0m.
        | * \033[1;31msh\033[0;31m is a symbolic link to \033[1mbash\033[0m.
        | * \033[1;31m/usr/bin/awk\033[0;31m is a symbolic link to gawk\033[0m.
        | * \033[1;31m/usr/bin/yacc\033[0;31m is a symbolic link to \033[1;31mbison\033[0;31m or a small script that executes bison\033[0m.
        | " | sed -E 's/^ *\| //g'
}

_lfs_general_compilation_instruction_2() {
    echo -e "\
        | \033[7;31mImportant\033[0m\033[31m__________________________________________________\033[0m
        | 1. \033[0;31mPlace all the sources and patches in a directory that will be accessible
        |    from the chroot environment such as \033[1;31m/mnt/lfs/sources/\033[0m.
        |    \033[0;31mDo \033[3mnot \033[0;9;31mput sources in \033[1;31m/mnt/lfs/tools/\033[0m.
        | 2. \033[0;31mChange to the sources directory\033[0m.
        | 3. \033[0;31mFor each package\033[0m:
        |    a. \033[0;31mUsing the \033[1mtar\033[0;31m program, extract the package to be built.
        |       In Chapter 5, ensure you are the \033[1;3mlfs\033[0;31m user when extracting the package\033[0m.
        |    b. \033[0;31mChange to the directory created when the package was extracted\033[0m.
        |    c. \033[0;31mFollow the book's instructions for building the package\033[0m.
        |    d. \033[0;31mChange back to the sources directory\033[0m.
        |    e. \033[0;31mDelete the extracted source directory unless instructed otherwise\033[0m.
        | " | sed -E 's/^ *\| //g'
}

################################################################################

_lfs_before_chapter5_build() {
    echo -e "\n\033[32mLFS environment variable: \033[1;32m"$LFS"\033[0m\n"
    _lfs_version_check
    echo
    _lfs_general_compilation_instruction_1
    _lfs_general_compilation_instruction_2
}

_lfs_chapter5_build_all_1() {
    _lfs_install_binutils_pass1
    _lfs_install_gcc_pass1
    _lfs_install_linux_api_headers
    _lfs_install_glibc
    _lfs_toolchain_sanity_check
}

_lfs_chapter5_build_all_2() {
    _lfs_install_libstdcxx_from_gcc
    _lfs_install_binutils_pass2
    _lfs_install_gcc_pass2
    _lfs_install_tcl
    _lfs_install_expect
    _lfs_install_dejagnu
    _lfs_install_m4
    _lfs_install_ncurses
    _lfs_install_bash
    _lfs_install_bison
    _lfs_install_bzip2
    _lfs_install_coreutils
    _lfs_install_diffutils
    _lfs_install_file
    _lfs_install_findutils
    _lfs_install_gawk
    _lfs_install_gettext
    _lfs_install_grep
    _lfs_install_gzip
    _lfs_install_make
    _lfs_install_patch
    _lfs_install_perl
    _lfs_install_sed
    _lfs_install_tar
    _lfs_install_texinfo
    _lfs_install_util-linux
    _lfs_install_xz
}

_lfs_get_package_file_name() {
    pack=$1
    source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
    grep "/"$pack"-" $source_dir/wget-list | sed -e "s/.*\///g" | head -n 1
}

_lfs_get_package_folder_name() {
    pack=$1
    _lfs_get_package_file_name $pack | sed -E 's/\.tar\..*//g'
}

_lfs_get_package_filename_foldername_test() {
    for pack in binutils coreutils; do
        filename=`_lfs_get_package_file_name $pack`
        foldername=`_lfs_get_package_folder_name $pack`
        echo -e "\033[36mtar xJf $filename\033[0m"
        echo -e "\033[36mcd $foldername\033[0m"
    done
}

################################################################################
# 5.4. Binutils-2.31.1 - Pass 1

# The Binutils package contains a linker, an assembler, and other tools for handling object files.

_lfs_install_binutils_pass1() {
    cd $LFS_SOURCES_DIR
    tar xJf binutils-2.31.1.tar.xz
    cd binutils-2.31.1

    mkdir -v build
    cd       build

    ../configure --prefix=/tools            \
                 --with-sysroot=$LFS        \
                 --with-lib-path=/tools/lib \
                 --target=$LFS_TGT          \
                 --disable-nls              \
                 --disable-werror
    make
    case $(uname -m) in
        x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
    esac
    make install
}

################################################################################
# 5.5. GCC-8.2.0 - Pass 1

# The GCC package contains the GNU compiler collection, which includes the C and C++ compilers.

_lfs_install_gcc_pass1() {
    cd $LFS_SOURCES_DIR
    tar xf gcc-8.2.0.tar.xz
    cd gcc-8.2.0

    # GCC now requires the GMP, MPFR and MPC packages.
    # As these packages may not be included in your host distribution, they will be built with GCC.
    # Unpack each package into the GCC source directory and rename the resulting directories so the GCC build procedures will automatically use them:
    tar -xf ../mpfr-4.0.1.tar.xz
    mv -v mpfr-4.0.1 mpfr
    tar -xf ../gmp-6.1.2.tar.xz
    mv -v gmp-6.1.2 gmp
    tar -xf ../mpc-1.1.0.tar.gz
    mv -v mpc-1.1.0 mpc

    # The following command will change the location of GCC's default dynamic linker to use the one installed in /tools.
    # It also removes /usr/include from GCC's include search path. Issue:
    for file in gcc/config/{linux,i386/linux{,64}}.h
    do
        # copy the files gcc/config/linux.h, gcc/config/i386/linux.h, and gcc/config/i368/linux64.h
        # to a file of the same name but with an added suffix of “.orig”
        cp -uv $file{,.orig}
        # the first sed expression prepends “/tools” to every instance of “/lib/ld”, “/lib64/ld” or “/lib32/ld”, while
        # the second one replaces hard-coded instances of “/usr”
        sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
            -e 's@/usr@/tools@g' $file.orig > $file
        # add our define statements which alter the default startfile prefix to the end of the file.
        # Note that the trailing “/” in “/tools/lib/” is required
        echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
        # use touch to update the timestamp on the copied files.
        # When used in conjunction with cp -u, this prevents unexpected changes to the original files in case the commands are inadvertently run twice
        touch $file.orig
    done

    # Finally, on x86_64 hosts, set the default directory name for 64-bit libraries to “lib”:
    case $(uname -m) in
      x86_64)
        sed -e '/m64=/s/lib64/lib/' \
            -i.orig gcc/config/i386/t-linux64
     ;;
    esac

    # The GCC documentation recommends building GCC in a dedicated build directory:
    mkdir -v build
    cd       build

    ../configure                                       \
        --target=$LFS_TGT                              \
        --prefix=/tools                                \
        --with-glibc-version=2.11                      \
        --with-sysroot=$LFS                            \
        --with-newlib                                  \
        --without-headers                              \
        --with-local-prefix=/tools                     \
        --with-native-system-header-dir=/tools/include \
        --disable-nls                                  \
        --disable-shared                               \
        --disable-multilib                             \
        --disable-decimal-float                        \
        --disable-threads                              \
        --disable-libatomic                            \
        --disable-libgomp                              \
        --disable-libmpx                               \
        --disable-libquadmath                          \
        --disable-libssp                               \
        --disable-libvtv                               \
        --disable-libstdcxx                            \
        --enable-languages=c,c++
    make
    make install
}

################################################################################
# 5.6. Linux-4.18.5 API Headers

# The Linux API Headers (in linux-4.18.5.tar.xz) expose the kernel's API for use by Glibc.

_lfs_install_linux_api_headers() {
    cd $LFS_SOURCES_DIR
    tar xf linux-4.18.5.tar.xz
    cd linux-4.18.5

    # Make sure there are no stale files embedded in the package:
    make mrproper

    # Now extract the user-visible kernel headers from the source.
    # They are placed in an intermediate local directory and copied to the needed location
    # because the extraction process removes any existing files in the target directory.
    make INSTALL_HDR_PATH=dest headers_install
    cp -rv dest/include/* /tools/include
}

################################################################################
# 5.7. Glibc-2.28

# The Glibc package contains the main C library.
# This library provides the basic routines for
# allocating memory, searching directories,
# opening and closing files, reading and writing files,
# string handling, pattern matching, arithmetic, and so on.

# There have been reports that this package may fail when building as a "parallel make". If this occurs, rerun the make command with a "-j1" option.

_lfs_install_glibc() {
    cd $LFS_SOURCES_DIR
    tar xf glibc-2.28.tar.xz
    cd glibc-2.28

    mkdir -v build
    cd       build

    ../configure                             \
          --prefix=/tools                    \
          --host=$LFS_TGT                    \
          --build=$(../scripts/config.guess) \
          --enable-kernel=3.2             \
          --with-headers=/tools/include      \
          libc_cv_forced_unwind=yes          \
          libc_cv_c_cleanup=yes

    make
    make install

    echo -e "\n\033[1;31mit's time for sanity check, run:\033[0m\n"
    echo -e "\n\033[1;33m_lfs_toolchain_sanity_check\033[0m\n"
}

################################################################################
# sanity check

_lfs_toolchain_sanity_check() {
    cd $LFS_SOURCES_DIR

    # At this point, it is imperative to stop and ensure that the basic functions (compiling and linking)
    # of the new toolchain are working as expected. To perform a sanity check, run the following commands:
    echo 'int main(){}' > dummy.c
    $LFS_TGT-gcc dummy.c
    readelf -l a.out | grep ': /tools'

    echo -e "\033[32mIf everything is working correctly, there should be no errors, and the output of the last command will be of the form:\033[0m"
    echo -e "\033[1;32m      [Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2]\033[0m"

    # Once all is well, clean up the test files:
    rm -v dummy.c a.out
}

################################################################################
# 5.8. Libstdc++ from GCC-8.2.0

# Libstdc++ is the standard C++ library.
# It is needed to compile C++ code (part of GCC is written in C++),
# but we had to defer its installation when we built gcc-pass1 because it depends on glibc, which was not yet available in /tools.

_lfs_install_libstdcxx_from_gcc() {
    cd $LFS_SOURCES_DIR
    cd gcc-8.2.0

    mv -v build build-pass1

    mkdir -v build
    cd       build

    ../libstdc++-v3/configure           \
        --host=$LFS_TGT                 \
        --prefix=/tools                 \
        --disable-multilib              \
        --disable-nls                   \
        --disable-libstdcxx-threads     \
        --disable-libstdcxx-pch         \
        --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/8.2.0

    make
    make install
}

################################################################################
# 5.9. Binutils-2.31.1 - Pass 2

_lfs_install_binutils_pass2() {
    cd $LFS_SOURCES_DIR
    cd binutils-2.31.1

    mv -v build build-pass1

    mkdir -v build
    cd       build

    CC=$LFS_TGT-gcc                \
    AR=$LFS_TGT-ar                 \
    RANLIB=$LFS_TGT-ranlib         \
    ../configure                   \
        --prefix=/tools            \
        --disable-nls              \
        --disable-werror           \
        --with-lib-path=/tools/lib \
        --with-sysroot

    make
    make install

    # Now prepare the linker for the “Re-adjusting” phase in the next chapter:
    make -C ld clean
    make -C ld LIB_PATH=/usr/lib:/lib
    cp -v ld/ld-new /tools/bin
}

################################################################################
# 5.10. GCC-8.2.0 - Pass 2

_lfs_install_gcc_pass2() {
    cd $LFS_SOURCES_DIR
    cd gcc-8.2.0

    # Our first build of GCC has installed a couple of internal system headers.
    # Normally one of them, limits.h, will in turn include the corresponding system limits.h header, in this case, /tools/include/limits.h.
    # However, at the time of the first build of gcc /tools/include/limits.h did not exist,
    # so the internal header that GCC installed is a partial, self-contained file and does not include the extended features of the system header.
    # This was adequate for building the temporary libc, but this build of GCC now requires the full internal header.
    # Create a full version of the internal header using a command that is identical to what the GCC build system does in normal circumstances:
    cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
      `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

    # Once again, change the location of GCC's default dynamic linker to use the one installed in /tools.
    for file in gcc/config/{linux,i386/linux{,64}}.h
    do
      cp -uv $file{,.orig}
      sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
          -e 's@/usr@/tools@g' $file.orig > $file
      echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
      touch $file.orig
    done

    # If building on x86_64, change the default directory name for 64-bit libraries to “lib”:
    case $(uname -m) in
      x86_64)
        sed -e '/m64=/s/lib64/lib/' \
            -i.orig gcc/config/i386/t-linux64
      ;;
    esac

    # As in the first build of GCC it requires the GMP, MPFR and MPC packages. Unpack the tarballs and move them into the required directory names:
    tar -xf ../mpfr-4.0.1.tar.xz
    mv -v mpfr-4.0.1 mpfr
    tar -xf ../gmp-6.1.2.tar.xz
    mv -v gmp-6.1.2 gmp
    tar -xf ../mpc-1.1.0.tar.gz
    mv -v mpc-1.1.0 mpc

    # Create a separate build directory again:
    mv -v build build__
    mkdir -v build
    cd       build

    # Before starting to build GCC, remember to unset any environment variables that override the default optimization flags.
    env

    CC=$LFS_TGT-gcc                                    \
    CXX=$LFS_TGT-g++                                   \
    AR=$LFS_TGT-ar                                     \
    RANLIB=$LFS_TGT-ranlib                             \
    ../configure                                       \
        --prefix=/tools                                \
        --with-local-prefix=/tools                     \
        --with-native-system-header-dir=/tools/include \
        --enable-languages=c,c++                       \
        --disable-libstdcxx-pch                        \
        --disable-multilib                             \
        --disable-bootstrap                            \
        --disable-libgomp

    make
    make install

    # As a finishing touch, create a symlink. Many programs and scripts run cc instead of gcc,
    # which is used to keep programs generic and therefore usable on all kinds of UNIX systems
    # where the GNU C compiler is not always installed.
    # Running cc leaves the system administrator free to decide which C compiler to install:
    ln -sv gcc /tools/bin/cc

    echo -e "\n\033[1;31mit's time for sanity check, run:\033[0m\n"
    echo -e "\n\033[1;33m_lfs_toolchain_sanity_check\033[0m\n"
}

################################################################################
# 5.11. Tcl-8.6.8

# To support running the test suites for GCC and Binutils and other packages

# Note that the Tcl package used here is a minimal version needed to run the LFS tests.
# For the full package, see the BLFS Tcl procedures.

_lfs_install_tcl() {
    cd $LFS_SOURCES_DIR
    tar xf tcl8.6.8-src.tar.gz
    cd tcl8.6.8

    cd unix
    ./configure --prefix=/tools

    make

    # As discussed earlier, running the test suite is not mandatory for the temporary tools here in this chapter
    # The Tcl test suite may experience failures under certain host conditions that are not fully understood.
    # Therefore, test suite failures here are not surprising, and are not considered critical.
    # The TZ=UTC parameter sets the time zone to Coordinated Universal Time (UTC), but only for the duration of the test suite run.
    # This ensures that the clock tests are exercised correctly.
    TZ=UTC make test

    make install

    # Make the installed library writable so debugging symbols can be removed later:
    chmod -v u+w /tools/lib/libtcl8.6.so

    # Install Tcl's headers. The next package, Expect, requires them to build.
    make install-private-headers

    # Now make a necessary symbolic link:
    ln -sv tclsh8.6 /tools/bin/tclsh  # error??
}

################################################################################
# 5.12. Expect-5.45.4

# The Expect package contains a program for carrying out scripted dialogues with other interactive programs.

_lfs_install_expect() {
    cd $LFS_SOURCES_DIR
    tar xf expect5.45.4.tar.gz
    cd expect5.45.4

    # First, force Expect's configure script to use /bin/stty instead of a /usr/local/bin/stty it may find on the host system.
    # This will ensure that our test suite tools remain sane for the final builds of our toolchain:
    cp -v configure{,.orig}
    sed 's:/usr/local/bin:/bin:' configure.orig > configure

    echo -e "\033[0;1m"

    ./configure --prefix=/tools       \
                --with-tcl=/tools/lib \
                --with-tclinclude=/tools/include

    echo -e "\033[0;2m"

    make

    echo -e "\033[0;3m"

    # As discussed earlier, running the test suite is not mandatory for the temporary tools here in this chapter.
    # Expect test suite is known to experience failures under certain host conditions that are not within our control.
    # Therefore, test suite failures here are not surprising and are not considered critical.
    make test

    echo -e "\033[0;4m"

    # SCRIPTS="" prevents installation of the supplementary Expect scripts, which are not needed.
    make SCRIPTS="" install

    echo -e "\033[0m"
}

################################################################################
# 5.13. DejaGNU-1.6.1

# The DejaGNU package contains a framework for testing other programs.

_lfs_install_dejagnu() {
    cd $LFS_SOURCES_DIR
    tar xf dejagnu-1.6.1.tar.gz
    cd dejagnu-1.6.1

    ./configure --prefix=/tools

    make install
    make check
}

################################################################################
# 5.14. M4-1.4.18

# The M4 package contains a macro processor.

_lfs_install_m4() {
    cd $LFS_SOURCES_DIR
    tar xf m4-1.4.18.tar.xz
    cd m4-1.4.18

    # First, make some fixes required by glibc-2.28:
    sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
    echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

    ./configure --prefix=/tools
    make
    make check
    make install
}

################################################################################
# 5.15. Ncurses-6.1

_lfs_install_ncurses() {
    pack=ncurses

    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $pack`
    cd `_lfs_get_package_folder_name $pack`

    sed -i s/mawk// configure

    ./configure --prefix=/tools \
                --with-shared   \
                --without-debug \
                --without-ada   \
                --enable-widec  \
                --enable-overwrite
    make
    make install
}

################################################################################
# 5.16. Bash-4.4.18

_lfs_install_bash() {
    package="bash"

    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    ./configure --prefix=/tools --without-bash-malloc

    make
    make tests
    make install
    ln -sv bash /tools/bin/sh
}

################################################################################
# 5.17. Bison-3.0.5

_lfs_install_bison() {
    package="bison"

    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    ./configure --prefix=/tools

    make
    make check
    make install
}

################################################################################
# 5.18. Bzip2-1.0.6

_lfs_install_bzip2() {
    package="bzip2"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`
    make
    make PREFIX=/tools install
}

################################################################################
# 5.19. Coreutils-8.30

_lfs_install_coreutils() {
    package="coreutils"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    ./configure --prefix=/tools --enable-install-program=hostname
    make
    make RUN_EXPENSIVE_TESTS=yes check
    make install
}

################################################################################
# 5.20. Diffutils-3.6

_lfs_install_diffutils() {
    package="diffutils"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    ./configure --prefix=/tools
    make
    make check
    make install
}


################################################################################
# 5.21. File-5.34

_lfs_install_file() {
    package="file"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    ./configure --prefix=/tools
    make
    make check
    make install
}

################################################################################
# 5.22. Findutils-4.6.0

_lfs_install_findutils() {
    package="findutils"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
    sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
    echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h

    ./configure --prefix=/tools
    make
    make check
    make install
}

################################################################################
# 5.23. Gawk-4.2.1

_lfs_install_gawk() {
    package="gawk"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    ./configure --prefix=/tools
    make
    make check
    make install
}

################################################################################
# 5.24. Gettext-0.19.8.1

# The Gettext package contains utilities for internationalization and localization.
# These allow programs to be compiled with NLS (Native Language Support),
# enabling them to output messages in the user's native language.

_lfs_install_gettext() {
    package="gettext"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    # For our temporary set of tools, we only need to build and install three programs from Gettext.

    cd gettext-tools
    EMACS="no" ./configure --prefix=/tools --disable-shared

    make -C gnulib-lib
    make -C intl pluralx.c
    make -C src msgfmt
    make -C src msgmerge
    make -C src xgettext

    cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin
}

################################################################################
# 5.25. Grep-3.1

_lfs_install_grep() {
    package="grep"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`
    ./configure --prefix=/tools
    make
    make check
    make install
}

################################################################################
# 5.26. Gzip-1.9

_lfs_install_gzip() {
    package="gzip"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
    echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

    ./configure --prefix=/tools
    make
    make check
    make install
}

################################################################################
# 5.27. Make-4.2.1

_lfs_install_make() {
    package="make"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    #First, work around an error caused by glibc-2.27:
    sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c

    ./configure --prefix=/tools --without-guile
    make
    make check
    make install
}

################################################################################
# 5.28. Patch-2.7.6

_lfs_install_patch() {
    package="patch"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`
    ./configure --prefix=/tools
    make
    make check
    make install
}

################################################################################
# 5.29. Perl-5.28.0

_lfs_install_perl() {
    package="perl"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth

    make

    # Although Perl comes with a test suite, it would be better to wait until it is installed in the next chapter.
    # Only a few of the utilities and libraries need to be installed at this time:
    cp -v perl cpan/podlators/scripts/pod2man /tools/bin
    mkdir -pv /tools/lib/perl5/5.28.0
    cp -Rv lib/* /tools/lib/perl5/5.28.0
}

################################################################################
# 5.30. Sed-4.5

_lfs_install_sed() {
    package="sed"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`
    ./configure --prefix=/tools
    make
    make check
    make install
}

################################################################################
# 5.31. Tar-1.30

_lfs_install_tar() {
    package="tar"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`
    ./configure --prefix=/tools
    make
    make check
    make install
}

################################################################################
# 5.32. Texinfo-6.5

_lfs_install_texinfo() {
    package="texinfo"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    # As part of the configure process, a test is made that indicates an error for TestXS_la-TestXS.lo.
    # This is not relevant for LFS and should be ignored.
    ./configure --prefix=/tools

    make
    make check
    make install
}

################################################################################
# 5.33. Util-linux-2.32.1

# The Util-linux package contains miscellaneous utility programs.

_lfs_install_util-linux() {
    package="util-linux"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`

    ./configure --prefix=/tools                \
                --without-python               \
                --disable-makeinstall-chown    \
                --without-systemdsystemunitdir \
                --without-ncurses              \
                PKG_CONFIG=""
    make
    make install
}

################################################################################
# 5.34. Xz-5.2.4

_lfs_install_xz() {
    package="xz"
    cd $LFS_SOURCES_DIR
    tar xf `_lfs_get_package_file_name $package`
    cd `_lfs_get_package_folder_name $package`
    ./configure --prefix=/tools
    make
    make check
    make install
}

################################################################################
# 5.35. Stripping

# The steps in this section are optional, but if the LFS partition is rather small,
# it is beneficial to learn that unnecessary items can be removed.

_lfs_optional_stripping() {
    strip --strip-debug /tools/lib/*
    /usr/bin/strip --strip-unneeded /tools/{,s}bin/*

    # To save more, remove the documentation:
    rm -rf /tools/{,share}/{info,man,doc}

    # Remove unneeded files:
    find /tools/{lib,libexec} -name \*.la -delete

    # At this point, you should have at least 3 GB of free space in $LFS
    # that can be used to build and install Glibc and Gcc in the next phase.
    # If you can build and install Glibc, you can build and install the rest too.
}


################################################################################
# post-chapter5

_lfs_after_chapter5() {
    echo -e "\
        | \033[7;32mNote\033[0m\033[32m__________________________________________________\033[0m
        | \033[0;32mThe commands in the remainder of this book must be performed
        | while logged in as user \033[0;1;36mroot \033[0;32mand no longer as user \033[0;9;36mlfs\033[0m.
        | \033[0;32mAlso, double check that \033[0;1;32m$LFS \033[0;32mis set in root's environment\033[0m.
        | " | sed -E 's/^ *\| //g'

    if [ `whoami` == "root" ]; then
        # 5.36. Changing Ownership

        # Currently, the $LFS/tools directory is owned by the user lfs,
        # a user that exists only on the host system.
        # If the $LFS/tools directory is kept as is,
        # the files are owned by a user ID without a corresponding account.
        # This is dangerous because a user account created later could get this same user ID
        # and would own the $LFS/tools directory and all the files therein,
        # thus exposing these files to possible malicious manipulation.

        # To avoid this issue, you could add the lfs user to the new LFS system later
        # when creating the /etc/passwd file, taking care to assign it the same user and group IDs as on the host system.

        # Better yet, change the ownership of the $LFS/tools directory to user root
        chown -R root:root $LFS/tools

        echo -e "\
            | \033[1;7;33mCaution\033[0;1m\033[33m__________________________________________________\033[0m
            | \033[0;1;33mAlthough the $LFS/tools directory can be deleted once the LFS system has been finished,
            | it can be retained to build additional LFS systems of the same book version\033[0m.
            | \033[0;1;33mIf you intend to keep the temporary tools for use in building future LFS systems,
            | now is the time to back them up\033[0m.
            | \033[0;1;33mSubsequent commands in chapter 6 will alter the tools currently in place,
            | rendering them useless for future builds\033[0m.
            | " | sed -E 's/^ *\| //g'
    else
        echo -e "\033[31muser should be \033[0;1;36mroot \033[0;31mbut is \033[0;1;33m`whoami`\033[0m."
    fi
}

################################################################################

# In Chapter 6, the full LFS system is built.
# The chroot (change root) program is used to enter a virtual environment and
# start a new shell whose root directory will be set to the LFS partition.
# This is very similar to rebooting and instructing the kernel to mount the LFS partition as the root partition.
# The system does not actually reboot, but instead uses chroot because
# creating a bootable system requires additional work which is not necessary just yet.
# The major advantage is that “chrooting” allows you to continue using the host system while LFS is being built.
# While waiting for package compilations to complete, you can continue using your computer as normal.

################################################################################
# 6.2. Preparing Virtual Kernel File Systems

# Various file systems exported by the kernel are used to communicate to and from the kernel itself.
# These file systems are virtual in that no disk space is used for them.
# The content of the file systems resides in memory.

_lfs_create_directories_dev_proc_sys_run() {
    # Begin by creating directories onto which the file systems will be mounted:
    mkdir -pv $LFS/{dev,proc,sys,run}

    # [22:37:09]root@lfshost:/media/sf_hi-lfs/8.3-systemd(master)$ ls /mnt/lfs/
    # lost+found  sources  tools
    # [22:38:37]root@lfshost:/media/sf_hi-lfs/8.3-systemd(master)$ _lfs_create_directories_dev_proc_sys_run
    # mkdir: created directory '/mnt/lfs/dev'
    # mkdir: created directory '/mnt/lfs/proc'
    # mkdir: created directory '/mnt/lfs/sys'
    # mkdir: created directory '/mnt/lfs/run'
    # [22:38:44]root@lfshost:/media/sf_hi-lfs/8.3-systemd(master)$ ls /mnt/lfs/
    # dev  lost+found  proc  run  sources  sys  tools
}

_lfs_create_initial_device_nodes() {
    # 6.2.1. Creating Initial Device Nodes
    # When the kernel boots the system, it requires the presence of a few device nodes, in particular the console and null devices.
    # The device nodes must be created on the hard disk so that they are available before udevd has been started,
    # and additionally when Linux is started with init=/bin/bash.
    mknod -m 600 $LFS/dev/console c 5 1
    mknod -m 666 $LFS/dev/null c 1 3
}

_lfs_mount_and_populate_dev() {
    # 6.2.2. Mounting and Populating /dev

    # The recommended method of populating the /dev directory with devices is
    # to mount a virtual filesystem (such as tmpfs) on the /dev directory,
    # and allow the devices to be created dynamically on that virtual filesystem
    # as they are detected or accessed.

    # Device creation is generally done during the boot process by Udev.
    # Since this new system does not yet have Udev and has not yet been booted,
    # it is necessary to mount and populate /dev manually.
    # This is accomplished by bind mounting the host system's /dev directory.
    # A bind mount is a special type of mount that allows you to create a mirror
    # of a directory or mount point to some other location.
    mount -v --bind /dev $LFS/dev
}

_lfs_mount_virtual_kernel_fs() {
    # 6.2.3. Mounting Virtual Kernel File Systems
    mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
    mount -vt proc proc $LFS/proc
    mount -vt sysfs sysfs $LFS/sys
    mount -vt tmpfs tmpfs $LFS/run

    # In some host systems, /dev/shm is a symbolic link to /run/shm.
    # The /run tmpfs was mounted above so in this case only a directory needs to be created.
    if [ -h $LFS/dev/shm ]; then
      mkdir -pv $LFS/$(readlink $LFS/dev/shm)
    fi
}

################################################################################
# 6.4. Entering the Chroot Environment

# It is time to enter the chroot environment to begin building and installing the final LFS system.

_lfs_enter_chroot_env() {
    # As user root, run the following command to enter the realm that is,
    # at the moment, populated with only the temporary tools:

    chroot "$LFS" /tools/bin/env -i \
        HOME=/root                  \
        TERM="$TERM"                \
        PS1='(lfs chroot) \u:\w\$ ' \
        PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
        /tools/bin/bash --login +h

    # The -i option given to the env command will clear all variables of the chroot environment.
    # After that, only the HOME, TERM, PS1, and PATH variables are set again.
    # The TERM=$TERM construct will set the TERM variable inside chroot to the same value as outside chroot.
    # This variable is needed for programs like vim and less to operate properly.

    # If other variables are needed, such as CFLAGS or CXXFLAGS, this is a good place to set them again.

    # From this point on, there is no need to use the LFS variable anymore,
    # because all work will be restricted to the LFS file system.
    # This is because the Bash shell is told that $LFS is now the root (/) directory.

    # Notice that /tools/bin comes last in the PATH.
    # This means that a temporary tool will no longer be used once its final version is installed.
    # This occurs when the shell does not “remember” the locations of executed binaries—for this reason,
    # hashing is switched off by passing the +h option to bash.

    # Note that the bash prompt will say I have no name!
    # This is normal because the /etc/passwd file has not been created yet.
}

_lfs_note_about_chroot() {
    echo -e "\
        | \033[1;7;33mNote\033[0;1m\033[33m__________________________________________________\033[0m
        | \033[1;33mIt is important that all the commands throughout the remainder of this chapter
        | and the following chapters are run from within the chroot environment\033[0m.
        | \033[1;33mIf you leave this environment for any reason (rebooting for example),
        | ensure that the virtual kernel filesystems are mounted as explained in Section 6.2.2,
        | “Mounting and Populating /dev” and Section 6.2.3, “Mounting Virtual Kernel File Systems”
        | and enter chroot again before continuing with the installation\033[0m.
        | " | sed -E 's/^ *\| //g'
}

_lfs_chroot() {
    _lfs_note_about_chroot
    _lfs_mount_and_populate_dev
    _lfs_mount_virtual_kernel_fs
    _lfs_enter_chroot_env
}

################################################################################
# 6.5. Creating Directories

_lfs_create_directories() {
    # time to create some structure in the LFS file system

    mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
    mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}

    # Directories are, by default, created with permission mode 755,
    # but this is not desirable for all directories.
    # two changes are made
    # - one to the home directory of user root, and
    # - another to the directories for temporary files.

    # The first mode change ensures that not just anybody can enter the /root
    # directory—the same as a normal user would do with his or her home directory.
    install -dv -m 0750 /root

    # The second mode change makes sure that any user can write to the /tmp and /var/tmp directories,
    # but cannot remove another user's files from them.
    # The latter is prohibited by the so-called “sticky bit,” the highest bit (1) in the 1777 bit mask.
    install -dv -m 1777 /tmp /var/tmp

    # (lfs chroot) I have no name!:/# install --help
    # Usage: install [OPTION]... [-T] SOURCE DEST
    #   or:  install [OPTION]... SOURCE... DIRECTORY
    #   or:  install [OPTION]... -t DIRECTORY SOURCE...
    #   or:  install [OPTION]... -d DIRECTORY...
    #
    # This install program copies files (often just compiled) into destination
    # locations you choose.  If you want to download and install a ready-to-use
    # package on a GNU/Linux system, you should instead be using a package manager
    # like yum(1) or apt-get(1).
    #
    # In the first three forms, copy SOURCE to DEST or multiple SOURCE(s) to
    # the existing DIRECTORY, while setting permission modes and owner/group.
    # In the 4th form, create all components of the given DIRECTORY(ies).
    #
    # Mandatory arguments to long options are mandatory for short options too.
    #       --backup[=CONTROL]  make a backup of each existing destination file
    #   -b                  like --backup but does not accept an argument
    #   -c                  (ignored)
    #   -C, --compare       compare each pair of source and destination files, and
    #                         in some cases, do not modify the destination at all
    #   -d, --directory     treat all arguments as directory names; create all
    #                         components of the specified directories
    #   -D                  create all leading components of DEST except the last,
    #                         or all components of --target-directory,
    #                         then copy SOURCE to DEST
    #   -g, --group=GROUP   set group ownership, instead of process' current group
    #   -m, --mode=MODE     set permission mode (as in chmod), instead of rwxr-xr-x
    #   -o, --owner=OWNER   set ownership (super-user only)
    #   -p, --preserve-timestamps   apply access/modification times of SOURCE files
    #                         to corresponding destination files
    #   -s, --strip         strip symbol tables
    #       --strip-program=PROGRAM  program used to strip binaries
    #   -S, --suffix=SUFFIX  override the usual backup suffix
    #   -t, --target-directory=DIRECTORY  copy all SOURCE arguments into DIRECTORY
    #   -T, --no-target-directory  treat DEST as a normal file
    #   -v, --verbose       print the name of each directory as it is created
    #       --preserve-context  preserve SELinux security context
    #   -Z                      set SELinux security context of destination
    #                             file and each created directory to default type
    #       --context[=CTX]     like -Z, or if CTX is specified then set the
    #                             SELinux or SMACK security context to CTX
    #       --help     display this help and exit
    #       --version  output version information and exit
    #
    # The backup suffix is '~', unless set with --suffix or SIMPLE_BACKUP_SUFFIX.
    # The version control method may be selected via the --backup option or through
    # the VERSION_CONTROL environment variable.  Here are the values:
    #
    #   none, off       never make backups (even if --backup is given)
    #   numbered, t     make numbered backups
    #   existing, nil   numbered if numbered backups exist, simple otherwise
    #   simple, never   always make simple backups
    #
    # GNU coreutils online help: <https://www.gnu.org/software/coreutils/>
    # Report install translation bugs to <https://translationproject.org/team/>
    # Full documentation at: <https://www.gnu.org/software/coreutils/install>
    # or available locally via: info '(coreutils) install invocation'
    # (lfs chroot) I have no name!:/#

    mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
    mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
    mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
    mkdir -v  /usr/libexec
    mkdir -pv /usr/{,local/}share/man/man{1..8}

    case $(uname -m) in
      x86_64) mkdir -v /lib64 ;;
    esac

    mkdir -v /var/{log,mail,spool}
    ln -sv /run /var/run
    ln -sv /run/lock /var/lock
    mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}
}

################################################################################
# 6.6. Creating Essential Files and Symlinks

_lfs_create_essential_files_and_symlinks() {
    # Some programs use hard-wired paths to programs which do not exist yet.
    # In order to satisfy these programs, create a number of symbolic links which will be replaced
    # by real files throughout the course of this chapter after the software has been installed:

    ln -sv /tools/bin/{bash,cat,dd,echo,ln,pwd,rm,stty} /bin
    ln -sv /tools/bin/{env,install,perl} /usr/bin
    ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
    ln -sv /tools/lib/libstdc++.{a,so{,.6}} /usr/lib
    for lib in blkid lzma mount uuid
    do
        ln -sv /tools/lib/lib$lib.so* /usr/lib
    done
    ln -svf /tools/include/blkid    /usr/include
    ln -svf /tools/include/libmount /usr/include
    ln -svf /tools/include/uuid     /usr/include
    install -vdm755 /usr/lib/pkgconfig
    for pc in blkid mount uuid
    do
        sed 's@tools@usr@g' /tools/lib/pkgconfig/${pc}.pc \
            > /usr/lib/pkgconfig/${pc}.pc
    done
    ln -sv bash /bin/sh

    # Historically, Linux maintains a list of the mounted file systems in the file /etc/mtab.
    # Modern kernels maintain this list internally and exposes it to the user via the /proc filesystem.
    # To satisfy utilities that expect the presence of /etc/mtab, create the following symbolic link:
    ln -sv /proc/self/mounts /etc/mtab

    # In order for user root to be able to login and for the name “root” to be recognized,
    # there must be relevant entries in the /etc/passwd and /etc/group files.
    cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
systemd-bus-proxy:x:72:72:systemd Bus Proxy:/:/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/bin/false
systemd-network:x:76:76:systemd Network Management:/:/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF
    # The actual password for root (the “x” used here is just a placeholder) will be set later.

    cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-bus-proxy:x:72:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
nogroup:x:99:
users:x:999:
EOF
    # The created groups are not part of any standard—they are groups decided on
    # - in part by the requirements of the Udev configuration in this chapter, and
    # - in part by common convention employed by a number of existing Linux distributions.
    #
    # In addition, some test suites rely on specific users or groups.
    #
    # The Linux Standard Base (LSB, available at http://www.linuxbase.org) recommends only that,
    # besides the group root with a Group ID (GID) of 0, a group bin with a GID of 1 be present.
    # All other group names and GIDs can be chosen freely by the system administrator since
    # well-written programs do not depend on GID numbers, but rather use the group's name.

    # The login, agetty, and init programs (and others) use a number of log files to record
    # information such as who was logged into the system and when.
    # However, these programs will not write to the log files if they do not already exist.
    # Initialize the log files and give them proper permissions:
    touch /var/log/{btmp,lastlog,faillog,wtmp}
    chgrp -v utmp /var/log/lastlog
    chmod -v 664  /var/log/lastlog
    chmod -v 600  /var/log/btmp
    # The /var/log/wtmp file records all logins and logouts.
    # The /var/log/lastlog file records when each user last logged in.
    # The /var/log/faillog file records failed login attempts.
    # The /var/log/btmp file records the bad login attempts.

    # Note:
    # The /run/utmp file records the users that are currently logged in.
    # This file is created dynamically in the boot scripts.
}

_lfs_remove_I_have_no_name_prompt() {
    # To remove the “I have no name!” prompt, start a new shell.
    # Since a full Glibc was installed in Chapter 5 and the /etc/passwd and /etc/group files
    # have been created, user name and group name resolution will now work:
    exec /tools/bin/bash --login +h
    # Note the use of the +h directive. This tells bash not to use its internal path hashing.
    # Without this directive, bash would remember the paths to binaries it has executed.
    # To ensure the use of the newly compiled binaries as soon as they are installed,
    # the +h directive will be used for the duration of this chapter.

    # (lfs chroot) I have no name!:/# exec /tools/bin/bash --login +h
    # (lfs chroot) root:/#
}

################################################################################
# 6.7. Linux-4.18.5 API Headers

# The Linux API Headers (in linux-4.18.5.tar.xz) expose the kernel's API for use by Glibc.

_lfs_post_chroot_install_linux_api_headers() {
    cd /sources/linux-4.18.5

    # Make sure there are no stale files and dependencies lying around from previous activity:
    make mrproper

    # Now extract the user-visible kernel headers from the source.
    # They are placed in an intermediate local directory and copied to the needed location
    # because the extraction process removes any existing files in the target directory.
    # There are also some hidden files used by the kernel developers and not needed by LFS
    # that are removed from the intermediate directory.
    make INSTALL_HDR_PATH=dest headers_install
    find dest/include \( -name .install -o -name ..install.cmd \) -delete
    cp -rv dest/include/* /usr/include
}

################################################################################
# 6.8. Man-pages-4.16

_lfs_post_chroot_install_man-pages() {
    cd /sources/
    tar xf man-pages-4.16.tar.xz
    cd man-pages-4.16
    make install
}

################################################################################
# 6.9. Glibc-2.28

_lfs_post_chroot_install_glibc() {
    cd /sources/glibc-2.28

    # Some of the Glibc programs use the non-FHS compilant /var/db directory to store their runtime data.
    # Apply the following patch to make such programs store their runtime data in the FHS-compliant locations:
    patch -Np1 -i ../glibc-2.28-fhs-1.patch

    # First create a compatibility symlink to avoid references to /tools in our final glibc:
    ln -sfv /tools/lib/gcc /usr/lib

    # Determine the GCC include directory and create a symlink for LSB compliance.
    # Additionally, for x86_64, create a compatibility symlink required
    # for the dynamic loader to function correctly:
    case $(uname -m) in
        i?86)    GCC_INCDIR=/usr/lib/gcc/$(uname -m)-pc-linux-gnu/8.2.0/include
                ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3
        ;;
        x86_64) GCC_INCDIR=/usr/lib/gcc/x86_64-pc-linux-gnu/8.2.0/include
                ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
                ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
        ;;
    esac

    # Remove a file that may be left over from a previous build attempt:
    rm -f /usr/include/limits.h

    # The Glibc documentation recommends building Glibc in a dedicated build directory:
    mv -v build build_
    mkdir -v build
    cd       build

    # Prepare Glibc for compilation:
    CC="gcc -isystem $GCC_INCDIR -isystem /usr/include" \
    ../configure --prefix=/usr                          \
                 --disable-werror                       \
                 --enable-kernel=3.2                    \
                 --enable-stack-protector=strong        \
                 libc_cv_slibdir=/lib
    unset GCC_INCDIR

    make

    # In this section, the test suite for Glibc is considered critical. Do not skip it under any circumstance.
    make check
    # You may see some test failures.
    # The Glibc test suite is somewhat dependent on the host system.
    # This is a list of the most common issues seen for some versions of LFS:
    # - misc/tst-ttyname is known to fail in the LFS chroot environment.
    # - inet/tst-idna_name_classify is known to fail in the LFS chroot environment.
    # - posix/tst-getaddrinfo4 and posix/tst-getaddrinfo5 may fail on some architectures.
    # - The nss/tst-nss-files-hosts-multi test may fail for reasons that have not been determined.
    # - The math tests sometimes fail when running on systems where the CPU is
    #   not a relatively new Intel or AMD processor.

    # Though it is a harmless message, the install stage of Glibc will complain
    # about the absence of /etc/ld.so.conf. Prevent this warning with:
    touch /etc/ld.so.conf

    # Fix the generated Makefile to skip an unneeded sanity check that fails in the LFS partial environment:
    sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

    # Install the package:
    make install

    # Install the configuration file and runtime directory for nscd:
    cp -v ../nscd/nscd.conf /etc/nscd.conf
    mkdir -pv /var/cache/nscd

    # Install the systemd support files for nscd:
    install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
    install -v -Dm644 ../nscd/nscd.service /lib/systemd/system/nscd.service

    # Next, install the locales that can make the system respond in a different language.
    # None of the locales are required, but if some of them are missing,
    # the test suites of future packages would skip important testcases.
    #
    # Individual locales can be installed using the localedef program.
    # E.g., the first localedef command below combines the /usr/share/i18n/locales/cs_CZ
    #       charset-independent locale definition with the /usr/share/i18n/charmaps/UTF-8.gz
    #       charmap definition and appends the result to the /usr/lib/locale/locale-archive file.
    # The following instructions will install the minimum set of locales necessary
    # for the optimal coverage of tests.
    #
    # Alternatively, install all locales listed in the glibc-2.28/localedata/SUPPORTED file
    # (it includes every locale listed above and many more) at once with the following time-consuming command:
    #     make localedata/install-locales
    # Then use the localedef command to create and install locales not listed in
    # the glibc-2.28/localedata/SUPPORTED file in the unlikely case you need them.
    #
    # Note:
    # Glibc now uses libidn2 when resolving internationalized domain names. This is a run time dependency.
    # If this capability is needed, the instrucions for installing libidn2 are in the BLFS libidn2 page.
    mkdir -pv /usr/lib/locale
    localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
    localedef -i de_DE -f ISO-8859-1 de_DE
    localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
    localedef -i de_DE -f UTF-8 de_DE.UTF-8
    localedef -i en_GB -f UTF-8 en_GB.UTF-8
    localedef -i en_HK -f ISO-8859-1 en_HK
    localedef -i en_PH -f ISO-8859-1 en_PH
    localedef -i en_US -f ISO-8859-1 en_US
    localedef -i en_US -f UTF-8 en_US.UTF-8
    localedef -i es_MX -f ISO-8859-1 es_MX
    localedef -i fa_IR -f UTF-8 fa_IR
    localedef -i fr_FR -f ISO-8859-1 fr_FR
    localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
    localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
    localedef -i it_IT -f ISO-8859-1 it_IT
    localedef -i it_IT -f UTF-8 it_IT.UTF-8
    localedef -i ja_JP -f EUC-JP ja_JP
    localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
    localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
    localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
    localedef -i zh_CN -f GB18030 zh_CN.GB18030
}

_lfs_post_chroot_configure_glibc() {
    # 6.9.2. Configuring Glibc

    # 6.9.2.1. Adding nsswitch.conf
    # The /etc/nsswitch.conf file needs to be created because the Glibc defaults do not work well in a networked environment.
    cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

    # 6.9.2.2. Adding time zone data
    tar -xf ../../tzdata2018e.tar.gz
    ZONEINFO=/usr/share/zoneinfo
    mkdir -pv $ZONEINFO/{posix,right}
    for tz in etcetera southamerica northamerica europe africa antarctica  \
              asia australasia backward pacificnew systemv; do
        zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
        zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
        zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
    done
    cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
    zic -d $ZONEINFO -p America/New_York
    unset ZONEINFO

    # determine the local time zone is to run the following script:
    tzselect
    # After answering a few questions about the location,
    # the script will output the name of the time zone (e.g., America/Edmonton).
    # There are also some other possible time zones listed in /usr/share/zoneinfo
    # such as Canada/Eastern or EST5EDT that are not identified by the script but can be used.
    # Then create the /etc/localtime file by running:
    ln -sfv /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

    # 6.9.2.3. Configuring the Dynamic Loader
    # By default, the dynamic loader (/lib/ld-linux.so.2) searches through /lib and /usr/lib
    # for dynamic libraries that are needed by programs as they are run.
    # However, if there are libraries in directories other than /lib and /usr/lib,
    # these need to be added to the /etc/ld.so.conf file in order for the dynamic loader to find them.
    # Two directories that are commonly known to contain additional libraries are /usr/local/lib and /opt/lib,
    # so add those directories to the dynamic loader's search path.
    cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF
    # If desired, the dynamic loader can also search a directory and include the contents of files found there.
    # Generally the files in this include directory are one line specifying the desired library path.
    # To add this capability run the following commands:
    cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
    mkdir -pv /etc/ld.so.conf.d
}

################################################################################
# 6.10. Adjusting the Toolchain

_lfs_post_chroot_adjust_toolchain() {
    # Now that the final C libraries have been installed, it is time to adjust the toolchain so that it will link any newly compiled program against these new libraries.

    # First, backup the /tools linker, and replace it with the adjusted linker we made in chapter 5.
    # We'll also create a link to its counterpart in /tools/$(uname -m)-pc-linux-gnu/bin:
    mv -v /tools/bin/{ld,ld-old}
    mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
    mv -v /tools/bin/{ld-new,ld}
    ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld

    # Next, amend the GCC specs file so that it points to the new dynamic linker.
    # Simply deleting all instances of “/tools” should leave us with the correct path to the dynamic linker.
    # Also adjust the specs file so that GCC knows where to find the correct headers and Glibc start files.
    gcc -dumpspecs | sed -e 's@/tools@@g'                   \
        -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
        -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
        `dirname $(gcc --print-libgcc-file-name)`/specs

    # It is a good idea to visually inspect the specs file to verify the intended change was actually made.
    cat `dirname $(gcc --print-libgcc-file-name)`/specs

    # It is imperative at this point to ensure that the basic functions (compiling and linking)
    # of the adjusted toolchain are working as expected.
    echo 'int main(){}' > dummy.c
    cc dummy.c -v -Wl,--verbose &> dummy.log
    readelf -l a.out | grep ': /lib'
    echo -e "\033[32mThere should be no errors, and the output of the last command will be (allowing for platform-specific differences in dynamic linker name):\033[0m"
    echo -e "\033[1;32m      [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]\033[0m"
    # Note that on 64-bit systems /lib is the location of our dynamic linker, but is accessed via a symbolic link in /lib64.
    # On 32-bit systems the interpreter should be /lib/ld-linux.so.2.

    # Now make sure that we're setup to use the correct start files:
    grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
    echo -e "\033[0;32mThe output of the last command should be:\033[0m"
    echo -e "\033[1;32m/usr/lib/../lib/crt1.o succeeded\033[0m"
    echo -e "\033[1;32m/usr/lib/../lib/crti.o succeeded\033[0m"
    echo -e "\033[1;32m/usr/lib/../lib/crtn.o succeeded\033[0m"

    # Verify that the compiler is searching for the correct header files:
    grep -B1 '^ /usr/include' dummy.log
    echo -e "\033[0;32mThe output of the last command should be:\033[0m"
    echo -e "\033[1;32m#include <...> search starts here:\033[0m"
    echo -e "\033[1;32m /usr/include\033[0m"

    # Next, verify that the new linker is being used with the correct search paths:
    grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
    echo -e "\033[0;32mReferences to paths that have components with '-linux-gnu' should be ignored, but otherwise the output of the last command should be:\033[0m"
    echo -e "\033[1;32mSEARCH_DIR("/usr/lib")\033[0m"
    echo -e "\033[1;32mSEARCH_DIR("/lib")\033[0m"

    # Next make sure that we're using the correct libc:
    grep "/lib.*/libc.so.6 " dummy.log
    echo -e "\033[0;32mThe output of the last command should be:\033[0m"
    echo -e "\033[1;32mattempt to open /lib/libc.so.6 succeeded\033[0m"

    # Lastly, make sure GCC is using the correct dynamic linker:
    grep found dummy.log
    echo -e "\033[0;32mThe output of the last command should be (allowing for platform-specific differences in dynamic linker name):\033[0m"
    echo -e "\033[1;32mfound ld-linux-x86-64.so.2 at /lib/ld-linux-x86-64.so.2\033[0m"

    # If the output does not appear as shown above or is not received at all, then something is seriously wrong.
    # Investigate and retrace the steps to find out where the problem is and correct it.
    # The most likely reason is that something went wrong with the specs file adjustment.
    # Any issues will need to be resolved before continuing with the process.

    # Once everything is working correctly, clean up the test files:
    rm -v dummy.c a.out dummy.log
}

################################################################################
# 6.11. Zlib-1.2.11

_lfs_post_chroot_install_zlib() {
    cd /sources/
    tar xf zlib-1.2.11.tar.xz
    cd zlib-1.2.11

    echo -e "\033[1;7;32m~~~~~~~~~~~~~~~~~~~~\033[0m"
    ./configure --prefix=/usr

    echo -e "\033[1;7;32m--------------------\033[0m"
    make

    echo -e "\033[1;7;32m====================\033[0m"
    make check

    echo -e "\033[1;7;32m++++++++++++++++++++\033[0m"
    make install

    # The shared library needs to be moved to /lib, and as a result the .so file in /usr/lib will need to be recreated:
    echo -e "\033[1;7;32m####################\033[0m"
    mv -v /usr/lib/libz.so.* /lib
    ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
}

################################################################################
# 6.12. File-5.34

_lfs_post_chroot_install_file() {
    pack=file

    cd /sources/
    tar xf `ls $pack-*z*`
    cd $pack-*[0-9]

    echo -e "\033[1;7;32m~~~~~~~~~~~~~~~~~~~~\033[0m"; ./configure --prefix=/usr
    echo -e "\033[1;7;32m--------------------\033[0m"; make
    echo -e "\033[1;7;32m====================\033[0m"; make check
    echo -e "\033[1;7;32m++++++++++++++++++++\033[0m"; make install
    echo -e "\033[1;7;32m####################\033[0m"
}

################################################################################
# 6.13. Readline-7.0

_lfs_post_chroot_install_readline() {
    package________name="readline"

    cd /sources/
    tar xf `ls $package________name-*tar*`
    cd $package________name-*[0-9]

    ________________________________________________________________________________ '
    # Reinstalling Readline will cause the old libraries to be moved to <libraryname>.old.
    # While this is normally not a problem, in some cases it can trigger a linking bug in ldconfig.
    # This can be avoided by issuing the following two seds:
    '
    sed -i '/MV.*old/d' Makefile.in
    sed -i '/{OLDSUFF}/c:' support/shlib-install
    ________________________________________________________________________________ '
    # configure
    '
    ./configure --prefix=/usr    \
                --disable-static \
                --docdir=/usr/share/doc/readline-7.0
    ________________________________________________________________________________ '
    # make
    '
    make SHLIB_LIBS="-L/tools/lib -lncursesw"
    ________________________________________________________________________________ '
    # make install
    '
    make SHLIB_LIBS="-L/tools/lib -lncurses" install
    ________________________________________________________________________________ '
    # Now move the dynamic libraries to a more appropriate location and fix up some permissions and symbolic links:
    '
    mv -v /usr/lib/lib{readline,history}.so.* /lib
    chmod -v u+w /lib/lib{readline,history}.so.*
    ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
    ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
    ________________________________________________________________________________ '
    # install the documentation:
    '
    install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-7.0
}

################################################################################
# 6.14. M4-1.4.18

_lfs_post_chroot_install_m4() {
    package________name="m4"
    cd /sources/
    tar xf `ls $package________name-*tar*`
    cd $package________name-*[0-9]

    ________________________________________________________________________________ '
    First, make some fixes required by glibc-2.28:
    '
    sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
    echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
    ________________________________________________________________________________ '
    # configure
    '
    ./configure --prefix=/usr
    ________________________________________________________________________________ '
    # make
    '
    make
    ________________________________________________________________________________ '
    # make check
    '
    make check
    ________________________________________________________________________________ '
    # make install
    '
    make install
}

################################################################################
# 6.15. Bc-1.07.1

_lfs_post_chroot_install_bc() {
    package________name="bc"
    cd /sources/
    tar xf `ls $package________name-*tar*`
    cd $package________name-*[0-9]

    ________________________________________________________________________________ '
    # First, change an internal script to use sed instead of ed:
    '
    cat > bc/fix-libmath_h << "EOF"
#! /bin/bash
sed -e '1   s/^/{"/' \
    -e     's/$/",/' \
    -e '2,$ s/^/"/'  \
    -e   '$ d'       \
    -i libmath.h

sed -e '$ s/$/0}/' \
    -i libmath.h
EOF
    ________________________________________________________________________________ '
    # Create temporary symbolic links so the package can find the readline library and confirm that its required libncurses library is available.
    # Even though the libraries are in /tools/lib at this point, the system will use /usr/lib at the end of this chapter.
    '
    ln -sv /tools/lib/libncursesw.so.6 /usr/lib/libncursesw.so.6
    ln -sfv libncurses.so.6 /usr/lib/libncurses.so
    ________________________________________________________________________________ '
    # Fix an issue in configure due to missing files in the early stages of LFS:
    '
    sed -i -e '/flex/s/as_fn_error/: ;; # &/' configure
    ________________________________________________________________________________ '
    # configure
    '
    ./configure --prefix=/usr           \
                --with-readline         \
                --mandir=/usr/share/man \
                --infodir=/usr/share/info
    ________________________________________________________________________________ '
    # make
    '
    make
    ________________________________________________________________________________ '
    # To test bc, run the commands below.
    # There is quite a bit of output, so you may want to redirect it to a file.
    # There are a very small percentage of tests (10 of 12,144) that will indicate a round off error at the last digit.
    '
    echo "quit" | ./bc/bc -l Test/checklib.b > test_checklib.output
    ________________________________________________________________________________ '
    # make install
    '
    make install
    ________________________________________________________________________________ '
    # now examin \033[0;36mtest_checklib.output
    '
}

################################################################################
# 6.16. Binutils-2.31.1

_lfs_post_chroot_install_binutils() {
    package________name="binutils"
    cd /sources/
    tar xf `ls $package________name-*tar*`
    cd $package________name-*[0-9]
    ________________________________________________________________________________ '
    Verify that the PTYs are working properly inside the chroot environment by performing a simple test:
    '
    expect -c "spawn ls"
    ________________________________________there_should_have________________________________________ '
    # This command should output the following.' '
    spawn ls' '
    # If, instead, the output includes the message below, then the environment is not set up for proper PTY operation.
    # This issue needs to be resolved before running the test suites for Binutils and GCC:' '
    The system has no more ptys.\n
    Ask your system administrator to create more.
    '
    ________________________________________________________________________________ '
    # The Binutils documentation recommends building Binutils in a dedicated build directory:
    '
    mv -v build build_
    mkdir -v build
    cd       build
    ________________________________________________________________________________ '
    # configure
    '
    ../configure --prefix=/usr       \
                 --enable-gold       \
                 --enable-ld=default \
                 --enable-plugins    \
                 --enable-shared     \
                 --disable-werror    \
                 --enable-64-bit-bfd \
                 --with-system-zlib
    ________________________________________________________________________________ '
    # make
    '
    make tooldir=/usr
    ________________________________________________________________________________ '
    # make check
    # \033[1;33mThe test suite for Binutils in this section is considered critical. Do not skip it under any circumstances.
    '
    make -k check
    ________________________________________________________________________________ '
    # make install
    '
    make tooldir=/usr install
}

################################################################################
# 6.17. GMP-6.1.2

_lfs_post_chroot_install_gmp() {
    package________name="gmp"
    cd /sources/
    tar xf `ls $package________name-*tar*`
    cd $package________name-*[0-9]
    ________________________________________NOTE________________________________________ '
    If you are building for 32-bit x86, but you have a CPU which is capable of running 64-bit code
    and you have specified CFLAGS in the environment, the configure script will attempt to configure for 64-bits and fail.
    Avoid this by invoking the configure command below with' '
    ABI=32 ./configure ...
    '
    ________________________________________NOTE________________________________________ '
    The default settings of GMP produce libraries optimized for the host processor.
    If libraries suitable for processors less capable than the host CPU are desired,
    generic libraries can be created by running the following:' '
    cp -v configfsf.guess config.guess\n
    cp -v configfsf.sub   config.sub
    '
    ________________________________________________________________________________ '
    # configure
    '
    ./configure --prefix=/usr    \
                --enable-cxx     \
                --disable-static \
                --docdir=/usr/share/doc/gmp-6.1.2
    ________________________________________________________________________________ '
    # make
    '
    make
    make html
    ________________________________________IMPORTANT________________________________________ '
    The test suite for GMP in this section is considered critical.
    Do not skip it under any circumstances.
    '
    ________________________________________________________________________________ '
    # make check
    '
    make check 2>&1 | tee gmp-check-log
    ________________________________________IMPORTANT________________________________________ '
    The code in gmp is highly optimized for the processor where it is built.
    Occasionally, the code that detects the processor misidentifies the system capabilities
    and there will be errors in the tests or other applications using the gmp libraries with the message "Illegal instruction".
    In this case, gmp should be reconfigured with the option --build=x86_64-unknown-linux-gnu and rebuilt.
    '
    ________________________________________________________________________________ '
    Ensure that all 190 tests in the test suite passed. Check the results by issuing the following command:
    '
    awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
    ________________________________________________________________________________ '
    # make install
    '
    make install
    make install-html
}

################################################################################
# example
_lfs_post_chroot_install_() {
    package________name=""
    cd /sources/
    tar xf `ls $package________name-*tar*`
    cd $package________name-*[0-9]
    ________________________________________________________________________________ '
    # configure
    '
    ./configure --prefix=/usr
    ________________________________________________________________________________ '
    # make
    '
    make
    ________________________________________________________________________________ '
    # make check
    '
    make check
    ________________________________________________________________________________ '
    # make install
    '
    make install
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
