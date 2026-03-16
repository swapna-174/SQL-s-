SELECT 
    pat.PAT_MRN_ID "PatientMRN"
    , pat.PAT_NAME "Name"
    , pat.PAT_FIRST_NAME "FirstName"
    , pat.PAT_MIDDLE_NAME "MiddleName"
    , pat.PAT_LAST_NAME "LastName"
    , zc_sfx.NAME "Suffix"
    , pat.DEATH_DATE "DeathDate"
    , elog.EPT_PAT_EVENT_DTTM "UpdateDate"
FROM PATIENT pat
    LEFT OUTER JOIN X_EPT_PAT_EVENT_LOG_EV58 elog ON pat.PAT_ID = elog.PAT_ID
    LEFT OUTER JOIN ZC_PAT_NAME_SUFFIX zc_sfx ON pat.PAT_NAME_SUFFIX_C = zc_sfx.PAT_NAME_SUFFIX_C
WHERE 
    pat.PAT_STATUS_C = '2'
    AND pat.PAT_FIRST_NAME <> 'RESEARCH'
    AND pat.PAT_FIRST_NAME <> 'Research'
    AND NOT(pat.PAT_MRN_ID LIKE '<%')
    AND NOT(pat.SEX_C IS NULL
        AND pat.BIRTH_DATE IS NULL)
-- Date for testing
    AND TRUNC(elog.EPT_PAT_EVENT_DTTM) >= '01-NOV-14'
--    AND TRUNC(elog.EPT_PAT_EVENT_DTTM) < '17-MAR-17'








