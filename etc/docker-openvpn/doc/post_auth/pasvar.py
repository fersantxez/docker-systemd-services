# This post_auth script demonstrates:
#
# (a) using RETAIN_PASSWORD to allow post_auth script to access the
#     auth password
#
# (b) using AUTH_NULL to disable primary auth -- this means that
#     post_auth script must assume full responsibility for
#     authentication
#
# (c) securely passing an arbitrary python dictionary to client-side
#     connect script (clivar.py is the client-side receiver script)

import json
from pyovpn.plugin import *

# auth password will be passed to post_auth() via authcred
RETAIN_PASSWORD=True

# primary auth method will always ALLOW
AUTH_NULL=True

def post_auth(authcred, attributes, authret, info):
    print "**********************************************"
    print "AUTHCRED", authcred
    print "ATTRIBUTES", attributes
    print "AUTHRET", authret
    print "INFO", info
    print "**********************************************"

    # Don't do challenge/response on sessions or autologin clients.
    # autologin client: a client that has been issued a special
    #   certificate allowing authentication with only a certificate
    #   (used for unattended clients such as servers).
    # session: a client that has already authenticated and received
    #   a session token.  The client is attempting to authenticate
    #   again using the session token.
    if info.get('auth_method') in ('session', 'autologin'):
        return authret

    # You MUST verify authcred here because AUTH_NULL is defined above,
    # so the normal primary auth method is disabled.
    if not (authcred['username'] == 'test' and authcred['password'] == 'changeme'):
        error = "pasvar: bad auth"
        authret['status'] = FAIL
        authret['reason'] = error        # this error string is written to the server log file
        authret['client_reason'] = error # this error string is reported to the client user
        return authret

    # argdict will be securely passed via json to client-side connect script
    argdict = {
        'auth_cookie' : 'a274c1c9f1c6e9bd16705c5dd7c01ac0',
        }

    # get user's property list, or create it if absent
    proplist = authret.setdefault('proplist', {})

    # pass argdict to client-side script via stdin
    authret['proplist']['prop_cli.script_stdin'] = json.dumps(argdict)

    return authret
