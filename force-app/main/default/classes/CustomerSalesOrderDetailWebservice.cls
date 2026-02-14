/*
* Name               : CustomerSalesOrderDetailWebservice
* Description        : This class is used to get a Sales Order details
*/
@RestResource (urlMapping = '/customer/salesorderdetail')
global without sharing class CustomerSalesOrderDetailWebservice {
    
    @HTTPPost
    global static void doPost(Id orderId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = getSalesOrder(orderId);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception e) {
            System.debug('msg '+ e.getMessage());
            System.debug('line no '+e.getLineNumber());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    global static SalesOrderModel getSalesOrder(String orderId) {
        SalesOrderModel salesOrderModel = new SalesOrderModel();

        List<SalesOrder__c> salesOrderList = CustomerServiceUtility.getSalesOrderDetail(' (Id = \'' + orderId + '\') ');

        SalesOrder__c salesOrderRecord = new SalesOrder__c();
        if (salesOrderList.isEmpty()) {
            return null;
        } else {
            salesOrderRecord = salesOrderList[0];
        }
        
        salesOrderModel.salesOrderRecordDetail = salesOrderRecord;
        
        String orderDate = salesOrderRecord.BookingDate__c != null ? DateTime.newInstance(salesOrderRecord.BookingDate__c.year(), salesOrderRecord.BookingDate__c.month(),salesOrderRecord.BookingDate__c.day()).format('dd MMM YYYY') : '';
        salesOrderModel.orderDetails.add(new salesOrderRecord('Order Date', orderDate));
        salesOrderModel.orderDetails.add(new salesOrderRecord('Unit', salesOrderRecord.Unit__r.Name));
        salesOrderModel.orderDetails.add(new salesOrderRecord('Unit Area', salesOrderRecord.unit__r.TotalArea__c));
        salesOrderModel.orderDetails.add(new salesOrderRecord('Owner Share Percentage', salesOrderRecord.OwnerSharePercentage__c));
        salesOrderModel.orderDetails.add(new salesOrderRecord('Net Amount', String.valueOf(salesOrderRecord.NetAmount__c) != null ? String.valueOf(salesOrderRecord.NetAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.NetAmount__c)));
        salesOrderModel.orderDetails.add(new salesOrderRecord('Collected Amount', String.valueOf(salesOrderRecord.TotalBilled__c) != null ? String.valueOf(salesOrderRecord.TotalBilled__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.TotalBilled__c)));
        salesOrderModel.orderDetails.add(new salesOrderRecord('Outstanding Amount', String.valueOf(salesOrderRecord.TotalOutstanding__c) != null ? String.valueOf(salesOrderRecord.TotalOutstanding__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.TotalOutstanding__c)));
        salesOrderModel.orderDetails.add(new salesOrderRecord('Unit Model', salesOrderRecord.UnitModel__c));
        salesOrderModel.orderDetails.add(new salesOrderRecord('Project Location', salesOrderRecord.Unit__r.Project__r.Name + (String.isNotBlank(salesOrderRecord.Unit__r.Project__c) && String.isNotBlank(salesOrderRecord.Unit__r.Project__r.City__c) ? ', ' + salesOrderRecord.Unit__r.Project__r.City__c : '')));

        Map<Id,Document__c> documentDetailMap = new Map<Id,Document__c>(salesOrderRecord.Documents__r); 
        Map<Id,DocumentQueryModel> documentData = new Map<Id,DocumentQueryModel>();
        
        if(documentDetailMap != null && !documentDetailMap.isEmpty()) {
            documentData =  DocumentService.getDocumentDetails(documentDetailMap);
        }
        salesOrderModel.documents = documentData.values();
        return salesOrderModel;
    }
    
    global class SalesOrderModel {
        public List<SalesOrderRecord> orderDetails                          {get;set;}
        public SalesOrder__c salesOrderRecordDetail                         {get;set;}
        public List<DocumentQueryModel> documents                           {get;set;}
        
        global SalesOrderModel() {
            this.orderDetails = new List<SalesOrderRecord>();
            this.documents = new List<DocumentQueryModel>();
        }
    }
    
    global class SalesOrderRecord {
        public String label     {get;set;}
        public Object value     {get;set;}
        
        public SalesOrderRecord(String label, Object value) {
            this.label = label;
            this.value = value;
        }
    }
}