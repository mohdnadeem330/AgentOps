/**********************************************************************************************************************
* Name               : OpportunityOfferLineTriggerHandler                                                        
* Description        : This class is to write all the trigger automations for the OpportunityOfferLine__c object
* Usage              : DLPZoneTriggerHandler
* Created By         : PWC Digital Middle East                                                     
******************************************************************************************************************/

public with sharing class OpportunityOfferLineTriggerHandler extends TriggerHandler{


    //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        //Populate default maintainance years (Villa 4, Apartment 2)
        Map<ID,String> salesOrderToUnitType = new map<id,String>();
        for(OpportunityOfferLine__c tempRecord : (List<OpportunityOfferLine__c>)newList){    
            if(tempRecord.BudgetTaskName__c != null){
                if(tempRecord.MaintenanceVisits__c ==null && tempRecord.SalesOrder__c!=null
                   && (tempRecord.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_HOME_MAINTENANCE) || tempRecord.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_AMC)) ){
                       salesOrderToUnitType.put(tempRecord.SalesOrder__c,'');
                   } 
            }
        }
        if(!salesOrderToUnitType.isEmpty()){
            for(SalesOrder__c tempSO : [select id,UnitType__c from SalesOrder__c where id in :salesOrderToUnitType.keySet()]){
                salesOrderToUnitType.put(tempSO.id,tempSO.UnitType__c);
            }
            for(OpportunityOfferLine__c tempRecord : (List<OpportunityOfferLine__c>)newList){ 
                if(tempRecord.BudgetTaskName__c != null){
                    if(tempRecord.MaintenanceVisits__c ==null && tempRecord.SalesOrder__c!=null && (tempRecord.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_HOME_MAINTENANCE) || tempRecord.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_AMC)) && salesOrderToUnitType.containsKey(tempRecord.SalesOrder__c) &&
                      (salesOrderToUnitType.get(tempRecord.SalesOrder__c)== 'Villa' || salesOrderToUnitType.get(tempRecord.SalesOrder__c) == 'Apartment' || salesOrderToUnitType.get(tempRecord.SalesOrder__c) == 'TownHouse' || salesOrderToUnitType.get(tempRecord.SalesOrder__c) == 'Penthouse' || salesOrderToUnitType.get(tempRecord.SalesOrder__c) == 'Loft') ){
                        tempRecord.MaintenanceVisits__c = salesOrderToUnitType.get(tempRecord.SalesOrder__c) == 'Apartment' ? '2':'4' ;
                    }
                }
            }
        }
        
    }


    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        list<OpportunityOfferLine__c> recordsToProcess = new list<OpportunityOfferLine__c>();
        list<OpportunityOfferLine__c> pmaRecords = new list<OpportunityOfferLine__c>();
        for(OpportunityOfferLine__c tempRecord : (List<OpportunityOfferLine__c>)newList){     
            if(tempRecord.BudgetTaskName__c!=null && (tempRecord.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_HOME_MAINTENANCE) || tempRecord.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_AMC)) && 
              tempRecord.OfferValue__c !=null && tempRecord.MaintenanceStartDate__c !=null && tempRecord.MaintenanceVisits__c!=null){
                recordsToProcess.add(tempRecord);
                pmaRecords.add(tempRecord);
            }     
        }
        if(!recordsToProcess.isEmpty()){
            createVisitDetails(recordsToProcess);
        }
        if(!pmaRecords.isEmpty()){
            updatePMADates(pmaRecords);
        }
    }
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        list<OpportunityOfferLine__c> recordsToProcess = new list<OpportunityOfferLine__c>();
        for(OpportunityOfferLine__c tempRecord : (List<OpportunityOfferLine__c>)newList){     
            OpportunityOfferLine__c oldRecord = (OpportunityOfferLine__c)oldMap.get(tempRecord.Id);
            if(tempRecord.BudgetTaskName__c!=null && (tempRecord.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_HOME_MAINTENANCE) || tempRecord.BudgetTaskName__c.equalsIgnoreCase(Constants.BUDGET_LINE_AMC)) && 
              tempRecord.OfferValue__c !=null && tempRecord.MaintenanceStartDate__c !=null && tempRecord.MaintenanceVisits__c!=null &&
              (oldRecord.MaintenanceStartDate__c != tempRecord.MaintenanceStartDate__c || oldRecord.MaintenanceVisits__c != tempRecord.MaintenanceVisits__c)){
                recordsToProcess.add(tempRecord);
            }       
        }
        if(!recordsToProcess.isEmpty()){
            createVisitDetails(recordsToProcess);
        }
    }
    public static void updatePMADates(list<OpportunityOfferLine__c> offerLines){
        list<SalesOrder__c> soToUpdate = new list<SalesOrder__c>();
        for(OpportunityOfferLine__c ofl : offerLines){
            if(ofl.SalesOrder__c!=null && ofl.MaintenanceStartDate__c !=null && ofl.MaintenanceVisits__c!=null){
                soToUpdate.add(new SalesOrder__c (id = ofl.SalesOrder__c , PMASTartDate__c = ofl.MaintenanceStartDate__c , PMAEndDate__c = ofl.MaintenanceStartDate__c.addYears(1).addDays(-1)));
            }
            
        }
        if(!soToUpdate.isEmpty()){
            update soToUpdate;
        }
    }
    public static void createVisitDetails(list<OpportunityOfferLine__c> offerLines){
        map<id,OpportunityOfferLine__c> offerLineMap = new map<id,OpportunityOfferLine__c>(offerLines);
        map<id,list<VisitDetail__c >> offerToVisitDetails = new map<id,list<VisitDetail__c >>();
        //get Existing Visits
        for(VisitDetail__c tempVisit : [select id,OfferLine__c from VisitDetail__c where OfferLine__c in : offerLineMap.keySet() order by PlannedDate__c]){
            if(!offerToVisitDetails.containsKey(tempVisit.OfferLine__c)){
                offerToVisitDetails.put(tempVisit.OfferLine__c, new list<VisitDetail__c >());
            }
            offerToVisitDetails.get(tempVisit.OfferLine__c).add(tempVisit);
            
            
        }
        
        //logic to create update delete the visit records
        list<VisitDetail__c> visitRecordsToUpsert=new list<VisitDetail__c>();
        list<VisitDetail__c> visitRecordsToDelete=new list<VisitDetail__c>();
        for(OpportunityOfferLine__c tempOfferRecord : offerLines){
            Integer monthAdder = 0;
            if(Integer.ValueOf(tempOfferRecord.MaintenanceVisits__c) == 12){monthAdder=1;}
            else if(Integer.ValueOf(tempOfferRecord.MaintenanceVisits__c) == 4){monthAdder=3;}
            else if(Integer.ValueOf(tempOfferRecord.MaintenanceVisits__c) == 2){monthAdder=6;}
            else if(Integer.ValueOf(tempOfferRecord.MaintenanceVisits__c) == 1){monthAdder=12;}
            
            Date tempInsStartDate= tempOfferRecord.MaintenanceStartDate__c;
            Integer totalVisits = Integer.ValueOf(tempOfferRecord.OfferValue__c) * Integer.ValueOf(tempOfferRecord.MaintenanceVisits__c);
            for (Integer i = 0 ; i < totalVisits ; i++) {
                tempInsStartDate =  i==0 ? tempInsStartDate.addMonths(2) : tempInsStartDate.addMonths(monthAdder) ;
                VisitDetail__c newVisitRecord = new VisitDetail__c(OfferLine__c= tempOfferRecord.Id, 
                                                            SalesOrder__c= tempOfferRecord.SalesOrder__c,
                                                            PlannedDate__c= tempInsStartDate.addDays(-1),
                                                            Vendor__c = tempOfferRecord.Vendor__c);
                                                            
                if(offerToVisitDetails.containsKey(tempOfferRecord.Id) && !offerToVisitDetails.get(tempOfferRecord.Id).isEmpty()){
                    newVisitRecord.id = offerToVisitDetails.get(tempOfferRecord.Id)[0].id;
                    offerToVisitDetails.get(tempOfferRecord.Id).remove(0);
                }
                visitRecordsToUpsert.add(newVisitRecord);
            }
        }
        
        if(!visitRecordsToUpsert.isEmpty()){
            upsert visitRecordsToUpsert;
        }
        
        //Delete extra records 
        for(Id tempKey : offerToVisitDetails.KeySet()){
            if(!offerToVisitDetails.get(tempKey).isEmpty()){
                visitRecordsToDelete.addAll(offerToVisitDetails.get(tempKey));
            }
        }
        if(!visitRecordsToDelete.isEmpty()){
            delete visitRecordsToDelete;
        }
    }
}