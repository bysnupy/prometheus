FROM openshift/origin-release:golang-1.10 AS builder
WORKDIR /go/src/github.com/prometheus/prometheus
COPY . .
RUN make build

FROM  openshift/origin-base
LABEL maintainer="The Prometheus Authors <prometheus-developers@googlegroups.com>"

ARG FROM_DIRECTORY=/go/src/github.com/prometheus/prometheus
COPY --from=builder ${FROM_DIRECTORY}/prometheus                            /bin/prometheus
COPY --from=builder ${FROM_DIRECTORY}/promtool                              /bin/promtool
COPY --from=builder ${FROM_DIRECTORY}/documentation/examples/prometheus.yml /etc/prometheus/prometheus.yml
COPY --from=builder ${FROM_DIRECTORY}/console_libraries/                    /usr/share/prometheus/console_libraries/
COPY --from=builder ${FROM_DIRECTORY}/consoles/                             /usr/share/prometheus/consoles/

RUN ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/
RUN mkdir -p /prometheus && \
    chown -R nobody:nobody etc/prometheus /prometheus

USER       nobody
EXPOSE     9090
VOLUME     [ "/prometheus" ]
WORKDIR    /prometheus
ENTRYPOINT [ "/bin/prometheus" ]
CMD        [ "--config.file=/etc/prometheus/prometheus.yml", \
             "--storage.tsdb.path=/prometheus", \
             "--web.console.libraries=/usr/share/prometheus/console_libraries", \
             "--web.console.templates=/usr/share/prometheus/consoles" ]
