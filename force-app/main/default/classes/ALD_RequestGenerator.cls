/*
 * To Fix Integration Issue
 * Generating the Request to validate if anything went wrong with any record
 * SARAVANAN SEKAR
 */
public class ALD_RequestGenerator {
    
    @AuraEnabled
    public static string generateSalesOrderRequest(List<Id> soIds) {
        try {
            Map<String, String> customerMap = new Map<String, String>();
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
                sodMap.put('admFeeAmount', so.ADMFeeAmount__c != null ? String.valueOf(so.ADMFeeAmount__c) : '');
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
                    ocMap.put('amount', oc.Amount__c != null ? String.valueOf(oc.Amount__c) : '');
                    
                    ocList.add(ocMap);
                }
                if(!isOtherCharge) {
                    Map<String, Object> ocMap = new Map<String, Object>();
                    ocMap.put('sfSalesOrderNum', '');
                    ocMap.put('recordId', '');
                    ocMap.put('typeOfCharge', '');
                    ocMap.put('amount', '');
                    
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
            return requestBody;
        } catch(Exception ex) {
            System.debug('EXCEPTION +'+ex.getMessage()+' -> '+ex.getLineNumber());
            return ex.getMessage()+' -> '+ex.getLineNumber();
        }
    }
    
    @AuraEnabled
    public static string generateCustomerRequest(List<Id> accIds) {
        try{
            List<Account> accList = AccountService.queryAllFieldsWithExtraFields(accIds);
            
            Map<String, Object> finalMap = new Map<String, Object>();
            List<Object> cdList = new List<Object>();
            
            for (Account acc: accList) {
                Map<String, Object> cdMap = new Map<String, Object>();
                
                String recordMode = String.isBlank(acc.ERPID__c) ? Constants.MULESOFT_CREATE_MODE : Constants.MULESOFT_UPDATE_MODE;
                String mobileCountryCode = '';
                if (acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT) {
                    mobileCountryCode = acc.MobileCountryCode__pc != null && acc.MobileCountryCode__pc.contains('+') ? acc.MobileCountryCode__pc.substring(1, acc.MobileCountryCode__pc.length()) : acc.MobileCountryCode__pc;
                } else {
                    mobileCountryCode = acc.MobileCountryCode__c != null && acc.MobileCountryCode__c.contains('+') ? acc.MobileCountryCode__c.substring(1, acc.MobileCountryCode__c.length()) : acc.MobileCountryCode__c;
                }
                
                cdMap.put('sfId', acc.Id);
                cdMap.put('custType', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? 'ORGANIZATION' : 'PERSON');
                cdMap.put('organizationName', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.Name : '');
                cdMap.put('registrationNumber', acc.RegistrationNumber__c);
                cdMap.put('issueDate', acc.RegistrationIssueDate__c);
                cdMap.put('expiryDate', acc.RegistrationExpiryDate__c);
                cdMap.put('placeOfRegistration', acc.PlaceOfRegistration__c);
                cdMap.put('nameInArabic', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.NameInArabic__c : ''); // for Organization
                cdMap.put('nameArabic', acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT ? acc.NameInArabic__c : '');   // for Person
                cdMap.put('motherNameArabic', acc.MotherNameArabic__pc);
                cdMap.put('tradeName', acc.TradeName__c);
                cdMap.put('unifiedNumber', acc.UnifiedNumber__c);
                cdMap.put('typeOfCompany', acc.TypeOfCompany__c);
                cdMap.put('owner', '');   // need to check by Venu
                cdMap.put('fullyOwnedByUaeNational', '');   // need to check by Venu
                cdMap.put('tenantIndustry', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.Industry : '');   // List Of Values | by Venu
                cdMap.put('customerClass', '');   // List Of Values | by Venu
                cdMap.put('investmentValue', '');   // List Of Values | by Venu
                cdMap.put('currentValueRating', acc.CurrentValueRating__c);
                cdMap.put('potentialValueRatingOrg', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.PotentialValueRating__c : ''); // for Organization
                cdMap.put('potentialValueRating', acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT ? acc.PotentialValueRating__c : '');   // for Person
                cdMap.put('influenceRating', '');   // List Of Values | by Venu
                cdMap.put('loyaltyOrg', acc.Loyalty__c);
                cdMap.put('placeOfIncorporation', '');   // need to check by Venu
                cdMap.put('gateReminderLetter', '');   // Date value
                cdMap.put('gateExpiryLetter', '');   // Date Value
                cdMap.put('preNameAdjunct', acc.Salutation);
                cdMap.put('firstName', acc.FirstName);
                cdMap.put('middleName', acc.MiddleName);
                cdMap.put('lastName', acc.LastName);
                cdMap.put('gender', acc.Gender__pc);
                cdMap.put('dateOfBirth', acc.PersonBirthdate);
                cdMap.put('maritalStatus', acc.MaritalStatus__pc);
                cdMap.put('passportNumber', acc.PassportNumber__pc);
                cdMap.put('passportType', acc.Passport_type__pc);
                cdMap.put('passportPlaceOfIssue', acc.PlaceofIssue__pc);
                cdMap.put('passportIssueDate', acc.PassportIssueDate__pc);
                cdMap.put('passportExpiryDate', acc.PassportExpiryDate__pc);
                cdMap.put('visaNo', acc.VisaUIDNo__pc);
                cdMap.put('visaExpiry', acc.VisaExpiryDate__pc);
                cdMap.put('nationality', acc.Nationality__pc);
                cdMap.put('nationalIdNumber', acc.NationalIdNumber__pc);
                cdMap.put('nationalIdExpiry', acc.NationalIdExpiryDate__pc);
                cdMap.put('homatCardNo', acc.Homatcardnumber__pc);
                cdMap.put('company', acc.Company__pc);   // need to check by Venu
                cdMap.put('companyName', acc.Company__pc);   // need to check by Venu
                cdMap.put('uaeFamilyNo', acc.UaeFamilyNumber__pc);
                cdMap.put('uaeFamilyBookNo', acc.UaeFamilyBookNumber__pc);
                cdMap.put('uaeFbPlaceOfIssue', acc.UaeFamilyBookPlaceofIssue__pc);
                cdMap.put('uaeFbIssueDate', acc.UaeFamilyBookDateofIssue__pc);
                cdMap.put('customerSegment', acc.CustomerType__c);   // List Of Values | by Venu
                cdMap.put('residencyStatus', acc.ResidentStatus__pc == 'Non-Resident' ? 'Non - Resident' : acc.ResidentStatus__pc);   // List Of Values | by Venu
                cdMap.put('employementStatus', acc.EmploymentStatus__pc);
                cdMap.put('purposeOfInvestment', '');   // need to check by Venu
                cdMap.put('smartPass', acc.SmartPass__pc);
                cdMap.put('unifiedNo', acc.UnifiedNumber__c);
                cdMap.put('loyalty', acc.Loyalty__c);
                cdMap.put('classification', acc.CustomerSubType__c);   // List Of Values | by Venu
                cdMap.put('partyId', acc.ERPID__c);
                cdMap.put('createdByUser', String.isBlank(acc.ERPID__c) ? acc.CreatedBy.Email : acc.Owner.Email);
                // cdMap.put('createdByUser', 'VPAWAR');
                cdMap.put('sourceOfFunds', acc.SourceofFunds__pc);
                cdMap.put('otherSoruceFund', acc.Other_Source_of_Funds__pc);
                cdMap.put('positionTitle', acc.Position__pc);

                //Pass compound field as a trimmed string.
                String workplaceAddress = acc.Workplace_Street__pc + ' ,'+ acc.Workplace_Country__pc + ' ,'+ acc.Workplace_Postalcode__pc;
                String trimmedWorkplaceAddress = workplaceAddress != null ? workplaceAddress.substring(0, Math.min(99, workplaceAddress.length())) : '';
                cdMap.put('companyAddress', trimmedWorkplaceAddress);
                cdMap.put('annualTotalIncome', String.valueOf(acc.AnnualIncome__pc));
                cdMap.put('noOfYearsWithCompany', String.valueOf(acc.NoofYearswithCompany__pc));
                cdMap.put('natureOfBusiness', acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT ? acc.Industry : '');   // List Of Values | by Venu
                cdMap.put('emailP', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.Email__c : acc.PersonEmail);
                cdMap.put('phoneLineTypeP', 'MOBILE');   // List Of Values // need to change
                cdMap.put('phoneCountryCodeP', mobileCountryCode);
                cdMap.put('phoneAreaCodeP', '');
                cdMap.put('phoneNumberP', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.MobileNumber1__c : acc.MobilePhone__pc);
                cdMap.put('phoneExtensionP', '');
                cdMap.put('countryP', String.isNotBlank(acc.BillingCountry) ? acc.BillingCountry : '');
                cdMap.put('address1P', acc.BillingStreet);
                cdMap.put('address2P', '');
                cdMap.put('address3P', '');
                cdMap.put('address4P', '');
                cdMap.put('cityP', acc.BillingCity);
                cdMap.put('postalCodeP', acc.BillingPostalCode);
                cdMap.put('stateP', acc.BillingState);
                cdMap.put('provinceP', '');
                cdMap.put('countyP', '');
                cdMap.put('emailS', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.Email__c : acc.PersonEmail);
                cdMap.put('phoneLineTypeS', 'MOBILE');   // List Of Values // need to change
                cdMap.put('phoneCountryCodeS', mobileCountryCode);
                cdMap.put('phoneAreaCodeS', '');
                cdMap.put('phoneNumberS', acc.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT ? acc.MobileNumber1__c : acc.MobilePhone__pc);
                cdMap.put('phoneExtensionS', '');
                cdMap.put('countryS', String.isNotBlank(acc.ShippingCountry) ? acc.ShippingCountry : '');
                cdMap.put('address1S', acc.ShippingStreet);
                cdMap.put('address2S', '');
                cdMap.put('address3S', '');
                cdMap.put('address4S', '');
                cdMap.put('cityS', acc.ShippingCity);
                cdMap.put('postalCodeS', acc.ShippingPostalCode);
                cdMap.put('stateS', acc.ShippingState);
                cdMap.put('provinceS', '');
                cdMap.put('countyS', '');
                
                Map<String, Object> oIds = new Map<String, Object>();
                if (acc.OtherERPID__c != null) {
                    oIds = (Map<String, Object>)JSON.deserializeUntyped(acc.OtherERPID__c);
                    for (String key: oIds.keySet()) {
                        oIds.put(key.toLowerCase(), oIds.get(key));
                    }
                }
                cdMap.put('partySiteIdP', !oIds.isEmpty() && oIds.containsKey('partysiteidp') ? String.valueOf(oIds.get('partysiteidp')) : '');
                cdMap.put('partySiteUseIdP', !oIds.isEmpty() && oIds.containsKey('partysiteuseidp') ? String.valueOf(oIds.get('partysiteuseidp')) : '');
                cdMap.put('contactPointIdPhoneP', !oIds.isEmpty() && oIds.containsKey('contactpointidphonep') ? String.valueOf(oIds.get('contactpointidphonep')) : '');
                cdMap.put('contactPointIdEmailP', !oIds.isEmpty() && oIds.containsKey('contactpointidemailp') ? String.valueOf(oIds.get('contactpointidemailp')) : '');
                cdMap.put('locationIdP', !oIds.isEmpty() && oIds.containsKey('locationidp') ? String.valueOf(oIds.get('locationidp')) : '');
                cdMap.put('partySiteIdS', !oIds.isEmpty() && oIds.containsKey('partysiteids') ? String.valueOf(oIds.get('partysiteids')) : '');
                cdMap.put('partySiteUseIdS', !oIds.isEmpty() && oIds.containsKey('partysiteuseids') ? String.valueOf(oIds.get('partysiteuseids')) : '');
                cdMap.put('contactPointIdPhoneS', !oIds.isEmpty() && oIds.containsKey('contactpointidphones') ? String.valueOf(oIds.get('contactpointidphones')) : '');
                cdMap.put('contactPointIdEmailS', !oIds.isEmpty() && oIds.containsKey('contactpointidemails') ? String.valueOf(oIds.get('contactpointidemails')) : '');
                cdMap.put('locationIdS', !oIds.isEmpty() && oIds.containsKey('locationids') ? String.valueOf(oIds.get('locationids')) : '');
                
                cdList.add(cdMap);
            }
            finalMap.put('customerDetails', cdList);
            
            String requestBody = JSON.serialize(finalMap);
            requestBody = requestBody.replaceAll(':null', ':""');
            System.debug('requestBody>>>' + requestBody);
            return requestBody;
        } catch(Exception ex) {
            System.debug('EXCEPTION +'+ex.getMessage()+' -> '+ex.getLineNumber());
            return ex.getMessage()+' -> '+ex.getLineNumber();
        }
    }
    
