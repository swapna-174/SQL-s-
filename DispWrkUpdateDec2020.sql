WITH DISPSTEP1
AS
(

                SELECT distinct
                odi.ACTION_INSTANT
                ,odi.CONTACT_DATE
                ,odi.ORDER_MED_ID
                ,odi.CONTACT_DATE_REAL
                ,frxeq.EQUIV_MED_DISP_QTY
                ,zunit.NAME

                FROM ORDER_DISP_INFO odi
                LEFT OUTER JOIN ord_act_ord_info ordact ON odi.ORDER_MED_ID = ordact.ORDER_ID AND odi.CONTACT_DATE_REAL = ordact.ORDER_DATE
                LEFT OUTER JOIN order_disp_info_2 odi2 ON odi.ORDER_MED_ID = odi2.ORDER_ID AND odi.CONTACT_DATE_REAL = odi2.CONTACT_DATE_REAL
                LEFT OUTER JOIN f_rx_equiv_disp_qty frxeq ON odi.ORDER_MED_ID = frxeq.ORDER_MED_ID AND odi.CONTACT_DATE_REAL = frxeq.CONTACT_DATE_REAL
                LEFT OUTER JOIN zc_med_unit zunit ON frxeq.DISP_QTYUNIT_C = zunit.DISP_QTYUNIT_C


                WHERE
                odi.ORD_CNTCT_TYPE_C = 5
--                AND odi.ORDER_MED_ID =315337894
--                AND odi.ACTION_INSTANT >= '1-jan-2019' AND odi.ACTION_INSTANT <= '31-jan-2019'
                ORDER BY odi.ORDER_MED_ID,odi.ACTION_INSTANT

)
, ORDMED
AS
(
                SELECT 
                 om.ORDER_MED_ID
                ,om.PAT_ENC_CSN_ID
                ,om.DISPLAY_NAME
                ,om.ORDER_INST
                ,TRUNC(om.ORDERING_DATE) "ORD_DATE"
                ,dispmed.CONTACT_DATE_REAL
                ,dispmed.ACTION_INSTANT
                ,zcdeadisp.NAME
                ,dispmed.EQUIV_MED_DISP_QTY
                ,dispmed.NAME "EQUIV_UNIT"

                FROM DISPSTEP1 dispmed
                LEFT OUTER JOIN ORDER_MED om ON dispmed.ORDER_MED_ID = om.ORDER_MED_ID
                LEFT OUTER JOIN order_medinfo omi ON om.ORDER_MED_ID = omi.ORDER_MED_ID
                LEFT OUTER JOIN clarity_medication cmdisp ON omi.DISPENSABLE_MED_ID = cmdisp.MEDICATION_ID
                LEFT OUTER JOIN RX_MED_TWO rx2disp ON cmdisp.MEDICATION_ID = rx2disp.MEDICATION_ID
                LEFT OUTER JOIN ZC_DEA_CLASS_CODE zcdeadisp ON rx2disp.DEA_CLASS_CODE_C = zcdeadisp.DEA_CLASS_CODE_C

)

,MARMED
AS
(
                SELECT a.ORDER_MED_ID
                ,count(a.order_med_id) "BLKCNT"
                ,max(a.ADMIN_DISPDATREAL) "ADMIN_DISPREAL"
                ,max(a.DISPENSE_CODE_C)   "DISPENSE_CODE_C"             
                ,max(a.TAKEN_TIME) "TAKEN_TIME"
                FROM
                (

                SELECT distinct
                odiadm.ORDER_MED_ID
                ,odiadm.CONTACT_DATE_REAL
                ,odiadm.ORD_CNTCT_TYPE_C
                ,odiadm.CONTACT_DATE
                ,odiadm.INP_ADMIN_LINE_NO
                ,odiadm.INP_ADMIN_DISP_LNK
                ,odiadm.ADMIN_DISPDATREAL
                ,odiadm.DISPENSE_CODE_C
                , mar.LINE
                ,mar.TAKEN_TIME
                ,mar.USER_ID
                ,odiadm.RX_DISPENSE_CART_ID
                FROM DISPSTEP1 ordadm
                LEFT outer JOIN ORDER_DISP_INFO odiadm ON odiadm.ORDER_MED_ID = ordadm.ORDER_MED_ID 
                LEFT OUTER JOIN mar_admin_info mar ON odiadm.ORDER_MED_ID = mar.ORDER_MED_ID AND odiadm.INP_ADMIN_LINE_NO = mar.LINE
                WHERE
                  mar.MAR_ACTION_C IN ('1', '6', '102', '105', '113', '114', '115','1002')
)a
      where 
        (case 
            when a.DISPENSE_CODE_C = 7 then 1
            else 0
            END
           ) = 1

      GROUP BY a.ORDER_MED_ID

)

