@RestResource(urlMapping='/getConfigurations')
global class BP_Configurations extends BP_BaseRestResource{
    
    @HttpGet
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);
        try{
            BP_Configurations service = new BP_Configurations();
            Map<String, String> params = RestContext.request.params;
            ApiResponse response = service.processRequest(params, null);
            
            handler.response.data = response.data;
            handler.response.success = true;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;
        }catch (Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = ex.getMessage();
            
        } finally {
            handler.finalize();
        }
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            return new ApiResponse(true, 200, 'Data fetched successfully', getConfigurations());
        }catch (Exception e) {
           
            return new ApiResponse(false, 400, 'Failed to process the request: ' + e.getMessage(), null);
        }
    }

    global static ConfigurationsResponse getConfigurations() {
        ConfigurationsResponse response = new ConfigurationsResponse();
        getLeadPicklistValues(response);
        getCasePicklistValues(response);
        getInvoiceBundlePicklistValues(response);
        response.projectDetails = getProjectDetails();
        response.AppointmentProjects = AppointmentController.getAllProjects();
        response.AldarExpertsAppointmentProjects = AppointmentController.getEventProjects();
        response.RefferedBy = BrokerAgencyRegistrationController.getBrokerAndSalesManagers();
        response.AldarExpertsAppointmentCancel = AppointmentController.getCancellationReasonPicklist();
        response.projectPicklistValues = getProjectPicklistValues();

        response.brokertype = BrokerAgencyRegistrationController.getServiceRequestPicklistValues();
        response.AldarExpertsAppointmentButtonLabel = System.Label.AldarExpertsButtonLabel;
        response.AldarExpertsAppointmentButtonEnabled = System.Label.AldarExpertAppointmentToggle;
        response.DigitalNonLaunch = System.Label.DigitalNonLaunch;
        //response.brokerRequestTypes = System.Label.BrokerRequestTypes.split(',');
        response.refferedSource = getPicklistValuesToReturn('HexaBPM__Service_Request__c', 'ReferralSource__c');
        response.tradeLicenseType = getPicklistValuesToReturn('HexaBPM__Service_Request__c', 'TradeLicenseType__c');
        response.residentCountryOrNationality = getPicklistValuesToReturn('AgencyTeam__c', 'Country__c');
   
        return response;
    }

    global static List<Map<String, String>> getProjectDetails() {
        List<Map<String, String>> projectList = new List<Map<String, String>>();
        
        for (Project__c proj : [SELECT Name,id, ProjectCode__c, AppointmentSystemID__c, AppointmentSystemCode__c FROM Project__c]) {
            Map<String, String> projectMap = new Map<String, String>();
            projectMap.put('ProjectName', proj.Name);
            projectMap.put('ProjectId', proj.id);
            projectMap.put('ProjectCode', proj.ProjectCode__c);
            projectMap.put('projectId', proj.AppointmentSystemID__c);
            projectMap.put('AppointmentSystemCode',proj.AppointmentSystemCode__c);
            
            projectList.add(projectMap);
        }
        return projectList;
    }
        
 

    global static void getLeadPicklistValues(ConfigurationsResponse response) {
        
        List<String> types = new List<String>{'Lead'};
        Schema.DescribeSobjectResult[] result = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fieldsMap = result[0].fields.getMap();
        
        response.saleTypePropertyUsage = Utilities.getDependentPickListValues(fieldsMap.get('SalesType__c').getDescribe(),fieldsMap.get('PropertyUsage__c').getDescribe());
        response.propertyUsagebuyRent = Utilities.getDependentPickListValues(fieldsMap.get('PropertyUsage__c').getDescribe(),fieldsMap.get('BuyRent__c').getDescribe());
        response.propertyUsageCustomerBudget = Utilities.getDependentPickListValues(fieldsMap.get('PropertyUsage__c').getDescribe(),fieldsMap.get('CustomerBudget__c').getDescribe());
        response.propertyUsageProject = Utilities.getDependentPickListValues(fieldsMap.get('PropertyUsage__c').getDescribe(),fieldsMap.get('Project__c').getDescribe());
        response.propertyUsageUnitType = Utilities.getDependentPickListValues(fieldsMap.get('PropertyUsage__c').getDescribe(),fieldsMap.get('UnitType__c').getDescribe());
        response.methodOfContactEnquiryCategory = Utilities.getDependentPickListValues(fieldsMap.get('LeadSource').getDescribe(),fieldsMap.get('EnquiryCategory__c').getDescribe());
        response.enquiryCategoryTrigger = Utilities.getDependentPickListValues(fieldsMap.get('EnquiryCategory__c').getDescribe(),fieldsMap.get('EnquiryTrigger__c').getDescribe());
        response.salesorigion = Utilities.getDependentPickListValues(fieldsMap.get('SalesOrigin__c').getDescribe(),fieldsMap.get('LeadOrigin__c').getDescribe());
        response.mortageValues = Utilities.getDependentPickListValues(fieldsMap.get('Financing__c').getDescribe(),fieldsMap.get('Mortgage__c').getDescribe());
        
        List<String> fieldAPIs = new List<String>{
            'LeadSource',
            'SalesOrigin__c',
            'LeadOrigin__c',
            'Financing__c',
            'PurposeOfUse__c',
            'PropertyReadiness__c',
            'NumberOfBedrooms__c',
            'ResidentStatus__c',
            'UnitType__c'
        };
                    
        for(String fieldAPI : fieldAPIs) {
            
            Schema.DescribeFieldResult fieldResult = fieldsMap.get(fieldAPI).getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            
            List<String> entries = new List<String>();
            
            for (Integer i = 0; i < picklistEntries.size(); i++){           
                Schema.PicklistEntry entry = picklistEntries[i];
                entries.add(entry.value);
            }  
            
            switch on fieldAPI {
                when 'LeadSource'{
                    response.leadSource = entries;
                    response.leadSource.sort();
                }
                when 'SalesOrigin__c'{
                    response.salesOrigin = entries;
                }
                when 'LeadOrigin__c' {
                    response.leadOrigin = entries;
                }
                when 'Financing__c'{
                    response.financing = entries;
                }
                when 'PurposeOfUse__c'{
                    response.purposeOfUse = entries;
                }
                when 'PropertyReadiness__c'{
                    response.propertyReadiness = entries;
                }
                when 'NumberOfBedrooms__c'{
                    response.numberOfBed = entries;
                }
                when 'ResidentStatus__c'{
                    response.uaeResidentStatus = entries; 
                }
                When 'UnitType__c'{
                    response.unitType = entries;
                }
            }
        }
        
        response.purposeOfUse          = getfilteredList(response.purposeOfUse, 'RTO');
        response.saleTypePropertyUsage = getfilteredMap(response.saleTypePropertyUsage, 'Commercial Land');
    }

    global static void getCasePicklistValues(ConfigurationsResponse response) {
        List<String> types = new List<String>{'Case'};
        Schema.DescribeSobjectResult[] result = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fieldsMap = result[0].fields.getMap();
        List<String> fieldAPIs = new List<String>{'Category__c'};
                    
        for(String fieldAPI : fieldAPIs) {
            
            Schema.DescribeFieldResult fieldResult = fieldsMap.get(fieldAPI).getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            
            List<String> entries = new List<String>();
            
            for (Integer i = 0; i < picklistEntries.size(); i++){           
                Schema.PicklistEntry entry = picklistEntries[i];
                entries.add(entry.value);
            }  
            
            switch on fieldAPI {
                when 'Category__c'{
                    response.categoryList = entries;
                }
            }
        }
    }
   
    public static List<String> getProjectPicklistValues() {
        List<String> projectNames = new List<String>();
        
        List<Project__c> projectList = [
            SELECT Id, Name, ProjectCode__c
            FROM Project__c
            WHERE BrokerSale__c = TRUE
            ORDER BY Name ASC
        ];
        
        for (Project__c proj : projectList) {
            projectNames.add(proj.Name);
        }
        
        return projectNames;
    }

    
    global static void getInvoiceBundlePicklistValues(ConfigurationsResponse response) {
        List<String> types = new List<String>{'InvoiceBundle__c'};
        Schema.DescribeSobjectResult[] result = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fieldsMap = result[0].fields.getMap();
        List<String> fieldAPIs = new List<String>{'Status__c'};
            
        for(String fieldAPI : fieldAPIs) {
            Schema.DescribeFieldResult fieldResult = fieldsMap.get(fieldAPI).getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            List<String> entries = new List<String>();
            for (Integer i = 0; i < picklistEntries.size(); i++){           
                Schema.PicklistEntry entry = picklistEntries[i];
                entries.add(entry.value);
            }  
            switch on fieldAPI {
                when 'Status__c' {
                    response.invoiceBundleStatus = entries;
                }
            }
        }
    }


    global with sharing class ConfigurationsResponse { 
        public List<Map<String, String>> projectDetails { get; set; }
        public List<Map<String, String>> AppointmentProjects { get; set; }
        public List<Map<String, String>> AldarExpertsAppointmentProjects { get; set; }
        public List<Map<String, String>> AldarExpertsAppointmentCancel { get; set; }
        public List<Map<String, String>> refferedSource { get; set; }
        public List<Map<String, String>> tradeLicenseType { get; set; }
        public List<Map<String, String>> residentCountryOrNationality { get; set; }
        public String AldarExpertsAppointmentButtonLabel{ get; set; }
        public String AldarExpertsAppointmentButtonEnabled{ get; set; }
        public String DigitalNonLaunch{ get; set;}
        public List<String> brokerRequestTypes {set; get;}
        
        public List<String> RefferedBy { get; set; }
        public List<String> brokertype { get; set; }
        public List<String> leadSource  {get; set; }
        public List<String> uaeResidentStatus  {get; set; }
        public List<String> salesOrigin  {get; set; }
        public List<String> leadOrigin  {get; set; }
        public List<String> salesType  {get; set; }
        public List<String> projectName  {get; set; }
        public List<String> unitType  {get; set; }
        public List<String> numberOfBed  {get; set; }
        public List<String> customerBudget  {get; set; }
        public List<String> purposeOfUse  {get; set; }
        public List<String> propertyReadiness  {get; set; }
        public List<String> financing  {get; set; }
        public List<String> categoryList  {get; set; }
        public List<String> invoiceBundleStatus  {get; set; }
        public List<String> projectPicklistValues { get; set; }

        public Map<String,List<String>> methodOfContactEnquiryCategory  {get; set; }
        public Map<String,List<String>> enquiryCategoryTrigger          {get; set; }
        public Map<String,List<String>> propertyUsagebuyRent            {get; set; }
        public Map<String,List<String>> propertyUsageCustomerBudget     {get; set; }
        public Map<String,List<String>> propertyUsageProject            {get; set; }
        public Map<String,List<String>> propertyUsageUnitType           {get; set; }
        public Map<String,List<String>> saleTypePropertyUsage           {get; set; }
        public Map<String,List<String>> salesorigion                    {get; set; }
        public Map<String,List<String>> mortageValues                   {get; set; }
        
        public ConfigurationsResponse() {
            this.uaeResidentStatus= new List<String>();
            this.salesOrigin= new List<String>();
            this.salesType= new List<String>();
            this.projectPicklistValues = new List<String>();

            this.projectName= new List<String>();
            this.unitType= new List<String>();
            this.numberOfBed= new List<String>();
            this.customerBudget= new List<String>();
            this.purposeOfUse= new List<String>();
            this.propertyReadiness= new List<String>();
            this.financing= new List<String>();
            this.categoryList = new List<String>();
            this.invoiceBundleStatus = new List<String>();
            this.methodOfContactEnquiryCategory  = new Map<String,List<String>>();
            this.enquiryCategoryTrigger  = new Map<String,List<String>>();
            this.propertyUsagebuyRent    = new Map<String,List<String>>();
            this.propertyUsageCustomerBudget   = new Map<String,List<String>>();
            this.propertyUsageProject    = new Map<String,List<String>>();
            this.propertyUsageUnitType   = new Map<String,List<String>>();
            this.saleTypePropertyUsage  = new Map<String,List<String>>();
            this.salesorigion  = new Map<String,List<String>>();
            this.mortageValues  = new Map<String,List<String>>();
            this.brokerRequestTypes = new List<String>();
            this.refferedSource = new List<Map<String,String>>();
            this.tradeLicenseType = new List<Map<String,String>>();
            this.residentCountryOrNationality = new List<Map<String, String>> ();
        }
    }
    
    public static List<String> getfilteredList(List<String> picklistValues, String picklistValueToFilter){
        Integer index = 0;
        while(index < picklistValues.size())
            if(picklistValues[index].contains(picklistValueToFilter))
            picklistValues.remove(index);
        else
            index++;
        
        return picklistValues; 
    }
    
    public static Map<String,List<String>> getfilteredMap(Map<String,List<String>> picklistMapValues, String picklistValueToFilter){
        Integer index = 0;
        
        for(String str : picklistMapValues.keySet()){
            picklistMapValues.remove(picklistValueToFilter);
        }
        return picklistMapValues;
    }

    public static List<Map<String,String>> getPicklistValuesToReturn (String objectAPIName, String picklistAPIName){
        List<Map<String,String>> pickListValuesToReturn = new List<Map<String,String>>();

        for(Schema.PicklistEntry a : Schema.getGlobalDescribe().get(objectAPIName).newSObject().getSObjectType().getDescribe().fields.getMap().get(picklistAPIName).getDescribe().getPickListValues()) {
            Map<String,String> tempMap = new Map<String,String>();
            tempMap.put('label', a.getLabel());
            tempMap.put('value', a.getValue());
            pickListValuesToReturn.add(tempMap);
        }
        return pickListValuesToReturn;
    }
}