#!/usr/bin/env bash

set -ex

cd "$(dirname "$0")/.."

openssl ca -gencrl \
    -config etc/root-ca.conf \
    -out data/crl/root-ca.crl

openssl ca -gencrl \
    -config etc/signing-ca.conf \
    -out data/crl/signing-ca.crl
