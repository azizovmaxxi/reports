-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-07-06';
-- execute m_rpt_3 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'm_rpt_3', 'P' ) IS NOT NULL DROP PROCEDURE m_rpt_3;

GO
CREATE PROCEDURE m_rpt_3 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
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

    DECLARE @result_m_rpt_3 NVARCHAR(MAX) = '
        SELECT
            COUNT(CASE WHEN k_ad = 1 THEN 1 ELSE NULL END) AS t2_c1,
            COUNT(CASE WHEN anti_drugs = 1 THEN 1 ELSE NULL END) AS t2_c2,
            COUNT(CASE WHEN percen = 1 THEN 1 ELSE NULL END) AS t2_c3,
            COUNT(CASE WHEN percen = 2 THEN 1 ELSE NULL END) AS t2_c4,
            COUNT(CASE WHEN percen = 3 THEN 1 ELSE NULL END) AS t2_c5,
            COUNT(CASE WHEN percen = 4 THEN 1 ELSE NULL END) AS t2_c6,
            COUNT(CASE WHEN percen = 5 THEN 1 ELSE NULL END) AS t2_c7,
            COUNT(CASE WHEN recommendation = 1 THEN 1 ELSE NULL END) AS t2_c8,
            COUNT(CASE WHEN recommendation = 0 THEN 1 ELSE NULL END) AS t2_c9,
            -- table_3
            COUNT(CASE WHEN smoking = 1 THEN 1 ELSE NULL END) AS t3_c1,
            COUNT(CASE WHEN smoking = 0 THEN 1 ELSE NULL END) AS t3_c2,
            COUNT(CASE WHEN no_smoking = 1 THEN 1 ELSE NULL END) AS t3_c3,
            COUNT(CASE WHEN no_smoking_6month = 1 THEN 1 ELSE NULL END) AS t3_c4,
            COUNT(CASE WHEN no_smoking_6month = 0 THEN 1 ELSE NULL END) AS t3_c5,
            COUNT(CASE WHEN nicotine = 1 THEN 1 ELSE NULL END) AS t3_c6,
            COUNT(CASE WHEN nicotine = 0 THEN 1 ELSE NULL END) AS t3_c7,
            COUNT(CASE WHEN alcohol = 1 THEN 1 ELSE NULL END) AS t3_c8,
            COUNT(CASE WHEN alcohol = 0 THEN 1 ELSE NULL END) AS t3_c9,
            COUNT(CASE WHEN salt = 1 THEN 1 ELSE NULL END) AS t3_c10,
            COUNT(CASE WHEN salt = 0 THEN 1 ELSE NULL END) AS t3_c11,
            -- table_4
            COUNT(CASE WHEN physical_activ = 1 THEN 1 ELSE NULL END) AS t4_c1,
            COUNT(CASE WHEN physical_activ = 0 THEN 1 ELSE NULL END) AS t4_c2,
            COUNT(CASE WHEN fruits = 1 THEN 1 ELSE NULL END) AS t4_c3,
            COUNT(CASE WHEN fruits = 0 THEN 1 ELSE NULL END) AS t4_c4,
            COUNT(CASE WHEN deast = 1 THEN 1 ELSE NULL END) AS t4_c5,
            COUNT(CASE WHEN deast = 0 THEN 1 ELSE NULL END) AS t4_c6,
            COUNT(CASE WHEN identi_changes = 1 THEN 1 ELSE NULL END) AS t4_c7,
            COUNT(CASE WHEN identi_changes = 0 THEN 1 ELSE NULL END) AS t4_c8
        FROM (
            SELECT M_case.*
                 , Mr.percen, Mr.cad, mr.dad
                 , ROW_NUMBER() OVER(PARTITION BY patient_id ORDER BY f_v_date DESC, date_ins DESC) AS filter_by_num
            FROM M_case
            INNER JOIN glb_lpu AS lpu ON M_case.lpu_id = lpu.id
            INNER JOIN p_person ON M_case.patient_id = p_person.id
            LEFT JOIN M_risk AS Mr on M_case.id = Mr.case_id
            WHERE p_person.birth_day < DateAdd(yyyy, -18, m_case.f_v_date)
                AND f_v_date BETWEEN @sdate AND @edate AND ('+@where_lpu+')
        ) AS result_case
        WHERE filter_by_num = 1
    '

    EXECUTE sp_executesql @result_m_rpt_3, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id
END