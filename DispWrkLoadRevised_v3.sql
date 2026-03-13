WITH DISPSTEP1
AS
(

                SELECT distinct
                odi.ACTION_INSTANT
                ,odi.CONTACT_DATE
                ,EXTRACT(HOUR FROM CAST(odi.ACTION_INSTANT as timestamp)) "HOUR"
                ,ordact.ACTION_ID
                ,CHKDSP.PREP_ACTTM "PREP_DTTM"
                ,CHKDSP.PREP_ACTUSER "PREP_USERID"
                ,empprep.NAME  "PREPPED_BY"
                ,odi.PHARMACY_USR_ID
                ,odi.ORDER_MED_ID
                ,odi.CONTACT_DATE_REAL   
                ,odi.DISPENSE_PHR_ID
                ,phr.PHARMACY_NAME
                ,zcpt.NAME "PHYSICAL_TYPE"
                ,odi.DISP_UNIT_ID   "DEST_DEPARTMENT_ID"
                ,dep.DEPARTMENT_NAME "DEST_DEPARTMENT"
                ,zcdc.NAME  "DISP_CODE"
                ,CASE WHEN returned.FIRST_RETURN_DATE_REAL IS NOT NULL THEN 'Y' ELSE 'N' END "DISP_RETURNED_YN"
                ,phr.PHYSICAL_TYPE_C
                ,CASE WHEN (odi.DISP_TYPE_C IN (5,9,14) AND COALESCE(phr.PHYSICAL_TYPE_C,0)=2) 
                                                                OR (odi.DISP_TYPE_C=15 AND COALESCE(ovr.ORD_ATTRIBUTE_C,0)<>1)
                                                THEN 1 --ADS DISPENSE
                                                WHEN (odi.DISP_TYPE_C NOT IN (5,6,9,12,14,21) AND COALESCE(ovr.ORD_ATTRIBUTE_C,0)=1)
                                                THEN 2 --ADS OVERRIDE DISPENSE
                                                WHEN (odi.DISP_TYPE_C IN (6,10,12,21))
                                                THEN 3 --CART DISPENSE
                                                WHEN (odi.DISP_TYPE_C IN (5,9,14) AND COALESCE(phr.PHYSICAL_TYPE_C,0) <> 2)
                                                THEN 4 --FIRST DOSE DISPENSE
                                                WHEN (COALESCE(ovr.ORD_ATTRIBUTE_C,0)<>1 AND odi.DISP_TYPE_C IN (8,11))
                                                THEN 5 --REDISPENSE
                                                ELSE NULL --not mapped to General dispense type
                                                END AS GEN_DISP_TYPE_C
                  ,CASE WHEN phr.PHYSICAL_TYPE_C = 3 THEN 1 ELSE 0 END AS "DISPROB"
                ,CHKDSP.CHECKED_ACTUSER "CHECK_USERNM"
                ,CHKDSP.CHECKED_ACTTM "CHECK_DTTM"
                ,empchk.NAME  "CHECK_BY"
    ,odi2.FULLY_RETURNED_YN "CART_CANCEL"
    ,PRTER.WORKSTATION_NAME "DISP_PRINTER"
    ,CASE WHEN odi.PHARMACY_USR_ID = 'RXTECH' THEN emprl.DEFAULT_USER_ROLE ELSE  empdisp.NAME END "DISPENSE_USER"
    ,odi.TRIGGER_FILL_YN 
    ,rxcrt.CART_NAME 
    ,DSPACT.ACTION_DTTM_LOCAL          ----- UPDATED 12/23/2020
    ,DSPACT.NAME "DISPENSE_ACTION"
    ,frxeq.EQUIV_MED_DISP_QTY
    ,zunit.NAME

--    ,odi.INP_ADMIN_LINE_NO
    ,CASE WHEN ovr.ORD_ATTRIBUTE_C = 1 THEN 'Y' ELSE 'N' END "ADS_OVERRIDE"
                FROM ORDER_DISP_INFO odi
                LEFT OUTER JOIN ord_act_ord_info ordact ON odi.ORDER_MED_ID = ordact.ORDER_ID AND odi.CONTACT_DATE_REAL = ordact.ORDER_DATE
                LEFT OUTER JOIN order_disp_info_2 odi2 ON odi.ORDER_MED_ID = odi2.ORDER_ID AND odi.CONTACT_DATE_REAL = odi2.CONTACT_DATE_REAL
                LEFT OUTER JOIN f_rx_equiv_disp_qty frxeq ON odi.ORDER_MED_ID = frxeq.ORDER_MED_ID AND odi.CONTACT_DATE_REAL = frxeq.CONTACT_DATE_REAL
               	LEFT OUTER JOIN zc_med_unit zunit ON frxeq.DISP_QTYUNIT_C = zunit.DISP_QTYUNIT_C

    LEFT OUTER JOIN CLARITY_DEP dep ON odi.DISP_UNIT_ID = dep.DEPARTMENT_ID
    LEFT OUTER JOIN CLARITY_LOC locrev ON dep.REV_LOC_ID=locrev.LOC_ID
    LEFT OUTER JOIN CLARITY_LOC parloc ON locrev.HOSP_PARENT_LOC_ID = parloc.LOC_ID

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
  
                LEFT OUTER JOIN 
                  (
                                                     SELECT 
                                                     actchk.ACTION_DTTM_LOCAL       ---UPDATED on 12/23/2020
                                                     ,actchk.USER_ID
                                                     ,actchk.ACTION_ID
                                                     ,actchk.ACTION_TYPE_C
                                                     ,zcact2.NAME
                                                     from ord_act_ot actchk 
                                                     LEFT OUTER JOIN ZC_ACTION_TYPE_2 zcact2 ON actchk.ACTION_TYPE_C = zcact2.ACTION_TYPE_2_C
                                                     WHERE 
                                                     actchk.ACTION_TYPE_C NOT IN ('210','200')
                     
                   ) DSPACT ON ordact.ACTION_ID = DSPACT.ACTION_ID    
                    
  LEFT OUTER JOIN
    (
       SELECT 
                                rxrpt.ORDER_MED_ID
                                ,rxrpt.REPORT_DAT
                                ,lws.WORKSTATION_NAME
                                FROM ORDER_RX_RPT_HXDAT  rxrpt
                                INNER JOIN ORDER_RX_RPT_HX ordrx ON rxrpt.ORDER_MED_ID = ordrx.ORDER_MED_ID AND rxrpt.LINE = ordrx.LINE
                                LEFT OUTER JOIN CLARITY_LWS lws ON ordrx.DESTINATION_ID = lws.WORKSTATION_ID
                                WHERE
                                ordrx.REPORT_USER_ID IS NOT NULL
                                AND ordrx.DESTINATION_ID <> '1471'
                                GROUP BY rxrpt.ORDER_MED_ID, rxrpt.REPORT_DAT, lws.WORKSTATION_NAME

    )PRTER ON PRTER.ORDER_MED_ID = odi.ORDER_MED_ID AND PRTER.REPORT_DAT = odi.CONTACT_DATE_REAL 

                LEFT OUTER JOIN clarity_emp empprep ON CHKDSP.PREP_ACTUSER = empprep.USER_ID
                LEFT OUTER JOIN clarity_emp empchk ON CHKDSP.CHECKED_ACTUSER = empchk.USER_ID
                LEFT OUTER JOIN clarity_emp empdisp ON odi.PHARMACY_USR_ID = empdisp.USER_ID
                LEFT OUTER JOIN clarity_emp_role emprl ON empdisp.USER_ID = emprl.USER_ID
    LEFT OUTER JOIN RX_CART rxcrt ON odi.RX_DISPENSE_CART_ID = rxcrt.CART_ID
                LEFT OUTER JOIN ZC_DISP_TYPE zdty ON odi.DISP_TYPE_C = zdty.DISP_TYPE_C

                LEFT OUTER JOIN RX_PHR phr ON odi.DISPENSE_PHR_ID = phr.PHARMACY_ID
                LEFT OUTER JOIN zc_physical_type zcpt ON phr.PHYSICAL_TYPE_C = zcpt.PHYSICAL_TYPE_C
                LEFT OUTER JOIN clarity_dep dep ON odi.DISP_UNIT_ID = dep.DEPARTMENT_ID
                LEFT OUTER JOIN ZC_DISPENSE_CODE zcdc ON odi.DISPENSE_CODE_C = zcdc.DFLT_DISP_CODE_C
                LEFT OUTER JOIN ORDER_ATTRIBUTE ovr ON ovr.ORDER_ID = odi.ORDER_MED_ID and ovr.LINE = 1 -- Cabinet Override 
        LEFT OUTER JOIN (
                        select disp2.ORDER_MED_ID
                        ,disp2.RETURN_CNCTDATREAL
                        ,MIN(disp2.CONTACT_DATE_REAL) FIRST_RETURN_DATE_REAL
                        from ORDER_DISP_INFO disp2
                        group by disp2.ORDER_MED_ID,disp2.RETURN_CNCTDATREAL
                        )returned on odi.ORDER_MED_ID=returned.ORDER_MED_ID and odi.CONTACT_DATE_REAL=returned.RETURN_CNCTDATREAL
                WHERE
                odi.ORD_CNTCT_TYPE_C = 5
                AND odi.ORDER_MED_ID =589704675
--   and TRUNC(odi.ACTION_INSTANT) >= '1-apr-2020'
--   AND TRUNC(odi.ACTION_INSTANT) <= '2-apr-2019'
    --  TRUNC(vrxd.DISP_DTTM) >= TRUNC (ADD_MONTHS (epic_util.efn_din (sysdate), -2), 'MM')
--        AND  TRUNC(vrxd.DISP_DTTM) < TRUNC (ADD_MONTHS (epic_util.efn_din (sysdate), -1), 'MM')

  ORDER BY odi.ORDER_MED_ID,odi.ACTION_INSTANT

)

