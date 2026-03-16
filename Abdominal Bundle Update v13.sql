--
--  This CTE captures the main patient population of those who have had a surgical procedure that falls under the Abdominal
-- Bundle protocol.  Procedures are queried by CPT Code.
--
WITH
PAT_POP AS
(
SELECT *
FROM
(
    SELECT *
    FROM
    (
        SELECT
            TO_CHAR(orl.SURGERY_DATE,'MM/DD/YYYY') "Surgery Date"
            , orl.SURGERY_DATE
            , atm.SURGICAL_LOG_ID
            , orl.LOG_ID
            , pat.PAT_ID
            , pat.PAT_MRN_ID
            , FLOOR((orl.SURGERY_DATE - pat.BIRTH_DATE) / 365.25) "Age at Encounter"
            , enc.PAT_ENC_CSN_ID
            , enc.INPATIENT_DATA_ID
            , pat.PAT_NAME
            , vlb.PRIMARY_PHYSICIAN_NM
            , bil.RECORD_NAME "Surgical Service"
            , CASE
                WHEN loc2.LOC_NAME = 'PARENT HIGH POINT' THEN 'HP'
                WHEN loc2.LOC_NAME = 'PARENT WAKE FOREST' THEN 'Winston'
                WHEN loc2.LOC_NAME = 'PARENT LEXINGTON' THEN 'Lexington'
                WHEN loc2.LOC_NAME = 'PARENT WILKES' THEN 'Wilkes'
                WHEN loc2.LOC_NAME = 'PARENT DAVIE' THEN 'Davie'
                ELSE loc2.LOC_NAME
            END AS "Location"
            , orl.CASE_CLASS_C
            , zc_cc.NAME "Case Class Name"
            , pbt.CPT_CODE
            , eap.PROC_NAME
            , vlp.WOUND_CLASS_NM
            , olc.TRACKING_EVENT_C
            , olc.TRACKING_TIME_IN
            , RANK() OVER ( PARTITION BY orl.LOG_ID ORDER BY orl.LOG_ID, pbt.CPT_CODE) rank
        FROM ARPB_TRANSACTIONS pbt
            LEFT OUTER JOIN ARPB_TX_MODERATE atm ON pbt.TX_ID = atm.TX_ID
            LEFT OUTER JOIN PAT_ENC enc ON enc.PAT_ENC_CSN_ID = pbt.PAT_ENC_CSN_ID
            LEFT OUTER JOIN PATIENT pat ON pbt.PATIENT_ID = pat.PAT_ID
            LEFT OUTER JOIN OR_LOG orl ON atm.SURGICAL_LOG_ID = orl.LOG_ID
            LEFT OUTER JOIN ZC_OR_CASE_CLASS zc_cc ON orl.CASE_CLASS_C = zc_cc.CASE_CLASS_C
            LEFT OUTER JOIN V_LOG_BASED vlb ON orl.LOG_ID = vlb.LOG_ID
--            LEFT OUTER JOIN V_LOG_PROCEDURES vlp ON orl.LOG_ID = vlp.LOG_ID 
--                AND vlp.WOUND_CLASS_NM IS NOT NULL
            LEFT OUTER JOIN 
                (
                SELECT
                    LOG_ID
                    , WOUND_CLASS_NM
                    , PANEL_SERVICE_C
                FROM
                    (
                    SELECT
                        vlp.LOG_ID
                        , vlp.WOUND_CLASS_C
                        , vlp.WOUND_CLASS_NM
                        , vlp.PANEL_SERVICE_C
                        , RANK () OVER (PARTITION BY vlp.LOG_ID ORDER BY vlp.WOUND_CLASS_C DESC) AS Rank
                    FROM V_LOG_PROCEDURES vlp
                    WHERE 
                         vlp.WOUND_CLASS_C IS NOT NULL
                    ORDER BY vlp.WOUND_CLASS_C DESC
                    )
                WHERE Rank = 1
                ) vlp ON orl.LOG_ID = vlp.LOG_ID
            LEFT OUTER JOIN OR_LOG_CASE_TIMES olc ON orl.LOG_ID = olc.LOG_ID
            LEFT OUTER JOIN CLARITY_EAP eap ON pbt.PROC_ID = eap.PROC_ID
            LEFT OUTER JOIN ZC_OR_SERVICE zc_os ON orl.SERVICE_C = zc_os.SERVICE_C
            LEFT OUTER JOIN CLARITY_SER ser ON vlb.PRIMARY_PHYSICIAN_ID = ser.PROV_ID
            LEFT OUTER JOIN CLARITY_LOC loc ON orl.LOC_ID = loc.LOC_ID
            LEFT OUTER JOIN CLARITY_LOC loc2 ON loc.HOSP_PARENT_LOC_ID = loc2.LOC_ID
            LEFT OUTER JOIN BILL_AREA bil ON pbt.BILL_AREA_ID = bil.BILL_AREA_ID
        WHERE
            FLOOR((orl.SURGERY_DATE - pat.BIRTH_DATE) / 365.25) >= 18
--            AND orl.SURGERY_DATE >= EPIC_UTIL.EFN_DIN('{?StartDate}')
--            AND orl.SURGERY_DATE <= EPIC_UTIL.EFN_DIN('{?EndDate}')
--            AND pbt.SERVICE_DATE >= EPIC_UTIL.EFN_DIN('{?StartDate}')
--            AND pbt.SERVICE_DATE <= EPIC_UTIL.EFN_DIN('{?EndDate}')
--            AND orl.SURGERY_DATE >= '01-Nov-2019'
            AND orl.SURGERY_DATE >= '01-Sep-2020'
            AND orl.SURGERY_DATE <= '30-Sep-2020'
--            AND pat.PAT_MRN_ID IN (1190599, 4801436, 1116026, 2244184, 4759201, 4753458, 1190599, 4797358, 4766995, 4756343, 4760643, 4201825)
--            AND pat.PAT_MRN_ID = '1447660'
--            AND pat.PAT_ID = 'Z3070495'
--            AND pat.PAT_MRN_ID IN ('4797462', '3658415')
--            AND pbt.SERVICE_DATE >= '01-Nov-2019'
            AND pbt.SERVICE_DATE >= '01-Sep-2020'
            AND pbt.SERVICE_DATE <= '30-Sep-2020'
            AND pbt.VOID_DATE IS NULL
            AND pbt.CPT_CODE IN ('43101',	'43107',	'43108',	'43112',	'43113',	'43116',	'43117',	'43118',	'43121',	'43122',	'43123'
                ,	'43124',	'43130',	'43135',	'43300',	'43305',	'43310',	'43312',	'43314',	'43320',	'43340',	'43341',	'43351',	'43352'
                ,	'43360',	'43361',	'43400',	'43401',	'43405',	'43410',	'43415',	'43420',	'43425',	'43496',	'43500',	'43501'
                ,	'43502',	'43510',	'43605',	'43610',	'43611',	'43620',	'43621',	'43622',	'43631',	'43632',	'43633',	'43634',	'43647'
                ,	'43648',	'43810',	'43820',	'43825',	'43830',	'43832',	'43840',	'43842',	'43843',	'43845',	'43846',	'43847',	'43848'
                ,	'43850',	'43855',	'43860',	'43865',	'43870',	'43880',	'43881',	'43882',	'43886',	'43887',	'43888',	'44010'
                ,	'44020',	'44021',	'44025',	'44110',	'44111',	'44120',	'44125',	'44130',	'44140',	'44141',	'44143',	'44144',	'44145'
                ,	'44146',	'44147',	'44150',	'44151',	'44155',	'44156',	'44157',	'44158',	'44160',	'44186',	'44187',	'44188',	'44202'
                ,	'44203',	'44204',	'44205',	'44206',	'44207',	'44208',	'44210',	'44211',	'44212',	'44227',	'44310',	'44312'
                ,	'44313',	'44314',	'44316',	'44320',	'44322',	'44340',	'44345',	'44346',	'44602',	'44603',	'44604',	'44605',	'44615'
                ,	'44620',	'44625',	'44626',	'44640',	'44650',	'44660',	'44661',	'44800',	'44900',	'44950',	'44960',	'44970'
                ,	'44979',	'45110',	'45111',	'45112',	'45113',	'45114',	'45116',	'45119',	'45120',	'45121',	'45123',	'45126',	'45130'
                ,	'45135',	'45136',	'45150',	'45160',	'45395',	'45397',	'45402',	'45540',	'45541',	'45550',	'45562',	'45563'
                ,	'45800',	'45805',	'45820',	'45825',	'47100',	'47120',	'47122',	'47125',	'47130',	'47300',	'47350',	'47360',	'47361'
                ,	'47362',	'47370',	'47371',	'47380',	'47381',	'47399',	'47400',	'47420',	'47425',	'47460',	'47480',	'47562'
                ,	'47563',	'47564',	'47570',	'47600',	'47605',	'47610',	'47612',	'47620',	'47711',	'47712',	'47715',	'47720'
                ,	'47721',	'47740',	'47741',	'47760',	'47765',	'47780',	'47785',	'47800',	'47801',	'47802',	'47900',	'48000'
                ,	'48001',	'48020',	'48100',	'48105',	'48120',	'48140',	'48145',	'48146',	'48148',	'48150',	'48152',	'48153',	'48154'
                ,	'48155',	'48500',	'48510',	'48520',	'48540',	'48545',	'48547',	'48548'
                ,   '43644',     '43645',     '43775',     '43842',    '43843',     '43845',     '43846',    '43847',    '43848',     '43850',     '43855', '43659', '45400') 
            AND pbt.BILL_AREA_ID IN (107, 92, 100, 280, 102, 109, 111, 112, 113)  --  Limit to charges by General Surgery surgeons
            AND olc.TRACKING_EVENT_C IN ('80','90')  --  80 = First Incision, 90 = Procedure Closing
            AND (orl.SERVICE_C = '110'
                OR vlp.PANEL_SERVICE_C = '110')
--            Removing Wound Class filter per Gina McRae 10/22/19
--            AND vlp.WOUND_CLASS_C = 20
        GROUP BY
            orl.LOG_ID
            , pat.PAT_ID
            , pat.PAT_MRN_ID
            , orl.SURGERY_DATE
            , atm.SURGICAL_LOG_ID
            , enc.PAT_ENC_CSN_ID
            , enc.INPATIENT_DATA_ID
            , pat.PAT_NAME
            , FLOOR((orl.SURGERY_DATE - pat.BIRTH_DATE) / 365.25)
            , vlb.PRIMARY_PHYSICIAN_NM
            , bil.RECORD_NAME
            , loc2.LOC_NAME
            , zc_os.NAME
            , orl.CASE_CLASS_C
            , zc_cc.NAME
            , pbt.BILL_AREA_ID
            , bil.RECORD_NAME
            , pbt.CPT_CODE
            , eap.PROC_NAME
            , vlp.WOUND_CLASS_NM
            , olc.TRACKING_EVENT_C
            , olc.TRACKING_TIME_IN
    )
)

PIVOT

  (
               MAX(TRACKING_TIME_IN)
                                FOR TRACKING_EVENT_C IN ('80' AS PROCSTART, '90' AS PROCEND)
  ) 
  
    WHERE rank = 1
    ORDER BY PROCSTART
)

