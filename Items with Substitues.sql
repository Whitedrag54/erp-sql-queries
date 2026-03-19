--Items with substitues by supplier
--Purpose: Request to identify which items had a substitue item id at our DC for a certain supplier

SELECT
    im.item_id 'Primary Item ID',
    imsub.item_id AS 'Sub Item ID',
    isub.sub_desc AS 'Sub Desc',
    il.stockable,
    il.inv_min AS 'MIN',
    il.inv_max AS 'MAX'

FROM
    inv_mast AS im
    LEFT JOIN inv_loc AS il ON im.inv_mast_uid = il.inv_mast_uid
    LEFT JOIN [location] AS l ON il.location_id = l.location_id
    LEFT JOIN inv_sub AS isub ON im.inv_mast_uid = isub.inv_mast_uid
    LEFT JOIN inv_mast AS imsub ON isub.sub_inv_mast_uid = imsub.inv_mast_uid
    LEFT JOIN inventory_supplier AS isupp ON im.inv_mast_uid = isupp.inv_mast_uid
    LEFT JOIN inventory_supplier_x_loc AS isuppxl ON isupp.inventory_supplier_uid = isuppxl.inventory_supplier_uid 
        AND isuppxl.location_id = il.location_id

WHERE
    --## Adjust supplier id and location per request
    isupp.supplier_id = '106685'
    AND il.location_id = 13
    AND im.delete_flag <> 'Y'
    AND il.delete_flag <> 'Y'
    AND isub.delete_flag <> 'Y'
    AND isupp.delete_flag <> 'Y'
    AND isuppxl.primary_supplier = 'Y'

ORDER BY 1