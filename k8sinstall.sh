#변수 
master=211.100.2.200
node1=211.100.2.201
node2=211.100.2.202
node3=211.100.2.203
name=$(whoami)
####

cat <<EOF | sudo tee /etc/hosts
$master master
$node1 node1
$node2 node2
$node3 node3
EOF
#####/etc/hosts complet ######
#####/etc/hosts complet ######
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab    ## /etc/fstab
#####swapoff complet ######
#####swapoff complet ######
if /sbin/ifconfig | grep -q $master;then
  echo 'master' > /etc/hostname
elif /sbin/ifconfig | grep -q $node1;then
  echo 'node1' > /etc/hostname
elif /sbin/ifconfig | grep -q $node2;then
  echo 'node2' > /etc/hostname
elif /sbin/ifconfig | grep -q $node3;then
  echo 'node3' > /etc/hostname
fi
#####hostname complet ######
#####hostname complet ######
setenforce 0

getenforce
#####selinuxoff complet ######
#####selinuxoff complet ######

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe br_netfilter
modprobe overlay

sysctl --system

#####iptables kernel complet ######
#####iptables kernel complet ######

dnf install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
#####yum-utils install complet ######
#####docker repo add complet ######

dnf -y install containerd.io

mkdir -p /etc/containerd

containerd config default | tee /etc/containerd/config.toml

sed -i '125s/false/true/' /etc/containerd/config.toml

systemctl --now enable containerd

#####(CRI) containerd.io install complet ######
#####(CRI) containerd.io config complet ######


if /sbin/ifconfig | grep -q $master;
then
firewall-cmd --permanent --add-port={6443,2379-2380,10250,10259,10257}/tcp
firewall-cmd --reload
elif /sbin/ifconfig | grep -q $node1 or $node2 or $node3;
then
firewall-cmd --permanent --add-port={10250,30000-32767}/tcp
firewall-cmd --reload
fi

#####FirewallD######
#####FirewallD######

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl --now enable kubelet

#####k8s repo add && command install######
#####k8s repo add && command install######


if /sbin/ifconfig | grep -q $master;
then
curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.3/manifests/calico.yaml -O
sed -i '4551s/#//' calico.yaml
sed -i '4552s/#//' calico.yaml
sed -i '4552s/192.168.0.0/172.16.0.0/' calico.yaml
sed -i '4551s/^ //g' calico.yaml
sed -i '4552s/^ //g' calico.yaml

kubeadm init --apiserver-advertise-address=$master --pod-network-cidr=172.16.0.0/16

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f calico.yaml
fi

#####calico install && kubeadm init######
#####calico install && kubeadm init######

init 6