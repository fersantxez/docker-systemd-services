# Example Access Server Post-Auth script that demonstrates
# challenge/response authentication.

# This example demonstrates both the Static and Dynamic
# Challenge/Response Protocols.  If a response to the static
# challenge is provided, we will use the static protocol;
# otherwise, we fall back to the dynamic protocol.

# This script will challenge the user to enter the current
# year in YYYY format.  The response entered by the user
# (if any) will be made available as authcred['static_response'].
# If a blank or null response is provided, we fall back
# to the Dynamic Protocol.

# post_auth_cr will be called after the primary authentication method
# (LDAP, RADIUS, PAM, etc.) successfully completes.  The crstate object
# is a dictionary that can be used to save state info from the time
# that the challenge is generated, to when the response is received.

import time
from pyovpn.plugin import *

# If False or undefined, AS will call us asynchronously in a worker thread.
# If True, AS will call us synchronously (server will block during call),
# however we can assume asynchronous behavior by returning a Twisted
# Deferred object.
SYNCHRONOUS=True

# Specifies the challenge text.  The AS will place this string
# in client profiles so that clients can prompt the user for
# a response.
STATIC_CHALLENGE = "What is the current year (YYYY)?"

# Should user's response be echoed?
STATIC_CHALLENGE_ECHO = True

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

    # was response provided? -- we support responses issued for both static and dynamic challenges
    year = authcred.get('static_response') # response to Static Challenge provided along with username/password
    if not year:
        year = crstate.response()          # response to dynamic challenge

    if year:
        # received response
        crstate.expire()
        try:
            if int(year) == time.gmtime().tm_year: # verify the result
                authret['status'] = SUCCEED
                authret['reason'] = "year is correct"
            else:
                authret['status'] = FAIL
                authret['reason'] = "year is incorrect"
        except ValueError:
            authret['status'] = FAIL
            authret['reason'] = "response fail -- year must be an integer"

        # allow end user to see actual error text
        authret['client_reason'] = authret['reason']

    elif crstate.get('challenge'):
        # received an empty or null response after challenge issued
        crstate.expire() # make sure to expire crstate at the end of the challenge/response transaction
        authret['status'] = FAIL
        authret['reason'] = "year was not provided"

        # allow end user to see actual error text
        authret['client_reason'] = authret['reason']

    else:
        # initial auth request without static response; issue challenge
        crstate['challenge'] = True # save state indicating challenge has been issued
        crstate.challenge_post_auth(authret, STATIC_CHALLENGE, echo=STATIC_CHALLENGE_ECHO)
    return authret
