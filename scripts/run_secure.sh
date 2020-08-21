#!/usr/bin/env bash
set -e

THISDIR=$(pwd)

PATH=$PWD/build-deps/target/bin:$PATH

s6-tlsserver -- 127.0.0.1 4444 ./build/.built/bin/httpd
