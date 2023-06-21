#!/bin/bash

# MASTER
if [[ $P_MASTER == 'P_MASTER' ]]; then

psql -U postgres -c "SET password_encryption = 'scram-sha-256'; CREATE ROLE $REPLICA_POSTGRES_USER WITH REPLICATION PASSWORD '$REPLICA_POSTGRES_PASSWORD' LOGIN;"

# Add replication settings to primary postgres conf
cat >> ${PGDATA}/postgresql.conf <<EOF
hot_standby = on
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3
synchronous_commit = ${SYNCHRONOUS_COMMIT}
listen_addresses = '*'
max_connections = 50			# (change requires restart)
shared_buffers = 1009871kB			# min 128kB
work_mem = 5049kB				# min 64kB
maintenance_work_mem = 504935kB		# min 1MB
dynamic_shared_memory_type = posix	# the default is the first option
effective_io_concurrency = 256		# 1-1000; 0 disables prefetching
max_worker_processes = 14		# (change requires restart)
max_parallel_workers_per_gather = 2	# taken from max_parallel_workers
max_parallel_workers = 3		# maximum number of max_worker_processes that
wal_buffers = 16MB			# min 32kB, -1 sets based on shared_buffers
#checkpoint_timeout = 5min		# range 30s-1d
max_wal_size = 1GB
min_wal_size = 512MB
checkpoint_completion_target = 0.9	# checkpoint target duration, 0.0 - 1.0
random_page_cost = 1.1			# same scale as above
effective_cache_size = 2958MB
default_statistics_target = 500	# range 1-10000
log_timezone = 'Europe/Istanbul'
autovacuum_max_workers = 10		# max number of autovacuum subprocesses
autovacuum_naptime = 10		# time between autovacuum runs
datestyle = 'iso, mdy'
timezone = 'Europe/Istanbul'
lc_messages = 'en_US.utf8'			# locale for system error message
lc_monetary = 'en_US.utf8'			# locale for monetary formatting
lc_numeric = 'en_US.utf8'			# locale for number formatting
lc_time = 'en_US.utf8'				# locale for time formatting
default_text_search_config = 'pg_catalog.english'
shared_preload_libraries = 'timescaledb'	# (change requires restart)
max_locks_per_transaction = 64		# min 10
timescaledb.telemetry_level=basic
timescaledb.max_background_workers = 8
timescaledb.last_tuned = '2022-06-15T17:58:32+03:00'
timescaledb.last_tuned_version = '0.12.0'
EOF

# Add synchronous standby names if we're in one of the synchronous commit modes
if [[ "${SYNCHRONOUS_COMMIT}" =~ ^(on|remote_write|remote_apply)$ ]]; then
cat >> ${PGDATA}/postgresql.conf <<EOF
synchronous_standby_names = '2 (${REPLICA_NAME},${REPLICA_NAME2})'
EOF
fi

# Add replication settings to primary pg_hba.conf
# Using the hostname of the primary doesn't work with docker containers, so we resolve to an IP using getent,
# or we use a subnet provided at runtime.
if  [[ -z $REPLICATION_SUBNET ]]; then
    REPLICATION_SUBNET=$(getent hosts ${REPLICATE_TO} | awk '{ print $1 }')/24
    REPLICATION_SUBNET2=$(getent hosts ${REPLICATE_TO2} | awk '{ print $1 }')/24
fi

cat >> ${PGDATA}/pg_hba.conf <<EOF
host     replication     ${REPLICA_POSTGRES_USER}   ${REPLICATION_SUBNET}       scram-sha-256
host     replication     ${REPLICA_POSTGRES_USER}   ${REPLICATION_SUBNET2}       scram-sha-256
EOF

# Restart postgres and add replication slot
pg_ctl -D ${PGDATA} -m fast -w restart
psql -U postgres -c "SELECT * FROM pg_create_physical_replication_slot('${REPLICA_NAME}_slot');"
psql -U postgres -c "SELECT * FROM pg_create_physical_replication_slot('${REPLICA_NAME2}_slot');"


# SLAVE 1
elif [[ $P_SLAVE1 == 'P_SLAVE1' ]]; then

