# This post_auth script is intended to show the info
# available to a post_auth script, but not actually
# affect the authentication process.

# Aside from that, it also requests that the OpenVPN
# daemon provide the X509 attribute 'basicConstraints'
# for connecting clients.

import time
from pyovpn.plugin import *

def x509_track():
    # Declare interest in basicConstraints X509 attribute for leaf certificate
    # and CN (common name) for all certificates in verification chain
    # ('+' prefix indicates to query attribute for all certs in chain).
    # Attribute values will be passed to post_auth() via attributes dictionary.
    # Attribute names are listed in obj_mac.h in OpenSSL.
    return ['basicConstraints', '+CN']

def post_auth(authcred, attributes, authret, info):
    print "**********************************************"
    print "AUTHCRED", authcred
    print "ATTRIBUTES", attributes
    print "AUTHRET", authret
    print "INFO", info
    print "**********************************************"
    return authret
