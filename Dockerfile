FROM alpine:3.10.2

RUN apk add --no-cache --update minidlna

COPY minidlna.conf /etc/minidlna.conf

RUN chmod 755 /etc/minidlna.conf \
 && echo "fs.inotify.max_user_watches=1048576" >> /etc/sysctl.conf

# --
# $ echo 'fs.inotify.max_user_watches = 200000' | tee /etc/sysctl.d/99-inotify-max_user_watches.conf
# $ sysctl -p --system
# --

EXPOSE 8200

CMD ["minidlnad", "-d"]