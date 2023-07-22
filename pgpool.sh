#!/bin/bash

pgpool -f ${PGPOOL_PGDATA}/pgpool.conf -F ${PGPOOL_PGDATA}/pcp.conf -m fast stop

rm -rf ${PGDATA}/pool_passwd
rm -rf ${PGDATA}/pool_hba.conf
rm -rf ${PGDATA}/pgpool.conf

touch ${PGDATA}/pool_passwd
touch ${PGDATA}/pool_hba.conf
touch ${PGDATA}/pgpool.conf


cat >> ${PGDATA}/pool_passwd <<EOF
# Kullanıcı adı: postgres, Şifre: postgres
postgres:"postgres"

#sha-256
#a942b37ccfaf5a813b1432caa209a43b9d144e47ad0de1549c289c253e556cd5
#md5
#e8a48653851e28c69d0506508fb27fc5
EOF

cat >> ${PGDATA}/pool_hba.conf <<EOF
local   all    all           trust
host    all    all    all    trust
EOF

cat >> ${PGDATA}/pgpool.conf <<EOF
# ----------------------------
#  pgPool-II configuration file
# ----------------------------
#
# This file consists of lines of the form:
#
#   name = value
#
# Whitespace may be used.  Comments are introduced with "#" anywhere on a line.
# The complete list of parameter names and allowed values can be found in the
# pgPool-II documentation.
#
# This file is read on server startup and when the server receives a SIGHUP
# signal.  If you edit the file on a running system, you have to SIGHUP the
# server for the changes to take effect, or use "pgpool reload".  Some
# parameters, which are marked below, require a server shutdown and restart to
# take effect.
#

backend_clustering_mode = 'streaming_replication'
#------------------------------------------------------------------------------
# CONNECTIONS
#------------------------------------------------------------------------------

# - pgpool Connection Settings -

listen_addresses = '*'
                                   # Host name or IP address to listen on:
                                   # '*' for all, '' for no TCP/IP connections
                                   # (change requires restart)
port = 7000
                                   # Port number
                                   # (change requires restart)
socket_dir = '/tmp'
                                   # Unix domain socket path
                                   # The Debian package defaults to
                                   # /var/run/postgresql
                                   # (change requires restart)


# - pgpool Communication Manager Connection Settings -

pcp_listen_addresses = '*'
                                   # Host name or IP address for pcp process to listen on:
                                   # '*' for all, '' for no TCP/IP connections
                                   # (change requires restart)
pcp_port = 9898
                                   # Port number for pcp
                                   # (change requires restart)
pcp_socket_dir = '/tmp'
                                   # Unix domain socket path for pcp
                                   # The Debian package defaults to
                                   # /var/run/postgresql
                                   # (change requires restart)
#listen_backlog_multiplier = 2
                                   # Set the backlog parameter of listen(2) to
								   # num_init_children * listen_backlog_multiplier.
                                   # (change requires restart)
#serialize_accept = off
                                   # whether to serialize accept() call to avoid thundering herd problem
                                   # (change requires restart)

# - Backend Connection Settings -

backend_hostname0 = 'pg-master'
                                   # Host name or IP address to connect to for backend 0
backend_port0 = 5432
                                   # Port number for backend 0
backend_weight0 = 0
                                   # Weight for backend 0 (only in load balancing mode)
backend_data_directory0 = '/tmp/master/'
                                   # Data directory for backend 0
backend_flag0 = 'ALWAYS_MASTER'
                                   # Controls various backend behavior
                                   # ALLOW_TO_FAILOVER, DISALLOW_TO_FAILOVER or ALWAYS_MASTER
backend_hostname1 = 'pg-slave1'
backend_port1 = 5433
backend_weight1 = 1
backend_data_directory1 = '/tmp/slave1/'
#backend_flag1 = 'ALLOW_TO_FAILOVER'

backend_hostname2 = 'pg-slave2'
backend_port2 = 5434
backend_weight2 = 2
backend_data_directory2 = '/tmp/slave2/'
#backend_flag2 = 'ALLOW_TO_FAILOVER'

# - Authentication -

enable_pool_hba = on
                                   # Use pool_hba.conf for client authentication
pool_passwd = '/opt/pgpool-II/etc/pool_passwd'
                                   # File name of pool_passwd for md5 authentication.
                                   # "" disables pool_passwd.
                                   # (change requires restart)
