@RestResource (urlMapping = '/customer/DocusignSPA')
global without sharing class DocusignSPAAPI {
	 @HttpPost
    global static void DocusignSPA() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
             Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();
            Map<String, Object> responseData = new Map<String, Object>(); 
           //  DocusignSPAData(mapFieldApiFieldValues);
            handler.response.success = true;
            handler.finalize();
        }catch(Exception ex){

            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
    }

    @AuraEnabled
    public static void SendforDigitalSignature(String recordId,String signType) {
        
        list<Document__c> documentRecord= new List<Document__c>(); 
        if(signType !='Parking'){
            documentRecord = [SELECT Id,Identityverification__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.Unit__r.Project__c,
        SalesOrder__r.Unit__r.Project__r.Name,DocumentType__c,SalesOrder__c,ExpressionofInterest__c,
        SalesOrder__r.Account__c,ExpressionofInterest__r.Account__c,Account__c,DocuSignedDateTime__c,
        Case__c, Case__r.SalesOrder__c, Case__r.AccountId, Case__r.RecordType.DeveloperName, 
        Opportunity__c, Opportunity__r.AccountId, Opportunity__r.RecordType.DeveloperName,Opportunity__r.Seller__c,
        Opportunity__r.SalesOrder__c,ProjectName__c,Document_Verified__c,
        SPAValidation__c FROM Document__c where id= :recordId AND SalesOrder__c != null limit 1];
        }else{
       documentRecord = [SELECT Id,Identityverification__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.Unit__r.Project__c,
        SalesOrder__r.Unit__r.Project__r.Name,DocumentType__c,SalesOrder__c,ExpressionofInterest__c,
        SalesOrder__r.Account__c,ExpressionofInterest__r.Account__c,Account__c,DocuSignedDateTime__c,
        Case__c, Case__r.SalesOrder__c, Case__r.AccountId, Case__r.RecordType.DeveloperName, 
        Opportunity__c, Opportunity__r.AccountId, Opportunity__r.RecordType.DeveloperName,Opportunity__r.Seller__c,
        Opportunity__r.SalesOrder__c,ProjectName__c,Document_Verified__c,
        SPAValidation__c FROM Document__c where id= :recordId AND Order__c != null limit 1];
        }
        
        update new List<Document__c>{ new Document__c(id=documentRecord[0].Id, Esignlocation__c='Signzy')};
        if(signType !='Parking'){
        update  new List<SalesOrder__c>{new SalesOrder__c(Id=documentRecord[0].SalesOrder__c,SubStatus__c = 'Digital SPA Submitted for sign off')};
        }
        List<Communication_Preference__c> cpList =[SELECT Id,Active__c FROM Communication_Preference__c WHERE Document__c =:recordId OR (Category__c ='Fasttrack' AND Account__c =:documentRecord[0].salesOrder__r.Account__c)];
        for(Communication_Preference__c cp :cpList){
            cp.Active__c = false;
        }
        update cpList;

        Communication_Preference__c cpp = new Communication_Preference__c();      
        cpp.Status__c = 'Link Sent';
        cpp.Active__c = true;
        cpp.Category__c =signType =='Parking'?'Premium Parking':'Digital SPA';
        cpp.Document__c =documentRecord[0].Id;
        if(signType !='Parking'){
        cpp.Sales_Order__c =documentRecord[0].SalesOrder__c;
        }
        insert cpp;

        Map<String,String> documentMap = new Map<String,String>();
        documentMap.put('documentId',documentRecord[0].Id);
            DocusignSPAData(documentRecord[0].Id,cpp.Id,signType);
   
        
    }
    @future(callout=true)
    public static void DocusignSPAData(String docRecordId,String CpId,String signType){//Map<String,String> mapFieldApiFieldValues
        //String relatedAccountId =mapFieldApiFieldValues.get('AccountId');
        //String relatedsObjectId =mapFieldApiFieldValues.get('SalesOrderId');
        //String docRecordId  = mapFieldApiFieldValues.get('documentId');
        //String docType = mapFieldApiFieldValues.get('docType');
        Organization org = Utilities.getOrganizationDetails();
        APISetting__mdt docuSignAuthentication = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_AUTHENTICATION);
        String pvtKey = Utilities.getConstant(CustomerAPIConstants.DOCUSIGN_PRIVATE_KEY).ConstantValueLong__c;
        String jwtToken = !Test.isRunningTest() ? JWTToken.issueToken(docuSignAuthentication, org.IsSandbox, pvtKey) : 'mock-jwt-token';
        String authToken = DocusignForMOUListing.callAPI(docuSignAuthentication, '', '', org.IsSandbox, 'Authentication', JSON.serialize(new DocuSignAPIWrapper.AuthenticationRequestModel(CustomerAPIConstants.GRANT_TYPE, jwtToken)));
       	//String UAEPASSSIGNROLE = Label.DOCUSIGN_UAEPASSSIGNROLE;
        //String IDNOWSIGNROLE = Label.DOCUSIGN_IDNOWSIGNROLE;
        String ALDARAPPROVERROLE = Label.DOCUSIGN_ALDARAPPROVERROLE;
        String ALDARUAEPASSROLE = Label.DOCUSIGN_ALDARUAEPASSROLE;
        //Integer idNowSequence = Integer.valueOf(Label.DOCUSIGN_idNowSequence) ;
        //Integer uaePassSequence =  Integer.valueOf(Label.DOCUSIGN_uaePassSequence) ;
        //Integer aldarApproverSequence =  Integer.valueOf(Label.DOCUSIGN_aldarApproverSequence) ;
   		//Integer aldarSignSequence =  Integer.valueOf(Label.DOCUSIGN_aldarSignSequence) ;
        
        
        
        list<Document__c> documentRecord =new List<Document__c>();
        if(signType =='Parking'){
            documentRecord = [SELECT Id,Identityverification__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.Unit__r.Project__c,
            SalesOrder__r.Unit__r.Project__r.Name,DocumentType__c,SalesOrder__c,ExpressionofInterest__c,
            SalesOrder__r.Account__c,ExpressionofInterest__r.Account__c,Account__c,DocuSignedDateTime__c,
            Case__c, Case__r.SalesOrder__c, Case__r.AccountId, Case__r.RecordType.DeveloperName, 
            Opportunity__c, Opportunity__r.AccountId, Opportunity__r.RecordType.DeveloperName,Opportunity__r.Seller__c,
            Opportunity__r.SalesOrder__c,ProjectName__c,Document_Verified__c,Order__r.Sales_Order__r.Account__c,Order__c,Order__r.Sales_Order__r.UnitNumber__c,
            SPAValidation__c FROM Document__c where id= :docRecordId AND Order__c != null limit 1];
        } else{
            documentRecord = [SELECT Id,Identityverification__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.Unit__r.Project__c,
        SalesOrder__r.Unit__r.Project__r.Name,DocumentType__c,SalesOrder__c,ExpressionofInterest__c,
        SalesOrder__r.Account__c,ExpressionofInterest__r.Account__c,Account__c,DocuSignedDateTime__c,
        Case__c, Case__r.SalesOrder__c, Case__r.AccountId, Case__r.RecordType.DeveloperName, 
        Opportunity__c, Opportunity__r.AccountId, Opportunity__r.RecordType.DeveloperName,Opportunity__r.Seller__c,
        Opportunity__r.SalesOrder__c,ProjectName__c,Document_Verified__c,
        SPAValidation__c FROM Document__c where id= :docRecordId AND SalesOrder__c != null limit 1];
        }
                                            
                                            createRecipientList(documentRecord,org,authToken,CpId,signType);
       
    }
    public static void createRecipientList(List<Document__c> documentRecord,Organization org,String authToken,String CpId,String signType ){
        String relatedAccountId ='';
        String relatedsObjectId ='';
        String docType ='';
        String signedDoc ='';
        Document__c relatedSignDocument  = new Document__c();
        List<JointOwner__c> jointOwnerList = new List<JointOwner__c>();
        if(signType != 'Parking'){
         relatedAccountId =documentRecord[0].SalesOrder__r.Account__c;
         relatedsObjectId  = documentRecord[0].SalesOrder__c;
         docType = documentRecord[0].DocumentType__c;
		// signedDoc = 'Signed ' +docType;
         signedDoc = 'Aldar Signed SPA';
        
         relatedSignDocument = [SELECT
                                   Id
                                   FROM Document__c 
                                   WHERE SalesOrder__c =:documentRecord[0].SalesOrder__c
                                   AND DocumentType__c =:signedDoc LIMIT 1 ];
        
        
        jointOwnerList = [SELECT Id,Account__c,Account__r.Name,Account__r.isPersonAccount,Account__r.ResidentStatus__pc,
                              FirstName__c,MiddleName__c,LastName__c,JointOwnerFullName__c,City__c,Salutation__c,
                              Nationality__c,Passport__c,Email__c,MobileNumber__c,Phone__c,Country__c,Suffix__c,
                              UAEID__c,SharePercentage__c  ,Account__r.AccountNumber__c
                              FROM JointOwner__c WHERE  SalesOrder__c = :relatedsObjectId ];
        }

        if(signType =='Parking'){
            signedDoc ='Signed '+documentRecord[0].DocumentType__c;
            relatedAccountId = documentRecord[0].Order__r.Sales_Order__r.Account__c;
            relatedsObjectId = documentRecord[0].Order__c;
            relatedSignDocument = [SELECT
                                   Id
                                   FROM Document__c 
                                   WHERE Order__c =:documentRecord[0].Order__c
                                   AND DocumentType__c =:signedDoc LIMIT 1 ];
            jointOwnerList = [SELECT Id,Account__c,Account__r.Name,Account__r.isPersonAccount,Account__r.ResidentStatus__pc,
                    FirstName__c,MiddleName__c,LastName__c,JointOwnerFullName__c,City__c,Salutation__c,
                    Nationality__c,Passport__c,Email__c,MobileNumber__c,Phone__c,Country__c,Suffix__c,
                    UAEID__c,SharePercentage__c  ,Account__r.AccountNumber__c
                    FROM JointOwner__c WHERE  SalesOrder__c = :relatedsObjectId ];
        }
        ContentVersion Contentversion = CustomerServiceUtility.getContentVersion(documentRecord[0].Id);
        
        Account relatedAccount = [select id,Name,isPersonAccount,AccountNumber__c,ResidentStatus__pc, FirstName,LastName, PersonEmail,(select id,FirstName,LastName, Email from Contacts where PrimaryContact__c =true) from account where id = :relatedAccountId limit 1];
       
        
        String primaryRecipientRole = '';
        /*Integer routingOrder;
        if(relatedAccount.ResidentStatus__pc != null && relatedAccount.ResidentStatus__pc == 'Resident'){
            primaryRecipientRole += UAEPASSSIGNROLE + '1';
            //uaePassSequence = uaePassSequence + 1;

            routingOrder = uaePassSequence;
        }else{
            primaryRecipientRole += IDNOWSIGNROLE + '1';
           // idNowSequence = idNowSequence + 1; 

            routingOrder = idNowSequence;
        }*/
        String recipientName = relatedAccount.isPersonAccount ? (relatedAccount.FirstName + ' '+ relatedAccount.LastName) : (relatedAccount.Contacts[0].FirstName + ' '+ relatedAccount.Contacts[0].LastName); // Recipient name
            if(org.IsSandbox && relatedAccount.ResidentStatus__pc != null && relatedAccount.ResidentStatus__pc == 'Non-Resident'){
                recipientName += ' X-MANUALTEST-HAPPYPATH';
            }
        
       APISetting__mdt docuSignEnvelope = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_ENVELOPE);
       DocuSignAPIWrapper.KeyValueModel keyValueModel = (DocuSignAPIWrapper.KeyValueModel)JSON.deserializeStrict(docuSignEnvelope.Headers__c, DocuSignAPIWrapper.KeyValueModel.class);
        String signProvider = '';//(relatedAccount.ResidentStatus__pc != null && relatedAccount.ResidentStatus__pc == 'Resident') ? keyValueModel.uaepass : keyValueModel.idnow;
        
        List<DocuSignAPIWrapper.DocumentModel> documentModel = new List<DocuSignAPIWrapper.DocumentModel>();
        System.debug('Chi'+Contentversion);
        documentModel.add(new DocuSignAPIWrapper.DocumentModel(Contentversion));
        
        DocuSignAPIWrapper.EnvelopeRequestModel envelopeRequestModel = new DocuSignAPIWrapper.EnvelopeRequestModel();
        String emailBody = '';
        if(signType =='Parking'){
            envelopeRequestModel.emailSubject =  Label.DOCUSIGN_EmailSubject_Parking +' '+documentRecord[0].Order__r.Sales_Order__r.UnitNumber__c;
            emailBody += Label.DOCUSIGN_EmailBody_Parking;
            emailBody += '<a href="';
            emailBody += '" target="_blank"> click here</a>';
            emailBody += Label.DOCUSIGN_EmailBody2_Parking;   
            emailBody += Label.DOCUSIGN_EmailBody3_Parking;
        }else{
        	envelopeRequestModel.emailSubject =  Label.DOCUSIGN_EmailSubject +' '+documentRecord[0].SalesOrder__r.UnitNumber__c;
            emailBody += Label.DOCUSIGN_EmailBody;
            emailBody += '<a href="';
            emailBody += '" target="_blank"> click here</a>';
            emailBody += Label.DOCUSIGN_EmailBody2;   
            emailBody += Label.DOCUSIGN_EmailBody3;
        }
       
        envelopeRequestModel.emailBlurb = emailBody;
        //envelopeRequestModel.emailSubject = CustomerAPIConstants.DOCUSIGN_EMAIL_SUBJECT;
        envelopeRequestModel.documents = documentModel;
        DocuSignAPIWrapper.notifications ntf= new DocuSignAPIWrapper.notifications();
        ntf.useAccountDefaults = true;
        envelopeRequestModel.notification = ntf;

        List<DocuSignAPIWrapper.SignerModel> signers = new List<DocuSignAPIWrapper.SignerModel>();
        DocuSignAPIWrapper.RecipientModel recipientModel = new DocuSignAPIWrapper.RecipientModel();
        
        String recipientEmail = relatedAccount.isPersonAccount ? (relatedAccount.PersonEmail ) : (relatedAccount.Contacts[0].Email ); // Recipient email
        String primarySignHolder = relatedAccount.isPersonAccount ? relatedAccount.AccountNumber__c+'SignatureHolder' : relatedAccount.AccountNumber__c+'OrgSignatureHolder'; 
        String primaryDateHolder = relatedAccount.isPersonAccount ? relatedAccount.AccountNumber__c+'DateHolder' : relatedAccount.AccountNumber__c+'OrgDateHolder'; 
        String primaryInitialHolder = relatedAccount.isPersonAccount ? relatedAccount.AccountNumber__c+'InitialsHolder' : relatedAccount.AccountNumber__c+'OrgInitialsHolder'; 
        String primaryNameHolder = relatedAccount.isPersonAccount ? relatedAccount.AccountNumber__c+'NameHolder' : relatedAccount.AccountNumber__c+'OrgNameHolder'; 
        String anchorString1 = relatedAccount.Id + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER;
        signers.add(new DocuSignAPIWrapper.SignerModel(relatedAccount.Id,recipientEmail,relatedAccount.Name, primarySignHolder, signProvider,'1','1','Signer','',primaryNameHolder,primaryDateHolder,''));
        List<Account> JointOwners = new List<Account>();
        String jointOwnerAcocuntIdString='';
        for(JointOwner__c jj :jointOwnerList)  {
            jointOwnerAcocuntIdString =  jointOwnerAcocuntIdString != null ? (jointOwnerAcocuntIdString + '\''+jj.Account__c+'\',') : '\''+jj.Account__c+'\','; 
        }  
         
            if(jointOwnerAcocuntIdString != null && jointOwnerAcocuntIdString!='' ){
                if(jointOwnerAcocuntIdString.endsWith(',')){
                    jointOwnerAcocuntIdString = jointOwnerAcocuntIdString.removeEnd(',');
                }
                JointOwners.addAll(CustomerServiceUtility.getAccountDetail(' (Id in (' + jointOwnerAcocuntIdString + ')  )'));
            }
        
   
         Integer signCount = 1;
        for(Account jo : JointOwners){
            // Add Recipient Salesorder's Account or Account's Primary Contact (must be present)
            /*String joRole = '';
            Integer routingOrder2;
            if(jo.ResidentStatus__pc != null && jo.ResidentStatus__pc == 'Resident'){
                joRole += UAEPASSSIGNROLE + String.valueOf(signCount);

                uaePassSequence = uaePassSequence + 1;

                routingOrder2 = uaePassSequence;
            }else{
                joRole += IDNOWSIGNROLE + String.valueOf(signCount);

                idNowSequence = idNowSequence +  1;

                routingOrder2 = idNowSequence;
            }*/
            recipientName = jo.Name;
           // recipientName  = (jo.FirstName__c == null ? '' : jo.FirstName__c )  + ' ' + (jo.MiddleName__c == null ? '': jo.MiddleName__c + ' ') + jo.LastName__c == null ? '':jo.LastName__c  ;// Recipient name
            if(org.IsSandbox && jo.ResidentStatus__pc != null && jo.ResidentStatus__pc == 'Non-Resident'){
                recipientName += ' X-MANUALTEST-HAPPYPATH';
            }
            recipientEmail =jo.isPersonAccount ? (jo.PersonEmail ) : (jo.Contacts[0].Email ); 
            String joSignHolder = jo.isPersonAccount ? jo.AccountNumber__c+'SignatureHolder' : jo.AccountNumber__c+'OrgSignatureHolder'; 
            String joDateHolder = jo.isPersonAccount ? jo.AccountNumber__c+'DateHolder' : jo.AccountNumber__c+'OrgDateHolder'; 
            String joInitialHolder = jo.isPersonAccount ? jo.AccountNumber__c+'InitialsHolder' : jo.AccountNumber__c+'OrgInitialsHolder'; 
            String joNameHolder = jo.isPersonAccount ? jo.AccountNumber__c+'NameHolder' : jo.AccountNumber__c+'OrgNameHolder'; 
            String anchorString = jo.Id + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER;
            String signProvider1 = '';//(jo.ResidentStatus__pc != null && jo.ResidentStatus__pc == 'Resident') ? keyValueModel.uaepass : keyValueModel.idnow;
			signers.add(new DocuSignAPIWrapper.SignerModel(jo.Id,recipientEmail,jo.Name, joSignHolder, signProvider1,String.valueOf(signCount+1),String.valueOf(signCount+1),'Signer','',joNameHolder,joDateHolder,''));
            
            signCount++;
        }
		signCount = 20;
       List<Aldarsignatory__mdt> aldarSign = [Select Id,email__c,Order__c,Type__c ,MasterLabel,DeveloperName,SigninggroupId__c,Signinggroupname__c FROM Aldarsignatory__mdt where active__c = true ORDER BY Order__c ];
        //ALDAR SIGN
        for(Aldarsignatory__mdt aSign : aldarSign){
            //String signProvider1 = (jo.ResidentStatus__pc != null && jo.ResidentStatus__pc == 'Resident') ? keyValueModel.uaepass : keyValueModel.idnow;
            recipientName = aSign.MasterLabel;
            //Approver Signatory
            if(aSign.Type__c == 'Approver'){
                signers.add(new DocuSignAPIWrapper.SignerModel(null,aSign.email__c,aSign.DeveloperName,'Simple','',String.valueOf(signCount+1),String.valueOf(signCount+1),'Approver','SIGN_AT_DOCUSIGN','','',''));
            }else if(aSign.Type__c == 'Signatory'){
                recipientEmail = aSign.email__c ;
                signers.add(new DocuSignAPIWrapper.SignerModel(null,recipientEmail,aSign.DeveloperName,'AldarSignatureHolder','',String.valueOf(signCount+1),String.valueOf(signCount+1),'Signer','SIGN_AT_DOCUSIGN','AldarNameHolder','AldarDateHolder','Stamp'));
            }
            //keyValueModel.idnow
            String joRole = 'AldarUAEPassSign';
            signCount++;

        }


         recipientModel.signers = signers;

        envelopeRequestModel.recipients = recipientModel;
        System.debug('Chirag'+envelopeRequestModel);
            envelopeRequestModel.status = CustomerAPIConstants.DOCUSIGN_STATUS_SENT;
			String envelopeId;
            envelopeId = DocusignForMOUListing.callAPI(docuSignEnvelope, authToken, '', org.IsSandbox, 'Envelope', JSON.serialize(envelopeRequestModel));

            if(envelopeId != null && envelopeId != ''){
                update new List<Document__c>{ new Document__c(id=relatedSignDocument.Id, DocuSignEnvelopeID__c=envelopeId)};
                    
                dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c();
                envelopeStatus.dfsle__DocuSignId__c   = envelopeId;
                envelopeStatus.dfsle__SenderName__c   = UserInfo.getUserName(); // Need to know where it is configured
                envelopeStatus.dfsle__SenderEmail__c  = UserInfo.getUserEmail(); // Need to know where it is configured
                envelopeStatus.dfsle__EmailSubject__c = Label.DOCUSIGN_EmailSubject +' '+documentRecord[0].SalesOrder__r.UnitNumber__c;
                envelopeStatus.dfsle__Status__c       = CustomerAPIConstants.DOCUSIGN_STATUS_SENT;
                envelopeStatus.dfsle__Sent__c         = system.now();
                envelopeStatus.CreatedFromAPI__c      = true;
                envelopeStatus.dfsle__SourceId__c = documentRecord[0].Id;
                envelopeStatus.Communication_Preference__c = CpId;
                envelopeStatus.Document__c = documentRecord[0].Id;
                insert envelopeStatus;
                List<dfsle__RecipientStatus__c> recipientStatusList = new List<dfsle__RecipientStatus__c>();
                List<Communication_Preference__c> cpList = new List<Communication_Preference__c>();
                for(DocuSignAPIWrapper.SignerModel signer: signers){
                    if(signer.AccountId != null){
                        Communication_Preference__c cp = new Communication_Preference__c();
                        if(signer.routingOrder == '1'){
                            cp.Status__c = 'Link Sent';
                        }else{
                            cp.Status__c = 'Pending Signature';
                        }
                        cp.Active__c = true;
                        cp.Category__c =signType =='Parking'?'Premium Parking':'Digital SPA';
                        cp.Document__c =documentRecord[0].Id;
                        if(signType !='Parking'){
                        cp.Sales_Order__c =documentRecord[0].SalesOrder__c;
                        }
                        cp.Account__c = signer.AccountId;
                        cp.Parent_CP__c = CpId;
                        cpList.add(cp);
                    }
                }
                insert cpList;
                List<Communication_Preference__c> compLIst = new List<Communication_Preference__c>();
                for(Communication_Preference__c  comp :[SELECT Id,Name,Active__c FROM Communication_Preference__c WHERE Account__c=:JointOwners AND Active__c = true AND Category__c ='Fasttrack']){
                    comp.Active__c =false;
                    compLIst.add(comp);
                }
                update compLIst;
                Map<Id,Id>CpMap = new Map<Id,Id>();
                Map<Id,Id>CpContactMap = new Map<Id,Id>();
                for(Communication_Preference__c cp1 :[SELECT Id,Name,Account__c,Contact__c FROM Communication_Preference__c WHERE Id =:cpList ]){
                    CpMap.put(cp1.Account__c,cp1.Id);
                    CpContactMap.put(cp1.Id,cp1.Contact__c);
                }

                
                for(DocuSignAPIWrapper.SignerModel signer: signers){

                    dfsle__RecipientStatus__c recipientStatus = new dfsle__RecipientStatus__c();
                    recipientStatus.dfsle__EnvelopeStatus__c = envelopeStatus.Id;
                    recipientStatus.dfsle__Email__c = signer.email;
                    recipientStatus.dfsle__RoutingOrder__c = Decimal.valueOf(signer.routingOrder);
                    recipientStatus.dfsle__SourceId__c = documentRecord[0].Id;
                    recipientStatus.dfsle__Type__c = signer.signerType;
                    if(signer.routingOrder == '1'){
                    recipientStatus.dfsle__Status__c = 'Sent';
                    }else{
                        recipientStatus.dfsle__Status__c = 'created';
                    }
                    recipientStatus.Name = signer.Name;
                    recipientStatus.Account__c = signer.AccountId;
                    recipientStatus.CommunicationPreference__c =signer.AccountId != null && CpMap.get(signer.AccountId) != null ?CpMap.get(signer.AccountId):null;
                    recipientStatus.Contact__c =  recipientStatus.CommunicationPreference__c != null? CpContactMap.get(recipientStatus.CommunicationPreference__c):null;
                    recipientStatus.dfsle__Sent__c = System.now();
                    recipientStatusList.add(recipientStatus);
                }
                if(!recipientStatusList.isEmpty()){
                    insert recipientStatusList;
                }
            }
        
    }
    public static String getDocusignURL(String docRecordId,String customerId,String returnURL){
        list<Document__c> documentRecord = [SELECT Id,Identityverification__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.Unit__r.Project__c,
                                            SalesOrder__r.Unit__r.Project__r.Name,DocumentType__c,SalesOrder__c,ExpressionofInterest__c,
                                            SalesOrder__r.Account__c,ExpressionofInterest__r.Account__c,Account__c,DocuSignedDateTime__c,
                                            Case__c, Case__r.SalesOrder__c, Case__r.AccountId, Case__r.RecordType.DeveloperName, 
                                            Opportunity__c, Opportunity__r.AccountId, Opportunity__r.RecordType.DeveloperName,Opportunity__r.Seller__c,
                                            Opportunity__r.SalesOrder__c,ProjectName__c,Document_Verified__c,
                                            SPAValidation__c FROM Document__c where id= :docRecordId  limit 1];
                                            String signedDoc = documentRecord[0].DocumentType__c.containsIgnoreCase('spa')?'Aldar Signed SPA': 'Signed '+documentRecord[0].DocumentType__c;
                                            Account account = CustomerServiceUtility.getAccountDetail(' (Id = \'' + customerId + '\') ')[0];
        
        Document__c relatedSignDocument = [SELECT  Id,DocuSignEnvelopeID__c FROM Document__c 
                                                            WHERE SalesOrder__c =:documentRecord[0].SalesOrder__c
                                                            AND DocumentType__c =:signedDoc LIMIT 1 ];
        String docuSignDocumentURL = '';
        
        //String docType = mapFieldApiFieldValues.get('docType');
        Organization org = Utilities.getOrganizationDetails();
        APISetting__mdt docuSignAuthentication = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_AUTHENTICATION);
        String pvtKey = Utilities.getConstant(CustomerAPIConstants.DOCUSIGN_PRIVATE_KEY).ConstantValueLong__c;
        String jwtToken = !Test.isRunningTest() ? JWTToken.issueToken(docuSignAuthentication, org.IsSandbox, pvtKey) : 'mock-jwt-token';
        String authToken = DocusignForMOUListing.callAPI(docuSignAuthentication, '', '', org.IsSandbox, 'Authentication', JSON.serialize(new DocuSignAPIWrapper.AuthenticationRequestModel(CustomerAPIConstants.GRANT_TYPE, jwtToken)));
        APISetting__mdt docuSignURL = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_URL);
        docuSignDocumentURL = DocusignForMOUListing.callAPI(docuSignURL, authToken, relatedSignDocument.DocuSignEnvelopeID__c, org.isSandbox, 'DosuSignURL', JSON.serialize(new DocuSignAPIWrapper.URLRequestModel(returnURL, account)));
        return docuSignDocumentURL;
    }
       
}