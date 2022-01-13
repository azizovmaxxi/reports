-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-07-06';
--execute m_rpt_5 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'm_rpt_5', 'P' ) IS NOT NULL DROP PROCEDURE m_rpt_5;

GO
CREATE PROCEDURE m_rpt_5 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
AS
BEGIN
    DECLARE @where_lpu VARCHAR(100) = '';

    IF @lpu_parent_id IS NULL
        set @where_lpu = 'lpu.id = @lpu_id OR lpu.parent_id = @lpu_id'

    IF @lpu_id > 0 AND @lpu_parent_id IS NOT NULL
        SET @where_lpu = 'lpu.id = @lpu_id';
    IF @lpu_id = -1
        SET @where_lpu = 'lpu.parent_id = @lpu_parent_id';
    IF @lpu_id = -2
        SET @where_lpu = 'lpu.id = @lpu_parent_id';

    DECLARE @result_m_rpt_5 NVARCHAR(MAX) = '
        WITH mark (num)
            AS ( SELECT num from (VALUES(1),(2),(3),(4),(5))nums(num)),
        chields(num, dang_signs_chield, life_three_day)
        AS (
             SELECT 1 AS num
                  , MAX(CONVERT(tinyint, dang_signs_chield)) AS dang_signs_chield
                  , MAX(COALESCE(life_three_day, 0)) AS life_three_day
             FROM M_case
                      INNER JOIN M_chield AS Mc on M_case.id = Mc.case_id
                      INNER JOIN glb_lpu AS lpu ON M_case.lpu_id = lpu.id
             WHERE (dang_signs_chield = 1 OR life_three_day IS NOT NULL)
               AND M_case.f_v_date BETWEEN @sdate AND @edate
               AND '+ @where_lpu +'
             GROUP BY M_case.patient_id
        ),
         chield_visits(num, patient_id, after_discharge)
             AS (
             SELECT 2 AS num, patient_id, after_discharge
             FROM M_case
                      INNER JOIN M_visit_chield AS Mvc ON M_case.id = Mvc.case_id
                      INNER JOIN glb_lpu AS lpu ON M_case.lpu_id = lpu.id
             WHERE yes_no = 1
               AND M_case.f_v_date BETWEEN @sdate AND @edate
               AND '+ @where_lpu +'
             GROUP BY patient_id, after_discharge
         ),
         feedings_1_year(num, patient_id, month3, month6)
             AS (
             SELECT 3 AS num, patient_id
                  , MAX(CONVERT(tinyint, month3)) AS month3
                  , MAX(CONVERT(tinyint, month6)) AS month6
             FROM M_case
                      INNER JOIN P_person Pp on M_case.patient_id = Pp.id
                      INNER JOIN M_b_feeding Mbf on M_case.id = Mbf.case_id
                      INNER JOIN glb_lpu lpu on M_case.lpu_id = lpu.id
             WHERE (birth_day<=DateAdd(yyyy, -1, f_v_date) AND birth_day>DateAdd(yyyy, -2, f_v_date))
               AND f_v_date BETWEEN @sdate AND @edate
               AND '+ @where_lpu +'
             GROUP BY patient_id
         ),
         child_evaluation(num, eval_month7, eval_year1_5, eval_year2_5, eval_year3_5)
             AS (
             SELECT 4 AS num
                  , MAX(CONVERT(tinyint, eval_month7)) AS eval_month7
                  , MAX(CONVERT(tinyint, [eval_year1.5])) AS eval_year1_5
                  , MAX(CONVERT(tinyint, [eval_year2.5])) AS eval_year2_5
                  , MAX(CONVERT(tinyint, [eval_year3.5])) AS eval_year3_5
             FROM M_case
                      INNER JOIN P_person Pp on M_case.patient_id = Pp.id
                      INNER JOIN M_b_feeding Mbf on M_case.id = Mbf.case_id
                      INNER JOIN glb_lpu lpu on M_case.lpu_id = lpu.id
             WHERE (eval_month7 = 1 OR [eval_year1.5] = 1 OR [eval_year2.5] = 1 OR [eval_year3.5] = 1)
               AND f_v_date BETWEEN @sdate AND @edate
               AND '+ @where_lpu +'
             GROUP BY patient_id
         ),
         mother_health(num, is_registered,got_acid,doctor_visit,dang_signs_mother,got_ferrum,got_iodine,dang_signs_preg)
             AS (
             SELECT 5 AS num
                  , MAX(CONVERT(tinyint, is_registered)) AS is_registered
                  , MAX(CONVERT(tinyint, got_acid)) AS got_acid
                  , MAX(CONVERT(tinyint, doctor_visit)) AS doctor_visit
                  , MAX(CONVERT(tinyint, dang_signs_mother)) AS dang_signs_mother
                  , MAX(CONVERT(tinyint, got_ferrum)) AS got_ferrum
                  , MAX(CONVERT(tinyint, got_iodine)) AS got_iodine
                  , MAX(CONVERT(tinyint, dang_signs_preg)) AS dang_signs_preg
             FROM M_case
             INNER JOIN M_mother_health Mmh ON M_case.id = Mmh.case_id
             INNER JOIN glb_lpu lpu on M_case.lpu_id = lpu.id
             WHERE f_v_date BETWEEN @sdate AND @edate
               AND '+ @where_lpu +'
             GROUP BY patient_id
         )
        SELECT
            COUNT(CASE WHEN ch.life_three_day <> 0 THEN 1 ELSE NULL END) AS s5_c1
             , COUNT(CASE WHEN ch.dang_signs_chield <> 0 THEN 1 ELSE NULL END) AS s5_c2
             , COUNT(CASE WHEN chv.after_discharge = 2 THEN 1 ELSE NULL END) AS s5_c3
             , COUNT(CASE WHEN chv.after_discharge = 3 THEN 1 ELSE NULL END) AS s5_c4
             , COUNT(CASE WHEN chv.after_discharge = 4 THEN 1 ELSE NULL END) AS s5_c5
             , COUNT(CASE WHEN chv.after_discharge = 5 THEN 1 ELSE NULL END) AS s5_c6
             , COUNT(CASE WHEN chv.after_discharge = 6 THEN 1 ELSE NULL END) AS s5_c7
             , COUNT(CASE WHEN chv.after_discharge = 7 THEN 1 ELSE NULL END) AS s5_c8
             , COUNT(CASE WHEN chv.after_discharge = 8 THEN 1 ELSE NULL END) AS s5_c9
             -- section_5_1
             , COUNT(f1y.patient_id) AS s5_1_c1
             , COUNT(CASE WHEN f1y.month3 = 1 THEN 1 ELSE NULL END) AS s5_1_c2
             , COUNT(CASE WHEN f1y.month6 = 1 THEN 1 ELSE NULL END) AS s5_1_c3
             -- section_5_2
             , COUNT(CASE WHEN ce.eval_month7 = 1 THEN 1 ELSE NULL END) AS s5_2_c1
             , COUNT(CASE WHEN ce.eval_year1_5 = 1 THEN 1 ELSE NULL END) AS s5_2_c2
             , COUNT(CASE WHEN ce.eval_year2_5 = 1 THEN 1 ELSE NULL END) AS s5_2_c3
             , COUNT(CASE WHEN ce.eval_year3_5 = 1 THEN 1 ELSE NULL END) AS s5_2_c4
             -- table_7
             , COUNT(CASE WHEN mh.is_registered = 1 THEN 1 ELSE NULL END) AS t7_c1
             , COUNT(CASE WHEN mh.got_acid = 1 THEN 1 ELSE NULL END) AS t7_c2
             , COUNT(CASE WHEN mh.got_ferrum = 1 THEN 1 ELSE NULL END) AS t7_c3
             , COUNT(CASE WHEN mh.got_iodine = 1 THEN 1 ELSE NULL END) AS t7_c4
             , COUNT(CASE WHEN mh.dang_signs_preg = 1 THEN 1 ELSE NULL END) AS t7_c5
             , COUNT(CASE WHEN mh.dang_signs_mother = 1 THEN 1 ELSE NULL END) AS t7_c6
             , COUNT(CASE WHEN mh.doctor_visit = 1 THEN 1 ELSE NULL END) AS t7_c7
        FROM mark
         LEFT JOIN chields ch ON ch.num = mark.num
         LEFT JOIN chield_visits chv ON chv.num = mark.num
         LEFT JOIN feedings_1_year f1y ON mark.num = f1y.num
         LEFT JOIN child_evaluation ce ON mark.num = ce.num
         LEFT JOIN mother_health mh ON mark.num = mh.num
    '

    EXECUTE sp_executesql @result_m_rpt_5, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id
END