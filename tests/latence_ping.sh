#!/bin/bash

NAMESPACE="oai"
UE_POD=$(kubectl get pods -n oai --no-headers | grep ueransim-gnb-ues | awk '{print $1}')
#NUM_UES=$(( $(kubectl exec -n $NAMESPACE $UE_POD -- ip a | grep -c uesimtun) / 2 ))

for i in $(seq 0 99); do
  echo "🔹 Pinging from uesimtun$i ..."
  kubectl exec -n $NAMESPACE $UE_POD -- ping -I uesimtun$i -c 3 google.com &
  sleep 1
done

wait
echo "✅ Done."