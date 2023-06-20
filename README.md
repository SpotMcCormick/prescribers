# prescribers
HERE is a class project I did at NSS involving claims for patients on medicare. Lots of functions where use one this like CASE, JOINS, CTE, & subqueries
Questions and code is below

1A.  Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

  	SELECT SUM(p2.total_claim_count) AS claim_count, p2.npi
  	 FROM prescriber as p1
   	INNER JOIN prescription AS p2
    	ON p2.npi = p1.npi
	GROUP BY p1.nppes_provider_last_org_name, p2.npi
	ORDER BY claim_count DESC
	LIMIT 1;'''
	
 99707
 
 1B. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
 
 --SELECT SUM(p2.total_claim_count) AS claim_count, p2.npi, p1.nppes_provider_last_org_name AS last_name, p1.nppes_provider_first_name AS first_name, p1.specialty_description
   FROM prescriber as p1
   INNER JOIN prescription AS p2
    ON p2.npi = p1.npi
	GROUP BY p1.nppes_provider_last_org_name, p1.nppes_provider_first_name, p2.npi, p1.specialty_description
	ORDER BY claim_count DESC
	LIMIT 1;*
 
 Bruce Pendley, family practice'
 
 2A. Which specialty had the most total number of claims (totaled over all drugs)?
 Which specialty had the most total number of claims (totaled over all drugs)?

 --SELECT SUM(p1.total_claim_count) AS total_claim_count, p2.specialty_description
	FROM drug AS d
	INNER JOIN prescription AS p1
	USING(drug_name)
		INNER JOIN prescriber AS p2
		USING(npi)
	WHERE opioid_drug_flag = 'Y'
	GROUP BY p2.specialty_description
	ORDER BY total_claim_count DESC
	
Nurse Practioniner

 2C. Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
 
 --SELECT DISTINCT p1.specialty_description
	FROM prescriber AS p1
	WHERE p1.specialty_description NOT IN
		(SELECT specialty_description
		FROM prescriber
		INNER JOIN prescription
		USING(npi))

"specialty_description"
"Ambulatory Surgical Center"
"Chiropractic"
"Contractor"
"Developmental Therapist"
"Hospital"
"Licensed Practical Nurse"
"Marriage & Family Therapist"
"Medical Genetics"
"Midwife"
"Occupational Therapist in Private Practice"
"Physical Therapist in Private Practice"
"Physical Therapy Assistant"
"Radiology Practitioner Assistant"
"Specialist/Technologist, Other"
"Undefined Physician type"

2D. For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

--WITH o AS (
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

3A.  Which drug (generic_name) had the highest total drug cost?

--SELECT generic_name, SUM(total_drug_cost)::MONEY AS total_cost
FROM drug 
JOIN prescription ON drug.drug_name = prescription.drug_name
GROUP BY generic_name
ORDER BY total_cost DESC
LIMIT 1;

----"NSULIN GLARGINE,HUM.REC.ANLOG"

3B. Which drug (generic_name) has the hightest total cost per day?

--SELECT generic_name, ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2)::MONEY AS cost_per_day
FROM drug
JOIN prescription ON drug.drug_name = prescription.drug_name
GROUP BY generic_name
ORDER BY cost_per_day DESC
LIMIT 1;

----""C1 ESTERASE INHIBITOR""


 4A. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

 --SELECT DISTINCT drug_name,
	CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
		WHEN antibiotic_drug_flag='N' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
	FROM drug

 4B. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics.
 --SELECT 
	CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
		WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type,
		SUM(total_drug_cost)::MONEY AS total_cost
		FROM drug
		INNER JOIN prescription AS p
		USING(drug_name)
		GROUP BY drug_type

 5A. How many CBSAs are in Tennessee?
 
 	SELECT count(DISTINCT fips_county.fipscounty)+ COUNT(DISTINCT cbsa) AS total_cbsa_in_tn
	FROM cbsa
	INNER JOIN fips_county
	 USING (fipscounty)
	WHERE state='TN'

 --42

 5B.  Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population. 

  SELECT c.cbsaname, SUM(p.population) AS total_pop
   FROM cbsa AS c
   INNER JOIN population AS p
   USING (fipscounty)
   GROUP BY c.cbsaname
   ORDER BY total_pop DESC

   5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
   
   	SELECT county, population
FROM fips_county
JOIN population ON fips_county.fipscounty = population.fipscounty
WHERE fips_county.fipscounty NOT IN (
  SELECT fipscounty
  FROM cbsa)
  ORDER BY population.population DESC
  LIMIT 1;

  --SEVIER

  6A.  Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
  
  	SELECT drug_name, total_claim_count
	FROM prescription
	WHERE total_claim_count >=3000
  
 6B. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

 SELECT drug_name,
		(SELECT DISTINCT opioid_drug_flag
		FROM drug
		WHERE opioid_drug_flag='Y') AS opioid
	FROM prescription
	WHERE total_claim_count >=3000

 6C.  Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

 	SELECT drug_name, p.nppes_provider_last_org_name||', '|| p.nppes_provider_first_name AS last_name_first_name,
		(SELECT DISTINCT opioid_drug_flag
		FROM drug
		WHERE opioid_drug_flag='Y') AS opioid
	FROM prescription
	INNER JOIN prescriber AS p
	USING (npi)
	WHERE total_claim_count >=3000


 Hope you enjoyed!! 
 
