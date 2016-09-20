CREATE PROCEDURE [audit].[Аудит_Создать триггеры аудита]
  @Схема                     SYSNAME,
  @Таблица                   SYSNAME,
  @Исключить_из_конфигурации BIT = 0
AS
BEGIN
  SET NOCOUNT ON

  DECLARE
    @UpdateTriggerName SYSNAME,
    @InsertTriggerName SYSNAME,
    @DeleteTriggerName SYSNAME,

    @UpdateTriggerScript NVARCHAR(MAX),
    @InsertTriggerScript NVARCHAR(MAX),
    @DeleteTriggerScript NVARCHAR(MAX),

    @UpdateTriggerCreateOrAlter NVARCHAR(10),
    @InsertTriggerCreateOrAlter NVARCHAR(10),
    @DeleteTriggerCreateOrAlter NVARCHAR(10),

    @ColumnsInsertSelect VARCHAR(MAX),
    @ColumnsDeleteSelect VARCHAR(MAX),

    @msg NVARCHAR(500)

  SET @UpdateTriggerName = @Таблица + N' Аудит UPDATE'
  SET @InsertTriggerName = @Таблица + N' Аудит INSERT'
  SET @DeleteTriggerName = @Таблица + N' Аудит DELETE'

  SET @msg = N'PROC [Аудит_Создать триггеры аудита] ([' + @Схема + '].[' + @Таблица + N']): '

  DECLARE @InfoMsg NVARCHAR(500)

  SET @InfoMsg = @msg + N' запущена'

  PRINT @InfoMsg

  IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @Таблица AND TABLE_SCHEMA = @Схема)
  BEGIN
    SET @msg = @msg + N'Таблица отсутствует в схеме БД'
    RAISERROR(@msg, 16, 1)
    RETURN
  END

  DECLARE @Columns TABLE(ColID int, ColName SYSNAME, ColType SYSNAME, ColMaxLen INT)

  -- Определяем наличие атрибута-первичного ключа
  DECLARE @PKColName SYSNAME, @count INT, @PkDataType SYSNAME

  SELECT @count = COUNT(tc.CONSTRAINT_NAME)
  FROM
    INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu JOIN
    INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc ON ccu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME JOIN
    INFORMATION_SCHEMA.COLUMNS c ON
      ccu.COLUMN_NAME = c.COLUMN_NAME   AND
      ccu.TABLE_NAME = c.TABLE_NAME     AND
      ccu.TABLE_SCHEMA = c.TABLE_SCHEMA
  WHERE
    tc.CONSTRAINT_TYPE = 'PRIMARY KEY' AND
    tc.TABLE_NAME = @Таблица AND
    ccu.TABLE_SCHEMA = @Схема

  IF (@count > 1)
  BEGIN
    SET @msg = @msg + N'Аудит таблиц с составным первичным ключом не поддерживается'
    RAISERROR(@msg, 16, 1)
    RETURN
  END

  IF (@count = 0)
  BEGIN
    SET @msg = @msg + N'У таблицы отсутствует первичный ключ'
    RAISERROR(@msg, 16, 1)
    RETURN
  END

  SELECT @PKColName = ccu.COLUMN_NAME, @PkDataType = c.DATA_TYPE
  FROM
    INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu JOIN
    INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc ON ccu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME JOIN
    INFORMATION_SCHEMA.COLUMNS c ON ccu.COLUMN_NAME = c.COLUMN_NAME AND ccu.TABLE_NAME = c.TABLE_NAME
  WHERE
    tc.CONSTRAINT_TYPE = 'PRIMARY KEY' AND
    tc.TABLE_NAME = @Таблица AND
    ccu.TABLE_SCHEMA = @Схема

  IF (@PkDataType != 'uniqueidentifier')
  BEGIN
    SET @msg = @msg + N'Поддерживается только аудит таблиц, имеющих тип первичного ключа uniqueidentifier'
    RAISERROR(@msg, 16, 1)
    RETURN
  END

  -- выбираем имена атрибутов таблицы, для которых возможен аудит
  INSERT INTO @Columns (ColID, ColName, ColType, ColMaxLen)
  SELECT sc.column_id, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
  FROM
    sys.schemas sch JOIN
    sys.tables st ON sch.[schema_id] = st.[schema_id] JOIN
    sys.columns sc ON sc.[object_id] = st.[object_id] JOIN
    INFORMATION_SCHEMA.COLUMNS ic ON
      ic.COLUMN_NAME = sc.name AND
      ic.TABLE_NAME = st.[name] AND
      ic.TABLE_SCHEMA = sch.[name]
  WHERE
    st.[name] = @Таблица AND
    sch.[name] = @Схема AND
    DATA_TYPE NOT IN (N'text', N'ntext', N'image',N'timestamp',N'sql_variant',N'hierarchyid') AND
    NOT (DATA_TYPE = N'varbinary' AND CHARACTER_MAXIMUM_LENGTH = -1) AND -- varbinary(max)
    sc.is_computed = 0 AND -- вычисляемым столбцам не нужен аудит
    COLUMN_NAME <> @PKColName -- первичный ключ не аудируем, так как он не меняется, а его значение есть в [Аудит - операции]

    SET @UpdateTriggerCreateOrAlter = N'CREATE'

    SET @InsertTriggerCreateOrAlter = N'CREATE'

    SET @DeleteTriggerCreateOrAlter = N'CREATE'

  SET @PKColName = REPLACE(@PKColName, '''', '''''')

  --region Формирование текстов триггеров

  --region формируем список атрибутов
  DECLARE ColCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT ColID, ColName, ColType, ColMaxLen
    FROM @Columns

  DECLARE
    @ColID          INT,
    @ColName        SYSNAME,
    @NotEqualClause NVARCHAR(300),
    @ColType        SYSNAME,
    @ColMaxLen      INT,
    @dValueClause   NVARCHAR(500),
    @iValueClause   NVARCHAR(500)

  OPEN ColCursor

  IF @PKColName <> 'ID'
  BEGIN
  SET @ColumnsInsertSelect = '
      i.[' + @PKColName +'] AS [ID],'
  SET @ColumnsDeleteSelect = '
      d.[' + @PKColName +'] AS [ID],'
  END
  ELSE
  BEGIN
  SET @ColumnsInsertSelect = '
      i.[ID],'
  SET @ColumnsDeleteSelect = '
      d.[ID],'
  END

  FETCH NEXT FROM ColCursor INTO @ColID, @ColName, @ColType, @ColMaxLen
  WHILE @@FETCH_STATUS = 0
  BEGIN

    SET @ColumnsInsertSelect = @ColumnsInsertSelect + '
      i.[' + @ColName + '] AS [id' + CAST(@ColID AS VARCHAR(20)) + '],'
    SET @ColumnsDeleteSelect = @ColumnsDeleteSelect + '
      d.[' + @ColName + '] AS [id' + CAST(@ColID AS VARCHAR(20)) + '],'

    FETCH NEXT FROM ColCursor INTO @ColID, @ColName, @ColType, @ColMaxLen
  END

  SET @ColumnsInsertSelect = substring(@ColumnsInsertSelect, 1, len(@ColumnsInsertSelect) - 1)
  SET @ColumnsDeleteSelect = substring(@ColumnsDeleteSelect, 1, len(@ColumnsDeleteSelect) - 1)
  --endregion

  --region Общая часть тригерров
  DECLARE
    @Header VARCHAR(max),
    @Footer VARCHAR(max),
    @InsertedPart VARCHAR(max),
    @DeletedPart VARCHAR(max)

  SET @Header =
'
  SET NOCOUNT ON

  DECLARE
    @convHandler UNIQUEIDENTIFIER,
    @inserted    XML,
    @deleted     XML,
    @Type        VARCHAR(1),
    @xml         XML
'
  SET @InsertedPart =
'
  SET @inserted =
  (
    SELECT ' +  @ColumnsInsertSelect + '
    FROM inserted i
    FOR XML RAW(''Row''), ROOT(''Inserted''), ELEMENTS XSINIL, TYPE
  )
'
  SET @DeletedPart =
'
  SET @deleted =
  (
    SELECT ' +  @ColumnsDeleteSelect + '
    FROM deleted d
    FOR XML RAW(''Row''), ROOT(''Deleted''), ELEMENTS XSINIL, TYPE
  )
'
  SET @Footer =
'
  SET @xml =
    ''<Root Table="' + @Таблица +
    '" Schema="' + @Схема +
    '" Type="'' + @Type + ''" PK="' + @PKColName +
    '" DateTime="'' + CONVERT(varchar(100), getdate(), 104) + '' '' + CONVERT(varchar(100), getdate(), 114) + ''" User="'' + SUSER_NAME() + ''">''
    + CAST(ISNULL(@inserted, '''') AS NVARCHAR(max))
    + CAST(ISNULL(@deleted, '''') AS NVARCHAR(max))
    + ''</Root>''

  BEGIN DIALOG @convHandler
    FROM SERVICE    [EAMAuditDmlSourceService]
    TO SERVICE      ''EAMAuditDmlTargetService''
    ON CONTRACT     [EAMAuditDmlContract]
    WITH ENCRYPTION = OFF;

  SEND ON CONVERSATION @convHandler
    MESSAGE TYPE [EAMAuditDmlMesssageType] (@xml)

  END CONVERSATION @convHandler

--  END
END
'
  --endregion

  --region Insert
  SET @InsertTriggerScript =
    N'/********************************************************************************************/
--  Триггер AFTER INSERT на таблицу [' + @Схема + '].[' + @Таблица + N']
--  Дата перерегистрации: ' + CAST(GETDATE() AS NVARCHAR(100)) + N'
--  Сгенерировано процедурой [Аудит_Создать триггеры аудита]
/********************************************************************************************/
' + @InsertTriggerCreateOrAlter + ' TRIGGER [' + @Схема + '].[' + @InsertTriggerName + ']
ON [' + @Схема + '].[' + @Таблица + ']
AFTER INSERT
NOT FOR REPLICATION
AS
BEGIN ' + @Header + '  SET @Type = ''I''
' + @InsertedPart + @Footer
  --endregion

  --region Update
  SET @UpdateTriggerScript =
    N'/********************************************************************************************/
--  Триггер AFTER UPDATE на таблицу [' + @Схема + '].[' + @Таблица + N']
--  Дата перерегистрации: ' + CAST(GETDATE() AS NVARCHAR(100)) + N'
--  Сгенерировано процедурой [Аудит_Создать триггеры аудита]
/********************************************************************************************/
' + @UpdateTriggerCreateOrAlter + ' TRIGGER [' + @Схема + '].[' + @UpdateTriggerName + ']
ON [' + @Схема + '].[' + @Таблица + ']
AFTER UPDATE
NOT FOR REPLICATION
AS
BEGIN ' + @Header + '  SET @Type = ''U''
' + @InsertedPart + @DeletedPart + @Footer
  --endregion

  --region Delete
  SET @DeleteTriggerScript =
    N'/********************************************************************************************/
--  Триггер AFTER DELETE на таблицу [' + @Схема + '].[' + @Таблица + N']
--  Дата перерегистрации: ' + CAST(GETDATE() AS NVARCHAR(100)) + N'
--  Сгенерировано процедурой [Аудит_Создать триггеры аудита]
/********************************************************************************************/
' + @DeleteTriggerCreateOrAlter + ' TRIGGER [' + @Схема + '].[' + @DeleteTriggerName + ']
ON [' + @Схема + '].[' + @Таблица + ']
AFTER DELETE
NOT FOR REPLICATION
AS
BEGIN ' + @Header + '  SET @Type = ''D''
' + @DeletedPart + @Footer
  --endregion
  --endregion

  BEGIN TRY
    IF (OBJECT_ID('[' + @Схема + '].[' + @UpdateTriggerName + ']') IS NOT NULL)
      EXEC(N'DROP TRIGGER [' + @Схема + '].[' + @UpdateTriggerName + N']')

    IF (OBJECT_ID('[' + @Схема + '].[' + @InsertTriggerName + ']') IS NOT NULL)
      EXEC(N'DROP TRIGGER [' + @Схема + '].[' + @InsertTriggerName + N']')

    IF (OBJECT_ID('[' + @Схема + '].[' + @DeleteTriggerName + ']') IS NOT NULL)
      EXEC(N'DROP TRIGGER [' + @Схема + '].[' + @DeleteTriggerName + N']')

    IF @Исключить_из_конфигурации = 0
    BEGIN
      --DEBUG вывод текстов триггеров
      --SELECT @UpdateTriggerScript
      --SELECT @InsertTriggerScript
      --SELECT @DeleteTriggerScript
      EXEC (@UpdateTriggerScript)
      EXEC (@InsertTriggerScript)
      EXEC (@DeleteTriggerScript)
    END

  END TRY
  BEGIN CATCH
    SET @msg = @msg + ' ошибка при создании триггеров аудита.
    ' + ERROR_MESSAGE()

    RAISERROR(@msg, 16, 1)
    RETURN
  END CATCH

  IF @Исключить_из_конфигурации = 0
  BEGIN
    IF NOT EXISTS(
      SELECT 1 FROM [audit].[Аудит - таблицы]
      WHERE [Название] = @Таблица AND [Схема] = @Схема
    )
    BEGIN
      INSERT INTO [audit].[Аудит - таблицы](
        [ID], [Схема], [Название]
      )
      VALUES(
        NewID(), @Схема, @Таблица
      )
    END
  END
  ELSE
  BEGIN
    DELETE FROM [audit].[Аудит - таблицы]
    WHERE
      [Название] = @Таблица AND
      [Схема] = @Схема
  END

  SET @InfoMsg = @msg + N' успешно завершена'

  PRINT @InfoMsg
END
