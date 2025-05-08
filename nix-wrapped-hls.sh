#!/bin/sh
cd "$(dirname "$0")"
exec nix develop --command haskell-language-server-wrapper "$@"