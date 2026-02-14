/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Constants class for Resale LWC on Opportunity.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Harsh Rohilla   <hrohilla@aldar.com>
* @modifiedBy     
* @maintainedBy   
* @version        1.0
* @created        2023-06-22
* @modified       2023-06-22
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
 */
public with sharing class ResaleConstants {

    public static Boolean RUN_ACCOUNT_TRIGGER_RESALE_SWITCH = TRUE;

    public static String YES = 'Yes';
    public static String STATUS_APPROVED = 'Approved';
    public static String STATUS_IN_PROGRESS = 'In Progress';
    public static String CHARGETYPE_LISTING = 'Listing Fee';
    public static String CHARGETYPE_SC_BUYER = 'Service Charge - Buyer';
    public static String CHARGETYPE_SC_SELLER = 'Service Charge - Seller';
    public static String CATEGORY_RESALE_OPP = 'Resale Opportunity';

    public static Decimal LISTING_PRICE = 1500;

    public static String OPP_STATUS_DISCUSSION_IN_PROGRESS = 'Discussion In Progress';
    public static String OPP_STATUS_PAY_PROGRESS = 'Payment in progress';
    public static String OPP_STATUS_MOU_SIGN_PROGRESS = 'MOU Signature in progress';
    public static String OPP_STATUS_SUBMITTED_LM_APPROVAL = 'Submitted for LM Approval';
    public static String OPP_STATUS_OFFER_ACCEPTED = 'Offer Accepted';
    public static String OPP_STATUS_CLOSED_WON = 'Closed Won';
    public static String OPP_STATUS_PAYMENT_CLEARED = 'Payment Cleared';

    public static String SR_TYPE_PROPERTY_TRANSFER_NOC = 'Property Transfer NOC';
    public static String SR_TYPE_PROPERTY_TRANSFER = 'Property Transfer';
    public static String SR_CHARGETYPE_TRANSFER_NORMAL = 'Transfer Normal';
    public static String SR_RT_TRANSFER_NOC = 'PropertyTransferNOC';
    public static String SR_RT_PROPERTY_TRANSFER = 'PropertyTransfer';

    public static String RO_STATUS_ACCEPTED = 'Accepted';
    public static String RO_STATUS_REJECTED = 'Rejected';
    public static String RO_STATUS_DISQUALIFIED = 'Disqualified';

    public static String RESALE_RECORDTYPE = 'Resale';
    public static String ALDAR_PROPERTIES_ORGWIDEEMAIL_NO_REPLY = 'Aldar Properties';

    public static String UNIT_RESALESTATUS_OFFER_PROGRESS = 'Offer in progress';
    public static String UNIT_RESALESTATUS_MOU_SIGNED = 'MOU Signed';
    public static String UNIT_RESALESTATUS_TRANSFER_PROGRESS = 'Transfer in progress';
    public static String UNIT_RESALESTATUS_TRANSFER_COMPLETED = 'Transfer Completed';

    public static String LEAD_STATUS_IN_PROGRESS = 'In Progress Lead';
    public static String LEAD_SOURCE_WALK_IN = 'Walk-In';
    public static String LEAD_SOURCE_DIRECT_EMAIL = 'Direct Email';
    public static String LEAD_SOURCE_DIRECT_CALL = 'Direct Call';
    public static String LEAD_SOURCE_800_ALDAR = '800-Aldar';
    public static String LEAD_SOURCE_ONLINE_LEAD = 'Online';
    public static String LEAD_SOURCE_BROKER_PORTAL = 'Broker Portal';

    public static List<String> RESALE_SALESORDER_STATUSES = new List<String>{ 'Pending', 'Approve Pending', 'Sold' };

    public static String RESALE_CASE_RecordTypeDeveloperName = 'Resale';
    public static Id Resale_Case_RecordTypeId = ResaleService.getRecordTypeId('Case', RESALE_CASE_RecordTypeDeveloperName);
    public static String Resale_Case_RecordTypeName = ResaleService.getRecordTypeName('Case', Resale_Case_RecordTypeId);
    
    public static String RESALE_OPPORTUNITY_RecordTypeDeveloperName = 'Resale';
    public static Id Resale_Opp_RecordTypeId = ResaleService.getRecordTypeId('Opportunity', RESALE_OPPORTUNITY_RecordTypeDeveloperName);
    public static String Resale_Opp_RecordTypeName = ResaleService.getRecordTypeName('Opportunity', Resale_Opp_RecordTypeId);

    public static String SERVICEREQUEST_PROP_TRANSFER_RecordTypeDeveloperName = 'PropertyTransfer';
    public static String SERVICEREQUEST_PROP_TRANSFER_NOC_RecordTypeDeveloperName = 'PropertyTransferNOC';
    
    public static String RESALE_RELATIONSHIP_MANAGER_PROFILE = 'Resale Relationship Manager'; 
    public static Boolean avoidProfileNameSOQL = false; 
    public static Map<String, Profile> PROFILE_NAME_MAP = !avoidProfileNameSOQL ? ResaleService.getProfileByIds(new List<String>{'Resale Relationship Manager'}) : new Map<String, Profile>();
    public static String RESALE_RELATIONSHIP_MANAGER_PROFILEID = PROFILE_NAME_MAP.containsKey('Resale Relationship Manager') ? PROFILE_NAME_MAP.get('Resale Relationship Manager').Id : null;

    public static String CONTACT_CENTER_AGENT = 'Contact Centre Agent'; 
    public static String SALES_MANAGER = 'Sales Manager'; 

    public static String CASE_ORIGIN_ONLINE = 'Online';
    public static String CASE_ORIGIN_CUSTOMER_PORTAL = 'Customer portal';

    public static String CASE_CUSTOMER_INTEREST_INTERESTED = 'Interested';//SSP-348
    
    public static String CASE_NEW = 'New';
    public static String CASE_IN_PROGRESS = 'In Progress';
    public static String CASE_QUALIFIED = 'Qualified';
    public static String CASE_DISCUSSION_IN_PROGRESS = 'Discussion In Progress';
    public static String CASE_AWAITING_LINE_MANAGER_APPROVAL = 'Awaiting Line Manager Approval';
    public static String CASE_REJECTED_BY_LINE_MANAGER = 'Rejected By Line Manager';
    public static String CASE_AGREEMENT_SIGNATURE_IN_PROCESS = 'Agreement Signature In Process';
    public static String CASE_PROPERTY_LISTED = 'Property Listed';
    // public static String CASE_CANCELLATION_IN_PROGRESS = 'Cancellation In Progress';
    public static String CASE_CANCELLED = 'Cancelled';
    public static String CASE_CLOSED = 'Closed';
    public static Set<String> RESALE_CASE_STATUS_BEFORE_AGREEMENT_SIGN = new Set<String>{CASE_NEW, CASE_IN_PROGRESS, CASE_QUALIFIED, CASE_DISCUSSION_IN_PROGRESS, CASE_AWAITING_LINE_MANAGER_APPROVAL, CASE_REJECTED_BY_LINE_MANAGER};
    
    public static String DOCUMENT_PLACEHOLDER_CATEGORY_RESALE_CASE = 'Resale Case';
    
    public static String CASE_DOCUMENT_RECORDTYPE_DNAME = 'Case_Document';
    public static String CASE_LISTING_AGREEMENT_DOCUMENT_TYPE = 'Listing Agreement';
    public static String CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE = 'Signed Listing Agreement';
    public static String DOCTYPE_SIGNED_MOU = 'Signed Listing MOU';
    public static string DOCUMENT_STATUS_UPLOADED = 'Uploaded'; 
    
    public static string RESALE_OPP_MOU_SIGNED_BUYER = 'Buyer completed';
    public static string RESALE_OPP_MOU_SIGNED_SELLER = 'Seller completed'; 
    
    public static String CALL_CUSTOMER = 'Call Customer';
    public static String TASK_TYPE_CALL = 'Call';
    public static String CUSTOMER_REACHED = 'Customer Reached';
    public static String CUSTOMER_NOT_REACHABLE = 'Customer Not Reachable';

    public static String TASK_COMPLETED = 'Completed';

    public static String PERSON_ACCOUNT_RT = 'Person Account';

    public static String SOOC_CLEARED_STATUS = 'Cleared';
    
    public static String CASE_CANCELLATION_REASON_OTHER = 'Other';
    
    public static String RESALE_ACTIVE_SALESORDER_UNIT_VALIDATION = ResaleService.getSystemMessage('RESALE_ACTIVE_SALESORDER_UNIT_VALIDATION');
    public static String RESALE_CASE_OPEN_PER_UNIT_VALIDATION = ResaleService.getSystemMessage('RESALE_CASE_OPEN_PER_UNIT_VALIDATION');
    public static String RESALE_OPEN_SERVICE_REQ_UNIT_VALIDATION = ResaleService.getSystemMessage('RESALE_OPEN_SERVICE_REQ_UNIT_VALIDATION');
    public static String RESALE_INVALID_UNIT_SELECTED_VALIDATION = ResaleService.getSystemMessage('RESALE_INVALID_UNIT_SELECTED_VALIDATION');
    public static String RESALE_CASES_MANY_PER_UNIT_VALIDATION = ResaleService.getSystemMessage('RESALE_CASES_MANY_PER_UNIT_VALIDATION');
    public static String RESALE_CASE_UNIT_NOT_OWNED_VALIDATION = ResaleService.getSystemMessage('RESALE_CASE_UNIT_NOT_OWNED_VALIDATION');
    public static String RESALE_CASE_SIGNED_LISTING_AGREEMENT_REQ = ResaleService.getSystemMessage('RESALE_CASE_SIGNED_LISTING_AGREEMENT_REQ');
    public static String RESALE_CHARGES_CREATED_SUCCESS = ResaleService.getSystemMessage('RESALE_CHARGES_CREATED_SUCCESS');
    public static String RESALE_CHARGES_ALREADY_EXIST = ResaleService.getSystemMessage('RESALE_CHARGES_ALREADY_EXIST');
    
    public static String UNIT_RESALESTATUS_PROPERTY_LISTED = 'Property Listed';
    public static String SERVICEREQUEST_IN_PROGRESS_STATUS = 'Transfer Approved';
    public static String SERVICEREQUEST_BUYER_CHEQUES_RECEIVED_STATUS = 'Buyer Cheques Received';


    public static String getStatusWithunitResaleStatus(String unitResaleStatus){
        Map<String, String> unitResaleStatusMap = 
            new Map<String, String>{
                'Property Listed' => 'Property listed',
                'Offer Accepted' => 'Offer Accepted',
                'Transfer in progress' => 'Transfer initiated',
                'Transfer Completed' => 'Transfer Completed'
            };
        return unitResaleStatusMap.containsKey(unitResaleStatus.trim()) ? unitResaleStatusMap.get(unitResaleStatus.trim()) : null;
    }
}