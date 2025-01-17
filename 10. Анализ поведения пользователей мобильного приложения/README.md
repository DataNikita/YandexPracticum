# Анализ поведения пользователей мобильного приложения
Сборный проект №2 

## Описание проекта
### Задача
Нужно разобраться, как ведут себя пользователи мобильного приложения. Необходимо проанализировать воронку продаж, оценить результаты A/A/B-тестирования (изменение шрифта в приложении).

## Данные
Предоставлен лог, в котором каждая запись — это действие пользователя, или событие. 
* Название события;
* Уникальный идентификатор пользователя;
* Время события;
* Номер эксперимента: 246 и 247 — контрольные группы, а 248 — экспериментальная.

## Навыки и инструменты
*python*, *pandas*, *numpy*, *seaborn*, *matplotlib*, *math*, *scipy*, *plotly*, *событийная аналитика*,  
*продуктовые метрики*, *проверка статистических гипотез*, *визуализация данных*

##  Вывод
Был проведен анализ и предобработка данных. После чего была изучена и визуализирована воронка продаж. 
Проанализированы результаты A/B-теста. Проведено сравнение 2 контрольных групп между собой. По результатам сравнения убедились в правильном разделении трафика, а затем было проведено сравнение с тестовой группой. Выявлено, что новый шрифт значительно не повлияет на поведение пользователей.
