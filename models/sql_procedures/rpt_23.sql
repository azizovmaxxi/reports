-- EXAMPLE PARAMETERS
-- declare @lpu_id integer = 61411;
-- declare @lpu_parent_id integer = 68241;
-- declare @sdate date = '2020-01-01';
-- declare @edate date = '2020-03-06';

-- execute rpt_23 @sdate, @edate, @lpu_id,@lpu_parent_id

GO
IF OBJECT_ID ( 'rpt_23', 'P' ) IS NOT NULL DROP PROCEDURE rpt_23;

GO
CREATE PROCEDURE rpt_23 @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT
AS
BEGIN

    DECLARE @select_lpu VARCHAR(50) = 'lpu.id = a_c.patient_lpu';

    DECLARE @where_lpu VARCHAR(100) = '';
    IF @lpu_parent_id IS NULL
        set @where_lpu = 'lpu.id = @lpu_id OR lpu.parent_id = @lpu_id';
    ELSE

    IF @lpu_id > 0 AND @lpu_parent_id IS NOT NULL
        set @where_lpu = 'lpu.id = @lpu_id';

    IF @lpu_id = -1
        set @where_lpu = 'lpu.parent_id = @lpu_parent_id';
    IF @lpu_id = -2
    BEGIN
        set @where_lpu = 'lpu.id = @lpu_parent_id';
        set @select_lpu = 'lpu.id = a_c.lpu_id';
    END


    DECLARE @result_rpt_23 NVARCHAR(MAX) = '
    select  coalesce(all_count, 0) AS all_count, coalesce(male, 0) AS male, coalesce(female, 0) AS female
     ,coalesce(for_40_all, 0) AS for_40_all, coalesce(for_40_male, 0) AS for_40_male
     ,coalesce(for_40_female, 0) AS for_40_female
     ,coalesce(cast((for_40_all*100.0/NULLIF(all_count,0)) as decimal(5,2)),0) AS percentage_40_all
     ,coalesce(cast((for_40_male*100.0/NULLIF(male,0)) as decimal(5,2)),0) AS percentage_40_male
     ,coalesce(cast((for_40_female*100.0/NULLIF(female,0)) AS decimal(5,2)),0) AS percentage_40_female
    from (
        select COUNT(*) AS all_count,
               SUM(CASE WHEN sex_id = 1 THEN 1 ELSE 0 END) AS male,
               SUM(CASE WHEN sex_id = 0 THEN 1 ELSE 0 END) AS female,
               SUM(CASE WHEN (birth_day < DATEADD(yyyy, -40, f_v_date)) THEN 1 ELSE 0 END) AS for_40_all,
               SUM(CASE WHEN (birth_day < DATEADD(yyyy, -40, f_v_date)) AND sex_id = 1 THEN 1 ELSE 0 END) AS for_40_male,
               SUM(CASE WHEN (birth_day < DATEADD(yyyy, -40, f_v_date)) AND sex_id = 0 THEN 1 ELSE 0 END) AS for_40_female
        from (
                 select max(a_c.f_v_date)f_v_date,a_c.patient_id, p_p.birth_day, p_p.sex_id, a_c.post_code
                 from a_case as a_c
                 join a_diagnosis as a_d on a_c.id = a_d.case_id
                 join p_person as p_p on a_c.patient_id = p_p.id
                 join glb_lpu as lpu on '+@select_lpu+'
                 where a_d.is_final = 1
                   AND recor = 1
                   AND a_d.icd10 between ''I10'' and ''I139''
                   and a_c.f_v_date BETWEEN @sdate and @edate
                   and ('+ @where_lpu +')
                 group by a_c.patient_id, p_p.birth_day, p_p.sex_id, a_c.post_code
             ) AS subquery2
    ) AS subquery1'

    EXECUTE sp_executesql @result_rpt_23, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT',
            @sdate, @edate, @lpu_id, @lpu_parent_id
END;