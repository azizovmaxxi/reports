-- EXAMPLE PARAMETERS
declare @lpu_id integer = 68241--61411;
declare @lpu_parent_id integer = null--68241;
declare @sdate date = '2020-01-01';
declare @edate date = '2020-03-06';

execute rpt_6 @sdate, @edate, @lpu_id,@lpu_parent_id, 'diseases'

GO
IF OBJECT_ID ( 'rpt_6', 'P' ) IS NOT NULL DROP PROCEDURE rpt_6;

GO
CREATE PROCEDURE rpt_6 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT, @type_rpt VARCHAR(50)
AS
BEGIN
    DECLARE @where_lpu VARCHAR(100) = '';
    DECLARE @select_lpu VARCHAR(100) = 'lpu.id = a_c.patient_lpu';
    DECLARE @rpt_type_diseases VARCHAR(100) = ' build_rows_diseases ';
    DECLARE @rpt_type_deads VARCHAR(100) = ' build_rows_deads ';

    IF @type_rpt = 'patients'
    BEGIN
        set @rpt_type_diseases = ' build_rows_by_patients '
        set @rpt_type_deads = ' build_rows_deads_by_patients '
    END;


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

    DECLARE @result_rpt_6 NVARCHAR(MAX) ='
    WITH rpt29_dictionary(num, full_name, code, icd10)
        AS (
            SELECT num, full_name, code, icd10
            FROM (
                VALUES(1, ''Эндемический зоб(впервые установленный)'', ''53'', ''E01''),
                      (2, ''в т.ч. 15 -18 лет'', ''53.1'', null),
                      (3, ''беременность'',	''53.2'',	''O992''),
                      (4, ''Железодефицитная анемия(впервые установленная)'', ''58.4'', ''D50''),
                      (5, ''в т.ч. 15 -18 лет'', ''54.1'', null),
                      (6, ''беременность'', ''54.2'', ''O990''),
                      (7, ''ОРВИ'',	''46'', ''J00-J06''),
                      (8, ''Грипп'', ''47'', ''J10-J11'')
            ) AS glb_rpt_icd10_life(num, full_name, code, icd10)
        ),
        diseases(case_id, icd10, f_v_date, patient_id, birth_day, sex_id, num)
        AS (
        select a_c.id as case_id, a_d.icd10, a_c.f_v_date, a_c.patient_id, p_p.birth_day, p_p.sex_id
        ,CASE
            WHEN a_d.icd10 LIKE ''E01%'' THEN 1
            WHEN a_d.icd10 LIKE ''O992'' THEN 3
            WHEN (a_d.icd10 LIKE ''D50%'' OR icd10 LIKE ''O990%'') THEN 4
            WHEN a_d.icd10 BETWEEN ''J00'' AND ''J069'' THEN 7
            WHEN a_d.icd10 BETWEEN ''J10'' AND ''J119'' THEN 8
        END AS num
        from a_case as a_c
        inner join a_diagnosis as a_d on a_c.id=a_d.case_id
        inner join p_person AS p_p on a_c.patient_id=p_p.id
        inner join glb_lpu as lpu on '+ @select_lpu +'
        where a_d.is_final=1 AND a_d.is_f_life=1
          AND (a_c.f_v_date BETWEEN @sdate AND @edate)
          AND (a_d.icd10 like ''E01%'' OR a_d.icd10 like ''O992%'' OR a_d.icd10 like ''O990%'' OR a_d.icd10 like ''D50%''
               OR a_d.icd10 between ''J00'' AND ''J069''
               OR a_d.icd10 between ''J10'' AND ''J119'')
          AND ('+ @where_lpu +')
        ),
         the_deads(case_id, icd10, f_v_date, patient_id, birth_day, sex_id, num)
             AS (
             select a_c.id as case_id, a_d.icd10, a_c.f_v_date, a_c.patient_id, p_p.birth_day, p_p.sex_id
                 ,CASE
                      WHEN a_d.icd10 LIKE ''E01%'' THEN 1
                      WHEN a_d.icd10 LIKE ''O992'' THEN 3
                      WHEN (a_d.icd10 LIKE ''D50%'' OR icd10 LIKE ''O990%'') THEN 4
                      WHEN a_d.icd10 BETWEEN ''J00'' AND ''J069'' THEN 7
                      WHEN a_d.icd10 BETWEEN ''J10'' AND ''J119'' THEN 8
                 END AS num
             from a_case as a_c
             inner join A_visit as a_v on a_c.id = a_v.case_id
             inner join p_person as p_p on a_c.patient_id=p_p.id
             inner join a_diagnosis as a_d on a_c.id=a_d.case_id
             inner join glb_lpu as lpu on '+ @select_lpu +'
             where a_v.vistyp_code in (25,28) and a_d.basic=1
               AND (a_c.f_v_date BETWEEN @sdate AND @edate)
               AND (a_d.icd10 like ''E01%'' OR a_d.icd10 like ''O992%'' OR a_d.icd10 like ''O990%'' OR a_d.icd10 like ''D50%''
                OR a_d.icd10 between ''J00'' AND ''J069''
                OR a_d.icd10 between ''J10'' AND ''J119'')
                AND ('+ @where_lpu +')
             group by a_c.id, a_c.f_v_date, a_c.patient_id, a_d.icd10, p_p.birth_day, p_p.sex_id
        ),
        build_rows_diseases(case_id, icd10, f_v_date, patient_id, birth_day, sex_id, num)
        AS (
            select case_id, icd10, f_v_date, patient_id, birth_day, sex_id, num
            from diseases
            UNION
            select case_id, icd10, f_v_date, patient_id, birth_day, sex_id, num
            from (
                select case_id, icd10, f_v_date, patient_id, birth_day, sex_id,
                    case when num=1 and birth_day between DateAdd(yyyy,-18,f_v_date) and DateAdd(yyyy,-15,f_v_date) then 2
                         when num=4 and birth_day between DateAdd(yyyy,-18,f_v_date) and DateAdd(yyyy,-15,f_v_date) then 5
                         when num=4 and icd10 LIKE ''O990%'' then 6
                    end as num
                from diseases
            ) as calc_sub_rows
        ),
        build_rows_deads(case_id, icd10, f_v_date, patient_id, birth_day, sex_id, num)
        AS (
            select case_id, icd10, f_v_date, patient_id, birth_day, sex_id, num
            from the_deads
            UNION
            select case_id, icd10, f_v_date, patient_id, birth_day, sex_id, num
            from (
                 select case_id, icd10, f_v_date, patient_id, birth_day, sex_id,
                    case
                        when num = 1 and birth_day between DateAdd(yyyy, -18, f_v_date) and DateAdd(yyyy, -15, f_v_date) then 2
                        when num = 4 and birth_day between DateAdd(yyyy, -18, f_v_date) and DateAdd(yyyy, -15, f_v_date) then 5
                        when num = 4 and icd10 LIKE ''O990%'' then 6
                    end as num
                 from the_deads
            ) as calc_sub_rows
        ),
        build_rows_by_patients(case_id, f_v_date, patient_id, birth_day, sex_id, num)
        AS (
            select max(case_id) as case_id, max(f_v_date) as f_v_date, patient_id, birth_day, sex_id, num
            from build_rows_diseases
            group by num, patient_id, sex_id, birth_day
        ),
        build_rows_deads_by_patients(case_id, f_v_date, patient_id, birth_day, sex_id, num)
        AS (
            select max(case_id) as case_id, max(f_v_date) as f_v_date, patient_id, birth_day, sex_id, num
            from build_rows_deads
            group by num, patient_id, sex_id, birth_day
        )
    SELECT r29d.num, r29d.full_name, r29d.code, r29d.icd10,
           count(brdi.case_id) AS c1,
           count(CASE WHEN brdi.sex_id=0 THEN 1 ELSE NULL END) AS c2,
           count(CASE WHEN brdi.birth_day>DateAdd(yyyy, -15, brdi.f_v_date) THEN 1 ELSE NULL END) AS c4,
           count(CASE WHEN brdi.birth_day>DateAdd(yyyy, -1, brdi.f_v_date) THEN 1 ELSE NULL END) AS c5,
           count(CASE WHEN brdi.birth_day<=DateAdd(yyyy, -1, brdi.f_v_date) and brdi.birth_day>DateAdd(yyyy, -2, brdi.f_v_date)
                      THEN 1 ELSE NULL END) AS c6,
           count(CASE WHEN brdi.birth_day BETWEEN DateAdd(yyyy, -5, brdi.f_v_date) AND DateAdd(yyyy, -2, brdi.f_v_date)
                      THEN 1 ELSE NULL END) AS c7,
           count(brde.case_id) AS c8,
           count(CASE WHEN brde.birth_day>DateAdd(yyyy, -15, brde.f_v_date) THEN 1 ELSE NULL END) AS c9,
           count(CASE WHEN brde.birth_day>DateAdd(yyyy, -1, brde.f_v_date) THEN 1 ELSE NULL END) AS c10,
           count(CASE WHEN brde.birth_day<=DateAdd(yyyy, -1, brde.f_v_date) and brde.birth_day>DateAdd(yyyy, -2, brde.f_v_date)
                      THEN 1 ELSE NULL END) AS c11,
           count(CASE WHEN brde.birth_day BETWEEN DateAdd(yyyy, -5, brde.f_v_date) AND DateAdd(yyyy, -2, brde.f_v_date)
                      THEN 1 ELSE NULL END) AS c12
    FROM rpt29_dictionary AS r29d
    LEFT JOIN '+@rpt_type_diseases+' as brdi ON r29d.num = brdi.num
    LEFT JOIN '+@rpt_type_deads+' as brde ON r29d.num = brde.num
    GROUP BY r29d.num, r29d.full_name, r29d.code, r29d.icd10
    ORDER BY r29d.num
    '

    EXECUTE sp_executesql @result_rpt_6, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id
END