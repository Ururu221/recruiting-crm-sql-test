-- Task 1. Ліди без подальших дій
-- Інтервал [@start_dt, @end_dt), UTC

SET NAMES utf8mb4;
SET time_zone = '+00:00';
USE crm;

-- приклад: березень 2025
SET @start_dt := '2025-03-01 00:00:00';
SET @end_dt   := '2025-04-01 00:00:00';

SELECT
  e.user_uid AS candidate_id,
  c.full_name,
  c.linkedin_url,
  e.vacancy_id,
  v.title     AS vacancy_title,
  e.creation_date,
  e.comment_text,
  c.is_friend,
  c.is_pro
FROM early_statuses e
JOIN candidates c ON c.id = e.user_uid
JOIN vacancies  v ON v.id = e.vacancy_id
WHERE e.type_id = 1
  AND e.creation_date >= @start_dt
  AND e.creation_date <  @end_dt
  AND EXISTS (
    SELECT 1 FROM access a
    WHERE a.entity_type='candidate' AND a.entity_id=c.id
      AND a.hr_id=1 AND a.right_code='Read'
  )
  AND EXISTS (
    SELECT 1 FROM access a
    WHERE a.entity_type='vacancy' AND a.entity_id=v.id
      AND a.hr_id=1 AND a.right_code='Read'
  )
  AND NOT EXISTS ( -- пізнішого статусу
    SELECT 1 FROM early_statuses s
    WHERE s.user_uid=e.user_uid AND s.vacancy_id=e.vacancy_id
      AND s.creation_date > e.creation_date
  )
  AND NOT EXISTS ( -- резюме з відправкою
    SELECT 1 FROM resumes r
    WHERE r.candidate_id=e.user_uid AND r.vacancy_id=e.vacancy_id
      AND r.sent_at IS NOT NULL
  )
ORDER BY e.creation_date ASC;
