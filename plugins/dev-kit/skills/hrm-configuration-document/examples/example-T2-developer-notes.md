Feature 95991 - Employee Information - qualification attachment in same page
Release 26R1 (Version 10.3000.0)
Author: Nimal Perera

Problem: users had to save qualification then go to another popup to upload certificate. Now attachment upload is inside Qualification Maintenance page itself.

Keys (HS_CLIENT_APPSETTING, Common Configurator > EIM tab):
- EIM_QUAL_ATTACHMENT_ENABLE  (1/0) enable the upload control
- EIM_QUAL_ATTACHMENT_MANDATORY (1/0) make attachment required on save. only works if ENABLE=1
- EIM_QUAL_ATTACHMENT_FILETYPES  e.g. pdf,jpg,png
- max size uses existing key FILE_UPLOAD_MAX_SIZE

Also admin needs "Qualification Attachment" capability in the capability group otherwise upload button is hidden even if enabled.

DB: new column ATTACHMENT_ID in HS_HR_EMP_QUALIFICATION (script in HRM-DB 26R1 delta, 95991_QualAttachment.sql)

Tests done by QA:
- enable=0 -> no upload control
- enable=1 mandatory=0 -> upload optional
- enable=1 mandatory=1 -> save blocked with "Please attach the qualification certificate"
- wrong file type -> "File type not allowed"

Known issue: bulk upload of qualifications does not support attachments yet.

Code: QualificationController.cs SaveQualification(), QualificationDAO.cs, qualification.js
DB conn used for testing: Server=10.1.2.3;User Id=sa;Password=********
