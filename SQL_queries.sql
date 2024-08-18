USE election;

-- Duplicate Check
SELECT pc_name, COUNT(pc_name)
FROM (SELECT state, pc_name FROM results_2014 GROUP BY 1, 2) AS a
GROUP BY 1
HAVING COUNT(pc_name)>1;

-- Total constituency per state
SELECT state, COUNT(pc_name)
FROM(SELECT state, pc_name FROM results_2019 GROUP BY 1,2) AS a
GROUP BY 1
ORDER BY 2 DESC;

-- Top 5 and Bottom 5 constituencies of 2014 in terms of voter turnout ratio

SELECT pc_name, ROUND((SUM(total_votes) / total_electors) * 100, 2) AS voter_turnout_ratio
FROM results_2014
GROUP BY pc_name, total_electors
ORDER BY 2 DESC
LIMIT 5;

SELECT pc_name, voter_turnout_ratio
FROM (SELECT pc_name, ROUND((SUM(total_votes) / total_electors) * 100, 2) AS voter_turnout_ratio
FROM results_2014
GROUP BY pc_name, total_electors
ORDER BY 2
LIMIT 5) AS bottom_five
ORDER BY 2 DESC;

-- Top 5 and Bottom 5 constituencies of 2019 in terms of voter turnout ratio

SELECT pc_name, ROUND((SUM(total_votes) / total_electors) * 100, 2) AS voter_turnout_ratio
FROM results_2019
GROUP BY pc_name, total_electors
ORDER BY 2 DESC
LIMIT 5;

SELECT pc_name, voter_turnout_ratio
FROM (SELECT pc_name, ROUND((SUM(total_votes) / total_electors) * 100, 2) AS voter_turnout_ratio
FROM results_2019
GROUP BY pc_name, total_electors
ORDER BY 2
LIMIT 5) AS bottom_five
ORDER BY 2 DESC;

-- Top 5 and Bottom 5 states of 2014 in terms of voter turnout ratio

SELECT state, (SUM(total_votes)/SUM(total_electors))*100 AS voter_turnout_ratio
FROM(
SELECT state, pc_name, SUM(total_votes) AS total_votes,  MAX(total_electors) AS total_electors
FROM results_2014
GROUP BY state, pc_name) AS state_table
GROUP BY state
ORDER BY 2 DESC
LIMIT 5;

SELECT state, voter_turnout_ratio
FROM (SELECT state, (SUM(total_votes)/SUM(total_electors))*100 AS voter_turnout_ratio
FROM(
SELECT state, pc_name, SUM(total_votes) AS total_votes,  MAX(total_electors) AS total_electors
FROM results_2014
GROUP BY state, pc_name) AS state_table
GROUP BY state
ORDER BY 2
LIMIT 5) AS bottom_five
ORDER BY 2 DESC;

-- Top 5 and Bottom 5 states of 2019 in terms of voter turnout ratio

SELECT state, (SUM(total_votes)/SUM(total_electors))*100 AS voter_turnout_ratio
FROM(
SELECT state, pc_name, SUM(total_votes) AS total_votes,  MAX(total_electors) AS total_electors
FROM results_2019
GROUP BY state, pc_name) AS state_table
GROUP BY state
ORDER BY 2 DESC
LIMIT 5;

SELECT state, voter_turnout_ratio
FROM (SELECT state, (SUM(total_votes)/SUM(total_electors))*100 AS voter_turnout_ratio
FROM(
SELECT state, pc_name, SUM(total_votes) AS total_votes,  MAX(total_electors) AS total_electors
FROM results_2019
GROUP BY state, pc_name) AS state_table
GROUP BY state
ORDER BY 2
LIMIT 5) AS bottom_five
ORDER BY 2 DESC;

-- List of constituencies which have elected the same party for two consecutive elections. Rank by % of votes to that winning party in 2019.

WITH result_2014 AS(
SELECT state, pc_name, candidate, party, party_symbol, total_votes,
ROW_NUMBER() OVER(PARTITION BY state, pc_name ORDER BY total_votes DESC) AS rowno1
FROM results_2014),

result_2019 AS(
SELECT state, pc_name, candidate, party, party_symbol, total_votes,
ROW_NUMBER() OVER(PARTITION BY state, pc_name ORDER BY total_votes DESC) AS rowno2,
SUM(total_votes) OVER(PARTITION BY state, pc_name) AS total_votes_all_2019
FROM results_2019)

