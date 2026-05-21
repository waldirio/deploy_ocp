#!/bin/bash

# Loading all the Variables
if [ -f deploy_ocp.conf ]; then
  source deploy_ocp.conf
fi

check_requirements_ssh()
{
  timeout --foreground -k 1 5 ssh root@$LNX_SRV hostname >/dev/null
  if [ $? -ne 0 ]; then
    echo "There is a problem accessing $LNX_SRV via ssh."
    echo "Please, fix it. Exiting ...."
    exit
  fi

  timeout --foreground -k 1 5 ssh root@$KVM_SRV hostname >/dev/null
  if [ $? -ne 0 ]; then
    echo "There is a problem accessing $KVM_SRV via ssh."
    echo "Please, fix it. Exiting ...."
    exit
  fi

  echo "You are able to access $LNX_SRV and $KVM_SRV with no issues."
}

check_dns()
{
  nslookup $API_ADDR $DNS_SERVER >/dev/null
  if [ $? -eq 0 ]; then
    API_STATUS="already in use"
  else
    API_STATUS="available"
  fi
}

setup_dns()
{
  # Place where we are setting up the DNS entries

  resp=$(ssh root@$KVM_SRV "virsh domifaddr $CLUSTER_NAME --source agent | grep 192")
  count=$(echo $resp | wc -c)
  if [ $count -ne 1 ]; then
    IP=$(echo $resp | awk '{print $NF}' | cut -d/ -f1)
    LAST_IP_FIELD=$(echo $IP | cut -d. -f4)
    echo "----"
    echo "Adding 'ocpsrv.$CLUSTER_NAME.$DOMAIN 86400 A $IP' to the DNS"
    echo "Adding 'api.$CLUSTER_NAME.$DOMAIN 86400 A $IP' to the DNS"
    echo "Adding 'api-int.$CLUSTER_NAME.$DOMAIN 86400 A $IP' to the DNS"
    echo "Adding '*.apps.$CLUSTER_NAME.$DOMAIN 86400 A $IP' to the DNS"
    echo "Adding '$LAST_IP_FIELD.$DNS_REVERSE_ZONE 86400 IN PTR ocpsrv.${CLUSTER_NAME}.${DOMAIN}.' to the DNS"
    echo "----"
    nsupdate -k $DNS_KEY_FILE << EOF
;server storage.king.lab
server $DNS_SERVER
;zone king.lab
zone $DOMAIN
update add ocpsrv.$CLUSTER_NAME.$DOMAIN 86400 A $IP
update add api.$CLUSTER_NAME.$DOMAIN 86400 A $IP
update add api-int.$CLUSTER_NAME.$DOMAIN 86400 A $IP
update add *.apps.$CLUSTER_NAME.$DOMAIN 86400 A $IP
send
;zone 86.168.192.in-addr.arpa
zone $DNS_REVERSE_ZONE
update add $LAST_IP_FIELD.$DNS_REVERSE_ZONE 86400 IN PTR ocpsrv.${CLUSTER_NAME}.${DOMAIN}.
send
EOF

    # Presenting the result of nslookup query on screen
    nslookup $API_ADDR $DNS_SERVER
  else
    echo "Not adding a thing"
  fi
}

