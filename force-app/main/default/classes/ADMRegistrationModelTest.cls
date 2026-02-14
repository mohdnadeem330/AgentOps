@isTest
private class ADMRegistrationModelTest {
    
    @isTest
    public static void callMethod (){
        Test.startTest();
        
        ADMRegistrationModel.CreateApplication cr = new ADMRegistrationModel.CreateApplication();
        cr.dmtNumber = '';
        cr.applicationType = '';
        cr.key = '';
        cr.priority = true;
        cr.isDraft = true;
        cr.buyers = null;
        cr.contractDetails = null;
        cr.paymentPlanType = '';
        cr.instalmentPlanList = null;
        cr.brokers = null;

        ADMRegistrationModel.InstalmentPlanList il = new ADMRegistrationModel.InstalmentPlanList();
        il.displayOrder = null;
        il.categoryType = null;
        il.date_Z = null;
        il.frequency = null;
        il.instalmentType = null;
        il.percentage = null;
        il.value = null;

        ADMRegistrationModel.Brokers br = new ADMRegistrationModel.Brokers();
        br.eidNumberOrUnified = null;
            
        ADMRegistrationModel.Buyers bu = new ADMRegistrationModel.Buyers();
        bu.eidNumberOrUnified = null;
        bu.email = null;
        bu.representatives = null;
        bu.tradeLicenseNo = null;
        bu.transactionShare = null;
        
        ADMRegistrationModel.Representatives re = new ADMRegistrationModel.Representatives();
        re.eidNumberOrUnified = null;
        
        ADMRegistrationModel.ContractDetails co = new ADMRegistrationModel.ContractDetails();
        co.dateOfSale = null;
        co.paidBy = null;
        co.projectCompletionDate = null;
        co.salePrice = null;

        ADMRegistrationModel.UploadDocumentRequest up = new ADMRegistrationModel.UploadDocumentRequest();
		up.applicationId = null;
		up.fileData = null;
		up.fileName = null;
		up.srDocId = null;

        Test.stopTest();
    }

}