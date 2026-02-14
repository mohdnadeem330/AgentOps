public without sharing class ReceiptAcknowledgementController {

    // FIN-144 by Sai Kumar: Static flag to track when both ReceiptAcknowledgement and ReceiptAllocation are created in same transaction
    // This prevents duplicate web service calls when both records are created in the same transaction
    public static boolean isCreatingBothReceiptAndAllocation = false;
    
    /*
    Get Current user profileName 
    */

    @AuraEnabled(cacheable=false)
    public static string getCurrentUserProfileName(){
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        system.debug('ProfileName' + PROFILE[0].Name);
        Return PROFILE[0].Name;
    }
    
    
    /*
    * Get Installment & Sales Order Details by record Id
    */
    @AuraEnabled(cacheable=true)
    public static InstallmentLines__c getInstallmentDetails(Id installmentLineId){
        try {
            InstallmentLines__c installmentRec = [SELECT Id, SalesOrder__c,SalesOrder__r.Id,SalesOrder__r.Account__c,SalesOrder__r.Opportunity__c,SalesOrder__r.Contact__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c 
                FROM InstallmentLines__c WHERE Id=:installmentLineId];
            
            return installmentRec ; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
    * Get Installment & Sales Order Details by record Id
    */
    @AuraEnabled(cacheable=false)
    public static ReceiptAcknowledgement__c createReceiptAcknowledgementRecord(ReceiptAcknowledgement__c recieptRecord,Id parentRecord,List<Object> filesToInsert,String wrapperString, Boolean createThirdPartyCase){
        Savepoint savePoint = null ;
        try {
            ReceiptAcknowlegment receiptAcknowledgement =(ReceiptAcknowlegment)JSON.deserialize(wrapperString,ReceiptAcknowlegment.class);
            System.debug(recieptRecord+'**recieptRecord**'+receiptAcknowledgement);
            savePoint = Database.setSavepoint();
            List<Account> unidentifiedAccount = new List<Account>();
            unidentifiedAccount = [SELECT Id FROM Account WHERE Name =: Label.UnidentifiedCustomerName];
            if(unidentifiedAccount.size() > 0 && unidentifiedAccount[0].Id == recieptRecord.Account__c){
                recieptRecord.UnidentifiedReceiptFlag__c = true;
                recieptRecord.ChequeReceived__c = true;
//                recieptRecord.isUnidentified1__c = true;
            }
            /*Boolean createAllocation = ((recieptRecord.PaymentType__c != 'Wire Transfer' || getCurrentUserProfileName() == CONSTANTS.FINANCE_PROFILE) && !(unidentifiedAccount.size() > 0 && unidentifiedAccount[0].Id == recieptRecord.Account__c));
            if( !createAllocation ){
                    recieptRecord.IsCreatedFromLink__c = false;
            }*/
            //Added by Sai Kumar as part of DFC-4 story
            if(receiptAcknowledgement.isInwardRemittanceForUnidentified == true){
                List<SalesOrder__c> unidentifiedSalesOrders = [
                    SELECT Id 
                    FROM SalesOrder__c 
                    WHERE Account__r.Name = :Label.UnidentifiedCustomerName
                    LIMIT 1
                ];
                if(!unidentifiedSalesOrders.isEmpty()) {
                    recieptRecord.SalesOrder__c = unidentifiedSalesOrders[0].Id;
                }
            }
            //Added by Sai Kumar as part FIN-81  of FAB Enhancements
            if(receiptAcknowledgement.isInwardRemittance == true){
                recieptRecord.ChequeReceived__c = true;
            }
            if(createThirdPartyCase){                
                Id thirdPartyPaymentNOCId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(System.Label.Third_Party_Payment_NOC_Record_Type).getRecordTypeId();
                List<Unit__c> virAccUnitList = new List<Unit__c>();
				Case cs = new Case();
                if(recieptRecord.Virtual_Account_Name__c != ''){
                    if(recieptRecord.UnidentifiedReceiptAccountType__c == System.Label.Escrow_Account_Type){
                        virAccUnitList = [SELECT Id, VirtualAccountNumber__c, VirtualAccountNumber__r.VirtualAccountName__c, VirtualAccountNumber__r.VirtualAccountNumber__c, RelatedSalesOrder__c, RelatedSalesOrder__r.Account__c FROM Unit__c WHERE VirtualAccountNumber__r.VirtualAccountNumber__c = :recieptRecord.Virtual_Account_Name__c OR VirtualAccountNumber__r.VirtualAccountName__c = :recieptRecord.Virtual_Account_Name__c LIMIT 1];               
                    } else if(recieptRecord.UnidentifiedReceiptAccountType__c == System.Label.Corporate_Account_Type){
                        virAccUnitList = [SELECT Id, VirtualAccountNumber__c, CorporateVirtualAccountNumber__r.VirtualAccountName__c, CorporateVirtualAccountNumber__r.VirtualAccountNumber__c, RelatedSalesOrder__c, RelatedSalesOrder__r.Account__c FROM Unit__c WHERE CorporateVirtualAccountNumber__r.VirtualAccountNumber__c = :recieptRecord.Virtual_Account_Name__c OR CorporateVirtualAccountNumber__r.VirtualAccountName__c = :recieptRecord.Virtual_Account_Name__c LIMIT 1];
                    }
                    if(!virAccUnitList.isEmpty()){							
                        cs.Unit__c = virAccUnitList[0].Id;
					}
                } 
				if((virAccUnitList.isEmpty() ||  recieptRecord.Virtual_Account_Name__c == '') && recieptRecord.SalesOrder__c != null) {
                    List<SalesOrder__c> salesorderList = [SELECT Id, Account__c, Unit__c FROM SalesOrder__c WHERE Id = :recieptRecord.SalesOrder__c LIMIT 1];				
                    
                    if(!salesorderList.isEmpty()){
                     cs.Unit__c = salesorderList[0].Unit__c != null ? salesorderList[0].Unit__c : null;   
				   }
                }
				cs.RecordTypeId = thirdPartyPaymentNOCId;
                cs.CaseComments__c = recieptRecord.Remarks__c != null ? recieptRecord.Remarks__c : '';
                insert cs;
                recieptRecord.Case__c = cs.Id;
            }
            
            // FIN-75: Sai Kumar - Bulk Installment Allocation changes
            // Set the bulk installment allocation flag if bulk installments or charges were selected
            // This helps identify receipt acknowledgements created through the bulk allocation process
            if ((receiptAcknowledgement.selectedInstallmentIds != null && !receiptAcknowledgement.selectedInstallmentIds.isEmpty()) ||
                (receiptAcknowledgement.selectedChargeIds != null && !receiptAcknowledgement.selectedChargeIds.isEmpty())) {
                recieptRecord.Bulk_Installment_Allocation__c = true;
                if(receiptAcknowledgement.selectedChargeIds != null && !receiptAcknowledgement.selectedChargeIds.isEmpty()){
                    recieptRecord.StopCallout__c = true;
                }
            }

            // FIN-144 by Sai Kumar: Check if we will be creating both ReceiptAcknowledgement and ReceiptAllocation in this transaction
            // Set the flag to prevent duplicate web service calls when both records are created in same transaction
            boolean willCreateAllocation = false;
            Decimal amountPending = 0;
            
            // Check the same conditions that determine if ReceiptAllocation will be created
            if ((recieptRecord.PaymentType__c != 'Wire Transfer' || getCurrentUserProfileName() == CONSTANTS.FINANCE_PROFILE) && 
                !(unidentifiedAccount.size() > 0 && unidentifiedAccount[0].Id == recieptRecord.Account__c) && 
                parentRecord != null) {
                
                // Calculate amountPending to check if it's greater than 0
                if(parentRecord.getSObjectType() == InstallmentLines__c.SObjectType){
                    amountPending = receiptAcknowledgement.installmentRec.PendingAmount__c;
                } else {
                    amountPending = receiptAcknowledgement.salesOrderOtherChargesRec.PendingAmount__c;
                }
                
                // Only set flag to true if amountPending > 0 (which means ReceiptAllocation will actually be created)
                if(amountPending > 0) {
                    willCreateAllocation = true;
                }
            }
            
            // FIN-144 by Sai Kumar: Set the flag to prevent duplicate web service calls
            if(willCreateAllocation) {
                isCreatingBothReceiptAndAllocation = true;
                System.debug('FIN-144: Setting isCreatingBothReceiptAndAllocation = true - both ReceiptAcknowledgement and ReceiptAllocation will be created in same transaction');
            }
            
            insert recieptRecord ; 
            //Added by Sai Kumar as part of DFC-4 story
            if (recieptRecord.Inward_Remittance__c != null) {
                Inward_Remittance__c inwardRemittance = new Inward_Remittance__c(
                    Id = recieptRecord.Inward_Remittance__c,
                    Status__c = 'Processed',
                    Receipt_Acknowledgement__c = recieptRecord.Id
                );
                update inwardRemittance;
            }
            
            //--- Create Receipt Allocation
            System.debug(amountPending+'**Reciept Amount**'+recieptRecord.Amount__c);
            //Receipt allocation not required if paymentMode if Wire Transfer. 
            //Added by sujesh on 03/09/22
            //if(createAllocation){
            if( (recieptRecord.PaymentType__c != 'Wire Transfer' || getCurrentUserProfileName() == CONSTANTS.FINANCE_PROFILE) && !(unidentifiedAccount.size() > 0 && unidentifiedAccount[0].Id == recieptRecord.Account__c)  ){
                if(parentRecord !=null){ 
                    // FIN-75: Sai Kumar - Bulk Installment Allocation changes
                    List<ReceiptAllocation__c> allocationsToInsert = new List<ReceiptAllocation__c>();
                    ReceiptAllocation__c receiptAllocation = new ReceiptAllocation__c();
                    if(parentRecord.getSObjectType() == InstallmentLines__c.SObjectType){
                        receiptAllocation.TypeOfInvoice__c = Constants.INVOICE_TYPE_INSTALLMENT ;
                        receiptAllocation.InstallmentLine__c = parentRecord ;
                        amountPending = receiptAcknowledgement.installmentRec.PendingAmount__c ;
                    }
                    else{
                        receiptAllocation.TypeOfInvoice__c = receiptAcknowledgement.salesOrderOtherChargesRec.TypeOfCharge__c ; //Constants.INVOICE_TYPE_ADM ;
                        receiptAllocation.SalesOrderOtherCharges__c = parentRecord ;
                        amountPending = receiptAcknowledgement.salesOrderOtherChargesRec.PendingAmount__c ;
                    }
                    System.debug(amountPending+'**Pending Amount**');
                    if(amountPending >0){
                        receiptAllocation.ReceiptAcknowledgement__c = recieptRecord.Id ;
                        if (receiptAcknowledgement.selectedInstallmentIds != null && !receiptAcknowledgement.selectedInstallmentIds.isEmpty()) {
                            receiptAllocation.AmountApplied__c = amountPending;
                        } else {
                        receiptAllocation.AmountApplied__c = (recieptRecord.Amount__c > amountPending ? amountPending : recieptRecord.Amount__c);
                        }
                        receiptAllocation.CurrencyIsoCode = recieptRecord.CurrencyIsoCode ;
                        receiptAllocation.DateOfApplication__c = Date.today();
                        receiptAllocation.Account__c = recieptRecord.Account__c ;
                        receiptAllocation.SalesOrder__c = recieptRecord.SalesOrder__c ;
                        System.debug('**recieptRecord**'+recieptRecord);
                        // FIN-75: Sai Kumar - Bulk Installment Allocation changes
                        allocationsToInsert.add(receiptAllocation);

                        if (receiptAcknowledgement.selectedInstallmentIds != null && !receiptAcknowledgement.selectedInstallmentIds.isEmpty()) {
                            // Process selected installments
                            List<InstallmentLines__c> selectedInstallments = [
                                SELECT Id, PendingAmount__c
                                FROM InstallmentLines__c
                                WHERE Id IN :receiptAcknowledgement.selectedInstallmentIds
                            ];

                            for (InstallmentLines__c installment : selectedInstallments) {
                                allocationsToInsert.add(new ReceiptAllocation__c(
                                    ReceiptAcknowledgement__c = recieptRecord.Id,
                                    InstallmentLine__c = installment.Id,
                                    AmountApplied__c = installment.PendingAmount__c,
                                    CurrencyIsoCode = recieptRecord.CurrencyIsoCode,
                                    DateOfApplication__c = Date.today(),
                                    Account__c = recieptRecord.Account__c,
                                    SalesOrder__c = recieptRecord.SalesOrder__c,
                                    TypeOfInvoice__c = Constants.INVOICE_TYPE_INSTALLMENT
                                ));
                            }
                        }
                        if (receiptAcknowledgement.selectedChargeIds != null && !receiptAcknowledgement.selectedChargeIds.isEmpty()) {
                            // Process selected charges
                            List<SalesOrderOtherCharges__c> selectedCharges = [
                                SELECT Id, PendingAmount__c, TypeOfCharge__c 
                                FROM SalesOrderOtherCharges__c
                                WHERE Id IN :receiptAcknowledgement.selectedChargeIds
                            ];

                            for (SalesOrderOtherCharges__c charge : selectedCharges) {
                                allocationsToInsert.add(new ReceiptAllocation__c(
                                    ReceiptAcknowledgement__c = recieptRecord.Id,
                                    SalesOrderOtherCharges__c = charge.Id,
                                    AmountApplied__c = charge.PendingAmount__c,
                                    CurrencyIsoCode = recieptRecord.CurrencyIsoCode,
                                    DateOfApplication__c = Date.today(),
                                    Account__c = recieptRecord.Account__c,
                                    SalesOrder__c = recieptRecord.SalesOrder__c,
                                    TypeOfInvoice__c = charge.TypeOfCharge__c
                                ));
                            }
                        }

                        if (!allocationsToInsert.isEmpty()) {
                            insert allocationsToInsert;
                        }
                    }
                }
            }
            
            if(filesToInsert!=null && filesToInsert.size()>0){
                //----- Insert all the files
                List<ContentVersion> paymentFiles = new List<ContentVersion>();
                for (Object file : filesToInsert) {
                    FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
                    ContentVersion contentVersionRec = new ContentVersion();
                    contentVersionRec.PathOnClient = fileData.Title;
                    contentVersionRec.Title = fileData.Title;
                    contentVersionRec.VersionData = fileData.FileContent;
                    paymentFiles.add(contentVersionRec);
                }
                System.debug('**Payment Files**'+paymentFiles);
                list<Database.saveResult> res = Database.insert(paymentFiles);
                createContentDocumentLinks(paymentFiles,recieptRecord.Id);
            }
            
            return recieptRecord ; 
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Error: ' + e.getStackTraceString());
            Database.rollback(savePoint);
            throw new AuraHandledException(e.getMessage());
        } finally {
            // FIN-144 by Sai Kumar: Always reset the flag to ensure it doesn't affect subsequent transactions
            isCreatingBothReceiptAndAllocation = false;
            System.debug('FIN-144: Reset isCreatingBothReceiptAndAllocation = false');
        }
    }

    @AuraEnabled(cacheable=false)
    public static ReceiptAcknowledgement__c createReceiptFromSR(ReceiptAcknowledgement__c recieptRecord, List<Object> filesToInsert) {

         /*String serviceRquestId = recieptRecord.ServiceRequest__c;
        
        HexaBPM__Service_Request__c serviceRquestRecord = [Select Id, RecordType.Name, ChargeCollected__c, SalesOrder__c, HexaBPM__Customer__c   from HexaBPM__Service_Request__c where Id =: serviceRquestId];

       if(serviceRquestRecord.RecordType.Name == 'Internal Mortgage Registration')
        {System.debug('Internal Mortgage Registration');
            SalesOrderOtherCharges__c soOtherCharges = new SalesOrderOtherCharges__c();
            soOtherCharges.Amount__c = serviceRquestRecord.ChargeCollected__c;
            soOtherCharges.SalesOrder__c = serviceRquestRecord.SalesOrder__c;
            soOtherCharges.TypeOfCharge__c = 'Service Charge';
            soOtherCharges.AmountReceived__c = recieptRecord.Amount__c;
            soOtherCharges.Account__c = serviceRquestRecord.HexaBPM__Customer__c;
            insert soOtherCharges;
        }// move to sr utility*/

        insert recieptRecord;
        if(filesToInsert!=null && filesToInsert.size()>0){
            //----- Insert all the files
            List<ContentVersion> paymentFiles = new List<ContentVersion>();
            for (Object file : filesToInsert) {
                FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
                ContentVersion contentVersionRec = new ContentVersion();
                contentVersionRec.PathOnClient = fileData.Title;
                contentVersionRec.Title = fileData.Title;
                contentVersionRec.VersionData = fileData.FileContent;
                paymentFiles.add(contentVersionRec);
            }
            System.debug('**Payment Files**'+paymentFiles);
            list<Database.saveResult> res = Database.insert(paymentFiles);
            createContentDocumentLinks(paymentFiles,recieptRecord.Id);
        }
        
        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c();
        //Monika: for Rebate request
        HexaBPM__Service_Request__c srRebate = [Select id,ReceiptAcknowledgement__c,SRType__c from HexaBPM__Service_Request__c where ID =:recieptRecord.ServiceRequest__c];
        if(srRebate.SRType__c == 'Rebate Request')
        {
            sr.ReceiptAcknowledgement__c = recieptRecord.Id;
        }
        sr.Id = recieptRecord.ServiceRequest__c;
        sr.IsChargeReceiptCreated__c = true;
        update sr;

        return recieptRecord;
    }

    @AuraEnabled(cacheable=false) //3309
    public static ReceiptAcknowledgement__c updatedReceiptAcknowledgementRecord(ReceiptAcknowledgement__c recieptRecord) {
        try {
            if (recieptRecord.Id != null) {
                update recieptRecord;
                return recieptRecord;
            } else {
                throw new AuraHandledException('Received an invalid ReceiptAcknowledgement__c record.');
            }
        } catch (Exception e) {
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    }    

    public class FileInfo {
        public String Title;
        public Blob FileContent;
    }

  
    public static void createContentDocumentLinks(List<ContentVersion> paymentFiles, Id recordId) {
        System.debug(recordId+'**Payment Files**'+paymentFiles);
        if (paymentFiles != null && recordId != null) {
            List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
            Set<Id> contentVersionIds = new Set<Id>();
            for(ContentVersion contentVersionRec : paymentFiles){
                if (contentVersionRec.Id != null)
                    contentVersionIds.add(contentVersionRec.Id);
            }

            List<ContentVersion> uploadedPaymentFiles = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id IN: contentVersionIds];
            Map<Id,Id> contentVersionDocumentMap = new Map<Id,Id>();
            for(ContentVersion contentVersionRec : uploadedPaymentFiles){
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentVersionRec.ContentDocumentId;
                cdl.LinkedEntityId = recordId;
                cdl.Visibility = 'InternalUsers';
                contentDocumentLinkList.add(cdl);
            }
            System.debug(contentDocumentLinkList.size()+'**Payment Files**'+contentDocumentLinkList);
            if(contentDocumentLinkList!=null && contentDocumentLinkList.size()>0)
                insert contentDocumentLinkList ;
        }
    }


    public class ReceiptAcknowlegment{
        @AuraEnabled
        public Decimal amount ;
        @AuraEnabled
        public Boolean allowCrypto ;
        @AuraEnabled
        public SalesOrder__c salesOrderRecord ;
        @AuraEnabled
        public HexaBPM__Service_Request__c serviceRequestRecord;
        @AuraEnabled
        public Date paymentDate ;
        @AuraEnabled
        public String objectName ;
        @AuraEnabled
        public Id salesOrderId ;
        @AuraEnabled
        public List<Account> relatedAccounts ;
        @AuraEnabled
        public InstallmentLines__c installmentRec ;
        @AuraEnabled 
        public Inward_Remittance__c inwardRemittanceRec ; //For inward remittance record
        @AuraEnabled
        public SalesOrderOtherCharges__c salesOrderOtherChargesRec ;
        @AuraEnabled
        public ReceiptAcknowledgement__c ReceiptAcknowledgementRec ;//ASF-3309
        //Harsh@Aldar -- Manager's Check Addition -- need resale Opp for updated redirection
        @AuraEnabled
        public Id resaleOpportunityId;
        //Monika -- Rebate Request
        @AuraEnabled
        public Id AccountId;

        @AuraEnabled
        public String SRType;

        //Added by Sai Kumar as part of DFC-4 story
        @AuraEnabled
        public Boolean isInwardRemittance;
        
        //Added by Sai Kumar as part of DFC-4 story
        @AuraEnabled
        public Boolean isInwardRemittanceForUnidentified;
        // FIN-75: Sai Kumar - Bulk Installment Allocation changes
        @AuraEnabled
        public List<InstallmentLines__c> otherInstallments;
        @AuraEnabled
        public List<SalesOrderOtherCharges__c> otherCharges;
        @AuraEnabled
        public List<Id> selectedInstallmentIds;
        @AuraEnabled
        public List<Id> selectedChargeIds;
       
        public ReceiptAcknowlegment(Boolean allowCrypto, Decimal amount,SalesOrder__c salesOrderRecord,Date paymentDate,String objectName){
            this.allowCrypto = allowCrypto;
            this.amount = amount ;
            this.salesOrderRecord  = salesOrderRecord ;
            this.paymentDate = paymentDate ;
            this.objectName = objectName ;
            this.salesOrderId = salesOrderRecord.Id ;
            this.relatedAccounts = new List<Account>();
            this.installmentRec = new InstallmentLines__c();
            this.salesOrderOtherChargesRec = new SalesOrderOtherCharges__c();
            this.serviceRequestRecord = new HexaBPM__Service_Request__c();
        }
        //Harsh@Aldar -- Manager's Check Addition -- need resale Opp for updated redirection
        public ReceiptAcknowlegment(Decimal amount,SalesOrder__c salesOrderRecord,Date paymentDate,String objectName, Id resaleOpportunityId){
            this.amount = amount ;
            this.salesOrderRecord  = salesOrderRecord ;
            this.paymentDate = paymentDate ;
            this.objectName = objectName ;
            this.salesOrderId = salesOrderRecord.Id ;
            this.relatedAccounts = new List<Account>();
            this.installmentRec = new InstallmentLines__c();
            this.salesOrderOtherChargesRec = new SalesOrderOtherCharges__c();
            this.serviceRequestRecord = new HexaBPM__Service_Request__c();
            this.resaleOpportunityId = resaleOpportunityId;
        }
        //Monika: For Rebate Request

        public ReceiptAcknowlegment(Decimal amount,Date paymentDate,String objectName, Id AccountId, SalesOrder__c salesOrderRecord){
            this.amount = amount ;
            this.paymentDate = paymentDate ;
            this.objectName = objectName ;
            this.serviceRequestRecord = new HexaBPM__Service_Request__c();
            this.AccountId = AccountId;
            this.SRType = 'Rebate Request';
            this.salesOrderId = salesOrderRecord.Id ;
            this.salesOrderRecord  = salesOrderRecord ;
        }
        
        //Added by Sai Kumar as part of DFC-4 story
        public ReceiptAcknowlegment(Decimal amount, Date paymentDate, String objectName, SalesOrder__c salesOrderRecord, Inward_Remittance__c inwardRemittanceRec) {
            this.amount = amount;
            this.paymentDate = paymentDate;
            this.objectName = objectName;
            this.inwardRemittanceRec = inwardRemittanceRec;
            this.isInwardRemittance = true;
            this.salesOrderRecord  = salesOrderRecord ;
            this.salesOrderId = salesOrderRecord.Id ;
            this.relatedAccounts = new List<Account>();
            this.installmentRec = new InstallmentLines__c();
            this.salesOrderOtherChargesRec = new SalesOrderOtherCharges__c();
            this.serviceRequestRecord = new HexaBPM__Service_Request__c();
        }
        public ReceiptAcknowlegment(){

        }
        
    }

    /*
    * Get Installment & Sales Order Details by record Id
    */
    @AuraEnabled(cacheable=true)
    public static ReceiptAcknowlegment initialiseReceiptAcknowlegment(Id recordId){
        try {
            ReceiptAcknowlegment parentRecord ;

            if(recordId !=null){
                if(recordId.getSObjectType() == InstallmentLines__c.SObjectType){
                    InstallmentLines__c installmentLineRec = [SELECT Id, SalesOrder__r.Is_Digital_Sales__c, SalesOrder__r.SalesManager__c,SalesOrder__r.Account__r.PersonEmail,SalesOrder__r.SalesManager__r.Email, SalesOrder__c,SalesOrder__r.Id,SalesOrder__r.ComplianceStatus__c,SalesOrder__r.Account__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,SalesOrder__r.Contact__c,InstallmentNumber__c,InstallmentAmount__c,InstallmentDate__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,AmountReceived__c,PendingAmount__c, SalesOrder__r.Account__r.Name, SalesOrder__r.Unit__r.Project__c, SalesOrder__r.Unit__r.BuildingSectionName__c,PaymentInstallments__r.AllowCryptoPayment__c FROM InstallmentLines__c WHERE Id=:recordId];
                    parentRecord = new ReceiptAcknowlegment(installmentLineRec.PaymentInstallments__r.AllowCryptoPayment__c,installmentLineRec.PendingAmount__c,installmentLineRec.SalesOrder__r,installmentLineRec.InstallmentDate__c,'InstallmentLines__r');
                    parentRecord.installmentRec = installmentLineRec ;

                    // FIN-147: For now, we are not showing installments; we will only show the selected order charges.
                    // FIN-75: Sai Kumar - Bulk Installment Allocation changes
                    /*List<InstallmentLines__c> otherInstallments = [
                        SELECT Id, InstallmentNumber__c, InstallmentAmount__c, CurrencyIsoCode, PendingAmount__c, InstallmentDate__c
                        FROM InstallmentLines__c
                        WHERE SalesOrder__c = :installmentLineRec.SalesOrder__c
                        AND PendingAmount__c > 0
                        AND Id != :recordId
                        AND InstallmentDate__c <= :Date.today()
                        ORDER BY InstallmentNumber__c ASC
                    ];
                    
                    parentRecord.otherInstallments = otherInstallments;*/
                    //please dont uncomment above lines

                    // Get other charges
                    List<SalesOrderOtherCharges__c> otherCharges = [
                        SELECT Id, Amount__c, PendingAmount__c, TypeOfCharge__c, Account__c
                        FROM SalesOrderOtherCharges__c
                        WHERE SalesOrder__c = :installmentLineRec.SalesOrder__c
                        AND PendingAmount__c > 0
                        AND TypeOfCharge__c IN ('ADM Fee', 'DLD', 'RAK Municipality Fee')
                        AND Account__c = :installmentLineRec.SalesOrder__r.Account__c
                    ];
                    parentRecord.otherCharges = otherCharges;
                }
                else if(recordId.getSObjectType() == SalesOrderOtherCharges__c.SObjectType){
                    SalesOrderOtherCharges__c otherChargesRec = [SELECT Id,Account__c, Opportunity__c, SalesOrder__c,SalesOrder__r.Id,SalesOrder__r.ComplianceStatus__c,SalesOrder__r.Account__c,SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,Name,TypeOfCharge__c,Amount__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,PendingAmount__c, SalesOrder__r.Account__r.Name, SalesOrder__r.Unit__r.Project__c, SalesOrder__r.Unit__r.BuildingSectionName__c, ChargedFromResaleOpp__c,ServiceRequest__c FROM SalesOrderOtherCharges__c WHERE Id=:recordId];
                    if(!otherChargesRec.ChargedFromResaleOpp__c){
                        parentRecord = new ReceiptAcknowlegment(false, otherChargesRec.PendingAmount__c,otherChargesRec.SalesOrder__r,null,'SalesOrdersOtherCharges__r');
                        parentRecord.salesOrderOtherChargesRec = otherChargesRec ;
                    }else{
                        //Harsh@Aldar ----- Resale Manager Cheque -- Take oppId out
                        if(otherChargesRec.Opportunity__c == null){
                            parentRecord = new ReceiptAcknowlegment(false, otherChargesRec.PendingAmount__c,otherChargesRec.SalesOrder__r,null,'SalesOrdersOtherCharges__r');
                            parentRecord.salesOrderOtherChargesRec = otherChargesRec ;
                        }else{
                            parentRecord = new ReceiptAcknowlegment(otherChargesRec.PendingAmount__c,otherChargesRec.SalesOrder__r,null,'Sales_Orders_Other_ChargesOpportunity__r', otherChargesRec.Opportunity__c);
                            parentRecord.salesOrderOtherChargesRec = otherChargesRec ;
                        }
                    }
                }
                else if(recordId.getSObjectType() == HexaBPM__Service_Request__c.SObjectType) {
                    /*SSR-269*/HexaBPM__Service_Request__c serviceRequest = [SELECT Id, Outstanding_Amount_to_be_Paid__c, Name, SRType__c, RecordTypeId, RecordType.Name,SalesOrder__c, SalesOrder__r.ComplianceStatus__c, SalesOrder__r.Opportunity__c, SalesOrder__r.UnitNumber__c, SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name, ChargeCollected__c, BuyerName__c, BuyerName__r.Name, BuyerName__r.IsPersonAccount, BuyerName__r.Email__c, BuyerName__r.PersonEmail, BuyerEmail__c, HexaBPM__Customer__c, HexaBPM__Customer__r.Name,HexaBPM__Customer__r.IsPersonAccount,  HexaBPM__Customer__r.Email__c, HexaBPM__Customer__r.PersonEmail, HexaBPM__Email__c, SalesOrder__r.Unit__r.Project__c, SalesOrder__r.Unit__r.BuildingSectionName__c FROM HexaBPM__Service_Request__c WHERE Id=:recordId];
                   //Monika: Rebate Request Changes
                    if(serviceRequest.SRType__c == 'Rebate request')
                    {
                        Decimal MaxVal = 0.0;
                        SRUnitSelected__c sUnit;
                        List<SRUnitSelected__c> selectedUnitList = [select Id,Name,ServiceRequest__c,OutstandingAmount__c,SalesOrder__c, SalesOrder__r.Opportunity__c, SalesOrder__r.Id, Unit__c,Rebate_Percentage__c,Previous_Rebate_Offered__c from SRUnitSelected__c  where ServiceRequest__c=:serviceRequest.id]; 
                    
                      if(!selectedUnitList.isEmpty()) 
                      {
                        for(SRUnitSelected__c unit: selectedUnitList)
                    {
                        if(unit.OutstandingAmount__c > MaxVal)
                        {
                            sUnit = unit;
                        }
                    }
                    parentRecord = new ReceiptAcknowlegment(serviceRequest.Outstanding_Amount_to_be_Paid__c, null,'HexaBPM__Service_Request__c', serviceRequest.HexaBPM__Customer__c, sUnit.SalesOrder__r);
                    parentRecord.serviceRequestRecord = serviceRequest;
                      }
                    }
                    else{                                    
                    parentRecord = new ReceiptAcknowlegment(false, serviceRequest.ChargeCollected__c,serviceRequest.SalesOrder__r,null,'HexaBPM__Service_Request__c');
                    parentRecord.serviceRequestRecord = serviceRequest;
                    }
                }                               
                else if(recordId.getSObjectType() == ReceiptAcknowledgement__c.SObjectType){ //Start ASF-3309
                    ReceiptAcknowledgement__c ReceiptAcknowledgementRec = [SELECT Id,Account__c, Opportunity__c,SalesOrder__c, SalesOrder__r.Id, SalesOrder__r.ComplianceStatus__c, SalesOrder__r.Account__c, SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,   Amount__c,SalesOrder__r.Name,Name,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c, SalesOrder__r.Account__r.Name, SalesOrder__r.Unit__r.Project__c, SalesOrder__r.Unit__r.BuildingSectionName__c,ServiceRequest__c FROM ReceiptAcknowledgement__c WHERE Id=:recordId];
                    parentRecord = new ReceiptAcknowlegment(false,ReceiptAcknowledgementRec.Amount__c,ReceiptAcknowledgementRec.SalesOrder__r,null,'ReceiptAcknowledgement__c');
                    parentRecord.ReceiptAcknowledgementRec = ReceiptAcknowledgementRec ;
                }
                //Added by Sai Kumar as part of DFC-4 story
                else if(recordId.getSObjectType() == Inward_Remittance__c.SObjectType) {
                    system.debug('inside inward---------');
                    Inward_Remittance__c remittance = [SELECT Id, Amount__c, Sales_Order__c, Sales_Order__r.Id, Sales_Order__r.ComplianceStatus__c, 
                                                     Sales_Order__r.Account__c, Sales_Order__r.Contact__c, Sales_Order__r.Opportunity__c, 
                                                     Sales_Order__r.OpportunityNumber__c, Sales_Order__r.Name, Sales_Order__r.UnitNumber__c, 
                                                     Sales_Order__r.AccountName__c, Sales_Order__r.Account__r.Name, Sales_Order__r.Unit__r.Project__c, 
                                                     Sales_Order__r.Unit__r.BuildingSectionName__c, Request_DateTime__c, Payment_Details__c, Transaction_Reference__c
                                                     FROM Inward_Remittance__c WHERE Id=:recordId];
                    
                    parentRecord = new ReceiptAcknowlegment(remittance.Amount__c, Date.valueOf(remittance.Request_DateTime__c), 'Inward_Remittance__c', remittance.Sales_Order__r, remittance);
                }
                
                if(parentRecord!=null && parentRecord.ReceiptAcknowledgementRec.SalesOrder__r !=null && recordId.getSObjectType() == ReceiptAcknowledgement__c.SObjectType){
                    parentRecord.relatedAccounts.addALL(AccountService.getAllRelatedAccountsForSalesOrderId(parentRecord.ReceiptAcknowledgementRec.SalesOrder__c));
                } //End ASF-3309

                if(parentRecord!=null && parentRecord.salesOrderRecord !=null && recordId.getSObjectType() != HexaBPM__Service_Request__c.SObjectType){
                    //Start ASF-3309
                    parentRecord.relatedAccounts.addALL(AccountService.getAllRelatedAccountsForSalesOrderId(parentRecord.salesOrderRecord.Id));
                    /*(for(AccountRelationship__c acctRelationship : AccountService.getRelatedAccountsForAccountId(parentRecord.salesOrderRecord.Account__c)){
                        parentRecord.relatedAccounts.add(acctRelationship.RelatedAccount__r);
                    }*/
                    //End ASF-3309 
                }
            }          
            return parentRecord ; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
  
     //ASF-3419 - add
    @AuraEnabled(cacheable=true)
    public static List<Corporate_Account__mdt> getCorporateAccounts() {
        return [SELECT Account_Number__c FROM Corporate_Account__mdt];
    }

    //SELECT ConversionRate,Id,IsActive,IsCorporate,IsoCode FROM CurrencyType
    //ASF-3290 - Building dropdown for escrow account selection
    @AuraEnabled
    public static List<BuildingSection__c> getBuildingsByProject(String projectId) {
        try {
            return [
                SELECT Id, Name 
                FROM BuildingSection__c 
                WHERE Project__c = :projectId
                ORDER BY Name ASC
            ];
        } catch(Exception e) {
            throw new AuraHandledException('Error retrieving buildings: ' + e.getMessage());
        }
    }
    //ASF-3290 - Building dropdown for escrow account selection 
    @AuraEnabled 
    public static String getBuildingEscrowAccount(String buildingId) {
        try {
            BuildingSection__c building = [
                SELECT Id, AccountNumberEscrow__c 
                FROM BuildingSection__c 
                WHERE Id = :buildingId 
                LIMIT 1
            ];
            return building.AccountNumberEscrow__c;
        } catch(Exception e) {
            throw new AuraHandledException('Error retrieving building escrow account: ' + e.getMessage());
        }
    }
}