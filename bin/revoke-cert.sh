#!/usr/bin/env bash

export cert_file="$1"
export crl_reason="$2"

if [ -z "$cert_file" -o -z "$crl_reason" ]; then
    echo "Usage: $(basename $0) path/to/cn.pem crl_reason" >&2
    echo >&2
    echo "crl_reason: unspecified, keyCompromise, CACompromise, affiliationChanged," >&2
    echo "            superseded, cessationOfOperation, certificateHold, removeFromCRL" >&2
    exit 1
fi

set -ex

cd "$(dirname "$0")/.."

mkdir -p data/certs/revoked

test -n "$cert_file"

subj_cn="$(openssl x509 -in $cert_file -noout -subject | grep -o 'CN=.*\>')"
CN=${subj_cn:3}
revoked_time=$(date +%Y%m%d.%H%M%S)

openssl ca \
    -config etc/signing-ca.conf \
    -revoke $cert_file \
    -crl_reason $crl_reason

for file in data/certs/$CN.* ; do
    mv $file data/certs/revoked/$revoked_time-$(basename $file)
done

./bin/gen-crl.sh
