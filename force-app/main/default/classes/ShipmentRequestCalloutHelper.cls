public class ShipmentRequestCalloutHelper {
    public static void PrepareDataForCallout(List<Id> srIds, Boolean isFutureCallout) {
        List<ShipmentRequest__c> srList = ShipmentRequestService.queryAllFieldsWithExtraFields(srIds);

        String processName = Constants.ARAMEX_CREATE_SHIPMENTS_INTEGRATION;
        ShipmentSetting__mdt sSetting = [SELECT Id, Label, DeveloperName, AccountNumber__c, CompanyName__c, AddressLine1__c, AddressLine2__c, City__c, StateCode__c, PostCode__c, CountryCode__c, POBox__c, PersonName__c, Country__c, FaxNumber__c, EmailAddress__c, PhoneNumber__c, MobilePhone__c, Username__c, Password__c, Version__c, AccountEntity__c, AccountPin__c, Source__c FROM ShipmentSetting__mdt WHERE DeveloperName =: processName];

        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> sList = new List<Object>();
        
        for (ShipmentRequest__c sr : srList) {
            Map<String, Object> sMap = new Map<String, Object>();

            sMap.put('Reference1', sr.Id);
            sMap.put('Reference2', null);
            sMap.put('Reference3', null);
                Map<String, Object> shipperMap = new Map<String, Object>();
                shipperMap.put('Reference1', null);
                shipperMap.put('Reference2', null);
                shipperMap.put('AccountNumber', sSetting.AccountNumber__c);
                    Map<String, Object> psMap = new Map<String, Object>();
                    psMap.put('Line1', sSetting.AddressLine1__c != null ? sSetting.AddressLine2__c : '');
                    psMap.put('Line2', sSetting.AddressLine2__c != null ? sSetting.AddressLine2__c : '');
                    psMap.put('Line3', '');
                    psMap.put('City', sSetting.City__c);
                    psMap.put('StateOrProvinceCode', sSetting.StateCode__c);
                    psMap.put('PostCode', sSetting.PostCode__c);
                    psMap.put('CountryCode', sSetting.CountryCode__c);
                    psMap.put('Longitude', 0);
                    psMap.put('Latitude', 0);
                    psMap.put('BuildingNumber', null);
                    psMap.put('BuildingName', null);
                    psMap.put('Floor', null);
                    psMap.put('Apartment', null);
                    psMap.put('POBox', sSetting.POBox__c);
                    psMap.put('Description', null);
                shipperMap.put('PartyAddress', psMap);

                    Map<String, Object> csMap = new Map<String, Object>();
                    csMap.put('Department', null);
                    csMap.put('PersonName', sSetting.PersonName__c);
                    csMap.put('Title', null);
                    csMap.put('CompanyName', sSetting.CompanyName__c);
                    csMap.put('PhoneNumber1', sSetting.MobilePhone__c != null ? sSetting.MobilePhone__c : sSetting.PhoneNumber__c);
                    csMap.put('PhoneNumber1Ext', null);
                    csMap.put('PhoneNumber2', sSetting.PhoneNumber__c);
                    csMap.put('PhoneNumber2Ext', null);
                    csMap.put('FaxNumber', sSetting.FaxNumber__c);
                    csMap.put('CellPhone', sSetting.MobilePhone__c != null ? sSetting.MobilePhone__c : sSetting.PhoneNumber__c);
                    csMap.put('EmailAddress', sSetting.EmailAddress__c);
                    csMap.put('Type', null);
                shipperMap.put('Contact', csMap);
            sMap.put('Shipper', shipperMap);

                Map<String, Object> consigneeMap = new Map<String, Object>();
                consigneeMap.put('Reference1', sr.Id);
                consigneeMap.put('Reference2', null);
                consigneeMap.put('AccountNumber', null);
                    Map<String, Object> pcMap = new Map<String, Object>();
                    pcMap.put('Line1', sr.Street__c != null ? sr.Street__c : '');
                    pcMap.put('Line2', '');
                    pcMap.put('Line3', '');
                    pcMap.put('City', sr.City__c);
                    pcMap.put('StateOrProvinceCode', sr.State__c);
                    pcMap.put('PostCode', sr.PostalCode__c);
                    pcMap.put('CountryCode', sr.CountryCode__c);
                    pcMap.put('Longitude', 0);
                    pcMap.put('Latitude', 0);
                    pcMap.put('BuildingNumber', null);
                    pcMap.put('BuildingName', null);
                    pcMap.put('Floor', null);
                    pcMap.put('Apartment', null);
                    pcMap.put('POBox', null);
                    pcMap.put('Description', null);
                consigneeMap.put('PartyAddress', pcMap);
                    Map<String, Object> ccMap = new Map<String, Object>();
                    ccMap.put('Department', null);
                    ccMap.put('PersonName', sr.AccountName__c);
                    ccMap.put('Title', null);
                    ccMap.put('CompanyName', sr.AccountCompany__c != null ? sr.AccountCompany__c : sr.AccountName__c);
                    ccMap.put('PhoneNumber1', sr.AccountMobileNumber__c != null ? sr.AccountMobileNumber__c : sr.AccountPhone__c);
                    ccMap.put('PhoneNumber1Ext', null);
                    ccMap.put('PhoneNumber2', sr.AccountMobileNumber__c == null ? sr.AccountPhone__c : null);
                    ccMap.put('PhoneNumber2Ext', null);
                    ccMap.put('FaxNumber', null);
                    ccMap.put('CellPhone', sr.AccountMobileNumber__c != null ? sr.AccountMobileNumber__c : sr.AccountPhone__c);
                    ccMap.put('EmailAddress', sr.AccountEmail__c);
                    ccMap.put('Type', null);
                consigneeMap.put('Contact', ccMap);
            sMap.put('Consignee', consigneeMap);

                Map<String, Object> dMap = new Map<String, Object>();
                dMap.put('Dimensions', null); // {Length, Width, Height, Unit}
                dMap.put('ChargeableWeight', null); // Not Sure
                dMap.put('DescriptionOfGoods', 'Documents');
                dMap.put('GoodsOriginCountry', sSetting.CountryCode__c);
                dMap.put('NumberOfPieces', 1);
                dMap.put('ProductGroup', sr.CountryCode__c == 'AE' ? 'DOM' : 'EXP');
                dMap.put('ProductType', sr.CountryCode__c == 'AE' ? 'OND' : 'GDX'); // PDX OR PPX OR PLX OR DDX OR DPX OR GDX OR GPX OR EPX
                dMap.put('PaymentType', 'P'); // P OR C OR 3
                dMap.put('PaymentOptions', 'ACCT'); // CASH OR ACCT OR PPST OR CRDT
                dMap.put('CustomsValueAmount', null); // ProductType "Dutible"
                dMap.put('CashOnDeliveryAmount', null); // Services "COD" being filled.
                dMap.put('InsuranceAmount', null);
                dMap.put('CashAdditionalAmount', null);
                dMap.put('CashAdditionalAmountDescription', null); // PaymentType "3" AND Cash Additional Amount is filled
                dMap.put('CollectAmount', null); // PaymentType "C" + PaymentOptions "ARCC"
                dMap.put('Services', null);
                dMap.put('Items', null);
                dMap.put('DeliveryInstructions', null);
                    Map<String, Object> awMap = new Map<String, Object>();
                    awMap.put('Unit', 'KG');
                    awMap.put('Value', 0.5);
                dMap.put('ActualWeight', awMAp);
            sMap.put('Details', dMap);

            sMap.put('ThirdParty', null);
            sMap.put('ShippingDateTime', '/Date(' + ((Date.newInstance(1970, 01, 01).daysBetween(Date.today())) * 86400) + '456)/');
            sMap.put('DueDate', '/Date(' + ((Date.newInstance(1970, 01, 01).daysBetween(Date.today().adddays(2))) * 86400) + '456)/');
            sMap.put('Comments', null);
            sMap.put('PickupLocation', null);
            sMap.put('OperationsInstructions', null);
            sMap.put('AccountingInstrcutions', null);
            sMap.put('Attachments', null);
            sMap.put('ForeignHAWB', null);
            sMap.put('TransportType', 0);
            sMap.put('PickupGUID', null);
            sMap.put('Number', null);
            sMap.put('ScheduledDelivery', null);

            sList.add(sMap);
        }
        finalMap.put('Shipments', sList);

        Map<String, Object> liMap = new Map<String, Object>();
        liMap.put('ReportID', 9729);
        liMap.put('ReportType', 'URL');

        finalMap.put('LabelInfo', liMap);

        Map<String, Object> ciMap = new Map<String, Object>();
        ciMap.put('Source', sSetting.Source__c);
        ciMap.put('AccountCountryCode', sSetting.CountryCode__c);
        ciMap.put('AccountEntity', sSetting.AccountEntity__c);
        ciMap.put('AccountPin', sSetting.AccountPin__c);
        ciMap.put('AccountNumber', sSetting.AccountNumber__c);
        ciMap.put('UserName', sSetting.Username__c);
        ciMap.put('Password', sSetting.Password__c);
        ciMap.put('Version', sSetting.Version__c);

        finalMap.put('ClientInfo', ciMap);

        Map<String, Object> tMap = new Map<String, Object>();
        tMap.put('Reference1', null);
        tMap.put('Reference2', null);
        tMap.put('Reference3', null);
        tMap.put('Reference4', null);
        tMap.put('Reference5', null);

        finalMap.put('Transaction', tMap);

        String requestBody = JSON.serialize(finalMap);
        System.debug('requestBody>>>' + requestBody);

        if (isFutureCallout && System.isFuture() == false) {
            CalloutToAramex.calloutFutureService(requestBody, true, Constants.ARAMEX_CREATE_SHIPMENTS_INTEGRATION);
        } else if (System.isFuture() == false) {
            CalloutToAramex.calloutService(requestBody, true, Constants.ARAMEX_CREATE_SHIPMENTS_INTEGRATION);
        }
    }

    @AuraEnabled
    public static String TrackingCallout(String srId) {
        try {
            List<ShipmentRequest__c> srList = ShipmentRequestService.queryAllFieldsWithExtraFields(new List<Id>{srId});

            String processName = Constants.ARAMEX_TRACk_SHIPMENTS_INTEGRATION;
            ShipmentSetting__mdt sSetting = [SELECT Id, Label, DeveloperName, AccountNumber__c, CountryCode__c, Username__c, Password__c, Version__c, AccountEntity__c, AccountPin__c, Source__c FROM ShipmentSetting__mdt WHERE DeveloperName =: processName];
            
            Map<String, Object> finalMap = new Map<String, Object>();
            List<String> sList = new List<String>();

            for (ShipmentRequest__c sr: srList) {
                sList.add(sr.AWBNumber__c);
            }
            finalMap.put('Shipments', sList);

            finalMap.put('GetLastTrackingUpdateOnly', false);

            Map<String, Object> ciMap = new Map<String, Object>();
            ciMap.put('Source', sSetting.Source__c);
            ciMap.put('AccountCountryCode', sSetting.CountryCode__c);
            ciMap.put('AccountEntity', sSetting.AccountEntity__c);
            ciMap.put('AccountPin', sSetting.AccountPin__c);
            ciMap.put('AccountNumber', sSetting.AccountNumber__c);
            ciMap.put('UserName', sSetting.Username__c);
            ciMap.put('Password', sSetting.Password__c);
            ciMap.put('Version', sSetting.Version__c);

            finalMap.put('ClientInfo', ciMap);
            finalMap.put('Transaction', null);

            String requestBody = JSON.serialize(finalMap);
            System.debug('requestBody>>>' + requestBody);

            return CalloutToAramex.calloutService(requestBody, true, Constants.ARAMEX_TRACk_SHIPMENTS_INTEGRATION);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}