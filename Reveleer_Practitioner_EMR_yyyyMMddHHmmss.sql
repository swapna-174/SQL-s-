/* ================================================================
   COHORT:
   ----------------------------------------------------------------
   Build list of BCBS (identity_type 522) patients who:
       - Have an active identity
       - Are active in program year 2025 OR have a future termination date
   ================================================================ */
WITH COHORT AS (
    SELECT DISTINCT
        pix.patientdurablekey
    FROM patientidentitydimx AS pix
    JOIN RosterAssignmentEventFact AS raef
        ON raef.patientdurablekey = pix.patientdurablekey
    JOIN datedim AS dd
        ON raef.TerminationDateKey = dd.datekey
    WHERE pix.identitytypeepicid IN (522)                 -- BCBS identity type
      AND pix.isactive = 1                                 -- Active identity record
      AND (
            YEAR(dd.datevalue) = 2025 
            OR dd.datevalue >= GETDATE()                  -- Not yet terminated
          )
),

/* ================================================================
   PROVIDER_EMR_COHORT:
   ----------------------------------------------------------------
   Providers associated to encounters for patients in COHORT
   within the last 90 days who:
       - Are Individuals (not resources)
       - Are current providers
       - Have valid NPI
       - Have non-"*Not Applicable" ProviderEpicId
   Extract:
       - Practitioner NPI
       - Practitioner Identifier (ProviderEpicId)
       - EMR Department ID (with fallback)
       - Department Name (alias)
       - Organization
   ================================================================ */
PROVIDER_EMR_COHORT AS (
    SELECT DISTINCT
        /* ---------- Practitioner NPI ---------- */
        CASE 
            WHEN pr.NPI LIKE '*%' THEN '' 
            ELSE pr.NPI 
        END AS practitioner_npi,

        /* ---------- Practitioner Identifier (Epic ID) ---------- */
        CASE 
            WHEN pr.ProviderEpicId LIKE '*%' THEN '' 
            ELSE pr.ProviderEpicId 
        END AS practitioner_identifier,

        /* ---------- EMR Department ID (use mapping if masked) ---------- */
        CASE 
            WHEN pr.PrimaryDepartmentEpicId LIKE '*%' 
                THEN deptmap.DepartmentEpicId
            ELSE pr.PrimaryDepartmentEpicId 
        END AS emr_department_id,

        /* ---------- Department Name Alias (fallback to mapping if masked) ---------- */
        CASE 
            WHEN PrimaryDepartment LIKE '*%' 
                THEN deptmap.DepartmentName
            ELSE PrimaryDepartment 
        END AS emr_department_id_alias,

        /* ---------- Organization ---------- */
        'ADVOCATE' AS organization

    FROM COHORT c
    JOIN encounterfact enc
        ON c.PatientDurableKey = enc.PatientDurableKey

    LEFT JOIN Providerdim AS pr
        ON pr.DurableKey = enc.ProviderDurableKey

    LEFT JOIN departmentdim AS dept
        ON enc.DepartmentKey = dept.DepartmentKey

    /* Most recent department mapping for provider */
    LEFT JOIN (
        SELECT 
            providerdurablekey,
            DepartmentKey,
            ROW_NUMBER() OVER (
                PARTITION BY providerdurablekey
                ORDER BY _lastupdatedInstant DESC
            ) AS rank_within_category
        FROM ProviderDepartmentMappingFact
    ) deptmap_fact
        ON enc.ProviderDurableKey = deptmap_fact.providerdurablekey
       AND deptmap_fact.rank_within_category = 1

    LEFT JOIN departmentdim AS deptmap
        ON deptmap.DepartmentKey = deptmap_fact.DepartmentKey

    WHERE pr.IsCurrent = 1                                 -- Active snapshot
      AND enc.date >= DATEADD(DAY, -90, CAST(GETDATE() AS DATE))   -- Last 90 days
      AND pr.type <> 'Resource'                            -- Exclude machines
      AND pr.EntityType = 'Individual'                     -- Human providers only
      AND (
             IsHospitalAdmission = 1
          OR IsInpatientAdmission = 1
          OR IsObservation = 1
          OR IsEdVisit = 1
          OR IsOutpatientFaceToFaceVisit = 1
          OR IsHospitalOutpatientVisit = 1
      )
      AND pr.ProviderEpicId <> '*Not Applicable'           -- Valid Epic ID
      AND LEN(pr.NPI) > 0                                  -- Must have NPI
)

/* ================================================================
   FINAL SELECT
   ----------------------------------------------------------------
   Output EMR provider-level cohort for reporting
   ================================================================ */
SELECT *
FROM PROVIDER_EMR_COHORT;