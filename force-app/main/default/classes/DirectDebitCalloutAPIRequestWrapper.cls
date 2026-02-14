public class DirectDebitCalloutAPIRequestWrapper {
    
    public static String PrepareDataForCalloutForMandate(DDTransaction__c ddtransaction, String requestType, String mandateReference){
        
        ADCBAndADIBMandateWrapperClass ddsRequestWrapper = new ADCBAndADIBMandateWrapperClass();
        
        /*Prepare the wrapper data and pass request body */
        
        /* Maximum Amount Details */
        ADCBAndADIBMandateWrapperClass.cls_MaximumAmount cls_MaximumAmountwrapper = new ADCBAndADIBMandateWrapperClass.cls_MaximumAmount();
        cls_MaximumAmountwrapper.Amount = String.ValueOf(ddtransaction.DirectDebitRequest__r.MaximumAmount__c);
        cls_MaximumAmountwrapper.max_Currency = String.ValueOf(ddtransaction.DirectDebitRequest__r.CurrencyIsoCode);
        
        /* Minimum Amount Details */
        ADCBAndADIBMandateWrapperClass.cls_MinimumAmount cls_MinimumAmountwrapper = new ADCBAndADIBMandateWrapperClass.cls_MinimumAmount();
        cls_MinimumAmountwrapper.Amount = String.ValueOf(ddtransaction.DirectDebitRequest__r.MinimumAmount__c);
        cls_MinimumAmountwrapper.min_Currency = String.ValueOf(ddtransaction.DirectDebitRequest__r.CurrencyIsoCode);
        
        /* Payment frequency Details */
        ADCBAndADIBMandateWrapperClass.cls_PaymentDetails paymentDetailsWrapper = new ADCBAndADIBMandateWrapperClass.cls_PaymentDetails();
        paymentDetailsWrapper.PaymentFrequency = ddtransaction.DirectDebitRequest__r.PaymentFrequencyCharacter__c; 
        paymentDetailsWrapper.IBAN = ddtransaction.DirectDebitRequest__r.CustomerIBANNumber__c;
        paymentDetailsWrapper.DefinedDays = ddtransaction.DirectDebitRequest__r.DirectDebitBank__c == BatchToDirectDebitCalloutAPIHelper.ADIBBankName ? '' : '0'; // defaulted to ZERO in the current process
        paymentDetailsWrapper.MaximumAmount = cls_MaximumAmountwrapper;
        paymentDetailsWrapper.MinimumAmount = cls_MinimumAmountwrapper;
        
        
        /* Mandate Details, Need to get confirmation on all the maapings */
        ADCBAndADIBMandateWrapperClass.cls_MandateDetails mandateDetailWrapper = new ADCBAndADIBMandateWrapperClass.cls_MandateDetails();
        mandateDetailWrapper.OICCode = ddtransaction.DirectDebitRequest__r.OIC__c; //940000331
        mandateDetailWrapper.FundingAccountType = ddtransaction.DirectDebitRequest__r.FundingAccountType__c; // C
        mandateDetailWrapper.DDAIssuedFor = ddtransaction.DirectDebitRequest__r.DDAPurposeCode__c; // 404
        datetime CommencesOnDatetime = (datetime)ddtransaction.DirectDebitRequest__r.CommencesOn__c;
        mandateDetailWrapper.DDACommencementDate = String.valueOf(CommencesOnDatetime.format(BatchToDirectDebitCalloutAPIHelper.ADCBDateFormat)); 
        datetime ExpiresOn = (datetime)ddtransaction.DirectDebitRequest__r.ExpiresOn__c;
        
        mandateDetailWrapper.DDAAmountType = ddtransaction.DirectDebitRequest__r.DDAamountType__c; //'V'
        mandateDetailWrapper.DDAInstancesAllowed = ddtransaction.DirectDebitRequest__r.DebitRequestInstanceAllowed__c;
        mandateDetailWrapper.DDAFileName = ddtransaction.DDAFileName__c; 
        mandateDetailWrapper.PaymentDetails = paymentDetailsWrapper;
        
        /* Payer Details */
        ADCBAndADIBMandateWrapperClass.cls_PayerDetails payerDetailsWrapper = new ADCBAndADIBMandateWrapperClass.cls_PayerDetails();
        payerDetailsWrapper.FullName     = ddtransaction.DirectDebitRequest__r.CustomerAccountName__c;
        payerDetailsWrapper.MobileNumber = ddtransaction.DirectDebitRequest__r.MobileNumber__c;
        payerDetailsWrapper.EmailId      = ddtransaction.DirectDebitRequest__r.CustomerEmail__c;
        payerDetailsWrapper.BankCode     = ddtransaction.DirectDebitRequest__r.PayingBankID__c;//FIN-141
        
        /* Customer Details */
        ADCBAndADIBMandateWrapperClass.cls_CustomerDetails customerDetailsWrapper = new ADCBAndADIBMandateWrapperClass.cls_CustomerDetails();
        customerDetailsWrapper.CustomerType   = ddtransaction.DirectDebitRequest__r.CustomerType__c;
        customerDetailsWrapper.CustomerId     = ddtransaction.DirectDebitRequest__r.CustomerIDNumber__c;
        customerDetailsWrapper.CustomerIdType = BatchToDirectDebitCalloutAPIHelper.getCustomerIdType(ddtransaction.DirectDebitRequest__r.CustomerIdType__c);//'EIDAC';
        
        
        /*Data*/
        ADCBAndADIBMandateWrapperClass.cls_Data dataWrapper = new ADCBAndADIBMandateWrapperClass.cls_Data();
        dataWrapper.RequestType = BatchToDirectDebitCalloutAPIHelper.getRequestType(requestType);
        String customerReference = ddtransaction.DirectDebitRequest__r.Name.right(5)+ddtransaction.Name.right(5);
        dataWrapper.CustomerReference = ddtransaction.DirectDebitRequest__r.PayerIdentification__c;//customerReference;//'DDR+DDT';
        dataWrapper.PayerId = '';//System.Label.ADIB_PayerId;//'SUS01';//ALDAR
        dataWrapper.CaptureMode = ddtransaction.DirectDebitRequest__r.CaptureMode__c;
        dataWrapper.CancellationCode = requestType == 'Cancellation' ? 'P50' : '';
        
        
        dataWrapper.PayerDetails = payerDetailsWrapper;
        dataWrapper.CustomerDetails = customerDetailsWrapper;
        dataWrapper.PreApprovalReference = '';
        dataWrapper.MandateReferenceNumber = mandateReference;
        
        mandateDetailWrapper.DDAExpiryDate = String.valueOf(ExpiresOn.format(BatchToDirectDebitCalloutAPIHelper.ADCBDateFormat));
		dataWrapper.MandateDetails = mandateDetailWrapper;
        
        ddsRequestWrapper.Data = dataWrapper;
        
        
        String requestBody = JSON.serialize(ddsRequestWrapper);
        
        // String requestBody = '{"Data": {"RequestType": "RQST","CustomerReference": "DDAREQ0051","PayerId": "SUS01","CustomerDetails": {"CustomerType": "IN","CustomerId": "784198363604806","CustomerIdType": "UEIC"},"PayerDetails": {"FullName": "Tyrin Lanyster","MobileNumber": "+971501112233","EmailId": "test@aldar.com","BankCode": "049"},"MandateDetails": {"OICCode": "940000331","FundingAccountType": "CUR","DDAIssuedFor": "404","DDACommencementDate": "27-02-2024","DDAExpiryDate": "28-02-2026","DDAAmountType": "V","DDAInstancesAllowed": "000","DDAFileName": "18083640_MN_AJFZA0014.pdf","PaymentDetails": {"PaymentFrequency": "D","IBAN": "AE350030011454359920001","DefinedDays": "","MinimumAmount": {"Amount": "1.00","Currency": "AED"},"MaximumAmount": {"Amount": "7620.00","Currency": "AED"}}},"CaptureMode": "P","PreApprovalReference": "","MandateReferenceNumber": "MES0581","CancellationCode": ""}}';
        if(requestBody.contains('min_Currency') || requestBody.contains('max_Currency')){
            requestBody = requestBody.replace('min_Currency', 'Currency');
            requestBody = requestBody.replace('max_Currency', 'Currency');
        }
        
        return requestBody;
    }
}