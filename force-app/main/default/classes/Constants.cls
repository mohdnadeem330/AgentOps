/**
 * @description       :  This class contains all the constants used in the application.
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-07-2025
 * @last modified by  : Protiviti
 * Version            : V1.1 ChangeMeIn@UserSettingsUnder.SFDoc
 * Version			      : V1.2  Added by Protiviti when retail contact logic added to CustomerProfileWeservice class.	
 * Version			      : V1.3  API Name of Retail Lead Record Type added by Protiviti on 18 Sept 2025.	
**/
public class Constants{
    
    //added by dharanesh on 5-5-2025 
    
    public static String DATA_MIGRATION_OWNER = '';
    //added by dharanesh on 5-5-2025

  public static String CASE_SUBVERTICAL_CUSTOMERPORTAL_LIVEALDAR  = 'Customer Portal and App - Live Aldar';//NOPMD: [Code Style-FieldNamingConventions]
  public static String CASE_CASECATEGORY_DATA_ACCOUNTMERGE        = 'Data - Account Merge';//NOPMD: [Code Style-FieldNamingConventions]
  public static String IS_VALID = 'IsValid';
  public static String NO = 'No';
  public static String YES = 'Yes';
  public static String RESPONSE_CODE = 'ResponseCode';
  public static String STATUS = 'Status';
  public static String INVALID = 'Invalid';
  public static String BROKER_REGISTRATIONS_SMS = 'BROKER_REGISTRATIONS_SMS';
  public static String ERROR_CODE = 'ErrorCode';
  public static String SMS_NOTIFICATION_WAS_SENT = 'SMS Notification was sent';
  public static String COMPLETED = 'Completed';
  public static String NORMAL = 'Normal';
  public static String PERSON_LEAD_RECORD_TYPE_NAME = 'Person';
  public static String ORGANIZATION_LEAD_RECORD_TYPE_Name = 'Organization';
    public static String RETAIL_LEAD_RECORD_TYPE_NAME = 'Retail Lead'; // API Name of Retail Lead Record Type added by Protiviti on 18 Sept 2025
  public static String BROKER_AGENCY_RECORD_TYPE_NAME = 'Broker Agency';
  public static String HOURS = 'Hours';
  public static String VAT = 'VAT';
  public static String EXTERNAL_COUNSEL = 'External Counsel';
    public static String ACCOUNT_CUSTOMER_SUB_TYPE_CORPORATE = 'CORPORATE'; // Changes Related to ASF-3387
    public static String ACCOUNT_CUSTOMER_SUB_TYPE_WEALTH = 'WEALTH'; // Changes Related to ASF-3387
  //----- Profiles
  public static String CONTACT_CENTER_AGENT = 'Contact Centre Agent';
  public static String CONTACT_CENTER_MANAGER = 'Contact Centre Manager';
  public static String USER_PROFILE_SYSTEM_ADMINISTRATOR = 'System Administrator';
  public static String SALES_MANAGER = 'Sales Manager';
  public static String PARTNER_COMMUNITY_USER = 'Agency Admin with Limited Access';
  public static String AGENCY_ADMIN_PROFILE = 'Agency Admin';
  public static String AGENCY_USER_PROFILE = 'Agency User';
  public static String PARTNER_COMMUNITY_USER_LOGIN = 'Agency Admin with Limited Access Login'; 
  public static String AGENCY_ADMIN_PROFILE_LOGIN = 'Agency Admin Login'; 
  public static String AGENCY_USER_PROFILE_LOGIN = 'Agency User Login';
  public static String AGENCY_PROFILE = 'Agency';
  public static String INTEGRATION_PROFILE = 'Integration Profile';
  public static string FINANCE_PROFILE = 'Finance Team';
  public static string CUSTOMER_MGMT_PROFILE = 'Customer Management';

  //----- APISetting__mdt
  public static String EMAIL = 'Email';
  public static String LEAD_IMPORT = 'LeadImport';
  public static String QUALTRICS = 'Qualitrics';
  public static String PHONE = 'Phone';
  public static String SMS = 'SMS';
  public static String SMSBULK = 'SMSBulk';
  public static String DARNA_USER_PROFILE = 'DARNAUserProfile';
  public static String DARNA_ACCESS_TOKEN = 'DARNAAccessToken';
  public static String DARNA_USER_POINTS = 'DARNAUserPoints';
  public static String DARNA_REDEEM_POINTS = 'DARNARedeemPoints';
  public static String DARNA_OTP_REQUEST = 'DARNAOTPRequest';
  public static String DARNA_ADD_POINT = 'DARNAAddPoints';
  public static String APPOINTMENT_SYSTEM = 'AppointmentSystem';
  public static String ASITE = 'asite';
  public static String CAPILLARY_ACCESS_TOKEN = 'CAPILLARYAccessToken';
  public static String CAPILLARY_ADD_POINT = 'CAPILLARYAddPoints';
  public static String CAPILLARY_VERIFY_CUSTOMER_WITH_POINT = 'CAPILLARYVerifyCustomerWithPoints';
  public static String CAPILLARY_CHECK_POINT_REDEEMABLE = 'CAPILLARYCheckPointsRedeemable';
  public static String CAPILLARY_REDEEM_POINTS = 'CAPILLARYRedeemPoints';

  //----- Darna Integration
  public static String SALES_BUSINESS_CATEGORY = 'Sales';
  public static String SALES_INSTALMENT_PAYMENT_BUSINESS_TRIGGER = 'sales_instalment_payment';
  public static String LEASING_ASSET_TYPE = 'leasing';

  public static Integer SUCCESS_CODE_200 = 200;
  public static Integer ERROR_CODE_422 = 422;
  
  public static String PAYMENT = 'Payment';
  public static String IBAN = 'IBAN';
  public static String MULESOFT = 'MuleSoftEndPoint';
  public static String BITLY = 'BitlyShortenURL';

  //----- Lead Status
  public static String QUALIFIED = 'Qualified Lead';
  public static String WORKING_LEAD = 'In Progress Lead';
  public static String RETIRED = 'Retired Lead';
  public static String NOT_DISCLOSED = 'Not Disclosed';
  public static String DUPLICATE_LEAD = 'Duplicate lead';
  public static String NEW_LEAD = 'New Lead';
  public static String CONVERTED_LEAD = 'Converted Lead';
  public static String CLOSED = 'Closed';
    
    //---- Lead Type
    public static String LEAD_TYPE_AM_SALE = 'AM Sale';
    public static String LEAD_TYPE_LOGISTICS = 'Logistics';
    public static String LEAD_TYPE_OPTIONS_AND_UPGRADES = 'Options and Upgrades';
    public static String LEAD_TYPE_RESALE = 'Resale';
    public static String LEAD_TYPE_NEW_SALE = 'New Sale';
    
    //---- Lead GROUP  
    public static String LEAD_GROUP_TYPE_LSQ = 'LSQ';
    
    //---- Lead Enquiry Category  
    public static String LEAD_ENQUIRY_CATEGORY_ALDAR_SELECT = 'Aldar Select';
    public static String LEAD_ENQUIRY_CATEGORY_WEALTH = 'Wealth';
    public static String LEAD_ENQUIRY_CATEGORY_CORPORATE = 'Corporate';
    public static String CUSTOMER_SUB_TYPE_DOMESTIC = 'DOMESTIC';
    public static String CUSTOMER_SUB_TYPE_INTERNATIONAL = 'INTERNATIONAL';
    // Lead Sales Origin
    public static String SALES_ORIGIN_DOMESTIC = 'Domestic';

  //----- Lead Fields
  public static String ASSET_MANAGEMENT = 'Asset Management';
  public static String RETAIL_LEASE = 'Retail';
  public static String RENT = 'Rent';
  public static String RESIDENTIAL_LEASE = 'Residential Lease';
  public static Set<String> PROPERTY_USAGE_YARDI = new Set<String>{'Retail','Office','Showroom','Operative Villages'};
  public static String WALK_IN = 'Walk-In';
  public static String L800_ALDAR = '800-Aldar';
  public static String ONLINE_LEAD = 'Online';
  public static String BROKER_PORTAL = 'Broker Portal';
  public static String EXISTING_CUSTOMER = 'Existing Customer';
  public static String NEW_CUSTOMER = 'New Customer';
    public static String ENQUIRY_TRIGGER = 'ADIA';
    public static String SKIPDUPLICATEAPPROVAL_STATUS = 'Approved';
    public static String LEAD_OBJECT = 'Lead';
    
    //  
    public static String TRUE_STRING = 'True';
    public static String FALSE_STRING = 'False';
  
  //---- Unique Keys
  public static String LEAD_UNIQUE_KEYS = 'LeadUniqueKeys';
  public static String EOIRANGE_UNIQUE_KEYS = 'EOIRangeUniqueKeys';
  public static String ACCOUNT_UNIQUE_KEYS = 'AccountUniqueKey';
  public static String LEAD_ACCOUNT_UNIQUE_KEYS = 'LeadAccountUniqueKey';
  public static String MATCH_LEAD_UNIQUE_KEYS = 'firstName;MiddleName;lastName;Email;Phone';
  public static String ACCOUNT_UNIQUE_KEY_1 = 'AccountUniqueKey1';
  public static String ACCOUNT_UNIQUE_KEY_2 = 'AccountUniqueKey2';
  public static String CORPORATEACCOUNT_UNIQUE_KEY_1 = 'CorporateAccountUniqueKey1';
  public static String ORGANISATION_ACCOUNT_UNIQUE_KEY = 'OrganizationAccountUniqueKey';


