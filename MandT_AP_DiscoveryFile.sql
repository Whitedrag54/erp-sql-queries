--Initial discovery data for M&T Payables Integration
--Purpose: Provide M&T with data in order to better identify the need of their AP Payables automation

--Total up the total payments in 2025 per Vendor
WITH TotalVendorAmounts AS (
   SELECT
      payments.vendor_id,
      SUM(payments.check_amount) AS 'TotalAmount',
      COUNT(*) AS 'PaymentCount'
   FROM
      payments
   WHERE
      YEAR(payments.check_date) = 2025
      AND cleared_bank = 'Y'
   GROUP BY 
      payments.vendor_id   
)

--## Issue with FROM statement likely as it was pulled right from P21. Will refine during file creation if project moves forward
SELECT DISTINCT

   payments.vendor_id AS 'Vendor ID',
   address.name AS 'Name',
   --## ACH address info is pulled from a different table
   CASE
      WHEN vendor.class_1id = 'ACH'
         THEN (
            SELECT TOP 1
               CASE
                  WHEN (address.mail_address1 IS NOT NULL AND (LTRIM(RTRIM(address.mail_address1)) <> '' AND LTRIM(RTRIM(address.mail_address1)) <> ' '))
                     THEN address.mail_address1
                  WHEN (address.mail_address2 IS NOT NULL AND (address.mail_address1 IS NULL OR LTRIM(RTRIM(address.mail_address1)) = '' OR LTRIM(RTRIM(address.mail_address1)) = ' '))
                     THEN address.mail_address2
               END
            FROM
               vendor_ach_contacts AS vac
               LEFT JOIN contacts AS c ON vac.contact_id = c.id
               LEFT JOIN [address] AS a ON a.id = c.address_id

            WHERE vac.vendor_id = payments.vendor_id
         )
      --## Used for other options of payment
      ELSE(
         CASE
            WHEN (address.mail_address1 IS NOT NULL AND (LTRIM(RTRIM(address.mail_address1)) <> '' AND LTRIM(RTRIM(address.mail_address1)) <> ' '))
               THEN address.mail_address1
            WHEN (address.mail_address2 IS NOT NULL AND (address.mail_address1 IS NULL OR LTRIM(RTRIM(address.mail_address1)) = '' OR LTRIM(RTRIM(address.mail_address1)) = ' '))
               THEN address.mail_address2
         END
      )
   END AS 'Address 1',

   CASE
      --## ACH address info is pulled from a different table
      WHEN vendor.class_1id = 'ACH'
         THEN (
            SELECT TOP 1
               CASE
                  WHEN (address.mail_address2 IS NOT NULL AND (LTRIM(RTRIM(address.mail_address2)) <> '' AND LTRIM(RTRIM(address.mail_address2)) <> ' '))
                     THEN address.mail_address2
                  ELSE ''
               END
            FROM
               vendor_ach_contacts AS vac
               LEFT JOIN contacts AS c ON vac.contact_id = c.id
               LEFT JOIN [address] AS a ON a.id = c.address_id

            WHERE vac.vendor_id = payments.vendor_id
         )
      --## Used for other options of payment
      ELSE(
         CASE
            WHEN (address.mail_address2 IS NOT NULL AND (LTRIM(RTRIM(address.mail_address2)) <> '' AND LTRIM(RTRIM(address.mail_address2)) <> ' '))
               THEN address.mail_address2
            ELSE ''
         END
      )
   END AS 'Address 2',   
   
   CASE
      --## ACH address info is pulled from a different table
      WHEN vendor.class_1id = 'ACH'
         THEN (
            SELECT TOP 1
               address.mail_city
            FROM
               vendor_ach_contacts AS vac
               LEFT JOIN contacts AS c ON vac.contact_id = c.id
               LEFT JOIN [address] AS a ON a.id = c.address_id

            WHERE vac.vendor_id = payments.vendor_id
         )
      --## Used for other options of payment
      ELSE address.mail_city
   END AS 'City',

   CASE
      --## ACH address info is pulled from a different table
      WHEN vendor.class_1id = 'ACH'
         THEN (
            SELECT TOP 1
               address.mail_state
            FROM
               vendor_ach_contacts AS vac
               LEFT JOIN contacts AS c ON vac.contact_id = c.id
               LEFT JOIN [address] AS a ON a.id = c.address_id

            WHERE vac.vendor_id = payments.vendor_id
         )
      --## Used for other options of payment
      ELSE address.mail_state
   END AS 'State',

   CASE
      --## ACH address info is pulled from a different table
      WHEN vendor.class_1id = 'ACH'
         THEN (
            SELECT TOP 1
               address.mail_postal_code
            FROM
               vendor_ach_contacts AS vac
               LEFT JOIN contacts AS c ON vac.contact_id = c.id
               LEFT JOIN [address] AS a ON a.id = c.address_id

            WHERE vac.vendor_id = payments.vendor_id
         )
      --## Used for other options of payment
      ELSE address.mail_postal_code
   END AS 'Zip/Postal Code',

   CASE
      --## ACH address info is pulled from a different table
      WHEN vendor.class_1id = 'ACH'
         THEN (
            SELECT TOP 1
               address.central_phone_number
            FROM
               vendor_ach_contacts AS vac
               LEFT JOIN contacts AS c ON vac.contact_id = c.id
               LEFT JOIN [address] AS a ON a.id = c.address_id

            WHERE vac.vendor_id = payments.vendor_id
         )
      --## Used for other options of payment
      ELSE address.central_phone_number
   END AS 'Telephone',

   address.email_address AS 'Email Address',
   TotalVendorAmounts.PaymentCount AS 'Count',
   'Y' AS 'Current Vendor',
   TotalVendorAmounts.TotalAmount AS 'Amount',

   CASE
      WHEN vendor.class_1id = 'ACH'
         THEN 'ACH'
      WHEN vendor.class_1id = 'Check'
         THEN 'Check'
      WHEN vendor.class_1id = 'CREDITC'
         THEN 'Card'
   END AS 'Payment Method'     

