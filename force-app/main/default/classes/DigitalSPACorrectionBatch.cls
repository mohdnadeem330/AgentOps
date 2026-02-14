global class DigitalSPACorrectionBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    private String soqlString;
    private String EmailId;
    Private String EnvelopeEndpoint;
    Private String DeleteEndPoint;
    
    global DigitalSPACorrectionBatch(String soqlString,String EmailId,String EnvelopeEndpoint,String DeleteEndPoint ) {
        this.soqlString = soqlString;
        this.EmailId = EmailId;
        this.EnvelopeEndpoint = EnvelopeEndpoint;
        this.DeleteEndPoint = DeleteEndPoint;
        
    }
    
    // Start method to query the Leads with offset
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(soqlString != null){
            return Database.getQueryLocator(soqlString);
        }else{
            return null;
        }
    }
    
    // Execute method to process each Lead
    global void execute(Database.BatchableContext bc, List<dfsle__EnvelopeStatus__c> scope) {
        try{
            String docusignenvId ='';
            for(dfsle__EnvelopeStatus__c envp :scope){
                //for(dfsle__RecipientStatus__c rep : envp.dfsle__Recipients__r){
                //    if(rep.dfsle__RoutingOrder__c ==23 && rep.dfsle__Status__c !='Completed'){
                        docusignenvId = envp.dfsle__DocuSignId__c;
                     //   break;
                   // }
               // }
            }
            if(docusignenvId !=''){
                String envelopeId = docusignenvId; 
                String  recipientEmail = EmailId;
                Organization org = Utilities.getOrganizationDetails();
                APISetting__mdt docuSignAuthentication = Utilities.getServiceDetails(CustomerAPIConstants.DOCUSIGN_AUTHENTICATION);
                String pvtKey = Utilities.getConstant(CustomerAPIConstants.DOCUSIGN_PRIVATE_KEY).ConstantValueLong__c;
                String jwtoken = JWTToken.issueToken(docuSignAuthentication, org.IsSandbox, pvtKey);
                String authToken = DocusignForMOUListing.callAPI(docuSignAuthentication, '', '', org.IsSandbox, 'Authentication', JSON.serialize(new DocuSignAPIWrapper.AuthenticationRequestModel(CustomerAPIConstants.GRANT_TYPE, jwtoken)));
                APISetting__mdt apiSetting =  Utilities.getServiceDetails('DocuSignEnvelope');
                /*String endPointURL =EnvelopeEndpoint;//'https://eu.docusign.net/restapi/v2.1/accounts/{{accountId}}/envelopes/{{envelopeId}}/recipients/{{recipientId}}';
                endPointURL = endPointURL.replace('{{accountId}}', apiSetting.APIKey__c);
                endPointURL = endPointURL.replace('{{envelopeId}}',envelopeId);
                endPointURL = endPointURL.replace('{{recipientId}}', '23');
                DocuSignAPIWrapper.EnvelopeRequestModel envelopeRequestModel = new DocuSignAPIWrapper.EnvelopeRequestModel();
                
                
                DocuSignAPIWrapper.RecipientModel recipientModel = new DocuSignAPIWrapper.RecipientModel();
                List<DocuSignAPIWrapper.SignerModel> signers = new List<DocuSignAPIWrapper.SignerModel>();
                signers.add(new DocuSignAPIWrapper.SignerModel(null,recipientEmail,'AldarUAEPassSign','AldarSignatureHolder','','24','24','Signer','SIGN_AT_DOCUSIGN','AldarNameHolder','AldarDateHolder','Stamp'));
                recipientModel.signers = signers;
                envelopeRequestModel.recipients = recipientModel;
                System.debug('Chirag'+envelopeRequestModel);
                envelopeRequestModel.status = CustomerAPIConstants.DOCUSIGN_STATUS_SENT;*/
                String jsonbody = '{"useAccountDefaults": "true"}';
                String endpoint =DeleteEndPoint; //'https://eu.docusign.net/restapi/v2.1/accounts/{{accountId}}/envelopes/{{envelopeId}}?resend_envelope=true';
                endpoint = endpoint.replace('{{accountId}}', apiSetting.APIKey__c);
                endpoint = endpoint.replace('{{envelopeId}}',envelopeId);
                Http http1 = new Http();
                HttpRequest request1 = new HttpRequest();
                request1.setHeader('Content-Type', 'application/json');
                if (String.isNotBlank(authToken)) {
                    request1.setHeader('Authorization', 'Bearer ' + authToken);
                }
                request1.setTimeout(120000);
                request1.setEndpoint(endpoint);
                request1.setMethod('PUT');
                System.debug(JSON.serialize(jsonbody));
                request1.setBody(jsonbody);
                HttpResponse response1 = http1.send(request1);
                String docuSignRes1 = response1.getBody();
                System.debug(docuSignRes1);
                
                /*Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setHeader('Content-Type', 'application/json');
                if (String.isNotBlank(authToken)) {
                    request.setHeader('Authorization', 'Bearer ' + authToken);
                }
                request.setTimeout(120000);
                request.setEndpoint(endPointURL);
                request.setMethod('DELETE');
                HttpResponse response = http.send(request);
                String docuSignRes = response.getBody();
                System.debug(docuSignRes);*/
            }
        }catch(Exception ex){
            LoggerService.save(LoggerService.addApexLog(ex,'DigitalSPACorrectionBatch','DigitalSPACorrectionBatch',scope[0].dfsle__DocuSignId__c));
        }
          
    }
    
    // Finish method (optional) to execute post-processing logic
    global void finish(Database.BatchableContext bc) {
        // Optionally, perform any post-processing tasks
    }
}