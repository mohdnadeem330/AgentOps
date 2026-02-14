/*Apex Class Name    : BrokerRenderPDFInvocable
Created Date       : 25-09-2024
@description       : This class is used to send Suspension/Warning letters to Agency/ Agent
                     calling from flow,
                     this class is covered from Apex class SuspensionWarningTriggerHandlerTest
@author            : Moh Sarfaraj
Modification Log:
Ver   Date              Author                               Modification
1.0  25-09-2024      Moh Sarfaraj                          Initial Version
*****************************************************************************************
*/
public without sharing class BrokerRenderPDFInvocable {
    
    @InvocableMethod(label='Render as PDF and Create Document for suspension/warning')
    public static void uploadSuspensionWarningLetter(List<Id> ids){

        Map<Id, Suspensions_Warning__c> mapSuspensions = new Map<Id, Suspensions_Warning__c>();
        Map<Id, Id> mapAgencyIdToSuspensionId = new Map<Id, Id>();
        Map<Id, Id> mapAgencyIdToWarningId = new Map<Id, Id>();

        for (Suspensions_Warning__c sw : [
            SELECT Id, SuspensionWarning__c, BrokerAgency__c
            FROM Suspensions_Warning__c
            WHERE Id IN :ids
        ]) {
            mapSuspensions.put(sw.Id, sw);

            if (sw.SuspensionWarning__c == 'Suspension' && sw.BrokerAgency__c != null) {
                mapAgencyIdToSuspensionId.put(sw.BrokerAgency__c, sw.Id);
            }
            if (sw.SuspensionWarning__c == 'Warning' && sw.BrokerAgency__c != null) {
                mapAgencyIdToWarningId.put(sw.BrokerAgency__c, sw.Id);
            }
        }

        Integer delayInMinutes = 2;

        if (!mapAgencyIdToSuspensionId.isEmpty()) {
            System.enqueueJob(
                new BrokerEmailQueue(mapAgencyIdToSuspensionId, mapSuspensions, true, true),
                delayInMinutes
            );
        }

        if (!mapAgencyIdToWarningId.isEmpty()) {
            System.enqueueJob(
                new BrokerEmailQueue(mapAgencyIdToWarningId, mapSuspensions, true, false),
                delayInMinutes
            );
        }
    }

    public class BrokerEmailQueue implements Queueable {

        Map<Id, Id> mapAgencyIdToRecordId;
        Map<Id, Suspensions_Warning__c> mapSuspensions;
        Boolean isForAgency;
        Boolean isSuspension;

        public BrokerEmailQueue(
            Map<Id, Id> mapAgencyIdToRecordId,
            Map<Id, Suspensions_Warning__c> mapSuspensions,
            Boolean isForAgency,
            Boolean isSuspension
        ) {
            this.mapAgencyIdToRecordId = mapAgencyIdToRecordId;
            this.mapSuspensions = mapSuspensions;
            this.isForAgency = isForAgency;
            this.isSuspension = isSuspension;
        }

        public void execute(QueueableContext qc) {

            Map<Id, User> mapAgencyToUser = new Map<Id, User>();
            Map<Id, List<String>> mapAgencyToEmails = new Map<Id, List<String>>();

            for (User u : [
                SELECT Id, Email, AccountId, Account.Email__c
                FROM User
                WHERE AccountId IN :mapAgencyIdToRecordId.keySet()
            ]) {
                mapAgencyToUser.put(u.AccountId, u);

                if (!mapAgencyToEmails.containsKey(u.AccountId)) {
                    mapAgencyToEmails.put(u.AccountId, new List<String>());
                }
                if (u.Email != null) {
                    mapAgencyToEmails.get(u.AccountId).add(u.Email);
                }
                if (u.Account.Email__c != null) {
                    mapAgencyToEmails.get(u.AccountId).add(u.Account.Email__c);
                }
            }

            OrgWideEmailAddress owea = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE DisplayName = 'Aldar Agency Support'
                LIMIT 1
            ];

            List<String> ccEmails =
                new List<String>(System.Label.BPM_SuspensionWarningCCEmailAddresses.split(','));

            Map<String, EmailTemplate> mapTemplates = new Map<String, EmailTemplate>();
            for (EmailTemplate et : [
                SELECT Id, DeveloperName
                FROM EmailTemplate
                WHERE DeveloperName IN (
                    'BrokerSuspensionEmailTemplate',
                    'BrokerWarningEmailTemplate'
                )
            ]) {
                mapTemplates.put(et.DeveloperName, et);
            }

            Map<Id, ContentVersion> mapRecordToAttachment = new Map<Id, ContentVersion>();
            String docType = isSuspension ? 'Suspension Letter' : 'Warning Letter';

            List<Document__c> docs = [
                SELECT Id, Suspensions_Warning__c
                FROM Document__c
                WHERE DocumentType__c = :docType
                AND Suspensions_Warning__c IN :mapSuspensions.keySet()
                ORDER BY CreatedDate DESC
            ];

            Map<Id, Id> docToRecord = new Map<Id, Id>();
            for (Document__c d : docs) {
                if (!docToRecord.containsKey(d.Id)) {
                    docToRecord.put(d.Id, d.Suspensions_Warning__c);
                }
            }

            Map<Id, Id> recordToContentVersionId = new Map<Id, Id>();
            Set<Id> contentVersionIds = new Set<Id>();

            for (ContentDocumentLink cdl : [
                SELECT ContentDocument.LatestPublishedVersionId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :docToRecord.keySet()
            ]) {
                Id recordId = docToRecord.get(cdl.LinkedEntityId);

                if (!recordToContentVersionId.containsKey(recordId)) {
                    recordToContentVersionId.put(
                        recordId,
                        cdl.ContentDocument.LatestPublishedVersionId
                    );
                    contentVersionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
                }
            }

            Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>(
                [
                    SELECT Id, Title, FileType, VersionData
                    FROM ContentVersion
                    WHERE Id IN :contentVersionIds
                ]
            );

            for (Id recordId : recordToContentVersionId.keySet()) {
                Id cvId = recordToContentVersionId.get(recordId);
                if (contentVersionMap.containsKey(cvId)) {
                    mapRecordToAttachment.put(recordId, contentVersionMap.get(cvId));
                }
            }

            List<Messaging.SingleEmailMessage> listEmails = new List<Messaging.SingleEmailMessage>();

            for (Id agencyId : mapAgencyIdToRecordId.keySet()) {

                Id recordId = mapAgencyIdToRecordId.get(agencyId);

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(mapAgencyToEmails.get(agencyId));
                mail.setTargetObjectId(mapAgencyToUser.get(agencyId).Id);
                mail.setOrgWideEmailAddressId(owea.Id);
                mail.setCcAddresses(ccEmails);
                mail.setSaveAsActivity(false);

                if (mapRecordToAttachment.containsKey(recordId)) {
                    ContentVersion cv = mapRecordToAttachment.get(recordId);

                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(cv.Title + '.' + cv.FileType);
                    efa.setBody(cv.VersionData);
                    efa.setInline(false);

                    mail.setFileAttachments(
                        new Messaging.EmailFileAttachment[] { efa }
                    );
                }

                mail.setTemplateId(
                    isSuspension
                        ? mapTemplates.get('BrokerSuspensionEmailTemplate').Id
                        : mapTemplates.get('BrokerWarningEmailTemplate').Id
                );

                listEmails.add(mail);
            }

            if (!listEmails.isEmpty()) {
                Messaging.sendEmail(listEmails);
            }
        }
    }
}