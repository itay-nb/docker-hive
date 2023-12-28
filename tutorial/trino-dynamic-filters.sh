#!/bin/bash -x

# BEFORE RUNNING: run on Hive DDL tpch 1G (see tpch-hive-shema.sql)

# dynamic filter works in broadcast-join

cat <<EOF | 
  explain analyze select count(*) from customer, nation where c_nationkey = n_nationkey and n_name = 'PERU';
EOF
docker-compose exec -T trino-coordinator bash -c \
  'trino --catalog hive --schema tpch1g --server=localhost:8090' | \
  grep --color=always -C9999 "Dynamic filters:\|- df_.*"

# dynamic filter DOES NOT work when the filter is too big

cat <<EOF | 
  explain analyze select count(*) from lineitem, orders where l_orderkey = o_orderkey and o_orderstatus = 'P';
EOF
docker-compose exec -T trino-coordinator bash -c \
  'trino --catalog hive --schema tpch1g --server=localhost:8090' | \
  grep --color=always -C9999 "Dynamic filters:\|- df_.*"

# dynamic filter works in Trino even in partition-join across nodes (see https://github.com/trinodb/trino/issues/3972)

tmpdir="$(mktemp -d /tmp/$(basename $0)-XXX)"
sudo tcpflow -o "$tmpdir" -i any -e http port 8093 &

cat <<EOF | 
  explain analyze select count(*) from lineitem, orders where l_orderkey = o_orderkey and o_clerk = 'Clerk#000000064';
EOF
docker-compose exec -T trino-coordinator bash -c \
  'trino --catalog hive --schema tpch1g --server=localhost:8090' | \
  grep --color=always -C9999 "Dynamic filters:\|- df_.*"

kill %%
# the coordinator sends to the worker POST /v1/task/<taskid> with a body that contains 'dynamicFilterDomains'
grep -l dynamicFilterDomains "$tmpdir/*" | xargs -n1 jq .dynamicFilterDomains
