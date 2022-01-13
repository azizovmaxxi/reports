-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 68241--61411;
-- declare @lpu_parent_id integer = null;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-07-06';
--
-- execute rpt_31 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_31', 'P' ) IS NOT NULL DROP PROCEDURE rpt_31;

GO
CREATE PROCEDURE rpt_31 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
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

    DECLARE @result_rpt_31 NVARCHAR(MAX) = '
     WITH calc_result(c1,c2,c3,c4,c5,c6,c7)
        AS (
            SELECT COUNT(*) AS c1,
                   COUNT(CASE WHEN birth_day<DateAdd(yyyy, -18, f_v_date) AND a_p_r.cervix_change = 1 THEN 1 ELSE NULL END) c2,
                   COUNT(CASE WHEN birth_day BETWEEN DateAdd(yyyy, -21, f_v_date) AND DateAdd (yyyy, -18, f_v_date)
                              AND a_p_r.cervix_change = 1  THEN 1 ELSE NULL END) c3,
                   COUNT(CASE WHEN birth_day BETWEEN DateAdd(yyyy, -31, f_v_date) AND DateAdd (yyyy, -21, f_v_date)
                              AND a_p_r.cervix_change = 1 THEN 1 ELSE NULL END) c4,
                   COUNT(CASE WHEN birth_day BETWEEN DateAdd(yyyy, -41, f_v_date) AND DateAdd (yyyy, -31, f_v_date)
                              AND a_p_r.cervix_change = 1 THEN 1 ELSE NULL END) c5,
                   COUNT(CASE WHEN birth_day BETWEEN DateAdd(yyyy, -50, f_v_date) AND DateAdd (yyyy, -41, f_v_date)
                              AND a_p_r.cervix_change = 1 THEN 1 ELSE NULL END) c6,
                   COUNT(CASE WHEN birth_day<DateAdd(yyyy, -50, f_v_date) AND a_p_r.cervix_change = 1 THEN 1 ELSE NULL END) c7
            FROM A_case AS a_c
            LEFT JOIN A_pressure_reference AS a_p_r ON a_c.id = a_p_r.case_id
            INNER JOIN p_person AS p_p ON a_c.patient_id = p_p.id
            INNER JOIN glb_lpu AS lpu ON '+ @select_lpu +'
            WHERE p_p.sex_id = 0 AND a_c.f_v_date BETWEEN @sdate AND @edate AND ('+@where_lpu+')
        )
        SELECT c1,c2,c3,c4,c5,c6,c7,
               cast((c2*100.0/NULLIF(c1,0)) AS decimal(5,2)) AS c2_percent,
               cast((c3*100.0/NULLIF(c1,0)) AS decimal(5,2)) AS c3_percent,
               cast((c4*100.0/NULLIF(c1,0)) as decimal(5,2)) AS c4_percent,
               cast((c5*100.0/NULLIF(c1,0)) AS decimal(5,2)) AS c5_percent,
               cast((c6*100.0/NULLIF(c1,0)) AS decimal(5,2)) AS c6_percent,
               cast((c7*100.0/NULLIF(c1,0)) AS decimal(5,2)) AS c7_percent
        FROM calc_result
    '

    EXECUTE sp_executesql @result_rpt_31, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id

END