# alpine nginx unit with php

An alpine php nginx unit with working versions:
 - alpine: 3.17.7
 - php: 8.1
 - unit: 1.31.1 
Also added extensions needed to run typical PHP apps e.g laravel.

Notes:
 - This Dockerfile was originally copied from https://gitlab.com/jd1378/nginx-unit-alpine-php but has been modified to include bug fixes and enhancements.
 - As of the time this dockerfile was written, the PHP embed module is excluded from Alpine versions greater than 3.17, see this issue: https://github.com/serversideup/docker-php/issues/233
 - For Alpine 3.17, the latest PHP image is php 8.1

## Usage

If your Dockerfile:
```sh
FROM erdivartanovich/nginx-unit-php-alpine
...
```

## Building locally

```sh
docker build -t nginx-unit-alpine-php .
```



