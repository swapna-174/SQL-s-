 
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

--------------------------------------------------------------------  
-- CAUTION: 
--          START_DATE  IS USED TO COLLECT AND SORT "ALL" "RELATED" COVID VACCINATIONS
--          REPORT_BEGIN_DATE IS USED TO FILTER FOR AN ALTERNATE REPORT DATE RANGE  
-------------------------------------------------------------------- 
                    SELECT  
                                TRUNC( EPIC_UTIL.EFN_DIN( '01-JAN-2021' ))  AS START_DATE   
                              , TRUNC( EPIC_UTIL.EFN_DIN( '09-MAR-2021' ))  AS REPORT_BEGIN_DATE                                  
                              , TRUNC( EPIC_UTIL.EFN_DIN( 'T' ))            AS END_DATE  
                     FROM   DUAL   
                     ) 
 
--------------------------------------------------------------------------------------------------------------------------------------------------------------                                         
----  IDENTIFY BASE POPULATION 
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CHECK ORDERS AND IMMUNE RECORDS FOR COVID VAC
, IMM_DAT AS (    
  SELECT    distinct 
              IMMUNE.PAT_ID   
            , IMMUNE.IMM_HISTORIC_ADM_YN
            ,  IMMUNE.IMM_CSN                                                     PAT_ENC_CSN_ID   -- ENSURE LINK BETWEEN IMMUNIZATION AND VISIT ENCOUNTERS
            , ORDER_med.ORDER_med_ID
            , 'Wake Forest Baptist Health'                                        org_name        ---- parent vfc --1/26/2021   from spec per CVMS 
            
-- today           , 'Wake Forest Baptist Medical Center'                                admin_name 
            , CASE
                WHEN  LOC2.LOC_id IN (  
                                         '100000'--	  PARENT WAKE FOREST 
                                        ,'100004'--		PARENT CORNERSTONE
                                       )  THEN 'Wake Forest Baptist Medical Center'  --Administer Location is the Initial Inventory location 
                WHEN  LOC2.LOC_id IN (   '100001'--		PARENT LEXINGTON  
                                       )  THEN 'Lexington Medical Center'            --Administer Location is the Initial Inventory location 
                WHEN  LOC2.LOC_id IN (   '100002'--		PARENT DAVIE 
                                       )  THEN 'Davie Medical Center'                --Administer Location is the Initial Inventory location  
                WHEN  LOC2.LOC_id IN (   '100005'--		PARENT WILKES 
                                       )  THEN 'Wilkes Medical Center'               --Administer Location is the Initial Inventory location   
                WHEN  LOC2.LOC_id IN (   '100009'--		PARENT HIGH POINT 
                                       )  THEN 'High Point Medical Center'           --Administer Location is the Initial Inventory location                                          
                ELSE                           'Wake Forest Baptist Medical Center'  --Administer Location is the Initial Inventory location                         
              END                                                               admin_name    --- parent vfc --1/26/2021   from spec per CVMS  
 
--- today ,  '34C001'                                                            vtrcks_prov_pin
             
            , CASE
--                WHEN  LOC2.LOC_id IN (  
--                                         '100000'--	  PARENT WAKE FOREST 
--                                        ,'100004'--		PARENT CORNERSTONE
--                                       )  THEN  '34C001'   --Administer Location is the Initial Inventory location 
 
                WHEN  LOC2.LOC_id IN (   '100000'  ) --	  PARENT WAKE FOREST 
                       AND ENC_DEP.REV_LOC_ID  =  '10035' ---- PEACE HAVEN LOCATIONS
                                          THEN  '34C046'    
                              
                WHEN  LOC2.LOC_id IN (   '100000'  ) --	  PARENT WAKE FOREST 
                       AND (      ENC_DEP.REV_LOC_ID IS NULL 
                             OR   ENC_DEP.REV_LOC_ID <> '10035' 
                              )           THEN  '34C001'   --Administer Location is the Initial Inventory location                                        
                                       
                WHEN  LOC2.LOC_id IN (  '100004' --		PARENT CORNERSTONE
                                       )  THEN  '34C001'   --Administer Location is the Initial Inventory location                                        
                                       
                WHEN  LOC2.LOC_id IN (   '100001'--		PARENT LEXINGTON  
                                       )  THEN  '29C013'            --Administer Location is the Initial Inventory location 
                WHEN  LOC2.LOC_id IN (   '100002'--		PARENT DAVIE 
                                       )  THEN  '30C002'               --Administer Location is the Initial Inventory location  
                WHEN  LOC2.LOC_id IN (   '100005'--		PARENT WILKES 
                                       )  THEN  '97C001'               --Administer Location is the Initial Inventory location   
                WHEN  LOC2.LOC_id IN (   '100009'--		PARENT HIGH POINT 
                                       )  THEN  '34C006'           --Administer Location is the Initial Inventory location                                          
                ELSE                            '34C001'   --Administer Location is the Initial Inventory location                         
              END                                                               vtrcks_prov_pin     --- vfc for admin  location  '40166742'  --1/26/2021 remove from spec per CVMS 

 
             ,  CASE  WHEN RX_NDC.RAW_11_DIGIT_NDC IS NOT NULL   THEN 
                            SUBSTR ( RX_NDC.RAW_11_DIGIT_NDC,1,5)   || '-'  ||
                            SUBSTR ( RX_NDC.RAW_11_DIGIT_NDC,6,4)   || '-'  ||
                            SUBSTR ( RX_NDC.RAW_11_DIGIT_NDC,10,2)    
                END        NDC     ---RAW 11 NDC CODE I.E. PRODUCT  AS FORMATTED   
   
            , CAST(IMMUNE.IMMUNE_DATE AS DATE)                                   IMMUNE_DATE    
           
            , IMMUNE.IMMUNE_ID                                                   vax_event_id 
            , ROW_NUMBER() 
               OVER ( PARTITION BY  IMMUNE.PAT_ID  
                          ORDER BY  IMMUNE.PAT_ID , IMMUNE.IMMUNE_ID 
                                     ASC   )   dose_num   --- USE TO FIND MOST RECENT I.E. MAX NUMBER OF DOSE          
            , ROW_NUMBER() 
               OVER ( PARTITION BY  IMMUNE.PAT_ID  
                          ORDER BY  IMMUNE.PAT_ID , IMMUNE.IMMUNE_ID 
                                     DESC )    dose_RANK  --- ORDER OF DOSE  GRABING THE FIRST ONE 
                                      
            , IMMUNE.LOT                                                         lot_number   
            , IMMUNE.EXPIRATION_DATE                                             vax_expiration_date
              
            ,CASE
                WHEN   ZC_SITE.TITLE ='LEFT VASTUS LATERALIS'     THEN   'Left Vastus Lateralis'
                WHEN   ZC_SITE.TITLE ='RIGHT VASTUS LATERALIS'    THEN   'Right Vastus Lateralis'
                WHEN   ZC_SITE.TITLE ='RIGHT DELTOID'             THEN   'Right Deltoid'
                WHEN   ZC_SITE.TITLE ='LEFT DELTOID'              THEN   'Left Deltoid'
                WHEN   ZC_SITE.TITLE ='RIGHT UPPER QUAD. GLUTEUS' THEN   'Right Gluteus Medius'
                WHEN   ZC_SITE.TITLE ='LEFT UPPER QUAD. GLUTEUS'  THEN   'Left Gluteus Medius'
                WHEN   ZC_SITE.TITLE ='RIGHT QUADRICEPS'          THEN   'Right Thigh'
                WHEN   ZC_SITE.TITLE ='LEFT QUADRICEPS'           THEN   'Left Thigh'
                WHEN   ZC_SITE.TITLE ='LEFT ARM'                  THEN   'Left Arm'
                WHEN   ZC_SITE.TITLE ='RIGHT ARM'                 THEN   'Right Arm' 
             END                                                                vax_admin_site

            ,CASE
                  WHEN UPPER(ZC_ROUTE.NAME) = UPPER('Intramuscular')   THEN  'Intramuscular (IM)'
                  WHEN UPPER(ZC_ROUTE.NAME) = UPPER('Subcutaneous')    THEN  'Subcutaneous (SQ)'
             END                                                                vax_route  
            , E.EMP_NAME                                                        vax_admin_provider_name    
            , EPIC_UTIL.EFN_DIN(IMMUNE.vis_date_text)                           vis_publication_date          -- SHEET GIVEN TO recipient DATE 
             
            ,   ( SELECT  DISTINCT 
                          case when CL_QANSWER_QA.QUEST_ID  = '127637' and  CL_QANSWER_QA.quest_answer is not null then  CL_QANSWER_QA.quest_answer
                               when CL_QANSWER_QA.QUEST_ID  = '128081' and  CL_QANSWER_QA.quest_answer is not null then  CL_QANSWER_QA.quest_answer
                                else '1'
                          end   quest_answer 
                  FROM  CL_QANSWER_QA 
                 WHERE  1=1
                   AND  CL_QANSWER_QA.QUEST_ID  in ( '127637' ,'128081') ---	AMB COVID VACCINE EUA DATE -- Date EUA and V-safe documents were given ("t" for today)
                   AND  CL_QANSWER_QA.ANSWER_ID = immune.IMM_ANSWER_ID
                                 )                                            vis_date_given_to_recipient   -- SHEET GIVEN TO recipient 
            , CASE WHEN IMMUNE.IMMNZTN_STATUS_C =1 THEN 'FALSE'
                         ELSE 'TRUE' 
              END                                                               AdverseReactionConsent        -------NEED TO VERIFY  
            , ' '                                                                vax_reaction                  ----Reaction after Vaccination          --- dropped per updated spec 1/25/2021
            , ' '                                                                vax_reaction_desc             ------Adverse Reactions (Description)   --- dropped per updated spec 1/25/2021
            ,  tmpser.prov_id    exclude_sch_tmp_prov_id 
            ,  ser.prov_id      template_prov_id
            ,  ser.prov_name    template_prov_name
            ,  ser.prov_type    template_prov_type 
            
            , TO_CHAR(   immune.update_date   , 'YYYY-MM-DD HH24:MI') vax_event_last_modified   
             
             , case when  trim(COALESCE ( IMMUNE.IMM_PRODUCT,CLARITY_IMMUNZATN.NAME ))  =  'covid 19 vaccine'  then clarity_lot.product
                    when  trim(COALESCE ( IMMUNE.IMM_PRODUCT,CLARITY_IMMUNZATN.NAME ))  =  ''  then clarity_lot.product
                    else  COALESCE ( IMMUNE.IMM_PRODUCT,CLARITY_IMMUNZATN.NAME )   
               end              product_name     
             
            , CASE WHEN ENC_DEP.DEPARTMENT_ID IS NOT NULL THEN ENC_DEP.DEPARTMENT_name || ' [' || ENC_DEP.DEPARTMENT_ID || ']'  END   EPIC_DEPARTMENT  
            , CASE WHEN  CP.EXTERNAL_NAME  IS NOT NULL THEN  CONCAT( CP.EXTERNAL_NAME  , ' [' || CP.PRC_ID || ']' )             END   VISIT_TYPE             
            ,CP.PRC_ID
            , clarity_pos.address_line_1   dep_address_line_1
            , initcap( CLARITY_POS.CITY )  DEP_CITY
            , CLARITY_POS.ZIP   DEP_ZIP
            , initcap( CASE WHEN ( UPPER( CLARITY_POS.CITY) ='WINSTON SALEM'  AND zc_cty.NAME IS NULL ) THEN 'Forsyth'
                            else  zc_cty.NAME  
                       end
                        )    DEP_COUNTY   
     
,   CASE
        WHEN  tmpser.prov_id  IN  (  '8274'	) --UNITED HEALTH CENTERS @ PETERS CREEK PARKWAY  
        THEN 1
     END EXCLUDEd_CLINIC -- EXCLUDE WHERE OLD_PROV_ID =  '8274'	--UNITED HEALTH CENTERS @ PETERS CREEK PARKWAY  
            
    FROM IMMUNE    
          LEFT JOIN CLARITY_IMMUNZATN         ON CLARITY_IMMUNZATN.IMMUNZATN_ID  = IMMUNE.IMMUNZATN_ID 
          LEFT JOIN ZC_IMMNZTN_STATUS         ON ZC_IMMNZTN_STATUS.INTERNAL_ID   = IMMUNE.IMMNZTN_STATUS_C
          LEFT JOIN ZC_ROUTE                  ON IMMUNE.ROUTE_C                  = ZC_ROUTE.ROUTE_C
          LEFT JOIN ZC_MFG                    ON IMMUNE.MFG_C                    = ZC_MFG.MFG_C
          LEFT JOIN ZC_SITE                   ON IMMUNE.SITE_C                   = ZC_SITE.SITE_C
          LEFT JOIN ZC_MED_UNIT               ON IMMUNE.IMMNZTN_DOSE_UNIT_C      = ZC_MED_UNIT.DISP_QTYUNIT_C   
          LEFT JOIN RX_NDC                    ON RX_NDC.NDC_ID                   = IMMUNE.NDC_num_id 
          LEFT JOIN clarity_lot               on    immune.lot                   =    clarity_lot.lot_num 
                                              and   immune.ndc_num_id            =    clarity_lot.ndc_num_id  
  
          LEFT JOIN PAT_ENC  	  IMM_ENC       ON  IMMUNE.IMM_CSN                 = IMM_ENC.PAT_ENC_CSN_ID    
          
          LEFT JOIN CLARITY_SER  SER          ON  IMM_ENC.VISIT_PROV_ID          = SER.PROV_ID
          
          LEFT JOIN ORDER_PROC                ON IMMUNE.ORDER_ID                 = ORDER_PROC.ORDER_PROC_ID
                                             AND  ( ORDER_PROC.order_status_c is null or  ORDER_PROC.order_status_c ='5' )
                                             
          LEFT JOIN ORDER_MED                 ON  IMMUNE.ORDER_ID                =  ORDER_med.ORDER_med_ID   
                                             AND  ( ORDER_MED.order_status_c is null or  ORDER_MED.order_status_c ='5' ) 
                                             
          LEFT JOIN clarity_medication  erx   ON ORDER_med.ORDER_med_ID          = erx.medication_id 
                                             and  erx.name  like 'COVID-19 VACCINE%'   
          
          LEFT JOIN  CLARITY_PRC CP           ON IMM_ENC.APPT_PRC_ID             = CP.PRC_ID              
          LEFT JOIN CLARITY_DEP ENC_DEP       ON IMM_ENC.EFFECTIVE_DEPT_ID       =  ENC_DEP.DEPARTMENT_ID   --- COALESCE ( IMM_ENC.DEPARTMENT_ID , ORD_ENC.DEPARTMENT_ID )   =  ENC_DEP.DEPARTMENT_ID 
          LEFT JOIN CLARITY_LOC LOC           ON ENC_DEP.REV_LOC_ID              = LOC.LOC_ID 
          LEFT JOIN CLARITY_POS               ON ENC_DEP.REV_LOC_ID              = CLARITY_POS.POS_ID  
          LEFT JOIN   ZC_COUNTY zc_cty        on CLARITY_POS.county_c            = zc_cty.county_c 
          LEFT JOIN CLARITY_LOC LOC2          ON LOC.HOSP_PARENT_LOC_ID          = LOC2.LOC_ID 
          LEFT JOIN CLARITY_EMP EMP           ON EMP.USER_ID                     = IMMUNE.GIVEN_BY_USER_ID  
          LEFT JOIN (
                       select 
                               CL_EMP_OT.user_id
                               , NAMES_STATIC.first_name ||' '|| NAMES_STATIC.last_name emp_name
                        from (
                               select  distinct
                                         CL_EMP_OT.user_id 
                                        ,CL_EMP_OT.emp_name_record_id
                                        , ROW_NUMBER() 
                                             OVER ( PARTITION BY  CL_EMP_OT.user_id  
                                                        ORDER BY  CL_EMP_OT.user_id   , contact_date  DESC  )        rank                                       
                                from  CL_EMP_OT 
                                where   1=1
                              ) CL_EMP_OT
                                 join   NAMES_STATIC  on    NAMES_STATIC.record_id =  CL_EMP_OT.emp_name_record_id  
                        where  CL_EMP_OT.rank =1            
                      )  E       ON    EMP.USER_ID        =   E.USER_ID      

-- ----  add logic to identify / exclude mass vax pats for lots owned outside of wake
-- EXCLUDE WHERE pat_enc_chng_appt.NEW_PROV_ID  vs pat_enc_chng_appt.old_prov_id =  '8274'	--UNITED HEALTH CENTERS @ PETERS CREEK PARKWAY 
-- ----  Added 2/15/2021 	DLC
--		This code examines table APPT_UTIL_SNAPSHOT for the existence of generic provider 8274 (UNITED HEALTH CENTER) and UTIL_SNAP_CHANGE has a value of 0
     	left join  ( 
                    SELECT    PAT_ENC_CSN_ID 
                           ,  UTIL_SNAP_PROV_ID  prov_id                              
                      FROM (      
                            select  distinct
                                     snp.*
                                      , ROW_NUMBER() 
                                         OVER ( PARTITION BY    snp.PAT_ENC_CSN_ID , snp.UTIL_SNAP_PROV_ID  
                                                    ORDER BY    snp.pAT_ENC_CSN_ID , snp.UTIL_SNAP_PROV_ID , snp.contact_date  DESC  )        SER_rank                           
                               from   pat_enc    pe 
                                         join  APPT_UTIL_SNAPSHOT snp    on    pe.PAT_ENC_CSN_ID     = snp.pat_enc_csn_id  
                              where 1=1 
                                and  pe.appt_prc_id                 IN ('586', '587', '588')  
                                and  snp.UTIL_SNAP_CHANGE  = '0'
                                and  snp.UTIL_SNAP_PROV_ID = '8274'
                             )  
                    WHERE  SER_RANK =1   
												 )  tmpser    on   IMMUNE.IMM_CSN                 =    tmpser.PAT_ENC_CSN_ID    
                         
WHERE  1=1     
    AND  ( tmpser.prov_id IS NULL OR tmpser.prov_id   <> '8274'  )   -- EXCLUDE WHERE OLD_PROV_ID =  '8274'	--UNITED HEALTH CENTERS @ PETERS CREEK PARKWAY  
    AND  TRUNC (IMMUNE.IMMUNE_DATE) BETWEEN   ( SELECT START_DATE FROM MYPARAMS )    and    ( SELECT END_DATE FROM MYPARAMS )   ---COLLECT AND RANK VACCINATIONS
    AND  IMMUNE.IMMNZTN_STATUS_C = 1  ---  GIVEN  
    AND  CLARITY_IMMUNZATN.IMMUNZATN_ID in (
                                            --IMMUNZATN_ID	NAME
                                            --102	PFIZER SARS-COV-2 VACCINE
                                            --104	MODERNA SARS-COV-2 VACCINE
                                            --105	JANSSEN SARS-COV-2 VACCINE
                                            --106	ASTRAZENECA SARS-COV-2 VACCINE
                                            --21066	SARS-COV-2 VACCINE (HISTORICAL)
                                         select distinct IMMUNZATN_ID 
                                           from CLARITY_IMMUNZATN 
                                          where name like '%COV%2%' -- get all SARS-COV-2 VACCINEs
                                            and name not like '%(HISTORICAL)%'
                                                )    
              ) 
  
  
