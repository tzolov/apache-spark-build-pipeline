#!/bin/bash

# /build_rpm.sh 2.2.0 tags/v1.1.0
# /build_rpm.sh 2.2.0-gphd-3.0.1.0 tags/v1.1.0
# scp -rp /rpm docker@192.168.59.103:

if [ ! $# -eq 2 ]; then
   echo "Two arguments are expected but found: $#!"
   echo "Usage: /build_rpm.sh <Hadoop Distro> <Spark Git Branch/Tag>"
   echo "Examples: /build_rpm.sh 2.2.0 tags/v1.1.0 or /build_rpm.sh 2.2.0-gphd-3.0.1.0 master"
   exit 1
fi

HADOOP_DIST=$1
GIT_BRANCH=$2

echo "Hadoop distro: $HADOOP_DIST"
echo "Branch/Tag: $ GIT_BRANCH"

# Build Spark with desired Hadoop Distro and git branch
rm -rf /spark
cd /
git clone https://github.com/apache/spark.git
cd /spark
git checkout $GIT_BRANCH
git branch

# Add Examples jar to the RPM. Fix the bin permissions to allow non-root users start Spark
#git am < /spark_rpm.patch
git apply /spark_rpm.patch
git apply /spark_lib_symlink.patch

# Kick the build
mvn -Pyarn -Phadoop-2.2 -Pdeb -Dhadoop.version=$HADOOP_DIST -DskipTests -Ddeb.bin.filemode=755 clean package

# Convert DEB to RPM and store the result in /rpm/$HADOOP_DIST
mkdir -p /rpm/$HADOOP_DIST
cd /rpm/$HADOOP_DIST

# Uncomment if you want to verify the correctness of the deb package
# dpkg-deb --info '/spark/assembly/target/spark_*.deb'

alien -v -r /spark/assembly/target/spark_*.deb

