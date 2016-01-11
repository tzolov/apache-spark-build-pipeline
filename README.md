### Deprecated in favor of a generic and standard approach: [https://github.com/tzolov/bigtop-centos]. For more info read the [How-To Guide](http://blog.tzolov.net/2015/06/leverage-apache-bigtop-to-build-hadoop.html?view=sidebar).

Apache Spark Build Pipeline
===========================

Docker container, equipped with all necessary tools to Build Apache Spark and generate RPMs.
Tools installed include: CentOS6, [Java7](http://www.oracle.com/technetwork/java/javase/downloads/jre7-downloads-1880261.html), [Maven3](http://maven.apache.org/), [Git](https://github.com/), [Alien](http://en.wikipedia.org/wiki/Alien_(software)).

### 1. Installation

* Install [Docker](https://www.docker.io/).
* Configure Docker Host - Spark build requires at least 4GB of memory. (For [boot2docker](http://boot2docker.io/) host set 8GB of memory: `boot2docker delete; boot2docker init -m 8192; boot2docker up; export DOCKER_HOST=tcp://<Docker Host IP>:2375`)
* Download [trusted build](https://registry.hub.docker.com/u/tzolov/apache-spark-build-pipeline/) from public [Docker Registry](https://index.docker.io/): `docker pull tzolov/apache-spark-build-pipeline` (alternatively, you can build an image from Dockerfile: `docker build -t="tzolov/my-apache-spark-build-pipeline:1.0.0" github.com/tzolov/apache-spark-build-pipeline.git`)
* Start a container with the latest image: `docker run --rm -t -i -v /rpm:/rpm tzolov/apache-spark-build-pipeline /bin/bash`

### 2. Create Spark RPM
The [build_rpm.sh](https://github.com/tzolov/apache-spark-build-pipeline/blob/master/build_rpm.sh) utility simplifies the rpm creation process.
Alternatively you can build the rpm by hand follwoing the step by step instructions in the [Build Spark RPM by hand](https://github.com/tzolov/apache-spark-build-pipeline/blob/master/README.md#22-build-spark-rpm-by-hand) section. 

#### 2.1 Use Spark build_rpm.sh script
The `build_rpm.sh <Hadoop Version> <Spark Branch or Tag>` creates a new Spark rpm for the specified Spark and Hadoop versions (only Hadoop Yarn distros are supported). The build process applies a [spark_rpm.patch](https://github.com/tzolov/apache-spark-build-pipeline/blob/master/spark_rpm.patch) to allows no-root users to run spark and to include the spark examples into the rpm.
Created RPMs are stored into `/rpm/<Hadoop Version>` folder.  
(Note: When run the buld_rpm.sh script deletes the /spark folder and clones a fresh copy form the spark github repository!)

Example usages:

    # Build Spark 1.2.0 rpm for Apache Hadoop 2.2.0
    /build_rpm.sh 2.2.0 tags/v1.2.0 

	# Build Spark 1.2.0 rpm for PivotalHD2.0 (Hadoop2.2.0 complient)
    /build_rpm.sh 2.2.0-gphd-3.1.0.0 tags/v1.2.0
    
    # Build Spark master (last snapshot) rpm for PivotalHD2.1 (Hadoop2.2.0 complient)
    /build_rpm.sh 2.2.0-gphd-3.1.0.0 master
    
You can copy the `/rpm` folder over SSH to the Docker host or another server: `scp -rp /rpm docker@<Docker Host IP>: .`. In turn you can copy from the Docker Host into local folder: `scp -rp docker@<Docker Host IP>:rpm <Your Local Folder>`.
    
#### 2.2 Build Spark RPM by hand
Detail instructions how to synch the Spark git repository, apply optional patch, build the project and generate RPM. Inside a running apache-spark-build-pipeline container perform the following steps:

    # Update the local Git repository with the remote master
    cd /spark
    git pull --rebase

    # Pick a branch/tag to generate RPM for. 
    # Use `git  branch -a` or `git tag` to list the available branches/tags
    git checkout tags/v1.2.0

    # Patch to allows no-root user to run spark 
    # and to include the spark examples into the rpm
    git am < /spark_assembly.patch

    # Build SPARK and generate DEB packages
    mvn -Pyarn -Phadoop-2.2 -Pdeb -Dhadoop.version=2.2.0 -DskipTests -Ddeb.bin.filemode=755 clean package

    # Check the Deb package and convert it into RPM
    # dpkg-deb --info '/spark/assembly/target/spark_*.deb'
    alien -v -r /spark/assembly/target/spark_*.deb 

Generated spark RPM is saved in the folder where the `alien` is run.

### 3. Build Spark tar.gz (excluding Deb or Rpm)
If you only need a pre-build tar.gz (excluding deb or rpm) package like the those officially distributed or [Spark website](http://spark.apache.org/downloads.html) Then you can use the `make-distribution.sh` script.

    /spark/make-distribution.sh --with-hive --with-yarn --tgz --skip-java-test --hadoop 2.2.0 --name hadoop22

### 4. Use Spark RPMs

Prerequisites: Installed Hadoop2/Yarn cluster. For testing the Spark rpm you can easily install a single-node Hadoop cluster: [PivotalHD 2.0 Single Node VM](https://network.gopivotal.com/products/pivotal-hd)

#### 4.1 Install Spark RPM

Pre-build Spark RPMs for:

* Apache Hadoop 2.2.0:
| [Spark-1.1.0-RPM](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0/spark-1.1.0-3.noarch.rpm) |
* PivotalHD2.0 (Hadoop 2.2.0 based):
| [Spark-1.1.0-RPM](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0-gphd-3.0.1.0/spark-1.1.0-3.noarch.rpm) | 
* PivotalHD2.1 (Hadoop 2.2.0 based):
| [Spark-1.2.0-ALL-RPM](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0-gphd-3.1.0.0/spark-1.2.0-1.noarch.rpm) | 
| [Spark-1.2.0-CORE-RPM](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0-gphd-3.1.0.0/spark-1.2.0-1.noarch.rpm) | 
| [Spark-1.2.0-EXAMPLES-RPM](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0-gphd-3.1.0.0/spark-1.2.0-1.noarch.rpm) | 

On your Hadoop master node Install the rpm from a remote url: `sudo yum -y install <use one of the RPM urls above>` or from the local filesystem `sudo yum install ./spark-XXX.noarch.rpm`

#### 4.2 Run Spark Shell
Set the `HADOOP_CONF_DIR` to the location of hadoop-conf directory. For [PivotalHD](http://www.gopivotal.com/big-data/pivotal-hd) HADOOP_CONF_DIR defaults to `/etc/gphd/hadoop/conf`. For CDH it may default to `/etc/hadoop/conf`
Add spark-assembly jar to the `SPARK_SUBMIT_CLASSPATH`. The `spark-assembly-xxx.jar` located in `/usr/share/spark/jars/` folder.

    export HADOOP_CONF_DIR=/etc/gphd/hadoop/conf
    # export SPARK_SUBMIT_CLASSPATH=/usr/share/spark/jars/spark-assembly-1.1.0-hadoop2.2.0.jar
    /usr/share/spark/bin/spark-shell --master yarn-client
    
#### 4.3 Submit Sample Spark application: SparkPi

    export HADOOP_CONF_DIR=/etc/gphd/hadoop/conf
    # export SPARK_SUBMIT_CLASSPATH=/usr/share/spark/jars/spark-assembly-1.1.0-hadoop2.2.0.jar:/usr/share/spark/jars/spark-assembly-1.1.0-hadoop2.2.0.jar:

    /usr/share/spark/bin/spark-submit \
      --num-executors 10  \
      --master yarn-cluster \
      --class org.apache.spark.examples.SparkPi \
      /usr/share/spark/jars/spark-examples-1.1.0-hadoop2.2.0.jar 10
