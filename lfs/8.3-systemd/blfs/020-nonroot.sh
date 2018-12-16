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

_x_install_libpng_() {
    set -e; set -v; set -x; url=https://downloads.sourceforge.net/libpng/libpng-1.6.35.tar.xz
    pushd $WD
    wget https://downloads.sourceforge.net/sourceforge/libpng-apng/libpng-1.6.35-apng.patch.gz
    _blfs_download_extract_and_enter $url

    gzip -cd ../libpng-1.6.35-apng.patch.gz | patch -p1

    LIBS=-lpthread ./configure --prefix=/usr --disable-static &&
    make

    make check

    sudo make install &&
    sudo mkdir -v /usr/share/doc/libpng-1.6.35 &&
    sudo cp -v README libpng-manual.txt /usr/share/doc/libpng-1.6.35

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_FreeType_() {
    set -e; set -v; set -x; url=https://downloads.sourceforge.net/freetype/freetype-2.9.1.tar.bz2
    pushd $WD
    wget https://downloads.sourceforge.net/freetype/freetype-doc-2.9.1.tar.bz2
    _blfs_download_extract_and_enter $url

    tar -xf ../freetype-doc-2.9.1.tar.bz2 --strip-components=2 -C docs
    sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg &&

    sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
        -i include/freetype/config/ftoption.h  &&

    ./configure --prefix=/usr --enable-freetype-config --disable-static &&
    make

    sudo make install &&
    sudo cp builds/unix/freetype-config /usr/bin
    sudo install -v -m755 -d /usr/share/doc/freetype-2.9.1 &&
    sudo cp -v -R docs/*     /usr/share/doc/freetype-2.9.1

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_ICU_() {
    set -e; set -v; set -x; url=http://download.icu-project.org/files/icu4c/62.1/icu4c-62_1-src.tgz
    pushd $WD
    wget $url
    tar xf icu4c-62_1-src.tgz
    cd icu

    cd source                                    &&
    ./configure --prefix=/usr                    &&
    make

    make check
    sudo make install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_HarfBuzz_() {
    set -e; set -v; set -x; url=https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.8.8.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure --prefix=/usr --with-gobject &&
    make
    make check
    sudo make install

    #hb-ot-shape-closure /usr/share/fonts/dejavu/DejaVuSans.ttf "Hello World."

    sleep 5

    _x_install_FreeType

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_Fontconfig_() {
    set -e; set -v; set -x; url=https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.0.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    rm -f src/fcobjshash.h
    ./configure --prefix=/usr        \
                --sysconfdir=/etc    \
                --localstatedir=/var \
                --disable-docs       \
                --docdir=/usr/share/doc/fontconfig-2.13.0 &&
    make
    
    make check

    sudo make install

    sudo install -v -dm755 \
            /usr/share/{man/man{1,3,5},doc/fontconfig-2.13.0/fontconfig-devel} &&
    sudo install -v -m644 fc-*/*.1         /usr/share/man/man1 &&
    sudo install -v -m644 doc/*.3          /usr/share/man/man3 &&
    sudo install -v -m644 doc/fonts-conf.5 /usr/share/man/man5 &&
    sudo install -v -m644 doc/fontconfig-devel/* \
                                      /usr/share/doc/fontconfig-2.13.0/fontconfig-devel &&
    sudo install -v -m644 doc/*.{pdf,sgml,txt,html} \
                                      /usr/share/doc/fontconfig-2.13.0

    fc-list

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_Xorg_libraries_() {
    set -e; set -v; set -x;
    pushd $WD

    cat > lib-7.md5 << "EOF"
c5ba432dd1514d858053ffe9f4737dd8  xtrans-1.3.5.tar.bz2
6b0f83e851b3b469dd660f3a95ac3e42  libX11-1.6.6.tar.bz2
52df7c4c1f0badd9f82ab124fb32eb97  libXext-1.3.3.tar.bz2
d79d9fe2aa55eb0f69b1a4351e1368f7  libFS-1.0.7.tar.bz2
addfb1e897ca8079531669c7c7711726  libICE-1.0.9.tar.bz2
499a7773c65aba513609fe651853c5f3  libSM-1.2.2.tar.bz2
eeea9d5af3e6c143d0ea1721d27a5e49  libXScrnSaver-1.2.3.tar.bz2
8f5b5576fbabba29a05f3ca2226f74d3  libXt-1.1.5.tar.bz2
41d92ab627dfa06568076043f3e089e4  libXmu-1.1.2.tar.bz2
20f4627672edb2bd06a749f11aa97302  libXpm-3.5.12.tar.bz2
e5e06eb14a608b58746bdd1c0bd7b8e3  libXaw-1.0.13.tar.bz2
07e01e046a0215574f36a3aacb148be0  libXfixes-5.0.3.tar.bz2
f7a218dcbf6f0848599c6c36fc65c51a  libXcomposite-0.4.4.tar.bz2
802179a76bded0b658f4e9ec5e1830a4  libXrender-0.9.10.tar.bz2
58fe3514e1e7135cf364101e714d1a14  libXcursor-1.1.15.tar.bz2
0cf292de2a9fa2e9a939aefde68fd34f  libXdamage-1.1.4.tar.bz2
0920924c3a9ebc1265517bdd2f9fde50  libfontenc-1.1.3.tar.bz2
b7ca87dfafeb5205b28a1e91ac3efe85  libXfont2-2.0.3.tar.bz2
331b3a2a3a1a78b5b44cfbd43f86fcfe  libXft-2.3.2.tar.bz2
1f0f2719c020655a60aee334ddd26d67  libXi-1.7.9.tar.bz2
0d5f826a197dae74da67af4a9ef35885  libXinerama-1.1.4.tar.bz2
28e486f1d491b757173dd85ba34ee884  libXrandr-1.5.1.tar.bz2
5d6d443d1abc8e1f6fc1c57fb27729bb  libXres-1.2.0.tar.bz2
ef8c2c1d16a00bd95b9fdcef63b8a2ca  libXtst-1.2.3.tar.bz2
210b6ef30dda2256d54763136faa37b9  libXv-1.0.11.tar.bz2
4cbe1c1def7a5e1b0ed5fce8e512f4c6  libXvMC-1.0.10.tar.bz2
d7dd9b9df336b7dd4028b6b56542ff2c  libXxf86dga-1.1.4.tar.bz2
298b8fff82df17304dfdb5fe4066fe3a  libXxf86vm-1.1.4.tar.bz2
d2f1f0ec68ac3932dd7f1d9aa0a7a11c  libdmx-1.1.4.tar.bz2
8f436e151d5106a9cfaa71857a066d33  libpciaccess-0.14.tar.bz2
4a4cfeaf24dab1b991903455d6d7d404  libxkbfile-1.0.9.tar.bz2
42dda8016943dc12aff2c03a036e0937  libxshmfence-1.3.tar.bz2
EOF

    mkdir lib &&
    cd lib &&
    grep -v '^#' ../lib-7.md5 | awk '{print $2}' | wget -i- -c \
        -B https://www.x.org/pub/individual/lib/ &&
    md5sum -c ../lib-7.md5

    for package in $(grep -v '^#' ../lib-7.md5 | awk '{print $2}')
    do
      packagedir=${package%.tar.bz2}
      tar -xf $package
      pushd $packagedir
      case $packagedir in
        libICE* )
          ./configure $XORG_CONFIG ICE_LIBS=-lpthread
        ;;

        libXfont2-[0-9]* )
          ./configure $XORG_CONFIG --disable-devel-docs
        ;;

        libXt-[0-9]* )
          ./configure $XORG_CONFIG \
                      --with-appdefaultdir=/etc/X11/app-defaults
        ;;

        * )
          ./configure $XORG_CONFIG
        ;;
      esac
      make
      make check 2>&1 | tee ../$packagedir-make_check.log
      sudo make install
      popd
      rm -rf $packagedir
      sudo /sbin/ldconfig
    done

    echo -e "\033[1;33mnow run \033[1;32mgrep -A9 summary *make_check.log\033[0m"

    set +x; set +v; set +e
}

_x_install_xcb_util_() {
    set -e; set -v; set -x; url=https://xcb.freedesktop.org/dist/xcb-util-0.4.0.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    make
    sudo make install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_xcb_util_image_() {
    set -e; set -v; set -x; url=https://xcb.freedesktop.org/dist/xcb-util-image-0.4.0.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    make
    LD_LIBRARY_PATH=$XORG_PREFIX/lib make check
    sudo make install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_xcb_util_keysyms_() {
    set -e; set -v; set -x; url=https://xcb.freedesktop.org/dist/xcb-util-keysyms-0.4.0.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    make
    sudo make install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_xcb_util_renderutil_() {
    set -e; set -v; set -x; url=https://xcb.freedesktop.org/dist/xcb-util-renderutil-0.3.9.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    make
    sudo make install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_xcb_util_wm_() {
    set -e; set -v; set -x; url=https://xcb.freedesktop.org/dist/xcb-util-wm-0.4.1.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    make
    sudo make install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_xcb_util_cursor_() {
    set -e; set -v; set -x; url=https://xcb.freedesktop.org/dist/xcb-util-cursor-0.1.3.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    make
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

_x_install_libpng() {
    _x_wrap_  _x_install_libpng_ && $WRAPPER
}

_x_install_FreeType() {
    _x_wrap_  _x_install_FreeType_ && $WRAPPER
}

_x_install_HarfBuzz() {
    _x_wrap_  _x_install_HarfBuzz_ && $WRAPPER
}

_x_install_ICU() {
    _x_wrap_  _x_install_ICU_ && $WRAPPER
    icuinfo
}

_x_install_Fontconfig() {
    _x_wrap_  _x_install_Fontconfig_ && $WRAPPER
}

_x_install_Xorg_libraries() {
    _x_wrap_  _x_install_Xorg_libraries_ && $WRAPPER
}

_x_install_xcb_util() {
    _x_wrap_  _x_install_xcb_util_ && $WRAPPER
}

_x_install_xcb_util_image() {
    _x_wrap_  _x_install_xcb_util_image_ && $WRAPPER
}

_x_install_xcb_util_keysyms() {
    _x_wrap_  _x_install_xcb_util_keysyms_ && $WRAPPER
}

_x_install_xcb_util_renderutil() {
    _x_wrap_  _x_install_xcb_util_renderutil_ && $WRAPPER
}

_x_install_xcb_util_wm() {
    _x_wrap_  _x_install_xcb_util_wm_ && $WRAPPER
}

_x_install_xcb_util_cursor() {
    _x_wrap_  _x_install_xcb_util_cursor_ && $WRAPPER
}

