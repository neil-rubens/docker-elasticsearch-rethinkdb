It is a fork from https://github.com/dockerfile/elasticsearch
initially started as to make it work with RethinkDB; but now also contains some improvements:
* updated version of java and ES (some of which is required by RethinkDB's river plugin)
* removed `\data` volume since will be fed from db
* removed `configuration` files; since everything will be within container
* installed plugins
   * RethinkDB river
   * HEAD


