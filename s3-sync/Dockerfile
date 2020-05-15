# Builds a docker image for Kafka Connect with the S3 plugin
# From https://github.com/dwp/docker-kafka-connect-s3/blob/master/Dockerfile

FROM confluentinc/cp-kafka-connect-base
ENV CONFLUENT_MAJOR_VERSION=5
ENV CONFLUENT_MINOR_VERSION=0
ENV CONFLUENT_PATCH_VERSION=1
ENV CONFLUENT_DEB_VERSION=1
ENV COMPONENT=kafka-connect

    RUN echo "===> Installing S3 connector ... ..." \
        && apt-get -qq update \
        && apt-get install -y \
            confluent-kafka-connect-storage-common=${CONFLUENT_VERSION}${CONFLUENT_PLATFORM_LABEL}-${CONFLUENT_DEB_VERSION} \
            confluent-kafka-connect-s3=${CONFLUENT_VERSION}${CONFLUENT_PLATFORM_LABEL}-${CONFLUENT_DEB_VERSION} \
        && apt-get autoremove -y \
        && echo "===> Upgrading ..."  \
        && apt-get dist-upgrade -y \
        && echo "===> Cleaning up ..."  \
        && apt-get clean && rm -rf /tmp/* /var/lib/apt/lists/*