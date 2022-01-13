-- declare @lpu_id integer = -2;
-- declare @lpu_parent_id integer = 68241;
declare @lpu_id integer = 15841---2;
declare @lpu_parent_id integer = null;
declare @sdate date = '2018-01-01';
declare @edate date = '2018-12-31';

execute rpt_3 @sdate, @edate, @lpu_id, @lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_3', 'P' ) IS NOT NULL DROP PROCEDURE rpt_3;

GO
CREATE PROCEDURE rpt_3 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT, @doctor_id VARCHAR(50) = NULL,
                       @type_rpt VARCHAR(50) = NULL, @trimestr INT = null, @calc_by VARCHAR(50) = NULL
AS
BEGIN
    DECLARE @pregnancy_date date = DATEADD(month, -9, @sdate);
    DECLARE @where_lpu VARCHAR(100) = '';
    DECLARE @where VARCHAR(300) = '';
    DECLARE @trim VARCHAR(50) = '';
    DECLARE @select_table VARCHAR(50) = ' born_second_case';
    DECLARE @calc_by_result VARCHAR(50) = ' result_rows ';

    IF @lpu_parent_id IS NULL
        set @where_lpu = 'lpu.id = @lpu_id OR lpu.parent_id = @lpu_id'

    IF @lpu_id > 0 AND @lpu_parent_id IS NOT NULL
        set @where_lpu = 'lpu.id = @lpu_id';

    IF @lpu_id = -1
        set @where_lpu = 'lpu.parent_id = @lpu_parent_id';
    IF @lpu_id = -2
        set @where_lpu = ' lpu.id = @lpu_parent_id ';

    IF @doctor_id IS NOT NULL
        set @where = CONCAT(@where, ' AND a_c.doctor_id = @doctor_id')
    IF @type_rpt = 'gynecological'
        set @where = CONCAT(@where, ' AND a_c.post_code = 1')
    IF @trimestr IS NOT NULL
        BEGIN
            set @trim = ' AND pregnancy = @trimestr '
            set @select_table = ' born_first_case '
        END
    IF @calc_by = 'patients'
        set @calc_by_result = ' (SELECT patient_id, num FROM result_rows GROUP BY patient_id, num) '


    DECLARE @result_rpt_3 NVARCHAR(MAX) = '
    WITH born_first_case(case_id, patient_id, icd10)
         AS (
            SELECT max(a_c.id) AS case_id, a_c.patient_id, a_d.icd10
            FROM a_case AS a_c
            INNER JOIN a_diagnosis AS a_d ON a_c.id = a_d.case_id
            INNER JOIN glb_lpu AS lpu ON a_c.lpu_id = lpu.id
            INNER JOIN A_visit AS a_v ON a_c.id = a_v.case_id
            WHERE a_c.f_v_date BETWEEN @sdate AND @edate
              AND (a_d.icd10 in (''Z321'')
                OR a_d.icd10 LIKE ''Z33%''
                OR a_d.icd10 LIKE ''Z34%''
                OR a_d.icd10 LIKE ''Z35%''
                OR a_d.icd10 LIKE ''Z36%''
                OR a_d.icd10 LIKE ''O%'')
                AND ('+ @where_lpu +') '+ CONCAT(@where, @trim)+'
            GROUP BY a_c.patient_id, a_d.icd10
        ),
        born_second_case(case_id, patient_id, icd10)
        AS (
            SELECT max(a_c.id) AS case_id, a_c.patient_id, a_d.icd10
            FROM a_case AS a_c
            INNER JOIN a_diagnosis AS a_d ON a_c.id=a_d.case_id
            INNER JOIN glb_lpu AS lpu on a_c.lpu_id = lpu.id
            WHERE (a_c.f_v_date>=@pregnancy_date AND a_c.f_v_date<=@edate)
              AND a_c.patient_id IN (SELECT sub_a_c.patient_id
                                     FROM a_case AS sub_a_c
                                     INNER JOIN a_diagnosis b ON sub_a_c.id=b.case_id
                                     INNER JOIN glb_lpu AS lpu on a_c.lpu_id = lpu.id
                                     WHERE (b.icd10 LIKE ''Z39%'' OR b.icd10=''O60'')
                                       AND sub_a_c.f_v_date BETWEEN @sdate AND @edate
                                       AND ('+ @where_lpu +')
                  )
              AND (a_d.icd10 in (''O60'', ''O364'', ''O120'', ''O121'',''O122'', ''O994'', ''O995'', ''O23'',''O230'',''O231'',''O232'',
                                ''O233'',''O234'', ''O230'', ''O996'', ''O990'', ''O980'', ''H521'', ''J06'',''J068'',''J069'', ''A560'',
                                ''A561'',''A562'', ''A493'', ''A638'',''B373'',''A590'',''B258'',''O264'',''O235'')
                   OR (a_d.icd10 LIKE ''Z39%'' OR a_d.icd10 like ''O60%'' OR a_d.icd10 like ''O10%'' OR a_d.icd10 like ''O11%''
                       OR a_d.icd10 like ''O13%'' OR a_d.icd10 like ''O14%'' OR a_d.icd10 like ''O15%'' OR a_d.icd10 like ''O22%''
                       OR a_d.icd10 like ''E66%'' OR a_d.icd10 like ''E01%'' OR a_d.icd10 like ''O24%'')
                  )
                  AND ('+ @where_lpu +') '+ @where +'
            GROUP BY patient_id, icd10
        ),
        build_rows(icd10, patient_id, num)
        AS(
            SELECT icd10, patient_id, 1 AS num
            FROM born_first_case
            UNION ALL
            SELECT icd10, patient_id,
            CASE WHEN bsc.icd10 IN (''O60'') OR bsc.icd10 like ''Z39%'' THEN 2
                 WHEN bsc.icd10 LIKE ''O60%'' THEN 3
                 WHEN bsc.icd10 IN (''O364'') THEN 4
                 WHEN bsc.icd10 LIKE ''O10%'' OR bsc.icd10 LIKE ''O11%'' THEN 6
                 WHEN bsc.icd10 IN (''O120'') THEN 7
                 WHEN bsc.icd10 IN (''O121'',''O122'') THEN 8
                 WHEN bsc.icd10 LIKE ''O13%'' THEN 10
                 WHEN bsc.icd10 LIKE ''O14%'' THEN 11
                 WHEN bsc.icd10 LIKE ''O15%'' THEN 12
                 WHEN bsc.icd10 IN (''O994'') THEN 14
                 WHEN bsc.icd10 IN (''O23'',''O230'',''O231'',''O232'',''O233'',''O234'') THEN 16
                 WHEN bsc.icd10 IN (''O230'') THEN 17
                 WHEN bsc.icd10 IN (''O996'') THEN 18
                 WHEN bsc.icd10 IN (''O990'') THEN 19
                 WHEN bsc.icd10 LIKE ''O22%'' THEN 20
                 WHEN bsc.icd10 IN (''O980'') THEN 21
                 WHEN bsc.icd10 IN (''H521'') THEN 22
                 WHEN bsc.icd10 IN (''J06'',''J068'',''J069'') THEN 23
                 WHEN bsc.icd10 LIKE ''E66%'' THEN 24
                 WHEN bsc.icd10 LIKE ''E01%'' THEN 25
                 WHEN bsc.icd10 LIKE ''O24%'' THEN 26
                 WHEN bsc.icd10 IN (''A560'',''A561'',''A562'') THEN 28
                 WHEN bsc.icd10 IN (''A493'') THEN 29
                 WHEN bsc.icd10 IN (''A638'') THEN 30
                 WHEN bsc.icd10 IN (''B373'') THEN 31
                 WHEN bsc.icd10 IN (''A590'') THEN 32
                 WHEN bsc.icd10 IN (''B258'') THEN 33
                 WHEN bsc.icd10 IN (''O264'') THEN 34
                 WHEN bsc.icd10 IN (''O235'') THEN 35
                ELSE 999
            END AS num
            FROM '+ @select_table +' AS bsc
        ),
        result_rows(icd10, patient_id, num)
        AS (
            SELECT icd10, patient_id, num FROM build_rows
            UNION ALL
            SELECT icd10, patient_id,
            CASE WHEN num IN (6,7,8,10,11,12) THEN 5
                WHEN num IN (14,15,16,17,18,19,20,21,22,23,24,25,26) THEN 13
                WHEN num IN (28,29,30,31,32,33,34,35) THEN 27
                ELSE 999
            END AS num
            FROM build_rows
            UNION ALL
            SELECT icd10, patient_id, CASE WHEN num IN (10,11,12) THEN 9 ELSE 999 END AS num
            FROM build_rows
        )
        SELECT garr.num, garr.full_name, garr.icd10, count(final.num) AS c1
        FROM glb_A_rpt_row AS garr
        LEFT JOIN '+@calc_by_result+' AS final ON garr.num = final.num
        GROUP BY garr.num, garr.full_name, garr.icd10
        ORDER BY garr.num;
        '

    EXECUTE sp_executesql @result_rpt_3, N'@sdate date, @edate date, @pregnancy_date date, @lpu_id INT, @lpu_parent_id INT,
                                           @trimestr INT, @doctor_id VARCHAR(50)',
            @sdate, @edate, @pregnancy_date, @lpu_id, @lpu_parent_id, @trimestr, @doctor_id
END