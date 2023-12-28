CREATE SCHEMA IF NOT EXISTS tpch${hiveconf:sf};
USE tpch${hiveconf:sf};

drop table if exists customer;
drop table if exists supplier;
drop table if exists lineitem;
drop table if exists orders;
drop table if exists nation;
drop table if exists part;
drop table if exists partsupp;
drop table if exists region;


create external table customer (
    c_custkey bigint,
    c_name string,
    c_address string,
    c_nationkey INTEGER,
    c_phone string,
    c_acctbal decimal(12,2),
    c_comment string
)
partitioned by (`c_mktsegment` string)
stored as parquet
location 'file:///nb-datasets/tpch/${hiveconf:sf}/customer';

msck repair table customer;


create external table supplier (
    s_suppkey BIGINT,
    s_name string,
    s_address string,
    s_phone string,
    s_acctbal decimal(12,2),
    s_comment string
)
partitioned by (s_nationkey INTEGER)
stored as parquet
location 'file:///nb-datasets/tpch/${hiveconf:sf}/supplier';

msck repair table supplier;



create external table lineitem (
    l_orderkey bigint,
    l_partkey bigint,
    l_suppkey bigint,
    l_linenumber bigint,
    l_quantity decimal(12,2),
    l_extendedprice decimal(12,2),
    l_discount decimal(12,2),
    l_tax decimal(12,2),
    l_returnflag string,
    l_linestatus string,
    l_commitdate date,
    l_receiptdate date,
    l_shipinstruct string,
    l_shipmode string,
    l_comment string
)
partitioned by (`l_shipdate` string)
stored as parquet
location 'file:///nb-datasets/tpch/${hiveconf:sf}/lineitem';

msck repair table lineitem;



create external table nation (
    n_nationkey INTEGER,
    n_name string,
    n_regionkey INTEGER,
    n_comment string
)
stored as parquet
location 'file:///nb-datasets/tpch/${hiveconf:sf}/nation';


create external table orders (
    o_orderkey bigint,
    o_custkey bigint,
    o_orderstatus string,
    o_totalprice decimal(12,2),
    o_orderpriority string,
    o_clerk string,
    o_shippriority INTEGER,
    o_comment string
)
partitioned by (`o_orderdate` string)
stored as parquet
location 'file:///nb-datasets/tpch/${hiveconf:sf}/orders';

msck repair table orders;



create external table part (
    p_partkey bigint,
    p_name string,
    p_mfgr string,
    p_brand string,
    p_size INTEGER,
    p_container string,
    p_retailprice decimal(12,2),
    p_comment string
)
partitioned by (`p_type` string)
stored as parquet
location 'file:///nb-datasets/tpch/${hiveconf:sf}/part';

msck repair table part;



create external table partsupp (
    ps_partkey bigint,
    ps_suppkey bigint,
    ps_availqty INTEGER,
    ps_supplycost decimal(12,2),
    p_comment string
)
stored as parquet
location 'file:///nb-datasets/tpch/${hiveconf:sf}/partsupp';



create external table region (
    r_regionkey INTEGER,
    r_name string,
    r_comment string
)
stored as parquet
location 'file:///nb-datasets/tpch/${hiveconf:sf}/region';