SELECT r2014.state, r2014.pc_name, r2014.party,
ROUND((r2019.total_votes*100/r2019.total_votes_all_2019), 2) AS vote_percent_2019,
RANK() OVER(ORDER BY r2019.total_votes*100/r2019.total_votes_all_2019 DESC) AS "rank"
FROM result_2014 AS r2014
JOIN result_2019 AS r2019
ON r2014.state = r2019.state AND r2014.pc_name = r2019.pc_name
WHERE r2014.rowno1 = 1 AND r2019.rowno2 = 1 AND r2014.party = r2019.party
ORDER BY "rank";

-- List of top 10 constituencies which have voted for different parties in two elections based on difference in winner vote percentage in two elections.

WITH result_2014 AS(
SELECT state, pc_name, candidate, party, party_symbol, total_votes,
ROW_NUMBER() OVER(PARTITION BY state, pc_name ORDER BY total_votes DESC) AS rowno1,
SUM(total_votes) OVER(PARTITION BY state, pc_name) AS total_votes_all_2014
FROM results_2014),

result_2019 AS(
SELECT state, pc_name, candidate, party, party_symbol, total_votes,
ROW_NUMBER() OVER(PARTITION BY state, pc_name ORDER BY total_votes DESC) AS rowno2,
SUM(total_votes) OVER(PARTITION BY state, pc_name) AS total_votes_all_2019
FROM results_2019)

SELECT state, pc_name, party_2014, party_2019, ABS(vote_percent_2014-vote_percent_2019) AS vote_percent_difference
FROM (SELECT r2014.state, r2014.pc_name, r2014.party AS party_2014, r2019.party AS party_2019,
ROUND((r2014.total_votes*100/r2014.total_votes_all_2014), 2) AS vote_percent_2014,
ROUND((r2019.total_votes*100/r2019.total_votes_all_2019), 2) AS vote_percent_2019
FROM result_2014 AS r2014
JOIN result_2019 AS r2019
ON r2014.state = r2019.state AND r2014.pc_name = r2019.pc_name
WHERE r2014.rowno1 = 1 AND r2019.rowno2 = 1 AND r2014.party != r2019.party) AS diff_party
ORDER BY 5 DESC
LIMIT 10;

-- Top 5 candidates based on margin difference with runners in 2014

WITH result_2014 AS(
SELECT state, pc_name, candidate, party, total_votes,
ROW_NUMBER() OVER(PARTITION BY state, pc_name ORDER BY total_votes DESC) AS rowno
FROM results_2014)

SELECT state, pc_name, candidate, party, total_votes, 
(total_votes - (SELECT total_votes FROM result_2014 AS subquery WHERE subquery.state = main.state 
AND subquery.pc_name = main.pc_name AND subquery.rowno = 2)) AS margin
FROM result_2014 AS main
WHERE rowno = 1
ORDER BY margin DESC
LIMIT 5;

-- Top 5 candidates based on margin difference with runners in 2019

WITH result_2019 AS(
SELECT state, pc_name, candidate, party, total_votes,
ROW_NUMBER() OVER(PARTITION BY state, pc_name ORDER BY total_votes DESC) AS rowno
FROM results_2019),

margin_calculation AS(
SELECT r1.state, r1.pc_name, r1.candidate, r1.party, r1.total_votes,
(r1.total_votes - r2.total_votes) AS margin
FROM result_2019 AS r1
JOIN result_2019 AS r2 ON r1.state = r2.state AND r1.pc_name = r2.pc_name AND r2.rowno = 2
WHERE r1.rowno = 1)

SELECT state, pc_name, candidate, party, total_votes, margin
FROM margin_calculation
ORDER BY margin DESC
LIMIT 5;

-- % split of votes of parties between 2014 vs 2019 at national level

SELECT v.party,
(v.total_votes_party_2014/(SELECT SUM(total_votes) FROM results_2014))*100 AS vote_split_2014,
(v.total_votes_party_2019/(SELECT SUM(total_votes) FROM results_2019))*100 AS vote_split_2019
FROM (SELECT a.*, b.total_votes_party_2019
FROM (SELECT party, sum(total_votes) AS total_votes_party_2014 FROM results_2014 GROUP BY party) AS a
JOIN (SELECT party, sum(total_votes) AS total_votes_party_2019 FROM results_2019 GROUP BY party) AS b
ON a.party = b.party) AS v
ORDER BY 3 DESC;

-- % split of votes of parties between 2014 vs 2019 at state level