  //---- Error Messages
  public static String QUALIFICATION_MESSAGE = 'QUALIFICATION_MESSAGE';
  public static String RETIRED_MESSAGE = 'RETIRED_MESSAGE';
 // public static final String RESTRICT_SPECIAL_CONDITION_UPDATION = 'RESTRICT_SPECIAL_CONDITION_UPDATION' ;
  public static final String SPECIALCONDITION_MESSAGE = 'RESTRICT_SPECIAL_CONDITION_UPDATION';
  public static String CONVERT_MESSAGE = 'CONVERT_MESSAGE';
  public static String CONVERT_MESSAGE_FOR_SM_WITHOUT_TASK = 'CONVERT_MESSAGE_FOR_SM_WITHOUT_TASK';
  public static String INSUFFICIENT_ACCESS = 'INSUFFICIENT_ACCESS';
  public static String RECEIPT_ALLOCATION_RESTRICTION = 'RECEIPT_ALLOCATION_RESTRICTION';
  public static String ALLOCATION_AMOUNT_RESTRICTION = 'ALLOCATION_AMOUNT_RESTRICTION';
  public static String UNITS_TIMER_EXPIRED   = 'UNITS_TIMER_EXPIRED';
  public static String UNITS_ALREADY_BOOKED = 'UNITS_ALREADY_BOOKED';
  public static String BUDGET_UNAVIALABLE   = 'BUDGET_UNAVIALABLE';
  public static String MULTIPLE_PAYMENT_PLAN = 'MULTIPLE_PAYMENT_PLAN';
  public static String NO_PAYMENT_PLAN = 'NO_PAYMENT_PLAN';
  public static String LPC_WAINER_AMOUNT_VERIFY_REQUIST_STEP = 'LPC_WAINER_AMOUNT_VERIFY_REQUIST_STEP';
  public static String TOTAL_LPC_AMOUNT_VERIFY_REQUIST_STEP = 'TOTAL_LPC_AMOUNT_VERIFY_REQUIST_STEP';
  public static String INSTALLMENT_LINE_VALIDATION = 'INSTALLMENT_LINE_VALIDATION';
  public static String RECEIPT_ACKNOWLEDGEMENT_SR_VALIDATION = 'RECEIPT_ACKNOWLEDGEMENT_SR_VALIDATION';
  public static String RECEIPT_NUMBER_CHEQUE_REPLACE_VALIDATION = 'RECEIPT_NUMBER_CHEQUE_REPLACE_VALIDATION';
  public static String PAYMENT_EXTENSION_DATE_SR_VALIDATION = 'PAYMENT_EXTENSION_DATE_SR_VALIDATION';
  public static String TOTAL_WAIVED_AMOUNT_VALIDATION = 'TOTAL_WAIVED_AMOUNT_VALIDATION';
  public static String WAIVED_PERCENTAGE_VALIDATION = 'WAIVED_PERCENTAGE_VALIDATION';
  public static String PROPOSAL_PAYMENT_PLAN_VALIDATION = 'PROPOSAL_PAYMENT_PLAN_VALIDATION';
  public static String INSTALLMENT_WITHOUT_RECEIPT = 'INSTALLMENT_WITHOUT_RECEIPT';
  public static String DUPLICATE_SR_MESSAGE = 'DUPLICATE_SR_MESSAGE';
  public static String LPC_ENTER_REICEPT_ERROR = 'LPC_ENTER_REICEPT_ERROR';
  public static String ADDITION_JOINT_OWNER_VALIDATION = 'ADDITION_JOINT_OWNER_VALIDATION';
  public static String DELETION_JOINT_OWNER_VALIDATION = 'DELETION_JOINT_OWNER_VALIDATION';
  public static String OWNERSHIP_CHANGE_VALIDATION = 'OWNERSHIP_CHANGE_VALIDATION';
  public static String PPC_PAID_EQUITY_VALIDATION = 'PPC_PAID_EQUITY_VALIDATION';
  public static String PPC_PAID_EQUITY_100_VALIDATION = 'PPC_PAID_EQUITY_100_VALIDATION';
  public static String ADM_CHARGE_NOT_PAID = 'ADM_CHARGE_NOT_PAID';
  public static String PPC_CHEQUE_REPLACEMENT_APPLICABILITY = 'PPC_CHEQUE_REPLACEMENT_APPLICABILITY';
  public static String PPC_CHEQUE_REPLACEMENT_NOT_CLOSED = 'PPC_CHEQUE_REPLACEMENT_NOT_CLOSED';
  public static String CASE_FIRST_COME_FIRST_SERVE_ERROR = 'CASE_FIRST_COME_FIRST_SERVE_ERROR';
  public static String LPC_RECEPT_NOT_PAID = 'LPC_RECEPT_NOT_PAID';
  public static String TRANSFER_CASES_ERROR = 'TRANSFER_CASES_ERROR';
  public static String CHEQUE_REPLACEMENT_STATUS_PPC_VALIDATION = 'CHEQUE_REPLACEMENT_STATUS_PPC_VALIDATION';
  public static String CHEQUE_REPLACEMENT_MATURITY_DATE_VALIDATION = 'CHEQUE_REPLACEMENT_MATURITY_DATE_VALIDAT';
  public static String CHEQUE_REPLACEMENT_BANK_NAME_VALIDATION = 'CHEQUE_REPLACEMENT_BANK_NAME_VALIDATION';
  public static String USER_EMIRATE_ID_VALIDATION = 'USER_EMIRATE_ID_VALIDATION';
  public static String REUPLOAD_DOCUMENTS_WITHOUT_APPLICATION = 'REUPLOAD_DOCUMENTS_WITHOUT_APPLICATION';
  public static String NO_DOCUMENTS_NEED_TO_REUPLOAD = 'NO_DOCUMENTS_NEED_TO_REUPLOAD';
  public static String DOCUMENTS_NEED_TO_REUPLOAD = 'DOCUMENTS_NEED_TO_REUPLOAD';
  public static String LPC_WAIVED_BY_VALIDATION = 'LPC_WAIVED_BY_VALIDATION';
  public static String CASE_SR_TYPE_NOT_EXIST = 'CASE_SR_TYPE_NOT_EXIST';
  public static String CASE_INITIATED_FROM_CASE = 'CASE_INITIATED_FROM_CASE';
  public static String TITLE_DEED_REG_APPLICATION_NUMBER_VALIDATION = 'TITLE_DEED_REG_APPLICATION_NUMBER_VALIDA';
  public static String TITLE_DEED_REG_APPLICATION_DATE_VALIDATION = 'TITLE_DEED_REG_APPLICATION_DATE_VALIDATI';
  public static String TITLE_DEED_REG_IN_PROGRESS_DATE_VALIDATION = 'TITLE_DEED_REG_IN_PROGRESS_DATE_VALIDATI';
  public static String TITLE_DEED_REG_REGISTRATION_DATE_VALIDATION = 'TITLE_DEED_REG_REGISTRATION_DATE_VALIDAT';
  public static String TITLE_DEED_REG_EVALUATION_VALIDATION = 'TITLE_DEED_REG_EVALUATION_VALIDATION';
  public static String SPA_APPLICATION_DATE_VALIDATION = 'SPA_APPLICATION_DATE_VALIDATION';
  public static String SPA_APPLICATION_NUMBER_VALIDATION = 'SPA_APPLICATION_NUMBER_VALIDATION';
  public static String SPA_PAYMENT_STEP_FROM_DARI = 'SPA_PAYMENT_STEP_FROM_DARI';
  public static String SPA_COMPLETION_DETAILS_VALIDATION = 'SPA_COMPLETION_DETAILS_VALIDATION';
  public static String PAYMENT_EXTENSION_AMOUNT_SR_VALIDATION = 'PAYMENT_EXTENSION_AMOUNT_SR_VALIDATION';
  public static String RECEIVED_RECEIPT_ACKNOWLEDGEMENT_SR = 'RECEIVED_RECEIPT_ACKNOWLEDGEMENT_SR';
  public static String OUTSTANDING_AMOUNT_LESS_100 = 'OUTSTANDING_AMOUNT_LESS_100';
  public static String HANDOVER_SR_NOT_FOUND = 'HANDOVER_SR_NOT_FOUND';
  public static String REQUIRED_DOCUMENT_NEED_TO_UPLOAD = 'REQUIRED_DOCUMENT_NEED_TO_UPLOAD';
  public static String CUSTOMER_EMAIL_NOT_AVAILABLE = 'CUSTOMER_EMAIL_NOT_AVAILABLE';
  public static String GOLDEN_VISA_IS_APPLICABLE_FOR_PERSON_ACC = 'GOLDEN_VISA_IS_APPLICABLE_FOR_PERSON_ACC';
  public static String CASE_ACCOUNT_RELATED_TO_UNIT_VALIDATION = 'CASE_ACCOUNT_RELATED_TO_UNIT_VALIDATION';
  public static String DLP_CUSTOMER_MOBILE_NUMBER_VALIDATION = 'DLP_CUSTOMER_MOBILE_NUMBER_VALIDATION';
  public static String DLP_ASITE_PROJECT_NAME_VALIDATION = 'DLP_ASITE_PROJECT_NAME_VALIDATION';
  public static String CASE_CIS_SHEET_SENT_VALIDATION = 'CASE_CIS_SHEET_SENT_VALIDATION';
  public static String CASE_CLOSED_VALIDATION = 'CASE_CLOSED_VALIDATION';
  public static String MORTGAGE_DETAILS_VALIDATION = 'MORTGAGE_DETAILS_VALIDATION';
  public static String PAY_BY_DETAILS_VALIDATION = 'PAY_BY_DETAILS_VALIDATION';
  public static String LPC_FREEZE_STATUS_VALIDATION = 'LPC_FREEZE_STATUS_VALIDATION';
  public static String CASE_TASKS_VALIDATION = 'CASE_TASKS_VALIDATION';
  public static String RECEIPT_ACKNOWLEDGEMENT_MATURITY_DATE_EX = 'RECEIPT_ACKNOWLEDGEMENT_MATURITY_DATE_EX';
  public static String CLEARED_RECEIPTS_ERROR = 'CLEARED_RECEIPTS_ERROR';
  public static String RECEIPT_OUTSTANDING_AMOUNT_LESS_100 = 'RECEIPT_OUTSTANDING_AMOUNT_LESS_100';
  public static String QA_SNAGGING_DATE_CHECK = 'QA_SNAGGING_DATE_CHECK';
  public static String QA_DE_SNAGGING_DATE_CHECK = 'QA_DE_SNAGGING_DATE_CHECK';
  public static String CUSTOMER_BLACKLISTED_COMPLIANCE = 'CUSTOMER_BLACKLISTED_COMPLIANCE';
  public static String CUSTOMER_BLACKLISTED_DEFAULT = 'CUSTOMER_BLACKLISTED_DEFAULT';
  public static String CUSTOMER_BLACKLISTED = 'CUSTOMER_BLACKLISTED';
  public static String SYNC_STATUS_ERROR_SR_MESSAGE = 'SYNC_STATUS_ERROR_SR_MESSAGE';
        public static String NO_SALES_ORDER_ERROR = 'NO_SALES_ORDER_ERROR';

    
  
    
    // Task Record Type
    public static String CALLING_LIST_TASK_RT = 'Calling List Task';

  //---- Task Status
  public static String CUSTOMER_REACHED = 'Customer Reached';
  public static String CUSTOMER_NOT_REACHABLE = 'Customer Not Reachable';
  public static String TASK_OPEN = 'Open';
  public static String TASK_COMPLETED = 'Completed';
  public static String TASK_DAY1 = 'SM - Day 1 - Task 1';

  public static String TASK_TYPE_DAY1 ='Day 1 - Task 1';
  //---- Task type
  public static String Task_type_External = 'External';
  public static String Task_type_Internal ='Internal';
  public static String Task_type_Follow_Up = 'Follow up task';
  public static String Task_type_Resolver = 'Resolver Attempt Task';
    
  //---- Task Subject
  public static String ALDAR_SALES_OFFER = 'Aldar Sales Offer';
  public static String MEETING = 'Meeting';
  public static String CLOSEDWON = 'closedWon';
  public static String CASE_CALL_ATTEMPT_1 = 'Call Attempt 1';
  public static String LEAD_AUTO_DIALER_QUEUE = 'Auto Dialer Queue';
  public static String Call = 'Call'; 
  
    public static String LEAD_OU_QUEUE = 'O&U Queue';

  //---- Opportunity stage
  public static String STAGE_PROPOSAL = 'Proposal';
  public static String STAGE_CLOSEDWON = 'Closed Won';
  public static String STAGE_NEW = 'New';
  public static String STAGE_IN_PROGRESS = 'Discussion In Progress';
  public static String STAGE_CLOSED_LOST = 'Closed Lost';
  public static String STAGE_MEETING = 'Meeting';

  //----- Unit Status
  public static String UNIT_STATUS_NEW = 'New';
  public static String UNIT_STATUS_AVAILABLE = 'Available';
  public static String UNIT_STATUS_BLOCKED = 'Blocked';
  public static String UNIT_STATUS_BOOKING_INPROGRESS = 'In-Progress';
  public static String UNIT_STATUS_BOOKED = 'Booked';
  public static String UNIT_STATUS_SOLD = 'Sold';
    public static String UNIT_STATUS_RESERVED = 'Reserved';

  public static String UNIT_BLOCKED_COMMENT = 'Blocked for Unit Swap';
  public static String UNIT_BLOCKED_REASON = 'MGMT SALES';

  //----- User Attributes
  public static String USER_ROLE_HEAD_OF_SALES = 'Head of Sales';
  public static String USER_TEAM_LAND = 'LAND';
  public static String USER_TEAM_AUH = 'AUH';
  public static String USER_TEAM_DXB = 'DXB';
  public static String USER_TEAM_VIP = 'VIP';
  public static String USER_TEAM_CASA = 'CASA';
  public static String USER_ROLE_CM_FINANCE = 'CM Finance';  
    public static String USER_START_THREE_ID_DIGIT = '005';
  //----- Queue
  public static String LEAD_DUPLICATE_QUEUE = 'Duplicate Queue';
  public static String LEAD_AGENT_QUEUE = 'Agent Queue';
  public static String DEFAULT_RR_QUEUE = 'SalesManagerRRAssignmentQueue';
  public static String SALES_RRQUEUE ='Sales Manager RR Queue';
  public static String ASSETS_MANAGEMENT_QUEUE = 'Assets Management';
  public static String BROKER_QUEUE = 'Broker Queue';
  public static String FINANCE_QUEUE = 'Finance Queue';
  public static String SURVEY_QUEUE = 'Survey Queue';
  public static String DLP_QUEUE = 'DLP Queue';
  public static String CM_FINANCE_QUEUE = 'CM Finance Queue';
  public static String POST_SALE_QUEUE = 'Post Sales Queue';
  public static String ADM_Community = 'ADM Community';
  public static String ADM_Registration= 'ADM Registration';
  public static String Comms_Queue= 'Comms Queue';
  public static String Home_Finance_Queue=  'Home Finance Queue';
  Public static string Customer_Onboarding_Queue = 'Onboarding queue';
  	public static String CM_NEW_SALE_QUEUE = 'Active Customer DLP';
  Public static String ADIAQUEUE = 'ADIA Queue';
  public static String LEAD_LOGISTICS_QUEUE = 'Logistics Queue';

    //----- Yardi API
  public static String YARDI_SUCCESS_STATUS = '201';

