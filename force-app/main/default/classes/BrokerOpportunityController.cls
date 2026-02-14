public with sharing class BrokerOpportunityController {
    
    @AuraEnabled(cacheable=false)
    public static List<Opportunity> getOpportunities(String brokerAgentId){

        List<Opportunity> opportunitiesList = [SELECT Account.Salutation, Account.FirstName, Account.LastName, 
        Account.PersonEmail, Account.PersonMobilePhone, StageName, BrokerAgentName__c, Owner.Name, Project__c,
        OpportunityNumber__c, LeadNumber__c, SalesTypefromLead__c, DealType__c, LastModifiedDate, ResidentStatus__c
         FROM Opportunity WHERE BrokerAgencyAccount__r.Id =: brokerAgentId ORDER BY LastModifiedDate DESC ];

        for(Opportunity oppRec : opportunitiesList){

            if(oppRec.Account != null){
                String email = oppRec.Account.PersonEmail;
                String mobileNumber = oppRec.Account.PersonMobilePhone;
                oppRec.Account.PersonEmail = email != null ? email : '' ;
                oppRec.Account.PersonMobilePhone = mobileNumber != null ? mobileNumber : '';
            }
        }
 
        return opportunitiesList;
    }

    @AuraEnabled
    public static String maskString(String strText, integer start1, integer end1, String maskChar){
    
        if(strText == null || strText.equals(''))
            return '';
    
        if(start1 < 0)
            start1 = 0;
    
        if( end1 > strText.length() ) 
            end1 = strText.length();
    
            integer maskLength = end1 - start1;
    
        if(maskLength == 0)
            return strText;
    
        String sbMaskString='';
    
        for(integer i = 0; i < maskLength; i++){
            sbMaskString += maskChar;
        }   
    
        return strText.substring(0, start1) + sbMaskString + strText.substring(start1 + maskLength);
    }

    @AuraEnabled(cacheable=false)
    public static Opportunity getOpportunityById(String opportunityId){

        List<Opportunity> opportunityList = [SELECT Account.Salutation, Account.FirstName, Account.LastName, SaleType__c, DealType__c, BookingType__c, BrokerAgencyAccountName__c, 
        BrokerAgentName__c, SalesManager__r.Name, Owner.Name, StageName, Project__c, UnitNumber__c, UnitType__c, NumberOfBedrooms__c,ResidentStatus__c
        FROM Opportunity WHERE Id=: opportunityId];

        return opportunityList[0];
    }

    @AuraEnabled(cacheable=false)
    public static SalesOrder__c getSalesOrderByOpportunity(String opportunityId){

        List<SalesOrder__c> salesOrderList = [SELECT Discount__c, NetAmount__c, Status__c, UnitNumber__c, ProjectName__c, UnitType__c,
        UnitNumberOfRooms__c, UnitSaleableArea__c, UnitSellingPrice__c, Unit__r.TotalRooms__c FROM SalesOrder__c WHERE Opportunity__c =: opportunityId];

        if(salesOrderList.size() != 0 ){
            return salesOrderList[0];
        }
        return null;
    }
}