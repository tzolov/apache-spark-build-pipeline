FROM centos:centos6

MAINTAINER Christian Tzolov "https://github.com/tzolov"

USER root

ENV JAVA_HOME /usr/java/jdk1.7.0_65
ENV MAVEN_OPTS -Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m
ENV MAVEN_HOME /usr/local/maven
ENV PATH $PATH:$MAVEN_HOME/bin

ADD spark_rpm.patch /spark_rpm.patch
ADD build_rpm.sh /build_rpm.sh

RUN \
    echo "--------------------- Install GIT and OS Utilities --------------------- "    ;\
      yum -y install git wget which unzip tar ;\
    echo "--------------------- Install JDK 7 --------------------- "    ;\
      wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u65-b17/jdk-7u65-linux-x64.rpm" ;\
      yum -y install ./jdk-7u65-linux-x64.rpm; java -version ;\
      rm ./jdk-7u65-linux-x64.rpm ;\
    echo "--------------------- Install Maven --------------------- "    ;\
      curl -o /tmp/maven.tar.gz http://ftp.nluug.nl/internet/apache/maven/maven-3/3.2.2/binaries/apache-maven-3.2.2-bin.tar.gz  ;\
      mkdir $MAVEN_HOME  ;\
      tar -C $MAVEN_HOME -xzvf /tmp/maven.tar.gz --strip 1  ;\
      rm /tmp/maven.tar.gz ;\
    echo "---------------------  Install Alien --------------------- " ;\
      rpm -iUvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm ;\
      yum -y install dpkg python rpm-build make m4 gcc-c++ autoconf automake redhat-rpm-config mod_dav_svn mod_ssl mod_wsgi perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker ;\
      git clone git://git.kitenet.net/alien ;\
      cd /alien/; perl Makefile.PL; make; make install; cd / ;\
      rm -Rf /alien ;\
      yum -y erase perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker gcc-c++ m4 autoconf automake ;\      
    echo "---------------- Clone Spark and (pre)populate the local Maven Repository -----------------" ;\
      cd / ;\
      git clone https://github.com/apache/spark.git ;\
      cd /spark ;\
      mvn -Pyarn -Phadoop-2.2 -Pdeb -Dhadoop.version=2.2.0 -DskipTests clean package ;\
      mvn -Pyarn -Phadoop-2.2 -Pdeb -Dhadoop.version=2.2.0-gphd-3.0.1.0 -DskipTests clean package ;\
      mvn clean ;\
      cd / ;\ 
    echo "---------------- Configure some build utilities -----------------" ;\      
      chmod a+x /build_rpm.sh 
# END RUN


# boot2docker delete
# boot2docker init -m 8192
# boot2docker up 
# boot2docker ip
#   The VM's Host only interface IP address is: 192.168.59.103
# export DOCKER_HOST=tcp://192.168.59.103:2375
# docker build --tag="tzolov/spark-build-pipeline:1.0.0" ~/Development/spark-builder/
# docker run -t -i tzolov/spark-build-pipeline:1.0.0 /bin/bash

# cd /spark
# git  branch -a or git tag
# git checkout tags/v1.0.1
# wget https://dl.dropboxusercontent.com/u/79241625/spark/spark_rpm.patch
# git am < spark_rpm.patch
# mvn -Pyarn -Phadoop-2.2 -Pdeb -Dhadoop.version=2.2.0 -DskipTests clean package
# dpkg-deb --info '/spark/assembly/target/spark_*.deb'
# alien -v -r /spark/assembly/target/spark_*.deb 

# /build_rpm.sh 2.2.0 tags/v1.0.1
# /build_rpm.sh 2.2.0-gphd-3.0.1.0 tags/v1.0.1
# scp -rp /rpm docker@192.168.59.103: 
# cd /Users/tzoloc/Dropbox/Public/spark; scp -rp docker@192.168.59.103:rpm .

# /spark/make-distribution.sh --with-hive --with-yarn --tgz --skip-java-test --hadoop 2.2.0 --name hadoop22



# Create a patch for the last commit
# git format-patch -1 --stdout > rpm.patch

