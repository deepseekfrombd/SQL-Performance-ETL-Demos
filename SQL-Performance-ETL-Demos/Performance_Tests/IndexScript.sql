--SQL Server Indexing Scripts – All Types

*** 1. Create Clustered Index
** Clustered index determines physical order of data in a table (1 per table).
      CREATE CLUSTERED INDEX idx_LoanAccount_CustomerId
      ON dbo.LoanAccount (CustomerId);
🔎 Use when:
  ## Your query mostly filters or sorts on this column
  ## The column is unique or nearly unique

*** 2. Create Non-Clustered Index
** Non-clustered indexes are separate from table data and reference the row location.
      CREATE NONCLUSTERED INDEX idx_LoanAccount_DisburseDate
      ON dbo.LoanAccount (DisburseDate);
🔎 Use when:
  ## Frequently queried by a column that's not part of primary key
  ## Want multiple indexes for different use cases

  3. Non-Clustered Index with INCLUDE Columns
  **Speeds up SELECT without needing full table or key lookups.
        CREATE NONCLUSTERED INDEX idx_LoanAccount_DisburseDate_Include
        ON dbo.LoanAccount (DisburseDate)
        INCLUDE (Branch_ID, AccountNo, DisburseAmount);
🔎 Use when:
    ## You want covering indexes for specific queries
    ## Reduce I/O and lookups
  

--Drop Index
    DROP INDEX idx_LoanAccount_DisburseDate
    ON dbo.LoanAccount;

  --Tip: Use this DMV to check unused indexes:
    SELECT *
    FROM sys.dm_db_index_usage_stats
    WHERE object_id = OBJECT_ID('dbo.LoanAccount');


  --Rebuild & Reorganize Index
    ALTER INDEX ALL ON dbo.LoanAccount REBUILD;

--Check Index Fragmentation
    SELECT 
        index_id, avg_fragmentation_in_percent, page_count
    FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.LoanAccount'), NULL, NULL, 'LIMITED')
    WHERE index_id > 0;


  --Auto Script to Suggest Missing Index
      SELECT
        migs.user_seeks,
        mid.statement,
        mid.equality_columns,
        mid.inequality_columns,
        mid.included_columns
      FROM sys.dm_db_missing_index_details AS mid
      JOIN sys.dm_db_missing_index_group_stats AS migs
        ON mid.index_handle = migs.group_handle
      ORDER BY migs.user_seeks DESC;



--Step 0: Test Query (Before Index)
-- Turn on performance stats
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Optimize Query
SELECT  [id]
      ,[AccountNo]
      ,[LoanProposalNo]
      ,[DisburseDate]
      ,[DisburseAmount]
      ,[CustSecurityFund]
      ,[InstServChrg]
      ,[InstCapDevLavy]
      ,[InstPrincipalAmt]
      ,[InstAmount]
      ,[AccountStatus]
      ,[GurName]
      ,[GurRelation]
      ,[GurAge]
      ,[GurAddress]
      ,[preparedBy]
      ,[checkedBy]
      ,[approvedBy]
      ,[numOfInstallment]
      ,[disburseAmountSC]
      ,[closedDate]
      ,[nomineeDeathDate]
      ,[InstServChrgLast]
      ,[InstPrincipalAmtLast]
      ,[InstAmountLast]
      ,[csfpercent]
      ,[customerId]
      ,[centId]
      ,[InstServChrg2ndLast]
      ,[InstPrincipalAmt2ndLast]
      ,[InstAmt2ndLast]
      ,[InstServChrg3rdLast]
      ,[InstPrincipalAmt3rdLast]
      ,[InstAmt3rdLast]
      ,[InstServChrg4thLast]
      ,[InstPrincipalAmt4thLast]
      ,[InstAmt4thLast]
      ,[InstServChrg5thLast]
      ,[InstPrincipalAmt5thLast]
      ,[InstAmt5thLast]
      ,[allow_rebate]
      ,[service_charg_id]
      ,[rebate_adjusted]
      ,[rebate_amount]
      ,[isFirstLoan]
      ,[branch_id]
      ,[customer_id]
      ,[working_id]
      ,[loan_proposal_id]
      ,[service_charge_id]
      ,[prepared_by]
      ,[checked_by]
      ,[approved_by]
      ,[productCode]
      ,[product_id]
      ,[LoanAccntNoCode]
      ,[MaturedDate]
      ,[installmentStartDate]
      ,[rebateCalculationText]
      ,[writeOff_amount]
      ,[loanPaymentDate]
      ,[realizableStopDate]
      ,[GurNationalId]
      ,[GurMobileNo]
      ,[IsMultipleDisbursement]
      ,[GurBirthDate]
      ,[GurBirthCerNo]
      ,[GurSmartId]
      ,[GurGender]
FROM [Practice].[dbo].[LoanAccount]
WHERE DisburseDate BETWEEN '2022-01-01' AND '2022-12-31';









