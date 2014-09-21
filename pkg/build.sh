#!/bin/bash

basedir=$(dirname $0)/../
workdir=.

# Get version details
[ ! -f "$basedir/.VERSION.mk" ] && make -C $basedir .VERSION.mk
. $basedir/.VERSION.mk

if [ "$#" -ne 2 ] ; then
  echo "Usage: $0 os release"
  echo
  echo "Example: $0 ubuntu 12.10"
fi

silent() {
  "$@" > /dev/null 2>&1
}
log() {
  echo "$@" >&2
}

os=$1
osver=$2

_fpm() {
  target=$1
  fpm -s dir -n logstash-kafka \
    -a noarch --url "https://github.com/joekiller/logstash-kafka.git" \
    --description "Logstash Kafka" \
    --vendor "na" \
    --license "Apache 2.0" \
    "$@"
}

case $os in
  centos|fedora|redhat|sl)
        _fpm -s dir -t rpm -n "logstash-kafka" -a all -v 1.2.1 --prefix /opt/logstash lib/ vendor/
    ;;
  ubuntu|debian)
    if ! echo $RELEASE | grep -q '\.(dev\|rc.*)'; then
      # This is a dev or RC version... So change the upstream version
      # example: 1.2.2.dev => 1.2.2~dev
      # This ensures a clean upgrade path.
      RELEASE="$(echo $RELEASE | sed 's/\.\(dev\|rc.*\)/~\1/')"
    fi

    _fpm -t deb --deb-user root --deb-group root \
      --iteration "1-$REVISION" --deb-ignore-iteration-in-dependencies \
      -d "logstash = $RELEASE" -v "$RELEASE" \
      -f -C $workdir/tarball --prefix /opt/logstash $(cat $workdir/files)
    ;;
esac
