Apache Spark Build Pipeline
===========================

Docker container, equipped with all necessary tools to Build Apache Spark and generate RPMs

### Installation

* Install [Docker](https://www.docker.io/).
* Download [trusted build](https://registry.hub.docker.com/u/tzolov/apache-spark-build-pipeline/) from public [Docker Registry](https://index.docker.io/): `docker pull tzolov/apache-spark-build-pipeline` (alternatively, you can build an image from Dockerfile: `docker build -t="tzolov/my-apache-spark-build-pipeline:1.0.0" github.com/tzolov/apache-spark-build-pipeline.git`)
* Configure Docker Host - Spark build requires at least 4GB of memory. In case of boot2docker host set 8GB of memory like this: `boot2docker delete; boot2docker init -m 8192`     
* Start a container with the latest image: `docker run -t -i tzolov/apache-spark-build-pipeline /bin/bash`

### Create Spark RPM
`Step by step instructions to build and generate Spark rpm` section below provides detail instructions of how to build a Spark RPM by hand. Tthe [build_rpm.sh](/build_rpm.sh) utility authomate and simplify the build process.

#### Build Spark RPM with the build_rpm.sh script
The [build_rpm.sh](/build_rpm.sh) script takes 2 input arguments `<Hadoop Version>` and `<Spark Branch\Tag>`. Then it clones a new copy Spark git project, builds a Spark DEB package and converts it into RPM. The RPM is stored in the `/rpm/<hadoop version>` folder. (Note: On each run this scripts deletes and clones again the /spark repository!)

Example usages:

    /build_rpm.sh 2.2.0 tags/v1.0.1 
     or  
    /build_rpm.sh 2.2.0-gphd-3.0.1.0 tags/v1.0.1
    
The result RPM is stored in the `/rpm/<Hadoop Version>` folder. You can copy the `/rpm` over SSH to the Host `scp -rp /rpm docker@<Docker Host IP>:`. In turn you can copy from the Docker Host into local folder: `scp -rp docker@<Docker Host IP>:rpm <Your Local Folder>`.
    
#### Build Spark RPM by hand
Detail instructions how to synch the Spark git repository, apply optional patch, build the project and generate RPM. Inside a running container perform the following steps.

    # Update the local Git repository with the remote master
    cd /spark
    git pull --rebase

    # Pick a branch/tag to generate RPM for. 
    # Use `git  branch -a` or `git tag` to list the available branches/tags
    git checkout tags/v1.0.1

    # Patch to allows no-root user to run spark 
    # and to include the spark examples into the rpm
    git am < spark_rpm.patch

    # Build SPARK and generate DEB packages
    mvn -Pyarn -Phadoop-2.2 -Pdeb -Dhadoop.version=2.2.0 -DskipTests clean package

    # Check the Deb package and convert it into RPM
    dpkg-deb --info '/spark/assembly/target/spark_*.deb'
    alien -v -r /spark/assembly/target/spark_*.deb 

Generated spark RPM is stored in the /spark folder (or the folder where the `alien` is run)

### Generate Spark Tar.gz distribution 
Spark project provides `make-distribution.sh` which can geneate project Tar.gz (excluding the Deb or Rpm)

    /spark/make-distribution.sh --with-hive --with-yarn --tgz --skip-java-test --hadoop 2.2.0 --name hadoop22

### Start the boot2docker host and set the ip:

    boot2docker up 
    boot2docker ip
      The VM's Host only interface IP address is: <Docker Host IP>
    export DOCKER_HOST=tcp://<Docker Host IP>:2375


### Install and Use Spark RPMs

#### Pre-build Spark RPMs links

+ Apache Hadoop 2.2.0:
[Spark 1.0.1](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0/spark-1.0.1-3.noarch.rpm) , 
[Spark Master Snapshot 17.07.2014](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0-gphd-3.0.1.0/spark-1.0.1-1.noarch.rpm)
+ PivotalHD2.0 (Hadoop 2.2.0 based):
[Spark 1.0.1](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0/spark-1.1.0%2BSNAPSHOT-1.noarch.rpm) ,
[Spark Master Snapshot 17.07.2014](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0-gphd-3.0.1.0/spark-1.1.0%2BSNAPSHOT-5.noarch.rpm) 

Install it directly from the remote rpm

    sudo yum -y install <use one of the RPM urls above>

Install fom the localy build rpm
    
    sudo yum install ./spark-XXX.noarch.rpm

Run Spark Shell

    export HADOOP_CONF_DIR=/etc/gphd/hadoop/conf
    export SPARK_SUBMIT_CLASSPATH=$SPARK_SUBMIT_CLASSPATH:/usr/share/spark/jars/spark-assembly-1.0.1-hadoop2.2.0.jar
    /usr/share/spark/bin/spark-shell --master yarn-client
    
Submit Sample Spark application: SparkPi

    export HADOOP_CONF_DIR=/etc/gphd/hadoop/conf
    export SPARK_SUBMIT_CLASSPATH=$SPARK_SUBMIT_CLASSPATH:/usr/share/spark/jars/spark-assembly-1.0.0-hadoop2.2.0.jar

    /usr/share/spark/bin/spark-submit \ 
      --num-executors 10  \ 
      --master yarn-cluster \ 
      --class org.apache.spark.examples.SparkPi \
      /usr/share/spark/jars/spark-examples-1.0.1-hadoop2.2.0.jar 10

