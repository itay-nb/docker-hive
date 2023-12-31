#!/bin/bash

# BEFORE RUNNING: run on Hive DDL tpch 1G (see tpch-hive-shema.sql)

_grep()
{
  [[ -t 1 ]] && use_color="--color=always"
  grep $use_color -E "|$@"
}

engine=${_engine:=presto}

if [ "$engine" = "trino" ] ; then
  CMD=trino
  COORDINATOR_PORT=8090
  WORKER_PORT=8093
else
  CMD=presto-cli
  COORDINATOR_PORT=8080
  WORKER_PORT="(8083 or 8084)" # for some reason presto prefers to send the single split in the first case to worker1 instead of worker0
fi

run()
{
  echo "$1" | docker-compose exec -T $engine-coordinator bash -c \
    "$CMD --catalog hive --schema tpch1g --server=localhost:$COORDINATOR_PORT"
} 

run_with_grep()
{
    run "$1" | _grep "$2"
}
tmpdir="" 
sniff_start()
{
  tmpdir="$(mktemp -d /tmp/$(basename $0)-XXX)"
  sudo tcpflow -o "$tmpdir" -i any -e http port $WORKER_PORT &
}

sniff_stop()
{
  sleep 1
  kill %%
}

dump_splits()
{
  while read l ; do echo $l | jq '.sources[] | .splits | sort_by(.split.connectorSplit.fileSplit.start) | .[] | .split.connectorSplit.fileSplit | .path+","+(.start|tostring)+":"+(.length|tostring)'; done
}

