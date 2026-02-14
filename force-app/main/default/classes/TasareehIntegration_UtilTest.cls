@isTest
public class TasareehIntegration_UtilTest {
    @isTest
    static void testUtilMethods(){
        Parcel__c plot= new Parcel__c(GsId__c='10004286518',Municipality_Owner__c='Al Dar' );
        insert plot;
        Permit__c permitObj = new Permit__c(
            Name = 'B1N-2023-003515',
            Channel__c = 'TAMM',
            KPIAchievedInDays__c = 2,
            KPIEndDate__c = DateTime.now(),
            KPIEndStatusType__c = 'Approved',
            KPIEndStatus__c = 'Project and Site Approved - N',
            KPIStartDate__c = DateTime.now(),
            Parcel_Plot__c=plot.Id,
            KPIStatus__c = 'Project and Site Approved - N',
            LastStatusDate__c = DateTime.now(),
            Municipality__c = 'DAR',
            Rec_Date__c = DateTime.now(),
            RecordId__c = 'B1N-2023-003515',
            ServiceCode__c = 'BPROJ',
            ServiceNameArabic__c = 'طلب تسجيل مشروع بناء',
            ServiceName__c = 'Building Project Registration Request',
            Status__c = 'Per Issued/Phased Ready(New)',
            ParentId__c = '10004286518',
            Sub_Service_Value1__c = 'New building on empty plot',
            SubmissionDate__c = DateTime.now(),
            KPI_Duration__c = 1,
            CAP_ID_1__c = '23BLD',
            CAP_ID_2__c = '0',
            CAP_ID_3__c = '02B6A',
            Category__c = 'BPROJ',
            Ignore_Proj__c = 'N',
            Module__c = 'Building',
            Plot_Changed__c = 'N',
            Plot_Number__c = 'P5',
            Record_Class__c = 'COMPLETE',
            Record_Status__c = 'A',
            Record_Status_Arabic__c = 'تمت موافقة المشروع والموقع - ج',
            Sector__c = 'Ba Al Ghaiylam',
            Sector_Arabic__c = 'بلغيلم',
            Service_Code__c = 'ADMA',
            Show_Alert__c = 'N',
            Sub_Service_Name__c = 'Secondary Service',
            Sub_Type__c = 'Project Creation Request',
            Type__c = 'Projects',
            User_Id__c = 'PUBLICUSER17150',
            Zone__c = 'Al Bahyah',
            Zone_Arabic__c = 'الباهية');
        insert permitObj;
        Fees__c fee= new Fees__c(recordId__c='15793',Invoice_Number__c=313945,FeeDescription__c='TASREEH review fees');
        insert fee;
        Permit_Payment__c pp= new Permit_Payment__c(FeeDescription__c='TASREEH review fees',InvoiceNumber__c='313945',	PaymentIdentifier__c='TASREEH review fees-313945');
        insert pp;
        StatusHistory__c sh=new StatusHistory__c(StatusDate__c=DateTime.now(),permit__c=permitObj.Id,Status__c='Submitted');
        insert sh;
        StatusHistory__c sh1=new StatusHistory__c(StatusDate__c=DateTime.now(),permit__c=permitObj.Id,Status__c='Pending Required Services');
        insert sh1;
        WorkflowTask__c w=new WorkflowTask__c();
        w.name='Review';
        insert w;
        List<BusinessHours> bhs = [select id, MondayStartTime, MondayEndTime from BusinessHours where IsDefault=true];
        TasareehIntegration_Util.DueDateRequest dueReq = new TasareehIntegration_Util.DueDateRequest();
        dueReq.startDate = DateTime.now();
        dueReq.businessDays = 5;
        dueReq.businessHoursRecord = bhs[0];
        dueReq.isDifference = false;
        dueReq.recId=w.id;
        dueReq.objapiname='WorkflowTask__c';
        
        
        TasareehIntegration_Util.DueDateRequest dueReq1 = new TasareehIntegration_Util.DueDateRequest();
        dueReq1.startDate = DateTime.now();
        dueReq1.endDate = DateTime.now();
        dueReq1.businessHoursRecord = bhs[0];
        dueReq1.isDifference = true;
        dueReq1.recId=w.id;
        dueReq1.objapiname='WorkflowTask__c';
         WorkflowTask__c w1=new WorkflowTask__c();
        w1.name='Review';
        w1.Actual_Due_Date__c=DateTime.now();
        w1.Department__c='ALDARPD';
        w1.Escalated_On__c=date.today();
        w1.Reviewer_Email__c='test@gmail.com';
        insert w1;
         WorkflowTask__c w2=new WorkflowTask__c();
        w2.name='Review';
        w2.Department__c='ALDARPD';
        w2.Actual_Due_Date__c=DateTime.now();
        w2.Notification_Date__c=date.today();
        w2.Reviewer_Email__c='test@gmail.com';
        insert w2;
        
        //String recordsData='[{"Sr.No":1,"MePS Ref#":"B1N-2022-005666-P03-M04","Receipt Date":"2023-02-11"," Amount Received ":1575,"BRS Ref":"000801","Actual MePs Refence ID":"B1N-2022-005666-P03-M04"},{"Sr.No":2,"MePS Ref#":"B1N-2021-006134-P01-I119","Receipt Date":"2023-02-11"," Amount Received ":630,"BRS Ref":"51241116223106","Actual MePs Refence ID":"B1N-2021-006134-P01-I119"}]';
        
        Test.startTest();
        Set<String> val = new Set<String>();
        val.add(permitObj.name);
        Boolean isProd = TasareehIntegration_Util.isProduction();
        Map<String,Id> mapPermitId = TasareehIntegration_Util.getPermitDetail(new Set<String>{permitObj.RecordId__c});
        TasareehIntegration_Util.calculateDueDate(new List<TasareehIntegration_Util.DueDateRequest>{dueReq});
        TasareehIntegration_Util.calculateDueDate(new List<TasareehIntegration_Util.DueDateRequest>{dueReq1});
        TasareehIntegration_Util.mapWithExtObjRecs('Name','Permit__c','Name',permitObj.id,val);
        //TasareehIntegration_Util.getPaymentBatchQuery('Fees__c');
        Database.executeBatch(new TasareehPaymentBatch('Permit_Payment__c'),10);
        Database.executeBatch(new TasareehPaymentBatch('Fees__c'),10);
       Database.executeBatch(new TasareehStatusHistoryBatch(),10);
        TasareehIntegration_Util.sendLoggerEmail();
        TasareehIntegration_Util.TasareehEmailBatchQuery();
        TasareehIntegration_Util.getReviewerNotificationTasks();
        Test.stopTest();
        
    }
}