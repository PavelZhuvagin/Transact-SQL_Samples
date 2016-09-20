--
--[Метаданные полей]
--
ALTER TABLE [config].[Метаданные полей] ADD
  CONSTRAINT [FK_Метаданные полей - ID_Подвида ПФ]
    FOREIGN KEY ([ID_Подвида ПФ])
    REFERENCES [assets].[Подвиды ПФ]([ID])

--
--[Исполнители и ответственные]
--
ALTER TABLE [objects].[Исполнители и ответственные] ADD
  CONSTRAINT [FK_Исполнители и ответственные - ID_Работы по плану]
    FOREIGN KEY ([ID_Работы по плану])
    REFERENCES [tasks].[Работы - план],

  CONSTRAINT [FK_Исполнители и ответственные - ID_Работы по факту]
    FOREIGN KEY ([ID_Работы по факту])
    REFERENCES [tasks].[Работы - факт],

  CONSTRAINT [FK_Исполнители и ответственные - ID_Подразделения]
    FOREIGN KEY ([ID_Подразделения])
    REFERENCES [objects].[Подразделения],

  CONSTRAINT [FK_Исполнители и ответственные - ID_Журнала работ]
    FOREIGN KEY ([ID_Журнала работ])
    REFERENCES [log].[Журналы работ],

  CONSTRAINT [FK_Исполнители и ответственные - ID_Графика]
    FOREIGN KEY ([ID_Графика])
    REFERENCES [tasks].[Графики]

--
--[Производственные фонды]
--
ALTER TABLE [assets].[Производственные фонды] ADD
  CONSTRAINT [FK_Производственные фонды - Подвиды ПФ]
    FOREIGN KEY ([ID_Подвида ПФ])
    REFERENCES [assets].[Подвиды ПФ]([ID]),

  CONSTRAINT [FK_Производственные фонды - Номенклатуры]
    FOREIGN KEY ([ID_Номенклатуры])
    REFERENCES [assets].[Номенклатуры]([ID]),

  CONSTRAINT [FK_Производственные фонды - Справочник моделей ПФ]
    FOREIGN KEY ([ID_Модели ПФ])
    REFERENCES [ref].[Справочник моделей ПФ]([ID]),

  CONSTRAINT [FK_Производственные фонды - Справочник изготовителей]
    FOREIGN KEY ([ID_Изготовителя])
    REFERENCES [ref].[Справочник изготовителей]([ID])

--
--[Нормативы работ для ПФ]
--
ALTER TABLE [objects].[Нормативы работ для ПФ] ADD
  CONSTRAINT [FK_Нормативы работ для ПФ - ID_Норматива работ]
    FOREIGN KEY ([ID_Норматива работ])
    REFERENCES [tasks].[Нормативы работ]([ID])

--
--[Нормативы работ - параметры ввода в действие]
--
ALTER TABLE [objects].[Нормативы работ - параметры ввода в действие] ADD
  CONSTRAINT [FK_Нормативы работ - параметры ввода в действие - ID_Работы в РЦ]
    FOREIGN KEY ([ID_Работы в РЦ])
    REFERENCES [tasks].[Работы в ремонтном цикле]([ID]),

  CONSTRAINT [FK_Нормативы работ - параметры ввода в действие - ID_Следующей работы в РЦ]
    FOREIGN KEY ([ID_Следующей работы в РЦ])
    REFERENCES [tasks].[Работы в ремонтном цикле]([ID])

--
--[Работы - план]
--
ALTER TABLE [tasks].[Работы - план] ADD
  CONSTRAINT [FK_Работы - план - ID_Нормативной работы]
    FOREIGN KEY ([ID_Нормативной работы])
    REFERENCES [tasks].[Нормативные работы],

  CONSTRAINT [FK_Работы - план - ID_Работы в РЦ]
    FOREIGN KEY ([ID_Работы в РЦ])
    REFERENCES [tasks].[Работы в ремонтном цикле],

  CONSTRAINT [FK_Работы - план - ID_Спецификации МТР]
    FOREIGN KEY ([ID_Спецификации МТР])
    REFERENCES [tasks].[Спецификации МТР],

  CONSTRAINT [FK_Работы - план - ID_Спецификации услуг]
    FOREIGN KEY ([ID_Спецификации услуг])
    REFERENCES [tasks].[Спецификации услуг]
--
--[Работы - факт]
--
ALTER TABLE [tasks].[Работы - факт] ADD
  CONSTRAINT [FK_Работы - факт - ID_Нормативной работы]
    FOREIGN KEY ([ID_Нормативной работы])
    REFERENCES [tasks].[Нормативные работы],

  CONSTRAINT [FK_Работы - факт - ID_Работы по плану]
    FOREIGN KEY ([ID_Работы по плану])
    REFERENCES [tasks].[Работы - план],

  CONSTRAINT [FK_Работы - факт - ID_Работы в РЦ]
    FOREIGN KEY ([ID_Работы в РЦ])
    REFERENCES [tasks].[Работы в ремонтном цикле],

  CONSTRAINT [FK_Работы - факт - ID_Спецификации МТР]
    FOREIGN KEY ([ID_Спецификации МТР])
    REFERENCES [tasks].[Спецификации МТР],

  CONSTRAINT [FK_Работы - факт - ID_Спецификации услуг]
    FOREIGN KEY ([ID_Спецификации услуг])
    REFERENCES [tasks].[Спецификации услуг]

--
--[Справочник типов работ]
--
ALTER TABLE [ref].[Справочник типов работ] ADD
  CONSTRAINT [FK_Справочник типов работ - ID_ГХ-сателлита план]
    FOREIGN KEY ([ID_ГХ-детализации плана])
    REFERENCES [config].[Группы характеристик],

  CONSTRAINT [FK_Справочник типов работ - ID_ГХ-сателлита факт]
    FOREIGN KEY ([ID_ГХ-детализации факта])
    REFERENCES [config].[Группы характеристик]

--
--[Записи журнала перемещений]
--
ALTER TABLE [log].[Записи журнала перемещений]  ADD
  CONSTRAINT [FK_Записи журнала перемещений - ID_МУ-источника]
    FOREIGN KEY ([ID_МУ-источника])
    REFERENCES [assets].[Места установки оборудования]([ID]),

  CONSTRAINT [FK_Записи журнала перемещений - ID_МУ-приёмника]
    FOREIGN KEY ([ID_МУ-приёмника])
    REFERENCES [assets].[Места установки оборудования]([ID])
