#
# Build environment
# 
FROM node:13.12.0-alpine as build

WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH

COPY package.json ./
COPY package-lock.json ./

RUN npm ci --silent
RUN npm install react-scripts@3.4.1 -g --silent

COPY . ./

RUN npm run build

#
# Production environment
#
FROM nginx:alpine

COPY --from=build /app/build /usr/share/nginx/html

RUN set -x \
  # Create nginx user/group first, to be consistent throughout Docker variants
  && addgroup -g 101 -S nginx \
  && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
  # Install the latest release of NGINX Plus and/or NGINX Plus modules
  # Uncomment individual modules if necessary
  # Use versioned packages over defaults to specify a release
  && nginxPackages=" \
  nginx-plus \
  # nginx-plus=${NGINX_VERSION}-${PKG_RELEASE} \
  # nginx-plus-module-xslt \
  # nginx-plus-module-xslt=${NGINX_VERSION}-${PKG_RELEASE} \
  # nginx-plus-module-geoip \
  # nginx-plus-module-geoip=${NGINX_VERSION}-${PKG_RELEASE} \
  # nginx-plus-module-image-filter \
  # nginx-plus-module-image-filter=${NGINX_VERSION}-${PKG_RELEASE} \
  # nginx-plus-module-perl \
  # nginx-plus-module-perl=${NGINX_VERSION}-${PKG_RELEASE} \
  # nginx-plus-module-njs \
  # nginx-plus-module-njs=${NGINX_VERSION}.${NJS_VERSION}-${PKG_RELEASE} \
  " \
  KEY_SHA512="e7fa8303923d9b95db37a77ad46c68fd4755ff935d0a534d26eba83de193c76166c68bfe7f65471bf8881004ef4aa6df3e34689c305662750c0172fca5d8552a *stdin" \
  && apk add --no-cache --virtual .cert-deps \
  openssl \
  && wget -O /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub \
  && if [ "$(openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout | openssl sha512 -r)" = "$KEY_SHA512" ]; then \
  echo "key verification succeeded!"; \
  mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
  else \
  echo "key verification failed!"; \
  exit 1; \
  fi \
  && apk del .cert-deps \
  && apk add -X "https://plus-pkgs.nginx.com/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main" --no-cache $nginxPackages \
  && if [ -n "/etc/apk/keys/nginx_signing.rsa.pub" ]; then rm -f /etc/apk/keys/nginx_signing.rsa.pub; fi \
  && if [ -n "/etc/apk/cert.key" && -n "/etc/apk/cert.pem"]; then rm -f /etc/apk/cert.key /etc/apk/cert.pem; fi \
  # Bring in gettext so we can get `envsubst`, then throw
  # the rest away. To do this, we need to install `gettext`
  # then move `envsubst` out of the way so `gettext` can
  # be deleted completely, then move `envsubst` back.
  && apk add --no-cache --virtual .gettext gettext \
  && mv /usr/bin/envsubst /tmp/ \
  \
  && runDeps="$( \
  scanelf --needed --nobanner /tmp/envsubst \
  | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
  | sort -u \
  | xargs -r apk info --installed \
  | sort -u \
  )" \
  && apk add --no-cache $runDeps \
  && apk del .gettext \
  && mv /tmp/envsubst /usr/local/bin/ \
  # Bring in tzdata so users could set the timezones through the environment
  # variables
  && apk add --no-cache tzdata \
  # Bring in curl and ca-certificates to make registering on DNS SD easier
  && apk add --no-cache curl ca-certificates \
  # Forward request and error logs to Docker log collector
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]