  //Email TEmplates
  public static string ALDAR_OFFER_LETTER = 'AldarOfferLetter';
  public static string ALDAR_TRADE_EXPIRY ='TradeLicenseExpiryReminder_v2';
  public static string ALDAR_OFFER_LETTER_LEAD = 'AldarOfferLetterLead';
  public static string PAYMENT_URL = 'Payment URL';
  public static string SUCCESS_PAYMENT = 'EOI Success Payment';
  public static string OTP_EMAIL = 'OTP Email';
  public static string ASSIGN_REQUEST_EMAIL = 'Unit Assign Request';
  public static String SALES_NON_PERFORMANCE_LAST_7_DAYS = 'Sales Non Performance Last 7 Days';
  public static String SALES_NON_PERFORMANCE_LAST_14_DAYS = 'Sales Non Performance Last 14 Days';
  public static String FREEHOLD_NOC_TO_CUSTOMER = 'FreeholdNOCToCustomer';
  public static String KEYHANDOVER = 'KeyHandover';
  public static String SERVICEREQUESTCASETEMPLATE = 'Service_Request_Case';

  //Org wide email address
  public static string ALDAR_PROPERTIES_ORGWIDEEMAIL = 'Aldar Development';
  public static string ALDAR_PROPERTIES_ORGWIDEEMAIL_BROKER = 'Aldar Agency Support';
  public static string ALDAR_PROPERTIES_ORGWIDEEMAIL_Post_Sales = 'Post Sales Case';
  public static string ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE = 'Aldar Customer Care';

  //Offer and Discount Types
  public static string  DISCOUNT_TYPE_BULK_DISCOUNT = 'Bulk Discount';
  public static string  DISCOUNT_TYPE_CORPORATE_DISCOUNT = 'Corporate Discount';
  public static string  DISCOUNT_TYPE_WEALTH_DISCOUNT = 'Wealth Discount';
  public static string  DISCOUNT_TYPE_PREMIUM ='Premium';
  public static string  OFFER_TYPE_VOUCHER ='Voucher';
  public static string  OFFER_ON_PM_FEE ='Property Management Fees';

  //CryptoKey
  public static string  CRYPTOKEY = '1212123434343434';
    
    //permission Set name
    Public static String CM_HOME_PERMISSION_SET = 'CM_Home_PermissionSet'; 

  //RoundRobinAssignmentMatrix
  public static string STATUS_AVAILABLE = 'Available';
  public static string STATUS_OFFLINE = 'Offline';
  //public static integer AGENT_ACTION_SLA_TIME_IN_HOURS = 2;

  //------ Account Record Type
  public static String ACCOUNT_OBJECT = 'Account';
  public static String PERSON_ACCOUNT_RT = 'Person Account';
  public static String ORGANISATION_ACCOUNT_RT = 'Organization Account';
  public static String BROKER_AGENCY_ACCOUNT_RT = 'Broker Agency';
    public static String CONTACT_OBJECT = 'Contact';
    public static String ORGANISATION_CONTACT_RT = 'Contact';
    
    //V1.2 Added By Protiviti for when retail contact logic added to CustomerProfileWeservice class.
  public static String BRAND_Account_RT = 'Brand account';	 
    
  //------ Contact Record Type
  public static String BROKER_AGENT = 'Broker Agent';

  //--- App Related Constants
  public static final Integer STATUS_CODE_SUCCESS = 200;
  public static final Integer STATUS_CODE_UNAUTHORIZED = 403;
  public static final Integer STATUS_CODE_SYSTEM_ERROR = 500;  
  public static final Integer STATUS_CODE_NOT_FOUND = 400;
  public static final Integer STATUS_CODE_OLD_VERSION = 101;

  //--- Booking Web-Service
  public static final Integer STATUS_CODE_UNITS_NOT_AVAILABLE = 801;
  public static final Integer STATUS_CODE_TIMER_EXPIRED = 802;
  public static final Integer STATUS_CODE_PAYMENT_TERMS_EXPECTION = 803;
  public static final Integer STATUS_CODE_OPPORTUNITY_INCOMPLETE = 804;
  public static final Integer STATUS_CODE_BUDGET_NOT_AVAILABLE = 805;

  //--- Generic Web-Service Messages
  public static final String SUCCESS_MESSAGE = 'Success';  
  public static final String MESSAGE_GENERIC_ERROR = 'An error has occured. Please contact your system administrator.';
  public static final String INVALID_REQUEST_BODY = 'Invalid Request Body';
  public static final String GENERIC_LOGIN_ERROR = 'There was an error logging in. Please contact your system administrator.';
  public static final String MESSAGE_OLD_APP_VERSION = 'Please update your app to the latest version.';
  public static final String INCORRECT_RECORD_ID = 'Please provide a valid record id.';
  public static final String GENERIC_MOBILE_LOG_VIEW = 'Mobile View';
  public static final String SUCCESS_MESSAGE_Activity = 'Activity has created successfully'; 
  public static final String INVALID_AGENT_ID = 'Invalid Agent Id';
  //public static final String INV = 'Invalid Agent Id';
  public static final String NO_ACTIVITY_FOUND = 'No activity found';    
  public static final String EMAIL_SENT_SUCCESSFULLY = 'Email sent successfully';    

  
  //----- Opportunity Unit
  public static string OPPO_UNIT_SUBSTATUS_PENDING_SM = 'Pending with Sales Manager';
  public static string DOCUMENT_TYPE_RA = 'Reservation Agreement';
    public static string DOCUMENT_TYPE_ITB = 'Intention to book';
  public static string DOCUMENT_TYPE_KYC = 'KYC Form';
  public static string DOCUMENT_TYPE_EOI = 'EOI Agreement';
  public static string DOCUMENT_TYPE_WEALTH = 'Wealth Form';
  public static string DOCUMENT_TYPE_SIGNED_WEALTH = 'Signed Wealth Form';
  public static string DOCUMENT_TYPE_SIGNED_RA = 'Signed Reservation Agreement';
    public static string DOCUMENT_TYPE_SIGNED_ITB = 'Signed Intention to book';
  public static string DOCUMENT_TYPE_SIGNED_KYC = 'Signed KYC Form';
  public static string DOCUMENT_TYPE_SIGNED_CIS = 'Signed CIS Sheet';
  public static string DOCUMENT_TYPE_ALDAR_SIGNED_SPA = 'Aldar Signed SPA';
  public static string DOCUMENT_TYPE_FLOOR_PLAN = 'Floor Plan';
  public static string DOCUMENT_TYPE_AFFECTION_PLAN = 'Affection Plan';
  public static string DOCUMENT_TYPE_SPA_APPROVAL_CHECK_LIST = 'SPA Validation and Approval Check List';
  public static string DOCUMENT_STATUS_COMPLETED = 'Completed';
  public static string DOCUMENT_TYPE_BROKERAGE_FORM = 'Brokerage Form';
  public static string DOCUMENT_TYPE_GTC = 'General Terms & Conditions';
  public static string DOCUMENT_TYPE_TITLE_DEED = 'Title Deed Copy';
  public static string DOCUMENT_SO_RT  ='SalesOrderDocument';
  public static string RTO_DOCUMENT_TYPE_GTC = 'RTO General Terms & Conditions';
  public static string DOCUMENT_TYPE_MCD = 'Master Community Declaration';
  public static string DOCUMENT_TYPE_Schedule_A = 'Schedule A';
  public static string DOCUMENT_TYPE_NOC_COPY = 'NOC Copy';
    public static string DOCUMENT_TYPE_SIGNED_NOC_COPY = 'Signed NOC Copy';
  public static string DOCUMENT_TYPE_Commercial_Trade_License = 'Aldar Commercial Trade License';
  public static string DOCUMENT_TYPE_Bank_Letter = 'Bank Letter';
  public static string STATUS_REJECTED = 'Rejected';
  public static string STATUS_DRAFT = 'Draft';
  public static string DOCUMENT_TYPE_PREFIX_SIGNED = 'Signed';
  public static string DOCUMENT_TYPE_PREFIX_COUNTER = 'Counter';
  public static string DOCUMENT_STATUS_GENERATED = 'Generated';
  public static string DOCUMENT_STATUS_UPLOADED = 'Uploaded';
  //public static string DOCUMENT_TYPE_SDDC = 'Signed Direct Debit Cancellation form';
  public static string DOCUMENT_TYPE_SDDCF = 'Signed Direct Debit Cancellation form';
  public static string DOCUMENT_TYPE_DDCF = 'Signed Direct Debit Cancellation form';
    
  public static string DOCUMENT_TYPE_SDDRF = 'Signed Direct Debit registration form';
  public static string DOCUMENT_TYPE_DDRF = 'Signed direct debit registration form';
    
  public static string DOCUMENT_TYPE_112 = 'Direct Debit registration form';
  public static String DOCUMENT_LITIGATION_LETTER = 'Litigation Letter';

  public static String DOCUMENT_UNIFIED_HANDOVER_DOCUMENTS = 'Unified Handover Documents';
  public static String DOCUMENT_SIGNED_UNIFIED_HANDOVER_DOCUMENTS = 'Signed Unified Handover Documents';
    public static String DOCUMENT_PROVIS_NOC = 'Provis NOC';
    
  

  //--- Sales Order Statuses
  public static String SO_STATUS_RTO_PENDING = 'RTO Pending';
  public static String SO_STATUS_RTO_Approve_PENDING = 'RTO Approve Pending';
  public static String SO_STATUS_RTO_CONVERTED = 'RTO Converted';
  public static String SO_STATUS_RTOCONVERTED = 'RTOConverted';
  public static String SO_STATUS_RTO_TERMINATED = 'RTO Terminated';
  public static String SO_STATUS_RTO_EXPIRED = 'RTO Expired';
  public static String SO_STATUS_RTO_SOLD = 'RTO Sold';
  public static String SO_STATUS_CANCELLED = 'Cancelled';
  public static String SO_STATUS_CANCELLED_BY_USER = 'Cancelled by User';
  public static String SO_STATUS_SOLD = 'Sold';
  public static string STATUS_RESERVATION_IN_PROGRESS = 'Reservation In Progress';
  public static string STATUS_APPROVAL_PENDING = 'Approve Pending';
  public static string STATUS_RESERVED = 'Reserved';
  public static string SUB_STATUS_DOCS_SIGNED = 'Documents Signed';
  public static string SUB_STATUS_POST_SALES_CANCELLATION = 'Post Sales Cancellation';
  public static string OPPO_UNIT_STATUS_PENDING = 'Pending';
  
  // Sales Order Other Charges Types
  public static string OTHER_CHARGES_TYPE_SERVICE_CHARGE = 'Service Charge';
  public static string OTHER_CHARGES_TYPE_TRANSFER_FEE_CHARGE = 'Transfer Fee Charge';
  public static string OTHER_CHARGES_TYPE_OWNERSHIP_CHANGE = 'Ownership Change';
  public static string OTHER_CHARGES_TYPE_MORTGAGE_REGISTRATION_CHARGE = 'Mortgage Registration Charge';
  public static string OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES = 'Late Payment Charges';
  public static string OTHER_CHARGES_TYPE_LPC_WAIVED_AMOUNT = 'LPC Waived Amount';
  public static string OTHER_CHARGES_TYPE_CREDIT_NOTE = 'Credit Note';
  public static string OTHER_CHARGES_TYPE_CANCELLATION_FEE = 'Cancellation Fee';
  public static string OTHER_CHARGES_TYPE_CREDIT_MEMO = 'Credit Memo';
  public static string OTHER_CHARGES_TYPE_DEBIT_MEMO = 'Debit Memo';
  public static string OTHER_CHARGES_TYPE_SECURITY_DEPOSIT = 'Security Deposit';
  public static string OTHER_CHARGES_Charge_TYPE_ADM_Fee_REFUND = 'ADM Fee Refund';  
  public static final String FEE_PAID_TO_ADM = 'ADM Directly';
  public static final String OTHERCHARGE_LEGAL = 'Legal Fee';


  public static string OTHER_CHARGES_SUB_TYPE_REALLOCATED_AMOUNT = 'Reallocated Amount';
  public static string OTHER_CHARGES_SUB_TYPE_FORFEITURE_AMOUNT = 'Forfeiture Amount';
  public static string OTHER_CHARGES_SUB_TYPE_CUSTOMER_REFUND = 'Customer Refund';
  public static string OTHER_CHARGES_SUB_TYPE_INSTALLMENT = 'Installment';
  public static string OTHER_CHARGES_SUB_TYPE_ADM_Fee_REFUND = 'ADM Fee Refund';  

  // Installment Line
  public static String STATUS_CLEARED = 'Cleared';
  
