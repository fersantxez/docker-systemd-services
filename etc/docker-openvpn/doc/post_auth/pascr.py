# Example Access Server Post-Auth script that demonstrates
# challenge/response authentication using OpenVPN
# Dynamic Challenge/Response Protocol.

# This script implements a turing test by asking the user
# to solve a simple multiplication problem.

# see pascrs.py for another example that uses both the
# Static and Dynamic Challenge/Response Protocol.

# post_auth_cr will be called after the primary authentication method
# (LDAP, RADIUS, PAM, etc.) successfully completes.  The crstate object
# is a dictionary that can be used to save state info from the time
# that the challenge is generated, to when the response is received.

import random
from pyovpn.plugin import *

# If False or undefined, AS will call us asynchronously in a worker thread.
# If True, AS will call us synchronously (server will block during call),
# however we can assume asynchronous behavior by returning a Twisted
# Deferred object.
SYNCHRONOUS=True

def post_auth_cr(authcred, attributes, authret, info, crstate):
    # see post_auth.txt for a detailed description of these members
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

    # crstate contains the challenge/response state
    if 'turing_result' not in crstate:
        # initial auth request, issue challenge
        a = random.randrange(10)
        b = random.randrange(10)
        crstate['turing_result'] = a * b # save the turing result in our state dictionary
        crstate.challenge_post_auth(authret, "Turing test: what is %d x %d?" % (a, b))
    else:
        # received response to challenge
        crstate.expire() # make sure to expire crstate at the end of the challenge/response transaction
        try:
            if int(crstate.response()) == crstate['turing_result']: # verify the turing result
                authret['status'] = SUCCEED
                authret['reason'] = "Turing test succeeded"
            else:
                authret['status'] = FAIL
                authret['reason'] = "Turing test failed"
        except ValueError:
            authret['status'] = FAIL
            authret['reason'] = "Turing test failed -- response not an integer"

        # allow end user to see actual error text
        authret['client_reason'] = authret['reason']
    return authret
