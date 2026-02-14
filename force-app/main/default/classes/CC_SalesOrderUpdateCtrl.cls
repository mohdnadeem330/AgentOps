global class CC_SalesOrderUpdateCtrl implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_SalesOrderUpdateCtrl: Invalid SR or SR Step';
            }else{
                HexaBPM__Service_Request__c sRRecord = [SELECT Id,HexaBPM__Summary__c,SRType__c, ADMApplicationNumber__c,RegistrationDate__c,PaymentDate__c,SalesOrder__c,Proceed_with_Offline__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                List<String> errorsMessages = new List<String>();
                if(stp.HexaBPM__Summary__c == 'Payment Step' && sRRecord.SRType__c == 'SPA Registration'){
                    if(sRRecord.Proceed_with_Offline__c && (sRRecord.RegistrationDate__c == null || sRRecord.PaymentDate__c == null)){
                        errorsMessages.add(Utilities.getSystemMessages(Constants.SPA_COMPLETION_DETAILS_VALIDATION).Message__c);
                    }
                    if(!errorsMessages.isEmpty()){
                        return errorsMessages.toString().replace(',','\n');
                    }
                    SalesOrder__c so = new SalesOrder__c(Id = sRRecord.SalesOrder__c);
                    so.SPARegistrationStatus__c = 'Registered';
                    update so;
                }
            }
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            result = e.getMessage()+' :CC_SalesOrderUpdateCtrl';
        }
        return result;
    }
}