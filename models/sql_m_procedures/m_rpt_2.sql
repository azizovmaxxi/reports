-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-07-06';
-- execute m_rpt_1 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'm_rpt_1', 'P' ) IS NOT NULL DROP PROCEDURE m_rpt_1;

GO
CREATE PROCEDURE m_rpt_1 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
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

    DECLARE @result_m_rpt_1 NVARCHAR(MAX) = '
        SELECT
               COUNT(*) AS c1
             , COUNT(CASE WHEN birth_day BETWEEN DateAdd(yyyy, -49, @edate) AND DateAdd(yyyy,-15,@edate) AND sex_id=0 THEN 1 ELSE NULL END) AS c2
             , COUNT(CASE WHEN birth_day > DateAdd(y,-29, DateAdd(m,-11, DateAdd(yyyy, -14, @edate))) THEN 1 ELSE NULL END) AS c3
             , COUNT(CASE WHEN birth_day BETWEEN DateAdd(yyyy, -1, @edate) AND DateAdd(yyyy,0,@edate) THEN 1 ELSE NULL END) AS c4
        FROM P_person AS p_p
        JOIN P_PersonAssignment AS p_pa ON p_p.id = p_pa.person_id
        JOIN glb_lpu AS lpu ON p_pa.gsv_id = lpu.id
        WHERE p_pa.end_date IS NULL AND rec_status != 3 AND ('+@where_lpu+')
        '

    EXECUTE sp_executesql @result_m_rpt_1, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id
END