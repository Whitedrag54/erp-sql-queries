
--Sales Discount Group By Item ID
--Purpose: Provides the branches with a report to review the Sales Discount Groups

--## Testing - Matching variables that was used in the P21 report
DECLARE @ItemID AS VARCHAR(40) = ' RU RFH080E4S-DA'

SELECT TOP(100)
    im.item_id,
    isupp.supplier_id,
    il.sales_discount_group,
    il.location_id
    
FROM
    inv_loc AS il
    LEFT JOIN inventory_supplier_x_loc AS isxl ON il.location_id = isxl.location_id
    LEFT JOIN inventory_supplier AS isupp ON isxl.inventory_supplier_uid = isupp.inventory_supplier_uid
        AND il.inv_mast_uid = isupp.inv_mast_uid
    LEFT JOIN inv_mast AS im ON il.inv_mast_uid = im.inv_mast_uid

WHERE
    il.delete_flag <> 'Y'
    --## We only want primary supplier
    AND isxl.primary_supplier = 'Y'
    AND isupp.delete_flag <> 'Y'
    AND im.delete_flag <> 'Y'
    AND im.item_id = @ItemID
    --## There are some items marked as discontinued
    AND (im.discontinued_date > GETDATE() OR im.discontinued_date IS NULL)

ORDER BY item_id, il.location_id