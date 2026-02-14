/**********************************************************************************************************************
* Name               : OpportunityEOIService                                                        
* Description        : This class is used to OpportunityEOI related helper and utility methods
* Usage              : 
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           @pwc.com     21 Jan 2022      Initial Draft       
******************************************************************************************************************/

public with sharing class OpportunityEOIService {
    //Create EOI reocrd
    @AuraEnabled(cacheable=false)
      public static Boolean createOpportunityEOI( String opportunity, String account, String projectName, String buildingSectionName, 
      String unitModel, String unitType, String unitFeatures, String paymentMode, String remarks, String customerPreference,
      String priceRangeFrom, String priceRangeTo, String interestFee, String numberOfUnits) {
        try{   
          List<OpportunityEOI__c> opportunityEOIList = new List<OpportunityEOI__c>();
            OpportunityEOI__c opportunityEOIRecord = new OpportunityEOI__c();
            opportunityEOIRecord.Opportunity__c = opportunity;
            opportunityEOIRecord.Account__c = account;
            opportunityEOIRecord.ProjectName__c = projectName;
            opportunityEOIRecord.BuildingSectionName__c = buildingSectionName;
            opportunityEOIRecord.UnitModel__c = unitModel;
            opportunityEOIRecord.UnitType__c = unitType;
            opportunityEOIRecord.UnitFeatures__c = unitFeatures;
            opportunityEOIRecord.PaymentMode__c = paymentMode;
            opportunityEOIRecord.Remarks__c = remarks;
            opportunityEOIRecord.CustomerPreference__c = customerPreference;
            opportunityEOIRecord.PriceRangeFrom__c = integer.valueof(priceRangeFrom);
            opportunityEOIRecord.PriceRangeTo__c = integer.valueof(priceRangeTo);
            opportunityEOIRecord.InterestFee__c = integer.valueof(interestFee);
            system.debug('numberofUnits>>>>>'+numberOfUnits);
            if(String.isNotBlank(numberofUnits)){
                opportunityEOIRecord.NumberOfUnits__c = integer.valueof(numberOfUnits);
            }
            
            opportunityEOIRecord.Status__c = Constants.STATUS_IN_PROGRESS;
            
            opportunityEOIList.add(opportunityEOIRecord);
            insert opportunityEOIList;
            return true;    
        }catch(Exception ex){
            System.debug('msg '+ex.getMessage());
            System.debug('Line no '+ex.getLineNumber());
            LoggerService.Save( LoggerService.addApexLog(ex,'OpportunityEOIService','Create Opportunity EOI record','createOpportunityEOI') );
            throw new AuraHandledException('Constants.MESSAGE_GENERIC_ERROR');
        } 
    }

    //Cancel EOI
    @InvocableMethod(callout=true)
    public static void cancelledOpportunityEOI(List<OpportunityEOI__c> opportunityEOIList) {
        for (OpportunityEOI__c opportunityEOIObject : opportunityEOIList) {
            opportunityEOIObject.Status__c = 'Cancelled';
        }
        update opportunityEOIList;
    }

    //Retrive all the EOI related to Opportunity
    @AuraEnabled(cacheable=false)
    public static Boolean checkOpportunityEOI(String opportunityId){ 
        List<OpportunityEOI__c> accountDetails =  [SELECT Id FROM OpportunityEOI__c WHERE Opportunity__c =: opportunityId]; 
        if (accountDetails.size() > 0) {
            return true;
        }else {
            return false;
        }
    }

    //Execute OpportunityEOI__c SOQL
    @AuraEnabled(cacheable=false)
      public static List<OpportunityEOI__c> getOpportunityEOIQuery(String query) {
      List<OpportunityEOI__c> records = Database.query(query);
      return records;
    }
    
    public static List<OpportunityEOI__c> queryAllFieldsWithExtraFields(List<Id> opportunityEOIId) {
        Set<String> opportunityEOIIdFieldList = Schema.getGlobalDescribe().get('OpportunityEOI__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(opportunityEOIIdFieldList);
        String fields = string.join(strList,',');
        
       Set<String> raFieldList = Schema.getGlobalDescribe().get('ReceiptAcknowledgement__c').getDescribe().fields.getMap().keySet();
        List<String> strRAList = new List<String>();
        strRAList.addAll(raFieldList);
        String raFields = string.join(strRAList, ',');

        Set<String> docFieldList = Schema.getGlobalDescribe().get('Document__c').getDescribe().fields.getMap().keySet();
        List<String> strDocList = new List<String>();
        strDocList.addAll(docFieldList);
        String docFields = string.join(strDocList, ',');
        
        String opportunityEOIIdStr = String.join(opportunityEOIId, '\',\'');
		
        String query = 'SELECT Account__r.Name, Opportunity__r.Name,' + fields + ', (SELECT ' + raFields + ' FROM Payments__r), (SELECT ' + docFields + ' FROM DocumentsExpressionofInterest__r) FROM OpportunityEOI__c WHERE Opportunity__c IN (\'' + opportunityEOIIdStr + '\')';
        System.debug('***OpportunityEOI query***'+query);
        List<OpportunityEOI__c> opportunityEOIRecords = getOpportunityEOIQuery(query);
        System.debug('***OpportunityEOI Records***'+opportunityEOIRecords);
        return opportunityEOIRecords;
    }
}