/**********************************************************************************************************************
* Name               : SOCancellationSRCreationValidation                                                        
* Description        : Apex class for validation of docuement when user creating SR from Sales Order Cancellation record
* Created By         : Bashim                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           bakhan@aldar.com     12/02/2025      Initial Draft       
******************************************************************************************************************/
public class SOCancellationSRCreationValidation{
    @InvocableMethod(label='Get Validation Message' description='Return the error message')
    public static List<String> validateDocuments(List<Id> lstSoCancellationId){
        List<String> errorMessages = new List<String>();
        Set<Id> soCancellationIds = new Set<Id>();
        soCancellationIds.addAll(lstSoCancellationId);
        Map<Id,List<Document__c>> docMap = DocumentService.getDocumentbySOCancellationId(soCancellationIds);
        List<SalesOrderCancellation__c> lstSOCancellation = [SELECT Id, RefundApplicable__c,Refund_To__c, Cancellation_Status__c, AccountType__c 
                                                             FROM SalesOrderCancellation__c
                                                             WHERE Id IN : lstSoCancellationId];
        List<Document__c> docList = new  List<Document__c>();
        if(docMap.get(lstSOCancellation[0].Id) != null && docMap.containsKey(lstSOCancellation[0].Id)){
            docList = docMap.get(lstSOCancellation[0].Id);
        }
        for(Document__c thisDoc : docList){
            if(thisDoc.DocumentType__c.equalsIgnoreCase(SalesOrderCancellationConstants.SALES_ORDER_CANCELLATION_IBAN_LATTER) && lstSOCancellation[0].AccountType__c.equalsIgnoreCase(SalesOrderCancellationConstants.ACCOUNT_TYPE_PERSON)){
                // changes the if condition, to check the document is there or not : Bashim
                if(!thisDoc.Status__c.equalsIgnoreCase(SalesOrderCancellationConstants.DOCUMENT_STATUS_UPLOADED) || thisDoc.ContentDocumentLinks == null || thisDoc.ContentDocumentLinks.isEmpty()){
                    errorMessages.add(Label.IBANLatterUploadSOCancellation);
                    return errorMessages;
                }
            }
            if(thisDoc.DocumentType__c.equalsIgnoreCase(SalesOrderCancellationConstants.SALES_ORDER_CANCELLATION_TRADE_LICENSE) && lstSOCancellation[0].AccountType__c.equalsIgnoreCase(SalesOrderCancellationConstants.ACCOUNT_TYPE_ORGANIZATION)){
                // changes the if condition, to check the document is there or not : Bashim
                if(!thisDoc.Status__c.equalsIgnoreCase(SalesOrderCancellationConstants.DOCUMENT_STATUS_UPLOADED) || thisDoc.ContentDocumentLinks == null || thisDoc.ContentDocumentLinks.isEmpty()){
                    errorMessages.add(Label.TradeLicenseUploadSOCancellation);
                    return errorMessages;
                }
            }
            
            if(thisDoc.DocumentType__c.equalsIgnoreCase(SalesOrderCancellationConstants.SALES_ORDER_CANCELLATION_NATIONALID_PASSPORT) && lstSOCancellation[0].AccountType__c.equalsIgnoreCase(SalesOrderCancellationConstants.ACCOUNT_TYPE_PERSON)){
                // changes the if condition, to check the document is there or not : Bashim
                if(!thisDoc.Status__c.equalsIgnoreCase(SalesOrderCancellationConstants.DOCUMENT_STATUS_UPLOADED) || thisDoc.ContentDocumentLinks == null || thisDoc.ContentDocumentLinks.isEmpty()){ errorMessages.add(Label.NationalIdPassportUploadSOCancellation);return errorMessages;
                }
            }
            
            
            if(lstSOCancellation[0].Refund_To__c != null && lstSOCancellation[0].Refund_To__c.equalsIgnoreCase(SalesOrderCancellationConstants.SALES_ORDER_CANCELLATION_THIRD_PARTY)){
                if(thisDoc.DocumentType__c.equalsIgnoreCase(SalesOrderCancellationConstants.SALES_ORDER_CANCELLATION_NOC)){
                    // changes the if condition, to check the document is there or not : Bashim
                    if(!thisDoc.Status__c.equalsIgnoreCase(SalesOrderCancellationConstants.DOCUMENT_STATUS_UPLOADED) || thisDoc.ContentDocumentLinks == null || thisDoc.ContentDocumentLinks.isEmpty()){ errorMessages.add(Label.ThirdPartyNOCUploadSOCancellation); return errorMessages;
                    }
                }
            }
        }
        return errorMessages;
    }
    
}