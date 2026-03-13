WITH ORDMED
as

(
    SELECT 
    om.ORDER_MED_ID
    ,om.PAT_ENC_CSN_ID
    ,om.DESCRIPTION
    ,om.DOSE_UNIT_C
    ,om.MED_ROUTE_C
    ,om.HV_DISCR_FREQ_ID
    ,coalesce(om.DISPLAY_NAME,om.AMB_MED_DISP_NAME) "DISPLAY_NAME"
    ,om.ORDERING_MODE_C
    ,om.ORDER_STATUS_C
    ,om.PAT_LOC_ID
    ,TRUNC(om.ORDERING_DATE) "ORD_DATE"
    ,om.AMB_MED_DISP_NAME
    ,om.MEDICATION_ID
    ,om.MIN_DISCRETE_DOSE
    ,om.order_start_time
    ,om.ORDER_END_TIME
    ,om.PAT_ID
    ,om.ORDER_PRIORITY_C
    ,zcop.NAME "PRIORITY"
    ,cmdisp.MEDICATION_ID  "ERX_NUMBER"
    ,cmdisp.NAME "ERX_NAME"
    ,omet.ORDER_DTTM
    ,cmdisp.FORM

    FROM ORDER_MED om
    LEFT OUTER JOIN order_medinfo omi ON om.ORDER_MED_ID = omi.ORDER_MED_ID
    LEFT OUTER JOIN clarity_medication cmdisp ON omi.DISPENSABLE_MED_ID = cmdisp.MEDICATION_ID
    LEFT OUTER JOIN ZC_ORDER_PRIORITY zcop ON om.ORDER_PRIORITY_C = zcop.ORDER_PRIORITY_C
    LEFT OUTER join order_metrics omet ON om.ORDER_MED_ID = omet.ORDER_ID

    WHERE
--   trunc(om.ORDERING_DATE) >= EPIC_UTIL.EFN_DIN ('{?Start_Date}')
--   AND trunc( om.ORDERING_DATE) <= EPIC_UTIL.EFN_DIN ('{?End_Date}')
--    om.ORDER_MED_ID = 576126871
    om.ORDERING_DATE >= '1-mar-2021'
    AND om.ORDERING_DATE < '31-mar-2021'
    AND om.PAT_LOC_ID IN (1000100009,1000100010,1000100023)
    
)

,MIXMED
as
(
    SELECT 
    omix.ORDER_MED_ID
    ,omix.LINE
    ,omix.MEDICATION_ID
    ,omix.MIN_DOSE_AMOUNT
    ,omix.DOSE_UNIT_C
    ,omix.MIN_CALC_DOSE_AMT
    ,omix.CALC_DOSE_UNIT_C
    ,ominfo.CALC_MIN_DOSE
    ,cm.NAME
    ,ominfo.MIXTURE_TYPE_C
    ,zmu.NAME "MIXDOSEUNIT"
    ,zmucalc.NAME "CALCDOSEUNIT"
    FROM ORDMED ord1
    INNER JOIN ORDER_MEDMIXINFO omix ON ord1.ORDER_MED_ID = omix.ORDER_MED_ID and omix.LINE = 1
    LEFT OUTER JOIN order_medinfo ominfo ON ord1.ORDER_MED_ID = ominfo.ORDER_MED_ID AND ominfo.MIXTURE_TYPE_C = 1
    LEFT OUTER JOIN clarity_medication cm ON omix.MEDICATION_ID = cm.MEDICATION_ID
    LEFT OUTER JOIN ZC_MED_UNIT zmu ON omix.DOSE_UNIT_C = zmu.DISP_QTYUNIT_C
    LEFT OUTER JOIN ZC_MED_UNIT zmucalc ON omix.DOSE_UNIT_C = zmucalc.DISP_QTYUNIT_C

)
,MARMED
AS
(
   SELECT --*
   mar.ORDER_MED_ID
   ,mar.MAR_ENC_CSN "ADMINTOT"
   ,to_number(mar.SIG)    "MARDOSE"
   ,mar.ROUTE_C "MARROUTEC"
   ,MAR_ACTION_C
   ,zar.NAME  "MARROUTE"
   ,zmu.NAME  "MARDOSEUNIT"
   ,mar.PAT_SUPPLIED_YN "PATSUPPLY"
   ,dep.DEPARTMENT_NAME
   ,dep.DEPARTMENT_ID
   ,mar.TAKEN_TIME
   FROM ORDMED ord2
   LEFT OUTER JOIN MAR_ADMIN_INFO mar ON ord2.ORDER_MED_ID = mar.ORDER_MED_ID
   LEFT OUTER JOIN ZC_MED_UNIT zmu ON mar.DOSE_UNIT_C = zmu.DISP_QTYUNIT_C
   LEFT OUTER JOIN ZC_ADMIN_ROUTE zar ON mar.ROUTE_C = zar.MED_ROUTE_C
   LEFT OUTER JOIN clarity_dep dep ON mar.MAR_ADMIN_DEPT_ID = dep.DEPARTMENT_ID
   WHERE
   mar.MAR_ACTION_C IN ('1', '6', '102', '105', '113', '114', '115','1002')

)
,MARMED1
AS
(

   SELECT
   mar.ORDER_MED_ID
   ,MIN(mar.TAKEN_TIME)  "FIRST_TAKEN_DTTM"

   FROM ORDMED ord2
   LEFT OUTER JOIN MAR_ADMIN_INFO mar ON ord2.ORDER_MED_ID = mar.ORDER_MED_ID
   WHERE
   mar.MAR_ACTION_C IN ('1', '6', '102', '105', '113', '114', '115','1002')
   GROUP BY mar.ORDER_MED_ID
)

