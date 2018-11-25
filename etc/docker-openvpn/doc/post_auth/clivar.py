#PYTHON
# above line indicates that script should be run via
# integrated python environment in Access Server client
# (this allows interoperability on both Mac and Windows).

# Client-side connect script that securely receives argdict
# from server side post_auth script (pasvar.py).

# Install on server for all users:
#   ./sacli --user __DEFAULT__ --key prop_cli.script.all.user.connect --value_file clivar.py UserPropPut

import sys, json
argdict = json.loads(sys.stdin.read())
print "ARGDICT: %r" % (argdict,)
