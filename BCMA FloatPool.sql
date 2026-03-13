SELECT DISTINCT
mar.TAKEN_TIME
,cm.NAME        "MEDICATION"
,ordi.ORDER_MED_ID
,pat.pat_mrn_id "MRN"
,zcnamed.NAME  "BCMA_MED_SCAN"
,medalrt.NAME   "MED_ALERT_REASON"
, CASE 
    WHEN mar.BCMA_MED_SCANCOMP_C = 13
        OR mar.MAR_ACTION_C NOT IN ('1','6','12','13','100','102','105','113','114','115','117','1000','1002','1005','1010','1016')

        OR (mar.BCMA_MED_SCANCOMP_C IS NULL AND 
            (rx3.REQUIRE_SCAN_YN='N' 
            OR mar.MAR_TIME_SOURCE_C IN (9,10,12,13)))
    THEN 0 
    ELSE 1 
    END "MED_REQUIRED_SCAN_BOOL"
, CASE 
    WHEN mar.BCMA_MED_SCANCOMP_C IN (12,13)
        OR mar.MAR_ACTION_C NOT IN ('1','6','12','13','100','102','105','113','114','115','117','1000','1002','1005','1010','1016')
        OR (mar.BCMA_MED_SCANCOMP_C IS NULL AND
            (rx3.REQUIRE_SCAN_YN='N' 
            OR mar.MAR_TIME_SOURCE_C IN (9,10,12,13)
            OR mar.MED_OVRIDE_ALERT_ID IS NOT NULL))
    THEN 0 
    ELSE 1 
    END "MED_SCANNED_BOOL"
,zcnapat.NAME  "BCMA_PAT_SCAN"
,patalrt.NAME   "PAT_ALERT_REASON"

, CASE
    WHEN mar.BCMA_PAT_SCANCOMP_C = 13
        OR mar.MAR_ACTION_C NOT IN ('1','6','12','13','100','102','105','113','114','115','117','1000','1002','1005','1010','1016')
        OR (mar.BCMA_PAT_SCANCOMP_C IS NULL AND 
            (mar.MAR_TIME_SOURCE_C IN (9,10,12,13)))
    THEN 0 
    ELSE 1 
  END "PAT_REQUIRED_SCAN_BOOL"
, CASE
    WHEN mar.BCMA_PAT_SCANCOMP_C IN (12,13)
        OR mar.MAR_ACTION_C NOT IN ('1','6','12','13','100','102','105','113','114','115','117','1000','1002','1005','1010','1016')
        OR (mar.BCMA_PAT_SCANCOMP_C IS NULL AND 
            (mar.MAR_TIME_SOURCE_C IN (9,10,12,13)
            OR mar.PAT_OVRIDE_ALERT_ID IS NOT NULL))
    THEN 0 
    ELSE 1 
  END "PAT_SCANNED_BOOL"
,CASE WHEN 
       mar.MAR_ACTION_C IN ('1','6','115','102','105','12','117','1016','1002','1010')

    AND( mar.BCMA_PAT_SCANCOMP_C = 11 
    OR (mar.BCMA_PAT_SCANCOMP_C IS NULL
    AND mar.MED_OVRIDE_ALERT_ID IS NULL))
 THEN 1 ELSE 0 END "NUMERATOR"

,CASE WHEN
    mar.TAKEN_TIME IS NOT NULL
    AND (ovrdl.OVRD_LNK_LINE IS NULL
    OR mar.OVRD_LINK_STATUS_C IS NOT NULL)
    AND(mar.BCMA_MED_SCANCOMP_C <> 13
          
   OR (mar.MAR_ACTION_C IN ('1','6','115','102','105','12','117','1016','1002','1010')
    AND mar.BCMA_MED_SCANCOMP_C IS NULL
    AND (rx3.REQUIRE_SCAN_YN = 1 OR rx3.REQUIRE_SCAN_YN IS NULL)
    AND mar.MAR_TIME_SOURCE_C NOT IN (9,10,12,14,13)))
     THEN 1 ELSE 0 END "DENOMINATOR"

