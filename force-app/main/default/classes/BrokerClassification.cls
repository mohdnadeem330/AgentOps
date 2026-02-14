/**********************************************************************************************************************
* Name                  : BrokerClassification                                                        
* Description           : This Apex class will be running everyday and update the broker classifications
* Created By            : 
* Last Modified By      : tdontha@aldar.com     - Tharun    (ASF-1535)
                          msarfaraj@aldar.com   - Sarfaraj  (BPE-194)
* Last Modified Date    : 18 Mar 2024
******************************************************************************************************************/
global class BrokerClassification implements Database.Batchable<sObject>, Database.Stateful,Schedulable {
    public List<BrokerClassification__c> brokerClassificationList;
    
    public static Map<Integer, String> monthToFieldAPI = new Map<Integer, String>{1 => 'BrokerClassificationInJan__c', 2 => 'BrokerClassificationInFeb__c', 3 => 'BrokerClassificationInMar__c', 
                                                                                  4 => 'BrokerClassificationInApr__c', 5 => 'BrokerClassificationInMay__c', 6 => 'BrokerClassificationInJun__c', 
                                                                                  7 => 'BrokerClassificationInJul__c',8 => 'BrokerClassificationInAug__c', 9 => 'BrokerClassificationInSep__c',
                                                                                  10 => 'BrokerClassificationInOct__c',11 => 'BrokerClassificationInNov__c',12 => 'BrokerClassificationInDec__c'};
    global void execute(SchedulableContext ctx) {
        database.executeBatch(new BrokerClassification(), 50);
    }
    
    global List<Account> start(Database.BatchableContext BC) {
        String currentyear = String.valueOf(System.Today().year()); 
        
        brokerClassificationList                        = [SELECT
                                                           Id,
                                                           AnnualSalesTargetFrom__c,
                                                           AnnualSalesTargetTo__c,
                                                           AnnualSalesTargetFromInternational__c,
                                                           AnnualSalesTargetToInternational__c,
                                                           Name
                                                           FROM BrokerClassification__c WHERE Year__c = :currentyear
                                                           ORDER BY AnnualSalesTargetFrom__c];

        Id brokerRecordTypeId                           = Schema.SObjectType.Account
                                                            .getRecordTypeInfosByDeveloperName()
                                                            .get('Broker_Agency')
                                                            .getRecordTypeId();

        List<Account> accListToBeReturned               = [SELECT
                                                           Id,
                                                           BrokerClassification__c,
                                                           ParentId,
                                                           AgencyRegion__c,
                                                           Parent.BrokerClassification__c
                                                           FROM Account
                                                           WHERE RecordTypeId = :brokerRecordTypeId
                                                           // AND Id IN ('0018d00000Em1SVAAZ','0018d00000Em1CyAAJ','0018d00000G3s4IAAR','0018d00000Em1DiAAJ','0018d00000LloAkAAJ')
                                                           ORDER BY ParentId DESC];
        return accListToBeReturned;
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accList) {
        // Added by Tharun - ASF-1535
        String AGENCYSTATUS_DOMESTIC            =   'Domestic';
        String AGENCYSTATUS_INTERNATIONAL       =   'International';

        // Added by Tharun - ASF-1535
        Map<Id,Account> accMap = new Map<Id,Account>(accList);
        Map<Id,Set<Id>> childAccByParentAcc = new Map<Id,Set<Id>>();
        Map<Id, Integer> storesalesordercount = new Map<Id, Integer>();

        Map<Id, Integer> totalSalesOrderCountInCurrentMonth = new Map<Id, Integer>();
        Map<Id, Decimal> totalSalesAmountInCurrentMonth = new Map<Id, Decimal>();

        List<Broker_Classification_Details__c> insertbcsdetails=new List<Broker_Classification_Details__c>();
        Set<Id> accountsToQuery = new Set<Id>();
        accountsToQuery.addAll(accMap.keySet());

        for(Account acc : [SELECT Id,ParentId FROM Account WHERE ParentId IN: accMap.keySet() ORDER BY ParentId ]){
            if(childAccByParentAcc.containsKey(acc.ParentId)){
                childAccByParentAcc.get(acc.ParentId).add(acc.Id);
            }else{
                childAccByParentAcc.put(acc.ParentId, new Set<Id>{acc.Id});
            }
            accountsToQuery.add(acc.Id);
        }
        List<Account> accountsToUpdate;
        accountsToUpdate = new List<Account>();
        system.debug('brokerClassificationList '+brokerClassificationList);
        system.debug('accMap '+accMap);
        Map<Id,Decimal> totalSalesByAccount;
        totalSalesByAccount = new Map<Id,Decimal>();

        // Added By Moh Sarfaraj for BRP-5822 
        Map<Id,AgencySalesInfo> mapAgencyIdToSalesInfo = new Map<Id,AgencySalesInfo>();

        for(AggregateResult ar : [SELECT Opportunity__r.BrokerAgencyAccount__c agencyAccount,SUM(NetAmount__c) netAmt,COUNT(Id) recordCount 
                                  FROM SalesOrder__c 
                                  WHERE Opportunity__r.BrokerAgencyAccount__c  IN: accountsToQuery
                                  AND BookingDate__c = THIS_YEAR
                                  AND Status__c = 'Sold'
                                  GROUP BY Opportunity__r.BrokerAgencyAccount__c ]){

            Double brokerSales = (double) ar.get('netAmt');
            Integer countOfIds = (Integer) ar.get('recordCount');

            // Added By Moh Sarfaraj for BRP-5822 
            AgencySalesInfo salesInfo = new AgencySalesInfo();
            salesInfo.totalNumberOfSales = (countOfIds != null || countOfIds != 0) ? countOfIds : 0;
            salesInfo.totalSalesAmount = (brokerSales != null || brokerSales != 0) ? brokerSales : 0;
            mapAgencyIdToSalesInfo.put((Id) ar.get('agencyAccount'), salesInfo);

            system.debug('AR '+ar);
            if(brokerSales != null){
                for(BrokerClassification__c brokerClass : brokerClassificationList){
                    if(brokerClass.AnnualSalesTargetFrom__c <= brokerSales && brokerClass.AnnualSalesTargetTo__c > brokerSales){
                        totalSalesByAccount.put((Id)ar.get('agencyAccount'),brokerSales);
                        storesalesordercount.put((Id)ar.get('agencyAccount'), countOfIds);
                    }
                }
            }else{
                totalSalesByAccount.put((Id)ar.get('agencyAccount'),brokerSales);
                system.debug('STANDARD CLASSIFICATION');
            }
        }

        // Added By Moh Sarfaraj for BPM-651 starts
        for(AggregateResult ar : [SELECT Opportunity__r.BrokerAgencyAccount__c agencyAccount, SUM(NetAmount__c) netAmt, COUNT(Id) recordCount 
                                  FROM SalesOrder__c 
                                  WHERE Opportunity__r.BrokerAgencyAccount__c IN: accountsToQuery
                                  AND BookingDate__c = THIS_YEAR 
                                  AND SoldDate__c = THIS_MONTH          
                                  AND Status__c = 'Sold'
                                  GROUP BY Opportunity__r.BrokerAgencyAccount__c]){

            Double brokerSales = (double) ar.get('netAmt');
            Integer countOfIds = (Integer) ar.get('recordCount');

            if(countOfIds != null){
                totalSalesOrderCountInCurrentMonth.put((Id) ar.get('agencyAccount'), countOfIds);
            }
            if(brokerSales != null){
                totalSalesAmountInCurrentMonth.put((Id) ar.get('agencyAccount'), brokerSales);
            }
        }
        // Added By Moh Sarfaraj for BPM-651 end

        system.debug('totalSalesByAccount '+totalSalesByAccount);
        // List<Account> accListToUpdate = new List<Account>();
        Map<Id,Account> totalSalesByAccountFinal =  new Map<Id,Account>(); 
        for(Account acc : accMap.values() ){
            Decimal totalSalesForAccount = 0;
            if(totalSalesByAccount.containsKey(acc.Id) && totalSalesByAccount.get(acc.Id) != null){
                totalSalesForAccount =  totalSalesForAccount +  totalSalesByAccount.get(acc.Id);
                system.debug('ADDING '+totalSalesForAccount);
            }
            // Commented By Moh Sarfaraj for BPE-194 on 18 March 24
            // if(childAccByParentAcc.containsKey(acc.Id)){
            //     system.debug('totalSalesByAccount.get(acc.Id) '+totalSalesByAccount.get(acc.Id));
            //     for(Id childAcc : childAccByParentAcc.get(acc.Id)){
            //         if(totalSalesByAccount.containsKey(childAcc) && totalSalesByAccount.get(childAcc) != null){
            //             // totalSalesForAccount = totalSalesForAccount + totalSalesByAccount.get(childAcc);
            //             // system.debug('totalSalesForAccount '+totalSalesForAccount);
            //             // system.debug('SUMMING UP CHILD RECORDS '+childAcc);
            //         }
            //     }
            // }
            for(BrokerClassification__c brokerClass : brokerClassificationList){
                //BPM-252 - field is popuating with Broker classification name for Marketing Reimbersemnt calculations
                acc.put(monthToFieldAPI.get(System.Today().month()),brokerClass.Name);
                // Added by Tharun - ASF-1535
                if(acc.AgencyRegion__c == AGENCYSTATUS_DOMESTIC){
                    if(brokerClass.AnnualSalesTargetFrom__c <= totalSalesForAccount && brokerClass.AnnualSalesTargetTo__c > totalSalesForAccount){
                        acc.BrokerClassification__c=brokerClass.Id;
                        break;
                    }
                }else if(acc.AgencyRegion__c == AGENCYSTATUS_INTERNATIONAL){
                    if(brokerClass.AnnualSalesTargetFromInternational__c <= totalSalesForAccount && brokerClass.AnnualSalesTargetToInternational__c > totalSalesForAccount){
                        acc.BrokerClassification__c=brokerClass.Id;
                        break;
                    }
                }
                // Added by Tharun - ASF-1535
            }
            acc.ClassificationSalesAmount__c = totalSalesForAccount;
            totalSalesByAccountFinal.put(acc.Id,acc);
            //   accMap.get(acc.Id).ClassificationSalesAmount__c =totalSalesForAccount;
            system.debug('---------------------- Account '+ acc.Id);
            system.debug('------- totalSalesForAccount '+ totalSalesForAccount);
            system.debug('-----BrokerClassification__c '+ accMap.get(acc.Id).BrokerClassification__c);
            // accListToUpdate.add(acc);
        }
        // Commented By Moh Sarfaraj for BPE-194 on 18 March 24
        // Updating broker classification of child same as parent. Added By Muzammil on 3rd Oct 2022
        // for(Account acc : accMap.values() ){
        //     if(acc.ParentId != null){
        //         if(totalSalesByAccountFinal.containsKey(acc.ParentId)){
        //             system.debug('UPDATING CHILD --- '+acc);
        //             if(totalSalesByAccountFinal.get(acc.ParentId).BrokerClassification__c != null){
        //                 acc.BrokerClassification__c = totalSalesByAccountFinal.get(acc.ParentId).BrokerClassification__c;
        //                 system.debug('totalSalesByAccountFinal.get(acc.ParentId) '+totalSalesByAccountFinal.get(acc.ParentId));
        //                 system.debug('UPDATed CHILD --- '+acc);
        //             }
        //         }else{
        //             system.debug('UPDATING FROM PARENT '+acc);
        //             acc.BrokerClassification__c = acc.Parent.BrokerClassification__c;
        //         }
        //     }
        // }
        
        for(Account acc : accMap.values() ){
            if(acc.BrokerClassification__c == null){
                acc.BrokerClassification__c=brokerClassificationList[0].Id;
                system.debug('STANDARD CLASSIFICATION IN LOOP');
            }
        }
        
        system.debug('accMap '+accMap);
        //   Database.SaveResult [] updateResult = Database.update(records, false);
        //Flag - Added By Ajay
        AccountTriggerHandler.skipAccountTrigger = true;
        Database.SaveResult [] updateResult = database.update(accMap.values(),false);
        for(Integer i=0;i<updateResult.size();i++){
            Database.SaveResult r = updateResult[i];
            if (!r.isSuccess()){
                for (Database.Error e : r.getErrors()){LoggerService.Save( LoggerService.createApexLog(e, 'Broker Classification - '+accMap.values()[i].Id, 'BrokerClassification', 'execute'));
                    system.debug('e.getMessage() '+e.getMessage());  
                } 
            }
        }

        Date today = Date.today();
        Date lastDayOfMonth = today.toStartOfMonth().addMonths(1).addDays(-1);
        List<Broker_Classification_Details__c> insertOrUpdateBCDetails = new List<Broker_Classification_Details__c>();

        String currentYear = String.valueOf(today.year());
        Decimal currentMonth = today.month(); 

    
        Set<Id> agencyIds = accMap.keySet();
        List<Broker_Classification_Details__c> existingRecords = [
            SELECT Id, Year__c, Month__c, AgencyName__c
            FROM Broker_Classification_Details__c
            WHERE Year__c = :currentYear AND Month__c = :currentMonth AND AgencyName__c IN :agencyIds
        ];

        Map<Id, Broker_Classification_Details__c> existingRecordsMap = new Map<Id, Broker_Classification_Details__c>();
        for (Broker_Classification_Details__c record : existingRecords) {
            existingRecordsMap.put(record.AgencyName__c, record);
        }

        for (Account accNewValues : accMap.values()) {
            Broker_Classification_Details__c bcDetails;
            
            if (existingRecordsMap.containsKey(accNewValues.Id)) {
                bcDetails = existingRecordsMap.get(accNewValues.Id);  
            } else {
                bcDetails = new Broker_Classification_Details__c();  
                bcDetails.Year__c = currentYear;
                bcDetails.Month__c = currentMonth;
                bcDetails.AgencyName__c = accNewValues.Id;
            }
            
            bcDetails.Classification__c = accNewValues.BrokerClassification__c;
            // Added By Moh Sarfaraj for BPM-651 starts
            bcDetails.Total_number_of_Sales_in_month__c = totalSalesOrderCountInCurrentMonth.get(accNewValues.Id); 
            bcDetails.Net_amount__c = totalSalesAmountInCurrentMonth.get(accNewValues.Id);
            // Added By Moh Sarfaraj for BPM-651 end

            // Added By Moh Sarfaraj for BRP-5822
            if(mapAgencyIdToSalesInfo.containsKey(accNewValues.Id)){
                bcDetails.TotalNumberofSales__c = mapAgencyIdToSalesInfo.get(accNewValues.Id).totalNumberOfSales;
                bcDetails.TotalSalesAmount__c =  mapAgencyIdToSalesInfo.get(accNewValues.Id).totalSalesAmount;
            }

            insertOrUpdateBCDetails.add(bcDetails);
            System.debug('Prepared Broker Classification Detail: ' + bcDetails);
        }

        if (!insertOrUpdateBCDetails.isEmpty()) {
            upsert insertOrUpdateBCDetails;
            System.debug('Successfully processed ' + insertOrUpdateBCDetails.size() + ' Broker Classification Details.');
        } else {
            System.debug('No records to process.');
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations
    }

    public class AgencySalesInfo{
        public Integer totalNumberOfSales;
        public Double totalSalesAmount;
    }
}