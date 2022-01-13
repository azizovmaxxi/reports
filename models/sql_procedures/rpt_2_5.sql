declare @lpu_id integer = 68241--61411;
declare @lpu_parent_id integer = null--68241;
declare @sdate date = '2020-01-01';
declare @edate date = '2020-12-31';

execute rpt_2_5 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_2_5', 'P' ) IS NOT NULL DROP PROCEDURE rpt_2_5;

GO
CREATE PROCEDURE rpt_2_5 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
AS
BEGIN
    DECLARE @where_lpu VARCHAR(100) = '';

    IF @lpu_parent_id IS NULL
        set @where_lpu = 'lpu.id = @lpu_id OR lpu.parent_id = @lpu_id'
    IF @lpu_id > 0 AND @lpu_parent_id IS NOT NULL
        set @where_lpu = 'lpu.id = @lpu_id';
    IF @lpu_id = -1
        set @where_lpu = 'lpu.parent_id = @lpu_parent_id';
    IF @lpu_id = -2
        set @where_lpu = 'lpu.id = @lpu_parent_id';

    DECLARE @result_rpt_2_5 NVARCHAR(MAX) ='
    WITH glb_contraception(num, full_name, code, contr_like)
        AS (
            SELECT num, full_name, code, contr_like
            FROM
                (VALUES
                 (1, ''Число женщин репродуктивного возраста, пользующихся контрацептивами'', ''1.0'', ''contr_id is not null''),
                 (2, ''в т.ч. ВМС'', ''1.1'', ''contr_id=3''),
                 (3, ''оральные контрацептивы'', ''1.2'', ''contr_id in (1,2)''),
                 (4, ''инъекционные'', ''1.3'', ''contr_id=4''),
                 (5, ''из них Депо-провера'', ''1.3.1'', ''contr_id=0''),
                 (6, ''стерилизация'', ''1.4'', ''contr_id=8''),
                 (7, ''презервативы'', ''1.5'', ''contr_id=5''),
                 (8, ''другие'', ''1.6'', ''contr_id not in (1,2,3,4,5,8)''),
                 (9, ''Число мужчин репродуктивного возраста, пользующихся контрацептивами'', ''4.0'', ''contr_id is not null''),
                 (10, ''в т.ч презервативами'', ''4.1'', ''contr_id=5''),
                 (11, ''Стерилизовано'', ''5.0'', ''contr_id=8'')
                )nums(num, full_name, code, contr_like)
        ),
         list_with_contracept(f_v_date, patient_id, birth_day, sex_id, doc_id, post_code, lpu_id, contr_id, num)
         AS (
             SELECT a_c.f_v_date, a_c.patient_id, p_p.birth_day, p_p.sex_id, a_c.doc_id, a_c.post_code, a_c.lpu_id, a_con.contr_id,
                    CASE
                        WHEN a_con.contr_id=3 AND sex_id=0 THEN 2
                        WHEN a_con.contr_id IN (1,2) AND sex_id=0 THEN 3
                        WHEN a_con.contr_id=4 AND sex_id=0 THEN 4
                        WHEN a_con.contr_id=0 AND sex_id=0 THEN 5
                        WHEN a_con.contr_id=8 AND sex_id=0 THEN 6
                        WHEN a_con.contr_id=5 AND sex_id=0 THEN 7
                        WHEN a_con.contr_id not in (1,2,3,4,5,8) AND sex_id=0  THEN 8
                        WHEN a_con.contr_id=5 AND sex_id=1 THEN 10
                        WHEN a_con.contr_id=8 AND sex_id=1 THEN 11
                    END AS num
             FROM a_case AS a_c
             INNER JOIN a_contraception AS a_con ON a_c.id=a_con.case_id
             INNER JOIN p_person AS p_p ON a_c.patient_id=p_p.id
             INNER JOIN glb_lpu AS lpu on a_c.lpu_id = lpu.id
             WHERE p_p.birth_day > DateAdd(yyyy, -49, a_c.f_v_date)
               AND a_c.f_v_date BETWEEN @sdate AND @edate
               AND ('+@where_lpu+')
             GROUP BY a_c.f_v_date, a_c.patient_id, p_p.birth_day, p_p.sex_id, a_c.doc_id, a_c.post_code, a_c.lpu_id, a_con.contr_id
         ),
         all_num(f_v_date, patient_id, birth_day, sex_id, doc_id, post_code, lpu_id, contr_id, num)
         AS(
             SELECT f_v_date, patient_id, birth_day, sex_id, doc_id, post_code, lpu_id, contr_id,
                CASE
                    WHEN contr_id IS NOT NULL AND sex_id=0 THEN 1
                    WHEN contr_id IS NOT NULL AND sex_id=1 THEN 9
                END AS num
             FROM list_with_contracept
             UNION
             SELECT f_v_date, patient_id, birth_day, sex_id, doc_id, post_code, lpu_id, contr_id, num
             FROM list_with_contracept
         )
         SELECT gc.num, gc.full_name, gc.code,
             count(lwc.num) AS c1,
             coalesce(count(case when lwc.birth_day>DateAdd(yyyy, -13, f_v_date) then 1 else null end),0) AS c2,
             coalesce(count(case when lwc.birth_day>DateAdd(yyyy,-14,f_v_date) and lwc.birth_day<=DateAdd(yyyy,-13,f_v_date)
                then 1 else null end),0) AS c3,
             coalesce(count(case when lwc.birth_day>DateAdd(yyyy,-15,f_v_date) and lwc.birth_day<=DateAdd(yyyy,-14,f_v_date)
                then 1 else null end),0) AS c4,
             coalesce(count(case when lwc.birth_day>DateAdd(yyyy,-18,f_v_date) and lwc.birth_day<=DateAdd(yyyy,-15,f_v_date)
                then 1 else null end),0) AS c5,
             coalesce(count(case when lwc.birth_day>DateAdd(yyyy,-20,f_v_date) and lwc.birth_day<=DateAdd(yyyy,-18,f_v_date)
                then 1 else null end),0) AS c6,
             coalesce(count(case when lwc.birth_day>DateAdd(yyyy,-25,f_v_date) and lwc.birth_day<=DateAdd(yyyy,-20,f_v_date)
                then 1 else null end),0) AS c7,
             coalesce(count(case when lwc.birth_day>DateAdd(yyyy,-30,f_v_date) and lwc.birth_day<=DateAdd(yyyy,-25,f_v_date)
                then 1 else null end),0) AS c8,
             coalesce(count(case when lwc.birth_day>DateAdd(yyyy,-35,f_v_date) and lwc.birth_day<=DateAdd(yyyy,-30,f_v_date)
                then 1 else null end),0) AS c9,
             coalesce(count(case when lwc.birth_day>DateAdd(yyyy,-40,f_v_date) and lwc.birth_day<=DateAdd(yyyy,-35,f_v_date)
                then 1 else null end),0) AS c10,
             coalesce(count(case when lwc.birth_day>DateAdd(yyyy,-49,f_v_date) and lwc.birth_day<=DateAdd(yyyy,-40,f_v_date)
                then 1 else null end),0) AS c11
         FROM glb_contraception AS gc
         left join all_num AS lwc ON gc.num = lwc.num
         GROUP BY gc.num, gc.full_name, gc.code
         ORDER BY gc.num
    '

    EXECUTE sp_executesql @result_rpt_2_5, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id
END