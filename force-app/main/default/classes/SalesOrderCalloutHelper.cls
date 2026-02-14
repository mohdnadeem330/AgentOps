public class SalesOrderCalloutHelper {
    //INTEG_ISSUE_FIX_SS START
    public static Boolean EXECUTE_ACCOUNT_FIRST = false;
    public static List<Id> soIds_copy = new List<Id>();
    public static Boolean isCalledFromQueueable_copy = false;
    public static Map<String, String> customerMap_copy = new Map<String, String>();
    // Commented for DDR deployment public static Boolean SALES_ORDER_CALLOUT_FINISHED = FALSE; //FLAG TO STOP MULTIPLE CALLOUTS
    //INTEG_ISSUE_FIX_SS - END
    
    public static Map<String, String> PrepareDataForCallout(List<Id> soIds, Boolean isCalledFromQueueable, Map<String, String> customerMap) {
        System.debug('SalesOrderCalloutHelper -> Invoked');

        List<SalesOrder__c> soList = SalesOrderService.queryAllFieldsWithExtraFields(soIds);

        List<Id> commissionIds = new List<Id>();
        for (SalesOrder__c so: soList) {
            for (CommissionLineItem__c cli : so.CommissionLineItems__r) {
                // if (cli.CommissionType__c == Constants.COMMISSION_LINE_EXTERNAL_COMMISSION && (cli.ApprovalStatus__c == Constants.APPROVED_STATUS || cli.GenerateClaimForm__c == Constants.COMMISSION_LINE_GENERATED)) {
                if (cli.CommissionType__c == Constants.COMMISSION_LINE_EXTERNAL_COMMISSION && cli.ApprovalStatus__c == Constants.APPROVED_STATUS) {
                    commissionIds.add(cli.Id);
                }
            }
        }

        List<Id> relatedIds = new List<Id>();
        List<Id> relatedClaimIds = new List<Id>();
        Map<Id, Id> commissionDocMap = new Map<Id, Id>();
        Map<Id, Id> commissionClaimDocMap = new Map<Id, Id>();
        for(Document__c doc: [SELECT Id, CommissionLineItem__c, DocumentType__c, AvailableForExternalUsers__c FROM Document__c WHERE CommissionLineItem__c IN: commissionIds AND (DocumentType__c =: Constants.DOCUMENT_PLACEHOLDER_CATEGORY_COMMISSION_INVOICE OR DocumentType__c =: Constants.DOCUMENT_PLACEHOLDER_CATEGORY_COMMISSION_CLAIM_FORM)]) {
            if (doc.DocumentType__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_COMMISSION_INVOICE) {
                relatedIds.add(doc.Id);
                commissionDocMap.put(doc.Id, doc.CommissionLineItem__c);
            } else if (doc.DocumentType__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_COMMISSION_CLAIM_FORM) {
                relatedClaimIds.add(doc.Id);
                commissionClaimDocMap.put(doc.Id, doc.CommissionLineItem__c);
            }
        }

        Map<Id, Map<String, String>> publicIdURLMap = new Map<Id, Map<String, String>>();
        Map<Id, Map<String, String>> newMap = ContentDocumentLinkService.getIdUSLMap(relatedIds);
        for (Id docId: newMap.keySet()) {
            if (commissionDocMap.containsKey(docId)) {
                publicIdURLMap.put(commissionDocMap.get(docId), newMap.get(docId));
            }
        }

        Map<Id, Map<String, String>> publicIdURLClaimMap = new Map<Id, Map<String, String>>();
        Map<Id, Map<String, String>> newClaimMap = ContentDocumentLinkService.getIdUSLMap(relatedClaimIds);
        for (Id docId: newClaimMap.keySet()) {
            if (commissionClaimDocMap.containsKey(docId)) {
                publicIdURLClaimMap.put(commissionClaimDocMap.get(docId), newClaimMap.get(docId));
            }
        }

        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> sodList = new List<Object>();
        
        List<Id> accIds = new List<Id>();
        List<Id> salesOrderIds = new List<Id>();
        for (SalesOrder__c so: soList) {
            if (String.isBlank(so.Account__r.ERPID__c)) {
                accIds.Add(so.Account__c);
                salesOrderIds.add(so.Id);
            }
        }
        system.debug('accIds:::'+accIds);
        system.debug('System.isFuture():::'+System.isFuture());
         system.debug('isCalledFromQueueable:::'+isCalledFromQueueable);
        if (!accIds.isEmpty() && System.isFuture() == false && !isCalledFromQueueable) {
            system.debug('coming inside');
            CustomerCalloutHelper.PrepareDataForCallout(accIds, salesOrderIds, 'SalesOrder__c');
            // commented by Muzammil for DD deployment return null; //To prevent executing the next lines of code when acc eprid is null
        }

        List<Id> recordIds = new List<Id>();
        for (SalesOrder__c so: soList) {
            if (String.isBlank(so.Account__r.ERPID__c) && !customerMap.containsKey(so.Account__c)) {
                continue;
            }
            recordIds.add(so.Id);
            Map<String, Object> sodMap = new Map<String, Object>();

            String recordMode = String.isBlank(so.ERPID__c) ? Constants.MULESOFT_CREATE_MODE : Constants.MULESOFT_UPDATE_MODE;

            sodMap.put('actionMode', recordMode);
            sodMap.put('sfSalesOrderNum', so.Id);
            sodMap.put('leadNumber', so.OpportunityNumber__c != null ? so.OpportunityNumber__c : '');
            sodMap.put('locationCode', so.Unit__c != null ? so.Unit__r.Name : '');
            sodMap.put('currencyCode', so.CurrencyIsoCode);
            sodMap.put('orderStatus', so.Status__c);
            sodMap.put('orderSubStatus', so.SubStatus__c);
            sodMap.put('saleEvent', so.Offer__c != null && so.Offer__r.SalesEventCampaignName__c != null ? so.Offer__r.SalesEventCampaignName__c : '');
            sodMap.put('partyId', so.Account__r.ERPID__c != null ? so.Account__r.ERPID__c : customerMap.get(so.Account__c));
            sodMap.put('orderDate', so.BookingDate__c);
            sodMap.put('remarks', so.Remarks__c != null ? so.Remarks__c : '');
            sodMap.put('inventoryCategory', so.UnitInventoryCategory__c != null ? so.UnitInventoryCategory__c : '');
            sodMap.put('saleType', so.OpportunitySaleType__c != null ? so.OpportunitySaleType__c : '');
            sodMap.put('dealType', so.OpportunityDealType__c != null ? so.OpportunityDealType__c : '');
            sodMap.put('bookingType', so.OpportunityBookingType__c != null ? so.OpportunityBookingType__c : '');
            sodMap.put('unitFinishing', so.UnitFinishing__c != null ? so.UnitFinishing__c : '');
            sodMap.put('unitFurnishing', so.UnitFurnishing__c != null ? so.UnitFurnishing__c : '');
            sodMap.put('designType', so.DesignType__c != null ? so.DesignType__c : '');
            sodMap.put('paytermClassification', so.PaymentPlan__c != null && so.PaymentPlan__r.Classification__c != null ? so.PaymentPlan__r.Classification__c : '');
            sodMap.put('approvePendingDate', '');
            sodMap.put('corporateWealthName', so.CorporateWealthName__c != null ? so.CorporateWealthName__c : '' );
            
            if (so.ApprovePendingDate__c != null) {
                sodMap.put('approvePendingDate', so.ApprovePendingDate__c);
            }
            sodMap.put('salesApprovedDate', '');
            if (so.SalesApprovedDate__c != null) {
                sodMap.put('salesApprovedDate', so.SalesApprovedDate__c);
            }
            sodMap.put('businessUnitId', so.Unit__c != null && so.Unit__r.Project__r.BusinessUnitId__c != null ? so.Unit__r.Project__r.BusinessUnitId__c : '');
            sodMap.put('admFlag', so.Unit__c != null && so.Unit__r.Project__r.ExcludeFromADM__c == true ? 'Y' : 'N');

            //----
            sodMap.put('podType', so.PODChoosen__c != null? String.valueOf(so.PODChoosen__c) : '' );
            sodMap.put('podAmount', so.PODAmount__c != null ? String.valueOf(so.PODAmount__c) : '');
            sodMap.put('designPremAmount', so.DesignPremiumAmount__c != null ? String.valueOf(so.DesignPremiumAmount__c) : '');
            sodMap.put('virtualAcctNo','');
            if (so.Unit__r.VirtualAccountNumber__c != Null){
                 sodMap.put('virtualAcctNo', String.valueOf(so.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c));
            }
              //-----
 
            sodMap.put('measuredArea', so.MeasuredArea__c != null ? String.valueOf(so.MeasuredArea__c) : '');
            sodMap.put('referralType', so.ReferralType__c != null ? so.ReferralType__c : '');
            sodMap.put('employeeName', so.EmployeeName__c != null ? so.EmployeeName__c : '');
            sodMap.put('brokerAgency', so.OpportunityBrokerAgencyAccount__c != null ? so.OpportunityBrokerAgencyAccount__c : '');
            sodMap.put('brokerAgent', so.OpportunityBrokerAgentContactName__c != null ? so.OpportunityBrokerAgentContactName__c : '');
            sodMap.put('multiPurRoomAmt', so.MultiPurposeAmount__c != null ? String.valueOf(so.MultiPurposeAmount__c) : '');
            sodMap.put('sellingPrice', so.SellingPrice__c != null ? String.valueOf(so.SellingPrice__c) : '');
            sodMap.put('premiumAmount', so.PremiumAmount__c != null ? String.valueOf(so.PremiumAmount__c) : '');
            sodMap.put('corporateDiscount', so.CorporateDiscount__c != null ? String.valueOf(so.CorporateDiscount__c) : '');
            sodMap.put('bulkDiscount', so.BulkDiscount__c != null ? String.valueOf(so.BulkDiscount__c) : '');
            sodMap.put('paytermDiscount', so.PaymentPlanDiscount__c != null ? String.valueOf(so.PaymentPlanDiscount__c) : '');
            sodMap.put('discount', so.Discount__c != null ? String.valueOf(so.Discount__c) : '');
            sodMap.put('netAmount', so.NetAmount__c != null ? String.valueOf(so.NetAmount__c) : '');
            sodMap.put('taxableAmount', so.TaxableAmount__c != null ? String.valueOf(so.TaxableAmount__c) : '');
            sodMap.put('amountPayable', so.AmountPayable__c != null ? String.valueOf(so.AmountPayable__c) : '');
            sodMap.put('otherRebateAmt', so.OtherRebateAmount__c != null ? String.valueOf(so.OtherRebateAmount__c) : '');
            decimal ADMFeeAmountFinal = 0;
            if(so.ADMFeeAmount__c != null){
                ADMFeeAmountFinal = so.ADMFeeAmount__c;
            }
            if(so.ADM_Admin_Fee__c != null ){
                ADMFeeAmountFinal = ADMFeeAmountFinal+ so.ADM_Admin_Fee__c;
            }
            sodMap.put('admFeeAmount', ADMFeeAmountFinal != null ? String.valueOf(ADMFeeAmountFinal) : '');         
          //  sodMap.put('admFeeAmount', so.ADMFeeAmount__c != null ? String.valueOf(so.ADMFeeAmount__c) : '');
            sodMap.put('admFeePercent', so.ADMPercentage__c != null ? String.valueOf(so.ADMPercentage__c) : '');
            sodMap.put('contractIssuedDate', '');
            if (so.ContractIssuedDate__c != null) {
                sodMap.put('contractIssuedDate', so.ContractIssuedDate__c);    
            }
            sodMap.put('contractFinalDeliveryDate', '');
            if (so.ContractFinalDeliveryDate__c != null) {
                sodMap.put('contractFinalDeliveryDate', so.ContractFinalDeliveryDate__c);
            }
            sodMap.put('email', so.Account__c != null ? so.Account__r.PersonEmail != null ? so.Account__r.PersonEmail : so.Account__r.Email__c : '');
            sodMap.put('phoneNumber', so.Account__c != null ? so.Account__r.PersonMobilePhone != null ? so.Account__r.PersonMobilePhone : so.Account__r.MobileNumber__c : '');
            sodMap.put('holdFlag', so.HoldFlag__c ? 'Y' : 'N');
            sodMap.put('defaultStatus', so.DefaultStatus__c != null ? so.DefaultStatus__c : '');
            sodMap.put('createdById', String.isBlank(so.ERPID__c) ? so.CreatedBy.Email : so.Owner.Email);
            sodMap.put('createdDate', date.newinstance(so.CreatedDate.year(), so.CreatedDate.month(), so.CreatedDate.day()));
            sodMap.put('vatTaxCode', so.VATTaxCode__c != null ? so.VATTaxCode__c : '');
            sodMap.put('vatRate', so.VATRate__c != null ? String.valueOf(so.VATRate__c) : '');
            sodMap.put('lastInstallmentRebate', so.LastInstallmentRebate__c != null ? String.valueOf(so.LastInstallmentRebate__c) : '');
            sodMap.put('additionalRebate', so.AdditionalRebate__c != null ? String.valueOf(so.AdditionalRebate__c) : '');
            sodMap.put('additionalRebate2', so.AdditionalRebate2__c != null ? String.valueOf(so.AdditionalRebate2__c) : '');
            sodMap.put('admFeeWaivedAmount', so.ADMFeeWaivedAmount__c != null ? String.valueOf(so.ADMFeeWaivedAmount__c) : '');
            sodMap.put('admWaivePercent', so.ADMWaivedPercentage__c != null ? String.valueOf(so.ADMWaivedPercentage__c) : '');
            sodMap.put('originalSellingPrice', so.RTOOriginalSellingPrice__c != null ? String.valueOf(so.RTOOriginalSellingPrice__c) : '');
            sodMap.put('corporatePartner', so.Account__c != null && so.Account__r.CorporateWealthName__c != null ? so.Account__r.CorporateWealthName__c : '');
            sodMap.put('mortgageBank', so.MortgageBank__c != null ? so.MortgageBank__c : '');
            sodMap.put('subsidyYears', so.SubsidyYears__c != null ? String.valueOf(so.SubsidyYears__c) : '');
            sodMap.put('subsidyAmount', so.SubsidyAmount__c != null ? String.valueOf(so.SubsidyAmount__c) : '');
            sodMap.put('homeMaintWaivedYears', so.HomeMaintenanceWaivedYears__c != null ? String.valueOf(so.HomeMaintenanceWaivedYears__c) : '');
            sodMap.put('homeMaintenaceAmt', '');
            sodMap.put('ssYasParksAmt', so.OtherSalesSupportAmount__c != null ? String.valueOf(so.OtherSalesSupportAmount__c) : '');
            sodMap.put('ssArtMembershipAmt', '');
            sodMap.put('srvChgWaivedYrs', so.ServiceChargeWaivedYears__c != null ? String.valueOf(so.ServiceChargeWaivedYears__c) : '');
            sodMap.put('custContactVerifyFlag', '');
            sodMap.put('oppertunityId', so.Opportunity__c != null ? so.Opportunity__c : '');
            sodMap.put('serviceChargeWaivedAmount', so.ServiceChargeWaivedAmount__c != null ? String.valueOf(so.ServiceChargeWaivedAmount__c) : '');
            sodMap.put('darnaAmount', so.DARNAAmount__c != null ? String.valueOf(so.DARNAAmount__c) : '');
            // *RTO* Start
            sodMap.put('securityDeposit', so.SecurityDeposit__c != null ? String.valueOf(so.SecurityDeposit__c) : '');
            sodMap.put('rtoOrigSellPrice', so.RTOOriginalSellingPrice__c != null ? String.valueOf(so.RTOOriginalSellingPrice__c) : ''); //RTOOriginalSellingPrice__c
            sodMap.put('rtoDiscount', so.RTODiscount__c != null ? String.valueOf(so.RTODiscount__c) : '');
            sodMap.put('rtoNetAmt', so.RTONetAmount__c != null ? String.valueOf(so.RTONetAmount__c) : '');
            //Added by Sanath H M 24.01.2023
            sodMap.put('ddRefNo' , so.Directdebitauthorityreferencenumber__c != null ? so.Directdebitauthorityreferencenumber__c: '');
            // *RTO* End
            sodMap.put('erpSalesOrderId', so.ERPID__c != null ? so.ERPID__c : '');
            sodMap.put('isHeaderChange', so.IsSalesOrderChange__c ? 'Y' : 'N');
            sodMap.put('isLinesChange', so.IsInstallmentLinesChange__c ? 'Y' : 'N');
            sodMap.put('isOtherChrgChange', so.IsOtherChargesChange__c ? 'Y' : 'N');
            sodMap.put('isPromotionChange', so.IsSalesOffersChange__c ? 'Y' : 'N');
            sodMap.put('isSaleConChange', so.IsSalesConsultantsChange__c ? 'Y' : 'N');



            Boolean isSOCancellation = false;
            for (SalesOrderCancellation__c soc: so.Sales_Order_Cancellation__r) {
                isSOCancellation = true;
                sodMap.put('adminRemarks', soc.Remarks__c != null ? soc.Remarks__c : '');
                sodMap.put('allInstProvided', soc.AllInstallmentProvided__c ? 'Y' : 'N');
                sodMap.put('blockingCustomer', soc.Black_List_Customer__c ? 'Y' : 'N');
                sodMap.put('brokerCommStatus', soc.BrokerCommissionStatus__c ? 'Y' : 'N');
                sodMap.put('cancelDate', soc.CancellationRequestDate__c);
                sodMap.put('cancelledBy', soc.CreatedBy.Email);
                sodMap.put('cancelReason', soc.ReasonforCancellation__c != null ? soc.ReasonforCancellation__c : '');
                sodMap.put('contractSignedByCust', soc.ContractSignedbyCustomer__c ? 'Y' : 'N');
                sodMap.put('downpayStatus', soc.DownPaymentStatus__c != null ? soc.DownPaymentStatus__c : '');
                sodMap.put('refundReason', soc.RefundReason__c != null ? soc.RefundReason__c : '');
            }

            if (!isSOCancellation) {
                sodMap.put('adminRemarks', '');
                sodMap.put('allInstProvided', '');
                sodMap.put('blockingCustomer', '');
                sodMap.put('brokerCommStatus', '');
                sodMap.put('cancelDate', '');
                sodMap.put('cancelledBy', '');
                sodMap.put('cancelReason', '');
                sodMap.put('contractSignedByCust', '');
                sodMap.put('downpayStatus', '');
                sodMap.put('refundReason', '');
            }

            List<Object> imlList = new List<Object>();
            for (InstallmentLines__c il : so.InstallmentLines__r) {
                Map<String, Object> iml = new Map<String, Object>();
                iml.put('sfSalesOrderNum', so.Id);
                iml.put('sfPaymentPlanId', il.PaymentPlan__c != null ? String.ValueOf(il.PaymentPlan__c) : '');
                iml.put('paymentPlanName', il.PaymentPlan__c != null && il.PaymentPlan__r.Name != null ? il.PaymentPlan__r.Name : '');
                iml.put('sfInstId', il.Id);
                iml.put('erpInstId', il.ERPID__c != null ? il.ERPID__c : '');
                iml.put('installmentNum', il.InstallmentNumber__c != null ? String.valueOf(il.InstallmentNumber__c) : '');
                iml.put('installmentPerc', il.InstallmentPercentage__c != null ? String.valueOf(il.InstallmentPercentage__c) : '');
                iml.put('brokPayoutPerc', il.BrokerPayoutPercentage__c != null ? String.valueOf(il.BrokerPayoutPercentage__c) : '');
                iml.put('installmentAmount', il.InstallmentAmount__c != null ? String.valueOf(il.InstallmentAmount__c) : '');
                iml.put('installmentDate', '');
                if (il.InstallmentDate__c != null) {
                    iml.put('installmentDate', il.InstallmentDate__c);
                }
                iml.put('description', il.Description__c != null ? il.Description__c : '');
                iml.put('createdById', String.isBlank(so.ERPID__c) ? so.CreatedBy.Email : so.Owner.Email);
                iml.put('createdDate', date.newinstance(il.CreatedDate.year(), il.CreatedDate.month(), il.CreatedDate.day()));

                 // *RTO* Start
                 iml.put('optFeePercent', il.RTOLine__c != null && il.RTOLine__r.OptionFee__c != null ? String.valueOf(il.RTOLine__r.OptionFee__c) : '');
                 iml.put('optFeeAmount', il.RTOLine__c != null && il.RTOLine__r.OptionFeeAmount__c != null ? String.valueOf(il.RTOLine__r.OptionFeeAmount__c) : '');
                 iml.put('rtoBuyoutPrice', il.RTOLine__c != null && il.RTOLine__r.RemainingPayment__c != null ? String.valueOf(il.RTOLine__r.RemainingPayment__c) : '');
                 iml.put('rtoPriceEsc', il.RTOLine__c != null && il.RTOLine__r.Rent__c != null ? String.valueOf(il.RTOLine__r.Rent__c) : '');
                 iml.put('rtoStartDate', '');
                 if (il.RTOStartDate__c != null) {
                     iml.put('rtoStartDate', il.RTOStartDate__c);
                 }
                 iml.put('rtoEndDate', '');
                 if (il.RTOEndDate__c != null) {
                     iml.put('rtoEndDate', il.RTOEndDate__c);
                 }
                 iml.put('rtoFrequency', il.RTOPaymentFrequency__c);
                 iml.put('rtoOptFeeTaxCode', il.RTOOptionFeeTaxCode__c != null ? String.valueOf(il.RTOOptionFeeTaxCode__c ) : il.RTOOptionFeeTaxCode__c);
                 iml.put('activeTenancyYear', il.ActiveTenancyYear__c ? 'Y' : 'N');
                 iml.put('rtoRebantAmount', il.RTOLine__c != null && il.RTOLine__r.RebateAmount__c != null ? String.valueOf(il.RTOLine__r.RebateAmount__c) : '');
                 iml.put('rtoRentPerEsc', il.RTOLine__c != null && il.RTOLine__r.RentEscalation__c != null ? String.valueOf(il.RTOLine__r.RentEscalation__c) :'');
                 iml.put('rtoRentDiscount', il.RTOLine__c != null && il.RTOLine__r.RTOConfiguration__c != null && il.RTOLine__r.RTOConfiguration__r.DiscountPercentage__c != null ? String.valueOf(il.RTOLine__r.RTOConfiguration__r.DiscountPercentage__c) : '');
                 iml.put('rtoRentPercent', '');
                 // *RTO* End

                imlList.add(iml);
            }
            sodMap.put('installmentLines', imlList);

            List<Object> ocList = new List<Object>();
            Boolean isOtherCharge = false;
            for (SalesOrderOtherCharges__c oc : so.SalesOrdersOtherCharges__r) {
                isOtherCharge = true;
                Map<String, Object> ocMap = new Map<String, Object>();
                ocMap.put('sfSalesOrderNum', so.Id);
                ocMap.put('recordId', oc.Id);
                ocMap.put('typeOfCharge', oc.TypeOfCharge__c != null ? oc.TypeOfCharge__c : '');
                //ocMap.put('amount', oc.Amount__c != null ? String.valueOf(oc.Amount__c) : '');
                //Added by Mahidhar ASF - 3618
                ocMap.put('amount', so.ADMFeeAmount__c != null ? String.valueOf(so.ADMFeeAmount__c) : '');
                ocMap.put('admAdminFee_AmtwithoutVAT', oc.Amount__c != null ? String.valueOf(oc.ADMAdminFeeAmount__c) : '');
                ocMap.put('admAdminFee_VATAmt', oc.Amount__c != null ? String.valueOf(oc.ADMAdminFeeVAT__c) : '');
                ocMap.put('serviceFee_AmtwithoutVAT', oc.Amount__c != null ? String.valueOf(oc.AldarServiceFee__c) : '');
                ocMap.put('serviceFee_VATAmt', oc.Amount__c != null ? String.valueOf(oc.AldarServiceFeeVAT__c) : '');
                

                ocList.add(ocMap);
            }
            if(!isOtherCharge) {
                Map<String, Object> ocMap = new Map<String, Object>();
                ocMap.put('sfSalesOrderNum', '');
                ocMap.put('recordId', '');
                ocMap.put('typeOfCharge', '');
                ocMap.put('amount', '');
                //Added by Mahidhar ASF - 3618
				ocMap.put('admAdminFee_AmtwithoutVAT', '');
                ocMap.put('admAdminFee_VATAmt', '');
                ocMap.put('serviceFee_AmtwithoutVAT', '');
                ocMap.put('serviceFee_VATAmt', '');
                
                ocList.add(ocMap);
            }
            sodMap.put('otherCharges', ocList);

            List<Object> sosList = new List<Object>();
            Boolean isOfferLine = false;
            for (OpportunityOfferLine__c ool : so.OpportunityOfferLines__r) {
                isOfferLine = true;
                Map<String, Object> sosMap = new Map<String, Object>();
                sosMap.put('sfSalesOrderNum', so.Id);
                sosMap.put('recordId', ool.Id);
                sosMap.put('offerName', ool.OfferLine__c != null && ool.OfferLine__r.OfferName__c != null && ool.OfferLine__r.OfferName__r.OfferName__c != null ? ool.OfferLine__r.OfferName__r.OfferName__c : '');
                sosMap.put('offerType', ool.OfferLine__c != null && ool.OfferLine__r.OfferType__c != null ? ool.OfferLine__r.OfferType__c : '');
                sosMap.put('offerOn', ool.OfferLine__c != null && ool.OfferLine__r.OfferOn__c != null ? ool.OfferLine__r.OfferOn__c : '');
                sosMap.put('offerValue', ool.OfferValue__c != null ? String.valueOf(ool.OfferValue__c) : '');

                sosList.add(sosMap);
            }
            if(!isOfferLine) {
                Map<String, Object> sosMap = new Map<String, Object>();
                sosMap.put('sfSalesOrderNum', '');
                sosMap.put('recordId', '');
                sosMap.put('offerName', '');
                sosMap.put('offerType', '');
                sosMap.put('offerOn', '');
                sosMap.put('offerValue', '');

                sosList.add(sosMap);
            }
            sodMap.put('salesOffers', sosList);

            List<Object> scList = new List<Object>();
            for (CommissionLineItem__c cli : so.CommissionLineItems__r) {
                Map<String, Object> scMap = new Map<String, Object>();
                scMap.put('sfSalesOrderNum', so.Id);
                scMap.put('sfRecId', cli.Id);
                scMap.put('erpRecId', cli.ERPID__c != null ? cli.ERPID__c : '');
                scMap.put('commInstNum', cli.InstalmentNumber__c != null ? cli.InstalmentNumber__c : '');
                scMap.put('commType', '');
                scMap.put('commInstPercent', cli.CommissionPercentage__c != null ? String.valueOf(cli.CommissionPercentage__c) : '');
                scMap.put('commAmount', cli.CommissionAmount__c != null ? String.valueOf(cli.CommissionAmount__c) : '');
                scMap.put('brokerAgency', cli.BrokerAgency__c != null && cli.BrokerAgency__r.ERPID__c != null ? cli.BrokerAgency__r.ERPID__c : '');
                scMap.put('brokerAgent', cli.BrokerAgent__c != null ? String.valueOf(cli.BrokerAgent__c) : '');
                scMap.put('salesManager', cli.SalesManager__c != null && cli.SalesManager__r.Email != null ? cli.SalesManager__r.Email : '');
                scMap.put('installmentPaid', cli.InstalmentPaid__c == 'Yes' ? 'Y' : 'N');
                scMap.put('paymentDueDate', '');
                if (cli.PaymentDueDate__c != null) {
                    scMap.put('paymentDueDate', cli.PaymentDueDate__c);
                }
                scMap.put('createdById', String.isBlank(so.ERPID__c) ? cli.CreatedBy.Email : cli.Owner.Email);
                scMap.put('createdDate', date.newinstance(cli.CreatedDate.year(), cli.CreatedDate.month(), cli.CreatedDate.day()));
                scMap.put('consultantType', cli.CommissionType__c != null ? cli.CommissionType__c : '');
                scMap.put('supInvNum', cli.InvoiceReferenceNumber__c != null ? cli.InvoiceReferenceNumber__c : '');
                scMap.put('supInvDate', '');
                if (cli.InvoiceDate__c != null) {
                    scMap.put('supInvDate', cli.InvoiceDate__c);
                }
                scMap.put('commissionBasis', 'Percent');
                scMap.put('commissionDefined', cli.PercentageWRTNetPrice__c != null ? String.valueOf(cli.PercentageWRTNetPrice__c) : '');
                scMap.put('approvalStatus', cli.ApprovalStatus__c != null ? cli.ApprovalStatus__c : '');

                Map<String, String> idURLMap = publicIdURLMap.containsKey(cli.Id) ? publicIdURLMap.get(cli.Id) : new Map<String, String>();
                scMap.put('doc1Id', !idURLMap.isEmpty() && idURLMap.containsKey('Id') ? idURLMap.get('Id') : '');
                scMap.put('doc1Url', !idURLMap.isEmpty() && idURLMap.containsKey('URL') ? idURLMap.get('URL') : '');

                Map<String, String> idURLClaimMap = publicIdURLClaimMap.containsKey(cli.Id) ? publicIdURLClaimMap.get(cli.Id) : new Map<String, String>();
                scMap.put('doc2Id', !idURLClaimMap.isEmpty() && idURLClaimMap.containsKey('Id') ? idURLClaimMap.get('Id') : '');
                scMap.put('doc2Url', !idURLClaimMap.isEmpty() && idURLClaimMap.containsKey('URL') ? idURLClaimMap.get('URL') : '');
                
                scMap.put('doc3Id', '');
                scMap.put('doc3Url', '');
                scMap.put('doc4Id', '');
                scMap.put('doc4Url', '');
                scMap.put('doc5Id', '');
                scMap.put('doc5Url', '');

                scList.add(scMap);
            }
            sodMap.put('salesConsultants', scList);

            sodList.add(sodMap);
        }
        finalMap.put('salesOrderDetails', sodList);

        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replace(':null', ':""');
        System.debug('requestBody>>>' + requestBody);
        
        //Commented by Muzammil for DD deployment SALES_ORDER_CALLOUT_FINISHED == FALSE && 
        if (!sodList.isEmpty() && System.isFuture() == false && !isCalledFromQueueable ) { 
            if (System.IsBatch() == true && !Trigger.isExecuting) { 
                CalloutToMuleSoft.calloutService(requestBody, true, Constants.SALESORDER_INTEGRATION, recordIds);
                
            } else if(!System.IsBatch() && Trigger.isExecuting){
                 //Commented by Muzammil for DD deployment       SALES_ORDER_CALLOUT_FINISHED = TRUE;
                CalloutToMuleSoft.calloutFutureService(requestBody, true, Constants.SALESORDER_INTEGRATION, recordIds);
            }
            //Commented by Arvind 
            //else if(System.IsBatch() && Trigger.isExecuting){
                  //system.debug('enqueueJobrun');  
            //System.enqueueJob(new QuableIntegrationHandler(requestBody, true, Constants.SALESORDER_INTEGRATION, recordIds));}
                           

        }
        

        Map<String, String> returnMap = new Map<String, String>();
        if (isCalledFromQueueable) {
            returnMap.put('processName', Constants.SALESORDER_INTEGRATION);
            returnMap.put('requestBody', requestBody);
            return returnMap;
        } else {
            return returnMap;
        }
    }
}