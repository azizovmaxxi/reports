-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 68241--61411;
-- declare @lpu_parent_id integer = null;
-- declare @sdate date = '2020-02-25';
-- declare @edate date = '2020-04-25';
--
-- execute rpt_12 @sdate, @edate, @lpu_id,@lpu_parent_id, 'diseases';

GO
IF OBJECT_ID ( 'rpt_12', 'P' ) IS NOT NULL DROP PROCEDURE rpt_12;

GO
CREATE PROCEDURE rpt_12 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT, @type_rpt VARCHAR(50),
                        @doctor_id VARCHAR(50) = null, @post_code VARCHAR(50) = null
AS
BEGIN
    DECLARE @where_lpu VARCHAR(100) = '';
    DECLARE @select_lpu VARCHAR(100) = 'lpu.id = a_c.patient_lpu';
    DECLARE @where VARCHAR(100) = '';

    IF @lpu_parent_id IS NULL
        set @where_lpu = 'lpu.id = @lpu_id OR lpu.parent_id = @lpu_id'

    IF @lpu_id > 0 AND @lpu_parent_id IS NOT NULL
        set @where_lpu = 'lpu.id = @lpu_id';

    IF @lpu_id = -1
        set @where_lpu = 'lpu.parent_id = @lpu_parent_id';
    IF @lpu_id = -2
        BEGIN
            set @where_lpu = 'lpu.id = @lpu_parent_id';
            set @select_lpu = 'lpu.id = a_c.lpu_id';
        END

    IF @doctor_id IS NOT NULL
        set @where = concat(@where, ' AND a_c.doctor_id = @doctor_id');

    IF @post_code IS NOT NULL
        set @where = concat(@where, ' AND a_c.post_code = @post_code');

    IF @type_rpt = 'diseases'
        set @where = concat(@where, ' AND a_d.icd10 BETWEEN ''I10'' AND ''I139''');
    ELSE
        set @where = concat(@where, ' AND a_d.icd10 BETWEEN ''A00'' AND ''T989''');

    DECLARE @result_rpt_12 NVARCHAR(MAX) = '
    WITH rows(num, sex)
         AS (
        SELECT num, sex from (VALUES(1, ''Всего''),(2, ''Мужчины''),(3, ''Женщины''))nums(num, sex)
    ),
     risk_factor(num, c1,c2,c3,c4,c5,c6,c7,c8,c9)
         AS(
         select
             CASE WHEN sex_id IS NULL THEN 1 WHEN sex_id = 0 THEN 3 ELSE 2 END AS num,
             coalesce(count(case_id),0) as c1,
             coalesce(count(CASE WHEN birth_day<DateAdd(yyyy, -40, f_v_date) AND case_id IS NOT NULL THEN 1 ELSE NULL END),0) c2,
             coalesce(count(CASE WHEN percen IS NOT NULL THEN 1 ELSE NULL END),0) AS c3,
             coalesce(count(CASE WHEN birth_day<DateAdd(yyyy, -40, f_v_date) AND percen IS NOT NULL THEN 1 ELSE NULL END),0) AS c4,
             coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=1 then 1 else null end),0) AS c5,
             coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=2 then 1 else null end),0) AS c6,
             coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=3 then 1 else null end),0) AS c7,
             coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=4 then 1 else null end),0) AS c8,
             coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=5 then 1 else null end),0) AS c9
         from (
                  SELECT a_c.id AS case_id, a_c.f_v_date, a_c.patient_id, p_p.birth_day, p_p.sex_id,
                         a_c.post_code, min(d.percen) as percen
                  FROM a_case AS a_c
                  INNER JOIN a_diagnosis AS a_d ON a_c.id=a_d.case_id
                  INNER JOIN p_person AS p_p ON a_c.patient_id=p_p.id
                  INNER JOIN glb_lpu AS lpu ON '+ @select_lpu +'
                  LEFT JOIN A_risk d ON a_c.id=d.case_id
                  WHERE a_d.is_final=1
                    AND a_c.f_v_date BETWEEN @sdate AND @edate
                    AND p_p.birth_day < DateAdd(yyyy, -18, f_v_date)
                    AND ('+ @where_lpu +')
                    '+ @where +'
                  GROUP BY a_c.id, a_c.f_v_date, a_c.patient_id, p_p.birth_day, p_p.sex_id, a_c.doctor_id, a_c.post_code, a_c.lpu_id
              ) AS result
         group by sex_id WITH ROLLUP
     )
    select rows.num, rows.sex
     ,rf.c1,rf.c2,rf.c3, rf.c4, rf.c5, rf.c6, rf.c7, rf.c8, rf.c9
     ,coalesce(cast((c4*100.0/NULLIF(c2,0)) as decimal(5,2)),0) AS c4_pr
     ,coalesce(cast((c5*100.0/NULLIF(c4,0)) as decimal(5,2)),0) AS c5_pr
     ,coalesce(cast((c6*100.0/NULLIF(c4,0)) as decimal(5,2)),0) AS c6_pr
     ,coalesce(cast((c7*100.0/NULLIF(c4,0)) as decimal(5,2)),0) AS c7_pr
     ,coalesce(cast((c8*100.0/NULLIF(c4,0)) as decimal(5,2)),0) AS c8_pr
     ,coalesce(cast((c9*100.0/NULLIF(c4,0)) as decimal(5,2)),0) AS c9_pr
    from rows
    left join risk_factor AS rf on rows.num = rf.num
    order by rows.num;'

    EXECUTE sp_executesql @result_rpt_12, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT,
        @doctor_id VARCHAR(50), @post_code VARCHAR(50)',
            @sdate, @edate, @lpu_id, @lpu_parent_id, @doctor_id, @post_code

END