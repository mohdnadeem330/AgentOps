@RestResource (urlMapping = '/generate/documents')
global without sharing class AccountDocumentGeneratorService {

    @HttpPost
    global static void doPost() {   
        RestContextHandler handler = new RestContextHandler(false);
        Savepoint sp = Database.setSavepoint();
        try {            
            Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();
            Utilities.objType = 'Account';
            
            if(mapFieldApiFieldValues == null){
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = 'Please provide valide request body params.';
                handler.finalize();
                return;
            }
            if(mapFieldApiFieldValues != null && !mapFieldApiFieldValues.keySet().contains('accountId')) {
                handler.response.success = false;   
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = 'Value for accountId is mandatory.';
                handler.finalize();
                return;
            }
            // call generate document service
            Boolean success = AccountDocumentGenerator.generateAllDocuments(mapFieldApiFieldValues.get('accountId'));
            if (success) {
                handler.response.success = true;
                handler.response.message = 'Documents generated successfully.';
                handler.response.statusCode = Constants.STATUS_CODE_SUCCESS;
                handler.finalize();
            } else {
                handler.response.success = false;                
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.finalize();
            }                  
        }
        // catch (DMLException exc) {
        //     Database.rollback(sp);
        //     handler.response.success = false;   
        //     handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
        //     handler.response.message = exc.getDMLMessage(0);
        //     handler.finalize(exc);
        // }
        catch (Exception exc) {
            Database.rollback(sp);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    }
}

// Sample req & res
// Endpoint - /services/apexrest/generate/documents
/*
Request - 
{
    "accountId":"0018d00000ECRjaAAH"
}
Response - 
{
    "success":true,
    "statusCode":200,
    "requestId":null,
    "message":"Success",
    "data":null
}*/