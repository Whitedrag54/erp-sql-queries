
--Sales Discount Group By Location & Supplier ID
--Purpose: Provides the branches with a report to review the Sales Discount Groups

--## Testing - Matching variables that was used in the P21 report
DECLARE @location AS INT = 7,
        @Supplier AS INT = 109519

SELECT
    isupp.supplier_id,
    il.sales_discount_group,
    im.item_id
    
FROM
    inv_loc AS il
    LEFT JOIN inventory_supplier_x_loc AS isxl ON il.location_id = isxl.location_id
    LEFT JOIN inventory_supplier AS isupp ON isxl.inventory_supplier_uid = isupp.inventory_supplier_uid
        AND il.inv_mast_uid = isupp.inv_mast_uid
    LEFT JOIN inv_mast AS im ON il.inv_mast_uid = im.inv_mast_uid

WHERE
    il.delete_flag <> 'Y'
    AND il.location_id = @location
    --## We only want primary supplier
    AND isxl.primary_supplier = 'Y'
    AND isupp.supplier_id = @Supplier
    AND isupp.delete_flag <> 'Y'
    AND im.delete_flag <> 'Y'
    --## There are some items marked as discontinued
    AND (im.discontinued_date > GETDATE() OR im.discontinued_date IS NULL)

ORDER BY item_id