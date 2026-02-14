global without sharing class CC_ValidateSPARegistrationDate implements HexaBPM.iCustomCodeExecutable{
    global string EvaluateCustomCode(HexaBPM__Service_Request__c ServiceReqObj, HexaBPM__Step__c stp){
        try{
            string result ='Success';
           
            HexaBPM__Step__c step =[select Id,HexaBPM__Summary__c from HexaBPM__Step__c where Id =: stp.Id];
           
            if(stp == null || stp.HexaBPM__SR__c == null){                
                return 'CC_ValidateSPARegistrationDate: Invalid SR or SR Step';
            }else{
                if(step.HexaBPM__Summary__c == 'Prepare & Verify the Investor Certificate'){
                    
                    HexaBPM__Service_Request__c serviceRequest1 = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];                    
                    if(serviceRequest1.SPARegistrationDate__c == null)
                    {
                        system.debug('Inside SPA Registration');
                        return  'Please enter SPA registration Date';
                    }
                }
                return null;
            }
        }catch(Exception ex){           
            return ex.getMessage()+'  Line:'+ex.getLineNumber()+' :CC_ShareInvestorCertificateCtrl';
        }
       // return null;
    }
    
}