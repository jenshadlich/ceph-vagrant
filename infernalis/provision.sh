#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

#export DATA_DEVICE=sdb
#export JOURNAL_DEVICE=sdc
#export FS_TYPE=xfs
export CEPH_SERVER_NODE=ceph-infernalis
export CEPH_RELEASE=infernalis

wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -

echo deb http://download.ceph.com/debian-${CEPH_RELEASE}/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list

sudo apt-get update > /dev/null
sudo apt-get install -q -y ceph-deploy

ceph-deploy install --release ${CEPH_RELEASE} ${CEPH_SERVER_NODE}
ceph-deploy pkg --install librados-dev ${CEPH_SERVER_NODE}

ceph-deploy new ${CEPH_SERVER_NODE}
echo "osd crush chooseleaf type = 0" >> ceph.conf
echo "osd pool default size = 1" >> ceph.conf

ceph-deploy install ${CEPH_SERVER_NODE}
ceph-deploy mon create-initial

mkdir /var/local/osd0
chown ceph:ceph /var/local/osd0

ceph-deploy osd prepare ${CEPH_SERVER_NODE}:/var/local/osd0
ceph-deploy osd activate ${CEPH_SERVER_NODE}:/var/local/osd0

#ceph-deploy disk --fs-type ${FS_TYPE} zap ${CEPH_SERVER_NODE}:${DATA_DEVICE}
#ceph-deploy disk --fs-type ${FS_TYPE} zap ${CEPH_SERVER_NODE}:${JOURNAL_DEVICE}
#ceph-deploy osd --fs-type ${FS_TYPE} create ${CEPH_SERVER_NODE}:${DATA_DEVICE}:${JOURNAL_DEVICE}

# version
ceph -v

# health
ceph -s

echo "Done."