WITH t2014 AS(
SELECT state, party, SUM(total_votes) AS total_votes_2014
FROM results_2014
GROUP BY state, party),

t2019 AS(
SELECT state, party, SUM(total_votes) AS total_votes_2019
FROM results_2019
GROUP BY state, party),

n2014 AS(
SELECT state, SUM(total_votes_2014) AS national_total_2014
FROM t2014
GROUP BY state),

n2019 AS(
SELECT state, SUM(total_votes_2019) AS national_total_2019
FROM t2019
GROUP BY state),

party_percentage AS(
SELECT 
COALESCE(t2014.state, t2019.state) AS state,
COALESCE(t2014.party, t2019.party) AS party,
t2014.total_votes_2014,
t2019.total_votes_2019,
(t2014.total_votes_2014 / n2014.national_total_2014) * 100 AS percentage_2014,
(t2019.total_votes_2019 / n2019.national_total_2019) * 100 AS percentage_2019
FROM t2014
LEFT JOIN t2019 ON t2014.state = t2019.state AND t2014.party = t2019.party
LEFT JOIN n2014 ON t2014.state = n2014.state
LEFT JOIN n2019 ON t2019.state = n2019.state

UNION

SELECT 
COALESCE(t2014.state, t2019.state) AS state,
COALESCE(t2014.party, t2019.party) AS party,
t2014.total_votes_2014,
t2019.total_votes_2019,
(t2014.total_votes_2014 / n2014.national_total_2014) * 100 AS percentage_2014,
(t2019.total_votes_2019 / n2019.national_total_2019) * 100 AS percentage_2019
FROM t2019
LEFT JOIN t2014 ON t2014.state = t2019.state AND t2014.party = t2019.party
LEFT JOIN n2014 ON t2014.state = n2014.state
LEFT JOIN n2019 ON t2019.state = n2019.state)
    
SELECT state, party,
COALESCE(total_votes_2014, 0) AS total_votes_2014,
COALESCE(total_votes_2019, 0) AS total_votes_2019,
COALESCE(percentage_2014, 0) AS percentage_2014,
COALESCE(percentage_2019, 0) AS percentage_2019
FROM party_percentage
ORDER BY state, party;

-- Top 5 constituencies for two major national parties where they have gained vote share in 2019 as compared to 2014

WITH total_votes_2014 AS (
    SELECT state, pc_name, SUM(total_votes) AS total_votes_2014
    FROM results_2014
    GROUP BY state, pc_name
),
total_votes_2019 AS (
    SELECT state, pc_name, SUM(total_votes) AS total_votes_2019
    FROM results_2019
    GROUP BY state, pc_name
),
vote_share AS (
    SELECT r2014.state, r2014.pc_name, r2014.party,
           r2014.total_votes AS total_votes_2014,
           r2019.total_votes AS total_votes_2019,
           (r2019.total_votes * 100.0 / t2019.total_votes_2019
            - r2014.total_votes * 100.0 / t2014.total_votes_2014) AS vote_share_gain
    FROM results_2014 AS r2014
    JOIN results_2019 AS r2019
    ON r2014.state = r2019.state
    AND r2014.pc_name = r2019.pc_name
    AND r2014.party = r2019.party
    JOIN total_votes_2014 AS t2014
    ON r2014.state = t2014.state
    AND r2014.pc_name = t2014.pc_name
    JOIN total_votes_2019 AS t2019
    ON r2019.state = t2019.state
    AND r2019.pc_name = t2019.pc_name
    WHERE r2014.total_votes * 100.0 / t2014.total_votes_2014
          < r2019.total_votes * 100.0 / t2019.total_votes_2019
)

SELECT state, pc_name, party, vote_share_gain
FROM vote_share
WHERE party = 'INC'
ORDER BY vote_share_gain DESC
LIMIT 5;

-- Top 5 constituencies for two major national parties where they have lost vote share in 2019 as compared to 2014

