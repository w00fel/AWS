#!/bin/bash

#
# Download/configure everything needed for installing Cloudera CDH.
#
VERSION=1.5.0

USERNAME=ec2-user
USERHOME=/home/${USERNAME}
CLOUDERA=${USERHOME}/cloudera

AMAZON=https://s3.amazonaws.com
BUCKET=${AMAZON}/cleo-cloudera-aws
IDENTITY=http://169.254.169.254/latest/dynamic/instance-identity/document

#
# Update time
#
yum -y install ntp
service ntpd start
ntpdate -u 0.amazon.pool.ntp.org

#
# Get cloudera director files.
#
mkdir -p ${CLOUDERA}/cloudera-director-client-${VERSION}
mkdir -p ${CLOUDERA}/cloudera-director-server-${VERSION}
mkdir -p ${CLOUDERA}/aws

LAUNCHPAD_CLIENT_ZIP=cloudera-director-client-${VERSION}-director${VERSION}.tar.gz
LAUNCHPAD_SERVER_ZIP=cloudera-director-server-${VERSION}-director${VERSION}.tar.gz

for LAUNCHPAD_ZIP in ${LAUNCHPAD_CLIENT_ZIP} ${LAUNCHPAD_SERVER_ZIP}
do
    wget -nv ${BUCKET}/media/${LAUNCHPAD_ZIP} --output-document=${CLOUDERA}/${LAUNCHPAD_ZIP}
done

tar xvf ${CLOUDERA}/${LAUNCHPAD_CLIENT_ZIP} -C ${CLOUDERA}/cloudera-director-client-${VERSION} --strip-components=1
tar xvf ${CLOUDERA}/${LAUNCHPAD_SERVER_ZIP} -C ${CLOUDERA}/cloudera-director-server-${VERSION} --strip-components=1

#
# Get default region and instance id.
#
wget -nv ${AMAZON}/aws-cli/awscli-bundle.zip --output-document=${CLOUDERA}/aws/awscli-bundle.zip
wget -nv ${BUCKET}/media/jq --output-document=${CLOUDERA}/aws/jq

unzip ${CLOUDERA}/aws/awscli-bundle.zip -d ${CLOUDERA}/aws
${CLOUDERA}/aws/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
chmod 755 ${CLOUDERA}/aws/jq
export JQ_CMD=${CLOUDERA}/aws/jq

export AWS_DEF_REGION=$(curl -s ${IDENTITY} | ${JQ_CMD} '.region'  | sed 's/^"\(.*\)"$/\1/')
export AWS_INSTANCEID=$(curl -s ${IDENTITY} | ${JQ_CMD} '.instanceId' | sed 's/^"\(.*\)"$/\1/' )

#
# Customize aws.cluster.conf.
#
AWS_CLUSTER_CONF=${CLOUDERA}/cloudera-director-client-${VERSION}/aws.cluster.conf
wget -nv ${BUCKET}/config/aws.cluster.conf.${VERSION} --output-document=${AWS_CLUSTER_CONF}

export AWS_SUBNETID=SUBNETID-CFN-REPLACE
export AWS_SECURITYGROUPIDS=SECURITYGROUPIDS-CFN-REPLACE
export AWS_KEYNAME=KEYNAME-CFN-REPLACE
export AWS_PRIVATEKEYNAME=${AWS_KEYNAME}.pem
export AWS_AMI=AMI-CFN-REPLACE
export AWS_CDH_MASTER_COUNT=MASTER-COUNT-CFN-REPLACE
export AWS_CDH_WORKER_COUNT=WORKER-COUNT-CFN-REPLACE
export AWS_CDH_MANAGER_INSTANCE_TYPE=MANAGER-TYPE-CFN-REPLACE
export AWS_CDH_MASTER_INSTANCE_TYPE=MASTER-TYPE-CFN-REPLACE
export AWS_CDH_WORKER_INSTANCE_TYPE=WORKER-TYPE-CFN-REPLACE

sed -i "s/region-REPLACE-ME/${AWS_DEF_REGION}/g" ${AWS_CLUSTER_CONF}
sed -i "s/instanceNamePrefix.*/instanceNamePrefix: cloudera-director-${AWS_INSTANCEID}/g" ${AWS_CLUSTER_CONF}

# Replace these via CloudFormation User-Data
sed -i "s/subnetId-REPLACE-ME/${AWS_SUBNETID}/g" ${AWS_CLUSTER_CONF}
sed -i "s/securityGroupsIds-REPLACE-ME/${AWS_SECURITYGROUPIDS}/g" ${AWS_CLUSTER_CONF}
sed -i "s/keyName-REPLACE-ME/${AWS_KEYNAME}/g" ${AWS_CLUSTER_CONF}
sed -i "s/privateKeyName-REPLACE-ME/${AWS_PRIVATEKEYNAME}/g" ${AWS_CLUSTER_CONF}
sed -i "s/image-REPLACE-ME/${AWS_AMI}/g" ${AWS_CLUSTER_CONF}
sed -i "s/manager-type-REPLACE-ME/${AWS_CDH_MANAGER_INSTANCE_TYPE}/g" ${AWS_CLUSTER_CONF}
sed -i "s/master-type-REPLACE-ME/${AWS_CDH_MASTER_INSTANCE_TYPE}/g" ${AWS_CLUSTER_CONF}
sed -i "s/worker-type-REPLACE-ME/${AWS_CDH_WORKER_INSTANCE_TYPE}/g" ${AWS_CLUSTER_CONF}
sed -i "s/master-count-REPLACE-ME/${AWS_CDH_MASTER_COUNT}/g" ${AWS_CLUSTER_CONF}
sed -i "s/worker-count-REPLACE-ME/${AWS_CDH_WORKER_COUNT}/g" ${AWS_CLUSTER_CONF}

wget -nv ${BUCKET}/keys/${AWS_PRIVATEKEYNAME} --output-document=${USERHOME}/${AWS_PRIVATEKEYNAME}
chmod 400 ${USERHOME}/${AWS_PRIVATEKEYNAME}

chown -R ${USERNAME} ${CLOUDERA}
