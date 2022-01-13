-- EXAMPLE PARAMETERS
-- declare @patient_id VARCHAR(36) = '00000000-0000-0000-0000-000000000000'
-- declare @sdate date = '2019-12-26';
-- declare @edate date = '2020-01-01';
-- execute rpt_9 @sdate, @edate, @patient_id

GO
IF OBJECT_ID ( 'rpt_9', 'P' ) IS NOT NULL DROP PROCEDURE rpt_9;

GO
CREATE PROCEDURE rpt_9 @sdate date, @edate date, @patient_id VARCHAR(36)
AS
BEGIN
    WITH cases(case_id, f_v_date, emergency, hosp_name, hosp_code, doctor, depend)
             AS (
            -- Get cases
            SELECT a_c.id AS case_id, CONVERT(date, a_c.f_v_date) AS f_v_date
                 , a_c.emergency, lpu.full_name AS hosp_name, lpu.code AS hosp_code
                 , P_doctor.Name AS doctor
                 , 'cases' AS depend
            FROM A_case AS a_c
                     INNER JOIN P_doctor ON a_c.doctor_id = P_doctor.ID
                     LEFT JOIN glb_lpu AS lpu on a_c.hosp_id = lpu.id
            WHERE (f_v_date BETWEEN @sdate AND @edate) AND patient_id = @patient_id
        ),
         visits(case_id, vistyp_code, full_name, count_v_type, depend)
             AS (
             SELECT v.case_id, v.vistyp_code, g_avt.full_name, COUNT(v.vistyp_code) AS count_v_type
                  , 'visits' AS depend
             FROM glb_A_visit_type AS g_avt
                      INNER JOIN A_visit AS v ON g_avt.code = v.vistyp_code
                      INNER JOIN cases ON cases.case_id = v.case_id
             GROUP BY v.case_id, v.vistyp_code, g_avt.full_name
         ),
         diagnosis(case_id, icd10, is_final, is_f_life, traum_code, depend)
             AS(
             SELECT a_d.case_id, icd10, is_final, is_f_life, traum_code
                  , 'diagnosis' AS depend
             FROM A_diagnosis AS a_d
                      INNER JOIN cases ON cases.case_id = a_d.case_id
         ),
         procedures(case_id, proctyp_code, full_name, p_number, depend)
             AS(
             SELECT a_p.case_id, a_p.proctyp_code, g_apt.full_name, a_p.p_number
                  , 'procedures' AS depend
             FROM A_procedure AS a_p
                      INNER JOIN glb_A_proc_type AS g_apt ON g_apt.code = a_p.proctyp_code
                      INNER JOIN cases ON a_p.case_id = cases.case_id
         ),
         narrow_specialists(case_id, post_code, post_name, icd10, depend)
             AS(
             SELECT a_s.case_id, a_s.post_code, g_sp.full_name AS post_name, a_s.icd10
                  , 'narrow_specialists' AS depend
             FROM A_specialist AS a_s
                      INNER JOIN glb_S_post AS g_sp ON g_sp.code = a_s.post_code
                      INNER JOIN cases ON a_s.case_id = cases.case_id
         ),
         contraceptions(case_id, contr_id, full_name, med_code, depend)
             AS(
             SELECT a_con.case_id, a_con.contr_id, g_acon.full_name, a_con.med_code
                  , 'contraceptions' AS depend
             FROM A_contraception AS a_con
                      INNER JOIN glb_A_contraceptive AS g_acon ON a_con.contr_id = g_acon.id
                      INNER JOIN cases ON a_con.case_id = cases.case_id
         ),
         medications(case_id, icd10, med_code, full_name, medshp_code, prescript_code, depend)
             AS (
             SELECT A_medication.case_id, A_medication.icd10, A_medication.med_code
                  , g_amed.full_name, A_medication.medshp_code, A_medication.prescript_code
                  , 'medications' AS depend
             FROM A_medication
                      INNER JOIN glb_A_medication AS g_amed ON A_medication.med_code = g_amed.code
                      INNER JOIN cases ON a_medication.case_id = cases.case_id
         ),
         a_references(case_id, ref_date, lpu_code, lpu_name, doctor_name, post_code, depend)
             AS ( -- направлен из
             SELECT a_reference.case_id, a_reference.ref_date
                  , glb_lpu.code AS lpu_code, glb_lpu.short_name AS lpu_name
                  , p_doctor.Name AS doctor_name, A_reference.post_code
                  , 'a_references' AS depend
             FROM A_reference
              INNER JOIN glb_lpu ON A_reference.lpu_id = glb_lpu.id
              INNER JOIN cases ON A_reference.case_id = cases.case_id
              INNER JOIN p_doctor ON p_doctor.ID = A_reference.doctor_id
         ),
         pressures(case_id, pressure_min, pressure_max, visit_num, dm, depend)
             AS ( -- артериальное давление
             SELECT A_pressure.case_id, A_pressure.pressure_min, A_pressure.pressure_max
                  , A_pressure.visit_num, A_pressure.dm, 'pressures' AS depend
             FROM A_pressure
              INNER JOIN cases ON A_pressure.case_id = cases.case_id
         ),
         risks(case_id, control_ad, accept_gipotenz, percen, depend)
             AS ( -- факторы риска
             SELECT A_risk.case_id, IIF(A_risk.control_ad=1, 'Да', 'Нет')
                  , IIF(A_risk.accept_gipotenz=1, 'Да', 'Нет') AS accept_gipotenz
                  , CASE WHEN percen = 1 THEN '<10%'
                      WHEN percen = 2 THEN '10<20%'
                      WHEN percen = 3 THEN '20<30%'
                      WHEN percen = 4 THEN '30<40%'
                      WHEN percen = 5 THEN '>40%'
                    END AS percen
                  , 'risks' AS depend
             FROM A_risk
              INNER JOIN cases ON A_risk.case_id = cases.case_id
         ),
         mother_health(case_id, is_registered, got_acid, iodine, one_preg, two_preg, positive_result,
             course_treatmedt, hiv, hiv_result, tested_anemia, jda, Rh0, doctor_visit, protein_urine,
             sowing_urine, ad, gravidogramm, depend)
             AS ( -- Охрана здоровья матери
             SELECT A_mother_health.case_id, is_registered, IIF(got_acid=1, 'Да', 'Нет') AS got_acid
                  , IIF(iodine=1, 'Да', 'Нет') AS iodine, IIF(one_preg=1, 'Да', 'Нет') AS one_preg
                  , IIF(two_preg=1, 'Да', 'Нет') AS two_preg, IIF(positive_result=1, 'Да', 'Нет') AS positive_result
                  , IIF(course_treatmedt=1, 'Да', 'Нет') AS course_treatmedt, IIF(hiv=1, 'Да', 'Нет') AS hiv
                  , IIF(hiv_result=1, 'Да', 'Нет') AS hiv_result, IIF(tested_anemia=1, 'Да', 'Нет') AS tested_anemia
                  , IIF(jda=1, 'Да', 'Нет') AS jda, IIF(Rh0=1, 'Да', 'Нет') AS Rh0
                  , IIF(doctor_visit=1, 'Да', 'Нет') AS doctor_visit, IIF(protein_urine=1, 'Да', 'Нет') AS protein_urine
                  , IIF(sowing_urine=1, 'Да', 'Нет') AS sowing_urine, IIF(ad=1, 'Да', 'Нет') AS ad
                  , IIF(gravidogramm=1, 'Да', 'Нет') AS gravidogramm
                  , 'mother_health' AS depend
             FROM A_mother_health
              INNER JOIN cases ON A_mother_health.case_id = cases.case_id
         ),
         lovz(case_id, l_registered, l_group, recog_first, recog_group, depend)
             AS ( -- ЛОВЗ
             SELECT A_lovz.case_id, IIF(l_registered=1, 'Да', 'Нет') AS l_registered, l_group
                  , IIF(recog_first=1, 'Да', 'Нет') AS recog_first, recog_group
                  , 'lovz' AS depend
             FROM A_lovz
              INNER JOIN cases ON A_lovz.case_id = cases.case_id
         ),
         pressure_reference(case_id, ref_ad, level_glucose, level_cholesterol, cervix, cervix_change
             , breast, breast_change, depend)
             AS ( -- ЛОВЗ
             SELECT A_pressure_reference.case_id
                  , CASE WHEN ref_ad = 1 THEN 'До врачебным кабинетом'
                      WHEN ref_ad = 2 THEN 'Средним мед. работником ФАП'
                      WHEN ref_ad = 3 THEN 'Специалистом СКЗ'
                    END AS ref_ad
                  , level_glucose, level_cholesterol
                  , IIF(cervix=1, 'Да', 'Нет') AS cervix, IIF(cervix_change=1, 'Да', 'Нет') AS cervix_change
                  , IIF(breast=1, 'Да', 'Нет') AS breast, IIF(breast_change=1, 'Да', 'Нет') AS breast_change
                  , 'pressure_reference' AS depend
             FROM A_pressure_reference
              INNER JOIN cases ON A_pressure_reference.case_id = cases.case_id
         ),
         chield_health(case_id, three_month, six_month, feeding_yes, feeding_age
                       , breast_feeding_three, breast_feeding_sex, breast_feeding_year, breast_feeding_twoear
                       , diarrhea_oral, diarrhea_zink, diarrhea_antibiotic, pmcp, depend)
             AS ( -- Охрана здоровья  детского населения
             SELECT A_chield_health.case_id
                  , three_month, six_month, feeding_yes, feeding_age
                  , breast_feeding_three, breast_feeding_sex, breast_feeding_year, breast_feeding_twoear
                  , IIF(diarrhea_oral=1, 'Да', 'Нет'), IIF(diarrhea_zink=1, 'Да', 'Нет')
                  , IIF(diarrhea_antibiotic=1, 'Да', 'Нет'), IIF(pmcp=1, 'Да', 'Нет')
                  , 'chield_health' AS depend
             FROM A_chield_health
              INNER JOIN cases ON A_chield_health.case_id = cases.case_id
         ),
         observation_chield(case_id, life_three_day, age_one, age_two, age_three, age_four, age_five, age_six, age_seven
             , age_eight, age_nine, age_ten, age_eleven, age_twelve, quarter_one, quarter_two, quarter_three, quarter_four
             , two_three_age, gulazyk_get, gulazyk_notget, degelmin, degelmin_over, doctor_gsv, depend)
             AS ( -- Наблюдения за здоровыми детьми
             SELECT A_observation_chield.case_id
                  , IIF(life_three_day=1, 'Врачом', 'Мед. сестрой') AS life_three_day, IIF(age_one=1, '1', null) AS age_one
                  , IIF(age_two=1, '2', null) AS age_two, IIF(age_three=1, '3', null)AS age_three
                  , IIF(age_four=1, '4', null) AS age_four, IIF(age_five=1, '5', null) AS age_five
                  , IIF(age_six=1, '6', null) AS age_six, IIF(age_seven=1, '7', null) AS age_seven
                  , IIF(age_eight=1, '8', null) AS age_eight, IIF(age_nine=1, '9', null) AS age_nine
                  , IIF(age_ten=1, '10', null) AS age_ten, IIF(age_eleven=1, '11', null) AS age_eleven
                  , IIF(age_twelve=1, '12', null) AS age_twelve, IIF(quarter_one=1, '1 квартал', null) AS quarter_one
                  , IIF(quarter_two=1, '2 квартал', null) AS quarter_two, IIF(quarter_three=1, '3 квартал', null) AS quarter_three
                  , IIF(quarter_four=1, '4 квартал', null) AS quarter_four, IIF(two_three_age=1, '1 полугодие', '2 полугодие') AS two_three_age
                  , IIF(gulazyk_get=1, 'Получает', null) AS gulazyk_get, IIF(gulazyk_notget=1, 'Получает', null) AS gulazyk_notget
                  , IIF(degelmin=1, '5 лет', null) AS degelmin
                  , IIF(degelmin_over=1, 'старше 5 лет по показанию', null) AS degelmin_over
                  , IIF(doctor_gsv=1, 'Да', 'Нет') AS doctor_gsv
                  , 'observation_chield' AS depend
             FROM A_observation_chield
              INNER JOIN cases ON A_observation_chield.case_id = cases.case_id
         )
    SELECT
        COALESCE(( SELECT * FROM cases ORDER BY f_v_date FOR XML PATH('cases')), '') AS cases,
        COALESCE(( SELECT * FROM visits FOR XML PATH('visits')), '') AS visits,
        COALESCE(( SELECT * FROM diagnosis FOR XML PATH('diagnosis')), '') AS diagnosis,
        COALESCE(( SELECT * FROM procedures FOR XML PATH('procedures')), '') AS procedures,
        COALESCE(( SELECT * FROM narrow_specialists FOR XML PATH('narrow_specialists')), '') AS narrow_specialists,
        COALESCE(( SELECT * FROM contraceptions FOR XML PATH('contraceptions')), '') AS contraceptions,
        COALESCE(( SELECT * FROM medications FOR XML PATH('medications')), '') AS medications,
        COALESCE(( SELECT * FROM a_references FOR XML PATH('a_references')), '') AS a_references,
        COALESCE(( SELECT * FROM pressures FOR XML PATH('pressures')), '') AS pressures,
        COALESCE(( SELECT * FROM risks FOR XML PATH('risks')), '') AS risks,
        COALESCE(( SELECT * FROM mother_health FOR XML PATH('mother_health')), '') AS mother_health,
        COALESCE(( SELECT * FROM lovz FOR XML PATH('lovz')), '') AS lovz,
        COALESCE(( SELECT * FROM pressure_reference FOR XML PATH('pressure_reference')), '') AS pressure_reference,
        COALESCE(( SELECT * FROM chield_health FOR XML PATH('chield_health')), '') AS chield_health,
        COALESCE(( SELECT * FROM observation_chield FOR XML PATH('observation_chield')), '') AS observation_chield
END