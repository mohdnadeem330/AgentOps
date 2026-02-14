/**********************************************************************************************************************
* Name               : SendGridTestUtils                                                        
* Description        : Apex Unit Tests Utilities
* Created By         : Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     15/09/2023      Initial Draft       
******************************************************************************************************************/
public with sharing class SendGridTestUtils {
    /**
	 * prepareMockDataToSendPaymentReminder description
	 */
	public static void prepareMockDataToSendPaymentReminder(){

		//for single invoice sync
		SendGridMockHTTPResponseGenerator paymentReminderMock = new SendGridMockHTTPResponseGenerator(200, getSuccessResponseJSON());

		Map<String, HttpCalloutMock> testRespMap  = new Map<String,HttpCalloutMock>();

        APISetting__mdt  sendGridAPI = Utilities.getServiceDetails(SendGridIntegrationUtilities.SENDGRID_PAYMENT_REMINDER);
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = sendGridAPI.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = sendGridAPI.ProductionURL__c ; 
        }

		testRespMap.put(endPointURL, paymentReminderMock);

		HttpCalloutMock multiCalloutMock = new SendGridMultiRequestMock(testRespMap);

		Test.setMock(HttpCalloutMock.class, multiCalloutMock);
	}

    public static void prepareMockDataToSendPaymentReminder_Error(){

		//for single invoice sync
		SendGridMockHTTPResponseGenerator paymentReminderMock = new SendGridMockHTTPResponseGenerator(400, getErrorResponseJSON_SalutationMissing());

		Map<String, HttpCalloutMock> testRespMap  = new Map<String,HttpCalloutMock>();

        APISetting__mdt  sendGridAPI = Utilities.getServiceDetails(SendGridIntegrationUtilities.SENDGRID_PAYMENT_REMINDER);
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = sendGridAPI.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = sendGridAPI.ProductionURL__c ; 
        }

		testRespMap.put(endPointURL, paymentReminderMock);

		HttpCalloutMock multiCalloutMock = new SendGridMultiRequestMock(testRespMap);

		Test.setMock(HttpCalloutMock.class, multiCalloutMock);
	}

    public static void prepareMockDataToSendPaymentReminder_Error_NoBody(){

		//for single invoice sync
		SendGridMockHTTPResponseGenerator paymentReminderMock = new SendGridMockHTTPResponseGenerator(500, null);

		Map<String, HttpCalloutMock> testRespMap  = new Map<String,HttpCalloutMock>();

        APISetting__mdt  sendGridAPI = Utilities.getServiceDetails(SendGridIntegrationUtilities.SENDGRID_PAYMENT_REMINDER);
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = sendGridAPI.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = sendGridAPI.ProductionURL__c ; 
        }

		testRespMap.put(endPointURL, paymentReminderMock);

		HttpCalloutMock multiCalloutMock = new SendGridMultiRequestMock(testRespMap);

		Test.setMock(HttpCalloutMock.class, multiCalloutMock);
	}

    static String getSuccessResponseJSON(){
        return  '{'+
                '    "status": true,'+
                '    "message": "Email successfully dispatched to : [harshrohillaa@gmail.com], cc: [], bcc: []",'+
                '    "data": {'+
                '        "id": "d-6706fcfe992144d29cded049acd7aad0",'+
                '        "name": "aldar_edm_payment_milestones_master_en_1",'+
                '        "generation": "dynamic",'+
                '        "updated_at": "2023-10-27 08:01:19",'+
                '        "versions": ['+
                '            {'+
                '                "id": "15fe5a0e-9d66-4c2e-ba6c-e2c9323cbcb4",'+
                '                "user_id": 36254078,'+
                '                "template_id": "d-6706fcfe992144d29cded049acd7aad0",'+
                '                "active": 1,'+
                '                "name": "aldar_edm_payment_milestones_master_en_1_v1",'+
                '                "html_content": "<HTML><BODY><p>Some Test HTML</BODY></HTML>",'+
                '                "plain_content": "Test PLain Content",'+
                '                "generate_plain_content": true,'+
                '                "subject": "",'+
                '                "updated_at": "2023-11-04 07:53:22",'+
                '                "editor": "code",'+
                '                "thumbnail_url": "test"'+
                '            }'+
                '        ]'+
                '    }'+
                '}';
    }

    static String getErrorResponseJSON_SalutationMissing(){

        return  '{'+
                '    "error": {'+
                '        "statusCode": 400,'+
                '        "message": "Bad Request Exception",'+
                '        "errorName": "BadRequestException",'+
                '        "details": {'+
                '            "success": false,'+
                '            "message": ['+
                '                ['+
                '                    "salutation should not be empty"'+
                '                ]'+
                '            ]'+
                '        },'+
                '        "path": "https://soho-emails-temp-container.azurewebsites.net",'+
                '        "requestId": "e5f715f5-2531-499f-a1bb-847deefeff6b",'+
                '        "timestamp": "2023-11-06T11:04:42.345Z"'+
                '    }'+
                '}';
    }

    /********************* APEX TEST DATA GENERATORS USED IN SENDGRIDTEST AND RELATED APEX TEST CLASSES START ***************************/

    public static void generateTestData(){
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        // acc.SourceofFunds__pc = '';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.Name_of_Seller__c = Label.ProformaSellerName;
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;

        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLine = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLine;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        insert buldingPaymentMapping;    
        
        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id,projectRecord.Id);
        insert offerRecord;
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;

       
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        salesOrderRecord.NetAmount__c  = 100;
        insert salesOrderRecord;
    }

    public static void generateTestData_Installment(Integer dayCount){
        List<InstallmentLines__c> installmentLines = new list<InstallmentLines__c>();
        Decimal totalNetSellingPrice = 1000000;
        SalesOrder__c salesOrderRecord = [SELECT Id FROM SalesOrder__c LIMIT 1];
        for(PaymentInstallments__c tempInstallmentLine : [select id,BrokerPayoutPercentage__c,Description__c,InstallmentNumber__c,InstallmentPercentage__c,InstallmentDate__c,PaymentPlan__c from PaymentInstallments__c LIMIT 1]){
            installmentLines.add(new InstallmentLines__c( 
                BrokerPayoutPercentage__c= tempInstallmentLine.BrokerPayoutPercentage__c,
                Description__c= tempInstallmentLine.Description__c,
                InstallmentNumber__c = tempInstallmentLine.InstallmentNumber__c,
                InstallmentPercentage__c= tempInstallmentLine.InstallmentPercentage__c,
                InstallmentDate__c = dayCount == 0 ? System.today() : System.today().addDays(dayCount),
                InstallmentAmount__c= totalNetSellingPrice * (tempInstallmentLine.InstallmentPercentage__c/100),
                PaymentInstallments__c= tempInstallmentLine.Id,
                SalesOrder__c = salesOrderRecord.Id,
                PaymentPlan__c= tempInstallmentLine.PaymentPlan__c
            )); 
        }

        insert installmentLines;
    }

    /********************* APEX TEST DATA GENERATORS USED SENDGRIDTEST AND RELATED APEX TEST CLASSES END ***************************/

}