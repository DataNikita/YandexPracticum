/* Задание 1. Отобразите все записи из таблицы company по компаниям, которые закрылись. */

SELECT *
FROM company
WHERE status = 'closed';

/* Задание 2. Отобразите количество привлечённых средств для новостных компаний США.
	      Используйте данные из таблицы company. Отсортируйте таблицу по убыванию значений в поле funding_total. */

SELECT funding_total
FROM company
WHERE category_code = 'news' AND country_code = 'USA'
ORDER BY funding_total DESC;

/* Задание 3. Найдите общую сумму сделок по покупке одних компаний другими в долларах.
	      Отберите сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно. */

SELECT SUM(price_amount)
FROM acquisition
WHERE (EXTRACT(YEAR FROM CAST(acquired_at AS date)) BETWEEN 2011 AND 2013) AND term_code = 'cash';

/* Задание 4. Отобразите имя, фамилию и названия аккаунтов людей в поле network_username,
 	      у которых названия аккаунтов начинаются на 'Silver'. */

SELECT first_name,
       last_name,
       network_username
FROM people
WHERE network_username LIKE 'Silver%';

/* Задание 5. Выведите на экран всю информацию о людях, у которых названия аккаунтов в поле network_username
 	      содержат подстроку 'money', а фамилия начинается на 'K'. */

SELECT *
FROM people
WHERE (network_username LIKE '%money%') AND (last_name LIKE 'K%');

/* Задание 6. Для каждой страны отобразите общую сумму привлечённых инвестиций, которые получили компании,
	      зарегистрированные в этой стране. Страну, в которой зарегистрирована компания, можно определить по коду страны.
	      Отсортируйте данные по убыванию суммы. */ 

SELECT country_code,
       SUM(funding_total)
FROM company
GROUP BY country_code
ORDER BY SUM(funding_total) DESC;

/* Задание 7. Составьте таблицу, в которую войдёт дата проведения раунда, а также минимальное и максимальное значения 
	      суммы инвестиций, привлечённых в эту дату. Оставьте в итоговой таблице только те записи,
	      в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению. */

SELECT CAST(funded_at AS date),
       MIN(raised_amount),
       MAX(raised_amount)
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) > 0 AND NOT MIN(raised_amount) = MAX(raised_amount);

/* Задание 8. Создайте поле с категориями:
	      - Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию high_activity.
	      - Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию middle_activity.
	      - Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию low_activity.
	      Отобразите все поля таблицы fund и новое поле с категориями. */

SELECT *,
       CASE
           WHEN invested_companies > 100 THEN 'high_activity'
           WHEN invested_companies BETWEEN 20 AND 99 THEN 'middle_activity'
           WHEN invested_companies < 20 THEN 'low_activity'
       END
FROM fund;

/* Задание 9. Для каждой из категорий, назначенных в предыдущем задании, посчитайте округлённое до ближайшего целого числа
	      среднее количество инвестиционных раундов, в которых фонд принимал участие.
	      Выведите на экран категории и среднее число инвестиционных раундов.
	      Отсортируйте таблицу по возрастанию среднего. */

WITH
i AS (SELECT *,
             CASE
                 WHEN invested_companies>=100 THEN 'high_activity'
                 WHEN invested_companies>=20 THEN 'middle_activity'
                 ELSE 'low_activity'
             END AS activity
      FROM fund
      )
SELECT activity,
       ROUND(AVG(investment_rounds))
FROM i
GROUP BY activity
ORDER BY ROUND;

/* Задание 10.  Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
	        Для каждой страны посчитайте минимальное, максимальное и среднее число компаний, в которые инвестировали 
	        фонды этой страны, основанные с 2010 по 2012 год включительно. Исключите страны с фондами, 
		у которых минимальное число компаний, получивших инвестиции, равно нулю.
		Выгрузите десять самых активных стран-инвесторов: отсортируйте таблицу по среднему количеству компаний
		от большего к меньшему. Затем добавьте сортировку по коду страны в лексикографическом порядке. */

SELECT country_code,
       MIN(invested_companies),
       MAX(invested_companies),
       AVG(invested_companies)
FROM fund
WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) BETWEEN 2010 AND 2012
GROUP BY country_code
HAVING MIN(invested_companies) > 0
ORDER BY AVG(invested_companies) DESC,
         country_code
LIMIT 10;

/* Задание 11.  Отобразите имя и фамилию всех сотрудников стартапов. Добавьте поле с названием учебного заведения,
		которое окончил сотрудник, если эта информация известна. */ 

