-- Task 2. Місячна статистика по вакансіях
-- Інтервал місяця [@start_dt, @end_dt)

SET NAMES utf8mb4;
SET time_zone = '+00:00';
USE crm;

-- березень 2025
SET @start_dt := '2025-03-01 00:00:00';
SET @end_dt   := '2025-04-01 00:00:00';

SELECT
  v.id AS vacancy_id,
  v.title AS vacancy_title,
  DATE_FORMAT(@start_dt, '%Y-%m') AS month,
  IFNULL(tc.total_candidates,0) AS total_candidates,
  IFNULL(rs.resumes_sent,0)     AS resumes_sent,
  IFNULL(ct.contracts,0)        AS contracts,
  IFNULL(rj.rejections,0)       AS rejections,
  IFNULL(ca.calls,0)            AS calls,
  IFNULL(iv.interviews,0)       AS interviews
FROM vacancies v
LEFT JOIN (
  SELECT vacancy_id, COUNT(DISTINCT user_uid) AS total_candidates
  FROM early_statuses
  WHERE type_id IN (1,3,4,10,11,12,14,19)
    AND creation_date >= @start_dt AND creation_date < @end_dt
  GROUP BY vacancy_id
) tc ON tc.vacancy_id = v.id
LEFT JOIN (
  SELECT vacancy_id, COUNT(*) AS resumes_sent
  FROM resumes
  WHERE sent_at IS NOT NULL
    AND sent_at >= @start_dt AND sent_at < @end_dt
  GROUP BY vacancy_id
) rs ON rs.vacancy_id = v.id
LEFT JOIN (
  SELECT vacancy_id, COUNT(*) AS contracts
  FROM early_statuses
  WHERE type_id=10
    AND creation_date >= @start_dt AND creation_date < @end_dt
  GROUP BY vacancy_id
) ct ON ct.vacancy_id = v.id
LEFT JOIN (
  SELECT vacancy_id, COUNT(*) AS rejections
  FROM early_statuses
  WHERE type_id=11
    AND creation_date >= @start_dt AND creation_date < @end_dt
  GROUP BY vacancy_id
) rj ON rj.vacancy_id = v.id
LEFT JOIN (
  SELECT vacancy_id, COUNT(*) AS calls
  FROM early_statuses
  WHERE type_id=2
    AND creation_date >= @start_dt AND creation_date < @end_dt
  GROUP BY vacancy_id
) ca ON ca.vacancy_id = v.id
LEFT JOIN (
  SELECT vacancy_id, COUNT(*) AS interviews
  FROM early_statuses
  WHERE type_id IN (12,14)
    AND creation_date >= @start_dt AND creation_date < @end_dt
  GROUP BY vacancy_id
) iv ON iv.vacancy_id = v.id
ORDER BY vacancy_id;
