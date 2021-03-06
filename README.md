# Web Interface to create OpenShift user accounts in htpasswd

One of the areas that OpenShift is lacking is in easy setup of new users when using htpasswd.  When you use htpasswd for your 
OpenShift user authentication, the user initially needs to set their password using the `htpasswd` command line tool on the
OpenShift master servers.

That kinda sucks.

Wouldn't it be great if you could provide your developers and other people with a simple web interface they can visit that
would allow them to set up a new account or change their password?  That's what this Git repo is for...  I originally wrote
it for my work at the CBC (Canadian Broadcasting Corporation) until we can transition over to our AD or LDAP.

![OpenShift user account creation through a web interface](web-interface.png)

# What you'll need

In order to make changes to the `htpasswd` file that your OCP masters use, the file will need to be in a space that the
containers on your application node(s) can also use.  For example and NFS mount.

- Create a small NFS space, say 100MB or so
- From your OpenShift master nodes, mount the disk and copy your `htpasswd` file into it
- Update your `master-config.yaml` file to include the new location of your `htpasswd` file
- In OpenShift, create a `persistentvolume` that will consume the same NFS space as your master nodes
- Once you're all done, run the commands below to help with your setup


![Architecture of the 'OpenShift User Accounts' application](ocp-users.png)


# Preparation for getting set up

First things first, clone this repository to a location that you have the `oc` command running.  Then do these commands.

```
OCP_MASTER=<your.openshift.domain.com:8443>

# NOTE: I'm using OSX so I did...
#    sed -i '' "s/old/new/g"
# ...however most Linux machines don't require the double-single-quotes '' in the command
sed -i '' "s/your-ocp-master-url/${OCP_MASTER}/g" openshift/configmap.yaml

# Update the values for OCP_GROUPS, PRETTY_NAME_GROUPS, and OPERATIONS to whatever you need
# - OCP_GROUPS is the names of the already-existing groups you have in OpenShift
# - PRETTY_NAME_GROUPS is what you'd like the web interface to display
# - OPERATIONS is the name of the team that owns the OpenShift environment
vi openshift/configmap.yaml

# ex: OCP_PV_NAME="openshift-users"
OCP_PV_NAME=<the name of the persistentvolume you created earlier>
sed -i '' "s/your-pv-name/${OCP_PV_NAME}/g" openshift/pvc.yaml

# ex: OCP_APP_HOSTNAME="accounts.openshift.mydomain.com"
OCP_APP_HOSTNAME=<enter the domain you want for the web interface>
sed -i '' "s/your-host-name/${OCP_APP_HOSTNAME}/g" openshift/pvc.yaml

# Either create a new Project or move into an existing one
oc new-project openshift-user-accounts
# Add the service account
oc create sa ocp-accounts
# Give it cluster-admin - Note: you may wish to consider a lower privilege, but in my case it's fine
oc adm policy add-cluster-role-to-user cluster-admin --serviceaccount=ocp-accounts
# Create the object definitions
oc create -f openshift
```

# FAQ

_Why does it perform a build instead of using a pre-built Docker image?_

You want to know what's going into the images you're using, right?  Right? :)

_Where in the container is the source code located?_

The index.html, which is in actuality a bash file, can be found at `/var/www/cgi-bin/`.  In fact Apache web server is configured to run inside the
container using only the `cgi-bin` as the website's root directory.  This way, when a user visits the site they immediately get the output produced
by the bash script, which is the account creation page.

_But can't anyone with access add their own account?_

Yes they can.  Which is why you should secure your `route`'s url.  It's also assumed that you trust the other people on your network, such as
developers and PMs, to create their own accounts appropriately.

# Bugs and other issues

It should be noted that I haven't spent much, or any time really, on ensuring that the user input is cleaned up in case of hack attempts.
So I offer no guarantees to the quality or functionality of this code.  USE AT YOUR OWN RISK.

If you find any bugs, please feel free to fork and put in a PR, or submit an Issue for it.

