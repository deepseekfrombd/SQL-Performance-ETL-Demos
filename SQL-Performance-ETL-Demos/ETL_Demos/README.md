# 🚀 ETL Job Demo – Financial Data Pipeline

This project shows a real-world ETL process using SQL Server. Data is extracted, transformed, and loaded into a data warehouse table for Power BI reporting.

## 🔄 Workflow

1. **Extract**: Loan disbursement data (2023)
2. **Transform**: Clean nulls, format fields, join with customer info
3. **Load**: Insert into data warehouse for Power BI

## 🛠️ Scripts

| Step | Script                              | Description                         |
|------|-------------------------------------|-------------------------------------|
| 1    | `ExtractLoanDisbursement.sql`       | Raw loan data extraction            |
| 2    | `CleanDisbursementData.sql`         | Remove NULLs, trim strings          |
| 2    | `MergeCustomerLoanData.sql`         | Join Customer + Loan for reporting  |
| 3    | `LoadToWarehouse.sql`               | Load cleaned data to DW             |

## 🧰 Tools Used
- SQL Server (T-SQL)
- Power BI (Dashboard Destination)
- GitHub (Version Control)

## 📊 Sample Dashboard
Power BI dashboard based on this data available here: [📁 See Dashboard.docx](../Dashboard.docx)

## 🔗 Author
**Alamgir Kabir**  
📍 Mohammadpur, Dhaka | [LinkedIn](https://www.linkedin.com/in/alamgir-kabir-247411120/)
