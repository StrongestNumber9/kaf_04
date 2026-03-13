FROM rockylinux/rockylinux:8

# Install dependencies
RUN --mount=type=bind,source=./rpm/,target=/rpm/ dnf -y install /rpm/*.rpm nc

# Copy configs
COPY config/ /config/
RUN mkdir /tmp/kraft-combined-logs && chown srv-kaf_07:srv-kaf_07 -R /tmp/kraft-combined-logs
COPY files/meta.properties /tmp/kraft-combined-logs/
COPY config/*.json /opt/teragrep/kaf_04/etc/

# Prepare custom path for kaf_04
RUN cp -ar /opt/teragrep/kaf_04/etc/ /custom-path

# Bootstrap
COPY tester.sh /tester.sh
RUN chmod +x /tester.sh

# Run
ENTRYPOINT ["/tester.sh"]
CMD [""]
