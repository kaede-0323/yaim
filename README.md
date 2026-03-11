# yaim
yaim (Yet Another IMage maker) is a utility that takes screenshots of your desktop.
It is designed to overcome shortcomings of maim and performs better in several ways.

## Features
- Takes screenshots of your desktop and saves them in PNG format or as raw output. Can also stream to stdout.
- Supports capturing predetermined regions or windows.
- Allows interactive selection of a region or window before taking a screenshot.

## How to Build

Install [Nim](https://nim-lang.org/) & [Nimble](https://nim-lang.github.io/nimble/index.html)

Install [libX11](https://www.x.org/releases/current/doc/libX11/libX11/libX11.html)

```sh
TMP=$(mktemp -d)
git clone https://github.com/kaede-0323/yaim.git "$TMP"
cd "$TMP"
nimble build
sudo mv ./yaim /usr/local/bin/
cd ~
rm -rf "$TMP"
```
