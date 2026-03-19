--Cycle Count Research
--Purpose: Confirm possible to provide the same data that is seen in the P21 Report so that it can be uploaded into EDA for reports

--## Matching variables that was used in the P21 report
DECLARE @StartDate AS DATE = '2025-12-2';
DECLARE @EndDate AS DATE = '2025-12-11';
DECLARE @LocationID AS INT = 5;

--## Obtain the total average percentage from the cycle counts
WITH TotalPercentage AS (
    SELECT
        
        --## Calculation to get the total average as a percentage
        ROUND(((SUM(CAST(cca.edited_items_on_count AS FLOAT)) / SUM(CAST(cca.items_on_count AS FLOAT)) * 100)) * -1 + 100, 2) AS total_accuracy_percentage

    FROM
        cycle_count_hdr AS cch
        LEFT JOIN cycle_count_accuracy AS cca ON cch.cycle_count_hdr_uid = cca.cycle_count_hdr_uid
        LEFT JOIN cycle_count_loc_criteria AS cclc ON cclc.cycle_count_loc_criteria_uid = cch.cycle_count_loc_criteria_uid

    WHERE
        CAST(cca.date_created AS DATE) BETWEEN @StartDate AND @EndDate
        AND cclc.location_id = @LocationID
)

SELECT

    cch.date_created AS 'Adjustment Date',
    cch.cycle_count_no AS 'Cycle Count Number',
    ISNULL(CAST(cca.adjustment_number AS varchar),'Approved') AS 'Adjustment Number',
    cca.items_on_count AS 'Number of Items Counted',
    cca.edited_items_on_count AS 'Number of Items Edited',
    --## Calculation to get the number of items that needed to be edited that were on the count as an accuracy percentage
    ROUND(((CAST(cca.edited_items_on_count AS FLOAT) / CAST(cca.items_on_count AS FLOAT) * 100)) * -1 + 100, 2) AS 'Accuracy Percentage',
    tp.total_accuracy_percentage AS 'Total Accuracy Percentage'

FROM
    cycle_count_hdr AS cch
    LEFT JOIN cycle_count_accuracy AS cca ON cch.cycle_count_hdr_uid = cca.cycle_count_hdr_uid
    LEFT JOIN cycle_count_loc_criteria AS cclc ON cclc.cycle_count_loc_criteria_uid = cch.cycle_count_loc_criteria_uid
    --## Drop in the WITH as this is matching the WHERE in the main SELECT. Epicor will have to calculate this another way
    --## as this can not be pulled in like this as the parameters will shift after the data is in EDA
    CROSS APPLY TotalPercentage AS tp

WHERE
    CAST(cca.date_created AS DATE) BETWEEN @StartDate AND @EndDate
    AND cclc.location_id = @LocationID