  //Timmer Names
  public static string RESERVATION_TIMMERNAME = 'ReservationUnit';
  public static string PAYMENT_GATEWAY_LINK = 'PaymentGatewayLink';
  public static string OTP = 'OTP';
  public static string BOOKING_TIMERNAME = 'Booking';
  public static string RESERVATION_TIMERNAME = 'ReservationUnit';
  public static string BROKER_KYC_TIMERNAME = 'BrokerKYC';
  public static string BROKER_RESERVATION_TIMERNAME = 'BrokerReservationUnit';

  //Payment
  public static string ONLINE = 'Online';
    public static string CRYPTO_PAYMENT = 'Crypto Payment';
  public static string SUCCESS_REASON_CODE = '100';
  public static string RECEIVED_PAYMENT_STATUS = 'Received';
  public static string REVERSED_PAYMENT_STATUS = 'Reversed';
  public static string DEFAULT_PAYMENT_STATUS = 'Default';
  public static String PAYMENT_PLAN_ACTIVE_YES = 'Yes';
  public static string RECEIPT_STATUS_CLEARED = 'Cleared';
  public static string LINK_SENT = 'Link Sent';
  public static string CHEQUE_REPLACED_STATUS_REASON = 'Cheque Replaced';
  public static string WIRE_TRANSFER = 'Wire Transfer';
  public static string CREDIT_CARD = 'Credit Card';
  public static string POS = 'POS';    
  public static string CHEQUE = 'Cheque';
  public static string MORTGAGE_CHEQUE = 'Mortgage Cheque';
  public static string CONFIRMED_PAYMENT_STATUS = 'Confirmed';
  public static string REMITTED_PAYMENT_STATUS = 'Remitted';
  public static List<String> PAYMENT_STATUS_ALLOWED_SOA = new List<String>{'Confirmed','Remitted','Cleared','Received'};


  //Receipt Acknowledgement
  public static string PAYMENT_TYPE_CREDIT_NOTE = 'Credit Note';
  public static string PAYMENT_SUB_TYPE_INSTALLMENT_REVERSAL = 'Installment Reversal';
  public static string PAYMENT_SUB_TYPE_OTHER_CHARGE_REVERSAL = 'Other Charges Reversal';
  public static string PAYMENT_SUB_TYPE_INVOICE_REVERSAL = 'Invoice Reversal';

  //Receipt Allocation
  public static string LPC_INVOICE_TYPE = 'LPC';

  //---- Currencies
  public static String UAE_CURRENCY_UNIT = 'Dhirams';
  public static String UAE_CURRENCY_SUBUNIT = 'fils';
  public static String UAE_CURRENCY = 'AED';

  //Booking Memo
  public static string STATUS_APPROVED = 'Approved';
  public static string APPROVAL_STATUS_APPROVAL_PENDING = 'Approval Pending';
  public static string APPROVAL_PROGRESS_APPROVED = 'Approved by Line Manager';
  public static string MEMO_TYPE_NEW_PAYMENT_PLAN = 'New Payment Plan';

  // Apex Sharing Access Level
  public static string READ_ACCESS = 'Read';
  public static string EDIT_ACCESS = 'Edit';
  public static string NONE_ACCESS = 'None';

  // Account Team Member
  public static String TEAM_ROLE_SALES_MANAGER = 'Sales Manager';
  public static String ROLE_SALES_ADMIN = 'Sales Admin';
  //Agency Team
  public static string PARTNER_OWNER = 'Partner/Owner';
  public static string AGENCY_ADMIN = 'Agency Admin';

  //Broker Agency Portal
  @AuraEnabled
  public final String SUBMITTED = 'Submitted';
  @AuraEnabled
  public final string AGENCY_ADMIN_AURA = 'Agency Admin';
  @AuraEnabled
  public final string REQUIRE_ADDITIONAL_INFORMATION = 'Require Additional Information';

  //----- Integration Process
  public static String PRICE_UPDATE = 'unitPrice';
  public static String STATUS_UPDATE = 'unitStatus';
  public static String JOINTOWNER_INTEGRATION = 'jointOwner';
  public static String CUSTOMER_INTEGRATION = 'customer';
  public static String AGENCY_INTEGRATION = 'supplBroker';
  public static String SALESORDER_INTEGRATION = 'salesOrder';
  public static String PAYMENT_CHQ_INTEGRATION = 'paymentChq';
  public static String MARKETING_REIMBURSEMENT_INTEGRATION = 'mrktReimburse';

  public static String PAYMENT_EXTN_INTEGRATION = 'paymentExtn';
  public static String PROPERTY_TRANS_INTEGRATION = 'propTrans';
  public static String CANCELLATION_INTEGRATION = 'cancellation';
  public static String LPC_INTEGRATION = 'lpcWaiver';
  public static String DEFAULT_INTEGRATION = 'defTerm';
  public static String HANDOVER_INTEGRATION = 'handover';
  public static String MILESTONE_INTEGRATION = 'milestone';
  public static String MORTGAGE_INTEGRATION = 'mortgage';
  public static String MORTGAGE_DISCHARGE_INTEGRATION = 'DISCHARGE';
  public static String MORTGAGE_REGISTRATION_INTEGRATION = 'REGISTRATION';
  public static String REBATE_REINSTATE_INTEGRATION = 'rebate';
  public static String PAYMENT_PLAN_CHANGE = 'paymentPlanChange';
  public static String ADM_FEE_REFUND_INTEGRATION = 'admRef';
  public static String OWNERSHIP_CHANGE_INTEGRATION = 'ownershipChange';
  public static String FREEZE_LPC_INTEGRATION = 'freezeLPCWaiver';
    
  public static String Damascus_Callback_Property = 'DamascusCallbackProperty';
  public static String Damascus_Callback_Project = 'DamascusCallbackProject';
  public static String Damascus_Callback_Payment_Plan = 'DamascusCallbackPaymentPlan';


  //----- Aramex Integration
  public static String ARAMEX_CREATE_SHIPMENTS_INTEGRATION = 'AramexCreateShipments';
  public static String ARAMEX_TRACk_SHIPMENTS_INTEGRATION = 'AramexTrackShipments';

  //----- Integration Reprocess
  public static String REPROCESS_PRICE = 'Price';
  public static String REPROCESS_STATUS = 'Status';

  //----- IBAN API
  public static String VALID = 'Valid';
  public static String NOT_VALID = 'Not Valid';
  public static String EXPIRED = 'Expired';
  //----- Service Request
  public static String BLACKLISTED_CUSTOMER_COMPLIANCE = 'TRUE_Compliance';
  public static String BLACKLISTED_CUSTOMER_DEFAULT = 'TRUE_Default';
  public static String BLACKLISTED_CUSTOMER_LEGAL = 'TRUE_Legal';
  public static String SUBMITTED = 'Submitted';
  public static String SR_STEP_02 = 'SRStep-02';
  public static String COMPLETED_STATUS = 'Completed';
  public static String PENDING_STATUS = 'Pending';
  public static String STEP_APPROVED_STATUS = 'Approved';
  public static String STEP_ACCEPTED_STATUS = 'Accepted';
  public static String SRCleared = 'Cleared';
  public static String Compliance_Cleared =  'Compliance Cleared';
  public static String Compliance_Rejected = 'Compliance Rejected';    
  public static String Rejected = 'Rejected';
  public static String Returned = 'Returned';
  public static String STEP_REJECTED_STATUS = 'Rejected';
  public static String AGENCY_AGREEMENT_SIGNED_BY_CCO_SRDOC = 'Agency Agreement Signed by CCO';
  public static String AGENCY_AGREEMENT_SIGNED_BY_HEAD_OF_BROKER_SRDOC = 'Agency Agreement Signed by Head of BM';
  public static String SUPPORTING_DOCUMENTS_SRDOC = 'Supporting Documents';
  public static String ADM_RECEIPT_SRDOC = 'ADM Receipt';
  public static String SPA_REGISTRATION_SRDOC = 'SPA Registration Documents';
  public static String NOC_DOCUMENT = 'NOC Document';
  public static String TITLE_DEED_REG_ADM_INVOICE_SRDOC = 'ADM Invoice';
  public static String BUYER_PROFILE_VERIFIED_STATUS = 'Buyer Profile Verified';
  public static String DOCUMENTS_ARCHIVED_STATUS = 'Documents Archived';
  public static String SALES_ORDER_CANCELLATION_COMPLETED_STATUS = 'Sales Order Cancellation Completed';
  public static String PROPERTY_TRANSFER_NOC_SR_TYPE = 'Property Transfer NOC';
  public static String RTO_TRANSFER_SR_TYPE = 'RTO Transfer';
  public static String CANCELLATION_SR_TYPE = 'Cancellation';
  public static String MUTUAL_CANCELLATION_SR_TYPE = 'Mutual Cancellation';
  public static String CONSOLIDATION_SR_TYPE = 'Consolidation';
  public static String UNIT_SWAP_SR_TYPE = 'Unit Swap';
  public static String RTO_CANCELLATION_SR_TYPE = 'RTO Cancellation';
  public static String CHEQUE_REPLACEMENT_SR_TYPE = 'Cheque Replacement';
  public static String PAYMENT_EXTENSION_SR_TYPE = 'Payment Extension';
  public static String SPA_REGISTRATION_TYPE = 'SPA Registration';
    public static String CREDIT_NOTE_CREATION_SR_TYPE = 'Credit Note Creation';//SS_CRED_NOTE_IMP_APRMAY23
    public static String CREDIT_NOTE_CREATION_SR_RECORD_TYPE = 'CreditNoteCreation';//SS_CRED_NOTE_IMP_APRMAY23
    public static String CREDIT_NOTE_CREATION_HEXA_SR_TYPE = 'Credit_Note_Creation';//SS_CRED_NOTE_IMP_JUN23

    
  public static String REQUEST_VERIFIED = 'Request Verified';
  public static String CLOSED_SR = 'Closed';
  public static String EQUITY_TRANSFERRED_SR = 'Equity Transferred';
  public static String CHEQUE_REPLACEMENT_APPLICABLE = 'Applicable';
  public static string SR_STATUS_DRAFT = 'Draft';
  public static string SR_STATUS_CANCELLED = 'Cancelled';
  public static string WAIVED_BY_PERCENTAGE = 'Percentage';
  public static string WAIVED_BY_AMOUNT = 'Amount';
  public static string Verification_BY_FINANCE = 'Verification by Finance';
  public static string SPA_PAYMENT_STEP = 'Payment Step';

  public static string CANCELLATION_REASON_CONSOLIDATION = 'Consolidation';
  public static string CANCELLATION_REASON_UNIT_SWAP = 'Unit/Ploat Swap';
  public static string CANCELLATION_REASON_MUTUAL_CANCELLATION_FORFEITURE = 'Mutual Cancellation - Forfeiture';
  public static string CANCELLATION_REASON_MUTUAL_CANCELLATION_REFUND = 'Mutual Cancellation - Refund';

  public static string REFUND_TYPE_REFUND = 'Refund';
  public static string REFUND_TYPE_REALLOCATION = 'Reallocation';

  public static String BUYER_ESIGN = 'Buyer';
  public static String SELLER_ESIGN = 'Seller';
  public static String CUSTOMER_ESIGN = 'Customer';
  public static String AUTHORISED_SIGNATORY_ESIGN = 'Authorised Signatory';
  public static String CUSTOMER_WITH_JOINT_OWNER_ESIGN = 'Customer with Joint Owner';
  public static String BUYER_WITH_JOINT_OWNER_ESIGN = 'Buyer with Joint Owner';

  public static String SUCCESS_RETURN_MESSAGE = 'Success';
  public static String ERROR_RETURN_MESSAGE = 'Error';

