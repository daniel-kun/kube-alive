#!/bin/bash
if [ ! -n "${PIPWD}" ] || [ ! -n "${PIMASTER}" ] || [ ! -n "${PINODE}" ] || [ ! -n "${PIUSERPWD}" ]; then
  echo "Error, all env vars must be set: PIPWD, PIMASTER, PINODE and PIUSERPWD.";
  exit 1
fi

echo "${PIPWD}
${PIPWD}
" | sudo passwd pi
sudo sh -c "echo 'kubepi-${PINODE}' > /etc/hostname"
sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get -y install vim screen
curl -sSL get.docker.com | sh
sudo usermod pi -aG docker && sudo dphys-swapfile swapoff && sudo dphys-swapfile uninstall && sudo update-rc.d dphys-swapfile remove
sudo sed -i 's/rootwait/rootwait cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/cmdline.txt
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list && sudo apt-get update -q && sudo apt-get install -qy kubeadm 

# Used when the kube-registry-proxy does not work (due to hostPort not working), so that the master node can be used as the docker registry:
sudo sh -c "echo '{ \"insecure-registries\":[\"${PIMASTER}:5000\"] }' > /etc/docker/daemon.json"
# For port-mapping, used for hostPort (e.g. for kube-registry-proxy)
sudo mkdir -p /etc/cni/net.d
sudo sh -c "echo '{
    \"name\": \"weave\",
    \"type\": \"weave-net\",
    \"hairpinMode\": true,
    \"plugins\": [
        {
            \"type\": \"bridge\",
            \"bridge\": \"cni0\",
            \"isGateway\": true,
            \"ipMasq\": true,
            \"ipam\": {
                \"type\": \"host-local\",
                \"subnet\": \"10.30.0.0/16\",
                \"routes\": [
                    { \"dst\": \"0.0.0.0/0\"   }
                ]
            }
        },
        {
            \"type\": \"portmap\",
            \"capabilities\": {\"portMappings\": true},
            \"snat\": true
        }
    ]
}' > /etc/cni/net.d/10-weave.conf"

sudo useradd -m daniel && sudo usermod daniel -aG docker && sudo usermod daniel -aG sudo
echo "${PIUSERPWD}
${PIUSERPWD}
"  | sudo passwd daniel

sudo -- chsh -s /bin/bash daniel && sudo -u daniel -- sh -c "mkdir -p /home/daniel/.ssh && echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAxsJKN8qgCEtDKLyLwD+q9IuiJyBz/9aNemz+rU3naoZs2qzmx2iywkaE+FvWW7j1d489s0nEY+zDJ8MOJdjXz5WqEkWBmmuQyk9u8D+DfGYOBgNIiLzUGHhaBsWRd8xXLMXTyWrz1H9n0XtmMGMl8xXRMCRZCNTTuxPU4LzDZsavmp232KpzIy0KzveqNIXKFVlJiq2CuSSEXiBmvocKzXBjH99nBkVox0xd/Cb8YO/Z0uMNtSmuZGQ+XbDOPdeDpD0/U92WV3GsOm0GOUr5S40gdOPJQKA81OXJJMXIeVaU1z3soZ+3Z1+CJBAAAXYFmCECOLaYdjSEMU9VSPDOsQ== rsa-key-20171217' > /home/daniel/.ssh/authorized_keys"

sudo shutdown -r now