,PHRM
AS

    (
       SELECT *
       FROM
       (
    
        SELECT distinct
        odi.ORDER_MED_ID
        ,odi.FIRSTDOSES_PHR_ID
        ,phr.PHARMACY_NAME
        ,odi.PHARMACY_USR_ID
        ,odi.VERIFY_CONT_DAT
        ,odi.DISP_STAT_NAME
        ,ser.PROV_NAME "PHR"
        ,odi.ACTION_INSTANT "PHR_DTTM"
        ,odi.MED_VERIFY_TYPE_C
        ,odi.DISP_MED_CNTCT_ID
        ,zcmvt.NAME "VERIFY_TYPE"
        ,ordrxt.LINE
        ,ordrxt.RXQ_REASON_C
        ,ordrxt.RX_VERIFY_INSTANT
        ,odi.ORD_CNTCT_TYPE_C
        ,ordrxt.RX_UNQUEUE_REASON_C
        ,rank() over ( partition by odi.ORDER_MED_ID order by   odi.ACTION_INSTANT,odi.DISP_MED_CNTCT_ID  ,RowNum) rank1
    
        FROM ORDMED ordphrm
        INNER JOIN order_disp_info odi ON odi.ORDER_MED_ID = ordphrm.ORDER_MED_ID
        LEFT OUTER JOIN RX_PHR phr ON odi.FIRSTDOSES_PHR_ID = phr.PHARMACY_ID
        LEFT OUTER JOIN clarity_ser ser ON odi.PHARMACY_USR_ID = ser.USER_ID
        LEFT OUTER JOIN ORDER_RXVER_TRACE ordrxt ON odi.ORDER_MED_ID = ordrxt.ORDER_MED_ID
        LEFT OUTER JOIN ZC_MED_VERIFY_TYPE zcmvt ON odi.MED_VERIFY_TYPE_C = zcmvt.MED_VERIFY_TYPE_C
        WHERE
         odi.ORD_CNTCT_TYPE_C IN (4,13)  --Verify, Pend Verify
         AND odi.PHARMACY_USR_ID <> '1' --- EPIC USER
        )
        WHERE rank1 = 1 
      ) 
      
 ,DISPTYP
 AS
 (
                SELECT distinct
                odi.ACTION_INSTANT
                ,odi.CONTACT_DATE
                ,odi.ORDER_MED_ID
                ,odi.CONTACT_DATE_REAL   
                ,odi.DISPENSE_PHR_ID
                ,CHKDSP.CHECKED_ACTUSER "CHECK_USERNM"
                ,CHKDSP.CHECKED_ACTTM "CHECK_DTTM"

                ,odi.DISP_UNIT_ID   "DEST_DEPARTMENT_ID"
                ,dep.DEPARTMENT_NAME "DEST_DEPARTMENT"
                ,zcdc.NAME  "DISP_CODE"
                ,CASE WHEN (odi.DISP_TYPE_C IN (5,9,14) AND COALESCE(phr.PHYSICAL_TYPE_C,0)=2) 
                                                                OR (odi.DISP_TYPE_C=15 AND COALESCE(ovr.ORD_ATTRIBUTE_C,0)<>1)
                                                THEN 'ADS DISPENSE'
                                                WHEN (odi.DISP_TYPE_C NOT IN (5,6,9,12,14,21) AND COALESCE(ovr.ORD_ATTRIBUTE_C,0)=1)
                                                THEN 'ADS OVERRIDE DISPENSE'
                                                WHEN (odi.DISP_TYPE_C IN (6,10,12,21))
                                                THEN 'CART DISPENSE'
                                                WHEN (odi.DISP_TYPE_C IN (5,9,14) AND COALESCE(phr.PHYSICAL_TYPE_C,0) <> 2)
                                                THEN 'FIRST DOSE DISPENSE'
                                                WHEN (COALESCE(ovr.ORD_ATTRIBUTE_C,0)<>1 AND odi.DISP_TYPE_C IN (8,11))
                                                THEN 'REDISPENSE'
                                                ELSE NULL --not mapped to General dispense type
                                                END AS GEN_DISP_TYPE_C


                FROM ORDMED ordmdisp
                INNER JOIN ORDER_DISP_INFO odi ON ordmdisp.ORDER_MED_ID = odi.ORDER_MED_ID
                LEFT OUTER JOIN ord_act_ord_info ordact ON odi.ORDER_MED_ID = ordact.ORDER_ID AND odi.CONTACT_DATE_REAL = ordact.ORDER_DATE
                LEFT OUTER JOIN order_disp_info_2 odi2 ON odi.ORDER_MED_ID = odi2.ORDER_ID AND odi.CONTACT_DATE_REAL = odi2.CONTACT_DATE_REAL
                LEFT OUTER JOIN ORDER_ATTRIBUTE ovr ON ovr.ORDER_ID = odi.ORDER_MED_ID and ovr.LINE = 1 -- Cabinet Override 
                LEFT OUTER JOIN RX_PHR phr ON odi.DISPENSE_PHR_ID = phr.PHARMACY_ID
                LEFT OUTER JOIN zc_physical_type zcpt ON phr.PHYSICAL_TYPE_C = zcpt.PHYSICAL_TYPE_C
                LEFT OUTER JOIN ZC_DISPENSE_CODE zcdc ON odi.DISPENSE_CODE_C = zcdc.DFLT_DISP_CODE_C
                LEFT OUTER JOIN clarity_dep dep ON odi.DISP_UNIT_ID = dep.DEPARTMENT_ID
    LEFT OUTER JOIN 
                  (
                                                SELECT *
                                                FROM 
                                                (
                                                     SELECT 
                                                     actchk.ACTION_DTTM_LOCAL          ----- UPDATED ON 12/23/2020
                                                     ,actchk.USER_ID
                                                     ,actchk.ACTION_ID
                                                     ,actchk.ACTION_TYPE_C
                                                     from ord_act_ot actchk 
                                                     WHERE 
                                                     actchk.ACTION_TYPE_C IN ('210','200')
                                                     
                                       )
                                                     pivot
                                                     (
                                                       max(ACTION_DTTM_LOCAL) "ACTTM"       ----- UPDATED ON 12/23/2020
                                                       ,max(USER_ID)  "ACTUSER"
                                                       FOR ACTION_TYPE_C IN  ('210' AS CHECKED,'200' AS PREP )
                                                      ) 
                     
                   ) CHKDSP ON ordact.ACTION_ID = CHKDSP.ACTION_ID 


                WHERE
                odi.ORD_CNTCT_TYPE_C = 5
 
 )     
      
      
      
    SELECT distinct
     ORDM.ORDER_MED_ID
     ,ORDM.PAT_ENC_CSN_ID
    ,ORDM.ERX_NUMBER
    ,ORDM.ERX_NAME
    ,coalesce(coalesce(ORDM.MIN_DISCRETE_DOSE, mixmd.MIN_DOSE_AMOUNT),MARDOSE) "DOSE"
    ,coalesce(coalesce(zmu.NAME ,mixmd.MIXDOSEUNIT),MARDOSEUNIT)      "DOSE_UNIT"
    ,coalesce(ominfo.CALC_MIN_DOSE,mixmd.MIN_CALC_DOSE_AMT) "DOSE_CALC"
    ,coalesce(zmucalc.NAME ,mixmd.CALCDOSEUNIT)      "CALC_DOSE_UNIT"
    ,CASE WHEN mixmd.MIXTURE_TYPE_C >= 1 then 'Y' ELSE 'N' END "IS_MED_MIXTURE"
    ,coalesce(zar.NAME,marmd.MARROUTE) "MED_ROUTE"
    ,ORDM.FORM  "FORMULATION"

    ,ipfq.FREQ_NAME "FREQUENCY"
    ,zom.NAME "ORDER_MODE_TYPE"
    ,zcps.NAME  "PATIENT_CLASS"
    ,zords.NAME "ORD_STATUS"
    ,PHRM.PHARMACY_NAME "FIRST_DISPENSE_PHARMACY_UNIT"
    ,dep.DEPARTMENT_NAME "ORD_PATIENT_LOCATION"
    ,PHRM.PHR "VERIFIED_RPH"
    ,PHRM.PHR_DTTM "VERIFIED_DTTM"
    ,disp.CHECK_USERNM
    ,disp.CHECK_DTTM
    ,ORDM.ORDER_DTTM "ORDERING_DTTM"
    ,ORDM.PRIORITY "ORDER_PRIORITY"
    ,odpar.ORD_DOSING_WEIGHT "DOSING_WEIGHT_KG"
    ,marmd1.FIRST_TAKEN_DTTM
    ,marmd.TAKEN_TIME
    ,disp.GEN_DISP_TYPE_C  "ACTION_TYPE"
    ,disp.ACTION_INSTANT   "ACTION_TAKEN"
    ,marmd.DEPARTMENT_NAME  "ADMIN_PATIENT_LOCATION"
    FROM ORDMED ORDM
    LEFT OUTER JOIN PAT_ENC_HSP hsp ON ORDM.PAT_ENC_CSN_ID = hsp.PAT_ENC_CSN_ID
    LEFT OUTER JOIN HSP_ACCOUNT har ON hsp.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
    LEFT OUTER JOIN MIXMED mixmd ON ORDM.ORDER_MED_ID = mixmd.ORDER_MED_ID
    LEFT OUTER JOIN MARMED marmd ON ORDM.ORDER_MED_ID = marmd.ORDER_MED_ID
    LEFT OUTER JOIN MARMED1 marmd1 ON ORDM.ORDER_MED_ID = marmd1.ORDER_MED_ID
    LEFT OUTER JOIN PHRM PHRM ON ORDM.ORDER_MED_ID = PHRM. ORDER_MED_ID
    LEFT OUTER JOIN DISPTYP disp ON ORDM.ORDER_MED_ID = disp.ORDER_MED_ID
    LEFT OUTER JOIN order_medinfo ominfo ON ORDM.ORDER_MED_ID = ominfo.ORDER_MED_ID
    INNER JOIN patient pat ON ORDM.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN ZC_ACCT_BASECLS_HA zcps ON har.ACCT_BASECLS_HA_C = zcps.ACCT_BASECLS_HA_C
    LEFT OUTER JOIN ZC_MED_UNIT zmu ON ORDM.DOSE_UNIT_C = zmu.DISP_QTYUNIT_C
    LEFT OUTER JOIN ZC_MED_UNIT zmucalc ON ominfo.CALC_DOSE_UNIT_C = zmucalc.DISP_QTYUNIT_C
    LEFT OUTER JOIN ZC_ADMIN_ROUTE zar ON ORDM.MED_ROUTE_C = zar.MED_ROUTE_C
    LEFT OUTER JOIN IP_FREQUENCY ipfq ON ORDM.HV_DISCR_FREQ_ID = ipfq.FREQ_ID
    LEFT OUTER JOIN ZC_ORDERING_MODE zom ON ORDM.ORDERING_MODE_C = zom.ORDERING_MODE_C
    LEFT OUTER JOIN ZC_ORDER_STATUS zords ON ORDM.ORDER_STATUS_C = zords.ORDER_STATUS_C
    LEFT OUTER JOIN clarity_dep dep ON ORDM.PAT_LOC_ID = dep.DEPARTMENT_ID
    LEFT OUTER JOIN ZC_ORDER_PRIORITY zcop ON ORDM.ORDER_PRIORITY_C = zcop.ORDER_PRIORITY_C
    LEFT OUTER JOIN ORD_DOSING_PARAMS odpar ON ORDM.ORDER_MED_ID = odpar.ORDER_ID
    WHERE
     har.ACCT_BASECLS_HA_C<>2
     AND marmd.DEPARTMENT_ID IN (1000100009,576455021)
   ORDER BY ORDM.PAT_ENC_CSN_ID,ORDM.ORDER_MED_ID,marmd.TAKEN_TIME