,ADMINREALCNT
AS
(
            SELECT a.ORDER_MED_ID
            ,count(a.order_med_id) "ADMIN_CNT"
            ,a.ADMIN_DISPDATREAL "ADMIN_DISPREAL"
            ,max(a.TAKEN_TIME) "TAKEN_TIME"

            FROM
            (

                SELECT distinct
                 odiadm.ORDER_MED_ID
                ,odiadm.CONTACT_DATE_REAL
                ,odiadm.ADMIN_DISPDATREAL
                ,mar.TAKEN_TIME
                                ,odiadm.DISPENSE_CODE_C

                FROM DISPSTEP1 ordadm
                LEFT outer JOIN ORDER_DISP_INFO odiadm ON odiadm.ORDER_MED_ID = ordadm.ORDER_MED_ID 
                LEFT OUTER JOIN mar_admin_info mar ON odiadm.ORDER_MED_ID = mar.ORDER_MED_ID AND odiadm.INP_ADMIN_LINE_NO = mar.LINE
                WHERE
              mar.MAR_ACTION_C IN ('1', '6', '102', '105', '113', '114', '115','1002')
)a
          where 
        (case  when a. DISPENSE_CODE_C IS null then 1
            when a.DISPENSE_CODE_C <> 7  then 1
            else 0
            END
           ) = 1

      GROUP BY a.ORDER_MED_ID,a.ADMIN_DISPDATREAL
            ORDER BY a.ADMIN_DISPDATREAL


) 


SELECT *
FROM
(
SELECT distinct
  vrxd.ORDER_MED_ID           ----- UNIQUE IDENTIFIER 
  ,vrxd.ACTION_INSTANT  "DISPENSE_DATE"  ----- UNIQUE IDENTIFIER
  ,marmd.BLKCNT  "BULK_ADMIN_COUNT"   ----- UPDATE COLUMN
  ,marcnt.ADMIN_CNT "ADMIN_COUNT"    ----- UPDATE COLUMN
    ,TO_CHAR(CAST(marcnt.TAKEN_TIME AS date), 'MM/DD/YYYY') "ADMIN_DATE"     ----- UPDATE COLUMN
  ,to_char(CAST(marcnt.TAKEN_TIME AS DATE), 'hh24:mi:ss AM')  "ADMIN_TIME"   ----- UPDATE COLUMN
  ,vrxd.NAME  "DEA_CLASS"              ----- NEW COLUMN
  ,vrxd.EQUIV_MED_DISP_QTY "IMPLIED_QTY"  ----- NEW COLUMN
  ,vrxd.EQUIV_UNIT  "IMPLIED_QTY_UNIT"   ----- NEW COLUMN

  ,rank() over ( partition by vrxd.ORDER_MED_ID,vrxd.CONTACT_DATE_REAL order by   vrxd.ACTION_INSTANT  ,RowNum) "IGNORE_THIS_COLUMN"
FROM ORDMED vrxd
LEFT OUTER JOIN MARMED marmd ON vrxd.ORDER_MED_ID=marmd.ORDER_MED_ID AND vrxd.CONTACT_DATE_REAL = marmd.ADMIN_DISPREAL
LEFT OUTER JOIN ADMINREALCNT marcnt ON vrxd.ORDER_MED_ID=marcnt.ORDER_MED_ID AND vrxd.CONTACT_DATE_REAL = marcnt.ADMIN_DISPREAL
                   
ORDER BY vrxd.ACTION_INSTANT
)
WHERE IGNORE_THIS_COLUMN = 1

