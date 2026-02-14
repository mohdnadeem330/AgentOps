/*
*********************************************************
Apex Class Name    : CorporateLegalCaseTriggerHelper
Created Date       : 
@description       : Class to handle case Trigger Business Logic of CorporateLegal
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public class CorporateLegalCaseTriggerHelper {

    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames);

    /*
    *********************************************************
    @Method Name    : beforeInsertCorporateLegalRT
    @author         : 
    @description    : Method to handle before insert logic for Corporate Legal RT
    @param          : newCaseRecords
    @return         : void
    ********************************************************
    */
    public static void beforeInsertCorporateLegalRT(List<Case> newCaseRecords) {
        for(Case caseRecord : newCaseRecords) {
            if(caseRecord.RecordTypeId == rtWrapper.corporateLegalRTypeID) {
                caseRecord.Status = 'Legal Notice';
            }
        }
    }
}