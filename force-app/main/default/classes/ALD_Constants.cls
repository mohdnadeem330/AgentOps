public class ALD_Constants {
    //GENERIC ERROR TITLE-START
    public static String SOMETHING_WRONG = 'Something Went Wrong!';
    //GENERIC ERROR TITLE-END
    //START - BANK INTEGRATION - VA - SARAVANAN_SEKAR
    public static String BANK_COLLECTION = 'Collection';
    public static Integer ALDVA_SUCCESS_CODE = 200;
    public static Integer ALDVA_FAILED_CODE_500 = 500;
    public static Integer ALDVA_FAILED_CODE_504 = 504;
    public static String ALDVA_INTEGRATION = 'virtualAccountIntegration';
    public static String ALDVA_CREATION = 'Creation';
    public static String ALDVA_CANCELLATION = 'Cancellation';
    public static string ALDVA_STATUS_AVAILABLE = 'Available';
    public static string ALDVA_STATUS_CANCELLED = 'Cancelled';
    public static string ALDVA_STATUS_TRANSFERRED = 'Transferred';
    public static string ALDVA_STATUS_USED = 'Used';
    public static string ADCB_BANK = 'ADCB';
    public static string FAB_BANK = 'FAB';
    public static string ABUDHABI_COMMERCIAL_BANK = 'Abu Dhabi Commercial Bank';
    public static string FIRST_ABUDHABI_BANK = 'First Abu Dhabi Bank';
    //END - BANK INTEGRATION - VA - SARAVANAN_SEKAR
    
    //START - WHATSAPP INTEGRATION - WA - SARAVANAN_SEKAR
    public static string WA_WORKFLOWS = 'whatsAppWrkFlows';
    
    public static string AD_WORKFLOWS = 'whatsAppWrkFlowsGenesis';
    public static string  AUTO_DIALER_STATUS_INPROGRESS='In Progress';
    public static string  AUTO_DIALER_STATUS_SYNCED='Synced';
    public static string  AUTO_DIALER_STATUS_FAILED='Failed';
    
    //END - WHATSAPP INTEGRATION - WA - SARAVANAN_SEKAR
    
    //START - FOR OTHER CHARGES INTEGRATION
    public static string ALD_OTHER_CHARGES_SUCCESS_CODE = '201';
    public static string ALD_OTHER_CHARGES_STATUS_FAILURE = 'Failure';
    public static string ALD_OTHER_CHARGES_MULE_NAME = 'SalesOrderOtherCharges';
    
    //END - FOR OTHER CHARGES INTEGRATION
    
    //START - INTEGRATION SYNC STATUS
    public static string  STATUS_INPROGRESS='In Progress';
    public static string  STATUS_SYNCED='Synced';
    public static string  STATUS_FAILED='Failed';
    //END - INTEGRATION SYNC STATUS
    
    //SR PROCESS VARIABLES - START
    public static string STEP_SUM_VERIFY_THE_REQUEST = 'Verify the Request';
    public static string CM_FINANCE_PROFILE = 'CM Finance';
    public static string STEP_CUST_ACKNOWLEDGED = 'Customer Acknowledged';
    //SR PROCESS VARIABLES - END
    
    //Agency Registration SR Record Types - START - Tharun
    public static String Agency_Registration_DEV_RT = 'AgencyRegistration';
    public static String Agency_Re_Registration_DEV_RT = 'AgencyReRegistration';
    public static String NOC_BROKER_LETTER = 'NOC_Broker_Letter';
    public static String BROKER_LOGIN_OTP_TIMER = 'BrokerLogin';
    public static Id BROKER_AGENT_RT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Constants.BROKER_AGENT).getRecordTypeId();
    //Agency Registration SR Record Types - END - Tharun
    
    //SS_DandT_Revamp_SP15-START
    public static String LEGAL_CANCELLATION_SR_TYPE = 'Legal Cancellation';
    public static string LEGAL_FLAG = 'Legal';
    public static String DEFAULT_FLAG = 'Default';
    public static string COURT_ORDER_FLAG = 'Court Order';
    public static String pushLabel = 'Push';
    public static String pushTransferToLegalTitle = 'Transfer to Legal';
    public static String pullFromLegalLabel = 'Pull';
    public static String pullFromLegalTitle = 'Pull from Legal';
    public static String pushReferToDandTLabel = 'Push';
    public static String pushReferToDandTTitle = 'Transfer to D&T';
    public static String PENDING = 'Pending';
    public static String TRANSFER_TO_LEGAL = 'Transfer to Legal';
    public static String TRANSFER_TO_EX_COUNSEL = 'Transferred to External Counsel';
    public static String PULLED_BACK_BY_DandT = 'Pulled back by D&T Team';
    public static String REFERRED_TO_DandT_BY_LEGAL = 'Returned for negotiation';
    public static String DandT_STEP_Summary = 'Customer Negotiation';
    public static String LEGAL_STEP_Summary = 'Court filing by Legal';
    public static String pushToExternalCounsel = 'External counsel';
    public static String SENT_TO_EXTERNAL_COUNSEL = 'Sent to external counsel';
    public static string SUBMITTED_TO_COURT = 'Submitted to Court';
    public static String LEGAL_PROFILE_NAME = 'Customer Management - D&T';//'00e8d000001yaA6';
    public static string BUDGET_LINE_ITEM_LEGAL_NAME = Label.BUDGET_LINE_ITEM_LEGAL_NAME;//'Sales Comm.-Internal';
    public static string LEGAL_CLEARED = 'Legal Cleared';
    public static String DOCUMENT_D_AND_T_MEMO = 'D and T Memo';
    public static string CUSTOMER_LEGAL_FLAG = 'Customer Legal Flagged';
    public static string UNIT_LEGAL_FLAG = 'Unit Legal Flagged';
    public static string UNIT_DEFAULTED = 'Unit Defaulted';
    public static string DEFAULT_AND_TERMINATION = 'Default And Termination';
    public static string PUSH_OR_PULL_SR_TO_DnTQueue_FROM_LEGAL = 'Transaction not allowed for this unit as it is Leggaly flagged! Please check with D&T Team before proceeding Negotiation.';
    //SS_DandT_Revamp_SP15-END
    
    public static string CHARGE_RULE_SALES_ORDER_OTHER_CHARGES = 'Sales Order Other Charge';
    public static string CHARGE_RULE_REVERSAL_CHARGE_TYPE = 'Reversal Charges';

}