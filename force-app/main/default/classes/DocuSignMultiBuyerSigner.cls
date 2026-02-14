public with sharing class DocuSignMultiBuyerSigner {
    
    
    public static String handleNOCDocuments(String customerId, String documentId, String returnURL,String authToken,Organization org){
        
        String docuSignDocumentURL;
        HexaBPM__SR_Doc__c srDocforEsign = [SELECT Id, Name, HexaBPM__Service_Request__c,SRTemplateName__c,UnitName__c FROM HexaBPM__SR_Doc__c WHERE Id =: documentId LIMIT 1];
        ContentVersion cv = CustomerServiceUtility.getContentVersion(documentId);
        
        
        if(srDocforEsign != null && cv.Id != null){
            docuSignDocumentURL = getDocusignURL(customerId,documentId,returnURL,authToken,org);
        }else{
            docuSignDocumentURL =CustomerAPIConstants.MESSAGE_DOCUMENT_NOT_FOUND;
        }
        return docuSignDocumentURL;
        
    }
    
    public static string  getDocusignURL(String customerId, String documentId, String returnURL,String authToke,Organization org){
        HexaBPM__SR_Doc__c srDocForEsign =[SELECT Id, Name,HexaBPM__Status__c,HexaBPM__Document_Name__c, DocumentMasterCode__c, HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.HexaBPM__Customer__c, HexaBPM__Service_Request__r.SalesOrder__c, HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name, createdDate ,HexaBPM__Comments__c,Provis_Reason__c FROM HexaBPM__SR_Doc__c where id=:documentId LIMIT 1];
        HexaBPM__Service_Request__c sr= srDocForEsign.HexaBPM__Service_Request__r;
        string docNameToUpdate;
        
        Account account = CustomerServiceUtility.getAccountDetail(' (Id = \'' + customerId + '\') ')[0];
        ContentVersion cv = CustomerServiceUtility.getContentVersion(documentId);
        
        if (srDocforEsign.Name == 'Owner Association Letter') {
            docNameToUpdate = 'Signed Owner Association Letter';
        } else if (srDocforEsign.Name == 'Document of Adherence') {
            docNameToUpdate = 'Signed Document of Adherence';
        }
        list<HexaBPM__SR_Doc__c> SignedSrDoc =[SELECT Id, Name,Docusign_Envelope_Id__c,HexaBPM__Document_Name__c FROM HexaBPM__SR_Doc__c where Name=:docNameToUpdate AND HexaBPM__Service_Request__c=: sr.Id  LIMIT 1];
        
        
        String authToken = authToke;//CustomerGetDocuSignURLWebService.callAPI(docuSignAuthentication, '', '', org.IsSandbox, 'Authentication', JSON.serialize(new CustomerGetDocuSignURLWebService.AuthenticationRequestModel(CustomerAPIConstants.GRANT_TYPE, jwtToken)));
        System.debug('authToken>>>' + authToken);
        
        //finding Joint owner Account Ids 
        Set<Id> accountIds = new Set<Id>();
        List<HexaBPM__Service_Request__c> existingSR = [ SELECT Id,  Case__c,BuyerName__c,  (SELECT Id, Account__c FROM Partners__r)  FROM HexaBPM__Service_Request__c   WHERE   SRType__c = 'Property Transfer NOC'  AND Id=:sr.Id];
        accountIds.add(account.Id);
        set<Account> joointOwnersList = new set<Account>();
        if (!existingSR.isEmpty()) {
            HexaBPM__Service_Request__c serviceRequest = existingSR[0];
            if (serviceRequest.Partners__r != null) {
                for (AgencyTeam__c partner : serviceRequest.Partners__r) {
                    if (partner.Account__c != null) {    
                        accountIds.add(partner.Account__c);
                    }
                }
            }
            if(serviceRequest.BuyerName__c != null){
                accountIds.add(serviceRequest.BuyerName__c);
            }
        }
        Map<Id, Account> accountMap = new Map<Id, Account>();
        if (!accountIds.isEmpty()) {
            accountMap = new Map<Id, Account>([SELECT Id, Name, isPersonAccount, PersonEmail, AccountNumber__c FROM Account WHERE Id IN :accountIds]);
        }
        
        for (Id accountId : accountIds) {
            if (accountMap.containsKey(accountId)) {
                Account relatedJOAccount = accountMap.get(accountId);
                joointOwnersList.add(relatedJOAccount);
                system.debug('JointAccountList::'+joointOwnersList);
            }
        }
        
        //envelope creation
        APISetting__mdt docuSignEnvelope = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_ENVELOPE);
        DocuSignAPIWrapper.KeyValueModel keyValueModel = (DocuSignAPIWrapper.KeyValueModel)JSON.deserializeStrict(docuSignEnvelope.Headers__c, DocuSignAPIWrapper.KeyValueModel.class);
        String signProvider = '';
        List<DocuSignAPIWrapper.DocumentModel> documentModel = new List<DocuSignAPIWrapper.DocumentModel>();
        
        documentModel.add(new DocuSignAPIWrapper.DocumentModel(cv));
        
        DocuSignAPIWrapper.EnvelopeRequestModel envelopeRequestModel = new DocuSignAPIWrapper.EnvelopeRequestModel();
        envelopeRequestModel.documents = documentModel;
        
        List<DocuSignAPIWrapper.SignerModel> signers = new List<DocuSignAPIWrapper.SignerModel>();
        DocuSignAPIWrapper.RecipientModel recipientModel = new DocuSignAPIWrapper.RecipientModel();
        Integer RoutingOrder =1;
        Integer recepientId =1;
        for(Account relatedAccount: joointOwnersList){
            
            system.debug('RelatedAccount'+relatedAccount);
            String recipientEmail = relatedAccount.isPersonAccount ? (relatedAccount.PersonEmail ) : (relatedAccount.Contacts[0].Email ); // Recipient email
                String primarySignHolder = relatedAccount.isPersonAccount ? relatedAccount.AccountNumber__c+'SignatureHolder' : relatedAccount.AccountNumber__c+'OrgSignatureHolder'; 
            String primaryDateHolder = relatedAccount.isPersonAccount ? relatedAccount.AccountNumber__c+'DateHolder' : relatedAccount.AccountNumber__c+'OrgDateHolder'; 
            String primaryInitialHolder = relatedAccount.isPersonAccount ? relatedAccount.AccountNumber__c+'InitialsHolder' : relatedAccount.AccountNumber__c+'OrgInitialsHolder'; 
            String primaryNameHolder = relatedAccount.isPersonAccount ? relatedAccount.Id+'NameHolder' : relatedAccount.Id+'OrgNameHolder'; 
            String anchorString1 = relatedAccount.Id + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER;
            signers.add(new DocuSignAPIWrapper.SignerModel(relatedAccount.Id,recipientEmail,relatedAccount.Name, anchorString1, signProvider,String.valueOf(recepientId),String.valueOf(RoutingOrder),'Signer','',primaryNameHolder,primaryDateHolder,''));
            system.debug('signers::'+signers);
            recepientId++;
        }
        system.debug('signerRoutingmodel::'+routingOrder);
        recipientModel.signers = signers;
        envelopeRequestModel.recipients = recipientModel;
        envelopeRequestModel.emailSubject ='Docusign';
        envelopeRequestModel.status = CustomerAPIConstants.DOCUSIGN_STATUS_SENT;
        System.debug('RecipientModel::'+recipientModel);
        
        System.debug('EnveloperRequestModel::'+envelopeRequestModel);
        
        String envelopeId;
        
        If(!SignedSrDoc.isEmpty()){
            if( String.isBlank(SignedSrDoc[0].Docusign_Envelope_Id__c)){
                envelopeId = DocusignForMOUListing.callAPI(docuSignEnvelope, authToken, '', org.IsSandbox, 'Envelope', JSON.serialize(envelopeRequestModel));       
            }else
                envelopeId = SignedSrDoc[0].Docusign_Envelope_Id__c;
        }
        String docuSignDocumentURL;
        
        APISetting__mdt docuSignURL = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_URL);
        docuSignDocumentURL = CustomerGetDocuSignURLWebService.callAPI(docuSignURL, authToken, envelopeId, org.IsSandbox, 'DosuSignURL', JSON.serialize(new DocuSignAPIWrapper.URLRequestModel(returnURL, account)));
        list<HexaBPM__SR_Doc__c> srrelated = [SELECT Id, Name,Docusign_Envelope_Id__c FROM HexaBPM__SR_Doc__c WHERE ((HexaBPM__Service_Request__c =:sr.Id) AND (Name =: docNameToUpdate ) )];
        
        if( String.isBlank(srrelated[0].Docusign_Envelope_Id__c) ){
            srrelated[0].Docusign_Envelope_Id__c = envelopeId;
            update srrelated;
        }
        system.debug('envelopeId::'+envelopeId);
        
        List<dfsle__EnvelopeStatus__c> existingEnvelopes = [SELECT Id FROM dfsle__EnvelopeStatus__c WHERE SR_Doc__c = :srDocForEsign.Id LIMIT 1 ];
        
        if( existingEnvelopes.isEmpty() ){
            dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c();
            envelopeStatus.dfsle__DocuSignId__c   = envelopeId;
            envelopeStatus.dfsle__SenderName__c   = UserInfo.getUserName(); // Need to know where it is configured
            envelopeStatus.dfsle__SenderEmail__c  = UserInfo.getUserEmail(); // Need to know where it is configured
            envelopeStatus.dfsle__EmailSubject__c = Label.DOCUSIGN_EmailSubject +' '+srDocForEsign.Name;
            envelopeStatus.dfsle__Status__c       = CustomerAPIConstants.DOCUSIGN_STATUS_SENT;
            envelopeStatus.dfsle__Sent__c         = system.now();
            envelopeStatus.CreatedFromAPI__c      = true;
            envelopeStatus.dfsle__SourceId__c = srDocForEsign.Id;
            //envelopeStatus.Document__c = srDocForEsign.Id;
            envelopeStatus.SR_Doc__c =srDocForEsign.Id;
            if(!Test.isRunningTest()){
                insert envelopeStatus;
            }
            
            
            List<dfsle__RecipientStatus__c> recipientStatusList = new List<dfsle__RecipientStatus__c>();
            for(DocuSignAPIWrapper.SignerModel signer: signers){
                
                dfsle__RecipientStatus__c recipientStatus = new dfsle__RecipientStatus__c();
                recipientStatus.dfsle__EnvelopeStatus__c = envelopeStatus.Id;
                recipientStatus.dfsle__Email__c = signer.email;
                recipientStatus.dfsle__RoutingOrder__c = Decimal.valueOf(signer.routingOrder);
                recipientStatus.dfsle__SourceId__c = srDocForEsign.Id;
                recipientStatus.dfsle__Type__c = signer.signerType;
                //if(signer.routingOrder == '1'){
                    recipientStatus.dfsle__Status__c = 'Sent';
                /*}else{
                    recipientStatus.dfsle__Status__c = 'created';
                }*/
                recipientStatus.Name = signer.Name;
                recipientStatus.Account__c = signer.AccountId;
                recipientStatus.dfsle__Sent__c = System.now();
                
                recipientStatusList.add(recipientStatus);
            }
            if(!recipientStatusList.isEmpty()  ){
                if(!Test.isRunningTest()){
                    insert recipientStatusList;
                }
                system.debug('recipientStatusList::'+recipientStatusList);
                
            }
            system.debug('envelopeStatus::'+envelopeStatus);
            
        }
        return docuSignDocumentURL;              
    }   
    
}