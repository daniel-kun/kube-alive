# Kubernetes: It's alive!

Some tools to experiment with Kubernetes (k8s) to observe it's behaviour in real scenarios.
You should have a k8s cluster up and running already to deploy the tools from this repository.
I used a Raspberry Pi cluster with five nodes and set them up as described by Scott Hanselman here: https://www.hanselman.com/blog/HowToBuildAKubernetesClusterWithARMRaspberryPiThenRunNETCoreOnOpenFaas.aspx

*Disclaimer: This is currently early work in progress, the configs include hard-coded IP addresses of the master node and the required local Docker registry must be set up manually.*

Behaviours of k8s that can be observed "live":

## Load-Balancing
When a ReplicaSet with multiple Pods exist, see how results are served from different Pods. Each Pod returns it's MAC address. (see src/getmac or http://<ip-of-master>:80)

## Self-Healing
When an app crashes, see how the Pod is recreated using a health check. (see src/healthcheck or http://<ip-of-master>:81)

## Auto-Scale
When traffic can not be served with a single Pod, more Pods are created automatically. (coming soon)

## Deployment
When a deployment is updated, you see that new Pods are created and then old Pods are killed. (coming soon)
