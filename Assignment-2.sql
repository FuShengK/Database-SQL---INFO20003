-- Q1. Find all the ongoing/unfinished steps. Display the title of these steps and full names of the users
-- who are taking these steps.

SELECT DISTINCT title, CONCAT( first_name , '', last_name ) AS user_full_nameFROM step_taken
    INNER JOIN user ON userID = user_id
    INNER JOIN step ON stepID = step_id
WHERE when_finished IS NULL;

-- Q2. List the themes and the number of the steps associated with these themes. Display the theme
-- name and number of associated steps sorted in descending order.

SELECT name, COUNT( step_id ) AS number
FROM step_theme RIGHT JOIN theme ON themeID = theme_id
GROUP BY name
ORDER BY number DESC;

-- Q3. Which step is the least popular based on the average rating given by users? Display the title and ID
-- of the step and its average rating (formatted to 2 decimal places). Only include those steps which are
-- rated by at least one user.

SELECT DISTINCT title, stepID , ROUND(AVG(rating), 2) AS rating_value
FROM step_taken INNER JOIN step ON stepID = step_id
GROUP BY stepID
HAVING COUNT( stepID ) > 0
ORDER BY rating_value
LIMIT 1;

-- Q4. Find the steps that are taken the greatest number of times. Display the ID, title and count of the
-- times the step has been taken. In case of ties, display all the steps with the same number of times
-- taken.

SELECT stepID , title, COUNT( * ) AS times
FROM step_taken INNER JOIN step ON stepID = step_id
GROUP BY stepID
HAVING times = ( 
    SELECT MAX(times)
    FROM ( 
        SELECT COUNT(*) AS times
        FROM step_taken
        GROUP BY step_id 
        ) AS greatest_steps );

-- Q5. Who is the most followed user between age of 15 and 18? Display the age (as an integer), first
-- name, and last name of such user along with the number of followers.


SELECT TIMESTAMPDIFF( YEAR, DOB, CURDATE() ) AS age, first_name , last_name , COUNT( * ) AS followers
FROM user_follow INNER JOIN user ON userID = followed_user_id
GROUP BY userID
HAVING 14 < age < 19 AND 
    followers = (
        SELECT MAX(followers)
        FROM (
            SELECT TIMESTAMPDIFF( YEAR, DOB, CURDATE() ) AS age, COUNT( following_user_id ) AS followers
            FROM user_follow INNER JOIN user ON userID = followed_user_id
            GROUP BY userID
            HAVING 14 < age < 19
            ) following_num );

-- Q6. Find all steps that are never taken or are taken exactly once? Display the id and title of these steps
-- along with the indication how many times the step has been taken (0 or 1).


SELECT stepID , title, COUNT( step_id ) AS times_being_taken
FROM step LEFT JOIN step_taken ON stepID = step_id
GROUP BY stepID
HAVING times_being_taken < 2;

-- Q7. Find users who started taking step
-- ‘Doing and being’ after they had started the step ‘ Panic ’ but
-- have never completed ‘ Panic’. Display the user ID, first name and last name.

SELECT DISTINCT userID , first_name , last_name
FROM ( 
    SELECT user_id , when_started AS pa_time
    FROM step_taken INNER JOIN step ON step_id = stepID
    WHERE title = 'Panic' AND when_finished IS NULL
) panic NATURAL JOIN ( 
    SELECT user_id , when_started AS dab_time
    FROM step_taken INNER JOIN step ON step_id = stepID
    WHERE title = 'Doing and being'
) doing_and_being INNER JOIN user ON userID = user_id
WHERE TIMEDIFF( pa_time, dab_time ) <

-- Q8. What finished steps were completed both by a user with first name "Alice" and a user with first
-- name "Bob"? Display the ID and title of such steps along with the number of times each user has
-- completed these steps.

SELECT * FROM ( 
    SELECT step_id , title, COUNT( step_id ) AS Bob
    FROM step_taken INNER JOIN user ON userID = user_id INNER JOIN step ON stepID = step_id
    WHERE first_name = 'Bob' AND when_finished IS NOT NULL
    GROUP BY step_id 
) bob NATURAL JOIN (
    SELECT step_id , title, COUNT(step_id ) AS Alice
    FROM step_taken INNER JOIN user ON userID = user_id INNER JOIN step ON stepID = step_id
    WHERE first_name = 'Alice' AND when_finished IS NOT NULL
    GROUP BY step_id 
    ) alice
GROUP BY step_id;

-- Q9. Find the top two users with the highest number of interests. For those two users, find out the
-- common steps taken by both of them. Display the titles of the common steps they have taken and the
-- number of times those steps are taken by each user.

SELECT * FROM (
    SELECT title, COUNT( * ) AS FIRST_ONE
    FROM step_taken INNER JOIN step ON stepID = step_id NATURAL JOIN (
        SELECT user_id
        FROM user_interest
        GROUP BY user_id
        ORDER BY COUNT( interest_id ) DESC
        LIMIT 1
    ) first_user
    GROUP BY step_id 
) top_1 NATURAL JOIN (
        SELECT title, COUNT(*) AS SECOND_ONE
        FROM step_taken INNER JOIN step ON stepID = step_id NATURAL JOIN (
            SELECT user_id
            FROM (
                SELECT ROW_NUMBER() OVER () AS id, user_id
                FROM (
                    SELECT user_id
                    FROM user_interest
                    GROUP BY user_id
                    ORDER BY COUNT( interest_id ) DESC
                    LIMIT 2
                ) top2 
            ) assigned_user
            WHERE id = 2 
        ) second_user
        GROUP BY step_id 
) top_2;

-- Q10. For each user taking a step, calculate how many other users have taken the same step. We are
-- only interested in the cases where the step is performed by at least 5 other users. Display the user ID,
-- number of other users (at least 5 other users) who are taking the same step and the title of the taken
-- step.

SELECT DISTINCT user_id AS ID, ( other_num 1) AS other_users , title
FROM step_taken INNER JOIN step ON step_id = stepID NATURAL JOIN (
    SELECT step_id , COUNT( DISTINCT user_id ) AS other_num , title
    FROM step_taken INNER JOIN step ON step_id = stepID
    GROUP BY step_idHAVING other_num > 6
) count_others
ORDER BY ID;