public without sharing class UploadDocumentLinkController {
     @AuraEnabled(cacheable=false)
    public static String generateAndSaveEncryptedKey(Id caseId) {

        //Encrypt Case Id
        String encryptedKey = EncryptionUtils.encryptString(caseId);
        //String safeToken = encryptedKey.replaceAll('[^a-zA-Z0-9]', ''); 
        //String urlSafeKey = EncodingUtil.urlEncode(encryptedKey, 'UTF-8');
        Integer expiryHours = Integer.valueOf(Label.Token_Expiry_Hours);


        //Save on Case
        Case c = new Case(
            Id = caseId,
            Encrypted_Token__c = encryptedKey , Token_Expiry_Date__c = system.now().addHours(expiryHours)

        );
        update c;       
        return encryptedKey;
    }


  @AuraEnabled
    public static Id validateEncryptedToken(String token) {
        if (String.isBlank(token)) {
            throw new AuraHandledException('Missing token');
        }
        system.debug('token-->>>'+token);
        // Look for a Case with matching token
        //String decodedToken = EncodingUtil.urlDecode(token, 'UTF-8');
        token = token.replace(' ', '+');
        List<Case> caseList = [SELECT Id, Encrypted_Token__c FROM Case WHERE Encrypted_Token__c = :token  AND Token_Expiry_Date__c >: system.now() LIMIT 1];
       
        if (caseList != null && caseList.size() > 0) {
             return caseList[0].Id;
        }else {
            throw new AuraHandledException('Invalid or expired token.'+token);
        }
       
    }

    @AuraEnabled
    public static void uploadFilesToCase(Id caseId, List<Id> contentDocumentIds) {
        if (caseId == null || contentDocumentIds.isEmpty()) {
            throw new AuraHandledException('No files to upload or invalid Case.');
        }

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for(Id docId : contentDocumentIds){
            links.add(new ContentDocumentLink(
                ContentDocumentId = docId,
                LinkedEntityId = caseId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }
        insert links;
        
        Case cse = [ SELECT Id, RecordType.DeveloperName FROM Case WHERE Id = :caseId ];

        Case c = new Case( Id = caseId, Encrypted_Token__c = null, Status = 'Work In Progress' );
        if( cse.RecordType.DeveloperName.equalsIgnoreCase('Complaints') 
            || cse.RecordType.DeveloperName.equalsIgnoreCase('Queries')
            ||cse.RecordType.DeveloperName.equalsIgnoreCase('Requests') ){
                 c.Sub_Status__c = 'Follow up by Customer' ;
        }

       update c;
    }
    
    @AuraEnabled(cacheable=true)
    public static Case getCaseDetails(Id caseId) {
        return [
            SELECT Id, CaseNumber, Subject, Status
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }

}