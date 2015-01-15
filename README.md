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


For more information on linking see:
* https://blog.codecentric.de/en/2014/01/docker-networking-made-simple-3-ways-connect-lxc-containers/
* https://docs.docker.com/userguide/dockerlinks/


<Future Improvement> need to link containers; and use their assigned ip (provided as environmnet variables); described [here](https://blog.codecentric.de/en/2014/01/docker-networking-made-simple-3-ways-connect-lxc-containers/)


## Setting up feeding the data from RethinkDB to ElasticSearch

Now that your container are linked you can set up feeding the data from RethinkDB to ElasticSearch.

The needed plugin [elasticsearch-river-rethinkdb](https://github.com/rethinkdb/elasticsearch-river-rethinkdb) has already been installed through dockerfile.

All you need to do is to point ES to the location of your db; which you can do by:

```
curl -XPUT <IP-ElasticSearch>:9200/_river/rethinkdb/_meta -d '{
   "type":"rethinkdb",
   "rethinkdb": {
     "databases": {"<DB>": {"<TABLE>": {"backfill": true}}},
     "host": "<IP-RethinkDB>",
     "port": 28015
   }}'
```
> replace `<DB>` and `<TABLE>` with appropriate values
> replace ips `<IP-ElasticSearch>`, `<IP-RethinkDB>` with ip issued by docker -- note it is different from localhost or 127.0.0.1 or 0.0.0.1 (since now you have several containers running on the same machine)
>> you can look up ids by `docker inspect --format '{{ .NetworkSettings.IPAddress }}' <CID>`

you should see: `{"_index":"_river","_type":"rethinkdb","_id":"_meta","_version":1,"created":true}`
> if `"created":false`: means that something is wrong
>> you might want to look at elasticsearch logs `log/elasticsearch.log` to get more details
>> wrong ip's are common

To test it:

`curl localhost:9200/<DB>/<TABLE>/_search?q=*:*`
> replace `<DB>` and `<TABLE>` with appropriate values

optionally: you may want to save your container state commiting it to an image:
`docker commit <CID> elasticsearch2`
or you can continue running it by `docker start elasticsearch`
> not for  large index files it take a little bit of time to initialize


For more information see:
* http://rethinkdb.com/docs/elasticsearch/
* https://github.com/rethinkdb/elasticsearch-river-rethinkdb
* http://www.elasticsearch.org/guide/en/elasticsearch/rivers/current/



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


! Troubleshooting

!! index is not created

see `data/log/elasticsearch.log` for the error message; in my case it was:

```
[2015-01-13 03:38:25,674][WARN ][river                    ] [Wildpride] failed to create river [rethinkdb][rethinkdb]
org.elasticsearch.common.settings.NoClassSettingsException: Failed to load class with value [rethinkdb]
        at org.elasticsearch.river.RiverModule.loadTypeModule(RiverModule.java:87)
        at org.elasticsearch.river.RiverModule.spawnModules(RiverModule.java:58)
        at org.elasticsearch.common.inject.ModulesBuilder.add(ModulesBuilder.java:44)
        at org.elasticsearch.river.RiversService.createRiver(RiversService.java:137)
        at org.elasticsearch.river.RiversService$ApplyRivers$2.onResponse(RiversService.java:275)
        at org.elasticsearch.river.RiversService$ApplyRivers$2.onResponse(RiversService.java:269)
        at org.elasticsearch.action.support.TransportAction$ThreadedActionListener$1.run(TransportAction.java:113)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1142)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)
        at java.lang.Thread.run(Thread.java:745)
Caused by: java.lang.ClassNotFoundException: rethinkdb
        at java.net.URLClassLoader$1.run(URLClassLoader.java:372)
        at java.net.URLClassLoader$1.run(URLClassLoader.java:361)
        at java.security.AccessController.doPrivileged(Native Method)
        at java.net.URLClassLoader.findClass(URLClassLoader.java:360)
        at java.lang.ClassLoader.loadClass(ClassLoader.java:424)
        at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:308)
        at java.lang.ClassLoader.loadClass(ClassLoader.java:357)
        at org.elasticsearch.river.RiverModule.loadTypeModule(RiverModule.java:73)
        ... 9 more

```


```
[2015-01-13 07:08:11,667][INFO ][cluster.metadata         ] [Punchout] [_river] update_mapping [rethinkdb] (dynamic)
[2015-01-13 07:08:11,716][ERROR][river.rethinkdb.feedworker] [] failed due to exception
com.rethinkdb.RethinkDBException: java.net.ConnectException: Connection refused
	at com.rethinkdb.SocketChannelFacade.connect(SocketChannelFacade.java:22)
	at com.rethinkdb.RethinkDBConnection.reconnect(RethinkDBConnection.java:50)
	at com.rethinkdb.RethinkDBConnection.<init>(RethinkDBConnection.java:45)
	at com.rethinkdb.RethinkDBConnection.<init>(RethinkDBConnection.java:37)
	at com.rethinkdb.RethinkDB.connect(RethinkDB.java:66)
	at org.elasticsearch.river.rethinkdb.FeedWorker.connect(FeedWorker.java:44)
	at org.elasticsearch.river.rethinkdb.FeedWorker.run(FeedWorker.java:67)
	at java.lang.Thread.run(Thread.java:745)
Caused by: java.net.ConnectException: Connection refused
	at sun.nio.ch.Net.connect0(Native Method)
	at sun.nio.ch.Net.connect(Net.java:457)
	at sun.nio.ch.Net.connect(Net.java:449)
	at sun.nio.ch.SocketChannelImpl.connect(SocketChannelImpl.java:647)
	at com.rethinkdb.SocketChannelFacade.connect(SocketChannelFacade.java:20)
	... 7 more
[2015-01-13 07:08:11,719][INFO ][river.rethinkdb.feedworker] [] thread shutting down
```

##


