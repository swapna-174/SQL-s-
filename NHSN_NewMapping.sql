-- *** SqlDbx Personal Edition ***
-- !!! Not licensed for commercial use beyound 90 days evaluation period !!!
-- For version limitations please check http://www.sqldbx.com/personal_edition.htm
-- Number of queries executed: 4073, number of rows retrieved: 10486786

SELECT *
    FROM NHSN_FACILITY_MAPPING nhsn_fac
    INNER JOIN nhsn_definition nhsn_def ON nhsn_fac.MAPPED_FACILITY_NHSN_DEF_ID = nhsn_def.NHSN_DEF_ID
--    LEFT OUTER JOIN clarity_dep_3 dep3 ON nhsn_fac.FACILITY_ID = dep3.PARENT_HOSP_ID
        LEFT OUTER JOIN nhsn_location_mapping nhsn_loc ON nhsn_def.NHSN_DEF_ID = nhsn_loc.MAPPED_LOCATION_NHSN_DEF_ID

WHERE
nhsn_loc.DEPARTMENT_ID = 1000108023
21
16

SELECT *
FROM nhsn_definition nd
INNER JOIN nhsn_definition_overtime ndo ON nd.NHSN_DEF_ID = ndo.NHSN_DEF_ID 
WHERE
nd.NHSN_DEF_ID IN (16,21)


SELECT *
    FROM NHSN_FACILITY_MAPPING nhsn_fac
    LEFT OUTER JOIN clarity_loc loc ON nhsn_fac.FACILITY_ID = loc.LOC_ID
    LEFT OUTER JOIN clarity_dep_3 dep3 ON nhsn_fac.FACILITY_ID = dep3.PARENT_HOSP_ID
    LEFT OUTER JOIN clarity_dep dep ON dep3.DEPARTMENT_ID = dep.DEPARTMENT_ID
    LEFT OUTER JOIN nhsn_location_mapping nhsn_loc ON dep3.DEPARTMENT_ID = nhsn_loc.DEPARTMENT_ID AND nhsn_fac.LINE = nhsn_loc.LINE
    LEFT OUTER JOIN nhsn_definition nhsn_def ON nhsn_loc.MAPPED_LOCATION_NHSN_DEF_ID = nhsn_def.NHSN_DEF_ID
    WHERE
    nhsn_loc.DEPARTMENT_ID = 1000108023
