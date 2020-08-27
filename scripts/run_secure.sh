#!/usr/bin/env bash
set -e

THISDIR=$(pwd)

PATH=$PWD/build-deps/target/bin:$PATH

export KEYFILE=$THISDIR/aquaplouf.mooo.com.key
export CERTFILE=$THISDIR/aquaplouf.mooo.com.bundle.crt
export CAFILE=$THISDIR/ca.crt

s6-tlsserver -- 127.0.0.1 4444 ./build/.built/bin/httpd
