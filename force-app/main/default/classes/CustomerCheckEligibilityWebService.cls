/*
* Name               : CustomerCheckEligibilityWebService
* Description        : This class is used to get eligible Units for Service Request / Case
*/
@RestResource (urlMapping = '/customer/checkeligibility')
global without sharing class CustomerCheckEligibilityWebService {

    public enum SRTYPE {PropertyTransfer, JointOwner, InvestorCertificate}
    public enum CASETYPE {DLP, DARNA, Feedback}

    @HTTPPost
    global static void doPost(String customerId, String orderId, String requestType, String referenceId){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = checkEligibility(customerId, orderId, requestType);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    public static List<EligibleUnitModel> checkEligibility(String customerId, String orderId, String requestType) {
        
        List<EligibleUnitModel> eligibleUnitModelList = new List<EligibleUnitModel>();

        // START | Building where clause for cheking Sales Order eligibility for a Sales Order or for return List eligible sales Orders
        String salesOrderWhrClause = '';
        if (String.isNotBlank(orderId)) {
            salesOrderWhrClause = ' (Id = \'' + orderId + '\') ';
        } else {
            List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwner(new List<Id>{customerId});
            String cancelledWhereCaluse = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
            String soIdsStr = String.join(soIds, '\',\'');
            if (!soIds.isEmpty()) {
                salesOrderWhrClause = ' ((Account__c = \'' + customerId + '\' OR Id IN (\'' + soIdsStr + '\')) AND ' + cancelledWhereCaluse + ') ';
            } else {
                salesOrderWhrClause = ' ((Account__c = \'' + customerId + '\') AND ' + cancelledWhereCaluse + ') ';
            }
        }
        // END | Building where clause for cheking Sales Order eligibility for a Sales Order or for return List eligible sales Orders
        List<SalesOrder__c> salesOrderList = CustomerServiceUtility.getSalesOrderDetailWithSR(salesOrderWhrClause);

        if (salesOrderList.isEmpty()) {
            eligibleUnitModelList.add(New EligibleUnitModel(new SalesOrder__c(), false, ''));
        } else if (String.isNotBlank(orderId)) {
            eligibleUnitModelList.add(verifySalesOrder(customerId, salesOrderList[0], true, requestType));
        } else {
            for (SalesOrder__c salesOrder: salesOrderList) {
                EligibleUnitModel eligibleUnitModel = verifySalesOrder(customerId, salesOrder, false, requestType);
                if (eligibleUnitModel != null) {
                    eligibleUnitModelList.add(eligibleUnitModel);
                }
            }
        }

        return eligibleUnitModelList;
    }

    // Validate Sales Order for Service Request and Case
    public static EligibleUnitModel verifySalesOrder(String customerId, SalesOrder__c salesOrder, Boolean isVerifySalesOrder, String requestType) {
        EligibleUnitModel returnModel;
        
        if (salesOrder.Account__c != customerId && (String.valueOf(SRTYPE.PropertyTransfer) == requestType || String.valueOf(SRTYPE.JointOwner) == requestType || String.valueOf(SRTYPE.InvestorCertificate) == requestType)) {
            return null;
        }
        
        if (!isVerifySalesOrder && salesOrder.Status__c != Constants.SO_STATUS_SOLD && String.isNotBlank(requestType) && (String.valueOf(SRTYPE.PropertyTransfer) == requestType || String.valueOf(SRTYPE.JointOwner) == requestType || String.valueOf(SRTYPE.InvestorCertificate) == requestType)) {
            return null;
        }

        if (String.isNotBlank(requestType) && String.valueOf(SRTYPE.InvestorCertificate) == requestType && salesOrder.Unit__r.RecordType.Name != Constants.UNIT_RECORD_TYPE_PLOT) {
            return null;
        }

        Boolean isSRopen = false;
        if (String.isNotBlank(requestType) && !salesOrder.ServiceRequests__r.isEmpty() && (String.valueOf(SRTYPE.PropertyTransfer) == requestType || String.valueOf(SRTYPE.JointOwner) == requestType || String.valueOf(SRTYPE.InvestorCertificate) == requestType)) {
            for (HexaBPM__Service_Request__c sr: salesOrder.ServiceRequests__r) {
                if (String.valueOf(SRTYPE.PropertyTransfer) == requestType && sr.HexaBPM__Closed_Date_Time__c == null && (sr.RecordType.Name == Constants.PROPERTY_TRANSFER_RT || sr.RecordType.Name == Constants.PROPERTY_TRANSFER_NOC_RT)) {
                    isSRopen = true;
                    break;
                } else if (String.valueOf(SRTYPE.JointOwner) == requestType && sr.HexaBPM__Closed_Date_Time__c == null && (sr.RecordType.Name == Constants.JOINT_OWNER_RT || sr.RecordType.Name == Constants.JOINT_OWNER_NOC_RT)) {
                    isSRopen = true;
                    break;
                } else if (String.valueOf(SRTYPE.InvestorCertificate) == requestType && sr.HexaBPM__Closed_Date_Time__c == null && sr.RecordType.Name == Constants.INVESTOR_CERTIFICATE_RT) {
                    isSRopen = true;
                    break;
                }
            }
        }
        
        if (String.isNotBlank(requestType) && String.valueOf(CASETYPE.DLP) == requestType 
            && (salesOrder.CustomerDLPStartDate__c == null || salesOrder.DLPDate__c == null || (salesOrder.CustomerDLPStartDate__c > date.today() || salesOrder.DLPDate__c < date.today()))
            && ( String.isBlank(salesOrder.Unit__r.DLPZone__c) || ( String.isNOTBlank(salesOrder.Unit__r.DLPZone__c) && salesOrder.Unit__r.DLPZone__r.ContractorDLPStatus__c.equalsIgnoreCase('Inactive')))) {
            returnModel = new EligibleUnitModel(salesOrder, false, '');
        } else if (String.isNotBlank(requestType) && String.valueOf(CASETYPE.DARNA) == requestType && salesOrder.DARNAAmount__c >= 1) {
            returnModel = new EligibleUnitModel(salesOrder, false, '');
        } else if (String.isNotBlank(requestType) && String.valueOf(SRTYPE.PropertyTransfer) == requestType && salesOrder.CPCAllocated__c) {
            returnModel = new EligibleUnitModel(salesOrder, false, '');
        // } else if (String.isNotBlank(requestType) && (salesOrder.HoldFlag__c || (salesOrder.Account__r.Blacklisted__c && (salesOrder.Account__r.BlacklistReason__c == CustomerAPIConstants.BLACKLISTED_CUSTOMER_COMPLIANCE || salesOrder.Account__r.BlacklistReason__c == CustomerAPIConstants.BLACKLISTED_CUSTOMER_LEGAL)))) {
        } else if (String.isNotBlank(requestType) && (salesOrder.HoldFlag__c || salesOrder.Account__r.Blacklisted__c)) {
            returnModel = new EligibleUnitModel(salesOrder, false, salesOrder.HoldFlag__c == true ? '' : '');
        } else if (isSRopen) {
            returnModel = new EligibleUnitModel(salesOrder, false, Utilities.getSystemMessages(Constants.DUPLICATE_SR_MESSAGE).Message__c);
        } else {
            returnModel = new EligibleUnitModel(salesOrder, true, '');
        }
       return returnModel;
        /*if (returnModel.isEligible || isVerifySalesOrder) {
            return returnModel;
        } else {
            return null;
        }*/
    }

    public class EligibleUnitModel{
        public String orderId                                       {get;set;}
        public String orderNo                                       {get;set;}
        public String unitId                                        {get;set;}
        public String unitNo                                        {get;set;}
        public Boolean isEligible                                   {get;set;}
        public String message                                       {get;set;}

        public EligibleUnitModel(SalesOrder__c salesOrder, Boolean isEligible, String message) {
            this.orderId = salesOrder.Id;
            this.orderNo = salesOrder.Name;
            this.unitId = salesOrder.Unit__c;
            this.unitNo = salesOrder.Unit__r.Name;
            this.isEligible = isEligible;
            this.message = message;
        }
    }
}