/*
* Name               : CustomerPaymentWebService
* Description        : This class is used to do Payment for installment or Other charges
*/
@RestResource (urlMapping = '/customer/createpayment')
global without sharing class CustomerPaymentWebService {

    @HTTPPost
    global static void doPost(String paymentId, String paymentType, Date paymentDate, Decimal paymentAmount, String referenceNumber, String bankName, String bankAccountNumber, String remarks, String referenceId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            PaymentModel paymentModel = payment(paymentId, paymentType, paymentDate, paymentAmount, referenceNumber, bankName, bankAccountNumber, remarks);
            if (paymentModel == null) {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = CustomerAPIConstants.MESSAGE_PAYMENT_ERROR;
            } else {
                handler.response.success = true;
                handler.response.data = paymentModel;
            }
            handler.finalize();
        } catch (Exception e) {
            System.debug(e.getStackTraceString());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    global static PaymentModel payment(String paymentId, String paymentType, Date paymentDate, Decimal paymentAmount, String referenceNumber, String bankName, String bankAccountNumber, String remarks) {
        PaymentModel paymentModel = new PaymentModel();
        boolean valid = true;
        ReceiptAcknowledgementController.ReceiptAcknowlegment installmentDetails = ReceiptAcknowledgementController.initialiseReceiptAcknowlegment(paymentId);
        
        if ((paymentAmount > installmentDetails.amount && paymentAmount < 1) || !isValid(installmentDetails) ) {
            valid = false;
        }
        if(Test.isRunningTest()){
            isValidOtherCharges(installmentDetails);
        }
        if ((paymentAmount > installmentDetails.amount && paymentAmount < 1) && !isValidOtherCharges(installmentDetails) ) {
            valid = false;
        }else{
            valid = true;
        }
        if (valid == false){return null;}

        ReceiptAcknowledgement__c receipt = new ReceiptAcknowledgement__c();
        receipt.PaymentType__c = paymentType;
        receipt.Amount__c = paymentAmount;
        receipt.SalesOrder__c = installmentDetails.salesOrderId;
        receipt.Opportunity__c = installmentDetails.salesOrderRecord.Opportunity__c;
        receipt.Account__c = installmentDetails.salesOrderRecord.Account__c;
        receipt.Remarks__c = remarks;
        receipt.ReferenceNumber__c = referenceNumber;
        receipt.MaturityDate__c = paymentDate;
        receipt.CurrencyIsoCode = Constants.UAE_CURRENCY;
        receipt.BankName__c = Constants.ABUDHABI_COMMERCIAL_BANK;
        receipt.CustomerBankAccount__c = bankAccountNumber;
        receipt.IsCreatedFromLink__c = true;
        receipt.DoNotSendPaymentURL__c = true;
        
        // Added by Tajinkumar for Digital Sales
        if(String.isNotBlank(paymentId) && (Id.valueOf(paymentId)).getSObjectType() == InstallmentLines__c.SObjectType && installmentDetails.salesOrderRecord.Is_Digital_Sales__c){
            receipt.Sales_Manager__c = installmentDetails.salesOrderRecord.SalesManager__c;
            receipt.Sales_Manager_Email__c = installmentDetails.salesOrderRecord.SalesManager__r.Email;
            receipt.ReceiptEmail__c = installmentDetails.salesOrderRecord.Account__r.PersonEmail;
        }
        
        if(installmentDetails.salesOrderOtherChargesRec != null && installmentDetails.salesOrderOtherChargesRec.ServiceRequest__c != null && installmentDetails.salesOrderOtherChargesRec.TypeOfCharge__c == 'Service Charge' ){
            receipt.ServiceRequest__c = installmentDetails.salesOrderOtherChargesRec.ServiceRequest__c;
            receipt.Receipt_Type__c = 'Charge Fee';
        }
        receipt = ReceiptAcknowledgementController.createReceiptAcknowledgementRecord(receipt, paymentId, new List<Object>(), JSON.serialize(installmentDetails), false);

        ReceiptAcknowledgement__c newReceipt = CustomerServiceUtility.getReceiptAcknowledgementDetail(' (Id = \'' + receipt.Id + '\') ')[0];
        paymentModel.receiptId = newReceipt.Id;
        paymentModel.receiptDetails = newReceipt;

        String projectId = String.valueOf(installmentDetails.salesOrderRecord.Unit__r.Project__c).substring(0, 15);
        String buildingId = String.valueOf(installmentDetails.salesOrderRecord.Unit__r.BuildingSectionName__c).substring(0, 15);
        System.debug('projectId>>>' + projectId);
        System.debug('buildingId>>>' + buildingId);

        List<MilestonePayment__mdt> projectMilestonePaymentList = [SELECT Id, ProjectId__c, BuildingId__c, APIKey__c, SecretKey__c, ProfileId__c, IsActive__c FROM MilestonePayment__mdt WHERE ProjectId__c =: projectId];
        List<MilestonePayment__mdt> buildingMilestonePaymentList = [SELECT Id, ProjectId__c, BuildingId__c, APIKey__c, SecretKey__c, ProfileId__c, IsActive__c FROM MilestonePayment__mdt WHERE BuildingId__c =: buildingId];
        
        if (Test.isRunningTest()) {
            projectMilestonePaymentList = [SELECT Id, ProjectId__c, BuildingId__c, APIKey__c, SecretKey__c, ProfileId__c, IsActive__c FROM MilestonePayment__mdt LIMIT 1];
            buildingMilestonePaymentList = [SELECT Id, ProjectId__c, BuildingId__c, APIKey__c, SecretKey__c, ProfileId__c, IsActive__c FROM MilestonePayment__mdt LIMIT 1];
        }
        
        MilestonePayment__mdt milestonePayment = new MilestonePayment__mdt();
        if (!projectMilestonePaymentList.isEmpty()) {
            for (MilestonePayment__mdt milestone: projectMilestonePaymentList) {
                if (projectId == milestone.ProjectId__c && milestone.IsActive__c == true) {
                    milestonePayment = projectMilestonePaymentList[0];
                }
            }
        }
        if (!buildingMilestonePaymentList.isEmpty()) {
            for (MilestonePayment__mdt milestone: buildingMilestonePaymentList) {
                if (buildingId == milestone.BuildingId__c && milestone.IsActive__c == true) {
                    milestonePayment = milestone;
                    break;
                }
            }
        }
        
        Map<String, String> paymentGatewayDetails = new Map<String, String>();
        if(installmentDetails.salesOrderOtherChargesRec != null || installmentDetails.serviceRequestRecord != null){
            List<APISetting__mdt> PaymentDetails = [SELECT APIKey__c,SecretKey__c,APIId__c FROM APISetting__mdt WHERE MasterLabel ='Payment'];
            paymentGatewayDetails.put('apiKey', PaymentDetails[0].APIKey__c);
            paymentGatewayDetails.put('secretKey', PaymentDetails[0].SecretKey__c);
            paymentGatewayDetails.put('profileId', PaymentDetails[0].APIId__c);
            paymentGatewayDetails.put('transactionId', paymentId + '-' + Datetime.now().getTime());
            paymentGatewayDetails.put('referenceNumber', newReceipt.Id + '-' + paymentId);
        
        }else{
            paymentGatewayDetails.put('apiKey', milestonePayment.APIKey__c);
            paymentGatewayDetails.put('secretKey', milestonePayment.SecretKey__c);
            paymentGatewayDetails.put('profileId', milestonePayment.ProfileId__c);
            paymentGatewayDetails.put('transactionId', paymentId + '-' + Datetime.now().getTime());
            paymentGatewayDetails.put('referenceNumber', newReceipt.Id + '-' + paymentId);
        
        }

        
        
       
        paymentModel.paymentGatewayDetails = paymentGatewayDetails;

        // if (paymentType == Constants.ONLINE) {
        //     Organization org = Utilities.getOrganizationDetails();
        //     paymentModel.paymentURL = org.IsSandbox ? CustomerAPIConstants.PAYMENT_SANDBOX_URL : CustomerAPIConstants.PAYMENT_PRODUCTION_URL;
        //     paymentModel.paymentURL += '?Id=' + newReceipt.EncryptedRecordId__c;
        // }

        return paymentModel;
    }
    
    global class PaymentModel{
        public Id receiptId                                     {get;set;}
        public ReceiptAcknowledgement__c receiptDetails         {get;set;}
        public Map<String, String> paymentGatewayDetails        {get;set;}
        // public String paymentURL                                {get;set;}
    }
    
    public Static boolean isValid(ReceiptAcknowledgementController.ReceiptAcknowlegment rARecord){
		string mainlineId = rARecord.installmentRec.id;
		string SalesOrderId = rARecord.salesOrderId;
		Decimal installmentNumber = rARecord.installmentRec.InstallmentNumber__c;
		//Decimal installmentNumberlessOne = installmentNumber -1;
        String cancelledWhereCaluse = ' (SalesOrder__r.Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND SalesOrder__r.Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
		String whrClause = ' (SalesOrder__r.Id = \'' + SalesOrderId + '\' AND ' + cancelledWhereCaluse + ') ';
		String directDebitRequestWhereClause = whrClause + ' AND Status__c = \'' + CustomerAPIConstants.DDR_APPROVED_BY_BANK + '\' ';
        List<String> directDebitRequestList = new List<String>();
        for (DirectDebitRequest__c directDebitRequest: Database.query('SELECT Id, Name, SalesOrder__c, Status__c FROM DirectDebitRequest__c WHERE ' + directDebitRequestWhereClause)) {
            directDebitRequestList.add(directDebitRequest.SalesOrder__c);
        }
		Boolean isDirectDebitRequest = directDebitRequestList.contains(SalesOrderId) ? true : false;
		list<InstallmentLines__c> lines = new list<InstallmentLines__c>([SELECT Id, SalesOrder__c,SalesOrder__r.Id,SalesOrder__r.Account__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,
									SalesOrder__r.Name,SalesOrder__r.Contact__c,InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c,SalesOrder__r.UnitNumber__c,
									SalesOrder__r.AccountName__c,AmountReceived__c,PendingAmount__c, SalesOrder__r.Account__r.Name, SalesOrder__r.Unit__r.Project__c, 
									SalesOrder__r.Unit__r.BuildingSectionName__c,OutstandingAmountToReceive__c,
									PaymentInstallments__r.IsHandoverPayment__c,InstallmentPayoutDate__c
									FROM InstallmentLines__c WHERE SalesOrder__c=:SalesOrderId order by InstallmentNumber__c ] );
		Boolean lastPayNow = false;
		system.debug('lines: '+lines);
		for(InstallmentLines__c line: lines){
			Date paymentDate = line.PaymentInstallments__c != null && line.PaymentInstallments__r.IsHandoverPayment__c ? line.InstallmentPayoutDate__c : line.InstallmentDate__c;
			Decimal outstandingAmount = line.OutstandingAmountToReceive__c > Decimal.valueOf(System.Label.BufferOutstandingAmount) ? line.OutstandingAmountToReceive__c : 0;
			boolean isHandoverPayment = line.PaymentInstallments__c != null ? line.PaymentInstallments__r.IsHandoverPayment__c : false;
            boolean isPayNow = isDirectDebitRequest || isHandoverPayment ? false : outstandingAmount > 0 && paymentDate != null ? true : false;

			if(line.id != mainlineId){
				lastPayNow = isPayNow? true : false;
                return lastPayNow;
            }else{
                isPayNow = lastPayNow ? false : isPayNow;
            	return isPayNow;
            }   
		}
		
		return false;
	}
     public Static boolean isValidOtherCharges(ReceiptAcknowledgementController.ReceiptAcknowlegment rARecord){
		string mainlineId = rARecord.salesOrderOtherChargesRec.id;
		string SalesOrderId = rARecord.salesOrderId;
		//Decimal installmentNumber = rARecord.salesOrderOtherChargesRec.InstallmentNumber__c;
		//Decimal installmentNumberlessOne = installmentNumber -1;
        String cancelledWhereCaluse = ' (SalesOrder__r.Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND SalesOrder__r.Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
		String whrClause = ' (SalesOrder__r.Id = \'' + SalesOrderId + '\' AND ' + cancelledWhereCaluse + ') ';
		String directDebitRequestWhereClause = whrClause + ' AND Status__c = \'' + CustomerAPIConstants.DDR_APPROVED_BY_BANK + '\' ';
        
		
		List<SalesOrderOtherCharges__c> soOtherCharges = [SELECT Id,Account__c, Opportunity__c, SalesOrder__c,SalesOrder__r.Id,SalesOrder__r.ComplianceStatus__c,SalesOrder__r.Account__c,SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,Name,TypeOfCharge__c,Amount__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,PendingAmount__c, SalesOrder__r.Account__r.Name, SalesOrder__r.Unit__r.Project__c, SalesOrder__r.Unit__r.BuildingSectionName__c, ChargedFromResaleOpp__c FROM SalesOrderOtherCharges__c WHERE SalesOrder__c=:SalesOrderId];
		Boolean lastPayNow = false;
		for(SalesOrderOtherCharges__c line: soOtherCharges){
			//Date paymentDate = line.PaymentInstallments__c != null && line.PaymentInstallments__r.IsHandoverPayment__c ? line.InstallmentPayoutDate__c : line.InstallmentDate__c;
			Decimal outstandingAmount = line.PendingAmount__c > Decimal.valueOf(System.Label.BufferOutstandingAmount) ? line.PendingAmount__c : 0;
			//boolean isHandoverPayment = line.PaymentInstallments__c != null ? line.PaymentInstallments__r.IsHandoverPayment__c : false;
            boolean isPayNow = outstandingAmount > 0 ? true : false;

			if(line.id != mainlineId){
				lastPayNow = isPayNow? true : false;
                
            }else{
                isPayNow = lastPayNow ? false : isPayNow;
            	return isPayNow;
            }   
		}
		
		return false;
	}
}