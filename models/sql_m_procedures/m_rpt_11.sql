-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-07-06';
-- execute m_rpt_11 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'm_rpt_11', 'P' ) IS NOT NULL DROP PROCEDURE m_rpt_11;

GO
CREATE PROCEDURE m_rpt_11 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
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

    DECLARE @result_m_rpt_11 NVARCHAR(MAX) = '
       SELECT count(*) c1
       FROM M_case
       INNER JOIN glb_lpu lpu ON lpu.id = M_case.lpu_id
       WHERE repeat_visit = 1
          AND f_v_date BETWEEN @sdate AND @edate
          AND ('+ @where_lpu +')
    '

    EXECUTE sp_executesql @result_m_rpt_11, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id
END