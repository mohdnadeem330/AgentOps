/**
 * @description Queueable class for sending a specific Salesforce file (ContentVersion)
 *              related to an Opportunity/Contact to Yardi via MuleSoft.
 * 
 * @author 
 * vkotaprolu@aldar.com
 * @date 2025-11-06
 */
public with sharing class RETL_AttachmentSyncToYardiQueueable implements Queueable, Database.AllowsCallouts {

    private Id opportunityId;
    private Id fileId; // ContentVersion Id

    public RETL_AttachmentSyncToYardiQueueable(Id oppId, Id contentVersionId) {
        this.opportunityId = oppId;
        this.fileId = contentVersionId;
    }

    public void execute(QueueableContext context) {
        try {
            pushAttachmentToYardi(opportunityId, fileId);
        } catch (Exception e) {
            LoggerService.save(
                LoggerService.addApexServiceCalls(
                    'AttachmentSyncToYardi',
                    'RETL_AttachmentSyncToYardiQueueable',
                    'execute',
                    opportunityId,
                    e.getMessage(),
                    opportunityId
                )
            );
        }
    }

    // -------------------- Wrapper Classes --------------------
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

    // -------------------- Core Logic --------------------
    private static void pushAttachmentToYardi(Id oppId, Id contentVersionId) {

        Opportunity opp = [
            SELECT Id, Name, RETL_Yardi_Id__c
            FROM Opportunity
            WHERE Id = :oppId
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
        att.Record_Code = opp.RETL_Yardi_Id__c;
        att.Property_Code = '';
        att.Object_Type = '1783';
        att.Attachment_Type = 'Brand Profile';
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
                    'RETL_AttachmentSyncToYardiQueueable',
                    'pushAttachmentToYardi',
                    requestBody,
                    'Error: ' + (res != null ? res.ErrorMessage : response.getBody()),
                    oppId
                )
            );
        }
    }

    // Static helper to enqueue easily
    public static void enqueueJob(Id oppId, Id contentVersionId) {
        System.enqueueJob(new RETL_AttachmentSyncToYardiQueueable(oppId, contentVersionId));
    }

    public class CustomException extends Exception {}
}