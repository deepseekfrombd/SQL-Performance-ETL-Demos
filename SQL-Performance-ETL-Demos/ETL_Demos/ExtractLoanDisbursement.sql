-- Extract raw loan disbursement data for Jan-Dec 2023
SELECT *
INTO Staging_LoanDisbursement
FROM LoanAccount
WHERE DisburseDate BETWEEN '2023-01-01' AND '2023-12-31';
