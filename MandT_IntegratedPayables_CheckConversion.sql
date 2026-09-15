/********************************************/
--M&T Integrated Payables Check Conversion
--Last Modified - 5/29/2026
--Modified By: Dan Dundon
--Notes:
--  Initial code was created using M&T's
--  spec sheet. It was determined to use only
--  an account code of our creation to avoid
--  sharing account number and routing number
--  through the file
--5/29/2026:
--  Updated code to be used in CmdExec in SQL
--  Agent
/********************************************/

IF OBJECT_ID('tempdb..#MandT_CheckData', 'U') IS NOT NULL
    DROP TABLE #MandT_CheckData;

--CurrentDay is typically Wed as that's when checks are run
DECLARE @CurrentDay DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
--This 1900 date is a Thurs; Using this to determine the previous Thurs
--DECLARE @LastThursday DATE = DATEADD(week, DATEDIFF(day, '1900-01-05', GETDATE()) / 7, '1900-01-04');

SELECT
    /*-------START Payer Details Section-------*/
    c.company_name AS 'Company (Payer) Name',
    '' AS 'Company (Payer) Name 2',
    companyaddress.mail_address1 AS 'Payer Address',
    '' AS 'Payer Address 2',
    companyaddress.mail_city AS 'Payer Address City',
    companyaddress.mail_state AS 'Payer Address State',
    companyaddress.mail_postal_code AS 'Payer Address Postal Code',
    '' AS 'Payer Address Country',
    '' AS 'Payer Bank Account Code',
    '' AS 'PayerBank AccountNumber',
    '' AS 'PayerBank RoutingNumber',
    '' AS 'Payer Flex Field 1',
    /*-------END Payer Details Section-------*/

    /*-------START Payment Details Section-------*/
    FORMAT(p.check_date, 'MM/dd/yyyy') AS 'Payment Date MM/DD/YYYY',
    p.check_no AS 'Payment Number',
    p.check_amount AS 'Payment Amount',
    p.vendor_id AS 'Vendor/ Supplier ID',
    UPPER(a.name) AS 'Payee Name',
    '' AS 'Payee Name 2',
    CASE
            WHEN (a.mail_address1 IS NOT NULL AND (LTRIM(RTRIM(a.mail_address1)) <> '' AND LTRIM(RTRIM(a.mail_address1)) <> ' '))
               THEN a.mail_address1
            WHEN (a.mail_address2 IS NOT NULL AND (a.mail_address1 IS NULL OR LTRIM(RTRIM(a.mail_address1)) = '' OR LTRIM(RTRIM(a.mail_address1)) = ' '))
               THEN a.mail_address2
    END AS 'Payee Address',

    CASE
        WHEN (a.mail_address2 IS NOT NULL AND (LTRIM(RTRIM(a.mail_address2)) <> '' AND LTRIM(RTRIM(a.mail_address2)) <> ' '))
            THEN a.mail_address2
        ELSE ''
    END AS 'Payee Address 2',

    ISNULL(a.mail_city,'') AS 'Payee Address City',
    ISNULL(a.mail_state, '') AS 'Payee Address State',
    ISNULL(a.mail_postal_code,'') AS 'Payee Address ZIP',
    '' AS 'Payee Address Country',
    '' AS 'Beneficiary Email Address',
    '' AS 'Mail/Handling Code',
    /*-------END Payment Details Section-------*/

    /*-------START Invoice/Remittance Details Section-------*/
    ah.invoice_no AS 'Invoice Number',
    FORMAT(ah.invoice_date, 'MM/dd/yyyy') AS 'Invoice Date',
    '' AS 'Invoice Description',
    ah.invoice_amount AS 'Invoice Gross',
    ah.terms_amount AS 'Invoice Discount',
    ah.amount_paid AS 'Invoice Net/Amount Paid'
    /*-------END Payment Details Section-------*/

INTO #MandT_CheckData

FROM
    vendor AS v
    LEFT JOIN payments AS p ON p.vendor_id = v.vendor_id
    INNER JOIN company AS c ON c.company_id = p.company_no
    INNER JOIN [address] AS a ON a.id = v.vendor_id
    LEFT JOIN [address] AS companyaddress ON c.address_id = companyaddress.id
    INNER JOIN bank_accounts AS ba ON ba.company_no = p.company_no
    AND ba.bank_no = p.bank_no
    LEFT JOIN apinv_hdr AS ah ON p.check_no = ah.check_no

