## source me, don't run me

export LFS_PARTITION=/dev/sdb

export LFS_VERSION="stable-systemd"

################################################################################

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

_lfs_get_package_file_name() {
    pack=$1
    source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
    grep $pack $source_dir/wget-list | sed -e "s/.*\///g" | head -n 1
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
##
##_lfs_install_() {
##    package=""
##
##    cd $LFS_SOURCES_DIR
##    tar xf `_lfs_get_package_file_name $pack`
##    cd `_lfs_get_package_folder_name $pack`
##
##    mkdir -v build
##    cd       build
##
##    make
##    make install
##}

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
