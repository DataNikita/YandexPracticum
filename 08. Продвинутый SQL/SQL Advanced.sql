/*					ПЕРВАЯ ЧАСТЬ					*/
/* Задание 1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки». */

SELECT COUNT(*)
FROM stackoverflow.posts AS p
WHERE (favorites_count >= 100 OR score > 300)
	AND post_type_id IN (SELECT id
                             FROM stackoverflow.post_types
                             WHERE type = 'Question'
                             ) ;

/* Задание 2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно?
	      Результат округлите до целого числа.*/

WITH aaa AS (SELECT DATE_TRUNC('day', creation_date::date) AS day,
                    COUNT(*) AS q_in_day
             FROM stackoverflow.posts
             WHERE (creation_date::date BETWEEN '2008-11-01' AND '2008-11-18')
              	   AND post_type_id IN (SELECT id
                                        FROM stackoverflow.post_types
                                        WHERE type = 'Question'
                                        )
             GROUP BY day
             ORDER BY day
            )
SELECT ROUND(AVG(q_in_day))
FROM aaa ;

/* Задание 3. Сколько пользователей получили значки сразу в день регистрации?
	      Выведите количество уникальных пользователей. */

WITH us AS (SELECT id,
                   DATE_TRUNC('day', creation_date)::date AS us_day
            FROM stackoverflow.users
            ),
     ba AS (SELECT user_id,
                   DATE_TRUNC('day', creation_date)::date AS ba_day
            FROM stackoverflow.badges
            )
SELECT COUNT(DISTINCT(ba.user_id))
FROM ba
INNER JOIN us ON us.id = ba.user_id
WHERE ba.ba_day = us.us_day ;

/* Задание 4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос? */

SELECT COUNT(DISTINCT po.id)
FROM stackoverflow.posts AS po
INNER JOIN stackoverflow.votes AS vo ON po.id = vo.post_id 
WHERE po.user_id IN (SELECT id
                  	 FROM stackoverflow.users
                  	 WHERE display_name = 'Joel Coehoorn'
                     ) ;

/* Задание 5. Выгрузите все поля таблицы vote_types.
	      Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке.
	      Таблица должна быть отсортирована по полю id. */

SELECT *,
       RANK() OVER(ORDER BY id DESC)
FROM stackoverflow.vote_types
ORDER BY id ;

/* Задание 6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close.
	      Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов.
	      Отсортируйте данные сначала по убыванию количества голосов,
	      потом по убыванию значения идентификатора пользователя. */ 

SELECT user_id,
       COUNT(id) AS count
FROM stackoverflow.votes
WHERE vote_type_id IN (SELECT id
                       FROM stackoverflow.vote_types
                       WHERE name = 'Close'
                       )
GROUP BY user_id
ORDER BY count DESC,
         user_id DESC
LIMIT 10 ;

/* Задание 7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября
	      по 15 декабря 2008 года включительно. Отобразите несколько полей:
	      * идентификатор пользователя;
	      * число значков;
	      * место в рейтинге — чем больше значков, тем выше рейтинг.
	      Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
	      Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя. */

WITH ba AS (SELECT DISTINCT user_id,
                   COUNT(id) AS count
            FROM stackoverflow.badges
            WHERE DATE_TRUNC('day', creation_date)::date BETWEEN '2008-11-15' AND '2008-12-15'
            GROUP BY user_id
            ORDER BY count DESC
            LIMIT 10
            )
SELECT *,
       DENSE_RANK() OVER(ORDER BY count DESC)
FROM ba
ORDER BY count DESC,
         user_id ;

/* Задание 8. Сколько в среднем очков получает пост каждого пользователя? Сформируйте таблицу из следующих полей:
	      * заголовок поста;
	      * идентификатор пользователя;
	      * число очков поста;
	      * среднее число очков пользователя за пост, округлённое до целого числа.
	      Не учитывайте посты без заголовка, а также те, что набрали ноль очков. */

