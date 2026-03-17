SELECT DISTINCT
    pat.PAT_MRN_ID  "MRN"
    , pat.PAT_NAME "Patient Name"
    , pat.BIRTH_DATE "Date of Birth"
    , pat.DEATH_DATE "Date of Death"
    , ser.PROV_NAME "Ordering Provider"
    , ser2.PROV_NAME "Authorizing Provider"
    , ser2.PROV_ID
    , om.ORDERING_DATE "Ordering Date"
    , om.ORDER_MED_ID "Order Med ID"
    , om.PAT_LOC_ID "Ordering Location ID"
    , dep.DEPARTMENT_NAME "Ordering Location Name"
    , loc2.LOC_NAME "Parent Location"
    , cm.MEDICATION_ID "ERX ID"
    , cm.NAME "Medication Name"

FROM ORDER_MED om
    LEFT OUTER JOIN PATIENT pat ON om.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN CLARITY_MEDICATION cm ON om.MEDICATION_ID = cm.MEDICATION_ID
    LEFT OUTER JOIN CLARITY_SER ser ON om.ORD_PROV_ID = ser.PROV_ID
    LEFT OUTER JOIN CLARITY_SER ser2 ON om.AUTHRZING_PROV_ID = ser2.PROV_ID
    LEFT OUTER JOIN CLARITY_DEP dep ON om.PAT_LOC_ID = dep.DEPARTMENT_ID
    LEFT OUTER JOIN CLARITY_LOC loc ON dep.REV_LOC_ID = loc.LOC_ID
    LEFT OUTER JOIN CLARITY_LOC loc2 ON loc.HOSP_PARENT_LOC_ID = loc2.LOC_ID

WHERE
    (ser.PROV_ID IN ('10825', '10838', '10826', '38368', '11032')
    OR ser2.PROV_ID IN ('10825', '10838', '10826', '38368', '11032'))
    AND om.ORDERING_DATE > '31-DEC-2019'

ORDER BY
    ser2.PROV_ID
    , cm.NAME
    , om.ORDERING_DATE
