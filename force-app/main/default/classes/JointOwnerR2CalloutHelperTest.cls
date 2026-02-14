@isTest(SeeAllData=false)
public class JointOwnerR2CalloutHelperTest {
    @isTest static void setupMethod() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        acc.ERPID__c = '12346';
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'aldar.test.account@gmail.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesorder.RebateForfeitureLetterSent__c = TRUE;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('Joint Owner');        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.JOINT_OWNER_RT, 'JointOwner');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c verificationByFinance = TestObjectsFactory.getSRStatus('Verification by Finance');       
        insert verificationByFinance;
       
        Id jointOwnerId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.JOINT_OWNER_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.ADDITION_JOINT_OWNER_RT, jointOwnerId, SRTemplateDetailRecord.Id);
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;

        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_OWNERSHIP_CHANGE;
        update otherCharges;

        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        newStep.HexaBPM__Summary__c = Constants.Verification_BY_FINANCE;
        newStep.HexaBPM__Step_Notes__c = 'Notes';
        newStep.HexaBPM__Closed_Date__c = Date.Today();
        insert newStep;

        Account acc1 = TestObjectsFactory.getPersonAccountRecord();
        acc1.ERPID__c = '12345';
        insert acc1;

        JointOwnerR2CalloutHelper.getDataForCallout(new List<Id>{newSR.Id});
        
        AgencyTeam__c agencyTeam = new AgencyTeam__c();
        agencyTeam.Account__c = acc.Id;
        agencyTeam.ServiceRequest__c = newSR.Id;
        agencyTeam.ShareHoldingPercentage__c = 20;
        agencyTeam.RelationshipType__c = 'Spouse Of';
        insert agencyTeam;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc.Id, 'Spouse Of');
        insert jointOwner;

        JointOwnerR2CalloutHelper.getDataForCallout(new List<Id>{newSR.Id});

        String requestBody = '{"ownershipDetails":[{"othChg":[{"subType":"","vatAmount":"","amountWithoutVat":"","installmentLine":"","salesSupportCost":"","typeOfCharge":"ADM Fee","outAmountWords":"Five Thousand One Hundred Forty-One Dhirams and Thirty Fils Only.","opportunity":"","invoiceNumber":"","invoiceId":"","amount":"5141.30","amountReceived":"","accountId":"0018d00000JqsogAAB","sfSalesOrderId":"a2A3H000000AeWoUAK","currencyCode":"AED","name":"OC-0005565","sfId":"a293H000000Mm7uQAC","srSfid":"a0Q3H000003YVXIUA4"}],"srType":"Addition Joint Owner","srSfid":"a0Q3H000003YVXIUA4","relationshipCode":"Friend Of","sfId":"a1O3H000000bVd4UAE","createdByUser":"hardikkumar.vitthani.tpr@pwc.com","sharePercentage":"30.00","jointOwnerId":"0018d00000JqsogAAB","custAccountId":"0013H00000XNHOIQA5","partyId":"4097764","salesOrderId":"a2A3H000000AeWoUAK","mode":"CREATE"}]}';
        
        String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "0f0549c0-a16f-11ed-af3e-06affba2cd76","results": {"ownershipChangeResp": [{"jointOwnerId": "21893","salesOrderId": "91525","partyId": "4130744","mode": "CREATE","sfId": "'+jointOwner.Id+'","sfRequestId": "0f0549c0-a16f-11ed-af3e-06affba2cd76","status": "Success","errorMsg": "","srSfId": "'+newSR.Id+'"}],"othChgRes": [{"sfRequestId": "0f0549c0-a16f-11ed-af3e-06affba2cd76","srSfid": "'+newSR.Id+'","sfId": "'+otherCharges.Id+'","erpId": "9012840","recAcct": "02.10.A321053.122101.02.00.000.000","expAcct": "02.10.A321053.233167.02.00.000.000","taxAcct": "02.10.A321053.233169.02.00.000.000","status": "Success","errorMsg": ""}]}}';
        String responseFailureBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "0f0549c0-a16f-11ed-af3e-06affba2cd76","results": {"ownershipChangeResp": [{"jointOwnerId": "21893","salesOrderId": "91525","partyId": "4130744","mode": "CREATE","sfId": "'+jointOwner.Id+'","sfRequestId": "0f0549c0-a16f-11ed-af3e-06affba2cd76","status": "Failure","errorMsg": "","srSfId": "'+newSR.Id+'"}],"othChgRes": [{"sfRequestId": "0f0549c0-a16f-11ed-af3e-06affba2cd76","srSfid": "'+newSR.Id+'","sfId": "'+otherCharges.Id+'","erpId": "9012840","recAcct": "02.10.A321053.122101.02.00.000.000","expAcct": "02.10.A321053.233167.02.00.000.000","taxAcct": "02.10.A321053.233169.02.00.000.000","status": "Failure","errorMsg": ""}]}}';
        
        try{
            Test.startTest();
            MuleSOResponeWrapper responseBodyWrapper = (MuleSOResponeWrapper)System.JSON.deserialize(responseBody, MuleSOResponeWrapper.class);
            JointOwnerR2CalloutHelper.processJointOwnerResponse(responseBodyWrapper.results, Constants.OWNERSHIP_CHANGE_INTEGRATION, '', '');

            responseBodyWrapper = (MuleSOResponeWrapper)System.JSON.deserialize(responseFailureBody, MuleSOResponeWrapper.class);
            JointOwnerR2CalloutHelper.processJointOwnerResponse(responseBodyWrapper.results, Constants.OWNERSHIP_CHANGE_INTEGRATION, '', '');
            
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestBody));
            System.enqueueJob(new CalloutToMuleSoftForSRQueueable(responseBody, true, Constants.OWNERSHIP_CHANGE_INTEGRATION, new List<Id>{newSR.Id}));
            
            Test.stopTest();
        } catch(Exception ex){
            System.debug('ex>>>' + ex);
        }
    }
}