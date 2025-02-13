#!/bin/sh

if [ -f /a.tar.xz ]; then
    echo "decompressing image..."
    sudo tar xpJf /a.tar.xz -C / > /dev/null 2>&1
    sudo rm /a.tar.xz
    sudo ln -snf dash /bin/sh
fi

readonly PATRONI_SCOPE=${PATRONI_SCOPE:-batman}
PATRONI_NAMESPACE=${PATRONI_NAMESPACE:-/service}
readonly PATRONI_NAMESPACE=${PATRONI_NAMESPACE%/}
readonly DOCKER_IP=$(hostname --ip-address)
case "$1" in
    haproxy)
        haproxy -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -D
        CONFD="confd -prefix=$PATRONI_NAMESPACE/$PATRONI_SCOPE -interval=10 -backend"
	    if [ ! -z "$PATRONI_ZOOKEEPER_HOSTS" ]; then
            while ! /usr/share/zookeeper/bin/zkCli.sh -server $PATRONI_ZOOKEEPER_HOSTS ls /; do
                sleep 1
            done
            exec dumb-init $CONFD zookeeper -node $PATRONI_ZOOKEEPER_HOSTS
        else
            
                sleep 90
            
            exec dumb-init $CONFD consul -node $(echo http://haproxy-consul:80 | sed 's/,/ -node /g')
        fi
        ;;
	
esac

export PATRONI_SCOPE
export PATRONI_NAMESPACE
export PATRONI_NAME="${PATRONI_NAME:-$(hostname)}"
export PATRONI_RESTAPI_CONNECT_ADDRESS="$DOCKER_IP:8008"
export PATRONI_RESTAPI_LISTEN="0.0.0.0:8008"
export PATRONI_admin_PASSWORD="${PATRONI_admin_PASSWORD:-admin}"
export PATRONI_admin_OPTIONS="${PATRONI_admin_OPTIONS:-createdb, createrole}"
export PATRONI_POSTGRESQL_CONNECT_ADDRESS="$DOCKER_IP:5432"
export PATRONI_POSTGRESQL_LISTEN="0.0.0.0:5432"
export PATRONI_POSTGRESQL_DATA_DIR="${PATRONI_POSTGRESQL_DATA_DIR:-$PGDATA}"
export PATRONI_REPLICATION_USERNAME="${PATRONI_REPLICATION_USERNAME:-replicator}"
export PATRONI_REPLICATION_PASSWORD="${PATRONI_REPLICATION_PASSWORD:-replicate}"
export PATRONI_SUPERUSER_USERNAME="${PATRONI_SUPERUSER_USERNAME:-postgres}"
export PATRONI_SUPERUSER_PASSWORD="${PATRONI_SUPERUSER_PASSWORD:-postgres}"
export PATRONI_CONSUL_HOST="${PATRONI_CONSUL_HOST:-${DOCKER_IP}:8500}"
export PATRONI_NAME="${PATRONI_NAME:-${HOSTNAME}}"


exec python3 /patroni.py postgres0.yml
