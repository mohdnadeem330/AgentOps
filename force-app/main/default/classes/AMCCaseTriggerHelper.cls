/*
*********************************************************
Apex Class Name    : AMCCaseTriggerHelper
Created Date       : 
@description       : Class to handle case Trigger Business Logic
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public class AMCCaseTriggerHelper {
    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames);
    /*
    *********************************************************
    @Method Name    : afterInsertAMCCaseRT
    @author         : 
    @description    : Method to handle after insert of AMC case record
    @param          : newCaseList
    @return         : void
    ********************************************************
    */
    public static void afterInsertAMCCaseRT(List<Case> newCaseList) {
        Map<Id,Set<Id>> mapSOProdId = new Map<Id,Set<Id>>();
        for(Case caseRecord : newCaseList) {
            if(caseRecord.RecordtypeId == rtWrapper.amcRTypeID) {
                if(caseRecord.CaseCategory__c == System.Label.ODCaseCategoty){
                    if(!mapSOProdId.containsKey(caseRecord.SalesOrder__c)) {
                        mapSOProdId.put(caseRecord.SalesOrder__c,new Set<Id>());
                    }
                    mapSOProdId.get(caseRecord.SalesOrder__c).add(caseRecord.ProductId);
                }
            }
        }
        if(!mapSOProdId.isEmpty()) {
            CaseTriggerHelper.updateOffLineQtyInprogress(mapSOProdId,Constants.CREATE); 
        }
    }
    /*
    *********************************************************
    @Method Name    : afterUpdateAMCCase
    @author         : 
    @description    : Method to handle after insert of AMC case record
    @param          : newCaseRecords,oldCaseMap
    @return         : void
    ********************************************************
    */
    public static void afterUpdateAMCCase(List<Case> newCaseRecords, Map<Id, Case> oldCaseMap) {
        Map<Id,Set<Id>> mapSOProdId = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> mapSOProdIdCncl= new Map<Id,Set<Id>>();
        for(Case newCase : newCaseRecords) {
            Case oldCase = oldCaseMap.get(newCase.Id);
            if(newCase.RecordtypeId == rtWrapper.amcRTypeID) {
                if (newCase.Status == Constants.CLOSED_CASE && newCase.Status != oldCase.Status && newCase.CaseCategory__c == Constants.ON_DEMAND){
                    if(newCase.AMC_Closure_Reason__c == System.Label.AMCClosureForComleted){
                        if(!mapSOProdId.containsKey(newCase.SalesOrder__c)) mapSOProdId.put(newCase.SalesOrder__c,new Set<Id>());
                        mapSOProdId.get(newCase.SalesOrder__c).add(newCase.ProductId); 
                    }else{  
                        if(!mapSOProdIdCncl.containsKey(newCase.SalesOrder__c))  mapSOProdIdCncl.put(newCase.SalesOrder__c,new Set<Id>()); 
                        mapSOProdIdCncl.get(newCase.SalesOrder__c).add(newCase.ProductId);  
                    }
                }
            }
        }
        if(!mapSOProdId.isEmpty()) {
            CaseTriggerHelper.UpdateOffLineQtyInprogress(mapSOProdId,Constants.CLOSED);
        }
        if(!mapSOProdIdCncl.isEmpty()) {
            CaseTriggerHelper.UpdateOffLineQtyInprogress(mapSOProdIdCncl,Constants.CANCELLED);
        }
    }
}