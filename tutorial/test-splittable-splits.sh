#!/bin/bash
_engine="presto"
script_dir="$(dirname $(realpath $0))"
. $script_dir/test-utils.sh

# CASE: regular invocation results in a single big split
sniff_start
run_with_grep \
  "select * from lineitem where l_shipdate = '1998-01-23' and l_comment = 'itay';" \
  "^Splits:"
sniff_stop
grep -h fileSplit $tmpdir/*| dump_splits



# CASE: reducing hive.max_initial_split_size causes the single split to be splitted into many small splits
sniff_start
run_with_grep \
  "set session hive.max_initial_split_size='1024B'; 
  select * from lineitem where l_shipdate = '1998-01-23' and l_comment = 'itay';" \
  "^Splits:"
sniff_stop
echo "Worker0:"
grep -h fileSplit $tmpdir/*08083 | dump_splits
echo "Worker1:"
grep -h fileSplit $tmpdir/*08084 | dump_splits