--------------------------------------------------------------------------------------------------------------------------------------                      
----- BASE POPULATION DATA
--------------------------------------------------------------------------------------------------------------------------------------------------------------             
-- LOGIC SELECTS THE MOST RECENT VACCINATION
-- FILTERS FOR DESIRED DATE RANGE
, BASE_POP AS (
                SELECT * 
                  FROM IMM_DAT 
                 WHERE DOSE_RANK = 1                        ---- LOOKUP THE MOST RECENT VAX TO FIND DOSE NUMBER
                   AND IMM_DAT.IMM_HISTORIC_ADM_YN IS NULL  ---- REMOVES DOCUMENTATION ONLY OBSERVATIONS 
                   AND  TRUNC (IMM_DAT.IMMUNE_DATE)  BETWEEN         ---- ----- -----  ( SELECT START_DATE FROM MYPARAMS )  
                                                                      ( SELECT REPORT_BEGIN_DATE FROM MYPARAMS )    
                                                               and    ( SELECT END_DATE FROM MYPARAMS )   ---COLLECT AND RANK VACCINATIONS
                 )
               
--------------------------------------------------------------------------------------------------------------------------------------------------------------                      
----- PATIENT DEMOGRAPHICS
--------------------------------------------------------------------------------------------------------------------------------------------------------------                 
, PAT_DEMO  AS  (  ----  PATIENT ADDRESS
                  SELECT * 
                    FROM ( 
                          SELECT  DISTINCT
                                    PATIENT.PAT_ID 
                                  , PATIENT.PAT_MRN_ID AS MRN 
                                  , PATIENT.PAT_FIRST_NAME    
                                  , PATIENT.PAT_MIDDLE_NAME   
                                  , PATIENT.PAT_LAST_NAME                                    
                                  , CAST(PATIENT.BIRTH_DATE AS DATE)   AS BIRTH_DATE  
                                  
                                  , CASE
                                        WHEN  ZC_SEX.ABBR = 'F'   THEN 'Female'
                                        WHEN  ZC_SEX.ABBR = 'M'   THEN 'Male'                                        
                                        WHEN  ZC_SEX.ABBR IS NULL THEN 'Unknown'
                                        WHEN  ZC_SEX.ABBR = 'U'   THEN 'Unknown' 
                                        ELSE  'Unknown'   
                                     END                      AS PAT_GENDER
                                                                     
                                  ,  CASE 
                                           WHEN Z_RACE1.NAME IS NULL                                        THEN   'Unknown'
                                           WHEN Z_RACE1.NAME = 'White or Caucasian'                         THEN   'White'
                                           WHEN Z_RACE1.NAME = 'Black or African American'                  THEN   Z_RACE1.NAME
                                           WHEN Z_RACE1.NAME = 'American Indian or Alaska Native'           THEN   Z_RACE1.NAME
                                           WHEN Z_RACE1.NAME = 'Asian'                                      THEN   Z_RACE1.NAME
                                           WHEN Z_RACE1.NAME = 'Native Hawaiian or Other Pacific Islander'  THEN   Z_RACE1.NAME
                                           WHEN Z_RACE1.NAME = 'Patient Refused'                            THEN   'Declined to State' 
                                           WHEN Z_RACE1.NAME = 'Unknown'                                    THEN   Z_RACE1.NAME
                                           WHEN Z_RACE1.NAME = 'Other'                                      THEN   Z_RACE1.NAME 
                                           ELSE 'Other'
                                          END             AS PATIENT_RACE1   
                                        
                                  , CASE 
                                         WHEN ZC_ETHNIC_GROUP.NAME IS NULL                      THEN   'Unknown' 
                                         WHEN ZC_ETHNIC_GROUP.NAME = 'Patient Refused'          THEN   'Declined to State' 
                                         WHEN ZC_ETHNIC_GROUP.NAME = 'Not Hispanic or Latino'   THEN   ZC_ETHNIC_GROUP.NAME
                                         WHEN ZC_ETHNIC_GROUP.NAME = 'Unknown'                  THEN   ZC_ETHNIC_GROUP.NAME
                                         WHEN ZC_ETHNIC_GROUP.NAME = 'Hispanic or Latino'       THEN   ZC_ETHNIC_GROUP.NAME
                                         ELSE 'Unknown' 
                                     END                 AS PATIENT_ETHNIC                                    
                                  
                                  
                                  , PATIENT.ADD_LINE_1      PATIENT_ADDRESS1 
                                  , PATIENT.ADD_LINE_2      PATIENT_ADDRESS2 
                                  , PATIENT.CITY         AS PATIENT_CITY
                                  , ZC_STATE.NAME        AS PATIENT_STATE 
                                  , PATIENT.ZIP          AS PATIENT_ZIP  
                                  ,  CASE WHEN  ZC_COUNTY.NAME   IN (
                                                                        'ALAMANCE',	'CUMBERLAND',	'JOHNSTON',	'RANDOLPH',
                                                                        'ALEXANDER',	'CURRITUCK',	'JONES',	'RICHMOND',
                                                                        'ALLEGHANY',	'DARE',	'LEE',	'ROBESON',
                                                                        'ANSON',	'DAVIDSON',	'LENOIR',	'ROCKINGHAM',
                                                                        'ASHE',	'DAVIE',	'LINCOLN',	'ROWAN',
                                                                        'AVERY',	'DUPLIN',	'MACON',	'RUTHERFORD',
                                                                        'BEAUFORT',	'DURHAM',	'MADISON',	'SAMPSON',
                                                                        'BERTIE',	'EDGECOMBE',	'MARTIN',	'SCOTLAND',
                                                                        'BLADEN',	'FORSYTH',	'MCDOWELL',	'STANLY',
                                                                        'BRUNSWICK',	'FRANKLIN',	'MECKLENBURG',	'STOKES',
                                                                        'BUNCOMBE',	'GASTON',	'MITCHELL',	'SURRY',
                                                                        'BURKE',	'GATES',	'MONTGOMERY',	'SWAIN',
                                                                        'CABARRUS',	'GRAHAM',	'MOORE',	'TRANSYLVANIA',
                                                                        'CALDWELL',	'GRANVILLE',	'NASH',	'TYRRELL',
                                                                        'CAMDEN',	'GREENE',	'NEW HANOVER',	'UNION',
                                                                        'CARTERET',	'GUILFORD',	'NORTHAMPTON',	'VANCE',
                                                                        'CASWELL',	'HALIFAX',	'ONSLOW',	'WAKE',
                                                                        'CATAWBA',	'HARNETT',	'ORANGE',	'WARREN',
                                                                        'CHATHAM',	'HAYWOOD',	'PAMLICO',	'WASHINGTON',
                                                                        'CHEROKEE',	'HENDERSON',	'PASQUOTANK',	'WATAUGA',
                                                                        'CHOWAN',	'HERTFORD',	'PENDER',	'WAYNE',
                                                                        'CLAY',	'HOKE',	'PERQUIMANS',	'WILKES',
                                                                        'CLEVELAND',	'HYDE',	'PERSON',	'WILSON',
                                                                        'COLUMBUS',	'IREDELL',	'PITT',	'YADKIN',
                                                                        'CRAVEN',	'JACKSON',	'POLK',	'YANCEY',
                                                                        'OTHER'	
                                                                            )        THEN        initcap(ZC_COUNTY.name)  
                                       WHEN  ZC_COUNTY.NAME  is null then    'Other'
                                       ELSE    'Other'
                                       END                                      PATIENT_COUNTY 
 
                                  , ZC_COUNTRY_2.ABBR    AS PATIENT_COUNTRY
                                  , ZC_PAT_LIVING_STAT.TITLE  PAT_STATUS_C 
                                  , CASE 
                                      WHEN EMPY_STATUS_C IN ( 1,2,7,8 )  THEN 'STUDENT'
                                      WHEN EMPY_STATUS_C IN ( 9 )  THEN 'UNKNOWN'
                                      WHEN EMPY_STATUS_C IN ( 4 )  THEN 'EMPLOYED'
                                      WHEN EMPY_STATUS_C IN ( 3 )  THEN 'UNEMPLOYED' 
                                      ELSE 'OTHER'
                                     END             employment

                                   , EMERGENCY_CONTACTS.GUARDIAN_NAME
                                  
                                   , SUBSTR(EMERGENCY_CONTACTS.GUARDIAN_NAME, 0,
                                                 CASE WHEN INSTR(EMERGENCY_CONTACTS.GUARDIAN_NAME, ',')-1<0  THEN LENGTH(EMERGENCY_CONTACTS.GUARDIAN_NAME) 
                                                 ELSE INSTR (EMERGENCY_CONTACTS.GUARDIAN_NAME, ',')-1 END) AS GUARD_LAST_NAME 
                                                 
                                    , REPLACE(SUBSTR(EMERGENCY_CONTACTS.GUARDIAN_NAME, INSTR(EMERGENCY_CONTACTS.GUARDIAN_NAME, ','), LENGTH(EMERGENCY_CONTACTS.GUARDIAN_NAME)),',','')  GUARD_FIRST_NAME                                 
   
                                    , CASE
                                          WHEN  ZREL.NAME IS NULL THEN  'NA'
                                          WHEN  ZREL.NAME = 'Unknown'  THEN  'Unknown'
                                          WHEN  ZREL.NAME = 'Other'  THEN  'Other'
                                          WHEN  ZREL.NAME = 'Spouse'  THEN  'Spouse'
                                          WHEN  ZREL.NAME = 'Husband'  THEN  'Spouse'
                                          WHEN  ZREL.NAME = 'Wife'  THEN  'Spouse'
                                          WHEN  ZREL.NAME = 'Step Parent'  THEN  'Parent'
                                          WHEN  ZREL.NAME = 'Stepmother'  THEN  'Parent'
                                          WHEN  ZREL.NAME = 'Stepfather'  THEN  'Parent'
                                          WHEN  ZREL.NAME = 'Father'  THEN  'Parent'
                                          WHEN  ZREL.NAME = 'Mother'  THEN  'Parent'
                                          WHEN  ZREL.NAME = 'Legal Guardian'  THEN  'Legal Guardian'
                                          WHEN  ZREL.NAME = 'Foster Parent'  THEN  'Legal Guardian'
                                          WHEN  ZREL.NAME = 'Brother'  THEN  'Sibling'
                                          WHEN  ZREL.NAME = 'Sister'  THEN  'Sibling'
                                          WHEN  ZREL.NAME = 'Son'  THEN  'Child'
                                          WHEN  ZREL.NAME = 'Daughter'  THEN  'Child' 
                                          ELSE 'Other'
                                      END                               AS   GUARDIAN_REL 
                                    
                                   , SUBSTR(EMERGENCY_CONTACTS.MOTHER_NAME, 0,
                                                 CASE WHEN INSTR(EMERGENCY_CONTACTS.MOTHER_NAME, ',')-1<0  THEN LENGTH(EMERGENCY_CONTACTS.MOTHER_NAME) 
                                                 ELSE INSTR (EMERGENCY_CONTACTS.MOTHER_NAME, ',')-1 END)     AS  mother_maiden_name
                    
                                    , COALESCE ( ZC_OCCUPATION.NAME , PAT3.OCCUPATION )   OCCUPATION 
                                    , ZC_INDUSTRY.NAME   INDUSTRY 
                                    
                                    , CASE WHEN OTHER_COMMUNIC_NUM IS NOT NULL   AND  OTHER_COMMUNIC_C = '1' THEN OTHER_COMMUNIC_NUM  -- MOBILE
                                           WHEN PATIENT.HOME_PHONE IS NOT NULL                               THEN PATIENT.HOME_PHONE   -- HOME
                                      END  PATIENT_PHONE  
                                      
                                    , CASE WHEN OTHER_COMMUNIC_NUM IS NOT NULL   AND  OTHER_COMMUNIC_C = '1' THEN 'Mobile'
                                           WHEN PATIENT.HOME_PHONE IS NOT NULL                               THEN 'Home'
                                      END  PATIENT_PHONE_TYPE 
                                    
                                    , CASE    
                                            WHEN  ZC_LANGUAGE.NAME IS NULL    THEN  'Unknown'                                    
                                            WHEN  ZC_LANGUAGE.NAME = 'Chinese'  THEN  'Chinese'
                                            WHEN  ZC_LANGUAGE.NAME = 'English'  THEN  'English'
                                            WHEN  ZC_LANGUAGE.NAME = 'Hindi'  THEN  'Hindi'
                                            WHEN  ZC_LANGUAGE.NAME = 'Japanese'  THEN  'Japanese'
                                            WHEN  ZC_LANGUAGE.NAME = 'Other'  THEN  'Other'
                                            WHEN  ZC_LANGUAGE.NAME = 'Arabic'  THEN  'Arabic'
                                            WHEN  ZC_LANGUAGE.NAME = 'Portuguese'  THEN  'Portuguese'
                                            WHEN  ZC_LANGUAGE.NAME = 'Russian'  THEN  'Russian'
                                            WHEN  ZC_LANGUAGE.NAME = 'Spanish'  THEN  'Spanish'
                                            ELSE  'Other' 
                                      END                      PAT_LANGUAGE
  
                                    , PATIENT.EMAIL_ADDRESS
                                    
                                    , CASE WHEN PATIENT.IS_PHONE_REMNDR_YN = 'Y'   THEN 'Y'--- 'Y (YES)'
                                           WHEN PATIENT.IS_PHONE_REMNDR_YN IS NULL THEN 'Y'--- 'Y (YES)'
                                           WHEN PATIENT.IS_PHONE_REMNDR_YN = 'N'   THEN 'N'--- 'N (NO)'
                                           ELSE    'Y'--- 'Y (YES)'
                                      END              IS_PHONE_REMNDR_YN  
                                      
                                    , ROW_NUMBER() OVER (PARTITION BY PATIENT.PAT_ID 
                                                                      ORDER BY    PATIENT.PAT_ID 
                                                                                , P_RACE1.PATIENT_RACE_C  DESC  ) RANK  ----SORT BY RACE  
                            FROM ( 
                                   SELECT  DISTINCT 
                                           BASE_POP.PAT_ID
                                     FROM  BASE_POP                             
                                     ) BASE_POP
                                       JOIN PATIENT                 ON BASE_POP.PAT_ID              =  PATIENT.PAT_ID
                                  LEFT JOIN PATIENT_4               ON PATIENT.PAT_ID               =  PATIENT_4.PAT_ID
                                  LEFT JOIN PATIENT_3 PAT3          ON PATIENT.PAT_ID               =  PAT3.PAT_ID             
                                  LEFT JOIN ZC_PAT_LIVING_STAT      ON PATIENT_4.PAT_LIVING_STAT_C  = ZC_PAT_LIVING_STAT.PAT_LIVING_STAT_C 
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
                                  LEFT JOIN ZC_OCCUPATION           ON    PATIENT_4.OCCUPATION_C    =  ZC_OCCUPATION.OCCUPATION_C
                                  LEFT JOIN ZC_INDUSTRY             ON    PATIENT_4.INDUSTRY_C      =  ZC_INDUSTRY.INDUSTRY_C
                                  LEFT JOIN ZC_PAT_RELATION ZREL    ON ZREL.PAT_RELATION_C          = EMERGENCY_CONTACTS.GUARDIAN_REL_C 
                                  LEFT JOIN ZC_LANGUAGE             ON  PATIENT.LANGUAGE_C          = ZC_LANGUAGE.LANGUAGE_C
                                  LEFT JOIN OTHER_COMMUNCTN         ON  PATIENT.PAT_ID              = OTHER_COMMUNCTN.PAT_ID                                 
                                  
                        WHERE   1=1 
                        ) 
                  WHERE  RANK =1   --- GET 1 RACE IF MULTI-RACE PATIENT
                 ) 
 --------------------------------------------------------------------------------------------------------------------------------------------------------------                                         
