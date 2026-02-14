/**********************************************************************************************************************
* Name               : DDTransactionTriggerHandler                                                        
* Description        : 
* Created By         : Tharun                                                   
******************************************************************************************************************/

public class DDTransactionTriggerHandler extends TriggerHandler{
    
    //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
           //prepopulateDDTCOllectionRecord((List<DDTransaction__c>) newList);           
        
    }
    
    //*** Before Update Action***//
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        
       /* for(DDTransaction__c ddTransaction: (List<DDTransaction__c>) newList ){
            DDTransaction__c oldDDT = (DDTransaction__c) oldMap.get(ddTransaction.Id);
            if(ddTransaction.DDResponse__c != null && ddTransaction.DDResponse__c != oldDDT.DDResponse__c ){
                DDTransactionResponseHandler.parseResponse((List<DDTransaction__c>)newList);
            }
        } */
    }

    //*** After Insert Action***//
    public static Map<String, ALD_Bank_Configuration__mdt> getBankConfig(){
        Map<String, ALD_Bank_Configuration__mdt> mapOfBankConfig = new Map<String, ALD_Bank_Configuration__mdt>();
        List<ALD_Bank_Configuration__mdt> BankConfigList = [SELECT Id, MasterLabel, DDAPIEnabled__c FROM ALD_Bank_Configuration__mdt];
        for(ALD_Bank_Configuration__mdt meta: BankConfigList){
            mapOfBankConfig.put(meta.MasterLabel, meta);
        }
        return mapOfBankConfig;
    }
    
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
       
      List<DDTransaction__c> updatednewList =  prepopulateDDTCOllectionRecord((List<DDTransaction__c>) newList);
        
        Map<Id,DDTransaction__c> ddrDDTMapIds      = new Map<Id,DDTransaction__c>();
        Map<Id,DDTransaction__c> ddrAPIDDTMapIds   = new Map<Id,DDTransaction__c>();
        Map<Id, DDTransaction__c> DDTransactionMap = new  Map<Id, DDTransaction__c>();
        Map<String, ALD_Bank_Configuration__mdt> bankConfigMap = getBankConfig();
        
        if(!newList.isEmpty()) {
            for(DDTransaction__c newDDTRecord : updatednewList) {
                System.debug('after insert '+newDDTRecord);
                if(bankConfigMap.get(newDDTRecord.DDBank__c) != null ){
                    if(newDDTRecord.DirectDebitRequest__c != null && !bankConfigMap.get(newDDTRecord.DDBank__c).DDAPIEnabled__c && newDDTRecord.Is_EDDS__c == FALSE){
                        ddrDDTMapIds.put(newDDTRecord.DirectDebitRequest__c, newDDTRecord);
                    }
                    else if(newDDTRecord.DirectDebitRequest__c != null && bankConfigMap.get(newDDTRecord.DDBank__c).DDAPIEnabled__c && newDDTRecord.Is_EDDS__c == FALSE){
                        DDTransactionMap.put(newDDTRecord.DirectDebitRequest__c, newDDTRecord);
                    }
                }
            }
        }
        
        system.debug('ddrDDTMapIds:::'+ddrDDTMapIds);
        system.debug('DDTransactionMap:::'+DDTransactionMap);
        if(!ddrDDTMapIds.isEmpty() && !Test.isRunningTest()) {
            GenerateFileHelper.prepareFileFromDDTBulkify(ddrDDTMapIds);
        }
        if(!DDTransactionMap.isEmpty()){
            GenerateFileHelperForAPI.appendDDRFormToDDT(DDTransactionMap);
        }
    }

    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
      
        List<DDTransaction__c> ddtResponseList = new List<DDTransaction__c>();
        List<DDTransaction__c> ddtUpdateStatus = new List<DDTransaction__c>();
        for(DDTransaction__c ddTransaction: (List<DDTransaction__c>) newList ){
            DDTransaction__c oldDDT = (DDTransaction__c) oldMap.get(ddTransaction.Id);
            if(ddTransaction.DDResponse__c != null && ddTransaction.DDResponse__c != oldDDT.DDResponse__c && ddTransaction.Is_EDDS__c == FALSE ){
                ddtResponseList.add(ddTransaction);
               // DDTransactionResponseHandler.parseResponse((List<DDTransaction__c>)newList);
            }
            if(ddTransaction.TransactionStatus__c != null && ddTransaction.TransactionStatus__c != oldDDT.TransactionStatus__c && (ddTransaction.APIEnabled__c == FALSE || ddTransaction.Is_EDDS__c == TRUE )){ //FIN-146
                ddtUpdateStatus.add(ddTransaction);
                //DDTransactionResponseHandler.updateDDRStatus((List<DDTransaction__c>)newList);
            }
        }
        if(ddtResponseList.size() > 0){
            DDTransactionResponseHandler.parseResponse(ddtResponseList);
        }
        if(ddtUpdateStatus.size() > 0){
            DDTransactionResponseHandler.updateDDRStatus(ddtUpdateStatus);
        }
    }
    
    public static List<DDTransaction__c> prepopulateDDTCOllectionRecord(List<DDTransaction__c> ddtransactionList){
        System.debug('ddtransactionList in prepopulateDDTCOllectionRecord '+ddtransactionList);
        
        List<DDTransaction__c> DDTtransactionListToUpdate = new List<DDTransaction__c>();
        Map<String, ALD_Bank_Configuration__mdt> bankConfigMap = getBankConfig();
        
        List<DDTransaction__c> allDdtransactionList = [SELECT
                                                       Id,
                                                       Sponsoring_Bank_Transaction_Reference_No__c, 
                                                       Name,CurrencyIsoCode,CreatedDate,CreatedById,LastModifiedDate,LastModifiedById,
                                                       LastViewedDate,LastReferencedDate,DDBankingReferenceNumber__c,DirectDebitRequest__c,
                                                       DDBank__c,DDResponse__c,RejectionReason__c,Requesttype__c,SOReferenceNumber__c,
                                                       SyncStatus__c,SyncTime__c,TransactionStatus__c,DDResponseFileName__c,AckNackResponse__c,
                                                       DD_Response_Files__c,RequestFileName__c,UniqueRegNumber__c,
                                                       CollectionAmount__c,Installment_Line__c,Receipt_Acknowledgement__c,
                                                       DDA_Unique_Number__c,DDResponsefiletype__c,ErrorReason__c,TransactionReferenceNumber__c,
                                                       DDAFileName__c,BankReferenceNumber__c,
                                                       DirectDebitRequest__r.DDAreferencenumber__c,Is_EDDS__c 
                                                       FROM DDTransaction__c 
                                                       WHERE Id IN: ddtransactionList AND Is_EDDS__c = FALSE];
        System.debug('allDdtransactionList '+allDdtransactionList);
         
        for(DDTransaction__c ddtransaction : allDdtransactionList) {
            String BankAPISyncStatus = '';
            if(ddtransaction.Requesttype__c == 'New Registration'){
                BankAPISyncStatus = 'Ready for Registration Mandate API';
            }else if(ddtransaction.Requesttype__c == 'Amendment'){
                BankAPISyncStatus = 'Ready for Amendment API';
            }else if(ddtransaction.Requesttype__c == 'Cancellation'){
                BankAPISyncStatus = 'Ready for Cancellation API';
            }else if(ddtransaction.Requesttype__c == 'Collection'){
                BankAPISyncStatus = 'Ready for Collection API';
            }
            ddtransaction.APIEnabled__c = bankConfigMap.get(ddtransaction.DDBank__c) != null ? bankConfigMap.get(ddtransaction.DDBank__c).DDAPIEnabled__c : false;
            ddtransaction.BankAPIsyncstatus__c = BankAPISyncStatus;
            ddtransaction.DDAFileName__c = Label.ADCB_BankRefNumber + ddtransaction.Name.right(6) + String.valueOf(Datetime.now().format('YYMM'))+'.pdf';
            ddtransaction.Sponsoring_Bank_Transaction_Reference_No__c = '003500'+String.valueOf(Datetime.now().format('YYMMdd'))+ddtransaction.Name.right(4);
            ddtransaction.DDA_Unique_Number__c = ddtransaction.DirectDebitRequest__r.DDAreferencenumber__c != null ? (ddtransaction.DirectDebitRequest__r.DDAreferencenumber__c + ddtransaction.Name.right(6)) : null;
            ddtransaction.TransactionReferenceNumber__c = ddtransaction.name.right(3)+'400'+String.valueOf(Datetime.now().format('YYMMdd'))+ddtransaction.name.right(4);
            DDTtransactionListToUpdate.add(ddtransaction);
        }
        
        System.debug('DDTtransactionListToUpdate '+DDTtransactionListToUpdate);
        if(!DDTtransactionListToUpdate.isEmpty()){
           update DDTtransactionListToUpdate;
        }
        return DDTtransactionListToUpdate;
    }
}