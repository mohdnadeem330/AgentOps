public without sharing class PaymentGWController {
    public String finalURL {get; set;}
    public String customerName {get; set;}
    public String amount {get; set;}
    public String projectName {get; set;}
    public String salutation {get; set;}
    public String firstName {get; set;}
    public String lastName {get; set;}
    public String email {get; set;}
    public String residence {get; set;}
    public String nationality {get; set;}
    public String city {get; set;}
    public String postalCode {get; set;}
    public String unitNumber {get; set;}
    public String passportExpiryDate {get; set;}
    public String passportNumber {get; set;}
    public String salesManager {get; set;}
    public String mobileWithoutCountryCode {get; set;}
    public String countryCode {get; set;}
    public String address {get; set;}
    public String eoi {get; set;}
    public String salesOrderTermsAndConditions {get; set;}
    public String version {get; set;}
    public String recId {get; set;}
    public String serviceRequest {get; set;}

    private ReceiptAcknowledgement__c payment;
    private String accessKey;
    private String profileId;
    private static String secretKey; // Added by Nikhil for redefine for other projects
    private String transactionUUID;
    private String signedFieldNames = 'access_key,profile_id,transaction_uuid,signed_field_names,unsigned_field_names,signed_date_time,locale,transaction_type,reference_number,amount,currency,payment_method,bill_to_address_city,bill_to_address_country,bill_to_address_line1,bill_to_address_line2,bill_to_address_postal_code,bill_to_address_state,bill_to_email,bill_to_forename,bill_to_phone,bill_to_surname';
    private String unsignedFieldNames='';
    private String locale = 'en';
    private String transactionType = 'sale';
    private String referenceNumber;
    private String signedDateTime = getUTCDateTime();
    private String currencyCode;
    private String paymentMethod = 'card';
    private String signature;
    private Map<String,String> parametersToSign = new Map<String,String>();
    private static APISetting__mdt  paymentAPI;
    private static List<MID_Config_for_Other_Charges__mdt>  paymentAPI_MIDConfig;

    private String country;
    private String state;
    private String street;
    private String mobilePhone;

    public string resp {get; set;}
    public static String reasonCode {get; set;}
    public static boolean viewResponseMessage {get; set;}
    private static String paymentId;
    private static String authenticationId;
    private static String decision;
    private static String authenticationReferenceNumber;
    private static String receiptNumber;
    private static String referenceNumber;
    // Added by Tharun
    private String authCode;
    // Added by Tharun on April 5 as per ASF-175
    private static String onlinePaymentMessage = '';
    public void paymentGWController1(){

        salesOrderTermsAndConditions = 'https://www.aldar.com/launchreservation_events/property-purchase_25000/residential-terms';

        resp = JSON.Serialize(ApexPages.currentPage().getParameters());
        paymentId = ApexPages.currentPage().getParameters().get('id');
        recId = paymentId;
        version = ApexPages.currentPage().getParameters().get('v');
        viewResponseMessage = false;
        
            
        /*resp = '{"utf8":"✓","transaction_id":"6551210281356291304002","signed_field_names":"transaction_id,decision,req_access_key,req_profile_id,req_transaction_uuid,req_transaction_type,req_reference_number,req_amount,req_currency,req_locale,req_payment_method,req_bill_to_forename,req_bill_to_surname,req_bill_to_email,req_bill_to_phone,req_bill_to_address_line1,req_bill_to_address_city,req_bill_to_address_country,req_card_number,req_card_type,req_card_type_selection_indicator,req_card_expiry_date,card_type_name,req_device_fingerprint_id,req_payer_authentication_acs_window_size,req_payer_authentication_indicator,req_payer_authentication_merchant_name,payer_authentication_reason_code,payer_authentication_specification_version,payer_authentication_transaction_id,payer_authentication_enroll_veres_enrolled,payer_authentication_acs_transaction_id,message,reason_code,auth_avs_code,auth_avs_code_raw,auth_response,auth_amount,auth_code,auth_cavv_result,auth_cavv_result_raw,auth_cv_result,auth_cv_result_raw,auth_trans_ref_no,auth_time,request_token,merchant_advice_code,auth_reconciliation_reference_number,bill_trans_ref_no,payer_authentication_validate_result,payer_authentication_cavv,payer_authentication_validate_e_commerce_indicator,payer_authentication_eci,payer_authentication_pares_status,payer_authentication_xid,score_device_fingerprint_cookies_enabled,score_device_fingerprint_flash_enabled,score_device_fingerprint_hash,score_device_fingerprint_images_enabled,score_device_fingerprint_javascript_enabled,score_device_fingerprint_true_ipaddress,score_device_fingerprint_true_ipaddress_city,score_device_fingerprint_true_ipaddress_country,score_device_fingerprint_screen_resolution,score_device_fingerprint_smart_id,score_device_fingerprint_smart_id_confidence_level,score_device_fingerprint_browser_language,score_factors,score_rcode,score_time_local,score_model_used,score_return_code,score_host_severity,score_score_result,score_reason_code,score_rflag,score_rmsg,score_address_info,score_identity_info,score_internet_info,score_ip_city,score_ip_country,score_ip_state,score_ip_routing_method,score_suspicious_info,score_velocity_info,decision_early_return_code,decision_early_reason_code,decision_reason_code,decision_rmsg,decision_rcode,decision_case_priority,decision_return_code,decision_early_rcode,decision_rflag,signed_field_names,signed_date_time","signed_date_time":"2022-06-13T11:50:29Z","signature":"jQckvlCQjdAyoTQx2A3icqrsgI+RM28DF5Ntn5vo46Y=","score_velocity_info":"VEL-NAME^VELI-CC^VELI-FP^VELI-TIP^VELL-CC^VELL-FP^VELL-TIP^VELS-CC^VELS-FP^VELS-TIP^VELV-CC","score_time_local":"14:50:28","score_suspicious_info":"MUL-EM","score_score_result":"84","score_rmsg":"Score exceeds threshold. Score = 84","score_rflag":"DSCORE","score_return_code":"1072000","score_reason_code":"100","score_rcode":"1","score_model_used":"default_cemea","score_ip_state":"c","score_ip_routing_method":"fixed","score_ip_country":"eg","score_ip_city":"al qahirah","score_internet_info":"MM-IPBCO","score_identity_info":"MORPH-C","score_host_severity":"1","score_factors":"H","score_device_fingerprint_true_ipaddress_country":"EG","score_device_fingerprint_true_ipaddress_city":"al qahirah","score_device_fingerprint_true_ipaddress":"134.238.72.127","score_device_fingerprint_smart_id_confidence_level":"100.00","score_device_fingerprint_smart_id":"5091b06a8a6e42f1891129e33b267789","score_device_fingerprint_screen_resolution":"1920x1080","score_device_fingerprint_javascript_enabled":"true","score_device_fingerprint_images_enabled":"false","score_device_fingerprint_hash":"5091b06a8a6e42f1891129e33b267789","score_device_fingerprint_flash_enabled":"false","score_device_fingerprint_cookies_enabled":"true","score_device_fingerprint_browser_language":"en-US,en;q=0.9","score_address_info":"UNV-ADDR","request_token":"Axj//wSTYyROYRgInWpC/7Us2atWLJiwZOGLNq2ZOWLNg0YMGSiOPFpWDgFRHHi0rB2IEsNQCHSGTSTL0YsKuzgwVybGSJzCMBE61IQAzQdu"'
        +',"req_transaction_uuid":"a1A8E000002g6e4UAA-1655120943666","req_transaction_type":"sale","req_reference_number":"00526000009Aw2oAAC","req_profile_id":"B21DB9B8-0EB5-4E27-A963-B6A0F50A6411","req_payment_method":"card","req_payer_authentication_merchant_name":"ADCB","req_payer_authentication_indicator":"01","req_payer_authentication_acs_window_size":"03","req_locale":"en","req_device_fingerprint_id":"6f7679efc99848ab9cca72185d49bb21","req_currency":"AED","req_card_type_selection_indicator":"1","req_card_type":"001","req_card_number":"xxxxxxxxxxxx1096","req_card_expiry_date":"02-2025","req_bill_to_surname":"Moscow","req_bill_to_phone":"+962787120342","req_bill_to_forename":"Created","req_bill_to_email":"ali.athamneh@pwc.com","req_bill_to_address_line1":"amman","req_bill_to_address_country":"JO","req_bill_to_address_city":"amman","req_amount":"2000.00","req_access_key":"a9e9af7262253248901760e4a429154f","reason_code":"100","payer_authentication_xid":"MTIzNDU2Nzg5MDEyMzQ1Njc4OTA=","payer_authentication_validate_result":"0","payer_authentication_validate_e_commerce_indicator":"vbv","payer_authentication_transaction_id":"UuNTkrX0O1WE6UESLY00","payer_authentication_specification_version":"2.1.0","payer_authentication_reason_code":"100","payer_authentication_pares_status":"Y","payer_authentication_enroll_veres_enrolled":"Y","payer_authentication_eci":"05","payer_authentication_cavv":"MTIzNDU2Nzg5MDEyMzQ1Njc4OTA=","payer_authentication_acs_transaction_id":"0d700b4c-c752-4e78-a79f-ec5ab57530a4","message":"Request was processed successfully.","merchant_advice_code":"01","decision_rmsg":"Service processed successfully","decision_rflag":"SOK","decision_return_code":"1320000","decision_reason_code":"100","decision_rcode":"1","decision_early_return_code":"9999999","decision_early_reason_code":"100","decision_early_rcode":"1","decision_case_priority":"3","decision":"ACCEPT","card_type_name":"Visa","bill_trans_ref_no":"6551210281356291304002","auth_trans_ref_no":"6551210281356291304002","auth_time":"2022-06-13T115029Z","auth_response":"00","auth_reconciliation_reference_number":"216411124967","auth_cv_result_raw":"M","auth_cv_result":"M","auth_code":"831000","auth_cavv_result_raw":"2","auth_cavv_result":"2","auth_avs_code_raw":"Y","auth_avs_code":"Y","auth_amount":"2000.00"}';
        */


        if(resp != null){
             populateFieldsFromResponse();
            if(reasonCode != null && String.isNotEmpty(reasonCode)){
                updatePaymentRecord();
                viewResponseMessage = true;
            }
        }
         //reasonCode = '100';

        paymentAPI = Utilities.getServiceDetails(Constants.PAYMENT);
        accessKey = paymentAPI.APIKey__c;
        profileId = paymentAPI.APIId__c;
        secretKey = paymentAPI.SecretKey__c; //Added by Nikhil 
        
        if(String.isNotBlank(paymentId)){ 
            if(String.isEmpty(reasonCode)){
                try{
                    paymentId = EncryptionUtils.decryptString(paymentId);
                } catch(Exception e){
                    System.debug(e);
                }
            }
 
            List<ReceiptAcknowledgement__c> paymentList = [Select SalesOrder__r.Unit__r.Project__c,
            Amount__c, CurrencyIsoCode, Id,Opportunity__r.Id,Account__r.BillingCity, Account__r.BillingCountry,
                      Contact__r.FirstName, Contact__r.LastName, CustomerName__c, Account__r.BillingState, Account__r.BillingStateCode, Account__r.BillingCountryCode, 
                      OpportunityEOI__r.ProjectNameFormula__c, SalesOrder__r.ProjectName__c, Account__r.BillingStreet, 
                      Account__r.BillingPostalCode, Contact__r.MobilePhone, Contact__r.Email, Opportunity__r.Owner.Name, 
                      Contact__r.Salutation, Contact__r.CountryOfResidence__c, Contact__r.Nationality__c, EncryptedRecordId__c, 
                      SalesOrder__r.UnitNumber__c, Contact__r.PassportExpiryDate__c, Contact__r.PassportNumber__c,
                      SalesOrder__r.SalesManagerName__c, Contact__r.MobilePhone__c, Contact__r.MobileCountryCode__c, ServiceRequest__c
                      FROM ReceiptAcknowledgement__c WHERE Id = :paymentId];

            if(!paymentList.isEmpty()){
            payment = paymentList[0];
 
            //added by Noor
            if(paymentList[0].SalesOrder__r.Unit__r.Project__c != null){
				 paymentAPI_MIDConfig = [SELECT API_Key__c,id,Profile_Id__c,Secret_Key__c,Project_Id__c,Is_Active__c  FROM MID_Config_for_Other_Charges__mdt  where Project_Id__c =:paymentList[0].SalesOrder__r.Unit__r.Project__c and Is_Active__c  = True ];
               if(!paymentAPI_MIDConfig.isEmpty() && paymentAPI_MIDConfig != null){
                    accessKey = paymentAPI_MIDConfig[0].API_Key__c;
                    profileId = paymentAPI_MIDConfig[0].Profile_Id__c;
                    secretKey = paymentAPI_MIDConfig[0].Secret_Key__c;//Added by Nikhil
                 }
            }        

            amount = String.valueOf(payment.Amount__c);
            currencyCode = payment.CurrencyIsoCode;
            firstName = payment.Contact__r.FirstName;
            lastName = payment.Contact__r.LastName;
            customerName = payment.CustomerName__c;
            city = payment.Account__r.BillingCity;
            country = payment.Account__r.BillingCountryCode;
            state = payment.Account__r.BillingStateCode;
            street = payment.Account__r.BillingStreet;
            postalCode = payment.Account__r.BillingPostalCode;
            mobilePhone = payment.Contact__r.MobilePhone;
            email = payment.Contact__r.Email;
            serviceRequest = payment.ServiceRequest__c;
            
            if(mobilePhone != null){
                mobilePhone = mobilePhone.replaceAll('[^a-zA-Z0-9\\s+]', '');
            }
            if(payment.OpportunityEOI__c != null){
                projectName = payment.OpportunityEOI__r.ProjectNameFormula__c;
                eoi = payment.OpportunityEOI__c;
            } else{
                projectName = payment.SalesOrder__r.ProjectName__c;
            }

            salutation = payment.Contact__r.Salutation;
            residence = payment.Contact__r.CountryOfResidence__c;
            nationality = payment.Contact__r.Nationality__c;
            unitNumber = payment.SalesOrder__r.UnitNumber__c;
            DateTime passportExpiry = payment.Contact__r.PassportExpiryDate__c;
            passportNumber = payment.Contact__r.PassportNumber__c;
            salesManager = payment.Opportunity__r.Owner.Name;
            mobileWithoutCountryCode = payment.Contact__r.MobilePhone__c;
            countryCode = payment.Contact__r.MobileCountryCode__c;

            address = '';

            if(street != null && !String.isEmpty(street)){
                address += (street + ' - ');
            }
            if(city != null && !String.isEmpty(city)){
                address += (city + ' - ');
            }
            if(state != null && !String.isEmpty(state)){
                address += (state + ' - ');
            }
            address += (payment.Account__r.BillingCountry);

            if(passportExpiry != null){
                passportExpiryDate = passportExpiry.format('dd-MM-yyyy');
            }

            transactionUUID = paymentId+'-'+Datetime.now().getTime();
        }
    }
            referenceNumber = UserInfo.getUserId();
             populateParametersToSign();
             signature = sign(parametersToSign);
             parametersToSign.put('signature', signature);   

    }

    private void populateParametersToSign() {
        parametersToSign.put('access_key',accessKey);
        parametersToSign.put('profile_id',profileId);
        parametersToSign.put('transaction_uuid',transactionUUID);
        parametersToSign.put('signed_field_names',signedFieldNames);
        parametersToSign.put('unsigned_field_names',unsignedFieldNames); 
        parametersToSign.put('signed_date_time',signedDateTime);
        parametersToSign.put('locale','en');
        parametersToSign.put('transaction_type','sale');
        parametersToSign.put('reference_number',referenceNumber);
        parametersToSign.put('amount',amount);
        parametersToSign.put('currency',currencyCode);  
        parametersToSign.put('payment_method',paymentMethod);
        parametersToSign.put('bill_to_address_city',String.isNotBlank(city) ? city : '');     
        parametersToSign.put('bill_to_address_country',String.isNotBlank(country) ? country : '');        
        parametersToSign.put('bill_to_address_postal_code',String.isNotBlank(postalCode) ? postalCode : '');     
        parametersToSign.put('bill_to_address_state',String.isNotBlank(state) ? state : '');
        parametersToSign.put('bill_to_email',String.isNotBlank(email) ? email : '');     
        parametersToSign.put('bill_to_forename',String.isNotBlank(firstName) ? firstName : '');     
        parametersToSign.put('bill_to_phone',String.isNotBlank(mobilePhone) ? mobilePhone : '');     
        parametersToSign.put('bill_to_surname',String.isNotBlank(lastName) ? lastName : '');     
        
        List<String> streetList = String.isNotBlank(street) ? splitAddressStreet(street) : new List<String>();
        parametersToSign.put('bill_to_address_line1',String.isNotBlank(street) ? streetList.size() == 2 ? streetList[0] : '' : '');
        parametersToSign.put('bill_to_address_line2',String.isNotBlank(street) ? streetList.size() == 2 ? streetList[1] : '' : '');
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

    public static String sign(Map<String, String> paramsArray)  {
         String dataToSign = buildDataToSign(paramsArray);
        String result = EncodingUtil.base64Encode(Crypto.generateMac('hmacSHA256', Blob.valueOf(dataToSign), Blob.valueOf(secretKey)));
        return result;
    }
    
    public String getUTCDateTime(){
        DateTime oUTSDateTime = Datetime.now();
        String strUTCDateTime = oUTSDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
         return strUTCDateTime;
    }
    
    public String getParametersValues() {
        String result = '';
        
        for(String oKey : parametersToSign.keySet()) { 
            System.debug('Request: <div><input type="hidden" id="' + oKey + '" name="' + oKey + '" value="' + parametersToSign.get(oKey) + '"readonly/></div>');
            result += '<div>';
            result += '<input type="hidden" id="' + oKey + '" name="' + oKey + '" value="' + parametersToSign.get(oKey) + '"readonly/>';
            result += '</div>';
        }
        return result;
    }

    public String getSignedData() {

        System.debug('Request: <input type="hidden" id="signature" name="signature" value="' + sign(parametersToSign) + '"readonly/>');

        String result = '';
        result += '<input type="hidden" id="signature" name="signature" value="' + sign(parametersToSign) + '"readonly/>';
        return result;
    }

    public String getValitity() {
        if(String.isNotBlank(paymentId)){
            return PaymentService.validateSFPaymentLink(paymentId);
        }
        return 'Invalid Link';
    }

    public String getEndp() {
        Organization org = Utilities.getOrganizationDetails();
           
        String endPointURL = paymentAPI.SandboxURL__c ;
           
        if(!org.IsSandbox){
            endPointURL = paymentAPI.ProductionURL__c ; 
        }

        string url = endPointURL;  
        return url;
    }

    ///////////////////////////// Handle Response ///////////////////////////////////////////////

    public void updatePaymentRecord(){
       
        if(String.isNotBlank(paymentId)){
            //payment is in progress;
            //Add by Noor it should work only when status of RAK is Link sent;
            List<ReceiptAcknowledgement__c> receiptAck = [SELECT ID FROM ReceiptAcknowledgement__c WHERE Id =: paymentId AND Status__c=:Constants.LINK_SENT];
            //soql for ID AND status == linksent;
            if(receiptAck.size()>0 && !receiptAck.isEmpty()){              
          
            // Tharun added PaymentResponseMessage__c = onlinePaymentMessage
            ReceiptAcknowledgement__c paymentRecord = new ReceiptAcknowledgement__c
                (id=Id.valueOf(paymentId), AuthenticationId__c=authenticationId, AuthenticationReferenceNumber__c=authenticationReferenceNumber, 
                 Decision__c=decision, JSONResponse__c=resp, PaymentResponseMessage__c=onlinePaymentMessage, 
                 ReasonCode__c=reasonCode, Status__c=Constants.LINK_SENT);
            
            if(reasonCode.equals(Constants.SUCCESS_REASON_CODE)){
                //Commented by Tharun
                //paymentRecord.Status__c = Constants.RECEIPT_STATUS_CLEARED;
                paymentRecord.Status__c = Constants.RECEIVED_PAYMENT_STATUS;
                paymentRecord.BankName__c = 'Abu Dhabi Commercial Bank';
                //paymentRecord.ReceiptNumber__c = receiptNumber; 
                paymentRecord.ReceiptDate__c = Date.Today();
                //Below line Tharun changed from referenceNumber to authCode, referenceNumber updated in Online_Payment_Reference_Number__c
                paymentRecord.ReferenceNumber__c = 'CC-'+authCode;
                paymentRecord.ChequeReceived__c = true;
                paymentRecord.OnlinePaymentCleared__c = true;
            }
            update paymentRecord;
           }
        }
    }

    public void populateFieldsFromResponse(){

        JSONParser parser = JSON.createParser(resp);

        while(parser.nextToken() != null){

            if(parser.getText().equals('req_transaction_uuid')){
                parser.nextToken();
                paymentId = parser.getText().split('-')[0];
            
            }else if(parser.getText().equals('payer_authentication_transaction_id')){
                parser.nextToken();
                authenticationId = parser.getText();
        
            }else if(parser.getText().equals('reason_code')){
                parser.nextToken();    
                reasonCode = parser.getText();
    
            }else if(parser.getText().equals('decision')){
                parser.nextToken();
                decision = parser.getText();
        
            }else if(parser.getText().equals('auth_trans_ref_no')){
                parser.nextToken();
                authenticationReferenceNumber = parser.getText();    

            }else if(parser.getText().equals('transaction_id')){
                parser.nextToken();
                receiptNumber = parser.getText();
                
            }else if(parser.getText().equals('bill_trans_ref_no')){
                parser.nextToken();
                referenceNumber = parser.getText();
                
            }else if(parser.getText().equals('auth_code')){
                parser.nextToken();
                authCode = parser.getText();
            }
            // Added by Tharun on April 5 as per ASF-175
            else if(parser.getText().equals('message')){
                parser.nextToken();
                if(parser.getText() != 'null' || parser.getText() != 'NULL'){
                    onlinePaymentMessage = parser.getText();
                }
            }
        }
    }
}