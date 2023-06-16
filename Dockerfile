FROM timescale/timescaledb:latest-pg14

ADD replication.sh /docker-entrypoint-initdb.d/