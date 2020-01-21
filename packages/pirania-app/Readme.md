## pirania-app

This package adds some necessary functionality for the Pirania interface in LiMe App.

### Governance

The `/etc/pirania/governance.json` file stores information that's useful for communal managment of Internet access.


The most important bit is `community.payday`, which is used for calculating when to create and renew member vouchers.


The other fields are intended to be used to help keep track of financial information, for more transperency and distribution or reponsabilities within the community.

In the future other numeral fields are intended to be used to assist on financial calculations.

### Content

The `/etc/pirania/content.json` files stores styling and content information for the captive-portal pages.

### get_clients

Returns ip and mac information for clients connected to the station.

### Todo:

Both content and governance files should be distributed through `shared-state`.