public class DocusignForMOUListing {

    public static String sendForESignResale(Id docRecordId, Id relatedSignDocumentId){
        system.debug('docRecordId::'+docRecordId);
        String docuSignDocumentURL = '';
        String returnURL = 'http://localhost';
        String envelopeId = '';
        List<Document__C> relatedSignDocument = new List<Document__C>(); 
        DocuSignMapper.RecipientTypeSequence = new List<String>{'BUYER', 'SELLER'};
        Organization org = Utilities.getOrganizationDetails();
        APISetting__mdt docuSignAuthentication = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_AUTHENTICATION);
        String pvtKey = Utilities.getConstant(CustomerAPIConstants.DOCUSIGN_PRIVATE_KEY).ConstantValueLong__c;
        String jwtToken = JWTToken.issueToken(docuSignAuthentication, org.IsSandbox, pvtKey);
        String authToken = callAPI(docuSignAuthentication, '', '', org.IsSandbox, 'Authentication', JSON.serialize(new AuthenticationRequestModel(CustomerAPIConstants.GRANT_TYPE, jwtToken)));
        
        String likedSignedString = 'Listing MOU';
        list<Document__c> documentRecord = [SELECT Id,Identityverification__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.Unit__r.Project__c,
                                            SalesOrder__r.Unit__r.Project__r.Name,DocumentType__c,SalesOrder__c,ExpressionofInterest__c,
                                            SalesOrder__r.Account__c,ExpressionofInterest__r.Account__c,Account__c,DocuSignedDateTime__c,
                                            Case__c, Case__r.SalesOrder__c, Case__r.AccountId, Case__r.RecordType.DeveloperName, 
                                            Opportunity__c, Opportunity__r.AccountId, Opportunity__r.RecordType.DeveloperName,Opportunity__r.Seller__c,
                                            Opportunity__r.SalesOrder__c,ProjectName__c,Document_Verified__c FROM Document__c where id= :docRecordId  limit 1];

        if(documentRecord[0].Opportunity__c != null && documentRecord[0].Opportunity__r.RecordType.DeveloperName.equalsIgnoreCase('Resale')){
            relatedSignDocument = [SELECT
                                   Id
                                   FROM Document__c 
                                   WHERE Opportunity__c =:documentRecord[0].Opportunity__c 
                                   AND DocumentType__c =: likedSignedString];
            
        }
        ContentVersion Contentversion = CustomerServiceUtility.getContentVersion(docRecordId);
        if(Contentversion != null){
            Account BuyerAccount  = CustomerServiceUtility.getAccountDetail(' (Id = \'' + documentRecord[0].Opportunity__r.AccountId + '\') ')[0];
            Account SellerAccount = CustomerServiceUtility.getAccountDetail(' (Id = \'' + documentRecord[0].Opportunity__r.Seller__c + '\') ')[0];
            
            List<Account> BuyerJointOwners = new List<Account>();
            List<Account> sellerJointOwners = new List<Account>();
            
            Set<Id> jointOwnerAcocuntIds = new Set<Id>();
            String SellerjointOwnerAcocuntIdString;            
            String BuyerjoinOwnerAccountIdString;
            
            for(JointOwner__c jointOwner: [SELECT Account__c,Id,SalesOrder__c, Opportunity__c, Opportunity__r.SalesOrder__c FROM JointOwner__c WHERE (SalesOrder__c =: documentRecord[0].Opportunity__r.SalesOrder__c  OR Opportunity__c =:documentRecord[0].Opportunity__c )]){
                System.debug('jointOwner::'+jointOwner);
                if(jointOwner.SalesOrder__c != null){
                    SellerjointOwnerAcocuntIdString =  SellerjointOwnerAcocuntIdString != null ? (SellerjointOwnerAcocuntIdString + '\''+jointOwner.Account__c+'\',') : '\''+jointOwner.Account__c+'\','; 
                }if(jointOwner.Opportunity__c != null){
                    BuyerjoinOwnerAccountIdString  = BuyerjoinOwnerAccountIdString != null ? (BuyerjoinOwnerAccountIdString + + '\''+jointOwner.Account__c+'\',') : '\''+jointOwner.Account__c+'\',';
                }
            }
            sellerJointOwners.add(SellerAccount);
            if(SellerjointOwnerAcocuntIdString != null){
                if(SellerjointOwnerAcocuntIdString.endsWith(',')){
                    SellerjointOwnerAcocuntIdString = SellerjointOwnerAcocuntIdString.removeEnd(',');
                }
                sellerJointOwners.addAll(CustomerServiceUtility.getAccountDetail(' (Id in (' + SellerjointOwnerAcocuntIdString + ')  )'));
            }
            BuyerJointOwners.add(BuyerAccount);
            if(BuyerjoinOwnerAccountIdString != null){
                if(BuyerjoinOwnerAccountIdString.endsWith(',')){
                    BuyerjoinOwnerAccountIdString =  BuyerjoinOwnerAccountIdString.removeEnd(',');
                }
                BuyerJointOwners.addAll(CustomerServiceUtility.getAccountDetail(' (Id in (' + BuyerjoinOwnerAccountIdString + ')  )'));  
            }
            APISetting__mdt docuSignEnvelope = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_ENVELOPE);
            KeyValueModel keyValueModel = (KeyValueModel)JSON.deserializeStrict(docuSignEnvelope.Headers__c, KeyValueModel.class);
            String signProvider = (BuyerAccount.ResidentStatus__pc != null && BuyerAccount.ResidentStatus__pc == 'Resident') ? keyValueModel.uaepass : keyValueModel.idnow;

