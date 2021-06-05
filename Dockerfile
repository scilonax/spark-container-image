FROM nvidia/cuda:11.0.3-runtime-ubuntu20.04

ARG spark_uid=185

RUN apt-get update && apt-get install -y --no-install-recommends openjdk-8-jdk openjdk-8-jre
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-amd64
ENV PATH $PATH:/usr/lib/jvm/java-1.8.0-openjdk-amd64/jre/bin:/usr/lib/jvm/java-1.8.0-openjdk-amd64/bin

RUN set -ex && \
    ln -s /lib /lib64 && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/examples && \
    mkdir -p /opt/spark/work-dir && \
    touch /opt/spark/RELEASE && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils \
    && apt-get install -y --no-install-recommends python libgomp1 telnet \
    && rm -rf /var/lib/apt/lists/*

COPY jars /opt/spark/jars
COPY bin /opt/spark/bin
COPY sbin /opt/spark/sbin
COPY kubernetes/dockerfiles/spark/entrypoint.sh /opt/
COPY examples /opt/spark/examples
COPY kubernetes/tests /opt/spark/tests
COPY data /opt/spark/data

ENV SPARK_HOME /opt/spark

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
RUN chmod +rx /sbin/tini

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +rx /usr/bin/tini

ENTRYPOINT [ "/opt/entrypoint.sh" ]

ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.2.0/hadoop-aws-3.2.0.jar /opt/spark/jars
RUN chmod 0644 /opt/spark/jars/hadoop-aws-3.2.0.jar
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.375/aws-java-sdk-bundle-1.11.375.jar /opt/spark/jars
RUN chmod 0644 /opt/spark/jars/aws-java-sdk-bundle-1.11.375.jar
ADD https://repo1.maven.org/maven2/ai/rapids/cudf/0.19.2/cudf-0.19.2-cuda11.jar /opt/spark/jars
RUN chmod 0644 /opt/spark/jars/cudf-0.19.2-cuda11.jar
ADD https://repo1.maven.org/maven2/com/nvidia/rapids-4-spark_2.12/0.5.0/rapids-4-spark_2.12-0.5.0.jar /opt/spark/jars
RUN chmod 0644 /opt/spark/jars/rapids-4-spark_2.12-0.5.0.jar
ADD https://raw.githubusercontent.com/apache/spark/master/examples/src/main/scripts/getGpusResources.sh /opt/spark/jars
RUN chmod 0755 /opt/spark/jars/getGpusResources.sh
ADD https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.0.2/spark-sql-kafka-0-10_2.12-3.0.2.jar /opt/spark/jars
RUN chmod 0644 /opt/spark/jars/spark-sql-kafka-0-10_2.12-3.0.2.jar
ADD https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/0.10.0.0/kafka-clients-0.10.0.0.jar /opt/spark/jars
RUN chmod 0644 /opt/spark/jars/kafka-clients-0.10.0.0.jar
ADD https://repo1.maven.org/maven2/org/apache/spark/spark-token-provider-kafka-0-10_2.12/3.0.2/spark-token-provider-kafka-0-10_2.12-3.0.2.jar /opt/spark/jars
RUN chmod 0644 /opt/spark/jars/spark-token-provider-kafka-0-10_2.12-3.0.2.jar
ADD https://repo1.maven.org/maven2/org/apache/commons/commons-pool2/2.6.2/commons-pool2-2.6.2.jar /opt/spark/jars
RUN chmod 0644 /opt/spark/jars/commons-pool2-2.6.2.jar
ADD https://repo1.maven.org/maven2/org/apache/spark/spark-streaming-kafka-0-10-assembly_2.12/3.0.2/spark-streaming-kafka-0-10-assembly_2.12-3.0.2.jar /opt/spark/jars
RUN chmod 0644 /opt/spark/jars/spark-streaming-kafka-0-10-assembly_2.12-3.0.2.jar

RUN mkdir ${SPARK_HOME}/python
RUN apt-get update && \
    apt install -y python3 python3-pip && \
    pip3 install --upgrade pip setuptools && \
    # Removed the .cache to save space
    rm -r /root/.cache && rm -rf /var/cache/apt/*

COPY python/pyspark ${SPARK_HOME}/python/pyspark
COPY python/lib ${SPARK_HOME}/python/lib

ENV PYTHONIOENCODING utf8

# Specify the User that the actual main process will run as
USER ${spark_uid}
