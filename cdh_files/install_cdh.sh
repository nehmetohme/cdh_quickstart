#!/bin/bash

source /tmp/cdh.cfg

#######################################
# All error messages will go through.  
# Globals:
#   None:
# Arguments:
#   error_log_entry:
# Returns:
#   None
#######################################
log_error() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: [ERROR] $@" | tee -a $LOG_FILE
  exit 1
}

#######################################
# All warning messages will go through.  
# Globals:
#   None:
# Arguments:
#   error_log_entry:
# Returns:
#   None
#######################################
log_warn() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: [WARN] $@" | tee -a $LOG_FILE
}

#######################################
# All info log messages will go through.  
# Globals:
#   None:
# Arguments:
#   info_log_entry:
# Returns:
#   None
#######################################
log_info() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: [INFO] $@" | tee -a $LOG_FILE
}

#######################################
# All debug log messages will go through.  
# Globals:
#   None:
# Arguments:
#   debug_log_entry:
# Returns:
#   None
#######################################
log_debug() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: [DEBUG] $@" | tee -a $LOG_FILE
}

#######################################
# Configure Cloudera Repo
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
configure_repo () {
  log_info "Configuring CDH and CM Repo"
  curl https://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/cloudera-cdh5.repo -o /etc/yum.repos.d/cdh.repo >>$LOG_FILE 2>&1 || log_error "Unable to configure CDH Repo"
  curl https://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo -o /etc/yum.repos.d/cloudera-manager.repo >>$LOG_FILE 2>&1 || log_error "Unable to configure CM Repo"
}

#######################################
# Prerequisites Software
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
prerequisite_software () {
  log_info "Installing prerequisite tools"
  yum install -y  sudo  >>$LOG_FILE 2>&1 || log_error "Unable to install misc tools"
  
  log_info "Install Oracle JDK"
  yum -y install oracle-j2sdk1.7.x86_64 >>$LOG_FILE 2>&1 || log_error "Failed to install Oracle"
 
  log_info "Settings Java Alternatives"
  alternatives --install /usr/bin/java java /usr/java/jdk1.7.0_67-cloudera/bin/java 100 >>$LOG_FILE 2>&1 || log_error "Unable to set alternatives for java"
  alternatives --install /usr/bin/javac javac /usr/java/jdk1.7.0_67-cloudera/bin/javac 100 >>$LOG_FILE 2>&1 || log_error "Unable to set alternatives for javac"
  alternatives --install /usr/bin/jar jar /usr/java/jdk1.7.0_67-cloudera/bin/jar 100 >>$LOG_FILE 2>&1 || log_error "Unable to set alternatives for jar"
  alternatives --set java /usr/java/jdk1.7.0_67-cloudera/bin/java >>$LOG_FILE 2>&1 || log_error  "Unable to set alternatives for java"
  alternatives --set javac /usr/java/jdk1.7.0_67-cloudera/bin/javac >>$LOG_FILE 2>&1 || log_error "Unable to set alternatives for javac"
  alternatives --set jar /usr/java/jdk1.7.0_67-cloudera/bin/jar >>$LOG_FILE 2>&1 || log_error "Unable to set alternatives for jar"

  log_info "Exporting Java Home"
  export JAVA_HOME=/usr/java/jdk1.7.0_67-cloudera/ >>$LOG_FILE 2>&1 || log_error "Unable to set Java Home"
  export PATH=$PATH:$JAVA_HOME/bin >>$LOG_FILE 2>&1 || log_warn "Failed to adapt PATH"
  echo 'JAVA_HOME="/usr/java/jdk1.7.0_67-cloudera/"' >> /etc/environment >>$LOG_FILE 2>&1 || log_error "Failed to add JAVA_HOME to /etc/environment"
  source /etc/environment >>$LOG_FILE 2>&1 || log_error "Failed to retrieve the latest env variable from /etc/environment"
}

