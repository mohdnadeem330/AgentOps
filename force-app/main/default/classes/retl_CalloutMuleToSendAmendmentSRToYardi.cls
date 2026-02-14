/**
* @File Name : retl_CalloutMuleToSendAmendmentSRToYardi.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 10, 2025 |   | Initial Version
**/

public class retl_CalloutMuleToSendAmendmentSRToYardi {
    
    public class SRCaseLeaseAmendmentRequestWrapper {
        public List<LeaseAmendment> WorkOrder;
    }
    
    public class LeaseAmendment {
        public String SF_Ref_WO_Id { get; set; }
        public String Tenant_Code { get; set; }
        public String Property_Code { get; set; }
        public String Unit_Code { get; set; }
        public String Template_Code { get; set; }
        public String WOStatus { get; set; }
        public String WOOrigin { get; set; }
        public String WOCategory { get; set; }
        public String SubCategory { get; set; }
        public String WOPriority { get; set; }
        public String Problem_Description { get; set; }
        public String Brief_Description { get; set; }
        public String Occupant_Code { get; set; }
        public String Caller_Name { get; set; }
        public String Caller_Number { get; set; }
        public String Caller_Email { get; set; }
        public String Related_WOID { get; set; }
        public String Common_Area { get; set; }
        public String ExtRef_Site_ID { get; set; }
        public String WO_ExtRef_ID { get; set; }
        public String userDefined1 { get; set; }
        public String userDefined2 { get; set; }
        public String userDefined3 { get; set; }
        public String userDefined4 { get; set; }
        public String userDefined5 { get; set; }
        public String userDefined6 { get; set; }
        public String userDefined7 { get; set; }
        public String CustomField1 { get; set; }
        public String CustomField2 { get; set; }
        public String CustomField3 { get; set; }
        public String AccessEntryNotes { get; set; }
        public String FullDescription { get; set; }
        public String TechnicianNotes { get; set; }
    }
    
    public class WorkOrderResponseWrapper {
        public String Yardi_WO_Code { get; set; }
        public String Status { get; set; }
        public String ErrorMessage { get; set; }
        public String SF_Ref_WO_Id { get; set; }
    }
    
    public class AttachmentRequestWrapper {
        public List<AttachmentItem> Attachments;
    }
    
    public class AttachmentItem {
        public String SF_Ref_Attachment_Id;
        public String Record_Code;
        public String Property_Code;
        public String Object_Type;
        public String Attachment_Type;
        public String Attachment_File_Name;
        public String AttachmentBase64;
    }
    
    public class AttachmentResponseWrapper {
        public String Yardi_Attachment_id;
        public String SF_Ref_Attachment_Id;
        public String Status;
        public String ErrorMessage;
    }
    
