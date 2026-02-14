@RestResource (urlMapping = '/create/relationship')
global with sharing class CreateAccountRelationshipWebService {
    
    @HttpPost
    global static void doPost(String accountId, String relatedAccountId, String relationshipType) {   
        RestContextHandler handler = new RestContextHandler(false);
        try{

            AccountRelationship__c accountRelationship = new AccountRelationship__c();

            if(accountId != Null && relatedAccountId != Null && relationshipType != Null)
            {
                accountRelationship.Account__c = accountId;
                accountRelationship.RelatedAccount__c = relatedAccountId ;
                accountRelationship.RelationshipType__c = relationshipType;
                insert accountRelationship;
            }

            handler.response.success = true;
            handler.response.data = accountRelationship ;
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
            System.debug('msg '+ex.getMessage());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);            
        }
    }
}