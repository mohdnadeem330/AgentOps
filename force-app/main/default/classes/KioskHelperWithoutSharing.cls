public without sharing class  KioskHelperWithoutSharing {
    
    public static List<KioskPageCampaign__c> getCampaignByName(String campaignName){
        return [SELECT Id,Name FROM KioskPageCampaign__c WHERE Name=:campaignName];
    }
    
    public static List<KioskPageSection__c> getSectionDetails(String campaignId){
        return [SELECT Id,LeadQueue__c,Kiosk_Page_Campaign__c,Kiosk_Page_Section_Order__c,Name,
                (SELECT Id,Field_Order__c,Query_from_object__c,SkipSave__c,
                 Picklist_schema_name__c,Get_picklist_values_from_schema__c,
                 Controlling_Field_Value__c,Controlling_Field__c,Field_Type__c,
                 Required__c,Name,Picklist_Values__c,Field_API_Name__c 
                 FROM Kiosk_Page_Fields__r WHERE IsActive__c = TRUE) 
                FROM KioskPageSection__c 
                WHERE Kiosk_Page_Campaign__c =: campaignId 
                AND IsActive__c = TRUE 
                ORDER BY Kiosk_Page_Section_Order__c ASC];
    }
    
    public static List<KioskDefaultFields__c> getDependentFieldsByCampaign(String campaignId){
        return [SELECT Id,ControllingField__c,DependentFieldCheckbox__c,ControllingFieldValue__c,DependentField__c,isBoolean__c,KioskPageSection__r.Name,
                DependentFieldValue__c,KioskPageSection__c,KioskPageSection__r.Kiosk_Page_Campaign__r.Name 
                FROM KioskDefaultFields__c WHERE KioskPageCampaign__c =: campaignId AND isActive__c = TRUE];
    }
    
    public static List<KioskDefaultFields__c> getDependentFieldsBySection(String sectionId){
        return   [SELECT Id,ControllingField__c,DependentFieldCheckbox__c,ControllingFieldValue__c,DependentField__c,isBoolean__c,KioskPageSection__r.Name,
                  DependentFieldValue__c,KioskPageSection__c,KioskPageSection__r.Kiosk_Page_Campaign__r.Name 
                  FROM KioskDefaultFields__c WHERE KioskPageSection__c = :sectionId AND isActive__c = TRUE ];
    }
    public static List<Group> getQueueByName(String queueName){
        return  [select Id,DeveloperName  from Group where Type = 'Queue' AND DeveloperName = : queueName];
    }
    
    public static List<KioskDependentPicklistValue__c> getDependentPicklistValues(){
        return [SELECT Id,Controlling_Field_Value__c,
                DependentFieldValueTextArea__c,
                ControllingFieldText__c,DependentFieldText__c
                FROM KioskDependentPicklistValue__c
                WHERE isActive__c = TRUE];
    }
    
    public static List<AllocationGroup__c> getAllocationGroups(){
        return  [SELECT Id,Name,(SELECT Id,UserName__c,User__c FROM AllocationGroupUsersAllocationGroup__r WHERE User__r.isActive=true and ShowonKioskPage__c = true) FROM AllocationGroup__c WHERE ShowOnKiosk__c = TRUE];
    }
    
    public static List<KioskPageSection__c> getExistingCampaign(String cloneFrom){
        
        return [Select id,IsActive__c, Kiosk_Page_Campaign__c, Kiosk_Page_Section_Order__c, LeadQueue__c, Name,
                (Select id,Controlling_FIeld__c, Controlling_Field_Value__c, Field_API_Name__c,
                 Field_Order__c, Field_Type__c, Get_picklist_values_from_schema__c,
                 IsActive__c, Kiosk_Page_Section__c, Name, Object_API_Name__c, 
                 Picklist_schema_name__c, Picklist_Values__c, Query_from_object__c, 
                 Required__c, SkipSave__c from Kiosk_Page_Fields__r )
                from KioskPageSection__c WHERE Kiosk_Page_Campaign__c=:cloneFrom ];
    }
    
    public static String getLeadNumber(Id leadId){
        return [SELECT Id,LeadNumber__c FROM Lead WHERE Id=:leadId].LeadNumber__c;
    }
    public static List<Account> getBrokerAccounts(){
        return [SELECT Id,Name,BillingCity, (SELECT Id,Name,AccountId FROM Contacts WHERE AgentStatus__c='Active') FROM Account WHERE recordType.Name =: Constants.BROKER_AGENCY_RECORD_TYPE_NAME AND AgencyStatus__c= 'Active'];
    }
    public static List<Contact> getBrokerAgents(Id brokerId){
        return [SELECT Id,Name,AccountId FROM Contact WHERE AccountId =: brokerId ];
    }
}