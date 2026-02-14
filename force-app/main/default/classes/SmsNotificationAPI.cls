global class SmsNotificationAPI {

    @InvocableMethod
    global static void sendSmsNotification(SmsRequest[] requests) {
        //EmailTemplate emailTemplate = Utilities.getEmailTemplate(requests[0].smsTemplateName);
        //String smsText = 'Dear '+ requests[0].firstName+' '+requests[0].lastName + ',\nThank you for your customer registered in Aldar properties. Your reference Lead Number is '+ requests[0].leadNumber + ' our Sales executive will be contacting you shortly. For further assistance, please do not hesitate to contact us on 800-25327. ';
        //SystemMessages__mdt messageDetails = Utilities.getSystemMessages(requests[0].smsBody);

        APISetting__mdt  smsAPI = Utilities.getServiceDetails(Constants.SMS);
        Organization org = Utilities.getOrganizationDetails();
           
        String endPointURL = smsAPI.SandboxURL__c ;
           
        if(!org.IsSandbox){
            endPointURL = smsAPI.ProductionURL__c ; 
        }
   
        String username = smsAPI.username__c;
        String apiId = smsAPI.apiId__c;
        String source = smsAPI.source__c;
        String method = smsAPI.Method__c;
           
        try{  
            for (SmsRequest smsRequest : requests) {
                smsRequest.destination = smsRequest.destination.replaceAll('(\\s+)', '').replace('+','');
                if (System.isBatch() || System.isFuture()) {
                    nonFutureCallout(smsRequest.smsBody, smsRequest.destination, (String)smsRequest.record.get('Id'), (String)smsRequest.record.get('OwnerId'), endPointURL, username, apiId, source, method);
                } else{
                    callout(smsRequest.smsBody, smsRequest.destination, (String)smsRequest.record.get('Id'), (String)smsRequest.record.get('OwnerId'), endPointURL, username, apiId, source, method);
                }
            }
            
        } catch(Exception e){
            LoggerService.save(LoggerService.addApexLog(e,'sendSmsNotification','SmsNotificationAPI',''));
            system.debug(e);
        }
            
        //return new List<boolean> {true};
       }
    

       @future(callout = true)
       public static void callout(string smsText,String destination, String recordId, String ownerId, String endPointURL, String username, String apiId, String source, String method){
           
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        String reqBody = endPointURL+'username='+username+'&apiId='+apiId+'&json=True'+'&destination='+destination+'&source='+source+'&text='+EncodingUtil.urlEncode(smsText,'UTF-8');
           
        request.setEndpoint(reqBody);
        request.setMethod(method);
           
        HttpResponse response = http.send(request);
                   
        JSONParser parser = JSON.createParser(response.getBody());
           
        String errorCode='';
        String description='';
        boolean isValid = false;
   
                   
        while(parser.nextToken() != null){
   
            if(Constants.ERROR_CODE.equals(parser.getText())){

                parser.nextToken();
                errorCode = parser.getText();
                   
                if('0'.equalsIgnoreCase(errorCode)){
                    isValid = true;

                    Id recId = Id.valueOf(recordId);
                    Schema.SObjectType sobjectType = recId.getSObjectType();
                    string sobjectName = sobjectType.getDescribe().getName();

                    
                    
                    Task tsk = new Task();
                    tsk.Subject = Constants.SMS_NOTIFICATION_WAS_SENT;
                    tsk.Status = Constants.COMPLETED;
                    tsk.Priority = Constants.NORMAL;
                    if(sobjectName == 'Lead'){
                        tsk.WhoId = recordId;
                    } else if(sobjectName == 'Opportunity'){
                        tsk.WhatId = recordId;
                    } else {
                        break;
                    }
                    tsk.OwnerId = ownerId;
                    tsk.Description = smsText;
                    tsk.ActivityDate = Date.today();
                    insert tsk;
                    
                    break;
                }
            }
        }
        if(!isValid){
            LoggerService.save(LoggerService.addApexServiceCalls('sendSmsNotification','SmsNotificationAPI','callout',reqBody,response.getBody(),recordId));
        }
    }

       public static void nonFutureCallout(string smsText,String destination, String recordId, String ownerId, String endPointURL, String username, String apiId, String source, String method){
           
           Http http = new Http();
           HttpRequest request = new HttpRequest();

           String reqBody = endPointURL+'username='+username+'&apiId='+apiId+'&json=True'+'&destination='+destination+'&source='+source+'&text='+EncodingUtil.urlEncode(smsText,'UTF-8');
           
           request.setEndpoint(reqBody);
           request.setMethod(method);
           
           HttpResponse response = http.send(request);
                   
           JSONParser parser = JSON.createParser(response.getBody());
           
           String errorCode='';
           String description='';
           boolean isValid = false;
   
                   
           while(parser.nextToken() != null){
   
               if(Constants.ERROR_CODE.equals(parser.getText())){
                   
                   parser.nextToken();
                   errorCode = parser.getText();
                   
                   if('0'.equalsIgnoreCase(errorCode)){
                    isValid = true;

                    Id recId = Id.valueOf(recordId);
                    Schema.SObjectType sobjectType = recId.getSObjectType();
                    string sobjectName = sobjectType.getDescribe().getName();

                    
                    
                    Task tsk = new Task();
                    tsk.Subject = Constants.SMS_NOTIFICATION_WAS_SENT;
                    tsk.Status = Constants.COMPLETED;
                    tsk.Priority = Constants.NORMAL;
                    if(sobjectName == 'Lead'){
                        tsk.WhoId = recordId;
                    } else if(sobjectName == 'Opportunity'){
                        tsk.WhatId = recordId;
                    } else {
                        break;
                    }
                    tsk.OwnerId = ownerId;
                    tsk.Description = smsText;
                    tsk.ActivityDate = Date.today();
                    insert tsk;
                    
                    break;
                }
               }
           }
           if(!isValid){
                LoggerService.save(LoggerService.addApexServiceCalls('sendSmsNotification','SmsNotificationAPI','callout',reqBody,response.getBody(),recordId));
           }
       }
       
       global class SmsRequest {
           @InvocableVariable(required=true)
           global String destination;

           @InvocableVariable(required=true)
           global String smsBody;
           
           @InvocableVariable(required=true)
           global SObject record; 
       }
   }