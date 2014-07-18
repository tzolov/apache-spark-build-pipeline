apache-spark-build-pipeline
===========================

Docker container, equipped with all necessary tools to Build Apache Spark and generate RPMs
### 1. Manual Spark RPM generation 

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
### 2. Fast (authomatic) Spark RPM generation
The build_rpm.sh script authomates the rpm build process. The script takes `<hadoop version>` and `<spark branch\tag>` 
input parameters and stores the generated rpm in `/rpm/<hadoop version>` folder.
Note: scripts deletes and clones the /spark folders every time it is run.

Example usages:

    /build_rpm.sh 2.2.0 tags/v1.0.1 
    (or)  /build_rpm.sh 2.2.0-gphd-3.0.1.0 tags/v1.0.1
    
Output is stored in the `/rpm/<hadoop version>` folder. Sink the generated rpms folder with the docker host
over SSH: 

    scp -rp /rpm docker@<Docker Host IP>: 

Or coppy the Docker Host /rpms into local folder

    cd /Users/tzoloc/Dropbox/Public/spark; scp -rp docker@<Docker Host IP>:rpm .

### 3. Generate Spark Tar.gz distro
Spark project provides `make-distribution.sh` which can geneate project Tar.gz (excluding the Deb or Rpm)

    /spark/make-distribution.sh --with-hive --with-yarn --tgz --skip-java-test --hadoop 2.2.0 --name hadoop22

### 4. Prepare your Docker daemon (Spark build requires at least 4GB memory)

    boot2docker delete
    boot2docker init -m 8192
    boot2docker up 
    boot2docker ip
      The VM's Host only interface IP address is: <Docker Host IP>
    export DOCKER_HOST=tcp://<Docker Host IP>:2375

#### 4.1 Create an Spark Build Pipeline image locally
    
    git clonehttps://github.com/tzolov/apache-spark-build-pipeline.git
    cd apache-spark-build-pipeline
    docker build --tag="tzolov/my-apache-spark-build-pipeline:1.0.0" .

#### 4.2 Run a container with the latest image

    docker run -t -i tzolov/apache-spark-build-pipeline:tatest /bin/bash
