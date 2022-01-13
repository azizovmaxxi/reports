-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-07-06';
--execute m_rpt_4 @sdate, @edate, @lpu_id, @lpu_parent_id

GO
IF OBJECT_ID ( 'm_rpt_4', 'P' ) IS NOT NULL DROP PROCEDURE m_rpt_4;

GO
CREATE PROCEDURE m_rpt_4 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
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

    DECLARE @result_m_rpt_4 NVARCHAR(MAX) = '
        SELECT
            COUNT(CASE WHEN visit_date BETWEEN @sdate AND @edate THEN 1 ELSE NULL END) AS c1,
            SUM(CASE WHEN filter_cases = 1 THEN calc ELSE 0 END) AS c2,
            COUNT(CASE WHEN vistyp_code IN (22,23) THEN 1 ELSE NULL END) AS c3,
            COUNT(CASE WHEN filter_cases = 1 THEN 1 ELSE NULL END) AS c4
        FROM (
             SELECT mv.case_id, mv.visit_date, mv.vistyp_code, COALESCE(count_diagnosis.calc, 0) AS calc
                  , ROW_NUMBER() OVER(PARTITION BY Mv.case_id ORDER BY Mv.visit_date) AS filter_cases
             FROM M_case
             INNER JOIN M_visit AS Mv ON M_case.id = Mv.case_id
             INNER JOIN glb_lpu AS lpu ON M_case.lpu_id = lpu.id
             LEFT JOIN (
                SELECT case_id, count(icd10) AS calc FROM M_diagnosis WHERE icd10 BETWEEN ''A00'' AND ''T989'' GROUP BY case_id
             ) AS count_diagnosis ON M_case.id = count_diagnosis.case_id
             WHERE mv.vistyp_code <> 28
                   AND M_case.f_v_date BETWEEN @sdate AND @edate
                   AND ('+@where_lpu+')
        ) AS cv
    '

    EXECUTE sp_executesql @result_m_rpt_4, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id
END