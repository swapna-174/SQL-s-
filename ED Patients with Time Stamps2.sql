WITH PT_DATA
AS
(
SELECT DISTINCT *
FROM
    (
    SELECT *
    FROM
        (
        SELECT
            pat.PAT_ID "Epic Internal Patient ID"
            , pat.PAT_MRN_ID "Medical Record Number"
            , fed.PAT_ENC_CSN_ID "Patient Encounter Number"
            , pat.PAT_NAME "Patient Full Name"
            , pat.BIRTH_DATE "Birth Date"
            , zc_sx.NAME "Patient Gender"
            , pat.ADD_LINE_1"Patient Address 1"
            , pat.ADD_LINE_2 "Patient Address 2"
            , pat.CITY "Patient City"
            , zc_cty.NAME "Patient County"
            , zc_st.NAME "Patient Sate"
            , pat.ZIP "Patient Zip"
            , zc_am.NAME "Arrival Method"
            , rsn.REASON_VISIT_NAME "Chief Complaint"
            , zc_ed.NAME "ED Disposition"
            , zc_al.ACUITY_LEVEL_C "Acuity Level"
            , zc_al.NAME "Acuity Name"
            , par.LOC_NAME "Parent Location"
            , edc.CARE_AREA_NAME "Primary Care Area"
            , dep.DEPARTMENT_NAME "Last Care Area"
            , dep2.DEPARTMENT_NAME "Hospitalized Department" 
            , fed.ADT_ARRIVAL_DTTM "ED Arrival DateTime"
--            , ed_evt.EVENT_ID
            , ed_evt.EVENT_TYPE "Event Type"
            , ed_evt.EVENT_TIME  "Event Time"
            , RANK() OVER ( PARTITION BY fed.PAT_ENC_CSN_ID, ed_evt.EVENT_TYPE 
                ORDER BY ed_evt.EVENT_TIME) rank 
            
        FROM F_ED_ENCOUNTERS fed
            INNER JOIN PATIENT pat ON fed.PAT_ID = pat.PAT_ID
            LEFT OUTER JOIN ZC_SEX zc_sx ON pat.SEX_C = zc_sx.RCPT_MEM_SEX_C
            LEFT OUTER JOIN ZC_COUNTY zc_cty ON pat.COUNTY_C = zc_cty.COUNTY_C
            LEFT OUTER JOIN ZC_STATE zc_st ON pat.STATE_C = zc_st.STATE_C
            LEFT OUTER JOIN ZC_ARRIV_MEANS zc_am ON fed.MEANS_OF_ARRIVAL_C = zc_am.MEANS_OF_ARRV_C
            LEFT OUTER JOIN CL_RSN_FOR_VISIT rsn ON fed.FIRST_CHIEF_COMPLAINT_ID = rsn.REASON_VISIT_ID
            LEFT OUTER JOIN ZC_ED_DISPOSITION zc_ed ON fed.ED_DISPOSITION_C = zc_ed.ED_DISPOSITION_C
            LEFT OUTER JOIN ZC_ACUITY_LEVEL zc_al ON fed.ACUITY_LEVEL_C = zc_al.ACUITY_LEVEL_C
            LEFT OUTER JOIN ED_CARE_AREA_INFO edc ON fed.ED_PRIMARY_CARE_AREA_ID = edc.CARE_AREA_ID
            LEFT OUTER JOIN CLARITY_DEP dep ON fed.LAST_EMERGENCY_DEPARTMENT_ID = dep.DEPARTMENT_ID
            LEFT OUTER JOIN CLARITY_ADT adt ON fed.PAT_ENC_CSN_ID = adt.PAT_ENC_CSN_ID
                AND adt.FIRST_IP_IN_IP_YN = 'Y'
            LEFT OUTER JOIN CLARITY_DEP dep2 ON adt.DEPARTMENT_ID = dep2.DEPARTMENT_ID
            LEFT OUTER JOIN ED_IEV_PAT_INFO ed_pat ON fed.PAT_ENC_CSN_ID = ed_pat.PAT_CSN
            LEFT OUTER JOIN ED_IEV_EVENT_INFO ed_evt ON ed_pat.EVENT_ID = ed_evt.EVENT_ID
            LEFT OUTER JOIN ED_EVENT_TMPL_INFO ed_tmp ON ed_evt.EVENT_TYPE = ed_tmp.RECORD_ID
            LEFT OUTER JOIN CLARITY_LOC loc ON dep.REV_LOC_ID = loc.LOC_ID
            LEFT OUTER JOIN CLARITY_LOC par ON loc.HOSP_PARENT_LOC_ID = par.LOC_ID
    
        WHERE
--            fed.ADT_ARRIVAL_DATE >= '01-Jan-2020'
--            AND fed.ADT_ARRIVAL_DATE < '01-Apr-2020'
            fed.ADT_ARRIVAL_DATE >= EPIC_UTIL.EFN_DIN(‘{?StartDate}’)
	        AND fed.ADT_ARRIVAL_DATE <= EPIC_UTIL.EFN_DIN(‘{?EndDate}’)
            AND ed_evt.EVENT_TYPE IN ('205', '210', '55', '16011121', '222', '16000301', '160491502', '110', '16011101', '60', '16012101', '231'
                , '16022281', '1061223', '1603007102', '320', '30050', '322', '30060', '30', '16023101','16026330','16026030','16026430'
                ,'16026530','16026130','16026230','16026302','16026002','16026402','16026502','16026102','16026202')
        )
    WHERE rank = 1
    )

PIVOT 
        (MAX("Event Time") FOR "Event Type" IN 
                        ('205' AS "ED Triage Start DT"
                        ,'210' AS "ED Triage End DT"
                        , '55' AS "ED Roomed DT"
                        , '16011121' AS "First Provider Contact DT"
                        ,'222' AS "ED Disposition DT"
                        ,'16000301'   AS "Admitted From ED DT"
                        ,'160491502' AS "ED Depart DT"
                        ,'16011101' AS "First Assigned Attend DT"
                        ,'60' AS "ED Discharge DT"
                        ,'16012101'   AS "First Assigned RN DT"
                        ,'231'   AS "Bed Request DT"
                        ,'1061223'   AS "Admit Order DT"
                        ,'1603007102'   AS "Consult Ordered DT"
                        ,'30050'   AS "Consult Called DT"
                        ,'322'   AS "Consult Recalled DT"
                        ,'30060'   AS "Consult Completed DT"
                        ,'30'   AS "Patient Ready for Discharge DT"
                        ,'16023101'   AS "IP Bed Assigned DT"                                      
                        , 16026330 AS "Hospitalist Arrived"
                        , 16026030 AS "Hospitalist Consult Called"
                        , 16026430 AS "Hospitalist Complete"
                        , 16026530 AS "Hospitalist Ordered"
                        , 16026130 AS "Hospitalist Re-Called"
                        , 16026230 AS "Hospitalist Responded"                                        
                        , 16026302 AS "Psychiatry Arrived"
                        , 16026002 AS "Psychiatry Called"
                        , 16026402 AS "Psychiatry Complete"
                        , 16026502 AS "Psychiatry Ordered"
                        , 16026102 AS "Psychiatry Re-Called"
                        , 16026202 AS "Psychiatry Responded"
                        )
          )
)

