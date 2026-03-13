  SELECT --*
  cm.MEDICATION_ID
  ,cm.NAME
  ,coalesce(rx2.SHORT_NAME, zcsg.NAME) "SHORT_NAME"
  ,zct.NAME   "THERA_CLASS"
  ,zcpp.NAME  "PHARM_CLASS"
--  ,CASE WHEN cm.NAME LIKE '%CIPROFLOXACIN%' THEN 'FLUOROQUINOLONES' 
--        WHEN cm.NAME LIKE '%LEVOFLOXACIN%' THEN 'FLUOROQUINOLONES'
--        WHEN cm.NAME LIKE '%MOXIFLOXACIN%' THEN 'FLUOROQUINOLONES'
--        WHEN cm.NAME LIKE '%CEFEPIME%' THEN 'BETA-LACTAMS'
--        WHEN cm.NAME LIKE '%PIPERACILLIN-TAZOBACTAM%' THEN 'BETA-LACTAMS'
--        WHEN cm.NAME LIKE '%IMIPENEM%' THEN 'BETA-LACTAMS'
--        WHEN cm.NAME LIKE '%MEROPENEM%' THEN 'BETA-LACTAMS'
--        WHEN cm.NAME LIKE 'VANCOMYCIN 1.25 G%' THEN 'VANCOMYCIN IV'
--        WHEN cm.NAME LIKE 'VANCOMYCIN%'||'%INTRAV%' THEN 'VANCOMYCIN IV'
--        WHEN cm.NAME LIKE 'VANCOMYCIN IT%' THEN 'VANCOMYCIN IV'
--        WHEN cm.NAME LIKE 'VANCOMYCIN%'||'%IV SYRI%' THEN 'VANCOMYCIN IV'
--        WHEN cm.NAME LIKE 'VANCOMYCIN%'||'%IVPB%' THEN 'VANCOMYCIN IV'
--        WHEN cm.NAME LIKE 'VANCOMYCIN%'||'%10 MG/ML INJ%' THEN 'VANCOMYCIN IV'
--        WHEN cm.NAME LIKE '%CLINDAMYCIN%' THEN 'OTHER GRAM AGENTS'
--        WHEN cm.NAME LIKE '%DAPTOMYCIN%' THEN 'OTHER GRAM AGENTS'
--        WHEN cm.NAME LIKE '%LINEZOLID%' THEN 'OTHER GRAM AGENTS'
--        WHEN cm.NAME LIKE '%CEFTAROLINE%' THEN 'OTHER GRAM POS AGENTS'
--        WHEN cm.NAME LIKE '%CEFTAZIDIME-AVIBACTAM%' THEN 'MULTI GRAM NEG AGENTS'
--        WHEN cm.NAME LIKE '%CEFTOLOZANE-TAZOBACTAM%' THEN 'MULTI GRAM NEG AGENTS'
--        WHEN cm.NAME LIKE '%MEROPENEM-VABORBACTAM%' THEN 'MULTI GRAM NEG AGENTS'
--        WHEN cm.NAME LIKE '%CEFIDEROCOL%' THEN 'MULTI GRAM NEG AGENTS'
--        WHEN cm.NAME LIKE '%OMADACYCLINE' THEN 'MULTI GRAM NEG AGENTS'
--  
--
--
--  ELSE 'OTHER' END "GROUPMED"
  FROM CLARITY_MEDICATION cm
  LEFT OUTER JOIN ZC_SIMPLE_GENERIC zcsg ON cm.SIMPLE_GENERIC_C = zcsg.SIMPLE_GENERIC_C
    LEFT OUTER JOIN RX_MED_TWO rx2 ON cm.MEDICATION_ID = rx2.MEDICATION_ID
    LEFT OUTER JOIN ZC_THERA_CLASS zct ON cm.THERA_CLASS_C = zct.THERA_CLASS_C
    LEFT OUTER JOIN ZC_PHARM_CLASS zcpp ON cm.PHARM_CLASS_C = zcpp.PHARM_CLASS_C
  WHERE 
  cm.THERA_CLASS_C = 41


