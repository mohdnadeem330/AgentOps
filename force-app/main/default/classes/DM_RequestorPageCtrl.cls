/***
Class       : DM_RequestorPageCtrl
Author      : Smaartt
Description : This class is accessed from LWC to retrieve requestor related information in portal.
TestClass   : DM_RequestorPageCtrlTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              13/02/2024           Initial Version
****************************************************************************************************************/
public without sharing class DM_RequestorPageCtrl {
    @auraEnabled
    public static list<Product2> getProducts(string type){
        String priceBookName = Label.DM_PriceBookName;
        return [SELECT Id, Name, (SELECT Id, List_Price_Incl_VAT__c FROM PricebookEntries WHERE IsActive = TRUE AND Pricebook2.Name =: priceBookName)
                FROM Product2 WHERE Family = :type AND IsActive = TRUE ORDER BY Name];
    }
    @auraEnabled
    public static Case getCaseInfo(string caseId){
        return [Select Id,CaseNumber,Contact.Name,ContactMobile,ContactEmail,Previous_Request_Number__c,Validity_Status__c,Validity_Date__c,Sub_Status__c,Description_By_Aldar__c,Additional_Info_Req_By__c,Required_Information__c,Type,Service_Price__c,Asset_Evaluation__c,IPS_Received_from_ADM__c,CreatedById,Is_the_area_pre_approved_by_aldar__c,Licensee_Email__c,Licensee_Company__c,Inspected_Date__c,Licensee_Address__c,Applicant_Contact_Details__c,Requestor_s_Authorized_signature_name__c,Requestor_s_Authorized_signature_EID_num__c,Is_the_site_Inspected__c,Request_split_payment__c,Purpose_of_Work__c,Demarcation__c,Hazards_Identified_Environmental_Impact__c,Type_of_Hazard_and_Risk_Impact__c,Safety_Precautions_and_Controls_in_Place__c,Safety_Precautions_taken__c,Duration_of_Work_Years__c,List_of_Equipment_to_be_Used_If_Any__c,Duration_of_Work_Days__c,Duration_of_Work_Months__c,Method_of_Excavation__c,Request_Type__c,Other_Excavation_Name__c,Status,Owner.Name,Assigned_To__r.Name,Utility__c,Development_Name__c,Project_Name__c,Plot_Developer__c,Sector_and_Plot_No__c,Project_Consultant__c,Appointed_Contractor__c,Description,NOC_to_be_Addressed_to__c,Dev_Stage__c,ProductId,Product.Name,Other_Utility_Name__c,PMC_Approved_Date__c,PMC_Reference_No__c,Stakeholder_Reference_No__c,Start_Date__c,End_Date__c,CreatedDate,Payment_Required__c,OwnerId,IsStopped, (SELECT Id,DocumentType__c FROM Documents__r) from Case WHERE Id=:caseId];
    }
    @auraEnabled
    public static String getPaymentRequests(Integer pageSize, Integer pageNumber, String filterCondition){
        String jsonData = '';
        Integer offset = (pageNumber - 1) * pageSize;
        String userId = UserInfo.getUserId();
        String conId = [select ContactId from User where Id=:userId limit 1].ContactId;
        //String countQuery = 'SELECT COUNT() FROM Payment_Request__c Where Case__c != null AND Case__r.CreatedById=:userId';
        String countQuery = 'SELECT COUNT() FROM Payment_Request__c Where Case__c != null AND (Case__r.CreatedById = \'' + userId+ '\'  OR Case__r.ContactId = \'' + conId+ '\' ) ';

        System.debug('filterCondition: ' + filterCondition);
        if (String.isNotBlank(filterCondition)) {
            countQuery += filterCondition;
        }
        Integer totalRecords = database.countQuery(countQuery);
        Integer recordEnd = pageSize * pageNumber;
        WrapperClass objcls =  new WrapperClass();
        objcls.pageSize = pageSize;
        objcls.pageNumber = pageNumber;
        objcls.recordStart = offset + 1;
        objcls.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        objcls.totalRecords = totalRecords;

        String mainQuery = 'Select Id,Name,Amount__c,Encrypted_Id__c,Case__r.CaseNumber,Payment_Type__c,Transaction_No__c,Transaction_Date__c,CreatedDate,Status__c from Payment_Request__c Where Case__c != null AND (Case__r.CreatedById = \'' + userId+ '\'  OR Case__r.ContactId = \'' + conId+ '\' ) ';
        if (String.isNotBlank(filterCondition)) {
            mainQuery += filterCondition;
        }
        mainQuery += ' ORDER BY CreatedDate DESC LIMIT :pageSize OFFSET :offset';
        System.debug('Main Query: ' + mainQuery);
        objcls.paymentReq = database.query(mainQuery);
        jsonData = JSON.serialize(objcls);
        return jsonData;
    }
    @auraEnabled
    public static list<External_Files__c> showCustomerDocuments(string caseId){
        return[Select Id,External_URL__c,Document__r.DocumentType__c,Document__r.Other_Document_Name__c,File_Name__c,Deleted_by_Creator__c,Document__r.CreatedDate,CreatedDate from External_Files__c where Document__r.Case__c  =:caseId and Deleted_by_Creator__c = false];
    }
    @auraEnabled
    public static Case createCase(Case caseObj){
        String productName;
        Id caseDocumentRecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_CaseDocumentRecordType).getRecordTypeId();

        list<User> userlist = [Select Id,Name,AccountId, ContactId from User Where Id=: UserInfo.getUserId()];
        if(userlist.size()>0 && userlist[0].ContactId != null){
            caseObj.AccountId=userlist[0].AccountId;
            caseObj.ContactId=userlist[0].ContactId;
        }
        if(caseObj.ProductId != null){
            Product2 product = [SELECT Name, (SELECT Id, List_Price_Incl_VAT__c FROM PricebookEntries WHERE IsActive = TRUE AND Pricebook2.Name = :Label.DM_PriceBookName) FROM Product2 WHERE Id = :caseObj.ProductId];
            if(!product.PricebookEntries.isEmpty()) {
                caseObj.Service_Price__c = product.PricebookEntries[0].List_Price_Incl_VAT__c;
            }
            caseObj.RecordTypeId =  Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_CaseRecordType).getRecordTypeId();
            productName = product.Name;
            System.debug('Product Name: ' + productName);
        }
        if(caseObj.Type == Label.DM_CaseType){
            productName = Label.DM_TLAProductName;
            caseObj.RecordTypeId =  Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_TLACaseRecordType).getRecordTypeId();
        }

        try{
            insert caseObj;
            Map<string,string> CaseRecTypeNames = DM_UtilityController.getCaseRecTypeName(new list<string>{caseObj.Id});
            System.debug('Inserted Case Object: ' + caseObj);
            List<Document__c> documents = new List<Document__c>();
            if(caseObj.IPS_Received_from_ADM__c == 'Yes' && caseObj.Development_Name__c == Label.DM_DevelopmentNameYasIsland){
                Document__c document = new Document__c();
                document.DocumentType__c = Label.DM_DocumentTypeIPS;
                document.Case__c = caseObj.Id;
                document.RecordTypeId = caseDocumentRecordTypeId;
                document.Case_Recordtype__c=CaseRecTypeNames.get(caseObj.Id);
                documents.add(document);
            }

            List<Service_Request_Documents__mdt> documentsMetadata = [SELECT Id, Service_Name__c, Mandatory_Documents__c, Active__c
                                                                      FROM Service_Request_Documents__mdt
                                                                      WHERE Service_Name__c = :productName AND Active__c = true];

            if (documentsMetadata.size() > 0 && documentsMetadata[0].Mandatory_Documents__c != null) {
                String[] mandatoryDocuments = documentsMetadata[0].Mandatory_Documents__c.split(',');
                for (String documentType : mandatoryDocuments) {
                    Document__c document = new Document__c();
                    document.DocumentType__c = documentType;
                    document.Case__c = caseObj.Id;
                    document.RecordTypeId = caseDocumentRecordTypeId;
                    document.Case_Recordtype__c=CaseRecTypeNames.get(caseObj.Id);
                    documents.add(document);
                }
            }
            if(documents.size()>0)
                insert documents;
            System.debug('Inserted Documents: ' + documents);
        }
        catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
        return caseObj;
    }
    @auraEnabled
    public static void updateCase(Case caseObj){
        try{
            update caseObj;
           Map<string,string> CaseRecTypeNames = DM_UtilityController.getCaseRecTypeName(new list<string>{caseObj.Id});
            List<String> developmentNames = Label.DM_DevelopmentNameYasIsland.split(',');
            if (developmentNames.contains(caseObj.Development_Name__c)) {
                List<Document__c> existingDocs = [SELECT Id FROM Document__c WHERE Case__c = :caseObj.Id AND DocumentType__c = :Label.DM_DocumentTypeIPS LIMIT 1];

                if (caseObj.IPS_Received_from_ADM__c == 'No') {
                    if (!existingDocs.isEmpty()) {
                        delete existingDocs;
                    }
                } else if (caseObj.IPS_Received_from_ADM__c == 'Yes') {
                    if (existingDocs.isEmpty()) {
                        Document__c document = new Document__c();
                        document.DocumentType__c = Label.DM_DocumentTypeIPS;
                        document.Case__c = caseObj.Id;
                        document.RecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_CaseDocumentRecordType).getRecordTypeId();
                        document.Case_Recordtype__c = CaseRecTypeNames.get(caseObj.Id);
                        insert document;
                    }
                }
            }
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @auraEnabled
    public static Document__c updateOtherDocument(String caseId,String otherDoc,String docType){
        try{
            Map<string,string> CaseRecTypeNames = DM_UtilityController.getCaseRecTypeName(new list<string>{caseId});
            Document__c document = new Document__c();
            document.DocumentType__c = docType;
            document.Case__c = caseId;
            document.Other_Document_Name__c = otherDoc;
            document.Case_Recordtype__c=CaseRecTypeNames.get(caseId);
            document.RecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_CaseDocumentRecordType).getRecordTypeId();
            insert document;
            System.debug('Document inserted successfully: ' + document);

            if(docType == Label.DM_DocumentTypeSignedTLA){
                Document__c signedDoc = new Document__c();
                signedDoc.DocumentType__c = Label.DM_DocumentTypeFinalTLA;
                signedDoc.Case__c = caseId;
                signedDoc.Case_Recordtype__c=CaseRecTypeNames.get(caseId);
                signedDoc.RecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
                insert signedDoc;
            }

            return document;
        }
        catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @auraEnabled
    public static String getAllCases(Integer pageSize, Integer pageNumber, String filterCondition){
        System.debug('Entering getAllCases method');
        String jsonData = '';
        Integer offset = (pageNumber - 1) * pageSize;
        String userId = UserInfo.getUserId();
        String conId = [select ContactId from User where Id=:userId limit 1].ContactId;

        String countQuery = 'SELECT COUNT() FROM Case Where (CreatedById = \'' + userId+ '\'  OR ContactId = \'' + conId+ '\' ) ';
        if (String.isNotBlank(filterCondition)) {
            countQuery += filterCondition;
        }

        system.debug('countQuery-->'+countQuery);
        Integer totalRecords = database.countQuery(countQuery);
        Integer recordEnd = pageSize * pageNumber;
        WrapperClass objcls =  new WrapperClass();
        objcls.pageSize = pageSize;
        objcls.pageNumber = pageNumber;
        objcls.recordStart = offset + 1;
        objcls.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        objcls.totalRecords = totalRecords;

        String mainQuery = 'Select Id,CaseNumber,status,Sub_Status__c,type,Dev_Stage__c,Validity_Status__c,CreatedDate from Case Where (CreatedById = \'' + userId+ '\'  OR ContactId = \'' + conId+ '\' ) ';
        if (String.isNotBlank(filterCondition)) {
            mainQuery += filterCondition;
        }
        mainQuery += ' ORDER BY CaseNumber DESC LIMIT :pageSize OFFSET :offset';
        System.debug('Main Query: ' + mainQuery);
        objcls.cs = database.query(mainQuery);
        jsonData = JSON.serialize(objcls);
        return jsonData;
    }
    @auraEnabled
    public static list<Case> getActionRequiredCases(){
        String userId = UserInfo.getUserId();
        String conId = [select ContactId from User where Id=:userId limit 1].ContactId;
        //return [Select Id,CaseNumber,status,Sub_Status__c,type,Dev_Stage__c,CreatedDate from Case Where CreatedById=:UserInfo.getUserId() AND (Sub_Status__c =: Label.DM_WaitingForPayment  OR Sub_Status__c =: Label.DM_AdditionalInfoFromCustomer) Order by CaseNumber Desc Limit 10];
        return [Select Id,CaseNumber,status,Sub_Status__c,type,Dev_Stage__c,Validity_Status__c,CreatedDate from Case Where (CreatedById=:UserInfo.getUserId() OR ContactId =: conId) AND (Status =: Label.DM_PendingWIthCustomer  And Sub_Status__c !=: Label.DM_AdditionalInfoFromPMC) Order by CaseNumber Desc Limit 10];
    }
    @AuraEnabled(cacheable=true)
    public static List<Service_Request_Documents__mdt> getSRRelatedDocuments(String serviceId) {

        String productName = [SELECT Name FROM Product2 WHERE Id = :serviceId].Name;
        List<Service_Request_Documents__mdt> documents = [SELECT Id, Service_Name__c, Mandatory_Documents__c, Active__c
                                                          FROM Service_Request_Documents__mdt
                                                          WHERE Service_Name__c = :productName AND Active__c = true];
        return documents;
    }
    @auraEnabled
    public static list<Document__c> getCustomerDocuments(string caseId){
        return [SELECT Id,DocumentType__c,Case__r.CaseNumber,Case__r.Account.AccountNumber__c,Other_Document_Name__c,Case__r.OwnerId,(SELECT Id,File_Name__c,External_URL__c,Deleted_by_Creator__c FROM External_Files__r WHERE Deleted_by_Creator__c = false) FROM Document__c WHERE Case__c = :caseId AND RecordType.DeveloperName  =: Label.DM_CaseDocumentRecordType];
    }

    public class WrapperClass{
        @AuraEnabled public Integer pageSize {get;set;}
        @AuraEnabled public Integer pageNumber {get;set;}
        @AuraEnabled public Integer totalRecords {get;set;}
        @AuraEnabled public Integer recordStart {get;set;}
        @AuraEnabled public Integer recordEnd {get;set;}
        @AuraEnabled public List<Case> cs {get;set;}
        @AuraEnabled public List<Payment_Request__c> paymentReq {get;set;}
    }
    @AuraEnabled
    public static String getSessionId(){
        return string.valueof(UserInfo.getSessionId());
    }
    @AuraEnabled
    public static void deleteRequestRecord(Id caseId) {
        try {
            Case cs = new Case(Id = caseId);
            delete cs;
        } catch (DmlException e) {
            throw new AuraHandledException('Error deleting Case record: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static List<documentWrapper> getDocuments(String sObjectName, String recordId, String recordType, Boolean isAvailable, String docType) {
        system.debug('Inside getDocuments');
        List<documentWrapper> docWrapList = new List<documentWrapper>();
        String query = 'SELECT Id, DocumentType__c, AvailableForExternalUsers__c,Other_Document_Name__c,CreatedDate FROM Document__c WHERE ' + sObjectName + ' = :recordId AND RecordType.DeveloperName = :recordType';

        if(docType != null && docType == Label.DM_DocumentTypeReceipt){
            query += ' AND DocumentType__c =: docType';
        }
        if (isAvailable != null) {
            query += ' AND AvailableForExternalUsers__c =: isAvailable';
        }

        system.debug('query '+query);

        List<Document__c> docList = Database.query(query);
        Map<Id, Document__c> docIdvsDoc = new Map<Id, Document__c>(docList);
        system.debug('docList---'+docList);
        map<Id,Id> conDocIdvsLinkedId = new map<Id,Id>();
        if (!docIdvsDoc.isEmpty()) {
            List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :docIdvsDoc.keyset()];
            system.debug('contentDocumentLinks---'+contentDocumentLinks);
            List<Id> contentDocumentIds = new List<Id>();
            for (ContentDocumentLink link : contentDocumentLinks) {
                contentDocumentIds.add(link.ContentDocumentId);
                conDocIdvsLinkedId.put(link.ContentDocumentId,link.LinkedEntityId);
            }

            for(ContentVersion con :[SELECT Id, Title, FileExtension, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds]){
                documentWrapper docWrap = new documentWrapper();
                docWrap.doc = docIdvsDoc.get(conDocIdvsLinkedId.get(con.ContentDocumentId));
                docWrap.contentVersion = con;
                if (docWrap.doc.DocumentType__c == 'Signed TLA') {
                    if (con.Title.contains('TLA')) {
                        docWrapList.add(docWrap);
                    }
                } else {
                    docWrapList.add(docWrap);
                }
            }
            System.debug('docWrapList: ' + docWrapList);
            return docWrapList;
        } else {
            return null;
        }
    }

    public class documentWrapper{
        @AuraEnabled public Document__c doc {get; set;}
        @AuraEnabled public ContentVersion contentVersion {get; set;}
    }
    @auraEnabled
    public static Map<String, Integer> fetchDMCounts(String groupByFilter) {
        User currentUser = [SELECT Profile.Name,ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        Id userId = UserInfo.getUserId();
        String conId = currentUser.ContactId;

        //String queryStr = 'SELECT ' + groupByFilter + ' , COUNT(Id) FROM Case WHERE CreatedById = :userId GROUP BY ' + groupByFilter;
        String queryStr = 'SELECT ' + groupByFilter + ' , COUNT(Id) FROM Case WHERE  (CreatedById = \'' + userId+ '\'  OR ContactId = \'' + conId+ '\' ) GROUP BY ' + groupByFilter;

        List<AggregateResult> aggregateResults = Database.query(queryStr);
        Map<String, Integer> caseCountsMap = new Map<String, Integer>();

        for (AggregateResult aggr : aggregateResults) {
            String status = (String) aggr.get(groupByFilter);
            Integer count = (Integer) aggr.get('expr0');
            if (status != null) {
                caseCountsMap.put(status, count);
            }
        }
        System.debug('caseCountsMap: ' + caseCountsMap);
        return caseCountsMap;
    }
    @AuraEnabled
    public static void updateDocumentUpload(list<tlaAttachments> tlaAttachments, Case caseObj, string identifier) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

        try {
            for(tlaAttachments file: tlaAttachments) {
                System.debug('base64'+file.base64);
                System.debug('filename'+file.filename);
                System.debug('recordId'+file.recordId);
                if (file.filename != null) {
                    ContentVersion cv = new ContentVersion();
                    cv.VersionData = EncodingUtil.base64Decode(file.base64);
                    if(file.fileType== label.DM_DocumentTypeSignedTLA){
                        cv.Title = label.dmTLAdocusignKey;
                        cv.PathOnClient=file.filename;
                    }else{
                        cv.Title = file.filename;
                        cv.PathOnClient=file.filename;
                    }

                    cv.Description = file.recordId;
                    contentVersions.add(cv);
                }else{
                    throw new AuraHandledException('Failed to create ContentVersion.');
                }
            }
            if (!contentVersions.isEmpty()) {
                insert contentVersions;
            }

            List<ContentVersion> conVersionList = [SELECT Id,PathOnClient,ContentDocumentId,Description,Title FROM ContentVersion WHERE Id IN :contentVersions];

            for (ContentVersion cv:  conVersionList) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.LinkedEntityId = cv.Description;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                contentDocumentLinks.add(cdl);
                if(cv.Title == label.dmTLAdocusignKey){
                    ContentDocumentLink cd = new ContentDocumentLink();
                    cd.ContentDocumentId = cv.ContentDocumentId;
                    cd.LinkedEntityId = caseObj.Id;
                    cd.ShareType = 'V';
                    cd.Visibility = 'AllUsers';
                    contentDocumentLinks.add(cd);
                }
            }
            if (!contentDocumentLinks.isEmpty()) {
                insert contentDocumentLinks;
            }

            if (caseObj != null && identifier =='requestor') {
                caseObj.Status = Label.DM_StatusWorkInProgress;
                caseObj.Sub_Status__c = Label.DM_SubStatusAddtionalInfoSubmitted;
                update caseObj;
                string Notificationbody = caseObj.CaseNumber +' is submitted the documents';
                DM_UtilityController.sendBellNotification(new set<string>{caseObj.OwnerId}, caseObj.Id , label.Dm_TLABellNotification_CaseTitle,Notificationbody);
            }
        } catch (DmlException e) {
            throw new AuraHandledException('Error in updateTLADoc: ' + e.getMessage());
        }
    }
    public class tlaAttachments {
        @AuraEnabled public String base64 { get; set; }
        @AuraEnabled public String filename { get; set; }
        @AuraEnabled public String recordId { get; set; }
        @AuraEnabled public String fileType { get; set; }
    }

    @AuraEnabled
    public static String submitWireTransferPayment(String reqId, String paymentdate, String name, String ref,String base64, String filename) {
        try {
            if (reqId != null) {
                Payment_Request__c paymentRequest = new Payment_Request__c();
                paymentRequest.Id = reqId;
                paymentRequest.Payment_Date__c = Date.valueOf(paymentDate);
                paymentRequest.Remittance_Name__c = name;
                paymentRequest.Payment_Reference_No__c = ref;
                paymentRequest.Payment_Type__c = Label.DM_PaymentTypeWireTransfer;
                paymentRequest.Status__c = Label.DM_PaymentUnConfiremed;
                update paymentRequest;

                List<Payment_Request__c> pr = [select Id,Case__r.RecordType.Name from Payment_Request__c where id=:reqId];

                Document__c document = new Document__c();
                document.DocumentType__c = Label.DM_DocumentTypePaymentSlip;
                document.Payment_Request__c = reqId;
                document.RecordTypeId = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_CaseDocumentRecordType).getRecordTypeId();
                document.Case_Recordtype__c=pr.size()>0?pr[0].Case__r.RecordType.Name:'';
                insert document;
                System.debug('document: ' + document.Id);

                if (document != null) {
                    ContentVersion cv = DM_UtilityController.createContentVersion(base64, filename);
                    ContentDocumentLink cdl = DM_UtilityController.createContentLink(cv.Id, document.Id);
                    if (cv == null || cdl == null) { return null; }
                    return cdl.Id;
                }
            }
            return null;
        } catch (DmlException e) {
            System.debug('Error in submitWireTransferPayment: ' + e.getMessage());
            throw new AuraHandledException('Error updating payment request: ' + e.getMessage());

        }
    }
    @AuraEnabled
    public static void updateExternalFileAsDeleted(string documentId) {
        External_Files__c externalFile = [SELECT Id, Deleted_by_Creator__c FROM External_Files__c WHERE Document__c = :documentId ORDER BY CreatedDate DESC LIMIT 1];

        if (externalFile != null) {
            externalFile.Deleted_by_Creator__c = true;
            update externalFile;
        }
    }
    @AuraEnabled
    public static void createContact(Contact con) {
        con.recordTypeId= Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get(Label.DM_ContactRecordType).getRecordTypeId();
        con.Is_Portal_Register_User__c=true;
        list<contact> conlist = [select id from Contact where email=:con.email AND recordtypeId=:con.recordTypeId];
        if(conlist.size()>0){
            throw new AuraHandledException('Email already registered.');
        }else{
            try {
                insert con;
            } catch (DmlException e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }
    @AuraEnabled
    public static void createPermitClosureReq(string caseId) {
        Case ca = new Case(Id=caseId);
        ca.Requested_Date__c = system.today();
        ca.Status =label.DM_CaseWorkInProgress;
        ca.Sub_Status__c=label.Dm_SubStatus_PermitRefund;

        Update ca;
    }
    //Added by protiviti
    @AuraEnabled(cacheable=true)
    public static String  checkFeatureFlagEnabled() {
        RETL_Tenant_Portal_Setting__mdt record = [
            SELECT Value__c
            FROM RETL_Tenant_Portal_Setting__mdt WHERE DeveloperName = 'DM_Contractor_Portal_Switch_Exp_Flag' limit 1
        ];
        return record.Value__c;
    }
    //End
}