cluster_info()
{
  # Let's ask some questions here

  #echo "AUDIT: beggining of cluster_info: $CLUSTER_NAME"
  while :
  do
    # Checking the DNS entry
    check_dns

    echo "DNS Entry '$API_ADDR' is $API_STATUS"
    echo "#######"
    echo "1. Set the domain, default/current is '$DOMAIN'"
    echo "2. Set the cluster name, default/current is '$CLUSTER_NAME'"
    echo "3. Set the local subnet CIDR, default/current is '$NET_CIDR'"
    echo "4. List ALL the OpenShift Version available"
    echo "5. Set the OpenShift Version, default is '$OCP_VERSION'"
    echo ""
    echo "8. Proceed with the Deployment!"
    echo ""
    echo "9. Exit"
    echo -n "Type the number: "
    read opc
    echo "#######"
    case $opc in
      '1') echo "Setting the Domain"
           echo "CUrrent value: $DOMAIN"
           echo -n "Please, type the domain name: "
           read DOMAIN
           API_ADDR="api.${CLUSTER_NAME}.${DOMAIN}"
           echo "New value: $DOMAIN"
           ;;
      '2') echo "Setting the Cluster"
           echo "CUrrent value: $CLUSTER_NAME"
           echo -n "Please, type the cluster name: "
           read CLUSTER_NAME
           API_ADDR="api.${CLUSTER_NAME}.${DOMAIN}"
           echo "New value: $CLUSTER_NAME"
           ;;
      '3') echo "Setting the Network CIDR"
           echo "CUrrent value: $NET_CIDR"
           echo -n "Please, type the cluster name: "
           read NET_CIDR
           echo "New value: $NET_CIDR"
           ;;
      '4') echo "List all OCP Versions"
           curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/ | grep -o "a href.*" | cut -d\" -f2 | sed 's#/##' 
           ;;
      '5') echo "Setting the OCP Version"
           echo "CUrrent value: $OCP_VERSION"
           echo -n "Please, type the OCP Version: "
           read OCP_VERSION
           echo "New value: $OCP_VERSION"
           ;;
      '8') echo "Go Rockets!!"
           steps_podman_srv
           ;;
      '9') echo "exiting ..."
         exit
    esac
  done
}

steps_podman_srv()
{
  # Execute all the steps to create the image

  TEMPLATE_INST_FILE="template_install-config.yaml"
  TEMPLATE_DOWN_FILE="template_download_binaries.sh"
  INST_FILE_FINAL="install-config.yaml"
  DOWN_FILE_FINAL="download_binaries.sh"

  # Intaller Template Section
  TEMPLATE_INST_FILE_NEW="new_install-config.yaml"

  # copy from the templates 
  cp $TEMPLATE_INST_FILE $TEMPLATE_INST_FILE_NEW

  # do all the changes here
  sed -i "" "s/<domain>/$DOMAIN/" $TEMPLATE_INST_FILE_NEW
  sed -i "" "s/<name>/$CLUSTER_NAME/" $TEMPLATE_INST_FILE_NEW
  sed -i "" "s#10.0.0.0/16#$NET_CIDR#" $TEMPLATE_INST_FILE_NEW
  sed -i "" "s#<pull_secret>#$PULL_SECRET#" $TEMPLATE_INST_FILE_NEW
  sed -i "" "s#<ssh_key>#$SSH_KEY#" $TEMPLATE_INST_FILE_NEW
  sed -i "" "s#/dev/disk/by-id/<disk_id>#/dev/vda#" $TEMPLATE_INST_FILE_NEW

  # Download Template Section
  TEMPLATE_DOWN_FILE_NEW="new_download_binaries.sh"
  
  # copy from the templates 
  cp $TEMPLATE_DOWN_FILE $TEMPLATE_DOWN_FILE_NEW

  # do all the changes here
  sed -i "" "s/<domain>/$DOMAIN/" $TEMPLATE_DOWN_FILE_NEW
  sed -i "" "s/<name>/$CLUSTER_NAME/" $TEMPLATE_DOWN_FILE_NEW
  sed -i "" "s/<ocp_version>/$OCP_VERSION/" $TEMPLATE_DOWN_FILE_NEW
  sed -i "" "s/<arch>/$ARCH/" $TEMPLATE_DOWN_FILE_NEW

  # copy via ssh the final/modified files
  scp $TEMPLATE_INST_FILE_NEW root@$LNX_SRV:/tmp/$INST_FILE_FINAL
  scp $TEMPLATE_DOWN_FILE_NEW root@$LNX_SRV:/tmp/$DOWN_FILE_FINAL

  # Script Execution on the remote Podman Server 
  ssh root@$LNX_SRV "bash /tmp/$DOWN_FILE_FINAL"

  # Moving On Calling two other functions
  download_image
  upload_image
}

download_image()
{
  # Download the image locally

  IMAGE_NAME="${CLUSTER_NAME}.${DOMAIN}-${OCP_VERSION}.iso"
  LOCAL_PATH="/tmp/${CLUSTER_NAME}.${DOMAIN}-${OCP_VERSION}"
  scp root@$LNX_SRV:$LOCAL_PATH/rhcos-live.iso /tmp/${IMAGE_NAME}
}

