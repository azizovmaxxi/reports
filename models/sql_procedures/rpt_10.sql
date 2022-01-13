USE [PersonOn]
GO
/****** Object:  StoredProcedure [dbo].[rpt_10]    Script Date: 25.06.2020 18:22:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[rpt_10] @sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT=null
AS
BEGIN
	declare @dinamicField varchar(80)
	declare @where nvarchar(800)

	set @dinamicField = case  when @lpu_id=-2 then 'a.lpu_id lpu_id' else 'a.patient_lpu lpu_id' end;

	set @where = case when @lpu_parent_id is null then 'a.patient_lpu in (select id from glb_lpu where (id=@lpu_id or parent_id=@lpu_id))'
				 when @lpu_parent_id is not null and @lpu_id=-1 then 'a.patient_lpu in (select id from glb_lpu where (id=@lpu_parent_id or parent_id=@lpu_parent_id))'
				 when @lpu_parent_id is not null and @lpu_id=-2 then 'a.lpu_id in (select id from glb_lpu where (id=@lpu_parent_id))'
				 when @lpu_parent_id is not null and @lpu_id>0 then 'a.patient_lpu=@lpu_id' end; 


DECLARE @result_rpt_10 NVARCHAR(MAX) = '
WITH result
    AS (SELECT a.id AS case_id, a.f_v_date,a.patient_id,
			   c.birth_day,c.sex_id,c.status_mhi, a.doc_id,a.smoking,
			   convert(int, cast(d.pressure_max AS varchar(10)) + '''' + cast(d.pressure_min AS varchar(10))) AS pressure,
			   d.dm,a.post_code, a.hosp_id,a.emergency,
			   b.diag_id,b.icd10,cast(b.is_f_life AS tinyint) is_f_life, b.basic, ' + @dinamicField +' 
				FROM (a_case AS a
					INNER JOIN a_diagnosis AS b ON a.id=b.case_id)
					INNER JOIN p_person c ON a.patient_id=c.id
					INNER JOIN a_pressure AS d ON a.id=d.case_id
				WHERE b.is_final=1 AND b.icd10 BETWEEN ''A00'' AND ''T989'' and '+ @where + '
				  AND a.f_v_date >= @sdate AND a.f_v_date <= @edate
    )

	    select all_count, isnull(male,0) male, isnull(female,0) female, 
		all_count1, isnull(male1,0) male1, isnull(female1,0) female1
		from
		(
			SELECT  sum(CASE WHEN pressure>=14090 AND pressure<180110 THEN 1 ELSE null END) AS all_count,
					sum(CASE WHEN sex_id=1 and pressure>=14090 AND pressure<180110 THEN 1 ELSE null END) AS male,
					sum(CASE WHEN sex_id=0 and pressure>=14090 AND pressure<180110 THEN 1 ELSE null END) AS female,
					sum(CASE WHEN pressure>=180110 THEN 1 ELSE null END) AS all_count1,
					sum(CASE WHEN sex_id=1 and pressure>=180110 THEN 1 ELSE null END) AS male1,
					sum(CASE WHEN sex_id=0 and pressure>=180110 THEN 1 ELSE null END) AS female1
			FROM result
		) a'

    EXECUTE sp_executesql @result_rpt_10, N'@sdate date, @edate date, @lpu_id INT, @lpu_parent_id INT=null',
            @sdate, @edate, @lpu_id, @lpu_parent_id

END

