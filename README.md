# Social network for trips - System Design

System Design социальной сети для путешествий для курса по System Design – https://balun.courses/courses/system_design

### Functional requirements:

- публикация поста с текстом, картинками и местом путешествия
- места путешествий преподготовленные
- оценка поста
- комментарий под постом
- подписка на путешественников
- поиск популярных (с наивысшим средним рейтинг) мест для путешествий
- просмотр постов по популярным местам для путешествий
- просмотр ленты других путешественников и ленты пользователя, основанной на подписках в обратном хронологическом порядке
- просмотр комментариев под постом

### Non-functional requirements:

- 10 000 000 DAU
- доступность 99,9%
- посты храним 20 лет, пользователей всегда
- клиенты - мобильные устройства и браузер
- гео распределение по странам СНГ
- сезонность есть - праздники, лето (x3 от обычной нагрузки).
Активность пользователей
- пользователь в среднем просматривает 9 лент (1 лента = 5 постов) в день в сезон
- пользователь в среднем постит раз в неделю в сезон
- пользователь в среднем читает 90 комментариев в сезон
- пользователь в среднем пишет комментарий раз в день в сезон
- пользователь в среднем ставит оценку 9 раз в день в сезон
- пользователь просматривает ленту популярных мест для путешествий 3 раза в день в сезон
- пользователь в среднем подписывается на путешественников раз в неделю в сезон
Ограничения:
- max количество картинок в посте - 10
- max размер изображения - 500 КБ
- max размер текста в посте - 2000 символов
- max размер комментария - 500 символов
Тайминги:
- получение ленты - 1 секунда
- просмотр комментариев - 1 секунда
- создание поста - 3 секунд (обработка - фоновый процесс)

## Basic calculations

### Создание поста (write)

#### RPS

    DAU = 10 000 000
    1 пост в неделю в сезон
    в сезон RPS = 10 000 000 / 86 400 / 7 ~= 20 rps

#### Transaction

Post

    post_id ~ 16 bytes
    user_id ~ 16 bytes
    text ~ 2000 * 2 bytes
    imgs ~ 10 * 500 kb
    place_id ~ 16 bytes

Итого:

    meta ~ 48 bytes
    text ~ 4kb
    static ~ 5mb

#### Трафик

    traffic в сезон (meta+text) = 20 * 4kb = 80 kb/s
    traffic в сезон (static) = 20 * 5mb = 100 mb/s


### Получение ленты (read)

#### RPS

    DAU = 10 000 000
    9 лент в день в сезон
    в сезон RPS = 10 000 000 / 86400 * 9 ~= 900 rps

#### Transaction

    post = post при создании + reactions_count (8 bytes)
    Лента (meta+text) = 5 * post(meta+text) ~= 5 * 4kb ~= 20kb
    Лента (static) = 5 * post(static) ~= 5 * 5mb ~= 25mb

#### Трафик

    traffic в сезон (meta+text) = 900 * 20kb = 18 mb/s
    traffic в сезон (static) = 900 * 25mb = 22 gb/s

### Получение ленты популярных мест (read)

#### RPS

    DAU = 10 000 000
    3 лент в день в сезон
    в сезон RPS = 10 000 000 / 86400 * 3 ~= 300 rps

#### Трафик

    traffic в сезон (meta+text) = 300 * 20kb = 6 mb/s
    traffic в сезон (static) = 300 * 25mb = 7 gb/s

### Написание комментариев (write)

#### RPS

    DAU = 10 000 000
    1 раз в день в сезон
    в сезон RPS = 10 000 000 / 86400 ~= 100 rps

#### Трафик

    traffic в сезон = 100 * 500 * 2 = 100 kb/s

### Просмотр комментариев (read)

#### RPS

    DAU = 10 000 000
    90 раз в день в сезон
    в сезон RPS = 10 000 000 / 86400 * 90 ~= 9k rps

#### Трафик

    traffic в сезон = 9000 * 500 * 2 = 10 mb/s

### оценивание/реакции (write)

#### RPS

    DAU = 10 000 000
    9 раз в день в сезон
    в сезон RPS = 10 000 000 / 86400 * 9 ~= 900 rps

#### Transaction

    post_id ~ 16 bytes

Итого 24 bytes

#### Трафик

    traffic в сезон = 900 * 16 = 15 kb/s

### подписки на путешественников (write)

#### RPS

    DAU = 10 000 000
    раз в неделю в сезон
    в сезон RPS = 10 000 000 / 86400 / 7 ~= 14 rps

#### Transaction

    post_id ~ 16 bytes
    user_id ~ 16 bytes

Итого 32 bytes

#### Трафик

    traffic в сезон = 900 * 32 ~= 30 kb/s

## Расчет ресурсов

### Диски

#### Посты

##### Capacity

    meta+text = 80 kb/s * 86400 * 365 ~= 80 kb/s * 100000 * 400 = 4 TB
    static = 100 mb/s * 86400 * 365 ~= 100 mb/s * 100000 * 400 = 4 PB