#authentication_timeout = 60
                                   # Delay in seconds to complete client authentication
                                   # 0 means no timeout.

# - SSL Connections -

ssl = off
                                   # Enable SSL support
                                   # (change requires restart)
#ssl_key = './server.key'
                                   # Path to the SSL private key file
                                   # (change requires restart)
#ssl_cert = './server.cert'
                                   # Path to the SSL public certificate file
                                   # (change requires restart)
#ssl_ca_cert = ''
                                   # Path to a single PEM format file
                                   # containing CA root certificate(s)
                                   # (change requires restart)
#ssl_ca_cert_dir = ''
                                   # Directory containing CA root certificate(s)
                                   # (change requires restart)


#------------------------------------------------------------------------------
# POOLS
#------------------------------------------------------------------------------

# - Concurrent session and pool size -

num_init_children = 5
                                   # Number of concurrent sessions allowed
                                   # (change requires restart)
max_pool = 2
                                   # Number of connection pool caches per connection
                                   # (change requires restart)

# - Life time -

child_life_time = 300
                                   # Pool exits after being idle for this many seconds
child_max_connections = 0
                                   # Pool exits after receiving that many connections
                                   # 0 means no exit
connection_life_time = 0
                                   # Connection to backend closes after being idle for this many seconds
                                   # 0 means no close
client_idle_limit = 0
                                   # Client is disconnected after being idle for that many seconds
                                   # (even inside an explicit transactions!)
                                   # 0 means no disconnection


#------------------------------------------------------------------------------
# LOGS
#------------------------------------------------------------------------------

# - Where to log -

#log_destination = 'stderr'
                                   # Where to log
                                   # Valid values are combinations of stderr,
                                   # and syslog. Default to stderr.

# - What to log -

#log_line_prefix = '%t: pid %p: '   # printf-style string to output at beginning of each log line.

#log_connections = off
                                   # Log connections
#log_hostname = off
                                   # Hostname will be shown in ps status
                                   # and in logs if connections are logged
log_statement = on
                                   # Log all statements
log_per_node_statement = on
                                   # Log all statements
                                   # with node and backend informations
#log_standby_delay = 'if_over_threshold'
                                   # Log standby delay
                                   # Valid values are combinations of always,
                                   # if_over_threshold, none

# - Syslog specific -

#syslog_facility = 'LOCAL0'
                                   # Syslog local facility. Default to LOCAL0
#syslog_ident = 'pgpool'
                                   # Syslog program identification string
                                   # Default to 'pgpool'

# - Debug -

#log_error_verbosity = default          # terse, default, or verbose messages

#client_min_messages = notice           # values in order of decreasing detail:
                                        #   debug5
                                        #   debug4
                                        #   debug3
                                        #   debug2
                                        #   debug1
                                        #   log
                                        #   notice
                                        #   warning
                                        #   error

#log_min_messages = warning             # values in order of decreasing detail:
                                        #   debug5
                                        #   debug4
                                        #   debug3
                                        #   debug2
                                        #   debug1
                                        #   info
                                        #   notice
                                        #   warning
                                        #   error
                                        #   log
                                        #   fatal
                                        #   panic

#------------------------------------------------------------------------------
# FILE LOCATIONS
#------------------------------------------------------------------------------

pid_file_name = 'pgpool.pid'
                                   # PID file name
                                   # Can be specified as relative to the"
                                   # location of pgpool.conf file or
                                   # as an absolute path
                                   # (change requires restart)
logdir = '/tmp'
                                   # Directory of pgPool status file
                                   # (change requires restart)


#------------------------------------------------------------------------------
# CONNECTION POOLING
#------------------------------------------------------------------------------

connection_cache = on
                                   # Activate connection pools
                                   # (change requires restart)

                                   # Semicolon separated list of queries
                                   # to be issued at the end of a session
                                   # The default is for 8.3 and later
reset_query_list = 'ABORT; DISCARD ALL'
                                   # The following one is for 8.2 and before
#reset_query_list = 'ABORT; RESET ALL; SET SESSION AUTHORIZATION DEFAULT'


#------------------------------------------------------------------------------
# REPLICATION MODE
#------------------------------------------------------------------------------

replication_mode = off
                                   # Activate replication mode
                                   # (change requires restart)
