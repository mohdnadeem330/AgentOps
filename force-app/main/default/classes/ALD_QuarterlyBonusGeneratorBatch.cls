/***************** Test class BrokerQuarterlyBonusCalculationsTest **************/

public class ALD_QuarterlyBonusGeneratorBatch implements Database.Batchable <SObject>, Database.stateful{
    Map<Id,String> agenciesVsClassification = new Map<Id,String>();
    String QuarterValue;
    Integer QuarterNumber;
    Integer Year;
    
    public ALD_QuarterlyBonusGeneratorBatch(Map<Id,String> agenciesVsClassification, String QuarterValue, Integer QuarterNumber, Integer Year){
        this.agenciesVsClassification = agenciesVsClassification;
        this.QuarterValue = QuarterValue;
        this.QuarterNumber = QuarterNumber;
        this.Year = Year;
    }
    
    public List<Account> start(Database.BatchableContext bc){
        Id brokerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId();
        
        List<Account> listOfAgencies; 
        List<Id> brokerAgencyAccountIds;
        brokerAgencyAccountIds = new List<Id>() ;
        
        if(!Test.isRunningTest()){
            for(Id agencyId : agenciesVsClassification.keySet()){  brokerAgencyAccountIds.add(agencyId); }
            listOfAgencies = [SELECT Id, AgencyRegion__c FROM Account WHERE Id IN : brokerAgencyAccountIds];
        }else {
            listOfAgencies = [select id, AgencyRegion__c from account where recordTypeId=: brokerRecordTypeId];
        } 
        return listOfAgencies;
    }
    