,DISPSTEP2
AS
(
  SELECT 
                disp1.ACTION_INSTANT
                ,disp1.CONTACT_DATE
                ,disp1.HOUR
                ,disp1.ACTION_ID
                ,disp1.PREP_DTTM
                ,disp1.PREP_USERID
                ,disp1.PREPPED_BY
                ,disp1.PHARMACY_USR_ID
                ,disp1.ORDER_MED_ID
                ,disp1.CONTACT_DATE_REAL
                ,disp1.DISPENSE_PHR_ID
                ,disp1.PHARMACY_NAME
                ,disp1.PHYSICAL_TYPE
                ,disp1.DEST_DEPARTMENT_ID
                ,disp1.DEST_DEPARTMENT
                ,disp1.DISP_CODE
                ,disp1.DISP_RETURNED_YN
                ,disp1.PHYSICAL_TYPE_C
                ,disp1.EQUIV_MED_DISP_QTY
                ,disp1.NAME
				,disp1.GEN_DISP_TYPE_C
    
  ,CASE WHEN disp1.GEN_DISP_TYPE_C = 1 THEN 1 ELSE 0 END AS "ADS"
  ,CASE WHEN disp1.GEN_DISP_TYPE_C = 2 THEN 1 ELSE 0 END AS "ADSOVERIDE"
  ,CASE WHEN disp1.GEN_DISP_TYPE_C = 3 THEN 1 ELSE 0 END AS "CART"
  ,CASE WHEN disp1.GEN_DISP_TYPE_C = 4 THEN 1 ELSE 0 END AS "FRST"
  ,CASE WHEN disp1.GEN_DISP_TYPE_C = 5 THEN 1 ELSE 0 END AS "REDISPENSE"
  ,CASE WHEN disp1.GEN_DISP_TYPE_C = 1 AND disp1.DISP_RETURNED_YN = 'Y' THEN 1 ELSE 0 END AS "ADSRET"
  ,CASE WHEN disp1.GEN_DISP_TYPE_C = 2 AND disp1.DISP_RETURNED_YN = 'Y' THEN 1 ELSE 0 END AS "ADSOVERIDERET"
  ,CASE WHEN disp1.GEN_DISP_TYPE_C = 3 AND disp1.DISP_RETURNED_YN = 'Y' THEN 1 ELSE 0 END AS "CARTRET"
  ,CASE WHEN disp1.GEN_DISP_TYPE_C = 4 AND disp1.DISP_RETURNED_YN = 'Y' THEN 1 ELSE 0 END AS "FRSTRET"
  ,CASE WHEN disp1.GEN_DISP_TYPE_C = 5 AND disp1.DISP_RETURNED_YN = 'Y' THEN 1 ELSE 0 END AS "REDISPENSERET"
  ,CASE WHEN disp1.PHYSICAL_TYPE_C = 3 THEN 1 ELSE 0 END AS "DISPROB"
                ,disp1.CHECK_USERNM
                ,disp1.CHECK_DTTM
                ,disp1.CHECK_BY
                ,disp1.CART_CANCEL
    ,disp1.DISP_PRINTER
    ,disp1.DISPENSE_USER
                ,disp1.TRIGGER_FILL_YN 
                ,disp1.CART_NAME 
    ,disp1.ACTION_DTTM_LOCAL       ----- UPDATED on 12/23/2020
    ,disp1.DISPENSE_ACTION
    ,disp1.ADS_OVERRIDE  

  FROM DISPSTEP1 disp1
  
 ) 


