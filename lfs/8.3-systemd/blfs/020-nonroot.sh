## source me, don't run me

export PS4="\033[1;33m++++++++++\033[0m"

export WD=/home/yyu/xc
export SELF=020-nonroot.sh
export WRAPPER=$WD/wrapper
export X_LOG=/var/log/blfs.Xorg.log

export XORG_PREFIX="/usr"
export XORG_CONFIG="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var --disable-static"

################################################################################

_____________() {
    echo -e "\033[1;46m"$@"\033[0m"
}

################################################################################

_x_refresh_the_functions() {
    functionsfile=$1
    functionsfile=${functionsfile:-$SELF}

    set -x
    rm   -v $WD/$functionsfile
    wget -O $WD/$functionsfile 192.168.10.144:8000/$functionsfile  # because python3 -m http.server
    .       $WD/$functionsfile
    set +x
}

_blfs_extract_filename() {
    echo $1 | sed -e 's/.*\///g'
}

_blfs_folder_name() {
    echo $1 | sed -e 's/\.tar\.[gxb]z2\?//g'
}

_blfs_download_extract_and_enter() {
    download_url=$1
    tarball=$(_blfs_extract_filename $download_url)
    folder=$(_blfs_folder_name $tarball)

    wget $download_url
    tar xf $tarball
    cd $folder
}

_blfs_cleanup() {
    download_url=$1
    tarball=$(_blfs_extract_filename $download_url)
    folder=$(_blfs_folder_name $tarball)

    rm -rf $folder $tarball
}

_x_setup_xorg_build_env_() {
    cat > /etc/profile.d/xorg.sh << EOF
XORG_PREFIX="$XORG_PREFIX"
XORG_CONFIG="--prefix=\$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var --disable-static"
export XORG_PREFIX XORG_CONFIG
EOF
    chmod 644 /etc/profile.d/xorg.sh
}

_x_install_util_macros_() {
    url=https://www.x.org/pub/individual/util/util-macros-1.19.2.tar.bz2

    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    #make
    sudo make install

    popd
}

_x_install_xorgproto_() {
    url=https://xorg.freedesktop.org/archive/individual/proto/xorgproto-2018.4.tar.bz2

    pushd $WD
    _blfs_download_extract_and_enter $url

    mkdir build &&
    cd    build &&

    meson --prefix=$XORG_PREFIX .. &&
    ninja

    sudo ninja install &&

    sudo install -vdm 755 $XORG_PREFIX/share/doc/xorgproto-2018.4 &&
    sudo install -vm 644 ../[^m]*.txt ../PM_spec $XORG_PREFIX/share/doc/xorgproto-2018.4

    popd
}

_x_install_libXau_() {
    set -e; set -v; set -x
    url=https://www.x.org/pub/individual/lib/libXau-1.0.8.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    make
    sudo make install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_libXdmcp_() {
    set -e; set -v; set -x; url=https://www.x.org/pub/individual/lib/libXdmcp-1.1.2.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    make
    sudo make install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_xcb_proto_() {
    set -e; set -v; set -x; url=https://xcb.freedesktop.org/dist/xcb-proto-1.13.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    make check
    sudo make install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_libxcb_() {
    set -e; set -v; set -x; url=https://xcb.freedesktop.org/dist/libxcb-1.13.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    sed -i "s/pthread-stubs//" configure &&
    ./configure $XORG_CONFIG      \
                --without-doxygen \
                --docdir='${datadir}'/doc/libxcb-1.13 &&
    make

    make check
    sudo make install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install___() {
    set -e; set -v; set -x; url=
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    make
    sudo make install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_wrap_() {
    cat > $WRAPPER << EOF
. $WD/$SELF
$@ 2>&1 | tee -a $X_LOG
EOF
    chmod +x $WRAPPER
}

_x_setup_xorg_build_env() {
    _x_wrap_  _x_setup_xorg_build_env_ && sudo $WRAPPER
}

_x_install_util_macros() {
    _x_wrap_  _x_install_util_macros_ && $WRAPPER
}

_x_install_xorgproto() {
    _x_wrap_  _x_install_xorgproto_ && $WRAPPER
}

_x_install_libXau() {
    _x_wrap_  _x_install_libXau_ && $WRAPPER
}

_x_install_libXdmcp() {
    _x_wrap_  _x_install_libXdmcp_ && $WRAPPER
}

_x_install_xcb_proto() {
    _x_wrap_  _x_install_xcb_proto_ && $WRAPPER
}

_x_install_libxcb() {
    _x_wrap_  _x_install_libxcb_ && $WRAPPER
}

