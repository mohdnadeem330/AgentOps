/**********************************************************************************************************************
* Name              : DocusignStatusWebService                                                         
* Description       : class to return the Signed doc details and status
* Created By & Date : Daksh Sharma - 11-Nov-2025
**********************************************************************************************************************/
@RestResource(urlmapping = '/LiveAldar/DocusignStatusWebService')
global with sharing class DocusignStatusWebService {
     global class StandardResponse{
        public Boolean success;
        public Integer statusCode;
        public String requestId;
        public String message;
        public Object data;
        public StandardResponse(Boolean success, Integer statusCode, String message, Object data, String  requestId){
            this.success = success;
            this.statusCode = statusCode;
            this.message = message;
            this.data = data;
            this.requestId = requestId;
        }
    }
    
    global class ReceiptWrapper{
        public string accountName { get; set; }
        public String emailId { get; set; }
        public String status { get; set; }
        public DateTime createdDate { get; set; }
        public String docName { get; set; }
        public ReceiptWrapper( dfsle__RecipientStatus__c rec, String docName ){
            this.accountName = rec.Name;
            this.emailId = rec.dfsle__Email__c;
            this.status = rec.dfsle__Status__c;
            this.createdDate = rec.CreatedDate;
            this.docName = docName;
        }
    }
    
    @HttpGet
    global static void doGet(){
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type','application/json');
        String documentId = RestContext.request.params.get('documentId');
        String customerId = RestContext.request.params.get('customerId');
        String returnURL = RestContext.request.params.get('returnURL');
        String requestId = documentId;
        //String authorisedSignatory = 'hardikkumar.vitthani.tpr@pwc.com'; 
        try{
            if(String.isBlank(documentId)){
                sendResponse(false, 400, 'Missing required parameter: documentId', null, null);
                return;
            }
            
            List<HexaBPM__SR_Doc__c> srDocList = [SELECT Id, Name, HexaBPM__Service_Request__c,HexaBPM__Service_Request__r.RecordType.Name FROM HexaBPM__SR_Doc__c WHERE Id =: documentId Limit 1];
            System.debug('srDocList -> '+ srDocList);
            if(srDocList.isEmpty()){
                sendResponse(false, 404, 'No Service Request found for the provided document Id' , null, requestId);
                return;
            }
            
            if(!String.isBlank(documentId) && !String.isBlank(customerId) && !String.isBlank(returnURL)){
                String url = DocusignSPAData(documentId, customerId, returnURL);
                if(!String.isBlank(url)){
                    sendResponse(true, 200, 'Document details fetched successfully', 
                                 new List<Object>{ new Map<String,Object>{ 'docuSignDocumentURL' => url } }, 
                                 requestId);
                }else{
                    sendResponse(false, 404, 'DocuSign URL not generated', null, requestId);
                }
                return;
            }
            
            if(!String.isBlank(documentId) && String.isBlank(customerId) && String.isBlank(returnURL)){
                String signedSrDocName = '%'+srDocList[0].Name+'%';
                String authorisedSignatory = [SELECT Id, FullName__c, EmailAddress__c, Type__c FROM InternalSignatories__mdt WHERE Type__c ='Property transfer' limit 1].EmailAddress__c;
                List<HexaBPM__SR_Doc__c> srDocSignedList = [SELECT Id, Name, Docusign_Envelope_Id__c FROM HexaBPM__SR_Doc__c 
                                                            WHERE HexaBPM__Service_Request__c =: srDocList[0].HexaBPM__Service_Request__c 
                                                            AND Docusign_Envelope_Id__c != null AND Name LIKE :signedSrDocName];
                if(srDocSignedList.isEmpty()){
                    sendResponse(false, 404, 'Please send for the signature first', null, requestId);
                    return;
                }
                Map<String, String> envelopeIdDocNameMap = new Map<String,String>();
                for(HexaBPM__SR_Doc__c drDoc: srDocSignedList){
                    envelopeIdDocNameMap.put(drDoc.Docusign_Envelope_Id__c,drDoc.Name);
                }
                
                List<dfsle__RecipientStatus__c> recipientStatusList = [SELECT Id, Name, dfsle__Email__c, dfsle__Status__c, CreatedDate, dfsle__EnvelopeStatus__r.dfsle__DocuSignId__c FROM dfsle__RecipientStatus__c
                                                                       WHERE dfsle__EnvelopeStatus__r.dfsle__DocuSignId__c =: srDocSignedList[0].Docusign_Envelope_Id__c];
                if(recipientStatusList.isEmpty()){
                    sendResponse(false, 404, 'Envelope initiated !!', null, requestId);
                    return;
                }
                
                List<ReceiptWrapper> responseWrapperList = new List<ReceiptWrapper>();
                for(dfsle__RecipientStatus__c rec: recipientStatusList){
                    String envId = rec.dfsle__EnvelopeStatus__r.dfsle__DocuSignId__c;
                    String docName = envelopeIdDocNameMap.containsKey(envId) ? envelopeIdDocNameMap.get(envId):null;
                    responseWrapperList.add(new ReceiptWrapper(rec, docName));
                }
                
                sendResponse(true, 200, 'Document details fetched successfully', responseWrapperList, requestId);
                return;
            }
            
            sendResponse(false, 400, 'Invalid parameter combination', null, requestId);
            
        }catch (Exception ex){
            sendResponse(false, 500, 'Error at line '+ ex.getLineNumber() + ': '+ ex.getMessage(), null, requestId);
        }
    }

    
    private static void sendResponse(Boolean success, Integer code, String msg, Object data, String requestId){
        RestResponse res = RestContext.response;
        res.statusCode = code;
        StandardResponse sr = new StandardResponse(success, code, msg, data, requestId);
        res.responseBody = Blob.valueOf(JSON.serialize(sr));
    }
    
    public static String DocusignSPAData(String docRecordId,String customerId,String returnURL){
        
        Organization org = Utilities.getOrganizationDetails();
        APISetting__mdt docuSignAuthentication = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_AUTHENTICATION);
        String pvtKey = Utilities.getConstant(CustomerAPIConstants.DOCUSIGN_PRIVATE_KEY).ConstantValueLong__c;
        String jwtToken = !Test.isRunningTest() ? JWTToken.issueToken(docuSignAuthentication, org.IsSandbox, pvtKey) : 'mock-jwt-token';
        String authToken = DocusignForMOUListing.callAPI(docuSignAuthentication, '', '', org.IsSandbox, 'Authentication', JSON.serialize(new DocuSignAPIWrapper.AuthenticationRequestModel(CustomerAPIConstants.GRANT_TYPE, jwtToken)));
       	
        String ALDARAPPROVERROLE = Label.DOCUSIGN_ALDARAPPROVERROLE;
        String ALDARUAEPASSROLE = Label.DOCUSIGN_ALDARUAEPASSROLE;
        //Integer idNowSequence = Integer.valueOf(Label.DOCUSIGN_idNowSequence) ;
        //Integer uaePassSequence =  Integer.valueOf(Label.DOCUSIGN_uaePassSequence) ;
        //Integer aldarApproverSequence =  Integer.valueOf(Label.DOCUSIGN_aldarApproverSequence) ;
   		//Integer aldarSignSequence =  Integer.valueOf(Label.DOCUSIGN_aldarSignSequence) ;
        
        
        
        //list<HexaBPM__SR_Doc__c> srDoc = CustomerServiceUtility.getSRDocDetail(' (Id = \'' + docRecordId + '\') ');
        List<HexaBPM__SR_Doc__c> srDoc = [SELECT Id, Name, HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.RecordTypeId, 
                                                    HexaBPM__Service_Request__r.RecordType.Name, DocumentMasterCode__c, 
                                                    HexaBPM__SR_Template_Doc__c, HexaBPM__SR_Template_Doc__r.ESignGroup__c, 
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__c,HexaBPM__Service_Request__r.SalesOrder__c,
                                          			HexaBPM__Service_Request__r.SalesOrder__r.unit__r.Name,
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.Name,
                                          			HexaBPM__Service_Request__r.HexaBPM__Customer__r.AccountNumber__c,
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.PersonEmail,
                                                    HexaBPM__Service_Request__r.Unit__r.Project__r.Development_Manager_Email__c, 
                                                    HexaBPM__Service_Request__r.HexaBPM__Customer__r.Email__c, 
                                                    HexaBPM__Service_Request__r.BuyerName__c, HexaBPM__Service_Request__r.BuyerName__r.Name,
                                          			HexaBPM__Service_Request__r.BuyerName__r.AccountNumber__c,
                                                    HexaBPM__Service_Request__r.BuyerName__r.PersonEmail,
                                                    HexaBPM__Service_Request__r.HandoverDetail__c, 
                                                    HexaBPM__Service_Request__r.BuyerName__r.Email__c
                                                    FROM HexaBPM__SR_Doc__c WHERE Id =: docRecordId LIMIT 1];
                                                    
		return createRecipientList(srDoc,customerId,org,authToken,returnURL);
       
    }
    public static String createRecipientList(List<HexaBPM__SR_Doc__c> documentRecord,String customerId,Organization org,String authToken, String returnURL ){
        String relatedAccountId ='';
        String relatedsObjectId ='';
        String docType ='';
        String signedDoc ='';
        String docuSignDocumentURL = '';
        Account account = CustomerServiceUtility.getAccountDetail(' (Id = \'' + customerId + '\') ')[0];
        HexaBPM__SR_Doc__c relatedSignDocument  = new HexaBPM__SR_Doc__c();
        List<AgencyTeam__c> SRjointOwnerList = new List<AgencyTeam__c>();
         relatedAccountId =documentRecord[0].HexaBPM__Service_Request__r.BuyerName__c;
         relatedsObjectId  = documentRecord[0].HexaBPM__Service_Request__c;
         docType = documentRecord[0].Name;
		 signedDoc = 'Signed ' +docType;
		system.debug('documentRecordId.'+documentRecord[0].Id);
        system.debug('relatedsObjectId-->'+relatedsObjectId);
        List<String> likedSignedStringList = new List<String>();
        likedSignedStringList.add(Constants.DOCUMENT_TYPE_PREFIX_SIGNED + '_' + documentRecord[0].DocumentMasterCode__c);
        likedSignedStringList.add(Constants.DOCUMENT_TYPE_PREFIX_SIGNED + '' + documentRecord[0].DocumentMasterCode__c);
        likedSignedStringList.add(Constants.DOCUMENT_TYPE_PREFIX_SIGNED + ' ' + documentRecord[0].DocumentMasterCode__c);
        String likedSignedString = String.join(likedSignedStringList, '\',\'');
        String whrClause = ' DocumentMasterCode__c IN (\'' + likedSignedString + '\') ';

        relatedSignDocument = CustomerServiceUtility.getSRDocDetail(' (' + whrClause + ' AND HexaBPM__Service_Request__c = \'' + documentRecord[0].HexaBPM__Service_Request__c + '\') ')[0];
		system.debug('relatedSignDocument-->'+relatedSignDocument);
        
        
        SRjointOwnerList = [SELECT Id,Account__c,Account__r.Name,Account__r.isPersonAccount,Account__r.ResidentStatus__pc,ShareHoldingPercentage__c  ,Account__r.AccountNumber__c FROM AgencyTeam__c WHERE  ServiceRequest__c = :relatedsObjectId ];
        

       
        ContentVersion Contentversion = CustomerServiceUtility.getContentVersion(documentRecord[0].Id);
        
        /*Account relatedAccount = [select id,Name,isPersonAccount,AccountNumber__c,ResidentStatus__pc, FirstName,LastName, PersonEmail,(select id,FirstName,LastName, Email from Contacts where PrimaryContact__c =true) from account where id = :relatedAccountId limit 1];
       
        
        String primaryRecipientRole = '';
        
        String recipientName = relatedAccount.isPersonAccount ? (relatedAccount.FirstName + ' '+ relatedAccount.LastName) : (relatedAccount.Contacts[0].FirstName + ' '+ relatedAccount.Contacts[0].LastName); // Recipient name
         */       
       	APISetting__mdt docuSignEnvelope = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_ENVELOPE);
       	String signProvider = '';
        List<DocuSignAPIWrapper.DocumentModel> documentModel = new List<DocuSignAPIWrapper.DocumentModel>();
        System.debug('Chi'+Contentversion);
        documentModel.add(new DocuSignAPIWrapper.DocumentModel(Contentversion));
        
        DocuSignAPIWrapper.EnvelopeRequestModel envelopeRequestModel = new DocuSignAPIWrapper.EnvelopeRequestModel();
        String emailBody = '';
        
        envelopeRequestModel.emailSubject =  Label.DOCUSIGN_EmailSubject +' '+documentRecord[0].HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name;
        emailBody += Label.DOCUSIGN_EmailBody;
        emailBody += '<a href="';
        emailBody += '" target="_blank"> click here</a>';
        emailBody += Label.DOCUSIGN_EmailBody2;   
        emailBody += Label.DOCUSIGN_EmailBody3;
        
       
        envelopeRequestModel.emailBlurb = emailBody;
        //envelopeRequestModel.emailSubject = CustomerAPIConstants.DOCUSIGN_EMAIL_SUBJECT;
        envelopeRequestModel.documents = documentModel;
        DocuSignAPIWrapper.notifications ntf= new DocuSignAPIWrapper.notifications();
        ntf.useAccountDefaults = true;
        envelopeRequestModel.notification = ntf;

        List<DocuSignAPIWrapper.SignerModel> signers = new List<DocuSignAPIWrapper.SignerModel>();
        DocuSignAPIWrapper.RecipientModel recipientModel = new DocuSignAPIWrapper.RecipientModel();
        List<String> eSignGroupList = String.isNotBlank(documentRecord[0].HexaBPM__SR_Template_Doc__r.ESignGroup__c) ? documentRecord[0].HexaBPM__SR_Template_Doc__r.ESignGroup__c.split(';') : new List<String>();
        Integer routingOrder = 1;
        //seller recipient
        //Buyer Recipient
        if (eSignGroupList.contains(Constants.BUYER_ESIGN) && documentRecord[0].HexaBPM__Service_Request__r.BuyerName__c != null) {
            String recipientKey = documentRecord[0].Id + '' + documentRecord[0].HexaBPM__Service_Request__r.BuyerName__c;
            if(documentRecord[0].Name == 'PT Unified Digital SPA'){
                recipientKey = documentRecord[0].HexaBPM__Service_Request__r.BuyerName__r.AccountNumber__c;
            }
            String recipientEmail = documentRecord[0].HexaBPM__Service_Request__r.BuyerName__r.PersonEmail != null ? documentRecord[0].HexaBPM__Service_Request__r.BuyerName__r.PersonEmail : documentRecord[0].HexaBPM__Service_Request__r.BuyerName__r.Email__c; // Recipient email
           	String primarySignHolder = documentRecord[0].HexaBPM__Service_Request__r.BuyerName__r.PersonEmail!= null ? recipientKey+'SignatureHolder' : recipientKey+'OrgSignatureHolder'; 
            String primaryDateHolder = documentRecord[0].HexaBPM__Service_Request__r.BuyerName__r.PersonEmail!= null ? recipientKey+'DateHolder' : recipientKey+'OrgDateHolder'; 
            String primaryInitialHolder = documentRecord[0].HexaBPM__Service_Request__r.BuyerName__r.PersonEmail!= null ? recipientKey+'InitialsHolder' : recipientKey+'OrgInitialsHolder'; 
            String primaryNameHolder = documentRecord[0].HexaBPM__Service_Request__r.BuyerName__r.PersonEmail!= null ? recipientKey+'NameHolder' : recipientKey+'OrgNameHolder'; 
            //String anchorString1 = relatedAccount.Id + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER;
            signers.add(new DocuSignAPIWrapper.SignerModel(documentRecord[0].HexaBPM__Service_Request__r.BuyerName__c,recipientEmail,documentRecord[0].HexaBPM__Service_Request__r.BuyerName__r.Name, primarySignHolder, signProvider,String.valueOf(routingOrder),String.valueOf(routingOrder),'Signer','',primaryNameHolder,primaryDateHolder,''));
            routingOrder += 1;
        }
        
        // Buyer with joint owner 
        if (eSignGroupList.contains(Constants.BUYER_WITH_JOINT_OWNER_ESIGN) && String.isNotBlank(documentRecord[0].HexaBPM__Service_Request__c)) {
            List<AgencyTeam__c> JointBuyerList = [ SELECT Id, Account__c,Account__r.AccountNumber__c, Account__r.PersonEmail,Account__r.Email__c, Account__r.name   FROM AgencyTeam__c WHERE ServiceRequest__c = : documentRecord[0].HexaBPM__Service_Request__c];
            if( JointBuyerList != null && JointBuyerList.size() > 0 ){
                for (AgencyTeam__c buyerObj : JointBuyerList ) {
                    String recipientKey = documentRecord[0].Id +''+ buyerObj.Account__c;
                    if(documentRecord[0].Name == 'PT Unified Digital SPA'){
                        recipientKey = buyerObj.Account__r.AccountNumber__c;
                    }
                    String recipientEmail = buyerObj.Account__r.PersonEmail != null ? buyerObj.Account__r.PersonEmail : buyerObj.Account__r.Email__c; // Recipient email
                    String primarySignHolder = buyerObj.Account__r.PersonEmail != null ? recipientKey+'SignatureHolder' : recipientKey+'OrgSignatureHolder'; 
                    String primaryDateHolder = buyerObj.Account__r.PersonEmail != null ? recipientKey+'DateHolder' : recipientKey+'OrgDateHolder'; 
                    String primaryInitialHolder = buyerObj.Account__r.PersonEmail != null ? recipientKey+'InitialsHolder' : recipientKey+'OrgInitialsHolder'; 
                    String primaryNameHolder = buyerObj.Account__r.PersonEmail != null ? recipientKey+'NameHolder' : recipientKey+'OrgNameHolder'; 
                    signers.add(new DocuSignAPIWrapper.SignerModel(buyerObj.Account__c,recipientEmail,buyerObj.Account__r.Name, primarySignHolder, signProvider,String.valueOf(routingOrder),String.valueOf(routingOrder),'Signer','',primaryNameHolder,primaryDateHolder,''));
                    routingOrder += 1;
                }
            }
        }
        if (eSignGroupList.contains(Constants.CUSTOMER_ESIGN) && documentRecord[0].HexaBPM__Service_Request__r.HexaBPM__Customer__c != null) {
            String recipientKey = documentRecord[0].Id + '' + documentRecord[0].HexaBPM__Service_Request__r.HexaBPM__Customer__c;
            if(documentRecord[0].Name == 'PT Unified Digital SPA'){
                recipientKey = documentRecord[0].HexaBPM__Service_Request__r.HexaBPM__Customer__r.AccountNumber__c;
            }
            String recipientEmail = documentRecord[0].HexaBPM__Service_Request__r.HexaBPM__Customer__r.PersonEmail != null ? documentRecord[0].HexaBPM__Service_Request__r.HexaBPM__Customer__r.PersonEmail : documentRecord[0].HexaBPM__Service_Request__r.HexaBPM__Customer__r.Email__c; // Recipient email
           	String primarySignHolder = documentRecord[0].HexaBPM__Service_Request__r.HexaBPM__Customer__r.PersonEmail!= null ? recipientKey+'SignatureHolder' : recipientKey+'OrgSignatureHolder'; 
            String primaryDateHolder = documentRecord[0].HexaBPM__Service_Request__r.HexaBPM__Customer__r.PersonEmail!= null ? recipientKey+'DateHolder' : recipientKey+'OrgDateHolder'; 
            String primaryInitialHolder = documentRecord[0].HexaBPM__Service_Request__r.HexaBPM__Customer__r.PersonEmail!= null ? recipientKey+'InitialsHolder' : recipientKey+'OrgInitialsHolder'; 
            String primaryNameHolder = documentRecord[0].HexaBPM__Service_Request__r.HexaBPM__Customer__r.PersonEmail!= null ? recipientKey+'NameHolder' : recipientKey+'OrgNameHolder'; 
            //String anchorString1 = relatedAccount.Id + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER;
            signers.add(new DocuSignAPIWrapper.SignerModel(documentRecord[0].HexaBPM__Service_Request__r.HexaBPM__Customer__c,recipientEmail,documentRecord[0].HexaBPM__Service_Request__r.HexaBPM__Customer__r.Name, primarySignHolder, signProvider,String.valueOf(routingOrder),String.valueOf(routingOrder),'Signer','',primaryNameHolder,primaryDateHolder,''));
            routingOrder += 1;
        }
        //Seller Joint owner
        if (eSignGroupList.contains(Constants.CUSTOMER_WITH_JOINT_OWNER_ESIGN) && String.isNotBlank(documentRecord[0].HexaBPM__Service_Request__c) && String.isNotBlank(documentRecord[0].HexaBPM__Service_Request__r.SalesOrder__c)) {
            List<JointOwner__c> JointSellerList = [ SELECT Id, Account__c, Account__r.AccountNumber__c, Account__r.PersonEmail,Account__r.Email__c, Account__r.name FROM JointOwner__c WHERE salesorder__c = : documentRecord[0].HexaBPM__Service_Request__r.SalesOrder__c];
            if( JointSellerList != null && JointSellerList.size() > 0 ){
                for (JointOwner__c sellerObj : JointSellerList ) {
                    String recipientKey = documentRecord[0].Id +''+ sellerObj.Account__c;
                    if(documentRecord[0].Name == 'PT Unified Digital SPA'){
                        recipientKey = sellerObj.Account__r.AccountNumber__c;
                    }
                    String recipientEmail = sellerObj.Account__r.PersonEmail != null ? sellerObj.Account__r.PersonEmail : sellerObj.Account__r.Email__c; // Recipient email
                    String primarySignHolder = sellerObj.Account__r.PersonEmail != null ? recipientKey+'SignatureHolder' : recipientKey+'OrgSignatureHolder'; 
                    String primaryDateHolder = sellerObj.Account__r.PersonEmail != null ? recipientKey+'DateHolder' : recipientKey+'OrgDateHolder'; 
                    String primaryInitialHolder = sellerObj.Account__r.PersonEmail != null ? recipientKey+'InitialsHolder' : recipientKey+'OrgInitialsHolder'; 
                    String primaryNameHolder = sellerObj.Account__r.PersonEmail != null ? recipientKey+'NameHolder' : recipientKey+'OrgNameHolder'; 
                    //String anchorString1 = relatedAccount.Id + CustomerAPIConstants.DOCUSIGN_SIGNATURE_HOLDER;
                    signers.add(new DocuSignAPIWrapper.SignerModel(sellerObj.Account__c,recipientEmail,sellerObj.Account__r.Name, primarySignHolder, signProvider,String.valueOf(routingOrder),String.valueOf(routingOrder),'Signer','',primaryNameHolder,primaryDateHolder,''));
                    routingOrder += 1;
                }
            }
        }
        if (eSignGroupList.contains(Constants.AUTHORISED_SIGNATORY_ESIGN)) {
            	routingOrder = 20;
                List<Aldarsignatory__mdt> aldarSign = [Select Id,email__c,Order__c,Type__c ,MasterLabel,DeveloperName,SigninggroupId__c,Signinggroupname__c FROM Aldarsignatory__mdt where active__c = true ORDER BY Order__c ];
                System.debug('inside aldarSign'+aldarSign);
                //ALDAR SIGN
                for(Aldarsignatory__mdt aSign : aldarSign){
                    System.debug('inside aSign'+aSign);
                    //String signProvider1 = (jo.ResidentStatus__pc != null && jo.ResidentStatus__pc == 'Resident') ? keyValueModel.uaepass : keyValueModel.idnow;
                    String recipientName = aSign.MasterLabel;
                    //Approver Signatory
                    if(aSign.Type__c == 'Approver'){
                        signers.add(new DocuSignAPIWrapper.SignerModel(null,aSign.email__c,aSign.DeveloperName,'Simple','',String.valueOf(routingOrder+1),String.valueOf(routingOrder+1),'Approver','SIGN_AT_DOCUSIGN','','',''));
                    }else if(aSign.Type__c == 'Signatory'){
                        String recipientEmail = aSign.email__c ;
                        signers.add(new DocuSignAPIWrapper.SignerModel(null,recipientEmail,aSign.DeveloperName,'AldarSignatureHolder','',String.valueOf(routingOrder+1),String.valueOf(routingOrder+1),'Signer','SIGN_AT_DOCUSIGN','AldarNameHolder','AldarDateHolder','Stamp'));
                    }
                    //keyValueModel.idnow
                    String joRole = 'AldarUAEPassSign';
                    routingOrder++;

        		}
                System.debug('All signatories Added to the Envelope');
            
        }
		recipientModel.signers = signers;
        envelopeRequestModel.recipients = recipientModel;
        System.debug('Chirag'+envelopeRequestModel);
        envelopeRequestModel.status = CustomerAPIConstants.DOCUSIGN_STATUS_SENT;
        String envelopeId;
        if(relatedSignDocument!=null && relatedSignDocument.Docusign_Envelope_Id__c != null){
			envelopeId = relatedSignDocument.Docusign_Envelope_Id__c;
        }else{
            envelopeId =  DocusignForMOUListing.callAPI(docuSignEnvelope, authToken, '', org.IsSandbox, 'Envelope', JSON.serialize(envelopeRequestModel));
        }
        System.debug('envelopeId --> '+envelopeId);
        APISetting__mdt docuSignURL = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_URL);
        docuSignDocumentURL = DocusignForMOUListing.callAPI(docuSignURL, authToken, envelopeId, org.IsSandbox, 'DosuSignURL', JSON.serialize(new URLRequestModel(returnURL, account)));
        system.debug('docuSignDocumentURL-->'+docuSignDocumentURL);
        List<dfsle__EnvelopeStatus__c> existingEnvelop = [Select id,name,dfsle__DocuSignId__c from dfsle__EnvelopeStatus__c where dfsle__DocuSignId__c =:envelopeId];
        if(envelopeId != null && envelopeId != '' && existingEnvelop.size() == 0){
                update new List<HexaBPM__SR_Doc__c>{ new HexaBPM__SR_Doc__c(id=relatedSignDocument.Id, Docusign_Envelope_Id__c=envelopeId)};
                    
                dfsle__EnvelopeStatus__c envelopeStatus = new dfsle__EnvelopeStatus__c();
                envelopeStatus.dfsle__DocuSignId__c   = envelopeId;
                envelopeStatus.dfsle__SenderName__c   = UserInfo.getUserName(); // Need to know where it is configured
                envelopeStatus.dfsle__SenderEmail__c  = UserInfo.getUserEmail(); // Need to know where it is configured
                envelopeStatus.dfsle__EmailSubject__c = Label.DOCUSIGN_EmailSubject +' '+documentRecord[0].HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name;
                envelopeStatus.dfsle__Status__c       = CustomerAPIConstants.DOCUSIGN_STATUS_SENT;
                envelopeStatus.dfsle__Sent__c         = system.now();
                envelopeStatus.CreatedFromAPI__c      = true;
                envelopeStatus.dfsle__SourceId__c = documentRecord[0].Id;
                //envelopeStatus.Communication_Preference__c = CpId;
                envelopeStatus.SR_Doc__c = documentRecord[0].Id;
                insert envelopeStatus;
                List<dfsle__RecipientStatus__c> recipientStatusList = new List<dfsle__RecipientStatus__c>();
                                
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
                    recipientStatus.dfsle__Sent__c = System.now();
                    recipientStatusList.add(recipientStatus);
                }
                if(!recipientStatusList.isEmpty()){
                    insert recipientStatusList;
                }
        }
        return docuSignDocumentURL;
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
        public String errorCode                     {get;set;} 
        public String message                       {get;set;}
    }


}