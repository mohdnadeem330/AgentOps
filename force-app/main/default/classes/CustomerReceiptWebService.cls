/*
    * Name               : CustomerReceiptWebService
    * Description        : This class is used to get Receipt for Installment Line or Other Charges
    */
    @RestResource (urlMapping = '/customer/generatereceipt')
    global without sharing class CustomerReceiptWebService {
    
        public static Boolean isRunningTest = false;
        
        @HTTPPost
        global static void doPost(String paymentId, String referenceId){
            
            RestContextHandler handler = new RestContextHandler(true);
            try {
                RestRequest req = RestContext.request;
                ReceiptModel receiptModel = generateReceipt(paymentId, referenceId);
                if (receiptModel == null) {
                    handler.response.success = false;
                    handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                    handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
                } else {
                    handler.response.success = true;
                    handler.response.data = receiptModel;
                }
                handler.finalize();
            } catch(Exception ex){
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
                handler.finalize(ex);
            }
        }
        
        public static ReceiptModel generateReceipt(String paymentId, String referenceId) {
            ReceiptModel receiptModel = new ReceiptModel();
            receiptModel.paymentId = paymentId;
            String salesOrderId = '';
            String fileName = '';
            String parkingRefId = '';
           // Added By Neelesh Start
           // 
           system.debug('Order.getSObjectType() '+ Order.getSObjectType() );
           system.debug('((Id)paymentId).getSObjectType()' + ((Id)paymentId).getSObjectType() );
            
            if (((Id)paymentId).getSObjectType() == Order.getSObjectType()) {
                system.debug('Payment ID inside Orderobject' );
                // InstallmentLines__c line = CustomerServiceUtility.getInstallmentLineDetail(' (Id = \'' + paymentId + '\') ')[0];
                List<Order> relatedOrders = [
                    SELECT Id, OrderNumber,  ParkingAsset__r.Parking_Ref_ID__c, Sales_Order__r.UnitNumber__c,
                    (SELECT PaymentType__c, Status__c  FROM Receipt_Acknowledgements__r Where Status__c = 'Cleared')
                    FROM Order 
                    WHERE Id =: paymentId
                    // Sales_Order__c = :line.SalesOrder_
                    //     ORDER BY CreatedDate DESC 
                    //     LIMIT 1
                ];
                String unitNumber = (relatedOrders[0].Sales_Order__r != null) ? relatedOrders[0].Sales_Order__r.UnitNumber__c : ' ';
                String orderNumber = relatedOrders.isEmpty() ? 'Unknown' : relatedOrders[0].OrderNumber;
                parkingRefId = relatedOrders.isEmpty() || relatedOrders[0].ParkingAsset__r == null  ? 'N/A' : String.valueOf(relatedOrders[0].ParkingAsset__r.Parking_Ref_ID__c);
                fileName = 'Receipt-' + unitNumber + '-' + (CustomerAPIConstants.PARKING_PAYMENT + ' ' + orderNumber).replace(' ', '-') + '-' + System.now().format('dd-MM-yyyy') + '.pdf';
                salesOrderId = relatedOrders[0].Sales_Order__c;
                system.debug('Line 56 order object :salesOrderId ' + salesOrderId);
            }
            // neelesh end here below else logic is previously created
        
            else {
                List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwnerWithEmail(referenceId);
                String soIdsStr = String.join(soIds, '\',\'');
                
                String salesOrderWhrClause = '';
                if (!soIds.isEmpty()) {
                    salesOrderWhrClause = ' (Account__r.PersonEmail = \'' + referenceId + '\' OR Id IN (\'' + soIdsStr + '\')) AND ';
                } else {
                    salesOrderWhrClause = ' (Account__r.PersonEmail = \'' + referenceId + '\') AND ';
                }
                salesOrderWhrClause += ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
        
                String query = 'SELECT Id FROM SalesOrder__c WHERE ' + salesOrderWhrClause;
                List<Id> soIdList = new List<Id>();
                for(SalesOrder__c so: Database.query(query)) {
                    soIdList.add(so.Id);
                }
        
                if (((Id)paymentId).getSObjectType() == InstallmentLines__c.getSObjectType()) {
                    InstallmentLines__c line = CustomerServiceUtility.getInstallmentLineDetail(' (Id = \'' + paymentId + '\') ')[0];
                    fileName = 'Receipt-' + line.SalesOrder__r.UnitNumber__c + '-' + (CustomerAPIConstants.INSTALLMENT_PAYMENT + ' ' + line.InstallmentNumber__c).replace(' ', '-') + '-' + System.now().format('dd-MM-yyyy') + '.pdf';
                    salesOrderId = line.SalesOrder__c;
                } else {
                    SalesOrderOtherCharges__c otherCharge = CustomerServiceUtility.getSalesOrderOtherChargeDetail(' (Id = \'' + paymentId + '\') ')[0];
                    fileName = 'Receipt-' + otherCharge.SalesOrder__r.UnitNumber__c + '-' + (String.isNotBlank(otherCharge.SubType__c) ? otherCharge.TypeOfCharge__c + ' - ' + otherCharge.SubType__c : otherCharge.TypeOfCharge__c).replace(' ', '-') + '-' + System.now().format('dd-MM-yyyy') + '.pdf';
                    salesOrderId = otherCharge.SalesOrder__c;
                }
        
                if (soIdList.isEmpty() || String.isBlank(salesOrderId) || !soIdList.contains(salesOrderId)) {
                    return null;
                }
            }
    
            PageReference pdf = Page.ReceiptDocument;
            pdf.getParameters().put('salesOrderId', salesOrderId);
            pdf.getParameters().put('paymentId', paymentId);
            pdf.getParameters().put('parkingRefId', parkingRefId);
    
            pdf.setRedirect(true);
    
            Blob fileContent;
            if (!isRunningTest) {
                fileContent = pdf.getContent();
            }
            
            receiptModel.fileDetail = new DocumentQueryModel('pdf', fileContent, fileName);
    
            return receiptModel;
        }
        
        global class ReceiptModel{
            public String paymentId                                 {get;set;}
            public DocumentQueryModel fileDetail                    {get;set;}
        }
    }