#######################################
# Install and Configure Zookeeper
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
install_configure_zookeeper () {

  log_info "Installing Zookeeper"
  yum -y install zookeeper-server >>$LOG_FILE 2>&1 || log_error "Unable to install zookeeper-server"

  mkdir /var/lib/zookeeper
  chown zookeeper:zookeeper /var/lib/zookeeper
  
  
  log_info "Adapting the Max Client Connections Limit for Zookeeper"
  sed -i '/maxClientCnxns/s/=.*/=0/' /etc/zookeeper/conf/zoo.cfg || log_warn "Unable to configure maxClientCnxns on Zookeeper"
  
  log_info "Initialize Zookeeper"
  service zookeeper-server init --force >>$LOG_FILE 2>&1 || log_error "Unable to init zookeeper-server"
  service zookeeper-server start >>$LOG_FILE 2>&1 || log_error "Unable to start zookeeper-server"
  service zookeeper-server stop >>$LOG_FILE 2>&1 || log_error "Unable to stop zookeeper-server" 
  
}

#######################################
# Install Impala
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
install_impala () {
  log_info "Install impala, catalog server, impala state-store"
  yum -y install impala impala-server impala-state-store impala-catalog impala-shell >>$LOG_FILE 2>&1 || log_error "Unable to install impala"

}

#######################################
# Install hadoop conf pseudo
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
install_pseudo_conf () {
  log_info "Install Hadoop Pseudo Conf"
  yum -y install hadoop-conf-pseudo >>$LOG_FILE 2>&1 || log_error "Unable to install hadoop configuration"

}

#######################################
# Install Hbase
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
install_hbase () {
  log_info "Install HBASE"
  yum -y install hbase hbase-thrift hbase-master hbase-regionserver >>$LOG_FILE 2>&1 || log_error "Unable to install HBASE"

  log_info "Use Zookeeper Standalone"
  echo "export HBASE_MANAGES_ZK=true" >> /etc/hbase/conf.dist/hbase-env.sh
}

#######################################
# Install Hadoop Encryption
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
install_hdfs_encryption () {
  log_info "Install HDFS Encryption"
  yum -y install hadoop-kms hadoop-kms-server >>$LOG_FILE 2>&1 || log_error "Unable to install HDFS Encryption"
}

#######################################
# Install Orchestration
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
install_oozie () {
  log_info "Install and Configure Oozie"
  yum -y install oozie oozie-client >>$LOG_FILE 2>&1 || log_warn "Unable to install Oozie"

  log_info "Configuring Oozie"
  alternatives --set oozie-tomcat-conf /etc/oozie/tomcat-conf.http >>$LOG_FILE 2>&1 || log_warn "Failed to create the symbolic link for oozie-tomcat-conf"

#  sudo -E -u hdfs hdfs dfs -mkdir /user/oozie >>$LOG_FILE 2>&1 || log_warn "Failed to create /user/oozie"
#  hdfs hdfs dfs -chown oozie:oozie /user/oozie >>$LOG_FILE 2>&1 || log_warn "Failed to adapt the permissions on /user/oozie"
  oozie-setup sharelib create -fs hdfs://localhost -locallib /usr/lib/oozie/oozie-sharelib-yarn >>$LOG_FILE 2>&1 || log_warn "Failed to create the sharelib folder"

 log_info "Oozie Database Initialization"
 oozie-setup db create -run >>$LOG_FILE 2>&1 || log_warn "Unable to initialize Oozie Database"
}

#######################################
# Install DataWarehouse and ETL
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
install_datawarehouse () {
  log_info "Installing hive, hue and pig"
  yum -y install hive pig hue >>$LOG_FILE 2>&1 || log_error "Unable to install hive, pig and hue"
}

