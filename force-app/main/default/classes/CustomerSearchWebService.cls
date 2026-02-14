/*
* Name               : CustomerSearchWebService
* Description        : This class is used to serach on Project, Sales Order and Serivce Request
*/
@RestResource (urlMapping = '/customer/search')
global without sharing class CustomerSearchWebService {
    
    @HTTPPost
    global static void doPost(String customerId, List<String> searchKey, String referenceId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = getSearchResult(customerId, searchKey);
            handler.response.success = true;
            handler.finalize();
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    
    public static SearchModel getSearchResult(String customerId, List<String> searchKey) {
        SearchModel searchModel = new SearchModel();

        // START | Building where clause for Sales Order, Service Request and Case to filter based on Search string
        String salesOrderWhereCluse = '';
        for (String sKey: searchKey) {
            salesOrderWhereCluse += (String.isNotBlank(salesOrderWhereCluse) ? ' OR ' : '') + ' Name LIKE \'%' + sKey + '%\' OR ProjectName__c LIKE \'%' + sKey + '%\' OR Unit__r.Name LIKE \'%' + sKey + '%\' ';
        }
        // END | Building where clause for Sales Order, Service Request and Case to filter based on Search string
        
        List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwner(new List<Id>{customerId});
        String soIdsStr = String.join(soIds, '\',\'');

        if (!soIds.isEmpty()) {
            searchModel.salesOrders = CustomerServiceUtility.getSalesOrderDetailForProfile(' ((Account__c = \'' + customerId + '\' OR Id IN (\'' + soIdsStr + '\')) AND ( ' + salesOrderWhereCluse + ' ) AND (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\')) ');
        } else {
            searchModel.salesOrders = CustomerServiceUtility.getSalesOrderDetailForProfile(' ((Account__c = \'' + customerId + '\') AND ( ' + salesOrderWhereCluse + ' ) AND (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\')) ');
        }

        CustomerGetServiceRequestWebService.SRModel srModel = new CustomerGetServiceRequestWebService.SRModel();
        srModel.customerId = customerId;
        srModel.searchKey = searchKey;
        String jsonBody = JSON.serialize(srModel);

        CustomerGetServiceRequestWebService.ResponseModel responseModel = CustomerGetServiceRequestWebService.getServiceRequest(jsonBody, null, false);
        searchModel.serviceRequests = responseModel.serviceRequests;

        searchModel.totalSearchResult = searchModel.serviceRequests.size() + searchModel.salesOrders.size();
        return searchModel;
    }

    global class SearchModel {
        public List<CustomerGetServiceRequestWebService.ServiceRequestModel> serviceRequests                {get;set;}
        public List<SalesOrder__c> salesOrders                                                              {get;set;}
        public Decimal totalSearchResult                                                                    {get;set;}
    }
}