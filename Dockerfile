# Requires Docker 17.09 or later (multi stage builds)
#
# Orchestrator will look for a configuration file at /etc/orchestrator.conf.json.
# It will listen on port 3000.
# If not present a minimal configuration will be generated using the following environment variables:
#
# Default variables which can be used are:
#
# ORC_TOPOLOGY_USER (default: orchestrator): username used by orchestrator to login to MySQL when polling/discovering
# ORC_TOPOLOGY_PASSWORD (default: orchestrator):  password needed to login to MySQL when polling/discovering
# ORC_DB_HOST (default: orchestrator):  orchestrator backend MySQL host
# ORC_DB_PORT (default: 3306):  port used by orchestrator backend MySQL server
# ORC_DB_NAME (default: orchestrator): database named used by orchestrator backend MySQL server
# ORC_USER (default: orc_server_user): username used to login to orchestrator backend MySQL server
# ORC_PASSWORD (default: orc_server_password): password used to login to orchestrator backend MySQL server

FROM alpine:3.8

ENV GOPATH=/tmp/go

RUN apk --no-cache update \
 && apk --no-cache upgrade \
 && apk add --update --no-cache \
    libcurl \
    rsync \
    gcc \
    g++ \
    go \
    build-base \
    bash \
    git

RUN mkdir -p $GOPATH/src/github.com/github/orchestrator
WORKDIR $GOPATH/src/github.com/github/orchestrator
COPY . .
RUN bash build.sh -b \
 && rsync -av $(find /tmp/orchestrator-release -type d -name orchestrator -maxdepth 2)/ / \
 && rsync -av $(find /tmp/orchestrator-release -type d -name orchestrator-cli -maxdepth 2)/ / \
 && cp /usr/local/orchestrator/orchestrator-sample-sqlite.conf.json /etc/orchestrator.conf.json \
 && tar czf /orchestrator.tar.gz -C /usr/local/orchestrator .

FROM alpine:3.8

RUN apk add --no-cache \
    bash \
    curl \
    jq

EXPOSE 3000

COPY --from=0 /orchestrator.tar.gz /orchestrator.tar.gz
COPY --from=0 /etc/orchestrator.conf.json /etc/orchestrator.conf.json

RUN mkdir /usr/local/orchestrator \
 && chown 0:0 /usr/local/orchestrator \
 && chmod 0775 /usr/local/orchestrator

WORKDIR /usr/local/orchestrator
ADD docker/entrypoint.sh /entrypoint.sh
CMD /entrypoint.sh
