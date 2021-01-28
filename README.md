pg_replicator
=============

Хелперы для логической репликации между Postgres 9/10/11/12/Amazon RDS 

Обозначения
-----------

Предполгаем что базы данных не меняют свои имена, а только переезжают с хоста на хост, из инстанса pg в другой инстанс.

Обозначения:

- `src` - источник, откуда производится репликация
- `dest` - приемник, куда происзводится репликация

Параметры:

- `--src-databases` - список баз для репликации через запятую
- `--src-host` - хост источника
- `--src-port` - порт источника
- `--src-user` - юзер источника, должен уметь читать все базы и `CREATE PUBLICATION`
- `--src-password` - пароль пользователя
- `--dest-host` - хост приемника
- `--dest-port` - порт приемника
- `--dest-user` - юзер приемника, должен уметь `DROP DATABASE`, `CREATE DATABASE`, `CREATE SUBSCRIPTION`, `UPDATE SEQUENCE` и тд
- `--dest-password` - пароль пользователя

Все параметры одинаковы для всех команд


### resync


**Удаляет** все базы на приемнике, указанные в `--src-databases`. 
С каждой базы источника снимается дамп схемы, затем по ней разворачивается пустая база на приемнике с таким же именем и схемой.

```shell
docker run --rm -it a00s/pg_replicator resync \
  --src-host 192.168.1.10 --src-port 5432 --src-user superuser --src-password superuser \
  --dest-host 192.168.1.11 --dest-port 5432 --dest-user superuser --dest-password superuser \
  --src-databases db1,db2
```

### start

В каждой базе источника создаются публикация. В каждой базе приемника создаются подписки.

`max_replication_slots` на источнике должно быть больше или равно количеству баз, указанных в `--src-databases`!

```shell
docker run --rm -it a00s/pg_replicator start \
  --src-host 192.168.1.10 --src-port 5432 --src-user superuser --src-password superuser \
  --dest-host 192.168.1.11 --dest-port 5432 --dest-user superuser --dest-password superuser \
  --src-databases db1,db2
```

### status

Отражает состояние всех подписок на приемнике. 
Так же показывает размер баз на источнике и приемнике. 
Можно запустить под `watch`.

```shell
docker run --rm -it a00s/pg_replicator status \
  --src-host 192.168.1.10 --src-port 5432 --src-user superuser --src-password superuser \
  --dest-host 192.168.1.11 --dest-port 5432 --dest-user superuser --dest-password superuser \
  --src-databases db1,db2
```

### stop

На приемнике удаляются все подписки. На источнике удаляются все публикации.

```shell
docker run --rm -it a00s/pg_replicator stop \
  --src-host 192.168.1.10 --src-port 5432 --src-user superuser --src-password superuser \
  --dest-host 192.168.1.11 --dest-port 5432 --dest-user superuser --dest-password superuser \
  --src-databases db1,db2
```

### sequences

Переносит значения всех sequences из источника в приемник.

```shell
docker run --rm -it a00s/pg_replicator sequences \
  --src-host 192.168.1.10 --src-port 5432 --src-user superuser --src-password superuser \
  --dest-host 192.168.1.11 --dest-port 5432 --dest-user superuser --dest-password superuser \
  --src-databases db1,db2
```


Репликация данных из Postgres 9.5+
----------------------------------

### start9

Запускает репликацию между Postgres 9.5+ и Postgres 10+.

```shell
docker run --rm -it a00s/pg_replicator start9 \
  --src-host 192.168.1.10 --src-port 5432 --src-user superuser --src-password superuser \
  --dest-host 192.168.1.11 --dest-port 5432 --dest-user superuser --dest-password superuser \
  --src-databases db1,db2
```

### stop9

Останавливает репликацию между Postgres 9.5+ и Postgres 10+.

```shell
docker run --rm -it a00s/pg_replicator stop9 \
  --src-host 192.168.1.10 --src-port 5432 --src-user superuser --src-password superuser \
  --dest-host 192.168.1.11 --dest-port 5432 --dest-user superuser --dest-password superuser \
  --src-databases db1,db2
```

### sequences9

Переносит значения всех sequences из источника в приемник.

```shell
docker run --rm -it a00s/pg_replicator sequences9 \
  --src-host 192.168.1.10 --src-port 5432 --src-user superuser --src-password superuser \
  --dest-host 192.168.1.11 --dest-port 5432 --dest-user superuser --dest-password superuser \
  --src-databases db1,db2
```
