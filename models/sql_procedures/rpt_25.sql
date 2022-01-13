-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 68241;
-- declare @lpu_parent_id integer = null;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-12-31';
--
-- execute rpt_25 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_25', 'P' ) IS NOT NULL DROP PROCEDURE rpt_25;

GO
CREATE PROCEDURE rpt_25 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT, @visit_num INT = NULL
AS
BEGIN
    DECLARE @where VARCHAR(100) = '';
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
    IF @visit_num IS NOT NULL
        set @where = ' AND a_p.visit_num = @visit_num '


    DECLARE @result_rpt_25 NVARCHAR(MAX) = '
    WITH rows(num, sex)
    AS ( SELECT num, sex from (VALUES(1, ''Всего''),(2, ''Мужчины''),(3, ''Женщины''))nums(num, sex)),
    result_rows(num, c1, c2)
    AS (
        SELECT CASE WHEN sex_id IS NULL THEN 1 WHEN sex_id = 1 THEN 2 ELSE 3 END AS num,
               count(CASE WHEN pressure>=140 THEN 1 ELSE NULL END) c1,
               count(CASE WHEN pressure<140 THEN 1 ELSE NULL END) c2
        FROM (
            SELECT a_c.id AS case_id, p_p.sex_id,
                   convert(int, cast(a_p.pressure_max AS varchar(24))) AS pressure
            FROM a_case AS a_c
             INNER JOIN a_diagnosis AS a_d ON a_c.id=a_d.case_id
             INNER JOIN p_person AS p_p ON a_c.patient_id=p_p.id
             INNER JOIN a_pressure AS a_p ON a_c.id=a_p.case_id
             INNER JOIN glb_lpu AS lpu ON '+@select_lpu+'
            WHERE a_d.is_final=1
              AND a_d.icd10 BETWEEN ''I10'' AND ''I139''
              AND a_c.f_v_date BETWEEN @sdate AND @edate
              AND '+@where_lpu+' '+@where+'
            GROUP BY a_c.id, sex_id, visit_num, a_p.pressure_max
        ) AS calc_query
        GROUP BY sex_id WITH ROLLUP
    )
    SELECT rows.num, rows.sex, COALESCE(r_r.c1, 0) AS c1, COALESCE(r_r.c2, 0) AS c2
    FROM rows
    LEFT JOIN result_rows AS r_r ON rows.num = r_r.num
    ORDER BY num;
    '

    EXECUTE sp_executesql @result_rpt_25, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT, @visit_num INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id, @visit_num
END