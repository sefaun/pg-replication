#!/bin/bash

# CONFIGURE PRIMARY
if [[ -z $REPLICATE_FROM ]]; then

psql -U postgres -c "SET password_encryption = 'scram-sha-256'; CREATE ROLE $REPLICA_POSTGRES_USER WITH REPLICATION PASSWORD '$REPLICA_POSTGRES_PASSWORD' LOGIN;"

# Add replication settings to primary postgres conf
cat >> ${PGDATA}/postgresql.conf <<EOF
listen_addresses= '*'
wal_level = replica
max_wal_senders = 2
max_replication_slots = 2
synchronous_commit = ${SYNCHRONOUS_COMMIT}
EOF

# Add synchronous standby names if we're in one of the synchronous commit modes
if [[ "${SYNCHRONOUS_COMMIT}" =~ ^(on|remote_write|remote_apply)$ ]]; then
cat >> ${PGDATA}/postgresql.conf <<EOF
synchronous_standby_names = '1 (${REPLICA_NAME})'
EOF
fi

# Add replication settings to primary pg_hba.conf
# Using the hostname of the primary doesn't work with docker containers, so we resolve to an IP using getent,
# or we use a subnet provided at runtime.
if  [[ -z $REPLICATION_SUBNET ]]; then
    REPLICATION_SUBNET=$(getent hosts ${REPLICATE_TO} | awk '{ print $1 }')/24
fi

cat >> ${PGDATA}/pg_hba.conf <<EOF
host     replication     ${REPLICA_POSTGRES_USER}   ${REPLICATION_SUBNET}       scram-sha-256
EOF

# Restart postgres and add replication slot
pg_ctl -D ${PGDATA} -m fast -w restart
psql -U postgres -c "SELECT * FROM pg_create_physical_replication_slot('${REPLICA_NAME}_slot');"

# CONFIGURE REPLICA
else

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
max_wal_senders = 2
max_replication_slots = 2
synchronous_commit = off
listen_addresses = '*'
max_worker_processes = 32
max_locks_per_transaction = 256
shared_preload_libraries = 'timescaledb'
EOF

# hot_standby ensure that replica is only for readonly

# Ensure proper permissions on postgresql.conf
chown postgres:postgres ${PGDATA}/postgresql.conf
chmod 0600 ${PGDATA}/postgresql.conf

pg_ctl -D ${PGDATA} -w start

fi