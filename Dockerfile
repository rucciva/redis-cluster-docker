
FROM redis:5.0.4

LABEL maintainer="rucciva@gmail.com" 

# Some Environment Variables
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Install system dependencies
RUN apt-get update -y \
    && apt-get install --no-install-recommends -y \
        locales \
        gettext \
        supervisor \
    # locale
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    # clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
    
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


# Prepare cluster
ARG REDIS_CLUSTER_FIRST_PORT
ENV REDIS_CLUSTER_FIRST_PORT ${REDIS_CLUSTER_FIRST_PORT:-7000}
ARG REDIS_CLUSTER_INSTANCES_COUNT
ENV REDIS_CLUSTER_INSTANCES_COUNT ${REDIS_CLUSTER_INSTANCES_COUNT:-6}

ENV REDIS_CLUSTER_CONF_DIR /redis-conf 
ENV REDIS_CLUSTER_DATA_DIR /redis-data
ENV REDIS_CLUSTER_CONF_FILE redis.conf 

COPY ./assets /tmp/assets
RUN cp /tmp/assets/build.sh /build.sh \
    && chmod +x /build.sh \
    && /build.sh \
    && cp /tmp/assets/entrypoint.sh /entrypoint.sh \
    && chmod +x /entrypoint.sh  \ 
    && rm -rf /tmp/assets

ENTRYPOINT ["/bin/bash"]
CMD ["/entrypoint.sh"]