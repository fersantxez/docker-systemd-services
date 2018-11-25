# Example Access Server Post-Auth script demonstrates three features:
#
# 1. How to set a connecting user's Access Server group based on LDAP
#    group settings for the user.
# 2. How to verify that a given Access Server user only logs in using
#    a known client machine.
# 3. How to verify that client machine contains up-to-date applications
#    (such as virus checker) before allowing it to connect to the server.

# Note that this script requires that the client provide us with information
# such as its MAC address and information about installed applications.
# The Access Server Client will only provide this information to trusted
# servers, so make sure that the client is configured to trust the profile
# which is used to connect to this server.

import re
import ldap

from pyovpn.plugin import *

# regex to parse the first component of an LDAP group DN
re_group = re.compile(r"^CN=([^,]+)")

# regex to parse the major component of a dotted version number
re_major_ver = re.compile(r"^(\d+)\.")

# Optionally set this string to a known public IP address (such as the
# public IP address of machines connecting from a trusted location, such
# as the corporate LAN).  If set, all users must first login from this
# IP address, where the machine's hardware (MAC) address will be recorded.
first_login_ip_addr=""

# If False or undefined, AS will call us asynchronously in a worker thread.
# If True, AS will call us synchronously (server will block during call),
# however we can assume asynchronous behavior by returning a Twisted
# Deferred object.
SYNCHRONOUS=False

# When True, indicates that script will select the user's group
# by setting proplist['conn_group'] and that user properties
# will be fetched from the DB after the post_auth method returns
# rather than before.
#GROUP_SELECT = True

def ldap_groups_parse(res):
    ret = set()
    for g in res[0][1]['memberOf']:
        m = re.match(re_group, g)
        if m:
            ret.add(m.groups()[0])
    return ret

# this function is called by the Access Server after normal authentication
def post_auth(authcred, attributes, authret, info):
    print "********** POST_AUTH", authcred, attributes, authret, info

    # default group assignment
    group = "default"

    # get user's property list, or create it if absent
    proplist = authret.setdefault('proplist', {})

    # user properties to save
    proplist_save = {}

    # set this to error string, if auth fails
    error = ""

    if info.get('auth_method') == 'ldap': # this code only operates when the Access Server auth method is set to LDAP
        # get the user's distinguished name
        user_dn = info['user_dn']

        # use our given LDAP context to perform queries
        with info['ldap_context'] as l:
            # get the LDAP group settings for this user
            ldap_groups = ldap_groups_parse(l.search_ext_s(user_dn, ldap.SCOPE_SUBTREE, attrlist=["memberOf"]))
            print "********** LDAP_GROUPS", ldap_groups

            # determine the access server group based on LDAP group settings
            if 'Administrators' in ldap_groups:
                group = "admin"
            elif 'Sales' in ldap_groups:
                group = "sales"
            elif 'Finance' in ldap_groups:
                group = "finance"
            elif 'Engineering' in ldap_groups:
                group = "engineering"

    # When a VPN client connects for the first time, save the MAC addr,
    # then require the same same MAC addr on subsequent connections.
    if attributes.get('vpn_auth'): # only do this for VPN authentication
        hw_addr = authcred.get('client_hw_addr') # current client's MAC addr
        if hw_addr:
            hw_addr_save = proplist.get('pvt_hw_addr') # saved MAC addr property
            if hw_addr_save:
                if hw_addr_save != hw_addr:
                    error = "not authorized to login from this client machine"
            else:
                # First login by this user, save MAC addr.
                if not first_login_ip_addr or first_login_ip_addr == authcred.get('client_ip_addr'):
                    proplist_save['pvt_hw_addr'] = hw_addr
                else:
                    error = "first login for this user must come from %s" % first_login_ip_addr
        else:
            error = "unable to identity client machine"

    # Verify that client apps are up to date (for purposes of example,
    # we verify that Firefox version 3 or higher is installed).
    # To do this, we query the Firefox version number from the
    # client.  This can be done by creating a file appver.txt:
    #   FIREFOX=^mozilla firefox
    # then load it into the AS Userprop DB:
    #   ./sacli [auth-options] -k vpn.client.app_verify --value_file=appver.txt ConfigPut
    #   ./sacli [auth-options] start
    # Also: make sure that the profile the client uses to connect to us is 
    # trusted, otherwise the client will not share application information with us.
    if attributes.get('vpn_auth'): # only do this for VPN authentication
        try:
            ver = attributes['client_info']['UV_APPVER_FIREFOX']
            if int(re.match(re_major_ver, ver).groups()[0]) < 3:
                error = "Firefox must be at least version 3 to connect"
        except:
            error = "cannot determine Firefox version"

    # process error, if one occurred
    if error:
        authret['status'] = FAIL
        authret['reason'] = error # this error string is written to the server log file
        authret['client_reason'] = error # this error string is reported to the client user

    # Set group name.
    # If global var GROUP_SELECT == True, user properties will be
    # loaded from the DB based on the group selected here ("mygroup)
    # and any user properties defined here will override those in
    # "mygroup".
    proplist['conn_group'] = group
    
    return authret, proplist_save
