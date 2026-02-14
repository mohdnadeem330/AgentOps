@RestResource (urlMapping = '/getLeadPicklistValues')
global class getLeadPicklistValuesWebservice {

     @HttpGet
    global static void doGet() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, List<String>> propProjMap = new Map<String, List<String>>();
            Map<String, List<String>> finalpropProjMap = new Map<String, List<String>>();
            List<String> projectListForStaff = System.Label.ProjectListForStaff.split(';');
            projectListForStaff.AddAll(System.Label.ProjectListForStaff2.split(';'));
            propProjMap = InterDepartmentalReferralController.getDependentMap('PropertyUsage__c','Project__c');
            LeadWrapper leadwrap = new LeadWrapper();
            for(String str: propProjMap.keySet()){
                if(str == 'Residential Land' || str == 'Residential Sale'){
                    if(propProjMap.get(str) != null){
                        List<String> projectList = propProjMap.get(str);
                        List<String> finalProjectList = new List<String>();
                        for(String projStr: projectList){
                            if(!projectListForStaff.contains(projStr)){
                                finalProjectList.add(projStr);
                            }
                        }
                        
                        if(str == 'Residential Sale'){
                            str = 'Residential Property';   
                        }
                        
                        finalpropProjMap.put(str, finalProjectList);
                    }
                }  
            }
            //code added by Noor
             // Get picklist values for CustomerLocation__c field on Lead
            Schema.DescribeFieldResult fieldResult = Lead.CustomerLocation__c.getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

            List<String> picklistValues = new List<String>();
            for (Schema.PicklistEntry entry : picklistEntries) {
                if (entry.isActive()) {
                    picklistValues.add(entry.getValue());
                }
            }

             leadwrap.customerCity = picklistValues; // till here
            
            leadwrap.propertyProjectMap = finalpropProjMap;
            handler.response.success = true;
            handler.response.data = leadwrap ;
            handler.finalize();
        }catch(Exception ex) {            
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        } 
    }
    public class LeadWrapper {
        public Map<String, List<String>> propertyProjectMap; 
        public List<String> customerCity;

    }
}