--
-- This captures the first tracking time and the last tracking time during a case.
--

, OR_TIMES
AS
(
SELECT
    olc.LOG_ID
    , MIN(olc.TRACKING_TIME_IN) "First OR Time"
    , MAX(olc.TRACKING_TIME_IN) "Last OR Time"
--    , olc.TRACKING_EVENT_C
--    , olc.TRACKING_TIME_IN
FROM OR_LOG_CASE_TIMES olc
    INNER JOIN PAT_POP pp ON olc.LOG_ID = pp.LOG_ID
GROUP BY
    olc.LOG_ID
)

--
-- Was an order put in for Abdominal Bundle?
--


, ABDOMINAL_ORDER
AS
(
SELECT *
FROM
    (
    SELECT
        op.PAT_ID 
        , TO_CHAR(op.ORDERING_DATE,'MM/DD/YYYY') "Ordering Date"
        , pp.SURGERY_DATE
        , RANK() OVER ( PARTITION BY op.PAT_ID ORDER BY op.PAT_ID,op.ORDERING_DATE DESC,RowNum) rank
    FROM ORDER_PROC op
        INNER JOIN PAT_POP pp ON op.PAT_ID = pp.PAT_ID
        INNER JOIN CLARITY_EAP eap ON op.PROC_ID = eap.PROC_ID
    WHERE
        eap.PROC_CODE = 'NUR2290'
        AND op.ORDERING_DATE >= pp.SURGERY_DATE - 90
        AND op.ORDERING_DATE <= pp.SURGERY_DATE
    )
    WHERE rank = 1
)

--
-- Was A1C test performed within 30 days of surgery?
--
, A1C_LAB
AS
(
SELECT *
FROM
    ( 
    SELECT
        op.PAT_ID 
        , res.ORD_VALUE
        , res.RESULT_DATE
        , RANK() OVER ( PARTITION BY op.PAT_ID ORDER BY op.PAT_ID,res.RESULT_TIME DESC,RowNum) rank
    FROM CLARITY_COMPONENT cc
        INNER JOIN ORDER_RESULTS res ON res.COMPONENT_ID = cc.COMPONENT_ID
        INNER JOIN ORDER_PROC op ON res.ORDER_PROC_ID = op.ORDER_PROC_ID
        INNER JOIN PAT_POP pp ON op.PAT_ID = pp.PAT_ID
    WHERE
        cc.NAME LIKE '%A1C%'
        AND TRUNC(MONTHS_BETWEEN(pp.SURGERY_DATE, res.RESULT_DATE)) <=1
        AND TRUNC(MONTHS_BETWEEN(pp.SURGERY_DATE, res.RESULT_DATE)) >= 0
        AND res.RESULT_DATE >= pp.SURGERY_DATE - 30
        AND res.RESULT_DATE <= pp.SURGERY_DATE
    )
    WHERE rank = 1
)

--
-- Was SA/MRSA testing performed within 3 months of surgery or has the pt ever tested positive?
--
, MRSA_LAB
AS
(
SELECT *
FROM
    ( SELECT
        op.PAT_ID 
        , pp.PAT_MRN_ID
        , res.ORD_VALUE
        , cc.COMPONENT_ID
        , res.RESULT_DATE
        , RANK() OVER ( PARTITION BY op.PAT_ID ORDER BY op.PAT_ID,res.RESULT_TIME DESC,RowNum) rank
    FROM CLARITY_COMPONENT cc
        INNER JOIN ORDER_RESULTS res ON res.COMPONENT_ID = cc.COMPONENT_ID
        INNER JOIN ORDER_PROC op ON res.ORDER_PROC_ID = op.ORDER_PROC_ID
        INNER JOIN PAT_POP pp ON op.PAT_ID = pp.PAT_ID
    WHERE
        cc.COMPONENT_ID IN ('3152', '1629', '1230292346', '1230291587', '1510831')
        AND ((TRUNC(MONTHS_BETWEEN(pp.SURGERY_DATE, res.RESULT_DATE)) <= 3
            AND TRUNC(MONTHS_BETWEEN(pp.SURGERY_DATE, res.RESULT_DATE)) >= 0
                    AND res.RESULT_DATE >= pp.SURGERY_DATE - 90
                    AND res.RESULT_DATE <= pp.SURGERY_DATE) -- Tested within 3 months of surgery date
            OR (res.ORD_VALUE = 'POSITIVE MRSA')) -- Tested positive at anytime
    )
    WHERE rank = 1
)

--
-- Was a PAC appt completed prior to surgery?
--
, PAC_VISIT
AS
(
SELECT *
FROM
    (
    SELECT
        orl.LOG_ID
        , enc2.CONTACT_DATE
    FROM OR_CASE orc
        INNER JOIN PAT_OR_ADM_LINK lnk ON orc.LOG_ID = lnk.LOG_ID
        INNER JOIN PAT_ENC enc ON lnk.OR_LINK_CSN = enc.PAT_ENC_CSN_ID
        INNER JOIN PAT_ENC enc2 ON enc.HSP_ACCOUNT_ID = enc2.HSP_ACCOUNT_ID
            AND enc2.DEPARTMENT_ID IN ('1000106010 ','1008301044','1012301018', '1024301059')
            AND enc2.APPT_STATUS_C <> 3 --Not a cancelled visit ---PAC visit
        INNER JOIN OR_LOG orl ON orc.LOG_ID = orl.LOG_ID
            AND orl.OR_TIME_EVTS_ENT_C = 2  -- surgery completed
        INNER JOIN PAT_POP pp ON pp.LOG_ID = orl.LOG_ID
    WHERE
        enc2.APPT_TIME IS NOT NULL 
        AND orc.RECORD_CREATE_DATE <= enc2.APPT_TIME
        AND pp.LOG_ID = orl.LOG_ID
    ORDER BY
        enc2.CONTACT_DATE DESC
    )
--WHERE ROWNUM = 1
)
             
