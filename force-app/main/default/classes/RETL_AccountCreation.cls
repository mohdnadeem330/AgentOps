public with sharing class RETL_AccountCreation {

    // --- Get Lead details  ---
    @AuraEnabled(cacheable=true)
    public static Lead getLeadDetails(Id leadId) {
        if (leadId == null) {
            throw new AuraHandledException('Lead Id is required.');
        }

        return [
            SELECT Id, Name, RETL_Brand__c, RETL_Brand__r.Name,
                   RETL_Group__c, RETL_Group__r.Name
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
    }

    // --- Create Account and optionally update Lead  ---
    @AuraEnabled
    public static Account createAccount(
        String name, 
        String type, 
        Id leadId, 
        Id brandId, 
        Id groupId, 
        String uaeVATRegisterNumber, 
        String taxAuthority 
    ) { 
        if (String.isBlank(name) || String.isBlank(type)) {
            throw new AuraHandledException('Name and Type are required.');
        }

        Account createdOrUpdatedAccount = null;

        // Check for the special case where we only update the Lead's associations
        if (type.equalsIgnoreCase('UpdateLead')) {
            if (leadId == null) {
                 throw new AuraHandledException('Lead Id is required for association update.');
            }

            Lead leadToUpdate = [
                SELECT Id, RETL_Brand__c, RETL_Group__c
                FROM Lead
                WHERE Id = :leadId
                LIMIT 1
            ];
            
            leadToUpdate.RETL_Brand__c = brandId; 
            leadToUpdate.RETL_Group__c = groupId;
            
            update leadToUpdate;

            // Return a dummy Account with the Lead ID for LWC flow navigation
            return new Account(); 
        } 
        
        // --- Standard Case: Create a new Account (Brand or Group) ---
        else {
            
            Map<String, Id> recordTypeMap = new Map<String, Id>();
            for (RecordType rt : [
                SELECT Id, DeveloperName 
                FROM RecordType         
                WHERE SObjectType = 'Account' AND DeveloperName IN ('RETL_Brand', 'OrganizationAccount')
            ]) {
                recordTypeMap.put(rt.DeveloperName, rt.Id);
            }

            Account acc = new Account();
            acc.Name = name;
            acc.UAEVATRegisterNumber__c = uaeVATRegisterNumber;
            acc.RETL_Tax_Authority__c = taxAuthority;
            

            if (brandId != null) {
                acc.put('RETL_Brand__c', brandId);
            }
            if (groupId != null) {
                acc.put('RETL_Group__c', groupId);
            }

            if (type.equalsIgnoreCase('Brand')) {
                acc.Type = 'Brand';
                acc.RecordTypeId = recordTypeMap.get('RETL_Brand');
                acc.Type = 'Brand'; 
                acc.RETL_Status__c = 'Active';
            } else if (type.equalsIgnoreCase('Group')) {
                acc.Type = 'Group';
                acc.RecordTypeId = recordTypeMap.get('OrganizationAccount');
                acc.Type = 'Group';
                acc.RETL_Status__c = 'Active';
            } else {
                throw new AuraHandledException('Invalid creation type selected.');
            }

            insert acc;
            // Callout to Yardi
            RETL_AccountSyncToYardi.pushToYardiAsync(acc.id); 
            createdOrUpdatedAccount = acc;

            // Optional: Update Lead association
            if (leadId != null) {
                Lead leadToUpdate = [
                    SELECT Id, RETL_Brand__c, RETL_Group__c
                    FROM Lead
                    WHERE Id = :leadId
                    LIMIT 1
                ];
                
                Id finalBrandId = brandId;
                Id finalGroupId = groupId;
                
                if (type.equalsIgnoreCase('Brand')) {
                    finalBrandId = createdOrUpdatedAccount.Id;
                } 
                else if (type.equalsIgnoreCase('Group')) {
                    finalGroupId = createdOrUpdatedAccount.Id;
                }

                if (finalBrandId != null) {
                    leadToUpdate.RETL_Brand__c = finalBrandId;
                }
                if (finalGroupId != null) {
                    leadToUpdate.RETL_Group__c = finalGroupId;
                }

                update leadToUpdate;
            }

            return createdOrUpdatedAccount;
        }
    }
}