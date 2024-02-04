# this alpine version must have a corresponding php image
ARG alpine_version='3.17.7'
ARG php_version='8.1'
ARG unit_version='1.31.1'

FROM alpine:$alpine_version as BUILDER

ARG unit_version
ARG php_version

COPY composer-setup.sh /usr/lib/composer/composer-setup.sh
RUN set -ex \
    && export php_pkg_ver=$(echo $php_version | sed 's/\.//') \
    && apk add --no-cache --update \
    php$php_pkg_ver php$php_pkg_ver-dev php$php_pkg_ver-embed php$php_pkg_ver-phar php$php_pkg_ver-mbstring php$php_pkg_ver-openssl \
    openssl-dev curl gcc musl-dev make linux-headers \
    && NCPU="$(getconf _NPROCESSORS_ONLN)" \
    && export UNITTMP=$(mktemp -d -p /tmp -t unit.XXXXXX) \
    && cd $UNITTMP \
    && curl -O "https://unit.nginx.org/download/unit-$unit_version.tar.gz" \
    && tar xzf unit-$unit_version.tar.gz \
    && cd unit-$unit_version \
    && echo '*self_spec:' > /tmp/no-pie-compile.specs \
    && echo '+ %{!r:%{!fpie:%{!fPIE:%{!fpic:%{!fPIC:%{!fno-pic:-fno-PIE}}}}}}' >> /tmp/no-pie-compile.specs \
    && ./configure --modules=/usr/lib/unit/modules --control="unix:/var/run/control.unit.sock" \
        --openssl --state=/var/lib/unit --pid=/var/run/unit.pid \
        --log=/dev/stdout --tmp=/var/tmp --user=unit --group=unit \
        --cc-opt='-g -O2 -flto=auto -ffat-lto-objects -specs=/tmp/no-pie-compile.specs -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
    && ./configure php --module=php$php_pkg_ver --config=/usr/bin/php-config$php_pkg_ver --lib-path=/usr/lib/php$php_pkg_ver \
    && make -j $NCPU unitd \
    && install -pm755 ./build/sbin/unitd /usr/sbin/unitd \
    && make -j $NCPU php$php_pkg_ver \
    && mkdir -p /usr/lib/unit/modules/ \
    && mv build/lib/unit/modules/php$php_pkg_ver.unit.so /usr/lib/unit/modules/php$php_pkg_ver.unit.so \
    && chmod 444 /usr/lib/unit/modules/php$php_pkg_ver.unit.so \
    && cd /usr/lib/composer \
    && ./composer-setup.sh

FROM alpine:$alpine_version

ARG php_version

COPY docker-entrypoint.sh /usr/local/bin/
COPY --from=BUILDER /usr/lib/unit/ /usr/lib/unit/
COPY --from=BUILDER /usr/sbin/unitd /usr/sbin/unitd
COPY --from=BUILDER /usr/lib/composer/composer.phar /usr/sbin/composer

RUN set -ex \
    && mkdir -p /var/lib/unit/ \
    && mkdir /docker-entrypoint.d/ \
    && export php_pkg_ver=$(echo $php_version | sed 's/\.//') \
    && apk add --no-cache --update \
        tini ca-certificates curl pcre2 musl openssl php$php_pkg_ver php$php_pkg_ver-embed \
        php$php_pkg_ver-session php$php_pkg_ver-phar php$php_pkg_ver-dom \
        php$php_pkg_ver-curl \
        php$php_pkg_ver-bcmath php$php_pkg_ver-ctype php$php_pkg_ver-fileinfo \
        php$php_pkg_ver-json php$php_pkg_ver-mbstring php$php_pkg_ver-openssl \
        php$php_pkg_ver-pdo php$php_pkg_ver-pdo_mysql php$php_pkg_ver-tokenizer php$php_pkg_ver-xml \
        php$php_pkg_ver-gd php$php_pkg_ver-iconv php$php_pkg_ver-zip php$php_pkg_ver-zlib \
        php$php_pkg_ver-simplexml php$php_pkg_ver-xmlreader php$php_pkg_ver-xmlwriter \
        php$php_pkg_ver-redis php$php_pkg_ver-opcache \
    && (ln -s /usr/bin/php$php_pkg_ver /usr/bin/php || true) \
    && (ln -s /usr/bin/phar$php_pkg_ver /usr/bin/phar || true) \
    && (ln -s /usr/bin/phar.phar$php_pkg_ver /usr/bin/phar.phar || true) \
    && (ln -s /etc/php$php_pkg_ver /etc/php || true) \
    && mkdir -p /usr/local/etc/ \
    && (ln -s /etc/php$php_pkg_ver /usr/local/etc/php || true) \
    && addgroup --system unit \
    && adduser \
      --system \
      --disabled-password \
      --ingroup unit \
      --no-create-home \
      --home /nonexistent \
      --gecos "unit user" \
      --shell /bin/false \
      unit \
    && (addgroup --system www-data || true) \
    && adduser \
      --system \
      --disabled-password \
      --ingroup www-data \
      --no-create-home \
      --home /nonexistent \
      --gecos "www-data user" \
      --shell /bin/false \
      www-data \
    && ldconfig /

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]

CMD ["/usr/sbin/unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]
