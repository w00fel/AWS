#!/usr/bin/env python

import subprocess
import sys

LOG = open('/home/ubuntu/cloudera/bootstrap.log', 'a')

# Bootstrap Cluster
print >> LOG, "Bootstrapping CDH Cluster\n"
args = []
args.append('/home/ubuntu/cloudera/director-client/bin/cloudera-director')
args.append('bootstrap-remote')
args.append('/home/ubuntu/cloudera/aws.cluster.conf')
args.append('--lp.remote.username=admin')
args.append('--lp.remote.password=admin')
args.append('--lp.remote.hostAndPort=127.0.0.1:7189')

subprocess.Popen(args, stdout=LOG, stderr=subprocess.STDOUT).wait()

print '{ "ControllerAction" : "bootstrapped" }'
sys.exit(0)
