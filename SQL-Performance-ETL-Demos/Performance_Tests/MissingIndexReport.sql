/*
===========================================
🚀 MissingIndexesReport.sql
-------------------------------------------
🔍 Purpose:
Identify missing index recommendations
based on actual query execution stats.

📌 Useful For:
• Performance tuning
• SQL optimization
• GitHub profiling
• ETL/data warehouse indexing
===========================================
*/

-- Optional: Show current database name
SELECT DB_NAME() AS CurrentDatabase;
GO

-- Main DMV-based report
SELECT 
    GETDATE() AS ReportGeneratedOn,
    migs.user_seeks AS [TimesIndexNeeded],
    migs.user_scans AS [ScansWithoutIndex],
    migs.avg_total_user_cost AS AvgQueryCostSaved,
    migs.avg_user_impact AS EstimatedImprovementPercent,
    CONVERT(DECIMAL(18,2), migs.avg_total_user_cost * migs.avg_user_impact / 100.0 * (migs.user_seeks + migs.user_scans)) AS EstimatedImpactScore,
    OBJECT_NAME(mid.object_id, mid.database_id) AS TableName,
    'CREATE NONCLUSTERED INDEX [IX_' + OBJECT_NAME(mid.object_id, mid.database_id) + '_' 
        + REPLACE(REPLACE(ISNULL(mid.equality_columns,''), '[', ''), ']', '') + '_'
        + REPLACE(REPLACE(ISNULL(mid.inequality_columns,''), '[', ''), ']', '') 
        + '] ON ' + mid.statement + ' (' + ISNULL(mid.equality_columns,'') 
        + CASE WHEN mid.inequality_columns IS NOT NULL THEN ',' + mid.inequality_columns ELSE '' END + ')' 
        + ISNULL(' INCLUDE (' + mid.included_columns + ')', '') 
    AS SuggestedIndexScript
FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig 
    ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid 
    ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID()  -- current database only
ORDER BY EstimatedImpactScore DESC;
GO



# 📊 Missing Indexes Report – SQL Server DMV

## 🎯 Purpose
This script helps detect **missing indexes** using **SQL Server's dynamic management views (DMVs)**. These recommendations are based on real query execution stats and estimated performance gains.

---

## 📁 File: `MissingIndexesReport.sql`

This script identifies and generates **`CREATE INDEX` suggestions** for missing indexes to help improve query speed and reduce resource consumption.

---

## 📌 Output Columns

| Column                    | Description                                       |
|---------------------------|---------------------------------------------------|
| `ReportGeneratedOn`       | Date/time the report was run                      |
| `TimesIndexNeeded`        | How many times this index would've helped         |
| `AvgQueryCostSaved`       | Average CPU/IO saved per use                      |
| `EstimatedImprovementPercent` | Estimated % performance gain                  |
| `EstimatedImpactScore`    | Combines usage frequency + cost savings           |
| `TableName`               | The table where index is recommended              |
| `SuggestedIndexScript`    | Ready-to-use `CREATE INDEX` script                |

---

## 🧠 Example Output

| TableName     | EstimatedImpactScore | SuggestedIndexScript |
|---------------|----------------------|-----------------------|
| LoanAccount   | 10830.00             | `CREATE NONCLUSTERED INDEX [IX_LoanAccount_DisburseDate_BranchID] ...` |

---

## ✅ Best Practices

- **Don't create all indexes blindly** — review query plans and index usage first.
- Prioritize indexes with **high impact scores** and **frequent use**.
- Monitor index usage via:
  ```sql
  SELECT * FROM sys.dm_db_index_usage_stats WHERE object_id = OBJECT_ID('dbo.YourTable');
