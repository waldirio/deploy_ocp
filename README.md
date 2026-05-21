# deploy_ocp
Deploy SNO Automatically

## Purpose
Imagine that you would like to deploy a new SNO `Single Node Openshift` easily, picking from a list of available versions, with no need to access the `console.redhat.com`, creating an `ISO`, downloading it, attaching to your local machine .... You got the point.

With this script, you just set the cluster name, pick the version of openshift you would like to deploy, and that's all. At the end of the day, your `SNO` should be Up and Running with no problems.

## Requirements
This is a bash script, and in order to this script works properly, there are some requirements.

- Ability to update your DNS via nsupdate
- KVM Server `Maybe, it will be your local machine`
- Linux Box `Maybe, it will be your local machine`

And that's it.

## How this Works?
In my scenario, I'm using MAC, and virtualization is not a thing on this specific machine. With that said, I do have the scenario below

- MAC, where I'm executing the code
- Linux Box, this machine will need also podman, just to download the binaries, prepare the ISO to move on with the installation
- KVM Box, here, it's just the server that the VM will be created, attached the ISO, and the installation will move on
- DNS Server. In this case, there is one domain that I can update passing the `key file` to `nsupdate` command

Now, let's check the flow

Executing the script
```
% ./deploy_ocp.sh
You are able to access s4.king.lab and srv05.king.lab with no issues.
DNS Entry 'api.cluster01.king.lab' is already in use
#######
1. Set the domain, default/current is 'king.lab'
2. Set the cluster name, default/current is 'cluster01'
3. Set the local subnet CIDR, default/current is '192.168.86.0/24'
4. List ALL the OpenShift Version available
5. Set the OpenShift Version, default is 'latest-4.21'

8. Proceed with the Deployment!

9. Exit
Type the number:
```

Just type 2, and set the new `cluster name`, for instance, let's set `ocp10`
```
Type the number: 2
#######
Setting the Cluster
CUrrent value: ocp4
Please, type the cluster name: ocp10
New value: ocp10
DNS Entry 'api.ocp10.king.lab' is available
#######
1. Set the domain, default/current is 'king.lab'
2. Set the cluster name, default/current is 'ocp10'
3. Set the local subnet CIDR, default/current is '192.168.86.0/24'
4. List ALL the OpenShift Version available
5. Set the OpenShift Version, default is 'latest-4.21'

8. Proceed with the Deployment!

9. Exit
Type the number:
```

The query is telling us that this cluster is available in the DNS `api.ocp10.king.lab`

Next, let's pick a different version of `OCP`, we can see a complete list by pressing 4
```
Type the number: 4
#######
List all OCP Versions
..
4.1.0
4.1.11
4.1.13
4.1.14
4.1.15
4.1.16
4.1.17
4.1.18
4.1.2
...
stable-4.5
stable-4.6
stable-4.7
stable-4.8
stable-4.9
stable
unreleased
DNS Entry 'api.ocp10.king.lab' is available
#######
1. Set the domain, default/current is 'king.lab'
2. Set the cluster name, default/current is 'ocp10'
3. Set the local subnet CIDR, default/current is '192.168.86.0/24'
4. List ALL the OpenShift Version available
5. Set the OpenShift Version, default is 'latest-4.21'

8. Proceed with the Deployment!

9. Exit
Type the number:
```

I'm saw the version `4.20.6`, and for my goal, this is the one.

Next, I'll set it, by typing 5 and adding/typing/pasting `4.20.6`
```
Type the number: 5
#######
Setting the OCP Version
CUrrent value: latest-4.21
Please, type the OCP Version: 4.20.6
New value: 4.20.6
DNS Entry 'api.ocp10.king.lab' is available
#######
1. Set the domain, default/current is 'king.lab'
2. Set the cluster name, default/current is 'ocp10'
3. Set the local subnet CIDR, default/current is '192.168.86.0/24'
4. List ALL the OpenShift Version available
5. Set the OpenShift Version, default is '4.20.6'

8. Proceed with the Deployment!

9. Exit
Type the number:
```

Ok, now we are ready to go, by pressing 8

