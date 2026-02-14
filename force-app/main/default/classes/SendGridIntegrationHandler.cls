/**********************************************************************************************************************
* Name               : SendGridIntegrationHandler                                                        
* Description        : Handler Class for the Payment Reminder Emails via SendGrid's REST API
* Created By         : Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     15/09/2023      Initial Draft       
******************************************************************************************************************/
public with sharing class SendGridIntegrationHandler {

    /**
     * Take request body from the Queueable Class SendGridCalloutQueueable and make a REST API callout to SendGrid
     */
    public static void doCallout (Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap){

        if(requestWrapperMap == null){
            return;
        }

        //******UNTIL THIS POINT, CODE IS BULKIFIED, ONCE THE API IS BULKIFIED, THE STRUCTURE WILL CHANGE******

        SendGridWrappers.PaymentMilestoneEmailWrapper requestWrapper = requestWrapperMap.values()[0];

        //LOGGING DATA
        Id recordId = new List<Id>(requestWrapperMap.keySet())[0];
        //Used for rollbacks in case of handover emails
        Set<String> projectHandoverPhasingTypes = new Set<String>{'tpl_ho1_1','tpl_ho4','tpl_ho2_3','tpl_ho2'};
        String processName = 'Send Grid API Callout';

        Map<String, String> configMapGlobal = SendGridIntegrationUtilities.getConfigMap_TypeToProcessName();
        processName = configMapGlobal.get(requestWrapper.type);
        
        //supressNulls parameter true
        String requestBodyJson = JSON.serialize(requestWrapper, true);

        //GET HEADER MAP AND ENDPOINT FROM CONFIGURATION
        APISetting__mdt  sendGridAPI = Utilities.getServiceDetails(SendGridIntegrationUtilities.SENDGRID_PAYMENT_REMINDER);
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = sendGridAPI.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = sendGridAPI.ProductionURL__c ; 
        }
        Map<String,String> headersMap = (Map<String,String>)JSON.deserialize(sendGridAPI.Headers__c, Map<String,String>.class);

        // Create an HTTP request
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPointURL);
        request.setMethod(sendGridAPI.Method__c);
        for(String headerName : headersMap.keySet()){
            request.setHeader(headerName, headersMap.get(headerName));
        }
        request.setBody(requestBodyJson);
        request.setTimeout(120000);
        
        system.debug('####request: '+requestBodyJson);

        // Create an HTTP instance to send the request
        Http http = new Http();
        HttpResponse response;

        try{
            response = http.send(request);
            // Process the response as needed
            List<Integer> successStatusCodesList = new List<Integer>{200, 201, 202};
            if (successStatusCodesList.contains(response.getStatusCode())) {
                // Request was successful
                //Harsh 03/11
                SendGridWrappers.SuccessResponse successWrapper = (SendGridWrappers.SuccessResponse) System.JSON.deserialize(response.getBody(), SendGridWrappers.SuccessResponse.class);
                String responseHTML = String.valueOf(successWrapper.Data.versions[0].html_content).length() < 131072 ? String.valueOf(successWrapper.Data.versions[0].html_content) : String.valueOf(successWrapper.Data.versions[0].html_content).abbreviate(131072);
                String plainContent = String.valueOf(successWrapper.Data.versions[0].plain_content).length() < 32000 ? String.valueOf(successWrapper.Data.versions[0].plain_content) : String.valueOf(successWrapper.Data.versions[0].plain_content).abbreviate(32000);

                Logger__c log = LoggerService.logSuccessResponse(processName, 'SendGridIntegrationHandler', 'doCallout', requestBodyJson.abbreviate(131070), response.getBody().abbreviate(131070), recordId);
                log.StatusCode__c = response.getStatusCode();
                insert log;

                createActivity(recordId, plainContent, responseHTML, requestWrapper.cc, requestWrapper.bcc, processName);
                //Reset failure reason on SRDoc for Handover Emails
                if(projectHandoverPhasingTypes.contains(requestWrapper.type)){
                    SendGridIntegrationUtilities.resetFailureReasonOnSRDoc(recordId);
                }
            } else {
                // Request failed
                //parse the error
                if(response.getBody() != null && response.getBody() != ''){
                    SendGridWrappers.ErrorWrapper errorWrapper = (SendGridWrappers.ErrorWrapper) System.JSON.deserialize(response.getBody(), SendGridWrappers.ErrorWrapper.class);
                    Logger__c log = LoggerService.addApexServiceCalls(processName, 'SendGridIntegrationHandler', 'doCallout', requestBodyJson?.abbreviate(131070), response.getBody()?.abbreviate(131070), recordId);
                    log.StatusCode__c = response.getStatusCode();
                    insert log;

                    String errorMessage = '';
                    try {
                        List<List<String>> messages = errorWrapper.error.details.message;
                        for(List<String> messageList : messages) {
                            for(String msg : messageList) {
                                errorMessage += msg + '\n';
                            }
                        }
                    } catch (Exception e) {
                        errorMessage = String.valueOf(response.getBody());
                    }

                    //handle Failures for Handover Phasing Letter
                    if(projectHandoverPhasingTypes.contains(requestWrapper.type)){
                        SendGridIntegrationUtilities.updateFailureReason_Handover(recordId, errorMessage.abbreviate(131070), requestWrapper.type);
                    }
                }else{
                    Logger__c log = LoggerService.addApexServiceCalls(processName, 'SendGridIntegrationHandler', 'doCallout', requestBodyJson.abbreviate(131070), null, recordId);
                    log.StatusCode__c = response.getStatusCode();
                    insert log;

                    //handle Failures for Handover Phasing Letter
                    if(projectHandoverPhasingTypes.contains(requestWrapper.type)){
                        SendGridIntegrationUtilities.updateFailureReason_Handover(recordId, '', requestWrapper.type);
                    }
                }
            }
        }catch(Exception e){
            System.debug('#### LOGGER + '+e);
            Logger__c log = LoggerService.createApexLog(e, '', processName, 'SendGridIntegrationHandler.doCallout');
            log.Message__c = requestBodyJson;
            log.ResponseMessage__c = response != null && response.getBody() != null ? response.getBody().abbreviate(131070) : null;
            if (recordId.getSObjectType() == HexaBPM__Service_Request__c.SObjectType) {
                log.ServiceRequest__c = recordId;
            }else if(recordId.getSObjectType() == Document__c.SObjectType){
                log.Document__c = recordId;
            }else if (recordId.getSObjectType() == HexaBPM__SR_Doc__c.SObjectType) {
                log.SR_Doc__c = recordId;
            }else if (recordId.getSObjectType() == Account.SObjectType) {
                log.Account__c = recordId;
            }
            log = LoggerService.saveAndReturnLogger(log);
            upsert log;
        }
    }

    public static void createActivity(Id recordId, String response, String htmlBody, String ccString, String bccString, String emailType){
        String docId = '';
        String contactAddress = '';

        if(recordId.getSObjectType() == Document__c.SObjectType){
            List<Document__c> docList = [SELECT Id, InstallmentLine__r.SalesOrder__r.Account__c, InstallmentLine__r.SalesOrder__r.Account__r.IsPersonAccount, InstallmentLine__r.SalesOrder__r.Account__r.PersonContactId, InstallmentLine__r.SalesOrder__r.Contact__c  FROM Document__c WHERE Id =: recordId LIMIT 1];
            if(docList.size() > 0){
                docId = docList[0].Id;
                
                if(docList[0].InstallmentLine__r.SalesOrder__r.Account__c != null){
                    if(docList[0].InstallmentLine__r.SalesOrder__r.Account__r.IsPersonAccount){
                        contactAddress = docList[0].InstallmentLine__r.SalesOrder__r.Account__r.PersonContactId;
                    }
                    else if(docList[0].InstallmentLine__r.SalesOrder__r.Contact__c != null){
                        contactAddress = docList[0].InstallmentLine__r.SalesOrder__r.Contact__c;
                    }
                }       
                createEmailMessage(emailType, response, htmlBody, docId, bccString, ccString, contactAddress);
            }
        }else if(recordId.getSObjectType() == HexaBPM__Service_Request__c.SObjectType){
            List<HexaBPM__Service_Request__c> srList = [SELECT Id, SalesOrder__r.Account__c, SalesOrder__r.Account__r.IsPersonAccount, SalesOrder__r.Account__r.PersonContactId, SalesOrder__r.Contact__c, SalesOrder__r.Unit__r.Name  FROM HexaBPM__Service_Request__c WHERE Id =: recordId LIMIT 1];
            if(srList.size() > 0){
                String srId = srList[0].Id;
                
                if(srList[0].SalesOrder__r.Account__c != null){
                    if(srList[0].SalesOrder__r.Account__r.IsPersonAccount){
                        contactAddress = srList[0].SalesOrder__r.Account__r.PersonContactId;
                    }
                    else if(srList[0].SalesOrder__r.Contact__c != null){
                        contactAddress = srList[0].SalesOrder__r.Contact__c;
                    }
                }        
                createEmailMessage(emailType +' - '+ srList[0].SalesOrder__r.Unit__r.Name, response, htmlBody, srId, bccString, ccString, contactAddress);
            }
        }else if(recordId.getSObjectType() == HexaBPM__SR_Doc__c.SObjectType){
            List<HexaBPM__SR_Doc__c> srDocList = [SELECT Id, HexaBPM__Service_Request__r.SalesOrder__r.Account__c, HexaBPM__Service_Request__r.SalesOrder__r.Account__r.IsPersonAccount, HexaBPM__Service_Request__r.SalesOrder__r.Account__r.PersonContactId, HexaBPM__Service_Request__r.SalesOrder__r.Contact__c, HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name, HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.Name FROM HexaBPM__SR_Doc__c WHERE Id =: recordId LIMIT 1];
            if(srDocList.size() > 0){
                String srDocId = srDocList[0].Id;
                
                if(srDocList[0].HexaBPM__Service_Request__r.SalesOrder__r.Account__c != null){
                    if(srDocList[0].HexaBPM__Service_Request__r.SalesOrder__r.Account__r.IsPersonAccount){
                        contactAddress = srDocList[0].HexaBPM__Service_Request__r.SalesOrder__r.Account__r.PersonContactId;
                    }
                    else if(srDocList[0].HexaBPM__Service_Request__r.SalesOrder__r.Contact__c != null){
                        contactAddress = srDocList[0].HexaBPM__Service_Request__r.SalesOrder__r.Contact__c;
                    }
                }        
                createEmailMessage(srDocList[0].HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.Name +' '+emailType +' - '+ srDocList[0].HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name, response, htmlBody, srDocId, bccString, ccString, contactAddress);
            }
        }else if(recordId.getSObjectType() == Account.SObjectType){

            List<Account> accList = [SELECT Id, PersonContactId 
                                    FROM Account 
                                    WHERE Id =: recordId 
                                    ];
            contactAddress = accList[0].PersonContactId;
            createEmailMessage(emailType, response, htmlBody, recordId, bccString, ccString, contactAddress);
        }
    }

    private static void createEmailMessage(String subject, String textBody, String htmlBody, String relatedToId, String bccString, String ccString, String contactAddress){
        // Create a new Email record
        EmailMessage email = new EmailMessage();
        email.Subject = subject;
        email.TextBody = textBody;
        email.htmlBody = htmlBody;
        email.RelatedToId = relatedToId; // Relate the Email to the sr record
        email.Incoming = false;
        email.Status = '3';
        email.BccAddress = bccString;
        email.CcAddress = ccString;
        // email.FromAddress = fromAddress;

        // Insert the Email record to create a new Email activity
        insert email;

        insert SendGridIntegrationUtilities.createEmailMessageRelation(email.ToAddress, email.Id, contactAddress);
    }
}