#!/usr/bin/env bash
set -e

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

if [ -f data/ca-env.sh ]; then
    echo 'Fatal: data/ca-env.sh exists ... aborting' >&2
    exit 1
fi

read -p 'Domain Name (ex: domain.tld): ' ca_domain
read -p 'Organization (ex: Company Name): ' org_name

domain_component_0=$(echo $ca_domain | cut -f 1 -d .)
domain_component_1=$(echo $ca_domain | cut -f 2 -d .)

set -x

test -n "$domain_component_0"
test -n "$domain_component_1"
test -n "$org_name"

cat > data/ca-env.sh << _END_
export ROOT_CA_DC_0='$domain_component_0'
export ROOT_CA_DC_1='$domain_component_1'
export ROOT_CA_ORG='$org_name'
export ROOT_CA_OU='$org_name Root CA'
export ROOT_CA_CN='$org_name Root CA'

export SIGNING_CA_DC_0='$domain_component_0'
export SIGNING_CA_DC_1='$domain_component_1'
export SIGNING_CA_ORG='$org_name'
export SIGNING_CA_OU='$org_name Signing CA'
export SIGNING_CA_CN='$org_name Signing CA'
_END_

. data/ca-env.sh

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
