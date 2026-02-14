/**********************************************************************************************************************
* Name              : DirectDebitService                                                        
* Description       : This Apex class will be a helper class for DirectDebitRequest__c trigger
* Method			: getSalesOrderDetailsForDDS	- get salesorders details
: populateDefaultValues			- populate all the important field values for DD from metaData
: getDirectDebitDefaultValues	- get directdebit default values from custom metadata
: getBankEntityIDValues			- get all banks paying ID code
: getMaximumAmount				- get maximum amount from the installment lines excluding SPA & handover
: checkForExistingActiveDDR		- 
: replicateDDRonOtherSalesOrders- 
: createApexInfoLog				- Information logged in Logger Object for data not found
* Created By        : tdontha@aldar.com - Tharun    
* Last Modified By	: tdontha@aldar.com - Tharun
******************************************************************************************************************/

public class DirectDebitService {
    public static String ClassName 									= 'DirectDebitService';
    public static String DOCUMENT_PLACEHOLDER_CATEGORY_DIRECT_DEBIT = 'Direct Debit';
    public static String LOG_TYPE_INFORMATION 						= 'Information';
    public static String LOG_PROCESS_NAME	 						= 'DirectDebit';
    public static String Cancellationinprogress                     = System.Label.Cancellationinprogress;
    public static String Cancelled                                  = System.Label.Cancelled;
    public static String RejectedbyBank                             = System.Label.RejectedbyBank;
    public static String CancellationSentToBank                     = 'Cancellation Sent to Bank';
    public static List<String> cancelledOrRejectedList              = new List<String>{Cancellationinprogress,Cancelled,RejectedbyBank, CancellationSentToBank};
        
     @AuraEnabled
    public static DDInitWrapper getSalesOrderAccountDetails(Id salesOrderId) {
        Id recordId = salesOrderId;
        String sObjName = salesOrderId.getSObjectType().getDescribe().getName();
        
        if(sObjName == 'HexaBPM__Service_Request__c') {
            HexaBPM__Service_Request__c sr = [SELECT Id, SalesOrder__c FROM HexaBPM__Service_Request__c WHERE Id=:salesOrderId LIMIT 1];
            salesOrderId = sr.SalesOrder__c;
        }

        DDInitWrapper initWrapper = new DDInitWrapper();
        initWrapper.salesOrderRecord = getSalesOrderDetailsForDDS(salesOrderId);
        initWrapper.submitFromObject = sObjName;
        initWrapper.relationShips = (sObjName == 'HexaBPM__Service_Request__c' ? getRelatedAccountRelationship(recordId) : CreateJointOwnersController.getRelatedAccountNames(salesOrderId));
        //initWrapper.serviceRequest = (sObjName == 'HexaBPM__Service_Request__c' ? getServiceRequestForDDS(recordId) : new HexaBPM__Service_Request__c());
        system.debug('initWrapper:::'+initWrapper);
        return initWrapper;
    }

  /* @AuraEnabled
    public static String updateServiceRequest(String ddrId, String recordId) {
        try {
            HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c();
            sr.Id = recordId;
           // sr.Direct_Debit_Request__c = ddrId;
            update sr;
            return 'success';
        } catch (Exception e) {
            throw newMessageException('Error : ' + e.getMessage());
        }
    } 

    private static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    } */
    
    public class DDInitWrapper {
        @AuraEnabled
        public SalesOrder__c salesOrderRecord;
        @AuraEnabled
        public List<AccountRelationship__c> relationShips;
        @AuraEnabled
        public String submitFromObject;
        @AuraEnabled
        public HexaBPM__Service_Request__c serviceRequest;
    }
    
    @AuraEnabled
    public static SalesOrder__c getSalesOrderDetailsForDDS(Id salesOrderId){
        return [SELECT 
                Id,
                Account__c, 
                Name,
                AccountNationalityIDNumber__c,
                Account__r.Name,
                Account__r.IsPersonAccount,
                Account__r.NationalIdNumber__pc,
                Account__r.PassportNumber__pc,
                Account__r.FirstName,
                Account__r.MiddleName,
                Account__r.LastName,
                Account__r.RegistrationNumber__c,                 
                Unit__r.Project__r.StartDate__c,
                Unit__r.Project__r.EndDate__c
                FROM 
                SalesOrder__c 
                WHERE 
                Id=:salesOrderId];
    }

