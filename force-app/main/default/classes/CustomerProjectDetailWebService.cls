/*
* Name               : CustomerProjectDetailWebService
* Description        : This class is used to get a Project Details with all related Sales Order of Customer
*/
@RestResource (urlMapping = '/customer/projectdetails')
global without sharing class CustomerProjectDetailWebService {
    
    @HTTPPost
    global static void doPost(String customerId, String projectId, String orderId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = getProjectDetail(customerId, projectId, orderId);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    public static List<CustomerProfileWebservice.SalesOrderModel> getProjectDetail(String customerId, String projectId, String orderId) {
        List<CustomerProfileWebservice.SalesOrderModel> salesOrderModelList = new List<CustomerProfileWebservice.SalesOrderModel>();

        List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwner(new List<Id>{customerId});

        String soIdsStr = String.join(soIds, '\',\'');
//        String cancelledWhereCaluse = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
        String cancelledWhereCaluse = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\'  AND Status__c != \'' + Constants.SO_STATUS_RTO_CONVERTED + '\'   AND Status__c != \'RTOConverted\' ) ';
        String salesOrderWhrClause = '';
        if (!soIds.isEmpty()) {
            salesOrderWhrClause = ' (Id != \'' + orderId + '\' AND Unit__r.Project__c = \'' + projectId + '\' AND (Account__c = \'' + customerId + '\' OR Id IN (\'' + soIdsStr + '\')) AND ' + cancelledWhereCaluse + ') ';
        } else {
            salesOrderWhrClause = ' (Id != \'' + orderId + '\' AND Unit__r.Project__c = \'' + projectId + '\' AND Account__c = \'' + customerId + '\' AND ' + cancelledWhereCaluse + ') ';
        }
        List<SalesOrder__c> salesOrderList = CustomerServiceUtility.getSalesOrderDetailForProfile(salesOrderWhrClause);

        salesOrderModelList = CustomerProfileWebservice.salesOrderDetails(customerId, salesOrderList);

        return salesOrderModelList;
    }
}