upload_image()
{
  # Upload the new image

  IMAGE_NAME="${CLUSTER_NAME}.${DOMAIN}-${OCP_VERSION}.iso"
  scp /tmp/$IMAGE_NAME root@$KVM_SRV:/var/lib/libvirt/images/$IMAGE_NAME

  deploy_monitor_template
  deploy_new_user_template
  new_vm
}

deploy_new_user_template()
{
  # A script will be created, that should be executed manually once the cluster is
  # up and running. This will create a local user, with the credentials from the 
  # configuration file.

  echo "Creating the New User Script"
  echo "Don't forget to access the folder with the installation files"
  echo "and execute the 'create_admin_user.sh' to add your '$USER_ID' user"
  echo "and '$PASSWORD' as password."

  TEMPLATE_USER="template_new_user.sh"
  TEMPLATE_USER_NEW="new_monitor.sh"
  LOCAL_PATH="/tmp/${CLUSTER_NAME}.${DOMAIN}-${OCP_VERSION}"
  USER_FINAL="$LOCAL_PATH/create_admin_user.sh"

  cp $TEMPLATE_USER $TEMPLATE_USER_NEW
  sed -i "" "s#<dir_here>#$LOCAL_PATH#" $TEMPLATE_USER_NEW
  sed -i "" "s#<user_id>#$USER_ID#" $TEMPLATE_USER_NEW
  sed -i "" "s#<password>#$PASSWORD#" $TEMPLATE_USER_NEW
  chmod -v 755 $TEMPLATE_USER_NEW
  scp $TEMPLATE_USER_NEW root@$LNX_SRV:$USER_FINAL
}

deploy_monitor_template()
{
  # This will create a script that you can monitor the installation progress

  echo "Creating the Monitor Script"
  TEMPLATE_MONITOR="template_monitor.sh"
  TEMPLATE_MONITOR_NEW="new_monitor.sh"
  LOCAL_PATH="/tmp/${CLUSTER_NAME}.${DOMAIN}-${OCP_VERSION}"
  MONITOR_FINAL="monitor_${CLUSTER_NAME}.${DOMAIN}-${OCP_VERSION}.sh"

  cp $TEMPLATE_MONITOR $TEMPLATE_MONITOR_NEW
  sed -i "" "s#<remote_dir>#$LOCAL_PATH#" $TEMPLATE_MONITOR_NEW
  chmod -v 755 $TEMPLATE_MONITOR_NEW
  scp $TEMPLATE_MONITOR_NEW root@$LNX_SRV:/tmp/$MONITOR_FINAL
}

new_vm()
{
  echo "Creating the VM"

  NAME="$CLUSTER_NAME"
  IMAGE_NAME="${CLUSTER_NAME}.${DOMAIN}-${OCP_VERSION}.iso"

  # --noautoconsole is the option to release the terminal, but this option
  # will allaw the machine to shutdown in the next restart, instead of restarting
  # The terminal will get stuck up to the first restart
  echo "virt-install --name $NAME \
                     --memory $MEMORY \
                     --vcpu $VCPU \
                     --os-variant fedora-coreos-stable \
                     --graphics vnc \
                     --cdrom /var/lib/libvirt/images/$IMAGE_NAME \
                     --disk size=$DISK \
                     --network type=direct,source=eno1,source.mode=bridge" >/tmp/wally.sh
 
 # We can't add the cards on all the VMs
 #                    --host-device 02:00.0 --host-device 02:00.1 \
 #                    --host-device 03:00.0 --host-device 03:00.1" >/tmp/wally.sh
  chmod 755 /tmp/wally.sh
  scp /tmp/wally.sh root@$KVM_SRV:/tmp/wally.sh
  ssh root@$KVM_SRV "nohup /tmp/wally.sh >/tmp/vm_output.log 2>&1 &"
  
  echo "let's wait for 120 seconds to prepare a new VM and retrieve"
  echo "the ip address, then setup the DNS entries"
  sleep 120

  # Let's call and setup DNS
  setup_dns
}

## Main
check_requirements_ssh
cluster_info