---- IDENTIFY RELEVANT ICD10 DX FOR BASE POPULATION  DURING PERIOD 
--------------------------------------------------------------------------------------------------------------------------------------------------------------                      

,  DX_LIST AS (  
                  SELECT DISTINCT 
                         EDG_CURRENT_ICD10.CODE   icd10_dx_code
                    FROM EDG_CURRENT_ICD10  
                   WHERE EDG_CURRENT_ICD10.CODE IN ( 
                                                    'T81.49XA',	'T86.49',	
                                                    'T85.590A',	'T86.90',	
                                                    'T86.5',	'T86.91',	
                                                    'T86.00',	'T86.99',	
                                                    'T86.01',	'T86.810',	
                                                    'T86.02',	'T86.812',	
                                                    'T86.09',	'T86.819',	
                                                    'T86.10',	'T86.890',	
                                                    'T86.11',	'T86.891',	
                                                    'T86.12',	'T86.898',	
                                                    'T86.13',	'T86.899',	
                                                    'T86.19',	'T86.8409',	
                                                    'T86.20',	'T86.8411',	
                                                    'T86.21',	'T86.8419',	
                                                    'T86.40',	'T86.8429',	
                                                    'T86.41',	'T86.8489',	
                                                    'T86.43',	'T86.8499', 	-- transplants
                                                    'Q90.9',	  ----Down Syndrome	
                                                    'Q92.9'     ----Down Syndrome	 
                                                    )                       
                        )      

