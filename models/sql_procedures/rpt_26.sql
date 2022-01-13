-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
declare @sdate date = '2020-01-01';
declare @edate date = '2020-03-06';
execute rpt_26 @sdate, @edate, @lpu_id,@lpu_parent_id, 'diseases'

GO
IF OBJECT_ID ( 'rpt_26', 'P' ) IS NOT NULL DROP PROCEDURE rpt_26;

GO
CREATE PROCEDURE rpt_26 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
AS
BEGIN
    DECLARE @where_lpu VARCHAR(100) = '';
    DECLARE @select_lpu VARCHAR(100) = 'lpu.id = a_c.patient_lpu';

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

    DECLARE @result_rpt_26 NVARCHAR(MAX) = '
    WITH rows(num, sex)
        AS (
            SELECT num, sex from (VALUES(1, ''Всего''),(2, ''Мужчины''),(3, ''Женщины''))nums(num, sex)
        ),
        risk_factor(num,c1,c3,c3,c4,c5,c6,c7,c8,c9)
        AS(
            select
                CASE WHEN sex_id IS NULL THEN 1 WHEN sex_id = 0 THEN 3 ELSE 2 END AS num,
                count(case_id) AS c1,
                coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and case_id is not null then 1 else null end) AS c2,
                coalesce(count(case when percen IS NOT NULL THEN 1 ELSE NULL END),0) AS c3,
                coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) AND percen IS NOT NULL THEN 1 ELSE NULL END),0) AS c4,
                coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=1 then 1 else null end),0) AS c5,
                coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=2 then 1 else null end),0) AS c6,
                coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=3 then 1 else null end),0) AS c7,
                coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=4 then 1 else null end),0) AS c8,
                coalesce(count(case when birth_day<DateAdd(yyyy, -40, f_v_date) and percen=5 then 1 else null end),0) AS c9
            from (
                 select a_c.f_v_date, p_p.birth_day, p_p.sex_id, min(a_r.percen) AS percen
                 from a_case as a_c
                  inner join a_diagnosis AS a_d on a_c.id=a_d.case_id
                  inner join p_person AS p_p on a_c.patient_id=p_p.id
                  inner join glb_lpu AS lpu on '+ @select_lpu +'
                  left join A_risk AS a_r on a_c.id=a_r.case_id
                 where a_d.is_final=1 AND p_p.birth_day<DateAdd(yyyy, -18, a_c.f_v_date)
                    and a_c.f_v_date between @sdate AND @edate
                    and a_d.icd10 between ''A00'' And ''T989''
                    and ('+ @where_lpu +')
                 group by a_c.patient_id, p_p.birth_day, p_p.sex_id, a_c.case_id, a_c.f_v_date, a_c.post_code
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
    left join risk_factor AS rf on rows.num = rf.num
    order by rows.num;
    '

    EXECUTE sp_executesql @result_rpt_26, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id

END;