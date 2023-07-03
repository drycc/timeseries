#!/bin/bash
function init_passwd() {
  if [[ $UID -ge 10000 ]]; then
      GID=$(id -g)
      sed -e "s/^postgres:x:[^:]*:[^:]*:/postgres:x:$UID:$GID:/" /etc/passwd > /tmp/passwd
      cat /tmp/passwd > /etc/passwd
      rm /tmp/passwd
  fi
}

function init_config() {
  cat > /data/patroni.yaml <<__EOF__
bootstrap:
  dcs:
    postgresql:
      use_pg_rewind: true
      parameters:
        max_connections: ${PG_MAX_CONNECTIONS}
        max_prepared_transactions: ${PG_MAX_CONNECTIONS}
  initdb:
  - auth-host: md5
  - auth-local: trust
  - encoding: UTF8
  - locale: ${LANG}
  - data-checksums
  pg_hba:
  - host all all 0.0.0.0/0 md5
  - host replication ${DRYCC_TIMESERIES_REPLICATOR} ${PATRONI_KUBERNETES_POD_IP}/16 md5
  post_bootstrap: /usr/share/scripts/patroni/post_init.sh
restapi:
  connect_address: '${PATRONI_KUBERNETES_POD_IP}:8008'
postgresql:
  data_dir: '${PGDATA}'
  parameters:
    timescaledb.license: 'timescale'
    shared_preload_libraries: 'auto_explain,timescaledb,pg_stat_statements'
  connect_address: '${PATRONI_KUBERNETES_POD_IP}:5432'
  authentication:
    superuser:
      username: '${DRYCC_TIMESERIES_SUPERUSER}'
      password: '${DRYCC_TIMESERIES_SUPERUSER_PASSWORD}'
    replication:
      username: '${DRYCC_TIMESERIES_REPLICATOR}'
      password: '${DRYCC_TIMESERIES_REPLICATOR_PASSWORD}'
watchdog:
  mode: off
__EOF__
  unset DRYCC_TIMESERIES_SUPERUSER_PASSWORD DRYCC_TIMESERIES_REPLICATION_PASSWORD
}

function start_main() {
  init_passwd
  init_config
  exec start-main /data/patroni.yaml
}

function start_node() {
  init_passwd
  init_config
  exec start-node /data/patroni.yaml
}
"start_$1"
