/**********************************************************************************************************************
* Name               : OpportunityEOITriggerHandler                                                        
* Description        : This class is used to provide all helper mrthods for OpportunityEOITrigger
* Usage              : OpportunityEOITrigger
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           @pwc.com     21 Jan 2022      Initial Draft       
******************************************************************************************************************/

public with sharing class OpportunityEOITriggerHandler extends TriggerHandler{
    //*** Before Insert Action***//
    public override void beforeInsertMethod(list<SObject> newList,map<ID,SObject> newMap){
        for(OpportunityEOI__c newRecord  : (list<OpportunityEOI__c >) newList){
            if(newRecord.InterestFee__c != null ){
                newRecord.InterestFeeinwords__c = Utilities.amountInWords(newRecord.InterestFee__c,'Dhirams','Fils');
            }
        }
    }

    //*** Before Update Action***//
    public override void beforeUpdateMethod(list<SObject> newList,map<Id,SObject> newmap,list<SObject> oldlist,map<Id,SObject> oldmap) {
        list<OpportunityEOI__c> allocatedEOIs = new list<OpportunityEOI__c>();
        for(OpportunityEOI__c newRecord  : (list<OpportunityEOI__c >) newList){
            OpportunityEOI__c oldRecord = (OpportunityEOI__c)oldMap.get(newRecord.Id);
            if(newRecord.InterestFee__c != null ){
                if(oldRecord.InterestFee__c != newRecord.InterestFee__c ){
                    newRecord.InterestFeeinwords__c = Utilities.amountInWords(newRecord.InterestFee__c,'Dhirams','Fils');
                }
            }else{
                newRecord.InterestFeeinwords__c = '';
            }
            //Auto Reject the EOI if ComplianceStatus__c is rejected
            if( newRecord.ComplianceStatus__c != oldRecord.ComplianceStatus__c && newRecord.ComplianceStatus__c==Constants.STATUS_REJECTED){
                newRecord.Status__c=Constants.STATUS_REJECTED;
            }
            // Create recipt Ack
            system.debug('oldRecord.Status__c ::'+oldRecord.Status__c );
            system.debug('newRecord.Status__c::'+newRecord.Status__c);
            if(newRecord.Status__c != oldRecord.Status__c && newRecord.Status__c == Constants.EOISTATUS_UNITCONFIRMED){
                allocatedEOIs.add(newRecord);
            }
        }

        if(!allocatedEOIs.isEmpty()){
            createPaymentLink(allocatedEOIs);
        }
    }

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        createEOItDocuments((list<OpportunityEOI__c>) newList);
        
    }
    
    //*** After Update Action***//
    public override void afterUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        updateEOIAgreement((list<OpportunityEOI__c>) newList, oldMap);
        
    }
    
    public static void updateEOIAgreement(List<OpportunityEOI__c> opportunityEOIList, Map<Id, SObject> oldMap){
        
        Set<Id> OpportunityEOIIds = new Set<Id>();
        Map<Id,Id> accountIdByEOIMap = new Map<Id,Id>();
        Map<Id,Id> contentDocumentIdByEOIMap = new Map<Id,Id>();
        List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
        
        
        for(OpportunityEOI__c oe : opportunityEOIList){
            if(oe.ComplianceStatus__c == Constants.STATUS_CLEARED && ((OpportunityEOI__c)oldMap.get(oe.Id)).ComplianceStatus__c != Constants.STATUS_CLEARED){
                OpportunityEOIIds.add(oe.Id);
            }
            if(oe.Account__c != null){
                accountIdByEOIMap.put(oe.Account__c, oe.Id);
            }
        }
        
        if(OpportunityEOIIds.isEmpty()) 
            return;
        
        List<Document__c> eoiDocuments = [SELECT Id,ExpressionofInterest__c FROM Document__c 
                                              WHERE DocumentType__c = 'Signed EOI Agreement' AND 
                                              ExpressionofInterest__c IN: OpportunityEOIIds];
        if(eoiDocuments.isEmpty())
            return;
        
        Map<Id,document__c> eoiDocumentMap = new Map<Id,Document__c>(eoiDocuments);
        for(ContentDocumentLink cdl : [SELECT Id,ContentDocumentId,LinkedEntityId  FROM ContentDocumentLink WHERE LinkedEntityId =: eoiDocuments[0].Id]){
            if(eoiDocumentMap.containsKey(cdl.LinkedEntityId)){
                contentDocumentIdByEOIMap.put(eoiDocumentMap.get(cdl.LinkedEntityId).ExpressionofInterest__c,cdl.ContentDocumentId);
            }
        }        
         
        List<Document__c> accountDocuments = [SELECT Id, Account__c, DocumentType__c 
                                              FROM Document__c WHERE DocumentType__c =: Constants.DOCUMENT_TYPE_SIGNED_KYC 
                                              AND Account__c IN: accountIdByEOIMap.keySet()];
        List<ContentDocumentLink> existingContentDocumentLinks = [SELECT Id,ContentDocumentId,LinkedEntityId  FROM ContentDocumentLink WHERE LinkedEntityId =: accountDocuments[0].Id];
        
        for(Document__c doc : accountDocuments ){
            if(accountIdByEOIMap.containsKey(doc.Account__c) && 
               contentDocumentIdByEOIMap.get(accountIdByEOIMap.get(doc.Account__c)) != null){
                   Id contentDocumentId = contentDocumentIdByEOIMap.get(accountIdByEOIMap.get(doc.Account__c));
        		   Id linkedEntityId = doc.Id;
                   
                   // Check if a ContentDocumentLink with the same ContentDocumentId and LinkedEntityId already exists
                   Boolean linkExists = false;
                   for (ContentDocumentLink existingLink : existingContentDocumentLinks) {
                       if (existingLink.ContentDocumentId == contentDocumentId &&
                           existingLink.LinkedEntityId == linkedEntityId) {
                               linkExists = true;
                               break;
                           }
                   }
                   
                   if (!linkExists) {
                       ContentDocumentLink cdl = new ContentDocumentLink();
                       cdl.ContentDocumentId = contentDocumentIdByEOIMap.get(accountIdByEOIMap.get(doc.Account__c));//Add ContentDocumentId
                       cdl.LinkedEntityId = doc.Id;//Add attachment parentId
                       cdl.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                       cdl.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
                       cdlToInsert.add(cdl);
                   }
            }
        } 
        
        if(!cdlToInsert.isEmpty()){
            Insert cdlToInsert;
        }
    }

    public static void createPaymentLink(list<OpportunityEOI__c> opportunityEOIs){
        map<id,ReceiptAcknowledgement__c> expressionofInterestToProcess = new  map<id,ReceiptAcknowledgement__c>();
        List<ReceiptAcknowledgement__c> expressionofInterestToProcessList = new List<ReceiptAcknowledgement__c>();
        for(OpportunityEOI__c tempRecord : opportunityEOIs){
            for(Integer i=1; i<=tempRecord.NumberOfUnits__c; i++){
                if((tempRecord.PaymentMode__c != 'Online' && i == 1) || tempRecord.PaymentMode__c == 'Online'){
                    ReceiptAcknowledgement__c ReceiptAcknowledgement = new ReceiptAcknowledgement__c();
                    ReceiptAcknowledgement.OpportunityEOI__c = tempRecord.id;
                    ReceiptAcknowledgement.Account__c  = tempRecord.Opportunity__r.AccountId;
                    ReceiptAcknowledgement.Contact__c = tempRecord.Opportunity__r.Contact__c;
                    ReceiptAcknowledgement.Opportunity__c = tempRecord.opportunity__c;
                   
                    ReceiptAcknowledgement.Amount__c= (tempRecord.PaymentMode__c != 'Online')? tempRecord.InterestFee__c : tempRecord.InterestFee__c / tempRecord.NumberOfUnits__c ;
                    ReceiptAcknowledgement.PaymentType__c=tempRecord.PaymentMode__c; 
                    expressionofInterestToProcessList.add(ReceiptAcknowledgement); 
                }
            }
        }
        if(!expressionofInterestToProcessList.isEmpty()){
            insert expressionofInterestToProcessList;
        }
         /*   expressionofInterestToProcess.put(tempRecord.id, new ReceiptAcknowledgement__c(OpportunityEOI__c=tempRecord.Id,
                                                                                Account__c=tempRecord.Opportunity__r.AccountId,
                                                                                Contact__c=tempRecord.Opportunity__r.Contact__c,
                                                                                Opportunity__c=tempRecord.opportunity__c,
                                                                                Amount__c=tempRecord.InterestFee__c,
                                                                                PaymentType__c=tempRecord.PaymentMode__c ));
        }
        
        if(!expressionofInterestToProcess.isEmpty()){
            insert expressionofInterestToProcess.values();
        } */
    }

    //Create EOI related documents based on the DocumentPlaceHolder__mdt configuration
    public static void createEOItDocuments(list<OpportunityEOI__c> opportunityEOIs){
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<string,ID> documentRecordTypeMap = new map<string,ID>();
        map<string,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_OPPORTUNITY_EOI});
        map<id,Account> relatedAccountRecords = new map<id,Account>();
        for(OpportunityEOI__c opportunityEOIRec : opportunityEOIs){
            relatedAccountRecords.put(opportunityEOIRec.Account__c,null);
        }
        relatedAccountRecords = new map<id,Account>([select id,RecordTypeId from account where id in :relatedAccountRecords.keySet()]);
        if(!documentMap.isEmpty()){
            for(OpportunityEOI__c opportunityEOIRec : opportunityEOIs){
                
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(Constants.DOCUMENT_PLACEHOLDER_CATEGORY_OPPORTUNITY_EOI)){
                    //skip wealth form for the Organization record types
                    if( (tempMetaRec.DocumentType__c.equalsIgnoreCase(Constants.DOCUMENT_TYPE_WEALTH) || tempMetaRec.DocumentType__c.equalsIgnoreCase(Constants.DOCUMENT_TYPE_SIGNED_WEALTH)) && relatedAccountRecords.containsKey(opportunityEOIRec.Account__c) && relatedAccountRecords.get(opportunityEOIRec.Account__c).RecordTypeId ==Constants.ORGANIZATION_RECORD_TYPE_ID){
                        continue;
                    }
                    string recordTypeID=null;
                    if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    //No existing check as records will be created on insert
                    Document__c documentRecord =new Document__c(DocumentType__c = tempMetaRec.DocumentType__c,
                                                ExpressionofInterest__c = opportunityEOIRec.Id,
                                                RecordtypeId= recordTypeID,
                                                AvailableForExternalUsers__c = tempMetaRec.AvailableForExternalUsers__c,
                                                SendForESign__c= tempMetaRec.eSignRequired__c,
                                                EligibleForeSign__c=tempMetaRec.EligibleForeSign__c,
                                                DocumentPlaceHolderId__c=tempMetaRec.DeveloperName /*,
                                                GenerateDocument__c = (tempMetaRec.GeneratedManually__c != true)*/ );
                    documentListToInsert.add(documentRecord);        
                    
                }
            }
        }
        
        if(!documentListToInsert.isEmpty()){
          insert documentListToInsert;  
        } 
    }
   
}