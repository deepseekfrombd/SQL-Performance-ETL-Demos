-- Load final result into reporting data warehouse
INSERT INTO DW_FinancialSummary (CustomerId, Gender, AccountNo, DisburseAmount, DisburseDate)
SELECT * FROM Final_Loan_Report;
