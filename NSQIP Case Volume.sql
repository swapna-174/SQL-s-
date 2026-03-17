SELECT 
    orl.LOG_ID
    , orl.SURGERY_DATE
    , ser.PROV_NAME "OR ROOM"
    , FLOOR((orl.SURGERY_DATE - pat.BIRTH_DATE) / 365.25) "Age at Encounter"
    , vlb.SERVICE_NM
    , vlb.PRIMARY_PROCEDURE_NM
    
FROM OR_LOG orl
    INNER JOIN PATIENT pat ON orl.PAT_ID = pat.PAT_ID
    INNER JOIN CLARITY_SER ser ON orl.ROOM_ID = ser.PROV_ID
    INNER JOIN V_LOG_BASED vlb ON orl.LOG_ID = vlb.LOG_ID
    
WHERE     
    orl.ROOM_ID IN ('2000','2001','2002','2003','2004','2005','2006','2007','2008','2009','2010','2011',
                '2012','2013','2014','2015','2016','2017','2018','2019','2020','2021','2022','2023','2024','2025','2026','2027','2028','2029',
                '2030','2031','2032','2033','2034','2035','2036','2037','2038','2039','2040','2041','2042','2043')
    AND orl.STATUS_C IN (2,5)
    AND orl.SURGERY_DATE >'30-Nov-2018'
    AND orl.SURGERY_DATE < '01-Dec-2019'
    AND (FLOOR((orl.SURGERY_DATE - pat.BIRTH_DATE) / 365.25)) >= 18
    
    