  //----- Service Request Record Type
    public static String PROPERTY_TRANSFER_OffPlan = 'Property Transfer (Off Plan)';
  public static String PROPERTY_TRANSFER_RT = 'Property Transfer';
  public static String PLOT_PROPERTY_TRANSFER_RT = 'Plot Property Transfer';
  public static String PROPERTY_TRANSFER_NOC_RT = 'Property Transfer NOC';
    public static String AldarEstatesMoveInOut_RT = 'AldarEstatesMoveIn';
  public static String AldarEstatesMoveOut_RT = 'AldarEstatesMoveOut';
  public static String HANDOVER_RT = 'Handover';
  public static String ADM_REGISTRATION_RT = 'ADM Registration';
  public static String PAYMENT_EXTENSION_RT = 'Payment Extension and Cheque Replacement';
  public static String INTERNAL_MORTGAGE_REGISTRATION_RT = 'Internal Mortgage Registration';
  public static String INTERNAL_MORTGAGE_DISCHARGE_RT = 'Internal Mortgage Discharge';
  public static String LPC_WAIVER_RT = 'LPC Waiver';
  public static String INVESTOR_CERTIFICATE_RT = 'Investor Certificate';
  public static String DEVELOPMENT_UNDERTAKING_AGREEMENT_RT = 'Development Undertaking Agreement';
  public static String PAYMENT_PLAN_CHANGE_RT = 'Payment Plan Change';
  public static String CANCELLATION_RT = 'Cancellation';
  public static String MUTUAL_CANCELLATION_RT = 'Mutual Cancellation';
  public static String CONSOLIDATION_RT = 'Consolidation';
  public static String UNIT_SWAP_RT = 'Unit Swap';
  public static String RTO_CANCELLATION_RT = 'RTO Cancellation';
  public static String SPA_REGISTRATION_RT = 'SPA Registration For Off Plan';
  public static String Golden_Visa_RT = 'Golden Visa';
  public static String ADM_Fee_Refund_RT = 'ADM Fee Refund';
  public static String LEASE_TO_FREEHOLD_TRANSFER_RT = 'Lease To Freehold Transfer';
  public static String JOINT_OWNER_NOC_RT = 'Joint Owner (NOC)';
  public static String OWNERSHIP_CHANGE_RT = 'Ownership Change';
  public static String ADDITION_JOINT_OWNER_RT = 'Addition Joint Owner';
  public static String DELETION_JOINT_OWNER_RT = 'Deletion Joint Owner';
  public static String TITLE_DEED_REGISTRATION_RT ='Title Deed Registration';
  public static String SPA_READY_TITLE_DEED_REGISTRATION_RT ='SPA & Title Deed Registration For Ready Properties';
  public static String SPA_RTO_PHPP_TITLE_DEED_REGISTRATION_RT ='SPA & Title Deed for RTO and PHPP';
  public static String REBATE_REINSTATE_RT = 'Rebate Reinstate';
  public static String RTO_EXTENSION_RT = 'RTO Payment Extension';
 
  public static String SPA_REGISTRATION_DEV_RT = 'SPARegistrationForOffPlan';
  public static String PROPERTY_TRANSFER_DEV_RT = 'PropertyTransfer';
  public static String PLOT_PROPERTY_TRANSFER_DEV_RT = 'PlotPropertyTransfer';
  public static String PROPERTY_TRANSFER_NOC_DEV_RT = 'PropertyTransferNOC';
  public static String INTERNAL_MORTGAGE_REGISTRATION_DEV_RT = 'InternalMortgageRegistration';
  public static String PAYMENT_EXTENSION_DEV_RT = 'PaymentExtension';
  public static String PROPERTY_TRANSFER_OFFPLAN_RT = 'PropertyTransferOffPlan';
  public static String PAYMENT_PLAN_CHANGE_DEV_RT = 'PaymentPlanChange';
  public static String LPC_WAIVER_DEV_RT = 'LPCWaiver';
  public static String Golden_Visa_DEV_RT = 'GoldenVisa';
  public static String TITLE_DEED_REGISTRATION_DEV_RT = 'TitleDeedRegistration';
  public static String JOINT_OWNER_DEV_RT = 'JointOwner';
  public static String JOINT_OWNER_NOC_DEV_RT = 'JointOwnerNOC';
  public static String DEFAULT_AND_TERMINATION_DEV_RT = 'DefaultAndTermination';
  public static String SPA_TITLEDEED_FOR_RTP_AND_PHPP_DEV_RT = 'SPATitleDeedForRTOAndPHPP';
  public static String CREDIT_NOTE_CREATION_DEV_RT = 'Credit_Note_Creation'; //SS_CRED_NOTE_IMP_APRMAY23
  public static String INVESTOR_CERT_LETTER_ISSUE = 'Letter Issuance';
  public static String INVESTOR_CERT_ATTESTED_SPA = 'Attested SPA';

  public static String JOINT_OWNER_RT = 'Joint Owner';
  public static String PRIMARY_OWNER = 'Primary Owner';
  public static String BROKER = 'Broker';

  //----- SR Charge Type
  public static String FULLY_PAID = 'Fully Paid';
  public static String NOT_FULLY_PAID = 'Not Fully Paid';

  //----- SR Unit Selection
  public static String REFUND_OPTION_1 = 'Option 1';
  public static String REFUND_OPTION_2 = 'Option 2';
  public static String REFUND_OPTION_3 = 'Option 3';
    public static String REFUND_OPTION_4 = 'Option 4';

  public static String RETAINED_UNIT = 'Retained';
  public static String CANCELLED_UNIT = 'Cancelled';

  //----- Broker Account Status
  public static String PENDING_VERIFICATION = 'Pending Verification';
  public static String ACTIVE = 'Active';
  public static String ACTIVE_AGENT_STATUS = 'Active';
  public static String IN_Active_AGENT_STATUS = 'In Active';
  public static String SUSPENDED = 'Suspended';
  //-------PriceUpdateRequest Status
    public static String APPROVE_STATUS = 'Approval Pending';
  
  //------SalesOrder Sub Status
  public static String SUB_STATUS = 'Printing Pending with Sales Admin';
  public static String SUB_STATUS_PENDINGWITHSALESADMIN = 'Pending with Sales Admin';
  public static String SUB_STATUS_CONTRACTDOCUMENTPRINTED = 'Contract Document Printed';
  public static String SALES_STATUS = 'Approve Pending';
  public static String SUB_STATUS_CM_VALIDATED = 'Validated By CM';
  public static String SALES_STATUS_CANCELLED = 'Cancelled';
  public static String SALES_SUB_STATUS_SPA_SIGNEDOFF_PENDING ='SPA Sign-off Pending';
  public static String SALES_SUB_STATUS_SPA_SIGNEDOFF = 'SPA Signed-off';
  public static String SALES_SUB_STATUS_REGISTRATION_PENDING = 'Registration Pending';
  public static String SALES_SUB_STATUS_REGISTRATION_COMPLETED = 'Registration Completed';
  public static String SALES_SUB_STATUS_FINANCE_PENDING = 'Pending for finance clearance';
  
  //-------Opportunity Status
  public static String SPECIAL_COND_STATUS= 'Approve Pending';
  public static String OPPORTUINTY_REFERRAL_STAFF= 'Internal Staff Referral';
  public static String OPPORTUINTY_AGENT_TYPE_DIRECT = 'Direct';
  public static String OPPORTUINTY_AGENT_TYPE_INDIRECT = 'Indirect';
  public static String OPPORTUINTY_USER_ROLE_POST_SALES_BOOKING = 'Post Sales Booking';
    public static String OPPORTUINTY_DAIRECT_AIP_COMMISSION_APPROVAL_STATUS_APPROVED = 'Approved'; //ASF - 3377

  //-------Project Budget Lines Name
  public static String BUDGET_LINE_DISCOUNT = 'Discounts';
  public static String BUDGET_LINE_SUBSIDY = 'Mortgage Subsidy';
  public static String BUDGET_LINE_ADMFEE = 'ADM Fee';
  public static String BUDGET_LINE_DLD = 'DLD';
  public static String RAKMunicipalityFee = 'RAK Municipality Fee';
    
  public static String BUDGET_LINE_ADMADMINFEE = 'ADM Admin Fee';
  public static String BUDGET_LINE_DARNA = 'Darna Loyalty';
  public static String BUDGET_LINE_REBATE = 'Rebates';
  public static String BUDGET_LINE_OTHER = 'Other Sales Support';
  public static String BUDGET_LINE_HOME_MAINTENANCE = 'Home Maintenance';
  public static String BUDGET_LINE_AMC = 'AMC';
  public static String BUDGET_LINE_DLP = 'DLP';
  public static String BUDGET_LINE_SC_WAIVER = 'SC Waiver';
  public static String BUDGET_LINE_INTERNAL_COMMISSION = 'Sales Comm.-Internal';
  public static String BUDGET_LINE_EXTERNAL_COMMISSION = 'Sales Comm.-External';
  public static String BUDGET_SALES_SUPPORT_BUCKET = 'Sales Support Bucket';
  public static String BUDGET_DISCOUNT_REBATE_BUCKET = 'Discount and Rebate Bucket';
  public static String BUDGET_TASK_INTERNAL_COMMISSION = '7.73.731';
  public static String BUDGET_TASK_EXTERNAL_COMMISSION = '7.73.732';
  public static String BUDGET_TASK_ADMFEE = '7.73.735';
  public static String BUDGET_TASK_SC_WAIVER = '7.73.736';
  public static String BUDGET_TASK_OTHER = '7.73.739';
  public static String BUDGET_TASK_HOME_MAINTENANCE = '7.73.741';
  public static String BUDGET_TASK_DARNA = '7.73.751';
  public static String BUDGET_TASK_PAYMENT_PROVISION = '7.73.760';
  public static String BUDGET_TASK_FORFEITED_CASH = '7.73.761';
  public static String BUDGET_TASK_SUBSIDY = '7.73.770';
  public static String BUDGET_TASK_DISCOUNT = '7.73.737';
  public static String BUDGET_TASK_REBATE = '7.73.738';

  //-------Commission Line Item
  public static String COMMISSION_LINE_INTERNAL_COMMISSION = 'Internal';
  public static String COMMISSION_LINE_EXTERNAL_COMMISSION = 'External';
  public static String COMMISSION_LINE_REFERRAL_COMMISSION = 'Referral';
  public static String COMMISSION_LINE_GENERATED = 'Generated';
  public static String COMMISSION_LINE_STATUS_SOLD = 'Sold';
  public static String COMMISSION_LINE_NOT_READY = 'Not Ready';
  public static String COMMISSION_LINE_QUARTER_PAYOUT = 'Quarter_Payout';
  public static String COMMISSION_LINE_QUARTER_NAME = 'Quarter';
  public static String COMMISSION_LINE_ELIGIBLE = 'Eligible';
  public static String COMMISSION_LINE_NOT_ELIGIBLE = 'Not Eligible';
  public static String COMMISSION_LINE_ELIGIBLE_FOR_NEXT_QUARTER = 'Eligible For Next Quarter';
  public static String COMMISSION_LINE_BONUS_COMMISSION = 'Bonus Commission';
  public static Map<Integer, String> COMMISSION_LINE_QUARTER = new Map<Integer, String>{1 => 'Q1', 2 => 'Q2', 3 => 'Q3', 4 => 'Q4'};

  //----- Case
  public static String CASE_NEW = 'New';
  public static String CASE_IN_PROGRESS = 'In Progress';
  public static String CASE_WORK_IN_PROGRESS = 'Work In Progress';
  public static String PROPERTY_TRANSFER_TYPE = 'Property Transfer';
  public static String PAYMENT_EXTENSION_TYPE = 'Payment Extension';
  public static String INTERNAL_MORTGAGE_REGISTRATION_TYPE = 'Internal Mortgage Registration';
  public static String INTERNAL_MORTGAGE_DISCHARGE_TYPE = 'Internal Mortgage Discharge';
  public static String LPC_WAIVER_TYPE = 'LPC Waiver';
  public static String CHEQUE_REPLACEMENT = 'Cheque Replacement';
  public static String INVESTOR_CERTIFICATE = 'Investor Certificate';
  public static String DEVELOPMENT_UNDERTAKING_AGREEMENT = 'Development Undertaking Agreement';
  public static String PAYMENT_PLAN_CHANGE_TYPE = 'Payment Plan Change';
  public static String CANCELLATION_TYPE = 'Cancellation';
  public static String MUTUAL_CANCELLATION_SUB_TYPE = 'Mutual Cancellation';
  public static String CONSOLIDATION_SUB_TYPE = 'Consolidation';
  public static String UNIT_SWAP_SUB_TYPE = 'Unit Swap';
  public static String SURVEY_CASE_ORIGIN = 'Survey';
  public static String CLOSED_CASE = 'Closed';
  public static String WITH_RESOLUTION_CASE = 'With Resolution';
  public static String AWAITING_ACTION_CASE = 'Awaiting Action';
  public static String LEASING_CASE_CATEGORY = 'Leasing';
  public static String LEASE_TO_FREEHOLD_TRANSFER_CASE_CATEGORY = 'Lease To Freehold Transfer';
  public static String OWNERSHIP_CHANGE_TYPE = 'Ownership Change';
  public static String ADDITION_JOINT_OWNER_TYPE = 'Addition Joint Owner';
  public static String DELETION_JOINT_OWNER_TYPE = 'Deletion Joint Owner';
  public static String SHARE_PERCENTAGE_CHANGE_TYPE = 'Share Percentage Change';
  public static String CASE_ORIGIN_CUSTOMER_PORTAL = 'Customer Portal';
  public static String CASE_ORIGIN_CUSTOMER_APP = 'Customer App';
  public static string DLP_Closed = 'DLP Closed';
  public static string Resolved = 'Resolved';
  public static string Escalated = 'Escalated';
  public static string Re_Opened = 'Re Opened';
  //----- Case Category
  public static String QUALTRICS_SURVEY_CATEGORY = 'Qualtrics Survey';
  public static List<String> RELATED_TO_QUALTRICS_SURVEY = new List<String>{'Sales Booking Experience','Overall Sales Experience','Suspect Retired Experience','Opportunity Retired Experience','Broker Experience'};