replicate_select = off
                                   # Replicate SELECT statements
                                   # when in replication mode
                                   # replicate_select is higher priority than
                                   # load_balance_mode.

insert_lock = off
                                   # Automatically locks a dummy row or a table
                                   # with INSERT statements to keep SERIAL data
                                   # consistency
                                   # Without SERIAL, no lock will be issued
lobj_lock_table = ''
                                   # When rewriting lo_creat command in
                                   # replication mode, specify table name to
                                   # lock

# - Degenerate handling -

replication_stop_on_mismatch = off
                                   # On disagreement with the packet kind
                                   # sent from backend, degenerate the node
                                   # which is most likely "minority"
                                   # If off, just force to exit this session

failover_if_affected_tuples_mismatch = off
                                   # On disagreement with the number of affected
                                   # tuples in UPDATE/DELETE queries, then
                                   # degenerate the node which is most likely
                                   # "minority".
                                   # If off, just abort the transaction to
                                   # keep the consistency


#------------------------------------------------------------------------------
# LOAD BALANCING MODE
#------------------------------------------------------------------------------

load_balance_mode = on
                                   # Activate load balancing mode
                                   # (change requires restart)
ignore_leading_white_space = on
                                   # Ignore leading white spaces of each query
white_function_list = ''
                                   # Comma separated list of function names
                                   # that don't write to database
                                   # Regexp are accepted
black_function_list = 'currval,lastval,nextval,setval'
                                   # Comma separated list of function names
                                   # that write to database
                                   # Regexp are accepted

database_redirect_preference_list = ''
								   # comma separated list of pairs of database and node id.
								   # example: postgres:primary,mydb[0-4]:1,mydb[5-9]:2'
								   # valid for streaming replicaton mode only.

app_name_redirect_preference_list = ''
								   # comma separated list of pairs of app name and node id.
								   # example: 'psql:primary,myapp[0-4]:1,myapp[5-9]:standby'
								   # valid for streaming replicaton mode only.
allow_sql_comments = off
								   # if on, ignore SQL comments when judging if load balance or
								   # query cache is possible.
								   # If off, SQL comments effectively prevent the judgment
								   # (pre 3.4 behavior).

#------------------------------------------------------------------------------
# MASTER/SLAVE MODE
#------------------------------------------------------------------------------

master_slave_mode = on
                                   # Activate master/slave mode
                                   # (change requires restart)
master_slave_sub_mode = 'stream'
                                   # Master/slave sub mode
                                   # Valid values are combinations stream, slony
                                   # or logical. Default is stream.
                                   # (change requires restart)

# - Streaming -

sr_check_period = 0
                                   # Streaming replication check period
                                   # Disabled (0) by default
sr_check_user = 'repuser'
                                   # Streaming replication check user
                                   # This is neccessary even if you disable streaming
                                   # replication delay check by sr_check_period = 0
sr_check_password = 'repuser'
                                   # Password for streaming replication check user
sr_check_database = 'postgres'
                                   # Database name for streaming replication check
#delay_threshold = 10000000
                                   # Threshold before not dispatching query to standby node
                                   # Unit is in bytes
                                   # Disabled (0) by default

# - Special commands -

follow_master_command = ''
                                   # Executes this command after master failover
                                   # Special values:
                                   #   %d = node id
                                   #   %h = host name
                                   #   %p = port number
                                   #   %D = database cluster path
                                   #   %m = new master node id
                                   #   %H = hostname of the new master node
                                   #   %M = old master node id
                                   #   %P = old primary node id
								   #   %r = new master port number
								   #   %R = new master database cluster path
                                   #   %% = '%' character

#------------------------------------------------------------------------------
# HEALTH CHECK GLOBAL PARAMETERS
#------------------------------------------------------------------------------

health_check_period = 10
                                   # Health check period
                                   # Disabled (0) by default
#health_check_timeout = 20
                                   # Health check timeout
                                   # 0 means no timeout
health_check_user = 'repuser'
                                   # Health check user
health_check_password = 'repuser'
                                   # Password for health check user
health_check_database = 'postgres'
                                   # Database name for health check. If '', tries 'postgres' frist, 
#health_check_max_retries = 0
                                   # Maximum number of times to retry a failed health check before giving up.
