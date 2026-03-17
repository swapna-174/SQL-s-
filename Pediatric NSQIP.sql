SELECT DISTINCT
    vlb.CASE_ID "Case ID"
    , vlb.ROOM_NM "Location"
    , TO_CHAR(vlb.PROC_DATE,'MM/DD/YYYY') "Surgery Date"
    , TO_CHAR(CASE_SCHEDULED_START_DTTM, 'HH24:MI:SS AM')"Surgery Time"
    , pat.PAT_MRN_ID "MRN"
    , pat.PAT_LAST_NAME "Patient Last Name"
    , pat.PAT_FIRST_NAME "Patient First Name"
    , TO_CHAR(pat.BIRTH_DATE,'MM/DD/YYYY') "Patient DOB"
    , vlb.PAT_AGE "Patient Age"
    , ser.PROV_NAME "Surgeon"
    , pbt.CPT_CODE "CPT Code"
    , eap.PROC_NAME "Procedure Name"

FROM ARPB_TRANSACTIONS pbt
    LEFT OUTER JOIN PATIENT pat ON pbt.PATIENT_ID = pat.PAT_ID
    LEFT OUTER JOIN CLARITY_LOC loc ON pbt.LOC_ID = loc.LOC_ID
    LEFT OUTER JOIN CLARITY_SER ser ON pbt.SERV_PROVIDER_ID = ser.PROV_ID
    LEFT OUTER JOIN CLARITY_EAP eap ON pbt.PROC_ID = eap.PROC_ID 
    LEFT OUTER JOIN ARPB_TX_MODERATE atm ON pbt.TX_ID = atm.TX_ID
    LEFT OUTER JOIN V_LOG_BASED vlb ON atm.SURGICAL_LOG_ID = vlb.LOG_ID
    
WHERE
    pbt.SERVICE_DATE >= EPIC_UTIL.EFN_DIN('mb-2')
    AND pbt.SERVICE_DATE <= EPIC_UTIL.EFN_DIN('me-2')
    AND pbt.VOID_DATE IS NULL
    AND pbt.CPT_CODE IN ('42961', '42962', '43194', '43215', '43247', '44055', '44120', '44140', '44141', '44143', 
        '44144', '44145', '49320', '49321', '49322', '58660', '58661', '58662', '58679', '58740', 
        '58805', '58900', '58920', '58925', '58940', '58943', '58950', '58999', '54600', '54520', 
        '54620', '54640', '54512', '54650')
    AND vlb.LOG_STATUS_C IN (2,5)
    AND vlb.PAT_AGE < 19
