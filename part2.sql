
USE [msdb]
GO
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Daily Index Defrag')
EXEC msdb.dbo.sp_delete_job @job_name=N'Daily Index Defrag', @delete_unused_schedule=1
GO

PRINT 'Creating Daily Index Maintenance job';
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Daily Index Defrag', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=3, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Inteligent defrag on one or more indexes for one or more databases.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'<Admin>', 
		--@notify_email_operator_name=N'SQLAdmins', 
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DB Exceptions', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @dbname NVARCHAR(128)
DECLARE curDB CURSOR FOR SELECT name 
	FROM sys.databases WHERE ([name] IN (	
	--Semantic Search
	''Semanticsdb'',
	''SSODB'',''BAMAnalysis'',''BAMArchive'',''BAMAlertsApplication'',''BAMAlertsNSMain'',''BAMPrimaryImport'',''BAMStarSchema'',''BizTalkMgmtDb'',''BizTalkMsgBoxDb'',''BizTalkDTADb'',''BizTalkRuleEngineDb'',
	''BAMPrimaryImport'',''BizTalkEDIDb'',''BizTalkHwsDb'',''TPM'',''BizTalkAnalysisDb'',
	''BAMPrimaryImportsuccessfully'',
	''SSO'',''WSS_Search'',''WSS_Search_Config'',''SharedServices_DB'',''SharedServices_Search_DB'',''WSS_Content'')
	OR [name] LIKE ''WSS_Search%''
	OR [name] LIKE ''SharedServices_DB%''
	OR [name] LIKE ''SharedServices_Search_DB%''
	OR [name] LIKE ''SharedServices__DB%''
	OR [name] LIKE ''SharedServices__Search_DB%''
	OR [name] LIKE ''SharedServicesContent%''
	OR [name] LIKE ''Secure_Store_Service_DB_%'' 
	OR [name] LIKE ''StateService%''
	OR [name] LIKE ''WebAnalyticsServiceApplication_StagingDB_%''
	OR [name] LIKE ''WebAnalyticsServiceApplication_ReportingDB_%''
	OR [name] LIKE ''Search_Service_Application_DB_%''
	OR [name] LIKE ''Search_Service_Application_CrawlStoreDB_%''
	OR [name] LIKE ''Search_Service_Application_PropertyStoreDB_%''
	OR [name] LIKE ''User Profile Service Application_ProfileDB_%''
	OR [name] LIKE ''User Profile Service Application_SyncDB_%''
	OR [name] LIKE ''User Profile Service Application_SocialDB_%''
	OR [name] LIKE ''Managed Metadata Service_%''
	OR [name] LIKE ''WordAutomationServices_%''
	OR [name] LIKE ''SharePoint_Admin_Content%''
	OR [name] LIKE ''AppManagement%''
	OR [name] LIKE ''Search_Service_Application_AnalyticsReportingStoreDB_%''
	OR [name] LIKE ''Search_Service_Application_LinkStoreDB_%''
	OR [name] LIKE ''Secure_Store_Service_DB_%''
	OR [name] LIKE ''SharePoint_Logging_%''
	OR [name] LIKE ''SettingsServiceDB%''
	OR [name] LIKE ''SharePoint_Logging_%''
	OR [name] LIKE ''Managed Metadata Service Application_Metadata_%''
	OR [name] LIKE ''SharePoint Translation Services_%''
	OR [name] LIKE ''SessionStateService%''
	OR [name] LIKE ''SharePoint_Config%'' 
	OR [name] LIKE ''SharePoint_AdminContent%''
	OR [name] LIKE ''WSS_Content%''
	OR [name] LIKE ''WSS_UsageApplication%''
	OR [name] LIKE ''Bdc_Service_DB_%''
	OR [name] LIKE ''Application_Registry_server_DB_%''
	OR [name] LIKE ''SubscriptionSettings_%''
	OR [name] LIKE ''SharePoint_AdminContent%''
	OR [name] LIKE ''FASTSearchAdminDatabase%''
)
	AND database_id NOT IN (SELECT DISTINCT(dbID) FROM MaintenanceOS.dbo.tbl_AdaptiveIndexDefrag_Exceptions)	AND database_id > 5
OPEN curDB
FETCH NEXT FROM curDB INTO @dbname
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT ''Excluding '' + @dbname
	EXEC MaintenanceOS.dbo.usp_AdaptiveIndexDefrag_Exceptions @exceptionMask_DB = @dbname, @exceptionMask_days = NULL
	FETCH NEXT FROM curDB INTO @dbname
END
CLOSE curDB
DEALLOCATE curDB', 
		@database_name=N'msdb', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Exec', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=3, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC MaintenanceOS.dbo.usp_AdaptiveIndexDefrag @onlineRebuild = 1, @sortInTempDB = 1, @maxDopRestriction = 2', 
		@database_name=N'msdb', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Purge Log', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE MaintenanceOS.dbo.usp_AdaptiveIndexDefrag_PurgeLogs;', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily Index Defrag', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20110629, 
		@active_end_date=99991231, 
		@active_start_time=230000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

PRINT 'Daily Index Maintenance job created';
GO