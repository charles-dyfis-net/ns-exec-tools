ns-exec-tools
=============

### Execline-style tools for using Linux restricted-namespace functionality

# Introduction

One of the useful things to come out of LXC is support for namespaces -- allowing a process to have its own mount table, its own concept of the current hostname, its own (presumably limited) view of the process tree or the set of available NICs, etc.

For building an environment that can be attached to there are tools like docker or lxc. If you just want to drop access to some NICs or filesystems from the current namespace for the duration of a single process's invocation, however, the tools provided by util-linux or lxc aren't ideal; that's where ns-exec-tools comes in.

# Usage

## with-bind-mount

Let's say you want to start a process with a conventional view of your filesystem -- *except for* a specific configuration file with a hardcoded name (on Linux, `/etc/resolv.conf` is an example of such). For that, you can use `with-bind-mount`:

    with-bind-mount --if-exists /etc/resolv.conf-foo /etc/resolv.conf -- runuser -u foouser foodaemon

If `--if-exists` is not given, the nonexistance of any of the two arguments will be a fatal error; if it is, a warning is printed to stderr and execution continues.

## without-mounts

Let's say you have a daemon that could operate even in the face of partial network outage, but gets hung up when a network filesystem it *shouldn't* have any dependency on is running. You can use `without-mounts` to remove that filesystem from its view of the world -- thus reducing both security and performance vulnerability.

    # mode 1: --fs-type=*
    unshare --mount -- \
      without-mounts --fs-type=nfs -- \
      runuser -u foo -- \
      foodaemon

    # mode 2: listed filesystems or subtrees
    unshare --mount -- \
      without-mounts --except --subtree=/proc --subtree=/dev /bin /usr/lib /etc /var/lib/foo -- \
      runuser -u foo -- \
      foodaemon

In the "mode 2" example here, we used the `--except` flag to invert the match, unmounting all filesystems *except* those which are mounted under a directory passed with `--subtree` or which contain a file directly listed before the `--` argument after which all arguments are used to define the command to call in the new namespace.

Note that `--fs-type` cannot be directly mixed with either `--subtree=*` or an explicit list of locations; only one mode or the other can be used. However, invocations of different types can be chained: A `without-mounts --fstype=nfs` can then call `--without-mounts --except` with a list of paths.

Note: `--subtree` only makes a particular lot of sense in `--except` mode, as `without-mounts` always acts recursively downward: `without-mounts /usr/local` will implicitly unmount `/usr/local/share`, but `without-mounts --except /usr/local` won't protect `/usr/local/share` (as opposed to `without-mounts --except --subtree=/usr/local`, which will).

## without-nics

Provides equivalent operation to `without-mounts`, but for Ethernet devices.

    without-nics --except eth1 eth2 -- foo arg1 arg2 ...

...will run `foo` with any NIC which is not `lo`, `eth1`, or `eth2` invisible.

# Dependencies

Runtime dependencies include:

- bash 4.x
- A linux kernel with the relevant features. Obviously.
- util-linux 2.27 or newer, for `unshare`
- `lxc` (for `without-nics`, which uses `lxc-unshare`).
  The util-linux `unshare`, like iproute2, uses `unshare(CLONE_NEWNET)`, which creates a new network namespace which contains only `lo`. By contrast, `lxc-unshare` uses `clone(CLONE_NEWNET)` to create a new namespace which contains all of the parent's devices, from which undesired devices can then be removed. This latter behavior is more approprate for the tools at hand.

Any rewrite to a non-bash language will probably be in Go. It's also probably only going to happen if my employer decides to pay for it; as long as this is a personal project, I'm going the perverse route. :)

# Contributing

Please make sure all code runs clean with [shellcheck](http://www.shellcheck.net/).
