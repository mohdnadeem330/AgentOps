public with sharing class SMSUtility {

    public static SMSMessages__mdt getMesssageDetails(string messageName){
        try{
            SMSMessages__mdt messageDetails = [SELECT DEVELOPERNAME, Destination__c, MessageText__c, ObjectName__c
                                              FROM SMSMessages__mdt
                                              WHERE DEVELOPERNAME =: messageName];
            return messageDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    public static String getMergeFields(String messageText, String destination){
        pattern p = pattern.compile('\\{!(.*?)\\}');
        Matcher m = p.matcher(messageText);

        List<String> mergeFields = new List<String>();

        if(String.isNotBlank(destination)){
            mergeFields.add(destination);
        }

        while(m.find()) {
            String fieldName = m.group().substring( 2, m.group().length() - 1);
            if(!mergeFields.contains(fieldName)){
                mergeFields.add(fieldName);
            }
        }

        return String.join(mergeFields,',');
    }

    public static List<SObject> getRecordDetails(Set<Id> recordsIds, String objectName, String fields){
        System.debug('fields '+fields);
        System.debug('objectName '+objectName);
        String query = 'SELECT Id,' + fields + ' FROM '+objectName+' WHERE Id In : recordsIds ';
        System.debug('query: '+query);
        List<SObject> records = Database.Query(query);
        
        return records;
    }

    public static List<SMSModel> renderMergeFields(String messageText, List<SObject> records, String destination){
        pattern p = pattern.compile('\\{!(.*?)\\}');
        Matcher m = p.matcher(messageText);

        List<SMSModel> smsList = new List<SMSModel>();
        for (SObject record : records) {

            SMSModel sms = new SMSModel();
            String smsText = messageText;

            Map<String,Object> recordMap = record.getPopulatedFieldsAsMap();
            System.debug('recordMap: '+recordMap);

            while(m.find()) {
                String fieldName = m.group().substring( 2, m.group().length() - 1);
                String subName = '';
                SObject subRecord = null;

                if(fieldName.contains('.')){
                    subRecord = (SObject)recordMap.get(fieldName.split('\\.')[0]);
                    subName = fieldName.split('\\.')[1];
                }
                smsText = smsText.replace(m.group(),(subRecord == null ? record.get(fieldName).toString() : subRecord.get(subName).toString()));
            }
            sms.smsMessage = smsText;
            sms.recordId = record.Id;

            if(destination.contains('.')){
                SObject subRecord = (SObject)recordMap.get(destination.split('\\.')[0]);
                sms.destination = subRecord.get(destination.split('\\.')[1]).toString();
            } else{
                sms.destination = record.get(destination).toString();
            }
            smsList.add(sms);
        }

        return smsList;
    }

    public static List<SMSModel> prepareSMS(String smsMessageName, Set<Id> recordsIds){
        
        SMSMessages__mdt messageDetails = SMSUtility.getMesssageDetails(smsMessageName);
        APISetting__mdt  smsAPISetting = Utilities.getServiceDetails(Constants.SMS);
        
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = smsAPISetting.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = smsAPISetting.ProductionURL__c ; 
        }

        String mergeFields = SMSUtility.getMergeFields(messageDetails.MessageText__c, messageDetails.Destination__c);
        List<SObject> records = SMSUtility.getRecordDetails(recordsIds, messageDetails.ObjectName__c, mergeFields);
        System.debug('records: '+records);

        List<SMSModel> smsList = SMSUtility.renderMergeFields(messageDetails.MessageText__c, records, messageDetails.Destination__c);
	System.debug('smslist '+smsList);
        return smsList;
    }

    public static void sendSMS(List<SMSModel> smsList){
        
        APISetting__mdt  smsAPISetting = Utilities.getServiceDetails(Constants.SMS);
        
        //----- Serialize JSON wrapper
        String smsApiSettingJson = json.serialize(smsAPISetting);

        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = smsAPISetting.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = smsAPISetting.ProductionURL__c ; 
        }

        for (SMSModel sms : smsList) {
            String smsJson = json.serialize(sms);
            smsCallout(smsJson, smsApiSettingJson, endPointURL);
        }

    }
    
    @future(callout = true)
    public static void smsCallout(String smsJson, String smsApiSettingJson, String endPointURL){
        //String endPointURL, String username, String apiId, String source, String method

        //----- Deserialize to object
        SMSModel sms = (SMSModel)json.deserialize(smsJson,SMSModel.Class);
        APISetting__mdt  smsAPISetting = (APISetting__mdt)json.deserialize(smsApiSettingJson,APISetting__mdt.Class);

        Http http = new Http();
        HttpRequest request = new HttpRequest();

        String reqBody = endPointURL+'username='+smsAPISetting.username__c+'&apiId='+smsAPISetting.apiId__c+'&json=True'+'&destination='+sms.destination+'&source='+smsAPISetting.source__c+'&text='+EncodingUtil.urlEncode(sms.smsMessage,'UTF-8');
           
        request.setEndpoint(reqBody);
        request.setMethod(smsAPISetting.Method__c);
       HttpResponse response = new HttpResponse();
        if(!Test.isRunningTest())
            response = http.send(request);
        else{
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"ErrorCode":0,"Description":"Success","Id":"20720af4-10c0-4c7e-a14d-7b4f1abfc1bf","OriginatingAddress":"ALDAR","DestinationAddress":"971547934361","MessageCount":4}');
            response.setStatusCode(200);            
        }
        
        
      
        System.debug('response '+response);
        JSONParser parser = JSON.createParser(response.getBody());
        System.debug('parser '+parser);
        System.debug('sms.smsMessage: '+sms.smsMessage);
        System.debug('response.getBody(): '+response.getBody());

        String errorCode='';
        String description='';
        boolean isValid = false;
   
                   
        while(parser.nextToken() != null){
   
            if(Constants.ERROR_CODE.equals(parser.getText())){

                parser.nextToken();
                errorCode = parser.getText();
                   
                if('0'.equalsIgnoreCase(errorCode)){
                    isValid = true;
                    break;
                }
            }
        }
        if(!isValid){
            LoggerService.save(LoggerService.addApexServiceCalls('sendSmsNotification','SmsNotificationAPI','callout',reqBody,response.getBody(),sms.recordId != null ? sms.recordId : null));
        }

    }

}