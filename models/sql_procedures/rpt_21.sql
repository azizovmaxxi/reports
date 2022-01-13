-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-03-06';
-- execute rpt_21 @sdate, @edate, @lpu_id,@lpu_parent_id, 'diseases'

GO
IF OBJECT_ID ( 'rpt_21', 'P' ) IS NOT NULL DROP PROCEDURE rpt_21;

GO
CREATE PROCEDURE rpt_21 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT, @type_rpt VARCHAR(50)
AS
BEGIN
    DECLARE @where_lpu VARCHAR(100) = '';
    DECLARE @risk_factor_lpu VARCHAR(100) = 'lpu.id = a_c.patient_lpu';
    DECLARE @risk_factor_icd10 VARCHAR(100) = '';
    DECLARE @risk_factor_grouping VARCHAR(100) = '';

    IF @type_rpt = 'diseases'
    BEGIN
        set @risk_factor_icd10 = ' a_d.icd10 between ''I10'' and ''I139'' ';
        set @risk_factor_grouping = ' a_c.patient_id, p_p.birth_day, p_p.sex_id, a_c.f_v_date, a_r.percen ';
    END
    ELSE
    BEGIN
        set @risk_factor_icd10 = ' a_d.icd10 between ''A00'' And ''T989'' ';
        set @risk_factor_grouping = ' a_c.patient_id, p_p.birth_day, p_p.sex_id ';
    END

    IF @lpu_parent_id IS NULL
        set @where_lpu = 'lpu.id = @lpu_id OR lpu.parent_id = @lpu_id'

    IF @lpu_id > 0 AND @lpu_parent_id IS NOT NULL
        set @where_lpu = 'lpu.id = @lpu_id';

    IF @lpu_id = -1
        set @where_lpu = 'lpu.parent_id = @lpu_parent_id';
    IF @lpu_id = -2
    BEGIN
        set @where_lpu = 'lpu.id = @lpu_parent_id';
        set @risk_factor_lpu = 'lpu.id = a_c.lpu_id';
    END

    DECLARE @result_rpt_21 NVARCHAR(MAX) = '
    WITH rows(num, sex)
        AS (
            SELECT num, sex from (VALUES(1, ''Всего''),(2, ''Мужчины''),(3, ''Женщины''))nums(num, sex)
        ),
        persons_18_and_greater(num, c1, c2)
        AS (
            select
                CASE WHEN P_person_lpu.sex_id IS NULL THEN 1 WHEN P_person_lpu.sex_id = 0 THEN 3 ELSE 2 END AS num,
                coalesce(COUNT(p_c.cat_id),0) AS c1,
                coalesce(COUNT(CASE WHEN P_person_lpu.birth_day < DateAdd(yyyy, -40, GETDATE()) THEN 1 ELSE NULL END),0) AS C2
            FROM p_category AS p_c
            INNER JOIN  glb_P_category ON p_c.cat_id = glb_P_category.id
            INNER JOIN (
               select p_p.sex_id, p_p.birth_day, p_p.id as person_id
               from P_person as p_p
               join P_PersonAssignment as p_pa on p_p.id = p_pa.person_id
               join glb_lpu as lpu on p_pa.gsv_id = lpu.id
               where p_pa.end_date is null AND ('+ @where_lpu +')
            ) AS P_person_lpu ON p_c.person_id = P_person_lpu.person_id
            WHERE p_c.start_date <= GETDATE()
              and (p_c.end_date is null or p_c.end_date>(GETDATE()))
              and glb_P_category.cattype = 3
              And P_person_lpu.birth_day < DateAdd(yyyy, -18, GETDATE())
            group by P_person_lpu.sex_id WITH ROLLUP
        ),
        risk_factor(num, c3,c4,c5,c6,c7,c8,c9)
        AS(
            select
                CASE WHEN sex_id IS NULL THEN 1 WHEN sex_id = 0 THEN 3 ELSE 2 END AS num,
                coalesce(count(CASE WHEN percen IS NOT NULL THEN 1 ELSE NULL END),0) AS c3,
                coalesce(count(CASE WHEN birth_day<DateAdd(yyyy, -40, f_v_date) AND percen IS NOT NULL THEN 1 ELSE NULL END),0) AS c4,
                coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=1 then 1 else null end),0) AS c5,
                coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=2 then 1 else null end),0) AS c6,
                coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=3 then 1 else null end),0) AS c7,
                coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=4 then 1 else null end),0) AS c8,
                coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=5 then 1 else null end),0) AS c9
            from (
                 select min(a_c.f_v_date) AS f_v_date, p_p.birth_day, p_p.sex_id, min(a_r.percen) AS percen
                 from a_case as a_c
                  inner join a_diagnosis AS a_d on a_c.id=a_d.case_id
                  inner join p_person AS p_p on a_c.patient_id=p_p.id
                  inner join glb_lpu AS lpu on '+ @risk_factor_lpu +'
                  left join A_risk AS a_r on a_c.id=a_r.case_id
                 where a_d.is_final=1 AND p_p.birth_day<DateAdd(yyyy, -18, a_c.f_v_date)
                    and a_c.f_v_date between @sdate AND @edate
                    and '+ @risk_factor_icd10 +'
                    and ('+ @where_lpu +')
                 group by '+ @risk_factor_grouping +'
            ) AS result
            group by sex_id WITH ROLLUP
        )
    select rows.num, rows.sex,
          coalesce(p18g.c1, 0) AS c1, coalesce(p18g.c2, 0) AS c2
         ,rf.c3, rf.c4, rf.c5, rf.c6, rf.c7, rf.c8, rf.c9
         ,coalesce(cast((c4*100.0/NULLIF(c2,0)) as decimal(5,2)),0) AS c4_pr
         ,coalesce(cast((c5*100.0/NULLIF(c4,0)) as decimal(5,2)),0) AS c5_pr
         ,coalesce(cast((c6*100.0/NULLIF(c4,0)) as decimal(5,2)),0) AS c6_pr
         ,coalesce(cast((c7*100.0/NULLIF(c4,0)) as decimal(5,2)),0) AS c7_pr
         ,coalesce(cast((c8*100.0/NULLIF(c4,0)) as decimal(5,2)),0) AS c8_pr
         ,coalesce(cast((c9*100.0/NULLIF(c4,0)) as decimal(5,2)),0) AS c9_pr
    from rows
    left join persons_18_and_greater AS p18g on rows.num = p18g.num
    left join risk_factor AS rf on rows.num = rf.num
    order by rows.num;
    '

    EXECUTE sp_executesql @result_rpt_21, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT, @type_rpt VARCHAR(50)',
            @sdate, @edate, @lpu_id, @lpu_parent_id, @type_rpt

END;