SELECT title,
       user_id,
       score,
       ROUND((AVG(score) OVER(PARTITION BY user_id)))
FROM stackoverflow.posts
WHERE score != 0 AND title IS NOT NULL ;

/* Задание 9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков.
	      Посты без заголовков не должны попасть в список. */

SELECT title
FROM stackoverflow.posts
WHERE title IS NOT NULL AND user_id IN ( WITH badges AS (SELECT user_id,
                                                                COUNT(id)
                                                         FROM stackoverflow.badges
                                                         GROUP BY user_id
                                                         )
                                         SELECT user_id
                                         FROM badges
                                         WHERE count > 1000
                                        ) ;

/* Задание 10. Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada).
	       Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
	       * пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
	       * пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
	       * пользователям с числом просмотров меньше 100 — группу 3.
	       Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу.
	       Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу. */

SELECT id,
       views,
       CASE
           WHEN views >= 350 THEN 1
           WHEN views < 350 AND views >= 100 THEN 2
           WHEN views < 100 THEN 3
       END
FROM stackoverflow.users
WHERE location LIKE '%Canada%' AND views > 0 ;

/* Задание 11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное 
	       число просмотров в своей группе. Выведите поля с идентификатором пользователя, группой и количеством просмотров.
	       Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора. */ 

WITH users AS (SELECT id,
                      views,
                      CASE
                          WHEN views >= 350 THEN 1
                          WHEN views < 350 AND views >= 100 THEN 2
                          WHEN views < 100 THEN 3
                       END AS user_group
               FROM stackoverflow.users
               WHERE location LIKE '%Canada%' AND views > 0
               ORDER BY views DESC
               ),
      max_views AS (SELECT *,
                           MAX(views) OVER(PARTITION BY user_group ORDER BY views DESC)
                    FROM users
                    )
SELECT id,
       user_group,
       views
FROM max_views
WHERE views = max
ORDER BY views DESC,
		 id ;

/* Задание 12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
	       * номер дня;
	       * число пользователей, зарегистрированных в этот день;
	       * сумму пользователей с накоплением. */

WITH users AS (SELECT DISTINCT(EXTRACT(DAY FROM creation_date::date)) AS day,
                      COUNT(id) OVER(PARTITION BY EXTRACT(DAY FROM creation_date::date))
               FROM stackoverflow.users
               WHERE id IN (SELECT id
                            FROM stackoverflow.users
                            WHERE (DATE_TRUNC('month', creation_date)::date) BETWEEN '2008-11-01' AND '2008-11-30'
                            )
               ORDER BY day
               )
SELECT *,
       SUM(count) OVER(ORDER BY day)
FROM users ;

/* Задание 13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией
	       и временем создания первого поста. Отобразите:
	       * идентификатор пользователя;
	       * разницу во времени между регистрацией и первым постом. */

WITH posts AS (SELECT DISTINCT user_id,
                      MIN(creation_date) OVER (PARTITION BY user_id) AS min_dt 
               FROM stackoverflow.posts
               )
SELECT posts.user_id,
       (posts.min_dt - users.creation_date) AS diff
FROM stackoverflow.users AS users
JOIN posts ON users.id = posts.user_id ;




/*					ВТОРАЯ ЧАСТЬ					*/


/* Задание 1. Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года.
	      Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить.
	      Результат отсортируйте по убыванию общего количества просмотров. */

SELECT DATE_TRUNC('month', creation_date)::date AS month,
       SUM(views_count) AS views_sum
FROM stackoverflow.posts
WHERE EXTRACT(YEAR FROM creation_date::date) = 2008
GROUP BY month
ORDER BY views_sum DESC ;

/* Задание 2. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации)
	      дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитывайте.
	      Для каждого имени пользователя выведите количество уникальных значений user_id.
	      Отсортируйте результат по полю с именами в лексикографическом порядке. */

SELECT users.display_name,
       COUNT(DISTINCT posts.user_id)
