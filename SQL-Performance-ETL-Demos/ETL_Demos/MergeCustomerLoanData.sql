-- Merge Customer + Disbursement into final table
SELECT 
    c.CustomerId,
    c.Gender,
    l.AccountNo,
    l.DisburseAmount,
    l.DisburseDate
INTO Final_Loan_Report
FROM Customer c
JOIN Staging_LoanDisbursement l ON c.CustomerID = l.CustomerID;


Select * FROM Final_Loan_Report
