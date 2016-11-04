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

# REMOVED && apt-get purge -y --auto-remove ca-certificates wget

# Microchip Tools (NetBeans) 32Bit Libraries and Required Dependency

RUN dpkg --add-architecture i386 \
    && apt-get update -y -qq \
    && apt-get install -y -qq --no-install-recommends \
    build-essential bzip2 cpio git p7zip-full python ragel sudo unzip vim zip \
    libc6:i386 libx11-6:i386 libxext6:i386 libstdc++6:i386 libexpat1:i386 \
    libxext6 libxrender1 libxtst6 libgtk2.0-0 libxslt1.1 libncurses5-dev \
    zlib1g zlib1g:i386

# REMOVED && apt-get upgrade -y -qq

# Additional Developer Tools (May Overlap Prior)

RUN apt-get install -y -qq --no-install-recommends \
    autoconf automake bison build-essential bzip2 cpio curl flex g++-multilib \
    gcc-multilib git p7zip-full python ragel sudo texinfo unzip vim zip \
    zlib1g-dev zlib1g-dev:i386

# Download and Install Microchip XC8, Current Version

RUN curl -fsSL -A "Mozilla/4.0" -o /tmp/xc8.run "http://www.microchip.com/mplabxc8linux" \
    && chmod a+x /tmp/xc8.run \
    && /tmp/xc8.run --mode unattended --unattendedmodeui none \
        --netservername localhost --LicenseType FreeMode --prefix /opt/microchip/xc8 \
    && rm /tmp/xc8.run

ENV PATH /opt/microchip/xc8/bin:$PATH

# Download and Install Microchip XC16, Current Version

RUN curl -fsSL -A "Mozilla/4.0" -o /tmp/xc16.run \
       "http://www.microchip.com/mplabxc16linux" \
    && chmod a+x /tmp/xc16.run \
    && /tmp/xc16.run --mode unattended --unattendedmodeui none \
        --netservername localhost --LicenseType FreeMode --prefix /opt/microchip/xc16 \
    && rm /tmp/xc16.run

ENV PATH /opt/microchip/xc16/bin:$PATH

# Download and Install Microchip XC32, Current Version

RUN curl -fsSL -A "Mozilla/4.0" -o /tmp/xc32.run \
       "http://www.microchip.com/mplabxc32linux" \
    && chmod a+x /tmp/xc32.run \
    && /tmp/xc32.run --mode unattended --unattendedmodeui none \
        --netservername localhost --LicenseType FreeMode --prefix /opt/microchip/xc32 \
    && rm /tmp/xc32.run

ENV PATH /opt/microchip/xc32/bin:$PATH

# Download and Install Microchip MPLABX, Current Version

RUN curl -fsSL -A "Mozilla/4.0" -o /tmp/mplabx-installer.tar \
       "http://www.microchip.com/mplabx-ide-linux-installer" \
    && tar xf /tmp/mplabx-installer.tar && rm /tmp/mplabx-installer.tar \
    && USER=root ./*-installer.sh --nox11 \
        -- --unattendedmodeui none --mode unattended --installdir /opt/microchip/mplabx \
    && rm ./*-installer.sh

ENV PATH /opt/microchip/mplabx/mplab_ide/bin:$PATH

VOLUME /tmp/.X11-unix

#ENV PATH /opt/microchip/mplabx/mplab_ide/bin:/opt/microchip/xc8/bin:/opt/microchip/xc16/bin:/opt/microchip/xc32/bin:$PATH

# Download and Install Open Source Archive Build Artifacts, XC16

RUN curl -fsSL -A "Mozilla/4.0" -o artifacts.zip \
    "https://gitlab.com/mmitchel/microchip-xc16/builds/artifacts/build_linux/download?job=build_xc16" \
    && unzip artifacts.zip \
    && mv /opt/microchip/xc16/bin/bin/elf-cc1 /opt/microchip/xc16/bin/bin/elf-cc1.orig \
    && cp install/bin/bin/elf-cc1 /opt/microchip/xc16/bin/bin/elf-cc1 \
    && chmod +x /opt/microchip/xc16/bin/bin/elf-cc1 \
    && rm -fr artifacts.zip build_output.txt install

# Container Tool Version Reports to Build Log

#CMD ["/opt/microchip/mplabx/mplab_ide/bin/mplab_ide"]

RUN [ -x /opt/microchip/xc8/bin/xc8 ] && xc8 --ver
RUN [ -x /opt/microchip/xc16/bin/xc16-gcc ] && xc16-gcc --version
RUN [ -x /opt/microchip/xc32/bin/xc32-gcc ] && xc32-gcc --version

# Entry Point for Local User ID Mapping, LOCAL_USER_ID
# docker run -it -e LOCAL_USER_ID=`id -u $USER` docker-image

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh && mkdir -p /MPLABXProjects
VOLUME /MPLABXProjects
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
