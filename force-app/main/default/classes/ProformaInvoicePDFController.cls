/**********************************************************************************************************************
* Name               : ProformaInvoicePDFController                                                        
* Description        : Controller for ProformaInvoicePDF Page
* Created By         : Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     15/09/2023      Initial Draft       
******************************************************************************************************************/
public without sharing class ProformaInvoicePDFController {

    public Wrapper dataWrapper { get; set; }
    
    //When called from button click, only installmentid passed is needed and soql is done
    public ProformaInvoicePDFController() {
        // Retrieve the related object record
        String recordId = ApexPages.currentPage().getParameters().get('id');
        dataWrapper = new Wrapper();
        //get the object api name
        String passedInObjectName = getObjApiNameById(recordId);
        if(passedInObjectName.toLowerCase() == 'installmentlines__c'){
            //get installment record from server first
            fetchDataFromServer(recordId);
        } 
        // else if(passedInObjectName.toLowerCase() == 'salesorderothercharges__c'){
        //     //get installment record from server first
        //     fetchDataFromServer_SOOC(recordId);
         else {
            return;
        }

     }

    private static String getObjApiNameById(Id recordId) {
        String objectApiName = '';
        
        if (recordId != null) {
            // Query the object's metadata to get its API name
            SObjectType objectType = recordId.getSObjectType();
            objectApiName = objectType.getDescribe().getName();
        }
        
        return objectApiName;
    }

    private void fetchDataFromServer(Id installmentLineId){
        InstallmentLines__c installmentRecord = getInstallmentLineData(installmentLineId);
        generateWrapper(installmentRecord);
    } 

    // private void fetchDataFromServer_SOOC(Id soocId){
    //     SalesOrderOtherCharges__c soocRecord = getSOOCData(soocId);
    //     System.debug('####soocRecord: '+soocRecord);
    //     generateWrapper_sooc(soocRecord);
        
    // } 

    // private void generateWrapper_sooc(SalesOrderOtherCharges__c soocRecord){

    //     Map<Id, Unit__c> virtualBankRecordMap = SendGridIntegrationUtilities.getVirtualBankAccountData(new List<Id>{soocRecord.SalesOrder__r.Unit__c});
    //     Unit__c virtualBankRecord = virtualBankRecordMap != null && virtualBankRecordMap.values().size() > 0 ? virtualBankRecordMap.values()[0] : null;
    //     //PI Number
    //     dataWrapper.installmentLineName = String.valueOf(soocRecord.Name);

    //     System.debug('####virtualBankRecordMap: '+virtualBankRecordMap);

    //     //If Virtual Account is not blank
    //     if(virtualBankRecord != null){
    //         dataWrapper.withVA = true;
    //         dataWrapper.virtualAccountTitle = virtualBankRecord.VirtualAccountNumber__r.VirtualAccountTitle__c;
    //         dataWrapper.virtualAccountNumber = virtualBankRecord.VirtualAccountNumber__r.VirtualAccountNumber__c;
    //         dataWrapper.virtualAccountBankName = virtualBankRecord.VirtualAccountNumber__r.BankName__c;
    //         dataWrapper.virtualAccountBankIBAN = virtualBankRecord.VirtualAccountNumber__r.VirtualIBANAccountNumber__c;
    //         dataWrapper.virtualAccountBankSwift = virtualBankRecord.VirtualAccountNumber__r.Swift_Code__c;
    //     }else{
    //         //If Virtual Account is blank
    //         dataWrapper.withVA = false;
    //         //Check Building's Escrow
    //         if(!String.isBlank(soocRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c)){
    //             dataWrapper.escrowBankName = soocRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c;
    //             dataWrapper.escrowBranch = soocRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c;
    //             dataWrapper.escrowAccountName = soocRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c;
    //             dataWrapper.escrowAccountNumber = soocRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c;
    //             dataWrapper.escrowIBAN = soocRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c;
    //             dataWrapper.escrowSwiftCode = soocRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c;
    //         }
    //         //If Building's Escrow is blank, check Project's Escrow
    //         else if(!String.isBlank(soocRecord.SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c)){
    //                 dataWrapper.escrowBankName = soocRecord.SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c;
    //                 dataWrapper.escrowBranch = soocRecord.SalesOrder__r.Unit__r.Project__r.BranchEscrow__c;
    //                 dataWrapper.escrowAccountName = soocRecord.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c;
    //                 dataWrapper.escrowAccountNumber = soocRecord.SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c;
    //                 dataWrapper.escrowIBAN = soocRecord.SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c;
    //                 dataWrapper.escrowSwiftCode = soocRecord.SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c;
    //         }
    //         //If Project's Escrow is also blank, use the Corporate Account on Project
    //         else{
    //             dataWrapper.escrowBankName = soocRecord.SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c;
    //             dataWrapper.escrowBranch = soocRecord.SalesOrder__r.Unit__r.Project__r.BranchCorporate__c;
    //             dataWrapper.escrowAccountName = soocRecord.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c;
    //             dataWrapper.escrowAccountNumber = soocRecord.SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c;
    //             dataWrapper.escrowIBAN = soocRecord.SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c;
    //             dataWrapper.escrowSwiftCode = soocRecord.SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c;
    //         }
    //     }

    //     dataWrapper.accountName = soocRecord.SalesOrder__r.Account__r.Name; 
    //     dataWrapper.accountShippingStreet = soocRecord.SalesOrder__r.Account__r.ShippingStreet;
    //     dataWrapper.accountShippingPostalCode = soocRecord.SalesOrder__r.Account__r.ShippingPostalCode;
    //     dataWrapper.accountShippingCity = soocRecord.SalesOrder__r.Account__r.ShippingCity;
    //     dataWrapper.accountShippingState = soocRecord.SalesOrder__r.Account__r.ShippingState;
    //     dataWrapper.accountShippingCountry = soocRecord.SalesOrder__r.Account__r.ShippingCountry;

    //     // dataWrapper.installmentLineNumber = installmentRecord.InstallmentNumber__c;

    //     dataWrapper.typePreText = soocRecord.TypeOfCharge__c;

    //     // dataWrapper.outstandingAmountWords = soocRecord.OutstandingAmountinwords__c;
    //     // dataWrapper.outstandingAmountAED = soocRecord.OutstandingAmount__c;
    //     // //WHERE TO POINT TO FOR SOOC???????
    //     // dataWrapper.outstandingAmountUSD = soocRecord.OutstandingAmount__c;

    //     dataWrapper.outstandingAmountWords = soocRecord.OutstandingAmountInWords__c;
    //     dataWrapper.outstandingAmountAED = soocRecord.OutstandingAmount__c;
    //     dataWrapper.outstandingAmountUSD = soocRecord.OutstandingAmountNumber__c;

    //     dataWrapper.unitName = soocRecord.SalesOrder__r.Unit__r.Name;
    //     dataWrapper.unitNumber = soocRecord.SalesOrder__r.Unit__r.UnitNumber__c;
        
    //     dataWrapper.todaysDate = String.valueOf(Date.today().format());

    //     // Set Postal Stamp and Logo
    //     if (soocRecord.SalesOrder__r.ProjectName__c != null) {
    //         String projectNameFromServer = soocRecord.SalesOrder__r.ProjectName__c;

    //         Map<String, Proforma_Config__mdt> configMap = Proforma_Config__mdt.getAll();
    //         Proforma_Config__mdt theConfig;

    //         Boolean foundMatch = false;

    //         for (String projectName : configMap.keySet()) {
    //             Proforma_Config__mdt thisConfig = configMap.get(projectName);

    //             if (thisConfig.Project_Name__c == projectNameFromServer) {
    //                 foundMatch = true;
    //                 theConfig = thisConfig;
    //                 break;
    //             }
    //         }

    //         if (!foundMatch) {
    //             // Use default config ('AA_DEFAULT') when no match is found
    //             Proforma_Config__mdt defaultConfig = configMap.get('AA_DEFAULT');
                
    //             if (defaultConfig != null) {
    //                 dataWrapper.projectLogoURL = defaultConfig.Logo__c;
    //                 dataWrapper.postalStampURL = defaultConfig.Postal_Stamp__c;

    //                 dataWrapper.projectLogoHeight = defaultConfig.Project_Logo_CSS__c.split(',')[0];
    //                 dataWrapper.projectLogoWidth = defaultConfig.Project_Logo_CSS__c.split(',')[1];

    //                 dataWrapper.postalStampHeight = defaultConfig.Postal_Stamp_CSS__c.split(',')[0];
    //                 dataWrapper.postalStampWidth = defaultConfig.Postal_Stamp_CSS__c.split(',')[1];
    //             }
    //         }else{
    //             dataWrapper.projectLogoURL = theConfig.Logo__c;
    //             dataWrapper.postalStampURL = theConfig.Postal_Stamp__c;

    //             dataWrapper.projectLogoHeight = theConfig.Project_Logo_CSS__c.split(',')[0];
    //             dataWrapper.projectLogoWidth = theConfig.Project_Logo_CSS__c.split(',')[1];

    //             dataWrapper.postalStampHeight = theConfig.Postal_Stamp_CSS__c.split(',')[0];
    //             dataWrapper.postalStampWidth = theConfig.Postal_Stamp_CSS__c.split(',')[1];
    //         }
    //     }
    // }

    private void generateWrapper(InstallmentLines__c installmentRecord){

        Map<Id, Unit__c> virtualBankRecordMap = SendGridIntegrationUtilities.getVirtualBankAccountData(new List<Id>{installmentRecord.SalesOrder__r.Unit__c});
        Unit__c virtualBankRecord = virtualBankRecordMap != null && virtualBankRecordMap.values().size() > 0 ? virtualBankRecordMap.values()[0] : null;
        dataWrapper.installmentLineName = String.valueOf(installmentRecord.Name);

        System.debug('####virtualBankRecordMap: '+virtualBankRecordMap);

        //If Virtual Account is not blank
        if(virtualBankRecord != null){
            dataWrapper.withVA = true;
            dataWrapper.virtualAccountTitle = virtualBankRecord.VirtualAccountNumber__r.VirtualAccountTitle__c;
            dataWrapper.virtualAccountNumber = virtualBankRecord.VirtualAccountNumber__r.VirtualAccountNumber__c;
            dataWrapper.virtualAccountBankName = virtualBankRecord.VirtualAccountNumber__r.BankName__c;
            dataWrapper.virtualAccountBankIBAN = virtualBankRecord.VirtualAccountNumber__r.VirtualIBANAccountNumber__c;
            dataWrapper.virtualAccountBankSwift = virtualBankRecord.VirtualAccountNumber__r.Swift_Code__c;
        }else{
            //If Virtual Account is blank
            dataWrapper.withVA = false;
            //Check Building's Escrow
            if(!String.isBlank(installmentRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c)){
                dataWrapper.escrowBankName = installmentRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c;
                dataWrapper.escrowBranch = installmentRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c;
                dataWrapper.escrowAccountName = installmentRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c;
                dataWrapper.escrowAccountNumber = installmentRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c;
                dataWrapper.escrowIBAN = installmentRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c;
                dataWrapper.escrowSwiftCode = installmentRecord.SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c;
            }
            //If Building's Escrow is blank, check Project's Escrow
            else if(!String.isBlank(installmentRecord.SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c)){
                    dataWrapper.escrowBankName = installmentRecord.SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c;
                    dataWrapper.escrowBranch = installmentRecord.SalesOrder__r.Unit__r.Project__r.BranchEscrow__c;
                    dataWrapper.escrowAccountName = installmentRecord.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c;
                    dataWrapper.escrowAccountNumber = installmentRecord.SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c;
                    dataWrapper.escrowIBAN = installmentRecord.SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c;
                    dataWrapper.escrowSwiftCode = installmentRecord.SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c;
            }
            //If Project's Escrow is also blank, use the Corporate Account on Project
            else{
                dataWrapper.escrowBankName = installmentRecord.SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c;
                dataWrapper.escrowBranch = installmentRecord.SalesOrder__r.Unit__r.Project__r.BranchCorporate__c;
                dataWrapper.escrowAccountName = installmentRecord.SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c;
                dataWrapper.escrowAccountNumber = installmentRecord.SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c;
                dataWrapper.escrowIBAN = installmentRecord.SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c;
                dataWrapper.escrowSwiftCode = installmentRecord.SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c;
            }
        }

        dataWrapper.accountName = installmentRecord.SalesOrder__r.Account__r.Name; 
        dataWrapper.accountShippingStreet = installmentRecord.SalesOrder__r.Account__r.ShippingStreet;
        dataWrapper.accountShippingPostalCode = installmentRecord.SalesOrder__r.Account__r.ShippingPostalCode;
        dataWrapper.accountShippingCity = installmentRecord.SalesOrder__r.Account__r.ShippingCity;
        dataWrapper.accountShippingState = installmentRecord.SalesOrder__r.Account__r.ShippingState;
        dataWrapper.accountShippingCountry = installmentRecord.SalesOrder__r.Account__r.ShippingCountry;

        dataWrapper.installmentLineNumber = installmentRecord.InstallmentNumber__c;

        //Harsh@aldar 09/01/2024
        // dataWrapper.outstandingAmountWords = installmentRecord.OutstandingAmountToReceiveInWords__c;
        // dataWrapper.outstandingAmountAED = installmentRecord.OutstandingAmountToReceive__c;
        // dataWrapper.outstandingAmountUSD = installmentRecord.OutstandingAmountToReceiveInUSD__c;

        if(installmentRecord.SalesOrder__r.Is_Digital_Sales__c == true && installmentRecord.InstallmentNumber__c ==1){
            dataWrapper.outstandingAmountWords = installmentRecord.OutstandingAmountToReceiveInWords__c;
            dataWrapper.outstandingAmountAED = installmentRecord.OutstandingAmountToReceive__c;
            dataWrapper.outstandingAmountUSD = installmentRecord.OutstandingAmountToReceiveInUSD__c;
        }else{
            dataWrapper.outstandingAmountWords = installmentRecord.OutstandingAmountInWords__c;
            dataWrapper.outstandingAmountAED = installmentRecord.OutstandingAmount__c;
            dataWrapper.outstandingAmountUSD = installmentRecord.OutstandingAmountNumber__c;
        }
        dataWrapper.unitName = installmentRecord.SalesOrder__r.Unit__r.Name;
        dataWrapper.unitNumber = installmentRecord.SalesOrder__r.Unit__r.UnitNumber__c;
        
        dataWrapper.todaysDate = String.valueOf(Date.today().format());

        dataWrapper.typePreText = 'Installment '+dataWrapper.installmentLineNumber+' ';

        // Set Postal Stamp and Logo
        if (installmentRecord.SalesOrder__r.ProjectName__c != null) {
            String projectNameFromServer = installmentRecord.SalesOrder__r.ProjectName__c;
            String sellerNameFromServer = installmentRecord.SalesOrder__r.Unit__r.Project__r.Name_of_Seller__c;

            Map<String, Proforma_Config__mdt> configMap = Proforma_Config__mdt.getAll();
            Proforma_Config__mdt theConfig;

            Boolean foundMatch = false;

            for (String projectName : configMap.keySet()) {
                Proforma_Config__mdt thisConfig = configMap.get(projectName);

                if (thisConfig.Project_Name__c == projectNameFromServer || Test.isRunningTest()) {
                    foundMatch = true;
                    theConfig = thisConfig;
                    break;
                }
            }

            if (foundMatch) {
                dataWrapper.projectLogoURL = theConfig.Logo__c;
                dataWrapper.postalStampURL = theConfig.Postal_Stamp__c;

                dataWrapper.projectLogoHeight = theConfig.Project_Logo_CSS__c.split(',')[0];
                dataWrapper.projectLogoWidth = theConfig.Project_Logo_CSS__c.split(',')[1];

                dataWrapper.postalStampHeight = theConfig.Postal_Stamp_CSS__c.split(',')[0];
                dataWrapper.postalStampWidth = theConfig.Postal_Stamp_CSS__c.split(',')[1];
                
            } else if(sellerNameFromServer?.toLowerCase() == Label.ProformaSellerName.toLowerCase()){
                //Harsh@Aldar 17/01/2024
                //Set stamp according to the Seller Name
                Proforma_Config__mdt aldarDevLLCConfig = configMap.get('AldarDevLLC');
                dataWrapper.projectLogoURL = aldarDevLLCConfig.Logo__c;
                dataWrapper.postalStampURL = aldarDevLLCConfig.Postal_Stamp__c;

                dataWrapper.projectLogoHeight = aldarDevLLCConfig.Project_Logo_CSS__c.split(',')[0];
                dataWrapper.projectLogoWidth = aldarDevLLCConfig.Project_Logo_CSS__c.split(',')[1];

                dataWrapper.postalStampHeight = aldarDevLLCConfig.Postal_Stamp_CSS__c.split(',')[0];
                dataWrapper.postalStampWidth = aldarDevLLCConfig.Postal_Stamp_CSS__c.split(',')[1];
            } else{
                // Use default config ('AA_DEFAULT') when no match is found
                Proforma_Config__mdt defaultConfig = configMap.get('AA_DEFAULT');
                
                if (defaultConfig != null) {
                    dataWrapper.projectLogoURL = defaultConfig.Logo__c;
                    dataWrapper.postalStampURL = defaultConfig.Postal_Stamp__c;

                    dataWrapper.projectLogoHeight = defaultConfig.Project_Logo_CSS__c.split(',')[0];
                    dataWrapper.projectLogoWidth = defaultConfig.Project_Logo_CSS__c.split(',')[1];

                    dataWrapper.postalStampHeight = defaultConfig.Postal_Stamp_CSS__c.split(',')[0];
                    dataWrapper.postalStampWidth = defaultConfig.Postal_Stamp_CSS__c.split(',')[1];
                }
            }
        }
    }

    private static InstallmentLines__c getInstallmentLineData(Id installmentId){
        return  [SELECT Id, Name,
                        OutstandingAmountToReceive__c,
                        OutstandingAmountToReceiveInUSD__c,
                        OutstandingAmountToReceiveInWords__c,
                        InstallmentDate__c,
                        InstallmentNumber__c,
                        OutstandingAmount__c,
                        OutstandingAmountInWords__c,
                        OutstandingAmountNumber__c,
                        InstallmentAmountintheWords__c,
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
                        SalesOrder__r.Unit__r.UnitNumber__c,
                        SalesOrder__r.Contact__r.Salutation, 
                        SalesOrder__r.Account__r.Salutation,
                        SalesOrder__r.Contact__r.Name, 
                        SalesOrder__r.Account__r.Name,
                        SalesOrder__r.Account__r.ShippingStreet,
                        SalesOrder__r.Account__r.ShippingPostalCode,
                        SalesOrder__r.Account__r.ShippingCity,
                        SalesOrder__r.Account__r.ShippingState,
                        SalesOrder__r.Account__r.ShippingCountry,
                        SalesOrder__r.Account__r.ResidentStatus__pc,
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
                        SalesOrder__r.Unit__r.Project__r.Name_of_Seller__c,
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
                        SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c,
                        SalesOrder__r.Is_Digital_Sales__c
            FROM InstallmentLines__c WHERE Id =:installmentId LIMIT 1];
    }

    // private static SalesOrderOtherCharges__c getSOOCData(Id soocId){
    //     return  [SELECT Id, Name,
    //                 Account__c,
    //                 ADMAdminFeeAmount__c,
    //                 Amount__c,
    //                 AmountReceived__c,
    //                 AmountWithoutVAT__c,
    //                 Approval_Status__c,
    //                 Bank_Account_Name__c,
    //                 Bank_Account_Number__c,
    //                 Bank_Name__c,
    //                 Beneficiary_Name__c,
    //                 Branch_Name__c,
    //                 CanEnterReceipt__c,
    //                 Case__c,
    //                 ChargedFromResaleOpp__c,
    //                 Description__c,
    //                 ERPID__c,
    //                 ErrorReason__c,
    //                 FeePaidTo__c,
    //                 FORM_SyncStatus__c,
    //                 IBAN_Number__c,
    //                 InstallmentLine__c,
    //                 InvoicedAmount__c,
    //                 InvoiceDate__c,
    //                 InvoiceId__c,
    //                 InvoiceNumber__c,
    //                 Is_Manual_Entry__c,
    //                 isValidationBypass__c,
    //                 Logger_Id__c,
    //                 Operating_Unit__c,
    //                 Opportunity__c,
    //                 OutstandingAmount__c,
    //                 OutstandingAmountinwords__c,
    //                 OutstandingAmountNumber__c,
    //                 Payment_Method__c,
    //                 PendingAmount__c,
    //                 PO_Box__c,
    //                 ReceiptAcknowledgement__c,
    //                 ReceivableAccount__c,
    //                 Remarks__c,
    //                 ReminderComment__c,
    //                 ReminderDate__c,
    //                 RevenueAccount__c,
    //                 SalesSupportCost__c,
    //                 ServiceRequest__c,
    //                 StatusIndicator__c,
    //                 SubType__c,
    //                 SyncStatus__c,
    //                 TaxAccount__c,
    //                 TypeOfCharge__c,
    //                 VATAmount__c,
    //                 SalesOrder__c,
    //                 SalesOrder__r.Id, 
    //                 SalesOrder__r.Project_Id__c,
    //                 SalesOrder__r.OutstandingAmount__c,
    //                 SalesOrder__r.UnitBuilding__c,
    //                 SalesOrder__r.Unit__c, 
    //                 SalesOrder__r.TotalInstallmentNo__c, 
    //                 SalesOrder__r.EquityPercentage__c, 
    //                 SalesOrder__r.TotalOutstanding__c, 
    //                 SalesOrder__r.Contact__c,
    //                 SalesOrder__r.Contact__r.LanguagePreference__c, 
    //                 SalesOrder__r.Account__r.LanguagePreference__pc, 
    //                 SalesOrder__r.ProjectName__c,
    //                 SalesOrder__r.Unit__r.Name,
    //                 SalesOrder__r.Unit__r.UnitNumber__c,
    //                 SalesOrder__r.Contact__r.Salutation, 
    //                 SalesOrder__r.Account__r.Salutation,
    //                 SalesOrder__r.Contact__r.Name, 
    //                 SalesOrder__r.Account__r.Name,
    //                 SalesOrder__r.Account__r.ShippingStreet,
    //                 SalesOrder__r.Account__r.ShippingPostalCode,
    //                 SalesOrder__r.Account__r.ShippingCity,
    //                 SalesOrder__r.Account__r.ShippingState,
    //                 SalesOrder__r.Account__r.ShippingCountry,
    //                 SalesOrder__r.Account__r.ResidentStatus__pc,
    //                 SalesOrder__r.Unit__r.UnitType__c,
    //                 SalesOrder__r.Unit__r.UnitModel__c,
    //                 SalesOrder__r.Unit__r.Project__c,
    //                 SalesOrder__r.Unit__r.Project__r.ProjectProgressAr__c,
    //                 SalesOrder__r.Unit__r.Project__r.ProjectProgressEn__c,
    //                 SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c,
    //                 SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c,
    //                 SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c,
    //                 SalesOrder__r.Unit__r.Project__r.BranchCorporate__c,
    //                 SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c,
    //                 SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c,
    //                 SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c,
    //                 SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c,
    //                 SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c,
    //                 SalesOrder__r.Unit__r.Project__r.BranchEscrow__c,
    //                 SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c,
    //                 SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameCorporate__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__r.BranchCorporate__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoCorporate__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c,
    //                 SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c 
    //             FROM SalesOrderOtherCharges__c 
    //             WHERE Id =: soocId
    //             LIMIT 1];
    // }

    public class Wrapper{ 

        public Boolean withVA {get; set;}
        //PI
        public String installmentLineName {get;set;}

        public String typePreText {get;set;}

        public String accountName {get;set;}
        public String accountShippingStreet {get;set;}
        public String accountShippingPostalCode {get;set;}
        public String accountShippingCity {get;set;}
        public String accountShippingState {get;set;}
        public String accountShippingCountry {get;set;}

        public Decimal installmentLineNumber {get;set;}
        public String outstandingAmountWords {get;set;}
        public Decimal outstandingAmountAED {get;set;}
        public Decimal outstandingAmountUSD {get;set;}

        public String unitName {get;set;}
        public String unitNumber {get;set;}

        public String virtualAccountTitle {get;set;}
        public String virtualAccountNumber {get;set;}
        public String virtualAccountBankName {get;set;}
        public String virtualAccountBankIBAN {get;set;}
        public String virtualAccountBankSwift {get;set;}

        public String todaysDate {get;set;}

        public String escrowBankName {get;set;}
        public String escrowBranch {get;set;}
        public String escrowAccountName {get;set;}
        public String escrowAccountNumber {get;set;}
        public String escrowIBAN {get;set;}
        public String escrowSwiftCode {get;set;}

        public String projectLogoURL {get;set;}
        public String projectLogoHeight {get;set;}
        public String projectLogoWidth {get;set;}
        public String postalStampURL {get;set;}
        public String postalStampHeight {get;set;}
        public String postalStampWidth {get;set;}
    }
}