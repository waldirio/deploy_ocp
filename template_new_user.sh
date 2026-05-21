#!/bin/bash
export KUBECONFIG="<dir_here>/ocp/auth/kubeconfig"

OC_PATH="<dir_here>/oc"
USER_ID="<user_id>"
PASSWORD="<password>"

htpasswd -c -B -b users.htpasswd $USER_ID $PASSWORD

$OC_PATH create secret generic htpass-secret --from-file=htpasswd=users.htpasswd -n openshift-config

$OC_PATH patch oauth cluster --type='merge' -p '{
  "spec": {
    "identityProviders": [
      {
        "name": "my_htpasswd_provider",
        "mappingMethod": "claim",
        "type": "HTPasswd",
        "htpasswd": {
          "fileData": {
            "name": "htpass-secret"
          }
        }
      }
    ]
  }
}'

$OC_PATH adm policy add-cluster-role-to-user cluster-admin admin
