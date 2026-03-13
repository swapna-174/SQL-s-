-- *** SqlDbx Personal Edition ***
-- !!! Not licensed for commercial use beyound 90 days evaluation period !!!
-- For version limitations please check http://www.sqldbx.com/personal_edition.htm
-- Number of queries executed: 5163, number of rows retrieved: 11066676

SELECT *
FROM ZC_EVS_TYPE



SELECT --*
loc.LOC_NAME
,CDEP.DEPT_ABBREVIATION  "SECTOR"
--,bev.EVS_NONBED_CLN_PLF_ID
--,plf.RECORD_NAME
,plf.DISPLAY_NAME
,bev.RECORD_NAME  "ROOM_NUMBER"
,cl_eve.INSTANT_TM  "CLEAN_DTTM"
,bev.EVENT_TYPE_C
,CDEP.DEPARTMENT_NAME
,cl_eve.RECORD_ID


FROM CL_BEV_EVENTS cl_eve
LEFT JOIN CL_BEV_ALL bev ON bev.RECORD_ID = cl_eve.RECORD_ID
LEFT JOIN cl_plf plf ON bev.EVS_NONBED_CLN_PLF_ID = plf.RECORD_ID
LEFT JOIN CLARITY_LOC loc ON loc.LOC_ID = bev.EAF_ID 
LEFT OUTER JOIN CLARITY_DEP CDEP ON bev.DEP_ID = CDEP.DEPARTMENT_ID
LEFT JOIN CL_HKR HKR on cl_eve.HKR_ID = HKR.RECORD_ID
WHERE 

TRUNC(cl_eve.INSTANT_TM) >= '1-apr-2021' 
--AND TRUNC(INSTANT_TM) <= '29-apr-2021'
--WHERE INSTANT_TM >= EPIC_UTIL.EFN_DIN('{?Begin Date}') 
--AND INSTANT_TM < EPIC_UTIL.EFN_DIN('{?End Date}')+1 
AND cl_eve.STATUS_C = 5    ---- completed
AND bev.ACTIVE_C <> 4    ---- not canceled
--AND HKR.EMP_ID = 'DEBMILLE'
AND (CDEP.DEPT_ABBREVIATION IN ('SSINTRANT1', 'SSOBPERIMC' )
      OR bev.EVS_NONBED_CLN_PLF_ID = '10485')
--OR CDEP.DEPARTMENT_NAME LIKE '%11 ARDMORE%'

--AND CDEP.DEPT_ABBREVIATION IN ('10AE','10AWA','10NT','10BU',
--AND cl_eve.RECORD_ID = 2088354
2106864

SELECT *
FROM CL_BEV_ALL bev_all
WHERE
bev_all.RECORD_ID = 2088354


SELECT *
FROM CLARITY_DEP dep
WHERE
dep.DEPARTMENT_NAME LIKE 'MC AW%' and
 dep.EXTERNAL_NAME LIKE '%Ardmore West%'
dep.DEPARTMENT_NAME LIKE '%PROC%'
--dep.DEPT_ABBREVIATION = '%18%'
dep.DEPARTMENT_NAME LIKE '%WEST%'

SELECT *
FROM CLARITY_EMP emp
WHERE
emp.NAME LIKE '%BAYTOPS, E%'

SELECT *
FROM V_ADT_EVS evs
LEFT OUTER JOIN CL_HKR hkr ON evs.HKR_ID = hkr.RECORD_ID
LEFT OUTER JOIN clarity_dep dep ON evs.DEPARTMENT_ID = dep.DEPARTMENT_ID
WHERE
--hkr.EMP_ID = 'DEBMILLE' and
TRUNC(evs.CLEAN_START_DTTM) >= '01-jan-2021'


SELECT *
FROM CL_BEV_ALL bev_all
LEFT OUTER JOIN CL_BEV_EVENTS beve ON bev_all.RECORD_ID = beve.RECORD_ID
LEFT OUTER JOIN CL_HKR hkr ON beve.HKR_ID = hkr.RECORD_ID

WHERE
bev_all.EVS_NONBED_CLN_PLF_ID = 10485
AND  TRUNC(INSTANT_TM) >= '1-apr-2021'
AND beve.STATUS_C = 5    ---- completed
AND bev_all.ACTIVE_C <> 4    ---- not canceled
