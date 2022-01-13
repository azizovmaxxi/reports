USE [***]
GO
/****** Object:  StoredProcedure [dbo].[rpt_1]    Script Date: 12.06.2020 8:33:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[rpt_1] (@sdate date, @edate date, @lpu_id int, @lpu_parent_id int, @type_rpt nvarchar(30))
as set nocount on
	--Создать тип
    --create type CaseType as table(id int, f_v_date smalldatetime, lpu_id int, patient_id uniqueidentifier, birth_day date, sex_id bit,  diag_id int, icd10 varchar(4), is_f_life bit
				--			       primary key(id, diag_id), index ix_Case_type(icd10))
	--create type rCaseType as table(num int, id int, f_v_date smalldatetime, lpu_id int, patient_id uniqueidentifier, birth_day date, sex_id bit,  diag_id int, icd10 varchar(4), is_f_life bit)
	--drop type rCaseType

	--select count(*) c1,  sum(CASE WHEN (DATEDIFF(hour,birth_day,f_v_date)/8766) > 18 THEN 1 ELSE 0 END) c2, sum(CASE WHEN (DATEDIFF(hour,birth_day,f_v_date)/8766) > 18 and is_f_life=1 THEN 1 ELSE 0 END) c3 

	declare @vNum int
	declare @sql nvarchar(max)=''
	declare @dinamicField varchar(80)
	declare @where nvarchar(800)
	declare @code nvarchar(800)
	declare @tCase CaseType;
	declare @rCase rCaseType;

	set @dinamicField = case  when @lpu_id=-2 then 'a.lpu_id lpu_id' else 'a.patient_lpu lpu_id' end;

	set @where = case when @lpu_parent_id is null then 'a.patient_lpu in (select id from glb_lpu where (id=@lpu_id or parent_id=@lpu_id))'
				 when @lpu_parent_id is not null and @lpu_id=-1 then 'a.patient_lpu in (select id from glb_lpu where (id=@lpu_parent_id or parent_id=@lpu_parent_id))'
				 when @lpu_parent_id is not null and @lpu_id=-2 then 'a.lpu_id in (select id from glb_lpu where (id=@lpu_parent_id))'
				 when @lpu_parent_id is not null and @lpu_id>0 then 'a.patient_lpu=@lpu_id' end; 
				     
    ---Создание @tCase с данными 
	set @sql =N';with ACase as
		( 
			select a.id, a.f_v_date, ' + @dinamicField + ', a.patient_id, p.sex_id, p.birth_day, d.diag_id, d.icd10,
			d.is_f_life 
			from a_case as a inner join a_diagnosis as d on a.id = d.case_id
			inner join p_person as p on a.patient_id = p.id			
			where a.f_v_date >= @sdate and a.f_v_date <= @edate and d.is_final = 1
			and d.icd10 between ''A00'' and ''T989'' and ' + @where + '			 
		)
    select id, f_v_date, lpu_id, patient_id, birth_day, sex_id,  diag_id, icd10, is_f_life from ACAse'

    insert into @tCase execute sp_executesql @sql, N'@sdate date, @edate date, @lpu_id int, @lpu_parent_id int',
									@sdate, @edate, @lpu_id, @lpu_parent_id

	---Обработка основных строк - впервые в жизни...
	declare @num int, @Between varchar(300)=null, @Like varchar(300), @Betweens varchar(300)=null, @Likes varchar(300)
	declare curs cursor for select num, icd10_between, icd10_like from glb_A_rpt_rows where is_women=0 and is_other=0 order by num
	open curs
	fetch from curs into @num, @Between, @Like
	while @@FETCH_STATUS=0
	begin
		set @where='' 
		if (@num=1)
		begin

			insert into @rCase(num, id, f_v_date, lpu_id, patient_id, birth_day,sex_id,diag_id,icd10, is_f_life) 
			select num, id, f_v_date, lpu_id, patient_id, birth_day,sex_id,diag_id,icd10, is_f_life from 
			(
				select @num as num, id, f_v_date, lpu_id, patient_id, birth_day,sex_id,diag_id,icd10, is_f_life, 
				ROW_NUMBER() over (partition by patient_id, icd10 order by f_v_date desc) rnum from @tCase where is_f_life=1
			) a where rnum=1
		end
		if @Between is not null or @Like is not null
		begin
			if @Between is not null
				begin
					set @where = dbo.A_fGetBetween(@Between)
				end
			
			if @Like is not null
			  begin
				if @Between is not null and @Like is not null
					begin
						set @where = @where + ' or '
					end
				   set @where = @where + ' ' + dbo.A_fGetLike(@Like)
			  end

			set @sql='select num, id, f_v_date, lpu_id, patient_id, birth_day,sex_id,diag_id,icd10, is_f_life from 
			(
				select @num as num, id, f_v_date, lpu_id, patient_id, birth_day,sex_id,diag_id,icd10, is_f_life, 
				ROW_NUMBER() over (partition by patient_id, icd10 order by f_v_date desc) rnum from @tCase where is_f_life=1
				 and ' + @where + '
			) a where rnum=1'
			insert into @rCase execute sp_executesql @sql, N'@tCase CaseType READONLY, @num int', @tCase, @num 
		end

		 	 
		 --select count(*) c1,  sum(CASE WHEN (DATEDIFF(hour,birth_day,f_v_date)/8766) > 18 THEN 1 ELSE 0 END) c2, sum(CASE WHEN (DATEDIFF(hour,birth_day,f_v_date)/8766) > 18 and is_f_life=1 THEN 1 ELSE 0 END) c3 
		 --from  ACase where is_f_life=1
		fetch next from curs into @num, @Between, @Like
	end
	close curs
	deallocate curs

	delete t from @tCase t join @rCase r on t.patient_id=r.patient_id and t.icd10=r.icd10 where r.num=1 and t.is_f_life=0
	
	--Обработка основных строк - не впервые в жизни...
	declare curs cursor for select num, icd10_between, icd10_like from glb_A_rpt_rows where is_women=0 and is_other=0 order by num
	open curs
	fetch from curs into @num, @Between, @Like
	while @@FETCH_STATUS=0
	begin
		set @where='' 
		if (@num=1)
		begin

			insert into @rCase(num, id, f_v_date, lpu_id, patient_id, birth_day,sex_id,diag_id,icd10, is_f_life) 
			select num, id, f_v_date, lpu_id, patient_id, birth_day,sex_id,diag_id,icd10, is_f_life from 
			(
				select @num as num, id, f_v_date, lpu_id, patient_id, birth_day,sex_id,diag_id,icd10, is_f_life, 
				ROW_NUMBER() over (partition by patient_id, icd10 order by f_v_date desc) rnum from @tCase
			) a where rnum=1
		end
		if @Between is not null or @Like is not null
		begin
			if @Between is not null
				begin
					set @where = dbo.A_fGetBetween(@Between)
				end
			
			if @Like is not null
			  begin
				if @Between is not null and @Like is not null
					begin
						set @where = @where + ' or '
					end
				   set @where = @where + ' ' + dbo.A_fGetLike(@Like)
			  end

			set @sql='select num, id, f_v_date, lpu_id, patient_id, birth_day,sex_id,diag_id,icd10, is_f_life from 
			(
				select @num as num, id, f_v_date, lpu_id, patient_id, birth_day,sex_id,diag_id,icd10, is_f_life, 
				ROW_NUMBER() over (partition by patient_id, icd10 order by f_v_date desc) rnum from @tCase where is_f_life=1
				 and ' + @where + '
			) a where rnum=1'
			insert into @rCase execute sp_executesql @sql, N'@tCase CaseType READONLY, @num int', @tCase, @num 
		end

		fetch next from curs into @num, @Between, @Like
	end
	close curs
	deallocate curs

	--Строки "из них лица женского пола"
	declare curs cursor for select num from glb_A_rpt_rows where is_women=1 order by num
	open curs
	fetch from curs into @num
	while @@FETCH_STATUS=0
	begin
		insert into @rCase select @num as num, id, f_v_date, lpu_id, patient_id, birth_day,sex_id,diag_id,icd10, is_f_life from @rCase where sex_id=0 and num=@num-1
		fetch next from curs into @num
	end
	close curs
	deallocate curs

	--Строки "прочие"
	declare curs cursor for select num, code from glb_A_rpt_rows where is_other=1 order by num
	open curs
	fetch from curs into @num, @code
	while @@FETCH_STATUS=0
	begin
	    set @code = SUBSTRING(@code, 1, CHARINDEX('.', @code, 0))+'0'
		set @vNum = (select num from glb_A_rpt_rows where code like @code) 
		insert into @rCase 
		select @num as num, id, f_v_date, lpu_id, patient_id, birth_day,sex_id, r.diag_id, icd10, is_f_life from @rCase r
		left join (select distinct diag_id from @rCase where num between @vNum+2 and @num-1) b on r.diag_id=b.diag_id
		 where b.diag_id is null and num=@vNum
		 print @vNum
		fetch next from curs into @num, @code
	end
	close curs
	deallocate curs

	
	select a.num, a.full_name, a.code, a.icd10, 
		count(id) c1, 
		sum(case when is_f_life=1 then 1 else 0 end) c2, 
		sum(case when (DATEDIFF(hour,birth_day,f_v_date)/8766) >= 18 then 1 else 0 end) c3,
		sum(case when (DATEDIFF(hour,birth_day,f_v_date)/8766) >= 18 and is_f_life=1 then 1 else 0 end) c4,
		sum(case when (DATEDIFF(hour,birth_day,f_v_date)/8766)>=15 and (DATEDIFF(hour,birth_day,f_v_date)/8766)<=17 then 1 else 0 end) c5,
		sum(case when (DATEDIFF(hour,birth_day,f_v_date)/8766)>=15 and (DATEDIFF(hour,birth_day,f_v_date)/8766)<=17 and is_f_life=1 then 1 else 0 end) c6,
		sum(case when (DATEDIFF(hour,birth_day,f_v_date)/8766)>=0 and (DATEDIFF(hour,birth_day,f_v_date)/8766)<=14 then 1 else 0 end) c7,
		sum(case when (DATEDIFF(hour,birth_day,f_v_date)/8766)>=0 and (DATEDIFF(hour,birth_day,f_v_date)/8766)<=14 and is_f_life=1 then 1 else 0 end) c8,
		sum(case when (DATEDIFF(hour,birth_day,f_v_date)/8766)<1  then 1 else 0 end) c9,
		sum(case when (DATEDIFF(hour,birth_day,f_v_date)/8766)<1 and is_f_life=1 then 1 else 0 end) c10,
		sum(case when (DATEDIFF(hour,birth_day,f_v_date)/8766)>=1 and (DATEDIFF(hour,birth_day,f_v_date)/8766)<=4 then 1 else 0 end) c11,
		sum(case when (DATEDIFF(hour,birth_day,f_v_date)/8766)>=1 and (DATEDIFF(hour,birth_day,f_v_date)/8766)<=4 and is_f_life=1 then 1 else 0 end) c12

		from glb_A_rpt_rows a left join  @rCase b on a.num=b.num
	group by a.num, a.full_name, a.code, a.icd10
	order by 1