--------------------------------------------------------------------------------------------------------------------------------------------------------------                                         
---- CHECK PATIENTS THAT HAVE DX ENCOUNTER -- FIND PATIENTS WITH  ICD10 DX FOR BASE POPULATION  DURING PERIOD 
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
         
 ,dx as ( 
          select distinct 
                 pat_id
                 ,code
           from (
                 SELECT DISTINCT 
                        EDG.DX_NAME
                          , case  
                                 when EDG_CURRENT_ICD10.CODE like 'T%' then 'TX'
                                 when EDG_CURRENT_ICD10.CODE like 'Q%' then 'DS'
                            end   code  
                      , edg.DX_ID
                      , PAT_ENC_DX.PAT_ID
                      , PAT_ENC_DX.PAT_ENC_CSN_ID 
                      , PAT_ENC_DX.CONTACT_DATE   
                      , PAT_ENC_DX.PRIMARY_DX_YN   
                                              
                   FROM BASE_POP
                             JOIN  PAT_ENC              ON  BASE_POP.PAT_ID         =  PAT_ENC.PAT_ID
                             JOIN  CLARITY_dep  DEP      ON PAT_ENC.DEPARTMENT_ID   =  DEP.DEPARTMENT_ID       ----   --CHECK FOR DX ENCS IN DEPARTMENT
                             JOIN  PAT_ENC_DX           ON  PAT_ENC.PAT_ENC_CSN_ID  =  PAT_ENC_DX.PAT_ENC_CSN_ID   
                             JOIN  CLARITY_EDG  EDG     ON  PAT_ENC_DX.DX_ID        =  EDG.DX_ID  
                             JOIN  EDG_CURRENT_ICD10    ON  PAT_ENC_DX.DX_ID        =  EDG_CURRENT_ICD10.DX_ID 
                             JOIN  DX_LIST              ON  EDG_CURRENT_ICD10.CODE  =  DX_LIST.ICD10_DX_CODE   
                   WHERE   1=1 
                     AND  TRUNC( PAT_ENC_DX.CONTACT_DATE )  BETWEEN  TRUNC(((SELECT TO_DATE(START_DATE) FROM MYPARAMS))-365)    AND TRUNC((SELECT TO_DATE(END_DATE) FROM MYPARAMS)) 
                   )
              )
         
