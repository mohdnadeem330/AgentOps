public with sharing class BuildingSectionService {
    public BuildingSectionService() {
    }

    @AuraEnabled(cacheable=false)
    public static List<BuildingSection__c> prepareLocationNames(String projectName){ 
    list<BuildingSection__c> lstLocationName = new list<BuildingSection__c>();
    for(BuildingSection__c objP : [Select Id,Name from BuildingSection__c where Project__r.Name	 =: projectName]){
      lstLocationName.add(objP);
    }
    return lstLocationName;
    }

    @AuraEnabled(cacheable=true)
    public static List<BuildingSection__c> prepareBuildingsNames(String projectId){ 
    list<BuildingSection__c> lstLocationName = new list<BuildingSection__c>();
    for(BuildingSection__c objP : [Select Id,Name from BuildingSection__c where Project__c	 =: projectId WITH SECURITY_ENFORCED order by Name]){
      lstLocationName.add(objP);
    }
    return lstLocationName;
    }

  /*  @AuraEnabled(cacheable=true)
    public static List<BuildingSection__c> prepareBuildingsNames2(String projectId){ 
    list<BuildingSection__c> lstLocationName = new list<BuildingSection__c>();
    for(BuildingSection__c objP : [Select Id,Name from BuildingSection__c where Project__c	 =: projectId WITH SECURITY_ENFORCED]){
      lstLocationName.add(objP);
    }
    return lstLocationName;
    }*/

    @AuraEnabled(cacheable=false)
    public static BuildingSection__c checkBuildingEligiblity(String buildingId){ 
    BuildingSection__c objbuilding = [select Id,EligibileforMultiPurposeRoom__c,EligibleforUnitFinishes__c from BuildingSection__c where Id =: buildingId limit 1];

    return objbuilding;
    }
}