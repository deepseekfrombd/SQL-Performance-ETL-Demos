USE [IMFAS-ERP]
GO
/****** Object:  User [alamgir]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [alamgir] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [erp_au]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [erp_au] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [Region1]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [Region1] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [Region10]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [Region10] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [Region2]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [Region2] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [Region3]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [Region3] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [Region4]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [Region4] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [Region5]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [Region5] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [Region6]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [Region6] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [Region7]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [Region7] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [Region8]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [Region8] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [Region9]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [Region9] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [ruser]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [ruser] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [ShahabUddin]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE USER [ShahabUddin] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  DatabaseRole [mdw_admin]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE ROLE [mdw_admin]
GO
/****** Object:  DatabaseRole [mdw_reader]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE ROLE [mdw_reader]
GO
/****** Object:  DatabaseRole [mdw_writer]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE ROLE [mdw_writer]
GO
/****** Object:  DatabaseRole [UtilityMDWCacheReader]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE ROLE [UtilityMDWCacheReader]
GO
/****** Object:  DatabaseRole [UtilityMDWWriter]    Script Date: 16-Jul-25 8:23:54 AM ******/
CREATE ROLE [UtilityMDWWriter]
GO
ALTER ROLE [db_owner] ADD MEMBER [erp_au]
GO
ALTER ROLE [db_datareader] ADD MEMBER [ruser]
GO
ALTER ROLE [mdw_writer] ADD MEMBER [mdw_admin]
GO
ALTER ROLE [mdw_reader] ADD MEMBER [mdw_admin]
GO
ALTER ROLE [mdw_writer] ADD MEMBER [UtilityMDWWriter]
GO
/****** Object:  Schema [core]    Script Date: 16-Jul-25 8:23:55 AM ******/
CREATE SCHEMA [core]
GO
/****** Object:  Schema [custom_snapshots]    Script Date: 16-Jul-25 8:23:55 AM ******/
CREATE SCHEMA [custom_snapshots]
GO
/****** Object:  Schema [snapshots]    Script Date: 16-Jul-25 8:23:55 AM ******/
CREATE SCHEMA [snapshots]
GO
/****** Object:  Schema [sysutility_ucp_core]    Script Date: 16-Jul-25 8:23:55 AM ******/
CREATE SCHEMA [sysutility_ucp_core]
GO
/****** Object:  Schema [sysutility_ucp_misc]    Script Date: 16-Jul-25 8:23:55 AM ******/
CREATE SCHEMA [sysutility_ucp_misc]
GO
/****** Object:  Schema [sysutility_ucp_staging]    Script Date: 16-Jul-25 8:23:55 AM ******/
CREATE SCHEMA [sysutility_ucp_staging]
GO
/****** Object:  DdlTrigger [add_operator_check]    Script Date: 16-Jul-25 8:23:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [add_operator_check]
ON DATABASE
WITH EXECUTE AS 'mdw_check_operator_admin'
FOR CREATE_TABLE 
AS 
BEGIN
    DECLARE @schema_name sysname;
    DECLARE @table_name sysname;

    -- Set options required by the rest of the code in this SP.
    SET ANSI_NULLS ON
    SET ANSI_PADDING ON
    SET ANSI_WARNINGS ON
    SET ARITHABORT ON
    SET CONCAT_NULL_YIELDS_NULL ON
    SET NUMERIC_ROUNDABORT OFF
    SET QUOTED_IDENTIFIER ON 


    SELECT @schema_name = EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]', 'sysname')
    IF (@schema_name = N'custom_snapshots')
    BEGIN
        SELECT @table_name = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname')

        -- Dynamically add a constraint on the newly created table
        -- Table must have the snapshot_id column
        DECLARE @check_name sysname;
        SELECT @check_name = N'CHK_check_operator_' + CONVERT(nvarchar(36), NEWID());
        DECLARE @sql nvarchar(2000);
        SELECT @sql = N'ALTER TABLE ' + QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name) +
                      N' ADD CONSTRAINT ' + QUOTENAME(@check_name) + ' CHECK (core.fn_check_operator(snapshot_id) = 1);';

        -- We dont expect any result set returned while executing ALTER TABLE statement in Dynamic SQL
        EXEC(@sql)
        WITH RESULT SETS NONE
        
        -- Dynamically revoke the CONTROL right on the table for mdw_writer
        -- That way mdw_writer creates the table but cannot remove it or alter it
        SELECT @sql = N'DENY ALTER ON ' + QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name) +
                      N'TO [mdw_writer]';

        -- We dont expect any result set returned while executing DENY statement in Dynamic SQL
        EXEC(@sql)
        WITH RESULT SETS NONE
    END
END;
GO
DISABLE TRIGGER [add_operator_check] ON DATABASE
GO
/****** Object:  DdlTrigger [deny_drop_table]    Script Date: 16-Jul-25 8:23:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [deny_drop_table]
ON DATABASE
FOR DROP_TABLE 
AS 
BEGIN
    -- Security check (role membership)
    IF (NOT (ISNULL(IS_MEMBER(N'mdw_admin'), 0) = 1) AND NOT (ISNULL(IS_SRVROLEMEMBER(N'sysadmin'), 0) = 1))
    BEGIN
        RAISERROR(14677, 16, -1, 'mdw_admin');
    END;
END;
GO
DISABLE TRIGGER [deny_drop_table] ON DATABASE
GO
ENABLE TRIGGER [add_operator_check] ON DATABASE
GO
ENABLE TRIGGER [deny_drop_table] ON DATABASE
GO
