#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
. data/ca-env.sh

set -x

openssl ca -gencrl \
    -config etc/root-ca.conf \
    -out data/crl/root-ca.crl

openssl ca -gencrl \
    -config etc/signing-ca.conf \
    -out data/crl/signing-ca.crl
