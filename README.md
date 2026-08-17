# ios-cli-tools

iOS-compatible shell + CLI util bins (`sh`, `ls`, `pwd`, `cat`, etc.).

## Quickstart

```
tar xf prebuilt.tar.gz
```

Will extract a precompiled sysroot to the `sysroot` directory. Binaries are in
`/bin`.

Or, you can use `compile.sh` to build from scratch (described below).

## What this does

This is a tiny bare-bones iOS userspace environment that depends only on
`libSystem.B.dylib`, making it useful for running off a ramdisk (no dyld shared
cache required).

- Prebuilt tools are provided in `prebuilt.tar.gz`.
- `compile.sh` builds `dash` and `coreutils` for iOS, producing the same files
already in `prebuilt.tar.gz`.
- We use `dash` instead of `bash` because it's lighter.
- The `printf` command requires `libiconv.2.dylib` in addition to `libSystem`.

## Build it yourself

Requirements:
- Mac + Xcode with iOS SDK (osxcross not tested)
- GNU Autotools (`autoconf` + `automake`)
- `wget`
- `git`

1. `brew install autoconf automake wget`
2. `./compile.sh`
3. Files will be in `${PWD}/sysroot`

The shell (`dash`) will be installed as `/bin/sh`, rather than `/bin/dash`.

## `prebuilt.tar.gz` Build Environment

macOS 26.6.2 (25G83) virtual machine with Xcode 26.5 (17F42).
