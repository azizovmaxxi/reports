-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-03-06';
-- execute rpt_29 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_29', 'P' ) IS NOT NULL DROP PROCEDURE rpt_29;

GO
CREATE PROCEDURE rpt_29 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
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

    DECLARE @result_rpt_29 NVARCHAR(MAX) = '
    WITH calc_result(c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19)
    AS (
        SELECT COUNT(*) AS c1,
           --
           COUNT(CASE WHEN p_p.sex_id = 1 AND p_p.birth_day>DateAdd(yyyy, -30, a_c.f_v_date) THEN 1 ELSE NULL END) AS c2,
           COUNT(CASE WHEN p_p.sex_id = 0 AND p_p.birth_day>DateAdd(yyyy, -30, a_c.f_v_date) THEN 1 ELSE NULL END) AS c3,
           --
           COUNT(CASE WHEN p_p.sex_id = 1
                      AND p_p.birth_day BETWEEN DateAdd(yyyy, -39, a_c.f_v_date) AND DateAdd(yyyy, -30, a_c.f_v_date) THEN 1 ELSE NULL END) AS c4,
           COUNT(CASE WHEN p_p.sex_id = 0
                      AND p_p.birth_day BETWEEN DateAdd(yyyy, -39, a_c.f_v_date) AND DateAdd(yyyy, -30, a_c.f_v_date) THEN 1 ELSE NULL END) AS c5,
           --
           COUNT(CASE WHEN p_p.sex_id = 1 AND p_p.birth_day<DateAdd(yyyy, -39, a_c.f_v_date) THEN 1 ELSE NULL END) AS c6,
           COUNT(CASE WHEN p_p.sex_id = 0 AND p_p.birth_day < DateAdd(yyyy, -39, a_c.f_v_date) THEN 1 ELSE NULL END) AS c7,

           -- calc_cholesterol
           --до 30 лет
           COUNT(CASE WHEN p_p.sex_id = 1 AND a_p_r.level_cholesterol IS NOT NULL
                      AND p_p.birth_day>DateAdd(yyyy, -30, a_c.f_v_date) THEN 1 ELSE NULL END) AS c8,
           COUNT(CASE WHEN p_p.sex_id = 0 AND a_p_r.level_cholesterol IS NOT NULL
                      AND p_p.birth_day>DateAdd(yyyy, -30, a_c.f_v_date) THEN 1 ELSE NULL END) AS c9,
           --30-40 лет
           COUNT(CASE WHEN p_p.sex_id = 1 AND a_p_r.level_cholesterol IS NOT NULL
                      AND p_p.birth_day BETWEEN DateAdd(yyyy, -39, a_c.f_v_date) AND DateAdd(yyyy, -30, a_c.f_v_date) THEN 1 ELSE NULL END) AS c10,
           COUNT(CASE WHEN p_p.sex_id = 0 AND a_p_r.level_cholesterol IS NOT NULL
                      AND p_p.birth_day BETWEEN DateAdd(yyyy, -39, a_c.f_v_date) AND DateAdd(yyyy, -30, a_c.f_v_date) THEN 1 ELSE NULL END) AS c11,
           --40 и старше
           COUNT(CASE WHEN p_p.sex_id = 1 AND a_p_r.level_cholesterol IS NOT NULL
                      AND p_p.birth_day<DateAdd(yyyy, -39, a_c.f_v_date) THEN 1 ELSE NULL END) AS c12,
           COUNT(CASE WHEN p_p.sex_id = 0 AND a_p_r.level_cholesterol IS NOT NULL
                      AND p_p.birth_day<DateAdd(yyyy, -39, a_c.f_v_date) THEN 1 ELSE NULL END) AS c13,
           -- calc_glucose
           --до 30 лет
           COUNT(CASE WHEN p_p.sex_id = 1 AND a_p_r.level_glucose IS NOT NULL
               AND p_p.birth_day>DateAdd(yyyy, -30, a_c.f_v_date) THEN 1 ELSE NULL END) AS c14,
           COUNT(CASE WHEN p_p.sex_id = 0 AND a_p_r.level_glucose IS NOT NULL
               AND p_p.birth_day>DateAdd(yyyy, -30, a_c.f_v_date) THEN 1 ELSE NULL END) AS c15,
           --30-40 лет
           COUNT(CASE WHEN p_p.sex_id = 1 AND a_p_r.level_glucose IS NOT NULL
               AND p_p.birth_day BETWEEN DateAdd(yyyy, -39, a_c.f_v_date) AND DateAdd(yyyy, -30, a_c.f_v_date) THEN 1 ELSE NULL END) AS c16,
           COUNT(CASE WHEN p_p.sex_id = 0 AND a_p_r.level_glucose IS NOT NULL
               AND p_p.birth_day BETWEEN DateAdd(yyyy, -39, a_c.f_v_date) AND DateAdd(yyyy, -30, a_c.f_v_date) THEN 1 ELSE NULL END) AS c17,
           --40 и старше
           COUNT(CASE WHEN p_p.sex_id = 1 AND a_p_r.level_glucose IS NOT NULL
               AND p_p.birth_day<DateAdd(yyyy, -39, a_c.f_v_date) THEN 1 ELSE NULL END) AS c18,
           COUNT(CASE WHEN p_p.sex_id = 0 AND a_p_r.level_glucose IS NOT NULL
               AND p_p.birth_day<DateAdd(yyyy, -39, a_c.f_v_date) THEN 1 ELSE NULL END) AS c19
        FROM A_case AS a_c
        LEFT JOIN A_pressure_reference AS a_p_r ON a_c.id = a_p_r.case_id
        INNER JOIN p_person AS p_p ON a_c.patient_id = p_p.id
        INNER JOIN glb_lpu AS lpu ON '+ @select_lpu +'
        WHERE a_c.f_v_date BETWEEN @sdate AND @edate AND ('+@where_lpu+')
    )
    SELECT c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,
           cast((c8*100.0/NULLIF(c2,0)) AS decimal(5,2)) AS c8_percent,
           cast((c9*100.0/NULLIF(c3,0)) AS decimal(5,2)) AS c9_percent,
           cast((c10*100.0/NULLIF(c4,0)) as decimal(5,2)) AS c10_percent,
           cast((c11*100.0/NULLIF(c5,0)) AS decimal(5,2)) AS c11_percent,
           cast((c12*100.0/NULLIF(c6,0)) AS decimal(5,2)) AS c12_percent,
           cast((c13*100.0/NULLIF(c7,0)) AS decimal(5,2)) AS c13_percent,
           cast((c14*100.0/NULLIF(c2,0)) AS decimal(5,2)) AS c14_percent,
           cast((c15*100.0/NULLIF(c3,0)) AS decimal(5,2)) AS c15_percent,
           cast((c16*100.0/NULLIF(c4,0)) AS decimal(5,2)) AS c16_percent,
           cast((c17*100.0/NULLIF(c5,0)) AS decimal(5,2)) AS c17_percent,
           cast((c18*100.0/NULLIF(c6,0)) AS decimal(5,2)) AS c18_percent,
           cast((c19*100.0/NULLIF(c7,0)) AS decimal(5,2)) AS c19_percent
    FROM calc_result
    '

    EXECUTE sp_executesql @result_rpt_29, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id

END;