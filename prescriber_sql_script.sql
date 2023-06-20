--1. 
   -- a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
   SELECT SUM(p2.total_claim_count) AS claim_count, p2.npi
   FROM prescriber as p1
   INNER JOIN prescription AS p2
    ON p2.npi = p1.npi
	GROUP BY p1.nppes_provider_last_org_name, p2.npi
	ORDER BY claim_count DESC
	LIMIT 1; 
	
	
	
--  99707
    --b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.


SELECT SUM(p2.total_claim_count) AS claim_count, p2.npi, p1.nppes_provider_last_org_name AS last_name, p1.nppes_provider_first_name AS first_name, p1.specialty_description
   FROM prescriber as p1
   INNER JOIN prescription AS p2
    ON p2.npi = p1.npi
	GROUP BY p1.nppes_provider_last_org_name, p1.nppes_provider_first_name, p2.npi, p1.specialty_description
	ORDER BY claim_count DESC
	LIMIT 1; 
	
	--Bruce Pendley, family practice
--2. 
   -- a. Which specialty had the most total number of claims (totaled over all drugs)?
  SELECT SUM(p1.total_claim_count) AS total_claims, p2.specialty_description
   FROM prescription AS p1
   INNER JOIN prescriber AS p2
   	ON p1.npi=p2.npi
GROUP BY p2.specialty_description
ORDER BY total_claims DESC
	
--family practice at 9752347

    --b. Which specialty had the most total number of claims for opioids?
	 
	
	SELECT SUM(p1.total_claim_count) AS total_claim_count, p2.specialty_description
	FROM drug AS d
	INNER JOIN prescription AS p1
	USING(drug_name)
		INNER JOIN prescriber AS p2
		USING(npi)
	WHERE opioid_drug_flag = 'Y'
	GROUP BY p2.specialty_description
	ORDER BY total_claim_count DESC
	
	--Nurse Practioniner
	

    --c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
	SELECT DISTINCT p1.specialty_description
	FROM prescriber AS p1
	WHERE p1.specialty_description NOT IN
		(SELECT specialty_description
		FROM prescriber
		INNER JOIN prescription
		USING(npi))
	
	
	--NO 

    --d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
	
	
	SELECT DISTINCT p1.specialty_description, ROUND(SUM(p2.total_claim_count) OVER(PARTITION BY p1.specialty_description)*100.0/
		2576654)
		AS opioid_perc_total
FROM prescriber AS p1
INNER JOIN prescription AS p2
USING(npi)
INNER JOIN drug
USING(drug_name)
ORDER BY opioid_perc_total DESC



WITH o AS (
	SELECT p1.specialty_description, SUM(p2.total_claim_count) AS opioid_claims
	FROM prescriber AS p1
	JOIN prescription p2
	USING(npi)
	Join  drug AS d
	USING(drug_name)
	WHERE d.opioid_drug_flag='Y'
	GROUP BY p1.specialty_description
),
	s AS(
		SELECT p1.specialty_description, SUM(p2.total_claim_count) specialty_claims
	FROM prescriber AS p1
	JOIN prescription p2
	USING(npi)
	Join  drug AS d
	USING(drug_name)
	GROUP BY p1.specialty_description
)
SELECT specialty_description,  ROUND(o.opioid_claims/s.specialty_claims *100,2) AS perc_of_opioids
FROM o
INNER JOIN s
USING(specialty_description)
ORDER BY perc_of_opioids DESC




WITH specialty_totals AS (
  SELECT specialty_description, SUM(total_claim_count) AS total_claims
  FROM prescription
  JOIN prescriber USING (npi)
  GROUP BY specialty_description
),
opioid_totals AS (
  SELECT --specialty_description, 
	SUM(total_claim_count) AS opioid_claims
  FROM prescription
  JOIN prescriber USING (npi)
  JOIN drug USING (drug_name)
  WHERE drug.opioid_drug_flag = 'Y'
  --GROUP BY specialty_description
)
SELECT s.specialty_description, 
       ROUND(o.opioid_claims / s.total_claims * 100,2) AS opioid_percentage
FROM specialty_totals s
JOIN opioid_totals o USING (specialty_description)
ORDER BY opioid_percentage DESC;


	
	SELECT
	specialty_description,
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) as opioid_claims,
	SUM(total_claim_count) AS total_claims,
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) * 100.0 /  SUM(total_claim_count) AS opioid_percentage
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
GROUP BY specialty_description
ORDER BY opioid_percentage DESC;



	
	

