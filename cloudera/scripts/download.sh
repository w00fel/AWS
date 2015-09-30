#!/bin/bash

usage() {
cat <<EOF
    Usage: $0 [options]
        -h print usage
        -b S3 BuildBucket that contains config/scripts/templates/media
EOF
    exit 1
}

# ------------------------------------------------------------------
# Read all inputs
# ------------------------------------------------------------------

while getopts ":h:b:" o; do
    case "${o}" in
        h) usage && exit 0
                ;;
        b) BUILDBUCKET=${OPTARG}
                ;;
        *) usage
                ;;
    esac
done

VERSION=1.5.0
BUILDBUCKET=$(echo ${BUILDBUCKET} | sed 's/"//g')

# ------------------------------------------------------------------
# Download everything needed for installing Cloudera
# ------------------------------------------------------------------

# first update time
yum -y install ntp
service ntpd start
ntpdate -u 0.amazon.pool.ntp.org

mkdir -p /home/ec2-user/cloudera/cloudera-director-client-${VERSION}
mkdir -p /home/ec2-user/cloudera/cloudera-director-server-${VERSION}
mkdir -p /home/ec2-user/cloudera/aws

LAUNCHPAD_CLI_ZIP=cloudera-director-client-${VERSION}-director${VERSION}.tar.gz
LAUNCHPAD_SERVER_ZIP=cloudera-director-server-${VERSION}-director${VERSION}.tar.gz

for LAUNCHPAD_ZIP in ${LAUNCHPAD_CLI_ZIP} ${LAUNCHPAD_SERVER_ZIP}
do
    wget https://s3.amazonaws.com/${BUILDBUCKET}/media/${LAUNCHPAD_ZIP} --output-document=/home/ec2-user/cloudera/${LAUNCHPAD_ZIP}
done

wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip --output-document=/home/ec2-user/cloudera/aws/awscli-bundle.zip
wget https://s3.amazonaws.com/${BUILDBUCKET}/media/jq --output-document=/home/ec2-user/cloudera/aws/jq

tar xvf /home/ec2-user/cloudera/${LAUNCHPAD_CLI_ZIP} -C /home/ec2-user/cloudera/cloudera-director-client-${VERSION} --strip-components=1
tar xvf /home/ec2-user/cloudera/${LAUNCHPAD_SERVER_ZIP} -C /home/ec2-user/cloudera/cloudera-director-server-${VERSION} --strip-components=1

cd /home/ec2-user/cloudera/aws
unzip awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
chmod 755 ./jq
export JQ_COMMAND=/home/ec2-user/cloudera/aws/jq

AWS_CLUSTER_CONF=/home/ec2-user/cloudera/cloudera-director-client-${VERSION}/aws.cluster.conf

wget https://raw.githubusercontent.com/w00fel/AWS/master/cloudera/config/aws.cluster.conf.${VERSION} --output-document=${AWS_CLUSTER_CONF}

export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | ${JQ_COMMAND} '.region'  | sed 's/^"\(.*\)"$/\1/')
export AWS_INSTANCEID=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | ${JQ_COMMAND} '.instanceId' | sed 's/^"\(.*\)"$/\1/' )

cd /home/ec2-user/cloudera/cloudera-director-client-${VERSION}

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

# Replace these via script variables
sed -i "s/region-REPLACE-ME/${AWS_DEFAULT_REGION}/g" ${AWS_CLUSTER_CONF}
sed -i "s/placementGroup-REPLACE-ME/${AWS_PLACEMENT_GROUP_NAME}/g" ${AWS_CLUSTER_CONF}
sed -i "s/instanceNamePrefix.*/instanceNamePrefix: cloudera-director-${AWS_INSTANCEID}/g" ${AWS_CLUSTER_CONF}

# Replace these via CloudFormation User-Data
sed -i "s/subnetId-REPLACE-ME/${AWS_SUBNETID}/g" ${AWS_CLUSTER_CONF}
sed -i "s/securityGroupsIds-REPLACE-ME/${AWS_SECURITYGROUPIDS}/g" ${AWS_CLUSTER_CONF}
sed -i "s/keyName-REPLACE-ME/${AWS_KEYNAME}/g" ${AWS_CLUSTER_CONF}
sed -i "s/privateKeyName-REPLACE-ME/${AWS_PRIVATEKEYNAME}/g" ${AWS_CLUSTER_CONF}
sed -i "s/image-REPLACE-ME/${AWS_AMI}/g" ${AWS_CLUSTER_CONF}
sed -i "s/manager-type-REPLACE-ME/${AWS_CDH_MANAGER_TYPE}/g" ${AWS_CLUSTER_CONF}
sed -i "s/master-type-REPLACE-ME/${AWS_CDH_MASTER_TYPE}/g" ${AWS_CLUSTER_CONF}
sed -i "s/worker-type-REPLACE-ME/${AWS_CDH_WORKER_TYPE}/g" ${AWS_CLUSTER_CONF}
sed -i "s/master-count-REPLACE-ME/${AWS_CDH_MASTER_COUNT}/g" ${AWS_CLUSTER_CONF}
sed -i "s/worker-count-REPLACE-ME/${AWS_CDH_WORKER_COUNT}/g" ${AWS_CLUSTER_CONF}

chown -R ec2-user /home/ec2-user/cloudera
