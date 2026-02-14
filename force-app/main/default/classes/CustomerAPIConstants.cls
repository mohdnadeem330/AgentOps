/*

* Name               : CustomerAPIConstants

* Description        :
* Version            : V1.1 Added by Protiviti when retail contact logic added to CustomerProfileWeservice class.
*/
public class CustomerAPIConstants {
    
    //--- Payment URL
    public static String PAYMENT_PRODUCTION_URL = 'https://aldarproperties.my.salesforce-sites.com/PaymentProcessing';
    public static String PAYMENT_SANDBOX_URL = 'https://aldarproperties--pruat.sandbox.my.salesforce-sites.com/PaymentProcessing';

    //--- Language
    public static String LANGUAGE_EN = 'en';
    public static String LANGUAGE_AR = 'ar';

    //--- Unit Type
    public static String UNIT_TYPE_OFF_PLAN = 'Off Plan Unit';
    public static String UNIT_TYPE_READY = 'Ready Unit';
    public static String UNIT_TYPE_PLOT = 'Plot';

    //--- Payment Status
    public static String PAYMENT_STATUS_CLEARED = 'Cleared';
    public static String PAYMENT_STATUS_UPCOMING_PAYMENT = 'Upcoming';
    public static String PAYMENT_STATUS_FUTURE_PAYMENT = 'Future';
    public static String PAYMENT_STATUS_HANDOVER_PAYMENT = 'Handover';
    public static String PAYMENT_STATUS_OUTSTANDING = 'Outstanding';
    public static String PAYMENT_STATUS_UNPAID = 'Unpaid';
    public static String PAYMENT_STATUS_PAYMENT_DUE = 'Payment Due';
    public static String PAYMENT_STATUS_RECEIVED = 'Received';
    public static String PAYMENT_STATUS_PAID = 'Paid';
    public static String PAYMENT_STATUS_CONFIRMED = 'Confirmed';
    public static String PAYMENT_STATUS_IN_PROCESS = 'Payment in Progress';
    public static string INSTALLMENT_PAYMENT = 'Installment';
    public static string DOWN_PAYMENT = 'Down Payment';
    //Added By Neelesh

    //--- Data Type
    public static String DATA_TYPE_MAP = 'map';
    public static string DATA_TYPE_ARRAY = 'array';
    public static string DATA_TYPE_DATE = 'date';
    public static string DATA_TYPE_STRING = 'string';
    public static string DATA_TYPE_NUMBER = 'nummber';
    public static string DATA_TYPE_CURRENCY = 'currency';
    public static string DATA_TYPE_PERCENTAGE = 'percentage';

    public static string ATTENDEE_TYPE_CODE = 'Customer';

    //--- Status
    public static string STATUS_ACTIVE = 'Active';
    public static string STATUS_EXPIRED = 'Expired';

    public static String BLACKLISTED_CUSTOMER_COMPLIANCE = 'Compliance';
    public static String BLACKLISTED_CUSTOMER_DEFAULT = 'Default';
    public static String BLACKLISTED_CUSTOMER_LEGAL = 'Legal';

    //--- Appointment Type
    public static string APPOINTMENT_LABEL_HOME_ORIENTATION = 'Home Orientation';
    public static string APPOINTMENT_TYPE_HOME_ORIENTATION = 'Snagging';
    public static string APPOINTMENT_LABEL_SNAG_VERIFICATION = 'Snag Verification';
    public static string APPOINTMENT_TYPE_SNAG_VERIFICATION = 'DeSnagging';
    public static string APPOINTMENT_LABEL_KEY_HANDOVER = 'Key Collection';
    public static string APPOINTMENT_TYPE_KEY_HANDOVER = 'KeyHandover';

    //--- Web-Service Messages
    public static String MESSAGE_MULTI_ACCOUNT_FOUND = 'There is more than one account with this email';
    //V1.1 Added by Protiviti when retail contact logic added to CustomerProfileWeservice class.
    public static String MESSAGE_MULTI_ACCOUNT_CONTACT_FOUND = 'There is more than one account and contact with this email';
    public static String MESSAGE_MULTI_CONTACT_FOUND = 'There is more than one contact with this email';
    public static String MESSAGE_NO_CONTACT_FOUND = 'No Contact Found, Please verify your Email/Emirates Id or contact Aldar';
    public static String MESSAGE_NO_DATA_FOUND = 'No Contact or Account Found, Please verify your Email/Emirates Id or contact Aldar';
    //V1.1 Added by Protiviti Ends here
    public static String MESSAGE_NO_ACCOUNT_FOUND = 'No Account Found, Please verify your Email/Emirates Id or contact Aldar';
    public static String MESSAGE_BLANK_REQUEST_PARAMETERS = 'Please provide Email or Emirates Id';
    public static String MESSAGE_DOCUMENT_NOT_FOUND = 'No document found, please try again after some time';
    public static String MESSAGE_GENERIC_ERROR = 'An error occured could you please try again by validating the information you have provided.';

