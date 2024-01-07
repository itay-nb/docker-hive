#!/bin/bash 

_grep()
{
  [[ -t 1 ]] && use_color="--color=always"
  grep $use_color -E "|$@"
}

_engine="$1"
engine=${_engine:=trino}

if [ "$engine" = "trino" ] ; then
  CMD=trino
  COORDINATOR_PORT=8090
  WORKER_PORT=8093
else
  CMD=presto-cli
  COORDINATOR_PORT=8080
  WORKER_PORT=8083
fi

run()
{
  tee /dev/tty | \
    docker-compose exec -T $engine-coordinator bash -c \
    "$CMD --catalog hive --schema tpch1g --server=localhost:$COORDINATOR_PORT"
} 

# BEFORE RUNNING: run on Hive DDL tpch 1G (see tpch-hive-shema.sql)

# CASE: dynamic filter works in broadcast-join

cat <<EOF | 
  explain analyze select count(*) from customer, nation where c_nationkey = n_nationkey and n_name = 'PERU';
EOF
  run | _grep "Dynamic filters:|- df_.*"

# CASE: dynamic filter DOES NOT work when the filter is too big

cat <<EOF | 
  explain analyze select count(*) from lineitem, orders where l_orderkey = o_orderkey and o_orderstatus = 'P';
EOF
  run | _grep "Dynamic filters:|- df_.*"


# CASE: partition-join: works on trino but not on presto
# Dynamic filter values are shuffled across nodes (see https://github.com/trinodb/trino/issues/3972)

tmpdir="$(mktemp -d /tmp/$(basename $0)-XXX)"
sudo tcpflow -o "$tmpdir" -i any -e http port $WORKER_PORT &
pid=$!

cat <<EOF | 
  explain analyze select count(*) from lineitem, orders where l_orderkey = o_orderkey and o_clerk = 'Clerk#000000064';
EOF
  run | _grep "Dynamic filters:|- df_.*"

sudo kill -INT $pid
sleep 1
sudo kill -9 $pid
# the coordinator sends to the worker POST /v1/task/<taskid> with a body that contains 'dynamicFilterDomains'
grep --no-filename --only-matching "^{.*dynamicFilterDomains.*}$" "$tmpdir"/* | jq .dynamicFilterDomains

# CASE: dynamic filter + partition pruning shows reduced scanned rows

# without DF
cat <<EOF | 
  set session enable_dynamic_filtering=false;
  explain analyze select count(*) from supplier, nation where s_nationkey = n_nationkey and n_name = 'RUSSIA';
EOF
  run | _grep "[ │]*Input:.*rows|.*hive:tpch1g:[^ ]*"

# with DF
cat <<EOF | 
  set session enable_dynamic_filtering=true;
  explain analyze select count(*) from supplier, nation where s_nationkey = n_nationkey and n_name = 'RUSSIA';
EOF
  run | _grep "^[ │]*Input:.*rows|.*hive:tpch1g:[^ ]*"

