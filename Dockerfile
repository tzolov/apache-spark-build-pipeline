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
    echo "--------------------- Install Maven 3 --------------------- "    ;\
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
    echo "------------- Clone Spark Git Repo and (pre)download some Maven dependencies ---------------" ;\
      cd / ;\
      git clone https://github.com/apache/spark.git ;\
      cd /spark ;\
      mvn -Pyarn -Phadoop-2.2 -Pdeb -Dhadoop.version=2.2.0 -DskipTests clean package ;\
      mvn -Pyarn -Phadoop-2.2 -Pdeb -Dhadoop.version=2.2.0-gphd-3.0.1.0 -DskipTests clean package ;\
      cd / ;\ 
    echo "---------------- Configure the build utilities -----------------" ;\      
      chmod a+x /build_rpm.sh 
# END RUN

# Sink with the Spark git repo
WORKDIR /spark

CMD git pull --rebase

## Prepare your Docker daemon (Spark build requires at least 4GB memory)
# boot2docker delete
# boot2docker init -m 8192
# boot2docker up 
# boot2docker ip
#   The VM's Host only interface IP address is: <Docker Host IP>
# export DOCKER_HOST=tcp://<Docker Host IP>:2375

## Create an image locally
# docker build --tag="tzolov/apache-spark-build-pipeline:1.0.0" ~/Development/projects/apache-spark-build-pipeline/

## Run a container with the latest image
# docker run -t -i tzolov/apache-spark-build-pipeline:tatest /bin/bash

## Generate an Spark RPM

## Update the local Git repository
# cd /spark
# git pull --rebase

## Pick a branch/tag to generate RPM for.
# git  branch -a or git tag
# git checkout tags/v1.0.1

## Apply a patch that allows no-root user to run spark and to include the spark examples into the rpm
# git am < spark_rpm.patch

## Build SPARK 	and generate DEB packages
# mvn -Pyarn -Phadoop-2.2 -Pdeb -Dhadoop.version=2.2.0 -DskipTests clean package

## Check the Deb package and convert it into RPM
# dpkg-deb --info '/spark/assembly/target/spark_*.deb'
# alien -v -r /spark/assembly/target/spark_*.deb 

## Automatic Spark RPM generation script. Note: scripts deletes and clones the /spark folders every time it is run
# /build_rpm.sh 2.2.0 tags/v1.0.1 or /build_rpm.sh 2.2.0-gphd-3.0.1.0 tags/v1.0.1

## Sink the generated rpms folder with the docker host
# scp -rp /rpm docker@<Docker Host IP>: 

## Copy rpms from the Docker host into Dropbox folder
# cd /Users/tzoloc/Dropbox/Public/spark; scp -rp docker@<Docker Host IP>:rpm .

## Generate Spark Tar.gz distro (excludes deb or rpm)
# /spark/make-distribution.sh --with-hive --with-yarn --tgz --skip-java-test --hadoop 2.2.0 --name hadoop22

## Create a patch for the last commit
# git format-patch -1 --stdout > rpm.patch

