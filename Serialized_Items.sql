--List of Item IDs that require serial numbers
--Purpose: Identifiying which Item IDs have serial numbers in order to remove this restriction on certain ones

SELECT DISTINCT
    il.location_id,
    im.item_id,
    im.item_desc,
    im.serialized,
    pg.product_group_desc

FROM
    inv_mast AS im
    LEFT JOIN inv_loc AS il ON im.inv_mast_uid = il.inv_mast_uid
    LEFT JOIN product_group AS pg ON il.product_group_id = pg.product_group_id

WHERE
    im.serialized = 'Y'
    AND im.delete_flag <> 'Y'
    --## For LG Items
    /*
    -- AND (im.item_id LIKE 'LG VRF%'
    --  OR im.item_id LIKE 'LG DFS%')
    -- AND il.product_group_id NOT IN ('341','311','9999','131','NEW','104','0000','241','911','201','139')
    -- AND il.product_group_id IN ('341','311','9999','131','NEW','104','0000','241','911','201','139')
    */
    
    --## For Mitsubishi Items
    AND im.item_id LIKE 'MITSU%'
    AND il.product_group_id IN ('311', '341', 'NEW', '0000', '131', '9999', '241')
    -- AND il.product_group_id NOT IN ('311', '341', 'NEW', '0000', '131', '9999', '241')
    
ORDER BY 1,2