    public static String MESSAGE_PAYMENT_ERROR = 'This amount is not authorised.';

    public static String MULTI_SIGNATURES_FOUND = 'Document is delivered via email for signing since there are several signatures on it.';

    public static String RETURN_SUCCESS = 'Success';
    public static String RETURN_ERROR = 'Error';

    public static String DOCUMENT_STATUS_PENDING = 'Pending';
    public static String DOCUMENT_STATUS_PENDING_UPLOAD = 'Pending Upload';
    public static String DOCUMENT_STATUS_DOCUSIGN_PENDING = 'DocuSign Pending';

    public static String ALL = 'All';
    
    public static final Integer STATUS_CODE_SYSTEM_MULTI_ACCOUNT = 409;
    public static final Integer STATUS_CODE_SYSTEM_MULTI_CONTACT = 409;//V1.1 Added by Protiviti

    //--- Fast Track
    public static String STEP_UPLOAD_DOCUMENTS = 'Upload Documents';
    public static String STEP_SIGN_DOCUMENTS = 'Sign Documents';

    public static String STATUS_FAST_TRACK_VALID = 'Valid';
    public static String STATUS_FAST_TRACK_INVALID = 'Invalid';
    public static String STATUS_FAST_TRACK_COMPLETED = 'Completed';

    public static String MESSAGE_FAST_TRACK_VALID = 'Enjoy a faster check-in process with us.';
    public static String MESSAGE_FAST_TRACK_INVALID = 'Fast Track reference is invalid. Please click on the email link to proceed.';
    public static String MESSAGE_FAST_TRACK_ALREADY_COMPLETED = 'Your Fast Track has already been submitted successfully.';

    //--- Installment Type
    public static string TYPE_DOWN_PAYMENT = 'Down Payment';
    public static string TYPE_INSTALLMENT_PAYMENT = 'Installment Payment';
    //Added by neelesh
    public static string PARKING_PAYMENT = 'Parking Payment';
    public static string TYPE_FINAL_PAYMENT = 'Final Payment';

    public static string DESCRIPTION_DOWN_PAYMENT = 'Upon Signing SPA';
    public static string DESCRIPTION_INSTALLMENT_PAYMENT = 'Construction Payment';
    public static string DESCRIPTION_FINAL_PAYMENT = 'Handover Payment';

    public static string ADJUSTMENT_WRITE_OFF = 'Adjustment Write Off';

    //--- Document Category
    public static string DOCUMENT_CATEGORY_PERSONAL_DOCUMENT = 'Personal Document';
    public static string DOCUMENT_CATEGORY_PROPERTY_DOCUMENT = 'Property Document';

    //--- Document Type
    public static string DOCUMENT_TYPE_PROFILE_PICTURE = 'Profile Picture';
    public static string DOCUMENT_TYPE_CIS_SHEET = 'CIS Sheet';
    public static string DOCUMENT_TYPE_SIGNED_CIS_SHEET = 'Signed CIS Sheet';
    public static string DOCUMENT_TYPE_SIGNED_KYC_FORM = 'Signed KYC Form';
    //--- API Setting
    public static string DOCUSIGN_AUTHENTICATION = 'DocuSignAuthentication';
    public static string DOCUSIGN_ENVELOPE = 'DocuSignEnvelope';
    public static string DOCUSIGN_URL = 'DocuSignURL';

    //--- Constant
    public static string DOCUSIGN_PUBLIC_KEY = 'DocuSignPublicKey';
    public static string DOCUSIGN_PRIVATE_KEY = 'DocuSignPrivateKey';
    public static string DOCUSIGN_SIGNATURE_HOLDER = 'SignatureHolder';
    public static string DOCUSIGN_STATUS_SENT = 'sent';

