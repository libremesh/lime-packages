# check-date-http

NTP daemon shipped with busybox is not capable to gracefully handle cases of extreme time skew, that are common enough in some community networks, this package detect that situation and restart sysntpd and/or reset the date depending on the configuration.

Check local time against a list of HTTP(s) services, if the time skew is more then 15 minutes, restart sysntpd to force time syncronization, or reset trought date command depending on configuration.

Remember to set your time zone in /etc/TZ. For argentina "echo 'UTC3' > /etc/TZ"
will do the job

## Configurations
You can change the behavior and the list of servers in ```/etc/config/check-date```

