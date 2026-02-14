/**********************************************************************************************************************
* Name               : PaymentPlanTriggerHandler                                                        
* Description        : This class contains all the helper methods for the PaymentPlan__c Trigger
* Usage              : PaymentPlanTrigger
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           @pwc.com     21 May 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class PaymentPlanTriggerHandler extends TriggerHandler {
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        createPaymentPlanDocuments((list<PaymentPlan__c>) newList);
    }
    
    public static void createPaymentPlanDocuments(list<PaymentPlan__c> paymentPlans){
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<string,ID> documentRecordTypeMap = new map<string,ID>();
        map<string,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PAYMENTPLAN});
        
        if(!documentMap.isEmpty()){
            for(PaymentPlan__c paymentPlanRec : paymentPlans){
                
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PAYMENTPLAN)){
                    string recordTypeID=null;
                    if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    //No existing check as records will be created on insert
                    Document__c documentRecord =new Document__c(DocumentType__c = tempMetaRec.DocumentType__c,
                                                PaymentPlan__c = paymentPlanRec.Id,
                                                RecordtypeId= recordTypeID,
                                                AvailableForExternalUsers__c = tempMetaRec.AvailableForExternalUsers__c /*,
                                                GenerateDocument__c = (tempMetaRec.GeneratedManually__c != true)*/ );
                    documentListToInsert.add(documentRecord);        
                    
                }
            }
        }
        
        if(!documentListToInsert.isEmpty()){
          insert documentListToInsert;  
        } 
    }
    
    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        for(PaymentPlan__c ppRecord : (List<PaymentPlan__c>)newList){
            Id recordId = ppRecord.Id ;
            PaymentPlan__c oldppRecord = (PaymentPlan__c)oldMap.get(recordId);
            
            if(ppRecord.Name != oldppRecord.Name 
               || ppRecord.isActive__c != oldppRecord.isActive__c 
               || ppRecord.OnlineFlag__c != oldppRecord.OnlineFlag__c){
                   ppRecord.DamascusSyncStatus__c = 'In Progress';
               }
        }
    }
    
    public override void afterUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        
        Map<Id, PaymentPlan__c> changedPPMap = new Map<Id, PaymentPlan__c>();
        List<String> paymentPlanIds = new List<String>();
        
        for(PaymentPlan__c ppRecord : (List<PaymentPlan__c>)newList){
            
            if(ppRecord.DamascusSyncStatus__c == 'In Progress'){
				changedPPMap.put(ppRecord.Id, ppRecord);
                paymentPlanIds.add(ppRecord.Id);
            }
        }
        
        if(changedPPMap !=null && !changedPPMap.isEmpty()){
            processPPChangesForDamascus(changedPPMap, paymentPlanIds);
        }
    }
    
    /*
     * @functionality: Callback API to Damascus
     * @author: Sarah
     * 
     */
    public static void processPPChangesForDamascus(Map<Id, PaymentPlan__c> newPPsMap, List<String> paymentPlanIds){
        
        if(System.isBatch()) {
            CalloutToMuleSoft.calloutService(
                JSON.serialize( new Map<String, Object>{ 'paymentplans' => Damascus_RestApiHandler.getModifiedPaymentPlans(paymentPlanIds) } ), 
                true,
                Constants.Damascus_Callback_Payment_Plan,
                new List<Id>(newPPsMap.keySet())
            );
        } else {
            CalloutToMuleSoft.calloutFutureService(
                JSON.serialize( new Map<String, Object>{ 'paymentplans' =>  Damascus_RestApiHandler.getModifiedPaymentPlans(paymentPlanIds) } ), 
                true, 
                Constants.Damascus_Callback_Payment_Plan,
                new List<Id>(newPPsMap.keySet())
            );
        }
        
    }
}