,zcmar.NAME  "MAR_ACTION"
,mar.MAR_ACTION_C
,zcsrc.NAME "MAR_TIME_SOURCE"
,mar.MAR_TIME_SOURCE_C
,ser.PROV_NAME
,ser.PROVIDER_TYPE
,mar.MAR_ADMIN_DEPT_ID
,dep.DEPARTMENT_NAME
,parloc.LOC_NAME
,emp.USER_ID
,emp.NAME
,ser.PROV_ID
,ser.DEPARTMENT_ID
,ser.DEPARTMENT_NAME
,ordi.ORDER_MED_ID
FROM MAR_ADMIN_INFO mar
INNER JOIN ORDER_MEDINFO ordi ON mar.ORDER_MED_ID = ordi.ORDER_MED_ID
LEFT OUTER JOIN rx_med_three rx3 ON ordi.DISPENSABLE_MED_ID = rx3.MEDICATION_ID
LEFT OUTER join MAR_OVRD_LINK_LINE ovrdl ON mar.ORDER_MED_ID = ovrdl.ORDER_MED_ID
LEFT OUTER JOIN clarity_dep dep ON mar.MAR_ADMIN_DEPT_ID = dep.DEPARTMENT_ID
LEFT OUTER JOIN clarity_loc loc ON dep.REV_LOC_ID = loc.LOC_ID
LEFT OUTER JOIN clarity_loc parloc ON loc.HOSP_PARENT_LOC_ID = parloc.LOC_ID
LEFT OUTER JOIN clarity_emp emp ON mar.USER_ID = emp.USER_ID
LEFT OUTER JOIN ZC_NO_YES_NA zcnamed ON mar.BCMA_MED_SCANCOMP_C = zcnamed.NO_YES_NA_C
LEFT OUTER JOIN ZC_NO_YES_NA zcnapat ON mar.BCMA_PAT_SCANCOMP_C = zcnapat.NO_YES_NA_C
LEFT OUTER JOIN ZC_MAR_RSLT zcmar ON mar.MAR_ACTION_C = zcmar.RESULT_C
LEFT OUTER JOIN ZC_MAR_TIME_SRC zcsrc ON mar.MAR_TIME_SOURCE_C = zcsrc.MAR_TIME_SRC_C
LEFT OUTER JOIN D_PROV_PRIMARY_HIERARCHY ser ON emp.PROV_ID = ser.PROV_ID
--LEFT OUTER JOIN clarity_ser sert ON ser.PROV_ID = ser.USER_ID

LEFT OUTER JOIN ALT_HISTORY medah ON mar.MED_OVRIDE_ALERT_ID=medah.ALT_ID 
LEFT OUTER JOIN ALT_HISTORY patah ON mar.PAT_OVRIDE_ALERT_ID=patah.ALT_ID 
LEFT OUTER JOIN ZC_ALRT_SP_OVR_RSN medalrt ON medah.SPEC_OVR_RSN_C=medalrt.ALRT_SP_OVR_RSN_C
LEFT OUTER JOIN ZC_ALRT_SP_OVR_RSN patalrt ON patah.SPEC_OVR_RSN_C=patalrt.ALRT_SP_OVR_RSN_C 
LEFT OUTER JOIN RX_MED_TWO rx2 ON ordi.DISPENSABLE_MED_ID=rx2.MEDICATION_ID
LEFT OUTER JOIN clarity_medication cm ON ordi.DISPENSABLE_MED_ID = cm.MEDICATION_ID
LEFT OUTER JOIN patient pat ON ordi.PAT_ID = pat.PAT_ID

WHERE
 TRUNC(mar.TAKEN_TIME) >= TRUNC (ADD_MONTHS (epic_util.efn_din (sysdate), -1), 'MM') 
