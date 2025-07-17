-- Clean nulls and fix formatting
UPDATE Staging_LoanDisbursement
SET DisburseAmount = ISNULL(DisburseAmount, 0),
    AccountNo = LTRIM(RTRIM(AccountNo))
WHERE DisburseAmount IS NULL OR AccountNo IS NULL;
