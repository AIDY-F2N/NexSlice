# NexSlice: Towards an Open and Reproducible Network Slicing Testbed for 5G and Beyond

<div align="center">
    <img src="fig/aidyf2n.png" alt="AIDY-F2N">
</div>

## Overview

This repository provides a deployment of the OpenAirInterface (OAI) 5G Standalone (SA) Core with network slicing, using a Disaggregated Radio Access Network (RAN) architecture. The RAN includes an OAI Central Unit (CU) split into Control Plane (CU-CP) and User Plane (CU-UP) components, an OAI Distributed Unit (DU), and multiple OAI NR-UEs, each assigned to a specific S-NSSAI (Single Network Slice Selection Assistance Information). Network slicing is applied at the core level, ensuring that different UEs are routed through their respective slices. In addition, we connect the UERANSIM simulator to the OAI 5G Core. UERANSIM is an open-source simulator that emulates both a 5G UE and a gNodeB (gNB), effectively representing a 5G mobile device and base station. It is used to generate traffic within the network slice and to evaluate performance and energy consumption.

A Network Slice consists of 5G Core and 5G RAN components, all defined within a PLMN. A slice is identified using S-NSSAI, which consists of:

- Slice/Service Type (SST): Defines the expected slice behavior (e.g., eMBB, URLLC, mMTC, V2X).

- Slice Differentiator (SD): Optionally differentiates slices within the same SST.

Each UE can connect to up to eight (8) slices simultaneously. SST values range from 0 to 255, with: SST 1 = eMBB, SST 2 = URLLC, SST 3 = mMTC, SST 4 = V2X, SST 5-127: Reserved for experimental use and SST 128-255: Reserved for operators

![Slicing](fig/slicing.png)


The common **AMF, NSSF, UDM, UDR, AUSF** components serve all slices. SMF and UPF in **Slice 1 and Slice 2** share the same NRF, making both UPFs discoverable by both SMFs.

Note that SSTs are only for numerical reference and does not reflect standard SST behaviour e.g. eMBB, URLCC, mMTC, V2X etc.

## Contributors

- Yasser BRAHMI, abdenour-yasser.brahmi@telecom-sudparis.eu
- Massinissa AIT ABA, massinissa.ait-aba@davidson.fr

## Table of Contents