--FROM statement pulled from inside P21
FROM
   vendor
   LEFT JOIN payments ON payments.vendor_id = vendor.vendor_id
   INNER JOIN company ON company.company_id = payments.company_no
   INNER JOIN [address] ON address.id = vendor.vendor_id
   INNER JOIN bank_accounts ON bank_accounts.company_no = payments.company_no
   AND bank_accounts.bank_no = payments.bank_no
   AND vendor.company_id = payments.company_no
   LEFT JOIN class AS v_class1 ON vendor.class_1id = v_class1.class_id
   AND v_class1.class_type = 'VD'
   AND v_class1.class_number = 1
   LEFT JOIN class AS v_class2 ON vendor.class_2id = v_class2.class_id
   AND v_class2.class_type = 'VD'
   AND v_class2.class_number = 2
   LEFT JOIN class AS v_class3 ON vendor.class_3id = v_class3.class_id
   AND v_class3.class_type = 'VD'
   AND v_class3.class_number = 3
   LEFT JOIN class AS v_class4 ON vendor.class_4id = v_class4.class_id
   AND v_class4.class_type = 'VD'
   AND v_class4.class_number = 4
   LEFT JOIN class AS v_class5 ON vendor.class_5id = v_class5.class_id
   AND v_class5.class_type = 'VD'
   AND v_class5.class_number = 5
   LEFT JOIN currency_hdr ON currency_hdr.currency_id = bank_accounts.currency_id
   LEFT JOIN currency_hdr AS currency_paym ON currency_paym.currency_id = payments.currency_id
   LEFT JOIN code_p21 transmission_method ON transmission_method.code_no = payments.transmission_method
   INNER JOIN TotalVendorAmounts ON payments.vendor_id = TotalVendorAmounts.vendor_id

WHERE
   bank_accounts.bank_no = 1
   AND payments.void <> 'Y'
   AND (vendor.class_1id = 'ACH' OR vendor.class_1id = 'Check' OR vendor.class_1id = 'CREDITC')

ORDER BY 1
