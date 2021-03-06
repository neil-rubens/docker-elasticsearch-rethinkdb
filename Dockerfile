#
# ElasticSearch Dockerfile
#
# https://github.com/dockerfile/elasticsearch
#

# Pull base image.
FROM dockerfile/java:oracle-java8

ENV ES_PKG_NAME elasticsearch-1.4.2

# Install ElasticSearch.
RUN \
  cd / && \
  wget https://download.elasticsearch.org/elasticsearch/elasticsearch/$ES_PKG_NAME.tar.gz && \
  tar xvzf $ES_PKG_NAME.tar.gz && \
  rm -f $ES_PKG_NAME.tar.gz && \
  mv /$ES_PKG_NAME /elasticsearch

# Define mountable directories.
# NR: commented out; data will be fed through rethinkdb anyways
#VOLUME ["/data"]

# Mount elasticsearch.yml config
# NR: commented out since want to keep things within container (such as plugins)
# ADD config/elasticsearch.yml /elasticsearch/config/elasticsearch.yml

# Install RethinkDB plugin for ElasticSearch: https://github.com/rethinkdb/elasticsearch-river-rethinkdb
RUN ["/elasticsearch/bin/plugin", "--install", "river-rethinkdb", "--url", "http://goo.gl/JmMwTf"]

# Install Admin UI
RUN ["/elasticsearch/bin/plugin", "--install", "mobz/elasticsearch-head"]

# Define working directory.
WORKDIR /data

# Define default command.
CMD ["/elasticsearch/bin/elasticsearch"]

# Expose ports.
#   - 9200: HTTP
#   - 9300: transport
EXPOSE 9200
EXPOSE 9300
