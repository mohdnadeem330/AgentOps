/***
Class       : CAFMCalloutToMuleSoft
Author      : Smaartt
Description : This class is calling from cls-CaseTriggerHandler
TestClass   : CAFMCalloutToMuleSoftTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details       
1.       V1.0              06/09/24           Initial Version 
****************************************************************************************************************/
public class CAFMCalloutToMuleSoft {
    /**
* Method Name: callCAFMCaseCreationQueue 
* @param cafmCaseIdList - cafm case Ids
* @description Method is invoked from caseTriggerHandler and it is calling batch apex calss with batch size 50,Max 100 callouts in a transaction
* 				 						 
*/
     @AuraEnabled
    public static void callCAFMCaseCreationQueue(List<Id> cafmCaseIdList){
         String queueRunner =system.Label.DM_CAFM_RunQueueable.trim().toUpperCase();
        if (!cafmCaseIdList.isEmpty() && queueRunner == 'TRUE') {
            System.enqueueJob(new CAFMTaskCreationQueueable(cafmCaseIdList, 0)); 
        } else {
            System.debug('No CAFM cases to process for queue.');
        }
    }
}