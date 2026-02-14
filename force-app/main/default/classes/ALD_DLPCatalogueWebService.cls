/**********************************************************************************************************************
* Name              : ALD_FetchDLPCatalogueWebService                                                        
* Description       : Webservice class to fetch and return DLP Catalogue 
* Method            : doPost()
* Created By        : nborse@aldar.com - Nilesh   
* Test Class        : ALD_DLPCatalogueWebServiceTest
******************************************************************************************************************/
@RestResource(urlMapping = '/LiveAldar/DLPCatalogue')
global with sharing class ALD_DLPCatalogueWebService {
    
    // HTTP POST method to handle incoming requests
    @HttpPost
    global static void doPost(){ 
        RestContextHandler handler = new RestContextHandler(true);
        try {
            // Retrieve the incoming request
            RestRequest req = RestContext.request;
            
            // Fetch configurations and set the response data
            handler.response.data = getConfigurations();
            handler.response.success = true;
            handler.finalize();
        } catch(Exception ex){
            // Handle any exceptions that occur
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    
    // Method to fetch configurations from various sources
    global static ConfigurationsModel getConfigurations() {
        List<categoryClass> categoryList = new List<categoryClass>();
        Map<String,categoryClass> categoryMap = new Map<String, categoryClass>();
        Map<String,List<String>> CatSubCatMap = new Map<String, List<String>>();
        Set<String> otherCatSet = new Set<String>();
        // Retrieve the Record Type ID for 'DLP' on the Case object
        Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        
        // Fetch picklist values for 'CaseCategory__c' on Case object
        Map<String, String> mapCaseCat = ALD_DLPCatalogueHelper.fetchPickListVal('Case', recTypeId, 'CaseCategory__c');
        
        // Fetch dependent picklist values for various fields
        Map<String, List<String>> mapCatSubCat = ALD_DLPCatalogueHelper.getDependentPicklistValues(Case.SubCategory__c);
        Map<String, List<String>> mapSubCatProblemCode = ALD_DLPCatalogueHelper.getDependentPicklistValues(Case.ProblemCode__c);
        Map<String, List<String>> mapProblemCodeIncident = ALD_DLPCatalogueHelper.getDependentPicklistValues(Case.IncidentDescription__c);
        
        //Added by Kuhinoor
        List<CaseFieldDependency__mdt > csFieldDepList = [SELECT Id, CaseCategory__c, SubCategory__c, UI_Category__c,  Display_Text__c, Icon_url__c
                                                            FROM CaseFieldDependency__mdt 
                                                            WHERE Enable_for_Live_Aldar__c = true ];

        for(CaseFieldDependency__mdt csd : csFieldDepList){
            if(csd.UI_Category__c.equalsIgnoreCase('Primary')){
                categoryList.add( new categoryClass(csd.CaseCategory__c , csd.Display_Text__c , csd.Icon_url__c ));
                if(!categoryMap.containsKey( csd.CaseCategory__c ) ){
                    categoryMap.put(csd.SubCategory__c, new categoryClass(csd.SubCategory__c , csd.Display_Text__c , csd.Icon_url__c));
                }
                if(!CatSubCatMap.containsKey(csd.CaseCategory__c)){
                    CatSubCatMap.put( csd.CaseCategory__c, new list<String>{csd.SubCategory__c});
                }else{
                    CatSubCatMap.get( csd.CaseCategory__c ).add(csd.SubCategory__c);
                }
            }else{
                otherCatSet.add(csd.SubCategory__c);
                if(!categoryMap.containsKey( csd.UI_Category__c ) ){
                    categoryMap.put(csd.UI_Category__c, new categoryClass(csd.UI_Category__c , csd.Display_Text__c , csd.Icon_url__c));
                }
            }
        }

        // Create response object and populate it with filtered values
        ConfigurationsModel response = new ConfigurationsModel();
        Map<String, List<String>> subcatmap =  CatSubCatMap; // filterPickVal(mapCatSubCat, categoryMap.keySet());
        response.catSubcat = subcatmap;
        Set<String> subCatSet = new Set<String>();
        for( String obj : categoryMap.keySet()){
            if(subcatmap.containsKey(obj)){
                subCatSet.addAll( subcatmap.get(obj) );
            }
        }

        response.categories.addAll( categoryMap.values() );
        response.subcatProbcode = filterPickVal(mapSubCatProblemCode, categoryMap.keySet());
         if(otherCatSet != null && otherCatSet.size() > 0 ){
            response.other = filterPickVal(mapSubCatProblemCode, otherCatSet);
        }
        response.probcodeIncident = filterPickVal(mapProblemCodeIncident, getUniqueVals(mapSubCatProblemCode));
        return response;
    }
    
    // Method to extract unique values from a map of dependent picklist values
    global static set<String> getUniqueVals(Map<String, List<String>> mapPicklstDepVals){
        set<String> setVals = new set<String>();
        
        // Iterate over the map entries and add all values to the set
        for (List<String> valueList : mapPicklstDepVals.values()) {
            setVals.addAll(valueList);
        }
        
        return setVals;
    }
    
    // Method to filter picklist values based on a set of controlling field values
    global static Map<String, List<String>> filterPickVal(Map<String, List<String>> mapContrlDepFldMap, set<String> setVals){
        Map<String, List<String>> mapFldMap = new Map<String, List<String>>();
        
        // Iterate over the controlling field map and filter values
        for(String ctrlFld : mapContrlDepFldMap.keySet()){
            if(setVals.contains(ctrlFld)){
                mapFldMap.put(ctrlFld, mapContrlDepFldMap.get(ctrlFld));
            }
        }
        return mapFldMap;
    }
    
    // Inner class to model the configurations response
    global with sharing class ConfigurationsModel { 
        public Map<String, List<String>> catSubcat { get; set; }
        public List<categoryClass> categories;
        public Map<String, List<String>> subcatProbcode { get; set; }
        public Map<String, List<String>> probcodeIncident { get; set; }
        public Map<String, List<String>> other;
 
        // Constructor to initialize the maps
        public ConfigurationsModel(){
            this.catSubcat = new Map<String, List<String>>();
            this.subcatProbcode = new Map<String, List<String>>();
            this.probcodeIncident = new Map<String, List<String>>();
            this.categories = new List<categoryClass>();
        }
    }

    Public class categoryClass{
        public String displayName;
        public String name;
        public String icon;
        public categoryClass(String name, String displayName, String icon){
            this.displayName = displayName;
            this.name = name;
            this.icon = icon;
        }
    }
}