## source me, don't run me

export PS4="\033[1;33m++++++++++\033[0m"

export WD=/home/yyu/xc
export SELF=020-nonroot.sh
export WRAPPER=$WD/wrapper
export BLFS_LOG=/var/log/blfs.log

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

_x_setup_xorg_build_env_() {
    cat > /etc/profile.d/xorg.sh << EOF
XORG_PREFIX="$XORG_PREFIX"
XORG_CONFIG="--prefix=\$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var --disable-static"
export XORG_PREFIX XORG_CONFIG
EOF
    chmod 644 /etc/profile.d/xorg.sh
}

_x_install___() {
    url=

    pushd /sources/downloads/blfs
    _blfs_download_extract_and_enter $url

    ./configure --prefix=/usr
    make
    make install

    popd
}

_x_wrap_() {
    cat > $WRAPPER << EOF
set -e; set -v; set -x
. $WD/$SELF
$@ 2>&1 | tee -a $BLFS_LOG
set +x; set +v; set +e
EOF
    chmod +x $WRAPPER
}

_x_setup_xorg_build_env() {
    _x_wrap_  _x_setup_xorg_build_env_ && sudo $WRAPPER
}

