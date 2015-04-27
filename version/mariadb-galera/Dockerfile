FROM gainmaster/archlinux:base
MAINTAINER Tony Hesjevik <tony@hesjevik.no>

COPY galera.pkg.tar.xz          /tmp/galera.pkg.tar.xz
COPY mariadb-galera.pkg.tar.xz  /tmp/mariadb-galera.pkg.tar.xz

RUN pacman-install-tar /tmp/galera.pkg.tar.xz /tmp/mariadb-galera.pkg.tar.xz

COPY mariadb-wrapper.sh  /usr/local/bin/mariadb-wrapper
COPY my.cnf              /etc/mysql/my.cnf

EXPOSE 3306

ENTRYPOINT ["mariadb-wrapper"]
