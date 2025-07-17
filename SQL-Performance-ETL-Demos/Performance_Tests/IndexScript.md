# LoanAccount Table — Indexing & Performance Optimization

## Overview

This repository contains SQL scripts and best practices to improve query performance on the `LoanAccount` table, including:

- Creating non-clustered and filtered indexes  
- Index maintenance (rebuild, drop)  
- Detecting missing indexes via SQL Server DMVs  
- Sample query with performance analysis using statistics  

---

## Index Creation

### Non-Clustered Index on `DisburseDate`

```sql
CREATE NONCLUSTERED INDEX idx_DisburseDate_Include
ON dbo.LoanAccount (DisburseDate)
INCLUDE (Branch_ID, DisburseAmount);
Filtered Index for Active Accounts
sql
Copy
Edit
CREATE NONCLUSTERED INDEX idx_ActiveLoans
ON dbo.LoanAccount (Branch_ID)
WHERE AccountStatus = 'Active';
Index Maintenance
Rebuild All Indexes on LoanAccount
sql
Copy
Edit
ALTER INDEX ALL ON dbo.LoanAccount REBUILD;
Drop an Old or Unused Index (Use with caution)
sql
Copy
Edit
DROP INDEX idx_OldIndex ON dbo.LoanAccount;
Missing Indexes Detection
sql
Copy
Edit
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
Query Performance Analysis
Enable IO and Time Statistics
sql
Copy
Edit
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
Sample Query for Performance Testing
sql
Copy
Edit
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
Author
Alamgir Kabir
📧 alamgirfrombd@gmail.com
📍 Dhaka, Bangladesh

License
MIT License

bash
Copy
Edit

If you want, I can also help you generate a downloadable `README.md` file for you. Just let me know!
