/**********************************************************************************************************************
* Name               : BrokerQuarterlyBonusCalculationsBatch                                                       
* Description        : Batch to create Quarterly Bonus Commission Records with Commission Line Items
* Usage              : Run for Last Quarter on Sales order by brokers                                               
* Created By         : Sanket Kumar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           sajkumar@aldar.com      10 April 2023   Initial Draft       
******************************************************************************************************************/
global class BrokerQuarterlyBonusCalculationsBatch implements Schedulable, Database.Batchable<sObject>{
    /**
    * Method Name : execute
    * Desription : Schedule the batch job
    **/
    global void execute(SchedulableContext ctx) {
        database.executeBatch(new BrokerQuarterlyBonusCalculationsBatch(), 1);
    }
    
    /**
    * Method Name : start
    * Desription : start method of the batch job, returns the active agencies to process
    **/
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'select id from account where AgencyStatus__c = \'Active\' and Broker_Classification_Formula__c != \'Standard\' ';
        return Database.getQueryLocator(query);
    }
    
    /**
    * Method Name : execute
    * Desription : creates the Quarterly Bonus Commission record for broker
    **/
    global void execute(Database.BatchableContext BC, List<Account> accountList){
        Map<Id,List<SalesOrder__c>> mapOfAccountWithItsSalesOrder = new Map<Id,List<SalesOrder__c>>();
        
        //query on Sales order related to agency where status is sold and sales approved date is in last quarter
        //and eligible for bonus equals true based on launched date
        //or sales order not from this quarter and last quarter but BrokerQuarterlyCommisionStatus__c equals Eligible For Next Quarter
        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
        
        if(!Test.isRunningTest()){
        salesOrderList = [select id, Account__c, NetAmount__c, EquityPercentage__c, BookingDate__c,
                                Unit__r.BuildingSectionName__r.LaunchStartDate__c, QuarterlyBonusInvoice__c,
                                opportunity__r.BrokerAgencyAccount__c, opportunity__r.BrokerAgencyAccount__r.ParentId,
                                Opportunity__r.BrokerAgencyAccount__r.BrokerClassification__r.QuarterlyBonusforAgencies__c,
                                Opportunity__r.BrokerAgencyAccount__r.Broker_Classification_Formula__c,
                                BrokerQuarterlyCommisionStatus__c, ExcludeFromBonusInvoice__c, EligibleForBonusPayout__c,
                                BrokerClassificationWhenSold__c 
                                from SalesOrder__c where Status__c =: constants.COMMISSION_LINE_STATUS_SOLD and
                                EligibleForBonusPayout__c = true and
                                BookingDate__c = THIS_YEAR  and
                                ((BookingDate__c  = LAST_QUARTER and opportunity__r.BrokerAgencyAccount__c =: accountList)
                                or (BookingDate__c  != THIS_QUARTER 
                                    and BookingDate__c  != LAST_QUARTER 
                                    and BrokerQuarterlyCommisionStatus__c =: constants.COMMISSION_LINE_ELIGIBLE_FOR_NEXT_QUARTER)
                                )];
        }else {
              salesOrderList = [select id, Account__c, NetAmount__c, EquityPercentage__c, BookingDate__c,
                                Unit__r.BuildingSectionName__r.LaunchStartDate__c, QuarterlyBonusInvoice__c,
                                opportunity__r.BrokerAgencyAccount__c, opportunity__r.BrokerAgencyAccount__r.ParentId,
                                Opportunity__r.BrokerAgencyAccount__r.BrokerClassification__r.QuarterlyBonusforAgencies__c,
                                Opportunity__r.BrokerAgencyAccount__r.Broker_Classification_Formula__c,
                                BrokerQuarterlyCommisionStatus__c, ExcludeFromBonusInvoice__c, EligibleForBonusPayout__c,
                                BrokerClassificationWhenSold__c 
                                from SalesOrder__c where Status__c =: constants.COMMISSION_LINE_STATUS_SOLD and
                                ((BookingDate__c  = LAST_QUARTER and opportunity__r.BrokerAgencyAccount__c =: accountList)
                                or (BookingDate__c  != THIS_QUARTER 
                                    and BookingDate__c  != LAST_QUARTER 
                                    and BrokerQuarterlyCommisionStatus__c =: constants.COMMISSION_LINE_ELIGIBLE_FOR_NEXT_QUARTER)
                                )];
        }
        
        
        for(SalesOrder__c so : salesOrderList)
        {
            if(string.isblank(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){
                if(mapOfAccountWithItsSalesOrder.containskey(so.opportunity__r.BrokerAgencyAccount__c)){
                    mapOfAccountWithItsSalesOrder.get(so.opportunity__r.BrokerAgencyAccount__c).add(so);
                }else{
                    mapOfAccountWithItsSalesOrder.put(so.opportunity__r.BrokerAgencyAccount__c, new List<SalesOrder__c>{so});
                }
            }else{
                if(mapOfAccountWithItsSalesOrder.containskey(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){
                    mapOfAccountWithItsSalesOrder.get(so.opportunity__r.BrokerAgencyAccount__r.ParentId).add(so);
                }else{
                    mapOfAccountWithItsSalesOrder.put(so.opportunity__r.BrokerAgencyAccount__r.ParentId, new List<SalesOrder__c>{so});
                }
            }
        }
        
        //getting the threshold values from metadata
        BrokerCommissionSetting__mdt thresholdInfo = BrokerCommissionSetting__mdt.getInstance(constants.COMMISSION_LINE_QUARTER_PAYOUT); 
        
        //Getting the fiscal quarter and year
        Integer quarter = [Select Number From Period Where type =: constants.COMMISSION_LINE_QUARTER_NAME and StartDate = LAST_FISCAL_QUARTER].Number;
        String currentFiscalYear = [SELECT FiscalYearSettings.Name FROM Period WHERE StartDate = LAST_FISCAL_QUARTER limit 1].FiscalYearSettings.Name;
        
        //defined the variable for processing the logic
        Map<Id,Account> agenciesToUpdate = new Map<Id,Account>();
        Map<Id,String> agenciesVsClassification = new Map<Id,String>();
        Map<Id,String> agenciesVsQuarter = new Map<Id,String>();
        Map<Id,SalesOrder__c> mapOfSalesOrderToUpdate = new Map<Id,SalesOrder__c>();
        Map<Id, Decimal> mapOfAgencyVsSellingAmountCurrentQuarter = new Map<Id,Decimal>();
        Map<Id, List<SalesOrder__c>> mapOfAgencyVsListOfEligibleSalesOrder = new Map<Id,List<SalesOrder__c>>();
        
        //run the loop on sales order list by agency
        for(Id agencyId : mapOfAccountWithItsSalesOrder.keyset()){
            Decimal EligibleNetAmount = 0;
            for(SalesOrder__c so: mapOfAccountWithItsSalesOrder.get(agencyId)){
                SalesOrder__c oldSalesOrder = so; 
                //creates a map of agency vs their classification
                if(string.isblank(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){
                    if(!agenciesVsClassification.containsKey(so.opportunity__r.BrokerAgencyAccount__c)){
                        if(string.isnotblank(so.BrokerClassificationWhenSold__c)){
                            agenciesVsClassification.put(so.opportunity__r.BrokerAgencyAccount__c,so.BrokerClassificationWhenSold__c);
                        }else{
                            agenciesVsClassification.put(so.opportunity__r.BrokerAgencyAccount__c,so.Opportunity__r.BrokerAgencyAccount__r.Broker_Classification_Formula__c);
                        }
                        //agenciesVsClassification.put(so.opportunity__r.BrokerAgencyAccount__c,so.Opportunity__r.BrokerAgencyAccount__r.Broker_Classification_Formula__c);
                    }
                    //creates a map of agency vs quarter
                    agenciesVsQuarter.put(so.opportunity__r.BrokerAgencyAccount__c,Constants.COMMISSION_LINE_QUARTER.get(quarter));
                }else{
                    if(!agenciesVsClassification.containsKey(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){
                        if(string.isnotblank(so.BrokerClassificationWhenSold__c)){
                            agenciesVsClassification.put(so.opportunity__r.BrokerAgencyAccount__r.ParentId,so.BrokerClassificationWhenSold__c);
                        }else{
                            agenciesVsClassification.put(so.opportunity__r.BrokerAgencyAccount__r.ParentId,so.Opportunity__r.BrokerAgencyAccount__r.Broker_Classification_Formula__c);
                        }
                        //agenciesVsClassification.put(so.opportunity__r.BrokerAgencyAccount__r.ParentId,so.Opportunity__r.BrokerAgencyAccount__r.Broker_Classification_Formula__c);
                    }
                    //creates a map of agency vs quarter
                    agenciesVsQuarter.put(so.opportunity__r.BrokerAgencyAccount__r.ParentId,Constants.COMMISSION_LINE_QUARTER.get(quarter));
                }
                
                if(so.NetAmount__c != null){
                    EligibleNetAmount = EligibleNetAmount + so.NetAmount__c;
                }
                //if equity percentage is greater tha or equal to threshold
                if(so.EquityPercentage__c >= thresholdInfo.EquityPercentage__c){
                    //if so has not been excluded from calculation manually
                    if(!so.ExcludeFromBonusInvoice__c){
                        so.BrokerQuarterlyCommisionStatus__c = constants.COMMISSION_LINE_ELIGIBLE;
                        if(string.isblank(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){
                            if(mapOfAgencyVsListOfEligibleSalesOrder.containskey(so.opportunity__r.BrokerAgencyAccount__c)){
                                mapOfAgencyVsListOfEligibleSalesOrder.get(so.opportunity__r.BrokerAgencyAccount__c).add(so);
                            }else{
                                mapOfAgencyVsListOfEligibleSalesOrder.put(so.opportunity__r.BrokerAgencyAccount__c,new List<SalesOrder__C>{so});
                            }
                        }else{
                            if(mapOfAgencyVsListOfEligibleSalesOrder.containskey(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){
                                mapOfAgencyVsListOfEligibleSalesOrder.get(so.opportunity__r.BrokerAgencyAccount__r.ParentId).add(so);
                            }else{
                                mapOfAgencyVsListOfEligibleSalesOrder.put(so.opportunity__r.BrokerAgencyAccount__r.ParentId,new List<SalesOrder__C>{so});
                            }
                        }
                    }
                }else{
                    so.BrokerQuarterlyCommisionStatus__c = constants.COMMISSION_LINE_ELIGIBLE_FOR_NEXT_QUARTER;
                }
                
                //mapOfSalesOrderToUpdate holds the so field values to updated
                if(!so.ExcludeFromBonusInvoice__c){
                    SalesOrder__c newSalesOrder = new SalesOrder__c(Id=so.Id);
                    newSalesOrder.BrokerClassificationWhenSold__c = string.isblank(so.BrokerClassificationWhenSold__c) ? so.Opportunity__r.BrokerAgencyAccount__r.Broker_Classification_Formula__c : so.BrokerClassificationWhenSold__c;
                    newSalesOrder.BrokerQuarterlyCommisionStatus__c = so.BrokerQuarterlyCommisionStatus__c;
                    newSalesOrder.QuarterlyBonusInvoice__c = (so.QuarterlyBonusInvoice__c == null) ? so.Opportunity__r.BrokerAgencyAccount__r.BrokerClassification__r.QuarterlyBonusforAgencies__c : so.QuarterlyBonusInvoice__c;
                    if(oldSalesOrder.BrokerQuarterlyCommisionStatus__c != newSalesOrder.BrokerQuarterlyCommisionStatus__c || 
                        oldSalesOrder.QuarterlyBonusInvoice__c != newSalesOrder.QuarterlyBonusInvoice__c ||
                        oldSalesOrder.BrokerClassificationWhenSold__c != newSalesOrder.BrokerClassificationWhenSold__c )  { mapOfSalesOrderToUpdate.put(so.Id,newSalesOrder);
                    }
                }
            }
            
            //if eligible net amount for agencies are less than amount threshold per quarter
            if(EligibleNetAmount < thresholdInfo.SumOfNetAmountThreshold__c){
                for(SalesOrder__c so: mapOfAccountWithItsSalesOrder.get(agencyId)){
                    if(!so.ExcludeFromBonusInvoice__c){
                        if(mapOfSalesOrderToUpdate.containskey(so.Id)){
                            if(mapOfSalesOrderToUpdate.get(so.Id).BrokerQuarterlyCommisionStatus__c != constants.COMMISSION_LINE_NOT_ELIGIBLE){
                                mapOfSalesOrderToUpdate.get(so.Id).BrokerQuarterlyCommisionStatus__c = constants.COMMISSION_LINE_NOT_ELIGIBLE;
                            }
                        }else{
                            if(so.BrokerQuarterlyCommisionStatus__c != constants.COMMISSION_LINE_NOT_ELIGIBLE){
                                so.BrokerQuarterlyCommisionStatus__c = constants.COMMISSION_LINE_NOT_ELIGIBLE;
                                mapOfSalesOrderToUpdate.put(so.Id,new SalesOrder__c(Id=so.Id,BrokerQuarterlyCommisionStatus__c = so.BrokerQuarterlyCommisionStatus__c));
                            }
                        }
                    }
                }
                mapOfAgencyVsListOfEligibleSalesOrder.remove(agencyId);
            }else{
                mapOfAgencyVsSellingAmountCurrentQuarter.put(agencyId,EligibleNetAmount);
            }
        }
        
        //generate map of classification name and bonus percentage
        Map<String,Decimal> mapOfClassificationNameWithBonus = new Map<String,Decimal>();
        // Added By Moh Sarfaraj for BPM-650
        String currentyear = String.valueOf(System.Today().year()); 

        for(BrokerClassification__c brokerclassification : [select id,name,QuarterlyBonusforAgencies__c 
                                                            from BrokerClassification__c WHERE Year__c = :currentyear]){
            mapOfClassificationNameWithBonus.put(brokerclassification.name,brokerclassification.QuarterlyBonusforAgencies__c);
        }
        
        //generate map of cli and its unique key
        Map<string,CommissionLineItem__c> mapOfAgencySOVsCLI = new Map<string,CommissionLineItem__c>();
        for(CommissionLineItem__c cli : [Select Id,SalesOrder__c, BrokerAgency__c from CommissionLineItem__c 
                                         where QuarterlyPayout__c =: Constants.COMMISSION_LINE_QUARTER.get(quarter)
                                         and CommissionType__c =: constants.COMMISSION_LINE_BONUS_COMMISSION])
        {
            string uniqueId = ''+cli.BrokerAgency__c+cli.SalesOrder__c;
            mapOfAgencySOVsCLI.put(uniqueId,cli);
        }
        
        //query existing quarter bonus record and create map of it
        Map<Integer,QuarterlyBonusCommission__c> maOfQuarterVsBonusRecord = new Map<Integer,QuarterlyBonusCommission__c>();
        Map<Id,QuarterlyBonusCommission__c> maOfAgencyIdVsBonusRecord = new Map<Id,QuarterlyBonusCommission__c>();
        for(QuarterlyBonusCommission__c qbc : [Select Id, Quarter__c, BrokerAgency__c from QuarterlyBonusCommission__c 
                                         where Quarter__c =: Constants.COMMISSION_LINE_QUARTER.get(quarter) and Approval_Status__c = null ])
        {
            maOfQuarterVsBonusRecord.put(quarter,qbc);
            maOfAgencyIdVsBonusRecord.put(qbc.BrokerAgency__c,qbc);
        }
        
        //upsert quarter bonus records
        List<QuarterlyBonusCommission__c> quarterBonusRecordToInsert = new List<QuarterlyBonusCommission__c>();
        for(Id agencyId : mapOfAgencyVsListOfEligibleSalesOrder.keyset()){
            QuarterlyBonusCommission__c commissionForThisQuarter;
            if(!maOfAgencyIdVsBonusRecord.containskey(agencyId)){
                commissionForThisQuarter = new QuarterlyBonusCommission__c();
            }else{
                commissionForThisQuarter = maOfAgencyIdVsBonusRecord.get(agencyId);
            }
            commissionForThisQuarter.Quarter__c = Constants.COMMISSION_LINE_QUARTER.get(quarter);
            commissionForThisQuarter.Status__c = constants.COMMISSION_LINE_NOT_READY;
            commissionForThisQuarter.BrokerAgency__c = agencyId;
            commissionForThisQuarter.Year__c = currentFiscalYear;
            commissionForThisQuarter.TotalEligibleAmount__c = mapOfAgencyVsSellingAmountCurrentQuarter.get(agencyId);
            if(mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)) != null){
                commissionForThisQuarter.TotalCommissionAmount__c = (commissionForThisQuarter.TotalEligibleAmount__c * mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)))/100;
            }else{
                commissionForThisQuarter.TotalCommissionAmount__c = 0;
            }
            quarterBonusRecordToInsert.add(commissionForThisQuarter);
            maOfAgencyIdVsBonusRecord.put(agencyId,commissionForThisQuarter);
        }
        if(!quarterBonusRecordToInsert.isempty()){
            upsert quarterBonusRecordToInsert;
        }
        
        //query newly upserted bonus record and update the map with fresh values
       for(QuarterlyBonusCommission__c qbc : [Select Id, Quarter__c, BrokerAgency__c from QuarterlyBonusCommission__c 
                                         where Quarter__c =: Constants.COMMISSION_LINE_QUARTER.get(quarter) and Approval_Status__c = null ])
        {
            maOfQuarterVsBonusRecord.put(quarter,qbc);
            maOfAgencyIdVsBonusRecord.put(qbc.BrokerAgency__c,qbc);
        }
        
        //upsert the commission line items
        List<CommissionLineItem__c> cliToInsert = new List<CommissionLineItem__c>();
        for(Id agencyId : mapOfAgencyVsListOfEligibleSalesOrder.keyset()){
            for(SalesOrder__c so : mapOfAgencyVsListOfEligibleSalesOrder.get(agencyId)){
                string uniqueId = ''+agencyId+so.Id;
                if(mapOfAgencySOVsCLI.containskey(uniqueId)){  
                    CommissionLineItem__c cli = mapOfAgencySOVsCLI.get(uniqueId);
                    if(mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)) != null){
                        cli.CommissionPercentage__c = mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId));
                        cli.CommissionAmount__c = (so.NetAmount__c * mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)))/100;
                    }else{
                        cli.CommissionPercentage__c = 0;
                        cli.CommissionAmount__c = 0;
                    }
                    //cli.CommissionAmount__c = (so.NetAmount__c * mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)))/100;
                    //cli.CommissionPercentage__c = mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId));
                    cli.QuarterlyBonusCommission__c = maOfAgencyIdVsBonusRecord.get(agencyId).Id;
                    cliToInsert.add(cli);
                }else{
                    CommissionLineItem__c cli = new CommissionLineItem__c();
                    cli.CommissionType__c = constants.COMMISSION_LINE_BONUS_COMMISSION;
                    cli.BrokerAgency__c = agencyId;
                    cli.SalesOrder__c = so.Id;
                    cli.QuarterlyPayout__c = agenciesVsQuarter.get(agencyId);
                    if(mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)) != null){
                        cli.CommissionPercentage__c = mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId));
                        cli.CommissionAmount__c = (so.NetAmount__c * mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)))/100;
                    }else{
                        cli.CommissionPercentage__c = 0;
                        cli.CommissionAmount__c = 0;
                    }
                    
                    cli.QuarterlyBonusCommission__c = maOfAgencyIdVsBonusRecord.get(agencyId).Id;
                    cliToInsert.add(cli);
                }
            }
            
        }
        
        if(!cliToInsert.isempty()){
            upsert cliToInsert;
        }
        if(!mapOfSalesOrderToUpdate.values().isempty()){
            //Commenting as of now to validate the results in prod
            //update mapOfSalesOrderToUpdate.values();
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}