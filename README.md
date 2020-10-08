# ARLAS-stack-birdstracking-tutorial

## About this tutorial
### What will you learn ?
With this tutorial, you'll be able to:
- start an ARLAS-Exploration stack
- Index some birdtracking data in Elasticsearch
- Reference the indexed birdtracking data in ARLAS
- Create a view of ARLAS-wui (a dashboard) to explore the birdtracking data using ARLAS-wui-hub and ARLAS-wui-builder

### What will you need ?

You will need :
- docker & docker-compose
- curl

### What will you get ?


## Birdstracking data

Let's explore some white storks migration data, provided by __the Movebank Data Repository__. 

We built a subset of the dataset provided in [this package](doi:10.5441/001/1.ck04mn78) by Movebank.

The subset is `birdstracking_data.csv`. It contains around 77 000 birds GPS positions described with 7 columns:

- identifier: An identifier of the emitted position
- name: Name of the moving bird
- location: Coordinates of the emitted position as longitudes/latitudes
- timestamp: Moment when the position is emitted
- speed_ms: Speed of the bird at this postion (m/s)
- height_m: Altitude of the birds at this position (m)
- trail: Linestring between the current position of the bird and the next one

A line of the csv file looks like:

|identifier|name|location|timestamp|speed_ms|height_m|trail|
|---|---|---|---|---|---|---|
|009829e...|Redrunner + / DER AU057 (eobs 3339)|'{"lon":8.7,"lat":50.4}'|1491922507|190.65|0.15|'{"coordinates":[[8.7,50.4],[8.72,50.41]],"type":"LineString"}'|
## Exploring Birdstracking data

We will explore this data using ARLAS.

__1. Starting ARLAS Exploration Stack__

- Get the docker-compose file from [ARLAS-Exploration-stack](https://github.com/gisaia/ARLAS-Exploration-stack.git) that will allow us to start the ARLAS stack

    ```shell
    curl -XGET \
        "https://raw.githubusercontent.com/gisaia/ARLAS-Exploration-stack/develop/docker-compose.yaml?token=AGMAY2BRSA7XD3KKD6JN6J27QYNSA" \
        -o docker-compose.yaml
    ```
- Start the ARLAS stack 
    ```shell
    cd ARLAS-Exploration-stack
    docker-compose up -d \
        arlas-wui \
        arlas-hub \
        arlas-builder \
        arlas-server \
        arlas-persistence-server \
        elasticsearch
    ```
    6 services are started:
    - ARLAS-wui at http://localhost:8096
    - ARLAS-wui-builder at http://localhost:8095
    - ARLAS-wui-hub at http://localhost:8094
    - ARLAS-server at http://localhost:19999/arlas/swagger
    - ARLAS-persistence at http://localhost:19997/arlas-persistence-server/swagger
    - Elasticsearch at http://localhost:9200

__2. Indexing birdtracking data in Elasticsearch__

- Create `birdstracking_index` index in Elasticsearch with `configs/birdtracking.es_mapping.json` mapping file

    ```shell
    curl -XPUT http://localhost:9200/birdstracking_index/?pretty \
    -d @configs/birdtracking.es_mapping.json \
    -H 'Content-Type: application/json'

    ```
- Index data in `birdstracking_data.csv` in Elasticsearch
    - We need Logstash as a data processing pipeline that ingests data in Elasticsearch. So we will download it and untar it:

        ```shell
        ( wget https://artifacts.elastic.co/downloads/logstash/logstash-7.4.2.tar.gz ; tar -xzf logstash-7.4.2.tar.gz )
        ```
    - Now we can index the data:

        ```shell
        cat birdstracking_data.csv \
        | ./logstash-7.4.2/bin/logstash \
        -f configs/birdtracking2es.logstash.conf
        ```
    - Check if __77 384__ birds positions are indexed:

        ```shell
        curl -XGET http://localhost:9200/birdstracking_index/_count?pretty
        ```
__3. Declaring `birdstracking_index` in ARLAS__

ARLAS-server interfaces with data indexed in Elasticsearch via a collection reference.

The collection references an identifier, a timestamp, and geographical fields which allows ARLAS-server to perform a spatial-temporal data analysis


- Create a Birdstracking collection in ARL  AS

    ```shell
    curl -X PUT \
    --header 'Content-Type: application/json;charset=utf-8' \
    --header 'Accept: application/json' \
    "http://localhost:19999/arlas/collections/birdstracking_collection?pretty=true" \
    --data @birdstracking_collection.json
    ```
