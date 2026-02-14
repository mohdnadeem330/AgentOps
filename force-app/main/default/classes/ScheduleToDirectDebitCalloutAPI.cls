global class ScheduleToDirectDebitCalloutAPI implements Schedulable {

    global void execute(SchedulableContext sc) {
        
        List<String> listOfDDTsForRegistrations = new List<String>();
        List<String> listOfDDTsForFileUpload = new List<String>();
        List<String> listOfDDTsForMandateEnquiry = new List<String>();
        Set<String> Bank_API_Sync_Status = new Set<String>{'Ready for Registration Mandate API','Registration Mandate API failed',
            												'Ready for file upload API','File upload API failed',
            												'Registration sent to bank','Mandate Enquiry API failed','Ready for Mandate Enquiry','Mandate Enquiry response received'}; //FIN-146
        List<DDTransaction__c> ddtList = [SELECT Id,BankAPIsyncstatus__c,TransactionStatus__c From DDTransaction__c 
                                         WHERE APIEnabled__c = TRUE AND Is_EDDS__c = FALSE AND BankAPIsyncstatus__c IN : Bank_API_Sync_Status];
        
        for(DDTransaction__c ddt : ddtList){
            //Registrations
            if(ddt.BankAPIsyncstatus__c == 'Ready for Registration Mandate API' || ddt.BankAPIsyncstatus__c == 'Registration Mandate API failed'){
                listOfDDTsForRegistrations.add(ddt.Id);
            }
            //FileUploads
            if(ddt.BankAPIsyncstatus__c == 'Ready for file upload API' || ddt.BankAPIsyncstatus__c == 'File upload API failed'){
                listOfDDTsForFileUpload.add(ddt.Id);
            }
            //Mandate Enquiries
            if(ddt.BankAPIsyncstatus__c == 'Registration sent to bank' || ddt.BankAPIsyncstatus__c == 'Mandate Enquiry API failed' || ddt.BankAPIsyncstatus__c == 'Ready for Mandate Enquiry' ||
                (ddt.BankAPIsyncstatus__c == 'Mandate Enquiry response received' && ddt.TransactionStatus__c != 'Rejected' && ddt.TransactionStatus__c != 'Approved')){ //FIN-146
                listOfDDTsForMandateEnquiry.add(ddt.Id);
            }
        }
        
        if(listOfDDTsForRegistrations.size()>0){
            BatchToDirectDebitCalloutAPI batch = new BatchToDirectDebitCalloutAPI(listOfDDTsForRegistrations, 'Registration', 'New Registration');
            Database.executeBatch(batch, 1);
        }
        if(listOfDDTsForFileUpload.size()>0){
            BatchToDirectDebitCalloutAPI batch = new BatchToDirectDebitCalloutAPI(listOfDDTsForFileUpload, 'FileUpload', 'New Registration');
            Database.executeBatch(batch, 1);
        }
        if(listOfDDTsForMandateEnquiry.size()>0){
            BAtchToDirectDebitEnquiryCalloutAPI batch = new BAtchToDirectDebitEnquiryCalloutAPI(listOfDDTsForMandateEnquiry, 'MandateEnquiry','New Registration'); 
			Database.executeBatch(batch, 1);
        }
    }
}