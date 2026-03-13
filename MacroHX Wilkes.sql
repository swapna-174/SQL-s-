 WITH LMCLOC
AS
(
  select *
 from 
  (
       SELECT --*
       uclloc.UCL_ID
       ,uclloc.PATIENT_ID
       ,uclloc.IMPLIED_UNIT_TYPE_C
       ,uclloc.ORDER_ID
       ,uclloc.RX_CONT_DATE_REAL
       ,uclloc.RX_COMP_LINE
       ,uclloc.MEDICATION_ID 
       ,uclloc.IMPLIED_QTY_UNIT_C
       ,uclloc.IMPLIED_QTY
       ,uclloc.SERVICE_DATE_DT
       ,uclloc.DEPARTMENT_ID
       ,uclloc.HOSPITAL_ACCOUNT_ID
       ,uclloc.EPT_CSN
       ,uclloc.BILLING_PROVIDER_ID
       ,rx2.DISPENSE_UNIT_C "DISP_UNIT_C"
       ,uclloc.MEDICATION_ID "MED_ID"
       ,frxucl.VOID_STATE
       ,uclloc.PRICE_OVERRIDE
       ,LOC.LOC_ID
       ,LOC.LOC_NAME
       ,parloc.LOC_NAME "PARENT_LOCATION"
       ,zcrpt6.NAME
       ,CDM.medication_id "CDM_MED_ID"
       ,CASE WHEN 
                 LOC.LOC_ID NOT IN ( 10023, 10063, 10064, 10073, 10075, 10076, 10077, 10078, 10079, 10080, 10081, 10083, 10085, 10087, 
                 10122, 10123, 10142, 10153, 10156, 10214, 10243, 10244, 10245, 10246, 10247, 10248, 10249, 10250, 10251, 10253, 10254, 10256, 100001,10243 ) 
                  and CHGDEP.PHYSICAL_LOC_C not IN (8, 9, 10,11)
            THEN 'MAIN'
            WHEN (parloc.LOC_ID = 100001 OR LOC.LOC_NAME LIKE 'THOMASVILLE%')
            THEN 'LMC'
            WHEN LOC.LOC_ID = 10243 ---------AND CHGDEP.DEPARTMENT_ID <> 1024301056 AND zcrpt6.NAME NOT LIKE 'PBC%')  2/11/2021
            THEN 'WILKES'
            WHEN CHGDEP.PHYSICAL_LOC_C IN (8, 9, 10,11)
            THEN 'HPR'
        END "LOCATION"  
            
       FROM CLARITY_UCL uclloc
       INNER JOIN F_RX_UCL frxucl ON uclloc.UCL_ID = frxucl.UCL_ID
       LEFT OUTER JOIN RX_MED_TWO rx2 ON uclloc.MEDICATION_ID = rx2.MEDICATION_ID

        LEFT OUTER JOIN CLARITY_LOC LOC ON uclloc.REVENUE_LOCATION_ID = LOC.LOC_ID
        LEFT OUTER JOIN CLARITY_LOC parloc ON LOC.HOSP_PARENT_LOC_ID = parloc.LOC_ID
        LEFT OUTER JOIN CLARITY_DEP CHGDEP ON uclloc.DEPARTMENT_ID = CHGDEP.DEPARTMENT_ID
        LEFT OUTER JOIN ZC_DEP_RPT_GRP_6 zcrpt6 ON CHGDEP.RPT_GRP_SIX = zcrpt6. RPT_GRP_SIX
        LEFT OUTER JOIN 
        (
        
           SELECT cm.medication_id
--           ,cm.MEDICATION_NAME
           FROM CLARITY_MEDICATION cm
           WHERE cm.medication_id IN (451078,12370,450231,5925,430853,114,400351,430178,6242,154061,451031,400470,431404,431664,431663)

        )CDM ON CDM.MEDICATION_ID = uclloc.MEDICATION_ID
        INNER JOIN
         ( --Choose a date range
           SELECT DISTINCT 
            EPIC_UTIL.EFN_DIN('{?Begin Date}') "Begin_Date"
           ,EPIC_UTIL.EFN_DIN('{?End Date}') "End_Date"
--          '1-oct-2020' "Begin_Date"
--         ,'30-oct-2020' "End_Date"
           FROM ZC_YES_NO
        ) dates on frxucl.REPORT_DATE BETWEEN dates."Begin_Date" and dates."End_Date"
  )a
    WHERE 