            List<DocumentModel> documentModel = new List<DocumentModel>();
            documentModel.add(new DocumentModel(Contentversion));
            
            EnvelopeRequestModel envelopeRequestModel = new EnvelopeRequestModel();
            envelopeRequestModel.emailSubject = CustomerAPIConstants.DOCUSIGN_EMAIL_SUBJECT;
            envelopeRequestModel.documents = documentModel;

            List<SignerModel> signers = new List<SignerModel>();
            RecipientModel recipientModel = new RecipientModel();

            for(Integer i=0; i<BuyerJointOwners.size() ; i++){
                String anchorString = BuyerJointOwners[i].Id + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER;
                signers.add(new SignerModel(BuyerJointOwners[i], anchorString, signProvider,String.valueOf(i+1),String.valueOf(i+1))); 
            }
            for(Integer i=0; i<sellerJointOwners.size() ; i++){
                String anchorString = sellerJointOwners[i].Id + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER;
                signers.add(new SignerModel(sellerJointOwners[i], anchorString, signProvider,String.valueOf(BuyerJointOwners.size()+i+1),String.valueOf(BuyerJointOwners.size()+i+1))); 
            }
            recipientModel.signers = signers;
            envelopeRequestModel.recipients = recipientModel;
            envelopeRequestModel.status = CustomerAPIConstants.DOCUSIGN_STATUS_SENT;

