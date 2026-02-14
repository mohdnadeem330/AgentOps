@RestResource (urlMapping = '/query/salesorderdetails')
global with sharing class SalesOrderWebservice {
    //without - Commenting for deployment
    @HTTPPost
    global static void doPost(Id orderId){
        
        RestContextHandler handler = new RestContextHandler(true);
        SalesOrderModel salesOrderModel = new SalesOrderModel();
        try {            
            List<Id> soIdList = new List<Id>();
            soIdList.add(orderId);            
            List<SalesOrder__c> salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(soIdList);
            
            SalesOrder__c salesOrderRecord = salesOrder[0];
            Id accountId = salesOrderRecord.Account__r.id;
            Id currentUserId = UserInfo.getUserId();

            List<Account> accountRecord = [SELECT id,Name,
                                           NationalIdNumber__pc,
                                           IsPersonAccount,
                                           PassportNumber__pc,
                                           (SELECT id,Account__c,Account__r.Name, 
                                            RelatedAccount__c,RelationshipType__c, 
                                            Account__r.RegistrationNumber__c,
                                            RelatedAccount__r.RegistrationNumber__c,
                                            RelatedAccount__r.Name,
                                            RelatedAccount__r.NationalIdNumber__pc,
                                            RelatedAccount__r.PassportNumber__pc,
                                            RelatedAccount__r.IsPersonAccount  
                                            FROM AccountRelationships__r)
                                           FROM Account WHERE Id =: accountId];
        
            Map<Id, Account> ddr_payerAccountsMap	= new Map<Id, Account>();
            ddr_payerAccountsMap.put(salesOrderRecord.Account__r.id, salesOrderRecord.Account__r);
            if(salesOrderRecord.Payment_Type__c == 'Direct Debit'){
                salesOrderModel.showOptOutDDR = true;
            }
            if(salesOrderRecord.SignatureType__c == 'Digital Signature'){
                salesOrderModel.physicalSignatureApproval = true;
            }
            salesOrderModel.SignatureChangeApprovalStatus = salesOrderRecord.SignatureChangeApprovalStatus__c != null ? salesOrderRecord.SignatureChangeApprovalStatus__c : '';
            
            if(accountRecord.size() > 0){
                salesOrderModel.accountRelationships = accountRecord[0].AccountRelationships__r;
                for(AccountRelationship__c accRel : accountRecord[0].AccountRelationships__r){
                    ddr_payerAccountsMap.put(accRel.RelatedAccount__r.Id, accRel.RelatedAccount__r);
                }
            }
            if(ddr_payerAccountsMap != null && !ddr_payerAccountsMap.isEmpty()){
                for(Account indvAccount: ddr_payerAccountsMap.values()){
                    if(indvAccount.IsPersonAccount){
                        salesOrderModel.ddr_payerAccounts.add(new PayerAccountRecords(indvAccount.Id, indvAccount.Name, (indvAccount.NationalIdNumber__pc != ''? indvAccount.NationalIdNumber__pc: ''), (indvAccount.PassportNumber__pc != '' ? indvAccount.PassportNumber__pc: ''), '', indvAccount.IsPersonAccount  )); 
                    }else{
                        salesOrderModel.ddr_payerAccounts.add(new PayerAccountRecords(indvAccount.Id, indvAccount.Name, '','', indvAccount.RegistrationNumber__c , indvAccount.IsPersonAccount )); 
                    }
                   // String CustomerIdNumber = indvAccount.IsPersonAccount ? indvAccount.NationalIdNumber__pc : indvAccount.RegistrationNumber__c;
                   
                }
            }
            
            Map<Id,Document__c> documentDetailMap = new Map<Id,Document__c> (salesOrder[0].Documents__r); 
            Map<Id,Document__c> ddr_documentDetailMap = new Map<Id,Document__c> (SalesOrderService.getAllActiveDirectDebitRequests(salesOrder[0].Id));
            Map<Id,DocumentQueryModel> documentData = new Map<Id,DocumentQueryModel>();
            Map<Id,DocumentQueryModel> ddr_documentData = new Map<Id,DocumentQueryModel>();
           
            if(documentDetailMap != null && !documentDetailMap.isEmpty())
                documentData =  DocumentService.getDocumentDetails(documentDetailMap);

            if(ddr_documentDetailMap != null && !ddr_documentDetailMap.isEmpty()){
               ddr_documentData = DocumentService.getDocumentDetails(ddr_documentDetailMap);
            }
            String orderDate = salesOrderRecord.BookingDate__c != null ? DateTime.newInstance( salesOrderRecord.BookingDate__c.year(), salesOrderRecord.BookingDate__c.month(),salesOrderRecord.BookingDate__c.day()).format('dd MMM YYYY') : '';             
            String customerSignedSPADate = salesOrderRecord.CustomerSignedSPADate__c != null ? DateTime.newInstance( salesOrderRecord.CustomerSignedSPADate__c.year(), salesOrderRecord.CustomerSignedSPADate__c.month(),salesOrderRecord.CustomerSignedSPADate__c.day()).format('dd MMM YYYY') : ''; 
            String reservationEndDate = salesOrderRecord.ReservationEnddate__c != null ? DateTime.newInstance( salesOrderRecord.ReservationEnddate__c.year(), salesOrderRecord.ReservationEnddate__c.month(),salesOrderRecord.ReservationEnddate__c.day()).format('dd MMM YYYY') : ''; 
            String reservationStartDate = salesOrderRecord.ReservationStartDate__c != null ? DateTime.newInstance( salesOrderRecord.ReservationStartDate__c.year(), salesOrderRecord.ReservationStartDate__c.month(),salesOrderRecord.ReservationStartDate__c.day()).format('dd MMM YYYY') : ''; 
                
            salesOrderModel.orderDetails.add(new salesOrderRecord('Customer Name', salesOrderRecord.Account__r.Name));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Order Number', salesOrderRecord.Name));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Order Date', orderDate));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Status', salesOrderRecord.Status__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Sub Status', salesOrderRecord.SubStatus__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Opportunity Number', salesOrderRecord.OpportunityNumber__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Unit', salesOrderRecord.Unit__r.Name));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Unit Area', salesOrderRecord.unit__r.TotalArea__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Payment Plan', salesOrderRecord.PaymentPlan__r.Name));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Offer', salesOrderRecord.OfferName__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Project Budget', salesOrderRecord.ProjectBudget__r.Name));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Inventory Launch', salesOrderRecord.InventoryLaunch__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Sub Status Remarks', salesOrderRecord.SubStatusRemarks__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Owner', salesOrderRecord.Owner.Name));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Account', salesOrderRecord.Account__r.Name));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Legal Submission Reason', salesOrderRecord.LegalSubmissionReason__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Sales Admin Rejection Reason', salesOrderRecord.SalesAdminRejectionReason__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Owner Share Percentage', salesOrderRecord.OwnerSharePercentage__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Sales Manager', salesOrderRecord.SalesManagerName__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Customer Signed the SPA', salesOrderRecord.CustomerSPASigned__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Customer Signed SPA Date', customerSignedSPADate));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Booking Date', orderDate));            
            salesOrderModel.orderDetails.add(new salesOrderRecord('Unit Building', salesOrderRecord.UnitBuilding__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Unit Plot Number', salesOrderRecord.UnitPlotNumber__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Broker Agency Name', salesOrderRecord.Opportunity__r.BrokerAgencyAccount__r.Name));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Broker Agent Name', salesOrderRecord.Opportunity__r.BrokerAgentContact__r.Name));
           // Commented by Arvind 
            //salesOrderModel.orderDetails.add(new salesOrderRecord('Finance Comments', salesOrderRecord.FinanceComments__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Etihad Guest Miles', salesOrderRecord.Etihad_Guest_Miles__c));
            salesOrderModel.orderDetails.add(new salesOrderRecord('Signature Type', salesOrderRecord.SignatureType__c));
