with EAP2 as 
   (
   select Max(EAPOT.CONTACT_DATE_REAL) CT_DT,
      EAPOT.PROC_ID 
   from CLARITY_EAP_OT EAPOT 
   where EAPOT.PROC_ID is not NULL 
   group by EAPOT.PROC_ID
   ), EAPOT2 as 
   (
   select Max(EAPOT.CONTACT_DATE_REAL) CT_DT,
      EAPOT.PROC_ID,
      EAPOT.CODE_TYPE_C,
      ZCT2.NAME,
      EAPOT.SHOW_HCPCS_YN 
   from CLARITY_EAP_OT EAPOT 
      left outer join ZC_CODE_TYPE ZCT2 on ZCT2.CODE_TYPE_C = EAPOT.CODE_TYPE_C 
   where EAPOT.PROC_ID is not NULL 
   group by EAPOT.PROC_ID, EAPOT.CODE_TYPE_C, ZCT2.NAME, EAPOT.SHOW_HCPCS_YN
   ), NDCINFO as 
   (
   select TX_NDC_INFORMATION.TX_ID,
      TX_NDC_INFORMATION.NDC_CODES_ID 
   from TX_NDC_INFORMATION 
   where TX_NDC_INFORMATION.LINE = 1 
   group by TX_NDC_INFORMATION.TX_ID, TX_NDC_INFORMATION.NDC_CODES_ID
   ) 
select case 
         when HTR.HSP_ACCOUNT_ID is not NULL then HTR.HSP_ACCOUNT_ID 
         else NULL 
      end as ACCOUNTNUMBER,
   case 
         when HTR.REVENUE_LOC_ID is not NULL then HTR.REVENUE_LOC_ID 
         else NULL 
      end as FACILITYCODE,
   case 
         when HTR.TX_ID is not NULL then HTR.TX_ID 
         else NULL 
      end as CHARGETRANSACTIONID,
   case 
         when DEP.DEPARTMENT_ID is not NULL then DEP.DEPARTMENT_ID 
         else NULL 
      end as DEPARTMENTCODE,
   case 
         when DEP.DEPARTMENT_NAME is not NULL then DEP.DEPARTMENT_NAME 
         else NULL 
      end as DEPARTMENTNAME,
   case 
         when EMP.USER_ID is not NULL then EMP.USER_ID 
         else NULL 
      end as USERID,
   case 
         when EMP.NAME is not NULL then EMP.NAME 
         else NULL 
      end as USERNAME,
   case 
         when HTR.SERVICE_DATE is not NULL then To_Char(Trunc(HTR.SERVICE_DATE), 'mm/dd/yyyy') 
         else NULL 
      end as SERVICEDATE,
   case 
         when HTR.TX_POST_DATE is not NULL then To_Char(Trunc(HTR.TX_POST_DATE), 'mm/dd/yyyy') 
         else NULL 
      end as POSTDATE,
   case 
         when REV.REVENUE_CODE is not NULL then REV.REVENUE_CODE 
         else NULL 
      end as REVENUECODE,
   case 
         when EAP.PROC_CODE is not NULL then EAP.PROC_CODE 
         else NULL 
      end as CHARGECODE,
   case 
         when HTR.ERX_ID is not NULL then MED.NAME 
         else case 
            when EAP.PROC_NAME is not NULL then EAP.PROC_NAME 
            else NULL 
         end 
      end as CHARGECODEDESCRIPTION,
   case 
         when HTR.TX_AMOUNT is not NULL then HTR.TX_AMOUNT 
         else NULL 
      end as CHARGEAMOUNT,
   case 
         when HTR.QUANTITY is not NULL then HTR.QUANTITY 
         else NULL 
      end as CHARGEQUANTITY,
   case 
         when HTR.HCPCS_CODE is not NULL and Length(HTR.HCPCS_CODE) = 5 then HTR.HCPCS_CODE 
         else case 
            when HTR.CPT_CODE is not NULL and Length(HTR.CPT_CODE) = 5 then HTR.CPT_CODE 
            else NULL 
         end 
      end as CPTCODE,
   case 
         when HTR.HCPCS_CODE is not NULL and Length(HTR.HCPCS_CODE) = 5 then (
         case 
               when HTR.MODIFIERS is not NULL and Instr(HTR.MODIFIERS, ',', 1) = 0 then HTR.MODIFIERS 
               when HTR.MODIFIERS is not NULL and Instr(HTR.MODIFIERS, ',', 1) <> 0 then SubStr(HTR.MODIFIERS, 1, Instr(HTR.MODIFIERS, ',', 1) - 1) 
               else NULL 
            end) 
         else case 
            when HTR.CPT_CODE is not NULL and Length(HTR.CPT_CODE) = 5 then (
            case 
                  when HTR.MODIFIERS is not NULL and Instr(HTR.MODIFIERS, ',', 1) = 0 then HTR.MODIFIERS 
                  when HTR.MODIFIERS is not NULL and Instr(HTR.MODIFIERS, ',', 1) <> 0 then SubStr(HTR.MODIFIERS, 1, Instr(HTR.MODIFIERS, ',', 1) - 1) 
                  else NULL 
               end) 
            else NULL 
         end 
      end as CPTMODIFIER1,
   case 
         when HTR.HCPCS_CODE is not NULL and Length(HTR.HCPCS_CODE) = 5 then (
         case 
               when HTR.MODIFIERS is not NULL and Instr(HTR.MODIFIERS, ',', 1) <> 0 and Instr(HTR.MODIFIERS, ',', 1, 2) = 0 then SubStr(HTR.MODIFIERS, (Instr(HTR.MODIFIERS, ',', 1) + 1), Length(HTR.MODIFIERS) - (Instr(HTR.MODIFIERS, ',', 1))) 
               when HTR.MODIFIERS is not NULL and Instr(HTR.MODIFIERS, ',', 1) <> 0 and Instr(HTR.MODIFIERS, ',', 1, 2) <> 0 then SubStr(HTR.MODIFIERS, (Instr(HTR.MODIFIERS, ',', 1) + 1), (Instr(HTR.MODIFIERS, ',', 1, 2)) - 1 - (Instr(HTR.MODIFIERS, ',', 1))) 
               else NULL 
            end) 
         else case 
            when HTR.CPT_CODE is not NULL and Length(HTR.CPT_CODE) = 5 then (
            case 
                  when HTR.MODIFIERS is not NULL and Instr(HTR.MODIFIERS, ',', 1) <> 0 and Instr(HTR.MODIFIERS, ',', 1, 2) = 0 then SubStr(HTR.MODIFIERS, (Instr(HTR.MODIFIERS, ',', 1) + 1), Length(HTR.MODIFIERS) - (Instr(HTR.MODIFIERS, ',', 1))) 
                  when HTR.MODIFIERS is not NULL and Instr(HTR.MODIFIERS, ',', 1) <> 0 and Instr(HTR.MODIFIERS, ',', 1, 2) <> 0 then SubStr(HTR.MODIFIERS, (Instr(HTR.MODIFIERS, ',', 1) + 1), (Instr(HTR.MODIFIERS, ',', 1, 2)) - 1 - (Instr(HTR.MODIFIERS, ',', 1))) 
                  else NULL 
               end) 
            else NULL 
         end 
      end as CPTMODIFIER2,
   case 
         when TXNDC.NDC_CODES_ID is not NULL then TXNDC.NDC_CODES_ID 
         else NULL 
      end as NDCNUMBER,
   NULL as IDENUMBER,
   case 
         when SER2.NPI is not NULL then SER2.NPI 
         else NULL 
      end as RENDERINGPHYSICIANNPI,
   case 
         when MED.MEDICATION_ID is not NULL then MED.MEDICATION_ID 
         else NULL 
      end as MEDICATIONID,
   case 
         when MED.NAME is not NULL then MED.NAME 
         else NULL 
      end as MEDICATION_NAME,
   case 
         when HTR.SUP_ID is not NULL then HTR.SUP_ID 
         else NULL 
      end as SUPPLYID,
   case 
         when SPLY.SUPPLY_NAME is not NULL then SPLY.SUPPLY_NAME 
         else NULL 
      end as SUPPLY_NAME 
      , DEP.RPT_GRP_SIX AS ChargeCodeType -- ADDING 9/30/2020 PER Alan Carlyle @ Waystar
