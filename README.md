# alpine nginx unit with php

An alpine php nginx unit with working versions:
 - alpine: 3.17.7
 - php: 8.1
 - unit: 1.31.1 
Also added extensions needed to run typical PHP apps e.g laravel.

Notes:
 - As of the time this dockerfile was written, the PHP embed module is excluded from Alpine versions greater than 3.17.
 - For Alpine 3.17, the latest PHP image is php 8.1

## building locally

```sh
docker build -t nginx-unit-alpine-php .
```

