-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-07-06';
-- execute m_rpt_6 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'm_rpt_8', 'P' ) IS NOT NULL DROP PROCEDURE m_rpt_8;

GO
CREATE PROCEDURE m_rpt_8 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
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

    DECLARE @result_m_rpt_8 NVARCHAR(MAX) = '
       SELECT COUNT(CASE WHEN cough = 1 THEN 1 ELSE NULL END) AS c1
             , COUNT(CASE WHEN sputum_coll = 1 THEN 1 ELSE NULL END) AS c2
        FROM (
            SELECT MAX(CONVERT(tinyint, cough)) AS cough
                 , MAX(CONVERT(tinyint, sputum_coll)) AS sputum_coll
            FROM M_case
            INNER JOIN glb_lpu lpu ON M_case.lpu_id = lpu.id
            WHERE (cough=1 OR sputum_coll=1)
                AND f_v_date BETWEEN @sdate AND @edate
                AND ('+ @where_lpu +')
            GROUP BY patient_id
        ) AS result_tuberkulez
    '

    EXECUTE sp_executesql @result_m_rpt_8, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id
END