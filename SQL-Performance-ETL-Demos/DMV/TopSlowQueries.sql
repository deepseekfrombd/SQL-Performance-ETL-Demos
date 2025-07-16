Use SET STATISTICS
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Your Query here
SELECT * FROM Loan WHERE TransDate = '2023-07-16';

--Use DMVs to Find Top Problem Queries
  



-- Top 5 slowest queries (by average time)
SELECT TOP 5 
    qs.total_elapsed_time / qs.execution_count AS AvgElapsedTime,
    qt.text AS QueryText
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY AvgElapsedTime DESC;


-- Use Proper Indexing
CREATE NONCLUSTERED INDEX idx_TransDate
ON Loan(TransDate)
INCLUDE (LoanID, Amount);


--Avoid SELECT *

SELECT * FROM Loan WHERE TransDate = '2023-01-01';
Good:


SELECT LoanID, Amount FROM Loan WHERE TransDate = '2023-01-01';
✅ Use SARGable Conditions


WHERE YEAR(TransDate) = 2023
Good:


WHERE TransDate BETWEEN '2023-01-01' AND '2023-12-31'
✅ Keep Statistics Updated

-- Update stats for a table
UPDATE STATISTICS Loan;
✅ Rebuild or Reorganize Indexes

-- Rebuild
ALTER INDEX ALL ON Loan REBUILD;

-- Or Reorganize
ALTER INDEX ALL ON Loan REORGANIZE;
✅ Use WITH (NOLOCK) for Reports (Optional)

SELECT LoanID, Amount
FROM Loan WITH (NOLOCK)
WHERE TransDate BETWEEN '2023-01-01' AND '2023-12-31';
⚠️ Warning: You may get dirty data. Use only for read-only reports.


🎯 Microsoft Official SQL Server Performance Tuning Resources
✅ 1. Monitor and Tune for Performance (Main Guide)
এটি Microsoft-এর অফিসিয়াল গাইড যেখানে execution plans, query tuning, indexing, DMVs, এবং performance monitoring tools (like Query Store, Extended Events, Perfmon) সবকিছু বিস্তারিতভাবে আছে।

🔗 Link:
👉 https://learn.microsoft.com/en-us/sql/relational-databases/performance/monitor-and-tune-for-performance

✅ 2. Query Performance Tuning (Best Practices)
এটি Query Optimizer, Statistics, Indexing, SARGability এবং Execution Plan বিশ্লেষণের উপর ভিত্তি করে গভীরতর টিউটোরিয়াল।

🔗 Link:
👉 https://learn.microsoft.com/en-us/sql/relational-databases/performance/performance-tuning-sql-server

✅ 3. Use the Query Store to Improve Performance
Query Store ব্যবহার করে কীভাবে performance degrade খুঁজে বের করবেন এবং regressions rollback করবেন তা শেখায়।

🔗 Link:
👉 https://learn.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store

✅ 4. Database Engine Tuning Advisor (DTA)
SQL Server এর built-in tuning tool DTA নিয়ে বিস্তারিত আলোচনা—কীভাবে workload analyze করে index recommendation পাওয়া যায়।

🔗 Link:
👉 https://learn.microsoft.com/en-us/sql/tools/dta/dta-tutorial?view=sql-server-ver16

✅ 5. Performance Tuning with Dynamic Management Views (DMVs)
sys.dm_exec_query_stats, sys.dm_db_index_usage_stats এর মতো DMVs ব্যবহার করে কিভাবে সমস্যা বের করবেন তা দেখায়।

🔗 Link:
👉 https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/performance-dynamic-management-views

✅ 6. Tune Nonclustered Indexes
কিভাবে effective non-clustered indexes তৈরি করবেন, INCLUDE columns ও filtered index কিভাবে কাজ করে, সব কিছু বুঝানো হয়েছে।

🔗 Link:
👉 https://learn.microsoft.com/en-us/sql/relational-databases/indexes/nonclustered-indexes

✅ 7. Statistics in SQL Server (Important for Query Plans)
SQL Server optimizer কিভাবে statistics ব্যবহার করে—এবং outdated stats এর কারণে কী সমস্যা হয়, তা বিশ্লেষণ করে।

🔗 Link:
👉 https://learn.microsoft.com/en-us/sql/relational-databases/statistics/statistics

🧠 Bonus – Microsoft Learn Full Module:
📘 [Performance tuning and monitoring in Azure SQL and SQL Server – Learn Path]
✅ Practice-based Microsoft Learn course (Free)

🔗 https://learn.microsoft.com/en-us/training/paths/performance-tune-monitor-azure-sql/




