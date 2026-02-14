/*
* Name               : CustomerDocumentDataWebService
* Description        : This class is used to get document file data(base 64)
*/
@RestResource (urlMapping = '/customer/documentdata')
global without sharing class CustomerDocumentDataWebService {
    
    @HTTPPost
    global static void doPost(String documentId, String referenceId,String multipleDocument){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            if(multipleDocument =='Yes'){
                List<DocumentQueryModel> documentQueryModel = getDocumentBase64(documentId, referenceId,multipleDocument);
                if (documentQueryModel.size() ==0) {
                    handler.response.success = false;
                    handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                    handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
                } else {
                    handler.response.success = true;
                    handler.response.data = documentQueryModel;
                }
            }else{
                DocumentQueryModel documentQueryModel = getDocumentBase64(documentId, referenceId,multipleDocument)[0];
            
            if (documentQueryModel == null) {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            } else {
                handler.response.success = true;
                handler.response.data = documentQueryModel;
            }
            }
            handler.finalize();
        } catch(Exception ex){
            System.debug('ex'+ex.getMessage()+ex.getLineNumber());
            handler.response.success = false; handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR; handler.finalize(ex);
        }
    }

    public static List<DocumentQueryModel> getDocumentBase64(String documentId, String referenceId,String multipleDocument) {

        Account acc = [SELECT Id FROM Account WHERE PersonEmail =: referenceId AND MergedAccount__c = false AND Blacklisted__c = false LIMIT 1];

        List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwnerWithEmail(referenceId);
        String soIdsStr = String.join(soIds, '\',\'');
        
        String salesOrderWhrClause = '';
        if (!soIds.isEmpty()) {
            salesOrderWhrClause = ' (Account__r.PersonEmail = \'' + referenceId + '\' OR Id IN (\'' + soIdsStr + '\')) AND ';
        } else {
            salesOrderWhrClause = ' (Account__r.PersonEmail = \'' + referenceId + '\') AND ';
        }
        salesOrderWhrClause += ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';

        String query = 'SELECT Id FROM SalesOrder__c WHERE ' + salesOrderWhrClause;
        List<Id> soIdList = new List<Id>();
        for(SalesOrder__c so: Database.query(query)) {
            soIdList.add(so.Id);
        }

        String accountId = '';
        String salesOrderId = '';
        if (((Id)documentId).getSObjectType() == Document__c.getSObjectType()) {
            Document__c doc = CustomerServiceUtility.getDocumentDetail(' Id = \'' + documentId + '\' ')[0];
            if (doc.SalesOrder__c != null) {
                salesOrderId = doc.SalesOrder__c;
                
                String whareClause = ' (SalesOrder__c = \'' + doc.SalesOrder__c + '\' AND RecordType.Name = \'' + Constants.PROPERTY_TRANSFER_RT + '\') ORDER BY LastModifiedDate DESC LIMIT 1';
                List<HexaBPM__Service_Request__c> srList = CustomerServiceUtility.getServiceRequestDetail(whareClause);
                if (!srList.isEmpty()) {
                    for (HexaBPM__SR_Doc__c srDoc: srList[0].HexaBPM__SR_Docs__r) {
                        documentId = doc.DocumentType__c.contains(CustomerAPIConstants.DOCUMENT_SIGNED_SPA) && srDoc.Name == CustomerAPIConstants.DOC_SPA_ALDAR_COPY ? srDoc.Id : doc.DocumentType__c.containsIgnoreCase('spa') && !doc.DocumentType__c.containsIgnoreCase(CustomerAPIConstants.DOCUMENT_SPA_DELIVERY_LETTER) && srDoc.Name == CustomerAPIConstants.DOC_SPA_CUSTOMER_COPY ? srDoc.Id : documentId;
                    }
                }
            } else {
                accountId = doc.Account__c;
            }
        } else if (((Id)documentId).getSObjectType() == HexaBPM__SR_Doc__c.getSObjectType()) {
            HexaBPM__SR_Doc__c doc = [SELECT Id, HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.SalesOrder__c FROM HexaBPM__SR_Doc__c WHERE Id =: documentId];
            salesOrderId = doc.HexaBPM__Service_Request__r.SalesOrder__c;
        }
        if (soIdList.size()>0 && soIdList.contains(salesOrderId) ){
            if ((String.isNotBlank(salesOrderId) && !soIdList.contains(salesOrderId)) || (String.isNotBlank(accountId) && accountId != acc.Id) || (String.isBlank(salesOrderId) && String.isBlank(accountId))) {
                return null;
            }
        }
        if(multipleDocument =='Yes'){
            List<ContentVersion> cv = new List<ContentVersion>();
           
                List<ContentDocumentLink> documentLink = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: documentId 
                                                        AND (NOT ContentDocument.Title LIKE 'CertificateOfCompletion%') ORDER BY SystemModstamp DESC];
                Set<Id>contentIds = new Set<Id>();
                
                if (documentLink.size() > 0) {
                    for(ContentDocumentLink cn :documentLink){
                        contentIds.add(cn.ContentDocumentId);
                    }
                    cv = [SELECT Id, FileExtension, Title, VersionData, ContentSize, CreatedDate, LastModifiedDate FROM ContentVersion WHERE 
                            ContentDocumentId =: contentIds AND IsLatest = true];
                }
            Map<Id,List<ContentDistribution>> contentDistributionMap = new Map<Id,List<ContentDistribution>>();
            for(ContentDistribution con:[SELECT Id, ContentDownloadUrl,ContentVersionId FROM ContentDistribution WHERE RelatedRecordId =: documentId AND ContentVersionId =: cv]){
                if(contentDistributionMap.containsKey(con.ContentVersionId)){
                    List<ContentDistribution> contentList =contentDistributionMap.get(con.ContentVersionId);
                    contentList.add(con);
                    contentDistributionMap.put(con.ContentVersionId,contentList);
                }else{
                    List<ContentDistribution> contentList = new List<ContentDistribution>();
                    contentList.add(con);
                    contentDistributionMap.put(con.ContentVersionId,contentList);
                }
            }
            List<DocumentQueryModel> docQueryList = new List<DocumentQueryModel>();
            for(ContentVersion cvv :cv){
                DocumentQueryModel documentQueryModel = new DocumentQueryModel();
                documentQueryModel.fileExtension = cvv.FileExtension;
                documentQueryModel.title = cvv.Title;
                documentQueryModel.contentVersionId = cvv.Id;

                Decimal fileSizeForCustomerPortalApp = Decimal.valueOf(Utilities.getConstant('FileSizeForCustomerPortalApp').ConstantValue__c);
                Decimal fileSize = fileSizeForCustomerPortalApp * 1024 * 1024;

                if (cvv.ContentSize > fileSize || Test.isRunningTest()) {
                    List<ContentDistribution> contentDistributionList = contentDistributionMap.get(cvv.Id) == null ?new List<ContentDistribution>() : contentDistributionMap.get(cvv.Id);
                    ContentDistribution contentDistribution = new ContentDistribution();
                    if (contentDistributionList.isEmpty()) {
                        contentDistribution = ContentDocumentLinkTriggerHandler.createContentDistribution(cvv.Id, documentId);
                        contentDistribution.Name = cvv.Title;
                        insert contentDistribution;
                        contentDistribution = [SELECT Id, ContentDownloadUrl FROM ContentDistribution WHERE Id =: contentDistribution.Id LIMIT 1];
                    } else {
                        contentDistribution = contentDistributionList[0];
                    }
                    documentQueryModel.documentURL = contentDistribution.ContentDownloadUrl;
                } else {
                    documentQueryModel.fileData = cvv.VersionData;
                }
                docQueryList.add(documentQueryModel);

            }
            return docQueryList;
        }else{
            List<DocumentQueryModel> docQueryList = new List<DocumentQueryModel>();
            ContentVersion cv = CustomerServiceUtility.getContentVersion(documentId);
            
            DocumentQueryModel documentQueryModel = new DocumentQueryModel();
            documentQueryModel.fileExtension = cv.FileExtension;
            documentQueryModel.title = cv.Title;
            documentQueryModel.contentVersionId = cv.Id;

            Decimal fileSizeForCustomerPortalApp = Decimal.valueOf(Utilities.getConstant('FileSizeForCustomerPortalApp').ConstantValue__c);
            Decimal fileSize = fileSizeForCustomerPortalApp * 1024 * 1024;
            if (cv.ContentSize > fileSize || Test.isRunningTest()) {
                List<ContentDistribution> contentDistributionList = [SELECT Id, ContentDownloadUrl FROM ContentDistribution WHERE RelatedRecordId =: documentId AND ContentVersionId =: cv.Id LIMIT 1];
                ContentDistribution contentDistribution = new ContentDistribution();
                if (contentDistributionList.isEmpty()) {
                    contentDistribution = ContentDocumentLinkTriggerHandler.createContentDistribution(cv.Id, documentId);
                    contentDistribution.Name = cv.Title;
                    insert contentDistribution;
                    contentDistribution = [SELECT Id, ContentDownloadUrl FROM ContentDistribution WHERE Id =: contentDistribution.Id LIMIT 1];
                } else {
                    contentDistribution = contentDistributionList[0];
                }
                documentQueryModel.documentURL = contentDistribution.ContentDownloadUrl;
            } else {
                documentQueryModel.fileData = cv.VersionData;
            }
            docQueryList.add(documentQueryModel);
            return docQueryList;
        }
    }
}