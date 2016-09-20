CREATE TABLE [config].[Метаданные справочников]
(
  [ID]                               UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL,
  [Схема]                            SYSNAME  NOT NULL DEFAULT 'ref', -- Название схемы без скобок и кавычек
  [Таблица]                          SYSNAME  NOT NULL, -- Название таблицы без схемы, скобок и кавычек
  [Поле названия]                    SYSNAME  NOT NULL,
  [Длительность редактирования, сут] SMALLINT NOT NULL DEFAULT 10000,

  CONSTRAINT [PK_Метаданные справочников]
    PRIMARY KEY CLUSTERED ([ID]),

  CONSTRAINT [AK_Метаданные справочников - схема и таблица]
    UNIQUE ([Схема], [Таблица])
)
GO

--Е.Мирошниченко
--Триггер проверят корректность имён таблиц и полей-названий
CREATE TRIGGER [config].[Метаданные справочников INSERT] 
ON [config].[Метаданные справочников]
INSTEAD OF INSERT
NOT FOR REPLICATION
AS
BEGIN
  IF EXISTS (
    SELECT 1 FROM inserted i
    WHERE Object_ID('['+i.[Схема]+'].['+i.[Таблица]+']') IS NULL
    )
    RAISERROR( 'Таблица с таким именем не существует', 16, 1)
  ELSE
    IF EXISTS (
      SELECT 1 FROM
        inserted i
        LEFT JOIN
        INFORMATION_SCHEMA.COLUMNS ISC
          ON ISC.TABLE_SCHEMA = i.[Схема] AND
             ISC.TABLE_NAME   = i.[Таблица] AND
             ISC.COLUMN_NAME  = i.[Поле названия]
      WHERE
        i.[Поле названия] IS NOT NULL AND
        ISC.COLUMN_NAME IS NULL
      )
      RAISERROR( 'Такое поле-название в таблице не существует', 16, 1)
    ELSE
      INSERT INTO [config].[Метаданные справочников] (
        [ID],
        [Схема],
        [Таблица],
        [Поле названия],
        [Длительность редактирования, сут]
      )
      SELECT
        i.[ID],
        i.[Схема],
        i.[Таблица],
        i.[Поле названия],
        i.[Длительность редактирования, сут]
      FROM
        inserted i
END
