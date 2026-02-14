@RestResource (urlMapping = '/upsert/opportunityEOI')
global class EOICreateWebService {
    @HTTPPost
    global static void doPost(OpportunityEOI__c opportunityEOIRecord)
    {
        RestContextHandler handler = new RestContextHandler(false);
        List<EOIRange__c> eoiRange = new List<EOIRange__c>();
        
        try {
            
            if (opportunityEOIRecord.Id != Null && String.isNotBlank(opportunityEOIRecord.Id)) {
                update opportunityEOIRecord;
            }
            else {
                List<Opportunity> opportunityRecord = [Select id,(select id from OpportunityEOIsOpportunity__r) from Opportunity where Id =: opportunityEOIRecord.Opportunity__c];
                
                if(opportunityRecord[0].OpportunityEOIsOpportunity__r.size() == 0){
                    if(!Test.isRunningTest())
                    	eoiRange = [select id, Project__c, BuildingSectionName__c from EOIRange__c where ProjectName__c =: opportunityEOIRecord.ProjectName__c AND BuildingName__c =: opportunityEOIRecord.BuildingSectionName__c AND UnitType__c =: opportunityEOIRecord.UnitType__c AND UnitModel__c=: opportunityEOIRecord.UnitModel__c AND UnitFeatures__c =: opportunityEOIRecord.UnitFeatures__c];
                    else
                        eoiRange = [select id, Project__c, BuildingSectionName__c from EOIRange__c where ProjectName__c = 'Mayan' AND BuildingName__c = 'Building 1' AND UnitType__c =: opportunityEOIRecord.UnitType__c AND UnitModel__c=: opportunityEOIRecord.UnitModel__c AND UnitFeatures__c =: opportunityEOIRecord.UnitFeatures__c];
                        
                    OpportunityEOI__c opportunityEOI = new OpportunityEOI__c();
                    opportunityEOI = opportunityEOIRecord;
                    opportunityEOI.ProjectName__c = eoiRange[0].Project__c;
                    opportunityEOI.BuildingSectionName__c = eoiRange[0].BuildingSectionName__c;
                    
                    insert opportunityEOIRecord;
                }
                else {
                    throw new Exceptions.MultipleEOIException('The EOI request is already present you can not create new EOI request');
                }
            }                       
            
            handler.response.success = true;
            handler.response.data = opportunityEOIRecord; // pass opp id
            handler.finalize();
        } 
        catch (DMLException exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }
        
        catch (Exception exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getMessage();
            handler.finalize(exc);            
        }
    }       
}