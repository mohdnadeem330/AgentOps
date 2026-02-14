/****************************************************************************************************************
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
public class DMcaseMilestonehandlerNew {
    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames); 
    /*
    *********************************************************
    @Method Name    : milestone
    @author         : 
    @description    : Method to handle before Insert logic for case
    @param          : newCaseList, oldCaseMap
    @return         : void
    ********************************************************
    */
    public static void milestone(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {   
        for(Case caseRecord : newCaseList) { 
            Case oldCase = oldCaseMap.get(caseRecord.Id);
            if(caseRecord.RecordTypeId == rtWrapper.DmrecordtypeId){
                if(caseRecord.Sub_Status__c!=oldCase.Sub_Status__c ){
                    if (caseRecord.Sub_Status__c.equals(Label.DM_AdditionalInfoFromCustomer) || caseRecord.Sub_Status__c.equals(Label.DM_AdditionalInfoFromPMC)) {
                        caseRecord.IsStopped = true;
                    } else if ((oldCase.Sub_Status__c.equals(Label.DM_AdditionalInfoFromCustomer) && !caseRecord.Sub_Status__c.equals(Label.DM_AdditionalInfoFromCustomer))|| (oldCase.Sub_Status__c.equals(Label.DM_AdditionalInfoFromPMC) &&!caseRecord.Sub_Status__c.equals(Label.DM_AdditionalInfoFromPMC))) {
                        caseRecord.IsStopped = false;
                    }        
                } 
            }
        }
    }
}