#!/usr/bin/env bash
set -e

THISDIR=$(pwd)
TOPDIR=$THISDIR/build-deps

DOWNLOADDIR=$TOPDIR/downloads
BUILDDIR=$TOPDIR/build
PACKAGEDIR=$TOPDIR/pkg
DISTDIR=$TOPDIR/dist
PATCHDIR=$TOPDIR/patches
SYSDEPSDIR=$TOPDIR/sysdeps
STAGINGDIR=$TOPDIR/staging
TARGETDIR=$TOPDIR/target

dl() {
    url=$1
    dest=$2
    if [[ -z "$dest" ]] ; then
        dest="$DOWNLOADDIR/$(basename $url)"
    fi
    if [[ -f "$dest" ]]; then
        printf "$(basename $url) already there\n"
    else
        printf "Downloading $(basename $url)\n"
        wget -c -q -O "$dest" "$url"
    fi
}

# point to make
MAKE_4x="make"

printf "Creating main dirs\n"
mkdir -p "$DOWNLOADDIR" "$BUILDDIR" "$PACKAGEDIR" "$DISTDIR" "$SYSDEPSDIR" "$STAGINGDIR" "$TARGETDIR"

# all packages
skarnet_all_packages=(
skalibs
execline
s6
s6-portable-utils
# s6-linux-utils
s6-dns
libressl
s6-networking
# s6-rc
)

# linux packages
skarnet_linux_packages=("${skarnet_all_packages[@]}")

# portable packages
skarnet_portable_packages=(
skalibs
execline
s6
s6-portable-utils
# s6-rc
)

platform=$(uname -o | tr A-Z a-z | tr "/" "-")
cygwin_check="cygwin"

targets_order=(
'native-'${platform}
)

# target platforms + simplified
declare -A targets
targets['native-'${platform}]=native

# software versions
declare -A versions
versions[skalibs]=2.9.2.1
versions[execline]=2.6.1.0
versions[s6]=2.9.2.0
versions[s6-portable-utils]=2.2.2.4
versions[s6-linux-utils]=2.5.1.2
versions[s6-dns]=2.3.2.0
versions[s6-networking]=2.3.1.2
versions[s6-rc]=0.5.1.4
versions[libressl]=3.2.0

declare -A manifests
manifests[skarnet_all_packages]="manifest.txt"
manifests[skarnet_linux_packages]="manifest-linux.txt"
manifests[skarnet_portable_packages]="manifest-portable.txt"

# downloads
printf "Downloading packages ...\n"
for package in "${skarnet_all_packages[@]}"; do
  [ ${package} != "libressl" ] && dl "http://skarnet.org/software/${package}/${package}-${versions[$package]}.tar.gz"
done
dl "https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-3.2.0.tar.gz" 

