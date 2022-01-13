-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-07-06';
-- execute m_rpt_6 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'm_rpt_6', 'P' ) IS NOT NULL DROP PROCEDURE m_rpt_6;

GO
CREATE PROCEDURE m_rpt_6 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
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

    DECLARE @result_m_rpt_6 NVARCHAR(MAX) = '
        SELECT COUNT(patient_id) AS r1_0
            , COUNT(CASE WHEN after_abortion = 1 THEN 1 ELSE NULL END) AS r2_1
            , COUNT(CASE WHEN contr_consulting = 1 THEN 1 ELSE NULL END) AS r2_2
        FROM (
             SELECT patient_id
                  , MAX(CONVERT(tinyint, after_abortion)) AS after_abortion
                  , MAX(CONVERT(tinyint, contr_consulting)) AS contr_consulting
             FROM M_case
             INNER JOIN p_person pp ON M_case.patient_id = pp.id
             INNER JOIN glb_lpu lpu ON M_case.lpu_id = lpu.id
             WHERE pp.sex_id = 0
               AND (pp.birth_day BETWEEN DateAdd(yyyy, -49, f_v_date) AND DateAdd(yyyy,-15, f_v_date))
               AND (M_case.contraception = 1 OR M_case.after_abortion = 1)
               AND M_case.f_v_date BETWEEN @sdate AND @edate
               AND ('+ @where_lpu +')
             GROUP BY patient_id
        ) AS result_contraception
    '

    EXECUTE sp_executesql @result_m_rpt_6, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id
END