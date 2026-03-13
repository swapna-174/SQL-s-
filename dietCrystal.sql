          WITH PPLHNO
          AS
          (
            SELECT --*
            hno.NOTE_ID
            ,hno.PAT_ENC_CSN_ID
            ,nte.CONTACT_DATE
            ,hno.CURRENT_AUTHOR_ID
            FROM hno_info hno 
            LEFT OUTER JOIN note_enc_info nte ON hno.NOTE_ID = nte.NOTE_ID 
            WHERE
            hno.IP_NOTE_TYPE_C = 2
--            AND hno.PAT_ENC_CSN_ID = 30123714055
            AND (nte.AUTHOR_SERVICE_C = 3048000300 OR nte.AUTHOR_PRVD_TYPE_C = 104)
            -- and nte.CONTACT_DATE = '23-jul-2020'
           AND nte.CONTACT_DATE >= EPIC_UTIL.EFN_DIN ('{?Start_Date}')    
           AND nte.CONTACT_DATE <= EPIC_UTIL.EFN_DIN ('{?End_Date}')
          
          )
          
          
          
          
            SELECT *
            FROM 
             (   
               
               
                SELECT distinct
                pat.PAT_MRN_ID
                ,pat.PAT_NAME
                ,hsp.PAT_ENC_CSN_ID
                ,CASE WHEN TRUNC((hno.CONTACT_DATE  - pat.BIRTH_DATE) / 365.25) < 1
                THEN CASE WHEN months_between (to_date(hno.CONTACT_DATE ), pat.BIRTH_DATE) < 1
                THEN CONCAT(to_char(floor(TRUNC(hno.CONTACT_DATE ) - pat.BIRTH_DATE))  ,' Days')
                ELSE CONCAT(to_char(floor(months_between (to_date(hno.CONTACT_DATE ), pat.BIRTH_DATE) ) ),' Months')  END        
                ELSE to_char(TRUNC(floor(hno.CONTACT_DATE  - pat.BIRTH_DATE) / 365.25))
                END "PATIENT_AGE_AT_ENCOUNTER"
                ,sex.NAME  "SEX"
                ,hsp.HOSP_ADMSN_TIME
                ,dep.DEPARTMENT_NAME  "UNIT"
                ,parloc.LOC_NAME  "PARENT_HOSPITAL"
                ,ser.PROV_NAME  "NOTE_AUTHOR_NM"
                ,hno.contact_date  "SERVICE_DATE"
                ,dd.MONTH_NAME
                ,dd.MONTH_NUMBER
                ,dd."YEAR"
                ,dd.YEAR_MONTH
                ,row_number() OVER (PARTITION BY pat.PAT_ID,ser.PROV_ID,hno.contact_date ORDER BY hno.contact_date ) "SEQ_NUM"
                FROM PPLHNO hno
                INNER JOIN PAT_ENC_HSP hsp ON hno.PAT_ENC_CSN_ID = hsp.PAT_ENC_CSN_ID
                INNER join patient pat ON hsp.PAT_ID = pat.PAT_ID
                LEFT OUTER JOIN zc_sex sex ON pat.SEX_C = sex.RCPT_MEM_SEX_C
                LEFT OUTER JOIN clarity_ser ser ON hno.CURRENT_AUTHOR_ID = ser.USER_ID
                LEFT OUTER JOIN clarity_dep dep ON hsp.DEPARTMENT_ID = dep.DEPARTMENT_ID
                LEFT OUTER JOIN clarity_loc loc ON dep.REV_LOC_ID = loc.LOC_ID
                LEFT OUTER JOIN clarity_loc parloc ON loc.HOSP_PARENT_LOC_ID = parloc.LOC_ID
                INNER JOIN DATE_DIMENSION dd ON hno.contact_date = dd.CALENDAR_DT
                where 
--                  parloc.LOC_ID IN (100009, 100010, 100011, 100012)
                (parloc.LOC_ID IN {?HospitalLocation} OR '0' IN {?HospitalLocation})   

                 
           )
           
       WHERE 
       SEQ_NUM = 1  
