/*
* Name               : CustomerSearchWebService
* Description        : Utility class for All Customer Web Service related common methods and SOQL Query
* last modified by   : Protiviti
* Version			 : V1.1 smaartt team
* Version			 : V1.2 Added by Protiviti when retail contact logic added to CustomerProfileWeservice class.
*/
public with sharing class CustomerServiceUtility {
    
    //----- Get File from Parent record Id//
    public static ContentVersion getContentVersion(String recordId) {
        ContentVersion cv = new ContentVersion();
		List<Document__c> documentList = new List<Document__c>();
        Boolean enableKycHistoryValidation = false;
        Document__c document = null;
        Document__History lastKYCGen = null;
        try {
            
            ContentDocumentLink documentLink = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: recordId 
                                                AND (NOT ContentDocument.Title LIKE 'CertificateOfCompletion%') ORDER BY SystemModstamp DESC LIMIT 1];
            
            if (documentLink.Id != null) {
                String contentDocumentId = documentLink.ContentDocumentId;
                String contentVersionQuery = 'SELECT Id, FileExtension, ContentDocumentId, Title, VersionData, ContentSize, CreatedDate, LastModifiedDate FROM ContentVersion WHERE ContentDocumentId = \'' + String.escapeSingleQuotes(contentDocumentId) +'\' AND IsLatest = true';
                
                if(!String.isBlank(Label.Enable_KYC_History_Validation)) {
                    enableKycHistoryValidation = Boolean.valueOf(Label.Enable_KYC_History_Validation);
                }
                if(enableKycHistoryValidation) {
                    documentList = getDocumentDetail('Id = \'' + String.escapeSingleQuotes(recordId) + '\'');
                    
                    if(!documentList.isEmpty()) {
                        document = documentList[0];
                    }
                    if(document != null && document.DocumentType__c == Constants.DOCUMENT_TYPE_KYC) {
                        try {
                            lastKYCGen = [SELECT Id,CreatedDate FROM Document__History WHERE ParentId = :recordId AND Parent.DocumentType__c = :Constants.DOCUMENT_TYPE_KYC AND Field = 'GenerateDocument__c' Order BY Createddate DESC LIMIT 1];
                        } catch(QueryException qe) {
                            lastKYCGen = null;
                        }
                        if(lastKYCGen != null) {
                            contentVersionQuery += ' AND CreatedDate >= ' + lastKYCGen.CreatedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''); 
                        }
                    }
                }
                contentVersionQuery += ' LIMIT 1';
                cv = Database.query(contentVersionQuery);
            }
        } catch (Exception ex) {
            return null;
        }
        return cv;
    }
    
    //----- Get Account details which custom where clause
    public static List<Account> getAccountDetail(String whereClause) {
        //V1.2 Modified below line by Protiviti. Added CustomerVertical__c to the query
        String query = 'SELECT Id, Name, FirstName, LastName, MiddleName, CustomerVertical__c, Industry, CustomerAppWebUser__c, AccountNumber__c, CountryOfResidence__pc, Blacklisted__c, BlacklistReason__c,CustomerResellPreference__c,isCustomerAppLocked__c,Customer_PEP__c,PEP_Details__c,DualCitizenship__c,SecondaryCitizenshipCountry__c,ERPID__c,IsPersonAccount,NameInArabic__c,IsJointOwnerRegistration__c,';//Added isCustomerAppLocked__c by Sarah on Mar 22, 2024;Customer_PEP__c by Sarah on Apr 10, 2024; PEP_Details__c by Sarah on April 15, 2024
        query += ' BillingStreet, BillingCity, BillingPostalCode, BillingState, BillingCountry, ShippingStreet, ShippingCity, ShippingPostalCode, ShippingState, ShippingCountry, ResidentialAddressSameAsPermanent__c,PersonContactId, MobileNumber1__c, MobileCountryCode__c, ';
        query += ' PersonBirthdate, Placeofbirth__c, PersonEmail,PersonMobilePhone, MobileCountryCode__pc,  MobilePhone__pc, CustomerType__c, CustomerSubType__c, Gender__pc, MaritalStatus__pc, VisaUIDNo__pc, VisaExpiryDate__pc,VisaType__c, CountryofBirth__pc, Number_of_Kids__pc, Interested_in_Cryptocurrency__pc, Other_Source_of_Funds__pc, ';
        query += ' Nationality__pc, NationalIdNumber__pc, NationalIdExpiryDate__pc, UAEPassConsolidated__c, ResidentStatus__pc, Passport_type__pc, PassportNumber__pc, PlaceofIssue__pc, PassportIssueDate__pc, PassportExpiryDate__pc, ';
        query += ' CustomerBankName__c, CustomerBankCountry__c, EmploymentStatus__pc, Company__pc, Workplace_Country__pc, Workplace_Postalcode__pc, Workplace_Street__pc, NoofYearswithCompany__pc, Position__pc, AnnualIncome__pc, SourceofFunds__pc, SapAccountID__c,FastTrackedAccount__c,';
        query += ' CMAccountManager__c, CMAccountManager__r.Name, CMAccountManager__r.Email, CMAccountManager__r.MobilePhone, CMAccountManager__r.Phone, ';
        query += ' KeyAccountManager__c, KeyAccountManager__r.Name, KeyAccountManager__r.Email, KeyAccountManager__r.MobilePhone, KeyAccountManager__r.Phone, Owner.Profile.Name, Owner.Name,OwnerId,Owner.MobilePhone, Owner.Phone, Owner.Email,' ;
        query += ' (SELECT Id, Name, Status__c FROM Opportunity_Units__r WHERE Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\'), ';
        query += ' (SELECT Id, Name, DocumentType__c, EligibleForeSign__c, Status__c, Case__c, Case__r.IsClosed,Createddate FROM Documents__r ORDER BY DocumentType__c ASC, LastModifiedDate DESC), ';
        query += ' (SELECT Id,Name,Owner.Name,OwnerId,Category__c,Status__c,FasttrackProgress__c,CreatedDate,FastTrack_Completion_Date_Time__c,isFastTrackAutoCompleted__c,Signzyskipped__c,Unit__c,Unit__r.Project__r.Id,Unit__r.Project__r.CommunityName__c,Lead__r.Name,Opportunity__c,Opportunity__r.OwnerId,Opportunity__r.Owner.Name,Document__c,SPAProgress__c,SPAStepStatus__c,isForgeryCheckFailedForPassport__c,ForgeryFailureResponse__c,isLivenessCheckFailed__c,LivenessFailureResponse__c ,Sales_Order__r.Unit__r.Name,Sales_Order__r.SalesManager__c,Sales_Order__r.SalesManager__r.Name,Sales_Order__r.SalesManager__r.Email,Sales_Order__r.SalesManager__r.MobilePhone,Unit__r.Status__c,Sales_Order__r.Status__c,Sales_Order__r.SubStatus__c,Sales_Order__c,Unit__r.Name,Unit__r.ReservationAmount__c,Document__r.Esignlocation__c,Active__c,Lead__c,Source_Type__c,Account__c,Project__c FROM Communication_Preferences__r WHERE (Category__c = \'FastTrack\' OR Category__c=\'Booking\' OR Category__c=\'NOC-FastTrack\' OR Category__c=\'Digital SPA\' OR Category__c=\'Premium Parking\' ) ORDER BY CreatedDate DESC) ';//Added by Tajinkumar - LAC-1988 
        query += ' FROM Account ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        System.debug('Account Query>>>' + query);
        List<Account> returnAccountList = Database.query(query);
        System.debug('Account Records>>>' + returnAccountList);
        
        return returnAccountList;
    }
    
    //----- Get Sales Order details which custom where clause
    public static List<SalesOrder__c> getSalesOrderDetailForProfile(String whereClause) {
        //Ajay - removed UnitCategory__c field from query bcz of p1 SF|Docusign issue
        //harsh@aldar 15/05/2026 Added UnitCategory__c back
        String query = 'SELECT Id, Name, CurrencyIsoCode, Unit__c, Account__c, Account__r.Name, Account__r.Blacklisted__c, Account__r.BlacklistReason__c, Account__r.CustomerResellPreference__c, Status__c, TitleDeedRegistrationNumber__c, TitleDeedRegistrationStatus__c,SubStatus__c,Is_Digital_Sales__c,Opportunity__c, ';//CustomerResellPreference field is added in query by Sarah on Mar 20, 2024
        query += ' RTOConverted__c, RTODiscount__c, RTONetAmount__c, RTOOriginalSellingPrice__c, ReservationEnddate__c, ReservationStartDate__c, HoldFlag__c,  CPCAllocated__c, HandoverServiceChargeStartDate__c, HandoverServiceChargeEndDate__c, AMCStartDate__c, AMCEndDate__c, PMAStartDate__c, PMAEndDate__c, ';
        query += ' AccountCity__c, AccountCountry__c, AccountEmail__c, AccountFirstName__c, AccountLastName__c, AccountMiddleName__c, AccountMobileNumber__c, AccountNameArabic__c, AccountName__c, AccountNationality__c, AccountNumber__c, AccountPassportNumber__c, AccountRecordType__c, AccountSalutation__c, AccountUAEID__c, CustomerDLPStartDate__c, DLPDate__c, HandoverReadyforOccupancyDate__c, UnitFinishing__c, UnitFurnishing__c, CustomerSPASigned__c, SignatureType__c, ';
        query += ' ADMFeeAmount__c, AmountPayable__c, BookingDate__c, NetAmountInWords__c, NetAmount__c, OwnerSharePercentage__c, SalesApprovedDate__c, SellingPrice__c, SoldDate__c, TerminationLetterSentFlag__c, ADMPercentage__c, ADMUnitNumber__c, ProjectName__c, SalesManagerName__c, ReservationamountNumber__c, IsReservation__c, GFAArea__c, TotalBilled__c, TotalInstallmentReceived__c, TotalOutstanding__c, OutstandingAmount__c, Gross_Sellable_Area__c, ADM_Admin_Fee__c, Total_ADM_Amount__c, TotalInstallmentNo__c, EquityPercentage__c, ';
        query += ' UnitADMPlotNumber__c, UnitADMSectorName__c, UnitAreaUOM__c, UnitCarParks__c, UnitFloor__c, UnitInternalArea__c, UnitCategory__c, UnitModel__c, UnitNumber__c, UnitPlotArea__c, UnitReservationFee__c, UnitSaleableArea__c, UnitSellingPrice__c, UnitTerraceArea__c, UnitTotalArea__c, UnitType__c,Unit__r.Project__r.CommunityName__c, Unit__r.Project__c, Unit__r.ProjectCode__c, Unit__r.Name, Unit__r.TotalArea__c, Unit__r.AreaUOM__c, Unit__r.ADMUnitNumber__c, Unit__r.BuildingSectionName__c, Unit__r.BuildingSectionName__r.CompletionCertificateDate__c, Unit__r.RecordType.Name, Unit__r.NumberOfBedrooms__c, Unit__r.NumberOfBathrooms__c, Unit__r.Project__r.Name, Unit__r.Project__r.City__c, Unit__r.Project__r.EnableDocumentsCustomerPortal__c, Unit__r.Project__r.EnableServiceCharge__c,Unit__r.Project__r.ProjectLocation__c ,Unit__r.Project__r.ECSS_ProjectCode__c, ';// Added UnitCategory__c on Apr 14, 2025 by Neelesh : OB-2266 : desc:: Added for furniture project
        query += ' Unit__r.ADMARBSectorName__c,Unit__r.ADMSectorName__c,Unit__r.ADMBuildingNumber__c,Unit__r.ADMFloorNumber__c,Unit__r.ADMZone__c,Unit__r.ADMPlotNumber__c,Unit__r.ADMZoneArabic__c, ';
        query += ' (SELECT Id, Name, Account__c, SharePercentage__c, Account__r.Name FROM Joint_OwnersSalesOrder__r) ';
        query += ' , LastInstallmentRebate__c, OtherRebateAmount__c';
        query += ' , (SELECT Id, Status FROM Cases__r WHERE RecordType.DeveloperName = \'Resale\' AND Status NOT IN (\'Closed\', \'Cancelled\')) ';
        query += ' FROM SalesOrder__c ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        System.debug('Sales Order Query>>>' + query);
        List<SalesOrder__c> returnSalesOrderList = Database.query(query);
        System.debug('Sales Order Records>>>' + returnSalesOrderList);
        
        return returnSalesOrderList;
    }
    
    //----- Get Sales Order details which custom where clause
    public static List<SalesOrder__c> getSalesOrderDetail(String whereClause) {
        //Ajay - removed UnitCategory__c field from query bcz of p1 SF|Docusign issue (made code match to prod)
        //harsh@aldar 15/05/2026 Added UnitCategory__c back
        String query = 'SELECT Id, Name, CurrencyIsoCode, Unit__c, Account__c, Account__r.Name, Account__r.Blacklisted__c, Account__r.BlacklistReason__c, Account__r.CustomerResellPreference__c, Status__c, TitleDeedRegistrationNumber__c, TitleDeedRegistrationStatus__c, SalesManager__c, SalesManager__r.Name, SalesManager__r.Email,Unit__r.Project__r.CommunityName__c,Is_Digital_Sales__c,SubStatus__c,Account__r.PersonContactId,Account__r.GTYB_Form_Submitted__pc,';
        query += ' RTOConverted__c, RTODiscount__c, RTONetAmount__c, RTOOriginalSellingPrice__c, ReservationEnddate__c, ReservationStartDate__c, HoldFlag__c, CPCAllocated__c, HandoverServiceChargeStartDate__c, HandoverServiceChargeEndDate__c, AMCStartDate__c, AMCEndDate__c, PMAStartDate__c, PMAEndDate__c,Payment_Type__c, ';
        query += ' AccountCity__c, AccountCountry__c, AccountEmail__c, AccountFirstName__c, AccountLastName__c, AccountMiddleName__c, AccountMobileNumber__c, AccountNameArabic__c, AccountName__c, AccountNationality__c, AccountNumber__c, AccountPassportNumber__c, AccountRecordType__c, AccountSalutation__c, AccountUAEID__c, CustomerDLPStartDate__c, DLPDate__c, HandoverReadyforOccupancyDate__c, UnitFinishing__c, UnitFurnishing__c, CustomerSPASigned__c, SignatureType__c, ';
        query += ' ADMFeeAmount__c, AmountPayable__c, BookingDate__c, NetAmountInWords__c, NetAmount__c, OwnerSharePercentage__c, SalesApprovedDate__c, SellingPrice__c, SoldDate__c, TerminationLetterSentFlag__c, ADMPercentage__c, ADMUnitNumber__c, ProjectName__c, SalesManagerName__c, ReservationamountNumber__c, IsReservation__c, GFAArea__c, TotalBilled__c, TotalInstallmentReceived__c, TotalOutstanding__c, OutstandingAmount__c, Gross_Sellable_Area__c, ADM_Admin_Fee__c, Total_ADM_Amount__c, TotalInstallmentNo__c, EquityPercentage__c, ';
        query += ' UnitADMPlotNumber__c, UnitADMSectorName__c, UnitAreaUOM__c, UnitCarParks__c, UnitFloor__c, UnitInternalArea__c, UnitModel__c, UnitNumber__c, UnitPlotArea__c, UnitReservationFee__c, UnitSaleableArea__c, UnitSellingPrice__c, UnitTerraceArea__c, UnitTotalArea__c, UnitType__c,Unit__r.Id,Unit__r.LockExpiryTime__c,Unit__r.LockedBy__c,Unit__r.LockedByCustomer__c,Unit__r.Status__c,Unit__r.DigitalSales__c, Unit__r.Project__c, Unit__r.ProjectCode__c, Unit__r.Name, Unit__r.ADDCPremiseId1__c, Unit__r.TotalArea__c, Unit__r.AreaUOM__c, Unit__r.ADMUnitNumber__c, Unit__r.BuildingSectionName__c, Unit__r.BuildingSectionName__r.CompletionCertificateDate__c, Unit__r.RecordType.Name, Unit__r.NumberOfBedrooms__c, Unit__r.NumberOfBathrooms__c, Unit__r.Project__r.Name, Unit__r.Project__r.City__c, Unit__r.Project__r.EnableDocumentsCustomerPortal__c, Unit__r.Project__r.EnableServiceCharge__c, ';
        query += ' (SELECT Id, Name, InstallmentDate__c, OriginalInstallmentDate__c, InstallmentPayoutDate__c, InstallmentAmount__c, OutstandingAmount__c, OutstandingAmountToReceive__c, InstallmentNumber__c, InstallmentPercentage__c, InvoiceId__c, InvoiceNumber__c, InvoicedAmount__c, IsStopPayment__c, Description__c, SalesOrder__c, SalesOrder__r.Name, SalesOrder__r.Unit__c, SalesOrder__r.UnitNumber__c, SalesOrder__r.CollectionPercentage__c, RTOLine__r.RentEscalation__c, RTOLine__r.RebateAmount__c, RTOLine__r.RTOConfiguration__r.DiscountPercentage__c, RTOLine__r.OptionFee__c, RTOLine__r.OptionFeeAmount__c, RTOLine__r.RemainingPayment__c, RTOLine__r.Rent__c, PaymentInstallments__c, PaymentInstallments__r.IsHandoverPayment__c, PaymentInstallments__r.DelayDays__c, PaymentInstallments__r.DelayReason__c, SalesOrder__r.BookingDate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c, SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c, SalesOrder__r.Unit__r.VirtualAccountNumber__c, SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c, SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c, SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c, SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c, SalesOrder__r.Unit__r.Project__r.BranchEscrow__c, SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c, SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c, SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c, SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c, SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c, SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameCorporate__c, SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BranchCorporate__c, SalesOrder__r.Unit__r.Project__r.BranchCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoCorporate__c, SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c, SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c, SalesOrder__r.Unit__r.Project__c, SalesOrder__r.Unit__r.BuildingSectionName__c,SalesOrder__r.Unit__r.ExpectedCustomerHandoverDate__c ,SalesOrder__r.ComplianceStatus__c,SalesOrder__r.Status__c,SalesOrder__r.Unit__r.Project__r.ReservationAmount__c  FROM InstallmentLines__r ORDER BY InstallmentNumber__c asc), ';
        query += ' (SELECT Id, Name, CreatedDate, Amount__c, PendingAmount__c, SubType__c, TypeOfCharge__c, OutstandingAmount__c, InvoiceId__c, InvoiceNumber__c, InvoicedAmount__c, SalesOrder__c, SalesOrder__r.Name, SalesOrder__r.Unit__c, SalesOrder__r.UnitNumber__c, Account__r.Name, SalesOrder__r.BookingDate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c, SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c, SalesOrder__r.Unit__r.VirtualAccountNumber__c, SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c, Account__c, SalesOrder__r.Account__c, SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c, SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c, SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c, SalesOrder__r.Unit__r.Project__r.BranchEscrow__c, SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c, SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c, SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c, SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c, SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c, SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameCorporate__c, SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BranchCorporate__c, SalesOrder__r.Unit__r.Project__r.BranchCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoCorporate__c, SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c, SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c, SalesOrder__r.Unit__r.Project__c, SalesOrder__r.Unit__r.BuildingSectionName__c,ReceiptAcknowledgement__c,SalesOrder__r.Sales_Type__c FROM SalesOrdersOtherCharges__r), ';
        query += ' (SELECT Id, Name, PaymentType__c, InstallmentLine__c, SalesOrderOtherCharges__c, AmountApplied__c, ReceiptAcknowledgement__r.ClearedDate__c, ReceiptAcknowledgement__r.Status__c FROM ReceiptAllocations__r ORDER BY LastModifiedDate DESC), ';
        query += ' (SELECT Id, Name, Account__c, SharePercentage__c, Account__r.Name FROM Joint_OwnersSalesOrder__r), ';
        //Added By Neelesh@Aldar 04/03/2025 Premium Parking
        query += ' (SELECT Id, Name, OrderNumber, TotalAmount, Sales_Order__r.UnitNumber__c FROM Orders__r), ';
        query += ' (SELECT Id, Name, DocumentType__c, EligibleForeSign__c,CreatedDate, Status__c FROM Documents__r ORDER BY DocumentType__c ASC) ';
        query += ' FROM SalesOrder__c ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        System.debug('Sales Order Query>>>' + query);
        List<SalesOrder__c> returnSalesOrderList = Database.query(query);
        System.debug('Sales Order Records>>>' + returnSalesOrderList);
        
        return returnSalesOrderList;
    }
    
    //----- Get Sales Order details which custom where clause
    public static List<SalesOrder__c> getSalesOrderDetailWithSR(String whereClause) {
        String query = 'SELECT Id, Name, Unit__c, Unit__r.Name,Unit__r.DLPZone__c,Unit__r.DLPZone__r.ContractorDLPStatus__c,Account__c, Account__r.Name, Account__r.Blacklisted__c, Account__r.BlacklistReason__c, Account__r.CustomerResellPreference__c, Status__c, HoldFlag__c, CPCAllocated__c, Unit__r.RecordType.Name,CustomerDLPStatus__c, CustomerDLPStartDate__c, DLPDate__c, HandoverServiceChargeStartDate__c, HandoverServiceChargeEndDate__c, DARNAAmount__c, ';
        query += ' (SELECT Id, Name, RecordType.Name, HexaBPM__Closed_Date_Time__c FROM ServiceRequests__r) ';
        query += ' FROM SalesOrder__c ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        System.debug('Sales Order Query>>>' + query);
        List<SalesOrder__c> returnSalesOrderList = Database.query(query);
        System.debug('Sales Order Records>>>' + returnSalesOrderList);
        
        return returnSalesOrderList;
    }
    
    //----- Get Installment Line details which custom where clause
    public static List<InstallmentLines__c> getInstallmentLineDetail(String whereClause) {
        String query = 'SELECT Id, Name, InstallmentDate__c, OriginalInstallmentDate__c, InstallmentPayoutDate__c, InstallmentAmount__c, OutstandingAmount__c, OutstandingAmountToReceive__c, InstallmentNumber__c, InstallmentPercentage__c, Description__c,SalesOrder__r.Unit__r.ExpectedCustomerHandoverDate__c,SalesOrder__r.Unit__r.Project__r.ReservationAmount__c, ';
        query += ' InvoiceId__c, InvoiceNumber__c, InvoicedAmount__c, IsStopPayment__c, PaymentInstallments__c, PaymentInstallments__r.IsHandoverPayment__c, PaymentInstallments__r.DelayDays__c, PaymentInstallments__r.DelayReason__c, SalesOrder__c, SalesOrder__r.Name, SalesOrder__r.Unit__c, SalesOrder__r.UnitNumber__c, SalesOrder__r.Account__c, SalesOrder__r.CollectionPercentage__c, SalesOrder__r.Unit__r.Project__c, SalesOrder__r.Unit__r.BuildingSectionName__c,SalesOrder__r.ComplianceStatus__c,SalesOrder__r.Status__c, ';
        query += ' SalesOrder__r.BookingDate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c, SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c, SalesOrder__r.Unit__r.VirtualAccountNumber__c, SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c, SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c, SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c, SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c, SalesOrder__r.Unit__r.Project__r.BranchEscrow__c, SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c, SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c, SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c, SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c, SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c, SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameCorporate__c, SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BranchCorporate__c, SalesOrder__r.Unit__r.Project__r.BranchCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoCorporate__c, SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c, SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c, ';
        query += ' (SELECT Id, Name, PaymentType__c, AmountApplied__c,Account__c, Account__r.PersonEmail, ReceiptAcknowledgement__r.ClearedDate__c, ReceiptAcknowledgement__r.Status__c FROM Receipt_Allocations__r ORDER BY LastModifiedDate DESC) ';//Account__r.PersonEmail added by Sarah on Mar 12, 2024 for ASF-
        query += ' FROM InstallmentLines__c ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        System.debug('query line no 107 ' + query);
        
        List<InstallmentLines__c> returnInstallmentLineList = Database.query(query);
        System.debug('returnInstallmentLineList List: ' + returnInstallmentLineList);
        
        
        return returnInstallmentLineList;
    }
    
    //----- Get Sales Orer Other Charges details which custom where clause
    public static List<SalesOrderOtherCharges__c> getSalesOrderOtherChargeDetail(String whereClause) {
        String query = 'SELECT Id, Name, CreatedDate, Amount__c, PendingAmount__c, SubType__c, TypeOfCharge__c, OutstandingAmount__c, Account__c,ReceiptAcknowledgement__c,SalesOrder__r.Sales_Type__c, ';
        query += ' InvoiceId__c, InvoiceNumber__c, InvoicedAmount__c, SalesOrder__c, SalesOrder__r.Name, SalesOrder__r.Unit__c, SalesOrder__r.UnitNumber__c, SalesOrder__r.Account__c, SalesOrder__r.Unit__r.Project__c, SalesOrder__r.Unit__r.BuildingSectionName__c, ';
        query += ' SalesOrder__r.BookingDate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameEscrow__c, SalesOrder__r.Unit__r.Project__r.BeneficiaryNameEscrow__c, SalesOrder__r.Unit__r.VirtualAccountNumber__c, SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c, SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoEscrow__c, SalesOrder__r.Unit__r.Project__r.IBANNoEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameEscrow__c, SalesOrder__r.Unit__r.Project__r.BankNameEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BranchEscrow__c, SalesOrder__r.Unit__r.Project__r.BranchEscrow__c, SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualAccountNumber__c, SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberEscrow__c, SalesOrder__r.Unit__r.Project__r.AccountNumberEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeEscrow__c, SalesOrder__r.Unit__r.Project__r.SwiftCodeEscrow__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BeneficiaryNameCorporate__c, SalesOrder__r.Unit__r.Project__r.BeneficiaryNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.AccountNumberCorporate__c, SalesOrder__r.Unit__r.Project__r.AccountNumberCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BankNameCorporate__c, SalesOrder__r.Unit__r.Project__r.BankNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BranchCorporate__c, SalesOrder__r.Unit__r.Project__r.BranchCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.IBANNoCorporate__c, SalesOrder__r.Unit__r.Project__r.IBANNoCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.SwiftCodeCorporate__c, SalesOrder__r.Unit__r.Project__r.SwiftCodeCorporate__c, ';
        query += ' (SELECT Id, Name, PaymentType__c, AmountApplied__c, ReceiptAcknowledgement__r.ClearedDate__c, ReceiptAcknowledgement__r.Status__c FROM ReceiptAllocations__r ORDER BY LastModifiedDate DESC) ';
        query += ' FROM SalesOrderOtherCharges__c ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        List<SalesOrderOtherCharges__c> returnSalesOrderOtherChargeList = Database.query(query);
        System.debug('Sales Order Other Charges List: ' + returnSalesOrderOtherChargeList);
        System.debug('query line no 119 ' + query);
        return returnSalesOrderOtherChargeList;
    }
    
    //----- Get Document details which custom where clause
    //Update by Harsh@ALD 17/02/2025 - Added Quote__c, Order__c
    public static List<Document__c> getDocumentDetail(String whereClause) {
        String query = 'SELECT Id, Name, DocumentType__c, EligibleForeSign__c,CreatedDate, Account__c, SalesOrder__c, Case__c, Opportunity__c, Unit__c, Unit__r.Name, Status__c, Quote__c, Order__c ';
        query += ' FROM Document__c ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        System.debug('Document Query>>>' + query);
        List<Document__c> returnDocumentList = Database.query(query);
        
        return returnDocumentList;
    }
    
    //----- Get Service Request Document details which custom where clause
    public static List<HexaBPM__SR_Doc__c> getSRDocDetail(String whereClause) {
        String query = 'SELECT Id, Name, DocumentMasterCode__c, HexaBPM__Service_Request__c,Docusign_Envelope_Id__c, HexaBPM__Service_Request__r.HexaBPM__Customer__c, HexaBPM__Service_Request__r.SalesOrder__c,HexaBPM__Document_Name__c,HexaBPM__Status__c,Provis_Reason__c,CreatedDate, HexaBPM__Service_Request__r.SalesOrder__r.Unit__r.Name,HexaBPM__Service_Request__r.SRType__c,HexaBPM__Document_Master__r.AvailableForCustomer__c,HexaBPM__Document_Master__r.Live_Aldar_Display_Name__c ';
        query += ' FROM HexaBPM__SR_Doc__c ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        System.debug('SR Doc Query>>>' + query);
        List<HexaBPM__SR_Doc__c> returnSRDocList = Database.query(query);
        
        return returnSRDocList;
    }
    
    //----- Get Appointment details which custom where clause
    public static List<Appointment__c> getAppointmentDetail(String whereClause) {
        String query = 'SELECT Id, Name, AppointmentId__c, Lead__c, Lead__r.Status, Lead__r.ConvertedAccountId, Lead__r.ConvertedOpportunityId, Opportunity__c, Opportunity__r.AccountId, ';
        query += ' Opportunity__r.FastTrackedOpportunity__c, Opportunity__r.NumberOfUnits__c, Opportunity__r.EstimatedPurchaseValue__c ';
        query += ' FROM Appointment__c ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        List<Appointment__c> returnAppointmentList = Database.query(query);
        
        return returnAppointmentList;
    }
    
    //----- Get Case details which custom where clause 
    //V1.1 Change here: added extrnal file in the query
    public static List<Case> getCaseDetail(String whereClause) {//v1.1
        String query = 'SELECT Id, CaseNumber, Priority, AccountId, Account.Name, RecordType.Name, CreatedDate, Status, IsClosed, ClosedDate, Origin, Subject, StatusReason__c, Unit__c, Unit__r.Name,Unit__r.BuildingSectionName__r.Precint_Name__c, DLP_Reason_for_Cancel__c,DLP_Closure_Reason__c,AMC_Closure_Reason__c,AMC_Due_Date__c, Description, CaseComments__c, Type,LastModifiedDate, ParentId,';
        query += ' SalesOrder__c, SalesOrder__r.Name, Organization__c, Department__c, Vertical__c, SubVertical__c, ProblemCode__c,IncidentDescription__c,CaseCategory__c, SubCategory__c, CustomerComment__c, CommentsForCustomer__c, OwnerId,';
        query += '(SELECT Id,File_Name__c,Comment__c,File_Format__c,External_URL__c FROM External_Files__r), (SELECT Id, Name, DocumentType__c, EligibleForeSign__c, Status__c FROM Documents__r ORDER BY DocumentType__c ASC),';
        query += ' (SELECT id, CommentBody, CreatedDate from CaseComments)';
        query += ' FROM Case ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        System.debug('query>>>' + query);
        List<Case> returnCaseList = Database.query(query);
        
        return returnCaseList;
    }
    
    //----- Get Service Request details which custom where clause
    public static List<HexaBPM__Service_Request__c> getServiceRequestDetail(String whereClause) {
        String query = 'SELECT Id, Name,Origin__c , CreatedDate, RecordType.Name, RecordTypeName__c, HexaBPM__Customer__c, HexaBPM__External_Status_Name__c, HexaBPM__IsClosedStatus__c, CustomerComment__c, CommentsForCustomer__c, ';
        query += ' HexaBPM__Customer__r.Name, Unit__c, Unit__r.Name, SalesOrder__c, SalesOrder__r.Name, SRType__c, ChargeType__c, ChargeCollected__c, PaymentType__c, TransferSellingPrice__c, HexaBPM__Closed_Date_Time__c, ';
        query += ' BuyerName__c,Move_In_Date__c,Move_Out_Date__c , BuyerName__r.Name, BuyerName__r.FirstName, BuyerName__r.LastName, BuyerName__r.MobileCountryCode__pc, BuyerName__r.MobilePhone__pc, BuyerName__r.BillingStreet, BuyerName__r.BillingCity, BuyerName__r.BillingState, BuyerName__r.BillingPostalCode, BuyerName__r.BillingCountry, ';
        query += ' HandoverDetail__c, HandoverDetail__r.CustomerSnaggingAppointment__c, HandoverDetail__r.CustomerSnaggingAppointment__r.AppointmentId__c, HandoverDetail__r.CustomerDesnaggingAppointment__c, HandoverDetail__r.CustomerDesnaggingAppointment__r.AppointmentId__c, HandoverDetail__r.KeyHandoverAppointment__c, HandoverDetail__r.KeyHandoverAppointment__r.AppointmentId__c, ';
        
        query += ' HandoverDetail__r.KeyHandoverDate__c, HandoverDetail__r.HandoverCompletionDate__c, HandoverDetail__r.CustomerSnaggingAppointment__r.Date__c, HandoverDetail__r.CustomerSnaggingAppointment__r.Appointment_Slot_Time__c, HandoverDetail__r.CustomerSnaggingAppointment__r.Slot__c, HandoverDetail__r.CustomerDesnaggingAppointment__r.Date__c, HandoverDetail__r.CustomerDesnaggingAppointment__r.Appointment_Slot_Time__c, HandoverDetail__r.CustomerDesnaggingAppointment__r.Slot__c, HandoverDetail__r.KeyHandoverAppointment__r.Date__c, HandoverDetail__r.KeyHandoverAppointment__r.Appointment_Slot_Time__c, HandoverDetail__r.KeyHandoverAppointment__r.Slot__c, ';
        query += ' HandoverDetail__r.KAR__c, HandoverDetail__r.KAR__r.Name, HandoverDetail__r.KAR__r.Email, HandoverDetail__r.KAR__r.Phone, HandoverDetail__r.KAR__r.MobilePhone, HandoverDetail__r.HandoverAgent__c, HandoverDetail__r.HandoverAgent__r.Name, HandoverDetail__r.HandoverAgent__r.Email, HandoverDetail__r.HandoverAgent__r.Phone, HandoverDetail__r.HandoverAgent__r.MobilePhone, HandoverDetail__r.Home_Orientation_Appointment__c, HandoverDetail__r.Home_Orientation_Appointment__r.AppointmentNumber, HandoverDetail__r.Home_Orientation_Appointment__r.SchedStartTime,HandoverDetail__r.Home_Orientation_Appointment__r.SchedEndTime,HandoverDetail__r.Desnagging_Appointment__c,';
        query +=  'HandoverDetail__r.Desnagging_Appointment__r.AppointmentNumber, HandoverDetail__r.Desnagging_Appointment__r.SchedStartTime,HandoverDetail__r.Desnagging_Appointment__r.SchedEndTime,HandoverDetail__r.Key_Handover_Appointment__c, HandoverDetail__r.Key_Handover_Appointment__r.SchedStartTime, HandoverDetail__r.Key_Handover_Appointment__r.SchedEndTime  , ';
        query += ' HandoverDetail__r.Home_Orientation_Appointment_Resource__c,HandoverDetail__r.Desnagging_Appointment_Resource__c,HandoverDetail__r.Key_Handover_Appointment_Resource__c ,';
        query += ' (SELECT Id, Name, HexaBPM__Summary__c, HexaBPM__Closed_Date__c, PortalAppStatus__c FROM HexaBPM__Steps_SR__r ORDER BY CreatedDate ASC), ';
        query += ' (SELECT Id, Name, HexaBPM__Status__c, CreatedDate FROM HexaBPM__SR_Docs__r ORDER BY CreatedDate ASC) ';
        query += ' FROM HexaBPM__Service_Request__c ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        System.debug('query>>>' + query);
        List<HexaBPM__Service_Request__c> returnServiceRequestList = Database.query(query);
        
        return returnServiceRequestList;
    }
    
    //----- Get Sales Order from from associate Joint Owner's Account Ids
    public static List<Id> getSalesOrderIdsFromJointOwner(List<Id> accIds) {
        List<Id> soIds = new List<Id>();
        List<JointOwner__c> jointOwnerList = [SELECT Id, SalesOrder__c, Account__c, SharePercentage__c FROM JointOwner__c WHERE Account__c IN: accIds AND SharePercentage__c > 0];
        for (JointOwner__c jointOwner: jointOwnerList) {
            if(jointOwner.SalesOrder__c != null) {
            soIds.add(jointOwner.SalesOrder__c);
        }
        }
        return soIds;
    }
    
    //----- Get Sales Order from from associate Joint Owner's Account Ids
    public static List<Id> getSalesOrderIdsFromJointOwnerWithEmail(String email) {
        List<Id> soIds = new List<Id>();
        List<JointOwner__c> jointOwnerList = [SELECT Id, SalesOrder__c, Account__c, SharePercentage__c FROM JointOwner__c WHERE Account__r.PersonEmail =: email AND SharePercentage__c > 0];
        for (JointOwner__c jointOwner: jointOwnerList) {
            if(jointOwner.SalesOrder__c != null) {
            soIds.add(jointOwner.SalesOrder__c);
        }
        }
        return soIds;
    }
    
    //----- Get Receipt Acknowledgement details which custom where clause
    public static List<ReceiptAcknowledgement__c> getReceiptAcknowledgementDetail(String whereClause) {
        
        String query = 'SELECT Id, Name, CurrencyIsoCode, CustomerName__c, Amount__c, ProjectName__c, UnitNumber__c, Status__c, AuthenticationId__c, AuthenticationReferenceNumber__c, ';
        query += ' Account__r.PersonEmail, Account__r.PersonMobilePhone, Account__r.BillingStreet, Account__r.BillingCity, Account__r.BillingState, Account__r.BillingStateCode, Account__r.BillingPostalCode, Account__r.BillingCountry, Account__r.BillingCountryCode, ';
        query += ' Contact__r.Salutation, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email, Contact__r.MobilePhone, Contact__r.MobilePhone__c, Contact__r.MobileCountryCode__c, Contact__r.CountryOfResidence__c, Contact__r.Nationality__c, Contact__r.PassportNumber__c, Contact__r.PassportExpiryDate__c ';
        query += ' FROM ReceiptAcknowledgement__c ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        System.debug('query>>>' + query);
        List<ReceiptAcknowledgement__c> receiptAcknowledgementList = Database.query(query);
        
        return receiptAcknowledgementList;
    }
    
    //----- Get Project details which custom where clause
    public static List<Project__c> getProjectDetail(String whereClause) {
        Set<String> proFieldList = Schema.getGlobalDescribe().get('Project__c').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(proFieldList);
        String fields = string.join(strList, ',');
        
        String query = 'SELECT ' + fields + ' FROM Project__c ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        System.debug('***Project query***' + query);
        
        List<Project__c> Projects = Database.Query(query);
        
        return Projects;
    }
}