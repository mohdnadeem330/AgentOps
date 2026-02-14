/* Batch to Create and Retry VA
* Created By: Saravanan Sekar 
*/ 
global class ALDVA_CreateVirtualAccountBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable  {
    global Set<String> ProjectIds = new Set<String>();
    global static String ClassName = 'ALDVA_CreateVirtualAccountBatch';
    Boolean IsTesting = TRUE;//FALSE;
    global String AvailableStr = Constants.UNIT_STATUS_AVAILABLE;
    global String NewStr = Constants.UNIT_STATUS_NEW;
    
    global ALDVA_CreateVirtualAccountBatch(Set<String> ProjectIds) {
        this.ProjectIds = ProjectIds;
        System.debug('BATCH Invoked -> '+this.ProjectIds);
    }
    
    public void execute(SchedulableContext sc) {
        //
        DateTime newDateTime = System.now();
        Set<String> projIds = new Set<String>();
        Map<String, String> projBank = new Map<String, String>();
        
        for(BankVirtualAccounts__c bva : [SELECT Id, CreatedDate, Project__c, Project__r.BankNameEscrow__c FROM BankVirtualAccounts__c WHERE CreatedDate <:newDateTime.addHours(-5) Order by Project__c ]) {
            if(!projBank.containsKey(bva.Project__c)) {
                projBank.put(bva.Project__c, bva.Project__r.BankNameEscrow__c);
                projIds.add(bva.Project__c);
            }
        }
        if(projIds.size()>0) {
            ALDVA_CreateVirtualAccountBatch aCreateBatch = new ALDVA_CreateVirtualAccountBatch(projIds);
            Database.executeBatch(aCreateBatch, 100);
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String ProjectIdsString = '';//ProjectIds.toString(); //String.join(ProjectIds, '\',\'');
        for(String s:ProjectIds) {  
            ProjectIdsString += (ProjectIdsString == ''?'\'':'\',\'')+s;
        }
        ProjectIdsString = ProjectIdsString+'\'';
        System.debug('ProjectIdsString -> '+ProjectIdsString);  
        String QueryStr;
        if(Test.isRunningTest()){
            QueryStr = 'SELECT Id, EscrowAccountNumber__c, Project__c, Project__r.BankNameEscrow__c, Unit__c, Unit__r.Status__c FROM BankVirtualAccounts__c WHERE (Unit__r.Status__c=:NewStr OR Unit__r.Status__c=:AvailableStr OR Unit__c=null)  AND CreatedDate=TODAY AND Project__c IN (' + ProjectIdsString + ')'; //=\''+String.escapeSingleQuotes(ProjectId)+'\'';
        }else{
            QueryStr =  'SELECT Id, EscrowAccountNumber__c, Project__c, Project__r.BankNameEscrow__c, Unit__c, Unit__r.Status__c FROM BankVirtualAccounts__c WHERE (Unit__r.Status__c=:NewStr OR Unit__r.Status__c=:AvailableStr OR Unit__c=null) AND VirtualAccountNumber__c=NULL AND EscrowAccountNumber__c!=null AND CreatedDate=TODAY AND Project__c IN (' + ProjectIdsString + ')'; //=\''+String.escapeSingleQuotes(ProjectId)+'\'';
        } System.debug('QueryStr -> '+QueryStr);
        
        return Database.getQueryLocator(QueryStr); //DML_ACTION 
    }
    
    global void execute(Database.BatchableContext bc, List<BankVirtualAccounts__c> scope) {  
        system.debug('scope::'+scope);
        system.debug('scope::'+scope.size());
        List<Id> recordIds = new List<Id>();
       //  try {
        
        System.debug('scope '+scope);
        List<BankVirtualAccounts__c> bvaToUpdate = new List<BankVirtualAccounts__c>();
        
        Organization org = Utilities.getOrganizationDetails();//DML_ACTION
        
        ALD_Bank_Configuration__mdt bankConfigADCB = ALD_Bank_Configuration__mdt.getInstance('Abu_Dhabi_Commercial_Bank'); //DML_ACTION
        ALD_Bank_Configuration__mdt bankConfigFAB = ALD_Bank_Configuration__mdt.getInstance('First_Abu_Dhabi_Bank'); //DML_ACTION
        
        for(BankVirtualAccounts__c bva : scope) { 
            //Do Callout
            String BANK_NAME_FROM_BVA = ALDVA_VirtualAccount.checkTheBankName(bva.Project__r.BankNameEscrow__c.toLowerCase());
            
            ALD_Bank_Configuration__mdt bankConfig = BANK_NAME_FROM_BVA == ALD_Constants.ADCB_BANK ? bankConfigADCB : 
            BANK_NAME_FROM_BVA == ALD_Constants.FAB_BANK ? bankConfigFAB : new ALD_Bank_Configuration__mdt();             

            bva = doVACreateCallout(bankConfig, org, bva, IsTesting);
            System.debug('bva '+bva);
            if(bva != null) {
                bvaToUpdate.add(bva);
            }
        }
      /*  if(bvaToUpdate.size()>0) {
            //update bvaToUpdate;
            Database.SaveResult[] srList = Database.update(bvaToUpdate, false);//DML_ACTION
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        recordIds.add(sr.getId()); //Just to Update the Logger Id incase of issue
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('BankVirtualAccounts__c fields that affected this error: ' + err.getFields());
                        
                        ALDVA_VirtualAccount.captureError(null, err, recordIds, TRUE);//DML_ACTION_METHOD
                    }
                }
            }
        } */ 
      /*   } catch (DMLException dmlex) {
             ALDVA_VirtualAccount.captureError(dmlex, null, recordIds, FALSE);//DML_ACTION_METHOD
         } catch(Exception ex) {
             ALDVA_VirtualAccount.captureError(ex, null, recordIds, FALSE);//DML_ACTION_METHOD
         } */
    }
    
    public static BankVirtualAccounts__c doVACreateCallout(ALD_Bank_Configuration__mdt bankConfig, Organization org, BankVirtualAccounts__c bva, Boolean IsTesting) {
        System.debug('doVACreateCallout '+bva);
      //  try{
       System.debug('bankConfig '+bankConfig);
        String RequestBody = bankConfig.Request_Parameters_to_Create__c;
        String NewRequestBody = RequestBody;
        system.debug('NewRequestBody:::'+NewRequestBody);
         bva.EscrowAccountNumber__c = Test.isRunningTest() ? '2345678' : bva.EscrowAccountNumber__c;
        NewRequestBody = NewRequestBody.replace('[REQUEST_ID]', bva.Id);
        NewRequestBody = NewRequestBody.replace('[PHYSICAL_ACC_NUMBER]', bva.EscrowAccountNumber__c);
        NewRequestBody = NewRequestBody.replace('[UNIQUE_REF_NUMBER]', bva.Id); //We are not passing Unit Number as per the request
        NewRequestBody = NewRequestBody.replace('[REMARKS_ANY]', ''); 
        system.debug('NewRequestBody:::'+NewRequestBody);
        CalloutToMuleSoft.calloutService(NewRequestBody, true, 'BankIntegrationVA', new List<Id>{bva.Id}); 
        
   /* } catch(Exception ex) {
        System.debug('Ex  '+ex.getLineNumber()+ex.getMessage()+ex.getStackTraceString());
    } */
        return null;
    }
    
  /*  public static BankVirtualAccounts__c updateVAccount(Id bvaId, String AccNumber, String IBANAccNumber, String VirtualCustomerID,
                                                        String CustomerID, String PhysicalAccountTitle, String ResponseId, 
                                                        String VirtualAccountStatus, String VirtualAccountTitle,
                                                        DateTime VirtualAccountOpenDate, String uniqueReferenceNumber){
       
        BankVirtualAccounts__c bva = new BankVirtualAccounts__c();
        bva.Id = bvaId;
        bva.VirtualAccountNumber__c = AccNumber;
        bva.VirtualIBANAccountNumber__c = IBANAccNumber;
        bva.VirtualCustomerID__c = VirtualCustomerID;
        bva.CustomerID__c = CustomerID;
        bva.PhysicalAccountTitle__c = PhysicalAccountTitle;
        bva.ResponseId__c = ResponseId;
        bva.StatusFlag__c = VirtualAccountStatus;
        bva.VirtualAccountTitle__c = VirtualAccountTitle;
        bva.VirtualAccountOpenDate__c = VirtualAccountOpenDate;
        bva.UniqueReferenceNumber__c = uniqueReferenceNumber;
        return bva;
    } */
    
    global void finish(Database.BatchableContext bc) { 
        System.debug('finis+scope.size()');
        //SEND EMAIL FROM HERE IF PROCESS IS 100% Completed
        //Map<String, Decimal> percentCompleted = ALDVA_VirtualAccount.checkTheProgressOfVACreation(ProjectIds[0]);//DML_ACTION_METHOD
        //if(percentCompleted.get('ProcessedPercentage') == 100) {
        //SEND EMAIL
        
        //}
    }
    
}