## bandwidth-test

**bandwidth-test** is a tool for estimating the maximum available download bandwidth from the internet. In order to work even on restricted connections, it just uses port 80 with HTTP connections. It has be designed for working also on a common Linux machine (requires lua, wget and pv), not only on OpenWrt.

By default, a few large files are downloaded during 20 seconds. After this timeout, the download gets interrupted and the speed estimated. The failed downloads gets ignored and more files gets downloaded until having 5 successful tests. At this point the outputted value is the median of the 5 results.

This software was developed during the course of [GSoC 2019](https://blog.freifunk.net/2019/08/18/load-correlated-distributed-bandwidth-analysis-for-libremesh-networks-4-conclusions-and-further-work/).