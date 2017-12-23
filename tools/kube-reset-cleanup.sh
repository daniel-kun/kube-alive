#!/bin/sh
# This is a workaround for a messed up kube master node that has been kubeadm init'ed multiple times.
# (However, in the end, I ended up discarding flannel and using weave instead)
rm -rvf /var/lib/cni/
rm -rvf /var/lib/kubelet/*
rm -rvf /etc/cni/
ifconfig cni0 down
ifconfig flannel.1 down
ifconfig docker0 down
ip link delete cni0
ip link delete flannel.1