#health_check_retry_delay = 1
                                   # Amount of time to wait (in seconds) between retries.
#connect_timeout = 10000
                                   # Timeout value in milliseconds before giving up to connect to backend.
								   # Default is 10000 ms (10 second). Flaky network user may want to increase
								   # the value. 0 means no timeout.
								   # Note that this value is not only used for health check,
								   # but also for ordinary conection to backend.

#------------------------------------------------------------------------------
# HEALTH CHECK PER NODE PARAMETERS (OPTIONAL)
#------------------------------------------------------------------------------
#health_check_period0 = 0
#health_check_timeout0 = 20
#health_check_user0 = 'nobody'
#health_check_password0 = ''
#health_check_database0 = ''
#health_check_max_retries0 = 0
#health_check_retry_delay0 = 1
#connect_timeout0 = 10000

#------------------------------------------------------------------------------
# FAILOVER AND FAILBACK
#------------------------------------------------------------------------------

failover_command = ''
                                   # Executes this command at failover
                                   # Special values:
                                   #   %d = node id
                                   #   %h = host name
                                   #   %p = port number
                                   #   %D = database cluster path
                                   #   %m = new master node id
                                   #   %H = hostname of the new master node
                                   #   %M = old master node id
                                   #   %P = old primary node id
								   #   %r = new master port number
								   #   %R = new master database cluster path
                                   #   %% = '%' character
failback_command = ''
                                   # Executes this command at failback.
                                   # Special values:
                                   #   %d = node id
                                   #   %h = host name
                                   #   %p = port number
                                   #   %D = database cluster path
                                   #   %m = new master node id
                                   #   %H = hostname of the new master node
                                   #   %M = old master node id
                                   #   %P = old primary node id
								   #   %r = new master port number
								   #   %R = new master database cluster path
                                   #   %% = '%' character

fail_over_on_backend_error = on
                                   # Initiates failover when reading/writing to the
                                   # backend communication socket fails
                                   # If set to off, pgpool will report an
                                   # error and disconnect the session.

search_primary_node_timeout = 300
                                   # Timeout in seconds to search for the
                                   # primary node when a failover occurs.
                                   # 0 means no timeout, keep searching
                                   # for a primary node forever.

#------------------------------------------------------------------------------
# ONLINE RECOVERY
#------------------------------------------------------------------------------

#recovery_user = 'nobody'
                                   # Online recovery user
#recovery_password = ''
                                   # Online recovery password
#recovery_1st_stage_command = ''
                                   # Executes a command in first stage
#recovery_2nd_stage_command = ''
                                   # Executes a command in second stage
#recovery_timeout = 90
                                   # Timeout in seconds to wait for the
                                   # recovering node's postmaster to start up
                                   # 0 means no wait
#client_idle_limit_in_recovery = 0
                                   # Client is disconnected after being idle
                                   # for that many seconds in the second stage
                                   # of online recovery
                                   # 0 means no disconnection
                                   # -1 means immediate disconnection


#------------------------------------------------------------------------------
# WATCHDOG
#------------------------------------------------------------------------------

# - Enabling -

use_watchdog = off
                                    # Activates watchdog
                                    # (change requires restart)

# -Connection to up stream servers -

trusted_servers = ''
                                    # trusted server list which are used
                                    # to confirm network connection
                                    # (hostA,hostB,hostC,...)
                                    # (change requires restart)
ping_path = '/bin'
                                    # ping command path
                                    # (change requires restart)

# - Watchdog communication Settings -

wd_hostname = ''
                                    # Host name or IP address of this watchdog
                                    # (change requires restart)
wd_port = 9000
                                    # port number for watchdog service
                                    # (change requires restart)
wd_priority = 1
									# priority of this watchdog in leader election
									# (change requires restart)

wd_authkey = ''
                                    # Authentication key for watchdog communication
                                    # (change requires restart)

wd_ipc_socket_dir = '/tmp'
									# Unix domain socket path for watchdog IPC socket
									# The Debian package defaults to
									# /var/run/postgresql
									# (change requires restart)


# - Virtual IP control Setting -

delegate_IP = ''
                                    # delegate IP address
                                    # If this is empty, virtual IP never bring up. 
                                    # (change requires restart)
if_cmd_path = '/sbin'
                                    # path to the directory where if_up/down_cmd exists 
                                    # (change requires restart)
