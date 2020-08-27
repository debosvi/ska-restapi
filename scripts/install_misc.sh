#!/usr/bin/env bash
set -e

THISDIR=$(pwd)
TOPDIR=$THISDIR/build-deps

DOWNLOADDIR=$TOPDIR/downloads
BUILDDIR=$TOPDIR/build
PACKAGEDIR=$TOPDIR/pkg
DISTDIR=$TOPDIR/dist
PATCHDIR=$TOPDIR/patches
STAGINGDIR=$TOPDIR/staging
TARGETDIR=$TOPDIR/target

dl() {
    url=$1
    dest=$2
    if [[ -z "$dest" ]] ; then
        dest="$DOWNLOADDIR/$(basename $url)"
	else
		dest="$DOWNLOADDIR/$dest"
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
mkdir -p "$DOWNLOADDIR" "$BUILDDIR" "$PACKAGEDIR" "$DISTDIR" "$STAGINGDIR" "$TARGETDIR"

# all packages
misc_all_packages=(
libressl
sqlite
)

platform=$(uname -o | tr A-Z a-z | tr "/" "-")

printf "Platform: ${platform}\n"
cygwin_platform_string="cywin"


cygwin_check() {
	if [[ ${cygwin_platform_string} == ${platform} ]] ; then
        return 1
    fi
	return 0
}

targets_order=(
'native-'${platform}
)

# target platforms + simplified
declare -A targets
targets['native-'${platform}]=native

# software versions
declare -A versions
versions[libressl]=3.2.0
versions[sqlite]=3.33.0

# first make targets
declare -A firsttargets
firsttargets[libressl]=""
firsttargets[sqlite]=sqlite3.h

# first make targets
declare -A paralellopts
paralellopts[libressl]="-j"
if cygwin_check; then paralellopts[libressl]="-j2"; fi
paralellopts[sqlite]="-j"

declare -A manifests
manifests[misc_all_packages]="manifest.txt"

# downloads
printf "Downloading packages ...\n"
dl "https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${versions[libressl]}.tar.gz" 
dl "https://github.com/sqlite/sqlite/archive/version-${versions[sqlite]}.tar.gz" "sqlite-${versions[sqlite]}.tar.gz"

for target in "${targets_order[@]}"; do
    # declare -A includes
    # includes[libressl]=""
	# includes[sqlite]=""

    # declare -A libs
    # libs[libressl]=""
    # libs[sqite]=""

    declare -A configopts
    configopts[libressl]="--disable-shared --enable-static --enable-nc --disable-tests"
    configopts[libressl]+=" --includedir=$PACKAGEDIR/libressl-$target/usr/include "
    configopts[libressl]+=" --libdir=$PACKAGEDIR/libressl-$target/usr/lib"
    
	configopts[sqlite]="--disable-shared --enable-static --enable-all --disable-amalgamation --disable-threadsafe"
    configopts[sqlite]+=" --includedir=$PACKAGEDIR/sqlite-$target/usr/include "
    configopts[sqlite]+=" --libdir=$PACKAGEDIR/sqlite-$target/usr/lib"
    
    build_install_package() { # {{{
        local package=$1
        local version=${versions[$package]}
		
		printf "Building ${package}-${version} for ${target}\n"
		
		mkdir -p "$BUILDDIR/${target}/${package}-${versions[$package]}"
        
        printf "\tExtracting ...\n"
        if [ ! -f "$BUILDDIR/${target}/${package}-${versions[$package]}/.tardone" ]; then 
			tar --strip-components 1 -xf "$DOWNLOADDIR/$package-${versions[$package]}.tar.gz" -C "$BUILDDIR/${target}/${package}-${versions[$package]}"
			touch "$BUILDDIR/${target}/${package}-${versions[$package]}/.tardone"
		fi

        cd "$BUILDDIR/${target}/${package}-${versions[$package]}"
        
        printf "\tConfiguring ...\n"
        if [ ! -f "$BUILDDIR/${target}/${package}-${versions[$package]}/.cfgdone" ]; then 
			./configure --prefix="$PACKAGEDIR/${package}-${target}" ${configopts[${package}]} > /dev/null
			touch "$BUILDDIR/${target}/${package}-${versions[$package]}/.cfgdone"
		fi
        
        printf "\tMaking ...\n"
        if [ ! -f "$BUILDDIR/${target}/${package}-${versions[$package]}/.mkdone" ]; then 
			[ "${firsttargets[$package]}" != "" ] && ${MAKE_4x} ${firsttargets[$package]} > /dev/null
			${MAKE_4x} ${paralellopts[$package]} > /dev/null
			touch "$BUILDDIR/${target}/${package}-${versions[$package]}/.mkdone"
		fi

        printf "\tInstalling ...\n"
        rm -rf "$PACKAGEDIR/${package}-${target}" 
        ${MAKE_4x} -j install  > /dev/null
    } # }}}

    tar_archive_package() { # {{{
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
    for package in "${misc_all_packages[@]}"; do
        printf "Running target ${target}...\n"
        build_install_package ${package}
        tar_archive_package ${package}
        printf "Complete \n\n"		
    done
done
