# Build image:
# docker build -t ps3-distcc-host-arch .
# Create container:
# docker run -itd -p 3632:3632 -p 3633:3633 ps3-distcc-host:latest

FROM gentoo/stage3:latest

# Distcc default port
EXPOSE 3632/tcp
EXPOSE 3633/tcp

RUN emerge-webrsync
RUN emerge distcc crossdev gentoolkit # ruby git

RUN mkdir -p /var/db/repos/crossdev/{profiles,metadata}
RUN chown -R portage:portage /var/db/repos/crossdev
RUN mkdir -p /etc/portage/repos.conf
RUN echo 'crossdev' >> "/var/db/repos/crossdev/profiles/repo_name"
RUN echo 'masters = gentoo' >> "/var/db/repos/crossdev/metadata/layout.conf"
RUN echo '[crossdev]' >> "/etc/portage/repos.conf/crossdev.conf"
RUN echo 'location = /var/db/repos/crossdev' >> "/etc/portage/repos.conf/crossdev.conf"
RUN echo 'priority = 10' >> "/etc/portage/repos.conf/crossdev.conf"
RUN echo 'masters = gentoo' >> "/etc/portage/repos.conf/crossdev.conf"
RUN echo 'auto-sync = no' >> "/etc/portage/repos.conf/crossdev.conf"

# Default configuration for the PS3 helper.
RUN crossdev --b '2.41-r3' --g '13.2.1_p20240113-r1' --k '6.7' --l '2.37-r7' -t powerpc64-unknown-linux-gnu --abis altivec

# Cleanup
RUN emerge --depclean
RUN revdep-rebuild
RUN eclean --deep distfiles
RUN eclean --deep packages
RUN rm /latest-stage3-*-openrc.txt
RUN rm -rf /var/db/repos/*
RUN rm -rf /var/tmp/*
RUN rm -rf /var/cache/distfiles/*

# Start distcc and bash
CMD distccd --no-detach --allow 192.168.0.0/16 --verbose --log-level debug --log-stderr