FROM stackoverflow.posts AS posts
JOIN stackoverflow.users AS users ON posts.user_id = users.id
JOIN stackoverflow.post_types AS types ON posts.post_type_id = types.id
WHERE types.type = 'Answer' 
      AND DATE_TRUNC('day', posts.creation_date)::date <= (DATE_TRUNC('day', users.creation_date)::date + INTERVAL '1 month')
GROUP BY users.display_name
HAVING COUNT(posts.id)>100
ORDER BY users.display_name ;

/* Задание 3. Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей,
	      которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года.
	      Отсортируйте таблицу по значению месяца по убыванию. */

SELECT DISTINCT(DATE_TRUNC('month', creation_date)::date) AS month,
       COUNT(id) OVER(PARTITION BY DATE_TRUNC('month', creation_date)::date)
FROM stackoverflow.posts
WHERE EXTRACT(YEAR FROM creation_date::date) = 2008
      AND user_id IN (SELECT user_id
                      FROM stackoverflow.posts
                      WHERE DATE_TRUNC('month', creation_date)::date = '2008-12-01'
                            AND user_id IN (SELECT id
                                            FROM stackoverflow.users
                                            WHERE DATE_TRUNC('month', creation_date)::date = '2008-09-01'
                                            )
                      )
ORDER BY month DESC ;


/* Задание 4. Используя данные о постах, выведите несколько полей:
	      * идентификатор пользователя, который написал пост;
	      * дата создания поста;
	      * количество просмотров у текущего поста;
	      * сумма просмотров постов автора с накоплением.
	      Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей,
	      а данные об одном и том же пользователе — по возрастанию даты создания поста. */

SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER(PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts
ORDER BY user_id, creation_date ;

/* Задание 5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой?
	      Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост.
	      Нужно получить одно целое число — не забудьте округлить результат. */

WITH days AS (SELECT DISTINCT user_id,
                     COUNT(DISTINCT(DATE_TRUNC('day', creation_date)::date)) count_day
              FROM stackoverflow.posts
              WHERE DATE_TRUNC('day', creation_date)::date BETWEEN '2008-12-01' AND '2008-12-07'
              GROUP BY user_id
              )
SELECT ROUND(AVG(count_day))
FROM days ;

/* Задание 6. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года?
	      Отобразите таблицу со следующими полями:
	      * Номер месяца.
	      * Количество постов за месяц.
	      * Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
	       Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным.
   	       Округлите значение процента до двух знаков после запятой. Переведите делимое в тип numeric. */

WITH posts AS (SELECT DISTINCT(EXTRACT('month' FROM creation_date::date)) AS post_month,
                      COUNT(id) OVER(PARTITION BY DATE_TRUNC('month', creation_date)::date) AS post_count
               FROM stackoverflow.posts
               WHERE DATE_TRUNC('day', creation_date)::date BETWEEN '2008-09-01' AND '2008-12-31'
              )
SELECT post_month,
       post_count,
       ROUND( ( ( post_count::numeric - LAG(post_count) OVER() ) / LAG(post_count) OVER() ) * 100 , 2)
FROM posts ;

/* Задание 7. Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации.
	      Выведите данные его активности за октябрь 2008 года в таком виде:
    	      * номер недели;
	      * дата и время последнего поста, опубликованного на этой неделе. */

WITH users AS (SELECT DISTINCT users.id,
                     users.creation_date::date,
                     COUNT(posts.id) OVER(PARTITION BY users.id)
              FROM stackoverflow.posts AS posts
              JOIN stackoverflow.users AS users ON posts.user_id = users.id
              ORDER BY count DESC
              LIMIT 1
              )
SELECT DISTINCT(EXTRACT('week' FROM posts.creation_date::date)) AS post_week,
       MAX(posts.creation_date) OVER(PARTITION BY EXTRACT('week' FROM posts.creation_date::date))
FROM stackoverflow.posts posts
INNER JOIN users ON posts.user_id = users.id
WHERE DATE_TRUNC('month', posts.creation_date)::date = '2008-10-01' ;
