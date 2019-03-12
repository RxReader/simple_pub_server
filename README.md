# simple_pub_server

[![Build Status](https://cloud.drone.io/api/badges/v7lin/simple_pub_server/status.svg)](https://cloud.drone.io/v7lin/simple_pub_server)
[![Docker Pulls](https://img.shields.io/docker/pulls/v7lin/simple_pub_server.svg)](https://hub.docker.com/r/v7lin/simple_pub_server)

Dart private pub_server

### usage

docker-compose.yml
````
# 版本
version: "3.7"

# 服务
services:

  simple_pub_server:
    container_name: simple_pub_server
    image: v7lin/simple_pub_server:0.1.5
    restart: always
    ports:
      - 8080:8080
    volumes:
      - ../dev-ops-repo/simple_pub_server:/tmp/package-db
    environment:
      - TZ=${TIME_ZONE:-Asia/Shanghai}
      - PUB_SERVER_REPOSITORY_DATA=/tmp/package-db
      - PUB_SERVER_STANDALONE=true
````

### push dart packages or flutter packages/plugins to private pub_server

````
# dart
pub publish --server http://${your domain}

# flutter
flutter packages pub publish --server http://${your pub_server domain}
````

[China - Shadowsocks](https://blog.haitanyule.com/2019-02-27/flutter/)

### import dart packages or flutter packages/plugins from private pub_server

[Pub-Dependencies](https://www.dartlang.org/tools/pub/dependencies)

````
test:
  hosted:
    name: test # name of your package/plugin
    url: http://${your pub_server domain}
  version: ^0.0.1
````