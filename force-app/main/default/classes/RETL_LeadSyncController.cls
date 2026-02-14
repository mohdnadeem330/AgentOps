/**
 * @description
 * Handles synchronization and retrieval of Yardi-related data for Lead/Opportunity
 * processing within Salesforce. This class exposes Aura-enabled methods used by
 * Lightning components to fetch necessary Yardi identifiers (Opportunity, Account,
 * Brand, Contact, Trade Licence, ContentVersion, etc.) and initiate MuleSoft
 * synchronization for Opportunity data.
 *
 * @author vkotaprolu@aldar.com
 * @date 2025-10-24
 */

public with sharing class RETL_LeadSyncController {
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getYardiRelatedInfo(Id opportunityId) {
        Map<String, String> yardiInfo = new Map<String, String>();
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity Id is required.');
        }
        
        // Query must be bulkified, but since it's an AuraEnabled method accepting a single ID,
        // this query is acceptable for the entry point.
        Opportunity opp = [
            SELECT 
                Id, AccountId, RETL_Yardi_Id__c, RETL_Lead_Financial_Yardi_Id__c, StageName,
                RETL_Brand__c, RETL_Brand__r.RETL_Yardi_Id__c,
                Account.RETL_Yardi_Id__c, Account.RETL_Group__c, RETL_AM_PreApproval__c,
                Account.RETL_Group__r.RETL_Yardi_Id__c, RETL_Yardi_Proposal_Id__c,
                RETL_Tenant_Code__c,Leasing_Committee_Approval_Status__c,RETL_Proposal_Status__c,
                (SELECT id FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        yardiInfo.put('PreApprovalStatus', opp.RETL_AM_PreApproval__c);      
        Integer lineItemCount = opp.OpportunityLineItems.size();
        yardiInfo.put('OpportunityLineItemCount', String.valueOf(lineItemCount));

        // --- 1. Get Trade Licence Yardi ID ---
        if (opp.AccountId != null) {
            List<Account> tradeLicences = [
                SELECT Id, ParentId, RETL_Yardi_Id__c 
                FROM Account 
                WHERE ParentId = :opp.accountId 
                LIMIT 1
            ];
            
            if (!tradeLicences.isEmpty()) {
                yardiInfo.put('TradeLicenceYardiId', tradeLicences[0].RETL_Yardi_Id__c);
            } else {
                yardiInfo.put('TradeLicenceYardiId', null);
            }
        } else {
             yardiInfo.put('TradeLicenceYardiId', null);
        }

        // --- 2. Opportunity, Account, and Brand IDs ---
        yardiInfo.put('OpportunityYardiId', opp.RETL_Yardi_Id__c);
        yardiInfo.put('OpportunityFinanceYardiId', opp.RETL_Lead_Financial_Yardi_Id__c);
        yardiInfo.put('AccountYardiId', opp.Account != null ? opp.Account.RETL_Yardi_Id__c : null);
        yardiInfo.put('BrandYardiId', opp.RETL_Brand__c != null ? opp.RETL_Brand__r.RETL_Yardi_Id__c : null);
        yardiInfo.put('OpportunityStage', opp.StageName);
        yardiInfo.put('TenantCode', opp.RETL_Tenant_Code__c);
        yardiInfo.put('ProposalYardiId', opp.RETL_Yardi_Proposal_Id__c);
        yardiInfo.put('LcApprovalStatus', opp.Leasing_Committee_Approval_Status__c);
        yardiInfo.put('ProposalStatus', opp.RETL_Proposal_Status__c);
        



        // --- 3. Group Code ---
        String groupCode = 'Not Applicable';
        if (opp.AccountId != null && opp.Account != null && opp.Account.RETL_Group__c != null) {
            groupCode = opp.Account.RETL_Group__r.RETL_Yardi_Id__c;
        }
        yardiInfo.put('GroupYardiId', groupCode);


        // --- 4. Contact Yardi ID & Contact Role Yardi ID ---
        Id contactId = null;
        if (opp.AccountId != null) {
            List<Contact> contacts = [
                SELECT 
                    Id, RETL_Yardi_Id__c, 
                    (SELECT Id, RETL_Yardi_Id__c FROM Contact_Roles__r LIMIT 1) // Assuming Contact_Roles__r is a custom relationship name
                FROM Contact
                WHERE AccountId = :opp.AccountId
                LIMIT 1
            ];
            
            if (!contacts.isEmpty()) { 
                Contact firstContact = contacts[0];
                yardiInfo.put('ContactYardiId', firstContact.RETL_Yardi_Id__c);
                contactId = firstContact.Id;

                if (firstContact.Contact_Roles__r != null && !firstContact.Contact_Roles__r.isEmpty()) { 
                    yardiInfo.put('ContactRoleYardiId', firstContact.Contact_Roles__r[0].RETL_Yardi_Id__c); 
                } else {
                    yardiInfo.put('ContactRoleYardiId', null);
                }
            } else {
                yardiInfo.put('ContactYardiId', null);
                yardiInfo.put('ContactRoleYardiId', null);
            }
        } else {
            yardiInfo.put('ContactYardiId', null);
            yardiInfo.put('ContactRoleYardiId', null);
        }

        // --- 5. Get ContentVersion Yardi ID (from related Contact files) ---        
        List<Document__c> docList = [
            SELECT Id, Lead__c, Opportunity__c 
            FROM Document__c 
            WHERE DocumentType__c ='Brand Profile' AND Opportunity__c =: opportunityId
        ];       
        if (!docList.isEmpty()) {
            // 5a. Get ContentDocumentIds linked to the Contact
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink cdl : [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :docList[0].Id
            ]) {
                contentDocumentIds.add(cdl.ContentDocumentId);
            }
            
            if (!contentDocumentIds.isEmpty()) {
                
                // 5b. Query ContentVersion using the collected ContentDocumentIds
                List<ContentVersion> versions = [
                    SELECT Id, Title, RETL_Yardi_Id__c
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentDocumentIds
                    
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                
                if (!versions.isEmpty()) { 
                    yardiInfo.put('ContentVersionYardiId', versions[0].RETL_Yardi_Id__c);
                } else {
                    yardiInfo.put('ContentVersionYardiId', null);
                }
            } else {
                yardiInfo.put('ContentVersionYardiId', null);
            }
        } else {
            yardiInfo.put('ContentVersionYardiId', null);
        }

        // 6 Trade License
        Id tradeLicenseAccountId = null;

        if (opp.AccountId != null) {
            List<Account> tradeLicences = [
                SELECT Id
                FROM Account
                WHERE ParentId = :opp.AccountId
                AND Type = 'Trade License' and ECSS_Trade_License_Number__c=NULL
                LIMIT 1
            ];
            
            if (!tradeLicences.isEmpty()) {
                tradeLicenseAccountId = tradeLicences[0].Id;
            }
        }

        yardiInfo.put('TradeLicenseAccountId', tradeLicenseAccountId);

        return yardiInfo;
    }

    @AuraEnabled
    public static String syncOpportunityToYardi(Id opportunityId) {        
        try {
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity Id is required.');
            }
            // ASSUMPTION: The RETL_LeadSyncToYardi class and pushToYardiAndUpdate method exist.
            RETL_LeadSyncToYardi.pushToYardiAndUpdate(opportunityId); 
            return 'Yardi sync initiated successfully';
        } catch (Exception e) {
            System.debug('Error in syncOpportunityToYardi: ' + e.getMessage());
            // Pass a generic error message to the client, logging the full details on the server.
            throw new AuraHandledException('Yardi sync failed: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void pushLCApprovalToYardi(Id opportunityId) {
        RETL_LCApprovalToYardi.pushLCApproval(opportunityId);
    }

    @AuraEnabled
    public static Id updateOpportunityStageAndReason(Id oppId, String stageName, String lossReason, String comments , String actionType ) {
        system.debug(stageName+' -- '+lossReason + ' -- ' + comments + ' ' + actionType);
        Opportunity opp = [SELECT Id, Name,StageName, LossReason__c, LossComments__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
        Id clonedOppId;
        
        if (actionType == 'CloneAndCancel') {
            // Get all editable + accessible fields on Opportunity
            Map<String, Schema.SObjectField> fieldsMap = Opportunity.SObjectType.getDescribe().fields.getMap();
            List<String> cloneableFields = new List<String>();

            for (Schema.SObjectField field : fieldsMap.values()) {
                Schema.DescribeFieldResult f = field.getDescribe();
                if (f.isAccessible() && f.isUpdateable()) {
                    cloneableFields.add(f.getName());
                }
            }

            // Dynamic query for all permitted fields
            String dynamicQuery = 'SELECT Id, ' + String.join(cloneableFields, ',') +
                                ' FROM Opportunity WHERE Id = :oppId';
            Opportunity fullOpp = Database.query(dynamicQuery);

            // Clone manually
            Opportunity clonedOpp = new Opportunity();

            for (String fieldName : cloneableFields) {
                if (fullOpp.get(fieldName) != null && fieldName != 'Id') {
                    clonedOpp.put(fieldName, fullOpp.get(fieldName));
                }
            }
            insert clonedOpp;

            //Resets
            clonedOpp.Name = opp.Name;
            clonedOpp.StageName = 'Deal In Progress';
            update clonedOpp;
            clonedOppId = clonedOpp.Id;
        }

        // ----------------------------------
        // UPDATE ORIGINAL OPP → Closed Lost
        // ----------------------------------
        opp.StageName = stageName;
        opp.LossReason__c = lossReason;
        opp.LossComments__c = comments;
        update opp;

        try {
            // Use the reason from LWC (lossReason)
            RETL_CancelProposalInYardi.pushCancelProposal(opp.Id, lossReason);
        } catch (Exception e) {
            System.debug('Error calling Cancel Proposal to Yardi: ' + e.getMessage());
            // Optionally, log using LoggerService
        }
        return clonedOppId;        
    }

    @AuraEnabled
    public static void syncProposalToYardi (string oppId) {
        try{
            System.enqueueJob(new RETL_WorkOrderForDealUpdateQueueable(oppId));
        }catch (DmlException e) {
        
        }
    }


    

}