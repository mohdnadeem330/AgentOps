/*
* Name               : CustomerPropertyJourneyWebServices
* Description        : This class is used to get Property Journeys for Units for Customer App and Protal
*/
@RestResource (urlMapping = '/customer/propertyjourneys')
global without sharing class CustomerPropertyJourneysWebService {

    @HTTPPost
    global static void doPost(String customerId, List<String> orderIds, String lang, String referenceId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = propertyJourneys(customerId, orderIds, lang);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    public static Map<String, List<MultiplePropertyJourneyUtility.PropertyJourneyModel>> propertyJourneys(String customerId, List<String> orderIds, String lang) {
        Map<String, List<MultiplePropertyJourneyUtility.PropertyJourneyModel>> propertyJourneyModelMap = new Map<String, List<MultiplePropertyJourneyUtility.PropertyJourneyModel>>();
        
        //----- Query on Sales Orders and Hanover SRs
        String soIdsStr = String.join(orderIds, '\',\'');
        String whrClause = ' (Id IN (\'' + soIdsStr + '\')) ';
        List<SalesOrder__c> salesOrderList = CustomerServiceUtility.getSalesOrderDetail(whrClause);

        /*List<HexaBPM__Service_Request__c> srList = CustomerServiceUtility.getServiceRequestDetail(' (SalesOrder__c IN (\'' + soIdsStr + '\') AND RecordType.Name = \'' + Constants.HANDOVER_RT + '\') ORDER BY LastModifiedDate ASC');
        Map<String, HexaBPM__Service_Request__c> srDetailsMap = new Map<String, HexaBPM__Service_Request__c>();
        for (HexaBPM__Service_Request__c srDetail: srList) {
            srDetailsMap.put(srDetail.SalesOrder__c, srDetail);
        }

        for (SalesOrder__c salesorder: salesOrderList) {
            HexaBPM__Service_Request__c srDetail = srDetailsMap.containsKey(salesorder.Id) ? srDetailsMap.get(salesorder.Id) : new HexaBPM__Service_Request__c();

            PropertyJourneyUtility.MainPropertyJourneyModel mainPropertyJourneyModel = PropertyJourneyUtility.propertyJourneyDetails(salesOrder, srDetail, true, lang);
            List<PropertyJourneyUtility.PropertyJourneyModel> propertyJourneyModel = mainPropertyJourneyModel.propertyJourneyDetails;
            propertyJourneyModelMap.put(salesorder.Id, propertyJourneyModel);
        }*/
		 propertyJourneyModelMap =  MultiplePropertyJourneyUtility.propertyJourneyDetails(salesOrderList,true,lang);        
        return propertyJourneyModelMap;
    }
}