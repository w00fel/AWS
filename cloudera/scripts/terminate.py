#!/usr/bin/env python

from __future__ import print_function

import subprocess
import boto
import sys

from boto.route53.record import ResourceRecordSets
from boto.route53.exception import DNSServerError

PUBLIC_ZONE_ID = "{{publicZone}}"
PRIVATE_ZONE_ID = "{{privateZone}}"

LOG = open('/home/ubuntu/cloudera/terminate.log', 'a', 0)

# Delete DNS Records
print("Deleting DNS Records", file=LOG)
conn = boto.connect_route53()
try:
    hosts = []
    changes = ResourceRecordSets(conn, PRIVATE_ZONE_ID)
    records = [r for r in conn.get_all_rrsets(PRIVATE_ZONE_ID) if r.type == "CNAME"]
    for record in records:
        changes.add_change_record("DELETE", record)
        hosts.append(record.name)
    if records:
        changes.commit()

        changes = ResourceRecordSets(conn, PUBLIC_ZONE_ID)
        records  = [r for r in conn.get_all_rrsets(PUBLIC_ZONE_ID) if r.type == "CNAME" and r.name in hosts]
        for record in records:
            changes.add_change_record("DELETE", record)
        if records:
            changes.commit()

except DNSServerError:
    print("Error Deleting DNS Records", file=LOG)

# Terminate Cluster
print("Terminating CDH Cluster", file=LOG)
args = []
args.append('/home/ubuntu/cloudera/director-client/bin/cloudera-director')
args.append('terminate')
args.append('/home/ubuntu/cloudera/cluster.conf')
args.append('--lp.terminate.assumeYes=true')

sys.exit(subprocess.Popen(args, stdout=LOG, stderr=subprocess.STDOUT).wait())
