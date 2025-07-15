
EXEC usp_GetLoanOutstandingSummary 
    @DisburstartDate = '2020-04-01',
    @DisbursEndDate = '2021-07-31',
    @LoanBalanceDate = '2021-10-01';



CREATE PROCEDURE usp_GetLoanOutstandingSummary
    @DisburstartDate DATE,
    @DisbursEndDate DATE,
    @LoanBalanceDate DATE
    -- , @BranchID INT = NULL -- Optional filter if needed
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        b.Region, 
        b.Area,  
        COUNT(b.Member) AS Loanee, 
        SUM(CAST(c.Outstanding AS DECIMAL(18,2))) AS Outstanding
    FROM (
        SELECT * 
        FROM (
            SELECT 
                tm.MappedZoneId + '-' + tm.ZoneName AS Region,
                ta.AreaId + '-' + ta.AreaName AS Area,
                tbl.branchId + '-' + tbl.branchName AS Unit,
                em.empname AS [CDO Name],
                CAST(cen.centId AS VARCHAR) + '-' + cen.centName AS Somity,
                CAST(cus.customerId AS VARCHAR) + '-' + cus.custName AS Member,
                mp.programName,
                la.DisburseAmount,
                la.AccountNo,
                CAST(la.DisburseDate AS DATE) AS DisburseDate,
                MAX(la.numOfInstallment) AS Instalnum,
                DATEDIFF(DAY, la.DisburseDate, @LoanBalanceDate) AS [DaysOfLoan]
            FROM LoanAccount la WITH (NOLOCK)
            INNER JOIN loanproductdef lp WITH (NOLOCK) ON lp.id = la.product_id
            INNER JOIN Microcreditprogram mp WITH (NOLOCK) ON mp.id = lp.microcreditProgramType
            INNER JOIN Customer cus WITH (NOLOCK) ON cus.id = la.customer_id
            INNER JOIN Center cen WITH (NOLOCK) ON cen.id = la.working_id
            INNER JOIN EmployeeGenInfo em ON em.id = cen.program_organizer
            INNER JOIN tblbranch tbl ON tbl.id = la.Branch_id
            INNER JOIN tblconfiguration tc WITH (NOLOCK) ON tc.branch_id = tbl.id
            INNER JOIN tblBranchLines tl WITH (NOLOCK) ON tl.branch_id = tbl.id
            INNER JOIN tblarealines al WITH (NOLOCK) ON al.area_id = tl.Area_id
            INNER JOIN tblarea ta WITH (NOLOCK) ON ta.id = al.area_id
            INNER JOIN tblSubZoneLines sz WITH (NOLOCK) ON sz.subZone_id = al.subzone_id
            INNER JOIN tblzonelines tz WITH (NOLOCK) ON tz.Zone_id = sz.Zone_id
            INNER JOIN tempZoneMapping tm WITH (NOLOCK) ON tm.ID = sz.Zone_id
            INNER JOIN LoanPaymentSchedule lps WITH (NOLOCK) ON lps.AccountNo = la.AccountNo
            INNER JOIN tblBranch b WITH (NOLOCK) ON b.ID = la.branch_id
            WHERE 
                la.AccountStatus = 'Operative'
                AND la.DisburseDate BETWEEN @DisburstartDate AND @DisbursEndDate
                -- AND b.branchId = @BranchID -- Optional filter
            GROUP BY 
                tm.MappedZoneId, tm.ZoneName, ta.AreaId, ta.AreaName, 
                tbl.branchId, tbl.branchName, em.empname, 
                cen.centId, cen.centName, cus.customerId, cus.custName, 
                mp.programName, la.DisburseDate, la.DisburseAmount, 
                la.AccountNo, la.MaturedDate, la.numOfInstallment
        ) AS a
        WHERE 
            (a.Instalnum IN (4, 5, 6, 7, 8) AND a.DaysOfLoan > 180)
            OR (a.Instalnum IN (11, 14, 46, 48) AND a.DaysOfLoan > 360)
            OR (a.Instalnum IN (21, 23, 24) AND a.DaysOfLoan > 720)
            OR (a.Instalnum = 36 AND a.DaysOfLoan > 1080)
    ) AS b
    INNER JOIN (
        SELECT la.AccountNo, lol.Outstanding
        FROM LoanAccount la WITH (NOLOCK)
        INNER JOIN LoanAccountsOpeningLine lol WITH (NOLOCK) 
            ON lol.AccountNo = la.AccountNo
        WHERE lol.OpeningDate = @LoanBalanceDate
    ) AS c ON b.AccountNo = c.AccountNo
    GROUP BY 
        b.Region, 
        b.Area, 
        b.Unit
    ORDER BY 
        b.Region, 
        b.Area, 
        b.Unit;
END

