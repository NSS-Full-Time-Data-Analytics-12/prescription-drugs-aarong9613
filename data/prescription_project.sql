SELECT *
FROM prescriber;

SELECT *
FROM prescription;

SELECT *
FROM drug;





1)
--a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

 SELECT SUM (total_claim_count) as sum_claim, npi
 FROM prescription
 	INNER JOIN prescriber USING (npi)
GROUP BY npi
ORDER BY sum_claim DESC;

--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

 SELECT SUM (total_claim_count) as sum_claim, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
 FROM prescription
 	INNER JOIN prescriber USING (npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY sum_claim DESC;

2)
--a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description, SUM (total_claim_count) AS sum_claims
	FROM prescription
INNER JOIN prescriber USING (npi)
GROUP BY specialty_description
ORDER BY sum_claims DESC;

--b.Which specialty had the most total number of claims for opioids?

SELECT SUM (total_claim_count) AS total_claims, specialty_description
	FROM prescription
	INNER JOIN drug USING (drug_name)
	INNER JOIN prescriber USING (npi)
WHERE opioid_drug_flag = 'Y' 
GROUP BY specialty_description
ORDER BY total_claims DESC;

--    c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT specialty_description, SUM(total_claim_count) AS total_prescription_count
FROM prescriber
 LEFT JOIN prescription USING (npi)
 GROUP BY specialty_description
 HAVING SUM(total_claim_count) IS NULL

--    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids? Use CASE WHEN********

WITH _b AS (SELECT SUM (total_claim_count) AS total_claims_opioids, specialty_description
FROM prescriber
	INNER JOIN prescription USING (npi)
	INNER JOIN drug USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description)

WITH _a AS (SELECT SUM (total_claim_count) AS total_claims_all_presc, specialty_description
FROM prescription
			INNER JOIN prescriber USING (npi)
GROUP BY specialty_description)


SELECT *
FROM _a
	INNER JOIN _a USING specialty_description
	INNER JOIN _b USING specialty_description


	

--a. Which drug (generic_name) had the highest total drug cost?**************
SELECT generic_name, total_drug_cost
FROM drug
	INNER JOIN prescription USING (drug_name)
ORDER BY total_drug_cost DESC;
--b. Which drug (generic_name) has the hightest total cost per day? 
SELECT DISTINCT generic_name, ROUND(SUM (total_drug_cost)/SUM(total_day_supply),2) AS cost_per_day	
FROM drug
	INNER JOIN prescription USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;
/*a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.*/
SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END AS drug_type
FROM drug;
/*b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.*/
SELECT SUM(total_drug_cost)::money,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	     WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug
	INNER JOIN prescription USING (drug_name)
GROUP BY opioid_drug_flag, antibiotic_drug_flag;
/*a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.*/

SELECT COUNT(DISTINCT cbsa) AS cbsa_count_TN
FROM cbsa INNER JOIN fips_county USING (fipscounty)
WHERE state = 'TN';

--b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT SUM(population) AS total_pop, cbsa
FROM cbsa
	INNER JOIN population USING (fipscounty)
GROUP by cbsa
ORDER BY total_pop DESC;

--c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT cbsa, cbsaname, population, county
FROM cbsa
	FULL JOIN fips_county USING (fipscounty)
	INNER JOIN population USING(fipscounty)
ORDER BY cbsa NULLS FIRST, population DESC
LIMIT(1);
-- a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT total_claim_count, drug_name
FROM prescription
	WHERE total_claim_count >= 3000;
	
-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
	SELECT total_claim_count, drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'YES' ELSE 'NO' END AS is_opioid
FROM prescription
	INNER JOIN drug USING (drug_name)
	WHERE total_claim_count >= 3000;

--    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
	SELECT total_claim_count, drug_name,nppes_provider_last_org_name, nppes_provider_first_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'YES' ELSE 'NO' END AS is_opioid
FROM prescription
	INNER JOIN drug USING (drug_name)
	INNER JOIN prescriber USING (npi)
	WHERE total_claim_count >= 3000;
--a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT specialty_description, npi, drug_name
FROM prescriber
	CROSS JOIN drug 
	WHERE specialty_description = 'Pain Management' AND nppes_provider_city ILIKE 'NASHVILLE' AND opioid_drug_flag = 'Y';
--b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).***************************
SELECT npi, drug.drug_name, SUM(total_claim_count) AS sum_claim
FROM prescriber
	INNER JOIN prescription USING (npi)
	CROSS JOIN drug 
	WHERE specialty_description = 'Pain Management' AND nppes_provider_city ILIKE 'NASHVILLE' AND opioid_drug_flag = 'Y'
	GROUP BY npi,drug.drug_name;
--c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT npi, drug.drug_name, COALESCE (SUM(total_claim_count),0) AS sum_claim 
FROM prescriber
	INNER JOIN prescription USING (npi)
	CROSS JOIN drug 
	WHERE specialty_description = 'Pain Management' AND nppes_provider_city ILIKE 'NASHVILLE' AND opioid_drug_flag = 'Y'
GROUP BY npi,drug.drug_name



