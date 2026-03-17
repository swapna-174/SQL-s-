WITH
PROC_CAT
AS
(SELECT
    tdl.PROC_ID
    , tdl.ORIG_SERVICE_DATE
    , tdl.PROCEDURE_QUANTITY
    , CASE
        WHEN tdl.PROC_ID IN (211513, 22720) 
            THEN  'ACLS Resuscitation'
        WHEN tdl.PROC_ID IN (64901, 	64899, 188529, 192303, 200847, 114192, 114196, 114206, 114204, 114200, 192305, 192418, 145419, 7931, 10081, 10079, 7917, 7915, 9549, 7929) 
            THEN 'Abscess Incision and Drainage'
        WHEN tdl.PROC_ID IN (22720, 11941) 
            THEN  'Airway Management (oral/nasal airway and Bag Valve Mask)'
        WHEN tdl.PROC_ID IN (22720) 
              THEN  'Cardiopulmonary resuscitation'
        WHEN tdl.PROC_ID IN (23030) 
            THEN  'Carotid Ultrasound'
        WHEN tdl.PROC_ID IN (19260, 13251, 13249) 
            THEN  'Central Line Placement'
        WHEN tdl.PROC_ID IN (64852) 
            THEN  'Chest Tube Placement'
        WHEN tdl.PROC_ID IN (14599, 14601, 14603, 14609, 14607, 14611, 14613, 14605) 
            THEN  'Colonoscopy'
        WHEN tdl.PROC_ID IN (114420, 116115, 116117, 16328, 8137) 
            THEN  'Contraception Procedure - (Sterilization, IUD, Implanon)'
        WHEN tdl.PROC_ID IN (23318, 23236, 23330, 23322, 23332, 23320, 23242, 23234, 23240, 23238) 
              THEN  'Electroencephalogram'
        WHEN tdl.PROC_ID IN (23272, 23274, 23268, 200965, 23270, 200973, 136860, 200974, 136862, 136864) 
            THEN  'Electromyogram'
        WHEN tdl.PROC_ID IN (116109, 116111, 116113, 16280, 711) 
            THEN  'Endometrial Biopsy'
        WHEN tdl.PROC_ID IN (139791, 197795, 116093, 16234, 16242, 16232, 16238, 16236, 16254, 16256) 
            THEN  'Evaluation of cervical disease (Colposcopy, conization, LEEP, cryotherapy)'
        WHEN tdl.PROC_ID IN (180369, 209268, 209238, 209212, 115873, 115871, 135818, 115875, 67006, 145529, 15478) 
            THEN  'Foley Catheter Placement'
        WHEN tdl.PROC_ID IN (116123, 116125, 98472, 116129, 201135, 199205, 67036, 16338, 128, 16368, 16372, 16374, 16378, 16376, 16370, 16380) 
            THEN  'Hysteroscopic surgery, D&C, or endometrial ablation'
        WHEN tdl.PROC_ID IN (15520, 15516, 15486, 15542, 15540, 16170, 16194, 16308) 
            THEN  'Incontinence or prolapse procedure (vaginal or abdominal)'
        WHEN tdl.PROC_ID IN (211553, 115118, 124092, 115120, 38849, 72364) 
            THEN  'Intubation'
        WHEN tdl.PROC_ID IN (15057, 16356, 16358, 16396, 16402, 16400, 16230, 64984, 16506, 16508) 
            THEN  'Laparoscopic Gynecological Surgery'
        WHEN tdl.PROC_ID IN (116191, 7521, 23422, 186573, 17052) 
            THEN  'Lumbar Puncture'
        WHEN tdl.PROC_ID IN (136592, 136590) 
            THEN  'Paracentesis'
        WHEN tdl.PROC_ID IN (72	, 703, 619, 14499, 14897, 15270, 16058, 15272, 6896) 
            THEN  'Robotic Surgery'
        WHEN tdl.PROC_ID IN (194061, 194059) 
            THEN  'Thoracentesis'
    END AS Proc_Category
FROM
    CLARITY.CLARITY_TDL_TRAN tdl
WHERE
    tdl.ORIG_SERVICE_DATE >= ADD_MONTHS(SYSDATE, -12) 
    AND tdl.PROC_ID in (64901, 	64899, 	188529, 	192303, 	200847, 	114192, 	114196, 	114206, 	114204, 	114200, 	
                        192305, 	192418, 	145419, 	7931, 	10081, 	10079, 	7917, 	7915, 	9549, 	7929, 	211513, 	22720, 	22720, 	11941, 	
                        22720, 	23030, 	19260, 	13251, 	13249, 	64852, 	14601, 	14603, 	14609, 	14607, 	14611, 	14613, 	14599, 	14605, 	114420, 	116115, 	
                        116117, 	16328, 	8137, 	23318, 	23330, 	23322, 	23332, 	23320, 	23242, 	23234, 	23240, 	23238, 	23236, 	23272, 	23274, 	23268, 	
                        200965, 	23270, 	200973, 	136860, 	200974, 	136862, 	136864, 	116109, 	116111, 	116113, 	16280, 	711, 	
                        139791, 	197795, 	116093, 	16234, 	16242, 	16232, 	16238, 	16236, 	16254, 	16256, 	180369, 	209268, 	209238, 	209212, 	
                        115873, 	115871, 	135818, 	115875, 	67006, 	145529, 	15478, 	116123, 	116125, 	98472, 	116129, 	201135, 	199205, 	
                        67036, 	16338, 	128, 	16368, 	16372, 	16374, 	16378, 	16376, 	16370, 	16380, 	15520, 	15516, 	15486, 	15542, 	15540, 	16170, 	16194, 	
                        16308, 	211553, 	115118, 	124092, 	115120, 	38849, 	72364, 	15057, 	16356, 	16358, 	16396, 	16402, 	16400, 	16230, 	64984, 	
                        16506, 	16508, 	116191, 	7521, 	23422, 	186573, 	17052, 	136592, 	136590, 	72, 	703, 	619, 	14499, 	14897, 	15270, 	
                        16058, 	15272, 	6896, 	194061, 	194059)
)
SELECT 
--    pc.PROC_ID "Procedure"
--    , eap.PROC_NAME "Procedure_Name"
    SUM(pc.PROCEDURE_QUANTITY) "Procedure_Count"
    , 'Professional Billing' AS "SOM_Module"
    , pc.Proc_Category AS "Proc_Category"