WITH PATPOPERX 
AS
(
  SELECT --%
  vrx.REPORT_DATE
, vrx.ORDER_ID
, vrx.MEDICATION_NM_WID
, vrx.MEDICATION_ID
, vrx.COST
, vrx.AUTHORIZING_PROV_NAME
, vrx.CHARGE_DEPARTMENT_NM_WID
, vrx.COST_CENTER_NM_WID
, vrx.UCL_ID
, vrx.IMPLIED_QTY
, vrx.ORDER_DATE_REAL
, vrx.CHARGE_DEPARTMENT_ID
--  ,vrx.MEDICATION_NM_WID
 , CASE WHEN vrx.MEDICATION_NM_WID like 'AMIKACIN%' then
    'Amikacin'
when vrx.MEDICATION_NM_WID like 'AMPHOTERICIN B LIPID%' then
    'Amphotericin B Lipid'
when vrx.MEDICATION_NM_WID like 'AMPHOTERICIN B LIPOSO%' then
    'Amphotericin B Liposomal'
when vrx.MEDICATION_NM_WID like 'AMPHOTERICIN B %' then
    'Amphotericin B'
when vrx.MEDICATION_NM_WID like 'AMPICILLIN-SULBACTAM%' then
    'Ampicillin-Sulbactam'
when vrx.MEDICATION_NM_WID like 'AZITHROMYCIN%' then
    'Azithromycin'
when vrx.MEDICATION_NM_WID like 'AZTREONAM%' then
    'Aztreonam'
when vrx.MEDICATION_NM_WID like 'CEFAZOLIN%' then
    'Cefazolin'
when vrx.MEDICATION_NM_WID like 'CEFEPIME%' then
    'Cefepime'
when vrx.MEDICATION_NM_WID like 'CEFOTAXIME%' then
    'Cefotaxime'
when vrx.MEDICATION_NM_WID like 'CEFOXITIN%' then
    'Cefoxitin'
when vrx.MEDICATION_NM_WID like 'CEFTAROLINE%' then
    'Ceftaroline'
when vrx.MEDICATION_NM_WID like 'CEFTAZIDIME-AVIBACTAM%' then
    'Ceftazidime-Avibactam'
when vrx.MEDICATION_NM_WID like 'CEFTAZIDIME %' then
    'Ceftazidime'
when vrx.MEDICATION_NM_WID like 'CEFTOLOZANE-TAZOBACTAM%' then
    'Ceftolozane-Tazobactam'
when vrx.MEDICATION_NM_WID like 'CEFTRIAXONE%' then
    'Ceftriaxone'
when vrx.MEDICATION_NM_WID like 'CEFUROXIME SODIUM%' then
    'Cefuroxime Sodium'
when vrx.MEDICATION_NM_WID like 'CIPROFLOXACIN%'||'%IN%' then
    'Ciprofloxacin Inj'
when vrx.MEDICATION_NM_WID like 'CIPROFLOXACIN%'||'%IVPB%' then
    'Ciprofloxacin Inj'
when vrx.MEDICATION_NM_WID like 'CIPROFLOXACIN%'||'%TAB%' then
    'Ciprofloxacin Oral'
when vrx.MEDICATION_NM_WID like 'CIPROFLOXACIN%'||'%SUSP%' then
    'Ciprofloxacin Oral'
when vrx.MEDICATION_NM_WID like 'CLINDAMYCIN%'||'%INJECTION%' then
    'Clindamycin Inj'
when vrx.MEDICATION_NM_WID like 'CLINDAMYCIN%'||'%IV SYRINGE%' then
    'Clindamycin Inj'
when vrx.MEDICATION_NM_WID like 'CLINDAMYCIN%'||'%INTRAVENOUS%' then
    'Clindamycin Inj'
when vrx.MEDICATION_NM_WID like 'CLINDAMYCIN%'||'%RX PREMIX%' then
    'Clindamycin Inj'
when vrx.MEDICATION_NM_WID like 'COLISTIMETHATE%' then
    'Colistimethate'
when vrx.MEDICATION_NM_WID like 'COLISTIN%' then
    'Colistimethate'
when vrx.MEDICATION_NM_WID like 'DALBAVANCIN%' then
    'Dalbavancin'
when vrx.MEDICATION_NM_WID like 'DAPTOMYCIN%' then
    'Daptomycin'
when vrx.MEDICATION_NM_WID like 'DORIPENEM%' then
    'Doripenem'
when vrx.MEDICATION_NM_WID like 'ERTAPENEM%' Then
    'Ertapenem'
when vrx.MEDICATION_NM_WID like 'FLUCONAZOLE%'||'%IN%' then
    'Fluconazole Inj'
when vrx.MEDICATION_NM_WID like 'FLUCONAZOLE%'||'%IVPB%' then
    'Fluconazole Inj'
when vrx.MEDICATION_NM_WID like 'FLUCONAZOLE%'||'%TAB%' then
    'Fluconazole Oral'
when vrx.MEDICATION_NM_WID like 'FLUCONAZOLE%'||'%SUSP%' then
    'Fluconazole Oral'
when vrx.MEDICATION_NM_WID like 'FLUCYTOSINE%' then
    'Flucytosine Oral'
when vrx.MEDICATION_NM_WID like 'IMIPENEM%' Then
    'Imipenem'
when vrx.MEDICATION_NM_WID like 'ISAVUCONAZONIUM%'||'%CAP%' THEN       --'%' || l.value || '%'
    'Isavuconazonium Oral'
when vrx.MEDICATION_NM_WID like 'ISAVUCONAZONIUM SULFATE%'||'%INTR%' then
    'Isavuconazonium Inj'
when vrx.MEDICATION_NM_WID like 'ITRACONAZOLE%' Then
    'Itraconazole'
when vrx.MEDICATION_NM_WID like 'LEVOFLOXACIN%'||'%INTR%' then
    'Levofloxacin Inj'
when vrx.MEDICATION_NM_WID like 'LEVOFLOXACIN%'||'%IV SYR%' then
    'Levofloxacin Inj'
when vrx.MEDICATION_NM_WID like 'LEVOFLOXACIN%'||'%IVPB%' then
    'Levofloxacin Inj'
when vrx.MEDICATION_NM_WID like 'LEVOFLOXACIN%'||'%TAB%' then
    'Levofloxacin Oral'
when vrx.MEDICATION_NM_WID like 'LEVOFLOXACIN%'||'%ORAL SOLU%' then
    'Levofloxacin Oral'
when vrx.MEDICATION_NM_WID like 'LINEZOLID%'||'%INTR%' then
    'Linezolid Inj'
when vrx.MEDICATION_NM_WID like 'LINEZOLID%'||'%PREMIX%' then
    'Linezolid Inj'
when vrx.MEDICATION_NM_WID like 'LINEZOLID%'||'%TAB%' then
    'Linezolid Oral'
when vrx.MEDICATION_NM_WID like 'LINEZOLID%'||'%SUSP%' then
    'Linezolid Oral'
when vrx.MEDICATION_NM_WID like 'MEROPENEM-VABORBACTAM%' Then
    'Meropenem-Vaborbactam'
when vrx.MEDICATION_NM_WID like 'MEROPENEM 0.1%' Then
    'Meropenem'
when vrx.MEDICATION_NM_WID like 'MEROPENEM 1%' Then
    'Meropenem'
when vrx.MEDICATION_NM_WID like 'MEROPENEM 1 GRAM INTRAVEN%' Then
    'Meropenem'
when vrx.MEDICATION_NM_WID like 'MEROPENEM 500 MG INTRAVEN%' Then
    'Meropenem'
when vrx.MEDICATION_NM_WID like 'MEROPENEM INJ%' Then
    'Meropenem'
when vrx.MEDICATION_NM_WID like 'MEROPENEM IV SYR%' Then
    'Meropenem'
when vrx.MEDICATION_NM_WID like 'MEROPENEM IVPB%' Then
    'Meropenem'
when vrx.MEDICATION_NM_WID like 'MICAFUNGIN%' Then
    'Micafungin'
when vrx.MEDICATION_NM_WID like 'MOXIFLOXACIN%'||'%IN%' then
    'Moxifloxacin Inj' 
when vrx.MEDICATION_NM_WID like 'MOXIFLOXACIN%'||'%TAB%' then
    'Moxifloxacin Oral' 
when vrx.MEDICATION_NM_WID like 'NAFCILLIN%' Then
    'Nafcillin'
when vrx.MEDICATION_NM_WID like 'OXACILLIN%' Then
    'Oxacillin'
when vrx.MEDICATION_NM_WID like 'PENICILLIN G%' then
    'Penicillin G'
when vrx.MEDICATION_NM_WID like 'PIPERACILLIN-TAZOBACTAM%' Then
    'Piperacillin-Tazobactam'
when vrx.MEDICATION_NM_WID like 'PLAZOMICIN%' Then
    'Plazomicin'
when vrx.MEDICATION_NM_WID like 'POSACONAZOLE%' Then
    'Posaconazole Oral'
when vrx.MEDICATION_NM_WID like 'QUINUPRISTIN-DALFOPRISTIN%' Then
    'Quinupristin-Dalfopristin'
when vrx.MEDICATION_NM_WID like 'REMDESIVIR%' Then
    'Remdesivir'
when vrx.MEDICATION_NM_WID like 'INV-REMDESIVIR%' Then
    'Remdesivir (Investigational)'
when vrx.MEDICATION_NM_WID like 'TIGECYCLINE%' Then
    'Tigecycline'
when vrx.MEDICATION_NM_WID like 'TOBRAMYCIN%' Then
    'Tobramycin'
when vrx.MEDICATION_NM_WID like 'VANCOMYCIN 1.25 G%' then
    'Vancomycin Inj'
when vrx.MEDICATION_NM_WID like 'VANCOMYCIN%'||'%INTRAV%' then
    'Vancomycin Inj'
when vrx.MEDICATION_NM_WID like 'VANCOMYCIN IT%' then
    'Vancomycin Inj'
when vrx.MEDICATION_NM_WID like 'VANCOMYCIN%'||'%IV SYRI%' then
    'Vancomycin Inj'
when vrx.MEDICATION_NM_WID like 'VANCOMYCIN%'||'%IVPB%' then
    'Vancomycin Inj'
when vrx.MEDICATION_NM_WID like 'VANCOMYCIN%'||'%10 MG/ML INJ%' then
    'Vancomycin Inj'
when vrx.MEDICATION_NM_WID like 'VANCOMYCIN%'||'%CAPSULE%' then
    'Vancomycin Oral'
when vrx.MEDICATION_NM_WID like 'VANCOMYCIN%'||'%ORAL%' then
    'Vancomycin Oral'
when vrx.MEDICATION_NM_WID like 'VORICONAZOLE%'||'%IN%' then
    'Voriconazole Inj'
when vrx.MEDICATION_NM_WID like 'VORICONAZOLE%'||'%TAB%' then
    'Voriconazole Oral'
when vrx.MEDICATION_NM_WID like 'VORICONAZOLE%'||'%SUSP%' then
    'Voriconazole Oral'
else
    'Non-Grouped'
END "GROUPER"




    
  FROM V_RX_CHARGES vrx
--  LEFT OUTER JOIN CLARITY_MEDICATION cm ON vrx.MEDICATION_ID = cm.MEDICATION_ID
  WHERE
  vrx.CHARGE_DEPARTMENT_NM_WID LIKE '%UNIT%' 
AND vrx.REPORT_DATE>= '1-jan-2020'
AND vrx.REPORT_DATE< '1-feb-2020'
--AND vrx.UCL_ID = 175344160
AND( 

vrx.MEDICATION_NM_WID LIKE 'AMIKACIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'AMPHOTERICIN B%'
OR vrx.MEDICATION_NM_WID LIKE 'AMPICILLIN-SULBACTAM%'
OR vrx.MEDICATION_NM_WID LIKE 'AZITHROMYCIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'AZTREONAM%'
OR vrx.MEDICATION_NM_WID LIKE 'CEFAZOLIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'CEFEPIME%' 
OR vrx.MEDICATION_NM_WID LIKE 'CEFOTAXIME%' 
OR vrx.MEDICATION_NM_WID LIKE 'CEFOXITIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'CEFTAROLINE%' 
OR vrx.MEDICATION_NM_WID LIKE 'CEFTAZIDIME-AVIBACTAM%' 
OR vrx.MEDICATION_NM_WID LIKE 'CEFTIAZIDIME%' 
OR vrx.MEDICATION_NM_WID LIKE 'CEFTOLOZANE-TAZOBACTAM%'
OR vrx.MEDICATION_NM_WID LIKE 'CEFTRIAXONE%'
OR vrx.MEDICATION_NM_WID LIKE 'CEFUROXIME SODIUM%'
OR vrx.MEDICATION_NM_WID LIKE 'CIPROFLOXACIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'CLINDAMYCIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'COLISTIMETHATE%'
OR vrx.MEDICATION_NM_WID LIKE 'COLISTIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'DALBAVANCIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'DAPTOMYCIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'DORIPENEM%' 
OR vrx.MEDICATION_NM_WID LIKE 'ERTAPENEM%'
OR vrx.MEDICATION_NM_WID LIKE 'FLUCONAZOLE%' 
OR vrx.MEDICATION_NM_WID LIKE 'FLUCYTOSINE%'
OR vrx.MEDICATION_NM_WID LIKE 'IMIPENEM%' 
OR vrx.MEDICATION_NM_WID LIKE 'INV_REMDESIVIR%'
OR vrx.MEDICATION_NM_WID LIKE 'ISAVUCONAZONIUM%' 
OR vrx.MEDICATION_NM_WID LIKE 'ITRACONAZOLE%' 
OR vrx.MEDICATION_NM_WID LIKE 'LEVOFLOXACIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'LINEZOLID%' 
OR vrx.MEDICATION_NM_WID LIKE 'MEROPENEM%'
OR vrx.MEDICATION_NM_WID LIKE 'MICAFUNGIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'MOXIFLOXACIN%'
OR vrx.MEDICATION_NM_WID LIKE 'NAFCILLIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'OXACILLIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'PENICILLIN G POTASSIUM%' 
OR vrx.MEDICATION_NM_WID LIKE 'PENICILLIN G SODIUM%'
OR vrx.MEDICATION_NM_WID LIKE 'PIPERACILLIN-TAZOBACTAM%'
OR vrx.MEDICATION_NM_WID LIKE 'PLAZOMICIN%' 
OR vrx.MEDICATION_NM_WID LIKE 'POSACONAZOLE%' 
OR vrx.MEDICATION_NM_WID LIKE 'QUINUPRISTIN-DALFOPRISTIN%'
OR vrx.MEDICATION_NM_WID LIKE 'REMDESIVIR%'
OR vrx.MEDICATION_NM_WID LIKE 'TIGECYCLINE%'
OR vrx.MEDICATION_NM_WID LIKE 'TOBRAMYCIN%'
OR vrx.MEDICATION_NM_WID LIKE 'VANCOMYCIN%'
OR vrx.MEDICATION_NM_WID LIKE 'VORICONAZOLE%') 
and
NOT (vrx.MEDICATION_NM_WID LIKE '%DESENS%'
OR vrx.MEDICATION_NM_WID LIKE '%DWELL%'
OR vrx.MEDICATION_NM_WID LIKE '%IRRIG%'
OR vrx.MEDICATION_NM_WID LIKE 'CLINDAMYCIN%CAPSULE'
OR vrx.MEDICATION_NM_WID LIKE 'CLINDAMYCIN%ORAL SOLUTION') 