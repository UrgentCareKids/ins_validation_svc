FROM flyway/flyway:8.5.0
ARG DEBIAN_FRONTEND=noninteractive
USER root
RUN apt-get update && \
    apt-get -y install postgresql=12+214ubuntu0.1
COPY scripts/ /scripts
# COPY seed /seed
USER flyway