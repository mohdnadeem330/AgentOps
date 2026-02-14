public with sharing class JointOwnerandThirdpartyValidation {
    
    public class ValidationResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String errorMessage;
        
        public ValidationResult() {
            isValid = true;
            errorMessage = '';
        }
    }

    private static Boolean isPersonAccount(Id accountId) {
        Account acc = [
            SELECT Id, IsPersonAccount 
            FROM Account 
            WHERE Id = :accountId 
            LIMIT 1
        ];
        return acc.IsPersonAccount;
    }
    
    @AuraEnabled
    public static ValidationResult validateJointOwner(Id accountId) {
        ValidationResult result = new ValidationResult();
        try {
            if (!isPersonAccount(accountId)) return result;

            List<ValidationFields__mdt> metaList = [
                SELECT FieldAPI__c
                FROM ValidationFields__mdt
                WHERE ObjectName__c = 'Account'
                AND RecordType__c = 'Person'
                AND (Required_For_Account_Type__c LIKE '%Joint Owner%')
            ];
            
            if (metaList.isEmpty()) return result;
            
            List<String> fieldsToQuery = new List<String>();
            for (ValidationFields__mdt m : metaList) fieldsToQuery.add(m.FieldAPI__c);
            
            Account acc = Database.query(
                'SELECT ' + String.join(fieldsToQuery, ',') + ' FROM Account WHERE Id = :accountId LIMIT 1'
            );
            
            List<String> missingLabels = new List<String>();
            Map<String, Schema.SObjectField> accFieldsMap = Schema.SObjectType.Account.fields.getMap();
            
            for (String fieldName : fieldsToQuery) {
                if (acc.get(fieldName) == null) {
                    String label = accFieldsMap.containsKey(fieldName)
                        ? accFieldsMap.get(fieldName).getDescribe().getLabel()
                        : fieldName;
                    missingLabels.add(label);
                }
            }
            
            if (!missingLabels.isEmpty()) {
                result.isValid = false;
                result.errorMessage = 'Please fill in the following required fields in Account: ' + String.join(missingLabels, ', ');
            }
        } catch (Exception e) {
            result.isValid = false;
            result.errorMessage = 'Validation failed: ' + e.getMessage();
        }
        return result;
    }

    @AuraEnabled
    public static ValidationResult validateThirdParty(Id accountId) {
        ValidationResult result = new ValidationResult();
        try {
           
            if (!isPersonAccount(accountId)) return result;
            
            List<ValidationFields__mdt> metaList = [
                SELECT FieldAPI__c
                FROM ValidationFields__mdt
                WHERE ObjectName__c = 'Account'
                AND RecordType__c = 'Person'
                AND (Required_For_Account_Type__c LIKE '%Third Party%')
            ];
            
            if (metaList.isEmpty()) return result;
            
            List<String> fieldsToQuery = new List<String>();
            for (ValidationFields__mdt m : metaList) fieldsToQuery.add(m.FieldAPI__c);
            
            Account acc = Database.query(
                'SELECT ' + String.join(fieldsToQuery, ',') + ' FROM Account WHERE Id = :accountId LIMIT 1'
            );
            
            List<String> missingLabels = new List<String>();
            Map<String, Schema.SObjectField> accFieldsMap = Schema.SObjectType.Account.fields.getMap();
            
            for (String fieldName : fieldsToQuery) {
                if (acc.get(fieldName) == null) {
                    String label = accFieldsMap.containsKey(fieldName)
                        ? accFieldsMap.get(fieldName).getDescribe().getLabel()
                        : fieldName;
                    missingLabels.add(label);
                }
            }
            
            if (!missingLabels.isEmpty()) {
                result.isValid = false;
                result.errorMessage = 'Please fill in the following required fields in Account: ' + String.join(missingLabels, ', ');
            }
        } catch (Exception e) {
            result.isValid = false;
            result.errorMessage = 'Validation failed: ' + e.getMessage();
        }
        return result;
    }

    @AuraEnabled
    public static ValidationResult validateAccountDocumentsLWC(Id accountId) {
        ValidationResult result = new ValidationResult();
        try {
        
            if (!isPersonAccount(accountId)) return result;
            
            List<JointOwner__c> joList = new List<JointOwner__c>{
                new JointOwner__c(Account__c = accountId)
            };
            
            SalesOrderRelationshipTriggerHelper.validateAccountDocuemnts(
                (List<SObject>)joList, 'JointOwner__c'
            );
            
            List<Document__c> docs = [
                SELECT Id, DocumentType__c, 
                       (SELECT Id FROM ContentDocumentLinks) 
                FROM Document__c 
                WHERE Account__c = :accountId
                AND Status__c = 'Uploaded' 
                AND DocumentType__c IN ('Passport Copy','Signed KYC Form','National ID Back Copy','National ID Front Copy')
            ];
            
            Set<String> docTypes = new Set<String>();
            for (Document__c d : docs) {
                if (d.ContentDocumentLinks != null && !d.ContentDocumentLinks.isEmpty()) {
                    docTypes.add(d.DocumentType__c);
                }
            }
            
            Account acc = [SELECT Id, ResidentStatus__pc FROM Account WHERE Id = :accountId LIMIT 1];
            Boolean isValid = true;
            String missingMsg = '';
            
            if (acc.ResidentStatus__pc == 'Resident') {
                List<String> requiredDocs = new List<String>{'Passport Copy','Signed KYC Form','National ID Back Copy','National ID Front Copy'};
                List<String> missingDocs = new List<String>();
                for (String d : requiredDocs) if (!docTypes.contains(d)) missingDocs.add(d);
                if (!missingDocs.isEmpty()) {
                    isValid = false;
                    missingMsg = 'For Resident Accounts, the following documents are missing: ' + String.join(missingDocs, ', ');
                }
            } else if (acc.ResidentStatus__pc == 'Non-Resident') {
                List<String> requiredDocs = new List<String>{'Passport Copy','Signed KYC Form'};
                List<String> missingDocs = new List<String>();
                for (String d : requiredDocs) if (!docTypes.contains(d)) missingDocs.add(d);
                if (!missingDocs.isEmpty()) {
                    isValid = false;
                    missingMsg = 'For Non-Resident Accounts, the following documents are missing: ' + String.join(missingDocs, ', ');
                }
            }
            
            if (!isValid) {
                result.isValid = false;
                result.errorMessage = missingMsg;
            }
        } catch (Exception e) {
            result.isValid = false;
            result.errorMessage = 'Document validation failed: ' + e.getMessage();
        }
        return result;
    }
}