#######################################
# Prepare HDFS
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
prepare_hdfs () {
  log_info "Format Namenode"
  sudo -E -u hdfs hdfs namenode -format >>$LOG_FILE 2>&1 || log_error "Failed to format the Namenode"
 
  log_info "Starting HDFS Namenode" 
  #/etc/init.d/hadoop-hdfs-namenode start >>$LOG_FILE 2>&1 || log_error "Unable to start Namenode"
  /etc/init.d/hadoop-hdfs-namenode start || log_error "Unable to start Namenode"

  log_info "Starting HDFS SecondaryNamenode"
  /etc/init.d/hadoop-hdfs-secondarynamenode start >>$LOG_FILE 2>&1 || log_error "Unable to start SecondaryNamenode"

  log_info "Starting HFDS Datanode"
  /etc/init.d/hadoop-hdfs-datanode start >>$LOG_FILE 2>&1 || log_error "Unable to start datanode"
 
  log_info "Create Hadoop required directories" 
  /usr/lib/hadoop/libexec/init-hdfs.sh >>$LOG_FILE 2>&1 || log_error "Unable to create the required Hadoop directories" 
  
  log_info "Creating HDFS Directories"
  sudo -E -u hdfs hdfs dfs -mkdir -p /user/hadoop >>$LOG_FILE 2>&1 || log_warn "Unable to create /user/hadoop directory"
  sudo -E -u hdfs hdfs dfs -chown hadoop /user/hadoop >>$LOG_FILE 2>&1 || log_warn "Unable to adapt the permissions on /user/hadoop directory"
  sudo -E -u hdfs hdfs dfs -mkdir -p       /tmp >>$LOG_FILE 2>&1 || log_warn "Unable to create /tmp directory"
  sudo -E -u hdfs hdfs dfs -chmod g+w   /tmp >>$LOG_FILE 2>&1 || log_warn "Unable to adapt the permissions on /tmp/"
  sudo -E -u hive hdfs dfs -mkdir -p       /user/hive/warehouse >>$LOG_FILE 2>&1 || log_warn "Unable to create /user/hive/warehouse directory"
  sudo -E -u hive hdfs dfs -chmod g+w   /user/hive/warehouse >>$LOG_FILE 2>&1 || log_warn "Unable to adapt the permissions on /user/hive/warehouse"
  sudo -E -u hdfs hdfs dfs -mkdir -p /hbase >>$LOG_FILE 2>&1 || log_warn "Unable to adapt the permissions on /hbase/"
  sudo -E -u hdfs hdfs dfs -chown hbase /hbase >>$LOG_FILE 2>&1 || log_warn "Unable to adapt the permissions on /hbase" 

  log_info "Verify HDFS"
  sudo -E -u hdfs hdfs dfs -ls -R / >>$LOG_FILE 2>&1 || log_error "Unable to list HDFS contents"
}

#######################################
# Prepare YARN
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
start_yarn () {
  log_info "start YARN"
  service hadoop-yarn-resourcemanager start >>$LOG_FILE 2>&1 || log_warn "Unable to start Resource Manager"
  service hadoop-yarn-nodemanager start >>$LOG_FILE 2>&1 || log_warn "Unable to start NodeManager"
  service hadoop-mapreduce-historyserver start >>$LOG_FILE 2>&1 || log_warn "Unable to start History Server"
}

#######################################
# Hue Configuration
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
configure_hue () {
  log_info "Create the Secret Key"
  sed -i 's/secret_key=/secret_key=_qpbdxoewsqlkhztybvfidtvwekftusgdlofbcfghaswuicmqp/g' /etc/hue/conf/hue.ini >>$LOG_FILE 2>&1 || log_warn "Unable to set hue secret key"
}


#######################################
# Install Solr
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
install_configure_solr () {
  yum -y install solr-server hue-search >>$LOG_FILE 2>&1 || log_warn "Failed to install solr and hue search"
  sudo -E -u hdfs hdfs dfs -mkdir -p /solr >>$LOG_FILE 2>&1 || log_warn "Failed to create /solr hdfs folder"
  sudo -E -u hdfs hdfs dfs -chown solr /solr >>$LOG_FILE 2>&1 || log_warn "Failed to adapt permissions on /solr"
  mv /tmp/solr /etc/default/solr >>$LOG_FILE 2>&1  
  solrctl init >>$LOG_FILE 2>&1 || log_warn "Failed to initialize solr"
}

#######################################
# Start Services
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
start_services () {
  service hbase-master start >>$LOG_FILE 2>&1 || log_warn "Failed to start HBase Master"
}

#######################################
# Start Services
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
start_services () {
  log_info "Start Services"

echo "Start Zookeeper"
for srvc in $(ls /etc/init.d/* | egrep -v 'RE|fun|net'|awk -F"/" '{print $4}')
do 
  log_info "Starting $srvc"
  service $srvc start  || log_warn "Unable to start $srvc"
done

nohup hiveserver2 >>$HIVE_LOG 2>&1  &
}

	
################################################################################
# MAIN

configure_repo
prerequisite_software
install_configure_zookeeper
#install_impala
install_pseudo_conf
prepare_hdfs
install_hbase
install_hdfs_encryption
install_oozie
install_datawarehouse
configure_hue
start_yarn
install_configure_solr
start_services
