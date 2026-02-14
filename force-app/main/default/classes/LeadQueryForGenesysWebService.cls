@RestResource (urlMapping = '/query/lead/genesys')
global with sharing class LeadQueryForGenesysWebService 
{
    @HttpPost
    global static void doPost(String leadRecordId)
    {
        RestContextHandler handler = new RestContextHandler(true);
        try 
        {
            if(String.isNotBlank(leadRecordId) && leadRecordId != null && leadRecordId != ''){
                Lead queriedLead = [SELECT id, 
                                    Project__c, 
                                    UnitType__c, 
                                    NumberOfBedrooms__c, 
                                    CustomerBudget__c, 
                                    PurposeOfUse__c, 
                                    Financing__c  
                                    FROM Lead 
                                    WHERE Id = :leadRecordId ];
                
                handler.response.data = queriedLead;
            }
            handler.response.message = 'Lead Queried Successfully';
            handler.response.success = true;
            handler.finalize();
        }
        
        catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            //handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.response.message = ex.getStackTraceString() + ex.getMessage();
            handler.finalize(ex);
        }
    }
    
}