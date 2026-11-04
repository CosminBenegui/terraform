# Ticket REQ-2455 — Hardware and software recommendation

Company: Harborline Logistics
Time box: 15 minutes, spoken out loud
No break script. Write your answer in `ANSWER.md` in this directory.

## The ask

The operations manager wants a recommendation before Friday's purchase meeting. You may buy one thing, not both:

- Option A. A second server, similar to the current one (about 2 vCPU, 16 GB RAM, one disk).
- Option B. Upgrade the current host to 8 vCPU, 32 GB RAM, and 200 GB disk. No second server.

You also choose the software support model: distro packages only, or a commercial MySQL subscription and a commercial web server. Say which you would buy and what you would ask the vendor before the PO is signed.

## What is running today

One Ubuntu 24.04 virtual machine.

- 2 vCPU, load average 3 to 4 during the lunch hour.
- 16 GB RAM. MySQL is the largest process.
- 80 GB disk, 85% full. The database is about 12 GB and grows about 1 GB a month. Nightly `mysqldump` makes the intranet slow while it runs.
- Apache, PHP, and MySQL on the same host. About 40 office users.
- No staging environment. Patches are applied on the only copy of the system.
- Two system administrators. One of you is on call.

## What "a good answer" is

`ANSWER.md` with these headings:

- Options
- Recommendation
- Risks
- Questions for the vendor

Pick one purchase. Defend it with the numbers above. Name what you would not buy, and why. Include backup, patching, and a place to test changes. The interview is the conversation, so say it as if the manager is in the room.

When you are done, bring the answer back and we will review it the way a hiring manager would.
