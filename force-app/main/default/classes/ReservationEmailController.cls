global with sharing class ReservationEmailController{

    global String opportunityId{get;set;}
    
    global  ReservationEmailController(){
    }
    
    global List<SalesOrder__c> reqList{
        get{        
            List<SalesOrder__c>untsToDisplay = new List<SalesOrder__c>();
            List<SalesOrder__c> unitList = [SELECT Unit__c,UnitBuilding__c,UnitProject__c,UnitProjectNumber__c,SellingPrice__c,NetAmount__c,UnitNumber__c,Remarks__c,UnitSellingPrice__c,UnitTotalArea__c,Unit__r.CurrencyIsoCode FROM SalesOrder__c WHERE Opportunity__c =:opportunityId];
            for(SalesOrder__c p:unitList){
                untsToDisplay.add(p);
            }
            
            return  untsToDisplay;
        }
        set;
    }
    
    
    global String NewLine {
        get { return '\r\n'; }
        set;
    }
}