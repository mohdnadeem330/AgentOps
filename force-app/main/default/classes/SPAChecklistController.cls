/**********************************************************************************************************************
* Name               : SPAChecklistService                                                        
* Description        : This class is used to retrive all the SPAChecklist__c records
* Usage              :                                                       
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           shivani@pwc.com     10 Feb 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class SPAChecklistController {

    /**
    * getmdtCategory 
    *
    * return all Category values from SPAChecklistItem__mdt metaData
    *
    * @param none
    * @return List<String> 
    * 
    */
    @AuraEnabled
    public static   List<String>   getmdtCategory(){
    List<String> showCategory =new   List<String>();
        List<SPAChecklistItem__mdt> mdtCategory=Utilities.getChecklist();
        for(SPAChecklistItem__mdt s:mdtCategory){
            if(!showCategory.contains(s.Category__c)){
                showCategory.add(s.Category__c);
            }
        }
        return showCategory;
    }

    /**
    * DataToDisplay 
    *
    * retrive SPAChecklist__c data under SalesOrder
    *
    * @param salesOrderId relatedSalesOrder ID
    * @return List<SPAChecklist__c> SPA checkList data
    * 
    */
    @AuraEnabled
    public static List<SPAChecklist__c> DataToDisplay(Id salesOrderId) {  
        List<SPAChecklist__c> ItemNameToDisplay= new List<SPAChecklist__c>();
        try{
            String accountIds;
            List<String> existSuppDocItemName= new List<String>();
            List<SPAChecklist__c> ExistItemNameData= new List<SPAChecklist__c>();
            List<String> ItemNames= new List<String>();
            List<SPAChecklist__c> existSuppDocItemNamesInObj = new  List<SPAChecklist__c>();
            Map<String,SPAChecklist__c> mapOfItemNames = new Map<String,SPAChecklist__c>();
            List<SalesOrder__c> getSalesOrderDetails=SalesOrderService.getSalesOrderRec(salesOrderId);
        
            for(SalesOrder__c s:getSalesOrderDetails){
                accountIds= s.Account__c;
            }
        
            String rectypename;
            rectypename=AccountService.getAccountRecordTypeName(accountIds);        
            List<SPAChecklistItem__mdt> getmdtRecRec =  Utilities.getAllmdtRec(rectypename);
            
            if(getmdtRecRec.size()>0){
                for(SPAChecklistItem__mdt spa:getmdtRecRec){
                    mapOfItemNames.put(spa.ItemName__c,new SPAChecklist__c(ItemName__c=spa.ItemName__c,ChecklistCategory__c=spa.Category__c)); 
                }
            }  
            existSuppDocItemNamesInObj = SPAChecklistService.SPAAllChecklistRecords(salesOrderId);
            
            if(existSuppDocItemNamesInObj.size()>0){
                for(SPAChecklist__c s:existSuppDocItemNamesInObj){
                    if(mapOfItemNames.containsKey(s.ItemName__c)){
                    
                        mapOfItemNames.put(s.ItemName__c,s); 
                    }
                }
            }
            Map<String,SPAChecklist__c> allValues = new   Map<String,SPAChecklist__c>();
            ItemNameToDisplay=  mapOfItemNames.Values();
        } catch(Exception ex){  
            String message=ex.getMessage();
        }  
        return ItemNameToDisplay;
    }   

    /**
    * saveSPA 
    *
    * Save SPAChecklist__c data under Sales Order
    *
    * @param spaRecord relatedSalesOrder ID
    * @param salId relatedSalesOrder ID
    * @return List<SPAChecklist__c> SPA checkList data
    * 
    */
    @AuraEnabled  
    public static list<SPAChecklist__c> saveSPA(List<Map<String,String>>  spaRecord, String salId ) {  
        list<SPAChecklist__c> newlist = new  list<SPAChecklist__c>();
        map<id,SPAChecklist__c> existingRecords = new map<id,SPAChecklist__c>();
        try{  
            for(Map<String,String> s:spaRecord){
                SPAChecklist__c sl = new SPAChecklist__c();
                sl.ValidatedBySalesAdmin__c=s.get('ValidatedbySalesAdmin__c');
                sl.ValidatedByCMTeam__c=s.get('ValidatedbyCMTeam__c');
                sl.Notes__c=s.get('Notes__c');
                sl.ChecklistCategory__c=s.get('ChecklistCategory__c');
                sl.ItemName__c=s.get('ItemName__c');
                
                if(!s.containsKey('SalesOrder__c')){
                    sl.SalesOrder__c=salId;
                }
                if(s.containsKey('Id')&&s.get('Id') != ''){
                    sl.Id=s.get('Id');
                    existingRecords.put(sl.Id,null);
                }
                newlist.add(sl);
            }
            //Populatethe validation Date
            existingRecords = new map<id,SPAChecklist__c>([select id,ValidatedBySalesAdmin__c,ValidatedByCMTeam__c from SPAChecklist__c where id in :existingRecords.keySet()]);
            for(SPAChecklist__c tempRec: newlist){
                if(tempRec.id!=null && existingRecords.containsKey(tempRec.id)){
                    
                }
                if(tempRec.ValidatedBySalesAdmin__c!=null && tempRec.ValidatedBySalesAdmin__c.equalsIgnoreCase(Constants.YES) ){
                    if(tempRec.id==null || (existingRecords.containsKey(tempRec.id) && existingRecords.get(tempRec.id).ValidatedBySalesAdmin__c != Constants.YES ) ){
                        tempRec.SalesAdminValidatedDate__c=system.today();
                    }
                }
                if(tempRec.ValidatedByCMTeam__c!=null && tempRec.ValidatedByCMTeam__c.equalsIgnoreCase(Constants.YES) ){
                    if(tempRec.id==null || (existingRecords.containsKey(tempRec.id)   && existingRecords.get(tempRec.id).ValidatedByCMTeam__c != Constants.YES ) ){
                        tempRec.CMValidatedDate__c=system.today();
                    }
                }
            }
            upsert newlist ;  
            
            
        } catch(Exception ex){  
            String message=ex.getMessage();
        
        }  
        return newlist;  
    }    
}