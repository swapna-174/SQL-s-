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
  WHERE
  vrx.CHARGE_DEPARTMENT_NM_WID LIKE '%UNIT%' 
AND vrx.REPORT_DATE>= '1-jan-2020'
AND vrx.REPORT_DATE< '1-feb-2020'
--AND vrx.UCL_ID = '176391155'
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
OR vrx.MEDICATION_NM_WID LIKE 'CLINDAMYCIN%'||'%CAPSULE%'
OR vrx.MEDICATION_NM_WID LIKE 'CLINDAMYCIN%'||'%ORAL SOLUTION%') 


)

,PATPOPMAR
AS
(
   SELECT -- *
   mar.ORDER_MED_ID
   ,mar.SIG
   ,mar.TAKEN_TIME
   ,zcun.NAME 
   ,mar.SAVED_TIME
   ,zcmr.NAME "ACTION"
    ,CASE when UPPER(zcun.NAME) like 'MG'  THEN TO_CHAR(TO_CHAR(mar.SIG/1000),'99.9999')
        when UPPER(zcun.NAME) like 'MCG'  THEN TO_CHAR(TO_CHAR(mar.SIG/1000000),'99.9999')
        else TO_CHAR(mar.SIG,'99.9999')
        END "DGRAMS"
   FROM PATPOPERX pp
   INNER JOIN CLARITY_UCL ucl ON pp.UCL_ID=ucl.UCL_ID
    LEFT OUTER JOIN MAR_ADMIN_INFO mar ON ucl.CREATED_TIME=mar.SAVED_TIME
    AND pp.ORDER_ID=mar.ORDER_MED_ID
    LEFT OUTER JOIN ZC_MAR_RSLT zcmr ON mar.MAR_ACTION_C=zcmr.RESULT_C
    LEFT OUTER JOIN ZC_MED_UNIT zcun ON mar.DOSE_UNIT_C=zcun.DISP_QTYUNIT_C
  WHERE
  zcmr.RESULT_C IN ('1','1002','102','105','113','114','115','6')

)
SELECT distinct
pperx.GROUPER
,har.HSP_ACCOUNT_ID || '-' ||TRUNC(mar.TAKEN_TIME)  "HAR_ADMINDATE"
,TO_CHAR(CAST(mar.TAKEN_TIME AS date), 'MM/DD/YYYY') "ADMIN_DATE"
,to_char(CAST(mar.TAKEN_TIME AS DATE), 'hh24:mi:ss AM')  "ADMIN_TIME"
, har.HSP_ACCOUNT_ID  "HSP_ACCOUNT_ID"
,om.PAT_ENC_CSN_ID   "ACCOUNT_#"
, pat.PAT_MRN_ID "MRN"
, pat.PAT_NAME   "PATIENT_NAME"
, zcps.NAME   "SERVICE"
, freq.FREQ_NAME "FREQUENCY"
, pperx.MEDICATION_ID  "MED_ID"
, pperx.MEDICATION_NM_WID "MEDICATION"
, mar.SIG    "ADMIN_DOSE_AMOUNT"
, mar.NAME   "DOSE_UNIT"
 ,mar.DGRAMS "2_USE_MULTIPLY"
,CASE WHEN pperx.IMPLIED_QTY > 0 THEN mar.DGRAMS
      ELSE '-1' end  "DOSE_GRAMS" 
,CASE WHEN TRUNC((ucl.SERVICE_DATE_DT  - pat.BIRTH_DATE) / 365.25) < 1
    THEN CASE WHEN months_between (to_date(ucl.SERVICE_DATE_DT), pat.BIRTH_DATE) < 1
    THEN CONCAT(to_char(floor(TRUNC(ucl.SERVICE_DATE_DT ) - pat.BIRTH_DATE))  ,' Days')
    ELSE CONCAT(to_char(floor(months_between (to_date( ucl.SERVICE_DATE_DT ), pat.BIRTH_DATE) ) ),' Months')  END        
    ELSE to_char(TRUNC(floor(ucl.SERVICE_DATE_DT  - pat.BIRTH_DATE) / 365.25))
    END "PATIENT_AGE_AT_ENCOUNTER"
, pperx.COST   "DOSE_COST"
, pperx.AUTHORIZING_PROV_NAME  "AUTHORIZING_PROVIDER"
, pperx.CHARGE_DEPARTMENT_NM_WID "LOCATION"
, mar.ACTION   "MAR_ACTION"
, pperx.COST_CENTER_NM_WID  "COST_CENTER"
, pperx.REPORT_DATE   "REPORT_DATE"
, pperx.ORDER_ID  "ORDER_ID"
, pperx.UCL_ID  "UCL_ID"
, pperx.IMPLIED_QTY  "IMPLIED_QTY"
,parloc.LOC_NAME
FROM PATPOPERX pperx 
INNER JOIN ORDER_MED om ON pperx.ORDER_ID = om.ORDER_MED_ID
LEFT OUTER JOIN PAT_ENC enc ON om.PAT_ENC_CSN_ID=enc.PAT_ENC_CSN_ID 
AND om.PAT_ENC_DATE_REAL=enc.PAT_ENC_DATE_REAL 
LEFT OUTER JOIN IP_FREQUENCY freq ON om.HV_DISCR_FREQ_ID=freq.FREQ_ID
LEFT OUTER JOIN ZC_ADMIN_ROUTE zcar ON om.MED_ROUTE_C=zcar.MED_ROUTE_C
LEFT OUTER JOIN HSP_ACCOUNT har ON enc.HSP_ACCOUNT_ID=har.HSP_ACCOUNT_ID
LEFT OUTER JOIN PATIENT pat ON enc.PAT_ID=pat.PAT_ID 
LEFT OUTER JOIN ZC_PAT_SERVICE zcps ON har.PRIM_SVC_HA_C=zcps.HOSP_SERV_C
INNER JOIN ORDER_DISP_INFO odi ON pperx.ORDER_DATE_REAL=odi.CONTACT_DATE_REAL
AND pperx.ORDER_ID=odi.ORDER_MED_ID 
INNER JOIN CLARITY_UCL ucl ON pperx.UCL_ID=ucl.UCL_ID
LEFT OUTER JOIN CLARITY_DEP dep ON pperx.CHARGE_DEPARTMENT_ID=dep.DEPARTMENT_ID
LEFT OUTER JOIN clarity_loc loc ON dep.REV_LOC_ID = loc.LOC_ID    -----ADT_PARENT_ID
LEFT OUTER JOIN clarity_loc parloc ON loc.HOSP_PARENT_LOC_ID = parloc.LOC_ID
INNER JOIN PATPOPMAR mar ON ucl.CREATED_TIME=mar.SAVED_TIME
              AND ucl.ORDER_ID=mar.ORDER_MED_ID
WHERE   
odi.ORD_CNTCT_TYPE_C IN (5,7,9) 
AND  NOT (zcar.NAME LIKE 'Both%' 
OR zcar.NAME LIKE 'Left%' 
OR zcar.NAME LIKE 'Right%' 
OR zcar.NAME LIKE 'Topical%')
AND loc.LOC_ID=10001
