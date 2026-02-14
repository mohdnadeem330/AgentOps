/*
* Class Name:  AFX_CtrlUnitSearch
* Created By : R3-DLP implementation-Smaartt
* Description: Controller class used for Unit Search LWC Component
*/
public class AFX_CtrlUnitSearch {
    @AuraEnabled( cacheable=true)
    public static BuildingUnitWrap searchBuidingUnit(String projectId){
        BuildingUnitWrap wrap = new BuildingUnitWrap();
        wrap.porjects = [SELECT Name, Id FROM Project__c];                       
        return wrap;   
    }
    @AuraEnabled( cacheable=true)
    public static List<BuildingSection__c> searchBuidingUnits(String projectId){        
        return [SELECT Id,Name FROM BuildingSection__c WHERE Project__c =: projectId];                  
    }
    @AuraEnabled( cacheable=true)
    public static List<Unit__c> searchUnits(String buildingId){        
        return [SELECT Id,Name,PropertyId__c,BuildingSectionName__c,BuildingSectionName__r.Name,
                (SELECT Id, Name, CustomerDLPStatus__c,Status__c,Account__c,Account__r.Name,CustomerDLPStartDate__c,DLPDate__c From OpportunityUnitsUnit__r where Status__c = 'Approve Pending' or Status__c= 'Sold'), 
                CommunityName__c,Project__r.Name,Project__c,PropertyUsage__c,UnitType__c FROM Unit__c WHERE BuildingSectionName__c =: buildingId];                 
    }      
    public class BuildingUnitWrap{
        @AuraEnabled
        Public List<Project__c> porjects;         
        @AuraEnabled
        Public List<BuildingSection__c> lstBuildings; 
        @AuraEnabled
        Public List<Unit__c> lstUnits;        
        public BuildingUnitWrap(){
            lstBuildings = new  List<BuildingSection__c>();
            lstUnits = new List<Unit__c>();
        }
    }
}