- [Build a K8s cluster](#build-a-k8s-cluster)
- [Tools Setup](#tools-setup-helm-multus-and-namespace)
- [OAI 5G SA Core Deployment](#oai-5g-sa-core-deployment)
- [5G RANs Deployments](#ueransim)
- [Monitoring](#setup-prometheus-monitoring)
- [Tests](#generate-traffic-using-iperf3)
- [Collaboration](#beyond-the-basics-network-slicing-and-collaboration)


# Build a K8S cluster
We assume that a Kubernetes cluster is already running using this repository: https://github.com/AIDY-F2N/k8s-cluster-setup-ubuntu24.git

# Tools Setup

1.  Install the Helm CLI usnig this link: https://helm.sh/docs/intro/install/

Helm CLI (Command-Line Interface) is a command-line tool used for managing applications on Kubernetes clusters. It is part of the Helm package manager, which helps you package, deploy, and manage applications as reusable units called Helm charts.

Helm provides a straightforward way to define, install, and upgrade complex Kubernetes applications. With Helm, you can define the desired state of your application using a declarative YAML-based configuration file called a Helm chart. A Helm chart contains all the necessary Kubernetes manifests, configurations, and dependencies required to deploy and run your application.

2.  Install Helm Spray using this command: 
```bash[language=bash]
helm plugin install https://github.com/ThalesGroup/helm-spray
```
Helm Spray is a Helm plugin that simplifies the deployment of Kubernetes applications using Helm charts. Helm is a package manager for Kubernetes that allows you to define, install, and manage applications as reusable units called charts. Helm Spray extends Helm's functionality by providing additional features and capabilities for managing the lifecycle of complex deployments. The command helm plugin install installs the Helm Spray plugin, enabling you to use its functionalities alongside Helm.

3. Clone Multus GitHub repository (À revoir!)
```bash[language=bash]
git clone https://github.com/k8snetworkplumbingwg/multus-cni.git
```
  - Apply a daemonset which installs Multus using kubectl. From the root directory of the clone, apply the daemonset YAML file:
    ```bash[language=bash]
    kubectl apply -f multus-cni/deployments/multus-daemonset-thick.yml
    ```
4. Create a namespace where the helm-charts will be deployed, in this tutorial, we deploy them in oai namespace. To create oai namespace use the below command on your cluster: 
    ```bash[language=bash]
    kubectl create ns nexslice
    ```

5. Clone this repository:
```bash[language=bash]
git clone https://github.com/AIDY-F2N/NexSlice.git
```


# OAI 5G SA Core Deployment
1. Open a terminal inside the folder "NexSlice" and deploy [setpodnet-scheduler](https://github.com/AIDY-F2N/setpodnet-scheduler) using the following command:

```bash[language=bash]
kubectl apply -f setpodnet-scheduler.yaml
```

2. Add latency and bandwidth constraints between pods: The User Plane Function (UPF) is a critical component in 5G networks, enabling low latency and high throughput. To optimize its deployment and ensure efficient communication with other core network functions, we need to specify constraints that reflect the UPF's requirements. For example, we have added constraints to the values file of the UPF pod (OAI-UERANSIM/OAI+UERANSIM/oai-5g-core-setpodnet/oai-upf/values.yaml) between UPF and SMF, and between UPF and AMF, using the following annotations:

```yaml
annotations:
  communication-with: "oai-amf,oai-smf"
  latency-oai-amf: "10"
  bandwidth-oai-amf: "1"
  latency-oai-smf: "10"
  bandwidth-oai-smf: "1"
```

3. Open a terminal inside the folder "NexSlice", and run the following commands to deploy the OAI core:
```bash[language=bash]
helm dependency update 5g_core/oai-5g-advance/
helm install 5gc 5g_core/oai-5g-advance/ -n nexslice
```
The two commands you provided are related to the Helm package manager and are used to manage and deploy Helm charts onto a Kubernetes cluster. 
After this, run this command to check if the core is deployed: 
```bash[language=bash]
kubectl get pods -n nexslice 
```

<div align="center">
    <img src="figures/5gc.png" alt="AIDY-F2N">
</div>


# Radio Access Networks (RANs)

## OAI Disaggregated 5G RAN
This setup launches the RAN components (OAI CU-CP, CU-UP, and DU) with SST support from 1 to 3, and deploys three OAI nrUEs, each configured with a different SST:

```bash[language=bash]
helm install cucp 5g_ran/dis_ran_gnb1/oai-cu-cp/ -n nexslice
helm install cuup 5g_ran/dis_ran_gnb1/oai-cu-up -n nexslice
helm install du 5g_ran/dis_ran_gnb1/oai-du -n nexslice

helm install nrue1 5g_ran/oai-nr-ue1 -n nexslice 
helm install nrue2 5g_ran/oai-nr-ue2 -n nexslice
```

To check if the UE has an IP address:

```bash[language=bash]
kubectl exec -it -n nexslice -c nr-ue $(kubectl get pods -n nexslice | grep oai-nr-ue | awk '{print $1}') -- ifconfig oaitun_ue1 |grep -E '(^|\s)inet($|\s)' | awk {'print $2'}
```
To test connectivity with a ping:

```bash[language=bash]
kubectl exec -it -n nexslice -c nr-ue $(kubectl get pods -n nexslice | grep oai-nr-ue2 | awk '{print $1}') -- ping -I oaitun_ue1 -c4 google.fr
```

## UERANSIM Deployment

UERANSIM stands for User Equipment (UE) and Radio Access Network (RAN) Simulator. It is an open-source software tool that simulates the behavior of a 5G RAN, specifically emulating the functions of both the UE and the gNB. UERANSIM allows users to replicate 5G UE behaviors such as mobility, radio resource management, connection establishment, and data transfer. It provides a realistic environment for testing and evaluating the performance of 5G networks and applications.

```bash[language=bash]
helm install ueransim-gnb 5g_ran/ueransim-gnb2/ -n nexslice

helm install ueransim-ue1 5g_ran/ueransim-ue1/ -n nexslice
helm install ueransim-ue2 5g_ran/ueransim-ue2/ -n nexslice
helm install ueransim-ue3 5g_ran/ueransim-ue3/ -n nexslice
```

# Monitoring

# iperf3

# Collaboration