, ORDMED
AS
(
                SELECT 
                 om.ORDER_MED_ID
                ,om.PAT_ENC_CSN_ID
                ,om.DISPLAY_NAME
                ,om.ORDER_INST
                ,om.DESCRIPTION
                ,om.DOSE_UNIT_C
                ,om.MED_ROUTE_C
                ,om.ORDER_STATUS_C
                ,om.PAT_LOC_ID
                ,om.ORD_PROV_ID
                ,om.AUTHRZING_PROV_ID
                ,om.HV_DISCR_FREQ_ID
                ,TRUNC(om.ORDERING_DATE) "ORD_DATE"
                ,om.AMB_MED_DISP_NAME
                ,om.MEDICATION_ID
                ,om.MIN_DISCRETE_DOSE
                ,om.order_start_time
                ,om.ORDER_END_TIME
                ,om.PAT_ID
                ,om.ORDER_PRIORITY_C
                ,om.SIG
    ,coalesce(rx2disp.SHORT_NAME, zcg.NAME) "SHORT_NAME"
                ,rx1disp.BILLING_CODE "BILLING_CODE"
    ,zcdeadisp.NAME "DEA_CLASS"
    ,zctcdisp.NAME  "THERA_CLASS"
                ,zcpcdisp.NAME  "PHARM_CLASS"
    ,cmdisp.MEDICATION_ID  "ERX_NUMBER"
    ,cmdisp.NAME "ERX_NAME"
    ,omet.PRL_ORDERSET_ID
    ,omet.ORDER_DTTM
    ,omet.ORDER_SOURCE_C
    ,zos.NAME "SOURCE"
    ,ser.PROV_NAME  "AUTHORIZING_PROV"
    ,ser.PROV_NAME "ORDERING_USER"
    ,emppnd.NAME "RELEASED_BY"
    ,cmdisp.FORM "FORMULATION"
    ,rx1disp.DFLT_DISP_CODE_C  ----- 7 bulk
    , omi.DISPENSABLE_MED_ID 
    ,zmu.NAME "MED_DOSE"
    ,zmucalc.NAME  "CALC_DOSE"
    ,omi.CALC_MIN_DOSE
    ,zar.NAME "MED_ROUTE"
    ,freq.FREQ_NAME
    ,zcop.NAME "ORDER_PRIORITY"
    ,zcg.NAME "SIMPLE"
    ,ordm2.INITIATED_TIME
    ,freq.PRN_YN
    ,dispmed.ACTION_INSTANT
                ,dispmed.CONTACT_DATE
                ,dispmed.HOUR
                ,dispmed.ACTION_ID
                ,dispmed.PREP_DTTM
                ,dispmed.PREP_USERID
                ,dispmed.PREPPED_BY
                ,dispmed.PHARMACY_USR_ID
                ,dispmed.CONTACT_DATE_REAL
                ,dispmed.DISPENSE_PHR_ID
                ,dispmed.PHARMACY_NAME
                ,dispmed.PHYSICAL_TYPE
                ,dispmed.DEST_DEPARTMENT_ID
                ,dispmed.DEST_DEPARTMENT
                ,dispmed.DISP_CODE
                ,dispmed.DISP_RETURNED_YN
                ,dispmed.PHYSICAL_TYPE_C
    ,dispmed.GEN_DISP_TYPE_C
                  ,CASE WHEN dispmed.GEN_DISP_TYPE_C = 1 THEN 1 ELSE 0 END AS "ADS"
                  ,CASE WHEN dispmed.GEN_DISP_TYPE_C = 2 THEN 1 ELSE 0 END AS "ADSOVERIDE"
                  ,CASE WHEN dispmed.GEN_DISP_TYPE_C = 3 THEN 1 ELSE 0 END AS "CART"
                  ,CASE WHEN dispmed.GEN_DISP_TYPE_C = 4 THEN 1 ELSE 0 END AS "FRST"
                  ,CASE WHEN dispmed.GEN_DISP_TYPE_C = 5 THEN 1 ELSE 0 END AS "REDISPENSE"
                  ,CASE WHEN dispmed.GEN_DISP_TYPE_C = 1 AND dispmed.DISP_RETURNED_YN = 'Y' THEN 1 ELSE 0 END AS "ADSRET"
                  ,CASE WHEN dispmed.GEN_DISP_TYPE_C = 2 AND dispmed.DISP_RETURNED_YN = 'Y' THEN 1 ELSE 0 END AS "ADSOVERIDERET"
                  ,CASE WHEN dispmed.GEN_DISP_TYPE_C = 3 AND dispmed.DISP_RETURNED_YN = 'Y' THEN 1 ELSE 0 END AS "CARTRET"
                  ,CASE WHEN dispmed.GEN_DISP_TYPE_C = 4 AND dispmed.DISP_RETURNED_YN = 'Y' THEN 1 ELSE 0 END AS "FRSTRET"
                  ,CASE WHEN dispmed.GEN_DISP_TYPE_C = 5 AND dispmed.DISP_RETURNED_YN = 'Y' THEN 1 ELSE 0 END AS "REDISPENSERET"
                  ,CASE WHEN dispmed.PHYSICAL_TYPE_C = 3 THEN 1 ELSE 0 END AS "DISPROB"
                ,dispmed.CHECK_USERNM
                ,dispmed.CHECK_DTTM
                ,dispmed.CHECK_BY
                ,dispmed.CART_CANCEL
    ,dispmed.DISP_PRINTER
    ,dispmed.DISPENSE_USER
                ,dispmed.TRIGGER_FILL_YN 
                ,dispmed.CART_NAME 
    ,dispmed.ACTION_DTTM_LOCAL             ------ UPDATED on 12/23/2020
    ,dispmed.DISPENSE_ACTION
    ,dispmed.ADS_OVERRIDE  
    ,dispmed.EQUIV_MED_DISP_QTY
    ,dispmed.NAME "EQUIV_UNIT"

    FROM DISPSTEP2 dispmed
    LEFT OUTER JOIN ORDER_MED om ON dispmed.ORDER_MED_ID = om.ORDER_MED_ID
                LEFT OUTER JOIN order_medinfo omi ON om.ORDER_MED_ID = omi.ORDER_MED_ID
    LEFT OUTER JOIN order_med_2 ordm2 ON om.ORDER_MED_ID=ordm2.ORDER_ID
                LEFT OUTER JOIN clarity_medication cmdisp ON omi.DISPENSABLE_MED_ID = cmdisp.MEDICATION_ID
                LEFT OUTER JOIN RX_MED_TWO rx2disp ON cmdisp.MEDICATION_ID = rx2disp.MEDICATION_ID
                LEFT OUTER JOIN RX_MED_ONE rx1disp ON cmdisp.MEDICATION_ID = rx1disp.MEDICATION_ID
                LEFT OUTER JOIN ZC_DEA_CLASS_CODE zcdeadisp ON rx2disp.DEA_CLASS_CODE_C = zcdeadisp.DEA_CLASS_CODE_C
                LEFT OUTER JOIN ZC_THERA_CLASS zctcdisp ON cmdisp.THERA_CLASS_C = zctcdisp.THERA_CLASS_C
                LEFT OUTER JOIN ZC_PHARM_CLASS zcpcdisp ON cmdisp.PHARM_CLASS_C = zcpcdisp.PHARM_CLASS_C
                LEFT OUTER JOIN ZC_ORDER_PRIORITY zcop ON om.ORDER_PRIORITY_C = zcop.ORDER_PRIORITY_C
                LEFT OUTER join order_metrics omet ON om.ORDER_MED_ID = omet.ORDER_ID
                LEFT OUTER JOIN zc_order_source zos ON omet.ORDER_SOURCE_C = zos.ORDER_SOURCE_C
                LEFT OUTER JOIN zc_simple_generic zcg ON cmdisp.SIMPLE_GENERIC_C = zcg.SIMPLE_GENERIC_C
                LEFT OUTER JOIN clarity_ser ser ON om.ORD_PROV_ID= ser.PROV_ID
                LEFT OUTER JOIN clarity_emp emp ON om.ORD_CREATR_USER_ID = emp.USER_ID
                LEFT OUTER JOIN order_pending ordpnd ON om.ORDER_MED_ID = ordpnd.ORDER_ID
                LEFT OUTER JOIN clarity_emp emppnd ON ordpnd.RELEASED_USER_ID = emppnd.USER_ID
    LEFT OUTER JOIN IP_FREQUENCY freq ON om.HV_DISCR_FREQ_ID=freq.FREQ_ID
    LEFT OUTER JOIN ZC_MED_UNIT zmu ON om.DOSE_UNIT_C = zmu.DISP_QTYUNIT_C
    LEFT OUTER JOIN ZC_MED_UNIT zmucalc ON omi.CALC_DOSE_UNIT_C = zmucalc.DISP_QTYUNIT_C
    LEFT OUTER JOIN ZC_ADMIN_ROUTE zar ON om.MED_ROUTE_C = zar.MED_ROUTE_C

)