--3. 
   -- a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, SUM(total_drug_cost)::MONEY AS total_cost
FROM drug 
JOIN prescription ON drug.drug_name = prescription.drug_name
GROUP BY generic_name
ORDER BY total_cost DESC
LIMIT 10;



"NSULIN GLARGINE,HUM.REC.ANLOG"
   

    --b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

------this one

SELECT generic_name, ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2)::MONEY AS cost_per_day
FROM drug
JOIN prescription ON drug.drug_name = prescription.drug_name
GROUP BY generic_name
ORDER BY cost_per_day DESC
LIMIT 10;

--""C1 ESTERASE INHIBITOR""
----	
	
	

--4. 
    --a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
	
SELECT DISTINCT drug_name,
	CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
		WHEN antibiotic_drug_flag='N' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
	FROM drug



    --b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

WITH cte AS (
	SELECT drug_name,
	CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
		WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
		FROM drug)
	SELECT cte.drug_type, sum(p.total_drug_cost)::MONEY AS total_drug_cost
	FROM prescription AS p
	INNER JOIN cte
	ON cte.drug_name=p.drug_name
	GROUP BY cte.drug_type
	
--OR
		
SELECT 
	CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
		WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type,
		SUM(total_drug_cost)::MONEY AS total_cost
		FROM drug
		INNER JOIN prescription AS p
		USING(drug_name)
		GROUP BY drug_type
		
	
	

--5. 
    --a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
	
	SELECT count(DISTINCT fips_county.fipscounty)+ COUNT(DISTINCT cbsa) AS total_cbsa_in_tn
	FROM cbsa
	INNER JOIN fips_county
	 USING (fipscounty)
	WHERE state='TN'
	
	--42
	
	
   -- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
  
  
  SELECT c.cbsaname, SUM(p.population) AS total_pop
   FROM cbsa AS c
   INNER JOIN population AS p
   USING (fipscounty)
   GROUP BY c.cbsaname
   ORDER BY total_pop DESC
  
   

    --c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

	SELECT county, population
FROM fips_county
JOIN population ON fips_county.fipscounty = population.fipscounty
WHERE fips_county.fipscounty NOT IN (
  SELECT fipscounty
  FROM cbsa)
  ORDER BY population.population DESC

--SEVIER

--6. 
   -- a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
	SELECT drug_name, total_claim_count
	FROM prescription
	WHERE total_claim_count >=3000

    --b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
	SELECT drug_name,
		(SELECT DISTINCT opioid_drug_flag
		FROM drug
		WHERE opioid_drug_flag='Y') AS opioid
	FROM prescription
	WHERE total_claim_count >=3000
	

    --c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
	SELECT drug_name, p.nppes_provider_last_org_name||', '|| p.nppes_provider_first_name AS last_name_first_name,
		(SELECT DISTINCT opioid_drug_flag
		FROM drug
		WHERE opioid_drug_flag='Y') AS opioid
	FROM prescription
	INNER JOIN prescriber AS p
	USING (npi)
	WHERE total_claim_count >=3000

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

   -- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT p.npi, d.drug_name
FROM prescriber AS p
CROSS JOIN drug AS d
WHERE p.nppes_provider_city='NASHVILLE'
	AND 
	d.opioid_drug_flag='Y'
	AND p.specialty_description='Pain Management'
	
	

    --b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
	
	SELECT p1.npi, d.drug_name, p2.total_claim_count, p1.nppes_provider_first_name|| ' ' || p1.nppes_provider_last_org_name
FROM prescriber AS p1
CROSS JOIN drug AS d
	LEFT JOIN
	prescription AS p2
	USING(npi, drug_name)
WHERE p1.nppes_provider_city='NASHVILLE'
	AND 
	d.opioid_drug_flag='Y'
	AND p1.specialty_description='Pain Management'

	
	
    
    --c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
	
	
		SELECT p1.npi, d.drug_name, p1.nppes_provider_first_name|| ' ' || p1.nppes_provider_last_org_name, COALESCE(p2.total_claim_count,0)
FROM prescriber AS p1
CROSS JOIN drug AS d
	LEFT JOIN
	prescription AS p2
	USING(npi, drug_name)
WHERE p1.nppes_provider_city='NASHVILLE'
	AND 
	d.opioid_drug_flag='Y'
	AND p1.specialty_description='Pain Management'
ORDER BY COALESCE(p2.total_claim_count,0)
