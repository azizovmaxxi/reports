
CREATE PROCEDURE rpt_15 (@sdate date, @edate date, @lpu_id int, @lpu_parent_id int)
as set nocount on

	declare @sql nvarchar(max)
	declare @dinamicField varchar(80)
	declare @join varchar(50)
	declare @where varchar(50)

	set @dinamicField = case  when @lpu_id=-2 then 'a.lpu_id' else 'a.patient_lpu' end;

	set @join = case when @lpu_id=-2 then 'a.lpu_id=lpu.id' else 'a.patient_lpu=lpu.id' end;

	set @where = case when @lpu_parent_id is null then 'lpu.parent_id = @lpu_id'
				 when @lpu_parent_id is not null and @lpu_id=-1 then 'lpu.parent_id = @lpu_parent_id'
				 when @lpu_parent_id is not null and @lpu_id=-2 then 'lpu.id=@lpu_parent_id' 
				 when @lpu_parent_id is not null and @lpu_id>0 then 'lpu.id=@lpu_id' end;     

	set @sql =';with ACase as
		( 
			select distinct a.f_v_date,  a.patient_id, p.birth_day, p.sex_id, a.doctor_id, a.post_code,
			' + @dinamicField + '
			from a_case as a inner join a_diagnosis as d on a.id = d.case_id
			inner join p_person as p on a.patient_id = p.id
			inner join glb_lpu as lpu on  ' + @join + '
			where a.f_v_date >= @sdate and a.f_v_date <= @edate and d.is_final = 1 and d.is_f_life=1 
			and d.icd10 between ''I10'' and ''I139'' and ' + @where + '			 
		)
    select all_count, isnull(male,0) male, isnull(female,0) female, isnull(for_40_all,0) for_40_all, isnull(for_40_male,0) for_40_male, isnull(for_40_female,0) for_40_female
	     ,isnull(cast((for_40_all*100/all_count) as decimal(5,2)),0) percentage_40_all
		 ,isnull(cast((for_40_male*100/male) as decimal(5,2)),0)  percentage_40_male
		 ,isnull(cast((for_40_female*100/female) as decimal(5,2)),0) percentage_40_female
		  from (
			select COUNT(*) AS all_count,
					   SUM(CASE WHEN sex_id = 1 THEN 1 ELSE 0 END) AS male,
					   SUM(CASE WHEN sex_id = 0 THEN 1 ELSE 0 END) AS female,
					   SUM(CASE WHEN (birth_day < DATEADD(yyyy, -40, f_v_date)) THEN 1 ELSE 0 END) AS for_40_all,
					   SUM(CASE WHEN (birth_day < DATEADD(yyyy, -40, f_v_date)) AND sex_id = 1 THEN 1 ELSE 0 END) AS for_40_male,
					   SUM(CASE WHEN (birth_day < DATEADD(yyyy, -40, f_v_date)) AND sex_id = 0 THEN 1 ELSE 0 END) AS for_40_female from ACase
					   ) tbl'

    execute sp_executesql @sql, N'@sdate date, @edate date, @lpu_id int, @lpu_parent_id int',
									@sdate, @edate, @lpu_id, @lpu_parent_id
	--print @sql




