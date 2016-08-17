FROM debian:jessie

MAINTAINER Michael Mitchell <mmitchel@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# General Startup Environment

ENV GOSU_VERSION 1.9
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends curl ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

#   && apt-get purge -y --auto-remove ca-certificates wget

# Microchip Tools Require i386 Compatability as Dependency

RUN dpkg --add-architecture i386 \
    && apt-get update -yq \
    && apt-get upgrade -yq \
    && apt-get install -yq --no-install-recommends build-essential bzip2 cpio git p7zip-full python ragel unzip \
    libc6:i386 libx11-6:i386 libxext6:i386 libstdc++6:i386 libexpat1:i386 \
    libxext6 libxrender1 libxtst6 libgtk2.0-0 libxslt1.1 libncurses5-dev

# Download and Install XC8 Compiler, Current Version

RUN curl -fSL -A "Mozilla/4.0" -o /tmp/xc8.run "http://www.microchip.com/mplabxc8linux" \
    && chmod a+x /tmp/xc8.run \
    && /tmp/xc8.run --mode unattended --unattendedmodeui none \
        --netservername localhost --LicenseType FreeMode --prefix /opt/microchip/xc8 \
    && rm /tmp/xc8.run

ENV PATH $PATH:/opt/microchip/xc8/bin

# Download and Install XC16 Compiler, Current Version

RUN curl -fSL -A "Mozilla/4.0" -o /tmp/xc16.run "http://www.microchip.com/mplabxc16linux" \
    && chmod a+x /tmp/xc16.run \
    && /tmp/xc16.run --mode unattended --unattendedmodeui none \
        --netservername localhost --LicenseType FreeMode --prefix /opt/microchip/xc16 \
    && rm /tmp/xc16.run

ENV PATH $PATH:/opt/microchip/xc16/bin

# Download and Install XC32 Compiler, Current Version

RUN curl -fSL -A "Mozilla/4.0" -o /tmp/xc32.run "http://www.microchip.com/mplabxc32linux" \
    && chmod a+x /tmp/xc32.run \
    && /tmp/xc32.run --mode unattended --unattendedmodeui none \
        --netservername localhost --LicenseType FreeMode --prefix /opt/microchip/xc32 \
    && rm /tmp/xc32.run

ENV PATH $PATH:/opt/microchip/xc32/bin

# Download and Install MPLABX IDE, Current Version

RUN curl -fSL -A "Mozilla/4.0" -o /tmp/mplabx-installer.tar "http://www.microchip.com/mplabx-ide-linux-installer" \
    && tar xf /tmp/mplabx-installer.tar && rm /tmp/mplabx-installer.tar \
    && USER=root ./*-installer.sh --nox11 \
        -- --unattendedmodeui none --mode unattended --installdir /opt/microchip/mplabx \
    && rm ./*-installer.sh

ENV PATH $PATH:/opt/microchip/mplabx/mplab_ide/bin

VOLUME /tmp/.X11-unix

#CMD ["/opt/microchip/mplabx/mplab_ide/bin/mplab_ide"]

# Container Tool Version Reports to Build Log

RUN [ -x /opt/microchip/xc8/bin/xc8 ] && xc8 --ver
RUN [ -x /opt/microchip/xc16/bin/xc16-gcc ] && xc16-gcc --version
RUN [ -x /opt/microchip/xc32/bin/xc32-gcc ] && xc32-gcc --version

# Entry Point for Local User ID Mapping, LOCAL_USER_ID
# docker run -it -e LOCAL_USER_ID=`id -u $USER` docker-image

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash"]
