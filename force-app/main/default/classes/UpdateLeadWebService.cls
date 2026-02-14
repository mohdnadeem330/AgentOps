/*
* Purpose : To query activities related to user
* Created by : Ajay Thakur
*/
@RestResource (urlMapping = '/update/lead')
global with sharing class UpdateLeadWebService {
    @HttpPost
    global static void doPost(Lead leadRecord) {   
        
        RestContextHandler handler = new RestContextHandler(false);
        
        try {  
                if (leadRecord.Id != Null) {
                    if(leadRecord.BAGIsRegisterFromWeb__c == null){
                        leadRecord.BAGIsRegisterFromWeb__c = false;
                    }
                    if(leadRecord.ExistingAccount__c != null){
                        UtilitiesWithoutSharing.updateLead(leadRecord);
                    }else {
                        update leadRecord;
                    }
                }
                handler.response.success = true;
                handler.response.data = leadRecord ;
                handler.finalize();
        }
        catch (DMLException exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }
        catch(Exception ex)
        {            
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
}