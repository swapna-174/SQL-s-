/*

 Main Patient Population

 Consists of cases with the following procedures: Peripheral/Other (ANE100P), Lumbar Plexus (ANE100M), Spinal (ANE100D), Sciatic (ANE100N),
 Brachial Plexus (ANE100L), CSE (ANE100B), Epidural (ANE100A), Truncal (ANE100O)

*/

WITH
PAT_POP AS
(SELECT DISTINCT
    pat.PAT_MRN_ID "Patient MRN"
    , fans.AN_LOG_ID "Log ID"
    , fans.AN_DATE "Service Date"
    , fans.AN_PROC_NAME "Procedure Name"
    , op.DESCRIPTION "Block Type" 
    , eap.PROC_CODE 
    , eap.PROC_NAME
    , npo.NOTE_ID "Note ID"
    , npo.ASC_PROC_ORDERS_ID "Order ID"

FROM F_AN_RECORD_SUMMARY fans
    LEFT OUTER JOIN HNO_INFO hno ON fans.AN_53_ENC_CSN_ID = hno.PAT_ENC_CSN_ID
    LEFT OUTER JOIN NOTES_PROC_ORDERS npo ON hno.NOTE_ID = npo.NOTE_ID
    LEFT OUTER JOIN ORDER_CONCEPT oc ON npo.ASC_PROC_ORDERS_ID = oc.ORDER_ID
    LEFT OUTER JOIN CLARITY_CONCEPT cc ON oc.CONCEPT_ID = cc.CONCEPT_ID
    LEFT OUTER JOIN ORDER_PROC op ON npo.ASC_PROC_ORDERS_ID = op.ORDER_PROC_ID
    LEFT OUTER JOIN PATIENT pat ON fans.AN_PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN CLARITY_EAP eap ON op.PROC_ID = eap.PROC_ID
    LEFT OUTER JOIN CLARITY_SER ser ON fans.AN_RESP_PROV_ID = ser.PROV_ID
WHERE fans.AN_DATE >= '01-Oct-2017'
    AND fans.AN_DATE < '07-Oct-2017'
    AND eap.PROC_CODE IN ('ANE100L', 'ANE100B', 'ANE100A', 'ANE100M', 'ANE100P', 'ANE100N', 'ANE100D', 'ANE100O')
    AND hno.IP_NOTE_TYPE_C = 28 -- Anesthesia Procedure Note
ORDER BY
    pat.PAT_MRN_ID
    , fans.AN_LOG_ID
    , npo.NOTE_ID
),

ANES_PROVIDER AS
(SELECT
    pp."Log ID"
    , pp."Order ID"
    , oc.CONCEPT_VALUE "Provider 1 ID"
    , oc.CONCEPT_ID
    , ser.PROV_NAME "Provider 1 Name"
    , ser.PROV_TYPE "Provider 1 Type"
FROM PAT_POP pp
    INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
    INNER JOIN CLARITY_SER ser ON oc.CONCEPT_VALUE = ser.PROV_ID
WHERE oc.CONCEPT_ID = 'EPIC#13218'
),

RESFELL_PROVIDER AS
(SELECT
    pp."Log ID"
    , pp."Order ID"
    , oc.CONCEPT_VALUE "Provider 2 ID"
    , oc.CONCEPT_ID
    , ser.PROV_NAME "Provider 2 Name"
    , ser.PROV_TYPE "Provider 2 Type"
FROM PAT_POP pp
    INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
    INNER JOIN CLARITY_SER ser ON oc.CONCEPT_VALUE = ser.PROV_ID
WHERE oc.CONCEPT_ID = 'EPIC#13219'
),

CRNA_PROVIDER AS
(SELECT
    pp."Log ID"
    , pp."Order ID"
    , oc.CONCEPT_VALUE "Provider 3 ID"
    , oc.CONCEPT_ID
    , ser.PROV_NAME "Provider 3 Name"
    , ser.PROV_TYPE "Provider 3 Type"
FROM PAT_POP pp
    INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
    INNER JOIN CLARITY_SER ser ON oc.CONCEPT_VALUE = ser.PROV_ID
WHERE oc.CONCEPT_ID = 'EPIC#13190'
),

PATIENT_POSITION AS
(SELECT
    pp."Log ID"
    , pp."Order ID"
    , oc.CONCEPT_VALUE "Patient Position"
    , oc.CONCEPT_ID
FROM PAT_POP pp
    INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
WHERE oc.CONCEPT_ID = 'EPIC#PROC0012'
),


