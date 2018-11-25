#!/usr/bin/env bash
#
# Sample script for setting up external PKI
# See epki.txt for full documentation.
#
/etc/init.d/openvpnas stop
cd /usr/local/openvpn_as/scripts
rm -rf epki
mkdir -p epki/root
./certool --dir epki/root --cn "EPKI Root Test" --type ca
./certool --dir epki/root --type intermediate --serial 1 --cn "EPKI Intermediate" --name inter
cp epki/root/inter.crt epki/ca.crt
cp epki/root/inter.key epki/ca.key
cat epki/root/ca.crt epki/ca.crt >epki/cabundle.crt
./certool --dir epki --type server --serial 1 --cn server
./certool --dir epki --tls_auth
if [ -f "dh.pem" ]; then
   cp dh.pem epki/dh.pem
else
   openssl dhparam -out epki/dh.pem 1024
fi
./confdba -mk external_pki.ta_key --value_file epki/ta.key
./confdba -mk external_pki.ca_crt --value_file epki/cabundle.crt
./confdba -mk external_pki.server_crt --value_file epki/server.crt
./confdba -mk external_pki.server_key --value_file epki/server.key
./confdba -mk external_pki.dh_pem --value_file epki/dh.pem
./confdba -mk external_pki.remote_cert_usage -v ns
./confdba -mk external_pki.autologin_x509_spec -v "role,,AUTOLOGIN"
useradd -s /sbin/nologin etest &>/dev/null
echo Need PKCS12 password for Userlogin cert
./certool --dir epki --type client --serial 2 --cn etest --cabundle epki/cabundle.crt --pkcs12 --prompt
echo Need PKCS12 password for Autologin cert
./certool --dir epki --type client --serial 3 --cn etest --name etestauto --cabundle epki/cabundle.crt --pkcs12 --prompt role=AUTOLOGIN
./confdba -mucp etest --key prop_autologin --value true
./confdba -u --assign_type
echo "Next steps:"
echo "1. Comment out certs_db definition in as.conf"
echo "2. Set password for etest user"
echo "3. Restart AS"
echo "4. Install one of these files on client: " epki/*.p12
echo "5. Connect to AS using user etest"
