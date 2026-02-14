global class BatchToModifyBankVirtualAccount implements Database.Batchable<sObject>, Database.AllowsCallouts{
    
    /* Constants */
    public static String FAB = 'First Abu Dhabi Bank';
    Public static String FABBankIntegrationVAModify  = 'FABBankIntegrationVAModify';
    public static String ADIB = 'Abu Dhabi Islamic Bank';
    Public static String ADIBBankIntegrationVAModify  = 'ADIBBankIntegrationVAModify';
    
    List<String> recordIds = new List<String>();
    global BatchToModifyBankVirtualAccount(List<String> recordIds) {
        this.recordIds = recordIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String recordIdsString = String.join(recordIds, '\',\'');
        String CancelledStatus = 'Cancelled';
        String query = 'SELECT Id, EscrowAccountNumber__c, Remarks__c,AccountType__c, Project__c,'+ 
            'Project__r.BankNameEscrow__c, Unit__c, Unit__r.Status__c,Unit__r.Name, Unit__r.ADMUnitNumber__c, BankName__c, Virtual_Account_Type__c ,'+
            'VirtualAccountNumber__c,VirtualIBANAccountNumber__c, EntityIdentifier__c, '+
            'RootVA__c FROM BankVirtualAccounts__c WHERE Id '+
            'IN (\'' + recordIdsString + '\') AND StatusFlag__c !=: CancelledStatus AND SendModificationRequest__c = true';
        
        System.debug('Modify query '+query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<BankVirtualAccounts__c> scope) {
        Set<Id> unitIds = new Set<Id>();
        Map<Id, Id> bvaUnitMap = new Map<Id, Id>();
        Map<Id, SalesOrder__c> bvaSOMap = new Map<Id, SalesOrder__c>();
        for(BankVirtualAccounts__c bva: scope){
            unitIds.add(bva.Unit__c);
            bvaUnitMap.put(bva.Unit__c, bva.Id);
        }
        System.debug('bvaUnitMap '+bvaUnitMap);
        List<SalesOrder__c> SalesOrderList = [SELECT Id, Unit__c, Unit__r.Name, Unit__r.ADMUnitNumber__c, Account__c, Account__r.Name, Account__r.BillingStreet,
                                              Account__r.BillingCity, Account__r.BillingState, Account__r.BillingCountry,Account__r.BillingPostalCode,
                                              Account__r.EmailAddress__pc,Account__r.MobileNumberEnc__pc FROM SalesOrder__c 
                                              WHERE Unit__c in: unitIds AND Status__c != 'Cancelled' AND Status__c != 'Cancelled by User'];
        
        System.debug('SalesOrderList '+SalesOrderList);
        
        for(SalesOrder__c so: SalesOrderList){
           bvaSOMap.put(bvaUnitMap.get(so.Unit__c), so);
        }
        
          System.debug('bvaSOMap '+bvaSOMap);
        if(bvaSOMap != null){
            for(BankVirtualAccounts__c bva: scope){
                System.debug('Bank Name '+bva.BankName__c);
                if(bva.BankName__c  == FAB){
                    //FABEscrowModifyVirtualAccountCallout(bva, bvaSOMap);
                }else if(bva.BankName__c == ADIB){
                    ADIBEscrowModifyVirtualAccountCallout(bva, bvaSOMap);
                }            
            }  
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
    
    //FAB-Code-Comment
   /* public static void FABEscrowModifyVirtualAccountCallout(BankVirtualAccounts__c bva, Map<Id, SalesOrder__c> bvaSOMap){
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
        vaIbanItem.vaEntityId = bva.EntityIdentifier__c;
        vaIbanItem.virtualAccountNo = '';
        vaIbanItem.virtualAccountName =  bvaSOMap.get(bva.Id).Unit__r.Name.replaceAll('-', ' ');
        vaIbanItem.virtualAccountType = '';
        vaIbanItem.hierarchyType = '';// Always P
        vaIbanItem.hierarchyName = bva.Id;
        vaIbanItem.parentMapping = '';
        vaIbanItem.alias = '';// Optional 
        vaIbanItem.primaryID = '';// Optional 
        vaIbanItem.emailAddress = bvaSOMap.get(bva.Id).Account__r.EmailAddress__pc;
        vaIbanItem.contactNumber = bvaSOMap.get(bva.Id).Account__r.MobileNumberEnc__pc;
        vaIbanItem.addressLine1 = bvaSOMap.get(bva.Id).Account__r.BillingStreet+ ', '+ bvaSOMap.get(bva.Id).Account__r.BillingCity;
        vaIbanItem.addressLine2 = bvaSOMap.get(bva.Id).Account__r.BillingState+', '+bvaSOMap.get(bva.Id).Account__r.BillingCountry;
        vaIbanItem.addressLine3 = bvaSOMap.get(bva.Id).Account__r.BillingPostalCode != null ? bvaSOMap.get(bva.Id).Account__r.BillingPostalCode : '';
        vaIbanItem.enrichmentField1 = bvaSOMap.get(bva.Id).Unit__r.ADMUnitNumber__c;
        vaIbanItem.enrichmentField2 = bvaSOMap.get(bva.Id).Unit__r.Name;// Optional
        vaIbanItem.enrichmentField3 = '';// Optional
        vaIbanItem.remarks = bva.Remarks__c; 
        vaIbanItem.vaIban = bva.VirtualIBANAccountNumber__c; 
        vaIbanItem.requestType = 'M'; 
        vaIBANList.add(vaIbanItem);
        message.vaIBANList = vaIBANList;
        fabWrapper.message = message;
        requestBody = JSON.serialize(fabWrapper);
        System.debug('requestBody::'+requestBody);
        
        if(requestBody != ''){
            CalloutToMuleSoft.calloutService(requestBody, true, FABBankIntegrationVAModify, new List<Id>{bva.Id}); 
        }
        
    } */
    
    public static void ADIBEscrowModifyVirtualAccountCallout(BankVirtualAccounts__c bva, Map<Id, SalesOrder__c> bvaSOMap){
        String configName = BankVirtualAccountController.getBankConfigName(ADIB);
        ALD_Bank_Configuration__mdt bankConfig;
        if(configName != ''){
            bankConfig = ALD_Bank_Configuration__mdt.getInstance(configName);
        }        
        
        System.debug('bva for ADIB Modify batch::'+bva);
        String requestBody = '';
        ADIBVirtualAccountModifyWrapper ADIBModifyWrapper = new ADIBVirtualAccountModifyWrapper();
        
        ADIBVirtualAccountModifyWrapper.Context contextWrapper = new ADIBVirtualAccountModifyWrapper.Context();
        contextWrapper.interfaceId = 'VANUMBERMODIFY_E_VALIDATION';
		contextWrapper.channelId = bankConfig.ChannelId__c;//'API';
		contextWrapper.channelRefNumber = bva.id+String.valueOf(DateTime.now().formatGMT('yyyyMMddHHmmss'));//H2H20261000003302A
		contextWrapper.bankEntityId = bankConfig.BankEntityId__c;//'IGTBAE';
		contextWrapper.groupCustomerCode = '';
		contextWrapper.customerCode = bankConfig.CustomerCode__c;
		contextWrapper.customerGuid = '';
		contextWrapper.bankCode = bankConfig.BankCode__c;//'050';
		contextWrapper.branchCode = bankConfig.BranchCode__c;//'196';
		contextWrapper.userId = bankConfig.UserId__c;//'ALDAR';
        
        //System.debug('unit check '+bvaSOMap.get(bva.Id).Unit__r.Name);
        ADIBVirtualAccountModifyWrapper.VirtualAccounts virtualAccountWrapper = new ADIBVirtualAccountModifyWrapper.VirtualAccounts();
        virtualAccountWrapper.parentVirtualAccountNumber = bva.RootVA__c;//'9123';
        virtualAccountWrapper.vaType = bankConfig.virtualAccountType__c; //'AS'
        virtualAccountWrapper.virtualAccountNumber = bva.VirtualAccountNumber__c; // VA number
        virtualAccountWrapper.virtualAccountName = bvaSOMap.get(bva.Id) != null ? bvaSOMap.get(bva.Id).Account__r.Name : '';
        virtualAccountWrapper.vaAliasName = bvaSOMap.get(bva.Id) != null ? bvaSOMap.get(bva.Id).Unit__r.Name : '';        
        virtualAccountWrapper.remarks1 = bvaSOMap.get(bva.Id) != null ? bvaSOMap.get(bva.Id).Unit__r.ADMUnitNumber__c : '';
        virtualAccountWrapper.status = bankConfig.statusva__c;//'A';
        
        ADIBVirtualAccountModifyWrapper.Payload payLoadWrapper = new ADIBVirtualAccountModifyWrapper.Payload();
        payLoadWrapper.virtualAccounts = virtualAccountWrapper;
        payLoadWrapper.customerRootVa = bva.RootVA__c;//'9123';
        payLoadWrapper.cif = bankConfig.CIF__c;//'798413', 237142;
        
        ADIBModifyWrapper.context = contextWrapper;
        ADIBModifyWrapper.payload = payLoadWrapper;
        
        requestBody = JSON.serialize(ADIBModifyWrapper);
        System.debug('requestBody:: ADIBModifyWrapper '+requestBody);
        
        if(requestBody != ''){
            CalloutToMuleSoft.calloutService(requestBody, true, ADIBBankIntegrationVAModify, new List<Id>{bva.Id});
        }        
        
    }    
    
}