//            salesOrderModel.orderDetails.add(new salesOrderRecord('POD Choosen', 'Kitchen')); Commented by Muzammil fro DDS deployment
                       
            salesOrderModel.amountDetails.add(new salesOrderRecord('Selling Price', String.valueOf(salesOrderRecord.SellingPrice__c) != null ? String.valueOf(salesOrderRecord.SellingPrice__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.SellingPrice__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Discount', String.valueOf(salesOrderRecord.Discount__c) != null ? String.valueOf(salesOrderRecord.Discount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.Discount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Net Amount', String.valueOf(salesOrderRecord.NetAmount__c) != null ? String.valueOf(salesOrderRecord.NetAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.NetAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Corporate Discount', String.valueOf(salesOrderRecord.CorporateDiscount__c) != null ? String.valueOf(salesOrderRecord.CorporateDiscount__c.format()) : String.valueOf(salesOrderRecord.CorporateDiscount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('DARNA Amount', String.valueOf(salesOrderRecord.DARNAAmount__c) != null ? String.valueOf(salesOrderRecord.DARNAAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.DARNAAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Taxable Amount', String.valueOf(salesOrderRecord.TaxableAmount__c) != null ? String.valueOf(salesOrderRecord.TaxableAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.TaxableAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Bulk Discount', String.valueOf(salesOrderRecord.BulkDiscount__c) != null ? String.valueOf(salesOrderRecord.BulkDiscount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.BulkDiscount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Last Inst. Amt', String.valueOf(salesOrderRecord.LastInstallmentRebate__c) != null ? String.valueOf(salesOrderRecord.LastInstallmentRebate__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.LastInstallmentRebate__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Amount Payable', String.valueOf(salesOrderRecord.AmountPayable__c) != null ? String.valueOf(salesOrderRecord.AmountPayable__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.AmountPayable__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Multi Purpose Room', salesOrderRecord.MultiPurposeRoom__c));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Premium Amount', String.valueOf(salesOrderRecord.PremiumAmount__c) != null ? String.valueOf(salesOrderRecord.PremiumAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.PremiumAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Tax Amount', String.valueOf(salesOrderRecord.TaxableAmount__c) != null ? String.valueOf(salesOrderRecord.TaxableAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.TaxableAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Multi Purpose Amount', String.valueOf(salesOrderRecord.MultiPurposeAmount__c) != null ? String.valueOf(salesOrderRecord.MultiPurposeAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.MultiPurposeAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Other Rebate Amount', String.valueOf(salesOrderRecord.OtherRebateAmount__c) != null ? String.valueOf(salesOrderRecord.OtherRebateAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.OtherRebateAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Appliances rebate Amount', String.valueOf(salesOrderRecord.AppliancesRebateAmount__c) != null ? String.valueOf(salesOrderRecord.AppliancesRebateAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.AppliancesRebateAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Home Maintenance Waived Amount', String.valueOf(salesOrderRecord.HomeMaintenanceWaivedAmount__c) != null ? String.valueOf(salesOrderRecord.HomeMaintenanceWaivedAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.HomeMaintenanceWaivedAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Other sales Support Amount', String.valueOf(salesOrderRecord.OtherSalesSupportAmount__c) != null ? String.valueOf(salesOrderRecord.OtherSalesSupportAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.OtherSalesSupportAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Internal Commission Amount', String.valueOf(salesOrderRecord.InternalCommissionAmount__c) != null ? String.valueOf(salesOrderRecord.InternalCommissionAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.InternalCommissionAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('External Commission Amount', String.valueOf(salesOrderRecord.ExternalCommissionAmount__c) != null ? String.valueOf(salesOrderRecord.ExternalCommissionAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.ExternalCommissionAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('PHPP Amount', String.valueOf(salesOrderRecord.PHPPAmount__c) != null ? String.valueOf(salesOrderRecord.PHPPAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.PHPPAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Diff Net Amount', String.valueOf(salesOrderRecord.DiffNetAmount__c) != null ? String.valueOf(salesOrderRecord.DiffNetAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.DiffNetAmount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Net Amount in Words', salesOrderRecord.NetAmountInWords__c));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Wealth Discount', String.valueOf(salesOrderRecord.WealthDiscount__c) != null ? String.valueOf(salesOrderRecord.WealthDiscount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.WealthDiscount__c)));
            salesOrderModel.amountDetails.add(new salesOrderRecord('Payment Plan Discount', String.valueOf(salesOrderRecord.PaymentPlanDiscount__c) != null ? String.valueOf(salesOrderRecord.PaymentPlanDiscount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.PaymentPlanDiscount__c)));

            salesOrderModel.additionalDetails.add(new salesOrderRecord('Corporate Partner', salesOrderRecord.Account__r.CorporateWealthName__c));
            salesOrderModel.additionalDetails.add(new salesOrderRecord('Subsidy Type', salesOrderRecord.SubsidyType__c));
            salesOrderModel.additionalDetails.add(new salesOrderRecord('ADM Fee Amount', String.valueOf(salesOrderRecord.ADMFeeAmount__c) != null ? String.valueOf(salesOrderRecord.ADMFeeAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.ADMFeeAmount__c)));
            salesOrderModel.additionalDetails.add(new salesOrderRecord('Originally Selling Price', String.valueOf(salesOrderRecord.RTOOriginalSellingPrice__c) != null ? String.valueOf(salesOrderRecord.RTOOriginalSellingPrice__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.RTOOriginalSellingPrice__c)));
            salesOrderModel.additionalDetails.add(new salesOrderRecord('Subsidy Amount', String.valueOf(salesOrderRecord.SubsidyAmount__c) != null ? String.valueOf(salesOrderRecord.SubsidyAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.SubsidyAmount__c)));
            salesOrderModel.additionalDetails.add(new salesOrderRecord('ADM Fee Waived Amount', String.valueOf(salesOrderRecord.ADMFeeWaivedAmount__c) != null ? String.valueOf(salesOrderRecord.ADMFeeWaivedAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.ADMFeeWaivedAmount__c)));            
            salesOrderModel.additionalDetails.add(new salesOrderRecord('SC Waived Years', salesOrderRecord.ServiceChargeWaivedYears__c));
            salesOrderModel.additionalDetails.add(new salesOrderRecord('Remarks', salesOrderRecord.Remarks__c));
            salesOrderModel.additionalDetails.add(new salesOrderRecord('Security Deposit', String.valueOf(salesOrderRecord.SecurityDeposit__c) != null ? String.valueOf(salesOrderRecord.SecurityDeposit__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.SecurityDeposit__c)));            
            salesOrderModel.additionalDetails.add(new salesOrderRecord('Unit Finishing', salesOrderRecord.UnitFinishing__c)); 
            salesOrderModel.additionalDetails.add(new salesOrderRecord('Unit floor', salesOrderRecord.UnitFloor__c));          
            salesOrderModel.additionalDetails.add(new salesOrderRecord('SC Waived Amount', String.valueOf(salesOrderRecord.ServiceChargeWaivedAmount__c) != null ? String.valueOf(salesOrderRecord.ServiceChargeWaivedAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.ServiceChargeWaivedAmount__c)));
            salesOrderModel.additionalDetails.add(new salesOrderRecord('Unit Type', salesOrderRecord.UnitType__c));
            salesOrderModel.additionalDetails.add(new salesOrderRecord('Payment Term Discount', String.valueOf(salesOrderRecord.PaymentPlanDiscount__c) != null ? String.valueOf(salesOrderRecord.PaymentPlanDiscount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.PaymentPlanDiscount__c)));//na
            salesOrderModel.additionalDetails.add(new salesOrderRecord('ADM Fee Percentage', salesOrderRecord.ADMPercentage__c));

            salesOrderModel.additionalDetails.add(new salesOrderRecord('Unit Furnishing', salesOrderRecord.UnitFurnishing__c));
            salesOrderModel.additionalDetails.add(new salesOrderRecord('Unit Finishing', salesOrderRecord.UnitFinishing__c));
            salesOrderModel.additionalDetails.add(new salesOrderRecord('Design Type', salesOrderRecord.DesignType__c));
            
            salesOrderModel.reservationDetails.add((new salesOrderRecord('Reservation Amount', salesOrderRecord.ReservationAmountType__c)));
            salesOrderModel.reservationDetails.add((new salesOrderRecord('Reservation Amount Type', String.valueOf(salesOrderRecord.RAcknowledgementReservationAmount__c) != null ?String.valueOf(salesOrderRecord.RAcknowledgementReservationAmount__c.format()) + ' ' + salesOrderRecord.CurrencyIsoCode : String.valueOf(salesOrderRecord.RAcknowledgementReservationAmount__c))));
            salesOrderModel.reservationDetails.add((new salesOrderRecord('Reservation End Date', reservationEndDate)));
            salesOrderModel.reservationDetails.add((new salesOrderRecord('Reservation Start Date', reservationStartDate)));
            
            if(String.isNotBlank(salesOrderRecord.OpportunityEOI__c) || salesOrderRecord.OpportunityEOI__c != null)
                salesOrderModel.orderDetails.add((new salesOrderRecord('Opportunity EOI Number', salesOrderRecord.OpportunityEOI__r.Name)));

            if(String.isBlank(salesOrderRecord.SpecialConditionApplicable__c) || salesOrderRecord.SpecialConditionApprovalStatus__c != 'Submitted')
                salesOrderModel.isSpecialConditionUpdateable = true;
          
            if(salesOrderRecord.Status__c == 'Reserved' && salesOrderRecord.Opportunity__r.ReservationApprovalStatus__c  == 'Approved'){
                salesOrderModel.reservationToBookingFlag = TRUE;
            }                           

            if(salesOrderRecord.Opportunity__r.CustomerResidentStatus__c != Constants.RESIDENTSTATUS_RESIDENT){
                salesOrderModel.ICArequired = true ;
            }

            salesOrderModel.ddr_CustomerIdNumber_default = salesOrderRecord.Account__r.IsPersonAccount? salesOrderRecord.AccountNationalityIDNumber__c : salesOrderRecord.Account__r.RegistrationNumber__c;
            salesOrderModel.ddr_CustomerIdType_default = salesOrderRecord.Account__r.IsPersonAccount ? 'UAE Emirates Identity Card' : 'Trade Licence Number';

            salesOrderModel.salesOrderCancellation = SalesOrderService.getSalesOrderCancellation(orderId) ;

            if((salesOrderRecord.Status__c != Constants.STATUS_APPROVAL_PENDING || salesOrderRecord.Status__c != Constants.OPPO_UNIT_STATUS_PENDING) && salesOrderModel.salesOrderCancellation.size() < 1){
                salesOrderModel.isEligibleForCancellation = true ;
                Schema.DescribeFieldResult reasonForCancellation = SalesOrderCancellation__c.ReasonforCancellation__c.getDescribe();
                for(Schema.PicklistEntry picklist: reasonForCancellation.getPicklistValues()){
                    salesOrderModel.cancellationReasons.add(picklist.getValue());
                }
                salesOrderModel.salesAdminUsers = UserService.getUsersByRoleName(Constants.ROLE_SALES_ADMIN);
            }

            salesOrderModel.salesOrderRecordDetail = salesOrderRecord;
            salesOrderModel.jointOwner = salesOrderRecord.Joint_OwnersSalesOrder__r;
            salesOrderModel.installment = salesOrderRecord.InstallmentLines__r;
            salesOrderModel.otherCharges = salesOrderRecord.SalesOrdersOtherCharges__r;
            salesOrderModel.commissionLines = salesOrderRecord.CommissionLineItems__r;
            salesOrderModel.directDebitRequests = salesOrderRecord.Direct_Debit_Request__r;// Added by Sanath H M,  Date: 12.12.2022
            
            if(salesOrderRecord.OwnerId == currentUserId)
                salesOrderModel.isSubStatusUpdateable = true;

            List<Map<String,String>> statusMap = SalesOrderSubStatusController.getApplicableSubStatus(salesOrderRecord.Id); 
            Set<String> subStatusSet = new Set<String>();
           
            for(Map<String,String> strMap : statusMap){
                subStatusSet.addAll(strMap.values());   
            }
                    
            salesOrderModel.subStatus = subStatusSet;
            salesOrderModel.receiptAcknowledgements = salesOrderRecord.Payments__r;
            salesOrderModel.documents = documentData.values();  
            salesOrderModel.ddr_documents = ddr_documentData.values(); 
            if(salesOrderRecord.Unit__r.Project__r.BankNameEscrow__c != Null && salesOrderRecord.Unit__r.Project__r.DirectDebitApplied__c){  //changed from OIC check to BankNameEscrow
               salesOrderModel.ddr_showNewButton = true;
            } 
           Schema.DescribeFieldResult fieldResult = SalesOrder__c.CurrencyIsoCode.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            Map<String,String> currencyList = new Map<String,String>();
            
            for( Schema.PicklistEntry pickListVal : ple){
                salesOrderModel.currencyValues.add(new salesOrderRecord(pickListVal.getLabel(), pickListVal.getValue()));
              
            }

           // salesOrderModel.winReasonValues = winReasonSet;

            Schema.DescribeFieldResult winReasonFieldResult = Opportunity.WinReason__c.getDescribe();
                for(Schema.PicklistEntry picklist: winReasonFieldResult.getPicklistValues()){
                    salesOrderModel.winReasonValues.add(picklist.getValue());
                }
            
            //Added By Tharun for SPA Signature - 02/02/2023
            Schema.DescribeFieldResult spaSigTypeFieldResult = SalesOrder__c.SignatureType__c.getDescribe();
                for(Schema.PicklistEntry picklist: spaSigTypeFieldResult.getPicklistValues()){
                    salesOrderModel.spaSignatureTypeValues.add(picklist.getValue());
                }
            //Digital to physical signature changes

            Schema.DescribeFieldResult digitalToPhysicalChangeReasons  = SalesOrder__c.SPASignaturetypechangereasonpicklist__c.getDescribe();

            for(Schema.PicklistEntry picklist: digitalToPhysicalChangeReasons.getPicklistValues()){

                salesOrderModel.digitalToPhysicalChangeReasons.add(picklist.getValue());

            }
            ConfigurationsWebService.ConfigurationsResponse response = new ConfigurationsWebService.ConfigurationsResponse();
            salesOrderModel.paymentMode = ConfigurationsWebService.getpaymentType(response);
            salesOrderModel.ddr_CustomerBankNames = ConfigurationsWebService.getDDRCustomerBankNames(response);    
            salesOrderModel.ddr_CustomerBankAccountTypes = ConfigurationsWebService.getDDRCustomerBankActTypes(response);
            salesOrderModel.ddr_CustomerIdTypes = salesOrderRecord.Account__r.IsPersonAccount ? new List<String>{'Passport', 'UAE Emirates Identity Card'} :new List<String>{'Trade Licence Number'};
             
           handler.response.success = true;
            handler.response.data = salesOrderModel;
            handler.finalize();
            
        } catch (Exception e) {
            System.debug('msg '+ e.getMessage());
            System.debug('line no '+e.getLineNumber());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
            
        } 
    }
    
    global class SalesOrderModel {
        public List<SalesOrderRecord> orderDetails                          {get;set;}
        public List<SalesOrderRecord> amountDetails                         {get;set;}
        public List<SalesOrderRecord> additionalDetails                     {get;set;}
        public List<SalesOrderRecord> reservationDetails                    {get;set;}
        public SalesOrder__c salesOrderRecordDetail                         {get;set;}
        public Boolean isSpecialConditionUpdateable                         {get;set;}
        public Boolean reservationToBookingFlag                             {get;set;}
        public Boolean ICArequired                                          {get;set;}
        public List<JointOwner__c> jointOwner                               {get;set;}
        public List<InstallmentLines__c> installment                        {get;set;}
        public List<SalesOrderOtherCharges__c> otherCharges                 {get;set;}
        public List<CommissionLineItem__c> commissionLines                  {get;set;}
        public Boolean isSubStatusUpdateable                                {get;set;}
        public Set<String> subStatus                                        {get;set;}
        public List<ReceiptAcknowledgement__c> receiptAcknowledgements      {get;set;}
        public List<DocumentQueryModel> documents                           {get;set;} 
        public List<AccountRelationship__c> accountRelationships            {get;set;}
        public List<String> paymentMode                                     {get;set;}
        public List<SalesOrderRecord> currencyValues                        {get;set;}
        public Set<String> winReasonValues                                  {get;set;}
        public Set<String> spaSignatureTypeValues                           {get;set;} // Added by Tharun,      Date: 02.02.2023
		public List<DirectDebitRequest__c> directDebitRequests              {get;set;} // Added by Sanath H M,  Date: 12.12.2022	
        public List<String> ddr_CustomerBankNames                           {get;set;} // Added by Sanath H M,  Date: 13.12.2022	
        public List<DocumentQueryModel> ddr_documents                       {get;set;} // Added by Sanath H M,  Date: 13.12.2022	
        public List<String> ddr_CustomerIdTypes                             {get;set;} // Added by Sanath H M,  Date: 13.12.2022	
        public List<String> ddr_CustomerBankAccountTypes                    {get;set;} // Added by Sanath H M,  Date: 13.12.2022	
        public List<PayerAccountRecords> ddr_payerAccounts			        {get;set;} // Added by Tharun,  	Date: 06.01.2023
        public Boolean ddr_showNewButton                                    {get;set;}
        public Boolean isEligibleForCancellation                            {get;set;}
        public List<SalesOrderCancellation__c> salesOrderCancellation       {get;set;}
        public Set<String> cancellationReasons                              {get;set;}
        public List<User> salesAdminUsers                                   {get;set;}
        public String ddr_CustomerIdNumber_default                          {get;set;}
        public String ddr_CustomerIdType_default                            {get;set;}
        public boolean showOptOutDDR                                        {get;set;}
        public boolean physicalSignatureApproval                            {get;set;}
        public String SignatureChangeApprovalStatus                        {get;set;}
         //Digital to physical signature changes
        public List<String> digitalToPhysicalChangeReasons                {get;set;}
        global SalesOrderModel()
        {
            this.orderDetails = new List<SalesOrderRecord>();
            this.amountDetails = new List<SalesOrderRecord>();
            this.additionalDetails = new List<SalesOrderRecord>();
            this.reservationDetails = new List<SalesOrderRecord>();
            this.isSpecialConditionUpdateable = false;
            this.reservationToBookingFlag = false;
            this.ICArequired = false;
            this.isSubStatusUpdateable = false;
            this.jointOwner = new List<JointOwner__c>();
            this.installment = new List<InstallmentLines__c>();
            this.otherCharges = new List<SalesOrderOtherCharges__c>();
            this.commissionLines = new List<CommissionLineItem__c>();
            this.receiptAcknowledgements = new List<ReceiptAcknowledgement__c>();
            this.subStatus = new Set<String>();
            this.documents = new List<DocumentQueryModel>();
            this.accountRelationships = new List<AccountRelationship__c>();
            this.paymentMode = new List<String>();
            this.currencyValues = new List<SalesOrderRecord>();
            this.winReasonValues = new Set<String>();
            this.spaSignatureTypeValues = new Set<String>();				// Added by Tharun, Date: 02.02.2023
			this.directDebitRequests = new List<DirectDebitRequest__c>();// Added by Sanath H M,  Date: 13.12.2022	
            this.ddr_CustomerBankNames = new List<String>();// Added by Sanath H M,  Date: 13.12.2022	
            this.ddr_documents = new List<DocumentQueryModel>();// Added by Sanath H M,  Date: 13.12.2022
            this.ddr_payerAccounts = new List<PayerAccountRecords>();		// Added by Tharun,		Date: 06.01.2023
            this.ddr_CustomerIdTypes = new List<String>();	
            this.ddr_CustomerBankAccountTypes = new List<String>();	
            this.ddr_showNewButton = false;
            this.isEligibleForCancellation = false ;
            this.salesOrderCancellation = new List<SalesOrderCancellation__c>();
            this.cancellationReasons = new Set<String>();
            this.salesAdminUsers = new List<User>();
            this.ddr_CustomerIdNumber_default ='';
            this.ddr_CustomerIdType_default='';
            this.showOptOutDDR = false;
            this.physicalSignatureApproval = false;
            this.SignatureChangeApprovalStatus = '';
             //Digital to physical signature changes
            this.digitalToPhysicalChangeReasons = new List<String>();
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

    global class ReceiptDetails{
        public ReceiptAcknowledgement__c receiptRecord     {get;set;}
        public Boolean isReceiptUpdatable                  {get;set;}
        
        public ReceiptDetails()
        {
            this.receiptRecord = new ReceiptAcknowledgement__c();
            this.isReceiptUpdatable = false;
        }
    }
    
    // Added by Tharun
    global class PayerAccountRecords{
        public String accountId			{get;set;}
        public String accountName		{get;set;}
        public String accountIdNumber	{get;set;}
        public String passportNumber    {get;set;}
        public String RegistrationNumber{get;set;}
        public boolean isPersonAccount {get;set;}
        
        public PayerAccountRecords(String accountId, String accountName, String accountIdNumber, String passportNumber, String RegistrationNumber, boolean isPersonAccount){
            this.accountId 		= accountId;
            this.accountName	= accountName;
            this.accountIdNumber= accountIdNumber;
            this.passportNumber = passportNumber;
            this.RegistrationNumber=RegistrationNumber;
            this.isPersonAccount = isPersonAccount;
        }
        
    }
}