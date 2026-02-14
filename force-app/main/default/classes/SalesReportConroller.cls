public with sharing class SalesReportConroller {

    @AuraEnabled(cacheable=true)
    public static list<SalesOrder__c> getSalesReport(String agentName, String accountName, Date startDate, Date endDate){
        set<string> statusValuesForReport= new set<String>{Constants.OPPO_UNIT_STATUS_PENDING,Constants.SALES_STATUS,Constants.SO_STATUS_SOLD};
        
        string dateFilter='';
        if(startDate!=null){
            
            dateFilter= ' and (  BookingDate__c >= :startDate )';
            //dateFilter= ' and createdDate >= :startDate';
        }
        if(endDate!=null){
            endDate = endDate.addDays(1);
            dateFilter+= ' and ( BookingDate__c <= :endDate )';
            //dateFilter+= ' and createdDate <= :endDate';
        }
        string nameFilter='';
        if(accountName!=null && accountName!=''){
            nameFilter+=' and AccountName__c like \'%'+accountName+'%\'';
        }
        string finalSOQL = 'select Status__c,AccountName__c,AccountNumber__c,AgentName__c,AgentType__c,ProjectName__c,UnitNumber__c,UnitAreaUOM__c,UnitTotalArea__c,CreatedDate,UnitSellingPrice__c,NetAmount__c from SalesOrder__c where Status__c in :statusValuesForReport '+nameFilter+dateFilter ;
        return database.Query(finalSOQL);
        /*if (accountName != null) {
            return [ AccountName__c LIKE :'%' + accountName + '%' /*AND AgentName__c =: agentName* /  ORDER BY CreatedDate DESC];
        }else{
            return [select Status__c,AccountName__c,AccountNumber__c,AgentName__c,AgentType__c,ProjectName__c,UnitAreaUOM__c,UnitTotalArea__c,CreatedDate,UnitSellingPrice__c from SalesOrder__c where Status__c in :statusValuesForReport /* and AgentName__c =: agentName* / ORDER BY CreatedDate DESC];
        }*/
    }
}