@RestResource (urlMapping = '/get/staffReferralLeads')
global class getStaffReferralLeadsWebService {

    @HttpPost
    global static void doPost(String employeeEmail, String employeeId){ 
        RestContextHandler handler = new RestContextHandler(false);
        try{
            staffReferralWrapper wrap = new staffReferralWrapper();
            List<Lead> staffLeads = new List<Lead>();
            List<leadWrapper> leadwraplist = new List<leadWrapper>();
            Set<String> leadNumberSet = new Set<String>();
            Map<String, SalesOrder__c> leadSOMap = new Map<String, SalesOrder__c>();
            List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
            Map<String, List<String>> propProjMap = new Map<String, List<String>>();
            Map<String, List<String>> finalpropProjMap = new Map<String, List<String>>();
            
        if(employeeEmail != null && employeeId != null && employeeEmail != '' && employeeId != ''){
            staffLeads = [SELECT
                          Id,
                          Name,
                          LeadNumber__c,
                          Status
                          FROM Lead
                          WHERE (EmployeeEmail__c =:employeeEmail
                          AND EmployeeId__c =:employeeId) ORDER BY CREATEDDATE DESC];
        }
        
        
        for(Lead lead:staffLeads){
            leadNumberSet.add(lead.LeadNumber__c);
        }
        if(!leadNumberSet.isEmpty()){
            salesOrderList = [Select Id, Status__c, Opportunity__c, Opportunity__r.LeadNumber__c FROM SalesOrder__c WHERE Opportunity__c in (SELECT Id from Opportunity WHERE LeadNumber__c in:leadNumberSet )];
        }
            system.debug('salesOrderList::'+salesOrderList);
        if(!salesOrderList.isEmpty()){
            for(SalesOrder__c so:salesOrderList){ leadSOMap.put(so.Opportunity__r.LeadNumber__c, so);
            }
        }            
        
        for(Lead lead : staffLeads){
            string soStatus = '';
            leadWrapper leadwrap = new leadWrapper();
            leadwrap.leadNumber = lead.LeadNumber__c;
            leadwrap.leadName = lead.Name;
            
            if(leadSOMap.containsKey(lead.LeadNumber__c)){
                if(leadSOMap.get(lead.LeadNumber__c).Status__c == 'Sold'){ soStatus = 'Sold';  
                }else if(leadSOMap.get(lead.LeadNumber__c).Status__c.contains('Cancelled')){soStatus = 'Cancelled';    
                }
            }
            if(lead.Status == 'New Lead' || lead.Status == 'In Progress Lead' || lead.Status == 'Qualified Lead'){
                leadwrap.referralStatus = 'Referred';
            }else if(lead.Status == 'Duplicate Lead' || lead.Status == 'Retired Lead' || soStatus == 'Cancelled'){ leadwrap.referralStatus = 'Retired';
            }else if(soStatus=='Sold'){ leadwrap.referralStatus = 'Unit Sold'; 
            }
            leadwraplist.add(leadwrap);
        }
        system.debug('leadwraplist'+leadwraplist);
        wrap.staffLeads = leadwraplist;
     /*   propProjMap = InterDepartmentalReferralController.getDependentMap('PropertyUsage__c','Project__c');
        system.debug('propProjMap::'+propProjMap);
       
            for(String str: propProjMap.keySet()){
                if(str == 'Residential Land' || str == 'Residential Sale'){
                    if(propProjMap.get(str) != null){
                        List<String> projectList = propProjMap.get(str);
                        if(str == 'Residential Sale'){
                          str = 'Residential Property';   
                        }
                       
                        finalpropProjMap.put(str, projectList);
                    }
                }  
            }
        system.debug('finalpropProjMap:::'+finalpropProjMap);   
        wrap.propertyProjectMap = finalpropProjMap; 
        system.debug('wrap.propertyProjectMap:::'+wrap.propertyProjectMap);*/
        handler.response.success = true;
        handler.response.data = wrap ;
        handler.finalize();
        }catch(Exception ex) {            
            handler.response.success = false; handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage(); handler.finalize(ex);
        } 
    }
    
    public class staffReferralWrapper {
        public List<leadWrapper> staffLeads;
       // public Map<String, List<String>> propertyProjectMap;
        
    }
    public class leadWrapper{
        public string leadNumber;
        public string leadName;
        public string referralStatus;
    }
    
 /*public static List<String> picklistValues(String objectName, String fieldName) {
        List<String> values = new List<String>();
        List<Schema.DescribeSobjectResult> results = Schema.describeSObjects(new List<String>{objectName});
        for(Schema.DescribeSobjectResult res : results) {
            for (Schema.PicklistEntry entry : res.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    values.add(entry.getValue());
                }
            }
        }
        system.debug('values::'+values);
        return values;
    } */
}

/*
 *services/apexrest/get/staffReferralLeads 
 * {
"employeeEmail":"emp@aldar.com",
"employeeId":"87654567"
}
 */