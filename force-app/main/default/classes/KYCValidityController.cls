public with sharing class KYCValidityController {
    //This method is used to update the KYC_Validity_Status__c and KYC_Expired_Date__c of account to valid when Sales order's ComplianceStatus__c == Constants.CLEARED 
    public static void updateKYCvalidity(List<SObject> lstSaleOrders, Map<Id, SObject> mapSaleOrders) {
        List<Id> accountIds = new List<Id>();
        List<Account> lstAccount = new List<Account>();
        List<Account> lstAccountToBeChecked = new List<Account>();
        for (SalesOrder__c saleOrder : (List<SalesOrder__c>)lstSaleOrders) {
            if (saleOrder.ComplianceStatus__c == Constants.CLEARED && ((SalesOrder__c)mapSaleOrders.get(saleOrder.Id)).ComplianceStatus__c != Constants.CLEARED && saleOrder.Account__c != null) {
                accountIds.add(saleOrder.Account__c);
            }
        }
        lstAccountToBeChecked = getAccounts(accountIds);
        if (lstAccountToBeChecked.size() == 0) return;
        lstAccount = getUpdatedAccounts(lstAccountToBeChecked);        
        updateAccounts(lstAccount);
    }

    public static void updateKYCvalidityOnARCleared(List<SObject> lstAccountRelations, Map<Id, SObject> mapAccountRelations) {
        List<Id> accountIds = new List<Id>();
        List<Account> lstAccount = new List<Account>();
        List<Account> lstAccountToBeChecked = new List<Account>();
        for (AccountRelationship__c accountRelation : (List<AccountRelationship__c>)lstAccountRelations) {
            if (accountRelation.ComplianceStatus__c == Constants.CLEARED && ((AccountRelationship__c)mapAccountRelations.get(accountRelation.Id)).ComplianceStatus__c != Constants.CLEARED && accountRelation.Account__c != null) {
                accountIds.add(accountRelation.Account__c);                
            }
        }
        lstAccountToBeChecked = getAccounts(accountIds);
        if (lstAccountToBeChecked.size() == 0) return;
        lstAccount = getUpdatedAccounts(lstAccountToBeChecked);        
        updateAccounts(lstAccount);
    }

    public static List<Account> getUpdatedAccounts(List<Account> lstAccountToBeChecked) {
        List<Account> lstAccount = new List<Account>();
        for (Account acc : lstAccountToBeChecked) {
            if (acc.Nationality__pc == 'United Arab Emirates') {
                Account accountToBeUpdated = getAccount(acc.Id);
                accountToBeUpdated.KYC_Expired_Date__c = Date.today().addYears(2);
                lstAccount.add(accountToBeUpdated);
            } else if (acc.Nationality__pc != 'United Arab Emirates' && acc.ResidentStatus__pc == 'Resident') {
                Account accountToBeUpdated = getAccount(acc.Id);
                accountToBeUpdated.KYC_Expired_Date__c = Date.today().addYears(1);
                lstAccount.add(accountToBeUpdated);
            } else {
                // lstAccount.add(getAccount(acc.Id));
            }
        }
        return lstAccount;
    }

    public static List<Account> getAccounts(List<Id> accountIds) {
        return [SELECT Id,Nationality__pc,ResidentStatus__pc FROM Account WHERE Id IN : accountIds];
    }

    public static Account getAccount(Id accountId) {
        Account acc = new Account();
        acc.Id = accountId;
        acc.KYC_Validity_Status__c = Constants.VALID;
        acc.KYC_ValidityDate__c = Date.today();
        // acc.KYC_Expired_Date__c = Date.today().addYears(2);
        acc.KYC_StatusUpdatedBy__c = UserInfo.getUserId();
        // acc.KYC_ExpiryComments__c = 'Data Updated';
        return acc;
    }

    public static void updateAccounts(List<Account> lstAccount) {
        if (lstAccount.size() > 0) {
            update lstAccount;
        }
    }

    public static void populateKycStatusIfKycMandatoryFieldsUpdated(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
        List<KYC_Mandatory_Field__mdt> metadataList = KYC_Mandatory_Field__mdt.getall().values();
        Map<String,Schema.SObjectField> accountfields = Schema.Account.SObjectType.getDescribe().fields.getMap();
        String fieldApiNames = '';
        Boolean accountUpdated = false;
        for (Account acc : (List<Account>) newMap.values()) { 
            if (acc.KYC_Validity_Status__c == Constants.VALID && ( acc.RecordTypeId == Utilities.getRecordTypeId(Constants.ACCOUNT_OBJECT,Constants.PERSON_ACCOUNT_RT) || 
                acc.RecordTypeId == Utilities.getRecordTypeId(Constants.ACCOUNT_OBJECT,Constants.ORGANISATION_ACCOUNT_RT))){
                for(KYC_Mandatory_Field__mdt meta : metadataList){
                    System.debug('meta :' + meta);
                    if (meta.ObjectName__c != Constants.ACCOUNT_OBJECT) continue;
                    if(((Account)newMap.get(acc.Id)).get(meta.FieldAPI__c) != ((Account)oldMap.get(acc.Id)).get(meta.FieldAPI__c)){
                        System.debug('meta.FieldAPI__c :' + meta.FieldAPI__c);
                        Schema.DescribeFieldResult fieldResult = accountfields.get(meta.FieldAPI__c).getDescribe();
                        fieldApiNames = fieldApiNames + fieldResult.getLabel() + ', ';
                        accountUpdated = true;
                    }
                }
                System.debug('fieldApiNames : ' + fieldApiNames);
                if (accountUpdated) {
                    acc.KYC_Validity_Status__c = Constants.NOT_VALID;
                    acc.KYC_Expired_Date__c = null;
                    acc.KYC_ValidityDate__c = null;                   
                    acc.KYC_StatusUpdatedBy__c = UserInfo.getUserId();
                    acc.KYC_ExpiryComments__c = 'Data Updated : ' + fieldApiNames.removeEnd(',');
                }
            }         
        }
    }

      /*public static void populateKycStatusIfKycMandatoryFieldsUpdatedOnContact(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
        List<KYC_Mandatory_Field__mdt> metadataList = KYC_Mandatory_Field__mdt.getall().values();
        Map<String,Schema.SObjectField> contactfields = Schema.Contact.SObjectType.getDescribe().fields.getMap();
        List<Account> lstAccountToBeUpdated = new List<Account>();
        String fieldApiNames = '';
        Boolean contactUpdated = false;
        for (Contact con : (List<Contact>) newMap.values()) { 
            if (con.RecordTypeId != Utilities.getRecordTypeId(Constants.CONTACT_OBJECT,Constants.ORGANISATION_CONTACT_RT)) continue;
            for(KYC_Mandatory_Field__mdt meta : metadataList){
                if (meta.ObjectName__c != Constants.CONTACT_OBJECT) continue;
                if(((Contact)newMap.get(con.Id)).get(meta.FieldAPI__c) != ((Contact)oldMap.get(con.Id)).get(meta.FieldAPI__c)){
                    Schema.DescribeFieldResult fieldResult = contactfields.get(meta.FieldAPI__c).getDescribe();
                    fieldApiNames = fieldApiNames + fieldResult.getLabel() + ', ';
                    contactUpdated = true;
                }
            }
          if (contactUpdated) {
                Account acc = new Account();
                acc.Id = con.AccountId;
                acc.KYC_Validity_Status__c = Constants.NOT_VALID;
                acc.KYC_Expired_Date__c = null;
                acc.KYC_ValidityDate__c = null;                 
                acc.KYC_StatusUpdatedBy__c = UserInfo.getUserId();
                acc.KYC_ExpiryComments__c = 'Data Updated : ' + fieldApiNames.removeEnd(',');
                lstAccountToBeUpdated.add(acc);
            }       
        }
        if (lstAccountToBeUpdated.size() > 0) {
            update lstAccountToBeUpdated;
        }
    }*/ 
}