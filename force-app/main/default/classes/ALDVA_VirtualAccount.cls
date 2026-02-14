/*
* Created By : ssekar@aldar.com Saravanan Sekar 12/12/2022
*/
public class ALDVA_VirtualAccount {
    public static String ClassName = 'ALDVA_VirtualAccount';
    public Static String AvailableStr = Constants.UNIT_STATUS_AVAILABLE;
    public Static String NewStr = Constants.UNIT_STATUS_NEW;
    
    /* ********************************************PUBLIC METHODS******************************************** */
    
    @AuraEnabled
    public static void callCancelVA(Boolean shallDoQuery, String recordId, BankVirtualAccounts__c bva, 
                                    ALD_Bank_Configuration__mdt bankConfig, Organization org) 
    {
        //This Method will being invoked from Batch Class and Realtime From VirtualAccountService on Status Change
        //recordId 		-> BankVirtualAccounts__c Id
        //shallDoQuery 	-> If TRUE then Run the Queries, Assumption is Individual Call and Direct Changes on the Record Data. Else, From Batch Class;
        //bva 			-> BankVirtualAccounts__c to execute for this process
        //bankConfig 	->  Metadata to get the necessary information
        List<Id> recordIds = new List<Id>();
        
        Boolean IsTesting = TRUE; //For Admin Test
        List<BankVirtualAccounts__c> bvaToUpdate = new List<BankVirtualAccounts__c>();
        if(shallDoQuery) {
            bva = [SELECT Id, BankName__c, EscrowAccountNumber__c, VirtualAccountNumber__c
                   FROM BankVirtualAccounts__c 
                   WHERE Id=:recordId]; 
            org = Utilities.getOrganizationDetails();    
        }
     //   String BANK_NAME_FROM_BVA = bva.BankName__c == 'Abu Dhabi Commercial Bank' ? 'Abu_Dhabi_Commercial_Bank': 'First_Abu_Dhabi_Bank';
        String BANK_NAME_FROM_BVA = '';
        if(Test.isRunningTest()){
            BANK_NAME_FROM_BVA = bva.BankName__c == 'Abu Dhabi Commercial Bank' ? 'Abu_Dhabi_Commercial_Bank': 'First_Abu_Dhabi_Bank';
        }else{
            BANK_NAME_FROM_BVA  = bva.BankName__c == 'Abu Dhabi Commercial Bank' ? 'ADCB': 'FAB';
        }
        bankConfig = ALD_Bank_Configuration__mdt.getInstance(BANK_NAME_FROM_BVA); 
        String RequestBody = bankConfig.Request_Parameters_to_Cancel__c;
       
        String NewRequestBody = RequestBody;
        NewRequestBody = NewRequestBody.replace('[REQUEST_ID]', bva.Id);
        NewRequestBody = NewRequestBody.replace('[PHYSICAL_ACC_NUMBER]', bva.EscrowAccountNumber__c);
        NewRequestBody = NewRequestBody.replace('[VIRTUAL_ACC_NUMBER]', bva.VirtualAccountNumber__c);
        System.debug('NewRequestBody -> '+NewRequestBody);
        
        CalloutToMuleSoft.calloutService(NewRequestBody, true, 'BankIntegrationVACancel', new List<Id>{bva.Id});
      
    }
    
    
    public static void callCancelVAViaBatch(List<String> recordIds) {
        //Invoking from the cancellation class - VirtualAccountService
        System.debug('callCancelVAViaBatch -> '+recordIds.size()+' -> '+recordIds);
        Integer batchSize = Utilities.getConstantValue('ALDVA_CancelVirtualAccountBatch') != null?Utilities.getConstantValue('ALDVA_CancelVirtualAccountBatch'): 1;
        if(Test.isRunningTest()){
        ALDVA_CancelVirtualAccountBatch vaBatch = new ALDVA_CancelVirtualAccountBatch(recordIds);
        Database.executeBatch(vaBatch);
        }else{
             ALDVA_CancelVirtualAccountBatch vaBatch = new ALDVA_CancelVirtualAccountBatch(recordIds);
        Database.executeBatch(vaBatch, batchSize);
        }
    }
    
