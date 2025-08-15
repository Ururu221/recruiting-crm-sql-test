
SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- Drops (order safe)
DROP TABLE IF EXISTS candidate_skills;
DROP TABLE IF EXISTS skill_variants;
DROP TABLE IF EXISTS reminders;
DROP TABLE IF EXISTS access;
DROP TABLE IF EXISTS resumes;
DROP TABLE IF EXISTS early_statuses;
DROP TABLE IF EXISTS vacancies;
DROP TABLE IF EXISTS candidates;
DROP TABLE IF EXISTS companies;
DROP TABLE IF EXISTS aspnetusers;

-- Core refs
CREATE TABLE aspnetusers(
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL UNIQUE,
  fio   VARCHAR(190) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE companies(
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(190) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE candidates(
  id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(190) NOT NULL,
  linkedin_url VARCHAR(255),
  is_friend TINYINT(1) NOT NULL DEFAULT 0,
  is_pro TINYINT(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE vacancies(
  id INT AUTO_INCREMENT PRIMARY KEY,
  company_id INT NOT NULL,
  title VARCHAR(190) NOT NULL,
  owner_hr_id INT NOT NULL,
  FOREIGN KEY(company_id) REFERENCES companies(id),
  FOREIGN KEY(owner_hr_id) REFERENCES aspnetusers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Activity (contracts as type_id=10)
CREATE TABLE early_statuses(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_uid INT NOT NULL,        -- candidate_id
  vacancy_id INT NOT NULL,
  type_id INT NOT NULL,         -- 1 Lead, 2 Call, 3 CV prepared, 4 CV sent, 10 Contract, 11 Rejected, 12 Interview, 14 Tech interview, 19 Offer
  substatus VARCHAR(50) NULL,
  comment_text VARCHAR(300),
  created_by INT NOT NULL,      -- hr id
  creation_date DATETIME NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  FOREIGN KEY(user_uid) REFERENCES candidates(id),
  FOREIGN KEY(vacancy_id) REFERENCES vacancies(id),
  FOREIGN KEY(created_by) REFERENCES aspnetusers(id),
  INDEX (user_uid, vacancy_id, created_by, creation_date),
  INDEX (type_id, creation_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Resumes (now includes sent_by/sent_at)
CREATE TABLE resumes(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  candidate_id INT NOT NULL,
  vacancy_id INT NOT NULL,
  created_by INT NOT NULL,
  created_at DATETIME NOT NULL,
  sent_by INT NULL,
  sent_at DATETIME NULL,
  FOREIGN KEY(candidate_id) REFERENCES candidates(id),
  FOREIGN KEY(vacancy_id) REFERENCES vacancies(id),
  FOREIGN KEY(created_by) REFERENCES aspnetusers(id),
  FOREIGN KEY(sent_by) REFERENCES aspnetusers(id),
  INDEX (candidate_id, vacancy_id, created_at),
  INDEX (vacancy_id, sent_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Unified access
CREATE TABLE access(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  entity_type ENUM('candidate','vacancy','status','resume','reminder') NOT NULL,
  entity_id BIGINT NOT NULL,
  hr_id INT NOT NULL,
  right_code ENUM('Read','Preview') NOT NULL,
  FOREIGN KEY(hr_id) REFERENCES aspnetusers(id),
  INDEX (entity_type, entity_id),
  INDEX (hr_id, right_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Reminders
CREATE TABLE reminders(
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  hr_id INT NOT NULL,
  candidate_id INT NOT NULL,
  remdate DATETIME NOT NULL,
  note VARCHAR(300),
  FOREIGN KEY(hr_id) REFERENCES aspnetusers(id),
  FOREIGN KEY(candidate_id) REFERENCES candidates(id),
  INDEX (remdate),
  INDEX (hr_id, remdate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Variants (single dimension for Task 4)
CREATE TABLE skill_variants(
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  cnt INT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE candidate_skills(
  candidate_id INT NOT NULL,
  variant_id INT NOT NULL,
  PRIMARY KEY(candidate_id, variant_id),
  FOREIGN KEY(candidate_id) REFERENCES candidates(id),
  FOREIGN KEY(variant_id) REFERENCES skill_variants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =======================
-- Seed
-- =======================
INSERT INTO aspnetusers (email, fio) VALUES
 ('hr1@example.com','Alice Recruiter'),
 ('hr2@example.com','Bob Recruiter');

INSERT INTO companies(name) VALUES ('Acme Inc'), ('Globex LLC');

INSERT INTO candidates(full_name, linkedin_url, is_friend, is_pro) VALUES
 ('John Doe','https://linkedin.com/in/johndoe',1,0),
 ('Jane Smith','https://linkedin.com/in/janesmith',0,1),
 ('Ivan Petrenko','https://linkedin.com/in/ivanpetrenko',0,0),
 ('Olha Kovalenko','https://linkedin.com/in/olhakovalenko',1,1),
 ('Carlos Ruiz','https://linkedin.com/in/carlosruiz',0,0),
 ('Mei Lin','https://linkedin.com/in/meilin',0,1);

INSERT INTO vacancies(company_id,title,owner_hr_id) VALUES
 (1,'Backend Engineer',1),
 (1,'Data Analyst',1),
 (2,'Frontend Developer',2);

-- early_statuses (March 2025, incl. contract as type 10)
INSERT INTO early_statuses(user_uid,vacancy_id,type_id,substatus,comment_text,created_by,creation_date,is_active) VALUES
 (1,1,1,'Neutral','Lead from LI',1,'2025-03-01 09:15:00',1),
 (1,1,2,'Positive','Phone talked',1,'2025-03-02 10:00:00',1),
 (1,1,3,'Positive','CV prepared',1,'2025-03-03 12:30:00',1),
 (1,1,4,'Positive','CV sent',1,'2025-03-04 15:10:00',1),
 (1,1,10,'Positive','Contract signed',1,'2025-03-20 11:00:00',1),
 (2,1,1,'Neutral','Lead cold',1,'2025-03-05 11:00:00',1),
 (3,2,1,'Neutral','Lead medium',1,'2025-03-06 10:20:00',1),
 (3,2,11,'Negative','Rejected by HR',1,'2025-03-10 14:40:00',1),
 (4,2,1,'Neutral','Lead good',1,'2025-03-07 09:00:00',1),
 (4,2,12,'Positive','Interview set',1,'2025-03-09 10:00:00',1),
 (5,3,1,'Neutral','Lead referral',2,'2025-03-02 13:00:00',1),
 (5,3,3,'Positive','CV prepared',2,'2025-03-03 16:00:00',1),
 (5,3,4,'Positive','CV sent',2,'2025-03-05 09:30:00',1),
 (6,3,2,'Neutral','Phone only',2,'2025-03-12 10:10:00',1);

-- resumes with sent_by/sent_at folded in
INSERT INTO resumes(candidate_id,vacancy_id,created_by,created_at,sent_by,sent_at) VALUES
 (1,1,1,'2025-03-03 12:35:00',1,'2025-03-04 15:12:00'),
 (5,3,2,'2025-03-03 16:05:00',2,'2025-03-05 09:35:00');

-- access grants
-- candidates: hr1 sees 1..4; hr2 sees 5..6
INSERT INTO access(entity_type,entity_id,hr_id,right_code) VALUES
 ('candidate',1,1,'Read'),('candidate',2,1,'Read'),('candidate',3,1,'Read'),('candidate',4,1,'Read'),
 ('candidate',5,2,'Read'),('candidate',6,2,'Read');

-- vacancies: owners
INSERT INTO access(entity_type,entity_id,hr_id,right_code) VALUES
 ('vacancy',1,1,'Read'),('vacancy',2,1,'Read'),('vacancy',3,2,'Read');

-- statuses: grant to creator HR (ids 1..14 align with early_statuses PKs here)
INSERT INTO access(entity_type,entity_id,hr_id,right_code) VALUES
 ('status',1,1,'Read'),('status',2,1,'Read'),('status',3,1,'Read'),('status',4,1,'Read'),
 ('status',5,1,'Read'),('status',6,1,'Read'),('status',7,1,'Read'),('status',8,1,'Read'),
 ('status',9,1,'Read'),('status',10,1,'Read'),('status',11,2,'Read'),('status',12,2,'Read'),
 ('status',13,2,'Read'),('status',14,2,'Read');

-- reminders
INSERT INTO reminders(hr_id,candidate_id,remdate,note) VALUES
 (1,2,'2025-03-15 09:00:00','Ping cold lead (Jane)'),
 (1,4,'2025-03-15 14:00:00','Confirm interview time (Olha)'),
 (2,5,'2025-03-15 10:00:00','Follow-up after CV sent (Carlos)'),
 (2,6,'2025-03-16 11:00:00','Second call (Mei)');

-- reminders access (owner only)
INSERT INTO access(entity_type,entity_id,hr_id,right_code) VALUES
 ('reminder',1,1,'Read'),('reminder',2,1,'Read'),('reminder',3,2,'Read'),('reminder',4,2,'Read');

-- variants (skills) minimal set + links
INSERT INTO skill_variants(name) VALUES ('Python'),('SQL'),('React'),('C#');

INSERT INTO candidate_skills VALUES
 (1,1),(1,2),   -- John: Python, SQL
 (2,3),         -- Jane: React
 (3,1),         -- Ivan: Python
 (4,3),(4,2),   -- Olha: React, SQL
 (5,1),(5,4),   -- Carlos: Python, C#
 (6,3),(6,2);   -- Mei: React, SQL

-- End of XS seed
