@RestResource(urlMapping = '/customer/getCaseOrSRDetail')
global without sharing class CustomerSingleCaseSRDetailsAPI {
    @HttpPost
    global static void getCaseSRDetails() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            
            Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();
            Map<String, Object> responseData = new Map<String, Object>(); 
            handler.response.data = getDetails(mapFieldApiFieldValues);
            handler.response.success = true;
            handler.finalize();
        } catch (Exception ex) {
            System.debug('Exception at Line: ' + ex.getLineNumber() + ' Message: ' + ex.getMessage());
            Logger__c lgs = LoggerService.createApexLog(ex,'SingleCaseSRDetailsAPI','SingleCaseSRDetailsAPI','LivingIn');
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
    }
    
    public static ResponseModel getDetails( Map<String,String> mapFieldApiFieldValues){
        ResponseModel ResponseModel = new ResponseModel();
        if(mapFieldApiFieldValues.containsKey('entityId')){
            String entityId = (String) mapFieldApiFieldValues.get('entityId');
            if(entityId.startsWith('500')){
                String caseWhereClause = '';
                caseWhereClause += 'Id = \'' + entityId + '\'';
                List<Case> caseList = CustomerServiceUtility.getCaseDetail(caseWhereClause);
                String status = CustomerAPIConstants.STATUS_IN_PROGRESS;
                
                if (caseList[0].IsClosed == false) {
                    status = CustomerAPIConstants.STATUS_IN_PROGRESS;
                } else if (caseList[0].IsClosed == true) {
                    status = CustomerAPIConstants.STATUS_CLOSED;
                }
                String type = caseList[0].CaseCategory__c == 'Tenant Onboarding' ? caseList[0].CaseCategory__c :  System.Label.GeneralCaseType.split(';').contains(caseList[0].Type) ? caseList[0].Type : caseList[0].RecordType.Name == Constants.FEEDBACK_CASE_RT ? CustomerAPIConstants.FEEDBACK : (caseList[0].CaseCategory__c == CustomerAPIConstants.CUSTOMER_PORTAL_AND_APP || caseList[0].CaseCategory__c == CustomerAPIConstants.OTHER) ? caseList[0].CaseCategory__c : ((caseList[0].Origin == CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_PORTAL || caseList[0].Origin == CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_APP) && String.isNotBlank(caseList[0].Subject)) ? caseList[0].Subject : String.isNotBlank(caseList[0].CaseCategory__c) ? caseList[0].CaseCategory__c : caseList[0].SubVertical__c;
                responseModel.status.add(status);
                if (caseList[0].Unit__c != null) {
                    responseModel.unitNames.add(caseList[0].Unit__r.Name );
                }
                responseModel.serviceRequests.add(new ServiceRequestModel(caseList[0], status, type));
                responseModel.type.add(type);
                responseModel.status.add(status);
                responseModel.communityManagers =GenericCaseCreationWebService.getCommunityManagerNames(caseList[0]?.OwnerId);
            }else{
                String srWhereClause = '';
                srWhereClause += 'Id = \'' + entityId + '\'';
                String query = 'SELECT Id, Name,Origin__c, CreatedDate, RecordType.Name, RecordTypeName__c, HexaBPM__Customer__c, HexaBPM__External_Status_Name__c, HexaBPM__IsClosedStatus__c, CustomerComment__c, CommentsForCustomer__c, ';
                query += ' HexaBPM__Customer__r.Name, Unit__c, Unit__r.Name,Unit__r.Project__r.OA_Community_Name__c,Move_In_Time__c,Move_Out_Time__c, SalesOrder__c, SalesOrder__r.Name, SRType__c, ChargeType__c, ChargeCollected__c, PaymentType__c, TransferSellingPrice__c, HexaBPM__Closed_Date_Time__c, ';
                query += ' BuyerName__c,Move_In_Date__c,Move_Out_Date__c, BuyerName__r.Name, BuyerName__r.FirstName, BuyerName__r.LastName, BuyerName__r.MobileCountryCode__pc, BuyerName__r.MobilePhone__pc, BuyerName__r.BillingStreet, BuyerName__r.BillingCity, BuyerName__r.BillingState, BuyerName__r.BillingPostalCode, BuyerName__r.BillingCountry, ';
                query += ' HandoverDetail__c, HandoverDetail__r.CustomerSnaggingAppointment__c,Unit__r.BuildingSectionName__r.Precint_Name__c, HandoverDetail__r.CustomerSnaggingAppointment__r.AppointmentId__c, HandoverDetail__r.CustomerDesnaggingAppointment__c, HandoverDetail__r.CustomerDesnaggingAppointment__r.AppointmentId__c, HandoverDetail__r.KeyHandoverAppointment__c, HandoverDetail__r.KeyHandoverAppointment__r.AppointmentId__c, ';
                
                query += ' HandoverDetail__r.KeyHandoverDate__c, HandoverDetail__r.HandoverCompletionDate__c, HandoverDetail__r.CustomerSnaggingAppointment__r.Date__c, HandoverDetail__r.CustomerSnaggingAppointment__r.Appointment_Slot_Time__c, HandoverDetail__r.CustomerSnaggingAppointment__r.Slot__c, HandoverDetail__r.CustomerDesnaggingAppointment__r.Date__c, HandoverDetail__r.CustomerDesnaggingAppointment__r.Appointment_Slot_Time__c, HandoverDetail__r.CustomerDesnaggingAppointment__r.Slot__c, HandoverDetail__r.KeyHandoverAppointment__r.Date__c, HandoverDetail__r.KeyHandoverAppointment__r.Appointment_Slot_Time__c, HandoverDetail__r.KeyHandoverAppointment__r.Slot__c, ';
                query += ' HandoverDetail__r.KAR__c, HandoverDetail__r.KAR__r.Name, HandoverDetail__r.KAR__r.Email, HandoverDetail__r.KAR__r.Phone, HandoverDetail__r.KAR__r.MobilePhone, HandoverDetail__r.HandoverAgent__c, HandoverDetail__r.HandoverAgent__r.Name, HandoverDetail__r.HandoverAgent__r.Email, HandoverDetail__r.HandoverAgent__r.Phone, HandoverDetail__r.HandoverAgent__r.MobilePhone, HandoverDetail__r.Home_Orientation_Appointment__c, HandoverDetail__r.Home_Orientation_Appointment__r.AppointmentNumber, HandoverDetail__r.Home_Orientation_Appointment__r.SchedStartTime,HandoverDetail__r.Home_Orientation_Appointment__r.SchedEndTime,HandoverDetail__r.Desnagging_Appointment__c,';
                query +=  'HandoverDetail__r.Desnagging_Appointment__r.AppointmentNumber, HandoverDetail__r.Desnagging_Appointment__r.SchedStartTime,HandoverDetail__r.Desnagging_Appointment__r.SchedEndTime,HandoverDetail__r.Key_Handover_Appointment__c, HandoverDetail__r.Key_Handover_Appointment__r.SchedStartTime, HandoverDetail__r.Key_Handover_Appointment__r.SchedEndTime  , ';
                query += ' HandoverDetail__r.Home_Orientation_Appointment_Resource__c,HandoverDetail__r.Desnagging_Appointment_Resource__c,HandoverDetail__r.Key_Handover_Appointment_Resource__c ,';
                query += ' (SELECT Id, Name, HexaBPM__Summary__c, HexaBPM__Closed_Date__c, PortalAppStatus__c FROM HexaBPM__Steps_SR__r ORDER BY CreatedDate ASC), ';
                query += ' (SELECT Id, Name, HexaBPM__Status__c, CreatedDate FROM HexaBPM__SR_Docs__r ORDER BY CreatedDate ASC) ';
                query += ' FROM HexaBPM__Service_Request__c ' + (String.isNotBlank(srWhereClause) ? ' WHERE ' + srWhereClause : '');
                
                List<HexaBPM__Service_Request__c> srList = Database.query(query);
                String status = CustomerAPIConstants.STATUS_IN_PROGRESS;
                if (srList[0].HexaBPM__IsClosedStatus__c == true) {
                    status = CustomerAPIConstants.STATUS_CLOSED;
                }
                String type = srList[0].RecordTypeName__c == Constants.INVESTOR_CERTIFICATE_RT ? CustomerAPIConstants.PROPERTY_CERTIFICATE : srList[0].RecordTypeName__c == Constants.PROPERTY_TRANSFER_NOC_RT ? srList[0].RecordTypeName__c : srList[0].SRType__c == 'Aldar Estates Move-Out' ? 'Move-Out' : srList[0].SRType__c == 'Aldar Estates Move-In' ? 'Move-In' : srList[0].RecordTypeName__c ;
                
                responseModel.serviceRequests.add(new ServiceRequestModel(srList[0], status, type));
                responseModel.type.add(type);
                responseModel.status.add(status);
                responseModel.unitNames.add(srList[0].Unit__r.Name);
                responseModel.moveInOutResponse.add(new moveInOutResponse(srList[0]));
                
            }
            
        }
        return responseModel;
    }
    public class responseDetails{
        public string srId;
        public string customerId;
        public string status;
        public string moveOutDate;
        public string moveOutTime;
        public string customerName;
        public string unitName;
        public string communityName;
        public string precinctName;
        public string srNo;
        public string cancellationResult;
    }    
    public class ResponseModel{
        public List<String> unitNames                      			{get;set;}
        public Set<String> type                                     {get;set;}
        public Set<String> status                                   {get;set;}
        public List<ServiceRequestModel> serviceRequests            {get;set;}
        public List<String> communityManagers						{get;set;}
        public list<moveInOutResponse> moveInOutResponse			{get;set;}
        
        public ResponseModel () {
            this.unitNames = new List<String>();
            this.type = new Set<String>();
            this.status = new Set<String>();
            this.serviceRequests = new List<ServiceRequestModel>();
            this.communityManagers = new List<String>();
            this.moveInOutResponse = new list<moveInOutResponse>();
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
        public string customerName										{get;set;}
        public string communityName										{get;set;}
        
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
            this.customerName = sr.HexaBPM__Customer__r.Name;
            this.communityName = sr.Unit__r.Project__r.OA_Community_Name__c;
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
    
    public class moveInOutResponse {
        public string srId;
        public string customerId;
        public string status;
        public string moveInDate;
        public string moveInTime;
        public string moveOutDate;
        public string moveOutTime;
        public string customerName;
        public string unitName;
        public string communityName;
        public string precinctName;
        public string srNo;
        public list<string> CommunityManager ; 
        
        public moveInOutResponse (HexaBPM__Service_Request__c moveInOUTSR) {
            
            this.status = moveInOUTSR.HexaBPM__External_Status_Name__c ;
            this.moveInDate = string.valueof(moveInOUTSR.Move_In_Date__c);
            this.moveInTime = string.valueof(moveInOUTSR.Move_In_Time__c);
            this.moveOutDate = string.valueof(moveInOUTSR.Move_Out_Date__c);
            this.moveOutTime = string.valueof(moveInOUTSR.Move_Out_Time__c);
            this.srId = moveInOUTSR.Id ;
            this.customerName = moveInOUTSR.HexaBPM__Customer__r.Name;
            this.unitName = moveInOUTSR.Unit__r.Name;
            this.communityName = moveInOUTSR.Unit__r.Project__r.OA_Community_Name__c;
            this.precinctName = moveInOUTSR.Unit__r.BuildingSectionName__r.Precint_Name__c;
            this.srNo = moveInOUTSR.Name;
            this.CommunityManager = CustomerMoveInServiceRequestHandler.getCommunityManagerNames(moveInOUTSR);
            
        }
    }
}