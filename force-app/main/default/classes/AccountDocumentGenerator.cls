public without sharing class AccountDocumentGenerator {

    @AuraEnabled
    public static Boolean generateAllDocuments(String accountId){
        try {
            List<Id> lstDocIds = new List<Id>();
            List<Id> lstDocIdToBeShared = new List<Id>();
            // OU_DocumentGenerationHelper.generateDocumentsForAccount(accountId);
            List<Account> lstAccount = [SELECT Id, RecordTypeId, CustomerType__c FROM Account WHERE Id =: accountId];
            
            for(Document__c tempDoc : [SELECT Id, DocumentType__c, Account__c, OwnerId FROM Document__c WHERE Account__c =: accountId]){
                if (tempDoc.OwnerId != UserInfo.getUserId()) {
                    lstDocIds.add(tempDoc.Id);
                }
            }
            for (UserRecordAccess recAccess : [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: UserInfo.getUserId() AND RecordId IN : lstDocIds]) {
                if (!recAccess.HasEditAccess) {
                    lstDocIdToBeShared.add(recAccess.RecordId);
                }
            }
            if (lstDocIdToBeShared.size() > 0) {
                shareDocumentRecordWithLoggedInUser(lstDocIdToBeShared);
            }
            AccountTriggerHandler.createAccountDocuments(lstAccount);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return true;
    }

    public static void shareDocumentRecordWithLoggedInUser(List<Id> lstDocIdToBeShared) {
        List<Document__Share> lstDocShare = new List<Document__Share>();
        for (Id docId : lstDocIdToBeShared) {
            Document__Share docShare = new Document__Share();
            docShare.ParentId = docId;
            docShare.UserOrGroupId = UserInfo.getUserId();
            docShare.AccessLevel = 'Edit';
            docShare.RowCause = 'Manual';
            lstDocShare.add(docShare);
        }
        if (lstDocShare.size() > 0) {
            insert lstDocShare;
        }
    }
}