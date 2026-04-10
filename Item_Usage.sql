--Item Usage
--Purpse: Initial discovery of items that have not been used for over 10 years. This will be the start of the data cleanup on items in P21

--This WITH takes all the items on orders from now to 10 years back
WITH used_items AS (
SELECT
    im.item_id AS 'Item ID',
    im.inv_mast_uid
    --For debugging/review
    -- CAST(im.date_created AS DATE) AS 'Date Created',
    -- im.product_type AS 'Product Type',
    -- SUM(ol.qty_ordered) AS 'Qty Ordered'

FROM
    oe_hdr AS oh
    LEFT JOIN oe_line AS ol ON oh.order_no = ol.order_no
    LEFT JOIN inv_mast AS im ON ol.inv_mast_uid = im.inv_mast_uid

WHERE
    im.delete_flag <> 'Y'
    AND oh.date_created BETWEEN '2016-1-01' AND DATEADD(day, 1, CAST(GETDATE() AS DATE))
    -- AND oh.projected_order = 'Y'
    AND oh.delete_flag <> 'Y'
    AND oh.cancel_flag <> 'Y'
    AND ol.cancel_flag <> 'Y'
    AND ol.delete_flag <> 'Y'
    AND ol.disposition <> 'C'

GROUP BY im.item_id, im.inv_mast_uid-- im.date_created, im.product_type
)

SELECT
    im.inv_mast_uid,
    im.item_id,
    CAST(im.date_created AS DATE) AS 'Date Created',
    im.product_type AS 'Product Type',
    --For debugging
    -- SUM(ol.qty_ordered) AS 'Qty Ordered'
    CAST(MAX(oh.date_created) AS DATE) AS 'Latest Order'

FROM 
    inv_mast AS im
    LEFT JOIN oe_line AS ol ON ol.inv_mast_uid = im.inv_mast_uid
    LEFT JOIN oe_hdr AS oh ON oh.order_no = ol.order_no

WHERE NOT EXISTS (
    SELECT 1 
    FROM used_items AS ui 
    WHERE ui.inv_mast_uid = im.inv_mast_uid
    )
    AND oh.delete_flag <> 'Y'
    AND oh.cancel_flag <> 'Y'
    AND ol.cancel_flag <> 'Y'
    AND ol.delete_flag <> 'Y'
    AND ol.disposition <> 'C'
    AND im.delete_flag <> 'Y'

GROUP BY im.item_id, im.inv_mast_uid, im.date_created, im.product_type

ORDER BY 5 DESC
 
--For spot checking 
--SELECT oe_hdr.order_no, oe_hdr.customer_id, oe_hdr.date_created, oe_hdr.delete_flag, oe_hdr.cancel_flag, oe_line.cancel_flag , oe_line.delete_flag, oe_line.disposition FROM oe_hdr LEFT JOIN oe_line ON oe_hdr.order_no = oe_line.order_no LEFT JOIN inv_mast ON inv_mast.inv_mast_uid = oe_line.inv_mast_uid WHERE inv_mast.item_id = 'MITSU R01E96201XX'