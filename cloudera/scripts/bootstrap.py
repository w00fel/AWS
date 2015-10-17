#!/usr/bin/env python

from __future__ import print_function

import subprocess
import sys

LOG = open('/home/ubuntu/cloudera/bootstrap.log', 'a', 0)

# Bootstrap Cluster
print("Bootstrapping CDH Cluster", file=LOG)
args = []
args.append('/home/ubuntu/cloudera/director-client/bin/cloudera-director')
args.append('bootstrap')
args.append('/home/ubuntu/cloudera/cluster.conf')

sys.exit(subprocess.Popen(args, stdout=LOG, stderr=subprocess.STDOUT).wait())
