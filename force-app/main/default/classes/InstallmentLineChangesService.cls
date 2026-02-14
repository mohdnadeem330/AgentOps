/**********************************************************************************************************************
* Name               : InstallmentLineChangesService                                                        
* Description        : Class contains InstallmentLineChanges__c releated utilitties                                               
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           @pwc.com     06/06/2022      Initial Draft       
******************************************************************************************************************/

public with sharing class InstallmentLineChangesService {
  //Retrive InstallmentLineChanges__c based on SOQL query
  @AuraEnabled(cacheable=false)
  public static List<InstallmentLineChanges__c> getInstallmentLineChangesQuery(String query) {
    List<InstallmentLineChanges__c> records = Database.query(query);
    return records;
  }

  //Create InstallmentLineChanges__c based on given parameters
  @AuraEnabled(cacheable=false)
  public static Boolean createInstallmentLineChanges(List<String> proposedRatesValues,List<String> proposedBrokerValues ,List<String> proposedDateValues, List<String> proposedDescription, String paymentPlan, String bookingMemo, String unit) {
            
    List<InstallmentLineChanges__c> InstallmentLineChangesList = new List<InstallmentLineChanges__c>();
    for (Integer i = 0; i < proposedRatesValues.size(); i++) {
      InstallmentLineChanges__c InstallmentLineChangesRecord = new InstallmentLineChanges__c();
      
      InstallmentLineChangesRecord.InstallmentNumber__c = i+1 ;
      if (String.isNotBlank(unit)) {
        InstallmentLineChangesRecord.Unit__c = unit;
      }
      if (String.isNotBlank(paymentPlan)) {
        InstallmentLineChangesRecord.PaymentPlan__c = paymentPlan;
      }
      if (String.isNotBlank(bookingMemo)) {
        InstallmentLineChangesRecord.BookingMemo__c = bookingMemo;
      }
      if (String.isNotBlank(proposedDateValues[i])) {
        InstallmentLineChangesRecord.ProposedInstallmentDate__c = Date.valueOf(proposedDateValues[i]);
      }
      if (String.isNotBlank(proposedDescription[i])) {
        InstallmentLineChangesRecord.Description__c = proposedDescription[i];
      }
      if (String.isNotBlank(proposedRatesValues[i])) {
        InstallmentLineChangesRecord.ProposedInstallmentPercentage__c = decimal.valueOf(proposedRatesValues[i]);
      }
      if (String.isNotBlank(proposedBrokerValues[i])) {
        InstallmentLineChangesRecord.BrokerPayoutPercentage__c = decimal.valueOf(proposedBrokerValues[i]);
      }
      InstallmentLineChangesList.add(InstallmentLineChangesRecord);
    }
            
    insert InstallmentLineChangesList;
    return true;     
  }

  @AuraEnabled(cacheable=false)
  public static List<InstallmentLineChanges__c> getInstallmentLineChangesByBookinMemoId(Id bookingMemoId) {
    List<InstallmentLineChanges__c> records = [select Id,BrokerPayoutPercentage__c,ProposedInstallmentPercentage__c,PaymentPlan__c,ProposedInstallmentDate__c,Description__c,InstallmentNumber__c,BookingMemo__c,Unit__c,Unit__r.BuildingSectionName__c from InstallmentLineChanges__c where BookingMemo__c =: bookingMemoId];
    return records;
  }
}