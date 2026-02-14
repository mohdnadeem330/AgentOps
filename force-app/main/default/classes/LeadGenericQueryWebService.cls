@RestResource (urlMapping = '/query/lead/generic')
global with sharing class LeadGenericQueryWebService {
    
    @HttpPost

    global static void doPost() {   
        RestContextHandler handler = new RestContextHandler(false);
        try {
            
            Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();
            Utilities.objType = 'Lead';
            
            if (mapFieldApiFieldValues != null && mapFieldApiFieldValues.keySet().contains('Id')) {
                String leadId = mapFieldApiFieldValues.get('Id');
                Lead queriedLead = LeadService.fetchLeadById(leadId);
                handler.response.data = queriedLead;
            }
            //added by Rohit for Nagwa and Genesys
            else if (mapFieldApiFieldValues != null && mapFieldApiFieldValues.keySet().contains('LeadNumber__c')){
                String leadNumber = mapFieldApiFieldValues.get('LeadNumber__c');
                Lead queriedLead = LeadService.fetchLeadByLeadNumber(leadNumber);
                handler.response.data = queriedLead;
            }
            else if (mapFieldApiFieldValues != null && mapFieldApiFieldValues.keySet().contains('MobilePhone') && mapFieldApiFieldValues.keySet().contains('Nagwa')){
                String mobilePhone = mapFieldApiFieldValues.get('MobilePhone');
                List<Lead> queriedLead = LeadService.fetchLeadByMobilePhone(mobilePhone);
                if(queriedLead.size()>0){
                    handler.response.data = queriedLead;
                } else {
                    handler.response.message = 'No records found';
                }
                
            }
            
            else {
                List<Lead> leads = LeadService.fetchLeads(Utilities.getWhereConditionfrmMap(mapFieldApiFieldValues));
                LeadQueryResponse response = new LeadQueryResponse(leads, 'Lead', false);
                handler.response.data = response;
            }

            handler.response.success = true;
            handler.finalize();
        }
        catch (Exception exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    }
    
    global with sharing class LeadQueryResponse extends QueryResponse {

        Set<String> projects = new Set<String>();
        
        global LeadQueryResponse (List<SObject> records, String objectName, Boolean processRecords) {   
            super(records, objectName, processRecords);

            for (SObject record : records) {

                Lead leadRecord = (Lead) record;
                if (leadRecord.Project__c != null) 
                    projects.add(leadRecord.Project__c);
            }
        }
    }   
}