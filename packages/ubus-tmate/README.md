# tmate ubus module

This session uses the /tmp/tmate.sock socket.
If you want to locally connect to the running session you can run `tmate -S /tmp/tmate.sock attach`.

| Path  | Procedure     |  Description                     |
| ----- | ------------- | -------------------------------- |
| tmate | get_session   | Get the current session (if any) |
| tmate | open_session  | Open a new session               |
| tmate | close_session | Close the current session        |

### ubus -v list tmate

```
'tmate' @5df79c49
	"get_session":{"no_params":"Integer"}
	"open_session":{"no_params":"Integer"}
	"close_session":{"no_params":"Integer"}
```
