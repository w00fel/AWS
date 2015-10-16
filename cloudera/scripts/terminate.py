#!/usr/bin/env python

import subprocess
import boto
import sys

from boto.route53.record import ResourceRecordSets
from boto.route53.exception import DNSServerError

PUBLIC_ZONE_ID = "{{publicZone}}"
PRIVATE_ZONE_ID = "{{privateZone}}"

LOG = open('/home/ubuntu/cloudera/terminate.log', 'a')

# Delete DNS Records
print >> LOG, "Deleting DNS Records\n"
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
    print >> LOG, "Error Deleting DNS Records\n"

# Terminate Cluster
print >> LOG, "Terminating CDH Cluster\n"
args = []
args.append('/home/ubuntu/cloudera/director-client/bin/cloudera-director')
args.append('terminate-remote')
args.append('/home/ubuntu/cloudera/aws.cluster.conf')
args.append('--lp.remote.username=admin')
args.append('--lp.remote.password=admin')
args.append('--lp.remote.hostAndPort=127.0.0.1:7189')
args.append('--lp.remote.terminate.assumeYes=true')

subprocess.Popen(args, stdout=LOG, stderr=subprocess.STDOUT).wait()

print '{ "ControllerAction" : "terminated" }'
sys.exit(0)
