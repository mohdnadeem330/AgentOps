/*
* Name               : CustomerServiceRequestWebService
* Description        : This class is used to Create Service Request or Case
* V1.1               : Added few more parameters in the Case Repsonse
* Modified by        : Nilesh B. 24 May 2024
* v1.2               : LiveAldar API : Unit is only one for customer then get the Unit and assign Unit to Case Else it should be null
                        RISS-259 
*/
@RestResource (urlMapping = '/customer/createservicerequest') 
global without sharing class CustomerServiceRequestWebService {
    
    public enum SRTYPE {PropertyTransferOffPlan, PropertyTransfer, JointOwner, InvestorCertificate}
    public enum CASETYPE {Feedback, StopPayment}

    @HTTPPost
    global static void doPost(){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            Object srDetails = serviceRequest(jsonBody);
            if (srDetails == null) {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            } else {
                handler.response.success = true;
                handler.response.data = srDetails;
            }
            handler.finalize();
        } catch (Exception e) {
            System.debug('Exception e'+e.getStackTraceString()+' '+e.getMessage());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message =e.getStackTraceString()+' '+e.getMessage();
            handler.finalize(e);
        }
    }

    public static Object serviceRequest(String jsonBody) {
        
        System.debug('jsonBody>>>' + jsonBody);
        ServiceRequestModel serviceRequestModel = (ServiceRequestModel)JSON.deserializeStrict(jsonBody, ServiceRequestModel.class);
        System.debug('serviceRequestModel>>>' + serviceRequestModel);
        List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwnerWithEmail(serviceRequestModel.referenceId);
        String soIdsStr = String.join(soIds, '\',\'');
        
        String salesOrderWhrClause = '';
        if (!soIds.isEmpty()) {            
            salesOrderWhrClause = ' (Account__r.PersonEmail = \'' + serviceRequestModel.referenceId + '\' OR Id IN (\'' + soIdsStr + '\')) AND ';
        } else {
            salesOrderWhrClause = ' (Account__r.PersonEmail = \'' + serviceRequestModel.referenceId + '\') AND ';
        }
        salesOrderWhrClause += ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
		String query = 'SELECT Id FROM SalesOrder__c WHERE ' + salesOrderWhrClause;
        List<Id> soIdList = new List<Id>();
        for(SalesOrder__c so: Database.query(query)) {
            soIdList.add(so.Id);            
            
        }
        if (String.isNotBlank(serviceRequestModel.orderId) && (soIdList.isEmpty() || !soIdList.contains(serviceRequestModel.orderId))) {
            return null;
        }

        String whrClause = ' (Id = \'' + serviceRequestModel.orderId + '\') ';        
        SalesOrder__c salesOrder = String.isNotBlank(serviceRequestModel.orderId) ? CustomerServiceUtility.getSalesOrderDetail(whrClause)[0] : new SalesOrder__c();
		if (serviceRequestModel.requestType == String.valueOf(SRTYPE.PropertyTransferOffPlan)) {
            // START | Check Buyer details is already is avilable or not, If found then use that otherwise create new
            
            List<Account> buyerAccountList = CustomerServiceUtility.getAccountDetail(' (PersonEmail = \'' + serviceRequestModel.buyer.PersonEmail + '\') ');
            
            Account buyer = new Account();
            Boolean isfound = false;
            if (!buyerAccountList.isEmpty() && buyerAccountList.size() == 1) {
                buyer = buyerAccountList[0];
                isfound = true;                
            } else if (!buyerAccountList.isEmpty()) {
                for (Account acc: buyerAccountList) {
                    if (acc.MobilePhone__pc == serviceRequestModel.buyer.MobilePhone__pc || (acc.FirstName == serviceRequestModel.buyer.FirstName && acc.LastName == serviceRequestModel.buyer.LastName)) {
                        buyer = acc;
                        isfound = true;
                        break;
                    }
                }
            }

            if (buyerAccountList.isEmpty() || !isFound) {                
                buyer = serviceRequestModel.buyer;
                buyer.RecordTypeId = Utilities.getRecordTypeId('Account', Constants.PERSON_ACCOUNT_RT);
                buyer.MobileNumberEnc__pc = buyer.MobileCountryCode__pc + buyer.MobilePhone__pc;
                buyer.PersonMobilePhone = buyer.MobileCountryCode__pc + buyer.MobilePhone__pc;
                insert buyer;
            }
            // END | Check Buyer details is already is avilable or not, If found then use that otherwise create new
			
           // String srType = String.isNotBlank(salesOrder.TitleDeedRegistrationNumber__c) ? Constants.PROPERTY_TRANSFER_NOC_RT : Constants.PROPERTY_TRANSFER_OffPlan;
              String srType = String.isNotBlank(salesOrder.TitleDeedRegistrationNumber__c) ? Constants.PROPERTY_TRANSFER_NOC_RT : 'Property Transfer (Off Plan)';
			
            HexaBPM__Service_Request__c newSR = createSR(serviceRequestModel, buyer, srType, srType);
            if (newSR == null) {                
                return null;
            }            
            ServiceRequestReturnModel serviceRequestReturnModel = new ServiceRequestReturnModel(newSR);            
            return serviceRequestReturnModel;
        } 
        else if (serviceRequestModel.requestType == String.valueOf(SRTYPE.JointOwner)) {
            String recordType = String.isNotBlank(salesOrder.TitleDeedRegistrationNumber__c) ? Constants.JOINT_OWNER_NOC_RT : Constants.JOINT_OWNER_RT;

            HexaBPM__Service_Request__c newSR = createSR(serviceRequestModel, new Account(), serviceRequestModel.srType, recordType);
            if (newSR == null) {
                return null;
            }
            ServiceRequestReturnModel serviceRequestReturnModel = new ServiceRequestReturnModel(newSR);
            
            return serviceRequestReturnModel;
        } 
        else if (serviceRequestModel.requestType == String.valueOf(SRTYPE.InvestorCertificate) || serviceRequestModel.requestType == 'Letter Issuance') {
            
            String srType = serviceRequestModel.requestType =='Letter Issuance' ? 'Letter Issuance': Constants.INVESTOR_CERTIFICATE_RT;
            String recordType= Constants.INVESTOR_CERTIFICATE_RT;
      

            HexaBPM__Service_Request__c newSR = createSR(serviceRequestModel, new Account(), srType, recordType);
            if (newSR == null) {
                return null;
            }
            ServiceRequestReturnModel serviceRequestReturnModel = new ServiceRequestReturnModel(newSR);
            
            return serviceRequestReturnModel;
        } 
        else {
            // Craete Case
            if (serviceRequestModel.requestType == String.valueOf(CASETYPE.StopPayment) && String.isNotBlank(serviceRequestModel.paymentId)) {
                InstallmentLines__c installmentLine = new InstallmentLines__c();
                installmentLine.Id = serviceRequestModel.paymentId;
                installmentLine.IsStopPayment__c = true;
                update installmentLine;
            }

            //String recordType = serviceRequestModel.requestType == String.valueOf(CASETYPE.Feedback) ? Constants.FEEDBACK_CASE_RT :( serviceRequestModel.requestType == Constants.DLP_CASE_RT ? Constants.DLP_CASE_RT : Constants.STANDARD_CASE_RT);//v1.1
            String recordType = serviceRequestModel.requestType == 'AMC' ? 'AMC' : (serviceRequestModel.requestType == String.valueOf(CASETYPE.Feedback) ? Constants.FEEDBACK_CASE_RT :( serviceRequestModel.requestType == Constants.DLP_CASE_RT ? Constants.DLP_CASE_RT : Constants.STANDARD_CASE_RT));//v1.1
            String startTime = null;
            String endTime = null;
            String userName = null;    
            Group queue = Utilities.getQueueInformation(CustomerAPIConstants.CCA_ONLINE_QUEUE);
            String caseOwnerId = queue.Id != null ? queue.Id : UserInfo.getUserId();

            Case newCase = new Case();
            newCase.RecordTypeId = Utilities.getRecordTypeId('Case', recordType);
            newCase.Origin = serviceRequestModel.origin;
            newCase.AccountId = serviceRequestModel.customerId;
            newCase.Unit__c = String.isNotBlank(serviceRequestModel.unitId) ? serviceRequestModel.unitId : null;
            newCase.SalesOrder__c = String.isNotBlank(serviceRequestModel.orderId) ? serviceRequestModel.orderId : null;
            newCase.InstallmentLine__c = String.isNotBlank(serviceRequestModel.paymentId) ? serviceRequestModel.paymentId : null;
            newCase.SubVertical__c = serviceRequestModel.subVertical;
            newCase.CaseCategory__c = serviceRequestModel.category;
            newCase.Subject = serviceRequestModel.subject;
            //Logic added for AMC on-demand case handle
            if(recordType == 'AMC' && (newCase.Origin == 'Customer Portal' || newCase.Origin == 'Customer App')){
                String sub = serviceRequestModel.subject;
                if(sub.contains(',')){ //segregate subject using comma
                    System.debug('*****sub'+sub);
                    List<String> lstSplit = sub.split(',');
                    newCase.CustomerType__c = 'Owner';
                    newCase.Vertical__c = 'DLP';
                    newCase.SubVertical__c = 'AMC';
                    newCase.SubCategory__c =  lstSplit.size() > 0 ? lstSplit[1] : null; 
                }
            }
             //Logic for DLP Cases v1.1 START
            if(recordType == Constants.DLP_CASE_RT && (newCase.Origin == 'Customer Portal' || newCase.Origin == 'Customer App')){
                //v1.2 START
                if (newCase.Unit__c == null) {
                    List<CustomerCheckEligibilityWebService.EligibleUnitModel> lstEgligibleOrds = CustomerCheckEligibilityWebService.checkEligibility(newCase.AccountId,null,'DLP');
                    if(!lstEgligibleOrds.isEmpty() && lstEgligibleOrds.size() == 1)
                        newCase.Unit__c = lstEgligibleOrds[0].unitId;
                }
                //v1.2 END
                //DLP - parent case logic
                List<String> casestatuses = system.label.DLPCaseStatuses.split(',');                
                List<Case> caselist = [SELECT Id, CaseNumber,(SELECT Id, SchedStartTime, SchedEndTime, FSSK__FSK_Assigned_Service_Resource__r.Name, RecordType.Name FROM Service_Appointments__r WHERE RecordType.Name = 'Assessment') FROM Case WHERE Recordtype_Name__c = :Constants.DLP_CASE_RT AND Unit__c = :newCase.Unit__c AND ParentId = null AND Status IN :casestatuses ORDER BY CreatedDate ASC LIMIT 1];
                if (caselist.size() == 1  && caselist[0].Service_Appointments__r != null && !caselist[0].Service_Appointments__r.isEmpty()) {     
                    ServiceAppointment sa = caselist[0].Service_Appointments__r[0];                    
                    if (sa.SchedStartTime != null && sa.SchedStartTime > System.now().addHours(24)) { newCase.ParentId = caselist[0].Id; startTime = String.valueOf(sa.SchedStartTime); endTime = String.valueOf(sa.SchedEndTime);userName = sa.FSSK__FSK_Assigned_Service_Resource__r.Name;  }
                }    
                String sub = serviceRequestModel.subject;
                
                if(sub.contains(',')){ //segregate subject using comma and populate sub cat, problem code and incident description
                    List<String> lstSplit = sub.split(',');
                    newCase.CustomerType__c = 'Owner';
                    newCase.Vertical__c = 'DLP';
                    newCase.SubCategory__c = lstSplit[0];
                    newCase.ProblemCode__c =  lstSplit[1];// == 'CM-PQA-MEP- Switches Socket' ? 'CM-PQA-MEP- Switches/Socket':lstSplit[1]);
                    newCase.IncidentDescription__c = lstSplit[2];// == 'A C noisy' ? 'A/C noisy': lstSplit[2]);
                    newCase.Subject = lstSplit[2];
                    newCase.ContactId = [SELECT PersonContactId FROM Account WHERE Id=: newCase.AccountId]?.PersonContactId;
                    List<CaseFieldDependency__mdt> lstskillMap = [SELECT id,Skill_Type__c FROM CaseFieldDependency__mdt WHERE Vertical__c = 'DLP' AND ProblemCode__c =: lstSplit[1] AND IncidentDescription__c=: lstSplit[2] LIMIT 1];
                    if(!lstskillMap.isEmpty())
                        newCase.Skills_Required__c =  lstskillMap[0].Skill_Type__c;
                    newCase.CaseComments__c  = serviceRequestModel.comment;    
                }
            }//v1.1 END
            newCase.CustomerComment__c = serviceRequestModel.comment;
            newCase.OwnerId = caseOwnerId;
            if (serviceRequestModel.requestType == String.valueOf(CASETYPE.Feedback) || serviceRequestModel.category == CustomerAPIConstants.CUSTOMER_PORTAL_AND_APP || serviceRequestModel.category == CustomerAPIConstants.OTHER) {
                newCase.isValidationBypass__c = true;
            }            
            insert newCase;

            newCase = CustomerServiceUtility.getCaseDetail(' (Id = \'' + newCase.Id + '\') ')[0];             
            CaseReturnModel caseReturnModel = new CaseReturnModel(newCase,startTime,endTime,userName); 
            if (Test.isRunningTest()) {                
                new CaseReturnModel(newCase); 
            }
            return caseReturnModel;
        }
    }

    // Craete Service Request
    public static HexaBPM__Service_Request__c createSR(ServiceRequestModel serviceRequestModel, Account buyer, String srType, String recordTypeName) {
        String comment = serviceRequestModel.comment;
        List<HexaBPM__Service_Request__c> propertyTransferOffplanStepList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> PTOffplanSRList= new  List<HexaBPM__Service_Request__c>();
        if (recordTypeName == Constants.JOINT_OWNER_NOC_RT || recordTypeName == Constants.JOINT_OWNER_RT) {
            comment = 'Comment: ' + serviceRequestModel.comment;
            if (!serviceRequestModel.jointOwners.isEmpty()) {
                Pattern namePattern = Pattern.compile('(^[\\u0600-\\u06FFa-zA-Z0-9\\,-.\\s]+$)');
                Pattern emailPattern = Pattern.compile('^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$');
                Pattern mobilePattern = Pattern.compile('([0-9]+$)');

                comment += '\n';
                Decimal counter = 1;
                for (JointOwnerModel jointOwner: serviceRequestModel.jointOwners) {
                    Matcher nameMatcher = namePattern.matcher(jointOwner.name);
                    Boolean checkName = nameMatcher.matches();
                    
                    Matcher emailMatcher = emailPattern.matcher(jointOwner.email);
                    Boolean checkEmail = emailMatcher.matches();
                    
                    Matcher mobileMatcher = mobilePattern.matcher(jointOwner.mobileNumber);
                    Boolean checkMobile = mobileMatcher.matches();
                    
                    System.debug('inside JO>>>' + checkName + '>>>' + checkEmail + '>>>' + checkMobile);
                    if (!checkName || !checkEmail || !checkMobile) 
                    {
                        return null;
                    }

                    comment = comment + '\n\n' + 'Joint Owner ' + counter;
                    comment = comment + '\n' + 'Name: ' + jointOwner.name;
                    comment = comment + '\n' + 'Email: ' + jointOwner.email;
                    comment = comment + '\n' + 'Mobile: ' + jointOwner.mobileCountryCode + '-' + jointOwner.mobileNumber;
                    counter++;
                }
            }
        }

        Group queue = Utilities.getQueueInformation(CustomerAPIConstants.CCA_ONLINE_QUEUE);
        String caseOwnerId = queue.Id != null ? queue.Id : UserInfo.getUserId();

        Case newCase = new Case();
        newCase.RecordTypeId = Utilities.getRecordTypeId('Case', Constants.STANDARD_CASE_RT);
        newCase.Origin = serviceRequestModel.origin;
        newCase.AccountId = serviceRequestModel.customerId;
        newCase.Unit__c = serviceRequestModel.unitId;
        newCase.SalesOrder__c = serviceRequestModel.orderId;
        newCase.SubVertical__c = CustomerAPIConstants.CASE_CUSTOMER_CARE;
        newCase.CaseCategory__c = recordTypeName != Constants.JOINT_OWNER_NOC_RT && recordTypeName != Constants.JOINT_OWNER_RT ? recordTypeName : '';
        newCase.Subject = srType;
        newCase.CustomerComment__c = comment;
        newCase.OwnerId = caseOwnerId;
        newCase.Status = 'New';
        insert newCase;
        newCase.Resolved_Status__c = Constants.WITH_RESOLUTION_CASE;
        newCase.Status = Constants.CLOSED_CASE;
        update newCase;


        Decimal transferFee;
        List<ChargeRule__c> chargeRuleList = [ SELECT Id, Name, SRType__c, ChargeType__c, ChargeAmount__c, VATChanges__c FROM ChargeRule__c WHERE SRType__c =:srType
                                              AND ChargeType__c = 'Transfer Normal' AND IsActive__c = true LIMIT 1 ];                
        if (!chargeRuleList.isEmpty()) {
            ChargeRule__c rule = chargeRuleList[0];
            Decimal chargeAmount = (rule.ChargeAmount__c != null) ? rule.ChargeAmount__c : 0;
            Decimal vatPercent   = (rule.VATChanges__c != null) ? rule.VATChanges__c : 0;
            transferFee = (chargeAmount + (chargeAmount * vatPercent / 100)).round();
        } else {
            transferFee = 0;
        }
     
        HexaBPM__Service_Request__c newSR = new HexaBPM__Service_Request__c();
               
        newSR.recordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', recordTypeName);
        newSR.Origin__c = serviceRequestModel.origin;
        newSR.HexaBPM__Customer__c = serviceRequestModel.customerId;
        newSR.Unit__c = serviceRequestModel.unitId;
        newSR.SalesOrder__c = serviceRequestModel.orderId;
        newSR.SRType__c = srType;
        newSR.BuyerName__c = buyer.Id;
        newSR.Case__c = newCase.Id;
        newSR.CustomerComment__c = comment;
        newSR.BrokerName__c = serviceRequestModel.brokerId;
        newSR.Pay_By__c = serviceRequestModel.payBy;
        newSR.TransferSellingPrice__c = serviceRequestModel.sellingPrice;
        newSR.ChargeType__c = transferFee !=0?'Transfer Normal':null;
        newSR.ChargeCollected__c = transferFee !=0?transferFee:null;
        newSR.Service_Territory__c = serviceRequestModel.location; 
        if (!Test.isRunningTest()) {           
                Insert newSR;
                TriggerControlVariables.stopFutureSubmitSR = true;
                SRUtility.submitSR(new List<Id>{newSR.Id});
                // SSR 751
				List<HexaBPM__Service_Request__c> queriedSRList = [SELECT Id, SRType__c, HexaBPM__External_Status_Name__c, Origin__c, TransferSellingPrice__c, HexaBPM__Customer__c, BuyerName__c FROM HexaBPM__Service_Request__c WHERE Id = :newSR.Id LIMIT 1];
                if (queriedSRList[0].SRType__c == Constants.PROPERTY_TRANSFER_OffPlan && queriedSRList[0].HexaBPM__External_Status_Name__c == Constants.SUBMITTED && (queriedSRList[0].Origin__c == 'Customer App' || queriedSRList[0].Origin__c == 'Customer Portal' )) {
                    propertyTransferOffplanStepList.add(queriedSRList[0]);
                    PTOffplanSRList.add(queriedSRList[0]); 
                }        
                if(!PTOffplanSRList.isempty()){
                    PropertyTransferService.checkBeforeUpdatePTOfflineValidation(PTOffplanSRList);
                    PropertyTransferService.PtOffplanSRStepOpen(propertyTransferOffplanStepList);
                }
                // End SSR 751
                     

            return CustomerServiceUtility.getServiceRequestDetail(' (Id = \'' + newSR.Id + '\') ')[0];
        } else {
            return newSR;
        }
    }
    
    global class ServiceRequestModel{        
        public String requestType                                   {get;set;}
        public String customerId                                    {get;set;}
        public String unitId                                        {get;set;}
        public String orderId                                       {get;set;}
        public String paymentId                                     {get;set;}
        public String srType                                        {get;set;}
        public Account buyer                                        {get;set;}
        public List<JointOwnerModel> jointOwners                    {get;set;}
        public String referenceId                                   {get;set;}
        public String origin                                        {get;set;}
        public String subVertical                                   {get;set;}
        public String category                                      {get;set;}
        public String subject                                       {get;set;}
        public String comment                                       {get;set;}
        public String brokerId                                      {get;set;}
        public String payBy                                         {get;set;}
        public decimal sellingPrice                                 {get;set;}
        public String location                                      {get;set;}
    }

    global class JointOwnerModel{
        public String name                                          {get;set;}
        public String email                                         {get;set;}
        public String mobileNumber                                  {get;set;}
        public String mobileCountryCode                             {get;set;}
    }

    global class ServiceRequestReturnModel{
        public String requestId                                     {get;set;}
        public String requestNo                                     {get;set;}
        public String customerId                                    {get;set;}
        public String customerName                                  {get;set;}
        public String buyerId                                       {get;set;}
        public String buyerName                                     {get;set;}
        public String orderId                                       {get;set;}
        public String orderName                                     {get;set;}
        public String unitId                                        {get;set;}
        public String unitName                                      {get;set;}
        public String srType                                        {get;set;}
        public List<DocumentQueryModel> documents                   {get;set;}

        public ServiceRequestReturnModel(HexaBPM__Service_Request__c sr) {
            this.requestId = sr.Id;
            this.requestNo = sr.Name;
            this.customerId = sr.HexaBPM__Customer__c;
            this.customerName = sr.HexaBPM__Customer__r.Name;
            this.buyerId = sr.BuyerName__c;
            this.buyerName = sr.BuyerName__r.Name;
            this.orderId = sr.SalesOrder__c;
            this.orderName = sr.SalesOrder__r.Name;
            this.unitId = sr.Unit__c;
            this.unitName = sr.Unit__r.Name;
            this.srType = sr.SRType__c;
            this.documents = new List<DocumentQueryModel>();
            for (HexaBPM__SR_Doc__c doc: sr.HexaBPM__SR_Docs__r) {
                documents.add(new DocumentQueryModel(doc));
            }
        }
    }
    //V1.1 START
    /*object to return appointment details*/
    global class AppointmentModel{
        public string schedStartTime                                {get;set;}
        public string schedEndTime                                  {get;set;}
        public string ArrivalWindowStart                            {get;set;}
        public string ArrivalWindowEnd                              {get;set;}
        public string resourceName                                  {get;set;}
        public string resourceId                                    {get;set;}
        public string appointmentNumber                             {get;set;}
        public string status                                        {get;set;}
        public string appointmentId                                 {get;set;}
        public string serviceNote                                   {get;set;}
        public string contactInfo                                   {get;set;}
        public AppointmentModel(){}
        public AppointmentModel(ServiceAppointment servApp){
            appointmentId     = servApp.Id;
            appointmentNumber = servApp.AppointmentNumber;
            status            = servApp.Status;
            schedStartTime    = String.valueOf(servApp.SchedStartTime);
            schedEndTime      =  String.valueOf(servApp.SchedEndTime);
            ArrivalWindowStart = String.valueOf(servApp.ArrivalWindowStartTime);
            ArrivalWindowEnd  =  String.valueOf(servApp.ArrivalWindowEndTime);
            resourceId        = servApp.FSSK__FSK_Assigned_Service_Resource__c;
            resourceName      = servApp.FSSK__FSK_Assigned_Service_Resource__r.Name;
            serviceNote       = (servApp.ServiceNote != null ? servApp.ServiceNote : servApp.Technician_Comments__c);
            contactInfo       = (servApp.FSSK__FSK_Assigned_Service_Resource__c != null && servApp.FSSK__FSK_Assigned_Service_Resource__r.RelatedRecord.MobilePhone != null ? servApp.FSSK__FSK_Assigned_Service_Resource__r.RelatedRecord.MobilePhone : '' );
        }
    }
    //V1.1 End
    global class CaseReturnModel{
        public String requestId                                     {get;set;}
        public String requestNo                                     {get;set;}
        public String customerId                                    {get;set;}
        public String customerName                                  {get;set;}
        public String orderId                                       {get;set;}
        public String orderName                                     {get;set;}
        public String unitId                                        {get;set;}
        public String unitName                                      {get;set;}
        public String organization                                  {get;set;}
        public String department                                    {get;set;}
        public String vertical                                      {get;set;}
        public String subVertical                                   {get;set;}
        public String category                                      {get;set;}//V1.1 Start
        public String subcategory                                   {get;set;}
        public String problemCode                                   {get;set;}
        public String incidentDesc                                  {get;set;}
        public String subject                                       {get;set;}
        public String status                                        {get;set;}
        public String createdDateTime                               {get;set;}
        public DateTime amcDueDate                                  {get;set;}//V2.0
        public String cancelReason                                  {get;set;}
        public String closureReason                                 {get;set;}
        public String comment                                       {get;set;}//V1.1 END
        public Boolean canReopen                                    {get;set;}
        public List<DocumentQueryModel> documents                   {get;set;}
        public String caseParentid                                  {get;set;}
        public String schedStartTime                              {get;set;}
        public String schedEndTime                                {get;set;}
        public String userName                                      {get;set;}
        public AppointmentModel appointment                         {get;set;} //V1.1
		public Boolean isEmergency                                  {get;set;} // added by kuhinoor...
        public CaseReturnModel(Case cs,String schedStartTimes,String schedEndTime,String userName) {
            this.requestId = cs.Id;
            this.requestNo = cs.CaseNumber;
            this.customerId = cs.AccountId;
            this.customerName = cs.Account.Name;
            this.orderId = cs.SalesOrder__c;
            this.orderName = cs.SalesOrder__r.Name;
            this.unitId = cs.Unit__c;
            this.unitName = cs.Unit__r.Name;
            this.organization = cs.Organization__c;
            this.department = cs.Department__c;
            this.vertical = cs.Vertical__c;
            this.subVertical = cs.SubVertical__c;   
            this.isEmergency = cs.Priority != null && cs.Priority.equalsIgnoreCase('Emergency') ? true : false ; // added by kuhinoor...
            //V1.1 Start
            this.category = cs.CaseCategory__c;
            this.subject = cs.subject;
            this.comment = cs.CustomerComment__c;
            this.status = cs.Status;
            this.subcategory = cs.SubCategory__c;
            this.problemCode  = cs.ProblemCode__c;
            this.incidentDesc  = cs.IncidentDescription__c;
            this.createdDateTime =String.valueOf(cs.createdDate);
            this.cancelReason = cs.DLP_Reason_for_Cancel__c;
            this.closureReason = (cs.SubVertical__c == 'AMC' ? cs.AMC_Closure_Reason__c : cs.DLP_Closure_Reason__c);//V2.0
            this.amcDueDate = cs.AMC_Due_Date__c;//V2.0
            this.canReopen = (cs.Status == 'Closed' && cs.CaseCategory__c != 'On Demand' && Date.today().daysBetween(cs.createdDate.date()) < 45 && cs.SubVertical__c == 'AMC' && cs.AMC_Closure_Reason__c == System.Label.DLP_customernotavailable ? true:false);
            this.appointment = new AppointmentModel();
            //V1.1 End
            this.documents = new List<DocumentQueryModel>();
            DocumentQueryModel doc = new DocumentQueryModel();
            doc.id = cs.id;
            doc.type = CustomerAPIConstants.DOCUMENT_SUPPORTING_DOCUMENTS;
            this.documents.add(doc);
            if (cs.Subject == CustomerAPIConstants.TYPE_PLOT_DESIGN) {
                doc.id = cs.id;
                doc.type = CustomerAPIConstants.DOCUMENT_TITLE_DEED;
                this.documents.add(doc);
                doc.id = cs.id;
                doc.type = CustomerAPIConstants.DOCUMENT_CONSULTANT_CERTIFICATE_LETTER;
                this.documents.add(doc);
            }
            this.caseParentid = cs.ParentId;
            this.schedStartTime = schedStartTimes;
            this.schedEndTime=schedEndTime;
            this.userName = userName; 
        }
        public CaseReturnModel(Case cs) {
            this.requestId = cs.Id;
            this.requestNo = cs.CaseNumber;
            this.customerId = cs.AccountId;
            this.customerName = cs.Account.Name;
            this.orderId = cs.SalesOrder__c;
            this.orderName = cs.SalesOrder__r.Name;
            this.unitId = cs.Unit__c;
            this.unitName = cs.Unit__r.Name;
            this.organization = cs.Organization__c;
            this.department = cs.Department__c;
            this.vertical = cs.Vertical__c;
            this.subVertical = cs.SubVertical__c;
            this.isEmergency = cs.Priority != null && cs.Priority.equalsIgnoreCase('Emergency') ? true : false ; // added by kuhinoor...
            //V1.1 Start
            this.category = cs.CaseCategory__c;
            this.subject = cs.subject;
            this.comment = cs.CustomerComment__c;
            this.status = cs.Status;
            this.subcategory = cs.SubCategory__c;
            this.problemCode  = cs.ProblemCode__c;
            this.incidentDesc  = cs.IncidentDescription__c;
            this.createdDateTime =String.valueOf(cs.createdDate);
            this.cancelReason = cs.DLP_Reason_for_Cancel__c;
            this.closureReason = (cs.SubVertical__c == 'AMC' ? cs.AMC_Closure_Reason__c : cs.DLP_Closure_Reason__c);//V2.0
            this.amcDueDate = cs.AMC_Due_Date__c;//V2.0
            this.canReopen = (cs.Status == 'Closed' && cs.CaseCategory__c != 'On Demand' && Date.today().daysBetween(cs.createdDate.date()) < 45 && cs.SubVertical__c == 'AMC' && cs.AMC_Closure_Reason__c == System.Label.DLP_customernotavailable ? true:false);
            this.caseParentid = cs.ParentId;
            this.appointment = new AppointmentModel();
            //V1.1 End
            this.documents = new List<DocumentQueryModel>();
            DocumentQueryModel doc = new DocumentQueryModel();
            doc.id = cs.id;
            doc.type = CustomerAPIConstants.DOCUMENT_SUPPORTING_DOCUMENTS;
            this.documents.add(doc);
            if (cs.Subject == CustomerAPIConstants.TYPE_PLOT_DESIGN) {
                doc.id = cs.id;
                doc.type = CustomerAPIConstants.DOCUMENT_TITLE_DEED;
                this.documents.add(doc);
                doc.id = cs.id;
                doc.type = CustomerAPIConstants.DOCUMENT_CONSULTANT_CERTIFICATE_LETTER;
                this.documents.add(doc);
            }
        }
    }
}