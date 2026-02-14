public with sharing class CreateShipmentRequestController {
    @AuraEnabled
    public static List<Object> getRelatedAccountNames(Id rId){
        try {
            List<Object> returnList = new List<Object>();
            
            SalesOrder__c so = SalesOrderService.getAccountWithJointOwners(rId);
            
            Map<String, String> rMap = new Map<String, String>();
            rMap.put('Id', so.Account__c);
            rMap.put('Name', so.Account__r.Name);
            rMap.put('RelationshipType', 'Self');
            rMap.put('BillingStreet', so.Account__r.BillingStreet);
            rMap.put('BillingCity', so.Account__r.BillingCity);
            rMap.put('BillingState', so.Account__r.BillingState);
            rMap.put('BillingPostalCode', so.Account__r.BillingPostalCode);
            rMap.put('BillingCountry', so.Account__r.BillingCountry);
            rMap.put('ShippingStreet', so.Account__r.ShippingStreet);
            rMap.put('ShippingCity', so.Account__r.ShippingCity);
            rMap.put('ShippingState', so.Account__r.ShippingState);
            rMap.put('ShippingPostalCode', so.Account__r.ShippingPostalCode);
            rMap.put('ShippingCountry', so.Account__r.ShippingCountry);
            returnList.add(rMap);
            for (JointOwner__c jo : so.Joint_OwnersSalesOrder__r) {
                rMap = new Map<String, String>();
                rMap.put('Id', jo.Account__c);
                rMap.put('Name', jo.Account__r.Name);
                rMap.put('RelationshipType', jo.RelationshipType__c);
                rMap.put('BillingStreet', jo.Account__r.BillingStreet);
                rMap.put('BillingCity', jo.Account__r.BillingCity);
                rMap.put('BillingState', jo.Account__r.BillingState);
                rMap.put('BillingPostalCode', jo.Account__r.BillingPostalCode);
                rMap.put('BillingCountry', jo.Account__r.BillingCountry);
                rMap.put('ShippingStreet', jo.Account__r.ShippingStreet);
                rMap.put('ShippingCity', jo.Account__r.ShippingCity);
                rMap.put('ShippingState', jo.Account__r.ShippingState);
                rMap.put('ShippingPostalCode', jo.Account__r.ShippingPostalCode);
                rMap.put('ShippingCountry', jo.Account__r.ShippingCountry);
                returnList.add(rMap);
            }  
            System.debug('returnList>>>' + returnList);
            return returnList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String saveShipmentRequest(String soId, String accId, Map<String, String> address) {
        try {
            ShipmentRequest__c sr = new ShipmentRequest__c();
            sr.SalesOrder__c = soId;
            sr.Account__c = accId;
            sr.Street__c = address.get('Street');
            sr.City__c = address.get('City');
            sr.State__c = address.get('State');
            sr.PostalCode__c = address.get('PostalCode');
            sr.Country__c = address.get('Country');
            insert sr;
            
            return sr.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}