#!/bin/bash

FULL_PATH="<remote_dir>"

export KUBECONFIG="$FULL_PATH/ocp/auth/kubeconfig"

watch -n1 "
  echo \"$FULL_PATH/oc get co\"
  $FULL_PATH/oc get co
  echo
  echo \"$FULL_PATH/oc get clusterversion\"
  $FULL_PATH/oc get clusterversion
  echo
  echo \"$FULL_PATH/oc get nodes\"
  $FULL_PATH/oc get nodes
  echo
  $FULL_PATH/oc get pods --no-headers -A | grep -v -E '( Completed | Running )' | wc -l
  echo \"$FULL_PATH/oc get pods -A | grep -v -E '( Completed | Running )'\"
  $FULL_PATH/oc get pods -A | grep -v -E '( Completed | Running )'
"
