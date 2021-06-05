wget https://downloads.apache.org/spark/spark-3.0.2/spark-3.0.2-bin-hadoop3.2.tgz
tar xvfz spark-3.0.2-bin-hadoop3.2.tgz

export SPARK_HOME=spark-3.0.2-bin-hadoop3.2
export SPARK_DOCKER_IMAGE=rbsilva/spark
export SPARK_DOCKER_TAG=3.0.2-cuda11

pushd ${SPARK_HOME}
cp ../Dockerfile ./Dockerfile

# Optionally install additional jars into ${SPARK_HOME}/jars/

docker build . -t ${SPARK_DOCKER_IMAGE}:${SPARK_DOCKER_TAG}
docker push ${SPARK_DOCKER_IMAGE}:${SPARK_DOCKER_TAG}
popd
