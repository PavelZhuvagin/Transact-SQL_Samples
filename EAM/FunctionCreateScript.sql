CREATE FUNCTION [pub].[Скрипты объединения записей справочников]
(
  @REF_TABLE_NAME VARCHAR(500),
  @OLD_ID UNIQUEIDENTIFIER,
  @NEW_ID UNIQUEIDENTIFIER
)
RETURNS @Result TABLE
(
  [QUERY] VARCHAR(MAX)
)
AS
BEGIN

  DECLARE
    @ref_id INT

  SELECT 
    @ref_id = [object_id]
  FROM 
    sys.objects 
  WHERE 
    [name] like '%' + @REF_TABLE_NAME +'%' AND --variable
    [type] = 'U'
    
    
  INSERT INTO @Result
  SELECT  
    'UPDATE [' + [S].[name] + '].[' + [T].[name] + '] SET' + char(13) +
    '  [' + [C].[name] + '] = ''' + CAST(@NEW_ID AS VARCHAR(36)) + '''' + char(13) + 
    'WHERE' + char(13) + 
    '  [' + [C].[name] + '] = ''' + CAST(@OLD_ID AS VARCHAR(36)) + ''''
  FROM 
    sys.foreign_key_columns [FKC]
    JOIN
    sys.tables [T]
      ON [T].[object_id] = [FKC].[parent_object_id]
    JOIN
    sys.schemas [S]
      ON [T].[schema_id] = [S].[schema_id]
    JOIN
    sys.columns [C]
      ON  ( [C].[column_id] = [FKC].[parent_column_id] AND 
            [C].[object_id] = [FKC].[parent_object_id])
  WHERE 
    [referenced_object_id] = @ref_id
  
  RETURN
   
END
GO
