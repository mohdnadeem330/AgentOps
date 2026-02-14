@RestResource (urlMapping = '/customer/getmoudocusignurl')
global class CustomerGetDocuSignURLMOUWebService {
    @HTTPPost
    global static void doPost(String customerId, String documentId, String returnURL, String referenceId){
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = getDocuSignURL(customerId, documentId, returnURL);
            handler.response.success = true;
            handler.finalize();
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
        
    }
    public static String getDocuSignURL(String customerId, String documentId, String returnURL) {
        String docuSignDocumentURL = '';
        
        Organization org = Utilities.getOrganizationDetails();
        Account account = CustomerServiceUtility.getAccountDetail(' (Id = \'' + customerId + '\') ')[0];
        
        //--- Start | Get Authentication Token
        APISetting__mdt docuSignAuthentication = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_AUTHENTICATION);
        String pvtKey = Utilities.getConstant(CustomerAPIConstants.DOCUSIGN_PRIVATE_KEY).ConstantValueLong__c;
        String jwtToken = JWTToken.issueToken(docuSignAuthentication, org.IsSandbox, pvtKey);
        System.debug('jwtToken>>>' + jwtToken);
        
        String authToken = callAPI(docuSignAuthentication, '', '', org.IsSandbox, 'Authentication', JSON.serialize(new AuthenticationRequestModel(CustomerAPIConstants.GRANT_TYPE, jwtToken)));
        System.debug('authToken>>>' + authToken);
        //--- End | Get Authentication Token
        
        ContentVersion cv = CustomerServiceUtility.getContentVersion(documentId);
        System.debug('ContentVersion>>>' + cv);
        
        if (cv != null && cv.Id != null) {
            List<DocumentModel> documentModel = new List<DocumentModel>();
            documentModel.add(new DocumentModel(cv));
            
            String anchorString = customerId + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER;
            String envelopeId;
            
            APISetting__mdt docuSignEnvelope = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_ENVELOPE);
            Document__c document = CustomerServiceUtility.getDocumentDetail(' (Id = \'' + documentId + '\') ')[0];
            Document__c relatedDocument = [select id, DocuSignEnvelopeID__c from Document__c where Id = :documentId];
            Document__c relatedSignedDocument = [select id, DocuSignEnvelopeID__c FROM Document__c WHERE Opportunity__c =: document.Opportunity__c AND DocumentType__c = 'Signed Listing MOU'];
            envelopeId = relatedSignedDocument.DocuSignEnvelopeID__c != null ? relatedSignedDocument.DocuSignEnvelopeID__c : DocusignForMOUListing.sendForESignResale(documentId, relatedSignedDocument.Id);
            system.debug('envelopeId::'+envelopeId);
            
            APISetting__mdt docuSignURL = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_URL);
            system.debug('docuSignURL::'+docuSignURL);
            system.debug('documentId::'+documentId);

            docuSignDocumentURL = callAPI(docuSignURL, authToken, envelopeId, org.IsSandbox, 'DosuSignURL', JSON.serialize(new URLRequestModel(returnURL, account)));
           
            system.debug('Type of Object::'+(((Id)documentId).getSObjectType()));
            system.debug('docuSignDocumentURL::'+docuSignDocumentURL);
           
            if (((Id)documentId).getSObjectType() == Document__c.getSObjectType()) {
                // Add the document's DocuSign envelope Id so that a sign document will be attached to the sign placeholder after the document has been signed
                
                String documentType = document.DocumentType__c.containsIgnoreCase('spa') ? Constants.DOCUMENT_TYPE_ALDAR_SIGNED_SPA : Constants.DOCUMENT_TYPE_PREFIX_SIGNED + ' ' + document.DocumentType__c;
                
                String docWhereClause = ' (Account__c = \'' + customerId + '\' AND DocumentType__c = \'' + documentType + '\') ';
                if (String.isNotBlank(document.SalesOrder__c)) {
                    docWhereClause = ' (SalesOrder__c = \'' + document.SalesOrder__c + '\' AND DocumentType__c = \'' + documentType + '\') ';
                } else if (String.isNotBlank(document.Case__c)) {
                    docWhereClause = ' (Case__c = \'' + document.Case__c + '\' AND DocumentType__c = \'' + documentType + '\') ';
                }
                
                List<Document__c> signedDocument = CustomerServiceUtility.getDocumentDetail(docWhereClause);
                if (!signedDocument.isEmpty()) {
                    signedDocument[0].DocuSignEnvelopeID__c = envelopeId;
                    update signedDocument[0];
                } else {
                    document.DocuSignEnvelopeID__c = envelopeId;
                    update document;
                }
            } /*else if (((Id)documentId).getSObjectType() == HexaBPM__SR_Doc__c.getSObjectType()) {
                HexaBPM__SR_Doc__c srDoc = CustomerServiceUtility.getSRDocDetail(' (Id = \'' + documentId + '\') ')[0];
                
                List<String> likedSignedStringList = new List<String>();
                likedSignedStringList.add(Constants.DOCUMENT_TYPE_PREFIX_SIGNED + '_' + srDoc.DocumentMasterCode__c);
                likedSignedStringList.add(Constants.DOCUMENT_TYPE_PREFIX_SIGNED + '' + srDoc.DocumentMasterCode__c);
                likedSignedStringList.add(Constants.DOCUMENT_TYPE_PREFIX_SIGNED + ' ' + srDoc.DocumentMasterCode__c);
                String likedSignedString = String.join(likedSignedStringList, '\',\'');
                String whrClause = ' DocumentMasterCode__c IN (\'' + likedSignedString + '\') ';
                
                List<HexaBPM__SR_Doc__c> updateSignedSRDoc = CustomerServiceUtility.getSRDocDetail(' (' + whrClause + ' AND HexaBPM__Service_Request__c = \'' + srDoc.HexaBPM__Service_Request__c + '\') ');
                if (!updateSignedSRDoc.isEmpty()) {
                    updateSignedSRDoc[0].Docusign_Envelope_Id__c = envelopeId;
                    update updateSignedSRDoc[0];
                } else {
                    srDoc.Docusign_Envelope_Id__c = envelopeId;
                    update srDoc;
                }
            } */
        } else {
            // If document is not generate then throw error and generate document at the same time
            docuSignDocumentURL = CustomerAPIConstants.MESSAGE_DOCUMENT_NOT_FOUND;
            
            if (((Id)documentId).getSObjectType() == Document__c.getSObjectType()) {
                Document__c document = CustomerServiceUtility.getDocumentDetail(' (Id = \'' + documentId + '\') ')[0]; 
                document.GenerateDocument__c = true;
                update document;
            } 
        }
        system.debug('docuSignDocumentURL::'+docuSignDocumentURL);
        return docuSignDocumentURL;
    }
    
    public static String callAPI(APISetting__mdt apiSetting, String token, String envelopeId, Boolean isSandbox, String apiName, String reqBody) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        String endPointURL = isSandbox ? apiSetting.SandboxURL__c : apiSetting.ProductionURL__c;
        if (apiName == 'Envelope') {
            endPointURL = endPointURL.replace('{{account_id}}', apiSetting.APIKey__c);
        } else if (apiName == 'DosuSignURL') {
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
        } else if (apiName == 'DosuSignURL') {
            if (!Test.isRunningTest()) {
                URLResponseModel urlModel = (URLResponseModel)JSON.deserializeStrict(docuSignRes, URLResponseModel.class);
                returnStr = urlModel.url;
            } else {
                returnStr = 'test';
            }
        }
        
        return returnStr;
    }
    
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
        public List<SignerModel> signers            {get;set;}
        
        public RecipientModel(Account acc, String anchorString, String signProvider) {
            List<SignerModel> signers = new List<SignerModel>();
            signers.add(new SignerModel(acc, anchorString, signProvider));
            
            this.signers = signers;
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
            this.clientUserId = acc.Name + '_' + acc.PersonEmail;
        }
    }
    
    public class URLResponseModel {
        public String url                           {get;set;}
    }
}