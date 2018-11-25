# Example Access Server Post-Auth script that demonstrates
# forcing an auth failure based on a random event.

import time
from pyovpn.plugin import *

def post_auth(authcred, attributes, authret, info):
    if int(time.time()) & 1:
        authret['status'] = FAIL
        authret['reason'] = "I can't let you do that"
        authret['client_reason'] = authret['reason']
    return authret