--    a.LOCATION='MAIN'
(a.LOCATION IN {?HospitalLocation} OR '0' IN {?HospitalLocation})




)
,UCL2USE
AS
(
  SELECT
       uclex.UCL_ID
       ,uclex.PATIENT_ID
       ,uclex.IMPLIED_UNIT_TYPE_C
       ,uclex.ORDER_ID 
       ,uclex.RX_CONT_DATE_REAL
       ,uclex.RX_COMP_LINE
       ,uclex.MEDICATION_ID 
       ,uclex.IMPLIED_QTY_UNIT_C
       ,uclex.IMPLIED_QTY
       ,uclex.SERVICE_DATE_DT
       ,uclex.DEPARTMENT_ID
       ,uclex.HOSPITAL_ACCOUNT_ID
       ,uclex.EPT_CSN
       ,uclex.BILLING_PROVIDER_ID
       ,uclex.DISP_UNIT_C 
        --Find the unit of the medication dispensed
        ,COALESCE(uclex.DISP_UNIT_C,odm.DISP_QTYUNIT_C) "DISPENSED_UNIT_C"

       ,uclex.MED_ID "MED_ID"
       ,med.MEDICATION_ID "MED_MED_ID"
       ,med.NAME "MED_MEDNAME"
       ,uclex.VOID_STATE
       ,uclex.PRICE_OVERRIDE
       ,uclex.LOC_ID
       ,uclex.LOC_NAME
       ,uclex.PARENT_LOCATION
       ,uclex.NAME
       ,ord.ORDER_MED_ID  
       ,ord.CONTACT_DATE_REAL 
       ,ord.DISP_MED_CNTCT_ID 
       ,ord.ACTION_INSTANT              
       ,ord.BULK_DISP_YN                                  
       ,odm.DISP_QTY            
       ,odm.CHARGE_METHOD_C     
       ,med.STRENGTH    
       ,phr.PHARMACY_NAME  "DISPENSE_PHARM"
       ,uclex.LOCATION
       ,uclex.CDM_MED_ID
        
  FROM LMCLOC uclex
  INNER JOIN ORDER_MEDINFO omdi ON uclex.ORDER_ID = omdi.ORDER_MED_ID
  LEFT OUTER JOIN ORDER_DISP_INFO ord ON uclex.ORDER_ID = ord.ORDER_MED_ID AND uclex.RX_CONT_DATE_REAL = ord.CONTACT_DATE_REAL
  left outer join ORDER_DISP_MEDS odm on uclex.ORDER_ID=odm.ORDER_MED_ID and uclex.RX_COMP_LINE=odm.LINE and odm.CONTACT_DATE_REAL=ord.DISP_MED_CNTCT_ID
  left outer join CLARITY_MEDICATION med on uclex.MED_ID = med.MEDICATION_ID
  left outer join RX_PHR phr on ord.DISPENSE_PHR_ID = phr.PHARMACY_ID


  WHERE 
  uclex.PRICE_OVERRIDE <> 0.00 
  AND uclex.PRICE_OVERRIDE <> 0.01
  AND (omdi.MIXTURE_TYPE_C is null or ((omdi.MIXTURE_TYPE_C=1 or omdi.MIXTURE_TYPE_C=2) 
  AND  ord.CHG_BY_COMP_YN='Y'))
  AND odm.CHARGE_METHOD_C NOT IN (108, 125, 126, 129,  171, 172, 174, 231, 233, 244, 247, 248) 

 ) 
 
