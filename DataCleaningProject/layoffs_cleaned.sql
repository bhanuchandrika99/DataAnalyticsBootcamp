/*
-- DATA CLEANING project : What we do --
--	Remove duplicates --
--	Standardize the Data --
-- Null values or blank values --
--	Remove any columns or rows --
--
*/

SELECT *
FROM layoffs;

-- Since we cannnot remove/ drop any columns in the raw data. We create staging data set or new raw data set, to make changes --

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;



-------- 1.CHECKING FOR DUPLICATES -------

SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions ) AS row_num
FROM layoffs_staging;

-- if the row_num >=2 then there are duplicates -- so wrinting a CTE for that --

WITH duplicate_cte AS (
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions ) AS row_num
	FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num >1;

-- CHECK IF THEY ARE REALLY DUPLICATE --
SELECT *
FROM layoffs_staging
WHERE company = 'Microsoft';

-- DELETEING DUPLICATE ROWS THAT HAVE ROW_NUM >1 --
WITH duplicate_cte AS (
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions ) AS row_num
	FROM layoffs_staging
)
DELETE 
FROM duplicate_cte
WHERE row_num >1;

-- GOT AN ERROR CODE-1288: THE target table duplicate_cte of the DELETE is no updatable -- So creating new table - FROM SCHEMA --
-- layoffs_staging > CopytoClipboard > Create Statement -- then paste 

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- CHECKING THE COLUMNS OF NEW TABLE CREATED--
SELECT *
FROM layoffs_staging2;

-- INSTERTING THE ABOVE DATA INTO NEW TABLE layoffs_staging2 --

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions ) AS row_num
FROM layoffs_staging;

-- WE GOT THE DATA SAME AS layoffs_staging BUT WITH AN EXTRA COLUMN ROW_NUM (USING CREATE TABLE) in layoffs_staging2 --
-- NOW WE PERFORM DELETE OPERATION --
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;
-- IF DELETE FUNCTION IS GIVING ERROR, TRY CHANGING THE safe update mode AND try again == To disable safe mode, toggle the option in Preferences -> SQL Editor and reconnect.
-- after unchecking the Safe updates mode , you don't have to restart MySQL; --
-- go to Query on the top left side of your window then select reconnect to server and then run your query. --

SELECT *
FROM layoffs_staging2;



		-------- 2.STANDARDIZING THE DATA (FINDING ISSUES IN YOUR DATA AND FIXING IT) ----------
        
-- a) Observed white spaces before company names --        
SELECT DISTINCT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- b) Observed few industry names little similar (Crypto and Crypto Currency -- 
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';
-- since most of them are crypto, changing the name as crypto for all --

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- c) Checking for issues any location --
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

-- d) Checking for any issues in country AND found an issue in United States--
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


SELECT *
FROM layoffs_staging2;

-- e) Checking the date column, Observed that the date column is in text format , so changing that to date format --

SELECT `date`, 
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2
ORDER BY 1;

-- date column is still in text format , so changin that using ALTER --
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;



----------- 3.NULL VALUES or BLANK VALUES -------

-- a) checking the other columns like laid_off for null and '' values , but on the go we found some missing values in industry as well --
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

UPDATE layoffs_staging2
SET  industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- TRYING to update/fill the missing values that we have information on. Example: Airbnd - industry - 'Travel' is missing for other Airbnb row --
SELECT *
FROM layoffs_staging2 t1 
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '') 
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1 
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '') 
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- Since we only have one row representing the Bally's interactive , we dont have enough info to keep or delete. So leaving it as it is--

----------- 4.REMOVE COLUMNS THAT WE DONT NEED ---------- ONLY DELETE WHEN YOU ARE REALLLY SURE --

-- SINCE WE DONT HAVE ANY information so that we can populate the missing values for total_laid_off and percentage_laid_off -- 
-- We are moving forward to delete those rows --

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;


DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;


SELECT *
FROM layoffs_staging2;

-- Also , we no more need row_num -- So dropping/deleting that as well --

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;