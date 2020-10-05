# ARLAS-stack-birdstracking-tutorial

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

## Exploring Birdstracking data

We will explore this data using ARLAS.

__1. Starting ARLAS Exploration Stack__

> Prequisites: To have installed
> - docker
> - docker-compose

- Clone the [ARLAS-Exploration-stack](https://github.com/gisaia/ARLAS-Exploration-stack.git) outside this project

    ```shell
    cd ..
    git clone https://github.com/gisaia/ARLAS-Exploration-stack.git
    ```
- Start the stack 
    ```shell
    cd ARLAS-Exploration-stack
    docker-compose up
    ```
    This will start 5 services:
    - ARLAS-wui at http://localhost:8096
    - ARLAS-wui-builder at http://localhost:8095
    - ARLAS-wui-hub at http://localhost:8094
    - ARLAS-server at http://localhost:19999/arlas/swagger
    - ARLAS-persistence at http://localhost:19997/arlas-persistence-server/swagger
    - Elasticsearch at http://localhost:9200

    _Note: You can use the script `start.sh` instead of `docker-compose up` command. This script has several parameters that helps you start an exernal Elasticsearch cluster or an ARLAS-server for example_

__2. Indexing birdtracking data in Elasticsearch__

- Go back to this repository
    ```shell
    cd ../ARLAS-stack-birdstracking-tutorial
    ```
- Create `birdstracking_index` index in Elasticsearch with `configs/birdtracking.es_mapping.json` mapping file

    ```shell
    curl -XPUT http://localhost:9200/birdstracking_index/ \
    -d @configs/birdtracking.es_mapping.json \
    -H 'Content-Type: application/json'

    ```
- Index data in `birdstracking_data.csv` in Elasticsearch
    - For that we need Logstash, a data processing pipeline that ingests data from a multitude of sources

        ```shell
        ( wget https://artifacts.elastic.co/downloads/logstash/logstash-7.4.2.tar.gz ; tar -xzf logstash-7.4.2.tar.gz )
        ```
    - Index data

        ```shell
        cat birdstracking_data.csv \
        | ./logstash-7.4.2/bin/logstash \
        -f configs/birdtracking2es.logstash.conf
        ```
    - Check if __77 384__ birds positions are indexed

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
