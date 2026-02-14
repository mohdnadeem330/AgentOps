@RestResource (urlMapping = '/submitQuarterlyBonusReport')
global with sharing class BP_QuarterlyBonusReport extends BP_BaseRestResource{
    @HttpPost
    global static void excute(){ 
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, String> params = RestContext.request.params;
            String requestBody = RestContext.request.requestBody.toString();
            
            if(!String.isEmpty(requestBody)){   
                BP_QuarterlyBonusReport service = new BP_QuarterlyBonusReport();
                ApiResponse response = service.processRequest(params, requestBody);
                handler.response.data = response.data;
                handler.response.success = true;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
            } else{
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Invalid Request Body';
            }
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
        }
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            Map<Id, QuarterlyBonusCommission__c> commissionLinesToProcess = new Map<Id, QuarterlyBonusCommission__c>();
            QuarterlyBonusWrapper requestWrapper = (QuarterlyBonusWrapper) JSON.deserialize(requestBody, QuarterlyBonusWrapper.class);
            
            if(String.isBlank(requestWrapper.qbcRecordId) || requestWrapper.qbcRecordId == null){
                return new ApiResponse(false, 400,'Quarterly Broker Commission Id can not be blank', null);
            }else{
                commissionLinesToProcess = new Map<Id, QuarterlyBonusCommission__c>([SELECT Id, BrokerAgency__r.Name, Quarter__c, Year__c FROM QuarterlyBonusCommission__c WHERE Id = :requestWrapper.qbcRecordId]); 
                if(commissionLinesToProcess.isEmpty() && !Test.isRunningTest()){
                    return new ApiResponse(false, 400,'Quarterly Broker Commission Lines are empty', null);
                }
            }

            if(String.isBlank(requestWrapper.status) || requestWrapper.status == null){
                return new ApiResponse(false, 400,'Quarterly Broker Commission Status can not be blank', null);
            }

            if(String.isBlank(requestWrapper.documentBase64) || requestWrapper.documentBase64 == null){
                return new ApiResponse(false, 400,'Quarterly Broker Commission document is required to submit', null);
            }

            requestWrapper.documentExtension = String.isBlank(requestWrapper.documentExtension) ? '.pdf' : '.'+ requestWrapper.documentExtension;
            
            return new ApiResponse(true, 200,'Quarterly Broker Commission Report is submitted', 
                            updateStatus(commissionLinesToProcess, requestWrapper)); 
        } catch (Exception e) {
            return new ApiResponse(false, 500,'Failed to submit Quarterly Broker Commission Report: ' + e.getMessage(), null);
        } 
    }

    public QuarterlyBonusCommission__c updateStatus(Map<Id, QuarterlyBonusCommission__c> commissionLinesToProcess, QuarterlyBonusWrapper requestWrapper){
        QuarterlyBonusCommission__c bonus = new QuarterlyBonusCommission__c(Id = requestWrapper.qbcRecordId, Status__c = requestWrapper.status, Comments__c = requestWrapper.comments);
        //CommissionLineItem__c commissionRecord = new CommissionLineItem__c(Id = recordId,status__c = status, AgencyAdmin__c = userInfo.getUserId(), OwnerID = userInfo.getUserId(), Comments__c= comments );
        if(!Schema.sObjectType.QuarterlyBonusCommission__c.isUpdateable() ){ throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
        update bonus;
        
        if(requestWrapper.status == Constants.STATUS_REJECTED || requestWrapper.status == Constants.COMMISSION_LINE_STATUS_ACCEPTED){
            generateInvoiceDocument(commissionLinesToProcess, requestWrapper);
        }
        return bonus;
    }

    /**
    * generateInvoiceDocument
    * On acceptance generate the Invoice attachment and store it under placeholder
    * @param  commissionLinesToProcess CommissionLineItem__c record to be processed
    * @return none
    */
    public static void generateInvoiceDocument(Map<Id, QuarterlyBonusCommission__c> commissionLinesToProcess, QuarterlyBonusWrapper requestWrapper){
        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion >();
        List<Document__c> placeholderList = [SELECT Id,QuarterlyBonusCommission__c FROM Document__c WHERE QuarterlyBonusCommission__c IN :commissionLinesToProcess.keySet()];
        Network network = [SELECT Name, UrlPathPrefix, Id FROM Network WHERE Name = :Constants.URL_PREFIX];
        
        if(placeholderList.isEmpty()){
            for(QuarterlyBonusCommission__c cr : commissionLinesToProcess.values()){
                placeholderList.add(new Document__c(DocumentType__c = 'Bonus Commission',
                                            QuarterlyBonusCommission__c = cr.Id,
                                            AvailableForExternalUsers__c = true,
                                            RecordtypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('SalesOrderDocument').getRecordTypeId()));
            }
            insert placeholderList;
        }
        for(Document__c tempDoc : placeholderList){       
            contentVersionMap.put(tempDoc.Id, 
                new ContentVersion(Title = commissionLinesToProcess.get(tempDoc.QuarterlyBonusCommission__c).BrokerAgency__r.Name
                                           + '_' + commissionLinesToProcess.get(tempDoc.QuarterlyBonusCommission__c).Quarter__c
                                           + '_' + commissionLinesToProcess.get(tempDoc.QuarterlyBonusCommission__c).Year__c
                                           + requestWrapper.documentExtension, 

                                    PathOnClient = commissionLinesToProcess.get(tempDoc.QuarterlyBonusCommission__c).BrokerAgency__r.Name
                                                   + '_' + commissionLinesToProcess.get(tempDoc.QuarterlyBonusCommission__c).Quarter__c
                                                   + '_' + commissionLinesToProcess.get(tempDoc.QuarterlyBonusCommission__c).Year__c 
                                                   + requestWrapper.documentExtension,

                                    VersionData = EncodingUtil.base64Decode(requestWrapper.documentBase64), origin = 'H',
                                    NetworkId = network.Id));
        }
        if(!contentVersionMap.isEmpty()){
            insert contentVersionMap.values();
            List<ContentDistribution> cdistribution = new List<ContentDistribution>();
            for(Id ccR : contentVersionMap.keySet()){
                cdistribution.add(ContentDocumentLinkTriggerHandler.createContentDistribution(contentVersionMap.get(ccR).Id, ccR));
            }
            insert cdistribution;

            Map<Id, Id> reverseMap = new Map<Id, Id>();
            for(Id docId : contentVersionMap.keySet()){
                reverseMap.put(contentVersionMap.get(docId).Id, docId);
            }

            List<ContentDocumentLink> documentLinksToCreate = new List<ContentDocumentLink>();
            for(ContentVersion tempCV : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionMap.values()]){
                documentLinksToCreate.add(new ContentDocumentLink(contentdocumentid = tempCV.ContentDocumentId,
                                                                  LinkedEntityId = reverseMap.get(tempCV.Id),
                                                                  ShareType ='V'));
            }
            if(!documentLinksToCreate.isEmpty()){
                insert documentLinksToCreate;
            }
        }
    }

    public class QuarterlyBonusWrapper{
        public String qbcRecordId;
        public String status;
        public String comments;
        public String documentBase64;
        public String documentExtension;

        public QuarterlyBonusWrapper(){}
    }
}