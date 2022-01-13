-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-07-06';
-- execute m_rpt_9 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'm_rpt_9', 'P' ) IS NOT NULL DROP PROCEDURE m_rpt_9;

GO
CREATE PROCEDURE m_rpt_9 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
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

    DECLARE @result_m_rpt_9 NVARCHAR(MAX) = '
       WITH case_with_procedures(case_id, proctyp_code, code2, full_name, home_visit, id_by_num)
       AS (
            SELECT M_case.id AS case_id, Mp.proctyp_code, gmpt.code2, gmpt.full_name, Mv.case_id AS home_visit
                 , ROW_NUMBER() OVER(PARTITION BY Mp.case_id ORDER BY gmpt.code2 DESC) AS id_by_num
            FROM M_case
             INNER JOIN glb_lpu lpu ON M_case.lpu_id = lpu.id
             INNER JOIN M_procedure Mp ON M_case.id = Mp.case_id
             INNER JOIN glb_M_proc_type gmpt ON Mp.proctyp_code = gmpt.code AND procctg_id = 24
             LEFT JOIN M_visit Mv ON M_case.id = Mv.case_id AND vistyp_code IN (22, 23)
            WHERE M_case.f_v_date BETWEEN @sdate AND @edate
              AND ('+ @where_lpu +')
        ),
        result_cases(all_cases, at_home, depend)
        AS (
            SELECT
                COUNT(CASE WHEN id_by_num=1 THEN 1 ELSE NULL END ) AS all_cases
               ,COUNT(CASE WHEN id_by_num=1 AND home_visit IS NOT NULL THEN 1 ELSE NULL END ) AS at_home
               , ''result_cases'' AS depend
            FROM case_with_procedures
        ),
        list_procedures(c1, c2, c3, c4, depend)
        AS (
            SELECT gMpt.code2 AS c1, gMpt.code AS c2, gMpt.full_name AS c3
                 , COUNT(cwp.case_id) AS c4, ''list_procedures'' AS depend
            FROM glb_M_proc_type gMpt
            LEFT JOIN case_with_procedures cwp ON gMpt.code = cwp.proctyp_code
            WHERE procctg_id=24
            GROUP BY gMpt.code2, gMpt.code, gMpt.full_name
        )
       SELECT
            COALESCE(( SELECT * FROM result_cases FOR XML PATH(''result_cases'')), '''') AS result_cases,
            COALESCE(( SELECT * FROM list_procedures ORDER BY c1 FOR XML PATH(''list_procedures'')), '''') AS list_procedures
    '

    EXECUTE sp_executesql @result_m_rpt_9, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id
END