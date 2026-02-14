public with sharing class SalesCommissionController {
    @AuraEnabled
    public static Map<String, object> getCommissionPayoutLineItems(String targetMonth, String targetYear){
        Map<String, object> results = new Map<String, object>(); 
        try {
                //Set<Id> salesMangerId = new Set<Id>();
                

                Map<Id, MonthlySalesTarget__c> managerBasedMonSalesTarget = new Map<Id, MonthlySalesTarget__c>();
                List<MonthlySalesTarget__c> lstMonthlySalesTarget = new List<MonthlySalesTarget__c>();
                
                for(MonthlySalesTarget__c objMSaleTarget : [SELECT AcceleratorCommissionAmount__c, AcceleratorPercentage__c,
                                                                    TargetAmount__c, TargetMonth__c, KPI1__c, KPI2__c,
                                                                    TargetYear__c, AcceleratorTargetAmount__c,
                                                                    ResourceName__c, KPIPayoutPercentage__c FROM MonthlySalesTarget__c 
                                                                    WHERE TargetMonth__c =: targetMonth AND TargetYear__c =: targetYear]){
                    //salesMangerId.add(objMSaleTarget.ResourceName__c);
                    managerBasedMonSalesTarget.put(objMSaleTarget.ResourceName__c, objMSaleTarget);
                    lstMonthlySalesTarget.add(objMSaleTarget);                                                    
                }
                system.debug('managerBasedMonSalesTarget>>>>>'+managerBasedMonSalesTarget);
                CommissionPayoutService.commisionPayoutLines(results, managerBasedMonSalesTarget, lstMonthlySalesTarget,targetMonth, targetYear, false, false);
                
        } catch (Exception e) {
            System.debug('exception details>>>>'+e);
            System.debug('exception details>>>>'+e.getLineNumber());
            System.debug('exception details>>>>'+e.getMessage());
            //throw new AuraHandledException(e.getMessage());
        }
        return results;
    }

    @AuraEnabled
    public static void validateCommissionPaylineItems(List<CommissionPayoutLine__c> lstCommissionPaylines, 
                                                        List<CommissionLineItem__c> lstCommisionLineItems, 
                                                        Map<Id, SalesOrder__c> mapSalesOrders,
                                                      	Map<String,list<CommissionPayoutLine__c>> mapExistingCommissionPayOuts,
                                                        String strMonth, String strYear){
        
        try {
            MonthlySalesTarget__c objMonthlySalesTargetParent = new MonthlySalesTarget__c();
            system.debug('lstCommissionPaylines>>>>>>>>'+lstCommissionPaylines);
            
            List<MonthlySalesTarget__c> lstMonthParents = [SELECT id FROM MonthlySalesTarget__c WHERE MonthlySalesTarget__c = NULL AND IsParent__c = TRUE AND TargetMonth__c =:strMonth AND TargetYear__c =:strYear LIMIT 1];
            if(lstMonthParents.isEmpty()){
                objMonthlySalesTargetParent.TargetMonth__c = strMonth;
                objMonthlySalesTargetParent.TargetYear__c = strYear;
                
                objMonthlySalesTargetParent.Team__c = 'AUH';
                objMonthlySalesTargetParent.TargetAmount__c = 00;
                objMonthlySalesTargetParent.InventoryTargetAmount__c = 00;
                objMonthlySalesTargetParent.LaunchTargetAmount__c = 00;
                objMonthlySalesTargetParent.IsParent__c = TRUE;
                insert objMonthlySalesTargetParent;
            }else{
                objMonthlySalesTargetParent = lstMonthParents[0];
            }

            Map<Id, CommissionLineItem__c> commissionLineItemsMap = new Map<Id, CommissionLineItem__c>(lstCommisionLineItems);
            Map<Id, Decimal> usersSumUpValues =  new Map<Id, Decimal>();
            Map<String,CommissionPayout__mdt> commissionPayoutMetaData = new Map<String,CommissionPayout__mdt>();
            Map<String,CommissionPayout__mdt> teamsPayoutMetaData = new Map<String,CommissionPayout__mdt>();
            for(CommissionPayout__mdt objCommissionPayOutMD : CommissionPayout__mdt.getAll().values()){
                commissionPayoutMetaData.put(objCommissionPayOutMD.Role__c, objCommissionPayOutMD);
                if(String.isNotBlank(objCommissionPayOutMD.Team__c)){
                    teamsPayoutMetaData.put(objCommissionPayOutMD.Team__c, objCommissionPayOutMD);
                }
            }

            Set<Id> salesManagersId = new Set<Id>();
            Map<Id, List<CommissionPayoutLine__c>> mpaCommissionPayouts = new Map<Id, List<CommissionPayoutLine__c>>();
            Decimal corporateHeadCommission = 0;
            Decimal wealthHeadCommission = 0;
            Decimal brokerHeadeCommission = 0;
            Decimal landHeadeCommission = 0;
            Decimal ccoCommission = 0;
            Decimal dirCommission = 0;
            Decimal exucutiveDirCommission = 0;

            Decimal corporateLaunchHeadCommission = 0;
            Decimal wealthLaunchHeadCommission = 0;
            Decimal brokerLaunchHeadeCommission = 0;
            Decimal landLaunchHeadeCommission = 0;
            Decimal ccoLaunchCommission = 0;
            Decimal dirLaunchCommission = 0;
            Decimal exucutiveDirLaunchCommission = 0;

            SalesOrder__c objSalesOrder = new SalesOrder__c();
            Map<Id, Decimal> managersMontlySalesSum = new Map<Id,Decimal>();
            Map<Id, Decimal> managersMontlySalesSumLaunch = new Map<Id,Decimal>();
            Map<Id, Decimal> managersMontlySalesSumLaunInven = new Map<Id, Decimal>();
            Map<String,Decimal> teamsMontlySalesSum = new Map<String,Decimal>();
            Map<String,Decimal> teamsMontlySalesSumLaunch = new Map<String,Decimal>();
            for(String managerId : mapExistingCommissionPayOuts.keySet()){
                if(!mapExistingCommissionPayOuts.get(managerId).isEmpty()){
                    lstCommissionPaylines.addAll(mapExistingCommissionPayOuts.get(managerId));
                }
            }
            
            for(CommissionPayoutLine__c objPayLine : lstCommissionPaylines){
                if(objPayLine.FutureCommission__c == Constants.COMMISSIONCURRENT){
                if(commissionLineItemsMap.containsKey(objPayLine.CommissionLineItem__c)){
                    objSalesOrder = mapSalesOrders.get(commissionLineItemsMap.get(objPayLine.CommissionLineItem__c).SalesOrder__c);
                    if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                        Decimal managerSalesAmount = 0;
                        if(managersMontlySalesSum.containsKey(objSalesOrder.SalesManager__c)){
                            managerSalesAmount = managersMontlySalesSum.get(objSalesOrder.SalesManager__c); 
                        }
                        managerSalesAmount = managerSalesAmount + objPayLine.PayoutAmount__c;
                        managersMontlySalesSum.put(objSalesOrder.SalesManager__c, managerSalesAmount);

                    }else if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
                        Decimal managerSalesAmount = 0;
                        if(managersMontlySalesSumLaunInven.containsKey(objSalesOrder.SalesManager__c)){
                            managerSalesAmount = managersMontlySalesSumLaunInven.get(objSalesOrder.SalesManager__c); 
                        }
                        managerSalesAmount = managerSalesAmount + objPayLine.PayoutAmount__c;
                        managersMontlySalesSumLaunInven.put(objSalesOrder.SalesManager__c, managerSalesAmount);
                    }
                    
                    System.debug('objSalesOrder>>>>>'+objSalesOrder);
                    System.debug('objSalesOrder>CustomerSubType__c>>>>'+objSalesOrder.Account__r.CustomerSubType__c);
                    System.debug('objSalesOrder>Team__c>>>>'+objSalesOrder.Team__c);
                    if(objSalesOrder.Team__c != Constants.TEAM_LAND){
                        if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                            Decimal teamSalesAmount = 0;
                            if(teamsMontlySalesSum.containsKey(objSalesOrder.Team__c)){
                                teamsMontlySalesSum.put(objSalesOrder.Team__c, teamsMontlySalesSum.get(objSalesOrder.Team__c) + objPayLine.SalesHeadPayoutAmount__c);
                            }else{
                                teamsMontlySalesSum.put(objSalesOrder.Team__c, objPayLine.SalesHeadPayoutAmount__c);
                            }
                        }else if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
                            Decimal teamSalesAmount = 0;
                            if(teamsMontlySalesSumLaunch.containsKey(objSalesOrder.Team__c)){
                                teamsMontlySalesSumLaunch.put(objSalesOrder.Team__c, teamsMontlySalesSumLaunch.get(objSalesOrder.Team__c) + objPayLine.SalesHeadPayoutAmount__c);
                            }else{
                                teamsMontlySalesSumLaunch.put(objSalesOrder.Team__c, objPayLine.SalesHeadPayoutAmount__c);
                            }
                        }
                        
                        
                        if(objSalesOrder.Account__r.CustomerSubType__c == Constants.WEALTH || objSalesOrder.Account__r.CustomerSubType__c == Constants.CORPORATE){
                            if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                                landHeadeCommission = landHeadeCommission + objPayLine.LandHead__c;
                            }else if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
                                landLaunchHeadeCommission = landHeadeCommission + objPayLine.LandHead__c;
                            }
                        }
                    }
                    
                    if(objSalesOrder.Team__c == Constants.TEAM_LAND){
                        if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                            landHeadeCommission = landHeadeCommission + objPayLine.LandHead__c;
                        }else if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
                            landLaunchHeadeCommission = landHeadeCommission + objPayLine.LandHead__c;
                        }
                    }
                    
                    if(objSalesOrder.Account__r.CustomerSubType__c == Constants.WEALTH){
                        System.debug('objPayLine>>>>>>WEALTH'+objPayLine);
                        
                        if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                            wealthHeadCommission = wealthHeadCommission + objPayLine.CorporateWealthPayoutAmount__c;
                        }else if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
                            wealthLaunchHeadCommission = wealthLaunchHeadCommission + objPayLine.CorporateWealthPayoutAmount__c;
                        }
                    }

                    if(objSalesOrder.Account__r.CustomerSubType__c == Constants.CORPORATE){
                        System.debug('objPayLine>>>>>>CORPORATE'+objPayLine);
                        
                        if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                            corporateHeadCommission = corporateHeadCommission + objPayLine.CorporateWealthPayoutAmount__c;
                        }else if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
                            corporateLaunchHeadCommission = corporateLaunchHeadCommission + objPayLine.CorporateWealthPayoutAmount__c;
                        }
                    }
                    if(objPayLine.BrokerHeadPayoutAmount__c != NULL){
                        
                        if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                            brokerHeadeCommission = brokerHeadeCommission + objPayLine.BrokerHeadPayoutAmount__c;
                        }else if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
                            brokerLaunchHeadeCommission = brokerLaunchHeadeCommission + objPayLine.BrokerHeadPayoutAmount__c;
                        }
                    }
                    
                    if(objPayLine.CCOPayoutAmount__c != NULL){
                        
                        if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                            ccoCommission = ccoCommission + objPayLine.CCOPayoutAmount__c;
                        }else if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
                            ccoLaunchCommission = ccoLaunchCommission + objPayLine.CCOPayoutAmount__c;
                        }
                    }

                    if(objPayLine.DirectorPayoutAmount__c != NULL){
                        
                        if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                            dirCommission = dirCommission + objPayLine.DirectorPayoutAmount__c;
                        }else if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
                            dirLaunchCommission = dirLaunchCommission + objPayLine.DirectorPayoutAmount__c;
                        }
                    }

                    if(objPayLine.ExecDirectorPayoutAmount__c != NULL){
                        
                        if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_INVENTORY){
                            exucutiveDirCommission = exucutiveDirCommission + objPayLine.ExecDirectorPayoutAmount__c;
                        }else if(objSalesOrder.InventoryLaunch__c == Constants.SALESORDER_INVENTORY_TYPE_LAUNCH){
                            exucutiveDirLaunchCommission = exucutiveDirLaunchCommission + objPayLine.ExecDirectorPayoutAmount__c;
                        }
                    }
                    }
                }
            }
            
            List<Id> lstResourceIds =  new List<Id>();
            lstResourceIds.addAll(managersMontlySalesSum.keySet());
            System.debug('teamsMontlySalesSum>>>>'+teamsMontlySalesSum);
            teamsMontlySalesSum.put(Constants.TEAM_LAND, landHeadeCommission);
            for(String teamName : teamsMontlySalesSum.keySet()){
                if(String.isNotBlank(teamsPayoutMetaData.get(teamName).HeadUserId__c)){
                    if(managersMontlySalesSum.containsKey(teamsPayoutMetaData.get(teamName).HeadUserId__c)){
                        managersMontlySalesSum.put(teamsPayoutMetaData.get(teamName).HeadUserId__c, 
                        managersMontlySalesSum.get(teamsPayoutMetaData.get(teamName).HeadUserId__c) + teamsMontlySalesSum.get(teamName));
                    }else{
                        managersMontlySalesSum.put(teamsPayoutMetaData.get(teamName).HeadUserId__c, teamsMontlySalesSum.get(teamName));
                    }
                    
                }
            }
            teamsMontlySalesSumLaunch.put(Constants.TEAM_LAND, landLaunchHeadeCommission);
            for(String teamName : teamsMontlySalesSumLaunch.keySet()){
                if(String.isNotBlank(teamsPayoutMetaData.get(teamName).HeadUserId__c)){
                    if(managersMontlySalesSumLaunInven.containsKey(teamsPayoutMetaData.get(teamName).HeadUserId__c)){
                        managersMontlySalesSumLaunInven.put(teamsPayoutMetaData.get(teamName).HeadUserId__c, managersMontlySalesSumLaunInven.get(teamsPayoutMetaData.get(teamName).HeadUserId__c) + teamsMontlySalesSumLaunch.get(teamName));
                    }else{
                        managersMontlySalesSumLaunInven.put(teamsPayoutMetaData.get(teamName).HeadUserId__c, teamsMontlySalesSumLaunch.get(teamName));
                    }
                    
                }
            }
            System.debug('managersMontlySalesSum>>>>'+managersMontlySalesSum);
            if(managersMontlySalesSum.containsKey(commissionPayoutMetaData.get(Constants.EXECUTIVE_DIRECTOR_OF_SALES).HeadUserId__c)){
                managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.EXECUTIVE_DIRECTOR_OF_SALES).HeadUserId__c, 
                managersMontlySalesSum.get(commissionPayoutMetaData.get(Constants.EXECUTIVE_DIRECTOR_OF_SALES).HeadUserId__c) + exucutiveDirCommission);
            }else{
                managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.EXECUTIVE_DIRECTOR_OF_SALES).HeadUserId__c, exucutiveDirCommission);
            }

            if(managersMontlySalesSumLaunInven.containsKey(commissionPayoutMetaData.get(Constants.EXECUTIVE_DIRECTOR_OF_SALES).HeadUserId__c)){
                managersMontlySalesSumLaunInven.put(commissionPayoutMetaData.get(Constants.EXECUTIVE_DIRECTOR_OF_SALES).HeadUserId__c, managersMontlySalesSumLaunInven.get(commissionPayoutMetaData.get(Constants.EXECUTIVE_DIRECTOR_OF_SALES).HeadUserId__c) + exucutiveDirLaunchCommission);
            }else{
                managersMontlySalesSumLaunInven.put(commissionPayoutMetaData.get(Constants.EXECUTIVE_DIRECTOR_OF_SALES).HeadUserId__c, exucutiveDirLaunchCommission);
            }

            if(managersMontlySalesSum.containsKey(commissionPayoutMetaData.get(Constants.CCO).HeadUserId__c)){
                managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.CCO).HeadUserId__c, managersMontlySalesSum.get(commissionPayoutMetaData.get(Constants.CCO).HeadUserId__c) + ccoCommission);
            }else{
                managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.CCO).HeadUserId__c, ccoCommission);
            }

            if(managersMontlySalesSumLaunInven.containsKey(commissionPayoutMetaData.get(Constants.CCO).HeadUserId__c)){
                managersMontlySalesSumLaunInven.put(commissionPayoutMetaData.get(Constants.CCO).HeadUserId__c, managersMontlySalesSumLaunInven.get(commissionPayoutMetaData.get(Constants.CCO).HeadUserId__c) + ccoLaunchCommission);
            }else{
                managersMontlySalesSumLaunInven.put(commissionPayoutMetaData.get(Constants.CCO).HeadUserId__c, ccoLaunchCommission);
            }    

            if(managersMontlySalesSum.containsKey(commissionPayoutMetaData.get(Constants.ASSOCIATE_DIRECTOR_OF_SALE).HeadUserId__c)){
                managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.ASSOCIATE_DIRECTOR_OF_SALE).HeadUserId__c, managersMontlySalesSum.get(commissionPayoutMetaData.get(Constants.ASSOCIATE_DIRECTOR_OF_SALE).HeadUserId__c) + dirCommission);
            }else{
                managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.ASSOCIATE_DIRECTOR_OF_SALE).HeadUserId__c, dirCommission);
            }

            if(managersMontlySalesSumLaunInven.containsKey(commissionPayoutMetaData.get(Constants.ASSOCIATE_DIRECTOR_OF_SALE).HeadUserId__c)){
                managersMontlySalesSumLaunInven.put(commissionPayoutMetaData.get(Constants.ASSOCIATE_DIRECTOR_OF_SALE).HeadUserId__c, managersMontlySalesSumLaunInven.get(commissionPayoutMetaData.get(Constants.ASSOCIATE_DIRECTOR_OF_SALE).HeadUserId__c) + dirLaunchCommission);
            }else{
                managersMontlySalesSumLaunInven.put(commissionPayoutMetaData.get(Constants.ASSOCIATE_DIRECTOR_OF_SALE).HeadUserId__c, dirLaunchCommission);
            }
            
            if(managersMontlySalesSum.containsKey(commissionPayoutMetaData.get(Constants.HEAD_OF_BROKER).HeadUserId__c)){
                managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.HEAD_OF_BROKER).HeadUserId__c, managersMontlySalesSum.get(commissionPayoutMetaData.get(Constants.HEAD_OF_BROKER).HeadUserId__c) + brokerHeadeCommission);
            }else{
                managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.HEAD_OF_BROKER).HeadUserId__c, brokerHeadeCommission);
            }

            if(managersMontlySalesSumLaunInven.containsKey(commissionPayoutMetaData.get(Constants.HEAD_OF_BROKER).HeadUserId__c)){
                managersMontlySalesSumLaunInven.put(commissionPayoutMetaData.get(Constants.HEAD_OF_BROKER).HeadUserId__c, managersMontlySalesSumLaunInven.get(commissionPayoutMetaData.get(Constants.HEAD_OF_BROKER).HeadUserId__c) + brokerLaunchHeadeCommission);
            }else{
                managersMontlySalesSumLaunInven.put(commissionPayoutMetaData.get(Constants.HEAD_OF_BROKER).HeadUserId__c, brokerLaunchHeadeCommission);
            }
            
            if(managersMontlySalesSum.containsKey(commissionPayoutMetaData.get(Constants.CORPORATE).HeadUserId__c)){
                managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.CORPORATE).HeadUserId__c, managersMontlySalesSum.get(commissionPayoutMetaData.get(Constants.CORPORATE).HeadUserId__c) + corporateHeadCommission);
            }else{
                managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.CORPORATE).HeadUserId__c, corporateHeadCommission);
            }

            if(managersMontlySalesSumLaunInven.containsKey(commissionPayoutMetaData.get(Constants.CORPORATE).HeadUserId__c)){
                managersMontlySalesSumLaunInven.put(commissionPayoutMetaData.get(Constants.CORPORATE).HeadUserId__c, managersMontlySalesSumLaunInven.get(commissionPayoutMetaData.get(Constants.CORPORATE).HeadUserId__c) + corporateLaunchHeadCommission);
            }else{
                managersMontlySalesSumLaunInven.put(commissionPayoutMetaData.get(Constants.CORPORATE).HeadUserId__c, corporateLaunchHeadCommission);
            }
           
            if(managersMontlySalesSum.containsKey(commissionPayoutMetaData.get(Constants.WEALTH).HeadUserId__c)){
                managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.WEALTH).HeadUserId__c, managersMontlySalesSum.get(commissionPayoutMetaData.get(Constants.WEALTH).HeadUserId__c) + wealthHeadCommission);
            }else{
                managersMontlySalesSum.put(commissionPayoutMetaData.get(Constants.WEALTH).HeadUserId__c, wealthHeadCommission);
            }

            if(managersMontlySalesSumLaunInven.containsKey(commissionPayoutMetaData.get(Constants.WEALTH).HeadUserId__c)){
                managersMontlySalesSumLaunInven.put(commissionPayoutMetaData.get(Constants.WEALTH).HeadUserId__c,managersMontlySalesSumLaunInven.get(commissionPayoutMetaData.get(Constants.WEALTH).HeadUserId__c) + wealthLaunchHeadCommission);
            }else{
                managersMontlySalesSumLaunInven.put(commissionPayoutMetaData.get(Constants.WEALTH).HeadUserId__c, wealthLaunchHeadCommission);
            }

            
            System.debug('managersMontlySalesSum>>>>>>>'+managersMontlySalesSum);
            System.debug('corporateHeadCommission>>>>>>>'+corporateHeadCommission);
            List<MonthlySalesTarget__c> lstMonthlySalesTarget = new List<MonthlySalesTarget__c>();
            for(MonthlySalesTarget__c objMonthlySales :[SELECT ResourceName__c,LaunchCommission__c, InventoryCommission__c,TotalPayableCommission__c FROM 
                                                        MonthlySalesTarget__c Where 
                                                        ResourceName__c IN: managersMontlySalesSum.keySet() 
                                                        OR ResourceName__c IN:managersMontlySalesSumLaunInven.keySet()]){
                Decimal inventoryCommission = 0;
                Decimal launchCommission = 0;
                if(managersMontlySalesSum.containsKey(objMonthlySales.ResourceName__c)){
                    objMonthlySales.InventoryCommission__c = managersMontlySalesSum.get(objMonthlySales.ResourceName__c);
                    inventoryCommission = managersMontlySalesSum.get(objMonthlySales.ResourceName__c);
                    //lstMonthlySalesTarget.add(objMonthlySales);
                }
                if(managersMontlySalesSumLaunInven.containsKey(objMonthlySales.ResourceName__c)){
                    objMonthlySales.LaunchCommission__c = managersMontlySalesSumLaunInven.get(objMonthlySales.ResourceName__c);
                    launchCommission = managersMontlySalesSumLaunInven.get(objMonthlySales.ResourceName__c);
                    //lstMonthlySalesTarget.add(objMonthlySales);
                }
                objMonthlySales.TotalPayableCommission__c = (inventoryCommission + launchCommission).setScale(2);
                objMonthlySales.MonthlySalesTarget__c = objMonthlySalesTargetParent.Id;
				lstMonthlySalesTarget.add(objMonthlySales);
            }
            if(!lstCommissionPaylines.isEmpty()){
                upsert lstCommissionPaylines;
            }

            if(!lstCommisionLineItems.isEmpty()){
                update lstCommisionLineItems;
            }
            system.debug('lstMonthlySalesTarget>>>>>'+lstMonthlySalesTarget);
            if(!lstMonthlySalesTarget.isEmpty()){
                update lstMonthlySalesTarget;
            }
            
        } catch (Exception e) {
            system.debug('exception>>>'+e);
            system.debug('exception>>>'+e.getLineNumber());
            system.debug('exception>>>'+e.getMessage());
            //throw new AuraHandledException(e.getMessage());
        }
    }
   
}