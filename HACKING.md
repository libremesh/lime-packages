

## Remote debugging Lua code mini-howto

ZeroBrane Studio, an OpenSource Lua IDE https://studio.zerobrane.com/, has awesome remote debugging
capabilities https://studio.zerobrane.com/doc-remote-debugging

If you have the code you want to debug, you just need to add the following line

```lua
require('mobdebug').start("10.5.5.140")
```
and it will connect to your computer (being `10.5.5.140` your computer) and will allow you to go step
by step, dump variables, etc.

For this to work you need to install two packages on the router: luasocket and lua-mobdebug

```
root@LiMe-abcd00:/# opkg update
root@LiMe-abcd00:/# opkg install luasocket lua-mobdebug
```

