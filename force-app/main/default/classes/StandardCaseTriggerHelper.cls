/*
*********************************************************
Apex Class Name    : CaseTriggerValidation
Created Date       : 
@description       : Class to handle case Trigger Business Logic
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public with sharing class StandardCaseTriggerHelper {

    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames);
    /*
    *********************************************************
    @Method Name    : beforeInsertStandardRT
    @author         : 
    @description    : Method to validate before insert case
    @param          : newCaseRecords
    @return         : void
    ********************************************************
    */
    public static void beforeInsertStandardRT(List<Case> newCaseRecords) {  
        List<String> CaseConversionSkipsubvertical = System.label.Skip_converstion_subvertical.split(',');      
        for(Case caseRecord : newCaseRecords) {
            if(caseRecord.RecordTypeId == rtWrapper.standardRTypeID) {
                if ((caseRecord.Origin == Constants.CUSTOMER_PORTAL || caseRecord.Origin == Constants.CUSTOMER_APP) && system.label.Revamp_Case_toggle.tolowercase() == 'true' && !CaseConversionSkipsubvertical.contains(caseRecord.SubVertical__c) || (caseRecord.Origin == Constants.EMAIL && system.label.Revamp_Case_email_converstion.tolowercase() == 'true')) {
                    caseRecord.RecordTypeId = rtWrapper.requestsRTypeID; 
                }
            }
        }
    }
}