from HSP_TRANSACTIONS HTR 
   left outer join CLARITY_DEP DEP on DEP.DEPARTMENT_ID = HTR.DEPARTMENT 
   left outer join CLARITY_SER_2 SER2 on SER2.PROV_ID = HTR.PERFORMING_PROV_ID 
   left outer join HSP_ACCOUNT HAR on HAR.HSP_ACCOUNT_ID = HTR.HSP_ACCOUNT_ID 
   left outer join CLARITY_EAP EAP on EAP.PROC_ID = HTR.PROC_ID 
   left outer join CL_UB_REV_CODE REV on REV.UB_REV_CODE_ID = HTR.UB_REV_CODE_ID 
   left outer join CL_UB_REV_CODE REVEAP on REVEAP.UB_REV_CODE_ID = EAP.UB_REV_CODE_ID 
   left outer join CLARITY_EMP EMP on EMP.USER_ID = HTR.USER_ID 
   left outer join ACCOUNT EAR on EAR.ACCOUNT_ID = HAR.GUARANTOR_ID 
   left outer join CLARITY_MEDICATION MED on MED.MEDICATION_ID = HTR.ERX_ID 
   left outer join CL_COST_CNTR BCC on BCC.COST_CNTR_ID = HTR.COST_CNTR_ID 
   left outer join EAP2 on EAP2.PROC_ID = EAP.PROC_ID 
   left outer join EAPOT2 on EAPOT2.PROC_ID = EAP2.PROC_ID and EAPOT2.CT_DT = EAP2.CT_DT 
   left outer join CLARITY_SER SER2 on SER2.PROV_ID = HTR.PERFORMING_PROV_ID 
   left outer join NDCINFO TXNDC on TXNDC.TX_ID = HTR.TX_ID 
   left outer join HSP_ACCT_LAST_UPDATE HARUP on HARUP.HSP_ACCOUNT_ID = HAR.HSP_ACCOUNT_ID 
   left outer join OR_SPLY SPLY on SPLY.SUPPLY_ID = HTR.SUP_ID 
where HTR.TX_ID is not NULL 
   and HTR.TX_TYPE_HA_C = 1 
   and To_Date(HARUP.INST_OF_UPDATE_DTTM, 'DD/MM/YYYY') Between To_Date(SysDate - 3, 'DD/MM/YYYY') 
   and To_Date(SysDate - 1, 'DD/MM/YYYY') 
   and EAR.ACCOUNT_TYPE_C not in ('101', '102') 
   and HAR.ACCT_FIN_CLASS_C ! = 4 
   and HAR.NUM_OF_CHARGES > 0 
-- and DEP.RPT_GRP_SIX <> '10' -- Removing per Alan Carlyle @ Waystar