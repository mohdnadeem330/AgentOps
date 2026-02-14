/**********************************************************************************************************************
* Name              : AgencyRegDocuSignHelperTest                                                        
* Description       : This Apex class is the test class for AgencyRegDocuSignHelper & CC_SendDocuSignEnv
* Method			: validateAgencyDocMethod	 
* Created By & Date : tdontha@aldar.com - Tharun [24-Aug-2023]
* Last Modified By	: tdontha@aldar.com - Tharun [25-Aug-2023]
* Test Coverage		: 91%
******************************************************************************************************************/
@isTest
public class AgencyRegDocuSignHelperTest
{
    @isTest
    static void validateAgencyDocMethod()
    {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id, DeveloperName FROM Recordtype 
                                WHERE SObjectType = 'HexaBPM__Service_Request__c' 
                                AND DeveloperName = :ALD_Constants.Agency_Re_Registration_DEV_RT]){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        HexaBPM__SR_Template__c SR_Template 					= new HexaBPM__SR_Template__c();
        SR_Template.Name 										= 'Agency Re-Registration';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c 			= ALD_Constants.Agency_Re_Registration_DEV_RT;
        insert SR_Template;
        
        HexaBPM__Step_Template__c Step_Template					= new HexaBPM__Step_Template__c();
        Step_Template.Name 										= 'Digital Signature by Authorized Signatory';
        Step_Template.HexaBPM__Code__c 							= 'Digital Signature by Authorized Signatory';
        Step_Template.HexaBPM__Step_RecordType_API_Name__c 		= 'General';
        insert Step_Template;
        
        HexaBPM__SR_Steps__c SRStep 							= new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c 							= SR_Template.id;
        SRStep.HexaBPM__Step_No__c 								= 5.0;
        SRStep.HexaBPM__Step_Template__c 						= Step_Template.Id;
        SRStep.HexaBPM__Summary__c 								= 'Assignment of Broker Manager';
        SRStep.HexaBPM__Step_RecordType_API_Name__c 			= 'General';
        SRStep.HexaBPM__Step_Instructions__c 					= 'Assignment of Broker Manager';
        insert SRStep;
        
        HexaBPM__Service_Request__c SR 							= new HexaBPM__Service_Request__c();
        SR.RecordTypeId 										= recordTypeSR.get('AgencyReRegistration');
        SR.HexaBPM__SR_Template__c 								= SR_Template.Id;
        SR.AccountName__c										= 'Tharun Test Agency';
        SR.City__c												= 'Abu Dhabi';
        SR.POBox__c												= '789907';
        SR.Designation__c										= 'CEO Of Company';
        SR.SignatoryName__c										= 'Tharun Kumar';
        SR.SignatoryEmail__c									= 'tdontha@aldar.com';
        insert SR;
        
        HexaBPM__Step__c step1 									= new HexaBPM__Step__c();
        step1.HexaBPM__Summary__c 								= 'Digital Signature by Authorized Signatory';
        step1.HexaBPM__SR__c 									= SR.Id;
        step1.HexaBPM__SR_Step__c 								= SRStep.Id;
        step1.HexaBPM__Start_Date__c 							= System.today();
        insert step1;
        
        HexaBPM__Step__c finalStep1 = [SELECT id, HexaBPM__Summary__c,Step_Template_Code__c, 
                                       HexaBPM__SR__r.HexaBPM__SR_Template__c,
                                       HexaBPM__SR__r.HexaBPM__Record_Type_Name__c,
                                       HexaBPM__SR_Step__c,
                                       HexaBPM__Start_Date__c 
                                       FROM HexaBPM__Step__c 
                                       WHERE Id = :step1.Id];
        
        
        HexaBPM__Document_Master__c objDocMaster 				= new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c 							= 'Agency_Agreement_Document';
        objDocMaster.HexaBPM__Available_to_client__c 			= true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp 					= new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c 					= objDocMaster.id ;
        docTemp.HexaBPM__Added_through_Code__c 					= true;
        docTemp.HexaBPM__SR_Template__c 						= SR_Template.id;
        docTemp.HexaBPM__Generate_Document__c 					= true;
        docTemp.HexaBPM__Evaluated_at__c 						= SRStep.id;
        insert docTemp;
        
        HexaBPM__SR_Doc__c objSRDoc 							= new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c 					= objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c 					= docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c					= SR.id  ;
        objSRDoc.HexaBPM__Step__c								= finalStep1.Id;
        objSRDoc.Send_For_E_Signature__c						= true;
        objSRDoc.HexaBPM__From_Finalize__c 						= true;
        objSRDoc.HexaBPM__Is_Not_Required__c 					= true;
        insert objSRDoc;
        
        List<HexaBPM__SR_Doc__c> srDoc 							= BrokerAgencyRegistrationController.attachDocuments(sr.Id);
        
        Test.startTest();
        CC_SendDocuSignEnv obj 									= new CC_SendDocuSignEnv();
        obj.EvaluateCustomCode(SR, finalStep1);
        AgencyRegDocuSignHelper.getStepDetails(SR.Id);
        Test.stopTest();
        
    }
    
}