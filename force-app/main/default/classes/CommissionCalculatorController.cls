public class CommissionCalculatorController {
 
    
    @AuraEnabled
    public static List<User> getSaleManagers(String ProfileName){
        List<Profile> profileList = [Select Id from Profile where Name =: ProfileName];
        system.debug('profileList::'+profileList);
        List<User> salesManagerList = [SELECT
                                      Id,
                                      Name
                                      FROM 
                                      User
                                      WHERE Profile.Id =: profileList[0].Id 
                                      AND isActive = true];
        return salesManagerList;
    }
    
    @AuraEnabled
    public static List<payoutWrapper> getSaleManagersCommission(String ProfileName, String SalesManagerId, String strMonth, String strYear){
        Map<Id, MonthlySalesTarget__c> managerBasedMonSalesTarget = new Map<Id, MonthlySalesTarget__c>();
        List<MonthlySalesTarget__c> lstMonthlySalesTarget = new List<MonthlySalesTarget__c>();
         List<payoutWrapper> wrapperList = new List<payoutWrapper>();
        List<MonthlySalesTarget__c> monthlySalesTarget = [SELECT
                                                          AcceleratorCommissionAmount__c,
                                                          AcceleratorPercentage__c,
                                                          TargetAmount__c,
                                                          TargetMonth__c,
                                                          KPI1__c,
                                                          KPI2__c,
                                                          TargetYear__c,
                                                          AcceleratorTargetAmount__c,
                                                          ResourceName__c,
                                                          KPIPayoutPercentage__c
                                                          FROM MonthlySalesTarget__c
                                                          WHERE TargetMonth__c =: strMonth 
                                                          AND TargetYear__c =: strYear 
                                                          AND ResourceName__c=:SalesManagerId 
                                                          AND ResourceName__r.isActive = true];
        
        system.debug('monthlySalesTarget:::'+monthlySalesTarget);
        for(MonthlySalesTarget__c objMSaleTarget : monthlySalesTarget){
            managerBasedMonSalesTarget.put(objMSaleTarget.ResourceName__c, objMSaleTarget);
            lstMonthlySalesTarget.add(objMSaleTarget); 
        }
        Map<String, object> results = new Map<String, object>(); 
        Map<String,list<CommissionPayoutLine__c>> mapExistingCommissionPayOuts = new Map<String,list<CommissionPayoutLine__c>>();
        List<CommissionPayoutLine__c> payoutLines = new List<CommissionPayoutLine__c>();
        List<CommissionLineItem__c> lstCommisionLineItems = new  List<CommissionLineItem__c>();
        Map<Id, SalesOrder__c> mapSalesOrders = new Map<Id, SalesOrder__c>();
       
        if(ProfileName == 'Sales Manager'){
            CommissionPayoutService.commisionPayoutLines(results, managerBasedMonSalesTarget, lstMonthlySalesTarget,strMonth, strYear, true, true);
        }else if(ProfileName == 'Broker Manager'){
           results = calculateBrokerManagerCommission(managerBasedMonSalesTarget, lstMonthlySalesTarget,strMonth, strYear, SalesManagerId);                                      
        }
       
        
        payoutLines =  (List<CommissionPayoutLine__c>)results.get('payoutLines');
        lstCommisionLineItems = (List<CommissionLineItem__c>)results.get('lstCommisionLineItems');
        if(ProfileName == 'Sales Manager'){
            mapSalesOrders = (Map<Id, SalesOrder__c>)results.get('mapSalesOrders');
            mapExistingCommissionPayOuts = (Map<String,list<CommissionPayoutLine__c>>)results.get('mapExistingCommissionPayOuts');
            
            for(String managerId : mapExistingCommissionPayOuts.keySet()){
                if(!mapExistingCommissionPayOuts.get(managerId).isEmpty()){
                    payoutLines.addAll(mapExistingCommissionPayOuts.get(managerId));
                }
            }
        }
        system.debug('payoutLines::'+payoutLines);
        system.debug('lstCommisionLineItems::'+lstCommisionLineItems);
        
        Map<Id, CommissionLineItem__c> commissionLineItemMap = new Map<Id, CommissionLineItem__c>([Select
                                                                                                   Id,
                                                                                                   Name,
                                                                                                   Unit_Number__c,
                                                                                                   SalesOrder__r.name,
                                                                                                   SalesOrder__r.EquityPercentage__c,
                                                                                                   SalesManager__r.Name,
                                                                                                   SalesOrder__r.Unit__c
                                                                                                   From CommissionLineItem__c
                                                                                                   where Id in: lstCommisionLineItems]);
       
        system.debug('commissionLineItemMap::'+commissionLineItemMap);
        
        system.debug('payoutLines::'+payoutLines);
            
            
       
       
        
        for(CommissionPayoutLine__c payoutLine: payoutLines){
            if(commissionLineItemMap.containsKey(payoutLine.CommissionLineItem__c)){
                system.debug('commissionLineItemMap::'+commissionLineItemMap.get(payoutLine.CommissionLineItem__c));
                payoutWrapper wrap = new payoutWrapper();
                wrap.payoutLine = payoutLine;
                wrap.commissionName = commissionLineItemMap.get(payoutLine.CommissionLineItem__c).name;
                wrap.equity = commissionLineItemMap.get(payoutLine.CommissionLineItem__c).SalesOrder__r.EquityPercentage__c;
                wrap.unitName = commissionLineItemMap.get(payoutLine.CommissionLineItem__c).Unit_Number__c;
                wrap.unitId = commissionLineItemMap.get(payoutLine.CommissionLineItem__c).SalesOrder__r.Unit__c;
                wrap.salesOrderName = commissionLineItemMap.get(payoutLine.CommissionLineItem__c).SalesOrder__r.name;
                wrap.salesManagerName = commissionLineItemMap.get(payoutLine.CommissionLineItem__c).SalesManager__r.Name;
                wrapperList.add(wrap);
            }
        }
        system.debug('wrapperList::'+wrapperList);
        return wrapperList;
        //return results.get('payoutLines');
    }
    
    public class payoutWrapper{
        @AuraEnabled  public CommissionPayoutLine__c payoutLine{get; set;}
        @AuraEnabled  public Decimal equity {get; set;}
        @AuraEnabled  public String commissionName {get; set;}
        @AuraEnabled  public String unitName {get; set;}
        @AuraEnabled  public String unitId {get; set;}
        @AuraEnabled  public String salesOrderName {get; set;}
        @AuraEnabled  public String salesManagerName {get; set;}
    }
    
    public static Map<String, object> calculateBrokerManagerCommission(Map<Id, MonthlySalesTarget__c> managerBasedMonSalesTarget,
											List<MonthlySalesTarget__c> lstMonthlySalesTarget,
                                            String strMonth, String strYear, String SalesManagerId){
                                                system.debug('strMonth::'+strMonth);
                                                 system.debug('strYear::'+strYear);
       	Map<Id,Map<Id,List<SalesOrder__c>>> salesOrderDetails = new Map<Id,Map<Id,List<SalesOrder__c>>>();
                                                
        integer numberOfDays = date.daysInMonth(integer.valueOf(strYear), integer.valueOf(strMonth));
         date yearStartDate = date.newInstance(integer.valueOf(strYear), integer.valueOf('1'), 1);                                   
        date soldStartDate = date.newInstance(integer.valueOf(strYear), integer.valueOf(strMonth), 1);
        date soldEndDate = date.newInstance(integer.valueOf(strYear), integer.valueOf(strMonth), numberOfDays);
		Map<Id,Decimal> mapCustomerCapNetAmount = new Map<Id,Decimal>();
		List<CommissionLineItem__c> lstCommissionLineItems = new List<CommissionLineItem__c>();
          
       /*    for(SalesOrder__c objSalesOrder :[SELECT Opportunity__c,Opportunity__r.BrokerAgencyAccount__c, 
                                                                                  Status__c,EquityPercentage__c,AgentType__c,InventoryLaunch__c,
                                                                                  Opportunity__r.BrokerAgencyAccount__r.OwnerId,
                                                                                  SoldDate__c,NetAmount__c,Team__c,Account__c,Account__r.ResidentStatus__pc,
                                                                                  Account__r.BillingCity,
                                                                                  (SELECT Commission30__c,Commission70__c,PayableCommission__c,
                                                                                   CommissionAmount__c,SalesOrder__c,SalesManager__c FROM CommissionLineItems__r 
                                                                                   Where CommissionType__c =: Constants.COMMISSION_LINE_EXTERNAL_COMMISSION )  FROM SalesOrder__c
                                                                                  WHERE AgentType__c = : Constants.OPPORTUINTY_AGENT_TYPE_INDIRECT 
                                                                                  
                                                                                  AND ((SoldDate__c >=: yearStartDate AND SoldDate__c <=: soldEndDate) 
                                                                                       OR (SalesApprovedDate__c >=: yearStartDate AND SalesApprovedDate__c <=: soldEndDate))
                                              AND Opportunity__r.BrokerAgencyAccount__r.OwnerId =: SalesManagerId]){
                                                 
                                                Decimal customerCapNetAmount = 0;  
                                                  if(mapCustomerCapNetAmount.containsKey(objSalesOrder.Opportunity__r.BrokerAgencyAccount__c)){
                                                      customerCapNetAmount = mapCustomerCapNetAmount.get(objSalesOrder.Opportunity__r.BrokerAgencyAccount__c);
                                                      
                                                  }
                                                  customerCapNetAmount = customerCapNetAmount + objSalesOrder.NetAmount__c; 
                                                  mapCustomerCapNetAmount.put(objSalesOrder.Opportunity__r.BrokerAgencyAccount__c, customerCapNetAmount);                                               
                                              } 
                                                
                                                System.debug('mapCustomerCapNetAmount:::'+mapCustomerCapNetAmount); */
                                         //  mapCustomerCapNetAmount.put(SalesManagerId, customerCapNetAmount);  
                                                
                             List<SalesOrder__c> objSalesOrderList = [SELECT Opportunity__c,Opportunity__r.BrokerAgencyAccount__c, 
                                                                                  Status__c,EquityPercentage__c,AgentType__c,InventoryLaunch__c,
                                                                                  Opportunity__r.BrokerAgencyAccount__r.OwnerId,
                                                                                  SoldDate__c,NetAmount__c,Team__c,Account__c,Account__r.ResidentStatus__pc,
                                                                                  Account__r.BillingCity,
                                                                                  (SELECT Commission30__c,Commission70__c,PayableCommission__c,
                                                                                   CommissionAmount__c,SalesOrder__c,SalesManager__c FROM CommissionLineItems__r 
                                                                                   Where CommissionType__c =: Constants.COMMISSION_LINE_EXTERNAL_COMMISSION )  FROM SalesOrder__c
                                                                                  WHERE AgentType__c = : Constants.OPPORTUINTY_AGENT_TYPE_INDIRECT 
                                                                                  
                                                                                  AND ((SoldDate__c >=: soldStartDate AND SoldDate__c <=: soldEndDate) 
                                                                                       OR (SalesApprovedDate__c >=: soldStartDate AND SalesApprovedDate__c <=: soldEndDate))
                                                                                  AND Opportunity__r.BrokerAgencyAccount__r.OwnerId =: SalesManagerId];   
                                                System.debug('objSalesOrderList::'+objSalesOrderList);
                                                 System.debug('objSalesOrderList size()::'+objSalesOrderList.size());   
                                                
                                                
                                                for(SalesOrder__c objSalesOrder :[SELECT Opportunity__c,Opportunity__r.BrokerAgencyAccount__c, 
                                                                                  Status__c,EquityPercentage__c,AgentType__c,InventoryLaunch__c,
                                                                                  Opportunity__r.BrokerAgencyAccount__r.OwnerId,
                                                                                  SoldDate__c,NetAmount__c,Team__c,Account__c,Account__r.ResidentStatus__pc,
                                                                                  Account__r.BillingCity,
                                                                                  (SELECT Commission30__c,Commission70__c,PayableCommission__c,
                                                                                   CommissionAmount__c,SalesOrder__c,SalesManager__c FROM CommissionLineItems__r 
                                                                                   Where CommissionType__c =: Constants.COMMISSION_LINE_EXTERNAL_COMMISSION )  FROM SalesOrder__c
                                                                                  WHERE AgentType__c = : Constants.OPPORTUINTY_AGENT_TYPE_INDIRECT 
                                                                                  
                                                                                  AND ((SoldDate__c >=: soldStartDate AND SoldDate__c <=: soldEndDate) 
                                                                                       OR (SalesApprovedDate__c >=: soldStartDate AND SalesApprovedDate__c <=: soldEndDate))
                                                                                  AND Opportunity__r.BrokerAgencyAccount__r.OwnerId =: SalesManagerId]){
                    system.debug('objSalesOrder:::'+objSalesOrder);                             
                 lstCommissionLineItems.addAll(objSalesOrder.CommissionLineItems__r);  
				  Decimal customerCapNetAmount = 0;  
                                                  if(mapCustomerCapNetAmount.containsKey(objSalesOrder.Opportunity__r.BrokerAgencyAccount__c)){
                                                      customerCapNetAmount = mapCustomerCapNetAmount.get(objSalesOrder.Opportunity__r.BrokerAgencyAccount__c);
                                                      
                                                  }
                                                  customerCapNetAmount = customerCapNetAmount + objSalesOrder.NetAmount__c; 
                                                  mapCustomerCapNetAmount.put(objSalesOrder.Opportunity__r.BrokerAgencyAccount__c, customerCapNetAmount); 
                                                  
                   Map<Id,List<SalesOrder__c>> brokerInfo = new Map<Id,List<SalesOrder__c>>();
                   if(salesOrderDetails.containsKey(objSalesOrder.Opportunity__r.BrokerAgencyAccount__r.OwnerId)){
                       brokerInfo = salesOrderDetails.get(objSalesOrder.Opportunity__r.BrokerAgencyAccount__r.OwnerId);
                       List<SalesOrder__c> lstSalesOrders =  new List<SalesOrder__c>();
                       if(brokerInfo.containsKey(objSalesOrder.Opportunity__r.BrokerAgencyAccount__c)){
                           lstSalesOrders = brokerInfo.get(objSalesOrder.Opportunity__r.BrokerAgencyAccount__c);
                       }
                       lstSalesOrders.add(objSalesOrder);
                       brokerInfo.put(objSalesOrder.Opportunity__r.BrokerAgencyAccount__c, lstSalesOrders);
                   }else{
                       brokerInfo.put(objSalesOrder.Opportunity__r.BrokerAgencyAccount__c, new List<SalesOrder__c>{objSalesOrder});
                   }
                   salesOrderDetails.put(objSalesOrder.Opportunity__r.BrokerAgencyAccount__r.OwnerId, brokerInfo);
        	}
			Map<Id, CommissionPayoutLine__c> mapCommissionPayoutLines = new Map<Id, CommissionPayoutLine__c>();
			for(CommissionPayoutLine__c objCommissionPayout : [SELECT CommissionLineItem__c,PayoutStatus__c,PayoutAmount__c,BrokerManager__c FROM CommissionPayoutLine__c WHERE 
                                                               CommissionLineItem__c IN:lstCommissionLineItems]){
              mapCommissionPayoutLines.put(objCommissionPayout.CommissionLineItem__c, objCommissionPayout);                                      
			}
        system.debug('salesOrderDetails>>>>>>>>'+salesOrderDetails);
		system.debug('mapCustomerCapNetAmount>>>>>>>>'+mapCustomerCapNetAmount);
		Map<String, object> results = BrokerManagerCommissionService.brokerManagerCommission(salesOrderDetails, managerBasedMonSalesTarget,  mapCustomerCapNetAmount,strMonth,strYear, mapCommissionPayoutLines, true);
        return results;
    }
    
}