,INSURERS
AS
(

   select *
   from
   
   (

      select distinct
      ucl2.UCL_ID as "INS_UCL_ID",
      harcvg.HSP_ACCOUNT_ID,
      harcvg.LINE,
      clpayor.PAYOR_NAME

      FROM UCL2USE ucl2
              Left outer join HSP_ACCT_CVG_LIST harcvg ON ucl2.HOSPITAL_ACCOUNT_ID = harcvg.HSP_ACCOUNT_ID
              Left outer join COVERAGE cvg ON harcvg.COVERAGE_ID = cvg.COVERAGE_ID
              Left outer join CLARITY_EPM clpayor on cvg.PAYOR_ID = clpayor.PAYOR_ID
          
      where
              harcvg.LINE BETWEEN 1 and 3 
    )
      pivot
        (
           MAX(PAYOR_NAME) "PNAME"
           for line in(1 as primary, 2 as secondary, 3 as tertiary)
 )

) 
       
 ,PATCLASS
 AS
 (
   SELECT adtMAX.*
   FROM 
    (
    select 
    MAX(cADT.EVENT_ID) max_ID
    , cUCL.UCL_ID
    , ord.DISP_MED_CNTCT_ID
    , att.ORD_ATTRIBUTE_C
    ,ord2.RX_PATIENT_CLASS_C
     from UCL2USE cUCL
     left outer join ORDER_DISP_INFO ord on ord.ORDER_MED_ID = cUCL.ORDER_ID and ord.CONTACT_DATE_REAL=cUCL.RX_CONT_DATE_REAL
     left outer join ORDER_DISP_INFO_2 ord2 on ord2.ORDER_ID = cUCL.ORDER_ID and ord2.CONTACT_DATE_REAL=cUCL.RX_CONT_DATE_REAL

        --determine if this is an override pull
     left outer join ORDER_ATTRIBUTE att on att.ORDER_ID=ord.ORDER_MED_ID and att.ORD_ATTRIBUTE_C = 1 
    left outer join CLARITY_ADT cADT on cADT.PAT_ENC_CSN_ID = cUCL.EPT_CSN and 

                --If the charge is a bulk charge with a service time listed, find the patient class before the service time
                            -- *TMH 281033 Use service time if it's not null, action instant otherwise
                  (
                       (
                            (
                              att.ORD_ATTRIBUTE_C is not null 
                              or ord.BULK_DISP_YN='N' 
                              or ord.BULK_DISP_YN is null 
                              or ord2.SERVICE_DTTM is NULL
                            ) 
                         and cADT.EFFECTIVE_TIME <= ord.ACTION_INSTANT
                         ) 
                      or (ord.BULK_DISP_YN='Y' and cADT.EFFECTIVE_TIME <=ord2.SERVICE_DTTM)
                  )
                      and (cADT.EVENT_SUBTYPE_C=1 or cADT.EVENT_SUBTYPE_C=3)
            group by cUCL.UCL_ID, ord.DISP_MED_CNTCT_ID, att.ORD_ATTRIBUTE_C,ord2.RX_PATIENT_CLASS_C
        )adtMAX 

        
 
 )
