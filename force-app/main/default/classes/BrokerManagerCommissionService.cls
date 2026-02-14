public class BrokerManagerCommissionService {
    public static void calculateBrokerManagerCommission(Map<Id, MonthlySalesTarget__c> managerBasedMonSalesTarget,
											List<MonthlySalesTarget__c> lstMonthlySalesTarget,
                                            String strMonth, String strYear){
                                                system.debug('strMonth::'+strMonth);
                                                 system.debug('strYear::'+strYear);
       	Map<Id,Map<Id,List<SalesOrder__c>>> salesOrderDetails = new Map<Id,Map<Id,List<SalesOrder__c>>>();
        integer numberOfDays = date.daysInMonth(integer.valueOf(strYear), integer.valueOf(strMonth));
        date soldStartDate = date.newInstance(integer.valueOf(strYear), integer.valueOf(strMonth), 1);
        date soldEndDate = date.newInstance(integer.valueOf(strYear), integer.valueOf(strMonth), numberOfDays);
		Map<Id,Decimal> mapCustomerCapNetAmount = new Map<Id,Decimal>();
		List<CommissionLineItem__c> lstCommissionLineItems = new List<CommissionLineItem__c>();
        for(SalesOrder__c objSalesOrder :[SELECT Opportunity__c,Opportunity__r.BrokerAgencyAccount__c, 
                                          	Status__c,EquityPercentage__c,AgentType__c,InventoryLaunch__c,
               								Opportunity__r.BrokerAgencyAccount__r.OwnerId,
               								SoldDate__c,NetAmount__c,Team__c,Account__c,Account__r.ResidentStatus__pc,
                                          	Account__r.BillingCity,
											(SELECT Commission30__c,Commission70__c,PayableCommission__c,
											CommissionAmount__c,SalesOrder__c,SalesManager__c FROM CommissionLineItems__r 
											Where CommissionType__c =: Constants.COMMISSION_LINE_EXTERNAL_COMMISSION )  FROM SalesOrder__c
                                          WHERE AgentType__c = : Constants.OPPORTUINTY_AGENT_TYPE_INDIRECT 
                                          AND SalesManager__r.isActive = true
                                          AND ((SoldDate__c >=: soldStartDate AND SoldDate__c <=: soldEndDate) 
                                               OR (SalesApprovedDate__c >=: soldStartDate AND SalesApprovedDate__c <=: soldEndDate))]){
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
		BrokerManagerCommissionService.brokerManagerCommission(salesOrderDetails, managerBasedMonSalesTarget, 
                                                               mapCustomerCapNetAmount,strMonth,strYear, 
                                                               mapCommissionPayoutLines, false);
    }
    
    public static Map<String, object> brokerManagerCommission(Map<Id,Map<Id,List<SalesOrder__c>>> salesOrderDetails, 
                                               Map<Id, MonthlySalesTarget__c> managerBasedMonSalesTarget,
                                               Map<Id,Decimal> mapCustomerCapNetAmount, String strMonth, String strYear, 
                                               Map<Id, CommissionPayoutLine__c> mapCommissionPayoutLines, boolean isCommissionCalculator){
                                                   system.debug('strMonth::'+strMonth);
                                                   system.debug('strYear::'+strYear); 
        Map<String, List<Broker_Manager_Commission__mdt>> lstTeamMetaData = new Map<String, List<Broker_Manager_Commission__mdt>>();
        Map<String, object> results = new Map<String, object>();
        List<CommissionLineItem__c> lstCommisionLineItems = new List<CommissionLineItem__c>();
		for(Broker_Manager_Commission__mdt objCustomMetaData : Broker_Manager_Commission__mdt.getAll().values()){
            List<Broker_Manager_Commission__mdt> lstBrokerManagerMetaData = new List<Broker_Manager_Commission__mdt>();
            if(lstTeamMetaData.containsKey(objCustomMetaData.Residence__c)){
                lstBrokerManagerMetaData = lstTeamMetaData.get(objCustomMetaData.Residence__c);
            }
            lstBrokerManagerMetaData.add(objCustomMetaData);
            lstTeamMetaData.put(objCustomMetaData.Residence__c, lstBrokerManagerMetaData);
		}
		system.debug('lstTeamMetaData>>>'+lstTeamMetaData);
		                                                  
        date startDate = Date.today();
		date endDate = Date.today(); 
                                                
		if(strMonth != '1'){
          	integer numberOfDays = date.daysInMonth(integer.valueOf(strYear), integer.valueOf(strMonth)-1);
         	startDate = Date.newInstance(Integer.valueOf(strYear), 1, 1);
            endDate =  Date.newInstance(Integer.valueOf(strYear), integer.valueOf(strMonth), numberOfDays);
        }  
		system.debug('startDate>>>>>>'+startDate);
		system.debug('endDate>>>>>>'+endDate);
		
		Map<String,Decimal> agencyPreviousMonthCap = new Map<String,Decimal>();
		if(strMonth != '1'){                                                   
			for(AggregateResult objAggregateResult : [SELECT SalesOrder__r.Opportunity__r.BrokerAgencyAccount__c brokerAgencyAccount, 
                                                        AVG(SalesOrder__r.NetAmount__c) netAmount FROM CommissionPayoutLine__c 
                                                     	Where  (SalesOrder__r.SoldDate__c >=: startDate AND SalesOrder__r.SoldDate__c <=: endDate)
														GROUP BY SalesOrder__r.Opportunity__r.BrokerAgencyAccount__c]){
           		system.debug('objAggregateResult>>>>>'+objAggregateResult);
				if(String.isNotBlank((String)objAggregateResult.get('brokerAgencyAccount'))){
             		agencyPreviousMonthCap.put((String)objAggregateResult.get('brokerAgencyAccount'), (Decimal)objAggregateResult.get('netAmount'));                                      	                             
				}
			}
        }
		system.debug('agencyPreviousMonthCap>>>>>>>'+agencyPreviousMonthCap);
		MonthlySalesTarget__c objMonthlySalesTargetParent = new MonthlySalesTarget__c();
        List<MonthlySalesTarget__c> lstMonthParents = [SELECT id FROM MonthlySalesTarget__c WHERE 
                                                           MonthlySalesTarget__c = NULL 
                                                           AND IsParent__c = TRUE AND TargetMonth__c =:strMonth 
                                                           AND TargetYear__c =:strYear LIMIT 1];
         if(lstMonthParents.isEmpty()){
			objMonthlySalesTargetParent.TargetMonth__c = strMonth;
			objMonthlySalesTargetParent.TargetYear__c = strYear;
            objMonthlySalesTargetParent.Team__c = Constants.USER_TEAM_AUH;
			objMonthlySalesTargetParent.TargetAmount__c = 00;
			objMonthlySalesTargetParent.InventoryTargetAmount__c = 00;
			objMonthlySalesTargetParent.LaunchTargetAmount__c = 00;
			objMonthlySalesTargetParent.IsParent__c = TRUE;
             if(!isCommissionCalculator){
                 insert objMonthlySalesTargetParent;
             }
             
		}else{
           objMonthlySalesTargetParent = lstMonthParents[0];
		}                                                   
		List<MonthlySalesTarget__c> lstMonthlySalesTarget = new List<MonthlySalesTarget__c>();
		List<CommissionPayoutLine__c> lstCommissionPayouts = new List<CommissionPayoutLine__c>();
            for(Id brokerManagerId : salesOrderDetails.keySet()){
                system.debug('brokerManagerId::'+brokerManagerId);
                Decimal totalBrokerCommission = 0;
                for(Id customerId : salesOrderDetails.get(brokerManagerId).keySet()){
                    system.debug('customerId::'+customerId);
                    boolean createCommission = true;
                    decimal capCalculation = 0;
                    if(mapCustomerCapNetAmount.containsKey(customerId)){
                       if(mapCustomerCapNetAmount.get(customerId) >= integer.valueOf(LABEL.NetAmountCapLimit)){
                          
                        system.debug('customerId>>>>'+customerId);
                        createCommission = false;
                       }else{
                           capCalculation = mapCustomerCapNetAmount.get(customerId);
                       }
                    }
                    if(createCommission){ 
                        for(SalesOrder__c objSalesOrder : salesOrderDetails.get(brokerManagerId).get(customerId)){
                            system.debug('objSalesOrder::'+objSalesOrder);
                            Decimal capLimit = capCalculation + objSalesOrder.NetAmount__c;
                            if(capLimit <= integer.valueOf(LABEL.NetAmountCapLimit)){
                                capCalculation = capCalculation + objSalesOrder.NetAmount__c;
                            	Decimal salesOrderCommission = 0;
                            
                            	Broker_Manager_Commission__mdt objBrokerManagerCommission;
                            	if(String.isNotBlank(objSalesOrder.Account__r.ResidentStatus__pc)){
                                
                                	List<Broker_Manager_Commission__mdt> citydetails = lstTeamMetaData.get(objSalesOrder.Account__r.ResidentStatus__pc);
                                	if(objSalesOrder.Account__r.ResidentStatus__pc == Constants.RESIDENTTYPE_NON_RESIDENT){
                                    	objBrokerManagerCommission = citydetails[0];
                                	}else{
                                    	for(Broker_Manager_Commission__mdt objBrokerMeta : citydetails){
                                        	if(String.isNotBlank(objSalesOrder.Account__r.BillingCity)){
                                            	system.debug('objBrokerMeta.CityNames__c>>>>>>'+objBrokerMeta.CityNames__c);
                                            	if(objBrokerMeta.CityNames__c.containsIgnoreCase(objSalesOrder.Account__r.BillingCity)){
                                                	objBrokerManagerCommission = objBrokerMeta;
                                                	break;
	                                            }
                                        	}
                                        
                                    	}
                                	}
                                    if(objBrokerManagerCommission != NULL){
                                        system.debug('objBrokerManagerCommission>>>>>'+objBrokerManagerCommission);
                                        if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                                            salesOrderCommission =  ((objSalesOrder.NetAmount__c == NULL ? 0 : objSalesOrder.NetAmount__c) *(objBrokerManagerCommission.InventoryPercentage__c/100));
                                        }else if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
                                            salesOrderCommission =  ((objSalesOrder.NetAmount__c == NULL ? 0 : objSalesOrder.NetAmount__c) *(objBrokerManagerCommission.LaunchPercentage__c/100));
                                        }
                                       
                                        CommissionPayoutLine__c objCommisionPayoutLine = new CommissionPayoutLine__c();
                                        
                                        for(CommissionLineItem__c objCommissionLine : objSalesOrder.CommissionLineItems__r){
                                            lstCommisionLineItems.add(objCommissionLine);
                                            if(mapCommissionPayoutLines.containsKey(objCommissionLine.Id)){
                                                objCommisionPayoutLine = mapCommissionPayoutLines.get(objCommissionLine.Id);
                                                break;
                                            }
                                        }
                                        if(objCommisionPayoutLine.PayoutStatus__c != Constants.COMMISSION_LINE_STATUS_PAID && objSalesOrder.CommissionLineItems__r.size()>0){
                                            totalBrokerCommission = totalBrokerCommission + salesOrderCommission;
                                            objCommisionPayoutLine.PayoutAmount__c = salesOrderCommission;
                                            objCommisionPayoutLine.SalesOrder__c = objSalesOrder.Id;
                                            objCommisionPayoutLine.PayoutDate__c = (Date.newInstance(Integer.valueOf(strYear), Integer.valueOf(strMonth), 01)).addMonths(1);
                                            objCommisionPayoutLine.RecalculatedDate__c = system.today();
                                            system.debug('objSalesOrder::'+objSalesOrder.id);
                                            system.debug('objSalesOrder commission::'+objSalesOrder.CommissionLineItems__r[0].Id);
                                            if(!mapCommissionPayoutLines.containskey(objCommisionPayoutLine.CommissionLineItem__c)){
                                                objCommisionPayoutLine.CommissionLineItem__c = objSalesOrder.CommissionLineItems__r[0].Id;
                                                objCommisionPayoutLine.BrokerManager__c = brokerManagerId;
                                            }
                                            
                                            if(managerBasedMonSalesTarget.containskey(brokerManagerId)){
                                                objCommisionPayoutLine.MonthlySalesTarget__c = managerBasedMonSalesTarget.get(brokerManagerId).Id;
                                            }
                                            objCommisionPayoutLine.AccumulatedAmount__c = capLimit;
                                            lstCommissionPayouts.add(objCommisionPayoutLine); 
                                        }
                                    }
                            	}
                            
                        	}
                        }
                	}
                }  
                
                if(managerBasedMonSalesTarget.containsKey(brokerManagerId)){
                   	MonthlySalesTarget__c objMonthlySalesTarget =  managerBasedMonSalesTarget.get(brokerManagerId);
                    objMonthlySalesTarget.TotalPayableCommission__c = totalBrokerCommission;
                    objMonthlySalesTarget.MonthlySalesTarget__c = objMonthlySalesTargetParent.Id;
                    lstMonthlySalesTarget.add(objMonthlySalesTarget);
	            }
        }
                                                   system.debug('lstCommissionPayouts:::'+lstCommissionPayouts);   
                                                   system.debug('lstCommissionPayouts:::'+lstCommissionPayouts.size());                                        
		if(!lstCommissionPayouts.isEmpty() && !isCommissionCalculator){
            upsert lstCommissionPayouts;                                           
		}
                                                   system.debug('lstMonthlySalesTarget:::'+lstMonthlySalesTarget.size());
                                                   system.debug('lstMonthlySalesTarget:::'+lstMonthlySalesTarget);
		if(!lstMonthlySalesTarget.isEmpty() && !isCommissionCalculator){
          update lstMonthlySalesTarget;                                             
		}
        results.put('payoutLines', lstCommissionPayouts);
		results.put('lstCommisionLineItems', lstCommisionLineItems);    
        return results;
    }
}