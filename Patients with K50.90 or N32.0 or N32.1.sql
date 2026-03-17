SELECT
    pat.PAT_MRN_ID
    , pat.PAT_NAME
    , hsp.DISCH_DATE_TIME
    , zc_bc.NAME "Base Class"
    , edg.DX_NAME
    , icd.CODE
    , dep.DEPARTMENT_NAME
    , loc.LOC_NAME
    
FROM HSP_ACCT_DX_LIST dx
    INNER JOIN HSP_ACCOUNT hsp ON dx.HSP_ACCOUNT_ID = hsp.HSP_ACCOUNT_ID
    INNER JOIN PATIENT pat ON hsp.PAT_ID = pat.PAT_ID
    INNER JOIN ZC_ACCT_BASECLS_HA zc_bc ON hsp.ACCT_BASECLS_HA_C = zc_bc.ACCT_BASECLS_HA_C
    INNER JOIN CLARITY_EDG edg ON dx.DX_ID = edg.DX_ID
    INNER JOIN EDG_CURRENT_ICD10 icd ON edg.DX_ID = icd.DX_ID
    INNER JOIN CLARITY_DEP dep ON hsp.DISCH_DEPT_ID = dep.DEPARTMENT_ID
    INNER JOIN CLARITY_LOC loc ON hsp.LOC_ID = loc.LOC_ID

WHERE
    loc.LOC_ID = 100000
    AND ((icd.CODE = 'K50.90'
        AND hsp.DISCH_DATE_TIME > '30-SEP-2017')
    OR icd.CODE = 'N32.0'
    OR icd.CODE = 'N32.1')