    @InvocableMethod(label='Push Case to Yardi' description='Pushes Case details to Yardi and updates record in Salesforce')
    public static void pushToYardiAndUpdate(List<PushToYardiRequest> requestList) {
        
        List<Id> caseIds = new List<Id>();
        Boolean isSandbox = [
            SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        
        if (!isSandbox) {
            isSandbox = True;
        }
        
        for (PushToYardiRequest req : requestList) {
            if (req.caseId != null) caseIds.add(req.caseId);
        }
        
        String className = 'RETL_SRCaseSyncToYardi';
        String methodName = 'pushToYardiAndUpdate';
        HttpResponse response;
        for (Id caseId : caseIds) {
            try {
                if (CaseId == null){
                    throw new CustomException('CaseId Id cannot be null.');
                }
                
                
                SRCaseLeaseAmendmentRequestWrapper CaseData = buildCaseWrapper(CaseId);
                if (CaseData == null || CaseData.WorkOrder.isEmpty()){
                    throw new CustomException('Unable to construct Yardi Case payload.');
                }
                
                
                MuleSoftSetting__mdt api = Utilities.getMuleSoftDetails(className);
                
                if (api == null){
                    throw new CustomException('Yardi API configuration not found in MuleSoftSetting__mdt.');
                }
                
                
                replaceNullStringsWithEmpty(CaseData);
                String requestBody = JSON.serialize(CaseData,false);
                System.debug('Yardi Case Request Body: ' + requestBody);
                
                
                response = CalloutToMuleSoft.makeCallout(api.DeveloperName, requestBody);
                if (response == null){
                    throw new CustomException('No response received from Yardi endpoint.');
                }
                
                Integer statusCode = response.getStatusCode();
                String resBody = response.getBody();
                System.debug('Response Code: ' + statusCode);
                System.debug('Response Body: ' + resBody);
                
                
                if (statusCode >= 200 && statusCode < 300 && !String.isBlank(resBody)) {
                    WorkOrderResponseWrapper resWrapper =
                        (WorkOrderResponseWrapper) JSON.deserialize(resBody, WorkOrderResponseWrapper.class);
                    
                    
                    if (resWrapper.Status == 'Success' && !String.isBlank(resWrapper.Yardi_WO_Code)) {
                        
                        update new Case(
                            Id = resWrapper.SF_Ref_WO_Id,
                            RETL_SR_Yardi_Work_Order_Id__c = resWrapper.Yardi_WO_Code // Assumes custom field RETL_Yardi_Id__c on Opportunity                        
                        );
                        
                        List<Document__c> docRecs = [
                            SELECT Id
                            FROM Document__c
                            WHERE Case__c = :caseId
                        ];
                        
                        if (!docRecs.isEmpty()) {
                            // collect document record Ids
                            List<Id> docRecIds = new List<Id>();
                            for (Document__c d : docRecs) docRecIds.add(d.Id);
                            
                            // Query ContentDocumentLink using only Id(s) in the WHERE clause (allowed)
                            List<ContentDocumentLink> docLinks = [
                                SELECT ContentDocumentId
                                FROM ContentDocumentLink
                                WHERE LinkedEntityId IN :docRecIds
                            ];
                            
                            if (!docLinks.isEmpty()) {
                                // collect ContentDocument Ids
                                Set<Id> contentDocIds = new Set<Id>();
                                for (ContentDocumentLink cdl : docLinks) {
                                    if (cdl.ContentDocumentId != null) contentDocIds.add(cdl.ContentDocumentId);
                                }
                                
                                // Query the latest ContentVersion(s) for those ContentDocument(s)
                                if (!contentDocIds.isEmpty()) {
                                    List<ContentVersion> latestVersions = [
                                        SELECT Id
                                        FROM ContentVersion
                                        WHERE ContentDocumentId IN :contentDocIds
                                        AND IsLatest = TRUE
                                    ];
                                    
                                    for (ContentVersion ver : latestVersions) {
                                        pushAttachmentToYardi(caseId, ver.Id);
                                    }
                                }
                            }
                        }
                        
                        
                        
                    } else {
                        
                        String errMsg = 'Yardi Case Sync Failed (Status Success but missing Yardi_WO_Code/Error): ' + resBody;
                        logError(className, methodName, requestBody, errMsg, resWrapper.SF_Ref_WO_Id);
                    }
                } else {
                    
                    String errMsg = 'Yardi Case Sync Failed: ' + statusCode + ' | Body: ' + resBody;
                    logError(className, methodName, requestBody, errMsg, CaseId);
                }
                
            } catch (Exception e) {
                
                logError(className, methodName, null, 'Exception while pushing Case to Yardi: ' + e.getMessage(), CaseId);
                throw e;
            }
        }
    }
    
    public class CustomException extends Exception {}
    @Testvisible
    private static SRCaseLeaseAmendmentRequestWrapper buildCaseWrapper(Id CaseId) {
        Case caseRec = [
            SELECT Id,CaseNumber, ContactId, AccountId,Account.Name, RecordTypeId,RETL_SR_Unit_Number__c,RETL_Yardi_Work_Order_Category__c,RETL_Yardi_Work_Order_Sub_Category__c, Status, Origin, Subject,
            Priority, Description, ContactPhone, ContactEmail, SubVertical__c,  Vertical__c, 
            Recordtype_Name__c, Creator_Email__c,  Demarcation__c, Contact_Name__c,  Requested_Date__c,
            RETL_SR_Type_Of_Request__c, RETL_SR_Category__c, RETL_Store_Name__c, RETL_SR_Sub_Category__c,
            RETL_SR_Service_Type__c, RETL_SR_Order__r.RETL_Property_Name__c,RETL_SR_Order__r.RETL_Yardi_Id__c, RETL_SR_Property_Name__c,  RETL_SR_Additional_Info__r.RETL_Unit_No__c,
            RETL_SR_Yardi_Work_Order_Id__c FROM Case
            WHERE Id = :CaseId
            LIMIT 1
        ];
        
        LeaseAmendment amendment = new LeaseAmendment();
        
        amendment.SF_Ref_WO_Id        = caseRec.Id;
        amendment.Tenant_Code         = caseRec.RETL_SR_Order__r.RETL_Yardi_Id__c;
        amendment.Property_Code       = caseRec.RETL_SR_Order__r.RETL_Property_Name__c;
        amendment.Unit_Code           = caseRec.RETL_SR_Unit_Number__c;
        amendment.Template_Code       = '';
        amendment.WOStatus            = 'Assigned';
        amendment.WOOrigin            = 'CA';
        amendment.WOCategory          = caseRec.RETL_Yardi_Work_Order_Category__c;
        amendment.SubCategory         = caseRec.RETL_Yardi_Work_Order_Sub_Category__c;
        amendment.WOPriority          = '';
        amendment.Problem_Description = caseRec.Subject;
        amendment.Brief_Description   = caseRec.RETL_SR_Type_Of_Request__c?.left(44);
        amendment.Caller_Name         = caseRec.Contact_Name__c;
        amendment.Caller_Number       = caseRec.ContactPhone;
        amendment.Caller_Email        = caseRec.ContactEmail;
        amendment.Occupant_Code         ='';
        
        // Optional additional mapping placeholders
        amendment.FullDescription = caseRec.Description;
        amendment.AccessEntryNotes = 'Created from Salesforce Case: ' + caseRec.CaseNumber;
        amendment.TechnicianNotes = 'Imported from Case RecordType: ' + caseRec.Recordtype_Name__c;
        
        
        
        SRCaseLeaseAmendmentRequestWrapper wrapper = new SRCaseLeaseAmendmentRequestWrapper();
        wrapper.WorkOrder = new List<LeaseAmendment>{amendment};
            
            return wrapper;
    }
    
    
    private static void logError(String className, String methodName, String requestBody, String errorMsg, Id recordId) {
        
        LoggerService.save(
            LoggerService.addApexServiceCalls(
                'OpportunitySyncToYardi',     // Process name
                className,         // Class name
                methodName,         // Method name
                'requestBody: ' + requestBody, // Request body for traceability
                errorMsg,          // Response body/Error message
                recordId           // Lookup for Mapping Related Opportunity record ID
            )
        );
        System.debug('Yardi Push Failure: ' + errorMsg);
    }
    
    
    private static void replaceNullStringsWithEmpty(SRCaseLeaseAmendmentRequestWrapper amendment) {
        if (amendment == null || amendment.WorkOrder == null) return;
        for (LeaseAmendment amend : amendment.WorkOrder) {
            if (amend.Related_WOID == null) amend.Related_WOID = '';
            if (amend.Common_Area == null) amend.Common_Area = '';
            if (amend.ExtRef_Site_ID == null) amend.ExtRef_Site_ID = '';
            if (amend.WO_ExtRef_ID == null) amend.WO_ExtRef_ID = '';
            if (amend.Unit_Code  == null) amend.Unit_Code  = '';
            if (amend.userDefined1 == null) amend.userDefined1 = '';
            if (amend.userDefined2 == null) amend.userDefined2 = '';
            if (amend.userDefined3 == null) amend.userDefined3 = '';
            if (amend.userDefined4 == null) amend.userDefined4 = '';
            if (amend.userDefined5 == null) amend.userDefined5 = '';
            if (amend.userDefined6 == null) amend.userDefined6 = '';
            if (amend.userDefined7 == null) amend.userDefined7 = '';
            
            if (amend.CustomField1 == null) amend.CustomField1 = '';
            if (amend.CustomField2 == null) amend.CustomField2 = '';
            if (amend.CustomField3 == null) amend.CustomField3 = '';
        }
        
        
    }
    
    // -------------------- Core Logic --------------------
    @TestVisible
    @future(callout=true)
    private static void pushAttachmentToYardi(Id caseId, Id contentVersionId) {
        
        Case cs = [
            SELECT Id, RETL_SR_Yardi_Work_Order_Id__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        ContentVersion version = [
            SELECT Id, Title, VersionData, FileExtension
            FROM ContentVersion
            WHERE Id = :contentVersionId
            LIMIT 1
        ];
        
        AttachmentRequestWrapper reqWrapper = new AttachmentRequestWrapper();
        reqWrapper.Attachments = new List<AttachmentItem>();
        
        AttachmentItem att = new AttachmentItem();
        att.SF_Ref_Attachment_Id = version.Id;
        att.Record_Code = cs.RETL_SR_Yardi_Work_Order_Id__c;
        att.Property_Code = '';
        att.Object_Type = '25';
        att.Attachment_Type = 'Legal Memo';
        att.Attachment_File_Name = version.Title;
        att.AttachmentBase64 = EncodingUtil.base64Encode(version.VersionData);
        
        
        reqWrapper.Attachments.add(att);
        
        String requestBody = JSON.serialize(reqWrapper, true);
        
        MuleSoftSetting__mdt api = Utilities.getMuleSoftDetails('RETL_AttachmentSyncToYardi');
        if (api == null) {
            throw new CustomException('MuleSoft endpoint configuration not found.');
        }
        
        HttpResponse response = CalloutToMuleSoft.makeCallout(api.DeveloperName, requestBody);
        
        if (response == null || response.getStatusCode() != 201) {
            throw new CustomException('Failed response from MuleSoft: ' + (response != null ? response.getBody() : 'null'));
        }
        
        System.debug('AttachmentSyncToYardi Response: ' + response.getBody());
        
        AttachmentResponseWrapper res = (AttachmentResponseWrapper) JSON.deserialize(response.getBody(), AttachmentResponseWrapper.class);
        
        if (res != null && res.Status == 'Success') {
            contentVersion cvToUpdate = [
                SELECT Id, RETL_Yardi_Id__c
                FROM ContentVersion
                WHERE Id = :contentVersionId
                LIMIT 1];
            cvToUpdate.RETL_Yardi_Id__c = res.Yardi_Attachment_id;
            update cvToUpdate;
            System.debug('Attachment uploaded successfully to Yardi. Yardi ID: ' + res.Yardi_Attachment_id);
        } else {
            LoggerService.save(
                LoggerService.addApexServiceCalls(
                    'AttachmentSyncToYardi',
                    'retl_CalloutMuleToSendAmendmentSRToYardi',
                    'pushAttachmentToYardi',
                    requestBody,
                    'Error: ' + (res != null ? res.ErrorMessage : response.getBody()),
                    caseId
                )
            );
        }
    }
    
    public class PushToYardiRequest {
        @InvocableVariable(label='Case Id' required=true description='The Id of the Case to send to Yardi')
        public Id caseId;
    }
}