  public static String CONTACT_DETAILS_UPDATE_CATEGORY = 'Contact Details Update';

  //----- Case Sub Category
  public static String NO_RESPONSE_SUB_CATEGORY = 'No Response';

  //----- Case Sub Vertical
    public static String CONTACT_CENTRE_SUB_VERTICAL = 'Contact Center';
    public static String DLP_SUB_VERTICAL = 'DLP';
    public static String DLP_VERTICAL = 'DLP';
    public static String DLP_CONTRACTOR_SUB_VERTICAL = 'DLP by Contractor';
    public static String LEGAL_VERTICAL = 'Legal';  
    public static String ORIGIN_SURVEY = 'Survey';
    public static String Property_Handover ='Property Handover';
    public static String CMO =  'CMO';
    public static String ADM_Services = 'ADM Services';
    public static String Comms ='Comms';
    public static String Home_Finance ='Home Finance';
    public static String Repair = 'Repair';

  //----- Case Record Type
  public static String FEEDBACK_CASE_RT = 'Feedback Case';
  public static String STANDARD_CASE_RT = 'Standard Case';
    public static String HOME_FINANCE_CASE_RT = 'Home Finance';
  public static String LEGAL_CASE_RT = 'Corporate Legal';
  public static String DLP_CASE_RT = 'DLP';
    public static String AMC_CASE_RT = 'AMC';
  public static String Requests = 'Requests';
  public static String Complaints = 'Complaints'; 
  public static String Queries = 'Queries';  
  public static String Development_Control = 'Development Control';   
    /* Added by Cloudzlab for ECSS*/
    public static String ECSSDevQueries = 'ECSS_Inquiry';
    public static String ECSSDevComplaints = 'ECSS_Complaints';
    public static String ECSSCustomerVerticalVal = 'Aldar Estates';
    public static String ECSSOppRecTypeName = Label.ECSS_OppRecTypeName ; //'ECSS Opportunity';
    public static String ECSSOppRecType = 'ECSS_Opportunity';
    public static String ECSSLeaseRecType = 'ECSS_Leasing';
    public static String ECSSSecondaryMarketOppRecTypeName = Label.ECSS_OpportunityRecTypeSecondaryMarket; //'ECSS_SecondaryMarket'
    public static String ECSSOffPlanOppRecTypeName = 'ECSS_OffPlan';



    // public static String ECSSDevRequests = 'ECSS_Requests';
    public static String ECSSDevMaintenance = 'ECSS_Maintenance';
    public static String ECSSQueries = Label.ECSS_Inquiry;
    public static String ECSSComplaints = Label.ECSS_Complaint;
    public static String ECSSRequests = Label.ECSS_Maintenance;
    public static String ECSSMaintenance = Label.ECSS_Maintenance;
    public static String ECSSFunctionalLocation = 'Functional Location';
    public static String CASE_RECORD_TYPE_RESALE = 'Resale'; 
    /* End */

  //--------Constants mdt
  public static String CONFIG_GROUP = 'ConfigGroup';
  public static String TRIGGER_SOURCE = 'TriggerSource';
  public static String TRIGGER_TOUCHPOINT = 'TriggerTouchpoint';
  public static String OPP_CONFIG_GROUP = 'OpportunityConfigGroup';
  public static String OPP_TRIGGER_TOUCHPOINT = 'OpportunityTriggerTouchpoint';
  public static String YARDI_UNITTYPE_MAPPING = 'YardiUnitTypeMapping';
  public static String SALES_ORDER_BOOKING_DATE = 'SalesOrderBookingDate';
  public static String SALES_ORDER_END_BOOKING_DATE = 'SalesOrderEndBookingDate';
  public static String OFFER_END_DATE = 'OfferEndDate';
  public static String RECEIPT_CLEARED_DATE = 'ReceiptClearedDate';

  // Broker Request
  public static String APPROVED_STATUS = 'Approved';
  public static Id MARKETING_REIMBURSEMENT_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('BrokerRequest__c').getDescribe().getRecordTypeInfosByDeveloperName().get('MarketingReimbursement').getRecordTypeId();

  //---------API Status Codes
  //public static Integer QUALITRICS_SUCCESS_STATUS = 200;
  //public static Integer QUALITRICS_BADREQUEST_STATUS = 400;
  public static String MULESOFT_SUCCESS_STATUS = '201';
  
  //---------Mulesoft Status Codes
  public static String MULESOFT_SUCCESS = 'Success';
  public static String MULESOFT_FAILURE = 'Failure';
  public static String MULESOFT_FAILED = 'Failed';
  public static String METHOD_POST = 'POST';

  //---------Mulesoft Mode
  public static String MULESOFT_CREATE_MODE = 'CREATE';
  public static String MULESOFT_UPDATE_MODE = 'UPDATE';
  public static String MULESOFT_DELETE_MODE = 'DELETE';
  public static String MULESOFT_SHAREHOLD_MODE = 'SHAREHOLD';
  public static String MULESOFT_OWNERSHIP_MODE = 'OWNERSHIP';

  //---------Sync Status
  public static String STATUS_IN_PROGRESS = 'In Progress';
  public static String STATUS_SYNCED = 'Synced';
  public static String STATUS_FAILED = 'Failed';
  
  //---------Account RecordTypeId
  public static Id BROKER_AGENCY_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId();
  public static Id ORGANIZATION_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('OrganizationAccount').getRecordTypeId();
  public static Id PERSON_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
  public static Id NON_REGISTERED_TYPE_ID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('NonRegisteredBrokerAgentAccount').getRecordTypeId();

  // Lead RecordType Id
  public static Id PERSON_LEAD_RT_ID = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByDeveloperName().get('Person').getRecordTypeId();

  //payment Plan
  public static String PAYMENT_PLAN_TYPE_STANDARD='Standard';
  //-----SPA Checklist
  public static String SPA_CHECKLIST_NAME='SPA Checklist Item'; 
  public static String ACCOUNT_RECORD_TYPE='Person'; 
  public static String SUPPLEMENTARY_CATEGORY='Supplementary Documents'; 
  public static String NATIONALITY = 'Nationality';
 // public static Boolean IS_ACTIVE='Supplemenatry Documents'; 

  public static String INVOICE_TYPE_INSTALLMENT = 'Installment';
  public static String INVOICE_TYPE_ADM = 'ADM';
  public static string INVOICE_TYPE_CREDIT_NOTE = 'Credit Note';//SS_CRED_NOTE_IMP_APRMAY23

  //Ord Wide DisplayName
  public static String DISPLAY_NAME='Aldar properties'; 

  //Broker Portal 
  public static String URL_PREFIX='Aldar Broker Portal'; 
  public static String USERNAME_DOMAIN='@aldarportal.com';
  
  //DOCUMENT PLACEHOLDER CATEGORY
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_PERSON_ACCOUNT = 'Person Account';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_ALDAR_STAFF = 'Aldar Staff';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_ORGANIZATION = 'Organization';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_BROKER_AGENCY = 'Broker Agency';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_RESERVATION = 'Reservation';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_BOOKING = 'Booking';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_RTO = 'RTO';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_JOINT_OWNER = 'Joint Owner';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_COMMISSION_INVOICE = 'Commission Invoice'; 
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_COMMISSION_CLAIM_FORM = 'Commission Claim Form'; 
    public static string DOCUMENT_PLACEHOLDER_CATEGORY_INVOICE_CLAIM = 'Invoice Claim Form';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_ACTIVITY='Activity';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_PROJECT='Project';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_OFFER='Offers & Promotions';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_PAYMENTPLAN='Payment Plan';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_OPPORTUNITY_EOI='Opportunity EOI';
  public static string DOCUMENT_RECORDTYPE_INVENTORY='InventoryDocument';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_CASE = 'Case';
  public static string DOCUMENT_PLACEHOLDER_SALES_ORDER_OTHER_CHARGES = 'Sales Order Other Charges';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_BUILDING_SECTION = 'Building/Section';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_DLP_ZONE = 'DLP Zone';
  public static string DOCUMENT_PLACEHOLDER_CATEGORY_SO_CANCELLATION = 'Sales Order Cancellation';
  
  //Invoice line status
  public static string CLEARED = 'Cleared';
  //COmmission lines
  public static string COMMISSION_LINE_STATUS_READY_FORE_SUBMISSION = 'Ready for Submission';
  public static string COMMISSION_LINE_STATUS_NOT_READY = 'Not Ready';
  //public static string COMMISSION_LINE_STATUS_IN_PROGRESS = 'In Progress';
  public static string COMMISSION_LINE_STATUS_ACCEPTED = 'Pending Invoice Verification';
  public static string COMMISSION_LINE_STATUS_FIXED = 'Fixed';
  public static string COMMISSION_LINE_STATUS_PAID = 'Paid';

  //Qualtrics Integration Status
  public static string QUALTRICS_SENT = 'Sent';
  public static string QUALTRICS_FAILED = 'Failed';
  public static string QUALTRICS_IN_PROGRESS = 'In Progress';

  //Lead Lost Reasons
  public static string LEAD_LOST_NO_REAL_POTENTIAL = 'No Real Potential';
  public static string LEAD_LOST_NOT_QUALIFIED = 'Not Qualified';
  public static string LEAD_LOST_FUTURE_POTENTIAL = 'Future Potential';
  public static string LEAD_LOST_INTEREST_LOST = 'Interest Lost' ;
  public static string LEAD_LOST_NO_ANSWER = 'No Answer' ;
  public static string LEAD_LOST_NO_PURCHASE_INTEREST = 'No Purchase Interest' ;

  //Opportunity Lost Reason
  public static string OPPORTUNITY_LOST_INTEREST  = 'Lost - Interest';
  public static string OPPORTUNITY_LOST_COMPLETION_DATE  = 'Lost - Completion Date';
  public static string OPPORTUNITY_LOST_PROJECT_LOCATIONS  = 'Lost - Project Locations';
  public static string OPPORTUNITY_LOST_AVAILABILITY  = 'Lost - Availability';
  public static string OPPORTUNITY_LOST_UNCONTACTABLE  = 'Lost - Uncontactable';
  public static string OPPORTUNITY_LOST_FUTURE_POTENTIAL  = 'Lost - Future Potential';
  public static string OPPORTUNITY_LOST_UNIT_VIEW  = 'Lost - Unit View';
  public static string OPPORTUNITY_LOST_PAYMENT_PLAN  = 'Lost - Payment Plan';
  public static string OPPORTUNITY_LOST_PRICE  = 'Lost - Price';

  //Broker Activity RecordTypeNames

  public static string BROKER_ACTIVITY_TYPE_ACTIVITY  = 'Activity';
  public static string BROKER_ACTIVITY_TYPE_EVENT  = 'Event';

  //----- Mobile App Constants
  public static String UNIT_AVAILABILITY = 'Availability';
  public static String UNIT_LOCKING = 'Locking';
  public static String RESERVE_PROCESS = 'Reserve';
  public static String BOOKING_PROCESS = 'Book';
  public static String BOOKING_ACTION = 'BOOKING';
  public static String BROKER_KYC = 'BrokerKYC';
  public static String BROKER_RESERVE_UNIT = 'BrokerReserveUnit';
  public static String BROKER_CANCEL_RESERVATION = 'BrokerCancelReservation';
  public static String BROKER_UNIT_RESERVATION = 'BrokerUnitReservation';
  public static String CUSTOMER_KYC_STATUS = 'CustomerKYCStatus';
    
