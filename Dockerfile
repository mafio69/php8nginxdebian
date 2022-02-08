FROM mafio69/phpfirststep8:12

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=048b95b48b708983effb2e5c935a1ef8483d9e3e

# RUN wget https://get.symfony.com/cli/installer -O - | bash

RUN curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic \
    && curl -sS https://getcomposer.org/installer | php \
    && mkdir -p /usr/share/nginx/logs/ \
    && touch -c /usr/share/nginx/logs/error.log \
    && mkdir -p /usr/share/nginx/logs/ \
    && cp composer.phar /usr/local/bin/composer  \
    && mv composer.phar /usr/bin/composer \
    && addgroup docker

COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/mime.types /etc/nginx/mime.types
COPY config/custom.ini /usr/local/etc/php/conf.d/custom.ini
COPY config/cron-task /etc/cron.d/crontask
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/enabled-symfony.conf /etc/nginx/conf.d/enabled-symfony.conf
COPY config/nginx/supervisord-main.conf /etc/supervisord.conf
COPY config/nginx/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./main /main

RUN usermod -a -G docker root && adduser \
       --system \
       --shell /bin/bash \
       --disabled-password \
       --home /home/docker \
       docker \
       && apt update \
       && apt install -y supervisor \
       && usermod -a -G docker root \
       && usermod -a -G docker docker \
       && chown -R docker:docker /var/log

ADD --chown=docker:docker /main /main
STOPSIGNAL SIGQUIT
WORKDIR /
EXPOSE 8080 9000
STOPSIGNAL SIGQUIT
#CMD ["php-fpm"]
CMD ["/usr/bin/supervisord", "-nc", "/etc/supervisord.conf"]