,MEDIID
as
                (
               SELECT *
               FROM 
                 (
                   SELECT Distinct
                                                odm.ORDER_MED_ID
                                                ,coalesce(ndcADSID.MPI_ID_VAL, ndgADSID.MPI_ID, erxADSID.MPI_ID) as "ADSIID"
                                                ,odm.DISP_MED_ID
                                                ,odm.CONTACT_DATE
                                     ,rank() over ( partition by odm.ORDER_MED_ID order by odm.CONTACT_DATE DESC,RowNum) rank
                                                FROM ORDMED ordmd
                                                LEFT OUTER JOIN ORDER_DISP_MEDS odm ON ordmd.ORDER_MED_ID = odm.ORDER_MED_ID
                                                left outer join RX_NDC_STATUS rxndc
                                                       on odm.DISP_NDC_CSN = rxndc.CNCT_SERIAL_NUM
                                                left outer join RX_NDC ordNDC
                                                       on rxndc.NDC_ID = ordNDC.NDC_ID
                                                left outer join RX_NDC_MPI_ID ndcADSID
                                                       on ndcADSID.NDC_ID = rxndc.NDC_ID
                                                       and ndcADSID.MPI_ID_TYPE_ID = 4   --<NDC IIT ID GOES HERE>
                                                left outer join RX_NDG_MPI_ID ndgADSID
                                                       on ndgADSID.NDG_ID = ordNDC.ASSOCIATED_NDG
                                                       and ndgADSID.MPI_ID_TYPE_ID = 5   --<NDG IIT ID GOES HERE>
                                                left outer join RX_MED_EPI_ID_NUM erxADSID
                                                       on erxADSID.MEDICATION_ID = odm.DISP_MED_ID  --> may want to change this for mixtures
                                                       and erxADSID.MPI_ID_TYPE_ID = 1   --<ERX IIT ID GOES HERE>
                                                WHERE
                                                       (ndcADSID.MPI_ID_VAL is not null
                                                       or ndgADSID.MPI_ID is not null
                                                       or erxADSID.MPI_ID is not NULL)
                                                       AND odm.LINE = 1
     )
   WHERE rank = 1  
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
                ,ominfomix.CALC_MIN_DOSE
                ,cmmix.NAME
    ,ominfomix.ORDER_SOURCE_C
    ,ominfomix.MIXTURE_TYPE_C
                ,zosmix.NAME "SOURCE"
                ,coalesce(rx2mix.SHORT_NAME, zcgmix.NAME)  "SHORT_NAME"
                ,zmumix.NAME "MIXDOSEUNIT"
                ,zmucalcmix.NAME "CALCDOSEUNIT"
                ,zctcmix.NAME  "MIX_THERA_CLASS"
                ,zcpcmix.NAME  "MIX_PHARM_CLASS"
    ,zcdeadispmix.NAME "MIX_DEA_CLASS"
                FROM ORDMED ordmix
                INNER JOIN ORDER_MEDMIXINFO omix ON ordmix.ORDER_MED_ID = omix.ORDER_MED_ID and omix.LINE = 1
                LEFT OUTER JOIN order_medinfo ominfomix ON ordmix.ORDER_MED_ID = ominfomix.ORDER_MED_ID AND ominfomix.MIXTURE_TYPE_C = 1
    LEFT OUTER JOIN ZC_ORDER_SOURCE zosmix ON ominfomix.ORDER_SOURCE_C = zosmix.ORDER_SOURCE_C
                LEFT OUTER JOIN clarity_medication cmmix ON omix.MEDICATION_ID = cmmix.MEDICATION_ID
                LEFT OUTER JOIN RX_MED_TWO rx2mix ON cmmix.MEDICATION_ID = rx2mix.MEDICATION_ID
                LEFT OUTER JOIN ZC_SIMPLE_GENERIC zcgmix ON cmmix.SIMPLE_GENERIC_C = zcgmix.SIMPLE_GENERIC_C
                LEFT OUTER JOIN ZC_MED_UNIT zmumix ON omix.DOSE_UNIT_C = zmumix.DISP_QTYUNIT_C
                LEFT OUTER JOIN ZC_MED_UNIT zmucalcmix ON omix.DOSE_UNIT_C = zmucalcmix.DISP_QTYUNIT_C
                LEFT OUTER JOIN ZC_THERA_CLASS zctcmix ON cmmix.THERA_CLASS_C = zctcmix.THERA_CLASS_C
                LEFT OUTER JOIN ZC_PHARM_CLASS zcpcmix ON cmmix.PHARM_CLASS_C = zcpcmix.PHARM_CLASS_C
                LEFT OUTER JOIN RX_MED_TWO rx2dispmix ON cmmix.MEDICATION_ID = rx2dispmix.MEDICATION_ID
    LEFT OUTER JOIN ZC_DEA_CLASS_CODE zcdeadispmix ON rx2dispmix.DEA_CLASS_CODE_C = zcdeadispmix.DEA_CLASS_CODE_C
  
)