,PATENC
AS
(
  SELECT 
     zdetyp.NAME        "ENCOUNTER_TYPE"
    ,har.HSP_ACCOUNT_ID "HSP_ACCOUNT_ID"
    ,enc.PAT_ENC_CSN_ID "PAT_ENC_CSN_ID"
    ,enc2.ADT_PAT_CLASS_C   "ADT_PAT_CLASS_C"
    ,anes_admit_enc.ADT_PAT_CLASS_C "ANES_PAT_CLASS_C"
    ,patCLS2.NAME  "PAT_CLS_2_NAME"
    ,patCLS.NAME  "PAT_CLS_NAME"
    ,UCLpatCLS.NAME "UCL_PAT_CLASS_NAME"
    ,UCLchargeCLS.NAME "UCL_PATIENT_CLASS"
    ,chargeCLS.NAME  "CHG_CLS_2_NAME"
    ,hsp.OP_ADM_EVENT_ID
    ,hsp.INP_ADM_EVENT_ID
    ,hsp.EMER_ADM_EVENT_ID
    ,uclpat.UCL_ID
       --Consider an encounter an office visit if:
    ,CASE 
             WHEN (enc.APPT_STATUS_C is not null        --The encounter has an appointment status
              AND hsp.PAT_ENC_CSN_ID is null        --It is not listed in the hospital encounters table
              AND enc2.IP_DOC_CONTACT_CSN is null   --There is no linked inpatient encounter for documentation
              AND enc.ENC_TYPE_C<>3                 --The contact type is not hospital encounter
              AND (enc2.INPATIENT_FLAG is null or enc2.INPATIENT_FLAG<>'Y'))    --The encounter is not flagged as inpatient
             THEN 'Y' 
             ELSE 'N' 
    END as "OFFICE_VISIT_YN"
       ,uclpat.PATIENT_ID
       ,uclpat.IMPLIED_UNIT_TYPE_C
       ,uclpat.ORDER_ID 
       ,uclpat.RX_CONT_DATE_REAL
       ,uclpat.RX_COMP_LINE
       ,uclpat.MEDICATION_ID 
       ,uclpat.IMPLIED_QTY_UNIT_C
       ,uclpat.IMPLIED_QTY
       ,uclpat.SERVICE_DATE_DT
       ,uclpat.DEPARTMENT_ID
       ,uclpat.HOSPITAL_ACCOUNT_ID
       ,uclpat.EPT_CSN
       ,uclpat.BILLING_PROVIDER_ID
       ,uclpat.DISP_UNIT_C 
        --Find the unit of the medication dispensed
        ,uclpat.DISPENSED_UNIT_C

       ,uclpat.MED_ID
       ,uclpat.MED_MED_ID
       ,uclpat.MED_MEDNAME
       ,uclpat.VOID_STATE
       ,uclpat.PRICE_OVERRIDE
       ,uclpat.LOC_ID
       ,uclpat.LOC_NAME
       ,uclpat.PARENT_LOCATION
       ,uclpat.NAME
       ,uclpat.ORDER_MED_ID  
       ,uclpat.CONTACT_DATE_REAL 
       ,uclpat.DISP_MED_CNTCT_ID 
       ,uclpat.ACTION_INSTANT               
       ,uclpat.BULK_DISP_YN                               
       ,uclpat.DISP_QTY         
       ,uclpat.CHARGE_METHOD_C      
       ,uclpat.STRENGTH 
       ,uclpat.DISPENSE_PHARM
       ,uclpat.LOCATION
       ,uclpat.CDM_MED_ID
    FROM UCL2USE uclpat
    INNER JOIN CLARITY_UCL_2 ucl2 ON uclpat.UCL_ID = ucl2.UCL_ID

    LEFT OUTER JOIN PATCLASS patclass ON uclpat.UCL_ID = patclass.UCL_ID
    INNER JOIN PAT_ENC enc ON uclpat.EPT_CSN = enc.PAT_ENC_CSN_ID
    LEFT OUTER JOIN ZC_DISP_ENC_TYPE zdetyp ON enc.ENC_TYPE_C = zdetyp.DISP_ENC_TYPE_C
    INNER JOIN PAT_ENC_2 enc2 ON enc.PAT_ENC_CSN_ID = enc2.PAT_ENC_CSN_ID
    LEFT OUTER JOIN PAT_ENC_HSP hsp ON uclpat.EPT_CSN = hsp.PAT_ENC_CSN_ID
    LEFT OUTER JOIN HSP_ACCOUNT har ON enc.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
    LEFT OUTER JOIN  ZC_PAT_CLASS zpc on har.ACCT_CLASS_HA_C = zpc.ADT_PAT_CLASS_C
    left outer join ZC_MED_UNIT DISPUNIT on uclpat.DISPENSED_UNIT_C = DISPUNIT.DISP_QTYUNIT_C

    ----Find procedure encounter for anesthesia charges
    left outer join AN_HSB_LINK_INFO hsbinfo on enc.PAT_ENC_CSN_ID=hsbinfo.AN_52_ENC_CSN_ID
    left outer join PAT_OR_ADM_LINK pator on pator.PAT_ENC_CSN_ID=hsbinfo.PRIMARY_PRC_ENC_CSN
    left outer join PAT_ENC_2 anes_admit_enc on pator.OR_LINK_CSN=anes_admit_enc.PAT_ENC_CSN_ID

    -- *TMH 281033 Find patient class and visit type based on ORD 48081
    left outer join ZC_PAT_CLASS patCLS2 on patCLS2.ADT_PAT_CLASS_C = patclass.RX_PATIENT_CLASS_C 
    left outer join HSD_BASE_CLASS_MAP map2 on map2.ACCT_CLASS_MAP_C = patclass.RX_PATIENT_CLASS_C
    left outer join ZC_ACCT_BASECLS_HA chargeCLS2 on map2.BASE_CLASS_MAP_C = chargeCLS2.ACCT_BASECLS_HA_C
    
    -- *TMH 281033 Find patient class and visit type for orders without Rx Patient Class listed
    left outer join CLARITY_ADT adt on adt.EVENT_ID = patclass.max_ID
    left outer join ZC_PAT_CLASS patCLS on patCLS.ADT_PAT_CLASS_C=adt.PAT_CLASS_C
    left outer join HSD_BASE_CLASS_MAP map on map.ACCT_CLASS_MAP_C = adt.PAT_CLASS_C
    left outer join ZC_ACCT_BASECLS_HA chargeCLS on map.BASE_CLASS_MAP_C = chargeCLS.ACCT_BASECLS_HA_C
   
   -- *TMH 316260 Find patient class and visit type based on UCL 1035
    left outer join ZC_PAT_CLASS UCLpatCLS on UCLpatCLS.ADT_PAT_CLASS_C = ucl2.PAT_CLASS_AT_CHARGE_TRIGGER_C 
    left outer join HSD_BASE_CLASS_MAP UCLmap on UCLmap.ACCT_CLASS_MAP_C = ucl2.PAT_CLASS_AT_CHARGE_TRIGGER_C
    left outer join ZC_ACCT_BASECLS_HA UCLchargeCLS on UCLmap.BASE_CLASS_MAP_C = UCLchargeCLS.ACCT_BASECLS_HA_C
) 
SELECT *
FROM
(
 SELECT a.*
    ,CASE WHEN a.PATIENT_CLASS like '%NEEDS REVIEW' THEN 1 ELSE 2 END "REVIEW_YN"

 FROM 
  (

    SELECT --*
    zimp.NAME "IMPLIED_UNIT_TYPE" 
    ,DISPUNIT.NAME as "DISPENSED_UNIT"
    ,pat.PAT_MRN_ID  "PAT_MRN"
    
    ,CASE WHEN penc.IMPLIED_UNIT_TYPE_C = 3
          THEN 'package'
          ELSE 
           ( CASE WHEN penc.IMPLIED_QTY_UNIT_C IS NULL
                  THEN 
                    CASE WHEN penc.IMPLIED_UNIT_TYPE_C=3 THEN ''
                    ELSE '*UNSPECIFIED UNIT' 
                    END
                  WHEN ZCUNIT.DISP_QTYUNIT_C IS NULL THEN '*UNKNOWN UNIT'
                  WHEN ZCUNIT.NAME IS NULL THEN '*UNNAMED UNIT'
                  ELSE ZCUNIT.NAME 
                  END )
     END "CALCULATED_CHARGE_UNIT"
          
    ,CASE WHEN penc.VOID_STATE >= 0 THEN ucl2.NUMBER_OF_PACKAGES ELSE ucl2.NUMBER_OF_PACKAGES * -1 END "CALCULATED_NUMBER_OF_PACKAGES"
    ,CASE WHEN penc.VOID_STATE > 0 THEN 1 ELSE -1 END *
          CASE WHEN (penc.IMPLIED_UNIT_TYPE_C IS NULL OR ( penc.IMPLIED_UNIT_TYPE_C = 3 AND ucl2.NUMBER_OF_PACKAGES IS NOT NULL)
                                                    OR penc.IMPLIED_QTY IS NULL)
               THEN ucl2.NUMBER_OF_PACKAGES
               ELSE penc.IMPLIED_QTY
      END "CHARGED_AMOUNT" 
    ,CASE WHEN (frxqt.EQUIV_MED_DISP_QTY IS NULL OR rx2.DISPENSE_UNIT_C IS NULL)
          THEN 
            CASE WHEN penc.DISP_QTY IS NULL THEN 0
                 WHEN penc.VOID_STATE >=0 THEN penc.DISP_QTY
                 ELSE -1* penc.DISP_QTY
                 END
          WHEN penc.VOID_STATE >= 0 THEN frxqt.EQUIV_MED_DISP_QTY
          ELSE -1* frxqt.EQUIV_MED_DISP_QTY
      END "AMOUNT_DISPENSED"            
     
     -- Visit type when charge dropped defaulting to ‘Outpatient’ if it’s a non-hospital encounter and finding the visit type otherwise.
    --CHARGE_CLASS
    ,CASE       
             --Look at UCL 1035 to find the visit type for the UCL first
             WHEN penc.UCL_PATIENT_CLASS is not NULL THEN penc.UCL_PATIENT_CLASS
    
             --Look at ORD 48081 to find visit type
             WHEN penc.PAT_CLS_2_NAME is not NULL THEN penc.PAT_CLS_2_NAME        
    
             --Check ADT event for visit type
             WHEN penc.CHG_CLS_2_NAME is not NULL THEN penc.CHG_CLS_2_NAME
    
             --If no ADT class is found, use the encounter level visit type
             WHEN penc.ADT_PAT_CLASS_C is not NULL THEN COALESCE((select ZC_ACCT_BASECLS_HA.NAME
                                                                                                        from HSD_BASE_CLASS_MAP
                                                                                                             left outer join ZC_ACCT_BASECLS_HA on HSD_BASE_CLASS_MAP.BASE_CLASS_MAP_C = ZC_ACCT_BASECLS_HA.ACCT_BASECLS_HA_C
                                                                                                        where HSD_BASE_CLASS_MAP.ACCT_CLASS_MAP_C=penc.ADT_PAT_CLASS_C),'*NEEDS REVIEW')
    
             --If the encounter has no patient class, check for an associated anesthesia encounter
             WHEN penc.ANES_PAT_CLASS_C is not null THEN COALESCE((select ZC_ACCT_BASECLS_HA.NAME
                                                                                                        from HSD_BASE_CLASS_MAP
                                                                                                              left outer join ZC_ACCT_BASECLS_HA on HSD_BASE_CLASS_MAP.BASE_CLASS_MAP_C = ZC_ACCT_BASECLS_HA.ACCT_BASECLS_HA_C
                                                                                                        where HSD_BASE_CLASS_MAP.ACCT_CLASS_MAP_C=penc.ANES_PAT_CLASS_C),'*NEEDS REVIEW')
    
             --Check is it's an office visit
             WHEN (penc.OFFICE_VISIT_YN='Y') THEN 'Office Visit'
          
            --A patient visit type for the charge could not be found
            ELSE '*NEEDS REVIEW'    
    
      END "CHARGE_CLASS"
    
    -- *TMH 281033 Find the patient class associated with the visit type 
    --PATIENT_CLASS
    ,CASE       
             --Look at UCL 1035 to find the patient class for the UCL first
             WHEN penc.UCL_PAT_CLASS_NAME is not NULL THEN penc.UCL_PAT_CLASS_NAME
    
             --Look at ORD 48081 to find patient class
             WHEN penc.PAT_CLS_2_NAME is not NULL THEN penc.PAT_CLS_2_NAME        
    
             --Check ADT event for patient class
             WHEN penc.PAT_CLS_NAME is not NULL THEN penc.PAT_CLS_NAME
    
             --If no ADT class found, use the encounter level patient class
             WHEN penc.ADT_PAT_CLASS_C is not NULL THEN (select ZC_PAT_CLASS.NAME
                                                                                       from ZC_PAT_CLASS
                                                                                       where ZC_PAT_CLASS.ADT_PAT_CLASS_C = penc."ADT_PAT_CLASS_C")
    
             --If the encounter has no patient class, check for an associated anesthesia encounter
             WHEN penc.ANES_PAT_CLASS_C is not null THEN (select ZC_PAT_CLASS.NAME
                                                                                       from ZC_PAT_CLASS
                                                                                       where ZC_PAT_CLASS.ADT_PAT_CLASS_C = penc.ANES_PAT_CLASS_C)
    
             --Check if it's an office visit
             WHEN (penc.OFFICE_VISIT_YN='Y') THEN 'Office Visit'
    
             --A patient class for the charge could not be found
             ELSE '*NEEDS REVIEW'
      END "PATIENT_CLASS"
     
      
    -- *TMH 285395 Determine what patient class source was used
    ,CASE   --PATIENT_CLASS_SOURCE
            WHEN penc.UCL_PAT_CLASS_NAME is not NULL THEN 'UCL 1035 - Rx Patient Class at Charge Trigger'
            WHEN penc.PAT_CLS_2_NAME is not NULL THEN 'ORD 48081 - Rx Patient Class'
            WHEN penc.PAT_CLS_NAME is not NULL THEN 'ADT 68 - ADT event prior to charge'
            WHEN penc.ADT_PAT_CLASS_C is not NULL THEN 'EPT 10110 - ADT Patient Class'
            WHEN penc.ANES_PAT_CLASS_C is not null THEN 'EPT 10110 - ADT Patient Class for linked admission'
            WHEN (penc.OFFICE_VISIT_YN='Y') THEN 'Non-ADT encounter'
            ELSE 'No source found'
      END "PATIENT_CLASS_SOURCE"
      
    ,CASE 
           WHEN penc.MED_ID IS NULL THEN '*UNSPECIFIED MEDICATION'
           WHEN penc.MED_MED_ID IS NULL THEN CONCAT('*UNKNOWN MEDICATION [',CONCAT(CAST(penc.MED_ID AS VARCHAR(18)),']'))
           WHEN penc.MED_MEDNAME IS NULL THEN CONCAT('*UNNAMED MEDICATION [',CONCAT(CAST(penc.MED_ID AS VARCHAR(18)),']'))
           ELSE CONCAT(penc.MED_MEDNAME,CONCAT(' [',CONCAT(CAST(penc.MED_ID AS VARCHAR(18)),']')))
     END AS MEDICATION_NM_WID
     
     ,CONCAT(COALESCE(rxndc.NDC_CODE,'*Unknown NDC Code'),CONCAT(' (',CONCAT(COALESCE(cast(rxndc.PACKAGE_SIZE as VARCHAR(10)),'*Unknown Package Size'),CONCAT(' ',CONCAT(COALESCE(ZCNDCUNIT.NAME, '*Unknown Package Unit'),')'))))) as NDC_CODE_PACKAGE_SIZE
    
    ,CASE 
            WHEN penc.DEPARTMENT_ID IS NULL THEN '*UNSPECIFIED CHARGE DEPARTMENT'
            WHEN CHGDEP.DEPARTMENT_ID IS NULL THEN CONCAT('*UNKNOWN CHARGE DEPARTMENT [',CONCAT(CAST(penc.DEPARTMENT_ID AS VARCHAR(18)),']'))
            WHEN CHGDEP.DEPARTMENT_NAME IS NULL THEN CONCAT('*UNNAMED CHARGE DEPARTMENT [',CONCAT(CAST(penc.DEPARTMENT_ID AS VARCHAR(18)),']'))
            ELSE CONCAT(CHGDEP.DEPARTMENT_NAME,CONCAT(' [',CONCAT(CAST(penc.DEPARTMENT_ID AS VARCHAR(18)),']')))
    END AS "CHARGE_DEPARTMENT_NM_WID"
    
    ,CASE 
           WHEN penc.IMPLIED_UNIT_TYPE_C=3 THEN 'package'
           WHEN penc.IMPLIED_QTY_UNIT_C IS NULL THEN '*UNSPECIFIED UNIT'
           WHEN ZCUNIT.DISP_QTYUNIT_C IS NULL THEN '*UNKNOWN UNIT'
           WHEN ZCUNIT.NAME IS NULL THEN '*UNNAMED UNIT'
           ELSE ZCUNIT.NAME 
    END as "IMPLIED_QTY_UNIT_NAME"
    
     --Returns 1 if the patient changed classes during the encounter, 0 otherwise
    ,CASE 
              WHEN (CASE 
                                WHEN penc.OP_ADM_EVENT_ID is not null THEN 1 
                                 ELSE 0 
                         END)
             + (CASE WHEN penc.INP_ADM_EVENT_ID is not null THEN 1 ELSE 0 END)
             + (CASE WHEN penc.EMER_ADM_EVENT_ID is not null THEN 1 ELSE 0 END)
             > 1 THEN 1
             ELSE 0
    END "CHANGED_CLASSES"
    
     
    ,ucl2.NUMBER_OF_PACKAGES "NUMBER_OF_PACKAGES"
    ,penc.UCL_PATIENT_CLASS  "UCL_PATIENT_CLASS"
    ,penc.HSP_ACCOUNT_ID    "HSP_ACCOUNT_ID"
    ,penc.PAT_ENC_CSN_ID    "PAT_ENC_CSN_ID"
    ,penc.ENCOUNTER_TYPE
    ,penc.ADT_PAT_CLASS_C   "ADT_PAT_CLASS_C"
    ,CASE WHEN LOCATION = 'MAIN' AND penc.CDM_MED_ID IS NOT NULL THEN rxndc.RAW_11_DIGIT_NDC || '_' || penc.CDM_MED_ID 
              WHEN LOCATION IN ('HPR','WILKES') THEN rxndc.RAW_11_DIGIT_NDC || '_' || penc.MED_MED_ID                             -----2/11/2021
              ELSE rxndc.RAW_11_DIGIT_NDC END  "CDM"
    ,rxndc.RAW_11_DIGIT_NDC "RAW_11_DIGIT_NDC"
    ,rxndc.RAW_NDC_CODE     "RAW_NDC_CODE"
    ,rxndc.BILLABLE_NDC_ID   "BILLABLE_NDC_ID"
    ,penc.UCL_ID                "UCL_ID"
    ,penc.IMPLIED_QTY * penc.VOID_STATE   "IMPLIED_QTY"
    ,rxndc.NDC_CODE         "NDC_CODE"
    ,rxndc.PACKAGE_SIZE     "V_PACKAGE_SIZE"
    ,penc.SERVICE_DATE_DT    "SERVICE_DATE"
    ,ZCNDCUNIT.NAME         "PACKAGE_UNIT"
    ,penc.STRENGTH          "STRENGTH"
    ,penc.ORDER_MED_ID      "ORDER_ID"
    ,penc.ACTION_INSTANT       "CHARGE_CREATION_TIME"
    ,penc.BULK_DISP_YN      "IS_BULK"
    ,penc.CHG_CLS_2_NAME  "CHG_CLS_2_NAME"
    ,penc.PAT_CLS_2_NAME  "PAT_CLS_2_NAME"
    ,penc.UCL_PAT_CLASS_NAME "UCL_PAT_CLASS_NAME"
    ,penc.ADT_PAT_CLASS_C "ANES_PAT_CLASS_C"
    ,ZCNDCUNIT.ABBR      "MED_UNIT_NAME_ABBR"
    ,penc.LOC_ID          "REV_LOC_ID"
    ,penc.LOC_NAME        "REV_LOC_NAME"
    ,penc.PARENT_LOCATION
    ,penc.PRICE_OVERRIDE  "TOTAL_CHARGE"
    ,penc.MED_ID    "MED_ID"
    ,penc.NAME         "RPT_GRP_SIX"
    ,penc.DEPARTMENT_ID  "DEPARTMENT_ID"
    ,penc.CHARGE_METHOD_C "CHARGE_METHOD"
    ,billingNPI.NPI       "PrescribingNPI"                                                                        
    ,penc.HOSPITAL_ACCOUNT_ID 
    ,penc.DISPENSE_PHARM 
    ,ins.primary_PNAME    "PrimaryPayor"
    ,ins.secondary_PNAME  "SecondaryPayor"
    ,ins.tertiary_PNAME   "TertiaryPayor" 
    ,penc.VOID_STATE  
    ,penc.MED_MED_ID
    ,penc.LOCATION
    ,penc.CDM_MED_ID
    FROM PATENC penc  
    LEFT OUTER JOIN ZC_IMP_EXT_UNIT zimp ON penc.IMPLIED_UNIT_TYPE_C = zimp.IMP_EXT_UNIT_C
    LEFT OUTER JOIN PATIENT pat ON penc.PATIENT_ID = pat.PAT_ID
    INNER JOIN CLARITY_UCL_2 ucl2 ON penc.UCL_ID = ucl2.UCL_ID
    LEFT OUTER JOIN INSURERS ins ON penc.UCL_ID = ins.INS_UCL_ID AND penc.HOSPITAL_ACCOUNT_ID = ins.HSP_ACCOUNT_ID
    LEFT OUTER JOIN F_RX_EQUIV_DISP_QTY frxqt ON penc.ORDER_ID = frxqt.ORDER_MED_ID 
                    AND penc.RX_COMP_LINE = frxqt.LINE
                    AND penc.DISP_MED_CNTCT_ID = frxqt.CONTACT_DATE_REAL
    LEFT OUTER JOIN RX_MED_TWO rx2 ON penc.MED_ID = rx2.MEDICATION_ID
    INNER JOIN UCL_NDC_CODES uclndc ON penc.UCL_ID = uclndc.UCL_ID AND (uclndc.LINE = 1 OR uclndc.LINE IS NULL)
    INNER JOIN RX_NDC rxndc ON uclndc.NDC_CODE_ID = rxndc.NDC_ID
    LEFT OUTER JOIN CLARITY_DEP CHGDEP ON penc.DEPARTMENT_ID = CHGDEP.DEPARTMENT_ID
    LEFT OUTER JOIN ZC_MED_UNIT ZCNDCUNIT on rxndc.MED_UNIT_C = ZCNDCUNIT.DISP_QTYUNIT_C
    LEFT OUTER JOIN ZC_MED_UNIT ZCUNIT ON penc.IMPLIED_QTY_UNIT_C = ZCUNIT.DISP_QTYUNIT_C
    left outer JOIN CLARITY_SER_2 billingNPI ON penc.BILLING_PROVIDER_ID = billingNPI.PROV_ID
    left outer join ZC_MED_UNIT DISPUNIT on penc.DISPENSED_UNIT_C = DISPUNIT.DISP_QTYUNIT_C
   )a   

)b
WHERE
(b.REVIEW_YN = {?NeedsReview}  OR '0' IN {?NeedsReview})













