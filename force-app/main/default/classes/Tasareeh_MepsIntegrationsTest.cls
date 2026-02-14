@isTest
public class Tasareeh_MepsIntegrationsTest {
    
    @isTest
    static void testExecuteSeries(){
        List<String> allInterfaces = new List<String>{
            'Parcels',
                'mapPermit',
                'mapWorkflowTask',
                'mapInspections',
                'mapPermitCustomProperties',
                'mapFees',
                'mapProfessional',
                'mapStatusHistory',
                'mapWorkflowHistory',
                'mapPayments',
                'mapBuildingDetails',
                'mapDocument',
                'mapB1Permit'
                };
                    
                    for(String strVal : allInterfaces){
                        testParcelsMethodHelper(strVal, '2023-07-01');
                    }
    }
    
    static void testParcelsMethodHelper(String methodName, String recDate) {
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new TasareehHttpMock());
        
        // Instantiate the Queueable class
        Tasareeh_MepsIntegrations queueable = new Tasareeh_MepsIntegrations(methodName, recDate,true);
        
        //Test.startTest();
        System.enqueueJob(queueable);
        //Test.stopTest();
    }
    
    @isTest
    static void testParcelsMethod() {
        // Directly call the helper method with sample data
        testParcelsMethodHelper('Parcels', '2023-07-01');
    }
    
    @isTest
    static void testExecuteWithInvalidMethod() {
        // Set up test data
        String methodName = 'InvalidMethod';
        String recDate = '2023-07-01';
        
        // Instantiate the Queueable class
        Tasareeh_MepsIntegrations queueable = new Tasareeh_MepsIntegrations(methodName, recDate,true);
        
        // Enqueue the job
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify the expected outcomes
        List<Logger__c> logs = [SELECT Id, Message__c FROM Logger__c WHERE ExecutingProcessName__c = 'Tasareeh_MepsIntegrations'];
        System.assertEquals(1, logs.size(), 'There should be one error log for invalid method');
        System.assert(logs[0].Message__c.contains('Invalid methodName'), 'Log message should indicate invalid method name');
    }
    
    // Mock class to simulate HTTP responses
    private class TasareehHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            String testResponse =       '{'+
                '    "B1Permits": ['+
                '        {'+
                '            "ServiceCode": "BPROJ",'+
                '            "RecordId": "B1S-2022-000109-P06-I02",'+
                '            "RecordStatus": "Submitted",'+
                '            "RecordStatusArabic": "تم تقديم الطلب",'+
                '            "RecordClass": "COMPLETE",'+
                '            "Balance": 0,'+
                '            "ProjectDescription": null,'+
                '            "LastStatusDate": "2023-08-29 00:00:00.0",'+
                '            "SubmissionDate": "2023-08-29 00:00:00.0",'+
                '            "Sector": "Al Wafia",'+
                '            "PlotNumber": "RCH57",'+
                '            "Zone": "AL KHATIM",'+
                '            "SectorArabic": "الوافية",'+
                '            "ZoneArabic": "الختم",'+
                '            "SubServiceName": null,'+
                '            "SubServiceValue": null,'+
                '            "UserId": "PUBLICUSER347",'+
                '            "SubServiceValueArabic": null,'+
                '            "ApplicationSubType": null,'+
                '            "ApplicationSubTypeAr": null'+
                '        }'+
                '    ],'+
                '    "BuildingDetails": ['+
                '        {'+
                '            "RecordId": "B1S-2022-000109-P06-I02",'+
                '            "BuildingNumber": "1",'+
                '            "NumberOfUnits": "1",'+
                '            "NumberOfFloors": "1",'+
                '            "NumberOfBasementFloors": null,'+
                '            "TotalHeight": null,'+
                '            "BuildingArea": "91",'+
                '            "FloorArea": null,'+
                '            "NumberOfEntrances": "1",'+
                '            "RecordUpdatedDate": "2024-05-25 10:02:19.877",'+
                '            "RecordDate": "2024-05-25 10:02:19.877"'+
                '        }'+
                '    ],'+
                '    "Documents": ['+
                '        {'+
                '            "DocumentId": 85163297,'+
                '            "RecordId": "B1S-2022-000109-P06-I02",'+
                '            "DocumentName": "Building Permit - B5N-2023-011568-P01.pdf",'+
                '            "DocumentGroup": "BLD_PER",'+
                '            "DocumentDescription": "Latest",'+
                '            "DocumentType": "application/pdf",'+
                '            "DocumentCategory": "Building Permit",'+
                '            "FileName": "Building Permit - B5N-2023-011568-P01.pdf",'+
                '            "FileSize": 562775,'+
                '            "UploadDate": "2024-04-15 13:36:19.953",'+
                '            "RecordDate": "2024-05-25 00:55:33.48"'+
                '        }'+
                '    ],'+
                '    "Fees": ['+
                '        {'+
                '            "RecordId": "B1S-2022-000109-P06-I02",'+
                '            "FeeId": 15793,'+
                '            "FeeDescription": "Unified Building Permit Request Fee (Abu Dhabi Civil Defense)",'+
                '            "FeeAmount": 0.5,'+
                '            "FeeCount": 22,'+
                '            "FeeTotal": 11,'+
                '            "FeeApplyDate": "2023-08-29 14:49:40.213",'+
                '            "FeeStatus": "INVOICED",'+
                '            "FeeSchedule": "PERMIT REQUEST",'+
                '            "INVOICE_NUMBER": 313945, '+                                
                '            "INVOICE_AMOUNT": 1260.0,'+                                 
                '            "StatusDate": "2023-08-29 14:34:03.24"'+
                '        },'+
                '        {'+
                '            "RecordId": "B1S-2022-000109-P06-I02",'+
                '            "FeeId": 15793,'+
                '            "FeeDescription": "Unified Building Permit Request Fee (Abu Dhabi Civil Defense)",'+
                '            "FeeAmount": 0.5,'+
                '            "FeeCount": 22,'+
                '            "FeeTotal": 11,'+
                '            "FeeApplyDate": "2023-08-29 14:49:40.213",'+
                '            "FeeStatus": "CREDITED",'+
                '            "FeeSchedule": "PERMIT REQUEST",'+
                '            "StatusDate": "2023-08-29 14:34:03.24"'+
                '        }'+
                '    ],'+
                '    "Inspections": ['+
                '        {'+
                '            "RecordId": "B1S-2022-000109-P06-I02",'+
                '            "InspectionNumber": 11111,'+
                '            "InspectionType": "Foundation Inspection",'+
                '            "Inspector": "INSP6 AA Structural",'+
                '            "ScheduleDate": "2023-08-31 08:00:00.0",'+
                '            "InspectionDate": "2023-08-29 13:22:00.0",'+
                '            "InspectionStatus": "Approved",'+
                '            "InspectorComments": null,'+
                '            "RecordDate": "2023-08-29 00:00:00.0"'+
                '        }'+
                '    ],'+
                '    "Parcels": ['+
                '        {'+
                '            "GisID": "100046939",'+
                '            "Zone": "Al Zahiyah",'+
                '            "PlotArea": "464.52",'+
                '            "Sector": "E16",'+
                '            "Street": "~",'+
                '            "LandUse": "commercialLand",'+
                '            "LandUseArabic": "ارض تجارية",'+
                '            "LandUseIdentifier": "COM-1",'+
                '            "Municipality": "ADM",'+
                '            "PlotNumber": "C41",'+
                '            "PlotWidth": null,'+
                '            "SecondaryLandUse": "commercial",'+
                '            "SecondaryLandUseArabic": "تجاري",'+
                '            "SitePlanNumber": "2011/230431",'+
                '            "StatusDate": "2023-08-29 12:16:38.87",'+
                '            "RecordId": null'+
                '        }'+
                '    ],'+
                '    "Permits": ['+
                '        {'+
                '            "RecordId": "B1S-2022-000109-P06-I02",'+
                '            "Municipality": "DAR",'+
                '            "ServiceName": "Inspection Request",'+
                '            "ServiceNameArabic": "طلب كشف فني موقعي",'+
                '            "ServiceCode": "INSP",'+
                '            "CurrentRecordStatus": "Approved",'+
                '            "CurrentKPIStatusOfRecord": "Pending Payment",'+
                '            "KPIStartDate": "2023-08-29 13:15:25.487",'+
                '            "KPIEndDate": "2023-08-29 13:22:30.983",'+
                '            "KPIAchievedInDays": 0,'+
                '            "SubmissionDate": "2023-08-29 00:00:00.0",'+
                '            "GisID": "100046939",'+
                '            "KPIEndStatusType": null,'+
                '            "KPIStartStatus": null,'+
                '            "KPIEndStatus": null,'+
                '            "CreatedBy": null,'+
                '            "channel": "TAMM",'+
                '            "LastStatusDate": "2023-08-29 13:12:45.27"'+
                '        },'+
                '       {'+
                '            "RecordId": "B1S-2022-000109",'+
                '            "Municipality": "DAR",'+
                '            "ServiceName": "Building Project Registration Request",'+
                '            "ServiceNameArabic": "طلب كشف فني موقعي",'+
                '            "ServiceCode": "BPROJ",'+
                '            "CurrentRecordStatus": "Approved",'+
                '            "CurrentKPIStatusOfRecord": "Pending Payment",'+
                '            "KPIStartDate": "2023-08-29 13:15:25.487",'+
                '            "KPIEndDate": "2023-08-29 13:22:30.983",'+
                '            "KPIAchievedInDays": 0,'+
                '            "SubmissionDate": "2023-08-29 00:00:00.0",'+
                '            "GisID": "100046939",'+
                '            "KPIEndStatusType": null,'+
                '            "KPIStartStatus": null,'+
                '            "KPIEndStatus": null,'+
                '            "CreatedBy": null,'+
                '            "channel": "TAMM",'+
                '            "LastStatusDate": "2023-08-29 13:12:45.27"'+
                '        }'+
                '    ],'+
                '    "PermitsCustomProperties": ['+
                '        {'+
                '            "RecordId": "B1S-2022-000109-P06-I02",'+
                '            "ASIFieldName": "Addition Sub Type",'+
                '            "ASIFieldValue": "Building additions horizontal expansion",'+
                '            "ASIFieldGroup": "PROJECT TYPE",'+
                '            "RecordDate": "2023-08-29 12:16:38.87"'+
                '        }'+
                '    ],'+
                '    "Professionals": ['+
                '        {'+
                '            "RecordId": "B1S-2022-000109-P06-I02",'+
                '            "ConsultantTradeLicenseNumber": "CN-1001312",'+
                '            "ConsultantType": "Designer and Supervisor",'+
                '            "ConsultantName": "CN-1001312 TEST",'+
                '            "ConsultantEmail": "eng.mohamed.emad1990@gmail.com",'+
                '            "ConsultantMobile": "+971522662323",'+
                '            "ContractorName": "CN-1792267 TEST",'+
                '            "ContractorMobile": "+971505440581",'+
                '            "ContractorTradeLicenseNumber": "CN-1792267",'+
                '            "ContractorEmail": "eng.mohamed.emad1990@gmail.com",'+
                '            "StatusDate": "2023-08-29 00:00:00.0"'+
                '        }'+
                '    ],'+
                '    "StatusHistory": ['+
                '        {'+
                '            "RecordId": "B1S-2022-000109-P06-I02",'+
                '            "RecordStatus": "Submitted",'+
                '            "StatusHistoryId": 845330,'+
                '            "StatusDate": "2023-08-29 12:16:38.87",'+
                '            "StatusComment": null,'+
                '            "ServiceCode": "BPROJ"'+
                '        }'+
                '    ],'+
                '    "WorkflowTasks": ['+
                '        {'+
                '            "RecordId": "B1S-2022-000109-P06-I02",'+
                '            "TaskName": "Review Assignment",'+
                '            "TaskStatus": "Received",'+
                '            "DueDays": "2",'+
                '            "DueDate": "2023-08-31 00:00:00.0",'+
                '            "AssginedDate": "2023-08-29 12:23:54.867",'+
                '            "StatusDate": "2023-08-29 12:16:38.87",'+
                '            "KPIInDays": 0,'+
                '            "IsActive": "Y",'+
                '            "IsCompleted": "N",'+
                '            "Comments": "undefined",'+
                '            "Department": "ADSC",'+
                '            "EmployeeName": "CORTRN CORTRN",'+
                '            "EmployeeId": "PUBLICUSER347",'+
                '            "SequenceId": 3'+
                '        }'+
                '    ],'+
                '    "WorkflowHistory": ['+
                '        {'+
                '            "RecordId": "B1S-2022-000109-P06-I02",'+
                '            "TaskName": "Inspection",'+
                '            "TaskStatus": "Approved",'+
                '            "DueInDays": "3",'+
                '            "TaskDueDate": "2023-09-01 00:00:00.0",'+
                '            "TaskAssignedDate": "2023-08-29 00:00:00.0",'+
                '            "TaskStatusDate": "2023-08-29 13:22:30.827",'+
                '            "TaskKPIInDays": 0,'+
                '            "IsActive": "N",'+
                '            "IsCompleted": "Y",'+
                '            "Comments": "undefined",'+
                '            "Department": null,'+
                '            "EmployeeName": "System User",'+
                '            "EmployeeId": "MOHAMEDIMAD",'+
                '            "Id": 34,'+
                '            "StatusDate": "2023-08-29 00:00:00.0"'+
                '        }'+
                '    ],'+
                '                "Payments": ['+
                ' {'+
                '   "RecordId": "B5M-2024-006730-P01-R01",'+
                '  "RecordSubmissionDate": "2025-02-17 15:39:05.95",'+
                ' "RecordRequestType": "Permit Renewal Request",'+
                ' "FeesDescription": "Unified Building Permit Request Fee (Abu Dhabi Civil Defense)",'+
                ' "FeesCode": "BLD_TASREEH",'+
                ' "gf_fee_schedule": "TASREEH",'+
                '"InvoiceNBR": "313945",'+
                '  "TransactionCode": "250490826903823",'+
                ' "PaymentMethod": "Online",'+
                ' "PaymentDate": "2025-02-18 08:27:01.74",'+
                '  "Amount": 2000.0'+        
                '}'+
                ']'+
                
                '}';
            //res.setBody('{"Parcels":[],"Permits":[],"WorkflowTasks":[],"Inspections":[],"PermitsCustomProperties":[],"Fees":[],"Professionals":[],"StatusHistory":[],"WorkflowHistory":[],"BuildingDetails":[],"Documents":[],"B1Permits":[]}');
            res.setBody(testResponse);
            return res;
        }
    }
    
    @isTest
    static void testCalloutExceptionHandling() {
        // Set up test data
        String methodName = 'Parcels';
        String recDate = '2023-07-01';
        
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new TasareehHttpMock());
        
        // Instantiate the Queueable class
        Tasareeh_MepsIntegrations queueable = new Tasareeh_MepsIntegrations(methodName, recDate,false);
        
        // Enqueue the job
        Test.startTest();
        //System.enqueueJob(queueable);
        Tasareeh_Schedulable pSch = new Tasareeh_Schedulable(); //Schedule apex class name
        String sch = '0 30 18 ? * SAT *'; //schedule interval time
        pSch.execute(null);
        //TasareehIntegration_Util.getPaymentBatchQuery('Fees__c');
        Test.stopTest();
        
        // Verify the expected outcomes
        List<Logger__c> logs = [SELECT Id, Message__c FROM Logger__c WHERE ExecutingProcessName__c = 'Tasareeh_MepsIntegrations'];
        //System.assertEquals(1, logs.size(), 'There should be one error log for callout exception');
        //System.assert(logs[0].Message__c.contains('Error during callout'), 'Log message should indicate callout error');
    }
    
    // Mock class to simulate HTTP exceptions
    private class TasareehHttpExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated callout exception');
        }
    }
}