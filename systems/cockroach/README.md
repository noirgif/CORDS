# How to run

Lessons learned:

## Version

Use CrDB [beta-20160714](https://www.cockroachlabs.com/docs/releases/beta-20160714.html)

Newest version(v19.2.1 as of now) differs too much in terms of insecure mode, startup arguments, and shutdown behavior, as far as I know.

## Configuration

Nothing needed.

## Run tests

Fixed a problem that the read & update workloads uses one of the mountpoints as logging directory.

- real problem: the workload in cockroach accepts a different array of arguments than the CORDS provide