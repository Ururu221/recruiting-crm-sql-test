# Recruiting CRM — SQL Test (MySQL 8)

Репозиторій для перевірки SQL-навыків на реалістичній схемі рекрутингу. Схема й сид — **MySQL 8**; у каталозі `sql/` — п’ять завдань (Task 1–5). Інтервали дат скрізь задаються як **\[start, end)** (верхня межа не входить).

## Що тут відбувається

* `schema/recruiting_crm_schema.sql` — створює всі таблиці (**aspnetusers, companies, candidates, vacancies, early\_statuses, resumes, access, reminders, skill\_variants, candidate\_skills**) і заливає мінімальний сид (березень 2025).
* `sql/task1.sql` — **ліди без подальших дій**: шукає статуси type\_id=1 (Lead) у діапазоні дат за парами кандидат–вакансія, де **нема пізнішого статусу**, **нема відправленого резюме**, і **Alice (hr\_id=1)** має доступ до кандидата і вакансії. Вивід: дані кандидата/вакансії + дата/коментар. Сортування за `creation_date ↑`.
* `sql/task2.sql` — **місячна статистика по вакансіях**: агрегати за місяць `[start, end)` — `total_candidates`, `resumes_sent`, `contracts`, `rejections`, `calls`, `interviews`. Збирання через `LEFT JOIN` попередньо агрегованих підзапитів до списку вакансій (усі відсутні — 0 через `IFNULL`).
* `sql/task3.sql` — **щоденний KPI по HR (за вчора, UTC)**: створює TEMP-таблицю `kpi_table` і одним скриптом рахує метрики (`leads_created`, `statuses_added`, `resumes_prepared`, `resumes_sent`, `calls_made`, `contracts_signed`) для кожного HR.
* `sql/task4.sql` — **оновлення лічильників навичок**: `UPDATE ... JOIN (SELECT ... GROUP BY)` — ставить `skill_variants.cnt = COUNT(DISTINCT candidate_id)` для кожного `variant_id` (немає — 0 через `IFNULL`).
* `sql/task5.sql` — **нагадування на сьогодні** для Alice (hr\_id=1) у `[сьогодні 00:00:00, завтра 00:00:00)` з перевіркою доступу до кожного нагадування в `access`.

## Де код і що всередині

```
recruiting-crm-sql-test/
├─ schema/
│  └─ recruiting_crm_schema.sql   # схема БД + сид (MySQL 8)
├─ sql/
│  ├─ task1.sql                   # Leads без подальших дій
│  ├─ task2.sql                   # Місячна статистика по вакансіях
│  ├─ task3.sql                   # Щоденний KPI по HR (вчора, UTC)
│  ├─ task4.sql                   # Оновлення лічильників навичок
│  └─ task5.sql                   # Нагадування на сьогодні (Alice)
├─ out/                           # текстові результати (CLI), див. нижче
└─ README.md
```

Кожен `taskN.sql` починається з:

```sql
SET NAMES utf8mb4;
SET time_zone = '+00:00';
USE crm;
```

і містить готові змінні дат (`@start_dt`, `@end_dt`) або розрахунок «вчора/сьогодні» (`@yesterday`, `@today`).

## Що міститься в `out/`

Каталог для збереження текстових виводів (`--table`) після виконання скриптів через CLI. Рекомендовані файли:

* `out/task1.txt` — результат Task 1 (список лідів без подальших дій).
* `out/task2.txt` — результат Task 2 (зведення по вакансіях за місяць).
* `out/task3.txt` — результат Task 3 (KPI за «вчора» від поточної дати; на сід-даних може бути 0).
* `out/task3_with-date-2025-03-21.txt` — демонстрація KPI за 2025‑03‑20 (див. нижче приклад підстановки дат).
* `out/task4_before.txt` / `out/task4_after.txt` — знімки «до/після» оновлення лічильників навичок.
* `out/task5.txt` — результат Task 5 (нагадування «на сьогодні»; на сід-даних порожньо без тестової дати).
* `out/task5_with-date-2025-03-15.txt` — демонстрація нагадувань за 2025‑03‑15.

## Швидкий старт (тільки Docker + CLI)

1. Запустити MySQL 8 у Docker:

```bash
docker run --name mysql8 -e MYSQL_ROOT_PASSWORD=pass -p 3306:3306 -d mysql:8
```

2. Створити БД і залити схему/сид:

```bash
docker exec -i mysql8 mysql -uroot -ppass -e "CREATE DATABASE crm CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
docker cp schema/recruiting_crm_schema.sql mysql8:/schema.sql
docker exec -i mysql8 sh -c "mysql -uroot -ppass crm < /schema.sql"
```

