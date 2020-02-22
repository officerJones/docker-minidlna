FROM alpine:3.10.2

COPY minidlna.conf /etc/minidlna.conf

RUN apk add --no-cache --update minidlna curl \
 && chmod 755 /etc/minidlna.conf

# TODO: increase inotify user watches

EXPOSE 8200

CMD ["minidlnad", "-d"]