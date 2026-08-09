#!/bin/sh

set -e

uv run shfmt -d .

uv run stylua -c .