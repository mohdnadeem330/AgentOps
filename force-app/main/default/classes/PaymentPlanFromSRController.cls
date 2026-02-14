/*
* This Class used with Payment Plan Change SR.
* The class is without sharing to make the booking memo available for all D%T users.
*/
public without sharing class PaymentPlanFromSRController{
    
    /*
    * get Service Request details
    */
    @AuraEnabled(cacheable=true)
    public static HexaBPM__Service_Request__c getServiceRequestDetails(string recordId){
        return [select Id, Name, SalesOrder__c, SalesOrder__r.WealthDiscount__c, SalesOrder__r.CorporateDiscount__c,SalesOrder__r.PaymentPlanDiscount__c,SalesOrder__r.BulkDiscount__c, SalesOrder__r.SellingPrice__c, SalesOrder__r.NetAmount__c, SalesOrder__r.Opportunity__c, ProposalPaymentPlan__c, SalesOrder__r.Offer__c, SalesOrder__r.PaymentPlan__c, SalesOrder__r.Discount__c, SalesOrder__r.OtherRebateAmount__c, Unit__c, HexaBPM__External_Status_Name__c, PaymentPlan__c, PaymentPlan__r.Name
        , Unit__r.BuildingSectionName__c, NewNetAmount__c FROM HexaBPM__Service_Request__c WHERE Id = :recordId];
    }

    /*
    * get Installments related to SO
    */
    @AuraEnabled(cacheable=true)
    public static list<InstallmentLines__c> getInstallmentLines(string salesorderId){
        
        list<InstallmentLines__c>  installmentLinesList = [Select Id, StatusIndicator__c, InstallmentNumber__c, InstallmentPercentage__c, InstallmentDate__c, InstallmentAmount__c, OutstandingAmount__c, PaymentInstallments__c,Description__c From InstallmentLines__c Where SalesOrder__c =: salesorderId Order By InstallmentNumber__c asc];

        return installmentLinesList;
    }

    /*
    * get Installments related to SO without Handover Installment
    */
    @AuraEnabled(cacheable=true)
    public static list<InstallmentLines__c> getInstallmentLineswithoutHandover(string salesorderId){
        
        list<InstallmentLines__c>  installmentLinesList = [Select Id, StatusIndicator__c, InstallmentNumber__c, InstallmentPercentage__c, InstallmentDate__c, InstallmentAmount__c, OutstandingAmount__c, PaymentInstallments__c,Description__c From InstallmentLines__c Where SalesOrder__c =: salesorderId  Order By InstallmentNumber__c asc];
        Integer installmentsCount = installmentLinesList.size();
        List<InstallmentLines__c> ilwithouthandover = new List<InstallmentLines__c>();
        for(InstallmentLines__c il: installmentLinesList){
            Boolean isLastInstallment = (installmentsCount == il.InstallmentNumber__c ? true : false) ;
            if(!isLastInstallment){
                ilwithouthandover.add(il);
            }
        }
        

        return ilwithouthandover;
    }

    /*
    * to create Booking Memo and Payment Installments for the new proposal payment plan
    */
    @AuraEnabled(cacheable=false)
    public static void createBookingMemo(HexaBPM__Service_Request__c srRecord, String specialNote, String discountPercentage, String rebatePercentage, List<Map<String,String>> installmentList, String paymentPlan, String newNetSellingPrice, String paymentPlanId) { 

        System.debug(srRecord);
        System.debug(installmentList);
        System.debug('**installmentList:'+installmentList.size());
        for (Map<String,String> mmm : installmentList) {
            System.debug('**MAP**:'+mmm);
        }

        BookingMemo__c bookingMemoRecord = new BookingMemo__c();
        bookingMemoRecord.MemoType__c = Constants.MEMO_TYPE_NEW_PAYMENT_PLAN;
        bookingMemoRecord.ApprovalStatus__c = Constants.APPROVAL_STATUS_APPROVAL_PENDING;
        bookingMemoRecord.RelatedOpportunity__c = srRecord.SalesOrder__r.Opportunity__c;
        bookingMemoRecord.MemoSubject__c = srRecord.Name + ' - ' + Constants.MEMO_TYPE_NEW_PAYMENT_PLAN;
        bookingMemoRecord.MemoHeader__c = srRecord.Name + ' - ' + Constants.MEMO_TYPE_NEW_PAYMENT_PLAN;
        
        if (String.isNotBlank(specialNote)) {
            bookingMemoRecord.SpecialNote__c = specialNote; 
        }
        insert bookingMemoRecord;
        updateSRBookingMemo(srRecord.Id, bookingMemoRecord.Id, paymentPlan, newNetSellingPrice, srRecord.SalesOrder__r.NetAmount__c, paymentPlanId);

        MemoLines__c memoLineRecord = MemoLinesService.createMemoLines(srRecord.SalesOrder__r.Offer__c, srRecord.SalesOrder__r.PaymentPlan__c, srRecord.Unit__c, bookingMemoRecord.Id, '', '', '', '', '', '', discountPercentage, rebatePercentage, '', '', '', '', '', '', '','' );
        insert memoLineRecord;

        insertPaymentInstallments(installmentList, bookingMemoRecord.Id, srRecord.Unit__c);
    }

    /*
    * create Payment Installment thats need to be replaced with Installment Lines
    */
    public static void insertPaymentInstallments(List<Map<String,String>> installmentLineChangesList, Id bookingMemo, Id unitId){
        List<InstallmentLineChanges__c> installmentChangesList = new List<InstallmentLineChanges__c>();

        for (Map<String,String> il : installmentLineChangesList) {

            InstallmentLineChanges__c installmentChangesRecord = new InstallmentLineChanges__c();
            installmentChangesRecord.InstallmentNumber__c = Integer.valueOf(il.get('Number'));
            installmentChangesRecord.ProposedInstallmentPercentage__c = Decimal.valueOf(il.get('Percentage'));
            installmentChangesRecord.InstallmentAmount__c = Decimal.valueOf(il.get('Amount'));
            
            if(il.get('readonly') == 'true'){
                installmentChangesRecord.InstallmentDate__c = il.get('Date') != null ? Date.valueOf(il.get('Date')) : null;
                installmentChangesRecord.InstallmentPercentage__c = Decimal.valueOf(il.get('Percentage'));
            }
            installmentChangesRecord.ProposedInstallmentDate__c = il.get('Date') != null ? Date.valueOf(il.get('Date')) : null;
            installmentChangesRecord.BookingMemo__c = bookingMemo;
            installmentChangesRecord.Unit__c = unitId;
            if(il.get('Description')!=null){
                 installmentChangesRecord.Description__c=il.get('Description');
            }
           
            installmentChangesList.Add(installmentChangesRecord);
        }

        System.debug('**MAP1**:'+installmentChangesList);
        insert installmentChangesList;
    }

    /*
    * Update Service Request after applying the new payment plan
    */
    public static void updateSRBookingMemo(string srId, String bookingMemoId, String paymentPlan, String newNetSellingPrice, Decimal oldNetSellingPrice, String paymentPlanId){
        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(Id= srId, ProposalPaymentPlan__c= bookingMemoId, ChargeType__c= paymentPlan, NewNetAmount__c= Decimal.valueOf(newNetSellingPrice), OldNetAmount__c= oldNetSellingPrice, SRType__c = Constants.PAYMENT_PLAN_CHANGE_TYPE, PaymentPlan__c = paymentPlanId);
        sr.NewNetAmountInWords__c = newNetSellingPrice != '' && newNetSellingPrice != null ? Utilities.amountInWords(Decimal.valueOf(newNetSellingPrice),'Dirham','Fils') : '';
        update sr;
    }

    /*
    * to get Booking Memo Details 
    */
    @AuraEnabled(cacheable=false)
    public static MemoLines__c getBookingMemoDetails(String bookingMemoId){
        MemoLines__c memoLineRecord = MemoLinesService.getMemoLinesByBookinMemoId(bookingMemoId)[0];
        return memoLineRecord;
    }

    /*
    * get Installment Line changes record
    */
    @AuraEnabled(cacheable=false)
    public static List<InstallmentLineChanges__c> getInstallmentLineChangesDetails(String bookingMemoId){
        List<InstallmentLineChanges__c> lineList = InstallmentLineChangesService.getInstallmentLineChangesQuery('Select Id, InstallmentAmount__c, InstallmentNumber__c, ProposedInstallmentPercentage__c, InstallmentDate__c, ProposedInstallmentDate__c, BookingMemo__c, Unit__c, InstallmentPercentage__c,Description__c FROM InstallmentLineChanges__c WHERE BookingMemo__c =\''+bookingMemoId+'\' Order By InstallmentNumber__c asc');
        return lineList;
    }

    /*
    * to get the latest created step on SR
    */
    @AuraEnabled(cacheable=false)
    public static HexaBPM__Step__c getServiceRequestStep(String serviceRequestId){

        try{

            List <HexaBPM__Step__c> step = [SELECT Name, HexaBPM__Step_Status__c, HexaBPM__SR__c, HexaBPM__SR_Step__r.Name, HexaBPM__Step_Notes__c, HexaBPM__Summary__c 
            FROM HexaBPM__Step__c
            WHERE HexaBPM__SR__c =: serviceRequestId order by CreatedDate Desc limit 1];

            if(step.size() == 0 ){
                return null;
            }

            return step[0];

        } catch(exception e) {
            system.debug(e);
            return null;
        }
    }

    /*
    * to complete 'Verify Request' step
    */
    @AuraEnabled(cacheable=false)
    public static void completeServiceRequestStep(HexaBPM__Step__c step, HexaBPM__Service_Request__c sr){

        HexaBPM__Status__c stepStatus = [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name=: Constants.COMPLETED_STATUS];
        step.HexaBPM__Status__c = stepStatus.Id;

        HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.REQUEST_VERIFIED LIMIT 1];
        sr.HexaBPM__External_SR_Status__c = objSRStatus.Id;
        sr.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;

        List<SObject> recordsToUpdate = new List<SObject>();
        recordsToUpdate.add(sr);
        recordsToUpdate.add(step);

        update recordsToUpdate;
    }

    /*
    * update/insert/delete instalmment 
    */
    @AuraEnabled(cacheable=false)
    public static void updateInstallmentChangesRecords(MemoLines__c memoLineRecord, List<Map<String,String>> installmentLineChangesList, HexaBPM__Service_Request__c srRecord, String newNetSellingPrice, String paymentPlanId){

        update memoLineRecord;
        srRecord.NewNetAmount__c = Decimal.valueOf(newNetSellingPrice);
        srRecord.NewNetAmountInWords__c = Utilities.amountInWords(Decimal.valueOf(newNetSellingPrice),'Dirham','Fils');
        srRecord.PaymentPlan__c = paymentPlanId;
        update srRecord;

        List<InstallmentLineChanges__c> lineList = getInstallmentLineChangesDetails(memoLineRecord.BookingMemo__c);
        Map<Integer, InstallmentLineChanges__c> installmentNumberWithRecord = new Map<Integer, InstallmentLineChanges__c>();

        for (InstallmentLineChanges__c il : lineList) {
            installmentNumberWithRecord.put(Integer.valueOf(il.InstallmentNumber__c), il);
        }
        List<InstallmentLineChanges__c> installmentChangesToUpdateInsertList = new List<InstallmentLineChanges__c>();

        for (Map<String,String> il : installmentLineChangesList) {

            InstallmentLineChanges__c installmentChangesRecord = new InstallmentLineChanges__c();
            InstallmentLineChanges__c oldRecord = installmentNumberWithRecord.get(Integer.valueOf(il.get('Number')));

            if( oldRecord != null){
                installmentChangesRecord.Id = oldRecord.Id;
            } else {
                installmentChangesRecord.BookingMemo__c = memoLineRecord.BookingMemo__c;
                installmentChangesRecord.Unit__c = memoLineRecord.Unit__c;
                installmentChangesRecord.InstallmentNumber__c = Integer.valueOf(il.get('Number'));
            }

            installmentChangesRecord.ProposedInstallmentPercentage__c = Decimal.valueOf(il.get('Percentage'));
            if(il.get('readonly') == 'true'){
                installmentChangesRecord.InstallmentDate__c = il.get('Date') != null ? Date.valueOf(il.get('Date')) : null;
                installmentChangesRecord.InstallmentPercentage__c = Decimal.valueOf(il.get('Percentage'));
            }
            if(il.get('Description')!=null){
                 installmentChangesRecord.Description__c=il.get('Description');
            } 
            installmentChangesRecord.ProposedInstallmentDate__c = il.get('Date') != null ? Date.valueOf(il.get('Date')) : null;
            installmentChangesRecord.InstallmentAmount__c = Decimal.valueOf(il.get('Amount'));
            installmentChangesToUpdateInsertList.Add(installmentChangesRecord);
        }
        upsert installmentChangesToUpdateInsertList;

        List<InstallmentLineChanges__c> installmentChangesToDeleteList = new List<InstallmentLineChanges__c>();

        if(installmentLineChangesList.size() < lineList.size()){
            for (InstallmentLineChanges__c rec : lineList) {
                if(rec.InstallmentNumber__c > installmentLineChangesList.size()){
                    installmentChangesToDeleteList.add(rec);
                }
            }
            delete installmentChangesToDeleteList;
        }
    }

    /*
    * get the list of available payment plans
    */
    @AuraEnabled(cacheable=true)
    public static List<PaymentPlan__c> getListOfPaymentPlans(Unit__c unit){
        
        User loggedInUser = Utilities.getLoggedInUserDetail();
        Map<Id,List<PaymentPlan__c>> unitPaymentPlanMap = PaymentPlanService.getListOfPaymentPlansPostSales(null,new List<Unit__c>{unit}, loggedInUser);

        return unitPaymentPlanMap.values()[0];
    }
}