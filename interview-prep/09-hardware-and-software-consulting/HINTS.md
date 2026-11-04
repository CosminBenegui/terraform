# Hints

## Level 1

Separate "the machine is slow at lunch" from "the disk is 85% full" and from "there is nowhere to test a patch". Those are three different risks. A bigger CPU does not fix all three.

## Level 2

Say what happens to the business if this single host dies, and what happens during the nightly dump. Then decide whether a second server is a staging host, a database host, or a backup target. One box cannot be all three.

## Level 3 — a defensible recommendation, not the only one

A strong answer upgrades disk and split of roles before it buys commercial web-server licenses. The urgent constraint is capacity and a single copy of the data, not the Apache brand. Commercial MySQL support is optional at 12 GB and two admins; say what incident would make you buy it. Questions for the vendor: restore time from their backup product, whether the subscription includes Ubuntu security updates or only their packages, and the lead time for the disk upgrade versus a second host. If you choose the second server instead, say which role moves off the current VM and how you will test patches on the other one.
