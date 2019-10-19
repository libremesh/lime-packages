## bandwidth-test

**bandwidth-test** is a tool for estimating the maximum available download bandwidth from the internet. In order to work even on restricted connections, it just uses port 80 with HTTP connections. It has be designed for working also on a common Linux machine (requires lua, wget and pv), not only on OpenWrt.

By default, a few large files are downloaded during 20 seconds. After this timeout, the download gets interrupted and the speed estimated. The failed downloads gets ignored and more files gets downloaded until having 5 successful tests. At this point the outputted value is the median of the 5 results.

```

root@ql-anaymarcos:~# bandwidth-test --help
Usage: /bin/bandwidth-test [SINGLE_TEST_DURATION] [NONZERO_TESTS] [SERVERS_LIST]
Measures maximum available download bandwidth downloading a list of files from the internet.
The measurement will take approximately SINGLE_TEST_DURATION*NONZERO_TESTS seconds.
Download of each URL is attempted at most one time: multiple URLs should be provided.
Speed in B/s is printed to STDOUT.

  SINGLE_TEST_DURATION  fixed duration of each download process,
                          if missing reads from UCI status-report (default 20)
  NONZERO_TESTS         minimum number of successful downloads,
                          if missing reads from UCI status-report (default 5)
  SERVERS_LIST          a space-separated list of files' URLs to download,
                          preferably large files.
                          When running with Busybox wget, has to include http://
                          and will likely fail with https://
                          if missing reads from UCI status-report
                          (defaults to a list of 10 MB files on various domains)

```

This software was developed during the course of [GSoC 2019](https://blog.freifunk.net/2019/08/18/load-correlated-distributed-bandwidth-analysis-for-libremesh-networks-4-conclusions-and-further-work/).
