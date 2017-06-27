# VERSION   0.1

FROM centos:latest
MAINTAINER Nehme Tohme <nehmetohme@gmail.com>

ADD cdh_files/install_cdh.sh /tmp/install_cdh.sh
ADD cdh_files/cdh.cfg /tmp/cdh.cfg

ENV TERM xterm
 ADD cdh_files/solr /tmp/solr
# ADD cdh_files/yarn-site.xml /etc/hadoop/conf/yarn-site.xml
 ADD cdh_files/hbase-site.xml /etc/hbase/conf.dist/hbase-site.xml

RUN chmod +x /tmp/install_cdh.sh && bash /tmp/install_cdh.sh

 # private and public mapping
 EXPOSE 2181:2181
 EXPOSE 8020:8020
 EXPOSE 8888:8888
 EXPOSE 11000:11000
 EXPOSE 11443:11443
 EXPOSE 9090:9090
 EXPOSE 8088:8088
 EXPOSE 19888:19888
 EXPOSE 9092:9092
 EXPOSE 16000:16000
 EXPOSE 16001:16001
 EXPOSE 42222:22
 EXPOSE 8042:8042
 EXPOSE 60010:60010
 EXPOSE 8983:8983
