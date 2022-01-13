declare @lpu_id integer = 61411;
declare @lpu_parent_id integer = 68241;
declare @sdate date = '2020-01-01';
declare @edate date = '2020-07-06';

execute rpt_22 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_22', 'P' ) IS NOT NULL DROP PROCEDURE rpt_22;

GO
CREATE PROCEDURE rpt_22 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
AS
BEGIN

    DECLARE @select_lpu VARCHAR(50) = 'lpu.id = a_c.patient_lpu';

    DECLARE @where_lpu VARCHAR(100) = '';
    IF @lpu_parent_id IS NULL
        set @where_lpu = 'lpu.id = @lpu_id OR lpu.parent_id = @lpu_id';
    ELSE

        IF @lpu_id > 0 AND @lpu_parent_id IS NOT NULL
            set @where_lpu = 'lpu.id = @lpu_id';

    IF @lpu_id = -1
        set @where_lpu = 'lpu.parent_id = @lpu_parent_id';
    IF @lpu_id = -2
        BEGIN
            set @where_lpu = 'lpu.id = @lpu_parent_id';
            set @select_lpu = 'lpu.id = a_c.lpu_id';
        END

    DECLARE @result_rpt_22 NVARCHAR(MAX) = '
    WITH rows(num, sex)
             AS (
            SELECT num, sex from (VALUES(1, ''Всего''),(2, ''Мужчины''),(3, ''Женщины''))nums(num, sex)
        ),
         gb_rows(num, c1, c2, c3, c4)
             AS (
             SELECT
                 CASE WHEN sex_id IS NULL THEN 1 WHEN sex_id = 0 THEN 3 ELSE 2 END AS num
                  ,COUNT(CASE WHEN is_f_life = 1 THEN 1 ELSE NULL END) AS c1
                  ,COUNT(CASE WHEN is_f_life = 0 AND num_is_f_life>1 THEN 1 ELSE NULL END) AS c2
                  ,COUNT(CASE WHEN is_f_life = 1 AND birth_day<DateAdd(yyyy, -40, f_v_date) THEN 1 ELSE NULL END) AS c3
                  ,COUNT(CASE WHEN is_f_life = 0 AND num_is_f_life>1 AND with_is_f_life = 1 AND birth_day<DateAdd(yyyy, -40, f_v_date) THEN 1 ELSE NULL END) AS c4
             FROM (
                      SELECT a_c.id AS case_id, a_c.f_v_date, a_c.patient_id, p_p.birth_day, p_p.sex_id,
                             cast(a_d.is_f_life AS tinyint) is_f_life,
                             count(*) OVER(PARTITION BY patient_id ORDER BY a_c.patient_id, case_id) AS num_is_f_life,
                             max(cast(a_d.is_f_life AS tinyint) ) OVER
                                 (PARTITION BY patient_id ORDER BY a_c.patient_id, case_id
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS with_is_f_life
                      FROM a_case AS a_c
                      INNER JOIN a_diagnosis AS a_d ON a_c.id=a_d.case_id
                      INNER JOIN p_person AS p_p ON a_c.patient_id=p_p.id
                      INNER JOIN glb_lpu AS lpu ON '+@select_lpu+'
                      WHERE a_d.basic=1
                        AND a_d.is_final=1
                        AND a_d.icd10 BETWEEN ''I10'' AND ''I139''
                        AND a_c.f_v_date BETWEEN @sdate AND @edate
                        AND ('+ @where_lpu +')
                  ) AS sub
             WHERE with_is_f_life = 1
             GROUP BY sex_id WITH ROLLUP
         )
    SELECT rows.sex, rows.num,
           COALESCE(gb_rows.c1, 0) AS c1, COALESCE(gb_rows.c2, 0) AS c2,
           COALESCE(gb_rows.c3, 0) AS c3, COALESCE(gb_rows.c4, 0) AS c4
    FROM rows
    LEFT JOIN gb_rows ON rows.num = gb_rows.num
    ORDER BY rows.num
    '

    EXECUTE sp_executesql @result_rpt_22, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id

END