--------------------------------------------------------------------------------------------------------------------------------------------------------------                                         
---- CHECK PATIENT HAS HAD DX ENCOUNTER -- FIND PATIENTS WITH  ICD10 DX FOR BASE POPULATION  DURING PERIOD 
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
             
,pl as (
           select distinct 
                 pat_id
                 ,code
           from (                 
                    SELECT DISTINCT
                           EDG.DX_NAME
                          , case  
                                 when EDG_CURRENT_ICD10.CODE like 'T%' then 'TX'
                                 when EDG_CURRENT_ICD10.CODE like 'Q%' then 'DS'
                            end   code   
                          , edg.DX_ID
                          , PROBLEM_LIST.PAT_ID
                          , PROBLEM_LIST.PROBLEM_EPT_CSN    
                          ,PROBLEM_LIST.DATE_OF_ENTRY       
                          , PROBLEM_LIST.PRINCIPAL_PL_YN       
                     FROM  BASE_POP
                                JOIN  PAT_ENC              ON  BASE_POP.PAT_ID         =   PAT_ENC.PAT_ID
                                JOIN  CLARITY_dep  DEP     ON PAT_ENC.DEPARTMENT_ID   =  DEP.DEPARTMENT_ID       ----   --CHECK FOR DX ENCS IN DEPARTMENT                                
                                JOIN  PROBLEM_LIST         ON  PAT_ENC.PAT_ENC_CSN_ID  =   PROBLEM_LIST.PROBLEM_EPT_CSN     
                             JOIN  CLARITY_EDG  EDG     ON  PROBLEM_LIST.DX_ID        =  EDG.DX_ID  
                             JOIN  EDG_CURRENT_ICD10    ON  PROBLEM_LIST.DX_ID        =  EDG_CURRENT_ICD10.DX_ID 
                             JOIN  DX_LIST              ON  EDG_CURRENT_ICD10.CODE  =  DX_LIST.ICD10_DX_CODE 
                    WHERE   1=1  
                     AND  (     PROBLEM_LIST.NOTED_DATE    BETWEEN  TRUNC(((SELECT TO_DATE(START_DATE) FROM MYPARAMS))-365)   AND TRUNC((SELECT TO_DATE(END_DATE) FROM MYPARAMS))
                            OR  PROBLEM_LIST.DATE_OF_ENTRY BETWEEN  TRUNC(((SELECT TO_DATE(START_DATE) FROM MYPARAMS))-365)    AND TRUNC((SELECT TO_DATE(END_DATE) FROM MYPARAMS))
                            OR  PROBLEM_LIST.UPDATE_DATE   BETWEEN  TRUNC(((SELECT TO_DATE(START_DATE) FROM MYPARAMS))-365)    AND TRUNC((SELECT TO_DATE(END_DATE) FROM MYPARAMS))
                            ) 
                  )
              )
--------------------------------------------------------------------------------------------------------------------------------------------------------------                                         
---- COMBINE DX ENCOUNTERS WITH PROBLEM LIST DOCUMENTATION FOR CONSOLIDATED LISTING FOR ICD10 DX FOR BASE POPULATION  DURING PERIOD 
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
                  
, combined_DX_HX AS (

                    SELECT distinct
                            PAT_ID 
                          ,	CODE  
                     FROM (
                            SELECT  *   FROM DX  
                          union all
                            SELECT  *   FROM PL 
                            )  
                    WHERE 1=1 
                        ) 
 
--------------------------------------------------------------------------------------------------------------------------------------------------------------                      
----- COMORBIDITIES
--------------------------------------------------------------------------------------------------------------------------------------------------------------                  
 ,COMORBIDITY AS (  ---===== get ref for Moses !!!!!!
  --ADDED FROM ABOVE LOGIC FOR:
  ----Down Syndrome
  --- Q90.9 dx
  --- Q92.9 dx 
  ----Immunocompromised state (weakened immune system) from solid organ transplant
  --- see info from Moses on DX codes  -- SEE ABOVE
  
                  SELECT  CORMO.PAT_ID 
                        , COUNT ( CORMO.REGISTRY_ID) COMORBIDITIES
                    FROM (
                          SELECT 
                                  BASE_POP.PAT_ID
                                , CASE
                                        WHEN PAT_ACTIVE_REG.REGISTRY_ID = 82299
                                             AND OBG.OBGYN_STAT_C = 4                   THEN  4      --- PREG
                                        WHEN PAT_ACTIVE_REG.REGISTRY_ID = 82299 
                                             AND (  DM_WLL_ALL.SMOKING_STATUS_C IN  ( --ZC_SMOKING_TOB_USE 
                                                                                         '1' -- Current Every Day Smoker 
                                                                                        ,'2' -- Current Some Day Smoker 
                                                                                        ,'3' -- Smoker, Current Status Unknown 
                                                                                        ,'4' -- Former Smoker  
                                                                                        ,'9' -- Heavy Tobacco Smoker 
                                                                                        ,'10' -- Light Tobacco Smoker 
                                                                                        )
                                                  OR DM_WLL_ALL.SMOKING_USER_YN = 'Y'
                                                  )                                     THEN  82014
                                        WHEN PAT_ACTIVE_REG.REGISTRY_ID = 82299
                                             AND DM_WLL_ALL.HAS_TYP_2_DIABETES_YN ='Y'  THEN  82000
                                        WHEN PAT_ACTIVE_REG.REGISTRY_ID = 82299  
                                             and combined_DX_HX.code = 'DS'                  THEN 1                                             
                                        WHEN PAT_ACTIVE_REG.REGISTRY_ID = 82299  
                                             and combined_DX_HX.code = 'TX'                  THEN 2
                                        ELSE PAT_ACTIVE_REG.REGISTRY_ID
                                    END  REGISTRY_ID
                          
                          FROM BASE_POP 
                                left join combined_DX_HX      on    BASE_POP.PAT_ID         =  combined_DX_HX.pat_id     AND combined_DX_HX.CODE IN ('DS','TX')
                                LEFT JOIN  PAT_ACTIVE_REG     ON    BASE_POP.PAT_ID         =  PAT_ACTIVE_REG.PAT_ID 
                                LEFT JOIN  DM_OBESITY         ON    BASE_POP.PAT_ID         =  DM_OBESITY.pat_id
                                LEFT JOIN  OBGYN_STAT OBG     ON    BASE_POP.PAT_ENC_CSN_ID =  OBG.UPDATE_CSN
                                                          AND   OBG.OBGYN_STAT_C = 4                   -------------   PREGNANCY 
                                LEFT JOIN DM_WLL_ALL          ON    BASE_POP.PAT_ID         = DM_WLL_ALL.pat_id
                          
                          WHERE  1=1
                          AND (
                                (PAT_ACTIVE_REG.REGISTRY_ID  IN (
                                                                  '82030' --  CANCER POPULATION REGISTRY  
                                                                 ,'82005' --  Chronic kidney disease
                                                                 ,'82009' --  COPD (chronic obstructive pulmonary disease)
                                                                 ,'82004' --	CONGESTIVE HEART FAILURE REGISTRY
                                                                 ,'82006' --	CORONARY ARTERY DISEASE REGISTRY
                                                                 )
                                  )
                          
                             OR (
                                     PAT_ACTIVE_REG.REGISTRY_ID     =  82007   --- OBESITY REGISTRY
                                 AND DM_OBESITY.BMI_LAST >= 34
                                 ) 
                             OR (
                                     PAT_ACTIVE_REG.REGISTRY_ID     =  82000	 --- DIABETES REGISTRY
                                 AND DM_WLL_ALL.HAS_TYP_2_DIABETES_YN = 'Y'
                                 )          
                             OR (     PAT_ACTIVE_REG.REGISTRY_ID    =  82299	--- WELLNESS REGISTRY-ALL
                                 AND (   
                                         combined_DX_HX.CODE IN ('DS','TX')
                                     OR DM_WLL_ALL.SMOKING_USER_YN = 'Y'
                                     OR DM_WLL_ALL.SMOKING_STATUS_C IN  ( --ZC_SMOKING_TOB_USE 
                                                                             '1' -- Current Every Day Smoker 
                                                                            ,'2' -- Current Some Day Smoker 
                                                                            ,'3' -- Smoker, Current Status Unknown 
                                                                            ,'4' -- Former Smoker  
                                                                            ,'9' -- Heavy Tobacco Smoker 
                                                                            ,'10' -- Light Tobacco Smoker 
                                                                            ) 
                                       )
                                  )
                              )                   
                           )  CORMO
                    GROUP BY PAT_ID
                   )  
 
