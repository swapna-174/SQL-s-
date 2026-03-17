WITH
DAILY_PTS AS
--
-- List of Patients by day who were admitted to, transferred to, transferred from, or discharged from 
-- MC RT 07 CARDIOLOGY UNIT or MC RT 05 CARDIOTHORACIC SURGERY / VASCULAR UNIT
-- or were on one of these units when the midnight census occurred.
--
(
SELECT *
FROM
(
SELECT *
FROM
(
    SELECT
        pat.PAT_MRN_ID
        , TRUNC(adt.EFFECTIVE_TIME) "CensusDate"
        , adt.EVENT_TYPE_C
        , adt.EFFECTIVE_TIME
        , dep.DEPARTMENT_NAME
    FROM CLARITY_ADT adt
        INNER JOIN PATIENT pat ON adt.PAT_ID = pat.PAT_ID
        INNER JOIN CLARITY_DEP dep On adt.DEPARTMENT_ID = dep.DEPARTMENT_ID
        LEFT OUTER JOIN CLARITY_ADT adt_out ON adt.XFER_EVENT_ID = adt_out.EVENT_ID
        LEFT OUTER JOIN CLARITY_ADT adt_in ON adt.XFER_IN_EVENT_ID = adt_in.EVENT_ID
    WHERE adt.EFFECTIVE_TIME >= (SELECT to_date('2016-02-02 00:00:00', 'yyyy-mm-dd hh24:mi:ss') AS DTTM FROM DUAL)
        AND adt.EFFECTIVE_TIME <= (SELECT to_date('2016-02-02 23:59:59', 'yyyy-mm-dd hh24:mi:ss') AS DTTM FROM DUAL)
--        AND adt.DEPARTMENT_ID IN  ('1000106014', '1000106015')
        AND adt.DEPARTMENT_ID = '1000106014'
        AND adt.EVENT_TYPE_C IN ('1','2','3','4',' 6')
--        AND adt.EVENT_TYPE_C = '1'
        AND adt.EVENT_SUBTYPE_C <> 2
        AND adt.PAT_ID IS NOT NULL
--
-- To eliminate transfer in and transfer out records where the patient transferred from one room to another with the same unit.
--
        AND (adt_out.DEPARTMENT_ID IS NULL
            OR adt_out.DEPARTMENT_ID <> adt.DEPARTMENT_ID)
       AND (adt_in.DEPARTMENT_ID IS NULL
            OR adt_in.DEPARTMENT_ID <> adt.DEPARTMENT_ID)
    GROUP BY 
        pat.PAT_MRN_ID
        , adt.EFFECTIVE_TIME
        , adt.EVENT_TYPE_C
        , dep.DEPARTMENT_NAME
    ORDER BY pat.PAT_MRN_ID, adt.EFFECTIVE_TIME
)
)

PIVOT

(
    MIN(EFFECTIVE_TIME)
    FOR EVENT_TYPE_C IN ('1' AS Admission, '3' AS TransferIn, '4' AS TransferOut, '2' AS Discharge, '6' AS Census)
)
)

, BED_TIMES AS

