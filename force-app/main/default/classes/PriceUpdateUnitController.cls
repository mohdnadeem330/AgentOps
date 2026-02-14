global with sharing class PriceUpdateUnitController{

    global String priceUpdReqtId{get;set;}
    global PriceUpdateRequest__c PriceUpdateRequest{
        get {
         PriceUpdateRequest = [Select Id, name from PriceUpdateRequest__c where id =: priceUpdReqtId];
          return PriceUpdateRequest; }
       set;
    }
    
    global  PriceUpdateUnitController(){
    }
    
    global List<PriceUpdateRequest__c> reqList{
        get{        
            List<PriceUpdateRequest__c>untsToDisplay = new List<PriceUpdateRequest__c>();
            List<PriceUpdateRequest__c> unitList = [SELECT Id,Name,TotalNewPrice__c, TotalCurrentPrice__c,(SELECT Id,Name,Project__r.Name,RequestNumber__c,Building__r.Name,Unit__r.Name,UnitStatus__c,CurrentPrice__c,NewPrice__c, PriceIncreaseAge__c FROM PriceUpdateUnits__r) FROM PriceUpdateRequest__c WHERE Id=:priceUpdReqtId];
            for(PriceUpdateRequest__c p:unitList){
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