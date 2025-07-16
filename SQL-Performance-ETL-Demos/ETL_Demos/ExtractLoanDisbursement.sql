-- Extract raw loan disbursement data for Jan-Dec 2023
SELECT *
INTO Staging_LoanDisbursement
FROM LoanDisbursement
WHERE DisbursementDate BETWEEN '2023-01-01' AND '2023-12-31';