,ADTSERV
AS
(

                                SELECT DISTINCT
                                adt.PAT_ENC_CSN_ID
                                ,adt.EVENT_TIME
                                ,zps.NAME "ADMITTING_SERVICE"
                                ,zha.NAME "ADTBASECLASS"
                                ,adt.BASE_PAT_CLASS_C
                                ,adt.PAT_CLASS_C
                                ,zax.NAME "ADTPATCLASS"
                    FROM ORDMED ordadt
                                LEFT OUTER JOIN CLARITY_ADT adt ON ordadt.PAT_ENC_CSN_ID= adt.PAT_ENC_CSN_ID
                                LEFT OUTER JOIN ZC_PAT_SERVICE zps ON adt.PAT_SERVICE_C = zps.HOSP_SERV_C
                                LEFT OUTER JOIN ZC_ACCT_BASECLS_HA zha ON adt.BASE_PAT_CLASS_C = zha.ACCT_BASECLS_HA_C
                                LEFT OUTER JOIN ZC_ACCT_CLASS_HA zax ON adt.PAT_CLASS_C = zax.ACCT_CLASS_HA_C

                                WHERE
                                adt.EVENT_TYPE_C = 1   ---- Admitted
                                AND adt.EVENT_SUBTYPE_C = 1 --- Original
                                ORDER BY adt.PAT_ENC_CSN_ID, adt.EVENT_TIME
)

