#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

export CEPH_SERVER_NODE=$(hostname -s)
export CEPH_RELEASE=jewel
export CEPH_RGW_PORT=8888

wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -

echo deb http://download.ceph.com/debian-${CEPH_RELEASE}/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list

apt-get update -q > /dev/null
apt-get install -q -y netcat
apt-get install -q -y ceph-deploy

ceph-deploy install --release ${CEPH_RELEASE} ${CEPH_SERVER_NODE}
ceph-deploy pkg --install librados-dev ${CEPH_SERVER_NODE}

ceph-deploy new ${CEPH_SERVER_NODE}
echo "#osd crush chooseleaf type = 0" >> ceph.conf
echo "osd pool default size = 1" >> ceph.conf
echo "#osd journal size = 128" >> ceph.conf
echo "#debug ms = 1" >> ceph.conf
echo "#debug rgw = 20" >> ceph.conf

ceph-deploy install ${CEPH_SERVER_NODE}
ceph-deploy mon create-initial

mkdir /var/local/osd0
chown ceph:ceph /var/local/osd0

mkdir /var/local/osd1
chown ceph:ceph /var/local/osd1

ceph-deploy osd prepare ${CEPH_SERVER_NODE}:/var/local/osd0
ceph-deploy osd activate ${CEPH_SERVER_NODE}:/var/local/osd0

ceph-deploy osd prepare ${CEPH_SERVER_NODE}:/var/local/osd1
ceph-deploy osd activate ${CEPH_SERVER_NODE}:/var/local/osd1

# print version
ceph -v

echo "Wait 5 seconds ..."
sleep 5

# print health
ceph -s

echo "##############"
echo "# Done CEPH. #"
echo "##############"
