/*
* Name               : CustomerGetServiceRequestWebService
* Description        : This class is used to Get Service Request and Case Details
*/
@RestResource (urlMapping = '/customer/getservicerequest')
global without sharing class CustomerGetServiceRequestWebService {

    @HTTPPost
    global static void doPost(){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            handler.response.data = getServiceRequest(jsonBody, 0, false);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception e) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }

    public static ResponseModel getServiceRequest(String jsonBody, Integer srLimit, Boolean onlyCase) {
        
        ResponseModel responseModel = new ResponseModel();

        System.debug('requestBody>>>' + jsonBody);
        SRModel srModel = (SRModel)JSON.deserializeStrict(jsonBody, SRModel.class);

        List<String> srRecordType = new List<String>{Constants.AldarEstatesMoveInOut_RT, Constants.AldarEstatesMoveOut_RT ,Constants.PROPERTY_TRANSFER_NOC_RT, Constants.PROPERTY_TRANSFER_RT, Constants.JOINT_OWNER_RT, Constants.JOINT_OWNER_NOC_RT, Constants.INVESTOR_CERTIFICATE_RT,'Title Deed Registration',Constants.PROPERTY_TRANSFER_OffPlan};
        String srRecordTypeStr = String.join(srRecordType, '\',\'');
        String typeValues = String.join(System.Label.GeneralCaseType.split(';'), '\',\'');

         list<HexaBPM__Service_Request__c> moveInSr = [SELECT Id,name FROM HexaBPM__Service_Request__c WHERE SalesOrder__c=:srModel.orderId AND SRType__c = 'Aldar Estates Move-In'];
       
        // START | Building where clause for Service Request and Case to filter based on Date, Status, Type and Search string
        List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwner(new List<Id>{srModel.customerId});
        String soIdsStr = String.join(soIds, '\',\'');

        String srWhereClause = '';
        String caseWhereClause = '';
        String moveInRTsStr = '\'' + Constants.AldarEstatesMoveInOut_RT + '\',\'' + Constants.AldarEstatesMoveOut_RT  + '\'';

		String otherRTsStr = '\'' + Constants.PROPERTY_TRANSFER_NOC_RT + '\',\'' + Constants.PROPERTY_TRANSFER_RT + '\',\'' +
    Constants.JOINT_OWNER_RT + '\',\'' + Constants.JOINT_OWNER_NOC_RT + '\',\'' +
    Constants.INVESTOR_CERTIFICATE_RT + '\',\'Title Deed Registration\',\''
    + Constants.PROPERTY_TRANSFER_OffPlan + '\'';


        
        if (!soIds.isEmpty()) {
            srWhereClause = ' ((HexaBPM__Customer__c = \'' + srModel.customerId + '\' OR SalesOrder__c IN (\'' + soIdsStr + '\') OR BuyerName__c = \'' + srModel.customerId +'\') AND RecordType.Name IN (\'' + srRecordTypeStr + '\') ';
            caseWhereClause = ' ((AccountId = \'' + srModel.customerId + '\' OR SalesOrder__c IN (\'' + soIdsStr + '\')) ';
        } else {
            srWhereClause = ' ((HexaBPM__Customer__c = \'' + srModel.customerId +  '\'  OR BuyerName__c = \'' + srModel.customerId +'\') AND RecordType.Name IN (\'' + srRecordTypeStr + '\') ';
            caseWhereClause = ' ((AccountId = \'' + srModel.customerId + '\') ';
        }
		
        
        String rtCondition = '('
            + 'RecordType.Name IN (' + moveInRTsStr + ')'
            + ' OR (RecordType.Name IN (' + otherRTsStr + ') AND (Origin__c = \'Customer Portal\' OR Origin__c = \'Customer App\'))'
            + ')';
        
       
        srWhereClause += ' AND ' + rtCondition;
        
		caseWhereClause += ' AND (((Origin = \'' + CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_PORTAL + '\' OR Origin = \'' + CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_APP + '\') ';
        caseWhereClause += ' AND (Vertical__c = \''+CustomerAPIConstants.CASE_DLP_RECORD_TYPE+'\' OR RecordType.name =\''+CustomerAPIConstants.CASE_DLP_RECORD_TYPE + '\' OR Origin = \'' + CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_PORTAL + '\' OR Origin = \'' + CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_APP + '\') ';
        caseWhereClause += ' AND Subject NOT IN (\'' + Constants.PROPERTY_TRANSFER_RT + '\', \'' + Constants.PROPERTY_TRANSFER_NOC_RT + '\', \'' + Constants.ADDITION_JOINT_OWNER_RT + '\', \'' + Constants.INVESTOR_CERTIFICATE_RT + '\'))';
        caseWhereClause +=  'OR (Type IN (\'' + typeValues + '\')))';

        if (srModel.fromDate != null) {
            srWhereClause += ' AND CreatedDate >= ' + String.valueOf(srModel.fromDate) + 'T00:00:00.000+0000 ';
            caseWhereClause += ' AND CreatedDate >= ' + String.valueOf(srModel.fromDate) + 'T00:00:00.000+0000 ';
        }
        if (srModel.toDate != null) {
            srWhereClause += ' AND CreatedDate <= ' + String.valueOf(srModel.toDate) + 'T23:59:59.000+0000 ';
            caseWhereClause += ' AND CreatedDate <= ' + String.valueOf(srModel.toDate) + 'T23:59:59.000+0000 ';
        }
        if (String.isNotBlank(srModel.orderId)) {
            srWhereClause += ' AND SalesOrder__c = \'' + srModel.orderId + '\' ';
            caseWhereClause += ' AND SalesOrder__c = \'' + srModel.orderId + '\' ';
        }
        if (String.isNotBlank(srModel.status)) {
            // if (srModel.status == CustomerAPIConstants.STATUS_NEW) {
            //     srWhereClause += ' AND (HexaBPM__External_Status_Name__c = \'' + Constants.SR_STATUS_DRAFT + '\' OR HexaBPM__External_Status_Name__c = \'' + Constants.SUBMITTED + '\') ';
            //     caseWhereClause += ' AND Status = \'' + CustomerAPIConstants.STATUS_NEW + '\' ';
            // } else
            if (srModel.status == CustomerAPIConstants.STATUS_IN_PROGRESS) {
                // srWhereClause += ' AND HexaBPM__IsClosedStatus__c = false AND HexaBPM__External_Status_Name__c != \'' + Constants.SR_STATUS_DRAFT + '\' AND HexaBPM__External_Status_Name__c != \'' + Constants.SUBMITTED + '\' ';
                // caseWhereClause += ' AND IsClosed = false AND Status != \'' + CustomerAPIConstants.STATUS_NEW + '\' AND Status != \'' + CustomerAPIConstants.CASE_STATUS_PENDING_WITH_CUSTOMER + '\' ';
                srWhereClause += ' AND HexaBPM__IsClosedStatus__c = false ';
                caseWhereClause += ' AND IsClosed = false ';
            } else if (srModel.status == CustomerAPIConstants.STATUS_CLOSED) {
                srWhereClause += ' AND HexaBPM__IsClosedStatus__c = true ';
                caseWhereClause += ' AND IsClosed = true ';
            } else {
                srWhereClause += ' AND Id = null ';
                caseWhereClause += ' AND Id = null ';
            }
        }
        
        if (srModel.searchKey != null && !srModel.searchKey.isEmpty()) {
            String srSearchClause = '';
            String caseSearchClause = '';
            for (String sKey: srModel.searchKey) {
                // Id = \'' + sKey + '\' OR 
                srSearchClause += (String.isNotBlank(srSearchClause) ? ' OR ' : '') + ' Name LIKE \'%' + sKey + '%\' OR Unit__r.Name LIKE \'%' + sKey + '%\' OR RecordType.Name LIKE \'%' + sKey + '%\' OR SRtype__c LIKE \'%' + sKey + '%\' ';
                caseSearchClause += (String.isNotBlank(caseSearchClause) ? ' OR ' : '') + ' CaseNumber LIKE \'%' + sKey + '%\' OR Unit__r.Name LIKE \'%' + sKey + '%\' OR CaseCategory__c LIKE \'%' + sKey + '%\' OR SubCategory__c LIKE \'%' + sKey + '%\' OR Subject LIKE \'%' + sKey + '%\' ';
            }
            srWhereClause += ' AND (' + srSearchClause + ') ';
            caseWhereClause += ' AND (' + caseSearchClause + ') ';
        }
        srWhereClause += ') ';
        caseWhereClause += ') ';

        // END | Building where clause for Service Request and Case to filter based on Date, Status, Type and Search string
        // 
        //Joint Buyer | START
		List<AgencyTeam__c> joBuyerList = [ SELECT Id, ServiceRequest__c FROM AgencyTeam__c WHERE Account__c = : srModel.customerId AND ServiceRequest__r.SRType__c = 'Property Transfer NOC'];
        List<String> serviceRequestIds = new List<String>();
        for (AgencyTeam__c JoBuyer : joBuyerList) {
            if (JoBuyer.ServiceRequest__c != null) {
                serviceRequestIds.add(JoBuyer.ServiceRequest__c);
               
            }
        }
        if (!serviceRequestIds.isEmpty()) {
            String joinedSRIds = '\'' + String.join(serviceRequestIds, '\',\'') + '\'';
            srWhereClause = '(' + srWhereClause + ' OR Id IN (' + joinedSRIds + '))';
        } else {
            
            srWhereClause = '(' + srWhereClause + ')';
        }
			//Joint Buyer | END
		system.debug('srWhereClause::'+ srWhereClause);
        if (!onlyCase) {
            List<HexaBPM__Service_Request__c> srList = CustomerServiceUtility.getServiceRequestDetail(srWhereClause);
            system.debug('srList::'+ srList);
            for (HexaBPM__Service_Request__c sr: srList) {
                if ((sr.RecordType.Name == Constants.JOINT_OWNER_RT || sr.RecordType.Name == Constants.JOINT_OWNER_NOC_RT) && sr.SRType__c != Constants.ADDITION_JOINT_OWNER_RT) {
                    continue;
                }
                String status = CustomerAPIConstants.STATUS_IN_PROGRESS;
                // if (sr.HexaBPM__External_Status_Name__c == Constants.SR_STATUS_DRAFT || sr.HexaBPM__External_Status_Name__c == Constants.SUBMITTED) {
                //     status = CustomerAPIConstants.STATUS_NEW;
                // } else
                if (sr.HexaBPM__IsClosedStatus__c == true) {
                    status = CustomerAPIConstants.STATUS_CLOSED;
                }
                
                String type = sr.RecordTypeName__c == Constants.INVESTOR_CERTIFICATE_RT ? CustomerAPIConstants.PROPERTY_CERTIFICATE : sr.RecordTypeName__c == Constants.PROPERTY_TRANSFER_NOC_RT ? sr.RecordTypeName__c : sr.SRType__c == 'Aldar Estates Move-Out' ? 'Move-Out' : sr.SRType__c == 'Aldar Estates Move-In' ? 'Move-In' : sr.RecordTypeName__c ;
                
                if (String.isNotBlank(type) && (String.isBlank(srModel.type) || srModel.type == type)) {
                    responseModel.serviceRequests.add(new ServiceRequestModel(sr, status, type));
                    
                    responseModel.type.add(type);
                    responseModel.status.add(status);
                    if (sr.Unit__c != null && sr.SalesOrder__c != null) {
                        responseModel.unitNames.put(sr.Unit__r.Name, sr.SalesOrder__c);
                    }
                }
            }
        }
        
        if (srLimit != null && srLimit != 0 && onlyCase) {
            caseWhereClause += ' AND SubVertical__c = \'' + Constants.DLP_SUB_VERTICAL + '\' ORDER BY LastModifiedDate DESC LIMIT ' + srLimit;
        }
        
        system.debug('caseWhereClause-->'+ caseWhereClause);
        
        List<Case> csList = CustomerServiceUtility.getCaseDetail(caseWhereClause);
        for (Case cs: csList) {
            String status = CustomerAPIConstants.STATUS_IN_PROGRESS;
            // if (cs.Status == CustomerAPIConstants.STATUS_NEW) {
            //     status = CustomerAPIConstants.STATUS_NEW;
            // } else
            if (cs.IsClosed == false) {
                status = CustomerAPIConstants.STATUS_IN_PROGRESS;
            } else if (cs.IsClosed == true) {
                status = CustomerAPIConstants.STATUS_CLOSED;
            }
            String type = cs.CaseCategory__c == 'Tenant Onboarding' ? cs.CaseCategory__c : System.Label.GeneralCaseType.split(';').contains(cs.Type) ? cs.Type : cs.RecordType.Name == Constants.FEEDBACK_CASE_RT ? CustomerAPIConstants.FEEDBACK : (cs.CaseCategory__c == CustomerAPIConstants.CUSTOMER_PORTAL_AND_APP || cs.CaseCategory__c == CustomerAPIConstants.OTHER) ? cs.CaseCategory__c : ((cs.Origin == CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_PORTAL || cs.Origin == CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_APP) && String.isNotBlank(cs.Subject)) ? cs.Subject : String.isNotBlank(cs.CaseCategory__c) ? cs.CaseCategory__c : cs.SubVertical__c;
            
            if (String.isNotBlank(type) && (String.isBlank(srModel.type) || srModel.type == type)) {
                type = type.contains(CustomerAPIConstants.CASE_SUBJECT_STOP_PAYMENT) ? CustomerAPIConstants.CASE_SUBJECT_STOP_PAYMENT : type;
                responseModel.serviceRequests.add(new ServiceRequestModel(cs, status, type));

                responseModel.type.add(type);
                responseModel.status.add(status);
                if (cs.Unit__c != null && cs.SalesOrder__c != null) {
                    responseModel.unitNames.put(cs.Unit__r.Name, cs.SalesOrder__c);
                }
            }
        }

        System.debug('responseModel>>>' + responseModel);
        return responseModel;
    }

    public class SRModel{
        public String customerId                                    {get;set;}
        public Date fromDate                                        {get;set;}
        public Date toDate                                          {get;set;}
        public String orderId                                       {get;set;}
        public String status                                        {get;set;}
        public String type                                          {get;set;}
        public String referenceId                                   {get;set;}
        public List<String> searchKey                               {get;set;}
    }

    public class ResponseModel{
        public Map<String, String> unitNames                        {get;set;}
        public Set<String> type                                     {get;set;}
        public Set<String> status                                   {get;set;}
        public List<ServiceRequestModel> serviceRequests            {get;set;}

        public ResponseModel () {
            this.unitNames = new Map<String, String>();
            this.type = new Set<String>();
            this.status = new Set<String>();
            this.serviceRequests = new List<ServiceRequestModel>();
        }
    }

    public class ServiceRequestModel{
        public String requestId                                     {get;set;}
        public String requestNo                                     {get;set;}
        public String unitId                                        {get;set;}
        public String unitName                                      {get;set;}
        public String type                                          {get;set;}
        public String requestDetail                                 {get;set;}
        public DateTime requestDate                                 {get;set;}
        public DateTime closedDate                                  {get;set;}
        public String status                                        {get;set;}
        public String comment                                       {get;set;}
        public String commentsForCustomer                           {get;set;}
        public Object srDetails                                     {get;set;}
		 public DateTime amcDueDate                       {get;set;}
        public string origin 							 {get;set;}
        public ServiceRequestModel (HexaBPM__Service_Request__c sr, String status, String type) {
            this.requestId = sr.Id;
            this.requestNo = sr.Name;
            this.type = type;
            this.requestDetail = sr.Name + ' | ' + type;
            this.requestDate = sr.CreatedDate;
            this.closedDate = sr.HexaBPM__Closed_Date_Time__c;
            this.status = status;
            this.unitId = sr.Unit__c;
            this.unitName = sr.Unit__r.Name;
            this.comment = sr.CustomerComment__c;
            this.commentsForCustomer = sr.CommentsForCustomer__c;
            this.srDetails = sr;
            this.amcDueDate = null;
            this.origin= sr.Origin__c;
        }
        
        public ServiceRequestModel (Case cs, String status, String type) {
            this.requestId = cs.Id;
            this.requestNo = cs.CaseNumber;
            this.type = type;
            this.requestDetail = cs.CaseNumber + ' | ' + type;
            this.requestDate = cs.CreatedDate;
            this.closedDate = cs.ClosedDate;
            this.status = status;
            this.unitId = cs.Unit__c;
            this.unitName = cs.Unit__r.Name;
            this.comment = cs.CustomerComment__c;
            this.commentsForCustomer = cs.CommentsForCustomer__c;
            this.srDetails = cs;
             this.amcDueDate = cs.AMC_Due_Date__c;
        }
    }
}