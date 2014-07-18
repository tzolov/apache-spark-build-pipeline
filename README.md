apache-spark-build-pipeline
===========================

Docker container, equipped with all necessary tools to Build Apache Spark and generate RPMs

### Configure Docker Host with at least 4GB of memory
Spark build requires at least 4GB of memory. In case of boot2docker host the following 
snippet shows how to set 8GB of memory:

    boot2docker delete; boot2docker init -m 8192; 

Start the host and set the ip:

    boot2docker up 
    boot2docker ip
      The VM's Host only interface IP address is: <Docker Host IP>
    export DOCKER_HOST=tcp://<Docker Host IP>:2375
    
Start a container with the latest image

    docker run -t -i tzolov/apache-spark-build-pipeline /bin/bash

### Fast (authomatic) Spark RPM generation
The build_rpm.sh script authomates the rpm build process. The script takes `<hadoop version>` and `<spark branch\tag>` 
input parameters and stores the generated rpm in `/rpm/<hadoop version>` folder.
Note: scripts deletes and clones the /spark folders every time it is run.

Example usages:

    /build_rpm.sh 2.2.0 tags/v1.0.1 
     or  
    /build_rpm.sh 2.2.0-gphd-3.0.1.0 tags/v1.0.1
    
Output is stored in the `/rpm/<hadoop version>` folder. Sink the generated rpms folder with the docker host
over SSH: 

    scp -rp /rpm docker@<Docker Host IP>: 

Or coppy the Docker Host /rpms into local folder

    cd /Users/tzoloc/Dropbox/Public/spark; scp -rp docker@<Docker Host IP>:rpm .
    
### Manual Spark RPM generation 
Inside a running container perform the following steps.

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

### Build the Spark Build Pipeline image locally
You can build the spark-build-pipeline `Dockerfile` image yourself. Just clone the GitHub repository and
run `docker build`
 
    git clonehttps://github.com/tzolov/apache-spark-build-pipeline.git
    cd apache-spark-build-pipeline
    docker build --tag="tzolov/my-apache-spark-build-pipeline:1.0.0" .

### Some pre-build RPMS

+ Apache Hadoop 2.2.0:
[Spark 1.0.1 RPM](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0/spark-1.0.1-3.noarch.rpm)
[Spark master snapshot RPM](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0-gphd-3.0.1.0/spark-1.0.1-1.noarch.rpm)
+ PivotalHD 2.0:
[Spark 1.0.1 RPM](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0/spark-1.1.0%2BSNAPSHOT-1.noarch.rpm) 
[Spark master snapshot RPM](https://dl.dropboxusercontent.com/u/79241625/spark/rpm/2.2.0-gphd-3.0.1.0/spark-1.1.0%2BSNAPSHOT-5.noarch.rpm) 


### Install Spark RPM with Yarn Hadoop distribution

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

