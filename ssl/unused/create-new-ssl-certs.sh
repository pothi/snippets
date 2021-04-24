#!/bin/bash

# Ref:
# https://datacenteroverlords.com/2012/03/01/creating-your-own-ssl-certificate-authority/
# http://apetec.com/support/generatesan-csr.htm

DOMAIN=$1

if [ "$DOMAIN" == "" ]; then
    echo "Usage $0 example.com"; exit 1;
fi

$(which sed) -i "s/example.com/$DOMAIN/g" openssl.cnf

openssl genrsa -out $DOMAIN.key

openssl req -new -out ${DOMAIN}.csr -key ${DOMAIN}.key -config openssl.cnf -subj '/C=IN/ST=Tamil Nadu/L=Srivilliputhur/O=Tiny WP/CN=Self-signed certificate'

openssl x509 -req -in ${DOMAIN}.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out ${DOMAIN}.crt -days 365 -sha256 -extensions v3_req -extfile openssl.cnf

$(which sed) -i "s/$DOMAIN/example.com/g" openssl.cnf
