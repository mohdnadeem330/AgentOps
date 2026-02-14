/**********************************************************************************************************************
* Name               : SPAChecklistService                                                        
* Description        : This class is used to retrive all the SPAChecklist__c records
* Usage              :                                                       
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           shivani@pwc.com     10 Feb 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class SPAChecklistService {
    /**
    * SPAAllChecklistRecords 
    *
    * return all SPAChecklist__c records related to SalesOrder
    
    *
    * @param Id Sales order record ID
    * @return  List<SPAChecklist__c>
    * 
    */
    public static List<SPAChecklist__c> SPAAllChecklistRecords( Id salesOrderId) {
        List<SPAChecklist__c> getAllExistingRec= [SELECT Id, Name, SalesOrder__c, ItemName__c, ValidatedbySalesAdmin__c, ValidatedbyCMTeam__c, Notes__c, ChecklistCategory__c FROM SPAChecklist__c WHERE SalesOrder__c =:salesOrderId ];
        return getAllExistingRec;
    }
}