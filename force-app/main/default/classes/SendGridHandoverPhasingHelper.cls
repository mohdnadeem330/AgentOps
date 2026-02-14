/**********************************************************************************************************************
* Name               : SendGridHandoverPhasingHelper                                                        
* Description        : Helper Class for the Project Handover Phasing Emails via SendGrid's REST API
* Created By         : Harsh@Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     15/01/2024      Initial Draft       
******************************************************************************************************************/
public with sharing class SendGridHandoverPhasingHelper {
    public static Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> generateWrapper_HandoverPhasing(List<Id> srDocIdList, String typeString){
        SendGrid_Config__mdt config;

        if(typeString == 'tpl_ho1_1'){
            config = SendGrid_Config__mdt.getInstance('HandoverPhasingEN_ho1_1'); //Phasing Letter
        } else if(typeString == 'tpl_ho1_2'){
            config = SendGrid_Config__mdt.getInstance('HandoverPhasingEN_ho1_2'); //ACD Extension 
        } else if(typeString == 'tpl_ho1_3'){
            config = SendGrid_Config__mdt.getInstance('HandoverPhasingEN_ho1_3'); //Handover Payment Reminder 20 Days // Moved to SendGridHandoverPaymentReminderHelper
        } else if(typeString == 'tpl_ho1_4'){
            config = SendGrid_Config__mdt.getInstance('HandoverPhasingEN_ho1_4'); //Handover Payment Reminder 10 Days // Moced to SendGridHandoverPaymentReminderHelper
        }else if(typeString == 'tpl_ho4'){
            config = SendGrid_Config__mdt.getInstance('HomeOrientationSnaggingEN_ho4'); //Home Orientation (Snagging)
        }else if(typeString == 'tpl_ho2_3'){
            config = SendGrid_Config__mdt.getInstance('RFO_EN_ho4'); //RFO Letter
        }else if(typeString == 'tpl_ho2'){
            config = SendGrid_Config__mdt.getInstance('HomeOrientationNoticeEN_ho2'); //Home Orientation Notice
        }else {
            return null;
        }

        if(config == null){
            System.debug('\n\n\n NO CONFIG RECORD FOUND FOR PROJECT HANDOVER PHASING EMAIL VIA SENDGRID. CHECK SendGrid_Config__mdt for ProjectPhasingEN_'+typeString+'\n\n\n');
            return null;
        }

        //Check Kill Switch
        if(config.Pause__c){
            System.debug('\n\n\n KILL SWITCH ENABLED FOR PROJECT HANDOVER PHASING EMAIL VIA SENDGRID. CHECK SendGrid_Config__mdt for ProjectPhasingEN_'+typeString+'\n\n\n');
            return null;
        }

        return generateHandoverPhasingWrapper(srDocIdList, config);
    }

    /**
     * Take a list of Document Ids and prepare the request wrapper to be sent to sendgrid
     */
    private static Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> generateHandoverPhasingWrapper(List<Id> srDocIdList, SendGrid_Config__mdt config){
        //List of Unit Ids
        List<Id> unitIdsList = new List<Id>();

        List<HexaBPM__SR_Doc__c> validSRDocList = new List<HexaBPM__SR_Doc__c>(); 

        //init wrapper
        Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap = new Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper>();

        //get Service Request Data from server
        List<HexaBPM__SR_Doc__c> srDocRecordList = SendGridIntegrationUtilities.getSRDocData(srDocIdList);

        Set<Id> soToProcess = new Set<Id>();

        //loop over the SR records from server, filter them and store needed values
        for(HexaBPM__SR_Doc__c srDocRecord : srDocRecordList){
            HexaBPM__Service_Request__c srRecord = srDocRecord.HexaBPM__Service_Request__r;
            if(srRecord != null && 
                srRecord.SalesOrder__c != null && 
                srRecord.SalesOrder__r.Unit__c != null &&
                srRecord.SalesOrder__r.Unit__r.Project__c != null &&
                srRecord.SalesOrder__r.Unit__r.BuildingSectionName__c != null
                ){ 
                    //all the valid documents to be considered further
                    validSRDocList.add(srDocRecord);
                    soToProcess.add(srRecord.SalesOrder__c);
                    //take out all unit Ids to get the Virtual Bank Records
                    unitIdsList.add(srRecord.SalesOrder__r.Unit__c);
            }
        }
        //get all joint owner email addresses
        Map<Id, Set<String>> soToJointOwnerMap =  DefaultAndTerminationUtility.getOwnerEmailList(soToProcess);

        //get Virtual Bank Account record from server, can result null if none found for the unit
        Map<Id, Unit__c> virtualBankRecordMap = SendGridIntegrationUtilities.getVirtualBankAccountData(unitIdsList);

        //Looping over the valid documents only
        for(HexaBPM__SR_Doc__c srDocRecord : validSRDocList){
            Id srDocId = srDocRecord.Id;

            //wrapper
            SendGridWrappers.PaymentMilestoneEmailWrapper wrap = new SendGridWrappers.PaymentMilestoneEmailWrapper();
            wrap.type = config.Type__c;

            String languagePreference = null;
            // Check Contact__c object first
            if (!String.isBlank(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Contact__r.LanguagePreference__c)) {
                languagePreference = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Contact__r.LanguagePreference__c;
            }
            
            // If Contact__c's language preference is not set, check Account__c object
            if (languagePreference == null && !String.isBlank(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.LanguagePreference__pc)) {
                languagePreference = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.LanguagePreference__pc;
            }

            // Set the language based on the preference or a default value
            if (languagePreference != null) {
                wrap.language = (languagePreference == 'Arabic') ? 'ar' : 'en';
            } else {
                // Set a default language if neither Contact__c nor Account__c has a preference
                wrap.language = 'en'; // or any other default value
            }

            //LANGUAGE OVERRIDE TO BE REMOVED LATER -- 08/10/23 VIET: Templates are only available for EN as of today
            wrap.language = 'en';
            //LANGUAGE OVERRIDE TO BE REMOVED LATER -- 08/10/23 VIET: Templates are only available for EN as of today
            
            wrap.property_name = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.ProjectName__c;
            wrap.unit_number = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name;

            if(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__c != null){
                wrap.salutation = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.Salutation; 
                wrap.customer_name = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.Name;
            }else if(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Contact__c != null){
                wrap.salutation = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Contact__r.Salutation; 
                wrap.customer_name = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Contact__r.Name;
            }

            // [Harsh@Aldar 02/11] added this temp override for handling empty salutation - to be removed in future
            if(String.isBlank(wrap.salutation) || wrap.salutation == null){
                wrap.salutation = ' ';
            }

            //[Harsh 23/10] If Unit Type and Model are same, dont send combination, just one string
            if(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitType__c.toLowerCase() == srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitModel__c.toLowerCase()){
                wrap.property_type = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitType__c;
            }else{
                wrap.property_type = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitType__c +' '+ srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitModel__c;
            }

            wrap.equity = String.valueOf(SendGridIntegrationUtilities.roundToTen((Integer)srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.EquityPercentage__c));
            wrap.remaining_to_date = 'AED '+String.valueOf(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.TotalOutstanding__c.format());

            //If Virtual Account is not blank
            if(virtualBankRecordMap != null && virtualBankRecordMap.get(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__c) != null){
                Unit__c virtualBankRecord = virtualBankRecordMap.get(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__c);
                wrap.wt_beneficiary = virtualBankRecord.VirtualAccountNumber__r.VirtualAccountTitle__c;
                wrap.wt_account_number = virtualBankRecord.VirtualAccountNumber__r.VirtualAccountNumber__c;
                wrap.wt_bank_name = virtualBankRecord.VirtualAccountNumber__r.BankName__c;
                wrap.wt_branch = Label.ProformaInvoiceVABranch;
                wrap.wt_iban = virtualBankRecord.VirtualAccountNumber__r.VirtualIBANAccountNumber__c;
                wrap.wt_swift_code = virtualBankRecord.VirtualAccountNumber__r.Swift_Code__c;
            }else{
                //If Virtual Account is blank
                //Check Building's Escrow
                if(!String.isBlank(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c)){
                    wrap.wt_bank_name = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c;
                    wrap.wt_account_number = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c;
                    wrap.wt_beneficiary = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c;
                    wrap.wt_branch = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c;
                    wrap.wt_iban = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c;
                    wrap.wt_swift_code = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c;
                }
                //If Building's Escrow is blank, check Project's Escrow
                else if(!String.isBlank(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c)){
                            wrap.wt_bank_name = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c;
                            wrap.wt_account_number = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c;
                            wrap.wt_beneficiary = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c;
                            wrap.wt_branch = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BranchEscrow__c;
                            wrap.wt_iban = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c;
                            wrap.wt_swift_code = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c;
                }
                //If Project's Escrow is also blank, use the Corporate Account on Project
                else{
                    wrap.wt_bank_name = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c;
                    wrap.wt_account_number = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c;
                    wrap.wt_beneficiary = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c;
                    wrap.wt_branch = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BranchCorporate__c;
                    wrap.wt_iban = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c;
                    wrap.wt_swift_code = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c;
                }
            }

            wrap.property_image = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.Image_URL__c == null ? Label.SendGridPropertyImageURL : srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.Image_URL__c;
            
            // Changes By Gourav for add recipient_email for OrganizationAccount type on 06-Aug-2025
            //wrap.recipient_email = (srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Contact__c != null ? srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Contact__r.Email : srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.PersonEmail) + (soToJointOwnerMap.containsKey(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__c)),',') : '' );
            if(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.IsPersonAccount){
                wrap.recipient_email = (srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Contact__c != null ? srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Contact__r.Email : srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.PersonEmail) + (soToJointOwnerMap.containsKey(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__c)),',') : '' );
            }else{
                wrap.recipient_email = (srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Contact__c != null ? srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Contact__r.Email : srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__r.Email__c) + (soToJointOwnerMap.containsKey(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__c)),',') : '' );
            }
            wrap.cc = config.CC__c == null ? '' : config.CC__c;
            wrap.bcc = config.BCC__c == null ? '' : config.BCC__c;
            wrap.cheque_beneficiary = wrap.wt_beneficiary;

            //Get Last Installment Number from Handover Detail
            if(srDocRecord.HexaBPM__Service_Request__r.HandoverDetail__r?.LastInstallment__r?.InstallmentNumber__c != null){
                wrap.installment = srDocRecord.HexaBPM__Service_Request__r.HandoverDetail__r.LastInstallment__r.InstallmentNumber__c +'-'+ srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.TotalInstallmentNo__c;
            }else{
                //if for some reason Handover Detail didnt had Last Installment populated, take the Last Installment Line as fallback
                wrap.installment = SendGridIntegrationUtilities.getLastInstallmentLine_Handover(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Id).InstallmentNumber__c +'-'+ srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.TotalInstallmentNo__c;
            }  

            wrap.appointment_phone = Label.SendGridAppointmentPhone; //800-25327
            wrap.customer_care_email = Label.SendGridCustCareEmail;//'customercare@aldar.com'
            wrap.customer_care_number = Label.SendGridCustCareNumber; //'800-ALDAR / 800-23134'
            wrap.international_contact_number = Label.SendGridInternationalConNum;

            // GENERIC MAPPINGS END
            
            // wrap.invoice_download_url = SendGridContentDistributionUtils.getSRDocPublicURL(srDocRecord.HexaBPM__Service_Request__r.Id, srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitNumber__c, 'ERP SOA');
            

            //Handover Phasing Letter
            if(config.Type__c == 'tpl_ho1_1'){
                //get Handover Phase from Handover Detail - ommit the word Phase if it is in the value since api has the word Phase in markup
                wrap.phase_number = srDocRecord.HexaBPM__Service_Request__r.HandoverDetail__r?.HandoverPhaseGroup__c?.remove('Stage-');
                wrap.handover_phase_date = SendGridIntegrationUtilities.getFormattedDate(srDocRecord?.HexaBPM__Service_Request__r?.HandoverDetail__r.Expected_Handover_Date__c);
               // wrap.handover_phase_date = SendGridIntegrationUtilities.getFormattedDate(srDocRecord?.HexaBPM__Service_Request__r?.HandoverDetail__r.HandoverPhaseDate__c);
                wrap.handover_date = srDocRecord?.HexaBPM__Service_Request__r?.HandoverDetail__r.Handover_Phase_Month_Year__c;
                wrap.soa_link = SendGridContentDistributionUtils.getSRDocPublicURL(srDocRecord?.HexaBPM__Service_Request__r?.Id, srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitNumber__c, 'ERP SOA');
                wrap.KAR_email = srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Email;
                wrap.KAR_name = srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Name;
                wrap.KAR_contact = srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Phone == null ? srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.MobilePhone : srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Phone;
                if (wrap.language == 'ar') {
                    wrap.download_handover_guidelines = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.HandoverProjectGuidelinesAR__c;
                }else {
                    wrap.download_handover_guidelines = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.HandoverProjectGuidelines__c;
                }

                if(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__c != null){
                    wrap.communication_preference_link_ar = EmailCommPreferenceController.generateURL(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__c);
                    wrap.communication_preference_link_en = wrap.communication_preference_link_ar;
                    wrap.communication_preference_link_ru = wrap.communication_preference_link_ar;
                }

                //loop the KAR User on Handover as one of CC
                wrap.cc += ','+srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Email;

            }
            
            //Home orientation (Snagging)
            if(config.Type__c == 'tpl_ho4'){
                wrap.download_snag_report = SendGridContentDistributionUtils.getSRDocPublicURL(srDocRecord.HexaBPM__Service_Request__r.Id, srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitNumber__c, 'Customer Snagging');
                if(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__c != null){
                    wrap.communication_preference_link_ar = EmailCommPreferenceController.generateURL(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__c);
                    wrap.communication_preference_link_en = wrap.communication_preference_link_ar;
                    wrap.communication_preference_link_ru = wrap.communication_preference_link_ar;
                }

                wrap.handover_agent = srDocRecord.HexaBPM__Service_Request__r.HOAgent__r.Name;
                wrap.contact_details = srDocRecord.HexaBPM__Service_Request__r.HOAgent__r.Phone == null ? srDocRecord.HexaBPM__Service_Request__r.HOAgent__r.MobilePhone : srDocRecord.HexaBPM__Service_Request__r.HOAgent__r.Phone;
                wrap.KAR_email = srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Email;
                wrap.KAR_name = srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Name;
                wrap.KAR_contact = srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Phone == null ? srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.MobilePhone : srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Phone;
                wrap.cc += ','+srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Email;
                wrap.cc += ','+srDocRecord.HexaBPM__Service_Request__r.HOAgent__r.Email;
            }
            //for RFO, adding fields
            if(config.Type__c == 'tpl_ho2_3'){
                //updated the tags
                wrap.liability_period_date = SendGridIntegrationUtilities.getFormattedDate(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.CustomerDLPStartDate__c);
                wrap.maintenance_contract_date = SendGridIntegrationUtilities.getFormattedDate(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.AMCStartDate__c);
                wrap.utilities_start_date = SendGridIntegrationUtilities.getFormattedDate(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.HandoverRFOPayDueDate__c);
                wrap.de_snagged_report = SendGridContentDistributionUtils.getSRDocPublicURL(srDocRecord.HexaBPM__Service_Request__r.Id, srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitNumber__c, 'Customer Desnagging');

                wrap.due_date = SendGridIntegrationUtilities.getFormattedDate(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.HandoverRFOPayDueDate__c);
                // Added Parm rfo_date on 26-Aug-2025
                wrap.rfo_date = SendGridIntegrationUtilities.getFormattedDate(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.HandoverReadyforOccupancyDate__c);
                System.debug('rfo_date>>'+wrap.rfo_date);
                wrap.amount_outstanding = 'AED '+String.valueOf(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.TotalOutstanding__c.format());
                wrap.book_an_appointment = Label.SendGridAppointmentPhone;
                if (wrap.language == 'ar') {
                    wrap.download_handover_guidelines = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.HandoverProjectGuidelinesAR__c;
                }else {
                    wrap.download_handover_guidelines = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.HandoverProjectGuidelines__c;
                }

                if(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__c != null){
                    wrap.communication_preference_link_ar = EmailCommPreferenceController.generateURL(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__c);
                    wrap.communication_preference_link_en = wrap.communication_preference_link_ar;
                    wrap.communication_preference_link_ru = wrap.communication_preference_link_ar;
                }

                wrap.KAR_email = srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Email;
                wrap.KAR_name = srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Name;
                wrap.KAR_contact = srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Phone == null ? srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.MobilePhone : srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Phone;

                wrap.cc += ','+srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Email;
                wrap.cc += ','+srDocRecord.HexaBPM__Service_Request__r.HOAgent__r.Email;
            }

            //Handover Payment Reminder 20 Days
            if(config.Type__c == 'tpl_ho1_3'){
                wrap.amount_outstanding = 'AED '+String.valueOf(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.TotalOutstanding__c.format());
            }
            //Handover Payment Reminder 10 Days
            if(config.Type__c == 'tpl_ho1_4'){
                wrap.amount_outstanding = 'AED '+String.valueOf(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.TotalOutstanding__c.format());
            }

            //Home Orientation Letter / Notice Mappings
            if(config.Type__c == 'tpl_ho2'){
                wrap.amount_due = 'AED '+String.valueOf(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.TotalOutstanding__c.format());
                if (wrap.language == 'ar') {
                    wrap.download_handover_guidelines = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.HandoverProjectGuidelinesAR__c;
                }else {
                    wrap.download_handover_guidelines = srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.HandoverProjectGuidelines__c;
                }
                wrap.download_orientation_notice = SendGridContentDistributionUtils.getSRDocPublicURL(srDocRecord.HexaBPM__Service_Request__r.Id, srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitNumber__c, 'Home Orientation Letter');

                wrap.book_orientation_appointment = Label.SendGridHomeOrientation;
                wrap.aldar_conduct_home_orientation = Label.SendGridAppointmentPhone;

                if(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__c != null){
                    wrap.communication_preference_link_ar = EmailCommPreferenceController.generateURL(srDocRecord.HexaBPM__Service_Request__r.SalesOrder__r.Account__c);
                    wrap.communication_preference_link_en = wrap.communication_preference_link_ar;
                    wrap.communication_preference_link_ru = wrap.communication_preference_link_ar;
                }

                wrap.KAR_email = srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Email;
                wrap.KAR_name = srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Name;
                wrap.KAR_contact = srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Phone == null ? srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.MobilePhone : srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Phone;
                //loop the KAR User on Handover as one of CC
                wrap.cc += ','+srDocRecord.HexaBPM__Service_Request__r.HOKAR__r.Email;

            }

            List<String> deDupeEmailsList = SendGridIntegrationUtilities.removeDuplicatesAcrossStrings(wrap.recipient_email, wrap.cc, wrap.bcc);
            wrap.recipient_email = deDupeEmailsList[0];
            wrap.cc = deDupeEmailsList[1];
            wrap.bcc = deDupeEmailsList[2];

            requestWrapperMap.put(srDocId, wrap);

        }
        return requestWrapperMap;                  
    }
}