if_up_cmd = 'ip addr add $_IP_$/24 dev eth0 label eth0:0'
                                    # startup delegate IP command
                                    # (change requires restart)
if_down_cmd = 'ip addr del $_IP_$/24 dev eth0'
                                    # shutdown delegate IP command
                                    # (change requires restart)
arping_path = '/usr/sbin'
                                    # arping command path
                                    # (change requires restart)
arping_cmd = 'arping -U $_IP_$ -w 1'
                                    # arping command
                                    # (change requires restart)

# - Behaivor on escalation Setting -

clear_memqcache_on_escalation = on
                                    # Clear all the query cache on shared memory
                                    # when standby pgpool escalate to active pgpool
                                    # (= virtual IP holder).
                                    # This should be off if client connects to pgpool
                                    # not using virtual IP.
                                    # (change requires restart)
wd_escalation_command = ''
                                    # Executes this command at escalation on new active pgpool.
                                    # (change requires restart)
wd_de_escalation_command = ''
									# Executes this command when master pgpool resigns from being master.
									# (change requires restart)

# - Watchdog consensus settings for failover -

failover_when_quorum_exists = on
									# Only perform backend node failover
									# when the watchdog cluster holds the quorum
									# (change requires restart)

failover_require_consensus = on
									# Perform failover when majority of Pgpool-II nodes
									# aggrees on the backend node status change
									# (change requires restart)

allow_multiple_failover_requests_from_node = off
									# A Pgpool-II node can cast multiple votes
									# for building the consensus on failover
									# (change requires restart)


# - Lifecheck Setting -

# -- common --

wd_monitoring_interfaces_list = ''  # Comma separated list of interfaces names to monitor.
									# if any interface from the list is active the watchdog will
									# consider the network is fine
									# 'any' to enable monitoring on all interfaces except loopback
									# '' to disable monitoring
									# (change requires restart)

wd_lifecheck_method = 'heartbeat'
                                    # Method of watchdog lifecheck ('heartbeat' or 'query' or 'external')
                                    # (change requires restart)
wd_interval = 10
                                    # lifecheck interval (sec) > 0
                                    # (change requires restart)

# -- heartbeat mode --

wd_heartbeat_port = 9694
                                    # Port number for receiving heartbeat signal
                                    # (change requires restart)
wd_heartbeat_keepalive = 2
                                    # Interval time of sending heartbeat signal (sec)
                                    # (change requires restart)
wd_heartbeat_deadtime = 30
                                    # Deadtime interval for heartbeat signal (sec)
                                    # (change requires restart)
heartbeat_destination0 = 'host0_ip1'
                                    # Host name or IP address of destination 0
                                    # for sending heartbeat signal.
                                    # (change requires restart)
heartbeat_destination_port0 = 9694 
                                    # Port number of destination 0 for sending
                                    # heartbeat signal. Usually this is the
                                    # same as wd_heartbeat_port.
                                    # (change requires restart)
heartbeat_device0 = ''
                                    # Name of NIC device (such like 'eth0')
                                    # used for sending/receiving heartbeat
                                    # signal to/from destination 0.
                                    # This works only when this is not empty
                                    # and pgpool has root privilege.
                                    # (change requires restart)

#heartbeat_destination1 = 'host0_ip2'
#heartbeat_destination_port1 = 9694
#heartbeat_device1 = ''

# -- query mode --

wd_life_point = 3
                                    # lifecheck retry times
                                    # (change requires restart)
wd_lifecheck_query = 'SELECT 1'
                                    # lifecheck query to pgpool from watchdog
                                    # (change requires restart)
wd_lifecheck_dbname = 'template1'
                                    # Database name connected for lifecheck
                                    # (change requires restart)
wd_lifecheck_user = 'nobody'
                                    # watchdog user monitoring pgpools in lifecheck
                                    # (change requires restart)
wd_lifecheck_password = ''
                                    # Password for watchdog user in lifecheck
                                    # (change requires restart)

# - Other pgpool Connection Settings -

#other_pgpool_hostname0 = 'host0'
                                    # Host name or IP address to connect to for other pgpool 0
                                    # (change requires restart)
#other_pgpool_port0 = 5432
                                    # Port number for other pgpool 0
                                    # (change requires restart)
