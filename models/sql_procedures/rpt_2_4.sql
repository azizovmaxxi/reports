-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = -2;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-01-31';
-- exec rpt_2_4  @sdate, @edate, @lpu_id, @lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_2_4', 'P' ) IS NOT NULL DROP PROCEDURE rpt_2_4;
GO
IF TYPE_ID(N'LocLpuType') IS NULL
CREATE TYPE LocLpuType AS TABLE(id INTEGER, parent_id INTEGER, code VARCHAR(6), short_name VARCHAR(150));
GO

USE [person]
GO
/****** Object:  StoredProcedure [dbo].[rpt_2_4]    Script Date: 01.10.2020 15:33:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[rpt_2_4] @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
AS
BEGIN
--
--Мониторируемые заболевания
--
DECLARE @loc_lpu LocLpuType;
declare @where nvarchar(200)
DECLARE @condition NVARCHAR(200) =
    CASE
        WHEN @lpu_id = -2 THEN ' id = ' + cast(@lpu_parent_id AS VARCHAR)
        WHEN @lpu_id = -1 THEN ' parent_id = ' + cast(@lpu_parent_id AS VARCHAR)
        WHEN @lpu_parent_id IS NULL THEN ' id = ' + cast(@lpu_id AS VARCHAR) + ' OR parent_id = ' + cast(@lpu_id AS VARCHAR)
        ELSE ' id = ' + cast(@lpu_id AS VARCHAR)
        END;

DECLARE @get_loc_lpu NVARCHAR(500) =
        N' SELECT id, parent_id, code, short_name FROM glb_lpu WHERE ' + @condition;

INSERT INTO @loc_lpu
    EXECUTE sp_executesql @get_loc_lpu;

--
-- STEP_2
--
DECLARE @selected_lpu_id NVARCHAR(500) = CASE WHEN @lpu_id = -2 THEN ' a_c.lpu_id lpu_id, ' ELSE ' a_c.patient_lpu lpu_id, ' END;

DECLARE @a_tmp_case_v TABLE(case_id INTEGER, lpu_id INTEGER, f_v_date SMALLDATETIME, doctor_id UNIQUEIDENTIFIER, post_code SMALLINT, doc_lpu INTEGER,
                            patient_id UNIQUEIDENTIFIER, hosp_id INTEGER, emergency BIT, birth_day SMALLDATETIME,
                            sex_id TINYINT, status_mhi BIT, index ix_a_tmp_case_v(case_id));

DECLARE @join_lpu_id NVARCHAR(500) = CASE WHEN @lpu_id = -2 THEN ' l_lpu.id = a_c.lpu_id ' ELSE ' l_lpu.id = a_c.patient_id ' END;

set @where = case when @lpu_id=-2 then '(select id from  @loc_lpu where id=a_c.lpu_id)' else '(select id from @loc_lpu where id=a_c.patient_lpu)' end

--Всего случаев поликлинического обслуживания
DECLARE @get_a_tmp_case_v NVARCHAR(MAX) = '
		SELECT
			a_c.id AS case_id,  '+ @selected_lpu_id +'
			a_c.f_v_date, a_c.doctor_id, a_c.post_code, a_c.lpu_id doc_lpu, a_c.patient_id, a_c.hosp_id, a_c.emergency,
			p_p.birth_day, p_p.sex_id, p_p.status_mhi
		FROM A_case AS a_c INNER JOIN P_person AS p_p ON a_c.patient_id = p_p.id  
		WHERE   exists ' + @where + '
		AND a_c.f_v_date BETWEEN @sdate AND @edate
		AND exists
			(SELECT case_id
			FROM A_visit
			WHERE vistyp_code <> 28 AND a_c.id=case_id
			)
        '
INSERT INTO @a_tmp_case_v --Всего случаев поликлинического обслуживания
    EXECUTE sp_executesql @get_a_tmp_case_v, N'@loc_lpu LocLpuType READONLY, @sdate DATE, @edate DATE', @loc_lpu, @sdate, @edate

--
-- STEP_3
-- a_tmp2
--

--Мониторируемые заболевания
DECLARE @a_tmp_2 TABLE(case_id INTEGER, f_v_date SMALLDATETIME, patient_id UNIQUEIDENTIFIER, birth_day SMALLDATETIME,
                       sex_id TINYINT, status_mhi BIT, doctor_id UNIQUEIDENTIFIER, post_code INTEGER, lpu_id INTEGER, doc_lpu INTEGER,
                       hosp_id INTEGER, emergency BIT, diag_id INTEGER, icd10 VARCHAR(7), is_f_life BIT, basic BIT, index ix_a_tmp2(case_id, patient_id, icd10));

		DECLARE @get_a_tmp_2 NVARCHAR(MAX) = '
				SELECT a_c.id AS case_id, a_c.f_v_date, a_c.patient_id, p_p.birth_day, p_p.sex_id, p_p.status_mhi,
					   a_c.doctor_id, a_c.post_code, '+ @selected_lpu_id +' a_c.lpu_id AS doc_lpu, a_c.hosp_id, a_c.emergency, a_d.diag_id, a_d.icd10,
					   is_f_life, a_d.basic
				FROM a_case AS a_c
				INNER JOIN a_diagnosis AS a_d ON a_c.id = a_d.case_id
				INNER JOIN P_person AS p_p ON a_c.patient_id = p_p.id
				WHERE a_d.is_final = 1
				  AND a_d.icd10 BETWEEN ''A00''  AND ''T989''
				  AND a_c.f_v_date BETWEEN @sdate AND @edate
				  AND exists '+ @where

		INSERT INTO @a_tmp_2
			EXECUTE sp_executesql @get_a_tmp_2, N'@loc_lpu LocLpuType READONLY, @sdate DATE, @edate DATE', @loc_lpu, @sdate, @edate;

----
---- STEP_4
---- Calc results
----
WITH count_c1(num, c1)
         AS (
        SELECT 3 AS num, count(*) AS c1
        FROM @a_tmp_case_v cv
        WHERE exists ( SELECT case_id FROM A_diagnosis WHERE icd10 BETWEEN 'A00' AND 'T989' and cv.case_id=case_id) 
        UNION 
        SELECT 4 AS num, count(*) AS c1
        FROM @a_tmp_case_v cv
        WHERE emergency = 1 AND exists (SELECT case_id FROM A_diagnosis WHERE icd10 BETWEEN 'A00' AND 'T989' and cv.case_id=case_id)
        UNION 
        SELECT 7 AS num, count(*) AS c1
        FROM @a_tmp_case_v AS a_t_c
                 INNER JOIN A_diagnosis a_d ON a_t_c.case_id = a_d.case_id
        WHERE a_t_c.hosp_id IS NOT NULL AND a_t_c.hosp_id <> 0 AND a_d.icd10 BETWEEN 'A00' AND 'T989' AND a_d.basic = 1
        UNION 
        SELECT 8 AS num, count(*) AS c1
        FROM @a_tmp_case_v AS atcv
                 INNER JOIN A_diagnosis a_d ON atcv.case_id = a_d.case_id
        WHERE atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0 AND atcv.emergency = 1
          AND a_d.icd10 BETWEEN 'A00' AND 'T989' AND a_d.basic = 1
    ),
    count_c2(num, c2)
         AS(
         SELECT 1 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2  left join
			( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			  t2.is_f_life = 1 AND t2.icd10 BETWEEN 'I10' AND 'I139'
			) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
			where atmp2.icd10 BETWEEN 'I10' AND 'I139' and
			 atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                  WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                  ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE atmp2.icd10 BETWEEN 'I10' AND 'I139'
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c2
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id FROM A_diagnosis WHERE icd10 BETWEEN 'I10' AND 'I139' and atcv.case_id=case_id)
         UNION
         SELECT 4 AS num, count(*) AS c2
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'I10' AND 'I139') AND atcv.emergency = 1
         UNION
         SELECT 7 AS num, count(*) AS c2
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'I10' AND 'I139') AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
     ),
     count_c3(num, c3)
         AS (
         SELECT 1 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2  left join
			( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			  t2.is_f_life = 1 AND t2.icd10 BETWEEN 'K25' AND 'K269'
			) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
			where atmp2.icd10 BETWEEN 'K25' AND 'K269' and
			 atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                  WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                  ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE atmp2.icd10 BETWEEN 'K25' AND 'K269'
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c3
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id FROM A_diagnosis WHERE icd10 BETWEEN 'K25' AND 'K269' and atcv.case_id=case_id)
         UNION
         SELECT 4 AS num, count(*) AS c3
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'K25' AND 'K269') AND atcv.emergency = 1 
         UNION
         SELECT 7 AS num, count(*) AS c3
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'K25' AND 'K269') AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
     ),
     count_c4(num, c4)
         AS (
         SELECT 1 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2  left join
			( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			  t2.is_f_life = 1 AND t2.icd10 Like 'J45%'
			) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
			where atmp2.icd10 Like 'J45%' and
			 atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                  WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                  ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE atmp2.icd10 like 'J45%'
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c4
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id FROM A_diagnosis WHERE icd10 like 'J45%' and atcv.case_id=case_id)
         UNION
         SELECT 4 AS num, count(*) AS c4
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 like 'J45%') AND atcv.emergency = 1 
         UNION
         SELECT 7 AS num, count(*) AS c4
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 like 'J45%') AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
     ),
     count_c5(num, c5)
         AS (
         SELECT 1 AS num, count(*) AS c2
		 FROM @a_tmp_2 AS atmp2  left join
		( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			t2.is_f_life = 1 AND (icd10 like 'D50%' OR icd10 like 'O990%')
		) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
		where (atmp2.icd10 like 'D50%' OR atmp2.icd10 like 'O990%') and
			atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE (atmp2.icd10 like 'D50%' OR icd10 like 'O990%')
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c5
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id FROM A_diagnosis WHERE (icd10 like 'D50%' OR icd10 like 'O990%') and atcv.case_id=case_id)
         UNION
         SELECT 4 AS num, count(*) AS c5
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 like 'D50%' OR icd10 like 'O990%') AND atcv.emergency = 1
         UNION
         SELECT 7 AS num, count(*) AS c5
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 like 'D50%' OR icd10 like 'O990%') AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
     ),
     count_c6(num, c6)
         AS (
         SELECT 1 AS num, count(*) AS c2
		 FROM @a_tmp_2 AS atmp2  left join
		( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			t2.is_f_life = 1 AND (icd10 like 'D50%' OR icd10 like 'O990%')
			AND (t2.birth_day between DateAdd(yyyy, -5, t2.f_v_date) and DateAdd(yyyy, 0, t2.f_v_date))
		) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
		where (atmp2.icd10 like 'D50%' OR atmp2.icd10 like 'O990%') 
		AND (atmp2.birth_day between DateAdd(yyyy, -5, atmp2.f_v_date) and DateAdd(yyyy, 0, atmp2.f_v_date)) and
		atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE (atmp2.icd10 like 'D50%' OR icd10 like 'O990%')
           AND (atmp2.birth_day between DateAdd(yyyy, -5, atmp2.f_v_date) and DateAdd(yyyy, 0, atmp2.f_v_date))
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c6
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id FROM A_diagnosis WHERE (icd10 like 'D50%' OR icd10 like 'O990%') and atcv.case_id=case_id)
           AND (atcv.birth_day between DateAdd(yyyy, -5, atcv.f_v_date) and DateAdd(yyyy, 0, atcv.f_v_date))
         UNION
         SELECT 4 AS num, count(*) AS c6
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 like 'D50%' OR icd10 like 'O990%') AND atcv.emergency = 1
           AND (atcv.birth_day between DateAdd(yyyy, -5, atcv.f_v_date) and DateAdd(yyyy, 0, atcv.f_v_date))
         UNION
         SELECT 7 AS num, count(*) AS c6
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 like 'D50%' OR icd10 like 'O990%') AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
           AND (atcv.birth_day between DateAdd(yyyy, -5, atcv.f_v_date) and DateAdd(yyyy, 0, atcv.f_v_date))
     ),
     count_c7(num, c7)
         AS (
         SELECT 1 AS num, count(*) AS c2
		 FROM @a_tmp_2 AS atmp2  left join
		( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			t2.is_f_life = 1 AND (t2.icd10 BETWEEN 'J00' AND 'J069' OR t2.icd10 BETWEEN 'J20' AND 'J229')
		) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
		where (atmp2.icd10 BETWEEN 'J00' AND 'J069' OR atmp2.icd10 BETWEEN 'J20' AND 'J229') and
			atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE (atmp2.icd10 BETWEEN 'J00' AND 'J069' OR icd10 BETWEEN 'J20' AND 'J229')
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c7
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id FROM A_diagnosis WHERE (icd10 BETWEEN 'J00' AND 'J069' OR icd10 BETWEEN 'J20' AND 'J229') and atcv.case_id=case_id)
         UNION
         SELECT 4 AS num, count(*) AS c7
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'J00' AND 'J069' OR icd10 BETWEEN 'J20' AND 'J229')
           AND atcv.emergency = 1 
         UNION
         SELECT 7 AS num, count(*) AS c7
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'J00' AND 'J069' OR icd10 BETWEEN 'J20' AND 'J229')
           AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
     ),
     count_c8(num, c8)
         AS (
         SELECT 1 AS num, count(*) AS c2
		 FROM @a_tmp_2 AS atmp2  left join
		( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			t2.is_f_life = 1 AND (t2.icd10 BETWEEN 'J00' AND 'J069' OR t2.icd10 BETWEEN 'J20' AND 'J229')
			AND (t2.birth_day between DateAdd(yyyy, -5, t2.f_v_date) and DateAdd(yyyy, 0, t2.f_v_date))
		) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
		where (atmp2.icd10 BETWEEN 'J00' AND 'J069' OR atmp2.icd10 BETWEEN 'J20' AND 'J229') 
		    AND (atmp2.birth_day between DateAdd(yyyy, -5, atmp2.f_v_date) and DateAdd(yyyy, 0, atmp2.f_v_date)) and
			atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE (atmp2.icd10 BETWEEN 'J00' AND 'J069' OR icd10 BETWEEN 'J20' AND 'J229')
           AND (atmp2.birth_day between DateAdd(yyyy, -5, atmp2.f_v_date) and DateAdd(yyyy, 0, atmp2.f_v_date))
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c8
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id FROM A_diagnosis WHERE (icd10 BETWEEN 'J00' AND 'J069' OR icd10 BETWEEN 'J20' AND 'J229') and atcv.case_id=case_id)
           AND (atcv.birth_day between DateAdd(yyyy, -5, atcv.f_v_date) and DateAdd(yyyy, 0, atcv.f_v_date))
         UNION
         SELECT 4 AS num, count(*) AS c8
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'J00' AND 'J069' OR icd10 BETWEEN 'J20' AND 'J229')
           AND atcv.emergency = 1
           AND (atcv.birth_day between DateAdd(yyyy, -5, atcv.f_v_date) and DateAdd(yyyy, 0, atcv.f_v_date))
         UNION
         SELECT 7 AS num, count(*) AS c8
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'J00' AND 'J069' OR icd10 BETWEEN 'J20' AND 'J229')
           AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
           AND (atcv.birth_day between DateAdd(yyyy, -5, atcv.f_v_date) and DateAdd(yyyy, 0, atcv.f_v_date))
     ),
     count_c9(num, c9)
         AS (
         SELECT 1 AS num, count(*) AS c2
		 FROM @a_tmp_2 AS atmp2  left join
		( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			t2.is_f_life = 1 AND (t2.icd10 like 'A03%' OR t2.icd10 like 'A04%' OR t2.icd10 like 'A08%' OR t2.icd10 like 'A09%')
		) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
		where (atmp2.icd10 like 'A03%' OR atmp2.icd10 like 'A04%' OR atmp2.icd10 like 'A08%' OR atmp2.icd10 like 'A09%') and
			atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE (atmp2.icd10 like 'A03%' OR icd10 like 'A04%' OR icd10 like 'A08%' OR icd10 like 'A09%')
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c9
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id
                           FROM A_diagnosis WHERE (icd10 like 'A03%' OR icd10 like 'A04%' OR icd10 like 'A08%' OR icd10 like 'A09%') and atcv.case_id=case_id)
         UNION
         SELECT 4 AS num, count(*) AS c9
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 like 'A03%' OR icd10 like 'A04%' OR icd10 like 'A08%' OR icd10 like 'A09%')
           AND atcv.emergency = 1 
         UNION
         SELECT 7 AS num, count(*) AS c9
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 like 'A03%' OR icd10 like 'A04%' OR icd10 like 'A08%' OR icd10 like 'A09%')
           AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
     ),
     count_c10(num, c10)
         AS (
         SELECT 1 AS num, count(*) AS c2
		 FROM @a_tmp_2 AS atmp2  left join
		( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			t2.is_f_life = 1 AND (t2.icd10 like 'A03%' OR t2.icd10 like 'A04%' OR t2.icd10 like 'A08%' OR t2.icd10 like 'A09%')
			 AND (t2.birth_day between DateAdd(yyyy, -5, t2.f_v_date) and DateAdd(yyyy, 0, t2.f_v_date))
		) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
		where (atmp2.icd10 like 'A03%' OR atmp2.icd10 like 'A04%' OR atmp2.icd10 like 'A08%' OR atmp2.icd10 like 'A09%')
		 AND (atmp2.birth_day between DateAdd(yyyy, -5, atmp2.f_v_date) and DateAdd(yyyy, 0, atmp2.f_v_date)) and
			atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE (atmp2.icd10 like 'A03%' OR icd10 like 'A04%' OR icd10 like 'A08%' OR icd10 like 'A09%')
           AND (atmp2.birth_day between DateAdd(yyyy, -5, atmp2.f_v_date) and DateAdd(yyyy, 0, atmp2.f_v_date))
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c10
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id
                           FROM A_diagnosis
                           WHERE (icd10 like 'A03%' OR icd10 like 'A04%' OR icd10 like 'A08%' OR icd10 like 'A09%') and atcv.case_id=case_id)
           AND (atcv.birth_day between DateAdd(yyyy, -5, atcv.f_v_date) and DateAdd(yyyy, 0, atcv.f_v_date))
         UNION
         SELECT 4 AS num, count(*) AS c10
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 like 'A03%' OR icd10 like 'A04%' OR icd10 like 'A08%' OR icd10 like 'A09%')
           AND atcv.emergency = 1 
           AND (atcv.birth_day between DateAdd(yyyy, -5, atcv.f_v_date) and DateAdd(yyyy, 0, atcv.f_v_date))
         UNION
         SELECT 7 AS num, count(*) AS c10
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 like 'A03%' OR icd10 like 'A04%' OR icd10 like 'A08%' OR icd10 like 'A09%')
           AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
           AND (atcv.birth_day between DateAdd(yyyy, -5, atcv.f_v_date) and DateAdd(yyyy, 0, atcv.f_v_date))
     ),
     count_c11(num, c11)
         AS (
         SELECT 1 AS num, count(*) AS c2
		 FROM @a_tmp_2 AS atmp2  left join
		( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			t2.is_f_life = 1 AND (t2.icd10 BETWEEN 'J40' AND 'J449')
		) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
		where (atmp2.icd10 BETWEEN 'J40' AND 'J449') and
			atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE (atmp2.icd10 BETWEEN 'J40' AND 'J449')
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c11
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id FROM A_diagnosis WHERE icd10 BETWEEN 'J40' AND 'J449' and atcv.case_id=case_id)
         UNION
         SELECT 4 AS num, count(*) AS c11
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'J40' AND 'J449')
           AND atcv.emergency = 1 
         UNION
         SELECT 7 AS num, count(*) AS c11
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'J40' AND 'J449')
           AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
     ),
     count_c12(num, c12)
         AS (
         SELECT 1 AS num, count(*) AS c2
		 FROM @a_tmp_2 AS atmp2  left join
		( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			t2.is_f_life = 1 AND (t2.icd10 BETWEEN 'J12' AND 'J189')
		) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
		where (atmp2.icd10 BETWEEN 'J12' AND 'J189') and
			atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE (atmp2.icd10 BETWEEN 'J12' AND 'J189')
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c12
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id FROM A_diagnosis WHERE icd10 BETWEEN 'J12' AND 'J189' and atcv.case_id=case_id)
         UNION
         SELECT 4 AS num, count(*) AS c12
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'J12' AND 'J189')
           AND atcv.emergency = 1 
         UNION
         SELECT 7 AS num, count(*) AS c12
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'J12' AND 'J189')
           AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
     ),
     count_c13(num, c13)
         AS (
         SELECT 1 AS num, count(*) AS c2
		 FROM @a_tmp_2 AS atmp2  left join
		( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			t2.is_f_life = 1 AND (t2.icd10 BETWEEN 'J12' AND 'J189')
			AND (t2.birth_day between DateAdd(yyyy, -5, t2.f_v_date) and DateAdd(yyyy, 0, t2.f_v_date))
		) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
		where (atmp2.icd10 BETWEEN 'J12' AND 'J189') 
		AND (atmp2.birth_day between DateAdd(yyyy, -5, atmp2.f_v_date) and DateAdd(yyyy, 0, atmp2.f_v_date)) and
			atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE (atmp2.icd10 BETWEEN 'J12' AND 'J189')
           AND (atmp2.birth_day between DateAdd(yyyy, -5, atmp2.f_v_date) and DateAdd(yyyy, 0, atmp2.f_v_date))
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c13
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id FROM A_diagnosis WHERE icd10 BETWEEN 'J12' AND 'J189' and atcv.case_id=case_id)
           AND (atcv.birth_day between DateAdd(yyyy, -5, atcv.f_v_date) and DateAdd(yyyy, 0, atcv.f_v_date))
         UNION
         SELECT 4 AS num, count(*) AS c13
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'J12' AND 'J189')
           AND atcv.emergency = 1 
           AND (atcv.birth_day between DateAdd(yyyy, -5, atcv.f_v_date) and DateAdd(yyyy, 0, atcv.f_v_date))
         UNION
         SELECT 7 AS num, count(*) AS c13
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'J12' AND 'J189')
           AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
           AND (atcv.birth_day between DateAdd(yyyy, -5, atcv.f_v_date) and DateAdd(yyyy, 0, atcv.f_v_date))
     ),
     count_c14(num, c14)
         AS (
         SELECT 1 AS num, count(*) AS c2
		 FROM @a_tmp_2 AS atmp2  left join
		( select case_id, patient_id, icd10 FROM @a_tmp_2 t2 WHERE  
			t2.is_f_life = 1 AND (t2.icd10 BETWEEN 'I20' AND 'I259')
		) b  on atmp2.patient_id=b.patient_id and atmp2.icd10=b.icd10 
		where (atmp2.icd10 BETWEEN 'I20' AND 'I259') and
			atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC) 
         UNION
         SELECT 2 AS num, count(*) AS c2
         FROM @a_tmp_2 AS atmp2
         WHERE (atmp2.icd10 BETWEEN 'I20' AND 'I259')
           AND atmp2.status_mhi = 1
           AND atmp2.case_id = (SELECT TOP 1 case_id FROM @a_tmp_2 AS b1
                                WHERE b1.patient_id = atmp2.patient_id AND b1.icd10 = atmp2.icd10
                                ORDER BY case_id DESC)
         UNION
         SELECT 3 AS num, count(*) AS c14
         FROM @a_tmp_case_v AS atcv
         WHERE exists (SELECT case_id FROM A_diagnosis WHERE icd10 BETWEEN 'I20' AND 'I259' and atcv.case_id=case_id)
         UNION
         SELECT 4 AS num, count(*) AS c14
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'I20' AND 'I259')
           AND atcv.emergency = 1 
         UNION
         SELECT 7 AS num, count(*) AS c14
         FROM @a_tmp_case_v AS atcv
                  INNER JOIN A_diagnosis AS a_d ON atcv.case_id = a_d.case_id
         WHERE a_d.basic = 1 AND (a_d.icd10 BETWEEN 'I20' AND 'I259')
           AND (atcv.hosp_id IS NOT NULL AND atcv.hosp_id <> 0)
     )
SELECT g_a_rpt_f.num, g_a_rpt_f.short_name, g_a_rpt_f.code,
       COALESCE(c_c1.c1, 0) AS c1, COALESCE(c_c2.c2, 0) AS c2, COALESCE(c_c3.c3, 0) AS c3, COALESCE(c_c4.c4, 0) AS c4,
       COALESCE(c_c5.c5, 0) AS c5, COALESCE(c_c6.c6, 0) AS c6, COALESCE(c_c7.c7, 0) AS c7, COALESCE(c_c8.c8, 0) AS c8,
       COALESCE(c_c9.c9, 0) AS c9, COALESCE(c_c10.c10, 0) AS c10, COALESCE(c_c11.c11, 0) AS c11,
       COALESCE(c_c12.c12, 0) AS c12, COALESCE(c_c13.c13, 0) AS c13, COALESCE(c_c14.c14, 0) AS c14
FROM glb_A_rpt_reference AS g_a_rpt_f
     LEFT JOIN count_c1 AS c_c1 ON c_c1.num = g_a_rpt_f.num
     LEFT JOIN count_c2 AS c_c2 ON c_c2.num = g_a_rpt_f.num
     LEFT JOIN count_c3 AS c_c3 ON c_c3.num = g_a_rpt_f.num
     LEFT JOIN count_c4 AS c_c4 ON c_c4.num = g_a_rpt_f.num
     LEFT JOIN count_c5 AS c_c5 ON c_c5.num = g_a_rpt_f.num
     LEFT JOIN count_c6 AS c_c6 ON c_c6.num = g_a_rpt_f.num
     LEFT JOIN count_c7 AS c_c7 ON c_c7.num = g_a_rpt_f.num
     LEFT JOIN count_c8 AS c_c8 ON c_c8.num = g_a_rpt_f.num
     LEFT JOIN count_c9 AS c_c9 ON c_c9.num = g_a_rpt_f.num
     LEFT JOIN count_c10 AS c_c10 ON c_c10.num = g_a_rpt_f.num
     LEFT JOIN count_c11 AS c_c11 ON c_c11.num = g_a_rpt_f.num
     LEFT JOIN count_c12 AS c_c12 ON c_c12.num = g_a_rpt_f.num
     LEFT JOIN count_c13 AS c_c13 ON c_c13.num = g_a_rpt_f.num
     LEFT JOIN count_c14 AS c_c14 ON c_c14.num = g_a_rpt_f.num
END;