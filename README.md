Overview: Running ElasticSearch with RethinkDB on Docker


It is a fork from https://github.com/dockerfile/elasticsearch
initially started as to make it work with RethinkDB; but now also contains some improvements:
* updated version of java and ES (some of which is required by RethinkDB's river plugin)
* removed `\data` volume since will be fed from db
* removed `configuration` files; since everything will be within container
* installed plugins
   * RethinkDB river
   * [HEAD](https://github.com/mobz/elasticsearch-head)

# Usage

`git clone https://github.com/neil-rubens/elasticsearch.git`

`sudo docker build --tag="activeintel/elasticsearch" .`

`run` for the first time as:

`sudo docker run -d -p 9200:9200 -p 9300:9300 --name elasticsearch activeintel/elasticsearch`

> container is `--name`d `elasticsearch` for convenience and linking (described later) 

for running container again later on make sure to use the `start` command:

`docker start elasticsearch`

to make sure that it is running goto http://localhost:9200/

# Additional differences from [dockerfile/elasticsearch](https://github.com/dockerfile/elasticsearch)

## data volumes

Decided not to use [data volume](https://docs.docker.com/userguide/dockervolumes/) since data will be fed from rethinkdb anyways; so it doesn't appear to be necessary.






# Various notes: mostly for keywords and search egnines

##

make sure to run build from within the downloaded directory otherwise you will see the following error:

```
ADD config/elasticsearch.yml /elasticsearch/config/elasticsearch.yml
config/elasticsearch.yml: no such file or directory
```

##

!!! Problem
For some reason when installing plugins with Dockerfile they do appear in the file system but are not loaded by ES at startup.

!!! Solution

ES [[config|https://github.com/dockerfile/elasticsearch/blob/master/config/elasticsearch.yml]] specifies plugins to be located at the mounted `\data` volume; so need to remove it and point it locally. 

##


