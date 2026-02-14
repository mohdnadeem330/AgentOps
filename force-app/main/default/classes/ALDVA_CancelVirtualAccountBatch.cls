/* Batch to Cancellation of VA
 * Created By: Saravanan Sekar 
 */ 
global class ALDVA_CancelVirtualAccountBatch implements Database.Batchable<sObject>, Database.AllowsCallouts  {
	String ClassName = 'ALDVA_CancelVirtualAccountBatch';
    Boolean IsTesting = TRUE;//FALSE;
    String QueryStr = NULL;
    List<String> recordIds = new List<String>();
    
    global ALDVA_CancelVirtualAccountBatch(List<String> bvaIds) {
        this.recordIds = bvaIds;
        System.debug('BATCH Invoked bvaId -> '+this.recordIds);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('recordIds::'+recordIds);
        if(recordIds.size()>0) {
            String recordIdsString = String.join(recordIds, '\',\'');
            QueryStr = 'SELECT Id, BankName__c, EscrowAccountNumber__c, VirtualAccountNumber__c FROM BankVirtualAccounts__c WHERE VirtualAccountClosureDate__c = NULL AND ResponseId__c != NULL AND Id IN (\'' + recordIdsString + '\') AND StatusFlag__c=\''+String.escapeSingleQuotes(ALD_Constants.ALDVA_STATUS_CANCELLED)+'\'';
        } else {
            QueryStr = 'SELECT Id, BankName__c, EscrowAccountNumber__c, VirtualAccountNumber__c FROM BankVirtualAccounts__c WHERE VirtualAccountClosureDate__c = NULL AND ResponseId__c != NULL AND StatusFlag__c=\''+String.escapeSingleQuotes(ALD_Constants.ALDVA_STATUS_CANCELLED)+'\'';
        }
        System.debug('QueryStr -> '+QueryStr);
        system.debug('Database.getQueryLocator(QueryStr)::'+Database.getQueryLocator(QueryStr));
        return Database.getQueryLocator(QueryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<BankVirtualAccounts__c> scope) {
        List<Id> recordIds = new List<Id>();
        System.debug('SCOPE Size -> '+scope.size());
       // try {
            System.debug('SIZE of Scope -> '+scope.size()); 
            
            Organization org = Utilities.getOrganizationDetails(); //DML_ACTION            
            
            ALD_Bank_Configuration__mdt bankConfigADCB = ALD_Bank_Configuration__mdt.getInstance(ALD_Constants.ADCB_BANK); //DML_ACTION
            ALD_Bank_Configuration__mdt bankConfigFAB = ALD_Bank_Configuration__mdt.getInstance(ALD_Constants.FAB_BANK); //DML_ACTION
            
            for(BankVirtualAccounts__c bva : scope) {
                //Do Callout by Calling below method
                String BANK_NAME_FROM_BVA = ALDVA_VirtualAccount.checkTheBankName(bva.BankName__c.toLowerCase());
                //ALD_Bank_Configuration__mdt bankConfig; String BANK_NAME_FROM_BVA = ALDVA_VirtualAccount.checkTheBankName(bva.BankName__c.toLowerCase()); if(BANK_NAME_FROM_BVA == ALD_Constants.ADCB_BANK) { bankConfig = bankConfigADCB; } else if(BANK_NAME_FROM_BVA == ALD_Constants.FAB_BANK) { bankConfig = bankConfigFAB; }
                ALD_Bank_Configuration__mdt bankConfig = BANK_NAME_FROM_BVA == ALD_Constants.ADCB_BANK ? bankConfigADCB : 
                BANK_NAME_FROM_BVA == ALD_Constants.FAB_BANK ? bankConfigFAB : new ALD_Bank_Configuration__mdt();
                ALDVA_VirtualAccount.callCancelVA(FALSE, bva.Id, bva, bankConfig, org);
            }
      /*  } catch (DMLException dmlex) {
            ALDVA_VirtualAccount.captureError(dmlex, null, recordIds, FALSE);//DML_ACTION_METHOD
        } catch(Exception ex) {
            ALDVA_VirtualAccount.captureError(ex, null, recordIds, FALSE);//DML_ACTION_METHOD
        } */
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('finished ALDVA_CancelVirtualAccountBatch');
        //Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.createApexLog(null,ALD_Constants.ALDVA_INTEGRATION,ClassName,'calloutService'));

    }
}