/*
* SR Type : SPA & Title Deed Registration For Ready Properties
* Purpose : To validate if the requried fields are filled.
*/
global without sharing class CC_SPAReadyPropertiesValidation implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_SPATitleDeedForReadyPropertiesValidation: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id,Name, HexaBPM__Customer__c, SalesOrder__r.Account__c, ElectronicServiceCharge__c, TitleDeedRegistrationFee__c, MortgageRegistrationFees__c, InProgressDate__c, MortgageAmount__c, MortgageBank__c, MortgageApplicationNumber__c, MortgageApplicable__c, PaymentDate__c, SPARegistrationDate__c, RegistrationDate__c,EvaluationFee__c,EvaluationApplicationNumber__c,ApplicationNumber__c, SalesOrder__c,ApplicationDate__c, SPAApplicationNumber__c, SPAApplicationDate__c, HexaBPM__Contact__c, Unit__r.Name, Unit__c, MortgageConfirmationDate__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                
                List<String> errorsMessages = new List<String>();

                if(stp.HexaBPM__Summary__c == 'CM Validation'){
                    if(sRRecord.MortgageApplicable__c == 'Yes' && (sRRecord.MortgageApplicationNumber__c == null || sRRecord.MortgageConfirmationDate__c == null || sRRecord.MortgageAmount__c == null || String.isBlank(sRRecord.MortgageBank__c) || sRRecord.MortgageRegistrationFees__c == null)){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.MORTGAGE_DETAILS_VALIDATION).Message__c);
                    }

                } else if(stp.HexaBPM__Summary__c == 'Verification & Submission of the Request For SPA'){
                    errorsMessages = spaRegistrationCompletionRegistrationValidation(sRRecord);

                } else if(stp.HexaBPM__Summary__c == 'SOA Verification'){
                    soaVerification(sRRecord);

                } else if(stp.HexaBPM__Summary__c == 'Evaluation Submission & Payment Completion'){
                    errorsMessages = submissionOfEvaludationValidation(sRRecord);

                } else if(stp.HexaBPM__Summary__c == 'Initiate Registration For Title Deed'){
                    errorsMessages = initiateRegistrationValidation(sRRecord);

                } else if(stp.HexaBPM__Summary__c == 'Registration In Progress For Title Deed'){
                    errorsMessages = registrationInProgressValidation(sRRecord);

                    if(errorsMessages.isEmpty()){
                        soOtherChargesCreation(sRRecord);
                    }

                } else if(stp.HexaBPM__Summary__c == 'Registration Completion For Title Deed'){
                    errorsMessages = registrationCompletionValidation(sRRecord);

                    if(errorsMessages.size() == 0){
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

                } else if(stp.HexaBPM__Summary__c == 'SPA Registration Completion For SPA'){

                    if(sRRecord.PaymentDate__c == null || sRRecord.SPARegistrationDate__c == null){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.SPA_COMPLETION_DETAILS_VALIDATION).Message__c);

                    } else {
                        SalesOrder__c so = new SalesOrder__c(Id = sRRecord.SalesOrder__c);
                        so.SPARegistrationStatus__c = 'Registered';
                        update so;
                    }
                }
                
                if(!errorsMessages.isEmpty()){
                    String errorString = errorsMessages.toString();
                    return errorString.substring(1,errorString.length()-1).replace(',',' | ');
                }
            }
        } catch(Exception e){
            result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_SPATitleDeedForReadyPropertiesValidation';
        }
        return result;
    }

    /*
    *  To validate Initiate Registration Step
    * 
    */
    public static List<String> spaRegistrationCompletionRegistrationValidation(HexaBPM__Service_Request__c sRRecord) {

        List<String> errorsMessages = new List<String>();

        if(String.isBlank(sRRecord.SPAApplicationNumber__c)){
            errorsMessages.add(Utilities.getSystemMessages(Constants.SPA_APPLICATION_NUMBER_VALIDATION).Message__c);
        }
        if(sRRecord.SPAApplicationDate__c == null){
            errorsMessages.add(Utilities.getSystemMessages(Constants.SPA_APPLICATION_DATE_VALIDATION).Message__c);
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
    public static List<String> submissionOfEvaludationValidation(HexaBPM__Service_Request__c sRRecord) {

        List<String> errorsMessages = new List<String>();

        if(sRRecord.EvaluationFee__c == null || sRRecord.EvaluationApplicationNumber__c == null){
            errorsMessages.add(Utilities.getSystemMessages(Constants.TITLE_DEED_REG_EVALUATION_VALIDATION).Message__c);
        }
        return errorsMessages;
    }

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
        if(sRRecord.EvaluationFee__c > 0){
            SalesOrderOtherCharges__c soRec = SRUtility.createSalesOrderOtherChargeFromSO(sRRecord.SalesOrder__r, 'Evaluation Fee', '', sRRecord.EvaluationFee__c, sRRecord);
            soOtherChargesList.add(soRec);
        }
        insert soOtherChargesList;

    }
}