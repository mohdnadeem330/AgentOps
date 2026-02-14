@RestResource (urlMapping = '/upsert/relationship')
global with sharing class UpsertAccountRelationshipWebService {
    
    @HttpPost
    global static void doPost(String accountId, String relatedAccountId, String relationshipType, String relationshipId, String relationshipSubType, String expectedTransaction) {   
        RestContextHandler handler = new RestContextHandler(false);
        try{

            AccountRelationship__c accountRelationship = new AccountRelationship__c();

            if(accountId != Null && relatedAccountId != Null && relationshipType != Null)
            {
                accountRelationship.Account__c = accountId;
                accountRelationship.RelatedAccount__c = relatedAccountId ;
                accountRelationship.RelationshipType__c = relationshipType;
                accountRelationship.RelationshipSubType__c = relationshipSubType;
                accountRelationship.Amountoftransactionexpected__c = Decimal.valueOf(expectedTransaction);
                insert accountRelationship;
            }
            else if(relationshipId != Null && relatedAccountId != relationshipType){
                accountRelationship.Id = relationshipId;
                accountRelationship.RelationshipType__c = relationshipType;
                accountRelationship.RelationshipSubType__c = relationshipSubType;
                accountRelationship.Amountoftransactionexpected__c = Decimal.valueOf(expectedTransaction);
                update accountRelationship;
                
            }
            else {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = Constants.INVALID_REQUEST_BODY;
                //handler.finalize('Invalid Request Body');
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