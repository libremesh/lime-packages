# cotonete [beta]

cotonete is a daemon that monitors the deafness of radios and reacts instantly to it, working around the issue.

## issue

Every now and then, certain wifi radios manifest an issue that is called deaf radio: the radio has good link, has associated links, but no traffic goes through it.

## solution

cotonete monitors the traffic over the wireless links by doing a link local ping6 to all the associated peers. If the ping doesn't increment the transmitted bandwidth announced by the statistics of the interface, then the radio is deaf and needs to be restarted.
