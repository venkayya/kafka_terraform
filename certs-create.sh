#!/bin/bash

#set -o nounset \
#    -o errexit \
#    -o verbose \
#    -o xtrace

# Generate CA key
				openssl req \
        				-new \
        				-x509 \
        				-keyout snakeoil-ca-1.key \
								-out snakeoil-ca-1.crt \
								-days 365 \
								-subj '/CN=ca1.test.serversecrect.io/OU=TEST/O=serversecrect/L=PaloAlto/S=Ca/C=US' \
								-passin pass:serversecrect \
								-passout pass:serversecrect

# Create host keystore
				keytool -genkey \
								-noprompt \
								-alias $(hostname) \
								-dname "CN=$(hostname),OU=TEST,O=serversecrect,L=PaloAlto,S=Ca,C=US" \
								-ext "SAN=dns:$(hostname),dns:localhost" \
								-keystore kafka.$(hostname).keystore.jks \
								-keyalg RSA \
								-storepass serversecrect \
								-keypass serversecrect

# Create the certificate signing request (CSR)
				keytool -keystore kafka.$(hostname).keystore.jks \
								-alias $(hostname) \
								-certreq -file $(hostname).csr \
								-storepass serversecrect \
								-keypass serversecrect \
								-ext "SAN=dns:$(hostname),dns:localhost"

# Sign the host certificate with the certificate authority (CA)
				openssl x509 \
								-req \
								-CA snakeoil-ca-1.crt \
								-CAkey snakeoil-ca-1.key \
								-in $(hostname).csr \
								-out $(hostname)-ca1-signed.crt \
								-days 9999 \
								-CAcreateserial \
								-passin pass:serversecrect \
								-extensions v3_req \
								-extfile <(cat <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
CN = $(hostname)
[v3_req]
subjectAltName = @alt_names
[alt_names]
DNS.1 = $(hostname)
DNS.2 = localhost
EOF
)

# Sign and import the CA cert into the keystore
				keytool -noprompt \
								-keystore kafka.$(hostname).keystore.jks \
								-alias CARoot \
								-import -file snakeoil-ca-1.crt \
								-storepass serversecrect \
								-keypass serversecrect

# Sign and import the host certificate into the keystore
				keytool -noprompt \
	        			-keystore kafka.$(hostname).keystore.jks \
								-alias $(hostname) \
								-import -file $(hostname)-ca1-signed.crt \
								-storepass serversecrect \
								-keypass serversecrect \
								-ext "SAN=dns:$(hostname),dns:localhost"

# Create truststore and import the CA cert
				keytool -noprompt \
	        			-keystore kafka.$(hostname).truststore.jks \
								-alias CARoot \
								-import -file snakeoil-ca-1.crt \
								-storepass serversecrect \
								-keypass serversecrect

# Save creds
#  			echo "serversecrect" > ${i}_sslkey_creds
#  			echo "serversecrect" > ${i}_keystore_creds
#  			echo "serversecrect" > ${i}_truststore_creds

# Create pem files and keys used for Schema Registry HTTPS testing
				keytool -export \
	        			-alias $(hostname) \
								-file $(hostname).der \
								-keystore kafka.$(hostname).keystore.jks \
								-storepass serversecrect

				openssl x509 \
	        			-inform der \
								-in $(hostname).der \
								-out $(hostname).certificate.pem

				keytool -importkeystore \
	        			-srckeystore kafka.$(hostname).keystore.jks \
								-destkeystore $(hostname).keystore.p12 \
								-deststoretype PKCS12 \
								-deststorepass serversecrect \
								-srcstorepass serversecrect \
								-noprompt

				openssl pkcs12 \
	        			-in $(hostname).keystore.p12 \
	        			-nodes \
	        			-nocerts \
	        			-out $(hostname).key \
	        			-passin pass:serversecrect
