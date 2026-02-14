global class BatchToCreateBankVirtualAccount implements Database.Batchable<sObject>, Database.AllowsCallouts {
   
    /* Constants */
    public static String ADCB = 'Abu Dhabi Commercial Bank';
    public static String FAB = 'First Abu Dhabi Bank';
    public static String ADIB = 'Abu Dhabi Islamic Bank';
    public static String ACCOUNT_TYPE = 'Escrow';
    public static String COrporate_ACCOUNT_TYPE = 'Aldar Corporate';
    
    List<BankVirtualAccounts__c> bankVirtualAccounts = new List<BankVirtualAccounts__c>();
    String virtualAccountType; 
    String bankName;   
    global BatchToCreateBankVirtualAccount(List<BankVirtualAccounts__c> bankVirtualAccounts, String virtualAccountType, String bankName) {
        this.bankVirtualAccounts = bankVirtualAccounts;
        this.virtualAccountType = virtualAccountType;
        this.bankName = bankName;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, EscrowAccountNumber__c, Remarks__c,AccountType__c, Project__c, Project__r.BankNameEscrow__c, Unit__c, Unit__r.Status__c, BankName__c, Virtual_Account_Type__c,VirtualAccountNumber__c,VirtualIBANAccountNumber__c, EntityIdentifier__c, RootVA__c  FROM BankVirtualAccounts__c WHERE VirtualAccountNumber__c = null AND EscrowAccountNumber__c != null AND Virtual_Account_Type__c =:virtualAccountType AND BankName__c =:bankName AND Id In:bankVirtualAccounts';
        System.debug('query :' + query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<BankVirtualAccounts__c> scope) {  
      system.debug('scope::'+scope);
        for(BankVirtualAccounts__c bva: scope){
            
            String configName = BankVirtualAccountController.getBankConfigName(bankName);
            ALD_Bank_Configuration__mdt bankConfig;
            if(configName != ''){
                bankConfig = ALD_Bank_Configuration__mdt.getInstance(configName);
            }
            if(bva.BankName__c  == ADCB && (bva.Virtual_Account_Type__c == ACCOUNT_TYPE || bva.Virtual_Account_Type__c == COrporate_ACCOUNT_TYPE)){
                ADCBEscrowVirtualAccountCallout(bankConfig, bva);  
            }
            //FAB-Code-Comments
            /*else if(bva.BankName__c  == FAB && bva.Virtual_Account_Type__c == ACCOUNT_TYPE){
                FABEscrowVirtualAccountCallout(bankConfig, bva);
                
            }*/
            else if(bva.BankName__c  == ADIB && bva.Virtual_Account_Type__c == ACCOUNT_TYPE){
                ADIBEscrowVirtualAccountCallout(bankConfig,bva);
            }
         }
    }
    global void finish(Database.BatchableContext bc) { 
    
    }
    
    public static void ADCBEscrowVirtualAccountCallout(ALD_Bank_Configuration__mdt bankConfig, BankVirtualAccounts__c bva){
        
        String RequestBody = bankConfig.Request_Parameters_to_Create__c; 
        String NewRequestBody = RequestBody;
        bva.EscrowAccountNumber__c = Test.isRunningTest() ? '2345678' : bva.EscrowAccountNumber__c;
        NewRequestBody = NewRequestBody.replace('[REQUEST_ID]', bva.Id);
        NewRequestBody = NewRequestBody.replace('[PHYSICAL_ACC_NUMBER]', bva.EscrowAccountNumber__c);
        NewRequestBody = NewRequestBody.replace('[UNIQUE_REF_NUMBER]', bva.Id); 
        NewRequestBody = NewRequestBody.replace('[REMARKS_ANY]', '');
        CalloutToMuleSoft.calloutService(NewRequestBody, true, BankVirtualAccountController.BankIntegrationVA, new List<Id>{bva.Id}); 
    }
    
    //FAB-Code-Comments
    /*public static void FABEscrowVirtualAccountCallout(ALD_Bank_Configuration__mdt bankConfig, BankVirtualAccounts__c bva){
        String requestBody = '';//'{{"requestId":"07cf70d0-7a36-11ea-bb18-ac1c89250010","requestDateTime":"20200409110460","serviceName":"vaIBANCreation","serviceCode":"SVC0010","customerCode":"TestCorp","langCode":"EN","message":{"vaIBANList":[{ "vaRequestId":"121212235344","vaEntityId":"356","virtualAccountNo":"0000000009","virtualAccountName":"PaymentsVA9","virtualAccountType":"P","hierarchyType":"C","hierarchyName":"TestHierarchyName","parentMapping":"12232323126","alias":"","primaryID":"","emailAddress":"testva@mindgate.in","contactNumber":"1131313","addressLine1":"Abudhabi","addressLine2":"Abudhabi","addressLine3":"","enrichmentField1":"","enrichmentField2":"","enrichmentField3":"","remarks":"","vaIban":"","requestType":"N"}]}}';
        FABVirtualAccountRequestWrapper fabWrapper = new FABVirtualAccountRequestWrapper();
        cls_message message = new cls_message();
        List<cls_vaIBANList> vaIBANList = new  List<cls_vaIBANList>();
        fabWrapper.requestId = bva.Id+String.valueOf(DateTime.now().formatGMT('yyyyMMddHHmmss')); 
        fabWrapper.requestDateTime =  DateTime.now().formatGMT('yyyyMMddHHmmss');
        fabWrapper.serviceName = bva.ServiceName__c;
        fabWrapper.serviceCode = bva.ServiceCode__c; 
        fabWrapper.customerCode = bva.CustomerCode__c; 
        fabWrapper.langCode = 'EN';
        cls_vaIBANList vaIbanItem = new cls_vaIBANList();
        vaIbanItem.vaRequestId = String.valueOf(bva.Id).substring(0,15);
        vaIbanItem.vaEntityId = bva.EntityIdentifier__c;
        vaIbanItem.virtualAccountNo = bva.VirtualAccountNumber__c;
        vaIbanItem.virtualAccountName = bva.Id;
        vaIbanItem.virtualAccountType = 'B';
        vaIbanItem.hierarchyType = 'P';
        vaIbanItem.hierarchyName = bva.Id;
        vaIbanItem.parentMapping = '';
        vaIbanItem.alias = '';// Optional 
        vaIbanItem.primaryID = '';// Optional 
        vaIbanItem.emailAddress = System.label.FABVAMEmailAddress;// 'smanohar@aldar.com';
        vaIbanItem.contactNumber = System.label.FABVAMContactNumber;//'971525783669';
        vaIbanItem.addressLine1 = System.label.FABVAMAddressLine1;//'Aldar square';
        vaIbanItem.addressLine2 = System.label.FABVAMAddressLine2;//'Yas island';
        vaIbanItem.addressLine3 = System.label.FABVAMAddressLine3;//'Abu dhabi';
        vaIbanItem.enrichmentField1 = '';// Optional
        vaIbanItem.enrichmentField2 = '';// Optional
        vaIbanItem.enrichmentField3 = '';// Optional
        vaIbanItem.remarks = bva.Remarks__c; // Optional for New VA
        vaIbanItem.vaIban = ''; // Optional for New VA
        vaIbanItem.requestType = 'N'; // Always N for New VA
        vaIBANList.add(vaIbanItem);
        message.vaIBANList = vaIBANList;
        fabWrapper.message = message;
        requestBody = JSON.serialize(fabWrapper);
        System.debug('requestBody::'+requestBody);
        CalloutToMuleSoft.calloutService(requestBody, true, BankVirtualAccountController.FABBankIntegrationVA, new List<Id>{bva.Id}); 
    }
    public class FABVirtualAccountRequestWrapper {
        public String requestId;
        public String requestDateTime;    
        public String serviceName;
        public String serviceCode;
        public String customerCode;
        public String langCode;
        public cls_message message;
    }
    public class cls_message {
       public List<cls_vaIBANList> vaIBANList; 
    }
    public class cls_vaIBANList {
        public String vaRequestId;
        public String vaEntityId;
        public String virtualAccountNo; 
        public String virtualAccountName;
        public String virtualAccountType;
        public String hierarchyType;
        public String hierarchyName;
        public String parentMapping;
        public String alias;
        public String primaryID;
        public String emailAddress;
        public String contactNumber;
        public String addressLine1;
        public String addressLine2;
        public String addressLine3;
        public String enrichmentField1; 
        public String enrichmentField2;
        public String enrichmentField3; 
        public String remarks;
        public String vaIban;
        public String requestType;
    }*/
    
    public static void ADIBEscrowVirtualAccountCallout(ALD_Bank_Configuration__mdt bankConfig, BankVirtualAccounts__c bva){
        String requestBody = '';
        ADIBVirtualAccountRequestWrapper ADIBWrapper = new ADIBVirtualAccountRequestWrapper();
        
        contextWrapper contextWrap = new contextWrapper();
        
        contextWrap.interfaceId = 'VADYNAMICCREATE_E_VALIDATION';
        contextWrap.channelId = bankConfig.ChannelId__c;//'API';
        contextWrap.channelRefNumber = bva.id+String.valueOf(DateTime.now().formatGMT('yyyyMMddHHmmss'));//H2H20261000003302A
        contextWrap.bankEntityId = bankConfig.BankEntityId__c;//'IGTBAE';
        contextWrap.groupCustomerCode = ''; 
        contextWrap.customerCode = bankConfig.CustomerCode__c; // For UAT
        contextWrap.customerGuid = '';
        contextWrap.bankCode = ''; //Optional 196
        contextWrap.branchCode = ''; //Optional BRN001
        contextWrap.userId = bankConfig.UserId__c;//'ALDAR'; //Mandatory, ADIB will give the value
        
        payloadWrapper payloadWrap = new payloadWrapper();
        payloadWrap.cif = bankConfig.CIF__c; //'798413' , 237142;
        payloadWrap.virtualAccountNumber = bva.RootVA__c != null ? bva.RootVA__c : '';//'9123'
        payloadWrap.virtualAccountType =  bankConfig.virtualAccountType__c;//AS
        payloadWrap.statusva = bankConfig.statusva__c;//'A';
        
        List<cls_vaDynamicDtls> cls_vaDynamicDtlsList = new List<cls_vaDynamicDtls>();
        
        cls_vaDynamicDtls vaDynamicDtlsWrap = new cls_vaDynamicDtls();
        vaDynamicDtlsWrap.seqence = ''; //1
        vaDynamicDtlsWrap.size = ''; //2  
        vaDynamicDtlsWrap.validationRule = 'C';   
        vaDynamicDtlsWrap.staticValue = '';  //ALDAR 
        vaDynamicDtlsWrap.rangeFrom = '';   
        vaDynamicDtlsWrap.rangeUpTo = '';   
        vaDynamicDtlsWrap.listOfValues = '';   
        vaDynamicDtlsWrap.lookupValues = '';   
        vaDynamicDtlsWrap.count = '1';
        
        cls_vaDynamicDtlsList.add(vaDynamicDtlsWrap);
        payloadWrap.vaDynamicDtls = cls_vaDynamicDtlsList;
        ADIBWrapper.payload = payloadWrap;
        ADIBWrapper.context = contextWrap;
        requestBody = JSON.serialize(ADIBWrapper);
        System.debug('requestBody:: ADIB '+requestBody);
        CalloutToMuleSoft.calloutService(requestBody, true,BankVirtualAccountController.ADIBBankIntegrationVA, new List<Id>{bva.Id}); 
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
        public String cif; 
        public String virtualAccountNumber; 
        public String virtualAccountType; 
        public String statusva;
        public list<cls_vaDynamicDtls> vaDynamicDtls;
    }
    public class cls_vaDynamicDtls {
        public String seqence;   
        public String size;   
        public String validationRule;   
        public String staticValue;   
        public String rangeFrom;   
        public String rangeUpTo;   
        public String listOfValues;   
        public String lookupValues;   
        public String count;   
    } 
    
}