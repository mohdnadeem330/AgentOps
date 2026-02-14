/**********************************************************************************************************************
* Name               : SendGridWrappers                                                        
* Description        : Wrappers to support the Payment Reminder Emails via SendGrid's REST API
* Created By         : Harsh@Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     15/09/2023      Initial Draft       
******************************************************************************************************************/
public with sharing class SendGridWrappers {

    public class PaymentMilestoneEmailWrapper{

        public String type;
        public String language;
        public String subject;
        public String reference_url;
        public String property_name;
        public String unit_number;
        public String salutation;
        public String customer_name;
        public String property_type;
        public String due_date;
        //Added rfo_date on 26/08/25 by gourav bhardwaj
        public String rfo_date;
        public String installment;
        public String equity;
        public String construction_progress_url;
        public String amount_due;
        public String remaining_to_date;
        public String complete_payment_url;
        public String wt_beneficiary;
        public String wt_account_number;
        public String wt_bank_name;
        public String wt_branch;
        public String wt_iban;
        public String wt_swift_code;
        public String cheque_beneficiary;
        public String reminder_url;
        public Boolean is_international;
        public String invoice_download_url;
        public String statement_download_url;
        public String contact_avatar;
        public String contact_name;
        public String contact_role;
        public String contact_email;
        public String contact_number;
        public String customer_care_email;
        public String customer_care_number;
        public String property_image;
        public String whatsapp_url;
        public String recipient_email;

        public String case_number;
        public String cc;
        public String bcc;
        public String support_email;

        //Payment Milestones LPC Waiver EN
        //Added 04/10/23 Harsh@Aldar
        public String uae_contact_number;
	    public String international_contact_number;
        public String mail_url;
        public String communication_preferences_url_en;
        public String communication_preferences_url_ru;
        public String communication_preferences_url_ar;
        public String live_aldar_url;

        public String property_unit;

        public String response_day;
        public String replied_day;
        public String milestone_amount_due_date;
        public String new_due_date;
        public String reason;

        //Harsh@Aldar 05/01/2024 Handover Email Wrappers Start
        public String STORAGE_CUSTOM_DOMAIN_NAME;
        //Harsh@Aldar 05/01/2024 Handover Email Wrappers End

        //Harsh@Aldar 15/01/2024 Handover Email Wrappers Start
        public String handover_progress;
        //Harsh@Aldar 15/01/2024 Handover Email Wrappers End

        //Harsh@Aldar 23/01/2023 Snagging Wrappers
        public String appointment_phone;
        public String download_snag_report;

        //Harsh@Aldar 23/01/2023 RFO Wrappers
        public String liability_period_date;
        public String maintenance_contract_date;
        public String utilities_start_date;

        public String amount_outstanding;

        public String download_handover_guidelines;

        public String phase_number;
        public String handover_date;
        public String handover_phase_date;

        public String account_representative;

        public String de_snagged_report;
        public String soa_link;
        
        public String communication_preference_link_en;
        public String communication_preference_link_ru;
        public String communication_preference_link_ar;

        public String book_an_appointment;
        public String download_orientation_notice;
        public String book_orientation_appointment;
        public String aldar_conduct_home_orientation;

        public String handover_agent;
        public String contact_details;
        public String KAR_contact_details;

        public String KAR_email;
        public String KAR_contact;
        public String KAR_name;

        //for fasttrack email harsh@aldar 05/03/2024
        public String register_link;

    }

    //SendGrid Error Wrapper Start
    public class ErrorWrapper {
        public Error error;
    }

    public class Details {
        public Boolean success;
        public List<List<String>> message;
    }

    public class Error {
        public Integer statusCode;
        public String message;
        public String errorName;
        public Details details;
        public String path;
        public String requestId;
        public String timestamp;
    }
    //SendGrid Error Wrapper End

    //[Harsh 03/11] New Response Structure
    public class SuccessResponse{
        public Boolean status;
        public String message;
        public Data data;
    }

    public class Versions {
        public String id;
        public Integer user_id;
        public String template_id;
        public Integer active;
        public String name;
        public String html_content;
        public String plain_content;
        public Boolean generate_plain_content;
        public String subject;
        public String updated_at;
        public String editor;
        public String thumbnail_url;
    }

    public class Data {
        public String id;
        public String name;
        public String generation;
        public String updated_at;
        public List<Versions> versions;
    }

    public class LPCFlowInputParamsWrapper{
        @InvocableVariable(label='Service Request Id' required=true description='Service Request Id')
        public String recordIdSR;
        
        @InvocableVariable(label='Process Name' required=true description='Submitted / Approved / Rejected')
        public String processName;
    }
}