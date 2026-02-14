/*
* Name               : CustomerGetDocuSignURLWebService
* Description        : This class is used to get DocuSign url for Signature
*/
@RestResource (urlMapping = '/customer/getdocusignurl')
global without sharing class CustomerGetDocuSignURLWebService {
    
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
            System.debug('Error Message' + ex.getMessage() + ' - ' + ex.getStackTraceString());
            handler.finalize(ex);
            RestContext.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
        }
    }
    
    public static String getDocuSignURL(String customerId, String documentId, String returnURL) {
        String docuSignDocumentURL = '';
        Boolean skipKycGeneration = false;
        if(!String.isBlank(Label.Enable_KYC_History_Validation)) {
            skipKycGeneration = Boolean.valueOf(Label.Enable_KYC_History_Validation);
        }

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

        //DOA AND OA 
        list<HexaBPM__SR_Doc__c> nocSrDoc = [ SELECT Id, Name,HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.SRType__c,HexaBPM__Service_Request__r.BuyerName__c FROM HexaBPM__SR_Doc__c WHERE Id = :documentId  AND  HexaBPM__Service_Request__r.SRType__c='Property Transfer NOC'];
        
        if(!nocSrDoc.isEmpty()){
        if((nocSrDoc[0].Name=='Owner Association Letter' || nocSrDoc[0].Name=='Document of Adherence') && !Test.isrunningTest()){
            return DocuSignMultiBuyerSigner.handleNOCDocuments(customerId, documentId, returnURL,authToken,org);
        }
        }
        
        ContentVersion cv = CustomerServiceUtility.getContentVersion(documentId);
        System.debug('ContentVersion>>>' + cv);

        if ((cv != null && cv.Id != null) ||Test.isrunningTest()) {
            List<DocumentModel> documentModel = new List<DocumentModel>();
            documentModel.add(new DocumentModel(cv));

            String anchorString = customerId + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER;
            system.debug('+++ anchorString '+anchorString);
            String salesOrderId = '';
            List<Document__c> relatedSignedDocument  = new List<Document__c>();
            List<HexaBPM__SR_Doc__c> relatedSignedSrDocument  = new List<HexaBPM__SR_Doc__c>(); //Added by rajat
            if (((Id)documentId).getSObjectType() == Document__c.getSObjectType()) {
                Document__c document = CustomerServiceUtility.getDocumentDetail(' (Id = \'' + documentId + '\') ')[0];
                if(document.DocumentType__c != 'Listing Agreement'){
                    if (document.DocumentType__c.containsIgnoreCase('spa')) {
                        //Added by CHIRAG START
                        relatedSignedDocument = [select id, DocuSignEnvelopeID__c FROM Document__c WHERE SalesOrder__c =: document.SalesOrder__c AND DocumentType__c = 'Aldar Signed SPA' LIMIT 1];
                        //Added by CHIRAG END
                        /*anchorString = account.AccountNumber__c + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER;
                        salesOrderId = document.SalesOrder__c;
                       SalesOrder__c salesOrder = CustomerServiceUtility.getSalesOrderDetail(' (Id = \'' + document.SalesOrder__c + '\') ')[0];
                        if (!salesOrder.Joint_OwnersSalesOrder__r.isEmpty()) {
                            //DownloadSODocsController.sendForESign(document.Id);
                            
                            //return CustomerAPIConstants.MULTI_SIGNATURES_FOUND;
                        }*/
                    } else {
                        anchorString = String.isNotBlank(document.SalesOrder__c) ? document.SalesOrder__c + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER : String.isNotBlank(document.Case__c) ? document.Case__c + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER : customerId + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER;
                    }
                    if(document.DocumentType__c.containsIgnoreCase('Parking')){
                        String signedCopy = 'Signed '+document.DocumentType__c;
                        relatedSignedDocument = [select id, DocuSignEnvelopeID__c FROM Document__c WHERE Order__c =: document.Order__c AND DocumentType__c =:signedCopy LIMIT 1];
                    }
                }
            }
            //Added by rajat for handling SR docs START
            else if (((Id)documentId).getSObjectType() == HexaBPM__SR_Doc__c.getSObjectType()){ 
                
                HexaBPM__SR_Doc__c srDoc = CustomerServiceUtility.getSRDocDetail(' (Id = \'' + documentId + '\') ')[0];
                
                List<String> likedSignedStringList = new List<String>();
                likedSignedStringList.add(Constants.DOCUMENT_TYPE_PREFIX_SIGNED + '_' + srDoc.DocumentMasterCode__c);
                likedSignedStringList.add(Constants.DOCUMENT_TYPE_PREFIX_SIGNED + '' + srDoc.DocumentMasterCode__c);
                likedSignedStringList.add(Constants.DOCUMENT_TYPE_PREFIX_SIGNED + ' ' + srDoc.DocumentMasterCode__c);
                String likedSignedString = String.join(likedSignedStringList, '\',\'');
                String whrClause = ' DocumentMasterCode__c IN (\'' + likedSignedString + '\') ';

                relatedSignedSrDocument = CustomerServiceUtility.getSRDocDetail(' (' + whrClause + ' AND HexaBPM__Service_Request__c = \'' + srDoc.HexaBPM__Service_Request__c + '\') ');
                
            }
            //Added by rajat for handling SR docs END
            System.debug('anchorString>>>' + anchorString);

            //--- Start | Create DocuSign Envelope
            APISetting__mdt docuSignEnvelope = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_ENVELOPE);
            KeyValueModel keyValueModel = (KeyValueModel)JSON.deserializeStrict(docuSignEnvelope.Headers__c, KeyValueModel.class);
            String signProvider = String.isNotBlank(salesOrderId) ? (account.ResidentStatus__pc != null && account.ResidentStatus__pc == 'Resident' ? keyValueModel.uaepass : keyValueModel.idnow) : '';

            EnvelopeRequestModel envelopeRequestModel = new EnvelopeRequestModel();
            envelopeRequestModel.emailSubject = CustomerAPIConstants.DOCUSIGN_EMAIL_SUBJECT;
            envelopeRequestModel.documents = documentModel;
            envelopeRequestModel.recipients = new RecipientModel(account, anchorString, signProvider);
            envelopeRequestModel.status = CustomerAPIConstants.DOCUSIGN_STATUS_SENT;
            //Added by Chirag START
            String envId = '';
            if(relatedSignedDocument.size() >0 && relatedSignedDocument[0].DocuSignEnvelopeID__c != null){
                envId = relatedSignedDocument[0].DocuSignEnvelopeID__c;
            }
            //Added by rajat START
            if(relatedSignedSrDocument.size() >0 && relatedSignedSrDocument[0].Docusign_Envelope_Id__c != null){
                envId = relatedSignedSrDocument[0].Docusign_Envelope_Id__c;
            }
            //Added by rajat END
            String envelopeId =  envId != '' ? envId :callAPI(docuSignEnvelope, authToken, '', org.IsSandbox, 'Envelope', JSON.serialize(envelopeRequestModel));
            //Added by CHirag END
            //--- End | Create DocuSign Envelope

            //--- Start | Get DocuSign URL
            APISetting__mdt docuSignURL = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_URL);
            docuSignDocumentURL = callAPI(docuSignURL, authToken, envelopeId, org.IsSandbox, 'DosuSignURL', JSON.serialize(new URLRequestModel(returnURL, account)));
            //--- End | Get DocuSign URL

            if (((Id)documentId).getSObjectType() == Document__c.getSObjectType()) {
                // Add the document's DocuSign envelope Id so that a sign document will be attached to the sign placeholder after the document has been signed
                Document__c document = CustomerServiceUtility.getDocumentDetail(' (Id = \'' + documentId + '\') ')[0];
                String documentType = document.DocumentType__c.containsIgnoreCase('spa') ? Constants.DOCUMENT_TYPE_ALDAR_SIGNED_SPA : Constants.DOCUMENT_TYPE_PREFIX_SIGNED + ' ' + document.DocumentType__c;
                
                String docWhereClause = ' (Account__c = \'' + customerId + '\' AND DocumentType__c = \'' + documentType + '\') ';
                if (String.isNotBlank(document.SalesOrder__c)) {
                    docWhereClause = ' (SalesOrder__c = \'' + document.SalesOrder__c + '\' AND DocumentType__c = \'' + documentType + '\') ';
                } else if (String.isNotBlank(document.Case__c)) {
                    docWhereClause = ' (Case__c = \'' + document.Case__c + '\' AND DocumentType__c = \'' + documentType + '\') ';
                }
                //Added by Harsh@ALD - For Premium Parking Quotes - search via Quote too
                //Added by Harsh@Aldar - 20/03/2025 - Premium Parking - Updated docusign to work on Order
                else if (String.isNotBlank(document.Order__c)) {
                    docWhereClause = ' (Order__c = \'' + document.Order__c + '\' AND DocumentType__c = \'' + documentType + '\') ';
                }

                List<Document__c> signedDocument = CustomerServiceUtility.getDocumentDetail(docWhereClause);
                if (!signedDocument.isEmpty()) {
                    signedDocument[0].DocuSignEnvelopeID__c = envelopeId;
                    update signedDocument[0];

                    if (document.DocumentType__c.containsIgnoreCase('spa')) {
                        document.DocuSignEnvelopeID__c = envelopeId;
                        update document;
                    }
                } else {
                    document.DocuSignEnvelopeID__c = envelopeId;
                    update document;
                }
            } 
            else if ((((Id)documentId).getSObjectType() == HexaBPM__SR_Doc__c.getSObjectType())||Test.isrunningTest()) {
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
            }
        } else {
            // If document is not generate then throw error and generate document at the same time
            docuSignDocumentURL = CustomerAPIConstants.MESSAGE_DOCUMENT_NOT_FOUND;
            
            if ((((Id)documentId).getSObjectType() == Document__c.getSObjectType()) ||Test.isrunningTest()) {
                Document__c document = CustomerServiceUtility.getDocumentDetail(' (Id = \'' + documentId + '\') ')[0];
                if(skipKycGeneration && document != null && document.DocumentType__c == Constants.DOCUMENT_TYPE_KYC) {
                    System.debug('Skipping GenerateDocument__c for KYC due to feature flag');
                } else {
                    document.GenerateDocument__c = true;
                    update document;
                }
                
            } else if ((((Id)documentId).getSObjectType() == HexaBPM__SR_Doc__c.getSObjectType())||Test.isrunningTest()) {
                HexaBPM__SR_Doc__c srDoc = CustomerServiceUtility.getSRDocDetail(' (Id = \'' + documentId + '\') ')[0];
                srDoc.HexaBPM__Generate_Document__c = true;
                update srDoc;
            }
        }

        return docuSignDocumentURL;
    }

    // Call DocuSign API to get Access Token, Envelope and URL
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
                try{
                    AuthenticationResponseModel authenticationModel = (AuthenticationResponseModel)JSON.deserializeStrict(docuSignRes, AuthenticationResponseModel.class);
                    returnStr = authenticationModel.access_token;
                } catch (JSONException je) {
                    System.debug('Authentication failed: ' + docuSignRes);
                    throw new CalloutException('DocuSign Authentication Error: ' + docuSignRes);
                }
                
            } else {
                returnStr = 'test';
            }
        } else if (apiName == 'Envelope') {
            if (!Test.isRunningTest()) {
                try{
                    EnvelopeResponseModel envelopeModel = (EnvelopeResponseModel)JSON.deserializeStrict(docuSignRes, EnvelopeResponseModel.class);
                    returnStr = envelopeModel.envelopeId;
                } catch (JSONException je) {
                    System.debug('Envelope creation failed: ' + docuSignRes);
                    throw new CalloutException('DocuSign Envelope Error: ' + docuSignRes);
                }
                
            } else {
                returnStr = 'test';
            }
        } else if (apiName == 'DosuSignURL') {
            
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
          // this.clientUserId = acc.Name + '_' + acc.PersonEmail; 
            this.clientUserId = acc.Id + '_' + acc.PersonEmail; // Added by Tajinkumar
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
          //this.clientUserId = acc.Name + '_' + acc.PersonEmail;
            this.clientUserId = acc.Id + '_' + acc.PersonEmail; // Added by Tajinkumar
        }
    }

    public class URLResponseModel {
        public String url                           {get;set;}
        public String errorCode                     {get;set;} //Added by Tajinkumar
        public String message                       {get;set;} //Added by Tajinkumar
    }
}