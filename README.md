# SQL Performance Tuning – Real-World Case Study by Alamgir Kabir

Welcome to my SQL performance tuning and ETL job demo repository. This repo showcases real-world SQL Server optimization techniques and ETL workflows that I’ve used in large-scale FinTech and microfinance systems across Bangladesh.

About Me

**Alamgir Kabir**  
Senior FinTech & Data Specialist  
 Mohammadpur, Dhaka, Bangladesh  
+8801712-706040  
✉️ alamgirfrombd@gmail.com  
🔗 [LinkedIn Profile](https://www.linkedin.com/in/alamgir-kabir-247411120/)

I’m a results-driven Finance & IT professional with **22+ years of experience**, currently leading digital financial transformation at **WAVE Foundation**. I specialize in **SQL Server performance tuning, business intelligence (Power BI), and custom ETL pipelines**, with hands-on expertise in ERP integrations, automation, and staff capacity building.

---

## What's in This Repository?

| Folder | Description |
|--------|-------------|
| `Scripts/` | SQL scripts for performance tuning, indexing, execution plan optimization |
| `ETL_Demos/` | Real-world ETL jobs using SQL Server, SSIS, and PowerShell |
| `Performance_Tests/` | Before/after comparisons, actual execution plan snapshots |
| `Resources/` | Sample datasets and configuration templates |

---

## Key Skills Demonstrated

- Query optimization using indexing, statistics, and execution plan analysis
- ETL process automation via SQL Server Agent and PowerShell
- Financial data pipeline design for Microfinance and FinTech systems
- Real-world reporting logic using stored procedures and views
- Performance audit using Dynamic Management Views (DMVs)

---

## Tools & Technologies

- **SQL Server** (views, stored procedures, indexing, tuning)
- **Power BI** (dynamic financial dashboards)
- **ASP.NET Core**, **Python**, **Tally ERP Integration**
- **SSIS**, **SQL Server Agent**, **PowerShell ETL Scripts**
- **Advanced Excel**, **Git**, **Windows Server**

---

##Sample Use Case

> **Stored Procedure Demo:**  
Track overdue loan accounts by disbursement date, aging, and outstanding amount with optimized SQL Server logic using indexed queries and joins.

```sql
EXEC usp_GetLoanOutstandingSummary 
    @DisburstartDate = '2020-04-01',
    @DisbursEndDate = '2021-07-31',
    @LoanBalanceDate = '2021-10-01';
