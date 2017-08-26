#Использовать json

Перем ТекущийКаталогПроекта;
Перем Лог;
Перем СоответствиеПеременныхСреды;
Перем ПутьФайлаНастроекПоУмолчанию;

#Область ПрограммныйИнтерфейс

Процедура ПриСозданииОбъекта(Знач НовыйПутьФайлаНастроек = "")
	Если Не ЗначениеЗаполнено(НовыйПутьФайлаНастроек) Тогда
		ПутьФайла = ОбъединитьПути(ТекущийКаталог(), ЧтениеПараметров.ИмяФайлаНастроекПоУмолчанию());
		ФайлПоУмолчанию = Новый Файл(ПутьФайла);
		Если ФайлПоУмолчанию.Существует() Тогда
			НовыйПутьФайлаНастроек = ФайлПоУмолчанию;
		КонецЕсли;
	КонецЕсли;
	
	Если ЗначениеЗаполнено(НовыйПутьФайлаНастроек) Тогда
		УстановитьФайлПоУмолчанию(НовыйПутьФайлаНастроек);
	КонецЕсли;
КонецПроцедуры

// Выполнить основной анализ и получить финальные параметры с учетом командной строки, переменных среды, файлов настроек
//
// Параметры:
//   Парсер - <ПарсерАргументовКоманднойСтроки> - ранее инициализированный парсер со всеми настройками командной строки
//   Аргументы - <Массив>, необязательный - набор аргументов командной строки, 
//		Если не указан, используется штатная коллекция АргументыКоманднойСтроки
//   КлючФайлаНастроек - <Строка>, необязательный - именованный параметр командной строки, 
//		который указывает на json-файл настройки 
//		Если не указан, используется ключ "--settings"
//   ПрефиксПеременныхСреды - <Строка>, необязательный - 
//		Если не указан, используется ключ "ONESCRIPT_APP_"
//
//  Возвращаемое значение:
//   <Соответствие> - итоговые параметры
//
Функция Прочитать(Парсер, Знач Аргументы = Неопределено, Знач КлючФайлаНастроек = "", Знач ПрефиксПеременныхСреды = "") Экспорт
	Параметры = Неопределено;

	Попытка
		
		Если Аргументы = Неопределено Тогда
			Аргументы = АргументыКоманднойСтроки;
		КонецЕсли;
		Если ПрефиксПеременныхСреды = "" Тогда
			ПрефиксПеременныхСреды = ЧтениеПараметров.ПрефиксПеременныхОкружения();
		КонецЕсли;
		Лог.Отладка("Использую префикс переменных окружения %1", ПрефиксПеременныхСреды);

		ТаблицаКоманд = Парсер.СправкаВозможныеКоманды();
		Если ТаблицаКоманд.Количество() = 0 Тогда
			ТаблицаКоманд = Парсер.СправкаПоПараметрам();		
		КонецЕсли;

		НовоеСоответствиеПеременныхСреды = ПолучитьСоответствиеПеременныхСредыИзТаблицыКоманд(ТаблицаКоманд, ПрефиксПеременныхСреды);
		Если Не ЗначениеЗаполнено(СоответствиеПеременныхСреды) Тогда
			СоответствиеПеременныхСреды = НовоеСоответствиеПеременныхСреды;
		Иначе
			ДополнитьСоответствиеСУчетомПриоритета(СоответствиеПеременныхСреды, НовоеСоответствиеПеременныхСреды);

			Лог.Отладка("Коллекция переменных среды с соответствующими ключами-параметрами:");
			ПоказатьПараметрыВРежимеОтладки(СоответствиеПеременныхСреды);
		КонецЕсли;

		Параметры = Парсер.Разобрать(Аргументы);

		Если ТипЗнч(Параметры) = Тип("Структура") и Параметры.Свойство("Команда") Тогда
			Команда = Параметры.Команда;
			Параметры = Параметры.ЗначенияПараметров;
			Лог.Отладка("Параметры команды %1 из командной строки, полученные от парсера cmdline:", Команда);
		Иначе
			Лог.Отладка("Параметры командной строки, полученные от парсера cmdline:");
		КонецЕсли;

		ПоказатьПараметрыВРежимеОтладки(Параметры);
		
		Если КлючФайлаНастроек = "" Тогда
			КлючФайлаНастроек = ЧтениеПараметров.КлючФайлаНастроек();
		КонецЕсли;
		Лог.Отладка("КлючФайлаНастроек <%1>", КлючФайлаНастроек);

		Если Не ЗначениеЗаполнено(ТекущийКаталогПроекта) Тогда
			ТекущийКаталогПроекта = ТекущийКаталог();
		КонецЕсли;
		Лог.Отладка("ТекущийКаталогПроекта <%1>", ТекущийКаталогПроекта);
		
		ДополнитьЗначенияПараметров(Параметры, Команда, КлючФайлаНастроек, СоответствиеПеременныхСреды);

		Параметры.Вставить("Команда", Команда);
		
		Лог.Отладка("Итоговые параметры:");
		ПоказатьПараметрыВРежимеОтладки(Параметры);
	Исключение
		Лог.Ошибка("Ошибка чтения настроек
		|%1", ОписаниеОшибки());

		ВызватьИсключение;
	КонецПопытки;

	Возврат Параметры;
КонецФункции // Прочитать

// Установить текущий каталог проекта-клиента
//
// Параметры:
//   ПарамТекущийКаталогПроекта - <Строка> - путь каталога
//
Процедура УстановитьТекущийКаталогПроекта(Знач ПарамТекущийКаталогПроекта) Экспорт
	ТекущийКаталогПроекта = ПарамТекущийКаталогПроекта;
КонецПроцедуры

// Получить текущий каталог проекта-клиента
//
//  Возвращаемое значение:
//   <Строка> - путь каталога
//
Функция ПолучитьТекущийКаталогПроекта() Экспорт
	Возврат ТекущийКаталогПроекта;
КонецФункции // ПолучитьТекущийКаталогПроекта()

// Установить путь к файлу настроек по умолчанию
//
// Параметры:
//   НовыйПутьФайлаНастроек - <Строка> - путь файла
//
Процедура УстановитьФайлПоУмолчанию(Знач НовыйПутьФайлаНастроек) Экспорт
	Файл = Новый Файл(НовыйПутьФайлаНастроек);
	СообщениеОшибки = СтрШаблон("Файл настроек не существует. Путь %1", НовыйПутьФайлаНастроек);
	Ожидаем.Что(Файл.Существует(), СообщениеОшибки).ЭтоИстина();

	ПутьФайлаНастроекПоУмолчанию = НовыйПутьФайлаНастроек;
КонецПроцедуры

// Загрузить соответствие переменных окружения параметрам команд
//
// Параметры:
//   Источник - <Соответствие или ФиксированноеСоответствие> - откуда загружаем
//		ключ - имя переменной окружения
//		значение - имя соответствующего ключа/параметра настройки
//
Процедура ЗагрузитьСоответствиеПеременныхОкруженияПараметрамКоманд(Источник) Экспорт
	ТипИсточника = ТипЗнч(Источник);
	Если ТипИсточника <> Тип("Соответствие") И ТипИсточника <> Тип("ФиксированноеСоответствие") Тогда
		ВызватьИсключение "Неверный тип источника у метода ЗагрузитьСоответствиеПеременныхОкруженияПараметрамКоманд";
	КонецЕсли;
	СоответствиеПеременныхСреды = Новый Соответствие;
	Для каждого КлючЗначение Из Источник Цикл
		СоответствиеПеременныхСреды.Вставить(КлючЗначение.Ключ, КлючЗначение.Значение);
	КонецЦикла;
КонецПроцедуры

#КонецОбласти

Функция ПолучитьСоответствиеПеременныхСредыИзТаблицыКоманд(Знач ТаблицаКоманд, Знач ПрефиксПеременныхСреды)
	Рез = Новый Соответствие;
	ЕстьВложеннаяТаблицаПараметров = ТаблицаКоманд.Колонки.Найти("Параметры") <> Неопределено;
	Если ЕстьВложеннаяТаблицаПараметров Тогда
		Для каждого Строка Из ТаблицаКоманд Цикл
			ДобавитьПараметрВКоллекциюСоответствияПеременныхОкружения(Рез, Строка.Параметры, ПрефиксПеременныхСреды);
		КонецЦикла;
	Иначе
		ДобавитьПараметрВКоллекциюСоответствияПеременныхОкружения(Рез, ТаблицаКоманд, ПрефиксПеременныхСреды);
	КонецЕсли;

	Лог.Отладка("Соответствие параметров команд и переменных среды:");
	ПоказатьПараметрыВРежимеОтладки(Рез);

	Возврат Рез;
КонецФункции // ПолучитьСоответствиеПеременныхСредыИзТаблицыКоманд

Процедура ДобавитьПараметрВКоллекциюСоответствияПеременныхОкружения(РезСоответствие, Параметры, ПрефиксПеременныхСреды)
	Для каждого Параметр Из Параметры Цикл
		ИмяПараметра = Параметр.Имя;
		ИмяПеременнойСреды = СтрШаблон("%1%2", 
			ПрефиксПеременныхСреды, ПреобразоватьВИмяПеременнойСреды(ИмяПараметра));
			РезСоответствие.Вставить(ИмяПеременнойСреды, ИмяПараметра);
	КонецЦикла;
КонецПроцедуры

Функция ПреобразоватьВИмяПеременнойСреды(Знач ИмяПараметра)
	Рез = ИмяПараметра;
	Рез = СтрЗаменить(Рез, "-", "_");
	Рез = СтрЗаменить(Рез, " ", "_");
	Возврат Рез;
КонецФункции // ПреобразоватьВИмяПеременнойСреды

Процедура ДополнитьЗначенияПараметров(Знач ЗначенияПараметров, Знач Команда, Знач КлючФайлаНастроек, 
		СоответствиеПеременныхСреды)
	
	Если Не ЗначениеЗаполнено(Команда) Тогда
		Команда = ЧтениеПараметров.КлючКомандыВФайлеНастроекПоУмолчанию();
	КонецЕсли;
	// ТекущийКаталогПроекта = УстановитьКаталогТекущегоПроекта(ЗначенияПараметров["--root"]);

	// ПараметрыСистемы.КорневойПутьПроекта = ТекущийКаталогПроекта;

	// ПутьКФайлуНастроекПоУмолчанию = ОбъединитьПути(ТекущийКаталогПроекта, ОбщиеМетоды.ИмяФайлаНастроек());

	// НастройкиИзФайла = ОбщиеМетоды.ПрочитатьНастройкиФайлJSON(ТекущийКаталогПроекта, 
	// 		ЗначенияПараметров[КлючФайлаНастроек], ПутьКФайлуНастроекПоУмолчанию);
	ПутьКФайлуНастройки = ЗначенияПараметров.Получить(КлючФайлаНастроек);
	Если Не ЗначениеЗаполнено(ПутьКФайлуНастройки) Тогда
		Лог.Отладка("В параметрах не задан ключ %1 к файлу настройки", КлючФайлаНастроек);
	КонецЕсли;
	НастройкиИзФайла = ПрочитатьНастройкиФайлJSON(ТекущийКаталогПроекта, ПутьКФайлуНастройки, ПутьФайлаНастроекПоУмолчанию);
		
	ЗначенияПараметровНизкийПриоритет = Новый Соответствие;

	Если НастройкиИзФайла.Количество() > 0 Тогда 
		ДополнитьАргументыИзФайлаНастроек(Команда, ЗначенияПараметровНизкийПриоритет, НастройкиИзФайла);
	КонецЕсли;
	
	ЗаполнитьЗначенияИзПеременныхОкружения(ЗначенияПараметровНизкийПриоритет, СоответствиеПеременныхСреды);

	ДополнитьСоответствиеСУчетомПриоритета(ЗначенияПараметров, ЗначенияПараметровНизкийПриоритет);

	// // на случай переопределения этой настройки повторная установка
	// УстановитьКаталогТекущегоПроекта(ЗначенияПараметров["--root"]);

	// ДобавитьДанныеПодключения(ЗначенияПараметров);
КонецПроцедуры

// Функция ПрочитатьНастройкиФайлJSON(Знач ТекущийКаталогПроекта, Знач ПутьКФайлу, Знач ПутьФайлаПоУмолчанию )
Функция ПрочитатьНастройкиФайлJSON(Знач ТекущийКаталогПроекта, Знач ПутьКФайлу, Знач ПутьФайлаПоУмолчанию )
	Рез = Новый Соответствие;

	// Лог.Отладка(":"+ПутьКФайлу+":"+ПутьФайлаПоУмолчанию);
	Если ПутьКФайлу = Неопределено ИЛИ НЕ ЗначениеЗаполнено(ПутьКФайлу) Тогда 
		ПутьКФайлу = ПутьФайлаПоУмолчанию;
		Лог.Отладка("Использую путь к файлу настройки по умолчанию %1", ПутьКФайлу);
	Иначе
		Лог.Отладка("Передан путь к файлу настройки %1", ПутьКФайлу);
	КонецЕсли;
	Если НЕ ЗначениеЗаполнено(ПутьКФайлу) Тогда 
		Лог.Отладка("Передана пустая строка в качестве пути к файлу настройки");
		Возврат Рез;
	КонецЕсли;
	Ожидаем.Что(ПутьКФайлу, "Путь к файлу настроек должен быть заполнен").Не_().Равно("").Не_().Равно(Неопределено);

	ПутьКФайлу = ОбъединитьПути(ТекущийКаталогПроекта, ПутьКФайлу);

	Рез = ПрочитатьФайлJSON(ПутьКФайлу);
	Лог.Отладка("Параметры из файла настроек:");
	ПоказатьПараметрыВРежимеОтладки(Рез);
	Возврат Рез;
КонецФункции

Функция ПрочитатьФайлJSON(Знач ИмяФайла)
	Лог.Отладка("Путь файла настроек <%1>", ИмяФайла);

	ФайлСуществующий = Новый Файл(ИмяФайла);
	Если Не ФайлСуществующий.Существует() Тогда
		ВызватьИсключение СтрШаблон("Файл настроек не существует. Путь <%1>", ИмяФайла);
		Возврат Новый Соответствие;
	КонецЕсли;
	Чтение = Новый ЧтениеТекста(ИмяФайла, КодировкаТекста.UTF8);
	JsonСтрока  = Чтение.Прочитать();
	Чтение.Закрыть();
	Лог.Отладка("Текст файла настроек:");
	Лог.Отладка(JsonСтрока);

	ПарсерJSON  = Новый ПарсерJSON();
	Результат   = ПарсерJSON.ПрочитатьJSON(JsonСтрока);

	Возврат Результат;
КонецФункции

Процедура ДополнитьАргументыИзФайлаНастроек(Знач Команда, ЗначенияПараметров, Знач НастройкиИзФайла)
	Перем КлючПоУмолчанию, Настройки;
	КлючПоУмолчанию = ЧтениеПараметров.КлючКомандыВФайлеНастроекПоУмолчанию();

	ДополнитьСоответствиеСУчетомПриоритета(ЗначенияПараметров, НастройкиИзФайла.Получить(Команда));
	
	НастройкиПоУмолчанию = НастройкиИзФайла.Получить(КлючПоУмолчанию);
	Если НастройкиПоУмолчанию = Неопределено Тогда
		ДополнитьСоответствиеСУчетомПриоритета(ЗначенияПараметров, НастройкиИзФайла);
	Иначе
		ДополнитьСоответствиеСУчетомПриоритета(ЗначенияПараметров, НастройкиПоУмолчанию);
	КонецЕсли;

	Лог.Отладка("Параметры после вставки из файла настроек:");
	ПоказатьПараметрыВРежимеОтладки(ЗначенияПараметров);

КонецПроцедуры //ДополнитьАргументыИзФайлаНастроек

Процедура ДополнитьСоответствиеСУчетомПриоритета(КоллекцияОсновная, Знач КоллекцияДоп)
	Если КоллекцияДоп = Неопределено Тогда 
		Возврат;
	КонецЕсли;

	Для Каждого Элемент из КоллекцияДоп Цикл 
		Значение = КоллекцияОсновная.Получить(Элемент.Ключ);
		Если Значение = Неопределено Тогда 
			КоллекцияОсновная.Вставить(Элемент.Ключ, Элемент.Значение);
		КонецЕсли;
	КонецЦикла;
КонецПроцедуры //ДополнитьСоответствиеСУчетомПриоритета

Процедура ЗаполнитьЗначенияИзПеременныхОкружения(ЗначенияПараметров, Знач СоответствиеПеременных) Экспорт

	Для каждого Элемент Из СоответствиеПеременных Цикл
		ЗначениеПеременной = ПолучитьПеременнуюСреды(ВРег(Элемент.Ключ));
		Лог.Отладка("В переменных среды найден параметр: <%1> = <%2>, тип %3", Элемент.Ключ, ЗначениеПеременной, ТипЗнч(ЗначениеПеременной));
		Если ЗначениеПеременной <> Неопределено Тогда
			Если ЗначениеПеременной = """""" Или ЗначениеПеременной = "''" Тогда
				ЗначениеПеременной = "";
			КонецЕсли;
			ЗначенияПараметров.Вставить(Элемент.Значение, ЗначениеПеременной);

			Лог.Отладка("Из переменных среды получен параметр: <%1> = <%2>", Элемент.Значение, ЗначениеПеременной);
		КонецЕсли;
	КонецЦикла;

КонецПроцедуры

Процедура ПоказатьПараметрыВРежимеОтладки(ЗначенияПараметров, Знач Родитель = "")
	Если Родитель = "" Тогда
		Лог.Отладка("	Тип параметров %1", ТипЗнч(ЗначенияПараметров));
	КонецЕсли;
	Если ЗначенияПараметров.Количество() = 0 Тогда
		Лог.Отладка("	Коллекция параметров пуста!");
	КонецЕсли;
	Для каждого Элемент из ЗначенияПараметров Цикл 
		ПредставлениеКлюча = Элемент.Ключ;
		Если Не ПустаяСтрока(Родитель) Тогда
			ПредставлениеКлюча  = СтрШаблон("%1.%2", Родитель, ПредставлениеКлюча);
		КонецЕсли;
		Лог.Отладка("	Получен параметр <%1> = <%2>", ПредставлениеКлюча, Элемент.Значение);
		Если ТипЗнч(Элемент.Значение) = Тип("Соответствие") Тогда
			ПоказатьПараметрыВРежимеОтладки(Элемент.Значение, ПредставлениеКлюча);
		КонецЕсли;
	КонецЦикла;
КонецПроцедуры

Лог = ПараметрыСистемы.ПолучитьЛог();
