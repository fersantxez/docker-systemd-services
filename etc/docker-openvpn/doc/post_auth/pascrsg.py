# Example Access Server Post-Auth script that demonstrates
# challenge/response authentication.

# This example is very similar to pascrs.py, with several changes:
# 1. The question asked is "How many minutes after the hour?"
#    (i.e. server time) to simulate a more OTP-like auth method
# 2. This script assigns connecting clients (that successfully
#    authenticate) to the group "mygroup".
# 3. This script demonstrates the use of a custom, per-client
#    session state object.
# 4. This script demonstrates autologin support.
# 5. This script demonstrates querying certificate for
#    X509 attributes (including x509v3 attributes).

# This example demonstrates both the Static and Dynamic
# Challenge/Response Protocols.  If a response to the static
# challenge is provided, we will use the static protocol;
# otherwise, we fall back to the dynamic protocol.

# This script will challenge the user to enter the current
# number of minutes after the hour.  The response entered by the user
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
STATIC_CHALLENGE = "How many minutes after the hour?"

# Should user's response be echoed?
STATIC_CHALLENGE_ECHO = True

# When True, indicates that script will select the user's group
# by setting proplist['conn_group'] and that user properties
# will be fetched from the DB after the post_auth_cr method returns
# rather than before.
GROUP_SELECT = True

# This object demonstrates how the post-auth script can maintain
# it's own mutable state object inside the session object for a
# given client session.  This object simply keeps a count of the
# number of times post_auth_cr was called on a given client
# session object.
class State(object):
    def __init__(self):
        self.count = 0
    def incr(self):
        self.count += 1
    def __str__(self): # invoked when the state object is printed
        return "<State %d>" % (self.count,)

def x509_track():
    # Declare interest in these X509 attributes.
    # ('+' prefix indicates to query attribute for all certs in chain,
    # rather than only leaf cert).
    # Attribute values will be passed to post_auth() via attributes dictionary.
    # Attribute names are listed in obj_mac.h in OpenSSL.
    return ['+CN', '+basicConstraints', '+extendedKeyUsage']

def post_auth_cr(authcred, attributes, authret, info, crstate):
    # see post_auth.txt for a detailed description of these members
    print "**********************************************"
    print "AUTHCRED", authcred
    print "ATTRIBUTES", attributes
    print "AUTHRET", authret
    print "INFO", info
    if hasattr(authret, 'state'):
        print "STATE", authret.state
    print "**********************************************"

    # Don't do challenge/response on sessions or autologin clients.
    # autologin client: a client that has been issued a special
    #   certificate allowing authentication with only a certificate
    #   (used for unattended clients such as servers).
    # session: a client that has already authenticated and received
    #   a session token.  The client is attempting to authenticate
    #   again using the session token.
    auth_method = info.get('auth_method')

    # pre-existing session login
    if auth_method == 'session':
        # demonstrate state object by incrementing counter
        if hasattr(authret, 'state'): # make sure state object exists
            authret.state.incr()
        return authret

    # autologin
    elif auth_method == 'autologin':
        authret['proplist'] = {
            'conn_group' : 'mygroup',
            }
        # autologin is stateless (no session object), so
        # we can't create a State object in authret as
        # we do for userlogin
        return authret

    # userlogin below this point

    # was response provided? -- we support responses issued for both static and dynamic challenges
    minute = authcred.get('static_response') # response to Static Challenge provided along with username/password
    if not minute:
        minute = crstate.response()          # response to dynamic challenge

    if minute:
        # received response
        crstate.expire()
        try:
            if int(minute) == time.gmtime().tm_min: # verify the result
                authret['status'] = SUCCEED
                authret['reason'] = "minute is correct"

                # Set group name.
                # If global var GROUP_SELECT == True, user properties will be
                # loaded from the DB based on the group selected here ("mygroup)
                # and any user properties defined here will override those in
                # "mygroup".
                authret['proplist'] = {
                    'conn_group' : 'mygroup',
                    }

                # save a State object in authret -- will persist
                # for the life of the session
                authret.state = State()
            else:
                authret['status'] = FAIL
                authret['reason'] = "minute is incorrect"
        except ValueError:
            authret['status'] = FAIL
            authret['reason'] = "response fail -- minute must be an integer"

        # allow end user to see actual error text
        authret['client_reason'] = authret['reason']

    elif crstate.get('challenge'):
        # received an empty or null response after challenge issued
        crstate.expire() # make sure to expire crstate at the end of the challenge/response transaction
        authret['status'] = FAIL
        authret['reason'] = "minute was not provided"

        # allow end user to see actual error text
        authret['client_reason'] = authret['reason']

    else:
        # initial auth request without static response; issue challenge
        crstate['challenge'] = True # save state indicating challenge has been issued
        crstate.challenge_post_auth(authret, STATIC_CHALLENGE, echo=STATIC_CHALLENGE_ECHO)

    return authret
