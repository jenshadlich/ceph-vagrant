#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

export CEPH_SERVER_NODE=$(hostname -s)
export CEPH_RELEASE=jewel
export CEPH_RGW_PORT=8888

wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -

echo deb http://download.ceph.com/debian-${CEPH_RELEASE}/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list

apt-get update -q > /dev/null
apt-get install -q -y netcat
apt-get install -q -y jq
apt-get install -q -y ceph-deploy

ceph-deploy install --release ${CEPH_RELEASE} ${CEPH_SERVER_NODE}
ceph-deploy pkg --install librados-dev ${CEPH_SERVER_NODE}

ceph-deploy new ${CEPH_SERVER_NODE}
echo "osd max object name len = 256" >> ceph.conf
echo "osd max object namespace len = 64" >> ceph.conf
echo "osd check max object name len on startup = false" >> ceph.conf
echo "osd crush chooseleaf type = 0" >> ceph.conf
echo "osd pool default size = 1" >> ceph.conf
echo "osd journal size = 128" >> ceph.conf
echo "#debug ms = 1" >> ceph.conf
echo "#debug rgw = 20" >> ceph.conf

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

ceph-deploy install --release ${CEPH_RELEASE} --rgw ${CEPH_SERVER_NODE}
ceph-deploy rgw create ${CEPH_SERVER_NODE}

echo "" >> ceph.conf
echo "[client]" >> ceph.conf
echo "rgw frontends = civetweb port=${CEPH_RGW_PORT}" >> ceph.conf

echo "" >> ceph.conf
echo "[client.rgw.${CEPH_SERVER_NODE}]" >> ceph.conf
echo "host = ${CEPH_SERVER_NODE}" >> ceph.conf
#echo "log file = /var/log/radosgw/client.rgw.${CEPH_SERVER_NODE}.log" >> ceph.conf

ceph-deploy --overwrite-conf config push ${CEPH_SERVER_NODE}
service radosgw restart id="rgw.${CEPH_SERVER_NODE}"

echo "Waiting for radosgw to launch on ${CEPH_RGW_PORT}..."
while ! nc -z localhost ${CEPH_RGW_PORT}; do
  sleep 0.1
done
echo "radosgw launched"

#--name client.rgw.${CEPH_SERVER_NODE}

echo ""
echo "Create user 'master'"
radosgw-admin user create --uid=master --display-name="master" --key-type=s3 --access-key="GMGR882QK9J3346TICDX" --secret="edd7NaBJWhPsVKue3eH89K337aQ6UNdBF83PZDNu"
echo "Create subuser 'master:testuser'"
radosgw-admin subuser create --uid=testuser --subuser=master:testuser --key-type=s3 --access-key="F6RMEXCDZ84QH5KB1OHN" --secret="LXyAPRkeuYh7zyVF8x0wsFSUEJDQB0ukHLuC2ihS"
radosgw-admin subuser modify --access=full --subuser=master:testuser

echo "############################"
echo "# Done CEPH OBJECT GATEWAY.#"
echo "############################"

echo ""
echo "Grant admin capabilities"
radosgw-admin caps add --uid master --caps "buckets=*"
radosgw-admin caps add --uid master --caps "metadata=*"
radosgw-admin caps add --uid master --caps "usage=*"
radosgw-admin caps add --uid master --caps "users=*"
echo "Done"

# clean up
apt-get autoremove -q -y
