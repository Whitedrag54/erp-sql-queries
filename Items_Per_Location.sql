--Items Per Location
--Purpose: Allows Purchasing and Pricing to isolate price and other details for items per location

--## Pulls discontinued item info
WITH Loc13ItemInfo AS (
    SELECT
        invs.inv_mast_uid,
        isxl.primary_supplier,
        s.supplier_name,
        il.discontinued

    FROM
        inventory_supplier AS invs
        LEFT JOIN inventory_supplier_x_loc AS isxl ON isxl.inventory_supplier_uid = invs.inventory_supplier_uid
        LEFT JOIN supplier AS s ON s.supplier_id = invs.supplier_id
        LEFT JOIN inv_loc AS il ON il.inv_mast_uid = invs.inv_mast_uid AND il.location_id = 13
    WHERE
        isxl.location_id = 13
        AND isxl.primary_supplier = 'Y'
        AND invs.delete_flag = 'N'
)

SELECT    
    im.item_id,
    im.item_desc,
    CASE
        --## Found some part numbers with only a space
        WHEN invs.supplier_part_no = ' '
            THEN ''
        ELSE LTRIM(RTRIM(ISNULL(invs.supplier_part_no,'')))
    END AS supplier_part_no,
    
    im.product_type,
    CAST(im.price1 AS FLOAT) AS price1,
    CAST(im.price2 AS FLOAT) AS price2,
    CAST(im.price3 AS FLOAT) AS price3,
    CAST(im.price4 AS FLOAT) AS price4,
    im.class_id2,
    im.class_id3,
    im.class_id4,
    im.class_id5,
    im.extended_desc,
    im.default_sales_discount_group,
    pf.price_family_id,
    il.stockable,
    invs.supplier_id,
    il.delete_flag,
    Wlii.discontinued,
    ivud.calculated_abcd_class

FROM
    inv_mast AS im
    LEFT JOIN inventory_supplier AS invs ON invs.inv_mast_uid = im.inv_mast_uid
    LEFT JOIN inventory_supplier_x_loc AS isxl ON isxl.inventory_supplier_uid = invs.inventory_supplier_uid
    LEFT JOIN price_family AS pf ON pf.price_family_uid = im.default_price_family_uid
    LEFT JOIN inv_loc AS il ON il.inv_mast_uid = im.inv_mast_uid AND il.location_id = isxl.location_id
    LEFT JOIN Loc13ItemInfo AS Wlii ON Wlii.inv_mast_uid = im.inv_mast_uid
    LEFT JOIN supplier AS s ON s.supplier_id = invs.supplier_id
    LEFT JOIN inv_mast_ud ivud ON im.inv_mast_uid = ivud.inv_mast_uid

WHERE
    im.delete_flag <> 'Y'
    AND isxl.primary_supplier <> 'N'
    --## Parameters used in SQL Report Server. DECLARE if debugging
    AND s.supplier_id = @SupplierID
    AND isxl.location_id = @LocationID

ORDER BY 1
