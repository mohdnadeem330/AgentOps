/**********************************************************************************************************************
* Name               :                                                         
* Description        : 
* Created By         : Tharun                                                   
******************************************************************************************************************/
public class DirectDebitTriggerHandler  extends TriggerHandler{

    //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        DirectDebitService.populateOwner((List<DirectDebitRequest__c>) newList);
        DirectDebitService.populateDefaultValues((List<DirectDebitRequest__c>) newList);
        DirectDebitService.checkForExistingActiveDDR ((List<DirectDebitRequest__c>) newList);
    }
    
    //*** Before Update Action***//
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        if(!System.isBatch()){
            DirectDebitService.checkForExistingActiveDDR ((List<DirectDebitRequest__c>) newList);
        }    
        
        List<DirectDebitRequest__c> directDebitRequestToBeUpdated = new List<DirectDebitRequest__c>();
        List<DirectDebitRequest__c> ddrToBeUpdatedBasedOnVerifierReceiver = new List<DirectDebitRequest__c>();
        List<DirectDebitRequest__c> directDebitRequestToUpdateWhenStatusRejected = new List<DirectDebitRequest__c>(); 
        List<DirectDebitRequest__c> ddrCancelltionToBeUpdatedBasedOnVerifierReceiver = new List<DirectDebitRequest__c>();
        List<DirectDebitRequest__c> dDRToUpdateWhenStatusCancellationRejected = new List<DirectDebitRequest__c>(); 
        List<DirectDebitRequest__c> dDRTocheckForSignedCancellationForm = new List<DirectDebitRequest__c>();
        
        Map<String, BankRoutingCodes__mdt> allBankCodeValues = new Map<String, BankRoutingCodes__mdt>();
        allBankCodeValues = DirectDebitService.getBankEntityIDValues();
        
        for(DirectDebitRequest__c ddrRequest: (List<DirectDebitRequest__c>) newList ){
            
            DirectDebitRequest__c oldDDR = (DirectDebitRequest__c) oldMap.get(ddrRequest.Id);
            //Below code to fetch ENTITYID__c from allBankCodeValues
            if(ddrRequest.CustomerBankName__c != oldDDR.CustomerBankName__c && !allBankCodeValues.isEmpty() && allBankCodeValues.Keyset().contains(ddrRequest.CustomerBankName__c)){
                ddrRequest.PayingBankID__c  = allBankCodeValues.get(ddrRequest.CustomerBankName__c).ENTITYID__c;
                ddrRequest.PayingBankRoutingCode__c = allBankCodeValues.get(ddrRequest.CustomerBankName__c).ROUTING_CODE__c;
            }
            if(ddrRequest.Cancelled__c && ddrRequest.Cancelled__c != oldDDR.Cancelled__c){
                directDebitRequestToBeUpdated.add(ddrRequest);
            }
            if((ddrRequest.isReceived__c && !oldDDR.isReceived__c) || (ddrRequest.isVerified__c && !oldDDR.isVerified__c)
               || ( (ddrRequest.Status__c == System.Label.ReceivedbyFinance|| ddrRequest.Status__c == System.Label.VerifiedbyFinance)
               && ddrRequest.Status__c != oldDDR.Status__c)){
                ddrToBeUpdatedBasedOnVerifierReceiver.add(ddrRequest);
            }
            
            if(((ddrRequest.ReceiveCancellationForm__c && !oldDDR.ReceiveCancellationForm__c) || (ddrRequest.CancelDirectDebitRequest__c && !oldDDR.CancelDirectDebitRequest__c)) && ddrRequest.Status__c != 'DDS Generated' && ddrRequest.Status__c != 'Received by Finance'){
                ddrCancelltionToBeUpdatedBasedOnVerifierReceiver.add(ddrRequest);
            }
            
            if(ddrRequest.Status__c == System.Label.RejectedbyBank && ddrRequest.Status__c != oldDDR.Status__c){                directDebitRequestToUpdateWhenStatusRejected.add(ddrRequest);
            }
            if(ddrRequest.Status__c == 'Cancellation Rejected' && ddrRequest.Status__c != oldDDR.Status__c){                dDRToUpdateWhenStatusCancellationRejected.add(ddrRequest);
            }
            if( (ddrRequest.CancelDirectDebitRequest__c && !oldDDR.CancelDirectDebitRequest__c ) || (ddrRequest.ReceiveCancellationForm__c && !oldDDR.ReceiveCancellationForm__c ) ){                dDRTocheckForSignedCancellationForm.add(ddrRequest);
            }
            
            system.debug('ddrRequest.Status__c:'+ddrRequest.Status__c);
            system.debug('oldDDR.Status__c:'+oldDDR.Status__c);
            if(ddrRequest.Status__c != oldDDR.Status__c ){
                if(ddrRequest.Status__c == System.Label.SenttoBank ){
                    ddrRequest.SentTobankDate__c = System.now();
                    ddrRequest.Rejection_Reason__c = '';
                    ddrRequest.AdditionalRejectionReason__c = '';
                    ddrRequest.RejectedDate__c = null;
                    ddrRequest.AckNak__c = null;
                }else if(ddrRequest.Status__c == System.Label.ApprovedbyBank){
                    ddrRequest.Approveddate__c = System.now();
                }else if(ddrRequest.Status__c == System.Label.RejectedbyBank){
                    ddrRequest.RejectedDate__c = System.now();
                }
            }
            
            if( (ddrRequest.CancelDirectDebitRequest__c && ddrRequest.ReceiveCancellationForm__c) && (!oldDDR.CancelDirectDebitRequest__c || !oldDDR.ReceiveCancellationForm__c)){
                if(ddrRequest.Status__c == 'DDS Generated' || ddrRequest.Status__c == 'Received by Finance'){
                    ddrRequest.Status__c = 'Cancelled';
                }
            }
        }
        
        
        if(!directDebitRequestToBeUpdated.isEmpty()){            DirectDebitService.updateDirectDebitStatus(directDebitRequestToBeUpdated);
        }
        if(!ddrToBeUpdatedBasedOnVerifierReceiver.isEmpty()){            DirectDebitService.updateDDRStatusVerifierReceiver(ddrToBeUpdatedBasedOnVerifierReceiver);
        }
        if(!directDebitRequestToUpdateWhenStatusRejected.isEmpty()){            DirectDebitService.updateDDRWhenStatusIsRejected(directDebitRequestToUpdateWhenStatusRejected);
        }
        if(!ddrCancelltionToBeUpdatedBasedOnVerifierReceiver.isEmpty()){            DirectDebitService.updateCancelltionDDRStatusVerifierReceiver(ddrCancelltionToBeUpdatedBasedOnVerifierReceiver);
        }
        if(!dDRToUpdateWhenStatusCancellationRejected.isEmpty()){           DirectDebitService.updateDDRWhenStatusIsCancellationRejected(dDRToUpdateWhenStatusCancellationRejected);
        }
        if(!dDRTocheckForSignedCancellationForm.isEmpty()){            DirectDebitService.checkForSignedDirectDebitFormCancellation(dDRTocheckForSignedCancellationForm);
        }
        
    }

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        List<DirectDebitRequest__c> directDebitRequestToReplicateList = new List<DirectDebitRequest__c>();
        Map<Id, DirectDebitRequest__c> toBeSentDDMap = new Map<Id,DirectDebitRequest__c>();
		for(Id mapKey : newMap.Keyset()) {
            toBeSentDDMap.put(mapKey, (DirectDebitRequest__c) newMap.get(mapKey));
        }
        if(!toBeSentDDMap.isEmpty()){
        	createDirectDebitDocuments(toBeSentDDMap);
        }
        system.debug('new list::::'+ (List<DirectDebitRequest__c>) newList );
        for(DirectDebitRequest__c ddrRequest: (List<DirectDebitRequest__c>) newList ){
            if(ddrRequest.Replicate_same_on_other_Sales_Order__c ){
                directDebitRequestToReplicateList.add(ddrRequest);
            }
        }
        if(!directDebitRequestToReplicateList.isEmpty()) {
            DirectDebitService.replicateDDRonOtherSalesOrders(directDebitRequestToReplicateList);
        }
    }

    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
       List<DirectDebitRequest__c> directDebitRequestToReplicateList = new List<DirectDebitRequest__c>();
         List<DirectDebitRequest__c> directDebitRequestSOToBeupdated = new List<DirectDebitRequest__c>();
        system.debug('new List:::'+ ((List<DirectDebitRequest__c>) newList));
        for(DirectDebitRequest__c ddrRequest: (List<DirectDebitRequest__c>) newList ){
            DirectDebitRequest__c oldDDR = (DirectDebitRequest__c) oldMap.get(ddrRequest.Id);
            if(ddrRequest.Replicate_same_on_other_Sales_Order__c && ddrRequest.Replicate_same_on_other_Sales_Order__c != oldDDR.Replicate_same_on_other_Sales_Order__c ){
                directDebitRequestToReplicateList.add(ddrRequest);
            }
            if(ddrRequest.Status__c == System.Label.Cancelled && ddrRequest.Status__c != oldDDR.Status__c){
                directDebitRequestSOToBeupdated.add(ddrRequest);
            }
        }
        
        if(!directDebitRequestSOToBeupdated.isEmpty()){
            DirectDebitService.updateSODDRN(directDebitRequestSOToBeupdated);
        }   
        if(!directDebitRequestToReplicateList.isEmpty()) {
            DirectDebitService.replicateDDRonOtherSalesOrders(directDebitRequestToReplicateList);
        }
    }
    
    /* Method Name 	: createDirectDebitDocuments
     * Description	: To create Document placeholders for Direct Debit 
     * 
     */
    public static void createDirectDebitDocuments(map<id,DirectDebitRequest__c> ddMap)
    {
       
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<string,ID> documentRecordTypeMap = new map<string,ID>();
        
        map<string,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{DirectDebitService.DOCUMENT_PLACEHOLDER_CATEGORY_DIRECT_DEBIT});
        system.debug('documentMap:::'+documentMap);
        if(!documentMap.isEmpty()){
            //get Existing Documents
            map<string,Document__c> existingDocMap = new map<string,Document__c>();
            for(Document__c tempDoc : [select id,DocumentType__c,DirectDebitRequest__c from Document__c where DirectDebitRequest__c in :ddMap.keySet()]){
                existingDocMap.put(tempDoc.DirectDebitRequest__c+tempDoc.DocumentType__c,tempDoc);
            }
            system.debug('documentMap:::'+ddMap.values());
            for(DirectDebitRequest__c dd : ddMap.values()){
                system.debug('documentMap:::'+documentMap.get(DirectDebitService.DOCUMENT_PLACEHOLDER_CATEGORY_DIRECT_DEBIT));
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(DirectDebitService.DOCUMENT_PLACEHOLDER_CATEGORY_DIRECT_DEBIT)){
                    string recordTypeID=null;
                    System.debug('LINE: 50 - '+tempMetaRec);
                    if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    System.debug('recordTypeID---'+recordTypeID);
                    if(!existingDocMap.containsKey( dd.Id + tempMetaRec.DocumentType__c))
                    {
                        Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'','',recordTypeID);
                        documentRecord.DirectDebitRequest__c	= dd.Id;
                        documentRecord.SendForESign__c			= tempMetaRec.eSignRequired__c;
                        documentRecord.DocumentPlaceHolderId__c	= tempMetaRec.DeveloperName;
                        documentRecord.EligibleForeSign__c		= tempMetaRec.EligibleForeSign__c;
                        
                        //documentRecord.GenerateDocument__c = (tempMetaRec.GeneratedManually__c != true);
                        documentListToInsert.add(documentRecord);    
                    }
                }
            }
        }
        
        if(!documentListToInsert.isEmpty()){
            insert documentListToInsert;  
        } 
    }   
}