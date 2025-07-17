# LoanAccount Table — Indexing & Performance Optimization

## Overview

This repository contains SQL scripts and best practices to improve query performance on the `LoanAccount` table, including:

- Creating non-clustered and filtered indexes  
- Index maintenance (rebuild, drop)  
- Detecting missing indexes via SQL Server DMVs  
- Sample query with performance analysis using statistics  

---

## Index Creation

### Non-Clustered Index on `DisburseDate`

```sql
CREATE NONCLUSTERED INDEX idx_DisburseDate_Include
ON dbo.LoanAccount (DisburseDate)
INCLUDE (Branch_ID, DisburseAmount);


