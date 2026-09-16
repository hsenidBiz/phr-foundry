-- =====================================================================================
-- The four notification views.
--
-- Replace the placeholders:
--   <PFX>        view name prefix, e.g. VW_HS_HR_ELC_TREQ_HRACK   (+ client suffix if used)
--   <TABLE>      source table, e.g. HS_HR_ELC_TREQ
--   <PK>         its primary key, becomes JS_ID
--   <CLAIM>      claim column, e.g. JSHIS_ID_HR_ACKNOW
--   <PARAM>      HS_PR_PARAMETERS key holding the FROM address
--   <WHERE>      the shared predicate - SEE BELOW
--
-- <WHERE> IS WRITTEN ONCE AND PASTED FOUR TIMES, UNCHANGED. It appears five times below
-- (twice in _ADD, once each elsewhere). If you edit one, edit all of them, then run the
-- predicate check in SKILL.md section 6 - drift here fails silently.
--
--   WHERE <flag col> = '1' AND <CLAIM> IS NULL
--
-- Compare varchar flags to STRINGS. '<flag> = 1' makes SQL Server convert the column to
-- int and throw on the first non-numeric value ever stored.
-- =====================================================================================

-- 1. PENDING - which rows the job should act on -----------------------------------------
IF OBJECT_ID('<PFX>_PEN') IS NOT NULL DROP VIEW <PFX>_PEN;
GO
CREATE VIEW <PFX>_PEN
AS
SELECT <PK> AS JS_ID
FROM <TABLE>
WHERE <flag col> = '1' AND <CLAIM> IS NULL;
GO
PRINT 'Created view <PFX>_PEN';
GO

-- 2. ADDRESS - who the mail goes to -----------------------------------------------------
--    TYPE must be exactly 'FROM' or 'TO'. The FROM row is a scalar subquery so it yields
--    exactly one address regardless of joins.
IF OBJECT_ID('<PFX>_ADD') IS NOT NULL DROP VIEW <PFX>_ADD;
GO
CREATE VIEW <PFX>_ADD
AS
SELECT (SELECT PAR_VALUE FROM HS_PR_PARAMETERS WHERE PAR_NAME = '<PARAM>') AS ADDRESS,
       'FROM' AS TYPE,
       <PK> AS JS_ID
FROM <TABLE>
WHERE <flag col> = '1' AND <CLAIM> IS NULL
UNION ALL
SELECT E.EMP_OFFICE_EMAIL AS ADDRESS,
       'TO' AS TYPE,
       T.<PK> AS JS_ID
FROM <TABLE> T
INNER JOIN HS_HR_EMPLOYEE E ON E.EMP_NUMBER = T.EMP_NUMBER
WHERE <flag col> = '1' AND <CLAIM> IS NULL;
GO
PRINT 'Created view <PFX>_ADD';
GO
-- Pick the recipient from the REQUIREMENT, not from whichever sample you copied.
--   requesting employee  ->  T.EMP_NUMBER                       (most common)
--   current approver     ->  HS_HR_WF_MAIN.WFMAIN_APPROVING_EMP_NUMBER
--   a fixed HR mailbox   ->  a second HS_PR_PARAMETERS scalar, TYPE 'TO'
-- The recipient join stays INNER: no employee row means no address, and dropping the row
-- from every view leaves the claim NULL so it is retried rather than marked sent.
-- Add 'CC' rows the same way if the scheduler build in use supports them - verify first.

-- 3. DATA - the merge fields ------------------------------------------------------------
--    One column per @TOKEN in the HTML, named identically. JS_ID is the join key and is
--    not a token.
IF OBJECT_ID('<PFX>_DAT') IS NOT NULL DROP VIEW <PFX>_DAT;
GO
CREATE VIEW <PFX>_DAT
AS
SELECT T.<PK> AS JS_ID,
       E.EMP_DISPLAY_NAME,
       E.EMP_DISPLAY_NUMBER,
       COALESCE(H.HIE_NAME, '-') AS BRANCH_NAME,
       CONVERT(varchar, T.<some date col>, 103) AS SOME_DATE
FROM <TABLE> T
INNER JOIN HS_HR_EMPLOYEE E ON E.EMP_NUMBER = T.EMP_NUMBER
LEFT OUTER JOIN HS_HR_COMPANY_HIERARCHY H ON H.HIE_CODE = T.<branch col>
WHERE <flag col> = '1' AND <CLAIM> IS NULL;
GO
PRINT 'Created view <PFX>_DAT';
GO
-- Dates are formatted HERE, not by the scheduler. Style 103 = dd/MM/yyyy.
-- Optional joins are LEFT + COALESCE: an unmatched lookup must not drop the row out of
-- _DAT while it remains in the other three.

-- 4. UPDATE - the write-back that closes the loop ---------------------------------------
IF OBJECT_ID('<PFX>_UPD') IS NOT NULL DROP VIEW <PFX>_UPD;
GO
CREATE VIEW <PFX>_UPD
AS
SELECT <PK> AS JS_ID, <CLAIM> AS JSHIS_ID
FROM <TABLE>
WHERE <flag col> = '1' AND <CLAIM> IS NULL;
GO
PRINT 'Created view <PFX>_UPD';
GO
-- The column alias MUST be JSHIS_ID. This is the view the scheduler writes through to
-- stamp the claim column; a different alias means the claim is never set and the same
-- row mails on every pass.