##### HDD

    meta+text:
    disks by capacity = 4 TB / 32 TB = 1 disks
    disks by bandwidth = (80 kb/s + 18 mb/s + 6 mb/s) / 100 mb/s ~= 1 disk
    disks by iops = (20 + 900 + 300) / 100 rps ~= 13 disks

    Total = 13 disks

    static:
    disks by capacity = 4 PB / 32 TB ~= 150 disks
    disks by bandwidth = (100 mb/s + 22 gb/s + 7 gb/s) / 100 mb/s ~= 291 disks
    disks by iops = (20 + 900 + 300) / 100 rps ~= 13 disks

    Total = 291 disks

##### SSD (SATA)

    meta+text:
    disks by capacity = 4 TB / 100 TB = 1 disks
    disks by bandwidth = (80 kb/s + 18 mb/s + 6 mb/s) / 500 mb/s ~= 1 disk
    disks by iops = (20 + 900 + 300) / 1000 rps ~= 2 disks

    Total = 2 disks

    static:
    disks by capacity = 4 PB / 100 TB ~= 40 disks
    disks by bandwidth = (100 mb/s + 22 gb/s + 7 gb/s) / 500 mb/s ~= 60 disks
    disks by iops = (20 + 900 + 300) / 1000 rps ~= 2 disks

    Total = 60 disks

##### SSD (NVME)

    meta+text:
    disks by capacity = 4 TB / 30 TB = 1 disks
    disks by bandwidth = (80 kb/s + 18 mb/s + 6 mb/s) / 3000 mb/s ~= 1 disk
    disks by iops = (20 + 900 + 300) / 10000 rps ~= 1 disks

    Total = 1 disks

    static:
    disks by capacity = 4 PB / 30 TB ~= 134 disks
    disks by bandwidth = (100 mb/s + 22 gb/s + 7 gb/s) / 3 gb/s ~= 10 disks
    disks by iops = (20 + 900 + 300) / 10000 rps ~= 1 disks

    Total = 10 disks

#### Реакции

##### Capacity

    15 kb/s * 86400 * 365 ~= 15 kb/s * 100000 * 400 = 1 TB

##### HDD

    disks by capacity = 1 TB / 32 TB = 1 disks
    disks by bandwidth = 15 kb/s / 100 mb/s ~= 1 disk
    disks by iops = 900 / 100 rps ~= 9 disks

    Total = 9 disks

##### SSD (SATA)

    disks by capacity = 1 TB / 100 TB = 1 disks
    disks by bandwidth = 15 kb/s / 500 mb/s ~= 1 disk
    disks by iops = 900 / 1000 rps ~= 1 disks

    Total = 1 disks

##### SSD (NVME)

    disks by capacity = 1 TB / 30 TB = 1 disks
    disks by bandwidth = 15 kb/s / 3000 mb/s ~= 1 disk
    disks by iops = 900 / 10000 rps ~= 1 disks

    Total = 1 disks

#### Подписки на путешественников

##### Capacity

    30 kb/s * 86400 * 365 = 30 * 100000 * 400 ~= 2 TB

##### HDD

    disks by capacity = 2 TB / 32 TB = 1 disks
    disks by bandwidth = 30 kb/s / 100 mb/s ~= 1 disk
    disks by iops = 14 / 100 rps ~= 1 disks

    Total = 1

##### SSD (SATA)

    disks by capacity = 2 TB / 100 TB = 1 disks
    disks by bandwidth = 30 kb/s / 500 mb/s ~= 1 disk
    disks by iops = 14 / 1000 rps ~= 1 disks

    Total = 1 disks

##### SSD (NVME)

    disks by capacity = 2 TB / 30 TB = 1 disks
    disks by bandwidth = 30 kb/s / 3000 mb/s ~= 1 disk
    disks by iops = 14 / 10000 rps ~= 1 disks

    Total = 1 disks

#### Комментарии

##### Capacity

    100 kb/s * 86400 * 365 ~= 100 * 100000 * 400 = 4 TB

##### HDD

    disks by capacity = 4 TB / 32 TB = 1 disks
    disks by bandwidth = (100 kb/s + 10 mb/s) / 100 mb/s ~= 1 disk
    disks by iops = (100 + 9000) / 100 rps ~= 91 disks

    Total = 91 disks

##### SSD (SATA)

    disks by capacity = 4 TB / 100 TB = 1 disks
    disks by bandwidth = (100 kb/s + 10 mb/s) / 500 mb/s ~= 1 disk
    disks by iops = 9100 / 1000 rps ~= 10 disks

    Total = 10 disks

##### SSD (NVME)

    disks by capacity = 4 TB / 30 TB = 1 disks
    disks by bandwidth = (100 kb/s + 10 mb/s) / 3000 mb/s ~= 1 disk
    disks by iops = 9100 / 10000 rps ~= 1 disks

    Total = 1 disks