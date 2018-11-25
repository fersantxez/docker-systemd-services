# Show connecting user, serial number, CN, and
# SHA1 fingerprint of leaf cert.

import time
from pyovpn.plugin import *

def x509_track():
    # Declare interest in leaf cert CN and
    # SHA1 fingerprint.  Use '+sha1' to get sha1
    # fingerprints for all certs in chain.
    return ['CN', 'sha1']

def post_auth(authcred, attributes, authret, info):
    try:
        attr = attributes['auth_parms']
        print "***** USER=%s SN=%s CN=%s SHA1=%s" % (
            authret['user'],
            attr['tls_serial_0'],
            attr['X509_0_CN'],
            attr['X509_0_sha1'])
    except Exception, e:
        print "***** POST AUTH FAIL:", e
    return authret