  //FastTRackSRDOCQueueable
    public static final List<String> DOCUMENT_TYPES = new List<String>{'National ID Front Copy', 'Passport Copy', 'National ID Back Copy'};
    public static final List<String> HEXABPM_SR_DOC_TYPES = new List<String>{'Buyer Emirates ID Copy', 'Buyer Passport Copy', 'Buyer Emirates ID BackSideCopy', 'Seller Emirates ID Copy', 'Seller Passport Copy', 'Seller Emirates ID BackSideCopy'};
    public static final String NATIONAL_ID_FRONT_COPY = 'National ID Front Copy';
    public static final String PASSPORT_COPY = 'Passport Copy';
    public static final String NATIONAL_ID_BACK_COPY = 'National ID Back Copy';
    public static final String BUYER_EMIRATES_ID_COPY = 'Buyer Emirates ID Copy';
    public static final String BUYER_PASSPORT_COPY = 'Buyer Passport Copy';
    public static final String BUYER_EMIRATES_BACK_COPY = 'Buyer Emirates ID BackSideCopy';
    public static final String SELLER_EMIRATES_ID_COPY = 'Seller Emirates ID Copy';
    public static final String SELLER_PASSPORT_COPY = 'Seller Passport Copy';
    public static final String SELLER_EMIRATES_ID_BACK_COPY = 'Seller Emirates ID BackSideCopy';
    public static final String UPLOADED = 'Uploaded';
    public static final String ALLUSERS = 'AllUsers';
    //ServiceTriggerHandler
    public static final String ALDAR_ESTATES_MOVEIN = 'Aldar Estates Move-In';
    public static final String ALDAR_ESTATES_MOVEOUT = 'Aldar Estates Move-Out';
    public static final String ALDAR_ESTATES_MOVEOUTSRTEMPLATE = 'Aldar Estates Move Out';
    public static final String NO_REFERRAL = 'No Referral';
    public static final String NO_REDERRAL = 'No Referral';
    public static final String LEGAL_CLEARED = 'Legal Cleared';
    public static final String OPEN = 'Open';
    public static final String CANCELLATION = 'Cancellation';
    public static final String SALES_CANCELLATION = 'Sales Cancellation';
    public static string CUSTOMER_PORTAL = 'Customer Portal';
    public static string CUSTOMER_APP = 'Customer App';
    public static string TITLE_DEED_APPROVAL = 'Title Deed Approval';
    public static string TRANSFER_EXEC_STATUS_ADM = 'Transfer Execution status in ADM';

  public static string SOQL_DML_OBJECT_ACCESS_MESSAGE ='You do not have permission to perform SOQL/DML on this object sObject';

  //Agent Work
  public static String TRANSFERRED = 'Transferred';

  //---- AML Result
  public static String AML_SCREENING_RESULT = 'No Risk Identified - Proceed';

  //Design Types
  public static String DESIGNTYPE_MEDITERRANEAN = 'Mediterranean';

  //----- Resident Status
  public static String RESIDENTSTATUS_RESIDENT = 'Resident';
  public static String RESIDENTTYPE_NON_RESIDENT = 'Non-Resident';


  //EOI Status
  public static String EOISTATUS_UNITCONFIRMED ='Unit Confirmed';
  public static String EOI_PAID = 'Paid';

  public static String OFFER_ON_MEMBERSHIP ='Membership';
  public static String OFFER_ON_HOME_MAINTENNANCE_FEE ='Home Maintenance Fees';
  public static String OFFER_ON_ADM_FEE ='ADM Fees';
  public static String OFFER_ON_SERVICE_CHARGES='Service Charges';
  public static String OFFER_TYPE_REBATE='Rebate';

  //External Comission Basis
  public static String COMISSIONBASIS_PERCENT ='Percent';
  public static String COMISSIONBASIS_AMOUNT ='Amount';

  //---- Sales Cancellation Status
  public static String DOWN_PAYMENT_STATUS_PAID = 'Paid';
  public static String DOWN_PAYMENT_STATUS_UNPAID = 'Unpaid';

  public static String CANCELLATION_STATUS_AWAITING_APPROVAL = 'Awaiting approval';
  public static String CANCELLATION_STATUS_APPROVED = 'Approved';

  public static String CANCELLATION_REASON_OTHER = 'Other';

  public static String KIOSKSELECTION_WALKIN = 'Walk In Leads';

  public static String SO_RECORD_TYPE_RTO = 'RTO';
  public static String UNIT_RECORD_TYPE_PLOT = 'Plot';
  public static String AGREEMENTTYPE_SALES_AGREEMENT = 'Sales Agreement';

  //----- Default and Termination -----
  public static String DEFAULT_AND_TERMINATION = 'Default And Termination';
  public static String STEP_STATUS_PENDING = 'Pending';
  public static String STEP_STATUS_COMPLETED = 'Completed';
  public static String STEP_STATUS_CANCELLED = 'Cancelled';
  public static String SR_STATUS_CLOSED = 'Closed';
  public static String STEP_STATUS_CUSTOMER_SETTELED = 'Customer Settled';
  public static String STEP_STATUS_TRANSFER_LEGAL = 'Transfer to Legal';
  public static String STEP_NAME_COURT_FILING = 'Court filing by Legal';
  public static String STEP_NAME_CUSTOMER_NEGOTIATION = 'Customer Negotiation';
  public static String DOC_TYPE_PAYMENTREMINDER ='Payment Reminder Letter';
  public static String DOC_TYPE_RTOREMINDER ='RTO Renewal Reminder';
  public static String DOC_TYPE_MILESTONE_CHANGELETTER ='Milestone Change Letter';
  public static String DOC_TYPE_DEFAULT_NOTICE ='Default Notice';
  
    //BANK INTEGRATION - VA - SARAVANAN_SEKAR
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

    //Bank Integration - Virtual Account - Mashreq Bank - Anuroop Vipin
    public static String MASHREQ_VA_COMPLETED = 'COMPLETED';
    public static String MASHREQ_VA_FAILED = 'FAILED';
    public static String MASHREQ_VA_INITIATED = 'INITIATED';
    public static String MASHREQ_VA_REJECTED = 'REJECTED';
    public static String MASHREQ_VA_COMPLETED_CODE = '200';
    public static String MASHREQ_VA_FAILED_CODE = '500';
    public static String MASHREQ_VA_INITIATED_CODE = '201';
    public static String MASHREQ_VA_REJECTED_CODE = '400';

  /* ---- Handover Process --- */
  public static String ASITE_UNIT_CLEARED ='Released for QA';
  public static String RECORDTYPE_HANDOVER ='Handover';
  public static String QA_SNAGGING_STEP ='QA Snagging';
  public static String QA_DESNAGGING_STEP ='QA Desnagging';
  public static String CUSTOMER_SNAGGING_STEP ='Home Orientation';
  public static String CUSTOMER_DESNAGGING_STEP ='Ready for Occupancy';
  public static String HO_HC_LETTER ='Handover Completion Letter';
  public static String HO_HO_LETTER ='Home Orientation Letter';
  public static String HO_RFO_LETTER ='Ready For Occupancy Letter';
  public static String HO_SNAGGING_LETTER ='Handover Snagging Letter';
  public static String HO_HP_LETTER ='Handover Phasing Letter';
  public static String STEP_STATUS_SENT ='Sent';
  public static String STEP_NAME_KAR_ASSIGNMENT = 'KAR Assignment / Billing';
  public static String STEP_NAME_FINANCE_VERIFICATION ='Finance Verification';
  public static String SR_STATUS_PENDING_FINANCE_VERIFICATION ='Pending Finance Verification';
  public static String STEP_STATUS_APPOINTMENT_BOOKED ='Appointment Booked';
  public static String SR_STATUS_FINANCE_VERIFICATION_COMPLETED ='Finance Verification Completed';
  public static String STEP_NAME_DESNAGGING_APPOINTMENT = 'Desnagging Appointment';
  public static String STEP_NAME_UTILITY_TRANSFER = 'Customer Utility Transfer';
  public static String STEP_NAME_KEYHANDOVER_APPOINTMENT = 'Customer Key Handover Appointment';
  public static String STEP_NAME_HOPRECHECK = 'Home Orientation Pre-Check';
  public static String STEP_NAME_SNAGGING_APPOINTMENT = 'Customer Home Orientation Appointment';
  public static String STEP_NAME_HANDOVER_PHASING = 'Handover Phasing';
  public static String STEP_NAME_TITLE_DEED = 'Title Deed Registration';
  public static String STEP_NAME_UPLOAD_TITLE_DEED = 'Upload Title Deed';
  public static String HO_STATUS_READY = 'Ready for Handover';
  public static String HO_STATUS_INPROGRESS = 'Handover In Progress';
  public static String HO_STATUS_COMPLETED = 'Handover Completed';
  public static String HO_STAGE_OFFERED_BY_PROJECTS = 'Offered By Projects';
  public static String HO_STAGE_RELEASED_BY_QA = 'Released by QA';
  public static String HO_DOC_CUST_DESNAG = 'Customer Desnagging';
  public static String HO_DOC_CUST_SNAG = 'Customer Snagging';
  public static String HO_TRANSSTATUS_NOTREADY = 'Not Ready ';
  public static String HO_TRANSSTATUS_NOTSTRTED = 'Not Started';
  public static String HO_TRANSSTATUS_INPROGRESS = 'In Progress';
  public static String HO_TRANSSTATUS_COMPLTED = 'Completed';
  public static String DOC_SIGNED_KEY_RECEIPT = 'Signed Early Handover Undertaking Letter';
  public static String DOC_SIGNED_DECLARATIONOFADHERENCE ='SignedDeclarationofAdherence';
  public static String DOC_SIGNED_KEY_FORM = 'Signed Key Acceptance Form';
  public static String DOC_SIGNED_NOC = 'Signed Handover NOC Letter';
  public static String EVENT_HO = 'Customer Home Orientation - ';
  public static String TASK_HO_CALL = 'Courtesy Call - 7 Days After Home Orientation - ';
  public static String TASK_HO_CALL_7 = 'Courtesy Call - 7 Days After Home Orientation - ';
  public static String TASK_HO_CALL_14 = 'Courtesy Call - 14 Days After Home Orientation - ';
  public static String TASK_HO_CALL_48 = 'Home Orientation PreCheck 48 hours before remainder Task - ';
  public static String TASK_RFO_CALL = 'Handover Payment Remainder - ';
  public static String HANDOVER_NOC_LETTER = 'Handover NOC Letter';

  /* ---- Appointment Types --- */
  public static String HO_HOME_ORIENTATION ='HO_HOME_ORIENTATION';
  public static String HO_DESNAGGING ='HO_DESNAGGING';
  public static String HO_KEYHANDOVER ='HO_KEYHANDOVER';
  public static String ASSESSMENT ='Assessment';
  public static String RESOLUTION ='Resolution';

     /* ---- Service Appointment Work Types --- */
    public static String HOME_ORIENTATION_SCHEDULED ='Home Orientation - Scheduled';
    public static String DESNAGGING_SCHEDULED ='Desnagging - Scheduled';
    public static String KEY_HANDOVER_SCHEDULED ='Key Handover - Scheduled';
    public static String SHOW_AROUND_SCHEDULED ='Show Around - Scheduled';
    public static String BANK_VALUATION_SCHEDULED ='Bank Valuation - Scheduled';

  /* ---- Outbound Call --- */
  public static String OUTBOUND_LOGIN ='OutboundLogin';
  public static String OUTBOUND_CONTACTLIST ='OutboundContactList';
  public static String OUTBOUND_CALL ='OutboundCall';
  public static String CONTACTLIST_PAYMENT_REMINDER ='Payment Reminder Calling List - Agentless';

  //Receipt Ack Payment sub Type
  public static String PAYMENT_SUB_TYPE_REBATE ='Rebate';
  public static String PAYMENT_SUB_TYPE_HO_REBATE ='Handover Rebate';

  //Case COntact Type
  public static String CASE_CUSTOMER_TENANT ='Tenant';
  public static String CASE_CUSTOMER_VISITOR ='Visitor';

  //RA reversal reasons
  public static String REV_REASON_ACCOUNTING_ERROR ='Accounting error';
  public static String REV_REASON_BOUNCED_CHEQUE_NO_DEF ='Bounced cheque w/o Default notice';
  public static String REV_REASON_ACCOUNT_CLOSED ='Account Closed';
  public static String REV_REASON_AMOUNT_MISMATCH ='Amount In Words and Num Mismatch';
  public static String REV_REASON_INSUFFICIENT_FUND ='Insufficient Funds';
  public static String REV_REASON_IRREGULAR_SIGNATIRE ='Irregular Signature';
  public static String REV_REASON_ALTERATION ='Alteration w/o proper Endorsement';
  public static String REV_REASON_SWIFT_CONFIRMATION ='Swift Confirmation Awaited From Issuing Bank';
  public static String REV_REASON_INVALID_DATE ='Invalid Date/Stale Date';
  public static String REV_REASON_RETURN_LESS ='Return-Less Security/Warning band Missing';

