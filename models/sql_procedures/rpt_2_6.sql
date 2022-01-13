-- declare @lpu_id integer = -2;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-12-31';

-- execute rpt_2_6 @sdate, @edate, @lpu_id, @lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_2_6', 'P' ) IS NOT NULL DROP PROCEDURE rpt_2_6;

GO
CREATE PROCEDURE rpt_2_6 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT,
    @sex_id TINYINT = NULL, @age VARCHAR(100) = NULL, @is_f_life BIT = null
AS
BEGIN
    DECLARE @where_lpu VARCHAR(100) = '';
    DECLARE @where VARCHAR(300) = '';
    DECLARE @select_lpu VARCHAR(50) = 'lpu.id = a_c.patient_lpu';

    IF @sex_id IS NOT NULL
        set @where = concat(@where, ' AND p_p.sex_id=@sex_id ')
    IF @is_f_life IS NOT NULL
        set @where = concat(@where, ' AND a_d.is_f_life=1 ')
    IF @age IS NOT NULL
        set @where = concat(@where,
            CASE
                WHEN @age='_14' THEN ' AND p_p.birth_day>DateAdd(yyyy, -15, a_c.f_v_date) '
                WHEN @age='_15_17' THEN ' AND p_p.birth_day between DateAdd(yyyy, -18, a_c.f_v_date) and  DateAdd(yyyy, -15, a_c.f_v_date) '
                WHEN @age='adult_teenager' THEN ' AND p_p.birth_day<DateAdd(yyyy, -15, a_c.f_v_date) '
                WHEN @age='adult' THEN ' AND p_p.birth_day<DateAdd(yyyy, -18, a_c.f_v_date) '
            END)

    IF @lpu_parent_id IS NULL
        set @where_lpu = ' (lpu.id = @lpu_id OR lpu.parent_id = @lpu_id) '
    IF @lpu_id > 0 AND @lpu_parent_id IS NOT NULL
        set @where_lpu = ' lpu.id = @lpu_id ';
    IF @lpu_id = -1
        set @where_lpu = ' lpu.parent_id = @lpu_parent_id ';
    IF @lpu_id = -2
        BEGIN
            set @where_lpu = 'lpu.id = @lpu_parent_id';
            set @select_lpu = 'lpu.id = a_c.lpu_id';
        END

    DECLARE @result_rpt_2_6 NVARCHAR(MAX) ='
    WITH glb_traum_icd(num, full_name, code, icd10)
        AS(
        SELECT num, full_name, code, icd10
        FROM
            (VALUES
             (1, ''Черепно-мозговые травмы (Всего)'', ''1.0'', ''S02-S07''),
             (2, ''Травмы позвоночника (Всего)'', ''2.0'', ''S12-S14, S22.0-S22.1, S23.0-S23.3, S24, S32-S34 кроме (S32.3-S32.5, S33.4), T08-T09''),
             (3, ''Травмы верхних конечностей'', ''3.0'', ''S40-S69, T00.2, T00.6, T02.2, T02.4, T03.2, T04.2, T05.0-T05.2, T10-T11''),
             (4, ''Травмы нижних конечностей'', ''4.0'', ''S70, S72-S73, S76-S80, S82-S83, S86-S90, S92-S93, S96-S99, T00.3, T02.3, T02.5, T03.3, T04.3, T05.3-T05.5, T12-T13''),
             (5, ''Травмы костей таза'', ''5.0'', ''S32.3-S32.5, S33.4''),
             (6, ''Травмы грудной клетки'', ''6.0'', ''S20, S22.2-S22.9, S23.4-S23.5, S25-S29''),
             (7, ''Травмы живота (Всего)'', ''7.0'', ''S30.1, S31.1, S31.8, S36''),
             (8, ''Травмы органов мочеполовой системы (Всего)'', ''8.0'', ''S37, S38.0, S38.2''),
             (9, ''Ожоги'', ''9.0'', ''T20-T32''),
             (10, ''Прочие'', ''10'', null),
             (11, ''Всего'', ''11'', ''S00-S99, T00-T35''),
             (12, ''Умерло'', ''12'', null)
            )nums(num, full_name, code, icd10)
      ),
      all_traum(case_id, f_v_date, birth_day, sex_id, is_f_life, traum_code, patient_id, icd10, basic, num) AS
        (
        SELECT MAX(a_c.id) AS case_id ,MAX(a_c.f_v_date) AS f_v_date, MAX(p_p.birth_day) AS birth_day ,MAX(p_p.sex_id) AS sex_id
             ,MAX(cast(a_d.is_f_life AS tinyint)) AS is_f_life, MAX(a_d.traum_code) traum_code
             ,a_c.patient_id, a_d.icd10, CAST(MAX(CAST(a_d.basic AS int)) AS bit) AS basic,
             CASE WHEN icd10 BETWEEN ''S02'' AND ''S079'' THEN 1
                 WHEN (icd10 BETWEEN ''S12'' AND ''S149'' OR icd10 BETWEEN ''S220'' AND ''S221''
                     OR icd10 BETWEEN ''S230'' AND ''S233'' OR icd10 BETWEEN ''T08'' AND ''T099''
                     OR icd10 BETWEEN ''S32'' AND ''S322'' OR icd10 BETWEEN ''S327'' AND ''S328''
                     OR icd10 BETWEEN ''S33'' AND ''S333'' OR icd10 BETWEEN ''S335'' AND ''S337'') THEN 2
                 WHEN (icd10 BETWEEN ''S40'' AND ''S699''
                     OR icd10 IN (''T002'', ''T006'', ''T022'', ''T024'', ''T032'', ''T042'', ''T050'', ''T051'', ''T052'')
                     OR icd10 BETWEEN ''T10'' AND ''T119'') THEN 3
                 WHEN (icd10 BETWEEN ''S70'' AND ''S709'' OR icd10 BETWEEN ''S72'' AND ''S739''
                     OR icd10 BETWEEN ''S76'' AND ''S809'' OR icd10 BETWEEN ''S82'' AND ''S839''
                     OR icd10 BETWEEN ''S86'' AND ''S909'' OR icd10 BETWEEN ''S92'' AND ''S939''
                     OR icd10 BETWEEN ''S96'' AND ''S999'' OR icd10 IN (''T003'', ''T023'', ''T025'', ''T033'', ''T043'', ''T053'', ''T054'', ''T055'')
                     OR icd10 BETWEEN ''T12'' AND ''T139'') THEN 4
                 WHEN (icd10 IN (''S323'', ''S324'', ''S325'', ''S334'')) THEN 5
                 WHEN (icd10 BETWEEN ''S20'' AND ''S209'' OR icd10 BETWEEN ''S222'' AND ''S229''
                     OR icd10 IN (''S234'', ''S235'') OR icd10 BETWEEN ''S25'' AND ''S299'') THEN 6
                 WHEN (icd10 BETWEEN ''S36'' AND ''S369'' OR icd10 IN (''S301'', ''S311'', ''S318'')) THEN 7
                 WHEN (icd10 BETWEEN ''S37'' AND ''S379'' OR icd10 IN (''S380'', ''S382'')) THEN 8
                 WHEN (icd10 BETWEEN ''T20'' AND ''T329'') THEN 9
                 ELSE 10
                 END AS num
        FROM A_case AS a_c
        INNER JOIN A_diagnosis AS a_d ON a_c.id = a_d.case_id
        INNER JOIN P_person AS p_p ON a_c.patient_id = p_p.id
        INNER JOIN glb_lpu AS lpu on '+ @select_lpu +'
        WHERE a_d.is_final = 1
            AND a_c.f_v_date BETWEEN @sdate AND @edate
            AND (icd10 BETWEEN ''S00'' AND ''S999'' OR icd10 BETWEEN ''T00'' AND ''T359'')
            AND (' + @where_lpu +') '+ @where +'
        GROUP BY patient_id, icd10
    ),
      all_num(case_id, f_v_date, birth_day, sex_id, is_f_life, traum_code, patient_id, icd10, basic, num)
      AS (
          SELECT case_id, f_v_date, birth_day, sex_id, is_f_life, traum_code, patient_id, icd10, basic, num
          FROM all_traum
          UNION
          SELECT case_id, f_v_date, birth_day, sex_id, is_f_life, traum_code, patient_id, icd10, basic,
                 CASE WHEN num IS NOT NULL THEN 11 END AS num
          FROM all_traum
          UNION
          SELECT a_t.case_id, a_t.f_v_date, a_t.birth_day, a_t.sex_id, a_t.is_f_life,
                 a_t.traum_code, a_t.patient_id, a_t.icd10, a_t.basic, 12 AS num
          FROM all_traum AS a_t
          INNER JOIN A_visit AS a_v ON a_t.case_id = a_v.case_id
          WHERE a_v.vistyp_code IN (25, 28) AND basic=1
      )
    SELECT glb_traum_icd.num,
           glb_traum_icd.full_name,
           glb_traum_icd.code,
           glb_traum_icd.icd10,
           count(a_n.num) AS c1,
           coalesce(count(CASE WHEN a_n.traum_code=11 THEN 1 ELSE NULL END),0) AS c2,
           coalesce(count(CASE WHEN a_n.traum_code=13 THEN 1 ELSE NULL END),0) AS c3,
           coalesce(count(CASE WHEN a_n.traum_code=12 THEN 1 ELSE NULL END),0) AS c4,
           coalesce(count(CASE WHEN a_n.traum_code=14 THEN 1 ELSE NULL END),0) AS c5,
           coalesce(count(CASE WHEN a_n.traum_code=23 THEN 1 ELSE NULL END),0) AS c6,
           coalesce(count(CASE WHEN (a_n.traum_code IN (15, 21, 22, 24) OR (a_n.case_id IS NOT NULL AND a_n.traum_code IS NULL))
               THEN 1 ELSE NULL END),0) AS c7
    FROM glb_traum_icd
    LEFT JOIN all_num AS a_n ON glb_traum_icd.num=a_n.num
    GROUP BY glb_traum_icd.num, glb_traum_icd.full_name, glb_traum_icd.code, glb_traum_icd.icd10
    ORDER BY num'

    EXECUTE sp_executesql @result_rpt_2_6, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT, @sex_id TINYINT',
            @sdate, @edate, @lpu_id, @lpu_parent_id, @sex_id;
END