# Stop postgres instance and clear out PGDATA
pg_ctl -D ${PGDATA} -m fast -w stop
rm -rf ${PGDATA}/*

# Create a pg pass file so pg_basebackup can send a password to the primary
cat > ~/.pgpass.conf <<EOF
*:5432:replication:${POSTGRES_USER}:${POSTGRES_PASSWORD}
EOF
chown postgres:postgres ~/.pgpass.conf
chmod 0600 ~/.pgpass.conf

# Backup replica from the primary
until PGPASSFILE=~/.pgpass.conf pg_basebackup -h ${REPLICATE_FROM} -D ${PGDATA} -U ${POSTGRES_USER} -vP -w
do
    # If docker is starting the containers simultaneously, the backup may encounter
    # the primary amidst a restart. Retry until we can make contact.
    sleep 1
    echo "Retrying backup . . ."
done

# standby.signal starts in postgresql mode and streams the WAL through the replication protocol.
touch ${PGDATA}/standby.signal

# Remove pg pass file -- it is not needed after backup is restored
rm ~/.pgpass.conf

# Create the postgresql.conf file so the backup knows to start in recovery mode
cat > ${PGDATA}/postgresql.conf <<EOF
primary_conninfo = 'host=${REPLICATE_FROM} port=5432 user=${POSTGRES_USER} password=${POSTGRES_PASSWORD} application_name=${REPLICA_NAME}'
primary_slot_name = '${REPLICA_NAME}_slot'
hot_standby = on
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3
synchronous_commit = off
listen_addresses = '*'
max_connections = 50			# (change requires restart)
shared_buffers = 1009871kB			# min 128kB
work_mem = 5049kB				# min 64kB
maintenance_work_mem = 504935kB		# min 1MB
dynamic_shared_memory_type = posix	# the default is the first option
effective_io_concurrency = 256		# 1-1000; 0 disables prefetching
max_worker_processes = 14		# (change requires restart)
max_parallel_workers_per_gather = 2	# taken from max_parallel_workers
max_parallel_workers = 3		# maximum number of max_worker_processes that
wal_buffers = 16MB			# min 32kB, -1 sets based on shared_buffers
max_wal_size = 1GB
min_wal_size = 512MB
checkpoint_completion_target = 0.9	# checkpoint target duration, 0.0 - 1.0
random_page_cost = 1.1			# same scale as above
effective_cache_size = 2958MB
default_statistics_target = 500	# range 1-10000
log_timezone = 'Europe/Istanbul'
autovacuum_max_workers = 10		# max number of autovacuum subprocesses
autovacuum_naptime = 10		# time between autovacuum runs
datestyle = 'iso, mdy'
timezone = 'Europe/Istanbul'
lc_messages = 'en_US.utf8'			# locale for system error message
lc_monetary = 'en_US.utf8'			# locale for monetary formatting
lc_numeric = 'en_US.utf8'			# locale for number formatting
lc_time = 'en_US.utf8'				# locale for time formatting
default_text_search_config = 'pg_catalog.english'
shared_preload_libraries = 'timescaledb'	# (change requires restart)
max_locks_per_transaction = 64		# min 10
timescaledb.telemetry_level=basic
timescaledb.max_background_workers = 8
timescaledb.last_tuned = '2022-06-15T17:58:32+03:00'
timescaledb.last_tuned_version = '0.12.0'
EOF

# hot_standby ensure that replica is only for readonly

# Ensure proper permissions on postgresql.conf
chown postgres:postgres ${PGDATA}/postgresql.conf
chmod 0600 ${PGDATA}/postgresql.conf

pg_ctl -D ${PGDATA} -w start



# SLAVE 2
elif [[ $P_SLAVE2 == 'P_SLAVE2' ]]; then

# Stop postgres instance and clear out PGDATA
pg_ctl -D ${PGDATA} -m fast -w stop
rm -rf ${PGDATA}/*

# Create a pg pass file so pg_basebackup can send a password to the primary
cat > ~/.pgpass.conf <<EOF
*:5432:replication:${POSTGRES_USER}:${POSTGRES_PASSWORD}
EOF
chown postgres:postgres ~/.pgpass.conf
chmod 0600 ~/.pgpass.conf

# Backup replica from the primary
until PGPASSFILE=~/.pgpass.conf pg_basebackup -h ${REPLICATE_FROM} -D ${PGDATA} -U ${POSTGRES_USER} -vP -w
do
    # If docker is starting the containers simultaneously, the backup may encounter
    # the primary amidst a restart. Retry until we can make contact.
    sleep 1
    echo "Retrying backup . . ."
done

# standby.signal starts in postgresql mode and streams the WAL through the replication protocol.
touch ${PGDATA}/standby.signal

# Remove pg pass file -- it is not needed after backup is restored
rm ~/.pgpass.conf

# Create the postgresql.conf file so the backup knows to start in recovery mode
cat > ${PGDATA}/postgresql.conf <<EOF
primary_conninfo = 'host=${REPLICATE_FROM} port=5432 user=${POSTGRES_USER} password=${POSTGRES_PASSWORD} application_name=${REPLICA_NAME2}'
primary_slot_name = '${REPLICA_NAME2}_slot'
hot_standby = on
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3
synchronous_commit = off
listen_addresses = '*'
max_connections = 50			# (change requires restart)
shared_buffers = 1009871kB			# min 128kB
work_mem = 5049kB				# min 64kB
maintenance_work_mem = 504935kB		# min 1MB
dynamic_shared_memory_type = posix	# the default is the first option
effective_io_concurrency = 256		# 1-1000; 0 disables prefetching
max_worker_processes = 14		# (change requires restart)
max_parallel_workers_per_gather = 2	# taken from max_parallel_workers
max_parallel_workers = 3		# maximum number of max_worker_processes that
wal_buffers = 16MB			# min 32kB, -1 sets based on shared_buffers
max_wal_size = 1GB
min_wal_size = 512MB
checkpoint_completion_target = 0.9	# checkpoint target duration, 0.0 - 1.0
random_page_cost = 1.1			# same scale as above
effective_cache_size = 2958MB
default_statistics_target = 500	# range 1-10000
log_timezone = 'Europe/Istanbul'
autovacuum_max_workers = 10		# max number of autovacuum subprocesses
autovacuum_naptime = 10		# time between autovacuum runs
datestyle = 'iso, mdy'
timezone = 'Europe/Istanbul'
lc_messages = 'en_US.utf8'			# locale for system error message
lc_monetary = 'en_US.utf8'			# locale for monetary formatting
lc_numeric = 'en_US.utf8'			# locale for number formatting
lc_time = 'en_US.utf8'				# locale for time formatting
default_text_search_config = 'pg_catalog.english'
shared_preload_libraries = 'timescaledb'	# (change requires restart)
max_locks_per_transaction = 64		# min 10
timescaledb.telemetry_level=basic
timescaledb.max_background_workers = 8
timescaledb.last_tuned = '2022-06-15T17:58:32+03:00'
timescaledb.last_tuned_version = '0.12.0'
EOF

# hot_standby ensure that replica is only for readonly

# Ensure proper permissions on postgresql.conf
chown postgres:postgres ${PGDATA}/postgresql.conf
chmod 0600 ${PGDATA}/postgresql.conf

pg_ctl -D ${PGDATA} -w start

fi