    @AuraEnabled
    public static String generateReceiptRequest(List<Id> pcIds){
        try {
            List<ReceiptAcknowledgement__c> pcList = ReceiptAcknowledgementService.queryAllFieldsWithExtraFields(pcIds);
            
            Map<String, Object> finalMap = new Map<String, Object>();
            List<Object> pcdList = new List<Object>();
            
            for (ReceiptAcknowledgement__c ra: pcList) {
                Map<String, Object> pcdMap = new Map<String, Object>();
                
                String recordMode = String.isBlank(ra.ERPID__c) ? Constants.MULESOFT_CREATE_MODE : Constants.MULESOFT_UPDATE_MODE;
                
                pcdMap.put('recordMode', recordMode);
                pcdMap.put('recordId', ra.Id); 
                pcdMap.put('createdById', ra.CreatedBy.Email);	
                // pcdMap.put('createdById', 'MENAYA@aldar.com');
                pcdMap.put('salesOrderId', ra.SalesOrder__c != null ? ra.SalesOrder__r.ERPID__c : '');
                pcdMap.put('sfSoPayTermId', ra.SalesOrder__c != null ? String.ValueOf(ra.SalesOrder__r.PaymentPlan__c) : '');
                pcdMap.put('chequeNo', ra.ReferenceNumber__c);
                pcdMap.put('unitNo', ra.SalesOrder__c != null && ra.SalesOrder__r.Unit__c != null ? ra.SalesOrder__r.Unit__r.Name : '');
                pcdMap.put('chequeAmt', String.valueOf(ra.Amount__c));
                pcdMap.put('currencyCode', ra.CurrencyIsoCode);
                pcdMap.put('bankName', ra.BankName__c);
                pcdMap.put('branchName', '');
                pcdMap.put('paymentType', ra.PaymentType__c);
                pcdMap.put('chequeDate', ra.MaturityDate__c);
                pcdMap.put('remarks', ra.Remarks__c);
                pcdMap.put('chequeReceived', ra.ChequeReceived__c ? 'Y' : 'N');
                pcdMap.put('chequeReceivedBy', ra.ChequeReceivedBy__c != null ? ra.ChequeReceivedBy__r.Email : '');
                pcdMap.put('chequeReceivedDate', ra.ChequeReceivedDate__c);
                pcdMap.put('erpCheckId', ra.ERPID__c);
                pcdMap.put('isHeaderFlag', ra.IsReceiptAcknowledgementChange__c ? 'Y' : 'N');
                pcdMap.put('isLinesFlag', ra.IsReceiptAllocationChange__c ? 'Y' : 'N');
                pcdMap.put('holdDate', ra.HoldDate__c );     // Added by Muzammil as part of receipt remittance - 23 Aug 2022
                pcdMap.put('sfRecStatus', ra.Status__c);    // Added by Muzammil as part of receipt remittance - 23 Aug 2022
                pcdMap.put('isDelete', ra.Markfordeletion__c ? 'Y' : 'N');    // Added by Muzammil to delete receipts - 16th Sept 2022
                
                Decimal iNo = 0;
                List<Object> raLineList = new List<Object>();
                for (ReceiptAllocation__c raLine: ra.Receipt_Allocations__r) {
                    Map<String, Object> raLineMap = new Map<String, Object>();
                    raLineMap.put('recackRecordId', ra.Id);
                    raLineMap.put('erpCheckApplId', raLine.ERPID__c);
                    raLineMap.put('recordId', raLine.Id);
                    raLineMap.put('salesOrderId', raLine.SalesOrder__c != null ? raLine.SalesOrder__r.ERPID__c : '');
                    raLineMap.put('chequeNo', ra.ReferenceNumber__c);
                    raLineMap.put('installmentNo', raLine.InstallmentLine__c != null ? String.valueOf(raLine.InstallmentLine__r.InstallmentNumber__c) : '');
                    raLineMap.put('unitNo', raLine.SalesOrder__c != null && raLine.SalesOrder__r.Unit__c != null ? raLine.SalesOrder__r.Unit__r.Name : '');
                    raLineMap.put('lineAmount', String.valueOf(raLine.AmountApplied__c));
                    raLineList.add(raLineMap);
                    if (raLine.SalesOrder__c == ra.SalesOrder__c && raLine.InstallmentLine__c != null && iNo < raLine.InstallmentLine__r.InstallmentNumber__c) {
                        iNo = raLine.InstallmentLine__r.InstallmentNumber__c;
                    }
                }
                pcdMap.put('receiptAppl', raLineList);
                pcdMap.put('installmentNo', iNo != 0 ? String.valueOf(iNo) : '');
                
                pcdList.add(pcdMap);
            }
            finalMap.put('pmtchqRq', pcdList);
            
            String requestBody = JSON.serialize(finalMap);
            requestBody = requestBody.replaceAll(':null', ':""');
            System.debug('requestBody>>> ' + requestBody);
            return requestBody;
        } catch(Exception ex) {
            System.debug('EXCEPTION +'+ex.getMessage()+' -> '+ex.getLineNumber());
            return ex.getMessage()+' -> '+ex.getLineNumber();
        }
    }
}