for target in "${targets_order[@]}"; do
    mkdir -p "$SYSDEPSDIR/${target}"

    declare -A includes
    includes[skalibs]=""
    includes[execline]="--with-include=$PACKAGEDIR/skalibs-$target/usr/include ${includes[skalibs]}"
    includes[s6]="--with-include=$PACKAGEDIR/execline-$target/usr/include ${includes[execline]}"
    includes[s6-portable-utils]="${includes[s6]}"
    includes[s6-linux-utils]="${includes[s6]}"
    includes[s6-dns]="${includes[s6]}"
    includes[s6-networking]="--with-include=$PACKAGEDIR/s6-dns-$target/usr/include --with-include=$PACKAGEDIR/s6-$target/usr/include ${includes[s6]}"
    includes[s6-rc]="--with-include=$PACKAGEDIR/s6-$target/usr/include ${includes[s6]}"

    declare -A libs
    libs[skalibs]=""
    libs[execline]="--with-lib=$PACKAGEDIR/skalibs-$target/usr/lib ${libs[skalibs]}"
    libs[s6]="--with-lib=$PACKAGEDIR/execline-$target/usr/lib ${libs[execline]}"
    libs[s6-portable-utils]="${libs[s6]}"
    libs[s6-linux-utils]="${libs[s6]}"
    libs[s6-dns]="${libs[s6]}"
    libs[s6-networking]="--with-lib=$PACKAGEDIR/s6-dns-$target/usr/lib --with-lib=$PACKAGEDIR/s6-${target}/usr/lib ${libs[s6]}"
    libs[s6-rc]="--with-lib=$PACKAGEDIR/s6-$target/usr/lib ${libs[s6]}"

    declare -A sysdeps
    sysdeps[skalibs]=""
    sysdeps[execline]="--with-sysdeps=$PACKAGEDIR/skalibs-$target/usr/lib/skalibs/sysdeps"
    sysdeps[s6]="${sysdeps[execline]}"
    sysdeps[s6-portable-utils]="${sysdeps[execline]}"
    sysdeps[s6-linux-utils]="${sysdeps[execline]}"
    sysdeps[s6-dns]="${sysdeps[execline]}"
    sysdeps[s6-networking]="${sysdeps[execline]}"
    sysdeps[s6-rc]="${sysdeps[execline]}"

    declare -A configopts
    configopts[skalibs]="--datadir=/etc --with-sysdep-devurandom=yes"
    [ ${platform} == ${cygwin_check} ] &&  configopts[skalibs]+=" --with-sysdep-pipe2=no --with-sysdep-ppoll=no --with-sysdep-strcasestr=no"
    configopts[execline]=""
    configopts[s6]=""
    configopts[s6-portable-utils]=""
    configopts[s6-dns]=""
    configopts[s6-networking]=""
    [ ${platform} == ${cygwin_check} ] && configopts[s6-networking]="--enable-ssl=libressl --with-ssl-path=$PACKAGEDIR/libressl-${target}"
    configopts[s6-rc]=""

    build_install_skarnet_package() { # {{{
        local package=$1
        local version=${versions[$package]}
        printf "Building ${package}-${version} for ${target}\n"

        mkdir -p "$BUILDDIR/${target}"
        cd "$BUILDDIR/${target}"

        printf "\tExtracting ...\n"
        tar xf "$DOWNLOADDIR/$package-${versions[$package]}.tar.gz" -C "$BUILDDIR/${target}"

        cd "$BUILDDIR/${target}/${package}-${versions[$package]}"

        printf "\tConfiguring ...\n"
        STATIC_LIBC_OPTS=""
        [ ${platform} == ${cygwin_check} ] && STATIC_LIBC_OPTS="--enable-static-libc "
        
        ./configure \
          --libdir=/usr/lib \
          --enable-static \
          --disable-shared \
          ${STATIC_LIBC_OPTS} \
          ${includes[$package]} \
          ${libs[$package]} \
          ${sysdeps[$package]} \
          ${configopts[$package]} > /dev/null

        printf "\tMaking ...\n"
        ${MAKE_4x} -j > /dev/null

        printf "\tInstalling ...\n"
        rm -rf "$PACKAGEDIR/${package}-${target}" 
        ${MAKE_4x} DESTDIR="$PACKAGEDIR/${package}-${target}" install >/dev/null
    } # }}}

    build_install_libressl_package() { # {{{
        local package=$1
        local version=${versions[$package]}
        printf "Building ${package}-${version} for ${target}\n"

        mkdir -p "$BUILDDIR/${target}"
        cd "$BUILDDIR/${target}"

        printf "\tExtracting ...\n"
        tar xf "$DOWNLOADDIR/$package-${versions[$package]}.tar.gz" -C "$BUILDDIR/${target}"

        cd "$BUILDDIR/${target}/${package}-${versions[$package]}"
        
        printf "\tConfiguring ...\n"
        mkdir -p build
        cd build		
        cmake -DCMAKE_INSTALL_PREFIX="$PACKAGEDIR/${package}-${target}" -DCMAKE_INSTALL_LIBDIR="$PACKAGEDIR/${package}-${target}/usr/lib" .. > /dev/null
        
        printf "\tMaking ...\n"
        ${MAKE_4x} -j > /dev/null

        printf "\tInstalling ...\n"
        rm -rf "$PACKAGEDIR/${package}-${target}" 
        ${MAKE_4x} install > /dev/null
    } # }}}

    tar_skarnet_package() { # {{{
        local package=$1
        local version=${versions[$package]}
        printf "Packaging ${package}-${version} for ${target}\n"
        
        for bindir in 'usr/bin' 'bin' 'usr/sbin' 'sbin'; do
            if [[ -d "$PACKAGEDIR/${package}-${target}/$bindir" ]]; then
                find "$PACKAGEDIR/${package}-${target}/$bindir" -type f -exec strip {} \;
            fi
        done

        tar -czf "$DISTDIR/${package}-${versions[$package]}-linux-${targets[$target]}-bin.tar.gz" \
            --owner 0 \
            --group 0 \
            --exclude "usr/lib" \
            --exclude "usr/include" \
            --exclude "include" \
            --exclude "share" \
            -C "$PACKAGEDIR/${package}-${target}" .

        local dev_dirs=""
        if [[ -d "$PACKAGEDIR/${package}-${target}/usr/lib" ]]; then
            dev_dirs="${dev_dirs} usr/lib"
        fi
        if [[ -d "$PACKAGEDIR/${package}-${target}/usr/include" ]]; then
            dev_dirs="${dev_dirs} usr/include"
        fi
        if [[ -d "$PACKAGEDIR/${package}-${target}/include" ]]; then
            dev_dirs="${dev_dirs} include"
        fi
        if [[ -d "$PACKAGEDIR/${package}-${target}/share" ]]; then
            dev_dirs="${dev_dirs} share"
        fi
        if [[ -n "${dev_dirs}" ]]; then
            tar -czf "$DISTDIR/${package}-${versions[$package]}-linux-${targets[$target]}-dev.tar.gz" \
                --owner 0 \
                --group 0 \
            -C "$PACKAGEDIR/${package}-${target}" $dev_dirs
        fi
    } # }}}

    # install skarnet packages
    for package in "${skarnet_all_packages[@]}"; do
        printf "Running target ${target}...\n"
        [ ${package} != "libressl" ] && build_install_skarnet_package ${package}
        [ ${package} == "libressl" ] && build_install_libressl_package ${package}
        tar_skarnet_package ${package}
        printf "Complete \n\n"		
    done
done

printf "Populating staging ...\n"
rm -rf $STAGINGDIR/*
for archive in $(find $DISTDIR -name "*dev*"); do 
    name=$(echo $archive | grep -o '[^/]*$')
    printf "\t$name\n"
    tar -C $STAGINGDIR -xf $archive
done

printf "Populating target ...\n"
rm -rf $TARGETDIR/*
for archive in $(find $DISTDIR -name "*bin*"); do 
    name=$(echo $archive | grep -o '[^/]*$')
    printf "\t$name\n"
    tar -C $TARGETDIR -xf $archive
done