------------------------------------------------------------------------------------------------------------------------------------------------------------------                      
--------- SEROLOGY
------------------------------------------------------------------------------------------------------------------------------------------------------------------    
--, SEROLOGY AS ( 
--leave blank   and the date !!!!!!! 
------ If recipient was diagnosed with COVID-19 through blood test not poc, include data and the date of diagnosis 
----------leaving serology out because we are not consistently capturing serology at time of vax
--                  )
           
,GRP AS (
        SELECT * 
         FROM ( 
         SELECT DISTINCT 
                   PAT.PAT_ID 
                  -- ,cvg.pat_rec_of_subs_id
                  --,pat.PAT_MRN_ID	 
                  , CASE    
                      WHEN cvg.pat_rec_of_subs_id  =  PAT.PAT_ID  AND cvg.payor_id ='405'  then 'HEALTHCARE'   ---subscr is the patient there fore get the data
                      WHEN cvg.pat_rec_of_subs_id  =  PAT.PAT_ID  AND  ( EEP.employer_name LIKE '%UNIVERSITY%' OR EEP.employer_name LIKE '%SCHOOL%' OR EEP.employer_name LIKE '%WFB%') then 'EDUCATION'
                      WHEN cvg.pat_rec_of_subs_id  =  PAT.PAT_ID   
                            AND ( EEP.employer_name LIKE '%MEDICAL%' OR EEP.employer_name LIKE '%HOSPITAL%' OR EEP.employer_name LIKE '%HEALTH%' OR EEP.employer_name LIKE '%WFB%' ) then 'HEALTHCARE' 
                      ELSE coalesce ( PAT3.OCCUPATION , ZC_OCCUPATION.NAME, 'UNKNOWN'  )  
                  END         OCCUPATION 
                  
                  , CASE    
                      WHEN cvg.pat_rec_of_subs_id  =  PAT.PAT_ID  AND cvg.payor_id ='405'  then 'HEALTHCARE'   ---subscr is the patient there fore get the data
                      WHEN cvg.pat_rec_of_subs_id  =  PAT.PAT_ID  AND  ( EEP.employer_name LIKE '%UNIVERSITY%' OR EEP.employer_name LIKE '%SCHOOL%' OR EEP.employer_name LIKE '%WFB%') then 'EDUCATION'
                      WHEN cvg.pat_rec_of_subs_id  =  PAT.PAT_ID   
                            AND ( EEP.employer_name LIKE '%MEDICAL%' OR EEP.employer_name LIKE '%HOSPITAL%' OR EEP.employer_name LIKE '%HEALTH%' OR EEP.employer_name LIKE '%WFB%' ) then 'HEALTHCARE'
                      ELSE  coalesce (  ZC_INDUSTRY.NAME  ,  'OTHER'  )   
                  END   INDUSTRY
                  
                  , CASE    
                      WHEN cvg.pat_rec_of_subs_id  =  PAT.PAT_ID THEN  Z1.NAME   
                      WHEN cvg.pat_rec_of_subs_id  <> PAT.PAT_ID AND EMPY_STATUS_C IN ( 1,2,7,8 )  THEN 'STUDENT'
                      WHEN cvg.pat_rec_of_subs_id  <> PAT.PAT_ID AND EMPY_STATUS_C IN ( 9 )  THEN 'UNKNOWN'
                      WHEN cvg.pat_rec_of_subs_id  <> PAT.PAT_ID AND EMPY_STATUS_C IN ( 4 )  THEN 'EMPLOYED'
                      WHEN cvg.pat_rec_of_subs_id  <> PAT.PAT_ID AND EMPY_STATUS_C IN ( 3 )  THEN 'UNEMPLOYED' 
                      ELSE 'OTHER'
                     END             employment_STATUS 
                    ,EEP.employer_name 
                    , ROW_NUMBER() 
                       OVER ( PARTITION BY   PAT.PAT_ID  
                                  ORDER BY   PAT.PAT_ID
                                           , MEM_EFF_FROM_DATE  DESC )   RANK  --- USE TO FIND MOST RECENT     
               FROM BASE_POP 
                     JOIN PATIENT PAT               ON PAT.PAT_ID                   = BASE_POP.PAT_ID
                LEFT JOIN COVERAGE_MEM_LIST cml     on cml.pat_id                   = pat.pat_id
                LEFT JOIN V_COVERAGE_PAYOR_PLAN cpp on cpp.coverage_id              = cml.coverage_id
                LEFT JOIN COVERAGE cvg              on cml.coverage_id              = cvg.COVERAGE_ID
            
                LEFT JOIN PATIENT_3 PAT3            ON    PAT3.PAT_ID               =  BASE_POP.PAT_ID
                LEFT JOIN PATIENT_4                 ON    PAT.PAT_ID                =  PATIENT_4.PAT_ID
                LEFT JOIN ZC_OCCUPATION             ON    PATIENT_4.OCCUPATION_C    =  ZC_OCCUPATION.OCCUPATION_C
                LEFT JOIN ZC_INDUSTRY               ON    PATIENT_4.INDUSTRY_C      =  ZC_INDUSTRY.INDUSTRY_C 
                LEFT JOIN ZC_SUBSCR_EMP_STAT  Z1    ON    cvg.SUBSCR_EMP_STAT_C     =  Z1.SUBSCR_EMP_STAT_C 
                LEFT JOIN CLARITY_EEP  EEP          ON    EEP.EMPLOYER_ID           =  CVG.SUBSCR_EMPLOYER_ID
                
         WHERE  1=1 
                 AND  (   MEM_EFF_TO_DATE IS NULL
                       OR TRUNC(cml.MEM_EFF_TO_DATE) >= TRUNC   ( BASE_POP.IMMUNE_DATE ) 
                       )
               )
       WHERE RANK =1
      )
 
