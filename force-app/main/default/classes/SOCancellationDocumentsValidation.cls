/**********************************************************************************************************************
* Name               : SOCancellationDocumentsValidation                                                        
* Description        : Handler to for Sales Order Cancellation record document level validation
* Created By         : Harsh@Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     18/03/2024      Initial Draft       
******************************************************************************************************************/
public with sharing class SOCancellationDocumentsValidation{
    
    public static void validateDocumentUpload(Map<Id, sObject> oldMap, List<sObject> newList){
        // Added for unit cancellation, filter list was removing record from newlist : Bashim
        oldMap = Trigger.oldMap;
        newList = Trigger.new;
        if(oldMap.size() > 0){
            Set<Id> recordIdSet = new Set<Id>();
            for(SalesOrderCancellation__c newRecord : (List<SalesOrderCancellation__c >) newList){
                if(newRecord.RefundApplicable__c && (newRecord.AccountType__c.equalsIgnoreCase(SalesOrderCancellationConstants.ACCOUNT_TYPE_PERSON) || newRecord.AccountType__c.equalsIgnoreCase(SalesOrderCancellationConstants.ACCOUNT_TYPE_ORGANIZATION)) 
                   && String.isNotBlank(newRecord.Cancellation_Status__c) && (newRecord.Cancellation_Status__c.equalsIgnoreCase(SalesOrderCancellationConstants.SALES_ORDER_CANCELLATION_AWAITING_APPROVAL))){
                       recordIdSet.add(newRecord.Id);
                   }                	
            }
            if(!recordIdSet.isEmpty()){
                Map<Id,List<Document__c>> docMap = DocumentService.getDocumentbySOCancellationId(recordIdSet); 
                for(SalesOrderCancellation__c newRecord : (List<SalesOrderCancellation__c >) newList){
                    SalesOrderCancellation__c oldRecord = (SalesOrderCancellation__c) oldMap.get(newRecord.Id);
                    List<Document__c> docList = docMap.get(newRecord.Id);
                    for(Document__c thisDoc : docList){
                        if(thisDoc.DocumentType__c.equalsIgnoreCase(SalesOrderCancellationConstants.SALES_ORDER_CANCELLATION_IBAN_LATTER) && newRecord.AccountType__c.equalsIgnoreCase(SalesOrderCancellationConstants.ACCOUNT_TYPE_PERSON)){
                            // changes the if condition, to check the document is there or not : Bashim
                            if(!thisDoc.Status__c.equalsIgnoreCase(SalesOrderCancellationConstants.DOCUMENT_STATUS_UPLOADED) || thisDoc.ContentDocumentLinks == null || thisDoc.ContentDocumentLinks.isEmpty()){
                                newRecord.addError(Label.IBANLatterUploadSOCancellation);
                            }
                        }
                        if(thisDoc.DocumentType__c.equalsIgnoreCase(SalesOrderCancellationConstants.SALES_ORDER_CANCELLATION_TRADE_LICENSE) && newRecord.AccountType__c.equalsIgnoreCase(SalesOrderCancellationConstants.ACCOUNT_TYPE_ORGANIZATION)){
                            // changes the if condition, to check the document is there or not : Bashim
                            if(!thisDoc.Status__c.equalsIgnoreCase(SalesOrderCancellationConstants.DOCUMENT_STATUS_UPLOADED) || thisDoc.ContentDocumentLinks == null || thisDoc.ContentDocumentLinks.isEmpty()){
                                newRecord.addError(Label.TradeLicenseUploadSOCancellation);
                            }
                        }                       
                        if(thisDoc.DocumentType__c.equalsIgnoreCase(SalesOrderCancellationConstants.SALES_ORDER_CANCELLATION_NATIONALID_PASSPORT) && newRecord.AccountType__c.equalsIgnoreCase(SalesOrderCancellationConstants.ACCOUNT_TYPE_PERSON)){
                            // changes the if condition, to check the document is there or not : Bashim
                            if(!thisDoc.Status__c.equalsIgnoreCase(SalesOrderCancellationConstants.DOCUMENT_STATUS_UPLOADED) || thisDoc.ContentDocumentLinks == null || thisDoc.ContentDocumentLinks.isEmpty()){
                                newRecord.addError(Label.NationalIdPassportUploadSOCancellation);
                            }
                        }                    
                        if(newRecord.Refund_To__c != null && newRecord.Refund_To__c.equalsIgnoreCase(SalesOrderCancellationConstants.SALES_ORDER_CANCELLATION_THIRD_PARTY)){
                            if(thisDoc.DocumentType__c.equalsIgnoreCase(SalesOrderCancellationConstants.SALES_ORDER_CANCELLATION_NOC)){
                                // changes the if condition, to check the document is there or not : Bashim
                                if(!thisDoc.Status__c.equalsIgnoreCase(SalesOrderCancellationConstants.DOCUMENT_STATUS_UPLOADED) || thisDoc.ContentDocumentLinks == null || thisDoc.ContentDocumentLinks.isEmpty()){
                                    newRecord.addError(Label.ThirdPartyNOCUploadSOCancellation);
                                }
                            }
                        }
                    }
                }
            }
        }   
    }    
}