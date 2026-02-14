public with sharing class PIOpportunitySubmissionController {

    @AuraEnabled
    public static String submitOpportunity(String opportunityId) {
        Opportunity currentOppRecord = [SELECT Id,Approval_Status__c FROM Opportunity WHERE Id =: opportunityId];
        List<Document__c> listName = new List<Document__c>();
        Map<String, String> docStatus = new Map<String, String>();
        Boolean documentUploaded = true;
        String userId = System.UserInfo.getUserId();
        Set<String> documents = new Set<String>();
        String docsMissing ='';
        
        for (Document__c doc : [SELECT Id,Status__C,DocumentType__c FROM Document__c WHERE Opportunity__c =: opportunityId]) {
            docStatus.put(doc.DocumentType__c, doc.Status__c);
        }
        //System.debug(JSON.serializePretty(docStatus));
        
        if(currentOppRecord.Approval_Status__c == 'None'){
            documents.addall(Label.P_I_Validation_Stage_Document.split(','));
        }else if(currentOppRecord.Approval_Status__c == 'Validation approved'){
            documents.addall(Label.P_I_Execution_Stage_Document.split(','));
        }else if(currentOppRecord.Approval_Status__c == 'Execution approved'){
            documents.addall(Label.P_I_Investment_Monitoring_Stage_Document.split(','));
        }else if(currentOppRecord.Approval_Status__c == 'Investment Monitoring approved'){
            documents.addall(Label.P_I_Exit_Stage_Document.split(','));
        }
        for (String doc : documents) {
            if(docStatus.containsKey(doc)  ){
                if( docStatus.get(doc) != 'Uploaded'  ){
                    documentUploaded = false;
                    docsMissing += doc+', ';
                    //system.debug('documentUploaded>>'+documentUploaded);
                }
            }else {
                documentUploaded = false;
                docsMissing += doc+', ';
                //system.debug('documentUploaded>>'+documentUploaded);
            }
        }
        //system.debug('documentUploaded>>'+documentUploaded);
        if(documentUploaded){
        
            if(currentOppRecord.Approval_Status__c == 'None'){
                currentOppRecord.Approval_Status__c = 'Validation in review';
            }else if(currentOppRecord.Approval_Status__c == 'Validation approved'){
                currentOppRecord.Approval_Status__c = 'Execution in review';
            }else if(currentOppRecord.Approval_Status__c == 'Execution approved'){
                currentOppRecord.Approval_Status__c = 'Investment Monitoring in review';
            }else if(currentOppRecord.Approval_Status__c == 'Investment Monitoring approved'){
                currentOppRecord.Approval_Status__c = 'Exit in review';
            }
            currentOppRecord.Submitted_for_Review_Date__c = System.Date.today();
            update currentOppRecord;
        }
        return docsMissing;
    }
}