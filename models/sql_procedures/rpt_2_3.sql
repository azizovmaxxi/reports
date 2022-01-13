-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 68241;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2019-01-01';
-- declare @edate date = '2020-12-31';

-- exec rpt_2_3 @sdate, @edate, @lpu_id, @lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_2_3', 'P' ) IS NOT NULL DROP PROCEDURE rpt_2_3;

GO
USE [person]
GO
/****** Object:  StoredProcedure [dbo].[rpt_2_3]    Script Date: 01.10.2020 15:32:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[rpt_2_3] @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
AS
BEGIN

	declare @sql nvarchar(max)='';
	declare @where nvarchar(200)
	declare @a_case_v acase_v;
	declare @current_lpu current_lpu;
    declare @dinamicField varchar(80)

	set @dinamicField = case  when @lpu_id=-2 then 'ac.lpu_id lpu_id' else 'ac.patient_lpu lpu_id' end;
	set @where = case when @lpu_id=-2 then '(select id from  @current_lpu where id=ac.lpu_id)' else '(select id from @current_lpu where id=ac.patient_lpu)' end

	insert into @current_lpu SELECT id, parent_id, code, short_name
            FROM glb_lpu
            WHERE (id = @lpu_id OR parent_id = @lpu_id OR id = @lpu_parent_id OR parent_id = @lpu_parent_id)

	set @sql = N'
	;with a_tmp_case_v(case_id, lpu_id, f_v_date, doctor_id, post_code, doc_lpu, patient_id, hosp_id, emergency) AS
		(
		SELECT
			ac.id AS case_id,  '+@dinamicField+',
			ac.f_v_date, ac.doctor_id,
			ac.post_code, ac.lpu_id doc_lpu, ac.patient_id, ac.hosp_id, ac.emergency
		FROM A_case AS ac WHERE  exists '+@where+'
		AND ac.f_v_date BETWEEN @sdate AND @edate
		AND exists
			(SELECT case_id
			FROM A_visit
			WHERE vistyp_code <> 28 AND ac.id=case_id
			)
		)
		select * from a_tmp_case_v'

		insert into @a_case_v
	execute sp_executesql @sql, N'@current_lpu current_lpu READONLY, @sdate date, @edate date, @lpu_id int, @lpu_parent_id int',
									@current_lpu, @sdate, @edate, @lpu_id, @lpu_parent_id

    ;WITH a_tmp_visit(case_id, visit_date, lpu_id, doctor_id, post_code, patient_id, birth_day, vistyp_code)
             AS (
             SELECT visit.case_id, visit.visit_date, ac.lpu_id, ac.doctor_id, ac.post_code, ac.patient_id, pp.birth_day, visit.vistyp_code
             FROM a_case AS ac
                      JOIN A_visit AS visit ON ac.id = visit.case_id
                      JOIN p_person AS pp ON ac.patient_id = pp.id
             WHERE visit.visit_date BETWEEN @sdate AND @edate and exists (select id from  @current_lpu cur where cur.id=ac.lpu_id)
         ),
         a_tmp_spec(f_v_date, case_id, lpu_id, doctor_id, post_code, patient_id, icd10)
             AS (
             SELECT  ac.f_v_date, a_spec.case_id, ac.lpu_id, ac.doctor_id, ac.post_code, ac.patient_id, a_spec.icd10
             FROM @a_case_v AS ac
             JOIN A_specialist AS a_spec ON ac.case_id = a_spec.case_id
             GROUP BY ac.f_v_date, a_spec.case_id, ac.lpu_id, ac.doctor_id, ac.post_code, ac.patient_id, a_spec.icd10
         ),
         a_tmp_grouped_visit(doctor_id, post_code, lpu_id)
             AS (
                 SELECT doctor_id, post_code, lpu_id
                 FROM @a_case_v
                 GROUP BY doctor_id, post_code, lpu_id
				 UNION
				 SELECT doctor_id, post_code, lpu_id
                 FROM a_tmp_visit
                 GROUP BY doctor_id, post_code, lpu_id
         ),
         count_a1(doctor_id, post_code, lpu_id, case_id)
             AS (
             SELECT doctor_id, post_code, lpu_id, count(case_id) AS case_id
             FROM a_tmp_visit
             WHERE vistyp_code in (11,12,31,32,34)
             GROUP BY doctor_id, post_code, lpu_id
         ),
         count_a2(doctor_id, post_code, lpu_id, case_id)
             AS (
             SELECT doctor_id, post_code, lpu_id, count(case_id) AS case_id
             FROM a_tmp_visit
             WHERE vistyp_code NOT IN (21, 22, 23, 24, 25, 26, 27, 33, 35, 36)
               AND vistyp_code <> 28
               AND exists
                   (SELECT case_id
                    FROM A_diagnosis
                    WHERE icd10 BETWEEN 'A00' AND 'T989' and a_tmp_visit.case_id=case_id)
             GROUP BY doctor_id, post_code, lpu_id
         ),
         count_a3(doctor_id, post_code, lpu_id, case_id)
             AS (
             SELECT doctor_id, post_code, lpu_id, count(case_id) AS case_id
             FROM a_tmp_visit
             WHERE vistyp_code IN (21, 22, 23, 24, 25, 26, 27, 33, 35, 36)
             GROUP BY doctor_id, post_code, lpu_id
         ),
         count_a4(doctor_id, post_code, lpu_id, case_id)
             AS (
             SELECT doctor_id, post_code, lpu_id, count(case_id) AS case_id
             FROM a_tmp_visit
             WHERE vistyp_code IN (21, 22, 23, 24, 25, 26, 27, 33, 35, 36)
               AND vistyp_code <> 28
               AND exists
                   (SELECT case_id
                    FROM A_diagnosis
                    WHERE icd10 BETWEEN 'A00' AND 'T989' and a_tmp_visit.case_id=case_id)
             GROUP BY doctor_id, post_code, lpu_id
         ),
         count_a5(doctor_id, post_code, lpu_id, case_id)
             AS (
             SELECT doctor_id, post_code, lpu_id, count(case_id) AS case_id
             FROM a_tmp_visit
             WHERE vistyp_code <> 28
             GROUP BY doctor_id, post_code, lpu_id
         ),
         count_a6(doctor_id, post_code, lpu_id, case_id)
             AS (
             SELECT doctor_id, post_code, lpu_id, count(case_id) AS case_id
             FROM a_tmp_visit
             WHERE vistyp_code <> 28
               AND case_id IN
                   (SELECT case_id
                    FROM A_diagnosis
                    WHERE icd10 BETWEEN 'A00' AND 'T989')
             GROUP BY doctor_id, post_code, lpu_id
         ),
         count_a7(doctor_id, post_code, lpu_id, case_id)
             AS (
             SELECT doctor_id, post_code, lpu_id, count(case_id) AS case_id
             FROM @a_case_v
             GROUP BY doctor_id, post_code, lpu_id
         ),
         count_a8(doctor_id, post_code, lpu_id, case_id)
             AS (
             SELECT doctor_id, post_code, lpu_id, count(case_id) AS case_id
             FROM @a_case_v
             WHERE case_id IN (SELECT case_id FROM A_diagnosis WHERE icd10 BETWEEN 'A00' AND 'T989')
             GROUP BY doctor_id, post_code, lpu_id
         ),
         count_a9(doctor_id, post_code, lpu_id, case_id)
             AS (
             SELECT atcv.doctor_id, atcv.post_code, atcv.lpu_id, count(atcv.case_id) AS case_id
             FROM @a_case_v AS atcv
                      INNER JOIN A_diagnosis AS giag ON atcv.case_id = giag.case_id
             WHERE atcv.hosp_id IS NOT NULL
               AND atcv.hosp_id <> 0
               AND giag.basic = 1
               AND giag.icd10 BETWEEN 'A00' AND 'T989'
             GROUP BY atcv.doctor_id, atcv.post_code, atcv.lpu_id
         ),
         count_a10(doctor_id, post_code, lpu_id, case_id)
             AS (
             SELECT doctor_id, post_code, lpu_id, count(case_id) AS case_id
             FROM a_tmp_spec
             WHERE icd10 BETWEEN 'A00' AND 'T989'
             GROUP BY doctor_id, post_code, lpu_id
         ),
         result_data(doctor_id, post_code, lpu_id, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
             AS (
             SELECT atgv.doctor_id, atgv.post_code, atgv.lpu_id
                  ,COALESCE(a1.case_id, 0) AS a1, COALESCE(a2.case_id, 0) AS a2, COALESCE(a3.case_id, 0) AS a3
                  ,COALESCE(a4.case_id, 0) AS a4, COALESCE(a5.case_id, 0) AS a5, COALESCE(a6.case_id, 0) AS a6
                  ,COALESCE(a7.case_id, 0) AS a7, COALESCE(a8.case_id, 0) AS a8, COALESCE(a9.case_id, 0) AS a9
                  ,COALESCE(a10.case_id, 0) AS a10
             FROM a_tmp_grouped_visit AS atgv
                      LEFT JOIN count_a1 AS a1 ON atgv.lpu_id = a1.lpu_id AND atgv.post_code = a1.post_code AND atgv.doctor_id = a1.doctor_id
                      LEFT JOIN count_a2 AS a2 ON atgv.lpu_id = a2.lpu_id AND atgv.post_code = a2.post_code AND atgv.doctor_id = a2.doctor_id
                      LEFT JOIN count_a3 AS a3 ON atgv.lpu_id = a3.lpu_id AND atgv.post_code = a3.post_code AND atgv.doctor_id = a3.doctor_id
                      LEFT JOIN count_a4 AS a4 ON atgv.lpu_id = a4.lpu_id AND atgv.post_code = a4.post_code AND atgv.doctor_id = a4.doctor_id
                      LEFT JOIN count_a5 AS a5 ON atgv.lpu_id = a5.lpu_id AND atgv.post_code = a5.post_code AND atgv.doctor_id = a5.doctor_id
                      LEFT JOIN count_a6 AS a6 ON atgv.lpu_id = a6.lpu_id AND atgv.post_code = a6.post_code AND atgv.doctor_id = a6.doctor_id
                      LEFT JOIN count_a7 AS a7 ON atgv.lpu_id = a7.lpu_id AND atgv.post_code = a7.post_code AND atgv.doctor_id = a7.doctor_id
                      LEFT JOIN count_a8 AS a8 ON atgv.lpu_id = a8.lpu_id AND atgv.post_code = a8.post_code AND atgv.doctor_id = a8.doctor_id
                      LEFT JOIN count_a9 AS a9 ON atgv.lpu_id = a9.lpu_id AND atgv.post_code = a9.post_code AND atgv.doctor_id = a9.doctor_id
                      LEFT JOIN count_a10 AS a10 ON atgv.lpu_id = a10.lpu_id AND atgv.post_code = a10.post_code AND atgv.doctor_id = a10.doctor_id
         ),
         group_data(parent_id, post_code, doctor_id, lpu_id, lpu_code, lpu_name, post_name, doc_name, a1, a2 ,a3 ,a4, a5, a6, a7, a8, a9, a10)
             AS (
             SELECT lpu.parent_id, gsp.code AS post_code, r_data.doctor_id, r_data.lpu_id, lpu.code, lpu.short_name,
                    gsp.full_name AS post_name, p_d.Name AS doctor_name,
                    r_data.a1, r_data.a2, r_data.a3, r_data.a4, r_data.a5, r_data.a6, r_data.a7, r_data.a8, r_data.a9, r_data.a10
             FROM result_data AS r_data
                      INNER JOIN P_doctor AS p_d ON r_data.doctor_id = p_d.id
                      INNER JOIN glb_S_post AS gsp ON r_data.post_code = gsp.code
                      INNER JOIN @current_lpu AS lpu ON r_data.lpu_id = lpu.id
         )
    SELECT parent_id, lpu_name, lpu_id, lpu_code, post_code, post_name,
           sum(a1) AS a1, sum(a2) AS a2, sum(a3) AS a3, sum(a4) AS a4,
           sum(a5) AS a5, sum(a6) AS a6, sum(a7) AS a7, sum(a8) AS a8,
           sum(a9) AS a9, sum(a10) AS a10,
           CONCAT(lpu_name, ' (', (CASE WHEN parent_id IS NULL THEN 'Узкие специалисты' ELSE CONVERT(VARCHAR, lpu_code) END), ')') AS build_group_title
    FROM group_data
    GROUP BY parent_id, lpu_name, lpu_id, lpu_code, post_code, post_name
    ORDER BY parent_id ASC, lpu_id DESC, post_code ASC;

END;