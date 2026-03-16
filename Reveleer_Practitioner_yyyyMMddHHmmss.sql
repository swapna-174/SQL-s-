/*===============================================================
    COHORT: Select all BCBS (identity type 522) patients
            active in 2025 or not yet terminated.
================================================================*/
WITH COHORT AS (
    SELECT DISTINCT 
        pix.patientdurablekey
    FROM patientidentitydimx pix
    JOIN RosterAssignmentEventFact raef
        ON raef.patientdurablekey = pix.patientdurablekey
    JOIN datedim dd
        ON raef.TerminationDateKey = dd.datekey
    WHERE pix.identitytypeepicid IN (522)                 -- BCBS EPI
      AND pix.isactive = 1                                 -- Active identity
      AND (
            YEAR(dd.datevalue) = 2025 
            OR dd.datevalue >= GETDATE()                   -- Termination not passed
          )
),

/*===============================================================
    PROVIDER_COHORT:
    - Identify providers seen by patients in COHORT within 90 days
    - Extract NPI, taxonomy, name, email, practice, credentials
    - Determine employed/independent + practice flags
================================================================*/
PROVIDER_COHORT AS (
    SELECT DISTINCT
        /* ---------- Provider Identifiers ---------- */
        CASE 
            WHEN pr.NPI LIKE '*%' THEN '' 
            ELSE pr.NPI 
        END                                             AS practitioner_npi,
        
        CASE 
            WHEN pr.PrimarySpecialtyTaxonomyCode LIKE '*%' THEN '' 
            ELSE pr.PrimarySpecialtyTaxonomyCode 
        END                                             AS practitioner_type,

        /* ---------- Provider Name Parsing ---------- */
        TRIM(SUBSTRING(
            pr.Name,
            CASE 
                WHEN CHARINDEX(',', pr.Name) = 0 
                    THEN 1 
                ELSE CHARINDEX(',', pr.Name) + 1 
            END,
            LEN(pr.Name)
        ))                                              AS first_name,

        TRIM(LEFT(
            pr.Name,
            NULLIF(CHARINDEX(',', pr.Name), 0) - 1
        ))                                              AS last_name,

        /* ---------- Email Logic (Provider → Employee fallback) ---------- */
        CASE 
            WHEN LEN(pr.email) > 0 AND pr.email NOT LIKE '*%' 
                THEN pr.email
            WHEN LEN(pr.email) = 0 
                 AND pr.email NOT LIKE '*%' 
                 AND emp.email NOT LIKE '*%' 
                THEN emp.email  
            ELSE '' 
        END                                             AS email_address,

        /* ---------- Practice ID (Provider vs Dept mapping fallback) ---------- */
        CASE 
            WHEN pr.PrimaryDepartmentEpicId LIKE '*%' 
                THEN deptmap.DepartmentEpicId
            ELSE pr.PrimaryDepartmentEpicId 
        END                                             AS practice_id,

        /* ---------- Credentials ---------- */
        CASE 
            WHEN pr.ClinicianTitle LIKE '*%' THEN '' 
            ELSE pr.ClinicianTitle  
        END                                             AS credentials,

        /* ---------- Employment Status ---------- */
        CASE 
            WHEN emp.EmployeeNumber IS NULL THEN 'Independent' 
            ELSE 'Employed' 
        END                                             AS affiliation,

        /* ---------- Provider Active Flag ---------- */
        CASE 
            WHEN pr.ActiveStatus_X = 'Active' THEN 'Y' 
            ELSE 'N' 
        END                                             AS practitioner_active,

        /* ---------- Primary Practice Flag ---------- */
        CASE 
            WHEN dept.DepartmentEpicId = pr.PrimaryDepartmentEpicId THEN 'TRUE'
            ELSE 'FALSE' 
        END                                             AS primary_practice_flag,

        'ADVOCATE'                                      AS organization

    FROM COHORT c
    JOIN encounterfact enc 
        ON c.patientdurablekey = enc.patientdurablekey

    LEFT JOIN providerdim pr
        ON pr.durablekey = enc.ProviderDurableKey

    LEFT JOIN departmentdim dept
        ON enc.DepartmentKey = dept.DepartmentKey

    LEFT JOIN EmployeeDim emp
        ON pr.EmployeeDurableKey = emp.DurableKey

    /* ----- Latest Department Mapping for each provider ----- */
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

    LEFT JOIN departmentdim deptmap
        ON deptmap.DepartmentKey = deptmap_fact.DepartmentKey

    WHERE pr.IsCurrent = 1
      AND emp.IsCurrent = 1
      AND enc.date >= DATEADD(DAY, -90, CAST(GETDATE() AS DATE)) -- last 90 days
      AND pr.type <> 'Resource'                                  -- Exclude machines
      AND pr.EntityType = 'Individual'                           -- Providers only
      AND (
            IsHospitalAdmission = 1 
         OR IsInpatientAdmission = 1 
         OR IsObservation = 1 
         OR IsEdVisit = 1 
         OR IsOutpatientFaceToFaceVisit = 1
         OR IsHospitalOutpatientVisit = 1
      )
)

/*===============================================================
    FINAL SELECT
================================================================*/
SELECT DISTINCT 
    practitioner_npi,
    practitioner_type,
    CASE WHEN first_name LIKE '*%' THEN '' ELSE first_name END AS first_name,
    CASE WHEN last_name  LIKE '*%' THEN '' ELSE last_name  END AS last_name,
    email_address,
    practice_id,
    credentials,
    affiliation,
    practitioner_active,
    primary_practice_flag,
    organization
FROM PROVIDER_COHORT;