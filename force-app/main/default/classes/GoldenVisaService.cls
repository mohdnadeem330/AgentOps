/*
*********************************************************
Apex Class Name    : GoldenVisaService
Created Date       : June 27 2025
@description       : This Class is used for Specfic for Golden Visa Service Requests
@author            : 
Modification Log:
Ver   Date         Author                               Modification
1.0   27-06-2025                                        Initial Version
*********************************************************
*/
public with sharing class GoldenVisaService {
    /*
    *********************************************************
    @Method Name    : gvAccountValidation
    @author         : 
    @description    : Method to validate the GoldenVisa Account 
    @param          : moveInRequests, unitMap 
    @return         : void
    ********************************************************
    */
    public static void gvAccountValidation(Map<Id,HexaBPM__Service_Request__c> goldenVisaAccountsIdsWithSR ){
        for (Account accountRec : [Select Id, IsPersonAccount From Account Where Id IN :goldenVisaAccountsIdsWithSR.keySet()]) {
            if(!accountRec.IsPersonAccount){
                (goldenVisaAccountsIdsWithSR.get(accountRec.Id)).addError(ServiceRequestTriggerHelper.getSystemMessagesMap().get(Constants.GOLDEN_VISA_IS_APPLICABLE_FOR_PERSON_ACC).Message__c);
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : updateGoldenVisaDetails
    @author         : 
    @description    : Method to update the GoldenVisa Details
    @param          : moveInRequests, unitMap 
    @return         : void
    ********************************************************
    */
    public static void updateGoldenVisaDetails(List<HexaBPM__Service_Request__c> newList, Set<Id> customerIdSet) {
        List<AggregateResult> aggregateResultList = [SELECT Account__c, SUM(TotalOutstanding__c), Count(Unit__c), SUM(TotalBilled__c) FROM SalesOrder__c Where Account__c IN: customerIdSet AND Status__c = 'Sold' GROUP BY Account__c];
        for (HexaBPM__Service_Request__c newRecord: (List<HexaBPM__Service_Request__c>) newList) {
            for(AggregateResult ar : aggregateResultList){               
                String customerId = (String) ar.get('Account__c');
                if(newRecord.HexaBPM__Customer__c == customerId){
                    newRecord.TotalOutstandingAmount__c = (Decimal) ar.get('expr0');
                    newRecord.TotalNumberofUnits__c = (Decimal) ar.get('expr1');
                    newRecord.TotalBilledAmount__c = (Decimal) ar.get('expr2');
                }
            }
        }
    }    
}