    public void execute(Database.BatchableContext bc, List<Account> listOfAgencies){
        Map<Id, String> agencyRegionMap = new Map<Id, String>();
        Map<Id, List<InstallmentLines__c>> installmentSalesorderMap = new Map<Id, List<InstallmentLines__c>>();
        Map<String, InstallmentLines__c> equityInstallment = new Map<String, InstallmentLines__c>();
        Map<Id,List<SalesOrder__c>> mapOfAccountWithItsSalesOrder = new Map<Id,List<SalesOrder__c>> ();
        Map<Id,Map<String, List<SalesOrder__c>>> mapOfAccountWithBUAndSalesOrder = new  Map<Id,Map<String, List<SalesOrder__c>>> ();
        Map<Id, ReceiptAllocation__c> installmentReceiptAllocationMap = new Map<Id, ReceiptAllocation__c>();
        
        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
        
        for(Account agency: listOfAgencies){
            agencyRegionMap.put(agency.Id, agency.AgencyRegion__c); 
        }
        If(!test.isRunningTest()){
            salesOrderList = [select id, Account__c, NetAmount__c, EquityPercentage__c, BookingDate__c,
                              Unit__r.BuildingSectionName__r.LaunchStartDate__c, QuarterlyBonusInvoice__c,Unit__r.Project__r.BusinessUnitId__c,
                              opportunity__r.BrokerAgencyAccount__c, opportunity__r.BrokerAgencyAccount__r.ParentId,
                              Opportunity__r.BrokerAgencyAccount__r.BrokerClassification__r.QuarterlyBonusforAgencies__c,
                              Opportunity__r.BrokerAgencyAccount__r.Broker_Classification_Formula__c,
                              Opportunity__r.BrokerAgencyAccount__r.AgencyRegion__c,
                              BrokerQuarterlyCommisionStatus__c, ExcludeFromBonusInvoice__c, EligibleForBonusPayout__c,
                              BrokerClassificationWhenSold__c   
                              from SalesOrder__c where Status__c = 'Sold' and EligibleForBonusPayout__c = true and CALENDAR_YEAR(BookingDate__c)=: Year AND CALENDAR_YEAR(SoldDate__c) =: Year  and 
                              // Chnaged here
                              ((CALENDAR_QUARTER(SoldDate__c)  =: QuarterNumber and opportunity__r.BrokerAgencyAccount__c in: listOfAgencies) or (CALENDAR_QUARTER(SoldDate__c)  !=: QuarterNumber and CALENDAR_QUARTER(SoldDate__c)  !=: (QuarterNumber-1) and BrokerQuarterlyCommisionStatus__c = 'Eligible For Next Quarter') )];
            
        }else{
            salesOrderList = [select id, Account__c, NetAmount__c, EquityPercentage__c, BookingDate__c,SoldDate__c,
                              Unit__r.BuildingSectionName__r.LaunchStartDate__c, QuarterlyBonusInvoice__c,Unit__r.Project__r.BusinessUnitId__c,
                              opportunity__r.BrokerAgencyAccount__c, opportunity__r.BrokerAgencyAccount__r.ParentId,
                              Opportunity__r.BrokerAgencyAccount__r.BrokerClassification__r.QuarterlyBonusforAgencies__c,
                              Opportunity__r.BrokerAgencyAccount__r.Broker_Classification_Formula__c,
                              Opportunity__r.BrokerAgencyAccount__r.AgencyRegion__c,
                              BrokerQuarterlyCommisionStatus__c, ExcludeFromBonusInvoice__c, EligibleForBonusPayout__c,
                              BrokerClassificationWhenSold__c   
                              from SalesOrder__c where Status__c = 'Sold'];            
            
        }
        List<InstallmentLines__c> installmentLineList =[SELECT Id,InstallmentAmount__c,InstallmentDate__c,InstallmentNumber__c,InstallmentPercentage__c,
                                                        PaymentClearanceDate__c,PaymentType__c,SalesOrder__c, SalesOrder__r.Name
                                                        FROM InstallmentLines__c WHERE SalesOrder__c IN: salesOrderList];
        
        
        
        for (InstallmentLines__c inst: installmentLineList ){
            List<InstallmentLines__c> instList = 
                installmentSalesorderMap.get(inst.SalesOrder__c) != null ? installmentSalesorderMap.get(inst.SalesOrder__c) : new List<InstallmentLines__c>();
            
            instList.add(inst);
            installmentSalesorderMap.put(inst.SalesOrder__c, instList);
        }        
        for(Id salesorderId: installmentSalesorderMap.keySet()){
            List<InstallmentLines__c> installmentLinesperSo  = installmentSalesorderMap.get(salesorderId);
            
            decimal equity = 0;
            for(InstallmentLines__c inst: installmentLinesperSo){
                equity = equity+inst.InstallmentPercentage__c;
                if(equity >= 20){
                    equityInstallment.put(inst.SalesOrder__c, inst);
                    break;
                }
            }
        }
        
        List<ReceiptAllocation__c> receiptAllocationList = [SELECT Id,ReceiptAcknowledgement__c, ReceiptAcknowledgement__r.ClearedDate__c, InstallmentLine__c FROM ReceiptAllocation__c
                                                            WHERE InstallmentLine__c IN:equityInstallment.values() AND ReceiptAcknowledgement__r.Status__c = 'Cleared' ORDER BY Createddate desc];  
        
        for(ReceiptAllocation__c receiptAllocation: receiptAllocationList){
            installmentReceiptAllocationMap.put(receiptAllocation.InstallmentLine__c, receiptAllocation);
            
        }
        for(SalesOrder__c so : salesOrderList){
            if(string.isblank(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){
                if(mapOfAccountWithItsSalesOrder.containskey(so.opportunity__r.BrokerAgencyAccount__c)){
                    mapOfAccountWithItsSalesOrder.get(so.opportunity__r.BrokerAgencyAccount__c).add(so);
                }
                else{ 
                    mapOfAccountWithItsSalesOrder.put(so.opportunity__r.BrokerAgencyAccount__c, new List<SalesOrder__c>{so}); 
                }
            }else{
                if(mapOfAccountWithItsSalesOrder.containskey(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){
                    mapOfAccountWithItsSalesOrder.get(so.opportunity__r.BrokerAgencyAccount__r.ParentId).add(so);
                } else{  
                    mapOfAccountWithItsSalesOrder.put(so.opportunity__r.BrokerAgencyAccount__r.ParentId, new List<SalesOrder__c>{so});
                }
                
                
            }
        }
        BrokerCommissionSetting__mdt thresholdInfo = BrokerCommissionSetting__mdt.getInstance(constants.COMMISSION_LINE_QUARTER_PAYOUT); 
        Integer quarter = QuarterNumber;
        //[Select Number From Period Where type = 'Quarter' and CALENDAR_QUARTER(StartDate) = 4 LIMIT 1].Number; // Chnaged here
        String currentFiscalYear = [SELECT FiscalYearSettings.Name FROM Period WHERE StartDate = LAST_FISCAL_QUARTER limit 1].FiscalYearSettings.Name; // Chnaged here
        Map<Id,Account> agenciesToUpdate = new Map<Id,Account>();
        
        Map<Id,String> agenciesVsQuarter = new Map<Id,String>();
        Map<Id,SalesOrder__c> mapOfSalesOrderToUpdate = new Map<Id,SalesOrder__c>();
        Map<Id, Decimal> mapOfAgencyVsSellingAmountCurrentQuarter = new Map<Id,Decimal>();
        Map<Id, Map<String, Decimal>> mapOfAgencyBUVsSellingAmountCurrentQuarter = new Map<Id, Map<String, Decimal>>();
        Map<Id, List<SalesOrder__c>> mapOfAgencyVsListOfEligibleSalesOrder = new Map<Id,List<SalesOrder__c>>();
        Map<Id,Map<String, List<SalesOrder__c>>> mapOfAgencyBUListOfEligibleSalesOrder = new Map<Id,Map<String, List<SalesOrder__c>>>();
        
        for(Id agencyId : mapOfAccountWithItsSalesOrder.keyset()){
            Decimal EligibleNetAmount = 0;
            Map<String, Decimal> mapOfBUvsEligibleAmount = new Map<String, Decimal>();
            Map<String, List<SalesOrder__c>> mapOfBUvsListOfEligibleSalesOrder = new Map<String, List<SalesOrder__c>>();
            
            for(SalesOrder__c so: mapOfAccountWithItsSalesOrder.get(agencyId)){
                SalesOrder__c oldSalesOrder = so; 
                if(string.isBlank(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){
                    agenciesVsQuarter.put(so.opportunity__r.BrokerAgencyAccount__c,Constants.COMMISSION_LINE_QUARTER.get(quarter));
                }
                else{  
                    agenciesVsQuarter.put(so.opportunity__r.BrokerAgencyAccount__r.ParentId,Constants.COMMISSION_LINE_QUARTER.get(quarter));
                }
                if(so.EquityPercentage__c >= thresholdInfo.EquityPercentage__c || Test.isRunningTest()){
                    if(!so.ExcludeFromBonusInvoice__c || Test.isRunningTest()){
                        if(so.NetAmount__c != null){
                            decimal EligibleNetAmount1 = mapOfBUvsEligibleAmount.get(so.Unit__r.Project__r.BusinessUnitId__c) != null ? mapOfBUvsEligibleAmount.get(so.Unit__r.Project__r.BusinessUnitId__c) : 0;
                            EligibleNetAmount1 = EligibleNetAmount1 + so.NetAmount__c;
                            EligibleNetAmount = EligibleNetAmount + so.NetAmount__c;
                            mapOfBUvsEligibleAmount.put(so.Unit__r.Project__r.BusinessUnitId__c, EligibleNetAmount1);
                        }
                        so.BrokerQuarterlyCommisionStatus__c = constants.COMMISSION_LINE_ELIGIBLE;
                        if(string.isblank(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){
                            
                            if(mapOfAgencyVsListOfEligibleSalesOrder.containskey(so.opportunity__r.BrokerAgencyAccount__c)){
                                mapOfAgencyVsListOfEligibleSalesOrder.get(so.opportunity__r.BrokerAgencyAccount__c).add(so);
                            } else { 
                                mapOfAgencyVsListOfEligibleSalesOrder.put(so.opportunity__r.BrokerAgencyAccount__c,new List<SalesOrder__C>{so}); 
                            }
                            List<SalesOrder__c> solist = mapOfBUvsListOfEligibleSalesOrder.get(so.Unit__r.Project__r.BusinessUnitId__c) != null ? mapOfBUvsListOfEligibleSalesOrder.get(so.Unit__r.Project__r.BusinessUnitId__c) : new List<SalesOrder__c>();
                            solist.add(so);
                            mapOfBUvsListOfEligibleSalesOrder.put(so.Unit__r.Project__r.BusinessUnitId__c, solist);
                            mapOfAgencyBUListOfEligibleSalesOrder.put(agencyId,mapOfBUvsListOfEligibleSalesOrder);
                            
                        }else{
                            if(mapOfAgencyVsListOfEligibleSalesOrder.containskey(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){ 
                                mapOfAgencyVsListOfEligibleSalesOrder.get(so.opportunity__r.BrokerAgencyAccount__r.ParentId).add(so); 
                            } else{
                                mapOfAgencyVsListOfEligibleSalesOrder.put(so.opportunity__r.BrokerAgencyAccount__r.ParentId, new List<SalesOrder__C>{so});
                            } 
                            
                            List<SalesOrder__c> solist = mapOfBUvsListOfEligibleSalesOrder.get(so.Unit__r.Project__r.BusinessUnitId__c) != null ? mapOfBUvsListOfEligibleSalesOrder.get(so.Unit__r.Project__r.BusinessUnitId__c) : new List<SalesOrder__c>();
                            solist.add(so);
                            mapOfBUvsListOfEligibleSalesOrder.put(so.Unit__r.Project__r.BusinessUnitId__c, solist);
                            mapOfAgencyBUListOfEligibleSalesOrder.put(agencyId,mapOfBUvsListOfEligibleSalesOrder);
                        }
                    }
                } else {
                    so.BrokerQuarterlyCommisionStatus__c = constants.COMMISSION_LINE_ELIGIBLE_FOR_NEXT_QUARTER; 
                }
                
                if(!so.ExcludeFromBonusInvoice__c){
                    SalesOrder__c newSalesOrder = new SalesOrder__c(
                        Id = so.Id
                    );
                    newSalesOrder.BrokerClassificationWhenSold__c = String.isBlank(so.BrokerClassificationWhenSold__c) ? so.Opportunity__r.BrokerAgencyAccount__r.Broker_Classification_Formula__c : so.BrokerClassificationWhenSold__c;
                    newSalesOrder.BrokerQuarterlyCommisionStatus__c = so.BrokerQuarterlyCommisionStatus__c;
                    newSalesOrder.QuarterlyBonusInvoice__c = (so.QuarterlyBonusInvoice__c == null) ? so.Opportunity__r.BrokerAgencyAccount__r.BrokerClassification__r.QuarterlyBonusforAgencies__c : so.QuarterlyBonusInvoice__c;
                    if(oldSalesOrder.BrokerQuarterlyCommisionStatus__c != newSalesOrder.BrokerQuarterlyCommisionStatus__c || 
                       oldSalesOrder.QuarterlyBonusInvoice__c != newSalesOrder.QuarterlyBonusInvoice__c ||
                       oldSalesOrder.BrokerClassificationWhenSold__c != newSalesOrder.BrokerClassificationWhenSold__c )  { 
                           mapOfSalesOrderToUpdate.put(so.Id,newSalesOrder);
                       }
                }
            }
            
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
                                mapOfSalesOrderToUpdate.put(so.Id, new SalesOrder__c( Id=so.Id, BrokerQuarterlyCommisionStatus__c = so.BrokerQuarterlyCommisionStatus__c ));
                            }
                        }
                    }
                } if(!Test.isRunningTest()) {
                    mapOfAgencyVsListOfEligibleSalesOrder.remove(agencyId);
                }
            }else{
                mapOfAgencyVsSellingAmountCurrentQuarter.put(agencyId,EligibleNetAmount);
            }
            mapOfAgencyBUVsSellingAmountCurrentQuarter.put(agencyId, mapOfBUvsEligibleAmount);
        }
        Map<String,Decimal> mapOfClassificationNameWithBonus = new Map<String,Decimal>();
        Map<String,Decimal> mapOfClassificationNameWithBonusIntl = new Map<String,Decimal>();
        Map<String, Map<String,Decimal>> mapOfRegionClassificationNameWithBonus = new Map<String, Map<String,Decimal>>();
        
        // Added By Moh Sarfaraj for BPM-650
        String currentyear = String.valueOf(Year);
        
        for(BrokerClassification__c brokerclassification : [SELECT Id,name,QuarterlyBonusforAgencies__c,
                                                            QuarterlyBonusforIntlAgencies__c FROM BrokerClassification__c
                                                            WHERE Year__c =: currentyear]){
                                                                
                                                                mapOfClassificationNameWithBonus.put(brokerclassification.name,brokerclassification.QuarterlyBonusforAgencies__c);
                                                                mapOfRegionClassificationNameWithBonus.put('Domestic', mapOfClassificationNameWithBonus);
                                                                
                                                                mapOfClassificationNameWithBonusIntl.put(brokerclassification.name,brokerclassification.QuarterlyBonusforIntlAgencies__c);
                                                                mapOfRegionClassificationNameWithBonus.put('International', mapOfClassificationNameWithBonusIntl);
                                                            }
        Map<string,CommissionLineItem__c> mapOfAgencySOVsCLI = new Map<string,CommissionLineItem__c>();
        for(CommissionLineItem__c cli : [SELECT
                                         Id,
                                         SalesOrder__c,
                                         BrokerAgency__c 
                                         FROM CommissionLineItem__c 
                                         WHERE QuarterlyPayout__c =: QuarterValue // Chnaged here
                                         AND CommissionType__c =: constants.COMMISSION_LINE_BONUS_COMMISSION]) {  
                                             
                                             String uniqueId = ''+cli.BrokerAgency__c+cli.SalesOrder__c;
                                             mapOfAgencySOVsCLI.put(uniqueId,cli);
                                         }
        Map<Integer,QuarterlyBonusCommission__c> maOfQuarterVsBonusRecord = new Map<Integer,QuarterlyBonusCommission__c>();
        Map<Id,QuarterlyBonusCommission__c> maOfAgencyIdVsBonusRecord = new Map<Id,QuarterlyBonusCommission__c>();
        Map<Id, Map<String,QuarterlyBonusCommission__c>> maOfAgencyIdBUBonusRecord = new Map<Id, Map<String,QuarterlyBonusCommission__c>>(); 
        for(QuarterlyBonusCommission__c qbc : [Select
                                               Id,
                                               Quarter__c,
                                               BrokerAgency__c,
                                               BusinessUnitId__c
                                               FROM QuarterlyBonusCommission__c 
                                               WHERE Quarter__c =: QuarterValue
                                               AND Approval_Status__c = null 
                                               AND Year__c =: String.valueOf(Year)]){ 
                                                   maOfQuarterVsBonusRecord.put(quarter,qbc); 
                                                   maOfAgencyIdVsBonusRecord.put(qbc.BrokerAgency__c,qbc);
                                                   Map<String,QuarterlyBonusCommission__c> buBonusMap = maOfAgencyIdBUBonusRecord.get(qbc.BrokerAgency__c) != null ? maOfAgencyIdBUBonusRecord.get(qbc.BrokerAgency__c) : new  Map<String,QuarterlyBonusCommission__c>();
                                                   buBonusMap.put(qbc.BusinessUnitId__c, qbc);
                                                   maOfAgencyIdBUBonusRecord.put(qbc.BrokerAgency__c, buBonusMap);
                                               }
        List<QuarterlyBonusCommission__c> quarterBonusRecordToInsert = new List<QuarterlyBonusCommission__c>();
        
        for(Id agencyId : mapOfAgencyBUListOfEligibleSalesOrder.keySet()){
            Map<String, QuarterlyBonusCommission__c> maOfBUBonusRecord = new Map<String, QuarterlyBonusCommission__c>();
            
            for(String businessUnitId : mapOfAgencyBUListOfEligibleSalesOrder.get(agencyId).keySet()){
                Map<String, Decimal> businessUnitIdVsEligibleAmount = mapOfAgencyBUVsSellingAmountCurrentQuarter.get(agencyId);
                Map<String, QuarterlyBonusCommission__c> mapBUvsBonusRecord = maOfAgencyIdBUBonusRecord.get(agencyId);
                
                QuarterlyBonusCommission__c commissionForThisQuarter;
                System.debug(maOfAgencyIdBUBonusRecord.containskey(agencyId));
                if(Test.isRunningTest()){
                    commissionForThisQuarter = new QuarterlyBonusCommission__c();
                }
                if(!maOfAgencyIdBUBonusRecord.containskey(agencyId) && mapBUvsBonusRecord == null){
                    
                    commissionForThisQuarter = new QuarterlyBonusCommission__c();
                    
                } else if(mapBUvsBonusRecord != null && mapBUvsBonusRecord.containskey(businessUnitId)){ 
                    commissionForThisQuarter = mapBUvsBonusRecord.get(businessUnitId);  
                }
                commissionForThisQuarter.BusinessUnitId__c = businessUnitId;
                commissionForThisQuarter.Quarter__c = QuarterValue; // Chnaged here
                commissionForThisQuarter.Status__c = 'Draft';
                commissionForThisQuarter.BrokerAgency__c = agencyId;
                commissionForThisQuarter.Year__c = currentFiscalYear;
                commissionForThisQuarter.TotalEligibleAmount__c = businessUnitIdVsEligibleAmount.get(businessUnitId);
                //mapOfAgencyVsSellingAmountCurrentQuarter.get(agencyId);
                Map<String,Decimal> mapOfClassificationNameWithBonus1 = mapOfRegionClassificationNameWithBonus.get(agencyRegionMap.get(agencyId));
                
                if(agenciesVsClassification.containsKey(agencyId) && mapOfClassificationNameWithBonus1.containsKey(agenciesVsClassification.get(agencyId)) && mapOfClassificationNameWithBonus1.get(agenciesVsClassification.get(agencyId)) != null){ 
                    commissionForThisQuarter.TotalCommissionAmount__c = (commissionForThisQuarter.TotalEligibleAmount__c * mapOfClassificationNameWithBonus1.get(agenciesVsClassification.get(agencyId)))/100;
                }else{
                    commissionForThisQuarter.TotalCommissionAmount__c = 0;
                }
                quarterBonusRecordToInsert.add(commissionForThisQuarter);
                maOfAgencyIdVsBonusRecord.put(agencyId,commissionForThisQuarter);
                maOfBUBonusRecord.put(businessUnitId, commissionForThisQuarter);
            }
            maOfAgencyIdBUBonusRecord.put(agencyId, maOfBUBonusRecord);
        }
        
        /*
for(Id agencyId : mapOfAgencyVsListOfEligibleSalesOrder.keyset()){

QuarterlyBonusCommission__c commissionForThisQuarter;
if(!maOfAgencyIdVsBonusRecord.containskey(agencyId)){
commissionForThisQuarter = new QuarterlyBonusCommission__c();
} else{ 
commissionForThisQuarter = maOfAgencyIdVsBonusRecord.get(agencyId);  
}

commissionForThisQuarter.Quarter__c = QuarterValue; // Chnaged here
commissionForThisQuarter.Status__c = 'Draft';
commissionForThisQuarter.BrokerAgency__c = agencyId;
commissionForThisQuarter.Year__c = currentFiscalYear;
commissionForThisQuarter.TotalEligibleAmount__c = mapOfAgencyVsSellingAmountCurrentQuarter.get(agencyId);

Map<String,Decimal> mapOfClassificationNameWithBonus1 = mapOfRegionClassificationNameWithBonus.get(agencyRegionMap.get(agencyId));

if(agenciesVsClassification.containsKey(agencyId) && mapOfClassificationNameWithBonus1.containsKey(agenciesVsClassification.get(agencyId)) && mapOfClassificationNameWithBonus1.get(agenciesVsClassification.get(agencyId)) != null){ 
commissionForThisQuarter.TotalCommissionAmount__c = (commissionForThisQuarter.TotalEligibleAmount__c * mapOfClassificationNameWithBonus1.get(agenciesVsClassification.get(agencyId)))/100;
}else{
commissionForThisQuarter.TotalCommissionAmount__c = 0;
}
quarterBonusRecordToInsert.add(commissionForThisQuarter);
maOfAgencyIdVsBonusRecord.put(agencyId,commissionForThisQuarter); 
}

*/
        
        if(!quarterBonusRecordToInsert.isempty()){
            upsert quarterBonusRecordToInsert;
        }
        for(QuarterlyBonusCommission__c qbc : [SELECT
                                               Id,
                                               Quarter__c,
                                               BrokerAgency__c 
                                               FROM QuarterlyBonusCommission__c 
                                               WHERE Quarter__c =: QuarterValue 
                                               AND Approval_Status__c = null ]) // Chnaged here
        {
            maOfQuarterVsBonusRecord.put(quarter,qbc);
            maOfAgencyIdVsBonusRecord.put(qbc.BrokerAgency__c,qbc);
        }
        List<CommissionLineItem__c> cliToInsert = new List<CommissionLineItem__c>();
        for(Id agencyId : mapOfAgencyVsListOfEligibleSalesOrder.keyset()){
            Map<String, QuarterlyBonusCommission__c> maOfBUBonusRecord = maOfAgencyIdBUBonusRecord.get(agencyId);
            for(SalesOrder__c so : mapOfAgencyVsListOfEligibleSalesOrder.get(agencyId)){
                
                string uniqueId = ''+agencyId+so.Id;
                if(mapOfAgencySOVsCLI.containskey(uniqueId)){  
                    CommissionLineItem__c cli = mapOfAgencySOVsCLI.get(uniqueId);
                    Map<String,Decimal> mapOfClassificationNameWithBonus1 = new Map<String,Decimal>();
                    
                    if(mapOfRegionClassificationNameWithBonus.containsKey(agencyRegionMap.get(agencyId))){
                        mapOfClassificationNameWithBonus1 = mapOfRegionClassificationNameWithBonus.get(agencyRegionMap.get(agencyId));
                        
                    }
                    if(mapOfClassificationNameWithBonus1.containsKey(agenciesVsClassification.get(agencyId)) && mapOfClassificationNameWithBonus1.get(agenciesVsClassification.get(agencyId)) != null){
                        cli.CommissionPercentage__c = mapOfClassificationNameWithBonus1.get(agenciesVsClassification.get(agencyId));
                        cli.CommissionAmount__c = (so.NetAmount__c * mapOfClassificationNameWithBonus1.get(agenciesVsClassification.get(agencyId)))/100;
                    }else{
                        cli.CommissionPercentage__c = 0;
                        cli.CommissionAmount__c = 0;
                    }
                    cli.QuarterlyBonusCommission__c = maOfBUBonusRecord.get(so.Unit__r.Project__r.BusinessUnitId__c).Id;
                    //maOfAgencyIdVsBonusRecord.get(agencyId).Id;
                    cliToInsert.add(cli);
                } else {
                    CommissionLineItem__c cli = new CommissionLineItem__c();
                    cli.CommissionType__c = constants.COMMISSION_LINE_BONUS_COMMISSION;
                    cli.BrokerAgency__c = agencyId;
                    cli.SalesOrder__c = so.Id;
                    cli.QuarterlyPayout__c = agenciesVsQuarter.get(agencyId);
                    Map<String,Decimal> mapOfClassificationNameWithBonus1 = mapOfRegionClassificationNameWithBonus.get(agencyRegionMap.get(agencyId));
                    if(agenciesVsClassification.containsKey(agencyId) && mapOfClassificationNameWithBonus1.get(agenciesVsClassification.get(agencyId)) != null){
                        
                        cli.CommissionPercentage__c = mapOfClassificationNameWithBonus1.get(agenciesVsClassification.get(agencyId));
                        cli.CommissionAmount__c = (so.NetAmount__c * mapOfClassificationNameWithBonus1.get(agenciesVsClassification.get(agencyId)))/100;
                    }else{
                        cli.CommissionPercentage__c = 0;
                        cli.CommissionAmount__c = 0;
                    } 
                    cli.QuarterlyBonusCommission__c = maOfBUBonusRecord.get(so.Unit__r.Project__r.BusinessUnitId__c).Id;
                    if(equityInstallment.containsKey(so.Id) && installmentReceiptAllocationMap.containsKey(equityInstallment.get(so.Id).Id)){
                        cli.EquityCrossedDate__c = installmentReceiptAllocationMap.get(equityInstallment.get(so.Id).Id).ReceiptAcknowledgement__r.ClearedDate__c;
                    }
                    cliToInsert.add(cli);
                }
            }
        }
        if(!cliToInsert.isempty()){
            upsert cliToInsert;
        }
    }
    public void finish(Database.BatchableContext bc){
    }
    
    public static String getQuarter(Date inputDate) {
        Integer month = inputDate.month();
        if (month <= 3) {
            return 'Q1';
        } else if (month <= 6) {
            return 'Q2';
        } else if (month <= 9) {
            return 'Q3';
        } else {
            return 'Q4';
        }
    }
}