(
SELECT
    dpts.PAT_MRN_ID
    , dpts.DEPARTMENT_NAME
    , dpts.Admission
    , dpts.TransferIn
    , dpts.TransferOut
    , dpts.Discharge
    , TRUNC(dpts.TransferIn, 'hh24') "TEST"
--
-- The date the patient was on one of the units.
--
    , CASE
        WHEN dpts.Admission IS NOT NULL
            THEN TRUNC(dpts.Admission)
        WHEN dpts.TransferIn IS NOT NULL
            THEN TRUNC(dpts.TransferIn)
        WHEN dpts.Discharge IS NOT NULL
            THEN TRUNC(dpts.Discharge)
        WHEN dpts.TransferOut IS NOT NULL
            THEN TRUNC(dpts.TransferOut)
        ELSE TRUNC(dpts.Census)
        END AS "InBedDate"
--
-- The time the patient was bedded in one of the two units, truncated to the format XX:00:00.
--
    , CASE
        WHEN dpts.Admission IS NOT NULL
            THEN TO_CHAR(TRUNC(dpts.Admission, 'hh24'), 'hh24:mi:ss')
        --
        -- Exclude instances where a patient transfers out temporarily for a procedure, then returns to the unit.
        --
        WHEN (dpts.TransferIn IS NOT NULL AND dpts.TransferOut IS NULL)
                OR (dpts.TransferIn IS NOT NULL AND dpts.TransferIn < dpts.TransferOut)
            THEN TO_CHAR(TRUNC(dpts.TransferIn, 'hh24'), 'hh24:mi:ss')
        --
        -- If there are no Admission or TransferIn events for the day and Discharge is not null, 
        -- TRUNC  Discharge to get 12:00:00.
        --
        WHEN dpts.Discharge IS NOT NULL
            THEN TO_CHAR(TRUNC(dpts.Discharge), 'hh24:mi:ss')
        --
        -- If there are no Admission, TransferIn, or Discharge events for the day and TransferOut is not null, 
        -- TRUNC  TransferOut to get 12:00:00.
        --
        WHEN dpts.TransferOut IS NOT NULL
            THEN TO_CHAR(TRUNC(dpts.TransferOut), 'hh24:mi:ss')
        ELSE TO_CHAR(TRUNC(dpts.Census), 'hh24:mi:ss')
        END AS "FirstInBedTime"

--
-- The time the patient was last in a bed in one of the two units, truncated to the format XX:00:00. 
--
    , CASE
        WHEN dpts.Discharge IS NOT NULL
            THEN TO_CHAR(TRUNC(dpts.Discharge, 'hh24'), 'hh24:mi:ss')
        WHEN (dpts.TransferOut IS NOT NULL AND dpts.TransferIn IS NULL)
                OR (dpts.TransferOut IS NOT NULL AND dpts.TransferIn < dpts.TransferOut)
            THEN TO_CHAR(TRUNC(dpts.TransferOut, 'hh24'), 'hh24:mi:ss')
        ELSE TO_CHAR(TRUNC(dpts.Census, 'hh24'), 'hh24:mi:ss')
        END AS "LastInBedTime"
FROM DAILY_PTS dpts
ORDER BY dpts.PAT_MRN_ID
)

SELECT
    bt.PAT_MRN_ID
    , bt.DEPARTMENT_NAME
    , bt."TEST"
    , bt.Admission
    , bt.TransferIn
    , bt.TransferOut
    , bt.Discharge
    , bt."InBedDate"
--    , bt."FirstInBedTimeTEST"
    , bt."FirstInBedTime"
    , bt."LastInBedTime"
    , CASE WHEN "FirstInBedTime" = '00:00:00' THEN 'Yes' ELSE 'No' END AS "Census0000"
    , CASE WHEN '01:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census0100"
    , CASE WHEN '02:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census0200"
    , CASE WHEN '03:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census0300"
    , CASE WHEN '04:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census0400"
    , CASE WHEN '05:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census0500"
    , CASE WHEN '06:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census0600"
    , CASE WHEN '07:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census0700"
    , CASE WHEN '08:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census0800"
    , CASE WHEN '09:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census0900"
    , CASE WHEN '10:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census1000"
    , CASE WHEN '11:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census1100"
    , CASE WHEN '12:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census1200"
    , CASE WHEN '13:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census1300"
    , CASE WHEN '14:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census1400"
    , CASE WHEN '15:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census1500"
    , CASE WHEN '16:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census1600"
    , CASE WHEN '17:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census1700"
    , CASE WHEN '18:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census1800"
    , CASE WHEN '19:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census1900"
    , CASE WHEN '20:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census2000"
    , CASE WHEN '21:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census2100"
    , CASE WHEN '22:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census2200"
    , CASE WHEN '23:00:00' BETWEEN "FirstInBedTime" AND "LastInBedTime" THEN 'Yes' ELSE 'No' END AS "Census2300"
FROM BED_TIMES bt










