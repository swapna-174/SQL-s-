

--select * from order_med om
--LEFT OUTER JOIN CLARITY_MEDICATION cm ON om.MEDICATION_ID = cm.MEDICATION_ID
--left outer join patient pat on om.PAT_ID = pat.PAT_ID
--where om.ORDERING_DATE between '01-jan-2016' AND '31-jan-2017'
----and cm.MEDICATION_ID = '10178'
--and om.AMB_MED_DISP_NAME like '%HEPARIN%'||'%PORCINE%'
--and om.ORDERING_MODE_C = 1
--and pat.PAT_MRN_ID = '1655878'

SELECT DISTINCT
    pat.PAT_MRN_ID  "MRN"
    , pat.PAT_NAME "Patient Name"
    , pat.BIRTH_DATE "Date of Birth"
    , pat.DEATH_DATE "Date of Death"
    --,zsx.NAME  "Gender"
    --,TRUNC((SYSDATE - pat.BIRTH_DATE) / 365.25) "Age"
    --,zpr.NAME  "Race"
    , ser.PROV_NAME "Ordering Provider"
    , ser2.PROV_NAME "Authorizing Provider"
    , om.ORDERING_DATE "Ordering Date"
    , om.ORDER_MED_ID "Order Med ID"
    , om.PAT_LOC_ID "Ordering Location ID"
    , dep.DEPARTMENT_NAME "Ordering Location Name"
    , loc2.LOC_NAME "Parent Location"
    --, om.ORDERING_MODE_C
    --,om.AMB_MED_DISP_NAME
    --, om.DISPLAY_NAME
    , cm.MEDICATION_ID "ERX ID"
    , cm.NAME "Medication Name"
    --,om.sig
    --,om.QUANTITY
FROM ORDER_MED om
    LEFT OUTER JOIN PATIENT pat ON om.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN CLARITY_MEDICATION cm ON om.MEDICATION_ID = cm.MEDICATION_ID
    LEFT OUTER JOIN CLARITY_SER ser ON om.ORD_PROV_ID = ser.PROV_ID
    LEFT OUTER JOIN CLARITY_SER ser2 ON om.AUTHRZING_PROV_ID = ser2.PROV_ID
    LEFT OUTER JOIN CLARITY_DEP dep ON om.PAT_LOC_ID = dep.DEPARTMENT_ID
    LEFT OUTER JOIN CLARITY_LOC loc ON dep.REV_LOC_ID = loc.LOC_ID
    LEFT OUTER JOIN CLARITY_LOC loc2 ON loc.HOSP_PARENT_LOC_ID = loc2.LOC_ID
    --LEFT OUTER JOIN CLARITY_EDG edg ON ped.DX_ID = edg.DX_ID
    --LEFT OUTER JOIN ZC_ETHNIC_GROUP zeg ON pat.ETHNIC_GROUP_C = zeg.ETHNIC_GROUP_C
    --left outer join PATIENT_RACE race on pat.PAT_ID = race.PAT_ID and race.LINE = 1
    --left outer join ZC_PATIENT_RACE zpr on race.PATIENT_RACE_C = zpr.PATIENT_RACE_C
    --LEFT OUTER JOIN ZC_SEX zsx ON pat.SEX_C = zsx.RCPT_MEM_SEX_C
WHERE
    (UPPER(om.AMB_MED_DISP_NAME) LIKE '%DENOSUMAB%'
    OR UPPER(om.DISPLAY_NAME) LIKE '%DENOSUMAB%'
    OR UPPER(cm.NAME) LIKE'%DENOSUMAB%'
    OR UPPER(om.AMB_MED_DISP_NAME) LIKE '%PROLIA%'
    OR UPPER(om.DISPLAY_NAME) LIKE '%PROLIA%'
    OR UPPER(cm.NAME) LIKE'%PROLIA%')
    AND om.PAT_LOC_ID = 1021101024

    
--    cm.MEDICATION_ID IN (174227, 174228,174229,174230,174221,174222,174223,174220,190491,190490)
--    AND om.ORDERING_MODE_C = 1
ORDER BY
    pat.PAT_MRN_ID
    , om.ORDERING_DATE