AND TRUNC(mar.TAKEN_TIME)  < TRUNC (ADD_MONTHS (epic_util.efn_din (sysdate), 0), 'MM') 
AND mar.MAR_ACTION_C IN  ('1','6','115','102','105','12','117','1016','1002','1010')
AND LOWER(emp.USER_ID) IN (
'aalynch',
'abbwood',
'acarillo',
'acarpent',
'aclontz',
'acorrell',
'adeliger',
'adelong',
'adrijohn',
'adshumat',
'afrankl',
'alstaylo',
'amayton',
'amcdonne',
'aprwilli',
'arocham',
'aruffin',
'asalah',
'asantiag',
'astarlin',
'atcasste',
'avictori',
'banspach',
'bder',
'bhuffman',
'bhunter',
'bkcline',
'bkpowell',
'blflores',
'bredavis',
'bredd',
'bsgreen',
'cacross',
'calimuru',
'camassey',
'canwilli',
'ccthornt',
'cdiones',
'cgarriso',
'chowells',
'chwillia',
'ckwilkin',
'clblackb',
'clyoung',
'cmalachi',
'crlannin',
'cwalls',
'cwest',
'cyhall',
'cywall',
'darkiger',
'dbullers',
'dftorres',
'dgateley',
'dllowe',
'dltate',
'dmccoy',
'dnesgoda',
'dpitt',
'drbaker',
'drblue',
'dsaid',
'dsese',
'eaward',
'echance',
'eledford',
'epatton',
'erenegar',
'esahadi',
'etrullwa',
'etucker',
'fwade',
'gcrensha',
'gruegeme',
'hidulsa',
'hlwarren',
'janallen',
'jbuono',
'jcduncan',
'jcorona',
'jdollive',
'jennibro',
'jfabia',
'jgavin',
'jlamonds',
'jmtate',
'jpmcinto',
'jrbowers',
'jrwarren',
'jsmurphy',
'jsuarezb',
'jtsherri',
'jvjackso',
'jwyant',
'kadjones',
'kaharris',
'kbrooke',
'kcburton',
'kdollive',
'keaster',
'kemcleod',
'kgross',
'khollowa',
'kirobert',
'kkoech',
'klpresco',
'knickels',
'krhunter',
'ktrexler',
'kwainsco',
'lcneal',
'ldeschen',
'lfulcher',
'llineber',
'lnichols',
'lrbennet',
'lwingfie',
'maeller',
'marnette',
'maustria',
'mbalbera',
'mbantigu',
'mcbrock',
'mcreed',
'mdouthit',
'mfreiber',
'mhache',
'mhmitche',
'mhowlett',
'mjavier',
'mjwolfe',
'mkcornat',
'mlprice',
'mmbaker',
'mmohamme',
'mscunana',
'mswinste',
'mtrombin',
'mworthin',
'mwprivet',
'nabair',
'nagee',
'ndjones',
'neze',
'njoshi',
'ofadeyi',
'pcoleman',
'pcrawfor',
'pgwhitfi',
'pkirkwoo',
'pliotard',
'rcornatz',
'rdalanon',
'rdoherty',
'rgnelson',
'rgragg',
'rkoontz',
'rmalit',
'rseguerr',
'rtonsay',
'rvasica',
'sammatth',
'sasimmon',
'sbboyd',
'scroft',
'sdbrown',
'sedaniel',
'sgnelson',
'skrodrig',
'skyei',
'slycan',
'smatczak',
'sokwudi',
'spilgrim',
'spreid',
'spungwa',
'srule',
'ssargent',
'sstaylor',
'stedward',
'svelazqu',
'syhooper',
'taswiceg',
'tccannon',
'tenscore',
'tholland',
'tkublank',
'tlspry',
'tmcdanie',
'tmotsing',
'trcoving',
'trhome',
'tsowens',
'tsrice',
'uyrichar',
'vbitterm',
'vcoggins',
'vhenry',
'vlloyd',
'voconnel',
'vsnichol',
'wjwillia',
'yperez',
'zclement',
'zosiones')
--AND emp.USER_ID IN ( 'ACORRELL','ERENEGAR','KIROBERT')

--SELECT *
--FROM CLARITY_EMP emp
--INNER JOIN clarity_emp_2 emp2 ON emp.USER_ID = emp2.USER_ID
--INNER JOIN clarity_emp_3 emp3 ON emp.USER_ID = emp3.USER_ID
----INNER JOIN CLARITY_EMP_ROLE empr ON emp.USER_ID = empr.USER_ID
--WHERE
--emp.USER_ID IN ( 'ACORRELL','ERENEGAR','KIROBERT')
--
--
--
--SELECT *
--FROM ZC_CLASSES

