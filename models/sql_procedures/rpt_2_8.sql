-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-12-31';
-- declare @lpu_id integer = -2;
-- declare @lpu_parent_id integer = 68241;

-- execute rpt_2_8 @sdate, @edate, @lpu_id, @lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_2_8', 'P' ) IS NOT NULL DROP PROCEDURE rpt_2_8;

GO
CREATE PROCEDURE rpt_2_8 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
AS
BEGIN

    DECLARE @lpu INT = null;

    IF @lpu_parent_id IS NULL
        set @lpu = @lpu_id
    ELSE
        set @lpu = @lpu_parent_id;

    WITH list_cases(f_v_date, patient_id, birth_day, lpu_code, lpu_name, post_code, doctor_id, diseases)
    AS (
        SELECT min(a_c.f_v_date) f_v_date, a_c.patient_id
             ,p.birth_day, lpu.code AS lpu_code, lpu.short_name AS lpu_name, a_c.post_code, a_c.doctor_id
             ,COUNT(CASE WHEN a_d.icd10 BETWEEN 'A00' AND 'T989' THEN 1 ELSE NULL END) AS diseases
        FROM a_case AS a_c
        INNER JOIN a_diagnosis AS a_d ON a_c.id=a_d.case_id
        INNER JOIN p_person AS p ON a_c.patient_id=p.id
        INNER JOIN glb_lpu AS lpu ON a_c.lpu_id = lpu.id
        WHERE a_c.f_v_date BETWEEN @sdate AND @edate
          AND lpu.parent_id = @lpu
        GROUP BY a_c.patient_id, p.birth_day, lpu.code, lpu.short_name, a_c.post_code, a_c.doctor_id
    ), calc_columns(doctor_id, post_code, lpu_code, lpu_name, c1, c2, c3, c4, c5, c6)
         AS (
        SELECT l_c.doctor_id, l_c.post_code, l_c.lpu_code, l_c.lpu_name,
               count(*) AS c1,
               count(CASE WHEN l_c.birth_day > DateAdd(y,-29, DateAdd(m,-11, DateAdd(yyyy, -14, l_c.f_v_date))) THEN 1 ELSE NULL END) AS c2,
               count(CASE WHEN l_c.birth_day < DateAdd(y,-29, DateAdd(m,-11, DateAdd(yyyy, -14, l_c.f_v_date))) THEN 1 ELSE NULL END) AS c3,
               count(CASE WHEN l_c.diseases > 0 THEN 1 ELSE NULL END) AS c4,
               count(CASE WHEN l_c.diseases > 0 AND l_c.birth_day > DateAdd(y,-29, DateAdd(m,-11, DateAdd(yyyy, -14, l_c.f_v_date))) THEN 1 ELSE NULL END) AS c5,
               count(CASE WHEN l_c.diseases > 0 AND l_c.birth_day < DateAdd(y,-29, DateAdd(m,-11, DateAdd(yyyy, -14, l_c.f_v_date))) THEN 1 ELSE NULL END) AS c6
        FROM list_cases AS l_c
        GROUP BY l_c.doctor_id, l_c.post_code, l_c.lpu_code, l_c.lpu_name
    ),result_rows(doctor_id, post_code, lpu_code, lpu_name,
                  c1, c2, c3, c4, c5, c6, percent_c2, percent_c3, percent_c5,percent_c6)
         AS(
        SELECT doctor_id, post_code, lpu_code, lpu_name, c1, c2, c3, c4, c5, c6,
               isnull((c2*100/NULLIF(c1,0)),0) AS percent_c2,
               isnull((c3*100/NULLIF(c1,0)),0) AS percent_c3,
               isnull((c5*100/NULLIF(c4,0)),0) AS percent_c5,
               isnull((c6*100/NULLIF(c4,0)),0) AS percent_c6
        FROM calc_columns
    )
    SELECT doctor_id, post_code, gsp.full_name AS post_name, lpu_code, lpu_name, p_d.Name AS doctor_name,
           c1, c2, c3, c4, c5, c6, percent_c2, percent_c3, percent_c5, percent_c6
    FROM result_rows
    JOIN P_doctor AS p_d ON p_d.ID = result_rows.doctor_id
    JOIN glb_S_post AS gsp on result_rows.post_code = gsp.code
    ORDER BY lpu_code DESC, doctor_name

END