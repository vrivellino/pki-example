#!/usr/bin/env bash
set -ex

cd "$(dirname "$0")/.."

gen_random_serial() {
    for h in $(dd if=/dev/urandom bs=8 count=1 2>/dev/null | od -A n -t x1) ; do
        echo -n $h | tr '[[:lower:]]' '[[:upper:]]'
    done
    echo
}

init_ca() {
    ca_name="$1"
    test -n "$ca_name"

    mkdir -p data/ca/$ca_name-ca/private data/ca/$ca_name-ca/db data/ca/$ca_name-ca/certs data/crl data/certs
    chmod 700 data/ca/$ca_name-ca/private

    if [ -e data/ca/$ca_name-ca/db/$ca_name-ca.db ]; then
        echo 'Fatal: root CA database already exists' >&2
        exit 1
    fi

    cp /dev/null data/ca/$ca_name-ca/db/$ca_name-ca.db
    cp /dev/null data/ca/$ca_name-ca/db/$ca_name-ca.db.attr

    set +x
    crt_serial="$(gen_random_serial)"
    crl_serial="$(gen_random_serial)"
    set -x
    echo "$crt_serial" > data/ca/$ca_name-ca/db/$ca_name-ca.crt.srl
    echo "$crl_serial" > data/ca/$ca_name-ca/db/$ca_name-ca.crl.srl

    openssl req -new \
        -config etc/$ca_name-ca.conf \
        -out data/ca/$ca_name-ca.csr \
        -keyout data/ca/$ca_name-ca/private/$ca_name-ca.key
}

init_ca root
openssl ca -selfsign \
    -config etc/root-ca.conf \
    -in data/ca/root-ca.csr \
    -out data/ca/root-ca.crt \
    -extensions root_ca_ext

init_ca signing
openssl ca \
    -config etc/root-ca.conf \
    -in data/ca/signing-ca.csr \
    -out data/ca/signing-ca.crt \
    -extensions signing_ca_ext
