public class ALD_QuarterlyBonusGenerator {

    public static void quarterlyBonusManual(){
        
        Id brokerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Broker_Agency')
            .getRecordTypeId();
       
        List<Id> brokerAgencyAccountIds; 
        
        if(!Test.isRunningTest()){
            brokerAgencyAccountIds = new List<Id>{'0018d00000Em1D0AAJ','0018d00000Em1DxAAJ','0018d00000Em1DBAAZ','0018d00000Em1cUAAR','0018d00000Em1MLAAZ',
            '0018d00000Em1RaAAJ','0018d00000Em1DLAAZ','0018d00000Em1DPAAZ','0018d00000kltpjAAA','0018d00000Em1DGAAZ',
            '0018d00000Em1CyAAJ','0018d00000Em1SLAAZ','0018d00000Em1i4AAB','0018d00000jn0fyAAA','0018d00000VClSmAAL',
            '0018d00000Em1ENAAZ','0018d00000Em1FPAAZ','0018d00000Em1e5AAB','0018d00000Em1DRAAZ','0018d00000Em1EuAAJ',
            '0018d00000Em1FhAAJ','0018d00000G3s4IAAR','0018d00000Em1d5AAB','0018d00000Em1DyAAJ','0018d00000Em1FYAAZ',
            '0018d00000Em1DiAAJ','0018d00000TeNONAA3','0018d00000Em1DqAAJ','0018d00000Em1D7AAJ','0018d00000Em1emAAB',
            '0018d00000Em1cMAAR','0018d00000Em1c1AAB','0018d00000Em1d3AAB','0018d00000Qp1AwAAJ','0018d00000Em1QHAAZ',
            '0018d00000LloAkAAJ','0018d00000Em1exAAB','0018d00000Em1hyAAB','0018d00000RtUyWAAV','0018d00000Em1YmAAJ',
            '0018d00000Em1CzAAJ','0018d00000Em1JdAAJ','0018d00000Em1YGAAZ','0018d00000Em1ikAAB','0018d00000Em1ilAAB',
            '0018d00000Em1RYAAZ','0018d00000Em1ifAAB','0018d00000Em1DNAAZ','0018d00000VBqUeAAL','0018d00000Em1L7AAJ',
            '0018d00000eWbqOAAS','0018d00000Em1EMAAZ','0018d00000GoKJJAA3','0018d00000Em1G7AAJ','0018d00000G6N9fAAF',
            '0018d00000UnpUyAAJ','0018d00000Em1SYAAZ','0018d00000HLJzlAAH','0018d00000IfUyZAAV', // SR 60
            '0018d00000Em1E1AAJ','0018d00000PAydDAAT','0018d00000PkTK6AAN','0018d00000Em1EIAAZ','0018d00000Em1iGAAR',
            '0018d00000XVnkcAAD','0018d00000NGbWxAAL','0018d00000Em1crAAB','0018d00000HioMKAAZ','0018d00000Em1PlAAJ',
            '0018d00000Em1JxAAJ','0018d00000Em1JeAAJ','0018d00000Em1DrAAJ','0018d00000KTXxzAAH','0018d00000KV432AAD',
            '0018d00000Em1E3AAJ','0018d00000Sot1iAAB','0018d00000Em1KIAAZ', '0018d00000eVcALAA0', // SR 79
            '0018d00000Em1SfAAJ','0018d00000Em1hPAAR','0018d00000Em1iAAAR','0018d00000Em1KCAAZ','0018d00000W0stnAAB',
            '0018d00000dijDeAAI','0018d00000cQNO3AAO'} ;
                    }else {
                        List<account> accountList = [select id from account where recordTypeId=: brokerRecordTypeId];
                        System.debug('accountList::'+accountList);
                        If(accountList.Size()>0){
                            brokerAgencyAccountIds = new List<Id>{accountList[0].Id}; 
                        }
                    } 
        
        Map<Id,List<SalesOrder__c>> mapOfAccountWithItsSalesOrder = new Map<Id,List<SalesOrder__c>>();
        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
        If(!Test.isRunningTest()){
         salesOrderList = [select id, Account__c, NetAmount__c, EquityPercentage__c, BookingDate__c,
                                              Unit__r.BuildingSectionName__r.LaunchStartDate__c, QuarterlyBonusInvoice__c,
                                              opportunity__r.BrokerAgencyAccount__c, opportunity__r.BrokerAgencyAccount__r.ParentId,
                                              Opportunity__r.BrokerAgencyAccount__r.BrokerClassification__r.QuarterlyBonusforAgencies__c,
                                              Opportunity__r.BrokerAgencyAccount__r.Broker_Classification_Formula__c,
                                              BrokerQuarterlyCommisionStatus__c, ExcludeFromBonusInvoice__c, EligibleForBonusPayout__c,
                                              BrokerClassificationWhenSold__c	
                                              from SalesOrder__c where Status__c = 'Sold' and
                                              EligibleForBonusPayout__c = true and
                                              CALENDAR_YEAR( SoldDate__c) = 2023  and
                                              // Chnaged here
                                              ((CALENDAR_QUARTER(SoldDate__c)  = 3 and opportunity__r.BrokerAgencyAccount__c in: brokerAgencyAccountIds)
                                               or (CALENDAR_QUARTER(SoldDate__c)  != 2 
                                                   and CALENDAR_QUARTER(SoldDate__c)  != 3 
                                                   and BrokerQuarterlyCommisionStatus__c = 'Eligible For Next Quarter')
                                              )];
        
        }else{
           salesOrderList = [select id, Account__c, NetAmount__c, EquityPercentage__c, BookingDate__c,SoldDate__c,
                                                  Unit__r.BuildingSectionName__r.LaunchStartDate__c, QuarterlyBonusInvoice__c,
                                                  opportunity__r.BrokerAgencyAccount__c, opportunity__r.BrokerAgencyAccount__r.ParentId,
                                                  Opportunity__r.BrokerAgencyAccount__r.BrokerClassification__r.QuarterlyBonusforAgencies__c,
                                                  Opportunity__r.BrokerAgencyAccount__r.Broker_Classification_Formula__c,
                                                  BrokerQuarterlyCommisionStatus__c, ExcludeFromBonusInvoice__c, EligibleForBonusPayout__c,
                                                  BrokerClassificationWhenSold__c	
                                                  from SalesOrder__c where Status__c = 'Sold' ];            
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
        BrokerCommissionSetting__mdt thresholdInfo = BrokerCommissionSetting__mdt.getInstance(constants.COMMISSION_LINE_QUARTER_PAYOUT); 
        Integer quarter = [Select Number From Period Where type = 'Quarter' and CALENDAR_QUARTER(StartDate) = 3 LIMIT 1].Number; // Chnaged here
        String currentFiscalYear = [SELECT FiscalYearSettings.Name FROM Period WHERE CALENDAR_QUARTER(StartDate) = 3 limit 1].FiscalYearSettings.Name; // Chnaged here
        Map<Id,Account> agenciesToUpdate = new Map<Id,Account>();
        Map<Id,String> agenciesVsClassification = new Map<Id,String>();
        Map<Id,String> agenciesVsQuarter = new Map<Id,String>();
        Map<Id,SalesOrder__c> mapOfSalesOrderToUpdate = new Map<Id,SalesOrder__c>();
        Map<Id, Decimal> mapOfAgencyVsSellingAmountCurrentQuarter = new Map<Id,Decimal>();
        Map<Id, List<SalesOrder__c>> mapOfAgencyVsListOfEligibleSalesOrder = new Map<Id,List<SalesOrder__c>>();   
        
        agenciesVsClassification.put('0018d00000Em1D0AAJ','Ambassador');
		agenciesVsClassification.put('0018d00000Em1DxAAJ','Ambassador');
		agenciesVsClassification.put('0018d00000Em1DBAAZ','Ambassador');
		
		agenciesVsClassification.put('0018d00000Em1cUAAR','Consul');
		agenciesVsClassification.put('0018d00000Em1MLAAZ','Consul');
		agenciesVsClassification.put('0018d00000Em1RaAAJ','Consul');
		
		
		agenciesVsClassification.put('0018d00000Em1DLAAZ','Attache');
		agenciesVsClassification.put('0018d00000Em1DPAAZ','Attache');
		agenciesVsClassification.put('0018d00000kltpjAAA','Attache');
		agenciesVsClassification.put('0018d00000Em1DGAAZ','Attache');
		agenciesVsClassification.put('0018d00000Em1CyAAJ','Attache');
		agenciesVsClassification.put('0018d00000Em1SLAAZ','Attache');
		agenciesVsClassification.put('0018d00000Em1i4AAB','Attache');
		agenciesVsClassification.put('0018d00000jn0fyAAA','Attache');
		agenciesVsClassification.put('0018d00000VClSmAAL','Attache');
		agenciesVsClassification.put('0018d00000Em1ENAAZ','Attache');
		agenciesVsClassification.put('0018d00000Em1FPAAZ','Attache');
	
		agenciesVsClassification.put('0018d00000Em1e5AAB','Consul'); // need to check for international agency
	
		agenciesVsClassification.put('0018d00000Em1DRAAZ','Attache');
		agenciesVsClassification.put('0018d00000Em1EuAAJ','Attache');
		agenciesVsClassification.put('0018d00000Em1FhAAJ','Attache');
		
		// SR 22 starts
		agenciesVsClassification.put('0018d00000G3s4IAAR','Envoy');
		agenciesVsClassification.put('0018d00000Em1d5AAB','Envoy');
		agenciesVsClassification.put('0018d00000Em1DyAAJ','Envoy');
		agenciesVsClassification.put('0018d00000Em1FYAAZ','Envoy');
		agenciesVsClassification.put('0018d00000Em1DiAAJ','Envoy'); //5
		
		agenciesVsClassification.put('0018d00000TeNONAA3','Envoy');
		agenciesVsClassification.put('0018d00000Em1DqAAJ','Envoy');
		agenciesVsClassification.put('0018d00000Em1D7AAJ','Envoy');
		agenciesVsClassification.put('0018d00000Em1emAAB','Envoy');
		agenciesVsClassification.put('0018d00000Em1cMAAR','Envoy'); // 10
		
		agenciesVsClassification.put('0018d00000Em1c1AAB','Envoy');
		agenciesVsClassification.put('0018d00000Em1d3AAB','Envoy');
		agenciesVsClassification.put('0018d00000Qp1AwAAJ','Envoy');
		agenciesVsClassification.put('0018d00000Em1QHAAZ','Envoy');
		agenciesVsClassification.put('0018d00000LloAkAAJ','Envoy'); // 15
		
		agenciesVsClassification.put('0018d00000Em1exAAB','Envoy');
		agenciesVsClassification.put('0018d00000Em1hyAAB','Envoy');
		agenciesVsClassification.put('0018d00000RtUyWAAV','Envoy');
		agenciesVsClassification.put('0018d00000Em1YmAAJ','Envoy');
		agenciesVsClassification.put('0018d00000Em1CzAAJ','Envoy'); // 20 envoy
		
		agenciesVsClassification.put('0018d00000Em1JdAAJ','Envoy');
		agenciesVsClassification.put('0018d00000Em1YGAAZ','Envoy');
		agenciesVsClassification.put('0018d00000Em1ikAAB','Envoy');
		agenciesVsClassification.put('0018d00000Em1ilAAB','Envoy');
		agenciesVsClassification.put('0018d00000Em1RYAAZ','Envoy');
		
		agenciesVsClassification.put('0018d00000Em1ifAAB','Envoy');
		agenciesVsClassification.put('0018d00000Em1DNAAZ','Envoy');
		agenciesVsClassification.put('0018d00000VBqUeAAL','Envoy');
		agenciesVsClassification.put('0018d00000Em1L7AAJ','Envoy');
		agenciesVsClassification.put('0018d00000eWbqOAAS','Envoy'); // 30
		
		agenciesVsClassification.put('0018d00000Em1EMAAZ','Envoy');
		agenciesVsClassification.put('0018d00000GoKJJAA3','Envoy');
		agenciesVsClassification.put('0018d00000Em1G7AAJ','Envoy');
		agenciesVsClassification.put('0018d00000G6N9fAAF','Envoy');
		agenciesVsClassification.put('0018d00000UnpUyAAJ','Envoy'); // 35
		
		agenciesVsClassification.put('0018d00000Em1SYAAZ','Envoy');
		agenciesVsClassification.put('0018d00000HLJzlAAH','Envoy');
		agenciesVsClassification.put('0018d00000IfUyZAAV','Envoy');
		agenciesVsClassification.put('0018d00000Em1E1AAJ','Envoy');
		agenciesVsClassification.put('0018d00000PAydDAAT','Envoy'); // 40
		
		agenciesVsClassification.put('0018d00000PkTK6AAN','Envoy');
		agenciesVsClassification.put('0018d00000Em1EIAAZ','Envoy');
		agenciesVsClassification.put('0018d00000Em1iGAAR','Envoy');
		agenciesVsClassification.put('0018d00000XVnkcAAD','Envoy');
		agenciesVsClassification.put('0018d00000NGbWxAAL','Envoy'); // 45
		
		agenciesVsClassification.put('0018d00000Em1crAAB','Envoy');
		agenciesVsClassification.put('0018d00000HioMKAAZ','Envoy');
		agenciesVsClassification.put('0018d00000Em1PlAAJ','Envoy');
		agenciesVsClassification.put('0018d00000Em1JxAAJ','Envoy');
		agenciesVsClassification.put('0018d00000Em1JeAAJ','Envoy'); // 50
		
		agenciesVsClassification.put('0018d00000Em1DrAAJ','Envoy');
		agenciesVsClassification.put('0018d00000KTXxzAAH','Envoy');
		agenciesVsClassification.put('0018d00000KV432AAD','Envoy');
		agenciesVsClassification.put('0018d00000Em1E3AAJ','Envoy');
		agenciesVsClassification.put('0018d00000Sot1iAAB','Envoy'); //55
		
		agenciesVsClassification.put('0018d00000Em1KIAAZ','Envoy');
		agenciesVsClassification.put('0018d00000eVcALAA0','Envoy');
		agenciesVsClassification.put('0018d00000Em1SfAAJ','Envoy');
		agenciesVsClassification.put('0018d00000Em1hPAAR','Envoy');
		agenciesVsClassification.put('0018d00000Em1iAAAR','Envoy'); //60
		
		agenciesVsClassification.put('0018d00000Em1KCAAZ','Envoy');
		agenciesVsClassification.put('0018d00000Em1iCAAR','Envoy');
		agenciesVsClassification.put('0018d00000W0stnAAB','Envoy');
		agenciesVsClassification.put('0018d00000dijDeAAI','Envoy');
		agenciesVsClassification.put('0018d00000cQNO3AAO','Envoy'); //65
        
        for(Id agencyId : mapOfAccountWithItsSalesOrder.keyset()){
            Decimal EligibleNetAmount = 0;
            for(SalesOrder__c so: mapOfAccountWithItsSalesOrder.get(agencyId)){
                SalesOrder__c oldSalesOrder = so; 
                if(string.isblank(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){
                    agenciesVsQuarter.put(so.opportunity__r.BrokerAgencyAccount__c,Constants.COMMISSION_LINE_QUARTER.get(quarter));
                }else{                    agenciesVsQuarter.put(so.opportunity__r.BrokerAgencyAccount__r.ParentId,Constants.COMMISSION_LINE_QUARTER.get(quarter));
                }
                if(so.NetAmount__c != null){
                    EligibleNetAmount = EligibleNetAmount + so.NetAmount__c;
                }
                if(so.EquityPercentage__c >= thresholdInfo.EquityPercentage__c){
                    if(!so.ExcludeFromBonusInvoice__c){
                        so.BrokerQuarterlyCommisionStatus__c = constants.COMMISSION_LINE_ELIGIBLE;
                        if(string.isblank(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){
                            if(mapOfAgencyVsListOfEligibleSalesOrder.containskey(so.opportunity__r.BrokerAgencyAccount__c)){                                mapOfAgencyVsListOfEligibleSalesOrder.get(so.opportunity__r.BrokerAgencyAccount__c).add(so);
                            }else{
                                mapOfAgencyVsListOfEligibleSalesOrder.put(so.opportunity__r.BrokerAgencyAccount__c,new List<SalesOrder__C>{so});
                            }
                        }else{
                            if(mapOfAgencyVsListOfEligibleSalesOrder.containskey(so.opportunity__r.BrokerAgencyAccount__r.ParentId)){                                mapOfAgencyVsListOfEligibleSalesOrder.get(so.opportunity__r.BrokerAgencyAccount__r.ParentId).add(so);
                            }else{
                                mapOfAgencyVsListOfEligibleSalesOrder.put(so.opportunity__r.BrokerAgencyAccount__r.ParentId,new List<SalesOrder__C>{so});
                            }
                        }
                    }
                }else{
                    so.BrokerQuarterlyCommisionStatus__c = constants.COMMISSION_LINE_ELIGIBLE_FOR_NEXT_QUARTER;
                }
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
            if(EligibleNetAmount < thresholdInfo.SumOfNetAmountThreshold__c){
                for(SalesOrder__c so: mapOfAccountWithItsSalesOrder.get(agencyId)){
                    if(!so.ExcludeFromBonusInvoice__c){
                        if(mapOfSalesOrderToUpdate.containskey(so.Id)){                            if(mapOfSalesOrderToUpdate.get(so.Id).BrokerQuarterlyCommisionStatus__c != constants.COMMISSION_LINE_NOT_ELIGIBLE){                                mapOfSalesOrderToUpdate.get(so.Id).BrokerQuarterlyCommisionStatus__c = constants.COMMISSION_LINE_NOT_ELIGIBLE;
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
        Map<String,Decimal> mapOfClassificationNameWithBonus = new Map<String,Decimal>();
        for(BrokerClassification__c brokerclassification : [select id,name,QuarterlyBonusforAgencies__c  from BrokerClassification__c]){    mapOfClassificationNameWithBonus.put(brokerclassification.name,brokerclassification.QuarterlyBonusforAgencies__c);
                                                            }
        Map<string,CommissionLineItem__c> mapOfAgencySOVsCLI = new Map<string,CommissionLineItem__c>();
        for(CommissionLineItem__c cli : [Select Id,SalesOrder__c, BrokerAgency__c from CommissionLineItem__c 
                                         where QuarterlyPayout__c ='Q3' // Chnaged here
                                         and CommissionType__c =: constants.COMMISSION_LINE_BONUS_COMMISSION])        {            string uniqueId = ''+cli.BrokerAgency__c+cli.SalesOrder__c;            mapOfAgencySOVsCLI.put(uniqueId,cli);
        }
        Map<Integer,QuarterlyBonusCommission__c> maOfQuarterVsBonusRecord = new Map<Integer,QuarterlyBonusCommission__c>();
        Map<Id,QuarterlyBonusCommission__c> maOfAgencyIdVsBonusRecord = new Map<Id,QuarterlyBonusCommission__c>();
        for(QuarterlyBonusCommission__c qbc : [Select Id, Quarter__c, BrokerAgency__c from QuarterlyBonusCommission__c 
                                               where Quarter__c ='Q3' and Approval_Status__c = null ]){ // Chnaged here
            maOfQuarterVsBonusRecord.put(quarter,qbc);            maOfAgencyIdVsBonusRecord.put(qbc.BrokerAgency__c,qbc);
        }
        List<QuarterlyBonusCommission__c> quarterBonusRecordToInsert = new List<QuarterlyBonusCommission__c>();
        for(Id agencyId : mapOfAgencyVsListOfEligibleSalesOrder.keyset()){
            QuarterlyBonusCommission__c commissionForThisQuarter;
            if(!maOfAgencyIdVsBonusRecord.containskey(agencyId)){
                commissionForThisQuarter = new QuarterlyBonusCommission__c();
            }else{                commissionForThisQuarter = maOfAgencyIdVsBonusRecord.get(agencyId);
            }
            commissionForThisQuarter.Quarter__c = 'Q3'; // Chnaged here
            commissionForThisQuarter.Status__c = constants.COMMISSION_LINE_NOT_READY;
            commissionForThisQuarter.BrokerAgency__c = agencyId;
            commissionForThisQuarter.Year__c = currentFiscalYear;
            commissionForThisQuarter.TotalEligibleAmount__c = mapOfAgencyVsSellingAmountCurrentQuarter.get(agencyId);
            if(mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)) != null){                commissionForThisQuarter.TotalCommissionAmount__c = (commissionForThisQuarter.TotalEligibleAmount__c * mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)))/100;
            }else{
                commissionForThisQuarter.TotalCommissionAmount__c = 0;
            }
            quarterBonusRecordToInsert.add(commissionForThisQuarter);
            maOfAgencyIdVsBonusRecord.put(agencyId,commissionForThisQuarter);
        }
        if(!quarterBonusRecordToInsert.isempty()){
            upsert quarterBonusRecordToInsert;
        }
        for(QuarterlyBonusCommission__c qbc : [Select Id, Quarter__c, BrokerAgency__c from QuarterlyBonusCommission__c 
                                               where Quarter__c ='Q3' and Approval_Status__c = null ]) // Chnaged here
        {
            maOfQuarterVsBonusRecord.put(quarter,qbc);
            maOfAgencyIdVsBonusRecord.put(qbc.BrokerAgency__c,qbc);
        }
        List<CommissionLineItem__c> cliToInsert = new List<CommissionLineItem__c>();
        for(Id agencyId : mapOfAgencyVsListOfEligibleSalesOrder.keyset()){
            for(SalesOrder__c so : mapOfAgencyVsListOfEligibleSalesOrder.get(agencyId)){
                string uniqueId = ''+agencyId+so.Id;
                if(mapOfAgencySOVsCLI.containskey(uniqueId)){  
                    CommissionLineItem__c cli = mapOfAgencySOVsCLI.get(uniqueId);
                    if(mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)) != null){                        cli.CommissionPercentage__c = mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId));                        cli.CommissionAmount__c = (so.NetAmount__c * mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)))/100;
                    }else{
                        cli.CommissionPercentage__c = 0;                        cli.CommissionAmount__c = 0;
                    }
                    cli.QuarterlyBonusCommission__c = maOfAgencyIdVsBonusRecord.get(agencyId).Id;                    cliToInsert.add(cli);
                }else{
                    CommissionLineItem__c cli = new CommissionLineItem__c();
                    cli.CommissionType__c = constants.COMMISSION_LINE_BONUS_COMMISSION;
                    cli.BrokerAgency__c = agencyId;
                    cli.SalesOrder__c = so.Id;
                    cli.QuarterlyPayout__c = agenciesVsQuarter.get(agencyId);
                    if(mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)) != null){
                        cli.CommissionPercentage__c = mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId));                        cli.CommissionAmount__c = (so.NetAmount__c * mapOfClassificationNameWithBonus.get(agenciesVsClassification.get(agencyId)))/100;
                    }else{
                        cli.CommissionPercentage__c = 0;
                        cli.CommissionAmount__c = 0;
                    } cli.QuarterlyBonusCommission__c = maOfAgencyIdVsBonusRecord.get(agencyId).Id;
                    cliToInsert.add(cli);
                }
            }
            
        }
        if(!cliToInsert.isempty()){
            upsert cliToInsert;
        }
    }
}