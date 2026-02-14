public class CommissionPayoutService {
	public static void getCommissionLines(List<MonthlySalesTarget__c> monthlySalesTarget,
                                          Date soldStartDate,
                                          Date soldEndDate,
                                          List<CommissionLineItem__c> lstCommisionLineItems, 
                                          Map<Id,SalesOrder__c> mapSalesOrders,
                                          Set<Id> salesOrderIds){
        set<Id> salesManagersId = new set<Id>();
        map<Id,MonthlySalesTarget__c> mapMonthlySalesTarget = new map<Id,MonthlySalesTarget__c>();
        for(MonthlySalesTarget__c objMonthlySalesTarget: monthlySalesTarget){
            salesManagersId.add(objMonthlySalesTarget.ResourceName__c);
            mapMonthlySalesTarget.put(objMonthlySalesTarget.ResourceName__c,objMonthlySalesTarget);
        }
        Map<Id,List<SalesOrder__c>> salesordersMap = new Map<Id,List<SalesOrder__c>>();
        Map<Id,List<CommissionLineItem__c>> mapCommissionLineItemsRelManagers = new Map<Id,List<CommissionLineItem__c>>();
        for(SalesOrder__c salesOrder : [SELECT SalesManager__c, SalesManager__r.Name, SalesManager__r.UserRole.Name,Status__c,EquityPercentage__c,AgentType__c,
                                        InventoryLaunch__c,Account__r.CustomerSubType__c,Unit__c,Unit__r.Name,SoldDate__c,
                                        NetAmount__c,Team__c,
                                        (SELECT 
                                         Commission70__c,Commission30__c,
                                         PayableCommission__c,
                                         CommissionAmount__c,SalesOrder__c,SalesManager__c FROM CommissionLineItems__r 
                                         Where CommissionType__c =: Constants.COMMISSION_LINE_INTERNAL_COMMISSION ) 
                                        FROM SalesOrder__c WHERE Status__c=: Constants.UNIT_STATUS_SOLD 
                                        AND SalesManager__c IN : salesManagersId 
                                        AND(
                                            (SoldDate__c >=: soldStartDate AND SoldDate__c <=: soldEndDate)
                                            OR (SalesApprovedDate__c >=: soldStartDate AND SalesApprovedDate__c <=: soldEndDate)
                                        )]){
                                            
                                            salesOrderIds.add(salesOrder.Id);
                                            mapSalesOrders.put(salesOrder.Id, salesOrder);
                                            List<SalesOrder__c> lstSalesOrders = new List<SalesOrder__c>();
                                            if(salesordersMap.containsKey(salesOrder.SalesManager__c)){
                                                lstSalesOrders = salesordersMap.get(salesOrder.SalesManager__c);
                                            }
                                            lstSalesOrders.add(salesOrder);
                                            salesordersMap.put(salesOrder.SalesManager__c, lstSalesOrders);
                                            
                                            List<CommissionLineItem__c> lstInLCommissionLineItems = new List<CommissionLineItem__c>();
                                            if(mapCommissionLineItemsRelManagers.containsKey(salesOrder.SalesManager__c)){
                                                lstInLCommissionLineItems = mapCommissionLineItemsRelManagers.get(salesOrder.SalesManager__c);
                                            }
                                            lstInLCommissionLineItems.addAll(salesOrder.CommissionLineItems__r);
                                            mapCommissionLineItemsRelManagers.put(salesOrder.SalesManager__c, lstInLCommissionLineItems);
                                        }
                                              
          System.debug('salesordersMap::'+salesordersMap);  
          System.debug('mapSalesOrders::'+mapSalesOrders);
          System.debug('salesOrderIds::'+salesOrderIds);
          System.debug('mapCommissionLineItemsRelManagers::'+mapCommissionLineItemsRelManagers);
                                              
        for(Id salesManagerId : salesordersMap.keySet()){
            if(mapMonthlySalesTarget.containsKey(salesManagerId)){
                MonthlySalesTarget__c objMonthlySalesTarget = mapMonthlySalesTarget.get(salesManagerId);
                if(mapCommissionLineItemsRelManagers.containsKey(salesManagerId) && salesordersMap.containsKey(salesManagerId)){
                    List<SalesOrder__c> lstSalesOrders = salesordersMap.get(salesManagerId);
                    for(CommissionLineItem__c objCommissionLineItem : mapCommissionLineItemsRelManagers.get(salesManagerId)){
                        objCommissionLineItem.AcceleratorAmount__c = objMonthlySalesTarget.AcceleratorCommissionAmount__c/lstSalesOrders.size();
                        if(objMonthlySalesTarget.KPIPayoutPercentage__c == Constants.KPI100PERCENTAGE){
                            objCommissionLineItem.PayableCommission__c = (objCommissionLineItem.Commission70__c + objCommissionLineItem.Commission30__c);
                        }else{
                            objCommissionLineItem.PayableCommission__c = (objCommissionLineItem.Commission70__c + (objCommissionLineItem.Commission30__c * Constants.PERCENTAGE30CALCULATION));
                        }
                        objCommissionLineItem.TotalPayableCommission__c = objCommissionLineItem.AcceleratorAmount__c + objCommissionLineItem.PayableCommission__c;
                    	lstCommisionLineItems.add(objCommissionLineItem);
                    }
                }
            }
        }
       System.debug('lstCommisionLineItems::'+lstCommisionLineItems);
     }
        
    public static void calculateRoleBaseCommission(CommissionPayoutLine__c objCommisionPayoutLine, 
									  SalesOrder__c objInSalesOrder, 
									  Map<String,CommissionPayout__mdt> commissionPayoutMetaData, 
									  CommissionLineItem__c objCommissionLineItem){
		Decimal landHeadCommission = 0;
		Map<String, CommissionPayout__mdt> lstTeamMetaData = new Map<String, CommissionPayout__mdt>();
		for(CommissionPayout__mdt objCustomMetaData : commissionPayoutMetaData.values()){
			if(String.isNotBlank(objCustomMetaData.Team__c)){
				lstTeamMetaData.put(objCustomMetaData.Team__c, objCustomMetaData);
			}                             
		}
		
		if(lstTeamMetaData.containsKey(objInSalesOrder.Team__c)){
            CommissionPayout__mdt salesHeadCustomMetaData = lstTeamMetaData.get(objInSalesOrder.Team__c);
            Decimal payOutAmount = objCommisionPayoutLine.PayoutAmount__c;
            Decimal finalCommission = 0;
            if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                finalCommission = (objCommisionPayoutLine.PayoutAmount__c * (salesHeadCustomMetaData.InventoryPercentage__c/100)).setScale(2);
            }else if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
				finalCommission = (objCommisionPayoutLine.PayoutAmount__c * (salesHeadCustomMetaData.LaunchPercentage__c/100)).setScale(2);
			}
			objCommisionPayoutLine.put(salesHeadCustomMetaData.CommissionPayoutAmountFieldAPI__c,finalCommission); 
            if(objInSalesOrder.Team__c == Constants.TEAM_LAND){
                landHeadCommission = finalCommission;
            }
		}
                                          
           
                                          
		if(objInSalesOrder.Account__r.CustomerSubType__c == Constants.WEALTH 
           || objInSalesOrder.Account__r.CustomerSubType__c == Constants.CORPORATE){
			CommissionPayout__mdt commMetaData = commissionPayoutMetaData.get(objInSalesOrder.Account__r.CustomerSubType__c);
			Decimal finalCommission = 0;
			if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
				finalCommission = (objInSalesOrder.NetAmount__c * (commMetaData.InventoryPercentage__c/100)).setScale(2);
			}else if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
				finalCommission = (objInSalesOrder.NetAmount__c * (commMetaData.LaunchPercentage__c/100)).setScale(2);
			}
			objCommisionPayoutLine.put(commMetaData.CommissionPayoutAmountFieldAPI__c,finalCommission);
            
            if(lstTeamMetaData.containsKey(Constants.TEAM_LAND)){
              	CommissionPayout__mdt commLandMetaData = lstTeamMetaData.get(Constants.TEAM_LAND);
                Decimal finalLandCommission = 0;
			if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
				finalLandCommission = ((finalCommission + landHeadCommission) * (commLandMetaData.InventoryPercentage__c/100)).setScale(2);
			}else if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
				finalLandCommission = ((finalCommission + landHeadCommission) * (commLandMetaData.LaunchPercentage__c/100)).setScale(2);
			}
                landHeadCommission = finalLandCommission;
			objCommisionPayoutLine.put(commLandMetaData.CommissionPayoutAmountFieldAPI__c,finalLandCommission);
			}
		}
		
		CommissionPayout__mdt commBrokerMetaData = commissionPayoutMetaData.get(Constants.HEAD_OF_BROKER);
		Decimal finalBrokerCommission = 0;
		if(objInSalesOrder.AgentType__c == Constants.OPPORTUINTY_AGENT_TYPE_INDIRECT){
			
			Decimal payOutAmount = (objCommissionLineItem.TotalPayableCommission__c - objCommissionLineItem.AcceleratorAmount__c);
			
			if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
				finalBrokerCommission = (payOutAmount * (commBrokerMetaData.InventoryPercentage__c/100)).setScale(2);
			}else if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
				finalBrokerCommission = (payOutAmount * (commBrokerMetaData.LaunchPercentage__c/100)).setScale(2);
			}
			 
		}
		if(objInSalesOrder.Team__c == Constants.USER_TEAM_AUH	 || objInSalesOrder.Team__c == Constants.USER_TEAM_VIP){
            if(commissionPayoutMetaData.containsKey(Constants.ASSOCIATE_DIRECTOR_OF_SALE)){
                CommissionPayout__mdt commMetaData = commissionPayoutMetaData.get(Constants.ASSOCIATE_DIRECTOR_OF_SALE);
                Decimal finalCommission = 0;
                if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                    finalCommission = (((objCommisionPayoutLine.SalesHeadPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.SalesHeadPayoutAmount__c) + landHeadCommission) * (commMetaData.InventoryPercentage__c/100)).setScale(2);
                }else if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
                    finalCommission = (((objCommisionPayoutLine.SalesHeadPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.SalesHeadPayoutAmount__c) + landHeadCommission) * (commMetaData.LaunchPercentage__c/100)).setScale(2);
                }
                objCommisionPayoutLine.put(commMetaData.CommissionPayoutAmountFieldAPI__c,finalCommission); 
            }                               
		}
		
		objCommisionPayoutLine.put(commBrokerMetaData.CommissionPayoutAmountFieldAPI__c,finalBrokerCommission);
		if(commissionPayoutMetaData.containsKey(Constants.EXECUTIVE_DIRECTOR_OF_SALES)){
		  CommissionPayout__mdt commMetaData = commissionPayoutMetaData.get(Constants.EXECUTIVE_DIRECTOR_OF_SALES);
		  Decimal finalCommission = 0;
		  if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
              if(objInSalesOrder.Team__c == Constants.USER_TEAM_LAND	 || objInSalesOrder.Team__c == Constants.USER_TEAM_DXB || objInSalesOrder.Team__c == Constants.USER_TEAM_CASA){
                 finalCommission = ((objCommisionPayoutLine.SalesHeadPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.SalesHeadPayoutAmount__c) * (commMetaData.InventoryPercentage__c/100)).setScale(2); 
              }else{
                 finalCommission = ((objCommisionPayoutLine.DirectorPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.DirectorPayoutAmount__c) * (commMetaData.InventoryPercentage__c/100)).setScale(2); 
              }
			  
		  }else if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
			  if(objInSalesOrder.Team__c == Constants.USER_TEAM_LAND	 || objInSalesOrder.Team__c == Constants.USER_TEAM_DXB || objInSalesOrder.Team__c == Constants.USER_TEAM_CASA){
                  finalCommission = ((objCommisionPayoutLine.SalesHeadPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.SalesHeadPayoutAmount__c) * (commMetaData.LaunchPercentage__c/100)).setScale(2); 
              }else{
                  finalCommission = ((objCommisionPayoutLine.SalesHeadPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.DirectorPayoutAmount__c) * (commMetaData.LaunchPercentage__c/100)).setScale(2);
              }
              
		  }
		  objCommisionPayoutLine.put(commMetaData.CommissionPayoutAmountFieldAPI__c,finalCommission); 
		}
		
		
                                          
		if(commissionPayoutMetaData.containsKey(Constants.CCO)){
		  CommissionPayout__mdt commMetaData = commissionPayoutMetaData.get(Constants.CCO);
		  Decimal finalCommission = 0;
		  if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
			  finalCommission = ((objCommisionPayoutLine.ExecDirectorPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.ExecDirectorPayoutAmount__c) * (commMetaData.InventoryPercentage__c/100)).setScale(2);
		  }else if(objInSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
			  finalCommission = ((objCommisionPayoutLine.ExecDirectorPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.ExecDirectorPayoutAmount__c) * (commMetaData.LaunchPercentage__c/100)).setScale(2);
		  }
		  objCommisionPayoutLine.put(commMetaData.CommissionPayoutAmountFieldAPI__c,finalCommission); 
		}
	}
    
    public static void getExistingCommissionPayoutLines(Map<String,list<CommissionPayoutLine__c>> mapExistingCommissionPayOuts, 
                                                        Set<Id> salesOrderIds, Date soldStartDate){
        for(CommissionPayoutLine__c objPayoutLine : [SELECT BrokerHeadPayoutAmount__c, CCOPayoutAmount__c, CommissionLineItem__c,
                                                     CommissionLineItem__r.SalesOrder__c, DirectorPayoutAmount__c,
                                                     SalesOrder__r.InventoryLaunch__c,SalesOrder__r.EquityPercentage__c,
                                                     ExecDirectorPayoutAmount__c,CorporateWealthPayoutAmount__c, FutureCommission__c,
                                                     LandHead__c,MonthlySalesTarget__c, PayoutAmount__c,
                                                     SalesHeadPayoutAmount__c,SalesManager__c 
                                                     FROM CommissionPayoutLine__c 
                                                     Where FutureCommission__c =: Constants.COMMISSIONFUTURE 
                                                     AND PayoutStatus__c != :Constants.COMMISSION_LINE_STATUS_PAID
                                                     AND SalesOrder__r.EquityPercentage__c >=: Constants.EQUITY_PERCENTAGE
                                                     AND (SalesOrder__r.SoldDate__c < :soldStartDate OR SalesOrder__r.SalesApprovedDate__c < :soldStartDate)
                                                    ]){
			List<CommissionPayoutLine__c> lstCommissionPays = new List<CommissionPayoutLine__c>();
			if(mapExistingCommissionPayOuts.containsKey(objPayoutLine.SalesManager__c)){
				lstCommissionPays = mapExistingCommissionPayOuts.get(objPayoutLine.SalesManager__c);                                           
			}
			system.debug('SalesOrder__r.EquityPercentage__c>>>>>'+objPayoutLine.SalesOrder__r.EquityPercentage__c);
			objPayoutLine.PayoutStatus__c = Constants.COMMISSION_LINE_STATUS_PAID;
            objPayoutLine.Equity__c = objPayoutLine.SalesOrder__r.EquityPercentage__c;
			lstCommissionPays.add(objPayoutLine);
			mapExistingCommissionPayOuts.put(objPayoutLine.SalesManager__c, lstCommissionPays);
        }
		system.debug('mapExistingCommissionPayOuts>>>>>'+mapExistingCommissionPayOuts);
    }
    
    /*
    public static void addExisitngCommmissionPayoutLines(Map<String,list<CommissionPayoutLine__c>> mapExistingCommissionPayOuts,
                                                        	CommissionPayoutLine__c objCommisionPayoutLine, 
									  						SalesOrder__c objInSalesOrder,
                                                        	List<CommissionPayoutLine__c> lstExistingCommisionPayouts){
		if(mapExistingCommissionPayOuts.containsKey(objInSalesOrder.SalesManager__c)){
            for(CommissionPayoutLine__c objPayoutlines : mapExistingCommissionPayOuts.get(objInSalesOrder.SalesManager__c)){
                objCommisionPayoutLine.BrokerHeadPayoutAmount__c = ((objCommisionPayoutLine.BrokerHeadPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.BrokerHeadPayoutAmount__c) + (objPayoutlines.BrokerHeadPayoutAmount__c == NULL ? 0 : objPayoutlines.BrokerHeadPayoutAmount__c));
                objCommisionPayoutLine.SalesHeadPayoutAmount__c = ((objCommisionPayoutLine.SalesHeadPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.SalesHeadPayoutAmount__c) + (objPayoutlines.SalesHeadPayoutAmount__c == NULL ? 0 : objPayoutlines.SalesHeadPayoutAmount__c));
                objCommisionPayoutLine.PayoutAmount__c = ((objCommisionPayoutLine.PayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.PayoutAmount__c) + (objPayoutlines.PayoutAmount__c == NULL ? 0 : objPayoutlines.PayoutAmount__c));
                objCommisionPayoutLine.LandHead__c = ((objCommisionPayoutLine.LandHead__c == NULL ? 0 : objCommisionPayoutLine.LandHead__c) + (objPayoutlines.LandHead__c == NULL ? 0 : objPayoutlines.LandHead__c));
                objCommisionPayoutLine.ExecDirectorPayoutAmount__c = ((objCommisionPayoutLine.ExecDirectorPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.ExecDirectorPayoutAmount__c) + (objPayoutlines.ExecDirectorPayoutAmount__c == NULL ? 0 : objPayoutlines.ExecDirectorPayoutAmount__c));
                objCommisionPayoutLine.DirectorPayoutAmount__c = ((objCommisionPayoutLine.DirectorPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.DirectorPayoutAmount__c) + (objPayoutlines.DirectorPayoutAmount__c == NULL ? 0 : objPayoutlines.DirectorPayoutAmount__c));
                objCommisionPayoutLine.CorporateWealthPayoutAmount__c = ((objCommisionPayoutLine.CorporateWealthPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.CorporateWealthPayoutAmount__c) + (objPayoutlines.CorporateWealthPayoutAmount__c == NULL ? 0 : objPayoutlines.CorporateWealthPayoutAmount__c));
                objCommisionPayoutLine.CCOPayoutAmount__c = ((objCommisionPayoutLine.CCOPayoutAmount__c == NULL ? 0 : objCommisionPayoutLine.CCOPayoutAmount__c) + (objPayoutlines.CCOPayoutAmount__c == NULL ? 0 : objPayoutlines.CCOPayoutAmount__c));
                objPayoutlines.PayoutStatus__c = Constants.COMMISSION_LINE_STATUS_PAID;
                lstExistingCommisionPayouts.add(objPayoutlines);
            }                                                   
		}
    }
    */
    public static void getCommissionPayoutMetaData(Map<String, CommissionPayout__mdt> commissionPayoutMetaData){
        for(CommissionPayout__mdt objCommissionPayOutMD : CommissionPayout__mdt.getAll().values()){
            commissionPayoutMetaData.put(objCommissionPayOutMD.Role__c, objCommissionPayOutMD);
        }
    }
    
    public static void getCurrentMonthCommissionPayoutLines(Map<Id, List<CommissionPayoutLine__c>> mapPayoutLines, 
                                                            List<CommissionLineItem__c> lstCommisionLineItems){
        for(CommissionPayoutLine__c objPayOutline : [SELECT PayoutStatus__c, 
                                                     CommissionLineItem__c, FutureCommission__c,
                                                     BrokerHeadPayoutAmount__c,CCOPayoutAmount__c,
                                                     CorporateWealthPayoutAmount__c,DirectorPayoutAmount__c,ExecDirectorPayoutAmount__c,
                                                     LandHead__c,PayoutAmount__c,SalesHeadPayoutAmount__c FROM CommissionPayoutLine__c 
                                                     WHERE CommissionLineItem__c IN :lstCommisionLineItems]){
			List<CommissionPayoutLine__c>  lstPayoutLines = new  List<CommissionPayoutLine__c>();
			if(mapPayoutLines.containsKey(objPayOutline.CommissionLineItem__c)){
				lstPayoutLines = mapPayoutLines.get(objPayOutline.CommissionLineItem__c);
			}
			lstPayoutLines.add(objPayOutline);
			mapPayoutLines.put(objPayOutline.CommissionLineItem__c, lstPayoutLines);                                      
		}
    }
    
    public static void getCalculatedCommissionPayouts(List<CommissionLineItem__c> lstCommisionLineItems, Map<Id, SalesOrder__c> mapSalesOrders,
														Map<Id, MonthlySalesTarget__c> managerBasedMonSalesTarget, 
														Map<String, CommissionPayout__mdt> commissionPayoutMetaData, 
														List<Object> lstCommissionPayoutLines, List<CommissionPayoutLine__c> lstCommissionPayoutLiness, 
														Map<String, object> results, 
                                                      	Map<String,list<CommissionPayoutLine__c>> mapExistingCommissionPayOuts,
                                                      	List<CommissionPayoutLine__c> lstExistingCommisionPayouts,
                                                      	boolean isBatch, String targetMonth, String targetYear
                                                     	){
		Map<Id, List<CommissionPayoutLine__c>> mapPayoutLines = New Map<Id, List<CommissionPayoutLine__c>>();
		CommissionPayoutService.getCurrentMonthCommissionPayoutLines(mapPayoutLines, lstCommisionLineItems);
		List<CommissionPayoutLine__c> delCommissionPayout = new List<CommissionPayoutLine__c>();
        for(CommissionLineItem__c objCommissionLineItem : lstCommisionLineItems){
            if(mapSalesOrders.containsKey(objCommissionLineItem.SalesOrder__c)){
				SalesOrder__c objInSalesOrder = mapSalesOrders.get(objCommissionLineItem.SalesOrder__c);
				MonthlySalesTarget__c objMontlySalesTareget = managerBasedMonSalesTarget.get(objInSalesOrder.SalesManager__c);
				if(objInSalesOrder.EquityPercentage__c >= Constants.EQUITY_PERCENTAGE){
                    CommissionPayoutLine__c objCommisionPayoutLine = new CommissionPayoutLine__c();
                    if(mapPayoutLines.containsKey(objCommissionLineItem.Id)){
                        for(CommissionPayoutLine__c objPayout : mapPayoutLines.get(objCommissionLineItem.Id)){
                           
                            if(objPayout.FutureCommission__c == Constants.COMMISSIONCURRENT){
                                objCommisionPayoutLine = objPayout;
                            }else{
                                delCommissionPayout.add(objCommisionPayoutLine);
                            }
							
                        }
                    }
                    if(String.isBlank(objCommisionPayoutLine.Id)){
                        objCommisionPayoutLine.Equity__c = objInSalesOrder.EquityPercentage__c;
                        objCommisionPayoutLine.CommissionLineItem__c = objCommissionLineItem.Id;
                    }
					
					
					objCommisionPayoutLine.SalesManager__c = objInSalesOrder.SalesManager__c;
                    objCommisionPayoutLine.SalesOrder__c = objInSalesOrder.Id;
					objCommisionPayoutLine.PayoutAmount__c = objCommissionLineItem.TotalPayableCommission__c;
					objCommisionPayoutLine.PayoutDate__c = (Date.newInstance(Integer.valueOf(targetYear), Integer.valueOf(targetMonth), 01)).addMonths(1);
					objCommisionPayoutLine.FutureCommission__c = Constants.COMMISSIONCURRENT;
					objCommisionPayoutLine.RecalculatedDate__c = system.today();	
					if(managerBasedMonSalesTarget.containsKey(objInSalesOrder.SalesManager__c)){
						objCommisionPayoutLine.MonthlySalesTarget__c = managerBasedMonSalesTarget.get(objInSalesOrder.SalesManager__c).Id;
					}
					
					CommissionPayoutService.calculateRoleBaseCommission(objCommisionPayoutLine, 
																		objInSalesOrder, 
																		commissionPayoutMetaData, 
																		objCommissionLineItem);
                    /*
					CommissionPayoutService.addExisitngCommmissionPayoutLines(mapExistingCommissionPayOuts,
																			objCommisionPayoutLine,
																			objInSalesOrder,
																			lstExistingCommisionPayouts); 
					*/
					lstCommissionPayoutLiness.add(objCommisionPayoutLine);
                    if(isBatch == false){
                    	lstCommissionPayoutLines.add(new Map<String,Object>{
                            'SalesManagerId'=>objInSalesOrder.SalesManager__c,
                            'SalesManagerName'=>objInSalesOrder.SalesManager__r.Name,
                            'UnitId'=>objInSalesOrder.Unit__c,
                            'UnitName'=>objInSalesOrder.Unit__r.Name,
                            'SoldDate'=>objInSalesOrder.SoldDate__c,
                            'NetAmount'=>objInSalesOrder.NetAmount__c,
                            'EquityPercentage'=>objInSalesOrder.EquityPercentage__c/100,
                            'Accelerator' =>objCommissionLineItem.AcceleratorAmount__c,
                            'X30Commission' =>objCommissionLineItem.Commission30__c,
                            'X70Commission' =>objCommissionLineItem.Commission70__c,
                            'Accelerator' =>(objCommissionLineItem.AcceleratorAmount__c).setScale(2),
                            'KPIPercentage' =>objMontlySalesTareget.KPIPayoutPercentage__c/100,
                            'TotalPaableCommi' =>(objCommissionLineItem.TotalPayableCommission__c).setScale(2),
                            'PayoutAmount' =>(objCommisionPayoutLine.PayoutAmount__c).setScale(2),
                            'PayoutType' =>'Current',
                            'dir'=>objCommisionPayoutLine.DirectorPayoutAmount__c,
                            'Broker_Head'=>objCommisionPayoutLine.BrokerHeadPayoutAmount__c,
                            'Sales_Head'=>objCommisionPayoutLine.SalesHeadPayoutAmount__c,
                            'Wealth_Head'=>objCommisionPayoutLine.CorporateWealthPayoutAmount__c,
                            'Land_Head'=>objCommisionPayoutLine.LandHead__c,
                            'Ex_Dir'=>objCommisionPayoutLine.ExecDirectorPayoutAmount__c,
                            'CCO'=>objCommisionPayoutLine.CCOPayoutAmount__c,
                            'agentType'=>objInSalesOrder.AgentType__c
                        });
                    }
				}
                else{
                    CommissionPayoutLine__c objCommisionPayoutLine = new CommissionPayoutLine__c();
                    if(mapPayoutLines.containsKey(objCommissionLineItem.Id)){
                        for(CommissionPayoutLine__c objPayout : mapPayoutLines.get(objCommissionLineItem.Id)){
                            if(objPayout.FutureCommission__c == Constants.COMMISSIONCURRENT){
                                objCommisionPayoutLine = objPayout;
                            }
						}
                    }
					if(String.isBlank(objCommisionPayoutLine.Id)){
                        objCommisionPayoutLine.Equity__c = objInSalesOrder.EquityPercentage__c;
                        objCommisionPayoutLine.CommissionLineItem__c = objCommissionLineItem.Id;
                    }
					
					objCommisionPayoutLine.SalesManager__c = objInSalesOrder.SalesManager__c;
                    objCommisionPayoutLine.SalesOrder__c = objInSalesOrder.Id;
					objCommisionPayoutLine.PayoutDate__c = (Date.newInstance(Integer.valueOf(targetYear), Integer.valueOf(targetMonth), 01)).addMonths(1);
					objCommisionPayoutLine.RecalculatedDate__c = system.today();
                    objCommisionPayoutLine.FutureCommission__c = Constants.COMMISSIONCURRENT;
					objCommisionPayoutLine.PayoutAmount__c = (objCommissionLineItem.TotalPayableCommission__c * Constants.PERCENTAGE75CALCULATION);
					if(managerBasedMonSalesTarget.containsKey(objInSalesOrder.SalesManager__c)){
						objCommisionPayoutLine.MonthlySalesTarget__c = managerBasedMonSalesTarget.get(objInSalesOrder.SalesManager__c).Id;
					}
					CommissionPayoutService.calculateRoleBaseCommission(objCommisionPayoutLine, 
																		objInSalesOrder, 
																		commissionPayoutMetaData, 
																		objCommissionLineItem);
					lstCommissionPayoutLiness.add(objCommisionPayoutLine);
                    if(isBatch == false){
                        lstCommissionPayoutLines.add(new Map<String,Object>{
                            'SalesManagerId'=>objInSalesOrder.SalesManager__c,
                            'SalesManagerName'=>objInSalesOrder.SalesManager__r.Name,
                            'UnitId'=>objInSalesOrder.Unit__c,
                            'UnitName'=>objInSalesOrder.Unit__r.Name,
                            'SoldDate'=>objInSalesOrder.SoldDate__c,
                            'NetAmount'=>objInSalesOrder.NetAmount__c,
                            'EquityPercentage'=>objInSalesOrder.EquityPercentage__c/100,
                            'Accelerator' =>objCommissionLineItem.AcceleratorAmount__c,
                            'X30Commission' =>objCommissionLineItem.Commission30__c,
                            'X70Commission' =>objCommissionLineItem.Commission70__c,
                            'Accelerator' =>(objCommissionLineItem.AcceleratorAmount__c).setScale(2),
                            'KPIPercentage' =>objMontlySalesTareget.KPIPayoutPercentage__c/100,
                            'TotalPaableCommi' =>(objCommissionLineItem.TotalPayableCommission__c).setScale(2),
                            'PayoutAmount' =>(objCommisionPayoutLine.PayoutAmount__c).setScale(2),
                            'PayoutType' =>'Current',
                            'dir'=>objCommisionPayoutLine.DirectorPayoutAmount__c,
                            'Broker_Head'=>objCommisionPayoutLine.BrokerHeadPayoutAmount__c,
                            'Sales_Head'=>objCommisionPayoutLine.SalesHeadPayoutAmount__c,
                            'Wealth_Head'=>objCommisionPayoutLine.CorporateWealthPayoutAmount__c,
                            'Land_Head'=>objCommisionPayoutLine.LandHead__c,
                            'Ex_Dir'=>objCommisionPayoutLine.ExecDirectorPayoutAmount__c,
                            'CCO'=>objCommisionPayoutLine.CCOPayoutAmount__c,
                            'agentType'=>objInSalesOrder.AgentType__c
                        });

                    }
					CommissionPayoutLine__c objFutureCommisionPayoutLine = new CommissionPayoutLine__c();
                    if(mapPayoutLines.containsKey(objCommissionLineItem.Id)){
                        for(CommissionPayoutLine__c objPayout : mapPayoutLines.get(objCommissionLineItem.Id)){
                            if(objPayout.FutureCommission__c == Constants.COMMISSIONFUTURE){
                                objFutureCommisionPayoutLine = objPayout;
                            }
						}
                    }
                    if(String.isBlank(objFutureCommisionPayoutLine.Id)){
                        objFutureCommisionPayoutLine.Equity__c = objInSalesOrder.EquityPercentage__c;
                        objFutureCommisionPayoutLine.CommissionLineItem__c = objCommissionLineItem.Id;
                    }
					
					objFutureCommisionPayoutLine.SalesManager__c = objInSalesOrder.SalesManager__c;
                    objFutureCommisionPayoutLine.SalesOrder__c = objInSalesOrder.Id;
					objFutureCommisionPayoutLine.PayoutDate__c = (Date.newInstance(Integer.valueOf(targetYear), Integer.valueOf(targetMonth), 01)).addMonths(1);
					objFutureCommisionPayoutLine.RecalculatedDate__c = system.today();
                    objFutureCommisionPayoutLine.FutureCommission__c = Constants.COMMISSIONFUTURE;
					objFutureCommisionPayoutLine.PayoutAmount__c = (objCommissionLineItem.TotalPayableCommission__c * Constants.PERCENTAGE25CALCULATION);
					if(managerBasedMonSalesTarget.containsKey(objInSalesOrder.SalesManager__c)){
						objFutureCommisionPayoutLine.MonthlySalesTarget__c = managerBasedMonSalesTarget.get(objInSalesOrder.SalesManager__c).Id;
					}
					CommissionPayoutService.calculateRoleBaseCommission(objFutureCommisionPayoutLine, 
																		objInSalesOrder, 
																		commissionPayoutMetaData, 
																		objCommissionLineItem);
					lstCommissionPayoutLiness.add(objFutureCommisionPayoutLine);
					if(isBatch == false){
                        lstCommissionPayoutLines.add(new Map<String,Object>{
                            'SalesManagerId'=>objInSalesOrder.SalesManager__c,
                            'SalesManagerName'=>objInSalesOrder.SalesManager__r.Name,
                            'UnitId'=>objInSalesOrder.Unit__c,
                            'UnitName'=>objInSalesOrder.Unit__r.Name,
                            'SoldDate'=>objInSalesOrder.SoldDate__c,
                            'NetAmount'=>objInSalesOrder.NetAmount__c,
                            'EquityPercentage'=>objInSalesOrder.EquityPercentage__c/100,
                            'Accelerator' =>objCommissionLineItem.AcceleratorAmount__c,
                            'X30Commission' =>objCommissionLineItem.Commission30__c,
                            'X70Commission' =>objCommissionLineItem.Commission70__c,
                            'Accelerator' =>(objCommissionLineItem.AcceleratorAmount__c),
                            'KPIPercentage' =>objMontlySalesTareget.KPIPayoutPercentage__c/100,
                            'TotalPaableCommi' =>(objCommissionLineItem.TotalPayableCommission__c).setScale(2),
                            'PayoutAmount' =>(objFutureCommisionPayoutLine.PayoutAmount__c).setScale(2),
                            'PayoutType' =>'Future',
                            'dir'=>objFutureCommisionPayoutLine.DirectorPayoutAmount__c,
                            'Broker_Head'=>objFutureCommisionPayoutLine.BrokerHeadPayoutAmount__c,
                            'Sales_Head'=>objFutureCommisionPayoutLine.SalesHeadPayoutAmount__c,
                            'Wealth_Head'=>objFutureCommisionPayoutLine.CorporateWealthPayoutAmount__c,
                            'Land_Head'=>objFutureCommisionPayoutLine.LandHead__c,
                            'Ex_Dir'=>objFutureCommisionPayoutLine.ExecDirectorPayoutAmount__c,
                            'CCO'=>objFutureCommisionPayoutLine.CCOPayoutAmount__c,
                            'agentType'=>objInSalesOrder.AgentType__c
                        });
                    }
				}
			}
        }
		if(!delCommissionPayout.isEmpty()){
			Delete delCommissionPayout;
		}
    }
    
    public static void commisionPayoutLines(Map<String, object> results, 
											Map<Id, MonthlySalesTarget__c> managerBasedMonSalesTarget,
											List<MonthlySalesTarget__c> lstMonthlySalesTarget,
                                            String targetMonth, String targetYear, boolean isBatch, boolean isValidateCommission){
		Map<Id, Map<String, User>> userDetails = new Map<Id, Map<String, User>>();
		set<Id> userIds = new set<Id>();
		Map<Id, SalesOrder__c> mapSalesOrders = new Map<Id, SalesOrder__c>();
		List<CommissionLineItem__c> lstCommisionLineItems = new List<CommissionLineItem__c>();
		Set<Id> salesOrderIds = new Set<Id>();
		integer numberOfDays = date.daysInMonth(integer.valueOf(targetYear), integer.valueOf(targetMonth));
		date soldStartDate = date.newInstance(integer.valueOf(targetYear), integer.valueOf(targetMonth), 1);
		date soldEndDate = date.newInstance(integer.valueOf(targetYear), integer.valueOf(targetMonth), numberOfDays);
		CommissionPayoutService.getCommissionLines(lstMonthlySalesTarget, soldStartDate, soldEndDate, 
                                                            lstCommisionLineItems, mapSalesOrders, 
                                                             salesOrderIds);
        Map<Id, MonthlySalesTarget__c> allMangerMonSalesTarget = new Map<Id, MonthlySalesTarget__c>();
		Map<String, CommissionPayout__mdt> commissionPayoutMetaData = new Map<String, CommissionPayout__mdt>();
		CommissionPayoutService.getCommissionPayoutMetaData(commissionPayoutMetaData);
		/*
		Map<Id, List<CommissionPayoutLine__c>> mapPayoutLines = New Map<Id, List<CommissionPayoutLine__c>>();
		CommissionPayoutService.getCurrentMonthCommissionPayoutLines(mapPayoutLines, lstCommisionLineItems);
		*/
		Set<Id> setSalesOrderIds = new Set<Id>();
		List<Object> lstCommissionPayoutLines = new List<Object>();
		List<CommissionPayoutLine__c> lstCommissionPayoutLiness = new List<CommissionPayoutLine__c>();
		
		//Using to add the future commission calculation
		Map<String,list<CommissionPayoutLine__c>> mapExistingCommissionPayOuts = new Map<String,list<CommissionPayoutLine__c>>();
		List<CommissionPayoutLine__c> lstExistingCommisionPayouts = new List<CommissionPayoutLine__c>();
		CommissionPayoutService.getExistingCommissionPayoutLines(mapExistingCommissionPayOuts, salesOrderIds, soldStartDate);
		CommissionPayoutService.getCalculatedCommissionPayouts(lstCommisionLineItems, mapSalesOrders, 
																managerBasedMonSalesTarget, 
																commissionPayoutMetaData, 
																lstCommissionPayoutLines,
																lstCommissionPayoutLiness, 
																results, mapExistingCommissionPayOuts,
																lstExistingCommisionPayouts,isBatch,targetMonth,targetYear);
		
		if(!lstExistingCommisionPayouts.isEmpty() && !isValidateCommission){
            update lstExistingCommisionPayouts;                                       
		}
                                                
		results.put('tableData', lstCommissionPayoutLines);
		results.put('payoutLines', lstCommissionPayoutLiness);
		results.put('lstCommisionLineItems', lstCommisionLineItems);
		results.put('mapSalesOrders', mapSalesOrders);
		results.put('mapExistingCommissionPayOuts', mapExistingCommissionPayOuts);
	}
    
}