, ORDSERV
AS
(
  SELECT *
  FROM
  (
  SELECT DISTINCT
         ordsvc.ORDER_MED_ID
        ,ordsvc.PAT_ENC_CSN_ID
                                ,har.PRIM_ENC_CSN_ID
                                ,har.ACCT_BASECLS_HA_C
                                ,har.ACCT_CLASS_HA_C
                                ,zha.NAME "HSPBASECLASS"
                                ,zac.NAME "HSPACCTCLASS"
                                ,har.HSP_ACCOUNT_ID
        ,HARBANSECLASS.HSPANBASECLASS
        ,HARBANSECLASS.HSPANACCTCLASS
  ,rank() over ( partition by ordsvc.ORDER_MED_ID order by ordsvc.ORDER_MED_ID desc ,RowNum) rank3

  FROM ORDMED ordsvc
  left outer join HSP_ACCOUNT har on ordsvc.PAT_ENC_CSN_ID = har.PRIM_ENC_CSN_ID
  LEFT OUTER JOIN ZC_ACCT_BASECLS_HA zha ON har.ACCT_BASECLS_HA_C= zha.ACCT_BASECLS_HA_C
  LEFT OUTER JOIN ZC_ACCT_CLASS_HA zac ON har.ACCT_CLASS_HA_C = zac.ACCT_CLASS_HA_C
    LEFT OUTER JOIN
  (
               SELECT distinct
                                hsbinfo.AN_52_ENC_CSN_ID
                                ,hsbinfo.AN_BILLING_CSN_ID
                                ,haran.ACCT_BASECLS_HA_C
                                ,haran.ACCT_CLASS_HA_C
                                ,zha.NAME "HSPANBASECLASS"
                                ,zac.NAME "HSPANACCTCLASS"
                                FROM AN_HSB_LINK_INFO hsbinfo
                                LEFT OUTER JOIN HSP_ACCOUNT haran ON hsbinfo.AN_BILLING_CSN_ID = haran.PRIM_ENC_CSN_ID
                                LEFT OUTER JOIN ZC_ACCT_BASECLS_HA zha ON haran.ACCT_BASECLS_HA_C= zha.ACCT_BASECLS_HA_C
                                LEFT OUTER JOIN ZC_ACCT_CLASS_HA zac ON haran.ACCT_CLASS_HA_C = zac.ACCT_CLASS_HA_C

  )HARBANSECLASS on ordsvc.PAT_ENC_CSN_ID = HARBANSECLASS.AN_52_ENC_CSN_ID

      )
  WHERE rank3 =1
  )


  ,PHRMV1
  AS
  (
   SELECT *
   FROM (
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

                                FROM ORDMED dispn
                                LEFT OUTER JOIN order_disp_info odi ON dispn.ORDER_MED_ID = odi.ORDER_MED_ID
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
--
  ,PHRMV2
  AS
  (
   SELECT *
   FROM (
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

                                FROM ORDMED dispn
                                LEFT OUTER JOIN order_disp_info odi ON dispn.ORDER_MED_ID = odi.ORDER_MED_ID
                                LEFT OUTER JOIN RX_PHR phr ON odi.FIRSTDOSES_PHR_ID = phr.PHARMACY_ID
                                LEFT OUTER JOIN clarity_ser ser ON odi.PHARMACY_USR_ID = ser.USER_ID
                                LEFT OUTER JOIN ORDER_RXVER_TRACE ordrxt ON odi.ORDER_MED_ID = ordrxt.ORDER_MED_ID
                                LEFT OUTER JOIN ZC_MED_VERIFY_TYPE zcmvt ON odi.MED_VERIFY_TYPE_C = zcmvt.MED_VERIFY_TYPE_C
                                WHERE
                                odi.MED_VERIFY_TYPE_C = 8
                                 AND odi.ORD_CNTCT_TYPE_C IN (4,13)  --Verify, Pend Verify
                                AND odi.PHARMACY_USR_ID <> '1' --- EPIC USER
                                AND ordrxt.RXQ_REASON_C IN (16,19)
                                AND ordrxt.RX_UNQUEUE_REASON_C IN (1,2)
                                )
                                WHERE rank1 = 1
                  )
--
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
                FROM ORDMED ordadm
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
--,max(a.TAKEN_TIME) "TAKEN_TIME"
,a.TAKEN_TIME "TAKEN_TIME"

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
                FROM ORDMED ordadm
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


      GROUP BY a.ORDER_MED_ID,a.ADMIN_DISPDATREAL,a.TAKEN_TIME

)  



SELECT distinct
   TRUNC(vrxd.ACTION_INSTANT) "DISPENSE_DATE"
  ,vrxd.HOUR "DISPENSE_HOUR"
  ,vrxd.ACTION_INSTANT "DISP_DTTM"
  ,UPPER(coalesce(coalesce(vrxd.SHORT_NAME, vrxd.SIMPLE),mixmd.SHORT_NAME))  "SHORT_NAME"
  ,vrxd.DISPLAY_NAME  "ORDER_DISPLAY_NAME"
  ,vrxd.ERX_NAME
  ,vrxd.ERX_NUMBER
  ,iid.ADSIID "IID"
  ,vrxd.DEA_CLASS                                                                  ----NEW COLUMN 4/15/2020
  ,CASE WHEN mixmd.MIXTURE_TYPE_C >= 1 then 'Y' ELSE 'N' END "IS_MED_MIXTURE"
  ,coalesce(coalesce(vrxd.MIN_DISCRETE_DOSE, mixmd.MIN_DOSE_AMOUNT),to_number(vrxd.SIG)) "DOSE"
  ,coalesce(vrxd.MED_DOSE ,mixmd.MIXDOSEUNIT)      "DOSE_UNIT"
  ,coalesce(vrxd.CALC_MIN_DOSE,mixmd.MIN_CALC_DOSE_AMT) "DOSE_CALC"
  ,coalesce(vrxd.CALC_DOSE ,mixmd.CALCDOSEUNIT)      "CALC_DOSE_UNIT"
  ,vrxd.EQUIV_MED_DISP_QTY "IMPLIED_QTY"  ----- NEW COLUMN  4/15/2020
  ,vrxd.EQUIV_UNIT  "IMPLIED_QTY_UNIT"   ----- NEW COLUMN  4/15/2020

  ,vrxd.MED_ROUTE
  ,vrxd.FREQ_NAME "FREQUENCY"
  ,vrxd.FORMULATION "FORMULATION"
  ,admsrv.ADMITTING_SERVICE
  ,dep.DEPARTMENT_NAME   "PATIENT_LOCATION"
  ,parloc.LOC_NAME "PARENT_LOCATION"
  ,vrxd.PHARMACY_NAME  "DISPENSING_PHARMACY"
  ,vrxd.DISP_PRINTER  "DISPENSING_PHARMACY_PRINTER"
  ,vrxd.PHYSICAL_TYPE  "DISPENSING_PHARMACY_TYPE"
  ,vrxd.ADS_OVERRIDE  "ADS_OVERIDE?"
  ,vrxd.PRN_YN  "PRN?"
  ,zcgd.NAME  "DISPENSE_TYPE"
  ,vrxd.DISP_CODE  "DISPENSE_CODE"
  ,vrxd.CART_NAME  "CART"
  ,vrxd.CART_CANCEL "CANCELED_CART_DISPENSE"
  ,vrxd.DISP_RETURNED_YN  "DISPENSED_RETURNED?"
  ,vrxd.ORDERING_USER "ORDERING_USER"
  ,vrxd.ORDER_DTTM
  ,vrxd.RELEASED_BY "RELEASED_BY"
  ,coalesce(vrxd.INITIATED_TIME,vrxd.ORDER_INST) "RELEASED_DTTM"
  ,phrm.PHR "FIRST_VERIFIED_RPH"
  ,phrm.PHR_DTTM "FIRST_VERIFIED_DTTM"
  ,TO_CHAR(CAST(phrm.PHR_DTTM AS date), 'MM/DD/YYYY') "FIRST_VERIFY_DATE"
  ,to_char(CAST(phrm.PHR_DTTM AS DATE), 'hh24:mi:ss AM')  "FIRST_VERIFY_TIME"
  ,phrm2.PHR "SECOND_VERIFIED_RPH"
  ,phrm2.PHR_DTTM "SECOND_VERIFIED_DTTM"
  ,TO_CHAR(CAST(phrm2.PHR_DTTM AS date), 'MM/DD/YYYY') "SECOND_VERIFY_DATE"
  ,to_char(CAST(phrm2.PHR_DTTM AS DATE), 'hh24:mi:ss AM')  "SECOND_VERIFY_TIME"
  ,vrxd.ORDER_MED_ID
  ,coalesce(coalesce(admsrv.ADTBASECLASS,svcmd.HSPBASECLASS),svcmd.HSPANBASECLASS) "ORD_PATIENT_BASE_CLASS"
  ,coalesce(coalesce(admsrv.ADTPATCLASS,svcmd.HSPACCTCLASS),svcmd.HSPANACCTCLASS) "ORD_PATIENT_ACCOUNT_CLASS"
  ,svcmd.HSP_ACCOUNT_ID "HAR"
  ,vrxd.ADS "ADS_DISPENSE"
  ,vrxd.ADSOVERIDE  "ADS_OVERRIDE_DISPENSE"
  ,vrxd.CART "CART_DISPENSE"
  ,vrxd.FRST "FIRST_DOSE_DISPENSE"
  ,vrxd.REDISPENSE "REDISPENSE"
  ,vrxd.DISPROB "ROBOTIC_DISPENSE"
  ,vrxd.ADSRET "ADS_DISPENSE_RETURN"
  ,vrxd.ADSOVERIDERET  "ADS_OVERRIDE_DISPENSE_RETURN"
  ,(vrxd.CARTRET + vrxd.FRSTRET + vrxd.REDISPENSERET)  "NON_ADS_RETURN"
  ,CASE WHEN marmd.DISPENSE_CODE_C = 7 THEN 'Y' ELSE 'N' END   "BULK_DISPENSE"
  ,marmd.BLKCNT  "BULK_ADMIN_COUNT"												----UPDATED 4/15/2020
  ,marcnt.ADMIN_CNT "ADMIN_COUNT"												----UPDATED 4/15/2020
  ,TO_CHAR(CAST(DISPADMIN.SCHED_ADMIN AS date), 'MM/DD/YYYY') "ADMIN_DUE_DATE"
  ,to_char(CAST(DISPADMIN.SCHED_ADMIN AS DATE), 'hh24:mi:ss AM')  "ADMIN_DUE_TIME"
  ,TO_CHAR(CAST(marcnt.TAKEN_TIME AS date), 'MM/DD/YYYY') "ADMIN_DATE"				----UPDATED 4/15/2020
  ,to_char(CAST(marcnt.TAKEN_TIME AS DATE), 'hh24:mi:ss AM')  "ADMIN_TIME"			----UPDATED 4/15/2020
  ,vrxd.DISPENSE_ACTION  
  ,vrxd.ACTION_DTTM_LOCAL  "ACTION_DTTM"                                       ------ UPDATED 12/23/2020
  ,coalesce(vrxd.THERA_CLASS,mixmd.MIX_THERA_CLASS) "THERA_CLASS"
  ,coalesce(vrxd.PHARM_CLASS,mixmd.MIX_PHARM_CLASS) "PHARM_CLASS"
  ,vrxd.ORDER_PRIORITY
  ,vrxd.DISPENSE_USER  "DISPENSING_USER"
  ,vrxd.PREPPED_BY "PREPPED_BY"
  ,vrxd.PREP_DTTM  "PREPPED_DTTM"
  ,vrxd.CHECK_BY  "CHECKED_BY"
  ,vrxd.CHECK_DTTM  "CHECKED_DTTM"
  ,vrxd.TRIGGER_FILL_YN "TRIGGER_FILL_DISPENSE_YN"
  ,vrxd.CONTACT_DATE_REAL  "CDR"    ----- NEW UNIQUE IDENTIFIER 4/15/2020
  ,rank() over ( partition by vrxd.ORDER_MED_ID,vrxd.CONTACT_DATE_REAL order by   vrxd.ACTION_INSTANT  ,RowNum) "IGNORE_THIS_COLUMN"
FROM ORDMED vrxd
LEFT OUTER JOIN MARMED marmd ON vrxd.ORDER_MED_ID=marmd.ORDER_MED_ID AND vrxd.CONTACT_DATE_REAL = marmd.ADMIN_DISPREAL
LEFT OUTER JOIN ADMINREALCNT marcnt ON vrxd.ORDER_MED_ID=marcnt.ORDER_MED_ID AND vrxd.CONTACT_DATE_REAL = marcnt.ADMIN_DISPREAL
LEFT OUTER JOIN order_med_2 ordm2 ON vrxd.ORDER_MED_ID=ordm2.ORDER_ID
LEFT OUTER JOIN MIXMED mixmd ON vrxd.ORDER_MED_ID=mixmd.ORDER_MED_ID
LEFT OUTER JOIN ADTSERV admsrv ON vrxd.PAT_ENC_CSN_ID = admsrv.PAT_ENC_CSN_ID
LEFT OUTER JOIN ORDSERV svcmd ON vrxd.ORDER_MED_ID = svcmd.ORDER_MED_ID
LEFT OUTER JOIN PHRMV1 phrm ON vrxd.ORDER_MED_ID = phrm.ORDER_MED_ID
LEFT OUTER JOIN PHRMV2 phrm2 ON vrxd.ORDER_MED_ID = phrm2.ORDER_MED_ID
left outer join MEDIID iid on vrxd.ORDER_MED_ID = iid.ORDER_MED_ID
LEFT OUTER JOIN MIXMED mixmd ON vrxd.ORDER_MED_ID = mixmd.ORDER_MED_ID
LEFT OUTER JOIN ZC_GEN_DISP_TYPE zcgd ON vrxd.GEN_DISP_TYPE_C=zcgd.GEN_DISP_TYPE_C
LEFT OUTER JOIN CLARITY_DEP dep ON vrxd.DEST_DEPARTMENT_ID=dep.DEPARTMENT_ID
LEFT OUTER JOIN CLARITY_LOC locrev ON dep.REV_LOC_ID=locrev.LOC_ID
LEFT OUTER JOIN CLARITY_LOC parloc ON locrev.HOSP_PARENT_LOC_ID = parloc.LOC_ID
     LEFT OUTER JOIN
     (
               SELECT 
                ordrx.ADMIN_INSTANT "SCHED_ADMIN"
                ,ordrx.ORDER_MED_ID
                ,ordrx.CONTACT_DATE
                ,ordrx.CONTACT_DATE_REAL
                FROM ORDER_RXADMINSTS ordrx
     )DISPADMIN ON vrxd.ORDER_MED_ID = DISPADMIN.ORDER_MED_ID AND vrxd.CONTACT_DATE_REAL = DISPADMIN.CONTACT_DATE_REAL
                   
ORDER BY vrxd.ACTION_INSTANT