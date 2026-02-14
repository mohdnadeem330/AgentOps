global class BatchToCancelBankVirtualAccount implements Database.Batchable<sObject>, Database.AllowsCallouts{

    List<String> recordIds = new List<String>();
    
    global BatchToCancelBankVirtualAccount(List<String> recordIds) {
        this.recordIds = recordIds;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String recordIdsString = String.join(recordIds, '\',\'');
        String query = 'SELECT Id, EscrowAccountNumber__c, Remarks__c,AccountType__c, Project__c, Project__r.BankNameEscrow__c, Unit__c, Unit__r.Status__c, BankName__c, Virtual_Account_Type__c,VirtualAccountNumber__c,VirtualIBANAccountNumber__c, EntityIdentifier__c FROM BankVirtualAccounts__c WHERE VirtualAccountClosureDate__c = NULL AND Id IN (\'' + recordIdsString + '\') AND StatusFlag__c=\''+String.escapeSingleQuotes(ALD_Constants.ALDVA_STATUS_CANCELLED)+'\'';
        System.debug('query '+query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<BankVirtualAccounts__c> scope) {
        
        System.debug('scope '+scope);
        for(BankVirtualAccounts__c bva: scope){
            String configName = BankVirtualAccountController.getBankConfigName(bva.BankName__c);
            ALD_Bank_Configuration__mdt bankConfig;
            
            //Abu Dhabi Commercial Bank
            if(bva.BankName__c  == BatchToCreateBankVirtualAccount.ADCB){
                ADCBEscrowCloseVirtualAccountCallout(bankConfig, bva);
                
            }//First Abu dhabi Bank
            else if(bva.BankName__c  == BatchToCreateBankVirtualAccount.FAB){
                //FABEscrowCloseVirtualAccountCallout(bva);
            }//Abu Dhabi Islamic Bank
            else if(bva.BankName__c  == BatchToCreateBankVirtualAccount.ADIB){
                ADIBEscrowCloseVirtualAccountCallout(bva);
            }
        }
    }
    global void finish(Database.BatchableContext bc) {
        
    }
    
    
    public static void ADCBEscrowCloseVirtualAccountCallout(ALD_Bank_Configuration__mdt bankConfig, BankVirtualAccounts__c bva){
        String RequestBody = bankConfig.Request_Parameters_to_Cancel__c;
        String NewRequestBody = RequestBody;
        NewRequestBody = NewRequestBody.replace('[REQUEST_ID]', bva.Id);
        NewRequestBody = NewRequestBody.replace('[PHYSICAL_ACC_NUMBER]', bva.EscrowAccountNumber__c);
        NewRequestBody = NewRequestBody.replace('[VIRTUAL_ACC_NUMBER]', bva.VirtualAccountNumber__c);
        System.debug('NewRequestBody -> '+NewRequestBody); 
        CalloutToMuleSoft.calloutService(NewRequestBody, true, BankVirtualAccountController.BankIntegrationVACancel, new List<Id>{bva.Id});
    }
    
    //FAB-Code-Comment
    /*public static void FABEscrowCloseVirtualAccountCallout(BankVirtualAccounts__c bva){
        system.debug('bva::'+bva);
        String requestBody = '';
        BatchToCreateBankVirtualAccount.FABVirtualAccountRequestWrapper fabWrapper = new BatchToCreateBankVirtualAccount.FABVirtualAccountRequestWrapper();
        BatchToCreateBankVirtualAccount.cls_message message = new BatchToCreateBankVirtualAccount.cls_message();
        List<BatchToCreateBankVirtualAccount.cls_vaIBANList> vaIBANList = new  List<BatchToCreateBankVirtualAccount.cls_vaIBANList>();
        fabWrapper.requestId = bva.Id+String.valueOf(DateTime.now().formatGMT('yyyyMMddHHmmss')); 
        fabWrapper.requestDateTime =  DateTime.now().formatGMT('yyyyMMddHHmmss');
        fabWrapper.serviceName = bva.ServiceName__c;
        fabWrapper.serviceCode = bva.ServiceCode__c; 
        fabWrapper.customerCode = bva.CustomerCode__c; 
        fabWrapper.langCode = 'EN';
        BatchToCreateBankVirtualAccount.cls_vaIBANList vaIbanItem = new BatchToCreateBankVirtualAccount.cls_vaIBANList();
        vaIbanItem.vaRequestId = String.valueOf(bva.Id).substring(0,15);
        vaIbanItem.vaEntityId = '';
        vaIbanItem.virtualAccountNo = bva.VirtualAccountNumber__c;
        vaIbanItem.vaIban = bva.VirtualIBANAccountNumber__c;//'AE780355417000006200005';//bva.VirtualIBANAccountNumber__c; 
        vaIbanItem.virtualAccountName = '';
        vaIbanItem.virtualAccountType = '';
        vaIbanItem.hierarchyType = '';
        vaIbanItem.hierarchyName = '';
        vaIbanItem.parentMapping = '';
        vaIbanItem.alias = '';
        vaIbanItem.primaryID = '';
        vaIbanItem.emailAddress = '';
        vaIbanItem.contactNumber = '';
        vaIbanItem.addressLine1 = '';
        vaIbanItem.addressLine2 = '';
        vaIbanItem.addressLine3 = '';
        vaIbanItem.enrichmentField1 = '';
        vaIbanItem.enrichmentField2 = '';
        vaIbanItem.enrichmentField3 = '';
        vaIbanItem.remarks = 'Unit Cancelled or Transferred'; 
        vaIbanItem.requestType = 'D'; 
        vaIBANList.add(vaIbanItem);
        message.vaIBANList = vaIBANList;
        fabWrapper.message = message;
        requestBody = JSON.serialize(fabWrapper);
        System.debug('requestBody::'+requestBody);
        CalloutToMuleSoft.calloutService(requestBody, true, BankVirtualAccountController.FABBankIntegrationVACancel, new List<Id>{bva.Id}); 
    }*/
    
    
    public static void ADIBEscrowCloseVirtualAccountCallout(BankVirtualAccounts__c bva){
        
        system.debug('bva adib::'+bva);
        
        String configName = BankVirtualAccountController.getBankConfigName(BatchToModifyBankVirtualAccount.ADIB);
        ALD_Bank_Configuration__mdt bankConfig;
        if(configName != ''){
            bankConfig = ALD_Bank_Configuration__mdt.getInstance(configName);
        }      
                
        String requestBody = '';
        ADIBVirtualAccountRequestWrapper ADIBWrapper = new ADIBVirtualAccountRequestWrapper();
        
        contextWrapper contextWrap = new contextWrapper();
        
        contextWrap.interfaceId = 'VACLOSURECREATE_E_VALIDATION';
        contextWrap.channelId = bankConfig.ChannelId__c;//'API';
        contextWrap.channelRefNumber = bva.id+String.valueOf(DateTime.now().formatGMT('yyyyMMddHHmmss'));
        contextWrap.bankEntityId = bankConfig.BankEntityId__c;//'IGTBAE';
        contextWrap.groupCustomerCode = ''; 
        contextWrap.customerCode = bankConfig.CustomerCode__c;
        contextWrap.customerGuid = '';
        contextWrap.bankCode = bankConfig.BankCode__c;//'050'; 
        contextWrap.branchCode = bankConfig.BranchCode__c;//'196'; 
        contextWrap.userId = bankConfig.UserId__c;//'ALDAR';
        
        payloadWrapper payloadWrap = new payloadWrapper();
        
        payloadWrap.virtualAccountNumber = bva.VirtualAccountNumber__c;
        Datetime myDT = system.now();
        String myDate = myDT.format('dd-MM-yyyy');
        payloadWrap.closureDate = myDate;
        payloadWrap.reasonForClosure =  'Unit Cancelled or VA is no more active';
        //payloadWrap.settlementAccountNumber ='';// '9123000000006';
        ADIBWrapper.payload = payloadWrap;
        ADIBWrapper.context = contextWrap;
        requestBody = JSON.serialize(ADIBWrapper);
        System.debug('requestBody::'+requestBody);                
        CalloutToMuleSoft.calloutService(requestBody, true, BankVirtualAccountController.ADIBBankIntegrationVACancel, new List<Id>{bva.Id});
    }
    
    public class ADIBVirtualAccountRequestWrapper {
        public contextWrapper context;
        public payloadWrapper payload;
    }
    
    public class contextWrapper {
        public String interfaceId; 
        public String channelId; 
        public String channelRefNumber; 
        public String bankEntityId; 
        public String groupCustomerCode; 
        public String customerCode; 
        public String customerGuid; 
        public String bankCode; 
        public String branchCode; 
        public String userId; 
    }
    public class payloadWrapper {
        public String virtualAccountNumber; 
        public String closureDate;
        public String reasonForClosure;
        //public String settlementAccountNumber;
    }
}