------------------------------------------------------------------------------------------------------------------------------------------------------------                      
----- ADIN_IMMS  - BRINGING DATA TOGETHER FOR REPORTING
--------------------------------------------------------------------------------------------------------------------------------------------------------------          
, ADMIN_IMMS AS  ( 
                   SELECT     
-- Pat_demo.pat_id,  -- TESTING ONLY
                            'WFBHCOVID'                     recip_authority_id    ---HARDCODE PER CVMS  -- PARENT LOCATION OF ALL WAKE FOREST
                            , PAT_DEMO.MRN                  recip_id 
                            , PAT_DEMO.PAT_FIRST_NAME       FirstName
                            , PAT_DEMO.PAT_MIDDLE_NAME      MiddleName
                            , PAT_DEMO.PAT_LAST_NAME        LastName
                            , To_Char( PAT_DEMO.BIRTH_DATE , 'yyyy-mm-dd')  PersonBirthDate
                            , PAT_DEMO.PAT_GENDER           Gender 
                        
                            , CASE  WHEN PAT_DEMO.GUARDIAN_NAME IS NOT NULL  THEN  TRIM (PAT_DEMO.GUARD_FIRST_NAME) 
                                    ELSE TRIM (PAT_DEMO.PAT_FIRST_NAME)   
                              END                                  resp_first_name
                  
                            , CASE  WHEN PAT_DEMO.GUARDIAN_NAME IS NOT NULL  THEN ' ' 
                                    ELSE  TRIM (PAT_DEMO.PAT_MIDDLE_NAME)   
                              END                                  resp_middle_name 
                              
                            , CASE  WHEN PAT_DEMO.GUARDIAN_NAME IS NOT NULL  THEN  TRIM (PAT_DEMO.GUARD_LAST_NAME) 
                                    ELSE TRIM (PAT_DEMO.PAT_LAST_NAME)   
                              END                                  resp_last_name 
                          
                            ,  CASE WHEN PAT_DEMO.GUARDIAN_REL is null               THEN  'Self' 
                                    WHEN PAT_DEMO.GUARDIAN_REL = 'NA'                THEN  'Self'
                                    WHEN (    PAT_DEMO.GUARDIAN_REL = 'Unknown'
                                          AND PAT_DEMO.GUARD_LAST_NAME IS NULL
                                          AND PAT_DEMO.GUARD_FIRST_NAME IS NULL 
                                          )                                          THEN  'Self'
                                    WHEN PAT_DEMO.GUARDIAN_REL  =   'Unknown' 
                                         AND (    PAT_DEMO.GUARD_LAST_NAME IS not NULL
                                               or PAT_DEMO.GUARD_FIRST_NAME IS not NULL 
                                          
                                               )                                     THEN  PAT_DEMO.GUARDIAN_REL  
                                    ELSE                                                   PAT_DEMO.GUARDIAN_REL
                                END                                 relationship_to_recip
         
                            , PAT_DEMO.mother_maiden_name          mother_maiden_name 
 
--                            , PAT_DEMO.PATIENT_ADDRESS1 ADDRESS_1
                            , COALESCE (  PAT_DEMO.PATIENT_ADDRESS1 ,  BASE_POP.dep_address_line_1)   ADDRESS_1
                            , PAT_DEMO.PATIENT_ADDRESS2 ADDRESS_2
--                            , PAT_DEMO.PATIENT_CITY     City
                             , COALESCE (  PAT_DEMO.PATIENT_CITY ,  BASE_POP.dep_CITY)   cITY
                            , COALESCE ( PAT_DEMO.PATIENT_STATE  ,'North Carolina')  State
                            
                            , COALESCE ( PAT_DEMO.PATIENT_COUNTrY, 'USA' )   Country  
                            , COALESCE ( PAT_DEMO.PATIENT_ZIP   , BASE_POP.DEP_ZIP)   Zip                       
--                            , PAT_DEMO.PATIENT_COUNTY   County
                             , COALESCE (PAT_DEMO.PATIENT_COUNTY  , BASE_POP.DEP_COUNTY)   COUNTY
                            , PAT_DEMO.PATIENT_RACE1    Race
                            , PAT_DEMO.PATIENT_ETHNIC   Ethnicity 
                                  
                            , CASE  WHEN PAT_DEMO.PAT_LANGUAGE  IS NULL     THEN  'English'
                                    WHEN PAT_DEMO.PAT_LANGUAGE = 'Unknown'  THEN  'English'
                                  else  PAT_DEMO.PAT_LANGUAGE 
                              END                        recip_primary_language  
                              
                            , CASE  WHEN PAT_DEMO.PATIENT_PHONE  IS NOT NULL  THEN  PAT_DEMO.PATIENT_PHONE   
                              END                       recip_telephone_number     

                            , CASE  WHEN PAT_DEMO.PATIENT_PHONE_TYPE  IS NOT NULL  THEN  PAT_DEMO.PATIENT_PHONE_TYPE 
                                    ELSE  'Mobile' 
                              END                       recip_telephone_number_type     
                            
                            , PAT_DEMO.EMAIL_ADDRESS    recip_email
                            
                            , CASE  WHEN PAT_DEMO.IS_PHONE_REMNDR_YN  IS NOT NULL  THEN   PAT_DEMO.IS_PHONE_REMNDR_YN
                                    WHEN PAT_DEMO.IS_PHONE_REMNDR_YN  IS NULL THEN 'Unknown'
                                    ELSE  'Unknown'
                              END                      recall_notices  
                             
                            , BASE_POP.org_name                                                                    
                            , BASE_POP.admin_name   
                            , BASE_POP.vtrcks_prov_pin   --- vfc for admin  location  '40166742'  
--                            , BASE_POP.ndc
                            , case 
--                                    when BASE_POP.ndc ='59267-1000-01' then '59267-1000-02'
--                                    when BASE_POP.ndc ='80777-0273-10' then '80777-0273-99'
                                    when BASE_POP.ndc like '59267%' then '59267-1000-02'  ---Pfizer-Biontech COVID-19 Vaccine  
                                    when BASE_POP.ndc like '80777%' then '80777-0273-99'  ---Moderna COVID-19 Vaccine  
                                    when BASE_POP.ndc like '59676%' then '59676-0580-05'  ---Johnson Johnson/Janssen Vaccine 
                                    else   BASE_POP.ndc
                               end                   ndc
                            ,  To_Char( BASE_POP.IMMUNE_DATE  , 'yyyy-mm-dd') ADMIN_DATE 
                            , BASE_POP.vax_event_id 
                      
                            
--------------------------------------------------------------------  
-- ADDED LOGIC TO CHECK DOSE NUMBER WHEN VISIT TYPE IS NULL  --AAE03-31-2021
-------------------------------------------------------------------- 
                            ,   CASE 
                                    WHEN  BASE_POP.prc_id = '586'                   THEN   'Dose 1 Administered'   
                                    
                                    WHEN ( BASE_POP.prc_id IS NULL  AND 
                                           BASE_POP.dose_num  = 1                )  THEN   'Dose 1 Administered'  

                                    WHEN ( BASE_POP.prc_id not IN ('586','587', '588') 
                                          AND  BASE_POP.dose_num  = 1            )  THEN   'Dose 1 Administered'   
                                    
                                    WHEN  BASE_POP.prc_id IN ('587', '588')         THEN   'Dose 2 Administered' 
                                    
                                    WHEN ( BASE_POP.dose_num  > 1    OR  
                                           BASE_POP.VISIT_TYPE LIKE '%2ND DOSE%' )  THEN   'Dose 2 Administered'  
                                           
                                           
                                 END                    dose_num                                  
--------------------------------------------------------------------                                 
                                 
                            , BASE_POP.lot_number  
                            , TO_CHAR(  BASE_POP.vax_expiration_date , 'YYYY-MM-DD')  vax_expiration_date
                            , BASE_POP.vax_admin_site
                            , BASE_POP.vax_route 
                            , BASE_POP.vax_admin_provider_name 
                            
                            , Case
                                  when BASE_POP.ndc     like '59267%' and  BASE_POP.IMMUNE_DATE <  '10-mar-2021'  then  '12-2020' 
                                  when BASE_POP.ndc     like '59267%' and  BASE_POP.IMMUNE_DATE >= '10-mar-2021'  then  '03-2021'  ---Pfizer-Biontech COVID-19 Vaccine
                                  else     
                                          case
                                               when TO_CHAR(BASE_POP.vis_publication_date , 'MM-YYYY') <> '12-2020' then '12-2020'
                                               when TO_CHAR(BASE_POP.vis_publication_date , 'MM-YYYY') is null      then '12-2020'
                                               when TO_CHAR(BASE_POP.vis_publication_date , 'MM-YYYY') =' '         then '12-2020'
                                               else TO_CHAR(BASE_POP.vis_publication_date , 'MM-YYYY')
                                           end  
                               End       vis_publication_date  --- VIS EUA DATE  
                               
                            
                            ,case when BASE_POP.vis_date_given_to_recipient is null then   To_Char( BASE_POP.IMMUNE_DATE  , 'yyyy-mm-dd') ---ADMIN_DATE 
                                  when BASE_POP.vis_date_given_to_recipient =' '    then   To_Char( BASE_POP.IMMUNE_DATE  , 'yyyy-mm-dd') ---ADMIN_DATE  
                                  when BASE_POP.vis_date_given_to_recipient ='1'    then   To_Char( BASE_POP.IMMUNE_DATE  , 'yyyy-mm-dd') ---ADMIN_DATE  
                                  else  TO_CHAR( coalesce ( EPIC_UTIL.EFN_DIN(  bASE_POP.vis_date_given_to_recipient ),BASE_POP.IMMUNE_DATE)   , 'YYYY-MM-DD') 
                             end   vis_date_given_to_recipient      -- SHEET GIVEN TO recipient 
 
                            ,   CASE 
                                  WHEN COMORBIDITY.COMORBIDITIES = 1     THEN   '1'         
                                  WHEN COMORBIDITY.COMORBIDITIES > 1     THEN   '2 or more'       
                                  WHEN COMORBIDITY.COMORBIDITIES IS NULL THEN   'None'         
                                END                       cmorbid_status --- Comorbidity status (Y/N)                             
 
-----------------------------------------------------------
-- need to add logic for Tiering / Program in Five Phases 
                           ,CASE
                               WHEN (    COALESCE (  GRP.INDUSTRY , GRP.OCCUPATION  ,PAT_DEMO.INDUSTRY  )      LIKE UPPER ('%HealthCare%')  
                                     )  
                                    AND  COALESCE (   GRP.EMPLOYMENT_STATUS ,PAT_DEMO.EMPLOYMENT ) IN ('Full Time','Part Time','Self Employed')  
                                                                                                              THEN 'Group 1'---'Phase 1a' --Health Care Workers and LTC staff and residentS
                                WHEN (
                                       trunc( months_between( BASE_POP.IMMUNE_DATE,  PAT_DEMO.birth_date )/ 12 ) >=65   
                                      )                                                                                         THEN 'Group 2'---'Phase 1b' -- >=65  and frontline essential workers
                               WHEN (    COALESCE (  GRP.INDUSTRY , GRP.OCCUPATION  ,PAT_DEMO.INDUSTRY  )      LIKE UPPER ('%ChildCare%')  
                                        or  COALESCE (  GRP.INDUSTRY , GRP.OCCUPATION  ,PAT_DEMO.INDUSTRY  )      LIKE UPPER ('%Education%') 
                                     )                                                                                          THEN 'Group 3'---'Phase 2' 
                                WHEN ( 
                                       trunc( months_between( BASE_POP.IMMUNE_DATE,  PAT_DEMO.birth_date )/ 12 )  between 16 and 64  
                                            OR  COMORBIDITY.COMORBIDITIES > 0
                                      )                                                                                         THEN 'Group 4'---'Phase 3' 
                                
                                ELSE                                                                                                 'Group 5'---'Phase 4' 
                             END                                     recip_priority_group    --- ADD LOGIC  FOR TIER IE priority 
 
                            ,'Unknown'                               SEROLOGY          --Required, if known for this recipient.   If Unknown, please leave blank.  
                            ,' '                                     Date_of_Disease   --Required, if known for this recipient.   If Unknown, please leave blank.  
                            , BASE_POP.AdverseReactionConsent        Vaccine_Refusal                                                   
                           
                        ,     CASE 
                                      WHEN  UPPER ( COALESCE (   GRP.OCCUPATION ,PAT_DEMO.OCCUPATION  ) )    LIKE UPPER ('%Long Term Care Facility%')    THEN    'Resident of Long Term Care Facility'
                                      WHEN  UPPER ( COALESCE (   GRP.OCCUPATION ,PAT_DEMO.OCCUPATION  ) )    LIKE UPPER ('%Congregant%Group%')    THEN    'Resident of Congregant/Group Setting'
                                      WHEN  UPPER ( COALESCE (   GRP.OCCUPATION ,PAT_DEMO.OCCUPATION  ) )    LIKE UPPER ('Student')    THEN    'Student'
                                      WHEN  UPPER ( COALESCE (   GRP.OCCUPATION ,PAT_DEMO.OCCUPATION  ) )    LIKE UPPER ('%Frontline%Worker%')    THEN    'Frontline Essential Worker ( In Person at Work)'
                                      WHEN  UPPER ( COALESCE (   GRP.OCCUPATION ,PAT_DEMO.OCCUPATION  ) )    LIKE UPPER ('%Essential Worker%')    THEN    'Other Essential Worker (non-frontline)'
                                      WHEN  UPPER ( COALESCE (   GRP.OCCUPATION ,PAT_DEMO.OCCUPATION  ) )    LIKE UPPER ('Health Care')   THEN    'Patient-facing Healthcare/ Long Term Care Facility Worker'
                                      WHEN  UPPER ( COALESCE (   GRP.OCCUPATION ,PAT_DEMO.OCCUPATION  ) )    LIKE UPPER ('%Childcare%')   THEN    'Childcare or PreK-12 Education'  
                                      WHEN  UPPER ( COALESCE (   GRP.OCCUPATION ,PAT_DEMO.OCCUPATION  ) )   IS NULL THEN    'None of the Above'  ---- 'Other / Not Applicable' 
                                     ELSE    'None of the Above'
                               END                             Recipient_type  
                        
                        ,     CASE 
                                    WHEN (    UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('%HealthCare%') 
                                           or UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('%Health Care%')  ) THEN    'Health Care'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Public Safety')    THEN    'Public Safety'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Food and agriculture')    THEN    'Food and agriculture'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Critical Manufacturing ')    THEN    'Critical Manufacturing '
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Commercial Facilities for Essential Goods')    THEN    'Commercial Facilities for Essential Goods'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Education')    THEN    'Education'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Transportation')    THEN    'Transportation'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Residential�facilities, housing,�and real estate')    THEN    'Residential�facilities, housing,�and real estate'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Finance')    THEN    'Finance'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('IT%Communication%')    THEN    'IT and Communication'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Energy')    THEN    'Energy'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Water and Wastewater')    THEN    'Water and Wastewater'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Commercial facilities')    THEN    'Commercial facilities'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Government and Community Services')    THEN    'Government and Community Services'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Public works and infrastructure support services')    THEN    'Public works and infrastructure support services'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Industries involving chemicals or hazardous materials')    THEN    'Industries involving chemicals or hazardous materials'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Hygiene products and services')    THEN    'Hygiene products and services'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Public Health')    THEN    'Public Health'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) )    LIKE UPPER ('Defense industrial base')    THEN    'Defense industrial base'
                                    WHEN  UPPER ( COALESCE (  GRP.INDUSTRY  ,PAT_DEMO.INDUSTRY  ) ) IS NULL THEN   'Other / Not Applicable'  
                                    ELSE      'Other / Not Applicable'
                               END       INDUSTRY
       
                            ,TO_CHAR( sysdate , 'YYYY-MM-DD')        file_date
                            ,' '                                      ssn          --- PER MOSES  NOT PROVIDING
                            ,' '                                      drivers_lic  --- PER MOSES  NOT PROVIDING
                            ,' '                                      ins_policy   --- PER MOSES  NOT PROVIDING
