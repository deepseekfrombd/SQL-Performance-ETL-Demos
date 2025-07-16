-- Create Clustered Index
CREATE CLUSTERED INDEX idx_LoanAccount_CustomerId ON dbo.LoanAccount (CustomerId);

-- Create Non-Clustered Index with INCLUDE
CREATE NONCLUSTERED INDEX idx_DisburseDate_Include
ON dbo.LoanAccount (DisburseDate)
INCLUDE (Branch_ID, DisburseAmount);

-- Create Filtered Index
CREATE NONCLUSTERED INDEX idx_ActiveLoans
ON dbo.LoanAccount (Branch_ID)
WHERE AccountStatus = 'Active';

-- Rebuild All Indexes
ALTER INDEX ALL ON dbo.LoanAccount REBUILD;

-- Drop Unused Index (if needed)
DROP INDEX idx_OldIndex ON dbo.LoanAccount;


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









