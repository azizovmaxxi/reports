USE [person]
GO
/****** Object:  StoredProcedure [dbo].[rpt_2_1]    Script Date: 01.10.2020 14:52:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[rpt_2_1] @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
AS
BEGIN
    --drop type acase_v
 --   create type acase_v as table(
	--[case_id] [int]  NOT NULL,
	--[lpu_id] [int] NULL,
	--[f_v_date] [smalldatetime] NOT NULL,
	--[doctor_id] [uniqueidentifier] NULL,
	--[post_code] [smallint] NULL,
	--[doc_lpu] [int] NULL,
	--[patient_id] [uniqueidentifier] NULL,
	--[hosp_id] [int] NULL,
	--[emergency] [bit] NOT NULL
	--primary key (case_id))
	--create type current_lpu as table(id int primary key, parent_id int null, code int, short_name nvarchar(150))

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
                      left join p_person AS pp ON ac.patient_id = pp.id
             WHERE visit.visit_date BETWEEN @sdate AND @edate and exists (select id from  @current_lpu cur where cur.id=ac.lpu_id)
         ),
         a_tmp_spec(f_v_date, case_id, lpu_id, doctor_id, post_code, patient_id, icd10)
             AS (
             SELECT  ac.f_v_date, a_spec.case_id, ac.lpu_id, ac.doctor_id, ac.post_code, ac.patient_id, a_spec.icd10
             FROM @a_case_v AS ac
             JOIN A_specialist AS a_spec ON ac.case_id = a_spec.case_id
             GROUP BY ac.f_v_date, a_spec.case_id, ac.lpu_id, ac.doctor_id, ac.post_code, ac.patient_id, a_spec.icd10
         ),
         count_c5(lpu_id, c5)
             AS (
             SELECT visit.lpu_id, count(*) AS c5
             FROM a_tmp_visit AS visit
             WHERE visit.vistyp_code <> 28
             GROUP BY visit.lpu_id
         ),
         count_c6(lpu_id, c6)
             AS (
             SELECT visit.lpu_id, count(*) c6
             FROM a_tmp_visit AS visit
             WHERE visit.vistyp_code <> 28 AND
                     exists (SELECT d.case_id
                                       FROM A_diagnosis d
                                       WHERE d.icd10 BETWEEN 'A00' AND 'T989' and visit.case_id=d.case_id)
             GROUP BY visit.lpu_id
         ),
         count_c7(lpu_id, c7)
             AS (
             SELECT atcv.lpu_id, count(*) AS c7
             FROM @a_case_v AS atcv
             GROUP BY atcv.lpu_id
         ),
         count_c8(lpu_id, c8)
             AS (
             SELECT atcv.lpu_id, count(*) AS c8
             FROM @a_case_v AS atcv
             WHERE exists ( SELECT d.case_id
                                     FROM A_diagnosis d
                                     WHERE d.icd10 BETWEEN 'A00' AND 'T989' and atcv.case_id=d.case_id)
             GROUP BY atcv.lpu_id
         ),
         count_c9(lpu_id, c9)
             AS (
             SELECT atcv.lpu_id, count(*) AS c9
             FROM @a_case_v AS atcv
                      JOIN A_diagnosis AS d ON atcv.case_id = d.case_id
             WHERE (((atcv.hosp_id) IS NOT NULL AND (atcv.hosp_id) <> 0))
               AND d.basic = 1
               AND d.icd10 BETWEEN 'A00' AND 'T989'
             GROUP BY atcv.lpu_id
         ),
         count_c10(lpu_id, c10)
             AS (
             SELECT a_tmp_spec.lpu_id, count(*) c10
             FROM a_tmp_spec
             WHERE a_tmp_spec.icd10 BETWEEN 'A00' AND 'T989'
             GROUP BY a_tmp_spec.lpu_id
         ),
         a_tmp_a3(icd, lpu_id, case_id, life)
             AS (
             SELECT icd, lpu_id, case_id,
                    (SELECT top 1 is_f_life
                     FROM A_diagnosis
                     WHERE case_id = sub.case_id
                     ORDER BY is_f_life DESC) AS life
             FROM
                 (SELECT diagnose.icd10 AS icd,
                         min(visit.lpu_id)  AS lpu_id,
                         min(visit.case_id) AS case_id
                  FROM a_tmp_visit AS visit
                           JOIN A_diagnosis AS diagnose ON visit.case_id = diagnose.case_id
                           JOIN @current_lpu cur ON cur.id = visit.lpu_id
                  WHERE visit.vistyp_code IN (26, 27)
                  GROUP BY diagnose.icd10, visit.patient_id) AS sub
         ),
         count_a1(lpu_id, a1)
             AS (
             SELECT visit.lpu_id, count(*) AS a1
             FROM a_tmp_visit AS visit
             WHERE visit.vistyp_code IN (26, 27)
             GROUP BY visit.lpu_id
         ),
         count_a2(lpu_id, a2)
             AS (
             SELECT visit.lpu_id, count(*) AS a2
             FROM a_tmp_visit AS visit
             WHERE birth_day < DateAdd(yyyy, -15, visit_date) AND visit.vistyp_code IN (26, 27)
             GROUP BY visit.lpu_id
         ),
         count_a3(lpu_id, a3)
             AS (
             SELECT lpu_id, count(*) AS a3
             FROM a_tmp_a3
             WHERE icd BETWEEN 'I10' AND 'I139'
             GROUP BY lpu_id
         ),
         count_a4(lpu_id, a4)
             AS (
             SELECT lpu_id, count(*) AS a4
             FROM a_tmp_a3
             WHERE icd BETWEEN 'I10' AND 'I139' AND life = 1
             GROUP BY lpu_id
         ),
         count_a5(lpu_id, a5)
             AS (
             SELECT lpu_id, count(*) AS a5
             FROM a_tmp_a3
             WHERE icd BETWEEN 'A15' AND 'A199'
             GROUP BY lpu_id
         ),
         count_a6(lpu_id, a6)
             AS (
             SELECT lpu_id, count(*) a6
             FROM a_tmp_a3
             WHERE (icd BETWEEN 'Z34' AND 'Z348') OR (icd BETWEEN 'O00' AND 'O999')
             GROUP BY lpu_id
         ),
         all_gsv(order_col, id, parent_id, short_name, code, c5, c6, c7, c8, c9, c10, a1, a2, a3, a4, a5, a6, group_col)
             AS (
             SELECT CASE WHEN parent_id IS NULL THEN -2 ELSE 0 END AS order_col,
					CASE WHEN parent_id IS NULL THEN -2 ELSE cur.id END AS id,
                    cur.parent_id, CASE WHEN parent_id IS NULL THEN 'Уз.Специалисты' ELSE cur.short_name END AS short_name,
                    cur.code, count_c5.c5, count_c6.c6, count_c7.c7, count_c8.c8, count_c9.c9, count_c10.c10,
                    count_a1.a1, count_a2.a2, count_a3.a3, count_a4.a4, count_a5.a5, count_a6.a6,
                    1 AS group_col
             FROM @current_lpu cur
                      LEFT JOIN count_c5  ON cur.id = count_c5.lpu_id
                      LEFT JOIN count_c6  ON cur.id = count_c6.lpu_id
                      LEFT JOIN count_c7  ON cur.id = count_c7.lpu_id
                      LEFT JOIN count_c8  ON cur.id = count_c8.lpu_id
                      LEFT JOIN count_c9  ON cur.id = count_c9.lpu_id
                      LEFT JOIN count_c10 ON cur.id = count_c10.lpu_id
                      LEFT JOIN count_a1  ON cur.id = count_a1.lpu_id
                      LEFT JOIN count_a2  ON cur.id = count_a2.lpu_id
                      LEFT JOIN count_a3  ON cur.id = count_a3.lpu_id
                      LEFT JOIN count_a4  ON cur.id = count_a4.lpu_id
                      LEFT JOIN count_a5  ON cur.id = count_a5.lpu_id
                      LEFT JOIN count_a6  ON cur.id = count_a6.lpu_id
         ),
         svod_gsv(order_col, id, parent_id, short_name, code, c5, c6, c7, c8, c9, c10, a1, a2, a3, a4, a5, a6)
             AS (
             SELECT -1 as order_col, -1 AS id, null AS parent_id, 'ВсеГСВ' AS short_name, null AS code
                  ,SUM(c5) AS c5,SUM(c6) AS c6
                  ,SUM(c7) AS c7,SUM(c8) AS c8
                  ,SUM(c9) AS c9,SUM(c10) AS c10
                  ,SUM(a1) AS a1,SUM(a2) AS a2
                  ,SUM(a3) AS a3,SUM(a4) AS a4
                  ,SUM(a5) AS a5,SUM(a6) AS a6
             FROM all_gsv where parent_id is not null
         ),
         svod_csm(order_col, id, parent_id, short_name, code, c5, c6, c7, c8, c9, c10, a1, a2, a3, a4, a5, a6)
             AS (
             SELECT -3 as order_col, -3 AS id, null AS parent_id, 'CSM' AS short_name, null AS code
                  ,SUM(c5), SUM(c6), SUM(c7), SUM(c8), SUM(c9), SUM(c10)
                  ,SUM(a1), SUM(a2), SUM(a3), SUM(a4),SUM(a5), SUM(a6)
             FROM all_gsv
         )
    SELECT  id, parent_id, short_name, code
         ,coalesce(c5, 0) AS c5 ,coalesce(c6, 0) AS c6 ,coalesce(c7, 0) AS c7 ,coalesce(c8, 0) AS c8
         ,coalesce(c9, 0) AS c9 ,coalesce(c10, 0) AS c10 ,coalesce(a1, 0) AS a1 ,coalesce(a2, 0) AS a2
         ,coalesce(a3, 0) AS a3 ,coalesce(a4, 0) AS a4 ,coalesce(a5, 0) AS a5 ,coalesce(a6, 0) AS a6
    FROM (
             SELECT order_col, cur.id, cur.parent_id, cur.short_name, cur.code,
                    c5, c6, c7, c8, c9, c10, a1, a2, a3, a4, a5, a6,
                    (CASE WHEN @lpu_id > 0 AND @lpu_parent_id IS NULL THEN 1 ELSE 0 END) AS show_all
             FROM svod_csm
             JOIN @current_lpu cur ON cur.parent_id IS NULL
             UNION ALL
             SELECT order_col, id, parent_id, short_name, code, c5, c6, c7, c8, c9, c10, a1, a2, a3, a4, a5, a6,
                    (CASE WHEN @lpu_id > 0 AND @lpu_parent_id IS NULL THEN 1 ELSE 0 END) AS show_all
             FROM svod_gsv
             UNION ALL
             SELECT order_col, id, parent_id, short_name, code, c5, c6, c7, c8, c9, c10, a1, a2, a3, a4, a5, a6,
                    (CASE WHEN @lpu_id > 0 AND @lpu_parent_id IS NULL THEN 1 ELSE 0 END) AS show_all
             FROM all_gsv
         ) AS result
    WHERE id = (CASE WHEN @lpu_id < 0 OR @lpu_parent_id IS NOT NULL THEN @lpu_id ELSE 0 END)
       OR show_all = 1
    ORDER BY order_col, id;


END;