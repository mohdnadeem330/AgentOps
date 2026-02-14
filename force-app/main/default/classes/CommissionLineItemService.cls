/**********************************************************************************************************************
* Name               : CommissionLineItemService                                                        
* Description        : Helper methods for CommissionLineItem

* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           ajay@pwc.com     21 May 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class CommissionLineItemService {
    public CommissionLineItemService() {}
    /**
    * insertCommissionLineItem 
    *
    * method to insert CommissionLineItem__c
    *
    * @param List<CommissionLineItem__c> commissionLines to be inserted
    * @return  lnone
    * 
    */
    @AuraEnabled(cacheable=false)
    public static void insertCommissionLineItem(List<CommissionLineItem__c> commissionLineList){
      insert commissionLineList;
    }

    /**
    * fetchCommissionLineForAPIByUser 
    *
    * get the sum of CommissionAmount__c commission for the given user and with given status
    *
    * @param userId
    * @param status 
    * @return  sum of CommissionAmount__c
    * 
    */
    public static AggregateResult[] fetchCommissionLineForAPIByUser(String userId, String status) {
        return [SELECT SUM(CommissionAmount__c) FROM CommissionLineItem__c WHERE SalesOrder__r.Status__c =: status AND SalesManager__c =: userId  AND SalesOrder__r.BookingDate__c = THIS_FISCAL_YEAR];
    }
}