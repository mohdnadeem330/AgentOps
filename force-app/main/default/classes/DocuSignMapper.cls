public class DocuSignMapper {
    public static List<String> RecipientTypeSequence = new List<String>{'BUYER', 'SELLER'};
    // replacing recordId with docRecordId
    // related account id can be multiple as buyer and seller, so instaed, going to use a map <Id, String> Id be acc Id and String either be Buyer or Seller, separate them for users  
    // relatedsObjectId : can be Opportunity or Sales Order to get joint owners, so instead going to use map <Id, String> Id be related Object Id like Sales Order or Opportunity and String either be Buyer or Seller : loop over, identify sObject, separate it for joint owners parent object Sales Order or Opportunity
    // relatedSignDocumentId: be same
    public static DocuSignWrapper.EnvelopeWrapper createEnvelopeWrapper(String docRecordId, List<DocuSignWrapper.Signer> signers){
        DocuSignWrapper.EnvelopeWrapper envelopeWrapper = new DocuSignWrapper.EnvelopeWrapper();
        
        envelopeWrapper.documentRecordId = getDocumentRecord(docRecordId).Id;
        envelopeWrapper.contentVersion = getFile(docRecordId);
        envelopeWrapper.isNormalSign = false;
        envelopeWrapper.recipients = getRecipients(signers);
        
        return envelopeWrapper;
    }

    public static List<DocuSignWrapper.RecipientWrapper> getRecipients(List<DocuSignWrapper.Signer> signers) {
        
        List<DocuSignWrapper.RecipientWrapper> recipients = new List<DocuSignWrapper.RecipientWrapper>();
        
        Map<Id, String> relatedAccIdToTypeMap = new Map<Id, String>();
        Map<Id, String> relatedSObjectIdToTypeMap = new Map<Id, String>();
        Map<Id, Set<Id>> relatedAccIdToRelatedSObjectIdSetMap = new Map<Id, Set<Id>>();
        for(DocuSignWrapper.Signer s : signers){
            relatedAccIdToTypeMap.put(s.primaryCustomerId, s.type);
            if(s.relatedSObjectIds != null && !s.relatedSObjectIds.isEmpty()){
                relatedAccIdToRelatedSObjectIdSetMap.put(s.primaryCustomerId, s.relatedSObjectIds);
                for(Id ri: s.relatedSObjectIds){
                    relatedSObjectIdToTypeMap.put(ri, s.type);
                }
            }
        }
        
        Map<String, List<Account>> relationTypeToAccountsListMap = getPrimaryAccountsMap(relatedAccIdToTypeMap);
        Map<String, List<JointOwner__c>> relationTypeToJointOwnersListMap = getJointOwnersMap(relatedSObjectIdToTypeMap);

        Integer routingOrder = 1;
        for(String recipientType : RecipientTypeSequence ){
            if(relationTypeToAccountsListMap.containsKey(recipientType)){
                for(Account acc: relationTypeToAccountsListMap.get(recipientType)){
                    // create recipeint wrapper
                    recipients.add(
                        createRecipient(
                            acc.isPersonAccount,
                            acc.isPersonAccount ? acc.Name : acc.Contacts[0].Name, // acc.isPersonAccount ? (acc.FirstName + ' '+ acc.LastName) : (acc.Contacts[0].FirstName + ' '+ acc.Contacts[0].LastName),
                            acc.isPersonAccount ? acc.PersonEmail : acc.Contacts[0].Email,
                            acc.Id,
                            routingOrder 
                    ));
                    routingOrder++;
                    if(relatedAccIdToRelatedSObjectIdSetMap.containsKey(acc.Id) ){
                        for(Id relatedSObjectId : relatedAccIdToRelatedSObjectIdSetMap.get(acc.Id) ){
                            if(relationTypeToJointOwnersListMap.containsKey(relatedSObjectId+'_'+recipientType)){
                                for(JointOwner__c jo : relationTypeToJointOwnersListMap.get(relatedSObjectId+'_'+recipientType)){
                                    // create recipeint wrapper
                                    recipients.add(
                                        createRecipient(
                                            jo.Account__r.isPersonAccount,
                                            jo.Account__r.Name, 
                                            jo.Email__c,
                                            jo.Account__r.Id,
                                            routingOrder
                                    ));
                                    routingOrder++;
                                }
                            }
                        }
                    }
                }
            }
        }
        return recipients;
    }

    public static DocuSignWrapper.RecipientWrapper createRecipient(Boolean isPersonAccount, String name, String email, String accountNumber, Integer routingOrder) {
        DocuSignWrapper.RecipientWrapper recipient = new DocuSignWrapper.RecipientWrapper();
            recipient.name = name;
            recipient.email = email;
            recipient.routingOrder = routingOrder;
            recipient.role = String.valueOf(routingOrder);
            recipient.signerType = 'Signer';
            recipient.recipientPlaceHolders = new DocuSignWrapper.RecipientTabs();
            recipient.recipientPlaceHolders.recipientSignHolder = accountNumber+ (isPersonAccount ? 'SignatureHolder' : 'OrgSignatureHolder') ;
            recipient.recipientPlaceHolders.recipientDateHolder = accountNumber+ (isPersonAccount ? 'DateHolder' : 'OrgDateHolder') ;
            recipient.recipientPlaceHolders.recipientInitialHolder = accountNumber+ (isPersonAccount ? 'InitialsHolder' : 'OrgInitialsHolder');
            recipient.recipientPlaceHolders.recipientNameHolder = accountNumber+ (isPersonAccount ? 'NameHolder' : 'OrgNameHolder') ;
        return recipient;
    }

    public static Document__c getDocumentRecord(Id docRecordId) {
        List<Document__c> documentRecords = [SELECT Id, Identityverification__c, DocumentType__c,
                                                Account__c, 
                                                Case__c, Case__r.AccountId, Case__r.RecordType.DeveloperName,
                                                Opportunity__c, Opportunity__r.AccountId, Opportunity__r.RecordType.DeveloperName,
                                                SalesOrder__c, SalesOrder__r.UnitNumber__c, SalesOrder__r.Account__c 
                                             FROM Document__c 
                                             WHERE Id=: docRecordId 
                                             LIMIT 1 ];
        return documentRecords[0];
    }

    public static ContentVersion getFile(Id docRecordId){
        Map<Id, Id> documentToContentVersionId = new Map<id,id>();
        for(ContentDocumentLink conDocLink : [  SELECT Id, LinkedEntityId, 
                                                    ContentDocumentId, ContentDocument.LatestPublishedVersionId 
                                                FROM ContentDocumentLink 
                                                WHERE LinkedEntityId =: docRecordId 
                                                ORDER BY ContentDocument.CreatedDate DESC 
                                                LIMIT 1]){
            documentToContentVersionId.put(conDocLink.LinkedEntityId,conDocLink.ContentDocument.LatestPublishedVersionId);
        }
        Map<Id, ContentVersion> contentVersionMap = new Map<Id,ContentVersion>(
                                                        [SELECT Id, FileType, Title, ContentDocumentId 
                                                         FROM ContentVersion 
                                                         WHERE Id IN: documentToContentVersionId.values() 
                                                         ORDER BY createddate DESC 
                                                         LIMIT 1]);
        if(contentVersionMap.isEmpty()){
            return null;
        }else{
            return contentVersionMap.values()[0];
        }
    }

    public static Map<String, List<Account>> getPrimaryAccountsMap(Map<Id, String> relatedAccIdToTypeMap) {
        Map<String, List<Account>> relationTypeToAccountsListMap = new Map<String, List<Account>>();
        if(!relatedAccIdToTypeMap.isEmpty()){
            for(Account acc: [  SELECT Id, isPersonAccount, 
                                    AccountNumber__c, ResidentStatus__pc, 
                                    Name, FirstName, LastName, PersonEmail, 
                                    (SELECT Id, Name, FirstName, LastName, Email 
                                    FROM Contacts 
                                    WHERE PrimaryContact__c = true) 
                                FROM Account 
                                WHERE Id IN: relatedAccIdToTypeMap.keySet()]){
                String relationType = relatedAccIdToTypeMap.get(acc.Id).toUpperCase();
                if(relationTypeToAccountsListMap.containsKey(relationType)){
                    relationTypeToAccountsListMap.get(relationType).add(acc);
                }else{
                    relationTypeToAccountsListMap.put(relationType, new List<Account>{acc});
                }
            }
        }
        return relationTypeToAccountsListMap;
    }

    public static Map<String, List<JointOwner__c>> getJointOwnersMap(Map<Id, String> relatedSObjectIdToTypeMap) {
        Map<String, List<JointOwner__c>> relationTypeToJointOwnersListMap = new Map<String, List<JointOwner__c>>();
        if(!relatedSObjectIdToTypeMap.isEmpty()){
            for(JointOwner__c jo: [ SELECT Id, Salutation__c, FirstName__c, MiddleName__c, LastName__c, Suffix__c,
                                        Email__c, MobileNumber__c, Phone__c, Country__c, 
                                        JointOwnerFullName__c, City__c, Nationality__c, Passport__c, 
                                        UAEID__c, SharePercentage__c,
                                        Account__c, Account__r.Name, Account__r.isPersonAccount, Account__r.ResidentStatus__pc, Account__r.AccountNumber__c,
                                        SalesOrder__c, Opportunity__c
                                    FROM JointOwner__c 
                                    WHERE Account__c IN: relatedSObjectIdToTypeMap.keySet()  
                                        OR SalesOrder__c IN: relatedSObjectIdToTypeMap.keySet()
                                        OR Opportunity__c IN: relatedSObjectIdToTypeMap.keySet()]){
                Id relationId = null;
                if(relatedSObjectIdToTypeMap.containsKey(jo.Account__c)){
                    relationId = jo.Account__c;
                }else if(relatedSObjectIdToTypeMap.containsKey(jo.Opportunity__c)){
                    relationId = jo.Opportunity__c;
                }else if(relatedSObjectIdToTypeMap.containsKey(jo.SalesOrder__c)){
                    relationId = jo.SalesOrder__c;
                }
                String relationType = relatedSObjectIdToTypeMap.get(relationId).toUpperCase();
                if(relationTypeToJointOwnersListMap.containsKey(relationId+'_'+relationType)){
                    relationTypeToJointOwnersListMap.get(relationId+'_'+relationType).add(jo);
                }else{
                    relationTypeToJointOwnersListMap.put(relationId+'_'+relationType, new List<JointOwner__c>{jo});
                }
            }
        }
        return relationTypeToJointOwnersListMap;
    }
}