/*
* Name               : CustomerFinancialWebservice
* Description        : This class is used to get Customer's Overdue Payment, Upcoming Payment and Other Charges for Sales Order and Service Request
*/
@RestResource (urlMapping = '/customer/financial')
global without sharing class CustomerFinancialWebservice {
    
    public static String globalOrderId = '';
    //Added by Tajinkumar Start
    public static Constant__mdt constMdt;
    public static Map<String,MilestonePayment__mdt> milestonePaymentMap;
    static 
    {
        if(constMdt == null){
            constMdt = Constant__mdt.getInstance('UpcomingCustomerPaymentNoOfMonth');
        }
        if(milestonePaymentMap == null){
            milestonePaymentMap = MilestonePayment__mdt.getAll(); 
        }
    }
    //Added by Tajinkumar End

    @HTTPPost
    global static void doPost(String customerId, String orderId, String paymentType, String paymentStatus){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = financial(customerId, orderId, paymentType, paymentStatus);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    public static FinancialModel financial(String customerId, String orderId, String paymentType, String paymentStatus) {
        FinancialModel financialModel = new FinancialModel();

        globalOrderId = orderId;
        boolean containsParking = false;

        orderId = orderId == CustomerAPIConstants.ALL ? '' : orderId;
        System.debug('orderId line 34' + orderId);

        //----- Building where clause for Financial statement based on Sales Order
        String cancelledWhereCaluse = ' (SalesOrder__r.Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND SalesOrder__r.Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\' AND  SalesOrder__r.Status__c != \'' + Constants.SO_STATUS_RTO_CONVERTED + '\' AND  SalesOrder__r.Status__c != \'RTOConverted\') '; // Added by Sateesh for Skipping RTO SO
        String whrClause = '';
        if (String.isNotBlank(orderId)) {
            whrClause = ' (SalesOrder__r.Id = \'' + orderId + '\' AND ' + cancelledWhereCaluse + ') ';   
        } else {
            List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwner(new List<Id>{customerId});
            String soIdsStr = String.join(soIds, '\',\'');
            if (!soIds.isEmpty()) {
                whrClause = ' ((SalesOrder__r.Account__c = \'' + customerId + '\' OR SalesOrder__r.Id IN (\'' + soIdsStr + '\')) AND ' + cancelledWhereCaluse + ') ';
            } else {
                whrClause = ' ((SalesOrder__r.Account__c = \'' + customerId + '\') AND ' + cancelledWhereCaluse + ') ';
            }
        }

        //----- Get all Installment Lines based on Type and Status
        List<InstallmentLines__c> installmentLineList = new List<InstallmentLines__c>();
        if (String.isBlank(paymentType) || paymentType == CustomerAPIConstants.INSTALLMENT_PAYMENT || paymentType == CustomerAPIConstants.DOWN_PAYMENT /* || paymentType == CustomerAPIConstants.PARKING_PAYMENT*/) {
            String installmentLineWhereQuery = String.isBlank(paymentType) ? '' : paymentType == CustomerAPIConstants.DOWN_PAYMENT ? ' InstallmentNumber__c = 1 AND ' : ' InstallmentNumber__c != 1 AND ';
            installmentLineWhereQuery += whrClause + ' ORDER BY SalesOrder__r.Name, InstallmentNumber__c ';
            System.debug('installmentLineWhereQuery : ' + installmentLineWhereQuery);
            installmentLineList = CustomerServiceUtility.getInstallmentLineDetail(installmentLineWhereQuery);
            System.debug('installmentLineList>>>' + JSON.serialize(installmentLineList));
        }

        //----- Get all Sales Order Other Charges based on Type and Status
        List<SalesOrderOtherCharges__c> otherChargeList = new List<SalesOrderOtherCharges__c>();
        if (String.isBlank(paymentType) || paymentType != CustomerAPIConstants.INSTALLMENT_PAYMENT || paymentType != CustomerAPIConstants.DOWN_PAYMENT)  {
            String admAdminFeeClause = paymentType == Constants.BUDGET_LINE_ADMFEE ? ' OR TypeOfCharge__c = \'' + Constants.BUDGET_LINE_ADMADMINFEE + '\' ' : '';
            String otherChargeWhereQuery = whrClause + (String.isNotBlank(paymentType) ? ' AND (TypeOfCharge__c = \'' + paymentType + '\' ' + admAdminFeeClause + ' OR SubType__c = \'' + paymentType + '\') ' : '') + ' ORDER BY SalesOrder__r.Name, CreatedDate ASC ';
            otherChargeList = CustomerServiceUtility.getSalesOrderOtherChargeDetail(otherChargeWhereQuery);
            System.debug('otherChargeList>>>' + JSON.serialize(otherChargeList));
        }

        String directDebitRequestWhereClause = whrClause + ' AND Status__c = \'' + CustomerAPIConstants.DDR_APPROVED_BY_BANK + '\' ';
        List<String> directDebitRequestList = new List<String>();
        for (DirectDebitRequest__c directDebitRequest: Database.query('SELECT Id, Name, SalesOrder__c, Status__c FROM DirectDebitRequest__c WHERE ' + directDebitRequestWhereClause)) {
            directDebitRequestList.add(directDebitRequest.SalesOrder__c);
            System.debug('directDebitRequestList>>>' + JSON.serialize(directDebitRequestList));
        }

        financialModel = populateFinancialDetails(installmentLineList, otherChargeList, directDebitRequestList, new Map<String, List<ReceiptAllocation__c>>(), paymentType, paymentStatus);
        List<String> unitNumbers = new List<String>();
        if(financialModel.unitNames != null) {
            for (String unitName : financialModel.unitNames.keySet()) {
                if (String.isNotBlank(unitName)) {
                    unitNumbers.add(unitName);
                }
            }  
        }
        System.debug('unitNumbers ' + unitNumbers);
        
        List<parkingOrders> parkingOrdersList = new List<parkingOrders>();
        List<Order> parkingOrderList  = new List<Order>();
        
            String whrcls ='';
            if(String.isNotBlank(orderId)){
               whrcls = ' WHERE Sales_Order__r.Id = \'' + orderId + '\'';   
            }else{
                whrcls = ' WHERE AccountId= \'' + customerId + '\' AND Sales_Order__c != null ';   
            }
             String ordelist = 'SELECT Id, TotalAmount, Amount_Outstanding__c, Amount_Received__c, EffectiveDate,  ParkingAsset__r.Ref_ID__c, ParkingAsset__r.Parking_Bay__c, Sales_Order__r.UnitNumber__c,'+
                '(SELECT PaymentType__c, Status__c  FROM Receipt_Acknowledgements__r where PaymentType__c = \'Online\')    FROM Order  '+whrcls;
                 
            /*List<Order> salesorderRelatedOrderList = [
                SELECT Id, TotalAmount, Amount_Outstanding__c, Amount_Received__c, EffectiveDate, 
                ParkingAsset__r.Ref_ID__c, ParkingAsset__r.Parking_Bay__c, Sales_Order__r.UnitNumber__c,
               (SELECT PaymentType__c, Status__c  FROM Receipt_Acknowledgements__r where PaymentType__c = 'Online')               
                FROM Order 
                WHERE Sales_Order__c =: orderId AND AccountId =: customerId 
            ];*/
        List<Order> salesorderRelatedOrderList =Database.query(ordelist); 
             parkingOrderList.addAll(salesorderRelatedOrderList);
            
            system.debug('SalesOrder related Order '+ parkingOrdersList);

        
        
        /*if((String.isBlank(orderId) || parkingOrderList.isEmpty() ) && String.isNotBlank(customerId)) {
            List<Order> accountRelatedOrderList = [
                SELECT Id, TotalAmount, Amount_Outstanding__c, Amount_Received__c, EffectiveDate, 
                ParkingAsset__r.Ref_ID__c, ParkingAsset__r.Parking_Bay__c, Sales_Order__r.UnitNumber__c,
			   (SELECT PaymentType__c, Status__c  FROM Receipt_Acknowledgements__r where PaymentType__c = 'Online')               
                FROM Order 
                WHERE AccountId =: customerId 
                AND Sales_Order__c != null
                //AND Sales_Order__r.UnitNumber__c IN :unitNumbers
            ];
                parkingOrderList.addAll(accountRelatedOrderList);
        }*/
        
        String PaymentMode = CustomerAPIConstants.PAYMENT_MODE_ONLINE;
        Decimal bufferAmount = 0;
        try {
            bufferAmount = Decimal.valueOf(System.Label.PremiumParkingPaymentBuffer);
        } catch (Exception e) {
            System.debug('Error fetching PremiumParkingPaymentBuffer: ' + e.getMessage());
        }
        //system.debug('parkingOrderList 125 line '+ parkingOrderList[0]);
        if (!parkingOrderList.isEmpty() && paymentType != CustomerAPIConstants.INSTALLMENT_PAYMENT  && paymentType != CustomerAPIConstants.DOWN_PAYMENT /*&&  paymentType == CustomerAPIConstants.PARKING_PAYMENT*/) {
            containsParking = true;
    		financialModel.containsParking = true;
            for (Order order : parkingOrderList) {
                String orderPaymentStatus;
                Decimal totalAmount = order.TotalAmount != null ? order.TotalAmount : 0;
                Decimal outstandingAmount = order.Amount_Outstanding__c != null ? order.Amount_Outstanding__c : 0;
                Decimal amountRecieved = order.Amount_Received__c != null ? order.Amount_Received__c : 0;
                
                if (outstandingAmount == 0 && amountRecieved  >= (totalAmount - bufferAmount)) {
					orderPaymentStatus = CustomerAPIConstants.PAYMENT_STATUS_PAID;                   
                } else if (outstandingAmount > 0 && amountRecieved < totalAmount) {
                    orderPaymentStatus =  CustomerAPIConstants.PAYMENT_STATUS_IN_PROCESS;
       		    } else if (outstandingAmount == 0 && amountRecieved < totalAmount ) {
              		orderPaymentStatus = CustomerAPIConstants.PAYMENT_STATUS_UNPAID;
        		} else if (outstandingAmount > 0) {
                    orderPaymentStatus =  CustomerAPIConstants.PAYMENT_STATUS_IN_PROCESS;
       			} else {
                    orderPaymentStatus = 'Payment Status Unknown'; 
                }
                financialModel.unitNames.put(order.Sales_Order__r.UnitNumber__c, order.Sales_Order__c);
                 String Status = '';
                System.debug('Test');
                if (paymentType == CustomerAPIConstants.PARKING_PAYMENT || (paymentType == '' ||paymentType == null)) {
                    // Add all five possible payment statuses
                    if(paymentStatus != '' && paymentStatus!= null){
                        financialModel.paymentStatus.add(paymentStatus);
                    }else if(paymentType == CustomerAPIConstants.PARKING_PAYMENT && (paymentStatus == '' || paymentStatus== null)){
                        financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_PAID);
                        financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_IN_PROCESS);
                        financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_UNPAID);
                    }else {
                        financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_PAID);
                        financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_IN_PROCESS);
                        financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_UNPAID);
                        financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_CLEARED);
                        financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_FUTURE_PAYMENT);
                    }
                } else {
                    // Otherwise, add only the relevant status
                    if (String.isNotBlank(status)) {
                        financialModel.paymentStatus.add(status);
                    }
                } 
                if ((paymentType == CustomerAPIConstants.PARKING_PAYMENT ||(paymentType == ''||paymentType == null)) && paymentStatus != CustomerAPIConstants.PAYMENT_STATUS_CLEARED &&  paymentStatus != CustomerAPIConstants.PAYMENT_STATUS_FUTURE_PAYMENT) {
                    financialModel.paymentType.add(CustomerAPIConstants.PARKING_PAYMENT);
                }
                
                if (String.isBlank(paymentStatus) || paymentStatus == orderPaymentStatus) {
                List<String> paymentTypes = new List<String>();
                Boolean isDownloadReceipt = false; 
                if (order.Receipt_Acknowledgements__r != null && !order.Receipt_Acknowledgements__r.isEmpty()) {
                            for (ReceiptAcknowledgement__c receipt : order.Receipt_Acknowledgements__r) {
                                if (receipt.PaymentType__c != null && receipt.PaymentType__c == 'Online' ) {
                                    system.debug('check payment type 155 '+ receipt.PaymentType__c);
                                    paymentTypes.add(receipt.PaymentType__c);
                                }
                                if (receipt.Status__c != null && receipt.Status__c == 'Cleared') {
                                    isDownloadReceipt = true;
                                }
                            }
                            system.debug('check payment type 160 '+ paymentTypes);
                        }    
                        String OrderpaymentType = paymentTypes.isEmpty() ? 'Not Available' : 'Parking Payment' ;
                        parkingOrdersList.add(new parkingOrders(
                            order.ParkingAsset__r.Ref_ID__c,      
                            order.ParkingAsset__r.Parking_Bay__c,         
                            order.TotalAmount,                    
                            order.Amount_Outstanding__c,           
                            order.Amount_Received__c,  
                            order.Sales_Order__r.UnitNumber__c,  // Corrected to fetch unit number
                            order.Id,  
                            order.EffectiveDate,
                            orderPaymentStatus,
                            PaymentMode,
                            OrderpaymentType,
                            isDownloadReceipt
                        ));
                    }
                } 
        }
        System.debug('filteredParkingOrders at line 202: ' + JSON.serialize(parkingOrdersList));
         if (parkingOrdersList.isEmpty()) {
            financialModel.paymentStatus.clear(); // Clear any existing values
             if(paymentStatus =='' || paymentStatus == null){
            financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_CLEARED);
            financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_FUTURE_PAYMENT);
             }else{
                 financialModel.paymentStatus.add(paymentStatus);
             }
        }

            List<parkingOrders> filteredParkingOrders = new List<parkingOrders>();  
            if(paymentType == CustomerAPIConstants.PARKING_PAYMENT){
                for (parkingOrders parkingOrder : parkingOrdersList) {
                    if (parkingOrder.PaymentType == CustomerAPIConstants.PARKING_PAYMENT && paymentType == CustomerAPIConstants.PARKING_PAYMENT) {
                    	filteredParkingOrders.add(parkingOrder);
                      }
                }
            }
            else{
                for (parkingOrders parkingOrder : parkingOrdersList) {
                    filteredParkingOrders.add(parkingOrder);
                }
            }
		System.debug('filteredParkingOrders at line 217: ' + JSON.serialize(filteredParkingOrders));
        financialModel.parkingOrders = filteredParkingOrders;
        // Added by Neelesh End
        return financialModel;
    }

    public static FinancialModel populateFinancialDetails(List<InstallmentLines__c> installmentLineList, List<SalesOrderOtherCharges__c> otherChargeList, List<String> directDebitRequestList, Map<String, List<ReceiptAllocation__c>> receiptMap, String paymentType, String paymentStatus) {
        FinancialModel financialModel = new FinancialModel();
        financialModel.filterUnitNo = globalOrderId;

        Decimal bufferOutstandingAmount = Decimal.valueOf(System.Label.BufferOutstandingAmount);
        
        
      //Integer UpcomingPayment = Integer.valueOf(Utilities.getConstant('UpcomingCustomerPaymentNoOfMonth').ConstantValue__c);
        Integer UpcomingPayment = constMdt != null ? Integer.valueOf(constMdt.ConstantValue__c) : null;//Added by Tajinkumar
        System.debug('UpcomingPayment : ' + UpcomingPayment);
        List<Id> projectIds = new List<Id>();
        List<Id> buildingIds = new List<Id>();
        if (!installmentLineList.isEmpty()) {
            for (InstallmentLines__c installmentLine: installmentLineList) {
                projectIds.add(installmentLine.SalesOrder__r.Unit__r.Project__c);
                buildingIds.add(installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__c);
            }
        }
        System.debug('projectIds : ' + projectIds);
       /* List<MilestonePayment__mdt> projectMilestonePaymentList = [SELECT Id, ProjectId__c, BuildingId__c, APIKey__c, SecretKey__c, ProfileId__c, IsActive__c FROM MilestonePayment__mdt WHERE ProjectId__c =: projectIds];
        List<MilestonePayment__mdt> buildingMilestonePaymentList = [SELECT Id, ProjectId__c, BuildingId__c, APIKey__c, SecretKey__c, ProfileId__c, IsActive__c FROM MilestonePayment__mdt WHERE BuildingId__c =: buildingIds];

        if (Test.isRunningTest()) {
            projectMilestonePaymentList = [SELECT Id, ProjectId__c, BuildingId__c, APIKey__c, SecretKey__c, ProfileId__c, IsActive__c FROM MilestonePayment__mdt LIMIT 1];
            buildingMilestonePaymentList = [SELECT Id, ProjectId__c, BuildingId__c, APIKey__c, SecretKey__c, ProfileId__c, IsActive__c FROM MilestonePayment__mdt LIMIT 1];
        }
        
        projectIds = new List<Id>();
        buildingIds = new List<Id>();
        if (!projectMilestonePaymentList.isEmpty()) {
            for (MilestonePayment__mdt milestone: projectMilestonePaymentList) {
                if (String.isBlank(milestone.BuildingId__c) && milestone.IsActive__c == true && String.isNotBlank(milestone.APIKey__c) && String.isNotBlank(milestone.SecretKey__c) && String.isNotBlank(milestone.ProfileId__c)) {
                    projectIds.add(milestone.ProjectId__c);
                }
            }
        }
        if (!buildingMilestonePaymentList.isEmpty()) {
            for (MilestonePayment__mdt milestone: buildingMilestonePaymentList) {
                if (milestone.IsActive__c == true && String.isNotBlank(milestone.APIKey__c) && String.isNotBlank(milestone.SecretKey__c) && String.isNotBlank(milestone.ProfileId__c)) {
                    buildingIds.add(milestone.BuildingId__c);
                }
            }
        }*/
        
        //Added By Tajinkumar Devar on 16-05-2025 Optimizing for Reducing number of SOQL
        Set<Id> getProjectIds = new Set<Id>();
        Set<Id> getBuildingIds = new Set<Id>();
       
        if(!Test.isRunningTest()){
            for(MilestonePayment__mdt projMilesone : milestonePaymentMap.values()){
                if (projMilesone.IsActive__c == true && String.isBlank(projMilesone.BuildingId__c) && String.isNotBlank(projMilesone.ProjectId__c) && projectIds.contains(Id.valueOf(projMilesone.ProjectId__c)) && String.isNotBlank(projMilesone.APIKey__c) && String.isNotBlank(projMilesone.SecretKey__c) && String.isNotBlank(projMilesone.ProfileId__c)) {
                    getProjectIds.add(projMilesone.ProjectId__c);
                    System.debug('getProjectIds : ' + getProjectIds);
                }
                if (projMilesone.IsActive__c == true && String.isNotBlank(projMilesone.BuildingId__c) && buildingIds.contains(Id.ValueOf(projMilesone.BuildingId__c)) && String.isNotBlank(projMilesone.APIKey__c) && String.isNotBlank(projMilesone.SecretKey__c) && String.isNotBlank(projMilesone.ProfileId__c)) {
                    getBuildingIds.add(projMilesone.BuildingId__c);
                    System.debug('getBuildingIds  :' + getBuildingIds);
                }
            }
        }
        else {
            List<MilestonePayment__mdt> projectMilestonePaymentList = [SELECT Id, ProjectId__c, BuildingId__c, APIKey__c, SecretKey__c, ProfileId__c, IsActive__c FROM MilestonePayment__mdt LIMIT 1];
        }

        //----- Populate Installment Line details
        if (!installmentLineList.isEmpty()) {
            
            String salesOrderId = installmentLineList[0].SalesOrder__c;
            financialModel.filterUnitNo = String.isNotBlank(financialModel.filterUnitNo) ? financialModel.filterUnitNo : salesOrderId;
            Boolean lastPayNow = false;
            for (InstallmentLines__c installmentLine: installmentLineList) {
                financialModel.unitNames.put(installmentLine.SalesOrder__r.UnitNumber__c, installmentLine.SalesOrder__c);
                Boolean isFuturePayment = installmentLine.InstallmentPayoutDate__c == null ? true : installmentLine.InstallmentPayoutDate__c > Date.today().addMonths(UpcomingPayment) ? true : false;
                String status = installmentLine.InstallmentPayoutDate__c != null || installmentLine.OutstandingAmountToReceive__c <= bufferOutstandingAmount ? CustomerAPIConstants.PAYMENT_STATUS_IN_PROCESS : CustomerAPIConstants.PAYMENT_STATUS_PAYMENT_DUE;
                if (installmentLine.InstallmentPayoutDate__c < date.today() && installmentLine.OutstandingAmountToReceive__c > bufferOutstandingAmount) {
                    status = CustomerAPIConstants.PAYMENT_STATUS_PAYMENT_DUE;
                } else if (installmentLine.OutstandingAmount__c <= bufferOutstandingAmount) {
                    status = CustomerAPIConstants.PAYMENT_STATUS_CLEARED;
                } else if (isFuturePayment) {
                    status = CustomerAPIConstants.PAYMENT_STATUS_FUTURE_PAYMENT;
                }  
                //Added By Neelesh ------------
                 if (String.isBlank(paymentStatus) && paymentType == CustomerAPIConstants.PARKING_PAYMENT ) {  
                    // If paymentStatus is blank, add "Payment In Progress", "Unpaid", and "Paid"
                    financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_IN_PROCESS);
                    financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_UNPAID);
                    financialModel.paymentStatus.add(CustomerAPIConstants.PAYMENT_STATUS_PAID);
                }
                // Added By Neelesh End here ------------------
                // else if (installmentLine.InstallmentPayoutDate__c <= Date.today().addMonths(UpcomingPayment) && installmentLine.OutstandingAmountToReceive__c > bufferOutstandingAmount) {
                //     status = CustomerAPIConstants.PAYMENT_STATUS_PAYMENT_DUE;
                // }
                if (financialModel.filterUnitNo != CustomerAPIConstants.ALL && financialModel.filterUnitNo != installmentLine.SalesOrder__c) {
                    continue;
                }
                
                if (String.isBlank(paymentStatus) || status == paymentStatus) {
                    Boolean isWireTransfer = false;
                    String receiptPaymentMode = '';
                    Date clearedDate = null;
                   Decimal totalAllocatedAmount = 0;
                     Decimal outstandingAmount = installmentLine.OutstandingAmount__c;
                    List<ReceiptAllocation__c> allocationList = !installmentLine.Receipt_Allocations__r.isEmpty() ? installmentLine.Receipt_Allocations__r : !receiptMap.isEmpty() && receiptMap.containsKey(installmentLine.Id) ? receiptMap.get(installmentLine.Id) : new List<ReceiptAllocation__c>();
                    for (ReceiptAllocation__c allocation: allocationList) {
                        if (allocation.AmountApplied__c > 0 && allocation.PaymentType__c != CustomerAPIConstants.ADJUSTMENT_WRITE_OFF && allocation.ReceiptAcknowledgement__r.Status__c != Constants.LINK_SENT) {
                            receiptPaymentMode += String.isNotBlank(receiptPaymentMode) && receiptPaymentMode.contains(allocation.PaymentType__c) ? '' : String.isNotBlank(receiptPaymentMode) ? ', ' + allocation.PaymentType__c : allocation.PaymentType__c;
                            isWireTransfer = isWireTransfer ? true : allocation.PaymentType__c == Constants.WIRE_TRANSFER ? true : false;
                          
                          
                            if (allocation.ReceiptAcknowledgement__r.ClearedDate__c != null && (outstandingAmount < bufferOutstandingAmount)&&(clearedDate == null || clearedDate <= allocation.ReceiptAcknowledgement__r.ClearedDate__c)) {
                                clearedDate = allocation.ReceiptAcknowledgement__r.ClearedDate__c;
                            }
                        }
                    }
                 
                    Boolean isDirectDebitRequest = directDebitRequestList.contains(installmentLine.SalesOrder__c) ? true : false;
                    String paymentMode = isDirectDebitRequest && !isWireTransfer ? CustomerAPIConstants.PAYMENT_MODE_DIRECT_DEBIT : '';
                    paymentMode = String.isNotBlank(paymentMode) && String.isNotBlank(receiptPaymentMode) && !receiptPaymentMode.contains(paymentMode) ? paymentMode + ', ' + receiptPaymentMode : String.isNotBlank(receiptPaymentMode) ? receiptPaymentMode : paymentMode;
                    
                    PaymentModel paymentModel = new PaymentModel(installmentLine, status, isDirectDebitRequest, paymentMode);
                    paymentModel.clearedDate = clearedDate;
                    if(installmentLine.PaymentInstallments__r.IsHandoverPayment__c == true && paymentModel.paymentDate == null){
                        paymentModel.paymentDate = installmentLine.SalesOrder__r.Unit__r.ExpectedCustomerHandoverDate__c;
                    }

                    paymentModel.isPayNow = paymentModel.isPayNow == true & lastPayNow == true && salesOrderId == installmentLine.SalesOrder__c ? false : paymentModel.isPayNow;
                    
                    if (clearedDate != null && installmentLine.InvoicedAmount__c > 0) {
                        paymentModel.paymentDetails.add(new KeyValueModel('Cleared Date', clearedDate, CustomerAPIConstants.DATA_TYPE_DATE));
                    }

                   // if(InstallmentMap.get(installmentLine.SalesOrder__c) != null && InstallmentMap.get(installmentLine.SalesOrder__c).size() == 1){
                    if(installmentLine.InstallmentNumber__c == 1  ){ 
                   // paymentModel.isPayNow = (!projectIds.isEmpty() && projectIds.contains(installmentLine.SalesOrder__r.Unit__r.Project__c)) ? paymentModel.isPayNow : (!buildingIds.isEmpty() && buildingIds.contains(installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__c)) ? paymentModel.isPayNow : false;
                    paymentModel.isPayNow = (!getProjectIds.isEmpty() && getProjectIds.contains(installmentLine.SalesOrder__r.Unit__r.Project__c)) ? paymentModel.isPayNow : (!getBuildingIds.isEmpty() && getBuildingIds.contains(installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__c)) ? paymentModel.isPayNow : false; // Added by Tajinkumar
                    }else{
                        paymentModel.isPayNow = false;
                    }
                    financialModel.paymentDetails.add(paymentModel);

                    lastPayNow = salesOrderId != installmentLine.SalesOrder__c ? paymentModel.isPayNow : lastPayNow == false && paymentModel.isPayNow == true ? true : lastPayNow;
                    salesOrderId = installmentLine.SalesOrder__c;
                    if (String.isNotBlank(status)) {
                        financialModel.paymentStatus.add(status);
                    }

                    financialModel.paymentType.add(installmentLine.InstallmentNumber__c == 1 ? CustomerAPIConstants.DOWN_PAYMENT : CustomerAPIConstants.INSTALLMENT_PAYMENT);
                }
            }
            // Added by Tajinkumar - LAC 2221
            Decimal amountReceived = 0;
            if(installmentLineList[0] != null && String.isNotBlank(salesOrderId)){
                for(AggregateResult  recAgg : [SELECT SUM(Amount__c)amountPaid FROM ReceiptAcknowledgement__c WHERE Status__c =: CustomerAPIConstants.PAYMENT_STATUS_RECEIVED AND SalesOrder__c =: salesOrderId]){
                    Decimal amountPaid = (Decimal) recAgg.get('amountPaid');
                    amountReceived = amountPaid != null ? amountPaid : 0;
                }
                financialModel.reservationAmount = installmentLineList[0]?.SalesOrder__r?.Unit__r?.Project__r?.ReservationAmount__c ?? 0;
                financialModel.paidReservationAmount = (amountReceived <= financialModel.reservationAmount) ? amountReceived : (amountReceived >= financialModel.reservationAmount) ? financialModel.reservationAmount : 0;
                financialModel.outstandingReservationAmount = (amountReceived >= financialModel.reservationAmount) ? 0 : (financialModel.reservationAmount - amountReceived); 
            }
         }

        //----- Populate Sales Order Other Charges details
        if (!otherChargeList.isEmpty()) {
            financialModel.filterUnitNo = String.isNotBlank(financialModel.filterUnitNo) ? financialModel.filterUnitNo : otherChargeList[0].SalesOrder__c;
            for (SalesOrderOtherCharges__c otherCharge: otherChargeList) {
                if(otherCharge.ReceiptAcknowledgement__c !='Not Applicable' ){
                    if((otherCharge.SalesOrder__r.Sales_Type__c !='AM Sale' || otherCharge.TypeOfCharge__c != 'ADM Fee' || Test.isRunningTest()) ){
                financialModel.unitNames.put(otherCharge.SalesOrder__r.UnitNumber__c, otherCharge.SalesOrder__c);
                
                String status = CustomerAPIConstants.PAYMENT_STATUS_IN_PROCESS;
                if (otherCharge.PendingAmount__c > bufferOutstandingAmount) {
                    status = CustomerAPIConstants.PAYMENT_STATUS_UNPAID;
                } else if (otherCharge.OutstandingAmount__c <= bufferOutstandingAmount) {
                    status = CustomerAPIConstants.PAYMENT_STATUS_CLEARED;
                }

				if (financialModel.filterUnitNo != CustomerAPIConstants.ALL && financialModel.filterUnitNo != otherCharge.SalesOrder__c) {
                    continue;
                }
                if (otherCharge.SalesOrder__r.Account__c != otherCharge.Account__c || otherCharge.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO || otherCharge.SubType__c == Constants.OTHER_CHARGES_SUB_TYPE_CUSTOMER_REFUND || otherCharge.SubType__c == Constants.OTHER_CHARGES_SUB_TYPE_REALLOCATED_AMOUNT || otherCharge.SubType__c == Constants.OTHER_CHARGES_SUB_TYPE_FORFEITURE_AMOUNT) {
                    continue;
                }

                if (String.isBlank(paymentStatus) || status == paymentStatus) {
                    Boolean isWireTransfer = false;
                    String receiptPaymentMode = '';
                    Date clearedDate = null;
                    List<ReceiptAllocation__c> allocationList = !otherCharge.ReceiptAllocations__r.isEmpty() ? otherCharge.ReceiptAllocations__r : !receiptMap.isEmpty() && receiptMap.containsKey(otherCharge.Id) ? receiptMap.get(otherCharge.Id) : new List<ReceiptAllocation__c>();
                    for (ReceiptAllocation__c allocation: allocationList) {
                        if (allocation.AmountApplied__c > 0 && allocation.PaymentType__c != CustomerAPIConstants.ADJUSTMENT_WRITE_OFF && allocation.ReceiptAcknowledgement__r.Status__c != Constants.LINK_SENT) {
                            receiptPaymentMode += String.isNotBlank(receiptPaymentMode) && receiptPaymentMode.contains(allocation.PaymentType__c) ? '' : String.isNotBlank(receiptPaymentMode) ? ', ' + allocation.PaymentType__c : allocation.PaymentType__c;
                            isWireTransfer = isWireTransfer ? true : allocation.PaymentType__c == Constants.WIRE_TRANSFER ? true : false;
                            if (allocation.ReceiptAcknowledgement__r.ClearedDate__c != null && (clearedDate == null || clearedDate <= allocation.ReceiptAcknowledgement__r.ClearedDate__c)) {
                                clearedDate = allocation.ReceiptAcknowledgement__r.ClearedDate__c;
                            }
                        }
                    }
                    
                    Boolean isDirectDebitRequest = directDebitRequestList.contains(otherCharge.SalesOrder__c) ? true : false;
                    String paymentMode = isDirectDebitRequest && !isWireTransfer ? CustomerAPIConstants.PAYMENT_MODE_DIRECT_DEBIT : '';
                    paymentMode = String.isNotBlank(paymentMode) && String.isNotBlank(receiptPaymentMode) && !receiptPaymentMode.contains(paymentMode) ? paymentMode + ', ' + receiptPaymentMode : String.isNotBlank(receiptPaymentMode) ? receiptPaymentMode : '';
                    
                    PaymentModel paymentModel = new PaymentModel(otherCharge, status, isDirectDebitRequest, paymentMode);
                    paymentModel.clearedDate = clearedDate;
                    if (clearedDate != null && otherCharge.InvoicedAmount__c > 0) {
                        paymentModel.paymentDetails.add(new KeyValueModel('Cleared Date', clearedDate, CustomerAPIConstants.DATA_TYPE_DATE));
                    }

                    paymentModel.isPayNow =  paymentModel.isPayNow;
                    //(!projectIds.isEmpty() && !projectIds.contains(otherCharge.SalesOrder__r.Unit__r.Project__c) )? false : (!buildingIds.isEmpty() && !buildingIds.contains(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__c)) ? false :
                    financialModel.paymentDetails.add(paymentModel);

                    if (String.isNotBlank(status)) {
                        financialModel.paymentStatus.add(status);
                    }
    
                    financialModel.paymentType.add(String.isNotBlank(otherCharge.SubType__c) ? otherCharge.SubType__c : otherCharge.TypeOfCharge__c == Constants.BUDGET_LINE_ADMADMINFEE ? Constants.BUDGET_LINE_ADMFEE : otherCharge.TypeOfCharge__c);
                }
            }
        }
    }
        }
        return financialModel;
    }
    
  public class FinancialModel{
        public List<PaymentModel> paymentDetails                        {get;set;}
        public Map<String, String> unitNames                            {get;set;}
        public Set<String> paymentType                                  {get;set;}
        public Set<String> paymentStatus                                {get;set;}
        public String filterUnitNo                                      {get;set;}
		// Added by neelesh
        public Boolean containsParking									{get;set;} 
        public List<parkingOrders> parkingOrders						{get;set;}
        // Added by Tajinkumar - LAC 2221
        public Decimal reservationAmount                                {get;set;}
        public Decimal paidReservationAmount                            {get;set;}
        public Decimal outstandingReservationAmount                     {get;set;}

        public FinancialModel() {
            this.paymentDetails = new List<PaymentModel>();
            this.unitNames = new Map<String, String>();
            this.paymentType = new Set<String>();
            this.paymentStatus = new Set<String>();
            this.filterUnitNo = '';
            this.parkingOrders = new List<parkingOrders>();
            this.containsParking = false;
            this.reservationAmount = 0;
            this.paidReservationAmount = 0;
            this.outstandingReservationAmount = 0;

        }
    }

    public class PaymentModel{
        public String referenceNumber                                   {get;set;}
        public String paymentId                                         {get;set;}
        public String salesOrderId                                      {get;set;}
        public String unitId                                            {get;set;}
        public String invoiceNo                                         {get;set;}
        public Date paymentDate                                         {get;set;}
        public Decimal delayDays                                        {get;set;}
        public Decimal totalAmount                                      {get;set;}
        public Decimal outstandingAmount                                {get;set;}
        public Decimal percentage                                       {get;set;}
        public String paymentType                                       {get;set;}
        public String paymentStatus                                     {get;set;}
        public String paymentMode                                       {get;set;}
        public Date clearedDate                                         {get;set;}
        public Decimal clearedAmount                                    {get;set;}
        public String description                                       {get;set;}
        public List<KeyValueModel> constructionDescription              {get;set;}
        public List<KeyValueModel> constructionDescriptionViewMore      {get;set;}
        public String salesOrderNo                                      {get;set;}
        public String complianceStatus                                  {get;set;}
        public String unitNo                                            {get;set;}
        public Boolean isHandoverPayment                                {get;set;}
        public Boolean isPayNow                                         {get;set;}
        public Boolean isDownloadReceipt                                {get;set;}
        public Boolean isAllowStopPayment                               {get;set;}
        public Boolean isInstallment                                    {get;set;}
        public List<KeyValueModel> paymentDetails                       {get;set;}
        public List<KeyValueModel> bankDetails                          {get;set;}

        public PaymentModel(InstallmentLines__c line, String status, Boolean isDirectDebitRequest, String paymentMode) {
            this.referenceNumber = line.Name;
            this.paymentId = line.Id;
            this.salesOrderId = line.SalesOrder__c;
            this.unitId = line.SalesOrder__r.Unit__c;
            this.invoiceNo = line.InvoiceNumber__c;
            this.paymentDate = line.PaymentInstallments__c != null && line.PaymentInstallments__r.IsHandoverPayment__c ? line.InstallmentPayoutDate__c : line.InstallmentDate__c;
            this.delayDays = line.PaymentInstallments__c != null ? line.PaymentInstallments__r.DelayDays__c : null;
            this.totalAmount = line.InstallmentAmount__c;
            this.outstandingAmount = line.OutstandingAmountToReceive__c > Decimal.valueOf(System.Label.BufferOutstandingAmount) ? line.OutstandingAmountToReceive__c : 0;
            this.percentage = line.InstallmentPercentage__c;
            this.clearedDate = null;
            this.clearedAmount = line.InvoicedAmount__c;
            this.paymentType = line.InstallmentNumber__c == 1 ? CustomerAPIConstants.DOWN_PAYMENT : CustomerAPIConstants.INSTALLMENT_PAYMENT + ' ' + line.InstallmentNumber__c;
            this.description = line.InstallmentNumber__c == 1 ? CustomerAPIConstants.DOWN_PAYMENT : CustomerAPIConstants.INSTALLMENT_PAYMENT + ' ' + line.InstallmentNumber__c;
            this.paymentStatus = status;
            this.paymentMode = paymentMode;
            this.salesOrderNo = line.SalesOrder__r.Name;
            this.complianceStatus = (line.SalesOrder__r.ComplianceStatus__c ==''||line.SalesOrder__r.ComplianceStatus__c ==null) && line.SalesOrder__r.Status__c =='Sold' ? 'Cleared' :line.SalesOrder__r.ComplianceStatus__c;
            this.unitNo = line.SalesOrder__r.UnitNumber__c;
            this.isHandoverPayment = line.PaymentInstallments__c != null ? line.PaymentInstallments__r.IsHandoverPayment__c : false;
            this.isPayNow = isDirectDebitRequest == true ? false : outstandingAmount > 0 && paymentDate != null ? true : false;
            //Added by Sarah for ASF- on Mar 11, 2024 - From here
            List<ReceiptAllocation__c> allocationList = !line.Receipt_Allocations__r.isEmpty() ? line.Receipt_Allocations__r : new List<ReceiptAllocation__c>();
            Boolean paidByCustomer = false;
            if(!allocationList.isEmpty()){
                for (ReceiptAllocation__c allocation: allocationList) {
                    if(allocation.Account__c == line.SalesOrder__r.Account__c ){
                        paidByCustomer = true;
                        break;
                    }
                }
            }
            this.isDownloadReceipt = status == CustomerAPIConstants.PAYMENT_STATUS_CLEARED || this.outstandingAmount == 0 ? paidByCustomer : false;
            /*if(!allocationList.isEmpty()){
                for (ReceiptAllocation__c allocation: allocationList) {
                    if(allocation.Account__r.PersonEmail.equalsIgnoreCase(UserInfo.getUserEmail())){
                        this.isDownloadReceipt = true;
                    } else {
                        this.isDownloadReceipt = status == CustomerAPIConstants.PAYMENT_STATUS_CLEARED || this.outstandingAmount == 0 ? true : false;
                    }
                }
            } else {
                this.isDownloadReceipt = status == CustomerAPIConstants.PAYMENT_STATUS_CLEARED || this.outstandingAmount == 0 ? true : false;
            }*/
            //Till here
            this.isInstallment = true;
            //this.isAllowStopPayment = !this.isDownloadReceipt && !this.isPayNow && line.SalesOrder__r.CollectionPercentage__c > 20 && line.OriginalInstallmentDate__c == null && (isDirectDebitRequest || paymentMode.containsIgnoreCase(Constants.CHEQUE)) && !line.IsStopPayment__c && paymentDate >= date.today().addDays(15) ? true : false; 
            this.isAllowStopPayment = false;
            this.constructionDescription = new List<KeyValueModel>();
            this.constructionDescription.add(new KeyValueModel('Amount', this.totalAmount, CustomerAPIConstants.DATA_TYPE_CURRENCY));
            this.constructionDescription.add(new KeyValueModel('Description',line.InstallmentPayoutDate__c != null && line.PaymentInstallments__r.IsHandoverPayment__c ?line.Description__c:(line.PaymentInstallments__r.IsHandoverPayment__c && this.paymentDate ==null ? 'Anticipated Handover':line.Description__c) , CustomerAPIConstants.DATA_TYPE_STRING));

            this.constructionDescriptionViewMore = new List<KeyValueModel>();
            this.constructionDescriptionViewMore.add(new KeyValueModel('Amount Pending', this.outstandingAmount, CustomerAPIConstants.DATA_TYPE_CURRENCY));
            if (line.OriginalInstallmentDate__c != null) {
                this.constructionDescriptionViewMore.add(new KeyValueModel('Original Date', line.OriginalInstallmentDate__c, CustomerAPIConstants.DATA_TYPE_DATE));
            }
            if (line.PaymentInstallments__c != null && String.isNotBlank(line.PaymentInstallments__r.DelayReason__c)) {
                this.constructionDescriptionViewMore.add(new KeyValueModel('Delay Reason', line.PaymentInstallments__r.DelayReason__c, CustomerAPIConstants.DATA_TYPE_STRING));
            }

            this.paymentDetails = new List<KeyValueModel>();
            this.paymentDetails.add(new KeyValueModel('Total Amount', this.totalAmount, CustomerAPIConstants.DATA_TYPE_CURRENCY));
            this.paymentDetails.add(new KeyValueModel('Installment Percentage', this.percentage, CustomerAPIConstants.DATA_TYPE_PERCENTAGE));
            this.paymentDetails.add(new KeyValueModel('Amount Paid', this.totalAmount - this.outstandingAmount, CustomerAPIConstants.DATA_TYPE_CURRENCY));
            if (this.paymentDate != null) {
                this.paymentDetails.add(new KeyValueModel('Due Date', this.paymentDate, CustomerAPIConstants.DATA_TYPE_DATE));
            }
            this.paymentDetails.add(new KeyValueModel('Total Amount Pending', this.outstandingAmount, CustomerAPIConstants.DATA_TYPE_CURRENCY));
            this.paymentDetails.add(new KeyValueModel('Description', this.description, CustomerAPIConstants.DATA_TYPE_STRING));
            if (String.isNotBlank(paymentMode)) {
                this.paymentDetails.add(new KeyValueModel('Mode of Payment', paymentMode, CustomerAPIConstants.DATA_TYPE_STRING));
            }
            if (line.InvoicedAmount__c > 0) {
                this.paymentDetails.add(new KeyValueModel('Cleared Amount', line.InvoicedAmount__c, CustomerAPIConstants.DATA_TYPE_CURRENCY));
            }

            this.bankDetails = new List<KeyValueModel>();
            if (line.SalesOrder__r.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c == null || line.SalesOrder__r.BookingDate__c < line.SalesOrder__r.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c) {
                this.bankDetails.add(new KeyValueModel('Beneficiary Name', (String.isNotBlank(line.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c) ? line.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c : line.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Bank Account Number', ((line.SalesOrder__r.Unit__r.VirtualAccountNumber__c !=null && String.isNotBlank(line.SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c)) ? line.SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c : (String.isNotBlank(line.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c) ? line.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c : line.SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c)), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Bank Name', (String.isNotBlank(line.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c) ? line.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c : line.SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Bank Branch', (String.isNotBlank(line.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c) ? line.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c : line.SalesOrder__r.Unit__r.Project__r.BranchEscrow__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('IBAN', ((line.SalesOrder__r.Unit__r.VirtualAccountNumber__c !=null && String.isNotBlank(line.SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c)) ? line.SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c : (String.isNotBlank(line.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c) ? line.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c : line.SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c)), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Swift Code', (String.isNotBlank(line.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c) ? line.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c : line.SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c)));
            }
            //----- If the Booking Date is on or after BCC date then Corporate of Building or Project to be used.
            else {
                this.bankDetails.add(new KeyValueModel('Beneficiary Name', (String.isNotBlank(line.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c) ? line.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c : line.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Bank Account Number', (String.isNotBlank(line.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c) ? line.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c : line.SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Bank Name', (String.isNotBlank(line.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameCorporate__c) ? line.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameCorporate__c : line.SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Bank Branch', (String.isNotBlank(line.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchCorporate__c) ? line.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchCorporate__c : line.SalesOrder__r.Unit__r.Project__r.BranchCorporate__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('IBAN', (String.isNotBlank(line.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoCorporate__c) ? line.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoCorporate__c : line.SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Swift Code', (String.isNotBlank(line.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c) ? line.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c : line.SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c), CustomerAPIConstants.DATA_TYPE_STRING));
            }
        }

        public PaymentModel(SalesOrderOtherCharges__c otherCharge, String status, Boolean isDirectDebitRequest, String paymentMode) {
            this.referenceNumber = otherCharge.Name;
            this.paymentId = otherCharge.Id;
            this.salesOrderId = otherCharge.SalesOrder__c;
            this.unitId = otherCharge.SalesOrder__r.Unit__c;
            this.invoiceNo = otherCharge.InvoiceNumber__c;
            this.paymentDate = Date.valueOf(otherCharge.CreatedDate);
            this.delayDays = null;
            this.totalAmount = otherCharge.Amount__c;
            this.outstandingAmount = otherCharge.PendingAmount__c > Decimal.valueOf(System.Label.BufferOutstandingAmount) ? otherCharge.PendingAmount__c : 0;
            this.percentage = 100;
            this.paymentType = String.isNotBlank(otherCharge.SubType__c) ? otherCharge.SubType__c : otherCharge.TypeOfCharge__c;
            this.clearedDate = null;
            this.clearedAmount = otherCharge.InvoicedAmount__c;
            this.description = String.isNotBlank(otherCharge.SubType__c) ? otherCharge.TypeOfCharge__c + ' - ' + otherCharge.SubType__c : otherCharge.TypeOfCharge__c;
            this.constructionDescription = new List<KeyValueModel>();
            this.constructionDescriptionViewMore = new List<KeyValueModel>();
            this.paymentStatus = status;
            this.paymentMode = paymentMode;
            this.salesOrderNo = otherCharge.SalesOrder__r.Name;
            this.unitNo = otherCharge.SalesOrder__r.UnitNumber__c;
            this.isHandoverPayment = false;
            this.isPayNow = isDirectDebitRequest == true ? false : outstandingAmount > 0 ? true : false;
            this.isDownloadReceipt = status == CustomerAPIConstants.PAYMENT_STATUS_CLEARED || this.outstandingAmount == 0 ? true : false;
            this.isInstallment = false;
            this.isAllowStopPayment = false;

            this.paymentDetails = new List<KeyValueModel>();
            this.paymentDetails.add(new KeyValueModel('Total Amount', this.totalAmount, CustomerAPIConstants.DATA_TYPE_CURRENCY));
            // this.paymentDetails.add(new KeyValueModel('Installment Percentage', this.percentage, CustomerAPIConstants.DATA_TYPE_PERCENTAGE));
            this.paymentDetails.add(new KeyValueModel('Amount Paid', this.totalAmount - this.outstandingAmount, CustomerAPIConstants.DATA_TYPE_CURRENCY));
            this.paymentDetails.add(new KeyValueModel('Due Date', this.paymentDate, CustomerAPIConstants.DATA_TYPE_DATE));
            this.paymentDetails.add(new KeyValueModel('Total Amount Pending', this.outstandingAmount, CustomerAPIConstants.DATA_TYPE_CURRENCY));
            this.paymentDetails.add(new KeyValueModel('Description', this.description, CustomerAPIConstants.DATA_TYPE_STRING));
            if (String.isNotBlank(paymentMode)) {
                this.paymentDetails.add(new KeyValueModel('Mode of Payment', paymentMode, CustomerAPIConstants.DATA_TYPE_STRING));
            }
            if (otherCharge.InvoicedAmount__c > 0) {
                this.paymentDetails.add(new KeyValueModel('Cleared Amount', otherCharge.InvoicedAmount__c, CustomerAPIConstants.DATA_TYPE_CURRENCY));
            }

            this.bankDetails = new List<KeyValueModel>();
            if (otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c == null || otherCharge.SalesOrder__r.BookingDate__c < otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c) {
                this.bankDetails.add(new KeyValueModel('Beneficiary Name', (String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c) ? otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c : otherCharge.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Bank Account Number', ((otherCharge.SalesOrder__r.Unit__r.VirtualAccountNumber__c !=null && String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c)) ? otherCharge.SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c : (String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c) ? otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c : otherCharge.SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c)), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Bank Name', (String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c) ? otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c : otherCharge.SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Bank Branch', (String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c) ? otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c : otherCharge.SalesOrder__r.Unit__r.Project__r.BranchEscrow__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('IBAN', ((otherCharge.SalesOrder__r.Unit__r.VirtualAccountNumber__c !=null && String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c)) ? otherCharge.SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c : (String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c) ? otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c : otherCharge.SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c)), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Swift Code', (String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c) ? otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c : otherCharge.SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c), CustomerAPIConstants.DATA_TYPE_STRING));
            }
            //----- If the Booking Date is on or after BCC date then Corporate of Building or Project to be used.
            else {
                this.bankDetails.add(new KeyValueModel('Beneficiary Name', (String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c) ? otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c : otherCharge.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Bank Account Number', (String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c) ? otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c : otherCharge.SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Bank Name', (String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameCorporate__c) ? otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameCorporate__c : otherCharge.SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Bank Branch', (String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchCorporate__c) ? otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchCorporate__c : otherCharge.SalesOrder__r.Unit__r.Project__r.BranchCorporate__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('IBAN', (String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoCorporate__c) ? otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoCorporate__c : otherCharge.SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c), CustomerAPIConstants.DATA_TYPE_STRING));
                this.bankDetails.add(new KeyValueModel('Swift Code', (String.isNotBlank(otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c) ? otherCharge.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c : otherCharge.SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c), CustomerAPIConstants.DATA_TYPE_STRING));
            }
        }
    }

    public class KeyValueModel {
        public String label                                 {get;set;}
        public Object value                                 {get;set;}
        public String type                                  {get;set;}
        
        public KeyValueModel(String label, Object value, String type) {
            this.label = label;
            this.value = value;
            this.type = type;
        }
        
        public KeyValueModel (String label, Object value) {
            this.label = label;
            this.value = value;
        }
    }
    
     // Added By neelesh
    public class parkingOrders {
        public String  parkingRefId 								{get; set;}
        public Decimal bayNumber 									{get; set;}
        public Decimal totalAmount 									{get; set;}
        public Decimal amountOutstanding 							{get; set;}
        public Decimal amountPaid 									{get; set;}
        public String unitNumber 									{get; set;}
        public String orderId 										{get; set;}
        public Date paymentDate 									{get; set;}
        public Boolean isDownloadReceipt 							{get; set;}
        public String PaymentStatus									{get; set;}
        public String PaymentType									{get; set;}
        public String PaymentMode									{get; set;}


        
        public parkingOrders(String parkingRefId, Decimal bayNumber, Decimal totalAmount, Decimal amountOutstanding, Decimal amountPaid, String unitNumber, String orderId, Date paymentDate, String orderPaymentStatus, String PaymentMode, String OrderpaymentType, Boolean isDownloadReceipt) {
            this.parkingRefId = parkingRefId;
            this.bayNumber = bayNumber;
            this.totalAmount = totalAmount;
            this.amountOutstanding = amountOutstanding;
            this.amountPaid = amountPaid;
 			this.unitNumber = unitNumber;
            this.orderId = orderId;
            this.paymentDate = paymentDate;
            this.PaymentStatus = orderPaymentStatus;
            this.PaymentMode = PaymentMode;
            this.PaymentType = OrderpaymentType;
            this.isDownloadReceipt = isDownloadReceipt;
        }
    }
}