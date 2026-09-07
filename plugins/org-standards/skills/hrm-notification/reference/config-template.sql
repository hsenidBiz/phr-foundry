-- =====================================================================================
-- Claim column, sender parameter and the two Job Scheduler configuration rows.
--
-- Placeholders:
--   <TABLE>   source table                <CLAIM>   claim column, JSHIS_ID_<EVENT>
--   <PFX>     view name prefix            <PARAM>   HS_PR_PARAMETERS key for the sender
--   <NAME>    job display name            <SUBJECT> mail subject line
--   <HTML>    template filename only, no path
--
-- Fully idempotent: a second run prints "already exists - skipped" and errors nowhere.
-- =====================================================================================

-- 1. Claim column ----------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = '<TABLE>' AND COLUMN_NAME = '<CLAIM>'
)
BEGIN
    ALTER TABLE <TABLE> ADD <CLAIM> numeric(18) NULL;
    PRINT 'Added column <CLAIM> to <TABLE>';
END
ELSE
BEGIN
    PRINT 'Column <CLAIM> already exists - skipped';
END
GO
-- CHECK THE GUARD NAME AND THE ADD NAME MATCH CHARACTER FOR CHARACTER. A shipped sample
-- guards on JSHIS_ID_ALERT and adds JSHIS_ID_ALER; the guard passes, the wrong column is
-- created, and all four views then reference a column that does not exist.
--
-- Match the type of any claim column already on this table. numeric(18) is usual; older
-- samples use varchar(100).
--
-- BACKFILL: normally none. Leaving historic rows NULL means they all mail on the first
-- pass, which is right when the event genuinely happened and nobody was told. Stamping
-- them marks them as already notified. Decide explicitly and say which you chose.

-- 2. Sender address --------------------------------------------------------------------
--    One parameter PER JOB. Sharing a key means changing one notification's sender
--    silently changes the other's.
IF NOT EXISTS (SELECT 1 FROM HS_PR_PARAMETERS WHERE PAR_NAME = '<PARAM>')
BEGIN
    INSERT INTO HS_PR_PARAMETERS (PAR_NAME, PAR_VALUE)
    VALUES ('<PARAM>', 'hrmenterprise@hsenid.lk');
    PRINT 'Inserted HS_PR_PARAMETERS row <PARAM> - REPLACE THE PLACEHOLDER ADDRESS';
END
ELSE
BEGIN
    PRINT 'HS_PR_PARAMETERS row <PARAM> already exists - left unchanged';
END
GO
-- PAR_NAME is a varchar(50) PRIMARY KEY: an unguarded insert fails on the second run.

-- 3. Job configuration -----------------------------------------------------------------
--    Both PKs are numeric(18) NON-IDENTITY, so both values must be computed.
--    COALESCE(MAX(id) + 1, 0) for BOTH - a bare MAX(id) + 1 yields NULL against a
--    non-nullable PK on an empty table.
IF NOT EXISTS (SELECT 1 FROM HS_HR_JS_TYPE WHERE JSTYP_PENDING_VIEW_NAME = '<PFX>_PEN')
BEGIN
    DECLARE @JSMailConId numeric(18);
    DECLARE @JSTypeId    numeric(18);

    SELECT @JSMailConId = COALESCE(MAX(JSMAILCON_ID) + 1, 0) FROM HS_HR_JS_MAIL_CONFIG;
    SELECT @JSTypeId    = COALESCE(MAX(JSTYP_ID) + 1, 0)     FROM HS_HR_JS_TYPE;

    INSERT INTO HS_HR_JS_MAIL_CONFIG
        (JSMAILCON_ID, JSMAILCON_NAME, JSMAILCON_SUBJECT, JSMAILCON_ADDRESS_VIEW,
         JSMAILCON_DATA_VIEW, JSMAILCON_ISHTML_FLG, JSMAILCON_BODY_TEXT)
    VALUES
        (@JSMailConId, '<NAME>', '<SUBJECT>', '<PFX>_ADD', '<PFX>_DAT', 1, '<HTML>');

    INSERT INTO HS_HR_JS_TYPE
        (JSTYP_ID, JSTYP_NAME, JSTYP_ACTION, JSTYP_PENDING_VIEW_NAME, JSMAILCON_ID,
         JSFREQ_ID, JSTYP_ISPROCESSING_FLG, JSTYP_UPDATE_VIEW_NAME, JSTYP_ISACTIVE_FLG)
    VALUES
        (@JSTypeId, '<NAME>', 1, '<PFX>_PEN', @JSMailConId, 1, 0, '<PFX>_UPD', 1);

    PRINT 'Inserted job configuration <NAME>';
END
ELSE
BEGIN
    PRINT 'Job configuration <NAME> already exists - skipped';
END
GO
-- The guard keys on JSTYP_PENDING_VIEW_NAME, NOT on JSTYP_NAME. The view name is what
-- binds the job to the scenario; the display name can be edited in the Job Scheduler UI,
-- and a guard on it lets a re-run after a rename create a second copy of everything.
--
-- JSMAILCON_BODY_TEXT is a FILENAME ONLY - no path, not the HTML itself. The file must
-- reach the scheduler host's alert directory or the job sends an empty body AND still
-- stamps the claim column.
--
-- JSFREQ_ID: confirm the row exists rather than assuming 1.
--     SELECT JSFREQ_ID, JSFREQ_TYPE, JSFREQ_FREQUENCY, JSFREQ_DESC FROM HS_HR_JS_FREQUENCY;
--
-- JSTYP_ISACTIVE_FLG = 1 means the job runs. Set it to 0 if the client has not signed
-- the notification off yet - the rest of the configuration can ship inert.
