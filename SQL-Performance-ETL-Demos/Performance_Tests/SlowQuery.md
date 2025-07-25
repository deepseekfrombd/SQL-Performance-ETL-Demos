# ⚠️ Query Performance Issue: AccountTransaction Table

## 📝 Original Query

```sql
/****** Script for SelectTopNRows command from SSMS ******/
SELECT TOP (1000) 
      [id],
      [WorkingType],
      [workingId],
      [productCode],
      [AccountNo],
      [TransNo],
      [TransType],
      [SingleOrCollection],
      [TransDate],
      [TransAmount],
      [InstallmentNum],
      [AdvanceInstNum],
      [Fine],
      [FineExempted],
      [ApprovalStatus],
      [PostingStatus],
      [preparedBy],
      [checkedBy],
      [approvedBy],
      [adjustAmount],
      [interest],
      [ServiceChargExempted],
      [AccountTransfered],
      [customerId],
      [principalamount],
      [servicecharge],
      [rebate_flag],
      [branch_id],
      [working_id],
      [product_type],
      [product_id],
      [customer_id],
      [prepared_by_id],
      [checked_by_id],
      [approved_by_id],
      [collection_sheet_id],
      [account_id],
      [transMode],
      [bankName],
      [checkNo],
      [checkDate],
      [bankAccountNo],
      [refund_amount],
      [TransCatType],
      [DueAmount],
      [DueRecovery],
      [AdvanceRecovery],
      [Payable_Amount],
      [DueDays],
      [DueAmount_Principal],
      [DueRecovery_Principal],
      [AdvanceRecovery_Principal],
      [PayableAmount_Principal],
      [CumulativePayableAmount],
      [CumulativePayableAmount_Principal],
      [advanceRemaining],
      [advanceRemaining_Principal],
      [isClosingTransaction],
      [entryTime],
      [lastModifiedTime]
FROM [Practice].[dbo].[AccountTransaction]
WHERE TransDate BETWEEN '2024-01-01' AND '2024-12-31';