FROM 
    PROC_CAT pc
    INNER JOIN CLARITY.CLARITY_EAP eap ON pc.PROC_ID = eap.PROC_ID
--WHERE 
--    pc.ORIG_SERVICE_DATE >= ADD_MONTHS(SYSDATE, -12) 
--    AND pc.PROC_ID in (64901, 	64899, 	188529, 	192303, 	200847, 	114192, 	114196, 	114206, 	114204, 	114200, 	
--                        192305, 	192418, 	145419, 	7931, 	10081, 	10079, 	7917, 	7915, 	9549, 	7929, 	211513, 	22720, 	22720, 	11941, 	
--                        22720, 	23030, 	19260, 	13251, 	13249, 	64852, 	14601, 	14603, 	14609, 	14607, 	14611, 	14613, 	14599, 	14605, 	114420, 	116115, 	
--                        116117, 	16328, 	8137, 	23318, 	23330, 	23322, 	23332, 	23320, 	23242, 	23234, 	23240, 	23238, 	23236, 	23272, 	23274, 	23268, 	
--                        200965, 	23270, 	200973, 	136860, 	200974, 	136862, 	136864, 	116109, 	116111, 	116113, 	16280, 	711, 	
--                        139791, 	197795, 	116093, 	16234, 	16242, 	16232, 	16238, 	16236, 	16254, 	16256, 	180369, 	209268, 	209238, 	209212, 	
--                        115873, 	115871, 	135818, 	115875, 	67006, 	145529, 	15478, 	116123, 	116125, 	98472, 	116129, 	201135, 	199205, 	
--                        67036, 	16338, 	128, 	16368, 	16372, 	16374, 	16378, 	16376, 	16370, 	16380, 	15520, 	15516, 	15486, 	15542, 	15540, 	16170, 	16194, 	
--                        16308, 	211553, 	115118, 	124092, 	115120, 	38849, 	72364, 	15057, 	16356, 	16358, 	16396, 	16402, 	16400, 	16230, 	64984, 	
--                        16506, 	16508, 	116191, 	7521, 	23422, 	186573, 	17052, 	136592, 	136590, 	72, 	703, 	619, 	14499, 	14897, 	15270, 	
--                        16058, 	15272, 	6896, 	194061, 	194059)
GROUP BY  
        pc.Proc_Category
--        , pc.PROC_ID
--        , eap.PROC_NAME