/**********************************************************************************************************************
* Name               : SendGridIntegrationHelper                                                        
* Description        : Helper Class for the Payment Reminder Emails via SendGrid's REST API
* Created By         : Harsh@Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     15/09/2023      Initial Draft       
******************************************************************************************************************/
public with sharing class SendGridIntegrationHelper {

    public static Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> generateWrapper_PaymentReminder_1(List<Id> documentIdList){
        SendGrid_Config__mdt config = SendGrid_Config__mdt.getInstance('AldarEDMPaymentMilestonesMasterEN_1');
        if(config == null){
            System.debug('\n\n\n NO CONFIG RECORD FOUND FOR PAYMENT REMINDER MILESTONE EMAIL VIA SENDGRID. CHECK SendGrid_Config__mdt for AldarEDMPaymentMilestonesMasterEN_1 \n\n\n');
            return null;
        }

        //Check Kill Switch
        if(config.Pause__c){
            System.debug('\n\n\n KILL SWITCH ENABLED FOR THIS PAYMENT REMINDER MILESTONE EMAIL VIA SENDGRID. CHECK SendGrid_Config__mdt for AldarEDMPaymentMilestonesMasterEN_1 \n\n\n');
            return null;
        }

        return generatePaymentReminderWrapper(documentIdList, config);
    }

    public static Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> generateWrapper_PaymentReminder_2(List<Id> documentIdList){
        SendGrid_Config__mdt config = SendGrid_Config__mdt.getInstance('AldarEDMPaymentMilestonesMasterEN_2');
        if(config == null){
            System.debug('\n\n\n NO CONFIG RECORD FOUND FOR PAYMENT REMINDER MILESTONE EMAIL VIA SENDGRID. CHECK SendGrid_Config__mdt for AldarEDMPaymentMilestonesMasterEN_2 \n\n\n');
            return null;
        }

        //Check Kill Switch
        if(config.Pause__c){
            System.debug('\n\n\n KILL SWITCH ENABLED FOR THIS PAYMENT REMINDER MILESTONE EMAIL VIA SENDGRID. CHECK SendGrid_Config__mdt for AldarEDMPaymentMilestonesMasterEN_2 \n\n\n');
            return null;
        }

        return generatePaymentReminderWrapper(documentIdList, config);
    }

    public static Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> generateWrapper_PaymentReminder_3(List<Id> documentIdList){
        SendGrid_Config__mdt config = SendGrid_Config__mdt.getInstance('AldarEDMPaymentMilestonesMasterEN_4');
        if(config == null){
            System.debug('\n\n\n NO CONFIG RECORD FOUND FOR PAYMENT REMINDER MILESTONE EMAIL VIA SENDGRID. CHECK SendGrid_Config__mdt for AldarEDMPaymentMilestonesMasterEN_4 \n\n\n');
            return null;
        }

        //Check Kill Switch
        if(config.Pause__c){
            System.debug('\n\n\n KILL SWITCH ENABLED FOR THIS PAYMENT REMINDER MILESTONE EMAIL VIA SENDGRID. CHECK SendGrid_Config__mdt for AldarEDMPaymentMilestonesMasterEN_4 \n\n\n');
            return null;
        }

        return generatePaymentReminderWrapper(documentIdList, config);
    }

    /**
     * Take a list of Document Ids and prepare the request wrapper to be sent to sendgrid
     */
    private static Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> generatePaymentReminderWrapper(List<Id> documentIdList, SendGrid_Config__mdt config){
        //List of Unit Ids
        List<Id> unitIdsList = new List<Id>();

        //Dont Send Reminders for the following Projects
        String bypassProjectIds = Label.SendGridPayReminderBypass;
        List<String> bypassProjectIdList = new List<String>();
        if (bypassProjectIds != 'none' && !String.isBlank(bypassProjectIds)) {
            // Split the comma-separated string into a list
            bypassProjectIdList = bypassProjectIds.split(',');
        
            // Trim any leading or trailing whitespaces from each element in the list
            for (Integer i = 0; i < bypassProjectIdList.size(); i++) {
                bypassProjectIdList[i] = bypassProjectIdList[i].trim();
            }
        }

        Map<Id, InstallmentLines__c> docIdInstallmentLineRecordMap = new Map<Id, InstallmentLines__c>();
        Map<Id, Id> docIdSalesOrderIdsMap = new Map<Id, Id>();

        List<Document__c> validDocumentsList = new List<Document__c>(); 

        //init wrapper
        Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper> requestWrapperMap = new Map<Id, SendGridWrappers.PaymentMilestoneEmailWrapper>();
        //get Documents Data from server
        List<Document__c> documentRecordList = SendGridIntegrationUtilities.getDocumentData(documentIdList);
        //loop over the documents records from server, filter them and store key values
        for(Document__c documentRecord : documentRecordList){
            if(documentRecord != null && 
                documentRecord.InstallmentLine__c != null && 
                documentRecord.InstallmentLine__r.SalesOrder__c != null && 
                documentRecord.InstallmentLine__r.SalesOrder__r.Unit__c != null &&
                documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__c != null &&
                documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__c != null &&
                !bypassProjectIdList.contains(documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__c)
                ){ 
                    //all the valid documents to be considered further
                    validDocumentsList.add(documentRecord);

                    //take out all unit Ids to get the Virtual Bank Records
                    unitIdsList.add(documentRecord.InstallmentLine__r.SalesOrder__r.Unit__c);

                    //store all the InstallmentLine records with document Id to fetch the Proforma Invoice PDF and get a public URL
                    docIdInstallmentLineRecordMap.put(documentRecord.Id, documentRecord.InstallmentLine__r);
            }
        }
        

        //get Virtual Bank Account record from server, can result null if none found for the unit
        Map<Id, Unit__c> virtualBankRecordMap = SendGridIntegrationUtilities.getVirtualBankAccountData(unitIdsList);

        //attach proforma invoice pdf to document and get a public distribution URL
        Map<Id, String> proformaURLMap = attachProformaPDF(docIdInstallmentLineRecordMap);

        //Looping over the valid documents only
        for(Document__c documentRecord : validDocumentsList){
            Id documentId = documentRecord.Id;

            //wrapper
            SendGridWrappers.PaymentMilestoneEmailWrapper wrap = new SendGridWrappers.PaymentMilestoneEmailWrapper();
            wrap.type = config.Type__c;

            String languagePreference = null;
            // Check Contact__c object first
            if (!String.isBlank(documentRecord.InstallmentLine__r.SalesOrder__r.Contact__r.LanguagePreference__c)) {
                languagePreference = documentRecord.InstallmentLine__r.SalesOrder__r.Contact__r.LanguagePreference__c;
            }
            
            // If Contact__c's language preference is not set, check Account__c object
            if (languagePreference == null && !String.isBlank(documentRecord.InstallmentLine__r.SalesOrder__r.Account__r.LanguagePreference__pc)) {
                languagePreference = documentRecord.InstallmentLine__r.SalesOrder__r.Account__r.LanguagePreference__pc;
            }

            // Set the language based on the preference or a default value
            if (languagePreference != null) {
                wrap.language = (languagePreference == 'Arabic') ? 'ar' : 'en';
            } else {
                // Set a default language if neither Contact__c nor Account__c has a preference
                wrap.language = 'en'; // or any other default value
            }

            //LANGUAGE OVERRIDE TO BE REMOVED LATER -- [HARSH] 08/10/23 VIET: Templates are only available for EN as of today
            wrap.language = 'en';
            //LANGUAGE OVERRIDE TO BE REMOVED LATER -- [HARSH] 08/10/23 VIET: Templates are only available for EN as of today
            
            wrap.reference_url = 'https://aldar.com';

            wrap.property_name = documentRecord.InstallmentLine__r.SalesOrder__r.ProjectName__c;
            wrap.unit_number = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Name;

            if(documentRecord.InstallmentLine__r.SalesOrder__r.Account__c != null){
                wrap.salutation = documentRecord.InstallmentLine__r.SalesOrder__r.Account__r.Salutation; 
                wrap.customer_name = documentRecord.InstallmentLine__r.SalesOrder__r.Account__r.Name;
            }
            else if(documentRecord.InstallmentLine__r.SalesOrder__r.Contact__c != null){
                wrap.salutation = documentRecord.InstallmentLine__r.SalesOrder__r.Contact__r.Salutation; 
                wrap.customer_name = documentRecord.InstallmentLine__r.SalesOrder__r.Contact__r.Name;

            } 

            // [Harsh@Aldar 02/11] added this temp override for handling empty salutation - to be removed in future
            if(String.isBlank(wrap.salutation) || wrap.salutation == null){
                wrap.salutation = ' ';
            }
            //[Harsh 23/10] If Unit Type and Model are same, dont send combination, just one string
            if(documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.UnitType__c.toLowerCase() == documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.UnitModel__c.toLowerCase()){
                wrap.property_type = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.UnitType__c;
            }else{
                wrap.property_type = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.UnitType__c +' '+ documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.UnitModel__c;
            }
            String formattedDate = SendGridIntegrationUtilities.getFormattedDate(documentRecord.InstallmentLine__r.InstallmentDate__c);
            wrap.due_date = formattedDate;
            wrap.installment = documentRecord.InstallmentLine__r.InstallmentNumber__c +'-'+ documentRecord.InstallmentLine__r.SalesOrder__r.TotalInstallmentNo__c; 
            //[Harsh@Aldar 17/11] Equity gets rounded off to closest 10
            wrap.equity = String.valueOf(roundToTen((Integer)documentRecord.InstallmentLine__r.SalesOrder__r.EquityPercentage__c));
            wrap.construction_progress_url = wrap.language == 'ar' ? documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.ProjectProgressAr__c : documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.ProjectProgressEn__c;
            wrap.amount_due = 'AED '+String.valueOf(documentRecord.InstallmentLine__r.OutstandingAmount__c.format());
            wrap.remaining_to_date = 'AED '+String.valueOf(documentRecord.InstallmentLine__r.SalesOrder__r.TotalOutstanding__c.format());

            //#### TBD
            wrap.complete_payment_url = 'https://www.aldar.com';

            //If Virtual Account is not blank
            if(virtualBankRecordMap != null && virtualBankRecordMap.get(documentRecord.InstallmentLine__r.SalesOrder__r.Unit__c) != null){
                Unit__c virtualBankRecord = virtualBankRecordMap.get(documentRecord.InstallmentLine__r.SalesOrder__r.Unit__c);
                wrap.wt_beneficiary = virtualBankRecord.VirtualAccountNumber__r.VirtualAccountTitle__c;
                wrap.wt_account_number = virtualBankRecord.VirtualAccountNumber__r.VirtualAccountNumber__c;
                wrap.wt_bank_name = virtualBankRecord.VirtualAccountNumber__r.BankName__c;
                wrap.wt_branch = Label.ProformaInvoiceVABranch;
                wrap.wt_iban = virtualBankRecord.VirtualAccountNumber__r.VirtualIBANAccountNumber__c;
                wrap.wt_swift_code = virtualBankRecord.VirtualAccountNumber__r.Swift_Code__c;

            }else{
                //If Virtual Account is blank
                //Check Building's Escrow
                if(!String.isBlank(documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c)){
                    wrap.wt_bank_name = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c;
                    wrap.wt_account_number = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c;
                    wrap.wt_beneficiary = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c;
                    wrap.wt_branch = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c;
                    wrap.wt_iban = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c;
                    wrap.wt_swift_code = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c;
                }

                //If Building's Escrow is blank, check Project's Escrow
                else if(!String.isBlank(documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c)){
                            wrap.wt_bank_name = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c;
                            wrap.wt_account_number = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c;
                            wrap.wt_beneficiary = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c;
                            wrap.wt_branch = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BranchEscrow__c;
                            wrap.wt_iban = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c;
                            wrap.wt_swift_code = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c;
                }
                //If Project's Escrow is also blank, use the Corporate Account on Project

                else{
                    wrap.wt_bank_name = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c;
                    wrap.wt_account_number = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c;
                    wrap.wt_beneficiary = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c;
                    wrap.wt_branch = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BranchCorporate__c;
                    wrap.wt_iban = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c;
                    wrap.wt_swift_code = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c;
                }
            }

            wrap.cheque_beneficiary = wrap.wt_beneficiary;
            //ICS file to be generated in SendGrid, will not be sent from SF
            wrap.reminder_url = 'http://calendar.ics';

            //[Harsh 23/10]
            //sale order contact lookup - if null - then account
            if(documentRecord.InstallmentLine__r.SalesOrder__r.Contact__c != null && documentRecord.InstallmentLine__r.SalesOrder__r.Contact__r.ResidentStatus__c != null){
                wrap.is_international = documentRecord.InstallmentLine__r.SalesOrder__r.Contact__r.ResidentStatus__c == 'Resident' ? false : true ;
            }
            else if(documentRecord.InstallmentLine__r.SalesOrder__r.Account__c != null){
                wrap.is_international = documentRecord.InstallmentLine__r.SalesOrder__r.Account__r.ResidentStatus__pc == 'Resident' ? false : true ;
            }

            //proforma invoice public url from the document using content distribution 
            wrap.invoice_download_url = proformaURLMap.size() > 0 && proformaURLMap.get(documentId) != null ? proformaURLMap.get(documentId) : null;
            //SOA public url from the document using content distribution
            //[HARSH 23/10] STOP SOA, send blank
            // wrap.statement_download_url = statementOfAccountURLMap.size() > 0 && statementOfAccountURLMap.get(documentId) != null ? statementOfAccountURLMap.get(documentId) : null;
            wrap.statement_download_url = null;

            wrap.property_image = documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.Image_URL__c == null ? Label.SendGridPropertyImageURL : documentRecord.InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.Image_URL__c;
            wrap.whatsapp_url = Label.SendGridWhatsappURL;
            wrap.recipient_email = documentRecord.RecipientEmail__c;

            //[Harsh 25/10] Communication Preference
            //currently only one english URL is passed to all 3 Russian, Arabic and English interfaces.
            //Since this is a protected link, all 3 links would have to be distributed separately to avoid access token overlap
            if(documentRecord.InstallmentLine__r.SalesOrder__r.Account__c != null){
                wrap.communication_preferences_url_ar = EmailCommPreferenceController.generateURL(documentRecord.InstallmentLine__r.SalesOrder__r.Account__c);
                wrap.communication_preferences_url_en = wrap.communication_preferences_url_ar;
                wrap.communication_preferences_url_ru = wrap.communication_preferences_url_ar;
            }

            wrap.cc = config.CC__c == null ? null : config.CC__c;
            wrap.bcc = config.BCC__c == null ? null : config.BCC__c; 

            requestWrapperMap.put(documentId, wrap);
        }

        return requestWrapperMap;                    
    }

    /**
     * Create, Attach and Distribute the Proforma Invoice PDF
     */
    private static Map<Id, String> attachProformaPDF(Map<Id, InstallmentLines__c> docIdInstallmentLineRecordMap){

        Map<Id, String> returnMap = new Map<Id, String>();

        for(Id documentId : docIdInstallmentLineRecordMap.keySet()){
            InstallmentLines__c installmentLineRecord = docIdInstallmentLineRecordMap.get(documentId);
            PageReference proformaInvoicePDFPage = Page.ProformaInvoicePDFPage;

            // Bind the controller instance to the Visualforce page
            proformaInvoicePDFPage.getParameters().put('id', installmentLineRecord.Id);
            proformaInvoicePDFPage.setRedirect(true);
            proformaInvoicePDFPage.getHeaders().put('Content-Type', 'application/pdf');

            // Generate PDF
            Blob pdfBlob;

            if(Test.isRunningTest()) { 
                pdfBlob = blob.valueOf('Unit.Test');
            } else {
                pdfBlob = proformaInvoicePDFPage.getContent();
            }

            //Attach and Get Distribution URL
            String publicURL = SendGridContentDistributionUtils.getPublicDistributionURLForPDF(pdfBlob, 'Proforma Invoice', 'Proforma_Invoice.pdf', 'S', 'I', documentId);
            returnMap.put(documentId, publicURL);
        }

        return returnMap;
    }

    /*
    * Rounds the input value to the nearest multiple of 10 with dynamic handling for values from 1 to 100.
    * If the input value is outside the valid range (1 to 100), the original value is returned.
    * The rounding is performed by calculating the remainder when dividing by 10.
    * If the remainder is 5 or greater, 10 is added to round up to the nearest multiple of 10.
    */
    private static Integer roundToTen(Integer arg) {
        if (arg < 1 || arg > 100) {
            return arg; // Return the original value if it's outside the valid range
        }
        Integer remainder = Math.mod(arg, 10);
        Integer roundedValue = arg - remainder;
    
        if (remainder >= 5) {
            roundedValue += 10;
        }
    
        return roundedValue;
    }
   
}