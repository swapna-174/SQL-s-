
/*
------------------------------------------------------------------------------------------------------------------------------------------------------------
PURPOSE			            : SHOW ADMINISTERED COVID VACCINATIONS
NAME			              :	XXXXX.SQL
DATE			              :	2021-01-06
AUTHOR			            :	AL ECHARD
DESCRIPTION	            :	PROVIDE DAILY DATA EXTRACT TO   
DETAIL                  : SHOW DETAIL RECORDS OF ADMINISTERED COVID VACCINATIONS 
FILENAME REQUIREMENTS   : TBD     
REVISION HISTORY        : 2021-01-06 Reporting    - Original Query Created        
------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

------------------------------------------------------------------------------------------------------------------------------------------------------------                      
-- SET DATE RANGE 
------------------------------------------------------------------------------------------------------------------------------------------------------------                      

WITH MYPARAMS AS (  
                    SELECT  
                               TRUNC( EPIC_UTIL.EFN_DIN( '01-JAN-2021' ))  AS START_DATE   -- Patients that are 5 years out from either Radiation/Surgery/Chemo 
                             , TRUNC( EPIC_UTIL.EFN_DIN( 'T' ))  AS END_DATE  
                     FROM   DUAL   
                     ) 
 
--------------------------------------------------------------------------------------------------------------------------------------------------------------                                         
----  IDENTIFY BASE POPULATION 
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- GET ORDERS FOR COVID VAC
, BASE_POP AS (     
                SELECT 
                          ORDER_PROC.PAT_ID
                        , ORDER_PROC.ORDER_PROC_ID
                  FROM  ORDER_PROC 
                 WHERE  1=1 
                   AND ORDER_PROC.PROC_ID in (  --- ORDERED VACC
                                               '142716'	----	PFIZER SARS-COV-2 VACCINE	----	IMM200
                                              ,'142717'	----	MODERNA SARS-COV-2 VACCINE	----	IMM201
                                              ,'142718'	----	SARS-COV2 VACCINE 1ST DOSE APPT	----	142718
                                              ,'142719'	----	PFIZER SARS-COV-2 VACCINE 2ND DOSE APPT	----	142719
                                              ,'142720'	----	MODERNA SARS-COV-2 VACCINE 2ND DOSE APPT	----	142720
                                              )
                  AND  ORDER_PROC.ordering_date   BETWEEN   ( SELECT START_DATE FROM MYPARAMS )    and    ( SELECT END_DATE FROM MYPARAMS ) 
                  AND ( ORDER_PROC.order_status_c is null or  ORDER_PROC.order_status_c ='5' )
                  
                  --AND ORDER_PROC.PAT_ID ='Z3747330'
                )
 

, PAT_DEMO  AS  (  ----  PATIENT ADDRESS
                          SELECT  DISTINCT 
                                    PATIENT.PAT_ID 
                                  , PATIENT.PAT_MRN_ID AS MRN
                                  ---, PATIENT.PAT_NAME
                                  , PATIENT.PAT_FIRST_NAME    
                                  , PATIENT.PAT_MIDDLE_NAME   
                                  , PATIENT.PAT_LAST_NAME                                    
                                  , CAST(PATIENT.BIRTH_DATE AS DATE) AS BIRTH_DATE 
                                  
                                  
                                  , CASE
                                        WHEN  ZC_SEX.ABBR IS NULL THEN 'U'
                                        WHEN  ZC_SEX.ABBR = 'NB'  THEN 'U'
                                        WHEN  ZC_SEX.ABBR = 'X'   THEN 'U'
                                        WHEN  ZC_SEX.ABBR = 'OTH' THEN 'U'
                                        ELSE  ZC_SEX.ABBR    --- U, M, F CASES PASS HERE
                                     END                      AS PAT_GENDER
                                  
                                  
                                  , NVL( Z_RACE1.NAME , 'OTHER' ) AS PATIENT_RACE1  
                                  , ZC_ETHNIC_GROUP.NAME AS PATIENT_ETHNIC  
                                  ,    PATIENT.ADD_LINE_1  PATIENT_ADDRESS1
--                                  ,    PATIENT.ADD_LINE_2  PATIENT_ADDRESS2
                                  , PATIENT.CITY     AS PATIENT_CITY
                                  , ZC_STATE.NAME      AS PATIENT_STATE 
                                  , PATIENT.ZIP       AS PATIENT_ZIP
                                  , ZC_COUNTY.NAME    AS PATIENT_COUNTY 
                                  , ZC_COUNTRY_2.ABBR  AS  PATIENT_COUNTRY
                                  , ZC_PAT_LIVING_STAT.TITLE  PAT_STATUS_C 
                                  , CASE 
                                      WHEN EMPY_STATUS_C IN ( 1,2,7,8 )  THEN 'STUDENT'
                                      WHEN EMPY_STATUS_C IN ( 9 )  THEN 'UNKNOWN'
                                      WHEN EMPY_STATUS_C IN ( 4 )  THEN 'EMPLOYED'
                                      WHEN EMPY_STATUS_C IN ( 3 )  THEN 'UNEMPLOYED' 
                                      ELSE 'OTHER'
                                     END             employment

                                  ,EMERGENCY_CONTACTS.GUARDIAN_NAME
                                  
                                 , SUBSTR(EMERGENCY_CONTACTS.GUARDIAN_NAME, 0,
                                               CASE WHEN INSTR(EMERGENCY_CONTACTS.GUARDIAN_NAME, ', ')-1<0
                                               THEN LENGTH(EMERGENCY_CONTACTS.GUARDIAN_NAME)
                                               ELSE INSTR (EMERGENCY_CONTACTS.GUARDIAN_NAME, ', ')-1 END) AS GUARD_LAST_NAME
                                               
                                  , REPLACE(SUBSTR(EMERGENCY_CONTACTS.GUARDIAN_NAME, INSTR(EMERGENCY_CONTACTS.GUARDIAN_NAME, ', '), LENGTH(EMERGENCY_CONTACTS.GUARDIAN_NAME)),',','')  GUARD_FIRST_NAME                                 
 
                                  , ZREL.NAME GUARDIAN_REL   
                                  , EMERGENCY_CONTACTS.MOTHER_NAME    ---The vaccine recipient's mother's maiden name.  
                                  , ZC_OCCUPATION.NAME   OCCUPATION 
                                  , ZC_INDUSTRY.NAME   INDUSTRY
                                  , PATIENT.HOME_PHONE  PATIENT_PHONE
                                  , ZC_LANGUAGE.NAME   PAT_LANGUAGE
                                  , PATIENT.EMAIL_ADDRESS
                                  
                            FROM  BASE_POP
                                       JOIN PATIENT                 ON BASE_POP.PAT_ID              =  PATIENT.PAT_ID
                                  LEFT JOIN PATIENT_4               ON PATIENT.PAT_ID               =  PATIENT_4.PAT_ID
                                  LEFT JOIN  ZC_PAT_LIVING_STAT     ON PATIENT_4.PAT_LIVING_STAT_C  = ZC_PAT_LIVING_STAT.PAT_LIVING_STAT_C 
                                  LEFT JOIN PAT_ADDRESS             ON PATIENT.PAT_ID               = PAT_ADDRESS.PAT_ID 
                                  
                                  LEFT JOIN PATIENT_RACE    P_RACE1 ON PATIENT.PAT_ID               = P_RACE1.PAT_ID   
                                                                   AND P_RACE1.LINE=1 
                                  LEFT JOIN ZC_PATIENT_RACE Z_RACE1 ON P_RACE1.PATIENT_RACE_C       = Z_RACE1.PATIENT_RACE_C   
                                  
                                  LEFT JOIN ZC_SEX                  ON PATIENT.SEX_C                = ZC_SEX.RCPT_MEM_SEX_C
                                  LEFT JOIN ZC_ETHNIC_GROUP         ON PATIENT.ETHNIC_GROUP_C       = ZC_ETHNIC_GROUP.ETHNIC_GROUP_C  
                                  LEFT JOIN ZC_STATE                ON PATIENT.STATE_C              = ZC_STATE.STATE_C 
                                  LEFT JOIN ZC_COUNTY               ON PATIENT.COUNTY_C             = ZC_COUNTY.COUNTY_C 
                                  LEFT JOIN ZC_COUNTRY_2            ON PATIENT.COUNTRY_C            = ZC_COUNTRY_2.COUNTRY_2_C
                                  LEFT JOIN EMERGENCY_CONTACTS      ON PATIENT.PAT_ID               = EMERGENCY_CONTACTS.PAT_ID
                                  LEFT JOIN    ZC_OCCUPATION        ON    PATIENT_4.OCCUPATION_C    =  ZC_OCCUPATION.OCCUPATION_C
                                  LEFT JOIN    ZC_INDUSTRY          ON    PATIENT_4.INDUSTRY_C      =  ZC_INDUSTRY.INDUSTRY_C
                                  LEFT JOIN   ZC_PAT_RELATION ZREL  ON ZREL.PAT_RELATION_C          = EMERGENCY_CONTACTS.GUARDIAN_REL_C 
                                  LEFT JOIN  ZC_LANGUAGE            ON  PATIENT.LANGUAGE_C          = ZC_LANGUAGE.LANGUAGE_C
                            WHERE   1=1             
                        )
 
   
, ADMIN_IMMS AS  ( 
                   SELECT     
                              LOC2.LOC_NAME               recip_authority_id    ---PARENT LOCATION OF WAKE FOREST
                            , PAT_DEMO.MRN              recip_id 
                            , PAT_DEMO.PAT_FIRST_NAME   FirstName
                            , PAT_DEMO.PAT_MIDDLE_NAME  MiddleNname
                            , PAT_DEMO.PAT_LAST_NAME    LastName
                            , PAT_DEMO.BIRTH_DATE       PersonBirthDate
                            , PAT_DEMO.PAT_GENDER       Gender 
                            
                            , CASE  WHEN PAT_DEMO.GUARDIAN_NAME IS NOT NULL  THEN  PAT_DEMO.GUARD_FIRST_NAME 
                                    ELSE PAT_DEMO.PAT_FIRST_NAME   
                              END                                  resp_first_name
                  
                            , CASE  WHEN PAT_DEMO.GUARDIAN_NAME IS NOT NULL  THEN '' 
                                    ELSE  PAT_DEMO.PAT_MIDDLE_NAME   
                              END                                  resp_middle_name 
                              
                            , CASE  WHEN PAT_DEMO.GUARDIAN_NAME IS NOT NULL  THEN  PAT_DEMO.GUARD_LAST_NAME 
                                    ELSE PAT_DEMO.PAT_LAST_NAME   
                              END                                  resp_last_name 
                  
                            , CASE  WHEN PAT_DEMO.GUARDIAN_REL  IS NOT NULL  THEN  PAT_DEMO.GUARDIAN_REL 
                                    ELSE 'Self'  
                              END                                    relationship_to_recip  
            
                            , PAT_DEMO.MOTHER_NAME                    mother_maiden_name 
 
                            , PAT_DEMO.PATIENT_ADDRESS1 ADDRESS_1
--                            , PAT_DEMO.PATIENT_ADDRESS2 recip_address_street_2
                            , PAT_DEMO.PATIENT_CITY     City
                            
                            , PAT_DEMO.PATIENT_STATE    State
                            
                            , PAT_DEMO.PATIENT_COUNTrY   Country  
                            , PAT_DEMO.PATIENT_ZIP      Zip                       
                            , PAT_DEMO.PATIENT_COUNTY   County
 
                            , PAT_DEMO.PATIENT_RACE1    Race
                            , PAT_DEMO.PATIENT_ETHNIC   Ethnicity 
                            , PAT_DEMO.PAT_LANGUAGE     recip_primary_language    
                            , PAT_DEMO.PATIENT_PHONE    recip_telephone_number 
                            , 'HOME'                    recip_telephone_number_type
                            , PAT_DEMO.EMAIL_ADDRESS    recip_email
                            , ''                        recall_notices   ----?????
   
                            , LOC2.LOC_NAME                org_name    ---PARENT LOCATION OF WAKE FOREST
                            , LOC2.LOC_id                  org_id    ---- this will be  vtrcks_prov_pin -- parent vfc

                            , ENC_DEP.SPECIALTY	            admin_type                                               -------NEED TO VERIFY                            
                            , ENC_DEP.DEPARTMENT_NAME	      admin_name
                            , enc_dep.department_id         admin_id    ---- this will be vfc for admin  location
                            
                            ,'vtrcks_prov_pin'              vtrcks_prov_pin  ---tbd

                            , NDC_CODE                                                                            -------NEED TO VERIFY
                            , IMMUNE.IMMUNE_DATE         admin_date
                            , IMMUNE.IMMUNE_ID           vax_event_id 
                            , ROW_NUMBER() OVER ( PARTITION BY  IMMUNE.PAT_ID , IMMUNE.IMMUNE_ID
                                                      ORDER BY  IMMUNE.PAT_ID , IMMUNE.IMMUNE_DATE  ASC)  dose_num                            
                            , IMMUNE.LOT                 lot_number   
                            , IMMUNE.EXPIRATION_DATE      vax_expiration
                            , ZC_SITE.TITLE               vax_admin_site
                            , ZC_ROUTE.TITLE              vax_route
                            
                            , CLARITY_SER_2.npi           Provider_License_Number
--                            , zc_lic.title                vax_admin_provider_title  --- can be a nurse
                            , CLARITY_SER.prov_name       vax_admin_provider_name
                            , IMMUNE.IMMUNE_DATE          vis_publication_date          -- SHEET GIVEN TO RECEIPT AT TIME
                            ,  'Y'                        vis_date_given_to_recipient   -- SHEET GIVEN TO RECEIPT AT TIME
                            , ''    vax_reaction   ----Reaction after Vaccination
                            , ''    vax_reaction_desc -------Adverse Reactions (Description)
                             
                            ,'' recip_priority_group      --- ADD LOGIC  FOR TIER
                            --CASE
                            --WHEN PAT_DEMO.EMPLOYMENT -- STUDENT 
                            --WHEN PAT_DEMO.OCCUPATION
                            --END    TIER
                            
                            ,'' serology                     --- CHECK MEDICAL HX FOR COVID
                            ,'' Date_of_Disease              --- CHECK MEDICAL HX FOR COVID
                            
                            , CASE WHEN IMMUNE.IMMNZTN_STATUS_C =1 THEN 'FALSE' ELSE 'TRUE'   END   AdverseReactionConsent     -------NEED TO VERIFY  
                            --- , CASE WHEN IMMUNE.STATUS = '5' THEN 'TRUE' ELSE 'FALSE'    END  PREVIOUS SPEC CALLED   vax_refusal
                                                         
                            , PAT_DEMO.EMPLOYMENT           Critical_Essential_Worker  --- ADD LOGIC  
                            , PAT_DEMO.INDUSTRY  
                            ,'' Tribal_Community         ---- CHECK IF TRIBAL
                            ,''                                      mpi_id       --- PER STATE LEAVE BLANK
                            ,''                                      mpi_authority--- PER STATE LEAVE BLANK
                            , TRUNC( EPIC_UTIL.EFN_DIN( 'T' ))       file_date
                            ,''                                      ssn          --- PER MOSES  NOT PROVIDING
                            ,''                                      drives_lic   --- PER MOSES  NOT PROVIDING
                            ,''                                      ins_policy   --- PER MOSES  NOT PROVIDING
                                            
                            --  ,  COALESCE ( IMM_CVX_CODE , IMMUNE.IMM_PRODUCT )         cvx                          -------NEED TO VERIFY                            
                            --  ,  ZC_MFG.TITLE              MVX ----(manufacturer)                                    -------NEED TO VERIFY   
                            --, POS.ADDRESS_LINE_1            admin_address_street
                            ----, POS.ADDRESS_LINE_2            admin_address_street_2
                            --, POS.CITY                      admin_address_city
                            --, POS_ZC_COUNTY.NAME            admin_address_county
                            --, POS_ZC_STATE.NAME             admin_address_state
                            --, POS.ZIP                       admin_address_zip
  
                    FROM  BASE_POP
                               JOIN ORDER_PROC                ON BASE_POP.ORDER_PROC_ID     = ORDER_PROC.ORDER_PROC_ID 
                          LEFT JOIN PAT_DEMO                  ON BASE_POP.PAT_ID            = PAT_DEMO.PAT_ID
                          LEFT JOIN  IMMUNE                   ON ORDER_PROC.ORDER_PROC_ID   =  IMMUNE.ORDER_ID 
                          LEFT JOIN RX_NDC                    ON RX_NDC.NDC_ID           = IMMUNE.NDC_num_id
                          LEFT JOIN PAT_ENC  	                ON PAT_ENC.PAT_ENC_CSN_ID  = ORDER_PROC.PAT_ENC_CSN_ID                       -----------IMMUNE.IMM_CSN
                          LEFT JOIN CLARITY_DEP ENC_DEP       ON COALESCE ( IMMUNE.ENCOUNTER_DEPT_ID, PAT_ENC.DEPARTMENT_ID )   =  ENC_DEP.DEPARTMENT_ID 
                          LEFT JOIN CLARITY_LOC LOC           ON ENC_DEP.REV_LOC_ID      = LOC.LOC_ID 
                          LEFT JOIN CLARITY_LOC LOC2          ON LOC.HOSP_PARENT_LOC_ID  = LOC2.LOC_ID
                          LEFT JOIN CLARITY_POS POS           ON ENC_DEP.REV_LOC_ID      =  POS.POS_ID
                          LEFT JOIN ZC_STATE   POS_ZC_STATE   ON POS.STATE_C              = POS_ZC_STATE.STATE_C 
                          LEFT JOIN ZC_COUNTY  POS_ZC_COUNTY  ON POS.COUNTY_C             = POS_ZC_COUNTY.COUNTY_C          
                                            
                          LEFT JOIN  ZC_ROUTE                 ON IMMUNE.ROUTE_C              = ZC_ROUTE.ROUTE_C
                          LEFT JOIN  ZC_MFG                   ON IMMUNE.MFG_C                = ZC_MFG.MFG_C
                          LEFT JOIN  ZC_SITE                  ON IMMUNE.SITE_C               = ZC_SITE.SITE_C
                          LEFT JOIN  ZC_MED_UNIT              ON IMMUNE.IMMNZTN_DOSE_UNIT_C  = ZC_MED_UNIT.DISP_QTYUNIT_C  
                          
                          LEFT JOIN CLARITY_EAP   EAP         ON ORDER_PROC.PROC_ID              = EAP.PROC_ID    
                          LEFT JOIN CLARITY_IMMUNZATN         ON CLARITY_IMMUNZATN.IMMUNZATN_ID  = IMMUNE.IMMUNZATN_ID 
                          LEFT JOIN ZC_IMMNZTN_STATUS         ON ZC_IMMNZTN_STATUS.INTERNAL_ID   = IMMUNE.IMMNZTN_STATUS_C 
                          LEFT JOIN CLARITY_EMP EMP           ON EMP.USER_ID                     = IMMUNE.GIVEN_BY_USER_ID 
                          LEFT JOIN CLARITY_EMP EMP2          ON EMP2.USER_ID                    = IMMUNE.ENTRY_USER_ID  
                          
                          LEFT JOIN CLARITY_SER            --- ON PAT_ENC.VISIT_PROV_ID           = CLARITY_SER.PROV_ID  --- remove link as the person giving the admin my not be an MD provider
                                                            ON CLARITY_SER.USER_ID       =    EMP.USER_ID
                          
                          LEFT JOIN  CLARITY_SER_2          ON CLARITY_SER.PROV_ID             = CLARITY_SER_2.PROV_ID 
                          LEFT JOIN ZC_LICENSE_DISPLAY zc_lic  ON  zc_lic.LICENSE_DISPLAY_C    = CLARITY_SER_2.CUR_CRED_C 

                  WHERE  1=1  
--                    AND IMM_CSN IN  (30133097646,   30133081420)    ---- HISTORICAL         
                    AND  IMMUNE.IMMNZTN_STATUS_C = 1  ---  GIVEN 
--                    AND  (  IMMUNE.IMM_HISTORIC_ADM_YN IS NULL OR IMMUNE.IMM_HISTORIC_ADM_YN ='Y'  )
                    AND  CLARITY_IMMUNZATN.active_status_c = 1  --- VACCINE IS ACTIVE 
--                    AND  CLARITY_IMMUNZATN.IMMUNZATN_ID in (
--                                                             '102'--	PFIZER SARS-COV-2 VACCINE
--                                                            ,'104'--	MODERNA SARS-COV-2 VACCINE
--                                                            )
                      )
         
         
---------------------------
----MAINLINE 
---------------------------
    SELECT ADMIN_IMMS.* 
 
----OPTIONAL FIELDS BELOW: 
          ,   CASE 
                WHEN ADMIN_IMMS.dose_num = 1 THEN   'No'        ---FIRST VACC
                WHEN ADMIN_IMMS.dose_num > 1 THEN   'Yes'       ---SECOND VACC
                WHEN ADMIN_IMMS.dose_num IS NULL THEN   'Unknown'   ---IF NULL THEN UNKNOWN         
              END                         vax_series_complete
--          , '' cmorbid_status --- Comorbidity status (Y/N)  
--          , '' serology----Serology results (Presence of Positive Resultt, Y/N) 
    
      FROM ADMIN_IMMS
      
      
      
      
      
      
       