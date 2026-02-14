/**********************************************************************************************************************
* Name               : InstallmentLinesTriggerHandler                                                        
* Description        : This class contains all the helper methods for the InstallmentLines__c Trigger
* Usage              : InstallmentLinesTrigger
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                    Date            Comment                                                                       
* 1.0           @pwc.com               21 May 2022      Initial Draft
* 2.0           rmohmmed@aldar.com     25th Aug2023     Update payment settlement date when outstanding amount less then 100 
******************************************************************************************************************/
public with sharing class InstallmentLinesTriggerHandler  extends TriggerHandler {
	//*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        map<id,InstallmentLines__c> installmentLineMap = new map<id,InstallmentLines__c>();
        Set<Id> installmentLineIds = new Set<Id>();
        List<InstallmentLines__c> installmentLineLPCSync = new List<InstallmentLines__c>();
        for(InstallmentLines__c newRecord  : (list<InstallmentLines__c >) newList){
            InstallmentLines__c oldRecord = (InstallmentLines__c) oldMap.get(newRecord.ID);
           //if( newRecord.InvoicedAmount__c!=null && newRecord.InstallmentAmount__c!=null && (newRecord.InvoicedAmount__c != oldRecord.InvoicedAmount__c || newRecord.InstallmentAmount__c != oldRecord.InstallmentAmount__c ) && (newRecord.InvoicedAmount__c >= newRecord.InstallmentAmount__c || ( (newRecord.InstallmentAmount__c - newRecord.InvoicedAmount__c) < Integer.valueOf(System.Label.CommissionAmountBuffer) ) )  ){
            if( newRecord.InvoicedAmount__c!=null && newRecord.InstallmentAmount__c!=null && (newRecord.InvoicedAmount__c != oldRecord.InvoicedAmount__c || newRecord.InstallmentAmount__c != oldRecord.InstallmentAmount__c ) && (newRecord.InvoicedAmount__c >= newRecord.InstallmentAmount__c || ((newRecord.Account_Resident_Status__c =='Resident' && (newRecord.InstallmentAmount__c - newRecord.InvoicedAmount__c) < Integer.valueOf(System.Label.CommissionAmountBuffer) ) || (newRecord.Account_Resident_Status__c =='Non-Resident' && (newRecord.InstallmentAmount__c - newRecord.InvoicedAmount__c) < Integer.valueOf(System.Label.CommissionIntAmountBuffer) ) ) )  ){
                installmentLineMap.put(newRecord.Id,newRecord);
            }
            if(newRecord.LPCFreezeDate__c != oldRecord.LPCFreezeDate__c || newRecord.LPCFreezeUntilDate__c != oldRecord.LPCFreezeUntilDate__c || (newRecord.LPCFreezeDateSyncStatus__c == 'In Progress' && newRecord.LPCFreezeDateSyncStatus__c != oldRecord.LPCFreezeDateSyncStatus__c )){
                installmentLineLPCSync.add(newRecord);
            }
            if(newRecord.InvoicedAmount__c != null && newRecord.InstallmentAmount__c !=null && (newRecord.InvoicedAmount__c != oldRecord.InvoicedAmount__c)
               && (newRecord.InstallmentAmount__c - newRecord.InvoicedAmount__c) < 100) {            
                    installmentLineIds.add(newRecord.Id);
                
            }
        }
        if(!installmentLineMap.isEmpty()){
            createCommissionLineDocuments(installmentLineMap);
        }
        
        if(!installmentLineIds.isEmpty()) {
            updateHandOverDate(installmentLineIds);
        }
        if(!installmentLineLPCSync.isEmpty()) {
        	LPCCalloutHelper.prepareDataForERPSync(installmentLineLPCSync);
        }
    }
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) { 
        LPCCalloutHelper.prepareDataForERPSync((List<InstallmentLines__c >)newList);
    }
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) { 
        //newRecord.OutstandingAmountinwords__c
        for(InstallmentLines__c newRecord  : (list<InstallmentLines__c >) newList){
            if(newRecord.InstallmentAmount__c != null ){
                if(newRecord.InvoicedAmount__c != null){
                    newRecord.OutstandingAmountinwords__c = Utilities.amountInWords((newRecord.InstallmentAmount__c - newRecord.InvoicedAmount__c), 'dirhams','fils');
                }else{
                     newRecord.OutstandingAmountinwords__c = Utilities.amountInWords(newRecord.InstallmentAmount__c , 'dirhams','fils');
                }
                if(newRecord.AmountReceived__c != null ){
                    newRecord.OutstandingAmountToReceiveInWords__c = Utilities.amountInWords((newRecord.InstallmentAmount__c - newRecord.AmountReceived__c ) , 'dirhams','fils');
                }else{
                    newRecord.OutstandingAmountToReceiveInWords__c = Utilities.amountInWords(newRecord.InstallmentAmount__c , 'dirhams','fils');
                }
            }
        }
    }
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        for(InstallmentLines__c newRecord  : (list<InstallmentLines__c >) newList){
            InstallmentLines__c oldRecord = (InstallmentLines__c)oldMap.get(newRecord.Id);
            //If installment date is changed
            if(newRecord.InstallmentDate__c != oldRecord.InstallmentDate__c && oldRecord.InstallmentDate__c!=null && newRecord.OriginalInstallmentDate__c ==null){
                newRecord.OriginalInstallmentDate__c = oldRecord.InstallmentDate__c;
            }
            
             if(newRecord.InstallmentDate__c!=oldRecord.InstallmentDate__c &&  
                   newRecord.InstallmentDate__c!=null &&
                   newRecord.InstallmentDate__c>=newRecord.ExtensionDate__c){
                   newRecord.ExtensionDate__c=null;
                }   
            
            if(newRecord.InstallmentAmount__c != null ){ 
                
                           
                if(newRecord.InvoicedAmount__c != null){
                    if(oldRecord.InstallmentAmount__c != newRecord.InstallmentAmount__c || 
                       oldRecord.InvoicedAmount__c != newRecord.InvoicedAmount__c){
                           newRecord.OutstandingAmountinwords__c = Utilities.amountInWords((newRecord.InstallmentAmount__c - newRecord.InvoicedAmount__c), 'dirhams','fils');
                       }
                }else{
                    if(oldRecord.InstallmentAmount__c != newRecord.InstallmentAmount__c){
                        newRecord.OutstandingAmountinwords__c = Utilities.amountInWords(newRecord.InstallmentAmount__c , 'dirhams','fils');
                    }
                }
                if(newRecord.AmountReceived__c != null){
                    if(oldRecord.InstallmentAmount__c != newRecord.InstallmentAmount__c || 
                       oldRecord.AmountReceived__c != newRecord.AmountReceived__c){
                           newRecord.OutstandingAmountToReceiveInWords__c = Utilities.amountInWords((newRecord.InstallmentAmount__c - newRecord.AmountReceived__c), 'dirhams','fils');
                       }
                } else{
                    if(oldRecord.InstallmentAmount__c != newRecord.InstallmentAmount__c){
                        newRecord.OutstandingAmountToReceiveInWords__c = Utilities.amountInWords(newRecord.InstallmentAmount__c , 'dirhams','fils');
                    }
                }
            }
        }
    }

    //This method is used to create commission placeholder + update the status to Ready for submission
    public static void createCommissionLineDocuments(map<id,InstallmentLines__c> installmentLineMap){
        map<id,CommissionLineItem__c > relatedCommisionRecords = new map<id,CommissionLineItem__c >([select id,Status__c,Name,SalesOrder__r.Status__c,BrokerAgency__c from CommissionLineItem__c where InstallmentLine__c  in :installmentLineMap.keySet()  ]);
        map<ID,ID> agencyIdToAdminMap = new map<ID,ID>();
        for(CommissionLineItem__c commissionRecord : relatedCommisionRecords.values()){
            if(commissionRecord.BrokerAgency__c!=null){
                agencyIdToAdminMap.put(commissionRecord.BrokerAgency__c,null);
            }
        }
        for(user tempU : [select id,accountId from User where accountId in :agencyIdToAdminMap.keySet() and isActive=true and Profile.Name in (:Constants.AGENCY_ADMIN_PROFILE,:Constants.AGENCY_ADMIN_PROFILE_LOGIN) ]){
            agencyIdToAdminMap.put(tempU.accountId,tempU.Id);
        }
        list<CommissionLineItem__c> updateRelatedCommisionRecords = new list<CommissionLineItem__c>();
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<string,ID> documentRecordTypeMap = new map<string,ID>();
        map<string,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_COMMISSION_INVOICE});
        if(!documentMap.isEmpty()){
            //get Existing Documents
            map<string,Document__c> existingDocMap = new map<string,Document__c>();
            for(Document__c tempDoc : [select id,DocumentType__c,CommissionLineItem__c from Document__c where CommissionLineItem__c in :relatedCommisionRecords.keySet()]){
                    existingDocMap.put(tempDoc.CommissionLineItem__c+tempDoc.DocumentType__c,tempDoc);
            }
			for(CommissionLineItem__c commissionRecord : relatedCommisionRecords.values()){
                if(commissionRecord.Status__c == Constants.COMMISSION_LINE_STATUS_NOT_READY && commissionRecord.SalesOrder__r.Status__c == Constants.SO_STATUS_SOLD){

                    for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(Constants.DOCUMENT_PLACEHOLDER_CATEGORY_COMMISSION_INVOICE)){
                        string recordTypeID=null;
                        if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                            if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                                documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                            }
                            recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                        }
                        if(!existingDocMap.containsKey( commissionRecord.Id + tempMetaRec.DocumentType__c)){
                            Document__c documentRecord =new Document__c(DocumentType__c = tempMetaRec.DocumentType__c,
                                                        CommissionLineItem__c = commissionRecord.Id,
                                                        AvailableForExternalUsers__c=true,
                                                        RecordtypeId= recordTypeID/*,
                                                        GenerateDocument__c=tempMetaRec.GeneratedManually__c*/ );
                            documentListToInsert.add(documentRecord); 
                            
                            
                            
                        }
                       
                    }
                    if(commissionRecord.Status__c == Constants.COMMISSION_LINE_STATUS_NOT_READY && commissionRecord.SalesOrder__r.Status__c == Constants.SO_STATUS_SOLD){
                        commissionRecord.Status__c = CONSTANTS.COMMISSION_LINE_STATUS_READY_FORE_SUBMISSION;
                        commissionRecord.InvoiceDate__c = system.today();
                        commissionRecord.InvoiceNumber__c = '1';
                        if(agencyIdToAdminMap.containsKey(commissionRecord.BrokerAgency__c) && agencyIdToAdminMap.get(commissionRecord.BrokerAgency__c)!=null){
                            commissionRecord.AgencyAdmin__c = agencyIdToAdminMap.get(commissionRecord.BrokerAgency__c);
                        }
                        updateRelatedCommisionRecords.add(commissionRecord);
                    }
                }
            }
        }
        if(!documentListToInsert.isEmpty()){
          insert documentListToInsert;  
        } 
        if(!updateRelatedCommisionRecords.isEmpty()){
            update updateRelatedCommisionRecords;
        }
    }
    
    /**
     * @description update handover payment settlement date when outstanding amount less then 100
     * @author rmohmmed@aldar.com | 08-25-2023 | Story Number
     * @param installmentLineIds
     **/
    public static void updateHandOverDate(Set<Id> installmentLineIds) {
		List<InstallmentLines__c> installmentLines = [SELECT Id, (SELECT Id, InstallmentLine__c, SalesOrderOtherCharges__c, ReceiptAcknowledgement__r.ClearedDate__c FROM Receipt_Allocations__r WHERE ReceiptAcknowledgement__r.ClearedDate__c != null and AmountApplied__c > 0 ORDER BY ReceiptAcknowledgement__r.ClearedDate__c DESC LIMIT 1), (SELECT Id FROM HandoverDetails__r) FROM InstallmentLines__c WHERE Id IN :installmentLineIds];
		List<HandoverDetails__c> handoverDetails = new List<HandoverDetails__c>();
        
        for(InstallmentLines__c line : installmentLines) {
            if(!line.Receipt_Allocations__r.isEmpty() && line.Receipt_Allocations__r[0].ReceiptAcknowledgement__c != null && line.Receipt_Allocations__r[0].ReceiptAcknowledgement__r.ClearedDate__c != null) {
                if(!line.HandoverDetails__r.isEmpty()) {
                    HandoverDetails__c handoverDetail = line.HandoverDetails__r[0];
                    handoverDetail.Payment_Settlement_Date__c = line.Receipt_Allocations__r[0].ReceiptAcknowledgement__r.ClearedDate__c;
                    handoverDetails.add(handoverDetail);
                }
            }
        }
        
        if(!handoverDetails.isEmpty()) {
            update handoverDetails;
        }
    }
}