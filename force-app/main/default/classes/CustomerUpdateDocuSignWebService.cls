/*
* Name               : CustomerUpdateDocuSignWebService
* Description        : This class is used to Updtae DocuSign Status
*/
@RestResource (urlMapping = '/customer/updatedocusign')
global without sharing class CustomerUpdateDocuSignWebService {
    
    @HTTPPost
    global static void doPost(String customerId, String documentId, String referenceId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = UpdateDocuSign(customerId, documentId);
            handler.response.success = true;
            handler.finalize();
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    
    public static String UpdateDocuSign(String customerId, String documentId) {

        Boolean isSuccess = false;

        if (((Id)documentId).getSObjectType() == Document__c.getSObjectType()) {
            // Add the document's DocuSign envelope Id so that a sign document will be attached to the sign placeholder after the document has been signed
            Document__c document = CustomerServiceUtility.getDocumentDetail(' (Id = \'' + documentId + '\') ')[0];
            String documentType = document.DocumentType__c.containsIgnoreCase('spa') ? Constants.DOCUMENT_TYPE_ALDAR_SIGNED_SPA : Constants.DOCUMENT_TYPE_PREFIX_SIGNED + ' ' + document.DocumentType__c;
            
            String docWhereClause = ' (Account__c = \'' + customerId + '\' AND DocumentType__c = \'' + documentType + '\') ';
            if (String.isNotBlank(document.SalesOrder__c)) {
                docWhereClause = ' (SalesOrder__c = \'' + document.SalesOrder__c + '\' AND DocumentType__c = \'' + documentType + '\') ';
            } else if (String.isNotBlank(document.Case__c)) {
                docWhereClause = ' (Case__c = \'' + document.Case__c + '\' AND DocumentType__c = \'' + documentType + '\') ';
            }

            List<Document__c> signedDocument = CustomerServiceUtility.getDocumentDetail(docWhereClause);
            if (!signedDocument.isEmpty()) {
                signedDocument[0].Status__c = CustomerAPIConstants.DOCUMENT_STATUS_DOCUSIGN_PENDING;
                update signedDocument[0];

                isSuccess = true;
            }
        } else if (((Id)documentId).getSObjectType() == HexaBPM__SR_Doc__c.getSObjectType()) {
            HexaBPM__SR_Doc__c srDoc = CustomerServiceUtility.getSRDocDetail(' (Id = \'' + documentId + '\') ')[0];

            List<String> likedSignedStringList = new List<String>();
            likedSignedStringList.add(Constants.DOCUMENT_TYPE_PREFIX_SIGNED + '_' + srDoc.DocumentMasterCode__c);
            likedSignedStringList.add(Constants.DOCUMENT_TYPE_PREFIX_SIGNED + '' + srDoc.DocumentMasterCode__c);
            likedSignedStringList.add(Constants.DOCUMENT_TYPE_PREFIX_SIGNED + ' ' + srDoc.DocumentMasterCode__c);
            String likedSignedString = String.join(likedSignedStringList, '\',\'');
            String whrClause = ' DocumentMasterCode__c IN (\'' + likedSignedString + '\') ';

            List<HexaBPM__SR_Doc__c> updateSignedSRDoc = CustomerServiceUtility.getSRDocDetail(' (' + whrClause + ' AND HexaBPM__Service_Request__c = \'' + srDoc.HexaBPM__Service_Request__c + '\') ');
            if (!updateSignedSRDoc.isEmpty()) {
                updateSignedSRDoc[0].HexaBPM__Status__c = CustomerAPIConstants.DOCUMENT_STATUS_DOCUSIGN_PENDING;
                update updateSignedSRDoc[0];
                
                isSuccess = true;
            }
        }

        if (isSuccess) {
            return CustomerAPIConstants.RETURN_SUCCESS;
        }
        return CustomerAPIConstants.RETURN_ERROR;
    }
}