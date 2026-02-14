public with sharing class RetriggerAPIController {
    public class GenericException extends Exception {}


    @AuraEnabled
    public static String callRespectiveAPI(String srId) {

        String whrClause = ' Id = \'' + srId + '\'';
        List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithWhereClause(whrClause);
		System.debug('serviceRequestList>>>' + serviceRequestList);
        String recordTypeName = Utilities.getRecordTypeName('HexaBPM__Service_Request__c', serviceRequestList[0].RecordTypeId);
        
        if (!serviceRequestList.isEmpty()) {
            callAPI(serviceRequestList, recordTypeName);
            for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
                serviceRequest.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            }
            update serviceRequestList;
        }
        return 'success';
    }

    public static void callAPI(List<HexaBPM__Service_Request__c> serviceRequestList, String recordTypeName) {
        if (!serviceRequestList.isEmpty()) {
            if (recordTypeName == Constants.PAYMENT_EXTENSION_RT) {
                PaymentExtensionCalloutHelper.prepareDataForCallout(serviceRequestList);
            } else if (recordTypeName == Constants.PROPERTY_TRANSFER_RT || recordTypeName == Constants.PLOT_PROPERTY_TRANSFER_RT || recordTypeName == Constants.PROPERTY_TRANSFER_NOC_RT) {
                List<Id> custAccountIds = new List<Id>();
                List<Id> srIds = new List<Id>();
                for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
                    srIds.add(serviceRequest.Id);
                    if (String.isBlank(serviceRequest.BuyerName__r.ERPID__c)) {
                        custAccountIds.add(serviceRequest.BuyerName__c);
                    }
                    for (AgencyTeam__c agencyTeam: serviceRequest.Partners__r) {
                        if (String.isBlank(agencyTeam.Account__r.ERPID__c)) {
                            custAccountIds.add(agencyTeam.Account__c);
                        }
                    }
                }
                if (!custAccountIds.isEmpty()) {
                    CustomerCalloutHelper.PrepareDataForCallout(custAccountIds, srIds, 'ServiceRequest_PropertyTransfer');
                } else {
                    PropertyTransferCalloutHelper.prepareDataForCallout(serviceRequestList);
                }
            } else if (recordTypeName == Constants.LPC_WAIVER_RT) {

                List<HexaBPM__Service_Request__c> freezeLPCRequests = new List<HexaBPM__Service_Request__c>();
                List<HexaBPM__Service_Request__c> closedLPCRequests = new List<HexaBPM__Service_Request__c>();

                for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
                    if(serviceRequest.LPCFreezeStatus__c == Constants.STATUS_FAILED || serviceRequest.LPCFreezeStatus__c == Constants.STATUS_IN_PROGRESS){
                        freezeLPCRequests.add(serviceRequest);
                    } 
                    if(serviceRequest.SyncStatus__c != Constants.STATUS_SYNCED){
                        closedLPCRequests.add(serviceRequest);
                    }
                }
                if(!freezeLPCRequests.isEmpty()){
                    LPCCalloutHelper.prepareDataForFreezeCallout(freezeLPCRequests, false);
                }
                if(!closedLPCRequests.isEmpty()){
                    LPCCalloutHelper.prepareDataForCallout(closedLPCRequests);
                }
            } else if (recordTypeName == Constants.DEFAULT_AND_TERMINATION) {
                DefaultAndTerminationCalloutHelper.syncDefaultServiceRequest(new map<id,HexaBPM__Service_Request__c>(serviceRequestList).keySet());
            } else if (recordTypeName == Constants.RECORDTYPE_HANDOVER) {
                HandoverCalloutHelper.prepareDataForCallout(serviceRequestList);
            } else if (recordTypeName == Constants.CANCELLATION_RT) {
                CancellationCalloutHelper.prepareDataForCallout(serviceRequestList);
            } else if (recordTypeName == Constants.PAYMENT_PLAN_CHANGE_RT) {
                PaymentPlanChangeCalloutHelper.prepareDataForCallout(serviceRequestList);
            } else if (recordTypeName ==Constants.INTERNAL_MORTGAGE_REGISTRATION_RT) {
                MortgageCalloutHelper.prepareDataForCallout(serviceRequestList);
            } else if (recordTypeName ==Constants.INTERNAL_MORTGAGE_DISCHARGE_RT) {
                MortgageCalloutHelper.prepareDataForCallout(serviceRequestList);
            } else if (recordTypeName ==Constants.REBATE_REINSTATE_RT) {
                RebateReinstateCalloutHelper.prepareDataForCallout(serviceRequestList);
            } else if (recordTypeName ==Constants.ADM_Fee_Refund_RT) {
                ADMFeeRefundCalloutHelper.prepareDataForCallout(serviceRequestList);
            } else if (recordTypeName == Constants.JOINT_OWNER_RT || recordTypeName == Constants.JOINT_OWNER_NOC_RT) {
                List<Id> custAccountIds = new List<Id>();
                List<Id> srIds = new List<Id>();
                for (HexaBPM__Service_Request__c serviceRequest: serviceRequestList) {
                    srIds.add(serviceRequest.Id);
                    for (AgencyTeam__c agencyTeam: serviceRequest.Partners__r) {
                        if (String.isBlank(agencyTeam.Account__r.ERPID__c)) {
                            custAccountIds.add(agencyTeam.Account__c);
                        }
                    }
                }
                if (!custAccountIds.isEmpty()) {
                    CustomerCalloutHelper.PrepareDataForCallout(custAccountIds, srIds, 'ServiceRequest_JointOwner');
                } else {
                    JointOwnerR2CalloutHelper.prepareDataForCallout(serviceRequestList);
                }
            } else if(recordTypeName == Constants.CREDIT_NOTE_CREATION_SR_TYPE) {
                try{
                    HexaBPM__Service_Request__c sRRecord = [SELECT Id,Amount__c, AmountWithoutVAT__c, VATAmount__c, ServiceRequestComments__c, Sales_Order_Other_Charges__c, 
                                                        InstallmentLine__c, InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.InvoicedAmount__c,
                                                        InstallmentLine__r.Name,InstallmentLine__r.InvoiceId__c,
                                                        PaymentType__c, Credit_Note_Sub_Type__c, Unit__c, SalesOrder__c, HexaBPM__Customer__c,
                                                        Sales_Order_Other_Charges__r.ERPID__c,ChargeType__c,
                                                        HexaBPM__External_SR_Status__r.Name,
                                                        InvoiceReversal__c,
                                                        SalesOrder__r.Opportunity__c,
                                                        (SELECT Id, HexaBPM__Step_Status__c, OwnerId, HexaBPM__Summary__c FROM HexaBPM__Steps_SR__r),
                                                        (SELECT Id FROM HexaBPM__SR_Docs__r)
                                                        FROM HexaBPM__Service_Request__c
                                                        WHERE Id =:serviceRequestList[0].Id Limit 1];
                    Map<String, String> cdLinkEntityId = new Map<String, String>();
                    for(HexaBPM__SR_Doc__c doc: sRRecord.HexaBPM__SR_Docs__r) {
                        cdLinkEntityId.put(doc.Id, ALDOC_OtherChargesHelper.generatePublicURL(doc.Id));
                    } 
                    if(sRRecord.InvoiceReversal__c) {
                        CC_ALDRA_CreditNoteCreationProcess.doCreditNoteCallout(null, cdLinkEntityId, sRRecord.Credit_Note_Sub_Type__c, sRRecord.Id, sRRecord.InstallmentLine__c, sRRecord.InstallmentLine__r.InvoiceId__c,true);
                    } else if(sRRecord.Credit_Note_Sub_Type__c == CC_ALDRA_CreditNoteCreationProcess.REBATE) {
                        ReceiptAcknowledgement__c rAck = [SELECT Id FROM ReceiptAcknowledgement__c WHERE ServiceRequest__c=:sRRecord.Id Limit 1];
                        
                        CC_ALDRA_CreditNoteCreationProcess.doCreditNoteCallout(new List<Id>{rAck.Id}, cdLinkEntityId, sRRecord.Credit_Note_Sub_Type__c, sRRecord.Id, sRRecord.InstallmentLine__c, sRRecord.InstallmentLine__r.InvoiceId__c,false);
                    } else {
                        ReceiptAllocation__c alloc = [SELECT Id FROM ReceiptAllocation__c WHERE ReceiptAcknowledgement__r.ServiceRequest__c= :sRRecord.Id Limit 1];
                        
                        CC_ALDRA_CreditNoteCreationProcess.doCreditNoteCallout(new List<Id>{alloc.Id},cdLinkEntityId, sRRecord.Credit_Note_Sub_Type__c, sRRecord.Id, null, null, false); 
                    }
                } catch(Exception ex) {
                    System.debug(ALD_Constants.SOMETHING_WRONG+' > '+ex.getStackTraceString()+' > '+ex.getLineNumber()+' > '+ex.getMessage());
                    throw new GenericException(ALD_Constants.SOMETHING_WRONG+' At > '+ex.getStackTraceString()+' Line > '+ex.getLineNumber()+' Error > '+ex.getMessage());
                }
            }
        }
    }
}