PATIENT_PREP AS
(SELECT
    pp."Log ID"
    , pp."Order ID"
    , oc.CONCEPT_VALUE
    , oc.CONCEPT_ID
    , CASE
        WHEN oc.CONCEPT_ID = 'EPIC#18418' THEN 'Chloraprep'
        WHEN oc.CONCEPT_ID = 'EPIC#12843' THEN 'DuraPrep'
        WHEN oc.CONCEPT_ID = 'EPIC#22635' THEN 'Betadine'
    END AS "Patient Prep"
FROM PAT_POP pp
    INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
WHERE oc.CONCEPT_ID IN ('EPIC#18418', 'EPIC#12843', 'EPIC#22635')
),

ASEPSIS AS
(SELECT *
FROM
    (SELECT
        pp."Log ID"
        , pp."Order ID"
        , oc.LINE "Sterile Prep"
        , oc.CONCEPT_VALUE "Asepsis Value"
        , oc.CONCEPT_ID
    FROM PAT_POP pp
        INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
    WHERE oc.CONCEPT_ID = 'EPIC#50553'
    )

    PIVOT 
    (
        MAX("Asepsis Value")
            FOR "Sterile Prep" IN ('1' AS "Sterile Prep 1", '2' AS "Sterile Prep 2", '3' AS "Sterile Prep 3", '4' AS "Sterile Prep 4")
    )
),

LATERALITY AS
(SELECT
    pp."Log ID"
    , pp."Order ID"
    , oc.CONCEPT_VALUE "Laterality"
    , oc.CONCEPT_ID
FROM PAT_POP pp
    INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
WHERE oc.CONCEPT_ID = 'EPIC#72501'
),

BLOCK_TYPE AS
(SELECT
    pp."Log ID"
    , pp."Order ID"
    , oc.CONCEPT_VALUE "Block Type"
    , oc.CONCEPT_ID
FROM PAT_POP pp
    INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
WHERE oc.CONCEPT_ID = 'EPIC#12678'
),

TECHNIQUE AS
(SELECT
    pp."Log ID"
    , pp."Order ID"
    , oc.CONCEPT_VALUE "Technique"
    , oc.CONCEPT_ID
FROM PAT_POP pp
    INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
WHERE oc.CONCEPT_ID = 'EPIC#72549'
),

NEEDLE_LOC AS
(SELECT *
FROM
    (SELECT
        pp."Log ID"
        , pp."Order ID"
        , oc.CONCEPT_VALUE "Location Value"
        , oc.CONCEPT_ID "Concept ID"
        , CASE
            WHEN oc.CONCEPT_ID = 'EPIC#72506' THEN 'Nerve Stimulation'
            WHEN oc.CONCEPT_ID = 'EPIC#72531' THEN 'Ultrasound'
            WHEN oc.CONCEPT_ID = 'EPIC#14412' THEN 'Landmark'
        END AS  "Needle Localization"
    FROM PAT_POP pp
        INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
    WHERE oc.CONCEPT_ID IN ('EPIC#72506', 'EPIC#72531', 'EPIC#14412')
    )

        PIVOT 
    (
        MAX("Needle Localization")
            FOR "Concept ID" IN ('EPIC#72506' AS "Needle Localization 1", 'EPIC#72531' AS "Needle Localization 2"
                    , 'EPIC#14412' AS "Needle Localization 3")
    )

),

ULTRASOUND_ORIENT AS
(SELECT
    pp."Log ID"
    , pp."Order ID"
    , oc.CONCEPT_VALUE "Ultrasound Orientation"
    , oc.CONCEPT_ID
FROM PAT_POP pp
    INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
WHERE oc.CONCEPT_ID IN ('EPIC#15426', 'WHANE#014')
),

PROCEDURE_EVAL AS
(SELECT
    pp."Log ID"
    , pp."Order ID"
    , oc.CONCEPT_VALUE  "Procedure Evaluation"
    , oc.CONCEPT_ID

FROM PAT_POP pp
    INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
WHERE oc.CONCEPT_ID = 'EPIC#11149'
),

HR_CHANGE AS
(SELECT
    pp."Log ID"
    , pp."Order ID"
    , oc.CONCEPT_VALUE 
    , oc.CONCEPT_ID
    , CASE
        WHEN oc.CONCEPT_VALUE = '0' THEN 'No'
        WHEN oc.CONCEPT_VALUE = '1' THEN 'Yes'
    END AS "Heart Rate Change"
FROM PAT_POP pp
    INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
WHERE oc.CONCEPT_ID = 'EPIC#13003'
),

