#!/bin/bash

#
# Install Cloudera CDH.
#
VERSION=1.5.0

USERNAME=ec2-user
USERHOME=/home/${USERNAME}
CLOUDERA=${USERHOME}/cloudera

DIRECTORDIR=${CLOUDERA}/cloudera-director-client-${VERSION}
AWS_CLUSTER_CONF=${DIRECTORDIR}/aws.cluster.conf

${DIRECTORDIR}/bin/cloudera-director bootstrap ${AWS_CLUSTER_CONF} --lp.terminate.assumeYes=true
