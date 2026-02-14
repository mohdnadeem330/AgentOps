public class ECSS_SMSIntegration {
    
    @InvocableMethod
    public static void sendMsg(List<RequestData> requestList)
    {
        RequestData rData = requestList[0];
        String reqSerialized = JSON.Serialize(rData);
        ECSS_SMSIntegration.sendMsgCallOut(reqSerialized); 
        //RequestData requestData = (RequestData) JSON.deserialize(reqSerialized,RequestData.class);
        //system.debug(requestData);
        
    }
    
    @future(callout=true)
    public static void sendMsgCallOut(String reqSeri)
    {   
        RequestData requestData = (RequestData) JSON.deserialize(reqSeri,RequestData.class);
        String message = requestData.message;
        Boolean isArabic = requestData.isArabic;
        //String message = 'testmmssg';
        ECSS_SMS_Configuration__mdt smsMtd = requestData.smsMtd;
        List<String>mobilePhones = new List<String>();
        mobilePhones.addAll(requestData.mobilePhones);
        system.debug('Message'+message);
        
        string outcomeMsg='';
        if (Limits.getCallouts() >= Limits.getLimitCallouts()) {
            outcomeMsg = 'Maximum number of callouts has been reached.';
            
        } 
        else if (smsMtd.EndPoint__c == null || smsMtd.Username__c == null || smsMtd.Password__c == null) {
            outcomeMsg = 'Please verify your API Credentials';
            
        } 
        else {
            HttpRequest req = new HttpRequest();
            Http h = new Http();
            HttpResponse res = new HttpResponse();
            
            String mobileNumber = '';
            for(String mobile : mobilePhones)
            {
                mobileNumber+=mobile+',';
            }
            mobileNumber = mobileNumber.substring(0, mobileNumber.length() - 1);
            String fullUrl = smsMtd.EndPoint__c + 'User=' + smsMtd.Username__c + '&passwd=' + smsMtd.Password__c + '&mobilenumber=' + mobilenumber + '&message=' + EncodingUtil.urlEncode(message, 'UTF-8') + '&sid=' + smsMtd.SID__c + '&mtype=' + smsMtd.MType__c + '&DR=' + smsMtd.DR__c;
             if(isArabic){
                 System.debug('entere here:arabic');
                 //message = message.replace(' ', '%20');
                 fullUrl = smsMtd.EndPoint__c + 'User=' + smsMtd.Username__c + '&passwd=' + smsMtd.Password__c + '&mobilenumber=' + mobilenumber + '&message=' +  EncodingUtil.urlEncode(message, 'UTF-8') + '&sid=' + smsMtd.SID__c + '&mtype=' + 'LNG' + '&DR=' + smsMtd.DR__c;
             }
            // Configure the request
            req.setEndpoint(fullUrl);
            req.setMethod(smsMtd.Method__c); 
            req.setTimeout(120000);
            System.debug('Entered now');
            try{
                res = h.send(req);
                outcomeMsg = res.getBody();
            }
            catch (System.CalloutException e) {
                // Handle any callout exceptions (e.g., connectivity issues, timeout, etc.)
                outcomeMsg = 'Callout Exception: ' + e.getMessage();
            } 
            catch (Exception e) {
                outcomeMsg = 'Exception: '+e.getMessage();
            }
            
            system.debug('OUTCOME'+outcomeMsg);
        }
     
    }
    public class RequestData {
            @InvocableVariable
            public ECSS_SMS_Configuration__mdt smsMtd;
            
            @InvocableVariable
            public List<String>mobilePhones;
            
            @InvocableVariable
            public String message;
        
        	@InvocableVariable
        	public Boolean isArabic;
    }
}