SELECT p.first_name,
       p.last_name,
       e.instituition
FROM people AS p
LEFT OUTER JOIN education AS e ON p.id = e.person_id;

/* Задание 12.  Для каждой компании найдите количество учебных заведений, которые окончили её сотрудники.
		Выведите название компании и число уникальных названий учебных заведений.
		Составьте топ-5 компаний по количеству университетов. */

SELECT c.name AS name,
       COUNT(DISTINCT i.instituition) AS count
FROM company AS c
INNER JOIN (SELECT p.company_id AS company_id,
                   e.instituition AS instituition       
            FROM people AS p
            LEFT OUTER JOIN education AS e ON p.id = e.person_id
            ) AS i ON c.id = i.company_id
GROUP BY c.name
ORDER BY count DESC
LIMIT 5;

/* Задание 13.  Составьте список с уникальными названиями закрытых компаний,
		для которых первый раунд финансирования оказался последним. */

SELECT DISTINCT(name)
FROM company
WHERE status = 'closed' AND id IN (SELECT company_id
                                   FROM funding_round
                                   WHERE is_first_round = 1 AND is_last_round = 1);

/* Задание 14. Составьте список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании. */

WITH
ludy AS ( SELECT id
          FROM company
          WHERE status = 'closed' AND id IN (SELECT company_id
                                             FROM funding_round
                                             WHERE is_first_round = 1 AND is_last_round = 1
                                             )
         )
SELECT DISTINCT(p.id)
FROM people AS p
INNER JOIN ludy ON p.company_id = ludy.id ;

/* Задание 15.  Составьте таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи
		и учебным заведением, которое окончил сотрудник. */

SELECT DISTINCT(e.person_id),
       e.instituition
FROM education AS e
WHERE e.person_id IN (WITH
                      ludy AS ( SELECT id
                                FROM company
                                WHERE status = 'closed' AND id IN (SELECT company_id
                                                                   FROM funding_round
                                                                   WHERE is_first_round = 1 AND is_last_round = 1
                                                                   )
                              )
                       SELECT DISTINCT(p.id)
                       FROM people AS p
                       INNER JOIN ludy ON p.company_id = ludy.id
                       );

/* Задание 16.  Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания.
		При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды. */

SELECT e.person_id,
       COUNT(e.instituition)
FROM education AS e
WHERE e.person_id IN (WITH
                      ludy AS ( SELECT id
                                FROM company
                                WHERE status = 'closed' AND id IN (SELECT company_id
                                                                   FROM funding_round
                                                                    WHERE is_first_round = 1 AND is_last_round = 1
                                                                   )
                               )
                      SELECT DISTINCT(p.id)
                      FROM people AS p
                      INNER JOIN ludy ON p.company_id = ludy.id
                      )
GROUP BY e.person_id;

/* Задание 17.  Дополните предыдущий запрос и выведите среднее число учебных заведений (всех, не только уникальных),
		которые окончили сотрудники разных компаний.
		Нужно вывести только одну запись, группировка здесь не понадобится. */

WITH
f16 AS (SELECT e.person_id, COUNT(e.instituition) AS count
        FROM education AS e
        WHERE e.person_id IN (WITH
                              ludy AS ( SELECT id
                                        FROM company
                                        WHERE status = 'closed' AND id IN (SELECT company_id
                                                                           FROM funding_round
                                                                            WHERE is_first_round = 1 AND is_last_round = 1
                                                                           )
                                      )
                               SELECT DISTINCT(p.id)
                               FROM people AS p
                               INNER JOIN ludy ON p.company_id = ludy.id
                              )
        GROUP BY e.person_id
       )
SELECT AVG(f16.count)
FROM f16;

/* Задание 18.  Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных),
		которые окончили сотрудники Socialnet. */

WITH
f16 AS (SELECT e.person_id, COUNT(e.instituition) AS count
        FROM education AS e
        WHERE e.person_id IN (WITH
                              ludy AS ( SELECT id
                                        FROM company
                                        WHERE name = 'Socialnet'
                                      )
                               SELECT DISTINCT(p.id)
                               FROM people AS p
                               INNER JOIN ludy ON p.company_id = ludy.id
                              )
        GROUP BY e.person_id
       )
SELECT AVG(f16.count)
FROM f16;

/* Задание 19.  Составьте таблицу из полей:
		* name_of_fund — название фонда;
		* name_of_company — название компании;
		* amount — сумма инвестиций, которую привлекла компания в раунде.
		В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов,
		а раунды финансирования проходили с 2012 по 2013 год включительно. */