  //Duration for Case Entitlement
  public static Integer CASEHOURS = 9;
  public static Integer CASEMINUTES = 60;

  //Default type
  public static String HANDOVER_DEFAULT = 'Handover Defaulter';
  public static String MILESTONE_DEFAULT = 'Milestone Defaulter';
  public static String REVERSAL_RESON_PAYMENTREVERSAL = 'Payment Reversal';

  //RTO Renewal
  public static String RTORENEWALTYPE = 'RTO Renewal';
  public static String STEPNAME_VERIFY_DETAILS = 'Verify Details';
  public static String STEPNAME_UPLOAD_SIGNED_CONTRACT = 'Upload Signed Contract';
  public static String STEPNAME_TAWTHEEQ_REGISTRATION = 'Tawtheeq Registration';
  public static String DOCNAME_TAWTHEEQ_LETTER = 'Tawtheeq Registration Letter';
  public static String DOCNAME_SIGNED_LEASING_LETTER = 'Signed Leasing Offer Letter';
  public static String DOCNAME_SIGNED_TENANCY_AGREEMENT = 'Signed Tenancy Agreement';
    
  /*------- Sales Order Inventory Launch Tyoes -----*/
  public static final String SALESORDER_INVENTORY_TYPE_INVENTORY = 'Inventory';
  public static final String SALESORDER_INVENTORY_TYPE_LAUNCH = 'Launch';
  public static final String HEAD_OF_BROKER = 'Head of Broker Management';
  public static final String ASSOCIATE_DIRECTOR_OF_SALE = 'Associate Director of Sales';
  public static final String EXECUTIVE_DIRECTOR_OF_SALES = 'Executive Director of Sales';
  public static final String CASA_VP = 'CASA VP';
  public static final String CCO = 'CCO';
  public static final String WEALTH = 'WEALTH';
  public static final String CORPORATE = 'CORPORATE';
    public static final Decimal PERCENTAGE30CALCULATION = 0.50; //Updated as suggested by Vijendra
  public static final String TEAM_LAND = 'LAND';
  public static final Integer EQUITY_PERCENTAGE = 20;
  public static final Decimal PERCENTAGE75CALCULATION = 0.75;
  public static final Decimal PERCENTAGE25CALCULATION = 0.25;
  public static final Decimal KPI100PERCENTAGE = 100;
  public static final String COMMISSIONCURRENT = 'Current';
  public static final String COMMISSIONFUTURE = 'Future';
  
  /*------- Offline Request -----*/
  public static final String ALDAR_BUSINESS_HOURS = 'Aldar Business Hours'; 
  public static final String SUNDAY = 'Sunday';
  public static final String MONDAY = 'Monday';
  public static final String TUESDAY = 'Tuesday';
  public static final String WEDNESDAY = 'Wednesday';
  public static final String THURSDAY = 'Thursday';
  public static final String FRIDAY = 'Friday';
  public static final String SATURDAY = 'Saturday';
  public static final String CUSTOM_NOTIFICATION_MSG = ' requested for the Offline Request Approval';
  public static final String CUSTOM_NOTIFICATION_TITTLE = 'Offline Request';
  public static final String CUSTOM_NOTIFICATION_API_NAME = 'OfflineRequestNotification';
  public static final String OFFLINE_REQUEST_STATUS_APPROVE = 'Approved';
  public static final String OFFLINE_REQUEST_STATUS_AWAITING_APPROVAL = 'Awaiting approval';  
    
  //Case Priority
  public static final String CODE_RED_PRIORITY = 'Code Red'; 
  public static final String APPOINMENT_CANCELLED = 'Cancelled';
  public static final String APPOINMENT_UPDATED = 'Updated';
    
  public static final String DLP_CLOSURE_REASON_NOT_UNDER_DLP = 'Not under the DLP scope'; 
  public static final String DLP_CLOSURE_REASON_COMMON_AREA_DLP = 'Common Area Related'; 
  public static final String DLP_CLOSURE_REASON_CUSTOMER_NOT_AVAILABLE = 'Customer Not Available - No Access'; 
       
   public static final String HANDOVER_HO = 'HANDOVER_HO'; 
   public static final String HANDOVER_KH = 'HANDOVER_RT'; 
   public static final String HOME_ORIENTATION_LETTER = 'Home Orientation'; 
   public static final String KEY_HANDOVER = 'Key Handover'; 
   
   public static final String HANDOVER_PROPERTYTRANSFER_DEAL_TYPE = 'Property Transfer'; 
   public static final String HANDOVER_RTO_DEAL_TYPE = 'RTO'; 
   public static final String HANDOVER_RTO_CONVERTED_DEAL_TYPE = 'RTO Converted';
   public static final String HANDOVER_RTO_CONVERTED_DEAL_TYPE_STATUS = 'RTOConverted';
   public static final String HANDOVER_NEW_SALE = 'New Sale';
    
   public static final String DPL_BY_CONTRACTOR = 'DLP by Contractor'; 
   public static final String DLP_BY_HOMEX = 'DLP by HomeX'; 
   public static final String AMC_BY_HOMEX = 'AMC by HomeX'; 
   public static final String PROJECT_NAME_FILTER = 'AlGurm-Phase2'; 
    
  // Account Customer Types
  public static final String ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF = 'Aldar Staff';
  //Account Customer Sub-Type
  public static final String ACCOUNT_CUSTOMER_SUBTYPE_CORPORATE = 'CORPORATE';  
    // ASF-3647: Account Agency Category 
    public static final String ACCOUNT_AGENCY_CATEGORY_WEALTH_INTRODUCER = 'Wealth Introducer';
    public static final String ACCOUNT_AGENCY_CATEGORY_BROKER = 'Broker';
    public static final String ACCOUNT_AGENCY_CATEGORY_LSQ_BROKERS= 'LSQ brokers';    
  //Offer Line Customer Types
  public static Set<String> OFFER_LINE_CUSTOMERTYPES = new Set<String>{'CORPORATE','VIP TIER 1','VVIP TIER 2','VVVIP TIER 3', 'WEALTH'};
    //Unit Statuses
    public static final List<String> UNIT_STATUSES = new List<String>{'Reserved','Approve pending','Sold','reservation in progress'};
    public static String RESALE_RELATIONSHIP_MANAGER = 'Resale Relationship Manager';
    
    
     //Unit Assignement 
     public static string APPROVAL_STATUS_PENDING_APPROVAL = 'Pending approval';

    //CaseTriggerHandler 
    public static final String GFA = 'GFA';
    public static final String NONGFA = 'Non GFA';
    public static final String HOMEFINANCECASE = 'Home Finance Case';
    public static final String INTERNAL = 'Internal';
    public static final String FINANCE_AFTER_APPROVED_EMAILTEMPLATE = 'FinanceAfterApprovedEmailTemplate';
    public static final String DISTRICT_MANAGEMENT_CAFM = 'District Management CAFM'; 
    public static final String DISTRICT_MANAGEMENT = 'District Management';
    public static final String CASE_HANDLING_QUEUE = 'Case Handling Queue';
    public static final String DEV_CONTROL_GROUP = 'Dev Control Group';
    public static final String CREATE = 'Create';
    public static final String CANCELLED = 'Cancelled';
    public static final String ON_DEMAND = 'On Demand';
    public static final String SALES_QUEUE = 'Sales queue';
    public static final String RESALE_QUEUE = 'ReSale queue';
    public static final String EMERGENCY = 'Emergency';
    public static final String WITHIN_SLA = 'Within SLA';
    public static final String OUT_OF_HOME = 'Out of home';
    public static final String NOC_FOR_UNIT_MODIFICATIONS = 'NOC for Unit modifications';
    public static final String ACCESS_CARD = 'Access Card';
    public static final String PROVIS = 'Provis';
    public static final String PET_REGISTRATION = 'Pet Registration';
    public static final String BOOKING = 'Booking';
    public static final String COMMON_AREA_MAINTENANCE = 'Common Area Maintenance';
    public static final String COMMUNITY_MANAGEMENT = 'Community Management';
    public static final String COMMUNITY_MANAGEMENT_OA = 'Community Management/OA';
    public static final String OTHER_REQUEST = 'Other Requests';
    public static final String TENANT_ONBOARDING = 'Tenant Onboarding';
    public static final String NEW_SALE = 'New Sale';
    public static final String TENANCY = 'Tenancy';
  
    //General Service API
    public static final Map<String, Map<String, Object>> CASE_TYPE_CATALOG = new Map<String, Map<String, Object>>{
        'Other Requests' => new Map<String, Object>{
            'RecordTypeId' => Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Query')).getRecordTypeId(),
            'CustomerType__c' => 'Owner',
            'Subject' => 'Other Requests ',
            'ECSS_CompanyOptions__C' => 'Provis',
            'SubVertical__c' => 'Provis',
            'CaseCategory__c' => 'Community Management/OA',
            'ECSS_Sub_Category_Text__c' => 'Community Management/OA',
            'ECSS_Object_Category__c' => 'Community Management/OA'
        },
        'Booking' => new Map<String, Object>{
            'RecordTypeId' => Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Query')).getRecordTypeId(),
            'CustomerType__c' => 'Owner',
            'Subject' => 'Booking',
            'ECSS_CompanyOptions__C' => 'Provis',
            'SubVertical__c' => 'Provis',
            'CaseCategory__c' => 'Booking',
            'ECSS_Sub_Category_Text__c' => 'Booking',
            'ECSS_Object_Category__c' => 'Booking'  
        },
        'Pet Registration' => new Map<String, Object>{
            'RecordTypeId' => Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Query')).getRecordTypeId(),
            'Subject' => 'Pet Registration',
            'CustomerType__c' => 'Owner',
            'ECSS_CompanyOptions__C' => 'Provis',
            'SubVertical__c' => 'Provis',
            'CaseCategory__c' => 'Pet Registration',
            'ECSS_Sub_Category_Text__c' => 'Pet Registration',
            'ECSS_Object_Category__c' => 'Pet Registration'   
        },
        'Complaints' => new Map<String, Object>{
            'RecordTypeId' => Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Complaint')).getRecordTypeId(),
            'Subject' => 'Complaints',
            'CustomerType__c' => 'Owner',
            'ECSS_CompanyOptions__C' => 'Provis',
            'SubVertical__c' => 'Provis',
            'CaseCategory__c' => 'Community Management',
            'ECSS_Sub_Category_Text__c' => 'Complaints',
            'ECSS_Object_Category__c' => 'Complaints' 
        },
        'Common Area Maintenance' => new Map<String, Object>{
            'RecordTypeId' => Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Query')).getRecordTypeId(),
            'Subject' => 'Common Area Maintenance',
            'CustomerType__c' => 'Owner',
            'ECSS_CompanyOptions__C' => 'Provis',
            'SubVertical__c' => 'Provis',
            'CaseCategory__c' => 'Common Area Maintenance',
            'ECSS_Sub_Category_Text__c' => 'Common Area Maintenance',
            'ECSS_Object_Category__c' => 'Common Area Maintenance'  
        },
        'Access Card' => new Map<String, Object>{
            'RecordTypeId' => Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Query')).getRecordTypeId(),
            'Subject' => 'Access Card',
            'CustomerType__c' => 'Owner',
            'ECSS_CompanyOptions__C' => 'Provis',
            'SubVertical__c' => 'Provis',
            'CaseCategory__c' => 'Access Card',
            'ECSS_Sub_Category_Text__c' => 'Access Card',
            'ECSS_Object_Category__c' => 'Access Card'   
        },
        'NOC for Unit modifications' => new Map<String, Object>{
            'RecordTypeId' => Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Query')).getRecordTypeId(),
            'Subject' => 'NOC for Unit modifications',
            'CustomerType__c' => 'Owner',
            'ECSS_CompanyOptions__C' => 'Provis',
            'SubVertical__c' => 'Provis',
            'CaseCategory__c' => 'NOC for Unit modifications',
            'ECSS_Sub_Category_Text__c' => 'NOC for Unit modifications',
            'ECSS_Object_Category__c' => 'NOC for Unit modifications'   
        },
        'Out of home' => new Map<String, Object>{
            'RecordTypeId' => Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Query')).getRecordTypeId(),
            'Subject' => 'Out of home',
            'CustomerType__c' => 'Owner',
            'ECSS_CompanyOptions__C' => 'Provis',
            'SubVertical__c' => 'Provis',
            'CaseCategory__c' => 'Out of home',
            'ECSS_Sub_Category_Text__c' => 'Out of home',
            'ECSS_Object_Category__c' => 'Out of home'   
        }
    }; 
    
}