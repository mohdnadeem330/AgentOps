/*
*********************************************************
Apex Class Name    : CustomerServiceCaseTriggerHelper
Created Date       : 
@description       : Class to handle Queries, complain and Request case Business Logic
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public class CustomerServiceCaseTriggerHelper {

    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames);
    public static CaseTriggerMetadata.QueueWrapper queueWrapper = CaseTriggerMetadata.getqueueWrInstance(CaseTriggerHelper.getQueueMap());

    /*
    *********************************************************
    @Method Name    : beforeInsertCustomerService
    @author         : 
    @description    : Method to handle before Insert logic for QCR case
    @param          : newCaseRecords
    @return         : void
    ********************************************************
    */
    public static void beforeInsertCustomerService(List<Case> newCaseRecords) {
        //Local Variable Declaration - Start
        Set<Id> caseUnit = new Set<Id>();
        Map<Id,String> caseSubVerticalMapNew = new Map<Id,String>();
        //Local Variable Declaration - End
        for(Case caseRecord : newCaseRecords){
            String recordTypeName = caseRecord.recordTypeId != null ? Utilities.getRecordTypeName('Case', caseRecord.recordTypeId) : '';
            if(caseRecord.RecordTypeId == rtWrapper.queriesRTypeID || caseRecord.RecordTypeId == rtWrapper.complaintsRTypeID || caseRecord.RecordTypeId == rtWrapper.requestsRTypeID){
                caseSubVerticalMapNew.put(caseRecord.Id, caseRecord.SubCategory__c);                                                                 
                //Case : KAR changes
                if(caseRecord.CaseCategory__c == System.label.Case_KAR_category && caseRecord.Unit__c != null) {
                    caseUnit.add(caseRecord.Unit__c);
                }    
                if(caseRecord.RecordTypeId == rtWrapper.requestsRTypeID  || caseRecord.RecordTypeId == rtWrapper.complaintsRTypeID){
                    if(caseRecord.Priority == 'P1'){
                        caseRecord.EntitlementId =System.label.Case_Normal_Entitlement_ID;
                    }else if(caseRecord.Priority == 'P2'){
                        caseRecord.EntitlementId =System.label.Case_Complaint_Request_P2;
                    }else if(caseRecord.Priority == 'P3'){
                        caseRecord.EntitlementId =System.label.Case_Complaint_Request_P3;
                    }                    
                }  
                if(caseRecord.Origin == Constants.SURVEY_CASE_ORIGIN && recordTypeName == Constants.Complaints){ //Added by Suraj J 10-Dec25
                    caseRecord.OwnerId = queueWrapper.surveyQueue.Id;
                }                          
            }
            //Queries RT 
            if(caseRecord.RecordTypeId == rtWrapper.queriesRTypeID){                   
                caseRecord.FCR__c = true;
                caseRecord.Assigned_To__c = UserInfo.getUserId();
                caseRecord.Status = Constants.CLOSED_CASE; 
            }
        }
        if(!caseUnit.isEmpty()) {
            CaseTriggerHelper.updateKARChanges(newCaseRecords,caseUnit);
        }
        if(!caseSubVerticalMapNew.isEmpty()) {            
            CaseTriggerHelper.populateSubVerticalDependentInfoNew(caseSubVerticalMapNew, newCaseRecords, null);                
        }
    }
	/*
    *********************************************************
    @Method Name    : beforeUpdateCustomerService
    @author         : 
    @description    : Method to handle before Insert logic for QCR case
    @param          : newCaseRecords,oldCaseMap
    @return         : void
    ********************************************************
    */
    public static void beforeUpdateCustomerService(List<Case> newCaseRecords, Map<Id, Case> oldCaseMap) {
        //Local Variable Declaration - Start
        List<case> tasksToInsert = new List<case>();
        List<Case> ownershipchangeCases = new List<Case>();
        List<RefreshComp__e> caseStatusEventList = new List<RefreshComp__e>();
        List<RefreshComp__e> caseSubStatusEventList = new List<RefreshComp__e>(); 
        Set<Id> caseUnit = new Set<Id>();
        Map<String, String> mapownerIds = new Map<String,String>();
        Map<Id,String> caseSubVerticalMapNew = new Map<Id,String>();
        //Local Variable Declaration - End
        for(Case caseRecord : newCaseRecords){
            Case oldCase = oldCaseMap.get(caseRecord.Id);
            if(caseRecord.RecordTypeId == rtWrapper.queriesRTypeID || caseRecord.RecordTypeId == rtWrapper.complaintsRTypeID || caseRecord.RecordTypeId == rtWrapper.requestsRTypeID){
                if((caseRecord.CaseCategory__c != oldcase.CaseCategory__c || caseRecord.Unit__c != oldcase.Unit__c) && caseRecord.CaseCategory__c == System.label.Case_KAR_category && caseRecord.Unit__c != null) {
                    caseUnit.add(caseRecord.Unit__c);
                } 
                integer Max_count = integer.valueof(system.label.Case_Follow_Up_Count_Escalation);               
                if(caseRecord.Customer_Follow_up_Count__c >= Max_count && caseRecord.Customer_Follow_up_Count__c != oldCase.Customer_Follow_up_Count__c ){
                    caseRecord.Status = 'Escalated';
                }    
                // Case revamp:For Creating task attempt 1 when case is resolved
                if(caseRecord.Status == 'Resolved' && oldCase.Status == caseRecord.Status && oldCase.Assigned_To__c == null && caseRecord.Assigned_To__c != null && caseRecord.Sub_Status__c != 'Call Attempt 1' && caseRecord.FCR__c == false){
                    tasksToInsert.add(caseRecord); 
                    caseRecord.Sub_Status__c = 'Call Attempt 1';                    
                }
                if(oldCase.Ownership_Bulk_Changed__c != caseRecord.Ownership_Bulk_Changed__c) {                    
                    ownershipchangeCases.add(caseRecord);
                    mapownerIds.put(caseRecord.id, oldCase.OwnerId);
                    caseRecord.Ownership_Bulk_Changed__c = oldCase.Ownership_Bulk_Changed__c;                    
                }                
                if(oldCase.Assigned_To__c != caseRecord.Assigned_To__c && oldCase.Assigned_To__c != null){
                    caseRecord.Previous_Owner__c = oldCase.Assigned_To__c;
                }
                if(caseRecord.FCR__c != oldcase.FCR__c && caseRecord.FCR__c == true){ 
                    caseRecord.Assigned_To__c = null;                    
                    if(caseRecord.Origin == 'Walk-In' || oldcase.OwnerId == System.label.Walk_in_team_queue){
                        caseRecord.OwnerId = System.label.Walk_in_team_queue;                                
                    }
                    else {
                        caseRecord.OwnerId = System.label.Contact_center_team_queue;
                    }                       
                } 
                //Case revamp : To populate new fields when subvertical,Case category,Sub category or record type changes.
                if(caseRecord.SubVertical__c != oldCase.SubVertical__c || caseRecord.CaseCategory__c != oldCase.CaseCategory__c || caseRecord.SubCategory__c != oldCase.SubCategory__c || caseRecord.RecordTypeId != oldCase.RecordTypeId || (caseRecord.FCR__c != oldcase.FCR__c && caseRecord.FCR__c == false)){
                    caseSubVerticalMapNew.put(caseRecord.Id, caseRecord.SubCategory__c);
                }
                if(caseRecord.RecordTypeId != oldcase.RecordTypeId) {                    
                    //Case revamp : If record type Changed to quries
                    if(caseRecord.RecordTypeId == rtWrapper.queriesRTypeID){
                        caseRecord.Status = 'Closed';
                        caseRecord.FCR__c = true;
                    }
                    //Case revamp : For entitlement process
                    if(((caseRecord.Recordtype_Name__c == Constants.Requests && caseRecord.FCR__c == false) || caseRecord.Recordtype_Name__c == Constants.Complaints)){                        
                        caseRecord.FCR__c = false;
                        if(caseRecord.Priority == 'P1'){
                            caseRecord.EntitlementId =System.label.Case_Normal_Entitlement_ID;
                        } else if(caseRecord.Priority == 'P2'){
                            caseRecord.EntitlementId =System.label.Case_Complaint_Request_P2;
                        } else if(caseRecord.Priority == 'P3'){
                            caseRecord.EntitlementId =System.label.Case_Complaint_Request_P3;
                        }                       
                    } 
                }                                    
            }
            //Logic for Queries RType
            if(caseRecord.Recordtype_Name__c != Constants.Queries) {
                if(oldCase.Status != caseRecord.Status){                    
                    caseRecord.Previous_Status__c = oldCase.Status;
                    if(caseRecord.Status != 'New' && caseRecord.Status != 'Closed') {
                        RefreshComp__e event = new RefreshComp__e(message__c = 'status-'+caseRecord.Status+'-'+caseRecord.RecordTypeId+'-'+caseRecord.Id);
                        caseStatusEventList.add(event);
                    }                    
                }                                        
                if(oldCase.Sub_Status__c != caseRecord.Sub_Status__c){
                    if(caseRecord.Sub_Status__c != 'Pending with other Department' && caseRecord.Sub_Status__c != 'Follow up by other Department') {
                        caseRecord.Previous_SubStatus__c = oldCase.Sub_Status__c;
                        RefreshComp__e event = new RefreshComp__e(message__c = 'Substatus-'+caseRecord.Sub_Status__c );
                        caseSubStatusEventList.add(event);
                    }                    
                }
            }
        }
        if(!caseUnit.isEmpty()) {
            CaseTriggerHelper.updateKARChanges(newCaseRecords,caseUnit);
        } 
        if(!tasksToInsert.isEmpty()){
            CaseTriggerHelper.createResolvertask(tasksToInsert);
        } 
        if(!ownershipchangeCases.isEmpty()){              
            MassOwnerShipChangeLogics.updateCaseOwner(OwnershipchangeCases, mapownerIds);
        }  
        if(!caseSubVerticalMapNew.isEmpty()){
            CaseTriggerHelper.populateSubVerticalDependentInfoNew(caseSubVerticalMapNew, newCaseRecords, oldCaseMap);
        }
        // Call method to publish events
        if(!caseStatusEventList.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(caseStatusEventList);
        }
        if(!caseSubStatusEventList.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(caseSubStatusEventList);
        }     
    }        
}