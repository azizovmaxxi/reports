-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-02-02';
-- declare @edate date = '2020-03-06';
-- declare @last_name varchar(50) = 'Рах'

GO
IF OBJECT_ID ( 'rpt_4', 'P' ) IS NOT NULL DROP PROCEDURE rpt_4;

GO
CREATE PROCEDURE rpt_4 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT, @last_name VARCHAR(50) = null,
                       @first_name VARCHAR(50) = null, @mid_name VARCHAR(50) = null, @birthday_start DATE = null,
                       @birthday_end DATE = null, @icd10_start VARCHAR(5) = null, @icd10_end VARCHAR(5) = null,
                       @is_f_life BIT = null, @is_final BIT = null, @sex_id TINYINT = null, @doctor_id VARCHAR(50) = null,
                       @post_code VARCHAR(50) = null, @visit BIT = null, @percen TINYINT = null, @control_ad BIT = null,
                       @accept_gipotenz BIT = null, @cervix BIT = null, @cervix_change BIT = null, @breast BIT = null,
                       @breast_change BIT = null, @is_registered TINYINT = null, @got_acid BIT = null, @iodine BIT = null,
                       @one_preg BIT = null, @two_preg BIT = null, @positive_result BIT = null, @course_treatmedt BIT = null,
                       @hiv BIT = null, @hiv_result BIT = null, @tested_anemia BIT = null, @jda BIT = null, @rh0 BIT = null,
                       @doctor_visit TINYINT = null, @protein_urine BIT = null, @sowing_urine BIT = null, @ad BIT = null,
                       @gravidogramm BIT = null, @vistyp_code TINYINT = null
