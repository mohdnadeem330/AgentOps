@RestResource (urlMapping = '/query/NagwaGetPin')
global with sharing class NagwaGetPinWebService {
    @HTTPPost
    global static void doPost(String actnumber){
        RestContextHandler handler = new RestContextHandler(false);  
        Account accountdetail = new Account();
        String query;
        try{
            if(actnumber!=null){
                query = 'select NAGWA_Pin__c from account where AccountNumber__c=:actnumber limit 1';
                accountdetail = Database.Query(query);
                
            }
            handler.response.data = accountdetail;
            handler.response.success = true;
            handler.finalize();
        }
        catch (DMLException exc) {handler.response.success    = false; handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = exc.getDMLMessage(0);   handler.finalize(exc);
        } catch (Exception ex) { handler.response.success    = false; handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = Constants.MESSAGE_GENERIC_ERROR; handler.finalize(ex);            
        }
    }   
}