, PROV_NAMES
AS
(
SELECT *
FROM
    (
    SELECT *
    FROM
        (       
        SELECT 
            ptd."Patient Encounter Number"
            , ed_evt.EVENT_TYPE "Event Type"
            , ser.PROV_NAME "Prov Name"
            , RANK() OVER ( PARTITION BY ptd."Patient Encounter Number", ed_evt.EVENT_TYPE 
                    ORDER BY ed_evt.EVENT_TIME) rank 
        FROM PT_DATA ptd
            INNER JOIN ED_IEV_PAT_INFO ed_pat ON ptd."Patient Encounter Number" = ed_pat.PAT_CSN
            INNER JOIN ED_IEV_EVENT_INFO ed_evt ON ed_pat.EVENT_ID = ed_evt.EVENT_ID
                AND ed_evt.EVENT_TYPE IN ('16011101', '16012101')
            INNER JOIN CLARITY_SER ser ON ed_evt.EVENT_PROV_ID = ser.PROV_ID
        )
    WHERE rank = 1   
    )
    
PIVOT
    
    (MAX("Prov Name") FOR "Event Type" IN 
            ('16011101' AS "First Assigned Attend Name"
            , '16012101'   AS "First Assigned RN Name"
            )
    )
)

, BED_NAMES
AS
(
SELECT *
FROM
    (
    SELECT *
    FROM
        (       
        SELECT 
            ptd."Patient Encounter Number"
            , ptd."Medical Record Number"
            , ed_evt.EVENT_TYPE "Event Type"
            , emp.NAME "Bed Request User"
            , RANK() OVER ( PARTITION BY ptd."Patient Encounter Number", ed_evt.EVENT_TYPE 
                    ORDER BY ed_evt.EVENT_TIME) rank 
        FROM PT_DATA ptd
            INNER JOIN ED_IEV_PAT_INFO ed_pat ON ptd."Patient Encounter Number" = ed_pat.PAT_CSN
            INNER JOIN ED_IEV_EVENT_INFO ed_evt ON ed_pat.EVENT_ID = ed_evt.EVENT_ID
                AND ed_evt.EVENT_TYPE = '231'
            INNER JOIN CLARITY_EMP emp ON ed_evt.EVENT_USER_ID = emp.USER_ID
        )
    WHERE rank = 1   
    )
)
  
