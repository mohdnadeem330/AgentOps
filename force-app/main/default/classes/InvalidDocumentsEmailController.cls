Global class InvalidDocumentsEmailController {
    Global String recordId { get; set; }
    Global String rejectionReason { get; set; }
    Global String accountName { get; set; }
    Global List<Document__c> documents;
    Global List<Document__c> getDocuments() {
        if(recordId!=null) {
            List<Document__c> documents = [
                SELECT Id, Name, DocumentType__c, Reason_For_Invalid__c, Opportunity__r.Account.Name
                FROM Document__c
                WHERE Opportunity__c = :recordId
                AND Status__c = 'Invalid Document'
            ];
            if(documents!=null && !documents.isEmpty()) {
                rejectionReason = documents[0].Reason_For_Invalid__c;
                accountName = documents[0].Opportunity__r.Account.Name;
            }
            return documents;
        }
        return null;
    }
}