AS
BEGIN

    DECLARE @where VARCHAR(MAX) = '';

    IF @last_name IS NOT NULL AND ltrim(rtrim(@last_name)) <> ''
        set @where = concat(@where, ' AND p_p.last_name like @last_name+''%''');
    IF @first_name IS NOT NULL AND ltrim(rtrim(@first_name)) <> ''
        set @where = concat(@where, ' AND p_p.first_name like @first_name+''%''');
    IF @mid_name IS NOT NULL AND ltrim(rtrim(@mid_name)) <> ''
        set @where = concat(@where, ' AND p_p.mid_name like @mid_name+''%''');
    IF @is_f_life IS NOT NULL
        set @where = concat(@where, ' AND diag.is_f_life = @is_f_life');
    IF @is_final IS NOT NULL
        set @where = concat(@where, ' AND diag.is_final = @is_final');
    IF @sex_id IS NOT NULL
        set @where = concat(@where, ' AND p_p.sex_id = @sex_id');

    -- START CHECK ICD PARAMS
    IF (@icd10_start IS NOT NULL AND ltrim(rtrim(@icd10_start)) <> '') AND (@icd10_end IS NOT NULL AND ltrim(rtrim(@icd10_end)) <> '')
        set @where = concat(@where, ' AND diag.icd10 BETWEEN @icd10_start AND @icd10_end');

    IF (@icd10_start IS NOT NULL AND ltrim(rtrim(@icd10_start)) <> '') AND (@icd10_end IS NULL OR ltrim(rtrim(@icd10_end)) = '')
        set @where = concat(@where, ' AND diag.icd10 = @icd10_start');

    IF (@icd10_start IS NULL OR ltrim(rtrim(@icd10_start)) = '') AND (@icd10_end IS NOT NULL AND ltrim(rtrim(@icd10_end)) <> '')
        set @where = concat(@where, ' AND diag.icd10 = @icd10_end');
    -- END CHECK ICD PARAMS

    -- START CHECK PATIENT BIRTHDAY  PARAMS FOR EXIST
    IF (@birthday_start IS NOT NULL AND ltrim(rtrim(@birthday_start)) <> '') AND (@birthday_end IS NOT NULL AND ltrim(rtrim(@birthday_end)) <> '')
        set @where = concat(@where, ' AND p_p.birth_day BETWEEN @birthday_start AND @birthday_end');

    IF (@birthday_start IS NOT NULL AND ltrim(rtrim(@birthday_start)) <> '') AND (@birthday_end IS NULL OR ltrim(rtrim(@birthday_end)) = '')
        set @where = concat(@where, ' AND p_p.birth_day = @birthday_start');

    IF (@birthday_start IS NULL OR ltrim(rtrim(@birthday_start)) = '') AND (@birthday_end IS NOT NULL AND ltrim(rtrim(@birthday_end)) <> '')
        set @where = concat(@where, ' AND p_p.birth_day = @birthday_end ');
    -- END CHECK PATIENT BIRTHDAY  PARAMS FOR EXIST

    IF @doctor_id IS NOT NULL
        set @where = concat(@where, ' AND case_visit.doctor_id = @doctor_id ');

    IF @post_code IS NOT NULL
        set @where = concat(@where, ' AND case_visit.post_code = @post_code ');

    -- START A_risk PARAMS
    IF @percen IS NOT NULL
        set @where = concat(@where, ' AND a_risk.percen = @percen ');

    IF @control_ad IS NOT NULL
        set @where = concat(@where, ' AND a_risk.control_ad = @control_ad ');

    IF @control_ad IS NOT NULL
        set @where = concat(@where, ' AND a_risk.accept_gipotenz = @accept_gipotenz ');
    -- END A_risk PARAMS
    -- START a_pressure_reference PARAMS
    IF @cervix IS NOT NULL
        set @where = concat(@where, ' AND apr.cervix = @cervix ');

    IF @cervix_change IS NOT NULL
        set @where = concat(@where, ' AND apr.cervix_change = @cervix_change ');

    IF @breast IS NOT NULL
        set @where = concat(@where, ' AND apr.breast = @breast ');

    IF @breast_change IS NOT NULL
        set @where = concat(@where, ' AND apr.breast_change = @breast_change ');
    -- END a_pressure_reference PARAMS

    -- START A_mother_health
    IF @is_registered IS NOT NULL
        set @where = concat(@where, ' AND amh.is_registered = @is_registered ');
    IF @got_acid IS NOT NULL
        set @where = concat(@where, ' AND amh.got_acid = @got_acid ');
    IF @iodine IS NOT NULL
        set @where = concat(@where, ' AND amh.iodine = @iodine ');
    IF @one_preg IS NOT NULL
        set @where = concat(@where, ' AND amh.one_preg = @one_preg ');
    IF @two_preg IS NOT NULL
        set @where = concat(@where, ' AND amh.two_preg = @two_preg ');
    IF @positive_result IS NOT NULL
        set @where = concat(@where, ' AND amh.positive_result = @positive_result ');
    IF @course_treatmedt IS NOT NULL
        set @where = concat(@where, ' AND amh.course_treatmedt = @course_treatmedt ');
    IF @hiv IS NOT NULL
        set @where = concat(@where, ' AND amh.hiv = @hiv ');
    IF @hiv_result IS NOT NULL
        set @where = concat(@where, ' AND amh.hiv_result = @hiv_result ');
    IF @tested_anemia IS NOT NULL
        set @where = concat(@where, ' AND amh.tested_anemia = @tested_anemia ');
    IF @jda IS NOT NULL
        set @where = concat(@where, ' AND amh.jda = @jda ');
    IF @rh0 IS NOT NULL
        set @where = concat(@where, ' AND amh.rh0 = @rh0 ');
    IF @doctor_visit IS NOT NULL
        set @where = concat(@where, ' AND amh.doctor_visit = @doctor_visit ');
    IF @protein_urine IS NOT NULL
        set @where = concat(@where, ' AND amh.protein_urine = @protein_urine ');
    IF @sowing_urine IS NOT NULL
        set @where = concat(@where, ' AND amh.sowing_urine = @sowing_urine ');
    IF @ad IS NOT NULL
        set @where = concat(@where, ' AND amh.ad = @ad ');
    IF @gravidogramm IS NOT NULL
        set @where = concat(@where, ' AND amh.gravidogramm = @gravidogramm ');
    -- END A_mother_health

    -- START case_visit
    IF @vistyp_code IS NOT NULL
        set @where = concat(@where, ' AND case_visit.vistyp_code = @vistyp_code ');
    -- END case_visit


    DECLARE @where_lpu VARCHAR(100) = '';
    IF @lpu_parent_id IS NULL
        set @where_lpu = 'lpu.id = @lpu_id OR lpu.parent_id = @lpu_id';
    ELSE

        IF @lpu_id > 0 AND @lpu_parent_id IS NOT NULL
            set @where_lpu = 'lpu.id = @lpu_id';

    IF @lpu_id = -1
        set @where_lpu = 'lpu.parent_id = @lpu_parent_id';
    IF @lpu_id = -2
        set @where_lpu = 'lpu.id = @lpu_parent_id';

    DECLARE @top_select VARCHAR(10) = '';
    IF @where = ''
        set @top_select = ' TOP 50 '
    ELSE
        set @top_select = ' TOP 1000 ';

    DECLARE @visits VARCHAR(50) = ' DISTINCT ';
    DECLARE @by_date VARCHAR(50) = ' a_c.f_v_date '
    IF @visit IS NOT NULL
        BEGIN
            set @visits = ''
            set @by_date = ' visit.visit_date '
        END

    DECLARE @result_cif NVARCHAR(MAX) = '
    select ' + @top_select + 'case_visit.case_id, case_visit.f_v_date, case_visit.patient_id,
       p_p.last_name , p_p.first_name, p_p.mid_name, p_p.birth_day,
       concat(street.name, '', дом '', padr.house, '', кв. '', padr.flat, '', тел.'', padr.phone) AS address,
       p_p.sex_id, left(case_visit.patient_lpu, 4) AS patient_lpu, left(case_visit.lpu_id, 4) AS lpu_id,
       case_visit.post_code, gsp.full_name as person_post, p_doc.name AS doctor_name, case_visit.hosp_id,
       case_visit.emergency, case_visit.vistyp_code, diag.diag_id, diag.icd10, diag.basic,
       diag.is_f_life, diag.is_final, diag.traum_code, case_visit.doctor_id
    from (select '+ @visits +' a_c.id AS case_id, '+ @by_date +' AS f_v_date, a_c.patient_id, a_c.lpu_id,
        a_c.patient_lpu, a_c.post_code, a_c.hosp_id, a_c.emergency, a_c.doctor_id,
        visit.vistyp_code
       from A_case as a_c
       inner join A_visit as visit on a_c.id = visit.case_id
       where '+ @by_date +' BETWEEN @sdate AND @edate
    ) as case_visit
    inner join A_diagnosis as diag on case_visit.case_id = diag.case_id
    inner join p_person    as p_p on case_visit.patient_id = p_p.id
    inner join P_doctor    as p_doc on case_visit.doctor_id = p_doc.id
    inner join glb_S_post  as gsp on case_visit.post_code = gsp.code
    inner join p_address   as padr on p_p.address_id = padr.id
    left join glb_streets as street on padr.street_id = street.id
    inner join glb_lpu AS lpu on case_visit.lpu_id = lpu.id
    left join a_risk on case_visit.case_id = a_risk.case_id
    left join a_pressure_reference as apr on case_visit.case_id = apr.case_id
    left join a_mother_health as amh on case_visit.case_id = amh.case_id
    where ('+ @where_lpu +') ' + @where + ' ORDER BY last_name, first_name, mid_name';

    EXECUTE sp_executesql @result_cif, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT, @last_name VARCHAR(50),
                         @first_name VARCHAR(50), @mid_name VARCHAR(50), @birthday_start DATE, @birthday_end DATE,
                         @icd10_start VARCHAR(5), @icd10_end VARCHAR(5),
                         @is_f_life BIT, @is_final BIT, @sex_id TINYINT, @doctor_id VARCHAR(50), @post_code VARCHAR(50),
                         @percen TINYINT, @control_ad BIT, @accept_gipotenz BIT, @cervix BIT, @cervix_change BIT,
                         @breast BIT, @breast_change BIT, @is_registered TINYINT, @got_acid BIT, @iodine BIT, @one_preg BIT,
                         @two_preg BIT, @positive_result BIT, @course_treatmedt BIT, @hiv BIT, @hiv_result BIT,
                         @tested_anemia BIT, @jda BIT, @rh0 BIT, @doctor_visit TINYINT, @protein_urine BIT, @sowing_urine BIT,
                         @ad BIT, @gravidogramm BIT',
            @sdate, @edate, @lpu_id, @lpu_parent_id, @last_name, @first_name, @mid_name, @birthday_start, @birthday_end,
            @icd10_start, @icd10_end, @is_f_life, @is_final, @sex_id, @doctor_id, @post_code, @percen, @control_ad,
            @accept_gipotenz, @cervix, @cervix_change, @breast, @breast_change, @is_registered, @got_acid, @iodine,
            @one_preg, @two_preg, @positive_result, @course_treatmedt, @hiv, @hiv_result, @tested_anemia, @jda, @rh0,
            @doctor_visit, @protein_urine, @sowing_urine, @ad, @gravidogramm
END;