SELECT f.name AS name_of_fund,
       c.name AS name_of_company,
       raised_amount AS amount
FROM investment AS i
LEFT OUTER JOIN company AS c ON i.company_id = c.id
LEFT OUTER JOIN fund AS f ON i.fund_id = f.id
INNER JOIN funding_round AS fr ON i.funding_round_id = fr.id
WHERE c.milestones > 6 AND EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2012 AND 2013;

/* Задание 20.  Выгрузите таблицу, в которой будут такие поля:
		* название компании-покупателя;
		* сумма сделки;
		* название компании, которую купили;
		* сумма инвестиций, вложенных в купленную компанию;
		* доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций,
		округлённая до ближайшего целого числа.
		Не учитывайте те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю,
		исключите такую компанию из таблицы.
		Отсортируйте таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании
		в лексикографическом порядке. Ограничьте таблицу первыми десятью записями. */

SELECT co.name AS buyer,
       ac.price_amount AS price ,
       comp.name AS salesman,
       comp.funding_total AS inv,
       ROUND(ac.price_amount/comp.funding_total)
FROM acquisition AS ac
LEFT JOIN company AS co ON ac.acquiring_company_id = co.id
LEFT JOIN company AS comp ON ac.acquired_company_id = comp.id
WHERE ac.price_amount > 0 AND comp.funding_total > 0
ORDER BY price DESC,
         salesman
LIMIT 10;

/* Задание 21.  Выгрузите таблицу, в которую войдут названия компаний из категории social, получившие финансирование
		с 2010 по 2013 год включительно. Проверьте, что сумма инвестиций не равна нулю.
		Выведите также номер месяца, в котором проходил раунд финансирования. */

SELECT c.name,
       EXTRACT(MONTH FROM CAST(fr.funded_at AS date)) AS MONTH      
FROM company AS c
RIGHT OUTER JOIN funding_round AS fr ON c.id = fr.company_id
WHERE c.category_code = 'social' AND fr.raised_amount > 0
      AND EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2010 AND 2013;

/* Задание 22.  Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды.
		Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
		* номер месяца, в котором проходили раунды;
		* количество уникальных названий фондов из США, которые инвестировали в этом месяце;
		* количество компаний, купленных за этот месяц;
		* общая сумма сделок по покупкам в этом месяце. */

WITH
companies AS (SELECT EXTRACT(MONTH FROM CAST(acquired_at AS date)) AS month,
                     COUNT(acquired_company_id) AS count_company,
                     SUM(price_amount) AS sum_amount
              FROM acquisition
              WHERE EXTRACT(YEAR FROM CAST(acquired_at AS date)) BETWEEN 2010 AND 2013
              GROUP BY month
              ),
funds AS (SELECT EXTRACT(MONTH FROM CAST(fr.funded_at AS date)) AS month,
                 COUNT(DISTINCT fu.name) AS count_names
          FROM funding_round AS fr
          LEFT JOIN investment AS inv ON fr.id = inv.funding_round_id
          LEFT JOIN fund AS fu ON inv.fund_id = fu.id
          WHERE EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2010 AND 2013 AND fu.country_code = 'USA'
          GROUP BY month
          )
SELECT funds.month,
       funds.count_names,
       companies.count_company,
       companies.sum_amount
FROM funds
INNER JOIN companies ON funds.month = companies.month;

/* Задание 23.  Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, в которых есть стартапы,
		зарегистрированные в 2011, 2012 и 2013 годах. Данные за каждый год должны быть в отдельном поле.
		Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему. */

WITH
     inv_2011 AS (SELECT country_code AS cd_2011,
                         AVG(funding_total) AS avg_2011
                  FROM company
                  WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2011
                  GROUP BY cd_2011),
     inv_2012 AS (SELECT country_code AS cd_2012,
                         AVG(funding_total) AS avg_2012
                  FROM company
                  WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2012
                  GROUP BY cd_2012),
     inv_2013 AS (SELECT country_code AS cd_2013,
                         AVG(funding_total) AS avg_2013
                  FROM company
                  WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2013
                  GROUP BY cd_2013)
SELECT inv_2011.cd_2011,
       inv_2011.avg_2011,
       inv_2012.avg_2012,
       inv_2013.avg_2013
FROM inv_2011
INNER JOIN inv_2012 ON inv_2011.cd_2011 = inv_2012.cd_2012
INNER JOIN inv_2013 ON inv_2011.cd_2011 = inv_2013.cd_2013
ORDER BY inv_2011.avg_2011 DESC ;