#other_wd_port0 = 9000
                                    # Port number for other watchdog 0
                                    # (change requires restart)
#other_pgpool_hostname1 = 'host1'
#other_pgpool_port1 = 5432
#other_wd_port1 = 9000


#------------------------------------------------------------------------------
# OTHERS
#------------------------------------------------------------------------------
relcache_expire = 0
                                   # Life time of relation cache in seconds.
                                   # 0 means no cache expiration(the default).
                                   # The relation cache is used for cache the
                                   # query result against PostgreSQL system
                                   # catalog to obtain various information
                                   # including table structures or if it's a
                                   # temporary table or not. The cache is
                                   # maintained in a pgpool child local memory
                                   # and being kept as long as it survives.
                                   # If someone modify the table by using
                                   # ALTER TABLE or some such, the relcache is
                                   # not consistent anymore.
                                   # For this purpose, cache_expiration
                                   # controls the life time of the cache.
relcache_size = 256
                                   # Number of relation cache
                                   # entry. If you see frequently:
								   # "pool_search_relcache: cache replacement happend"
								   # in the pgpool log, you might want to increate this number.

check_temp_table = on
                                   # If on, enable temporary table check in SELECT statements.
                                   # This initiates queries against system catalog of primary/master
								   # thus increases load of master.
								   # If you are absolutely sure that your system never uses temporary tables
								   # and you want to save access to primary/master, you could turn this off.
								   # Default is on.

check_unlogged_table = on
                                   # If on, enable unlogged table check in SELECT statements.
                                   # This initiates queries against system catalog of primary/master
                                   # thus increases load of master.
                                   # If you are absolutely sure that your system never uses unlogged tables
                                   # and you want to save access to primary/master, you could turn this off.
                                   # Default is on.

#------------------------------------------------------------------------------
# IN MEMORY QUERY MEMORY CACHE
#------------------------------------------------------------------------------
memory_cache_enabled = off
								   # If on, use the memory cache functionality, off by default
memqcache_method = 'shmem'
								   # Cache storage method. either 'shmem'(shared memory) or
								   # 'memcached'. 'shmem' by default
                                   # (change requires restart)
memqcache_memcached_host = 'localhost'
								   # Memcached host name or IP address. Mandatory if
								   # memqcache_method = 'memcached'.
								   # Defaults to localhost.
                                   # (change requires restart)
memqcache_memcached_port = 11211
								   # Memcached port number. Mondatory if memqcache_method = 'memcached'.
								   # Defaults to 11211.
                                   # (change requires restart)
memqcache_total_size = 67108864
								   # Total memory size in bytes for storing memory cache.
								   # Mandatory if memqcache_method = 'shmem'.
								   # Defaults to 64MB.
                                   # (change requires restart)
memqcache_max_num_cache = 1000000
								   # Total number of cache entries. Mandatory
								   # if memqcache_method = 'shmem'.
								   # Each cache entry consumes 48 bytes on shared memory.
								   # Defaults to 1,000,000(45.8MB).
                                   # (change requires restart)
memqcache_expire = 0
								   # Memory cache entry life time specified in seconds.
								   # 0 means infinite life time. 0 by default.
                                   # (change requires restart)
memqcache_auto_cache_invalidation = on
								   # If on, invalidation of query cache is triggered by corresponding
								   # DDL/DML/DCL(and memqcache_expire).  If off, it is only triggered
								   # by memqcache_expire.  on by default.
                                   # (change requires restart)
memqcache_maxcache = 409600
								   # Maximum SELECT result size in bytes.
								   # Must be smaller than memqcache_cache_block_size. Defaults to 400KB.
                                   # (change requires restart)
memqcache_cache_block_size = 1048576
								   # Cache block size in bytes. Mandatory if memqcache_method = 'shmem'.
								   # Defaults to 1MB.
                                   # (change requires restart)
memqcache_oiddir = '/var/log/pgpool/oiddir'
				   				   # Temporary work directory to record table oids
                                   # (change requires restart)
white_memqcache_table_list = ''
                                   # Comma separated list of table names to memcache
                                   # that don't write to database
                                   # Regexp are accepted
black_memqcache_table_list = ''
##aaa
EOF

pgpool -f ${PGPOOL_PGDATA}/pgpool.conf -F ${PGPOOL_PGDATA}/pcp.conf