-- Task 5. Нагадування на сьогодні для Alice (hr_id=1), з перевіркою доступу
-- Інтервал: [сьогодні 00:00:00, завтра 00:00:00) UTC

SET NAMES utf8mb4;
SET time_zone = '+00:00';
USE crm;

SET @today    := UTC_DATE();
SET @tomorrow := DATE_ADD(@today, INTERVAL 1 DAY);

SELECT
  r.id AS reminder_id,
  r.remdate,
  r.candidate_id,
  c.full_name,
  r.note
FROM reminders r
JOIN candidates c ON c.id = r.candidate_id
WHERE r.hr_id = 1
  AND r.remdate >= @today
  AND r.remdate <  @tomorrow
  AND EXISTS (
    SELECT 1 FROM access a
    WHERE a.entity_type='reminder' AND a.entity_id=r.id
      AND a.hr_id=1 AND a.right_code='Read'
  )
ORDER BY r.remdate;
