SELECT
    vlb.LOG_ID "Log ID"
    , vlb.PROC_DATE "Surgery Date"
    , pat.PAT_ID "Pat ID"
    , pat.PAT_MRN_ID "MRN"
    , FLOOR((vlb.PROC_DATE - pat.BIRTH_DATE) / 365.25) "Age at Encounter"
    , pat.PAT_NAME "Patient Name"
    , loc2.LOC_NAME "Parent Location"
    , loc.LOC_NAME
    , vlb.SERVICE_NM "Service"
    , zc_bc.NAME "Account Base Class"
    , zc_cc.NAME "Case Class Name"
    , vlb.ROOM_NM "OR Room"
    , vlb.PRIMARY_PHYSICIAN_NM "Primary Physician"
    , vlb.PRIMARY_PROCEDURE_NM "Primary Procedure"
    , peh.HOSP_DISCH_TIME "Discharge DateTime"
    , zc_dsp.NAME "Discharge Disposition"
    , zc_dst.NAME "Discharge Destination"

FROM V_LOG_BASED vlb
    INNER JOIN PATIENT pat ON vlb.PAT_ID = pat.PAT_ID
    INNER JOIN PAT_OR_ADM_LINK pal ON vlb.LOG_ID = pal.LOG_ID
    INNER JOIN PAT_ENC_HSP peh ON pal.OR_LINK_CSN = peh.PAT_ENC_CSN_ID
    INNER JOIN ZC_DISCH_DISP zc_dsp ON peh.DISCH_DISP_C = zc_dsp.DISCH_DISP_C
    INNER JOIN HSP_ACCOUNT hsp ON peh.HSP_ACCOUNT_ID = hsp.HSP_ACCOUNT_ID
    INNER JOIN ZC_ACCT_BASECLS_HA zc_bc ON hsp.ACCT_BASECLS_HA_C = zc_bc.ACCT_BASECLS_HA_C
    LEFT OUTER JOIN ZC_OR_CASE_CLASS zc_cc ON vlb.CASE_CLASS_C = zc_cc.CASE_CLASS_C
    LEFT OUTER JOIN CLARITY_LOC loc ON vlb.LOCATION_ID = loc.LOC_ID
    LEFT OUTER JOIN CLARITY_LOC loc2 ON loc.HOSP_PARENT_LOC_ID = loc2.LOC_ID
    LEFT OUTER JOIN ZC_DISCH_DEST zc_dst ON peh.DISCH_DEST_C = zc_dst.DISCH_DEST_C    

WHERE 
    vlb.PROC_DATE > '29-FEB-2020'
    AND FLOOR((vlb.PROC_DATE - pat.BIRTH_DATE) / 365.25) >= 18
    AND peh.DISCH_DISP_C IN ('11','205','204','224','70','223','10','5','215','66','221','218','210','50','51'
                    ,'4','214','7','63','220','64','65','62','2','3','213')
    AND hsp.ACCT_BASECLS_HA_C = 1   
    