    @AuraEnabled
    public static void callCreateVA(String recordId) {
        //This method will be invoked from aldvaCreateVirtualAccount LWC.
        //recordId 	-> Project__c Id
        //  try {
        List<BankVirtualAccounts__c> vAccToInsertWithUnit = new List<BankVirtualAccounts__c>();
        List<BankVirtualAccounts__c> vAccToInsert = new List<BankVirtualAccounts__c>();
        System.debug('recordId -> '+recordId);
        Project__c proj = [SELECT
                           Id,
                           AccountNumberEscrow__c,
                           BankNameEscrow__c,
                           AccountNumberCorporate__c,
                           CommunityName__c, 
                           IBANNoEscrow__c,
                           (SELECT
                            Id
                            FROM
                            UnitsProject__r
                            WHERE Status__c=:AvailableStr 
                            OR Status__c=:NewStr) 
                           FROM Project__c 
                           WHERE Id=:recordId]; //DML_ACTION
        System.debug('proj  AccountNumberEscrow__c -> '+proj.AccountNumberEscrow__c);
        
        Integer unitCount = proj.UnitsProject__r.size();
        System.debug('unitCount*2 -> '+unitCount*2);
        String BankName = proj.BankNameEscrow__c;
        String EscrowAccountNumber = proj.AccountNumberEscrow__c;
        String CorporateEscrowAccountNumber = proj.AccountNumberCorporate__c;
        String IBANNoEscrow = proj.IBANNoEscrow__c;
        String ProjId = proj.Id;
        
        //Insert one set of VA Record with Unit Relationship
        for(Unit__c un : proj.UnitsProject__r) {
            BankVirtualAccounts__c bva = new BankVirtualAccounts__c();
            bva.AccountType__c = ALD_Constants.BANK_COLLECTION;
            bva.BankName__c = BankName;
            bva.EscrowAccountNumber__c = EscrowAccountNumber;
            bva.Virtual_Account_Type__c = 'Escrow';
            bva.EscrowIBANAccountNumber__c = IBANNoEscrow;
            bva.Project__c = ProjId;
            bva.BufferFlag__c = FALSE; //TAGGING WITH UNIT
            bva.Unit__c = un.Id; //TAGGING WITH UNIT
            vAccToInsertWithUnit.add(bva);
            
           /* To Create Co-rporate Bank Virtual Accounts  
            BankVirtualAccounts__c corporateBVA = new BankVirtualAccounts__c();
            corporateBVA.AccountType__c = ALD_Constants.BANK_COLLECTION;
            corporateBVA.BankName__c = BankName;
            corporateBVA.EscrowAccountNumber__c = CorporateEscrowAccountNumber;
            corporateBVA.EscrowIBANAccountNumber__c = IBANNoEscrow;
            corporateBVA.Project__c = ProjId;
            corporateBVA.BufferFlag__c = FALSE; 
            corporateBVA.Virtual_Account_Type__c = 'Aldar Corporate';
            corporateBVA.Unit__c = un.Id; 
            vAccToInsertWithUnit.add(corporateBVA); */

            
        }
        
        if(vAccToInsertWithUnit.size()>0) {
            insert vAccToInsertWithUnit;
            
            List<Unit__c> unitWithVAToUpdate = new List<Unit__c>();
            List<Unit__c> unitWithCorporateVAToUpdate = new List<Unit__c>();
            Map<Id, Unit__c> unitWithVAToUpdateMap = new Map<Id, Unit__c>();
            for(BankVirtualAccounts__c bva : vAccToInsertWithUnit) {
                Unit__c un = new Unit__c();
               
                un = unitWithVAToUpdateMap.get(un.Id) != null ? unitWithVAToUpdateMap.get(un.Id) : new Unit__c();
                un.Id = bva.Unit__c;
               
                if(bva.Virtual_Account_Type__c == 'Escrow'){
                    un.VirtualAccountNumber__c = bva.Id;
                    unitWithVAToUpdate.add(un);
                }
                if(bva.Virtual_Account_Type__c == 'Aldar Corporate'){
                     un.CorporateVirtualAccountNumber__c = bva.Id;
                    unitWithCorporateVAToUpdate.add(un);
                }
                unitWithVAToUpdateMap.put(un.Id, un);
              
                    //unitWithVAToUpdate.add(un);
              
            }
            if(unitWithVAToUpdate.size()>0) {
                update unitWithVAToUpdate;
            }
             if(unitWithCorporateVAToUpdate.size()>0) {
                update unitWithCorporateVAToUpdate;
            }
        }
        
        
        //Insert another set of VA Record without Unit Relationship
        for(Integer i=0;i<unitCount;i++) {
            BankVirtualAccounts__c bva = new BankVirtualAccounts__c();
            bva.AccountType__c = ALD_Constants.BANK_COLLECTION;
            bva.BankName__c = BankName;
            bva.EscrowAccountNumber__c = EscrowAccountNumber;
            bva.EscrowIBANAccountNumber__c = IBANNoEscrow;
            bva.Project__c = ProjId;
            bva.Virtual_Account_Type__c = 'Escrow';
            bva.BufferFlag__c = TRUE;
            vAccToInsert.add(bva);
            
          /*  BankVirtualAccounts__c corporateBVA = new BankVirtualAccounts__c();
            corporateBVA.AccountType__c = ALD_Constants.BANK_COLLECTION;
            corporateBVA.BankName__c = BankName;
            corporateBVA.EscrowAccountNumber__c = CorporateEscrowAccountNumber;
            corporateBVA.EscrowIBANAccountNumber__c = IBANNoEscrow;
            corporateBVA.Project__c = ProjId;
            corporateBVA.BufferFlag__c = TRUE; 
            corporateBVA.Virtual_Account_Type__c = 'Aldar Corporate';
            vAccToInsert.add(corporateBVA); */
        }
        
        System.debug('vAccToInsert 2 Size -> '+vAccToInsert.size());
        
        if(vAccToInsert.size()>0) {
            insert vAccToInsert; //DML_ACTION
            System.debug('vAccToInserted -> '+vAccToInsert[0].Id);
            Integer batchSize = Utilities.getConstantValue('ALDVA_CreateVirtualAccountBatchSize');
            Set<String> ProjectIds = new Set<String>();
            ProjectIds.add(ProjId);
            if(Test.isRunningTest()){
                ALDVA_CreateVirtualAccountBatch vaBatch = new ALDVA_CreateVirtualAccountBatch(ProjectIds);
                Database.executeBatch(vaBatch); 
            }else{
                ALDVA_CreateVirtualAccountBatch vaBatch = new ALDVA_CreateVirtualAccountBatch(ProjectIds);
                Database.executeBatch(vaBatch, 1);
            }
        }
        
        /* } catch(Exception ex) {
System.debug('Exception '+ex.getMessage()+ex.getLineNumber()+ex.getStackTraceString()+' - - > '+ex);
} */
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> checkTheProgressOfVACreation(String recordId) {
        //This method will be invoked from aldvaCreateVirtualAccount LWC.
        //To Check the Progress of the Account Creation
        
        Map<String, Decimal> statusWithNumber = new Map<String, Decimal>(); //Example: 'Success', 34.00
        List<BankVirtualAccounts__c> allVa = [SELECT Id, VirtualAccountNumber__c 
                                              FROM BankVirtualAccounts__c 
                                              WHERE Project__c=:recordId]; //DML_ACTION
        Integer countOfSuccess = 0;
        for(BankVirtualAccounts__c VA : allVa) {
            if(VA.VirtualAccountNumber__c != null) {
                countOfSuccess++;
            }
        }
        
        Decimal percentageCompleted;
        if(allVa.size()>0) {
            percentageCompleted = ((((Decimal) countOfSuccess) / (Decimal)allVa.size()) * 100).round(System.RoundingMode.CEILING);
        }
        
        statusWithNumber.put('Success',countOfSuccess); // 40
        statusWithNumber.put('TotalCount',allVa.size()); //100
        statusWithNumber.put('ProcessedPercentage',percentageCompleted); // 75/150 * 100 = 50%
        
        return statusWithNumber;
    }
    
    /*********************************************HELPER METHODS*********************************************/
    
   /* public static void captureError(Exception dmlex, Database.Error err, List<Id> recordIds, Boolean isError) {
        //isError -> TRUE, If Error During DML Insert or Update; False, If any Exception
        
        Logger__c lgs = new Logger__c();
        if(isError) {
            lgs = LoggerService.saveAndReturnLogger(LoggerService.createApexLog(err, ALD_Constants.ALDVA_INTEGRATION+' - '+ALD_Constants.ALDVA_CANCELLATION, ClassName, 'vaCreationExecuteBatch')); //DML_ACTION_METHOD
        } else {
            lgs = LoggerService.saveAndReturnLogger(LoggerService.createApexLog(dmlex, ALD_Constants.ALDVA_INTEGRATION+' - '+ALD_Constants.ALDVA_CANCELLATION, ClassName,'vaCreationBatch'));//DML_ACTION_METHOD
        }
        updateStatusAsFailed(recordIds, lgs.Id);//DML_ACTION_METHOD
    }*/
    
  /*  public static Id captureServiceCalls(String NewRequestBody, HTTPResponse response, List<Id> recordIds, Boolean isError, String ExceptionType) {
        //isError -> TRUE, If Error During DML Insert or Update; False, If any Exception
        //Return logger id if its a service call
        //Update the status to Failed if isError is TRUE
        
        Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.addApexServiceCalls(ClassName, ExceptionType, ALD_Constants.ALDVA_INTEGRATION, (NewRequestBody.length() < 131072 ? NewRequestBody : ''),response.getBody(),null));//DML_ACTION
        if(isError) {
            updateStatusAsFailed(recordIds, lgs.Id);//DML_ACTION_METHOD
        }
        return lgs.Id;
    }
    */
    public static String checkTheBankName(String bankName) {
        //Pass the Bank Name here to find the Bank Name. Get it from ALD_Constants Class.
        //bankName -> String From Creation and Cancellation batch classes
        
        String ConstBankName = null;
        if(bankName == ALD_Constants.ABUDHABI_COMMERCIAL_BANK.toLowerCase() || bankName == ALD_Constants.ADCB_BANK.toLowerCase()) {
            ConstBankName = ALD_Constants.ADCB_BANK;
        }
        if(bankName == ALD_Constants.FIRST_ABUDHABI_BANK.toLowerCase() || bankName == ALD_Constants.FAB_BANK.toLowerCase()) {
            ConstBankName = ALD_Constants.FAB_BANK;
        }
        
        return ConstBankName;
    }
    
   /* public static void updateStatusAsFailed(List<Id> recordIds, String loggerId) {
        //Similar Approach as CalloutToMuleSoft.updateStatusAsFailed
        if (!recordIds.isEmpty()) {
            String objectType = '';
            if (recordIds[0].getSObjectType() == BankVirtualAccounts__c.SObjectType) {
                objectType = 'BankVirtualAccounts__c';
            } else if (recordIds[0].getSObjectType() == Project__c.SObjectType) {
                objectType = 'Project__c';
            }
            if (objectType != '') {
                List<SObject> updateSObjectList = new List<SObject>();
                for (Id rId: recordIds) {
                    SObject updateSObject = Schema.getGlobalDescribe().get(objectType).newSObject();
                    updateSObject.put('Id', rId);
                    updateSObject.put('SyncStatus__c', Constants.STATUS_FAILED);
                    updateSObject.put('Logger_Id__c', loggerId);//SAL-597 SARAN
                    updateSObjectList.add(updateSObject);
                }
                if (!updateSObjectList.isEmpty()) {
                    update updateSObjectList;//DML_ACTION
                }
            }
        }
    } */
   
    public static void updateBankVirtualAccountResponse(String json, String requestBody){
        system.debug('requestBody::'+requestBody);
        system.debug('json::'+json);
        List<BankVirtualAccounts__c> bvaList = new List<BankVirtualAccounts__c>();
        ALDVA_ADCB_ResponseWrapper wrapper   = parseResponse(json);
       system.debug('wrapper:::'+wrapper);
        BankVirtualAccounts__c bva = new BankVirtualAccounts__c();
        bva.Id = wrapper.response.requestId;
       // bva.ResponseJSON__c = json;
        bva.RequestJSON__c = requestBody;
        if(wrapper.response.errorCode != null && wrapper.response.errorDescription != null){ 
            bva.ErrorCode__c   = wrapper.response.errorCode;
            bva.ErrorReason__c = wrapper.response.errorDescription;
        }else{
            bva.StatusFlag__c = wrapper.response.virtualAccountStatus == 'C' ? ALD_Constants.ALDVA_STATUS_CANCELLED : (wrapper.response.virtualAccountStatus == 'A' ? 'Available':'');
            bva.VirtualAccountNumber__c = wrapper.response.virtualAccountNumber;
            bva.ResponseId__c = wrapper.responseId;
            bva.PhysicalAccountTitle__c = wrapper.response.physicalAccountTitle;
            bva.CustomerID__c = wrapper.response.customerID;
            bva.VirtualCustomerID__c = wrapper.response.virtualCustomerID;
            bva.VirtualAccountTitle__c = wrapper.response.virtualAccountTitle;
            bva.VirtualIBANAccountNumber__c = wrapper.response.virtualIBAN;
            if(wrapper.response.virtualAccountOpenDate != null){
                date vaOpendate = date.parse(wrapper.response.virtualAccountOpenDate);
                dateTime vaOpendateTime = datetime.newInstance(vaOpendate, Time.newInstance(0,0,0,0));
                bva.VirtualAccountOpenDate__c = vaOpendateTime;
            }
            if(wrapper.response.virtualAccountClosureDate != null){
                date vaClosedate = date.parse(wrapper.response.virtualAccountClosureDate);
                dateTime vaClosedateTime = datetime.newInstance(vaClosedate, Time.newInstance(0,0,0,0));
                bva.VirtualAccountClosureDate__c = vaClosedateTime;
            }
            bva.SyncStatus__c = Constants.STATUS_SYNCED;
        }
        bvaList.add(bva);
        if(!bvaList.isEmpty()){
            update bvaList;
        }
    }
    Public static ALDVA_ADCB_ResponseWrapper parseResponse(String json){
       system.debug((ALDVA_ADCB_ResponseWrapper)System.JSON.deserialize(json, ALDVA_ADCB_ResponseWrapper.class));
        return (ALDVA_ADCB_ResponseWrapper)System.JSON.deserialize(json, ALDVA_ADCB_ResponseWrapper.class);
    }
    
}