SELECT DISTINCT
            ptd."Epic Internal Patient ID"
--            , ptd.EVENT_ID
            , ptd."Medical Record Number"
            , ptd."Patient Encounter Number"
            , ptd."Patient Full Name"
            , ptd."Birth Date"
            , ptd."Patient Gender"
            , ptd."Patient Address 1"
            , ptd."Patient Address 2"
            , ptd."Patient City"
            , ptd."Patient County"
            , ptd."Patient Sate"
            , ptd."Patient Zip"
            , ptd."Arrival Method"
            , ptd."Chief Complaint"
            , ptd."ED Disposition"
            , ptd."Acuity Level"
            , ptd."Acuity Name"
            , ptd."Parent Location"
            , ptd."Primary Care Area"
            , ptd."Last Care Area"
            , ptd."Hospitalized Department" 
            , ptd."ED Arrival DateTime"
            , ptd."ED Triage Start DT"
            , ptd."ED Triage End DT"
            , ptd."ED Roomed DT"
            , ptd."First Provider Contact DT"            
            , ptd."ED Disposition DT"
            , ptd."Admitted From ED DT"
            , ptd."ED Depart DT"
            , ptd."First Assigned Attend DT"
            , prv."First Assigned Attend Name"
            , ptd."ED Discharge DT"
            , ptd."First Assigned RN DT"
            , prv."First Assigned RN Name"
            , ptd."Bed Request DT"
            , bdn."Bed Request User"
            , ptd."Admit Order DT"
            , ptd."Consult Ordered DT"
            , ptd."Consult Called DT"
            , ptd."Consult Recalled DT"
            , ptd."Consult Completed DT"
            , ptd."Patient Ready for Discharge DT"
            , ptd."IP Bed Assigned DT"                                      
            , ptd."Hospitalist Arrived"
            , ptd."Hospitalist Consult Called"
            , ptd."Hospitalist Complete"
            , ptd."Hospitalist Ordered"
            , ptd."Hospitalist Re-Called"
            , ptd."Hospitalist Responded"                                        
            , ptd."Psychiatry Arrived"
            , ptd."Psychiatry Called"
            , ptd."Psychiatry Complete"
            , ptd."Psychiatry Ordered"
            , ptd."Psychiatry Re-Called"
            , ptd."Psychiatry Responded"
FROM PT_DATA ptd
    LEFT OUTER JOIN PROV_NAMES prv ON ptd."Patient Encounter Number" = prv."Patient Encounter Number"
    LEFT OUTER JOIN BED_NAMES bdn ON ptd."Patient Encounter Number" = bdn."Patient Encounter Number"