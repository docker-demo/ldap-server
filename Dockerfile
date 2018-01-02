FROM alpine:3.7

ENV OPENLDAP_VERSION 2.4.45-r3

RUN apk update \
&& apk add openldap=${OPENLDAP_VERSION} openldap-back-mdb=${OPENLDAP_VERSION} \ 
&& rm -rf /var/cache/apk/* \
&& rm -rf /etc/openldap/DB_CONFIG.example \
&& mkdir -p /run/openldap \
&& chown ldap:ldap /run/openldap

COPY slash /

EXPOSE 389 636

ENTRYPOINT ["/docker-entrypoint.sh"]
