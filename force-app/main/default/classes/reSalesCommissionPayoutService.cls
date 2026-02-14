public class reSalesCommissionPayoutService {

    Public static void getCommissionLines(List<MonthlySalesTarget__c> monthlySalesTarget, Date transferStartDate,Date transferEndDate, List<CommissionLineItem__c> lstCommisionLineItems,  Map<Id,SalesOrder__c> mapSalesOrders, Set<Id> salesOrderIds){
        Set<Id> salesManagersId = new Set<Id>();
        Set<Id> salesOrderIdSet = new Set<Id>();
        Map<Id,MonthlySalesTarget__c> mapMonthlySalesTarget = new Map<Id,MonthlySalesTarget__c>();
        Map<Id,List<SalesOrder__c>> salesordersMap = new Map<Id,List<SalesOrder__c>>();
        Map<Id,List<CommissionLineItem__c>> mapCommissionLineItemsRelManagers = new Map<Id,List<CommissionLineItem__c>>();
        Map<SalesOrder__c, Opportunity> soOppMap = new Map<SalesOrder__c, Opportunity>();
        for(MonthlySalesTarget__c objMonthlySalesTarget: monthlySalesTarget){
            salesManagersId.add(objMonthlySalesTarget.ResourceName__c);
            mapMonthlySalesTarget.put(objMonthlySalesTarget.ResourceName__c,objMonthlySalesTarget);
        }
        system.debug('mapMonthlySalesTarget:::'+mapMonthlySalesTarget);
        system.debug('transferStartDate:::'+transferStartDate);
        system.debug('transferEndDate:::'+transferEndDate);
        
        Id resaleRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(ResaleConstants.RESALE_RECORDTYPE).getRecordTypeId();
        List<Opportunity> resaleOpportunityList = [SELECT
                                                   Id,
                                                   SalesOrder__c
                                                  
                                                   FROM Opportunity
                                                   WHERE RecordTypeId =:resaleRecordTypeId
                                                   AND TransferredDate__c>=: transferStartDate 
                                                   AND TransferredDate__c <=: transferEndDate
                                                   AND SalesOrder__c != NULL
                                                   AND SalesOrder__r.Status__c =:Constants.UNIT_STATUS_SOLD 
                                                   AND OwnerId IN : salesManagersId
                                                   AND Transferred__c = True];
        
        system.debug('resaleOpportunityList::'+resaleOpportunityList);
        for(Opportunity opportunity: resaleOpportunityList){
            salesOrderIdSet.add(opportunity.SalesOrder__c);
        }
      
        for(SalesOrder__c salesOrder : [SELECT SalesManager__c, SalesManager__r.Name, SalesManager__r.UserRole.Name,Status__c,EquityPercentage__c,AgentType__c, InventoryLaunch__c,Account__r.CustomerSubType__c,Unit__c,Unit__r.Name,SoldDate__c,NetAmount__c,Team__c,
                                        Opportunity__r.OwnerId,(SELECT  Commission70__c,Commission30__c,PayableCommission__c, CommissionAmount__c,SalesOrder__c,SalesManager__c FROM CommissionLineItems__r WHERE CommissionType__c =: Constants.COMMISSION_LINE_INTERNAL_COMMISSION
                                                               AND SalesManager__c IN: salesManagersId) 
                                        ,(SELECT Id, OwnerId FROM Opportunities__r) FROM SalesOrder__c WHERE Id IN: salesOrderIdSet]) {
                                            if(salesOrder.Opportunities__r.size()>0){
                                                salesOrderIds.add(salesOrder.Id);
                                                mapSalesOrders.put(salesOrder.Id, salesOrder);
                                                List<SalesOrder__c> lstSalesOrders = new List<SalesOrder__c>();
                                                if(salesordersMap.containsKey(salesOrder.Opportunities__r[0].OwnerId)){
                                                    lstSalesOrders = salesordersMap.get(salesOrder.Opportunities__r[0].OwnerId);
                                                }
                                                lstSalesOrders.add(salesOrder);
                                                salesordersMap.put(salesOrder.Opportunities__r[0].OwnerId, lstSalesOrders);
                                                
                                                List<CommissionLineItem__c> lstInLCommissionLineItems = new List<CommissionLineItem__c>();
                                                if(mapCommissionLineItemsRelManagers.containsKey(salesOrder.Opportunity__r.OwnerId)){
                                                    lstInLCommissionLineItems = mapCommissionLineItemsRelManagers.get(salesOrder.Opportunities__r[0].OwnerId);
                                                }
                                                
                                                lstInLCommissionLineItems.addAll(salesOrder.CommissionLineItems__r);
                                                system.debug('lstInLCommissionLineItems:::'+lstInLCommissionLineItems);
                                                mapCommissionLineItemsRelManagers.put(salesOrder.Opportunities__r[0].OwnerId, lstInLCommissionLineItems);
                                                
                                            }
                                        }
        
        system.debug('mapCommissionLineItemsRelManagers::'+mapCommissionLineItemsRelManagers);
       
        for(Id salesManagerId : salesordersMap.keySet()){
            if(mapMonthlySalesTarget.containsKey(salesManagerId)){
                MonthlySalesTarget__c objMonthlySalesTarget = mapMonthlySalesTarget.get(salesManagerId);
                if(mapCommissionLineItemsRelManagers.containsKey(salesManagerId) && salesordersMap.containsKey(salesManagerId)){
                    List<SalesOrder__c> lstSalesOrders = salesordersMap.get(salesManagerId);
                    for(CommissionLineItem__c objCommissionLineItem : mapCommissionLineItemsRelManagers.get(salesManagerId)){
                        if(objMonthlySalesTarget.AcceleratorCommissionAmount__c != 0 && objMonthlySalesTarget.AcceleratorPercentage__c != null){
                            objCommissionLineItem.AcceleratorAmount__c = ((objCommissionLineItem.PayableCommission__c * objMonthlySalesTarget.AcceleratorPercentage__c)/100);
                        }
                        
                        objCommissionLineItem.PayableCommission__c = (objCommissionLineItem.CommissionAmount__c);
                        objCommissionLineItem.TotalPayableCommission__c = objCommissionLineItem.AcceleratorAmount__c + objCommissionLineItem.PayableCommission__c;
                    	lstCommisionLineItems.add(objCommissionLineItem);
                    }
                }
            }
        }
        system.debug('lstCommisionLineItems::'+lstCommisionLineItems);
    }
    public static void getExistingCommissionPayoutLines(Map<String,CommissionPayoutLine__c> mapExistingCommissionPayOuts, List<CommissionLineItem__c> lstCommisionLineItems){
        List<CommissionPayoutLine__c> commissionPayoutLineItems = [SELECT BrokerHeadPayoutAmount__c, CCOPayoutAmount__c, CommissionLineItem__c,
                                                                   CommissionLineItem__r.SalesOrder__c, DirectorPayoutAmount__c,
                                                                   SalesOrder__r.InventoryLaunch__c,SalesOrder__r.EquityPercentage__c,
                                                                   ExecDirectorPayoutAmount__c,CorporateWealthPayoutAmount__c, FutureCommission__c,
                                                                   LandHead__c,MonthlySalesTarget__c, PayoutAmount__c,
                                                                   SalesHeadPayoutAmount__c,SalesManager__c 
                                                                   FROM CommissionPayoutLine__c
                                                                   WHERE CommissionLineItem__c IN: lstCommisionLineItems];
        
        for(CommissionPayoutLine__c commissionPayoutLine : commissionPayoutLineItems) {
            mapExistingCommissionPayOuts.put(commissionPayoutLine.CommissionLineItem__c, commissionPayoutLine);
        }
    }
    
    public static void getCalculatedCommissionPayouts(Map<String,CommissionPayoutLine__c> mapExistingCommissionPayOuts, List<CommissionLineItem__c> lstCommisionLineItems, String targetMonth, String targetYear, List<CommissionPayoutLine__c> objCommisionPayoutLineItemList, Map<Id, MonthlySalesTarget__c> managerBasedMonSalesTarget){
        
        
        for(CommissionLineItem__c CommissionLineItem: lstCommisionLineItems){
            MonthlySalesTarget__c objMontlySalesTarget = managerBasedMonSalesTarget.get(CommissionLineItem.SalesManager__c);
            CommissionPayoutLine__c objCommisionPayoutLine = new CommissionPayoutLine__c();
            
            if(mapExistingCommissionPayOuts.get(CommissionLineItem.id) != null ) {
                objCommisionPayoutLine.Id = mapExistingCommissionPayOuts.get(CommissionLineItem.Id).Id;
                
            }

            if(mapExistingCommissionPayOuts.get(CommissionLineItem.id) == null) {
                objCommisionPayoutLine.CommissionLineItem__c = CommissionLineItem.Id;
            }   
            objCommisionPayoutLine.SalesManager__c = CommissionLineItem.SalesManager__c;
            objCommisionPayoutLine.SalesOrder__c = CommissionLineItem.SalesOrder__c;
            objCommisionPayoutLine.PayoutAmount__c = CommissionLineItem.TotalPayableCommission__c;
            objCommisionPayoutLine.PayoutDate__c = (Date.newInstance(Integer.valueOf(targetYear), Integer.valueOf(targetMonth), 01)).addMonths(1);
            objCommisionPayoutLine.FutureCommission__c = Constants.COMMISSIONCURRENT;
            objCommisionPayoutLine.RecalculatedDate__c = system.today();
            objCommisionPayoutLine.MonthlySalesTarget__c = objMontlySalesTarget!= null ? objMontlySalesTarget.Id : null;
            objCommisionPayoutLine.DirectorPayoutAmount__c = ((15*CommissionLineItem.TotalPayableCommission__c)/100);
            objCommisionPayoutLine.ExecDirectorPayoutAmount__c = ((40*objCommisionPayoutLine.DirectorPayoutAmount__c)/100);
            objCommisionPayoutLine.CCOPayoutAmount__c = ((120*objCommisionPayoutLine.ExecDirectorPayoutAmount__c)/100);
            objCommisionPayoutLineItemList.add(objCommisionPayoutLine);
        }
    }
    
    public static void commisionPayoutLines(Map<String, object> results, Map<Id, MonthlySalesTarget__c> managerBasedMonSalesTarget,List<MonthlySalesTarget__c> lstMonthlySalesTarget, String targetMonth, String targetYear, boolean isBatch, boolean isValidateCommission){
        Map<Id, Map<String, User>> userDetails = new Map<Id, Map<String, User>>();
		set<Id> userIds = new set<Id>();
		Map<Id, SalesOrder__c> mapSalesOrders = new Map<Id, SalesOrder__c>();
		List<CommissionLineItem__c> lstCommisionLineItems = new List<CommissionLineItem__c>();
		Set<Id> salesOrderIds = new Set<Id>();
        Map<String,CommissionPayoutLine__c> mapExistingCommissionPayOuts = new Map<String,CommissionPayoutLine__c>();
        List<CommissionPayoutLine__c> objCommisionPayoutLineItemList = new List<CommissionPayoutLine__c>();
        
        integer numberOfDays = date.daysInMonth(integer.valueOf(targetYear), integer.valueOf(targetMonth));
		date transferStartDate = date.newInstance(integer.valueOf(targetYear), integer.valueOf(targetMonth), 1);
		date transferEndDate = date.newInstance(integer.valueOf(targetYear), integer.valueOf(targetMonth), numberOfDays);
        
        getCommissionLines(lstMonthlySalesTarget, transferStartDate, transferEndDate, lstCommisionLineItems, mapSalesOrders, salesOrderIds);
        getExistingCommissionPayoutLines(mapExistingCommissionPayOuts, lstCommisionLineItems);
        getCalculatedCommissionPayouts(mapExistingCommissionPayOuts, lstCommisionLineItems, targetMonth, targetYear, objCommisionPayoutLineItemList, managerBasedMonSalesTarget);
        system.debug('lstCommisionLineItems::'+lstCommisionLineItems);
        system.debug('mapExistingCommissionPayOuts::'+mapExistingCommissionPayOuts);
        
        if(!lstCommisionLineItems.isEmpty()){ update lstCommisionLineItems; }  
        
        if(!objCommisionPayoutLineItemList.isEmpty()){ upsert objCommisionPayoutLineItemList; }
        
        results.put('payoutLines', objCommisionPayoutLineItemList);
        results.put('lstCommisionLineItems', lstCommisionLineItems);
        results.put('mapExistingCommissionPayOuts', mapExistingCommissionPayOuts);
        results.put('mapSalesOrders', mapSalesOrders);
    }
    
    public static void validateCommissionPaylineItems(List<CommissionPayoutLine__c> lstCommissionPaylines,   List<CommissionLineItem__c> lstCommisionLineItems,  Map<Id, SalesOrder__c> mapSalesOrders,	Map<String,CommissionPayoutLine__c> mapExistingCommissionPayOuts, String strMonth, String strYear){
                                                            
        MonthlySalesTarget__c objMonthlySalesTargetParent = new MonthlySalesTarget__c();
        system.debug('lstCommissionPaylines::::::::'+lstCommissionPaylines);
         system.debug('lstCommisionLineItems::::::::'+lstCommisionLineItems);
        List<CommissionPayoutLine__c> allCommissionPayoutLineList = [SELECT AcceleratorAmount__c,AccumulatedAmount__c,AmountExclAccelerator__c,AmountInclAccelerator__c,BrokerAgencyAccount__c,BrokerHeadPayoutAmount__c,BrokerManager__c,CCOPayoutAmount__c,CommissionLineItem__c,CorporateWealthPayoutAmount__c,CreatedById,CreatedDate,CurrencyIsoCode,DirectorPayoutAmount__c,Equity__c,erpid__c,ExecDirectorPayoutAmount__c,FutureCommission__c,Id,LandHead__c,LastModifiedById,LastModifiedDate,MonthlySalesTarget__c,Name,PaidDate__c,PayoutAmount__c,PayoutDate__c,PayoutStatus__c,ProjectCode__c,RecalculatedDate__c,SalesHeadPayoutAmount__c,SalesManager__c,SalesOrder__c,SoldDate__c,UnitNumber__c FROM CommissionPayoutLine__c WHERE Id in:lstCommissionPaylines];
        List<MonthlySalesTarget__c> lstMonthParents = [SELECT id FROM MonthlySalesTarget__c WHERE MonthlySalesTarget__c = NULL AND IsParent__c = TRUE AND TargetMonth__c =:strMonth AND TargetYear__c =:strYear AND Team__c = 'ReSales' LIMIT 1];                                                   
       
        if(lstMonthParents.isEmpty()){
            objMonthlySalesTargetParent.TargetMonth__c = strMonth;
            objMonthlySalesTargetParent.TargetYear__c = strYear;
            
            objMonthlySalesTargetParent.Team__c = 'ReSales';
            objMonthlySalesTargetParent.TargetAmount__c = 00;
            objMonthlySalesTargetParent.InventoryTargetAmount__c = 00;
            objMonthlySalesTargetParent.LaunchTargetAmount__c = 00;
            objMonthlySalesTargetParent.IsParent__c = TRUE;
            insert objMonthlySalesTargetParent;
        }else{
            objMonthlySalesTargetParent = lstMonthParents[0];
        }
        system.debug('objMonthlySalesTargetParent:::'+objMonthlySalesTargetParent);
        system.debug('lstMonthParents:::'+lstMonthParents);
        
        Map<String,CommissionPayout__mdt> commissionPayoutMetaData = new Map<String,CommissionPayout__mdt>();
        for(CommissionPayout__mdt objCommissionPayOutMD : CommissionPayout__mdt.getAll().values()){
            commissionPayoutMetaData.put(objCommissionPayOutMD.Role__c, objCommissionPayOutMD);  
        }
        
        SalesOrder__c objSalesOrder = new SalesOrder__c();
        Map<Id, CommissionLineItem__c> commissionLineItemsMap = new Map<Id, CommissionLineItem__c>(lstCommisionLineItems);
        
        system.debug('commissionLineItemsMap::::::::'+commissionLineItemsMap);
        
        Map<Id, Decimal> usersSumUpValues =  new Map<Id, Decimal>();
        Map<Id, Decimal> managersMontlySalesSum = new Map<Id,Decimal>();
        Decimal ccoCommission = 0;
        Decimal dirCommission = 0;
        Decimal exucutiveDirCommission = 0;
        
        for(CommissionPayoutLine__c objPayLine : allCommissionPayoutLineList){
            System.debug('objPayLine.CommissionLineItem__c:::'+objPayLine.CommissionLineItem__c);
            system.debug('commissionLineItemsMap.containsKey(objPayLine.CommissionLineItem__c)::'+commissionLineItemsMap.containsKey(objPayLine.CommissionLineItem__c));
            if(commissionLineItemsMap.containsKey(objPayLine.CommissionLineItem__c)){
                objSalesOrder = mapSalesOrders.get(commissionLineItemsMap.get(objPayLine.CommissionLineItem__c).SalesOrder__c);
                 Decimal managerSalesAmount = 0;
                if(managersMontlySalesSum.containsKey(objPayLine.SalesManager__c)){
                    managerSalesAmount = managersMontlySalesSum.get(objPayLine.SalesManager__c); 
                }
                managerSalesAmount = managerSalesAmount + objPayLine.PayoutAmount__c;
                managersMontlySalesSum.put(objPayLine.SalesManager__c, managerSalesAmount);
                
                system.debug('managersMontlySalesSum::'+managersMontlySalesSum);
                
                if(objPayLine.CCOPayoutAmount__c != NULL){
                    ccoCommission = ccoCommission + objPayLine.CCOPayoutAmount__c;
                }
                if(objPayLine.DirectorPayoutAmount__c != NULL){
                    dirCommission = dirCommission + objPayLine.DirectorPayoutAmount__c; 
                }
                if(objPayLine.ExecDirectorPayoutAmount__c != NULL){
                    exucutiveDirCommission = exucutiveDirCommission + objPayLine.ExecDirectorPayoutAmount__c;  
                }
            }
        }
        
        List<Id> lstResourceIds =  new List<Id>();
        lstResourceIds.addAll(managersMontlySalesSum.keySet());
        System.debug('lstResourceIds::'+lstResourceIds);
        
        if(managersMontlySalesSum.containsKey(commissionPayoutMetaData.get(Constants.EXECUTIVE_DIRECTOR_OF_SALES).HeadUserId__c)){
            managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.EXECUTIVE_DIRECTOR_OF_SALES).HeadUserId__c, 
                                       managersMontlySalesSum.get(commissionPayoutMetaData.get(Constants.EXECUTIVE_DIRECTOR_OF_SALES).HeadUserId__c) + exucutiveDirCommission);
        }
        if(managersMontlySalesSum.containsKey(commissionPayoutMetaData.get(Constants.CCO).HeadUserId__c)){
            managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.CCO).HeadUserId__c, managersMontlySalesSum.get(commissionPayoutMetaData.get(Constants.CCO).HeadUserId__c) + ccoCommission);
        }
        if(managersMontlySalesSum.containsKey(commissionPayoutMetaData.get(Constants.ASSOCIATE_DIRECTOR_OF_SALE).HeadUserId__c)){
            managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.ASSOCIATE_DIRECTOR_OF_SALE).HeadUserId__c, managersMontlySalesSum.get(commissionPayoutMetaData.get(Constants.ASSOCIATE_DIRECTOR_OF_SALE).HeadUserId__c) + dirCommission);
        }
        
        List<MonthlySalesTarget__c> lstMonthlySalesTarget = new List<MonthlySalesTarget__c>();
        for(MonthlySalesTarget__c objMonthlySales :[SELECT ResourceName__c,LaunchCommission__c, InventoryCommission__c,TotalPayableCommission__c FROM MonthlySalesTarget__c Where  ResourceName__c IN: managersMontlySalesSum.keySet() AND Team__c = 'ReSales']){
           system.debug('objMonthlySales:::::'+objMonthlySales);
            Decimal totalCommission = 0;
            if(managersMontlySalesSum.containsKey(objMonthlySales.ResourceName__c)){
                totalCommission = managersMontlySalesSum.get(objMonthlySales.ResourceName__c);
            }
            objMonthlySales.TotalPayableCommission__c = (totalCommission).setScale(2);
            objMonthlySales.MonthlySalesTarget__c = objMonthlySalesTargetParent.Id;
            lstMonthlySalesTarget.add(objMonthlySales);
        }
        
        if(!lstCommissionPaylines.isEmpty()){ upsert allCommissionPayoutLineList ;}
        
        if(!lstCommisionLineItems.isEmpty()){ update lstCommisionLineItems;}
        system.debug('lstMonthlySalesTarget>>>>>'+lstMonthlySalesTarget);
        if(!lstMonthlySalesTarget.isEmpty()){update lstMonthlySalesTarget; }
    }
}