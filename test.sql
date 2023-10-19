create procedure syn.usp_ImportFileCustomerSeasonal
	@ID_Record int
as
    -- 1) Проставил отступ для set
    set nocount on

-- 2) Проставил отступ для блока begin
begin
    -- 3) Все переменные задаются в одном объявлении
	declare
	    @RowCount int = (select count(*) from syn.SA_CustomerSeasonal)
	    ,@ErrorMessage varchar(max)

    -- 4) Комментарий с таким же отступом как и код
    -- Проверка на корректность загрузки
	if not exists (
	    -- 5) В условных операторах весь блок смещается на 1 отступ
        select 1
        from syn.ImportFile as f
        where f.ID = @ID_Record
            and f.FlagLoaded = cast(1 as bit)
	    )

	-- 6) На одном уровне с `if` и `begin/end`
	-- 7) Вложения выделяются отступами
    begin
        set @ErrorMessage = 'Ошибка при загрузке файла, проверьте корректность данных'
        -- 8) Убрал лишнюю пустую строку
        raiserror(@ErrorMessage, 3, 1)
        return
    end

	CREATE TABLE #ProcessedRows (
		ActionType varchar(255),
		ID int
	)
    -- 9) Между -- и комментарием добавил один пробел
	-- Чтение из слоя временных данных
	select
		cc.ID as ID_dbo_Customer
		,cst.ID as ID_CustomerSystemType
		,s.ID as ID_Season
		,cast(cs.DateBegin as date) as DateBegin
		,cast(cs.DateEnd as date) as DateEnd
		,cd.ID as ID_dbo_CustomerDistributor
		,cast(isnull(cs.FlagActive, 0) as bit) as FlagActive
	into #CustomerSeasonal
	from syn.SA_CustomerSeasonal cs
		join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
			and cc.ID_mapping_DataSource = 1
		join dbo.Season as s on s.Name = cs.Season
		join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor
			and cd.ID_mapping_DataSource = 1
		join syn.CustomerSystemType as cst on cs.CustomerSystemType = cst.Name
	where try_cast(cs.DateBegin as date) is not null
		and try_cast(cs.DateEnd as date) is not null
		and try_cast(isnull(cs.FlagActive, 0) as bit) is not null

	-- Определяем некорректные записи
	-- Добавляем причину, по которой запись считается некорректной
	select
	    -- 10) перенёс запятую
		cs.*,
		case
			when cc.ID is null
			    -- 11) Результат на 1 отступ от when
			    then 'UID клиента отсутствует в справочнике "Клиент"'
			when cd.ID is null
			    then 'UID дистрибьютора отсутствует в справочнике "Клиент"'
			when s.ID is null
			    then 'Сезон отсутствует в справочнике "Сезон"'
			when cst.ID is null
			    then 'Тип клиента в справочнике "Тип клиента"'
			when try_cast(cs.DateBegin as date) is null
			    then 'Невозможно определить Дату начала'
			when try_cast(cs.DateEnd as date) is null
			    then 'Невозможно определить Дату начала'
			when try_cast(isnull(cs.FlagActive, 0) as bit) is null
			    then 'Невозможно определить Активность'
		end as Reason
	into #BadInsertedRows
	from syn.SA_CustomerSeasonal as cs
	    -- 12) отступ для блока join
        left join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
            and cc.ID_mapping_DataSource = 1
        left join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor
            -- 13) отступ для and
            and cd.ID_mapping_DataSource = 1
        left join dbo.Season as s on s.Name = cs.Season
        left join syn.CustomerSystemType as cst on cst.Name = cs.CustomerSystemType
	where cc.ID is null
		or cd.ID is null
		or s.ID is null
		or cst.ID is null
		or try_cast(cs.DateBegin as date) is null
		or try_cast(cs.DateEnd as date) is null
		or try_cast(isnull(cs.FlagActive, 0) as bit) is null

end
