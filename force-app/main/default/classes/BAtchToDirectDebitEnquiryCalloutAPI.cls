global class BAtchToDirectDebitEnquiryCalloutAPI implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{

    public static String DDAPI_BULK_COLLECTION_MANDATE = 'BulkCollectionMandate';
    public static String DDAPI_MANDATE_ENQUIRY = 'MandateEnquiry';
    public Set<Id> file_Ids_ForLog   = new Set<Id>();
    List<String> DDtransactionIdSet = new List<String>();
    String typeOfDDAPI = '';
    String requestType = '';
    
    public BAtchToDirectDebitEnquiryCalloutAPI(List<String> DDtransactionIdSet, String typeOfDDAPI, String requestType){
        this.DDtransactionIdSet = DDtransactionIdSet;
        this.typeOfDDAPI = typeOfDDAPI;
        this.requestType = requestType;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        //String transactionStatus = 'Processed by Salesforce';
        //String query = 'SELECT DDBank__c,DirectDebitRequest__c,Id,Name,Requesttype__c,TransactionStatus__c FROM DDTransaction__c ';
        String query = BatchToDirectDebitCalloutAPI.getQueryFields();
        String whereCondition = 'WHERE Id IN: DDtransactionIdSet ';//AND TransactionStatus__c =: transactionStatus ';
        if(requestType == BatchToDirectDebitCalloutAPIHelper.REGISTRATION && typeOfDDAPI == DDAPI_MANDATE_ENQUIRY){
            whereCondition += 'AND Requesttype__c = \'New Registration\'';
        }else if(requestType == 'Cancellation' && typeOfDDAPI == DDAPI_MANDATE_ENQUIRY){
            whereCondition += 'AND Requesttype__c = \'Cancellation\'';
        } else if(requestType == BatchToDirectDebitCalloutAPIHelper.COLLECTION && typeOfDDAPI == DDAPI_BULK_COLLECTION_MANDATE){
			whereCondition += 'AND Requesttype__c = \'Collection\'';
      	}
        String finalQuery = query + whereCondition;
		System.debug('finalQuery:'+finalQuery);
        return Database.getQueryLocator(finalQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<DDTransaction__c> ddTransactionList){
        
        if(!ddTransactionList.isEmpty() && typeOfDDAPI == DDAPI_BULK_COLLECTION_MANDATE){
            BatchToDirectDebitEnquiryCalloutHelper.getMandateCollectionEnquiryResult(ddTransactionList, requestType); //Kindly refer the bulk collection Mandate Enquiry API for now.
        }
        if(!ddTransactionList.isEmpty() && typeOfDDAPI == DDAPI_MANDATE_ENQUIRY){
            BatchToDirectDebitEnquiryCalloutHelper.getMandateEnquiryResult(ddTransactionList, requestType); //Kindly refer the Mandate Enquiry API for now.
        }
    }
    
    global void finish(Database.BatchableContext BC){
       
    }
}