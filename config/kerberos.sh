#!/usr/bin/env bash

################################################################################
######################$$$$$Required for Settingup Kerberos$$$$##################
################################################################################

sudo apt-get update -y
export DEBAIN_FRONTEND=noninteractive; sudo apt-get install -y krb5-kdc krb5-admin-server

###########################$$$ KRB5 Configuration $$$###########################
tee /etc/krb5.conf <<EOF
[libdefaults]
    default_realm = KAFKASECURITY.POC
# The following krb5.conf variables are only for MIT Kerberos.
    kdc_timesync = 1
    ccache_type = 4
    forwardable = true
    proxiable = true
# The following libdefaults parameters are only for Heimdal Kerberos.
    fcc-mit-ticketflags = true
[realms]
    KAFKASECURITY.POC = {
      kdc = kerberos.c.terraformkafka.internal
      admin_server = kerberos.c.terraformkafka.internal
    }
[domain_realm]
    .kafkasecurity.poc = KAFKASECURITY.POC
    kafkasecurity.poc = KAFKASECURITY.POC
EOF

#############################  KDC configuration  ##############################
tee /etc/krb5kdc/kdc.conf <<EOF
[kdcdefaults]
    kdc_ports = 750,88

[realms]
    KAFKASECURITY.POC = {
        database_name = /var/lib/krb5kdc/principal
        admin_keytab = FILE:/etc/krb5kdc/kadm5.keytab
        acl_file = /etc/krb5kdc/kadm5.acl
        key_stash_file = /etc/krb5kdc/stash
        kdc_ports = 750,88
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        master_key_type = des3-hmac-sha1
        supported_enctypes = aes256-cts:normal aes128-cts:normal
        default_principal_flags = +preauth
    }
EOF

######################  Kerberos new realm and database  #######################
(echo "unsecurepass"; echo "unsecurepass") | krb5_newrealm

######################  Kerberos Access Control List  ##########################
tee /etc/krb5kdc/kadm5.acl <<EOF
# This file Is the access control list for krb5 administration.
# When this file is edited run /etc/init.d/krb5-admin-server restart to activate
# One common way to set up Kerberos administration is to allow any principal
# ending in /admin  is given full administrative rights.
# To enable this, uncomment the following line:
 */admin *
EOF

#############################  Restart kerberos  ###############################
sleep 10s
systemctl restart krb5-admin-server krb5-kdc

#############################  Adding pricipals  ###############################
kadmin.local -q "addprinc -pw unsecurekrb5pass venkayyanaidu/admin"
kadmin.local -q "addprinc -randkey kafka/kafka1.c.terraformkafka.internal"
kadmin.local -q "addprinc -randkey kafka/kafka2.c.terraformkafka.internal"
kadmin.local -q "addprinc -randkey kafka/kafka3.c.terraformkafka.internal"
kadmin.local -q "addprinc -randkey zookeeper/zk1.c.terraformkafka.internal"
kadmin.local -q "addprinc -randkey zookeeper/zk2.c.terraformkafka.internal"
kadmin.local -q "addprinc -randkey zookeeper/zk3.c.terraformkafka.internal"
