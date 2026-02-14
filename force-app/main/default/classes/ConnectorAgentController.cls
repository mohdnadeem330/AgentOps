global without sharing class ConnectorAgentController {
	public ConnectorAgentController(Object o) { } 
    
    @RemoteAction
    global static Lead findLead(String id) {
        try{ 
			Lead leads = [Select id,OwnerId from Lead where Id =:id limit 1];
            System.debug('leads found : ' + leads);
            leads.GenesysBypassforOwnerChange__c = true;
            leads.OwnerId = UserInfo.getUserId();
            update leads;
            
            leads.GenesysBypassforOwnerChange__c = false;
            update leads;
            return leads;
        } catch(Exception e){
            	System.debug('Error in create lead ' + e);     
        }
    	return null;
    }    
}