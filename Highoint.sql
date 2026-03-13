--**********************************************************************************
--  REVENUE USAGE BY ACCOUNT CLASS REPORTING GROUPED BY SERVICE DATE
--   NOTE:  THE POST DATE IS USED TO PULL DATA BETWEEN DATES PROVIDED BY USER
--**********************************************************************************
 SELECT COMPANY,OPERATING_UNIT,DEPT, PROGRAM,FUND,
              COST_CTR, SERVICE_DT, STAT_CODE, ACCT_CODE, ACCT_CLASS  ,PROC_CODE
             , CHARGES, AMOUNT
   FROM
  (
    SELECT COMPANY,DEPT,OPERATING_UNIT,FUND, PROGRAM 
        , COST_CTR, SERVICE_DT, STAT_CODE, ACCT_CODE, ACCT_CLASS      
        , SUM(CHARGES) AS CHARGES
        , SUM(AMOUNT) AS AMOUNT 
        ,PROC_CODE
     FROM 
     (  
     SELECT X.COMPANY,X.DEPT,X.OPERATING_UNIT, X.FUND, X."PROGRAM",  X.COST_CTR 
              , TO_CHAR(HT.SERVICE_DATE, 'MM/DD/YYYY')  AS SERVICE_DT 
            --  , HT.SERVICE_DATE AS SERVICE_DT
              , AC.NAME AS ACCT_CLASS
              , CASE WHEN AC.ABBR IN ('I', 'IP', 'IR', 'IH') THEN 'I'
                     ELSE 'O'
                END AS  ACCT_CODE
              , HT.TX_AMOUNT AS AMOUNT    
              , CASE WHEN X.QUANTITY_FLAG = 'Y' THEN HT.QUANTITY *  X.QTY_MULTIPLIER
                          WHEN HT.QUANTITY < 0          THEN -1
                          ELSE 1  
                END  AS CHARGES           
              , X.STAT_CODE
              , PROC.PROC_CODE
            
   --*  EPIC CLARITY TABLES             
           FROM CLARITY.HSP_TRANSACTIONS@EDWS2CLARITY HT                                      
           JOIN CLARITY.ZC_ACCT_CLASS_HA @EDWS2CLARITY AC ON  AC.ACCT_CLASS_HA_C = HT.ACCT_CLASS_HA_C 
           JOIN CLARITY.CLARITY_EAP@EDWS2CLARITY PROC        ON  HT.PROC_ID = PROC.PROC_ID
           JOIN CLARITY.CL_COST_CNTR@EDWS2CLARITY C            ON  HT.COST_CNTR_ID = C.COST_CNTR_ID            
  
   --*  BUDGET OFFICE (LANE JESSUP) DEPT, COST CENTER, PROCEDURE CODE TABLE         
           JOIN EDWSEXTRACTADMIN.CST_CNTR_DEPT_HIGHTPOINT_NEW  X  --< MAIN CAMPUS WFBMC 
             ON  C.COST_CENTER_CODE = X.COST_CTR 

      ---WHERE ( HT.TX_POST_DATE BETWEEN   :STARTDATE AND :ENDDATE ) 
           WHERE ( HT.TX_POST_DATE BETWEEN  '01-JUL-2021' AND '31-JUL-2021')
            AND HT.TX_TYPE_HA_C IN (1, 4)
            AND ( X.PROC_CODE = 'ALL' OR X.PROC_CODE = PROC.PROC_CODE) 
       
   --* NEW 2013-11-13:  DO NOT INCLUDE CERTAIN DEPT + COST CTR + PROC_CODE COMBOS PER LANE JESSUP        
             AND NOT EXISTS (SELECT 1
                               FROM EDWSEXTRACTADMIN.CST_CNTR_DEPT_PROC_EXCLUDES2_NEW EXC  
                              WHERE EXC.OPERATNG_UNIT = X.OPERATING_UNIT 
                                  AND EXC.DEPT = X.DEPT 
                                  AND EXC.COST_CTR = X.COST_CTR 
                                  AND EXC.PROC_CODE = PROC.PROC_CODE)        
       )
   GROUP BY  COMPANY,DEPT,OPERATING_UNIT,FUND,PROGRAM, COST_CTR, SERVICE_DT, STAT_CODE,ACCT_CODE, ACCT_CLASS,PROC_CODE
 )
 WHERE CHARGES <> 0 OR AMOUNT <> 0
 ORDER BY  COMPANY,DEPT,OPERATING_UNIT,FUND, PROGRAM, COST_CTR, SERVICE_DT, STAT_CODE, ACCT_CLASS,PROC_CODE