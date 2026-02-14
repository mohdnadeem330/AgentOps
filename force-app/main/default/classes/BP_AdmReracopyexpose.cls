@RestResource(urlMapping='/agentAdmReraCopy')
global without sharing class BP_AdmReracopyexpose extends BP_BaseRestResource {

    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        Map<String, String> params = RestContext.request.params;
        String requestBody = RestContext.request.requestBody.toString();

        if (!String.isEmpty(requestBody)) {
            BP_AdmReracopyexpose service = new BP_AdmReracopyexpose();
            ApiResponse response = service.processRequest(params, requestBody);

            handler.response.data = response.data;
            handler.response.success = response.success;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;
        } else {
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = 'Invalid Request Body';
        }

        handler.finalize();
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        Map<String, Object> requestBodyData = parseRequestBody(requestBody);
        String contactId = (String) requestBodyData.get('contactId');

        if (String.isEmpty(contactId)) {
            return new ApiResponse(false, 400, 'Missing contactId', null);
        }

        Map<String, Object> docInfo = getDocuments(contactId);
        Map<String, String> documents = (Map<String, String>) docInfo.get('documents');

        if (documents == null || documents.isEmpty()) {
            return new ApiResponse(false, 404, 'Documents not fetched for the given contactId', null);
        }

        return new ApiResponse(true, 200, 'Documents fetched successfully', docInfo);
    }

    public static Map<String, Object> getDocuments(String contactId) {
        Map<String, String> documentMap = new Map<String, String>();
        Map<String, DateTime> lastModifiedDateMap = new Map<String, DateTime>();
        Map<String, Object> response = new Map<String, Object>();

        if (!String.isEmpty(contactId)) {
            Set<String> documentNames = new Set<String>{'ADM Card', 'RERA Broker Card'};

            List<Document__c> docs = [
                SELECT Id, Name, DocumentType__c, Contact__c
                FROM Document__c
                WHERE Contact__c = :contactId
                AND DocumentType__c IN :documentNames
            ];

            // Extract only the Ids
            Set<Id> docIds = new Set<Id>();
            for (Document__c doc : docs) {
                docIds.add(doc.Id);
            }

            Map<Id, Id> docToContentDocMap = new Map<Id, Id>();
            if (!docIds.isEmpty()) {
                for (ContentDocumentLink cdl : [
                    SELECT ContentDocumentId, LinkedEntityId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN :docIds
                ]) {
                    docToContentDocMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                }
            }

            Set<Id> contentDocIds = new Set<Id>(docToContentDocMap.values());

            Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
            if (!contentDocIds.isEmpty()) {
                for (ContentVersion cv : [
                    SELECT ContentDocumentId, VersionData, Title, LastModifiedDate
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentDocIds
                    AND IsLatest = true
                ]) {
                    contentVersionMap.put(cv.ContentDocumentId, cv);
                }
            }

            for (Document__c doc : docs) {
                Id contentDocId = docToContentDocMap.get(doc.Id);
                if (contentDocId != null && contentVersionMap.containsKey(contentDocId)) {
                    ContentVersion cv = contentVersionMap.get(contentDocId);
                    String base64Data = EncodingUtil.base64Encode(cv.VersionData);
                    documentMap.put(doc.DocumentType__c, base64Data);
                    lastModifiedDateMap.put(doc.DocumentType__c, cv.LastModifiedDate);
                }
            }

            response.put('documents', documentMap);
            response.put('lastModifiedDates', lastModifiedDateMap);
        }

        return response;
    }
}