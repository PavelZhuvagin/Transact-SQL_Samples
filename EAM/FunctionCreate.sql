CREATE FUNCTION [config].[Допустимые значения поля]
(
  @@Схема   NVARCHAR(100),
  @@Таблица NVARCHAR(100),
  @@Поле    NVARCHAR(100)
)
RETURNS @Result TABLE
(
  [Значение] NVARCHAR(100) NOT NULL
)
BEGIN
  DECLARE
    @Список NVARCHAR(1000),
    @xml    XML

  SELECT
    @Список = cc.[definition]
  FROM
    sys.columns col
    JOIN
    sys.tables tbl ON col.[object_id] = tbl.[object_id]
    JOIN
    sys.schemas sch ON tbl.[schema_id] = sch.[schema_id]
    JOIN
    sys.check_constraints cc
      ON cc.parent_object_id = tbl.[object_id] AND
         cc.parent_column_id = col.[column_id]
  WHERE
    sch.[name] = @@Схема AND
    tbl.[name] = @@Таблица AND
    col.[name] = @@Поле

  IF @Список IS NULL
    RETURN

  IF @Список LIKE '(%)'
    SET @Список = SUBSTRING( @Список, 2, LEN(@Список) - 2 )

  --Далее обработка для check-constraint, содержащего список допустимых значений
  --это устанавливает по отсутствию знаков < и > и оператора AND
  IF
    CHARINDEX('<',    @Список) > 0 OR
    CHARINDEX('>',    @Список) > 0 OR
    CHARINDEX(' AND', @Список) > 0
    RETURN

  SET @Список = REPLACE( @Список, '''', '' )
  SET @Список = REPLACE( @Список, '['+@@Поле+']=', '<r v=''' )
  SET @Список = REPLACE( @Список, ' OR ', '''/> ' )

  --Формируется XML-строка вида <Root><r v="Газлифт" /><r v="ШГН" /><r v="ЭВН" /><r v="ЭЦН" /><r v="Фонтан" /></Root>
  SET @Список = '<Root> '+@Список + '''/> </Root>'
  SET @Список = REPLACE( @Список, '''(', '''' )
  SET @Список = REPLACE( @Список, ')''', '''' )

  SET @xml = @Список

  INSERT INTO @Result
  SELECT
    X.t.value('(@v)[1]', 'NVARCHAR(100)')
  FROM @Xml.nodes('/Root/r') AS X(t)

  RETURN
END
GO
