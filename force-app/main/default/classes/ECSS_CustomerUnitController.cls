public with sharing class ECSS_CustomerUnitController {
    @AuraEnabled(cacheable=true)
    public static List<CustomerUnitWrapper> getCustomerUnits(string accountId) {
        List<CustomerUnitWrapper> customerUnitWrapperList = new List<CustomerUnitWrapper>();
        try{
            
            if(accountId!= null && accountId != ''){
                for(Customer_Unit__c cUnit:[SELECT Id, Name, Unit__r.Name,unit__c, Unit__r.ECSS_Unit_Type__c,
                                            Unit__r.ECSS_Project__c, Unit__r.ECSS_Project__r.Name,
                                            Unit__r.ECSS_Building_Section__c, Unit__r.ECSS_Building_Section__r.Name,active__c,
                                            Unit__r.ECSS_Zone__c, Unit__r.ECSS_Zone__r.Name,Unit__r.ECSS_Unit_Code__c,Customer_Type__c
                                            FROM Customer_Unit__c WHERE account__c=:accountId and active__c = true])
                {
                    CustomerUnitWrapper cuw = new CustomerUnitWrapper();
                    cuw.unitId = cUnit.unit__c;
                    cuw.unitName = cUnit.unit__r.Name;
                    cuw.customerUnitId = cUnit.Id;
                    cuw.projectName = cUnit.Unit__r.ECSS_Project__r.Name;
                    cuw.unitType = cUnit.Unit__r.ECSS_Unit_Type__c;
                    cuw.projectId = cUnit.Unit__r.ECSS_Project__c;
                    cuw.buildingName = cUnit.Unit__r.ECSS_Building_Section__r.Name;
                    cuW.buildingId = cUnit.Unit__r.ECSS_Building_Section__c;
                    cuw.zoneName = cUnit.Unit__r.ECSS_Zone__r.Name;
                    cuW.zoneId = cUnit.Unit__r.ECSS_Zone__c;
                    cuW.unitCode = cUnit.Unit__r.ECSS_Unit_Code__c;
                    cuW.customerType = cUnit.Customer_Type__c;
                    customerUnitWrapperList.add(cuw);
                }
            }
        }
        catch(exception e){  return customerUnitWrapperList;  }
        return customerUnitWrapperList;
        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<CustomerUnitWrapper> getRelatedUnits(string accountId) {
        List<CustomerUnitWrapper> customerUnitWrapperList = new List<CustomerUnitWrapper>();
        try{
            
            if(accountId!= null && accountId != ''){
                for(Customer_Unit__c cUnit:[SELECT Id, Name, Unit__r.Name,unit__c, Unit__r.ECSS_Unit_Type__c,
                                            Unit__r.ECSS_Project__c, Unit__r.ECSS_Project__r.Name,
                                            Unit__r.ECSS_Building_Section__c, Unit__r.ECSS_Building_Section__r.Name,
                                            Unit__r.ECSS_Zone__c, Unit__r.ECSS_Zone__r.Name,Unit__r.ECSS_Unit_Code__c,Unit__r.Description
                                            FROM Customer_Unit__c WHERE account__c=:accountId])
                {
                    CustomerUnitWrapper cuw = new CustomerUnitWrapper();
                    cuw.unitId = cUnit.unit__c;
                    cuw.unitName = cUnit.unit__r.Name;
                    cuw.customerUnitId = cUnit.Id;
                    cuw.projectName = cUnit.Unit__r.ECSS_Project__r.Name;
                    cuw.unitType = cUnit.Unit__r.ECSS_Unit_Type__c;
                    cuw.projectId = cUnit.Unit__r.ECSS_Project__c;
                    cuw.buildingName = cUnit.Unit__r.ECSS_Building_Section__r.Name;
                    cuW.buildingId = cUnit.Unit__r.ECSS_Building_Section__c;
                    cuw.zoneName = cUnit.Unit__r.ECSS_Zone__r.Name;
                    cuW.zoneId = cUnit.Unit__r.ECSS_Zone__c;
                    cuW.unitCode = cUnit.Unit__r.ECSS_Unit_Code__c;
                    cuW.description = cUnit.Unit__r.Description;
                    System.debug('Unit Code:'+ cUnit.Unit__r.ECSS_Unit_Code__c);
                    customerUnitWrapperList.add(cuw);
                }
            }
            else{
                for(Asset cUnit:[SELECT Id, Name, ECSS_Unit_Type__c,
                                            ECSS_Project__c,ECSS_Project__r.Name,Description,
                                            ECSS_Building_Section__c, ECSS_Building_Section__r.Name,ECSS_Unit_Code__c,
                                            ECSS_Zone__c,ECSS_Zone__r.Name
                                            FROM Asset where recordtype.name like '%Functional%' limit 5000])
                {
                    CustomerUnitWrapper cuw = new CustomerUnitWrapper();
                    cuw.unitId = cUnit.Id;
                    cuw.unitName = cUnit.Name;
                    cuw.projectName = cUnit.ECSS_Project__r.Name;
                    cuw.unitType = cUnit.ECSS_Unit_Type__c;
                    cuw.projectId = cUnit.ECSS_Project__c;
                    cuw.buildingName = cUnit.ECSS_Building_Section__r.Name;
                    cuW.buildingId = cUnit.ECSS_Building_Section__c;
                    cuw.zoneName = cUnit.ECSS_Zone__r.Name;
                    cuW.zoneId = cUnit.ECSS_Zone__c;
                    cuW.unitCode = cUnit.ECSS_Unit_Code__c;
                    cuW.description = cUnit.Description;
                    System.debug('Desc:'+cuW.description); 
                    customerUnitWrapperList.add(cuw);
                }
            }
        }
        catch(exception e){  return customerUnitWrapperList;  }
        return customerUnitWrapperList;
        
    }
    public class CustomerUnitWrapper {
        @AuraEnabled 
        public string unitId;
        
        @AuraEnabled 
        public string unitName;
        
        @AuraEnabled 
        public string unitType;
        
        @AuraEnabled 
        public string projectName;
        
        @AuraEnabled 
        public string projectId;
        
        @AuraEnabled 
        public string buildingName;
        
        @AuraEnabled 
        public string buildingId;
        
        @AuraEnabled 
        public string zoneName;
        
        @AuraEnabled 
        public string zoneId;
        
        @AuraEnabled 
        public string customerUnitId;
        
        @AuraEnabled 
        public string unitCode;
        
        @AuraEnabled 
        public string description;
   @AuraEnabled 
        public string customerType;


        
    }
    
    
}