--
-- Was a PAC appt completed prior to surgery (PAC appointment not linked to the surgery)?
--
, UNLINKED_PAC_VISIT
AS
(
SELECT *
FROM
    (SELECT DISTINCT
        pp.LOG_ID
        , enc.CONTACT_DATE
    FROM PAT_POP pp
        INNER JOIN PAT_ENC enc ON pp.PAT_ID = enc.PAT_ID
            AND enc.DEPARTMENT_ID IN ('1000106010 ','1008301044','1012301018', '1024301059')
            AND enc.APPT_STATUS_C <> 3 --Not a cancelled visit ---PAC visit
    WHERE
        enc.APPT_TIME IS NOT NULL 
        AND enc.CONTACT_DATE >= pp.SURGERY_DATE - 60
        AND enc.CONTACT_DATE <= pp.SURGERY_DATE
        AND NOT EXISTS
            (SELECT
                pacv.LOG_ID
            FROM PAC_VISIT pacv
            WHERE pp.LOG_ID = pacv.LOG_ID        
            )
    ORDER BY
        enc.CONTACT_DATE DESC
    )
--WHERE ROWNUM = 1
)

--
-- Responses to the questions in the Abdominal Bundle flowsheet
--
, PRE_OP_MEAS
AS
(
SELECT *
FROM
    (SELECT *
    FROM
            (
            SELECT
                meas.FSD_ID "Flowsheet Record"
                , rec.INPATIENT_DATA_ID
                , meas.FLO_MEAS_ID "Measure ID"
                , meas.MEAS_VALUE "Measure Value"
                , lnk.LOG_ID
--                , RANK() OVER ( PARTITION BY rec.INPATIENT_DATA_ID, lnk.LOG_ID, meas.FLO_MEAS_ID 
                , RANK() OVER ( PARTITION BY lnk.LOG_ID, meas.FLO_MEAS_ID 
                    ORDER BY meas.RECORDED_TIME DESC, RowNum) rank
            FROM IP_FLWSHT_REC rec
                INNER JOIN IP_FLWSHT_MEAS meas ON rec.FSD_ID = meas.FSD_ID
                INNER JOIN IP_FLO_GP_DATA dat ON meas.FLO_MEAS_ID = dat.FLO_MEAS_ID
                INNER JOIN IP_DATA_STORE sto ON rec.INPATIENT_DATA_ID = sto.INPATIENT_DATA_ID
                INNER JOIN PAT_OR_ADM_LINK lnk ON sto.EPT_CSN = lnk.OR_LINK_CSN
                INNER JOIN PAT_POP pp ON lnk.LOG_ID = pp.LOG_ID
                INNER JOIN OR_TIMES ort ON pp.LOG_ID = ort.LOG_ID 
            WHERE 
                meas.FLO_MEAS_ID IN ('10834', '6209', '6015', '6017', '11371', '6220', '10829', '10379', '10380', '10381', '10830', '6222')
                AND meas.RECORDED_TIME >= ort."First OR Time"
                AND meas.RECORDED_TIME <= ort."Last OR Time"
            ORDER BY
                RECORD_DATE DESC
            )
    WHERE rank = 1
)

    PIVOT 
          (LISTAGG ("Measure Value") WITHIN GROUP (ORDER BY "Measure ID") FOR  "Measure ID" IN 
                            ('10834' AS "Documented Pt CHG Bath"
                            ,'6209' AS "CHG Wipes Used"
                            , '6015' AS "Bowel Prep Complete"
                            , '6017' AS "Pre-Op Antibiotic"
                            ,'11371' AS "Pre-Warmed Room"
                            ,'6220'   AS "Skin Prep by Appropriate Staff"
                            ,'10829' AS "OR Traffic Sign Used"
                            ,'10379' AS "Wound Protector Used"
                            ,'10380' AS "Gown/Glove Changed"
                            ,'10381' AS "Closing Pan Used"
                            ,'6222'   AS "No Flash Instruments"
                            ,'10830' AS "Silverlon Used")
          )
)

--
-- Dates and times of Last Liquid and Last Solids
--

, LAST_LIQ_SOLID
AS
(
SELECT *
FROM
    (SELECT *
    FROM
            (SELECT
                meas.FSD_ID "Flowsheet Record"
                , rec.INPATIENT_DATA_ID
                , meas.FLO_MEAS_ID "Measure ID"
                , meas.MEAS_VALUE "Measure Value"
                , lnk.LOG_ID
--                , RANK() OVER ( PARTITION BY rec.INPATIENT_DATA_ID, lnk.LOG_ID, meas.FLO_MEAS_ID 
                , RANK() OVER ( PARTITION BY lnk.LOG_ID, meas.FLO_MEAS_ID 
                    ORDER BY meas.RECORDED_TIME DESC, RowNum) rank
            FROM IP_FLWSHT_REC rec
                INNER JOIN IP_FLWSHT_MEAS meas ON rec.FSD_ID = meas.FSD_ID
                INNER JOIN IP_FLO_GP_DATA dat ON meas.FLO_MEAS_ID = dat.FLO_MEAS_ID
                INNER JOIN IP_DATA_STORE sto ON rec.INPATIENT_DATA_ID = sto.INPATIENT_DATA_ID
                INNER JOIN PAT_OR_ADM_LINK lnk ON sto.EPT_CSN = lnk.OR_LINK_CSN
                INNER JOIN PAT_POP pp ON lnk.LOG_ID = pp.LOG_ID
                INNER JOIN OR_TIMES ort ON pp.LOG_ID = ort.LOG_ID 
            WHERE 
                meas.FLO_MEAS_ID IN ('1020100004', '1217', '1020100005', '1630100000')
                AND meas.RECORDED_TIME >= ort."First OR Time"
                AND meas.RECORDED_TIME <= ort."Last OR Time"
            ORDER BY
                RECORD_DATE DESC)
    WHERE rank = 1
)

    PIVOT 
          (LISTAGG ("Measure Value") WITHIN GROUP (ORDER BY "Measure ID") FOR  "Measure ID" IN 
                            ('1020100004' AS "Date of Last Liquid"
                            , '1217' AS "Time of Last Liquid"
                            , '1020100005' AS "Date of Last Solid"
                            , '1630100000' AS "Time of Last Solid")
          )
WHERE 
    "Date of Last Liquid" IS NOT NULL
    OR "Date of Last Solid" IS NOT NULL
)


--
-- Has the pt's temp remained above 36C from Case/Incision Start to Procedure Finish?
-- Has the pt's FiO2 remained above 60% from Case/Incision Start to Procedure Finish?
--


, TEMP_O2_DATA AS
(
SELECT *
FROM
    (SELECT *
    FROM
        (
        SELECT
                pp.PAT_ID
                , pp.PAT_MRN_ID
                , pp.LOG_ID
                , meas.RECORDED_TIME
                , TO_CHAR(meas.RECORDED_TIME, 'MI') "Minutes"
                , meas.FLO_MEAS_ID "Measure ID"
                , dat.FLO_MEAS_NAME "Measure Name"
                , meas.MEAS_VALUE "Measure Value"
                , olc.TRACKING_EVENT_C
                , olc.TRACKING_TIME_IN
            FROM F_AN_RECORD_SUMMARY fans
                INNER JOIN PAT_ENC enc ON fans.AN_52_ENC_CSN_ID = enc.PAT_ENC_CSN_ID
                INNER JOIN IP_FLWSHT_REC rec ON enc.INPATIENT_DATA_ID = rec.INPATIENT_DATA_ID
                INNER JOIN IP_FLWSHT_MEAS meas ON rec.FSD_ID = meas.FSD_ID
                INNER JOIN IP_FLO_GP_DATA dat ON meas.FLO_MEAS_ID = dat.FLO_MEAS_ID
                INNER JOIN AN_HSB_LINK_INFO ahli ON fans.AN_EPISODE_ID = ahli.SUMMARY_BLOCK_ID
                INNER JOIN PAT_POP pp ON ahli.AN_BILLING_CSN_ID = pp.PAT_ENC_CSN_ID
                INNER JOIN OR_LOG_CASE_TIMES olc ON pp.LOG_ID = olc.LOG_ID
            WHERE 
                meas.FLO_MEAS_ID IN ('9293', '8266')
                AND pp.SURGERY_DATE = TRUNC(meas.RECORDED_TIME)
                AND olc.TRACKING_EVENT_C IN ('80','90') -- Case/Incision Start Time and Procedure Closing Time
            ORDER BY meas.FLO_MEAS_ID
                , meas.RECORDED_TIME
    )
    pivot
    
      (
                   MAX(TRACKING_TIME_IN)
                                    FOR TRACKING_EVENT_C IN ('80' AS ProcStart,'90' AS ProcEnd)
      ) 
    )
WHERE "Minutes" IN ('00', '15', '30', '45')
)

, TEMP_DATA
AS
(
--SELECT *
--FROM
--    (SELECT *
--    FROM
--        (
SELECT DISTINCT
    t2.PAT_ID
    , t2.PAT_MRN_ID
    , t2.LOG_ID
    , t2.ProcStart
    , t2.ProcEnd
--    , t2.RECORDED_TIME
    , t2."Minutes"
    , t2."Measure ID"
--    , t2."Measure Value"
    , CASE
        WHEN t2."Measure ID" = '8266' 
            AND t2."Measure Value" < 36 
            AND t2.RECORDED_TIME BETWEEN t2.ProcStart AND t2.ProcEnd THEN 'No'
        WHEN t2."Measure ID" = '8266' 
            AND t2."Measure Value" >= 36 
            AND t2.RECORDED_TIME BETWEEN t2.ProcStart AND t2.ProcEnd THEN 'Yes'
    END AS "Temp >= 36"
FROM TEMP_O2_DATA t2  
WHERE 
    t2."Measure ID" = '8266' 
    AND (CASE
        WHEN t2."Measure ID" = '8266' 
            AND t2."Measure Value" < 36 
            AND t2.RECORDED_TIME BETWEEN t2.ProcStart AND t2.ProcEnd THEN 'No'
        WHEN t2."Measure ID" = '8266' 
            AND t2."Measure Value" >= 36 
            AND t2.RECORDED_TIME BETWEEN t2.ProcStart AND t2.ProcEnd THEN 'Yes'
    END) = 'No'
ORDER BY t2."Measure ID"
--        )
    
--    pivot
--    
--      (
--                   MAX("Normal Level?")
--                                    FOR "Measure ID" IN ('8266' AS "Temp >= 36",'9293' AS "FiO2 >= 60")
--      ) 
--    )
)

, O2_DATA 
AS
(
--SELECT *
--FROM
--    (SELECT *
--    FROM
--        (
SELECT DISTINCT
    t2.PAT_ID
    , t2.PAT_MRN_ID
    , t2.LOG_ID
    , t2.ProcStart
    , t2.ProcEnd
--    , t2.RECORDED_TIME
    , t2."Minutes"
    , t2."Measure ID"
--    , t2."Measure Value"
    , CASE
        WHEN t2."Measure ID" = '9293' 
            AND t2."Measure Value" < 60 
            AND t2.RECORDED_TIME BETWEEN t2.ProcStart AND t2.ProcEnd THEN 'No'
        WHEN t2."Measure ID" = '9293' 
            AND t2."Measure Value" >= 60 
            AND t2.RECORDED_TIME BETWEEN t2.ProcStart AND t2.ProcEnd THEN 'Yes'
    END AS "FiO2 >= 60"
FROM TEMP_O2_DATA t2  
WHERE
    t2."Measure ID" = '9293' 
    AND (CASE
        WHEN t2."Measure ID" = '9293' 
            AND t2."Measure Value" < 60 
            AND t2.RECORDED_TIME BETWEEN t2.ProcStart AND t2.ProcEnd THEN 'No'
        WHEN t2."Measure ID" = '9293' 
            AND t2."Measure Value" >= 60 
            AND t2.RECORDED_TIME BETWEEN t2.ProcStart AND t2.ProcEnd THEN 'Yes'
    END) = 'No'
ORDER BY t2."Measure ID"
--        )
    
--    pivot
--    
--      (
--                   MAX("Normal Level?")
--                                    FOR "Measure ID" IN ('8266' AS "Temp >= 36",'9293' AS "FiO2 >= 60")
--      ) 
--    )
)

--
-- Has the pt been diagnosed with Diabetes?
--
, DIABETES
AS
(    
SELECT DISTINCT
    pl.PAT_ID
    , pp.SURGERY_DATE
    , pp.LOG_ID
    , pl.PROBLEM_STATUS_C
    , 'Yes' "Diabetes Diagnosis?"
FROM PROBLEM_LIST pl
INNER JOIN PAT_POP pp ON pl.PAT_ID = pp.PAT_ID
INNER JOIN GROUPER_DX_RECORDS gdx ON gdx.CMPL_DX_RECS_ID = pl.DX_ID
WHERE 
    pl.PROBLEM_STATUS_C = 1
    AND gdx.GROUPER_ID = 210000
)

--
-- If antibiotics were given during surgery and a second dose was required, did the second dose occur within the required time?
--

, ANTIBIOTICS_DATA 
AS
(
SELECT DISTINCT
    PAT_ID
    , PAT_MRN_ID
    , LOG_ID
    , SURGERY_DATE
    , "Abx Given Prior to Case Start"
    , "Re-doseGiven"
    , "ROW_NUM"
    , "DoseNumber"
    , "NextDoseNumber"
FROM
    (
    SELECT DISTINCT
        PAT_ID
        , PAT_MRN_ID
        , LOG_ID
        , SURGERY_DATE
        , ORDER_MED_ID
        , "Abx Given Prior to Case Start"
        , "Re-doseGiven"
        , ROW_NUMBER() OVER (PARTITION BY LOG_ID ORDER BY ORDER_MED_ID, "DoseNumber" ASC, "Abx Given Prior to Case Start" DESC
            , "Re-doseGiven" DESC, "NextDoseNumber" DESC ) "ROW_NUM"
        , "DoseNumber"
        , "NextDoseNumber"
    FROM
            (
            SELECT
                PAT_ID
                , PAT_MRN_ID
                , LOG_ID
                ,  "ENC CSN"
                , SURGERY_DATE
                , PROCSTART
                , PROCEND
                , ORDER_MED_ID
                , TAKEN_TIME
                , "DoseNumber"
                , CASE
                    WHEN "DoseNumber" = 1 AND TAKEN_TIME <= PROCSTART
                        THEN 'Yes'
                    WHEN "DoseNumber" = 1 AND TAKEN_TIME > PROCSTART
                        THEN 'No'
        --            ELSE 'Not 1st Dose'
                    END AS "Abx Given Prior to Case Start"
                , "NextDoseNumber"        
                , "NextDoseTakenTime"
                , "MinutesBetweenDoses"
                , "RedoseTimes"
                ,  "AnesthTime"
                , NAME
                , FREQ_NAME
                , CASE
                    -- Next dose Not needed
                    WHEN ("AnesthTime" < "RedoseTimes")
                        THEN 'N/A'
                    -- Next dose on time
                    WHEN "NextDoseNumber" IS NOT NULL 
                        AND "MinutesBetweenDoses" IS NOT NULL 
                        AND ("DoseNumber" + 1 = "NextDoseNumber") 
                        AND ("AnesthTime" >= "RedoseTimes")
                        AND ("RedoseTimes" >= "MinutesBetweenDoses")
                        THEN 'Yes'
                    -- Missed next dose
                    WHEN "NextDoseNumber" IS NULL 
                        AND "MinutesBetweenDoses" IS NULL 
                        AND ("AnesthTime" >= "RedoseTimes")
                        THEN 'No'
                    -- Next dose late
                    WHEN "NextDoseNumber" IS NOT NULL 
                        AND "MinutesBetweenDoses" IS NOT NULL 
                        AND ("DoseNumber" + 1 = "NextDoseNumber") 
                        AND ("AnesthTime" > "RedoseTimes")
                        AND ("RedoseTimes" < "MinutesBetweenDoses")
                        THEN 'No'
                    ELSE 'ND'
                    END AS "Re-doseGiven"
            FROM
                (SELECT
                    PAT_ID
                    , PAT_MRN_ID
                    , LOG_ID
                    ,  "ENC CSN"
                    , SURGERY_DATE
                    , PROCSTART
                    , PROCEND
                    , ORDER_MED_ID
                    , TAKEN_TIME
                    , "DoseNumber"
                    , "NextDoseNumber"
                    , "NextDoseTakenTime"
                    , ROUND((("NextDoseTakenTime" - TAKEN_TIME) * 24 * 60), 2) AS "MinutesBetweenDoses"
                    , "RedoseTimes"
                    , "AnesthTime"
                    , NAME
                    , FREQ_NAME
                FROM
                    (
                    SELECT
                        PAT_ID
                        , PAT_MRN_ID
                        , LOG_ID
                        ,  "ENC CSN"
                        , SURGERY_DATE
                        , PROCSTART
                        , PROCEND
                        , ORDER_MED_ID
                        , TAKEN_TIME
                        , "DoseNumber"
                        , LEAD ("DoseNumber",1) OVER (PARTITION BY PROCSTART, MEDICATION_ID 
                            ORDER BY "DoseNumber") AS "NextDoseNumber"
                        , LEAD (Taken_Time,1) OVER (PARTITION BY PROCSTART, MEDICATION_ID 
                            ORDER BY "DoseNumber") AS "NextDoseTakenTime"
                        , "RedoseTimes"
                        , "AnesthTime"
                        , NAME
                        , FREQ_NAME
                    FROM
                        (
                        SELECT DISTINCT
                            pp.PAT_ID
                            , pp.PAT_MRN_ID
                            , pp.LOG_ID
                            , pp.PAT_ENC_CSN_ID "ENC CSN"
                            , pp.SURGERY_DATE
                            , pp.PROCSTART
                            , pp.PROCEND
                            , om.ORDER_MED_ID
                            , mar.TAKEN_TIME
        --                    , DENSE_RANK() OVER ( PARTITION BY pp.PAT_MRN_ID, pp.PROCSTART, cm.NAME
                            , DENSE_RANK() OVER ( PARTITION BY pp.LOG_ID, pp.PROCSTART, cm.NAME
                                ORDER BY mar.TAKEN_TIME) "DoseNumber"
                            , om.MEDICATION_ID
                            , cm.NAME
                            , ipf.FREQ_NAME
                            , CASE
                                WHEN UPPER(cm.NAME) LIKE '%AMPICILLIN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CEFAZOLIN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CEFEPIME%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CEFOTETAN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CEFOXITIN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CEFTAZIDIME%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CEFUROXIME%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CIPROFLOXACIN%' THEN 330
                                WHEN UPPER(cm.NAME) LIKE '%CLINDAMYCIN%' THEN 330
                                WHEN UPPER(cm.NAME) LIKE '%DORIPENEM%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%DOXYCYCLINE%' THEN 720
                                WHEN UPPER(cm.NAME) LIKE '%GENTAMICIN%' THEN 330
                                WHEN UPPER(cm.NAME) LIKE '%IMIPENEM%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%MEROPENEM%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%METRONIDAZOLE%' THEN 450
                                WHEN UPPER(cm.NAME) LIKE '%NAFCILLIN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%OXACILLIN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%PENICILLIN G%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%PIPERACILLIN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%VANCOMYCIN%' THEN 450
                                END AS "RedoseTimes"
                            , ROUND(((pp.PROCEND - PROCSTART) * 24 * 60), 2) AS "AnesthTime"
                        FROM PAT_POP pp
                            INNER JOIN ORDER_MED om ON pp.PAT_ID = om.PAT_ID
                            INNER JOIN MAR_ADMIN_INFO mar ON om.ORDER_MED_ID = mar.ORDER_MED_ID
                            INNER JOIN CLARITY_MEDICATION cm ON om.MEDICATION_ID = cm.MEDICATION_ID
                            LEFT OUTER JOIN IP_FREQUENCY ipf ON om.HV_DISCR_FREQ_ID = ipf.FREQ_ID
                        WHERE 
                            (UPPER(cm.NAME) LIKE '%CEFOXITIN%'
                            OR UPPER(cm.NAME) LIKE  '%AMPICILLIN%'
                            OR UPPER(cm.NAME) LIKE  '%CEFAZOLIN%'
                            OR UPPER(cm.NAME) LIKE  '%CEFEPIME%'
                            OR UPPER(cm.NAME) LIKE  '%CEFOTETAN%'
                            OR UPPER(cm.NAME) LIKE  '%CEFOXITIN%'
                            OR UPPER(cm.NAME) LIKE  '%CEFTAZIDIME%'
                            OR UPPER(cm.NAME) LIKE  '%CEFTRIAXONE%'
                            OR UPPER(cm.NAME) LIKE  '%CEFUROXIME%'
                            OR UPPER(cm.NAME) LIKE  '%CIPROFLOXACIN%'
                            OR UPPER(cm.NAME) LIKE  '%CLINDAMYCIN%'
                            OR UPPER(cm.NAME) LIKE  '%DORIPENEM%'
                            OR UPPER(cm.NAME) LIKE  '%DOXYCYCLINE%'
                            OR UPPER(cm.NAME) LIKE  '%GENTAMICIN%'
                            OR UPPER(cm.NAME) LIKE  '%IMIPENEM %'
                            OR UPPER(cm.NAME) LIKE  '%MEROPENEM%'
                            OR UPPER(cm.NAME) LIKE  '%METRONIDAZOLE%'
                            OR UPPER(cm.NAME) LIKE  '%MOXIFLOXACIN%'
                            OR UPPER(cm.NAME) LIKE  '%NAFCILLIN%'
                            OR UPPER(cm.NAME) LIKE  '%OXACILLIN%'
                            OR UPPER(cm.NAME) LIKE  '%PENICILLIN G%'
                            OR UPPER(cm.NAME) LIKE  '%PIPERACILLIN%'
                            OR UPPER(cm.NAME) LIKE  '%FLUCONAZOLE%'
                            OR UPPER(cm.NAME) LIKE  '%VANCOMYCIN%')
        -- 60 minutes before Procedure Start Time
                            AND mar.TAKEN_TIME >= (pp.PROCSTART - (60/(24*60)))
                            AND mar.TAKEN_TIME <= pp.PROCEND
                        ORDER BY
                            pp.PAT_ID
                            , pp.PROCSTART
                            , cm.NAME
                            , mar.TAKEN_TIME
                        )                                
                    )            
                )        
    --        ORDER BY
    --            "DoseNumber" ASC
    --            , "Abx Given Prior to Case Start" DESC
    --            , "Re-doseGiven" DESC
    --            , "NextDoseNumber"   
            )
    )
WHERE ROW_NUM = 1
)

, ABX_DATA_REDOSE
AS
(
SELECT DISTINCT
    PAT_ID
    , PAT_MRN_ID
    , LOG_ID
    , SURGERY_DATE
    , "Abx Given Prior to Case Start"
    , "Re-doseGiven"
    , "ROW_NUM"
    , "DoseNumber"
    , "NextDoseNumber"
FROM
    (
    SELECT DISTINCT
        PAT_ID
        , PAT_MRN_ID
        , LOG_ID
        , SURGERY_DATE
        , ORDER_MED_ID
        , "Abx Given Prior to Case Start"
        , "Re-doseGiven"
--        , ROW_NUMBER() OVER (PARTITION BY LOG_ID ORDER BY "DoseNumber" ASC, "Abx Given Prior to Case Start" DESC, "Re-doseGiven" DESC, "NextDoseNumber" DESC ) "ROW_NUM"
        , ROW_NUMBER() OVER (PARTITION BY LOG_ID ORDER BY ORDER_MED_ID, "Re-doseGiven" DESC ) "ROW_NUM"
        , "DoseNumber"
        , "NextDoseNumber"
    FROM
            (
            SELECT
                PAT_ID
                , PAT_MRN_ID
                , LOG_ID
                ,  "ENC CSN"
                , SURGERY_DATE
                , PROCSTART
                , PROCEND
                , ORDER_MED_ID
                , TAKEN_TIME
                , "DoseNumber"
                , CASE
                    WHEN "DoseNumber" = 1 AND TAKEN_TIME <= PROCSTART
                        THEN 'Yes'
                    WHEN "DoseNumber" = 1 AND TAKEN_TIME > PROCSTART
                        THEN 'No'
        --            ELSE 'Not 1st Dose'
                    END AS "Abx Given Prior to Case Start"
                , "NextDoseNumber"        
                , "NextDoseTakenTime"
                , "MinutesBetweenDoses"
                , "RedoseTimes"
                ,  "AnesthTime"
                , NAME
                , FREQ_NAME
                , CASE
                    -- Next dose Not needed
                    WHEN ("AnesthTime" < "RedoseTimes")
                        THEN 'N/A'
                    -- Next dose on time
                    WHEN "NextDoseNumber" IS NOT NULL 
                        AND "MinutesBetweenDoses" IS NOT NULL 
                        AND ("DoseNumber" + 1 = "NextDoseNumber") 
                        AND ("AnesthTime" >= "RedoseTimes")
                        AND ("RedoseTimes" >= "MinutesBetweenDoses")
                        THEN 'Yes'
                    -- Missed next dose
                    WHEN "NextDoseNumber" IS NULL 
                        AND "MinutesBetweenDoses" IS NULL 
                        AND ("AnesthTime" >= "RedoseTimes")
                        THEN 'No'
                    -- Next dose late
                    WHEN "NextDoseNumber" IS NOT NULL 
                        AND "MinutesBetweenDoses" IS NOT NULL 
                        AND ("DoseNumber" + 1 = "NextDoseNumber") 
                        AND ("AnesthTime" > "RedoseTimes")
                        AND ("RedoseTimes" < "MinutesBetweenDoses")
                        THEN 'No'
                    ELSE 'ND'
                    END AS "Re-doseGiven"
            FROM
                (
                SELECT
                    PAT_ID
                    , PAT_MRN_ID
                    , LOG_ID
                    ,  "ENC CSN"
                    , SURGERY_DATE
                    , PROCSTART
                    , PROCEND
                    , ORDER_MED_ID
                    , TAKEN_TIME
                    , "DoseNumber"
                    , "NextDoseNumber"
                    , "NextDoseTakenTime"
                    , ROUND((("NextDoseTakenTime" - TAKEN_TIME) * 24 * 60), 2) AS "MinutesBetweenDoses"
                    , "RedoseTimes"
                    , "AnesthTime"
                    , NAME
                    , FREQ_NAME
                FROM
                    (
                    SELECT
                        PAT_ID
                        , PAT_MRN_ID
                        , LOG_ID
                        ,  "ENC CSN"
                        , SURGERY_DATE
                        , PROCSTART
                        , PROCEND
                        , ORDER_MED_ID
                        , TAKEN_TIME
                        , "DoseNumber"
                        , LEAD ("DoseNumber",1) OVER (PARTITION BY PROCSTART, MEDICATION_ID 
                            ORDER BY "DoseNumber") AS "NextDoseNumber"
                        , LEAD (Taken_Time,1) OVER (PARTITION BY PROCSTART, MEDICATION_ID 
                            ORDER BY "DoseNumber") AS "NextDoseTakenTime"
                        , "RedoseTimes"
                        , "AnesthTime"
                        , NAME
                        , FREQ_NAME
                    FROM
                        (
                        SELECT DISTINCT
                            pp.PAT_ID
                            , pp.PAT_MRN_ID
                            , pp.LOG_ID
                            , pp.PAT_ENC_CSN_ID "ENC CSN"
                            , pp.SURGERY_DATE
                            , pp.PROCSTART
                            , pp.PROCEND
                            , om.ORDER_MED_ID
                            , mar.TAKEN_TIME
        --                    , DENSE_RANK() OVER ( PARTITION BY pp.PAT_MRN_ID, pp.PROCSTART, cm.NAME
                            , DENSE_RANK() OVER ( PARTITION BY pp.LOG_ID, pp.PROCSTART, cm.NAME
                                ORDER BY mar.TAKEN_TIME) "DoseNumber"
                            , om.MEDICATION_ID
                            , cm.NAME
                            , ipf.FREQ_NAME
                            , CASE
                                WHEN UPPER(cm.NAME) LIKE '%AMPICILLIN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CEFAZOLIN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CEFEPIME%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CEFOTETAN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CEFOXITIN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CEFTAZIDIME%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CEFUROXIME%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%CIPROFLOXACIN%' THEN 330
                                WHEN UPPER(cm.NAME) LIKE '%CLINDAMYCIN%' THEN 330
                                WHEN UPPER(cm.NAME) LIKE '%DORIPENEM%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%DOXYCYCLINE%' THEN 720
                                WHEN UPPER(cm.NAME) LIKE '%GENTAMICIN%' THEN 330
                                WHEN UPPER(cm.NAME) LIKE '%IMIPENEM%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%MEROPENEM%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%METRONIDAZOLE%' THEN 450
                                WHEN UPPER(cm.NAME) LIKE '%NAFCILLIN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%OXACILLIN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%PENICILLIN G%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%PIPERACILLIN%' THEN 210
                                WHEN UPPER(cm.NAME) LIKE '%VANCOMYCIN%' THEN 450
                                END AS "RedoseTimes"
                            , ROUND(((pp.PROCEND - PROCSTART) * 24 * 60), 2) AS "AnesthTime"
                        FROM PAT_POP pp
                            INNER JOIN ORDER_MED om ON pp.PAT_ID = om.PAT_ID
                            INNER JOIN MAR_ADMIN_INFO mar ON om.ORDER_MED_ID = mar.ORDER_MED_ID
                            INNER JOIN CLARITY_MEDICATION cm ON om.MEDICATION_ID = cm.MEDICATION_ID
                            LEFT OUTER JOIN IP_FREQUENCY ipf ON om.HV_DISCR_FREQ_ID = ipf.FREQ_ID
                        WHERE 
                            (UPPER(cm.NAME) LIKE '%CEFOXITIN%'
                            OR UPPER(cm.NAME) LIKE  '%AMPICILLIN%'
                            OR UPPER(cm.NAME) LIKE  '%CEFAZOLIN%'
                            OR UPPER(cm.NAME) LIKE  '%CEFEPIME%'
                            OR UPPER(cm.NAME) LIKE  '%CEFOTETAN%'
                            OR UPPER(cm.NAME) LIKE  '%CEFOXITIN%'
                            OR UPPER(cm.NAME) LIKE  '%CEFTAZIDIME%'
                            OR UPPER(cm.NAME) LIKE  '%CEFTRIAXONE%'
                            OR UPPER(cm.NAME) LIKE  '%CEFUROXIME%'
                            OR UPPER(cm.NAME) LIKE  '%CIPROFLOXACIN%'
                            OR UPPER(cm.NAME) LIKE  '%CLINDAMYCIN%'
                            OR UPPER(cm.NAME) LIKE  '%DORIPENEM%'
                            OR UPPER(cm.NAME) LIKE  '%DOXYCYCLINE%'
                            OR UPPER(cm.NAME) LIKE  '%GENTAMICIN%'
                            OR UPPER(cm.NAME) LIKE  '%IMIPENEM %'
                            OR UPPER(cm.NAME) LIKE  '%MEROPENEM%'
                            OR UPPER(cm.NAME) LIKE  '%METRONIDAZOLE%'
                            OR UPPER(cm.NAME) LIKE  '%MOXIFLOXACIN%'
                            OR UPPER(cm.NAME) LIKE  '%NAFCILLIN%'
                            OR UPPER(cm.NAME) LIKE  '%OXACILLIN%'
                            OR UPPER(cm.NAME) LIKE  '%PENICILLIN G%'
                            OR UPPER(cm.NAME) LIKE  '%PIPERACILLIN%'
                            OR UPPER(cm.NAME) LIKE  '%FLUCONAZOLE%'
                            OR UPPER(cm.NAME) LIKE  '%VANCOMYCIN%')
        -- 60 minutes before Procedure Start Time
                            AND mar.TAKEN_TIME >= (pp.PROCSTART - (60/(24*60)))
                            AND mar.TAKEN_TIME <= pp.PROCEND
                        ORDER BY
                            pp.PAT_ID
                            , pp.LOG_ID
--                            , pp.PROCSTART
                            , om.ORDER_MED_ID
--                            , cm.NAME
                            , mar.TAKEN_TIME
                        )
                    )
                )
    --        ORDER BY
    --            "DoseNumber" ASC
    --            , "Abx Given Prior to Case Start" DESC
    --            , "Re-doseGiven" DESC
    --            , "NextDoseNumber"   
            )
--    ORDER BY
--        PAT_ID
--        , LOG_ID
--        , ORDER_MED_ID
--        , TAKEN_TIME
    )
WHERE ROW_NUM = 1
)






SELECT DISTINCT
    pp."Surgery Date"
    , pp.LOG_ID
    , pp.PAT_ID
    , pp.PAT_MRN_ID
    , pp.PAT_NAME
    , pp."Age at Encounter"
    , pp."Location"
    , pp.PRIMARY_PHYSICIAN_NM
    , pp."Surgical Service"
    , pp.CASE_CLASS_C
    , pp."Case Class Name"
    , pp.CPT_CODE "CPT Code"
    , pp.PROC_NAME "Procedure Name"
    , CASE
            WHEN ao."Ordering Date" IS NULL THEN 'No'
            ELSE 'Yes'
        END AS "Abdominal Bundle Order Init'd"
    , CASE 
            WHEN dbt."Diabetes Diagnosis?" IS NULL THEN 'No'
            ELSE dbt."Diabetes Diagnosis?" 
        END AS "Diabetes Diagnosis?"
    , CASE 
--            WHEN a_l.ORD_VALUE IS NULL 
--                AND pp.CASE_CLASS_C IN (70, 80, 90)  -- Emergency Cases
--                THEN 'N/A'
            WHEN a_l.ORD_VALUE IS NULL 
                THEN 'No'
                ELSE 'Yes'
        END AS "HgbA1C Test"
    , CASE 
            WHEN m_l.ORD_VALUE IS NULL 
                AND pp.CASE_CLASS_C IN (70, 80, 90)  -- Emergency Cases
                THEN 'N/A'
            WHEN m_l.ORD_VALUE IS NULL 
                THEN 'No'
            WHEN m_l.ORD_VALUE IS NOT NULL 
                THEN 'Yes'
        END AS  "SA/MRSA Pre Op Screen"
    , CASE 
            WHEN m_l.RESULT_DATE IS NULL 
                AND pp.CASE_CLASS_C IN (70, 80, 90)  -- Emergency Cases
                THEN 'N/A'
            WHEN m_l.RESULT_DATE IS NULL 
                THEN 'No'
            WHEN m_l.RESULT_DATE IS NOT NULL 
                THEN TO_CHAR(m_l.RESULT_DATE, 'MM/DD/YYYY')
        END AS  "SA/MRSA Screen Date"
    , CASE 
            WHEN p_v.CONTACT_DATE IS NULL AND u_p_v.CONTACT_DATE IS NULL
                AND pp.CASE_CLASS_C IN (70, 80, 90)  -- Emergency Cases
                THEN 'N/A'
            WHEN p_v.CONTACT_DATE IS NULL AND u_p_v.CONTACT_DATE IS NULL
                THEN 'No'
            WHEN p_v.CONTACT_DATE IS NOT NULL 
                THEN 'Yes'
            WHEN u_p_v.CONTACT_DATE IS NOT NULL 
                THEN 'Yes'
        END AS  "PAC Visit"
    , pp.WOUND_CLASS_NM "Wound Class"
--    , CASE
--            WHEN pp.CPT_CODE IN ('43647', '43648', '44186', '44187', '44188', '44202', '44203', '44204', '44205', '44206', '44207', 
--                '44208', '44210', '44211', '44212', '44227', '44238', '44970', '44979', '45395', '45397', '45402', '45499', '47370', '47371', 
--                '47379', '47562', '47563', '47564', '47570', '47579') -- CPT Codes for Laparoscopic Cases
--            THEN 'Laparoscopic'
----            ELSE 'No'
--        END AS "Surgical Approach"
    , CASE
        WHEN pom."Documented Pt CHG Bath" IS NULL THEN 'ND'
        WHEN pom."Documented Pt CHG Bath" = 'NO' THEN 'No'
        WHEN pom."Documented Pt CHG Bath" = 'YES' THEN 'Yes'
        WHEN pom."Documented Pt CHG Bath" = 'N/A' THEN 'N/A'
    END AS "Documented Pt CHG Bath"
    , CASE
        WHEN pom."CHG Wipes Used" IS NULL THEN 'ND' 
        WHEN pom."CHG Wipes Used" = 'NO' THEN 'No'
        WHEN pom."CHG Wipes Used" = 'YES' THEN 'Yes'
    END AS "CHG Wipes Used (Holding Room)"    
    , CASE
        WHEN pom."Bowel Prep Complete" IS NULL THEN 'ND' 
        WHEN pom."Bowel Prep Complete" = 'No' THEN 'No' 
        WHEN pom."Bowel Prep Complete" = 'N/A' THEN 'N/A' 
        WHEN pom."Bowel Prep Complete" = 'Yes' THEN 'Yes' 
    END AS "Bowel Prep Complete"
    , CASE
        WHEN pom."Pre-Op Antibiotic" IS NULL THEN 'ND'
        WHEN pom."Pre-Op Antibiotic" = 'No' THEN 'No'
        WHEN pom."Pre-Op Antibiotic" = 'N/A' THEN 'N/A'
        WHEN pom."Pre-Op Antibiotic" = 'Yes' THEN 'Yes'
    END AS "Pre-Op Antibiotic Taken"
--
----    , pom."Date of Last Liquid"
----    , pom."Time of Last Liquid"
----    , pom."Date of Last Solid"
----    , pom."Time of Last Solid"
    , CASE
        WHEN lls."Date of Last Liquid" IS NULL THEN 'ND'
        ELSE TO_CHAR(TO_DATE('18401231','YYYYMMDD') + lls."Date of Last Liquid", 'MM-DD-YYYY')  
    END AS "Date of Last Liquid"
    , CASE
        WHEN lls."Time of Last Liquid" IS NULL THEN 'ND'
        ELSE TO_CHAR(TO_DATE(lls."Time of Last Liquid",'sssss'),'hh24:mi')  
    END AS "Time of Last Liquid"
    , CASE
        WHEN lls."Date of Last Solid" IS NULL THEN 'ND'
        ELSE TO_CHAR(TO_DATE('18401231','YYYYMMDD') + lls."Date of Last Solid", 'MM-DD-YYYY')  
    END AS "Date of Last Solid"
    , CASE
        WHEN lls."Time of Last Solid" IS NULL THEN 'ND'
        ELSE TO_CHAR(TO_DATE(lls."Time of Last Solid",'sssss'),'hh24:mi')  
    END AS "Time of Last Solid"
    , CASE
        WHEN pom."Pre-Warmed Room" IS NULL THEN 'ND'
        WHEN pom."Pre-Warmed Room" = 'No' THEN 'No'
        WHEN pom."Pre-Warmed Room" = 'Yes' THEN 'Yes'
    END AS "Pre-Warmed Room"    
    , CASE
        WHEN pom."Skin Prep by Appropriate Staff" IS NULL THEN 'ND'
        WHEN pom."Skin Prep by Appropriate Staff" = 'No' THEN 'No'
        WHEN pom."Skin Prep by Appropriate Staff" = 'Yes' THEN 'Yes'
    END AS "Skin Prep by Appropriate Staff"
    , CASE
        WHEN pom."OR Traffic Sign Used" IS NULL THEN 'ND'
        WHEN pom."OR Traffic Sign Used" = 'NO' THEN 'No'
        WHEN pom."OR Traffic Sign Used" = 'Yes' THEN 'Yes'
    END AS "OR Traffic Sign Used"
    , CASE
        WHEN pom."Wound Protector Used" IS NULL THEN 'ND' 
        WHEN pom."Wound Protector Used" = 'No' THEN 'No'
        WHEN pom."Wound Protector Used" = 'No (Laproscopic Only)' THEN 'N/A'
        WHEN pom."Wound Protector Used" = 'NA (Not Applicable)' THEN 'N/A'
        WHEN pom."Wound Protector Used" = 'Yes' THEN 'Yes'
    END AS "Wound Protector Used"
    , CASE
        WHEN pom."Gown/Glove Changed" IS NULL THEN 'ND' 
        WHEN pom."Gown/Glove Changed" = 'No' THEN 'No'
        WHEN pom."Gown/Glove Changed" = 'No (Laproscopic Only)' THEN 'N/A'
        WHEN pom."Gown/Glove Changed" = 'NA (Not Applicable)' THEN 'N/A'
        WHEN pom."Gown/Glove Changed" = 'Yes' THEN 'Yes'
    END AS "Gown/Glove Changed"
    , CASE
        WHEN pom."Closing Pan Used" IS NULL THEN 'ND' 
        WHEN pom."Closing Pan Used" = 'No' THEN 'No'
        WHEN pom."Closing Pan Used" = 'No (Laproscopic Only)' THEN 'N/A'
        WHEN pom."Closing Pan Used" = 'NA (Not Applicable)' THEN 'N/A'
        WHEN pom."Closing Pan Used" = 'Yes' THEN 'Yes'
    END AS "Closing Pan Used"
    , CASE
        WHEN pom."No Flash Instruments" IS NULL THEN 'ND' 
        WHEN pom."No Flash Instruments" = 'No' THEN 'No'
        WHEN pom."No Flash Instruments" = 'Yes (comment required)' THEN 'Yes'
    END AS "Flash Instruments Used"
-- Update this CASE when the Dressing Type flowsheet is updated
    , CASE
        WHEN pom."Silverlon Used" IS NULL THEN 'Other' 
        WHEN pom."Silverlon Used" = 'No' THEN 'Other'
        WHEN pom."Silverlon Used" = 'No (Laparoscopic Only)' THEN 'Other'
        WHEN pom."Silverlon Used" = 'Yes' THEN 'Silverlon'
        ELSE pom."Silverlon Used"
    END AS "Dressing Type"
    , pom."Silverlon Used"
    , CASE
        WHEN td."Temp >= 36" IS NULL THEN 'Yes'
        ELSE td."Temp >= 36"
    END AS "Temp >= 36"
    , CASE
        WHEN od."FiO2 >= 60" IS NULL THEN 'Yes'
        ELSE od."FiO2 >= 60"
    END AS "FiO2 >= 60"
----        , CASE 
----                WHEN gc180. "PostOp+7_2ConsecDaysGluc>180" IS NULL 
----                THEN 'No' 
----                ELSE gc180. "PostOp+7_2ConsecDaysGluc>180" 
----            END AS "PostOp+7_2ConsecDaysGluc>180"
----        , CASE 
----                WHEN gc70. "PostOp+7Days_Glucose<70" IS NULL 
----                THEN 'No' 
----                ELSE gc70. "PostOp+7Days_Glucose<70" 
----            END AS "PostOp+7Days_Glucose<70"
----        , CASE 
----                WHEN ed."EuglycemiaDuringProcedure" IS NULL 
----                THEN 'Yes' 
----                ELSE ed."EuglycemiaDuringProcedure" 
----            END AS "EuglycemiaDuringProcedure"
----    , abd."DoseNumber"
    , CASE
        WHEN abd."Abx Given Prior to Case Start" = 'No' THEN 'No' 
        WHEN abd."Abx Given Prior to Case Start" = 'Yes' THEN 'Yes'
        ELSE 'ND'
    END AS "Abx Given Prior to Case Start"
    , CASE
        WHEN adr."Re-doseGiven" IS NULL THEN 'ND'
        ELSE adr."Re-doseGiven"
    END AS "Re-doseGiven"
--    , CASE
--        WHEN abd."Re-doseGiven" IS NULL THEN 'ND' 
--        ELSE abd."Re-doseGiven"
--    END AS "Re-doseGiven"

FROM PAT_POP pp
    LEFT OUTER JOIN A1C_LAB a_l ON pp.PAT_ID = a_l.PAT_ID
    LEFT OUTER JOIN MRSA_LAB m_l ON pp.PAT_ID = m_l.PAT_ID
    LEFT OUTER JOIN PAC_VISIT p_v ON pp.LOG_ID = p_v.LOG_ID
    LEFT OUTER JOIN UNLINKED_PAC_VISIT u_p_v ON pp.LOG_ID = u_p_v.LOG_ID
    LEFT OUTER JOIN PRE_OP_MEAS pom ON pp.LOG_ID = pom.LOG_ID
    LEFT OUTER JOIN LAST_LIQ_SOLID lls ON pp.LOG_ID = lls.LOG_ID
    LEFT OUTER JOIN ABDOMINAL_ORDER ao ON pp.PAT_ID = ao.PAT_ID
    LEFT OUTER JOIN TEMP_DATA td ON pp.LOG_ID = td.LOG_ID
    LEFT OUTER JOIN O2_DATA od ON pp.LOG_ID = od.LOG_ID
    LEFT OUTER JOIN DIABETES dbt ON pp.LOG_ID = dbt.LOG_ID
--    LEFT OUTER JOIN GLUCOSE_CONTROL_GT180 gc180 ON pp.PAT_ID = gc180.PAT_ID 
--        AND pp.SURGERY_DATE = gc180.SURGERY_DATE
--    LEFT OUTER JOIN GLUCOSE_CONTROL_LT70 gc70 ON pp.PAT_ID = gc70.PAT_ID
--        AND pp.SURGERY_DATE = gc70.SURGERY_DATE
--    LEFT OUTER JOIN EUGLYCEMIA_DATA ed ON pp.PAT_ID = ed.PAT_ID
--        AND pp.SURGERY_DATE = ed.SURGERY_DATE
    LEFT OUTER JOIN ANTIBIOTICS_DATA abd ON pp.LOG_ID = abd.LOG_ID
    LEFT OUTER JOIN ABX_DATA_REDOSE adr ON pp.LOG_ID = adr.LOG_ID
    
    
--GROUP BY 
--    pp.LOG_ID
--    , pp.PAT_ID
--    , pp.CPT_CODE
--    , pp.PROC_NAME
--    , pp."Surgery Date"
--    , pp.PAT_MRN_ID
--    , pp.PAT_NAME
--    , pp."Age at Encounter"
--    , pp."Location"
--    , pp.PRIMARY_PHYSICIAN_NM
--    , pp."Surgical Service"
----    , pp."Subspecialty"
--    , pp.CASE_CLASS_C
--    , pp."Case Class Name"
--    , a_l.ORD_VALUE
--    , ao."Ordering Date"
--    , dbt."Diabetes Diagnosis?"
--    , m_l.ORD_VALUE
--    , m_l.RESULT_DATE
--    , p_v.CONTACT_DATE
--    , u_p_v.CONTACT_DATE
--    , pp.WOUND_CLASS_NM
--    , pom."Documented Pt CHG Bath"
--    , pom."CHG Wipes Used"
--    , pom."Bowel Prep Complete"
--    , pom."Pre-Op Antibiotic"
--    , lls."Date of Last Liquid"
--    , lls."Time of Last Liquid"
--    , lls."Date of Last Solid"
--    , lls."Time of Last Solid"
--    , pom."Pre-Warmed Room"
--    , pom."Skin Prep by Appropriate Staff"
--    , pom."OR Traffic Sign Used"
--    , pom."Wound Protector Used"
--    , pom."Gown/Glove Changed"
--    , pom."Closing Pan Used"
--    , pom."No Flash Instruments"
--    , pom."Silverlon Used"
--    , td."Temp >= 36"
--    , od."FiO2 >= 60"
------    , "PostOp+7_2ConsecDaysGluc>180"
------    , "PostOp+7Days_Glucose<70"
------    , "EuglycemiaDuringProcedure"
------    , abd."DoseNumber"
--    , abd."Abx Given Prior to Case Start"
--    , adr."Re-doseGiven"
