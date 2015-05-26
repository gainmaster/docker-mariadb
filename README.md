# MariaDB Docker image

[![Build Status](http://ci.hesjevik.im/buildStatus/icon?job=docker-mariadb)](http://ci.hesjevik.im/job/docker-mariadb/) [![Docker Hub](https://img.shields.io/badge/docker-ready-blue.svg?style=plastic)](https://registry.hub.docker.com/u/gainmaster/mariadb/)

This repository contains a **Dockerfile** for a base MariaDB image. This repository is a part of an automated build, published to the [Docker Hub][docker_hub_repository].

**Base image:** [gainmaster/docker-arch][docker_hub_base_image]

[docker_hub_repository]: https://registry.hub.docker.com/u/gainmaster/mariadb/
[docker_hub_base_image]: https://registry.hub.docker.com/u/gainmaster/archlinux/

## Docker Hub automated build tags

`gainmaster/mariadb` provides multiple tagged images:

* `latest` (default) : MariaDB (alias to `mariadb`)
* `mariadb` : MariaDB
* `mariadb-galera` : MariaDB Galera Cluster

## Installed packages

* [MariaDB][mariadb] - An enhanced, drop-in replacement for MySQL.

[mariadb]: https://mariadb.org/

## Resources

These resources have been helpful when creating this Docker image:
