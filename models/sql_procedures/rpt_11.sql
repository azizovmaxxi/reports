-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 68241;
-- declare @lpu_parent_id integer = null;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-12-31';
--
-- execute rpt_11 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_11', 'P' ) IS NOT NULL DROP PROCEDURE rpt_11;

GO
CREATE PROCEDURE rpt_11 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT,
        @icd10_start VARCHAR(10) = NULL, @icd10_end VARCHAR(10) = NULL
AS
BEGIN
    DECLARE @where VARCHAR(100) = ' a_d.icd10 BETWEEN ''A00'' AND ''T989'' ';
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

    IF @icd10_start IS NOT NULL AND @icd10_end IS NOT NULL
        set @where = ' a_d.icd10 BETWEEN @icd10_start AND @icd10_end'

    DECLARE @result_rpt_11 NVARCHAR(MAX) = '
    WITH rows(num, sex)
    AS ( SELECT num, sex from (VALUES(1, ''Всего''),(2, ''Мужчины''),(3, ''Женщины''))nums(num, sex)),
    result_rows(num, c1, c2, c3, c4, c5, c6, c7, c8)
        AS (
             SELECT CASE WHEN sex_id IS NULL THEN 1 WHEN sex_id = 1 THEN 2 ELSE 3 END AS num,
                    count(patient_id) c1,
                    count(CASE WHEN birth_day>DateAdd(yyyy, -15, f_v_date) THEN 1 ELSE NULL END) c2,
                    count(CASE WHEN birth_day BETWEEN DateAdd(yyyy, -18, f_v_date) AND DateAdd (yyyy, -15, f_v_date) THEN 1 ELSE NULL END) c3,
                    count(CASE WHEN birth_day BETWEEN DateAdd(yyyy, -21, f_v_date) AND DateAdd (yyyy, -18, f_v_date) THEN 1 ELSE NULL END) c4,
                    count(CASE WHEN birth_day BETWEEN DateAdd(yyyy, -31, f_v_date) AND DateAdd (yyyy, -21, f_v_date) THEN 1 ELSE NULL END) c5,
                    count(CASE WHEN birth_day BETWEEN DateAdd(yyyy, -41, f_v_date) AND DateAdd (yyyy, -31, f_v_date) THEN 1 ELSE NULL END) c6,
                    count(CASE WHEN birth_day BETWEEN DateAdd(yyyy, -50, f_v_date) AND DateAdd (yyyy, -41, f_v_date) THEN 1 ELSE NULL END) c7,
                    count(CASE WHEN birth_day<DateAdd(yyyy, -50, f_v_date) THEN 1 ELSE NULL END) c8
             FROM (
                  SELECT max(a_c.f_v_date) AS f_v_date, p_p.id AS patient_id, p_p.birth_day, p_p.sex_id
                  FROM a_case AS a_c
                   INNER JOIN a_diagnosis AS a_d ON a_c.id=a_d.case_id
                   INNER JOIN p_person AS p_p ON a_c.patient_id=p_p.id
                   INNER JOIN glb_lpu AS lpu ON '+@select_lpu+'
                  WHERE a_c.smoking=1
                    AND a_d.basic=1
                    AND a_c.f_v_date BETWEEN @sdate AND @edate
                    AND '+@where+'
                    AND ('+@where_lpu+')
                  GROUP BY p_p.id, p_p.birth_day, p_p.sex_id
             ) AS calc_result
             GROUP BY sex_id WITH ROLLUP
        )
    SELECT rows.num, rows.sex,
        COALESCE(r_r.c1, 0) AS c1, COALESCE(r_r.c2, 0) AS c2, COALESCE(r_r.c3, 0) AS c3,
        COALESCE(r_r.c4, 0) AS c4, COALESCE(r_r.c5, 0) AS c5, COALESCE(r_r.c6, 0) AS c6,
        COALESCE(r_r.c7, 0) AS c7, COALESCE(r_r.c8, 0) AS c8
    FROM rows
    LEFT JOIN result_rows AS r_r ON rows.num = r_r.num
    ORDER BY num;
    '

    EXECUTE sp_executesql @result_rpt_11, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT,
        @icd10_start VARCHAR(10), @icd10_end VARCHAR(10)',
            @sdate, @edate, @lpu_id, @lpu_parent_id, @icd10_start, @icd10_end
END