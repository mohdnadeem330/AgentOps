@RestResource (urlMapping = '/upsert/jointonwer')
global with sharing class CreateUpdateJointOwnerWebService {
    @HTTPPost
    global static void doPost(Id salesOrderId, String jointOwnerId, String accountId, String sharePercentage, Boolean isDelete, Decimal expectedAmount){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            JointOwner__c jointOwner = new JointOwner__c();

            if(String.isNotBlank(jointOwnerId) && jointOwnerId != null)
                jointOwner.Id = jointOwnerId;

                if(salesOrderId != null && accountId != null && sharePercentage != null)
                {
                    jointOwner.SalesOrder__c = salesOrderId;
                    jointOwner.Account__c = accountId;
                    jointOwner.SharePercentage__c = Decimal.valueOf(sharePercentage);
                    // Add joint owner expected amount
                    jointOwner.Expected_Amount__c = expectedAmount;
                }
            

            List<AccountRelationship__c> AccountRelationshipList = createJointOwnersController.getRelationType(salesOrderId);
            String relationType;

            for(AccountRelationship__c acc : AccountRelationshipList)
            {
                if(acc.RelatedAccount__c == accountId)
                    relationType = acc.RelationshipType__c;
            }

            jointOwner.RelationshipType__c = relationType;
            if(isDelete != null)
                jointOwner.IsDeleted__c = isDelete;//Boolean.valueOf(isdelete);
            upsert jointOwner;
            
            handler.response.success = true;
            handler.response.data = jointOwner ;
            handler.finalize();

        }
        catch (DMLException exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        } catch (Exception ex) {
            System.debug('msg '+ex.getMessage());
            System.debug('line no '+ex.getLineNumber());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);            
        }
            
        
    }
}