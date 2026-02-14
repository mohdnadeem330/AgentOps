/**********************************************************************************************************************
* Name               : SendGridIntegrationUtilities                                                        
* Description        : Utilities Class for the Payment Reminder Emails via SendGrid's REST API
* Created By         : Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     15/09/2023      Initial Draft       
******************************************************************************************************************/
public with sharing class SendGridIntegrationUtilities {

    //Name of the API Setting custom metadata record as Constant
    public static final String SENDGRID_PAYMENT_REMINDER = 'SendGridPaymentReminder';

    public static Boolean checkMainKillSwitch(){
        //CHECK MAIN KILL SWITCH
        SendGrid_Config__mdt config = SendGrid_Config__mdt.getInstance('AA_MAIN_KILL_SWITCH');
        if(config != null && config.Pause__c){
            System.debug('\n\n\n MAIN KILL SWITCH FOUND ENABLED FOR PAYMENT REMINDER MILESTONE EMAIL VIA SENDGRID. CHECK SendGrid_Config__mdt for AA_MAIN_KILL_SWITCH \n\n\n');
            return true;
        }
        return false;
    }

    //[Harsh@Aldar 06/11 ] 
    public static List<HexaBPM__Service_Request__c> getSRData(List<String> srIdList){
        List<HexaBPM__Service_Request__c> srList = [SELECT Id, 
                                                        SalesOrder__c,
                                                        SalesOrder__r.Id, 
                                                        SalesOrder__r.Project_Id__c,
                                                        SalesOrder__r.OutstandingAmount__c,
                                                        SalesOrder__r.UnitBuilding__c,
                                                        SalesOrder__r.Unit__c, 
                                                        SalesOrder__r.TotalInstallmentNo__c, 
                                                        SalesOrder__r.EquityPercentage__c, 
                                                        SalesOrder__r.TotalOutstanding__c, 
                                                        SalesOrder__r.Contact__c,
                                                        SalesOrder__r.Contact__r.LanguagePreference__c, 
                                                        SalesOrder__r.Account__r.LanguagePreference__pc, 
                                                        SalesOrder__r.ProjectName__c,
                                                        SalesOrder__r.Unit__r.Name,
                                                        SalesOrder__r.Contact__r.Salutation, 
                                                        SalesOrder__r.Contact__r.Email, 
                                                        SalesOrder__r.Account__r.Salutation,
                                                        SalesOrder__r.Contact__r.Name, 
                                                        SalesOrder__r.Account__r.Name,
                                                        SalesOrder__r.Account__r.IsPersonAccount,
                                                        SalesOrder__r.Account__r.ResidentStatus__pc,
                                                        SalesOrder__r.Contact__r.ResidentStatus__c,
                                                        SalesOrder__r.Unit__r.UnitType__c,
                                                        SalesOrder__r.Unit__r.UnitModel__c,
                                                        SalesOrder__r.Unit__r.Project__c,
                                                        SalesOrder__r.Unit__r.Project__r.ProjectProgressAr__c,
                                                        SalesOrder__r.Unit__r.Project__r.ProjectProgressEn__c,
                                                        SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c,
                                                        SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c,
                                                        SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c,
                                                        SalesOrder__r.Unit__r.Project__r.BranchCorporate__c,
                                                        SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c,
                                                        SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c,
                                                        SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c,
                                                        SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c,
                                                        SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c,
                                                        SalesOrder__r.Unit__r.Project__r.BranchEscrow__c,
                                                        SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c,
                                                        SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameCorporate__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__r.BranchCorporate__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoCorporate__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c,
                                                        SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c

                                                    FROM HexaBPM__Service_Request__c 
                                                    WHERE SalesOrder__c != null 
                                                    AND Id IN: srIdList
        ];

        // Create a Set to store Account Ids for which we need to query Contacts
        Map<Id, Id> accountId_salesOrderIdMap = new Map<Id, Id>();
        Map<Id, Contact> salesOrderId_ContactMap = new Map<Id, Contact>();

        for (HexaBPM__Service_Request__c thisSR : srList) {
            if (thisSR.SalesOrder__c != null) {
                //Store all Non Person Accounts
                if (!thisSR.SalesOrder__r.Account__r.IsPersonAccount) {
                    accountId_salesOrderIdMap.put(thisSR.SalesOrder__r.Account__c , thisSR.SalesOrder__c);
                }
            }
        }

        // Query Contacts for non-Person Accounts
        if (!accountId_salesOrderIdMap.isEmpty()) {
            List<Account> accList = [SELECT Id, (SELECT Id, Name, Salutation, Email, LanguagePreference__c FROM Contacts) FROM Account WHERE Id IN: accountId_salesOrderIdMap.keySet()];
            for(Account thisAcc : accList){
                if(thisAcc.Contacts != null && thisAcc.Contacts.size() > 0){
                    Contact relatedContact = thisAcc.Contacts[0];
                    if(accountId_salesOrderIdMap != null && accountId_salesOrderIdMap.get(thisAcc.Id) != null){
                        salesOrderId_ContactMap.put(accountId_salesOrderIdMap.get(thisAcc.Id), relatedContact);
                    } 
                }                               
            }
        }

        //loop again on the dataset and make sure if any sales order has non person account then the contact on it is populated
        for (HexaBPM__Service_Request__c thisSR : srList) {
            if (thisSR.SalesOrder__c != null) {
                if (!thisSR.SalesOrder__r.Account__r.IsPersonAccount) {
                    //if Contact field on Sales Order is not populated for a non person account, then add the value to use in the code later
                    if(thisSR.SalesOrder__r.Contact__r == null){
                        //check if contact record was found for this, attach
                        if(salesOrderId_ContactMap != null && salesOrderId_ContactMap.get(thisSR.SalesOrder__c) != null){
                            thisSR.SalesOrder__r.Contact__r = salesOrderId_ContactMap.get(thisSR.SalesOrder__c);
                            thisSR.SalesOrder__r.Contact__c = salesOrderId_ContactMap.get(thisSR.SalesOrder__c).Id;
                        }
                    }
                }
            }
        }
        return srList;
    }

    /**
     * Used to get the details using SR, used in HandoverEmails
     */
    public static List<HexaBPM__SR_Doc__c> getSRDocData(List<String> srDocIdList){
        List<HexaBPM__SR_Doc__c> srDocList = [SELECT Id, 
                                                HexaBPM__Service_Request__c,
                                                HexaBPM__Service_Request__r.Id,
                                                HexaBPM__Service_Request__r.WaivedAmount__c,
                                                HexaBPM__Service_Request__r.SalesOrder__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Id, 
                                                HexaBPM__Service_Request__r.SalesOrder__r.CustomerDLPStartDate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.AMCStartDate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.HandoverRFOPayDueDate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Project_Id__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.OutstandingAmount__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.UnitBuilding__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__c, 
                                                HexaBPM__Service_Request__r.SalesOrder__r.TotalInstallmentNo__c, 
                                                HexaBPM__Service_Request__r.SalesOrder__r.EquityPercentage__c, 
                                                HexaBPM__Service_Request__r.SalesOrder__r.TotalOutstanding__c, 
                                                HexaBPM__Service_Request__r.SalesOrder__r.Contact__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Contact__r.LanguagePreference__c, 
                                                HexaBPM__Service_Request__r.SalesOrder__r.Account__r.LanguagePreference__pc, 
                                                HexaBPM__Service_Request__r.SalesOrder__r.ProjectName__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitNumber__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Contact__r.Salutation, 
                                                HexaBPM__Service_Request__r.SalesOrder__r.Contact__r.Email, 
                                                HexaBPM__Service_Request__r.SalesOrder__r.Account__r.Salutation,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Contact__r.Name, 
                                                HexaBPM__Service_Request__r.SalesOrder__r.Account__r.Name,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Account__r.PersonEmail,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Account__r.IsPersonAccount,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Account__r.ResidentStatus__pc,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Contact__r.ResidentStatus__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitType__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.UnitModel__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.ProjectProgressAr__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.ProjectProgressEn__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BranchCorporate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.BranchEscrow__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.HandoverProjectGuidelines__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.HandoverProjectGuidelinesAR__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Project__r.Image_URL__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameCorporate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchCorporate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoCorporate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c,
                                                HexaBPM__Service_Request__r.SalesOrder__r.HandoverReadyforOccupancyDate__c,
                                                HexaBPM__Service_Request__r.HandoverDetail__c,
                                                HexaBPM__Service_Request__r.HandoverDetail__r.HandoverPhaseGroup__c,
                                                HexaBPM__Service_Request__r.HandoverDetail__r.Expected_Handover_Date__c,
                                                HexaBPM__Service_Request__r.HandoverDetail__r.HandoverPhaseDate__c,
                                                HexaBPM__Service_Request__r.HandoverDetail__r.Handover_Phase_Month_Year__c,
                                                HexaBPM__Service_Request__r.HandoverDetail__r.LastInstallment__c,
                                                HexaBPM__Service_Request__r.HandoverDetail__r.LastInstallment__r.InstallmentNumber__c,
                                                HexaBPM__Service_Request__r.HOKAR__r.Name,
                                                HexaBPM__Service_Request__r.HOKAR__r.MobilePhone,
                                                HexaBPM__Service_Request__r.HOKAR__r.Phone,
                                                HexaBPM__Service_Request__r.HOKAR__r.Email,
                                                HexaBPM__Service_Request__r.HOAgent__c,
                                                HexaBPM__Service_Request__r.HOAgent__r.Name,
                                                HexaBPM__Service_Request__r.HOAgent__r.MobilePhone,
                                                HexaBPM__Service_Request__r.HOAgent__r.Phone,
                                                HexaBPM__Service_Request__r.HOAgent__r.Email
                                            FROM HexaBPM__SR_Doc__c 
                                            WHERE HexaBPM__Service_Request__r.SalesOrder__c != null 
                                            AND Id IN: srDocIdList
                                            ];

        // Create a Set to store Account Ids for which we need to query Contacts
        Map<Id, Id> accountId_salesOrderIdMap = new Map<Id, Id>();
        Map<Id, Contact> salesOrderId_ContactMap = new Map<Id, Contact>();

        for(HexaBPM__SR_Doc__c thisSRDoc : srDocList){
            HexaBPM__Service_Request__c thisSR = thisSRDoc.HexaBPM__Service_Request__r;
            if (thisSR.SalesOrder__c != null) {
                //Store all Non Person Accounts
                if (!thisSR.SalesOrder__r.Account__r.IsPersonAccount) {
                    accountId_salesOrderIdMap.put(thisSR.SalesOrder__r.Account__c , thisSR.SalesOrder__c);
                }

                //Store all Non Person Accounts
                if (!thisSR.SalesOrder__r.Account__r.IsPersonAccount) {
                    accountId_salesOrderIdMap.put(thisSR.SalesOrder__r.Account__c , thisSR.SalesOrder__c);
                }
            }
        }

        // for (HexaBPM__Service_Request__c thisSR : srList) {
        //     if (thisSR.SalesOrder__c != null) {
        //         //Store all Non Person Accounts
        //         if (!thisSR.SalesOrder__r.Account__r.IsPersonAccount) {
        //             accountId_salesOrderIdMap.put(thisSR.SalesOrder__r.Account__c , thisSR.SalesOrder__c);
        //         }
        //     }
        // }

        // Query Contacts for non-Person Accounts
        if (!accountId_salesOrderIdMap.isEmpty()) {
            List<Account> accList = [SELECT Id, (SELECT Id, Name, Salutation, Email, LanguagePreference__c FROM Contacts) FROM Account WHERE Id IN: accountId_salesOrderIdMap.keySet()];
            for(Account thisAcc : accList){
                if(thisAcc.Contacts != null && thisAcc.Contacts.size() > 0){
                    Contact relatedContact = thisAcc.Contacts[0];
                    if(accountId_salesOrderIdMap != null && accountId_salesOrderIdMap.get(thisAcc.Id) != null){
                        salesOrderId_ContactMap.put(accountId_salesOrderIdMap.get(thisAcc.Id), relatedContact);
                    } 
                }                               
            }
        }

        for(HexaBPM__SR_Doc__c thisSRDoc : srDocList){
            //loop again on the dataset and make sure if any sales order has non person account then the contact on it is populated
            HexaBPM__Service_Request__c thisSR = thisSRDoc.HexaBPM__Service_Request__r;
            if (thisSR.SalesOrder__c != null) {
                if (!thisSR.SalesOrder__r.Account__r.IsPersonAccount) {
                    //if Contact field on Sales Order is not populated for a non person account, then add the value to use in the code later
                    if(thisSR.SalesOrder__r.Contact__r == null){
                        //check if contact record was found for this, attach
                        if(salesOrderId_ContactMap != null && salesOrderId_ContactMap.get(thisSR.SalesOrder__c) != null){
                            thisSR.SalesOrder__r.Contact__r = salesOrderId_ContactMap.get(thisSR.SalesOrder__c);
                            thisSR.SalesOrder__r.Contact__c = salesOrderId_ContactMap.get(thisSR.SalesOrder__c).Id;
                        }
                    }
                }
            }
        }
        
        return srDocList;
    }

    /**
     * Get List complete data from the related records through passed Document Id List
     * For a Business Account, if Contact field on Account is not populated, it queries the related Contact records and use its values
     */
    public Static List<Document__c> getDocumentData(List<Id> documentIdList){
        List<Document__c> documentList = [SELECT Id, InstallmentLine__c, RecipientEmail__c,
                                            InstallmentLine__r.InstallmentDate__c,
                                            InstallmentLine__r.InstallmentNumber__c,
                                            InstallmentLine__r.OutstandingAmount__c,
                                            InstallmentLine__r.OriginalInstallmentDate__c,
                                            InstallmentLine__r.Paymentinstallments__r.Comments_for_Customer__c,
                                            InstallmentLine__r.SalesOrder__c,
                                            InstallmentLine__r.SalesOrder__r.Id, 
                                            InstallmentLine__r.SalesOrder__r.Project_Id__c,
                                            InstallmentLine__r.SalesOrder__r.OutstandingAmount__c,
                                            InstallmentLine__r.SalesOrder__r.UnitBuilding__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__c, 
                                            InstallmentLine__r.SalesOrder__r.TotalInstallmentNo__c, 
                                            InstallmentLine__r.SalesOrder__r.EquityPercentage__c, 
                                            InstallmentLine__r.SalesOrder__r.TotalOutstanding__c, 
                                            InstallmentLine__r.SalesOrder__r.Contact__c,
                                            InstallmentLine__r.SalesOrder__r.Contact__r.LanguagePreference__c, 
                                            InstallmentLine__r.SalesOrder__r.Account__r.LanguagePreference__pc, 
                                            InstallmentLine__r.SalesOrder__r.ProjectName__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Name,
                                            InstallmentLine__r.SalesOrder__r.Contact__r.Salutation, 
                                            InstallmentLine__r.SalesOrder__r.Account__r.Salutation,
                                            InstallmentLine__r.SalesOrder__r.Contact__r.Name, 
                                            InstallmentLine__r.SalesOrder__r.Account__r.Name,
                                            InstallmentLine__r.SalesOrder__r.Account__r.IsPersonAccount,
                                            InstallmentLine__r.SalesOrder__r.Account__r.ResidentStatus__pc,
                                            InstallmentLine__r.SalesOrder__r.Contact__r.ResidentStatus__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.UnitType__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.UnitModel__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.ProjectProgressAr__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.ProjectProgressEn__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BranchCorporate__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.BranchEscrow__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.Image_URL__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.HandoverProjectGuidelines__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.Project__r.HandoverProjectGuidelinesAR__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameCorporate__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchCorporate__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoCorporate__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c,
                                            InstallmentLine__r.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c

                                        FROM Document__c 
                                        WHERE InstallmentLine__c != null 
                                        AND Id IN: documentIdList
        ];

        // Create a Set to store Account Ids for which we need to query Contacts
        Map<Id, Id> accountId_salesOrderIdMap = new Map<Id, Id>();
        Map<Id, Contact> salesOrderId_ContactMap = new Map<Id, Contact>();

        for (Document__c doc : documentList) {
            if (doc.InstallmentLine__r.SalesOrder__c != null) {
                //Store all Non Person Accounts
                if (!doc.InstallmentLine__r.SalesOrder__r.Account__r.IsPersonAccount) {
                    accountId_salesOrderIdMap.put(doc.InstallmentLine__r.SalesOrder__r.Account__c , doc.InstallmentLine__r.SalesOrder__c);
                }
            }
        }
       
        // Query Contacts for non-Person Accounts
        if (!accountId_salesOrderIdMap.isEmpty()) {
             // [Harsh 23/10]
            //get Contact from Sales Order first
            for(SalesOrder__c thisSalesOrder : [SELECT Id, Contact__c, Contact__r.Id, Contact__r.FirstName, Contact__r.LastName, Contact__r.Salutation,  Contact__r.Email, Contact__r.LanguagePreference__c, Contact__r.ResidentStatus__c FROM SalesOrder__c WHERE Id IN: accountId_salesOrderIdMap.values()]){
                if(thisSalesOrder.Contact__c != null){
                    salesOrderId_ContactMap.put(thisSalesOrder.Id, new Contact( Id = thisSalesOrder.Contact__r.Id, 
                                                                                FirstName = thisSalesOrder.Contact__r.FirstName,
                                                                                LastName = thisSalesOrder.Contact__r.LastName,
                                                                                Salutation = thisSalesOrder.Contact__r.Salutation,
                                                                                Email = thisSalesOrder.Contact__r.Email,
                                                                                LanguagePreference__c = thisSalesOrder.Contact__r.LanguagePreference__c,
                                                                                ResidentStatus__c = thisSalesOrder.Contact__r.ResidentStatus__c
                                                                                ));
                }
            }

            //If Contact was not found on sales order, as a last resort get the first contact under Account
            List<Account> accList = [SELECT Id, (SELECT Id, Name, Salutation,  Email, LanguagePreference__c, ResidentStatus__c FROM Contacts) FROM Account WHERE Id IN: accountId_salesOrderIdMap.keySet()];
            for(Account thisAcc : accList){
                if(thisAcc.Contacts != null && thisAcc.Contacts.size() > 0){
                    Contact relatedContact = thisAcc.Contacts[0];
                    if(accountId_salesOrderIdMap != null && accountId_salesOrderIdMap.get(thisAcc.Id) != null){
                        if(!salesOrderId_ContactMap.containsKey(accountId_salesOrderIdMap.get(thisAcc.Id))){
                            salesOrderId_ContactMap.put(accountId_salesOrderIdMap.get(thisAcc.Id), relatedContact);
                        }
                    } 
                }                               
            }
        }

        //loop again on the dataset and make sure if any sales order has non person account then the contact on it is populated
        for (Document__c doc : documentList) {
            if (doc.InstallmentLine__r.SalesOrder__c != null) {
                if (!doc.InstallmentLine__r.SalesOrder__r.Account__r.IsPersonAccount) {
                    //if Contact field on Sales Order is not populated for a non person account, then add the value to use in the code later
                    if(doc.InstallmentLine__r.SalesOrder__r.Contact__r == null){
                        //check if contact record was found for this, attach
                        if(salesOrderId_ContactMap != null && salesOrderId_ContactMap.get(doc.InstallmentLine__r.SalesOrder__c) != null){
                            doc.InstallmentLine__r.SalesOrder__r.Contact__r = salesOrderId_ContactMap.get(doc.InstallmentLine__r.SalesOrder__c);
                            doc.InstallmentLine__r.SalesOrder__r.Contact__c = salesOrderId_ContactMap.get(doc.InstallmentLine__r.SalesOrder__c).Id;
                        }
                    }
                }
            }
        }
        return documentList;
    }

    /**
     * Get the Virtual Bank Account Records for passed Unit Ids, if none found returns null
     */
     public static Map<Id, Unit__c> getVirtualBankAccountData(List<Id> unitIdList){

        Map<Id, Unit__c> mapDocId_VABankAccount = new Map<Id, Unit__c>();

        for(Unit__c unitRecord : [SELECT Id, VirtualAccountNumber__c, VirtualAccountNumber__r.Name, VirtualAccountNumber__r.BankName__c,
                                VirtualAccountNumber__r.VirtualAccountTitle__c, VirtualAccountNumber__r.VirtualAccountNumber__c, 
                                VirtualAccountNumber__r.VirtualAccountName__c, VirtualAccountNumber__r.VirtualIBANAccountNumber__c, 
                                VirtualAccountNumber__r.Swift_Code__c 
                                FROM Unit__c 
                                WHERE Id IN: unitIdList 
                                AND VirtualAccountNumber__c != null]){

            mapDocId_VABankAccount.put(unitRecord.id, unitRecord);
            
        }
        return mapDocId_VABankAccount;
    }

    /**
     * Generic Util to create EmailMessageRelation records
     */
    public static EmailMessageRelation createEmailMessageRelation(String relationAddress, Id emailMessageId, Id relatedContactId){
        EmailMessageRelation emailMessageRelation = new EmailMessageRelation();
        emailMessageRelation.RelationAddress = relationAddress;
        emailMessageRelation.EmailMessageId = emailMessageId;
        emailMessageRelation.RelationId = relatedContactId; //Can use Contact/Lead/User only
        emailMessageRelation.RelationType = 'ToAddress'; //Can use Contact/Lead/User only

        return emailMessageRelation;
    }

    /*
    * Returns a formatted date string in the 'MMM dd, yyyy' format based on the provided Date parameter.
    * 
    * @param theDate - The input Date to be formatted.
    * @return String - The formatted date string.
    */
    public static String getFormattedDate (Date theDate){
        if(theDate != null){
            Integer thisYear = theDate.year();
            Integer thisMonth = theDate.month();
            Integer thisDate = theDate.day();
            DateTime dt = DateTime.newInstance(thisYear, thisMonth, thisDate);
            System.debug(dt.format('MMM')); // Will print the name of the month
            String formattedDate = dt.format('MMM') + ' ' + thisDate + ', ' + thisYear;
            return formattedDate;
        }else {
            return null;
        }
    }

    /*
    * Rounds the input value to the nearest multiple of 10 with dynamic handling for values from 1 to 100.
    * If the input value is outside the valid range (1 to 100), the original value is returned.
    * The rounding is performed by calculating the remainder when dividing by 10.
    * If the remainder is 5 or greater, 10 is added to round up to the nearest multiple of 10.
    */
    public static Integer roundToTen(Integer arg) {
        if (arg < 1 || arg > 100 || arg == null) {
            return arg; // Return the original value if it's outside the valid range
        }
        Integer remainder = Math.mod(arg, 10);
        Integer roundedValue = arg - remainder;
    
        if (remainder >= 5) {
            roundedValue += 10;
        }
    
        return roundedValue;
    }

    /**
     * Used to get the last installment line using SO Id
     */
    public static InstallmentLines__c getLastInstallmentLine_Handover(String salesOrderId){

        List<InstallmentLines__c> allInstallmentLines = [SELECT Id, InstallmentNumber__c FROM InstallmentLines__c WHERE SalesOrder__c =: salesOrderId ORDER BY InstallmentNumber__c DESC];
        return allInstallmentLines[0];

    }

    /**
     * Used to get Process Name on basis of Type - Used when Naming the Activity
     * Returns a map of Type String => Process Name String
     * Harsh@Aldar 25/01/2024
     */
    public static Map<String, String> getConfigMap_TypeToProcessName(){
        Map<String, String> retMap = new Map<String, String>(); 
        for(SendGrid_Config__mdt thisConfig : SendGrid_Config__mdt.getAll().values()){
            retMap.put(thisConfig.Type__c, thisConfig.Process_Name__c);
        }
        return retMap;
    }

    // Failure : HandoverPhasingLetterDate HandoverPhasingLetterSent field should be emptied out in case of a failure - pending
    // Failure : HandoverPhasing Step -  where summary = 'Handover Phasing' - StepStatus should get to Pending
    // Failure : New field Failure Reason - Update Failure Reason on SR Doc
    public static void updateFailureReason_Handover(Id srDocId, String failureReason, String processName){
        if(srDocId.getSObjectType() == HexaBPM__SR_Doc__c.SObjectType){
            String stepSummary;
            if(processName == 'tpl_ho1_1'){
                stepSummary = 'Handover Phasing';
            }else if(processName == 'tpl_ho2_3'){
                stepSummary = 'Ready for Occupancy';
            }else if(processName == 'tpl_ho2'){
                stepSummary = 'Home Orientation Letter';
            }else if(processName == 'tpl_ho4'){
                stepSummary = 'Home Orientation';
            }else{
                return;
            }

            try {
                if(String.isNotBlank(failureReason)){
                    update new HexaBPM__SR_Doc__c(Id = srDocId, SendGridFailureReason__c = 'There was an error, the API didnt sent a response. Check Logs.');
                }
                resetStats(srDocId, processName);
                resetStep(srDocId, stepSummary);
            } catch (Exception e) {
                System.debug('#### Error when trying to update Failure Reason on SRDoc '+e.getMessage());
            }
        }
    }

    @testVisible
    private static void resetStep(Id srDocId, String stepSummary){
        List<HexaBPM__SR_Doc__c> srList = [SELECT Id, HexaBPM__Service_Request__c FROM HexaBPM__SR_Doc__c WHERE Id =: srDocId LIMIT 1];
        if(srList.size() > 0){
            List<HexaBPM__Step__c> stepsList = [SELECT Id FROM HexaBPM__Step__c WHERE HexaBPM__Summary__c =: stepSummary AND HexaBPM__SR__c =: srList[0].HexaBPM__Service_Request__c LIMIT 1];
            if(stepsList.size() > 0){
                Id stepId = stepsList[0].Id;
                update new HexaBPM__Step__c(Id = stepId, HexaBPM__Status__c = getPendingStatusId());
            }
        } 
    }

    @testVisible
    private static Id getPendingStatusId(){
        List<HexaBPM__Status__c> statusList = [SELECT Id FROM HexaBPM__Status__c WHERE HexaBPM__Code__c = 'Pending' LIMIT 1];
        if(statusList.size() > 0){
            return statusList[0].Id;
        }
        return null;
    }

    private static void resetStats(Id srDocId, String processName){
        List<HexaBPM__SR_Doc__c> handoverDetailRecordList = [SELECT HexaBPM__Service_Request__r.HandoverDetail__c 
                                                                FROM HexaBPM__SR_Doc__c 
                                                                WHERE Id =: srDocId
                                                                LIMIT 1];
        if(processName == 'tpl_ho1_1'){
            update new HandoverDetails__c(Id = handoverDetailRecordList[0].HexaBPM__Service_Request__r.HandoverDetail__c, HandoverPhasingLetterDate__c = null, HandoverPhasingLetterSent__c = false);
        }else if(processName == 'tpl_ho2_3'){
            update new HandoverDetails__c(Id = handoverDetailRecordList[0].HexaBPM__Service_Request__r.HandoverDetail__c, RFOSent__c = false);
        }else if(processName == 'tpl_ho2'){
            update new HandoverDetails__c(Id = handoverDetailRecordList[0].HexaBPM__Service_Request__r.HandoverDetail__c, CHODate__c = null, CHOSent__c = false);
        }else if(processName == 'tpl_ho4'){
            update new HandoverDetails__c(Id = handoverDetailRecordList[0].HexaBPM__Service_Request__r.HandoverDetail__c, HO_Snagging_Letter_Sent__c = false);
        }else{
            return;
        }
    }

    public static void resetFailureReasonOnSRDoc(Id srDocId){
        update new HexaBPM__SR_Doc__c (Id = srDocId, SendGridFailureReason__c = '');
    }

    public static List<String> removeDuplicatesAcrossStrings(String str1, String str2, String str3) {
        // Concatenate all three strings
        String combinedString = str1 + ',' + str2 + ',' + str3;

        // Remove duplicates
        Set<String> uniqueValues = new Set<String>();
        List<String> valuesList = combinedString.split(',');

        for (String value : valuesList) {
            uniqueValues.add(value.trim());
        }

        // Separate unique values into three strings
        List<String> uniqueStrings = new List<String>();
        String uniqueString1 = '';
        String uniqueString2 = '';
        String uniqueString3 = '';

        for (String value : uniqueValues) {
            if (String.isNotBlank(str1) && str1?.contains(value)) {
                uniqueString1 += value + ',';
            } else if(String.isNotBlank(str2) && str2?.contains(value)) {
                uniqueString2 += value + ',';
            } else if(String.isNotBlank(str3) && str3?.contains(value)) {
                uniqueString3 += value + ',';
            }
        }

        uniqueString1 = uniqueString1.removeEnd(',');
        uniqueString2 = uniqueString2.removeEnd(',');
        uniqueString3 = uniqueString3.removeEnd(',');

        uniqueStrings.add(uniqueString1);
        uniqueStrings.add(uniqueString2);
        uniqueStrings.add(uniqueString3);

        return uniqueStrings;
    }
}