   /* @AuraEnabled
    public static HexaBPM__Service_Request__c getServiceRequestForDDS(Id serviceRequestId){
        return [SELECT 
                Id,
                BuyerName__c, 
                Name,
                //AccountNationalityIDNumber__c,
                BuyerName__r.Name,
                BuyerName__r.IsPersonAccount,
                BuyerName__r.NationalIdNumber__pc,
                BuyerName__r.PassportNumber__pc,
                BuyerName__r.FirstName,
                BuyerName__r.MiddleName,
                BuyerName__r.LastName,
                BuyerName__r.RegistrationNumber__c,
                Unit__r.Project__r.StartDate__c,
                Unit__r.Project__r.EndDate__c
                FROM 
                HexaBPM__Service_Request__c 
                WHERE 
                Id =:serviceRequestId];
    } */

    public static List<AccountRelationship__c> getRelatedAccountRelationship(Id recordId){
        try {
            Set<Id> accountRelIds = new Set<Id>();
            List<String> accountRelRelationType = new List<String>();
            List<AccountRelationship__c> accountNames = new List<AccountRelationship__c>();
            HexaBPM__Service_Request__c serviceRequest = [SELECT Id, BuyerName__c FROM HexaBPM__Service_Request__c WHERE Id =:recordId LIMIT 1];

            if(serviceRequest.BuyerName__c != null){
                Account acctWithRelationships = [SELECT Id, (SELECT Id, RelatedAccount__c FROM AccountRelationships__r WHERE RelatedAccount__c != null ) FROM Account WHERE Id =:serviceRequest.BuyerName__c];
                if(!acctWithRelationships.AccountRelationships__r.isEmpty()) {
                    for(AccountRelationship__c acr : acctWithRelationships.AccountRelationships__r) {
                        accountRelIds.add(acr.Id); 
                    }
                }
            }

            if(!accountRelIds.isEmpty()){
                accountNames = AccountRelationshipService.getAccountRelationshipType(accountRelIds);
            }

            return  accountNames;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static void populateOwner(List<DirectDebitRequest__c> ddList){
        Set<Id> salesOrderIdSet = new Set<Id>();
        for(DirectDebitRequest__c dd : ddList){
            salesOrderIdSet.add(dd.SalesOrder__c);
        }

        Map<Id,SalesOrder__c> soMap = new Map<Id,SalesOrder__c>([SELECT Id, Account__c, Name,
                                                                     SalesManager__c,
                                                                     SalesManager__r.ManagerId 
                                                                     FROM SalesOrder__c 
                                                                     WHERE Id IN: salesOrderIdSet]);
        for(DirectDebitRequest__c dd : ddList){
            if(soMap.containsKey(dd.SalesOrder__c)){
                if(soMap.get(dd.SalesOrder__c).SalesManager__c != null){
                    dd.OwnerId = soMap.get(dd.SalesOrder__c).SalesManager__c;
                }
            }            
        }
    }
        
    public static void populateDefaultValues(List<DirectDebitRequest__c> ddList){
        //try{
            Set<Id> salesOrderIdSet 								= new Set<Id>();
            Map<String, DirectdebitDefaultvalues__mdt> allDDValues 	= new Map<String, DirectdebitDefaultvalues__mdt>();
            allDDValues         									= getDirectDebitDefaultValues();
            system.debug('allDDValues::'+allDDValues);
            Map<String, BankRoutingCodes__mdt> allBankCodeValues 	= new Map<String, BankRoutingCodes__mdt>();
            allBankCodeValues   									= getBankEntityIDValues();
            
            for(DirectDebitRequest__c dd : ddList){
                salesOrderIdSet.add(dd.SalesOrder__c);
            }
            Map<Id,SalesOrder__c> soMap = new Map<Id,SalesOrder__c>([SELECT Id, Account__c, Name, NetAmount__c,Account__r.Name, 
                                                                     Unit__r.Project__r.StartDate__c,
                                                                     Unit__r.Project__r.EndDate__c,
                                                                     Unit__r.Project__r.BankNameEscrow__c,
                                                                     Unit__r.Project__r.BeneficiaryNameEscrow__c,
                                                                     Unit__r.Project__r.Name,
                                                                     Unit__r.Project__r.Name_of_Seller__c,
                                                                     Unit__r.ExpectedCustomerHandoverDate__c,
                                                                     Unit__r.BuildingSectionName__r.BankNameEscrow__c,
                                                                     Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c,
                                                                     Unit__r.BuildingSectionName__r.Name,
                                                                     Unit__r.BuildingSectionName__r.StartDate__c,
                                                                     Unit__r.BuildingSectionName__r.EndDate__c,
                                                                     Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c,//SSR-273
                                                                     SalesManager__r.Email,
                                                                     SalesManager__r.Manager.Email,
                                                                     SalesManager__c,
                                                                     SalesManager__r.ManagerId,
                                                                     (SELECT ID,InstallmentNumber__c, 
                                                                      InstallmentAmount__c,InstallmentDate__c 
                                                                      FROM InstallmentLines__r 
                                                                      ORDER BY InstallmentNumber__c ASC )
                                                                     FROM SalesOrder__c 
                                                                     WHERE Id IN: salesOrderIdSet]);
            
            for(DirectDebitRequest__c dd : ddList){
                if(soMap.containsKey(dd.SalesOrder__c) && dd.Is_EDDS__c == FALSE && (soMap.get(dd.SalesOrder__c).Unit__r.Project__r.BankNameEscrow__c != null || soMap.get(dd.SalesOrder__c).Unit__r.BuildingSectionName__r.BankNameEscrow__c != null)) {
                  if(soMap.get(dd.SalesOrder__c).SalesManager__c != null){
                        dd.SalesManagerEmail__c             = soMap.get(dd.SalesOrder__c).SalesManager__r.Email != null? soMap.get(dd.SalesOrder__c).SalesManager__r.Email : null;
                    }
                    if(soMap.get(dd.SalesOrder__c).SalesManager__r.ManagerId != null){
                        dd.LineManagersEmail__c             = soMap.get(dd.SalesOrder__c).SalesManager__r.Manager.Email != null? soMap.get(dd.SalesOrder__c).SalesManager__r.Manager.Email:null;
                    }
                    String EscrowDirectDebitBank 			=  soMap.get(dd.SalesOrder__c).Unit__r.BuildingSectionName__r.BankNameEscrow__c != null ? soMap.get(dd.SalesOrder__c).Unit__r.BuildingSectionName__r.BankNameEscrow__c:  soMap.get(dd.SalesOrder__c).Unit__r.Project__r.BankNameEscrow__c;
                    
                    if((!allDDValues.isEmpty() || allDDValues <> null) && allDDValues.KeySet().contains(EscrowDirectDebitBank)){
                         system.debug('populate default values');
                        Date dateToday 						= Date.today();
                        
                        // For All Banks
                        dd.DirectDebitBank__c				= EscrowDirectDebitBank;
                        dd.CommencesOn__c 					= Date.valueOf(Datetime.now().format('yyyy-MM-dd'));
                        dd.ExpiresOn__c 					= soMap.get(dd.SalesOrder__c).Unit__r.ExpectedCustomerHandoverDate__c <> null ? soMap.get(dd.SalesOrder__c).Unit__r.ExpectedCustomerHandoverDate__c.addYears(1) : null ;
                        dd.PaymentFrequency__c 				= allDDValues.get(EscrowDirectDebitBank).PaymentFrequency__c;
                        dd.MinimumAmount__c 				= allDDValues.get(EscrowDirectDebitBank).MinimumAmount__c;
                        dd.MaximumAmount__c 				= soMap.get(dd.SalesOrder__c).InstallmentLines__r.size() > 1 ? getMaximumAmount(soMap.get(dd.SalesOrder__c).InstallmentLines__r)  :  0;
                        //dd.MaximumAmount__c 				= 10;
                        // Arvind - Chnaged the OriginatorName, Get the Name of Selller from project
                        //dd.OriginatorName__c                = EscrowDirectDebitBank == 'First Abu Dhabi Bank' ? ('Aldar Properties PJSC ('+soMap.get(dd.SalesOrder__c).Unit__r.Project__r.name + ')') : (soMap.get(dd.SalesOrder__c).Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c != null ? soMap.get(dd.SalesOrder__c).Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c: soMap.get(dd.SalesOrder__c).Unit__r.Project__r.BeneficiaryNameEscrow__c);
                        dd.OriginatorName__c                  = EscrowDirectDebitBank == 'First Abu Dhabi Bank' ? (soMap.get(dd.SalesOrder__c).Unit__r.Project__r.Name_of_Seller__c +  '(' + soMap.get(dd.SalesOrder__c).Unit__r.Project__r.name + ')') :(soMap.get(dd.SalesOrder__c).Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c != null ?soMap.get(dd.SalesOrder__c).Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c :soMap.get(dd.SalesOrder__c).Unit__r.Project__r.BeneficiaryNameEscrow__c);
                        //allDDValues.get(EscrowDirectDebitBank).OriginatorName__c;
                        dd.FirstInitiationDate__c 			= Date.valueOf(Datetime.now().format('yyyy-MM-dd'));
                        dd.IssuedFor__c 					= allDDValues.get(EscrowDirectDebitBank).IssuedFor__c;
                        dd.DDAPurposeCode__c 				= allDDValues.get(EscrowDirectDebitBank).DDA_PurposeCode__c;
                        dd.AmountType__c 					= allDDValues.get(EscrowDirectDebitBank).AmountType__c;
                        dd.FrequencyParameter__c 			= String.valueOf(DateTime.now().format('MMM').toUpperCase()) + String.valueof(dateToday.day()) ;
                        dd.Account__c 						= soMap.get(dd.SalesOrder__c).Account__c != null? soMap.get(dd.SalesOrder__c).Account__c : null;
                        dd.PrimarySponsoringname__c         = allDDValues.get(EscrowDirectDebitBank).PrimarySponsoringname__c;
                        
                        // For ADCB specific
                        dd.RecordIdentifier__c 				= allDDValues.get(EscrowDirectDebitBank).RecordIdentifier__c;
                        dd.RequestingBankReferenceNumber__c	= String.valueof(dateToday.year()).right(2) + String.valueof(dateToday.month()).leftPad(2, '0') + String.valueof(dateToday.day()).leftPad(2, '0') ;
                        dd.RequestingBankSequenceNumber__c 	= allDDValues.get(EscrowDirectDebitBank).RequestingBankSequenceNumber__c;
                        dd.DebitRequestInstanceAllowed__c 	= allDDValues.get(EscrowDirectDebitBank).DebitRequestInstanceAllowed__c;
                        dd.CaptureMode__c 					= allDDValues.get(EscrowDirectDebitBank).CaptureMode__c;
                        //dd.PayingBankID__c 					= allDDValues.get(EscrowDirectDebitBank).PayingBank_ID__c;
                        
                        //Below code to fetch ENTITYID__c from allBankCodeValues
                        System.debug('CustomerBankName__c----->'+dd.CustomerBankName__c);
                        if(!allBankCodeValues.isEmpty() && allBankCodeValues.Keyset().contains(dd.CustomerBankName__c)){
                            dd.PayingBankID__c  = allBankCodeValues.get(dd.CustomerBankName__c).ENTITYID__c;
                            dd.PayingBankRoutingCode__c = allBankCodeValues.get(dd.CustomerBankName__c).ROUTING_CODE__c;
                        }else{
                            // Specified bank is not found in CustomMetadata
                            String StackTrace = 'CustomerBankName__c - '+dd.CustomerBankName__c+'\n'+'\n'+'allBankCodeValues.KeySet() - '+allBankCodeValues.KeySet();
                            LoggerService.save(DirectDebitService.createApexInfoLog('Bank paying ID is not found in BankRoutingCodes__mdt CustomMetadata', LOG_PROCESS_NAME, ClassName, 'populateDefaultValues', StackTrace));
                        }
                        
                    }
                    else{
                        // Specified bank is not found in CustomMetadata
                        String StackTraceRecord = 'EscrowDirectDebitBank - '+EscrowDirectDebitBank+'\n'+'\n'+'allDDValues.KeySet() - '+allDDValues.KeySet();
                        LoggerService.save(DirectDebitService.createApexInfoLog('Escrow bank for the project is not found in DirectdebitDefaultvalues__mdt CustomMetadata',
                                                                                LOG_PROCESS_NAME,
                                                                                ClassName,
                                                                                'populateDefaultValues',
                                                                                StackTraceRecord));
                    }
                }
            }
            
       /* }catch(Exception ex){
            LoggerService.save(LoggerService.createApexLog(ex,LOG_PROCESS_NAME,ClassName,'populateDefaultValues'));
        } */
    }
    
    
    
    
    //Added by Tharun to get all DD Default values
    public static Map<String, DirectdebitDefaultvalues__mdt> getDirectDebitDefaultValues(){
        Map<String, DirectdebitDefaultvalues__mdt> ddValues = new Map<String, DirectdebitDefaultvalues__mdt>();
        try{
            List<DirectdebitDefaultvalues__mdt> ddValuesList = [SELECT Id, DeveloperName, DDA_PurposeCode__c, MinimumAmount__c, IssuedFor__c, BankName__c,
                                                                PayingBank_ID__c, PaymentFrequency__c, ProjectEscrowBankName__c, AmountType__c,
                                                                RequestingBankSequenceNumber__c, DebitRequestInstanceAllowed__c,
                                                                CaptureMode__c, RecordIdentifier__c, OriginatorName__c, PrimarySponsoringname__c
                                                                FROM DirectdebitDefaultvalues__mdt];
            
            for(DirectdebitDefaultvalues__mdt ddSingle :ddValuesList){
                ddValues.put(ddSingle.BankName__c,ddSingle);
            }
            system.debug('ddValues:::'+ddValues.get('First Abu Dhabi Bank'));
            return ddValues; 
        }
        catch(exception ex){
            LoggerService.save(LoggerService.createApexLog(ex,LOG_PROCESS_NAME,ClassName,'getDirectDebitDefaultValues'));
            return null;
        }
    }
    
    
    //Added by Tharun to get all the ENTITYID for Banks
    public static Map<String, BankRoutingCodes__mdt> getBankEntityIDValues(){
        try  {
            Map<String, BankRoutingCodes__mdt> brValues = new Map<String, BankRoutingCodes__mdt>();
            List<BankRoutingCodes__mdt> brValuesList = [SELECT
                                                        Id,
                                                        ENTITYID__c,
                                                        ENTITYNAME__c,
                                                        ENTITYTYPE__c,
                                                        ROUTING_CODE__c
                                                        FROM BankRoutingCodes__mdt];
            for(BankRoutingCodes__mdt brSingle :brValuesList){
                brValues.put(brSingle.ENTITYNAME__c,brSingle);
            }
            return brValues;
        }
        catch(exception ex)
        {
            LoggerService.save(LoggerService.createApexLog(ex,LOG_PROCESS_NAME,ClassName,'getBankEntityIDValues'));
            return null;
        }
    }
    
    
    //Added by Tharun to get maximum amount from the installment lines excluding SPA & handover
    public static Double getMaximumAmount(List<InstallmentLines__c> installmentLinesList)
    {
        try{
            Double finalAmount = 0;
            if(installmentLinesList.size() > 1){
                installmentLinesList.remove(0);
                
                if(Label.DDPaymentConsiderHandover == 'false' ){
                    installmentLinesList.remove(installmentLinesList.size() -1);
                }
                
                for (InstallmentLines__c singleIL : installmentLinesList){
                    if(finalAmount < singleIL.InstallmentAmount__c){
                        finalAmount = singleIL.InstallmentAmount__c;
                    }
                }
            }
            return finalAmount;
        }
        catch(exception ex){
            LoggerService.save(LoggerService.createApexLog(ex,LOG_PROCESS_NAME,ClassName,'getMaximumAmount'));
            return null;
        }
    }
    public static void checkForExistingActiveDDR (List<DirectDebitRequest__c> ddList){
        Map<Id, List<DirectDebitRequest__c>> salesOrderDDRMap = new Map<Id, List<DirectDebitRequest__c>>();
        Set<Id> salesOrderIdSet = new Set<Id>();
        for(DirectDebitRequest__c directDebitRequest: ddList) {
            if(!directDebitRequest.Skip_off_plan_ddr_validation__c || Trigger.isUpdate) // this condition added by daksh to create record from live aldar
            {
                salesOrderIdSet.add(directDebitRequest.SalesOrder__c);
            }
        }
        List<DirectDebitRequest__c> allOtherDirectDebitRequests = [SELECT
                                                                   Id,
                                                                   SalesOrder__c
                                                                   FROM DirectDebitRequest__c
                                                                   WHERE SalesOrder__c IN: salesOrderIdSet
                                                                   AND Id Not in: ddList
                                                                  // AND SalesOrder__r.Has_Active_DirectDebit__c = true];
                                                                   AND Status__c  NOT IN: cancelledOrRejectedList];
                                                                 
        system.debug('allOtherDirectDebitRequests::'+allOtherDirectDebitRequests);
        for(DirectDebitRequest__c directDebitRequest: allOtherDirectDebitRequests) {
            List<DirectDebitRequest__c> directDebitRequestList = salesOrderDDRMap.get(directDebitRequest.SalesOrder__c) != null ?  salesOrderDDRMap.get(directDebitRequest.SalesOrder__c) : new List<DirectDebitRequest__c>();
            directDebitRequestList.add(directDebitRequest);
            salesOrderDDRMap.put(directDebitRequest.SalesOrder__c, directDebitRequestList); 
        }
        
        for(DirectDebitRequest__c directDebitRequest: ddList) {
            if(salesOrderDDRMap.get(directDebitRequest.SalesOrder__c) != Null &&
               (directDebitRequest.Status__c != System.Label.Cancellationinprogress &&  directDebitRequest.Status__c != System.Label.Cancelled && directDebitRequest.Status__c != System.Label.RejectedbyBank && directDebitRequest.Status__c != 'Cancellation Sent to Bank')) {
                   directDebitRequest.addError(System.Label.DirectDebitForOneErrorMessage);
               }
        }
    }
    
    public static void replicateDDRonOtherSalesOrders(List<DirectDebitRequest__c> ddList) {
        
        List<DirectDebitRequest__c> directDebitRequestListToInsert = new List<DirectDebitRequest__c>();
        List<Id> salesOrder_Ids = new List<Id>();
        Map<Id, Id> ddrSOMap = new Map<Id, Id>(); 
        List<SalesOrder__c> allOtherSalesOrderList = new List<SalesOrder__c>();
        Map<Id, List<SalesOrder__c>> opportunitySOMap = new Map<Id, List<SalesOrder__c>>();
        List<DirectDebitRequest__c> allDirectDebitTransactions = [SELECT 
                                                                  Id,
                                                                  SalesOrder__c,
                                                                  CustomerIdType__c,
                                                                  SalesOrder__r.Opportunity__c,
                                                                  CustomerBankAccountType__c,
                                                                  CustomerBankName__c,
                                                                  CustomerIDNumber__c,
                                                                  CustomerAccountName__c,
                                                                  CustomerIBANNumber__c,
                                                                  Replicate_same_on_other_Sales_Order__c
                                                                  FROM DirectDebitRequest__c
                                                                  WHERE Id in: ddList ];
        if(allDirectDebitTransactions.size()>0){
            for(DirectDebitRequest__c ddr: allDirectDebitTransactions){
                if(ddr.Replicate_same_on_other_Sales_Order__c){
                    salesOrder_Ids.add(ddr.SalesOrder__c);
                    ddrSOMap.put(ddr.Id, ddr.SalesOrder__r.Opportunity__c);
                }
            }
        }
        if(ddrSOMap.values().size()>0){
            allOtherSalesOrderList = [SELECT Id,
                                      Opportunity__c,
                                      (SELECT Id FROM Direct_Debit_Request__r)
                                      FROM SalesOrder__c
                                      WHERE Id NOT in: salesOrder_Ids
                                      AND Opportunity__c in: ddrSOMap.values()]; 
        }
        
        if(allOtherSalesOrderList.size()>0){
            for(SalesOrder__c salesOrder: allOtherSalesOrderList){
                List<SalesOrder__c> salesOrderList = opportunitySOMap.get(salesOrder.Opportunity__c) != null ? opportunitySOMap.get(salesOrder.Opportunity__c) : new List<SalesOrder__c>();
                salesOrderList.add(salesOrder);
                opportunitySOMap.put(salesOrder.Opportunity__c, salesOrderList);
            }
        }
        
        
        for(DirectDebitRequest__c ddr:  ddList){
            if(ddr.Replicate_same_on_other_Sales_Order__c && ddr.Is_EDDS__c == false){
                if(ddrSOMap.get(ddr.Id) != null && opportunitySOMap.get(ddrSOMap.get(ddr.Id)) != null){
                    if(!opportunitySOMap.get(ddrSOMap.get(ddr.Id)).isEmpty()){
                        for(SalesOrder__c salesOrder: opportunitySOMap.get(ddrSOMap.get(ddr.Id))){
                            if(salesOrder.Direct_Debit_Request__r.isEmpty()){
                                DirectDebitRequest__c directDebitRequestForOtherSOs      = new DirectDebitRequest__c();
                                directDebitRequestForOtherSOs.SalesOrder__c              = salesOrder.Id;
                                directDebitRequestForOtherSOs.CustomerIdType__c          = ddr.CustomerIdType__c;
                                directDebitRequestForOtherSOs.CustomerBankAccountType__c = ddr.CustomerBankAccountType__c;
                                directDebitRequestForOtherSOs.CustomerBankName__c        = ddr.CustomerBankName__c;
                                directDebitRequestForOtherSOs.CustomerIDNumber__c        = ddr.CustomerIDNumber__c;
                                directDebitRequestForOtherSOs.CustomerAccountName__c     = ddr.CustomerAccountName__c;
                                directDebitRequestForOtherSOs.CustomerIBANNumber__c      = ddr.CustomerIBANNumber__c; 
                                directDebitRequestForOtherSOs.Account__c                 = ddr.Account__c;
                                directDebitRequestForOtherSOs.PayerAccount__c                 = ddr.PayerAccount__c;
                                directDebitRequestListToInsert.add(directDebitRequestForOtherSOs); 
                            }   
                        } 
                    }
                }
            } 
        }
        if(!directDebitRequestListToInsert.isEmpty()){
            insert directDebitRequestListToInsert;
        }
    }
    Public static void updateSODDRN(List<DirectDebitRequest__c> ddList){
        Set<Id> salesOrderIdSet = new Set<Id>();
        List<SalesOrder__c> salesOrderToUpdate = new List<SalesOrder__c>();
        for(DirectDebitRequest__c ddr: ddList){
            if(ddr.Status__c == System.Label.Cancelled) {
                salesOrderIdSet.add(ddr.SalesOrder__c);
            }
        }
        List<SalesOrder__c> salesOrderList = [SELECT 
                                              Id,
                                              Directdebitauthorityreferencenumber__c
                                              FROM salesOrder__c 
                                              WHERE Id in: salesOrderIdSet];
        for(SalesOrder__c so: salesOrderList){
            if(so.Directdebitauthorityreferencenumber__c != null && so.Directdebitauthorityreferencenumber__c != ''){
                so.Directdebitauthorityreferencenumber__c = '';
                salesOrderToUpdate.add(so);
            }
        }
        if(!salesOrderToUpdate.isEmpty()){
            update salesOrderToUpdate;
        }
    }
    
    Public static void updateDirectDebitStatus(List<DirectDebitRequest__c> ddList){
        for(DirectDebitRequest__c ddr: ddList){
            if(ddr.Cancelled__c){
                ddr.Status__c = System.Label.Cancelled;  
            }
        }
    }   
    
    public static void updateCancelltionDDRStatusVerifierReceiver(List<DirectDebitRequest__c> ddList){
        
        for(DirectDebitRequest__c ddr: ddList){
            if(ddr.Is_EDDS__c == false){
                if(ddr.ReceiveCancellationForm__c && !ddr.CancelDirectDebitRequest__c ){
                    if(ddr.CancellationReceivedBy__c == null){
                        ddr.CancellationReceivedBy__c = UserInfo.getUserId(); 
                    }
                    ddr.CancellationReceivedDateTime__c = System.now();
                }
                if(ddr.CancelDirectDebitRequest__c && ddr.ReceiveCancellationForm__c){ 
                    ddr.Status__c = 'Cancellation in progress';
                    if(ddr.CancellationVerifiedBy__c == null){
                        ddr.CancellationVerifiedBy__c =  UserInfo.getUserId();
                    }
                    ddr.CancellationVerifiedDateTime__c = System.now();
                }
            }
        }
    }
    
    Public static void updateDDRStatusVerifierReceiver(List<DirectDebitRequest__c> ddList){
        
        for(DirectDebitRequest__c ddr: ddList){
            if(ddr.Is_EDDS__c == false){
                if(ddr.isReceived__c && !ddr.isVerified__c && ddr.Status__c != System.Label.VerifiedbyFinance){
                    ddr.Status__c = System.Label.ReceivedbyFinance;
                    if(ddr.ReceivedBy__c == null){
                        ddr.ReceivedBy__c = UserInfo.getUserId(); 
                    }
                    ddr.Received_Date_time__c = System.now();
                }
                if(ddr.isVerified__c && ddr.isReceived__c){
                    ddr.Status__c =System.Label.VerifiedbyFinance;  
                    if(ddr.VerifiedBy__c == null){
                        ddr.VerifiedBy__c =  UserInfo.getUserId();
                    }
                    ddr.Verified_Date_time__c = System.now();
                }
                if(ddr.Status__c == System.Label.ReceivedbyFinance){
                    ddr.isReceived__c = true;
                    if(ddr.ReceivedBy__c == null){
                        ddr.ReceivedBy__c = UserInfo.getUserId();
                    }
                    ddr.Received_Date_time__c = System.now();
                }
                if(ddr.Status__c == System.Label.VerifiedbyFinance){
                    ddr.isVerified__c = true;
                    if(ddr.VerifiedBy__c == null){
                        ddr.VerifiedBy__c = UserInfo.getUserId(); 
                    }
                    ddr.Verified_Date_time__c = System.now();
                } 
            }
        }
    }
    Public static void updateDDRWhenStatusIsCancellationRejected(List<DirectDebitRequest__c> ddList){
        for(DirectDebitRequest__c ddr: ddList){
            if(ddr.Status__c == 'Cancellation Rejected' && ddr.Is_EDDS__c == false){
                ddr.ReceiveCancellationForm__c = false;
                ddr.CancelDirectDebitRequest__c = false;
                ddr.CancellationReceivedDateTime__c = null;
                ddr.CancellationVerifiedDateTime__c = null;
                ddr.CancellationReceivedBy__c = null;
                ddr.CancellationVerifiedBy__c = null;
            }
        }
    }
    
    public static void checkForSignedDirectDebitFormCancellation(List<DirectDebitRequest__c> ddList){
        system.debug('ddList::'+ddList);
        Map<Id, Id> ddrDocumentMap	= new Map<Id, Id>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        Map<Id, List<ContentDocumentLink>> documentContentLinkMap = new Map<Id, List<ContentDocumentLink>>();
        
        for(DirectDebitRequest__c ddr  :[SELECT Id,(SELECT Id, DocumentType__c FROM Documents__r WHERE DocumentType__c IN ('Signed Direct Debit Cancellation form')) FROM DirectDebitRequest__c  WHERE ID IN: ddList ]){
            if(ddr.Documents__r.size()>0){
                ddrDocumentMap.put(ddr.id, ddr.Documents__r[0].Id);
            }
        }
        if(ddrDocumentMap.values().size()>0){
            contentDocumentLinks  = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink
                                     WHERE LinkedEntityId IN: ddrDocumentMap.values()];
        }
        
        if (contentDocumentLinks.size() > 0) {
            for (ContentDocumentLink contentDocumentLink : contentDocumentLinks ){
                List<ContentDocumentLink> contentDocVersion  = documentContentLinkMap.get(contentDocumentLink.LinkedEntityId) != null ? documentContentLinkMap.get(contentDocumentLink.LinkedEntityId) : new List<ContentDocumentLink>();
                contentDocVersion.add(contentDocumentLink);
                documentContentLinkMap.put(contentDocumentLink.LinkedEntityId, contentDocVersion);
            }
        }
        
        for(DirectDebitRequest__c ddr : ddList){
            if(ddr.Is_EDDS__c == false){
                system.debug('doc Id '+ ddrDocumentMap.get(ddr.Id));
                
                if(documentContentLinkMap.containsKey(ddrDocumentMap.get(ddr.Id)) && ddrDocumentMap.containskey(ddr.Id)){
                    if (documentContentLinkMap.get( ddrDocumentMap.get(ddr.Id) ).size()== 0) {
                        ddr.addError('Please add signed Direct Debit Cancellation Form before receiving/verifying'); 
                    }
                }else{
                    ddr.addError('Please add signed Direct Debit Cancellation Form before receiving/verifying'); 
                }
            }
        }
    }
    
    Public static void updateDDRWhenStatusIsRejected(List<DirectDebitRequest__c> ddList){
        for(DirectDebitRequest__c ddr: ddList){
            if(ddr.Status__c == System.Label.RejectedbyBank && ddr.Is_EDDS__c == false){
                ddr.ReceivedBy__c = null;
                ddr.isReceived__c = false;
                ddr.VerifiedBy__c = null;
                ddr.isVerified__c = false;
                ddr.Received_Date_time__c = null;
                ddr.Verified_Date_time__c = null;
            }
        }
    }
    
    //------Initialise Information Logger
    public static Logger__c createApexInfoLog(String message, String processName, 
                                              String className, String methodName, String stackTrace){       
        Logger__c newLog 				= new Logger__c();
        newLog.LogType__c 				= LOG_TYPE_INFORMATION;
        newLog.ClassName__c 			= className ;
        newLog.MethodName__c 			= methodName ;
        newLog.Message__c 				= message ;
        newLog.ExecutingProcessName__c 	= processName ;
        newLog.StackTrace__c 			= stackTrace;
        return newLog;
    }
    
    
}