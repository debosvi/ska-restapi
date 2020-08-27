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
