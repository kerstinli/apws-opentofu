#docker build -t logstash .
#docker run -d --name logstash --rm logstash:latest
#docker rename frosty_tharp logstash

# Basis-Image
FROM arm64v8/logstash:8.19.18
#FROM logstash:9.4.2

RUN logstash-plugin install logstash-output-opensearch

USER logstash

WORKDIR /usr/share/logstash
COPY logstash.conf /usr/share/logstash/pipeline/logstash.conf
EXPOSE 5044
CMD ["-f", "/usr/share/logstash/pipeline/logstash.conf"]