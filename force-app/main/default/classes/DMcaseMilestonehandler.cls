/***
Class       : DMcaseMilestonehandler
Author      : Smaartt
Description : Stop and resuming milestone timing in salesforce
TestClass   : DMcaseMilestonehandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              22/04/24           Initial Version 
2.       v1.1              17/09/24           Added null checks
****************************************************************************************************************/
public class DMcaseMilestonehandler {
    public static void milestone(Case caseRecord, Case oldCase) {    
        if(caseRecord.Sub_Status__c !=null && oldCase.Sub_Status__c!= null){
            if (caseRecord.Sub_Status__c.equals(Label.DM_AdditionalInfoFromCustomer) || caseRecord.Sub_Status__c.equals(Label.DM_AdditionalInfoFromPMC)) {
                caseRecord.IsStopped = true;
            } else if ((oldCase.Sub_Status__c.equals(Label.DM_AdditionalInfoFromCustomer) && !caseRecord.Sub_Status__c.equals(Label.DM_AdditionalInfoFromCustomer))|| (oldCase.Sub_Status__c.equals(Label.DM_AdditionalInfoFromPMC) &&!caseRecord.Sub_Status__c.equals(Label.DM_AdditionalInfoFromPMC))) {
                caseRecord.IsStopped = false;
            }        
        } 
    }
}