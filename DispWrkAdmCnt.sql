-- *** SqlDbx Personal Edition ***
-- !!! Not licensed for commercial use beyound 90 days evaluation period !!!
-- For version limitations please check http://www.sqldbx.com/personal_edition.htm
-- Number of queries executed: 3320, number of rows retrieved: 10088875

SELECT a.ORDER_MED_ID
,count(a.order_med_id) "ADMIN_CNT"
--,a.order_med_id
--,MAX(a.ADMIN_DISPDATREAL) "ADMIN_DISPREAL"
,a.ADMIN_DISPDATREAL "ADMIN_DISPREAL"
--,a.TAKEN_TIME
,MAX(a.MAR_ACTION)   "MAR_ACTION"
--,max(a.TAKEN_TIME) "TAKEN_TIME"
FROM
(
--                SELECT *
                SELECT distinct
                odiadm.ORDER_MED_ID
                ,odiadm.CONTACT_DATE_REAL
----                ,odiadm.ORD_CNTCT_TYPE_C
--                ,odiadm.CONTACT_DATE
                ,odiadm.INP_ADMIN_LINE_NO
                ,odiadm.INP_ADMIN_DISP_LNK
                ,odiadm.ADMIN_DISPDATREAL     ----- Contact Date Real of the dispense contact that corresponds to this administration contact
--                ,odiadm.DISP_MED_CNTCT_ID
                  ,mar.mar_ord_dat
--                ,odi2.NUM_DOSES_TO_SUPPLY
                ,odiadm.DISPENSE_CODE_C
                , mar.LINE
                ,mar.TAKEN_TIME
                ,mar.USER_ID
--                  ,mar.INFUSION_RATE
                ,odiadm.RX_DISPENSE_CART_ID
                ,zcmr.NAME "MAR_ACTION"
--                FROM ORDMED ordadm
--                FROM F_RX_ORDER frx
              from  ORDER_DISP_INFO odiadm
--                LEFT outer JOIN ORDER_DISP_INFO odiadm ON odiadm.ORDER_MED_ID = frx.ORDER_MED_ID AND odiadm.CONTACT_DATE_REAL = frx.ORDERING_DATE_REAL
--                INNER JOIN order_disp_info_2 odi2 ON odiadm.ORDER_MED_ID = odi2.ORDER_ID
                LEFT OUTER JOIN mar_admin_info mar ON odiadm.ORDER_MED_ID = mar.ORDER_MED_ID AND odiadm.INP_ADMIN_LINE_NO = mar.LINE
--                INNER JOIN MAR_ADDL_INFO mar_info ON odiadm.ORDER_MED_ID = mar_info.ORDER_ID AND odiadm.CONTACT_DATE_REAL = mar_info.CONTACT_DATE_REAL
                LEFT OUTER JOIN ZC_MAR_RSLT zcmr ON mar.MAR_ACTION_C = zcmr.RESULT_C
                WHERE
                mar.MAR_ACTION_C IN ('1', '6', '102', '105', '113', '114', '115','1002')
--                AND odiadm.ORD_CNTCT_TYPE_C = 7
--                AND odiadm.MEDADMIN_STATUS_C <> 1
                AND 
                odiadm.ORDER_MED_ID = 504865862
          -----504148311.00    589704675   508013224  497662698  524222297 587058292  504865862
          ------ 524222297 has nulls for ADMIN_DISPREAL and mar_action new bag

--                AND odiadm.ADMIN_DISPDATREAL = 65761.05
--                AND TRUNC(mar.TAKEN_TIME) = '19-jan-2021'

)a
          where 
        (case  when a. DISPENSE_CODE_C IS null then 1
            when a.DISPENSE_CODE_C <> 7  then 1
            else 0
            END
           ) = 1

      GROUP BY a.ORDER_MED_ID,a.ADMIN_DISPDATREAL

--      GROUP BY a.ORDER_MED_ID,a.ADMIN_DISPDATREAL,a.TAKEN_TIME
--      GROUP BY a.ORDER_MED_ID,a.TAKEN_TIME


--SELECT *
--FROM ZC_MAR_RSLT zcmr
--WHERE
--zcmr.RESULT_C IN ('1', '6', '102', '105', '113', '114', '115','1002')



--SELECT distinct
--odi_disp.ORDER_MED_ID
--,odi_disp.CONTACT_DATE_REAL
--,odi_disp.ORD_CNTCT_TYPE_C
--,odi_admin.ADMIN_DISPDATREAL
--,odi_admin.ORD_CNTCT_TYPE_C
--,odi_admin.INP_ADMIN_LINE_NO
--,mar.LINE
--,mar.TAKEN_TIME
--FROM ORDER_DISP_INFO odi_disp
--INNER JOIN order_disp_info odi_admin ON odi_disp.CONTACT_DATE_REAL = odi_admin.ADMIN_DISPDATREAL AND odi_disp.ORDER_MED_ID = odi_admin.ORDER_MED_ID
--LEFT OUTER JOIN mar_admin_info mar ON odi_admin.ORDER_MED_ID = mar.ORDER_MED_ID AND odi_admin.INP_ADMIN_LINE_NO = mar.LINE
--
--WHERE 
--odi_disp.ORDER_MED_ID = 508013224
--AND odi_disp.ORD_CNTCT_TYPE_C = 5
--AND odi_admin.ORD_CNTCT_TYPE_C = 7