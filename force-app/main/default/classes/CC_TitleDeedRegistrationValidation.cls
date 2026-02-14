/*
* SR Type : Title Deed Registration
* Purpose : To validate if the requried fields are filled.
*/
global without sharing class CC_TitleDeedRegistrationValidation implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{
            
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_TitleDeedRegistrationValidation: Invalid SR or SR Step';
            }else{
                
                HexaBPM__Service_Request__c sRRecord = [SELECT Id, Name, HexaBPM__Customer__c, SalesOrder__r.Account__c, ElectronicServiceCharge__c, Pay_By__c, Proceed_with_Offline__c, PremiseRequired__c, ApplicationNumber__c, ApplicationDate__c, InProgressDate__c, RegistrationDate__c, EvaluationFee__c, EvaluationApplicationNumber__c, Unit__r.Name, HexaBPM__Contact__c, SalesOrder__c, MortgageApplicable__c, MortgageApplicationNumber__c, MortgageBank__c, MortgageAmount__c, TitleDeedRegistrationFee__c, MortgageRegistrationFees__c, MortgageConfirmationDate__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                
                List<String> errorsMessages = new List<String>();
                
                if(stp.HexaBPM__Summary__c == 'CM Validation'){
                    if(sRRecord.MortgageApplicable__c == 'Yes' && (sRRecord.MortgageApplicationNumber__c == null || sRRecord.MortgageConfirmationDate__c == null || sRRecord.MortgageAmount__c == null || String.isBlank(sRRecord.MortgageBank__c) || sRRecord.MortgageRegistrationFees__c == null)){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.MORTGAGE_DETAILS_VALIDATION).Message__c);
                    }
                } else if(stp.HexaBPM__Summary__c == 'Initiate Registration') {
                    if(sRRecord.Pay_By__c == null) {
                        errorsMessages.add(Utilities.getSystemMessages(Constants.PAY_BY_DETAILS_VALIDATION).Message__c);
                    } else if(!sRRecord.Proceed_with_Offline__c){
                        ID jobID = System.enqueueJob(new DARIRegistrationQueueable('createApplication', sRRecord.Id));
                    }
                } else if(stp.HexaBPM__Summary__c == 'Mortgage Registration') {
                    if(!sRRecord.Proceed_with_Offline__c){
                        ID jobID = System.enqueueJob(new DARIRegistrationQueueable('postMortgageDetails', sRRecord.Id));
                    }
                } else if(stp.HexaBPM__Summary__c == 'Fetch Application') {
                    if(!sRRecord.Proceed_with_Offline__c){
                        ID jobID = System.enqueueJob(new DARIRegistrationQueueable('fetchApplication', sRRecord.Id));
                    }
                }else if(stp.HexaBPM__Summary__c == 'Registration In Progress') {
                    soOtherChargesCreation(sRRecord);
                    if(!sRRecord.Proceed_with_Offline__c) {
                        if(srRecord.PremiseRequired__c) {
                            ID jobID = System.enqueueJob(new DARIRegistrationQueueable('postPropertyDetails', sRRecord.Id));
                        } else {
                            ID jobID = System.enqueueJob(new DARIRegistrationQueueable('postRegistrationFeeDetails', sRRecord.Id));
                        }
                    }                    
                } else if(stp.HexaBPM__Summary__c == 'Salesforce - Approval') {
                    if(!sRRecord.Proceed_with_Offline__c) {
                        if(stp.HexaBPM__Step_Status__c == Constants.STEP_ACCEPTED_STATUS) {
                            ID jobID = System.enqueueJob(new DARIRegistrationQueueable('postDeveloperApproval', sRRecord.Id));
                        } else if(stp.HexaBPM__Step_Status__c == Constants.STEP_REJECTED_STATUS) {
                            ID jobID = System.enqueueJob(new DARIRegistrationQueueable('cancellationApp', sRRecord.Id));
                        }
                    }
                } else if(stp.HexaBPM__Summary__c == 'Capture Fee Details') {
                    errorsMessages = captureFeeDetailsValidation(sRRecord);
                } else if(stp.HexaBPM__Summary__c == 'Payment Step') {
                    errorsMessages = registrationInProgressValidation(sRRecord);
                    if(sRRecord.Pay_By__c != null && sRRecord.Pay_By__c == 'BUYER') {
                        errorsMessages.add('Developer can not Pay, as Payer should be the Buyer.');
                    }
                    
                    if(errorsMessages.isEmpty() && !sRRecord.Proceed_with_Offline__c) {
                        ID jobID = System.enqueueJob(new DARIRegistrationQueueable('dmtRegFeePayments', sRRecord.Id));
                    }
                } else if(stp.HexaBPM__Summary__c == 'Registration Completion') {
                    errorsMessages = registrationCompletionValidation(sRRecord);
                    if(errorsMessages.size() == 0) {
                        soFieldMapping(sRRecord); 
                    }                    
                } else if(stp.HexaBPM__Summary__c == 'SOA Verification') {
                    soaVerification(sRRecord);
                }  else if(stp.HexaBPM__Summary__c == 'Evaluation Submission') {
                    errorsMessages = submissionOfEvaludationValidation(sRRecord);
                } else if(stp.HexaBPM__Summary__c == 'Customer Payment') {
                     errorsMessages = customerPaymentSOCvalidation(sRRecord.Id);
                }
                
                if(!errorsMessages.isEmpty()) {
                    String errorString = errorsMessages.toString();
                    return errorString.substring(1,errorString.length()-1).replace(',',' | ');
                }
            }
        } catch(Exception e){
            result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_TitleDeedRegistrationValidation';
        }
        return result;
    }
    
    public static List<String> submissionOfEvaludationValidation(HexaBPM__Service_Request__c sRRecord) {
        
        List<String> errorsMessages = new List<String>();
        
        if(sRRecord.EvaluationFee__c == null || sRRecord.EvaluationApplicationNumber__c == null){
            errorsMessages.add(Utilities.getSystemMessages(Constants.TITLE_DEED_REG_EVALUATION_VALIDATION).Message__c);
        }
        return errorsMessages;
    }
    
    /*
*  To validate Initiate Registration Step
* 
*/
    public static List<String> initiateRegistrationValidation(HexaBPM__Service_Request__c sRRecord) {
        
        List<String> errorsMessages = new List<String>();
        
        if(String.isBlank(sRRecord.ApplicationNumber__c)){
            errorsMessages.add(Utilities.getSystemMessages(Constants.TITLE_DEED_REG_APPLICATION_NUMBER_VALIDATION).Message__c);
        }
        if(sRRecord.ApplicationDate__c == null){
            errorsMessages.add(Utilities.getSystemMessages(Constants.TITLE_DEED_REG_APPLICATION_DATE_VALIDATION).Message__c);
        }
        return errorsMessages;
    }
    
    /*
*  To validate Registration In Progress Step
* 
*/
    public static List<String> registrationInProgressValidation(HexaBPM__Service_Request__c sRRecord) {
        
        List<String> errorsMessages = new List<String>();
        
        if(sRRecord.InProgressDate__c == null){
            errorsMessages.add(Utilities.getSystemMessages(Constants.TITLE_DEED_REG_IN_PROGRESS_DATE_VALIDATION).Message__c);
        }
        
        if(String.isBlank(sRRecord.ApplicationNumber__c)){
            errorsMessages.add(Utilities.getSystemMessages(Constants.TITLE_DEED_REG_APPLICATION_NUMBER_VALIDATION).Message__c);
        }
        
        if(sRRecord.ApplicationDate__c == null){
            errorsMessages.add(Utilities.getSystemMessages(Constants.TITLE_DEED_REG_APPLICATION_DATE_VALIDATION).Message__c);
        }
        return errorsMessages;
    }
    
    /*
*  To validate Registration Completion Step
* 
*/
    public static List<String> registrationCompletionValidation(HexaBPM__Service_Request__c sRRecord) {
        
        List<String> errorsMessages = new List<String>();
        
        if(sRRecord.RegistrationDate__c == null){
            errorsMessages.add(Utilities.getSystemMessages(Constants.TITLE_DEED_REG_REGISTRATION_DATE_VALIDATION).Message__c);
        }
        return errorsMessages;
    }
    
    /*
*  To validate Registration Completion Step
* 
*/
    public static void soaVerification(HexaBPM__Service_Request__c sRRecord) {
        
        String orgWideEmailAddress='';
        for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE limit 1 ]){
            orgWideEmailAddress=tempRec.id;
        }
        
        string emailTemplateId ='';
        for(Emailtemplate tempRec:  [select id, DeveloperName from emailtemplate where DeveloperName = 'TitleDeedRegistrationPaymentConfirmationNotice' limit 1]){
            emailTemplateId=tempRec.Id;
        }
        String fileName = 'SOA - '+sRRecord.Unit__r.Name+' - '+sRRecord.Name+' - '+Date.Today();
        //SRUtility.generatePdfAndSendEmail(sRRecord.HexaBPM__Contact__c, emailTemplateId, sRRecord.Id, orgWideEmailAddress, sRRecord.SalesOrder__c, fileName);
    }
    /*
*  To validate Registration Completion Step
* 
*/
    public static void soFieldMapping(HexaBPM__Service_Request__c sRRecord) {
        SalesOrder__c soRecord = new SalesOrder__c();
        soRecord.Id = sRRecord.SalesOrder__c;
        soRecord.TitleDeedRegistrationNumber__c = sRRecord.ApplicationNumber__c;
        soRecord.TitleDeedRegistrationStatus__c = 'Registered';
        soRecord.MortgageApplicable__c = sRRecord.MortgageApplicable__c == 'Yes' ? 'Yes, With ADM' : sRRecord.MortgageApplicable__c;
        soRecord.MortgageApplicationNumber__c = sRRecord.MortgageApplicationNumber__c;
        soRecord.MortgageBankAccount__c = sRRecord.MortgageBank__c;
        soRecord.MortgageAmount__c = sRRecord.MortgageAmount__c;
        
        update soRecord;
    }
    
    /*
*  To Create SO Other Charges for fees
* 
*/
    public static void soOtherChargesCreation(HexaBPM__Service_Request__c sRRecord) {
        
        List<SalesOrderOtherCharges__c> soOtherChargesList = new List<SalesOrderOtherCharges__c>();
        
        if(sRRecord.ElectronicServiceCharge__c > 0){
            SalesOrderOtherCharges__c soRec = SRUtility.createSalesOrderOtherChargeFromSO(sRRecord.SalesOrder__r, 'Electronic Service Charge', '', sRRecord.ElectronicServiceCharge__c, sRRecord);
            soOtherChargesList.add(soRec);
        }
        if(sRRecord.TitleDeedRegistrationFee__c > 0){
            SalesOrderOtherCharges__c soRec = SRUtility.createSalesOrderOtherChargeFromSO(sRRecord.SalesOrder__r, 'Title Deed Registration Fee', '', sRRecord.TitleDeedRegistrationFee__c, sRRecord);
            soOtherChargesList.add(soRec);
        }
        if(sRRecord.MortgageRegistrationFees__c > 0){
            SalesOrderOtherCharges__c soRec = SRUtility.createSalesOrderOtherChargeFromSO(sRRecord.SalesOrder__r, 'Mortgage Registration Fees', '', sRRecord.MortgageRegistrationFees__c, sRRecord);
            soOtherChargesList.add(soRec);
        }
        insert soOtherChargesList;
        
    }
    
    /*
*  To validate Sales Orders Other Charges
* 
*/
    public static List<String> captureFeeDetailsValidation(HexaBPM__Service_Request__c sRRecord) {
        
        List<SalesOrderOtherCharges__c> soOtherChargesList = [Select Id, Name, FeePaidTo__c, AmountReceived__c, TypeOfCharge__c From SalesOrderOtherCharges__c Where ServiceRequest__c =: sRRecord.Id];
        List<String> errorsMessages = new List<String>();
        
        for (SalesOrderOtherCharges__c soOtherCharges : soOtherChargesList) {
            if(soOtherCharges.FeePaidTo__c == null){
                errorsMessages.add('Kindly populate \'Fee Paid To\' field on '+soOtherCharges.TypeOfCharge__c+' SO Other Charges: '+soOtherCharges.Name);
            } else if(soOtherCharges.FeePaidTo__c == 'Aldar' && soOtherCharges.AmountReceived__c == null){
                errorsMessages.add('Kindly create a receipt for '+soOtherCharges.TypeOfCharge__c+' SO Other Charges: '+soOtherCharges.Name);
            }
        }
        return errorsMessages;
    }
        public static List<string> customerPaymentSOCvalidation(Id srId){
        List<String> errorsMessages = new List<String>();
        SalesOrderOtherCharges__c soc = [SELECT Id,Amount__c,PendingAmount__c,AmountReceived__c FROM SalesOrderOtherCharges__c WHERE TypeOfCharge__c = 'Title Deed Registration Fee' AND ServiceRequest__c =:srId LIMIT 1];
        if(soc.AmountReceived__c == null || soc.AmountReceived__c == 0 || (soc.AmountReceived__c != null && soc.Amount__c > (soc.AmountReceived__c+10))){
             errorsMessages.add('Please Clear the "Title Registration Fee" to proceed.');
        }
        return errorsMessages;
    }
}