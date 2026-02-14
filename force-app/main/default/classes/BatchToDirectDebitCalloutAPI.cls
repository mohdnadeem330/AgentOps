global class BatchToDirectDebitCalloutAPI implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{

    public static String DDAPI_REGISTRATION = 'Registration';
    public static String DDAPI_FILE_UPLOAD = 'FileUpload';
    public static String DDAPI_BULK_COLLECTION_MANDATE = 'BulkCollectionMandate';
    public static String DDAPI_MANDATE_ENQUIRY = 'MandateEnquiry';
    public static String DDAPI_CANCELLATION = 'Cancellation';

    public Set<Id> file_Ids_ForLog   = new Set<Id>();
   
    List<String> DDtransactionIdSet = new List<String>();
    String typeOfDDAPI = '';
    String requestType = '';
    
    public BatchToDirectDebitCalloutAPI(List<String> DDtransactionIdSet, String typeOfDDAPI, String requestType){
        this.DDtransactionIdSet = DDtransactionIdSet;
        this.typeOfDDAPI = typeOfDDAPI;
        this.requestType = requestType;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String unProcessedStatus = 'Unprocessed';
        
        String query = getQueryFields();
        
        String whereCondition = 'WHERE Id IN: DDtransactionIdSet AND TransactionStatus__c =: unProcessedStatus ';
        
        if(requestType == BatchToDirectDebitCalloutAPIHelper.REGISTRATION && (typeOfDDAPI == DDAPI_REGISTRATION || typeOfDDAPI == DDAPI_CANCELLATION || typeOfDDAPI == DDAPI_FILE_UPLOAD || typeOfDDAPI == DDAPI_MANDATE_ENQUIRY)){
            whereCondition += 'AND Requesttype__c = \'New Registration\'';
        } else if(requestType == BatchToDirectDebitCalloutAPIHelper.AMENDMENT && (typeOfDDAPI == DDAPI_REGISTRATION || typeOfDDAPI == DDAPI_CANCELLATION || typeOfDDAPI == DDAPI_FILE_UPLOAD)){
			whereCondition += 'AND Requesttype__c = \'Amendment\'';
		} else if(requestType == BatchToDirectDebitCalloutAPIHelper.CANCELLATION && (typeOfDDAPI == DDAPI_REGISTRATION || typeOfDDAPI == DDAPI_CANCELLATION || typeOfDDAPI == DDAPI_FILE_UPLOAD)){
			whereCondition += 'AND Requesttype__c = \'Cancellation\'';
        } else if(requestType == BatchToDirectDebitCalloutAPIHelper.COLLECTION && typeOfDDAPI == DDAPI_BULK_COLLECTION_MANDATE){
			whereCondition += 'AND Requesttype__c = \'Collection\'';
      	}
		
        String finalQuery = query + whereCondition;
        System.debug('finalQuery:'+finalQuery);
        return Database.getQueryLocator(finalQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<DDTransaction__c> ddTransactionList){
       
        if(!ddTransactionList.isEmpty() && (typeOfDDAPI == DDAPI_REGISTRATION || typeOfDDAPI == DDAPI_CANCELLATION)){ 
            BatchToDirectDebitCalloutAPIHelper.PrepareDataForCalloutForMandate(ddTransactionList, requestType);
        }
        if(!ddTransactionList.isEmpty() && typeOfDDAPI == DDAPI_FILE_UPLOAD){
            BatchToDirectDebitCalloutAPIHelper.PrepareDataForCalloutForFileUpload(ddTransactionList, requestType);
        }
        if(!ddTransactionList.isEmpty() && typeOfDDAPI == DDAPI_BULK_COLLECTION_MANDATE){
            BatchToDirectDebitCalloutAPIHelper.PrepareDataForCalloutForCollection(ddTransactionList, requestType); //Kindly refer the bulk collection Mandate API for now.
        }
        // if(!ddTransactionList.isEmpty() && typeOfDDAPI == DDAPI_CANCELLATION){
        //     BatchToDirectDebitCalloutAPIHelper.PrepareDataForCalloutForCancellation(ddTransactionList, requestType); //Kindly refer the bulk collection Mandate API for now.
        // }
    }
    
    global void finish(Database.BatchableContext BC){
     
    }
    
    public static String getQueryFields() {
    return 'SELECT Id, Name, DDBank__c, Requesttype__c, TransactionStatus__c, DDBankingReferenceNumber__c, DDResponseFileName__c, DDAFileName__c, BankReferenceNumber__c, SOReferenceNumber__c, ' +
           'DirectDebitRequest__r.SalesOrder__r.Name, DirectDebitRequest__r.DirectDebitBank__c, DirectDebitRequest__r.RequestTypforFile__c, DirectDebitRequest__r.OIC__c, ' +
           'DirectDebitRequest__r.PayerIdentification__c, DirectDebitRequest__r.DDAreferencenumber__c, ' +
           'DirectDebitRequest__r.CustomerType__c, DirectDebitRequest__r.CustomerIdType__c, DirectDebitRequest__r.CustomerIDNumber__c, DirectDebitRequest__r.CustomerBankName__c, ' +
           'DirectDebitRequest__r.CustomerAccountName__c, DirectDebitRequest__r.CustomerBankAccountType__c, DirectDebitRequest__r.CustomerIBANNumber__c, ' +
           'DirectDebitRequest__r.MobileNumber__c, DirectDebitRequest__r.CustomerEmail__c, DirectDebitRequest__r.IssuedFor__c, DirectDebitRequest__r.CustomerMobile__c, ' +
           'DirectDebitRequest__r.CommencesOn__c, DirectDebitRequest__r.ExpiresOn__c, DirectDebitRequest__r.AmountType__c, DirectDebitRequest__r.PaymentFrequency__c, ' +
           'DirectDebitRequest__r.MinimumAmount__c, DirectDebitRequest__r.MaximumAmount__c, DirectDebitRequest__r.CurrencyIsoCode, DirectDebitRequest__r.FirstInitiationDate__c, ' +
           'DirectDebitRequest__r.FrequencyParameter__c, DirectDebitRequest__r.MakerRemarks__c, DirectDebitRequest__r.FundingAccountType__c, DirectDebitRequest__r.DDAPurposeCode__c, ' +
           'DirectDebitRequest__r.DDAamountType__c, DirectDebitRequest__r.DebitRequestInstanceAllowed__c, DirectDebitRequest__r.PayingBankRoutingCode__c, DirectDebitRequest__r.PayingBankID__c, ' +
           'DirectDebitRequest__r.CaptureMode__c, DirectDebitRequest__r.CollectionAmount__c, DirectDebitRequest__r.Originator_Account_Number__c, DirectDebitRequest__r.PaymentFrequencyCharacter__c, DirectDebitRequest__r.Name,CollectionAmount__c,DDRReference__c,CollectionBatchId__c FROM DDTransaction__c ';
	}
}