/*
* Name               : CustomerHomeWebservice
* Description        : This class is used to get overview of Investment and Welcome message
*/
@RestResource (urlMapping = '/customer/home')
global without sharing class CustomerHomeWebservice {
    
    @HTTPPost
    global static void doPost(String customerId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = getHomeData(customerId);
            handler.response.success = true;
            handler.finalize();
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    
    public static List<HomeModel> getHomeData(String customerId) {
        List<HomeModel> homeModelList = new List<HomeModel>();

        //----- Welcome message from System Message
        homeModelList.add(new HomeModel('Welcome Message', Utilities.getSystemMessages('CUSTOMER_WELCOME_MESSAGE').Message__c));
        
        Decimal totalEquity = 0;
        Decimal totalOutstanding = 0;
        Decimal totalNetAmount = 0;
        Decimal totalInvestment = 0;
        Decimal totalFuturePayment = 0;
        Decimal TotalParkingPayment = 0;         //Added by Neelesh

        List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwner(new List<Id>{customerId});

        String soIdsStr = String.join(soIds, '\',\'');
        String cancelledWhereCaluse = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\' AND Status__c != \'' + Constants.SO_STATUS_RTO_CONVERTED + '\' AND Status__c != \'RTOConverted\' ) ';
        String salesOrderWhrClause = '';
        if (!soIds.isEmpty()) {
            salesOrderWhrClause = ' ((Account__c = \'' + customerId + '\' OR Id IN (\'' + soIdsStr + '\')) AND ' + cancelledWhereCaluse + ') ';
        } else {
            salesOrderWhrClause = ' (Account__c = \'' + customerId + '\' AND ' + cancelledWhereCaluse + ') ';
        }
        List<SalesOrder__c> salesOrderList = CustomerServiceUtility.getSalesOrderDetail(salesOrderWhrClause);

        //----- Home Page dashboard component like total Investment, Outstanding and etc.
        String personContactId ='';
        Boolean GTYBFormSubmitted = false;
        for (SalesOrder__c salesOrder: salesOrderList) {
            if(personContactId == ''){
                personContactId = salesOrder.Account__r.PersonContactId;
            }
            if(GTYBFormSubmitted == false){
        GTYBFormSubmitted = salesOrder.Account__r.GTYB_Form_Submitted__pc;
            }
            Decimal soTotalOutstanding = salesOrder.OutstandingAmount__c;

            for (InstallmentLines__c line: salesOrder.InstallmentLines__r) {
                if (line.InstallmentDate__c > date.today() || line.InstallmentDate__c == null) {
                    totalFuturePayment += line.OutstandingAmount__c;
                }
            }
            for (SalesOrderOtherCharges__c otherCharge: salesOrder.SalesOrdersOtherCharges__r) {
                if (otherCharge.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES) {
                    soTotalOutstanding += otherCharge.OutstandingAmount__c;
                }
            }
            
            totalOutstanding += soTotalOutstanding;
            totalEquity += salesOrder.TotalBilled__c;
            totalNetAmount += salesOrder.NetAmount__c;
            // totalInvestment += salesOrder.NetAmount__c;
            // --- Fetch and calculate Total Parking Payment --- added By neelesh 
           
            
        }
        
        //by sujesh on 11June as per recommednation from harry that total invstment shown should be the property value. 
        //less the rebate. Pending to write the logic for rebate
      
        //totalInvestment += totalEquity + totalOutstanding + totalFuturePayment;
		totalInvestment = totalNetAmount;
        
        //Added by neelesh
        /* List<Order> parkingOrders = [
                SELECT TotalAmount 
                FROM Order
                WHERE AccountId = :customerId 
                AND Payment_Status__c IN ('Received', 'Cleared')
            ];
            
            for (Order order : parkingOrders) {
                totalParkingPayment += order.TotalAmount;
            }*/
        
        List<ReceiptAcknowledgement__c> receipts = [
            SELECT Amount__c 
            FROM ReceiptAcknowledgement__c 
            WHERE Account__c = :customerId 
            AND Status__c IN ('Received', 'Cleared')
            AND Order__c != null 
            AND CPQQuote__c != null
        ];
        
        for (ReceiptAcknowledgement__c receipt : receipts) {
            totalParkingPayment += receipt.Amount__c;
        }
		//Neelesh code end here        
        
        homeModelList.add(new HomeModel('Total Investments', totalInvestment));
        homeModelList.add(new HomeModel('Total Paid', totalEquity));
        homeModelList.add(new HomeModel('Total Outstanding', totalOutstanding));
        homeModelList.add(new HomeModel('Total Future Payment', totalFuturePayment));
         homeModelList.add(new HomeModel('ContactId',personContactId));
        homeModelList.add(new HomeModel('GTYBFormSubmitted',GTYBFormSubmitted));
                //Added By Neelesh 
        homeModelList.add(new HomeModel('Total Parking Payment', totalParkingPayment)); // Added new value

        
        return homeModelList;
    }

    global class HomeModel {
        public String label                                 {get;set;}
        public Object value                                 {get;set;}
        
        public HomeModel (String label, Object value) {
            this.label = label;
            this.value = value;
        }
                
    }
}