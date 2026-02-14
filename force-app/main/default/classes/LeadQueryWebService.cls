@RestResource (urlMapping = '/query/lead')
global with sharing class LeadQueryWebService {
    
    public static Set<String> LEAD_STATUS = new Set<String>{'New Lead','In Progress Lead','Qualified Lead'};
    
    @HttpPost
    global static void doPost() {   
        RestContextHandler handler = new RestContextHandler(false);
        try {
            LeadDetailResponse detailResponse = new LeadDetailResponse();
            detailResponse.hasInterDeptReferral = false;
            detailResponse.hasVerifyLead = false;
            Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();
            Utilities.objType = 'Lead';
            
            if (mapFieldApiFieldValues != null && mapFieldApiFieldValues.keySet().contains('Id')) {
                String leadId = mapFieldApiFieldValues.get('Id');
                Lead leadRecord = LeadService.fetchLeadById(leadId);
//                Lead queriedLead = LeadService.fetchLeadById(leadId);
//                handler.response.data = queriedLead;
                if(leadRecord.ExistingAccount__c == null && LEAD_STATUS.contains(leadRecord.Status)){
                    detailResponse.hasVerifyLead = true;
                }
                if(leadRecord.SkipDuplicateApprovalStatus__c=='Approved'){
                    detailResponse.hasVerifyLead = false;
                }
                detailResponse.leadRecord = leadRecord;
                handler.response.data = detailResponse;
            }
              // added by Arvind 
            else if (mapFieldApiFieldValues != null && mapFieldApiFieldValues.keySet().contains('Application_Number__c') && mapFieldApiFieldValues.keySet().contains('NationalId__c') && mapFieldApiFieldValues.keySet().contains('MobilePhone') )
            {
                String appNumber = mapFieldApiFieldValues.get('Application_Number__c');
                String EmiratesId = mapFieldApiFieldValues.get('NationalId__c');
                String MobileNumberwithCountrycode = mapFieldApiFieldValues.get('MobilePhone');
                List<Lead> queriedLead = LeadService.fetchLeadByAppNumber(appNumber,emiratesId,mobileNumberwithCountrycode);
                if(queriedLead.size() > 0)
                {
                    handler.response.data = queriedLead[0];
                  
                }
                else
                {
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
    global class LeadDetailResponse {
        
        public boolean hasInterDeptReferral;
        public boolean hasVerifyLead;
        public Lead leadRecord;
        
        public LeadDetailResponse(){
            this.leadRecord = new Lead();
            
        }
    }
}