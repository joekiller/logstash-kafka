#!/usr/bin/env bash

[ -z "$1" ] && echo "you must profile a config file path" && exit 1

for file in vendor/jar/*.jar;
do
  CLASSPATH=$CLASSPATH:$file
done

for file in build/monolith/*.jar;
do
  CLASSPATH=$CLASSPATH:$file
done
java -cp $CLASSPATH logstash.runner agent -f $1 -vv