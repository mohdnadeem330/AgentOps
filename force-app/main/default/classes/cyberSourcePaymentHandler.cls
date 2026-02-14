/*Class     : cyberSourcePaymentHandler
Author      : Smaartt
Description : This class is accessed from public site and process the payment in cybersource gateway and capture the response and update back to the salesforce payment Request obj.
TestClass   : cyberSourcePaymentHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              23/04/24           Initial Version 
****************************************************************************************************************/
public without sharing class cyberSourcePaymentHandler {
    public Map<String,String> parametersToSign = new Map<String,String>();
    public String signature;
    public String signedFieldNames = 'access_key,profile_id,transaction_uuid,signed_field_names,unsigned_field_names,signed_date_time,locale,transaction_type,reference_number,amount,currency,payment_method,bill_to_address_city,bill_to_address_country,bill_to_address_line1,bill_to_address_line2,bill_to_address_postal_code,bill_to_address_state,bill_to_email,bill_to_forename,bill_to_phone,bill_to_surname';
    private String accesskey;
    private string outletRefId;//'78A21E32-2DE3-43DE-974F-41B730AA1F64';
    private static string secretkey;
    public String version {get; set;}
    public string resp {get; set;}
    public static String reasonCode {get; set;}
    public static String endPointUrl {get; set;}
    public static String paymentId;
    public static string transcationId {get;set;}
    public Payment_Request__c paymntReq;  
    public String recId {get; set;}
    public string transactionUUID {get; set;}
    public string amount {get; set;}
    public string city {get; set;}
    public string country {get; set;}
    public string postalCode {get; set;}
    public string state {get; set;}
    public string email {get; set;}
    public string firstName {get; set;}
    public string mobilePhone {get; set;}
    public string lastName {get; set;}
    public string street {get; set;}
    public String TermsAndConditions {get; set;}
    public String homePageUrl {get; set;}
    public boolean showHome {get; set;}
    
    public void initiatePayment(){
        TermsAndConditions= Label.DM_PaymentConditions;
        version = ApexPages.currentPage().getParameters().get('v');
        resp = JSON.Serialize(ApexPages.currentPage().getParameters());
        paymentId = ApexPages.currentPage().getParameters().get('id');
        string prcs = ApexPages.currentPage().getParameters().get('gw');
        if(prcs == null){
            prcs = 'DM'; 
        }
        recId = paymentId; 
        system.debug('payment id 1-'+paymentId);
        system.debug('resp 1-'+resp);
        Payment_Gateway_Config__mdt pg  = paymentGatewayHelper.getPaymentConfig(prcs);
        if(pg != null){
            homePageUrl= pg.Home_Page_URL__c;
            accesskey =pg.API_Key__c;
            secretkey=pg.API_Secret__c;
            outletRefId=pg.Merchant_Ref_Id__c;
            Organization org = Utilities.getOrganizationDetails();
            endPointUrl = pg.Sandbox_End_Point_URL__c;
            if(!org.IsSandbox)
                endPointUrl = pg.Prod_End_Point_URL__c;
        }   
        
        if(!String.isBlank(paymentId)){
            system.debug('payment id 2-'+paymentId);        
            paymentId = EncryptionUtils.decryptString(paymentId);   
            system.debug('payment id 3-'+paymentId);        
            list<Payment_Request__c>  paymntReqList = [select id,Name,Amount__c,Case__c,Case__r.CaseNumber,Account__r.BillingPostalCode,Account__r.BillingStreet,Account__r.BillingCity,Account__r.BillingState,Account__r.BillingCountryCode,Contact__r.MobilePhone,Contact__r.Email,Contact__r.LastName,Contact__r.FirstName from Payment_Request__c where Id=:paymentId FOR UPDATE];        
            if(!paymntReqList.isEmpty()) {
                Payment_Request__c payInfo = paymntReqList[0];
                transactionUUID =payInfo.Id+'-'+Datetime.now().getTime();
                system.debug('transaction Id--'+transactionUUID);
                amount = String.valueOf(payInfo.Amount__c);
                city = String.isNotBlank(payInfo.Account__r.BillingCity) ?payInfo.Account__r.BillingCity:'';
                country =String.isNotBlank(payInfo.Account__r.BillingCountryCode)?payInfo.Account__r.BillingCountryCode:'';
                postalCode=String.isNotBlank(string.valueOf(payInfo.Account__r.BillingPostalCode))?string.valueOf(payInfo.Account__r.BillingPostalCode):'';
                state =String.isNotBlank(payInfo.Account__r.BillingState)?payInfo.Account__r.BillingState:'';
                email=String.isNotBlank(payInfo.Contact__r.Email)?payInfo.Contact__r.Email:'';
                firstName=String.isNotBlank(payInfo.Contact__r.FirstName)?payInfo.Contact__r.FirstName:'';
                lastName=String.isNotBlank(payInfo.Contact__r.LastName)?payInfo.Contact__r.LastName:'';
                mobilePhone=String.isNotBlank(payInfo.Contact__r.MobilePhone)?payInfo.Contact__r.MobilePhone.replaceAll('[^a-zA-Z0-9\\s+]', ''):'';
                street = payInfo.Account__r.BillingStreet;              
               
            }           
            
        }
        if(resp != null){
            system.debug('resp-'+resp);
            Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(resp);
            if(result != null){
                reasonCode ='';
                reasonCode = string.valueOf(result.get('reason_code'));
                system.debug('reasonCode'+reasonCode);
                transcationId = string.valueOf(result.get('transaction_id'));
                system.debug('msg-'+result.get('message'));
                
                Payment_Request__c req = new Payment_Request__c();                
                string recIdVal;
                if(string.valueOf(result.get('req_transaction_uuid')) != null && string.valueOf(result.get('decision'))!='CANCEL'){
                    recIdVal= string.valueOf(result.get('req_transaction_uuid')).split('-')[0];
                    req.Id = Id.valueOf(recIdVal);
                    req.Authentication_Id__c =string.valueOf(result.get('payer_authentication_transaction_id'));
                    req.Auth_Reference_No__c=string.valueOf(result.get('auth_trans_ref_no'));
                    req.Auth_Amount__c=decimal.valueOf(string.valueOf(result.get('auth_amount'))); 
                    req.Auth_Reconciliation_Ref_No__c=string.valueOf(result.get('auth_reconciliation_reference_number')); 
                    req.JSON_Response__c=resp;
                    req.Reason_Code__c=string.valueOf(result.get('reason_code'));
                    req.Status__c=Constants.RECEIVED_PAYMENT_STATUS;                   
                    req.Transaction_Date__c=system.now();//Datetime.parse(string.valueOf(result.get('auth_time')));
                    req.Transaction_No__c=transcationId;
                    req.Auth_Code__c='CC-'+string.valueOf(result.get('auth_code'));
                    req.Merchant_Reference_Id__c=string.valueOf(result.get('req_profile_id'));
                    req.Transaction_Status_Msg__c=string.valueOf(result.get('message'));
                    list<Payment_Request__c>  payReqList = [select id,Name,Case_Recordtype__c from Payment_Request__c where Id=:req.Id];
                    if(payReqList[0].Case_Recordtype__c !='Development_Control'){
                        showHome=true;
                    }else{
                        showHome=false;
                    }
                    try {
                        update req;
                    } catch (DmlException e) {
                        system.debug('error-->'+e.getMessage());
                        throw new AuraHandledException(e.getMessage());
                    } 
                }
            }            
        }  
        preparePaymentInfo();
    }
    public void preparePaymentInfo(){
        system.debug('inside preapre');
        parametersToSign.put('access_key',accesskey);
        parametersToSign.put('profile_id',outletRefId);
        parametersToSign.put('transaction_uuid',transactionUUID);
        parametersToSign.put('signed_field_names',signedFieldNames);
        parametersToSign.put('unsigned_field_names',''); 
        parametersToSign.put('signed_date_time',getUTCDateTime());
        parametersToSign.put('locale','en');
        parametersToSign.put('transaction_type','sale');
        parametersToSign.put('reference_number',UserInfo.getUserId());
        parametersToSign.put('amount',amount);
        parametersToSign.put('currency','AED');  
        parametersToSign.put('payment_method','card');
        parametersToSign.put('bill_to_address_city',city);     
        parametersToSign.put('bill_to_address_country',country);        
        parametersToSign.put('bill_to_address_postal_code',postalCode);     
        parametersToSign.put('bill_to_address_state',state);
        parametersToSign.put('bill_to_email',email);     
        parametersToSign.put('bill_to_forename',firstName);     
        parametersToSign.put('bill_to_phone',mobilePhone);     
        parametersToSign.put('bill_to_surname',lastName);   
        List<String> streetList = String.isNotBlank(street) ? splitAddressStreet(street) : new List<String>();
        parametersToSign.put('bill_to_address_line1',String.isNotBlank(street) ? streetList.size() == 2 ? streetList[0] : '' : '');
        parametersToSign.put('bill_to_address_line2',String.isNotBlank(street) ? streetList.size() == 2 ? streetList[1] : '' : '');
        signature = sign(parametersToSign);
        parametersToSign.put('signature', signature);
        
        system.debug('paraMap-'+parametersToSign);
    }
    public String getPaymentValidity() {
        system.debug('payment-id'+paymentId);
        if(String.isNotBlank(paymentId)){
            list<Payment_Request__c> payInfo = [Select id,Reason_Code__c from Payment_Request__c where Id=:paymentId];
            if(!payInfo.isEmpty()){
                if(payInfo[0].Reason_Code__c == '100')
                    return 'Payment Already Proccessed.';
                else 
                    return ''; //valid
                
            }else{
                return 'Invalid Payment';
            }
        }else{
            return 'Invalid Link/User cancelled the tranasction';
        }
        
        
    }
    private static List<string> splitAddressStreet(String street) {
        List<String> streetList = new List<String>();
        
        List<String> strList = street.split(' ');
        String street1 = '';
        String street2 = '';
        for (String tempStr: strList) {
            if (street1.length() <= 60 && (street1.length() + tempStr.length()) <= 60 && String.isBlank(street2)) {
                street1 += tempStr + ' ';
            } else if ((String.isBlank(street2) && tempStr.length() <= 60) || (street2.length() <= 60 && (street2.length() + tempStr.length()) <= 60)) {
                street2 += tempStr + ' ';
            }
        }
        streetList.add(street1.trim());
        streetList.add(street2.trim());
        
        return streetList;
    }
    
    public String getParametersValues() {
        
        String result = '';        
        for(String oKey : parametersToSign.keySet()) { 
            result += '<div>';
            result += '<input type="hidden" id="' + oKey + '" name="' + oKey + '" value="' + parametersToSign.get(oKey) + '"readonly/>';
            result += '</div>';
        }
        System.debug('params: ' + result);
        return result;
    }
    public static String sign(Map<String, String> paramsArray)  {
        //system.debug('Point: paramsArray: ' + paramsArray);
        String dataToSign = buildDataToSign(paramsArray);      
        String result = EncodingUtil.base64Encode(Crypto.generateMac('hmacSHA256', Blob.valueOf(dataToSign), Blob.valueOf(secretkey)));
        return result;
    }
    public String getSignedData() {
        
        //System.debug('Request: <input type="hidden" id="signature" name="signature" value="' + sign(parametersToSign) + '" readonly/>');
        
        String result = '';
        result += '<input type="hidden" id="signature" name="signature" value="' + sign(parametersToSign) + '" readonly />';
        system.debug('signedData' + result);
        return result;
    }
    
    private static String buildDataToSign(Map<String,String> paramsArray) {
        String[] signedFieldNames = paramsArray.get('signed_field_names').split(',');
        List<String> dataToSign = new List<String>();
        
        for(String oSignedFieldName : signedFieldNames) {
            dataToSign.add(oSignedFieldName + '=' + paramsArray.get(oSignedFieldName));
        }
        return commaSeparate(dataToSign);
    }
    private static String commaSeparate(List<String> dataToSign) {
        String result = '';
        for(String str : dataToSign) {
            result += (result==''?'':',') + str;
        }
        return result;                         
    }
    public String getUTCDateTime(){
        DateTime oUTSDateTime = Datetime.now();
        String strUTCDateTime = oUTSDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        //System.debug('Point: '+strUTCDateTime );
        return strUTCDateTime;
    }
}