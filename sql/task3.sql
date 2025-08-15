-- Task 3. KPI за вчора [UTC] у TEMP-таблицю kpi_table

SET NAMES utf8mb4;
SET time_zone = '+00:00';
USE crm;

DROP TEMPORARY TABLE IF EXISTS kpi_table;

CREATE TEMPORARY TABLE kpi_table (
  day_date DATE,
  hr_id INT,
  leads_created INT,
  statuses_added INT,
  resumes_prepared INT,
  resumes_sent INT,
  calls_made INT,
  contracts_signed INT
) ENGINE=Memory;

SET @today     := UTC_DATE();
SET @yesterday := DATE_SUB(@today, INTERVAL 1 DAY);

INSERT INTO kpi_table
(day_date, hr_id, leads_created, statuses_added, resumes_prepared,
 resumes_sent, calls_made, contracts_signed)
SELECT
  @yesterday, u.id,
  IFNULL(l.leads_created,0),
  IFNULL(sa.statuses_added,0),
  IFNULL(rp.resumes_prepared,0),
  IFNULL(rs.resumes_sent,0),
  IFNULL(cm.calls_made,0),
  IFNULL(cs.contracts_signed,0)
FROM aspnetusers u
LEFT JOIN (
  SELECT created_by, COUNT(*) leads_created
  FROM early_statuses
  WHERE type_id=1 AND creation_date>=@yesterday AND creation_date<@today
  GROUP BY created_by
) l  ON l.created_by  = u.id
LEFT JOIN (
  SELECT created_by, COUNT(*) statuses_added
  FROM early_statuses
  WHERE type_id<>1 AND creation_date>=@yesterday AND creation_date<@today
  GROUP BY created_by
) sa ON sa.created_by = u.id
LEFT JOIN (
  SELECT created_by, COUNT(*) resumes_prepared
  FROM early_statuses
  WHERE type_id=3 AND creation_date>=@yesterday AND creation_date<@today
  GROUP BY created_by
) rp ON rp.created_by = u.id
LEFT JOIN (
  SELECT IFNULL(sent_by, created_by) hr_id, COUNT(*) resumes_sent
  FROM resumes
  WHERE sent_at IS NOT NULL AND sent_at>=@yesterday AND sent_at<@today
  GROUP BY IFNULL(sent_by, created_by)
) rs ON rs.hr_id = u.id
LEFT JOIN (
  SELECT created_by, COUNT(*) calls_made
  FROM early_statuses
  WHERE type_id=2 AND creation_date>=@yesterday AND creation_date<@today
  GROUP BY created_by
) cm ON cm.created_by = u.id
LEFT JOIN (
  SELECT created_by, COUNT(*) contracts_signed
  FROM early_statuses
  WHERE type_id=10 AND creation_date>=@yesterday AND creation_date<@today
  GROUP BY created_by
) cs ON cs.created_by = u.id;

SELECT * FROM kpi_table ORDER BY hr_id;
