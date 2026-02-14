/*
* Name               : CustomerPropertyJourneyWebService
* Description        : This class is used to get Property Journey for a Unit for Customer App and Protal
*/
@RestResource (urlMapping = '/customer/propertyjourney')
global without sharing class CustomerPropertyJourneyWebService {

    @HTTPPost
    global static void doPost(String customerId, String orderId, String lang, String referenceId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = propertyJourney(customerId, orderId, lang);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    public static PropertyJourneyUtility.MainPropertyJourneyModel propertyJourney(String customerId, String orderId, String lang) {
        PropertyJourneyUtility.MainPropertyJourneyModel mainPropertyJourneyModel = new PropertyJourneyUtility.MainPropertyJourneyModel();
        
        //----- Query on Sales Order and Hanover SR
        String whrClause = ' (Id = \'' + orderId + '\') ';
        SalesOrder__c salesOrder = CustomerServiceUtility.getSalesOrderDetail(whrClause)[0];

        HexaBPM__Service_Request__c srDetail = new HexaBPM__Service_Request__c();
        List<HexaBPM__Service_Request__c> srList = CustomerServiceUtility.getServiceRequestDetail(' (SalesOrder__c = \'' + orderId + '\' AND RecordType.Name = \'' + Constants.HANDOVER_RT + '\') ORDER BY LastModifiedDate DESC LIMIT 1');
        if (!srList.isEmpty()) {
            srDetail = srList[0];
        }

        mainPropertyJourneyModel = PropertyJourneyUtility.propertyJourneyDetails(salesOrder, srDetail, false, lang);
        
        return mainPropertyJourneyModel;
    }
}