WHERE
    c.company_id = 'MSI'
    AND ba.bank_no = 1
    AND p.void <> 'Y'
    AND v.class_1id = 'Check'
    AND p.check_date < DATEADD(DAY, 1, @CurrentDay)
    AND p.check_date >= @CurrentDay
    --AND p.check_date >= @LastThursday
    AND ah.approved = 'Y'

ORDER BY p.check_date DESC

--Add Header to file
SELECT
    '"Company (Payer) Name"',
    '"Company (Payer) Name 2"',
    '"Payer Address"',
    '"Payer Address 2"',
    '"Payer Address City"',
    '"Payer Address State"',
    '"Payer Address Postal Code"',
    '"Payer Address Country"',
    '"Payer Bank Account Code"',
    '"PayerBank AccountNumber"',
    '"PayerBank RoutingNumber"',
    '"Payer Flex Field 1"',
    '"Payment Date MM/DD/YYYY"',
    '"Payment Number"',
    '"Payment Amount"',
    '"Vendor/ Supplier ID"',
    '"Payee Name"',
    '"Payee Name 2"',
    '"Payee Address"',
    '"Payee Address 2"',
    '"Payee Address City"',
    '"Payee Address State"',
    '"Payee Address ZIP"',
    '"Payee Address Country"',
    '"Beneficiary Email Address"',
    '"Mail/Handling Code"',
    '"Invoice Number"',
    '"Invoice Date"',
    '"Invoice Description"',
    '"Invoice Gross"',
    '"Invoice Discount"',
    '"Invoice Net/Amount Paid"'

UNION ALL

--Include data into file
SELECT
    '"' + CAST([Company (Payer) Name] AS VARCHAR(100)) + '"',
    '"' + CAST([Company (Payer) Name 2] AS VARCHAR(100)) + '"',
    '"' + CAST([Payer Address] AS VARCHAR(100)) + '"',
    '"' + CAST([Payer Address 2] AS VARCHAR(100)) + '"',
    '"' + CAST([Payer Address City] AS VARCHAR(100)) + '"',
    '"' + CAST([Payer Address State] AS VARCHAR(100)) + '"',
    '"' + CAST([Payer Address Postal Code] AS VARCHAR(100)) + '"',
    '"' + CAST([Payer Address Country] AS VARCHAR(100)) + '"',
    '"' + CAST([Payer Bank Account Code] AS VARCHAR(100)) + '"',
    '"' + CAST([PayerBank AccountNumber] AS VARCHAR(100)) + '"',
    '"' + CAST([PayerBank RoutingNumber] AS VARCHAR(100)) + '"',
    '"' + CAST([Payer Flex Field 1] AS VARCHAR(100)) + '"',
    '"' + CAST([Payment Date MM/DD/YYYY] AS VARCHAR(100)) + '"',
    '"' + CAST([Payment Number] AS VARCHAR(100)) + '"',
    '"' + CAST([Payment Amount] AS VARCHAR(100)) + '"',
    '"' + CAST([Vendor/ Supplier ID] AS VARCHAR(100)) + '"',
    '"' + CAST([Payee Name] AS VARCHAR(100)) + '"',
    '"' + CAST([Payee Name 2] AS VARCHAR(100)) + '"',
    '"' + CAST([Payee Address] AS VARCHAR(100)) + '"',
    '"' + CAST([Payee Address 2] AS VARCHAR(100)) + '"',
    '"' + CAST([Payee Address City] AS VARCHAR(100)) + '"',
    '"' + CAST([Payee Address State] AS VARCHAR(100)) + '"',
    '"' + CAST([Payee Address ZIP] AS VARCHAR(100)) + '"',
    '"' + CAST([Payee Address Country] AS VARCHAR(100)) + '"',
    '"' + CAST([Beneficiary Email Address] AS VARCHAR(100)) + '"',
    '"' + CAST([Mail/Handling Code] AS VARCHAR(100)) + '"',
    '"' + CAST([Invoice Number] AS VARCHAR(100)) + '"',
    '"' + CAST([Invoice Date] AS VARCHAR(100)) + '"',
    '"' + CAST([Invoice Description] AS VARCHAR(100)) + '"',
    '"' + CAST([Invoice Gross] AS VARCHAR(100)) + '"',
    '"' + CAST([Invoice Discount] AS VARCHAR(100)) + '"',
    '"' + CAST([Invoice Net/Amount Paid] AS VARCHAR(100)) + '"'

FROM
    #MandT_CheckData

DROP TABLE #MandT_CheckData