WITH total_votes_2014 AS (
    SELECT state, pc_name, SUM(total_votes) AS total_votes_2014
    FROM results_2014
    GROUP BY state, pc_name
),
total_votes_2019 AS (
    SELECT state, pc_name, SUM(total_votes) AS total_votes_2019
    FROM results_2019
    GROUP BY state, pc_name
),
vote_share AS (
    SELECT r2014.state, r2014.pc_name, r2014.party,
           r2014.total_votes AS total_votes_2014,
           r2019.total_votes AS total_votes_2019,
           (r2014.total_votes * 100.0 / t2014.total_votes_2014
            - r2019.total_votes * 100.0 / t2019.total_votes_2019) AS vote_share_loss
    FROM results_2014 AS r2014
    JOIN results_2019 AS r2019
    ON r2014.state = r2019.state
    AND r2014.pc_name = r2019.pc_name
    AND r2014.party = r2019.party
    JOIN total_votes_2014 AS t2014
    ON r2014.state = t2014.state
    AND r2014.pc_name = t2014.pc_name
    JOIN total_votes_2019 AS t2019
    ON r2019.state = t2019.state
    AND r2019.pc_name = t2019.pc_name
    WHERE r2014.total_votes * 100.0 / t2014.total_votes_2014
          > r2019.total_votes * 100.0 / t2019.total_votes_2019
)

SELECT state, pc_name, party, vote_share_loss
FROM vote_share
WHERE party = 'INC'
ORDER BY vote_share_loss DESC
LIMIT 5;

-- Constituency which has voted the most for NOTA in 2014

SELECT state, pc_name, party, total_votes, ROUND(SUM(total_votes)*100/total_electors, 2) AS "% vote share"
FROM results_2014
WHERE party = "NOTA"
GROUP BY 1, 2, 4, total_electors
ORDER BY total_votes DESC
LIMIT 1;

-- Constituency which has voted the most for NOTA in 2019

SELECT state, pc_name, party, total_votes, ROUND(SUM(total_votes)*100/total_electors, 2) AS "% vote share"
FROM results_2019
WHERE party = "NOTA"
GROUP BY 1, 2, 4, total_electors
ORDER BY total_votes DESC
LIMIT 1;


-- List of constituencies which have elected candidates whose party has less than 10% vote share at state level in 2019

WITH winners AS(
SELECT state, pc_name, party, total_votes,
ROW_NUMBER() OVER(PARTITION BY state, pc_name ORDER BY total_votes DESC) AS rowno
FROM results_2019),

party_votes AS(
SELECT state, party, SUM(total_votes) AS party_total_votes
FROM results_2019
GROUP BY state, party),

state_total AS(
SELECT state, SUM(total_votes) AS state_total_votes
FROM results_2019
GROUP BY state)

SELECT w.state, w.pc_name, w.party, w.total_votes, (p.party_total_votes/s.state_total_votes)*100 AS vote_share
FROM winners AS w
JOIN party_votes AS p ON w.state = p.state AND w.party = p.party
JOIN state_total AS s ON w.state = s.state
WHERE w.rowno = 1 AND (p.party_total_votes/s.state_total_votes)*100 < 10;

-- postal votes vs turnout ratio for year 2019

SELECT pc_name, ROUND(SUM(postal_votes)/SUM(total_votes) * 100, 2) AS postal_votes, ROUND((SUM(total_votes) / total_electors) * 100, 2) AS voter_turnout_ratio
FROM results_2019
GROUP BY 1, total_electors;

-- gdp of state vs turnout ratio for year 2019

WITH turnout AS(
SELECT state, ROUND((SUM(total_votes)/SUM(total_electors))*100, 2) AS voter_turnout_ratio
FROM (SELECT state, pc_name, SUM(total_votes) AS total_votes, MAX(total_electors) AS total_electors
FROM results_2019
GROUP BY state, pc_name) AS a
GROUP BY state)

SELECT turnout.state, turnout.voter_turnout_ratio, gdp.gdp
FROM turnout JOIN gdp
ON turnout.state = gdp.state;

-- literacy of state vs turnout ratio for year 2019

WITH turnout AS(
SELECT state, ROUND((SUM(total_votes)/SUM(total_electors))*100, 2) AS voter_turnout_ratio
FROM (SELECT state, pc_name, SUM(total_votes) AS total_votes, MAX(total_electors) AS total_electors
FROM results_2019
GROUP BY state, pc_name) AS a
GROUP BY state)

SELECT turnout.state, turnout.voter_turnout_ratio, literacy.literacy_rate
FROM turnout JOIN literacy
ON turnout.state = literacy.state;

-- total_seats_won

SELECT COUNT(DISTINCT(pc_name))
FROM (SELECT pc_name, party,
ROW_NUMBER() OVER (PARTITION BY pc_name ORDER BY total_votes DESC) AS rowno
FROM results_2019) AS r
WHERE r.party = 'INC' AND r.rowno = 1;