    //--- Case Status Reason
    public static string CASE_STATUS_REASON_WITH_RESOLUTION = 'With Resolution';
    public static string CASE_STATUS_REASON_WITHOUT_RESOLUTION = 'Without Resolution';
    public static string CASE_STATUS_PENDING = 'Pending';
    public static string CASE_STATUS_PENDING_WITH_CUSTOMER = 'Pending with Customer';

    //--- Case Origin
    public static string CASE_ORIGIN_CUSTOMER_PORTAL = 'Customer Portal';
    public static string CASE_ORIGIN_CUSTOMER_APP = 'Customer App';
    
    public static string CASE_DLP_RECORD_TYPE = 'DLP';
    
    public static string CUSTOMER_PORTAL_AND_APP = 'Customer Portal and App';
    public static string OTHER = 'Other';

    public static string CASE_SUBJECT_STOP_PAYMENT = 'Deferral';
    public static string TYPE_PLOT_DESIGN = 'Plot Design';

    public static string CCA_ONLINE_QUEUE = 'CCA Online';

    public static string CASE_CUSTOMER_TYPE_OWNER = 'Owner';

    public static string PROPERTY_CERTIFICATE = 'Property Certificate';
    public static string FEEDBACK = 'Feedback';

    public static string CASE_UPDATE_PROFILE_SUBJECT = 'Update Profile';

    public static string CASE_CUSTOMER_CARE = 'Customer Care';
    
    public static string MULTI_ACCOUNT_FOUND_SUBJECT = 'Multiple accounts have been identified for email:';
    public static string MULTI_ACCOUNT_FOUND_LOGIN = 'Multiple accounts found during Login';
    public static string MULTI_ACCOUNT_FOUND_REGISTRATION = 'Multiple accounts found during Registration';
    //V1.1 Added by Protiviti
    public static string MULTI_CONTACT_FOUND_SUBJECT = 'Multiple contacts have been identified for email:';
    public static string MULTI_CONTACT_FOUND_LOGIN = 'Multiple contacts found during Login';
    public static string MULTI_CONTACT_FOUND_REGISTRATION = 'Multiple contact found during Registration';
	//V1.1 Added by Protiviti Ends here

    //--- Status
    public static string STATUS_NEW = 'New';
    public static string STATUS_PROCESSING = 'Processing';
    public static string STATUS_IN_PROGRESS = 'In Progress';
    public static string STATUS_CLOSED = 'Closed';

    public static string DDR_APPROVED_BY_BANK = 'Approved by Bank';

    public static string SR_STATUS_CLOSED = 'Closed';

    //--- Payment Mode
    public static string PAYMENT_MODE_DIRECT_DEBIT = 'Direct Debit';
    //Added By Neelesh@Aldar 27/02/25 Premium Parking
    public static string PAYMENT_MODE_ONLINE = 'Online';
    //--- Step Name
    public static string STEP_HOME_ORIENTATION = 'Home Orientation';
    public static string STEP_TITLE_DEED_REGISTRATION = 'Title Deed Registration';
    public static string STEP_KEY_HANDOVER = 'Key Handover';
    public static string STEP_PROPERTY_SECURED = 'Property Secured';
    public static string STEP_PROPERTY_SECURED_AR = 'الملكية مؤمنة';

    //--- Document
    public static string DOCUMENT_NATIONAL_ID_FRONT_COPY = 'National ID Front Copy';
    public static string DOCUMENT_NATIONAL_ID_BACK_COPY = 'National ID Back Copy';
    public static string DOCUMENT_PASSPORT_COPY = 'Passport Copy';
    public static string DOCUMENT_VISA_COPY = 'Visa Copy';
    public static string DOCUMENT_TRADE_LICENSE = 'Trade License';
    public static string DOCUMENT_SIGNED_KYC = 'Signed KYC Form';
    public static string DOCUMENT_OTHERS = 'Others';

    public static string DOC_SPA_ALDAR_COPY = 'SPA Aldar Copy';
    public static string DOC_SPA_CUSTOMER_COPY = 'SPA Customer Copy';

    public static string DOCUMENT_SPA_CUSTOMER_COPY = 'SPA-Customer Copy';
    public static string DOCUMENT_SIGN_SPA = 'Sign SPA';
    public static string DOCUMENT_SIGNED_SPA = 'Signed SPA';
    public static string DOCUMENT_CANCELLATION_AGREEMENT = 'Cancellation Agreement';
    public static string DOCUMENT_SPA_DELIVERY_LETTER = 'SPA Delivery Letter';

