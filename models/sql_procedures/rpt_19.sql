-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-07-06';
-- execute rpt_19 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_19', 'P' ) IS NOT NULL DROP PROCEDURE rpt_19;

GO
CREATE PROCEDURE rpt_19 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
AS
BEGIN
    DECLARE @where_lpu VARCHAR(100) = '';
    DECLARE @population_lpu VARCHAR(100) = 'lpu.parent_id = @lpu_parent_id';
    DECLARE @select_lpu VARCHAR(100) = 'lpu.id = a_c.patient_lpu';

    IF @lpu_parent_id IS NULL
    BEGIN
        set @where_lpu = 'lpu.id = @lpu_id OR lpu.parent_id = @lpu_id'
        set @population_lpu = 'lpu.parent_id = @lpu_id'
    END

    IF @lpu_id > 0 AND @lpu_parent_id IS NOT NULL
    BEGIN
        set @where_lpu = 'lpu.id = @lpu_id';
        set @population_lpu = 'lpu.id = @lpu_id';
    END

    IF @lpu_id = -1
        set @where_lpu = 'lpu.parent_id = @lpu_parent_id';
    IF @lpu_id = -2
        BEGIN
            set @where_lpu = 'lpu.id = @lpu_parent_id';
            set @select_lpu = 'lpu.id = a_c.lpu_id';
        END

    DECLARE @result_rpt_19 NVARCHAR(MAX) = '
        WITH rows(num, sex)
        AS (
            SELECT num, sex from (VALUES(1, ''Всего''),(2, ''Мужчины''),(3, ''Женщины''))nums(num, sex)
        ),
        persons_18_and_greater(num, c1, c2)
        AS (
            SELECT
                CASE WHEN P_person_lpu.sex_id IS NULL THEN 1 WHEN P_person_lpu.sex_id = 0 THEN 3 ELSE 2 END AS num,
                coalesce(COUNT(p_c.cat_id),0) AS c1,
                coalesce(COUNT(CASE WHEN P_person_lpu.birth_day < DateAdd(yyyy, -40, GETDATE()) THEN 1 ELSE NULL END),0) AS C2
            FROM p_category AS p_c
            INNER JOIN  glb_P_category ON p_c.cat_id = glb_P_category.id
            INNER JOIN (
                SELECT p_p.sex_id, p_p.birth_day, p_p.id AS person_id
                FROM P_person AS p_p
                JOIN P_PersonAssignment AS p_pa ON p_p.id = p_pa.person_id
                JOIN glb_lpu AS lpu ON p_pa.gsv_id = lpu.id
                WHERE p_pa.end_date IS NULL AND ('+ @population_lpu +')
            ) AS P_person_lpu ON p_c.person_id = P_person_lpu.person_id
            WHERE p_c.start_date <= GETDATE()
                AND (p_c.end_date IS NULL OR p_c.end_date>(GETDATE()))
                AND glb_P_category.cattype = 3
                AND P_person_lpu.birth_day < DateAdd(yyyy, -18, GETDATE())
            GROUP BY P_person_lpu.sex_id WITH ROLLUP
        ),
        arterial_pressure(num, c3, c4, c5, c6)
        AS (
            SELECT CASE WHEN sex_id IS NULL THEN 1 WHEN sex_id = 0 THEN 3 ELSE 2 END AS num,
                   COUNT(case_id) AS c3,
                   COUNT(CASE WHEN birth_day<DateAdd(yyyy, -40, f_v_date) AND (dm=1 OR dm=2) THEN 1 ELSE NULL END) c4,
                   COUNT(CASE WHEN birth_day<DateAdd(yyyy, -40, f_v_date) AND dm=1 THEN 1 ELSE NULL END) c5,
                   COUNT(CASE WHEN birth_day<DateAdd(yyyy, -40, f_v_date) AND dm=2 THEN 1 ELSE NULL END) c6
            FROM (
                SELECT MIN(a_c.id) AS case_id,  min(a_c.f_v_date) AS f_v_date, MIN(a_p.dm) AS dm, p_p.birth_day, p_p.sex_id
                FROM a_case AS a_c
                INNER JOIN a_diagnosis AS a_d ON a_c.id = a_d.case_id
                INNER JOIN p_person AS p_p ON a_c.patient_id = p_p.id
                INNER JOIN a_pressure AS a_p ON a_c.id = a_p.case_id
                INNER JOIN glb_lpu AS lpu ON '+ @select_lpu +'
                WHERE a_d.is_final=1
                  AND a_d.icd10 BETWEEN ''A00'' AND ''T989''
                  AND p_p.birth_day<DateAdd(yyyy, -18, f_v_date)
                  AND a_p.dm IS NOT NULL
                  AND a_c.f_v_date BETWEEN @sdate AND @edate
                  AND ('+ @where_lpu +')
                GROUP BY a_c.patient_id, p_p.birth_day, p_p.sex_id
            ) AS sub_query
            GROUP BY SEX_ID WITH ROLLUP
        )
        SELECT rows.num, rows.sex
            ,coalesce(p18g.c1, 0) AS c1, coalesce(p18g.c2, 0) AS c2
            ,coalesce(ap.c3, 0) AS c3, coalesce(ap.c4, 0) AS c4
            ,coalesce(ap.c5, 0) AS c5 , coalesce(ap.c6, 0) AS c6
            ,coalesce(cast((c3*100.0/NULLIF(c1,0)) as decimal(5,2)),0) AS c3_pr
            ,coalesce(cast((c4*100.0/NULLIF(c2,0)) as decimal(5,2)),0) AS c4_pr
            ,coalesce(cast((c5*100.0/NULLIF(c4,0)) as decimal(5,2)),0) AS c5_pr
            ,coalesce(cast((c6*100.0/NULLIF(c4,0)) as decimal(5,2)),0) AS c6_pr
        FROM rows
        LEFT JOIN persons_18_and_greater AS p18g on rows.num = p18g.num
        LEFT JOIN arterial_pressure AS ap on rows.num = ap.num
        ORDER BY rows.num;
        '

    EXECUTE sp_executesql @result_rpt_19, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id
END