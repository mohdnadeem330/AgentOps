/*
*********************************************************
Apex Class Name    : CaseTriggerHandlerNew
Created Date       : 
@description       : Class to handle case Trigger metadata 
@author            : 
Modification Log:
Ver   Date         Author                Modification
1.0   27-06-2025                         Initial Version
*********************************************************
*/
public without sharing class CaseTriggerMetadata {
    /*
    *********************************************************
    @Method Name    : CaseRecordTypeWrapper
    @author         : 
    @description    : Wrapper class to hold case recordtype ids
    @param          : 
    @return         : 
    ********************************************************
    */
    public static CaseRecordTypeWrapper recTypeInstance = null;
    public class CaseRecordTypeWrapper {        

        public Id amcRTypeID;
        public Id feedbackRTypeID;
        public Id standardRTypeID;
        public Id corporateLegalRTypeID;
        public Id cafmRecordTypeId;
        public Id dlpRTypeID;
        public Id devControlRTypeID;
        public Id homeFinanceRTId;
        public Id queriesRTypeID;
        public Id complaintsRTypeID;        
        public Id requestsRTypeID;
        public Id ecssQueriesRTypeID;
        public Id ecssComplaintsRTypeID;
        public Id ecssMaintenanceRTypeID;
        public Id DmrecordtypeId;

        private CaseRecordTypeWrapper(Map<String, Id> recordMap) {
            this.amcRTypeID            = recordMap.get(System.Label.AMCRecTypeLabel);
            this.feedbackRTypeID       = recordMap.get(Constants.FEEDBACK_CASE_RT);
            this.standardRTypeID       = recordMap.get(Constants.STANDARD_CASE_RT);
            this.corporateLegalRTypeID = recordMap.get(Constants.LEGAL_CASE_RT);
            this.cafmRecordTypeId      = recordMap.get(Constants.DISTRICT_MANAGEMENT_CAFM);
            this.dlpRTypeID            = recordMap.get(Constants.DLP_CASE_RT);
            this.DmrecordtypeId        = recordMap.get(Constants.DISTRICT_MANAGEMENT);
            this.devControlRTypeID     = recordMap.get(Constants.Development_Control);
            this.homeFinanceRTId       = recordMap.get(Constants.Home_Finance);
            this.queriesRTypeID          = recordMap.get(Constants.Queries);
            this.complaintsRTypeID       = recordMap.get(Constants.Complaints);
            this.requestsRTypeID         = recordMap.get(Constants.Requests);
            this.ecssQueriesRTypeID      = recordMap.get(Constants.ECSSQueries);
            this.ecssComplaintsRTypeID   = recordMap.get(Constants.ECSSComplaints);
            this.ecssMaintenanceRTypeID  = recordMap.get(Constants.ECSSMaintenance);
        }        
    }    

    // Public method to get instance (creates it only once)
    public static CaseRecordTypeWrapper getRTypeInstance(Map<String, Id> recordMap) {
        if (CaseTriggerMetadata.recTypeInstance == null) {
            CaseTriggerMetadata.recTypeInstance = new CaseRecordTypeWrapper(recordMap);
        }
        return CaseTriggerMetadata.recTypeInstance;
    }
    /*
    *********************************************************
    @Method Name    : QueueWrapper
    @author         : 
    @description    : Wrapper class to hold case recordtype ids
    @param          : 
    @return         : 
    ********************************************************
    */
    public static QueueWrapper queueWrInstance = null;
    public class QueueWrapper {
        public Group onboarding;
        public Group surveyQueue;
        public Group dlpQueue;
        public Group postSalesCaseQueue;
        public Group admCommunityCaseQueue;
        public Group admRegCaseQueue;
        public Group commsRegCaseQueue;
        public Group homeFinanceQueue;
        public Group goldenVisaCaseQueue;
        public Group postSaleQueue;
        public Group cmFinanceQueue;
        public Group newSalesQueue;
        public Group handoverCaseQueue;
        public Group caseHandlingQueue;
        public Group devControlQueue; 

        // Constructor
        public QueueWrapper(Map<String, Group> queueMap) {
            this.onboarding              = queueMap.get(Constants.Customer_Onboarding_Queue);
            this.surveyQueue             = queueMap.get(Constants.SURVEY_QUEUE);
            this.dlpQueue                = queueMap.get(Constants.DLP_QUEUE);
            this.postSalesCaseQueue      = queueMap.get(Constants.POST_SALE_QUEUE);
            this.admCommunityCaseQueue   = queueMap.get(Constants.ADM_Community);
            this.admRegCaseQueue         = queueMap.get(Constants.ADM_Registration);
            this.commsRegCaseQueue       = queueMap.get(Constants.Comms_Queue);
            this.homeFinanceQueue        = queueMap.get(Constants.Home_Finance_Queue);
            this.goldenVisaCaseQueue     = queueMap.get(Constants.Golden_Visa_RT);
            this.postSaleQueue           = queueMap.get(Constants.POST_SALE_QUEUE);
            this.cmFinanceQueue          = queueMap.get(Constants.CM_FINANCE_QUEUE); 
            this.newSalesQueue           = queueMap.get(Constants.CM_NEW_SALE_QUEUE);
            this.handoverCaseQueue       = queueMap.get(Constants.HANDOVER_RT);
            this.caseHandlingQueue       = queueMap.get(Constants.CASE_HANDLING_QUEUE);
            this.devControlQueue         = queueMap.get(Constants.DEV_CONTROL_GROUP);                       
        }
    }
    // Public method to get instance (creates it only once)
    public static QueueWrapper getqueueWrInstance(Map<String, Group> queueMap) {
        if (CaseTriggerMetadata.queueWrInstance == null) {
            CaseTriggerMetadata.queueWrInstance = new QueueWrapper(queueMap);
        }
        return CaseTriggerMetadata.queueWrInstance;
    }
    //Queue Names Set
    public static Set<String> queuenames = new Set <String> {
        Constants.SURVEY_QUEUE, 
        Constants.DLP_QUEUE,
        Constants.POST_SALE_QUEUE,
        Constants.ADM_Community,
        Constants.ADM_Registration,
        Constants.Comms_Queue,
        Constants.Home_Finance_Queue,
        Constants.CM_FINANCE_QUEUE,
        Constants.Customer_Onboarding_Queue, 
        Constants.CM_NEW_SALE_QUEUE,
		Constants.HANDOVER_RT,
        Constants.CASE_HANDLING_QUEUE,
        Constants.DEV_CONTROL_GROUP,
        Constants.Golden_Visa_RT
    }; 
    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames);
    //Skip RecordTypes
    public static Set<Id> skipCustomerSupportEcssRecordTypeIds = new Set<Id>{
        rtWrapper.queriesRTypeID,
        rtWrapper.complaintsRTypeID,
        rtWrapper.requestsRTypeID,
        rtWrapper.ecssQueriesRTypeID,
        rtWrapper.ecssComplaintsRTypeID,
        rtWrapper.ecssMaintenanceRTypeID
    };
    //Skip RecordTypes
    public static Set<Id> skipCustomerSupportRecordTypeIds = new Set<Id>{
        rtWrapper.queriesRTypeID,
        rtWrapper.complaintsRTypeID,
        rtWrapper.requestsRTypeID
    };

    public static final Set < String > errorMessages = new Set < String > {
        Constants.CASE_ACCOUNT_RELATED_TO_UNIT_VALIDATION,
        Constants.DLP_CUSTOMER_MOBILE_NUMBER_VALIDATION,
        Constants.CASE_TASKS_VALIDATION,
        Constants.CASE_FIRST_COME_FIRST_SERVE_ERROR,
        Constants.TRANSFER_CASES_ERROR
    };
}