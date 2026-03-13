        SELECT 
        hsp.PAT_ID
        ,pat.PAT_MRN_ID
        ,pat.PAT_NAME
        ,hsp.HOSP_ADMSN_TIME
        ,hsp.HOSP_DISCH_TIME
        ,hsp.PAT_ENC_CSN_ID
        ,edg.DX_ID
        ,edg.DX_NAME "ADMITDXNM"
        ,edg.CURRENT_ICD10_LIST "ADMITDX10"
        ,parloc.LOC_ID
        ,parloc.LOC_NAME
        ,hsp.ADT_PAT_CLASS_C
        ,zpc.NAME  "PATIENT_CLASS"
        ,zsrv.NAME "DISCHARGE_SERVICE"
        ,zps.NAME   "DISCHARGE_DISPOSITION"
        ,tobco.CONTACT_DATE
        ,ztu.NAME "TOBACCO_USER"
        ,tobco.TOBACCO_PAK_PER_DY
        ,tobco.SMOKING_QUIT_DATE
        ,tobco.CIGARETTES_YN
        ,tobco.TOBACCO_COMMENT
        ,CASE WHEN ACSGOAL.PAT_ENC_CSN_ID IS NOT NULL THEN 'Y' ELSE 'N' END "ACS_CARE_PLAN"
        ,CASE WHEN LIPID.PAT_ENC_CSN_ID IS NOT NULL THEN 'Y' ELSE 'N' END "LIPID_PROFILE_ORDERED"
--        ,ACSGOAL.LST_FILED_INST_DTTM "ACS_FIRST_CARE_PLAN_DTTM"
        FROM PAT_ENC_HSP hsp
        INNER JOIN PATIENT pat ON hsp.PAT_ID = pat.PAT_ID
        LEFT OUTER JOIN HSP_ACCT_ADMIT_DX admdx ON hsp.HSP_ACCOUNT_ID = admdx.HSP_ACCOUNT_ID
        LEFT OUTER JOIN 
        (
           
           SELECT *
           FROM
            (
           
           
            SELECT --*
            hno.NOTE_ID
            ,hno.PAT_ID
            ,hno.PAT_ENC_CSN_ID
            ,hno.LST_FILED_INST_DTTM
            ,hno_txt.LINE
            ,hno_txt.NOTE_TEXT
                ,row_number() OVER (PARTITION BY hno.PAT_ENC_CSN_ID ORDER BY hno.LST_FILED_INST_DTTM ) "SEQ_NUM"
            FROM HNO_INFO hno
            INNER JOIN hno_note_text hno_txt ON hno.NOTE_ID = hno_txt.NOTE_ID
            LEFT OUTER JOIN NOTE_SMARTTEXT_IDS ntxt ON hno.NOTE_ID = ntxt.NOTE_ID
            WHERE
            hno.IP_NOTE_TYPE_C = '1000001'
            AND hno_txt.NOTE_TEXT LIKE '%ACS%'
           )
           WHERE
           SEQ_NUM= 1
      
        
        )ACSGOAL ON ACSGOAL.PAT_ENC_CSN_ID = hsp.PAT_ENC_CSN_ID
        
       LEFT OUTER JOIN 
       (
        SELECT *
            FROM
            (
            
                    SELECT --* 
                    op.ORDER_PROC_ID
                    ,op.PAT_ID
                    ,op.PAT_ENC_CSN_ID
                    ,op.DESCRIPTION
                    ,op.ORDER_TIME
                    ,eap.PROC_ID
                    ,eap.PROC_NAME
                    ,row_number() OVER (PARTITION BY op.PAT_ENC_CSN_ID ORDER BY op.ORDER_TIME ) "SEQ_NUM"
            
                    FROM ORDER_PROC op
                    LEFT OUTER JOIN clarity_eap eap ON op.PROC_ID = eap.PROC_ID
                    WHERE 
                    op.ORDER_TYPE_C = 7
                    AND eap.PROC_NAME LIKE '%LIPID%'
             )
             WHERE
             SEQ_NUM = 1
       )LIPID ON LIPID.PAT_ENC_CSN_ID = hsp.PAT_ENC_CSN_ID 
        
        
        
        LEFT OUTER JOIN CLARITY_EDG edg ON admdx.ADMIT_DX_ID = edg.DX_ID
        LEFT OUTER JOIN CLARITY_DEP dep ON dep.DEPARTMENT_ID = hsp.DEPARTMENT_ID
        LEFT OUTER JOIN CLARITY_LOC loc ON dep.REV_LOC_ID = loc.LOC_ID
        LEFT OUTER JOIN CLARITY_LOC parloc ON loc.HOSP_PARENT_LOC_ID = parloc.LOC_ID
        LEFT OUTER JOIN HSP_ACCOUNT har ON har.HSP_ACCOUNT_ID = hsp.HSP_ACCOUNT_ID
        LEFT OUTER JOIN SOCIAL_HX tobco ON hsp.PAT_ENC_CSN_ID = tobco.HX_LNK_ENC_CSN
        LEFT OUTER JOIN  ZC_TOBACCO_USER  ztu ON tobco.TOBACCO_USER_C = ztu.TOBACCO_USER_C
        LEFT OUTER JOIN ZC_MC_PAT_STATUS zps ON har.PATIENT_STATUS_C=zps.PAT_STATUS_C
        LEFT OUTER JOIN ZC_PAT_SERVICE zsrv ON har.PRIM_SVC_HA_C=zsrv.HOSP_SERV_C--) 
        LEFT OUTER JOIN ZC_PAT_CLASS zpc ON hsp.ADT_PAT_CLASS_C = zpc.ADT_PAT_CLASS_C
        WHERE 
        
         hsp.HOSP_DISCH_TIME  >= EPIC_UTIL.EFN_DIN ('{?Start_Date}')   
       AND hsp.HOSP_DISCH_TIME  < EPIC_UTIL.EFN_DIN ('{?End_Date}')+1
       AND (parloc.LOC_ID IN {?Location} OR 0 IN {?Location})
       AND edg.CURRENT_ICD10_LIST IN {?Diagnosis}

--         hsp.HOSP_DISCH_TIME >= '1-mar-2021'
--         AND hsp.HOSP_DISCH_TIME < '22-mar-2021'
--         AND edg.CURRENT_ICD10_LIST = 'I21.4'
--         AND parloc.LOC_ID = 100000
