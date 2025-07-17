

-- 1.2 Create Non-Clustered Index on DisburseDate with included columns
CREATE NONCLUSTERED INDEX idx_DisburseDate_Include
ON dbo.LoanAccount (DisburseDate)
INCLUDE (Branch_ID, DisburseAmount);

-- 1.3 Create Filtered Index for Active Accounts
CREATE NONCLUSTERED INDEX idx_ActiveLoans
ON dbo.LoanAccount (Branch_ID)
WHERE AccountStatus = 'Active';

-- 📌 Step 2: Index Maintenance Commands

-- 2.1 Rebuild All Indexes on the LoanAccount Table
ALTER INDEX ALL ON dbo.LoanAccount REBUILD;

-- 2.2 Drop Old or Unused Index (Use only if sure)
DROP INDEX idx_OldIndex ON dbo.LoanAccount;

-- 📌 Step 3: Identify Missing Indexes (Auto-Suggest by SQL Server)
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

-- 📌 Step 4: Analyze Query Performance (Before/After Indexing)

-- 4.1 Enable Performance Statistics
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- 4.2 Test Query (You may optimize it further)
SELECT  
    [id], [AccountNo], [LoanProposalNo], [DisburseDate], [DisburseAmount],
    [CustSecurityFund], [InstServChrg], [InstCapDevLavy], [InstPrincipalAmt],
    [InstAmount], [AccountStatus], [GurName], [GurRelation], [GurAge],
    [GurAddress], [preparedBy], [checkedBy], [approvedBy], [numOfInstallment],
    [disburseAmountSC], [closedDate], [nomineeDeathDate], [InstServChrgLast],
    [InstPrincipalAmtLast], [InstAmountLast], [csfpercent], [customerId],
    [centId], [InstServChrg2ndLast], [InstPrincipalAmt2ndLast], [InstAmt2ndLast],
    [InstServChrg3rdLast], [InstPrincipalAmt3rdLast], [InstAmt3rdLast],
    [InstServChrg4thLast], [InstPrincipalAmt4thLast], [InstAmt4thLast],
    [InstServChrg5thLast], [InstPrincipalAmt5thLast], [InstAmt5thLast],
    [allow_rebate], [service_charg_id], [rebate_adjusted], [rebate_amount],
    [isFirstLoan], [branch_id], [customer_id], [working_id], [loan_proposal_id],
    [service_charge_id], [prepared_by], [checked_by], [approved_by],
    [productCode], [product_id], [LoanAccntNoCode], [MaturedDate],
    [installmentStartDate], [rebateCalculationText], [writeOff_amount],
    [loanPaymentDate], [realizableStopDate], [GurNationalId], [GurMobileNo],
    [IsMultipleDisbursement], [GurBirthDate], [GurBirthCerNo], [GurSmartId],
    [GurGender]
FROM [Practice].[dbo].[LoanAccount]
WHERE DisburseDate BETWEEN '2022-01-01' AND '2022-12-31';
