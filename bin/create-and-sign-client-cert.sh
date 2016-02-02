#!/usr/bin/env bash

split_common_name() {
    set +x
    declare -a domain_components_list=($(echo $1 | sed 's/[.]/ /g'))
    n=$((${#domain_components_list[@]} - 1))
    i=0
    while [ $i -le $n ]; do
        echo "export domainComponent$i=\"${domain_components_list[$(($n - $i))]}\""
        i=$(($i + 1))
    done
    set -x
}

if [ -e "data/certs/$1.crt" ]; then
    echo "Fatal: certificate for $1 already exists: data/certs/$1.crt" >&2
    exit 1
fi

set -ex

cd "$(dirname "$0")/.."

export CN="$1"
export companyName="${SSL_COMPANY_NAME:-Simple Inc}"
export ouName="${SSL_ORG_NAME:-Operations}"
eval "$(split_common_name $CN)"

test -n "$CN"
test -n "$domainComponent0"
test -n "$domainComponent1"
test -n "$companyName"
test -n "$ouName"

openssl req -verbose -new \
    -config etc/client.conf \
    -out data/certs/$CN.csr \
    -keyout data/certs/$CN.key \
    -subj "/DC=$domainComponent0/DC=$domainComponent1/O=$companyName/OU=$ouName/CN=$CN"

openssl ca \
    -config etc/signing-ca.conf \
    -in data/certs/$CN.csr \
    -out data/certs/$CN.crt \
    -extensions client_ext

serial="$(openssl x509 -in data/certs/$CN.crt -noout -serial | cut -f 2 -d =)"

cd data/ca/signing-ca/certs
ln -snf $serial.pem $CN.pem
