# shell helper functions for LibreMesh

unique_append() {
	[ -f "$2" ] && grep -qF "$1" "$2" || echo "$1" >> "$2"
}
