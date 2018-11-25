# This Example Access Server Post-Auth script demonstrates how
# to extract the Access Server group assignment based on the
# X509 "member" attribute of the connecting client certificate.

from pyovpn.plugin import *

def x509_track():
    # tell OpenVPN core that we are interested in the "member" X509 attribute
    return ['member']

def post_auth(authcred, attributes, authret, info):
    print "********** POST_AUTH", authcred, attributes, authret, info

    # get user's property list, or create it if absent
    proplist = authret.setdefault('proplist', {})

    # set the group name -- the var name is formatted as
    # X509_<certificate-depth>_<X509_attribute>
    proplist['conn_group'] = attributes['auth_parms']['X509_0_member']

    return authret
