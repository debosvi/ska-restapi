#!/usr/bin/env bash
set -e

SCRIPTDIR=$(dirname "$0")

DOMAIN=aquaplouf.mooo.com
KEYSIZE=4096

# PATH=$PWD/build-deps/target/native-cygwin/bin:$PATH
PATH=$PWD/build-deps/pkg/libressl-native-cygwin/bin:$PATH

rm -fv $DOMAIN.* ca.*

printf "Generate certs\n"

openssl genrsa -out $DOMAIN.key $KEYSIZE
openssl req -config $SCRIPTDIR/configs/aquaplouf.ssl.config -new -key $DOMAIN.key -out $DOMAIN.csr -verbose

openssl genrsa -out ca.key $KEYSIZE
openssl req -config $SCRIPTDIR/configs/aquaplouf.ssl.config -new -x509 -key ca.key -out ca.crt -verbose
openssl x509 -req -in $DOMAIN.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out $DOMAIN.crt
cat $DOMAIN.crt ca.crt > $DOMAIN.bundle.crt
