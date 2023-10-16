echo "* speed up provision"
sudo apt-get remove -y --purge man-db # no need for man

echo "* install dependencies"
apt-get update
sudo apt-get remove docker docker-engine docker.io containerd runc
apt-get install -y make git gcc build-essential jq python3-pip  apt-transport-https ca-certificates curl gnupg-agent software-properties-common zip unzip golang-cfssl libseccomp2 net-tools
sudo pip install pyyaml

echo "* install go"
GO_VERSION=1.19
wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
tar -xf go${GO_VERSION}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo mv go /usr/local
rm go${GO_VERSION}.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin:$HOME/go/bin" >> /home/vagrant/.profile
echo "export PATH=\$PATH:/usr/local/go/bin:$HOME/go/bin" >> /root/.profile
export PATH=$PATH:/usr/local/go/bin:/home/vagrant/go/bin

echo "* install cri-containerd"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker vagrant
sudo systemctl start containerd

echo "* lttng setup"
sudo apt install -y linux-headers-$(uname -r)
sudo apt install -y lttng-modules-dkms lttng-tools liblttng-ust-*
sudo usermod -a -G tracing vagrant
