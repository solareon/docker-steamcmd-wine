# Set the base image
FROM ubuntu:22.04 as build_stage

# Prevent tzdata apt-get installation from asking for input.
ENV DEBIAN_FRONTEND=noninteractive

# Set Label
LABEL maintainer="https://github.com/solareon"
ARG PUID=1000

# Set environment variables
ENV USER steam
ENV HOMEDIR "/home/${USER}"
ENV STEAMCMDDIR "${HOMEDIR}/steamcmd"

# Set working directory
WORKDIR $HOMEDIR

# Insert Steam prompt answers
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo steam steam/question select "I AGREE" | debconf-set-selections \
 && echo steam steam/license note '' | debconf-set-selections

# Update the repository and install SteamCMD, libs, and Wine
RUN dpkg --add-architecture i386 \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends apt-utils \
    && apt-get install -y --no-install-recommends --no-install-suggests \
		locales \
		ca-certificates \
		nano \
		curl \
		wget \
		libc6 \
		libstdc++6 \
		lib32gcc-s1 \
		nuget \
		git \
		unzip \
		wine-stable \
		wine32 \
		wine64 \
		libwine \
		libwine:i386 \
		fonts-wine \
    && apt-get upgrade -y \
    && apt-get install -y tzdata \
    && apt-get install sudo -y \
    && apt-get autoremove --purge -y \
    && apt-get autoclean -y \
    && rm -rf /var/lib/apt/lists/*

  	# Create unprivileged user & download SteamCMD, execute as user
RUN useradd -u "${PUID}" -m "${USER}" \
	&& su "${USER}" -c \
		"mkdir -p \"${STEAMCMDDIR}\" \
		&& curl -fsSL 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar xvzf - -C \"${STEAMCMDDIR}\" \
		&& \"./${STEAMCMDDIR}/steamcmd.sh\" +quit \
		&& mkdir -p \"${HOMEDIR}/.steam/sdk32\" \
		&& ln -s \"${STEAMCMDDIR}/linux32/steamclient.so\" \"${HOMEDIR}/.steam/sdk32/steamclient.so\" \
		&& ln -s \"${STEAMCMDDIR}/linux32/steamcmd\" \"${STEAMCMDDIR}/linux32/steam\" \
		&& ln -s \"${STEAMCMDDIR}/steamcmd.sh\" \"${STEAMCMDDIR}/steam.sh\"" \
	# Symlink steamclient.so; So misconfigured dedicated servers can find it
	&& ln -s "${STEAMCMDDIR}/linux64/steamclient.so" "/usr/lib/x86_64-linux-gnu/steamclient.so"

FROM build_stage AS ubuntu-22.04-root
WORKDIR ${STEAMCMDDIR}

FROM ubuntu-22.04-root as ubuntu-22.04
USER ${USER}