Overview: Running ElasticSearch with RethinkDB on Docker


It is a fork from https://github.com/dockerfile/elasticsearch
initially started as to make it work with RethinkDB; but now also contains some improvements:
* updated version of java and ES (some of which is required by RethinkDB's river plugin)
* removed `\data` volume since will be fed from db
* removed `configuration` files; since everything will be within container
* installed plugins
  * [RethinkDB river](https://github.com/rethinkdb/elasticsearch-river-rethinkdb)
  * [HEAD](https://github.com/mobz/elasticsearch-head) for troubleshooting

# Usage

`git clone https://github.com/neil-rubens/elasticsearch.git`

`sudo docker build --tag="activeintel/elasticsearch" .`

`run` for the first time as:

`sudo docker run -d -p 9200:9200 -p 9300:9300 --name elasticsearch activeintel/elasticsearch`

> container is `--name`d `elasticsearch` for convenience and linking (described later) 

for running container again later on make sure to use the `start` command:

`docker start elasticsearch`

to make sure that it is running goto http://localhost:9200/


# Inegrating RethinkDB with ElasticSearch

## Linking Containers

You need to [link](https://docs.docker.com/userguide/dockerlinks/) `elasticsearch` and `rethinkdb` docker containers so that they can exchange data.  
> this assumes that you already have a `rethinkdb` docker container; if not here are the [instructions](https://github.com/dockerfile/rethinkdb)
> here it is also assumed that your rethinkdb container is `--name`d `rethinkdb`; if it is not use container id instead

To link, `rethinkdb` container should already be running; and the you run the `elasticsearch` image as:

`docker run -d -p 9200:9200 -p 9300:9300 --name elasticsearch --link rethinkdb:elasticsearch-rethinkdb-link activeintel/elasticsearch`

> linking actually happens in this part `--link rethinkdb:elasticsearch-rethinkdb-link`
>> if your rethikdb container is not named you will need to specify its container id: `--link <CID>:elasticsearch-rethinkdb-link`


For more information on linking see: https://docs.docker.com/userguide/dockerlinks/


## Setting up RethinkDB Link

The needed plugin [elasticsearch-river-rethinkdb](https://github.com/rethinkdb/elasticsearch-river-rethinkdb) has already been installed through dockerfile.

All you need to do is to point ES to the location of your db; which you can do by:

```
curl -XPUT localhost:9200/_river/rethinkdb/_meta -d '{
   "type":"rethinkdb",
   "rethinkdb": {
     "databases": {"<DB>": {"<TABLE>": {"backfill": true}}},
     "host": "localhost",
     "port": 28015
   }}'
```

> replace `<DB>` and `<TABLE>` with appropriate values

To test it:

`curl localhost:9200/<DB>/<TABLE>/_search?q=*:*`
> replace `<DB>` and `<TABLE>` with appropriate values


For more information see:
* http://rethinkdb.com/docs/elasticsearch/
* https://github.com/rethinkdb/elasticsearch-river-rethinkdb




# Additional differences from [dockerfile/elasticsearch](https://github.com/dockerfile/elasticsearch)

## data volumes

Decided not to use [data volume](https://docs.docker.com/userguide/dockervolumes/) since data will be fed from rethinkdb anyways; so it doesn't appear to be necessary.

I've found these articles quite useful for making the decision:
* http://www.tech-d.net/2014/11/03/docker-indepth-volumes/
* https://docs.docker.com/userguide/dockervolumes/


# minor tips

for trouble shooting your image you might consider connecting to it as:

`sudo docker start -d -i -t elasticsearch --entrypoint /bin/bash`




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


