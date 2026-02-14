public with sharing class ShipmentRequestTriggerHandler extends TriggerHandler{
    
    //*** Before Insert Action***//
    public override void beforeInsertMethod(list<SObject> newList, Map<Id, SObject> newMap){
        Map<String, String> countryCodeMap = new Map<String, String>();
        List<Schema.PicklistEntry> picklistValues = Account.BillingCountryCode.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry picklist: picklistValues) {
            if (picklist.isActive()) {
                countryCodeMap.put(picklist.getLabel().toUpperCase(), picklist.getValue());
            }
        }

        Set<Id> ids = new Set<Id>();
        for (ShipmentRequest__c sr: (List<ShipmentRequest__c>) newList) {
            ids.add(sr.SalesOrder__c);
        }

        Map<Id, SalesOrder__c> soMap = new Map<Id, SalesOrder__c>([SELECT Id, Name, Account__c, CustomerAddress__c, Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingPostalCode, Account__r.ShippingCountry FROM SalesOrder__c WHERE Id IN :ids]);
        for (ShipmentRequest__c sr: (List<ShipmentRequest__c>) newList) {
            sr.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            
            SalesOrder__c so = soMap.get(sr.SalesOrder__c);
            Map<String, Object> cAddress = new Map<String, Object>();
            if (so.CustomerAddress__c != null) {
                cAddress = (Map<String, Object>)JSON.deserializeUntyped(so.CustomerAddress__c);
            }
            sr.Account__c = sr.Account__c != null ? sr.Account__c : null;
            if (sr.IsAutoCreated__c) {
                sr.Street__c = so.Account__r.ShippingStreet;
                sr.City__c = so.Account__r.ShippingCity;
                sr.State__c = so.Account__r.ShippingState;
                sr.PostalCode__c = so.Account__r.ShippingPostalCode;
                sr.Country__c = so.Account__r.ShippingCountry;
            } else {
                sr.Street__c = sr.Street__c != null ? sr.Street__c : !cAddress.isEmpty() && cAddress.containsKey('Street') ? String.valueOf(cAddress.get('Street')) : '';
                sr.City__c = sr.City__c != null ? sr.City__c : !cAddress.isEmpty() && cAddress.containsKey('City') ? String.valueOf(cAddress.get('City')) : '';
                sr.State__c = sr.State__c != null ? sr.State__c : !cAddress.isEmpty() && cAddress.containsKey('State') ? String.valueOf(cAddress.get('State')) : '';
                sr.PostalCode__c = sr.PostalCode__c != null ? sr.PostalCode__c : !cAddress.isEmpty() && cAddress.containsKey('PostalCode') ? String.valueOf(cAddress.get('PostalCode')) : '';
                sr.Country__c = sr.Country__c != null ? sr.Country__c : !cAddress.isEmpty() && cAddress.containsKey('Country') ? String.valueOf(cAddress.get('Country')) : '';
            }

            if (String.isNotBlank(sr.Country__c)) {
                sr.CountryCode__c = countryCodeMap.containsKey(sr.Country__c.toUpperCase()) ? countryCodeMap.get(sr.Country__c.toUpperCase()) : '';
            }
        }
    }

    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        List<Id> srIds = new List<Id>();
        for (ShipmentRequest__c sr: (list<ShipmentRequest__c>) newList) {
            if (sr.SyncStatus__c == Constants.STATUS_IN_PROGRESS && sr.AWBNumber__c == null) {
                srIds.add(sr.Id);
            }
        }
        User usr = Utilities.getLoggedInUserDetail();
        if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !srIds.isEmpty()) {
            ShipmentRequestCalloutHelper.PrepareDataForCallout(srIds, true);
        }
    }

    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        List<Id> srIds = new List<Id>();
        for (ShipmentRequest__c sr: (list<ShipmentRequest__c>) newList) {
            if (sr.SyncStatus__c == Constants.STATUS_IN_PROGRESS && sr.AWBNumber__c == null) {
                srIds.add(sr.Id);
            }
        }
        User usr = Utilities.getLoggedInUserDetail();
        if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !srIds.isEmpty()) {
            ShipmentRequestCalloutHelper.PrepareDataForCallout(srIds, true);
        }
    }
}