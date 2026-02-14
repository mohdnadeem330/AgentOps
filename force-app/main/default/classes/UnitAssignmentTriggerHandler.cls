public with sharing class UnitAssignmentTriggerHandler extends TriggerHandler {
    
    public UnitAssignmentTriggerHandler() {}

    public override void beforeInsertMethod(list<SObject> newList, map<Id,SObject> newMap){
        Map<String, Unit_Assignment__c> uniqueKeyToNewRequestMap = new Map<String, Unit_Assignment__c>();
        for (Unit_Assignment__c newUA : (List<Unit_Assignment__c>)newList) {
            newUA.UniqueKey__c = '' + newUA.RequestedBy__c + newUA.Unit__c + newUA.Status__c;
            uniqueKeyToNewRequestMap.put(newUA.UniqueKey__c, newUA);
        }
        if(!uniqueKeyToNewRequestMap.isEmpty()){
            for (Unit_Assignment__c existingUA : [ SELECT Id, UniqueKey__c, Unit__r.Name, RequestedBy__r.Name, Status__c 
                                                       FROM Unit_Assignment__c 
                                                       WHERE UniqueKey__c IN: uniqueKeyToNewRequestMap.keySet() 
                                                            AND Status__c = 'Pending approval']
                ) {
                uniqueKeyToNewRequestMap.get(existingUA.UniqueKey__c).Unit__c.addError(
                    'Request is already in progress for ' + existingUA.Unit__r.Name /* + ' : ' + existingUA.Status__c + '. Please deselect this unit.'*/ );
            }
        }
    }
    
    public override void beforeUpdateMethod(list<SObject> newList,map<Id,SObject> newmap,list<SObject> oldlist,map<Id,SObject> oldmap) {
        newList = trigger.new;
        newMap = trigger.newMap;
        oldList = trigger.old;
        oldMap = trigger.oldMap;
        Map<Id, List<Unit_Assignment__c>> unitIdToRequestsMap = new Map<Id, List<Unit_Assignment__c>>();
        for(Unit_Assignment__c newUA: (List<Unit_Assignment__c>) newList){
            Unit_Assignment__c oldUA = (Unit_Assignment__c) oldMap.get(newUA.Id);
            newUA.Status__c = (newUA.ApproverResponse__c != null && newUA.ApproverResponse__c != oldUA.ApproverResponse__c) ? newUA.ApproverResponse__c : newUA.Status__c ;
            if(newUA.Status__c == 'Approved' && newUA.Status__c != oldUA.Status__c){
                if( unitIdToRequestsMap.containsKey( newUA.Unit__c )){
                    unitIdToRequestsMap.get(newUA.Unit__c).add(newUA);
                }else{
                    unitIdToRequestsMap.put(newUA.Unit__c, new List<Unit_Assignment__c>{newUA});
                }
            }
        }

        if(!unitIdToRequestsMap.isEmpty()){
            for(Unit__c u: [SELECT Id, Name, Status__c, AssignedToUser__c, AllocationGroup__c FROM Unit__c WHERE Id IN: unitIdToRequestsMap.keySet() FOR UPDATE]){
                String errorMessage; 
                if( u.AssignedToUser__c != null ){
                    errorMessage = 'Unit assigned to someone else. ';
                }else if( u.Status__c != 'Available' ){
                    errorMessage = 'Unit is not available. ';
                }else if( unitIdToRequestsMap.get(u.Id).size() > 1 ){
                    errorMessage = u.Name + ': Cannot approve multiple requests for this Unit.';
                }
                for(Unit_Assignment__c ua : unitIdToRequestsMap.get(u.Id)){
                    if(errorMessage != null){
                        ua.addError( errorMessage );                    
                    }else{
                        ua.ExistingAllocationGroup__c = u.AllocationGroup__c;
                    }
                }
            }
        }
    }

    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        Map<Id, Unit_Assignment__c> unitIdToApprovedReqMap = new Map<Id, Unit_Assignment__c>();
        newList = trigger.new;
        newMap = trigger.newMap;
        oldList = trigger.old;
        oldMap = trigger.oldMap;
        system.debug('newList '+newList);
        
        for (Unit_Assignment__c newUA : (List<Unit_Assignment__c>) newList) {
            Unit_Assignment__c oldUA = (Unit_Assignment__c) oldMap.get(newUA.Id);
            if (newUA.Status__c == 'Approved' && newUA.Status__c != oldUA.Status__c) {
                unitIdToApprovedReqMap.put(newUA.Unit__c, newUA);
            }
        }
        if( !unitIdToApprovedReqMap.isEmpty() ){
            List<Unit__c> unitsToUpdate = new List<Unit__c>();
            for (Id unitId : unitIdToApprovedReqMap.keySet()) {
                if (unitIdToApprovedReqMap.get(unitId) == null) { continue; }
                unitsToUpdate.add( 
                    new Unit__c(
                        Id = unitId, 
                        AssignedToUser__c = unitIdToApprovedReqMap.get(unitId).RequestedBy__c, 
                        AllocationGroup__c = null,
                        RelatedOpportunity__c = unitIdToApprovedReqMap.get(unitId).Opportunity__c
                    ) 
                );
            }
            Set<Id> unitsToDisqualigyRequests = new Set<Id>();
            if( !unitsToUpdate.isEmpty()) {
                System.debug('unitsToUpdate :' + unitsToUpdate);
                Database.SaveResult[] srList = Database.update(unitsToUpdate, false);
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        List<String> errors = new List<String>();
                        for(Database.Error err : sr.getErrors()) {
                            List<String> errosFields = new List<String>();
                            Map<String,Schema.SObjectField> unitField = Schema.SObjectType.Unit__c.fields.getMap();
                            for(String fieldApiName : err.getFields()){
                                errosFields.add( getFieldLabel('Unit__c', fieldApiName) );
                            }
                            errors.add( 'Unit Errors: \n'+ String.join( errosFields, ', ') +': '+ err.getMessage());
                        }
                        unitIdToApprovedReqMap.get( sr.getId() ).Unit__c.addError( String.join( errors,'\n') );   
                    }else{
                        unitsToDisqualigyRequests.add( sr.getId() );
                    }
                }
            }
            // disqualify the the other matching unit assignment request
            List<Unit_Assignment__c> assignmentToDisqualify = [ SELECT Id, Status__c 
                                                                FROM Unit_Assignment__c 
                                                                WHERE Unit__c IN : unitsToDisqualigyRequests 
                                                                    AND Status__c = 'Pending approval'];
            if( !assignmentToDisqualify.isEmpty() ){
                for (Unit_Assignment__c ua : assignmentToDisqualify) {
                    ua.Status__c = 'Disqualified';
                }
                update assignmentToDisqualify;
            }
        }
    }

    public static Map<String, Map<String,Schema.SObjectField>> ObjectFieldsMap = new Map<String, Map<String,Schema.SObjectField>>();

    @TestVisible
    private static String getFieldLabel(String objectApiName, String fieldApiName) {
        if(!ObjectFieldsMap.containsKey(objectApiName)){
            ObjectFieldsMap.put(objectApiName, Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap());
        }
        return ObjectFieldsMap.get(objectApiName).get(fieldApiName).getDescribe().getLabel();
    }
}