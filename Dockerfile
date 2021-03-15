FROM adoptopenjdk/openjdk11:debianslim-jre
LABEL org.opencontainers.image.authors="Andreas Wachter <buddyspencer@protonmail.com>"
# upgrade all packages since alpine jre8 base image tops out at 8u212
RUN apt-get update; apt-get upgrade -y
RUN apt-get install -y curl openssl imagemagick lsof bash wget git jq mariadb-client tzdata rsync nano sudo knockd ttf-dejavu dos2unix

RUN set -ex; curl -o /usr/local/bin/su-exec.c https://raw.githubusercontent.com/ncopa/su-exec/master/su-exec.c; fetch_deps='gcc libc-dev'; apt-get update; apt-get install -y --no-install-recommends $fetch_deps; rm -rf /var/lib/apt/lists/*; gcc -Wall /usr/local/bin/su-exec.c -o/usr/local/bin/su-exec; chown root:root /usr/local/bin/su-exec; chmod 0755 /usr/local/bin/su-exec; rm /usr/local/bin/su-exec.c; apt-get purge -y --auto-remove $fetch_deps
RUN addgroup --gid 1000 minecraft && adduser --shell /bin/false -u 1000 --gid 1000 --home /home/minecraft --disabled-password --gecos '' minecraft && mkdir -m 777 /data && chown minecraft:minecraft /data /home/minecraft
COPY files/sudoers* /etc/sudoers.d
EXPOSE 25565 25575
# hook into docker BuildKit --platform support
# see https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETOS=linux
ARG TARGETARCH=arm64
ARG TARGETVARIANT=""
ARG EASY_ADD_VER=0.7.1
ADD https://github.com/itzg/easy-add/releases/download/${EASY_ADD_VER}/easy-add_${TARGETOS}_${TARGETARCH}${TARGETVARIANT} /usr/bin/easy-add
RUN chmod +x /usr/bin/easy-add
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT}  --var version=1.2.0 --var app=restify --file {{.app}} --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT}  --var version=1.4.7 --var app=rcon-cli --file {{.app}} --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT}  --var version=0.7.1 --var app=mc-monitor --file {{.app}} --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT}  --var version=1.5.0 --var app=mc-server-runner --file {{.app}} --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT}  --var version=0.1.1 --var app=maven-metadata-release --file {{.app}} --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz
COPY mcstatus /usr/local/bin
VOLUME ["/data"]
COPY server.properties /tmp/server.properties
COPY log4j2.xml /tmp/log4j2.xml
WORKDIR /data
ENV UID=1000 GID=1000  JVM_XX_OPTS="-XX:+UseG1GC" MEMORY="1G" TYPE=VANILLA VERSION=LATEST ENABLE_RCON=true RCON_PORT=25575 RCON_PASSWORD=minecraft SERVER_PORT=25565 ONLINE_MODE=TRUE SERVER_NAME="Dedicated Server" ENABLE_AUTOPAUSE=false AUTOPAUSE_TIMEOUT_EST=3600 AUTOPAUSE_TIMEOUT_KN=120 AUTOPAUSE_TIMEOUT_INIT=600 AUTOPAUSE_PERIOD=10 AUTOPAUSE_KNOCK_INTERFACE=eth0
COPY start* /
COPY health.sh /
ADD files/autopause /autopause
RUN dos2unix /start* && chmod +x /start*
RUN dos2unix /health.sh && chmod +x /health.sh
RUN dos2unix /autopause/* && chmod +x /autopause/*.sh
ENTRYPOINT [ "/start" ]
HEALTHCHECK --start-period=1m CMD /health.sh
