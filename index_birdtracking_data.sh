#!/bin/bash
set -o errexit

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
PROJECT_ROOT_DIRECTORY="$(dirname "$SCRIPT_DIRECTORY")"
BIRDTRACKINGINDEX="birdtracking_index"
LOGSTASH_VERSION="7.4.2"

usage(){
	echo "Usage: ./index_birdtracking_data.sh [--es-cluster] []"
	echo " -esc|--es-cluster             ES cluster to use. If not set, http://localhost:9200 is considered"
  echo " -h|--help                     Display manual"
	exit 1
}

for i in "$@"
do
case $i in
    -h|--help)
    HELP="true"
    shift # past argument=value
    ;;
    -esc=*|--es-cluster=*)
    export ES_CLUSTER="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

if [ ! -z ${HELP+x} ];
    then
        usage;
fi

if [ ! -z ${ES_CLUSTER+x} ];
    then
        echo "ELASTICSEARCH is running on cluster $ES_CLUSTER"
    else
        ES_CLUSTER=http://localhost:9200
        echo "ELASTICSEARCH is running on http://localhost:9200"
fi


echo "## Deleting '${BIRDTRACKINGINDEX}' in case it already exists"
curl -XDELETE "${ES_CLUSTER}/${BIRDTRACKINGINDEX}?pretty"
echo ""
echo "## Creating '${BIRDTRACKINGINDEX}'"
curl  -f -XPUT ${ES_CLUSTER}/${BIRDTRACKINGINDEX}/ -d @${SCRIPT_DIRECTORY}/configs/birdtracking.es_mapping.json  -H 'Content-Type: application/json'
echo ""
echo ""
echo "## Indexing data in '${BIRDTRACKINGINDEX}'"
echo ""
echo "#### Installing LOGSTASH..."
[ -d logstash-$LOGSTASH_VERSION ] && echo "logstash found " || ( wget https://artifacts.elastic.co/downloads/logstash/logstash-$LOGSTASH_VERSION.tar.gz ; tar -xzf logstash-$LOGSTASH_VERSION.tar.gz )
echo ""
echo "#### Indexing..."
sed '1d' ${SCRIPT_DIRECTORY}/data/birdstracking_data.csv > ${SCRIPT_DIRECTORY}/headless_birdstracking_data.csv
cat ${SCRIPT_DIRECTORY}/headless_birdstracking_data.csv| ./logstash-$LOGSTASH_VERSION/bin/logstash -f ${SCRIPT_DIRECTORY}/configs/birdtracking2es.logstash.conf
rm ${SCRIPT_DIRECTORY}/headless_birdstracking_data.csv
