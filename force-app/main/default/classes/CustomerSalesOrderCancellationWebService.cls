/* Name              : CustomerSalesOrderCancellationWebService
* Description        : This Class is Used for Cancelling the Existing SalesOrder when the Customer Changes the Payment Plan for a Unit in Customer App and Portal
Added By             : Tajinkumar Devar on 05-05-2025*/


@RestResource(urlMapping='/customer/salesOrderCancellation')
global with sharing class CustomerSalesOrderCancellationWebService {
    
    private static ResponseWrapper objResponse = new ResponseWrapper();
    
    @HTTPPatch
    global static void doPatch(String customerId, Boolean isPaymentPlanChanged, String orderId, String unitId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = CustomerSalesOrderCancellation(customerId,isPaymentPlanChanged, orderId, unitId);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    
    global static ResponseWrapper CustomerSalesOrderCancellation(String customerId, Boolean isPaymentPlanChanged, String orderId, String unitId){
        
        Savepoint sp;
        RestRequest req = RestContext.request;
        Boolean wasOrderCancelled = false;
        Boolean wasUnitUpdated = false;
        SalesOrder__c salesOrder;
        Unit__c unit;
        Account account;
        
        try {
            sp = Database.setSavepoint();
            
            if(!isPaymentPlanChanged) {
                objResponse.success = false;
                objResponse.message = 'No changes performed. Payment plan has not been changed.';
                return objResponse;
            }
            
            if (String.isBlank(customerId) ||String.isBlank(orderId) || String.isBlank(unitId)) {
                objResponse.success = false;
                objResponse.message = 'Missing or invalid input parameters.';
                return objResponse;
            }
            
            String accWhrClause = ' (Id = \'' + customerId + '\') ';
            List<Account> accountList = CustomerServiceUtility.getAccountDetail(accWhrClause);
            
            if (accountList.isEmpty()) {
                objResponse.success = false;
                objResponse.message = 'Account Id not found with provided ID.';
                return objResponse;
            }
            if (!accountList.isEmpty()) {
                account = accountList[0];
            }
            
            String whrClause = ' (Id = \'' + orderId + '\') ';
            List<SalesOrder__c> salesOrderList = CustomerServiceUtility.getSalesOrderDetail(whrClause);
            
            if (salesOrderList.isEmpty()) {
                objResponse.success = false;
                objResponse.message = 'Sales Order not found with provided ID.';
                return objResponse;
            }
            
            if (!salesOrderList.isEmpty()) {
                salesOrder = salesOrderList[0];
                
                if (salesOrder.Status__c != Constants.SO_STATUS_CANCELLED) {
                    salesOrder.Status__c = Constants.SO_STATUS_CANCELLED;
                    update salesOrder;
                    wasOrderCancelled = true;
                }
                
                if(unitId != salesOrder.unit__r.Id) {
                    objResponse.success = false;
                    objResponse.message = 'Unit not found with provided ID.';
                    return objResponse;
                } else {
                    unit = salesOrder.unit__r;
                    System.debug('Unit : ' + unit);
                }
            }
            // Commented because Unit Locking should not happen after SO is cancelled as per new 20 mins Timer implementation
            if (unit.LockExpiryTime__c != null && unit.LockedByCustomer__c != null && unit.Status__c != Constants.UNIT_STATUS_AVAILABLE && unit.LockExpiryTime__c > System.now()) {
              /*UnitAvailabilityWebService.UnitdigitalSales = true;
                UnitAvailabilityWebService.UnitCustomerId = account.Id; 
                BookingUtility.lockUnit(new List<Unit__c>{unit}, Constants.RESERVATION_TIMERNAME);*/
                unit.Status__c = Constants.UNIT_STATUS_BOOKING_INPROGRESS;
                update unit;
                wasUnitUpdated = true;
                System.debug('wasUnitUpdated : ' + wasUnitUpdated);
            } 
            
            if (wasOrderCancelled && salesOrder.Status__c == Constants.SO_STATUS_CANCELLED && wasUnitUpdated && unit.Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS) {
                objResponse.success = true;
                objResponse.statusCode = Constants.SUCCESS_CODE_200;
                objResponse.orderId = salesOrder.Id;
                objResponse.message = 'Previous Sales Order was cancelled due to a payment plan change.';
                
            } else if (wasOrderCancelled) {
                objResponse.success = true;
                objResponse.statusCode = Constants.SUCCESS_CODE_200;
                objResponse.orderId = salesOrder.Id;
                objResponse.message = 'Sales Order was cancelled, but Unit is not in Booking In Progress status.';
                
            } else {
                objResponse.success = false;
                objResponse.statusCode = 400;
                objResponse.message = 'No action taken. Sales Order was already cancelled or Unit status is invalid.';
            }
            
            return objResponse;
        }
        catch(Exception ex) {
            Database.rollback(sp);
            System.debug('Error Occured While Cancelling SalesOrder : ' + ex.getMessage() + ' ' +  ex.getStackTraceString());
            objResponse.success = false;
            objResponse.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            objResponse.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            return objResponse;
        }
    }
    
    global class ResponseWrapper {
        public String orderId; 
        public Boolean success;
        public String message;
        public Integer statusCode;
        
        global ResponseWrapper(){}
    }
}