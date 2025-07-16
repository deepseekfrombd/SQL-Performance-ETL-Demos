USE [ST-RMS]
GO
/****** Object:  StoredProcedure [dbo].[ConsCreateViewConsolidateTrialBalance]    Script Date: 16-Jul-25 8:22:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ConsCreateViewConsolidateTrialBalance]  
@branch_id nvarchar(MAX),@branchid nvarchar(MAX), @periodStartDate DateTime,@periodEndDate DateTime , @sessionId varchar(100) 
AS  
BEGIN  
    Exec ('If object_ID(''ConsolidateTrialBalance'+@sessionId+''',''V'') is not null   
            drop view ConsolidateTrialBalance'+@sessionId+';')  
    EXEC ('  
CREATE VIEW ConsolidateTrialBalance'+@sessionId+'  
AS  

select areainfo.AreaId,areainfo.areaname +''-''+areainfo.AreaId areaname,d.accDesc,a.pDesc,(a.drAmount+a.drprevAmount) drAmount,(a.crAmount+a.crprevAmount) crAmount,(a.drAmount+a.drprevAmount)-(a.crAmount+a.crprevAmount) Amount  from 
(
SELECT tb.branch_id ,tb.id,accDesc,autoAccCode,accountType,pGroupId,pLevelId,pDesc,groupId,levelId,accId,manualAccCode, SUM(drAmount) drAmount,SUM(crAmount*-1) crAmount,   
SUM(case when openingAmount > 0 then openingAmount else 0 end) drprevAmount ,SUM(case when openingAmount < 0 then openingAmount*-1 else 0 end) crprevAmount   
FROM   
(  
 SELECT a.branch_id,ch.id,CASE ch.accountType WHEN 2 THEN 1 ELSE ch.accountType END AS accountType, ch.accDesc,ch.autoAccCode,pa.groupId as pGroupId, pa.levelId as pLevelId, pa.accdesc as pDesc, ch.groupId,ch.levelId,ch.accId,ch.manualAccCode,   
 SUM(case when amount> 0 then amount else 0 end) drAmount,SUM(case when amount< 0 then amount else 0 end) crAmount,  
 sum(openingAmount)openingAmount  
 FROM   
 (  
  select branch_id,voucherno, voucherdate, accdesc, autoAccCode,groupId, levelId, accId, auto_acc_id,  
  manualAccCode,amount , 0 as openingAmount  
  from  viewAllApprovedVoucher_pre WHERE autoAccCode NOT IN (select autoAccCode from tblAccount where profitLoss = 1 or packageid<>1)   
  and voucherdate between ''' + @periodStartDate + ''' and ''' + @periodEndDate + '''  
  UNION ALL  
  select o.branch_id,''opening'',o.periodenddate,c.accDesc,c.autoAccCode,c.groupId,c.levelId,c.accId,o.auto_acc_id,  
  c.manualAccCode,0 as amount, o.openingamount as openingAmount  
  from tblOpening o   
  INNER JOIN viewAllChildChartOfAccounts c ON o.auto_acc_id = c.id  and o.periodstartdate = ''' + @periodStartDate + '''  
  and c.transactionStatus = 0  
  and o.packageid=1  
 ) a  
 INNER JOIN tblParentChildReport pc on a.auto_acc_id = pc.child_auto_acc_id   
 INNER JOIN tblAccount pa on pa.id = pc.parent_auto_acc_id  
 INNER JOIN tblAccount ch on ch.id = pc.child_auto_acc_id  
 inner join  func_TempBranchLines('''+@periodEndDate + ''') b on a.branch_id = b.branch_id  
 '+ @branch_id +'  
 group by ch.accountType, ch.accdesc,ch.autoAccCode,pa.groupId,pa.levelId, pa.accdesc,ch.groupId,ch.levelId,ch.accId,ch.manualAccCode,ch.id,a.branch_id  
)tb  
group by accountType,accDesc,autoAccCode,pGroupId,pLevelId,pDesc,groupId,levelId,accId,manualAccCode,tb.id ,tb.branch_id 
  
--------------------------  
  
union all  
  
    select o.branch_id,a.id,''Fund Adjustment'' as cDesc,a.autoAccCode as cCode,a.accountType, pc.parentGroupId, pc.parentLevelId,ap.accdesc as pDesc, a.groupId,a.levelId,a.accId,    
 a.manualAccCode,0 drAmount,0 crAmount,0 drprevAmount,0 crprevAmount  
    from  tblOpening o with (NOLOCK)    
    inner join tblAccount a with (NOLOCK) on a.id = o.auto_acc_id    
    inner join tblParentChildReport pc with (NOLOCK) on o.auto_acc_id = pc.child_auto_acc_id    
    inner join tblAccount ap with (NOLOCK) on ap.id = pc.parent_auto_acc_id    
    where a.accStatus = 0 and  o.periodStartDate = ''' + @periodStartDate + '''  and a.profitLoss = 1     
    and a.packageId=1    
 and o.branch_id in('+@branchid+')  
   
--------------------------  
)a
 		---------corporate----------
	inner join
	(
		select b.id,a.accdesc from tblAccount b 
		inner join 
		( 
			select  id,accdesc  from tblAccount where  controlLevel_id=''00000000-0000-0000-0000-000000000000'' and controlLevelId=0 and packageId=1 and transactionStatus=0
		) a on a.id=b.corporrate_id
	) d on a.id=d.id

	---------------

	
	inner join 

(select a.areaname,a.AreaId,b.branch_id from tblArea a 
inner join tblBranchLines b on a.AreaId=b.AreaId
inner join tblBranch c on b.branch_id=c.ID) areainfo
on a.branch_id=areainfo.branch_id

where (a.drAmount+a.drprevAmount)-(a.crAmount+a.crprevAmount)<>0

'   
)  

END 


GO
/****** Object:  StoredProcedure [dbo].[ConsCreateViewReceiptsAndPayments]    Script Date: 16-Jul-25 8:22:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ConsCreateViewReceiptsAndPayments]
@branch_id nvarchar(MAX), @periodStartDate DateTime, @periodEndDate DateTime,  @sessionId varchar(100),@acountvoucherType int=1,
@packageId int 
AS
BEGIN
declare @periodMonth int,@yearStartDate date
SELECT @periodMonth = MONTH(@periodStartDate) 
	--print @startDate
	if @periodMonth <= 6
		SET @yearStartDate = CAST(CAST(YEAR(@periodStartDate) - 1 AS varchar) + '-' + CAST(7 AS varchar) + '-' + CAST(01 AS varchar) AS DATETIME)
	else 
		SET @yearStartDate = CAST(CAST(YEAR(@periodStartDate) AS varchar) + '-' + CAST(7 AS varchar) + '-' + CAST(01 AS varchar) AS DATETIME)


    Exec ('If object_ID(''conCreateViewReceiptsAndPayments'+@sessionId+''',''V'') is not null 
            drop view conCreateViewReceiptsAndPayments'+@sessionId+';')
    EXEC ('
CREATE VIEW conCreateViewReceiptsAndPayments'+@sessionId+'
AS

select areainfo.AreaId,areainfo.areaname,a.* from 
(
SELECT branch_id,ReceiptPaymentGroup,activateConsolidation,activateFor, Sequence, parentGroupId, parentLevelId, parentAccId, pCode, p1Desc, pDesc as pDesc,
  groupId, levelId, accId,  
 cCode, cDesc, profitLoss,
 case when SUM(acPrevAmount)<0 then SUM(acPrevAmount)*(-1)
 else

  SUM(acPrevAmount) end as  acPrevAmount, 

   case when SUM(acAmount)<0 then SUM(acAmount)*(-1)
 else

  SUM(acAmount) end as  acAmount, 

   case when SUM(acTodateAmount)<0 then SUM(acTodateAmount)*(-1)
 else

  SUM(acTodateAmount) end as  acTodateAmount, 
 SUM(hasNote) as hasNote, accountType,manualAcccode,gSl,rsl,pSl,packageId from 
 (  
  SELECT a.branch_id,a.activateConsolidation,aa.activateFor,ReceiptPaymentGroup, Sequence, parentGroupId, parentLevelId,   
  parentAccId, pCode, p1Desc, pDesc, a.groupId, a.levelId, a.accId, cCode, cDesc, a.profitLoss, openingAmount as acPrevAmount, acAmount ,   
  CASE WHEN aa.accountType in( 1,2) AND Sequence = 1 THEN openingAmount WHEN aa.accountType in( 1,2) AND Sequence = 6 THEN acAmount 
  ELSE openingAmount + acAmount END as acTodateAmount, hasNote  
  ,aa.accountType,aa.manualAcccode,aa.gSl,aa.rsl,aa.pSl,aa.packageId from 
  (  
   select id, branch_id,auto_acc_id,activateConsolidation,parentGroupId,parentLevelId,parentAccId, pCode, p1Desc, pDesc,groupId,levelId,accId, cCode, 
   cDesc, profitLoss  
   , SUM(ISNULL(openingAmount,0)) openingAmount , SUM(ISNULL(amount,0)) as acAmount,SUM(hasNote) as hasNote,packageId, accountType, ReceiptPaymentGroup, Sequence  
   FROM(   
    select a.id, o.branch_id,o.auto_acc_id, a.activateConsolidation, pc.parentGroupId,pc.parentLevelId,pc.parentAccId, ap.autoAccCode as pCode, 
	pa1.accdesc as p1Desc, ap.accdesc as pDesc, o.groupId,o.levelId,o.accId,  
    a.autoAccCode as cCode, a.accdesc as cDesc, a.profitLoss,o.drorcr,  
    ISNULL(ABS(o.openingAmountdr)*-1,0) as openingAmount, 0 as amount, 0 as hasNote,a.packageId, a.accountType,  
    case   
    when (pc.parentGroupId=1 or pc.parentGroupId=2) then ''Capital Receipts'' 
    when (pc.parentGroupId = 3 or pc.parentGroupId = 4 ) then  ''Revenue Receipts'' 
    end as ReceiptPaymentGroup,  
    case    
    when (pc.parentGroupId=1 or pc.parentGroupId=2) then 2  
    when (pc.parentGroupId = 3 or pc.parentGroupId = 4 ) then 3     
    else 0 end  as Sequence    
    from tblReceiptsPaymentsOpening o with (NOLOCK)  
    inner join tblAccount a with (NOLOCK) on a.id = o.auto_acc_id  
    inner join tblParentChildReport pc with (NOLOCK) on o.auto_acc_id = pc.child_auto_acc_id     
    inner join tblAccount ap with (NOLOCK) on ap.id = pc.parent_auto_acc_id    
    LEFT JOIN tblParentChildReport pc1 with (NOLOCK) on ap.id = pc1.child_auto_acc_id  
    LEFT JOIN tblAccount pa1 with (NOLOCK) on pa1.id = pc1.parent_auto_acc_id  
    Where o.periodstartdate =  '''+@periodStartDate+'''   and o.openingAmountdr >0 and a.receiptsPayments = 1 
	and a.packageId='''+@packageId+'''
	--and o.type='+@acountvoucherType+'
	 
    UNION 

    select a.id, o.branch_id,o.auto_acc_id, a.activateConsolidation, pc.parentGroupId,pc.parentLevelId,pc.parentAccId, ap.autoAccCode as pCode, 
	pa1.accdesc as p1Desc, ap.accdesc as pDesc, o.groupId,o.levelId,o.accId,  
    a.autoAccCode as cCode, a.accdesc as cDesc, a.profitLoss,o.drorcr,  
    ISNULL(ABS(o.openingAmountcr),0) as openingAmount, 0 as amount,0 as hasNote,a.packageId, a.accountType,  
    case      
    when (pc.parentGroupId=1 or pc.parentGroupId=2) then ''Capital Payments''
    when (pc.parentGroupId = 3 or pc.parentGroupId = 4 ) then  ''Revenue Payments'' 
    end as ReceiptPaymentGroup,  
    case      
    when (pc.parentGroupId=1 or pc.parentGroupId=2) then 4   
    when (pc.parentGroupId = 3 or pc.parentGroupId = 4 ) then 5    
    else 0 end  as Sequence    
    from tblReceiptsPaymentsOpening o with (NOLOCK)   
    inner join tblAccount a with (NOLOCK) on a.id = o.auto_acc_id  
    inner join tblParentChildReport pc with (NOLOCK) on o.auto_acc_id = pc.child_auto_acc_id     
    inner join tblAccount ap with (NOLOCK) on ap.id = pc.parent_auto_acc_id  
    LEFT JOIN tblParentChildReport pc1 with (NOLOCK) on ap.id = pc1.child_auto_acc_id  
    LEFT JOIN tblAccount pa1 with (NOLOCK) on pa1.id = pc1.parent_auto_acc_id  
    Where o.periodstartdate =  '''+@periodStartDate+'''   and o.openingAmountcr >0 and a.receiptsPayments = 1  
   and a.packageId='''+@packageId+'''
   --	and o.type='+@acountvoucherType+'

    UNION   

    Select cur.Id, cur.branch_id,cur.auto_acc_id, cur.activateConsolidation,cur.parentGroupId,cur.parentLevelId,cur.parentAccId,cur.pCode,cur.p1Desc,
	 cur.pDesc,cur.groupId,cur.levelId,cur.accId,  
    cur.cCode,cur.cDesc,cur.profitLoss,1,0 as openingAmount, SUM(cur.amount) acAmount,SUM(hasNote) as hasNote, cur.accountType,cur.packageId,  
    cur.ReceiptPaymentGroup,cur.Sequence FROM (     
  
  
select vd.auto_acc_id as Id, vc.branch_id,vd.auto_acc_id, a.activateConsolidation, pc.parentGroupId,pc.parentLevelId,pc.parentAccId, 
ap.autoAccCode as pCode, pa1.accdesc as p1Desc, ap.accdesc as pDesc,vd.groupId,vd.levelId,vd.accId,  
a.autoAccCode as cCode, a.accdesc as cDesc, a.profitLoss, 0 as openingAmount, ISNULL(vd.amount,0) as amount, 
CASE vc.voucherType WHEN 4 THEN 1 ELSE 0 END hasNote, a.packageId,a.accountType,
case 
when vd.amount<0 and (pc.parentGroupId=1 or pc.parentGroupId=2) then ''Capital Receipts''
when vd.amount>0 and (pc.parentGroupId=1 or pc.parentGroupId=2) then ''Capital Payments''
when vd.amount<0 and (pc.parentGroupId = 3 or pc.parentGroupId = 4 ) then ''Revenue Receipts''
when vd.amount>0 and (pc.parentGroupId = 3 or pc.parentGroupId = 4 ) then ''Revenue Payments'' else null 
end as ReceiptPaymentGroup,
case  
when vd.amount<0 and (pc.parentGroupId=1 or pc.parentGroupId=2) then 2 
when vd.amount>0 and (pc.parentGroupId=1 or pc.parentGroupId=2) then 4 
when vd.amount<0 and (pc.parentGroupId = 3 or pc.parentGroupId = 4 ) then 3 
when vd.amount>0 and (pc.parentGroupId = 3 or pc.parentGroupId = 4 ) then 5 else 0 end  as Sequence 	
from 
tblVoucherDetail vd with (NOLOCK) inner join tblParentChildReport pc with (NOLOCK) on vd.auto_acc_id = pc.child_auto_acc_id
inner join tblAccount a with (NOLOCK) on vd.auto_acc_id = a.id inner join tblVoucher vc with (NOLOCK) on vd.voucher_id = vc.id
inner join tblAccount ap with (NOLOCK) on pc.parent_auto_acc_id = ap.id Left join tblParentChildReport pc1 with (NOLOCK)
on ap.id = pc1.child_auto_acc_id Left join tblAccount pa1 with (NOLOCK) on pa1.id = pc1.parent_auto_acc_id
where a.accountType=0  and a.packageId='''+@packageId+'''
and vc.voucherdate between  '''+@periodStartDate+'''   and  '''+@periodEndDate+''' 
and vc.voucherType <> case when '+@acountvoucherType+'= 0 then 100 else 4 end  -- cng by 4had previously <>4       
       
    )cur   
    GROUP BY cur.Id, cur.branch_id,cur.auto_acc_id,cur.activateConsolidation,
	 cur.parentGroupId,cur.parentLevelId,cur.parentAccId, cur.pCode, cur.p1Desc, cur.pDesc, cur.groupId,cur.levelId,cur.accId,  
    cur.cCode, cur.cDesc, cur.profitLoss,cur.accountType,cur.ReceiptPaymentGroup,cur.Sequence,cur.packageId  




		
		------------new form cash/cash and non cash ------------

	union

	Select cur.Id, cur.branch_id,cur.auto_acc_id, cur.activateConsolidation,cur.parentGroupId,cur.parentLevelId,cur.parentAccId,cur.pCode,cur.p1Desc,
	 cur.pDesc,cur.groupId,cur.levelId,cur.accId,  
    cur.cCode,cur.cDesc,cur.profitLoss,1,0 as openingAmount, SUM(cur.amount) acAmount,SUM(hasNote) as hasNote, cur.accountType,cur.packageId,  
    cur.ReceiptPaymentGroup,cur.Sequence FROM (     

select vd.auto_acc_id as Id, vc.branch_id,vd.auto_acc_id, a.activateConsolidation, pc.parentGroupId,pc.parentLevelId,pc.parentAccId, 
ap.autoAccCode as pCode, pa1.accdesc as p1Desc, ap.accdesc as pDesc,vd.groupId,vd.levelId,vd.accId,  
a.autoAccCode as cCode, a.accdesc as cDesc, a.profitLoss, 0 as openingAmount, 
case when ISNULL(vd.amount,0)>0 then 
 ISNULL(vd.amount,0)+isnull(vd.vat,0)+isnull(vd.tax,0) else  ISNULL(vd.amount,0)-isnull(vd.vat,0)-isnull(vd.tax,0) end  as amount, 
CASE vc.voucherType WHEN 4 THEN 1 ELSE 0 END hasNote, a.packageId,a.accountType,
case 
when vd.amount<0 and (pc.parentGroupId=1 or pc.parentGroupId=2) then ''Capital Receipts''
when vd.amount>0 and (pc.parentGroupId=1 or pc.parentGroupId=2) then ''Capital Payments''
when vd.amount<0 and (pc.parentGroupId = 3 or pc.parentGroupId = 4 ) then ''Revenue Receipts''
when vd.amount>0 and (pc.parentGroupId = 3 or pc.parentGroupId = 4 ) then ''Revenue Payments'' else null 
end as ReceiptPaymentGroup,
case  
when vd.amount<0 and (pc.parentGroupId=1 or pc.parentGroupId=2) then 2 
when vd.amount>0 and (pc.parentGroupId=1 or pc.parentGroupId=2) then 4 
when vd.amount<0 and (pc.parentGroupId = 3 or pc.parentGroupId = 4 ) then 3 
when vd.amount>0 and (pc.parentGroupId = 3 or pc.parentGroupId = 4 ) then 5 else 0 end  as Sequence 	
from 
tblVoucherDetail vd with (NOLOCK) inner join tblParentChildReport pc with (NOLOCK) on vd.auto_acc_id = pc.child_auto_acc_id
inner join tblAccount a with (NOLOCK) on vd.auto_acc_id = a.id inner join tblVoucher vc with (NOLOCK) on vd.voucher_id = vc.id
inner join tblAccount ap with (NOLOCK) on pc.parent_auto_acc_id = ap.id Left join tblParentChildReport pc1 with (NOLOCK)
on ap.id = pc1.child_auto_acc_id Left join tblAccount pa1 with (NOLOCK) on pa1.id = pc1.parent_auto_acc_id
where
-- a.accounttype=0 and
  a.packageId='''+@packageId+'''
and vc.voucherdate between  '''+@periodStartDate+'''   and  '''+@periodEndDate+''' 
 and vc.voucherType =(
		 
		 select top 1 vouchertype from tblvoucher y inner join tblvoucherdetail x
         on y.id=x.voucher_id inner join tblaccount c on x.auto_acc_id=c.id and c.accounttype  in(1,2) and y.vouchertype=4
         and y.voucherdate   between  '''+@periodStartDate+'''   and  '''+@periodEndDate+''' 
         and x.branch_id in('+@branch_id+')
		 )
		 -- and a.accdesc not in(''cash in Hand'',''cash at bank'')
		and  a.accounttype not in(1,2)
        and vc.branch_id in('+@branch_id+')
       
    )cur   
    GROUP BY cur.Id, cur.branch_id,cur.auto_acc_id,cur.activateConsolidation,
	 cur.parentGroupId,cur.parentLevelId,cur.parentAccId, cur.pCode, cur.p1Desc, cur.pDesc, cur.groupId,cur.levelId,cur.accId,  
    cur.cCode, cur.cDesc, cur.profitLoss,cur.accountType,cur.ReceiptPaymentGroup,cur.Sequence,cur.packageId 
	------------new form cash/cash and non cash ------------






	 UNION  
    select a.Id, Ac.branch_id,ac.auto_acc_id, a.activateConsolidation,pc.parentGroupId, pc.parentLevelId, pc.parentAccId, ap.autoAccCode pCode,'''' as p1Desc, 
	''Opening Balance'' as pDesc,    
    ac.groupId, ac.levelId, ac.accId, a.autoAccCode cCode, a.accdesc cDesc, a.profitLoss,1, 0 as openingamount,    
    isnull(ac.openingamount,0) as amount, 0 as hasNote, ac.accountType,a.packageId,''Opening Balance'' , 1    
    from tblOpening ac with (NOLOCK)  
    inner join tblAccount a with (NOLOCK) on a.id = ac.auto_acc_id  
    inner join tblParentChildReport pc with (NOLOCK) on ac.auto_acc_id = pc.child_auto_acc_id     
    inner join tblAccount ap with (NOLOCK) on ap.id = pc.parent_auto_acc_id   
    Where a.accounttype in (1,2) and ac.periodStartDate = '''+@periodStartDate+'''    
	and a.packageId='''+@packageId+'''

    UNION  

    select a.id, Ac.branch_id,ac.auto_acc_id, a.activateConsolidation,pc.parentGroupId, pc.parentLevelId, pc.parentAccId, ap.autoAccCode pCode, '''' as p1Desc,
	 ''Opening Balance'' as pDesc,    
    ac.groupId, ac.levelId, ac.accId, a.autoAccCode cCode, a.accdesc cDesc, a.profitLoss,1, isnull(ac.openingamount,0) as openingamount,    
    0 as amount, 0 as hasNote, ac.accountType,a.packageId,''Opening Balance'' , 1    
    from tblOpening ac with (NOLOCK)   
    inner join tblAccount a with (NOLOCK) on a.id = ac.auto_acc_id  
    inner join tblParentChildReport pc with (NOLOCK) on ac.auto_acc_id = pc.child_auto_acc_id     
    inner join tblAccount ap with (NOLOCK) on ap.id = pc.parent_auto_acc_id   
    Where a.accounttype in (1,2) and ac.periodStartDate =  '''+@yearStartDate+'''
	and a.packageId='''+@packageId+'''
    UNION  
    select Id, branch_id,auto_acc_id,activateConsolidation,parentGroupId, parentLevelId, parentAccId, pCode, '''' as p1Desc, ''Closing Balance'' as pDesc,    
    groupId, levelId, accId, cCode, cDesc, profitLoss,1, SUM(isnull(openingamount,0)) as openingamount ,    
    SUM(isnull(amount,0)) as amount, 0 as hasNote, accountType,packageId ,''Closing Balance'', 6  
    FROM (  
     select a.Id, Ac.branch_id,ac.auto_acc_id,a.activateConsolidation,pc.parentGroupId, pc.parentLevelId, pc.parentAccId, ap.autoAccCode pCode, ap.accdesc pDesc,    
     ac.groupId, ac.levelId, ac.accId, a.autoAccCode cCode, a.accdesc cDesc, a.profitLoss, 0 as openingamount,    
     isnull(ac.openingamount,0) as amount, ac.accountType,a.packageId
     from tblOpening ac with (NOLOCK)  
     inner join tblAccount a with (NOLOCK) on a.id = ac.auto_acc_id  
     inner join tblParentChildReport pc on ac.auto_acc_id = pc.child_auto_acc_id     
     inner join tblAccount ap with (NOLOCK) on ap.id = pc.parent_auto_acc_id   
     Where a.accounttype in (1,2) and ac.periodStartDate =  '''+@periodStartDate+'''  
	 and a.packageId='''+@packageId+'''
     UNION  	  
     select id, branch_id,auto_acc_id,activateConsolidation,parentGroupId, parentLevelId, parentAccId, pCode, ''Closing Balance'' as pDesc,    
     groupId, levelId, accId, cCode, cDesc, profitLoss, SUM(isnull(openingamount,0)) as openingamount ,    
     SUM(isnull(amount,0)) as amount, accountType,packageId
     FROM (  
      select vd.auto_acc_id as Id, vc.branch_id,vd.auto_acc_id,a.activateConsolidation,pc.parentGroupId,pc.parentLevelId,pc.parentAccId,   
      ap.autoAccCode as pCode, ap.accdesc as pDesc,vd.groupId,vd.levelId,vd.accId,    
      a.autoAccCode as cCode, a.accdesc as cDesc, a.profitLoss, 0 openingAmount,  vd.amount as amount , a.accountType,a.packageId     
      from
	   tblVoucherDetail vd with (NOLOCK), 
	  tblParentChildReport pc with (NOLOCK), 
	  tblAccount a with (NOLOCK), 
	  tblVoucher vc with (NOLOCK), tblAccount ap with (NOLOCK)   
      where  vd.auto_acc_id = pc.child_auto_acc_id and a.id = vd.auto_acc_id and ap.id = pc.parent_auto_acc_id  
      and vc.branch_id = vd.branch_id  and vc.id=vd.voucher_id   
      and a.accountType in(1,2) and vc.voucherdate between  '''+@periodStartDate+'''   and   '''+@periodEndDate+'''  
	  and a.packageId='''+@packageId+'''
     )cv  
     group by id, branch_id,auto_acc_id,activateConsolidation,parentGroupId, parentLevelId, parentAccId, pCode, pDesc,    
     groupId, levelId, accId, cCode, cDesc, profitLoss,accountType,packageId

     UNION   

     select a.id, Ac.branch_id,ac.auto_acc_id,a.activateConsolidation,pc.parentGroupId, pc.parentLevelId, pc.parentAccId, ap.autoAccCode pCode, ap.accdesc pDesc,    
     ac.groupId, ac.levelId, ac.accId, a.autoAccCode cCode, a.accdesc cDesc, a.profitLoss, isnull(ac.openingamount,0) as openingamount,    
     0 as amount, ac.accountType,a.packageId 
     from tblOpening ac with (NOLOCK)  
     inner join tblAccount a with (NOLOCK) on a.id = ac.auto_acc_id  
     inner join tblParentChildReport pc with (NOLOCK) on ac.auto_acc_id = pc.child_auto_acc_id     
     inner join tblAccount ap with (NOLOCK) on ap.id = pc.parent_auto_acc_id   
     Where a.accounttype in (1,2) and ac.periodStartDate = '''+@periodStartDate+'''
	 and a.packageId='''+@packageId+'''
    )cl  
    group by Id, branch_id,auto_acc_id,activateConsolidation,parentGroupId, parentLevelId, parentAccId, pCode, pDesc,    
    groupId, levelId, accId, cCode, cDesc, profitLoss,accountType,packageId    
   ) rp  
   Group by Id, branch_id,auto_acc_id,activateConsolidation,parentGroupId,parentLevelId,parentAccId, pCode, p1Desc, pDesc,groupId,levelId,accId, cCode, cDesc, profitLoss  
   ,accountType, packageId,ReceiptPaymentGroup, Sequence  
  )a   


  		---------corporate----------
	inner join
	(
		select b.id,a.accdesc from tblAccount b 
		inner join 
		( 
			select  id,accdesc  from tblAccount where  controlLevel_id=''00000000-0000-0000-0000-000000000000'' and controlLevelId=0 and packageId=1 and transactionStatus=0
		) a on a.id=b.corporrate_id
	) d on a.id=d.id

	---------------




  INNER JOIN tblAccount aa with (NOLOCK) on aa.Id = a.Id  
  Where branch_id in('+@branch_id+') and
   ReceiptPaymentGroup is not null and aa.receiptsPayments = 1 
  and aa.transactionStatus = 0 
  and aa.packageId='''+@packageId+'''
   
 )mis6  
 Group by branch_id,ReceiptPaymentGroup,activateConsolidation,activateFor, Sequence, parentGroupId, parentLevelId, parentAccId, pCode, p1Desc, pDesc, groupId, levelId, accId,  
 cCode, cDesc, profitLoss, accountType,manualAcccode,gSl,rsl,pSl,packageId)a
 

	inner join 

(select a.areaname,a.AreaId,b.branch_id from tblArea a 
inner join tblBranchLines b on a.AreaId=b.AreaId
inner join tblBranch c on b.branch_id=c.ID) areainfo
on a.branch_id=areainfo.branch_id

 
 
 
 '
)
END
GO
/****** Object:  StoredProcedure [dbo].[CreateInventoryStatus]    Script Date: 16-Jul-25 8:22:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateInventoryStatus]      
@branch_Id uniqueidentifier,
@item_id varchar(100),@location_Id varchar(100),
@sessionId  varchar(100)      

AS 
BEGIN
       Exec ('If object_ID(''View_InventoryStatus'+@sessionId+''',''V'') is not null       
            drop view View_InventoryStatus'+@sessionId+';')      
    EXEC ('
	CREATE VIEW View_InventoryStatus'+@sessionId+'      
AS  
SELECT     i.Id Item_id,i.name AS ItemName, i.code AS ItemCode, i.defaultCost, i.defaultPrice, i.discount, i.reorderLevel, t.AddItemQuantity - t.RemoveItemQuantity AS balance, t.branch_Id,       
l.name AS locationName,l.id location_id, ic.categoryName, isc.name AS subCategoryName  ,i.label    
FROM         dbo.tblItem AS i INNER JOIN      
(SELECT     location_Id, branch_Id, item_Id, SUM(CASE WHEN tblItemTransaction.transactionType = ''Add'' AND       
tblItemTransaction.quantity >= 0 THEN tblItemTransaction.quantity ELSE 0 END) AS AddItemQuantity,       
SUM(CASE WHEN tblItemTransaction.transactionType = ''Remove'' AND tblItemTransaction.quantity >= 0 THEN tblItemTransaction.quantity ELSE 0 END)       
AS RemoveItemQuantity      
FROM          dbo.tblItemTransaction  
 where branch_Id = '''+@branch_Id+''' 
  '+@item_id+'      
  '+@location_Id+' 
GROUP BY location_Id, branch_Id, item_Id) AS t ON i.Id = t.item_Id LEFT OUTER JOIN      
dbo.tblItemCategory AS ic ON ic.Id = i.category_Id LEFT OUTER JOIN      
dbo.tblItemSubCategory AS isc ON isc.Id = i.subCategory_Id LEFT OUTER JOIN      
dbo.tblLocation AS l ON l.Id = t.location_Id '  
) 
END    
GO
/****** Object:  StoredProcedure [dbo].[CreateViewPortfolioPerformance]    Script Date: 16-Jul-25 8:22:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[CreateViewPortfolioPerformance]
 @periodStartDate DateTime, @sessionId varchar(100)
As
Begin
Exec ('If object_ID(''viw_portfolioperformance_dueamount'+@sessionId+''',''V'') is not null 
            drop view viw_portfolioperformance_dueamount'+@sessionId+';')
    EXEC ('
CREATE VIEW viw_portfolioperformance_dueamount'+@sessionId+'
AS
SELECT p.slNo, p.description, ''BR1''=SUM(CASE y.branchId when ''002'' then y.dueAmount else 0 end),
''BR2''=SUM(CASE y.branchId when ''003'' then y.dueAmount else 0 end),
''BR3''=SUM(CASE y.branchId when ''004'' then y.dueAmount else 0 end),
''BR4''=SUM(CASE y.branchId when ''005'' then y.dueAmount else 0 end),
''BR5''=SUM(CASE y.branchId when ''006'' then y.dueAmount else 0 end),
''BR6''=SUM(CASE y.branchId when ''007'' then y.dueAmount else 0 end),
''BR7''=SUM(CASE y.branchId when ''008'' then y.dueAmount else 0 end),
''BR8''=SUM(CASE y.branchId when ''009'' then y.dueAmount else 0 end),
''BR9''=SUM(CASE y.branchId when ''010'' then y.dueAmount else 0 end),
''BR10''=SUM(CASE y.branchId when ''011'' then y.dueAmount else 0 end),
''BR11''=SUM(CASE y.branchId when ''012'' then y.dueAmount else 0 end),
''BR12''=SUM(CASE y.branchId when ''013'' then y.dueAmount else 0 end)
FROM Par p left join (
	select branchId,branch_id,dueDays,sum(dueAmount) dueAmount FROM 
	(
		select a.branch_id,a.AccountNo,ag.outstanding dueamount, dueDays=CASE WHEN dueAmount>0 AND duedays>=0 and duedays<=30 THEN 30
		WHEN dueAmount>0 AND duedays>30 and duedays<=60 THEN 60
		WHEN dueAmount>0 AND duedays>61 and duedays<=90 THEN 90
		WHEN dueAmount>0 AND duedays>91 and duedays<=120 THEN 120
		WHEN dueAmount>0 AND duedays>120 THEN 121 
		ELSE 0 END FROM func_getLoanAging_all_standard(''' +@periodStartDate+ ''')  ag 
		inner join LoanAccount a on ag.account_id = a.id where ag.instPrincipalAmt > 0			
	) x inner join tblBranch b on x.branch_id = b.ID 
	group by b.branchId,x.branch_id,x.dueDays
) y on p.days = y.dueDays where y.branchId in(''002'',''003'',''004'',''005'',''006'',''007'',''008'',''009'',''010'',''011'',''012'',''013'') 
group by p.slNo,p.description
'
)

 Exec ('If object_ID(''viw_portfolioperformance_customerNo'+@sessionId+''',''V'') is not null 
            drop view viw_portfolioperformance_customerNo'+@sessionId+';')
    EXEC ('
CREATE VIEW viw_portfolioperformance_customerNo'+@sessionId+'
AS

SELECT p.slNo, p.description,''BR1''=SUM(CASE y.branchId when ''002'' then y.customerNo else 0 end),
''BR2''=SUM(CASE y.branchId when ''003'' then y.customerNo else 0 end),
''BR3''=SUM(CASE y.branchId when ''004'' then y.customerNo else 0 end),
''BR4''=SUM(CASE y.branchId when ''005'' then y.customerNo else 0 end),
''BR5''=SUM(CASE y.branchId when ''006'' then y.customerNo else 0 end),
''BR6''=SUM(CASE y.branchId when ''007'' then y.customerNo else 0 end),
''BR7''=SUM(CASE y.branchId when ''008'' then y.customerNo else 0 end),
''BR8''=SUM(CASE y.branchId when ''009'' then y.customerNo else 0 end),
''BR9''=SUM(CASE y.branchId when ''010'' then y.customerNo else 0 end),
''BR10''=SUM(CASE y.branchId when ''011'' then y.customerNo else 0 end),
''BR11''=SUM(CASE y.branchId when ''012'' then y.customerNo else 0 end),
''BR12''=SUM(CASE y.branchId when ''013'' then y.customerNo else 0 end)
FROM Par p left join (
      select branchId,branch_id,dueDays,count(customerId) customerNo FROM (
		   select branch_id,customerId,''dueDays''=max(dueDays) FROM
		   (
				select a.branch_id,a.customerId, a.AccountNo,ag.outstanding dueamount, 
				dueDays=CASE WHEN dueAmount>0 AND duedays>=0 and duedays<=30 THEN 30
				WHEN dueAmount>0 AND duedays>30 and duedays<=60 THEN 60
				WHEN dueAmount>0 AND duedays>61 and duedays<=90 THEN 90
				WHEN dueAmount>0 AND duedays>91 and duedays<=120 THEN 120
				WHEN dueAmount>0 AND duedays>120 THEN 121 
				ELSE 0 END FROM func_getLoanAging_all_standard(''' +@periodStartDate+ ''')  ag 
				inner join LoanAccount a on ag.account_id = a.id where ag.instPrincipalAmt > 0
		   ) w group by branch_id,customerId	
	) x inner join tblBranch b on x.branch_id = b.ID 
	group by b.branchId,x.branch_id,x.dueDays
) y on p.days = y.dueDays where y.branchId in(''002'',''003'',''004'',''005'',''006'',''007'',''008'',''009'',''010'',''011'',''012'',''013'') 
group by p.slNo,p.description'
)

 Exec ('If object_ID(''ViewOutstandingPortfolioPerformance'+@sessionId+''',''V'') is not null 
            drop view ViewOutstandingPortfolioPerformance'+@sessionId+';')
    EXEC ('
CREATE VIEW ViewOutstandingPortfolioPerformance'+@sessionId+'
AS
SELECT p.productCode,p.Productname,
''BR1''=SUM(CASE b.branchId when ''002'' then z.outstanding else 0 end),
''BR2''=SUM(CASE b.branchId when ''003'' then z.outstanding else 0 end),
''BR3''=SUM(CASE b.branchId when ''004'' then z.outstanding else 0 end),
''BR4''=SUM(CASE b.branchId when ''005'' then z.outstanding else 0 end),
''BR5''=SUM(CASE b.branchId when ''006'' then z.outstanding else 0 end),
''BR6''=SUM(CASE b.branchId when ''007'' then z.outstanding else 0 end),
''BR7''=SUM(CASE b.branchId when ''008'' then z.outstanding else 0 end),
''BR8''=SUM(CASE b.branchId when ''009'' then z.outstanding else 0 end),
''BR9''=SUM(CASE b.branchId when ''010'' then z.outstanding else 0 end),
''BR10''=SUM(CASE b.branchId when ''011'' then z.outstanding else 0 end),
''BR11''=SUM(CASE b.branchId when ''012'' then z.outstanding else 0 end),
''BR12''=SUM(CASE b.branchId when ''013'' then z.outstanding else 0 end)
from LoanProductDef p  with (nolock) cross join tblbranch b with (nolock) left join 
(
	select branch_id,product_id,''outstanding''=sum(dueamount) FROM
	(
		select a.branch_id,a.product_id, a.AccountNo,ag.outstanding dueamount
		FROM func_getLoanAging_all_standard(''' +@periodStartDate+ ''')  ag 
		inner join LoanAccount a on ag.account_id = a.id where ag.instPrincipalAmt > 0
	) w group by branch_id,product_id


)z  on z.product_id =p.id and b.id=z.branch_id
group by p.productCode,p.Productname'
)

 Exec ('If object_ID(''ViewClientPerformance'+@sessionId+''',''V'') is not null 
            drop view ViewClientPerformance'+@sessionId+';')
    EXEC ('
CREATE VIEW ViewClientPerformance'+@sessionId+'
AS
SELECT p.productCode,p.Productname ,
''BR1''=SUM(CASE b.branchId when ''002'' then z.clienttotal else 0 end),
''BR2''=SUM(CASE b.branchId when ''003'' then z.clienttotal else 0 end),
''BR3''=SUM(CASE b.branchId when ''004'' then z.clienttotal else 0 end),
''BR4''=SUM(CASE b.branchId when ''005'' then z.clienttotal else 0 end),
''BR5''=SUM(CASE b.branchId when ''006'' then z.clienttotal else 0 end),
''BR6''=SUM(CASE b.branchId when ''007'' then z.clienttotal else 0 end),
''BR7''=SUM(CASE b.branchId when ''008'' then z.clienttotal else 0 end),
''BR8''=SUM(CASE b.branchId when ''009'' then z.clienttotal else 0 end),
''BR9''=SUM(CASE b.branchId when ''010'' then z.clienttotal else 0 end),
''BR10''=SUM(CASE b.branchId when ''011'' then z.clienttotal else 0 end),
''BR11''=SUM(CASE b.branchId when ''012'' then z.clienttotal else 0 end),
''BR12''=SUM(CASE b.branchId when ''013'' then z.clienttotal else 0 end)
from LoanProductDef p with (nolock)  cross join tblbranch b with (nolock) left join 
(
	 SELECT a.branch_id,a.product_id,''clienttotal''= count(*) from  LoanAccount a 
	  where (a.AccountStatus=''Operative'' or (a.AccountStatus=''Cloesd'' and a.closedDate>''' +@periodStartDate+ '''  ))  and a.disbursedate <=''' +@periodStartDate+ '''  
	  group by  a.branch_id,a.product_id	  
)z  on z.product_id =p.id  and b.id=z.branch_id 
group by p.productCode,p.Productname	
'
)
 Exec ('If object_ID(''ViewCustomerCategory'+@sessionId+''',''V'') is not null 
            drop view ViewCustomerCategory'+@sessionId+';')
    EXEC ('
CREATE VIEW ViewCustomerCategory'+@sessionId+'
AS
SELECT cc.itemCode,cc.itemName ,
''BR1''=SUM(CASE b.branchId when ''002'' then z.clienttotal else 0 end),
''BR2''=SUM(CASE b.branchId when ''003'' then z.clienttotal else 0 end),
''BR3''=SUM(CASE b.branchId when ''004'' then z.clienttotal else 0 end),
''BR4''=SUM(CASE b.branchId when ''005'' then z.clienttotal else 0 end),
''BR5''=SUM(CASE b.branchId when ''006'' then z.clienttotal else 0 end),
''BR6''=SUM(CASE b.branchId when ''007'' then z.clienttotal else 0 end),
''BR7''=SUM(CASE b.branchId when ''008'' then z.clienttotal else 0 end),
''BR8''=SUM(CASE b.branchId when ''009'' then z.clienttotal else 0 end),
''BR9''=SUM(CASE b.branchId when ''010'' then z.clienttotal else 0 end),
''BR10''=SUM(CASE b.branchId when ''011'' then z.clienttotal else 0 end),
''BR11''=SUM(CASE b.branchId when ''012'' then z.clienttotal else 0 end),
''BR12''=SUM(CASE b.branchId when ''013'' then z.clienttotal else 0 end)
from CustomerCategory cc with (nolock)  cross join tblbranch b with (nolock) left join 
(

	 SELECT  c.branch_id,''customercategoryName'' =''Individual'',''clienttotal''= count(*) from  customer c  where c.workingType=''Individual'' 
	 and  c.memberCategory = ''Indivisual'' and (c.customerStatus=''Active'' or (c.customerStatus=''dropout''and  c.dropout_date >''' +@periodStartDate+ ''' )) 
	 and c.admissionDate <=''' +@periodStartDate+ ''' and c.id in 
	 (select customer_id from loanAccount where accountstatus=''Operative'' or( accountstatus=''closed'' and closedDate >''' +@periodStartDate+ ''' ))
	 group by  c.branch_id
	 union 
	 SELECT c.branch_id,''customercategoryName''= ''Group Customers'',''clienttotal''= count(*) from  customer c  where c.workingType = ''Center'' 
	 and (c.customerStatus=''Active'' or (c.customerStatus=''dropout''and  c.dropout_date >''' +@periodStartDate+ ''' )) and 
	 c.admissionDate <=''' +@periodStartDate+ '''  and c.id in 
	 (select customer_id from loanAccount where accountstatus=''Operative'' or( accountstatus=''closed'' and closedDate >''' +@periodStartDate+ ''' ))
	 group by c.branch_id
	 union 
	 SELECT c.branch_id,''customercategoryName''= ''Institutions'',''clienttotal''= count(*) from  customer c   where c.memberCategory=''Non Indivisual'' 
	 and c.workingType=''Individual'' and (c.customerStatus=''Active'' or (c.customerStatus=''dropout''and  c.dropout_date >''' +@periodStartDate+ ''' )) 
	 and c.admissionDate <=''' +@periodStartDate+ '''  and c.id in 
	 (select customer_id from loanAccount where accountstatus=''Operative'' or( accountstatus=''closed'' and closedDate >''' +@periodStartDate+ ''' ))
	 group by c.branch_id
	 union 
	 SELECT c.branch_id,''customercategoryName''= ''Loan free clients'',''clienttotal''= count(*) from  customer c  where c.id not in 
	 (select customer_id from loanAccount where accountstatus=''Operative'' or( accountstatus=''closed'' and closedDate >''' +@periodStartDate+ ''' )) 
	 and (c.customerStatus=''Active'' or (c.customerStatus=''dropout''and  c.dropout_date >''' +@periodStartDate+ ''' )) 
	 and c.admissionDate <=''' +@periodStartDate+ ''' 
	 group by c.branch_id	
	 union 
	 SELECT c.branch_id,''customercategoryName'' =''Exited clients'',''clienttotal''= count(*) from  customer c   where  c.customerStatus=''dropout'' 
	 and  c.dropout_date<=''' +@periodStartDate+ '''  and c.admissionDate <=''' +@periodStartDate+ ''' 
	 group by c.branch_id
	 
)z  on z.customercategoryName =cc.itemName  and z.branch_id = b.id
group by cc.itemCode,cc.itemName

'
)
END
GO
/****** Object:  StoredProcedure [dbo].[CreateViewSubLedger]    Script Date: 16-Jul-25 8:22:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateViewSubLedger]      
@branch_id UniqueIdentifier, @periodStartDate DateTime,@periodEndDate DateTime,@account_id varchar(100),@subLedger_id varchar(100), @sessionId varchar(100)       
    
AS      
BEGIN     
declare @parm nvarchar(200)    
set @parm='@periodEndDate date, @periodStartDate date, @branch_id UniqueIdentifier,@account_id varchar(100)'    
Declare @groupid int,@str varchar(max)='',@query nvarchar(max)=''    
select @groupid=groupId from tblAccount where id=@account_id    
if(@groupid = 3 or @groupid=4)     
begin    
set @str='v.voucherdate >= dbo.FirstDayOfFY(@periodEndDate) and     
 v.voucherdate <= DATEADD(MONTH, DATEDIFF(MONTH, ''19000101'', @periodEndDate), ''18991231'')'    
end    
else    
begin    
set @str='v.voucherdate < @periodStartDate'    
end     
        
          
set @query='     
insert into TempSubLedger    
SELECT branch_id,voucherNo,VoucherDate,particulars,manualAccCode,accdesc,slgdescription,sglid,sglcode,groupId,      
''Opening''=SUM(CASE voucherNo When ''OPB'' Then amount Else 0 END),      
''debits''=SUM(CASE When  amount>=0 then amount else 0 End),       
''credits''=SUM(Case When  amount<0 then amount*(-1) else 0 End) FROM (      
select o.branch_id,''voucherNo''=''OPB'',''VoucherDate''=@periodStartDate,particulars='''',''manualAccCode''='''',''accdesc''='''', ''slgdescription''=s.description,''sglid''=s.id,a.groupId,''sglcode''=s.code,       
''amount''=IsNull((      
  select sum(slt.amount) from tblVoucher v inner join tblVoucherDetail d on v.branch_id = d.branch_id and v.id = d.voucher_id      
  inner join subLedgerTransaction slt on slt.voucher_detail_Id =d.id inner join tblSubledger sl  on sl.id = slt.sub_ledger_Id      
  where '+@str+' and d.auto_acc_id = o.auto_acc_id and v.branch_id = o.branch_id      
  and sl.id = s.Id       
 ),0)      
 + IsNull((select top 1 amount from SubLedgerOpening where subLedger_id = s.Id and openingDate <=@periodStartDate and branch_id=@branch_id  order by openingDate desc),0)      
      
  from tblOpening o inner join tblSubledger s on o.auto_acc_id = s.acc_Id inner join tblAccount a on a.id = s.acc_Id       
  Where auto_acc_id = @account_id and periodstartdate = dbo.StartDayOfMonth (@periodStartDate)    
        
and branch_id = @branch_id     
--and a.groupId not in (3,4)    
UNION      
select v.branch_id,v.voucherno,v.voucherDate,v.particulars,a.manualAccCode,a.accdesc,aa.description,aa.id ,a.groupId,      
aa.code,aa.Amount      
from tblVoucherDetail vd        
inner join tblVoucher v  on vd.voucher_id=v.id      
inner   join tblaccount a on vd.auto_acc_id= a.id       
left join (      
 select sl.code, sl.description,sl.acc_id,sl.id, slt.voucher_id,slt.voucher_detail_id,slt.amount      
 from tblSubledger sl  inner join subLedgerTransaction slt on slt.sub_ledger_Id =sl.id      
) aa on aa.voucher_detail_Id = vd.id      
where v.branch_id =@branch_id and vd.auto_acc_id=@account_id       
and v.voucherdate between @periodStartDate AND @periodEndDate     
) x      
where  x.sglid ' + @subLedger_id + '      
Group by branch_id,voucherNo,VoucherDate,particulars,manualAccCode,accdesc,slgdescription,sglid,sglcode,groupId     
'     
print  @query    
exec sp_executesql @query,@parm,@periodEndDate,@periodStartDate , @branch_id ,@account_id      
END
GO
/****** Object:  StoredProcedure [dbo].[CreateViewVoucher]    Script Date: 16-Jul-25 8:22:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateViewVoucher]  
@branch_id UniqueIdentifier,@voucher_id UniqueIdentifier , @sessionId varchar(100)   
AS  
BEGIN  
    Exec ('If object_ID(''viewAllVoucher'+@sessionId+''',''V'') is not null   
            drop view viewAllVoucher'+@sessionId+';')  
    EXEC ('  
CREATE VIEW viewAllVoucher'+@sessionId+'  
AS  
select  v.id,v.branch_id,  
 v.voucherno, voucherdate,  
  vouchertype, voucherstatus,  
   postingStatus chequeno,  
    chequedate, bankname,   
particulars,''preparedBy''=ep.empName, ''approvedBy''=ea.empName, ''checkedBy''=ec.empName,   
 [lineno],  
 CASE WHEN ST.AMOUNT IS NOT NULL and ST.sub_ledger_Id<>''00000000-0000-0000-0000-000000000000''  
 THEN ST.AMOUNT   
 ELSE   
 case when v.voucherType=1 then   
 case when d.amount>=0 then d.amount+isnull(d.vat,0)+isnull(d.tax,0) else d.amount+isnull(-d.vat,0)+isnull(-d.tax,0)end    
 else   
 case when d.amount>0 then d.amount+isnull(d.vat,0)+isnull(d.tax,0) else d.amount+isnull(-d.vat,0)+isnull(-d.tax,0)end    
 end  
 END as amount,  
   
  d.groupId, d.levelId,   
d.accId ,a.accDesc+''-''+ISNULL(st.description,''-'') accDesc, a.manualAccCode,a.autoAccCode,  
b.manualAccCode pManualAcccode,b.accdesc pAccdesc,b.autoAccCode pAutoAccCode,v.currencyType,v.totalAmount,v.fcTotalAmount  
from tblVoucher v inner join tblVoucherDetail d on v.branch_id = d.branch_id and v.id = d.voucher_id   
inner join tblAccount a on a.id = d.auto_acc_id  
inner join tblParentChildReport c on a.id = c.child_auto_acc_id  
inner join tblAccount b on b.id = c.parent_auto_acc_id  
  
--LEFT join SubledgerTransaction st on st.voucher_detail_Id=d.id-- new adder for subledger name  
--LEFT join tblSubledger s on s.Id=st.sub_ledger_Id--- new adder for subledger name  

left join(
select s.description,st.* from tblSubledger s 
inner join SubledgerTransaction st on s.Id=st.sub_ledger_Id
) st on st.voucher_detail_Id=d.id     -------------new update for duplicate
  
left outer join EmployeeGenInfo ep on v.preparedBy = Cast(ep.id as varchar (60))  
left outer join EmployeeGenInfo ec on v.checkedBy = Cast(ec.id as varchar (60))  
left outer join EmployeeGenInfo ea on v.approvedBy = Cast(ea.id as varchar (60))  
Where v.branch_id ='''+@branch_id + ''' and v.id =''' + @voucher_id + ''''   
)  
END
GO
/****** Object:  StoredProcedure [dbo].[proc_AutoVoucherCreate]    Script Date: 16-Jul-25 8:22:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
CREATE PROCEDURE [dbo].[proc_AutoVoucherCreate] @branch_id UniqueIdentifier, @voucherDate datetime,@PackageId int  
AS  
SET NOCOUNT ON  
BEGIN  
  
 Declare @currentDate DateTime  
 select @currentDate=currentDate from tblConfiguration where branch_id = @branch_id  
  
 Update accountTransaction SET isReconsiled = 1  where transdate = @currentDate and branch_id = @branch_id and isReconsiled=0  
   
   --Remove existing auto voucher  
 ------------------------------------  
 DELETE FROM tblVoucherDetail with (rowlock) where voucher_id in  
 (SELECT id FROM tblVoucher with (nolock) Where packageid=@PackageId and (isAutoGenerated = 1 or particulars='--Auto Generated--') and branch_id = @branch_id and voucherdate = @voucherDate)  
 and branch_id = @branch_id 
 DELETE FROM tblVoucher  with (rowlock) Where (isAutoGenerated = 1 or particulars='--Auto Generated--') and branch_id = @branch_id and voucherdate = @voucherDate  
 and  particulars not  in ( '--Auto voucher on Inventory Purchase--' ,'--Auto voucher on Inventory issue--','--Auto voucher on Inventory Sales/Return--') and packageId=@PackageId  
  
 --Fixing Transaction anomaly - P & I breakdown  
 -----------------------------------------------------  
 Update t with (rowlock) SET t.principalAmount = round(((t.transamount-IsNull(t.fine,0))/(a.disburseAmountSC*1.00/a.disburseamount)),2) from accountTransaction t   
 inner join customer c on t.customerId = c.customerId inner join LoanAccount a on t.accountNo = a.accountno  
 where t.branch_id = @branch_id and t.transdate =@voucherDate and product_type = 2 and transtype = 0   
 and (t.transamount-IsNull(t.fine,0)) <> IsNull(principalamount,0)+IsNull(servicecharge,0)  
  
 Update t with (rowlock) SET t.servicecharge = (t.transamount-IsNull(t.fine,0))-t.principalAmount from accountTransaction t inner join customer c on t.customerId = c.customerId    
 where t.branch_id = @branch_id and t.transdate =@voucherDate and product_type = 2 and transtype = 0   
 and (t.transamount-IsNull(t.fine,0)) <> IsNull(principalamount,0)+IsNull(servicecharge,0)  
 ---------------------------  
  
 --Fixing  P & I for 0 transamount  
 -----------------------------------------------------  
 update accounttransaction with(rowlock) set principalAmount=0,servicecharge=0,fine=0 where transamount=0 and (isNull(principalAmount,0)>0 or isNull(servicecharge,0)>0 or isNull(fine,0)>0) and product_type=2 and transtype=0  
 and branch_id=@branch_id    
 ---------------------------  
   
   ------------------Auto Voucher Create-----  
      declare @voucher_id uniqueIdentifier  
      declare @autoAcc_id uniqueIdentifier  
      declare @voucherAmount numeric(25,2)  
   declare @transAmount numeric(25,2)  
   declare @VoucherNo nvarchar (10)  
      declare @GLCode numeric(25)        
      declare @counterJV int =1  
     
 -----Start for transmode =0 and CR  
 -------------------------------------  
 Exec proc_autovoucherCreateSingle @branch_id, @voucherDate, 0,0,'R','--Auto Generated--',1  
   ------END for transmode =0 and CR  
   ---------------------------------------  
      
   ---------------Start for transmode =1 and BR  
     Exec proc_autovoucherCreateSingle @branch_id, @voucherDate, 2,1,'R','--Auto Generated--',1  
     
 ---------------END for transmode =1 and BR  
   
 ---------------Start for transmode =0 and CP  
    Exec proc_autovoucherCreateSingle @branch_id, @voucherDate, 1,0,'P','--Auto Generated--',1    
  
    ---------------END for transmode =0 and CP  
  
 ---------------Start for transmode =1 and BP  
     Exec proc_autovoucherCreateSingle @branch_id, @voucherDate, 3,1,'P','--Auto Generated--',1    
     
 ---------------END for transmode =1 and BP  
  
 ---------------Start for transmode =2 (bank Control) - Receipt   
 Exec proc_autovoucherCreateSingle @branch_id, @voucherDate, 4,2,'R','--Auto Generated--',1  
 ---------------End for transmode =2 (bank Control) - Receipt   
    
    ---------------Start for transmode =2 (bank Control) - Payment   
    Exec proc_autovoucherCreateSingle @branch_id, @voucherDate, 4,2,'P','--Auto Generated--',1  
 ---------------End for transmode =2 (bank Control) - Payment   
   
  
 ---------------Start for transmode =4 and JV  - AccountTransfer  
        
     select @voucherAmount =  isNull(sum(TransAmount),0) from Customer c with (nolock) inner join AccountTransaction at with(nolock) on c.id = at.customer_id   
  where c.customerStatus <> 'Transfer-out' and at.branch_id = @branch_id and at.TransType = 0 and product_type=2  and at.transMode = 4  and at.TransDate =  @voucherDate  
  and at.isReconsiled = 1  
 if(@voucherAmount > 0)  
 begin  
     select @voucher_id = NEWID()  
     INSERT INTO tblVoucher (branch_id,id, voucherdate, vouchertype, voucherstatus,postingStatus, chequeno, chequedate,   
     bankname,particulars, preparedBy, approvedBy, checkedBy,isAutoGenerated,totalAmount)    
     VALUES (@branch_id,@voucher_id,@voucherDate,4,0,0,'',NULL,'','--Loan Repaid from Savings--',null,null,null,1,@voucherAmount)  
   exec proc_set_voucher_no @voucher_id,@branch_id,@PackageId  
    
     select @VoucherNo = voucherno from tblVoucher where id= @voucher_id  
         
     
    DECLARE cur_AutoVoucherJV CURSOR FOR  
   
     select voucherAmount = isnull(SUM(TransAmount),0),spd.SavingProdGLCode from Customer c with (nolock) inner join AccountTransaction at with(nolock) on c.id = at.customer_id   
    inner join SavingsProductDef spd   
    on at.product_id = spd.id   
    where c.customerStatus <> 'Transfer-out' and at.branch_id = @branch_id and at.TransType = 1 and at.product_type = 1 and at.transMode = 4 and at.TransDate =  @voucherDate  
 and at.isReconsiled = 1  
    group by spd.SavingProdGLCode having isnull(SUM(TransAmount),0) > 0  
   
     union all  
  
    select voucherAmount = isnull(SUM(principalamount),0)*-1,lpd.LoanProductGLCode  from Customer c with (nolock) inner join AccountTransaction at with(nolock) on c.id = at.customer_id   
    inner join LoanProductDef lpd   
    on at.product_id = lpd.id   
   where c.customerStatus <> 'Transfer-out' and at.branch_id = @branch_id and at.TransType = 0 and at.product_type = 2 and at.transMode = 4 and at.TransDate = @voucherDate and at.isReconsiled = 1  
    group by lpd.LoanProductGLCode having isnull(SUM(principalamount),0) > 0  
      
    union all  
      
    select voucherAmount = isnull(SUM(servicecharge),0)*-1,scd.ServiceChargeGLCode  from Customer c with (nolock) inner join AccountTransaction at with(nolock) on c.id = at.customer_id   
    inner join LoanAccount lpd   
    on at.account_id = lpd.id   
    inner join ServiceChargeDef scd  
    on lpd.service_charg_id = scd.ServiceChargeId  
    where c.customerStatus <> 'Transfer-out' and at.branch_id = @branch_id and at.TransType = 0 and at.product_type = 2 and at.transMode = 4 and at.TransDate = @voucherDate and at.isReconsiled = 1  
    group by scd.ServiceChargeGLCode having isnull(SUM(servicecharge),0) > 0  
       
   OPEN cur_AutoVoucherJV   
   FETCH NEXT FROM cur_AutoVoucherJV    
   INTO @voucherAmount,@GLCode  
      
   WHILE @@FETCH_STATUS = 0   
   BEGIN    
      select @autoAcc_id = id from tblAccount where autoAccCode = @GLCode   
      INSERT INTO tblVoucherDetail  ----- for debit * creadit  
      ( branch_id, id, voucher_id, voucherno,[lineno], amount, groupId, levelId, accId,auto_acc_id)   
      VALUES (@branch_id, NEWID(), @voucher_id,@VoucherNo,@counterJV,@voucherAmount,  
      convert(numeric,substring(Convert(varchar,@GLCode),1,1)),  
      convert(numeric,substring(Convert(varchar,@GLCode),2,3)),  
      convert(numeric,substring(Convert(varchar,@GLCode),5,7)),@autoAcc_id)  
      set @counterJV = @counterJV+1  
      
    FETCH NEXT FROM cur_AutoVoucherJV    
    INTO  @voucherAmount,@GLCode  
  
   END  
   CLOSE cur_AutoVoucherJV   
   DEALLOCATE cur_AutoVoucherJV  
      end  
  
 ---------------END for transmode =4 and JV  
  
    
 Update v with (rowlock) set v.auto_acc_id = a.id from tblAccount a with (nolock)  
 inner join tblVoucherDetail v on a.groupId = v.groupId and a.levelId = v.levelId and a.accId = v.accId  
 Where v.auto_acc_id is null and v.branch_id = @branch_id  
  
 DECLARE @approverId UNIQUEIDENTIFIER  
 Select top 1 @approverId = approved_by_id from AccountTransaction with (nolock) Where branch_id = @branch_id and transDate = @voucherDate and  approved_by_id is not null and isReconsiled = 1  
 order by transDate desc  
  
 Update v with (rowlock) SET v.totalAmount =   
 IsNull((select SUM(amount) from tblVoucherDetail with (nolock) where branch_id = v.branch_id and voucher_id = v.id and amount >= 0),0), v.approvedBy = @approverId,  
 v.currencyType = 'TZS'  from tblVoucher v where IsNull(v.totalAmount,0) = 0 and v.branch_id = @branch_id   
 and v.voucherdate = @voucherDate and isAutoGenerated = 1  
 --and v.id =@voucher_id   
  
 update tblVoucher with(rowlock) set currencyType ='TZS'  where currencyType is null and branch_id = @branch_id  
 update tblVoucher with(rowlock) set approvedBy =@approverId  where approvedBy is null and branch_id = @branch_id   
END
GO
