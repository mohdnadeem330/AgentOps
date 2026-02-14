/**********************************************************************************************************************
* Name              : CC_SendDocuSignEnvTest                                                        
* Description       : This Apex class is the test class for CC_SendDocuSignEnv
* Method			: validateSendDocuSignTestMethod	 
* Created By        :  
* Last Modified By	: tdontha@aldar.com - Tharun
* Test Coverage		: 86% & 89% with AgencyRegDocuSignHelperTest
******************************************************************************************************************/
@isTest
public with sharing class CC_SendDocuSignEnvTest
{
    @isTest
    static void validateSendDocuSignTestMethod() 
    {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'AgencyRegistration']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Agency Registration';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='AgencyRegistration';
        insert SR_Template;
        
        HexaBPM__Step_Template__c ST1 = new HexaBPM__Step_Template__c();
        ST1.Name = 'Step 1';
        ST1.HexaBPM__Code__c = 'Digital Signature by Authorized Signatory';
        ST1.HexaBPM__Step_RecordType_API_Name__c = 'Digital Signature by Authorized Signatory';
        insert ST1;
        
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Step 2';
        ST.HexaBPM__Code__c = 'Require More Information';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'Require More Information';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep1 = new HexaBPM__SR_Steps__c();
        SRStep1.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep1.HexaBPM__Step_No__c = 10;
        SRStep1.HexaBPM__Step_Template__c = ST1.Id;
        SRStep1.HexaBPM__Summary__c = 'Digital Signature by Authorized Signatory';
        SRStep1.HexaBPM__Step_RecordType_API_Name__c = 'AgencyRegistration';
        insert SRStep1;
        
        HexaBPM__SR_Steps__c SRStep2 = new HexaBPM__SR_Steps__c();
        SRStep2.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep2.HexaBPM__Step_No__c = 20;
        SRStep2.HexaBPM__Step_Template__c = ST.Id;
        SRStep2.HexaBPM__Summary__c = 'Require More Information';
        SRStep2.HexaBPM__Step_RecordType_API_Name__c = 'AgencyRegistration';
        insert SRStep2;
        
        System.debug('SR_Template.id->'+SR_Template.id);
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('AgencyRegistration');
        SR.HexaBPM__SR_Template__c = SR_Template.Id;  
        insert SR;
        System.debug('SR.Id->'+SR.Id);
        System.debug('SR.HexaBPM__SR_Template__c->'+SR.HexaBPM__SR_Template__c);
        
        HexaBPM__Step__c step1 = new HexaBPM__Step__c();
        step1.HexaBPM__Summary__c = 'AgencyRegistration';
        step1.HexaBPM__SR__c = SR.Id;
        step1.HexaBPM__SR_Step__c = SRStep1.Id;
        step1.HexaBPM__Start_Date__c = System.today();
        insert step1;
        
        HexaBPM__Step__c step2 = new HexaBPM__Step__c();
        step2.HexaBPM__Summary__c = 'AgencyRegistration';
        step2.HexaBPM__SR__c = SR.Id;
        step2.HexaBPM__SR_Step__c = SRStep2.Id;
        step2.HexaBPM__Start_Date__c = System.today();
        insert step2;
        
        System.debug('step.id->'+step1.id);
        System.debug('SR.id->'+SR.id);
        System.debug('SR.HexaBPM__SR_Template__c->'+SR.HexaBPM__SR_Template__c);
        
        HexaBPM__Step__c finalStep1 = [SELECT id, HexaBPM__Summary__c,Step_Template_Code__c, 
                                       HexaBPM__SR__r.HexaBPM__SR_Template__c,
                                       HexaBPM__SR__r.HexaBPM__Record_Type_Name__c,
                                       HexaBPM__SR_Step__c,
                                       HexaBPM__Start_Date__c 
                                       FROM HexaBPM__Step__c 
                                       WHERE Id = :step1.Id];
        
        System.debug('step HexaBPM__SR_Template__c ->'+finalStep1.HexaBPM__SR__r.HexaBPM__SR_Template__c);
        
        HexaBPM__Step__c finalStep2 = [SELECT id, HexaBPM__Summary__c,Step_Template_Code__c, 
                                       HexaBPM__SR__r.HexaBPM__SR_Template__c,
                                       HexaBPM__SR__r.HexaBPM__Record_Type_Name__c,
                                       HexaBPM__SR_Step__c,
                                       HexaBPM__Start_Date__c 
                                       FROM HexaBPM__Step__c 
                                       WHERE Id = :step2.Id];
        
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Agency_Agreement_Document';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__Document_Master__c objDocMaster2 = new HexaBPM__Document_Master__c();
        objDocMaster2.HexaBPM__Code__c = 'AgencyAgreementSignedbyHeadofBM';
        objDocMaster2.HexaBPM__Available_to_client__c = true;
        insert objDocMaster2;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id;
        docTemp.HexaBPM__Added_through_Code__c = true;
        docTemp.HexaBPM__SR_Template__c = SR_Template.id;
        docTemp.HexaBPM__Optional__c = true;
        docTemp.HexaBPM__Evaluated_at__c = SRStep1.id;
        docTemp.HexaBPM__Generate_Document__c = false;
        insert docTemp;
                
        HexaBPM__SR_Template_Docs__c docTemp2 = new HexaBPM__SR_Template_Docs__c();
        docTemp2.HexaBPM__Document_Master__c = objDocMaster2.id;
        docTemp2.HexaBPM__Added_through_Code__c = true;
        docTemp2.HexaBPM__SR_Template__c = SR_Template.id;
        docTemp2.HexaBPM__Generate_Document__c = true;
        docTemp2.HexaBPM__Optional__c = true;
        docTemp2.HexaBPM__Evaluated_at__c = SRStep1.id;
        insert docTemp2;
        
        
        HexaBPM__SR_Doc__c objSRDoc2 = new HexaBPM__SR_Doc__c();
        objSRDoc2.HexaBPM__Document_Master__c = objDocMaster2.id;
        objSRDoc2.HexaBPM__SR_Template_Doc__c = docTemp2.id;
        objSRDoc2.HexaBPM__Service_Request__c = SR.id  ;
        objSRDoc2.HexaBPM__Step__c = finalStep1.Id;
        objSRDoc2.Send_For_E_Signature__c=true;
        objSRDoc2.HexaBPM__From_Finalize__c = true;
        objSRDoc2.HexaBPM__Is_Not_Required__c = true;
        insert objSRDoc2;
        
        list<HexaBPM__SR_Doc__c> srDoc = BrokerAgencyRegistrationController.attachDocuments(sr.Id);
        
        Test.startTest();
        System.debug('finalStep1--->'+finalStep1.HexaBPM__SR__c);
        CC_SendDocuSignEnv objStep1 = new CC_SendDocuSignEnv();
        objStep1.EvaluateCustomCode(SR, finalStep1);
		Test.StopTest();
    }
    
}