    public static string DOCUMENT_SUPPORTING_DOCUMENTS = 'Supporting Documents';
    public static string DOCUMENT_TITLE_DEED = 'Title Deed';
    public static string DOCUMENT_CONSULTANT_CERTIFICATE_LETTER = 'Consultant Certificate Letter';
    public static string DOCUMENT_SELLER_PASSPORT_COPY = 'Seller Passport Copy';
    public static string DOCUMENT_SELLER_EMIRATES_ID_COPY = 'Seller Emirates ID Copy';
    public static string DOCUMENT_BUYER_PASSPORT_COPY = 'Buyer Passport Copy';
    public static string DOCUMENT_BUYER_EMIRATES_ID_COPY = 'Buyer Emirates ID Copy';
    public static string DOCUMENT_PROVIS_NOC = 'Provis NOC';
    public static string DOCUMENT_EXISTING_TITLE_DEED = 'Existing Title Deed';
    public static string DOCUMENT_JOINT_OWNER_PASSPORT_COPY = 'Joint Owner Passport Copy';
    public static string DOCUMENT_JOINT_OWNER_EMIRATES_ID_COPY = 'Joint Owner Emirates ID Copy';
    public static string DOCUMENT_PROVIS_DEVELOPMENT_NOC = 'Provis/Development NOC';
    public static string DOCUMENT_EID_TRADE_LICENSE = 'EID/Trade License';
    public static string DOCUMENT_TITLE_DEED_COPY = 'Title Deed Copy';
    public static string DOCUMENT_EMIRATES_ID_TRADE_LICENSE_COPY = 'Emirates ID /Trade License Copy';
    public static string DOCUMENT_FULLY_SIGNED_CLIENT_INFORMATION_SHEET = 'Fully Signed Client Information Sheet';

    public static string DOCUMENT_SPA_REGISTRATION_DOCUMENTS = 'SPA Registration Documents';

    public static string DOCUMENT_HOME_ORIENTATION_LETTER = 'Home Orientation Letter';
    public static string DOCUMENT_HANDOVER_LETTER = 'Handover Letter';
    public static string DOCUMENT_CUSTOMER_SNAGGING = 'Customer Snagging';
    public static string DOCUMENT_HOME_ORIENTATION_REPORT = 'Home Orientation Report';
    public static string DOCUMENT_CUSTOMER_DESNAGGING = 'Customer Desnagging';
    public static string DOCUMENT_HANDOVER_PHASING_LETTER = 'Handover Phasing Letter';
    public static string DOCUMENT_DISTRICT_COOLING_TRANSFER = 'District Cooling Transfer';
    public static string DOCUMENT_SERVICE_CHARGES_PAYMENT_PROOF = 'Service Charges Payment Proof';
    public static string DOCUMENT_ADDC_CERTIFICATE = 'ADDC Certificate';
    public static string DOCUMENT_NOC_FOR_ADDC = 'NOC for ADDC';
    public static string DOCUMENT_READY_FOR_OCCUPANCY_LETTER = 'Ready For Occupancy Letter';
    public static string DOCUMENT_HANDOVER_NOC_LETTER = 'Handover NOC Letter';
    public static string DOCUMENT_SIGNED_HANDOVER_NOC_LETTER = 'Signed Handover NOC Letter';
    public static string DOCUMENT_PLOT_POSSESSION_CERTIFICATE = 'Plot Possession Certificate';
    public static string DOCUMENT_SIGNED_PLOT_POSSESSION_CERTIFICATE = 'Signed Plot Possession Certificate';

    //--- API
    public static string NOTIFICATION_CLICK_ACTION = 'fcm.ACTION.NOTIF';
    public static string GRANT_TYPE = 'urn:ietf:params:oauth:grant-type:jwt-bearer';
    public static string DOCUSIGN_EMAIL_SUBJECT = 'Please sign this document';

    public static string CUSTOMER_NOTIFICATION_INTEGRATION = 'customerNotification';
    public static string CUSTOMER_PUSH_NOTIFICATION_INTEGRATION = 'customerPushNotification';
    public static string WHATSAPP_LINK_GENESYS = 'WatsAppLinkGenesys';
}