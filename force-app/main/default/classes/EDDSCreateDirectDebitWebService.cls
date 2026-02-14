@RestResource (urlMapping = '/edds/createEDirectDebit')
global with sharing class EDDSCreateDirectDebitWebService {
    public static CreateDDWrapper ddWrapperObject;
    
    @HTTPPost
    global static void doPost(){  
        RestContextHandler handler = new RestContextHandler(true);
        try {
            Boolean isError = false;
            String errorMessage = '';
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            ddWrapperObject = (CreateDDWrapper)JSON.deserialize(jsonBody, CreateDDWrapper.class);
            
            //validate enum value
            if(EDDSService.isValidJourneyType(ddWrapperObject.journeyType)==false){
                isError = true;
                errorMessage += 'Provide a valid Journey Type. ';
            }else{
                if(EDDSService.isValidSalesforceId(ddWrapperObject.payerAccountId,'Account')==false) {
                    isError = true;
                    errorMessage += 'Provide a valid Account Id. ';
                }
                if(ddWrapperObject.journeyType == EDDSService.JOURNEY_TYPE.NewSale.name()  || ddWrapperObject.journeyType == EDDSService.JOURNEY_TYPE.OffPlanTransfer.name() /*|| ddWrapperObject.journeyType == EDDSService.JOURNEY_TYPE.NewLeasing.name()*/){
                    if(EDDSService.isValidSalesforceId(ddWrapperObject.relatedRecordId,'SalesOrder__c')==false) {
                        isError = true;
                        errorMessage += 'Provide a valid Sales Order Id. ';
                    }
                }else if(ddWrapperObject.journeyType == EDDSService.JOURNEY_TYPE.NewLeasing.name()){
                    // TODO: Add validation for related record id
                    /*if(EDDSService.isValidSalesforceId(relatedRecordId,'Contract')==false) {
                        isError = true;
                        errorMessage += 'Provide a valid Contract Id. ';
                    }*/
                }else if(ddWrapperObject.journeyType == EDDSService.JOURNEY_TYPE.Retail.name()){
                    // TODO: Add validation for related record id
                }
            }
            if(isError) {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_NOT_FOUND;
                handler.response.message = errorMessage.trim();
                handler.setResponseStatusCode(Constants.STATUS_CODE_NOT_FOUND);
                handler.finalize();
                return;
            }
            if(ddWrapperObject.journeyType == EDDSService.JOURNEY_TYPE.NewSale.name()  || ddWrapperObject.journeyType == EDDSService.JOURNEY_TYPE.OffPlanTransfer.name()){
                List<SalesOrder__c> salesOrderList =    [SELECT Id, Name, Account__c,Unit__r.Project__r.BankNameEscrow__c,Unit__r.BuildingSectionName__r.BankNameEscrow__c,Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c,
                                                        Unit__r.Project__r.BeneficiaryNameEscrow__c,SalesManager__r.Email,
                                                        SalesManager__r.Manager.Email, SalesManager__c, SalesManager__r.ManagerId,Unit__r.Project__r.Name_of_Seller__c,Unit__r.Project__r.name 
                                                        FROM SalesOrder__c WHERE Id =: ddWrapperObject.relatedRecordId LIMIT 1];
                List<Account> payerAccountList = [SELECT Id, Name FROM Account WHERE Id =: ddWrapperObject.payerAccountId LIMIT 1];                                                        
                if(!salesOrderList.isEmpty() && !payerAccountList.isEmpty()){
                    Map<String, DirectdebitDefaultvalues__mdt> allDDValues 	= new Map<String, DirectdebitDefaultvalues__mdt>();
                    allDDValues = DirectDebitService.getDirectDebitDefaultValues();
                    String EscrowDirectDebitBank    =   salesOrderList[0].Unit__r.BuildingSectionName__r.BankNameEscrow__c!=null?salesOrderList[0].Unit__r.BuildingSectionName__r.BankNameEscrow__c:salesOrderList[0].Unit__r.Project__r.BankNameEscrow__c;
                    DirectDebitRequest__c dd = null;
                    if(ddWrapperObject.directDebitId==null || ddWrapperObject.directDebitId.trim()==''){
                        dd = new DirectDebitRequest__c();
                    }else{
                        dd = new DirectDebitRequest__c(Id = ddWrapperObject.directDebitId);
                    }
                    dd.Is_EDDS__c = true;

                    /*Populate Manager and LineManager Emails*/
                    if(salesOrderList[0].SalesManager__c != null){
                        dd.SalesManagerEmail__c =   salesOrderList[0].SalesManager__r.Email!=null?salesOrderList[0].SalesManager__r.Email:null;
                    }
                    if(salesOrderList[0].SalesManager__r.ManagerId != null){
                        dd.LineManagersEmail__c =   salesOrderList[0].SalesManager__r.Manager.Email!=null?salesOrderList[0].SalesManager__r.Manager.Email:null;
                    }

                    /*Populate default values if default metadata record is retrieved*/
                    if((!allDDValues.isEmpty() || allDDValues <> null) && allDDValues.KeySet().contains(EscrowDirectDebitBank)){
                        dd.PaymentFrequency__c 				= allDDValues.get(EscrowDirectDebitBank).PaymentFrequency__c;
                        dd.MinimumAmount__c 				= allDDValues.get(EscrowDirectDebitBank).MinimumAmount__c;
                    }

                    dd.OriginatorName__c    =   EscrowDirectDebitBank=='First Abu Dhabi Bank'?(salesOrderList[0].Unit__r.Project__r.Name_of_Seller__c+'('+salesOrderList[0].Unit__r.Project__r.name+')'):(salesOrderList[0].Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c!=null?salesOrderList[0].Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c :salesOrderList[0].Unit__r.Project__r.BeneficiaryNameEscrow__c);
                    dd.EDDS_DDAID__c = ddWrapperObject.ddaId;
                    dd.EDDS_DDARID__c = ddWrapperObject.ddarId;
                    dd.CustomerIdType__c = ddWrapperObject.customerIdType;
                    dd.CustomerIDNumber__c = ddWrapperObject.customerIdNumber;
                    dd.CustomerAccountName__c = ddWrapperObject.customerBankAccountTitle;
                    dd.CustomerBankAccountType__c = ddWrapperObject.customerBankAccountType;
                    dd.CustomerBankName__c = ddWrapperObject.customerAccountBankName;
                    dd.CustomerIBANNumber__c = ddWrapperObject.customerBankAccountNumber;
        
                    dd.Status__c = ddWrapperObject.customerBankAccountTitle;
                    dd.CustomerAccountName__c = ddWrapperObject.customerBankAccountTitle;
        
                    dd.SalesOrder__c = ddWrapperObject.relatedRecordId;
                    dd.PayerAccount__c = ddWrapperObject.payerAccountId;
                    dd.Account__c = salesOrderList.isEmpty()?null:salesOrderList[0].Account__c;
                    dd.AmountType__c = ddWrapperObject.amountType;
                    dd.CommencesOn__c = ddWrapperObject.commencesOn!=null&&ddWrapperObject.commencesOn!=''?Date.valueOf(ddWrapperObject.commencesOn):null;
                    dd.ExpiresOn__c = ddWrapperObject.expiresOn!=null&&ddWrapperObject.expiresOn!=''?Date.valueOf(ddWrapperObject.expiresOn):null;
                    dd.PaymentFrequency__c = ddWrapperObject.paymentFrequency;
                    dd.MaximumAmount__c = ddWrapperObject.maxAmount;
                    dd.MinimumAmount__c = ddWrapperObject.minAmount;
                    dd.EDDS_DDA_Reference_Number__c = ddWrapperObject.ddaReferenceNumber;
                    dd.Status__c = 'DDS Generated';
                    upsert dd;

                    DDTransaction__c ddTransaction = new DDTransaction__c();
                    ddTransaction.RequestType__c = 'New Registration';
                    ddTransaction.TransactionStatus__c =  'Unprocessed';
                    ddTransaction.DirectDebitRequest__c = dd.Id;
                    ddTransaction.EDDS_DDA_Reference_Number__c = ddWrapperObject.ddaReferenceNumber;
                    ddTransaction.EDDS_DDAID__c = ddWrapperObject.ddaId;
                    ddTransaction.EDDS_DDARID__c = ddWrapperObject.ddarId;
                    //ddTransaction.DDBank__c = ddUpdated.DirectDebitBank__c;
                    insert ddTransaction;

                    handler.response.data = EDDSService.getDirectDebitByIdSet(new Set<Id>{dd.Id})[0];
                    handler.response.success = true;
                    handler.response.message = Constants.SUCCESS_MESSAGE;
                    handler.finalize();
                }
            }else if(ddWrapperObject.journeyType == EDDSService.JOURNEY_TYPE.NewLeasing.name()){
                // TODO: Add validation for related record id
                /*if(EDDSService.isValidSalesforceId(relatedRecordId,'Contract')==false) {
                    isError = true;
                    errorMessage += 'Provide a valid Contract Id. ';
                }*/
            }else if(ddWrapperObject.journeyType == EDDSService.JOURNEY_TYPE.Retail.name()){
                // TODO: Add validation for related record id
            }

        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.setResponseStatusCode(Constants.STATUS_CODE_SYSTEM_ERROR);
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
    }

    public class CreateDDWrapper{
        public String directDebitId;
        public String relatedRecordId;	//a2AFV000001208E2AQ
        public String payerAccountId;	//001FV000008DbGZYA0
        public String journeyType;	//NewSale
        public String amountType;	//Variable
        public String paymentFrequency;	//Monthly
        public Decimal maxAmount;	//5260000
        public Decimal minAmount;	//0
        public String ddaReferenceNumber;	//1758875554568OU#00064336
        public String expiresOn;	//
        public String commencesOn;	//26/09/2025
        public String customerMobileNumber;	//+971545127085
        public String customerEmail;	//test@pwc.com
        public String custNid;	//784199012345678
        public String customerIdNumber;	//784199012345678
        public String customerIdType;	//UAE Emirates Identity Card
        public String customerType;	//Individual
        public String customerFullName;	//Jane Doe
        public String customerBankAccountNumber;	//AE123456789123456789123
        public String customerBankAccountTitle;	//Jane Doe Thomson
        public String customerBankAccountType;	//Current
        public String customerAccountBankName;	//Abu Dhabi Commercial Bank
        public String userPreferPaymentMethod;	//Bank Account
        public String ddaId;	//914
        public String ddarId;	//795
        /*public static CreateDDWrapper parse(String json){
            return (CreateDDWrapper) System.JSON.deserialize(json, CreateDDWrapper.class);
        }*/
    }    
}