SLOW_FRAC_INJ AS
(SELECT
    pp."Log ID"
    , pp."Order ID"
    , oc.CONCEPT_VALUE
    , oc.CONCEPT_ID
    , CASE
        WHEN oc.CONCEPT_VALUE = '0' THEN 'No'
        WHEN oc.CONCEPT_VALUE = '1' THEN 'Yes'
    END AS "Slow Fractionated Injection"
FROM PAT_POP pp
    INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
WHERE oc.CONCEPT_ID = 'EPIC#13005'
),

PROCEDURE_COMPLICATIONS AS
(SELECT *
FROM
    (SELECT
        pp."Log ID"
        , pp."Order ID"
        , oc.LINE "Complication"
        , oc.CONCEPT_VALUE "Complication Value"
        , oc.CONCEPT_ID
    FROM PAT_POP pp
        INNER JOIN ORDER_CONCEPT oc ON pp."Order ID" = oc.ORDER_ID
    WHERE oc.CONCEPT_ID = 'EPIC#13008'
    )

    PIVOT 
    (
        MAX("Complication Value")
            FOR "Complication" IN ('1' AS "Complication 1", '2' AS "Complication 2", '3' AS "Complication 3"
                    , '4' AS "Complication 4", '5' AS "Complication 5", '6' AS "Complication 6")
    )
)


SELECT 
    pp."Patient MRN"
    , pp."Log ID"
    , pp."Note ID"
    , pp."Order ID"
    , pp."Service Date"
    , pp."Procedure Name"
    , aprv."Provider 1 ID"
    , aprv."Provider 1 Name"
    , aprv."Provider 1 Type"
    , rprv."Provider 2 ID"
    , rprv."Provider 2 Name"
    , rprv."Provider 2 Type"
    , cprv."Provider 3 ID"
    , cprv."Provider 3 Name"
    , cprv."Provider 3 Type"
    , pp."Block Type"
    , patpos."Patient Position"
    , patprp."Patient Prep"
    , ase."Sterile Prep 1"
    , ase."Sterile Prep 2"
    , ase."Sterile Prep 3"
    , ase."Sterile Prep 4"
    , lat."Laterality"
    , blt."Block Type"
    , tcn."Technique"
    , ndl."Needle Localization 1"
    , ndl."Needle Localization 2"
    , ndl."Needle Localization 3"
    , ult."Ultrasound Orientation"
    , pvl."Procedure Evaluation"
    , hrc."Heart Rate Change"
    , sfi."Slow Fractionated Injection"
    , prc."Complication 1"
    , prc."Complication 2"
    , prc."Complication 3"
    , prc."Complication 4"
    , prc."Complication 5"
    , prc."Complication 6"

FROM PAT_POP pp
    LEFT OUTER JOIN ANES_PROVIDER aprv ON pp."Order ID" = aprv."Order ID"
    LEFT OUTER JOIN RESFELL_PROVIDER rprv ON pp."Order ID" = rprv."Order ID"
    LEFT OUTER JOIN CRNA_PROVIDER cprv ON pp."Order ID" = cprv."Order ID"
    LEFT OUTER JOIN PATIENT_POSITION patpos ON pp."Order ID" = patpos."Order ID"
    LEFT OUTER JOIN PATIENT_PREP patprp ON pp."Order ID" = patprp."Order ID"
    LEFT OUTER JOIN ASEPSIS ase ON pp."Order ID" = ase."Order ID"
    LEFT OUTER JOIN LATERALITY lat ON pp."Order ID" = lat."Order ID"
    LEFT OUTER JOIN BLOCK_TYPE blt ON pp."Order ID" = blt."Order ID"    
    LEFT OUTER JOIN TECHNIQUE tcn ON pp."Order ID" = tcn."Order ID"
    LEFT OUTER JOIN NEEDLE_LOC ndl ON pp."Order ID" = ndl."Order ID"
    LEFT OUTER JOIN ULTRASOUND_ORIENT ult ON pp."Order ID" = ult."Order ID"
    LEFT OUTER JOIN PROCEDURE_EVAL pvl ON pp."Order ID" = pvl."Order ID"
    LEFT OUTER JOIN HR_CHANGE hrc ON pp."Order ID" = hrc."Order ID"
    LEFT OUTER JOIN SLOW_FRAC_INJ sfi ON pp."Order ID" = sfi."Order ID"
    LEFT OUTER JOIN PROCEDURE_COMPLICATIONS prc ON pp."Order ID" = prc."Order ID"

ORDER BY
    pp."Patient MRN"
    , pp."Service Date"
    , pp."Log ID"
    , pp."Note ID"