--                           ,BASE_POP.last_update                                  ---2021_02_09 new field for adding update
                        ,BASE_POP.vax_event_last_modified                          ---2021_02_09 new field for adding update
                        ,BASE_POP.PAT_ID  
 
                        ,case when ( BASE_POP.ndc like '59267%' or upper(BASE_POP.PRODUCT_NAME)   like upper( 'PFIZER%COV%'   ) )  then 'Pfizer COVID-19 Vaccine (EUA)'
                              when ( BASE_POP.ndc like '80777%' or upper(BASE_POP.PRODUCT_NAME)   like upper( 'MODERNA%COV%'  ) )  then 'Moderna COVID-19 Vaccine (EUA)'
                              when ( BASE_POP.ndc like '59676%' or upper(BASE_POP.PRODUCT_NAME)   like upper( 'JANSSEN%COV%'  ) )  then 'Johnson Johnson COVID-19 Vaccine (EUA)'
                              when upper(BASE_POP.PRODUCT_NAME)   like upper( 'ASTRAZENECA%COV%'  )   then    'AstraZeneca COVID19 Vaccine (EUA)'
                             else BASE_POP.PRODUCT_NAME 
                         end  PRODUCT_NAME
------------------additional fields added on 3/2/2021                        
                        ,BASE_POP.template_prov_id   epic_clinic_prov_id
                        ,BASE_POP.template_prov_name epic_clinic_prov
                        ,BASE_POP.EPIC_DEPARTMENT  
                        ,BASE_POP.VISIT_TYPE 
                        ,base_pop.dose_num   patient_doses 
--                      , FAILED_iMM_CSN_CHECK
                       ,BASE_POP.IMMUNE_DATE 
                       ,base_pop.EXCLUDEd_CLINIC
                    FROM  BASE_POP      
                               JOIN PAT_DEMO                  ON BASE_POP.PAT_ID            = PAT_DEMO.PAT_ID 
                          LEFT JOIN COMORBIDITY               ON BASE_POP.PAT_ID            = COMORBIDITY.PAT_ID
--                          LEFT JOIN serology                  ON BASE_POP.PAT_ID            =  serology.PAT_ID 
                          LEFT JOIN GRP                       ON BASE_POP.PAT_ID            = GRP.PAT_ID 
                          LEFT JOIN combined_DX_HX            ON BASE_POP.PAT_ID            = combined_DX_HX.PAT_ID 
                  WHERE  1=1   
                      )
        
---------------------------
----MAINLINE 
---------------------------
    SELECT ADMIN_IMMS.*  
      FROM ADMIN_IMMS 
     WHERE  1=1
----     and trunc( IMMUNE_DATE) >'09-MAR-21'
--     and  (    visit_type like upper('COVID%Vaccine%')
--           or  visit_type like upper('%2nd%dose%')
--            ) 
--       ORDER BY  IMMUNE_DATE ,lastname,  recip_id  
                    