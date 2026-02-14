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
public class HomeFinanceCaseTriggerHelper {


    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames);
    public static Boolean isByPassCreateDocumentPlaceHolder = false;
    
    @InvocableMethod(label='HomeFinanceCaseTriggerHelper class byPassCreateDocumentPlaceHolder method to avoid document placeholder records')
    public static void byPassCreateDocumentPlaceHolder(List<Id> ids){
        isByPassCreateDocumentPlaceHolder = true;
    }
    /*
    *********************************************************
    @Method Name    : afterInsertHomeFinanceCase
    @author         : 
    @description    : Method to handle after insert of AMC case record
    @param          : newCaseList
    @return         : void
    ********************************************************
    */
    public static void afterInsertHomeFinanceCase(List<Case> newCaseList) {
        List<Case> listCaseToCreateDocumentPlaceHolderForHFCases = new List<Case>();
        for(Case caseRecord : newCaseList) {
            if(caseRecord.RecordTypeId == rtWrapper.homeFinanceRTId) {
                if(!isByPassCreateDocumentPlaceHolder && String.isBlank(caseRecord.ParentId)) {
                    listCaseToCreateDocumentPlaceHolderForHFCases.add(caseRecord);
                }
            }
        }
        if(!listCaseToCreateDocumentPlaceHolderForHFCases.isEmpty()){
            createHomeFinanceDocuments(listCaseToCreateDocumentPlaceHolderForHFCases);
        }
    }
    /*
    *********************************************************
    @Method Name    : afterUpdateHomeFinanceCase
    @author         : 
    @description    : Method to handle after insert of AMC case record
    @param          : newCaseRecords,oldCaseMap
    @return         : void
    ********************************************************
    */
    public static void afterUpdateHomeFinanceCase(List<Case> newCaseRecords, Map<Id, Case> oldCaseMap) {
        Set<Id> setHomeFinnaceCaseIds = new Set<Id>();
        Set<Id> setParentCaseIdToCreateCommission = new Set<Id>();
        for(Case newCase : newCaseRecords) {
            Case oldCase = oldCaseMap.get(newCase.Id);
            if(newCase.RecordTypeId == rtWrapper.homeFinanceRTId) {
                if(newCase.Verified_by_Finance__c && newCase.Verified_by_Finance__c != oldCase.Verified_by_Finance__c){
                    setHomeFinnaceCaseIds.add(newCase.Id);
                }            
                if(newCase.Sum_of_Total_Commission_for_Aldar__c != null && newCase.PaymentReceived__c && newCase.PaymentReceived__c != oldCase.PaymentReceived__c){                   
                    setParentCaseIdToCreateCommission.add(newCase.Id);
                }
            }
        }
        if(!setHomeFinnaceCaseIds.isEmpty()){
            sentEmailToHuspyAfterVerified(setHomeFinnaceCaseIds);
        }        
        if(!setParentCaseIdToCreateCommission.isEmpty()){
            createCommissionRecord (setParentCaseIdToCreateCommission, newCaseRecords);  
        }
    }
    /*
    *********************************************************
    @Method Name    : sentEmailToHuspyAfterVerified
    @author         : 
    @description    : Added By Moh Sarfaraj for BPM-431
    @param          : setVerifiedCaseIds
    @return         : void
    ********************************************************
    */
    public static void sentEmailToHuspyAfterVerified (Set<Id> setVerifiedCaseIds){
        List<String> toRecipents = System.Label.FinanceAfterApprovedCaseEmail.split(',');
        String emailTemplateDeveloperName = Constants.FINANCE_AFTER_APPROVED_EMAILTEMPLATE;
        Map<Id,Attachment> attachmentMap = new Map<Id,Attachment>();
        Set<Id> setToCheckCaseAttachmentTaken = new Set<Id>();
        
        for(Attachment eachAttachment : [SELECT Id,ParentId FROM Attachment WHERE ParentId IN: setVerifiedCaseIds ORDER BY CreatedDate DESC]){
            if(!setToCheckCaseAttachmentTaken.contains(eachAttachment.ParentId)){                
                attachmentMap.put(eachAttachment.Id, eachAttachment);
                setToCheckCaseAttachmentTaken.add(eachAttachment.ParentId);
            }
        }
        // Calling Queueable to sending emails
        if(!attachmentMap.isEmpty() && toRecipents != null && !toRecipents.isEmpty()){
            Integer delayInMinutes = 1;
            System.enqueueJob(new HomeFinanceCaseSubmissionInvocable.FinanceUtilityToSentEmail(attachmentMap, emailTemplateDeveloperName, toRecipents, null), delayInMinutes);
        }
    }
    /*
    *********************************************************
    @Method Name    : createCommissionRecord
    @author         : 
    @description    : Added By Moh Sarfaraj for BPM-460 Home Finance Case
    @param          : setParentCaseIds, newCaseList
    @return         : void
    ********************************************************
    */
    public static void createCommissionRecord (Set<Id> setParentCaseIds, List<Case> newCaseList){
        try{
            final List<String> listCommissionPercentagePot = new List<String>(System.Label.HomeFinanceCommissionPercentValue.split(','));
            List<CommissionLineItem__c> listCLIToInsert = new List<CommissionLineItem__c>();
            
            for(Case eachCase : newCaseList){
                if(setParentCaseIds.contains(eachCase.Id)){
                    CommissionLineItem__c commissionLineItem = new CommissionLineItem__c();
                    commissionLineItem.SalesManager__c = UserInfo.getUserId(); //eachCase.OwnerId;
                    commissionLineItem.CommissionType__c = Constants.INTERNAL;
                    commissionLineItem.Case__c = eachCase.Id;
                    commissionLineItem.CommissionPercentage__c = 0;
                    Double commissionPot = (Double.valueOf(listCommissionPercentagePot[0]) * eachCase?.Sum_of_Total_Commission_for_Aldar__c)/100;
                    commissionLineItem.CommissionAmount__c = (Double.valueOf(listCommissionPercentagePot[1]) * commissionPot)/100;
                    CaseTriggerHandlerNew.newInsertSet.add(commissionLineItem);
                }
            }
        }catch(Exception ex){System.debug('error->'+ex.getMessage());}
    }   
    /*
    *********************************************************
    @Method Name    : createHomeFinanceDocuments
    @author         : 
    @description    : Method used to create home finance document
    @param          : caseRecords
    @return         : 
    ********************************************************
    */
    public static void createHomeFinanceDocuments(List<Case> caseRecords){
        String homeFinanceCase = Constants.HOMEFINANCECASE;
        List<Document__c> documentListToInsert = new List<Document__c>();
        Map<string,Id> documentRecordTypeMap = new Map<String,Id>();
        Map<Id,Case> caseIdToRecMap = new Map<Id,Case>(caseRecords);
        Map<String,List<DocumentPlaceHolder__mdt>> documentMap = 
        DocumentService.getDocumentMetaDataByCategory(new Set<String>{homeFinanceCase});

        if(!documentMap.isEmpty() && !caseIdToRecMap.isEmpty()){
            //get Existing Documents
            Map<String,Document__c> existingDocMap = new Map<String,Document__c>();
            for(Document__c tempDoc : [SELECT Id,DocumentType__c,Case__c FROM Document__c WHERE Case__c IN :caseIdToRecMap.keySet()]){
                existingDocMap.put(tempDoc.Case__c+tempDoc.DocumentType__c, tempDoc);
            }
            for(Case eachCase : caseRecords){
                String documentTypeToProcess; 
                List<DocumentPlaceHolder__mdt> documentsToProcess = new List<DocumentPlaceHolder__mdt>();
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(homeFinanceCase)){
                    string recordTypeID = null;                
                    if(tempMetaRec.RecordTypeDeveloperName__c != null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c, Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID = documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }                    
                    if(!existingDocMap.containsKey(eachCase.Id + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord = new Document__c();// DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'', eachCase.Id, recordTypeID);
                        documentRecord.Case__c = eachCase.Id; 
                        documentRecord.RecordTypeId = recordTypeID;
                        documentRecord.DocumentType__c = tempMetaRec.DocumentType__c;
                        documentRecord.SendForESign__c = tempMetaRec.eSignRequired__c;
                        documentRecord.DocumentPlaceHolderId__c = tempMetaRec.DeveloperName;  
                        documentRecord.EligibleForeSign__c = tempMetaRec.EligibleForeSign__c;
                        CaseTriggerHandlerNew.newInsertSet.add(documentRecord); 
                        existingDocMap.put(eachCase.Id + tempMetaRec.DocumentType__c,documentRecord);       
                    }
                }
            }
        }
    } 
}