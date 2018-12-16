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

_x_install_libdrm_() {
    set -e; set -v; set -x; url=https://dri.freedesktop.org/libdrm/libdrm-2.4.93.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    mkdir build &&
    cd    build &&

    meson --prefix=$XORG_PREFIX -Dudev=true &&
    ninja
    sudo ninja install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_funcsigs_() {
    set -e; set -v; set -x; url=https://files.pythonhosted.org/packages/source/f/funcsigs/funcsigs-1.0.2.tar.gz
    pushd $WD
    _blfs_download_extract_and_enter $url

    sudo python setup.py install --optimize=1

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_beaker_() {
    set -e; set -v; set -x; url=https://files.pythonhosted.org/packages/source/B/Beaker/Beaker-1.10.0.tar.gz
    pushd $WD
    _blfs_download_extract_and_enter $url

    sudo python setup.py install --optimize=1
    sudo python3 setup.py install --optimize=1

    popd; set +x; set +v; set +e
}

_x_install_MarkupSafe_() {
    set -e; set -v; set -x; url=https://files.pythonhosted.org/packages/source/M/MarkupSafe/MarkupSafe-1.0.tar.gz
    pushd $WD
    _blfs_download_extract_and_enter $url

    sudo python setup.py build
    sudo python setup.py install --optimize=1
    sudo python3 setup.py build
    sudo python3 setup.py install --optimize=1

    popd; set +x; set +v; set +e
}

_x_install_mako_() {
    set -e; set -v; set -x; url=https://files.pythonhosted.org/packages/source/M/Mako/Mako-1.0.4.tar.gz
    pushd $WD
    _blfs_download_extract_and_enter $url

    sudo python setup.py install --optimize=1
    sudo sed -i "s:mako-render:&3:g" setup.py
    sudo python3 setup.py install --optimize=1

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_libva_() {
    set -e; set -v; set -x;

    url=https://github.com/intel/libva/releases/download/2.2.0/libva-2.2.0.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url
    ./configure $XORG_CONFIG &&
    make
    sudo make install
    popd

    sleep 10
    
    url=https://github.com/intel/intel-vaapi-driver/releases/download/2.2.0/intel-vaapi-driver-2.2.0.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url
    ./configure $XORG_CONFIG &&
    make
    sudo make install
    popd

    set +x; set +v; set +e
}

_x_install_libvdpau_() {
    set -e; set -v; set -x; url=https://people.freedesktop.org/~aplattner/vdpau/libvdpau-1.1.1.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG \
                --docdir=/usr/share/doc/libvdpau-1.1.1 &&
    make
    make check
    sudo make install

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_libxml2_() {
    set -e; set -v; set -x; url=http://xmlsoft.org/sources/libxml2-2.9.8.tar.gz
    pushd $WD
    wget http://www.w3.org/XML/Test/xmlts20130923.tar.gz
    wget http://www.linuxfromscratch.org/patches/blfs/8.3/libxml2-2.9.8-python3_hack-1.patch
    _blfs_download_extract_and_enter $url

    patch -Np1 -i ../libxml2-2.9.8-python3_hack-1.patch
    sed -i '/_PyVerify_fd/,+1d' python/types.c
    ./configure --prefix=/usr    \
                --disable-static \
                --with-history   \
                --with-python=/usr/bin/python3 &&
    make
    #tar xf ../xmlts20130923.tar.gz

    sudo make install

    echo -e "\033[1;32m**************************************************\033[0m"

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_Wayland_() {
    set -e; set -v; set -x; url=https://wayland.freedesktop.org/releases/wayland-1.15.0.tar.xz
    pushd $WD
    _blfs_download_extract_and_enter $url
    ./configure --prefix=/usr    \
                --disable-static \
                --disable-documentation &&
    make
    make check
    sudo make install

    echo -e "\033[1;32m**************************************************\033[0m"

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_Wayland_Protocols_() {
    set -e; set -v; set -x; url=https://wayland.freedesktop.org/releases/wayland-protocols-1.15.tar.xz
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure --prefix=/usr &&
    make
    make check
    sudo make install

    echo -e "\033[1;32m**************************************************\033[0m"

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_Mesa_() {
    set -e; set -v; set -x; url=https://mesa.freedesktop.org/archive/mesa-18.1.6.tar.xz
    pushd $WD
    wget http://www.linuxfromscratch.org/patches/blfs/8.3/mesa-18.1.6-add_xdemos-1.patch
    _blfs_download_extract_and_enter $url

    patch -Np1 -i ../mesa-18.1.6-add_xdemos-1.patch
    GLL_DRV="i915,r600,nouveau,radeonsi,svga,swrast"
    ./configure CFLAGS='-O2' CXXFLAGS='-O2' LDFLAGS=-lLLVM \
                --prefix=$XORG_PREFIX              \
                --sysconfdir=/etc                  \
                --enable-texture-float             \
                --enable-osmesa                    \
                --enable-xa                        \
                --enable-glx-tls                   \
                --with-platforms="drm,x11,wayland" \
                --with-gallium-drivers=$GLL_DRV    &&

    unset GLL_DRV &&

    make
    make -C xdemos DEMOS_PREFIX=$XORG_PREFIX
    make -k check
    sudo make install

    install -v -dm755 /usr/share/doc/mesa-18.1.6 &&
    cp -rfv docs/* /usr/share/doc/mesa-18.1.6

    echo -e "\033[1;32m**************************************************\033[0m"

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_xbitmaps_() {
    set -e; set -v; set -x; url=https://www.x.org/pub/individual/data/xbitmaps-1.1.2.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    sudo make install

    echo -e "\033[1;32m**************************************************\033[0m"

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_Xorg_applications_() {
    set -e; set -v; set -x;
    pushd $WD

    cat > app-7.md5 << "EOF"
3b9b79fa0f9928161f4bad94273de7ae  iceauth-1.0.8.tar.bz2
c4a3664e08e5a47c120ff9263ee2f20c  luit-1.1.1.tar.bz2
18c429148c96c2079edda922a2b67632  mkfontdir-1.0.7.tar.bz2
987c438e79f5ddb84a9c5726a1610819  mkfontscale-1.1.3.tar.bz2
e475167a892b589da23edf8edf8c942d  sessreg-1.1.1.tar.bz2
2c47a1b8e268df73963c4eb2316b1a89  setxkbmap-1.3.1.tar.bz2
3a93d9f0859de5d8b65a68a125d48f6a  smproxy-1.0.6.tar.bz2
f0b24e4d8beb622a419e8431e1c03cd7  x11perf-1.6.0.tar.bz2
f3f76cb10f69b571c43893ea6a634aa4  xauth-1.0.10.tar.bz2
d50cf135af04436b9456a5ab7dcf7971  xbacklight-1.2.2.tar.bz2
9956d751ea3ae4538c3ebd07f70736a0  xcmsdb-1.0.5.tar.bz2
b58a87e6cd7145c70346adad551dba48  xcursorgen-1.0.6.tar.bz2
8809037bd48599af55dad81c508b6b39  xdpyinfo-1.3.2.tar.bz2
480e63cd365f03eb2515a6527d5f4ca6  xdriinfo-1.0.6.tar.bz2
249bdde90f01c0d861af52dc8fec379e  xev-1.2.2.tar.bz2
90b4305157c2b966d5180e2ee61262be  xgamma-1.0.6.tar.bz2
f5d490738b148cb7f2fe760f40f92516  xhost-1.0.7.tar.bz2
6a889412eff2e3c1c6bb19146f6fe84c  xinput-1.6.2.tar.bz2
12610df19df2af3797f2c130ee2bce97  xkbcomp-1.4.2.tar.bz2
c747faf1f78f5a5962419f8bdd066501  xkbevd-1.1.4.tar.bz2
502b14843f610af977dffc6cbf2102d5  xkbutils-1.0.4.tar.bz2
938177e4472c346cf031c1aefd8934fc  xkill-1.0.5.tar.bz2
5dcb6e6c4b28c8d7aeb45257f5a72a7d  xlsatoms-1.1.2.tar.bz2
4fa92377e0ddc137cd226a7a87b6b29a  xlsclients-1.1.4.tar.bz2
e50ffae17eeb3943079620cb78f5ce0b  xmessage-1.0.5.tar.bz2
723f02d3a5f98450554556205f0a9497  xmodmap-1.0.9.tar.bz2
eaac255076ea351fd08d76025788d9f9  xpr-1.0.5.tar.bz2
4becb3ddc4674d741487189e4ce3d0b6  xprop-1.2.3.tar.bz2
ebffac98021b8f1dc71da0c1918e9b57  xrandr-1.5.0.tar.bz2
96f9423eab4d0641c70848d665737d2e  xrdb-1.1.1.tar.bz2
c56fa4adbeed1ee5173f464a4c4a61a6  xrefresh-1.0.6.tar.bz2
70ea7bc7bacf1a124b1692605883f620  xset-1.2.4.tar.bz2
5fe769c8777a6e873ed1305e4ce2c353  xsetroot-1.1.2.tar.bz2
558360176b718dee3c39bc0648c0d10c  xvinfo-1.1.3.tar.bz2
11794a8eba6d295a192a8975287fd947  xwd-1.0.7.tar.bz2
9a505b91ae7160bbdec360968d060c83  xwininfo-1.1.4.tar.bz2
79972093bb0766fcd0223b2bd6d11932  xwud-1.0.5.tar.bz2
EOF

    mkdir app &&
    cd app &&
    grep -v '^#' ../app-7.md5 | awk '{print $2}' | wget -i- -c \
        -B https://www.x.org/pub/individual/app/ &&
    md5sum -c ../app-7.md5
    for package in $(grep -v '^#' ../app-7.md5 | awk '{print $2}')
    do
      packagedir=${package%.tar.bz2}
      tar -xf $package
      pushd $packagedir
         case $packagedir in
           luit-[0-9]* )
             sed -i -e "/D_XOPEN/s/5/6/" configure
           ;;
         esac

         ./configure $XORG_CONFIG
         make
         sudo make install
      popd
      rm -rf $packagedir
    done
    sudo rm -f $XORG_PREFIX/bin/xkeystone

    echo -e "\033[1;32m**************************************************\033[0m"

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_xcursor_themes_() {
    set -e; set -v; set -x; url=https://www.x.org/pub/individual/data/xcursor-themes-1.0.5.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    make
    sudo make install

    echo -e "\033[1;32m**************************************************\033[0m"

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_Xorg_Fonts_() {
    set -e; set -v; set -x;
    pushd $WD

    cat > font-7.md5 << "EOF"
23756dab809f9ec5011bb27fb2c3c7d6  font-util-1.3.1.tar.bz2
0f2d6546d514c5cc4ecf78a60657a5c1  encodings-1.0.4.tar.bz2
6d25f64796fef34b53b439c2e9efa562  font-alias-1.0.3.tar.bz2
fcf24554c348df3c689b91596d7f9971  font-adobe-utopia-type1-1.0.4.tar.bz2
e8ca58ea0d3726b94fe9f2c17344be60  font-bh-ttf-1.0.3.tar.bz2
53ed9a42388b7ebb689bdfc374f96a22  font-bh-type1-1.0.3.tar.bz2
bfb2593d2102585f45daa960f43cb3c4  font-ibm-type1-1.0.3.tar.bz2
6306c808f7d7e7d660dfb3859f9091d2  font-misc-ethiopic-1.0.3.tar.bz2
3eeb3fb44690b477d510bbd8f86cf5aa  font-xfree86-type1-1.0.4.tar.bz2
EOF

    mkdir font &&
    cd font &&
    grep -v '^#' ../font-7.md5 | awk '{print $2}' | wget -i- -c \
        -B https://www.x.org/pub/individual/font/ &&
    md5sum -c ../font-7.md5

    for package in $(grep -v '^#' ../font-7.md5 | awk '{print $2}')
    do
      packagedir=${package%.tar.bz2}
      tar -xf $package
      pushd $packagedir
        ./configure $XORG_CONFIG
        make
        sudo make install
      popd
      sudo rm -rf $packagedir
    done

    sudo install -v -d -m755 /usr/share/fonts                               &&
    sudo ln -svfn $XORG_PREFIX/share/fonts/X11/OTF /usr/share/fonts/X11-OTF &&
    sudo ln -svfn $XORG_PREFIX/share/fonts/X11/TTF /usr/share/fonts/X11-TTF

    echo -e "\033[1;32m**************************************************\033[0m"

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_XKeyboardConfig_() {
    set -e; set -v; set -x; url=https://www.x.org/pub/individual/data/xkeyboard-config/xkeyboard-config-2.24.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG --with-xkb-rules-symlink=xorg &&
    make
    sudo make install

    echo -e "\033[1;32m**************************************************\033[0m"

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_Pixman_() {
    set -e; set -v; set -x; url=https://www.cairographics.org/releases/pixman-0.34.0.tar.gz
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure --prefix=/usr --disable-static &&
    make
    make check
    sudo make install

    echo -e "\033[1;32m**************************************************\033[0m"

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_libepoxy_() {
    set -e; set -v; set -x; url=https://github.com/anholt/libepoxy/releases/download/1.5.2/libepoxy-1.5.2.tar.xz
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure --prefix=/usr &&
    make
    make check
    sudo make install

    echo -e "\033[1;32m**************************************************\033[0m"

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_Xorg_Server_() {
    set -e; set -v; set -x; url=https://www.x.org/pub/individual/xserver/xorg-server-1.20.1.tar.bz2
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG          \
                --enable-glamor       \
                --enable-suid-wrapper \
                --with-xkb-output=/var/lib/xkb &&
    make
    #sudo ldconfig && make check
    sudo make install &&
    sudo mkdir -pv /etc/X11/xorg.conf.d

    echo -e "\033[1;32m**************************************************\033[0m"

    popd; _blfs_cleanup $url; set +x; set +v; set +e
}

_x_install_libva_rebuild_() {
    _x_install_libva
}

_x_install___() {
    set -e; set -v; set -x; url=
    pushd $WD
    _blfs_download_extract_and_enter $url

    ./configure $XORG_CONFIG
    make
    #make check
    sudo make install

    echo -e "\033[1;32m**************************************************\033[0m"

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

_x_install_libdrm() {
    _x_wrap_  _x_install_libdrm_ && $WRAPPER
}

_x_install_funcsigs() {
    _x_wrap_  _x_install_funcsigs_ && $WRAPPER
}

_x_install_beaker() {
    _x_wrap_  _x_install_beaker_ && $WRAPPER
}

_x_install_MarkupSafe() {
    _x_wrap_  _x_install_MarkupSafe_ && $WRAPPER
}

_x_install_mako() {
    _x_wrap_  _x_install_mako_ && $WRAPPER
}

_x_install_libva() {
    _x_wrap_  _x_install_libva_ && $WRAPPER
}

_x_install_libvdpau() {
    _x_wrap_  _x_install_libvdpau_ && $WRAPPER
}

_x_install_libxml2() {
    _x_wrap_  _x_install_libxml2_ && $WRAPPER
}

_x_install_Wayland() {
    _x_wrap_  _x_install_Wayland_ && $WRAPPER
}

_x_install_Wayland_Protocols() {
    _x_wrap_  _x_install_Wayland_Protocols_ && $WRAPPER
}

_x_install_Mesa() {
    _x_wrap_  _x_install_Mesa_ && $WRAPPER
}

_x_install_xbitmaps() {
    _x_wrap_  _x_install_xbitmaps_ && $WRAPPER
}

_x_install_Xorg_applications() {
    _x_wrap_  _x_install_Xorg_applications_ && $WRAPPER
}

_x_install_xcursor_themes() {
    _x_wrap_  _x_install_xcursor_themes_ && $WRAPPER
}

_x_install_Xorg_Fonts() {
    _x_wrap_  _x_install_Xorg_Fonts_ && $WRAPPER
}

_x_install_XKeyboardConfig() {
    _x_wrap_  _x_install_XKeyboardConfig_ && $WRAPPER
}

_x_install_Pixman() {
    _x_wrap_  _x_install_Pixman_ && $WRAPPER
}

_x_install_libepoxy() {
    _x_wrap_  _x_install_libepoxy_ && $WRAPPER
}

_x_install_Xorg_Server() {
    _x_wrap_  _x_install_Xorg_Server_ && $WRAPPER
}

_x_install_libva_rebuild() {
    _x_wrap_  _x_install_libva_rebuild_ && $WRAPPER
}