            envelopeId = callAPI(docuSignEnvelope, authToken, '', org.IsSandbox, 'Envelope', JSON.serialize(envelopeRequestModel));
            system.debug('envelopeId::'+envelopeId);
            if(envelopeId != null && envelopeId != ''){
                update new List<Document__c>{new Document__c(id=relatedSignDocumentId, DocuSignEnvelopeID__c=envelopeId)};
                    
                dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c();
                envelopeStatus.dfsle__DocuSignId__c   = envelopeId;
                envelopeStatus.dfsle__SenderName__c   = UserInfo.getUserName(); // Need to know where it is configured
                envelopeStatus.dfsle__SenderEmail__c  = UserInfo.getUserEmail(); // Need to know where it is configured
                envelopeStatus.dfsle__EmailSubject__c = CustomerAPIConstants.DOCUSIGN_EMAIL_SUBJECT;
                envelopeStatus.dfsle__Status__c       = CustomerAPIConstants.DOCUSIGN_STATUS_SENT;
                envelopeStatus.dfsle__Sent__c         = system.now();
                envelopeStatus.CreatedFromAPI__c      = true;
                insert envelopeStatus;
                List<dfsle__RecipientStatus__c> recipientStatusList = new List<dfsle__RecipientStatus__c>();
                for(SignerModel signer: signers){
                    dfsle__RecipientStatus__c recipientStatus = new dfsle__RecipientStatus__c();
                    recipientStatus.dfsle__EnvelopeStatus__c = envelopeStatus.Id;
                    recipientStatus.dfsle__Email__c = signer.email;
                    recipientStatus.dfsle__RoutingOrder__c = Decimal.valueOf(signer.routingOrder);
                    recipientStatus.dfsle__SourceId__c = docRecordId;
                    recipientStatus.dfsle__Type__c = 'Signer';
                    recipientStatus.dfsle__Status__c = 'Sent';
                    recipientStatus.Name = signer.Name;
                    recipientStatus.dfsle__Sent__c = System.now();
                    recipientStatusList.add(recipientStatus);
                }
                if(!recipientStatusList.isEmpty()){
                    insert recipientStatusList;
                }
            }
        }
        return Constants.SUCCESS_MESSAGE;
    }
    
    public static String callAPI(APISetting__mdt apiSetting, String token, String envelopeId, Boolean isSandbox, String apiName, String reqBody) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        String endPointURL = isSandbox ? apiSetting.SandboxURL__c : apiSetting.ProductionURL__c;
        if (apiName == 'Envelope') {
            endPointURL = endPointURL.replace('{{account_id}}', apiSetting.APIKey__c);
        } else if (apiName == 'DosuSignURL') { // Added by Daksh/Ajay
            endPointURL = endPointURL.replace('{{account_id}}', apiSetting.APIKey__c).replace('{{envelope_id}}', envelopeId);
        }
        
        request.setHeader('Content-Type', 'application/json');
        if (String.isNotBlank(token)) {
            request.setHeader('Authorization', 'Bearer ' + token);
        }
        request.setTimeout(120000);
        request.setEndpoint(endPointURL);
        request.setMethod(apiSetting.Method__c);
        request.setBody(reqBody);
        System.debug('docuSign>>>requestBody>>>' + reqBody);
        
        HttpResponse response = http.send(request);
        String docuSignRes = response.getBody();
        System.debug('docuSign>>>responseBody>>>' + docuSignRes);
        System.debug('apiName' + apiName); 
        String returnStr = '';
        if (apiName == 'Authentication') {
            if (!Test.isRunningTest()) {
                AuthenticationResponseModel authenticationModel = (AuthenticationResponseModel)JSON.deserializeStrict(docuSignRes, AuthenticationResponseModel.class);
                returnStr = authenticationModel.access_token;
            } else {
                returnStr = 'test';
            }
        } else if (apiName == 'Envelope') {
            if (!Test.isRunningTest()) {
                EnvelopeResponseModel envelopeModel = (EnvelopeResponseModel)JSON.deserializeStrict(docuSignRes, EnvelopeResponseModel.class);
                returnStr = envelopeModel.envelopeId;
            } else {
                returnStr = 'test';
            }
        } 
        else if (apiName == 'DosuSignURL') {  // Added by Daksh/Ajay
            
            URLResponseModel urlModel;
            if (!Test.isRunningTest()) {
                try {
                    urlModel = (URLResponseModel)JSON.deserializeStrict(docuSignRes, URLResponseModel.class);
                } catch (System.JSONException je) {
                    System.debug('DocuSign URL Parsing Error: ' + je.getMessage() + ' - Response: ' + docuSignRes);
                    throw new CalloutException('DocuSign URL Parsing Error: ' + je.getMessage());
                }
                if (urlModel.url == null && urlModel.errorCode != null) {
                    System.debug('DocuSign Error: ' + urlModel.errorCode + ' - ' + urlModel.message);
                    throw new CalloutException('DocuSign Error: ' + urlModel.message); 
                }
                
                returnStr = urlModel.url;
            }
            else {
                returnStr = 'test';
            }
        }
        
        return returnStr;
    }
    /* Wrapper class */
    public class AuthenticationRequestModel {
        public String grant_type                    {get;set;}
        public String assertion                     {get;set;}

        public AuthenticationRequestModel(String grantType, String assertion) {
            this.grant_type = grantType;
            this.assertion = assertion;
        }
    }

    public class AuthenticationResponseModel {
        public String access_token                  {get;set;}
        public String token_type                    {get;set;}
        public Integer expires_in                   {get;set;}
        public String scope                         {get;set;}
    }

    public class KeyValueModel {
        public String uaepass;
        public String idnow;
    }

    public class EnvelopeRequestModel {
        public String emailSubject                  {get;set;}
        public List<DocumentModel> documents        {get;set;}
        public RecipientModel recipients            {get;set;}
        public String status                        {get;set;}
    }

    public class DocumentModel {
        public Blob documentBase64                  {get;set;}
        public String name                          {get;set;}
        public String fileExtension                 {get;set;}
        public String documentId                    {get;set;}

        public DocumentModel(ContentVersion cv) {
            this.documentBase64 = cv.VersionData;
            this.name = cv.Title;
            this.fileExtension = cv.FileExtension;
            this.documentId = '1';
        }
    }

    public class RecipientModel {
        public List<SignerModel> signers {get;set;}
        
        public RecipientModel(Account acc, String anchorString, String signProvider) {
            List<SignerModel> signers = new List<SignerModel>();
            signers.add(new SignerModel(acc, anchorString, signProvider));
            this.signers = signers;
        }
        
        public RecipientModel() {
            this.signers = new List<SignerModel>();
        }
    }

    public class SignerModel {
        public String email                                                 {get;set;}
        public String name                                                  {get;set;}
        public String recipientId                                           {get;set;}
        public String routingOrder                                          {get;set;}
        public String clientUserId                                          {get;set;}
        public List<SignProviderModel> recipientSignatureProviders          {get;set;}
        public TabModel tabs                                                {get;set;}
        public String EmbeddedRecipientStartURL                             {get;set;}

        public SignerModel(Account acc, String anchorString, String signProvider) {
            this.email = acc.PersonEmail;
            this.name = acc.Name;
            this.clientUserId = acc.Name + '_' + acc.PersonEmail;            
            this.recipientId = '1';
            this.routingOrder = '1';
            this.recipientSignatureProviders = new List<SignProviderModel>();
            if (String.isNotBlank(signProvider)){
                this.recipientSignatureProviders.add(new SignProviderModel(signProvider));
            }
            this.tabs = new TabModel(anchorString);
        }
        public SignerModel(Account acc, String anchorString, String signProvider,String recipientId,String routingOrder) {
            this.email = acc.PersonEmail;
            this.name = acc.Name;
            this.clientUserId = acc.Name + '_' + acc.PersonEmail; 
            this.recipientId = recipientId;
            this.routingOrder = routingOrder;
            this.recipientSignatureProviders = new List<SignProviderModel>();
            if (String.isNotBlank(signProvider)){
                this.recipientSignatureProviders.add(new SignProviderModel(signProvider));
            }
            this.tabs = new TabModel(anchorString);
            this.EmbeddedRecipientStartURL = 'SIGN_AT_DOCUSIGN';
        }
    }

    public class SignProviderModel {
        public String signatureProviderName                                 {get;set;}
        public Map<String, String> signatureProviderOptions                 {get;set;}

        public SignProviderModel(String signProvider) {
            this.signatureProviderName = signProvider;
            this.signatureProviderOptions = new Map<String, String>();
        }
    }

    public class TabModel {
        public List<SignHereModel> signHereTabs     {get;set;}

        public TabModel(String anchorString) {
            List<SignHereModel> signHereTabs = new List<SignHereModel>();
            signHereTabs.add(new SignHereModel(anchorString));

            this.signHereTabs = signHereTabs;
        }
    }

    public class SignHereModel {
        public String anchorString                  {get;set;}
        public String anchorUnits                   {get;set;}
        public String anchorXOffset                 {get;set;}
        public String anchorYOffset                 {get;set;}

        public SignHereModel(String anchorString) {
            this.anchorString = anchorString;
            this.anchorUnits = 'pixels';
            this.anchorXOffset = '20';
            this.anchorYOffset = '10';
        }
    }

    public class EnvelopeResponseModel {
        public String envelopeId                    {get;set;}
        public String uri                           {get;set;}
        public String statusDateTime                {get;set;}
        public String status                        {get;set;}
    }

    public class URLRequestModel {
        public String returnUrl                     {get;set;}
        public String authenticationMethod          {get;set;}
        public String email                         {get;set;}
        public String userName                      {get;set;}
        public String clientUserId                  {get;set;}

        public URLRequestModel(String returnUrl, Account acc) {
            this.returnUrl = returnUrl;
            this.authenticationMethod = 'none';
            this.email = acc.PersonEmail;
            this.userName = acc.Name;
            this.clientUserId = acc.Id + '_' + acc.PersonEmail;
        }
    }

    public class URLResponseModel {
        public String url                           {get;set;}
        public String errorCode                     {get;set;} //Added by Tajinkumar
        public String message                       {get;set;} //Added by Tajinkumar
    }
}