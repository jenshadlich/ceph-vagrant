#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

#export DATA_DEVICE=sdb
#export JOURNAL_DEVICE=sdc
#export FS_TYPE=xfs
export CEPH_SERVER_NODE=ceph-infernalis
export CEPH_RELEASE=infernalis
export CEPH_RGW_PORT=8888

wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -

echo deb http://download.ceph.com/debian-${CEPH_RELEASE}/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list

sudo apt-get update > /dev/null
sudo apt-get install -q -y ceph-deploy

ceph-deploy install --release ${CEPH_RELEASE} ${CEPH_SERVER_NODE}
ceph-deploy pkg --install librados-dev ${CEPH_SERVER_NODE}

ceph-deploy new ${CEPH_SERVER_NODE}
echo "osd crush chooseleaf type = 0" >> ceph.conf
echo "osd pool default size = 1" >> ceph.conf
echo "osd journal size = 128" >> ceph.conf

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

#ceph-deploy disk --fs-type ${FS_TYPE} zap ${CEPH_SERVER_NODE}:${DATA_DEVICE}
#ceph-deploy disk --fs-type ${FS_TYPE} zap ${CEPH_SERVER_NODE}:${JOURNAL_DEVICE}
#ceph-deploy osd --fs-type ${FS_TYPE} create ${CEPH_SERVER_NODE}:${DATA_DEVICE}:${JOURNAL_DEVICE}

# version
ceph -v

echo "Wait 5 seconds ..."
sleep 5

# health
ceph -s

echo "Done CEPH."

ceph-deploy install --rgw ${CEPH_SERVER_NODE}
ceph-deploy rgw create ${CEPH_SERVER_NODE}

echo "" >> ceph.conf
echo "[client]" >> ceph.conf
echo "rgw frontends = civetweb port=${CEPH_RGW_PORT}" >> ceph.conf

echo "" >> ceph.conf
echo "[client.rgw.${CEPH_SERVER_NODE}]" >> ceph.conf
echo "host = ${CEPH_SERVER_NODE}" >> ceph.conf
echo "log file = /var/log/radosgw/client.rgw.${CEPH_SERVER_NODE}.log" >> ceph.conf

ceph-deploy --overwrite-conf config push ${CEPH_SERVER_NODE}
service radosgw restart id="rgw.${CEPH_SERVER_NODE}"

echo "Wait 5 seconds ..."
sleep 5

# check ListAllMyBucketsResult
curl http://${CEPH_SERVER_NODE}:${CEPH_RGW_PORT}

echo "Done CEPH OBJECT GATEWAY."