```
Type the number: 8
#######
new_install-config.yaml                              100% 3288     2.7MB/s   00:00
new_download_binaries.sh                             100% 1533     1.3MB/s   00:00
mkdir: created directory '/tmp/ocp10.king.lab-4.20.6'
Downloading the OC
Value of OCP_VERSION: 4.20.6
Downloading the openshift-install-linux
Downloading the CoreOS image
level=info msg=Consuming Install Config from target directory
level=warning msg=Making control-plane schedulable by setting MastersSchedulable to true for Scheduler cluster settings
level=info msg=Successfully populated MCS CA cert information: root-ca 2036-05-18T16:32:56Z 2026-05-21T16:32:56Z
level=info msg=Successfully populated MCS TLS cert information: root-ca 2036-05-18T16:32:56Z 2026-05-21T16:32:56Z
level=info msg=Single-Node-Ignition-Config created in: ocp and ocp/auth
Trying to pull quay.io/coreos/coreos-installer:release...
Getting image source signatures
Copying blob sha256:e1c9ca6d329e5559b751c2dcbce815cb5fbbdd6914c4bd64dd8859005ca1b64e
Copying blob sha256:de6be2cc5821a6503324eb123e4ca03c1d0c5979c8b63f333372b9ed4cbcc222
Copying blob sha256:cd2c034211b13f1b571b3693c74de4c317eedaa7dbf00b930c676cd6a652a5c0
Copying config sha256:0156a83c4ee83f8d0cee283e05cad6ef7d6d6c3ca3c7347c78d22043c7d99fc5
Writing manifest to image destination
rhcos-live.iso                                       100% 1285MB  96.2MB/s   00:13
ocp10.king.lab-4.20.6.iso                            100% 1285MB 102.1MB/s   00:12
Creating the Monitor Script
new_monitor.sh                                       100%  566   752.0KB/s   00:00
Creating the New User Script
Don't forget to access the folder with the installation files
and execute the 'create_admin_user.sh' to add your 'admin' user
and 'Secret123' as password.
new_monitor.sh                                       100%  703   693.5KB/s   00:00
Creating the VM
wally.sh                                             100%  373   364.3KB/s   00:00
let's wait for 120 seconds to prepare a new VM and retrieve
the ip address, then setup the DNS entries
----
Adding 'ocpsrv.ocp10.king.lab 86400 A 192.168.86.163' to the DNS
Adding 'api.ocp10.king.lab 86400 A 192.168.86.163' to the DNS
Adding 'api-int.ocp10.king.lab 86400 A 192.168.86.163' to the DNS
Adding '*.apps.ocp10.king.lab 86400 A 192.168.86.163' to the DNS
Adding '163.86.168.192.in-addr.arpa 86400 IN PTR ocpsrv.ocp10.king.lab.' to the DNS
----
Server:		storage.king.lab
Address:	192.168.86.250#53

Name:	api.ocp10.king.lab
Address: 192.168.86.163

DNS Entry 'api.ocp10.king.lab' is already in use
#######
1. Set the domain, default/current is 'king.lab'
2. Set the cluster name, default/current is 'ocp10'
3. Set the local subnet CIDR, default/current is '192.168.86.0/24'
4. List ALL the OpenShift Version available
5. Set the OpenShift Version, default is '4.20.6'

8. Proceed with the Deployment!

9. Exit
Type the number:
```

Ok, at this moment, the machine got created under `KVM`, the `DNS` was updated properly, all the necessary entries were added to it, and your `SNO` installation will proceed.

You can also access the `Linux Box` that created the `ISO` to monitor the installation. You will see something as below
```
ls -ltr /tmp
-rwxr-xr-x. 1 root root  566 May 21 16:33 monitor_ocp10.king.lab-4.20.6.sh
drwxr-xr-x. 3 root root  189 May 21 16:33 ocp10.king.lab-4.20.6
```

and
```
# tree /tmp/ocp10.king.lab-4.20.6
/tmp/ocp10.king.lab-4.20.6
├── create_admin_user.sh
├── kubectl
├── oc
├── ocp
│   ├── auth
│   │   ├── kubeadmin-password
│   │   └── kubeconfig
│   ├── bootstrap-in-place-for-live-iso.ign
│   ├── metadata.json
│   └── worker.ign
├── oc.tar.gz
├── openshift-install
├── openshift-install-linux.tar.gz
├── README.md
└── rhcos-live.iso

3 directories, 13 files
```

Basically, the `/tmp/monitor_ocp10.king.lab-4.20.6.sh` is the script that you can execute, and it will be presenting the current state of your cluster. Let me show you an example
```
<< updated soon >>
```

and the `/tmp/ocp10.king.lab-4.20.6/create_admin_user.sh` is the script that will create a new administrative user in your `SNO`. Please, execute this script once your installation is finished.
```
<< updated soon >>
```